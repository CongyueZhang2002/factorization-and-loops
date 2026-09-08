# Endpoint distribution domain and finite-order truncation

## Question

Follow-up on our stage4 endpoint assembly. The general symbolic-v normalized endpoint system/matching passed fullCF198 (11 components) andCF300 (24 components), and the91-family depth0 campaign is running. Exactmain+ghost coverage resolves to345masters; physicalmeasureconversion, hadronicflux andinitialcoloraverage are explicit. We keep only source unintegrated observed momentum kc; no observed angular/energy Jacobian is silently inserted. z=1-v-w, v=-t/s,w=-u/s. A general scalar projector first combines W=c^T T, then constructs coefficients of W H z^R c0. Finite coefficient data througheps5 remain explicitlytruncated. Separate regulated primary-sector Laurentbounds include spectral-projector poles (notjust bounds of the sum, where slopes maycancel).

Two focused mathematical questions before finaldistributions:
1. At fixedv in(0,1), z runs[0,Z(v)] withZ=1-v. Butz=Z meansw=0; thefullbare coefficient mayhaveobserved collinear poles there. We can prove/compute localFrobenius subtraction nearz0, and store thefull2-variablefinite interiorF and R=F-S (notreplaceR bylocalTaylor). Howbest tostateandimplement the single-thresholddistribution without falselyclaiming globalintegrabilityatw0? Isit rigorouslyvalid to keep conventional [log^kz/z]_+,[0,Z] and delta contactmomentsZ^(b eps)/(b eps), but define actionon smooth testfunctions compactlysupported awayfromz=Z, withR locallyintegrableonlynearz0 andon0<z<Z? Or should production choose localcutoffchi andincludean explicitoverlap/transitionterm? Please comparepracticalamplitude-communitypresentation andwhat isneededfor barehardkernelpaper-levelclaim. We will notrepresentthis asfinitefullNNLOcrosssection.
2. Our exactcoefficienttable storesphysicalmaster terms with independentnormalization/analyticprefactors (s^eps,Pi^eps) and2finiteepsiloncoefficientrecords. Normaldepth iscomputedfrom c^T T atgeneric eps afterignoringfinite tails onlywhen a uniformper-primary distributionbound puts themabovetarget. Toavoidneedlesslycombininghugepolynomials, isit safeto firsttruncate eachfinite coefficientrecord to its mathematicallysufficienttargetorder, thencompute normaldepth of thatfiniteepsilonpolynomial W? We explicitlyrejectcoalescingdivisorslikez+eps in coefficientdenominators andnormalgauge. Areanyadditionalorderoflimitsconditions missing?

Giveconcisecriticalguidanceand recommendedpreciseoutputdomain/convention. No needa newglobalboundarycalculation orredundantAMFlowchecks.

## Pro response

Yes to the restricted-domain prescription. Pretruncation is also safe under your sectorwise bounds, but the resulting normal depth is sufficient through the requested distributional order—not necessarily the exact generic-ϵ depth.

1. Keep the conventional plus prescription, with an explicitly excluded upper boundary

I recommend retaining the conventional [0,Z(v)] plus distributions as the production default. A cutoff is not required for rigor.

On each certified tangential patch U⊂(0,1), use the domain

Ω
thr
	​

={(v,z):v∈U, 0≤z<1−v}.

Test functions are smooth up to and including z=0, with compact support away from w=0 and the boundaries of U. At fixed v, this means

φ∈C
c
∞
	​

([0,Z)),Z=1−v,

where this notation allows φ(0)

=0. Do not use C
c
∞
	​

((0,Z)), which would make the threshold-supported terms invisible. This is the usual local-distribution framework, applied to a half-open domain with a retained threshold boundary. 
What's new

Define

⟨δ(z),φ⟩=φ(0),⟨D
k
Z
	​

,φ⟩=∫
0
Z
	​

z
log
k
z
	​

[φ(z)−φ(0)]dz.

Then the meromorphic identity remains

z
−1+α
=
α
Z
α
	​

δ(z)+
k≥0
∑
	​

k!
α
k
	​

D
k
Z
	​

,

with logarithmic modes obtained by ∂
α
ℓ
	​

. This is the finite-upper-limit version of the standard endpoint-subtraction identity. 
arXiv

The upper-endpoint singularity of F does not invalidate this identity: the moment Z
α
/α integrates the chosen power-law subtraction model, not F. Although φ vanishes near Z, φ−φ(0) does not; its finite tail precisely supplies the compensation associated with the subtraction endpoint. Consequently, an evaluator must not stop the plus-subtraction integral at the support of φ without adding that tail correction. 
arXiv

For each requested Laurent coefficient, the actual pairing is

⟨F
n
	​

(v,⋅),φ⟩=
	​

D
δ,n
	​

(v)φ(0)+
k
∑
	​

D
k,n
	​

(v)⟨D
k
Z
	​

,φ⟩
+∫
0
Z
	​

R
n
	​

(v,z)φ(z)dz,
	​


where

R
n
	​

=[ϵ
n
](F−S)

uses the full interior solution.

The needed integrability statement is

R
n
	​

(v,⋅)∈L
loc
1
	​

([0,Z)),

not L
1
([0,Z]). For a joint (v,z) distribution, establish this locally uniformly in v, for example through a bound

∣R
n
	​

(v,z)∣≤C
K
	​

z
−1+η
(1+∣logz∣
m
),η>0,

