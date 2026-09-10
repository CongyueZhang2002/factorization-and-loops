# GPT-6 Pro review 20

Verified model: gpt-6-pro. Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.

## Prompt

Critical review for the general NNLO framework, continuing review19. Repository https://github.com/CongyueZhang2002/factorization-and-loops local work newer. The weighted endpoint fix is implemented and both numerator counterexamples pass. We located the formerly missing hard-sector constant: its formal solution contributes ONLY a lower integer power to physical row17, below the proved onset. That zero equation fixes it; full rank6 and all50 unused/used physical coefficient equations agree at two negative-epsilon/scale points. The general driver now handles additional q-g/g-q/charge-conjugate UU/LL RR sources: 311 master positions ->68 exact integral classes ->55 spanning directions; all have unit cuts. Their ordered boundary matching has full rank7, and takes37s. We have explicit finite singular-boundary connections in sigma and rho with exact Gamma boundary data and automated epsilon orders.

New nontrivial decision: automatic GPL conversion of the rho connection sees square roots from its unregulated homogeneous basis:
P1(rho,z)=(1+z)^2-4 z rho,
P2(rho,z)=rho^2+4(1-z)(1-rho).
The source DE itself is rational. The converter handles rational letters; single linear/quadratic roots could be handled by a shared rationalizing chart for the entire ancestor-integral dependency chain. We will not assume two unrelated roots together are GPL. First we are applying actual boundary-value coefficients and pruning the resulting finite graph to see whether these root terms survive.

But there may be a more fundamental upstream inefficiency. In the q-q two-gluon RR card we use one physical D-dimensional gluon sum with TIMELIKE reference P=p+q, and one covariant sum -g_D for the other unobserved gluon. This creates an ordinary gauge denominator P.k2, and extra masters. The other q-g and g-q RR components have only one unobserved gluon with a covariant sum. The density matrices on incoming/observed partons are physical and normalized.

Please scrutinize these points:
1. For a COMPLETE tree current amplitude gamma* q -> q g g with on-shell external partons, does the one-physical-plus-one-covariant prescription equal the fully physical result and become independent of the physical gluon's reference vector WITHOUT extra ghosts? My argument: once gluon1 is physically projected, the amplitude obeys the Ward identity in gluon2, so its covariant sum is legitimate. Hence reference-P dependence should cancel in the summed on-shell scalar integrand. Check the uncontracted Ward identities carefully; do not assume separately transverse covariant tensors.
2. Would selecting the incoming null momentum p as the physical reference be a legitimate and useful alternative? Then p.k2 coincides on the unit cut with -(p-k2)^2/2, already among ordinary graph denominators, instead of introducing P.k2. Its collinear zero is on a boundary; the existing common high-D cut-convergence certificate must still justify that denominator before any i0 removal. We would compare the COMPLETE scalar integrands from reference P and reference p exactly modulo the unit-cut identities.
3. If the on-shell summed rational integrand should have NO reference denominator, prioritize whole-sum cancellation before family decomposition? It might explain excess auxiliary masters compared to the literature's 21 physical RR masters, but we will not force that number or import the literature basis.
4. If the square-root sectors survive in genuinely requested masters, is the appropriate generic GPL step to rationalize each single-conic dependency component, including pullbacks of its ancestor GPLs, rather than making unrelated per-integral changes? Any quick diagnostic for whether P1 and P2 can enter the same genuine integration chain or merely arise in separate homogeneous blocks?

User priority is general reusable first-principles workflow; no fitted coefficients, no selected-family corrections. We are reading literature only for mathematical methods and independent validation, not importing SIDIS master values or coefficients. Please be particularly critical of point1: if it is wrong, it is a production correctness issue, not just an optimization.


## Response

Point 1 is correct: one physical gluon sum and one covariant sum give the fully physical result, without external ghost completion, for the complete on-shell tree current amplitude. The remaining physical-reference dependence must cancel pointwise. The open two-gluon tensor is not separately transverse; using that stronger, false identity would be an error.

There is also a concrete obstruction relevant to point 4: at fixed generic z, the two roots you list together generate a genus-one curve. Each root is individually rationalizable, but a genuinely mixed integration chain cannot be handled by assuming a simultaneous rationalizing substitution in ρ.

The priority should therefore be exact state-sum cancellation and observable-level pruning, before extending the GPL converter to the auxiliary sectors.

