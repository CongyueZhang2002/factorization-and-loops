# Phase-space denominator signs

The criterion assumes two future-directed null incoming momenta, positive
s=(ka+kb)^2, and the complete list of future-directed null final momenta
summing to ka+kb. The list includes the observed and eliminated recoil
particles. It is a physical phase-space assumption of this integration
route, not a consequence of declaring individual scalar products zero.

For R=a ka+b kb+sum_i c_i p_i with real constant coefficients, the exact
range of R^2/s on the unrestricted phase-space closure is

    min_{i != j} (a+c_i)(b+c_j) <= R^2/s <= max_{i != j} (a+c_i)(b+c_j).

The proof writes R^2/s as a convex combination of the displayed corner
values. The same nonnegative weights work for every coefficient vector.
At strictly nonsoft, beam-noncollinear and final-final-noncollinear points,
the weights can all be positive. Thus bounds of one weak sign with one
nonzero bound imply a strict sign in that interior. Every corner is attained
on the closure by p_i=ka, p_j=kb and the remaining final particles soft.
The [independent Pro review](../External/ChatGPT/Records/2026-09-08/07_phase_space_denominator_review.md)
includes the flow argument, strictness, two-body case and counterexamples.

## Implemented scope

`IdentifySafePropagator` admits exact rational multiples of real momentum
squares and bilinears P.Q for which both operands are identically null on
the stated phase space. It compares the actual inverse propagator with the
admitted square, retains its rational sign/scale, and rejects additive
mass/constant fields. In particular, bounds for Q^2 never certify Q^2-m^2.
This matters because [FeynCalc StandardPropagatorDenominator](https://feyncalc.github.io/FeynCalcBook/StandardPropagatorDenominator.html)
encodes quadratic, linear and additive mass terms in distinct fields.

A mixed global range does not establish a crossing on a fixed-angle slice.
The present implementation conservatively rejects that unsupported case.
A zero bound allows a boundary zero; two zero bounds are rejected. Symbolic
coefficients are not replaced by numerical guesses. Massive final-state
geometry and virtual-loop denominators require separate treatments.

## Denominator support through IBP

An ordinary slot with exponent zero is absent, and one with negative exponent
is a polynomial numerator. Only positive ordinary indices require this sign
criterion. Cuts retain their original defining polynomials and orientations.
The workflow checks positive support at family construction, again after
BMHV dimensional shifts, at IBP input, and on terminal masters in both import
paths. It deduplicates actual propagators before parsing.

Kira receives each distinct maximal requested sector, keeping incomparable
sectors separate instead of introducing their union. Jobs are generated from
the requested integrals. A master that activates an unsupported ordinary
slot fails acceptance. Unsupported sectors are never declared scaleless or
zero by this criterion. Family mappings and the independent cut-preservation
checks remain necessary.

## Causal and endpoint limits

A strict interior sign does not prove endpoint integrability or authorize
removing i0. Equality of prescriptions can be justified if complete terms
have a common absolutely convergent regulator domain and compatible
meromorphic continuations; dimensional regularization alone need not supply
that domain. Partial-fraction summands and dotted cuts require the applicable
term-level argument. No convergence theorem is automated by this sign check.

The null identity is used only to classify signs on the cut surface. It does
not replace family polynomials modulo cut equations: x delta'(x)=-delta(x).
Noninteger powers and logarithms retain their branch phases. The theorem
also makes no assertion along an auxiliary-mass deformation. AMFlow's
virtual prescriptions and deformation construction remain separate.

## Sufficient analytic justification for ordinary prescriptions

Let the ordinary propagator powers nu_j be positive integers. It suffices
that the complete term, paired with any required smooth test function of
observed variables, be absolutely integrable in an open regulator domain:

    integral |N(epsilon,p)| product_j |Q_j(p)|^(-nu_j) dPhi < infinity.

A locally uniform bound on compact subsets of that regulator domain gives

    |Q_j + i sigma_j eta|^(-nu_j) <= |Q_j|^(-nu_j), eta > 0.

Dominated convergence makes every choice sigma_j=+/-1 give the same integral
there. Their compatible meromorphic continuations in epsilon are consequently
identical. The convergent domain need not contain epsilon=0. For example,

    lim_(eta->0+) integral_0^1 x^(-epsilon)/(x +/- i eta) dx = -1/epsilon
    for Re(epsilon)<0,

and this common answer is continued afterward. Expanding at epsilon=0 before
the eta limit does not establish that equality. This argument concerns
ordinary denominators; the opposite prescriptions defining a cut delta
function are retained.

Equality at a generic observed momentum cannot exclude an endpoint-supported
term such as delta(1-w). Distributional equality requires pairing with test
functions including that endpoint before establishing the common dominating
integral. Dotted cuts require normal derivatives, their cut-coordinate
Jacobians and possible boundary terms to be controlled. A formal Kira IBP
relation alone is not an independent proof that boundary terms vanish.

## Certificate shared by a phase-space geometry

For a compact massless real-radiation geometry with no virtual loops, a
large-Re(D) proof can avoid separate sector decomposition of every family.
Choose an independent external frame containing the beams (and the observed
momentum for an interior fixed-observed slice). The transverse Gram matrix
of independent integrated momenta is positive semidefinite. Its determinant
G must be nonzero generically, cover every allowed denominator zero, and
actually occur in the analytic-D measure with positive D-dependent exponent.
A final-state-only Gram can miss beam collinearity; a Gram containing all
momentum-conserving vectors is identically zero. Neither suffices.

If an actual representation supplies

    dmu_D = C(D,X) G^((D-D0)/2) dmu_D0

with finite positive reference measure on a compact semialgebraic domain,
then the semialgebraic Lojasiewicz inequality bounds any finite product of
admitted inverse denominators by C G^(-N). Sufficiently large Re(D), hence
sufficiently negative Re(epsilon), makes the full term integrable. A finite
collection shares a common half-plane. All positive-semidefinite constraints
and measurement boundaries must remain in that representation. Agreement
only at integer dimensions is insufficient: the Gram-power representation
must define the integral on an open complex-D domain.

The undotted generic-kinematic certificate is now implemented and used before
real-radiation partial fractions; see
[the implementation and scope](HermitianInterferencesAndPrescriptions.md).
The complete observed-endpoint distribution and dotted-cut extension remain
separate obligations. Their physical
positive-energy cut cycle and BMHV measurement conventions must be respected.
The independent review is recorded in
[09_hermitian_interference_and_causal_prescriptions.md](../External/ChatGPT/Records/2026-09-08/09_hermitian_interference_and_causal_prescriptions.md).
