# Remaining physical boundary coefficients

## Prompt

We implemented your coalescing-null boundary limit and one final-state pair Beta reduction. All exact normalizations/large-D hypotheses preserved. This overnight run has ~5h45 left. Please advise the next general mathematical extension; avoid family special cases.

Current results at fixed v=1/4, w=3/4-z, z=Q^2 ->0:
- Original 346 cut masters, 84 retained Fuchsian seed columns including known volume.
- Generic seed charpoly lambda*(lambda+2eps)^48*(lambda+3eps)^3*(lambda+4eps)^32; primary annihilator lambda*(lambda+2eps)^2*(lambda+3eps)^2*(lambda+4eps)^2.
- Unit cuts + external-subset invariants + at most ONE distinct pair now construct 238 whole-domain coefficients. Unhandled:87 masters with raised cuts,18 with TWO distinct pair invariants,3 with other (linear?) propagator type.
- Exact slope -2 primary jet through normal order2 suffices for those238 rows. After original gauge, lower-than-physical integer powers and forbidden logs produce32 homogeneous constraints. Five further same-Euler-profile identities; all238 leading coefficient rows add just ONE non-elementary Euler integral beyond volume. That integral is now evaluated through eps^2 with SubTropica/HyperFLINT. Thus39 independent exact equations including volume,45 unknown amplitude series remain. New relations are applied by primitive unit pivots after scaling original amplitudes by their proven Laurent bounds; no pole constraints lost.
- The recognized coefficients exhaust their current observable rank. Integrating more profiles in this set adds no information. Frobenius numerical initialization/Taylor continuation now works, with original-gauge matching-point refinement validated.

Questions:
1. Prioritize what general physical extension gives reliable rank gain next: joint final-state pair moments for18 more unit-cut integrals; raised cuts via mass derivatives with all distribution/domain terms; or external-collinear regions carrying slopes -3,-4? Explain what can be concretely achieved without a false completeness claim.
2. Can the joint conditional law for two pair invariants be reduced to a low-dimensional Euler representation with correct normalization? At fixed x~Dirichlet(alpha,alpha,alpha), alpha=(D-2)/2, write x12=x1+x2, q=sqrt(x1*x2/x12)u, K=sqrt(x12*x3)v, |u|^2+|v|^2=1. k1T=q+x1/x12 K, k2T=-q+x2/x12 K,k3T=-K. s12/z=x12 rho, rho=|u|^2~Beta(alpha,alpha). Relative angle c=u.v/(|u||v|) has density (1-c^2)^(alpha-3/2)/B(1/2,alpha-1/2). Derive s13/z,s23/z and whether angular inverse integer moments admit a rational/Beta simplification. Must preserve joint dependence; multiplying marginals is invalid. Perhaps numerator/denominator substitutions rationalize the square roots before SubTropica.
3. For raised cut powers, is there a useful global differential/IBP identity that expresses their slope -2 whole-domain coefficient from a finite-dimensional MASSIVE three-body phase-space deformation, before constructing hard collinear regions? State precisely the missing information rather than recommending differentiating a massless volume naively.
4. Is39 equations out of84 consistent with only the complete slope -2 primary component partly fixed (9 or10 dimensions remaining there plus35 other slopes)? Best cheap rank-based way to choose next observables?

Please challenge any invalid inference above; recommend a concrete sequence for reusable general NNLO boundary code. Exact physical boundary completeness remains open, and artificial numerical tests are not AMFlow physics validation.


## Pro response

Your joint angular setup is correct, and it admits a stronger simplification: two distinct pair denominators require only one additional Euler variable, with no square roots. I would implement that next, after checking its projected rank. In parallel, classify the raised-cut targets for a restricted massive-phase-space derivative construction described below; it can reduce their coefficients to shifted versions of the same fraction/pair integrals without solving a generic massive family.

Neither whole-domain extension will normally determine the 35 directions in the −3,−4 primary components. Those require additional physical information, such as selected nonuniform region coefficients.

1. First resolve the rank accounting and use it to allocate work

Your total is consistent:

84−39=45.

But the likely primary decomposition of the remaining freedom is

9 in slope −2+3 in slope −3+32 in slope −4+1 exceptional zero-slope direction.
	​

(1)

This follows if all 39 equations were constructed exclusively from the slope-−2 primary jet, as your description suggests. The known phase volume belongs to slope −2, not to the exceptional zero eigenvalue.

