# Fixed measured-slice Laurent bound review

Verified model: gpt-6-pro, standard; HTTP 200. Request 7300528f-38e6-4a81-90c5-f47bfefe7e03.

## Request

Please review one precise mathematical extension before I implement it in the common framework (not SIDIS-specific).

The common master-definition and Baikov constructor now accepts typed particle and measurement cuts. For a measured two-body integral it reproduces dPhi2/dz exactly, including the signed repeated measurement delta. Across all four q-q RR components, exact affine identities reduce 248 positions to 57 classes; exact closure of their differential relations leaves 42 spanning masters. Sampled pivot selection is now checked against the entire exact rational relation space. The same finite solver and order planner pass one-, two-, and three-variable tests.

Remaining question: can the EXISTING compact-cut Laurent pole bound be extended to fixed generic measured slices without introducing another i0-certification criterion?

Current theorem for pure phase-space masters: at fixed physical external kinematics, use independent inverse-propagator/Baikov coordinates u. The forward particle domain is compact. The external Gram span has one time direction. All active ordinary denominator zeros lie on the true transverse Gram boundary, with established algebraic Gram-dominance bounds; large real D therefore gives absolute convergence and all required finite normal derivatives. After differentiating the cut distributions in that convergence half-plane, the remaining integral is over a compact semialgebraic domain with density
  pref(e) R(u,e) P(u)^(a0 + c e - m),
where P is the transverse Gram determinant, R rational, and all singular divisors are regulated by P. Resolution of singularities gives a conservative Laurent lower bound val(pref)+val(numerator)-n*val(c e), n = number of residual Baikov variables. Existing code carries the exact normalization and signed finite cut derivatives.

Proposed measured extension:
1. Add r independent real affine measurement constraints among the scalar-product coordinates. Their Jacobian with the existing cuts is nonzero at the fixed generic external point. No variable-dependent acceptance theta beyond forward particles/Gram positivity.
2. Keep measurement cuts separate from energy-directed particle cuts. The constrained slice is compact; require a nonempty strict Gram/positive-energy interior and a restricted Gram polynomial that is not identically zero.
3. Restrict the established parent Gram-dominance inequalities to this affine slice. The extra coordinates are linear, so their cut Jacobians add no loop-dependent singular factors.
4. For finite particle and measurement dots, take all normal derivatives in independent cut coordinates in a sufficiently large-D convergence domain, including the moving Gram/energy-domain extension. Then analytically continue.
5. Apply the same compact semialgebraic pole-multiplicity argument with n reduced by the independent measurement cuts. Do NOT infer external-endpoint uniformity, and do NOT claim pointwise convergence of finite-i0 regulators from an already existing test-function-only certificate.

Is this sufficient to establish the fixed-generic-measurement Laurent bound? Precisely what additional hypotheses/proof are needed for normal derivative boundary terms, degeneration of the slice, or uniformity in a neighborhood of the measured value? Can the parent Gram bounds + independent affine coordinates + strict slice interior establish the needed local uniform high-D domain, or is a further quantified algebraic condition necessary? Please challenge the argument rather than assuming it.

Example dimensions: L=2, E=2 gives seven independent scalar products. Three particle cuts plus one independent linear measurement leave n=3. The naive conservative bound would then be val(pref)+val(numerator)-3 for an exponent linear in epsilon, as opposed to the unmeasured five/six-variable bound. I will not use that number until the general proof/conditions are established.

The question is about a rigorous sufficient bound for epsilon-order planning at ordinary interior points, not about computing boundary values or crossing external x/z endpoints. Mixed virtual/cut loops are a separate scope. We retain the same meromorphic forward-tip convention and ordinary prescriptions.


## Response

Yes—the reduced-dimension Laurent bound can be established within the existing certificate. But step 4 needs a uniform normal-derivative argument; compactness and a nonempty slice alone do not supply it. If your parent Gram-dominance estimates hold uniformly on the full allowed mass-deformed domain, they provide the missing ingredient without a new i0-certification criterion.

For the stated L=2,E=2 example, the resulting bound is conditionally

val
ϵ
	​

I≥val
ϵ
	​

(explicit factors)−3.
	​


The explicit factors must include all regulator poles and numerator zeros after the cut-normal derivatives have been performed. This is a bound at fixed generic measurement values, not on the subsequently assembled endpoint distributions.

