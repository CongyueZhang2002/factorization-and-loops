# 01 — Make the direct multiquadratic strip solver production-ready

> **Status:** [🟡] In progress  
> **Owner:** Fable for live-package implementation; Codex for independent review  
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

- [🟡] Certify dlog potentials on the **active reconstructed residue support**,
  preferring installed diagonal alphabets. Zero-residue candidates must be
  removed, certified records must supersede equivalent unverified forms, and
  empty active support must be valid. This is Fable A2.

- [🟡] Make every modular obstruction explicitly ansatz-relative and require
  all requested fresh usable images before promotion. A consistent, missing,
  or unusable fresh image must never become a negative contract. This is Fable
  A1.

- [🟡] Preserve divisor/Galois provenance before cancellation and require the
  canonical independent root frame. The provider must receive an immutable
  pre-materialization bundle, and dependent/composite radicals must not create
  fake independent generators. This is Fable A3.

- [🟢] Keep final regulator factorization as the existing family-level constant
  transformation. Strip residues may remain rational in the regulator but must
  be kinematics-free; `FactorFamilyRegulatorDependence` completes the epsilon
  form.

## Major performance goals

- [🟡] Bypass global exact forcing-channel decomposition. The providers exist,
  but split-branch sampling is not yet the production default. Quotient grade
  should be the nonsplit fallback/cross-check, and global channels only an
  explicit artifact fallback.

- [🟡] Evaluate the preserved deferred DAG directly. Provider sampling must
  occur without unconditional symbolic materialization; shared operands should
  compile once and be reused across points.

- [ ] Use one provider-backed row assembler and one production
  sampling/reconstruction loop. Screen, solve, and reconstruction must consume
  the same provider interface, and the duplicate fibrewise pass must be
  removed. This is Fable B1.

- [ ] Harden lifting and validation with adaptive good-prime accumulation,
  replacement of exceptional images, and fresh provider-backed pointwise
  residuals. This is Fable B2.

- [ ] Promote split-branch sampling with bounded full-block evidence. Frozen
  CF300 `(12,9)` must agree with the oracle in complete rows, normalization,
  rank/nullity, solved residual, and regulator reconstruction at multiple
  images; a genuine rank-3 fixture must exercise all eight grades. This is
  Fable B3.

- [ ] Reduce ansatz width using divisor valuations and Newton/support
  propagation, but only if integrated timing shows width or elimination is a
  material bottleneck.

- [ ] Compile modular evaluation if integrated timing shows point evaluation
  dominates. One shared deferred-DAG IR should serve split and quotient
  providers.

- [ ] Reuse one affine backend with pivot-plan reuse, FLINT where justified,
  and dynamic point/image scheduling after measurements justify the added
  complexity.

## Generality and conciseness goals

- [🟡] No executable family/process-specific dispatch in `Private`; empirical
      family narratives move to `Results/` or `Design/`.
- [ ] Root generators and grades are generated dynamically; rank three is a
      tested resource ceiling, not three hard-coded local variables.
- [🟡] Negative results always name the tested alphabet, divisor, denominator,
      support, and evidence bounds.
- [ ] `multiquadraticStripDecomposeForcingPerEntry` is either a real tested
      fallback or leaves production for `Prototypes/`.
- [🟡] Legacy channel and sign-row implementations remain only as explicit
      differential oracles; duplicate production assemblers and the old
      fibrewise solve are removed.
- [ ] Split the large source only after provider, reconstruction, and
      installation interfaces stabilize; this is tracked by goal 03.

## Completion conditions

- [ ] A provider-backed result maps to `Gauge`, active `Alphabet`, and
      `ResidueMatrices` and installs through `FamilyRowGauge`.
- [ ] Fresh unseen modular images validate the reconstructed generic solution.
- [ ] Family regulator factorization and the family certificate accept it.
- [ ] At least one real triple-root off-diagonal block completes through this
      path.
- [ ] Integrated phase timing shows no remaining known symbolic prerequisite
      consuming a dominant fraction of the solve.

## Assessment sources

- `Exchange/Codex/2026-08-25/10_pro_private_code_review.md`
- `Exchange/Codex/2026-08-25/11_merged_private_code_review.md`
- `Exchange/Fable/2026-08-26/01_round1_review_disposition.md`
- `Exchange/Codex/2026-08-26/01_round2_review_response.md`
- `Exchange/Fable/2026-08-26/03_round3_correction_plan.md`
- `Exchange/Codex/2026-08-26/02_round3_detailed_fix_instructions.md`

## Next gate

Finish and independently test A1–A3, then make the split-branch provider the
sole production sampling input under B1–B3. Measure the integrated phase split
before choosing support reduction, compiled modular IR, or backend work.
