# CF303 Soft Modes Followup

## Question

# Follow-up: CF303 soft modes from the accepted compact operator

Please continue this established Assess Multiquadratic Pipeline conversation. We implemented the explicit lazy rebase you recommended and corrected the Frobenius coordinate convention so an inward coordinate includes its differential Jacobian. I now have decisive compact data for CF303 and want the shortest mathematically complete route to the physical formal result (periods may remain named and unevaluated).

On the physical low-p branch

- `0 < p < 1/Sqrt[2]`, `u_soft = 2 p`;
- use `rho = 2 p - u > 0` approaching the boundary;
- `s = 1-v-w = alpha(p) rho + O(rho^2)` with `alpha(p)=(1-2 p^2)/(2 p)>0`;
- chart branches are `sqrt(lambda2)=-2p` and `sqrt(1-4vw)=1-2p^2`.

The accepted 43-source lazy dlog operator gives its normal residue without loading the 1.4 GB expanded connection. Only four source pole IDs contribute. Its exact 43x43 residue `R_S` has:

- rank 7, nullity 36;
- eigenvalues `-4` (multiplicity 4), `-3` (1), `-2` (2), `0` (36);
- `Nullity[R_S^k]=36` for k=1..5, so the zero sector is semisimple.

For the non-epsilon final 2-row layer:

- the three diagonal composite elliptic letters have zero normal residue at `u=2p`;
- precisely one off-diagonal GPL pole contributes, `du/(u-2p)`;
- its Laurent deck `B(eps,p)=Sum_{n=-2}^4 eps^n B_n(p)` has 26 nonzero entries at every nonzero order and generic rank 2;
- at exact sample `p=3/5, eps=1/7`, `rank(B|ker R_S)=1`;
- the full 45x45 residue `[[eps R_S,0],[B,0]]` has rank 8 and nullities of powers `{37,38,38,38}`. Thus the zero eigenvalue has algebraic multiplicity 38, geometric multiplicity 37, with exactly one length-2 Jordan chain.

The source masters split into 39 exact lower-family images and four CF303-owned seven-line masters; the final two are CF303-owned eight-line masters. Lower-family transport operators exist for all 39 inherited sources, but most physical periods remain formal Stage-3 symbols. We only need to output the exact GPL/eMPL result up to explicitly named physical periods and a precise Stage-3 needs ledger.

Please answer concretely:

1. What is the shortest exact construction of the CF303 physical selector matrix at the soft endpoint using these compact residues, without expanding the full connection or inventing arbitrary boundary functions of p?
2. How should the one generalized zero mode induced by `B|ker R_S` be represented or excluded by physical regularity? Does the rational-in-epsilon residue require a generalized Frobenius construction beyond the ordinary epsilon-form mode map?
3. Can the 39 inherited source solutions be evaluated directly at the historical interior base `u=1/2` and precomposed there, leaving only the four own-source plus two target modes for a soft Frobenius calculation? If yes, what exact tangential data are still required for those six?
4. Is there a valid way to infer zero/no-new-period conditions for the two final target homogeneous constants from soft phase-space scaling, or must one explicitly rebuild the missing CF303 nullity constraint rank?
5. Suggest a compact, reusable algorithm/API that produces (a) the regularized endpoint-to-interior selector deck and (b) the exact list of still-unevaluated boundary periods, with no dense symbolic materialization and no redundant certification layer.

Please distinguish what follows from the residue algebra above from what still needs topology/region input.

## Pro response

Verdict: CONDITIONAL GO

The compact residue data are sufficient to construct the local regular-singular selector deck without expanding the 45×45 connection. They are not, by themselves, sufficient to identify the physical selector over symbolic p: the remaining six CF303-owned modes still need either region/topology normalizations as explicit functions of p, or the induced tangential differential equation along the soft divisor.

The shortest route is:

39 inherited interior selectors⊕compact six-mode soft Levelt deck
regularized rebase
	​

u=
2
1
	​

	​


followed by the existing lazy H/K+T
25
	​

 operator.

This preserves the established architecture. CF303’s obstruction was isolated rather than indicating failure of the rest of the campaign, while deferred/provider evaluation was adopted precisely to avoid swollen symbolic source compositions. 

Pasted markdown

 

11_reconstruct_dont_simplify

 The prior production profile likewise showed that post-solve symbolic normalization—not modular solving—was the dominant cost. 

08_three_root_slowdown_and_reco…

 The deferred-leaf architecture was designed to keep exact compositions in compact channel form. 

codex_overnight_optimization_tr…

1. Compact construction of the soft selector

Set

ρ=2p−u,du=−dρ,u−2p=−ρ.

