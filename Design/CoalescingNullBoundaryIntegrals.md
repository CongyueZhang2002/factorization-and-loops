# Whole-domain boundary coefficients from coalescing null directions

The constructor accepts three labelled massless cuts summing to Q, with z=Q^2
tending to zero from above, unit cut powers or one doubled cut. Original
momentum polynomials, signs, cut orientations, the absolute routing determinant
and the existing AMFlow phase-space normalization are preserved. It matches
future-null external-subset quadratic factors, exact multiples of P.R, explicit
Q^2 factors and at most two distinct final-state pair invariants. Unsupported
off-shell numerator structures fail explicitly.

External P.Q must have a positive finite limit. External pair invariants remain
finite, and the small-positive-z spatial Gram matrix must be positive semidefinite.
These checks establish the coalescing null geometry.

The invariant fractions x_i=(P_ref.k_i)/(P_ref.Q) obey the Dirichlet law with
alpha=(D-2)/2. They are not energy fractions. Under x1=t, x2=(1-t)u,
x3=(1-t)(1-u), the unnormalized density is

    t^(alpha-1) (1-t)^(2alpha-1) u^(alpha-1) (1-u)^(alpha-1).

The raw prefactor is Pi^(D-2)/(4 Gamma[D-2]). Including the existing standard
phase-space conversion, the D=4 volume is z/(256 Pi^3).

## Pair invariants

For one pair, y_ij=(k_i+k_j)^2/z=(x_i+x_j) rho with
rho~Beta(alpha,alpha), conditionally on x. Its integer inverse moment is
Pochhammer[alpha,-a]/Pochhammer[2alpha,-a] times (x_i+x_j)^(-a).
Simplify this rational factor before epsilon-order determination.

Two pairs share a particle; permute them to y12^p y13^q. Their joint moment
contains ordinary2F1[p,q;alpha;chi], chi=x2*x3/(x12*x13).
For p,q>0 the exact Euler representation is

    Gamma[2alpha] Gamma[alpha-p] /
      (Gamma[2alpha-p-q] Gamma[alpha] Gamma[q])
    * x13^(p-q) Integrate[
        r^(alpha-q-1) (1-r)^(q-1)/(x1+x2*x3*r)^p, {r,0,1}].

Only one extra integration variable is needed. If one power is nonpositive,
use the terminating hypergeometric sum. The canonical integral identity includes
the marked pair powers and all six external fraction powers. This representation
and an independent four-dimensional angular representation agree with the
invariant-simplex Gamma moment to about 3e-13 at D=10, in under one second.

## Whole-domain convergence

For unit cuts, let N be the sum of positive external and pair powers.
Conditional marginal inverse moments and Holder give a uniform L2 bound for
real D>4N+2. Almost-everywhere coalescence establishes the coefficient
z^(D-3-m-A), where m counts explicit recoil powers and A is the signed sum of
pair powers. Continue the coefficient identity meromorphically; do not assert
that the same scaled limit converges near epsilon=0.

For one doubled cut i, introduce m_i^2=z*mu_i and retain the full moving massive
domain h=1-sum(mu_i/x_i)>0. The measure contains h_+^(D-3); pair invariants are

    Y_ij(mu)=h*y_ij + (x_i+x_j)(mu_i/x_i+mu_j/x_j).

The first mass derivative gives the finite insertion

    (A-(D-3))/x_i * F
      - Sum[a_e*x_e/(x_i*y_e)*F, pairs e containing i].

Its additional integer z power is -1. Pair numerators are included.
Recognized external numerator/denominator derivatives are suppressed by
sqrt(z) in L2; no other off-shell mass dependence is silently discarded.

The sufficient domain is D>4(N+2)+2. At fixed fractions, each massive external
inverse moment is bounded by C*x_j^(-p), uniformly in the translated angular
center. Use the bounded ball density of the conditional transverse vector and
the locally integrable Riesz kernel in 2alpha dimensions. Conditional Holder
then gives total fraction inverse degree at most 2(N+2).
The remaining moving-domain exponent is at least (D-3)-A_positive-1>0.
For the support strip x_i<=2mu, the difference quotient is
O(mu^(alpha/2-1)); on its complement h>1/2. These estimates justify the domain
derivative and coalescence of the differentiated integral. The output stores
the exact generator match and these degree bounds.

Dotted-volume and one-pair coefficients agree with an independent dot-lowering
cut-IBP identity. A cut-inverse-propagator numerator is rejected unless its
off-shell derivative is explicitly handled; it is never set to zero first.

## DE matching and implementation

FeynFacet/Integrals/Asymptotics owns geometry-specific construction.
FeynFacet/Boundary/PhysicalCoefficients.wl extracts generic-epsilon normal/log
coefficient rows and identical-integral relations. Primary Frobenius coefficients
use dependency-ordered diagonal block solves. The current residue has 309 blocks,
largest dimension two. The general driver extends the normal jet automatically;
some doubled cuts require order three.

All 346 original masters now have constructed whole-domain leading coefficients.
This is not 346 independent integration jobs and does not determine the other
asymptotic regions. Three non-elementary Euler integrals, exact matching and
known volume fix the 48-dimensional slope -2 component.

Pro reviews are retained in
[the consultation records](../External/ChatGPT/Records/2026-09-07), especially
03,05,06 and 07.
