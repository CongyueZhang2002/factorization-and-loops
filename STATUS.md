# Active — conventional NLO electron-positron EEC

The complete alpha_s^2 distribution is NOT finished. Continue this calculation
only; PSLQ/numerical reconstruction is deferred. No subagents. At most eight
aggregate CPUs and two main Wolfram kernels. Preserve accepted lower orders,
the dirty/private tree, healthy jobs and read-only ~/FACET. Derive/save the full
measured result before comparing a published measured NLO EEC coefficient.
Universal unmeasured scalar inputs are separately identified and allowed.

Read Projects/EE_EEC/README.md and Reports/2026-09-18/NLOEECPhysicalCoefficients.md.
The older NLOEECOvernight.md is the chronological campaign record. Completed
logs/receipts and one-off scripts are in Archive/Runs/2026-09-18/NLOEECChecks.
Current code revision before the latest point/domain repairs: d88d6195;
consult git log for their subsequent commit. Actual GPT-6 Pro reviews26–35
are retained under External/ChatGPT/Records/2026-09-18.

## Inspect these jobs before launching anything

- Gluons measured source reduction runs on CPUs0–3 through the permanent card.
  State: Projects/EE_EEC/Raw/NNLO/q-qb/DoubleReal/Work/Components/Gluons/
  MeasuredReductionState.json. Initial supervisor586559, process group586560.
  Log: Archive/Runs/2026-09-18/NLOEECChecks/GluonsMeasuredReduction.log.
  The sampled span closes after32911seeds/682466equations; exact Kira/FireFly
  reconstruction is running. A sampled closure is not an accepted reduction.
- IdenticalPhysicalOrderGPL currently converts the newly sufficient finite
  evolution on CPUs4–7. Inspect its .log/.json and actual processes. The bounded
  pass retains partial progress, so completion of the supervisor alone does
  not mean every GPL was converted.
- Old identical-quark ControlledDE and physical-provider supervisors completed.
  Do not restart earlier failed or superseded attempts. The parallel auxiliary
  runner chooses CPUs4–7 while the gluon supervisor is alive, otherwise0–7.

## Accepted physics and remaining work

RealVirtual, two-parton Virtual/contact and Counter-UV raw distributions are
accepted. All three inclusive RR rates are explicit through epsilon^0, with
all lower poles. RR+RV+Virtual+UV cancels inclusive poles epsilon^-4..^-1
EXACTLY (GeneratedInclusivePoleAudit.wl,21.526s). This does not establish
angular pole cancellation, RR endpoint contacts, or the full EEC result.

DifferentQuarks has16 physical master records sufficient for every nonzero
column of its18-entry measured DE; the other two columns vanish exactly. Its
interior is evaluated. The earlier master16 dependency bug and downstream
library/interior were repaired; original DE residuals were checked. The corrected
finite interior value at the retained internal point is -5.962453423298079809…
(the older -5.91645 is invalid). Its RR endpoints are unfinished.

IdenticalQuarks has an exact43-integral unit-cut source span for4234 original
source targets, then an exact closed42-coordinate DE. No minimality claim.
Successful DE recovery1426.822s including startup; earlier failures/preparation
remain separately counted. Its physical provider465.697s returned12 partial
records, only7/41 sufficient source requests. Feasible DE-order extension adds
four partial records in50.632s; still34 unmet full requests. Current extended
values are in Work/ExtendedPhysicalMasterOrders.wxf, not yet merged into the
original PartialMasterValues.wl. They are not a complete master result.

## Identical-quark physical solution preparation

- All43 source-basis moment insertions are constructed. Ten combinations are
  covered by retained reductions and have evaluated inclusive RHS values
  (eleven targets to six separately identified universal scalars,37.986s).
  SourceBasisMomentConstraints.wxf, DifferentialBasisMomentConstraints.wxf,
  InclusiveMomentValues.wxf retain definitions/provenance. Rank on physical
  homogeneous constants and sufficient RHS epsilon depth remain unestablished.
- Exact finite-integration preparation124.323s succeeds. The root field is
  sqrt(z),sqrt(1-z). The common rational coordinate uses u*=1/2, mapped by the
  actual root ordering to z*=9/25 with positive rational roots. This is a new
  normalization point with no assigned physical constants.