1. Why the hybrid state sum is correct

Let k
2
	​

,k
3
	​

 be the two unobserved gluons, and write the complete current amplitude as

M
αβ
μ
	​

(k
2
	​

,k
3
	​

),

with current index μ and gluon indices α,β. Suppress color and quark-spin labels.

The electromagnetic current is a color-singlet gauge-invariant insertion. Its being off shell does not invalidate the QCD Ward identities for the on-shell external partons. With all other colored external states physical, the relevant on-shell identities have the form

k
2
α
	​

M
αβ
μ
	​

=k
3β
	​

U
μ
,k
3
β
	​

M
αβ
μ
	​

=k
2α
	​

V
μ
.
	​

(1)

The right-hand sides generally do not vanish. They are the longitudinal structures associated with the ghost-line Slavnov–Taylor identities. The established restriction is precisely that one external polarization sum may be replaced by −g
D
	​

 while the others remain physical; replacing multiple sums generally requires ghost completion. 
arXiv

1.1 Replacing the second sum is legitimate

For any physical polarization of gluon 2,

ϵ
2
α
	​

k
2α
	​

=0,

equation (1) gives

k
3
β
	​

ϵ
2
α
	​

M
αβ
μ
	​

=0.

Thus the amplitude with gluon 2 physically projected is transverse in gluon 3. Every gauge term in the difference between its physical sum and −g
D
	​

 vanishes.

Consequently,

Σ
d
2
	​

d
3
	​

	​

=Σ
d
2
	​

C
3
	​

	​

=Σ
C
2
	​

d
3
	​

	​

,C
i
	​

=−g
D
	​

,
	​

(2)

where Σ includes the complete amplitude–conjugate product and the prescribed current and other external-state contractions.

These are pointwise identities on the on-shell phase space, before angular averaging or IBP. They hold for the current tensor, so they also hold after either UU projection or the Hermitian g
1
	​

 projection. Positivity of the projected scalar is not needed.

They do not imply

Σ
d
2
	​

C
3
	​

	​

=Σ
C
2
	​

C
3
	​

	​

.
1.2 Reference independence can be shown without assuming separate transversality

For an admissible reference n, define

d
αα
′
(k,n)=−g
D
αα
′
	​

+k
α
b
α
′
+b
α
k
α
′
,
b
α
=
k⋅n
n
α
	​

−
2(k⋅n)
2
n
2
k
α
	​

,k⋅b=1.

This is the full physical polarization sum, including the last term for timelike n. 
FeynCalc

Let B(X,Y) denote the remaining Hermitian current, spin, and color bilinear, with X on the conjugate side. Expanding the physical sum on gluon 2 and applying (1) gives

Σ
d
2
	​

(n)C
3
	​

	​

=Σ
C
2
	​

C
3
	​

	​

−B(U,V)−B(V,U).
	​

(3)

The reference enters this calculation only through k
2
	​

⋅b=1; it has disappeared from the result.

Equation (3) is a useful reference-free representation derived from the same generated amplitude. It does not require introducing external ghost amplitudes into production. However, the correction is the displayed cross bilinear; do not replace it by a negative square unless U=V has separately been established in the chosen convention.

Equivalently, under n→n
′
,

Δd
αα
′
=k
2
α
	​

Δb
α
′
+Δb
α
k
2
α
′
	​

,k
2
	​

⋅Δb=0.

The two terms reduce through (1) to factors proportional to k
2
	​

⋅Δb, and therefore vanish.

Thus the old timelike-reference calculation is not intrinsically wrong. Its uncanceled reference denominator is an upstream simplification issue—or an implementation diagnostic if it survives the complete exact sum.

1.3 Conditions that must be audited in the actual implementation

The proof assumes the complete gauge-related graph sum, exact color algebra, correct fermion-line ordering, and full-D on-shell conditions. In particular:

Do not impose transverse-polarization identities on the gluon that will be summed with −g
D
	​

 before performing that sum. FeynCalc explicitly warns against this combination. 
FeynCalc

Count the actual covariant sums, not their card labels. An incoming or tagged gluon projector previously simplified to −g
D
	​

 would change the state-sum problem.

Keep integrated k
i
	​

 genuinely D-dimensional. The Ward identities use \slashedk
D
2
	​

=k
D
2
	​

, not a four-dimensional null replacement.

