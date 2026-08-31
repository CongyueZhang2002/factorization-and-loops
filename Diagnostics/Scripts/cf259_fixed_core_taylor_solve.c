#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <flint/flint.h>
#include <flint/nmod.h>
#include <flint/nmod_mat.h>

/* Solve (K0 + z K1) X(z) = H(z) coefficient by coefficient.  K0 is
   factorized once; every subsequent coefficient is one matrix-vector product
   and two triangular solves.  Coefficient streams are coefficient-major. */

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

static int read_matrix(FILE *stream, nmod_mat_t matrix)
{
    slong row;
    size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row)
        if (fread(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns)
            return 0;
    return 1;
}

static int read_core(const char *path, const unsigned char expected[7],
                     nmod_mat_t matrix, uint64_t n_expected,
                     uint64_t modulus_expected)
{
    unsigned char magic[7];
    uint64_t rows, columns, modulus;
    FILE *stream = fopen(path, "rb");
    int ok;
    if (stream == NULL) {
        fprintf(stderr, "cannot open %s: %s\n", path, strerror(errno));
        return 0;
    }
    ok = fread(magic, 1, sizeof(magic), stream) == sizeof(magic) &&
         memcmp(magic, expected, sizeof(magic)) == 0 &&
         read_u64(stream, &rows) && read_u64(stream, &columns) &&
         read_u64(stream, &modulus) && rows == n_expected &&
         columns == n_expected && modulus == modulus_expected &&
         read_matrix(stream, matrix) && fclose(stream) == 0;
    if (!ok) {
        fprintf(stderr, "invalid or truncated core file: %s\n", path);
        fclose(stream);
    }
    return ok;
}

