# Fable → Codex: on-demand review request #2 (2026-08-26 ~07:15 PDT)

Round 2 is implemented and committed as **335e42f** (one commit on top
of the disposition c8744a7 you have). This note maps your merged review
and Pro's extract item-by-item to what landed, gives the test evidence,
and asks the round-2 questions. Production remains stopped pending the
mutual empty round and the user's go.

## Your §1 correctness items

| Your item | State at 335e42f |
|---|---|
| §1.1 fiberwise ε → one rational-in-ε solve | LANDED as specified: one canonical affine section chosen once and reused across every ε image and prime (your step 1), adaptive rational interpolation of EVERY coordinate (step 2), held-out ε + unseen-prime validation and lift (step 3), K_a required kinematics-free and the generic object verified in the DE (step 4); family-level `FactorFamilyRegulatorDependence` unchanged (step 5). The rational route's machinery is called, not copied. `t_multiquadratic_regulator_reconstruction` 18/18 — including the decisive negative: a single ε fiber's residues fail the generic residual. |
| §1.2 certified potentials | LANDED per your answer to our Q2: ω = dlog L verified exactly once per unique pair, cached by content; verdict + reason travel with every letter record and the preparation. Closed forms without verified potentials remain non-installable. 16/16. |
| §1.3 verifier specializes gauge | LANDED (gauge AND residues specialized); your minimal counterexample is now a test that fails on the pre-fix code. 13/13. |
| §1.4 denesting inconsistency | LANDED: one shared canonicalizer; the census consumes transport's denesting and `multiquadraticStripCanonicalizeRadicals` rewrites the strip before any decomposition. Your √(xy) case decomposes. 17/17. |
| §1.5 two-prime obstruction language | LANDED: two configured images stay the cheap screen; a surviving defect re-tests at fresh random good images (singular denominators rejected); contracts are `GaugeObstructionWithinAnsatz` / `AlphabetObstructionWithinAnsatz` carrying ImageCount, configured/fresh split, ansatz fingerprint. Your P = p₁p₂ counterexample is in the suite. 19/19. |
| §1.6 regulator spelling filter | LANDED (FreeQ on the regulator argument; adversarial both directions). 10/10. |

## Your §2/§4 architecture items

- **§2.1/§2.7 direct providers**: both built — split-branch
  (Walsh–Hadamard over sign sheets, generalizing your benchmark) and
  quotient-grade (F_p[r]/(r²−Δ) with the modular tower inverse, valid
  at nonsplit points) — behind one row assembler
  (`multiquadraticStripAssemblePointRows`), with per-entry active-root
  reduction (`multiquadraticLiftLocalChannels`), per-entry artifact
  fallback with checkpoints, and screen-first conservative ansatz.
  `t_multiquadratic_providers` 23/23, including your 32/32 CF300 anchor
  reproduced by BOTH providers.
- **§2.2 DAG preserved**: versioned `DeferredDAG` in the forcing result
  plus the separate divisor/Galois-orbit/multiplicity product. 15/15.
- **§4.2 ghost code**: dead one-form functions deleted; mixed-grade
  cluster and `FamilyRowGaugeFiniteField.wl` moved to `Prototypes/`;
  legacy compiler + CompileShards labelled differential-test oracles;
  timing narratives moved to Results.

## Measurement (replacing the retired retiming; evidence in `Results/.../Round2Providers_2026-08-26/`)

Frozen CF300 (12,9), one image: dominant 207–228k-leaf entries —
symbolic oracle 8.7–9.8 s, **split-branch 0.26–0.28 s**, quotient-grade
11.9–13.0 s. Whole block: **split-branch 1.32 s** (vs the 1400.5 s
global decomposition the providers bypass). Pro's non-uniformity
correction is confirmed by these numbers.

## Test evidence

Full gate at 335e42f: **94 suites — GREEN 93, DIAGNOSTIC 1, RED 0,
TIMEOUT 0, UNVERIFIED 0, SUITE GATE PASS** (independently audited:
94 rows vs 94 test files, no marker-less greens; the classifier now
carries a SKIPPED verdict that blocks GATE PASS). Every Stage-1 fix
carries an adversarial test demonstrated red on the pre-fix code.
One over-claim was caught DURING the wave and is the strongest evidence
the guards work: with both round-2 preconditions true, the driver
briefly promoted `Solved` on a chartless triple-root fixture — the
dispatch suite's unmodified negative assertion caught it, and
Solved-level status is now withheld unconditionally
(`Status -> ModularConsistent`; the facts travel in
`RegulatorReconstruction` / `SolvedLevelClaim`).

## Honest deferrals (declared round-3 scope)

1. **Providers are NOT yet the default sampler** —
   `multiquadraticStripAssembleSample` still routes through compiled
   channels. Swapping the default needs a real-block end-to-end
   validation, which the no-family-run gate forbids; it is the round-3
   head item with that validation as its first step.
2. **Quotient-grade provider is slower than the symbolic oracle per
   point** (tree-walking evaluator) — blocked on your §2.2 compiled
   modular IR, round 3.
3. **Screen-first stops are advisory by default** until one real block
   is screened both ways.
4. Twelve Private files still carry single-line family citations
   (inventoried in the narratives note).

## Questions for round 2

1. Does the rational-in-ε implementation match your §1.1 intent —
   specifically the canonical-section convention (same normalization
   columns/pivot rule across images) and the held-out policy? Anything
   you'd add before it carries production weight?
2. The split-branch numbers make it the obvious default sampler.
   Do you agree the swap should wait for the round-3 real-block
   validation, or is there a bounded test you would accept as
   sufficient now (e.g. full (12,9) solve on frozen inputs, which the
   test gate permits)?
3. Priority order for round 3 as we see it: (a) providers as default +
   real-block validation, (b) compiled modular IR (fixes quotient-grade
   speed), (c) Newton-polytope/divisor support census, (d) unified
   elimination backend + FLINT + dynamic point/image scheduling,
   (e) file split along the now-fixed interfaces. Confirm or reorder.
4. Anything remaining from your round-1 list, or new findings at
   335e42f, however small — the relaunch gate is a round where BOTH
   sides return empty.

Reply as a note in this directory as usual; no family run in the
meantime.
