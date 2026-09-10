# FORM BMHV algebra

Verified outgoing gpt-6-pro, standard effort, HTTP200. Request45138d18-c757-491b-b764-2990f487e0d3.

## Question

Continue the integrated electromagnetic SIDIS NNLO UU/LL first-principles campaign. Latest: complete NLO benchmark inventory; native measured cut validation replaced by explicit L(L+E) IBPs into Kira config:false, following your review. UU q gamma* -> q g g scalar algebra now uses FORM 5.0.1, 64 original traces, about20s per current projector, saved both2F1 and FL/x in56s. Previously FeynCalc open traces331s and full contractions >90s. Six elementary FORM/FeynCalc exact tensor tests and six generated NLO density/epsilon-coefficient checks pass.

Nontrivial decision: efficient BMHV LL extension of this FORM adapter. Please challenge the design before implementation, using primary FORM/FeynCalc documentation if useful. gamma5 is currently explicitly rejected by the adapter. In FeynCalc convention Tr[1]=4, fullD gamma algebra, physical external p,q 4D, integrated k1,k2 genuinelyD; current 2g1 has a 4D Levi-Civita tensor and incoming helicity density has gamma5. Joint evanescent angular average occurs AFTER the scalar contraction and keeps independent SPD/SP4 data until then. We must preserve positive epsilon coefficients, not fit finite factors to reference.

Candidate1: leave each chiral trace to FeynCalc BMHV, then FORM accelerates the tensor contraction, with an explicit physical metric P_mu_nu (P^2=P,TrP=4), fullmetric traceD, projected vectors and scalar products. Candidate2: expand gamma5=-i/4! epsilon_{abcd} barGamma^a barGamma^b barGamma^c barGamma^d (sign must match declared FeynCalc convention), let nonchiral FORM tracen handle fullD gammas, then contract physical epsilon tensors via -det(P). Beware unrestricted4D FORM index labels accidentally replacing the projector. Candidate3 if a rigorously equivalent faster established tool exists.

Questions: (a) Is gamma5 expansion plus explicitP correct for arbitrary BMHV traces, including >1gamma5 and loop momenta, with trace order/cyclicity? What epsilon and metric signs exactly match FeynCalc BMHV? (b) Give precise minimal rewrite rules/FORM representation for physicalP, mixed/fullD vector components, and pairwise4D epsilon contraction, including evanescent factors; which naive shortcuts fail? (c) Would FeynCalc intermediate symbolic traces then FORM contraction be safer and sufficiently fast? (d) What independent low-cost algebra checks at O(eps), O(eps^2) distinguish true BMHV from an anticommuting-gamma5 mistake? Please avoid arguing from agreement at eps0 only. Recommend one production path. Keep scheme-renormalization Z5 distinct from raw D-dimensional algebra.


## Pro response

Candidate 2 is mathematically correct and is my recommended production path: replace γ
5
	​

 by its physical four-dimensional definition, then use FORM’s nonchiral D-dimensional trace engine. Keep Candidate 1 as an independent FeynCalc/West comparison path for selected traces and generated densities.

The crucial requirements are that the replacement happens before FORM sees any native chiral matrix, that physical projectors survive every contraction, and that FORM’s native Levi-Civita convention is not silently identified with FeynCalc’s. A further normalization trap is that FeynCalc and FORM assign different factors of two to their numbered chiral projectors.

1. Fix the algebra and signs at the adapter boundary

Use

D=4−2ϵ,g
phys
	​

=diag(1,−1,−1,−1),ε
0123
=+1,tr1=4.

Distinguish the physical projector P
μ
ν
	​

 from the full metric:

P
2
=P,trP=4,H
μ
ν
	​

=δ
μ
ν
	​

−P
μ
ν
	​

,trH=D−4.

Then

γ
ˉ
	​

μ
=P
μ
ν
	​

γ
ν
,
γ
^
	​

μ
=H
μ
ν
	​

γ
ν
.

For these conventions,

γ
5
	​

=i
γ
ˉ
	​

0
γ
ˉ
	​

1
γ
ˉ
	​

2
γ
ˉ
	​

3
=−
4!
i
	​

ε
abcd
	​

γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d
.
	​


The minus sign is correct: ε
0123
	​

=−1 in the stated metric.

The corresponding trace is

tr(γ
μ
γ
ν
γ
ρ
γ
σ
γ
5
	​

)=−4iε
μνρσ
,
	​


