#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <flint/flint.h>
#include <flint/nmod.h>
#include <flint/ulong_extras.h>

/* Native row assembly for the multiquadratic strip data-layout contract. */

#define MQRA_MAX_ROOT_COUNT 3U

typedef struct
{
    mp_limb_t prime;
    nmod_t modulus;
    size_t root_count;
    size_t grade_count;
    size_t upper;
    size_t lower;
    size_t support_count;
    size_t one_form_count;
    size_t point_count;
    size_t row_count;
    size_t basis_transformation_unknown_count;
    size_t residue_unknown_count;
    size_t unknown_count;
    size_t point_stride;
    size_t root_square_offset;
    size_t basis_transformation_denominator_log_offset;
    size_t root_log_offset;
    size_t e_offset;
    size_t c_offset;
    size_t inhomogeneity_offset;
    size_t one_form_offset;
    uint64_t * support;
    mp_limb_t * points;
} mqra_input_t;

typedef struct
{
    const mqra_input_t * input;
    size_t first_point;
    size_t final_point;
    mp_limb_t * rows;
    mp_limb_t * right;
    int failed;
} mqra_worker_t;

static const unsigned char input_magic[8] =
    {'M', 'Q', 'R', 'A', '1', 'V', '1', '\0'};
static const unsigned char output_magic[8] =
    {'M', 'Q', 'R', 'A', '1', 'X', '1', '\0'};

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int checked_add_size(size_t a, size_t b, size_t * result)
{
    if (b > SIZE_MAX - a)
        return 0;
    *result = a + b;
    return 1;
}

static int checked_mul_size(size_t a, size_t b, size_t * result)
{
    if (a != 0U && b > SIZE_MAX / a)
        return 0;
    *result = a * b;
    return 1;
}

static int u64_to_size(uint64_t value, size_t * result)
{
    if (value > (uint64_t) SIZE_MAX)
        return 0;
    *result = (size_t) value;
    return 1;
}

static int read_u64_le(FILE * stream, uint64_t * value)
{
    unsigned char bytes[8];
    unsigned int index;
    uint64_t result = 0U;
    if (fread(bytes, 1U, sizeof(bytes), stream) != sizeof(bytes))
        return 0;
    for (index = 0U; index < 8U; ++index)
        result |= ((uint64_t) bytes[index]) << (8U * index);
    *value = result;
    return 1;
}

static int write_u64_le(FILE * stream, uint64_t value)
{
    unsigned char bytes[8];
    unsigned int index;
    for (index = 0U; index < 8U; ++index)
        bytes[index] = (unsigned char) ((value >> (8U * index)) & UINT64_C(255));
    return fwrite(bytes, 1U, sizeof(bytes), stream) == sizeof(bytes);
}

static int add_product(size_t * total, size_t a, size_t b, size_t c,
    size_t d)
{
    size_t value;
    if (!checked_mul_size(a, b, &value)
        || !checked_mul_size(value, c, &value)
        || !checked_mul_size(value, d, &value)
        || !checked_add_size(*total, value, total))
        return 0;
    return 1;
}

static void clear_input(mqra_input_t * input)
{
    free(input->support);
    free(input->points);
    memset(input, 0, sizeof(*input));
}

