# Collinear benchmark campaign, 2026-09-08

Completed 2026-09-10. All requested NLO outputs and full SIDIS NNLO UU/LL
outputs have independent full finite comparisons. The last missing NLO qg LL
comparison now passes against public Navis for both observed tags, including
all distribution components. SIDIS has all 26 explicit final files and its
five-point independent reference checks pass. See STATUS.md and the process-owned
Campaign.json for current counts and limitations. The progress sections below
are historical.

The user authorized overnight implementation and calculation, stopping after complete
transverse-momentum-integrated electromagnetic SIDIS NNLO UU/LL. No TMD work and no full NNLO pp->hX in this campaign.
No subagents. Use eight total cores/subkernels and at most two main Wolfram kernels.
The existing five-minute thread heartbeat continues this campaign.

## Scope and completion

1. Keep the completed qqprime NLO UU/LL calculation as a regression.
2. Generate qqbar -> observed distinct-flavor qprime + X at NLO UU/LL.
3. Generate qg -> observed q + X and qg -> observed g + X at NLO UU/LL;
   enumerate every real final state, identical-particle weight and lower-order dependency.
4. Inclusive photon-mediated unpolarized Drell-Yan d sigma/dQ^2 at NLO,
   integrated over pair transverse momentum, rapidity and lepton angles.
5. Electromagnetic SIDIS integrated over hadron transverse momentum at NLO
   UU (transverse/longitudinal structure functions) and LL (g1, unpolarized FF).
6. Complete the same SIDIS observables at NNLO, all partonic channels and scales.

A benchmark is complete only when the card-driven general workflow generates
the full finite hard function with exact cancellation of distribution poles,
sufficient epsilon coverage, no unknown constants or unevaluated integrals,
and independent coefficient or suitably integrated reference checks.
Reference ancillary files and AMFlow values must never become production input.
Permanent reusable code is the deliverable. Do not substitute literature hard
functions into production or infer a generated result from a helicity identity.

## Architecture gaps established from source inspection

- NLO currently runs one real setup. Real cards need complete component
  enumeration/aggregation with flavor multiplicities, tags and ghost handling.
- Counterterm enumeration supports q/qbar/g and explicit Born file paths, but
  new channels require automatically generated complete declared dependencies.
- Current physical compiler assumes two incoming massless colored partons,
  one observed massless parton and a fixed recoil. Colorless current projectors
  and measurement constraints must be separate from permanent diagram algebra.
- Current NLO hard-function evaluator stores through epsilon0 only. NNLO
  convolutions require deeper lower-order inputs, with actual pole-aware bounds.
- SIDIS needs a spacelike current, x/z measurement constraints, mixed real/virtual
  masters and two-variable distributions including corners.
- Complete NNLO UV/PDF/FF factorization is missing; schemes must use the corrected
  flavor basis, not the obsolete singlet-assignment prescription.

## Review and references

Verified GPT-6 Pro architecture review requested through External/ChatGPT.
Pending prompt: Codex/General/ChatGPT/pending_benchmark_campaign_prompt.md.
Actual remote: https://github.com/CongyueZhang2002/factorization-and-loops;
the dirty local tree is ahead and must be preserved.
INCNLO original source is installed under External/References/ppHX_NLO.
The validation wrapper supports the source-defined channels. From stru.f: annihilation is J0=5,
qg observed same quark is J0=13 and qg observed gluon is J0=14.
The color denominator CC is taken from cdel.f: CA^2 for quark pairs,
CA(CA^2-1) for qg, and (CA^2-1)^2 for gg. The selected tag conventions
are verified for indices 1, 5, 13, 14; no normalization is fitted.
SIDIS references: arXiv:2401.16281v2 ancillary.inc (UU), arXiv:2404.08597v3
ancillary_pol.inc (LL), and JHEP03(2026)109 flavor-basis scheme corrections.
These are independent test data.

## Current work

Completed distinct-flavor annihilation NLO UU and incoming LL from cards.
Fresh complete times: 148.57 s and 161.47 s including process startup.
32 independent INCNLO coefficient values and four exact LL=-UU identities pass.
The existing qqprime UU result passes all 32 INCNLO checks with the new driver.

