# Response Before CF48 Tool

## Question

_The question was not preserved in the local bridge record._

## Pro response

Your proposed direction is mathematically sound, but one correction is essential:

B
val
	​

=kerQ(τ
0
	​

)
	​


is necessary and sufficient only when τ
0
	​

 is an ordinary point of the lifted system and the evaluated row basis has its generic rank there. At a tangential regular-singular base point, the same idea works only after pulling the constraints into the local Frobenius/Levelt coefficient space.

The broader strategy I recommend is

valuation output-null reduction⟶physical boundary embedding⟶reachable/observable minimization⟶compact Chen circuit.
	​


For CF299 and CF407, this should be tested before generating any more explicit weight-four or weight-five word lists.

1. Pre-transport valuation constraints

Let the finite lifted state collect every canonical Laurent coefficient that can contribute either to a forbidden physical coefficient or to a demanded final coefficient:

X(τ)=
	​

F
n
min
	​

	​

(τ)
F
n
min
	​

+1
	​

(τ)
⋮
F
n
max
	​

	​

(τ)
	​

	​

,
dτ
dX
	​

=A(τ)X.
(1)

For a pure family ϵ-form, A is the usual block-shift lift of the dlog connection.

Let

Y
<
	​

(τ)=L
<
	​

(τ)X(τ)
(2)

be the vector of all physical-basis Laurent coefficients known to vanish. These should include every exact family valuation you trust, not only the demanded output rows.

Define the dual derivative

∇
∨
q=
dτ
dq
	​

+qA.
(3)

Starting from

Q
0
	​

=rowspan
K(τ)
	​

L
<
	​

,

iterate

Q
r+1
	​

=rowspan
K(τ)
	​

(Q
r
	​

∪∇
∨
Q
r
	​

).
(4)

Stop only when both

dimQ
r+1
	​

=dimQ
r
	​


and the exact membership condition

∇
∨
Q
r
	​

⊆Q
r
	​

(5)

have been proved.

Since the lifted state is finite dimensional, the row rank can increase only finitely many times. Define

N
val
	​

=Ann(Q)={x∣qx=0 for every q∈Q}.
(6)

At an ordinary point τ
0
	​

, away from every denominator and exceptional-rank divisor,

B
val
	​

=N
val
	​

(τ
0
	​

)=kerQ(τ
0
	​

).
	​

(7)

This is both necessary and sufficient:

if X(τ
0
	​

)∈B
val
	​

, then Y
<
	​

 and all of its derivatives vanish at τ
0
	​

;

closure under Eq. (5) implies that they continue to vanish;

analyticity and uniqueness then give

L
<
	​

(τ)X(τ)≡0

throughout the connected nonsingular path chamber;

conversely, any solution satisfying the valuation constraints identically belongs to every kernel in Eq. (6).

This is the exact linear-time-varying analogue of an unobservable/output-nulling subspace.

Conditions that must be added

The construction is valid only if:

the lifted Laurent window is complete:
no omitted F
n
	​

 can contribute through a negative power in T
total
	​

;

every forbidden coefficient is genuinely known to vanish analytically;

row-space calculations are over the exact coefficient field;

exceptional divisors where rank changes are retained;

an ordinary point is not chosen on a letter, transformation pole, or apparent-rank locus.

For nonzero prescribed coefficients rather than zero constraints, augment the state by a constant component:

X
=(
X
1
	​

),
X
′
=(
A
0
	​

0
0
	​

)
X
,

so that affine equations become homogeneous row constraints.

2. Singular and tangential base points

At a regular-singular boundary s=0, one must not evaluate Q(s) naively at s=0.

Let the local physical fundamental solution be

Φ
bnd
	​

(s)=H(s)s
J
,H(0)=1,
(8)

where s
J
 includes the required fractional powers and Jordan logarithms on the declared physical branch. For a normal crossing, this is replaced by the corresponding product of local factors.

The tangential boundary state is the coefficient vector c in

X(s)=Φ
bnd
	​

(s)c.
(9)

Pull the output-null module into this coefficient space:

Q
	​

bnd
	​

(s)=Q(s)Φ
bnd
	​

(s).
(10)

Expand it in generalized Frobenius monomials,

Q
	​

bnd
	​

(s)=
λ,k,n
∑
	​

s
λ+n
(logs)
k
Q
λ,k,n
	​

.
(11)

Then the allowed tangential data are

B
val
tan
	​

=
λ,k,n
⋂
	​

kerQ
λ,k,n
	​

.
	​

(12)

In practice, accumulate coefficient rows until their exact rank stabilizes. This includes:

