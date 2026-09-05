#define main flint_deferred_ast_point_main
#include "../../../FeynFacet/Backends/flint/flint_deferred_ast_eval.c"
#undef main

/* Truncated-path-jet evaluator for a preserved BlockEquationDeferredV1 DAG.

   This deliberately includes the point evaluator above in the same
   translation unit.  The record loader, expression interning, fail-closed
   InputForm grammar helpers, modular arithmetic, primality test, status data-layout contract,
   and OpenMP policy therefore have one implementation.  Renaming its main
   keeps DAGO1V1/DAGO2V1 byte-for-byte untouched while this executable exposes
   a separate request and output data-layout contract.

   CLI:
     flint_deferred_path_jet INPUT.wl REQUEST.txt OUTPUT.bin [--threads N]

   See PROTOCOL_DAPJ1.md for the exact line and binary formats. */

enum { MAX_JET_ORDER = 64, MAX_JET_EPSILON_IMAGES = 4096 };

typedef struct {
    uint64_t prime;
    char *symbol[3];
    size_t order, coefficient_count, rank, epsilon_count;
    char *root_expression[MAX_RANK];
    uint64_t *epsilon, *x, *y;
    uint64_t *delta[MAX_RANK], *root[MAX_RANK];
} jet_request_t;

/* The upstream packed evaluator intentionally accepts only Taylor units.
   The sector-24 target rows contain explicit soft poles before their complete
   connection/embedding contraction, so this CF303-local diagnostic carries a
   valuation and an absolute precision cutoff during expression evaluation.
   The persisted DAPJ1 byte layout is unchanged: the caller multiplies each
   expression by a declared eighth power of the soft factor, and this fork
   requires the resulting Taylor series to be known through rho^10. */
enum { CF303_REQUIRED_SCALED_THROUGH = 10 };
typedef struct {
    uint64_t *x;
    int64_t valuation;
    int64_t cutoff;
    int ok;
} jet_value_t;

typedef struct jet_parser jet_parser_t;
struct jet_parser {
    const unsigned char *begin, *p, *end;
    const jet_request_t *request;
    size_t epsilon_index;
    uint64_t **slots;
    size_t slot_count, slot_capacity;
    enum status_code status;
    int allow_sqrt;
};

static void jet_series_zero(uint64_t *a, size_t n) {
    memset(a, 0, n * sizeof(*a));
}
static void jet_series_one(uint64_t *a, size_t n) {
    jet_series_zero(a, n);
    a[0] = 1;
}

static void jet_series_mul(uint64_t *out, const uint64_t *a,
                           const uint64_t *b, size_t n, uint64_t prime) {
    size_t degree, k;
    for (degree = 0; degree < n; ++degree) {
        uint64_t sum = 0;
        for (k = 0; k <= degree; ++k)
            sum = addm(sum, mulm(a[k], b[degree - k], prime), prime);
        out[degree] = sum;
    }
}

static int jet_series_inverse(uint64_t *out, const uint64_t *a,
                              size_t n, uint64_t prime) {
    size_t degree, k;
    uint64_t inverse_constant;
    if (a[0] == 0) return 0;
    inverse_constant = invm(a[0], prime);
    out[0] = inverse_constant;
    for (degree = 1; degree < n; ++degree) {
        uint64_t sum = 0;
        for (k = 1; k <= degree; ++k)
            sum = addm(sum, mulm(a[k], out[degree - k], prime), prime);
        out[degree] = mulm(sum ? prime - sum : 0, inverse_constant, prime);
    }
    return 1;
}

static int jet_series_power(uint64_t *out, const uint64_t *input,
                            int64_t exponent, size_t n, uint64_t prime) {
    uint64_t accumulator[MAX_JET_ORDER + 1];
    uint64_t base[MAX_JET_ORDER + 1];
    uint64_t temporary[MAX_JET_ORDER + 1];
    uint64_t inverse[MAX_JET_ORDER + 1];
    uint64_t magnitude = exponent < 0 ?
        (uint64_t)(-(exponent + 1)) + 1U : (uint64_t)exponent;
    jet_series_one(accumulator, n);
    if (exponent < 0) {
        if (!jet_series_inverse(inverse, input, n, prime)) return 0;
        memcpy(base, inverse, n * sizeof(*base));
    } else memcpy(base, input, n * sizeof(*base));
    while (magnitude) {
        if (magnitude & 1U) {
            jet_series_mul(temporary, accumulator, base, n, prime);
            memcpy(accumulator, temporary, n * sizeof(*accumulator));
        }
        magnitude >>= 1U;
        if (magnitude) {
            jet_series_mul(temporary, base, base, n, prime);
            memcpy(base, temporary, n * sizeof(*base));
        }
    }
    memcpy(out, accumulator, n * sizeof(*out));
    return 1;
}

static size_t laurent_length(int64_t valuation, int64_t cutoff) {
    return cutoff > valuation ? (size_t)(cutoff - valuation) : 0U;
}

static void laurent_normalize(uint64_t *a, int64_t *valuation,
                              int64_t cutoff) {
    size_t length = laurent_length(*valuation, cutoff), shift = 0;
    while (shift < length && a[shift] == 0) ++shift;
    if (shift == length) {
        jet_series_zero(a, length);
        *valuation = cutoff;
        return;
    }
    if (shift) {
        memmove(a, a + shift, (length - shift) * sizeof(*a));
        memset(a + length - shift, 0, shift * sizeof(*a));
        *valuation += (int64_t)shift;
    }
}