Therefore the unique final-layer pole satisfies

u−2p
du
	​

=
ρ
dρ
	​

,

with positive residue. The normal residue of the complete 45-master system is thus

R(ϵ,p)=(
ϵR
S
	​

B(ϵ,p)
	​

0
0
2×2
	​

	​

).

This is regular singular for fixed ϵ, but it is not an ordinary epsilon-form residue because B begins at ϵ
−2
.

Use the group inverse of R
S
	​


Let P
0
	​

 be the exact spectral projector onto kerR
S
	​

. Since the zero eigenspace is semisimple,

dimkerR
S
	​

=36

and the group inverse R
S
#
	​

 exists, satisfying

R
S
	​

R
S
#
	​

=R
S
#
	​

R
S
	​

=I−P
0
	​

,R
S
#
	​

P
0
	​

=P
0
	​

R
S
#
	​

=0.

Then the complete singular factor is available in closed block form:

ρ
R
=
	​

ρ
ϵR
S
	​

B[logρP
0
	​

+
ϵ
1
	​

R
S
#
	​

(ρ
ϵR
S
	​

−I)]
	​

0
I
2
	​

	​

	​

.
	​

(1)

This follows directly by integrating the lower-left block of the matrix exponential:

∫
0
logρ
	​

Be
tϵR
S
	​

dt.

Equation (1) is the shortest exact normal-mode representation. It automatically includes:

all nonzero source exponents −4ϵ,−3ϵ,−2ϵ;

any Jordan structure within the nonzero source eigenspaces;

the unique zero-eigenvalue logarithmic chain;

the rational Laurent dependence of B on ϵ.

Do not diagonalize the full 45×45 residue. Its nonzero-eigenvalue eigenvectors would contain artificial factors B/(ϵλ), producing avoidable ϵ
−3
 coordinates. The block exponential keeps cancellations such as

ϵ
B
	​

R
S
#
	​

(ρ
ϵR
S
	​

−I)

manifest.

Physical s-normalization

Since

s=α(p)ρ+O(ρ
2
),α(p)=
2p
1−2p
2
	​

>0,

a boundary vector normalized in the physical variable s and one normalized in ρ are related by

c
ρ
	​

=α(p)
R(ϵ,p)
c
s
	​

.
	​

(2)

The same block formula as (1), with ρ→α, evaluates this conversion:

α
R
=(
α
ϵR
S
	​

B[logαP
0
	​

+
ϵ
1
	​

R
S
#
	​

(α
ϵR
S
	​

−I)]
	​

0
I
2
	​

	​

).
(3)

Because α>0 on the stated branch, no additional iπ enters logα.

This is where the corrected endpoint-coordinate Jacobian and the ϵ-dependent scaling factor enter. The current BuildEndpointFrobenius implementation is restricted to a connection that becomes epsilon-independent after division by ϵ; it should therefore be applied to the 43-source system, not blindly to the full residue R. The existing boundary-mode code already maps source modes through the Frobenius prefactor and physical basis gauge, so the final two-row extension should be added through (1)–(3), not by replacing the source mode machinery.

Endpoint-to-interior selector

Let V
phys
	​

(p,ϵ) map the named physical periods into the allowed soft modes. The interior selector is

C
∗
	​

(p,ϵ)=U
reg
	​

(u
∗
	​

=
2
1
	​

,
v
soft
	​

;p,ϵ)α(p)
R(ϵ,p)
V
phys
	​

(p,ϵ).
	​

(4)

Here U
reg
	​

 is the already implemented regularized lazy rebase from the inward tangent at u=2p to u=
2
1
	​

. The analytic Frobenius prefactor H(ρ,p,ϵ)=I+O(ρ) enters inside this regularized rebase. It does not alter the endpoint coefficient c because H(0)=I.

Tangential regularization means the endpoint logarithms generated by ρ
R
 are already part of the regularized transport; they must not be multiplied in a second time. Regularized endpoint limits are equivalently described by tangential base points. 
arXiv
+1

2. The single generalized zero mode

Let K
0
	​

 be a 43×36 basis of kerR
S
	​

, and define

C
0
	​

=BK
0
	​

.

Assuming the reported rank-one result is generic over the relevant (p,ϵ) domain,

rankC
0
	​

=1.

Choose a rank factorization

C
0
	​

=tℓ,

where t is a nonzero two-component target vector and ℓ is a row functional on the 36-dimensional source zero space. Choose h with ℓh=1, and set

g=(
K
0
	​

h
0
	​

),e=(
0
t
	​

).

Then

Rg=e,Re=0,

and the generalized solution is

ρ
R
g=g+logρe.
	​

(5)
It is not an additional independent period

