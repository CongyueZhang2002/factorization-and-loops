# Diagonal and off-diagonal epsilon-form audit

Date: 2026-08-21

This was a short, targeted audit of Fable's packaged diagonal-block and
off-diagonal finite-field epsilon-form routes.  I reviewed the package
implementations and their transport wiring, ran the packaged regressions,
constructed adversarial examples, and tested external candidate fixes.  I did
not modify anything under `FeynFacet/`.

## Result

Three fixes are needed before the outputs can be treated as certified epsilon
forms.

### 1. Diagonal gate accepts a regulator-dependent letter

The exact identity

```wl
Ax = {{eps/(x + eps)}}; Ay = {{0}};
T = {{1}}; letters = {x + eps}; residues = {{{1}}};
```

was reported as `Certified` by both `CertifyDiagonalBlockEpsForm` and the
scalar `DiagonalBlockEpsForm` route.  The pushed connection is algebraically
exact, but `x + eps` is not an epsilon-independent letter, so this is not a
canonical epsilon form.

`CodexDiagonalBlockEpsFormCandidate.wl` adds `LettersEpsFree` to the exact
gate and requires it for `Status -> "Certified"`.  It also adds the same field
to the zero-block certificate for a stable schema.  The ordinary scalar and
irreducible-block positive tests still certify.

### 2. Off-diagonal verifier confuses an exact identity with an epsilon form

`VerifyEpsFormStrip` checked only that the two unspecialized Pfaffian
residuals vanished.  It did not require either:

- an epsilon-independent alphabet, or
- residue matrices constant in both kinematic variables and the regulator.

Consequently it accepted both of these one-entry counterexamples:

```wl
Alphabet -> {x + eps}; ResidueMatrices -> {{{1}}}; BbarX = {{eps/(x + eps)}}
Alphabet -> {x};       ResidueMatrices -> {{{eps}}}; BbarX = {{eps^2/x}}
```

The historical CF254 `(9,6)` fixture is a real, larger instance of the second
case.  It is explicitly marked `RawResidues -> True`; its residue tensor has
dimensions `{13,4,1}`, with 44 nonzero entries, and all 44 depend on `eps`.
Nevertheless, the stored old certificate says
`ExactPfaffianResidualsZero -> True`.  It is a reproducible raw affine lift,
not a solved epsilon-form strip.

`CodexFiniteFieldEpsFormCandidate.wl` separates the two concepts:

- `ExactPfaffianResidualsZero` remains the literal differential-identity
  result.
- `LettersEpsFree` and `ConstantResidues` record the structural checks.
- `CanonicalEpsFormCertified` is the acceptance field and requires all three.
- Structural failures return before the expensive unspecialized `Together`
  pass, with `StructuralFailureReasons` and
  `Missing["NotRunStructuralGateFailed"]` for the skipped exact check.
- `ReconstructEpsFormStrip` accepts only
  `CanonicalEpsFormCertified -> True`.

`CodexFiniteFieldStripSolveCandidate.wl` also hardens
`InstallEpsFormStripSolution`: it retains the existing exact-residual
certificate requirement, but cheaply recomputes alphabet epsilon-independence
and residue constancy from the actual solution.  Thus a legacy raw artifact
cannot be installed by spoofing or carrying the old exact-residual boolean,
and a valid installation does not repeat the expensive exact simplification.

This fail-fast ordering matters in practice.  The old CF254 regression spent
45.8 seconds reaching the false-positive result.  With the structural gate it
reaches the intended rejection in 9.7 seconds including reconstruction; the
corrected raw-lift regression completes in 7.9 seconds and records
`ExactCheckSeconds -> 0`.

### 3. The unseen-prime reserve can be empty

The solver searched only the first 65 primes descending from `2147483399`,
despite the comment claiming that the reserve could never be exhausted.  A
legal `Primes` option containing those 65 values leaves `reservePrimes = {}`
and reaches `First[{}]`.

`CodexFiniteFieldStripSolveCandidate.wl` adds
`finiteFieldStripReservePrimes`, which walks downward until it has found the
requested number of primes absent from the finite schedule.  In the targeted
full solve, the exhausted 65-prime schedule now selects `2147481907`, outside
the schedule, and returns a canonical solved strip after one lift prime.

## Test results

All six packaged baselines were green before candidate overrides:

| Packaged test | Result | Wall time |
|---|---:|---:|
| `t_diagonal_block_epsform.wls` | pass | 2.7 s |
| `t_finite_field_round2.wls` | pass | 22.2 s |
| `t_finite_field_strip_solve.wls` | pass | 2.5 s |
| `t_finite_field_adaptive_sampling.wls` | pass | 0.2 s |
| `t_finite_field_constrained_solve.wls` | pass | 16.1 s |
| `t_finite_field_eps_form.wls` | pass under the old identity-only gate | 47.7 s |

The targeted packaged adversarial script reproduced all five expected bad
behaviours in 3.3 seconds with no messages.  With the final external
candidates:

