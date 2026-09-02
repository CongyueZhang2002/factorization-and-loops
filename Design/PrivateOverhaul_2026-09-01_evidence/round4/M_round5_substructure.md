# Round 5, agent M: substructure inside the layers (user ruling "subsubfolders")

**Date:** 2026-09-02, from 14:20 PDT.  **Ruling:** Design/PrivateOverhaul_2026-09-01.md, section
"Round 5" (layout table).  **Rules kept:** every kernel through the seat launcher, 300 s caps,
`git mv` for tracked files (staged renames only, no commit), no edit to the plan or HANDOFF.
Every log was checked for its own tally line and for "Failed to open file" (none); wall times
are the seat-log acquire-to-release times.  Pure moves: no definition was edited; the head
multiset over all of `FeynFacet/Private` (`^symbol[`, excluding Begin/End/Clear/ClearAll) is
compared before and after every phase.

## Phase 1: Core, Process, Reduction (done, verified)

### (a) Loader (`FeynFacet/FeynFacet.m:419-445`)
A manifest entry may now be a path relative to its layer (`"Modular/ModularArithmetic.wl"`)
or a bare name (`"TaskBroker.wl"`); the shape `layer -> {entries}` is unchanged.
`$feynFacetPrivateModuleNames` (bare names of every entry) must be duplicate-free, otherwise a
typed `Print` names the duplicates and the load `Abort`s (line 431).  `$feynFacetPrivateFileIndex`
carries both spellings of every entry, so `feynFacetPrivateFile["ModularArithmetic.wl"]` and
`feynFacetPrivateFile["Modular/ModularArithmetic.wl"]` return the same path (`$Failed` for an
unknown name).  The one production caller (`FiniteFieldStripSolve.wl:277`, bare name) needs no
change.

### (b) Core (`git mv`, staged; the split by Core.wl's own banners)
| from | to |
|---|---|
| `Core/MultiquadraticAlgebra.wl` | `Core/Algebra/MultiquadraticAlgebra.wl` |
| `Core/RationalMaterialization.wl` | `Core/Algebra/RationalMaterialization.wl` |
| `Core/ModularArithmetic.wl` | `Core/Modular/ModularArithmetic.wl` |
| `Core/Core.wl` (1293 lines) | `Core/Base/Core.wl` (813) + `Core/Artifacts/Artifacts.wl` (142, new) + `Core/Algebra/Radicals.wl` (125, new) + `Core/Charts/ChartData.wl` (277, new) |

The split (`scratchpad/round4/M/r5/split_core.py`) cut `Core.wl` at its own section comments,
verified each cut sits on a blank line between top-level statements, kept the head multiset of
the four pieces equal to the original's (79 heads) and every non-blank original line present
verbatim; its single `ClearAll` list (31 names) was partitioned by defining file (Base 15,
Artifacts 5, Radicals 4, Charts 7, none dangling) and the public `Clear[FamilyArtifactRead,
FamilyArtifactWrite]` travelled with those definitions.  Contents:
- **Base/Core.wl**: everything before the round-4 banner (contexts, installation geometry,
  kernel counts, result headers, basis/scalar declarations, exact zero tests, linear integral
  sums) + the regulator/variable resolution and word collector (`$masterTransportRegulatorNames`
  ... `masterTransportCollect`) + the zero tests, check level and exact-point zero test
  (`masterTransportSimplifyZeroQ` ... `masterTransportPointZeroQ`).  A short note after the
  banner (lines 631-638) says where the rest went.
- **Artifacts/Artifacts.wl**: `$familyArtifactReadMessages`, `FamilyArtifactRead/Write`, the
  four `coefficient*Record` binary-record functions.
