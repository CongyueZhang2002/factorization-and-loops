#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include <flint/flint.h>
#include <flint/nmod_mat.h>
#include <flint/ulong_extras.h>

/*
 * External, version-pinned rectangular affine RREF helper.
 *
 * This program deliberately uses FLINT 3.0.1's internal _nmod_mat_rref
 * entry point because the public wrapper does not return pivot and row
 * permutations.  The exact FLINT version is checked both at compile time
 * and at run time.  This protocol is separate from CFFA4.
 *
 * Every integer in the wire format is an explicitly encoded unsigned
 * 64-bit little-endian word.  See PROTOCOL.md for the complete contract.
 */

#if __FLINT_VERSION != 3 || __FLINT_VERSION_MINOR != 0 || \
    __FLINT_VERSION_PATCHLEVEL != 1
#error "flint_affine_rref requires the FLINT 3.0.1 headers"
#endif

enum {
    EXIT_USAGE = 2,
    EXIT_IO = 3,
    EXIT_PROTOCOL = 4,
    EXIT_INCONSISTENT = 5,
    EXIT_INTERNAL = 6,
    EXIT_OUTPUT = 7
};

static const unsigned char INPUT_MAGIC[8] =
    {'C', 'F', 'F', 'R', '1', 'V', '1', '\0'};
static const unsigned char OUTPUT_MAGIC[8] =
    {'C', 'F', 'F', 'R', '1', 'X', '1', '\0'};

typedef struct {
    uint64_t rows;
    uint64_t columns;
    uint64_t rhs_columns;
    uint64_t modulus;
    uint64_t preference_count;
    uint64_t flags;
    uint64_t nonce_hi;
    uint64_t nonce_lo;
    uint64_t payload_words;
} input_header_t;

typedef struct {
    uint64_t rows;
    uint64_t columns;
    uint64_t rhs_columns;
    uint64_t modulus;
    uint64_t rank;
    uint64_t nullity;
    uint64_t preference_count;
    uint64_t flags;
    uint64_t nonce_hi;
    uint64_t nonce_lo;
    uint64_t payload_words;
} output_header_t;

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int checked_add_u64(uint64_t a, uint64_t b, uint64_t *out)
{
    if (a > UINT64_MAX - b)
        return 0;
    *out = a + b;
    return 1;
}

static int checked_mul_u64(uint64_t a, uint64_t b, uint64_t *out)
{
    if (a != 0 && b > UINT64_MAX / a)
        return 0;
    *out = a * b;
    return 1;
}

static int read_exact(FILE *stream, void *buffer, size_t bytes)
{
    return bytes == 0 || fread(buffer, 1, bytes, stream) == bytes;
}

static int write_exact(FILE *stream, const void *buffer, size_t bytes)
{
    return bytes == 0 || fwrite(buffer, 1, bytes, stream) == bytes;
}

static int read_u64_le(FILE *stream, uint64_t *value)
{
    unsigned char b[8];
    unsigned int i;
    uint64_t x = 0;
    if (!read_exact(stream, b, sizeof(b)))
        return 0;
    for (i = 0; i < 8; ++i)
        x |= ((uint64_t) b[i]) << (8U * i);
    *value = x;
    return 1;
}

static int write_u64_le(FILE *stream, uint64_t value)
{
    unsigned char b[8];
    unsigned int i;
    for (i = 0; i < 8; ++i)
        b[i] = (unsigned char) ((value >> (8U * i)) & UINT64_C(0xff));
    return write_exact(stream, b, sizeof(b));
}

static int read_input_header(FILE *stream, input_header_t *h)
{
    unsigned char magic[8];
    return read_exact(stream, magic, sizeof(magic)) &&
           memcmp(magic, INPUT_MAGIC, sizeof(magic)) == 0 &&
           read_u64_le(stream, &h->rows) &&
           read_u64_le(stream, &h->columns) &&
           read_u64_le(stream, &h->rhs_columns) &&
           read_u64_le(stream, &h->modulus) &&
           read_u64_le(stream, &h->preference_count) &&
           read_u64_le(stream, &h->flags) &&
           read_u64_le(stream, &h->nonce_hi) &&
           read_u64_le(stream, &h->nonce_lo) &&
           read_u64_le(stream, &h->payload_words);
}