- `TestCodexEpsFormCandidates.wls`: 9/9 checks pass in 0.05 s.
- `CandidateRegressionDiagonal.wls`: 23/23 checks pass in 3.4 s.
- `CandidateRegressionFiniteFieldRound2.wls`: all checks pass in 26.1 s,
  including held-out sampling, sparse support, FLINT/Wolfram agreement and
  unseen-prime checks.
- `CandidateRegressionFiniteFieldRawRejection.wls`: 9/9 checks pass in 7.9 s;
  the raw gauge/residues and modular images reproduce exactly, while canonical
  certification is refused before the exact residual pass.
- `CandidateRegressionFiniteFieldStripSolve.wls`: all 9 checks pass in 2.6 s,
  including rejection of the raw checkpoint installation.

The old `t_finite_field_eps_form.wls` expectation intentionally fails under
the corrected gate.  That is not a compatibility defect in the candidate: the
fixture itself says `RawResidues -> True`.  Its replacement expectation is
`CandidateRegressionFiniteFieldRawRejection.wls`.  Likewise, the installation
assertions in `t_finite_field_strip_solve.wls` must use a genuinely canonical
fixture or assert rejection of this raw one; the corrected version is included.

## Additional stress probes

- A reducible two-by-two one-pole slice with residue eigenvalues `{60,61}`
  exposes the known single-regulator integer-alias ambiguity of the
  `NumericalEps` slice helper (`{-41,-40}` at `eps=1/101`, versus `{60,61}`
  symbolically).  This is outside the intended irreducible-block route.  On an
  irreducible noncommuting KZ-type system scaled by 60, numerical and symbolic
  slice residues agree exactly and both full drivers certify.  The final exact
  gate also prevents a false positive.  I do not recommend adding cost to the
  production route for this reducible-only probe.
- A custom support outside the chosen numerator rectangle fails closed rather
  than certifying.  A typed bounds check would improve diagnostics, but it is
  not a soundness blocker and is not included in the candidate changes.

## Integration order and test migration

The full external files are drop-in comparison copies.  Integrate their small
diffs in this order:

1. `CodexFiniteFieldEpsFormCandidate.wl`
2. `CodexFiniteFieldStripSolveCandidate.wl`
3. `CodexDiagonalBlockEpsFormCandidate.wl`

Then migrate the two raw-fixture tests as described above.  The public usage
text in `FeynFacet.m` should also say that `VerifyEpsFormStrip` reports literal
residual equality separately from `CanonicalEpsFormCertified`, and that the
diagonal gate requires epsilon-independent letters.

Do not label or install the CF254 `(9,6)` raw fixture as `ExactDLog`; it remains
useful as a modular reconstruction fixture.

## Files

- `CodexDiagonalBlockEpsFormCandidate.wl` — diagonal gate fix.
- `CodexFiniteFieldEpsFormCandidate.wl` — structural/canonical verifier and
  fail-fast reconstruction gate.
- `CodexFiniteFieldStripSolveCandidate.wl` — unbounded reserve-prime selection
  and installation structural gate.
- `TestPackagedEpsFormStress.wls` — packaged counterexamples.
- `TestCodexEpsFormCandidates.wls` — final negative and positive candidate
  checks.
- `CandidateRegressionDiagonal.wls`
- `CandidateRegressionFiniteFieldRound2.wls`
- `CandidateRegressionFiniteFieldRawRejection.wls`
- `CandidateRegressionFiniteFieldStripSolve.wls`
- `AnalyzeLegacyRawResidues.wls`, `ProbeAdditionalEdgeCases.wls`, and
  `ProbeHighResidueDriver.wls` — focused diagnostics.
- `logs/` — baseline, counterexample, candidate and migration logs.

## Hashes and package preservation

Packaged sources after the audit (unchanged from before it):

```text
d33863ff0bde0507dfe02097c3313a15aefca0b0b2dd88a00f5383c5f7cecde5  FeynFacet/Private/DiagonalBlockEpsForm.wl
b9a31bb5f76d85322a9e74c40edfc6c629527d6b1d9d20cbe48d2ed27d297448  FeynFacet/Private/FiniteFieldEpsForm.wl
be269c6c04c15817cc0e6e6782ce9549f5d67f0cc99901537cf9647c4bc87bfd  FeynFacet/Private/FiniteFieldStripSolve.wl
```

Final external candidates:

```text
f30ee4528774b3ea1e966b7d0aafebe8ac2dfbdab092545db54d45960e0882d4  CodexDiagonalBlockEpsFormCandidate.wl
1409e5125861b30f28596f876234ad361b7df06efc1c2fea3edef47d6207c910  CodexFiniteFieldEpsFormCandidate.wl
163d6d683e5b71140fc31b521a70f80347e142b5d0725145175f618314bb3db6  CodexFiniteFieldStripSolveCandidate.wl
```

The tests used one dedicated main Wolfram kernel with six subkernels.  No
unrelated process was signalled or stopped.