- **Algebra/Radicals.wl**: the "algebraic letters: radicals of the spectator" section
  (`masterTransportRadicalQ/Canon/Normalize/ZeroQ`).  **Judgement call:** that section's tail
  (`SimplifyZeroQ`, `ZeroQ`, `ZeroMatQ`, `CheckLevel`, `PointZeroQ`) is the file's "Sound zero
  test" block, which the plan's table assigns to Base ("zero tests"); it stayed in Base, and
  Radicals.wl holds the radical algebra only.  The boundary is the comment `(* Sound zero test.`
  (a top-level statement boundary), so the cut is clean.
- **Charts/ChartData.wl**: the "Two-variable chart pullback" section (`masterTransportFreeSymbols`,
  `RationalQ`, `ChartRecordQ`, `ChartData`, `PullBackOneForm`, `MapTogetherSubstitute`,
  `Options[...]`/`masterTransportPullBackSystem`).
The three new files carry `Begin["FeynFacet`Private`"]`/`End[]` (Core.wl itself is loaded
inside FeynFacet.m's own `Begin` and has none; nesting is harmless).  Load-time references: the
only load-time statements in these files are literal `$`-assignments and one literal `Options`
list, so the order Base, Modular, Algebra (MultiquadraticAlgebra, RationalMaterialization,
Radicals), Artifacts, Charts holds with nothing forcing another order.

### (c) Process and Reduction (`git mv`, staged)
Process: `Cards/Process.wl`, `Cards/CanonicalFamilies.wl`, `Diagrams/Topologies.wl`,
`Diagrams/Collinear.wl`, `Diagrams/DimensionalShift.wl`.  Reduction: `Kira/Reduction.wl`,
`Kira/StreamingKira.wl`, `AmFlow/MasterIntegralAmFlow.wl`, `Coefficients/Simplification.wl`,
`Coefficients/CoefficientStore.wl`, `Coefficients/Reconstruction.wl`, `Coefficients/Assembly.wl`.

### (d) Manifest (`FeynFacet/Private/LoadOrder.wl`)
Entries of the three layers are the relative paths above in the previous load order (Core:
Base, Modular, Algebra x3, Artifacts, Charts); the header gained a "SUB-FOLDERS" block with one
line per sub-folder and what belongs there (lines 66-108), including the EpsForm/Transport
placeholders for phases 2-3.

### (e) Path consumers
- Tests that `Get` a Core module by literal path now use `FeynFacet`Private`feynFacetPrivateFile`:
  `Tests/FiniteField/t_modular_arithmetic.wls:66` (ModularArithmetic.wl; header line 2 updated);
  `Tests/Multiquadratic/t_multiquadratic_algebra.wls:35, 194`, `_algebra_differential.wls:52`,
  `_persistence.wls:56`, `_prepare_core.wls:46`, `_provenance.wls:61`, `_strip_solve.wls:48`
  (MultiquadraticAlgebra.wl).
- The six manifest-reading multiquadratic tests and the four source-scan tests now address the
  solver files through `feynFacetPrivateFile[#]` and select on `FileNameTake[#]`, so they are
  already correct for the phase-2 relative entries.
- `Scripts/Diagnostics/overhaul/route_split.py` and `reachability.py` walked `Private/` with
  `os.listdir` (which, since round 4, saw only `LoadOrder.wl`): both now use a `private_files()`
  walk of any depth; `move_to_backup.py` accepts a nested `Private/<layer>/[<sub>/]File.wl` and
  writes the full relative path into its provenance header (its docstring says so).
- Prose-only mentions left as they were, all still resolvable by name: `Scripts/verify_reconstruction_slice.wls:18`,
  `Scripts/assemble_reconstruction.wls:23` (Reduction/Reconstruction.wl), the round-4 evidence
  notes, CLAUDE.md.  `Scripts/Diagnostics/ModularSplitPoints.wl:3` (mine) updated.
- No Scripts file loads a Core/Process/Reduction module by literal path (grep over
  `"Private", "Core"|"Process"|"Reduction"` and `Private/<layer>/`).

### (f) Verification
- **Load check** (`scratchpad/round4/M/r5/load_check_r5.wls`, seat, 4 s): one definition head per
  moved or new file has DownValues > 0 (19 files: `facetKernelCount`, `modularRationalReconstruct`,
  `multiquadraticBasisMasks`, `rationalMaterializationRationalQ`, `masterTransportRadicalQ`,
  `FamilyArtifactRead`, `masterTransportFreeSymbols`, `GenerateDiagram`, `momentumRelativeSign`,
  `canonicalFamilyName`, `dimensionalShiftPreserveCuts`, `convertAmplitudeSide`, `ibpFail`,
  `kiraStreamFamilyKey`, `masterIntegralFail`, `coefficientFormatDuration`, `assemblyGhostSign`,
  `coefficientAnalyticContextQ`, `reconstructionFail`); `feynFacetPrivateFile` answers both
  spellings for a Core, a Reduction and a flat entry and `$Failed` for an unknown name; 48
  module names, unique; every manifest file exists.
- **Head multiset** over all of `Private` (46 -> 49 files): identical before and after, 1883
  heads (`scratchpad/round4/M/r5/heads_before.txt` vs `heads_after1.txt`).
- **Tests** (seat A):

| test | cap | verdict | wall |
|---|---:|---|---:|
| `Tests/FiniteField/t_modular_arithmetic.wls` | 120 | 62 assertions, 0 failed; 0 `Set::shape` | 26 s |
| `Tests/Core/t_family_artifact_read.wls` (Artifacts.wl) | 120 | 15 assertions, 0 failed | 3 s |
| `Tests/Multiquadratic/t_multiquadratic_algebra.wls` (reads the manifest) | 120 | 75 OK, 0 FAIL | 7 s |
| `Tests/Core/t_ghost_card_pipeline.wls` (Process: diagram generation 7 diagrams, pre-IBP pipeline) | 300 | 6 assertions, 0 failed | 6 s |
| `Tests/Core/t_streaming_kira_import.wls` (Reduction/Kira: `KiraSolve`, `KiraStreamImport`) | 300 | 19 assertions, 0 failed | 89 s |

## Phase 2: EpsForm

Unlocked by the coordinator after G finished its EpsForm edits; executed only after the last
phase-1 kernel had exited (a move under a loading kernel is the race the plan warns about).
Pure moves, no file renamed, no definition touched.

### Moves (`scratchpad/round4/M/r5/phase2.sh`)
`git mv` for the 16 tracked files, plain `mv` for the 8 files that are still untracked in the
working tree (`FiniteFieldStripBroker.wl` and the seven round-4 solver parts, which the
committer will add at their new paths):

| sub-folder | files (manifest order preserved inside the layer) |
|---|---|
| `EpsForm/Blocks/` | CanonicalBlocks.wl, BlockEquationDeferred.wl, LibraEpsForm.wl, DiagonalBlockEpsForm.wl |
| `EpsForm/Strip/` | EpsFormStrip.wl, EpsFormStripObstruction.wl |
| `EpsForm/FiniteField/` | FiniteFieldEpsForm.wl, FiniteFieldStripSolve.wl, FiniteFieldStripBroker.wl, FiniteFieldGaugePullBack.wl |
| `EpsForm/Multiquadratic/` | MultiquadraticStripSolve.wl, MultiquadraticStripLetters.wl, MultiquadraticStripScreens.wl, MultiquadraticStripPrepareCompile.wl, MultiquadraticStripSampling.wl, MultiquadraticStripProviders.wl, MultiquadraticStripReconstruction.wl, MultiquadraticStripDriver.wl, MultiquadraticInstallation.wl |
| `EpsForm/Family/` | FamilyRegulatorFactor.wl, FamilyRowGauge.wl, FamilyRowGaugeResume.wl, FamilyCertificateModular.wl, FamilyEpsForm.wl |

No flat file is left in `EpsForm/`.  Manifest: the 24 entries became the relative paths in the
SAME order (the script asserted the old entry set equals the moved set); the header's
SUB-FOLDERS block gained one line per EpsForm sub-folder (Blocks, Strip, FiniteField,
Multiquadratic, Family) and now says Transport follows in phase 3.

### Path consumers
- Code: `Tests/FiniteField/t_finite_field_regulator_interpolation_backend.wls:7`,
  `Tests/Infrastructure/t_broker_adaptive.wls:593`, `Tests/Multiquadratic/t_family_regulator_root_frame.wls:79`
  and the six `Scripts/Diagnostics/CF300/2026-08-28/*.wls` that `Get` FiniteFieldStripSolve.wl
  by literal path now call `FeynFacet`Private`feynFacetPrivateFile["..."]` (each loads the
  package first, checked).  The six manifest-reading multiquadratic tests and the four
  source-scan tests were made layout-proof in phase 1 (`feynFacetPrivateFile[#]`,
  `FileNameTake[#]`), so they needed nothing here.
- Prose `Private/EpsForm/<File>.wl` -> `Private/EpsForm/<Sub>/<File>.wl` in 17 files (the seven
  solver-part headers, `CanonicalBlocks.wl:797` (a status string naming the replacement route's
  file), `Scripts/family_epsform_sector.wls:901`, eight test header comments).  Not in scope
  and left as is: `Scripts/family_epsform_pool.sh:4` (Infrastructure, flat, still valid),
  `Scripts/HardClassToolkit.wl:41` (a Transport path, phase 3), `Scripts/Backup/`,
  `Private_Backup/`.  `Tests/Multiquadratic/t_construction_budget.wls`, named in the
  coordinator's list, does not exist (`Tests/Infrastructure/t_construction_budget.wls` has no
  EpsForm path).