1. Formulate the extension as a normal-jet theorem

Let

N=
2
L(L+1)
	​

+LE

be the number of independent scalar products. Suppose there are c independent particle constraints and r independent affine measurement constraints. Complete them to affine coordinates

u⟷(s,v),s∈R
c+r
,v∈R
n
,n=N−c−r.

The s
i
	​

 should be the actual defining polynomials of the cuts, with their declared normalization—not merely alternative functions with the same zeros.

At fixed external kinematics, this coordinate transformation has a constant, nonzero Jacobian. If its coefficients depend on measurement parameters, choose a sufficiently small neighborhood where its determinant remains bounded away from zero, and include derivatives of that parameter dependence.

Write the uncut Baikov density locally as

F
ϵ
	​

(s,v)=χ
Ω
	​

(s,v)R(s,v,ϵ)P(s,v)
λ(ϵ)
,λ(ϵ)=a
0
	​

+c
ϵ
	​

ϵ,

where P>0 denotes the appropriately signed true transverse Gram polynomial on the physical component. Here χ
Ω
	​

 retains the physical Gram component and forward-energy conditions.

For cut orders ν
i
	​

, set α
i
	​

=ν
i
	​

−1. In the cut coordinates, your normalization

C
ν
i
	​

	​

(s
i
	​

)=
α
i
	​

!
(−1)
α
i
	​

	​

δ
(α
i
	​

)
(s
i
	​

)

gives, where differentiation is justified,

I
ν
	​

(ϵ)=
α!
N
ext
	​

(ϵ)
	​

∫d
n
v∂
s
α
	​

F
ϵ
	​

(s,v)∣
s=0
	​

.
	​

(1)

The two derivative signs cancel. Converting this normal derivative into a derivative of a measured variable can introduce the already tracked constraint-rescaling signs and Jacobians. The distinction follows directly from the action of delta derivatives. 
DLMF

Equation (1), with the parent forward-tip convention, is the step to prove. Once it yields a finite sum of ordinary n-dimensional integrals of the stated form, the pole-multiplicity argument is straightforward.

Particle and measurement powers change the required normal-jet order. They do not change the number n of residual integration variables.

2. When the parent bounds supply the missing uniformity
2.1 Use a neighborhood in measurement values and the existing mass cone

Let U be a small neighborhood of the chosen measurement value z
0
	​

, and let

0≤μ
i
	​

≤δ

be a sufficiently small collection of allowed particle mass-squared increments.

At fixed future-timelike total momentum, the forward particle momenta have a common compact bound. Their scalar products therefore lie in a common compact set. An affine coordinate transformation with uniformly invertible coefficient matrix places all corresponding residual domains inside one fixed box.

For particle-normal derivatives, retain the parent theorem’s already justified mass-jet construction and meromorphic forward-tip convention. Do not silently extend its domain to negative cut masses. The additional measurement parameters can vary on both sides of z
0
	​

; that does not require changing the particle-cut convention.

2.2 The useful parent hypothesis is pointwise Gram domination

Suppose every active ordinary denominator Q
j
	​

 has an established bound, throughout that common physical domain,

∣Q
j
	​

∣
−1
≤C
j
	​

P
−κ
j
	​

,P>0,
	​

(2)

with constants and exponents independent of the nearby masses and measurement values.

Restricting to an affine slice preserves (2) immediately. Measurement variation merely selects other points of the same parent domain.

Polynomial derivatives are bounded on the common compact set. Consequently, differentiating

RP
λ

a finite number of times only:

increases the finite powers of the existing Q
j
−1
	​

;

introduces finite powers of P
−1
;

produces polynomial factors in λ;

differentiates bounded numerator and coordinate factors.

For each required derivative order q, one therefore obtains a conservative estimate of the form

	​

∂
s
α
	​

(RP
λ
)
	​

≤C
q
	​

(λ)P
Reλ−K
q
	​

,∣α∣≤q.
	​

(3)

Here K
q
	​

 is finite, and C
q
	​

(λ) is locally bounded in a right half-plane of λ, away from explicit prefactor poles.

For example, if

R=
∏
j
	​

Q
j
b
j
	​

	​

N
	​

,

a deliberately loose estimate can budget q additional powers of every denominator and q powers of P
−1
:

K
q
	​

=q+
j
∑
	​

κ
j
	​

(b
j
	​

+q).

There is no need to optimize this threshold merely to establish a Laurent lower bound.

Choose Reλ large enough that all relevant derivatives vanish at P=0. Taking the budget through one order beyond the required jet is a convenient conservative way to establish differentiability of the zero extension.

2.3 Moving boundaries must be included in that argument

Require that every moving physical boundary of the chosen forward component is contained in

P=0.

This includes the energy-boundary/tip loci already handled by the parent theorem. Fixed auxiliary box boundaries can be placed outside the support.

Under this condition and (3), the zero-extended integrand has the required finite regularity in the measurement-normal directions. In the high-D convergence domain, differentiation produces the derivatives of the interior expression without additional uncompensated boundary distributions.

This is the controlled statement. It is not the assertion

∂
s
	​

χ
Ω
	​

=0.

Terms from differentiating χ
Ω
	​

 are suppressed by the vanishing normal jets of the weighted density in that initial domain. Their continued consequences are subsequently contained in the meromorphic family.

Nor do you need every slice to intersect every Gram-boundary stratum transversely. A boundary can be singular or tangent to the measurement fiber; sufficiently high powers of P, together with the quantitative bounds, can still make the required finite jets well defined.

2.4 Is another quantified algebraic test required?

Not if the parent certificate already has the uniform bounds just described. The measured extension can reuse their witnesses, enlarge the finite derivative budget, and restrict the domain. It does not need a second prescription-independence test.

If the parent result instead provides only convergence after integrating the unmeasured variables, that is insufficient. An integrable function need not have an integrable restriction to every affine slice. For example,

(u
2
+v
2
)
−3/4

is locally integrable in two dimensions, whereas its restriction to v=0 is ∣u∣
−3/2
, which is not.

Likewise, separate estimates for each mass point, with uncontrolled constants, are not yet a common neighborhood estimate.

There is a useful algebraic fallback within the same certificate. On a closed bounded semialgebraic total domain, uniform zero containment

Z(Q
j
	​

)⊆Z(P)

implies a uniform inequality

P
A
j
	​

≤C
j
	​

∣Q
j
	​

∣

for some finite exponent A
j
	​

. This is the semialgebraic Łojasiewicz inequality. Including the mass parameters as coordinates makes the quantification uniform over the allowed compact parameter set. 
arXiv

Thus the necessary condition is quantitative and uniform, but it need not be newly solved when your existing witnesses already establish it.

3. Strict slice interior is useful, but does not mean “no degeneration”

A strict point on the slice gives

P>0,all required energies>0.

Together with the full-rank affine constraints, it ensures that nearby measured values have nonempty physical fibers and that the fiber has the expected dimension n.

It does not establish that every boundary stratum varies regularly with the measured value.

For example, consider the elementary family

F(a,λ)=∫
−1
1
	​

(u
2
−a)
+
λ
	​

du.

At a=0, the affine constraint selecting a is regular, the restricted polynomial u
2
 is not identically zero, and the fiber has a strict positive interior away from u=0. Nevertheless,

