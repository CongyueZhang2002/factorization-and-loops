// Exact native-CPU benchmark for the cached CF259 CUDA postfix workload.
// Benchmark-only code: this is not a production fallback.

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <numeric>
#include <stdexcept>
#include <string>
#include <vector>
#include <omp.h>
#ifdef __linux__
#include <sched.h>
#endif

namespace {
enum : uint32_t { CONST = 1, INPUT, ADD, SUB, MUL, POW, INV, NEG };
constexpr uint32_t MAX_STACK = 32, FIXTURE_IMAGES = 88;

struct Header {
    char magic[8];
    uint64_t version, prime, programs, instructions, constants;
    uint64_t input_channels, images, bases, rank, grades;
    uint64_t records, terms, factors, reference_values;
};
static_assert(sizeof(Header) == 120);

struct Payload {
    Header h{};
    std::vector<uint32_t> offsets, code, constants, inputs;
    std::vector<uint32_t> record_offsets, term_offsets, factors, reference;
};

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

template <class T>
void read_vector(std::ifstream &in, std::vector<T> &v, uint64_t n) {
    if (n > std::numeric_limits<size_t>::max() / sizeof(T))
        throw std::runtime_error("payload section too large");
    v.resize(size_t(n));
    in.read(reinterpret_cast<char *>(v.data()), std::streamsize(v.size() * sizeof(T)));
    if (!in) throw std::runtime_error("truncated payload");
}

Payload load_payload(const std::string &path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) throw std::runtime_error("cannot open payload");
    Payload x;
    in.read(reinterpret_cast<char *>(&x.h), sizeof(x.h));
    if (!in || std::memcmp(x.h.magic, "CFCPU1V1", 8) || x.h.version != 1)
        throw std::runtime_error("bad payload header");
    read_vector(in, x.offsets, x.h.programs + 1);
    read_vector(in, x.code, x.h.instructions);
    read_vector(in, x.constants, x.h.constants);
    read_vector(in, x.inputs, x.h.input_channels * x.h.images);
    read_vector(in, x.record_offsets, x.h.records + 1);
    read_vector(in, x.term_offsets, x.h.terms + 1);
    read_vector(in, x.factors, x.h.factors);
    read_vector(in, x.reference, x.h.reference_values);
    char c;
    if (in.read(&c, 1)) throw std::runtime_error("trailing payload data");
    if (x.h.images != FIXTURE_IMAGES || x.h.images != x.h.bases * x.h.grades ||
        x.h.grades != (uint64_t{1} << x.h.rank) || x.h.grades > 8 ||
        x.h.reference_values != x.h.records * x.h.images ||
        x.offsets.back() != x.h.instructions ||
        x.record_offsets.back() != x.h.terms || x.term_offsets.back() != x.h.factors)
        throw std::runtime_error("inconsistent payload dimensions");
    for (uint32_t i : x.factors)
        if (i >= x.h.programs) throw std::runtime_error("bad factor index");
    return x;
}

inline bool batch_inverse(uint32_t *v, uint32_t n, const Field &f,
                          uint32_t *scratch) {
    uint32_t product = f.one;
    for (uint32_t i = 0; i < n; ++i) {
        if (!v[i]) return false;
        scratch[i] = product;
        product = f.mul(product, v[i]);
    }
    uint32_t suffix = f.power(product, f.p - 2);
    for (uint32_t i = n; i-- > 0;) {
        uint32_t original = v[i];
        v[i] = f.mul(scratch[i], suffix);
        suffix = f.mul(suffix, original);
    }
    return true;
}

struct Timings { double expressions{}, assembly{}, channels{}, total{}; };