The alternative “10 plus 35” would require an equation also removing the exceptional direction, leaving only 38 independent conditions on the 48-dimensional −2 component. Do not decide between these counts from the total rank alone.

In a generic-epsilon primary seed basis, check the support of the current constraint matrix Q:

QΠ
−3
	​

=QΠ
−4
	​

=QΠ
0
	​

=0.

If these identities hold and rankQ=39, equation (1) follows. Perform this over the generic coefficient field, not at epsilon zero, where the primary sectors collide.

Rank-filter every next physical calculation

Write the current solution of the amplitude constraints as

c=c
known
	​

+Kf,dimf=45,

in your Laurent-bound-preserving coordinates. For candidate coefficient rows L, compute

Δr=rank(LK).
	​

(2)

Include the automatically zero lower-power and logarithmic rows in this test before evaluating any Euler integral. Apply those homogeneous equations immediately when their physical justification is established.

For the 18 two-pair integrals, this requires only their candidate physical valuations and sufficiently deep existing primary jets—not their integration. If their combined projected rank is zero, do not evaluate them for amplitude reduction.

The same test should guide the raised-cut subset. Eighty-seven unhandled masters are not evidence of 87 independent opportunities. Moreover, whole-domain slope-−2 coefficients can remove at most the remaining nine directions in that primary component under the decomposition above.

2. Two pair invariants: exact conditional law and a three-dimensional Euler integral

Any two distinct pairs among three particles share an index. By a cut-preserving permutation, take the denominators to be y
12
p
	​

y
13
q
	​

, where

y
ij
	​

=
Q
2
(k
i
	​

+k
j
	​

)
2
	​

,x
ij
	​

=x
i
	​

+x
j
	​

,α=
2
D−2
	​

.
The two remaining invariants

Your transverse variables give

y
12
	​

=x
12
	​

ρ,

and direct substitution yields

y
13
	​

=
x
12
	​

x
2
	​

x
3
	​

ρ+x
1
	​

(1−ρ)+2
x
1
	​

x
2
	​

x
3
	​

ρ(1−ρ)
	​

c
	​

,
	​

(3)
y
23
	​

=
x
12
	​

x
1
	​

x
3
	​

ρ+x
2
	​

(1−ρ)−2
x
1
	​

x
2
	​

x
3
	​

ρ(1−ρ)
	​

c
	​

.
	​

(4)

In particular,

y
12
	​

+y
13
	​

+y
23
	​

=1.

Conditional on x, the normalized measure is

B(α,α)
ρ
α−1
(1−ρ)
α−1
	​

dρ
B(1/2,α−1/2)
(1−c
2
)
α−3/2
	​

dc.
(5)

The radial split and relative angle are independent under this underlying measure. The angular normalization requires Reα>1/2; subsequent inverse moments require stronger convergence conditions. The normalization follows from the beta integral. 
DLMF

An angular integral alone is generally hypergeometric, not rational:

⟨(A+Bc)
−q
⟩
c
	​

=A
−q
2
	​

F
1
	​

(
2
q
	​

,
2
q+1
	​

;α;
A
2
B
2
	​

).
(6)

However, integrating the radial variable too gives a considerably cleaner result.

Closed joint conditional moment

Define

χ=
x
12
	​

x
13
	​

x
2
	​

x
3
	​

	​

,1−χ=
x
12
	​

x
13
	​

x
1
	​

	​

.

For interior fractions, 0<χ<1. Then

M
p,q
	​

(x)
	​

:=E[y
12
−p
	​

y
13
−q
	​

∣x]
=
Γ(2α−p−q)Γ(α)
2
Γ(2α)Γ(α−p)Γ(α−q)
	​

x
12
p
	​

x
13
q
	​

2
	​

F
1
	​

(p,q;α;χ)
	​

.
	​

	​

(7)

Here 
2
	​

F
1
	​

 is the ordinary, not regularized, hypergeometric function.

A short derivation also checks the normalization. Equations (3)–(4) imply

y
13
	​

=x
13
	​

	​

χ
	​

u+
1−χ
	​

v
	​

2
.

Replace the uniform unit-sphere pair (u,v) by two independent Gaussian vectors (U,V) in 2α dimensions, with density proportional to e
−∣U∣
2
−∣V∣
2
. For

W=
χ
	​

U+
1−χ
	​

V,

their quadratic Laplace transform is

E[e
−s∣U∣
2
−t∣W∣
2
]=[1+s+t+(1−χ)st]
−α
.

