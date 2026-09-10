# Joint endpoint continuation of unit-cut integrals

This is a joint-domain specialization of the existing compact-cut convergence
certificate in FeynFacet/Integrals/Convergence.wl, called through
CertifyOrdinaryPrescriptionRemoval with JointExternalDomain. It does not
compute endpoint coefficients or their epsilon orders.

## Domain and measure

Let the E independent external momenta have a nondegenerate Lorentzian Gram
matrix G on a compact external parameter set. A continuous reference T must
remain timelike, with T.P positive and P future causal. The code checks these
conditions and the absence of poles in the rational external geometry on the
closed set. An invertible fixed rational routing relates L independent loop
momenta to L+1 forward particle momenta. Every particle energy is bounded by
the total energy. Thus all loop components and scalar products are uniformly
bounded in a regular frame.

With A_ia=k_i.p_a and B_ij=k_i.k_j, define

    H = A Inverse[G] Transpose[A] - B,     Delta = Det[H].

The physical domain includes every principal-minor inequality H>=0, the
forward conditions T.k_i>=0, and the actual cut equations. Det[H]>=0 alone is
insufficient. Delta is the unscaled positive transverse determinant.

The angular pushforward has weight

    Abs[Det[G]]^(-L/2) Delta^((D-E-L-1)/2).

The dimensional constant and typed normalization are retained. With the full
Gram determinant instead, the external factor is
Abs[Det[G]]^((E-D+1)/2); the Schur complement equates the two expressions.
See the standard Baikov formula in
[Böhm et al., section II](https://arxiv.org/html/1712.09737v3#S2).
A recoil-dependent rescaling of Delta must retain its compensating power.

## No separate endpoint measure

Perform the transverse angular pushforward under a smooth JOINT external
test function before eliminating cuts. Its Gamma-normalized positive Gram
power defines a continuous-D family on an open convergence domain. Agreement
only at integer D would not prove uniqueness.

At sufficiently large Re(D), the Gram power extended by zero outside the
positive-semidefinite cone is continuous and vanishes on rank-deficient
strata. An additional finite margin permits the normal regularity needed
for cut regularization. The complete affine cut matrix has a nonzero constant
minor, checked by the code. Eliminating those scalar coordinates is therefore
a regular linear change, uniform in the external variables. Applying the
unit-cut approximate identities restricts the continuous density to this
graph, without a singular external Jacobian or a separate endpoint atom.

The future-energy bound persists under small independent nonnegative particle
mass increments. Positive Gram powers vanish at forward tips and the moving
Gram boundary, supplying compact domination in the cut limit. The present
joint implementation refuses dotted final cuts: the generic mass-derivative
theorem is not automatically a joint endpoint theorem.

## Divisor domination

The existing fixed-interior certificate proves that ordinary denominator
zeros lie on the Gram boundary. Every newly admitted external face must
either satisfy those same conditions or, under the current sufficient rule,
have P^2=0. A null sum of forward null momenta makes them collinear, so their
transverse Gram vanishes. For the checked null-reference fraction
z=p.k_tag/(p.P), both z=0 and z=1 also force Gram degeneracy.

Exact external coefficient divisors are checked as well. They must be
nonzero on the closed domain or have all zeros on these proved Gram faces.
An interior divisor such as x-z fails. Failure may be resolved by a better
basis or an independently proved cancellation; it is not proof of inequivalence.

Mixed D-kinematic divisors require a uniform proof. D(1-x)-1 has an interior
zero for arbitrarily large positive D and is rejected. Purely dimensional
meromorphic factors remain separate, with isolated poles excluded from the
open domain. Spatial dimensional powers cannot silently remove Gram zeros.

On a compact semialgebraic set K, zero(P_j) contained in zero(Delta) implies
finite N_j,C_j with

    Delta^N_j <= C_j Abs[P_j].

This is the compact semialgebraic Łojasiewicz inequality, e.g. Theorem 2.12 in
[Fichou's notes](https://perso.univ-rennes1.fr/goulwen.fichou/RAG1.pdf).
For a finite product of ordinary and spatial coefficient denominators,
sufficiently large Re(D) absorbs their finite Gram losses. Polynomial
numerators are bounded. The inequality
Abs[(P+i eta)^(-n)]<=Abs[P]^(-n) then gives the joint L1 ordinary-prescription
limit. A positive margin controls logarithms from D derivatives.

Existence of this domain does not give an explicit numerical threshold D*,
an optimized pole bound, or sufficient endpoint Taylor orders.

## Exact generic identities and continuation

Certify both the original expression and its actual final reduced terms, or
independently regularized combinations. In a common high-D domain these are
integrable densities, equal almost everywhere by the already justified
generic physical reduction. Their joint test-function pairings agree on an
open domain and hence under meromorphic continuation. An endpoint-supported
difference cannot survive this equality.

The product with 1/(1-z), for example, is formed before continuation in the
integrable domain. This does not authorize multiplying arbitrary
Laurent-expanded distributions by that singular function. Genuine delta
and plus terms still have to be calculated.

Intermediate dotted IBP integrals need no new joint certificate if they
disappear from the final identity and the generic IBP identity is already
justified. A joint assertion about those intermediates themselves would need
the stronger normal-derivative theorem.

## Coverage

Tests/Integrals/t_joint_cut_convergence.wls tests the valid case and rejects
an interior pole, a moving D-dependent pole, dotted final cuts, and a
recoil-dependent dimensional rescaling. Existing generic and measured
prescription tests continue to exercise this same certificate.

The mathematical decision was reviewed by verified GPT-6 Pro:
[review 29](../External/ChatGPT/Records/2026-09-10/29_joint_endpoint_convergence.md).
A passing convergence certificate does not establish a uniform truncated
corner expansion or a completed hard function.