distinct ϵ-dependent exponents;

Jordan/logarithmic partners;

all powers required by the lifted Laurent window;

the selected tangential direction and branch.

A simpler implementation is to use the exact local series to move from the tangential base point to one nearby ordinary anchor s
∗
	​

, then apply Eq. (7) there. Libra is explicitly designed to construct generalized local series and to determine the asymptotic coefficients needed for boundary matching, but it does not determine the physical period coefficients themselves. 
arXiv

Thus the answer to question 1 is:

Yes at an ordinary point; at a singular point, not as written.
	​


Use Eq. (12), or move exactly to an ordinary anchor first.

3. What this is called in the literature

There are three equivalent viewpoints.

Control-theory language

Your Q is the differential observability or output-null closure. Its annihilator is the unobservable/output-nulling state subspace of a linear time-varying system.

After introducing an allowed boundary embedding B and demanded output map D, the further reduction is a time-varying version of:

reachability;

observability;

Kalman decomposition;

minimal realization.

Differential-module language

The connection defines a differential module over K(τ). The valuation constraints define a differential submodule in the dual module. Its annihilator is an invariant differential submodule of the state module. The observable physical system is a subquotient.

Chen-series or automata language

For a canonical dlog system with constant residues,

dF=ϵ
a
∑
	​

R
a
	​

dlogϕ
a
	​

F,

the coefficient associated with a word w=a
1
	​

⋯a
k
	​

 in the physical output is

c(w)=DR
a
1
	​

	​

⋯R
a
k
	​

	​

B.
	​

(13)

This is a recognizable noncommutative formal series, equivalently a weighted finite automaton with linear representation

(D,{R
a
	​

},B).

Its minimal state dimension is obtained by the usual reachable/observable reduction. Over a field, a linear representation is minimal precisely when its left and right closures are both full; this is standard weighted-automata/minimal-realization theory. 
arXiv
+1

This is especially relevant to your proposed Chen matrix circuit. You are not inventing an ad hoc compression: DUB is a standard finite-state realization of a noncommutative series.

Available symbolic software

There is no established Feynman-integral package that takes your lifted family system and performs this complete reduction automatically.

The closest general symbolic tools are:

OreModules for systems over Ore algebras; it provides elimination, quotients, ranks, minimal parametrizations, and related module operations;

OreMorphisms for kernels, images, cokernels, idempotents, decompositions, and reductions of linear functional systems. 
Rocq
+2
Rocq
+2

OreSys for exact uncoupling of one-variable Ore systems into scalar equations. 
RISC

OreModules/OreMorphisms are public Maple packages, but they are older research software and may be more cumbersome than the direct exact linear algebra needed for dimensions of order 100.

For the constant-residue Chen realization, the reachable/observable minimization is sufficiently simple that a local exact implementation is preferable:

R=span{R
w
	​

B∣w∈A
∗
},
(14)
O=span{DR
w
	​

∣w∈A
∗
}.
(15)

The minimal state is the reachable space modulo its unobservable part.

Use modular arithmetic to discover ranks and pivots, then reconstruct and certify over the exact field.

4. Exact construction of the physical boundary embedding

The boundary embedding must be built independently of the global transported answer.

At each relevant stratum:

Step 1: derive the local mode basis

Construct

X
hom
	​

(s)=Φ
bnd
	​

(s)c,
(16)

with all:

Frobenius powers;

Jordan logarithms;

cut and branch information;

tangential directions;

basis transformations back to the physical masters.

Step 2: include lower-sector particular solutions

For a block-triangular family, write

X(s)=X
part
	​

(s)+Φ
bnd
	​

(s)c.
(17)

The particular term is determined from already solved lower sectors. It introduces no new homogeneous constant.

Step 3: assemble exact boundary constraints

Use:

exact lower-sector inheritance maps;

powered-integral equivalences;

phase-space-volume anchors;

regularity conditions that are analytically proved;

mode absences proved by regions or contour arguments;

genuinely new periods where the residual nullity demands them.

This gives

C(ϵ)c=d(ϵ).
(18)

Parameterize the solution as

c=c
∗
	​

+Np,
(19)

where p is the minimal vector of unresolved physical periods.

Step 4: move to the transport base point

At a regular anchor τ
0
	​

,

X(τ
0
	​

)=X
∗
	​

(τ
0
	​

)+E(τ
0
	​

)Np.
(20)

The physical boundary embedding can therefore be stored as

B
phys
	​

=[X
∗
	​

(τ
0
	​

) ∣ E(τ
0
	​

)N].
(21)

The first column is an affine particular solution and the remaining columns multiply unresolved period symbols. Alternatively augment the state by 1.

