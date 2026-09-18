# Two resolved particles in massless four-body phase space

The physical coordinate construction is implemented by
`MasslessPairPhaseSpaceCoordinates`; actual Pro mathematical review17 confirmed
its normalization, scalar-invariant coverage and angular continuation. The generic
`ConstructPhaseSpaceMeasurementPushforward` retains all proved simple physical
roots and exact Jacobians. `EvaluatePairMeasurementEulerMaster` evaluates the
supported angle-independent polynomial periods through explicit beta/Gauss
functions. Positive ordinary powers require the shared original-product prescription certificate and a nonempty initial Euler convergence domain. This does not
complete general four-body integration or endpoint continuation. No measured
literature hard coefficient enters the derivation.

Take q=sum p_i, q^2=s>0, p_i^2=0, D=4-2epsilon. Integrate overall rotations,
but keep scalar invariants. With particles1,2 resolved, define

    x1 = 2q.p1/s = x,
    x2 = 2q.p2/s = (1-x)y/(1-z*x),
    z  = s (p1.p2)/(2(q.p1)(q.p2)),
    rho = (q-p1-p2)^2/s = (1-x)(1-y).

The positive-energy interior has x,y,z in(0,1). The recoil condition gives
x2<(1-x)/(1-z*x). This is a kinematic pair angle, without an observable weight,
pair multiplicity, symmetry factor, amplitude or measurement delta.

Let R=q-p1-p2, A=R.p1=s*x1*(1-z*x2)/2,
B=R.p2=s*x2*(1-z*x1)/2. In the recoil rest frame define

    cpsi = 1 - R^2 (p1.p2)/(A B),
    c = 1-2a, h = 1-2b,
    p1.p2 = s*z*x1*x2/2,
    p1.p3 = A*(1-c)/2, p1.p4 = A*(1+c)/2,
    p2.p3 = B*(1-c*cpsi-sqrt(1-c^2)*sqrt(1-cpsi^2)*h)/2,
    p2.p4 = B-p2.p3, p3.p4 = s*rho/2.

The normalized recoil angular measures are

    a^(-epsilon)(1-a)^(-epsilon)/B(1-epsilon,1-epsilon),
    b^(-1/2-epsilon)(1-b)^(-1/2-epsilon)/B(1/2-epsilon,1/2-epsilon).

The standard Lorentz-invariant convention is product d^(D-1)p/
[(2Pi)^(D-1)2E] times (2Pi)^D delta^D(q-sum p).
Using the two resolved one-particle measures times dPhi2(R) gives the
five-variable density

    C(epsilon) s^(2-3epsilon) [z(1-z)]^(-epsilon)
      x^(1-2epsilon) (1-x)^(2-3epsilon)
      y^(1-2epsilon) (1-y)^(-epsilon)
      (1-z*x)^(-2+2epsilon)
      * normalized recoil angular measures,

    C(epsilon) = (4Pi)^(3epsilon) Gamma(1-epsilon)
                 /[2048 Pi^5 Gamma(2-2epsilon)^2].

In particular the pair orientation measure contains
Omega_(D-2) Omega_(D-3) [4z(1-z)]^((D-4)/2) *2 dz.
The last factor is the Jacobian d cos(theta)=-2 dz. The energy change of
variables contributes dx2/dy=(1-x)/(1-z*x). Neither factor is an operator
normalization to insert independently into a card.

An exact inclusive normalization check follows by integrating y, then z,
then x. The beta products are

    B(2-2epsilon,1-epsilon)
    B(1-epsilon,1-epsilon)
    B(2-2epsilon,2-2epsilon),

since 2F1(2-2epsilon,1-epsilon;2-2epsilon;x)=(1-x)^(-1+epsilon).
Thus the volume is

    (4Pi)^(3epsilon) Gamma(1-epsilon)^4 s^(2-3epsilon)
      /[2048 Pi^5 Gamma(3-3epsilon) Gamma(4-4epsilon)],

or s^2/(24576Pi^5) at epsilon=0. This agrees algebraically with iterated
two-body factorization. It checks normalization, not the continuation of an
arbitrary singular measured integrand.

The implemented reusable interface is a pair-resolved coordinate option for
scalar four-particle decay phase space. An arbitrary supported polynomial
measurement would still be pushed forward from its actual card expression.
For an angle measurement on the resolved pair, the cut simply selects z.
No process name, energy weight or hard coefficient would enter the coordinate
provider.

Remaining mathematical work: limiting charts at z=0,1, rho=0, x=0 and the coupled x=z=1
corner; sector/region completeness for each actual master; sufficient epsilon
orders, physical boundary constants and distributional endpoint bounds.
The coordinate representation supplies none of those endpoint conclusions by itself.

The record stores d=1-z*x, K=1-z+z*rho, zeta=z*rho/K, the exact Gram
 determinant and inverse energy map. Scalar-product observables integrate both
parity orientations; oriented Levi-Civita observables are outside its scope.
Moving angular collinear loci are b=0,a=zeta and b=1,a=1-zeta. With
 t=1-z,X=1-x,Y=1-y, the distinct balances t~X and t~XY must be resolved for
singular integrands. The internal 1/s34 collinear pole persists at interior z;
no contact-order bound is inferred from the positive coordinate density.


## Explicit complement-mass coefficients

`EvaluatePairComplementMassPeriod` recognizes ordinary complementary invariants
`(q-p_i)^2` from the original typed cut data, including their prescriptions and
normalization. It returns finite coefficients for one untagged complement,
two tagged complements, and a mixed tagged/untagged pair. A single untagged
complement may carry nonnegative tagged-pair invariant powers. Two untagged
complements supply only their epsilon^-1 residue after an exact radial subtraction.
These scalar classes do not encode observable weights or particle multiplicities.
The mathematical derivation and fixed-interior convergence bounds are retained
in `External/ChatGPT/Records/2026-09-18/19_complement_mass_physical_periods.md`.

Known finite coefficients propagate through
`ExtendMasterLaurentCoefficientsUsingDifferentialEquations`, separately from the
exact-function consequence routine. Differentiation includes moving GPL letters;
the coefficient valuation and omitted-tail audit control any lost epsilon orders.
An unresolved order remains unresolved. None of these operations determines
measurement endpoint contacts from interior values alone.

## Inclusive moments for physical constants

`ConstructPolynomialMeasurementMoment` constructs moment equations from the
actual typed integral. For its unit measurement cut `z F-G`, with positive `F`
and support `0<G/F<1`, inserting `F^(N+1)` gives

    integral dz z^p (1-z)^q J_R,N(z)
      = integral dPhi R F^(N-p-q) G^p (F-G)^q,   N >= p+q.

The factor of `F` compensates the delta Jacobian. The operation retains the
same labeled particle measure, ordinary prescriptions and dimension on both
sides. It checks the support in compatible physical coordinates and uses the
existing compact-cut Gram-domination proof for a common initial convergence
domain. Equality is then continued meromorphically. Dotted cuts, insufficient
insertion degree, restricted observable coverage and measurement-dependent
normalizations are rejected by this unit-cut interface.

The output contains explicit measured and unmeasured GLI combinations, with
their definitions. It is a constraint to reduce and evaluate, not a solved
moment or a boundary value. Numerator insertions can require integrals outside
the existing DE span. Their reduction, scalar epsilon coverage, continued
endpoint pairing and exact rank on the unresolved homogeneous solutions must
all be established before they fix constants. This does not determine the
complete observable's endpoint contact order. Mathematical review25 is retained
under `External/ChatGPT/Records/2026-09-18`; the regression driver is
`Tests/Integrals/t_polynomial_measurement_moments.wls`.
