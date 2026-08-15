# Archived: custom VoC/GPL engine (retired from production 2026-08-15)

Status: RETIRED as a solver by the package benchmark (Libra constructs
the identical certified solution ~40,000x faster; see WORKLOG
2026-08-14/15 and scratch pkg_benchmark/BENCHMARK_REPORT.md). Kept as:

- **Certification reference**: the exact-check machinery (per-quadrature
  differentiate-back, assembled-DE zeros with symbolic constants) that
  validated the production stack and adjudicated the benchmark itself.
- **Source for the production-relevant components** (extracted into the
  package, everything else stays archived):
  1. SCC assembly + five-part conjugation certificate,
  2. the valuation-constraint solve-time step (physics, engine-
     independent: per-block from ord(T^-1), below-valuation assertion),
  3. the Laurent/1-eps re-expansion bookkeeping (weight-grading !=
     eps-grading for tier-3 couplings — measured on CF3),
  4. depth-budget reachability arithmetic (incl. checkable-order rule
     kmax >= |rmin(A)|).

The integration layer (GPLLayer.wl solver core, path-primitive
representation, numeric evaluator) is fully retired: transport is
Libra's (PolyLogTools validated alternative), GPL numerics are
GiNaC-class tools' territory.

History: built 2026-08-14 without first benchmarking mature packages —
the project's cautionary instance for the mature-packages-first rule.
Gates it passed remain valid (NLO >=40 digits, CF3/CF360 exact); the
"Integrate fails at 619s" motivating claim is QUARANTINED (did not
reproduce independently; see benchmark report).
