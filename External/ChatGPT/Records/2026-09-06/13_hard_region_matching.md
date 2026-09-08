# Hard-region matching experiment

## Question

We have concrete new evidence while you thought:
1. A new general exact cut-integral equivalence algorithm based on unit-Jacobian affine changes to independent oriented cut momenta groups all1561 local master functions into355 classes in1.75s (91families; full propagator powers, off-shell polynomial identity, cut momenta and causal signs preserved). All347 original coefficient masters are distinct under these maps, plus8 derivative-closure classes.
2. Pulling all91 rational DEs into this355-dimensional basis yields164 nonzero overlap equations (different DEs for same exact integral). Their rank is7. Differentiated constraints (dC+C A) still rank7 at a rational point. Thus currently348-spanning functions, not an established minimum. Extra independent-looking class CF248 with raised cut. We'll store exact quotient and substitute finite solutions, and distinguish CF269 basepoints.
3. Recovered actual historical files (not just period labels): AllMasterSoftCornerIntegralCensus.wl records347 originalmasters ->152 scalar boundary integrals from hard-region soft-corner substitution -> BoundaryIBPPreparation.wl exact partial fractions220terms,62cut topologies,154targets -> BoundaryIBPAnalysis.wl 7boundarymasters. These have two loops and just two external lightlike momenta a,b with2a.b=1. Two of7 are3-particle massless phase-space volume and same with one doubled cut. Other5 are cut phase-space integrals with eikonal a.k,b.k and pairwise final-state denominators. Geometry catalog appears simply sets external observed massless c->0 after suitable integer scaling; this captures hard region, not proven allsoft/collinear contributions. It reduced all347leadinghard-regionintegrals; unknown completeness.
4. Current math gap: how to go from355/348function directions to actual few boundaryintegrals without recreating decadesofmatchingcode. Local normal/tangential sourceanddegeneracy machinery exists, but only epsilonformFrobeniusconstructor; full noncanonical regular singular generic helper missing. Saved global rationalDEs are regular in physicalinterior.

Please propose the fastest concrete experiment now. Can we use full hard-region Taylor data (IBP-reduced to7 one-scale masters), plus DE local Frobenius matching at the corner and at other boundaries, to check rank without doing expensive analytic transport? What input is missing to certify absent region modes? Is a generic-dimension region analysis via parametric polynomial scaling the best next implementation, or would small inclusive moment reductions be cheaper here (observed c is externalmasslessparton, v=2a.c/s,w=2b.c/s; integratingc addsanextracut/loop and mightbeharder)? We should notpromise17or33basedonoldcounts. Please also discuss whether the two cut-only volume/dotted-volume masters are related by mass-squared differentiation or homogeneity, and exactly what convention matters.


## Pro response

Your 355−7=348 count is justified as a spanning bound. The recovered seven-integral reduction makes hard-region matching the right next experiment—but the relevant rank is the rank of the map from DE solution amplitudes to hard-region coefficients, not the rank of the seven boundary integrals.

My recommendation is to implement a one-variable, generic-ϵ, local coefficient-extraction test, extend the hard-region reductions only for the coefficients that increase its rank, and retain every undetermined mode. Do not start with a campaign-wide region engine or an inclusive three-loop reduction.

There is also an immediate independent test: with the standard reverse-unitarity convention, the massless three-particle dotted volume is rationally proportional to the ordinary volume. I derive the coefficient below. If those are indeed the two stored definitions, the seven reported boundary masters are not minimal even within the hard region.

1. What the new evidence establishes

The equivalence quotient and overlap equations accomplish the first reduction that was previously missing. There is no reason now to process the 1,561 family-labelled positions as separate boundary problems.

Two qualifications remain:

First, rank seven for the differentiated constraints at one rational point does not establish generic differential closure of the relation space. For a row matrix Q(X,ϵ) of retained relations, the relevant identity is

∂
i
	​

Q+QA
i
	​

=B
i
	​

Q.

Until this is established, 348 remains a spanning bound, and additional differential consequences may reduce it further. This need not delay the experiment: work with the 355 representatives and impose QG=0 in the local coefficient equations, or use the rational quotient already constructed.

Second, the historical calculation establishes that its 347 selected leading hard-region targets reduce to seven integrals. It does not establish that all higher Taylor coefficients, all eight additional closure classes, or every nonhard region reduce to the same seven. Those are separate questions.

The next calculation should therefore return something of the form

a(ϵ)=M
H
	​

(ϵ)P
H
	​

(ϵ)+N
H
	​

(ϵ)u(ϵ),
	​

