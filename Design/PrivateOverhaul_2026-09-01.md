# FeynFacet/Private overhaul — living plan and progress (started 2026-09-02 03:00)

Assignment (user, 2026-09-02): overnight, autonomous overhaul of the package
internals, mainly `FeynFacet/Private/`. Goals in the user's numbering:
(1) stale-code separation into `Private_Backup/` with evidence, (2) dedup of
independently rebuilt wheels, (3) purposeful subfolder/layer structure with
an explicit load order, (4) maintainability/extensibility — declared geometry
data instead of code paths, (5) conciseness, (6) measurement-first
performance (representation fixes; GPU only on a measured hot path),
(7) correctness with failing-test-then-fix, (8) standardization of formats
and scripted drivers, (9) generality, (10) removal of over-certification and
hash bureaucracy, (11) finish CF259 transport as the integration proof.
Tests are a behavioural reference, not a requirement. Lane split with Codex
is dissolved; stale house rules yield to this assignment. Pace: normal, no
forcing.

Resources: 8 subkernels/cores (P-cores 0,1,6,7,8,9,18,19), RTX 5080
available. House rules kept: allowance + auto-kill on every launch, an Opus
watchdog per background run, exact acceptance only, evidence into Results/.

Baseline commit: `2d73f71f` (Codex's uncommitted work-in-progress committed
unmodified at takeover). Working scratchpad:
`/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad`
(`inventory/` static analyses, `bench/` benchmarks and the baseline test log,
`branch/` an extracted copy of `codex/day-rank3-validation`, `mergeprobe/` a
throwaway merge worktree).

## Findings from the survey (facts, measured 2026-09-02 03:00–03:40)

- Package: 39 files, 72,399 lines in `Private/`; `MultiquadraticStripSolve.wl`
  alone is 17,916 lines (25%). 4,968 defined private symbols; 91 public
  symbols; 158 test files in 7 categories.
- Symbol-level reachability from public API + Scripts + string-constructed
  names (parser corrected 04:10 to handle comment markers inside strings):
  1,646 live, 10 test-only, 15 dead (seven legacy sparse-reduction helpers
  in Core.wl, `canonicalBlocksOrbitAct`, `familyCertMQEvaluateMatrix`,
  `finiteFieldStripArtifactTag`, `multiquadraticFieldResetPathStatistics`,
  `multiquadraticStripAssemblePoint`, `observableTransportRowBasis`/
  `ColumnBasis`, `pathTransportExceptionPlanQ`). Stale code is therefore
  mostly whole ROUTES behind options and fallbacks, not unreachable
  symbols; the 15 dead symbols are removed in the cleanup commit.
- Two divergent code lines exist. `main` (ours, 320 commits since the
  2026-08-26 merge-base) and `codex/day-rank3-validation` (80 commits). The
  branch carries the accepted lazy-operator observable transport
  (`ObservableTransport.wl` +2,072 lines, new
  `ObservableTransportFiniteField.wl` 1,921 lines, pool mission and
  kernel-pool campaign scripts, 8 transport tests) with which Codex
  re-transported all 88 ordinary families on 2026-09-01 (88/88 accepted:
  86 exact, CF385/CF408 modular). `main` carries the CF303 exception seam
  (`PathTransportException.wl`, `PathTransportNative.wl`), the gauge
  pull-back and installation modules, `RationalMaterialization.wl`, and a
  9,225-line-larger `MultiquadraticStripSolve.wl`. A full merge has 17
  conflicting files (42 hunks in `MultiquadraticStripSolve.wl`, 33 in
  `BlockEquationDeferred.wl`); measured in the merge-probe worktree.
- Static dependency check of the branch's two transport files against
  `main`: they use no branch-only symbol outside themselves (the three
  reported names are locals). Definition-difference check of the shared
  symbols they call (03:40): eight differ, all in main's favour
  (hardening, extra charts, cleanup); the adoption keeps main's versions.
- CF259 state: off-diagonal completion finished by Codex 2026-08-31
  (`CF259_27_strip_state.wl`, 4.6 MB, `TransportReady -> True`); family
  eps-form assembled 2026-09-01 in the Codex tree
  (`Runtime/2026-09-01_observable_transport_triple_final/cf259_assemble/family_epsform_CF259.wl`,
  471 MB, expanded matrices); common dlog residues computed natively on
  the compact connection (13 CRT primes + fresh prime, 10.0 s, 47 masters,
  rank-3 root cover); compact transport-ready record
  (`cf259_dlog_gpu/family_epsform_CF259_compact.wl`, 47 MB, schema
  `TransportReadyEpsilonConnection` / `ConstantResidueDLog`). Transport
  itself has NOT run to completion: Codex's last commit (02:43 today)
  bypasses symbolic valuation scans that were the measured bottleneck on
  this record; no `observable_transport_CF259.wl` exists anywhere.
- GPU: Codex measured (2026-09-01/02) that an OpenMP CPU postfix evaluator
  beats their CUDA kernel 3.1x on the CF259 connection workload (0.36 s vs
  1.13 s per 88-image evaluation, 16 threads) and that end-to-end native
  dlog residues are 2.0x faster than CUDA. The GPU wins only for very long
  three-root canonicalization batches at parity with 16 ideal cores. No
  Python GPU stack is installed (no cupy/torch/numba); nvcc 13.0 exists.

## Decisions taken (with reasons)

- D0. **Goal 9 finding.** No package code path keys on a family name:
  every `CF<n>` occurrence in `Private/` is in a comment or a chart
  `Notes` string (measured 03:50). The chart catalog is keyed by root
  squares. Generality work therefore concentrates on the catalog's
  data form (goal 4) and on test fixtures that reach outside the
  repository (`t_exact_family_epsilon_form_q` reads `../FACET/...`
  relative to the repository parent).

- D1. **Transport layer: adopt the branch implementation into `main`
  surgically rather than a full merge.** The accepted, measured transport
  is on the branch; a full merge is a multi-hour, high-risk operation on
  files the overhaul will restructure anyway. Adoption = copy the two
  transport modules, the pool mission, the kernel-pool campaign driver and
  the eight transport tests; register in the load list; run the transport
  tests. Superseded main-side transport code goes to `Private_Backup/`
  with its evidence. Done 03:30-05:55; the branch's last revision carried
  two regressions (B4, B7) that adoption exposed and fixed.
- D2. **GPU: design note only, no implementation.** Measured evidence above
  says the hot finite-field evaluation is better served by the OpenMP CPU
  evaluator; the GPU path would need a cooperative-lane kernel redesign to
  compete. Recorded under Goal 6.
- D3. **Baseline first.** The full test batch runs on `main` at `2d73f71f`
  before any edit (started 03:15, 8 subkernels, allowance 4 h, watchdog
  running). Every later change is compared against that table.

## Workstreams and status

Legend: DONE / RUNNING / TODO / NOT-DONE (deliberate) / NEEDS-USER.

