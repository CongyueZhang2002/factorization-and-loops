# Project cards and partonic results

A project has one `card.wl` containing shared physics, the ordered parton
channel catalog, declared orders, kinematics, normalization scales, subtraction
schemes and execution settings. Calculation files use Wolfram Language.

```text
Projects/ppHX_UU_NNLO/
  card.wl
  LO/
    qqp-qqp/Cards/Born.wl
    qg-qg/Cards/Born.wl
  NLO/
    qqp-qqp/
      Cards/Real.wl
      Cards/Virtual.wl
      Cards/Counterterm.wl
      Results/Result.wl
  NNLO/
    qqp-qqp/
      Cards/DoubleReal.wl
      Geometry/
```

LL and TT use separate projects; both incoming quarks are polarized, with
unpolarized fragmentation. The NNLO project currently declares a bare
double-real contribution. Missing real-virtual, double-virtual and NNLO
counterterms are not treated as zero.

## Cards

`ReadContributionCard[channelDirectory,name]` combines the root and contribution
associations recursively. Association members merge; lists and scalar values
replace defaults. `ReadProcessCard` compiles the physical amplitude setup
and derives the complete diagram selection without modifying input files.
Select the components of `DoubleReal.wl` as `DoubleReal.Gluons` and
`DoubleReal.Ghosts`. Their assembly weights are explicit in that one card and checked against the
particle content. The existing assembly derives and applies each weight once.

The channel catalog explicitly records the ordered incoming pair, observed
parton and recoil. Radiation belongs to the contribution. Spin assignments
follow physical roles; replacing a quark by a gluon also changes its PDF/FF
species. No spin-transfer result is reused for incoming TT.

Each NLO channel needs three cards. A counterterm card contains, for example:

```wl
<|
  "Contribution" -> "Counterterm",
  "EpsilonRange" -> {-1, 0},
  "Include" -> {"UV", "IncomingA", "IncomingB", "Observed"},
  "LowerOrderResults" -> <|
    "qqp-qqp" -> <|
      "File" -> "../../../LO/qqp-qqp/Results/Result.wl",
      "EpsilonRange" -> {0, 1}
    |>,
    "qg-qg" -> <|
      "File" -> "../../../LO/qg-qg/Results/Result.wl",
      "EpsilonRange" -> {0, 1}
    |>
  |>
|>
```

Paths are relative to the card's directory, independently of the working
directory. A dependency can point to another filename under its declared LO/channel/Results directory.
The declared channel controls its producer.

`PlanNLOProject` resolves the effective schemes before enumerating nonzero
kernels. Custom finite kernels can introduce additional LO channels; missing
channel declarations or dependencies fail explicitly. A contribution may
override just one nested field:

```wl
"Counterterms" -> <|
  "FactorizationScalesSquared" -> <|"IncomingA" -> alternativeMuF2|>
|>
```

The other scales inherit from the root. `KernelParameters` stays one readable
row. `WriteProjectCard` supplies the same formatting for future cards.

## Epsilon orders and result identity

Finite NLO counterterms have a simple epsilon pole. A target through epsilon^m
requires Born coefficients through epsilon^(m+1), including D-dimensional
convolution weights. The planner checks the card's declaration. The producer
computes the maximum of its Born request and the consumer's declared range;
the reader rejects insufficient saved coverage. Born cards can request
higher powers explicitly.

This rule applies to NLO counterterms, not a virtual representation with double
poles. The NLO real/virtual analytic driver currently supports finite output
through epsilon^0 and rejects deeper requests.

Physical contributions and completed order/channel results all use
`FeynFacet-PartonicResult`:

```wl
result["Coefficients"][epsilonPower]["DeltaCoefficient"]
result["Coefficients"][epsilonPower]["PlusCoefficients"][logPower]
result["Coefficients"][epsilonPower]["RegularCoefficient"]
```

Metadata includes `EpsilonRange`, certified `LaurentLowerBound`,
`DimensionalRegulator`, `Order`, `Contribution`, channel/spin identity, `Scale`,
`Variables`, `DensityConvention`, `DimensionalPrefactor`, and `DistributionBasis`
(variable, endpoint, interval, distance). Physical coupling powers are included.
The present NLO convention defers only the map-independent common
`(muR2)^(p epsilon)` for Born power p. It is recorded outside the epsilon
coefficients. Invariant-dependent factors stay inside the coefficients.

LO stores the delta(1-w) coefficient
b(s,s(v-1),-s v;epsilon)/(s v). Counterterm convolution reconstructs the invariant
Born coefficient on its support using the mapped Born invariants, retaining
the constraint Jacobian and the FF weight xi^(-2+2 epsilon). This is the
physical convolution on the common result, not a file adapter.

`CombinePartonicResults` requires matching coordinates, density convention and
dimensional prefactors. Missing coefficients are zero only below a certified
Laurent bound; a partially stored epsilon window cannot be silently padded.

