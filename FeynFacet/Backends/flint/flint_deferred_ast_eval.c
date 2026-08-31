#define _GNU_SOURCE
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

/* Native backend for BlockEquationDeferredV1 point images.

   CLI:
     flint_deferred_ast_eval INPUT.wl REQUEST.txt OUTPUT.bin [--derivatives]

   REQUEST is deliberately neutral and line oriented:
     DeferredASTRequestV1
     prime P
     variables X Y EPS
     rank R                         (0 <= R <= 3)
     root ROOT_SQUARE_INPUTFORM     (R lines; one-line InputForm)
     base_count N
     image x y eps d1 r1 ... dR rR (N lines)

   Every supplied root is authenticated twice: r_i^2 == d_i modulo P and
   the declared root-square expression evaluates to d_i at every base image.
   Sqrt[...] in the DAG is accepted only when its normalized argument is one
   of those exact declared expressions.  The grammar is the fail-closed subset
   emitted by the preserved DeferredPreparation: integers, the three supplied
   symbols (qualified contexts are allowed), +, -, *, /, signed integer powers,
   parentheses, and declared Sqrt generators.

   OUTPUT is little-endian.  The ordinary mode uses DAGO1V1; derivative
   mode uses DAGO2V1 and writes, for every record, value channels followed
   by d/dx channels and d/dy channels:
     char magic[8] = "DAGO1V1\0" or "DAGO2V1\0";
     uint64 status, prime, rank, baseCount, gradeCount,
            recordCount, termCount, uniqueExpressionCount,
            dimension0, dimension1, dimension2, parseNanoseconds,
            evaluationNanoseconds;
     repeated recordCount times:
       uint64 target[3];
       uint64 channels[baseCount][gradeCount];

   Status zero is success.  On failure the same header is written with all
   unavailable fields zero; dimension0 carries a failing record/expression
   index and dimension1 a byte offset when those are known. */

enum status_code {
    ST_OK = 0,
    ST_USAGE = 1,
    ST_REQUEST_IO = 2,
    ST_REQUEST_SCHEMA = 3,
    ST_INVALID_PRIME = 4,
    ST_RESOURCE_LIMIT = 5,
    ST_INPUT_IO = 6,
    ST_PREPARATION_SCHEMA = 7,
    ST_UNSUPPORTED_EXPRESSION = 8,
    ST_UNDECLARED_RADICAL = 9,
    ST_SINGULAR_IMAGE = 10,
    ST_ROOT_VALUE_MISMATCH = 11,
    ST_ROOT_SQUARE_MISMATCH = 12,
    ST_OUTPUT_IO = 13,
    ST_INTERNAL = 14
};

enum { MAX_RANK = 3, MAX_TOTAL_IMAGES = 4096, MAX_RECORDS = 1000000 };

typedef struct { const unsigned char *a, *b; } span_t;
typedef struct {
    uint64_t prime;
    char *symbol[3];
    size_t rank, base_count, grade_count, image_count;
    char *root_expression[MAX_RANK];
    uint64_t *vx, *vy, *ve;
    uint64_t *delta[MAX_RANK], *root[MAX_RANK];
} request_t;

typedef struct { size_t coefficient, *operands, operand_count; } term_t;
typedef struct { uint64_t target[3]; term_t *terms; size_t term_count; } record_t;
typedef struct { span_t span; uint64_t hash; } expression_t;

typedef struct parser parser_t;
/* A parser value is either one modular image vector or, in derivative mode,
   three contiguous vectors {value, d/dx, d/dy}.  Derivatives are propagated
   by forward-mode automatic differentiation while the preserved expression
   DAG is parsed; this avoids materializing symbolic derivatives of the large
   deferred forcing. */
typedef struct { uint64_t *x; int ok; } value_t;
struct parser {
    const unsigned char *begin, *p, *end;
    const request_t *request;
    uint64_t **slots;
    size_t slot_count, slot_capacity;
    uint64_t *prefix;
    enum status_code status;
    int allow_sqrt;
    int derivatives;
};

typedef struct { int curly, square, round, association, string, escape; } depth_t;

static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

static const char *status_name(enum status_code status) {
    static const char *const names[] = {
        "OK", "Usage", "RequestIO", "RequestSchema", "InvalidPrime",
        "ResourceLimit", "InputIO", "PreparationSchema",
        "UnsupportedExpression", "UndeclaredRadical", "SingularImage",
        "RootValueMismatch", "RootSquareMismatch", "OutputIO", "Internal"
    };
    return status <= ST_INTERNAL ? names[status] : "Unknown";
}

static uint64_t addm(uint64_t a, uint64_t b, uint64_t p) {
    uint64_t c = a + b;
    return c >= p ? c - p : c;
}
static uint64_t subm(uint64_t a, uint64_t b, uint64_t p) {
    return a >= b ? a - b : p - (b - a);
}
static uint64_t mulm(uint64_t a, uint64_t b, uint64_t p) {
    return (uint64_t)((__uint128_t)a * b % p);
}
static uint64_t powm(uint64_t a, uint64_t n, uint64_t p) {
    uint64_t result = 1;
    while (n) {
        if (n & 1U) result = mulm(result, a, p);
        a = mulm(a, a, p);
        n >>= 1U;
    }
    return result;
}
static uint64_t invm(uint64_t a, uint64_t p) { return powm(a, p - 2U, p); }

