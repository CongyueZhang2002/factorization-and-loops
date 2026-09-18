# Explicit Gram domination and bounded moment selection

Actual ChatGPT6 Pro,7m13s, mathematical review in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Prompt supplied pushedfa4eb5b9bfa51b2a5fc2830dde8a0b53a9bfe09f.
Pro explicitly did not execute or audit that source. It checked the determinant
identity symbolically. No measured EEC coefficient was requested or compared.

For sij=2pi.pj, S=sum sij>0, H_ii=0,H_ij=sij, let Delta=-det H.
With a=s12*s34,b=s13*s24,c=s14*s23,

    Delta=4ab-(a+b-c)^2,
    0<=Delta<=4S^3*sij for every pair.

This determinant is16 times the determinant of [pi.pj]; keep that convention.
A denominator with verified unit-cut identity sigma_j Dj=sum c_j,ab sab,
sigma_j=+/-1,c_j,ab>=0,sum c_j,ab=c_j>0, obeys
abs(Dj)>=c_j Delta/(4S^3). Coefficients may depend on external parameters only
with their signs/nonzero lower bounds established locally on the domain.

In dimensionless xij=sij/S, the invariant scalar four-particle measure is
K4(D) S^(3D/2-4) (Delta/S^4)^((D-5)/2) dSigma5(x), on the physical part of
the compact positive simplex. Eliminating sum xij=1 has constant Jacobian.
There is no further Gram Jacobian; the Gram boundary is a theta restriction,
not a delta root. Overall angular orientations are already integrated.
For a polynomial numerator and total positive ordinary-denominator power P,
Re D>5+2P is a sufficient common convergence domain, or Re epsilon<-P-1/2.
This is conservative, not a sharp singularity estimate. A finite sum can use
max P without recombining all its denominators. Dimensional derivatives add
logs, controlled by a strictly positive Gram exponent margin, away from
isolated normalization poles.

For F>0 and 0<Z=G/F<1 in the complete physical interior,

    J_N[phi]=integral dPhi R F^N phi(Z).

The positive measurement regularization eta/[Pi(t^2+eta^2)] obeys
integral_0^1 dz F^(N+1) delta_eta(Fz-G) abs(phi(z))<=F^N norm(phi)_infinity.
This is uniform as F->0. The Gram majorant controls the parent integral;
F=0 has zero invariant measure and cannot supply an arbitrary extra contact
under this specified dominated limit. Ordinary eta limits use the same bound.
Regularized graph deltas converge weakly, not in total variation. The limiting
pushforward is a finite-measure-valued holomorphic family on the high-D domain.
A constant observable still produces an interior delta; support alone does
not establish absolute continuity of the pushforward.

The Gram witness supplies the initial germ. It does not independently prove
meromorphic continuation; once the existing construction continues that germ,
uniqueness preserves the full distributional identity. No near-D=4 contact
order or weighted L1 bound follows. Example: (-epsilon)t_+^(-3-epsilon)
has finite coefficient delta''/2 despite zero finite interior coefficient.
Dotted particle cuts, extra external directions and denominators with interior
zeros are outside this positive unit-cut witness; retain the broader proof.

## Select moment rows without reopening every measured reduction

Do not multiply an integrated IBP identity by a loop-dependent polynomial.
The derivative acts on that polynomial too; multiplication is not an operation
on the IBP quotient without new inserted identities.

Within small groups sharing a measurement cut and a modest common ordinary
denominator H, use actual representatives P_i/H. Choose inexpensive unmeasured
Q_a/H. Seek bounded-degree r_i(z), z-independent b_a and polynomial witnesses
A,B_l such that

    sum r_i(z) P_i = F sum b_a Q_a + (zF-G)A + sum C_l B_l,

where C_l are original unit particle-cut polynomials. Equate scalar-product
and z coefficients, solve the finite linear system and verify the polynomial
identity exactly after clearing external denominators. It yields
integral dz r(z)I(z)=sum b_a U_a without new measured IBPs. Normalize external
family factors explicitly. Start at z degrees0/1 and sector-local supports;
a global common denominator for all43 integrals could defeat the purpose.

Second pass: actual inserted integrals already covered partly by retained
reductions give K_a=R_ai I_i+E_ab X_b. Cancel rational GLI coefficients before
finding the exact kernel t^T E=0. Treating unresolved X as independent is
conservative. Initially t is z-independent; otherwise the inclusive side
requires the corresponding additional weighted moments.

For I=I_fixed+Y_U c, accepted moment responses are
M_aj=MC integral r_a(z) [Y_U]_j. Only exact rank increase on unresolved modes
justifies new integrations or deeper epsilon expansions. An adjoint relation
r=v'+vA changes a moment by its regulated boundary product, not automatically
zero. Include inclusive coefficient valuations, endpoint continuation and
epsilon-rank/inverse-matrix losses in order planning.

Universal scalar-measure reference mentioned by Pro: Eq5.1 of
https://arxiv.org/abs/hep-ph/0311276 . Generalized Hermite reduction reference:
https://arxiv.org/abs/1805.03445 . These are method/scalar inputs, not a measured
hard coefficient.
