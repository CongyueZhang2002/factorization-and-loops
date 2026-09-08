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

static int read_matrix_rows(FILE *stream, nmod_mat_t matrix)
{
    slong row;
    size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row) {
        if (fread(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns)
            return 0;
    }
    return 1;
}

static int write_matrix_rows(FILE *stream, const nmod_mat_t matrix)
{
    slong row;
    size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row) {
        if (fwrite(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns)
            return 0;
    }
    return 1;
}

int main(int argc, char **argv)
{
    static const unsigned char input_magic[8] =
        {'F', 'F', 'S', 'R', '1', 'V', '1', '\0'};
    static const unsigned char output_magic[8] =
        {'F', 'F', 'S', 'R', '1', 'X', '1', '\0'};
    unsigned char observed_magic[8];
    uint64_t rows_u64, gauge_columns_u64, residue_columns_u64;
    uint64_t core_rows_u64, modulus_u64, index_u64;
    slong rows, gauge_columns, residue_columns, core_rows, remainder_rows;
    slong total_columns, augmented_columns, row, column, core_index;
    slong remainder_index, rank_s, rank_augmented;
    int threads = 1;
    int solved, verified, ok = 0;
    unsigned char *is_core = NULL;
    slong *core_indices = NULL;
    FILE *input = NULL, *output = NULL;
    nmod_mat_t A, B, G_core, B_core, X, check, G_remainder;
    nmod_mat_t B_remainder, product, schur, rank_matrix;
    double total_start, input_start, input_seconds, copy_seconds;
    double solve_start, solve_seconds, multiply_start, multiply_seconds;
    double rank_start, rank_seconds, output_start, output_seconds;

    if (sizeof(mp_limb_t) != sizeof(uint64_t)) {
        fprintf(stderr, "requires 64-bit FLINT limbs\n");
        return 2;
    }
    if (argc != 4) {
        fprintf(stderr, "usage: %s INPUT.bin OUTPUT.bin THREADS\n", argv[0]);
        return 2;
    }
    threads = atoi(argv[3]);
    if (threads < 1 || threads > 8) {
        fprintf(stderr, "THREADS must be in 1..8\n");
        return 2;
    }
    flint_set_num_threads(threads);
    total_start = wall_seconds();
    input_start = wall_seconds();
    input = fopen(argv[1], "rb");
    if (input == NULL) {
        fprintf(stderr, "cannot open %s: %s\n", argv[1], strerror(errno));
        return 3;
    }
    if (fread(observed_magic, 1U, sizeof(observed_magic), input)
          != sizeof(observed_magic) ||
        memcmp(observed_magic, input_magic, sizeof(input_magic)) != 0 ||
        !read_u64(input, &rows_u64) ||
        !read_u64(input, &gauge_columns_u64) ||
        !read_u64(input, &residue_columns_u64) ||
        !read_u64(input, &core_rows_u64) ||
        !read_u64(input, &modulus_u64)) {
        fprintf(stderr, "invalid input header\n");
        fclose(input);
        return 4;
    }
    if (rows_u64 == 0U || gauge_columns_u64 == 0U ||
        residue_columns_u64 == 0U || core_rows_u64 != gauge_columns_u64 ||
        rows_u64 <= core_rows_u64 || rows_u64 > (uint64_t) WORD_MAX ||
        gauge_columns_u64 > (uint64_t) WORD_MAX ||
        residue_columns_u64 > (uint64_t) WORD_MAX || modulus_u64 < 5U) {
        fprintf(stderr, "invalid dimensions or modulus\n");
        fclose(input);
        return 4;
    }
    rows = (slong) rows_u64;
    gauge_columns = (slong) gauge_columns_u64;
    residue_columns = (slong) residue_columns_u64;
    core_rows = (slong) core_rows_u64;
    remainder_rows = rows - core_rows;
    total_columns = gauge_columns + residue_columns;
    augmented_columns = residue_columns + 1;
    is_core = (unsigned char *) calloc((size_t) rows, sizeof(*is_core));
    core_indices = (slong *) malloc((size_t) core_rows * sizeof(*core_indices));
    if (is_core == NULL || core_indices == NULL) {
        fprintf(stderr, "allocation failure\n");
        fclose(input);
        free(is_core); free(core_indices);
        return 6;
    }
    for (core_index = 0; core_index < core_rows; ++core_index) {
        if (!read_u64(input, &index_u64) || index_u64 >= rows_u64 ||
            is_core[index_u64] != 0U) {
            fprintf(stderr, "invalid core row index\n");
            fclose(input);
            free(is_core); free(core_indices);
            return 4;
        }
        core_indices[core_index] = (slong) index_u64;
        is_core[index_u64] = 1U;
    }
    nmod_mat_init(A, rows, total_columns, (mp_limb_t) modulus_u64);
    nmod_mat_init(B, rows, 1, (mp_limb_t) modulus_u64);
    if (!read_matrix_rows(input, A) || !read_matrix_rows(input, B) ||
        fclose(input) != 0) {
        fprintf(stderr, "truncated matrix payload\n");
        nmod_mat_clear(A); nmod_mat_clear(B);
        free(is_core); free(core_indices);
        return 4;
    }
    input = NULL;
    input_seconds = wall_seconds() - input_start;

    input_start = wall_seconds();
    nmod_mat_init(G_core, core_rows, gauge_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(B_core, core_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(X, gauge_columns, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(check, core_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(G_remainder, remainder_rows, gauge_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(B_remainder, remainder_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(product, remainder_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_init(schur, remainder_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    for (core_index = 0; core_index < core_rows; ++core_index) {
        row = core_indices[core_index];
        for (column = 0; column < gauge_columns; ++column)
            nmod_mat_entry(G_core, core_index, column) =
                nmod_mat_entry(A, row, column);
        for (column = 0; column < residue_columns; ++column)
            nmod_mat_entry(B_core, core_index, column) =
                nmod_mat_entry(A, row, gauge_columns + column);
        nmod_mat_entry(B_core, core_index, residue_columns) =
            nmod_mat_entry(B, row, 0);
    }
    remainder_index = 0;
    for (row = 0; row < rows; ++row) {
        if (is_core[row] != 0U)
            continue;
        for (column = 0; column < gauge_columns; ++column)
            nmod_mat_entry(G_remainder, remainder_index, column) =
                nmod_mat_entry(A, row, column);
        for (column = 0; column < residue_columns; ++column)
            nmod_mat_entry(B_remainder, remainder_index, column) =
                nmod_mat_entry(A, row, gauge_columns + column);
        nmod_mat_entry(B_remainder, remainder_index, residue_columns) =
            nmod_mat_entry(B, row, 0);
        ++remainder_index;
    }
    copy_seconds = wall_seconds() - input_start;

    solve_start = wall_seconds();
    solved = nmod_mat_solve(X, G_core, B_core);
    solve_seconds = wall_seconds() - solve_start;
    if (!solved) {
        fprintf(stderr, "gauge core is singular\n");
        goto cleanup;
    }
    nmod_mat_mul(check, G_core, X);
    verified = nmod_mat_equal(check, B_core);
    if (!verified) {
        fprintf(stderr, "gauge solve residual nonzero\n");
        goto cleanup;
    }

    multiply_start = wall_seconds();
    nmod_mat_mul(product, G_remainder, X);
    nmod_mat_sub(schur, B_remainder, product);
    multiply_seconds = wall_seconds() - multiply_start;

    rank_start = wall_seconds();
    nmod_mat_init(rank_matrix, remainder_rows, residue_columns,
        (mp_limb_t) modulus_u64);
    for (row = 0; row < remainder_rows; ++row)
        for (column = 0; column < residue_columns; ++column)
            nmod_mat_entry(rank_matrix, row, column) =
                nmod_mat_entry(schur, row, column);
    rank_s = nmod_mat_rank(rank_matrix);
    nmod_mat_clear(rank_matrix);
    nmod_mat_init(rank_matrix, remainder_rows, augmented_columns,
        (mp_limb_t) modulus_u64);
    nmod_mat_set(rank_matrix, schur);
    rank_augmented = nmod_mat_rank(rank_matrix);
    nmod_mat_clear(rank_matrix);
    rank_seconds = wall_seconds() - rank_start;

    output_start = wall_seconds();
    output = fopen(argv[2], "wb");
    if (output == NULL ||
        fwrite(output_magic, 1U, sizeof(output_magic), output)
          != sizeof(output_magic) ||
        !write_u64(output, (uint64_t) remainder_rows) ||
        !write_u64(output, (uint64_t) augmented_columns) ||
        !write_u64(output, modulus_u64) ||
        !write_u64(output, (uint64_t) rank_s) ||
        !write_u64(output, (uint64_t) rank_augmented) ||
        !write_matrix_rows(output, schur) || fclose(output) != 0) {
        if (output != NULL) fclose(output);
        fprintf(stderr, "failed writing output\n");
        goto cleanup;
    }
    output = NULL;
    output_seconds = wall_seconds() - output_start;
    ok = 1;
    printf("{\"backend\":\"FLINT-Schur\",\"rows\":%" PRIu64
           ",\"gauge_columns\":%" PRIu64
           ",\"residue_columns\":%" PRIu64
           ",\"remainder_rows\":%ld,\"rank_s\":%ld"
           ",\"rank_augmented\":%ld,\"threads\":%d"
           ",\"input_seconds\":%.9f,\"copy_seconds\":%.9f"
           ",\"solve_seconds\":%.9f,\"multiply_seconds\":%.9f"
           ",\"rank_seconds\":%.9f,\"output_seconds\":%.9f"
           ",\"total_seconds\":%.9f}\n",
        rows_u64, gauge_columns_u64, residue_columns_u64,
        remainder_rows, rank_s, rank_augmented, threads,
        input_seconds, copy_seconds, solve_seconds, multiply_seconds,
        rank_seconds, output_seconds, wall_seconds() - total_start);

cleanup:
    nmod_mat_clear(A); nmod_mat_clear(B);
    nmod_mat_clear(G_core); nmod_mat_clear(B_core);
    nmod_mat_clear(X); nmod_mat_clear(check);
    nmod_mat_clear(G_remainder); nmod_mat_clear(B_remainder);
    nmod_mat_clear(product); nmod_mat_clear(schur);
    free(is_core); free(core_indices);
    flint_cleanup();
    return ok ? 0 : 5;
}