static int prime64(uint64_t n) {
    static const uint64_t small[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    static const uint64_t witness[] = {
        2, 325, 9375, 28178, 450775, 9780504, 1795265022
    };
    uint64_t d, x, a;
    unsigned s = 0;
    size_t i, r;
    if (n < 2) return 0;
    for (i = 0; i < sizeof(small) / sizeof(*small); ++i) {
        if (n == small[i]) return 1;
        if (n % small[i] == 0) return 0;
    }
    d = n - 1;
    while ((d & 1U) == 0) { ++s; d >>= 1U; }
    for (i = 0; i < sizeof(witness) / sizeof(*witness); ++i) {
        a = witness[i] % n;
        if (a == 0) continue;
        x = powm(a, d, n);
        if (x == 1 || x == n - 1) continue;
        for (r = 1; r < s; ++r) {
            x = mulm(x, x, n);
            if (x == n - 1) break;
        }
        if (r == s) return 0;
    }
    return 1;
}

static char *trim_line(char *line) {
    char *a = line, *b;
    while (*a && isspace((unsigned char)*a)) ++a;
    b = a + strlen(a);
    while (b > a && isspace((unsigned char)b[-1])) --b;
    *b = '\0';
    return a;
}

static int symbol_name(const char *s) {
    const unsigned char *p = (const unsigned char *)s;
    if (!(*p == '$' || isalpha(*p))) return 0;
    for (++p; *p; ++p) if (!(*p == '$' || isalnum(*p))) return 0;
    return 1;
}

static int parse_u64_token(char **cursor, uint64_t *value) {
    char *p = *cursor, *end;
    unsigned long long v;
    while (*p && isspace((unsigned char)*p)) ++p;
    if (!isdigit((unsigned char)*p)) return 0;
    errno = 0;
    v = strtoull(p, &end, 10);
    if (errno || end == p || (*end && !isspace((unsigned char)*end))) return 0;
    *value = (uint64_t)v;
    *cursor = end;
    return 1;
}

static void free_request(request_t *r) {
    size_t k;
    for (k = 0; k < 3; ++k) free(r->symbol[k]);
    for (k = 0; k < MAX_RANK; ++k) {
        free(r->root_expression[k]);
        free(r->delta[k]);
        free(r->root[k]);
    }
    free(r->vx); free(r->vy); free(r->ve);
    memset(r, 0, sizeof(*r));
}

static enum status_code load_request(const char *path, request_t *r) {
    FILE *f = fopen(path, "r");
    char *line = NULL, *p, *save, *token;
    size_t capacity = 0, k, i, expected;
    ssize_t got;
    uint64_t v;
    memset(r, 0, sizeof(*r));
    if (!f) return ST_REQUEST_IO;
#define NEXT_LINE() do { got = getline(&line, &capacity, f); \
    if (got < 0) { free(line); fclose(f); free_request(r); \
        return ST_REQUEST_SCHEMA; } p = trim_line(line); } while (0)
    NEXT_LINE();
    if (strcmp(p, "DeferredASTRequestV1")) goto schema;
    NEXT_LINE();
    if (strncmp(p, "prime ", 6)) goto schema;
    p += 6;
    if (!parse_u64_token(&p, &r->prime) || *trim_line(p)) goto schema;
    if (!(3 < r->prime && r->prime < (UINT64_C(1) << 63)) || !prime64(r->prime)) {
        free(line); fclose(f); free_request(r); return ST_INVALID_PRIME;
    }
    NEXT_LINE();
    if (strncmp(p, "variables ", 10)) goto schema;
    p += 10; save = NULL;
    for (k = 0; k < 3; ++k) {
        token = strtok_r(k ? NULL : p, " \t", &save);
        if (!token || !symbol_name(token)) goto schema;
        r->symbol[k] = strdup(token);
        if (!r->symbol[k]) goto resource;
    }
    if (strtok_r(NULL, " \t", &save) || !strcmp(r->symbol[0], r->symbol[1]) ||
        !strcmp(r->symbol[0], r->symbol[2]) || !strcmp(r->symbol[1], r->symbol[2]))
        goto schema;
    NEXT_LINE();
    if (strncmp(p, "rank ", 5)) goto schema;
    p += 5;
    if (!parse_u64_token(&p, &v) || *trim_line(p) || v > MAX_RANK) goto schema;
    r->rank = (size_t)v;
    r->grade_count = (size_t)1U << r->rank;
    for (k = 0; k < r->rank; ++k) {
        NEXT_LINE();
        if (strncmp(p, "root ", 5) || !p[5]) goto schema;
        r->root_expression[k] = strdup(p + 5);
        if (!r->root_expression[k]) goto resource;
    }
    NEXT_LINE();
    if (strncmp(p, "base_count ", 11)) goto schema;
    p += 11;
    if (!parse_u64_token(&p, &v) || *trim_line(p) || v == 0) goto schema;
    r->base_count = (size_t)v;
    if (r->base_count > MAX_TOTAL_IMAGES / r->grade_count) goto resource;
    r->image_count = r->base_count * r->grade_count;
    r->vx = calloc(r->image_count, sizeof(uint64_t));
    r->vy = calloc(r->image_count, sizeof(uint64_t));
    r->ve = calloc(r->image_count, sizeof(uint64_t));
    for (k = 0; k < r->rank; ++k) {
        r->delta[k] = calloc(r->image_count, sizeof(uint64_t));
        r->root[k] = calloc(r->image_count, sizeof(uint64_t));
    }
    if (!r->vx || !r->vy || !r->ve) goto resource;
    for (k = 0; k < r->rank; ++k)
        if (!r->delta[k] || !r->root[k]) goto resource;
    expected = 3 + 2 * r->rank;
    for (i = 0; i < r->base_count; ++i) {
        uint64_t fields[3 + 2 * MAX_RANK];
        size_t field, sheet, image;
        NEXT_LINE();
        if (strncmp(p, "image ", 6)) goto schema;
        p += 6;
        for (field = 0; field < expected; ++field)
            if (!parse_u64_token(&p, &fields[field]) || fields[field] >= r->prime)
                goto schema;
        if (*trim_line(p)) goto schema;
        for (k = 0; k < r->rank; ++k)
            if (fields[4 + 2 * k] == 0 ||
                mulm(fields[4 + 2 * k], fields[4 + 2 * k], r->prime) !=
                    fields[3 + 2 * k]) {
                free(line); fclose(f); free_request(r);
                return ST_ROOT_VALUE_MISMATCH;
            }
        for (sheet = 0; sheet < r->grade_count; ++sheet) {
            image = i * r->grade_count + sheet;
            r->vx[image] = fields[0];
            r->vy[image] = fields[1];
            r->ve[image] = fields[2];
            for (k = 0; k < r->rank; ++k) {
                uint64_t root = fields[4 + 2 * k];
                r->delta[k][image] = fields[3 + 2 * k];
                r->root[k][image] = (sheet & ((size_t)1U << k)) && root ?
                    r->prime - root : root;
            }
        }
    }
    while ((got = getline(&line, &capacity, f)) >= 0)
        if (*trim_line(line)) goto schema;
    free(line); fclose(f); return ST_OK;
schema:
    free(line); fclose(f); free_request(r); return ST_REQUEST_SCHEMA;
resource:
    free(line); fclose(f); free_request(r); return ST_RESOURCE_LIMIT;
#undef NEXT_LINE
}

static void continuation(parser_t *s) {
    ++s->p;
    if (s->p < s->end && *s->p == '\r') ++s->p;
    if (s->p < s->end && *s->p == '\n') ++s->p;
    while (s->p < s->end && (*s->p == ' ' || *s->p == '\t')) ++s->p;
}
static void space(parser_t *s) {
    for (;;) {
        while (s->p < s->end && isspace(*s->p)) ++s->p;
        if (s->p < s->end && *s->p == '\\' && s->p + 1 < s->end &&
            (s->p[1] == '\n' || s->p[1] == '\r')) continuation(s);
        else break;
    }
}