F(a,0)={
2,
2−2
a
	​

,
	​

a<0,
0<a<1,
	​


so the continued density is not differentiable at that interior parameter value.

For sufficiently large Reλ, any specified finite number of a-derivatives is controlled. The example therefore separates two issues:

The high-D normal-jet construction can work without a globally regular boundary fibration.

After continuation, a classical pointwise derivative at a critical measured value need not exist.

For the planner, define the master at the fixed point by the proven high-D fiber integral and its meromorphic continuation. If it is also to be treated as an ordinary coefficient function in a neighborhood, require that the point belong to an appropriate regular parameter chamber.

Do not let a StrictInterior test stand in for that latter statement. A boundary-compatible stratification and exclusion of its critical values is a sufficient way to establish a regular chamber, but a full such computation is not necessary merely to obtain the fixed-fiber pole bound.

Reject the ordinary fixed-fiber bound when the restricted Gram polynomial vanishes identically or the physical fiber has no strict n-dimensional interior. Such a case can describe threshold-supported distributions or a lower-dimensional period and needs its own representation.

4. Why the pole order is at most the residual dimension

Assume that the preceding argument has produced

I(ϵ)=
τ
∑
	​

f
τ
	​

(ϵ)∫
Ω
0
	​

	​

d
n
vR
τ
	​

(v,ϵ)P
0
	​

(v)
a
0
	​

+c
ϵ
	​

ϵ−m
τ
	​

,
(4)

with:

compact semialgebraic Ω
0
	​

;

a fixed branch P
0
	​

>0 in its interior;

all spatial singular divisors controlled by P
0
	​

;

the meromorphic family obtained from the common convergence domain.

Resolving the relevant polynomial divisors and rectifying the domain gives finitely many local charts with normal-crossing factors. This is the resolution-based construction of meromorphic polynomial-power distributions; sector decomposition is its familiar computational realization for dimensionally regulated integrals. 
Wiley Online Library
+1

A chart integral has the form

∫
[0,1]
n
	​

h(y,ϵ)
j=1
∏
n
	​

y
j
A
j
	​

+B
j
	​

ϵ
	​

d
n
y,
	​

(5)

where h is smooth in y and holomorphic in ϵ after explicit regulator poles have been factored out.

Taylor subtraction in one coordinate gives terms containing

A
j
	​

+k+1+B
j
	​

ϵ
1
	​

.
(6)

For a fixed coordinate j, at most one Taylor index k makes the constant term of this denominator vanish. Thus that coordinate contributes at most one simple epsilon pole. The elementary extraction in (6) is also the pole-isolation step in sector-decomposition algorithms. 
arXiv

There are n coordinates in each chart. Consequently,

pole order of the integral in (5)≤n.
	​

(7)

Different charts are added, not multiplied. Increasing their number does not increase this maximum order.

If B
j
	​

=0, a divergent factor in that coordinate cannot be regulated by varying ϵ. Such a factor must be absent under the assumed high-D convergence hypothesis. It is not legitimate to assign it “one epsilon pole” anyway.

The correct valuation formula

For each term, extract

f
τ
	​

(ϵ)R
τ
	​

(v,ϵ)=ϵ
b
τ
	​

R
τ
	​

(v,ϵ),

where 
R
τ
	​

 has no remaining explicit regulator pole and its spatial divisor is fixed.

Then

val
ϵ
	​

I≥
τ
min
	​

b
τ
	​

−n.
	​

(8)

With a common explicit prefactor and numerator valuation b, this is your proposed

val
ϵ
	​

I≥val
ϵ
	​

(pref)+val
ϵ
	​

(numerator)−n,
	​


provided all epsilon-dependent denominator factors have already been included in the first two terms.

For a more general exponent displacement δ(ϵ) with

val
ϵ
	​

δ=h,

the same argument gives the conservative bound

τ
min
	​

b
τ
	​

−nh.

For c
ϵ
	​

ϵ with nonzero constant c
ϵ
	​

, h=1.

Finite dots change the shifted exponents m
τ
	​

, the high-D threshold, and the explicit coefficients. They do not increase the maximum number of independent pole-producing coordinates.

5. Four restrictions on the valuation calculation
Differentiate before determining numerator zeros

The valuation must be computed after the signed normal derivatives, their prefactors, and the slice restriction.

For example,

sC
2
	​

(s)=C
1
	​

(s),

whereas replacing s by zero first would incorrectly eliminate the term. Similarly, a numerator s+ϵ has valuation one after unit-cut restriction but its first normal derivative is 1, with valuation zero.

A numerator factor observed only after an invalid early support substitution cannot improve the bound.

Include explicit epsilon denominators

A factor 1/ϵ
q
 in R, an angular normalization, a basis normalization, or a cut-coordinate Jacobian is outside the geometric n-pole count. It must appear in b
τ
	​

.

The valuation of a polynomial numerator is the minimum valuation of its exact coefficients, not its value at one generic numerical point in the residual coordinates. Taking the minimum termwise is conservative; exact cancellation may improve it.

Exclude regulator-dependent spatial divisors unless separately justified

“R is rational” is too broad on its own. For the simple rule, require that its spatial denominators be epsilon-independent, with all regulator-only factors separated.

For example,

∫
0
1
	​

u+ϵ
du
	​

=log(1+ϵ)−logϵ

does not have a Laurent expansion at zero. Merely observing that u+ϵ is nonzero for positive real ϵ does not establish the required meromorphic family.

Original scalar masters with fixed ordinary denominators fit the intended restriction. Do not accidentally apply the theorem to a representation containing a moving spatial pole created by an epsilon-dependent transformation.

Keep the unexpanded polynomial-power form

Cut-normal derivatives do not differentiate the exponent’s dependence on ϵ. They produce

(λ)
j
	​

P
λ−j
×rational factors,

not extra logarithmic insertions.

If the input instead already contains log
q
P, this is effectively an exponent derivative and can increase pole order. The n-bound should therefore be applied to the exact unexpanded family, before extracting its Laurent coefficients.

Likewise, summing arbitrarily many pre-expanded logarithmic terms is not a substitute for the meromorphic construction. Polynomial-power distributions and their continuation are the appropriate objects. 
arXiv

6. The L=2,E=2 case and its actual scope

Here

N=
2
2(3)
	​

+2(2)=7.

Three independent particle constraints and one independent affine measurement leave

n=7−3−1=3.
	​


Thus, once the extension’s hypotheses are established,

val
ϵ
	​

I≥b−3.
	​


For these same L,E and three particle cuts, the unmeasured residual dimension is

7−3=4,

not five or six. A previous five- or six-variable bound came from a different external span, coordinate representation, or stage of constraint elimination. Count the independent residual variables in the representation to which the proof is applied.

No additional loss of one power is needed merely because the measurement cut is repeated. Its finite derivatives have already been included in (4).

This bound does not apply unchanged to endpoint delta/plus coefficients. Integrating or distributionally extending in an external variable can introduce further regulator poles. Nor does a fixed-z bound exclude a contribution supported entirely at an exceptional measured value.

It also does not promote a test-function-only i0 certificate into pointwise convergence of η-regulated fibers. The new result is a fixed-fiber Laurent bound derived using the parent’s approved definition and domination estimates. Its scope should be recorded separately from any stronger claim about the ordinary-regulator limit.

7. Minimal implementation and decisive regressions

I would implement this as a measured-fiber specialization of the current certificate, with the following proof data:

Required datum	Role
Rank of the combined particle/measurement coordinate map	Establishes n and a nonsingular cut Jacobian
Strict physical point and (P	_{\rm slice}\not\equiv0)
Parent uniform Gram-dominance witnesses	Controls all spatial denominator powers
Particle and measurement normal-jet orders	Determines the enlarged finite derivative budget
Moving-boundary containment in P=0	Justifies zero-extension differentiation
Explicit regulator valuation and nonzero exponent slope	Converts the geometric n-bound into a Laurent bound

No explicit resolution computation is required simply to use the conservative multiplicity theorem. Resolution supplies the proof of the bound; it need not become another expensive production calculation.

Three synthetic tests would be particularly informative.

A sharp dimension-counting test. For

P(u)=
j=1
∏
n
	​

u
j
	​

(1−u
j
	​

),
∫
[0,1]
n
	​

P(u)
−1−ϵ
d
n
u=B(−ϵ,−ϵ)
n
∼(−
ϵ
2
	​

)
n
.

This saturates the n-pole bound.

A moving-boundary test with an essential evanescent coefficient. For a<1,

F(a,λ)=∫
a
1
	​

[(u−a)(1−u)]
λ
du=(1−a)
2λ+1
B(λ+1,λ+1).

For large Reλ,

∂
a
	​

F=−λ(1−a)
2λ
B(λ,λ+1).

At λ=0, its continuation is −1, not zero. This tests that the algorithm keeps the product of a vanishing normal-derivative coefficient and an integral pole. It also tests the moving-domain treatment without adding an independent boundary term.

A distinction between strict interior and regular dependence. Use the F(a,λ)=∫(u
2
−a)
+
λ
	​

du example above. It should be accepted as a high-λ finite-jet test when its bounds pass, but not labeled a regular classical parameter point at λ=0,a=0.

Recommendation: implement the reduced n-count now only behind the uniform normal-jet extension. If your existing Gram witnesses already apply jointly to the compact mass-deformed domain and smooth ambient insertions, the remaining work is chiefly a finite derivative-budget calculation and a zero-extension lemma—not another i0 criterion. If they certify only unmeasured integral convergence, strengthen that part of the same theorem before using −3 for order planning.