- The original distributional parent bound is -5 for all42 coordinates
  (16.424s). The separately Gram-matched fixed-fiber proof establishes scalar
  bounds -4 at generic interior kinematics (16.124s). PhysicalScalarPoleBounds.wxf
  retains the proof. Neither bound fixes constants or measurement endpoints.
- Known physical bounds plus these scalar bounds now feed the actual order
  planner: transformed evolution through epsilon^5,662 retained matrix
  coefficients. Requested original upper orders are3 for3masters,1 for13,
  0 for22 and-1 for3. Boundary requirements are retained entrywise.
  Planning17.272s; construction18.669s. PhysicalExpansionOrders.wxf and
  FiniteEvolutionPhysicalOrders.wxf contain the sufficient finite evolution
  up to constants. No physical constant or full master completion is claimed.
- A positive affine path rescaling removes artificial endpoint-dependent GPL
  letters. All438 definitions of the earlier evolution through order1 convert
  in90.623+42.789s,780 distinct GPL objects, weight<=4. The final pass allowed
  the two measured359k/519k-leaf expressions within a1million-leaf caller limit.
  FiniteEvolutionRescaledGPLThroughOrder1.wxf is complete for that limited order.
  The new sufficient physical evolution has619 definitions; its conversion is
  the active pass above.
- The known16 physical records give sampled differential-span rank16, with no
  gain from the first derivative (5.117s). Establish exact closure before
  concluding that further derivatives supply no new information. More physical
  moment/endpoint constraints are needed for the remaining directions.

Permanent recent repairs: feasible intermediate Laurent orders; both overlap
lower-bound directions; meromorphic regulator/reciprocal normalization; preserved
conic inverse metadata; explicit GPL root domains; positive affine path scaling
with tangential-log tests; full saved GPL assumptions checked after reuse; and
physical point selection for polynomial measurements in pulled-back coordinates.
The last repair preserves original physical cuts while mapping the proposed DE
point back to their measurement variable. It does not pretend a quadratic
measurement is an affine propagator. Eleven fiber/point assertions pass7.368s;
twelve GPL scale/domain assertions pass0.964s.

Next: finish exact gluon reduction; use sufficient evolution and actual physical
moment/endpoint equations to determine the missing identical-quark constants;
then complete measured gluons, original-source RR endpoint proof/contacts,
exact angular pole cancellation and explicit final Mathematica coefficients.
Do not call an inclusive, interior-only, master-only, or imported-reference
calculation a complete NLO EEC reproduction. Actual monotonic receipts include
startup; reuse and prior failed attempts must remain distinguished.

# Completed — derived normalization and observable definitions

The user authorized fixing the card audit findings with actual GPT-6 Pro review,
and requested a dedicated FeynFacet/Normalization directory. That directory now
owns shared counting, bare operator sewing, observable conventions, couplings,
momentum rescaling, flux/phase space and master-measure conversions.
See [the report](Reports/2026-09-18/DerivedNormalizations.md) and
[the module guide](FeynFacet/Normalization/README.md). All 355 authored cards load;
ordinary contributions derive their state factors. Independent derived-factor
overrides are rejected, and integrated measurements must pass exact covariance
checks before ordinary Mellin subtraction. The supported endpoint paths derive
their powers and regularity conditions from the scalar density.

Actual GPT-6 Pro completed two mathematical reviews. All 211 assertions in 16
retained tests pass, including fresh Born/current/counterterm source generation,
absolute normalization anchors, current and scattering convolutions, and the
existing EEC literature comparison. No accepted coefficient files were overwritten
and no full-project cold regeneration is claimed. No owned computation is running.

---

# Completed — production-card normalization audit

[The audit](Reports/2026-09-17/CardNormalizationAudit.md) covers all 355 authored
cards in ten projects. It identifies un-derived collinear weights/maps, trusted
current symmetry and flavor factors, independent tensor-normalization constants,
and asserted endpoint preconditions. All 48 explicit unobserved symmetry factors
agree with particle counting; all 371 result-input weights are one. A 14.010 s
single-core diagnostic confirms the symmetry-default and endpoint-assertion gaps.
Five NNLO reduction reuse paths are also stale and fall back to fresh reductions.