Its Mellin integrals produce the hypergeometric factor in (7). Dividing out the independent total-radius moment,

E[(∣U∣
2
+∣V∣
2
)
−p−q
]=
Γ(2α)
Γ(2α−p−q)
	​

,

gives precisely the prefactor displayed there.

For positive integer p,q, a sufficient fixed-x starting domain is Reα>max(p,q), followed by meromorphic continuation.

Eliminate the square roots completely

Using the Euler representation of the ordinary hypergeometric function, equation (7) becomes

M
p,q
	​

(x)=
	​

Γ(2α−p−q)Γ(α)Γ(q)
Γ(2α)Γ(α−p)
	​

x
13
p−q
	​

×∫
0
1
	​

[x
1
	​

+x
2
	​

x
3
	​

r]
p
r
α−q−1
(1−r)
q−1
	​

dr.
	​

	​

(8)

The Euler representation initially requires q>0 and Reα>q. 
DLMF

Multiply this by your existing normalized Dirichlet measure and external-subset profile. The final coefficient is a three-variable Euler integral, not the four-variable integral over x
1
	​

,x
2
	​

,ρ,c.

Under your existing square map,

x
1
	​

=t,x
2
	​

=(1−t)u,x
3
	​

=(1−t)(1−u),

the only new denominator is

t+(1−t)
2
u(1−u)r.
	​

(9)

No radical rationalization is needed.

This polynomial is positive in the open cube, but it vanishes on boundary strata. It is not a resolved unit on the closed cube until the relevant endpoint factors have been treated. Your current positivity distinction is exactly appropriate.

Try r as the first integration variable: its denominator evaluates to

x
1
	​

(r=0),x
1
	​

+x
2
	​

x
3
	​

=x
12
	​

x
13
	​

(r=1).

Both endpoints factor into existing fraction/complement factors. This is favorable for the polynomial reduction, but the actual integrand must still pass the integration backend’s reducibility checks.

For integer p,q, the Gamma prefactor in (7) or (8) simplifies to a rational function of α; the generic hypergeometric dependence does not disappear. Gamma recurrence should be applied before computing epsilon valuations. 
DLMF

For example,

M
1,1
	​

(x)=2(2α−1)∫
0
1
	​

x
1
	​

+x
2
	​

x
3
	​

r
r
α−2
	​

dr.
	​

(10)

At α=2, this is

x
2
	​

x
3
	​

6
	​

log
x
1
	​

x
1
	​

+x
2
	​

x
3
	​

	​

,

already showing why a universal rational/Beta-only answer is unavailable.

If either power is nonpositive, the corresponding hypergeometric series terminates; use finite polynomial moments instead of an Euler representation whose parameter assumptions fail. A numerator involving the third pair can first be expanded using y
23
	​

=1−y
12
	​

−y
13
	​

 for unit massless cuts.

Full-limit justification and tests

The existing whole-domain proof extends unchanged in structure. In Hölder, include both positive pair powers in

N=N
external
	​

+p+q.

Each individual normalized pair invariant has the same finite inverse moments used previously. Independence between pairs is unnecessary. Thus D>4N+2 remains a sufficient L
2
 condition.

The physical coefficient now multiplies

z
D−3−m−p−q
,

so it still supplies slope-−2 equations. It is a full whole-domain coefficient, not an assertion that nonuniform regions are absent at other powers.

Require reduction to the one-pair formula when one power is zero, symmetry under p↔q, x
2
	​

↔x
3
	​

, and the marginal identity

E[y
12
−p
	​

y
13
−q
	​

]=
Γ(α)
2
Γ(3α−p−q)
Γ(3α)Γ(α−p)Γ(α−q)
	​

.
	​

(11)

The last follows from the three-body invariant-simplex beta integral. 
DLMF

3. Raised cuts: a useful massive deformation exists without a generic massive IBP solve

There is no universal homogeneity identity that determines every dotted cut from massless unit-cut values. But your light-cone representation gives a more specific construction that is promising for these recognized integrands.

Exact massive phase-space geometry

Introduce independent cut masses

m
i
2
	​

=zμ
i
	​

,h(x,μ)=1−
i
∑
	​

x
i
	​

μ
i
	​

	​

,β=D−3=2α−1.

With Q and the external vectors held fixed, the raw three-body marginal measure is

dΦ
3,marginal
raw
	​

=
4Γ(D−2)
π
D−2
	​