static int write_output_header(FILE *stream, const output_header_t *h)
{
    return write_exact(stream, OUTPUT_MAGIC, sizeof(OUTPUT_MAGIC)) &&
           write_u64_le(stream, h->rows) &&
           write_u64_le(stream, h->columns) &&
           write_u64_le(stream, h->rhs_columns) &&
           write_u64_le(stream, h->modulus) &&
           write_u64_le(stream, h->rank) &&
           write_u64_le(stream, h->nullity) &&
           write_u64_le(stream, h->preference_count) &&
           write_u64_le(stream, h->flags) &&
           write_u64_le(stream, h->nonce_hi) &&
           write_u64_le(stream, h->nonce_lo) &&
           write_u64_le(stream, h->payload_words);
}

static void *checked_calloc(size_t count, size_t size)
{
    if (count == 0)
        return NULL;
    if (size != 0 && count > SIZE_MAX / size)
        return NULL;
    return calloc(count, size);
}

static int compare_slong(const void *lhs, const void *rhs)
{
    const slong a = *(const slong *) lhs;
    const slong b = *(const slong *) rhs;
    return (a > b) - (a < b);
}

static int matrix_is_identity(const nmod_mat_t matrix)
{
    slong i, j;
    if (nmod_mat_nrows(matrix) != nmod_mat_ncols(matrix))
        return 0;
    for (i = 0; i < nmod_mat_nrows(matrix); ++i)
        for (j = 0; j < nmod_mat_ncols(matrix); ++j)
            if (nmod_mat_entry(matrix, i, j) != (mp_limb_t) (i == j))
                return 0;
    return 1;
}

static int verify_two_sided_inverse(const nmod_mat_t matrix,
                                    const nmod_mat_t inverse)
{
    nmod_mat_t left, right;
    int ok;
    const slong n = nmod_mat_nrows(matrix);
    if (n != nmod_mat_ncols(matrix) ||
        n != nmod_mat_nrows(inverse) || n != nmod_mat_ncols(inverse))
        return 0;
    nmod_mat_init(left, n, n, matrix->mod.n);
    nmod_mat_init(right, n, n, matrix->mod.n);
    nmod_mat_mul(left, matrix, inverse);
    nmod_mat_mul(right, inverse, matrix);
    ok = matrix_is_identity(left) && matrix_is_identity(right);
    nmod_mat_clear(left);
    nmod_mat_clear(right);
    return ok;
}

static int verify_affine_data(const nmod_mat_t A, const nmod_mat_t b,
                              const nmod_mat_t particular,
                              const nmod_mat_t nullspace,
                              const slong *free_columns)
{
    nmod_mat_t ap, nt, an;
    slong i, j;
    int ok = 1;
    const slong rows = nmod_mat_nrows(A);
    const slong columns = nmod_mat_ncols(A);
    const slong nullity = nmod_mat_nrows(nullspace);

    nmod_mat_init(ap, rows, 1, A->mod.n);
    nmod_mat_mul(ap, A, particular);
    ok = nmod_mat_equal(ap, b);
    nmod_mat_clear(ap);
    if (!ok)
        return 0;

    nmod_mat_init(nt, columns, nullity, A->mod.n);
    nmod_mat_init(an, rows, nullity, A->mod.n);
    nmod_mat_transpose(nt, nullspace);
    nmod_mat_mul(an, A, nt);
    ok = nmod_mat_is_zero(an);
    nmod_mat_clear(nt);
    nmod_mat_clear(an);
    if (!ok)
        return 0;

    for (i = 0; i < nullity; ++i) {
        if (nmod_mat_entry(particular, free_columns[i], 0) != 0)
            return 0;
        for (j = 0; j < nullity; ++j)
            if (nmod_mat_entry(nullspace, i, free_columns[j]) !=
                (mp_limb_t) (i == j))
                return 0;
    }
    return 1;
}

