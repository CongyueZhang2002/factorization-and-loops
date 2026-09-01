#include <cuda_runtime.h>
#include <chrono>
#include <cstring>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "postfix_kernels.cu"

constexpr uint32_t P31 = 2147483423U;
constexpr uint32_t NP31 = 124076833U;
constexpr uint32_t R31 = 450U;

static uint32_t host_mont(uint32_t a, uint32_t b) {
    uint64_t t = uint64_t(a) * b;
    uint32_t m = uint32_t(t) * NP31;
    uint64_t u = (t + uint64_t(m) * P31) >> 32;
    return uint32_t(u >= P31 ? u - P31 : u);
}

static uint32_t host_power(uint32_t a, uint32_t exponent) {
    uint32_t result = R31;
    while (exponent) {
        if (exponent & 1) result = host_mont(result, a);
        a = host_mont(a, a);
        exponent >>= 1;
    }
    return result;
}

static void host_eval_batch(const uint32_t *ops, const uint32_t *args,
                            const uint32_t *constants,
                            uint32_t begin, uint32_t end,
                            const uint32_t *inputs, uint32_t image_count,
                            uint32_t *output, uint32_t *stack,
                            uint32_t *prefix) {
    uint32_t sp = 0;
    for (uint32_t pc = begin; pc < end; ++pc) {
        uint32_t op = ops[pc], arg = args[pc];
        if (op == CONST) {
            uint32_t *slot = stack + sp++ * image_count;
            for (uint32_t i = 0; i < image_count; ++i) slot[i] = constants[arg];
        } else if (op == INPUT) {
            std::memcpy(stack + sp++ * image_count, inputs + arg * image_count,
                        4 * image_count);
        } else if (op == POW) {
            uint32_t *a = stack + (sp - 1) * image_count;
            for (uint32_t i = 0; i < image_count; ++i) a[i] = host_power(a[i], arg);
        } else if (op == INV) {
            uint32_t *a = stack + (sp - 1) * image_count;
            for (uint32_t i = 0; i < image_count; ++i)
                prefix[i] = i ? host_mont(prefix[i - 1], a[i]) : a[i];
            uint32_t inverse = host_power(prefix[image_count - 1], P31 - 2);
            for (uint32_t i = image_count; i-- > 0;) {
                uint32_t before = i ? prefix[i - 1] : R31;
                uint32_t current = host_mont(inverse, before);
                inverse = host_mont(inverse, a[i]);
                a[i] = current;
            }
        } else if (op == NEG) {
            uint32_t *a = stack + (sp - 1) * image_count;
            for (uint32_t i = 0; i < image_count; ++i)
                if (a[i]) a[i] = P31 - a[i];
        } else {
            uint32_t *b = stack + --sp * image_count;
            uint32_t *a = stack + (sp - 1) * image_count;
            for (uint32_t i = 0; i < image_count; ++i) {
                if (op == ADD) a[i] = a[i] + b[i] >= P31 ? a[i] + b[i] - P31 : a[i] + b[i];
                else if (op == SUB) a[i] = a[i] >= b[i] ? a[i] - b[i] : P31 - (b[i] - a[i]);
                else a[i] = host_mont(a[i], b[i]);
            }
        }
    }
    std::memcpy(output, stack, 4 * image_count);
}

static void check(cudaError_t status, const char *where) {
    if (status != cudaSuccess) {
        std::fprintf(stderr, "%s: %s\n", where, cudaGetErrorString(status));
        std::exit(2);
    }
}

