# Source identities and primary-sector divisibility

GPT-6 Pro consultation, 2026-09-07.

## Question

We have completed all 91 symbolic tangential endpoint systems and their exact physical-seed matching. Full interior contraction for all345 masters is complete; serialization is being checked. Your response19 is being applied.

CF1 onset corrected and verified exactly: raw I1 and I2 both start z^(1−2epsilon). T=diag(z,1); normalized R=diag(−2epsilon,0); the complete2×84 physical amplitude matching matrix is row1={epsilon^5,0,...,0}, row2=0. The entire slope-zero homogeneous component vanishes exactly, and H1(2,1)=−(2−3epsilon)/[(1−2epsilon)v].

The first exact source-pair audit finds NONZERO weighted-source residues for both CF1 coefficients at two rational regulator/kinematic points on f=0. The ghost terms and native parser are undergoing an independent Wolfram check. Thus we do not assume the original finite CF1 jets have uniform tails. We are reconstructing only exact two-variable residues and finding all masters sharing
 f=−6s(1+epsilon)(z+tau), tau=2epsilon(1−v)/[3(1+epsilon)].
The complete support scan is ongoing.

I want to settle a precise proof/implementation choice before spending hours on endpoint moving-scale corrections.

1. The unreduced amplitude pairs and every source integral are retained. These have fixed propagators independent of D. On the moving curve z=−tau at fixed nonzero epsilon, assume a source cut integral is analytic on the chosen local continuation, since there is no source Landau divisor there. Exact IBP identities give each source integral as sum_i K_ai I_i. Therefore its complete residue row satisfies sum_i Res(K_ai) I_i(v,−tau,epsilon)=0. Does the retained source identity plus this justified analyticity provide the exact residue cancellation certificate you requested, without numerically evaluating masters on the moving curve? What additional data would make the analyticity statement adequate rather than circular?

2. In our normalized Frobenius systems the physical scalar solutions have finitely many slopes b in {−2,−3,−4} (the absent slope0 has been checked where used), finite logarithmic Jordan powers, and coefficient matrices jointly analytic in z and meromorphic in epsilon with established uniform finite epsilon-pole bounds. Tangential seed coefficients are meromorphic in epsilon. Substituting z=−tau produces finite sums epsilon^(b epsilon) times polynomials in Log[epsilon] with meromorphic coefficient functions of epsilon. Are these distinct generalized monodromy sectors linearly independent over meromorphic germs, so the exact total moving residue identity implies primary-by-primary divisibility? A monodromy loop around epsilon=0 multiplies each slope by exp(2pi i b epsilon), with the usual triangular logarithmic action; distinct slopes have distinct eigenvalues for generic nonzero epsilon. If this argument is valid under the stated assumptions, it could convert the source IBP residue identities into the primary-block divided differences of your response19 without reconstructing huge exact coefficient functions. Please identify any failure of the joint meromorphic assumption due to the rational normalizing gauge or parameter resonances.

3. Regardless of whether exact division is proved, for a finite requested orderN your finite moving-contact formula appears directly usable with finitely many primary normal coefficients:
 -pi tau^(b epsilon)/sin(pi b epsilon) * G_b(−tau,epsilon)
 * sum_j tau^j/j! delta^(j).
For logarithmic blocks differentiate the exponent kernel. We would represent Log[epsilon] as a separate formal symbol while expanding, use your n+j bound, and require all retained Log[epsilon] coefficients to cancel in the complete merged output before declaring an ordinary Laurent series. Is this the simpler production route even when source residue identities imply exact cancellation? In that case are all moving-contact terms identically zero primary-by-primary, or can derivative-log blocks leave nonzero contacts despite a vanishing complete residue? Please distinguish an exact pole cancellation from cancellation only to the target distribution order.

We want the cheapest mathematically sufficient general code. Existing finite solved DEs and physical boundary data should be reused. No new AMFlow campaign or global canonicalization is planned.


## Response

Your source-identity and monodromy arguments are correct under the stated joint-meromorphic assumptions. Two qualifications are essential: analyticity must cover the participating masters as well as the source integral, and “primary-by-primary” means after merging all contributions with the same slope, not separately for each family or projector column.

Under those hypotheses, use exact source-residue cancellation followed by targetwise divided differences. The additional moving-contact corrections then vanish, including the logarithmic ones. They should be a fallback, not the default calculation.

1. The retained source identities can supply the exact cancellation certificate

Put

