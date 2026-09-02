// Family-neutral native evaluator for DeferredAST postfix programs over a
// 31-bit prime field.  The C ABI is consumed by deferred_native.py.

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <memory>
#include <numeric>
#include <stdexcept>
#include <vector>
#include <omp.h>

namespace {
enum : uint32_t { CONST = 1, INPUT, ADD, SUB, MUL, POW, INV, NEG };
constexpr uint32_t MAX_STACK = 32;

double elapsed(std::chrono::steady_clock::time_point at) {
    return std::chrono::duration<double>(std::chrono::steady_clock::now() - at).count();
}

uint32_t inverse32(uint32_t odd) {
    uint32_t x = odd;
    for (int i = 0; i < 5; ++i) x *= 2u - odd * x;
    return x;
}

struct Field {
    uint32_t p, np, one;
    explicit Field(uint32_t prime) : p(prime), np(0u - inverse32(prime)),
        one(uint32_t((uint64_t{1} << 32) % prime)) {}
    inline uint32_t add(uint32_t a, uint32_t b) const {
        uint32_t c = a + b; return c >= p ? c - p : c;
    }
    inline uint32_t sub(uint32_t a, uint32_t b) const {
        return a >= b ? a - b : p - (b - a);
    }
    inline uint32_t mul(uint32_t a, uint32_t b) const {
        uint64_t t = uint64_t(a) * b;
        uint32_t m = uint32_t(t) * np;
        uint64_t u = (t + uint64_t(m) * p) >> 32;
        return uint32_t(u >= p ? u - p : u);
    }
    uint32_t power(uint32_t a, uint32_t exponent) const {
        uint32_t result = one;
        while (exponent) {
            if (exponent & 1u) result = mul(result, a);
            exponent >>= 1;
            if (exponent) a = mul(a, a);
        }
        return result;
    }
};

struct Plan {
    uint32_t programs, constants, records, terms;
    std::vector<uint32_t> offsets, code, record_offsets, term_offsets, factors, order;
    bool two_factor_fast;
};

void copy_error(char *destination, uint64_t capacity, const char *message) {
    if (!destination || !capacity) return;
    std::strncpy(destination, message, size_t(capacity - 1));
    destination[capacity - 1] = '\0';
}

inline bool batch_inverse(uint32_t *values, uint32_t count, const Field &f,
                          uint32_t *scratch) {
    uint32_t product = f.one;
    for (uint32_t i = 0; i < count; ++i) {
        if (!values[i]) return false;
        scratch[i] = product;
        product = f.mul(product, values[i]);
    }
    uint32_t suffix = f.power(product, f.p - 2);
    for (uint32_t i = count; i-- > 0;) {
        uint32_t original = values[i];
        values[i] = f.mul(scratch[i], suffix);
        suffix = f.mul(suffix, original);
    }
    return true;
}

void validate_plan(const Plan &p) {
    if (!p.programs || p.offsets.size() != size_t(p.programs) + 1 ||
        p.offsets.front() || p.record_offsets.size() != size_t(p.records) + 1 ||
        p.record_offsets.front() || p.term_offsets.size() != size_t(p.terms) + 1 ||
        p.term_offsets.front() || p.record_offsets.back() != p.terms ||
        p.term_offsets.back() != p.factors.size())
        throw std::runtime_error("inconsistent postfix plan dimensions");
    for (uint32_t factor : p.factors)
        if (factor >= p.programs) throw std::runtime_error("factor index exceeds program count");
    for (uint32_t term = 0; term < p.terms; ++term)
        if (p.term_offsets[term] == p.term_offsets[term + 1])
            throw std::runtime_error("empty postfix assembly term");
}

void evaluate(const Plan &p, uint32_t prime, const uint32_t *constants,
              const uint32_t *inputs, uint32_t input_channels, uint32_t images,
              uint32_t bases, uint32_t rank, uint32_t grades, uint32_t threads,
              uint32_t *output, double *timings) {
    auto total_at = std::chrono::steady_clock::now();
    if (prime < 3 || prime >= (uint32_t{1} << 31) || !(prime & 1) ||
        !inputs || !output || (!constants && p.constants) || !threads || threads > 64 ||
        rank > 3 || grades != (1u << rank) || !bases || images != bases * grades ||
        input_channels < 3 + rank || images > 4096)
        throw std::runtime_error("invalid native evaluation request");
    Field f(prime);
    std::vector<uint32_t> expressions(size_t(p.programs) * images);
    std::vector<uint32_t> raw(size_t(p.records) * images);
    int bad = 0;
    omp_set_dynamic(0); omp_set_num_threads(int(threads));

    auto at = std::chrono::steady_clock::now();
#pragma omp parallel
    {
        std::vector<uint32_t> workspace(size_t(MAX_STACK + 1) * images);
        uint32_t *scratch = workspace.data() + size_t(MAX_STACK) * images;
#pragma omp for schedule(dynamic, 1)
        for (uint32_t ordered = 0; ordered < p.programs; ++ordered) {
            uint32_t program = p.order[ordered], sp = 0;
            bool okay = true;
            for (uint32_t pc = p.offsets[program]; pc < p.offsets[program + 1]; ++pc) {
                uint32_t instruction = p.code[pc];
                uint32_t op = instruction >> 28, arg = instruction & 0x0fffffffu;
                if (op == CONST || op == INPUT) {
                    if (sp == MAX_STACK || (op == CONST && arg >= p.constants) ||
                        (op == INPUT && arg >= input_channels)) { okay = false; break; }
                    uint32_t *destination = workspace.data() + size_t(sp++) * images;
                    if (op == CONST) std::fill_n(destination, images, constants[arg]);
                    else std::copy_n(inputs + size_t(arg) * images, images, destination);
                } else if (!sp) { okay = false; break;
                } else if (op == NEG) {
                    uint32_t *a = workspace.data() + size_t(sp - 1) * images;
#pragma omp simd
                    for (uint32_t i = 0; i < images; ++i) a[i] = a[i] ? f.p - a[i] : 0;
                } else if (op == INV) {
                    if (!batch_inverse(workspace.data() + size_t(sp - 1) * images,
                                       images, f, scratch)) { okay = false; break; }
                } else if (op == POW) {
                    uint32_t *a = workspace.data() + size_t(sp - 1) * images;
                    if (!arg) std::fill_n(a, images, f.one);
                    else if (arg > 1) {
                        std::copy_n(a, images, scratch);
                        std::fill_n(a, images, f.one);
                        uint32_t exponent = arg;
                        while (exponent) {
                            if (exponent & 1u) {
#pragma omp simd
                                for (uint32_t i = 0; i < images; ++i)
                                    a[i] = f.mul(a[i], scratch[i]);
                            }
                            exponent >>= 1;
                            if (exponent) {
#pragma omp simd
                                for (uint32_t i = 0; i < images; ++i)
                                    scratch[i] = f.mul(scratch[i], scratch[i]);
                            }
                        }
                    }
                } else {
                    if (sp < 2) { okay = false; break; }
                    uint32_t *b = workspace.data() + size_t(--sp) * images;
                    uint32_t *a = workspace.data() + size_t(sp - 1) * images;
                    if (op == ADD) {
#pragma omp simd
                        for (uint32_t i = 0; i < images; ++i) a[i] = f.add(a[i], b[i]);
                    } else if (op == SUB) {
#pragma omp simd
                        for (uint32_t i = 0; i < images; ++i) a[i] = f.sub(a[i], b[i]);
                    } else if (op == MUL) {
#pragma omp simd
                        for (uint32_t i = 0; i < images; ++i) a[i] = f.mul(a[i], b[i]);
                    } else { okay = false; break; }
                }
            }
            if (!okay || sp != 1) {
#pragma omp atomic write
                bad = 1;
            } else std::copy_n(workspace.data(), images,
                               expressions.data() + size_t(program) * images);
        }
    }
    if (bad) throw std::runtime_error("invalid postfix program or singular image");
    timings[0] = elapsed(at);

    at = std::chrono::steady_clock::now();
    if (p.two_factor_fast) {
#pragma omp parallel for schedule(static)
        for (uint64_t linear = 0; linear < uint64_t(p.records) * images; ++linear) {
            uint32_t record = uint32_t(linear / images), image = uint32_t(linear % images);
            uint32_t a = p.factors[2 * record], b = p.factors[2 * record + 1];
            raw[size_t(linear)] = f.mul(expressions[size_t(a) * images + image],
                                        expressions[size_t(b) * images + image]);
        }
    } else {
#pragma omp parallel for schedule(static)
        for (uint64_t linear = 0; linear < uint64_t(p.records) * images; ++linear) {
            uint32_t record = uint32_t(linear / images), image = uint32_t(linear % images);
            uint32_t total = 0;
            for (uint32_t term = p.record_offsets[record];
                 term < p.record_offsets[record + 1]; ++term) {
                uint32_t first = p.term_offsets[term];
                uint32_t product = expressions[size_t(p.factors[first]) * images + image];
                for (uint32_t factor = first + 1; factor < p.term_offsets[term + 1]; ++factor)
                    product = f.mul(product,
                        expressions[size_t(p.factors[factor]) * images + image]);
                total = f.add(total, product);
            }
            raw[size_t(linear)] = total;
        }
    }
    timings[1] = elapsed(at);

    at = std::chrono::steady_clock::now();
    std::vector<uint32_t> scale(size_t(bases) * grades);
    for (uint32_t base = 0; base < bases; ++base)
        for (uint32_t grade = 0; grade < grades; ++grade) {
            uint32_t denominator = grades * f.one % f.p;
            for (uint32_t root = 0; root < rank; ++root)
                if (grade & (1u << root))
                    denominator = f.mul(denominator,
                        inputs[size_t(3 + root) * images + base * grades]);
            scale[size_t(base) * grades + grade] =
                f.mul(f.power(denominator, f.p - 2), 1u);
        }
#pragma omp parallel for schedule(static)
    for (uint64_t rb = 0; rb < uint64_t(p.records) * bases; ++rb) {
        uint32_t record = uint32_t(rb / bases), base = uint32_t(rb % bases);
        uint32_t values[8];
        size_t begin = size_t(record) * images + base * grades;
        std::copy_n(raw.data() + begin, grades, values);
        for (uint32_t width = 1; width < grades; width <<= 1)
            for (uint32_t start = 0; start < grades; start += 2 * width)
                for (uint32_t j = 0; j < width; ++j) {
                    uint32_t a = values[start + j], b = values[start + width + j];
                    values[start + j] = f.add(a, b);
                    values[start + width + j] = f.sub(a, b);
                }
        for (uint32_t grade = 0; grade < grades; ++grade)
            output[begin + grade] = f.mul(values[grade], scale[size_t(base) * grades + grade]);
    }
    timings[2] = elapsed(at); timings[3] = elapsed(total_at);
}
} // namespace