Timings evaluate(const Payload &x, int threads, std::vector<uint32_t> &out,
                 std::vector<int> &cpus) {
    const Field f(uint32_t(x.h.prime));
    const uint32_t images = uint32_t(x.h.images), programs = uint32_t(x.h.programs);
    std::vector<uint32_t> expr(size_t(programs) * images);
    std::vector<uint32_t> raw(size_t(x.h.records) * images);
    out.resize(size_t(x.h.records) * images);
    std::vector<uint32_t> order(programs);
    std::iota(order.begin(), order.end(), 0u);
    std::stable_sort(order.begin(), order.end(), [&](uint32_t a, uint32_t b) {
        return x.offsets[a + 1] - x.offsets[a] > x.offsets[b + 1] - x.offsets[b];
    });

    omp_set_dynamic(0); omp_set_num_threads(threads);
    cpus.assign(threads, -1);
    int bad = 0;
    auto total_at = std::chrono::steady_clock::now(), at = total_at;
#pragma omp parallel
    {
        int tid = omp_get_thread_num();
#ifdef __linux__
        cpus[tid] = sched_getcpu();
#endif
        alignas(64) uint32_t stack[MAX_STACK][FIXTURE_IMAGES];
        alignas(64) uint32_t scratch[FIXTURE_IMAGES];
#pragma omp for schedule(dynamic, 1)
        for (uint32_t oi = 0; oi < programs; ++oi) {
            uint32_t program = order[oi], sp = 0;
            bool okay = true;
            for (uint32_t pc = x.offsets[program]; pc < x.offsets[program + 1]; ++pc) {
                uint32_t insn = x.code[pc], op = insn >> 28, arg = insn & 0x0fffffffu;
                if (op == CONST || op == INPUT) {
                    if (sp == MAX_STACK || (op == CONST && arg >= x.h.constants) ||
                        (op == INPUT && arg >= x.h.input_channels)) { okay = false; break; }
                    uint32_t *dst = stack[sp++];
                    if (op == CONST) std::fill_n(dst, images, x.constants[arg]);
                    else std::copy_n(x.inputs.data() + size_t(arg) * images, images, dst);
                } else if (!sp) { okay = false; break;
                } else if (op == NEG) {
                    uint32_t *a = stack[sp - 1];
#pragma omp simd
                    for (uint32_t i = 0; i < images; ++i) a[i] = a[i] ? f.p - a[i] : 0;
                } else if (op == INV) {
                    if (!batch_inverse(stack[sp - 1], images, f, scratch)) {
                        okay = false; break;
                    }
                } else if (op == POW) {
                    uint32_t *a = stack[sp - 1];
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
                    uint32_t *b = stack[--sp], *a = stack[sp - 1];
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
            } else std::copy_n(stack[0], images, expr.data() + size_t(program) * images);
        }
    }
    if (bad) throw std::runtime_error("invalid postfix program or singular image");
    Timings t; t.expressions = elapsed(at);

    at = std::chrono::steady_clock::now();
    bool fast = x.h.terms == x.h.records && x.h.factors == 2 * x.h.records;
    if (fast) {
#pragma omp parallel for schedule(static)
        for (uint64_t k = 0; k < x.h.records * x.h.images; ++k) {
            uint32_t r = uint32_t(k / images), i = uint32_t(k % images);
            uint32_t a = x.factors[2 * r], b = x.factors[2 * r + 1];
            raw[size_t(k)] = f.mul(expr[size_t(a) * images + i],
                                   expr[size_t(b) * images + i]);
        }
    } else {
#pragma omp parallel for schedule(static)
        for (uint64_t k = 0; k < x.h.records * x.h.images; ++k) {
            uint32_t r = uint32_t(k / images), i = uint32_t(k % images), total = 0;
            for (uint32_t term = x.record_offsets[r]; term < x.record_offsets[r + 1]; ++term) {
                uint32_t first = x.term_offsets[term];
                uint32_t product = expr[size_t(x.factors[first]) * images + i];
                for (uint32_t factor = first + 1; factor < x.term_offsets[term + 1]; ++factor)
                    product = f.mul(product, expr[size_t(x.factors[factor]) * images + i]);
                total = f.add(total, product);
            }
            raw[size_t(k)] = total;
        }
    }
    t.assembly = elapsed(at);

    at = std::chrono::steady_clock::now();
    std::vector<uint32_t> scale(size_t(x.h.bases) * x.h.grades);
    for (uint32_t base = 0; base < x.h.bases; ++base)
        for (uint32_t grade = 0; grade < x.h.grades; ++grade) {
            uint32_t denominator = uint32_t(x.h.grades) * f.one % f.p;
            for (uint32_t root = 0; root < x.h.rank; ++root)
                if (grade & (1u << root))
                    denominator = f.mul(denominator,
                        x.inputs[size_t(3 + root) * images + base * x.h.grades]);
            scale[size_t(base) * x.h.grades + grade] =
                f.mul(f.power(denominator, f.p - 2), 1u);
        }
#pragma omp parallel for schedule(static)
    for (uint64_t rb = 0; rb < x.h.records * x.h.bases; ++rb) {
        uint32_t record = uint32_t(rb / x.h.bases), base = uint32_t(rb % x.h.bases);
        uint32_t values[8];
        size_t begin = size_t(record) * images + base * x.h.grades;
        std::copy_n(raw.data() + begin, x.h.grades, values);
        for (uint32_t width = 1; width < x.h.grades; width <<= 1)
            for (uint32_t start = 0; start < x.h.grades; start += 2 * width)
                for (uint32_t j = 0; j < width; ++j) {
                    uint32_t a = values[start + j], b = values[start + width + j];
                    values[start + j] = f.add(a, b);
                    values[start + width + j] = f.sub(a, b);
                }
        for (uint32_t grade = 0; grade < x.h.grades; ++grade)
            out[begin + grade] = f.mul(values[grade], scale[size_t(base) * x.h.grades + grade]);
    }
    t.channels = elapsed(at); t.total = elapsed(total_at); return t;
}

std::vector<int> parse_threads(const std::string &s) {
    std::vector<int> result; size_t at = 0;
    while (at < s.size()) {
        size_t comma = s.find(',', at);
        int n = std::stoi(s.substr(at, comma == std::string::npos ? comma : comma - at));
        if (n < 1 || n > 16) throw std::runtime_error("threads must be in 1..16");
        result.push_back(n); if (comma == std::string::npos) break; at = comma + 1;
    }
    return result;
}

void print_cpus(const std::vector<int> &cpus) {
    std::cout << '[';
    for (size_t i = 0; i < cpus.size(); ++i) { if (i) std::cout << ','; std::cout << cpus[i]; }
    std::cout << ']';
}
} // namespace