static int establish_layout(mqra_input_t * input)
{
    size_t value, stride = 0U;
    input->grade_count = ((size_t) 1U) << input->root_count;
    if (!checked_mul_size(input->upper, input->lower, &value)
        || !checked_mul_size(value, input->grade_count, &value)
        || !checked_mul_size(value, input->support_count,
            &input->basis_transformation_unknown_count)
        || !checked_mul_size(input->one_form_count, input->upper, &value)
        || !checked_mul_size(value, input->lower,
            &input->residue_unknown_count)
        || !checked_add_size(input->basis_transformation_unknown_count,
            input->residue_unknown_count, &input->unknown_count)
        || !checked_mul_size(input->grade_count, 2U, &value)
        || !checked_mul_size(value, input->upper, &value)
        || !checked_mul_size(value, input->lower, &input->row_count))
        return 0;
    if (!checked_add_size(stride, 4U, &stride))
        return 0;
    input->root_square_offset = stride;
    if (!checked_add_size(stride, input->root_count, &stride))
        return 0;
    input->basis_transformation_denominator_log_offset = stride;
    if (!checked_add_size(stride, 2U, &stride))
        return 0;
    input->root_log_offset = stride;
    if (!add_product(&stride, input->root_count, 2U, 1U, 1U))
        return 0;
    input->e_offset = stride;
    if (!add_product(&stride, 2U, input->upper, input->upper,
        input->grade_count))
        return 0;
    input->c_offset = stride;
    if (!add_product(&stride, 2U, input->lower, input->lower,
        input->grade_count))
        return 0;
    input->inhomogeneity_offset = stride;
    if (!add_product(&stride, 2U, input->upper, input->lower,
        input->grade_count))
        return 0;
    input->one_form_offset = stride;
    if (!add_product(&stride, input->one_form_count, 2U,
        input->grade_count, 1U))
        return 0;
    input->point_stride = stride;
    return input->row_count != 0U && input->unknown_count != 0U;
}

static int read_input(const char * path, mqra_input_t * input)
{
    FILE * stream = NULL;
    unsigned char magic[8];
    uint64_t header[7], word;
    size_t index, point_index, word_index, support_words, point_words;
    size_t byte_count;

    memset(input, 0, sizeof(*input));
    stream = fopen(path, "rb");
    if (stream == NULL)
        return 0;
    if (fread(magic, 1U, sizeof(magic), stream) != sizeof(magic)
        || memcmp(magic, input_magic, sizeof(magic)) != 0) {
        fclose(stream);
        return 0;
    }
    for (index = 0U; index < 7U; ++index)
        if (!read_u64_le(stream, header + index)) {
            fclose(stream);
            return 0;
        }
    if (sizeof(mp_limb_t) != sizeof(uint64_t)
        || sizeof(ulong) != sizeof(uint64_t)
        || header[0] < UINT64_C(5) || (header[0] & UINT64_C(1)) == 0U
        || !n_is_prime((mp_limb_t) header[0])
        || header[1] > MQRA_MAX_ROOT_COUNT
        || header[2] == 0U || header[3] == 0U || header[4] == 0U
        || header[6] == 0U
        || !u64_to_size(header[1], &input->root_count)
        || !u64_to_size(header[2], &input->upper)
        || !u64_to_size(header[3], &input->lower)
        || !u64_to_size(header[4], &input->support_count)
        || !u64_to_size(header[5], &input->one_form_count)
        || !u64_to_size(header[6], &input->point_count)
        || !establish_layout(input)) {
        fclose(stream);
        return 0;
    }
    input->prime = (mp_limb_t) header[0];
    nmod_init(&input->modulus, input->prime);
    if (!checked_mul_size(input->support_count, 2U, &support_words)
        || !checked_mul_size(support_words, sizeof(*input->support),
            &byte_count)) {
        fclose(stream);
        return 0;
    }
    input->support = (uint64_t *) malloc(byte_count);
    if (input->support == NULL) {
        fclose(stream);
        return 0;
    }
    for (index = 0U; index < support_words; ++index)
        if (!read_u64_le(stream, input->support + index)) {
            fclose(stream);
            clear_input(input);
            return 0;
        }
    if (!checked_mul_size(input->point_count, input->point_stride, &point_words)
        || !checked_mul_size(point_words, sizeof(*input->points), &byte_count)) {
        fclose(stream);
        clear_input(input);
        return 0;
    }
    input->points = (mp_limb_t *) malloc(byte_count);
    if (input->points == NULL) {
        fclose(stream);
        clear_input(input);
        return 0;
    }
    for (point_index = 0U; point_index < input->point_count; ++point_index)
        for (word_index = 0U; word_index < input->point_stride; ++word_index) {
            if (!read_u64_le(stream, &word) || word >= header[0]
                || ((word_index < 4U
                    || (word_index >= input->root_square_offset
                        && word_index < input->basis_transformation_denominator_log_offset))
                    && word == 0U)) {
                fclose(stream);
                clear_input(input);
                return 0;
            }
            input->points[point_index * input->point_stride + word_index]
                = (mp_limb_t) word;
        }
    if (fgetc(stream) != EOF || ferror(stream) || fclose(stream) != 0) {
        clear_input(input);
        return 0;
    }
    return 1;
}

