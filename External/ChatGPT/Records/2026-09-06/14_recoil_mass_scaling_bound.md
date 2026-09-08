# Recoil-mass scaling bound

## Question

Please challenge this potentially decisive physical scaling theorem before we use it. We have implemented exact global identities and substituted ALL91 actual finite solutions:1556local boundaryseries/8811slots ->346sharedseries/2197slots. CF269 lower-sector constants at its different point are replaced by explicit already-solved lower-sector expressions with imported scalar-integral definitions (no dense bridge;4CF269 own inputs remain atitsownpoint,344otherglobalbasispositions atcommonpoint;2positionsunrequested). The known ordinary phase-volume input will removeone.

Radial hard-corner probe at epsilon=1/97:242global diagonal SCCs (sizes1..4),240fuchsifiablebyintegerdiagonalpowers,2blocks(size5total)not. Of343computed exponents109integer,234noninteger. Thus hard radial Taylor dataaloneclearlydoesn'tgivefew inputs.

More promising: recoil-mass edge z=Q^2=1-v-w ->0 atfixedv=3/5,Q=a+b-c. Every242globaldiagonalblock admitsanintegerdiagonalFuchsianrescaling;all348residueeigenvaluesrationalatsampleepsilon. Inferred slopes fromnearintegerparts:
b=-2:48directions; b=-4:32; b=-3:3; b=-1:19; b=0:234; b=+1:12, forlambda=a+b epsilon. We willverifythecharpolyfactorizationwithsymbolicepsilon beforeusingthese. Ifallphysical integralshavebound z^(D-3-M), MfixedintegerindependentofD, thenonlyb<=-2survive:83homogeneousdirections BEFOREboundaryIBP,anchors,etc. This couldrecoverrealdozens legitimately.

Candidate proof, for UNITcuts first:
The3particlemasslessphase-space factor scales z^(D-3), withallcutmomenta future andsumQ. Put k_i=sqrt(z)*hat(k_i) inQrest. Atfixedvawayfrom0,1, eachfutureexternalnull P in{a,b,c} has P.Q boundedpositive.
For tree-derived ordinary denominators, explicitly verify (using momentumconservationandcutpermutations) each q is either a subset R ofcutmomenta, or ±P±R with P oneexternalnull andRsubsetcuts; q and−qequivalent. Numerators polynomial.
- R^2=z*hat(R)^2, supplies onlyinteger zpowers.
- For (P+R)^2, denominator >=2P.R. For (P-R)^2, forsmallz, |(P-R)^2|>=const*2P.R uniformly: R^2/(2P.R)<=O(z/(P.Q)), using R0+|R| bounded byQ0 inrest.
- P.R is sumpositive P.k_i, so inverse powers bounded byone P.k_i inversepower.
The distribution of (P.k_i)/(P.Q) has finite inverse moments for ReD sufficientlylarge, uniformlyinP direction byrotationinvariance. Forproductswithdifferent P directions, Hölder bounds bysingle-factor high inverse moments, henceuniform evenwhen a,b,c directionscoalesce inQrest. Likewise subset invariant inverse momentsarefiniteforlargeD. Numerators bounded. Therefore absolutevalue integral <=C(D) z^(D-3-M) forsomefixedM; arbitrary fixedpropagatorpowers justraise theReDconvergencethreshold. Bymeromorphiccontinuation, DE modes withb>-2 cannotoccur: asDbecomeslarge theyviolate thebound regardlessofinteger valuations/logs.

Raisedcuts needcare:
We can initially applythe theorem ONLY to unitcutmasterrows and prove theyobserve thecompletehomogeneousdiagonalblock by exact differential row-span closure. Differentiationonlyshiftsintegerpowers, so an invisible leadingcomponent isnot enough tosave a forbiddenepsilon-slope mode. Blocksnotobservedbyeligibleunitcutrows remainunconstrained. Alternatively massderivatives add integerinversez powers afterlegitimatedifferentiationinthelargeDconvergencedomain, but we shouldnotassume thiswithoutproof.