int main(int argc, char **argv)
{
    static const unsigned char base_magic[7] =
        {'C','F','K','0','B','1','\0'};
    static const unsigned char slope_magic[7] =
        {'C','F','K','0','S','1','\0'};
    static const unsigned char rhs_magic[7] =
        {'C','F','K','0','T','1','\0'};
    static const unsigned char output_magic[7] =
        {'C','F','K','0','Y','1','\0'};
    unsigned char magic[7];
    uint64_t n_u64, order_u64, modulus_u64;
    slong n, order, coefficient, row, rank;
    int threads = 1, ok = 0;
    uint64_t center_u64 = 1;
    FILE *input = NULL, *output = NULL;
    mp_limb_t *h = NULL, *x = NULL;
    slong *permutation = NULL;
    nmod_mat_t K0, K1, LU, previous, product, right, permuted, solution;
    double start, read_done, lu_done, recurrence_done, write_done;

    if (sizeof(mp_limb_t) != sizeof(uint64_t)) {
        fprintf(stderr, "requires 64-bit FLINT limbs\n");
        return 2;
    }
    if (argc < 5 || argc > 7) {
        fprintf(stderr, "usage: %s BASE_AT_EPS1 SLOPE RHS_TAYLOR OUTPUT"
                        " [THREADS] [CENTER_MOD]\n",
                argv[0]);
        return 2;
    }
    if (argc == 6) {
        threads = atoi(argv[5]);
        if (threads < 1 || threads > 16) {
            fprintf(stderr, "THREADS must be in 1..16\n");
            return 2;
        }
    }
    if (argc == 7) {
        threads = atoi(argv[5]);
        if (threads < 1 || threads > 16) {
            fprintf(stderr, "THREADS must be in 1..16\n");
            return 2;
        }
        center_u64 = strtoull(argv[6], NULL, 10);
    }
    flint_set_num_threads(threads);
    start = wall_seconds();
    input = fopen(argv[3], "rb");
    if (input == NULL ||
        fread(magic, 1, sizeof(magic), input) != sizeof(magic) ||
        memcmp(magic, rhs_magic, sizeof(magic)) != 0 ||
        !read_u64(input, &n_u64) || !read_u64(input, &order_u64) ||
        !read_u64(input, &modulus_u64) || n_u64 == 0 || order_u64 == 0 ||
        n_u64 > (uint64_t) WORD_MAX || order_u64 > (uint64_t) WORD_MAX ||
        modulus_u64 < 5) {
        fprintf(stderr, "invalid Taylor RHS header\n");
        if (input != NULL) fclose(input);
        return 3;
    }
    n = (slong) n_u64;
    order = (slong) order_u64;
    h = (mp_limb_t *) flint_malloc((size_t) n * (size_t) order *
                                    sizeof(mp_limb_t));
    x = (mp_limb_t *) flint_calloc((size_t) n * (size_t) order,
                                   sizeof(mp_limb_t));
    permutation = (slong *) flint_malloc((size_t) n * sizeof(slong));
    if (fread(h, sizeof(mp_limb_t), (size_t) n * (size_t) order, input)
          != (size_t) n * (size_t) order || fclose(input) != 0)
        goto cleanup_early;
    input = NULL;

    nmod_mat_init(K0, n, n, (mp_limb_t) modulus_u64);
    nmod_mat_init(K1, n, n, (mp_limb_t) modulus_u64);
    nmod_mat_init(LU, n, n, (mp_limb_t) modulus_u64);
    nmod_mat_init(previous, n, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(product, n, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(right, n, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(permuted, n, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(solution, n, 1, (mp_limb_t) modulus_u64);
    if (!read_core(argv[1], base_magic, K0, n_u64, modulus_u64) ||
        !read_core(argv[2], slope_magic, K1, n_u64, modulus_u64))
        goto cleanup;
    if (center_u64 >= modulus_u64) {
        fprintf(stderr, "CENTER_MOD must be below the modulus\n");
        goto cleanup;
    }
    if (center_u64 != 1) {
        mp_limb_t delta = nmod_sub((mp_limb_t) center_u64, 1, K0->mod);
        for (row = 0; row < n; ++row) {
            slong column;
            for (column = 0; column < n; ++column)
                nmod_mat_entry(K0, row, column) = nmod_add(
                    nmod_mat_entry(K0, row, column),
                    nmod_mul(delta, nmod_mat_entry(K1, row, column),
                             K0->mod), K0->mod);
        }
    }
    read_done = wall_seconds();

    nmod_mat_set(LU, K0);
    for (row = 0; row < n; ++row)
        permutation[row] = row;
    rank = nmod_mat_lu(permutation, LU, 1);
    if (rank != n) {
        fprintf(stderr, "K0 is singular: rank %ld of %ld\n",
                (long) rank, (long) n);
        goto cleanup;
    }
    lu_done = wall_seconds();

    for (coefficient = 0; coefficient < order; ++coefficient) {
        if (coefficient > 0) {
            for (row = 0; row < n; ++row)
                nmod_mat_entry(previous, row, 0) =
                    x[(size_t) (coefficient - 1) * (size_t) n + (size_t) row];
            nmod_mat_mul(product, K1, previous);
        }
        for (row = 0; row < n; ++row) {
            mp_limb_t value = h[(size_t) coefficient * (size_t) n +
                                (size_t) row];
            if (coefficient > 0)
                value = nmod_sub(value, nmod_mat_entry(product, row, 0),
                                 K0->mod);
            nmod_mat_entry(right, row, 0) = value;
        }
        for (row = 0; row < n; ++row)
            nmod_mat_entry(permuted, row, 0) =
                nmod_mat_entry(right, permutation[row], 0);
        nmod_mat_solve_tril(solution, LU, permuted, 1);
        nmod_mat_solve_triu(solution, LU, solution, 0);
        for (row = 0; row < n; ++row)
            x[(size_t) coefficient * (size_t) n + (size_t) row] =
                nmod_mat_entry(solution, row, 0);
    }
    recurrence_done = wall_seconds();

    output = fopen(argv[4], "wb");
    if (output == NULL ||
        fwrite(output_magic, 1, sizeof(output_magic), output)
          != sizeof(output_magic) || !write_u64(output, n_u64) ||
        !write_u64(output, order_u64) || !write_u64(output, modulus_u64) ||
        fwrite(x, sizeof(mp_limb_t), (size_t) n * (size_t) order, output)
          != (size_t) n * (size_t) order || fclose(output) != 0) {
        fprintf(stderr, "failed writing %s\n", argv[4]);
        if (output != NULL) fclose(output);
        output = NULL;
        goto cleanup;
    }
    output = NULL;
    write_done = wall_seconds();
    printf("{\"status\":\"ok\",\"dimension\":%" PRIu64
           ",\"order\":%" PRIu64 ",\"threads\":%d"
           ",\"center_mod\":%" PRIu64
           ",\"read_seconds\":%.6f,\"lu_seconds\":%.6f"
           ",\"recurrence_seconds\":%.6f,\"write_seconds\":%.6f"
           ",\"total_seconds\":%.6f}\n",
           n_u64, order_u64, threads, center_u64,
           read_done - start, lu_done - read_done,
           recurrence_done - lu_done, write_done - recurrence_done,
           write_done - start);
    ok = 1;

cleanup:
    nmod_mat_clear(K0); nmod_mat_clear(K1); nmod_mat_clear(LU);
    nmod_mat_clear(previous); nmod_mat_clear(product); nmod_mat_clear(right);
    nmod_mat_clear(permuted); nmod_mat_clear(solution);
cleanup_early:
    if (input != NULL) fclose(input);
    if (output != NULL) fclose(output);
    flint_free(h); flint_free(x); flint_free(permutation);
    flint_cleanup_master();
    return ok ? 0 : 4;
}
