# Two resolved particles in massless four-body phase space

This is a proposed physical coordinate construction, submitted to actual Pro
for mathematical review17 on18September. It is not implemented or an evaluated
master integral. No measured literature hard coefficient enters the derivation.

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
Using the two resolved one-particle measures times dPhi2(R) gives the proposed
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

The intended reusable interface is a pair-resolved coordinate option for
scalar four-particle decay phase space. An arbitrary supported polynomial
measurement would still be pushed forward from its actual card expression.
For an angle measurement on the resolved pair, the cut simply selects z.
No process name, energy weight or hard coefficient would enter the coordinate
provider.

Remaining mathematical work: independent review of coverage and angular
continuation; limiting charts at z=0,1, rho=0, x=0 and the coupled x=z=1
corner; sector/region completeness for each actual master; sufficient epsilon
orders, physical boundary constants and distributional endpoint bounds.
This proposal supplies none of those endpoint conclusions by itself.
