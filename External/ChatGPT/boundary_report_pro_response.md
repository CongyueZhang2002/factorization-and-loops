Counting Independent Analytic Boundary Integrations in Reverse Unitarity
Executive answer

The number of Kira master integrals is not the number of analytic boundary integrations that must be evaluated independently.

For the complete NLO real-emission reduction considered here, the exact counts are:

Object being counted	Exact number
Kira master integrals	6
Positive-denominator classes after exact momentum relabeling	3
Maximal nontrivial denominator classes	2
Analytic inputs needed to determine all 6 masters	2
Genuinely nontrivial boundary integrations, when the elementary phase-space normalization is treated as known	1

The two analytic inputs are:

B(ϵ)=
1−2ϵ
2π
	​

,

the elementary cut-bubble normalization, and the normalized endpoint of one generic top function,

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

2
	​

F
1
	​

(1,1;1−ϵ;z).

All five non-bubble NLO masters are obtained by substituting different physical cross ratios and scale pairs into this same function. They do not require five separate integrations.

Thus the operational NLO conclusion is

6 masters require 2 analytic inputs in total,or only 1 genuinely nontrivial SubTropica boundary job
	​


when the elementary bubble normalization is supplied as known.

For the corrected NNLO double-real reduction, the exact denominator bookkeeping gives

342 masters⟶130 powered classes⟶82 positive-denominator classes⟶17 maximal nontrivial denominator classes.

The number 17 is not yet the number of NNLO boundary integrations. It counts maximal denominator geometries before differential-equation closure, local boundary analysis, identification of equivalent parametric densities, and comparison of normalized analytic periods.

1. The integrals being classified

Let

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

and define the unobserved recoil momentum

q=k
a
	​

+k
b
	​

−k
c
	​

,q
2
=s+t+u.

A reverse-unitarity integral has the form

I
T,ν
	​

(s,t,u;ϵ)=∫
r=1
∏
L
	​

iπ
D/2
d
D
ℓ
r
	​

	​

j=1
∏
N
T
	​

	​

D
T,j
−ν
j
	​

	​

,D=4−2ϵ.

The topology label T specifies:

the ordered denominator list;

the loop and phase-space integration momenta;

the external momenta;

the kinematic relations;

the positions and positive-energy orientations of the physical cuts.

The exponent vector

ν=(ν
1
	​

,…,ν
N
T
	​

	​

)

specifies one integral in that topology. Kira represents it as

GLI[T,ν].
1.1 Positive-denominator set

For a master integral I
T,ν
	​

, define

D
+
	​

(I
T,ν
	​

)={D
T,j
	​

:ν
j
	​

>0},

with the cut identity and cut orientation attached to every physical cut element.

This set records which denominator hypersurfaces are present, but not their positive powers. Consequently,

D
−1
andD
−2

belong to the same positive-denominator set, although they are different integrals. A negative index represents a numerator or irreducible scalar-product insertion and is not included.

No comparison is valid if it:

deletes a physical cut;

maps a cut to an ordinary propagator;

reverses the positive-energy direction of a cut;

changes the declared physical branch without an explicit continuation map.

2. Distinct notions that must not be conflated

Several different equivalence and counting problems occur between diagrams and analytic boundary data.

2.1 Equality of diagrams

Two diagrams are equal only when their:

graph structure;

field assignments;

external ordering;

position on the amplitude or conjugate-amplitude side

all agree.

Distinct diagrams can nevertheless generate the same integral topology after color, spin, polarization, and numerator algebra. Diagram counting therefore determines neither the number of masters nor the number of boundary integrations.

2.2 Equality after an affine loop-momentum transformation

Two integral topologies are equivalent when an invertible affine transformation

ℓ
r
′
	​

=
s
∑
	​

A
rs
	​

ℓ
s
	​

+
i
∑
	​

B
ri
	​

p
i
	​

,detA=±1,

together with an allowed external-momentum relabeling, maps the complete denominator list of one topology into that of the other while preserving every physical cut.

At one loop, for example,

ℓ⟼q−ℓ