static int normalized_span_string(span_t span, const char *text) {
    const unsigned char *p = span.a;
    const unsigned char *end = span.b;
    const unsigned char *q = (const unsigned char *)text;
    for (;;) {
        while (p < end && isspace(*p)) ++p;
        while (*q && isspace(*q)) ++q;
        if (p < end && *p == '\\' && p + 1 < end &&
            (p[1] == '\n' || p[1] == '\r')) {
            ++p; while (p < end && isspace(*p)) ++p; continue;
        }
        if (!*q || p == end) return !*q && p == end;
        if (*p++ != *q++) return 0;
    }
}

static value_t allocate_value(parser_t *s) {
    uint64_t *buffer;
    if (s->slot_count == s->slot_capacity) {
        size_t old = s->slot_capacity;
        size_t next = old ? 2 * old : 32;
        uint64_t **slots = realloc(s->slots, next * sizeof(*slots));
        size_t i;
        if (!slots) { s->status = ST_RESOURCE_LIMIT; return (value_t){NULL, 0}; }
        s->slots = slots;
        for (i = old; i < next; ++i) s->slots[i] = NULL;
        s->slot_capacity = next;
    }
    buffer = s->slots[s->slot_count];
    if (!buffer) {
        buffer = malloc(s->request->image_count *
                        (s->derivatives ? 3U : 1U) * sizeof(*buffer));
        if (!buffer) { s->status = ST_RESOURCE_LIMIT; return (value_t){NULL, 0}; }
        s->slots[s->slot_count] = buffer;
    }
    ++s->slot_count;
    return (value_t){buffer, 1};
}
static void release_value(parser_t *s, value_t value) {
    if (s->slot_count && s->slots[s->slot_count - 1] == value.x) --s->slot_count;
    else s->status = ST_INTERNAL;
}

static value_t constant_value(parser_t *s, uint64_t a) {
    value_t result = allocate_value(s);
    size_t i, n = s->request->image_count;
    if (result.ok) {
        for (i = 0; i < n; ++i) result.x[i] = a;
        if (s->derivatives) memset(result.x + n, 0, 2U * n * sizeof(uint64_t));
    }
    return result;
}

static value_t binary_value(parser_t *s, value_t a, value_t b, int op) {
    size_t i, n = s->request->image_count;
    uint64_t p = s->request->prime;
    if (!a.ok || !b.ok) return (value_t){NULL, 0};
    if (op == '/') {
        uint64_t inverse;
        for (i = 0; i < n; ++i) {
            if (b.x[i] == 0) { s->status = ST_SINGULAR_IMAGE; return (value_t){NULL, 0}; }
            s->prefix[i] = i ? mulm(s->prefix[i - 1], b.x[i], p) : b.x[i];
        }
        inverse = invm(s->prefix[n - 1], p);
        for (i = n; i-- > 0;) {
            uint64_t before = i ? s->prefix[i - 1] : 1;
            uint64_t current = mulm(inverse, before, p);
            inverse = mulm(inverse, b.x[i], p);
            if (s->derivatives) {
                uint64_t quotient = mulm(a.x[i], current, p);
                a.x[n + i] = mulm(subm(a.x[n + i],
                    mulm(quotient, b.x[n + i], p), p), current, p);
                a.x[2U * n + i] = mulm(subm(a.x[2U * n + i],
                    mulm(quotient, b.x[2U * n + i], p), p), current, p);
                a.x[i] = quotient;
            } else a.x[i] = mulm(a.x[i], current, p);
        }
    } else {
        for (i = 0; i < n; ++i) {
            if (op == '+') {
                a.x[i] = addm(a.x[i], b.x[i], p);
                if (s->derivatives) {
                    a.x[n + i] = addm(a.x[n + i], b.x[n + i], p);
                    a.x[2U * n + i] = addm(a.x[2U * n + i],
                        b.x[2U * n + i], p);
                }
            } else if (op == '-') {
                a.x[i] = subm(a.x[i], b.x[i], p);
                if (s->derivatives) {
                    a.x[n + i] = subm(a.x[n + i], b.x[n + i], p);
                    a.x[2U * n + i] = subm(a.x[2U * n + i],
                        b.x[2U * n + i], p);
                }
            } else {
                uint64_t av = a.x[i], bv = b.x[i];
                if (s->derivatives) {
                    a.x[n + i] = addm(mulm(a.x[n + i], bv, p),
                        mulm(av, b.x[n + i], p), p);
                    a.x[2U * n + i] = addm(mulm(a.x[2U * n + i], bv, p),
                        mulm(av, b.x[2U * n + i], p), p);
                }
                a.x[i] = mulm(av, bv, p);
            }
        }
    }
    release_value(s, b);
    return s->status == ST_OK ? a : (value_t){NULL, 0};
}

static value_t power_value(parser_t *s, value_t a, int64_t exponent) {
    size_t i, n = s->request->image_count;
    uint64_t magnitude = exponent < 0 ? (uint64_t)(-(exponent + 1)) + 1U :
                                       (uint64_t)exponent;
    if (!a.ok) return a;
    for (i = 0; i < n; ++i) {
        uint64_t base = a.x[i];
        uint64_t derivative_factor = 0;
        if (s->derivatives && exponent != 0) {
            uint64_t coefficient = exponent < 0 ?
                s->request->prime - (magnitude % s->request->prime) :
                magnitude % s->request->prime;
            if (exponent < 0) {
                if (base == 0) {
                    s->status = ST_SINGULAR_IMAGE;
                    return (value_t){NULL, 0};
                }
                derivative_factor = mulm(coefficient,
                    powm(invm(base, s->request->prime), magnitude + 1U,
                         s->request->prime), s->request->prime);
            } else if (magnitude == 1U) derivative_factor = coefficient;
            else if (base != 0) derivative_factor = mulm(coefficient,
                powm(base, magnitude - 1U, s->request->prime),
                s->request->prime);
        }
        if (exponent < 0) {
            if (base == 0) { s->status = ST_SINGULAR_IMAGE; return (value_t){NULL, 0}; }
            base = invm(base, s->request->prime);
        }
        a.x[i] = powm(base, magnitude, s->request->prime);
        if (s->derivatives) {
            a.x[n + i] = mulm(derivative_factor, a.x[n + i],
                              s->request->prime);
            a.x[2U * n + i] = mulm(derivative_factor,
                  a.x[2U * n + i], s->request->prime);
        }
    }
    return a;
}

static int declared_root_index(const parser_t *s, span_t base) {
    size_t i;
    if (!s->allow_sqrt) return -1;
    for (i = 0; i < s->request->rank; ++i)
        if (normalized_span_string(base, s->request->root_expression[i]))
            return (int)i;
    return -1;
}