static size_t basis_transformation_index(const mqra_input_t * input, size_t upper_index,
    size_t lower_index, size_t grade, size_t monomial)
{
    return (((upper_index * input->lower + lower_index) * input->grade_count
        + grade) * input->support_count) + monomial;
}

static size_t row_index(const mqra_input_t * input, size_t target_grade,
    size_t direction, size_t upper_index, size_t lower_index)
{
    return (((target_grade * 2U + direction) * input->upper + upper_index)
        * input->lower) + lower_index;
}

static mp_limb_t e_value(const mqra_input_t * input, const mp_limb_t * point,
    size_t direction, size_t row, size_t column, size_t grade)
{
    size_t index = (((direction * input->upper + row) * input->upper + column)
        * input->grade_count) + grade;
    return point[input->e_offset + index];
}

static mp_limb_t c_value(const mqra_input_t * input, const mp_limb_t * point,
    size_t direction, size_t row, size_t column, size_t grade)
{
    size_t index = (((direction * input->lower + row) * input->lower + column)
        * input->grade_count) + grade;
    return point[input->c_offset + index];
}

static void * assemble_points(void * argument)
{
    mqra_worker_t * worker = (mqra_worker_t *) argument;
    const mqra_input_t * input = worker->input;
    const size_t grade = input->grade_count;
    const size_t support = input->support_count;
    size_t basis_count, derivative_count, weight_count;
    size_t point_index, mask, root, monomial, direction, source_grade;
    size_t target_grade, upper_index, lower_index, coupling_index;
    size_t product_grade, common_grade, row, column, letter;
    mp_limb_t * x_powers = NULL, * y_powers = NULL;
    mp_limb_t * monomial_values = NULL, * delta_factors = NULL;
    mp_limb_t * basis_derivatives = NULL, * product_weights = NULL;
    mp_limb_t * output_row, * point, * point_rows, * point_right;
    mp_limb_t x_inverse, y_inverse, denominator_inverse, half, value, log_value;
    mp_limb_t weight, coefficient, contribution;

    if (!checked_mul_size(grade, support, &basis_count)
        || !checked_mul_size(2U, basis_count, &derivative_count)
        || !checked_mul_size(grade, basis_count, &weight_count)) {
        worker->failed = 1;
        return NULL;
    }
    x_powers = (mp_limb_t *) malloc(support * sizeof(*x_powers));
    y_powers = (mp_limb_t *) malloc(support * sizeof(*y_powers));
    monomial_values = (mp_limb_t *) malloc(support
        * sizeof(*monomial_values));
    delta_factors = (mp_limb_t *) malloc(grade * sizeof(*delta_factors));
    basis_derivatives = (mp_limb_t *) malloc(derivative_count
        * sizeof(*basis_derivatives));
    product_weights = (mp_limb_t *) malloc(weight_count
        * sizeof(*product_weights));
    if (x_powers == NULL || y_powers == NULL || monomial_values == NULL
        || delta_factors == NULL
        || basis_derivatives == NULL || product_weights == NULL) {
        worker->failed = 1;
        goto cleanup;
    }
    half = (mp_limb_t) n_invmod(2U, input->prime);
    for (point_index = worker->first_point;
         point_index < worker->final_point; ++point_index) {
        point = input->points + point_index * input->point_stride;
        point_rows = worker->rows
            + point_index * input->row_count * input->unknown_count;
        point_right = worker->right + point_index * input->row_count;
        x_inverse = (mp_limb_t) n_invmod(point[0], input->prime);
        y_inverse = (mp_limb_t) n_invmod(point[1], input->prime);
        denominator_inverse = (mp_limb_t) n_invmod(point[3], input->prime);
        delta_factors[0] = 1U;
        for (mask = 1U; mask < grade; ++mask) {
            root = 0U;
            while ((mask & (((size_t) 1U) << root)) == 0U)
                root++;
            delta_factors[mask] = nmod_mul(
                delta_factors[mask & ~(((size_t) 1U) << root)],
                point[input->root_square_offset + root], input->modulus);
        }
        for (monomial = 0U; monomial < support; ++monomial) {
            x_powers[monomial] = nmod_pow_ui(point[0],
                (ulong) input->support[2U * monomial], input->modulus);
            y_powers[monomial] = nmod_pow_ui(point[1],
                (ulong) input->support[2U * monomial + 1U], input->modulus);
            monomial_values[monomial] = nmod_mul(nmod_mul(
                x_powers[monomial], y_powers[monomial], input->modulus),
                denominator_inverse, input->modulus);
        }
        for (direction = 0U; direction < 2U; ++direction)
            for (source_grade = 0U; source_grade < grade; ++source_grade)
                for (monomial = 0U; monomial < support; ++monomial) {
                    value = (mp_limb_t) (input->support[2U * monomial
                        + direction] % (uint64_t) input->prime);
                    value = nmod_mul(value,
                        direction == 0U ? x_inverse : y_inverse,
                        input->modulus);
                    log_value = nmod_sub(value,
                        point[input->basis_transformation_denominator_log_offset + direction],
                        input->modulus);
                    for (root = 0U; root < input->root_count; ++root)
                        if ((source_grade & (((size_t) 1U) << root)) != 0U)
                            log_value = nmod_add(log_value,
                                nmod_mul(half, point[input->root_log_offset
                                    + 2U * root + direction], input->modulus),
                                input->modulus);
                    basis_derivatives[(direction * grade + source_grade)
                        * support + monomial] = nmod_mul(
                            monomial_values[monomial], log_value,
                            input->modulus);
                }
        for (target_grade = 0U; target_grade < grade; ++target_grade)
            for (source_grade = 0U; source_grade < grade; ++source_grade) {
                product_grade = target_grade ^ source_grade;
                common_grade = product_grade & source_grade;
                value = nmod_mul(point[2], delta_factors[common_grade],
                    input->modulus);
                for (monomial = 0U; monomial < support; ++monomial)
                    product_weights[(target_grade * grade + source_grade)
                        * support + monomial] = nmod_mul(value,
                            monomial_values[monomial], input->modulus);
            }
        for (target_grade = 0U; target_grade < grade; ++target_grade)
            for (direction = 0U; direction < 2U; ++direction)
                for (upper_index = 0U; upper_index < input->upper; ++upper_index)
                    for (lower_index = 0U; lower_index < input->lower;
                         ++lower_index) {
                        row = row_index(input, target_grade, direction,
                            upper_index, lower_index);
                        output_row = point_rows + row * input->unknown_count;
                        for (monomial = 0U; monomial < support; ++monomial) {
                            contribution = basis_derivatives[
                                (direction * grade + target_grade) * support
                                    + monomial];
                            if (contribution != 0U) {
                                column = basis_transformation_index(input, upper_index,
                                    lower_index, target_grade, monomial);
                                output_row[column] = nmod_add(output_row[column],
                                    contribution, input->modulus);
                            }
                        }
                        for (source_grade = 0U; source_grade < grade;
                             ++source_grade) {
                            product_grade = target_grade ^ source_grade;
                            for (monomial = 0U; monomial < support; ++monomial) {
                                weight = product_weights[(target_grade * grade
                                    + source_grade) * support + monomial];
                                if (weight == 0U)
                                    continue;
                                for (coupling_index = 0U;
                                     coupling_index < input->upper;
                                     ++coupling_index) {
                                    coefficient = e_value(input, point, direction,
                                        upper_index, coupling_index,
                                        product_grade);
                                    if (coefficient != 0U) {
                                        contribution = nmod_mul(weight,
                                            coefficient, input->modulus);
                                        column = basis_transformation_index(input,
                                            coupling_index, lower_index,
                                            source_grade, monomial);
                                        output_row[column] = nmod_sub(
                                            output_row[column], contribution,
                                            input->modulus);
                                    }
                                }
                                for (coupling_index = 0U;
                                     coupling_index < input->lower;
                                     ++coupling_index) {
                                    coefficient = c_value(input, point, direction,
                                        coupling_index, lower_index,
                                        product_grade);
                                    if (coefficient != 0U) {
                                        contribution = nmod_mul(weight,
                                            coefficient, input->modulus);
                                        column = basis_transformation_index(input, upper_index,
                                            coupling_index, source_grade,
                                            monomial);
                                        output_row[column] = nmod_add(
                                            output_row[column], contribution,
                                            input->modulus);
                                    }
                                }
                            }
                        }
                        for (letter = 0U; letter < input->one_form_count;
                             ++letter) {
                            coefficient = point[input->one_form_offset
                                + (letter * 2U + direction) * grade
                                + target_grade];
                            contribution = nmod_mul(point[2], coefficient,
                                input->modulus);
                            if (contribution != 0U) {
                                column = input->basis_transformation_unknown_count
                                    + (letter * input->upper + upper_index)
                                        * input->lower + lower_index;
                                output_row[column] = contribution;
                            }
                        }
                        point_right[row] = point[input->inhomogeneity_offset
                            + ((direction * input->upper + upper_index)
                                * input->lower + lower_index) * grade
                            + target_grade];
                    }
    }
cleanup:
    free(x_powers);
    free(y_powers);
    free(monomial_values);
    free(delta_factors);
    free(basis_derivatives);
    free(product_weights);
    return NULL;
}

