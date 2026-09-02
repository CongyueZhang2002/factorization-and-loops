# Round 4, agent M: finite-field consolidation, legacy ABI records, multiquadratic split

**Date:** 2026-09-02, 13:30-14:30 PDT.  **Input:** `Exchange/Codex/2026-09-02/01_private_overhaul_assessment.md`
(items "The modular test does not restore its context", "`Core/ModularArithmetic.wl` is only a
partial consolidation", "test one real pre-overhaul checkpoint", "split `MultiquadraticStripSolve.wl`").
**Files owned and touched:** `FeynFacet/Private/Core/ModularArithmetic.wl`,
`FeynFacet/Private/EpsForm/MultiquadraticStripSolve.wl` (now eight files, see 4),
`Tests/FiniteField/t_modular_arithmetic.wls`, `Tests/Multiquadratic/` (twelve files).
`FeynFacet/Private/EpsForm/FiniteFieldStripSolve.wl` was read, not changed (its only
prime-schedule body already calls `modularPrimes`, line 2656).  **Outside my ownership, by the
task's explicit allowance or instruction:** one list entry in `FeynFacet/Private/LoadOrder.wl`
(the "EpsForm" list, line 73 -- the other lines that `git diff` shows in that file are G's
concurrent edits, not mine) and the new file `Scripts/Diagnostics/ModularSplitPoints.wl`
(the task says functions without a production caller "must move to Scripts/Diagnostics/").
No git state was touched; `Design/PrivateOverhaul_2026-09-01.md` and `HANDOFF.md` were not edited.

Every kernel run went through the seat launcher with the stated cap; every log was checked for
the test's own tally line and for "Failed to open file" (none); wall times below are the seat
log's acquire-to-release times.  Line numbers are the state of the files at the end of the
round (after the split).

## 1. `t_modular_arithmetic.wls` restores its context (Codex item, red)

**Defect confirmed by reading:** line 74 saved `{$Context, $ContextPath}` into the bare symbol
`ftModularSavedContexts` while `$Context` was `Global\``; lines 75-76 switched to
`FTModularArithmeticTest\``; the restore at line 473 spelled the same bare name, which now
resolved in the new context, unset -- `Set::shape`, restoration skipped, 61/61 reported.

**Change** (`Tests/FiniteField/t_modular_arithmetic.wls`): the saved pair lives in
`Global\`ftModularSavedContexts` at the save (line 85) and at the restore (line 489); a new
section H (lines 483-495) asserts after the restore that `$Context === "Global\`"`, that the
pair equals the saved one, that `FTTest\`` is on the path and `FTModularArithmeticTest\`` is
not; the report is called as `FTTest\`FTReport[]` so the assertion cannot depend on the
restore it checks.  Header comment updated (lines 71-78).

**Result:** 62 assertions, 0 failed, **zero** `Set::shape` lines in the output, exit 0;
4.6 s wall (`time`), seat A 13:31:02-13:31:07.  Re-run after point 2 (13:50:17): 62/62, zero
`Set::shape`.

## 2. `Core/ModularArithmetic.wl`: migration completed

### 2.1 Inventory (every production call site read)

| primitive | production callers (after this round) | duplicates found in my files | action |
|---|---|---|---|
| `modularRationalReconstruct` | `FiniteFieldEpsForm.wl:107`, `FamilyCertificateModular.wl:117` | none (both strip solvers lift through the `FiniteFieldEpsForm.wl` wrappers) | none |
| `modularCRT` | `FiniteFieldEpsForm.wl:116` (hence every `epsFormFiniteFieldCombineCoordinate` lift) | none | none |
| `modularImageQ` | `FiniteFieldEpsForm.wl:141` | none | none |
| `modularSquareRoot(s)` | `MultiquadraticAlgebra.wl:170`, `FamilyCertificateModular.wl:539`, `ObservableTransportFiniteField.wl:221,257`, and now both multiquadratic screens | the two screens' own `PowerMod[delta, (p+1)/4, p]` plus square check | replaced (2.2) |
| `modularResidueQ` | **new:** every split-point test of the multiquadratic solver (11 sites) | the inline `JacobiSymbol[#1, prime] === 1 &` idiom | replaced (2.2) |
| `modularPrimes` | `FiniteFieldStripSolve.wl:2656` (`finiteFieldStripReservePrimes`) | the multiquadratic fresh-image draw -- **different semantics**, kept (2.3) | documented |
| `modularLift` | none | the multiquadratic regulator lift -- **different semantics**, kept (2.3); an identical composition exists in two files I do not own (2.4) | kept in Core, documented, reported |
| `modularSplitPointQ`, `modularSplitPoints`, `modularEvaluateAt` | none | none identical (2.3) | **moved verbatim** to `Scripts/Diagnostics/ModularSplitPoints.wl` |
| `modularTonelliShanks` | internal to `modularSquareRoot` | -- | none |

### 2.2 Replacements (semantics proved identical by reading both sides)

*Residue test.*  All 11 occurrences of `JacobiSymbol[#1, prime] === 1 &` in the solver became
`modularResidueQ[#1, prime] &`: `MultiquadraticStripScreens.wl:669, 1554`;
`MultiquadraticStripSampling.wl:380, 384, 490, 1188, 1256, 1376`;
`MultiquadraticStripProviders.wl:1929, 2165, 2208`.  Identity: for an odd prime p and an
integer v, `JacobiSymbol[v, p] === 1` iff `Mod[v, p] =!= 0 && JacobiSymbol[v, p] === 1`
(the symbol is 0 at a multiple of p), which is `modularResidueQ`; for a non-integer (`$Failed`
from a failed evaluation) both sides are not `True`, so `AllTrue` returns `False` either way.
The only difference is at p = 2 (Kronecker reading versus a typed `$Failed`), and every entry
gate of the solver requires `p > 3` (or `p == 3 mod 4`) before these sites are reached.
`JacobiSymbol` no longer occurs in the solver.

*Square roots.*  In `multiquadraticStripIntegrabilityScreen` and `multiquadraticStripGaugeScreen`
(`MultiquadraticStripScreens.wl:673-682` and `1558-1567`) the block
`rootValues = PowerMod[deltaValues, (prime + 1)/4, prime]; If[! AllTrue[..., Mod[root^2 - delta, prime] === 0 &], rejected["RootImageNotARoot"]++; Continue[]]`
became `rootValues = multiquadraticSquareRoots[deltaValues, prime]; If[rootValues === $Failed, rejected["RootImageNotARoot"]++; Continue[]]`.
Identity: both screens admit only `PrimeQ[p] && Mod[p, 4] == 3` (entry gates at
`MultiquadraticStripScreens.wl:` the `InvalidIntegrabilityScreenInput` / `InvalidGaugeScreenInput`
checks), and the residue test just above guarantees every `delta` is a nonzero residue; for
such inputs `modularSquareRoot` returns exactly `PowerMod[a, (p+1)/4, p]` (its Euler pre-check
passes, its square check passes by Euler's criterion), so the root list is the same
representative-by-representative (the multiquadratic ABI the modular test pins) and the
`RootImageNotARoot` branch is as unreachable as it was.  `(prime + 1)/4` no longer occurs in the
solver.  `multiquadraticSquareRoots` is the solver's existing name for `modularSquareRoots`
(a one-line alias in `Core/MultiquadraticAlgebra.wl:170`), not a second implementation.

### 2.3 Production bodies kept, and why (documented in both headers)

Header of `MultiquadraticStripSolve.wl` (lines 91-119) and of `ModularArithmetic.wl`
(lines 52-70):

- *Split points.*  The solver evaluates a radicand at a point with
  `multiquadraticStripModRational` (exact `Together`, then ONE reduction) and needs the reduced
  values for the roots; `modularSplitPointQ` reduced literal by literal
  (`modularEvaluateAt`) and refuses a coefficient denominator divisible by p even when it
  cancels, and returns only a verdict.  Not a drop-in; the production form is kept and
  `modularResidueQ` is the shared part.
- *Fresh-image primes* (`multiquadraticStripFreshResidueScreenImages`,
  `multiquadraticStripFreshScreenImages`): `NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]]`
  under `RandomSeeding -> seed + 104729`, filtered to 3 mod 4, unseen, distinct.
  `modularPrimes["Random" -> s]` draws `RandomPrime` on `[2^30, 2^31)` under `SeedRandom[s]`:
  a different sequence, which would rename the primes in every stored screen-evidence record.
  Kept.
- *Regulator lift* (`multiquadraticStripReconstructRegulator`,
  `MultiquadraticStripReconstruction.wl`, the `liftAttempt` closure): CRT, reconstruction at
  the product modulus and the image check at every prime are the Core primitives through
  `epsFormFiniteFieldCombineCoordinate` / `RationalReconstruct` / `ImageQ`, but the loop
  records the `Position` of every unreconstructible coefficient
  (`"UnresolvedCoefficientLocations"`), which the prime-schedule extension consumes;
  `modularLift` returns a bare `$Failed`.  Kept.

### 2.4 The move and the consequences

- `Scripts/Diagnostics/ModularSplitPoints.wl` (new, 127 lines): `modularEvaluateAt`,
  `modularSplitPointQ`, `modularSplitPoints` verbatim (the split script asserted the copied
  block is byte-identical to the removed one), with `Begin`/`End`, a `ClearAll` and a header
  saying why they left the package.  Not loaded by the package.
- `ModularArithmetic.wl`: header rewritten (lines 1-76: the consumer table above, the kept
  bodies), `ClearAll` reduced to the nine live symbols (80-90), the split-point section
  removed, comment updates at `modularLift` (245-253: status and the two identical
  compositions in files I do not own), `modularSquareRoot` (zero handling now points at
  `modularResidueQ`), `modularResidueQ` (its production role).  501 -> 461 lines.
- `Tests/FiniteField/t_modular_arithmetic.wls:67` reads the diagnostics file after
  `ModularArithmetic.wl`, so sections F keep exercising the sampler; header lines 55-61 say so.
- `Tests/Multiquadratic/t_multiquadratic_algebra.wls:153-171`: the two assertions that named
  `modularSplitPointQ` now pin `modularResidueQ` on reduced radicands (accepts all-square,
  rejects a vanishing radicand), with the same independent `JacobiSymbol` reference.
- **`modularLift` stays in Core although it has no production caller**, because the task's
  rule for moving requires "no identical duplicate" and there are two, in files I do not own:
  `diagonalBlockLiftFunction` (`EpsForm/DiagonalBlockEpsForm.wl:947-962`) and the coefficient
  lift of `EpsForm/FiniteFieldGaugePullBack.wl:974-985` are exactly CRT + reconstruction at the
  product modulus + `ImageQ` at every prime on their padded numerator/denominator lists (the
  image check against the CRT value is the check against the original image, since they are
  congruent).  Open item for G, see 6.

### 2.5 Verification of point 2

| test | verdict | wall (seat log) | note |
|---|---|---|---|
| `Tests/FiniteField/t_modular_arithmetic.wls` (cap 120) | 62 assertions, 0 failed; 0 `Set::shape` | 5 s (13:50:17) | loads Core + the diagnostics file |
| `Tests/Multiquadratic/t_multiquadratic_algebra.wls` (cap 120) | 75 OK, 0 FAIL | 7 s (13:50:24) | pins `modularResidueQ` |
| `Tests/Multiquadratic/t_multiquadratic_persistence.wls` (cap 300) | 53 OK, 0 FAIL | 34 s (13:56:34) | its S section runs both per-image screens (the replaced root blocks) |
| `Tests/Multiquadratic/t_multiquadratic_obstruction_driver.wls` (cap 300) | 23 OK, 0 FAIL | 4 s (13:53:00) | |
| `Tests/Multiquadratic/t_multiquadratic_obstruction_images.wls` (cap 300) | 19 OK, 0 FAIL | 5 s (13:53:05) | integrability screen at real points |
| `Tests/Multiquadratic/t_multiquadratic_gauge_screen.wls` (cap 300) | 59 OK, 0 FAIL | 75 s (13:54:20) | gauge screen at real points |

`Tests/FiniteField/t_finite_field_strip_solve.wls` was **not** run: `FiniteFieldStripSolve.wl`
is unchanged and `modularPrimes` is unchanged; the test reads `Codex/TwoRootCF254Sector9Lower`
fixtures and has no tally line of its own.  The strip-solver test of point 4 covers the
multiquadratic route end to end.

## 3. Legacy ABI records ("SourceSHA256" -> "ABIVersion")

**What the pre-U3 writer stored** (read from `git show 96be12e9:.../MultiquadraticStripSolve.wl`,
read-only): every checkpoint header, letter certificate, potential and compiled assembly
carried `"SourceSHA256" -> FileHash[<this file>]` where today's carry `"ABIVersion"`, in the
same key position; the checkpoint seal was the fingerprint of that header and the
`AssemblyFingerprint` the fingerprint of the semantic payload whose last key was
`"SourceSHA256"`.  **What the validators did at the start of this round:** required the
`"ABIVersion"` key (`KeyExistsQ` list, header `KeyTake`, certificate `KeyTake`) -- a legacy
record failed every one of them, while the prose at line 502 claimed acceptance.  **What is on
disk:** a bounded `grep -l` over `ppHX_NNLO_DoubleReal/Results` and `Tests/Multiquadratic/Fixtures`
for the five multiquadratic schema strings found **no** stored record of these schemas; the two
fixtures named in the task (`cf259_frozen_rows24.wl`, `cf300_frozen_stripsolvers.wl`) carry
`"SourceSHA256"` as the hash of the *sector state they were frozen from*, under the schemas
`FeynFacetFrozenTestFixture` and `FrozenCF300StripSolversV1`, and never pass through the
multiquadratic validators.

**Measured refusal before the fix:** the new test, run against the unpatched validators
(13:50:27, exit 13): 27 assertions, 13 failed -- exactly the admission and lineage assertions
(A2, A4-A8, B2, B5, C2-C4, D1 and the helper-existence check); the 14 refusal and current-format
assertions already passed.

**Fix -- an alias of the key, not a weakening** (`MultiquadraticStripSolve.wl`):
- prose at lines 323-331 corrected; helpers at 335-386: `multiquadraticStripLegacySourceSHA256Q`
  (64 hex digits), `multiquadraticStripABIKey` (`"ABIVersion"` if present, else
  `"SourceSHA256"` if well formed, else `$Failed`), `multiquadraticStripABILineage`
  (`"ABIVersion"` / `"LegacySourceSHA256"` / `$Failed`), `multiquadraticStripABIVersionValidQ`
  (current key must equal the ABI-1 string; legacy key admitted), `multiquadraticStripABIAliasExpected`
  (an expected certificate re-keyed to the record's lineage, same position);
- `multiquadraticStripPrepareCheckpointAccept` (728-751): a record with neither key or a
  malformed legacy hash is refused typed (`PrepareCheckpointABIUnknown`); the header seal is
  recomputed over the key the record carries; `"ABILineage"` is reported in the `Accepted`
  verdict;
- letter dlog certificates, V1 and channel schema (`MultiquadraticStripLetters.wl:1054, 1083`):
  the expected certificate is aliased to the record's key before the `KeyTake` comparison;
- `multiquadraticStripSemanticPayload` (`MultiquadraticStripPrepareCompile.wl:2481`): the last
  key is the record's identity key, so a legacy `AssemblyFingerprint` is recomputed over the
  pre-U3 payload exactly; `multiquadraticStripCompiledValidQ` (2875-2900): required key and
  version test through the helpers;
- `multiquadraticStripReadPreparedArtifact` (`MultiquadraticStripDriver.wl:85`): the hydrated
  assembly carries `"ABILineage"`.
- Not aliased, deliberately: layouts, samples, providers and pool keys are built in memory by
  the current code and are never legacy.

The content binding is unchanged (every seal is still checked, over the key the record was
sealed with); what the alias gives up is comparing the legacy hash with anything, which is the
U3 ruling itself (every pre-U3 source is the ABI-1 lineage) -- and the hash stays bound by the
seal (test A10).  **One thing I added and then removed:** a version-equality refusal in the
checkpoint gate.  `t_multiquadratic_persistence` P5 pins "resume admission is blind to the
current implementation hash" (a checkpoint must be accepted with `$multiquadraticStripABIVersion`
blocked to another string): the persistence run of 13:52:56 failed that one assertion, the
refusal was removed, and A8 of the new test now asserts the admission.  The compiled-assembly
validator keeps its pre-existing version equality.

**Test:** `Tests/Multiquadratic/t_multiquadratic_legacy_abi_records.wls` (new, 355 lines,
27 assertions): A prepare checkpoints (current and pre-U3 format, direct and through
`multiquadraticStripArtifactWrite`/`LoadRaw`, five typed refusals, foreign-version admission);
B letter certificates in both schemas; C a real rank-2 compiled assembly of the persistence
fixture (compile 0.05 s) hydrated through `multiquadraticStripReadPreparedArtifact` in both
formats plus four refusals; D the real 2026-08-25 fixture `cf300_frozen_stripsolvers.wl` loads
raw with a well-formed legacy hash and lineage `LegacySourceSHA256`, and the prepared-artifact
reader refuses it typed (`ArtifactSchemaUnknown`) -- the alias admits a key, not a schema.
Results: **27/27** at 13:52:23 (4 s), 13:57:10 (after the gate correction, 4 s) and 13:58:59
(after the split, 4 s).

## 4. The split of `MultiquadraticStripSolve.wl` (18 060 lines) into eight files

Done last, after 1-3 were green and a load check of the unsplit file had produced reference
numbers.  Cuts at the file's own section banners (every cut line verified at bracket depth 0
with comments and strings stripped); every top-level statement copied verbatim, in order; the
only added text is one header comment per file, `Begin["FeynFacet\`Private\`"]`/`End[]`, and
the per-file `ClearAll`: the original 330-name list was **partitioned by where each symbol is
defined** (the task's "kept where the definitions they refer to now live"; 0 names without a
definition; the script asserts no symbol is defined in two files, since a later file's
`ClearAll` would erase it).  The second `ClearAll` (compile architecture) stays with its
definitions.  Reason for partitioning rather than keeping one list in the first file: six
tests re-`Get` the solver directly after `LoadFACET`, and a single list in file 1 would erase
the other seven files' definitions on that re-read.

| file (EpsForm/) | lines | definition heads | content |
|---|---:|---:|---|
| `MultiquadraticStripSolve.wl` | 798 | 39 | ABI and legacy alias, globals, stage announcements, failure/fingerprint utilities, forcing-channel provenance, prepare-checkpoint records, `ModRational`, canonical rules |
| `MultiquadraticStripLetters.wl` | 2296 | 80 | grade-basis field arithmetic, one-form span, alphabet construction, regulator samples, letter keys and dlog certificates, potentials, diagonal spans, candidate letters, gauge denominators |
| `MultiquadraticStripScreens.wl` | 2310 | 56 | residue-only integrability screen, admission/telemetry/compile cache, two-image rejection path, evidence classifier, full-gauge screen, degree-offset ladder |
| `MultiquadraticStripPrepareCompile.wl` | 3119 | 84 | preparation, exact channel compilation, compile architecture, compiled validator, row layout and coefficient ABI |
| `MultiquadraticStripSampling.wl` | 3388 | 80 | prime forms, point/sample assembly, sign transforms and differential certificate, affine solve (Wolfram/native/constrained/follower/pilot), support ladder, unpacking, exact residual |
| `MultiquadraticStripProviders.wl` | 3142 | 88 | direct coefficient providers, sparse plans, native backends, chart-forcing provider, preflight, provider channels, conservative/bundle gauge denominators |
| `MultiquadraticStripReconstruction.wl` | 1523 | 7 | rational-in-epsilon reconstruction |
| `MultiquadraticStripDriver.wl` | 1648 | 11 | artifacts, option gates, cache clearing, the top-level entry point and terminal acceptance |

Codex's five responsibilities map as: provider/compiler = PrepareCompile + Providers; sampling
and affine solve = Sampling; interpolation/lift = Reconstruction; persistence = the checkpoint
primitives in Solve + the artifact layer in Driver; terminal acceptance = Driver.  Letters and
Screens are the two large blocks that precede them in the file's own structure and did not fit
any of the five.

**Manifest:** `FeynFacet/Private/LoadOrder.wl:73`, the "EpsForm" entry
`"MultiquadraticStripSolve.wl"` replaced by the eight names in the order above (before
`"MultiquadraticInstallation.wl"`).  Load-time references checked: `Options` inheritance stays
within Screens (three chains) and Driver <- PrepareCompile (`Options[multiquadraticStripPrepare]`,
earlier file); `$`-globals evaluated at load reference only their own file or file 1
(`$multiquadraticStripMaximumRootCount`); `SetAttributes[multiquadraticStripCacheInsert, HoldFirst]`
stays adjacent to its definition; no top-level call exists in the source; no later module
inherits a multiquadratic `Options[...]` at load time (`TransportCharts.wl:2154` is inside a body).
`$multiquadraticStripSourceFile` (recorded as `"SourceFile"`, key-existence only) is still the
first file.

**Tests touched for the split** (all in `Tests/Multiquadratic/`): the six that `Get` the solver
directly (`t_multiquadratic_strip_solve`, `_prepare_core`, `_persistence`, `_provenance`,
`_algebra_differential`, `_algebra`) now read the manifest and `Get` every `MultiquadraticStrip*`
file in load order; the four that scan the source text (`_prepare_core`, `_regulator_filter`,
`_gauge_screen`, `_obstruction_images`) now join the text of all eight (otherwise the "no
surviving spelling" scans would have become vacuous and the "contract language" scans false).

**Verification (a), load check** (`scratchpad/round4/M/load_check.wls` through the seat, cap
120): before the split (13:55:57, 6 s) and after (13:58:15, 36 s) print identical numbers --
`DownValues` counts `solveEpsFormStripMultiquadratic` 2, `multiquadraticStripPrepare` 2,
`multiquadraticStripCompile` 2, `multiquadraticStripAssembleSample` 3,
`multiquadraticStripReconstructRegulator` 3, `multiquadraticStripIntegrabilityScreen` 2,
`multiquadraticStripDirectProvider` 2, `multiquadraticStripReadPreparedArtifact` 2,
`multiquadraticStripFailure` 1, `multiquadraticStripABIKey` 2; `Options` lengths 70 / 21 / 15 / 25
(`solveEpsFormStripMultiquadratic`, `GaugeScreenLadder`, `IntegrabilityScreenImages`, `Prepare`);
277 `FeynFacet\`Private\`multiquadraticStrip*` names; `SourceFile` = the first file.  (A first
version of the check used `DownValues[Symbol[...]]`, which holds its argument and reported 1 for
everything; it was replaced by `DownValues @@ {Symbol[...]}` and re-run before the split.)

**Verification (b), nothing lost:** definition heads (`^symbol[`, excluding `Begin`/`End`/
`ClearAll`) 445 in the original and 445 over the eight files, as an identical per-name multiset
(`diff` of `sort | uniq -c`), and the split script asserted the head *sequence* is unchanged and
that every non-blank original line outside the partitioned `ClearAll` block is present verbatim.
Line counts 18 058 -> 18 224 (+166 scaffolding lines).  The pre-split file is kept at
`scratchpad/round4/M/MultiquadraticStripSolve.wl.before_split`.

**Verification (c), tests after the split:**

All through the seat launcher from the repository root, 14:00-14:02 PDT, seat A; every log
carries the test's own tally line and no "Failed to open file"; wall = seat-log acquire to release.

| test (`Tests/Multiquadratic/`) | cap | verdict | wall | exercises after the split |
|---|---:|---|---:|---|
| `t_multiquadratic_algebra.wls` | 120 | 75 OK, 0 FAIL | 9 s | manifest-driven direct `Get` of all eight files; `modularResidueQ` |
| `t_multiquadratic_obstruction_driver.wls` | 120 | 23 OK, 0 FAIL | 3 s | screens through the driver |
| `t_multiquadratic_regulator_reconstruction.wls` | 120 | 18 OK, 0 FAIL | 4 s | `MultiquadraticStripReconstruction.wl` |
| `t_multiquadratic_legacy_abi_records.wls` | 300 | 27 assertions, 0 failed | 4 s | point 3 across four files |
| `t_multiquadratic_persistence.wls` | 300 | 53 OK, 0 FAIL | 36 s | direct `Get`; checkpoints; both screens; P5 |
| `t_multiquadratic_obstruction_images.wls` | 300 | 19 OK, 0 FAIL | 4 s | source-text scan over eight files |
| `t_multiquadratic_gauge_screen.wls` | 300 | 59 OK, 0 FAIL | 76 s | gauge screen; source-text scan |
| `t_multiquadratic_regulator_filter.wls` | 300 | 10 OK, 0 FAIL | 3 s | source-text scan (R5) |
| `t_multiquadratic_algebra_differential.wls` | 300 | 24 OK, 0 FAIL | 6 s | direct `Get` |
| `t_multiquadratic_provenance.wls` | 300 | 69 OK, 0 FAIL | 19 s | direct `Get` |
| `t_multiquadratic_prepare_core.wls` | 300 | 36 OK, 0 FAIL | 4 s | direct `Get`; source-text scan (O4) |
| `t_multiquadratic_strip_solve.wls` (once) | 600 | 92 OK, 0 FAIL | 23 s | the whole route; cases RANK0_1x1 2.1 s, RANK1_1x1 4.5 s, RANK2_2x1 4.8 s, RANK3_1x1 7.8 s (the task quoted about 270 s for this test; the measured run is 23 s, tally line present) |

Package load on this box is a few seconds (the load check prints its numbers in 4-6 s), so the
3-4 s runs are complete runs, as their tally lines show.

## 5. Runs that did not go as planned (all corrected, all visible above)

- Legacy test, first post-fix run: 26/27 because my foreign-version record used `Append` on an
  existing key (header order changed under `KeyTake`); rebuilt key by key.
- Persistence P5 red once (the version-equality refusal); removed, see 3.
- Load check's first form reported bogus `DownValues` counts; corrected before use.

## 6. Open items (for the owners named)

1. **G** (`DiagonalBlockEpsForm.wl`, `FiniteFieldGaugePullBack.wl`): `diagonalBlockLiftFunction`
   (947-962) and the lift at 974-985 are `modularLift` on padded coefficient lists; wiring them
   gives `modularLift` its production callers (or, if G decides otherwise, `modularLift` should
   follow the sampler to `Scripts/Diagnostics/`).  Until then the CLAUDE.md sentence "lift-and-
   verify has ONE implementation" is true of the primitives, not of the composition.
2. **G / T**: the same `JacobiSymbol[#, prime] === 1` idiom that `modularResidueQ` now replaces
   in the solver still occurs at `ObservableTransportFiniteField.wl:542, 551, 753, 761, 975, 997,
   1114, 1136` (T), `FamilyRegulatorFactor.wl:1281`, `BlockEquationDeferred.wl:780, 792`,
   `FamilyCertificateModular.wl:787` (G); drop-in for every odd prime.
3. **G**: `Scripts/Diagnostics/ModularSplitPoints.wl` is a new file in the Scripts tree
   (task-mandated); `LoadOrder.wl:73` carries my one-entry change.
4. The header comment of each of the seven new files has one over-long line (the content
   blurb); cosmetic, left as is to avoid another edit cycle on files under test.
5. Prose in test headers and Design notes still names the single file
   `MultiquadraticStripSolve.wl` as "the solver"; the path is still valid (part 1), so nothing
   is broken, but a reader should know it is eight files now.
6. `t_finite_field_strip_solve.wls` was not run (see 2.5).