(1)

where a are complete local DE amplitudes, P
H
	​

 are actual reduced hard-region integrals, and u are explicitly unresolved amplitudes. The central diagnostic is

δ
H
	​

=dimu.

That number—not a period-type count—determines the next workload.

2. The fastest concrete experiment
A. Use a radial soft limit through the common ordinary point

Introduce

z=v+w,t=
v+w
v
	​

,v=zt,w=z(1−t).

Then c=z
c
ˉ
(t), with the direction of the observed parton fixed as z→0
+
.

For

dG=A
v
	​

Gdv+A
w
	​

Gdw,

the pulled-back system is

∂
z
	​

G=[tA
v
	​

+(1−t)A
w
	​

]G,∂
t
	​

G=z(A
v
	​

−A
w
	​

)G.
(2)

Use t
0
	​

=3/5 for the first calculation. This ray passes through the common basepoint:

(v
∗
	​

,w
∗
	​

)=(1/4,1/6)⟺(z
∗
	​

,t
∗
	​

)=(5/12,3/5).

Thus any later numerical connection along this ray connects directly to the existing ordinary-point constants. CF269 remains separately based, as you already intend.

A second generic rational t is useful for detecting specialization problems. Do not add ranks from independently normalized rays without identifying their solution coordinates.

B. Construct complete local jets, not a full analytic connection matrix

The missing helper can initially be much narrower than a general multivariable boundary package:

Given a one-variable rational DE block, construct its complete regular-singular power/log coefficient jets at generic ϵ, including inherited sources.

After a suitable local gauge, write

z∂
z
	​

F=[R(ϵ)+
m≥1
∑
	​

z
m
A
m
	​

(ϵ)]F+S.
(3)

For a local ansatz

F=
λ,n
∑
	​

z
λ(ϵ)+n
f
λ,n
	​

(L,ϵ),L=logz,

the recurrence is

[(λ+n)1−R+∂
L
	​

]f
λ,n
	​

=
m=1
∑
n
	​

A
m
	​

f
λ,n−m
	​

+s
λ,n
	​

.
	​

(4)

This is the necessary extension of an epsilon-form Frobenius constructor: R is now a general matrix in ϵ, rather than ϵR
0
	​

. At resonances, solve the coupled polynomial-in-L equations and retain all free coefficients; do not invert a singular recurrence matrix.

Start with integer valuation gauges and the existing homogeneous-block machinery. For blocks still displaying higher-order poles, a scalar regular-singular equation for a cyclic component is a possible fallback; it avoids making a full multivariable Fuchsianization implementation a prerequisite. Scalarization and Frobenius/reduction-of-order constructions are used in noncanonical DE series methods. 
arXiv

Regularity of the rational DEs in the physical interior does not establish regular singularity at the corner. A block whose regular-singular reduction has not been obtained stays unresolved.

Keep ϵ generic at this stage. Expanding

z
bϵ
=1+bϵlogz+⋯

before classifying modes can obscure the distinction between hard and nonhard exponent sectors.

C. Build the coefficient-extraction matrix before requesting more boundary IBPs

Let the complete local solution at t
0
	​

 be

G(z)=Ψ(z,ϵ)a(ϵ),

where Ψ is needed only as a truncated power/log expansion.

Choose coefficient functionals corresponding to the hard Taylor coefficients you can calculate. Applying them to the local solution gives

E
N
	​

(ϵ)a(ϵ).

The integral expansion and boundary IBP reduction give

H
N
	​

(ϵ)=T
N
	​

(ϵ)P
H
	​

(ϵ).

The matching equations are

E
N
	​

a=T
N
	​

P
H
	​

.
	​

(5)

Compute rankE
N
	​

, not rankT
N
	​

. The latter cannot exceed the number of hard boundary masters; the former can be much larger. Hundreds of independent equations can have right-hand sides expressed through six or seven common integrals.

There is a physical-validity condition behind (5), discussed below: the selected full-solution coefficient must actually equal the calculated hard-region coefficient. Initially, store separately the rows for which this is established and those that assume the hard region exhausts a particular exponent sector.

Use the local DE jets to identify which additional coefficient rows would increase rank. Only then generate and reduce those Taylor coefficients. This avoids expanding every master to an arbitrary common depth.

Include the eight closure classes explicitly. A quotient identity may supply their coefficients; otherwise they need their own selected expansions. In particular, do not omit the raised-cut CF248 direction merely because the historical campaign covered the original 347.