extern "C" void *ffnative_plan_create(
    const uint32_t *offsets, uint32_t programs,
    const uint32_t *ops, const uint32_t *args, uint64_t instructions,
    uint32_t constants, const uint32_t *record_offsets, uint32_t records,
    const uint32_t *term_offsets, uint32_t terms,
    const uint32_t *factors, uint32_t factor_count,
    char *error, uint64_t error_capacity) {
    try {
        if (!offsets || !ops || !args || !record_offsets || !term_offsets || !factors)
            throw std::runtime_error("null postfix-plan array");
        auto plan = std::make_unique<Plan>();
        plan->programs = programs; plan->constants = constants;
        plan->records = records; plan->terms = terms;
        plan->offsets.assign(offsets, offsets + size_t(programs) + 1);
        if (plan->offsets.back() != instructions)
            throw std::runtime_error("instruction count disagrees with offsets");
        plan->code.resize(size_t(instructions));
        for (uint64_t i = 0; i < instructions; ++i) {
            if (ops[i] < CONST || ops[i] > NEG || args[i] >= (1u << 28))
                throw std::runtime_error("postfix instruction exceeds packed native ABI");
            plan->code[size_t(i)] = (ops[i] << 28) | args[i];
        }
        plan->record_offsets.assign(record_offsets, record_offsets + size_t(records) + 1);
        plan->term_offsets.assign(term_offsets, term_offsets + size_t(terms) + 1);
        plan->factors.assign(factors, factors + factor_count);
        plan->order.resize(programs); std::iota(plan->order.begin(), plan->order.end(), 0u);
        std::stable_sort(plan->order.begin(), plan->order.end(), [&](uint32_t a, uint32_t b) {
            return plan->offsets[a + 1] - plan->offsets[a] >
                   plan->offsets[b + 1] - plan->offsets[b];
        });
        plan->two_factor_fast = terms == records && factor_count == 2 * records;
        validate_plan(*plan); return plan.release();
    } catch (const std::exception &exception) {
        copy_error(error, error_capacity, exception.what()); return nullptr;
    }
}

extern "C" void ffnative_plan_destroy(void *opaque) {
    delete static_cast<Plan *>(opaque);
}

extern "C" int ffnative_evaluate(
    void *opaque, uint32_t prime, const uint32_t *constants,
    const uint32_t *inputs, uint32_t input_channels, uint32_t images,
    uint32_t bases, uint32_t rank, uint32_t grades, uint32_t threads,
    uint32_t *output, double *timings, char *error, uint64_t error_capacity) {
    try {
        if (!opaque || !timings) throw std::runtime_error("null native plan or timing output");
        evaluate(*static_cast<Plan *>(opaque), prime, constants, inputs,
                 input_channels, images, bases, rank, grades, threads, output, timings);
        return 0;
    } catch (const std::exception &exception) {
        copy_error(error, error_capacity, exception.what()); return 1;
    }
}