/* For an authenticated declared square Delta = r^2, evaluate only odd
   half-integer powers

       Delta^((2 k + 1)/2) = Delta^k r.

   The supplied sheet value of r preserves the deck sign.  No generic square
   root is inferred from a modular residue: a nonmatching base is refused. */
static value_t odd_half_power_value(parser_t *s, value_t base,
                                    int64_t numerator, int root_index) {
    size_t i, n = s->request->image_count;
    int64_t k = (numerator - 1) / 2;
    for (i = 0; i < n; ++i) {
        uint64_t delta = base.x[i], delta_power, value;
        uint64_t root = s->request->root[root_index][i];
        uint64_t magnitude = k < 0 ? (uint64_t)(-(k + 1)) + 1U :
                                     (uint64_t)k;
        if (delta == 0 && (k < 0 || s->derivatives)) {
            s->status = ST_SINGULAR_IMAGE;
            return (value_t){NULL, 0};
        }
        delta_power = powm(k < 0 ? invm(delta, s->request->prime) : delta,
                           magnitude, s->request->prime);
        value = mulm(delta_power, root, s->request->prime);
        if (s->derivatives) {
            uint64_t magnitude_mod = (uint64_t)(numerator < 0 ?
                -(numerator + 1) + 1 : numerator) % s->request->prime;
            uint64_t coefficient = mulm(magnitude_mod,
                invm(2U, s->request->prime), s->request->prime);
            uint64_t factor;
            if (numerator < 0 && coefficient)
                coefficient = s->request->prime - coefficient;
            factor = mulm(mulm(coefficient, value, s->request->prime),
                          invm(delta, s->request->prime), s->request->prime);
            base.x[n + i] = mulm(factor, base.x[n + i], s->request->prime);
            base.x[2U * n + i] = mulm(factor, base.x[2U * n + i],
                                      s->request->prime);
        }
        base.x[i] = value;
    }
    return base;
}

static int symbol_tail(span_t symbol, const char *wanted) {
    const unsigned char *tail = symbol.a, *p;
    for (p = symbol.a; p < symbol.b; ++p) if (*p == '`') tail = p + 1;
    return (size_t)(symbol.b - tail) == strlen(wanted) &&
           !memcmp(tail, wanted, strlen(wanted));
}

static value_t parse_sum(parser_t *s);
static value_t parse_primary(parser_t *s) {
    value_t result = {NULL, 0};
    const request_t *r = s->request;
    int sign = 1;
    size_t i;
    span_t power_base = {NULL, NULL};
    space(s);
    while (s->p < s->end && (*s->p == '+' || *s->p == '-')) {
        if (*s->p++ == '-') sign = -sign;
        space(s);
    }
    if (s->p >= s->end) { s->status = ST_UNSUPPORTED_EXPRESSION; return result; }
    if (*s->p == '(') {
        ++s->p; power_base.a = s->p; result = parse_sum(s);
        power_base.b = s->p; space(s);
        if (s->p >= s->end || *s->p++ != ')') s->status = ST_UNSUPPORTED_EXPRESSION;
    } else if (isdigit(*s->p)) {
        power_base.a = s->p;
        uint64_t n = 0;
        while (s->p < s->end && isdigit(*s->p))
            n = addm(mulm(n, 10, r->prime), (uint64_t)(*s->p++ - '0'), r->prime);
        power_base.b = s->p;
        result = constant_value(s, n);
    } else {
        span_t symbol;
        symbol.a = s->p;
        while (s->p < s->end &&
               (isalnum(*s->p) || *s->p == '$' || *s->p == '`')) ++s->p;
        symbol.b = s->p;
        if (symbol.a == symbol.b) { s->status = ST_UNSUPPORTED_EXPRESSION; return result; }
        space(s);
        if (symbol_tail(symbol, "Sqrt") && s->p < s->end && *s->p == '[') {
            const unsigned char *argument_start, *argument_end;
            int root_index = -1;
            if (!s->allow_sqrt) { s->status = ST_UNDECLARED_RADICAL; return result; }
            ++s->p; argument_start = s->p;
            result = parse_sum(s); argument_end = s->p; space(s);
            if (s->p >= s->end || *s->p++ != ']') {
                s->status = ST_UNSUPPORTED_EXPRESSION; return (value_t){NULL, 0};
            }
            for (i = 0; i < r->rank; ++i)
                if (normalized_span_string((span_t){argument_start, argument_end},
                                           r->root_expression[i])) {
                    root_index = (int)i; break;
                }
            if (root_index < 0) {
                s->status = ST_UNDECLARED_RADICAL; return (value_t){NULL, 0};
            }
            for (i = 0; i < r->image_count; ++i) {
                uint64_t root = r->root[root_index][i];
                if (s->derivatives) {
                    uint64_t inverse_two_root;
                    if (root == 0) {
                        s->status = ST_SINGULAR_IMAGE;
                        return (value_t){NULL, 0};
                    }
                    inverse_two_root = invm(mulm(2U, root, r->prime), r->prime);
                    result.x[r->image_count + i] = mulm(
                        result.x[r->image_count + i], inverse_two_root, r->prime);
                    result.x[2U * r->image_count + i] = mulm(
                        result.x[2U * r->image_count + i], inverse_two_root,
                        r->prime);
                }
                result.x[i] = r->root[root_index][i];
            }
        } else if (symbol_tail(symbol, r->symbol[0]) ||
                   symbol_tail(symbol, r->symbol[1]) ||
                   symbol_tail(symbol, r->symbol[2])) {
            int variable_index = symbol_tail(symbol, r->symbol[0]) ? 0 :
                                 symbol_tail(symbol, r->symbol[1]) ? 1 : 2;
            const uint64_t *source = variable_index == 0 ? r->vx :
                                     variable_index == 1 ? r->vy : r->ve;
            result = allocate_value(s);
            if (result.ok) {
                memcpy(result.x, source, r->image_count * sizeof(uint64_t));
                if (s->derivatives) {
                    for (i = 0; i < r->image_count; ++i) {
                        result.x[r->image_count + i] = variable_index == 0;
                        result.x[2U * r->image_count + i] = variable_index == 1;
                    }
                }
            }
            power_base = symbol;
        } else {
            s->status = ST_UNSUPPORTED_EXPRESSION;
            return result;
        }
    }
    space(s);
    if (result.ok && s->p < s->end && *s->p == '^') {
        uint64_t magnitude = 0;
        int exponent_sign = 1, parenthesized = 0, rational = 0;
        uint64_t denominator = 1;
        int64_t exponent;
        ++s->p; space(s);
        if (s->p < s->end && *s->p == '(') { parenthesized = 1; ++s->p; space(s); }
        if (s->p < s->end && (*s->p == '+' || *s->p == '-'))
            if (*s->p++ == '-') exponent_sign = -1;
        if (s->p >= s->end || !isdigit(*s->p)) {
            s->status = ST_UNSUPPORTED_EXPRESSION; return (value_t){NULL, 0};
        }
        while (s->p < s->end && isdigit(*s->p)) {
            unsigned digit = (unsigned)(*s->p++ - '0');
            if (magnitude > (UINT64_MAX - digit) / 10U ||
                magnitude > (uint64_t)INT64_MAX) {
                s->status = ST_RESOURCE_LIMIT; return (value_t){NULL, 0};
            }
            magnitude = 10U * magnitude + digit;
        }
        space(s);
        /* InputForm encloses a rational exponent: x^(3/2).  Without those
           parentheses, x^2/2 is ordinary division after the integer power. */
        if (parenthesized && s->p < s->end && *s->p == '/') {
            rational = 1; ++s->p; space(s); denominator = 0;
            if (s->p >= s->end || !isdigit(*s->p)) {
                s->status = ST_UNSUPPORTED_EXPRESSION;
                return (value_t){NULL, 0};
            }
            while (s->p < s->end && isdigit(*s->p)) {
                unsigned digit = (unsigned)(*s->p++ - '0');
                if (denominator > (UINT64_MAX - digit) / 10U) {
                    s->status = ST_RESOURCE_LIMIT;
                    return (value_t){NULL, 0};
                }
                denominator = 10U * denominator + digit;
            }
            space(s);
        }
        if (parenthesized && (s->p >= s->end || *s->p++ != ')')) {
            s->status = ST_UNSUPPORTED_EXPRESSION; return (value_t){NULL, 0};
        }
        exponent = exponent_sign < 0 ? -(int64_t)magnitude : (int64_t)magnitude;
        if (rational) {
            int root_index;
            if (denominator != 2 || !(magnitude & 1U)) {
                s->status = ST_UNSUPPORTED_EXPRESSION;
                return (value_t){NULL, 0};
            }
            root_index = power_base.a && power_base.b ?
                declared_root_index(s, power_base) : -1;
            if (root_index < 0) {
                s->status = ST_UNDECLARED_RADICAL;
                return (value_t){NULL, 0};
            }
            result = odd_half_power_value(s, result, exponent, root_index);
        } else {
            result = power_value(s, result, exponent);
        }
    }
    /* InputForm precedence: -x^2 is -(x^2); (-x)^2 has explicit brackets. */
    if (sign < 0 && result.ok) {
        size_t count = r->image_count * (s->derivatives ? 3U : 1U);
        for (i = 0; i < count; ++i)
            if (result.x[i]) result.x[i] = r->prime - result.x[i];
    }
    return result;
}