The boundary reduction must also be extended to the newly demanded powers and numerators. A seven-master reduction for 154 targets is not automatically a seven-master reduction for the full Taylor tower. Reverse-unitarity expansion followed by IBP reduction of the expansion coefficients is an established method, but the reduction coverage must match the actual coefficient targets. 
arXiv

D. Use known tangential dependence without doing tangential transport

If the hard coefficients are known as functions of t, rather than only at t
0
	​

, their tangential derivatives can supply further equations at the same point.

For example, suppose the local amplitude coordinates obey

∂
t
	​

a=B
loc
	​

(t,ϵ)a

and a known hard coefficient satisfies

E(t)a(t)=T(t)P
H
	​

.

Then

[∂
t
	​

E+EB
loc
	​

]a=(∂
t
	​

T)P
H
	​

.
(6)

Evaluate this at t
0
	​

, and iterate only while rank increases.

This uses your existing normal/tangential machinery and requires no analytic connection along the boundary. It can distinguish directions that have the same normal exponent.

However, the tangential DE alone does not remove constants. The additional information comes from comparing it with the independently known angular dependence of the hard coefficients.

E. Stop using a resonance criterion, not an arbitrary Taylor depth

A plateau between orders N and N+1 is not a proof of saturation. A mode may first appear at a later integer valuation.

The local constructor should record every resonance index at which

det[(λ+n)1−R]=0.

Continue sufficiently far to expose all independent leading jets, including shifts induced by the physical-basis gauge. Once the full local solution space is represented, one can distinguish:

directions not yet seen because the jet is too short;

directions identically invisible to the chosen hard coefficient functionals.

The elementary obstruction is

G(z)=G
H
	​

(z)P+z
−ϵ
G
S
	​

(z)Q,

with G
H
	​

,G
S
	​

 ordinary power series. No number of integer-power hard Taylor coefficients determines Q at generic ϵ.

After saturation, solve (5) to obtain (1). If the equations are physically justified, they provide a constructive representation using at most

#P
H
	​

+δ
H
	​


series inputs, before accounting for known evaluations and relations among P
H
	​

.

A nonzero left-null relation of E
N
	​

 also gives a useful diagnostic:

ℓE
N
	​

=0⟹ℓT
N
	​

P
H
	​

=0.

This may expose a missing boundary IBP relation—or an incorrect hard expansion. Do not silently assume the seven stored integrals are algebraically independent.

3. What is missing to make hard matching physical?

There are two different issues: correctness of the hard expansion itself, and whether it exhausts the full-solution coefficients being matched.

The hard substitution must retain every surviving direction and cut derivative

Setting c→0 after multiplying by an integer power is not universally equivalent to extracting the hard region.

For example, on an undotted massless cut k
2
=0,

(k+c)
2
1
	​

=
2zk⋅
c
ˉ
1
	​

.

After removing z
−1
, the denominator k⋅
c
ˉ
 remains. It cannot be replaced by an integral involving only a,b.

This does not show that your historical substitution is wrong. It gives a precise test: does every selected coefficient truly have only the two-vector denominator structure, or has a surviving 
c
ˉ
-dependent denominator been discarded? Tensor numerators involving 
c
ˉ
 are a different matter and can often be reduced covariantly against a,b.

Raised cuts require an additional check. With

Δ
1
	​

(D)=δ(D),Δ
2
	​

(D)=−δ
′
(D),

one has

DΔ
2
	​

(D)=Δ
1
	​

(D),

not zero. Consequently, simplifications valid on an undotted cut need not remain valid after Taylor expansion generates dotted cuts. Preserve the off-shell polynomial dependence until the cut-power algebra has been applied.

A cheaper certificate than a complete region census may suffice

For a finite set of selected Taylor coefficients, seek an open domain in the dimensional or auxiliary regulators where differentiating under the phase-space integral is justified:

∂
z
n
	​

∫
Ω(z)
	​

ω(z)
	​

z=0
	​

=∫∂
z
n
	​

ω(z)∣
z=0
	​

,n≤N,
(7)

after transforming the domain appropriately and including its boundary dependence.

A uniform integrable bound on the differentiated integrand establishes these identities there; meromorphic continuation then supplies the corresponding dimensionally regulated coefficient identities.

For bounded final-state phase space, sufficiently large ReD is a useful place to test such bounds. It is not automatically sufficient: angular singularities, surviving eikonal denominators, and differentiated cuts must all be included. For dotted cuts, establish the statement after treating the delta derivatives or through a controlled mass deformation.

This is potentially much cheaper than constructing every region. It can certify selected rows of (5).