int main(int argc, char **argv) {
    uint32_t programs = argc > 1 ? std::strtoul(argv[1], nullptr, 10) : 2048;
    uint32_t images = argc > 2 ? std::strtoul(argv[2], nullptr, 10) : 512;
    uint32_t rounds = argc > 3 ? std::strtoul(argv[3], nullptr, 10) : 4;
    if (!programs || !images || !rounds || uint64_t(programs) * images > 2000000)
        return 3;
    std::vector<uint32_t> offsets(1, 0), ops, args, constants,
                          inputs(6ULL * images);
    auto emit = [&](uint32_t op, uint32_t arg = 0) { ops.push_back(op); args.push_back(arg); };
    auto emit_const = [&](uint32_t value) {
        emit(CONST, constants.size()); constants.push_back(value);
    };
    for (uint32_t program = 0; program < programs; ++program) {
        emit(INPUT, 0); emit_const(uint64_t(program + 1) * R31 % P31); emit(ADD);
        for (uint32_t r = 0; r < rounds; ++r) {
            emit(INPUT, 1); emit(MUL); emit(INPUT, 2); emit(ADD);
            emit(POW, 2 + r % 4);
            emit(INPUT, 3 + r % 3); emit(INV); emit(MUL);
            emit_const(uint64_t(17 + program + r) * R31 % P31); emit(ADD);
        }
        offsets.push_back(ops.size());
    }
    for (uint32_t channel = 0; channel < 6; ++channel)
        for (uint32_t image = 0; image < images; ++image) {
            uint32_t value = (uint64_t(1664525 + 97 * channel) * (image + 1)
                              + 1013904223 + channel) % (P31 - 1) + 1;
            inputs[channel * images + image] = uint64_t(value) * R31 % P31;
        }
    uint64_t count64 = uint64_t(programs) * images;
    uint32_t count = count64;
    std::vector<uint32_t> expected(count), observed(count);
    std::vector<uint32_t> cpu_stack(32ULL * images), prefix(images);
    auto cpu0 = std::chrono::steady_clock::now();
    for (uint32_t program = 0; program < programs; ++program)
        host_eval_batch(ops.data(), args.data(), constants.data(), offsets[program],
                        offsets[program + 1], inputs.data(), images,
                        expected.data() + program * images,
                        cpu_stack.data(), prefix.data());
    auto cpu1 = std::chrono::steady_clock::now();

    auto init0 = std::chrono::steady_clock::now();
    check(cudaFree(nullptr), "CUDA context");
    auto init1 = std::chrono::steady_clock::now();
    uint32_t *d_offsets, *d_ops, *d_args, *d_constants, *d_inputs, *d_output,
             *d_status;
    auto gpu0 = std::chrono::steady_clock::now();
    check(cudaMalloc(&d_offsets, 4 * offsets.size()), "offset allocation");
    check(cudaMalloc(&d_ops, 4 * ops.size()), "op allocation");
    check(cudaMalloc(&d_args, 4 * args.size()), "arg allocation");
    check(cudaMalloc(&d_constants, 4 * constants.size()), "constant allocation");
    check(cudaMalloc(&d_inputs, 4 * inputs.size()), "input allocation");
    check(cudaMalloc(&d_output, 4 * count), "output allocation");
    check(cudaMalloc(&d_status, 4), "status allocation");
    check(cudaMemcpy(d_offsets, offsets.data(), 4 * offsets.size(), cudaMemcpyHostToDevice), "offset copy");
    check(cudaMemcpy(d_ops, ops.data(), 4 * ops.size(), cudaMemcpyHostToDevice), "op copy");
    check(cudaMemcpy(d_args, args.data(), 4 * args.size(), cudaMemcpyHostToDevice), "arg copy");
    check(cudaMemcpy(d_constants, constants.data(), 4 * constants.size(), cudaMemcpyHostToDevice), "constant copy");
    check(cudaMemcpy(d_inputs, inputs.data(), 4 * inputs.size(), cudaMemcpyHostToDevice), "input copy");
    check(cudaMemset(d_status, 0, 4), "status clear");
    cudaEvent_t start, stop;
    check(cudaEventCreate(&start), "event create"); check(cudaEventCreate(&stop), "event create");
    check(cudaEventRecord(start), "event start");
    ff31_eval<<<(count + 127) / 128, 128>>>(
        d_offsets, d_ops, d_args, d_constants, d_inputs, d_output, d_status,
        0, programs, images, P31, NP31, R31);
    check(cudaEventRecord(stop), "event stop"); check(cudaEventSynchronize(stop), "kernel");
    float kernel_ms = 0; check(cudaEventElapsedTime(&kernel_ms, start, stop), "event time");
    uint32_t status = 0;
    check(cudaMemcpy(observed.data(), d_output, 4 * count, cudaMemcpyDeviceToHost), "output copy");
    check(cudaMemcpy(&status, d_status, 4, cudaMemcpyDeviceToHost), "status copy");
    cudaEventDestroy(start); cudaEventDestroy(stop);
    cudaFree(d_offsets); cudaFree(d_ops); cudaFree(d_args); cudaFree(d_constants);
    cudaFree(d_inputs);
    cudaFree(d_output); cudaFree(d_status);
    auto gpu1 = std::chrono::steady_clock::now();
    if (status) { std::fprintf(stderr, "GPU status=%u\n", status); return 4; }
    for (uint32_t i = 0; i < count; ++i)
        if (observed[i] != expected[i]) {
            std::fprintf(stderr, "mismatch[%u]=%u expected %u\n", i, observed[i], expected[i]);
            return 1;
        }
    double cpu_ms = std::chrono::duration<double, std::milli>(cpu1 - cpu0).count();
    double init_ms = std::chrono::duration<double, std::milli>(init1 - init0).count();
    double gpu_ms = std::chrono::duration<double, std::milli>(gpu1 - gpu0).count();
    double raw = cpu_ms / gpu_ms, kernel = cpu_ms / kernel_ms;
    uint64_t explicit_bytes = 4ULL * (offsets.size() + ops.size() + args.size()
                                      + inputs.size() + count + 1);
    uint64_t conservative_bytes = explicit_bytes + 128ULL * count;
    std::printf(
        "PASS programs=%u images=%u rounds=%u outputs=%u instructions=%zu "
        "cpu_batch_ms=%.3f context_ms=%.3f gpu_kernel_ms=%.3f gpu_e2e_ms=%.3f "
        "kernel_speedup=%.2fx e2e_speedup=%.2fx two_prime_speedup=%.2fx "
        "ideal16c_two_prime_speedup=%.2fx explicit_MiB=%.2f conservative_MiB=%.2f\n",
        programs, images, rounds, count, ops.size(), cpu_ms, init_ms, kernel_ms,
        gpu_ms, kernel, raw, raw / 2, raw / 32,
        explicit_bytes / 1048576.0, conservative_bytes / 1048576.0);
}
