#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <flint/flint.h>
#include <flint/nmod.h>
#include <flint/nmod_mat.h>
#include <flint/nmod_poly.h>
#include <flint/ulong_extras.h>
#include <omp.h>

/*
 * Prototype finite-field rational interpolation backend.
 *
 * Discovery reproduces finiteFieldStripFitCandidates and the synchronized
 * adaptive held-out loop in finiteFieldStripHeldOutInterpolate: minimal total
 * degree, every numerator/denominator split, reduced-pair deduplication, and
 * exact held-out checks.  Held-outs are consumed sequentially: only a point
 * which empties a candidate set is promoted into construction, avoiding the
 * old three-point construction overshoot.  Coordinates remain parallel inside
 * each synchronized point step.  Each coordinate also remembers the first
 * total degree not yet disproved.  Construction data only grows, so a degree
 * whose complete candidate set has been rejected can never become viable
 * later; retaining that monotone floor avoids rescanning all lower Pade
 * splits after every promoted point.
 */

enum {
    MODE_DISCOVERY = 0,
    MODE_FIXED_PROFILE = 1
};

enum {
    RESULT_ACCEPTED = 0,
    RESULT_MORE_SAMPLES = 1,
    RESULT_INTERNAL_FAILURE = 2
};

enum {
    REASON_NONE = 0,
    REASON_GROW_REQUIRED = 1,
    REASON_HELD_OUT_ROUND = 2,
    REASON_INTERNAL = 3,
    REASON_MAXIMUM_DEGREE_EXCEEDED = 4
};

enum {
    COORD_ACCEPTED = 0,
    COORD_UNRESOLVED = 1,
    COORD_HELD_OUT_SHORTFALL = 2,
    COORD_AMBIGUOUS = 3,
    COORD_PEER_NOT_TERMINAL = 4,
    COORD_INTERNAL_FAILURE = 5
};

static const unsigned char input_magic[8] =
    {'F', 'F', 'R', 'I', '1', 'V', '1', '\0'};
static const unsigned char output_magic[8] =
    {'F', 'F', 'R', 'I', '1', 'X', '1', '\0'};
static const uint64_t negative_infinity_degree = UINT64_MAX;

typedef struct {
    slong numerator_degree;
    slong denominator_degree;
    size_t numerator_count;
    size_t denominator_count;
    mp_limb_t *numerator;
    mp_limb_t *denominator;
} candidate_t;

typedef struct {
    candidate_t *items;
    size_t count;
    size_t capacity;
    size_t next_total_degree;
} candidate_set_t;

typedef struct {
    mp_limb_t prime;
    nmod_t modulus;
    size_t sample_count;
    size_t coordinate_count;
    size_t initial_count;
    size_t held_out_count;
    size_t maximum_total_degree;
    unsigned mode;
    mp_limb_t *abscissae;
    mp_limb_t *values;
    uint64_t *expected_numerator_degrees;
    uint64_t *expected_denominator_degrees;
} interpolation_input_t;

typedef struct {
    unsigned status;
    unsigned reason;
    size_t consumed;
    size_t construction_count;
    size_t required_additional;
    int threads;
    candidate_set_t *coordinates;
} interpolation_result_t;

static int checked_mul_size(size_t left, size_t right, size_t *product)
{
    if (left != 0U && right > SIZE_MAX / left)
        return 0;
    *product = left * right;
    return 1;
}

static int u64_to_size(uint64_t value, size_t *converted)
{
    if (value > (uint64_t) SIZE_MAX)
        return 0;
    *converted = (size_t) value;
    return 1;
}

static int read_u64_le(FILE *stream, uint64_t *value)
{
    unsigned char bytes[8];
    size_t index;
    uint64_t result = 0U;

    if (fread(bytes, 1U, sizeof(bytes), stream) != sizeof(bytes))
        return 0;
    for (index = 0U; index < sizeof(bytes); ++index)
        result |= ((uint64_t) bytes[index]) << (8U * index);
    *value = result;
    return 1;
}

static int write_u64_le(FILE *stream, uint64_t value)
{
    unsigned char bytes[8];
    size_t index;

    for (index = 0U; index < sizeof(bytes); ++index)
        bytes[index] = (unsigned char) ((value >> (8U * index)) & UINT64_C(255));
    return fwrite(bytes, 1U, sizeof(bytes), stream) == sizeof(bytes);
}

static void candidate_init(candidate_t *candidate)
{
    memset(candidate, 0, sizeof(*candidate));
    candidate->numerator_degree = -1;
    candidate->denominator_degree = -1;
}

static void candidate_clear(candidate_t *candidate)
{
    free(candidate->numerator);
    free(candidate->denominator);
    candidate_init(candidate);
}

static int candidate_equal(const candidate_t *left, const candidate_t *right)
{
    return left->numerator_degree == right->numerator_degree
        && left->denominator_degree == right->denominator_degree
        && left->numerator_count == right->numerator_count
        && left->denominator_count == right->denominator_count
        && memcmp(left->numerator, right->numerator,
            left->numerator_count * sizeof(*left->numerator)) == 0
        && memcmp(left->denominator, right->denominator,
            left->denominator_count * sizeof(*left->denominator)) == 0;
}

static void candidate_set_init(candidate_set_t *set)
{
    memset(set, 0, sizeof(*set));
}