static uint64_t laurent_coefficient(const jet_value_t *value,
                                    int64_t exponent) {
    if (exponent < value->valuation || exponent >= value->cutoff) return 0;
    return value->x[(size_t)(exponent - value->valuation)];
}

static int laurent_multiply(uint64_t *out, int64_t *out_valuation,
    int64_t *out_cutoff, const uint64_t *a, int64_t a_valuation,
    int64_t a_cutoff, const uint64_t *b, int64_t b_valuation,
    int64_t b_cutoff, size_t capacity, uint64_t prime) {
    size_t degree, k, a_length, b_length, length;
    if (a_valuation >= a_cutoff || b_valuation >= b_cutoff) {
        *out_cutoff = a_cutoff + b_cutoff;
        *out_valuation = *out_cutoff;
        jet_series_zero(out, capacity);
        return 1;
    }
    *out_valuation = a_valuation + b_valuation;
    *out_cutoff = a_cutoff + b_valuation < b_cutoff + a_valuation ?
                  a_cutoff + b_valuation : b_cutoff + a_valuation;
    length = laurent_length(*out_valuation, *out_cutoff);
    if (length > capacity) return 0;
    a_length = laurent_length(a_valuation, a_cutoff);
    b_length = laurent_length(b_valuation, b_cutoff);
    jet_series_zero(out, capacity);
    for (degree = 0; degree < length; ++degree) {
        uint64_t sum = 0;
        size_t lower = degree >= b_length ? degree - b_length + 1U : 0U;
        size_t upper = degree < a_length ? degree : a_length - 1U;
        if (lower <= upper)
            for (k = lower; k <= upper; ++k)
                sum = addm(sum, mulm(a[k], b[degree - k], prime), prime);
        out[degree] = sum;
    }
    laurent_normalize(out, out_valuation, *out_cutoff);
    return 1;
}

static int laurent_inverse(uint64_t *out, int64_t *out_valuation,
    int64_t *out_cutoff, const uint64_t *a, int64_t valuation,
    int64_t cutoff, size_t capacity, uint64_t prime) {
    size_t degree, k, length = laurent_length(valuation, cutoff);
    uint64_t inverse_leading;
    if (!length || a[0] == 0 || length > capacity) return 0;
    inverse_leading = invm(a[0], prime);
    jet_series_zero(out, capacity);
    out[0] = inverse_leading;
    for (degree = 1; degree < length; ++degree) {
        uint64_t sum = 0;
        for (k = 1; k <= degree; ++k)
            sum = addm(sum, mulm(a[k], out[degree - k], prime), prime);
        out[degree] = mulm(sum ? prime - sum : 0, inverse_leading, prime);
    }
    *out_valuation = -valuation;
    *out_cutoff = cutoff - 2 * valuation;
    return 1;
}

static int laurent_power(uint64_t *out, int64_t *out_valuation,
    int64_t *out_cutoff, const uint64_t *input, int64_t input_valuation,
    int64_t input_cutoff, int64_t exponent, size_t capacity,
    uint64_t prime) {
    uint64_t accumulator[MAX_JET_ORDER + 1];
    uint64_t base[MAX_JET_ORDER + 1];
    uint64_t temporary[MAX_JET_ORDER + 1];
    uint64_t inverse[MAX_JET_ORDER + 1];
    int64_t accumulator_valuation = 0, accumulator_cutoff = (int64_t)capacity;
    int64_t base_valuation = input_valuation, base_cutoff = input_cutoff;
    int64_t temporary_valuation, temporary_cutoff;
    uint64_t magnitude = exponent < 0 ?
        (uint64_t)(-(exponent + 1)) + 1U : (uint64_t)exponent;
    jet_series_zero(accumulator, capacity);
    accumulator[0] = 1;
    memcpy(base, input, capacity * sizeof(*base));
    if (exponent < 0) {
        if (!laurent_inverse(inverse, &base_valuation, &base_cutoff,
              input, input_valuation, input_cutoff, capacity, prime))
            return 0;
        memcpy(base, inverse, capacity * sizeof(*base));
    }
    while (magnitude) {
        if (magnitude & 1U) {
            if (!laurent_multiply(temporary, &temporary_valuation,
                  &temporary_cutoff, accumulator, accumulator_valuation,
                  accumulator_cutoff, base, base_valuation, base_cutoff,
                  capacity, prime)) return 0;
            memcpy(accumulator, temporary, capacity * sizeof(*accumulator));
            accumulator_valuation = temporary_valuation;
            accumulator_cutoff = temporary_cutoff;
        }
        magnitude >>= 1U;
        if (magnitude) {
            if (!laurent_multiply(temporary, &temporary_valuation,
                  &temporary_cutoff, base, base_valuation, base_cutoff,
                  base, base_valuation, base_cutoff, capacity, prime))
                return 0;
            memcpy(base, temporary, capacity * sizeof(*base));
            base_valuation = temporary_valuation;
            base_cutoff = temporary_cutoff;
        }
    }
    memcpy(out, accumulator, capacity * sizeof(*out));
    *out_valuation = accumulator_valuation;
    *out_cutoff = accumulator_cutoff;
    return 1;
}

static void free_jet_request(jet_request_t *request) {
    size_t k;
    for (k = 0; k < 3; ++k) free(request->symbol[k]);
    for (k = 0; k < MAX_RANK; ++k) {
        free(request->root_expression[k]);
        free(request->delta[k]);
        free(request->root[k]);
    }
    free(request->epsilon);
    free(request->x);
    free(request->y);
    memset(request, 0, sizeof(*request));
}