interchanges the two cut momenta ℓ and q−ℓ. Integrals related by this transformation are not independent topology problems.

2.3 Equality of powered master integrals

Two masters are power-equivalent if a certified momentum transformation maps:

every ordinary denominator;

every physical cut;

every positive and negative exponent

to the corresponding data of the second master.

A doubled ordinary propagator remains doubled, and a differentiated cut remains differentiated. This relation answers:

Are these exactly the same integral, including all denominator powers?

For the NNLO double-real calculation, the relabeling group includes all permutations of the three positive-energy cut momenta. The geometric hard-leg relabelings act on

{k
a
	​

,k
b
	​

,−k
c
	​

}.

A hard-leg crossing identifies denominator geometry only. Equality of physical values additionally requires the corresponding analytic-continuation and branch map.

2.4 Equality of positive-denominator sets

To classify denominator geometry, replace every positive exponent by one and repeat the full canonicalization over all allowed momentum relabelings.

Two masters belong to the same class at this level if they contain the same cut and ordinary denominator hypersurfaces, even when their powers differ.

The order of operations is essential:

remove the positive powers;

reapply every allowed relabeling;

choose the canonical denominator set.

It is generally incorrect to remove powers only from a powered representative chosen earlier. The relabeling that minimizes a powered description need not minimize the corresponding unpowered denominator description.

2.5 Set inclusion between denominator classes

Let [A] and [B] denote equivalence classes of positive-denominator sets. Define

[A]⪯[B]

when there exists an allowed relabeling g such that

g(A)⊆B.

This is a partial order, not an equivalence relation.

Strict inclusion,

[A]≺[B],

means that [A]⪯[B] but the two classes are not equivalent.

A class is maximal when it is not strictly included in any other class in the master inventory. For a maximal class M, define its downward closure by

↓M={A:[A]⪯[M]}.

This contains the maximal class and all lower-denominator classes contained in it. Two different maximal classes can contain the same lower-denominator class, so their downward closures may overlap.

2.6 Closure under kinematic differentiation and IBP reduction

A maximal denominator class does not automatically define a self-contained differential-equation problem.

Let

V
M
	​

=span{I
j
	​

:D
+
	​

(I
j
	​

)∈↓M}.

Choose independent kinematic coordinates ξ
α
	​

, for example two dimensionless ratios together with an overall scale relation. The class M defines a closed differential-equation family only if

∂
ξ
α
	​

	​

V
M
	​

⊆V
M
	​


for every independent ξ
α
	​

, after exact IBP reduction.

If a derivative of a master in V
M
	​

 produces a top-level master belonging to another incomparable maximal denominator class, the two classes must be included in one larger differential system.

Shared lower-denominator masters do not by themselves force such a merger. Conversely, one maximal denominator class can split into several independent differential-equation blocks.

2.7 Equality of analytic boundary data

Even two closed differential systems can require the same normalized analytic period at a boundary.

Such an identification is valid only after fixing:

integral normalization;

cut identities and positive-energy directions;

physical kinematic chamber;

causal prescription;

endpoint and direction of approach;

analytic branch.

The following counts are therefore distinct:

N
master
	​

,N
maximal denominator
	​

,N
DE system
	​

,N
scalar boundary coefficient
	​

,N
boundary integration
	​

,N
new period
	​

.

Their meanings are:

Count	Meaning
N
master
	​

	Number of individual Kira basis integrals
N
maximal denominator
	​

	Number of maximal nontrivial denominator geometries
N
DE system
	​

	Number of closed coupled differential systems
N
scalar boundary coefficient
	​

	Number of unfixed Frobenius or Levelt coefficients after physical constraints
N
boundary integration
	​

	Number of distinct direct analytic integrations needed to determine those coefficients
N
new period
	​

	Number of normalized analytic quantities not already known from another system

Only N
boundary integration
	​

 directly counts independent SubTropica jobs.

One boundary integration may determine several scalar coefficients. Conversely, one differential system may require several distinct boundary integrations. Two different systems may also reuse the same period.

