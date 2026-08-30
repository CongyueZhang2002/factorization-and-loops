#define _GNU_SOURCE

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <flint/flint.h>
#include <flint/fmpz.h>
#include <flint/fmpz_mpoly.h>

#if __FLINT_VERSION != 3 || __FLINT_VERSION_MINOR != 0 || \
    __FLINT_VERSION_PATCHLEVEL != 1
#error "flint_mpoly_gcd requires the FLINT 3.0.1 headers"
#endif

enum {
    EXIT_USAGE = 2,
    EXIT_IO = 3,
    EXIT_PROTOCOL = 4,
    EXIT_ARITHMETIC = 5,
    EXIT_OUTPUT = 6
};

static const char INPUT_MAGIC[] = "FFMG1P1";
static const char QUOTIENT_MAGIC[] = "FFMG1Q1";
static const char GCD_MAGIC[] = "FFMG1G1";

enum { MAX_VARIABLES = 1024 };

typedef struct {
    FILE *stream;
    slong variables;
    slong rows;
} sparse_input_t;

static double wall_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        return 0.0;
    return (double) ts.tv_sec + 1.0e-9 * (double) ts.tv_nsec;
}

static void trim_line_end(char *line)
{
    size_t length = strlen(line);
    while (length > 0 && (line[length - 1] == '\n' || line[length - 1] == '\r'))
        line[--length] = '\0';
}

