# Gluon reference vectors and reduced coefficient normalization

Verified outgoing model gpt-6-pro; standard thinking effort; HTTP 200.
Request: ca8b1c9d-3c6b-4b2a-8718-c3b29d7b0c59.
Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.

## Question

One additional general-workflow issue while the SIDIS implementation proceeds. Our fully generated single-inclusive q g -> observed g + X NLO UU run completed all 256 qgg real interferences and Kira reduction, but finite-field coefficient normalization rejects a momentum fraction xa in individual pre-reduction target coefficients. Coefficients are currently stripped of PDF/FF factors and expected xa^-1 xb^-1 zh^-2 powers, rationalized, and checked to be free of all hadronic momentum fractions BEFORE multiplying each target by its Kira reduction. The observed-gluon polarization projector currently uses a dual light-cone reference vector nhb whose direction depends on xa/xb in the chosen hadronic coordinate parameterization. Initial gluon projectors use the opposite beam. Applying the declared SU(N) identity CF=(CA^2-1)/(2CA) to a failing complete target (CF10, four unit indices; 16MB expression) does NOT remove xa.

I suspect this is an overly strong per-target check: gauge-reference dependence may cancel between redundant scalar integrals after IBP, even when the complete summed physical density is independent. We should ultimately require fraction/reference independence of complete master coefficients, not assume it for each unreduced target. For speed, an explicit reference n=the opposite incoming physical parton momentum for each incoming gluon, and n=ka for the observed outgoing gluon, should make every raw coefficient rational in the partonic invariants immediately (physical scattering interior has s>0,t<0,u<0 so relevant k.n is nonzero). The unpolarized projector remains -g_D+(k n+n k)/(k.n)-n^2 kk/(k.n)^2, with the incoming D-2 average and no observed FF average; no covariant-only replacement or fitted term is proposed.

Please challenge both points: (1) is per-target fraction independence unjustified in this situation, and how should exact/finite-field cancellation be deferred until the reduced result without treating numerical gauge checks as a proof? (2) is the stated explicit physical reference choice legitimate throughout the recoil endpoint w->1 at fixed interior v, for UU and incoming LL, with the full graph and ghost content already included? Any conflict with the operator normalization or use of physical 4D external observed momentum in the single-inclusive hadronic calculation? The desired fix is general code and card-level reference declarations, not manually setting physical PDF fractions to numerical values. No need to calculate a hard function for us.


## Pro response

Yes: the mandatory fraction-independence check belongs on the complete reduced coefficient vector, not on arbitrary unreduced targets. Your proposed physical reference choices are also valid at w→1 with fixed 0<v<1. Two qualifications matter: this does not establish why the particular CF10 coefficient retains x
a
	​

, and the physical qgg tree density should already be reference-independent before integration. IBP may expose a cancellation hidden by the representation; it should not be described as repairing genuine gauge dependence.

1. Why the per-target check is too strong

After stripping the declared operator and measure factors, write the real contribution as

H(ξ)=
A
∑
	​

c
A
	​

(ξ;s,t,u,D)I
A
	​

(s,t,u,D),ξ=(x
a
	​

,x
b
	​

,z
h
	​

).

Suppose Kira and the cross-family identifications give

I
A
	​

=
j
∑
	​

R
Aj
	​

(s,t,u,D)M
j
	​

.

Then the physical coefficient vector is

C
j
	​

(ξ;s,t,u,D)=
A
∑
	​

c
A
	​

(ξ;s,t,u,D)R
Aj
	​

(s,t,u,D).
	​


The condition

∂
ξ
α
	​

	​

C
j
	​

=0

does not imply ∂
ξ
α
	​

	​

c
A
	​

=0: the latter derivatives can form a relation among the targets.

For a purely illustrative relation I
3
	​

=I
1
	​

+I
2
	​

,

(a+ρ)I
1
	​

+(b+ρ)I
2
	​