static int jet_read_series(char *line, const char *prefix, uint64_t *series,
                           size_t count, uint64_t prime) {
    char *cursor;
    size_t i;
    if (strncmp(line, prefix, strlen(prefix))) return 0;
    cursor = line + strlen(prefix);
    for (i = 0; i < count; ++i)
        if (!parse_u64_token(&cursor, &series[i]) || series[i] >= prime)
            return 0;
    return *trim_line(cursor) == '\0';
}

static enum status_code load_jet_request(const char *path,
                                         jet_request_t *request) {
    FILE *file = fopen(path, "r");
    char *line = NULL, *p, *save, *token;
    size_t capacity = 0, k, i;
    ssize_t got;
    uint64_t value;
    memset(request, 0, sizeof(*request));
    if (!file) return ST_REQUEST_IO;
#define JET_NEXT_LINE() do { got = getline(&line, &capacity, file); \
    if (got < 0) { free(line); fclose(file); free_jet_request(request); \
        return ST_REQUEST_SCHEMA; } p = trim_line(line); } while (0)
    JET_NEXT_LINE();
    if (strcmp(p, "DeferredPathJetRequestV1")) goto schema;
    JET_NEXT_LINE();
    if (strncmp(p, "prime ", 6)) goto schema;
    p += 6;
    if (!parse_u64_token(&p, &request->prime) || *trim_line(p)) goto schema;
    if (!(3 < request->prime && request->prime < (UINT64_C(1) << 63)) ||
        !prime64(request->prime)) {
        free(line); fclose(file); free_jet_request(request);
        return ST_INVALID_PRIME;
    }
    JET_NEXT_LINE();
    if (strncmp(p, "variables ", 10)) goto schema;
    p += 10; save = NULL;
    for (k = 0; k < 3; ++k) {
        token = strtok_r(k ? NULL : p, " \t", &save);
        if (!token || !symbol_name(token)) goto schema;
        request->symbol[k] = strdup(token);
        if (!request->symbol[k]) goto resource;
    }
    if (strtok_r(NULL, " \t", &save) ||
        !strcmp(request->symbol[0], request->symbol[1]) ||
        !strcmp(request->symbol[0], request->symbol[2]) ||
        !strcmp(request->symbol[1], request->symbol[2])) goto schema;
    JET_NEXT_LINE();
    if (strncmp(p, "order ", 6)) goto schema;
    p += 6;
    if (!parse_u64_token(&p, &value) || *trim_line(p) ||
        value > MAX_JET_ORDER) goto schema;
    request->order = (size_t)value;
    request->coefficient_count = request->order + 1U;
    JET_NEXT_LINE();
    if (strncmp(p, "rank ", 5)) goto schema;
    p += 5;
    if (!parse_u64_token(&p, &value) || *trim_line(p) || value > MAX_RANK)
        goto schema;
    request->rank = (size_t)value;
    for (k = 0; k < request->rank; ++k) {
        JET_NEXT_LINE();
        if (strncmp(p, "root ", 5) || !p[5]) goto schema;
        request->root_expression[k] = strdup(p + 5);
        if (!request->root_expression[k]) goto resource;
    }
    JET_NEXT_LINE();
    if (strncmp(p, "epsilon_count ", 14)) goto schema;
    p += 14;
    if (!parse_u64_token(&p, &value) || *trim_line(p) || value == 0 ||
        value > MAX_JET_EPSILON_IMAGES) goto schema;
    request->epsilon_count = (size_t)value;
    request->epsilon = calloc(request->epsilon_count, sizeof(uint64_t));
    request->x = calloc(request->coefficient_count, sizeof(uint64_t));
    request->y = calloc(request->coefficient_count, sizeof(uint64_t));
    for (k = 0; k < request->rank; ++k) {
        request->delta[k] = calloc(request->coefficient_count, sizeof(uint64_t));
        request->root[k] = calloc(request->coefficient_count, sizeof(uint64_t));
    }
    if (!request->epsilon || !request->x || !request->y) goto resource;
    for (k = 0; k < request->rank; ++k)
        if (!request->delta[k] || !request->root[k]) goto resource;
    for (i = 0; i < request->epsilon_count; ++i) {
        JET_NEXT_LINE();
        if (strncmp(p, "epsilon ", 8)) goto schema;
        p += 8;
        if (!parse_u64_token(&p, &request->epsilon[i]) || *trim_line(p) ||
            request->epsilon[i] >= request->prime) goto schema;
    }
    JET_NEXT_LINE();
    if (!jet_read_series(p, "x_jet ", request->x,
                         request->coefficient_count, request->prime))
        goto schema;
    JET_NEXT_LINE();
    if (!jet_read_series(p, "y_jet ", request->y,
                         request->coefficient_count, request->prime))
        goto schema;
    for (k = 0; k < request->rank; ++k) {
        JET_NEXT_LINE();
        if (!jet_read_series(p, "delta_jet ", request->delta[k],
                             request->coefficient_count, request->prime))
            goto schema;
        JET_NEXT_LINE();
        if (!jet_read_series(p, "root_jet ", request->root[k],
                             request->coefficient_count, request->prime))
            goto schema;
    }
    while ((got = getline(&line, &capacity, file)) >= 0)
        if (*trim_line(line)) goto schema;
    free(line); fclose(file); return ST_OK;
schema:
    free(line); fclose(file); free_jet_request(request);
    return ST_REQUEST_SCHEMA;
resource:
    free(line); fclose(file); free_jet_request(request);
    return ST_RESOURCE_LIMIT;
#undef JET_NEXT_LINE
}