### Verification
- **Load check** (`scratchpad/round4/M/r5/load_check_p2.wls`, seat, 3 s): one definition head
  per EpsForm file has DownValues > 0 (24/24); `feynFacetPrivateFile` answers the bare and the
  relative spelling for a FiniteField, a Multiquadratic and a Family entry; 48 module names,
  unique; every manifest file exists; `Options[SolveEpsFormStrip]` 15 (the round-4 reference),
  `Options[solveEpsFormStripMultiquadratic]` 70 (the round-4 reference),
  `Options[SolveEpsFormStripInFrame]` 25 = `Join[Options[SolveEpsFormStrip]` (15) `, {10 own}]`
  as `Geometry/TransportCharts.wl:1122-1152` declares it today under G's uncommitted edits
  (round 4 recorded 26 for the earlier version of that list) -- full inheritance, so the
  EpsForm-before-Geometry load order is intact.
- **Head multiset** over all of `Private` after phase 2: identical to the phase-0 snapshot
  except eight `observableTransport*` heads (three removed, five added) in
  `Transport/ObservableTransport.wl`, whose mtime (14:19:32) is later than the snapshot
  (14:11:32); Transport has no rename and no edit of mine -- those are T's live edits, not a
  move effect.  Core/Process/Reduction/EpsForm heads are unchanged.