static value_t parse_term(parser_t *s) {
    value_t result = parse_primary(s);
    space(s);
    while (result.ok && s->status == ST_OK && s->p < s->end &&
           (*s->p == '*' || *s->p == '/')) {
        int op = *s->p++;
        value_t right = parse_primary(s);
        result = binary_value(s, result, right, op);
        space(s);
    }
    return result;
}

static value_t parse_sum(parser_t *s) {
    value_t result = parse_term(s);
    space(s);
    while (result.ok && s->status == ST_OK && s->p < s->end &&
           (*s->p == '+' || *s->p == '-')) {
        int op = *s->p++;
        value_t right = parse_term(s);
        result = binary_value(s, result, right, op);
        space(s);
    }
    return result;
}

static void parser_destroy(parser_t *s) {
    size_t i;
    for (i = 0; i < s->slot_capacity; ++i) free(s->slots[i]);
    free(s->slots); free(s->prefix);
    memset(s, 0, sizeof(*s));
}

static enum status_code evaluate_span(parser_t *s, span_t span,
                                      int allow_sqrt, uint64_t *output,
                                      size_t *offset) {
    value_t value;
    s->begin = span.a; s->p = span.a; s->end = span.b;
    s->status = ST_OK; s->slot_count = 0; s->allow_sqrt = allow_sqrt;
    value = parse_sum(s); space(s);
    if (!value.ok || s->status != ST_OK || s->p != s->end) {
        if (s->status == ST_OK) s->status = ST_UNSUPPORTED_EXPRESSION;
        if (offset) *offset = (size_t)(s->p - s->begin);
        return s->status;
    }
    memcpy(output, value.x, s->request->image_count *
           (s->derivatives ? 3U : 1U) * sizeof(uint64_t));
    return ST_OK;
}

static void depth_step(depth_t *d, const unsigned char *p,
                       const unsigned char *end, size_t *advance) {
    unsigned char c = *p, next = p + 1 < end ? p[1] : 0;
    *advance = 1;
    if (d->string) {
        if (d->escape) d->escape = 0;
        else if (c == '\\') d->escape = 1;
        else if (c == '"') d->string = 0;
        return;
    }
    if (c == '"') { d->string = 1; return; }
    if (c == '<' && next == '|') { ++d->association; *advance = 2; return; }
    if (c == '|' && next == '>') { --d->association; *advance = 2; return; }
    if (c == '{') ++d->curly; else if (c == '}') --d->curly;
    else if (c == '[') ++d->square; else if (c == ']') --d->square;
    else if (c == '(') ++d->round; else if (c == ')') --d->round;
}
static int depth_zero(const depth_t *d) {
    return d->curly == 0 && d->square == 0 && d->round == 0 &&
           d->association == 0 && !d->string;
}

static const unsigned char *find_key(span_t scope, const char *key) {
    return memmem(scope.a, (size_t)(scope.b - scope.a), key, strlen(key));
}

static int association_after_key(span_t scope, const char *key, span_t *value) {
    const unsigned char *p = find_key(scope, key), *start;
    int depth = 0, string = 0, escape = 0;
    if (!p) return 0;
    p += strlen(key);
    while (p + 1 < scope.b && !(p[0] == '<' && p[1] == '|')) ++p;
    if (p + 1 >= scope.b) return 0;
    start = p; depth = 1; p += 2;
    while (p < scope.b) {
        unsigned char c = *p, next = p + 1 < scope.b ? p[1] : 0;
        if (string) {
            if (escape) escape = 0;
            else if (c == '\\') escape = 1;
            else if (c == '"') string = 0;
            ++p; continue;
        }
        if (c == '"') { string = 1; ++p; continue; }
        if (c == '<' && next == '|') { ++depth; p += 2; continue; }
        if (c == '|' && next == '>') {
            --depth; p += 2;
            if (depth == 0) { *value = (span_t){start, p}; return 1; }
            continue;
        }
        ++p;
    }
    return 0;
}