h=z+τ(ϵ,v),z
c
	​

=−τ.

For a retained exact source identity

J
a
	​

(v,z,ϵ)=
i
∑
	​

K
ai
	​

(v,z,ϵ)I
i
	​

(v,z,ϵ),

suppose every relevant K
ai
	​

 has at most a simple h-pole:

K
ai
	​

=
h
r
ai
	​

(v,ϵ)
	​

+q
ai
	​

(v,z,ϵ).

If J
a
	​

, every participating I
i
	​

, and the q
ai
	​

 are holomorphic in z at z
c
	​

, for generic nonzero ϵ, multiplication by h and restriction give

i
∑
	​

r
ai
	​

(v,ϵ)I
i
	​

(v,z
c
	​

,ϵ)=0.
	​


This is an exact consequence of the retained identity and analyticity. Evaluating masters numerically on the moving curve would add no proof.

An amplitude multiplier P
a
	​

(v,z,ϵ) regular at z
c
	​

 contributes the residue row

P
a
	​

(v,z
c
	​

,ϵ)r
ai
	​

(v,ϵ).

Consequently, exact source-level certificates survive the amplitude weighting and main/ghost combination. Nonzero individual CF1 coefficient residues are entirely compatible with them.

What makes the analyticity premise adequate

The required premise is not merely that the propagators contain no D. It is that the original integrals define a meromorphic family in ϵ, with kinematic singularities confined to a fixed, proper singular locus, on the chosen continuation. Fixed-polynomial parametric or period representations provide the relevant framework: regulator dependence enters exponents and meromorphic prefactors, while the integration geometry determines the possible kinematic singularities. 
arXiv

For your certificate, retain the raw integral definitions, cut orientations and prescriptions, normalization factors, and the identification of the continued cut cycle. The geometric argument must account for boundary pinches and infinity, not only leading finite-momentum Landau equations. This qualification matters for massless integrals with UV/IR divergences, where a naive Landau-equation test can miss singular structures or report permanent pinches. 
arXiv

There is a useful simplification here. Once a proper D-independent kinematic singular locus has been established, you do not need to prove that every point of h=0 avoids it. Indeed,

∂ϵ
∂z
c
	​

	​

=−
3(1+ϵ)
2
2(1−v)
	​


=0

on your tangential patch. Thus (v,ϵ)↦(v,z
c
	​

) sweeps an open kinematic set. The moving hypersurface cannot be contained in a fixed proper kinematic singular locus. Generic points suffice to obtain the identity, which then continues analytically.

This is a family-level geometric argument, not a request to recompute every source integral or its complete Landau discriminant. However, it must apply to the actual cut-integral class, rather than being inferred from the apparent poles of the already-reduced DE.

The remaining support scan is consequential. It must include the complete residue row, the common physical branches, and the pole multiplicity. If another coefficient has an h
−m
 term with m>1, the simple-residue formula is insufficient: principal-part cancellation involves derivatives of the masters at z
c
	​

. For example, the h
−1
 coefficient contains

i,m≥1
∑
	​

K
ai,−m
	​

(m−1)!
∂
z
m−1
	​

I
i
	​

(z
c
	​

)
	​

.

That is still finite, but it is a different supported case.

2. Your monodromy argument separates slopes and logarithmic coefficients

Write the complete pole numerator, after amplitude weighting, as

G(v,z,ϵ)=
b
∑
	​

z
bϵ
ℓ=0
∑
L
b
	​

	​

(logz)
ℓ
G
bℓ
	​

(v,z,ϵ),F
pole
	​

=
z+τ
G
	​

.

Integer powers of z, including finitely many negative ones, are included in G
bℓ
	​

.

The hypothesis needed for the following argument is precise: locally uniformly on the tangential patch, there exist finite P,d such that

ϵ
P
z
d
G
bℓ
	​

(v,z,ϵ)is jointly holomorphic near (z,ϵ)=(0,0).
	​


This concerns the complete functions represented by the Frobenius systems—not merely the computed finite coefficient list.

Since

z
c
	​

=ϵu(v,ϵ),u(v,0)

=0,

a consistent branch gives

logz
c
	​

=logϵ+λ(v,ϵ),

where λ=logu is holomorphic on the chosen patch. Therefore the source-residue identity becomes

b
∑
	​

e
bϵL
ℓ=0
∑
L
b
	​

	​

A
bℓ
	​

(v,ϵ)L
ℓ
=0,L=logϵ,