where the epsilon tensor projects all four indices into the physical subspace. This matches FeynCalc’s documented default $LeviCivitaSign = -1. Bind that convention explicitly in the adapter’s tests rather than relying on an inherited session setting. 
FeynCalc

The defining BMHV relations are

{γ
5
	​

,
γ
ˉ
	​

μ
}=0,[γ
5
	​

,
γ
^
	​

μ
]=0,γ
5
2
	​

=1.
	​


In particular,

{γ
5
	​

,γ
μ
}=2
γ
^
	​

μ
γ
5
	​

,

not zero. FeynCalc’s BMHV implementation distinguishes the D, 4, and D−4 spaces and evaluates arbitrary chiral traces within that algebra. 
FeynCalc

Multiple γ
5
	​

 insertions and cyclicity

Expanding every occurrence in its original position, with fresh dummy indices for each occurrence, is valid for arbitrary finite traces, including traces with loop momenta and multiple γ
5
	​

’s. It reduces the problem to ordinary D-dimensional Clifford algebra plus physical tensor identities.

Trace cyclicity remains valid. What is invalid is moving γ
5
	​

 through a general D-dimensional string using an anticommuting rule.

There is an exact optimization for multiple insertions. Define

R
μ
ν
	​

=H
μ
ν
	​

−P
μ
ν
	​

=δ
μ
ν
	​

−2P
μ
ν
	​

.

Then

γ
5
	​

γ
μ
γ
5
	​

=R
μ
ν
	​

γ
ν
.
	​


Conjugation is multiplicative:

γ
5
	​

(Γ
1
	​

⋯Γ
n
	​

)γ
5
	​

=(γ
5
	​

Γ
1
	​

γ
5
	​

)⋯(γ
5
	​

Γ
n
	​

γ
5
	​

).

Thus pairs of γ
5
	​

’s can be removed by reflecting the intervening gamma arguments, leaving at most one explicit epsilon insertion per trace. This is a BMHV identity, not an NDR shortcut.

For the initial implementation, expansion of all insertions is the simpler correctness baseline. Add reflection-based pair elimination only when multiple-insertion traces create measurable growth.

Never let native FORM chiral matrices enter this path

FORM documents that g5_ anticommutes with the other gamma matrices; tracen rejects native γ
5
	​

,γ
6
	​

,γ
7
	​

, while trace4 employs four-dimensional identities. None provides your BMHV continuation automatically. 
Nikhef
+1

Therefore, lower the chiral objects in your exporter or in an inert intermediate representation before constructing FORM’s native gamma string. Replacing g5_ immediately before tracen is too late if an earlier normalization has already used its anticommutation rules.

Also expand chiral projectors explicitly:

FeynCalc DiracGamma[6,7]=
2
1±γ
5
	​

	​

,

whereas FORM’s g6_, g7_ represent 1±γ
5
	​

. Directly translating the numbered objects loses a factor 1/2 per projector. 
FeynCalc
+1

2. Minimal tensor representation
2.1 Use one ambient index space and explicit subspace tensors

A suitable FORM declaration layer is conceptually:

form
Symbols D;
Dimension D;
Indices mu,nu,rho,sigma,a,b,c,d;
Vectors p,q,k1,k2;
Tensors P4(symmetric), E4(antisymmetric);
UnitTrace 4;

This is the declaration layer, not a complete contraction program. Its intended meanings are:

d_ is the ambient contraction tensor, interpreted consistently with your Lorentz scalar products.

P4 is a user-defined physical projector.

E4 is a user-defined physical Minkowski epsilon tensor.

Every generated Lorentz dummy index has ambient dimension D.

tracen handles only ordinary gamma matrices.

FORM permits user-defined symmetric and antisymmetric tensors. Its default index dimension is four unless changed, so the Dimension D declaration must precede index creation; generated dummy indices also depend on that setting. 
Nikhef
+1

Do not change an index’s dimension to four as a substitute for inserting P. In particular, “the epsilon indices are declared four-dimensional” does not by itself define their contractions with full-D indices and vectors.

Also, P is not the Gram projector onto span{p,q}. The latter has rank two. The physical four-dimensional subspace includes the two physical transverse directions whose orientation your later joint average must retain.

2.2 The necessary rewrite identities

The tensor layer needs the following exact contractions:

gP=P,P
2
=P,P
μ
μ
	​

=4,
gH=H,H
2
=H,PH=HP=0,H
μ
μ
	​

=D−4.
	​

	​


You need not store H independently; H=g−P is sufficient.

For vector components,

v
ˉ
μ
=P
μ
ν
	​

v
ν
,
v
^
μ
=H
μ
ν
	​