Production code, cards and accepted results are unchanged. This was an audit,
not an implementation of the postponed normalization overhaul or a new claim of
incorrect physical coefficients. No owned job remains running.

---

# Completed — LO/NLO high-pT coefficient delivery folder

[The package](Projects/SIDIS_HighPT_TT_SpinTransfer/Exports/SIDIS_HighPT_TT_HardCoefficients/README.md)
contains the accepted LO quark and NLO quark/antiquark coefficients, original
metadata companions and standalone Wolfram examples. Windows folder and ZIP
are in the Agentic Loops workspace. All 10 loading checks and six exact file
comparisons pass; ZIP size is 480,700 bytes. See [the report](Reports/2026-09-17/HardCoefficientPackage.md).
No production calculation was repeated, no file was sent to Curtis and no
owned job remains running. The normalization overhaul is postponed until after
the reply to Curtis, as requested.

---
# Completed — bare fragmentation operator-to-density derivation

[Derivation and code audit](Design/FragmentationNormalization.md) establish
`dz/z^(2-2 epsilon)` from the standard bare FF scalar extraction and the
longitudinal attachment-momentum Jacobian, with the observed momentum fixed.
The inspected Born/real/virtual paths use the same canonical cut tensor and
require no new scalar multiplier. Familiar stripped projectors remain valid.

[The report](Reports/2026-09-17/FragmentationNormalizationDerivation.md) records
18 independent Python check groups (1.610 s after imports), the completed
actual GPT-6 Pro review, and its incorporated color, gluon-spin, radial-bound
and matching qualifications. Production code, cards, coefficients and library
values were unchanged; no full production run was repeated. No owned job remains
running. The general automatic operator/density normalization implementation
has not been made; its mathematical basis is now explicit.

---
# Completed — direct comparison with Curtis's polarized high-pT code

[Comparison report](Reports/2026-09-17/CurtisHighPTComparison.md): all tested Born
and four real-emission amplitude sectors agree. The finite FF subtraction
difference is confirmed directly. One virtual box has an absorptive continuation
error, independently reviewed by GPT-6 Pro; its effect on Curtis's complete real
hard coefficient is not established. His full accepted polarized NLO result is
not public, so the comparison is explicitly partial at the final-coefficient level.
Production results and Curtis's checkout are unchanged. All owned checks finished;
no message was sent to Curtis. NLO EEC and further NNLO work were not started.

The [ppHX FF normalization follow-up](Reports/2026-09-17/PPHXFragmentationNormalization.md)
confirms that deleting only the dimensional FF weight spoils the independent
UU/LL qq-prime coefficient comparisons. Production files remain unchanged.

The [Zhongbo convention and Pro review](Reports/2026-09-17/ZhongboFragmentationConvention.md)
finds that his July13 NLO note retains d^(2 epsilon) in the fragmentation
convolution weight while using ordinary scalar MSbar kernels. Both source
notes and the final GPT-6 Pro assessment are saved. The proposed shared
operator/density normalization remains unimplemented pending further work;
no production coefficients were changed by this review.

---
# Completed — full leading-order QCD ee EEC

`Projects/EE_EEC/Results/NLO/q-qb/Results.wl` contains the complete
order-alpha_s EEC correction, both Born contacts and the expression through
that order. It agrees exactly with arXiv:1905.01310 Eq.21. Both Laurent poles
cancel; both moments agree with the independently generated inclusive rate.
Six native quadratic-cut masters have explicit physical values and satisfy
their DE. No unevaluated integrals or boundary constants remain in the result.

The implementation generalizes card-declared polynomial measurements, the
existing IBP/DE path, and two endpoints of one variable in the common result
format. 146 accepted assertions pass, including existing affine regressions.
Actual GPT-6 Pro reviewed the mathematical construction and full completion.
The result and metadata occupy 2,901 bytes.

[Run guide](Projects/EE_EEC/README.md) · [Completion and timings](Reports/2026-09-17/FullLOEEC.md).
The standard rerun was 51.20 s including startup with compatible
Kira/library reuse; it is not a cold benchmark. No owned process remains
running. Code is uncommitted; preserve unrelated changes. This is conventional
LO EEC (alpha_s), not conventional NLO EEC (alpha_s squared).