Questions:
1. Is theuniformboundargumentvalid, or is therea missed angular/soft region thatcouldproduce b=-1 despite ReDlarge? Please identifyanycounterexampleorbadinequality.
2. Does exclusionforanopenlargeReDdomain legitimatelyimplyidenticallyzeromode amplitudes meromorphically nearD4? Which regularsingular/hypothesesmustbewritten?
3. Is unitcutrow observability sufficient toapplytheboundtoblockhomogeneousfreedom after lowersectorsareknown? How bestdealwithdifferent normal integergauges/source terms? We wanta conservative dimensionbound(sumretainedalgebraicmultiplicities), notunsupportedfullconnection.
4. Would83(ifvalidated) bea legitimate upperboundonremaining DE inputseries afterthisphysicalcondition (notclaimednumberofnewboundaryintegrals)? We willstillneedexplicitlocal matching/connectionstouseitinthesavedsolutions.

Pleasefocusonthistheorem. We haven'tappliedthese mode removalsyet.

## Pro response

Yes—the unit-cut bound can be proved under your stated denominator restrictions. I do not find a missing soft or angular region that permits b=−1 within that class. However, the conclusion “at most 83 input series” additionally requires symbolic regular-singularity and exponent certificates, plus observability of the excluded modes. Those are substantive conditions, but they do not require a full analytic connection matrix.

The most important corrections are: prove the estimate for a real interval of sufficiently large D, not merely integer dimensions; apply exclusion to complete local solution components rather than leading residue eigenvectors; and treat sourced blocks through differences of solutions with the same lower-sector data.

1. The uniform estimate is valid—and can be made explicit

Set s=1, as in your proposed edge. At fixed v and w=1−v−z,

a⋅Q=
2
1−v
	​

,b⋅Q=
2
v+z
	​

,c⋅Q=
2
1−z
	​

.

Thus these products have a common positive lower bound for sufficiently small z>0, uniformly for v in a compact subinterval of (0,1).

The three-particle measure has the exact scaling

dΦ
3
	​

(Q)=z
D−3
d
Φ
3,D
	​

,

where the hatted measure is the unit-mass phase space. This is also manifest in the dimensionally continued three-body Dalitz representation. 
Scipp Legacy

Your inequality for P−R is correct

Let R be a sum of a subset of the future-directed cut momenta, and S=Q−R. Both are future causal. In the Q-rest frame, write r=∣R∣. Then

R
0
+r≤R
0
+S
0
=
z
	​

.

For future-null P,

P⋅R=P
0
(R
0
−
P
⋅R)≥P
0
(R
0
−r),P
0
=
z
	​

P⋅Q
	​

.

Consequently,

R
2
=(R
0
−r)(R
0
+r)≤
P⋅Q
z
	​

P⋅R.
	​

(1)

This inequality remains meaningful when both sides vanish; no division by P⋅R is needed.

It follows that

∣(P−R)
2
∣≥(1−
2P⋅Q
z
	​

)2P⋅R,
	​

(2)

provided z<2P⋅Q. Also,

(P+R)
2
≥2P⋅R.

Both estimates are uniform over the entire phase space. In particular, they hold in the simultaneous soft/collinear corners, not just away from them.

For any selected constituent k
i
	​

 of a nonempty R,

P⋅R≥P⋅k
i
	​

.

Thus your reduction of each such inverse denominator to a single-factor inverse moment is legitimate.

The inverse moments have a simple uniform bound

Normalize the unit-mass phase-space measure to a probability measure, and define

Y
P,i
	​

=
P⋅Q
P⋅k
i
	​

	​

,U
ij
	​

=
z
(k
i
	​

+k
j
	​

)
2
	​

,α=
2
D
	​

−1.

Each variable lies in [0,1]. Their individual inverse moments are

⟨Y
P,i
−p
	​

⟩
D
	​

=⟨U
ij
−p
	​

⟩
D
	​

=
Γ(α)Γ(3α−p)
Γ(α−p)Γ(3α)
	​

,α>p.
	​

(3)

For U
ij
	​

, this follows from the Dirichlet density

(U
12
	​

U
13
	​

U
23
	​

)
D/2−2
,U
12
	​

+U
13
	​

+U
23
	​

=1,

in the three-body Dalitz measure. 
Scipp Legacy

For Y
P,i
	​

, one can derive it directly by writing

Y
P,i
	​

=x
i
	​

t
i
	​

,x
i
	​

=
z
	​

2E
i
	​

	​

,t
i
	​

=
2
1−cosθ
P,i
	​

	​

.

Rotational invariance makes the energy and overall direction independent. Their marginal distributions are respectively

