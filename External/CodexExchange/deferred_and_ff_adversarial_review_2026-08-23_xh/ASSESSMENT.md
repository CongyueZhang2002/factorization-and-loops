# Adversarial audit: deferred regulator propagation and finite-field hardening

Date: 2026-08-23 (America/Los_Angeles)

Scope: the staged deferred-row-gauge/regulator candidate and the two
finite-field hardening templates under `External/CodexExchange`, checked
against the pinned package sources.  This review launched no Wolfram kernel,
edited no package source, and signalled no process.

## Verdict

There is no P0 algebraic error on the intended production path.  If `T` is the
constant, exactly inverted transformation already certified by
`FactorFamilyRegulatorDependence[InFrame]`, and the connection is block lower
triangular,

`diag(T^-1,I) A diag(T,I) = {{T^-1 A00 T,0},{A10 T,A11}}`.

The proposed deferred helper installs exactly these four blocks.  The sector
driver also composes the accumulated transformation in the correct order,
`S -> S diag(T,I)` and `SInverse -> diag(T^-1,I) SInverse`.  The row-gauge
deferred sums are only a representation change, the atomic state write remains
before the skipped progress census, and Production still writes only a
`CandidateEpsilonForm`; the separate family certifier is the exact acceptance
boundary.

The candidates are not yet merge-ready.  The following P1 issues should be
closed first.

## P1 findings

### 1. Cached modular artifacts bypass the explicit backend contract

The finite-field patch hardens live samples, but the production cache reader
still accepts an artifact using only `RecordFingerprint`, numerator offset and
support shell.  Therefore a run requesting explicit `"FLINT"` can silently
load an old Wolfram-produced interpolation without invoking FLINT at all.  It
can then report a solver configuration describing the new request, not the
execution that produced the cached residues.

This is both a backend-semantics and resume-provenance failure.  Bind every
modular artifact to the exact sealed plan fingerprint and a versioned backend
execution contract containing request, thread count, finite-field source hash,
and applicable native-binary hash.  Old artifacts must be stale, never legacy.

### 2. `Backend -> "FLINT"` still has an unreported Wolfram discovery stage

The existing `Backend` option controls only the constrained square core.  A
top-level explicit FLINT solve still discovers its M1 plan with Wolfram
`MatrixRank`, `LinearSolve`, `NullSpace`, and row selection; the pilot call does
not inherit the top-level backend request.  The candidate's statement that an
explicit request never calls Wolfram is consequently too broad, and
`BackendsUsed` omits the pilot.

Keep the two backends separate.  For this merge, explicitly record
`PlanDiscoveryBackendRequested/Used -> "Wolfram"` and describe `Backend` as the
fixed-core backend.  A future native affine-RREF route must be a distinct
`PlanDiscoveryBackend -> "FLINTAffineRREF"` contract with the CFFR certificate;
it must not be smuggled through the CFFA4 fixed-core option.

### 3. The deferred regulator helper does not enforce its mathematical domain

`familyRegulatorPropagateTruncation` documents a *constant* regulator
transformation but accepts an `x`/`y`-dependent matrix and never checks that
`inverse` is actually the two-sided inverse of `transformation`.  For such an
input the helper omits `-G^-1 dG` from the prefix and can return `Status -> OK`
for a wrong connection.  It also installs an arbitrary dimension-correct
`transformedPrefix` without any seal tying it to the just-certified factor.

The current factor routines do produce constant exact inverses, so this does
not falsify the observed CF300 path.  It does falsify the helper's advertised
fail-closed contract and leaves a one-field wiring or future factor regression
undetected until the expensive final family certificate.  Pass the kinematic
variables to the helper, reject transformations containing them, verify the
two inverse identities (regulator-only matrices make this cheap), and bind the
input/output/transform fingerprints returned by the factor routine before
installing the prefix.

### 4. Solver `ImplementationProvenance` is incomplete

