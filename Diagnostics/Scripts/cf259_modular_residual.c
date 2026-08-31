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

/* One production-style acceptance operation: exact A*x=b arithmetic at a
   random modular point.  No symbolic simplification or intermediate guards. */

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static int read_u64(FILE *stream, uint64_t *value)
{
    return fread(value, sizeof(uint64_t), 1, stream) == 1;
}

static int read_matrix(FILE *stream, nmod_mat_t matrix)
{
    slong row;
    size_t columns = (size_t) nmod_mat_ncols(matrix);
    for (row = 0; row < nmod_mat_nrows(matrix); ++row)
        if (fread(matrix->rows[row], sizeof(mp_limb_t), columns, stream)
              != columns) return 0;
    return 1;
}

int main(int argc, char **argv)
{
    static const unsigned char expected_magic[7] =
        {'C','F','K','0','V','1','\0'};
    unsigned char magic[7];
    uint64_t rows_u64, columns_u64, modulus_u64;
    slong rows, columns, row, defects = 0;
    int threads = 1;
    FILE *stream;
    nmod_mat_t A, b, x, product;
    double start, read_done, multiply_done;

    if (argc < 2 || argc > 3) {
        fprintf(stderr, "usage: %s SAMPLE.bin [THREADS]\n", argv[0]);
        return 2;
    }
    if (argc == 3) {
        threads = atoi(argv[2]);
        if (threads < 1 || threads > 16) return 2;
    }
    flint_set_num_threads(threads);
    start = wall_seconds();
    stream = fopen(argv[1], "rb");
    if (stream == NULL ||
        fread(magic, 1, sizeof(magic), stream) != sizeof(magic) ||
        memcmp(magic, expected_magic, sizeof(magic)) != 0 ||
        !read_u64(stream, &rows_u64) || !read_u64(stream, &columns_u64) ||
        !read_u64(stream, &modulus_u64) || rows_u64 == 0 ||
        columns_u64 == 0 || rows_u64 > (uint64_t) WORD_MAX ||
        columns_u64 > (uint64_t) WORD_MAX || modulus_u64 < 5) {
        fprintf(stderr, "invalid residual input header\n");
        if (stream != NULL) fclose(stream);
        return 3;
    }
    rows = (slong) rows_u64;
    columns = (slong) columns_u64;
    nmod_mat_init(A, rows, columns, (mp_limb_t) modulus_u64);
    nmod_mat_init(b, rows, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(x, columns, 1, (mp_limb_t) modulus_u64);
    nmod_mat_init(product, rows, 1, (mp_limb_t) modulus_u64);
    if (!read_matrix(stream, A) || !read_matrix(stream, b) ||
        !read_matrix(stream, x) || fclose(stream) != 0) {
        fprintf(stderr, "truncated residual input payload\n");
        return 3;
    }
    read_done = wall_seconds();
    nmod_mat_mul(product, A, x);
    for (row = 0; row < rows; ++row)
        if (nmod_mat_entry(product, row, 0) != nmod_mat_entry(b, row, 0))
            ++defects;
    multiply_done = wall_seconds();
    printf("{\"status\":\"%s\",\"rows\":%" PRIu64
           ",\"columns\":%" PRIu64 ",\"defects\":%ld"
           ",\"read_seconds\":%.6f,\"multiply_seconds\":%.6f"
           ",\"total_seconds\":%.6f}\n",
           defects == 0 ? "accepted" : "rejected", rows_u64, columns_u64,
           (long) defects, read_done - start, multiply_done - read_done,
           multiply_done - start);
    nmod_mat_clear(A); nmod_mat_clear(b); nmod_mat_clear(x);
    nmod_mat_clear(product); flint_cleanup_master();
    return defects == 0 ? 0 : 4;
}
