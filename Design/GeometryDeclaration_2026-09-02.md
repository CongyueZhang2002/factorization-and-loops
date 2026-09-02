# Root geometries and rationalizing charts as declared data (goal 4)

State measured 2026-09-02 (overhaul survey). The package already keys
every chart on ROOT SQUARES, never on a family name: `TransportRootSetChart`
matches a request's declared quadratics against the catalog exactly;
`FamilyAlgebraicRootCensus` reads the root squares out of a family's
class forms; `TransportFamilyChartRegister`/`Load` store a per-family
chart assignment as data in
`Results/UU_08_10_canonical/TransportFamilyCharts.wl`; the multiquadratic
solver takes its root frame as a list of `<|"Root", "RootSquare"|>`
records. No `CF<n>` appears in package code outside comments and chart
`Notes` strings.

What a new root geometry needs today, and where it lives after the
overhaul:

| Item | Today | After |
|---|---|---|
| the rationalizing chart record (`Name`, `Kind`, `Variables`, `Subst`, `Roots`, optional `Parents`, `InverseByRoots`, `Notes`) | built inside `TransportChartCatalog[]` in `TransportCharts.wl` | one record in the data file `Private/Geometry/ChartCatalog.wl`, loaded by the same function; schema documented at the top of that file |
| its exact licence (`root^2 == RootSquare o Subst`, nondegenerate Jacobian, `Parents` composition) | `TransportChartVerify` re-derives | unchanged; run over the whole catalog by `Tests/Multiquadratic/t_kallen_q4_chart.wls` and the chart tests |
| a chart that exists only for one family | `TransportFamilyChartRegister` (Results data) | unchanged |
| a new chart derived automatically from root squares | `RationalizeTransportChartExtension` (RationalizeRoots) | unchanged |
| branch/sign data of the roots at a base point | the transport card (`Path` with `BranchStatement`) and the certificate's root-frame records | unchanged; documented here as the third declared datum |

Declaring a geometry therefore means: (1) one catalog record OR one
per-family registration, (2) nothing else. Code paths that mention a
chart NAME (`"Kallen1"`, `"KallenQ4a"`, ...) outside the catalog file are
defects against this rule; the survey found none in package code (the
names occur in tests and in the `Parents` field of other records).

Open item recorded, not done: the joint-chart derivation by the iterated
pencil (the `KallenQ4a` construction) is documented in the catalog but
not automated as a generic "second conic through a rational point"
routine; `RationalizeTransportChartExtension` covers the automatic route
where RationalizeRoots succeeds.

## Where the geometry sits in the layer graph (round 4, 2026-09-02)

The Codex review of 2026-09-02 (`Exchange/Codex/2026-09-02/01_private_overhaul_assessment.md`,
"Generality") found the seven layers not acyclic: the manifest loads
`Geometry` after `EpsForm` (because `TransportCharts.wl` inherits
`Options[SolveEpsFormStrip]` at load time), while EpsForm files called
helpers defined in Geometry and Transport.  A symbol scan over the
manifest (definitions per file, references per file, a reference whose
only definitions live in a later layer is "upward") measured 55
upward symbol references in 12 files before the pass.  The shared
helpers were moved DOWN, verbatim and under their historical names:

