NVCC := /usr/local/cuda-13.0/bin/nvcc
NVCCFLAGS := --threads 1 -O3 -ptx -arch=compute_120

.PHONY: all check clean
all: postfix_kernels.ptx nvcc_smoke benchmark_postfix

postfix_kernels.ptx: postfix_kernels.cu
	$(NVCC) $(NVCCFLAGS) $< -o $@

nvcc_smoke: nvcc_smoke.cu
	$(NVCC) --threads 1 -O3 -arch=sm_120 $< -o $@

benchmark_postfix: benchmark_postfix.cu postfix_kernels.cu
	$(NVCC) --threads 1 -O3 -arch=sm_120 $< -o $@

check: all
	taskset -c 0 ./nvcc_smoke
	taskset -c 0 python3 probe_driver.py
	taskset -c 0 python3 self_test.py

clean:
	$(RM) postfix_kernels.ptx nvcc_smoke benchmark_postfix