static void jet_continuation(jet_parser_t *parser) {
    ++parser->p;
    if (parser->p < parser->end && *parser->p == '\r') ++parser->p;
    if (parser->p < parser->end && *parser->p == '\n') ++parser->p;
    while (parser->p < parser->end &&
           (*parser->p == ' ' || *parser->p == '\t')) ++parser->p;
}

static void jet_space(jet_parser_t *parser) {
    for (;;) {
        while (parser->p < parser->end && isspace(*parser->p)) ++parser->p;
        if (parser->p < parser->end && *parser->p == '\\' &&
            parser->p + 1 < parser->end &&
            (parser->p[1] == '\n' || parser->p[1] == '\r'))
            jet_continuation(parser);
        else break;
    }
}

static jet_value_t jet_allocate_value(jet_parser_t *parser) {
    uint64_t *buffer;
    if (parser->slot_count == parser->slot_capacity) {
        size_t old = parser->slot_capacity;
        size_t next = old ? 2U * old : 32U;
        uint64_t **slots = realloc(parser->slots, next * sizeof(*slots));
        size_t i;
        if (!slots) {
            parser->status = ST_RESOURCE_LIMIT;
            return (jet_value_t){NULL, 0};
        }
        parser->slots = slots;
        for (i = old; i < next; ++i) parser->slots[i] = NULL;
        parser->slot_capacity = next;
    }
    buffer = parser->slots[parser->slot_count];
    if (!buffer) {
        buffer = malloc(parser->request->coefficient_count * sizeof(*buffer));
        if (!buffer) {
            parser->status = ST_RESOURCE_LIMIT;
            return (jet_value_t){NULL, 0};
        }
        parser->slots[parser->slot_count] = buffer;
    }
    ++parser->slot_count;
    return (jet_value_t){buffer, 0,
        (int64_t)parser->request->coefficient_count, 1};
}

static void jet_release_value(jet_parser_t *parser, jet_value_t value) {
    if (parser->slot_count &&
        parser->slots[parser->slot_count - 1U] == value.x)
        --parser->slot_count;
    else parser->status = ST_INTERNAL;
}

static jet_value_t jet_constant_value(jet_parser_t *parser, uint64_t value) {
    jet_value_t result = jet_allocate_value(parser);
    if (result.ok) {
        jet_series_zero(result.x, parser->request->coefficient_count);
        result.x[0] = value;
        if (!value) result.valuation = result.cutoff;
    }
    return result;
}

static jet_value_t jet_binary_value(jet_parser_t *parser, jet_value_t a,
                                    jet_value_t b, int operation) {
    size_t i, n = parser->request->coefficient_count;
    uint64_t prime = parser->request->prime;
    uint64_t left[MAX_JET_ORDER + 1];
    uint64_t right[MAX_JET_ORDER + 1];
    int64_t valuation, cutoff;
    if (!a.ok || !b.ok) return (jet_value_t){NULL, 0};
    if (operation == '+' || operation == '-') {
        valuation = a.valuation < b.valuation ? a.valuation : b.valuation;
        cutoff = a.cutoff < b.cutoff ? a.cutoff : b.cutoff;
        if (laurent_length(valuation, cutoff) > n) {
            parser->status = ST_RESOURCE_LIMIT;
            return (jet_value_t){NULL, 0};
        }
        jet_series_zero(left, n);
        for (i = 0; i < laurent_length(valuation, cutoff); ++i) {
            int64_t exponent = valuation + (int64_t)i;
            uint64_t av = laurent_coefficient(&a, exponent);
            uint64_t bv = laurent_coefficient(&b, exponent);
            left[i] = operation == '+' ? addm(av, bv, prime) :
                                         subm(av, bv, prime);
        }
        memcpy(a.x, left, n * sizeof(*a.x));
        a.valuation = valuation;
        a.cutoff = cutoff;
        laurent_normalize(a.x, &a.valuation, a.cutoff);
    } else if (operation == '*') {
        if (!laurent_multiply(left, &valuation, &cutoff,
              a.x, a.valuation, a.cutoff, b.x, b.valuation, b.cutoff,
              n, prime)) {
            parser->status = ST_RESOURCE_LIMIT;
            return (jet_value_t){NULL, 0};
        }
        memcpy(a.x, left, n * sizeof(*a.x));
        a.valuation = valuation;
        a.cutoff = cutoff;
    } else {
        int64_t inverse_valuation, inverse_cutoff;
        if (!laurent_inverse(right, &inverse_valuation, &inverse_cutoff,
              b.x, b.valuation, b.cutoff, n, prime) ||
            !laurent_multiply(left, &valuation, &cutoff,
              a.x, a.valuation, a.cutoff, right, inverse_valuation,
              inverse_cutoff, n, prime)) {
            parser->status = ST_SINGULAR_IMAGE;
            return (jet_value_t){NULL, 0};
        }
        memcpy(a.x, left, n * sizeof(*a.x));
        a.valuation = valuation;
        a.cutoff = cutoff;
    }
    jet_release_value(parser, b);
    return parser->status == ST_OK ? a : (jet_value_t){NULL, 0};
}

static jet_value_t jet_power_value(jet_parser_t *parser, jet_value_t value,
                                   int64_t exponent) {
    uint64_t result[MAX_JET_ORDER + 1];
    int64_t valuation, cutoff;
    if (!value.ok) return value;
    if (!laurent_power(result, &valuation, &cutoff, value.x,
          value.valuation, value.cutoff, exponent,
          parser->request->coefficient_count, parser->request->prime)) {
        parser->status = ST_SINGULAR_IMAGE;
        return (jet_value_t){NULL, 0};
    }
    memcpy(value.x, result,
           parser->request->coefficient_count * sizeof(*value.x));
    value.valuation = valuation;
    value.cutoff = cutoff;
    return value;
}