−ρI
3
	​

=aI
1
	​

+bI
2
	​

.

Every displayed target coefficient depends on ρ, but the integral combination does not. Collecting every diagram contribution to each target does not remove this redundancy.

Therefore:

A “complete target coefficient” is not necessarily the coefficient of an independent object. Your current rejection is justified only if the target representation has already been proved independent under the relevant on-shell, algebraic, symmetry, and integration relations. Completion of diagram summation alone does not establish that independence.

The unsuccessful substitution

C
F
	​

=
2C
A
	​

C
A
2
	​

−1
	​


only excludes that particular color redundancy as the explanation for the isolated coefficient. It neither disproves eventual reference cancellation nor demonstrates that an IBP relation is responsible.

Which reduced vector should be checked?

Use a common, fraction-independent master basis after all relevant family equivalences and normalizations have been applied. Checking each family’s local master vector separately can reproduce the same mistake when different families contain equivalent masters.

Also ensure that fractions have not migrated into the definition of a master:

M
j
local
	​

(ξ)=h
j
	​

(ξ)M
j
canonical
	​

.

The check belongs after this normalization is accounted for.

Independence of every coefficient in a genuinely independent, fraction-free master basis is necessary and sufficient. If the retained “masters” still satisfy additional relations, coefficientwise independence remains a sufficient acceptance condition, but a failure can still reflect that residual redundancy.

Hold the partonic invariants fixed

The intended statement is absence of additional fraction dependence at fixed partonic kinematics. It is not independence under changing x
a
	​

 while keeping the hadronic invariants fixed. With massless collinear kinematics,

s=x
a
	​

x
b
	​

S,t=
z
h
	​

x
a
	​

	​

T,u=
z
h
	​

x
b
	​

	​

U.

Those changes would alter the physical partonic scattering. These are the conventional single-inclusive mappings. 
arXiv

Thus the derivative test should mean

∂
x
a
	​

	​

C
j
	​

∣
s,t,u,D
	​

=0,

and similarly for x
b
	​

,z
h
	​

, after the declared scalar normalization has been stripped. A convenient independent chart uses

S=
x
a
	​

x
b
	​

s
	​

,T=
x
a
	​

tz
h
	​

	​

,U=
x
b
	​

uz
h
	​

	​

.

Finite-field evaluations must respect this mapping rather than treating all six invariants and fractions as independent.

2. The stronger underlying identity is local gauge-reference independence

For an on-shell gluon define

d
D
μν
	​

(k,n)=−g
D
μν
	​

+
k⋅n
k
μ
n
ν
+n
μ
k
ν
	​

−
(k⋅n)
2
n
2
k
μ
k
ν
	​

.

This is the physical transverse polarization sum, provided k⋅n

=0; using another external momentum as n is legitimate. 
FeynCalc

Introduce

B
μ
(k,n)=
k⋅n
n
μ
	​

−
2(k⋅n)
2
n
2
k
μ
	​

.

Then

d
D
μν
	​

(k,n)=−g
D
μν
	​

+k
μ
B
ν
+B
μ
k
ν
,

so two reference choices obey the exact identity

d
D
μν
	​

(k,n
′
)−d
D
μν
	​

(k,n)=k
μ
V
ν
+V
μ
k
ν
,V=B(k,n
′
)−B(k,n).
	​


For the complete tree amplitude with the other external states physical,

k
μ
A
μ
	​

=0.

Consequently,

A
μ
∗
	​

[d
D
μν
	​

(k,n
′
)−d
D
μν
	​

(k,n)]A
ν
	​

=0

at each allowed phase-space point.

In a non-Abelian amplitude, the qualification about the other external states matters. One should not replace it with an unrestricted tensor identity while summing other gluons covariantly without their appropriate ghost completion. Covariant external sums and their ghost completion must represent the same physical-state sum. 
arXiv

For your qgg real calculation, this implies:

Reference dependence should cancel within the complete physical real contribution. It should not require virtual corrections, PDF/FF counterterms, or finite helicity-scheme terms.

The cancellation can be hidden by different momentum routings, partial fractions, cut relations, tensor reductions, or redundant scalar integrals. Kira can expose it. But a reduced cancellation does not establish that the unreduced density lacked the local Ward identity.

A useful diagnostic is therefore an amplitude-level Ward contraction for the observed gluon, or the exact reference-difference contraction above. This can be substantially smaller than simplifying the entire squared expression. Apply it with the remaining physical polarizations—or with the correctly completed physical density—not to an arbitrary open-index tensor.

There is also a cheap preliminary distinction:

d
D
	​

(k,λn)=d
D
	​

(k,n).

If the old reference depended on fractions only through its magnitude, that dependence would cancel within the projector itself. Your statement that its direction depends on x
a
	​

/x
b
	​

 explains why this simpler identity is insufficient.

3. Defer cancellation without weakening the correctness requirement

The change should be “allow declared temporary variables until physical assembly,” not “ignore surviving fractions.”

Separate admissibility from physical independence

At the unreduced-target stage, retain checks for exact algebra, declared variables, correct dimensional treatment, valid cuts, and compatible kinematic relations. But allow x
a
	​

,x
b
	​

,z
h
	​

 and declared reference parameters as temporary coefficient variables.

Then assemble

C=cR
	​


before requesting that the result contain only the declared partonic variables, regulator, scales, and color/flavor parameters.

For performance, evaluate this sparse linear combination over finite fields directly. There is no need to expand or individually reconstruct every 16 MB target coefficient before multiplying by its reduction. Evaluating coefficient expressions, applying a reduction matrix, and reconstructing the resulting combinations is precisely a supported use of finite-field computational graphs. 
arXiv

For the existing run, this means preserving the x
a
	​

-dependent target expression, passing it through its reduction, and summing every contribution to each common master. For the new physical-reference run, the reference-generated nuisance dependence should largely disappear upstream.

Keep proof and sampling distinct

There are three different statements:

Exact arithmetic at a sample point. A nonzero residual at an admissible finite-field point detects a failure of the proposed rational identity. Zero at sampled points is useful evidence, not an identity proof.

Reconstructed rational functions. Reconstructing the complete master coefficients, including any possible nuisance dependence, gives candidate exact expressions. Do not prescribe a fraction-free reconstruction ansatz and then cite its fraction-free output as evidence that the discarded dependence canceled.

An established rational identity. This requires an exact verification of the reconstructed expression against the source combination, or a deterministic modular verification with sufficient bounds. Finite-field samples can be used to reconstruct algebraic identities; their role is not restricted to approximate numerical comparisons. 
arXiv

For example, for a reconstructed coefficient C=N/Q, independence of a variable ξ is the polynomial identity

Q∂
ξ
	​

N−N∂
ξ
	​

Q=0.
	​


Its validity for the original calculation additionally requires that N/Q has been established as the original assembled coefficient.

This does not mandate a giant characteristic-zero Together call. One can verify algebraic identities in a factored representation, use a Ward-identity reduction, or use denominator-cleared modular polynomial verification with proven degree and coefficient bounds. Without such a certificate, describe fresh-prime and fresh-point agreement as probabilistic validation, however strong.

For the finite-field evaluation itself, retain generic D or generic Laurent coefficients, respect the declared SU(N) relations at generic N, and exclude poles and singular reduction specializations. Checking only D=4 would miss evanescent reference dependence.

Do not substitute numerical PDF fractions into the production coefficient. Values assigned during finite-field evaluation are sampling coordinates for reconstructing an identity, not a redefinition of the physical fractions.

Do this before endpoint expansion

The preferred ordering is

complete master assembly⟶fraction/reference cancellation⟶endpoint and Laurent expansion.

Your order planner still controls any earlier truncation.

