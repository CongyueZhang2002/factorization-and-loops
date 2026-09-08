# Coefficient poles and common master rows

Before expanding in the normal coordinate and epsilon, form the scalar
coefficient row in a common DE basis. A pole at z=z_c(epsilon), with z_c(0)=0,
cannot be removed by taking a fixed-z Laurent series first.

For a simple pole, retained source reduction identities determine a residue
row r. An exact relation r T(z_c)=0 proves cancellation in the normalized
scalar row c^T T. The physical input may contain finite coefficient jets:
subtract their reconstructed exact pole parts, retain their declared unknown
tail, and supply these pole parts in the common exact row. Keep the other
exact coefficients together when possible; splitting all of them separately
can introduce unnecessarily deep epsilon poles.

SeparateMasterCoefficientPoles is process independent. Its input consists of
a canonical coefficient entry, identified exact residues, and a source
certificate which covers every coalescing divisor. It returns the finite
remainder and exact pole entries. The order planner propagates the removed
and restored pieces through scalar projection and explicit physical solution.
The final merger rejects missing, duplicated, or changed pieces, in addition
to requiring complete master coverage.

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
