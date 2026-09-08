# Coalescing reduction divisor and endpoint order analysis

Consultation: GPT-6 Pro, 2026-09-07.

## Question

We found a concrete complication with the two finite CF1 coefficient records. Please challenge the next mathematical step before we commit to a costly calculation.

We retain exact epsilon-dependent coefficients for all other physical masters; only these two CF1 coefficients are finite jets through epsilon^5 (starting at epsilon^-4 and epsilon^-2). Original reconstruction traces were deleted, but all 374 exact Kira reduction outputs and 1,296 original amplitude-pair results remain. We can do targeted source assembly without regenerating amplitudes.

An exact audit of 59,864 reduction entries feeding these two CF1 masters found 15,246 distinct inverse-polynomial bases. All but one class obey a fixed joint z/epsilon divisor structure. In 732 coefficients across 16 source families there is a simple inverse of
  f = 5 D a - 5 D b - 3 D c - 26 a + 26 b + 18 c,
where a=s, b=-t=s v, c=-u=s w. With D=4-2 epsilon and z=1-v-w,
  f = -2 s [2 epsilon (1-v) + 3 (1+epsilon) z].
It therefore coalesces with z=0 as epsilon->0.

This divisor does NOT cancel inside every individual reduction coefficient. Exact witness: CF230 source powers {1,1,1,-2,1,1,1,1,0} reducing to CF1 volume, at D=13/3,a=1,b=1/4,c=13/20, has denominator zero and numerator -306761/3600000. The full amplitude-weighted residue may still cancel; an agent is testing that targeted sum, including main weight1/2 and ghost weight-1. We will not infer uniformity from the known epsilon jets.

The two CF1 masters have the closed DE
Av = {{(1-2e)/(-1+v+w),0},{(-2+3e)/(v(-1+v+w)),-e/v}},
Aw = {{(1-2e)/(-1+v+w),0},{(2-3e)/((-1+w)(-1+v+w)),-e/(-1+w)}}.
Their physical normal expansion has slope -2 only, and uniform individual sector epsilon lower bounds0. The first is the phase-space volume, beginning z^(1-2e); the second begins z^(-2e). Other families have slopes -2,-3,-4 and negative amplitude epsilon bounds. Exact physical seeds are matched to all family endpoint systems, and scalar projection uses W=c^T T before H_n.

Questions:
1. If the coalescing pole survives the complete CF1 coefficient, how should the general production path handle it without falsely treating the two finite jets as a uniform remainder? Does one need a globally combined master basis/gauge, or can exact coalescing residues be extracted from retained source reductions and separated from a jointly meromorphic regular coefficient remainder? Explain the minimum exact source data needed.
2. Is a surgical representation c = residue(e,v)/(z-z_c(e,v)) + regular(e,v,z) sufficient, keeping the pole term unexpanded until combined with masters? Could exact apparent-pole regularity of the DE supply a divided-difference or polynomial-division construction using finitely many normal and epsilon coefficients, with a provable order budget?
3. A finite epsilon jet of 1/(z+epsilon) has a remainder with growing fixed z poles; do not assume its pointwise O(epsilon^6) controls its distributional order. Please analyze when the volume factor z^(1-2epsilon) or an epsilon valuation of the residue makes the unresolved part harmless through epsilon^0, and when the second CF1 master can still affect finite contacts. We need a genuine bound, not a heuristic.
4. Recommend the shortest sound implementation sequence. We can perform targeted rational residue tests and symbolic residue reconstruction in (epsilon,v), but rebuilding all huge exact three-variable coefficient functions is undesirable. If the chosen family-by-family decomposition cannot certify a uniform scalar density before combining overlaps, say that explicitly.

The final result remains a threshold distribution on the half-open domain, not a fully integrated or finite NNLO cross section. Numerical checks should remain proportionate; AMFlow already validated all345 physical masters at a generic point.


## Response

The residue-first approach is sound; treating the two stored jets as uniform input is not yet justified. A global master-basis change is not required. You can isolate the obstruction using two-variable residues, retain a certified fixed-divisor remainder, and resolve only the scalar block carrying this divisor.

There is also a concrete inconsistency in the stated CF1 onset that changes the order budget.

1. First distinguish the physical master basis from the normalized endpoint basis

From the supplied matrices,

A
z
	​

=(
(1−2ϵ)/z
−(2−3ϵ)/[z(v+z)]
	​

0
−ϵ/(v+z)
	​

).

Its residue eigenvalues are 1−2ϵ and 0, not 1−2ϵ and −2ϵ.