int main(int argc, char **argv) try {
    if (argc < 3 || argc > 5) {
        std::cerr << "usage: " << argv[0] << " PAYLOAD THREADS[,..] [REPEATS] [LAST_OUTPUT]\n";
        return 2;
    }
    auto at = std::chrono::steady_clock::now();
    Payload p = load_payload(argv[1]);
    double read_s = elapsed(at);
    at = std::chrono::steady_clock::now(); Field field(uint32_t(p.h.prime)); (void)field;
    double setup_s = elapsed(at);
    auto thread_counts = parse_threads(argv[2]);
    int repeats = argc >= 4 ? std::stoi(argv[3]) : 1;
    if (repeats < 1 || repeats > 20) throw std::runtime_error("repeats must be 1..20");
    std::cout << "{\"phase\":\"cpu_cold_setup\",\"payload_read_s\":" << read_s
              << ",\"field_setup_s\":" << setup_s << "}\n";
    std::vector<uint32_t> output;
    for (int threads : thread_counts) for (int repeat = 1; repeat <= repeats; ++repeat) {
        std::vector<int> cpus;
        auto call_at = std::chrono::steady_clock::now();
        Timings t = evaluate(p, threads, output, cpus);
        double call_wall_s = elapsed(call_at);
        bool equal = output.size() == p.reference.size() &&
            std::memcmp(output.data(), p.reference.data(), output.size() * 4) == 0;
        size_t first_bad = output.size();
        if (!equal) for (size_t i = 0; i < std::min(output.size(), p.reference.size()); ++i)
            if (output[i] != p.reference[i]) { first_bad = i; break; }
        std::cout << "{\"phase\":\"cpu_warm_evaluation\",\"threads\":" << threads
                  << ",\"repeat\":" << repeat << ",\"cpus\":"; print_cpus(cpus);
        std::cout << ",\"expression_s\":" << t.expressions
                  << ",\"assembly_s\":" << t.assembly << ",\"channels_s\":" << t.channels
                  << ",\"total_s\":" << t.total << ",\"call_wall_s\":" << call_wall_s
                  << ",\"byte_equal_gpu\":"
                  << (equal ? "true" : "false") << ",\"compared_bytes\":" << output.size() * 4;
        if (!equal) std::cout << ",\"first_mismatch\":" << first_bad;
        std::cout << "}\n" << std::flush; if (!equal) return 3;
    }
    if (argc >= 5) {
        std::ofstream out(argv[4], std::ios::binary);
        out.write(reinterpret_cast<const char *>(output.data()), std::streamsize(output.size() * 4));
    }
    return 0;
} catch (const std::exception &e) {
    std::cerr << "cf259_cpu_postfix_benchmark: " << e.what() << '\n'; return 1;
}