near z=0, on each compact K⊂U, together with interior local integrability.

What a cutoff changes

An ϵ-independent smooth cutoff χ(v,z), equal to one near z=0 and zero near Z, is an optional alternative:

F=χS+R
χ
	​

,R
χ
	​

=F−χS=R+(1−χ)S.

For the cutoff-subtracted kernel defined by integrating
χz
−1+α
[φ−φ(0)], the contact moment becomes

M
χ
	​

(α)=
α
Z
α
	​

−∫
0
Z
	​

(1−χ)z
−1+α
dz.

The second term is analytic near α=0. Differentiate this formula for explicit logarithmic modes.

Thus a cutoff merely redistributes finite terms among the contact coefficient, subtraction distribution, and ordinary remainder. Do not combine cutoff-weighted subtraction integrals with the unchanged Z
α
/α moment unless the displayed compensation is included. It also does not resolve the w=0 singularity, which remains in R
χ
	​

.

The conventional form is therefore preferable for the analytic presentation; a cutoff can be useful for numerical localization or later patch assembly. Extending the result to tests that reach w=0 requires that endpoint’s own extension/subtraction, and potentially a joint analysis where boundaries meet. Multiple singular endpoints are not regularized merely by subtracting at one of them. 
arXiv

Recommended paper/output convention:

The result is the Laurent expansion of the bare double-real coefficient as a distribution at z=0, acting on smooth test functions compactly supported away from w=0 and tangential-domain boundaries. Plus distributions use the subtraction interval [0,1−v]. The remainder is threshold-regular and locally integrable on the stated half-open domain; no integrability or distributional extension at w=0 is asserted. Normalization remains that of the source coefficient with unintegrated observed momentum k
c
	​

.

In particular, φ=1 on the whole interval is not an admissible test. Neither the contact coefficient nor this representation defines the fully integrated bare coefficient.

2. Pretruncate the finite records, then determine targetwise normal depth

Your proposed optimization is valid with a noncircular truncation certificate.

Let f
r
	​

 be one finite coefficient record and

Δf
r
	​

=f
r
	​

−f
r
[≤K
r
	​

]
	​

=O(ϵ
K
r
	​

+1
).

For each primary sector ρ, let m
rρ
	​

 be a certified lower-order shift of the complete downstream distribution map, valid for the entire allowed remainder class:

ν
ϵ
	​

(L
rρ
	​

g)≥ν
ϵ
	​

(g)+m
rρ
	​

.

This shift includes all relevant normalization, gauge, Frobenius, seed, spectral-projector, and contact-moment poles. Then

K
r
	​

+1+m
rρ
	​

>Nfor every relevant ρ
	​


makes the discarded part irrelevant through ϵ
N
. Use separate bounds for different consumers when that saves work. For products of finite records, include the other factors’ lower Laurent bounds when assigning each record’s cutoff.

The key restriction is that these initial bounds must come from a coarse untruncated pole budget, not from the already-truncated normal depth. After establishing them, refining the depth using the smaller polynomial is legitimate.

Compute the depth coefficientwise

Once every participating factor has its sufficiently deep Laurent jet, write

W
jet
=
j=j
min
	​

∑
J
	​

ϵ
j
W
j
	​

(v,z).

With formal ϵ,

ord
z
	​

W
jet
=
j
min
	​

ord
z
	​

W
j
	​

	​


using the minimum over components for a row vector. This avoids a large generic-ϵ polynomial combination. Exact cancellations within a coefficient can tighten the depth; conservative component/block bounds can only request extra work.

Two qualifications matter:

Truncating c does not automatically make c
T
T an ϵ-polynomial. Rational-ϵ gauge factors and analytic prefactors need their own sufficient jets, or must remain exact factored objects. Their expansion depth is determined by downstream poles, not simply by the final target N.

The depth is targetwise. A discarded term such as

ϵ
K+1
z
−d

can change the exact generic-ϵ normal depth while making no contribution through the certified output order. Preserve that distinction in the result metadata; the omitted tail has not become identically zero.

Additional order-of-limits conditions

Rejecting denominators such as z+ϵ is necessary but not a complete acceptance criterion. A convenient sufficient condition for factors whose expansions are interchanged is

f(v,z,ϵ)=ϵ
−p
z
−d
G(v,z,ϵ),

with fixed finite p,d and G jointly analytic near (z,ϵ)=(0,0), locally uniformly on the admitted v-patch—or the corresponding explicitly supported fixed-ramification version.

This requires checking branch divisors and analytic factors as well as denominators. For example, 
z+ϵ
	​

 and exp(ϵ/z) violate the required fixed local expansion structure even without a denominator of the literal form z+ϵ. More generally, the z-pole budget must not grow without bound with the ϵ-Taylor order.

Keep z
b
ρ
	​

ϵ
 and its Jordan logarithmic structure outside that interchange: retain the regulated modes until the distribution map has been applied. Their normal limit and ϵ-expansion do not generally commute. 
arXiv
 Fixed-branch s
ϵ
 and π
ϵ
, with s

=0 fixed, are harmless analytic units, but their required Taylor coefficients still participate in cancellations and finite contact terms.

The production sequence should therefore be:

coarse sectorwise bounds ⟶ sufficient input jets ⟶ coefficientwise depth of W ⟶ demanded Frobenius coefficients.
	​


Under those conditions, early truncation removes algebra that provably cannot affect the result, without changing the threshold distribution or requiring additional boundary normalization.