with all A
bℓ
	​

 meromorphic germs in ϵ.

Direct proof of independence

Let K be the field of those single-valued meromorphic germs, with v fixed in the patch. Regulator monodromy acts K-linearly:

M:L↦L+2πi.

On

V
b
	​

=span
K
	​

{e
bϵL
L
ℓ
:0≤ℓ≤L
b
	​

},

its only eigenvalue is

μ
b
	​

=e
2πibϵ
,

and

(M−μ
b
	​

)
L
b
	​

+1
V
b
	​

=0.

For b

=c,

μ
b
	​

−μ
c
	​

=2πi(b−c)ϵ+O(ϵ
2
)

is nonzero and invertible in the meromorphic field. Hence the generalized eigenspaces form a direct sum. The identity separates into one identity for each b.

Within a fixed slope, a finite polynomial in L cannot vanish with nonzero meromorphic coefficients: repeated continuation L↦L+2πin proves this directly. Thus every A
bℓ
	​

=0. The shift L↦L+λ is an invertible triangular transformation, so

G
bℓ
	​

(v,z
c
	​

,ϵ)=0for every merged slope b and log power ℓ.
	​


This is stronger than merely showing that the complete logarithmic expression vanishes on the curve.

It does not separate different families carrying the same slope. In particular, a nonzero CF1 contribution must cancel within the complete slope-−2 scalar block. Contributions belonging only to slopes −3 and −4 cannot cancel it under these hypotheses.

Gauge and resonance qualifications

A rational gauge whose entries have only finite ϵ- and z-poles times jointly holomorphic units preserves the required class. Integer shears contribute integer powers of ϵ after substitution. Spectral-projector poles at colliding residue eigenvalues are also permissible when their finite Laurent bounds are included.

The important exclusions are coalescing denominators or branch points left inside the purported holomorphic factors, essential regulator dependence such as e
z/ϵ
, and an unbounded growth of regulator pole orders with Frobenius order. A finite set of checked H
n
	​

 cannot establish the uniform hypothesis.

For a normalized Fuchsian family analytic in the parameter, the absence of nonzero integer eigenvalue differences gives a Frobenius factor converging on a parameter-uniform neighborhood; this is the relevant parameterized result, not merely fixed-ϵ Frobenius existence. 
arXiv

Your slopes coalesce at ϵ=0, but that alone is not an obstruction. Finite meromorphic projectors and finite Jordan logarithms accommodate it. There is also no reason to construct the regulator-monodromy projectors computationally: the preceding argument establishes separation as a theorem. Their 1/ϵ factors would matter only if you tried to infer separate identities from a finite-order total identity.

3. Exact divisibility gives a finite implementation

The coefficientwise identities above imply divisibility in the joint analytic ring after clearing the admitted fixed poles.

Write one coefficient as

G
bℓ
	​

(z,ϵ)=z
−d
n≥0
∑
	​

g
n
	​

(ϵ)z
n
,ν
ϵ
	​

(g
n
	​

)≥−P

uniformly in n. Since G
bℓ
	​

(z
c
	​

,ϵ)=0,

z−z
c
	​

G
bℓ
	​

(z,ϵ)
	​

=z
−d
k≥0
∑
	​

Q
k
	​

(ϵ)z
k
,

where

Q
k
	​

(ϵ)=
n≥k+1
∑
	​

g
n
	​

(ϵ)z
c
n−k−1
	​

.
	​


This follows by applying

z−z
c
	​

z
n
−z
c
n
	​

	​

=
k=0
∑
n−1
	​

z
k
z
c
n−1−k
	​


to the numerator.

Because ν
ϵ
	​

(z
c
	​

)=1, Q
k
	​

 through ϵ
M
 requires only

n≤k+1+M+P.
	​


For a retained n, g
n
	​

 is needed through

ϵ
M−(n−k−1)
.

Thus the output can be actual finite solved coefficients built from your existing endpoint systems. No infinite moving-curve value, lazy quotient, or global gauge transformation is needed.

This may still demand additional normal coefficients; the exact proof does not make those dependencies disappear. It avoids the separate expansion of moving contacts and their subsequent cancellations.

Do not apply this conclusion directly to the two unrepaired finite CF1 jets. First retain their exact coalescing pole parts:

c
i
	​

=
z+τ
r
i
	​

	​

+q
i
	​

,q
i
[≤5]
	​

=c
i
[≤5]
	​

−[
z+τ
r
i
	​

	​

]
[≤5]
.