static int write_slong_vector(FILE *stream, const slong *values, slong count)
{
    slong i;
    for (i = 0; i < count; ++i)
        if (values[i] < 0 || !write_u64_le(stream, (uint64_t) values[i]))
            return 0;
    return 1;
}

static int write_nmod_matrix(FILE *stream, const nmod_mat_t matrix)
{
    slong i, j;
    for (i = 0; i < nmod_mat_nrows(matrix); ++i)
        for (j = 0; j < nmod_mat_ncols(matrix); ++j)
            if (!write_u64_le(stream,
                              (uint64_t) nmod_mat_entry(matrix, i, j)))
                return 0;
    return 1;
}

static char *make_temp_template(const char *output_path)
{
    static const char suffix[] = ".tmp.XXXXXX";
    const size_t path_length = strlen(output_path);
    char *result;
    if (path_length > SIZE_MAX - sizeof(suffix))
        return NULL;
    result = (char *) malloc(path_length + sizeof(suffix));
    if (result == NULL)
        return NULL;
    memcpy(result, output_path, path_length);
    memcpy(result + path_length, suffix, sizeof(suffix));
    return result;
}

static int write_output_atomic(const char *output_path,
                               const output_header_t *header,
                               const slong *pivot_columns,
                               const slong *free_columns,
                               const slong *independent_rows,
                               const slong *normalization_columns,
                               const nmod_mat_t particular,
                               const nmod_mat_t nullspace,
                               const nmod_mat_t row_minor_inverse,
                               const nmod_mat_t normalization_minor_inverse)
{
    char *temp_path = make_temp_template(output_path);
    FILE *stream = NULL;
    int descriptor = -1;
    int ok = 0;

    if (temp_path == NULL)
        return 0;
    descriptor = mkstemp(temp_path);
    if (descriptor < 0)
        goto cleanup;
    stream = fdopen(descriptor, "wb");
    if (stream == NULL)
        goto cleanup;
    descriptor = -1;

    ok = write_output_header(stream, header) &&
         write_slong_vector(stream, pivot_columns, (slong) header->rank) &&
         write_slong_vector(stream, free_columns, (slong) header->nullity) &&
         write_slong_vector(stream, independent_rows, (slong) header->rank) &&
         write_slong_vector(stream, normalization_columns,
                            (slong) header->nullity) &&
         write_nmod_matrix(stream, particular) &&
         write_nmod_matrix(stream, nullspace) &&
         write_nmod_matrix(stream, row_minor_inverse) &&
         write_nmod_matrix(stream, normalization_minor_inverse);

    if (ok && (fflush(stream) != 0 || fsync(fileno(stream)) != 0))
        ok = 0;
    if (fclose(stream) != 0)
        ok = 0;
    stream = NULL;
    if (!ok)
        goto cleanup;
    if (rename(temp_path, output_path) != 0) {
        ok = 0;
        goto cleanup;
    }
    ok = 1;

cleanup:
    if (stream != NULL)
        fclose(stream);
    if (descriptor >= 0)
        close(descriptor);
    if (!ok)
        unlink(temp_path);
    free(temp_path);
    return ok;
}

static int input_file_size_is_exact(FILE *stream, uint64_t payload_words)
{
    struct stat status;
    uint64_t payload_bytes, expected_bytes;
    const uint64_t header_bytes = UINT64_C(8) + UINT64_C(9) * UINT64_C(8);
    if (fstat(fileno(stream), &status) != 0 || !S_ISREG(status.st_mode) ||
        status.st_size < 0 ||
        !checked_mul_u64(payload_words, UINT64_C(8), &payload_bytes) ||
        !checked_add_u64(header_bytes, payload_bytes, &expected_bytes) ||
        expected_bytes > (uint64_t) INT64_MAX)
        return 0;
    return (uint64_t) status.st_size == expected_bytes;
}

