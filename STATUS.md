# Active — conventional NLO electron-positron EEC

The complete alpha_s^2 distribution is NOT finished. Continue only this
calculation; PSLQ is deferred. No subagents. At most eight aggregate CPUs and
two main Wolfram kernels. Preserve accepted lower orders, dirty/private work,
healthy jobs and read-only ~/FACET. Derive and save the complete measured result
before comparing any published measured NLO EEC hard coefficient. Universal
unmeasured scalar inputs remain separately identified.

Read Projects/EE_EEC/README.md and Reports/2026-09-18/NLOEECPhysicalCoefficients.md.
Actual GPT-6 Pro reviews37–39 are retained. Review39 accepts joint moment and
endpoint equations subject to regulator-uniform local subtraction and sufficient
constraint orders; these are not automatically satisfied by a rank calculation.

## Inspect actual jobs before launching

The gluon DE is closed, dimension96, with no minimality claim. The final
card-driven continuation took1319.726s including startup, after the direct
verified import284.043s and earlier separate reconstruction/source costs.
GluonsPhysicalBasisOptimizedState.json/log in Archive/Runs/2026-09-18/NLOEECChecks
is the current physical-basis continuation; inspect it and actual processes.
The previous physical-basis attempt timed out605.009s after reading the large
record and finding96 exact affine classes. Record traversal now batches disjoint
association updates; an already unit-cut basis is retained without another dense
candidate-selection problem. The first optimization rerun is still being timed.

At most two main kernels total. A separate standalone_nlo_qcd campaign sometimes
occupies the other licence; preserve it. Campaign auxiliary queues wait for a free
licence and use at most four CPUs while another main kernel is present. Their
state files are under Archive/Runs/2026-09-18/NLOEECChecks. Do not start duplicate
queues or rerun completed exact reductions/conversions.

## Accepted physics and remaining work

RealVirtual, two-parton Virtual/contact and Counter-UV distributions are saved.
All inclusive RR rates are explicit through epsilon^0. The inclusive sum cancels
epsilon^-4..^-1 exactly (GeneratedInclusivePoleAudit.wl,21.526s). Angular pole
cancellation and RR endpoint contacts are not established by this inclusive check.

DifferentQuarks has16 physical records covering every nonzero source column in
its18-coordinate DE. Two zero-source columns need no value. The corrected finite
interior is -5.962453423298079809... at the retained test point; the previous
-5.91645 value is invalid. Endpoint distribution completion remains.

IdenticalQuarks has a closed42-coordinate DE and43 inclusive moment equations,
all with explicit universal unmeasured scalar RHS through epsilon^0. Endpoint
scaling of the actual Gram/density excludes slopes beta>-2 in the ramified
coordinate at both ends. At rho=1-u the selected, Laurent-saturated boundary
space has20 amplitudes. The exact closed16-output subsystem has rank10.
The opposite endpoint supplies rank8 on its10D invisible subspace, leaving
exactly2 new homogeneous amplitude series beyond the known outputs. This does
not fill missing known-output epsilon tails.

The endpoint connection through epsilon^4 has all533 GPL definitions converted.
KnownOutputBoundaryAmplitudeMap.wxf is the exact closed-subsystem map.
OppositeEndpointAmplitudeConstraints4.wxf has complete matrices through epsilon^1.
PhysicalBoundaryConstraintRank.wxf establishes the exact rank8 by a matching
upper bound and nonzero minor64/27 at epsilon^1.

Regulator-uniform moment poles are now constructed from exact local Frobenius
jets, including logarithmic modes, both Jacobians and endpoint pole terms.
Starting normal depth8 and opposite depth0 are derived from actual density poles.
MomentPoles.wl automatically rejects moving regulator/endpoint divisors.
MeromorphicMomentMatricesThroughOrder0.wxf contains43x20 matrices through epsilon^0,
valid jointly with the forbidden-amplitude equations. ResidualPhysicalMomentRank.wxf
shows rows20 and43 independently determine the two remaining freedoms: leading
responses {-Q2^2/2,0} and {0,-Q2^2/2}. Required higher matrix/constraint orders
must still be propagated through the physical amplitude Laurent bounds.

All moment rows without known-output equations have leading rank15 and next
rank2 after exact GPL constant identities. An earlier apparent next rank3 was
spurious and superseded. Adding row-normalized known-output equations gives
leading rank19 and next rank1 (KnownAndMomentBoundaryRank.wxf). Its first failed
rank attempt divided zero rows by epsilon^Infinity; the corrected receipt is
IdenticalKnownAndMomentRankCorrected.json,5.667s. No constant is fixed by those rank-only files; the subsequent projected solves
below now supply the two leading orders.

KnownPhysicalBoundaryOutputCoefficients.wxf has31 accepted coefficients, one
remaining {15,0} extraction timeout; unknown tails are not zero. The fixed-path
GPL parameter limit now recovers {3,0} and{10,0} exactly by uniformly separated
letters. The remaining coefficient should be simplified locally, not expanded
into a large global pullback. Partial donor coverage is still explicit.

The joint19+1 system proves amplitudes no worse than epsilon^-4. Its leading
projection fixes only c_7,-4=-5/(4096 Pi^5 Q2^2), with every other coefficient at
that order zero. All surplus equations at the leading order agree exactly;
the other19 bounds improve to-3. PhysicalBoundaryLeadingLaurentCoefficients.wxf
retains the proof and maps (surplus run6.404s). A projected next-order calculation
needs only15 finite integrals from the656-entry order5 connection and completes
9.169s. After exact weight-two shuffle identities its value is215/(49152 Pi^5 Q2^3).
PhysicalBoundaryCoefficientsThroughMinus3.wxf now fixes all20 coefficients at-3;
all full equations through-3 and the selected delayed equation through-2 agree
(6.867s). Higher amplitude orders remain unknown.

ContractedPhysicalBoundaryOrderPlan.wxf contracts the original41 source columns
before deciding amplitude orders (170.826s). The formal source row has valuation-3,
but contracted connection orders-3,-2,-1 vanish exactly. Fourteen amplitudes are
needed through0 and six through-1; this does not imply sufficient higher connection
coefficients are already computed. Future high-order work should calculate only
the necessary matrix-vector contractions on already fixed lower coefficients.
The all-column order5 GPL attempt retained600/633 required definitions converted (656 definitions total) but timed
out on33 definitions/dependencies (579.098s). Do not simply raise all limits;
the first required contraction already reused the available15-integral subset.

Actual Pro40 inspected8b7fed8c, accepted uniform moment subtraction and the19+1
Laurent bound, and identified an assumption-sensitive moving-letter valuation.
It is repaired by specializing zero leading coefficients and proving the surviving
ones nonzero and finite. Twenty-three GPL endpoint/shuffle assertions pass0.915s.
Five incremental GPL-conversion assertions pass0.864s, seven bounded-DE/unit-basis
assertions6.568s, and52 readable/binary record assertions across five drivers pass
11.152s including startup. Current relevant code may be newer than the Pro40
revision; see git HEAD and retained review40 for its exact inspection scope.

Next: finish gluon physical-basis preparation and reuse; fix physical amplitudes with the joint
moment/endpoint/known-output system and sufficient orders; complete RR interiors,
endpoint/contact data, exact angular poles and final explicit Mathematica results.
No imported, inclusive-only, interior-only or master-only result completes NLO EEC.
All quoted successful/failed times are Python monotonic elapsed seconds including
startup. Check receipts; a completion marker alone does not certify a rank/result.

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
