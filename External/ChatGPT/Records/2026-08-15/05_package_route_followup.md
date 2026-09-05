# Package Route Followup

## Question

Continue the same FACET analytic-master discussion. Please assess the next exact
package experiments, not numerical verification routes.

New measured facts:

1. `MultivariateCreativeTelescoping.jl` exactly derived the Cauchy and Euler--Gauss
   telescopers directly from their integrands.  For

     Integral[u^eps (1-u)^eps (1-t u)^(-1-eps), {u,0,1}],

   it returned, up to an overall minus sign, the exact Gauss operator

     t(1-t) Dt^2 + (2+2 eps-(3+2 eps)t) Dt - (1+eps)^2.

   Its public API returns no telescoping certificate.  On the physical CF231
   two-variable density from the earlier attachment, building the annihilator took
   6.7 s, but the exact F4 Groebner basis was stopped after 22 minutes at 13.0 GB
   RSS without producing a telescoper.

2. Macaulay2 1.26.06 `ConnectionMatrices` works very well once a holonomic ideal is
   known.  Exact measured fixtures:
   - generic Gauss GKZ ideal: rank 2, four 2x2 matrices, exact flatness; connection
     computation 0.35 s;
   - massless one-loop triangle ideal: rank 4, two 4x4 matrices, exact flatness;
     connection computation 0.19 s.

3. The likelihood-ideal calculation gives the physical CF231 cohomology rank 5.
   The public `TwistedCohomology` Julia border-Macaulay construction reproduced
   smaller exact fixtures but reached 8.65 GB before finishing the first physical
   CF231 connection matrix.  The generic coefficient-space GKZ rank is 6, so plain
   substitution into its generic connection is invalid.

4. Risa/Asir `mt_mm` exactly reproduced controlled Macaulay/restriction fixtures.
   A first attempt at `nk_restriction.ost_integration_exp` for the finite interval
   Integral[1/(1-z t),{t,0,1}] reached 7.7 GB without returning an operator and also
   emitted a package-symbol redeclaration warning.  It is not yet a viable default.

5. An exact one-variable pullback detector was tested on Fable's solved class 115.
   In 0.010 s it found z=v w and proved

     A_v = (partial_v z) M(z),  A_w = (partial_w z) M(z),

   including flatness and exact reconstruction.  It rejected a deliberately
   perturbed non-flat control.

6. The public `CopositiveFeynman.jl` package found the exact Polya exponent 1 for
   x^2-x y+y^2, but found no exponent through N=10 for the CF231 branch polynomial.
   Its N=100 search reached 6.8 GB in two minutes.  CF231 is nevertheless certified
   directly by the exact identity

     Q=(s a+(s_x-s_y)b)^2+4 s_x s_y b(b+s)>0

   in the physical chamber.  Is there a mature exact SOS, copositivity, or
   semialgebraic-certificate package that can discover compact identities of this
   kind without general CAD?

Please give a concrete recommendation, with public package/function names and exact
acceptance tests, for these questions:

A. Is there a mature exact package that derives the *physical* Gauss--Manin/Pfaffian
   system for a product-of-polynomial-powers Euler density directly in the physical
   kinematic variables, preferably using finite-field Macaulay reconstruction, so we
   avoid both the generic rank-six GKZ system and the large symbolic border matrix?
   In particular, assess the OpenXM `mt_mm`/amp-MM implementation, the
   `TwistedCohomology` likelihood-ideal code, and any newer public package we have
   missed.

B. Is there existing software that computes relative/open-chain creative-telescoping
   certificates or face-source systems for a simplex with noninteger polynomial
   powers?  If no production-ready package exists, identify the smallest deterministic
   algorithm we should implement.  It must distinguish a homogeneous bulk equation
   from the inhomogeneous physical face equations.

C. `MultivariateCreativeTelescoping.jl` internally constructs derivative-reduction
   maps before finding linear dependencies.  Is extending those reductions to retain
   exact divergence certificates mathematically straightforward, or is a different
   algorithm required?  State what data must be tracked.

D. Which of the following can safely become generic FACET functions now: exact
   one-variable pullback detection; likelihood quotient/rank and basis; physical
   D-ideal derivation; ideal-to-Pfaffian conversion; singular-divisor and residue
   analysis; scalar-operator recognition; relative face-source derivation?  For each,
   state an exact criterion and the package best suited to it.

E. Suggest one decisive CF231-scale experiment that is more informative than another
   generic Groebner calculation.  We prefer a route that either constructs the exact
   rank-five connection or proves a lower-dimensional special-function pullback.

The final FACET result must remain an exact analytic function of kinematics and eps.
Fixed-point numerical values may only compare an independently derived analytic result.

## Pro response

_No Pro response was recorded._