static void candidate_set_clear(candidate_set_t *set)
{
    size_t index;

    for (index = 0U; index < set->count; ++index)
        candidate_clear(set->items + index);
    free(set->items);
    candidate_set_init(set);
}

/* Takes ownership of candidate on both insertion and deduplication. */
static int candidate_set_append_unique(candidate_set_t *set,
    candidate_t *candidate)
{
    size_t index, new_capacity, byte_count;
    candidate_t *resized;

    for (index = 0U; index < set->count; ++index)
        if (candidate_equal(set->items + index, candidate)) {
            candidate_clear(candidate);
            return 1;
        }
    if (set->count == set->capacity) {
        new_capacity = set->capacity == 0U ? 4U : 2U * set->capacity;
        if (new_capacity < set->capacity
            || !checked_mul_size(new_capacity, sizeof(*set->items), &byte_count)) {
            candidate_clear(candidate);
            return 0;
        }
        resized = (candidate_t *) realloc(set->items, byte_count);
        if (resized == NULL) {
            candidate_clear(candidate);
            return 0;
        }
        set->items = resized;
        set->capacity = new_capacity;
    }
    set->items[set->count++] = *candidate;
    candidate_init(candidate);
    return 1;
}

static mp_limb_t evaluate_coefficients(const mp_limb_t *coefficients,
    size_t count, mp_limb_t value, nmod_t modulus)
{
    size_t index = count;
    mp_limb_t result = 0U;

    while (index > 0U) {
        --index;
        result = nmod_add(nmod_mul(result, value, modulus),
            coefficients[index], modulus);
    }
    return result;
}

static int candidate_predicts_sample(const candidate_t *candidate,
    mp_limb_t x, mp_limb_t y, nmod_t modulus)
{
    mp_limb_t numerator = evaluate_coefficients(candidate->numerator,
        candidate->numerator_count, x, modulus);
    mp_limb_t denominator = evaluate_coefficients(candidate->denominator,
        candidate->denominator_count, x, modulus);

    return denominator != 0U
        && numerator == nmod_mul(y, denominator, modulus);
}

static int candidate_predicts_indices(const candidate_t *candidate,
    const interpolation_input_t *input, size_t coordinate,
    const size_t *indices, size_t count)
{
    size_t cursor, sample;

    for (cursor = 0U; cursor < count; ++cursor) {
        sample = indices[cursor];
        if (!candidate_predicts_sample(candidate, input->abscissae[sample],
                input->values[sample * input->coordinate_count + coordinate],
                input->modulus))
            return 0;
    }
    return 1;
}

static void candidate_set_filter(candidate_set_t *set,
    const interpolation_input_t *input, size_t coordinate,
    const size_t *indices, size_t count)
{
    size_t read_index, write_index = 0U;

    for (read_index = 0U; read_index < set->count; ++read_index) {
        if (candidate_predicts_indices(set->items + read_index, input,
                coordinate, indices, count)) {
            if (write_index != read_index) {
                set->items[write_index] = set->items[read_index];
                candidate_init(set->items + read_index);
            }
            ++write_index;
        } else {
            candidate_clear(set->items + read_index);
        }
    }
    set->count = write_index;
}

static int construction_values_are_zero(const interpolation_input_t *input,
    size_t coordinate, const size_t *construction, size_t construction_count)
{
    size_t cursor;

    for (cursor = 0U; cursor < construction_count; ++cursor)
        if (input->values[construction[cursor] * input->coordinate_count
                + coordinate] != 0U)
            return 0;
    return 1;
}

static int make_zero_candidate(candidate_t *candidate)
{
    candidate_init(candidate);
    candidate->numerator = (mp_limb_t *) calloc(1U,
        sizeof(*candidate->numerator));
    candidate->denominator = (mp_limb_t *) malloc(
        sizeof(*candidate->denominator));
    if (candidate->numerator == NULL || candidate->denominator == NULL) {
        candidate_clear(candidate);
        return 0;
    }
    candidate->denominator[0] = 1U;
    candidate->numerator_count = 1U;
    candidate->denominator_count = 1U;
    candidate->numerator_degree = -1;
    candidate->denominator_degree = 0;
    return 1;
}

