# SIDIS LL NNLO results

Completed on 2026-09-10. Electromagnetic SIDIS integrated over transverse
momentum, with structure-function vector {2g1}. All 13 channel results
include double real, real–virtual, double virtual where present, UV
renormalization, PDF and FF counterterms. LL additionally includes the finite
Larin-to-helicity-MSbar conversion.

The final files contain explicit coefficients through epsilon^0 in the common
delta/plus/regular format. They contain no unevaluated integrations, unresolved
master integrals or solution generators. Ordinary GPLs are explicit standard
special functions. Lossless storage compression gives 1,762,089 bytes in total.

| Channel | Final file |
| --- | --- |
| q-q | [Result.wl](q-q/Results/Result.wl) |
| qbar-qbar | [Result.wl](qbar-qbar/Results/Result.wl) |
| q-g | [Result.wl](q-g/Results/Result.wl) |
| qbar-g | [Result.wl](qbar-g/Results/Result.wl) |
| g-q | [Result.wl](g-q/Results/Result.wl) |
| g-qbar | [Result.wl](g-qbar/Results/Result.wl) |
| q-qbar | [Result.wl](q-qbar/Results/Result.wl) |
| qbar-q | [Result.wl](qbar-q/Results/Result.wl) |
| q-qp | [Result.wl](q-qp/Results/Result.wl) |
| q-qpbar | [Result.wl](q-qpbar/Results/Result.wl) |
| qbar-qp | [Result.wl](qbar-qp/Results/Result.wl) |
| qbar-qpbar | [Result.wl](qbar-qpbar/Results/Result.wl) |
| g-g | [Result.wl](g-g/Results/Result.wl) |

## Validation

Every delta, plus and regular coefficient was compared with the independent
NNLO expressions at five exact parameter points. These cover all four
kinematic regions separated by x=z and x+z=1, unequal renormalization/PDF/FF
scales, and a second color/flavor/charge assignment. Agreement is about
40 decimal digits using 50-digit arithmetic. Every negative epsilon
coefficient was checked separately, including all supported distributions.
These are numerical comparisons, not a claim of a global symbolic identity
proof. No published coefficient enters production.

The finalizer additionally checks the input pole coefficients independently
of the literature and matches its exact input expressions before extracting
the finite range. Read-back checks preserve every scalar coefficient and
all result metadata. The mathematical endpoint construction was reviewed
with verified GPT-6 Pro.

- [Completion report](q-q/Results/Validation/CompletionReport.wl)
- [Point 1](q-q/Results/Validation/NNLOComparisonPoint1.wl)
- [Point 2](q-q/Results/Validation/NNLOComparisonPoint2.wl)
- [Point 3](q-q/Results/Validation/NNLOComparisonPoint3.wl)
- [Point 4](q-q/Results/Validation/NNLOComparisonPoint4.wl)
- [Color/flavor/charge check](q-q/Results/Validation/NNLOComparisonPoint5.wl)

Independent sources:
[Bonino et al., UU](https://arxiv.org/abs/2401.16281v2),
[Bonino et al., LL](https://arxiv.org/abs/2404.08597v3).
The [Haug–Wunder ancillary files](https://arxiv.org/abs/2505.18109v2)
also document the abbreviation rln2=Log[2] used in the LL reference.

## Reading and evaluating

Get["q-q/Results/Result.wl"] returns the full association using standard
Wolfram Language decompression. Coefficients[0] first separates the x axis
and then the z axis, using DeltaCoefficient, PlusCoefficients and
RegularCoefficient. Each leaf is the structure-function vector listed above.

For example, after assigning the result to result:

    result["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]

is the double-delta coefficient. PlusCoefficients[k] multiplies
[Log[1-variable]^k/(1-variable)]_+ on [0,1].
The GPL convention is G[{a1,...,an},z] with kernels dt/(t-ai).

With FeynFacet/Solution.m loaded, EvaluateGPLExpression evaluates a coefficient
with exact parameter rules. For continuation across removable seams, use
the RealLetterPrescription stored in result["GPLContinuation"].
Keep each RegularCoefficient grouped when integrating it; its individual
algebraic summands need not be integrable separately.

## Replaying the final assembly

From the repository root in WSL, both projects can be assembled again from
their saved solved bulk/face profiles with:

    python3 Scripts/finish_partonic_assembly.py \
      Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/DoubleReal/CompleteChannels/EndpointAssemblyPlan.wl \
      Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/Validation/FinalizationPlan.wl \
      --projects SIDIS_UU_NNLO SIDIS_LL_NNLO --order NNLO

This replays the final assembly, not diagram generation or a fresh master
reduction. The process-dependent inputs remain in the project cards and
the stored reduction/solution manifests. The generic endpoint, finite-order,
special-function and final-result code is in FeynFacet.

The independent check can be repeated with:

    python3 Scripts/Validation/run_sidis_nnlo_checks.py SIDIS_UU_NNLO SIDIS_LL_NNLO

The checker uses at most two Wolfram kernels. Final endpoint assembly now
takes roughly 0.1–1.5 seconds per channel, before file writing.