But even a valid finite Taylor expansion does not exclude a contribution such as z
α+βD
 whose first several derivatives vanish in that regulator domain. Nor does having a separately valid continuation for each Taylor coefficient prove that the complete physical function equals its hard Taylor series.

What actually excludes an undetermined mode?

For each residual mode, one needs an independent reason its physical amplitude vanishes or is related to known inputs. Examples are a proven scaling bound incompatible with that mode, an empty oriented-cut region, a scaleless region integral in the specified regulator scheme, an exact boundary relation, or complete matching to a set of physical regions.

A region enumeration must also account for overlaps and possible cancellations. Completeness and the treatment of overlap contributions are substantive conditions of expansion by regions, not consequences of listing several plausible scalings. 
arXiv

Most importantly, nonhard regions can sometimes contribute to the same exponent/log sector as the hard region. In that case,

H
N
full
	​

=H
N
hard
	​

+H
N
other
	​

,

and the hard contribution alone cannot be used on the right of (5). A generic-D exponent classification can often distinguish these sectors, but coincident sectors and auxiliary-regulator cancellations must be retained explicitly.

4. Other boundaries: use numerical transport only on the residual space

Once

a=M
H
	​

P
H
	​

+N
H
	​

u

has been obtained, other boundary conditions need act only on u.

Initialize the δ
H
	​

 columns

Ψ(z)N
H
	​


at a small positive z using the local series, and propagate those columns numerically to another boundary. There is no need to construct or analytically transport a full 348×348 fundamental matrix.

If a physical condition at the second boundary is represented by a local coefficient functional L
s
	​

, the residual constraint matrix is

B
s
	​

=L
s
	​

U
s←H
	​

N
H
	​

.
(8)

Its rank measures how much that boundary adds beyond the hard data.

Use the complete coefficient functional at the second boundary—not a residue acting directly on the starting amplitudes. The condition must itself be physically justified. In particular, a DE pole that is apparent for every solution yields no new constraint.

For the experiment, stable high-precision ranks at several nonspecial ϵ values are useful decision evidence. A numerical rank is not yet a certified bound. A certified nonzero minor, including series and integration error bounds, supplies a generic rank lower bound. In contrast, a nonzero modular minor of an exact local rational coefficient matrix already proves the corresponding algebraic rank lower bound.

This lets you postpone analytic connection coefficients until the residual dimension is known. It does not eliminate the eventual need for explicit matching coefficients when substituting into the saved finite solutions.

5. Regions versus inclusive moments in this specific problem

I would now put inclusive moments behind targeted region analysis. Your clarification about c changes the cost assessment.

Here c is an external observed massless parton. Integrating it requires its on-shell measure, schematically

∫d
D
cδ
+
	​

(c
2
)w(
s
2a⋅c
	​

,
s
2b⋅c
	​

)G(c),

including the Jacobian and angular measure when rewritten in v,w. It is not merely deleting two measurement delta functions from an existing integral.

Under your stated topology, this adds an independent integration and a cut. That may still produce a useful inclusive family, but there is no present evidence that it is cheaper than completing selected two-loop boundary regions. Test such a moment only after identifying a particularly simple residual combination or a known inclusive reduction.

For region analysis, implement a candidate generator for the residual blocks, not a universal certificate for all 355 classes.

Given a physical parametric representation

I(z)=∫
Ω(z)
	​

i
∏
	​

dx
i
	​

x
i
α
i
	​

(ϵ)−1
	​

j
∏
	​

P
j
	​

(x,z)
β
j
	​

(ϵ)
,

a scaling x
i
	​

=z
r
i
	​

y
i
	​

 predicts

λ
r
	​

(ϵ)=
i
∑
	​

r
i
	​

α
i
	​

(ϵ)+
j
∑
	​

m
j
	​

(r)β
j
	​

(ϵ),
(9)

plus any prefactor valuation. Here m
j
	​

(r) is the leading z-valuation of P
j
	​

.

Compare these exponents with the unresolved local DE sectors. Reduce only region integrals needed to span those sectors. Polynomial/Newton-polytope methods provide an algorithmic way to generate candidate scalings, particularly for positive-coefficient representations. 
arXiv

For your cuts, however, the representation must retain the physical domain, oriented energy support, and causal prescriptions. Feeding an uncut polynomial to a region finder and subsequently attaching cut labels is not a completeness argument. Sign cancellations and internal pinches can require additional domain decompositions; explicit examples show that naive facets can miss leading regions. This is a warning about the method, not a claim that your two-loop families necessarily contain those particular hidden regions. 
arXiv

Thus the implementation order should be:

local rank deficit⟶targeted physical scaling candidates⟶region IBP⟶mode matching.
	​

6. The volume and dotted-volume relation

Assume the ordinary volume is

V
D
	​

(s;m
1
2
	​

,m
2
2
	​

,m
3
2
	​

)=N
D
	​

∫d
D
k
1
	​

d
D
k
2
	​

i=1
∏
3
	​

δ
+
	​

(k
i
2
	​

−m
i
2
	​

),

where

k
3
	​

=P−k
1
	​

−k
2
	​

,P=a+b,P
2
=s>0,

all three cut momenta are future-directed, and N
D
	​

 is independent of the masses.

Define cut powers by

Δ
n
	​

(D
q
	​

)=
2πi
θ(q
0
)
	​

[
(D
q
	​

−i0)
n
1
	​

−
(D
q
	​

+i0)
n
1
	​

]=
(n−1)!
(−1)
n−1
	​

θ(q
0
)δ
(n−1)
(D
q
	​

),
(10)

with D
q
	​

=q
2
−m
2
. Then

∂
m
2
	​

Δ
1
	​

(D
q
	​

)=Δ
2
	​

(D
q
	​

).

Consequently, the volume with one doubled cut is

V
211,D
	​

(s)=∂
m
1
2
	​

	​

V
D
	​

(s;m
1
2
	​

,0,0)
	​

m
1
2
	​

=0
	​

,
(11)

first where this differentiation is legitimate, then by meromorphic continuation.

The result is

V
211,D
	​

(s)=−
(D−4)s
(D−3)(3D−8)
	​

V
111,D
	​

(s).
	​

(12)

At D=4−2ϵ,

V
211
	​

(s)=
ϵs
(1−2ϵ)(2−3ϵ)
	​

V
111
	​

(s).
	​

(13)
Derivation

Factorize the phase space through u=(k
2
	​

+k
3
	​

)
2
/s, and set x=m
1
2
	​

/s. Up to a mass-independent factor,

V
D
	​

(s;m
1
2
	​

,0,0)=K
D
	​

s
D−3
∫
0
(1−
x
	​

)
2
	​

duu
D/2−2
λ(1,x,u)
(D−3)/2
.

At x=0,

V
D
	​

(s;0,0,0)=K
D
	​

s
D−3
B(
2
D
	​

−1,D−2).

For ReD>4, differentiation gives

∂
m
1
2
	​

	​

V
D
	​

	​

0
	​

=−K
D
	​

s
D−4
(D−3)[B(
2
D
	​

−1,D−4)+B(
2
D
	​

,D−4)].

The beta-function recurrences give (12).

What convention matters?

The relative normalization of cut powers matters: a doubled cut is not δ
+
2
	​

. If the stored doubled object is +δ
′
, rather than the −δ
′
 in (10), the sign reverses. A rescaled denominator also introduces the corresponding scale factor.

The derivative in (11) holds the external vectors and s fixed and changes one cut mass squared. Differentiating a common mass assigned to all three lines gives three equal dotted contributions at the massless point.

The massless limit must be understood through the regulated identity. Near four dimensions, the massive phase-space volume has nonanalytic small-mass terms; blindly differentiating the full small-mass expression at fixed ϵ and setting the mass to zero need not be legitimate.

Finally, homogeneity alone does not give (12). It only gives

(s∂
s
	​

+
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

)V
D
	​

=(D−3)V
D
	​

.

At zero masses, the mass-derivative terms disappear from this equation. Their values require the phase-space/IBP relation above.

If your two stored definitions match these assumptions, immediately test and insert (13). The reported seven hard boundary masters then reduce to at most six spanning integrals, with the volume known and at most five requiring new evaluation. This says nothing yet about missing regions or higher-Taylor targets. Also, the 1/ϵ factor must be propagated into Laurent-depth demands.

7. The implementation milestone I would require

The first run should produce three numbers and the matrices supporting them:

r,p
H
	​

,δ
H
	​

=r−rankE
H
	​

,
	​


where r is the retained global solution dimension, p
H
	​

 is the number of actual hard boundary integrals required by the selected coefficients after reduction, and E
H
	​

 contains only justified matching rows.

Alongside them, retain the explicit parametrization (1), the unresolved modes with their full exponent/log jets, and any additional rank obtainable only under unproved hard-region assumptions.

The decisive result is not “seven boundary masters.” It is “these explicit hard integrals determine all but δ
H
	​

 directions, and here are the surviving directions.” That result directly tells you whether a few targeted region reductions will finish the problem or whether the historical hard corner leaves a substantial part of the physical solution undetermined.