static int candidate_from_null_vector(candidate_t *candidate,
    const mp_limb_t *vector, size_t numerator_count,
    size_t denominator_count, mp_limb_t prime)
{
    nmod_poly_t numerator, denominator, divisor, reduced_numerator,
        reduced_denominator, remainder;
    slong numerator_degree, denominator_degree;
    size_t index, byte_count;
    mp_limb_t leading, inverse;
    int ok = 0;

    candidate_init(candidate);
    nmod_poly_init(numerator, prime);
    nmod_poly_init(denominator, prime);
    nmod_poly_init(divisor, prime);
    nmod_poly_init(reduced_numerator, prime);
    nmod_poly_init(reduced_denominator, prime);
    nmod_poly_init(remainder, prime);

    for (index = 0U; index < numerator_count; ++index)
        nmod_poly_set_coeff_ui(numerator, (slong) index, vector[index]);
    for (index = 0U; index < denominator_count; ++index)
        nmod_poly_set_coeff_ui(denominator, (slong) index,
            vector[numerator_count + index]);
    if (nmod_poly_is_zero(denominator))
        goto cleanup;
    nmod_poly_gcd(divisor, numerator, denominator);
    if (nmod_poly_is_zero(divisor))
        goto cleanup;
    nmod_poly_divrem(reduced_numerator, remainder, numerator, divisor);
    if (!nmod_poly_is_zero(remainder))
        goto cleanup;
    nmod_poly_divrem(reduced_denominator, remainder, denominator, divisor);
    if (!nmod_poly_is_zero(remainder) || nmod_poly_is_zero(reduced_denominator))
        goto cleanup;
    denominator_degree = nmod_poly_degree(reduced_denominator);
    leading = nmod_poly_get_coeff_ui(reduced_denominator, denominator_degree);
    inverse = (mp_limb_t) n_invmod(leading, prime);
    nmod_poly_scalar_mul_nmod(reduced_numerator, reduced_numerator, inverse);
    nmod_poly_scalar_mul_nmod(reduced_denominator, reduced_denominator, inverse);
    numerator_degree = nmod_poly_degree(reduced_numerator);
    denominator_degree = nmod_poly_degree(reduced_denominator);
    candidate->numerator_count = numerator_degree < 0
        ? 1U : (size_t) numerator_degree + 1U;
    candidate->denominator_count = (size_t) denominator_degree + 1U;
    if (!checked_mul_size(candidate->numerator_count,
            sizeof(*candidate->numerator), &byte_count))
        goto cleanup;
    candidate->numerator = (mp_limb_t *) calloc(1U, byte_count);
    if (!checked_mul_size(candidate->denominator_count,
            sizeof(*candidate->denominator), &byte_count))
        goto cleanup;
    candidate->denominator = (mp_limb_t *) malloc(byte_count);
    if (candidate->numerator == NULL || candidate->denominator == NULL)
        goto cleanup;
    for (index = 0U; index < candidate->numerator_count; ++index)
        candidate->numerator[index] = nmod_poly_get_coeff_ui(
            reduced_numerator, (slong) index);
    for (index = 0U; index < candidate->denominator_count; ++index)
        candidate->denominator[index] = nmod_poly_get_coeff_ui(
            reduced_denominator, (slong) index);
    candidate->numerator_degree = numerator_degree;
    candidate->denominator_degree = denominator_degree;
    ok = 1;

cleanup:
    nmod_poly_clear(numerator);
    nmod_poly_clear(denominator);
    nmod_poly_clear(divisor);
    nmod_poly_clear(reduced_numerator);
    nmod_poly_clear(reduced_denominator);
    nmod_poly_clear(remainder);
    if (!ok)
        candidate_clear(candidate);
    return ok;
}

/* Returns 1 with a candidate, 1 with has_candidate=0, or 0 on allocation. */
static int fit_split(const interpolation_input_t *input, size_t coordinate,
    const size_t *construction, size_t construction_count,
    size_t numerator_degree, size_t denominator_degree,
    candidate_t *candidate, int *has_candidate)
{
    size_t numerator_count = numerator_degree + 1U;
    size_t denominator_count = denominator_degree + 1U;
    size_t columns, row, column, cursor, free_column = SIZE_MAX;
    slong rank, pivot;
    slong *pivot_columns = NULL;
    mp_limb_t *vector = NULL;
    nmod_mat_t matrix;
    mp_limb_t power, x, y;
    int matrix_initialized = 0, ok = 0, denominator_nonzero = 0;

    candidate_init(candidate);
    *has_candidate = 0;
    if (numerator_count > SIZE_MAX - denominator_count)
        return 0;
    columns = numerator_count + denominator_count;
    if (construction_count > (size_t) LONG_MAX || columns > (size_t) LONG_MAX)
        return 0;
    nmod_mat_init(matrix, (slong) construction_count, (slong) columns,
        input->prime);
    matrix_initialized = 1;
    for (row = 0U; row < construction_count; ++row) {
        x = input->abscissae[construction[row]];
        y = input->values[construction[row] * input->coordinate_count
            + coordinate];
        power = 1U;
        for (column = 0U; column < numerator_count; ++column) {
            nmod_mat_set_entry(matrix, (slong) row, (slong) column, power);
            power = nmod_mul(power, x, input->modulus);
        }
        power = 1U;
        for (column = 0U; column < denominator_count; ++column) {
            nmod_mat_set_entry(matrix, (slong) row,
                (slong) (numerator_count + column),
                nmod_neg(nmod_mul(y, power, input->modulus), input->modulus));
            power = nmod_mul(power, x, input->modulus);
        }
    }
    rank = nmod_mat_rref(matrix);
    if ((slong) columns - rank != 1) {
        ok = 1;
        goto cleanup;
    }
    if (!checked_mul_size((size_t) rank, sizeof(*pivot_columns), &cursor))
        goto cleanup;
    pivot_columns = (slong *) malloc(cursor);
    if (!checked_mul_size(columns, sizeof(*vector), &cursor))
        goto cleanup;
    vector = (mp_limb_t *) calloc(1U, cursor);
    if ((rank > 0 && pivot_columns == NULL) || vector == NULL)
        goto cleanup;
    for (row = 0U; row < (size_t) rank; ++row) {
        pivot = -1;
        for (column = 0U; column < columns; ++column)
            if (nmod_mat_entry(matrix, (slong) row, (slong) column) != 0U) {
                pivot = (slong) column;
                break;
            }
        if (pivot < 0)
            goto cleanup;
        pivot_columns[row] = pivot;
    }
    cursor = 0U;
    for (column = 0U; column < columns; ++column) {
        if (cursor < (size_t) rank
            && pivot_columns[cursor] == (slong) column) {
            ++cursor;
        } else {
            if (free_column != SIZE_MAX)
                goto cleanup;
            free_column = column;
        }
    }
    if (free_column == SIZE_MAX)
        goto cleanup;
    vector[free_column] = 1U;
    for (row = 0U; row < (size_t) rank; ++row)
        vector[(size_t) pivot_columns[row]] = nmod_neg(nmod_mat_entry(matrix,
            (slong) row, (slong) free_column), input->modulus);
    for (column = 0U; column < denominator_count; ++column)
        if (vector[numerator_count + column] != 0U) {
            denominator_nonzero = 1;
            break;
        }
    if (!denominator_nonzero) {
        ok = 1;
        goto cleanup;
    }
    if (!candidate_from_null_vector(candidate, vector, numerator_count,
            denominator_count, input->prime))
        goto cleanup;
    if (!candidate_predicts_indices(candidate, input, coordinate, construction,
            construction_count)) {
        candidate_clear(candidate);
        ok = 1;
        goto cleanup;
    }
    *has_candidate = 1;
    ok = 1;

cleanup:
    if (matrix_initialized)
        nmod_mat_clear(matrix);
    free(pivot_columns);
    free(vector);
    if (!ok)
        candidate_clear(candidate);
    return ok;
}