Finally require the exact consistency check

Q(τ
0
	​

)B
phys
	​

=0.
(22)

No circularity is involved:

the local modes come from the local DE;

their coefficients come from cut kinematics, lower sectors, and boundary periods;

only afterward is the global transport applied.

5. Compact Chen evolution is an exact analytic answer

Yes:

H(τ)=D(τ)U(τ,τ
0
	​

)B,U=Pexp∫
τ
0
	​

τ
	​

A,
	​

(23)

is an exact analytic result, provided the record contains:

the exact finite ϵ-depth;

the residue matrices and letters;

the integration path and chamber;

tangential base-point prescription;

algebraic-letter branches;

exact boundary periods and normalization;

the physical output map D.

Modern multiloop calculations explicitly regard canonical differential equations plus analytic boundary data as fully specifying the master integrals in terms of Chen iterated integrals. 
arXiv

Individual GPL/HPL words do not have to be enumerated.

At finite weight, the circuit can be a straight-line program whose nodes are:

residue-matrix multiplication;

dlog integration;

block source insertion;

exact addition;

boundary projection.

It supports exact differentiation recursively.

Endpoint expansion without full enumeration

Near an endpoint s=0, write

U(τ,τ
0
	​

)=H
end
	​

(s)s
ϵR
end
	​

C
end←0
	​

,
(24)

where C
end←0
	​

 is the regularized connection matrix from the transport base to the endpoint basis.

That connection matrix can remain a Chen circuit. The physical endpoint modes are extracted from

DH
end
	​

(s)s
ϵR
end
	​

C
end←0
	​

B.
(25)

Thus one can:

diagonalize or Jordan-decompose R
end
	​

;

retain the factors

s
m+aϵ
(logs)
k

unexpanded;

compute only the projected regular coefficients needed for the hard function;

convert those modes to delta and plus distributions.

Full word expansion is needed only when:

a manuscript requires explicit GPL formulas;

one wants a conventional function-basis representation;

a selected endpoint constant must be reduced to known constants.

One-fold exact integral representations over lower-weight functions are also standard in difficult multiloop problems, particularly when explicit high-weight expansion is unattractive. 
arXiv
+1

6. CF299 and the Gauss block

The known Gauss 
2
	​

F
1
	​

 diagonal block should be used as an exact primitive node, but it does not by itself imply that the six demanded physical combinations satisfy low-order scalar equations.

Your measured fact

dimspan{D, DR
a
	​

, DR
a
	​

R
b
	​

,…}=22

means that, before imposing valuation and boundary restrictions, the demanded outputs observe the entire family.

A scalar Picard–Fuchs equation obtained at that stage will generically have order close to 22, which is likely worse than the canonical system.

Decisive test

First perform the valuation and boundary reduction. Let the resulting minimal candidate system have matrices

A
ˉ
(τ),
D
ˉ
,
B
ˉ
.

For each demanded scalar output h=
d
ˉ
X, generate cyclic rows

q
0
	​

=
d
ˉ
,q
k+1
	​

=q
k
′
	​

+q
k
	​

A
ˉ
.
(26)

Stop at the first exact dependence

q
m
	​

=
j=0
∑
m−1
	​

a
j
	​

q
j
	​

.
(27)

This gives

[∂
τ
m
	​

−
j=0
∑
m−1
	​

a
j
	​

(τ)∂
τ
j
	​

]h=0.
(28)

Use OreSys or ore_algebra to normalize and factor the operator. Algorithms for deriving and minimizing Picard–Fuchs operators are well established, including for Feynman periods. 
arXiv
+1

Adopt the scalar route only if:

the minimal order is small, roughly m≲4–6;

the reconstruction of demanded outputs is compact;

the operator factors into first-order or recognized Gauss/hypergeometric factors;

the inhomogeneous/lower-block data remain manageable.

If the order remains near 22, retain the matrix circuit.

The Gauss block can still be solved exactly and inserted as a known source in the blockwise circuit, reducing repeated word expansion inside that block.

7. Can a constant ϵ-dependent gauge remove the ϵ
−3
 depth?

Let

dF=ϵ
a
∑
	​

R
a
	​

dlogϕ
a
	​

F.

Consider a kinematics-independent gauge

F=G(ϵ)
F
.

The transformed residues are

R
a
	​

(ϵ)=G(ϵ)
−1
R
a
	​

G(ϵ).
(29)

Suppose these are required to be independent of ϵ. Choose one generic ϵ
0
	​

. Then

H(ϵ)=G(ϵ)G(ϵ
0
	​

)
−1

satisfies