Establish the identity at generic D, before epsilon truncation. A finite helicity-PDF transformation cannot repair a state-sum error.

The clean exact test is

Σ
d
2
	​

(P)C
3
	​

	​

−Σ
d
2
	​

(p)C
3
	​

	​

=0
	​

(4)

after complete scalar assembly, or the smaller amplitude identities (1). Checking only

k
2
α
	​

M
αβ
	​

=0

would reject a correct QCD amplitude.

2. The null reference p is legitimate and useful

For the physical sum on gluon 2, choosing the incoming null momentum gives

d
D
αα
′
	​

(k
2
	​

,p)=−g
D
αα
′
	​

+
p⋅k
2
	​

k
2
α
	​

p
α
′
+p
α
k
2
α
′
	​

	​

.
	​

(5)

Using another external momentum as the reference is standard provided its dot product with the gluon is nonzero. No photon or FF spin average is introduced by this choice. 
FeynCalc

In the open physical region,

2p⋅k
2
	​

=J(1−z)y>0.

The zero occurs on unresolved boundaries, not at an ordinary interior point.

On the unit particle cut,

(p−k
2
	​

)
2
=−2p⋅k
2
	​

,

so

p⋅k
2
	​

1
	​

=−
(p−k
2
	​

)
2
2
	​

.
	​

(6)

This is likely a better intermediate representation than introducing P⋅k
2
	​

: it uses a polynomial already present among the ordinary graph denominators.

There are three scope restrictions.

Unit-cut equality is not an off-shell family identity

Away from the cut,

2p⋅k
2
	​

=k
2
2
	​

−(p−k
2
	​

)
2
.

Thus equation (6) is valid for the original unit-cut density but not as a replacement in arbitrary dotted-particle masters.

Apply it in the raw unit-cut integrand before generating the corresponding family and its IBPs. Do not change the definition of existing dotted descendants or their mass-normal derivatives using (6).

A gauge denominator has no automatically assigned causal prescription

The factor 1/(p⋅k
2
	​

) in a polarization projector is algebraic. Identifying its on-shell polynomial with an ordinary graph denominator does not, by itself, authorize assigning +i0, merging oppositely prescribed slots, or dropping an existing prescription.

If the factor cancels from the complete density before integration, this issue disappears from the new production integrand. If it remains as an intermediate integral denominator, use the established common convergence certificate for the required powers and continuation. Its positive interior sign is not the proof.

Do not evaluate this projector directly on its collinear boundary

The reference choice is valid on the open chamber. Its apparent boundary singularity is handled through the complete scalar density and the regulated integral. There is no uniform lower bound on p⋅k
2
	​

 as z→1 or y→0.

Changing P to p also leaves the BMHV and operator definitions unchanged. Both references are physical and lie in span{p,q}, so they introduce no extra transverse direction and preserve the hypotheses of the joint angular average.

3. Cancel the reference factors before creating integral families

Yes: this should now take priority over converting the broad master system to GPLs.

For this tree amplitude, equation (3) provides a reference-free rational representation built from the generated amplitude and its Ward contractions. Therefore a denominator introduced solely through the arbitrary polarization reference is removable from the complete physical density.

That does not mean every individual interference, denominator-family contribution, or master coefficient is reference-free. Your current calculation may simply have retained a large auxiliary space in which the cancellation becomes visible only after assembly.

A practical exact cancellation stage

Use a common set of scalar products for the complete current contribution, retaining generic D. Apply the declared color identities and momentum conservation, then work in the rational function field localized away from the ordinary singular divisors, modulo the unit-cut ideal

k
1
2
	​

=k
2
2
	​

=k
3
2
	​

=0.

The measurement relation can also be used when needed, but the state-sum identity should normally be established without it.

Keep reference-generated denominator factors explicitly marked. For

g=P⋅k
2
	​

,

collect the complete expression by its powers of g. After bringing the relevant terms to a common rational denominator, verify exact divisibility of the numerator by the required power of g, using the same on-shell relations.

This need not be one enormous unrestricted Together call. A common-denominator calculation restricted to the marked gauge factors, or the Ward-reduced construction (3), can expose the cancellation much earlier.

Finite-field evaluations can assist reconstruction and falsification, but an exact identity or a certified reconstruction is what authorizes removal. Use generic color parameters subject to the card’s actual SU(N) relations; the earlier fraction diagnostic already demonstrated why treating C
F
	​