3. Exact classification of denominator geometries

The exact denominator classification proceeds from the stored Kira master list and the corresponding topology definitions.

Read each

GLI[T,ν],

the ordered denominator list of T, and the recorded cut positions, cut momenta, and cut directions.

Convert every denominator with positive exponent into its exact scalar-product polynomial.

Impose the massless external relations and the on-shell equations associated with the physical cuts.

Express every denominator in an independent scalar-product coordinate basis.

For geometric comparison only, remove an overall kinematics-dependent factor when that factor has been certified nonzero in the declared physical chamber. This does not remove the factor from the actual integral normalization.

Apply every certified cut-momentum and hard-leg relabeling.

Canonically order the transformed denominators, cut data, and powers. The lexicographically minimal exact representation defines the powered master class.

Replace every positive exponent by one and repeat the full relabeling and canonicalization. This defines the positive-denominator class.

For every pair of positive-denominator classes, test exact set inclusion under all allowed relabelings.

Remove the class containing only the physical cuts and identify the maximal remaining classes.

The resulting maximal-class count is

N
maximal denominator
	​

=∣Max(C∖{C
cut only
	​

})∣,

where C is the finite set of positive-denominator classes.

This procedure determines denominator geometry only. It does not construct a differential equation or evaluate any boundary integral.

4. NLO worked example
4.1 Cut kinematics

At NLO there is one independent emitted momentum k
e
	​

 and one dependent cut momentum

k
d
	​

=q−k
e
	​

.

The two physical cut denominators are

C
e
	​

=k
e
2
	​

,C
d
	​

=(q−k
e
	​

)
2
.

Introduce

a=2k
a
	​

⋅k
e
	​

,b=2k
b
	​

⋅k
e
	​

,c=2k
c
	​

⋅k
e
	​

.

On the two-cut surface,

C
d
	​

=0.

Since

q=k
a
	​

+k
b
	​

−k
c
	​

,q
2
=s+t+u,

the cut equation gives

c=a+b−(s+t+u).

Representative ordinary denominators are

D
a
	​

=(k
a
	​

−k
e
	​

)
2
=−a,
D
s
	​

=(k
a
	​

+k
b
	​

−k
e
	​

)
2
=s−a−b,

and

D
c
	​

=(k
c
	​

+k
e
	​

)
2
=c=a+b−(s+t+u).
4.2 Three positive-denominator classes

The six Kira masters occupy three exact positive-denominator classes:

A
0
	​

={C
e
	​

,C
d
	​

},
A
1
	​

={C
e
	​

,C
d
	​

,D
a
	​

,D
s
	​

},
A
2
	​

={C
e
	​

,C
d
	​

,D
a
	​

,D
c
	​

}.

Their master multiplicities are:

Denominator class	Number of masters	Interpretation
A
0
	​

	1	Elementary two-body cut volume
A
1
	​

	2	First maximal nontrivial denominator geometry
A
2
	​

	3	Second maximal nontrivial denominator geometry

The only strict inclusions are

A
0
	​

⊂A
1
	​

,A
0
	​

⊂A
2
	​

.

Neither A
1
	​

 nor A
2
	​

 contains the other. The geometric classification is therefore

6 masters⟶3 positive-denominator classes⟶2 maximal nontrivial denominator classes.

This does not imply two distinct nontrivial boundary integrations.

4.3 The two direct NLO analytic integrations

The exact NLO evaluator invokes SubTropica twice.

Elementary cut bubble

The first direct integration is reduced to the density

f
B
	​

(r,ϵ)=r
−ϵ
(1+r)
−2+2ϵ
,0<r<∞.

With the evaluator’s exact normalization, it gives

B(ϵ)=
1−2ϵ
2π
	​

.

This is the elementary cut-only phase-space normalization.

Generic top function

The second direct integration is reduced to

f
T
	​

(r,z,ϵ)=
1+(1−z)r
(1+r)
ϵ
	​

,0<z<1.

With the evaluator’s normalization, the result is

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

2
	​

F
1
	​

