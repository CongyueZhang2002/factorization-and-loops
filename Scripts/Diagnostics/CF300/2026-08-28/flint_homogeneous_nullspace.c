#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <flint/flint.h>
#include <flint/nmod_mat.h>
#include <flint/ulong_extras.h>

#if __FLINT_VERSION != 3 || __FLINT_VERSION_MINOR != 0 || \
    __FLINT_VERSION_PATCHLEVEL != 1
#error "this diagnostic adapter requires FLINT 3.0.1"
#endif

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int read_u64(FILE *stream, uint64_t *value)
{
    return fread(value, sizeof(uint64_t), 1U, stream) == 1U;
}

static int write_u64(FILE *stream, uint64_t value)
{
    return fwrite(&value, sizeof(uint64_t), 1U, stream) == 1U;
}

static int read_matrix(FILE *stream, nmod_mat_t matrix, uint64_t modulus)
{
    slong row, column;
    uint64_t value;
    for (row = 0; row < nmod_mat_nrows(matrix); ++row) {
        for (column = 0; column < nmod_mat_ncols(matrix); ++column) {
            if (!read_u64(stream, &value) || value >= modulus)
                return 0;
            nmod_mat_set_entry(matrix, row, column, (mp_limb_t) value);
        }
    }
    return 1;
}

static int write_matrix(FILE *stream, const nmod_mat_t matrix)
{
    slong row, column;
    for (row = 0; row < nmod_mat_nrows(matrix); ++row)
        for (column = 0; column < nmod_mat_ncols(matrix); ++column)
            if (!write_u64(stream,
                    (uint64_t) nmod_mat_entry(matrix, row, column)))
                return 0;
    return 1;
}

