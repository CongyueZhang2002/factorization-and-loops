# Private_Backup — superseded package code, never loaded

Files here mirror the names they had under `FeynFacet/Private/` at the
time of the overhaul (2026-09-02). Nothing in this directory is read by
`FeynFacet.m`; the load manifest is `FeynFacet/Private/LoadOrder.wl`.
Every move below records the evidence that the code is not on any
production contract: the reference scan over `FeynFacet/`, `Scripts/`,
`Tests/` and `Addon/Load/` including string-constructed names
(`Symbol["FeynFacet`Private`" <> ...]`, `ToExpression`), the production
driver that used to reach it, and what replaced it.

Scan tooling (scratchpad `inventory/`): `symbol_inventory.py`
(definitions and references per symbol, string-constructed sites),
`reachability.py` (call-graph reachability from the public API, the
scripts and string-constructed names).

## Moves (2026-09-02 04:25)

| Backup file | Symbols moved | Evidence | Replacement / stub |
|---|---|---|---|
| `EpsFormStrip.wl` | `SolveEpsFormStrip` (definition; `Options` kept), `epsFormStripExactPotentialGauge`, `epsFormStripRunCanonica` (~315 lines) | production entry `SolveEpsFormStripInFrame` is called with `"FiniteFieldFirst" -> True` by `Scripts/family_epsform_sector.wls:1399`; only `FACET_STRIP_ROUTE=Legacy` reached the ladder; `t_construction_budget` replaces it by a stand-in; route_split.py: 4 route-only symbols | typed `RouteRetired` stub; in-frame default `FiniteFieldFirst -> True` |
| `TaskBroker.wl` | `taskBrokerCanonicaLadder` (~33 lines) | only caller was the moved ladder | none -- MOVED BACK 2026-09-02 06:08 (t_task_broker_limit drives it); the backup file is a placeholder |
| `LibraEpsForm.wl` | `LibraFamilyEpsForm` (definition; `Options` kept) and 8 helpers (~348 lines) | no script; one test (moved to `Tests/`); loader helpers kept for `FamilyRegulatorFactor` | typed `RouteRetired` stub |
| `TransportCharts.wl` | `transportChartMapleCanonicalGauge` (~23 lines) | `GaugePullBackMode` default is `"Exact"`; no script selects `"MapleCanonical"`; one test (moved) | typed `RouteRetired` stub; caller returns `StripGaugeMapleCanonicalizationFailed` |
| `Core.wl` | 7 legacy sparse-reduction helpers (~72 lines) | zero references anywhere (reachability.py, string-constructed names included) | none |
| `CanonicalBlocks.wl`, `FamilyCertificateModular.wl`, `FiniteFieldStripSolve.wl`, `MultiquadraticStripSolve.wl`, `ObservableTransport.wl`, `PathTransportException.wl` | one to two dead symbols each (see file headers) | zero references anywhere | none |
| `Tests/t_libra_family_eps_form.wls`, `Tests/t_maple_canonical_gauge.wls` | the two tests of the moved routes | they test only moved code | run them against the backup code by hand if ever needed |