static int fit_coordinate(const interpolation_input_t *input,
    size_t coordinate, const size_t *construction, size_t construction_count,
    candidate_set_t *set)
{
    size_t total, numerator_degree, maximum;
    uint64_t expected_numerator, expected_denominator;
    candidate_t candidate;
    int has_candidate;

    if (construction_values_are_zero(input, coordinate, construction,
            construction_count)) {
        if (input->mode == MODE_FIXED_PROFILE
            && input->expected_numerator_degrees[coordinate]
                != negative_infinity_degree)
            return 1;
        if (!make_zero_candidate(&candidate))
            return 0;
        return candidate_set_append_unique(set, &candidate);
    }
    if (input->mode == MODE_FIXED_PROFILE) {
        expected_numerator = input->expected_numerator_degrees[coordinate];
        expected_denominator = input->expected_denominator_degrees[coordinate];
        if (expected_numerator == negative_infinity_degree)
            return 1;
        if (!fit_split(input, coordinate, construction, construction_count,
                (size_t) expected_numerator, (size_t) expected_denominator,
                &candidate, &has_candidate))
            return 0;
        if (!has_candidate)
            return 1;
        if (candidate.numerator_degree != (slong) expected_numerator
            || candidate.denominator_degree != (slong) expected_denominator) {
            candidate_clear(&candidate);
            return 1;
        }
        return candidate_set_append_unique(set, &candidate);
    }
    maximum = input->maximum_total_degree;
    if (construction_count == 0U)
        return 1;
    if (maximum > construction_count - 1U)
        maximum = construction_count - 1U;
    for (total = set->next_total_degree; total <= maximum; ++total) {
        for (numerator_degree = 0U; numerator_degree <= total;
                ++numerator_degree) {
            if (!fit_split(input, coordinate, construction, construction_count,
                    numerator_degree, total - numerator_degree, &candidate,
                    &has_candidate))
                return 0;
            if (has_candidate
                && !candidate_set_append_unique(set, &candidate))
                return 0;
        }
        if (set->count != 0U) {
            set->next_total_degree = total + 1U;
            break;
        }
    }
    if (set->count == 0U)
        set->next_total_degree = maximum + 1U;
    return 1;
}

static void interpolation_input_clear(interpolation_input_t *input)
{
    free(input->abscissae);
    free(input->values);
    free(input->expected_numerator_degrees);
    free(input->expected_denominator_degrees);
    memset(input, 0, sizeof(*input));
}