static int output_aliases_open_input(FILE *input, const char *output_path)
{
    struct stat input_status, output_status;
    if (fstat(fileno(input), &input_status) != 0)
        return -1;
    if (stat(output_path, &output_status) != 0)
        return errno == ENOENT ? 0 : -1;
    return input_status.st_dev == output_status.st_dev &&
           input_status.st_ino == output_status.st_ino;
}

int main(int argc, char **argv)
{
    input_header_t input_header;
    output_header_t output_header;
    FILE *input = NULL;
    unsigned char trailing;
    unsigned char *preference_seen = NULL;
    slong *preference = NULL, *augmented_pivots = NULL, *row_permutation = NULL;
    slong *pivot_columns = NULL, *free_columns = NULL;
    slong *independent_rows = NULL, *normalization_columns = NULL;
    slong *preference_pivots = NULL, *preference_row_permutation = NULL;
    slong rows, columns, rank, nullity, augmented_rank, preference_rank;
    slong i, j, pivot_cursor, free_count;
    uint64_t matrix_words, expected_payload_words, output_payload_words;
    uint64_t term, value;
    int threads = 1;
    int exit_code = EXIT_INTERNAL;
    int matrices_initialized = 0;
    int rank_matrices_initialized = 0;
    int nullity_matrices_initialized = 0;
    double start_seconds, rref_seconds, witness_construction_seconds;
    double verification_seconds, output_seconds;
    nmod_mat_t A, b, augmented, particular, nullspace;
    nmod_mat_t row_minor, row_minor_inverse;
    nmod_mat_t preference_matrix, normalization_minor;
    nmod_mat_t normalization_minor_inverse;

    if (sizeof(mp_limb_t) != sizeof(uint64_t) || sizeof(ulong) != 8 ||
        sizeof(slong) != 8 || strcmp(flint_version, "3.0.1") != 0) {
        fprintf(stderr, "requires a 64-bit FLINT 3.0.1 runtime\n");
        return EXIT_USAGE;
    }
    if (argc < 3 || argc > 4) {
        fprintf(stderr, "usage: %s INPUT.bin OUTPUT.bin [THREADS]\n", argv[0]);
        return EXIT_USAGE;
    }
    if (strcmp(argv[1], argv[2]) == 0) {
        fprintf(stderr, "input and output paths must differ\n");
        return EXIT_USAGE;
    }
    if (argc == 4) {
        char *end = NULL;
        long parsed;
        errno = 0;
        parsed = strtol(argv[3], &end, 10);
        if (errno != 0 || end == argv[3] || *end != '\0' ||
            parsed < 1 || parsed > 64) {
            fprintf(stderr, "THREADS must be a decimal integer from 1 to 64\n");
            return EXIT_USAGE;
        }
        threads = (int) parsed;
    }

    flint_set_num_threads(threads);
    start_seconds = wall_seconds();
    input = fopen(argv[1], "rb");
    if (input == NULL) {
        fprintf(stderr, "cannot open input: %s\n", strerror(errno));
        exit_code = EXIT_IO;
        goto cleanup;
    }
    {
        const int aliases = output_aliases_open_input(input, argv[2]);
        if (aliases != 0) {
            if (aliases > 0)
                fprintf(stderr,
                        "input and output paths reference the same file\n");
            else
                fprintf(stderr, "cannot inspect output path: %s\n",
                        strerror(errno));
            exit_code = aliases > 0 ? EXIT_USAGE : EXIT_IO;
            goto cleanup;
        }
    }
    if (!read_input_header(input, &input_header)) {
        fprintf(stderr, "invalid or truncated CFFR1 input header\n");
        exit_code = EXIT_PROTOCOL;
        goto cleanup;
    }
    if (input_header.rows == 0 || input_header.columns == 0 ||
        input_header.rows > (uint64_t) LONG_MAX ||
        input_header.columns > (uint64_t) LONG_MAX ||
        input_header.rhs_columns != 1 ||
        input_header.preference_count != input_header.columns ||
        input_header.flags != 0 ||
        (input_header.nonce_hi == 0 && input_header.nonce_lo == 0) ||
        input_header.modulus > (uint64_t) ULONG_MAX ||
        !n_is_prime((ulong) input_header.modulus)) {
        fprintf(stderr, "invalid CFFR1 dimensions, flags, or prime modulus\n");
        exit_code = EXIT_PROTOCOL;
        goto cleanup;
    }
    if (!checked_mul_u64(input_header.rows, input_header.columns,
                         &matrix_words) ||
        !checked_add_u64(matrix_words, input_header.rows,
                         &expected_payload_words) ||
        !checked_add_u64(expected_payload_words, input_header.columns,
                         &expected_payload_words) ||
        input_header.payload_words != expected_payload_words ||
        !input_file_size_is_exact(input, input_header.payload_words)) {
        fprintf(stderr, "invalid CFFR1 payload length or overflow\n");
        exit_code = EXIT_PROTOCOL;
        goto cleanup;
    }

    rows = (slong) input_header.rows;
    columns = (slong) input_header.columns;
    preference = (slong *) checked_calloc((size_t) columns, sizeof(slong));
    preference_seen = (unsigned char *) checked_calloc((size_t) columns, 1);
    augmented_pivots = (slong *) checked_calloc((size_t) columns + 1,
                                                sizeof(slong));
    row_permutation = (slong *) checked_calloc((size_t) rows, sizeof(slong));
    pivot_columns = (slong *) checked_calloc((size_t) columns, sizeof(slong));
    free_columns = (slong *) checked_calloc((size_t) columns, sizeof(slong));
    independent_rows = (slong *) checked_calloc((size_t) rows, sizeof(slong));
    normalization_columns = (slong *) checked_calloc((size_t) columns,
                                                      sizeof(slong));
    preference_pivots = (slong *) checked_calloc((size_t) columns,
                                                 sizeof(slong));
    preference_row_permutation = (slong *) checked_calloc((size_t) columns,
                                                          sizeof(slong));
    if (preference == NULL || preference_seen == NULL ||
        augmented_pivots == NULL || row_permutation == NULL ||
        pivot_columns == NULL || free_columns == NULL ||
        independent_rows == NULL || normalization_columns == NULL ||
        preference_pivots == NULL || preference_row_permutation == NULL) {
        fprintf(stderr, "allocation failure\n");
        exit_code = EXIT_IO;
        goto cleanup;
    }

    nmod_mat_init(A, rows, columns, (mp_limb_t) input_header.modulus);
    nmod_mat_init(b, rows, 1, (mp_limb_t) input_header.modulus);
    nmod_mat_init(augmented, rows, columns + 1,
                  (mp_limb_t) input_header.modulus);
    matrices_initialized = 1;

    for (i = 0; i < rows; ++i) {
        for (j = 0; j < columns; ++j) {
            if (!read_u64_le(input, &value) || value >= input_header.modulus) {
                fprintf(stderr, "invalid or truncated matrix entry\n");
                exit_code = EXIT_PROTOCOL;
                goto cleanup;
            }
            nmod_mat_set_entry(A, i, j, (mp_limb_t) value);
            nmod_mat_set_entry(augmented, i, j, (mp_limb_t) value);
        }
    }
    for (i = 0; i < rows; ++i) {
        if (!read_u64_le(input, &value) || value >= input_header.modulus) {
            fprintf(stderr, "invalid or truncated right-hand side entry\n");
            exit_code = EXIT_PROTOCOL;
            goto cleanup;
        }
        nmod_mat_set_entry(b, i, 0, (mp_limb_t) value);
        nmod_mat_set_entry(augmented, i, columns, (mp_limb_t) value);
    }
    for (i = 0; i < columns; ++i) {
        if (!read_u64_le(input, &value) || value >= input_header.columns ||
            preference_seen[value]) {
            fprintf(stderr, "normalization preference is not a permutation\n");
            exit_code = EXIT_PROTOCOL;
            goto cleanup;
        }
        preference[i] = (slong) value;
        preference_seen[value] = 1;
    }
    if (fread(&trailing, 1, 1, input) != 0 || ferror(input)) {
        fprintf(stderr, "trailing or unreadable CFFR1 input data\n");
        exit_code = EXIT_PROTOCOL;
        goto cleanup;
    }
    if (fclose(input) != 0) {
        input = NULL;
        fprintf(stderr, "failed closing input\n");
        exit_code = EXIT_IO;
        goto cleanup;
    }
    input = NULL;

    rref_seconds = wall_seconds();
    augmented_rank = _nmod_mat_rref(augmented, augmented_pivots,
                                    row_permutation);
    rref_seconds = wall_seconds() - rref_seconds;
    witness_construction_seconds = wall_seconds();
    if (augmented_rank < 0 || augmented_rank > columns + 1) {
        fprintf(stderr, "FLINT returned an invalid augmented rank\n");
        exit_code = EXIT_INTERNAL;
        goto cleanup;
    }
    for (i = 0; i < augmented_rank; ++i) {
        if (augmented_pivots[i] == columns) {
            fprintf(stderr, "affine system is inconsistent\n");
            exit_code = EXIT_INCONSISTENT;
            goto cleanup;
        }
    }
    rank = augmented_rank;
    if (rank > columns) {
        fprintf(stderr, "affine system is inconsistent\n");
        exit_code = EXIT_INCONSISTENT;
        goto cleanup;
    }
    nullity = columns - rank;
    for (i = 0; i < rank; ++i) {
        pivot_columns[i] = augmented_pivots[i];
        if (pivot_columns[i] < 0 || pivot_columns[i] >= columns ||
            (i > 0 && pivot_columns[i - 1] >= pivot_columns[i])) {
            fprintf(stderr, "FLINT returned invalid pivot indices\n");
            exit_code = EXIT_INTERNAL;
            goto cleanup;
        }
    }
    for (i = pivot_cursor = free_count = 0; i < columns; ++i) {
        if (pivot_cursor < rank && pivot_columns[pivot_cursor] == i)
            ++pivot_cursor;
        else
            free_columns[free_count++] = i;
    }
    if (pivot_cursor != rank || free_count != nullity) {
        fprintf(stderr, "pivot/free partition is invalid\n");
        exit_code = EXIT_INTERNAL;
        goto cleanup;
    }
    for (i = 0; i < rank; ++i) {
        independent_rows[i] = row_permutation[i];
        if (independent_rows[i] < 0 || independent_rows[i] >= rows) {
            fprintf(stderr, "FLINT returned invalid independent-row indices\n");
            exit_code = EXIT_INTERNAL;
            goto cleanup;
        }
    }
    qsort(independent_rows, (size_t) rank, sizeof(slong), compare_slong);
    for (i = 1; i < rank; ++i) {
        if (independent_rows[i - 1] == independent_rows[i]) {
            fprintf(stderr, "FLINT returned duplicate independent rows\n");
            exit_code = EXIT_INTERNAL;
            goto cleanup;
        }
    }

    nmod_mat_init(particular, columns, 1, (mp_limb_t) input_header.modulus);
    nmod_mat_init(nullspace, nullity, columns,
                  (mp_limb_t) input_header.modulus);
    nmod_mat_zero(particular);
    nmod_mat_zero(nullspace);
    for (i = 0; i < rank; ++i)
        nmod_mat_set_entry(particular, pivot_columns[i], 0,
                           nmod_mat_entry(augmented, i, columns));
    for (j = 0; j < nullity; ++j) {
        nmod_mat_set_entry(nullspace, j, free_columns[j], 1);
        for (i = 0; i < rank; ++i) {
            value = (uint64_t) nmod_mat_entry(augmented, i, free_columns[j]);
            nmod_mat_set_entry(nullspace, j, pivot_columns[i],
                value == 0 ? 0 : (mp_limb_t) (input_header.modulus - value));
        }
    }

    nmod_mat_init(row_minor, rank, rank, (mp_limb_t) input_header.modulus);
    nmod_mat_init(row_minor_inverse, rank, rank,
                  (mp_limb_t) input_header.modulus);
    rank_matrices_initialized = 1;
    for (i = 0; i < rank; ++i)
        for (j = 0; j < rank; ++j)
            nmod_mat_set_entry(row_minor, i, j,
                nmod_mat_entry(A, independent_rows[i], pivot_columns[j]));
    if (rank > 0 && !nmod_mat_inv(row_minor_inverse, row_minor)) {
        fprintf(stderr, "independent-row witness minor is singular\n");
        exit_code = EXIT_INTERNAL;
        goto cleanup;
    }

    nmod_mat_init(preference_matrix, nullity, columns,
                  (mp_limb_t) input_header.modulus);
    nmod_mat_init(normalization_minor, nullity, nullity,
                  (mp_limb_t) input_header.modulus);
    nmod_mat_init(normalization_minor_inverse, nullity, nullity,
                  (mp_limb_t) input_header.modulus);
    nullity_matrices_initialized = 1;
    for (i = 0; i < nullity; ++i)
        for (j = 0; j < columns; ++j)
            nmod_mat_set_entry(preference_matrix, i, j,
                               nmod_mat_entry(nullspace, i, preference[j]));
    if (nullity > 0) {
        preference_rank = _nmod_mat_rref(preference_matrix,
                                        preference_pivots,
                                        preference_row_permutation);
        if (preference_rank != nullity) {
            fprintf(stderr, "normalization preference lost nullspace rank\n");
            exit_code = EXIT_INTERNAL;
            goto cleanup;
        }
        for (j = 0; j < nullity; ++j)
            normalization_columns[j] = preference[preference_pivots[j]];
        /* The preference determines the greedy set; wire order is canonical. */
        qsort(normalization_columns, (size_t) nullity, sizeof(slong),
              compare_slong);
        for (j = 0; j < nullity; ++j) {
            if (normalization_columns[j] < 0 ||
                normalization_columns[j] >= columns ||
                (j > 0 && normalization_columns[j - 1] >=
                          normalization_columns[j])) {
                fprintf(stderr, "FLINT returned invalid normalization indices\n");
                exit_code = EXIT_INTERNAL;
                goto cleanup;
            }
        }
        for (i = 0; i < nullity; ++i)
            for (j = 0; j < nullity; ++j)
                nmod_mat_set_entry(normalization_minor, i, j,
                    nmod_mat_entry(nullspace, i, normalization_columns[j]));
        if (!nmod_mat_inv(normalization_minor_inverse, normalization_minor)) {
            fprintf(stderr, "normalization witness minor is singular\n");
            exit_code = EXIT_INTERNAL;
            goto cleanup;
        }
    }

    witness_construction_seconds =
        wall_seconds() - witness_construction_seconds;
    verification_seconds = wall_seconds();
    if (!verify_affine_data(A, b, particular, nullspace, free_columns) ||
        (rank > 0 && !verify_two_sided_inverse(row_minor,
                                               row_minor_inverse)) ||
        (nullity > 0 && !verify_two_sided_inverse(
                           normalization_minor,
                           normalization_minor_inverse))) {
        fprintf(stderr, "internal affine or inverse-witness verification failed\n");
        exit_code = EXIT_INTERNAL;
        goto cleanup;
    }
    verification_seconds = wall_seconds() - verification_seconds;

    output_payload_words = 0;
    if (!checked_add_u64(output_payload_words, (uint64_t) rank,
                         &output_payload_words) ||
        !checked_add_u64(output_payload_words, (uint64_t) nullity,
                         &output_payload_words) ||
        !checked_add_u64(output_payload_words, (uint64_t) rank,
                         &output_payload_words) ||
        !checked_add_u64(output_payload_words, (uint64_t) nullity,
                         &output_payload_words) ||
        !checked_add_u64(output_payload_words, (uint64_t) columns,
                         &output_payload_words) ||
        !checked_mul_u64((uint64_t) nullity, (uint64_t) columns, &term) ||
        !checked_add_u64(output_payload_words, term, &output_payload_words) ||
        !checked_mul_u64((uint64_t) rank, (uint64_t) rank, &term) ||
        !checked_add_u64(output_payload_words, term, &output_payload_words) ||
        !checked_mul_u64((uint64_t) nullity, (uint64_t) nullity, &term) ||
        !checked_add_u64(output_payload_words, term, &output_payload_words)) {
        fprintf(stderr, "output payload size overflow\n");
        exit_code = EXIT_INTERNAL;
        goto cleanup;
    }
    output_header.rows = input_header.rows;
    output_header.columns = input_header.columns;
    output_header.rhs_columns = 1;
    output_header.modulus = input_header.modulus;
    output_header.rank = (uint64_t) rank;
    output_header.nullity = (uint64_t) nullity;
    output_header.preference_count = input_header.preference_count;
    output_header.flags = 0;
    output_header.nonce_hi = input_header.nonce_hi;
    output_header.nonce_lo = input_header.nonce_lo;
    output_header.payload_words = output_payload_words;

    output_seconds = wall_seconds();
    if (!write_output_atomic(argv[2], &output_header, pivot_columns,
                             free_columns, independent_rows,
                             normalization_columns, particular, nullspace,
                             row_minor_inverse,
                             normalization_minor_inverse)) {
        fprintf(stderr, "failed atomic output write: %s\n", strerror(errno));
        exit_code = EXIT_OUTPUT;
        goto cleanup;
    }
    output_seconds = wall_seconds() - output_seconds;

    printf("{\"backend\":\"FLINT-_nmod_mat_rref-3.0.1\"," \
           "\"rows\":%" PRIu64 ",\"columns\":%" PRIu64 "," \
           "\"rank\":%ld,\"nullity\":%ld,\"modulus\":%" PRIu64 "," \
           "\"threads\":%d,\"rref_seconds\":%.9f," \
           "\"witness_construction_seconds\":%.9f," \
           "\"verification_seconds\":%.9f,\"output_seconds\":%.9f," \
           "\"total_seconds\":%.9f,\"verified\":true}\n",
           input_header.rows, input_header.columns, (long) rank,
           (long) nullity, input_header.modulus, threads, rref_seconds,
           witness_construction_seconds, verification_seconds, output_seconds,
           wall_seconds() - start_seconds);
    exit_code = 0;

cleanup:
    if (input != NULL)
        fclose(input);
    if (nullity_matrices_initialized) {
        nmod_mat_clear(preference_matrix);
        nmod_mat_clear(normalization_minor);
        nmod_mat_clear(normalization_minor_inverse);
    }
    if (rank_matrices_initialized) {
        nmod_mat_clear(row_minor);
        nmod_mat_clear(row_minor_inverse);
        nmod_mat_clear(particular);
        nmod_mat_clear(nullspace);
    }
    if (matrices_initialized) {
        nmod_mat_clear(A);
        nmod_mat_clear(b);
        nmod_mat_clear(augmented);
    }
    free(preference);
    free(preference_seen);
    free(augmented_pivots);
    free(row_permutation);
    free(pivot_columns);
    free(free_columns);
    free(independent_rows);
    free(normalization_columns);
    free(preference_pivots);
    free(preference_row_permutation);
    flint_cleanup();
    return exit_code;
}
