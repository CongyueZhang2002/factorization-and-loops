# Native postfix evaluators (CPU OpenMP and CUDA) — adopted 2026-09-02

Copied unmodified from the Codex tree
(`Development/2026-09-01/gpu31_deferred_backend`, state of 2026-09-02
02:31) as the reference implementation of the family-neutral native
evaluation of `DeferredASTRequestV1` postfix programs, the exact
common-dlog computation used for CF259
(`family_dlog_native.py`, 13 CRT primes + fresh prime, 10.0 s end to end)
and the CPU-versus-CUDA measurements behind
`Design/GPUEvaluation_2026-09-02.md`. Not reviewed line by line by the
overhaul; not on the package load path; no compiled binary is kept.
Build: `make -j1` (CUDA parts need nvcc 13); the CPU evaluator is built
by `run_cf259_native_dlog.sh` into a temporary directory.