NNLO endpoint assembly writes the same coefficient fields through
`PartonicResultFromEndpointDensity`. Its actual coordinate and interval remain
explicit. Closed finite shared definitions are retained once. The request must
state the physical density convention. Incompatible bases fail combination.
Delta derivatives or stronger generalized plus distributions require an explicit
extension and are rejected by this standard delta/logarithmic-plus constructor.
Intermediate reduction and DE records remain mathematical working data.

## Running

From the repository:

```sh
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_UU_NNLO qqp-qqp all
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_LL_NLO qqp-qqp all
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_TT_NLO qqp-qqp all
wolframscript -file Scripts/Validation/check_nlo_qqprime_references.wls
```

`assemble` reuses amplitudes/reduction and recomputes physical contributions.
Missing or insufficient LO dependencies are regenerated. Final output is
`Projects/<project>/<order>/<channel>/Results/Result.wl`; individual contributions use
`Results/{Real,Virtual,Counterterm}/Result.wl`. Kira and reconstruction workspaces
preserve the complete owner path and contribution.

For NNLO upstream generation:

```sh
wolframscript -file Scripts/regenerate_pairs.wls Projects/ppHX_UU_NNLO/NNLO/qqp-qqp DoubleReal.Gluons DoubleReal/Gluons/Amplitudes 8
```

The three old projects and duplicate NLO-specific drivers are archived. There
is no production old-card loader or result migration. Historical test data
explicitly names its archive. The full NNLO computation has not been
regenerated as part of this layout change.


## Polarization by physical leg

The root `Polarization` association is the sole spin declaration:
`<|"Incoming"->{"L","U"},"Observed"->"L"|>` for longitudinal transfer.
`SpinParameters` supplies helicity symbols and transverse vectors. The compiler
derives HadronLongSpin, HadronTransSpin, DistributionFactor, and
SetDistributionZero from those declarations and the actual quark/gluon species.
Counterterm enumeration consumes the same Polarization object; the observed
leg is no longer assumed unpolarized. Collinear gluon transversity fails explicitly.

The five requested calculations are UU, incoming LL and TT, and LL/TT spin
transfer from incoming A to the observed outgoing quark. UU is shared.
The LL transfer project selects HelicityMSbar for both polarized quark legs;
the TT transfer project selects MSbar without a helicity-restoring term.

The time-like helicity restoration follows Stratmann and Vogelsang,
[hep-ph/9612250, Eq. (47) and the following discussion](https://arxiv.org/pdf/hep-ph/9612250).
See [the GPT-6 Pro review](../External/ChatGPT/Records/2026-09-08/17_spin_transfer_workflow.md).
The helicity-conservation and soft-limit identities are tests, never replacement
rules for generated amplitudes or fitted corrections to final coefficients.


## Intermediate storage and algebra

Generated pair records use lossless compression inside Get-readable Wolfram
files; final small physical results remain ordinary associations. Compression
stores the complete expressions and never reconstructs coefficients on demand.
The coefficient reconstruction entry points now produce
FeynFacet-MasterIntegralCoefficients directly. The version-8 input conversion
is retired. Finite reconstructed zero prefixes retain their unknown higher tail.

Dimensional-shift monomials use structural zero pruning. Unproven zeros remain
in the exact sum until rational coefficients are aggregated over masters.
This avoids repeatedly proving that large intermediate coefficients are nonzero.
On the full-azimuth TT-transfer interference {4,5}, the previous run exceeded
13 minutes; the profiled revised calculation completed in 34.52 seconds.
A separate TT interference agreed exactly with the previous algorithm.


The supplied helicity spin parameters are {1,1,1}: the coefficients of g1/G1
use unit helicity projectors. Arbitrary transverse vectors and azimuths remain
explicit. A symbolic helicity magnitude would be an extra polarization weight,
not a change to the partonic coefficient or a finite counterterm.


## Several measured endpoint variables

The same FeynFacet-PartonicResult can carry a tensor product of endpoint
distributions. DistributionBasis["Axes"] lists each axis in order, with its
Variable, Distance, Endpoint and Interval. At each axis the existing
DeltaCoefficient, PlusCoefficients and RegularCoefficient fields repeat;
only the final axis contains scalar coefficient functions. Thus the coefficient
of delta(1-x) times [1/(1-z)]_+ is
Coefficients[n]["DeltaCoefficient"]["PlusCoefficients"][0]. This records a
finite coefficient explicitly and contains no delayed generator.

CreatePartonicResultFromEndpointExpansion converts the explicit normal-crossing
endpoint expansion into those fields. Each axis declares NormalVariable and
its distance from the physical endpoint. The current conversion requires unit
absolute Jacobian, so x and 1-x are supported on [0,1]; arbitrary rescalings must
first include their exact measurement Jacobian. Unprojected variable-dependent
delta/plus coefficients and multiple distributions on one axis are rejected.
The common reader, epsilon-range requirement, scalar mapping and contribution
sum apply to either one axis or the recursive tensor product. No change of
result representation is needed between LO, NLO and NNLO of the same observable.
