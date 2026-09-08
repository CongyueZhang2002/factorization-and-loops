> Layout record as of 2026-09-02, kept for the overhaul evidence. The current folder layout and load order are the header of `FeynFacet/Private/LoadOrder.wl`.

# FeynFacet/Private layer structure (overhaul 2026-09-02, goal 3)

The package modules live in seven subfolders of `FeynFacet/Private/`,
loaded in the order of the manifest `FeynFacet/Private/LoadOrder.wl`
(the only list of modules; `FeynFacet.m` reads it and refuses to load if
it is missing, malformed, or names an absent file). A layer may
reference only itself and the layers above it.

| order | layer | contents |
|---|---|---|
| 1 | `Core/` | `Core.wl` exact algebra, bases, metadata, installation roots; `ModularArithmetic.wl` primes, modular square roots, split points, CRT, rational reconstruction, lift-and-verify (one implementation, goal 2); `MultiquadraticAlgebra.wl` extension-field grade algebra; `RationalMaterialization.wl` rational-DAG compaction |
| 2 | `Process/` | process cards, diagram generation, topologies and cuts, dimensional shifts, collinear factorization |
| 3 | `Reduction/` | Kira reduction and streaming import, coefficient store, simplification, finite-field coefficient reconstruction, assembly, AMFlow cross-checks |
| 4 | `Infrastructure/` | `TaskBroker.wl` (pool-side parallelism) |
| 5 | `Geometry/` | `TransportCharts.wl` chart catalog and verification, the algebraic frame builder, root census, per-family chart registry, chart extension, the record-to-chart coordinate map and the record-chart resolution (Design/GeometryDeclaration_2026-09-02.md) |
| 6 | `EpsForm/` | stage 1: canonical blocks and classes, diagonal-block eps-forms, off-diagonal completion (the in-frame solver `Strip/EpsFormStripInFrame.wl`, finite-field and multiquadratic solvers, deferred block equations, gauge pull-back, installation), row gauges and resume, regulator factorization, modular family certificate, family eps-form records and certifier |
| 7 | `Transport/` | stage 2: family assembly and the Libra transport entry (`MasterTransport.wl`), word engines, the CF303 exception seam, the observable transport (production) and its finite-field coordinate reconstruction |

Superseded code is kept, never loaded, under `FeynFacet/Private_Backup/`
with its evidence in `Private_Backup/EVIDENCE.md`; tests that only
exercised moved code are under `Private_Backup/Tests/`.

Tests that `Get` or `Import` a module file directly use the layered
path (`{root, "FeynFacet", "Private", "<Layer>", "<File>.wl"}`).

Upward references: none at call time since round 7 (2026-09-02); the
symbol scan reports only two name-only references (Core matches the
public retired head `TransportWord` as a pattern; Process issues the
message `BuildSimplificationContext::invalid`), listed in the manifest
header.


## Correction 2026-09-02 07:30 (review finding D1)

Geometry loads AFTER EpsForm, not before: `TransportCharts.wl` evaluates
`Options[SolveEpsFormStripInFrame] = Join[Options[SolveEpsFormStrip], ...]`
at load time, and with the earlier order `Options[SolveEpsFormStrip]` was
still `{}`, so fifteen inherited options vanished and every finite-field
strip solve wrote its artifacts to a relative `ScratchDirectory/Tag_...`
path (the stray directories under `Tests/` were that symptom). Runtime
references between layers are unaffected by order; only top-level
evaluations are, and the manifest order is now: Core, Process, Reduction,
Infrastructure, EpsForm, Geometry, Transport.


## Correction 2026-09-02 (round 7): the D1 order is superseded, the graph is acyclic

The load-time inheritance that forced Geometry after EpsForm (D1 above)
moved WITH the in-frame solver: `SolveEpsFormStripInFrame`, its option
list and the helpers only it used (stage log, broker-parallel tasks,
deferred-bundle pullbacks, deadline bookkeeping, timings, the retired
Maple stub) are now `EpsForm/Strip/EpsFormStripInFrame.wl` (listed after
`Strip/EpsFormStrip.wl`, whose `Options[SolveEpsFormStrip]` it joins),
moved verbatim from `Geometry/TransportCharts.wl` (proof:
`Design/PrivateOverhaul_2026-09-01_evidence/round4/G_layers_geometry_scripts.md`,
section 7).  The four `observableTransport*` predicates `FamilyEpsForm`
used went down as well: the zero tests and `BlockLowerQ` to
`Core/Base/Core.wl`, `RecordChart` with `SourceFrameQ` to Geometry.  The
manifest order is again Core, Process, Reduction, Infrastructure,
Geometry, EpsForm, Transport, and the scan finds no call-time upward
reference in any layer.

Sub-folder layout (round 5), one line each -- the manifest header carries
the same list with what belongs where:

| layer | sub-folders (files) |
|---|---|
| `Core/` | `Base/` (Core.wl), `Modular/` (ModularArithmetic.wl), `Algebra/` (MultiquadraticAlgebra.wl, RationalMaterialization.wl, Radicals.wl), `Artifacts/` (Artifacts.wl), `Charts/` (ChartData.wl) |
| `Process/` | `Cards/` (Process.wl, CanonicalFamilies.wl), `Diagrams/` (Topologies.wl, DimensionalShift.wl, Collinear.wl) |
| `Reduction/` | `Kira/` (Reduction.wl, StreamingKira.wl), `AmFlow/` (MasterIntegralAmFlow.wl), `Coefficients/` (Simplification.wl, Assembly.wl, CoefficientStore.wl, Reconstruction.wl) |
| `Infrastructure/` | flat (TaskBroker.wl) |
| `Geometry/` | flat (TransportCharts.wl) |
| `EpsForm/` | `Blocks/` (CanonicalBlocks.wl, BlockEquationDeferred.wl, LibraEpsForm.wl, DiagonalBlockEpsForm.wl), `Strip/` (EpsFormStrip.wl, EpsFormStripInFrame.wl, EpsFormStripObstruction.wl), `FiniteField/` (FiniteFieldEpsForm.wl, FiniteFieldStripSolve.wl, FiniteFieldStripBroker.wl, FiniteFieldGaugePullBack.wl), `Multiquadratic/` (MultiquadraticStripSolve.wl, ...Letters, ...Screens, ...PrepareCompile, ...Sampling, ...Providers, ...Reconstruction, ...Driver, MultiquadraticInstallation.wl), `Family/` (FamilyRegulatorFactor.wl, FamilyRowGauge.wl, FamilyRowGaugeResume.wl, FamilyCertificateModular.wl, FamilyEpsForm.wl) |
| `Transport/` | `Assembly/` (MasterTransport.wl), `Observable/` (ObservableTransport.wl, ObservableTransportFiniteField.wl) |

Tests that `Get` or `Import` a module source do so through
`FeynFacet`Private`feynFacetPrivateFile["<Name>.wl"]` (either spelling),
never through a path that assumes a folder layout.