static int jet_declared_root_index(const jet_parser_t *parser, span_t base) {
    size_t i;
    if (!parser->allow_sqrt) return -1;
    for (i = 0; i < parser->request->rank; ++i)
        if (normalized_span_string(base,
                                   parser->request->root_expression[i]))
            return (int)i;
    return -1;
}

static jet_value_t jet_odd_half_power_value(jet_parser_t *parser,
                                            jet_value_t base,
                                            int64_t numerator,
                                            int root_index) {
    int64_t integer_power = (numerator - 1) / 2;
    uint64_t power[MAX_JET_ORDER + 1];
    uint64_t product[MAX_JET_ORDER + 1];
    size_t n = parser->request->coefficient_count;
    int64_t power_valuation, power_cutoff;
    int64_t product_valuation, product_cutoff;
    if (!laurent_power(power, &power_valuation, &power_cutoff, base.x,
          base.valuation, base.cutoff, integer_power, n,
          parser->request->prime) ||
        !laurent_multiply(product, &product_valuation, &product_cutoff,
          power, power_valuation, power_cutoff,
          parser->request->root[root_index], 0, (int64_t)n,
          n, parser->request->prime)) {
        parser->status = ST_SINGULAR_IMAGE;
        return (jet_value_t){NULL, 0};
    }
    memcpy(base.x, product, n * sizeof(*base.x));
    base.valuation = product_valuation;
    base.cutoff = product_cutoff;
    return base;
}

static jet_value_t jet_parse_sum(jet_parser_t *parser);

static jet_value_t jet_parse_primary(jet_parser_t *parser) {
    jet_value_t result = {NULL, 0};
    const jet_request_t *request = parser->request;
    int sign = 1;
    size_t i;
    span_t power_base = {NULL, NULL};
    jet_space(parser);
    while (parser->p < parser->end &&
           (*parser->p == '+' || *parser->p == '-')) {
        if (*parser->p++ == '-') sign = -sign;
        jet_space(parser);
    }
    if (parser->p >= parser->end) {
        parser->status = ST_UNSUPPORTED_EXPRESSION;
        return result;
    }
    if (*parser->p == '(') {
        ++parser->p;
        power_base.a = parser->p;
        result = jet_parse_sum(parser);
        power_base.b = parser->p;
        jet_space(parser);
        if (parser->p >= parser->end || *parser->p++ != ')')
            parser->status = ST_UNSUPPORTED_EXPRESSION;
    } else if (isdigit(*parser->p)) {
        uint64_t integer = 0;
        power_base.a = parser->p;
        while (parser->p < parser->end && isdigit(*parser->p))
            integer = addm(mulm(integer, 10, request->prime),
                (uint64_t)(*parser->p++ - '0'), request->prime);
        power_base.b = parser->p;
        result = jet_constant_value(parser, integer);
    } else {
        span_t symbol;
        symbol.a = parser->p;
        while (parser->p < parser->end &&
               (isalnum(*parser->p) || *parser->p == '$' ||
                *parser->p == '`')) ++parser->p;
        symbol.b = parser->p;
        if (symbol.a == symbol.b) {
            parser->status = ST_UNSUPPORTED_EXPRESSION;
            return result;
        }
        jet_space(parser);
        if (symbol_tail(symbol, "Sqrt") && parser->p < parser->end &&
            *parser->p == '[') {
            const unsigned char *argument_start, *argument_end;
            int root_index = -1;
            if (!parser->allow_sqrt) {
                parser->status = ST_UNDECLARED_RADICAL;
                return result;
            }
            ++parser->p;
            argument_start = parser->p;
            result = jet_parse_sum(parser);
            argument_end = parser->p;
            jet_space(parser);
            if (parser->p >= parser->end || *parser->p++ != ']') {
                parser->status = ST_UNSUPPORTED_EXPRESSION;
                return (jet_value_t){NULL, 0};
            }
            for (i = 0; i < request->rank; ++i)
                if (normalized_span_string(
                      (span_t){argument_start, argument_end},
                      request->root_expression[i])) {
                    root_index = (int)i;
                    break;
                }
            if (root_index < 0) {
                parser->status = ST_UNDECLARED_RADICAL;
                return (jet_value_t){NULL, 0};
            }
            memcpy(result.x, request->root[root_index],
                   request->coefficient_count * sizeof(*result.x));
            result.valuation = 0;
            result.cutoff = (int64_t)request->coefficient_count;
        } else if (symbol_tail(symbol, request->symbol[0]) ||
                   symbol_tail(symbol, request->symbol[1]) ||
                   symbol_tail(symbol, request->symbol[2])) {
            int variable_index = symbol_tail(symbol, request->symbol[0]) ? 0 :
                symbol_tail(symbol, request->symbol[1]) ? 1 : 2;
            result = jet_allocate_value(parser);
            if (result.ok) {
                if (variable_index == 0)
                    memcpy(result.x, request->x,
                           request->coefficient_count * sizeof(*result.x));
                else if (variable_index == 1)
                    memcpy(result.x, request->y,
                           request->coefficient_count * sizeof(*result.x));
                else {
                    jet_series_zero(result.x, request->coefficient_count);
                    result.x[0] = request->epsilon[parser->epsilon_index];
                }
                result.valuation = 0;
                result.cutoff = (int64_t)request->coefficient_count;
            }
            power_base = symbol;
        } else {
            parser->status = ST_UNSUPPORTED_EXPRESSION;
            return result;
        }
    }
    jet_space(parser);
    if (result.ok && parser->p < parser->end && *parser->p == '^') {
        uint64_t magnitude = 0, denominator = 1;
        int exponent_sign = 1, parenthesized = 0, rational = 0;
        int64_t exponent;
        ++parser->p;
        jet_space(parser);
        if (parser->p < parser->end && *parser->p == '(') {
            parenthesized = 1;
            ++parser->p;
            jet_space(parser);
        }
        if (parser->p < parser->end &&
            (*parser->p == '+' || *parser->p == '-'))
            if (*parser->p++ == '-') exponent_sign = -1;
        if (parser->p >= parser->end || !isdigit(*parser->p)) {
            parser->status = ST_UNSUPPORTED_EXPRESSION;
            return (jet_value_t){NULL, 0};
        }
        while (parser->p < parser->end && isdigit(*parser->p)) {
            unsigned digit = (unsigned)(*parser->p++ - '0');
            if (magnitude > ((uint64_t)INT64_MAX - digit) / 10U) {
                parser->status = ST_RESOURCE_LIMIT;
                return (jet_value_t){NULL, 0};
            }
            magnitude = 10U * magnitude + digit;
        }
        jet_space(parser);
        if (parenthesized && parser->p < parser->end && *parser->p == '/') {
            rational = 1;
            ++parser->p;
            jet_space(parser);
            denominator = 0;
            if (parser->p >= parser->end || !isdigit(*parser->p)) {
                parser->status = ST_UNSUPPORTED_EXPRESSION;
                return (jet_value_t){NULL, 0};
            }
            while (parser->p < parser->end && isdigit(*parser->p)) {
                unsigned digit = (unsigned)(*parser->p++ - '0');
                if (denominator > (UINT64_MAX - digit) / 10U) {
                    parser->status = ST_RESOURCE_LIMIT;
                    return (jet_value_t){NULL, 0};
                }
                denominator = 10U * denominator + digit;
            }
            jet_space(parser);
        }
        if (parenthesized &&
            (parser->p >= parser->end || *parser->p++ != ')')) {
            parser->status = ST_UNSUPPORTED_EXPRESSION;
            return (jet_value_t){NULL, 0};
        }
        exponent = exponent_sign < 0 ? -(int64_t)magnitude :
                                       (int64_t)magnitude;
        if (rational) {
            int root_index;
            if (denominator != 2 || !(magnitude & 1U)) {
                parser->status = ST_UNSUPPORTED_EXPRESSION;
                return (jet_value_t){NULL, 0};
            }
            root_index = power_base.a && power_base.b ?
                jet_declared_root_index(parser, power_base) : -1;
            if (root_index < 0) {
                parser->status = ST_UNDECLARED_RADICAL;
                return (jet_value_t){NULL, 0};
            }
            result = jet_odd_half_power_value(parser, result, exponent,
                                               root_index);
        } else result = jet_power_value(parser, result, exponent);
    }
    if (sign < 0 && result.ok)
        for (i = 0; i < laurent_length(result.valuation, result.cutoff); ++i)
            if (result.x[i]) result.x[i] = request->prime - result.x[i];
    return result;
}