| helper group | from | to |
|---|---|---|
| root/radical algebra of charts: `transportChartRadicalBases`, `...NumericSquareClass`, `...SquareSplit`, `...ExactSquareRoot`, `...SquareClassData`, `...DenestRadicalBase`, `...DenestSign`, `...CanonicalizeDenestedRadicals`, `...RootIndices`, `...CurrentRoots`, `...RootBranchScale`, `...ApplyRootBranches`, `...DeclaredRadicalGenerators`, `...AlgebraicZeroQ`, `transportChartRekey` | Geometry/TransportCharts.wl | Core/MultiquadraticAlgebra.wl |
| chart-record data and chain-rule pullbacks, regulator/variable resolution, radical zero tests, check level, exact-point zero test: `masterTransportChartData`, `...PullBackOneForm`, `...PullBackSystem`, `...MapTogetherSubstitute`, `...ChartRecordQ`, `...FreeSymbols`, `...RationalQ`, `...Normalize`, `...Resolve*`, `...DefaultVariables`, `...DetectRegulator`, `...Radical*`, `...SimplifyZeroQ`, `...ZeroQ`, `...ZeroMatQ`, `...Collect`, `...NormalizeWords`, `...WordFreeQ`, `...CheckLevel`, `...PointZeroQ`, `$masterTransportRegulatorNames`, `$masterTransportZeroTimeLimit` | Transport/MasterTransport.wl | Core/Core.wl |
| `masterTransportRecordCoordinateMap` (needs `masterTransportComposeTwoVariableRecord`) | Transport/MasterTransport.wl | Geometry/TransportCharts.wl |
| `masterTransportLoadLibra`, `$masterTransportLibraLoaded` | Transport/MasterTransport.wl | EpsForm/LibraEpsForm.wl |
| `FamilyArtifactRead`, `FamilyArtifactWrite`, `$familyArtifactReadMessages` | EpsForm/FamilyEpsForm.wl | Core/Core.wl |
| `coefficientAppendRecord`, `...WriteRecord`, `...ScanRecords`, `...ReadRecord` | Reduction/CoefficientStore.wl | Core/Core.wl |
| `validPreIBPResultQ` | Reduction/Reduction.wl | Process/Collinear.wl |
| `normalizeCoefficientKinematics`, `coefficientMassDimension`, `$coefficientBranchGrammars` | Reduction/Simplification.wl | Process/Process.wl |
| `taskBrokerSampleTask`, `...SampleWorkerLimit`, `...SampleBatch` (call the EpsForm sampler) | Infrastructure/TaskBroker.wl | EpsForm/FiniteFieldStripBroker.wl (new, listed after FiniteFieldStripSolve.wl) |

The manifest order is unchanged.  What remains upward, by name (the
header of `FeynFacet/Private/LoadOrder.wl` carries the same list):

- EpsForm -> Geometry, call-time catalog/registry lookups:
  `TransportRootSetChart` (BlockEquationDeferred.wl, DiagonalBlockEpsForm.wl,
  FamilyRegulatorFactor.wl), `TransportChartVerify`, `transportFamilyChartAlias`
  (FamilyEpsForm.wl).  These cannot move down: they ARE the catalog.
  The honest graph has the chart catalog below EpsForm; it sits above
  only because `SolveEpsFormStripInFrame` (an EpsForm client: it calls
  `SolveEpsFormStripFiniteField`, `VerifyEpsFormStrip`, the
  multiquadratic engine and the deferred-bundle helpers) shares its
  file and inherits `Options[SolveEpsFormStrip]` at load time.  The
  recorded follow-up, not done in round 4 (four agents editing the
  EpsForm solvers concurrently; ~1,500 lines to relocate): move
  `SolveEpsFormStripInFrame` with `transportChartPullBackDeferredBundle`,
  `transportChartPullBackDeferredPreparation`,
  `transportChartParallelJacobianPullBack`,
  `transportChartProjectionDecompose*` and its option list into an
  EpsForm file listed after `EpsFormStrip.wl`, then list Geometry before
  EpsForm; the geometry layer is then exactly the declared data of this
  note plus its verification, and the graph is acyclic.
- EpsForm/FamilyEpsForm.wl -> Transport/ObservableTransport.wl:
  `observableTransportBlockLowerQ`, `observableTransportRecordChart`,
  `observableTransportZeroMatrixQ`, `observableTransportZeroQ` (four
  predicates, ~40 lines; the zero tests wrap `masterTransportZeroQ`, now
  in Core).  Not moved because ObservableTransport.wl was owned by
  another agent in this round; the pure move is: zero predicates to
  Core/Core.wl next to `masterTransportZeroQ`, `RecordChart` (needs the
  catalog) to Geometry, `BlockLowerQ` to Core.
- Name-only: Core.wl matches the public retired head `TransportWord` as a
  pattern inside `masterTransportZeroQ`'s word branch; Process.wl issues
  `BuildSimplificationContext::invalid` (a message defined in Reduction).
  Neither is a load-time dependency; the scan reports them and they are
  accepted as such.
- `fail` in Core/RationalMaterialization.wl is a `Module`-local symbol,
  not the Process.wl `fail` (scan false positive).