v
ν
.

Define

S
D
	​

(v,w)=v⋅w,S
4
	​

(v,w)=v⋅Pw.

Then

v
ˉ
⋅w
v
^
⋅w
v
ˉ
⋅
w
^
	​

=
v
ˉ
⋅
w
ˉ
=S
4
	​

(v,w),
=
v
^
⋅
w
^
=S
D
	​

(v,w)−S
4
	​

(v,w),
=0.
	​

	​


A minimal serialization map is:

FeynCalc object	Algebraic representation
GAD[mu]	γ
μ

GA[mu]	P
μ
α
	​

γ
α

GSD[k]	\slashedk
D
	​


GS[k]	\slashed
k
ˉ
, or P(k,α)γ
α

Full-dimensional metric	g
μν

Four-dimensional metric	P
μν

SPD[k,l]	S
D
	​

(k,l)
SP[k,l]	S
4
	​

(k,l)
Four-dimensional epsilon	E
4
	​

, with the rules below

Mixed-dimensional Pair objects must be interpreted before export. Their dimensional labels are semantic data, not formatting: FeynCalc explicitly resolves mixed pairings according to BMHV. 
FeynCalc

For the declared physical p,q,

Pp=p,Pq=q.

For integrated k
1
	​

,k
2
	​

, do not apply those rules. For instance,

k
D
2
	​

=0⟹
k
ˉ
2
=−
k
^
2
,

not 
k
ˉ
2
=0.

Projected vector aliases can improve speed, provided their complete mixed scalar-product table is generated centrally. Declaring an alias kbar as an ordinary FORM vector without those relations is not enough.

2.3 Physical epsilon contraction

Require

P
μ
α
	​

E
4
ανρσ
	​

=E
4
μνρσ
	​

,H
μ
α
	​

E
4
ανρσ
	​

=0.
	​


The general pair contraction is

E
4
μ
1
	​

μ
2
	​

μ
3
	​

μ
4
	​

	​

E
4,ν
1
	​

ν
2
	​

ν
3
	​

ν
4
	​

	​

=−
π∈S
4
	​

∑
	​

sgn(π)
i=1
∏
4
	​

P
μ
i
	​

ν
π(i)
	​

	​

.
	​


Useful reduced forms are

E
4
μνρσ
	​

E
4,ανρσ
	​

E
4
μνρσ
	​

E
4,αβρσ
	​

E
4
μνρσ
	​

E
4,μνρσ
	​

	​

=−6P
μ
α
	​

,
=−2(P
μ
α
	​

P
ν
β
	​

−P
μ
β
	​

P
ν
α
	​

),
=−24.
	​

	​


Equivalently, for vector arguments,

E
4
	​

(v
1
	​

,v
2
	​

,v
3
	​

,v
4
	​

)E
4
	​

(w
1
	​

,w
2
	​

,w
3
	​

,w
4
	​

)=−det[S
4
	​

(v
i
	​

,w
j
	​

)].
	​


Replacing P by g
D
	​

 in these expressions changes the regulator prescription. For example, the fully contracted result would incorrectly become

−D(D−1)(D−2)(D−3)=−24+100ϵ−140ϵ
2
+⋯.

It passes at ϵ
0
 and fails immediately afterward.

Do not identify E4 with native FORM e_ without a complete convention conversion. FORM’s trace/epsilon conventions differ from the usual Minkowski convention, including the associated phase and determinant convention. Using your own epsilon tensor avoids importing those assumptions. 
Nikhef

If a single epsilon remains, preserve it as a physical tensor. Four-dimensional Schouten identities may simplify it, but they apply only inside the projected subspace. They must not be used on arbitrary full-D vectors.

2.4 How to lower γ
5
	​


The fully explicit replacement is

−
24
i
	​

E
4,abcd
	​

P
a
α
	​

P
b
β
	​

P
c
γ
	​

P
d
δ
	​

γ
α
γ
β
γ
γ
γ
δ
.

Once the physical-slot property of E4 is implemented, the four displayed projectors are redundant:

γ
5
	​

⟼−
24
i
	​

E
4,abcd
	​

γ
a
γ
b
γ
c
γ
d
.
	​


Here the indices remain ambient-D labels; the epsilon tensor, not their declarations, supplies the physical projection.

There is no need to expand this into 24 separately permuted gamma words. The antisymmetric tensor and its summed indices already implement that antisymmetrization.

3. Preserve order, then simplify without expanding unnecessarily

A suitable production sequence is

