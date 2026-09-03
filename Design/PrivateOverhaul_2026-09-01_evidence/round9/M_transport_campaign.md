# M, round 9: observable-transport campaign on the families with a certified eps-form and no accepted transport

Written as the campaign runs (2026-09-03).  Rules: no commits; the pool's main kernel is
launched through `scratchpad/bench/seat_run.sh` (two-main licence: the pool takes one seat,
agent T's runs the other); 8 subkernels; native adapter threads up to 8 more; per-family cap
1800 s; outputs in a NEW dated directory, never touching the accepted set; the main session's
Opus watchdog watches the pool (nothing armed here).

## 1. Census (step 1; one launcher run, `scratchpad/round9/census.wls`, 13 s: package load, `Get` of every transport file, `AcceptedObservableTransportQ` on each, the certified records' keys, file presence for the physical stages)

**Counts.** 91 families (`DifferentialEquations/nnlo_de_CF*.wl`).  Certified eps-form records
in `FamilyEpsFormsCertified/`: **89** (all `ExactEpsilonForm` but CF300 `ExactFrame`; missing:
CF259, CF303 -- the two triple-root families without a certified record; CF300, the third
triple-root family, was certified 2026-09-03).  The `certification_report.wl` in that directory
is dated 2026-08-20 (54 exact, 37 incomplete then); 34 of the 37 were certified on 2026-08-22
(the zero-root and two-root campaigns), CF385 and CF408 on 2026-08-29, CF300 on 2026-09-03 -- the
table gives each family's root class, certification date, record status/method and its
2026-08-20 inventory status.  Observable transports accepted by the package's current
`AcceptedObservableTransportQ`: **2** -- CF300 (`families/`, 2026-09-03) and CF385 (`families/`
and `repair_v9/`, both accepted).  The other 86 files under `ObservableTransport_2026-09-01_codex`
(copied 2026-09-02 03:55 from Codex's 2026-09-01 results; the README there says 86 exact + 2
modular) are **refused by the current predicate**: since round 4 it requires
`Certificates["FamilyInputAccepted"]`, `Certificates["TransportEpsilonValuationsBound"]` and the
epsilon-valuation certificate bound to its source (`TransportEpsilonValuationSource` /
`...Certificate` / `...Valuations`), and those keys exist only in the two accepted files (grep over
the 91 files); every file's top-level `Status` now reads `ModularlyVerifiedObservableTransport`
(CF408 `repair_v9`: `ExactObservableTransport`, also refused).  So the acceptance changed under
the records, not the records under the acceptance.  Physical stages: endpoint transports 39
families (`PhysicalEndpointTransport/`), boundary modes 39 (`PhysicalBoundaryModes/`).
CF259 has a certified transport artifact outside the accepted set
(`FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/observable_transport_2026-09-02_certified/`,
9.3 MB, `FamilyInputAccepted -> True`, valuation source `FamilyRecord`); the predicate was not run
on it in this census (it is not a target: no certified eps-form record) -- it will be run as a
pool mission during step 2 and recorded.

**Target set (certified eps-form, no accepted transport): 87 families** = the 89 certified minus
CF300 and CF385.  Not attempted: CF259 and CF303 (no certified eps-form; inventory reason:
triple-root families whose eps-form stage is the round-8 stage-1 work -- CF303 has the recorded
strict-dlog no-go, CF259's eps-form lives as a compact-valuation record under the triple-root
campaign directory, not in the certified inventory).

**Census table** (`scratchpad/round9/census.tsv`, `census.log`; "target" = certified eps-form and no accepted transport):

| family | eps-form (category) | observable transport (file status / accepted by `AcceptedObservableTransportQ`) | endpoint | boundary modes | target |
|---|---|---|---|---|---|
| CF1 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ExactObservableTransport -> False | False | False | YES |
| CF2 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF3 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF12 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF13 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF16 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF18 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF20 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF21 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF23 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF24 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF26 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF27 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF33 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF34 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF48 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF50 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF52 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF53 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF56 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF57 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF67 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF68 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF69 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF71 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF86 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF88 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF90 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF91 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF97 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF98 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF123 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF124 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF197 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF198 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF199 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF201 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF204 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF205 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF207 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF209 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF210 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF211 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF212 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF213 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF215 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF217 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF218 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF226 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF230 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF231 | two-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF232 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF236 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF240 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF248 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF249 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF253 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF254 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF258 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF259 | not certified (triple-root) | no file in the accepted set ; certified artifact FamilyEpsFormsSolving/.../CF259/observable_transport_2026-09-02_certified (ModularlyVerified, FamilyInputAccepted True, valuation source FamilyRecord; predicate not run in this census) | False | False | - |
| CF260 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF262 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF263 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF264 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF265 | two-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF267 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF269 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF299 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF300 | triple-root; certified 2026-08-29 (CertifiedEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> True | True | True | - |
| CF301 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF303 | not certified (triple-root) | no file in the accepted set | False | False | - |
| CF305 | two-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF308 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF311 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF319 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF321 | ordinary; certified 2026-08-20 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF360 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF371 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF384 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF385 | ordinary; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> True; repair_v9: ModularlyVerifiedObservableTransport -> True | True | True | - |
| CF388 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF390 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF393 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF404 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF407 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF408 | ordinary; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoExactlyCertifiedCandidate | families: ModularlyVerifiedObservableTransport -> False; repair_v9: ModularlyVerifiedObservableTransport -> False | False | False | YES |
| CF413 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF415 | zero-root; certified 2026-08-22 (ExactEpsilonForm, SectorCANONICA+ExactStripSolver); Aug-20 inventory NoCandidate | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF416 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF420 | ordinary; certified 2026-08-20 (ExactEpsilonForm, LibraFuchsifyFactorOut (E1, decision memo 2026-08-17)); Aug-20 inventory Exact | families: ModularlyVerifiedObservableTransport -> False | True | True | YES |
| CF429 | ordinary; certified 2026-08-20 (ExactEpsilonForm, None); Aug-20 inventory Exact | repair_v9: ExactObservableTransport -> False | False | False | YES |

**Census addendum (pool mission `census_cf259`, 0.8 s):** CF259's certified artifact IS accepted by
`AcceptedObservableTransportQ` (`ModularlyVerifiedObservableTransport`, valuation source
`FamilyRecord`, certificates `FamilyEpsilonFormCertified`, `FamilyEpsilonFormExact`,
`FamilyInputAccepted`, `TransportEpsilonValuationsBound`, kernels/evolution exact and certified).
Accepted transports by the current predicate are therefore three: CF300, CF385, CF259 (the last
outside the accepted directory).  The target set stays 87 (CF259 has no record in
`FamilyEpsFormsCertified/`, the census's definition).

## 2. Campaign (step 2)

- Pool: `Scripts/KernelPool.wls` started 15:13:10 THROUGH the seat launcher
  (`seat_run.sh 14400 wolframscript -file Scripts/KernelPool.wls <pooldir> 8 True`, pool
  directory `scratchpad/round9/pool`, main PID 1546246, 8 subkernels, serving at 15:13:16; the
  launcher pins the seat's 8 CPUs, which the subkernels and any native child process inherit).
  Nothing armed by me; the main session's Opus watchdog watches the pool.
- Driver: `scratchpad/round9/campaign_r9.sh` = the canonical
  `Scripts/observable_transport_kernelpool_campaign.sh` with two changes: the per-family wait is
  `FACET_FAMILY_CAP` (1800 s) instead of 86400 s, and a timed-out family is cancelled through the
  pool's `control/<mission>.cancel` and recorded `timeout` (typed, no retry); and
  `FACET_KEEP_POOL` keeps the pool alive between the first-family check and the queue.
  Family slots 6, helper seats 2 (`FACET_KERNEL_COUNT=8`).
- Manifest: `scratchpad/round9/manifest_r9.tsv`, the 87 targets in easy-first order by the
  2026-09-01 records' wall times (CF429 0 s ... CF305 212 s); inputs
  `FamilyEpsFormsCertified/family_epsform_<CF>.wl`, `DifferentialEquations/nnlo_de_<CF>.wl`,
  `MasterCoefficientValuations.wl`, no card (the accepted 2026-09-01 records name the same
  inputs).  Output: NEW `Results/UU_08_10_canonical/ObservableTransport_2026-09-03_round9/`
  (`observable_transport_<CF>.wl`, `<CF>.log` -> pool log, `<CF>.pool-status`, `campaign.tsv`,
  `campaign.log`).  The mission writes a record only if `AcceptedObservableTransportQ` holds
  (certified at construction); `exact` in `campaign.tsv` therefore means accepted.
- First-family check (before the queue): CF429 alone -- `exact`, mission wall 0.2 s,
  `ExactObservableTransport`, 2 demanded (order,row) pairs, 4 boundary coordinates, weight 1;
  one message inside the mission, `IdentityMatrix::dims` (dimension 0) -- see the note below.
- Queue launched 15:17 on the remaining 86 families.

### Campaign table (family, status, wall, cause) -- filled as the queue drains

| family | campaign status | mission wall s | record TotalSeconds | record status | cause / note |
|---|---|---:|---:|---|---|
| CF429 | exact | 0.3 | 0.02 | ExactObservableTransport | (1 kernel message(s) in the mission log, record accepted) |
| CF3 | exact | 0.7 | 0.39 | - | - |
| CF360 | exact | 0.7 | 0.41 | - | - |
| CF68 | exact | 0.8 | 0.48 | - | - |
| CF1 | exact | 0.4 | 0.20 | ExactObservableTransport | - |
| CF69 | exact | 0.8 | 0.68 | - | - |
| CF210 | exact | 0.4 | 0.26 | - | - |
| CF262 | exact | 0.4 | 0.16 | - | - |
| CF212 | exact | 0.6 | 0.52 | - | - |
| CF34 | exact | 0.4 | 0.21 | - | - |
| CF197 | exact | 0.6 | 0.39 | - | - |
| CF204 | exact | 0.5 | 0.25 | - | - |
| CF201 | exact | 0.5 | 0.35 | - | - |
| CF2 | exact | 0.5 | 0.33 | - | - |
| CF90 | exact | 0.5 | 0.33 | - | - |
| CF86 | exact | 0.5 | 0.34 | - | - |
| CF207 | exact | 0.5 | 0.33 | - | - |
| CF198 | exact | 0.5 | 0.34 | - | - |
| CF205 | exact | 0.7 | 0.45 | - | - |
| CF199 | exact | 0.6 | 0.36 | - | - |
| CF209 | exact | 0.6 | 0.42 | - | - |
| CF263 | exact | 0.6 | 0.48 | - | - |
| CF211 | exact | 0.7 | 0.49 | - | - |
| CF12 | exact | 0.7 | 0.47 | - | - |
| CF371 | exact | 0.9 | 0.70 | - | - |
| CF20 | exact | 0.8 | 0.69 | - | - |
| CF23 | exact | 0.8 | 0.56 | - | - |
| CF21 | exact | 0.9 | 0.73 | - | - |
| CF123 | exact | 0.9 | 0.79 | - | - |
| CF16 | exact | 0.9 | 0.65 | - | - |
| CF24 | exact | 0.8 | 0.62 | - | - |
| CF390 | exact | 1.1 | 0.96 | - | - |
| CF215 | exact | 1.2 | 1.03 | - | - |
| CF27 | exact | 1.4 | 1.17 | - | - |
| CF226 | exact | 1.3 | 1.08 | - | - |
| CF415 | exact | 1.3 | 1.05 | - | - |
| CF404 | exact | 1.5 | 1.34 | - | - |
| CF267 | exact | 1.7 | 1.45 | - | - |
| CF124 | exact | 2.1 | 1.82 | - | - |
| CF393 | exact | 1.7 | 1.50 | - | - |
| CF308 | exact | 1.8 | 1.60 | - | - |
| CF248 | exact | 1.2 | 1.03 | - | - |
| CF57 | exact | 9.6 | 9.33 | - | - |
| CF388 | exact | 4.8 | 4.60 | - | - |
| CF91 | exact | 1.7 | 1.46 | - | - |
| CF249 | exact | 2.0 | 1.76 | - | - |
| CF56 | exact | 5.7 | 5.50 | - | - |
| CF301 | exact | 2.6 | 2.40 | - | - |
| CF253 | exact | 6.1 | 5.92 | - | - |
| CF407 | exact | 27.4 | 27.16 | - | - |
| CF33 | exact | 11.5 | 11.21 | - | - |
| CF420 | exact | 28.4 | 28.17 | - | - |
| CF67 | exact | 2.5 | 2.43 | - | - |
| CF230 | exact | 4.4 | 4.17 | - | - |
| CF384 | exact | 36.3 | 36.06 | - | - |
| CF88 | exact | 3.6 | 3.39 | - | - |
| CF413 | exact | 40.4 | 40.17 | - | - |
| CF26 | exact | 16.6 | 16.33 | - | - |
| CF299 | exact | 34.7 | 34.42 | - | - |
| CF13 | exact | 37.1 | 36.85 | - | - |
| CF18 | exact | 39.5 | 39.23 | - | - |
| CF416 | exact | 5.9 | 5.67 | - | - |
| CF97 | exact | 11.4 | 11.10 | - | - |
| CF50 | exact | 24.7 | 24.29 | - | - |
| CF53 | exact | 35.9 | 35.67 | - | - |
| CF264 | exact | 18.0 | 17.78 | - | - |
| CF260 | exact | 45.0 | 44.79 | - | - |
| CF98 | exact | 28.1 | 27.85 | - | - |
| CF258 | exact | 40.6 | 40.18 | - | - |
| CF218 | exact | 13.5 | 13.30 | - | - |
| CF217 | exact | 14.1 | 13.88 | - | - |
| CF213 | exact | 15.1 | 14.79 | - | - |
| CF232 | exact | 22.5 | 22.29 | - | - |
| CF71 | exact | 22.1 | 21.82 | - | - |
| CF48 | exact | 60.2 | 59.83 | - | - |
| CF52 | exact | 69.4 | 69.09 | - | - |
| CF254 | exact | 99.7 | 99.37 | - | - |
| CF240 | exact | 191.8 | 191.50 | - | - |
| CF236 | exact | 93.8 | 93.49 | - | - |
| CF408 | exact | 112.8 | 112.30 | - | - |
| CF269 | exact | 101.9 | 101.49 | - | - |
| CF319 | exact | 80.0 | 79.73 | - | - |
| CF231 | exact | 80.6 | 80.15 | - | - |
| CF265 | incomplete | 170.5 | - | - | typed `DLogResiduesRequired` (`Reason -> NoProductionSymbolicFallback`) |
| CF321 | exact | 269.5 | 269.21 | - | - |
| CF311 | exact | 153.0 | 152.39 | - | - |
| CF305 | incomplete | 160.1 | - | - | typed `DLogResiduesRequired` (`Reason -> NoProductionSymbolicFallback`) |

Queue drained 15:26:34 (launcher wall 582 s for the 86 queued families; driver exit 2 = two
incomplete).  **85 of 87 accepted** (`exact` = record written after `AcceptedObservableTransportQ`),
**2 typed failures**: CF265 and CF305, both two-root families (charts Kallen13, Kallen23), both
`DLogResiduesRequired` after 170.5 s and 160.1 s; no timeouts; the two-in-a-row rule never
fired (CF311 succeeded between them).  Mission walls: 83 families under 30 s, CF231 (two-root)
and CF321 the slowest accepted at ~60-100 s; the helper broker served the harder families
(`tb_observableCovariant` tasks).  The two failures are the only families of the target set
whose records the 2026-09-01 builder (with its symbolic residue fallback) accepted and today's
production builder refuses: `ObservableTransport.wl:2925-2940` -- a missing usable dlog
decomposition is an input failure (`NoProductionSymbolicFallback`); their certified records carry
an `EpsilonFormCertificate["DLog"]` (Valid, 32 x 32 constant residues, variables {y, s}) with the
same record-level flags as the accepted two-root CF231 and CF321, so the refusal is decided inside
the transport's demand/path stage (the run works for ~165 s first); a verbose re-run of CF265
into scratch (`scratchpad/round9/diag/`, a diagnostic with the mission's `Verbose` card, not a
retry into the campaign directory) is queued on the step-3 pool and its output is reported in
section 4.  Not fixed: the builder is agent T's file.

## 3. Physical stages on the new transports (step 3)

Pool restarted through the seat launcher at 15:27:43 (serving after 7 s), same directory; one
boundary-mode mission per family (scratch copies of `Scripts/Transport/PhysicalBoundary/build_boundary_mode_campaign.wls`
and its submit script, reading `ObservableTransport_2026-09-03_round9/` instead of the 2026-09-01
directory -- the Transport scripts themselves untouched), then one endpoint mission per accepted
mode (scratch copies of `build_physical_endpoint_transport_family.wls` and its submit script,
reading the new transport and mode directories), then the summarizer as a pool mission; pool
stopped 15:30:40 (seat released).  Outputs: `PhysicalBoundaryModes_2026-09-03_round9/`
(`boundary_mode_<CF>.wl`, `campaign_summary_<CF>.wl` per family) and
`PhysicalEndpointTransport_2026-09-03_round9/` (`physical_endpoint_transport_<CF>.wl`,
`campaign_summary.wl`).  Eligible families = the 42 with structural nullity periods
(`BoundaryPeriods/Certificates/NullityPeriods.wl`) minus CF300 and CF385 (accepted before this
campaign) = 40; the physical stage is not defined for the other 45 new transports (no boundary
period realization in the ledger), which the builders would refuse as `NoActiveFamiliesSelected`.

**Result: boundary modes accepted 39 of 40, endpoint transports accepted 39 of 39**
(`campaign_summary.wl`: `PhysicalEndpointTransportCampaignComplete`, 39 families, 61 mode
realizations, `MissingFamilies -> {}`; period coefficients `KnownZero` / `Unevaluated` as in the
2026-09-03 accepted set -- no Stage-3 value certificates were involved).  CF211 refused:
`BoundaryModeMapIncomplete` / `AmbiguousPhysicalEigenspace` (block nullity 2 at the `wEdge`
stratum, dimension 14) -- the degenerate-eigenspace mode selection that is agent T's round-9
item (1); CF209 and CF260, which had no endpoint transport before, are accepted now.  Timing:
modes 0.5-6 s each, endpoint builds 1-60 s each; the whole step 3 took 3 min of pool time.

| family | boundary modes (status, chart, stratum, periods, s) | endpoint transport (Stage-3 coordinates, grades, s) | previously (2026-09-03 accepted set) |
|---|---|---|---|
| CF13 | Accepted, Kallen1, wEdge, 2, 0.7 | accepted; 2.3 s build (mission wall 2.5 s) | yes |
| CF18 | Accepted, Kallen2, wEdge, 2, 0.9 | accepted; 2.2 s build (mission wall 2.5 s) | yes |
| CF21 | Accepted, Kallen2, wEdge, 1, 0.3 | accepted | yes |
| CF23 | Accepted, Kallen2, wEdge, 1, 0.4 | accepted | yes |
| CF26 | Accepted, Kallen1, wEdge, 1, 0.4 | accepted; 1.2 s build (mission wall 1.4 s) | yes |
| CF33 | Accepted, Kallen2, wEdge, 2, 0.4 | accepted; 2.6 s build (mission wall 2.9 s) | yes |
| CF48 | Accepted, Q4b, vEdge, 2, 2.3 | accepted; 5.6 s build (mission wall 5.9 s) | yes |
| CF52 | Accepted, Q4b, vEdge, 2, 2.3 | accepted; 4.6 s build (mission wall 4.9 s) | yes |
| CF53 | Accepted, Kallen2, wEdge, 1, 2.7 | accepted | yes |
| CF56 | Accepted, Kallen1, wEdge, 3, 2.7 | accepted; 2.5 s build (mission wall 2.8 s) | yes |
| CF57 | Accepted, Kallen2, wEdge, 2, 2.5 | accepted; 1.2 s build (mission wall 1.4 s) | yes |
| CF67 | Accepted, RationalIdentity, wEdge, 1, 0.6 | accepted | yes |
| CF71 | Accepted, RationalIdentity, wEdge, 1, 0.8 | accepted | yes |
| CF90 | Accepted, source (v,w), wEdge, 1, 0.2 | accepted | yes |
| CF91 | Accepted, Kallen2, wEdge, 2, 1.0 | accepted; 0.6 s build (mission wall 0.7 s) | yes |
| CF97 | Accepted, Kallen2, wEdge, 3, 1.3 | accepted; 0.5 s build (mission wall 0.7 s) | yes |
| CF123 | Accepted, RationalIdentity, wEdge, 1, 0.2 | accepted | yes |
| CF124 | Accepted, source (v,w), wEdge, 1, 0.2 | accepted | yes |
| CF209 | Accepted, RationalIdentity, wEdge, 1, 0.2 | accepted | no |
| CF211 | BoundaryModeMapFailed | not built (no accepted mode) | no |
| CF212 | Accepted, source (v,w), wEdge, 1, 0.1 | accepted | yes |
| CF226 | Accepted, Kallen23, vEdge, 1, 0.3 | accepted | yes |
| CF236 | Accepted, Kallen12, wEdge, 2, 4.8 | accepted; 3.8 s build (mission wall 4.1 s) | yes |
| CF248 | Accepted, Kallen3, wEdge, 1, 0.4 | accepted | yes |
| CF253 | Accepted, Kallen3, wEdge, 1, 0.4 | accepted | yes |
| CF260 | Accepted, Q4a, wEdge, 1, 0.7 | accepted; 2.4 s build (mission wall 2.8 s) | no |
| CF267 | Accepted, RationalIdentity, wEdge, 1, 0.3 | accepted | yes |
| CF269 | Accepted, RationalIdentity, wEdge, 2, 4.7 | accepted | yes |
| CF299 | Accepted, Bilinear115, wEdge, 4, 1.9 | accepted; 2.0 s build (mission wall 2.2 s) | yes |
| CF308 | Accepted, RationalIdentity, wEdge, 1, 0.4 | accepted | yes |
| CF311 | Accepted, RationalIdentity, wEdge, 1, 2.0 | accepted | yes |
| CF384 | Accepted, Kallen1, wEdge, 3, 1.9 | accepted; 3.4 s build (mission wall 3.6 s) | yes |
| CF388 | Accepted, Kallen1, wEdge, 1, 1.4 | accepted; 0.6 s build (mission wall 0.8 s) | yes |
| CF390 | Accepted, RationalIdentity, wEdge, 1, 0.4 | accepted | yes |
| CF404 | Accepted, RationalIdentity, wEdge, 1, 0.6 | accepted | yes |
| CF407 | Accepted, Kallen1, wEdge, 1, 1.5 | accepted; 2.7 s build (mission wall 3.0 s) | yes |
| CF413 | Accepted, Kallen2, wEdge, 5, 2.2 | accepted; 3.3 s build (mission wall 3.7 s) | yes |
| CF415 | Accepted, RationalIdentity, wEdge, 1, 0.4 | accepted | yes |
| CF416 | Accepted, Kallen2, wEdge, 1, 2.5 | accepted; 0.6 s build (mission wall 0.8 s) | yes |
| CF420 | Accepted, Kallen2, wEdge, 1, 2.4 | accepted; 1.4 s build (mission wall 1.6 s) | yes |

## 4. Families without an accepted observable transport after this campaign, and why

| family | reason |
|---|---|
| CF259 | no record in `FamilyEpsFormsCertified/` (triple-root; its eps-form is a compact-valuation record under the triple-root campaign directory); its certified transport artifact of 2026-09-02 IS accepted by `AcceptedObservableTransportQ` (census addendum) -- it is a transport outside the accepted directory, not a missing one |
| CF303 | no certified eps-form (triple-root; recorded strict-dlog no-go, Codex note 05); T's transport route |
| CF265 | certified eps-form (two-root, chart Kallen13); transport refused typed `DLogResiduesRequired` (`Reason -> NoProductionSymbolicFallback`) after 170 s; verbose diagnostic below |
| CF305 | certified eps-form (two-root, chart Kallen23); same refusal after 160 s |

Every other family (85 of the 87 targets, plus CF300 and CF385 from before) now has an accepted
observable transport in `ObservableTransport_2026-09-03_round9/` or the accepted set.

**CF265 diagnostic** (`scratchpad/round9/pool/logs/diag_CF265.log`, verbose card, output into
scratch, 127 s): loads 0.2 s; epsilon valuations `ComputedFromGauge` 2.9 s; Laurent extraction
8.4 s (orders {0, 4}); forbidden map {61, 76}, 55 boundary slots; first covariant closure ranks
{56, 60, 60} at 44 s; boundary evolution `AmbientBasePoint`, 36714 constraint leaves, constraint
rank 39; second closure ranks 39 -> 50 -> 55 ...; then the dlog-residue stage refuses:
base constraint cancellation {55, 140} 0.2 s, base kernel {140, 85}, demanded map {6, 140}, 140
extended slots, 85 base coordinates at 126.7 s -- and the next stage, the dlog residues of the
first kernel identity, returns `DLogResiduesRequired` at once (the mission ends at 127.3 s).  So
every closure and kernel step succeeds; the refusal is the residue record: `usableDLogQ` demands
the certificate's `Dimension` (32) equal the transport's dimension and `ConstantResidues`, and
neither the computed finite-field dlog (`PointwiseReplay`, `FreshPrimeValidation`) nor the exact
route is available to this record.
The 2026-09-01 record of CF265 (`ModularlyVerifiedObservableTransport`) was built by a builder
that still had a symbolic residue fallback; today's production builder
(`ObservableTransport.wl:2925-2940`) treats a dlog decomposition it cannot use as an input
failure.  The certified records of CF265/CF305 carry `EpsilonFormCertificate["DLog"]` (Valid,
constant residues, 32 x 32, variables {y, s}) with the same record-level flags as the accepted
two-root CF231 (dimension 23) and CF321 (dimension 25); what differs is inside the transport
(dimension 32, the largest two-root strips).  Not fixed here: the builder is agent T's file;
recorded for T with the log.

## 5. Deliverable summary

- Census: 91 families; 89 certified eps-forms; accepted transports before the campaign 2 in
  the accepted directory (+ CF259's artifact outside it); the 86 records of 2026-09-01 refused by
  the current predicate (epsilon-valuation certificate binding); physical stages 39.
- Campaign: 87 targets, **85 accepted**, 2 typed failures (CF265, CF305, `DLogResiduesRequired`),
  0 timeouts, 582 s of pool wall for the queue, first family checked before the queue, the
  two-in-a-row rule never fired, every family with a typed status and wall in section 2.
- Physical stages: boundary modes 39/40 (CF211 `AmbiguousPhysicalEigenspace`), endpoint
  transports 39/39, summary `PhysicalEndpointTransportCampaignComplete`.
- Remaining without a transport: CF265, CF305 (typed refusal, cause recorded), CF303 (no
  eps-form, no-go), CF259 (accepted artifact outside the accepted directory).
- Housekeeping: nothing committed; no package or Transport file edited (all drivers are scratch
  copies under `scratchpad/round9/`); the accepted directories untouched; the pool stopped and
  both seats free at 15:30:40; no kernels running.
