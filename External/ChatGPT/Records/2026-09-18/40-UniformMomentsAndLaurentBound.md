# Pro review: uniform moment equations and the boundary Laurent bound

Actual ChatGPT 6 Pro, 8m 59s. Source inspected: https://github.com/CongyueZhang2002/factorization-and-loops/commit/8b7fed8c771b1cc54aa3207246e072afd09bf6c7

Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

The following is the rendered response text; mathematical layout follows the browser extraction.

Worked for 8m 59s

The 19+1 rank argument does establish c=O(ϵ
−4
), provided those are exact ranks of the regular, consistently normalized combined system. The moment-pole extraction is sound for your normalized Frobenius spectra. I found one concrete GPL guard defect: a symbolic leading coefficient can vanish under the supplied assumptions, invalidating the classification of a moving letter as tending to infinity.

Source inspected

I accessed exact revision 8b7fed8c771b1cc54aa3207246e072afd09bf6c7, “Construct uniform dimensional moment equations and GPL endpoint limits.”

I inspected the complete Boundary/MomentPoles.wl and Functions/GPL/EndpointExpansion.wl, including the Hadamard routine; Tests/Boundary/t_frobenius_moment_poles.wls; Tests/Transport/t_gpl_finite_endpoint.wls; t_gpl_hadamard_finite_part.wls; and the final continuation in Reports/2026-09-18/NLOEECPhysicalCoefficients.md.

This was static inspection and mathematical review. I did not execute the Wolfram tests, inspect the saved production matrices, or independently verify their ranks, entries, or timings.

1. Moment poles and regulator-uniform Frobenius expansion
The pole extraction has the correct depth, sign, and logarithmic factors

Let the complete rational density multiplier have lowest normal power ℓ. A primary solution has the form

t
βϵ
j≥0
∑
	​

p
∑
	​

t
j
log
p
tH
j,p
	​

(ϵ).

Only j≤−1−ℓ can contribute to the coefficient of t
−1+βϵ
. Thus

N
jet
	​

=max(0,−1−ℓ)
	​


is sufficient. The implementation uses that bound and computes

h
p
	​

(ϵ)=
j=0
∑
N
jet
	​

	​

D
−1−j
	​

(ϵ)H
j,p
	​

(ϵ),

followed by

p
∑
	​

(βϵ)
p+1
(−1)
p
p!h
p
	​

(ϵ)
	​

.
	​


This includes analytically sourced components, not just residue eigenvectors. No factorial is missing or duplicated. The sourced higher-pole and Jordan tests directly exercise these features.

The zero-slope columns remain explicitly listed, and CompleteDimensionalMomentEstablished remains false. That correctly leaves their physical elimination and the finite-part contribution to the caller.

The denominator check is substantive

After epsilon rescaling, the verifier checks regular singularity in t, epsilon regularity, and rational joint dependence. Every denominator factor other than extractable powers of t and ϵ must be nonzero at (0,0).

Locally on a nonsingular external-parameter domain, this proves that the remaining rational coefficients are jointly holomorphic on a common neighborhood. In particular, it excludes the shrinking endpoint layer in

(t+ϵ)
2
ϵ
	​

.

That is the relevant condition—not merely rationality or a generic-ϵ Taylor expansion.

Regulator resonances do not obstruct your normalized case

For the reported normalized spectrum λ
i
	​

=β
i
	​

ϵ, the positive-order Frobenius recurrence involves operators whose eigenvalues are

n+(β−β
i
	​

)ϵ,n≥1.

They are nonzero in a sufficiently small common regulator disk: choose, for example,

∣ϵ∣<
2max
i,j
	​

∣β
i
	​

−β
j
	​

∣
1
	​


when the maximum is nonzero. No positive-order resonance accumulates at ϵ=0.

Coinciding exponents at order zero are handled by the complete Jordan blocks. Meromorphic primary-basis matrices can contribute finite epsilon poles, which must enter the order budget, but do not create an unbounded sequence of new recurrence poles. This is the relevant parameter-dependent refinement of the usual Frobenius resonance distinction. 
DLMF

Therefore, for your normalized affine spectra and finite-meromorphic seed changes, the combined checks are sufficient for the local subtraction argument. The standalone denominator verifier should not be interpreted as proving arbitrary supplied spectral data or their epsilon coverage.

The check remains local to each endpoint. Preserve the full, unexpanded ordinary-path admissibility as well: coefficientwise interior-pole checks alone can miss an interior layer such as

(t−
2
1
	​

)
2
+ϵ
2
ϵ
	​

.

The module correctly states that interior singularities are outside its certificate’s scope.

Hadamard extraction is consistent

The new routine computes a primitive and takes

CT
t→0
	​

P(a−t)−CT
t→0
	​

P(t),

with constant power and constant logarithmic degree. Its interior rational-pole rejection and separate MeromorphicDimensionalIntegralEstablished -> False are appropriate. I found no endpoint-orientation error in this path.

2. GPL parameter limits: correct mechanism, one specialization bug

For letters with limits strictly separated from the fixed closed segment, GPLs depend analytically on those letters. A rational letter has a positive-power approach to its finite limit; a letter escaping to infinity gives a vanishing kernel. Fixed zero letters retain the tangential convention. These are compatible with the regularized hyperlogarithm framework. 
arXiv

Thus replacing the GPL by its limiting value is valid through parameter order zero when its coefficient has only nonnegative powers and finite logarithmic growth:

t
α
log
q
t[G(t)−G(0)]⟶0,α≥0.

