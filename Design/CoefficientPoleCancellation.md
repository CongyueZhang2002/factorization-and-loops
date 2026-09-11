# Coefficient poles and common master rows

Before expanding in the normal coordinate and epsilon, form the scalar
coefficient row in a common DE basis. A pole at z=z_c(epsilon), with z_c(0)=0,
cannot be removed by taking a fixed-z Laurent series first.

The general production constructor is `ConstructEndpointCoefficientGroups`.
It finds the exact pole support, chooses a covering accepted closed system and
cancels the full coefficient row times its gauge. Candidate coverage comes from
actual powered-integral definitions, not matching family names. The bound
endpoint, Laurent bounds, physical matching and coordinate records travel with
each contribution and are checked by the scalar driver.

A source belonging to only one moving-divisor group moves as a whole when all
its terms are exact. A shared source contributes exact principal parts and keeps
its regular remainder. If a fresh coefficient was reconstructed as an exact
exceptional part plus a finite regular part, principal parts are subtracted
**only from the exact exceptional part**. The finite regular prefix and unknown
tail are unchanged. Subtracting them again from that already regular prefix is
incorrect.

The lower-level `SeparateMasterCoefficientPoles` accepts supplied exact pole
data for a whole coefficient; its finite input includes those poles. It is not
the adapter for an independently reconstructed regular prefix. The automatic
production constructor determines its fresh pieces itself and checks their
recombination and the ownership of the actual emitted inputs.

Every original coefficient has one whole owner. Exact partial pieces are
recorded once as removed and once as added. Contribution labels are independent
of mathematical family names, so several contributions can use the same saved
DE without sharing an output directory. The final merger checks this ownership
again.

A residual divisor certificate includes its tangential domain. Removing a
moving divisor does not prove that every remaining tangential divisor is
removable. The final result intersects these recorded conditions with the
requested tangential assumptions.

## Exact rational arithmetic

CancelRationalExpressions in FeynFacet/Algebra/RationalFunctions.wl uses
the FLINT rational-function backend. Build it with
FeynFacet/Backends/flint/build_rational_functions.sh.
The protocol is an uncompressed WXF pair of variable symbols and exact
rational expressions. All arithmetic is over Q with symbolic parameters;
there is no specialization to a numerical phase-space point.

SimplifyMasterCoefficientEntries preserves analytic prefactors and finite
Laurent records. Nonrational factors are restored after rational cancellation.
Additive exponent identities are first expressed using integer outer powers,
so equivalent normalization factors cannot become unrelated variables.
The moving-divisor check restores the actual endpoint values of analytic
units; in particular s^epsilon-1+z must not be misclassified as a joint unit.

The ppHX campaign uses the existing CF230 and CF231 closures for two complete
13-master pole supports. These are process input choices, not special cases
in the public functions. The residue, gauge, source-denominator and domain
certificates are retained under the process Results/Assembly directory.

RationalLaurentCoefficients expands a whole requested range in one native
call. After stripping the numerator and denominator valuations, polynomial
division uses Q_n=(N_n-Sum[D_j Q_(n-j),j=1..n])/D_0. The returned coefficients
are explicit rational functions. Analytic factors independent of the normal
coordinate belong to the coefficient field; a root depending on that
coordinate retains the general symbolic-series path. This distinction is
tested with analytic epsilon powers, external factors and a normal root.

For the last four saved-stage ppHX continuations, the normal projections and
physical scalar solutions took 47-68 seconds each after this change. These
times start from saved order plans and normal jets; they are not full family
regeneration times. All 345 coefficient contributions are now covered by
84 ordinary family results and eight complementary partial contributions.

The full distribution assembly preserves all finite definitions and writes
the full interior density minus its singular endpoint expression as the
regular remainder. Color collection acts on scalar coefficient expressions,
including any color-dependent algebraic definitions, while retaining shared
color-independent integral definitions. The original definition lists and
uncollected expressions remain in the output exactly. Numerical cancellations at a single
tangential point are diagnostic; they do not authorize removing symbolic
distribution coefficients.