An exact finite-ϵ identity between correctly defined cut integrals survives distributional continuation. A check only at ordinary w<1 points, or after dropping regulator-suppressed terms, does not independently establish equality of endpoint delta and plus terms.

4. The proposed references are nonsingular at the recoil endpoint

Let k
c
	​

 be the observed gluon and use

s=(k
a
	​

+k
b
	​

)
2
,t=(k
a
	​

−k
c
	​

)
2
,u=(k
b
	​

−k
c
	​

)
2
,
v=1+
s
t
	​

,w=−
s+t
u
	​

.

These give

t=−s(1−v),u=−svw,s
X
	​

=s+t+u=sv(1−w).

For an incoming gluon, choosing the opposite incoming momentum gives

k
a
	​

⋅k
b
	​

=
2
s
	​

.

For the observed gluon, choosing n
c
	​

=k
a
	​

 gives

k
c
	​

⋅n
c
	​

=k
c
	​

⋅k
a
	​

=−
2
t
	​

=
2
s(1−v)
	​

.
	​


Therefore, at fixed s>0 and 0<v<1,

k
a
	​

⋅k
b
	​

>0,k
c
	​

⋅k
a
	​

>0,

and neither denominator approaches zero as w→1. In fact, both are independent of w. Since the references are null, the n
2
 term vanishes exactly.

This remains true throughout the integration over the recoil system: these scalar products involve only the fixed external partonic kinematics. Thus the reference choice introduces no new 1/(1−w) singularity and no singular gauge factor at the recoil threshold.

There are two boundaries to this statement.

First, n
c
	​

=k
a
	​

 becomes unsuitable at the separate beam-collinear boundary v→1, where t→0. A general reference selector should associate this choice with its domain. The alternative n
c
	​

=k
b
	​

 has

k
c
	​

⋅k
b
	​

=
2
svw
	​

,

which is nonzero near w=1 for v>0. This motivates reference charts for broader kinematic coverage, not a change at the recoil endpoint you are currently treating.

Second, the same nonsingularity argument does not automatically apply to a reference assigned to an unobserved integrated gluon: its dot product with a beam can vanish in a collinear region. Keep that issue separate from the fixed observed leg.

What this does and does not guarantee about raw coefficients

The proposed references remove the extra hadronic direction. Their denominators are partonic invariants:

k
a
	​

⋅k
b
	​

1
	​

=
s
2
	​

,
k
c
	​

⋅k
a
	​

1
	​

=−
t
2
	​

.

Thus they eliminate this source of fraction-dependent coefficients without introducing new integration-dependent denominators.

However, “every raw expression is immediately a rational function of s,t,u” is too literal. Before integral decomposition, the density still depends on scalar products involving recoil momenta. Explicit coordinate parameterizations can also retain removable square roots or redundant fraction expressions. The structural expectation is:

After expressing scalar products in the declared partonic basis, coefficients of the remaining integral numerators and denominators should acquire no additional hadronic variables from these references.

A fraction-free result in this gauge is not itself proof of gauge correctness: an incomplete diagram sum can also be fraction-free.

5. UU, incoming LL, operator normalization, and ghosts
The same choice works for LL

For incoming LL, the gluon helicity density uses the existing BMHV four-dimensional antisymmetric tensor, schematically

ρ
Δg
μν
	​

(k,n)=−
2
i
	​

k⋅n
ε
ˉ
μνρσ
k
ρ
	​

n
σ
	​

	​

,

with your established amplitude/conjugate index order and color average.

For physical four-dimensional k,n,n
′
, the four-dimensional Schouten identity implies

ρ
Δg
μν
	​

(k,n
′
)−ρ
Δg
μν
	​

(k,n)=k
μ
V
ν
−k
ν
V
μ

for an appropriate V. The Ward identity therefore removes the reference dependence for definite helicity as well. Changing a helicity reference is not changing the physical helicity axis.

