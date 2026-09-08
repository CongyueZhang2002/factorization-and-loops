# 01 — Make the direct multiquadratic strip solver production-ready

> **Status:** [🟡] In progress  
> **Owner:** Codex for live-package implementation and independent validation
> **Origin:** merged Codex, two-subagent, and ChatGPT Classic Pro assessment  
> **Scope:** two independent dimensionless variables and a configurable multiquadratic root rank

## Goal

Produce one general, efficient, installable off-diagonal epsilon-form solver
for rational and multiquadratic coefficient fields. It must reconstruct one
coherent gauge as a rational function of the regulator, carry a certified dlog
alphabet, sample the deferred equation without first materializing global root
channels, and install its result through the existing family row-gauge ABI.

Success is an installed triple-root off-diagonal block with fresh modular
validation—not merely consistent individual regulator fibres or a faster
preparation benchmark.

## Correctness goals

- [🟢] Reconstruct one rational-in-regulator gauge and all residue coordinates
  from a common affine section. Use the same normalization and pivot convention
  across regulator images, validate at held-out regulator values and an unseen
  prime, and replay the generic differential equation.

- [🟢] Verify the reconstructed gauge and residues with the regulator
  specialized consistently. Gauge, residues, forcing, and one-forms must all
  belong to the same regulator fibre.

- [🟢] Use the actual regulator argument and one shared radical
  denesting/canonicalization route. Renamed regulators and composite radicals
  must work without symbol-name assumptions.

- [🟢] Certify dlog potentials on the **active reconstructed residue support**,
  preferring installed diagonal alphabets. Zero-residue candidates must be
  removed, certified records must supersede equivalent unverified forms, and
  empty active support must be valid. This is Fable A2.

- [🟢] Make every modular obstruction explicitly ansatz-relative and require
  all requested fresh usable images before promotion. A consistent, missing,
  or unusable fresh image must never become a negative contract. This is Fable
  A1.

- [🟢] Preserve divisor/Galois provenance before cancellation and require the
  canonical independent root frame. The provider must receive an immutable
  pre-materialization bundle, and dependent/composite radicals must not create
  fake independent generators. This is Fable A3.

- [🟢] Keep final regulator factorization as the existing family-level constant
  transformation. Strip residues may remain rational in the regulator but must
  be kinematics-free; `FactorFamilyRegulatorDependence` completes the epsilon
  form.

## Major performance goals

- [🟢] Bypass global exact forcing-channel decomposition. Split-branch sampling
  is the production default, quotient grade is the independent oracle, and
  global channels are only an explicit artifact fallback.

- [🟢] Evaluate the preserved deferred DAG directly. Provider sampling must
  occur without unconditional symbolic materialization; shared operands should
  compile once and be reused across points.

- [🟢] Use one provider-backed row assembler and one production
  sampling/reconstruction loop. Screen, solve, and reconstruction must consume
  the same provider interface, and the duplicate fibrewise pass must be
  removed. This is Fable B1.

- [🟢] Harden lifting and validation with adaptive good-prime accumulation,
  replacement of exceptional images, and fresh provider-backed pointwise
  residuals. This is Fable B2.

- [🟡] Promote split-branch sampling with bounded full-block evidence. Frozen
  CF300 `(12,9)` must agree with the oracle in complete rows, normalization,
  rank/nullity, solved residual, and regulator reconstruction at multiple
  images; a genuine rank-3 fixture must exercise all eight grades. This is
  Fable B3.

- [🟢] Decide whether to reduce ansatz width using divisor valuations and
  Newton/support propagation. Physical CF300 adopted the minimal `{0,0}`
  support with zero defect, so no added sparse-support machinery is justified
  by current timing.

- [🟢] Compile modular evaluation where it materially dominates. Split-branch
  entries now use one authenticated sparse root-placeholder compiler/cache;
  deferred operands compile once and replay from a shared image store, with
  exact quotient-grade and substitution fallbacks retained as oracles.

- [🟢] Reuse one affine backend with pivot-plan reuse and FLINT where justified.
  Native CFFR discovers the modal affine plan; constrained followers now use
  the existing certified CFFA4 multi-RHS backend with all-row replay and exact
  Wolfram fallback. A dynamic cross-image pool remains rejected pending a
  measured benefit large enough to justify its memory/state complexity.

## Generality and conciseness goals

