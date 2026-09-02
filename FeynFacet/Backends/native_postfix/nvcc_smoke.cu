#include <cuda_runtime.h>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

constexpr uint32_t P = 2147483423U;
constexpr uint32_t NP = 124076833U;  // -P^{-1} mod 2^32
constexpr uint32_t RMOD = 450U;      // 2^32 mod P

__host__ __device__ static inline uint32_t mont(uint32_t a, uint32_t b) {
    uint64_t t = uint64_t(a) * b;
    uint32_t m = uint32_t(t) * NP;
    uint64_t u = (t + uint64_t(m) * P) >> 32;
    return uint32_t(u >= P ? u - P : u);
}

__global__ void smoke(const uint32_t *xs, const uint32_t *ys, uint32_t *out,
                      uint32_t n, uint32_t iterations) {
    uint32_t i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    uint32_t x = xs[i], y = ys[i];
    for (unsigned k = 0; k < iterations; ++k) {
        x = mont(x, y); x = x + 17U * RMOD % P; if (x >= P) x -= P;
        y = mont(y, y); y = y + 29U * RMOD % P; if (y >= P) y -= P;
    }
    out[i] = x;
}

int main(int argc, char **argv) {
    uint32_t n = argc > 1 ? std::strtoul(argv[1], nullptr, 10) : 4096;
    uint32_t iterations = argc > 2 ? std::strtoul(argv[2], nullptr, 10) : 31;
    if (!n || n > 2000000 || !iterations) return 5;
    std::vector<uint32_t> x(n), y(n), expected(n), observed(n);
    for (uint32_t i = 0; i < n; ++i) {
        uint32_t x_standard = (1664525U * i + 1013904223U) % P;
        uint32_t y_standard = (22695477U * i + 1U) % P;
        x[i] = uint64_t(x_standard) * RMOD % P;
        y[i] = uint64_t(y_standard) * RMOD % P;
        if (mont(x[i], y[i]) != uint64_t(x_standard) * y_standard % P * RMOD % P)
            return 4;
    }
    auto cpu0 = std::chrono::steady_clock::now();
    for (uint32_t i = 0; i < n; ++i) {
        uint32_t a = x[i], b = y[i];
        for (unsigned k = 0; k < iterations; ++k) {
            a = mont(a, b); a += 17U * RMOD % P; if (a >= P) a -= P;
            b = mont(b, b); b += 29U * RMOD % P; if (b >= P) b -= P;
        }
        expected[i] = a;
    }
    auto cpu1 = std::chrono::steady_clock::now();
    auto init0 = std::chrono::steady_clock::now();
    if (cudaFree(nullptr) != cudaSuccess) return 6;
    auto init1 = std::chrono::steady_clock::now();
    uint32_t *dx, *dy, *dout;
    auto gpu0 = std::chrono::steady_clock::now();
    if (cudaMalloc(&dx, 4 * n) || cudaMalloc(&dy, 4 * n) || cudaMalloc(&dout, 4 * n)) return 2;
    cudaMemcpy(dx, x.data(), 4 * n, cudaMemcpyHostToDevice);
    cudaMemcpy(dy, y.data(), 4 * n, cudaMemcpyHostToDevice);
    cudaEvent_t start, stop;
    cudaEventCreate(&start); cudaEventCreate(&stop); cudaEventRecord(start);
    smoke<<<(n + 127) / 128, 128>>>(dx, dy, dout, n, iterations);
    cudaEventRecord(stop);
    if (cudaEventSynchronize(stop) != cudaSuccess) return 3;
    float kernel_ms = 0; cudaEventElapsedTime(&kernel_ms, start, stop);
    cudaMemcpy(observed.data(), dout, 4 * n, cudaMemcpyDeviceToHost);
    auto gpu1 = std::chrono::steady_clock::now();
    cudaEventDestroy(start); cudaEventDestroy(stop);
    cudaFree(dx); cudaFree(dy); cudaFree(dout);
    for (uint32_t i = 0; i < n; ++i)
        if (observed[i] != expected[i]) {
            std::fprintf(stderr, "mismatch[%u]=%u expected %u\n", i, observed[i], expected[i]);
            return 1;
        }
    double cpu_ms = std::chrono::duration<double, std::milli>(cpu1 - cpu0).count();
    double init_ms = std::chrono::duration<double, std::milli>(init1 - init0).count();
    double gpu_ms = std::chrono::duration<double, std::milli>(gpu1 - gpu0).count();
    std::printf(
        "PASS montgomery prime=%u values=%u iterations=%u cpu_ms=%.3f "
        "context_ms=%.3f gpu_kernel_ms=%.3f gpu_e2e_ms=%.3f "
        "kernel_speedup=%.2fx e2e_speedup=%.2fx two_prime_speedup=%.2fx bytes=%u\n",
        P, n, iterations, cpu_ms, init_ms, kernel_ms, gpu_ms,
        cpu_ms / kernel_ms, cpu_ms / gpu_ms, cpu_ms / gpu_ms / 2, 12 * n);
    return 0;
}