The proposed provenance hashes only private solver files.  Zero forcing is
actually selected and constructed in `Scripts/family_epsform_sector.wls`, yet
that script is not hashed.  One-form materialization is in
`FamilyRowGauge.wl`, also not hashed.  For `Automatic`/`"FLINT"`, the native
binary is not hashed.  Thus a checkpoint may compare `SameQ` under a changed
implementation while claiming exact source binding.

Include the sector driver and materializer hashes for all applicable routes,
plus the backend execution contract from finding 1.  Increment the solver
configuration schema when doing this.

### 5. The staged finite-field files are not executable patch artifacts

Both numbered `.patch` files contain bare `@@` hunks: `git apply --check`
reports `patch with only garbage at line 4`, and they also lack the
`*** Begin Patch` grammar required by the workspace `apply_patch` tool.  The
README does say to rebase manually, so no source was silently changed, but the
deliverables must be converted to one real post-rebase apply-patch image before
integration.  Record the post-rebase source hashes in that image.

### 6. Native output canonicality is not part of the CFFA4 certificate

The new core check proves the modular residual but accepts arbitrary integers
congruent to the solution, including entries outside `[0,p-1]`.  Downstream
code assumes canonical field representatives and compares normalized vectors
structurally.  Require every returned word to lie in `[0,p-1]` (or reduce once
and record that normalization) before accepting the adapter response.

### 7. The tests miss the likely mutants above

The current exact deferred unit is strong for constant valid `T`, raw future
sums, and later-row overwrite.  It does not test a kinematic-dependent `T`, a
bad inverse, a mismatched transformed prefix, or the actual driver's
`S`/`SInverse` multiplication directions.  Its manual `S` construction would
still pass if the driver patch swapped them.

The finite-field driver tests process failure and plan metadata well, but do
not create a Wolfram cache followed by an explicit-FLINT request, inject a
noncanonical but residue-correct native matrix, or attest pilot-discovery
provenance.  Add these mutants before promotion.

## Resume and certificate ordering

- A sector certificate is appended before `factorTruncated[k]`, so reverse
  selection of the matching sector is correctly ordered.
- Regulator propagation failure stops before state mutation and writes a typed
  stop record.
- The successful state write remains before the guarded `badStrips` census.
- A crash before that write replays the strip checkpoint; a crash after it
  resumes from the exact raw sums.
- Old row certificates fall back to Together.
- A Development resume of an already-propagated Production state does not
  retroactively canonicalize old raw sums if the prefix is already eps
  factored.  This is exact, but the staged assessment's claim that Development
  always restores the canonical representation is too strong and should be
  corrected.
- The campaign shell does submit `certify_family_epsform_record.wls` after a
  successful candidate.  Direct use of the sector script alone still produces
  only a candidate, not an exact certificate, as it should.

## Required merge order

1. Wait for all source-pinned missions to finish and re-pin sources.
2. Rebase backend option validation, sealed plans, and live-sample telemetry.
3. Add modular-artifact plan/backend/source/binary binding in the same commit.
4. Rebase bounded failure persistence and solver configuration; expand its
   implementation provenance and bump its schema.
5. Integrate deferred row-gauge/regulator propagation with the constant,
   inverse, and factor-seal guards.
6. Run static gates, existing exact units, new mutants, copied-checkpoint
   Production/Development comparisons, real rational/algebraic cache replay,
   and finally a complete independent family certificate.

The three `.apply_patch` files in this review are concrete post-rebase
templates for the central guards, the factor input/output seal, and complete
solver/backend implementation provenance.  They are deliberately not applied
to package sources in this review.

## Static evidence

- Finite-field candidate static gate: 52/52 passed.
- Wolfram delimiter scan of the two deferred test drivers: passed.
- Pinned source hashes match the hardening README.
- No kernel-launch, parallel-map, process-execution, or shell-escape call is
  present in the staged adversarial drivers.
