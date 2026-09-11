# SIDIS NNLO double-real master-count comparison

Checked on 2026-09-11 by reading the current saved production records. This is a
comparison of counts and reduction scope, not a completed mapping to a published
basis. Real-virtual and double-virtual integrals are separate.

| Calculation or reduction stage | Double-real masters |
|---|---:|
| Our exact IBP reduction of 6,610 targets | 22 |
| Our additional exact differential relations | 20 |
| Our current nonnegative-index basis and physical coefficient vector | 20 |
| Bonino, Gehrmann and Stagnitto | 21 |
| Ahmed et al., initial LiteRed reduction | 20 |
| Ahmed et al., after two additional proven identities | 18 |

The first paper states 21 masters in 13 integral families in
[Section III, arXiv:2401.16281v2](https://arxiv.org/html/2401.16281v2#S3).
The later study starts with 20 in 13 families, then eliminates j9 and j16
using differential equations and physical boundary constants; see
[Sections II and III.3, arXiv:2412.16509v2](https://arxiv.org/html/2412.16509v2#S3.SS3).
Those two published identities are not identified with our two reductions
from 22 to 20.

## What our records establish

The [read-back inventory](q-q/Results/Validation/MasterCountComparison_2026-09-11/StoredCounts.wl)
was produced by [this inspection](q-q/Results/Validation/MasterCountComparison_2026-09-11/Inspect.wls);
its [run report](q-q/Results/Validation/MasterCountComparison_2026-09-11/RunReport.json)
records successful completion. It reads existing artifacts without rerunning
IBP reduction, solving a DE or changing any physics result.

Current source records under q-q/Results/DoubleReal/CompleteChannels:

- ExactReduction.wl has 6,610 targets and 22 distinct retained masters.
- ReducedDifferentialSystem.wl and RegularDifferentialSystem.wl each have
  20 distinct basis entries and two 20-by-20 connection matrices.
- DifferentialRelationClosure.wl records dimension 20 and saved exact checks
  of differential closure, embedding, left inverse and flatness.
- RegularPhysicalMasterCoefficients.wl and RegularScalarSolutionRequest.wl
  use the same 20-entry count. EndpointAssemblyPlan.wl has 26 UU/LL outputs.
- RegularBasisReduction.wl retains the original 22-entry Masters metadata
  alongside FinalBasisReduction; it is not the current final basis count.

The final regular system retains 12 family labels. Those labels describe our
chosen denominator bases and cannot be equated with the paper's 13 families
without an integral-definition mapping. Likewise, the 13 channel folders
in each project are partonic channels, not integral families.

## Comparison still missing

The literature counts were already discussed in the September 9 Pro review
07. A completed normalization-preserving mapping of our current basis to either
paper's integral list has not been established in the retained acceptance
records. The reduction explicitly does not assert global master minimality.

Therefore we have a solved 20-component spanning system, not a demonstrated
match to the smallest published 18-integral list. A further reduction may be
possible. Establish it by mapping the measured cut definitions, signs,
normalizations and dimensional conventions, and then checking the additional
relations with our DEs and physical boundary data. Do not delete two masters
solely to match a count.

The existing independent checks of the complete NNLO coefficient functions
remain a different test; agreement of contracted coefficients does not prove
independence or minimality of the master basis.