Then certify the fixed-divisor remainder class of q
i
	​

, preserving its unknown O(ϵ
6
) tail. The exact pole pieces participate in the complete scalar divided difference; the q
i
	​

 tails receive the ordinary sufficient-order analysis.

An exact cancellation theorem for the full coefficients does not automatically hold for a mixture in which only two pole parts have been replaced by truncated outer expansions.

4. Moving contacts: exact cancellation versus finite-order cancellation

With

K(α,τ)=−
sin(πα)
πτ
α
	​

,

the moving contribution for a logarithmic block is, as a targetwise distributional asymptotic expansion,

C
bℓ
	​

=G
bℓ
	​

(−τ,ϵ)∂
α
ℓ
	​

K(α,τ)
	​

α=bϵ
	​

j
∑
	​

j!
τ
j
	​

δ
(j)
(z).
	​


The exponent derivative holds G
bℓ
	​

 and τ fixed. The kernel comes from analytically continued beta moments and the gamma reflection formula. Its branches must be inherited consistently from the original continuation. 
DLMF
+1

Under your exact hypotheses, every additional moving contact vanishes

The monodromy argument established

G
bℓ
	​

(−τ,ϵ)≡0

for every merged b,ℓ. Therefore

C
bℓ
	​

≡0.
	​


Derivative-log blocks do not leave residual contacts: the dummy exponent derivative acts on the kernel, not on a nonzero coefficient hidden inside the cancellation.

This concerns the additional moving-scale correction. It does not set the usual threshold delta coefficients of the divided, fixed-divisor density to zero.

Exact pole cancellation alone would not suffice without the meromorphic hypothesis

For comparison,

z
α
z+τ
logz−log(−τ)
	​


has a removable pole at z=−τ. Nevertheless, its moving contribution contains

K
′
(α,τ)−log(−τ)K(α,τ),

which is generally nonzero.

Here the coefficient −log(−τ) is not meromorphic in ϵ. This example distinguishes the weaker statement “the pole is removable for each fixed regulator” from your stronger joint-meromorphic, coefficientwise divisibility result.

Finite-order cancellation has a different budget

Suppose only

G
bℓ
	​

(−τ,ϵ)=O(ϵ
M
)

has been established. Since the differentiated kernel begins at order
ϵ
−ℓ−1
, its j-th contact can begin at

ϵ
M+j−ℓ−1
	​


with polynomial dependence on logϵ. To discard it through ϵ
N
, require

M+j−ℓ−1>N.

For all contacts, the j=0 condition is sufficient.

Equivalently, if

G
bℓ
	​

(z,ϵ)=z
q
n≥0
∑
	​

g
n
	​

(ϵ)z
n
,ν
ϵ
	​

(g
n
	​

)≥p,

only terms satisfying

n+j≤N−p−q+ℓ+1
	​


can contribute through order N.

Your proposal to keep logϵ as a separate formal symbol is appropriate for this fallback, but checking its cancellation is not enough. Log-free Laurent contacts must also be retained. In particular, a finite constant contact can remain even when every logϵ coefficient vanishes.

Nor does cancellation of the total moving residue through order N imply separate slope/log cancellation through that order: the monodromy eigenvalues coalesce at ϵ=0, and separating finite jets can lose regulator orders. Either use the exact theorem or bound the actual complete contact expression.

Recommended production sequence

Finish the divisor-support and multiplicity scan. Associate the complete source rows with the physical master definitions and the fixed-singular-locus analyticity argument. This establishes the exact scalar residue relations without moving-curve evaluations.

Restore the exact pole parts of the two finite CF1 coefficients. Keep the remaining coefficients as explicitly truncated fixed-divisor jets. Residues may remain exact sparse source sums; a single enormous rational numerator is unnecessary.

Merge the pole numerator by slope and logarithmic degree. Apply the exact monodromy-separation theorem, then compute only the demanded divided-difference coefficients using the finite bound above.

Run the usual threshold-distribution assembly on that fixed-divisor representation. Implement moving-contact expansion only for cases where the exact joint-meromorphic/divisibility certificate is unavailable but a complete targetwise correction is supported.

The decisive economical choice is therefore proof-backed scalar division, not a moving-contact campaign. The certificate can be source-level, while the division is performed on the merged scalar endpoint blocks. Until the support closure and joint-meromorphic hypotheses cover that block, neither a familywise uniformity claim nor the deletion of its moving contributions is justified.