The general real-state enumeration and collinear dependency planner now retain
same-flavor exchange diagrams, sum only unobserved equivalent flavors, and reject
a missing flavor representative. Quark-gluon observed-quark and observed-gluon
UU/LL cards have been provisioned; their sequential full campaign is running.
See the process-owned ProductionRun.json and ProductionRun.log files.

The observed-gluon Born dependency originally exhausted memory after 511 s.
A missing kinematic-assumption helper and unsimplified positive monomial roots
were responsible. The fixed producer evaluates the declared physical region,
normalizes powers only on proved positive branches, and applies the declared
color identities before the expensive simplification. A fresh qqbar->gg Born
through epsilon1 takes 16.63 s and has no spurious momentum-fraction dependence.
Aborted and failed arithmetic is now rejected by the common result validator.

The existing ExtractEndpointDistributions entry point now accepts
EndpointGeometry -> "NormalCrossings". It expands jointly smooth factors on
rectangular charts with simple endpoint poles, including separate corner,
edge and regular epsilon demands, through explicit finite coefficient records.
It reuses the existing moment, Laurent-product and omitted-tail infrastructure.
Thirteen tests pass against exact regulated moments, endpoint permutation,
nonunit intervals and missing-order/overlap rejection. This is infrastructure;
it is not yet a generated SIDIS coefficient or a general sector-resolution engine.
The common physical-result adapter still needs extension for this tensor basis.

GPT-6 Pro review is retained in
External/ChatGPT/Records/2026-09-08/18_collinear_benchmark_architecture.md.
A follow-up is pending on exact-D current normalization and partonic spin-density
operators for an integrated tagged momentum. The review explicitly identifies
the remaining off-shell RV, two-loop VV, measurement-cut and flavor-matrix
factorization work; completion of those must be demonstrated independently.


## 2026-09-09 continuation

Active calculations now live in Projects/. The campaign state is
Projects/ppHX_UU_NNLO/NLO/qqp-qqp/Results/Validation/CollinearBenchmarkCampaign/Campaign.json.
All absolute text/binary reduction paths were relocated, and all 17 stream
manifests validate. The observed-quark qg UU result is complete, with 32/32
independent INCNLO coefficient checks. Remaining qg runs await the optimized
pure-gluon Born dependency.

Physics/CurrentTensors.wl now generates electromagnetic current amplitudes
through the shared converter, with wavefunction amputation before contraction.
The normalized spin-density operation in CollinearFactorization.wl uses the
PDF/FF definitions from Distributions.wl. Eight new generated-vertex checks
fix charge, incoming color average, exact-D transverse/longitudinal Born
normalization, quark/antiquark helicity signs and the off-shell Ward identity.
These are generated Born building blocks, not full SIDIS hard functions.

## 2026-09-09 continuation

The incoming-LL project explicitly uses ka as the polarization reference of
an observed gluon kc. The operator dual direction is unchanged. The dot
product is -t/2, nonzero on the declared physical domain and throughout the
recoil endpoint at fixed 0<v<1. The shared card reader filters this reference
out of channels without an observed gluon. Prior exact Born comparisons and
the universal projector-difference Ward identity validate the choice; the
full incoming-LL qg benchmark remains required. The active UU observed-gluon
calculation retains its original reference for the independent comparison.

The actual UU observed-gluon fraction failure required both IBP and the
declared SU(N) color identity. This is corrected after assembling common
master coefficients. An exact coefficient identity does not turn the
underlying finite-field reconstruction checks into deterministic proofs.

SIDIS current ingredients are generated by the shared diagram converter.
The two-particle measurement and one-particle Born Jacobian are derived from
cards. Real coefficients retain the exact Gamma/scale factors and evanescent
angular moments; the endpoint API specifies support away from opposite faces.
One-loop virtual scalar functions come from Dirichlet Gamma integrals,
including the FeynCalc pi^(-epsilon) convention conversion. The LL virtual
numerator uses rotational averages of powers of the evanescent loop square,
rather than a four-dimensional loop substitution. Pro review is pending for
this general extension.

Complete current PDF/FF counterterms, pole cancellation, NLO literature
comparison, and all NNLO components are still in progress. No benchmark hard
function or reference master value is a production input.