---
## Previous completed work

# Completed — high-pT SIDIS transverse-spin hard coefficients and code review

Both `Projects/SIDIS_HighPT_TT_SpinTransfer/Results/NLO/{q-q,q-qb}/Results.wl`
are explicit and finite, with exact symbolic pole cancellation. The quark result
includes exact removable diagonal values; direct angular epsilon extrapolation
agrees with its finite interior to better than 2e-23. No external coefficient
was used as a production input. A full external finite-NLO comparison is not
claimed. Latest paired sizes: 9,807,765 bytes and 882,302 bytes.

[Completion, stage timings and permanent fixes](Reports/2026-09-17/HighPTSpinTransferProgress.md).
The common card/raw/result path is runnable without conversation context; use
the [project README](Projects/SIDIS_HighPT_TT_SpinTransfer/README.md).
The latest assembly driver times, 87.623 s and 11.074 s, are not cold totals.
Earlier failed/interrupted attempts remain separately recorded.

Curtis's public code is cloned at
`External/Reviews/CurtisCollinsEP-2026-09-17/Code`, commit
`fef5eaa098202080dd32d51b71bff45e8d3a64c9`.
[The review](Reports/2026-09-17/CurtisCollinsCodeReview.md) derives a missing finite
FF normalization term in his documented high-pT matching and reproduces an
optional reporting-test packaging failure. It also checks the spin/Fourier
conventions, endpoint-class qualification and literal CA-kernel discrepancy.
Actual GPT-6 Pro reviewed the finite normalization. No message was sent to him.

The shared library now contains 65 values in 64 families (530,781 bytes).
The new angular seeds are published, duplicate keys were repaired, and fresh-kernel
reuse passes. No owned process remains running. The readable-record audit passes
for all 211 final-result/library records.

Code is uncommitted; preserve unrelated changes. Previously completed NLO
projects are unchanged. Integrated SIDIS NNLO and ppHX NNLO were not resumed.

---
# Historical baseline — structured shared master library, 16 September

`Library/MasterIntegrals` now uses canonical integral families, standard sector
numbers and propagator-power indexes. It contains 36 explicit physical values
in 35 families, 350,026 bytes including all metadata and README. Exact virtual
and cut momentum transformations, bounded exact IBP reuse, automatic scalar/DE
publication and partial physical Laurent-coefficient evolution are implemented.

All 117 focused and surrounding Wolfram assertions pass. All 134 NLO master
requests were found and independently recomputed without conflicts. Complete
20-master SIDIS reuse and two partial-reuse fixtures agree with all 48 stored
physical coefficients. The missing-master evolution took 0.856 s; one missing
coefficient took 0.807 s. Whole-driver times include startup/preparation and are
reported separately. GPT-6 Pro reviewed the mathematical method.

Read `Design/SharedMasterIntegralLibrary.md` for matching and solver limits.
Report: `Reports/2026-09-16/StructuredMasterIntegralLibrary.md`.
Machine checks: `Reports/2026-09-16/StructuredMasterLibraryValidation.json`.
The former flat library is retained under
`Archive/Runs/2026-09-16-StructuredMasterLibrary/LibraryBefore` only.

The independently reviewed workflow chart was already sent to Congyue Zhang's
Slack self-DM at 12:55 PM on 16 September; it was not resent.
See `Reports/2026-09-16/WorkflowReviewAndDelivery.md`.

At completion of that library task no owned process remained running. Accepted NLO hard functions and their timings
are unchanged. The NNLO endpoint/final campaign remains paused.

---
# Current calculation status — 16 September 2026

## NLO complete; stopped at the user’s request

The user explicitly requested stopping after all NLO runs and the timing table.
Do not resume NNLO without a new user instruction.

All 29 fresh NLO channels have completed. Final LL/UU reruns use corrected
monotonic clocks and valid channel timing. The 53 qq-prime and 320 Navis checks
pass; the other accepted NLO reference receipts remain valid. Two TT channels
have internal checks but no full external comparison.