static int write_words_le(FILE * stream, const mp_limb_t * values, size_t count)
{
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    return fwrite(values, sizeof(*values), count, stream) == count;
#else
    size_t index;
    for (index = 0U; index < count; ++index)
        if (!write_u64_le(stream, (uint64_t) values[index]))
            return 0;
    return 1;
#endif
}

static int write_output(const char * path, const mqra_input_t * input,
    const mp_limb_t * rows, const mp_limb_t * right, size_t matrix_words,
    size_t right_words)
{
    FILE * stream = fopen(path, "wb");
    int ok;
    if (stream == NULL)
        return 0;
    ok = fwrite(output_magic, 1U, sizeof(output_magic), stream)
            == sizeof(output_magic)
        && write_u64_le(stream, (uint64_t) input->prime)
        && write_u64_le(stream, (uint64_t) input->point_count)
        && write_u64_le(stream, (uint64_t) input->row_count)
        && write_u64_le(stream, (uint64_t) input->unknown_count)
        && write_words_le(stream, rows, matrix_words)
        && write_words_le(stream, right, right_words);
    if (fclose(stream) != 0)
        ok = 0;
    return ok;
}

int main(int argc, char ** argv)
{
    mqra_input_t input;
    mqra_worker_t * workers = NULL;
    pthread_t * thread_ids = NULL;
    mp_limb_t * rows = NULL, * right = NULL;
    char * end = NULL;
    long requested_threads = 1L;
    size_t thread_count, thread_index, points_per_thread, extra_points;
    size_t first_point, matrix_words, right_words, byte_count, launched = 0U;
    int result = 1, worker_failure = 0;
    double total_start, input_start, input_seconds, assembly_start;
    double assembly_seconds, output_start, output_seconds;

    memset(&input, 0, sizeof(input));
    if (argc != 3 && argc != 4) {
        fprintf(stderr, "usage: %s INPUT.bin OUTPUT.bin [THREADS]\n", argv[0]);
        return 2;
    }
    if (argc == 4) {
        errno = 0;
        requested_threads = strtol(argv[3], &end, 10);
        if (errno != 0 || end == argv[3] || *end != '\0'
            || requested_threads < 1L || requested_threads > 8L) {
            fprintf(stderr, "THREADS must be between 1 and 8.\n");
            return 2;
        }
    }
    total_start = wall_seconds();
    input_start = wall_seconds();
    if (!read_input(argv[1], &input)) {
        fprintf(stderr, "invalid or unsafe MQRA input\n");
        return 3;
    }
    input_seconds = wall_seconds() - input_start;
    if (!checked_mul_size(input.point_count, input.row_count, &right_words)
        || !checked_mul_size(right_words, input.unknown_count, &matrix_words)
        || !checked_mul_size(matrix_words, sizeof(*rows), &byte_count))
        goto cleanup;
    rows = (mp_limb_t *) calloc(matrix_words, sizeof(*rows));
    if (rows == NULL
        || !checked_mul_size(right_words, sizeof(*right), &byte_count))
        goto cleanup;
    right = (mp_limb_t *) calloc(right_words, sizeof(*right));
    if (right == NULL)
        goto cleanup;
    thread_count = (size_t) requested_threads;
    if (thread_count > input.point_count)
        thread_count = input.point_count;
    workers = (mqra_worker_t *) calloc(thread_count, sizeof(*workers));
    thread_ids = (pthread_t *) calloc(thread_count, sizeof(*thread_ids));
    if (workers == NULL || thread_ids == NULL)
        goto cleanup;
    points_per_thread = input.point_count / thread_count;
    extra_points = input.point_count % thread_count;
    first_point = 0U;
    assembly_start = wall_seconds();
    for (thread_index = 0U; thread_index < thread_count; ++thread_index) {
        workers[thread_index].input = &input;
        workers[thread_index].first_point = first_point;
        workers[thread_index].final_point = first_point + points_per_thread
            + (thread_index < extra_points ? 1U : 0U);
        first_point = workers[thread_index].final_point;
        workers[thread_index].rows = rows;
        workers[thread_index].right = right;
        if (pthread_create(thread_ids + thread_index, NULL, assemble_points,
            workers + thread_index) != 0)
            break;
        launched++;
    }
    if (launched != thread_count)
        goto join_cleanup;
    for (thread_index = 0U; thread_index < launched; ++thread_index) {
        if (pthread_join(thread_ids[thread_index], NULL) != 0)
            worker_failure = 1;
        if (workers[thread_index].failed != 0)
            worker_failure = 1;
    }
    launched = 0U;
    if (worker_failure != 0)
        goto cleanup;
    assembly_seconds = wall_seconds() - assembly_start;
    output_start = wall_seconds();
    if (!write_output(argv[2], &input, rows, right, matrix_words,
        right_words)) {
        fprintf(stderr, "failed writing MQRA output\n");
        goto cleanup;
    }
    output_seconds = wall_seconds() - output_start;
    printf("{\"backend\":\"FLINT-nmod-row-assemble\","
           "\"prime\":%" PRIu64 ",\"points\":%zu,\"rows\":%zu,"
           "\"unknowns\":%zu,\"threads\":%zu,\"input_seconds\":%.9f,"
           "\"assembly_seconds\":%.9f,\"output_seconds\":%.9f,"
           "\"total_seconds\":%.9f}\n", (uint64_t) input.prime,
        input.point_count, input.row_count, input.unknown_count, thread_count,
        input_seconds, assembly_seconds, output_seconds,
        wall_seconds() - total_start);
    result = 0;
    goto cleanup;

join_cleanup:
    while (launched > 0U) {
        launched--;
        (void) pthread_join(thread_ids[launched], NULL);
    }
cleanup:
    if (result != 0)
        fprintf(stderr, "MQRA assembly failed\n");
    free(workers);
    free(thread_ids);
    free(rows);
    free(right);
    clear_input(&input);
    flint_cleanup();
    return result;
}