static int read_input(const char *path, interpolation_input_t *input)
{
    FILE *stream = NULL;
    unsigned char magic[8];
    uint64_t header[7], value;
    size_t index, value_count, byte_count;
    int ok = 0;

    memset(input, 0, sizeof(*input));
    stream = fopen(path, "rb");
    if (stream == NULL)
        return 0;
    if (fread(magic, 1U, sizeof(magic), stream) != sizeof(magic)
        || memcmp(magic, input_magic, sizeof(magic)) != 0)
        goto cleanup;
    for (index = 0U; index < 7U; ++index)
        if (!read_u64_le(stream, header + index))
            goto cleanup;
    if (sizeof(mp_limb_t) != sizeof(uint64_t)
        || header[0] < UINT64_C(5) || header[0] >= (UINT64_C(1) << 63U)
        || (header[0] & UINT64_C(1)) == 0U
        || !n_is_prime((mp_limb_t) header[0])
        || !u64_to_size(header[1], &input->sample_count)
        || !u64_to_size(header[2], &input->coordinate_count)
        || !u64_to_size(header[3], &input->initial_count)
        || !u64_to_size(header[4], &input->held_out_count)
        || !u64_to_size(header[5], &input->maximum_total_degree)
        || header[6] > MODE_FIXED_PROFILE
        || input->sample_count == 0U || input->coordinate_count == 0U
        || input->initial_count == 0U || input->held_out_count == 0U
        || input->initial_count > input->sample_count
        || input->sample_count >= (size_t) LONG_MAX
        || input->coordinate_count > (size_t) LLONG_MAX)
        goto cleanup;
    input->prime = (mp_limb_t) header[0];
    input->mode = (unsigned) header[6];
    nmod_init(&input->modulus, input->prime);
    if (!checked_mul_size(input->sample_count,
            sizeof(*input->abscissae), &byte_count))
        goto cleanup;
    input->abscissae = (mp_limb_t *) malloc(byte_count);
    if (!checked_mul_size(input->sample_count, input->coordinate_count,
            &value_count)
        || !checked_mul_size(value_count, sizeof(*input->values), &byte_count))
        goto cleanup;
    input->values = (mp_limb_t *) malloc(byte_count);
    if (input->abscissae == NULL || input->values == NULL)
        goto cleanup;
    for (index = 0U; index < input->sample_count; ++index) {
        if (!read_u64_le(stream, &value) || value >= header[0])
            goto cleanup;
        input->abscissae[index] = (mp_limb_t) value;
    }
    for (index = 0U; index < value_count; ++index) {
        if (!read_u64_le(stream, &value) || value >= header[0])
            goto cleanup;
        input->values[index] = (mp_limb_t) value;
    }
    if (input->mode == MODE_FIXED_PROFILE) {
        if (!checked_mul_size(input->coordinate_count,
                sizeof(*input->expected_numerator_degrees), &byte_count))
            goto cleanup;
        input->expected_numerator_degrees = (uint64_t *) malloc(byte_count);
        input->expected_denominator_degrees = (uint64_t *) malloc(byte_count);
        if (input->expected_numerator_degrees == NULL
            || input->expected_denominator_degrees == NULL)
            goto cleanup;
        for (index = 0U; index < input->coordinate_count; ++index) {
            if (!read_u64_le(stream,
                    input->expected_numerator_degrees + index)
                || !read_u64_le(stream,
                    input->expected_denominator_degrees + index))
                goto cleanup;
            if (input->expected_numerator_degrees[index]
                    == negative_infinity_degree) {
                if (input->expected_denominator_degrees[index] != 0U)
                    goto cleanup;
            } else if (input->expected_numerator_degrees[index]
                    > (uint64_t) input->maximum_total_degree
                || input->expected_denominator_degrees[index]
                    > (uint64_t) input->maximum_total_degree
                || input->expected_numerator_degrees[index]
                    > UINT64_MAX
                        - input->expected_denominator_degrees[index]
                || input->expected_numerator_degrees[index]
                    + input->expected_denominator_degrees[index]
                        > (uint64_t) input->maximum_total_degree
                || input->expected_numerator_degrees[index]
                    > (uint64_t) LONG_MAX
                || input->expected_denominator_degrees[index]
                    > (uint64_t) LONG_MAX)
                goto cleanup;
        }
    }
    if (fgetc(stream) != EOF)
        goto cleanup;
    ok = 1;

cleanup:
    if (stream != NULL)
        fclose(stream);
    if (!ok)
        interpolation_input_clear(input);
    return ok;
}

static void interpolation_result_clear(interpolation_result_t *result,
    size_t coordinate_count)
{
    size_t coordinate;

    if (result->coordinates != NULL)
        for (coordinate = 0U; coordinate < coordinate_count; ++coordinate)
            candidate_set_clear(result->coordinates + coordinate);
    free(result->coordinates);
    memset(result, 0, sizeof(*result));
}

