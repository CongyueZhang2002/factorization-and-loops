# Deep-rung benchmark result: Maple vs simultaneous finite-field, 2026-08-20

The equal-resource benchmark you asked for is done. Protocol as agreed:
same coupling record per fixture, standardized code
(`SolveResidueRationalGauge` vs `SolveEpsFormStripFiniteField`), one
Wolfram kernel per job with internal parallelism capped
(`ResidueKernels -> 1`, `KernelCount -> 1`), fresh finite-field
artifacts (no replay), each backend's own exact both-variable residual
check as acceptance. Jobs ran concurrently on subkernels; every record
carries `Concurrent -> True`. Fixtures, per-job records, and
`benchmark_summary.wl` are in
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BenchmarkStripBackends/`.

| fixture | Maple | finite-field |
|---|---|---|
| CF48 (13,11) — small residue system | SOLVED 3.8 s (Maple call 0.3 s) | SOLVED 10.7 s |
| CF254 (9,6) | FAILED at 6328 s | SOLVED 1365 s |
| CF254 (9,7) — the hard production strip | FAILED at 6271 s | SOLVED 7254 s |

The (9,7) finite-field solve used 6 primes at a steady ~14.5 min per
prime single-core; the adaptive validation margin demanded one prime
beyond the historical five. Caveats stated in the records: the Maple
failures are ladder exhaustion at this allocation within ~105-minute
walls, not absence proofs; and single-core walls are not production
speed (production sampling parallelizes over kernels and reuses
artifacts — cf. the 791 s replay).

Verdict under the agreed rule (lower wall at equal resources, per size
regime): **the simultaneous finite-field affine solve is the production
deep rung** — it solved all three fixtures including both that Maple
could not — and **Maple is retained as the small-residue-system fast
path and the independent cross-check engine**. This resolves the open
question in your production-scheduling note. Next wiring step on our
side, pending the user's confirmation: the finite-field rung becomes
the automatic escalation inside `SolveEpsFormStrip`'s ladder, with the
Maple route attempted first only when the residue system is small.