[H(ϵ),R
a
	​

]=0for every a.
(30)

Therefore all permissible ϵ-dependent freedom lies in the common centralizer

Z(R)={H∣[H,R
a
	​

]=0 ∀a}.
(31)

Consequences:

Scalar centralizer

If

dimZ(R)=1,

then

G(ϵ)=g(ϵ)G
0
	​

.

Only an overall scalar rescaling is possible. It cannot change relative ϵ-depths among master directions.

Nontrivial centralizer

If the residue representation has invariant components or repeated isomorphic submodules, the centralizer may contain projectors. One can then use shears such as

G(ϵ)=
α
∑
	​

ϵ
m
α
	​

P
α
	​

.
(32)

These can redistribute ϵ-valuation among invariant sectors.

However,

T
total
	​

→T
total
	​

G,B→G
−1
B,

and therefore

DUB

is unchanged. A pole removed from T
total
	​

 generally reappears in the boundary embedding or in the required canonical Laurent window.

Thus the centralizer test settles whether relative depth can be redistributed, but it does not imply that the intrinsic transport depth disappears.

Run the centralizer test after valuation/minimal-realization reduction. A gauge may be useful if the physical boundary has no support on the directions whose depth worsens.

The correct optimization target is the total transfer problem

(D,{R
a
	​

},B),

not the pole order of T
total
	​

 alone.

8. Recommended route for CF299
Primary route

Build the exact finite lifted system only over the genuinely required Laurent window.

Compute the dual valuation closure Q.

At a regular anchor—or in local Frobenius coefficient space—obtain

B
val
	​

.

Construct the physical boundary embedding

B
phys
	​

=B
∗
	​

+Np.

Intersect it with B
val
	​

.

Compute the right residue closure generated by the surviving boundary columns.

Quotient by the subspace invisible to the six demanded rows.

Store and transport the resulting minimal Chen circuit.

Treat the Gauss block as an exact special-function node.

Run the scalar-order test of Eq. (26) only on the reduced system.

Likely outcome

The original demanded-row closure being full does not rule out a substantial reduction after valuation and physical-boundary restriction. If the minimal dimension remains near 22, stop attempting explicit word enumeration and retain the circuit.

9. Recommended route for CF407

Use the same first seven steps.

Because the alphabet has 12 letters and even a single seed generates a large word count, CF407 is the stronger case for retaining the exact circuit.

Run scalarization only if the post-valuation reachable/observable dimension falls sharply. Otherwise a scalar operator will likely be high order and algebraically larger than the original system.

For both CF299 and CF407, the compact realization is not a fallback of lower scientific status. It is the natural exact representation of the physical Chen series.

10. The decisive benchmark

Use CF299 at its terminal required order.

Record:

N
lift
	​

,dimQ,dimB
val
	​

,dimR,N
min
	​

,

where N
min
	​

 is the final reachable-observable realization dimension.

Also record:

number of physical boundary columns;

dual-closure construction time;

exact-certification time;

circuit node count;

explicit word count if expanded;

peak RSS;

terminal endpoint-projection time.

The exact certificates should be:

∇
∨
Q⊆Q,
(33)
L
<
	​

B
val
	​

=0,
(34)

and, for a constant-residue reduction with embedding P,

R
a
	​

P=P
R
ˉ
a
	​

,B=P
B
ˉ
,DP=
D
ˉ
.
(35)

For an observable quotient, retain the corresponding exact projection identities.

These imply for every Chen word w,

DR
w
	​

B=
D
ˉ
R
ˉ
w
	​

B
ˉ
.
	​

(36)

Equation (36) proves equality for all weights without enumerating them.

Finally require:

L
<
	​

(τ)U(τ,τ
0
	​

)B
val
	​

=0
(37)

as a consequence of the output-null construction, and exact agreement with the existing explicit transport through the highest already completed low weight.

Ranked conclusion

For both families:

Pre-transport valuation/output-null reduction.

Exact physical boundary embedding.

Reachable-observable minimization of the Chen realization.

Compact circuit as the default analytic representation.

Endpoint projection directly on the circuit.

Scalar Picard–Fuchs only after the minimal-order test.

ϵ-dependent gauge only if the post-reduction centralizer is nontrivial.

For CF299, exploit the Gauss block as a reusable exact subcircuit.

For CF407, expect the circuit itself to be the final efficient representation unless valuation constraints reduce the state dimension dramatically.

The proposed dual closure is therefore the correct next experiment. The main change is to formulate it as an exact output-nulling/minimal-realization problem and to stop treating explicit enumeration of every Chen word as necessary for an analytic result.