x
i
	​

∼Beta(2α,α),t
i
	​

∼Beta(α,α),

whose inverse moments multiply to (3).

Now suppose the majorant contains factors X
j
−p
j
	​

	​

, where each X
j
	​

 is one of these normalized variables. Put

N=
j
∑
	​

p
j
	​

.

Weighted Hölder gives

⟨
j
∏
	​

X
j
−p
j
	​

	​

⟩
D
	​

≤
j
∏
	​

⟨X
j
−N
	​

⟩
D
p
j
	​

/N
	​

.
(4)

The right-hand side is finite for

D>2N+2,

and is independent of the relative directions of the external null vectors.

This is precisely what prevents coalescing external directions from producing an overlooked enhancement that defeats your bound. Hölder deliberately replaces the simultaneous singularities by sufficiently high individual inverse moments. It can be very wasteful, but it is uniform.

For scalar polynomial numerators, boundedness is also straightforward:

0≤P⋅k
i
	​

≤P⋅Q,0≤k
i
	​

⋅k
j
	​

≤
2
z
	​

.

Fixed rational kinematic prefactors can be covered by an additional fixed integer pole order.

Therefore, for an eligible integral,

∣I(z,v,D)∣≤C(D)z
D−3−M
	​

(5)

for all sufficiently small z>0, with M independent of D. The constant can be uniform in v on a compact interior interval. It need not be bounded as D→∞.

Two qualifications must be explicit in the theorem

First, use a positive dimensionally continued measure for real large D. Geometric arguments stated only for integer-dimensional spheres are not enough for the subsequent identity-theorem argument. Write the angular/energy integrals in a fixed finite collection of variables with the usual D-dependent beta or Gram weights. For sufficiently large real D, those weights are positive, so the same Hölder argument applies.

You do not need an inequality for complex D. An interval of real D suffices.

Second, eligibility must exclude ill-defined or differently normalized objects. An ordinary denominator that vanishes identically on the unit-cut support—such as an uncancelled k
i
2
	​

—is not covered. Nor is a denominator involving cancellations not controlled by (1), an additional virtual integration, a different number of physical phase-space particles, or a normalization containing z
γϵ
.

For comparison, a two-particle phase-space volume scales as z
D/2−2
=z
−ϵ
: it genuinely has b=−1, but it is outside your three-particle hypothesis. Similarly, dividing a three-particle integral by its phase-space volume shifts the slope classification. Your integer diagonal gauges do not cause that problem.

Under the stated eligibility conditions, no separate exhaustive region classification is needed to establish (5). It is a bound on the full physical integration domain.

2. Why the bound excludes b>−2 meromorphically

The argument is valid, but the logical order matters:

large-D estimate⟹zero forbidden coefficients there⟹analytic continuation of those zeros.

Do not analytically continue the inequality itself.

Required local form

At generic D, the relevant system must be regular singular at z=0, with a complete local solution space consisting of convergent power/log germs. For the spectra you propose, these have the form

z
a+bϵ
n≥n
0
	​

∑
	​

z
n
k=0
∑
K
	​

(logz)
k
f
n,k
	​

(D).
(6)

Regular-singular DE analysis is what connects residue exponents with such local scaling behavior; it is not necessary to have strict epsilon form. 
arXiv

Suppose a nonzero observed contribution with slope b first appears at integer shift n. Since

ϵ=2−
2
D
	​

,

its power relative to the bound is

(a+n+bϵ)−(D−3−M)
	​

=a+n+2b+3+M−(1+
2
b
	​

)D.
	​

(7)

For b>−2, this tends to −∞ as real D→+∞. Therefore, at sufficiently large fixed D, any such nonzero contribution violates (5).

A finite logarithmic polynomial cannot compensate for this strict power mismatch. Neither can a large but finite integer valuation. And an extremely small nonzero coefficient depending on D does not help: hold that D fixed and take z→0
+
.

Cancellations do not invalidate the argument—but must be treated correctly

At generic D, different slopes cannot cancel as complete power/log germs unless their exponents become congruent modulo integers. Those exceptional values of D can be avoided.

Within one slope class, however, several directions can cancel their leading coefficients. Thus:

You must exclude a complete nonzero slope component, not each leading residue eigenvector separately.