static int list_after_key(span_t scope, const char *key,
                          span_t **items_out, size_t *count_out) {
    const unsigned char *p = find_key(scope, key), *item;
    span_t *items = NULL;
    size_t count = 0, capacity = 0, advance;
    depth_t depth = {0};
    if (!p) return 0;
    p += strlen(key);
    while (p < scope.b && *p != '{') ++p;
    if (p == scope.b) return 0;
    item = ++p;
    for (; p < scope.b;) {
        if (*p == '}' && depth_zero(&depth)) {
            const unsigned char *a = item, *b = p;
            while (a < b && isspace(*a)) ++a;
            while (b > a && isspace(b[-1])) --b;
            if (a < b) {
                if (count == capacity) {
                    capacity = capacity ? 2 * capacity : 16;
                    items = realloc(items, capacity * sizeof(*items));
                    if (!items) return 0;
                }
                items[count++] = (span_t){a, b};
            }
            *items_out = items; *count_out = count; return 1;
        }
        if (*p == ',' && depth_zero(&depth)) {
            const unsigned char *a = item, *b = p;
            while (a < b && isspace(*a)) ++a;
            while (b > a && isspace(b[-1])) --b;
            if (a < b) {
                if (count == capacity) {
                    capacity = capacity ? 2 * capacity : 16;
                    items = realloc(items, capacity * sizeof(*items));
                    if (!items) return 0;
                }
                items[count++] = (span_t){a, b};
            }
            item = ++p; continue;
        }
        depth_step(&depth, p, scope.b, &advance); p += advance;
    }
    free(items); return 0;
}

static int scalar_after_key(span_t scope, const char *key, span_t *value) {
    const unsigned char *p = find_key(scope, key), *a;
    size_t advance;
    depth_t depth = {0};
    if (!p) return 0;
    p += strlen(key);
    while (p + 1 < scope.b && !(p[0] == '-' && p[1] == '>')) ++p;
    if (p + 1 >= scope.b) return 0;
    p += 2; while (p < scope.b && isspace(*p)) ++p; a = p;
    for (; p < scope.b;) {
        if (depth_zero(&depth) && (*p == ',' ||
            (*p == '|' && p + 1 < scope.b && p[1] == '>'))) {
            const unsigned char *b = p;
            while (b > a && isspace(b[-1])) --b;
            *value = (span_t){a, b}; return a < b;
        }
        depth_step(&depth, p, scope.b, &advance); p += advance;
    }
    value->a = a; value->b = scope.b; return a < scope.b;
}