ordered FeynCalc gamma words and typed tensors
↓
explicit chiral-projector factors and BMHV lowering
↓
ordinary FORM gamma strings and tracen
↓
physical-projector/epsilon contractions
↓
scalar polynomial in S
D
	​

,S
4
	​

↓
S
4
	​

=S
D
	​

−H and joint evanescent averaging.
	​

	​


Several efficiency choices are algebraically safe.

Contract projectors and eliminate zero physical–evanescent contractions early. This reduces tensor rank without setting integrated vectors physical.

For g
1
	​

, consider contracting the epsilon introduced by γ
5
	​

 with the current-projector epsilon before the longest trace expansion. The result is a determinant of physical projectors. Whether this or tracing first is cheaper depends on the gamma-word contractions; both are exact. Contract partially shared epsilon indices before expanding a general 24-term determinant.

Canonicalize and cache repeated trace words. Cyclic shifts are safe for a closed trace. Preserve dimensional tags, spin-line identity, epsilon parity, and the sign of dummy-index permutations. Do not use unrestricted word reversal or anticommuting-γ
5
	​

 equivalences as cache identities.

Retain scalar coefficients and denominator factors outside trace expansion. The trace engine should not repeatedly expand identical kinematic prefactors.

Guard the result. A completed scalar contraction should contain no gamma matrices, uncontracted Lorentz indices, or native FORM chiral objects. For the requested scalar LL observables, verify the expected epsilon-tensor closure; do not discard unexpected tensors merely to reach the scalar interface.

Your later joint angular average is the correct place to replace the correlated hatted scalar products. Performing a one-vector average during individual trace evaluation would lose correlations between different traces or tensor factors.

Conjugation must remain a separate operation

With the stated Minkowski convention, E
4
	​

 is real, i changes sign under complex conjugation, and γ
5
†
	​

=γ
5
	​

. But Dirac conjugation satisfies

γ
0
γ
5
†
	​

γ
0
=−γ
5
	​

.

Thus complex conjugation of a scalar epsilon factor is not a substitute for conjugating a spinor chain.

Preserve the existing amplitude-conjugation and current-index convention before exporting the contracted interference. Do not add an extra gamma-five sign because FORM’s native convention describes conjugation differently.

4. Candidate 1 is valid, but its speed is not established

FeynCalc already supplies an independent established algorithm: its BMHV odd-γ
5
	​

 traces use West’s formula by default. 
FeynCalc

Therefore the hybrid

FeynCalc BMHV trace⟶typed FORM tensor contraction

is mathematically sound. Evaluate only the chiral trace objects in FeynCalc and leave the surrounding current/polarization tensor contraction to FORM. Preserve every 4, D, and D−4 Pair in the export.

It is safer specifically against implementing the chiral-trace algorithm incorrectly. It is not automatically safe against mistakes in the shared projector serializer or epsilon contraction layer.

Nor is “sufficiently fast” established by the current timings. Your previous open-trace stage was already expensive; replacing only subsequent contractions may leave most of that cost intact. Conversely, expanding one γ
5
	​

 adds four ordinary matrices and can increase FORM trace size. The UU timings do not determine the LL timings in either direction.

I would not introduce a third trace package or port a second optimized chiral recursion now. Use Candidate 2 as the production algebra and Candidate 1 as a selected-trace oracle. Benchmark the complete projected scalar on a representative generated LL RR contribution—not merely the isolated nonchiral trace—to assess the actual expansion cost.

5. Regulator-sensitive checks with explicit expected answers

These tests distinguish BMHV from an anticommuting-γ
5
	​

 calculation. They should be exact in D before expansion.

5.1 Basic convention and physical-projector tests

Require

tr1=4,trγ
5
2
	​

=4,trγ
5
	​

=0,
tr(γ
μ
γ
ν
γ
ρ
γ
σ
γ
5
	​

)=−4iE
4
μνρσ
	​

,

and

E
4
μνρσ
	​

E
4,μνρσ
	​

=−24.

Also test

trP=4,trH=D−4,PH=0.

These separate a trace-normalization error, an epsilon-phase error, and an erroneous full-D epsilon contraction.

5.2 One-γ
5
	​

 test close to the LL production structure

Directly from BMHV,

γ
μ
	​

γ
5
	​

γ
μ
=(D−8)γ
5
	​

.
	​


Let

T
4
abcd
	​

=tr(
γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d
γ
5
	​

)=−4iE
4
abcd
	​

.

Cyclicity then gives

