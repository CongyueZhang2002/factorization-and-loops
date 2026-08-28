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

/*
 * External A4 benchmark helper.  This is not a package dependency or
 * integration proposal.  It reads a square constrained core and all right-
 * hand sides from a deliberately simple little-endian binary stream, solves
 * them in one FLINT nmod_mat_solve call, verifies A.X == B, optionally writes
 * X, and prints one JSON record with transfer and compute timings.
 *
 * Input format (all unsigned 64-bit little-endian words):
 *   magic[8] = "CFFA4V1\0"
 *   rows, columns, rhs_columns, modulus
 *   A row-major, then B row-major.
 *
 * Solution format:
 *   magic[8] = "CFFA4X1\0"
 *   rows, rhs_columns, modulus
 *   X row-major.
 */

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int read_u64(FILE *stream, uint64_t *value)
{
    return fread(value, sizeof(uint64_t), 1, stream) == 1;
}

static int write_u64(FILE *stream, uint64_t value)
{
    return fwrite(&value, sizeof(uint64_t), 1, stream) == 1;
}

static int read_matrix_rows(FILE *stream, nmod_mat_t matrix)
{
    slong row;
    const size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row)
        if (fread(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns)
            return 0;
    return 1;
}

static int write_matrix_rows(FILE *stream, const nmod_mat_t matrix)
{
    slong row;
    const size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row)
        if (fwrite(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns)
            return 0;
    return 1;
}

int main(int argc, char **argv)
{
    static const unsigned char input_magic[8] =
        {'C', 'F', 'F', 'A', '4', 'V', '1', '\0'};
    static const unsigned char output_magic[8] =
        {'C', 'F', 'F', 'A', '4', 'X', '1', '\0'};
    unsigned char observed_magic[8];
    uint64_t rows_u64, columns_u64, rhs_columns_u64, modulus_u64;
    slong rows, columns, rhs_columns;
    int threads = 1;
    int solved = 0, verified = 0, wrote_solution = 0;
    FILE *input = NULL, *output = NULL;
    nmod_mat_t A, B, X, AX;
    double total_start, input_start, input_seconds;
    double solve_start, solve_seconds, verify_start, verify_seconds;
    double output_start, output_seconds = 0.0, total_seconds;

    if (sizeof(mp_limb_t) != sizeof(uint64_t)) {
        fprintf(stderr, "This benchmark requires a 64-bit FLINT limb.\n");
        return 2;
    }
    if (argc < 2 || argc > 4) {
        fprintf(stderr,
            "usage: %s INPUT.bin [SOLUTION.bin|-] [THREADS]\n", argv[0]);
        return 2;
    }
    if (argc == 4) {
        threads = atoi(argv[3]);
        if (threads < 1 || threads > 8) {
            fprintf(stderr, "THREADS must be between 1 and 8.\n");
            return 2;
        }
    }

    flint_set_num_threads(threads);
    total_start = wall_seconds();
    input_start = wall_seconds();
    input = fopen(argv[1], "rb");
    if (input == NULL) {
        fprintf(stderr, "cannot open %s: %s\n", argv[1], strerror(errno));
        return 3;
    }
    if (fread(observed_magic, 1, sizeof(observed_magic), input)
          != sizeof(observed_magic) ||
        memcmp(observed_magic, input_magic, sizeof(input_magic)) != 0 ||
        !read_u64(input, &rows_u64) ||
        !read_u64(input, &columns_u64) ||
        !read_u64(input, &rhs_columns_u64) ||
        !read_u64(input, &modulus_u64)) {
        fprintf(stderr, "invalid or truncated A4 input header\n");
        fclose(input);
        return 4;
    }
    if (rows_u64 == 0 || rows_u64 != columns_u64 ||
        rhs_columns_u64 == 0 || rows_u64 > (uint64_t) WORD_MAX ||
        rhs_columns_u64 > (uint64_t) WORD_MAX || modulus_u64 < 5) {
        fprintf(stderr, "invalid A4 dimensions or modulus\n");
        fclose(input);
        return 4;
    }
    rows = (slong) rows_u64;
    columns = (slong) columns_u64;
    rhs_columns = (slong) rhs_columns_u64;
    nmod_mat_init(A, rows, columns, (mp_limb_t) modulus_u64);
    nmod_mat_init(B, rows, rhs_columns, (mp_limb_t) modulus_u64);
    nmod_mat_init(X, columns, rhs_columns, (mp_limb_t) modulus_u64);
    nmod_mat_init(AX, rows, rhs_columns, (mp_limb_t) modulus_u64);
    if (!read_matrix_rows(input, A) || !read_matrix_rows(input, B)) {
        fprintf(stderr, "truncated A4 matrix payload\n");
        fclose(input);
        nmod_mat_clear(A); nmod_mat_clear(B);
        nmod_mat_clear(X); nmod_mat_clear(AX);
        return 4;
    }
    if (fclose(input) != 0) {
        fprintf(stderr, "failed closing A4 input\n");
        nmod_mat_clear(A); nmod_mat_clear(B);
        nmod_mat_clear(X); nmod_mat_clear(AX);
        return 4;
    }
    input_seconds = wall_seconds() - input_start;

    solve_start = wall_seconds();
    solved = nmod_mat_solve(X, A, B);
    solve_seconds = wall_seconds() - solve_start;

    verify_start = wall_seconds();
    if (solved) {
        nmod_mat_mul(AX, A, X);
        verified = nmod_mat_equal(AX, B);
    }
    verify_seconds = wall_seconds() - verify_start;

    if (argc >= 3 && strcmp(argv[2], "-") != 0) {
        output_start = wall_seconds();
        output = fopen(argv[2], "wb");
        if (output != NULL &&
            fwrite(output_magic, 1, sizeof(output_magic), output)
              == sizeof(output_magic) &&
            write_u64(output, (uint64_t) columns) &&
            write_u64(output, (uint64_t) rhs_columns) &&
            write_u64(output, modulus_u64) &&
            write_matrix_rows(output, X) && fclose(output) == 0) {
            wrote_solution = 1;
        } else {
            if (output != NULL) fclose(output);
            fprintf(stderr, "failed writing solution file\n");
        }
        output_seconds = wall_seconds() - output_start;
    }

    total_seconds = wall_seconds() - total_start;
    printf("{\"backend\":\"FLINT-nmod_mat_solve\","
           "\"rows\":%" PRIu64 ",\"columns\":%" PRIu64 ","
           "\"rhs_columns\":%" PRIu64 ",\"modulus\":%" PRIu64 ","
           "\"threads\":%d,\"input_seconds\":%.9f,"
           "\"solve_seconds\":%.9f,\"verify_seconds\":%.9f,"
           "\"output_seconds\":%.9f,\"total_seconds\":%.9f,"
           "\"solved\":%s,\"verified\":%s,"
           "\"wrote_solution\":%s}\n",
           rows_u64, columns_u64, rhs_columns_u64, modulus_u64, threads,
           input_seconds, solve_seconds, verify_seconds, output_seconds,
           total_seconds, solved ? "true" : "false",
           verified ? "true" : "false",
           wrote_solution ? "true" : "false");

    nmod_mat_clear(A); nmod_mat_clear(B);
    nmod_mat_clear(X); nmod_mat_clear(AX);
    flint_cleanup();
    return (solved && verified) ? 0 : 5;
}
