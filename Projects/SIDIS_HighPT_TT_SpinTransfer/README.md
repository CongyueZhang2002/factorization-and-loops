# Fixed high-pT SIDIS transverse spin transfer

**Completed:** the independent NLO tagged-quark and tagged-antiquark hard
coefficients are in `Results/NLO/q-q/Results.wl` and
`Results/NLO/q-qb/Results.wl`, with their `.meta.wxf` companions. Both pass exact
symbolic pole cancellation and contain explicit logarithms/dilogarithms and
rational functions, with no unevaluated integrals. The quark result includes
verified removable diagonal values.

This is the independent-azimuth moment `(T11+T22)/2` for a physical incoming
quark and observed outgoing quark/antiquark. The two stored structures are
`TransversePhoton` (average over two physical photon states) and
`LongitudinalPhoton`. An external transverse-photon sum is twice our T entry.
The inclusive collinear hard coefficient does not include a TMD matrix element,
jet matching, lepton flux or electromagnetic coupling. Flavor charges and the
powers of alpha_s are already present in the stored coefficients; do not
multiply those powers a second time.

The density is relative to `d^3 k / ((2 pi)^3 2 E_k)`. Unobserved phase space and
loops are D=4-2 epsilon dimensional; external p,q,k and spin axes are physical
four-dimensional, with BMHV gamma5. The reference operator is the physical
component of the MSbar-renormalized tensor light-ray operator. Its exact BMHV
Hodge identity fixes the pseudotensor conversion to unity; see
[operator conventions](../../Design/PhysicalTransversityOperators.md).

Kinematics:

    S = 2 p.q = Q2/x
    z = p.k/(p.q)
    (p+q-k)^2 = S (1-x)(1-z)(1-w)
    pT^2 = S z(1-x)(1-z) w

The Born endpoint is w=1. The fixed-high-pT domain is 0<x,z<1, 0<w<=1;
zero-pT boundaries require a separate calculation. Delta and plus distributions
are in 1-w. The result card's `RemovableKinematicLimits -> {x->z}` requests
exact two-sided limits; its remaining rational exceptional point is resolved
automatically. The verification is of these explicit limits, not a general
joint-limit theorem for unrelated processes.

## Standalone coefficient package

[Exports/SIDIS_HighPT_TT_HardCoefficients](Exports/SIDIS_HighPT_TT_HardCoefficients/README.md)
contains LO q-q and complete finite NLO q-q/q-qb, the original paired metadata,
and dependency-free Wolfram loading/numerical examples. It is a copy of these
accepted results with explicit normalization and distribution conventions,
not a fresh calculation. The [packaging report](../../Reports/2026-09-17/HardCoefficientPackage.md)
records loading checks, sizes and the Windows delivery copy/ZIP.

## Read the result

With the package loaded from the repository root:

```wl
hard = FeynFacet`ReadPartonicResult[
  "Projects/SIDIS_HighPT_TT_SpinTransfer/Results/NLO/q-q/Results.wl"];
hard["Coefficients"][0]["Delta"]
hard["Coefficients"][0][{"Plus",0}]
hard["Coefficients"][0]["Regular"]
```

Each value is a two-component vector in the structure order above. Framework
readers restore symbol identities from the binary companion. Plain `Get` on the
readable `.wl` displays the same mathematical expressions with unqualified names.
Keep both files together. The coefficients already include renormalization and
factorization-scale logarithms.

## Regenerate or resume

Inside `/home/maxzhang/factorization-and-loops`, supervise these through
`Scripts/wolfram.py`, with at most eight aggregate CPUs and two main kernels:

```text
Scripts/run_project_result.wls Projects/SIDIS_HighPT_TT_SpinTransfer/Results/NLO/q-q/Result_Card.wl all
Scripts/run_project_result.wls Projects/SIDIS_HighPT_TT_SpinTransfer/Results/NLO/q-qb/Result_Card.wl all
```

Use `resume` for exact matching retained stages or `assemble` to read completed
raw results. The common raw-card runner handles generated amplitudes, projection,
scalar reduction/angular integration, endpoint expansion and automatic source
counterterms. No literature coefficient is a production input. Born epsilon
orders for counterterms are inferred from the requested result and pole order;
standalone LO stores only epsilon^0. For an isolated raw contribution:

```text
Scripts/run_raw_contribution.wls Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/NLO/q-q/Virtual/Card.wl resume
```

A real card can contain components. Their work belongs under
`Raw/NLO/q-q/Real/Work/Components/<name>/Work`. Explicit diagnostic stage drivers
also accept names such as `Real.SameFlavor` through `ReadContributionCard`;
do not invent a separate `Real.SameFlavor/` path.

Fresh angular evaluation publishes its independent exact seed functions to
`Library/MasterIntegrals`. Existing retained angular values can be published with
`Scripts/publish_angular_masters.wls ANGULAR_DENSITY.wl REPORT.wl`. The library
contains scalar integrals and their physical conventions, not endpoint contacts.

## Normalization and checks

At finite epsilon the stored object is the amputated cut tensor evaluated at
physical external momentum, with canonical dimensional unobserved phase space
and no observed-state integration. The label `per physical d3k` describes the
final observable; it does not define a different all-epsilon bare pairing.
The [operator derivation](../../Design/FragmentationNormalization.md) connects
this raw definition to the standard bare scalar FF and yields
`d zeta/zeta^(2-2 epsilon)`. Its epsilon-dependent factor produces a finite
`2 log(zeta) P_T(zeta)` term under a pole, independently of gamma5 conversion.
The same cut normalization applies to Born, real and virtual, with no added
transverse-density multiplier. Counterterms regenerate their own source;
they do not read the standalone LO result folder.

[The derivation report](../../Reports/2026-09-17/FragmentationNormalizationDerivation.md)
records 18 inexpensive independent checks and completed GPT-6 Pro review.
It changes no saved production result and is not a new full NLO comparison.

Run `Tests/Physics/t_highpt_hard_functions.wls`,
`Tests/Physics/t_highpt_quark_poles.wls`, and
`Tests/Physics/t_highpt_antiquark_finite.wls` under the same supervisor. The first
checks both saved coefficients, diagonal values, and the quark finite interior
against unexpanded exact angular values. The last checks the new antiquark
channel, including a near-threshold diagonal point. Pole cancellation alone
does not verify finite scheme or normalization terms.

External comparisons: corrected Born in hep-ph/0602188 Appendix A, one-loop
helicity amplitudes in 0904.2665, and an exact nontrivial antiquark tree point
from Curtis Zhou's public code. There is no full external finite-NLO comparison.
See [completion and timings](../../Reports/2026-09-17/HighPTSpinTransferProgress.md)
and [Curtis code review](../../Reports/2026-09-17/CurtisCollinsCodeReview.md).

## Direct comparison with Curtis's public code

The [17 September component comparison](../../Reports/2026-09-17/CurtisHighPTComparison.md)
checks all 45 physical Born tensor components, the exact dimensional Born moment,
four real-emission sectors at rational points, eight ordinary cut masters, seven
virtual masters, and the actual PDF/FF counterterms. Born and tested real amplitudes
agree. The finite FF subtraction mismatch is confirmed directly. One virtual box
has an absorptive continuation error; it is not evidence by itself of a different
real hard coefficient. His complete accepted polarized output is not public,
so no full finite-NLO comparison is claimed. The scripts and records remain under
`External/Reviews/CurtisCollinsEP-2026-09-17/Comparison`.