,C
A
	​

 as unrelated can hide physical cancellations.

Preserve the completed work

Do not discard the 55-direction system and its boundary data. Instead:

Reassemble the reference-free raw coefficient using the existing reductions wherever possible.

Identify the resulting target subspace and its actual dependency closure.

Recompute only reductions or basis adaptations that are genuinely needed.

An arbitrary common master basis may express a graph-only integral through combinations involving masters originally discovered in gauge sectors. Therefore, do not set a column to zero merely because its representative has a gauge denominator. A basis adapted to the graph-only sectors can make the cancellation manifest.

Nor should the published master count become a stopping criterion. Different denominator inventories, numerator targets, and levels of exact relation closure can give different spanning sets. The pertinent question is whether unnecessary polarization-reference factors were admitted into the target family before the complete sum was simplified.

The auxiliary masters can be mathematically correct and still be unnecessary for the physical coefficient. Their nontrivial square-root sectors would then be work the amplitude never required.

4. Pruning must include the requested coefficient combinations

Applying exact boundary coefficients before GPL conversion is the right first step. It should be followed by assembly of the actual requested master combinations, not only by per-master pruning.

For a rational differential system, an algebraic homogeneous basis can introduce roots that disappear in the boundary-selected solution. But a zero homogeneous amplitude does not automatically remove the corresponding root from a particular solution:

F
(n)
(ρ)=Y
0
	​

(ρ)[c
(n)
+∫
ρ
0
	​

ρ
	​

Y
0
−1
	​

(s)S
(n)
(s)ds].

Even when c
(n)
=0, the forcing term can populate that component.

Thus prune the complete finite-order expression graph, including all forcing ancestors, outer homogeneous factors, and the final observable coefficients.

The source DE being rational does not establish GPL expressibility. Rational differential systems can describe algebraic and elliptic functions; even an epsilon-form is not, by itself, a guarantee of multiple polylogarithms. 
arXiv

Boundary simplifications must be exact. Agreement at two negative-epsilon points is a useful check of a candidate cancellation, but is not sufficient for deleting an entire analytic branch or a Gamma-valued coefficient.

5. Single-conic conversion is appropriate—with the whole dependency chain

For a component involving only one square root of a linear or quadratic polynomial in ρ, use one chart for that component and every ancestor evaluated inside it. This is the appropriate application of rational-root parametrization methods. 
arXiv

Suppose

ρ=R(t,z).

Every kernel must be pulled back:

K(ρ,z)dρ⟼K(R(t,z),z)∂
t
	​

R(t,z)dt.

Previously computed ancestor GPLs must be transformed as iterated integrals in the same chart. For instance,

ρ−a(z)
dρ
	​

⟼
R(t,z)−a(z)
R
t
	​

(t,z)
	​

dt,

whose partial fractions determine the transformed letters.

Do not transform only the outer kernel and leave an ancestor evaluated in an incompatible variable.

For the two-variable connection,

dI=(A
ρ
	​

dρ+A
z
	​

dz)I,

the pullback is

A
t
	​

=R
t
	​

A
ρ
	​

,
A
z
	​

=A
z
	​

+R
z
	​

A
ρ
	​

.
	​

(7)

This matters if you check tangential compatibility after conversion.

Also transform the lower endpoint and its tangential normalization. If

ρ∼c(z)(t−t
0
	​

)
m
,

then

logρ∼logc(z)+mlog(t−t
0
	​

).

Discarding logc(z) changes finite boundary constants.

Explicit single-root charts for your polynomials

For

P
1
	​

=(1+z)
2
−4zρ,

a particularly convenient physical chart is

ρ=(1+z)t−zt
2
,
P
1
	​

	​

=1+z−2zt.
	​

(8)

It maps 0<ρ<1 monotonically to 0<t<1 for 0<z<1, and

P
1
	​

	​

dρ
	​

=dt.

For

P
2
	​

=(ρ−2(1−z))
2
+4z(1−z),

set

v=
P
2
	​

	​

+ρ−2(1−z).

Then

ρ
P
2
	​

	​

P
2
	​

	​

dρ
	​

	​

=2(1−z)+
2
v
	​

−
v
2z(1−z)
	​

,
=
2
v
	​

+
v
2z(1−z)
	​

,
=
v
dv
	​

.
	​

	​

(9)