static int parse_ulong_decimal(const char *text, ulong *value)
{
    char *end = NULL;
    unsigned long parsed;
    const unsigned char *cursor = (const unsigned char *) text;
    if (*cursor == '\0')
        return 0;
    while (*cursor != '\0') {
        if (*cursor < (unsigned char) '0' || *cursor > (unsigned char) '9')
            return 0;
        ++cursor;
    }
    errno = 0;
    parsed = strtoul(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0')
        return 0;
    *value = (ulong) parsed;
    return 1;
}

static int valid_integer_decimal(const char *text)
{
    const unsigned char *cursor = (const unsigned char *) text;
    if (*cursor == (unsigned char) '-')
        ++cursor;
    if (*cursor == '\0')
        return 0;
    while (*cursor != '\0') {
        if (*cursor < (unsigned char) '0' || *cursor > (unsigned char) '9')
            return 0;
        ++cursor;
    }
    return 1;
}

static int open_sparse_input(const char *path, sparse_input_t *input)
{
    char *line = NULL;
    char *cursor;
    char *magic;
    char *variables_text;
    char *rows_text;
    size_t capacity = 0;
    ssize_t length;
    ulong variables;
    ulong rows;

    input->stream = fopen(path, "r");
    if (input->stream == NULL)
        return EXIT_IO;
    length = getline(&line, &capacity, input->stream);
    if (length < 0) {
        free(line);
        return ferror(input->stream) ? EXIT_IO : EXIT_PROTOCOL;
    }
    trim_line_end(line);
    cursor = line;
    magic = strsep(&cursor, "\t");
    variables_text = strsep(&cursor, "\t");
    rows_text = strsep(&cursor, "\t");
    if (magic == NULL || variables_text == NULL || rows_text == NULL ||
        cursor != NULL || strcmp(magic, INPUT_MAGIC) != 0 ||
        !parse_ulong_decimal(variables_text, &variables) || variables == 0 ||
        variables > (ulong) MAX_VARIABLES ||
        !parse_ulong_decimal(rows_text, &rows) || rows > (ulong) LONG_MAX) {
        free(line);
        return EXIT_PROTOCOL;
    }
    input->variables = (slong) variables;
    input->rows = (slong) rows;
    free(line);
    return 0;
}

static int read_sparse_body(sparse_input_t *input, fmpz_mpoly_t polynomial,
                            const fmpz_mpoly_ctx_t context)
{
    char *line = NULL;
    size_t capacity = 0;
    ulong *exponents;
    fmpz_t coefficient;
    slong row;
    int status = 0;

    if ((size_t) input->variables > SIZE_MAX / sizeof(*exponents))
        return EXIT_IO;
    exponents = malloc((size_t) input->variables * sizeof(*exponents));
    if (exponents == NULL)
        return EXIT_IO;
    fmpz_init(coefficient);
    for (row = 0; row < input->rows; ++row) {
        char *cursor;
        char *token;
        slong variable;
        ssize_t length = getline(&line, &capacity, input->stream);
        if (length < 0) {
            status = ferror(input->stream) ? EXIT_IO : EXIT_PROTOCOL;
            break;
        }
        trim_line_end(line);
        cursor = line;
        for (variable = 0; variable < input->variables; ++variable) {
            token = strsep(&cursor, "\t");
            if (token == NULL || !parse_ulong_decimal(token, &exponents[variable])) {
                status = EXIT_PROTOCOL;
                break;
            }
        }
        if (status != 0)
            break;
        token = strsep(&cursor, "\t");
        if (token == NULL || cursor != NULL || !valid_integer_decimal(token) ||
            fmpz_set_str(coefficient, token, 10) != 0 ||
            fmpz_is_zero(coefficient)) {
            status = EXIT_PROTOCOL;
            break;
        }
        fmpz_mpoly_push_term_fmpz_ui(polynomial, coefficient, exponents, context);
    }
    if (status == 0) {
        ssize_t extra = getline(&line, &capacity, input->stream);
        if (extra >= 0)
            status = EXIT_PROTOCOL;
        else if (ferror(input->stream))
            status = EXIT_IO;
    }
    free(line);
    free(exponents);
    fmpz_clear(coefficient);
    if (status == 0) {
        fmpz_mpoly_sort_terms(polynomial, context);
        fmpz_mpoly_combine_like_terms(polynomial, context);
    }
    return status;
}

static int close_sparse_input(sparse_input_t *input)
{
    int result = 0;
    if (input->stream != NULL && fclose(input->stream) != 0)
        result = EXIT_IO;
    input->stream = NULL;
    return result;
}

static int write_sparse_atomic(const char *path, const char *magic,
                               const fmpz_mpoly_t polynomial,
                               const fmpz_mpoly_ctx_t context,
                               slong variables)
{
    static const char suffix[] = ".tmp.XXXXXX";
    size_t path_length = strlen(path);
    char *temporary;
    int descriptor;
    FILE *stream;
    ulong *exponents;
    fmpz_t coefficient;
    slong row;
    int ok = 1;

    if (path_length > SIZE_MAX - sizeof(suffix))
        return 0;
    temporary = malloc(path_length + sizeof(suffix));
    if (temporary == NULL)
        return 0;
    memcpy(temporary, path, path_length);
    memcpy(temporary + path_length, suffix, sizeof(suffix));
    descriptor = mkstemp(temporary);
    if (descriptor < 0) {
        free(temporary);
        return 0;
    }
    stream = fdopen(descriptor, "w");
    if (stream == NULL) {
        close(descriptor);
        unlink(temporary);
        free(temporary);
        return 0;
    }
    if ((size_t) variables > SIZE_MAX / sizeof(*exponents)) {
        fclose(stream);
        unlink(temporary);
        free(temporary);
        return 0;
    }
    exponents = malloc((size_t) variables * sizeof(*exponents));
    if (exponents == NULL) {
        fclose(stream);
        unlink(temporary);
        free(temporary);
        return 0;
    }
    fmpz_init(coefficient);
    if (fprintf(stream, "%s\t%ld\t%ld\n", magic, (long) variables,
                (long) fmpz_mpoly_length(polynomial, context)) < 0)
        ok = 0;
    for (row = 0; ok && row < fmpz_mpoly_length(polynomial, context); ++row) {
        slong variable;
        fmpz_mpoly_get_term_exp_ui(exponents, polynomial, row, context);
        fmpz_mpoly_get_term_coeff_fmpz(coefficient, polynomial, row, context);
        for (variable = 0; variable < variables; ++variable)
            if (fprintf(stream, "%lu\t", (unsigned long) exponents[variable]) < 0)
                ok = 0;
        if (ok && (fmpz_fprint(stream, coefficient) < 0 || fputc('\n', stream) == EOF))
            ok = 0;
    }
    fmpz_clear(coefficient);
    free(exponents);
    if (ok && fflush(stream) != 0)
        ok = 0;
    if (ok && fsync(fileno(stream)) != 0)
        ok = 0;
    if (fclose(stream) != 0)
        ok = 0;
    if (ok && rename(temporary, path) != 0)
        ok = 0;
    if (!ok)
        unlink(temporary);
    free(temporary);
    return ok;
}

static int parse_threads(const char *text, int *threads)
{
    ulong value;
    if (!parse_ulong_decimal(text, &value) || value < 1 || value > 64)
        return 0;
    *threads = (int) value;
    return 1;
}

int main(int argc, char **argv)
{
    sparse_input_t numerator_input = {NULL, 0, 0};
    sparse_input_t divisor_input = {NULL, 0, 0};
    fmpz_mpoly_ctx_t context;
    fmpz_mpoly_t numerator, divisor, gcd, quotient;
    int threads = 1;
    int status;
    int context_initialized = 0;
    int polynomials_initialized = 0;
    double started, after_read, after_gcd, after_divexact, after_write;

    started = wall_seconds();
    if (strcmp(flint_version, "3.0.1") != 0) {
        fprintf(stderr, "FLINT 3.0.1 runtime required (found %s)\n", flint_version);
        return EXIT_USAGE;
    }
    if ((argc != 5 && argc != 6) ||
        (argc == 6 && !parse_threads(argv[5], &threads))) {
        fprintf(stderr,
                "usage: %s NUMERATOR.ffmg DIVISOR.ffmg QUOTIENT.ffmg GCD.ffmg [THREADS]\n",
                argv[0]);
        return EXIT_USAGE;
    }
    if (strcmp(argv[3], argv[4]) == 0) {
        fprintf(stderr, "quotient and gcd output paths must differ\n");
        return EXIT_USAGE;
    }
    flint_set_num_threads(threads);

    status = open_sparse_input(argv[1], &numerator_input);
    if (status == 0)
        status = open_sparse_input(argv[2], &divisor_input);
    if (status != 0) {
        fprintf(stderr, "failed reading FFMG1 header\n");
        goto cleanup;
    }
    if (numerator_input.variables != divisor_input.variables) {
        fprintf(stderr, "input variable counts differ\n");
        status = EXIT_PROTOCOL;
        goto cleanup;
    }

    fmpz_mpoly_ctx_init(context, numerator_input.variables, ORD_LEX);
    context_initialized = 1;
    fmpz_mpoly_init(numerator, context);
    fmpz_mpoly_init(divisor, context);
    fmpz_mpoly_init(gcd, context);
    fmpz_mpoly_init(quotient, context);
    polynomials_initialized = 1;

    status = read_sparse_body(&numerator_input, numerator, context);
    if (status == 0)
        status = read_sparse_body(&divisor_input, divisor, context);
    if (close_sparse_input(&numerator_input) != 0 ||
        close_sparse_input(&divisor_input) != 0) {
        if (status == 0)
            status = EXIT_IO;
    }
    if (status != 0) {
        fprintf(stderr, "invalid, truncated, or unreadable FFMG1 polynomial\n");
        goto cleanup;
    }
    if (fmpz_mpoly_is_zero(divisor, context)) {
        fprintf(stderr, "divisor polynomial must be nonzero\n");
        status = EXIT_PROTOCOL;
        goto cleanup;
    }
    after_read = wall_seconds();

    if (!fmpz_mpoly_gcd(gcd, numerator, divisor, context) ||
        fmpz_mpoly_is_zero(gcd, context)) {
        fprintf(stderr, "FLINT multivariate gcd failed\n");
        status = EXIT_ARITHMETIC;
        goto cleanup;
    }
    after_gcd = wall_seconds();
    if (!fmpz_mpoly_divides(quotient, numerator, gcd, context)) {
        fprintf(stderr, "exact numerator cofactor division failed\n");
        status = EXIT_ARITHMETIC;
        goto cleanup;
    }
    after_divexact = wall_seconds();

    if (!write_sparse_atomic(argv[3], QUOTIENT_MAGIC, quotient, context,
                             numerator_input.variables) ||
        !write_sparse_atomic(argv[4], GCD_MAGIC, gcd, context,
                             numerator_input.variables)) {
        fprintf(stderr, "failed committing FFMG1 output\n");
        status = EXIT_OUTPUT;
        goto cleanup;
    }
    after_write = wall_seconds();
    printf("{\"backend\":\"FLINT-fmpz_mpoly-3.0.1\","
           "\"protocol\":\"FFMG1\",\"threads\":%d,"
           "\"variables\":%ld,\"numerator_terms\":%ld,"
           "\"divisor_terms\":%ld,\"quotient_terms\":%ld,"
           "\"gcd_terms\":%ld,\"read_seconds\":%.9f,"
           "\"gcd_seconds\":%.9f,\"divexact_seconds\":%.9f,"
           "\"write_seconds\":%.9f,\"total_seconds\":%.9f}\n",
           threads, (long) numerator_input.variables,
           (long) fmpz_mpoly_length(numerator, context),
           (long) fmpz_mpoly_length(divisor, context),
           (long) fmpz_mpoly_length(quotient, context),
           (long) fmpz_mpoly_length(gcd, context), after_read - started,
           after_gcd - after_read, after_divexact - after_gcd,
           after_write - after_divexact, after_write - started);
    status = 0;

cleanup:
    close_sparse_input(&numerator_input);
    close_sparse_input(&divisor_input);
    if (polynomials_initialized) {
        fmpz_mpoly_clear(quotient, context);
        fmpz_mpoly_clear(gcd, context);
        fmpz_mpoly_clear(divisor, context);
        fmpz_mpoly_clear(numerator, context);
    }
    if (context_initialized)
        fmpz_mpoly_ctx_clear(context);
    flint_cleanup_master();
    return status;
}