Rejecting negative-power prefactors is necessary unless a letter jet is computed. The helper is invoked only for requested upper order zero, matching this limited operation. The direct classical-series path also requires an explicit integer-power Laurent polynomial in t,logt, rather than accepting an unresolved series.

Concrete defect: generic valuation can be wrong on the assumed parameter locus

letterLimit calculates the rational valuation using Cancel[a], without establishing that its leading coefficient is nonzero under $gplAssumptions.

Consider

G({2+
t
c−d
	​

};
2
1
	​

),assumptions c=d.

The actual letter is identically 2, so the limit is

G(2;
2
1
	​

)=log
4
3
	​

.

The current helper sees the generic power t
−1
, classifies the letter as infinite, and returns zero. This follows directly from the source control flow; I did not execute this counterexample.

Bounded repair: simplify under the declared assumptions where possible, then verify that the leading numerator and denominator coefficients used to determine the valuation are finite and nonzero on that domain. If the leading coefficient vanishes, recompute the order; if its status is unresolved, reject the limit rather than assume generic behavior.

This affects symbolic specializations. It does not show that the two reported physical donor limits are wrong; their actual leading coefficients need inspection under their retained domains.

The new trailing-zero reduction is algebraically appropriate. In particular, GPL words at argument one must not be treated as independent symbols before exact shuffle identities are applied. The focused tests cover the cancellation that previously produced a spurious pivot.

3. The combined system really gives the amplitude bound

Use the actual row-normalized system

R(ϵ)c(ϵ)=y(ϵ),R=
	​

B
ϵ
M
K
	​

	​

,

including any additional stated row scalings in both R and y.

Assume:

R is holomorphic at zero, with a certified lower bound—not merely absent negative terms in a short computed window.

rankR
0
	​

=19.

The first reduced Schur coefficient has rank one, established after the necessary exact GPL identities.

y=O(ϵ
−3
), including every missing-but-retained donor coefficient.

Then a selected 20×20 subsystem R has, under holomorphic invertible row and column operations, the form

P(ϵ)R(ϵ)Q(ϵ)=diag(1
19
	​

,ϵs(ϵ)),s(0)

=0.

Consequently

R
−1
=O(ϵ
−1
),
c=O(ϵ
−4
).
	​


This conclusion uses only the leading regular matrix and its first correction. It does not require constructing the full inverse or higher connection orders.

The report records the corrected 19+1 ranks and explicitly separates them from physical coefficient determination. I have not independently checked the determining minor.

The auxiliary interpretation of 
M
 does not invalidate this

The physical amplitude vector satisfies both

Bc=0,
M
c=U.

That is sufficient for the algebraic bound. 
M
 need not define a physical integral on vectors violating Bc=0.

Changing the off-constraint extension by

M
↦
M
+LB

does not change those physical equations. You may therefore continue using the joint system rather than projecting all 20 columns first. The necessary condition is that the retained matrix coefficients and constraint orders genuinely represent this joint system to the required depth.

The resulting bound belongs to the specific amplitude coordinates used in the stack. Any subsequent pole-valued column transformation requires its own valuation propagation.

4. Cheapest next solve: only the delayed projection

For a selected square subsystem, write

R=R
0
	​

+ϵR
1
	​

+⋯,y=ϵ
−3
y
−3
	​

+ϵ
−2
y
−2
	​

+⋯.

Choose nonzero vectors

R
0
	​

n=0,ℓR
0
	​

=0,

and define

γ=ℓR
1
	​

n

=0.

Both nullspaces are one-dimensional.

Since c=O(ϵ
−4
), the two leading equations imply

c
−4
	​

=αn,γα=ℓy
−3
	​

.

Therefore

c
−4
	​

=n
ℓR
1
	​

n
ℓy
−3
	​

	​

.
	​

(1)

Compute this projection next. There is no need to expand the full inverse or all 43 moment rows further.

To improve the bound to c=O(ϵ
−3
), it suffices that

ℓy
−3
	​

=0.
	​


The entire vector y
−3
	​

 need not vanish. Its nonzero component in imR
0
	​

 can determine part of c
−3
	​

 without producing an ϵ
−4
 term.

If the projection contains an unavailable donor coefficient, retain that symbol. It may require only one donor combination, rather than completion of the large individual expression that timed out.

If the ϵ
−4
 coefficient vanishes

Solve

R
0
	​

c
−3
	​

=y
−3
	​


for a particular solution v, leaving

c
−3
	​

=v+αn.

The next projected equation gives

α=
γ
ℓy
−2
	​

−ℓR
1
	​

v
	​

.
	​

(2)

This still uses only R
0
	​

,R
1
	​

, now with the RHS through order −2. No R
2
	​

 is needed because c
−4
	​

=0.

If c
−4
	​


=0, the next equation instead contains R
2
	​

c
−4
	​

; extend that specific demand rather than pretending the present matrix depth suffices.

More generally, with established amplitude lower bound b and one delayed pivot, a conservative demand for c through order k is

R through k+1−b,y through k+1.
	​


The sparse convolution audit can reduce this. For example, after proving b=−3, finite amplitudes can generally require R through order four and y through order one—not just the current first-order matrix.

Decision

Proceed with the selected 19+1 system and compute (1), then (2) when the first projection vanishes. Check the surplus equations at those same orders, retain missing donor coefficients explicitly, and extend only the resulting matrix/RHS demands.

The supported pole formula and constrained-moment interpretation do not require redesign. Repair the assumption-sensitive moving-letter valuation before accepting further symbolic limits. The next physical progress can come from the leading projected RHS, without another global connection expansion or a new endpoint engine.