z
β
(x
1
	​

x
2
	​

x
3
	​

)
α−1
[h(x,μ)]
+
β
	​

dx
1
	​

dx
2
	​

.
	​

(12)

Here [h]
+
β
	​

=θ(h)h
β
. This explicitly retains the moving massive domain.

It follows by replacing the massless transverse constraint by

i
∑
	​

zx
i
	​

k
i⊥
2
	​

	​

=1−
i
∑
	​

x
i
	​

μ
i
	​

	​

.

Rescale the transverse sphere by 
h
	​

. Its normalized ρ,c measure is unchanged.

The scaled pair invariants become

Y
ij
	​

(μ)=hy
ij
	​

+x
ij
	​

(
x
i
	​

μ
i
	​

	​

+
x
j
	​

μ
j
	​

	​

),
	​

(13)

where y
ij
	​

 denotes the massless unit-sphere expression. In particular,

Y
12
	​

+Y
13
	​

+Y
23
	​

=1+μ
1
	​

+μ
2
	​

+μ
3
	​

.

This is why simplifying with the massless sum rule before differentiation would be wrong.

For a coalesced external-subset profile f(x), the candidate massive coefficient is obtained by integrating

[h]
+
β
	​

f(x)
e
∏
	​

Y
e
	​

(μ)
−a
e
	​

(14)

against the same fraction and normalized angular measures.

One dot gives an explicit insertion operator

With the cut convention

Δ
n
	​

(k
2
−m
2
)=
(n−1)!
(−1)
n−1
	​

θ(k
0
)δ
(n−1)
(k
2
−m
2
),

one has

Δ
r+1
	​

=
r!
1
	​

∂
m
2
r
	​

Δ
1
	​

,∂
m
i
2
	​

	​

	​

z
	​

=z
−1
∂
μ
i
	​

	​

.
(15)

Let

F(x,y)=f(x)
e
∏
	​

y
e
−a
e
	​

	​

,A
pair
	​

=
e
∑
	​

a
e
	​

.

Differentiating (14) once and setting μ=0, in a sufficiently convergent large-D domain, gives

D
i
	​

F=
x
i
	​

A
pair
	​

−β
	​

F−
e∋i
∑
	​

x
i
	​

a
e
	​

x
e
	​

	​

y
e
	​

F
	​

.
	​

(16)

Thus a single raised cut contributes one additional integer z
−1
, and its coefficient is a finite combination of:

a shifted singleton-fraction power;

increased powers of already present pair invariants;

rational coefficients in D.

No new distinct pair invariant appears. With no pair denominators, this simplifies to

D
i
	​

f=−
x
i
	​

D−3
	​

f.
	​

(17)

Consequently, the external-subset-only dotted subclass may reduce directly to your existing two-dimensional Euler-profile backend.

For the volume, equation (17) gives

V
V
dotted
	​

	​

=−
(α−1)z
(2α−1)(3α−1)
	​

=
ϵz
(1−2ϵ)(2−3ϵ)
	​

,
(18)

recovering the previously established convention-sensitive check.

For higher cut powers, differentiate the massive expression (14) before setting μ=0, including the factorials in (15). Do not repeatedly apply (16) with unchanged β: after one differentiation the surviving powers of h have changed. Sparse automatic differentiation of the finite product is sufficient.

What remains to be proved before accepting these as physical equations

Equations (12)–(16) provide the geometry and algebra, not permission to interchange limits without checking them. The missing information is specific:

The off-shell integral definition. Preserve the original numerator and ordinary denominator polynomials before imposing cut equations. For example, k
i
2
	​

Δ
2
	​

(k
i
2
	​

)=Δ
1
	​

(k
i
2
	​

), not zero. Any explicit mass dependence of the original normalization or integrand must also be differentiated.

Derivative/domain control. For the required finite mass-derivative multi-index, establish differentiation of the full [h]
+
β
	​

 integral in a real large-D interval. There, sufficiently large β makes the relevant boundary terms vanish or gives integrable ordinary derivatives. Continue that identity meromorphically afterward. Do not drop the domain indicator at the start.

Joint recoil/mass control. The derivative must commute with the coalescence coefficient extraction. A bound for the undifferentiated unit-cut integrand does not alone establish this. In the explicit massive parameterization, check the extra inverse fraction, pair, and h powers generated by the derivatives. Terms from noncoalesced external factors must either contribute to the retained coefficient or be proved suppressed.