| Project | Channels | Full elapsed seconds |
|---|---:|---:|
| DrellYan_UU | 6 | 40.723026906 |
| ppHX_UU | 4 | 2147.438345167 |
| ppHX_LL | 4 | 1931.672895829 |
| ppHX_TT | 1 | 42.199472640 |
| ppHX_LL_SpinTransfer | 1 | 196.053268877 |
| ppHX_TT_SpinTransfer | 1 | 433.665988701 |
| SIDIS_UU | 6 | 28.337371286 |
| SIDIS_LL | 6 | 25.933431337 |

Production campaign: `Reports/2026-09-16/FreshRegeneration/NLOClockRetimingCampaign.json`
(Active null). Validation: `NLORetimingValidation.json` in the same directory.
The finishing controller's first Navis invocation lacked its required project
names; corrected invocation passes. Its two short invocation failures are
recorded separately and are not production timings.

The final readability audit passed: 4754 records, zero errors.
The final PDF has exactly one page and was rendered and visually checked.
All 29 channel times and sizes are populated; 27 channels have passed external
comparisons and two TT entries show N/A for unavailable full references.
No production, validation or report controller remains running. NNLO was not
resumed. Work is stopped as explicitly requested.

- [One-page table](Reports/2026-09-16/calculation_status.pdf)
- [TeX source](Reports/2026-09-16/calculation_status.tex)
- [Exact table data](Reports/2026-09-16/calculation_status_data.json)
- [Completion report](Reports/2026-09-16/NLOCompletion.md)

## SIDIS NNLO: paused; wait for a new user instruction

No fresh NNLO hard function or full NNLO reference comparison is complete.
ppHX NNLO is excluded. SIDIS UU has regenerated the corrected 20-master basis,
boundaries, explicit masters and bulk coefficients. SIDIS LL NNLO is queued.

The September 10 resolved-endpoint construction was working. Fresh orchestration
omitted the certified ordinary-prescription equivalences and resolved charts;
this did not invalidate that historical mathematics. See
[the historical audit](Reports/2026-09-16/SIDISPreviousWorkflowAudit.md).

The permanent reducer repair gives 62 -> 21 -> 20 after certified prescription
equivalence and exact differential closure. Twelve regression assertions pass.
Source generation (2865.872 s) and shared IBP/DE construction (3822.950 s) remain
counted in the fresh project cost; shared work is counted once. Superseded and
failed attempts are separate. The measured current campaign and receipts are in
`Reports/2026-09-16/FreshRegeneration/RemainingCampaign.json`.

The new general `FeynFacet/Coefficients/ResolvedEndpointProfiles.wl` connects
Newton charts, physical boundary transfer, ordinary faces, exceptional faces,
interface removability and scalar uniformity. It is connected to
`Scripts/construct_ordered_endpoint_profiles.wls`, but full execution is pending.
Endpoint attempt 2 stopped before mathematical preparation because reading the
process card after solution loading reinitialized FeynArts. The driver now uses
the exact stored source definitions instead. Do not reintroduce that read.

Pro review 12 found no mathematical blocker in the displayed construction and
identified unchecked final writes. These writes now require successful paths.
Review: `External/ChatGPT/Records/2026-09-16/12_restored_endpoint_producer.md`
(actual gpt-6-pro request 32b2ee94-2d14-47b6-b633-556ac08bf9d0).

Only after the user resumes NNLO: run `Tests/Coefficients/t_resolved_endpoint_profiles.wls`
and `Tests/Infrastructure/test_endpoint_write_failure.py`, then resume the
RemainingManifest campaign from EndpointProfiles. Do not regenerate accepted
masters or restore old results. Source-generation timing must remain included.

## Execution and records

One project at a time, at most eight aggregate CPU cores and two main Wolfram
kernels. The NLO campaign is stopped; later authorized library tests are recorded separately.
Project clocks use Python monotonic time; current local clocks use Linux uptime.
All previous generated NLO/NNLO project data and saved masters were deleted on
16 September; this campaign starts from cards. Mathematical reference inputs
remain validation inputs only. Readable `.wl` and `.meta.wxf` are paired.

Earlier implementation details and superseded status are preserved in
`Archive/History/Status/BeforeNLOClockRetimingCompletion_2026-09-16.md`.
