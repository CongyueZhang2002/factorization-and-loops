# 02 — Integrate today's rank-3 performance improvements

> **Status:** [🟡] In progress — isolated implementation is ready; live integration remains  
> **Owner:** Codex  
> **Workspace:** `/home/maxzhang/factorization-and-loops-codex`  
> **Branch:** `codex/day-rank3-validation`  
> **Implementation commits:** `fb2cfbd`, `a90ab40`

## Goal

Integrate the independently measured rank-3 improvements into the production
multiquadratic route, while keeping only changes that buy a material fraction
of an important stage. The final result must reduce real end-to-end solve time
and feed the same installation contract as goal 01.

## Optimization goals and status

- [🟡] Construct all candidate dlogs directly in the exact grade algebra and
  reuse their compiled channels. The isolated implementation is complete and
  measured **71.84 s → about 25.97 s**, but live integration remains.

- [🟡] Batch independent dlogs with bounded helper ownership. `DLogKernels`
  limits workers, uses one bootstrap, closes only helpers it launched, and
  falls back locally on a malformed shard; live integration remains.

- [🟡] Replace repeated scalar diagonal `SolveAlways` calls with one shared
  span solve. The isolated shared phase measured **4.8 s**, while the
  historical route exceeded 90 s; live integration remains.

- [🟡] Harden rank-3 deferred construction against branch/provenance aliasing.
  The isolated implementation binds the root branch, revalidates structural
  mutants, and preserves source-divisor provenance; live integration remains.

- [🟡] Define the smallest installable direct-solver result rather than another
  row-gauge solver. The 17/17 prototype maps onto the existing
  `Gauge`/`Alphabet`/`ResidueMatrices` ABI; production wiring remains.

- [🟢] Reject complexity that yields only marginal savings. Finite-field row
  reduction was rejected because it replaces only about 5% of the
  diagonal-span stage, and the 1–2 s helper-bootstrap experiment was removed.

- [ ] Port the accepted units into the live package without replacing Fable's
  large files wholesale.

- [ ] Measure the complete deferred-provider-to-installation route, including
  construction, sampling, reconstruction, active-potential certification,
  fresh validation, and installation.

- [ ] Use the integrated improvements in a real triple-root off-diagonal solve.
  Completion requires an installed block, not only candidate-letter and unit
  benchmarks.

## Integration units

1. Grade-algebra dlog construction, bounded batching, and channel reuse.
2. Shared diagonal-span solve with exact confirmation/fallback.
3. Rank-3 deferred-bundle identity and provenance hardening.
4. Small installation adapter after Fable's provider record names stabilize.

Each unit should land separately with its focused tests. Do not copy either
large isolated `Private` file wholesale.

## Complexity filter

- Keep the approximately 3× candidate-stage improvement.
- Keep the at-least-19× diagonal-span improvement.
- Keep branch/provenance hardening as required correctness work.
- Reject further dlog micro-tuning until integrated timing says this stage is
  again dominant.
- Reject FLINT, support-census, quotient-IR, or dynamic-pool rewrites here when
  they duplicate goal 01's evidence-gated decisions.

## Evidence

- `Exchange/Codex/2026-08-26/03_rank3_performance_handoff.md`
- `Exchange/Codex/2026-08-26/04_review_gaps_and_ownership.md`
- `Exchange/Codex/2026-08-26/05_install_contract_and_complexity_filter.md`

## Completion conditions

- [ ] All accepted units are present in the live package.
- [ ] Their focused adversarial and regression suites pass after integration.
- [ ] Integrated timing retains a material end-to-end benefit.
- [ ] The result participates in the production provider/reconstruction route
      and contributes to completing a triple-root strip.

## Next gate

Resolve Fable's current edit boundary, then port the three implementation units
one at a time. Integrate the adapter only after the provider/reconstruction
record schema is stable.