- [🟡] No executable family/process-specific dispatch in `Private`; empirical
      family narratives move to `Results/` or `Design/`.
- [🟢] Root generators and grades are generated dynamically; rank three is a
      tested resource ceiling, not three hard-coded local variables.
- [🟢] Negative results always name the tested alphabet, divisor, denominator,
      support, and evidence bounds.
- [🟢] `multiquadraticStripDecomposeForcingPerEntry` is either a real tested
      fallback or leaves production for `Prototypes/`.
- [🟢] Legacy channel and sign-row implementations remain only as explicit
      differential oracles; duplicate production assemblers and the old
      fibrewise solve are removed.
- [ ] Split the large source only after provider, reconstruction, and
      installation interfaces stabilize; this is tracked by goal 03.

## Completion conditions

- [🟢] A provider-backed result maps to `Gauge`, active `Alphabet`, and
      `ResidueMatrices` and installs through `FamilyRowGauge`.
- [🟢] Fresh unseen modular images validate the reconstructed generic solution.
- [🟢] Family regulator factorization and the family certificate accept it.
  The authenticated numeric root-frame handoff and planted rank-three
  cross-stage chain pass 14/14, including all-eight-sheet certification and
  mutation rejection.
- [🟡] At least one real triple-root off-diagonal block completes through this
      path.
- [🟡] Integrated phase timing shows no remaining known symbolic prerequisite
      consuming a dominant fraction of the solve.

## Assessment sources

- `Exchange/Codex/2026-08-25/10_pro_private_code_review.md`
- `Exchange/Codex/2026-08-25/11_merged_private_code_review.md`
- `Exchange/Fable/2026-08-26/01_round1_review_disposition.md`
- `Exchange/Codex/2026-08-26/01_round2_review_response.md`
- `Exchange/Fable/2026-08-26/03_round3_correction_plan.md`
- `Exchange/Codex/2026-08-26/02_round3_detailed_fix_instructions.md`

## Overnight progress — 2026-08-27

- [🟢] Round B provider, one-loop reconstruction, adaptive CRT, exceptional
  image replacement, modal affine-plan quorum, fresh unseen-prime residuals,
  installation ABI, and whole-family multiquadratic certificate are in the
  live package.
- [🟢] Physical provider promotion passed 41/41: exact eight-grade comparison,
  two regulator images, full row/rank/nullity agreement, a 2,120-unknown
  production sample, native FLINT solve, and a held-out zero residual.
- [🟢] All three real CF259 two-root subframes agree between split-branch and
  independent quotient-grade evaluation (14/14); nonsplit points are rejected
  before large evaluation.
- [🟢] A 27-suite integrated eight-worker gate passed with zero failures before
  the latest hardening wave. The focused hardening suites are also green:
  constrained affine plans 26/26, modal pilot authentication 12/12, whole-
  family multiquadratic certification 27/27, and the installed family chain
  14/14.
- [🟢] Corrected five substantive review defects: mixed evidence can no longer
  become an obstruction; pilots are bound to their exact sampled systems;
  numeric square classes survive family factorization/certification; whole-
  family pivot plans use a 2-of-up-to-3 modal quorum; sparse containers are
  normalized in both denesting branches.
- [🟢] Large constrained followers now use the certified CFFA4 FLINT multi-RHS
  backend with 1--8 native threads, exact core certification, unchanged full-
  row replay, and typed Wolfram fallback. A representative 2,260-by-2,260,
  53-RHS native benchmark improved from 1.55 s at one thread to 0.50 s at
  eight threads (3.1x); the 8-thread path is covered by the 26/26 suite.
- [🟡] The copied-state CF300 `(12,9)` campaign is live on CPUs 0--15 with
  eight Wolfram helpers and an eight-thread native ceiling. Deferred Bundle V2
  materialized 8 targets from 37 shared operands/48 terms with zero fallback;
  the direct rank-three provider adopted minimal support `{0,0}` with zero
  defects in 690.3 s. Regulator reconstruction has now started with 2,260
  unknowns and 53 one-forms. The original Fable state is untouched.

## Next gate

Obtain the typed CF300 block result, run the physical promotion gate once more
on the final source, then continue CF259 and CF303 with the corrected CFFA4
follower path.
Only after those measurements should any cross-image dynamic pool or further
support machinery be reconsidered.