static int interpolate(const interpolation_input_t *input, int threads,
    interpolation_result_t *result)
{
    size_t *construction = NULL;
    size_t construction_count = 0U, coordinate, cursor;
    size_t unresolved, degree_bound_exceeded, failures, ambiguous,
        validation_index;
    size_t validation_pass_count = 0U, required_validation;
    size_t construction_bytes;
    int parallel_error;

    memset(result, 0, sizeof(*result));
    result->threads = threads;
    result->coordinates = (candidate_set_t *) calloc(input->coordinate_count,
        sizeof(*result->coordinates));
    if (!checked_mul_size(input->sample_count, sizeof(*construction),
            &construction_bytes))
        goto internal_failure;
    construction = (size_t *) malloc(construction_bytes);
    if (result->coordinates == NULL || construction == NULL)
        goto internal_failure;
    for (coordinate = 0U; coordinate < input->coordinate_count; ++coordinate)
        candidate_set_init(result->coordinates + coordinate);
    construction_count = input->initial_count;
    result->consumed = input->initial_count;
    for (cursor = 0U; cursor < construction_count; ++cursor)
        construction[cursor] = cursor;

    for (;;) {
        parallel_error = 0;
#pragma omp parallel for num_threads(threads) schedule(static) reduction(|:parallel_error)
        for (long long signed_coordinate = 0;
                signed_coordinate < (long long) input->coordinate_count;
                ++signed_coordinate) {
            size_t current = (size_t) signed_coordinate;
            candidate_set_filter(result->coordinates + current, input, current,
                construction, construction_count);
            if (result->coordinates[current].count == 0U
                && !fit_coordinate(input, current, construction,
                    construction_count, result->coordinates + current))
                parallel_error = 1;
        }
        if (parallel_error)
            goto internal_failure;
        unresolved = 0U;
        degree_bound_exceeded = 0U;
        ambiguous = 0U;
        for (coordinate = 0U; coordinate < input->coordinate_count;
                ++coordinate)
            if (result->coordinates[coordinate].count == 0U) {
                ++unresolved;
                if (input->mode == MODE_DISCOVERY
                    && result->coordinates[coordinate].next_total_degree
                        > input->maximum_total_degree)
                    ++degree_bound_exceeded;
            } else if (result->coordinates[coordinate].count > 1U) {
                ++ambiguous;
            }
        if (degree_bound_exceeded != 0U) {
            result->status = RESULT_MORE_SAMPLES;
            result->reason = REASON_MAXIMUM_DEGREE_EXCEEDED;
            result->required_additional = 0U;
            break;
        }
        if (unresolved != 0U) {
            if (result->consumed >= input->sample_count) {
                result->status = RESULT_MORE_SAMPLES;
                result->reason = REASON_GROW_REQUIRED;
                result->required_additional = 1U;
                break;
            }
            construction[construction_count++] = result->consumed++;
            validation_pass_count = 0U;
            continue;
        }
        if (ambiguous == 0U
            && validation_pass_count >= input->held_out_count) {
            result->status = RESULT_ACCEPTED;
            result->reason = REASON_NONE;
            break;
        }
        if (result->consumed >= input->sample_count) {
            required_validation = input->held_out_count > validation_pass_count
                ? input->held_out_count - validation_pass_count : 0U;
            if (ambiguous != 0U && required_validation == 0U)
                required_validation = 1U;
            result->status = RESULT_MORE_SAMPLES;
            result->reason = REASON_HELD_OUT_ROUND;
            result->required_additional = required_validation;
            break;
        }
        validation_index = result->consumed++;
#pragma omp parallel for num_threads(threads) schedule(static)
        for (long long signed_coordinate = 0;
                signed_coordinate < (long long) input->coordinate_count;
                ++signed_coordinate) {
            size_t current = (size_t) signed_coordinate;
            candidate_set_filter(result->coordinates + current, input, current,
                &validation_index, 1U);
        }
        failures = 0U;
        for (coordinate = 0U; coordinate < input->coordinate_count; ++coordinate)
            if (result->coordinates[coordinate].count == 0U)
                ++failures;
        if (failures == 0U) {
            ++validation_pass_count;
        } else {
            construction[construction_count++] = validation_index;
            validation_pass_count = 0U;
        }
    }
    result->construction_count = construction_count;
    free(construction);
    return 1;

internal_failure:
    free(construction);
    result->status = RESULT_INTERNAL_FAILURE;
    result->reason = REASON_INTERNAL;
    result->construction_count = construction_count;
    result->required_additional = 0U;
    return 0;
}

static unsigned coordinate_status(const interpolation_result_t *result,
    size_t coordinate)
{
    size_t count;

    if (result->status == RESULT_INTERNAL_FAILURE)
        return COORD_INTERNAL_FAILURE;
    count = result->coordinates == NULL
        ? 0U : result->coordinates[coordinate].count;
    if (result->status == RESULT_ACCEPTED)
        return COORD_ACCEPTED;
    if (count == 0U)
        return COORD_UNRESOLVED;
    if (count > 1U)
        return COORD_AMBIGUOUS;
    if (result->reason == REASON_HELD_OUT_ROUND)
        return COORD_HELD_OUT_SHORTFALL;
    return COORD_PEER_NOT_TERMINAL;
}

static int write_output(const char *path, const interpolation_input_t *input,
    const interpolation_result_t *result)
{
    FILE *stream = fopen(path, "wb");
    size_t coordinate, index;
    unsigned status;
    const candidate_t *candidate;
    uint64_t numerator_degree, denominator_degree;
    int ok = 1;

    if (stream == NULL)
        return 0;
    ok = fwrite(output_magic, 1U, sizeof(output_magic), stream)
            == sizeof(output_magic)
        && write_u64_le(stream, (uint64_t) input->prime)
        && write_u64_le(stream, (uint64_t) input->sample_count)
        && write_u64_le(stream, (uint64_t) input->coordinate_count)
        && write_u64_le(stream, (uint64_t) input->mode)
        && write_u64_le(stream, (uint64_t) result->status)
        && write_u64_le(stream, (uint64_t) result->reason)
        && write_u64_le(stream, (uint64_t) result->consumed)
        && write_u64_le(stream, (uint64_t) result->construction_count)
        && write_u64_le(stream, (uint64_t) result->required_additional)
        && write_u64_le(stream, (uint64_t) result->threads);
    for (coordinate = 0U; ok && coordinate < input->coordinate_count;
            ++coordinate) {
        status = coordinate_status(result, coordinate);
        candidate = status == COORD_ACCEPTED
            ? result->coordinates[coordinate].items : NULL;
        numerator_degree = candidate == NULL ? negative_infinity_degree
            : candidate->numerator_degree < 0 ? negative_infinity_degree
            : (uint64_t) candidate->numerator_degree;
        denominator_degree = candidate == NULL ? negative_infinity_degree
            : (uint64_t) candidate->denominator_degree;
        ok = write_u64_le(stream, (uint64_t) status)
            && write_u64_le(stream, numerator_degree)
            && write_u64_le(stream, denominator_degree)
            && write_u64_le(stream, (uint64_t) result->consumed)
            && write_u64_le(stream, candidate == NULL ? 0U
                : (uint64_t) candidate->numerator_count)
            && write_u64_le(stream, candidate == NULL ? 0U
                : (uint64_t) candidate->denominator_count);
        if (candidate != NULL) {
            for (index = 0U; ok && index < candidate->numerator_count; ++index)
                ok = write_u64_le(stream, (uint64_t) candidate->numerator[index]);
            for (index = 0U; ok && index < candidate->denominator_count; ++index)
                ok = write_u64_le(stream,
                    (uint64_t) candidate->denominator[index]);
        }
    }
    if (fclose(stream) != 0)
        ok = 0;
    return ok;
}