The physical branch has v>0. Its lower endpoint can be algebraic in z; that is acceptable as a parameter-dependent endpoint of a GPL representation.

I checked both chart identities and their Jacobians exactly. They are separate charts, not a simultaneous rationalization.

6. These two roots together have a genuine fixed-z obstruction

This can be decided directly from the supplied polynomials.

The first has the single real root

ρ
1
	​

=
4z
(1+z)
2
	​

.

The discriminant of the second is

disc
ρ
	​

P
2
	​

=16z(z−1)<0
	​


for 0<z<1. Hence P
2
	​

 has two distinct nonreal roots and cannot share ρ
1
	​

.

Therefore

E
z
	​

:y
2
=P
1
	​

(ρ,z)P
2
	​

(ρ,z)
	​

(10)

is a nonsingular cubic curve at every generic physical 0<z<1: it has genus one. Integrals involving the square root of such a cubic are the elliptic, rather than conic, case. 
DLMF

The obstruction is also visible after rationalizing P
1
	​

. Put

w=
P
1
	​

	​

,v=4z
P
2
	​

	​

.

Direct substitution gives

v
2
=[w
2
−(3z−1)
2
]
2
+64z
3
(1−z).
	​

(11)

This is a nonsingular quartic for 0<z<1, not another conic.

Thus no rational substitution in one parameter at fixed generic z can rationalize both roots simultaneously. The compositum of the two quadratic fields, not the individual square roots in isolation, is the appropriate algebraic object to inspect. 
arXiv

This statement is restricted to the fixed-z, ρ-integration problem. It does not assert that every conceivable two-variable change of coordinates is impossible.

The obstruction does not prove that the requested coefficients are elliptic

A mixed differential can still be exact. For example,

d
P
1
	​

P
2
	​

	​

=
2
P
1
	​

P
2
	​

	​

∂
ρ
	​

(P
1
	​

P
2
	​

)
	​

dρ

has an algebraic primitive.

By contrast,

P
1
	​

P
2
	​

	​

dρ
	​


is generically an elliptic differential. Its presence in an uncanceled primitive is a materially different situation.

So a common-root label is a warning that conic rationalization is insufficient. Before declaring an elliptic contribution, simplify exact derivatives and the actual boundary-selected combination. Do not force a GPL conversion, but do not infer a non-GPL final result from an auxiliary homogeneous basis either.

7. A cheap diagnostic for separate versus genuinely mixed chains

Use the finite integral-expression graph after boundary specialization and observable assembly.

Assign every nonzero kernel its square-class support over the rational function field in ρ, with z treated as a parameter. Simplify rational squares and exact cancellations first. Roots depending only on z are constants for this integration and should not be counted as additional ρ-curves.

Then distinguish:

Structure	Consequence
Sum of an P
1
	​

-component and a separate P
2
	​

-component	Convert separately
Product of completed functions, with no further integration	Separate GPL representations may remain as a product
Kernel in the P
1
	​

 field multiplying an ancestor depending on P
2
	​

, inside an integral	Genuinely mixed candidate
Off-diagonal forcing between the two root sectors	Potential mixed chain even if their homogeneous blocks are separate
Mixed kernel that simplifies to an exact derivative or cancels in the observable	No need to introduce a new function class

A union of root labels at an addition node is therefore too conservative: distribute integration over the sum before concluding that one common chart is required. Conversely, inspecting only diagonal homogeneous blocks is too weak: off-diagonal couplings and higher-epsilon forcing can join them.

For a candidate mixed chain, retain the exact finite-integral representation until algebraic differential reduction establishes whether the elliptic part cancels. Your finite solver remains a valid analytic representation even when the optional GPL layer cannot yet certify a conversion.

Recommended next action

First establish the reference cancellation in the existing generated tree density. Use the weak identities (1), or the exact difference (4), at generic D, with the full color relations and unit-cut kinematics. This is a correctness test and an opportunity to remove the P⋅k
2
	​

 family before further integration work.

Then reassemble the requested coefficient combinations using the completed reductions and exact boundary data, and compute their active dependency graph. Only after that should the converter apply the single-conic charts to surviving components.

The null reference p is a valid economical alternative and an independent algebraic check. It is not necessary to abandon the existing P-reference result if the exact cancellation is demonstrated. The two-root genus-one obstruction is real, but whether it matters physically depends on the graph that survives those upstream cancellations.