The proposed change of the outgoing unpolarized reference is even simpler: the same symmetric-projector argument applies separately to each incoming helicity configuration, hence also to their LL combination.

The existing finite helicity-PDF scheme conversion remains required in its usual place. No additional finite PDF or FF conversion arises from changing this reference, and such a conversion must not be used to remove gauge-reference dependence. The known HVBM helicity-restoring subtraction addresses the regulator’s polarized splitting-function convention, not an external polarization-reference choice. 
arXiv

Physical four-dimensional momenta are compatible with the D-dimensional sum

With k,n physical,

d
D
μν
	​

(k,n)=d
4
μν
	​

(k,n)−
g
^
	​

μν
.
	​


Changing the physical reference modifies only the four-dimensional gauge terms. It does not remove the evanescent polarization contribution.

Therefore retain exactly the prescribed normalization:

incoming U gluon: 
D−2
d
D
	​

	​

,observed U gluon: d
D
	​

.

A four-dimensional observed momentum does not mean that its spin sum should be reduced to two states. Conversely, none of this permits setting the evanescent components of the integrated recoil momenta to zero. The standard HVBM single-inclusive setup makes precisely this distinction between physical external momenta and dimensionally integrated recoil momenta. 
arXiv

Separate polarization references from operator dual vectors

This is the important interface issue when replacing nhb.

A polarization reference is homogeneous:

d
D
	​

(k,λn)=d
D
	​

(k,n).

It need not obey a dual-vector normalization such as P
h
	​

⋅n
h
	​

=1. If the existing correlator interface requires that normalization, use

n
h
	​

=
P
h
	​

⋅k
a
	​

k
a
	​

	​


within that interface; it produces the same polarization sum as n=k
a
	​

.

But do not replace nhb globally if it also defines light-cone operator contractions or their scalar normalization. Separate, or explicitly reconcile, the operator dual direction and the external polarization reference. Otherwise a leftover P
h
	​

⋅n
h
	​

 factor can masquerade as gauge dependence.

The expected x
a
−1
	​

x
b
−1
	​

z
h
−2
	​

 factors should continue to follow from your established operator and observed-spectrum definitions. Their powers must not be adjusted to make the new gauge pass.

Changing the reference does not change the ghost prescription

You are changing n within the same physical transverse sum, not replacing that sum by −g
D
	​

. Therefore this change alone neither introduces nor removes ghost contributions.

Keep internal ghosts and any existing external covariant-sum completion consistent with their actual roles. In particular, a leg already treated with a physical transverse sum must not also receive the ghost correction intended to remove its unphysical polarizations. FeynCalc’s documentation explicitly distinguishes these two treatments. 
FeynCalc

For the two possible observed-gluon tags, instantiate the reference declaration on the tagged leg after relabeling. The tag sum and identical-particle symmetry factor remain unchanged.

Recommended general implementation

Use card-level reference declarations resolved before hadronic coordinate expansion, for example schematically:

Wolfram Language
"PolarizationReferences" -> <|
  "IncomingGluon" -> OppositeIncomingMomentum,
  "ObservedGluon" -> IncomingMomentum[1]
|>

The compiler should check on-shellness, dimensional status, and k⋅n

=0 on the declared domain. It should not change internal propagator gauge.

Separately, split coefficient validation into unreduced admissibility and complete-master physical independence. Assemble target coefficients with their reductions before reconstruction wherever that avoids expression growth. Existing Kira tables can be reused when the new numerator targets lie in their already reduced closure; equality of diagram sets alone is not sufficient to establish that.

The appropriate fix is therefore both changes together: remove the universal per-target independence requirement, and eliminate the avoidable hadronic reference direction at the source. Retain an exact Ward/reference-difference identity as the physical justification and the complete reduced fraction-independence check as the assembly test. Neither the isolated CF10 failure nor success in the new reference choice, by itself, settles the correctness of the full generated density.