The coefficient multiplying this logarithmic chain is already one linear combination of the source zero-mode coefficients:

ℓc
S,0
	​

.

Thus the chain introduces no new boundary constant beyond the source periods. It induces a target logarithm from one source zero mode.

The target zero eigenspace still contains two independent pure target vectors:

(
0
e
1
	​

	​

),(
0
e
2
	​

	​

).

One lies in the same direction as the endpoint of the chain, but its constant coefficient remains independent of the chain coefficient.

Physical regularity

If region analysis proves that the corresponding physical target combination has no leading logs term, impose

BP
0
	​

c
S
	​

=0.
	​

(6)

Because the map has rank one, this is one linear condition.

It is not justified to impose (6) from residue algebra alone. Soft and threshold integrals routinely acquire logarithms after expansion in ϵ, and expansion by regions is the standard mechanism for identifying which endpoint modes and constants are actually present or absent. 
arXiv
+1

So:

Residue algebra: exactly one possible length-two zero chain.

Topology/regions: decides whether its coefficient vanishes physically.

The full final layer does require a generalized regular-singular construction beyond the ordinary epsilon-form mode map. But no generic 45×45 Levelt implementation is required: source Frobenius plus the explicit block factor (1) is complete.

One caution: the single sample p=3/5,ϵ=1/7 does not alone prove generic rank one. The construction should use a rank-one factorization of BP
0
	​

 over the accepted function-field deck, or work patchwise where a selected pivot is nonzero.

3. Precomposing the 39 inherited sources

Yes, conditionally. The 39 inherited solutions can be evaluated at the historical interior base and inserted directly into the 43-source boundary vector.

Let

F
inh
	​

(
2
1
	​

,p,ϵ)=C
inh
	​

(p,ϵ)Π
inh
	​


be their lower-family selectors, with formal lower-family period columns Π
inh
	​

. Embed this directly into the source boundary vector before running the final H/K and T
25
	​

 layers.

Two conditions are required.

Inherited-source closure

The 39-dimensional inherited source subspace must be invariant under every source residue matrix used between the soft endpoint and the interior base:

P
inh
	​

R
a
	​

(1−P
inh
	​

)=0for every source letter a.
	​

(7)

Normal-residue closure alone is insufficient. If (7) holds, the 39 source solutions can be transported independently. The four CF303-owned source rows may still receive inhomogeneous contributions from those inherited rows; those contributions must be included by the existing 43-source operator when forming their interior values.

The p=
4
1
	​

 base-point collision

The historical base u
∗
	​

=
2
1
	​

 coincides with the soft endpoint when

2p=
2
1
	​

⟺p=
4
1
	​

.

Therefore u=
2
1
	​

 is not a uniformly regular interior base over the complete interval

0<p<
2
	​

1
	​

.

The shortest exact treatment is to use two p-chambers,

0<p<
4
1
	​

,
4
1
	​

<p<
2
	​

1
	​

,

with the value at p=
4
1
	​

 defined by the appropriate tangential limit or by a second regular base-point patch. A single unqualified interior-base formula across the whole interval would hide a base-point/letter collision.

Data still required for the six CF303-owned components

For the four own-source and two final target masters, the following remain necessary:

Their original-integral soft powers and permitted log multiplicities.

Leading region coefficients, or explicit boundary-integral definitions.

The physical-to-canonical endpoint gauge, including the path gauge and T
25
	​

.

The inward tangent and branches already stated.

The p-dependence of the boundary periods.

The last item cannot be obtained from the normal residue. In coordinates (p,ρ),

u=2p−ρ

implies that the tangential connection along fixed ρ is built from

A
∥
	​

=A
p
	​

+2A
u
	​

.
	​

(8)

If

Φ(ρ,p,ϵ)=H(ρ,p,ϵ)ρ
R(p,ϵ)

is the local Levelt factor, the induced boundary connection is

Γ
soft
	​

(p,ϵ)=Reg
ρ=0
	​

[Φ
−1
(A
∥
	​

Φ−∂
p
	​

Φ)].
	​

(9)

Then the boundary mode amplitudes satisfy

∂
p
	​

c=Γ
soft
	​

c.

There are two mathematically complete choices:

Stage 3 supplies the six boundary periods as explicitly defined functions of p, associated with named boundary integrals.

Compute the induced six-mode tangential system (9), so that Stage 3 supplies only constants at one reference p
0
	​

.

Without one of these, BoundaryPeriodCoefficient[id,n] is an arbitrary function of p disguised as a constant.

4. Can the two target constants be set to zero?

Not from the residue data.