static mp_limb_t rational_value(mp_limb_t a0, mp_limb_t a1,
    mp_limb_t b0, mp_limb_t b1, mp_limb_t x, mp_limb_t prime,
    nmod_t modulus)
{
    mp_limb_t numerator = nmod_add(a0, nmod_mul(a1, x, modulus), modulus);
    mp_limb_t denominator = nmod_add(b0, nmod_mul(b1, x, modulus), modulus);
    return nmod_mul(numerator, (mp_limb_t) n_invmod(denominator, prime),
        modulus);
}

static int candidate_predicts_all(const candidate_t *candidate,
    const interpolation_input_t *input, size_t coordinate)
{
    size_t sample;

    for (sample = 0U; sample < input->sample_count; ++sample)
        if (!candidate_predicts_sample(candidate, input->abscissae[sample],
                input->values[sample * input->coordinate_count + coordinate],
                input->modulus))
            return 0;
    return 1;
}

static int self_test(void)
{
    interpolation_input_t input;
    interpolation_result_t result;
    size_t sample, value_count;
    mp_limb_t x, square, fourth, polynomial;
    int ok = 1;

    memset(&input, 0, sizeof(input));
    input.prime = UINT64_C(1000003);
    nmod_init(&input.modulus, input.prime);
    input.sample_count = 10U;
    input.coordinate_count = 3U;
    input.initial_count = 4U;
    input.held_out_count = 3U;
    input.maximum_total_degree = 6U;
    input.mode = MODE_DISCOVERY;
    value_count = input.sample_count * input.coordinate_count;
    input.abscissae = (mp_limb_t *) malloc(input.sample_count
        * sizeof(*input.abscissae));
    input.values = (mp_limb_t *) malloc(value_count * sizeof(*input.values));
    if (input.abscissae == NULL || input.values == NULL) {
        interpolation_input_clear(&input);
        return 0;
    }
    for (sample = 0U; sample < input.sample_count; ++sample) {
        x = (mp_limb_t) sample + 1U;
        input.abscissae[sample] = x;
        input.values[sample * input.coordinate_count] = rational_value(2U, 3U,
            1U, 5U, x, input.prime, input.modulus);
        square = nmod_mul(x, x, input.modulus);
        fourth = nmod_mul(square, square, input.modulus);
        input.values[sample * input.coordinate_count + 1U] = fourth;
        input.values[sample * input.coordinate_count + 2U] = 0U;
    }
    if (!interpolate(&input, 4, &result))
        ok = 0;
    if (ok && (result.status != RESULT_ACCEPTED || result.consumed != 8U
        || result.construction_count != 5U
        || result.coordinates[0].items[0].numerator_degree != 1
        || result.coordinates[0].items[0].denominator_degree != 1
        || result.coordinates[1].items[0].numerator_degree != 4
        || result.coordinates[1].items[0].denominator_degree != 0
        || result.coordinates[2].items[0].numerator_degree != -1
        || result.coordinates[2].items[0].denominator_degree != 0))
        ok = 0;
    for (sample = 0U; ok && sample < input.coordinate_count; ++sample)
        if (!candidate_predicts_all(result.coordinates[sample].items, &input,
                sample))
            ok = 0;
    interpolation_result_clear(&result, input.coordinate_count);

    input.mode = MODE_FIXED_PROFILE;
    input.expected_numerator_degrees = (uint64_t *) malloc(
        input.coordinate_count * sizeof(*input.expected_numerator_degrees));
    input.expected_denominator_degrees = (uint64_t *) malloc(
        input.coordinate_count * sizeof(*input.expected_denominator_degrees));
    if (input.expected_numerator_degrees == NULL
        || input.expected_denominator_degrees == NULL)
        ok = 0;
    if (ok) {
        input.expected_numerator_degrees[0] = 1U;
        input.expected_denominator_degrees[0] = 1U;
        input.expected_numerator_degrees[1] = 4U;
        input.expected_denominator_degrees[1] = 0U;
        input.expected_numerator_degrees[2] = negative_infinity_degree;
        input.expected_denominator_degrees[2] = 0U;
        if (!interpolate(&input, 3, &result))
            ok = 0;
        if (ok && (result.status != RESULT_ACCEPTED || result.consumed != 8U
            || result.construction_count != 5U))
            ok = 0;
        interpolation_result_clear(&result, input.coordinate_count);
    }
    if (ok) {
        input.sample_count = 8U;
        input.values[6U * input.coordinate_count] = nmod_add(
            input.values[6U * input.coordinate_count], 1U, input.modulus);
        if (!interpolate(&input, 2, &result)
            || result.status != RESULT_MORE_SAMPLES
            || result.reason != REASON_GROW_REQUIRED
            || result.construction_count != 7U)
            ok = 0;
        interpolation_result_clear(&result, input.coordinate_count);
    }
    free(input.abscissae);
    free(input.values);
    free(input.expected_numerator_degrees);
    free(input.expected_denominator_degrees);
    input.abscissae = NULL;
    input.values = NULL;
    input.expected_numerator_degrees = NULL;
    input.expected_denominator_degrees = NULL;
    input.sample_count = 26U;
    input.coordinate_count = 1U;
    input.initial_count = 4U;
    input.held_out_count = 3U;
    input.maximum_total_degree = 22U;
    input.mode = MODE_DISCOVERY;
    input.abscissae = (mp_limb_t *) malloc(input.sample_count
        * sizeof(*input.abscissae));
    input.values = (mp_limb_t *) malloc(input.sample_count
        * sizeof(*input.values));
    if (input.abscissae == NULL || input.values == NULL)
        ok = 0;
    if (ok) {
        for (sample = 0U; sample < input.sample_count; ++sample) {
            x = (mp_limb_t) sample + 1U;
            input.abscissae[sample] = x;
            polynomial = 0U;
            for (size_t degree = 23U; degree > 0U; --degree)
                polynomial = nmod_add(nmod_mul(polynomial, x, input.modulus),
                    (mp_limb_t) degree, input.modulus);
            input.values[sample] = polynomial;
        }
        if (!interpolate(&input, 4, &result))
            ok = 0;
        if (ok && (result.status != RESULT_ACCEPTED
            || result.consumed != 26U || result.construction_count != 23U
            || result.coordinates[0].items[0].numerator_degree != 22
            || result.coordinates[0].items[0].denominator_degree != 0
            || !candidate_predicts_all(result.coordinates[0].items, &input,
                0U)))
            ok = 0;
        interpolation_result_clear(&result, input.coordinate_count);
    }
    if (ok) {
        for (sample = 0U; sample < input.sample_count; ++sample) {
            x = (mp_limb_t) sample + 1U;
            polynomial = 0U;
            for (size_t degree = 24U; degree > 0U; --degree)
                polynomial = nmod_add(nmod_mul(polynomial, x, input.modulus),
                    (mp_limb_t) degree, input.modulus);
            input.values[sample] = polynomial;
        }
        if (!interpolate(&input, 4, &result))
            ok = 0;
        if (ok && (result.status != RESULT_MORE_SAMPLES
            || result.reason != REASON_MAXIMUM_DEGREE_EXCEEDED
            || result.required_additional != 0U
            || result.consumed != 24U || result.construction_count != 24U))
            ok = 0;
        interpolation_result_clear(&result, input.coordinate_count);
    }
    interpolation_input_clear(&input);
    printf("{\"self_test\":\"%s\",\"discovery\":\"adaptive\","
        "\"fixed_profile\":true,\"held_out_failure\":true,"
        "\"maximum_degree\":true,\"maximum_degree_rejection\":true,"
        "\"sample_counts\":[8,8,8,26],"
        "\"construction_counts\":[5,5,7,23]}\n",
        ok ? "PASS" : "FAIL");
    return ok;
}

