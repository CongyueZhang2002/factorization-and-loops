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

/* Coordinatewise Padé reconstruction from a coefficient-major Taylor stream.
   The first TRAIN coefficients determine a reduced approximant via FLINT's
   Berlekamp-Massey recurrence; all remaining coefficients are disjoint
   validation data.  The explicit recurrence form also handles an arbitrary
   polynomial part, unlike the proper-at-infinity convention of FLINT 3.0.1's
   nmod_berlekamp_massey_V_poly interface. */

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

int main(int argc, char **argv)
{
    static const unsigned char input_magic[7] =
        {'C','F','K','0','Y','1','\0'};
    static const unsigned char output_magic[7] =
        {'C','F','K','0','P','1','\0'};
    unsigned char magic[7];
    uint64_t n_u64, order_u64, modulus_u64;
    slong n, order, train, coordinate, k, i, denominator_degree;
    slong numerator_degree, max_numerator_degree = -1;
    slong max_denominator_degree = -1, failures = 0;
    slong first_failure = -1, last_failure = -1;
    mp_limb_t *coefficients = NULL, *series = NULL, *denominator = NULL;
    mp_limb_t *numerator = NULL, *connection = NULL, *backup = NULL;
    mp_limb_t *temporary = NULL;
    FILE *input = NULL, *output = NULL;
    nmod_t mod;
    double start, read_done, reconstruct_done, write_done;
    int ok = 0;

    if (sizeof(mp_limb_t) != sizeof(uint64_t)) {
        fprintf(stderr, "requires 64-bit FLINT limbs\n");
        return 2;
    }
    if (argc != 4) {
        fprintf(stderr, "usage: %s TAYLOR_SOLUTION OUTPUT TRAIN\n", argv[0]);
        return 2;
    }
    train = (slong) strtol(argv[3], NULL, 10);
    start = wall_seconds();
    input = fopen(argv[1], "rb");
    if (input == NULL ||
        fread(magic, 1, sizeof(magic), input) != sizeof(magic) ||
        memcmp(magic, input_magic, sizeof(magic)) != 0 ||
        !read_u64(input, &n_u64) || !read_u64(input, &order_u64) ||
        !read_u64(input, &modulus_u64) || n_u64 == 0 || order_u64 == 0 ||
        n_u64 > (uint64_t) WORD_MAX || order_u64 > (uint64_t) WORD_MAX ||
        modulus_u64 < 5) {
        fprintf(stderr, "invalid Taylor solution header\n");
        if (input != NULL) fclose(input);
        return 3;
    }
    n = (slong) n_u64;
    order = (slong) order_u64;
    if (train < 4 || train >= order) {
        fprintf(stderr, "TRAIN must leave at least one held-out coefficient\n");
        fclose(input);
        return 3;
    }
    coefficients = (mp_limb_t *) flint_malloc((size_t) n * (size_t) order *
                                               sizeof(mp_limb_t));
    series = (mp_limb_t *) flint_malloc((size_t) order * sizeof(mp_limb_t));
    denominator = (mp_limb_t *) flint_malloc((size_t) (train + 1) *
                                              sizeof(mp_limb_t));
    numerator = (mp_limb_t *) flint_malloc((size_t) train *
                                            sizeof(mp_limb_t));
    connection = (mp_limb_t *) flint_calloc((size_t) (train + 1),
                                             sizeof(mp_limb_t));
    backup = (mp_limb_t *) flint_calloc((size_t) (train + 1),
                                         sizeof(mp_limb_t));
    temporary = (mp_limb_t *) flint_malloc((size_t) (train + 1) *
                                            sizeof(mp_limb_t));
    if (fread(coefficients, sizeof(mp_limb_t),
              (size_t) n * (size_t) order, input)
          != (size_t) n * (size_t) order || fclose(input) != 0)
        goto cleanup;
    input = NULL;
    read_done = wall_seconds();
    nmod_init(&mod, (mp_limb_t) modulus_u64);

    output = fopen(argv[2], "wb");
    if (output == NULL ||
        fwrite(output_magic, 1, sizeof(output_magic), output)
          != sizeof(output_magic) || !write_u64(output, n_u64) ||
        !write_u64(output, order_u64) || !write_u64(output, modulus_u64) ||
        !write_u64(output, (uint64_t) train)) {
        fprintf(stderr, "cannot create %s: %s\n", argv[2], strerror(errno));
        goto cleanup;
    }

    for (coordinate = 0; coordinate < n; ++coordinate) {
        slong linear_complexity = 0, shift = 1, index;
        mp_limb_t previous_discrepancy = 1;
        int valid = 1;
        slong first_bad = -1;
        for (k = 0; k < order; ++k)
            series[k] = coefficients[(size_t) k * (size_t) n +
                                     (size_t) coordinate];
        memset(connection, 0, (size_t) (train + 1) * sizeof(mp_limb_t));
        memset(backup, 0, (size_t) (train + 1) * sizeof(mp_limb_t));
        connection[0] = 1;
        backup[0] = 1;
        for (index = 0; index < train; ++index) {
            mp_limb_t discrepancy = series[index];
            for (i = 1; i <= linear_complexity; ++i)
                discrepancy = nmod_add(discrepancy,
                    nmod_mul(connection[i], series[index - i], mod), mod);
            if (discrepancy == 0) {
                ++shift;
            } else {
                mp_limb_t scale = nmod_mul(discrepancy,
                    nmod_inv(previous_discrepancy, mod), mod);
                memcpy(temporary, connection,
                       (size_t) (train + 1) * sizeof(mp_limb_t));
                for (i = 0; i + shift <= train; ++i)
                    if (backup[i] != 0)
                        connection[i + shift] = nmod_sub(
                            connection[i + shift],
                            nmod_mul(scale, backup[i], mod), mod);
                if (2 * linear_complexity <= index) {
                    linear_complexity = index + 1 - linear_complexity;
                    memcpy(backup, temporary,
                           (size_t) (train + 1) * sizeof(mp_limb_t));
                    previous_discrepancy = discrepancy;
                    shift = 1;
                } else {
                    ++shift;
                }
            }
        }
        denominator_degree = linear_complexity;
        while (denominator_degree > 0 &&
               connection[denominator_degree] == 0)
            --denominator_degree;
        for (i = 0; i <= denominator_degree; ++i)
            denominator[i] = connection[i];
        numerator_degree = -1;
        for (k = 0; k < train; ++k) {
            mp_limb_t sum = 0;
            slong upper = FLINT_MIN(k, denominator_degree);
            for (i = 0; i <= upper; ++i)
                sum = nmod_add(sum,
                    nmod_mul(denominator[i], series[k - i], mod), mod);
            numerator[k] = sum;
            if (sum != 0) numerator_degree = k;
        }
        for (k = train; valid && k < order; ++k) {
            mp_limb_t sum = 0;
            slong upper = FLINT_MIN(k, denominator_degree);
            for (i = 0; i <= upper; ++i)
                sum = nmod_add(sum,
                    nmod_mul(denominator[i], series[k - i], mod), mod);
            if (sum != 0) {
                valid = 0;
                first_bad = k;
            }
        }
        if (!valid) {
            ++failures;
            if (first_failure < 0) first_failure = coordinate + 1;
            last_failure = coordinate + 1;
            if (failures <= 12)
                fprintf(stderr, "held-out Padé failure at coordinate %ld"
                        " (p=%ld q=%ld first_bad=%ld)\n",
                        (long) (coordinate + 1), (long) numerator_degree,
                        (long) denominator_degree, (long) first_bad);
            numerator_degree = -1;
            denominator_degree = 0;
            denominator[0] = 1;
        }
        if (numerator_degree > max_numerator_degree)
            max_numerator_degree = numerator_degree;
        if (denominator_degree > max_denominator_degree)
            max_denominator_degree = denominator_degree;
        if (!write_u64(output, (uint64_t) (numerator_degree + 1)) ||
            !write_u64(output, (uint64_t) (denominator_degree + 1)) ||
            (numerator_degree >= 0 && fwrite(numerator, sizeof(mp_limb_t),
              (size_t) (numerator_degree + 1), output) !=
              (size_t) (numerator_degree + 1)) ||
            fwrite(denominator, sizeof(mp_limb_t),
              (size_t) (denominator_degree + 1), output) !=
              (size_t) (denominator_degree + 1)) {
            fprintf(stderr, "failed writing Padé payload\n");
            goto cleanup;
        }
    }
    reconstruct_done = wall_seconds();
    if (fclose(output) != 0) {
        output = NULL;
        fprintf(stderr, "failed closing Padé output\n");
        goto cleanup;
    }
    output = NULL;
    write_done = wall_seconds();
    printf("{\"status\":\"%s\",\"dimension\":%" PRIu64
           ",\"order\":%" PRIu64 ",\"train\":%ld"
           ",\"held_out\":%ld,\"failures\":%ld"
           ",\"first_failure\":%ld,\"last_failure\":%ld"
           ",\"max_numerator_degree\":%ld"
           ",\"max_denominator_degree\":%ld"
           ",\"read_seconds\":%.6f,\"reconstruct_seconds\":%.6f"
           ",\"write_seconds\":%.6f,\"total_seconds\":%.6f}\n",
           failures == 0 ? "validated" : "held_out_failure", n_u64,
           order_u64, (long) train, (long) (order - train), (long) failures,
           (long) first_failure, (long) last_failure,
           (long) max_numerator_degree, (long) max_denominator_degree,
           read_done - start, reconstruct_done - read_done,
           write_done - reconstruct_done, write_done - start);
    ok = failures == 0;

cleanup:
    if (input != NULL) fclose(input);
    if (output != NULL) fclose(output);
    if (coefficients != NULL) {
        flint_free(coefficients); flint_free(series);
        flint_free(denominator); flint_free(numerator);
        flint_free(connection); flint_free(backup); flint_free(temporary);
    }
    flint_cleanup_master();
    return ok ? 0 : 4;
}