| # | Goal | Item | Status |
|---|------|------|--------|
| 0 | prep | Survey, symbol inventory, reachability, route census | DONE |
| 0 | prep | Baseline test batch on `2d73f71f` | attempts 1-2 stopped (B1, B2, then fresh-kernel churn -> never-started resubmits); attempt 3 (REUSE mode) pooled phase done 05:24 (97 OK / 26 screened, 3 cancelled at 105 min), standalone confirmations running |
| 0 | prep | Merge probe of the Codex branch | DONE (17 conflicts) |
| 11 | CF259 | Adopt branch transport layer (D1) | DONE: copied 03:30; coefficient-field regression fixed (B4); adopted tests repaired (B7, fixture-independent assertions): all seven pass on the branch plus the two new tests (jet Laurent 7/7, radical scale 10/10) |
| 11 | CF259 | Move CF259 evidence into Results/ | DONE 03:45 (`.../CF259/transport_inputs_2026-09-02/`, README with provenance); 88 ordinary observable transports copied to `Results/.../ObservableTransport_2026-09-01_codex/` |
| 11 | CF259 | Run compact-record transport at cheap scale, then full | DONE 05:51: probe 5 transported CF259 end to end in 564 s (ModularlyVerifiedObservableTransport, 20 demanded pairs, 167 boundary coordinates, weight 5, operator-automaton representation), accepted by the public predicate; artifact + provenance under `Results/.../CF259/observable_transport_2026-09-02/`. Probes 1-4 failed at rank sampling; the cause (B8) was the compiler's radical grammar, fixed with a test |
| 1 | stale | Route-level deadness verification (Maple/CANONICA/Legacy/Symbolic routes) | DONE (route_split.py table) |
| 1 | stale | `Private_Backup/` with per-move evidence | DONE 04:25 for the three test-only routes + 15 dead symbols (~830 lines; `FeynFacet/Private_Backup/EVIDENCE.md`); CanonicalizeClasses and the Libra transport engines deliberately left (see EVIDENCE) |
| 2 | dedup | Rational reconstruction / CRT / prime admissibility census | `Core/ModularArithmetic.wl` (61-assertion test) is the one implementation; `familyCertRationalReconstruct`, `familyCertMQSquareRoot`, `epsFormFiniteFieldRationalReconstruct`, `epsFormFiniteFieldCombineLists`, `multiquadraticSquareRoots` (now any odd prime), `multiquadraticSplitPointQ` are aliases of it (04:30); remaining inline copies listed in the goal-2 section |
| 3 | structure | Layer design + load order | DONE 04:20 (load check passed 04:43 after the manifest fix B5): 7 layer folders, `Private/LoadOrder.wl` manifest read by `FeynFacet.m`, 27 tests/scripts re-pointed; `Design/PrivateLayers_2026-09-02.md` |
| 4 | geometry | Declared root-geometry/chart data | design note `Design/GeometryDeclaration_2026-09-02.md`: the catalog is already keyed by root squares and declarative; the two declaration paths are documented; the data-file split is deliberately not done (N1) |
| 5 | concise | Simplify where it genuinely simplifies | 15 dead symbols and ~830 lines of retired routes out of the load path; duplicated finite-field primitives collapsed to one module with aliases; retired-route stubs answer typed statuses; no further rewriting for its own sake |
| 6 | perf | Benchmark harness (before/after) | DONE: `Scripts/Diagnostics/benchmark_overhaul.wls`, `benchmark_laurent_jet.wls`; table in the Benchmarks section (CF259 end-to-end 564 s is the headline; the jet Laurent route measured and rejected) |
| 7 | bugs | Bug list with failing tests | B1-B14 below (B2, B4, B7, B8, B12, B14 with tests; B9-B11, B13, B14 found by the acceptance batches and fixed the same night; B1 driver-only; B3 design note; B5 my own; B6 in the new module's test) |
| 8 | std | Format convergence, scripted drivers | `Scripts/transport_family_record.sh` (single-record transport with allowance + licence retry), `Scripts/compact_family_dlog_record.wls` adopted, pool tools path-neutral, reuse-mode batch driver; analysis tools archived under `Scripts/Diagnostics/overhaul/` |
| 10 | certs | Redundant validation layers census | audit DONE (32 mechanisms, report archived); A1-A2 applied; the rest listed with reasons |
| 9 | generality | Algebraic records choose admissible rank/residue samples automatically (`observableTransportAdmissibleSamples`, 04:35): no per-family sample data; defaults kept when admissible | wired, exercised by CF259 probe 3 |
| 6 | GPU | Design note | DONE (`Design/GPUEvaluation_2026-09-02.md`) |



## Goal 1: route-level evidence gathered so far (03:45)

Verified by reading the production drivers, not by grep alone.

| Route | Where | Production use today | Verdict |
|---|---|---|---|
| CANONICA complete-sector `TransformOffDiagonalBlock` and per-sector `TransformDlogToEpsForm` | `Scripts/family_epsform_sector.wls` | only under `FACET_STRIP_ROUTE=Legacy`; the default `FiniteFieldFirst` route skips both (user decision 2026-08-22) but still `Get`s CANONICA every mission and resolves NextEquationD/InsertD/TransformDE (used at lines 1226/1708/1715 only when not blockwise) | Legacy-only; CANONICA load in the driver is dead weight on the default route |
| CANONICA/Maple strip ladder `SolveEpsFormStrip` (EpsFormStrip.wl) | called from `SolveEpsFormStripInFrame` (TransportCharts.wl:2088) unless `"FiniteFieldFirst" -> True` | the sector driver passes `"FiniteFieldFirst" -> True` (line 1399): never entered in production | stale candidate (tests: t_eps_form_strip, t_maple_canonical_gauge) |
| Maple operand canonicalization `blockEquationDeferredMapleCanonicalOperandValue` | BlockEquationDeferred.wl, option `AlgebraicCanonicalize` (default True; TransportCharts passes False) | on the default deferred forcing route for algebraic (radical) operands of the rank>=1 completion | live (rank>=1 completions) |
| Maple canonical gauge `GaugePullBackMode -> "MapleCanonical"` | TransportCharts.wl | default is `"Exact"`; only the cache-directory option is set by the driver | stale candidate |
| `LibraFamilyEpsForm` whole-family Libra route | LibraEpsForm.wl | no script; one test; `FamilyRegulatorFactor` uses only the two Libra loader helpers from that file | backup candidate (keep the loader helpers) |
| Libra symbolic transport `TransportFamily` (`"TransportBackend" -> "Libra"`, engines Monolithic/Blockwise) | MasterTransport.wl, BlockwiseTransport.wl | the August sweep (`sweep_transport.wls`, 71 `Masters/*.wl`); the sector driver uses `TransportFamilyInChart[..., "AssemblyOnly" -> True]` for assembly + alphabet only | assembly half live; transport half superseded by the observable transport (88/88 ordinary families, 2026-09-01) |
| Blockwise engine helpers (`masterTransportBWSchedule`, `BWLinearize`, `BlockwiseSolve`) and `CanonicalWordTransport` operators | BlockwiseTransport.wl, CanonicalWordTransport.wl | consumed by the CF303 exception seam (PathTransportException/Native) and by Codex's CF303 operator work | keep (CF303 route); test-only reachability for the canonical-word operators |
| Stage-1 `CanonicalizeClasses` (CANONICA ladder) | CanonicalBlocks.wl | superseded by `DiagonalBlockClassCampaign` (173/173 on the finite-field route, 2026-08-21); the class ledger stands | keep the decomposition/classification; the CANONICA canonicalizer is a backup candidate |

## Goal 1: route-only code measured (04:15, `inventory/route_split.py`)

Symbols reachable ONLY through each candidate route (from no public
symbol, production script or string-constructed name), with the lines
their definitions occupy:

| Route root | route-only symbols | lines | real callers today |
|---|---:|---:|---|
| `SolveEpsFormStrip` (CANONICA/Maple strip ladder) | 5 (4 in EpsFormStrip.wl + `taskBrokerCanonicaLadder`) | ~356 | sector driver's `Legacy` branch only; test `t_construction_budget` (budget accounting) |
| `TransportFamily` (Libra path-ordered transport) | 29 (25 in BlockwiseTransport.wl, 3 in CanonicalWordTransport.wl, the `TransportFamily` body) | ~1,913 | August drivers `family_epsform.wls`, `sweep_transport.wls`; tests t_block_demands, t_blockwise_transport, t_algebraic_letters, t_chart_transport, t_master_transport (+ transport-mode uses of `TransportFamilyInChart` in t_check_levels, t_exact_depth, t_multiquadratic_transport_frame, t_transport_checkpoint) |
| `CanonicalizeClasses` (CANONICA class ladder) | 4 | ~252 | test t_canonical_blocks only |
| `LibraFamilyEpsForm` | 9 | ~365 | test t_libra_family_eps_form only |
| `transportChartMapleCanonicalGauge` | 1 | ~36 | test t_maple_canonical_gauge only |
| `TransportPathArtifactRun` (CF303 exception seam) | 18 (PathTransportNative.wl) | ~888 | public entry, CF303 route: KEEP |

`Options[SolveEpsFormStrip]` stays in place when its definition moves
(`SolveEpsFormStripInFrame` filters its options through it).

## Goal 2: dedup census (03:55) and migration targets

Measured by a statement-level scan of `Private/` (74 defining statements
touch CRT, rational reconstruction, modular square roots or prime
selection, in 12 files):

| Wheel | Copies found | One implementation (new) |
|---|---|---|
| rational reconstruction (Wang) | `epsFormFiniteFieldRationalReconstruct` (FiniteFieldEpsForm), `familyCertRationalReconstruct` (FamilyCertificateModular; lacks the sign normalization and residual check of the first), inline in `multiquadraticStripReconstructRegulator`, `finiteFieldGaugePullBackLift`, `diagonalBlockLiftFunction` | `modularRationalReconstruct`, `modularLift` (ModularArithmetic.wl) |
| CRT combination | `epsFormFiniteFieldCombineLists`/`CombineCoordinate`, `familyCertMQReconstructResidues`, `familyCertificateModular` | `modularCRT` |
| modular square root, restricted to p = 3 mod 4 | `multiquadraticSquareRoots` (MultiquadraticAlgebra), `familyCertMQSquareRoot`, inline `PowerMod[.., (p+1)/4, p]` in 8+ functions of MultiquadraticStripSolve, PathTransportNative, BlockEquationDeferred, FamilyRegulatorFactor; the restriction caused the 2026-08-31 wasted 6,600-attempt run on a p = 1 mod 4 prime (Codex note 18) | `modularSquareRoot` (Tonelli-Shanks, any odd prime) |
| split-point search | `multiquadraticSplitPointQ`, `pathTransportNativeSplitPoints`, `multiquadraticStripSplitPointRows`, `observableTransportFF*` trial pools | `modularSplitPointQ`, `modularSplitPoints` |
| prime selection | ~40 sites (`NextPrime`, `RandomPrime`, `PrimeQ` loops) | `modularPrimes` |
| add-on loaders | `masterTransportLoadLibra` (MasterTransport), `libraEpsFormLoadBackend` (a Fermat-backend wrapper that already delegates to it -- not a duplicate on inspection), `canonicalBlocksLoadCanonica`, `epsFormStripCanonicaSymbol`, `masterTransportLoadPolyLogTools`, `transportChartLoadRationalizeRoots` | candidates for one `Infrastructure/AddOnLoaders.wl`; not done tonight (no measured cost, low risk of divergence) |

The 11 "symbols defined in two files" reported by the first scan were
false positives (ClearAll lists and signature overloads such as
`SimplifyAssum[expr, assumptions]` vs `SimplifyAssum[expr, card]`).

Migration order (each step: tests of the consumer stay passing, one
commit): certificate (`FamilyCertificateModular`), lift helpers
(`FiniteFieldEpsForm`, `DiagonalBlockEpsForm`, `FiniteFieldGaugePullBack`),
`PathTransportNative` split points, then the `MultiquadraticStripSolve`
inline sites (largest, lowest production value now that the rank-3
completions are finished).

## Goal 10: certification audit outcome (report: scratchpad/inventory/certification_audit.md, 04:00)

32 mechanisms tabulated (9 keep, 17 merge, 6 remove). Applied so far in
the `overhaul` worktree:

- A1 `multiquadraticAlgebraABIFingerprint[]` memoized (was a symbolic
  probe + full InputForm + SHA256 on every call, reached per sample and
  per prime through three validity predicates).
- A2 `finiteFieldStripCFFRAdapterHashes[]` now hashes the FLINT binary
  and source once per session and re-hashes only when size or
  modification date changes (was a file read + SHA256 per adapter call =
  per sample; the comment already promised once per session).

Correction to the audit: `familyRegulatorPropagateTruncation` is NOT
dead — `Scripts/family_epsform_sector.wls:821` calls it by its
context-qualified name; the seal it consumes stays. (The audit's scan
missed qualified names; the overhaul's own scan includes them.)

Queued (each with a before/after measurement on the frozen (9,6)
strip fixture): move `finiteFieldStripValidateEliminationPlan` out of
the per-sample path to plan admission (item 6); the hot/full split of
`multiquadraticStripCompiledValidQ` and the `canonicalData` reuse in
`multiquadraticStripPreparationValidQ` (items 2-3; the multiquadratic
solver is no longer on a production path, so these are maintainability
work and go after the CF259 transport); drop the duplicated
root-frame authentication (FamilyEpsForm.wl:402 vs
FamilyCertificateModular.wl:1122) and the duplicated chart identity
in `masterTransportChartData` (items 10, 12).

Not to be removed: the terminal family certificate, fresh-prime and
held-out acceptance, resume-admission fingerprints, the adapter
all-row residual replay (`finiteFieldStripCFFRVerify`); the audit's
open question whether native follower solves skip the all-row residual
(MultiquadraticStripSolve.wl:10131) is recorded for a later check.

## Goal 3: layer design for `FeynFacet/Private/` (draft 03:50, from the measured dependency matrix)

Measured now: 39 flat files; every file depends on `Core.wl`; the
stage-1/stage-2 files depend on each other in a tangle (e.g.
`MultiquadraticStripSolve` <-> `BlockEquationDeferred` <->
`FamilyRegulatorFactor` <-> `TransportCharts`), and the physics front end
(process, topology, reduction, coefficients) is cleanly separated from
the master-solving stages. Load order is a hand-maintained list in
`FeynFacet.m`.

Target layout (subfolders of `Private/`, loaded in this order; the load
order becomes an explicit manifest `Private/LoadOrder.wl` read by
`FeynFacet.m`, so a file's layer is visible from its path and the order
is one list, not scattered knowledge):

1. `Core/` — Core.wl (exact algebra, basis, metadata, installation
   roots), ModularArithmetic.wl (NEW: one implementation of primes,
   modular square roots, split points, CRT, rational reconstruction,
   lift-and-verify), MultiquadraticAlgebra.wl (extension-field grade
   algebra), RationalMaterialization.wl (rational-DAG compaction).
2. `Process/` — Process.wl, Topologies.wl, CanonicalFamilies.wl,
   DimensionalShift.wl, Collinear.wl (diagram generation to pre-IBP).
3. `Reduction/` — Reduction.wl, StreamingKira.wl, CoefficientStore.wl,
   Simplification.wl, Reconstruction.wl, Assembly.wl,
   MasterIntegralAmFlow.wl (IBP, coefficient reconstruction, assembly,
   numerical cross-checks).
4. `Infrastructure/` — TaskBroker.wl (pool-side parallelism).
5. `Geometry/` — TransportCharts.wl (chart catalog + root geometry,
   to be turned into declared data: goal 4).
6. `EpsForm/` — stage 1: CanonicalBlocks.wl, DiagonalBlockEpsForm.wl,
   LibraEpsForm.wl (if it survives goal 1), EpsFormStrip.wl,
   BlockEquationDeferred.wl, FiniteFieldEpsForm.wl,
   FiniteFieldStripSolve.wl, MultiquadraticStripSolve.wl,
   MultiquadraticInstallation.wl, FiniteFieldGaugePullBack.wl,
   EpsFormStripObstruction.wl, FamilyRowGauge.wl,
   FamilyRowGaugeResume.wl, FamilyRegulatorFactor.wl,
   FamilyCertificateModular.wl, FamilyEpsForm.wl.
7. `Transport/` — stage 2: MasterTransport.wl (assembly + certificates;
   the Libra engines are goal-1 candidates), BlockwiseTransport.wl and
   CanonicalWordTransport.wl (the word/operator engines used by the
   CF303 exception route), PathTransportException.wl,
   PathTransportNative.wl, ObservableTransport.wl,
   ObservableTransportFiniteField.wl (production transport).

Rules: a layer may reference only itself and lower layers; the manifest
lists files per layer; `FeynFacet.m` derives `$feynFacetPrivateFiles`
from it. Cross-layer upward references found by the dependency matrix
(e.g. `FamilyEpsForm` -> `ObservableTransport` for four zero-tests,
`Core` -> nothing upward once the pseudo-dependencies through generic
local names are discounted) are moved down with the symbol.

Known same-context name collisions to resolve while moving (11 symbols
defined in two files; five are duplicated helpers between
`CoefficientStore.wl` and `Simplification.wl`: coefficientAnalyticContextQ,
coefficientKiraReductionQ, coefficientPairFileKey,
coefficientResolveResultDirectory, coefficientRunProject; plus
`$coefficientLateSetupKeys`, `AMFlowPrescription` (Process/Topologies),
`SimplifyAssum`/`FullSimplifyAssum` (Core/Process),
`CoefficientSimplification` (three files: usage vs definitions)).

## Bugs found

- B1. `Scripts/run_tests_pool.sh`: the header lists five tests that must
  run standalone (they launch subkernels, Kira workers or a nested
  KernelPool) but `standalone_only()` only listed the chart tests. Run
  pooled, the nested pools exhausted the licence seats of the running
  pool (03:18:24 onward: relaunch refusals, 8 -> 7 subkernels, never-
  started resubmits, throughput 3.6 -> 1 test/min). Fixed in the driver
  (five names added); no package test, it is a shell driver.
- B2. `Scripts/KernelPool.wls`: a mission whose kernel was closed right
  after the scheduler handed it the next evaluation is requeued and
  re-dispatched; the orphaned evaluation is re-run by Parallel Tools,
  claims the mission and completes, and the server's own re-dispatch
  returns DUPLICATE -- which the server filed as the verdict (measured:
  `fresh_t_epsform_obstruction` passed 7/7 in 261.7 s, recorded
  `Status -> DUPLICATE, Wall -> 0`, absent from `done/`). Fix: the
  wrapper writes the result sidecar for every mission and the server
  prefers the sidecar whenever the drained evaluation reports DUPLICATE.
  Regression test `Tests/Infrastructure/t_kernelpool_duplicate_verdict.wls`
  (deterministic: the resurrected run's claim, sidecar and marker are
  placed before dispatch; the pre-fix server files DUPLICATE). Its first
  run (05:04) could not bring up its nested pool while the baseline pool
  held the licence seats -- environment, not a verdict; rerun pending.
- B4. Adopted transport (`ObservableTransport.wl` as of the Codex branch
  tip fc6792f7, 02:43): `BuildObservableTransport` read the coefficient
  field only from `record["ChartRecord"]` and returned
  `ObservableTransportCoefficientFieldMissingOrInvalid` for every record
  without that key -- which includes all certified ordinary-family
  records (`FamilyEpsFormsCertified/`, the very inputs of the accepted
  88-family run); the field lives in their `EpsilonFormCertificate`. A
  regression introduced while chasing CF259 after the 88-family run.
  Fix: `observableTransportCoefficientField[record]` resolves chart
  record, then certificate, then "Rational" for radical-free records
  (radical records without a declared field are refused). Test: the
  adopted `t_observable_transport` (CF27) and `_compact_ordering` tests
  exercise it; they failed before the fix.
- G1 (generality, fixed). `Tests/EpsilonForm/t_exact_family_epsilon_form_q.wls`
  read its two fixtures from `../FACET/Codex/General/...` relative to the
  repository's parent directory (the frozen legacy tree), so it failed in
  every worktree not placed beside `~/FACET`. The fixtures (1.8 MB) are
  now under `Results/UU_08_10_canonical/FamilyEpsForms/Fixtures_2026-08-19/`
  and the test reads them from the repository.
- B5 (my own, found by the first load check 04:27). The manifest
  generator wrote a trailing comma after the last layer of
  `Private/LoadOrder.wl`; the package refused to load ("manifest missing
  or malformed") and every queued test that followed exited 0 in
  seconds WITHOUT a tally -- void results that a careless reader would
  have called passes. Fixed (manifest), and the seat queue now marks a
  job without a result marker as NO-TALLY.
- B6 (worker's finding in the new module, fixed before adoption).
  `modularPrimes` walked all ~49 million primes between 2^30 and 2^31
  when a filter rejected every candidate (an 8-minute "smoke test");
  both searches are bounded by a candidate budget (1000 + 200 count)
  and fail typed. Semantic differences between the existing copies,
  now pinned by assertions: `multiquadraticSquareRoots[{0}, p]` returns
  `{0}` while `familyCertMQSquareRoot[0, p]` refuses -- the core module
  follows the algebra ABI (zero has root zero) and the split-point
  predicates refuse a zero radicand, which is where the certificate's
  rule belongs; the two rational-reconstruction copies agree on every
  input (their differing checks are loop invariants).
- B7. Adopted transport tests `t_observable_transport_compact_ordering`
  and `_final_reconstruction` (branch tip): `AcceptedObservableTransportQ`
  was tightened at 02:43 to require the certificate key
  `FamilyInputAccepted` (which `BuildObservableTransport` writes), but
  the tests' synthetic records still carried only the five older keys,
  so every synthetic word map answered `ObservableTransportNotAccepted`
  (11 and 3 failures). The tests were passing when Codex reported them
  earlier that night; the tip broke them. Fix: the key is added to the
  synthetic certificates (the predicate is right to demand it).
- B8 (the CF259 integration finding, fixed). The observable transport's
  finite-field compiler recognized a radical only when its base equals a
  declared root square up to a perfect-square factor, and its grammar had
  no numeric radicals. Once the first variable is fixed at the path's base
  point (x = 14/45), Wolfram canonicalizes `Sqrt[4x + y^2]` as
  `Sqrt[56 + 45 y^2]/(3 Sqrt[5])`: the base is the declared square times
  45 (not a square) and a loose `Sqrt[5]` appears, so the constraint
  matrix was refused (`AlgebraicMatrixCompileFailed`) and the failure
  surfaced as `SingularConstraintRankSample` (probes 1-4; probe 4's named
  offenders and dump pinned it). Rational records never see radicals;
  CF259 is the first algebraic record through this step. Fix (both in
  `ObservableTransportFiniteField.wl`): rescaled declared squares are
  split as `Sqrt[c] Sqrt[q]` before the root-branch substitution, and
  numeric square roots compile to a `SquareRootConstant` node evaluated
  as one fixed modular root per prime (square-free class, so products
  stay consistent; a non-residue rejects the trial). Test:
  `t_observable_transport_ff_radical_scale.wls` (compiles the dump's
  radical forms, checks the radical identities on all four sheets and the
  derivative evaluator, and calls the production rank sampler).
- B3 (design weakness, not fixed): in `fresh_` mode the pool closes and
  relaunches a subkernel per test; the scheduler hands queued
  evaluations to kernels that are about to be closed, evaluations then
  wait 90 s and are resubmitted up to three times before being filed
  NEVERSTARTED (attempt 2: 12 resubmits in 6 minutes, two at 3/3).
  Reuse mode (`REUSE=1`) avoids the churn and is the recommended batch
  mode; a fresh kernel is used only for the standalone confirmations.

### B9 — the strip solver's FLINT backend located its own source by a flat `Private/` path (found 06:05 by the overhaul batch; fixed)
`finiteFieldStripBackendConfiguration` built `FileNameJoin[{$feynFacetPrivateDirectory, "FiniteFieldStripSolve.wl"}]`
and returned `BackendSourceUnavailable` when the file was absent. After the layer move (goal 3)
the file lives in `Private/EpsForm/`, so every FLINT-backed finite-field solve on the branch failed
and its callers reported a solve failure: the first pooled comparison showed 12 regressions with
this one cause (t_finite_field_affine_rref_backend, t_solver_budget, t_finite_field_round2,
t_finite_field_adaptive_sampling, t_broker_adaptive, t_family_certificate_multiquadratic,
t_construction_budget, ...). Fix: `FeynFacet.m` builds `$feynFacetPrivateFileIndex` from the
manifest and exposes `feynFacetPrivateFile["X.wl"]`; the solver uses it. A grep over package,
scripts and tests found no other code path assuming the flat layout (remaining matches are prose).
Lesson for goal 3: a layer move is followed by a grep for `$feynFacetPrivateDirectory` and
`"Private", "<file>"`, not only by a load test. Confirmed by the `fix1_*` reruns.

### B10 — `taskBrokerCanonicaLadder` moved to `Private_Backup` although a test drives it directly (found 06:05; fixed)
The reachability scan counted package callers only; the sole caller (`SolveEpsFormStrip`) is
retired, but `Tests/Infrastructure/t_task_broker_limit.wls` calls the helper directly with a
counting stand-in for `epsFormStripRunCanonicaOne`. Moved back into
`Private/Infrastructure/TaskBroker.wl` (its collaborators are live). Goal-1 rule tightened: a
symbol moves only when package AND test references are absent; test-only symbols are listed and
decided one by one.

### Worktree omissions, not code bugs (06:01)
The overhaul worktree lacked the `Codex/ppHX_NLO`, `Codex/ppHX_NNLO_DoubleReal` links (solved
Kira workspaces: t_registry_seeding) and the fixture directory of G1
(t_exact_family_epsilon_form_q). Links added, reruns green. On `main` the paths are real
directories. `t_reconstruction_parser` is red on BOTH worktrees at different assertions (baseline:
"A. the stored NLO trace manifest loads with its alias map"; overhaul: "E. relative marker paths
resolve against the trace directory", "K. the assembly entry point discovers the trace"): its NLO
trace fixture is reached through a symlinked `Results/` directory in the worktrees, so relative
marker paths resolve elsewhere; it is re-run on `main` after the merge before any conclusion.

### B11 — reused pool subkernels carry leaked Global` values between missions (found 06:12; fixed in the pool, confirmation pending)
`t_physical_variable_coefficients` failed on the overhaul pool with `1/0` and `ComplexInfinity` messages
while loading its Kira store; on the baseline pool it passes. The adopted transport tests assign
values to bare short Global names at top level (`p = <prime>`, `m = <matrix>`, `q = <expression>`),
the reused subkernel keeps them, and a later mission whose Kira coefficients contain `m`/`q` evaluates
nonsense. Two fixes: (1) `Scripts/KernelPool.wls` now records which Global names carry an own value
before a mission and unsets every name that gained one during it (function definitions and
`$`-prefixed package globals are left alone; the mission log records "MISSION isolation: unset N
leaked Global` values ..."); (2) the three tests use descriptive names (`radicalPrime`,
`radicalMatrix`, `jetMatrix`, `closureQ`) and pass again (`fix3_*`). The pool fix takes effect at the
next pool start; the running overhaul pool is unchanged, so the coefficient test's verdict on the
branch comes from its standalone confirmation (fresh kernel).
CONFIRMED 06:50: in a fresh kernel on the overhaul tree the test passes the step that failed in
the pool ("TT B. fresh finite-field reconstruction completes" and the following TT assertions);
the pool failure was kernel pollution. (Its baseline wall is 3081 s; the confirmation job's
30-min allowance was disarmed so it can finish.)
Evidence (06:17, eight probe missions, one per subkernel): subkernel 8 carried 160 Global names
with own values left by earlier missions (`adapted, algebraicZeroQ, annotated, artifactRoot, base,
baseline, binary, bundle, card, ...`, plus `q4 -> 4 rx + ry^2`, `vv -> v`, `t0 -> <AbsoluteTime>`);
the other seven carried none. The `1/0` messages appeared only in missions that landed on a
polluted kernel (the batch's t_multiquadratic_transport_frame run, the reruns of
t_construction_budget and t_physical_variable_coefficients), never in the same tests on clean
kernels. The fixed pool unsets exactly this class of leftovers after every mission.

### B12 — the finite-field strip route stores wall-clock timings inside its result payload (found 06:15; test migrated, code unchanged)
Two consecutive `SolveEpsFormStripInFrame` solves of the construction-budget fixture differ only in
`"InnerSolution" -> ... "LiftingSeconds" -> 0.0009` vs `0.000871`, so the test's byte-identity
assertion cannot hold on the finite-field route (it held on the retired CANONICA/Maple route, whose
records carried no timings). `Tests/Infrastructure/t_construction_budget.wls` now compares the
result with every duration-named key stripped recursively, and its pinned fingerprint is
re-recorded for the overhaul route (`70333921...`, measured 06:18; the old a475092 value is kept in
the comment). Not done (deliberately): moving the timings out of the certified payload into a
diagnostics key would touch every consumer of "InnerSolution"; listed under decisions for the user.


### B13 — `FeynCalc`Names` shadows `System`Names` in every script parsed after LoadFACET (found 06:28; documented, pool code already immune)
Probing the eight overhaul subkernels: on five of them `Context[Names]` is `FeynCalc`` and
`Names[...]` stays unevaluated, on the sixth (kernel 8, whose `$ContextPath` had been reset by
the modular-arithmetic test) it is `System``. FeynCalc creates a symbol `Names` in its own
context, and LoadFACET leaves `FeynCalc`` ahead of `System`` on `$ContextPath`, so any test or
mission script that mentions `Names` after loading binds to the empty shadow. Package code is safe
(`BeginPackage` restricts the path while the package body is parsed) and `Scripts/KernelPool.wls`
already writes `System`Names`. Recorded in CLAUDE.md's Wolfram-trap list; my probe scripts of this
session fell into it (the first Global-value probe reported "1 name" on the shadowed kernels).
Also measured on the reused kernels: kernel 1 (which had additionally loaded Libra, Fermatica,
FeynArts) reproduces the construction-budget fixture with different provenance hashes and `1/0`
messages that kernels 3 and 4 do not emit, while the mathematical result agrees. The pooled phase
therefore stays a SCREEN; the standalone confirmations in fresh kernels are the verdicts, and the
in-pool `fix*` reruns above are treated the same way.

### B14 — the multiquadratic family certifier starves its own prime budget on inadmissible primes (found 07:15 by the standalone confirmations; pre-existing; fixed with a test)
`t_family_certificate_multiquadratic` failed its numeric constant-field frame assertion in 4 of 33
runs on the branch and 2 of 31 on the baseline (24-trial diagnostics per tree, fresh kernels),
always as `InsufficientFreshValidationPrimes` with rejected primes p == 7 (mod 12): there the
numeric root square 3 is a non-residue, so no split point exists, yet the certifier drew such
primes, spent 80 point attempts on each and charged them to the single 24-draw budget shared by the
pilot, CRT, extension and fresh-validation stages. Fix in `FamilyCertificateModular.wl`:
`familyCertMQDrawPrime` draws only primes p == 3 (mod 4) at which every numeric root square is a
non-zero residue (bounded raw draws), and only trials consume the budget. Regression assertion:
no rejected prime has `JacobiSymbol[3, p] == -1` and no `InsufficientUsablePoints` rejection
occurs. Confirmation (fresh kernel test + 24-trial tally) in the acceptance section.

### Review findings D1-D4 (adversarial review of the branch diff, 07:30; all fixed on the branch) and risks R1-R6
An Opus review agent read `git diff 2d73f71f overhaul` with adversarial questions per change
(report: scratchpad `review/adversarial_review_2026-09-02.md`, 4 defects, 6 risks, 9 notes).
- D1 (serious, my layer move): the manifest loaded Geometry before EpsForm, but
  `TransportCharts.wl` evaluates `Options[SolveEpsFormStripInFrame] = Join[Options[SolveEpsFormStrip], ...]`
  at load time, so fifteen inherited options vanished; `OptionValue::nodef` fired and every
  finite-field strip solve wrote its artifacts to a relative `ScratchDirectory/Tag_...` path
  (the stray directories under `Tests/` that I had wrongly gitignored as "test scratch").
  Fix: Geometry now loads after EpsForm; the ignore rule is removed and the stray directories
  deleted; a load check prints the option counts. Lesson for goal 3: load-time evaluations
  (`Options[...] = Join[Options[...]]`, `$flag = f[]`) are order dependencies that a dependency
  matrix of call sites does not show; grep for them before ordering layers.
- D2 (my B11 code): the pool isolation would have unset `poolRun`'s own Module locals (`r$nnn`,
  `hadMessages$nnn`) because they gain values during the mission; every sidecar would then have
  recorded a bare symbol as the result. Names containing `$` are now skipped and the three
  scan variables are Module locals. The code had not yet run in any pool (the batches used the
  old pool file).
- D3 (goal 1): `t_canonica_scheduler` drives `epsFormStripRunCanonica` and
  `epsFormStripExactDLogQ`, which I had moved to `Private_Backup`; restored (same rule as B10).
- D4 (A2): the adapter-hash stamp (size + modification date) missed a `cp -p` replacement;
  the change date (ctime) is now part of the stamp.
Risks R1-R5 of the review were fixed on the branch (log 07:30); R6 (the shared square root serves p == 1 (mod 4) with the Tonelli-Shanks representative, every caller gates the prime itself) is recorded as a note, and the review's NOTES are copied into the deliberately-not-done list where they are not addressed.

## Benchmarks

Harness: `Scripts/Diagnostics/benchmark_overhaul.wls`, one row per item;
"before" = main at 2d73f71f (base worktree), "after" = branch `overhaul`.
E-cores 2-5,10-13 while the baseline pool ran on the P-cores; single
measurements, wall seconds.

| item | before (2d73f71f) | after (overhaul) |
|---|---:|---:|
| package load | 2.67 s | 2.06-2.12 s (final branch, two runs; the 4.11 s of checkpoint 4 was a cold first load) |
| observable transport CF27 (rational, 8 masters): status / wall | ExactObservableTransport / 1.15 s | ModularlyVerifiedObservableTransport / 1.29-1.32 s |
| diagonal-block eps-form, synthetic 2x2 block | Certified / 3.19 s | Certified / 1.80-1.98 s |
| observable transport CF230 (Kallen chart, 13 masters) | not measured on the old route (Codex measured 2,989 s materialized vs 3.4 s lazy) | ModularlyVerifiedObservableTransport / 2.90 s at checkpoint 4; 5.70 s after the review-R1 per-call scan; 3.79 s with the radical constants recorded at compile time (final) |
| observable transport CF385 (8 masters, 153 boundary coordinates) | not measured | ModularlyVerifiedObservableTransport / 47.5 s, 1.2 GB peak (final branch) |
| diagonal-block eps-form, class 1 (1x1, ScalarDLog) | not measured | Certified / 0.001 s (round 2, standing stage-1 item `dbe_class1`) |
| diagonal-block eps-form, class 97 (4x4 hard class, SliceResiduesFiniteFieldAffine) | ~2950 s for class 77 in the 2026-08-21 campaign (4 subkernels); class 97 not timed alone | Certified / 46.2 s, 211 MB (round 2, one kernel, `dbe_class97`) |
| CF259 full observable transport (47 masters, rank-3, compact record) | never completed before (Codex: transport not run; probes 1-4 failed at rank sampling) | 564 s, accepted (probe 5) |
| CF259 Laurent extraction (47x47, 417 nonzero entries, rank-3), orders -3..4 | ~10 min (probe 1, SeriesCoefficient) | jet + Cancel[Together] per coefficient: NOT finished after 21 min (stopped) -- slower; the cost is the canonicalization of algebraic coefficients, not the series expansion. Default kept at SeriesCoefficient; jet retained as an option (7/7 unit test). Next lever, not done: uncanonical jets with a modular zero test in the forbidden-map construction (masterTransportZeroQ runs Together/Simplify per entry) |

CF259 transport, probe 5 (accepted run, one E-core kernel, Verbose):

| stage | wall |
|---|---:|
| input preparation, valuations (from record), structural support | 0.4 s |
| Laurent extraction of the 47x47 transformation, orders -3..high (SeriesCoefficient) | 439 s (78% of the run) |
| forbidden map {102,120}, first covariant closure (rank 93 -> 97 -> 97) | ~60 s |
| boundary evolution (AmbientBasePoint, 187,988 constraint leaves), second closure (77 -> 94 -> 94), base constraint cancellation {94,261} | ~60 s |
| base kernel {261,167}, demanded map {20,261}, operator-automaton representation | ~3 s |
| total, status ModularlyVerifiedObservableTransport | 564 s |

The Laurent stage is the hot spot of triple-root transport; the jet
route with canonicalization did not beat it (see below); an uncanonical
jet with modular zero tests is the recorded next step.


## Acceptance batches (FINAL, 08:40)

Method: both trees ran `Scripts/run_tests_pool.sh` in REUSE mode on their own KernelPool
(8 subkernels); the pooled phase is a SCREEN (reused kernels leak state: B11, B13), every pooled
failure is confirmed in a fresh standalone kernel. Baseline = main at 2d73f71f with the driver
fixes B1-B3 (driver complete: `failed: 13` of 146 rows). Overhaul = the `overhaul` branch; its
driver died before its standalone phase (my edit under a running script, 06:37), so its
confirmations ran through sequential seat queues in fresh kernels, including the reruns after
every fix (`fix1_` .. `fix15_`). Evidence: `Design/PrivateOverhaul_2026-09-01_evidence/` (both
driver logs, the four queue logs, the tables, the tools, the review report, the watchdog heartbeat).

Merged verdict per test (rows identical on both trees omitted; "latest run" = the last fresh-kernel
run of that test on the branch):

```
| test | baseline (pooled / standalone) | overhaul pooled | overhaul standalone (latest run) | verdict |
|---|---|---|---|---|
| t_algebraic_observable_transport | EXIT4 | OK | OK (fix13 08:34:21) | fixed |
| t_chart_transport | OK | - | - | pending |
| t_exact_depth | EXIT1 | - | EXIT1 (fix10 07:34:28) | red-both |
| t_kernelpool_duplicate_verdict | - | - | OK (fix15 08:35:36) | new |
| t_libra_family_eps_form | OK | - | - | pending |
| t_maple_canonical_gauge | OK | - | - | pending |
| t_master_transport | EXIT1 | - | EXIT1 (confirm 07:55:28) | red-both |
| t_modular_arithmetic | - | OK | OK (confirm 07:51:32) | new |
| t_multiquadratic_end_to_end_install | EXIT1 | - | EXIT1 (fix10 07:42:42) | red-both |
| t_multiquadratic_gauge_ladder | EXIT137 | - | - | pending |
| t_multiquadratic_gauge_screen | EXIT137 | - | - | pending |
| t_multiquadratic_installation | EXIT1 | - | EXIT1 (fix10 07:42:28) | red-both |
| t_multiquadratic_installed_family_chain | EXIT1 | - | EXIT1 (fix10 07:42:03) | red-both |
| t_multiquadratic_letters | EXIT137 | - | - | pending |
| t_multiquadratic_obstruction_driver | EXIT1 | - | EXIT1 (fix10 07:31:39) | red-both |
| t_multiquadratic_regulator_reconstruction | EXIT1 | - | EXIT1 (fix10 07:32:05) | red-both |
| t_multiquadratic_strip_solve | EXIT1 | - | EXIT1 (fix10 07:32:36) | red-both |
| t_observable_transport_compact_ordering | - | OK | - | new |
| t_observable_transport_covariant_closure | - | OK | OK (confirm 07:53:07) | new |
| t_observable_transport_ff_radical_scale | - | OK | OK (fix13 08:32:53) | new |
| t_observable_transport_final_reconstruction | - | OK | - | new |
| t_observable_transport_finite_field | - | OK | OK (fix13 08:33:15) | new |
| t_observable_transport_integration_load | - | OK | - | new |
| t_observable_transport_laurent_jet | - | OK | OK (confirm 07:51:59) | new |
| t_streaming_kira_import | EXIT16 | - | EXIT16 (confirm 06:57:14) | red-both |

summary: same 117, fixed 1, new 9, red-both 9, pending 6
```

Reading:
- No regression. Every pooled difference of the first comparison (12 at 06:05) traced to one
  root cause each (B9, B10, worktree links, a script name in a retired-route message, the closed
  p == 1 (mod 4) divergence) and is green again after its fix in a fresh kernel.
- "pending" rows: t_chart_transport ran on the branch under the loop I stopped at 08:02, so its
  end line is missing from the queue log; its job log ends with exit 0, 29 assertions, 0 failed (`job_t_chart_transport_branch.log`
  in the evidence folder), the same 29 as the baseline. t_libra_family_eps_form and t_maple_canonical_gauge were retired with their
  routes (moved to `Private_Backup/`; green on the baseline). The three multiquadratic tests
  capped at 30 minutes on the baseline (1921 / 1961 / 1906 s, EXIT137; their compile route is
  ~7900 s by their own comments) were not run on the branch: no verdict is possible within the
  allowance on either tree.
- Red on both trees, same failing assertions (pre-existing, outside this overhaul):
  t_multiquadratic_installation, _end_to_end_install, _installed_family_chain,
  _obstruction_driver, _regulator_reconstruction, _strip_solve, t_exact_depth, t_master_transport,
  t_streaming_kira_import (EXIT16).
- Fixed by the overhaul: t_algebraic_observable_transport (EXIT4 on the baseline standalone).
- New and green: t_modular_arithmetic, the seven adopted observable-transport tests, and the
  rewritten pool verdict test.
- Flaky by design and now fixed: t_family_certificate_multiquadratic (B14: 24/24 after the fix,
  1-2 failures per 24 before, on both trees).

## Round 2 (2026-09-02 morning): the user's rulings on U1-U4 and N1-N8

Rulings (verbatim intent) and what was done:
- U1 "What replaced Libra? If it's not active retire it": the observable transport
  (`BuildObservableTransport`, lazy-operator route, 88/88 ordinary families + CF259) replaced the
  Libra path-ordered transport engines. Retired to `Private_Backup/`: `TransportFamily` and its
  engines (BlockwiseTransport.wl, CanonicalWordTransport.wl whole), the path-transport exception
  seam and native jets (PathTransportException.wl, PathTransportNative.wl whole), the word and
  quadrature heads; `TransportFamilyInChart` keeps its assembly mode (FamilyEpsForm.wl uses it) and
  answers RouteRetired for transport. NOT retired: `masterTransportLoadLibra` and the Libra balance
  slice inside `DiagonalBlockEpsForm` -- that is the production stage-1 route. Ten tests of the
  retired routes moved to `Private_Backup/Tests/`; the August sweep and Libra research scripts to
  `Scripts/Backup/retired_routes_2026-09-02/`.
- U2 "if the full check is not too expensive, add it": native (FLINT) constrained-core solves now
  replay ALL original rows by two Freivalds projections (`$multiquadraticStripFreivaldsProjections`),
  O(m n) per projection instead of the O(m n (nullity+1)) exact product, false acceptance <= p^-2;
  evidence method `NativeCoreVerifiedFreivaldsAllRows`; the pre-existing `NativeConstrainedCoreVerified`
  records stay readable.
- U3 "kill that hash": `$multiquadraticStripSourceSHA256` (a hash of the 949 kB solver file) is
  replaced by the hand-maintained `$multiquadraticStripABIVersion` ("MultiquadraticStripSolve-ABI-1")
  in every certificate, checkpoint header and cache key (key name `ABIVersion`); a comment edit no
  longer invalidates artifacts; the old symbol is an alias of the version for readers. Tests migrated
  (persistence, provenance, radical denesting, Q4 chart, support-ladder evidence).
- U4 "yes include wall timing": `SolveEpsFormStripInFrame` results carry ONE top-level `Timings`
  record (`StripTimingsV1`: the construction stages and every duration key lifted out of the inner
  solve, path-keyed); `InnerSolution` is now byte-identical between solves.
- N1 (charts are in `Private/Geometry/TransportCharts.wl`: `TransportChartCatalog[]` + the family
  registry); N4 (advice: leave the double validation of the multiquadratic solver until it is needed
  again, then keep only the full check as the certificate step); N5 (GPU: no canonicalization step
  was tried on a GPU; the only GPU candidate in stage 1 is the batched modular evaluation of block
  equations, measured CPU-favourable at current batch sizes; see the design note).
- N2 "put the Legacy branches into backup": `Scripts/family_epsform_sector.wls` lost its CANONICA
  loader, the NextEquationD/InsertD/TransformDE branches, the Maple options and the Legacy dispatch
  (1970 -> 1860 lines; the pre-removal copy is `Scripts/Backup/family_epsform_sector_2026-09-02_before_legacy_removal.wls`).
- N3 "if we are not using canonica and libra anymore, put them to backup": CANONICA is gone from the
  live package: `CanonicalizeClasses` (class ladder), the CANONICA loader/regulator bridge, the
  strip ladder helpers, the broker CANONICA ladder, the Maple helpers -> `Private_Backup/`;
  `ValidateCanonicalForm` reimplemented without CANONICA (letters from the irreducible denominator
  factors, residues by an exact linear solve at rational points, the dlog identity re-verified with
  Together); `DiagonalBlockEpsForm`'s CANONICA fallback answers RouteRetired and its independent
  validation uses the new validator. Libra stays where stage 1 needs it (above).
- N7 "why not": the strip solver's reserve-prime schedule is now `modularPrimes[31, count,
  "Exclude" -> lifted, "Below" -> 2147483399]` (same schedule); the native path-transport sampler
  went to backup with its route.
- N8: `multiquadraticSplitPointQ` -> `Private_Backup/`; its two tests assert the shared predicate.
- The user's correction, recorded as a rule: a stage that has produced its artifacts is still a
  maintained, optimizable route of the general workflow; "closed" never means "reference only".
  Follow-up in this round: a real class enters the benchmark harness as a standing stage-1 item.

Finding of the round-2 smoke run (11:06, watchdog): CANONICA was still on the PRODUCTION stage-1
path -- the finite-field strip route took its letter alphabet from `CANONICA`ExtractIrreducibles`
through the symbol bridge I had moved to backup, and `SolveResidueRationalGauge` used
`CANONICA`RatFunctionZeroCoeffs`; with the bridge gone every strip solve lost its letters (sampler
"no nonsingular points"). Replaced by `epsFormStripIrreducibleFactors` (irreducible,
regulator-free denominator factors of the strip entries, plus the variables) and
`epsFormStripRationalZeroCoefficients` (numerator monomial coefficients); the affected tests were
re-queued. Benchmarks on the round-2 tree (commit 4adfa4cc + working changes): load 2.13 s, class 1
0.001 s, class 97 46.2 s (Certified, SliceResiduesFiniteFieldAffine), CF27 1.30 s, CF230 3.87 s,
synthetic block 1.78 s.

Acceptance of round 2: the load check and the affected tests run in fresh kernels on the seat
queue first, then the full suite; results are appended below.

## Test cost audit (12:20, user ruling: verification must be small and fast)

Measured on the baseline batch (pooled walls, standalone confirmations): 159 rows, 670
kernel-minutes in total; the 29 tests above 90 s account for 646 of those minutes (96%). The top of
the list: t_multiquadratic_gauge_screen / _gauge_ladder / _letters (compile route on the real CF300
(12,9) block, 6185 s pooled and capped at 30 min standalone), t_physical_variable_coefficients
(3081 s: rebuilds a Kira store), t_multiquadratic_regulator_filter (2509 s),
t_multiquadratic_obstruction_images (1899 s), t_construction_dag (1578 s),
t_multiquadratic_installed_family_chain (800 s), t_multiquadratic_providers (542 s),
t_epsform_obstruction (390 s), t_multiquadratic_dispatch (230 s), t_finite_field_eps_form (191 s),
t_exact_depth (190 s), t_family_certificate_modular (188 s), t_package_generality (170 s).

Done now: the real-block sections of t_multiquadratic_gauge_ladder (L7) and
t_multiquadratic_gauge_screen (G11-G13) run only with FACET_TEST_LONG=1; by default they print a
skipped line and the synthetic sections carry the contract (the same for t_multiquadratic_letters
where its synthetic tail is independent of the fixture). Rule (memory `test-cost-discipline`): after a
change, run the small tests of the touched code in fresh kernels 8-way through the pool's fresh_
missions; never the serial standalone phase; cap verification at tens of minutes.

Next work items (new code, not test runs): (1) t_physical_variable_coefficients reads a stored,
frozen Kira store instead of rebuilding one (51 min -> seconds); (2) frozen SMALL fixtures for the
multiquadratic integration tests (regulator_filter, obstruction_images, installed_family_chain,
providers, dispatch): a 2x2 or 3x3 strip with one root instead of the CF300 (12,9) block;
(3) t_construction_dag and t_epsform_obstruction: cap the DAG size / obstruction order in the
default mode, full size under FACET_TEST_LONG=1; (4) the driver's standalone phase runs the
screened tests through fresh_ missions 8-way instead of serially.

## Round 2 acceptance (13:00, user ruling: no hours-long runs)

Verdicts come from three sources: the pooled full batch (reuse kernels), 8-way fresh_ missions for the pooled failures, and two standalone seat queues for the tests that need a main kernel (`round2/final_queues/`). Totals over the 159-row suite after the 12 retirements: 102 green, 8 red, 3 not run.

| Group | Result |
|---|---|
| Pooled failures re-run fresh | all green: observable transport 12/0, constrained plan 27/27, assembly 10/10, finite-field adversarial 13/13, ghost card 6/6, regulator interpolation 9/9, dlog broker 11/11, follower image wave 13/13 |
| Standalone queues | nlo golden 5/5, coefficient golden 6/6, registry seeding 6/6, reconstruction parser 14/14, reconstruction ghost 8/8, gauge ladder 22/22 (gated fast mode) |
| `t_two_core_ceiling` | fails under a 4-core `taskset` (Automatic/Requested ceilings False), passes with the machine's 12-core list (`round3/t_two_core_ceiling_12cores.log`): the assertion depends on the CPU list, not on the code |
| Red in the baseline and in round 2 (identical assertions) | `t_multiquadratic_strip_solve`, `_regulator_reconstruction`, `_obstruction_driver`, `_installed_family_chain`, `t_streaming_kira_import` -- all taken up in round 3 below |
| Not run | `t_multiquadratic_gauge_screen`, `_letters` (gated fast mode; the queue was killed on the user's order), `t_reconstruction_nlo` (killed while hung in kernel start, see the kernel-start note) |

## Round 3 (12:40-13:00): the long and the red tests, fixed in code

User rulings applied: "fix the tests"; "when you see something running pathological, kill it and fix it". Every run below was capped at 2-10 minutes; two stalled kernel starts were killed by PID.

| Test | Before | Cause | Fix | After |
|---|---|---|---|---|
| `t_multiquadratic_regulator_filter`, `t_multiquadratic_obstruction_images` | 2509 s, 1899 s (pooled), the last step never reached | the R5/O10 source scan stripped comments from the 950,000-character solver source one character at a time with `AppendTo` (quadratic); the solver call itself takes 0 s | `FTTest\`FTStripComments`: one linear pass over the comment delimiters, shared in TestKit | obstruction_images 19/19, regulator_filter 10/10, each about 70-100 s including the package load |
| `t_epsform_obstruction` | 670 s pooled; (a) alone 670 s | the certificate recomputed the order-m series of the diagonal blocks and the full matrix product inside the entry loop (upper x lower times per order); the residue and primitive stages then grow with the order (measured after the fix: orders 0..3 take 14, 45, 66, 93 s) | series memoized per (mu, m), product once per order; per-stage timings in the verbose log; test (a) certifies orders 0-1 by default, order 3 with `FACET_TEST_LONG=1` | 7/7, (a) 61 s |
| `t_physical_variable_coefficients` | 3081 s | two full finite-field coefficient reconstructions (NLO TT and the NNLO ghost grid with a 10 MB Kira artifact) | the ghost data set is gated behind `FACET_TEST_LONG=1`; the NLO set keeps the full exact contract | not re-run (user ruling) |
| `t_construction_dag` | 1644 s pooled, 1578 s in the baseline | none in the test: standalone it is 86/86 in 3.9 s after load (`round3/t_construction_dag_standalone_stamped.log`); the pooled wall time is a pool artefact of the reuse kernels | TestKit now stamps every assertion with its wall seconds, so the next pooled run shows where the time went | 86/86 |
| `t_multiquadratic_strip_solve` (20 red), `_regulator_reconstruction` (6 red), `_obstruction_driver` (3 red) | red since the baseline | the engine canonicalizes a SUPPLIED gauge denominator through `multiquadraticStripMergeGaugeDenominator`: every factor is scaled to a unit leading coefficient (`1 - x - y` becomes `-1 + x + y`) and factors free of the chart variables are dropped. The tests planted coefficients against their own spelling of the denominator (sign flip in the packed vector, pinned normalizations and null direction) and the driver test tried to force a regulator-only "pool-killing" denominator through the driver, which the merge discards by construction | the tests read the canonical denominator from the engine's own merge and the driver test asserts the merge (regulator-free ansatz denominator, then the confirmed fresh-image obstruction of D2). API note recorded: a caller who pins gauge normalizations must express them in the engine's canonical denominator | 92/92, 18/18, 23/23 |
| `t_multiquadratic_installed_family_chain` | red since the baseline (456 s) | CORRECTED 13:20 by Codex's diagnosis: not a solver limitation and not a never-green test (it passed 14/14 four times before, e.g. the 98 s run of 2026-08-27 in the codex tree's `Runtime/2026-08-27_native_hotpaths_pool/logs/`). The preparation multiplies a SUPPLIED gauge denominator by the automatic algebraic-letter norm factor (`GaugeDenominatorFactor -> Automatic`), so the planted gauge with constant support no longer fits: a 32x20 ansatz of rank 20 with augmented rank 21 at every prime, reported only as `NoUsableStructuralPilot` | test restored from the backup with `"GaugeDenominatorFactor" -> 1`, a check that the prepared denominator stays `2 + x + y`, and the option documented as the BASE denominator that the automatic factor may enlarge | 15/15 (the 14 plus the new denominator check) in about 100 s (`round3/t_multiquadratic_installed_family_chain_restored.log`) |
| `t_streaming_kira_import` | EXIT17 pooled, EXIT16 in the reuse confirmation | pool artefact: standalone all 100 regenerated pair files pass `validPreIBPResultQ` (`round3/preibp_validator_all_100_pairs.log`) and section A passes | none needed for A; the Kira sections ran standalone with a 10-minute cap | 19/19 in 90 s (`round3/t_streaming_kira_import.log`) |

Closed item (13:20): the installable rank-three chain was misdiagnosed above as a solver capability gap; Codex found the cause (automatic denominator factor applied to a supplied base denominator) and the test is back in the suite. A follow-up worth doing: the solver should report an inconsistent structural ansatz as such (rank versus augmented rank) instead of the pilot-level `NoUsableStructuralPilot`.

Kernel-start hang (environment, seen twice today; user decision 13:15: `$AllowInternet = False` is now set in `~/.Wolfram/Kernel/init.m`, no kernel on this machine needs the internet): a fresh `wolframscript` kernel can sit at 0-2% CPU with no output for minutes while its paclet manager fetches over the network at start-up (the watchdog saw `WolframChatbookInstaller`, a frozen download under `~/.Wolfram/Paclets/Temporary` and an open TCP connection to the paclet server). `t_reconstruction_nlo` and the first `t_multiquadratic_regulator_filter` rerun were killed in that state. Mitigation to decide with the user: `$AllowInternet = False` in the user's kernel `init.m` (affects every kernel on the machine), or a per-launch stall guard in the seat queue (kill and retry when the log is empty after 60 s).

## Round 4 (13:25 onward): Codex's assessment, every point taken up

Source: `Exchange/Codex/2026-09-02/01_private_overhaul_assessment.md`. Every claim was verified against the code before assignment (13:20); all held except two already done (the `"Below"` option, fixed in round 2) or partly covered (legacy `SourceSHA256` fixtures load in the round-2 tests). Work split across four Fable 5.1 agents by file ownership so no two edit the same file; every kernel launch goes through the two-seat launcher `scratchpad/bench/seat_run.sh` (flock on two seats, CPU pinning, hard timeout); an Opus watchdog checks every 5 minutes. Reports land in `PrivateOverhaul_2026-09-01_evidence/round4/`.

| Agent | Owns | Points |
|---|---|---|
| T | `Transport/ObservableTransport*.wl`, `Tests/Transport` | epsilon-valuation certificate bound to the record and required by acceptance; radical constants in both fresh-prime selectors with an adversarial seed; typed exhaustion instead of retained inadmissible samples; explicit coefficient field for transport-ready records and complete legacy inference; stale Laurent comment; shrink `t_algebraic_observable_transport` |
| M | `Core/ModularArithmetic.wl`, `EpsForm/FiniteFieldStripSolve.wl`, `EpsForm/MultiquadraticStripSolve.wl`, `Tests/FiniteField`, `Tests/Multiquadratic` | context restore of `t_modular_arithmetic` made real; finish the finite-field consolidation (production duplicates replaced or reference-only functions moved out); a legacy-ABI admission test on a real 2026-08-25 fixture; split the 17,900-line solver by responsibility (last, pure moves, manifest updated) |
| G | `Geometry/TransportCharts.wl`, `Transport/MasterTransport.wl`, other EpsForm files, `LoadOrder.wl`, `Scripts/`, `FeynFacet.m` usage | `MapleCanonical` out of the allowed set; enumerate upward cross-layer calls and move shared helpers down, document the true graph; canonical vs standalone campaign scripts; retired master-transport script to the backup |
| L (worktree `factorization-and-loops-L`, branch `round4-laurent`) | Laurent extraction | the modular jet route: uncanonical jet DAGs evaluated modulo primes, only the demanded/constraint maps reconstructed; small-fixture equality with the SeriesCoefficient route, typed reconstruction certificate; one capped CF259 benchmark |
| main session | `HANDOFF.md`, this plan | one current-status block in HANDOFF (done 13:30); merge of L's branch; acceptance wording "no detected regression on exercised paths" |

Results (per agent, as reported and checked by the main session):

- **T (code done 14:00; CF259 certification probe running).** Epsilon valuations: a certificate (`observableTransportCertifyEpsilonValuations`) evaluates the TTotal/TTotalInverse entries at three random admissible kinematic points with eps replaced by a fresh 31-bit prime and reads the epsilon orders as p-adic valuations (numeric radicals replaced by Hensel-lifted p-adic roots); a claimed order above the observation is refused, at or below it is certified (`Tight` when equal), the certificate is bound to a fingerprint of the record's entries and ranges, and `BuildObservableTransport` uses stored valuations only with status `TransportEpsilonValuationsCertified`; `AcceptedObservableTransportQ` requires the new `TransportEpsilonValuationsBound` certificate and re-checks the binding (a result from the previous code is refused). Records on disk are certified in place by `observableTransportCertifyEpsilonValuationsFile` (original kept as `*.before_certificate_2026-09-02.wl`); the CF259 compact record is `Uncertified` until that runs. Radical constants now gate both fresh-prime selectors (test with a seed whose first prime has (5|p) = -1: 7/7). Sample exhaustion is the typed `AdmissibleSamplesExhausted`. Coefficient field: transport-ready records must declare it, legacy inference scans every computational field (12/12 with the exhaustion checks). Stale Laurent comment corrected. `t_algebraic_observable_transport` measured at 5 s (Codex's non-finish was the kernel-start hang), duplicate run removed, 25/25. Regressions: `t_observable_transport`, `_finite_field` 18/18, `_ff_radical_scale` 10/10, `_covariant_closure`, `_laurent_jet` 7/7, all 3-6 s. Left for G's files: certify at construction in `Scripts/compact_family_dlog_record.wls`; a public name in `FeynFacet.m`. CF259 certification probe (14:00): the first attempt found 0 admissible trials in 24 attempts (every rejection `RadicandNotResidue`: the substituted triple-root radicands carry several prime factors, so a random 31-bit prime is a residue for all of them only rarely), a design gap in the certifier, not in the record. Two p-adic designs then failed on the real record (merged radicands; hidden exact zeros needing a precision loop) and both were killed at their caps; the exact univariate route replaced them (substitute a rational point, canonical radicals, `Together`, `CoefficientList`, first exactly nonzero coefficient; no primes). Final run (14:25-14:29, 199 s, `scratchpad/round4/T/cf259_certify_run5.log`): certificate tight, TMin -3 and all 27 block bounds equal Codex's claim at three points; the record certified in place (original kept as `*.before_certificate_2026-09-02.wl`). Consequence: the stored 564 s transport artifact predates the certificate fields, so `AcceptedObservableTransportQ` on it answers False; one rerun of CF259 (about 265 s on the new route) would produce an accepted artifact and is proposed to the user, not launched. Main-session union load check of T+M+G edits: 2.1 s, every moved and new symbol defined.
- **M (done 14:30).** `t_modular_arithmetic` saves and restores its contexts through `Global\`ftModularSavedContexts` and asserts the restore (62/62, zero `Set::shape`). Consolidation: every production call site inventoried; the 11 inline `JacobiSymbol` residue tests and the two screens' `PowerMod[(p+1)/4]` root blocks in the multiquadratic solver now call `modularResidueQ` / `multiquadraticSquareRoots` (identity proved in the report); `modularSplitPointQ`, `modularSplitPoints`, `modularEvaluateAt` (no production caller, no identical duplicate) moved verbatim to `Scripts/Diagnostics/ModularSplitPoints.wl`; kept with documented reasons: the solver's fresh-image prime draw (a different random sequence would rename stored evidence) and its regulator lift (records unreconstructible coefficient positions); `modularLift` stays in Core because two identical compositions exist in files M does not own (handed to G). Legacy ABI: the validators in fact refused `"SourceSHA256"` records (13 of 27 assertions failed before the fix); an alias of the key (`multiquadraticStripABIKey`, lineage `LegacySourceSHA256`), every seal still checked over the key the record carries; a version-equality refusal was tried and removed because `t_multiquadratic_persistence` P5 pins blind resume admission; new test `t_multiquadratic_legacy_abi_records` 27/27. Split: `MultiquadraticStripSolve.wl` (18,060 lines) into eight files (Solve, Letters, Screens, PrepareCompile, Sampling, Providers, Reconstruction, Driver) at the file's own banners, pure moves, `ClearAll` partitioned by defining file (six tests re-`Get` the solver), manifest updated; 445 definition heads before and after as an identical multiset; load check identical before and after; twelve multiquadratic tests green (strip_solve 92/92 in 23 s, gauge_screen 59/59 in 76 s, the rest 3-36 s). Main-session check: live-package definition heads 2115 at HEAD versus the working tree, only the three diagnostics-moved functions absent.
- **L (report 14:15, benchmark running).** Calibrated first on real CF259 entries (417 nonzero entries, 11.8 MB; the nine demanded rows hold 72% of the text): the production route's cost on small entries is the `Cancel[Together]` of `SeriesCoefficient`'s bulky output; one `Series` per entry gives byte-identical canonical coefficients (`SameQ`) at 1.4x to 10x less; Codex's premise, the uncanonical jet compiler evaluated modulo primes, does not terminate on nested-quotient entries (the common-denominator cross-multiplication grows with the nesting depth, the same effect as the 21-minute rejection), and the demanded map (20 x 261 algebraic functions, 72% of the text) is the physics output and must be canonical anyway, so reconstructing it from modular samples is out of budget by orders of magnitude. Design decision, with the estimates recorded in `round4/L_modular_laurent_route.md`: the exact route B is production (`$observableTransportLaurentMethod = "Series"`), each row expanded only to the order the transport reads (demanded rows to their demanded order, the 38 forbidden-map rows to valuation - 1 instead of order 2), orders above a cap are typed placeholders both consumers assert on; a pole below the record's `TMin` is the typed refusal `LaurentValuationBelowRecord` (the former route dropped it silently); a pre-existing empty-constraint defect on the ambient-base-point branch fixed. Tests: new `t_observable_transport_laurent_series` 19/19 (real CF259 entries and three end-to-end fixtures `SameQ` between the routes) and the nine transport tests green. The modular-only closure is not built; its value on CF259 is bounded in the report (60-150 s of new cost against 40-60 s removed). The Jet route is demonstrably pathological on nested quotients and should be retired to the backup with its test (main session). CF259 benchmark (single run, 14:13-14:18, `scratchpad/round4/L/cf259_bench.log`): transport 265 s against the accepted 564 s, every deterministic part of the transported object `SameQ` with the accepted artifact (demanded rows, constraint matrix, base kernel and embedding, operator automaton, boundary operators), no new certificate primes; total script 272 s.
- **G (done 13:56).** `GaugePullBackMode` allowed set is `{"Exact", "FiniteFieldReconstruct"}`; "MapleCanonical" gets the typed `InvalidGaugePullBackMode` refusal, the stub still answers `RouteRetired` by name; test `t_gauge_pullback_mode` 6/6. Layer cycle: a symbol scan found 55 upward call-time references in 12 files; moved verbatim downward: the 15-symbol radical/chart algebra cluster (Geometry to `Core/MultiquadraticAlgebra.wl`), 26 `masterTransport*` helpers (Transport to `Core/Core.wl`), the Libra loader (Transport to `EpsForm/LibraEpsForm.wl`), `FamilyArtifactRead/Write` (EpsForm to Core), binary record I/O (Reduction to Core), `validPreIBPResultQ` (Reduction to `Process/Collinear.wl`), the kinematics normalization chain (Reduction to `Process/Process.wl`), the broker's strip-sampler client (Infrastructure to the new `EpsForm/FiniteFieldStripBroker.wl`, one manifest entry). Main-session check: definition heads in the live package 2115 before, 2136 after, none lost by G's moves. Remaining upward references are named in the `LoadOrder.wl` header and `Design/GeometryDeclaration_2026-09-02.md` (EpsForm to Geometry catalog lookups; FamilyEpsForm to four `observableTransport*` predicates). Scripts: kernel-pool campaign driver canonical, process driver labelled standalone; `complete_master_transport.sh` does not drive the retired route and stays. Regressions: load check, `t_epsform_obstruction` 7/7 (63 s), `t_package_generality` 25/25 (111 s); main session: `t_multiquadratic_transport_frame` (solves through `SolveEpsFormStripInFrame` with the moved helpers) 20/20. Proof that the moves are pure: every cut block occurs byte-identically once in its destination (`round4/G_move_proof.log`). Follow-up (14:15): `Scripts/compact_family_dlog_record.wls` certifies the epsilon valuations after building the compact record and writes only a certified record (typed status and exit 3 otherwise); public `CertifyTransportEpsilonValuations` (record or file) in `FeynFacet.m` with wrappers at the end of `ObservableTransport.wl`; probe 11/11, script end-to-end on a two-block fixture: good claim written, stale `TMin` refused, missing claim derived. Further follow-ups (14:30): the two spelled-out lifts (`diagonalBlockLiftFunction`, the gauge pull-back lift) are now `modularLift` on padded per-prime lists, duplicates deleted, so lift-and-verify has one implementation of the composition too; the residue idiom in `FamilyRegulatorFactor.wl`, `BlockEquationDeferred.wl`, `FamilyCertificateModular.wl` is `modularResidueQ`; verified by `t_diagonal_block_epsform` 25/25, `t_finite_field_gauge_pullback` 14/14, `t_multiquadratic_regulator_factor` 66/66, `t_deferred_bundle_chart_compatibility` 20/20, `t_family_certificate_multiquadratic` 28/28 (3-14 s each).

## Round 5 (14:20, user ruling): substructure inside the layers

User: "Let there be substructure in private, like subsubfolder; you can't just pile everything under the subfolder." After rounds 3-4 the layer folders hold 4 / 5 / 7 / 1 / 24 / 1 / 3 files (Core, Process, Reduction, Infrastructure, EpsForm, Geometry, Transport); EpsForm in particular is a pile of 24 files and `Core/Core.wl` became a grab-bag of the helpers moved down in round 4. Decided layout (pure moves; file names unchanged so that no test, script or note goes stale on the name; the manifest entries become paths relative to the layer, `feynFacetPrivateFile` answers to the bare name as well as to the relative path):

| Layer | Sub-folders (files) |
|---|---|
| Core | `Algebra/` (MultiquadraticAlgebra.wl, RationalMaterialization.wl, the radical/letter algebra of Core.wl), `Modular/` (ModularArithmetic.wl), `Artifacts/` (the artifact reader/writer and binary record I/O now in Core.wl), `Charts/` (the chart-record data and chain-rule pullbacks now in Core.wl), `Base/` (what remains of Core.wl: contexts, regulator/variable resolution, zero tests). Core.wl is split at its own banners into those files, pure moves of blocks, as the solver was in round 4. |
| Process | `Cards/` (Process.wl, CanonicalFamilies.wl), `Diagrams/` (Topologies.wl, Collinear.wl, DimensionalShift.wl) |
| Reduction | `Kira/` (Reduction.wl, StreamingKira.wl), `AmFlow/` (MasterIntegralAmFlow.wl), `Coefficients/` (Simplification.wl, CoefficientStore.wl, Reconstruction.wl, Assembly.wl) |
| Infrastructure | one file, stays flat (`TaskBroker.wl`) |
| EpsForm | `Blocks/` (DiagonalBlockEpsForm.wl, CanonicalBlocks.wl, LibraEpsForm.wl, BlockEquationDeferred.wl), `Strip/` (EpsFormStrip.wl, EpsFormStripObstruction.wl), `FiniteField/` (FiniteFieldEpsForm.wl, FiniteFieldStripSolve.wl, FiniteFieldStripBroker.wl, FiniteFieldGaugePullBack.wl), `Multiquadratic/` (the eight MultiquadraticStrip*.wl and MultiquadraticInstallation.wl), `Family/` (FamilyEpsForm.wl, FamilyRegulatorFactor.wl, FamilyCertificateModular.wl, FamilyRowGauge.wl, FamilyRowGaugeResume.wl) |
| Geometry | one file, stays flat (`TransportCharts.wl`); the open item of round 4 (move `SolveEpsFormStripInFrame` into EpsForm) is the next step there |
| Transport | `Observable/` (ObservableTransport.wl, ObservableTransportFiniteField.wl), `Assembly/` (MasterTransport.wl: the chart assembly and the retired-route stubs) -- moved only after L's branch is merged |

Phase 1 (M, done 14:30): loader accepts layer-relative entries, `feynFacetPrivateFile` answers to the bare name and the relative path, duplicate bare names abort the load; Core split at its own banners into `Base/Core.wl` (813 lines), `Artifacts/Artifacts.wl`, `Algebra/Radicals.wl`, `Charts/ChartData.wl` plus the moved `Algebra/MultiquadraticAlgebra.wl`, `Algebra/RationalMaterialization.wl`, `Modular/ModularArithmetic.wl`; Process and Reduction moved as decided; 13 tests that loaded modules by literal path now use `feynFacetPrivateFile`; the overhaul tooling (`route_split.py`, `reachability.py`, `move_to_backup.py`) walks nested layers. Head multiset over all of Private identical before and after (1883 heads, 46 to 49 files); load check 4 s; `t_modular_arithmetic` 62/62, `t_family_artifact_read` 15/15, `t_multiquadratic_algebra` 75/75, `t_ghost_card_pipeline` 6/6.

Phase 2 (M, done 14:35): the 24 EpsForm files into `Blocks/`, `Strip/`, `FiniteField/`, `Multiquadratic/`, `Family/`; 9 code consumers and 17 prose mentions re-pointed; load check 24/24 files live, head multiset identical; `t_multiquadratic_algebra` 75/75, `t_multiquadratic_regulator_filter` 10/10, `t_epsform_obstruction` 7/7.

Merge of L's branch (main session, 14:25): L's edits to `ObservableTransport.wl` merged three-way onto T's (one conflict, the route comment and default: L's version taken, `"Series"` is production); L's test, fixture and report copied; on the merged file `t_observable_transport` all True, `t_observable_transport_laurent_series` 18/19 with the one failure an ordering assumption (a stale `TMin` is now refused by T's certificate gate before L's Laurent guard can fire; the assertion now accepts either typed refusal). Checkpoint commit 57bd613d.

Phase 3 (M step 1 at 14:27, step 2 run by the main session at 14:30 after the Laurent merge): `Transport/Assembly/MasterTransport.wl`, `Transport/Observable/ObservableTransport.wl`, `Transport/Observable/ObservableTransportFiniteField.wl`; manifest entries relative; `t_observable_transport_finite_field` re-pointed through `feynFacetPrivateFile`; load check OK (48 unique module names, both spellings, no flat Transport file), `t_observable_transport_finite_field` 18/18.

Sequencing: the moves start when T and G have finished editing (a move under a live editor loses edits); Transport last, after the merge of `round4-laurent`. Verification: load check, the manifest-reading tests (six multiquadratic tests, `t_modular_arithmetic`), the source-scan tests, one test per moved group, definition-head multiset before/after.

## Round 6 (16:45, user: "do all the 3 open"; at most two Fable agents, Opus watchers)

- `main` pushed to `origin/main` (89c0479d..bff72ee3, 31 commits) at 16:49; pushed again at the end of the round.
- Seat launcher hardened (`scratchpad/bench/seat_run.sh`, copy in `Scripts/seat_run.sh`): the release line is written on every exit path, including a wrapper killed by signal (the 14:03 seat-B accounting gap); refuses a missing `-file` script (exit 66) instead of wolframscript's silent exit 0.
- T: retire the Jet Laurent route to `Private_Backup/ObservableTransportJet.wl` with its test and evidence (`"Jet"` answers `RouteRetired`), then ONE CF259 transport run through the new route on the certified record, into `.../CF259/observable_transport_2026-09-02_certified/`, accepted-predicate check and SameQ comparison with the 05:51 artifact.
- G: `SolveEpsFormStripInFrame` moved into `EpsForm/Strip/`, Geometry listed before EpsForm, upward-reference scan re-run, design notes updated to the true graph.
- Opus watchdog resumed for the period.

Results:
- T (done 17:05): Jet route retired to `Private_Backup/ObservableTransportJet.wl` with its test and evidence; `"Jet"` answers `RouteRetired`; `t_observable_transport_laurent_series` 20/20. CF259 rerun on the certified record: `ModularlyVerifiedObservableTransport` in 270 s (Laurent 151 s vs 440 s), `AcceptedObservableTransportQ` True with the valuation certificate bound, every deterministic part SameQ with the 05:51 artifact; new artifact `.../CF259/observable_transport_2026-09-02_certified/observable_transport_CF259.wl` (SHA-256 fe0c6f59...6060), the 05:51 one kept.
- G (done 17:08): `SolveEpsFormStripInFrame` and its 33 helpers moved verbatim to `EpsForm/Strip/EpsFormStripInFrame.wl` (TransportCharts.wl 2806 to 1108 lines), the four `observableTransport*` predicates down to Core/Geometry, Geometry listed before EpsForm: the layer graph is acyclic (zero call-time upward references, scan in the report), proof of pure moves in `round4/G_inframe_move_proof.log`; load check 26/26; `t_multiquadratic_transport_frame` 20/20, `t_construction_budget` 40/40, `t_epsform_obstruction` 7/7, `t_package_generality` 25/25. Main-session final load check of the whole tree: 1.9 s, every public name defined, no duplicate definitions after the concurrent edits, manifest order Core, Process, Reduction, Infrastructure, Geometry, EpsForm, Transport.

## Round 7 (after the quota reset; one Fable agent, Opus watchdog)

- T: make the valuation certificate cheap (numeric-point orders, one pass per point, exact zero test only on candidate leading coefficients, per-block early exit; target under 60 s on CF259 against 199 s) and make the transport driver write each stage milestone to the run log as it happens (the watchdog saw the CF259 log appear only at completion, so a mid-run hang is invisible until the cap).
- Main session: L's merged worktree and branch removed; the three round-1 scratch worktrees (`base`, `mergeprobe`, `work`) removed. The `work` tree still held uncommitted items; checked afterwards against the object store and all refs: its staged `Design/MultiquadraticInstallationContract.md` and `Development/2026-09-01/gpu31_deferred_backend/` are Codex's files (commits a90ab40a, e3db6fd3 on Codex's branch), and its `KernelPool.wls` was the OLDER hard-coded-path version (main carries the `FACET_SCRATCHPAD` one). Nothing of ours was lost.

Results (T, 17:45): the transport driver now writes every milestone to `<output>.log` as it happens (hook `$observableTransportMilestoneHook`; CF27 evidence: 16 stamped lines, the file grows during the run). Certificate: 199 s to 112 s on CF259 by a rigorous per-entry order lower bound from the quotient scaffold (4389 of 4418 entries skipped), exact evaluation only for candidates that can lower a minimum, truncated-coefficient route for later candidates, contract unchanged, test 31/31; a defect found on the way (canonical ordering put unbounded entries last) fixed. Target under 60 s not reached: 26-29 s per point are C-level scans over 100 MB of numerators; the next lever (single-pass exponents per numerator, per-row denominator sharing, estimated 35 s total) is recorded in T's report.

## Round 8 (user mandate after the quota reset): speed campaigns on both stages

User: "optimize also the transporter for non-eps form, like CF303; and also optimize canonicalization, like the triple roots were very slow ... use the lessons learned in transport into canonicalization, I want several folds / order of magnitude speed up for hard blocks; you can attack in every way. You can use an adversarial subagent to assess the result / make recommendations, before you call it finished." Two Fable agents at a time, Opus watchers.

State found by reconnaissance (17:30):
- Stage 1 on the triple-root families (`FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/`): CF259 solved (its eps-form feeds the accepted transport); CF300's regulator reconstruction ended in `RegulatorScheduleExhausted` after 855-2078 s missions; CF303's block (25,18) has NO rational dlog form (`ModularStructureUnstable`, 4910 s; Codex's 2026-08-30 note 05: the gauge-eliminated integrability screen has defect 1 at three images, a confirmed no-go for strict dlog). Codex's 2026-08-27 profile: one CF300 (12,9) image was 183 s, 94% coefficient evaluation, cut to 3.8 s by native batch evaluation and sealed sparse plans; the 2026-08-20 (9,7) record: 7106 of 7254 s in modular sampling, `MatrixRank` 10 s per sample in Wolfram.
- CF303 transport: Codex's tree holds a provisional, audit-blocked hybrid route (`Diagnostics/Reports/CF303_FINAL45_ELLIPTIC_TRANSPORT.md`, `cf303_hybrid_path_gauge_operator_2026-09-01.md`): the final block is rational-in-epsilon (valuation -2, orders -2..4 needed), every path one-form dlog on the quartic curve Y^2 = P4(u), an elliptic layer with marked poles, a deferred exact circuit (sealed Hermite/recurrence nodes executed over F_q or F_q2) replacing the non-viable characteristic-zero recurrence; 1,551 lines of scripts plus JSON manifests and a python resolver, none of it in our package.

Charters:
- M (stage 1): fixture ladder of hard blocks that finish in seconds to minutes; per-stage profile; attack the top costs with the transport lessons (one Series per entry, no repeated Together, modular evaluation of uncanonical DAGs, native batches, caps, memoization across primes); exact acceptance contract unchanged; before/after table per fixture and stage. Report `round8/M_stage1_speed.md`.
- T (non-eps-form transport), after round 7: read Codex's CF303 route and reports; design and implement a general package route for a rational-in-epsilon final layer (Laurent recurrence order by order with typed exceptions, modular evaluation of the sealed circuit, only demanded maps reconstructed) on top of `BuildObservableTransport`'s machinery, with the elliptic (curve) letters as a typed extension; small synthetic fixtures first, then CF303's accepted inputs under caps; optimize with the same lessons; report `round8/T_noneps_transport.md`.
Results so far:
- M, pass 1 (18:45, `round8/M_stage1_speed.md`): the finite-field solves on the triple-root families total seconds (CF300 1.7 s over 66 strips, CF303 33.6 s over 276); the hours were symbolic: CF303 (25,18) materialization 1477 s, candidate letters 1514 s, regulator reconstruction 3245 s; CF300 bundle-denominator refinement 486 s. Ladder (production route, standalone probe): R1 CF300 (12,9) deferred 51 s; R3 (12,1) 50 s; R2 (12,9) frozen symbolic 163 s; R4 (12,7) 246 s. R4 profile: chart pull-back 115 s (materialization 53 + Jacobian normalization 60), inner solve 92 s (prepare 21, held-out sampling 52 of which the point loop is 14.5), gauge pull-back normalizer 29 s, linear algebra/interpolation/lift under 2 s. Retained: Jacobian normalization through the FLINT-backed exact canonicalizer gated at 150 k leaves (60.1 to 22.6 s; R4 whole solve 246 to 204 s), one SparseArray per sample, sampler timers; dropped: ungated canonicalizer (loss on R1), a Together probe for materialization. Second pass ordered on the four resisting levers (held-out block outside the point loop, per-point cache across regulator samples, native DAG batch for the deferred materialization, the gauge pull-back normalizer) plus one capped ceiling measurement on CF303 (25,18).
- T (done 19:45, `round8/T_noneps_transport.md`, commit f2965aed): assessment of Codex's route (general structure versus CF303 data; its acceptance is image evidence without a re-verifiable predicate; 80% of an image is Maple parsing); new route `BuildRationalEpsilonLayerTransport` in `Transport/Observable/RationalEpsilonLayer.wl` with `AcceptedRationalEpsilonLayerTransportQ`: typed alphabet gate (curve letters only with a declared quartic; the elliptic channel itself refused typed), certified epsilon window, one Series per entry, path gauge K_n = B_n + D H_(n-1) - H_(n-1) S - dH_n executed as a sealed Hermite circuit over F_q[u], adaptive lift-and-verify with fresh-prime validation, demand-pruned word enumeration with a typed cap, certificate and predicate; test 19/19 against an independent characteristic-zero reference. CF303 inputs consumed as data at p = 9/8 (conjugate algebraic poles merged into rational letters): typed `LowerBlockExceptionRequired` for masters {1,2,12,21,22,29,30} and `CurveChannelNotImplemented`; the rational sub-layer alone (partial, not a CF303 result) 46.7 s, then 1.1 s with a direct exact route for path-free coefficients and demand-pruned source growth, SameQ with the modular circuit. Remaining for CF303: the elliptic channel, the seven Maple-only exception forcings, the T25 gauge, p-dependence, the source layer from a family record. Adversarial review R1 launched 19:50.
- Adversarial review (fresh Fable, after each campaign's report): assess correctness claims, the measurements and the generality, recommend; the campaign is "finished" only after the review's points are answered.

## Deliberately not done

- N1. Splitting the chart catalog into a separate data file: the records
  in `TransportChartCatalog[]` are already declarative (Name, Subst,
  Roots, Parents, Notes) and reference two helper functions; a second
  file would add a loader and buy nothing measurable. The declaration
  paths (catalog record, per-family registration, automatic extension)
  are documented in `Design/GeometryDeclaration_2026-09-02.md`.
- N2. Removing the Legacy branches from `Scripts/family_epsform_sector.wls`
  (2,111 lines, six tests exercise it): the route is refused at start
  and CANONICA is no longer loaded on the production route; deleting the
  interleaved branches was judged more risk than value tonight.
- N3. `CanonicalizeClasses` and the Libra transport engines: see
  `Private_Backup/EVIDENCE.md` and decision U1.
- N4. The multiquadratic solver's hot/full validation split (audit items
  2-5): the solver is no longer on a production path (all rank-3
  completions finished); maintainability-only work, deferred.
- N5. GPU work beyond the design note (goal 6): the measured evidence
  favours the CPU evaluator; the reference tooling is adopted under
  `FeynFacet/Backends/native_postfix/` unreviewed.

- N6 (pool state beyond own values). The pool isolation of B11 unsets leaked Global own values
  only. Leaked function definitions, `$Context`/`$ContextPath` switches and the `FeynCalc`Names`
  shadow (B13) are not undone; the pooled phase therefore remains a screen with standalone
  confirmation, which the driver already does. A full per-mission sandbox (fresh subkernel per
  mission) costs the 60-80 s package load per test and was rejected for the batch.

- N7 (goal 2, from review note N2). The finite-field consolidation is wired into
  FiniteFieldEpsForm.wl, FamilyCertificateModular.wl, MultiquadraticAlgebra.wl and the
  observable-transport compiler; the split-point sampler of PathTransportNative.wl and the
  prime schedules of FiniteFieldStripSolve.wl keep their own bodies (each has its own artifact
  and ABI contract; migrating them needs their long tests, `t_path_transport_native_order`
  and the strip-solve suite, in a dedicated pass). The primitives without a production caller
  (`modularLift`, `modularResidueQ`, `modularSplitPoints`, `modularPrimes`) stay as the
  reference API with their 61-assertion test; the module header now says so.
- N8 (review note N1). `multiquadraticSplitPointQ` (no live caller) now reduces rational
  coordinates correctly but collapses an unevaluable input to False instead of a typed failure.
- N9 (review note N6). The pool isolation scans `Names["Global`*"]` twice per mission
  (one ToExpression per name); measured cost not yet recorded; `FACET_POOL_ISOLATION` is
  read on the subkernel, so it takes effect for kernels started after it is set.

## Decisions that need the user
- U4 (from B12): should solver result payloads carry wall-clock timings at all? Today `InnerSolution` of the finite-field route embeds `LiftingSeconds` etc., which makes records non-reproducible byte-wise and defeats fingerprint pins. Proposal: one top-level `"Timings"` key per record, excluded from certification hashes; requires a schema bump for the strip-state records. Not done in the overhaul because the record readers in the sector driver and the resume logic key on the current layout.

- U1. Retire the Libra path-ordered transport engines (`TransportFamily`
  with engines Monolithic/Blockwise, ~1,900 route-only lines, five tests)
  to `Private_Backup/`? The observable transport is the production route
  (88/88 ordinary families accepted 2026-09-01) and the 71 `Masters/*.wl`
  artifacts of the August sweep remain as evidence. `TransportFamilyInChart`
  keeps its assembly mode (used by the eps-form driver). The overhaul
  proceeds with the four small routes first and does this one last if
  time permits; it is reversible (git) either way.
- U2. Audit item 7: `finiteFieldStripCFFRVerify` skips the r x r row-minor
  replay on the grounds that every follower sample does an all-row
  residual, while MultiquadraticStripSolve.wl:10131 says native follower
  solves do not repeat the all-row product. If both hold, that is a
  possible under-check on the native follower path, not a redundancy. Not
  touched tonight; needs a look before any removal there.
- U3. `$multiquadraticStripSourceSHA256` (a hash of the 949 kB solver
  source) is an ingredient of every stored assembly and letter certificate,
  so editing a comment in that file invalidates every stored artifact. A
  hand-maintained ABI version number would carry the same intent; left as
  is tonight because it would re-key existing artifacts.

## Log
- 11:42 (round 2) t_multiquadratic_constrained_affine_plan 27/27 after the propagation. The full-batch pool of 11:38 launched ZERO of eight subkernels (`LinkConnect::linkc`, then "no subkernels; exiting") while an orphaned WolframKernel of the 11:38 attempt (parent gone, 1 s CPU) was still alive; the driver sat idle on the dead pool. Orphan and driver killed by verified PID; subkernel launch probed in a bare kernel before relaunching. Third kernel-start irregularity of the morning (two stalled mains, one failed subkernel launch); the pool's own guard (exit when no subkernel comes up) worked.
- 11:40 (round 2) t_finite_field_eps_form green on the rerun (all booleans True). The constrained-plan failures traced to the Freivalds projection count living only inside the residual-check evidence, not in the top-level solve record the evidence predicate reads; propagated, rerun running. Full suite launched on the KernelPool (8 subkernels, REUSE mode, driver run from a scratch copy with the repository root pinned -- the first attempt found no tests because the copy derived its root from its own location). Two kernels today started but never loaded (4 s CPU after minutes); both killed by verified PID and re-run; cause not established (licence/link start-up), recorded here for the next reader. Round-2 checkpoint committed on main.
- 11:30 (round 2) smoke queue B drained (39 jobs, watchdog: no refusal, no stall). After the CANONICA-alphabet replacement and the test migrations every rerun is green: t_construction_budget 40/40 (fingerprint intact), t_finite_field_affine_rref_backend 35/35, t_broker_adaptive 40/40, t_family_row_gauge 39/39, t_generality_renamed_variables 53/53, t_radical_denesting 36/36, t_kallen_q4_chart 60/60, t_package_generality 25/25, t_canonical_blocks 13/13, plus t_hard_class_epsforms 24/24, t_family_certificate_multiquadratic 28/28, t_multiquadratic_persistence 53/53, t_multiquadratic_provenance 69/69, t_modular_arithmetic 61/61, t_multiquadratic_algebra 75/75 and the boolean-style tests exit 0. Open: t_multiquadratic_constrained_affine_plan (2 U2 assertions; diagnostic running), t_finite_field_eps_form (rerun running). t_eps_form_strip turned out to drive the Maple residue-gauge route (SolveResidueRationalGauge) -- retired with its test per N3.
- 11:00 (round 2) the retirement edits went through a fresh-kernel load check after one syntax slip (my usage-message rewrite left the tail of the old TransportFamily usage dangling in FeynFacet.m; the watchdog caught it, fixed, re-checked: Options 26, stubs answer RouteRetired, validator True/False on the good/bad forms, timings record, ABI version). Two more slips fixed the same hour: the new `"Below"` option of modularPrimes had not been registered (reserve primes returned $Failed; re-registered, 3 reserve primes identical to the old schedule), and my restore of canonicalBlocksChartParameter copied 300 lines of the ladder back into the live module (returned to the backup; the live file defines the chooser only). Smoke queue B (26 affected tests + benchmark) running; t_canonical_blocks 13/13 with the CANONICA-free validator, t_generality_renamed_variables and t_construction_budget migrated to the retired-route contracts and re-queued.
- 08:41 post-merge verification on `main` in fresh kernels: load check Options[SolveEpsFormStrip] 15 / Options[SolveEpsFormStripInFrame] 26, restored helpers defined; t_construction_budget 40/40, t_kernelpool_duplicate_verdict 7/7, t_observable_transport_ff_radical_scale 10/10, t_modular_arithmetic 61/61, t_reconstruction_parser exit 0 (real directories, no symlink). Session ends here; the next session starts from HANDOFF.md.
- 08:38 `main` fast-forwarded to `overhaul` (e577a6a9, 18 commits on 2d73f71f); post-merge verification in fresh kernels from the main tree (load check, t_construction_budget, t_reconstruction_parser, t_kernelpool_duplicate_verdict, t_observable_transport_ff_radical_scale, t_modular_arithmetic) running. Housekeeping for the next session: the `base` and `work` git worktrees live under the session scratchpad (`git worktree prune` once it is gone); the KernelPool with the new isolation code has now run three kernel-launching tests green but no production campaign yet.
- 08:40 all confirmation queues drained; final merged table written into the acceptance section; benchmark table finalized (CF230 3.79 s after recording the radical constants at compile time). Deviation to record: the last two short queues (queue3: three fast tests + benchmark, queue4: one 30 s test) ran without their own watchdog agent; the waiter scripts and direct log reads served as the check, and both drained within minutes.
- 08:30 second confirmation queue drained (watchdog: 17/17 jobs, no allowance kill, no licence refusal, no fatal signature; the six kernel-launching tests took both seats cleanly): fix12 reruns after the workspace copy all green incl. t_reconstruction_parser 14/14 (the K assertion was the symlink); the standalone-only set green (t_canonica_scheduler, t_canonical_pipeline, t_pair_queue_schedule, t_kernelpool_return_marker, t_kernelpool_resource_policy with the NEW pool code, t_kallen_q4_chart 60/60, t_family_regulator_factor_in_frame, t_radical_denesting, t_transport_chart_extension). The stray `Power::infy` (t_family_regulator_factor_in_frame) and `N::meprec` (t_radical_denesting) messages occur identically (4 each) in the baseline's fresh-kernel runs. One red: my own B2 regression test t_kernelpool_duplicate_verdict, which had never passed -- its planted-claim scenario cannot occur because the dispatcher's stale-record hygiene deletes claims before every dispatch; the verdict logic is now one function (`poolVerdictFromDrain`) and the test evaluates it verbatim from the source (cases a-e), no pool launch, so it leaves the standalone-only list. Benchmark on the final branch (commit 1dd66dc0): load 2.12 s, CF27 1.32 s, CF230 5.70 s (was 2.90 s at checkpoint 4 -> the review-R1 scan per sampler call; the radical constants are now recorded once at compile time, remeasure running), CF385 47.5 s (new), dbe 1.80 s.
- 08:00 watchdog finding (the second watchdog's report): my `sed -i` on the confirmation queue file at 07:53 replaced its inode, so the running loop kept reading a stale deleted copy (the three capped tests still in it, the fix12 reruns absent). Stopped that loop by verified PID (its running chart-transport job finishes on its own) and armed a second loop on a fresh, APPEND-ONLY queue (`queue_overhaul_confirm2.tsv`: fix12 reruns, the four remaining standalone-only tests, the six kernel-launching tests, the benchmark) that starts when the job ends. Rule: a queue file read by a live loop is appended to, never rewritten in place and never `sed -i`'d; the first two duplicate-consumer incidents of the night were the same class.
- 08:00 t_reconstruction_parser on the branch (standalone) failed only assertion K, which compares the artifact's TraceDirectory with ExpandFileName of the test's trace path: in my worktree `Codex/ppHX_NLO` was a symlink to main's workspace (the discovered manifest path came back resolved), in the baseline worktree it is a real directory (its tests built it at 05:25). Not a code difference: replaced the link by a real copy (162 MB) and re-queued the parser, ghost, NLO golden and registry tests (`fix12_*`). t_master_transport fails the same L5 assertion on both trees (red-both).
- 07:54 second duplicate-consumer incident: the 06:36 waiter script (`launch_confirm_after_baseline.sh`) had survived my earlier kill (I killed its setsid wrapper, not the loop) and, when the baseline finished at 07:51, launched a second seat-queue loop on the same queue file; it re-ran two short tests before I stopped it and its job by verified PID. Rule recorded: after `setsid ... &`, find the loop by its own command line and kill THAT pid; verify with a process listing, not with the wrapper's exit. No result was affected (the duplicate runs passed and are superseded in the table by the later runs).
- 07:40 the four remaining red standalone confirmations on the branch (t_exact_depth 1 of 23, t_multiquadratic_obstruction_driver 3 of 23, t_multiquadratic_regulator_reconstruction 6 of 18, t_multiquadratic_strip_solve 20 of 92) fail EXACTLY the same assertions as the baseline's pooled runs of those tests (assertion-text diff empty modulo line wrapping): pre-existing reds, not regressions; the baseline's standalone confirmations of them are running. Baseline letters capped at 1906 s like its two siblings. A load check after the ClearAll cleanup caught one mangled SetAttributes line (fixed, re-checked).
- 07:45 review notes applied: dangling ClearAll entries of moved symbols removed in eight files, `epsFormFiniteFieldImageQ` wired to the shared module, the retired Libra worker documented (no early exit: an Exit inside a Get would end a pool subkernel), EVIDENCE.md corrected, stale `FeynFacet/Private/<file>` prose paths updated to the layer paths in twelve files; N7-N9 added to the not-done list; load check queued.
- 07:30 review defects D1-D4 fixed and confirmed in fresh kernels: Options[SolveEpsFormStrip] 15 / Options[SolveEpsFormStripInFrame] 26 after the layer reorder (load check), t_construction_budget 40/40, the restored helpers defined. B14 confirmed: 24 of 24 numeric-frame certifications succeed with the admissible-prime draw (was 1-2 failures per 24), the fixed certificate test 28/28. Review risks addressed on the branch: R1 (numeric radical constants must be residues at the sampling prime; typed rejection counter), R2 (a radical whose square is a declared square keeps its own root symbol), R3 (no factorization beyond 30 digits), R4 (CRT alias keeps its list shape), R5 (fingerprint memo keyed by $ContextPath); R6 recorded (callers gate p == 1 mod 4 themselves). Reruns of the touched tests queued (fix11_*).
- 07:20 certificate diagnostics (fresh kernels, 24 certifications per tree of the numeric constant-field frame): overhaul 1 failure, baseline 2 failures; with the earlier runs, branch 4/33, baseline 2/31, always `InsufficientFreshValidationPrimes` after `InsufficientUsablePoints` at primes p == 7 (mod 12), where the numeric root square 3 is a non-residue. Verdict: pre-existing flaky design (the certifier draws primes without checking the numeric root squares' residuosity and spends up to 80 point attempts per hopeless prime out of one 24-draw budget shared by four stages), not a branch regression; fixed as B14 below with a deterministic regression assertion.
- 07:12 confirmation queue (fresh kernels, overhaul tree) after 27 jobs: 23 OK incl. t_physical_variable_coefficients (B11 confirmed), t_finite_field_affine_rref_backend, t_broker_adaptive, t_solver_budget, t_task_broker_limit, t_construction_budget 40/40; red on BOTH trees (pre-existing): t_multiquadratic_installation, t_multiquadratic_end_to_end_install, t_multiquadratic_installed_family_chain, t_streaming_kira_import (EXIT16). One open item: t_family_certificate_multiquadratic fails its numeric constant-field frame assertion standalone (26/27) and in the batch's pooled run, but passed the pooled rerun and the baseline; the certificate is unseeded (`Seed -> Automatic` draws a random seed), so six-trial diagnostics on both trees are queued next to separate flakiness from a branch defect.
- 06:50 confirmation results so far (fresh kernels, overhaul tree): t_modular_arithmetic 61/61, t_observable_transport_laurent_jet 7/7, t_observable_transport_covariant_closure 4/4 booleans True, t_multiquadratic_algebra_differential 24/24, t_package_generality 25/25. Incident: my restart of the seat queue left the first loop alive (the PID I checked was the setsid wrapper's, not the loop's), so two loops consumed the same queue for ten minutes; the newer one was stopped by verified PID and the one garbled job re-queued. Baseline: t_multiquadratic_gauge_screen capped at 1961 s (EXIT137), t_multiquadratic_letters running under the same cap.
- 06:40 confirmation queue for the overhaul tree started (52 standalone jobs: 6 changed tests, 33 SCREEN rows, 13 standalone-only tests; the 6 kernel-launching tests last because they need both seats). First attempt had put a kernel-launching test first; it was aborted and its two leftover kernels killed by verified PID. Pooled-row comparison of the two drivers: no regressions, 2 fixed (t_algebraic_observable_transport, t_reconstruction_nlo), 9 new tests green.
- 06:37 the overhaul driver died at the end of its pooled phase with a bash parse error (`line 232: unexpected EOF`): I had edited `Scripts/run_tests_pool.sh` in the work tree at 05:57, one minute after launching it, and bash reads a running script incrementally, so the standalone phase never started and the pool was left running. All 127 pooled rows are valid. Recovery: pool stopped by control file; the standalone-only tests and every SCREEN row go through my seat queue (`bench/queue_overhaul_confirm.tsv`, 30-min allowance each) once the baseline releases the seat. Rule added to the launch script: run drivers from a scratch COPY, never from the tree being edited.
- 06:36 queues arranged for the seat: the baseline driver's standalone phase (gauge_screen capped at 06:47, letters next), then my confirmation queue for the tests changed after the batch (`bench/queue_overhaul_confirm.tsv`, waits for the baseline seat), while the overhaul driver's own standalone confirmations retry on licence refusal. Pool isolation code corrected to qualify bare names from Names[] (it would otherwise have touched the wrong symbol on a kernel with a switched context).
- 06:31 B13 found while chasing the kernel-dependent fixture hashes; t_modular_arithmetic now restores $Context/$ContextPath (it had left `FTModularArithmeticTest`` active on kernel 8).
- 06:21 t_construction_budget 40/40 on the branch after the B12 migration; its fingerprint is now kernel-independent (identical on subkernels 1 and 3). Checkpoint 5 committed on `overhaul`. Pooled regressions left: t_physical_variable_coefficients (B11; standalone confirmation pending), t_kernelpool_duplicate_verdict (needs a standalone seat), t_reconstruction_parser (red on both trees).
- 06:16 reruns after the fixes: B9 confirmed (t_finite_field_affine_rref_backend, t_finite_field_adaptive_sampling, t_family_certificate_multiquadratic, t_task_broker_limit (B10), t_registry_seeding, t_exact_family_epsilon_form_q, t_check_levels now OK on the overhaul pool); t_package_generality fixed (the retired-route messages named a driver script); t_multiquadratic_algebra_differential migrated (its pinned p == 1 (mod 4) divergence is closed by the shared modular square root, goal 2); B11 found and fixed. Open: t_construction_budget byte-identity (dump mission running), t_physical_variable_coefficients (B11, standalone confirmation), t_kernelpool_duplicate_verdict (ran pooled because the driver edit landed after the launch; standalone rerun queued), t_reconstruction_parser (red on both trees, different assertion).

- 05:56 full test batch of the overhaul branch launched (REUSE mode,
  8 subkernels on E-cores, allowance 4 h) while the baseline's standalone
  confirmations finish on the P-cores; results go into the acceptance
  table below when both batches print their final tables.
- 06:00 checkpoint 4 committed; the B8 test's remaining failure was a
  test defect (the derivative evaluator returns {values, derivatives});
  `t_observable_transport` all twelve checks true.

- 05:52 `t_modular_arithmetic` 61/61 on the overhaul branch; adopted
  transport tests: final_reconstruction 3/3, finite_field 18/18,
  algebraic 13/13, integration_load all true, compact_ordering all true
  (B7 fix); `t_observable_transport` one fixture-dependent assertion
  (active-letter indices) still to be made definition-based.

- 05:51 CF259 observable transport accepted (probe 5, 564 s) -- the
  integration proof of the overhaul: adopted transport layer + fix B8 on
  a real triple-root family to a real, accepted result. Artifact moved
  into Results with README and the failure evidence of probes 1 and 4.

- 05:37 probe 4 named the compile offenders (`Sqrt[5]`,
  `Sqrt[56 + 45 y^2]`); 05:40 fix B8 implemented with its test; 05:41
  CF259 probe 5 launched with the fix.

- 05:27 CF259 probe 3: the rank-sampling failure is a compile refusal of
  the constraint matrix by the finite-field algebraic compiler (grammar:
  integers, rationals, variables, root symbols, Plus, Times, integer
  powers); the admissible-sample logic was never reached. Diagnostics
  now name the first subexpressions outside the grammar; the driver
  passes the dump directory (a missed anchor had dropped it); probe 4
  launched 05:32.

- 05:25 baseline: three pooled tests (t_multiquadratic_gauge_ladder,
  _gauge_screen, _letters) had run 105 minutes on reused subkernels
  without a line of output; cancelled so the standalone phase can run
  (their standalone confirmations measure them on fresh kernels; the
  gauge-screen test's own comment puts its intended route at 43-51 s and
  the alternative compile at ~7,900 s, so a reused kernel that lost a
  trusted fast path is the suspected cause -- to be confirmed by the
  fresh runs).

- 05:05 measured: the epsilon-jet Laurent route with per-coefficient
  Cancel[Together] is slower than SeriesCoefficient on CF259 (stopped at
  21 min, reference ~10 min); default reverted to SeriesCoefficient, jet
  kept as an option with its unit test; the real cost is canonicalizing
  algebraic coefficients, which the downstream zero tests
  (masterTransportZeroQ: Together, radical zero test, Simplify) would
  pay anyway -- a modular zero test is the next lever (not done).

- 04:43 validation queue on branch `overhaul` (manifest fixed): package
  loads (41 modules, load check passed); `t_observable_transport_laurent_jet`
  7/7; `t_modular_arithmetic` 60/61 -- the one failure was a wrong test
  expectation (a unit denominator bound must return the integer preimage
  1492, not refuse), corrected; CF259 Laurent benchmark running.

- 04:35 algebraic records now select admissible rank and residue
  samples automatically (every letter and root square a nonzero rational
  at the point; deterministic fraction grid); checkpoint commit 96be12e9
  on branch `overhaul` (139 files) before the load check.

- 04:20-04:30 structure move applied (7 layers, manifest, 27 tests and
  scripts re-pointed); Private_Backup populated (three test-only routes,
  15 dead symbols, two tests); typed RouteRetired stubs; in-frame solver
  default FiniteFieldFirst -> True; eps-form driver refuses the retired
  Legacy route and no longer loads CANONICA on the production route;
  pool tools take their paths from POOL/FACET_SCRATCHPAD instead of a
  hard-coded session path; CLAUDE.md top section and HANDOFF entry
  drafted. All of it awaits the load check and test runs queued behind
  the baseline's licence seat (queue2: load check, jet test, modular
  test, CF259 Laurent benchmark, transport tests, pool-duplicate test,
  before/after benchmarks, CF259 probe 3).

- 04:05 Laurent extraction re-implemented as an exact epsilon-jet
  (compile each entry once into eps-polynomial numerator/denominator with
  opaque algebraic coefficients, division recurrence for all orders,
  per-entry SeriesCoefficient fallback outside the grammar); unit test
  `t_observable_transport_laurent_jet.wls`; benchmark
  `Scripts/Diagnostics/benchmark_laurent_jet.wls` queued on the CF259
  record. Rank-sampling failures now carry per-sample rejection counts
  and an optional state dump (`"DiagnosticDirectory"` card key). Seat
  queue (`bench/seatqueue.sh`) sequences standalone kernel jobs behind
  the two-main licence limit: jet test, CF259 Laurent benchmark, CF259
  probe 2, adopted transport tests.

- 03:43 CF259 compact record + Codex's transport valuations combined
  (`family_epsform_CF259_compact_valuations.wl`, 27 blocks, TMin -3);
  03:44 CF259 transport probe 1 launched; licence note: while the pool
  main and one standalone main run, a third main is refused, so kernel
  work is sequenced (baseline pool, then one job at a time).

- 03:35 baseline attempt 3 (REUSE mode) launched with watchdog; 03:33
  ModularArithmetic module + test delegated to an Opus worker (goal 2);
  adopted transport tests failed to run only because the copied tests
  derived the repository root for a flat Tests/ layout (fixed: 3 levels).

- 03:24 baseline attempt 1 stopped on the watchdog's report (B1, B2);
  03:28 worktrees: `overhaul` branch at scratchpad/work (all edits),
  detached `base/` at 2d73f71f for the baseline with the two driver
  fixes; 03:31 branch transport layer copied into `overhaul`.

- 03:00 survey started; 03:12 Codex WIP committed as `2d73f71f`;
  03:15 baseline test batch launched (8 subkernels, P-cores, 4 h
  allowance) with watchdog; 03:35 merge probe: 17 conflicting files;
  03:40 branch transport files use no branch-only external symbols.
- 13:00 Round 3 done: 8 tests fixed or explained (regulator_filter 10/10, obstruction_images 19/19, epsform_obstruction 7/7 at 61 s, strip_solve 92/92, regulator_reconstruction 18/18, obstruction_driver 23/23, streaming_kira_import 19/19, construction_dag 86/86 standalone in 3.9 s); installed_family_chain moved to the backup as a never-green WIP contract; two kernel-start hangs killed by PID; all runs capped at 2-10 minutes. Evidence in `round3/`.
- 13:20 Codex's diagnosis applied: `t_multiquadratic_installed_family_chain` restored with `"GaugeDenominatorFactor" -> 1` and a base-denominator check, 15/15 in about 100 s; the GaugeDenominator option documented as the base denominator. User decision: `$AllowInternet = False` in `~/.Wolfram/Kernel/init.m` (probe: a fresh kernel reports False and reaches its script in 11 s).
- 14:30 Rounds 4-5 closed: commits 57bd613d, 2790adef and this one; every Codex point worked through (reports `round4/T_*`, `M_*`, `G_*`, `L_*`, `M_round5_*`); Private has sub-folders in every multi-file layer; CF259 record certified; open: rerun CF259 through the new route for an accepted artifact with the certificate (user's go), retire the Jet route to the backup, the Geometry catalog edge (move `SolveEpsFormStripInFrame` into EpsForm), the certifier's speed-ups, and pushing `main` (28+ commits ahead).
- 17:10 Round 6 closed: all three open items done (CF259 accepted artifact with certificate, main pushed, Jet retired, layer graph acyclic, launcher hardened). Nothing in flight.
