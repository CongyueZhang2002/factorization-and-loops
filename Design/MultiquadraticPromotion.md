# Multiquadratic (extension-field) machinery: promotion into FeynFacet

Scope decided 2026-08-23 (Fable, user-directed standardization of Codex's
overnight work).  Sources: `Exchange/Codex/2026-08-22/04_triple_root_campaign/`
(TripleRootAlgebra.wl, TripleRootStripAdapter.wl,
direct_root_channel_assembler_xh/DirectRootChannelAssembler.wl, oracles) and
the promotion gates in
`Exchange/Codex/2026-08-23/12_package_bug_handoff.md`.

## Module layout

1. `FeynFacet/Private/MultiquadraticAlgebra.wl` — the ONE neutral algebra
   ABI (handoff External gap 3).  Content = TripleRootAlgebra.wl: basis
   masks, Hadamard/character table, xor-grade multiplication with
   ri^2 = Delta_i, derivative rule, polynomial reduction to the root basis,
   conjugate evaluation/projection, split-point tests, modular square
   roots, grade closure and F2 rank.  Names: keep the TR* function names
   (they are the audited ABI) but house them in FeynFacet`Private`; export
   an `MultiquadraticAlgebraABIFingerprint[]` (rank-independent hash of
   ordering + semantics probes) that every consumer records.
   `FamilyRowGaugeFiniteField.wl` must be rewritten to CONSUME this module
   (delete its duplicated root ordering/square-class arithmetic/grade
   masks); a differential test proves identical ordering, fingerprints and
   grade multiplication against the old copy before the deletion lands.

2. `FeynFacet/Private/MultiquadraticStripSolve.wl` — the direct
   root-channel sampler (from DirectRootChannelAssembler.wl) plus the
   strip adapter.  Changes required by the handoff, non-negotiable:
   - production sampler accepts NO "BranchFlipMask" (gap 1): the option is
     removed there; sign flips live only in the sign-transform /
     differential-certificate APIs;
   - artifact hydration must not hardcode Global` (pool defect 3): raw
     load and value validation split, explicit artifact context,
     context-free canonical fingerprints (ABI variables canonicalized to
     placeholders before hashing);
   - no `Quiet[Check[Get[...], $Failed]]` (pool defect 4): use
     Quiet[CheckAbort[...]] + $MessageList collection + schema validators;
   - typed failures throughout; fail closed on missing FLINT binary
     (the affine-RREF backend is requested via the existing
     "PlanDiscoveryBackend" option surface of FiniteFieldStripSolve).

3. Solution contract (gap 2, the OneForms problem): the package strip
   contract requires Alphabet + constant residue matrices + a certified
   dlog potential.  The direct solver produces closed one-forms.  Until a
   potential is returned and verified per candidate (DLog[letter] ==
   oneForm exactly), the multiquadratic solver may return
   "Status" -> "ModularConsistent" with the reconstructed data, and the
   sector driver must NOT install it as Solved.  The typed stop chain is:
   SolveEpsFormStripInFrame -> NoRationalStripChart -> multiquadratic
   solve -> ModularConsistent (recorded, not installed) or typed failure.
   No physical CF300 block currently has even a consistent ansatz (the A0
   family of discriminators is inconsistent with certified ranks), so no
   physical Solved claim is possible today regardless.

## Tests (all new, package-level)

- `t_multiquadratic_algebra.wls`: exact algebra identities ranks 0-3
  (associativity/commutativity samples, derivative Leibniz, conjugate
  round trip via Hadamard, char-0 vs mod-p agreement, grade closure/rank),
  plus the ABI fingerprint stability check.
- `t_multiquadratic_algebra_differential.wls`: old FamilyRowGaugeFiniteField
  copies vs the neutral module: identical ordering, fingerprints, and
  grade products on randomized inputs (the deletion gate).
- `t_multiquadratic_strip_solve.wls`: synthetic solvable blocks built from
  KNOWN multiquadratic gauges of ranks 0-3 (the t_finite_field_adversarial
  pattern: construct forcing from a chosen gauge/residues, then require
  exact recovery, unseen-prime and all-sign-branch validation); the
  BranchFlipMask rejection; the ModularConsistent (not Solved) contract;
  fail-closed on a corrupted artifact and on a missing native binary.

## Explicitly out of scope for this pass

- The CF300 campaign drivers, recapture/oracle harnesses, and the
  affine-witness screens stay External (they are evidence, not package).
- The A0-ansatz search (repeated poles / new algebraic letters) is a
  mathematics task, not a porting task.
- `AffineInconsistencyWitness.wl` Heads->True bug: staged patch exists
  (`affine_witness_score_heads_fix_2026-08-23.patch`); apply only after
  confirming no source-pinned mission still references the file.
