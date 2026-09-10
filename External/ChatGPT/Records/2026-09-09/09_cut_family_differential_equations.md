# Cut-family differential equations and physical sheets

Verified outgoing model: gpt-6-pro; request 4737f78f-1fb8-4c44-9f34-03d3543bbb17; HTTP 200.

## Question

Please review the next mathematical step for our general first-principles integrated SIDIS NNLO framework (code: https://github.com/CongyueZhang2002/factorization-and-loops, local changes newer than remote). Your reviews 07/08 guided joint angular averages and physical gluon state sums.

We now have: (i) correlated full-Gram evanescent angular averages retaining causal propagators, 18 tests; (ii) explicit physical unobserved gluon sums, allowing at most one covariant sum without ghost completion; (iii) typed particle vs linear measurement cuts with C_n(G)=(-1)^(n-1) delta^(n-1)(G)/(n-1)!, separate particle theta conditions; (iv) Kira native linear denominator support (fixed FeynHelpers malformed shifted-bilinear YAML and lost dimensionless measurement parameter); (v) a full one-loop three-cut measured two-body reduction. Kira's raised measurement cut gives exactly d_z log[Phi_2(s) z^-eps(1-z)^-eps/Beta(1-eps,1-eps)], including prefactor derivatives and negative constraint-rescaling signs. No ordinary i0 removal inferred.

For generic external kinematic derivatives, I propose: external basis p_a with nondegenerate Gram G(t); choose velocity matrix B=(1/2) G'(t) G(t)^(-1), so dp_a/dt=sum_b B_ab p_b and G'=B G+G B^T. Differentiate all ordinary, particle-cut and measurement-cut inverse denominators at fixed loop momentum components, retaining explicit parameter derivatives, then express scalar-product numerators in the complete inverse-denominator basis. Apply -nu_i dD_i C_(nu_i+1) in cut slots; terms pinching a required cut vanish. Include d(log MeasurePrefactor)/dt, preserve all ordinary i0 signs. No loop integration measure Jacobian because loop components held fixed.

SIDIS: p^2=0,q^2=-Q2,p.q=Q2/(2x), G nonsingular inside x>0. For x variation fixed Q2, simpler dp/dx=-p/x,dq/dx=0 is another valid choice, differing from the symmetric Gram choice by a Lorentz variation. RR particle cuts k1^2,k2^2,(p+q-k1-k2)^2 and measurement Gm=2p.k1-z Q2/x, overall J=Q2/x. For z variation fixed kinematics only the measurement derivative is needed; for x the recoiling particle cut also changes. The current implementation deliberately rejects x until this extension is justified.

Please challenge this derivative construction for CUT integrals:
1. Do positive-energy theta derivatives vanish/disappear in a controlled way when their timelike reference follows external kinematics, for arbitrary finite positive cut powers? What scope can we claim without recycling an unproved normal-derivative argument? Are massless cut tips an actual extra term? Please separate a distributional identity from analytic continuation of convergent phase-space integrals.
2. Which cheap independent checks would most efficiently establish the general code? Measured 2-body exact Beta formula in x,z and measured Phi_3 boundary; compatibility of mixed partial derivatives after IBP; negative cut rescalings are candidates.
3. For RR three-body all four mandatory cuts, does the nondegenerate-Gram construction and linear measurement cut yield the needed two-variable DE with no extra geometric data beyond time orientation and correct physical branch? For RV, must virtual and phase loops be differentiated or analytically continued differently?
4. Our current CutFamilies API retains ordinary prescriptions and refuses to call legacy AMFlow real-emission with a linear cut. What is the clean general evaluation route for these linear-cut masters? Is existing AMFlow support usable via a documented backend, or should independent numerical validation instead use directly measured phase space/sector decomposition? Do not advise silently replacing a linear cut by a quadratic one.
5. Any more efficient first-principles SIDIS NNLO production strategy that avoids overengineering these pieces, while yielding explicit analytic coefficients and retaining general framework reuse? Reference results must remain verification-only.

Please answer concrete mathematical scope, pitfalls, and a recommended next implementation order; no reference coefficient as production input.

## Pro response

Your derivative construction is correct for a consistently regularized family of forward-energy cut integrals. The qualification is not “every derivative of a theta function is identically zero.” Rather, the definition of the positive-energy cut—including its extension at the massless tip—must be fixed before differentiation. With the usual meromorphic dimensional/analytic continuation, your denominator-differentiation rule is justified without adding a separate, ad hoc soft-tip term.

I would implement the sparse SIDIS x-derivative next, retain all ordinary prescriptions, and use directly measured phase-space integrals as the first independent numerical validation route. A new linear-cut AMFlow adapter should be optional and separately validated, not a prerequisite for producing the analytic RR solution.

1. External differentiation: the proposed construction is correct

Treat the external vectors as a column indexed by a:

dt
dp
a
μ
	​

	​

=B
ab
	​

p
b
μ
	​

.

For symmetric, nonsingular G,

B=
2
1
	​

G
′
G
−1

satisfies

BG+GB
T
=G
′
.

Therefore it realizes exactly the requested variations of all external scalar products.

At fixed loop components,

D
t
	​

(ℓ
i
	​

⋅p
a
	​

)=B
ab
	​

ℓ
i
	​

⋅p
b
	​

,D
t
	​

(ℓ
i
	​

⋅ℓ
j
	​

)=0.
	​


Fixed loop components do not mean fixed loop–external scalar products. This distinction should be explicit in the implementation.

For a normalized family

I
ν
	​

=N(t,ϵ)∫
ℓ
∏
	​

d
D
ℓ
i
∏
	​

F
ν
i
	​

	​

(D
i
	​

),

the derivative is

D
t
	​

I
ν
	​

=
N
N
′
	​

I
ν
	​

−
i
∑
	​

ν
i
	​

N∫
ℓ
∏
	​

d
D
ℓ(D
t
	​

D
i
	​

)F
ν
i
	​

+1
	​

(D
i
	​

)
j

=i
∏
	​

F
ν
j
	​

	​

(D
j
	​

),
	​


with the positive-energy qualification discussed below. For ordinary propagators, F
ν
	​

=(D+i0σ)
−ν
; for measurement cuts, F
ν
	​

=C
ν
	​

.

This must also differentiate numerator insertions, represented either explicitly or by negative ordinary indices. Only pinching a mandatory cut gives zero; pinching an ordinary propagator gives a lower sector.

There is no loop-measure Jacobian in this representation. A Jacobian would arise if you additionally changed integration variables by a parameter-dependent routing or changed to scalar-product/Baikov coordinates. Do not import that Jacobian into a fixed-component derivative.

Two practical safeguards are important:

Differentiate each dependence once. If p
a
	​

⋅p
b
	​

 has already been replaced by G
ab
	​

(t), differentiate that replacement explicitly; do not also apply the vector-velocity rule to the same eliminated product. Conversely, remaining ℓ⋅p
a
	​

 objects still require the velocity rule.

Differentiate before value-only cut restriction. Relations such as D
i
	​

=0 cannot be imposed inside a numerator that is about to multiply a raised cut. The identities

D
i
	​

C
ν+1
	​

(D
i
	​

)=C
ν
	​

(D
i
	​

)

must perform that simplification.

Different velocity choices

If B and 
B
 realize the same G
′
, their difference K obeys

KG+GK
T
=0.

It is an infinitesimal Lorentz transformation on the nondegenerate external span, extendable to the ambient physical space. For a scalar integral with the same time orientation, the two derivative constructions consequently agree after integration.

They need not give identical unreduced integrands. Their difference can be represented by Lorentz identities and loop total derivatives.

For several external variables, the symmetric Gram prescription need not define a globally commuting choice of external-vector frame. Its commutator can be a Lorentz rotation. Therefore, test mixed-partial compatibility on the integrated/reduced scalar system, not by demanding that every external vector constructed with the symmetric prescription have commuting raw derivatives.

For your x,z problem, G is independent of z, so this complication is largely absent.

2. Positive-energy factors: a precise justification and its limits

Write a particle cut as

T
ν
+
	​

(k;τ)=θ(τ⋅k)C
ν
	​

(k
2
−m
2
),τ future timelike.

A formal differentiation would produce

D
t
	​

T
ν
+
	​

=
	​

−νθ(τ⋅k)D
t
	​

(k
2
−m
2
)C
ν+1
	​

(k
2
−m
2
)
+δ(τ⋅k)D
t
	​

(τ⋅k)C
ν
	​

(k
2
−m
2
).
	​

(1)

The second line cannot simply be declared zero without specifying how these distributions are defined.

2.1 Massive cuts and the nonzero massless shell

For m
2
>0, the shell and τ⋅k=0 are disjoint. The second line of (1) is genuinely zero for every finite cut power.

For m=0, they meet only at

k=0.

Away from that point, θ(τ⋅k) is locally constant on a neighborhood of either mass-shell component. Consequently, its derivative contributes nothing there, also for raised cuts.

A moving reference τ(t) is not intrinsically problematic. For any two future timelike references,

sign(τ⋅k)=sign(
τ
⋅k)

on the nonzero causal cone. One can therefore keep a fixed future timelike reference throughout a real physical chamber instead of differentiating a normalization such as P/
P
2
	​

.

That removes unnecessary reference derivatives, but does not by itself resolve the massless tip when the cut momentum k(t) changes.

2.2 A controlled massless definition without an unproved mass-limit interchange

A useful mathematical construction starts with the forward-cone family

U
λ
+
	​

(k)=
Γ(λ+1)
θ(τ⋅k)θ(k
2
)(k
2
)
λ
	​


where Reλ is initially sufficiently large.

In this initial domain:

The function is independent of the choice of future timelike τ.

The cone-boundary terms vanish under differentiation.

Direct differentiation gives

∂
k
μ
	​

U
λ
+
	​

(k)=2k
μ
	​

U
λ−1
+
	​

(k).
	​


Continue this identity as a distribution-valued meromorphic identity. This is the standard type of analytic continuation used for forward-cone Riesz distributions; additional gamma factors can make the corresponding Riesz-normalized family entire. 
arXiv

At generic D, define the massless cut family by

T
ν
+
	​

=
(ν−1)!
(−1)
ν−1
	​

U
−ν
+
	​

.

Where the elementary product is well defined, this equals

θ(τ⋅k)
(ν−1)!
(−1)
ν−1
	​

δ
(ν−1)
(k
2
).

Elsewhere it specifies its continuation, including the tip.

The continued derivative identity becomes

∂
k
μ
	​

T
ν
+
	​

(k)=−2νk
μ
	​

T
ν+1
+
	​

(k),
	​


and therefore

D
t
	​

T
ν
+
	​

(k(t))=−νD
t
	​

(k
2
)T
ν+1
+
	​

(k(t)).
	​

(2)

Equation (2) is the justification for your production rule. It does not require first asserting that the separately written product
δ(τ⋅k)δ
(ν−1)
(k
2
) exists and equals zero.

The code does not need to introduce λ numerically. This is a definition and proof of the cut algebra it implements.

2.3 What must still hold for a complete integral

A single-cut identity is not permission to multiply arbitrary singular distributions independently.

For the full RR integral, establish the identities for a jointly regulated integrand and then continue the resulting family. Ordinary denominator powers may need analytic regulators in addition to D. For a finite derivative closure, the required regularization conditions must cover its largest cut powers and all soft/collinear boundary strata.

In RR, the causal-cone support together with fixed timelike total momentum gives a particularly useful compact regulated domain. In RV, ultraviolet and infrared regions may prevent dimension alone from supplying a common convergence region, so the usual analytically regulated Feynman-integral definition is needed.

The important distinction is:

Continue the complete regulated identity; do not multiply separately chosen finite parts of singular cut distributions and assume the same identity survives.

Nor should you claim a single fixed convergence strip valid for unbounded cut powers. The needed statement is for every specified finite set of powers and derivatives.

2.4 Are soft tips an extra term?

Not an additional universal term to append to the proposed DE. In the meromorphic cut convention above, their contributions are already fixed by the continued distributions and equation (2).

But a proof based only on the smooth, nonzero mass shell is incomplete. At a special integer dimension, a separately defined extension at the tip can contain contact terms; taking premature finite parts or dropping regulator-suppressed factors can change the result.

For your measured RR problem,

p⋅k
1
	​

=
2x
zQ
2
	​

>0

excludes k
1
	​

=0, but does not exclude k
2
	​

=0 or k
3
	​

=0. Thus the measured two-body tests, where both particles are nonsoft at interior x,z, do not alone settle this issue for RR.

External endpoint terms must also be distinguished from particle-tip bookkeeping. For example,

∂
s
	​

s
+
−ϵ
	​

=−ϵs
+
−1−ϵ
	​

.

Its ϵ→0 distributional limit is

∂
s
	​

θ(s)=δ(s),

not zero. The endpoint delta is already encoded in the analytically continued right-hand side and is lost if one sets ϵ=0 too early. These are distributional derivatives, not derivatives of ordinary interior functions. 
DLMF

Finally, this reasoning is specific to the energy-orientation theta factors. Additional acceptance cuts such as θ(f(k,t)) can have genuine nonsoft boundary contributions and must be differentiated explicitly. Phase-space IBP with such Heaviside measurements requires additional boundary terms in general. 
arXiv

3. The sparse SIDIS x-derivative has an important exact simplification

Use your proposed choice

D
x
	​

p=−
x
p
	​

,D
x
	​

q=0,

at fixed Q
2
 and fixed loop components. It gives the required variations of p
2
,q
2
,p⋅q.

Set

J=
x
Q
2
	​

,G
m
	​

=2p⋅k
1
	​

−zJ.

Then

D
x
	​

J=−
x
J
	​

,D
x
	​

G
m
	​

=−
x
G
m
	​

	​

.
	​


Consequently,

D
x
	​

[JC
ν
	​

(G
m
	​

)]
	​

=−
x
J
	​

C
ν
	​

+
x
νJ
	​

G
m
	​

C
ν+1
	​

=
x
ν−1
	​

JC
ν
	​

(G
m
	​

).
	​

	​

(3)

For the original unit measurement,

D
x
	​

[JC
1
	​

(G
m
	​

)]=0.
	​


Thus the measurement and its Jacobian cancel exactly in the x-derivative. This is an algebraic simplification before IBP, not a use of G
m
	​

=0.

For a raised measurement cut, the residual

x
ν−1
	​


must remain.

At fixed external kinematics,

∂
z
	​

[JC
ν
	​

(G
m
	​

)]=νJ
2
C
ν+1
	​

(G
m
	​

).
	​

(4)

Equations (3)–(4) give a particularly inexpensive mixed-derivative regression. They should commute exactly for every tested positive ν.

An optional basis normalization is

C
ν
	​

=J
ν
C
ν
	​

(G
m
	​

).

Since J>0 in the physical chamber,

C
ν
	​

=C
ν
	​

(G
m
	​

/J),

and

D
x
	​

C
ν
	​

=0,∂
z
	​

C
ν
	​

=ν
C
ν+1
	​

.

This may simplify the measurement-cut part of a DE, but it is not necessary to change your current family normalization.

For the eliminated recoil momentum

k
3
	​

=p+q−k
1
	​

−k
2
	​

,
D
x
	​

k
3
	​

=−
x
p
	​

,
D
x
	​

(k
3
2
	​

)=−
x
2p⋅k
3
	​

	​

.
	​


Its particle-cut derivative therefore contributes

D
x
	​

T
ν
3
	​

+
	​

(k
3
	​

)=
x
2ν
3
	​

p⋅k
3
	​

	​

T
ν
3
	​

+1
+
	​

(k
3
	​

),
	​


under the cut convention established above.

The first two quadratic cuts do not change under this velocity. Ordinary propagators and scalar numerator insertions still do.

This sparse velocity is preferable to the symmetric Gram velocity for production here: it avoids unnecessary motion of q, makes the unit measurement invariant, and generates fewer intermediate numerator terms. Keep the symmetric construction as the general fallback and an independent check.

4. What the resulting two-variable DE does—and does not—require

After reducing the differentiated integrals to a common master basis,

∂
x
	​

I=A
x
	​

(x,z,ϵ)I,∂
z
	​

I=A
z
	​

(x,z,ϵ)I.

The nondegenerate external Gram matrix and the linear measurement denominator are sufficient for the algebraic generation of these derivatives. Linear measured SIDIS cuts have been used precisely this way to construct x,z differential systems. 
arXiv

No extra physical vector is required. However, distinguish three statements:

External nondegeneracy: G is invertible. This licenses the external derivative lift.

Regularity of the measured cut geometry: the mandatory constraints have the appropriate rank on the generic smooth phase-space stratum. This is not implied by the external Gram determinant. Degeneracies at soft/collinear boundaries are handled by the regulated integral, not by pretending that every cut surface is everywhere regular.

Choice of solution: the DE matrices do not determine the physical integration cycle or its boundary constants. Your particle orientations, measurement support, ordinary prescriptions, and actual boundary integration select the physical solution.

The null gradient of the measurement,

∂
k
1
	​

	​

G
m
	​

=2p,

is nonzero and does not prevent it from defining a regular hypersurface. Do not try to construct a normal vector by dividing by p
2
.

After the starting physical integral is defined, complex continuation is continuation of that integral along a specified path. It is not evaluation of a theta function at complex arguments.

RV uses the same external derivative algebra

For a combined RV family, hold both virtual-loop and phase-space-loop components fixed. Differentiate all denominators and numerator invariants with the same D
t
	​

.

The distinction is in their distributions:

Virtual propagators retain their +i0 or −i0.

Particle cuts retain the forward-energy convention.

Measurement cuts have no energy theta.

No additional phase-space or virtual-loop Jacobian appears merely because one integration is “real” and another “virtual.”

Do not add the integrated D-dimensional real-emission momentum to the physical external Gram basis. After your joint evanescent reduction, it remains an integration variable of the full-D scalar family.

Differentiation commutes with taking the prescribed analytic boundary value on a nonsingular chamber. Crossing a threshold or pinch requires continuation of the solution; it is not a reason to change the derivative rule or erase prescriptions.

5. The most efficient independent checks

The following checks exercise different failure modes rather than repeatedly testing the same identity.

A. Exact measured two- and three-body derivatives

With

s=Q
2
x
1−x
	​

,

the measured two-body volume has the dependence

V
2
	​

=A(ϵ)s
−ϵ
z
−ϵ
(1−z)
−ϵ
.

Therefore,

V
2
	​

∂
x
	​

V
2
	​

	​

=
x(1−x)
ϵ
	​

,
V
2
	​

∂
z
	​

V
2
	​

	​

=−
z
ϵ
	​

+
1−z
ϵ
	​

.
	​


Your independently integrated measured three-body volume has the dependence

V
3
	​

=B(ϵ)s
1−2ϵ
z
−ϵ
(1−z)
1−2ϵ
.

It must give

V
3
	​

∂
x
	​

V
3
	​

	​

=−
x(1−x)
1−2ϵ
	​

,
V
3
	​

∂
z
	​

V
3
	​

	​

=−
z
ϵ
	​

−
1−z
1−2ϵ
	​

.
	​


The three-body test is particularly valuable: it includes all four mandatory cuts and nontrivial recoil-cut differentiation. Use the full exact measured volume, not only one endpoint limit.

B. Two external lifts, one reduced derivative

Construct ∂
x
	​

 using both

B
sym
	​

=
2
1
	​

G
x
	​

G
−1

and

D
x
	​

p=−p/x,D
x
	​

q=0.

Their difference must reduce to zero for each selected scalar integral at generic ϵ.

This catches errors in fixed-component differentiation, numerator reconstruction, and external scalar-product substitutions.

C. Mixed partials and scaling

For a column master vector, verify

∂
x
	​

A
z
	​

−∂
z
	​

A
x
	​

+A
z
	​

A
x
	​

−A
x
	​

A
z
	​

=0.
	​


Include derivatives of basis normalizations in this test.

Flatness is necessary, not sufficient. A wrong common normalization f(x,z) shifts both matrices by derivatives of logf and can remain flat. That is why the independent volume checks matter.

Also test the homogeneous Q
2
-scaling inferred from the integration measure, denominator powers, and measurement prefactor. It is an inexpensive way to detect a lost J or an extra loop-measure factor.

D. Cut powers, normalizations, and time orientation

For a real nonzero external rescaling c(t),

C
ν
	​

(cG)=sgn(c)c
−ν
C
ν
	​

(G).
	​


Within a chart where c does not cross zero, differentiate this identity, including c
′
/c. The particle’s energy orientation is attached to its momentum, not inferred from the sign chosen for its inverse denominator.

For positive cut masses, compare generated raised-cut derivatives with direct mass derivatives of an exactly integrated massive phase-space test:

T
ν
+
	​

(k;m
2
)=
(ν−1)!
1
	​

∂
m
2
ν−1
	​

T
1
+
	​

(k;m
2
).

Then separately test the controlled massless continuation. This checks the code’s normal derivatives without using the positive-mass result as an unproved justification for interchanging all limits.

Changing a future timelike reference should leave these tests unchanged. Numerical or finite-field samples are useful diagnostics; the low-sector beta-function identities and symbolic cut-rescaling identities can be verified exactly.

6. Evaluation of linear-cut masters
6.1 Recommended production and validation split

For analytic production, use

generated derivative targets→IBP→(A
x
	​

,A
z
	​

)→physically integrated boundary data→analytic transport.
	​


For the first independent numerical checks, use directly measured phase-space parameterizations, not a replacement of the measurement denominator.

For RR, your nested factorization already provides

dΦ
3
	​

=
2π
dM
2
	​

dΦ
2
	​

(P;k
1
	​

,K)dΦ
2
	​

(K;k
2
	​

,k
3
	​

).

The measurement gives

z=(1−u)y,u=M
2
/s,0<u<1−z.

Solving the delta analytically and setting

u=(1−z)t,0<t<1,

produces a directly measured parameter integral with all energy conditions built into the decay construction. Map the remaining angles to fixed intervals and retain their exact D-dependent weights.

Extract endpoint singularities before numerical integration. A general parametric sector-decomposition backend is appropriate here: pySecDec’s documented make_package interface accepts integration variables, regulators, polynomial factors, prefactors, and remainder functions without requiring a Feynman graph. 
pySecDec

It must receive the derived ordinary parameter integral—not raw delta distributions that it is expected to interpret.

For unavoidable raised particle cuts, obtain the corresponding normal derivatives of a correctly defined parameter representation before taking a singular massless limit. Alternatively, reduce them to an evaluable set of unit-particle-cut integrals, while recognizing that this latter comparison does not independently verify the reduction used.

Keep ordinary prescriptions wherever a direct parameter denominator can vanish. Sector decomposition of endpoint poles is not itself an i0-removal proof.

6.2 What AMFlow currently establishes

There is documented AMFlow support for linear propagators and for phase-space integrations. The current repository lists separate linear_propagator, automatic_phasespace, and feynman_prescription examples. Thus it would be inaccurate to call the method categorically incapable of linear or cut integrals. 
GitLab

However, I could not verify a documented backend contract establishing your exact combination:

positive-energy quadratic cuts+a non-energy linear measurement cut+raised measurement powers+independent causal information.

That distinction matters. The published linear-propagator method introduces an auxiliary quadratic term and solves a differential equation to remove it with the prescribed limit. It is not a pointwise identification of a linear cut with a quadratic mass shell. 
arXiv

A legitimate adapter would have to preserve the measurement discontinuity, avoid adding an energy restriction to it, and validate the limit and normalization. Your measured two-body family—including raised and negatively rescaled measurement cuts—is an appropriate first acceptance test. Merely reaching a numeric answer through an AMFlow entry point is not sufficient.

Your current refusal to send a linear-cut family to the legacy real-emission adapter is therefore appropriate. It need not become a permanent prohibition on a separately validated adapter.

There is also a current-version caveat: AMFlow 2.0 was documented in July 2026. Its alternative "FT" recursion mode has a stated contour limitation: only Euclidean evaluations are guaranteed by that implementation. It should not be selected as an automatically safe shortcut for physical RR/RV integrals. 
arXiv

The AMFlow differential-equation solver can separately be used as an alternative numerical transporter for your DE and boundary values. That checks numerical propagation, not the independence of the underlying boundary calculation or DE derivation.

7. Recommended next implementation order
Order	Implementation	Acceptance condition
1	Fixed-loop-component external derivative, with the sparse SIDIS x-velocity and generic Gram fallback	Exact measurement identities (3)–(4), measured V
2
	​

,V
3
	​

 derivatives, and lift independence
2	Shared RR derivative closure and x,z matrices	All differentiated targets reduce in the common basis; exact normalization/scaling checks and mixed-partial compatibility
3	Direct measured parameter integrals for selected seeds and numerical checks	Independently reproduced low sectors and representative nontrivial masters, with singularities subtracted before numerical integration
4	Minimal physical boundary construction and analytic transport	Boundary constants obtained from actual region/phase-space integrals; complete coefficient dependency closure
5	RV derivative/evaluation adapter and optional linear-cut AMFlow adapter	The same cut semantics and branch tests; no reclassification of integrated momenta as physical externals

The efficiency gain should come from sharing the reduction and solving only the needed scalar system, not from building a more elaborate general-purpose geometry layer now. Generate the union of amplitude and first-derivative targets across channels, reuse the joint angular reduction, and avoid a separate Kira campaign for every projection.

Use both x,z equations for closure and consistency, but a fixed piecewise path can suffice for actual transport. An epsilon form is optional; it should not block your existing finite-order solution machinery. Integrate only the independent boundary data required by the system, and combine master coefficients before expanding them into large explicit special-function expressions. The published SIDIS study independently demonstrates that both DE transport and direct radial-angular integration are viable, without requiring either route to serve as imported production data. 
arXiv

The final correctness boundary is:

one defined meromorphic forward-cut family
+ fixed-component differentiation
+ preserved measurement normals and prescriptions
⟹the proposed raised-denominator DE rules.
	​

	​


That is enough to justify implementing the interior x-derivative. It does not permit dropping endpoint distributions, taking massless limits term by term without control, or assuming that a numerical backend preserves a linear measurement cut merely because it supports ordinary phase-space integrals.