tr[γ
μ
γ
ˉ
	​

a
γ
ˉ
	​

b
γ
ˉ
	​

c
γ
ˉ
	​

d
γ
μ
	​

γ
5
	​

]=(D−8)T
4
abcd
	​

.
	​


An anticommuting prescription would give −DT
4
abcd
	​

. The two agree at D=4 but differ at O(ϵ).

This tests the single-γ
5
	​

 path, not just your multiple-insertion optimization.

5.3 Two-γ
5
	​

 trace

The exact result is

tr(γ
5
	​

γ
μ
γ
5
	​

γ
μ
	​

)=4(D−8)=−16−8ϵ.
	​


The anticommuting result would be

−4D=−16+8ϵ.

A longer useful contraction is

tr(γ
5
	​

γ
μ
γ
ν
γ
5
	​

γ
μ
	​

γ
ν
	​

)=4[2D−(D−8)
2
]=−32−80ϵ−16ϵ
2
.
	​


This tests nonadjacent insertions and correlated index contraction.

5.4 A test whose first nonzero answer is O(ϵ
2
)

Define the Dirac object

X=γ
μ
	​

γ
5
	​

γ
μ
+Dγ
5
	​

.

BMHV gives

X=2(D−4)γ
5
	​

,

hence

tr(X
2
)=16(D−4)
2
=64ϵ
2
.
	​


An anticommuting implementation gives zero identically.

This is an especially useful regression: checking only the constant and linear epsilon coefficients would miss the error.

5.5 Integrated-vector test before and after angular averaging

For genuinely D-dimensional vectors k,l,

tr(γ
5
	​

\slashedk
D
	​

γ
5
	​

\slashedl
D
	​

)=4[S
D
	​

(k,l)−2S
4
	​

(k,l)].
	​


For k=l and k
D
2
	​

=0,

tr(γ
5
	​

\slashedk
D
	​

γ
5
	​

\slashedk
D
	​

)=8
k
^
2
.
	​


It is not zero.

Applying your already verified one-vector average with a rank-two physical external span gives

8⟨
k
^
2
⟩=−8
1−ϵ
ϵ
	​

k
⊥
2
	​

=−8(ϵ+ϵ
2
)k
⊥
2
	​

+O(ϵ
3
).

This simultaneously tests the distinction between SPD and SP4, the scalar contraction, and its interface to angular averaging. Use the generic k,l version as well so that a diagonal-only scalar-product bug does not pass.

5.6 An independent matrix oracle

For a small number of representative words, use explicit Clifford matrices in D=6 and D=8, with

γ
5
	​

=iγ
0
γ
1
γ
2
γ
3

built only from the four physical directions. Normalize the ordinary matrix trace by

tr
4
	​

(A)=
2
D/2
4
	​

Tr
matrix
	​

(A).
	​


Choose vectors with nonzero components outside the physical four-space.

This gives an inexpensive check independent of both FORM’s symbolic trace implementation and FeynCalc’s West recursion. Integer-dimensional evaluations are not a proof of the full symbolic identity, but they complement the exact D-dependent tests above. I checked the contracted identities in §§5.2–5.4 with normalized explicit Clifford matrices in D=4,6,8; they give the stated results.

For generated comparisons, compare raw scalar expressions before angular averaging, and then the averaged expressions through the required positive-epsilon window. A finite coefficient agreement alone cannot identify where an evanescent error canceled accidentally.

6. Recommended production boundary

Implement one shared physical-tensor layer used by both candidate routes, with the following division:

FeynCalc: generated amplitudes, conjugation, typed input;
adapter: BMHV lowering and explicit P,E
4
	​

 semantics;
FORM: ordinary D-dimensional traces and tensor contraction;
existing framework: joint angular average, IBP, integration, schemes.
	​

	​


Start with the single-γ
5
	​

 lowering needed for the quark LL current and the zero-γ
5
	​

, two-epsilon case relevant to a polarized incoming gluon. Implement multiple insertions correctly through the same definition; optimize their elimination only afterward. Keep all dependence on D exact through the scalar contraction.

Finally, no Z
5
	​

 belongs in this algebra adapter. The electromagnetic vertex remains a vector current. The finite polarized-PDF scheme transformation and any genuinely required operator renormalization act later on the corresponding operator/coefficient system; they do not alter the BMHV trace definition. FeynCalc likewise distinguishes its algebraic BMHV treatment from user-supplied finite counterterms. 
FeynCalc

The production acceptance criterion is therefore not agreement at ϵ
0
, but agreement of the exact projected Clifford algebra—including the 64ϵ
2
 and integrated-vector tests—before any scheme transformation or hard-function comparison.