- **Tests** (seat A, 300 s caps):

| test | cap | verdict | wall (seat B) |
|---|---:|---|---:|
| `Tests/Multiquadratic/t_multiquadratic_algebra.wls` (reads the manifest; direct `Get` of the nine Multiquadratic files through `feynFacetPrivateFile`) | 300 | 75 OK, 0 FAIL | 6 s |
| `Tests/Multiquadratic/t_multiquadratic_regulator_filter.wls` (source-text scan of the eight solver files at their new paths) | 300 | 10 OK, 0 FAIL | 3 s |
| `Tests/EpsilonForm/t_epsform_obstruction.wls` (Strip/EpsFormStripObstruction.wl) | 300 | 7 OK, 0 FAIL | 64 s |

Not run, on the coordinator's time-pressure instruction (14:21, "only the load check, the head
multiset and two tests"): `t_diagonal_block_epsform`, `t_finite_field_gauge_pullback`,
`t_multiquadratic_regulator_factor` -- the chain that would have run them was stopped by its
verified PID after the obstruction test had started; that test finished on its own seat.
Every log above carries the test's own tally line and no "Failed to open file".

### State at hand-off (14:23)
Consistent and ready for a checkpoint commit: 24 EpsForm files in five sub-folders (16 staged
renames, 8 untracked files at their new paths -- `FiniteField/FiniteFieldStripBroker.wl` and the
seven round-4 solver parts, to be `git add`ed by the committer), manifest and consumers updated,
no literal `"Private", "EpsForm"` path left in code outside `Backup/`, no test kernel of mine
running.  Transport (phase 3) untouched, waiting for the coordinator's message.