(1,1;1−ϵ;z).

For the real branch 0<z<1,

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=
Λ
1
	​

Λ
2
	​

π
	​

[
	​

−
ϵ(1−z)
1
	​

+
1−z
ln(1−z)
	​

+ϵ
1−z
Li
2
	​

(
z−1
z
	​

)
	​

+ϵ
2
1−z
Li
3
	​

(
z−1
z
	​

)
	​

+O(ϵ
3
)].
	​


The argument

z−1
z
	​


is negative for 0<z<1, so the displayed logarithms and polylogarithms lie on the common real branch selected by the physical chamber.

4.4 Differential equation and endpoint normalization

Apart from its constant scale factor, the generic top function satisfies the hypergeometric equation

z(1−z)T
′′
(z)+(1−ϵ−3z)T
′
(z)−T(z)=0.

At z=0, the two local Frobenius behaviors are associated with exponents

0andϵ.

The physical solution is the branch analytic in z at z=0. Its remaining normalization is fixed by

z→0
+
lim
	​

[
π
Λ
1
	​

Λ
2
	​

	​

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)+
ϵ
1
	​

]=0
	​

.

Equivalently,

T(0,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

.

The combination of:

the analytic Frobenius branch at z=0; and

this one normalization

uniquely selects the physical generic top solution. A new boundary calculation is not required for each kinematic instance.

The current direct evaluator computes the full generic one-variable density. In a differential-equation workflow, the independently required information from that integration is the normalized endpoint above.

4.5 Five physical top instances from one generic function

The five non-bubble masters are obtained by substituting the following cross ratios and scale pairs into the same function T:

Instance	Cross ratio z
i
	​

	Scale pair (Λ
i1
	​

,Λ
i2
	​

)
ac	
(s+t)(t+u)
su
	​

	(−
2
s+t
	​

,−
2
t+u
	​

)
ab	
(s+t)(s+u)
tu
	​

	(−
2
s+t
	​

,−
2
s+u
	​

)
abb	
(s+t)(s+u)
s(s+t+u)
	​

	(−
2
s+t
	​

,−
2
s+u
	​

)
cb	
(s+u)(t+u)
st
	​

	(−
2
t+u
	​

,−
2
s+u
	​

)
cbb	
(s+u)(t+u)
u(s+t+u)
	​

	(−
2
t+u
	​

,−
2
s+u
	​

)

In the declared physical chamber used by the calculation,

0<z
i
	​

<1

for all five rows. They therefore use the same physical branch of T.

The five rows are kinematic substitutions, not five new integrations.

4.6 Exact NLO analytic workload

Two counting conventions are useful.

Complete analytic-input count

Include the elementary cut volume:

N
analytic input
NLO
	​

=2.

The two inputs are:

B(ϵ);

the normalized endpoint of T.

Genuinely nontrivial boundary-task count

Treat the elementary cut volume as known:

N
nontrivial boundary job
NLO
	​

=1.

The only nontrivial job is the generic top endpoint.

Quantity	Exact count	Meaning
Kira masters	6	One bubble and five physical top instances
Positive-denominator classes	3	Exact denominator geometries after relabeling
Maximal nontrivial denominator classes	2	Geometric classification only
Analytic inputs needed for all masters	2	Bubble normalization and generic top endpoint
Genuinely nontrivial SubTropica boundary jobs	1	Generic top endpoint, with bubble preloaded
Physical top instances generated from that input	5	Kinematic substitutions

The correct operational statement is therefore

6 NLO masters⇒2 analytic inputs in total⇒1 genuinely nontrivial boundary job.
	​


There must not be five additional jobs for the five top instances.

5. NNLO double-real classification
5.1 Cut kinematics

At NNLO double real there are two independent emitted momenta k
e
	​

,k
f
	​

 and one dependent cut momentum

k
g
	​

=q−k
e
	​

−k
f
	​

.

The three physical cuts are

C
e
	​

=k
e
2
	​

,C
f
	​

=k
f
2
	​

,C
g
	​

=(q−k
e
	​

−k
f
	​

)
2
.

All six permutations of

{k
e
	​

,k
f
	​

,k
g
	​

}

are included when comparing denominator geometries. The geometric hard-leg transformations act on

{k
a
	​

,k
b
	​

,−k
c
	​

}.

The corresponding physical crossing and branch continuation are retained as a separate requirement when analytic values are compared.

5.2 Exact NNLO bookkeeping

The corrected NNLO Kira basis gives:

Object being counted	Exact number	Definition
Kira masters	342	Individual stored GLI basis elements
Powered classes	130	All denominator and cut powers retained
Positive-denominator classes	82	Positive powers replaced by one, followed by complete recanonicalization
Cut-only class	1	Elementary three-body phase-space normalization
Nontrivial denominator classes	81	At least one ordinary propagator is present
Maximal nontrivial denominator classes	17	Not strictly included in another denominator class

The 130 powered classes account for all 342 masters:

14×1+65×2+22×3+21×4+8×6=342.

Their cut-power patterns are

92 classes with (1,1,1),38 classes with (1,1,2).

The location of the doubled cut is identified under permutation of the three cut momenta, while the fact that one cut is doubled remains part of the powered classification.

Among the 17 maximal nontrivial denominator classes:

Number of ordinary denominators, in addition to the three cuts	Number of maximal classes
6	4
5	12
4	1

Thus the exact geometric inventory is

342⟶130⟶82⟶17.
	​


Every one of the 81 nontrivial denominator classes is contained in at least one of the 17 maximal classes. Their downward closures overlap, so master counts associated with different maximal classes must not be added.

5.3 Why the number 17 is not the NNLO boundary workload

The NLO result already disproves the rule

one maximal denominator class=one boundary integration.

At NLO, two maximal nontrivial denominator classes lead to one generic nontrivial top endpoint.

Before an NNLO SubTropica queue can be constructed, the following steps remain.

Construct the exact differential equations.
For each maximal denominator class, include all masters in its downward closure and differentiate with respect to a complete set of independent kinematic variables.

Reduce every derivative by IBP.
Determine whether the resulting equations stay within that downward closure.

Merge classes that are dynamically coupled.
If derivatives connect top-level masters from two incomparable maximal classes, those classes belong to one larger differential system.

Decompose each closed system into coupled blocks.
A single denominator class can contain several independent differential-equation blocks.

Analyze the chosen boundary.
Determine the Frobenius or Levelt exponents, resonant blocks, logarithmic modes, and allowed physical branches.

Impose physical constraints.
Apply:

regularity;

expansion-by-regions information;

corner behavior;

symmetry;

scaleless limits;

lower-integral data;

known normalizations.

Count the remaining scalar boundary coefficients.
This count can be larger or smaller than the number of maximal denominator classes.

Choose explicit analytic integrals that determine those coefficients.
One explicit integration can determine several scalar coefficients.

Identify equivalent generic densities.
Distinct differential systems or denominator classes can reduce to the same parametric integral after a change of variables or a certified crossing.

Identify reused normalized periods.
A boundary quantity already computed for one system need not be reevaluated for another system.

Assign one SubTropica job to each remaining distinct analytic representation.

Only after these steps is the exact NNLO boundary-integration count known.

The number 17 should therefore be described as

17 maximal nontrivial denominator classes,
	​


not as 17 differential systems, 17 scalar constants, or 17 SubTropica jobs.

6. Lessons from three completed NNLO examples

For brevity, the stored record labels 83bb, f228, and d099 are used to distinguish three completed examples. These labels are not physical family names.

Their measured analytic difficulty is

83bb>f228>d099.

This is an empirical ordering based on differential coupling, local boundary structure, and genuinely new analytic information. It is not determined solely by denominator count.

6.1 Coupled eight-master example

The example labeled 83bb contains eight masters and a genuinely coupled two-master top block. Its local boundary analysis contains the modes

x
0
,x
−ϵ
,x
−2ϵ
.

After all lower-integral data are imposed, one genuinely new top-corner period remains.

Determining it requires a nonfactorized corner integration with explicit control of:

endpoint scaling;

physical branches;

the coupling of the top masters;

matching to the lower sectors.

This is the most difficult of the three completed examples.

6.2 Doubled-cut example with a repeated Jordan block

The example labeled f228 contains four masters and a doubled physical cut. Its boundary residue has a repeated Jordan block.

One η-regulated two-region boundary integration determines two independent nonuniform asymptotic coefficients.

Therefore,

1 boundary integration

⇒1 scalar boundary coefficient.
	​


One explicit integral can provide several pieces of boundary information.

6.3 Factorized example with a reused period

The example labeled d099 contains five masters and factorizes into smaller blocks.

Its normalized hard top-boundary period is the same period already required by the coupled eight-master example. Once that period is known, d099:

still requires its own differential transport;

still requires lower-integral bookkeeping;

introduces no additional hard period.

Therefore,

1 new differential system

⇒1 new analytic period.
	​


Together, the three examples demonstrate that the following quantities must remain distinct:

number of masters;

number of maximal denominator classes;

number of closed differential systems;

number of scalar boundary coefficients;

number of explicit boundary integrations;

number of genuinely new periods.

7. Physical crossing and branch qualification

The denominator classification identifies geometric relations. A hard-leg crossing can move the invariants between different physical chambers.

Consequently, two crossing-related denominator classes may have the same geometric form while their physical values differ by analytic continuation.

Before identifying their boundary data, one must specify:

the starting and final kinematic chambers;

the causal i0 prescription;

the path of analytic continuation;

the branches of logarithms, powers, polylogarithms, or more general functions;

the cut orientation.

Thus the count 17 is exact for the declared geometric quotient. If crossing-related physical chambers are kept distinct until their branch maps are proven, the number of separately tabulated physical expressions may be larger. This does not alter the denominator-class count.

8. Recommended SubTropica agent workflow

Each analytic boundary task assigned to an agent should contain:

the exact normalized cut integral to be evaluated;

the boundary point or corner;

the direction of approach;

the required Laurent order in ϵ;

the physical kinematic chamber;

the causal and branch conventions;

the local scaling modes predicted by the differential equation;

all lower-integral data already known;

the scalar boundary coefficients that the integration must determine;

an independent numerical check point and required precision.

The required output is an exact analytic Laurent expansion. A numerical value alone is not a completed task.

SubTropica is used when it produces the analytic integral. AMFlow provides an independent numerical check and does not replace the analytic result.

NLO queue

The exact NLO queue is:

Job	Analytic input	Required result	Status
0	Elementary cut-bubble density	B(ϵ)=
1−2ϵ
2π
	​

	Elementary; may be preloaded
1	Generic top endpoint	T(0,ϵ)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

	The only genuinely nontrivial NLO boundary task

There are no additional jobs for the five physical top instances. They are obtained by kinematic substitution into the same generic function.

9. Conclusions

The NLO calculation establishes three distinct exact facts:

N
master
NLO
	​

=6,
N
maximal denominator
NLO
	​

=2,

and

N
analytic input
NLO
	​

=2.

When the elementary bubble is supplied as known,

N
nontrivial boundary job
NLO
	​

=1.

The operational conclusion is

\boxed{ 6\ \text{masters require 2 analytic inputs in total: one elementary bubble and one generic top endpoint. }

Equivalently,

with the bubble preloaded, NLO requires exactly one genuinely nontrivial SubTropica boundary integration.
	​


All five physical top masters follow from the same generic top function by kinematic substitution.

For NNLO double real, the exact result currently established is

342 masters⟶130 powered classes⟶82 positive-denominator classes⟶17 maximal nontrivial denominator classes.
	​


The number of distinct NNLO boundary integrations is not yet established. It requires:

exact differential-equation closure;

local Frobenius or Levelt analysis;

physical boundary constraints;

identification of equivalent parametric densities;

comparison of normalized boundary periods.

Accordingly, the number 17 must remain a geometric denominator-class count and must not yet be used as the size of the NNLO SubTropica agent queue.