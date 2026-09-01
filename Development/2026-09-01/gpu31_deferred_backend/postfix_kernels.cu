#include <cstdint>

enum : uint32_t { CONST = 1, INPUT, ADD, SUB, MUL, POW, INV, NEG };

__device__ __forceinline__ uint32_t addm(uint32_t a, uint32_t b, uint32_t p) {
    uint32_t c = a + b;
    return c >= p ? c - p : c;
}

__device__ __forceinline__ uint32_t subm(uint32_t a, uint32_t b, uint32_t p) {
    return a >= b ? a - b : p - (b - a);
}

__device__ __forceinline__ uint32_t mont(uint32_t a, uint32_t b,
                                         uint32_t p, uint32_t nprime) {
    uint64_t t = uint64_t(a) * b;
    uint32_t m = uint32_t(t) * nprime;
    uint64_t u = (t + uint64_t(m) * p) >> 32;
    return uint32_t(u >= p ? u - p : u);
}

__device__ __forceinline__ uint32_t power(uint32_t a, uint32_t exponent,
                                          uint32_t p, uint32_t nprime,
                                          uint32_t one) {
    uint32_t result = one;
    while (exponent) {
        if (exponent & 1) result = mont(result, a, p, nprime);
        a = mont(a, a, p, nprime);
        exponent >>= 1;
    }
    return result;
}

extern "C" __global__ __launch_bounds__(128) void ff31_eval(
    const uint32_t *__restrict__ offsets,
    const uint32_t *__restrict__ ops,
    const uint32_t *__restrict__ args,
    const uint32_t *__restrict__ constants,
    const uint32_t *__restrict__ inputs,
    uint32_t *__restrict__ output,
    uint32_t *__restrict__ status,
    uint32_t program_start,
    uint32_t program_batch,
    uint32_t image_count,
    uint32_t prime,
    uint32_t nprime,
    uint32_t one) {
    uint32_t linear = blockIdx.x * blockDim.x + threadIdx.x;
    if (linear >= program_batch * image_count) return;
    uint32_t program = program_start + linear / image_count;
    uint32_t image = linear % image_count;
    uint32_t stack[32], sp = 0;
    for (uint32_t pc = offsets[program]; pc < offsets[program + 1]; ++pc) {
        uint32_t op = ops[pc], arg = args[pc];
        if (op == CONST || op == INPUT) {
            if (sp == 32) { atomicOr(status, 2U); return; }
            stack[sp++] = op == CONST ? constants[arg]
                                      : inputs[arg * image_count + image];
            continue;
        }
        if (!sp) { atomicOr(status, 2U); return; }
        if (op == POW) stack[sp - 1] = power(stack[sp - 1], arg, prime, nprime, one);
        else if (op == INV) {
            if (!stack[sp - 1]) { atomicOr(status, 1U); return; }
            stack[sp - 1] = power(stack[sp - 1], prime - 2, prime, nprime, one);
        } else if (op == NEG) {
            if (stack[sp - 1]) stack[sp - 1] = prime - stack[sp - 1];
        } else {
            if (sp < 2) { atomicOr(status, 2U); return; }
            uint32_t b = stack[--sp], a = stack[sp - 1];
            if (op == ADD) stack[sp - 1] = addm(a, b, prime);
            else if (op == SUB) stack[sp - 1] = subm(a, b, prime);
            else if (op == MUL) stack[sp - 1] = mont(a, b, prime, nprime);
            else { atomicOr(status, 2U); return; }
        }
    }
    if (sp != 1) { atomicOr(status, 2U); return; }
    output[program * image_count + image] = stack[0];
}

extern "C" __global__ __launch_bounds__(128) void ff31_assemble(
    const uint32_t *__restrict__ record_offsets,
    const uint32_t *__restrict__ term_offsets,
    const uint32_t *__restrict__ factors,
    const uint32_t *__restrict__ expressions,
    uint32_t *__restrict__ output,
    uint32_t record_count,
    uint32_t image_count,
    uint32_t prime,
    uint32_t nprime) {
    uint32_t linear = blockIdx.x * blockDim.x + threadIdx.x;
    if (linear >= record_count * image_count) return;
    uint32_t record = linear / image_count;
    uint32_t image = linear % image_count;
    uint32_t total = 0;
    for (uint32_t term = record_offsets[record];
         term < record_offsets[record + 1]; ++term) {
        uint32_t first = term_offsets[term];
        uint32_t product = expressions[factors[first] * image_count + image];
        for (uint32_t factor = first + 1; factor < term_offsets[term + 1]; ++factor)
            product = mont(product,
                expressions[factors[factor] * image_count + image], prime, nprime);
        total = addm(total, product, prime);
    }
    output[linear] = total;
}

extern "C" __global__ __launch_bounds__(128) void ff31_channels(
    const uint32_t *__restrict__ raw,
    const uint32_t *__restrict__ inputs,
    uint32_t *__restrict__ channels,
    uint32_t record_batch,
    uint32_t base_count,
    uint32_t rank,
    uint32_t grade_count,
    uint32_t prime,
    uint32_t nprime,
    uint32_t one,
    uint32_t grade_one) {
    uint32_t image_count = base_count * grade_count;
    uint32_t linear = blockIdx.x * blockDim.x + threadIdx.x;
    if (linear >= record_batch * image_count) return;
    uint32_t record = linear / image_count;
    uint32_t image = linear % image_count;
    uint32_t base = image / grade_count;
    uint32_t grade = image % grade_count;
    uint32_t sum = 0;
    for (uint32_t sheet = 0; sheet < grade_count; ++sheet) {
        uint32_t value = raw[record * image_count + base * grade_count + sheet];
        sum = __popc(sheet & grade) & 1 ? subm(sum, value, prime)
                                          : addm(sum, value, prime);
    }
    uint32_t denominator = grade_one;
    for (uint32_t root = 0; root < rank; ++root)
        if (grade & (1U << root))
            denominator = mont(
                denominator,
                inputs[(3 + root) * image_count + base * grade_count],
                prime, nprime);
    uint32_t inverse = power(denominator, prime - 2, prime, nprime, one);
    channels[linear] = mont(mont(sum, inverse, prime, nprime), 1, prime, nprime);
}