After cancellation, a nonzero component has some later first nonzero coefficient. That later integer shift still cannot rescue b>−2. For a meromorphic family, this first nonzero order is fixed generically; isolated zeros of its coefficient do not change the conclusion.

This also handles repeated eigenvalues and Jordan chains without falsely merging directions.

What must continue in D?

Use the same physical integral, branch, cut orientations and prescriptions throughout. Its ordinary-point data and the relevant local coefficient maps must admit analytic continuation in D through a connected domain, with meromorphic behavior near the dimensional-regularization point. The exact DE is an equation at generic dimension, not merely an identity of a few epsilon coefficients. 
arXiv

If the forbidden coefficient functions vanish on a real interval avoiding exceptional dimensions, the identity theorem makes them vanish throughout the connected analytic continuation. Poles and resonance points are handled by continuation around them and subsequent meromorphic limits.

Two warnings are important:

Vanishing at arbitrarily many integer dimensions alone is insufficient; sin(πD) is a simple counterexample.

At ϵ=0, different slope classes can coalesce. Impose the exclusion at generic ϵ, then take the Laurent expansion. No new free mode appears solely at ϵ=0 within a meromorphic family.

Your finite stored epsilon solutions are therefore the objects to which the resulting constraints are applied, not sufficient evidence for the generic-D exclusion themselves.

What regular-singularity verification is sufficient here?

Verify the proposed integer diagonal Fuchsian rescalings symbolically in ϵ. A pole coefficient could vanish accidentally at the sample value.

For a block-triangular system with meromorphic off-diagonal coefficients, regular-singular diagonal blocks give regular-singular extensions. Variation of constants can add integer shifts and logarithms, but not new epsilon slopes or essential exponentials. Thus a full-system analytic Fuchsian transformation is not a prerequisite for your conservative count.

Likewise, verify

det(λ1−R
j
	​

(ϵ))=
ν
∏
	​

(λ−a
jν
	​

−b
jν
	​

ϵ)
m
jν
	​

(8)

as an exact identity. “Nearest integer at ϵ=1/97” is not a slope certificate.

3. Unit-cut observability is sufficient—with the correct formulation

Your proposed route through unit-cut rows is preferable to assuming a dotted-cut theorem.

Consider a block with inherited lower-sector data:

θG
j
	​

=B
j
	​

G
j
	​

+S
j
	​

(G
<j
	​

),θ=z∂
z
	​

.

Take two candidate solutions with the same lower-sector data. Their difference h
j
	​

 satisfies

θh
j
	​

=B
j
	​

h
j
	​

.
(9)

If both candidates obey the unit-cut estimates, their difference obeys estimates of the same form.

Let E
j
	​

(z,D) select eligible unit-cut integral combinations, after removing contributions involving the fixed lower sectors. Define

E
j
[0]
	​

=E
j
	​

,E
j
[k+1]
	​

=θE
j
[k]
	​

+E
j
[k]
	​

B
j
	​

.
(10)

Then

θ
k
(E
j
	​

h
j
	​

)=E
j
[k]
	​

h
j
	​

.

A sufficient certificate is

rank
Q(z,D)
	​

	​

E
j
[0]
	​

E
j
[1]
	​

⋮
	​

	​

=dimG
j
	​

.
	​

(11)

Compute until the row space stabilizes.

For a forbidden-slope homogeneous component, the bound first implies that its complete observed output E
j
	​

h
j
	​

 vanishes. Equation (11) then implies that the component itself vanishes.

This proves the result without assuming that every eigenvector has a nonzero leading component in an eligible row.

Important implementation details

Use the differential row span, not the residue row span. The rows E
j
	​

R
j
k
	​

 alone can miss visibility arising at higher orders in z.

Keep the observation map in the physical basis. If

G
j
	​

=T
j
	​

F
j
	​

,

the eligible observation becomes E
j
	​

T
j
	​

F
j
	​

. Include T
j
	​

 and its derivatives in (10). A finite-order meromorphic gauge changes integer valuations but not b.

Do not infer derivative estimates from a bare big-O bound. Differentiation need not preserve such an estimate for arbitrary functions. Here the complete regular-singular power/log structure is what justifies preservation of the slope classification.

Normal observability at fixed v is the simplest certificate. If your closure uses tangential derivatives as well, establish the bound on an open v-interval and apply it to the complete tangential coefficient functions. Tangential closure at a single isolated v, combined with a bound only on that one ray, is not automatically the same argument. Your uniform lower bounds on P⋅Q make the neighborhood version available.