Indeed, writing I
1
	​

=V(ϵ)z
1−2ϵ
, the second equation is

∂
z
	​

I
2
	​

+
v+z
ϵ
	​

I
2
	​

=−
v+z
(2−3ϵ)V(ϵ)
	​

z
−2ϵ
.

If the physical seed eliminates the slope-zero homogeneous solution, then

I
2
	​

=−
(1−2ϵ)v
2−3ϵ
	​

V(ϵ)z
1−2ϵ
+O(z
2−2ϵ
).

Thus the unrescaled second component cannot begin at z
−2ϵ
. That onset can belong to an explicitly shifted component, but its coefficient must shift too.

For example, if I=zJ, a coefficient pole

z−z
c
	​

r
	​

I

has pole residue z
c
	​

r in the coefficient of J, not r. Since z
c
	​

=O(ϵ), this changes its ϵ-valuation.

Apply the bounds below using the residue and normal exponent in the same representation. Your W=c
T
T ordering is appropriate; mixing a physical-coefficient residue with a normalized-component onset is not.

2. Exact residue extraction is sufficient to recover a uniform coefficient remainder

Set

τ(ϵ,v)=
3(1+ϵ)
2ϵ(1−v)
	​

,z
c
	​

=−τ,f=−6s(1+ϵ)(z−z
c
	​

).

For each affected physical coefficient, construct

c
i
	​

(ϵ,v,z)=
z−z
c
	​

r
i
	​

(ϵ,v)
	​

+q
i
	​

(ϵ,v,z).
	​


The exact residue is obtained directly from the retained source data:

r
i
	​

=
source terms a
∑
	​

ω
a
	​

[(z−z
c
	​

)P
a
	​

(ϵ,v,z)K
ai
	​

(ϵ,v,z)]
z=z
c
	​

	​

,

where P
a
	​

 is the amplitude-pair multiplier, K
ai
	​

 the reduction coefficient, and ω
a
	​

 includes the stated main/ghost weights and normalization maps.

This needs exact regulator dependence of the relevant source multipliers, not their stored physical coefficient jets. It does not require reassembling the complete three-variable numerator.

The minimum exact information is:

The contributing source-to-master maps and multipliers, including analytic prefactors and main/ghost weights.

The complete principal part on this divisor, with confirmation that the pole remains simple after multiplication.

A fixed-divisor/pole-budget certificate for everything left after subtraction.

Your denominator census is useful for the last item, but it must include the source multipliers, not only the Kira entries.

Why the regular remainder can stay a finite jet

For a representative rational term h(z)/(z−z
c
	​

), with h regular at z
c
	​

,

z−z
c
	​

h(z)
	​

=
z−z
c
	​

h(z
c
	​

)
	​

+
z−z
c
	​

h(z)−h(z
c
	​

)
	​

.

After clearing the admitted denominators of h, the last numerator is polynomially divisible by z−z
c
	​

. Thus the last term has only fixed divisors. Evaluating at z
c
	​

 can introduce additional pure ϵ-poles, which must be recorded.

Consequently, after obtaining r
i
	​

,

q
i
[≤5]
	​

=c
i
[≤5]
	​

−[
z−z
c
	​

r
i
	​

	​

]
[≤5]
	​


is sufficient to retain the existing data without rebuilding the huge exact q
i
	​

. Its remainder is now subject to the ordinary fixed-divisor order analysis. Demand additional regular coefficients only if that analysis actually requires them.

This is a local removal of a reduction artifact, not a requirement for global canonicalization. Difference-quotient reorganizations have also been used to make cancellations of spurious Gram denominators manifest. 
arXiv

Coefficient residues are not the final cancellation test

If the individual r
i
	​

 do not vanish, the relevant condition is

R(ϵ,v)=
i∈B
f
	​

∑
	​

r
i
	​

(ϵ,v)I
i
	​

(v,z
c
	​

,ϵ)=0,
	​


where B
f
	​

 includes all physical masters whose coefficients carry this divisor, not just the two CF1 entries.

This equation presumes the participating masters are analytic at z
c
	​

 for fixed nonzero ϵ on the chosen branch. Nonzero CF1 residues can cancel against residues multiplying other masters. Conversely, master regularity at z
c
	​

 does not imply R=0.

For small real negative ϵ, z
c
	​

>0 lies inside the threshold integration region. The half-open-domain convention therefore does not avoid this obstruction. Do not assign a new principal-value or i0 prescription to this reduction denominator.