The two pure target zero modes are legitimate homogeneous solutions because the final diagonal normal residue vanishes. The rank-one map BP
0
	​

 creates one logarithmic chain, but it does not eliminate either pure target constant.

They may be set to zero only if physical information establishes that the corresponding original target integrals:

vanish with strictly positive soft power;

are fixed combinations of inherited/source periods;

or have forbidden constant/logarithmic leading terms.

The relevant test must be applied after composing with the path gauge and T
25
	​

, because a constant canonical target mode need not remain constant in the original physical basis.

The minimum calculation is not a new 45×45 nullity analysis. Restrict the exact local mode matrix to the residual six-dimensional CF303-owned sector, map it into the six original CF303 masters, and form the matrix of coefficients of all region-forbidden powers and logarithms:

C
forbidden
	​

(p,ϵ)c
own
	​

=0.

Its rank determines the number of new periods:

N
new
	​

=6−rankC
forbidden
	​

−already inherited/identified directions.
	​

(10)

In particular, the two target constants vanish only if the physical constraint matrix has rank two on their pure-target subspace. Generic phase-space suppression is not sufficient without topology-specific numerator and propagator scaling.

5. Compact reusable algorithm/API

The appropriate package object is a selector deck, not a dense endpoint matrix.

A suitable interface is conceptually:

BuildRegularizedEndpointSelectorDeck[
    SourceOperator,
    FinalResidueDeck,
    EndpointSpec,
    InheritedSelectorProviders,
    PhysicalModeRealizations,
    Demand
]
Internal algorithm

Convert the compact source residue into P
0
	​

 and R
S
#
	​

.

Construct the final normal factor through equation (1).

Form the physical-coordinate conversion α
R
 through equation (3).

Embed the 39 inherited interior selectors.

Build only the residual six-mode local selector.

Apply the physical region constraints to those six columns.

Regularized-rebase the surviving columns to u=
2
1
	​

, separately in the required p-chambers.

Precompose those columns with the existing 43-source lazy operator.

Apply the final H/K circuit and T
25
	​

 only at requested rows and epsilon orders.

Propagate Laurent valuations through the selector deck to derive the exact Stage-3 epsilon-depth needs.

Recommended output
"NormalResidueDeck"
    -> {RS, BByEpsilonOrder, ZeroProjector, GroupInverse}

"GeneralizedZeroChain"
    -> {SourceFunctional, SourceVector, TargetVector, ChainLength -> 2}

"PhysicalCoordinateTransfer"
    -> alpha(p)^NormalResidue

"InheritedInteriorSelectors"
    -> sparse provider-backed columns

"OwnModeSelector"
    -> sparse six-column deck

"EndpointToInteriorSelectorsByOrder"
    -> epsilon-order-indexed sparse matrices/circuits

"TangentialBoundarySystem"
    -> GammaSoft
       or Missing["PeriodsDefinedAsBoundaryIntegrals"]

"FormalPeriodColumns"
    -> ordered period identifiers

"Stage3Needs"
    -> records containing:
       PeriodID,
       OwnerFamily,
       BoundaryIntegralOrTangentialMode,
       SoftExponent,
       LogLevel,
       RequiredEpsilonOrders,
       InheritedProvider,
       Status

The generalized chain should be recorded as an induced action of a source-period functional, not as a separate period ID.

Largest likely performance trap

The main risk is propagating a full 45×45 endpoint connection—or every inherited period column separately—through the lazy GPL/eMPL operator.

Avoid it by precomposing at the smallest column space:

known 39-source interior selector⊕surviving six-mode selector.
	​


Then propagate only:

the distinct inherited period combinations actually appearing in the 43-source vector;

the surviving CF303-owned mode columns after physical constraints.

Keep α
R
 in the compact projector/group-inverse representation; do not expand it into a full matrix of logarithmic series. Keep composite GPL/eMPL letters unsplit until a paper coefficient is requested.

If a family phase exceeds one hour, the first diagnostic should be whether it has accidentally materialized:

all 45 mode columns;

all Stage-3 period columns before linear reduction;

or all marked-point expansions of composite elliptic letters.

Final decision

Proceed with the compact selector-deck route. Do not build a full 45×45 Frobenius solution.

The residue algebra determines:

the exact normal factor (1);

one induced length-two zero chain;

35 source zero modes that do not feed the target logarithm;

two pure target zero modes;

seven nonzero source-residue directions.

It does not determine:

whether the logarithmic chain is physically allowed;

whether either target constant vanishes;

the p-dependence or normalization of the six CF303-owned periods.

Those require the small six-mode region/tangential calculation. Once that is supplied, the existing lazy rebase plus H/K+T
25
	​

 machinery yields the exact formal physical result with a precise, finite Stage-3 period ledger.