For a fixed finite number of derivatives in your positive-domain subclass, these checks can be formulated as finite endpoint power-counting problems. That is a much smaller task than constructing an unrestricted massive-family DE.

The sensitivity of cut formulas to doubled propagators is real; treating a doubled cut as merely the same on-shell restriction is not sufficient. 
arXiv

Where IBP helps

First derive the correct finite derivative insertions. Then reduce their shifted fraction/pair targets with your boundary integration identities or boundary IBP.

A generic massive-family reduction

∂
m
i
2
	​

	​

I=M
i
	​

(m
2
,D)I

is another valid route, but it need not specialize regularly at zero mass and may introduce additional masters. It should not be the first implementation when (16) applies.

Likewise, homogeneity only gives a relation containing

i
∑
	​

m
i
2
	​

∂
m
i
2
	​

	​

I.

Those coefficients vanish at the massless point; the individual mass derivatives are not thereby determined.

A proved raised-cut bound could also remove the exceptional zero-mode exemption if the newly eligible row observes it. Do not count that removal until the differentiated full-domain estimate is established.

4. When to move to the −3,−4 regions

Even complete success on the remaining whole-domain −2 component leaves the 35 other-slope directions. So the next region implementation should be a coefficient-targeted calculation, not a campaign-wide region classifier.

I would first target the three-dimensional −3 component, selecting an original observable whose projected coefficient row adds rank and whose denominator/domain structure is simplest.

In the Q-rest frame, external angular separations are O(
z
	​

). A collinear angular cap of that size has measure scaling

z
(D−2)/2
=z
α
.

Combined with the bulk z
D−3
, it changes the epsilon slope from −2 to −3. Two suitable independent angular scalings can produce an additional z
2α
, hence slope −4.

These are candidate scaling mechanisms, not region identifications. Soft scalings and overlap configurations can have the same epsilon slope.

The essential change from the coalescing constructor is to retain the external angular separations at their scaled size. If

n
P
	​

=n
∗
	​

+
z
	​

η
P
	​

+⋯,n
k
	​

=n
∗
	​

+
z
	​

ℓ+⋯,

the denominators retain dependence on ℓ−η
P
	​

. Setting every external direction equal first destroys the very information needed for the collinear coefficient.

For one selected observable, construct an exact domain partition or subtraction that isolates the relevant endpoint and controls the remainder. Include every contribution and overlap at the targeted generic-epsilon power, and match both the constant and logarithmic coefficients allowed by the primary Jordan structure.

An uncomputed region with the same slope cannot be declared absent merely because the computed region already matches an eigenvalue. Conditions on completeness and overlap terms are substantive parts of expansion by regions. 
arXiv

This gives an honest vertical slice: one or a few fully accounted-for coefficients at slope −3, with exact amplitude equations. It makes no claim that the overall region list is complete.

5. Recommended sequence for this run

First, perform the primary-support and candidate-rank audit. Establish whether the remaining dimensions are 9+3+32+1. Test all 18 two-pair coefficient rows and their vanishing conditions against the current free space. Classify the raised-cut targets by their underlying zero-, one-, or two-pair structure.

Also inspect the three “other” propagators algebraically. A genuine eikonal P⋅R with future-null P and future subset R fits the old proof, with scale P⋅Q rather than 2P⋅Q. A signed linear combination with possible interior zeros does not. The name “linear propagator” is insufficient for either conclusion.

Second, implement equation (8) as the two-pair backend. Canonicalize the marked pair powers together with the six fraction powers under S
3
	​

, preserve exact scales, and evaluate only a rank-increasing set of Euler coefficients.

Third, implement the restricted massive insertion algebra (12)–(16). Start with raised cuts whose coalesced integrands have no pair denominator, then one pair. Accept each subclass only after the derivative/domain checks. Use the new two-pair backend when differentiation generates higher powers of two existing pairs.

Fourth, start one certified −3 region coefficient once the inexpensive whole-domain rank gain is exhausted or screened out. Do not keep integrating zero-rank whole-domain profiles while the unresolved freedom lies in other primary components.

The decisive new simplifications are that two-pair moments are three-dimensional root-free Euler integrals, and eligible dotted whole-domain coefficients reduce to finite shifted fraction/pair insertions. Both can be implemented generically. Their payoff must still be measured by exact projected rank, while the eventual −3,−4 work must establish completeness only for the specific coefficients being used—not infer it from the residue spectrum or artificial-amplitude numerical tests.