static jet_value_t jet_parse_term(jet_parser_t *parser) {
    jet_value_t result = jet_parse_primary(parser);
    jet_space(parser);
    while (result.ok && parser->status == ST_OK && parser->p < parser->end &&
           (*parser->p == '*' || *parser->p == '/')) {
        int operation = *parser->p++;
        jet_value_t right = jet_parse_primary(parser);
        result = jet_binary_value(parser, result, right, operation);
        jet_space(parser);
    }
    return result;
}

static jet_value_t jet_parse_sum(jet_parser_t *parser) {
    jet_value_t result = jet_parse_term(parser);
    jet_space(parser);
    while (result.ok && parser->status == ST_OK && parser->p < parser->end &&
           (*parser->p == '+' || *parser->p == '-')) {
        int operation = *parser->p++;
        jet_value_t right = jet_parse_term(parser);
        result = jet_binary_value(parser, result, right, operation);
        jet_space(parser);
    }
    return result;
}

static void jet_parser_destroy(jet_parser_t *parser) {
    size_t i;
    for (i = 0; i < parser->slot_capacity; ++i) free(parser->slots[i]);
    free(parser->slots);
    memset(parser, 0, sizeof(*parser));
}

static enum status_code jet_evaluate_span(jet_parser_t *parser, span_t span,
                                          int allow_sqrt, uint64_t *output,
                                          size_t *offset) {
    jet_value_t value;
    parser->begin = span.a;
    parser->p = span.a;
    parser->end = span.b;
    parser->status = ST_OK;
    parser->slot_count = 0;
    parser->allow_sqrt = allow_sqrt;
    value = jet_parse_sum(parser);
    jet_space(parser);
    if (!value.ok || parser->status != ST_OK || parser->p != parser->end) {
        if (parser->status == ST_OK)
            parser->status = ST_UNSUPPORTED_EXPRESSION;
        if (offset) *offset = (size_t)(parser->p - parser->begin);
        return parser->status;
    }
    jet_series_zero(output, parser->request->coefficient_count);
    if (value.valuation < 0 ||
        value.cutoff <= CF303_REQUIRED_SCALED_THROUGH) {
        if (offset) *offset = value.valuation < 0 ?
            (size_t)(-value.valuation) : (size_t)value.cutoff;
        return ST_SINGULAR_IMAGE;
    }
    for (int64_t exponent = value.valuation;
         exponent < value.cutoff &&
         exponent < (int64_t)parser->request->coefficient_count;
         ++exponent)
        output[exponent] =
            value.x[(size_t)(exponent - value.valuation)];
    return ST_OK;
}