3. Divided differences work—but require more than ordinary-point DE regularity

For one logless primary block, suppose the pole contribution has been written

F
pole
	​

=z
bϵ
z−z
c
	​

G(z,ϵ,v)
	​

,

where, after clearing known finite powers of ϵ and z, G is jointly holomorphic near (z,ϵ)=(0,0), uniformly on compact tangential patches.

If

G(z
c
	​

,ϵ,v)=0

is an exact identity, then

z−z
c
	​

G(z)
	​

=
z−z
c
	​

G(z)−G(z
c
	​

)
	​


has the required fixed-divisor local representation. Apply this construction to the analytic coefficient after factoring the regulated powers—not by differentiating the full z
bϵ
 expression across its branch point. Retaining such powers is essential because the normal and regulator limits need not commute. 
arXiv

A finite, provable normal-order budget

Write

G(z,ϵ)=
n≥0
∑
	​

G
n
	​

(ϵ)z
n
,ν
ϵ
	​

(G
n
	​

)≥−Puniformly in n.

Then

[z
k
]
z−z
c
	​

G(z)−G(z
c
	​

)
	​

=
n≥k+1
∑
	​

G
n
	​

(ϵ)z
c
n−k−1
	​

.

Because ν
ϵ
	​

(z
c
	​

)=1, computing this coefficient through ϵ
M
 requires only

n≤k+1+M+P.
	​


For each retained n, G
n
	​

 is needed through

ϵ
M−(n−k−1)
.

Here M must already include the downstream distributional demand.

That supplies the requested finite construction. Finite coefficients can compute the quotient to sufficient order; they do not by themselves prove the exact identity G(z
c
	​

)=0. Alternatively, prove a sufficiently high-order zero and bound the unresolved moving-pole remainder as below.

The DE can help verify a proposed relation. On the moving curve,

dv
dI
c
	​

	​

=[B
v
	​

+(∂
v
	​

z
c
	​

)A
z
	​

]
z=z
c
	​

	​

I
c
	​

.

Use this equation to test preservation of the proposed residue relation and match the physical solution using existing seeds. The absence of a pole in the original CF1 DE at z
c
	​

 supplies no vanishing condition on an arbitrary coefficient row.

Finally, cancellation of the total residue at fixed nonzero ϵ is weaker than a joint fixed-divisor certificate. Distinct slopes evaluated at z
c
	​

=O(ϵ) introduce factors like ϵ
bϵ
. Require primary-block divisibility or explicitly account for the resulting moving-scale contributions. Do not infer familywise uniformity from cancellation after summing different slopes.

4. The genuine distributional bound is a moving-scale bound

Consider a logless term

F
pole
	​

=r(ϵ,v)
z+τ
z
q−2ϵ
A(z,ϵ,v)
	​

,

with integer q, A jointly holomorphic, its coefficient valuations bounded below by zero, and

ν
ϵ
	​

(r)=p.

For a sharp leading estimate assume A(0,0,v)

=0. Include all primary-amplitude, normalization, and projector poles in p.

The issue is the region z∼ϵ, which is absent from a fixed-z Taylor expansion. Such additional scaling regions can supply contributions needed to cancel poles or logarithms generated by the outer expansion. 
arXiv

Why increasing the coefficient-jet depth does not fix it

The exact geometric remainder is

z+τ
1
	​

−
m=0
∑
L
	​

z
m+1
(−τ)
m
	​

=
z
L+1
(z+τ)
(−τ)
L+1
	​

.

For L≥q, its leading contact moment, initially defined with an independent exponent α and then analytically continued, is

∫
0
∞
	​

z+τ
(−τ)
L+1
z
q−L−1+α
	​

dz=(−1)
q+1
τ
q+α
sin(πα)
π
	​

.

This follows from the beta integral and gamma reflection formula. Replacing the constant test function by a compactly supported function equal to one near zero changes only the higher-order outer contribution relevant to this estimate. 
DLMF
+1

Setting α=−2ϵ, the missing contact starts at

ϵ
p+q−1
,
	​


independently of how large L is. With an explicit log
ℓ
z, differentiation in α gives the sufficient bound

ϵ
p+q−ℓ−1
	​


with possible accompanying logarithms of ϵ.

These estimates hold on fixed complex regulator sectors avoiding the moving pole on the integration contour, with branches inherited from the original continuation. They do not prescribe a new physical continuation.

For the stated logless, amplitude-bound-zero situation:

Actual scalar mode	Error from ignoring the coalescing tail	Sufficient condition for no contribution through ϵ
0