Full observability is stronger than necessary. It suffices that the unobservable solution subspace contain no b>−2 component. But full rank is likely the easiest certificate for blocks of these sizes.

Source terms determine affine relations, not necessarily zero constants

The difference-of-solutions argument is essential. In a sourced block, the coefficient called a “homogeneous constant” in an ordinary-point variation-of-constants formula can be nonzero because it cancels a forbidden contribution from the chosen particular solution. General inhomogeneous DE solutions explicitly contain this freedom in the choice of particular solution. 
arXiv

For example,

θℓ=ρℓ,θh=ℓ,ρ=D−3.

Then

ℓ=Az
ρ
,h=C+
ρ
A
	​

z
ρ
.

The physical estimate excludes the constant local mode. But if the particular solution was defined by integration from z
0
	​

,

h(z)=h(z
0
	​

)+
ρ
A
	​

(z
ρ
−z
0
ρ
	​

),

the condition is

h(z
0
	​

)=
ρ
A
	​

z
0
ρ
	​

,

not h(z
0
	​

)=0.

Therefore, your theorem constrains the dimension of the affine fiber over inherited lower-sector data. It does not authorize setting corresponding ordinary-point inputs to zero.

Raised cuts

Unit-cut observability avoids having to bound differentiated delta distributions directly. If a block is not observed by eligible unit-cut rows, leave its unobserved freedom in the count.

It may be cheaper to find additional eligible unit-cut integrals with numerator insertions and reduce them into that block than to prove a general mass-derivative theorem.

Your alternative dotted-cut argument is not established merely by differentiating (5): a bound on the massive integral does not automatically bound its derivatives at zero mass. Uniform differentiability of the integral, including moving support and endpoint terms, is a separate requirement.

4. Is 83 a legitimate upper bound?

Yes, conditionally—and it would be a genuine physical upper bound, not a period-label census.

For block j, let

m
j
keep
	​

=
ν:b
jν
	​

≤−2
∑
	​

m
jν
	​

.

If every excluded homogeneous direction is observed by eligible unit-cut rows, the admissible fiber over fixed lower-sector data has dimension at most m
j
keep
	​

.

Proceeding through the block-triangular system gives

dim(admissible DE input space)≤
j
∑
	​

m
j
keep
	​

.
	​

(12)

Using your reported slope multiplicities, the proposed bound is

48+32+3=
83
	​

.

Algebraic multiplicities are the correct conservative counts here. Repeated eigenvalues and logarithmic chains must not be replaced by geometric eigenspace dimensions or period-type counts. Lower-sector compatibility may reduce the bound further; it cannot increase these fiber dimensions.

If observability is incomplete, the conservative replacement is

dim(admissible input space)≤83+
j
∑
	​

u
j
bad
	​

,
	​

(13)

where u
j
bad
	​

 counts forbidden-slope homogeneous directions not excluded by the available observations. For an entirely uncertified block, retain all of its otherwise-discarded directions.

This is a bound on free meromorphic DE input series. It is not a claim of 83 new boundary integrals, 83 Laurent slots, or a rational IBP rank of 83. The resulting relations among ordinary-point constants can involve connection coefficients that are not rational in ϵ.

Do not automatically subtract the two unrequested positions from this spectral count: project the admissible solution space onto the demanded outputs. The known volume supplies an additional anchor when its restriction to the retained space is demonstrably nontrivial.

Recommended acceptance criterion

For the dimension bound itself, the necessary computational certificates are limited: exact denominator eligibility for the observed unit-cut rows; symbolic Fuchsian rescalings and characteristic factorizations; and exact differential observability certificates for all discarded directions. The uniform-moment argument above supplies the physical theorem.

You can certify the bound without first constructing the full noncanonical Frobenius matching or an analytic connection matrix. Those are still needed to turn the bound into explicit substitutions in the saved solutions.

The central conclusion is that your proposed recoil-edge condition can legitimately exclude b>−2 without enumerating every region. Its strength comes from uniform control of the entire physical phase space. The remaining danger is not an angular region hidden from Hölder; it is applying the theorem to an ineligible integral representation, an incorrectly normalized exponent, or an unobserved sourced-block direction.