int main(int argc, char **argv)
{
    static const unsigned char input_magic[8] =
        {'F', 'F', 'H', 'N', '1', 'V', '1', '\0'};
    static const unsigned char output_magic[8] =
        {'F', 'F', 'H', 'N', '1', 'X', '1', '\0'};
    unsigned char observed_magic[8], trailing;
    uint64_t rows_u64, columns_u64, modulus_u64;
    slong rows, columns, rank, nullity, i, j, pivot_cursor, free_cursor;
    slong *pivots = NULL, *row_permutation = NULL, *free_columns = NULL;
    int threads = 1, ok = 0;
    FILE *input = NULL, *output = NULL;
    nmod_mat_t matrix, nullspace;
    int matrix_initialized = 0, nullspace_initialized = 0;
    double start, input_seconds, rref_seconds, output_seconds, phase;

    if (sizeof(mp_limb_t) != sizeof(uint64_t) ||
        strcmp(flint_version, "3.0.1") != 0) {
        fprintf(stderr, "requires a 64-bit FLINT 3.0.1 runtime\n");
        return 2;
    }
    if (argc < 3 || argc > 4) {
        fprintf(stderr, "usage: %s INPUT.bin OUTPUT.bin [THREADS]\n", argv[0]);
        return 2;
    }
    if (argc == 4) {
        char *end = NULL;
        long parsed;
        errno = 0;
        parsed = strtol(argv[3], &end, 10);
        if (errno != 0 || end == argv[3] || *end != '\0' ||
            parsed < 1 || parsed > 64)
            return 2;
        threads = (int) parsed;
    }
    flint_set_num_threads(threads);
    start = wall_seconds();
    phase = wall_seconds();
    input = fopen(argv[1], "rb");
    if (input == NULL ||
        fread(observed_magic, 1U, 8U, input) != 8U ||
        memcmp(observed_magic, input_magic, 8U) != 0 ||
        !read_u64(input, &rows_u64) || !read_u64(input, &columns_u64) ||
        !read_u64(input, &modulus_u64) || rows_u64 == 0 ||
        columns_u64 == 0 || rows_u64 > (uint64_t) LONG_MAX ||
        columns_u64 > (uint64_t) LONG_MAX ||
        modulus_u64 > (uint64_t) ULONG_MAX ||
        !n_is_prime((ulong) modulus_u64)) {
        fprintf(stderr, "invalid input header\n");
        goto cleanup;
    }
    rows = (slong) rows_u64;
    columns = (slong) columns_u64;
    nmod_mat_init(matrix, rows, columns, (mp_limb_t) modulus_u64);
    matrix_initialized = 1;
    if (!read_matrix(input, matrix, modulus_u64) ||
        fread(&trailing, 1U, 1U, input) != 0U || ferror(input)) {
        fprintf(stderr, "invalid matrix payload\n");
        goto cleanup;
    }
    fclose(input);
    input = NULL;
    input_seconds = wall_seconds() - phase;

    pivots = calloc((size_t) (rows < columns ? rows : columns),
        sizeof(slong));
    row_permutation = calloc((size_t) rows, sizeof(slong));
    free_columns = calloc((size_t) columns, sizeof(slong));
    if (pivots == NULL || row_permutation == NULL || free_columns == NULL) {
        fprintf(stderr, "allocation failure\n");
        goto cleanup;
    }
    phase = wall_seconds();
    rank = _nmod_mat_rref(matrix, pivots, row_permutation);
    rref_seconds = wall_seconds() - phase;
    if (rank < 0 || rank > (rows < columns ? rows : columns)) {
        fprintf(stderr, "invalid rank\n");
        goto cleanup;
    }
    nullity = columns - rank;
    for (i = pivot_cursor = free_cursor = 0; i < columns; ++i) {
        if (pivot_cursor < rank && pivots[pivot_cursor] == i)
            ++pivot_cursor;
        else
            free_columns[free_cursor++] = i;
    }
    if (pivot_cursor != rank || free_cursor != nullity) {
        fprintf(stderr, "invalid pivot partition\n");
        goto cleanup;
    }
    nmod_mat_init(nullspace, nullity, columns, (mp_limb_t) modulus_u64);
    nullspace_initialized = 1;
    nmod_mat_zero(nullspace);
    for (j = 0; j < nullity; ++j) {
        nmod_mat_set_entry(nullspace, j, free_columns[j], 1);
        for (i = 0; i < rank; ++i) {
            mp_limb_t value = nmod_mat_entry(matrix, i, free_columns[j]);
            nmod_mat_set_entry(nullspace, j, pivots[i],
                value == 0 ? 0 : (mp_limb_t) (modulus_u64 - value));
        }
    }

    phase = wall_seconds();
    output = fopen(argv[2], "wb");
    if (output == NULL ||
        fwrite(output_magic, 1U, 8U, output) != 8U ||
        !write_u64(output, rows_u64) || !write_u64(output, columns_u64) ||
        !write_u64(output, modulus_u64) ||
        !write_u64(output, (uint64_t) rank) ||
        !write_u64(output, (uint64_t) nullity) ||
        !write_matrix(output, nullspace) || fclose(output) != 0) {
        output = NULL;
        fprintf(stderr, "output failure\n");
        goto cleanup;
    }
    output = NULL;
    output_seconds = wall_seconds() - phase;
    printf("{\"rows\":%" PRIu64 ",\"columns\":%" PRIu64
           ",\"rank\":%ld,\"nullity\":%ld,\"threads\":%d"
           ",\"input_seconds\":%.9f,\"rref_seconds\":%.9f"
           ",\"output_seconds\":%.9f,\"total_seconds\":%.9f}\n",
        rows_u64, columns_u64, (long) rank, (long) nullity, threads,
        input_seconds, rref_seconds, output_seconds, wall_seconds() - start);
    ok = 1;

cleanup:
    if (input != NULL)
        fclose(input);
    if (output != NULL)
        fclose(output);
    if (nullspace_initialized)
        nmod_mat_clear(nullspace);
    if (matrix_initialized)
        nmod_mat_clear(matrix);
    free(pivots);
    free(row_permutation);
    free(free_columns);
    flint_cleanup_master();
    return ok ? 0 : 3;
}
