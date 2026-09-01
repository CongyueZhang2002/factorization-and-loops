#define _POSIX_C_SOURCE 200809L

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <flint/nmod_mat.h>
#include <flint/ulong_extras.h>

/* Generic square modular solve used by the targeted CF303 q3 sampler.

   Request NMSL1V1: magic[8], prime, dimension, rhs_count, followed by the
   row-major A matrix and row-major B matrix as uint64 little endian words.
   Response NMSL1X1: magic[8], status, prime, dimension, rhs_count, followed
   by row-major X satisfying A X = B. */

static int read_u64(FILE *stream, uint64_t *value)
{
    unsigned char bytes[8];
    unsigned int i;
    uint64_t result = 0;
    if (fread(bytes, 1, 8, stream) != 8)
        return 0;
    for (i = 0; i < 8; ++i)
        result |= ((uint64_t) bytes[i]) << (8 * i);
    *value = result;
    return 1;
}

static int write_u64(FILE *stream, uint64_t value)
{
    unsigned char bytes[8];
    unsigned int i;
    for (i = 0; i < 8; ++i)
        bytes[i] = (unsigned char) (value >> (8 * i));
    return fwrite(bytes, 1, 8, stream) == 8;
}

int main(int argc, char **argv)
{
    FILE *input = NULL, *output = NULL;
    uint64_t prime, dimension, rhs_count, value;
    slong i, j, n, rhs;
    nmod_mat_t matrix, right, solution;
    int initialized = 0, solved = 0, exit_code = 1;

    if (argc != 3) {
        fprintf(stderr, "usage: %s REQUEST.bin RESPONSE.bin\n", argv[0]);
        return 2;
    }
    input = fopen(argv[1], "rb");
    if (input == NULL)
        goto cleanup;
    {
        unsigned char magic[8];
        if (fread(magic, 1, 8, input) != 8 ||
            memcmp(magic, "NMSL1V1\0", 8) != 0 ||
            !read_u64(input, &prime) ||
            !read_u64(input, &dimension) ||
            !read_u64(input, &rhs_count) ||
            dimension == 0 || dimension > 256 ||
            rhs_count == 0 || rhs_count > 64 ||
            !n_is_prime((ulong) prime))
            goto cleanup;
    }
    n = (slong) dimension;
    rhs = (slong) rhs_count;
    nmod_mat_init(matrix, n, n, (mp_limb_t) prime);
    nmod_mat_init(right, n, rhs, (mp_limb_t) prime);
    nmod_mat_init(solution, n, rhs, (mp_limb_t) prime);
    initialized = 1;
    for (i = 0; i < n; ++i)
        for (j = 0; j < n; ++j) {
            if (!read_u64(input, &value) || value >= prime)
                goto cleanup;
            nmod_mat_set_entry(matrix, i, j, (mp_limb_t) value);
        }
    for (i = 0; i < n; ++i)
        for (j = 0; j < rhs; ++j) {
            if (!read_u64(input, &value) || value >= prime)
                goto cleanup;
            nmod_mat_set_entry(right, i, j, (mp_limb_t) value);
        }
    if (fgetc(input) != EOF)
        goto cleanup;
    solved = nmod_mat_solve(solution, matrix, right);

    output = fopen(argv[2], "wb");
    if (output == NULL ||
        fwrite("NMSL1X1\0", 1, 8, output) != 8 ||
        !write_u64(output, solved ? 0 : 1) ||
        !write_u64(output, prime) ||
        !write_u64(output, dimension) ||
        !write_u64(output, rhs_count))
        goto cleanup;
    if (solved)
        for (i = 0; i < n; ++i)
            for (j = 0; j < rhs; ++j)
                if (!write_u64(
                    output, (uint64_t) nmod_mat_get_entry(solution, i, j)))
                    goto cleanup;
    exit_code = solved ? 0 : 4;

cleanup:
    if (input != NULL)
        fclose(input);
    if (output != NULL && fclose(output) != 0)
        exit_code = 1;
    if (initialized) {
        nmod_mat_clear(matrix);
        nmod_mat_clear(right);
        nmod_mat_clear(solution);
    }
    return exit_code;
}
