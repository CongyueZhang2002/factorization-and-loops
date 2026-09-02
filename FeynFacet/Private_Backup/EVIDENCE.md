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