Deliberately NOT moved (recorded per the user's rule):

- `CanonicalizeClasses` (CANONICA class ladder, ~250 lines, public): its
  test `t_canonical_blocks.wls` also covers the live decomposition and
  classification; splitting that test was judged not worth the risk
  tonight. Evidence for staleness stands (stage 1 re-derived 173/173 on the
  finite-field route, 2026-08-21).
- The Libra path-ordered transport engines of `TransportFamily`
  (~1,900 route-only lines in BlockwiseTransport.wl, CanonicalWordTransport.wl
  and the `TransportFamily` body): public entry with five tests; see
  decision U1 in Design/PrivateOverhaul_2026-09-01.md.

## Candidates and evidence (2026-09-02 03:50)

| Candidate | Evidence | Replacement |
|---|---|---|
| `LibraEpsForm.wl`: `LibraFamilyEpsForm` and its helpers | reachable only from `Tests/EpsilonForm/t_libra_family_eps_form.wls`; no script; `FamilyRegulatorFactor.wl` uses two loader helpers (`libraEpsFormLoadBackend`, `libraEpsFormFermatCompatibleQ`) which stay | the sector driver's finite-field completion + `FactorFamilyRegulatorDependence` |
| `EpsFormStrip.wl`: `SolveEpsFormStrip` CANONICA degree ladder and Maple residue route | production entry `SolveEpsFormStripInFrame` is called with `"FiniteFieldFirst" -> True` by `Scripts/family_epsform_sector.wls:1399`, which skips `SolveEpsFormStrip`; only `FACET_STRIP_ROUTE=Legacy` reaches it | finite-field affine solve (`SolveEpsFormStripFiniteField`) |
| `TransportCharts.wl`: `GaugePullBackMode -> "MapleCanonical"` branch and `transportChartMapleCanonicalGauge` | default mode `"Exact"`; no script sets the mode; `t_maple_canonical_gauge.wls` exercises it directly | `"Exact"` and `"FiniteFieldReconstruct"` modes |
| `MasterTransport.wl`: Libra path-ordered transport (`TransportFamily` engines `Monolithic`/`Blockwise`, `masterTransportVerifyTransport`, quadrature rules) | August sweep only (`Scripts/sweep_transport.wls`, `pooled_sweep.wls`, diagnostics); the sector driver uses `TransportFamilyInChart[..., "AssemblyOnly" -> True]` for assembly | `BuildObservableTransport` (88/88 ordinary families accepted 2026-09-01) |
| `CanonicalBlocks.wl`: `CanonicalizeClasses` CANONICA ladder | stage 1 re-derived 173/173 on the finite-field route (`DiagonalBlockClassCampaign`, 2026-08-21) | `DiagonalBlockEpsForm.wl` |

Kept although test-only reachable: `CanonicalWordTransport.wl` and the
blockwise helpers of `BlockwiseTransport.wl` (consumed by the CF303
exception route, `PathTransportException.wl` / `PathTransportNative.wl`).


## Corrections 2026-09-02 (acceptance batches and review)

- `taskBrokerCanonicaLadder` (TaskBroker.wl), `epsFormStripExactDLogQ` and `epsFormStripRunCanonica` (EpsFormStrip.wl) were moved back into the live tree: the reachability scan counted package callers only, and `t_task_broker_limit` / `t_canonica_scheduler` drive them directly. Rule: a symbol moves only when package AND test references are absent.


## Round 2 (2026-09-02, user decisions U1/N2/N3/N8 after the overnight overhaul)

| module | what moved | evidence | replacement |
|---|---|---|---|
| `Transport/BlockwiseTransport.wl`, `CanonicalWordTransport.wl`, `PathTransportNative.wl`, `PathTransportException.wl` (whole modules) | the Libra path-ordered transport engines (Monolithic/Blockwise), the word engines and the CF303 exception seam | `route_split.py`: reachable only through `TransportFamily` / `TransportPathArtifactRun`; no helper used by ObservableTransport*, EpsForm or Geometry | `BuildObservableTransport` on the transport-ready family record |
| `Transport/MasterTransport.wl` | `TransportFamily` (~915 lines), `TransportWord`, `TransportQuadrature`, `TransportStatus` and the derivative rules of the word/quadrature heads | same route; `TransportFamilyInChart` keeps its assembly mode (used by FamilyEpsForm.wl and the family assembly script) and answers RouteRetired for transport | observable transport |
| `EpsForm/CanonicalBlocks.wl` | `CanonicalizeClasses` and its ladder helpers, `canonicalBlocksLoadCanonica`, `canonicalBlocksToCanonica`/`FromCanonica`, `canonicalBlocksAttempt`/`Solve` (~356 lines) | CANONICA class ladder; `ValidateCanonicalForm` is CANONICA-free since the same day (letters from denominator factors, residues by exact linear solve, identity re-verified with Together) | `DiagonalBlockClassCampaign` (finite-field route) |
| `EpsForm/EpsFormStrip.wl` | `epsFormStripRunCanonica`, `epsFormStripExactDLogQ`, `epsFormStripRunCanonicaOne`, the CANONICA loader/symbol bridge and the Maple canonicalization helpers (~574 lines) | CANONICA/Maple ladder remnants; the two helpers restored on 2026-09-02 06:35 for `t_canonica_scheduler` go with that test | finite-field strip route |
| `Infrastructure/TaskBroker.wl` | `taskBrokerCanonicaLadder`, `taskBrokerCanonicaTask` | CANONICA ladder farming; `t_task_broker_limit` retired with it | broker quota logic covered by `t_broker_adaptive` |
| `Core/MultiquadraticAlgebra.wl` | `multiquadraticSplitPointQ` | no caller (user decision N8) | `modularSplitPointQ` |
| `Scripts/Backup/retired_routes_2026-09-02/` | `family_epsform.wls`, `family_epsform_maple.wls`, `sweep_transport.wls`, `sweep_launch.sh`, `sweep_pass2.sh`, `pooled_sweep.wls`, `pool_phase2.wls`, `Libra/` | drivers of the retired routes | `family_epsform_sector.wls` (Legacy branches removed the same day; pre-removal copy beside it), the observable-transport campaign scripts |
| `Private_Backup/Tests/` | t_master_transport, t_block_demands, t_blockwise_transport, t_algebraic_letters, t_canonical_word_transport, t_path_transport_exception, t_path_transport_native_order, t_chart_transport, t_transport_checkpoint, t_canonica_scheduler, t_task_broker_limit, t_canonical_blocks_canonica (sections D-I of the live test) | tests of the retired routes | the observable-transport tests; `t_canonical_blocks` keeps A, B, C, G and validates the class-form ledger |

Restored after the move: `canonicalBlocksChartParameter` (generic chart-parameter chooser; `t_generality_renamed_variables` cross-checks it against `diagonalBlockChartParameter`).

Kept deliberately: `masterTransportLoadLibra` and the Libra balance slice of `DiagonalBlockEpsForm` (production stage-1 route), `SolveResidueRationalGauge` (exact symbolic residue solver, no CANONICA), `TransportFamilyInChart` assembly mode.