static enum status_code write_jet_output(const char *path,
    enum status_code status, const jet_request_t *request,
    const record_t *records, size_t record_count, size_t term_count,
    size_t expression_count, const uint64_t dimensions[3],
    const uint64_t *channels, uint64_t parse_ns, uint64_t evaluation_ns,
    uint64_t detail_index, uint64_t detail_offset) {
    FILE *file = fopen(path, "wb");
    uint64_t header[12];
    size_t i, record_index;
    if (!file) return ST_OUTPUT_IO;
    if (fwrite("DAPJ1V1\0", 1, 8, file) != 8 ||
        !write_u64(file, (uint64_t)status)) goto failed;
    if (status == ST_OK) {
        uint64_t values[] = {request->prime, request->order, request->rank,
            request->epsilon_count, record_count, term_count, expression_count,
            dimensions[0], dimensions[1], dimensions[2], parse_ns,
            evaluation_ns};
        memcpy(header, values, sizeof(header));
    } else {
        memset(header, 0, sizeof(header));
        header[7] = detail_index;
        header[8] = detail_offset;
    }
    for (i = 0; i < 12; ++i)
        if (!write_u64(file, header[i])) goto failed;
    if (status == ST_OK) {
        size_t channel_count = request->epsilon_count *
                               request->coefficient_count;
        for (record_index = 0; record_index < record_count; ++record_index) {
            size_t axis;
            for (axis = 0; axis < 3; ++axis)
                if (!write_u64(file, records[record_index].target[axis]))
                    goto failed;
            for (i = 0; i < channel_count; ++i)
                if (!write_u64(file,
                    channels[record_index * channel_count + i])) goto failed;
        }
    }
    if (fclose(file)) return ST_OUTPUT_IO;
    return status;
failed:
    fclose(file);
    return ST_OUTPUT_IO;
}