Volume-type z
1−2ϵ
	Starts at ϵ
p
	p≥1
Effective z
−2ϵ
 mode	Starts at ϵ
p−1
	p≥2

These are bounds on the error of using the fixed-z coefficient jet, not on the entire exact pole contribution. Additional exact cancellations can improve them.

Also, p is the valuation of the extracted residue—not the starting order −4 or −2 of the stored coefficient. Substituting z=z
c
	​

 can turn fixed z-poles into additional ϵ-poles.

Two sharp examples

For τ=ϵ,

z+ϵ
z
1−2ϵ
	​

⟶1

as a distribution when ϵ→0
+
. But its outer expansion includes

z
−2ϵ
−ϵz
−1−2ϵ
+⋯.

Using the usual endpoint continuation,

z
−1−2ϵ
=−
2ϵ
1
	​

δ(z)+finite distributions,

the outer expansion gives

1+
2
1
	​

δ(z)

at finite order. The omitted coalescing tail contributes −
2
1
	​

δ(z). This persists at any finite geometric truncation L≥1, including a jet through ϵ
5
. The endpoint identity used here is the standard dimensional-regulator subtraction identity. 
arXiv

Similarly,

z+ϵ
ϵz
−2ϵ
	​

⟶0,

whereas its outer expansion has finite term

−
2
1
	​

δ(z).

The missing tail supplies +
2
1
	​

δ(z).

Thus the volume factor alone does not save a residue of valuation zero, and an effective second-master residue of valuation one can still change the finite contact.

A finite local correction is available when division is not established

For an integer-power, logless primary block

F
pole,ρ
	​

=
z+τ
z
b
ρ
	​

ϵ
G
ρ
	​

(z,ϵ)
	​

,

the missing moving-scale contact contribution relative to the sufficiently deep outer expansion is, asymptotically through the demanded order,

C
ρ
	​

=−
sin(πb
ρ
	​

ϵ)
πτ
b
ρ
	​

ϵ
	​

G
ρ
	​

(−τ,ϵ)
j=0
∑
J
ρ
	​

	​

j!
τ
j
	​

δ
(j)
(z).
	​


Explicit logarithmic blocks are obtained by differentiating the kernel with respect to its exponent, holding their coefficients fixed.

This formula need not introduce an unevaluated moving-curve function. If

G
ρ
	​

=z
q
n≥0
∑
	​

g
ρn
	​

(ϵ)z
n
,ν
ϵ
	​

(g
ρn
	​

)≥p,

then through ϵ
N
, only

n+j≤N−p−q+ℓ+1
	​


can contribute for a block with log
ℓ
z. Hence only finitely many normal coefficients, regulator coefficients, and delta derivatives are required.

This is a possible narrowly supported extension for your simple coalescing divisor. It is not permission to leave the exact pole as an unresolved expression in the final output. Materialize the finite correction and combine the affected scalar blocks.

The factors τ
b
ρ
	​

ϵ
 generate logϵ. Any such terms at retained orders must cancel in the merged result if you claim an ordinary meromorphic Laurent expansion of the bare kernel. Likewise, derivative delta functions cannot simply be deleted to fit the requested basis. Sector-subtraction constructions obtain Laurent coefficients only after the singular structure has been properly resolved. 
arXiv

Recommended implementation sequence

Resolve the onset/basis mismatch and finish the exact amplitude-weighted residue test. Reconstruct only the two-variable residues needed for the two finite CF1 records. Include all prefactors and weights before deciding they vanish.

If those residues vanish, use the fixed-divisor certificate to rehabilitate the existing jets. No deeper coalescing analysis is needed. If they survive, store exact pole parts plus finite, explicitly truncated fixed-divisor remainders.

Collect the complete scalar block sharing f. Prefer a certified common-primary divided difference. Otherwise use the finite moving-scale correction above, with its explicit order budget, and combine overlaps before checking the final distribution basis.

Fail explicitly when a relevant residue, branch prescription, or overlap cancellation remains unresolved. A family-by-family decomposition cannot certify a uniform scalar density when its surviving pole requires cancellations outside that family. This does not invalidate the solved master systems or require another generic-point AMFlow campaign.

The immediate calculation worth committing to is therefore targeted residue reconstruction and its scalar overlap closure—not reconstruction of all huge exact coefficient functions and not a global gauge change. The output domain remains your threshold half-open domain; excluding w=0 does not eliminate a divisor that moves into z=0 with the regulator.