static uint64_t normalized_hash(span_t span) {
    uint64_t hash = UINT64_C(1469598103934665603);
    const unsigned char *p;
    for (p = span.a; p < span.b; ++p) {
        if (isspace(*p)) continue;
        if (*p == '\\' && p + 1 < span.b && (p[1] == '\n' || p[1] == '\r')) {
            ++p; if (*p == '\r' && p + 1 < span.b && p[1] == '\n') ++p;
            continue;
        }
        hash ^= *p; hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static int normalized_equal(span_t a, span_t b) {
    const unsigned char *p = a.a, *q = b.a;
    for (;;) {
        while (p < a.b && isspace(*p)) ++p;
        while (q < b.b && isspace(*q)) ++q;
        if (p < a.b && *p == '\\' && p + 1 < a.b &&
            (p[1] == '\n' || p[1] == '\r')) {
            ++p; while (p < a.b && isspace(*p)) ++p;
        }
        if (q < b.b && *q == '\\' && q + 1 < b.b &&
            (q[1] == '\n' || q[1] == '\r')) {
            ++q; while (q < b.b && isspace(*q)) ++q;
        }
        if (p == a.b || q == b.b) return p == a.b && q == b.b;
        if (*p++ != *q++) return 0;
    }
}

static size_t intern_expression(span_t span, expression_t **table,
                                size_t *count, size_t *capacity) {
    uint64_t hash = normalized_hash(span);
    size_t i;
    for (i = 0; i < *count; ++i)
        if ((*table)[i].hash == hash && normalized_equal((*table)[i].span, span))
            return i;
    if (*count == *capacity) {
        size_t next = *capacity ? 2 * *capacity : 256;
        expression_t *grown = realloc(*table, next * sizeof(**table));
        if (!grown) return SIZE_MAX;
        *table = grown; *capacity = next;
    }
    (*table)[*count] = (expression_t){span, hash};
    return (*count)++;
}

static int uint_span(span_t span, uint64_t *value) {
    uint64_t result = 0;
    const unsigned char *p = span.a;
    while (p < span.b && isspace(*p)) ++p;
    if (p == span.b || !isdigit(*p)) return 0;
    while (p < span.b && isdigit(*p)) {
        unsigned digit = (unsigned)(*p++ - '0');
        if (result > (UINT64_MAX - digit) / 10U) return 0;
        result = 10U * result + digit;
    }
    while (p < span.b && isspace(*p)) ++p;
    if (p != span.b) return 0;
    *value = result; return 1;
}

static enum status_code load_records(const unsigned char *data, size_t size,
    record_t **records_out, size_t *record_count_out,
    expression_t **expressions_out, size_t *expression_count_out,
    size_t *term_total_out, uint64_t dimensions[3]) {
    span_t whole = {data, data + size}, deferred, preparation,
           status_span, version_span, *record_spans = NULL;
    size_t record_count = 0, record_index, expression_count = 0,
           expression_capacity = 0, term_total = 0;
    expression_t *expressions = NULL;
    record_t *records;
    if (!association_after_key(whole, "\"DeferredPreparation\"", &deferred) ||
        !association_after_key(deferred, "\"Preparation\"", &preparation) ||
        !scalar_after_key(preparation, "\"Status\"", &status_span) ||
        !scalar_after_key(preparation, "\"ABIVersion\"", &version_span) ||
        !normalized_span_string(status_span, "\"Prepared\"") ||
        !normalized_span_string(version_span, "\"BlockEquationDeferredV1\"") ||
        !list_after_key(preparation, "\"Records\"", &record_spans, &record_count) ||
        record_count == 0 || record_count > MAX_RECORDS) return ST_PREPARATION_SCHEMA;
    records = calloc(record_count, sizeof(*records));
    if (!records) { free(record_spans); return ST_RESOURCE_LIMIT; }
    dimensions[0] = dimensions[1] = dimensions[2] = 0;
    for (record_index = 0; record_index < record_count; ++record_index) {
        span_t *target = NULL, *terms = NULL;
        size_t target_count = 0, term_count = 0, term_index;
        if (!list_after_key(record_spans[record_index], "\"Target\"",
                            &target, &target_count)) goto invalid;
        if (target_count != 3 ||
            !list_after_key(record_spans[record_index], "\"Terms\"",
                            &terms, &term_count)) {
            free(target); free(terms); goto invalid;
        }
        for (size_t axis = 0; axis < 3; ++axis) {
            if (!uint_span(target[axis], &records[record_index].target[axis]) ||
                records[record_index].target[axis] == 0) {
                free(target); free(terms); goto invalid;
            }
            if (records[record_index].target[axis] > dimensions[axis])
                dimensions[axis] = records[record_index].target[axis];
        }
        free(target);
        records[record_index].terms = calloc(term_count, sizeof(term_t));
        records[record_index].term_count = term_count;
        if (term_count && !records[record_index].terms) {
            free(terms); goto resource;
        }
        term_total += term_count;
        for (term_index = 0; term_index < term_count; ++term_index) {
            span_t coefficient, *operands = NULL;
            size_t operand_count = 0, operand_index;
            term_t *term = &records[record_index].terms[term_index];
            if (!scalar_after_key(terms[term_index], "\"Coefficient\"", &coefficient) ||
                !list_after_key(terms[term_index], "\"Operands\"",
                                &operands, &operand_count)) {
                free(operands); free(terms); goto invalid;
            }
            term->coefficient = intern_expression(coefficient, &expressions,
                &expression_count, &expression_capacity);
            if (term->coefficient == SIZE_MAX) {
                free(operands); free(terms); goto resource;
            }
            term->operands = calloc(operand_count, sizeof(size_t));
            term->operand_count = operand_count;
            if (operand_count && !term->operands) {
                free(operands); free(terms); goto resource;
            }
            for (operand_index = 0; operand_index < operand_count; ++operand_index) {
                term->operands[operand_index] = intern_expression(operands[operand_index],
                    &expressions, &expression_count, &expression_capacity);
                if (term->operands[operand_index] == SIZE_MAX) {
                    free(operands); free(terms); goto resource;
                }
            }
            free(operands);
        }
        free(terms);
    }
    /* TargetOrder is an ABI, not telemetry.  Require the complete
       lexicographic {form,row,column} rectangle before an adapter may reshape
       the returned channel stream. */
    if (dimensions[0] > SIZE_MAX / dimensions[1] ||
        dimensions[0] * dimensions[1] > SIZE_MAX / dimensions[2] ||
        record_count != dimensions[0] * dimensions[1] * dimensions[2])
        goto invalid;
    for (record_index = 0; record_index < record_count; ++record_index) {
        size_t zero = record_index;
        uint64_t expected[3];
        expected[2] = (uint64_t)(zero % dimensions[2] + 1); zero /= dimensions[2];
        expected[1] = (uint64_t)(zero % dimensions[1] + 1); zero /= dimensions[1];
        expected[0] = (uint64_t)(zero + 1);
        if (records[record_index].target[0] != expected[0] ||
            records[record_index].target[1] != expected[1] ||
            records[record_index].target[2] != expected[2]) goto invalid;
    }
    free(record_spans);
    *records_out = records; *record_count_out = record_count;
    *expressions_out = expressions; *expression_count_out = expression_count;
    *term_total_out = term_total; return ST_OK;
invalid:
    free(record_spans); free(expressions);
    for (record_index = 0; record_index < record_count; ++record_index) {
        for (size_t t = 0; t < records[record_index].term_count; ++t)
            free(records[record_index].terms[t].operands);
        free(records[record_index].terms);
    }
    free(records); return ST_PREPARATION_SCHEMA;
resource:
    free(record_spans); free(expressions);
    for (record_index = 0; record_index < record_count; ++record_index) {
        for (size_t t = 0; t < records[record_index].term_count; ++t)
            free(records[record_index].terms[t].operands);
        free(records[record_index].terms);
    }
    free(records); return ST_RESOURCE_LIMIT;
}

static void free_records(record_t *records, size_t count) {
    size_t r, t;
    for (r = 0; r < count; ++r) {
        for (t = 0; t < records[r].term_count; ++t)
            free(records[r].terms[t].operands);
        free(records[r].terms);
    }
    free(records);
}

static int write_u64(FILE *f, uint64_t value) {
    unsigned char b[8];
    size_t i;
    for (i = 0; i < 8; ++i) b[i] = (unsigned char)(value >> (8 * i));
    return fwrite(b, 1, 8, f) == 8;
}

static enum status_code write_output(const char *path, enum status_code status,
    const request_t *request, const record_t *records, size_t record_count,
    size_t term_count, size_t expression_count, const uint64_t dimensions[3],
    const uint64_t *channels, uint64_t parse_ns, uint64_t evaluation_ns,
    uint64_t detail_index, uint64_t detail_offset, int derivatives) {
    FILE *f = fopen(path, "wb");
    size_t r, count;
    uint64_t header[12];
    if (!f) return ST_OUTPUT_IO;
    if (fwrite(derivatives ? "DAGO2V1\0" : "DAGO1V1\0", 1, 8, f) != 8 ||
        !write_u64(f, status)) goto failed;
    if (status == ST_OK) {
        uint64_t values[] = {request->prime, request->rank, request->base_count,
            request->grade_count, record_count, term_count, expression_count,
            dimensions[0], dimensions[1], dimensions[2], parse_ns, evaluation_ns};
        memcpy(header, values, sizeof(header));
    } else {
        memset(header, 0, sizeof(header));
        header[7] = detail_index; header[8] = detail_offset;
    }
    for (r = 0; r < 12; ++r) if (!write_u64(f, header[r])) goto failed;
    if (status == ST_OK) {
        count = request->base_count * request->grade_count *
                (derivatives ? 3U : 1U);
        for (r = 0; r < record_count; ++r) {
            size_t axis, i;
            for (axis = 0; axis < 3; ++axis)
                if (!write_u64(f, records[r].target[axis])) goto failed;
            for (i = 0; i < count; ++i)
                if (!write_u64(f, channels[r * count + i])) goto failed;
        }
    }
    if (fclose(f)) return ST_OUTPUT_IO;
    return status;
failed:
    fclose(f); return ST_OUTPUT_IO;
}

int main(int argc, char **argv) {
    request_t request;
    enum status_code status;
    int fd = -1;
    struct stat st;
    unsigned char *data = MAP_FAILED;
    record_t *records = NULL;
    expression_t *expressions = NULL;
    size_t record_count = 0, expression_count = 0, term_count = 0;
    uint64_t dimensions[3] = {0, 0, 0};
    parser_t parser = {0};
    uint64_t *expression_values = NULL, *record_values = NULL, *channels = NULL;
    size_t expression_index, record_index, image, base, grade, sheet, root_index,
           component, components, image_stride, channel_stride;
    uint64_t detail_index = 0, detail_offset = 0;
    double started = now_seconds(), parsed_at, evaluated_at;
    int derivatives = argc == 5 && !strcmp(argv[4], "--derivatives");
    if (!(argc == 4 || derivatives)) {
        fprintf(stderr, "Status=%s Code=%d\n", status_name(ST_USAGE), ST_USAGE);
        return ST_USAGE;
    }
    status = load_request(argv[2], &request);
    if (status != ST_OK) goto finish;
    fd = open(argv[1], O_RDONLY);
    if (fd < 0 || fstat(fd, &st)) { status = ST_INPUT_IO; goto finish; }
    data = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (data == MAP_FAILED) { status = ST_INPUT_IO; goto finish; }
    status = load_records(data, (size_t)st.st_size, &records, &record_count,
        &expressions, &expression_count, &term_count, dimensions);
    if (status != ST_OK) goto finish;
    parsed_at = now_seconds();
    parser.request = &request;
    parser.derivatives = derivatives;
    components = derivatives ? 3U : 1U;
    image_stride = components * request.image_count;
    channel_stride = components * request.base_count * request.grade_count;
    parser.prefix = malloc(request.image_count * sizeof(uint64_t));
    if (!parser.prefix) { status = ST_RESOURCE_LIMIT; goto finish; }
    expression_values = malloc(expression_count * image_stride * sizeof(uint64_t));
    record_values = calloc(record_count * image_stride, sizeof(uint64_t));
    channels = calloc(record_count * channel_stride,
                      sizeof(uint64_t));
    if (!expression_values || !record_values || !channels) {
        status = ST_RESOURCE_LIMIT; goto finish;
    }
    for (root_index = 0; root_index < request.rank; ++root_index) {
        span_t root_span = {(const unsigned char *)request.root_expression[root_index],
            (const unsigned char *)request.root_expression[root_index] +
                strlen(request.root_expression[root_index])};
        uint64_t *root_square = expression_values; /* temporary reusable slot */
        status = evaluate_span(&parser, root_span, 0, root_square, &detail_offset);
        if (status != ST_OK) { detail_index = root_index + 1; goto finish; }
        for (image = 0; image < request.image_count; ++image)
            if (root_square[image] != request.delta[root_index][image]) {
                status = ST_ROOT_SQUARE_MISMATCH;
                detail_index = root_index + 1; detail_offset = image + 1; goto finish;
            }
    }
    for (expression_index = 0; expression_index < expression_count; ++expression_index) {
        status = evaluate_span(&parser, expressions[expression_index].span, 1,
            expression_values + expression_index * image_stride,
            &detail_offset);
        if (status != ST_OK) { detail_index = expression_index + 1; goto finish; }
    }
    for (record_index = 0; record_index < record_count; ++record_index) {
        size_t term_index;
        uint64_t *target = record_values + record_index * image_stride;
        for (term_index = 0; term_index < records[record_index].term_count; ++term_index) {
            term_t *term = &records[record_index].terms[term_index];
            uint64_t *coefficient = expression_values +
                                    term->coefficient * image_stride;
            size_t operand_index;
            for (image = 0; image < request.image_count; ++image) {
                uint64_t product = coefficient[image];
                uint64_t derivative_x = derivatives ?
                    coefficient[request.image_count + image] : 0;
                uint64_t derivative_y = derivatives ?
                    coefficient[2U * request.image_count + image] : 0;
                for (operand_index = 0; operand_index < term->operand_count;
                     ++operand_index) {
                    uint64_t *operand = expression_values +
                        term->operands[operand_index] * image_stride;
                    uint64_t operand_value = operand[image];
                    if (derivatives) {
                        derivative_x = addm(mulm(derivative_x, operand_value,
                            request.prime), mulm(product,
                            operand[request.image_count + image], request.prime),
                            request.prime);
                        derivative_y = addm(mulm(derivative_y, operand_value,
                            request.prime), mulm(product,
                            operand[2U * request.image_count + image],
                            request.prime), request.prime);
                    }
                    product = mulm(product, operand_value, request.prime);
                }
                target[image] = addm(target[image], product, request.prime);
                if (derivatives) {
                    target[request.image_count + image] = addm(
                        target[request.image_count + image], derivative_x,
                        request.prime);
                    target[2U * request.image_count + image] = addm(
                        target[2U * request.image_count + image], derivative_y,
                        request.prime);
                }
            }
        }
    }
    for (record_index = 0; record_index < record_count; ++record_index)
        for (component = 0; component < components; ++component)
          for (base = 0; base < request.base_count; ++base)
            for (grade = 0; grade < request.grade_count; ++grade) {
                uint64_t sum = 0, denominator = request.grade_count,
                         *target = record_values + record_index * image_stride +
                                   component * request.image_count;
                for (sheet = 0; sheet < request.grade_count; ++sheet) {
                    uint64_t value = target[base * request.grade_count + sheet];
                    if (__builtin_parityll((unsigned long long)(sheet & grade)))
                        sum = subm(sum, value, request.prime);
                    else sum = addm(sum, value, request.prime);
                }
                for (root_index = 0; root_index < request.rank; ++root_index)
                    if (grade & ((size_t)1U << root_index))
                        denominator = mulm(denominator,
                            request.root[root_index][base * request.grade_count],
                            request.prime);
                channels[record_index * channel_stride +
                         (component * request.base_count + base) *
                         request.grade_count + grade] =
                    mulm(sum, invm(denominator, request.prime), request.prime);
            }
    evaluated_at = now_seconds();
    status = write_output(argv[3], ST_OK, &request, records, record_count,
        term_count, expression_count, dimensions, channels,
        (uint64_t)((parsed_at - started) * 1e9),
        (uint64_t)((evaluated_at - parsed_at) * 1e9), 0, 0, derivatives);
finish:
    if (status != ST_OK && (argc == 4 || derivatives)) {
        enum status_code written = write_output(argv[3], status,
            &request, NULL, 0, 0, 0, dimensions, NULL, 0, 0,
            detail_index, detail_offset, derivatives);
        if (written == ST_OUTPUT_IO) status = ST_OUTPUT_IO;
    }
    fprintf(stderr, "Status=%s Code=%d Records=%zu Terms=%zu Unique=%zu "
        "Detail=%" PRIu64 ":%" PRIu64 " TotalSeconds=%.6f\n",
        status_name(status), status, record_count, term_count, expression_count,
        detail_index, detail_offset, now_seconds() - started);
    parser_destroy(&parser);
    free(expression_values); free(record_values); free(channels);
    free(expressions); free_records(records, record_count);
    if (data != MAP_FAILED) munmap(data, (size_t)st.st_size);
    if (fd >= 0) close(fd);
    free_request(&request);
    return status;
}