int main(int argc, char **argv) {
    jet_request_t request = {0};
    enum status_code status = ST_OK;
    int fd = -1, threads = 1, argument;
    struct stat st = {0};
    unsigned char *data = MAP_FAILED;
    record_t *records = NULL;
    expression_t *expressions = NULL;
    size_t record_count = 0, expression_count = 0, term_count = 0;
    uint64_t dimensions[3] = {0, 0, 0};
    uint64_t *expression_values = NULL, *channels = NULL;
    uint64_t detail_index = 0, detail_offset = 0;
    double started = now_seconds(), parsed_at = started, evaluated_at = started;
    size_t coefficient_count, expression_stride, channel_stride;
    if (argc < 4) {
        fprintf(stderr, "Status=%s Code=%d\n", status_name(ST_USAGE),
                ST_USAGE);
        return ST_USAGE;
    }
    for (argument = 4; argument < argc; ++argument) {
        if (!strcmp(argv[argument], "--threads") && argument + 1 < argc) {
            char *end = NULL;
            long parsed = strtol(argv[++argument], &end, 10);
            if (!end || *end || parsed < 1 || parsed > 8) {
                fprintf(stderr, "Status=%s Code=%d\n",
                        status_name(ST_USAGE), ST_USAGE);
                return ST_USAGE;
            }
            threads = (int)parsed;
        } else {
            fprintf(stderr, "Status=%s Code=%d\n", status_name(ST_USAGE),
                    ST_USAGE);
            return ST_USAGE;
        }
    }
    status = load_jet_request(argv[2], &request);
    if (status != ST_OK) goto finish;
    if ((size_t)threads > request.epsilon_count)
        threads = (int)request.epsilon_count;
    coefficient_count = request.coefficient_count;
    fd = open(argv[1], O_RDONLY);
    if (fd < 0 || fstat(fd, &st)) {
        status = ST_INPUT_IO;
        goto finish;
    }
    data = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (data == MAP_FAILED) {
        status = ST_INPUT_IO;
        goto finish;
    }
    status = load_records(data, (size_t)st.st_size, &records, &record_count,
        &expressions, &expression_count, &term_count, dimensions);
    if (status != ST_OK) goto finish;
    parsed_at = now_seconds();
    for (size_t root_index = 0; root_index < request.rank; ++root_index) {
        uint64_t square[MAX_JET_ORDER + 1];
        jet_series_mul(square, request.root[root_index],
            request.root[root_index], coefficient_count, request.prime);
        if (request.root[root_index][0] == 0 ||
            memcmp(square, request.delta[root_index],
                   coefficient_count * sizeof(*square))) {
            status = ST_ROOT_VALUE_MISMATCH;
            detail_index = root_index + 1U;
            goto finish;
        }
    }
    for (size_t epsilon_index = 0; epsilon_index < request.epsilon_count;
         ++epsilon_index) {
        jet_parser_t parser = {0};
        parser.request = &request;
        parser.epsilon_index = epsilon_index;
        for (size_t root_index = 0; root_index < request.rank; ++root_index) {
            span_t root_span = {
                (const unsigned char *)request.root_expression[root_index],
                (const unsigned char *)request.root_expression[root_index] +
                    strlen(request.root_expression[root_index])};
            uint64_t evaluated[MAX_JET_ORDER + 1];
            size_t offset = 0;
            status = jet_evaluate_span(&parser, root_span, 0, evaluated,
                                       &offset);
            if (status != ST_OK) {
                detail_index = root_index + 1U;
                detail_offset = offset;
                jet_parser_destroy(&parser);
                goto finish;
            }
            if (memcmp(evaluated, request.delta[root_index],
                       coefficient_count * sizeof(*evaluated))) {
                status = ST_ROOT_SQUARE_MISMATCH;
                detail_index = root_index + 1U;
                detail_offset = epsilon_index + 1U;
                jet_parser_destroy(&parser);
                goto finish;
            }
        }
        jet_parser_destroy(&parser);
    }
    if (expression_count > SIZE_MAX / request.epsilon_count ||
        expression_count * request.epsilon_count >
            SIZE_MAX / coefficient_count ||
        expression_count * request.epsilon_count * coefficient_count >
            SIZE_MAX / sizeof(*expression_values) ||
        record_count > SIZE_MAX / request.epsilon_count ||
        record_count * request.epsilon_count > SIZE_MAX / coefficient_count ||
        record_count * request.epsilon_count * coefficient_count >
            SIZE_MAX / sizeof(*channels)) {
        status = ST_RESOURCE_LIMIT;
        goto finish;
    }
    expression_stride = request.epsilon_count * coefficient_count;
    channel_stride = expression_stride;
    expression_values = malloc((expression_count ?
        expression_count * expression_stride : 1U) *
        sizeof(*expression_values));
    channels = calloc(record_count * channel_stride, sizeof(*channels));
    if (!expression_values || !channels) {
        status = ST_RESOURCE_LIMIT;
        goto finish;
    }
    {
        enum status_code parallel_status = ST_OK;
        uint64_t parallel_index = 0, parallel_offset = 0;
#pragma omp parallel num_threads(threads)
        {
            jet_parser_t parser = {0};
            parser.request = &request;
#pragma omp for schedule(static)
            for (size_t epsilon_index = 0;
                 epsilon_index < request.epsilon_count; ++epsilon_index) {
                parser.epsilon_index = epsilon_index;
                for (size_t expression_index = 0;
                     expression_index < expression_count; ++expression_index) {
                    size_t offset = 0;
                    enum status_code local_status = jet_evaluate_span(&parser,
                        expressions[expression_index].span, 1,
                        expression_values + expression_index *
                            expression_stride + epsilon_index *
                            coefficient_count, &offset);
                    if (local_status != ST_OK) {
#pragma omp critical(deferred_path_jet_failure)
                        {
                            if (parallel_status == ST_OK ||
                                expression_index + 1U < parallel_index) {
                                parallel_status = local_status;
                                parallel_index = expression_index + 1U;
                                parallel_offset = offset;
                            }
                        }
                        break;
                    }
                }
            }
            jet_parser_destroy(&parser);
        }
        if (parallel_status != ST_OK) {
            status = parallel_status;
            detail_index = parallel_index;
            detail_offset = parallel_offset;
            goto finish;
        }
    }
#pragma omp parallel for num_threads(threads) schedule(static)
    for (size_t epsilon_index = 0; epsilon_index < request.epsilon_count;
         ++epsilon_index) {
        uint64_t product[MAX_JET_ORDER + 1];
        uint64_t temporary[MAX_JET_ORDER + 1];
        for (size_t record_index = 0; record_index < record_count;
             ++record_index) {
            uint64_t *target = channels + record_index * channel_stride +
                               epsilon_index * coefficient_count;
            for (size_t term_index = 0;
                 term_index < records[record_index].term_count; ++term_index) {
                term_t *term = &records[record_index].terms[term_index];
                const uint64_t *coefficient = expression_values +
                    term->coefficient * expression_stride +
                    epsilon_index * coefficient_count;
                memcpy(product, coefficient,
                       coefficient_count * sizeof(*product));
                for (size_t operand_index = 0;
                     operand_index < term->operand_count; ++operand_index) {
                    const uint64_t *operand = expression_values +
                        term->operands[operand_index] * expression_stride +
                        epsilon_index * coefficient_count;
                    jet_series_mul(temporary, product, operand,
                                   coefficient_count, request.prime);
                    memcpy(product, temporary,
                           coefficient_count * sizeof(*product));
                }
                for (size_t degree = 0; degree < coefficient_count; ++degree)
                    target[degree] = addm(target[degree], product[degree],
                                          request.prime);
            }
        }
    }
    evaluated_at = now_seconds();
    status = write_jet_output(argv[3], ST_OK, &request, records, record_count,
        term_count, expression_count, dimensions, channels,
        (uint64_t)((parsed_at - started) * 1e9),
        (uint64_t)((evaluated_at - parsed_at) * 1e9), 0, 0);
finish:
    if (status != ST_OK) {
        enum status_code written = write_jet_output(argv[3], status,
            &request, NULL, 0, 0, 0, dimensions, NULL, 0, 0,
            detail_index, detail_offset);
        if (written == ST_OUTPUT_IO) status = ST_OUTPUT_IO;
    }
    fprintf(stderr, "Status=%s Code=%d Records=%zu Terms=%zu Unique=%zu "
        "Order=%zu EpsilonImages=%zu Detail=%" PRIu64 ":%" PRIu64
        " Threads=%d TotalSeconds=%.6f\n", status_name(status), status,
        record_count, term_count, expression_count, request.order,
        request.epsilon_count, detail_index, detail_offset, threads,
        now_seconds() - started);
    free(expression_values);
    free(channels);
    free(expressions);
    free_records(records, record_count);
    if (data != MAP_FAILED) munmap(data, (size_t)st.st_size);
    if (fd >= 0) close(fd);
    free_jet_request(&request);
    return status;
}