static int parse_threads(const char *text, int *threads)
{
    char *end = NULL;
    long parsed;

    errno = 0;
    parsed = strtol(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || parsed < 1 || parsed > 8)
        return 0;
    *threads = (int) parsed;
    return 1;
}

int main(int argc, char **argv)
{
    interpolation_input_t input;
    interpolation_result_t result;
    int threads = 1, exit_code = 0;
    double started, elapsed;

    if (argc == 2 && strcmp(argv[1], "--self-test") == 0)
        return self_test() ? 0 : 1;
    if (argc < 3 || argc > 4) {
        fprintf(stderr, "usage: %s INPUT.bin OUTPUT.bin [THREADS]\n"
            "       %s --self-test\n", argv[0], argv[0]);
        return 64;
    }
    if (argc == 4 && !parse_threads(argv[3], &threads)) {
        fprintf(stderr, "THREADS must be an integer from 1 through 8\n");
        return 64;
    }
    if (!read_input(argv[1], &input)) {
        fprintf(stderr, "invalid FFRI1 input\n");
        return 65;
    }
    started = omp_get_wtime();
    if (!interpolate(&input, threads, &result))
        exit_code = 70;
    elapsed = omp_get_wtime() - started;
    if (!write_output(argv[2], &input, &result)) {
        fprintf(stderr, "failed to write FFRI1 output\n");
        exit_code = 74;
    }
    printf("{\"backend\":\"FLINT-nmod-rational-interpolate\","
        "\"status\":%u,\"mode\":%u,\"samples\":%zu,"
        "\"coordinates\":%zu,\"consumed\":%zu,"
        "\"construction_count\":%zu,\"threads\":%d,"
        "\"seconds\":%.9f}\n", result.status, input.mode,
        input.sample_count, input.coordinate_count, result.consumed,
        result.construction_count, threads, elapsed);
    interpolation_result_clear(&result, input.coordinate_count);
    interpolation_input_clear(&input);
    return exit_code;
}