### Open items
1. The three EpsForm tests above, plus `t_family_regulator_root_frame`, `t_broker_adaptive`,
   `t_finite_field_regulator_interpolation_backend` and the CF300 diagnostics scripts (their
   `Get` lines changed to `feynFacetPrivateFile`), have not been re-run after phase 2.
2. `Scripts/HardClassToolkit.wl:41` still names `Private/Transport/MasterTransport.wl` (prose);
   phase 3 will move that file to `Transport/Assembly/`.
3. Design notes and CLAUDE.md still describe the flat layer folders; a prose pass after phase 3.

## Phase 3: Transport

Unlocked after the merge of L's branch and the checkpoint commit 57bd613d, with the constraint
that `ObservableTransport.wl` moves last (T may still edit it).

### Step 1 (14:27): MasterTransport.wl and ObservableTransportFiniteField.wl
- `git mv` (staged): `Transport/MasterTransport.wl` -> `Transport/Assembly/MasterTransport.wl`,
  `Transport/ObservableTransportFiniteField.wl` -> `Transport/Observable/ObservableTransportFiniteField.wl`.
- Manifest: `"Transport" -> {"Assembly/MasterTransport.wl", "ObservableTransport.wl",
  "Observable/ObservableTransportFiniteField.wl"}` (a bare entry between two relative ones, as
  allowed); the header's SUB-FOLDERS block gained `Transport/Assembly` and
  `Transport/Observable` lines.
- Consumers: `Tests/Transport/t_observable_transport_finite_field.wls:6` (the only code path;
  it named `ObservableTransportFiniteField.wl`) now `Get`s
  `FeynFacet`Private`feynFacetPrivateFile["ObservableTransportFiniteField.wl"]` after
  `LoadFACET`; `Scripts/HardClassToolkit.wl:41` (prose) updated to `Transport/Assembly/`.  No
  Scripts file loads a Transport module by literal path.
- Verification: load check (`scratchpad/round4/M/r5/load_check_p3.wls`, seat, 3 s) --
  `masterTransportLoadLibra` and `TransportFamilyInChart` (Assembly/MasterTransport.wl) and
  `BuildObservableTransport` live, both spellings answer for both moved files, the bare entry
  `ObservableTransport.wl` still resolves, 48 unique module names, every manifest file exists,
  `Options[SolveEpsFormStripInFrame]` 25, `Options[BuildObservableTransport]` 16;
  `Tests/Transport/t_observable_transport_finite_field.wls` (direct `Get` of the moved
  finite-field compiler through `feynFacetPrivateFile`, cap 300): **18 assertions, 0 failed**,
  4 s.  (One of my five probe names, `observableTransportFiniteFieldCompile`, does not exist in
  that file -- probe error, not a load failure; the test exercises the file directly.)

### Step 2: ObservableTransport.wl -- waits for "move ObservableTransport.wl"
Staged as `scratchpad/round4/M/r5/phase3_step2.sh` (git mv, manifest entry, load check with a
head from each Observable file, the finite-field test once).
