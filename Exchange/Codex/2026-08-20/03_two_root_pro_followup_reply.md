Decisive conclusion

The new certificates change the diagnosis. Both first hard extensions are rationally split:

CF254 (9,8) and (9,7) satisfy exact two-variable Pfaffian identities.

CF231 (8,7) also satisfies all 32 exact symbolic identities; the failure through nine primes was only insufficient reconstruction modulus.

The production route should therefore remain the sharp simultaneous modular solver, but its state must be upgraded from “one gauge per strip” to an affine row state. The full augmented Maple solver is a useful independent benchmark, not the primary production engine. Cross-class Källén maps should be tested first because they could eliminate several remaining strips at once, but they should be subject to a strict, bounded isomorphism test.

My ranking is:

Rank	Route	Role
1	Sharp modular solve with affine row propagation	Production route
2	Exact cross-class Källén involution	Cheapest possible shortcut; test before more interpolation
3	Augmented Maple RationalSolutions	Independent affine-space reconstruction and fallback
4	Bounded whole-row CANONICA retry after installing the solved strips	Cheap opportunistic check
5	Targeted balance	Only after an exact local obstruction; none is presently indicated

Routes 3 and 5 in the question are not really alternatives: propagating the affine family is the correct state-management layer for the sharp modular solver.

The conclusions below are based on the current source archive, particularly CF254_AUDIT.md, CF231_STATUS.md, the lifted exact checks, and the interpolation/lifting scripts.

1. Can the chosen CF254 (9,7) representative obstruct a later strip?
Yes, in principle

Let the already completed lower subsystem be

dF
j
	​

=ϵ
k≤j
∑
	​

Ω
jk
	​

F
k
	​

,

with every Ω
jk
	​

 epsilon-independent and logarithmic. Let block i be the new upper block, with diagonal connection ϵE. A lower-triangular row transformation contains matrices

R
ij
	​

,j<i.

The complete row equation is

∂
μ
	​

R
ij
	​

−ϵ(E
μ
	​

R
ij
	​

−R
ij
	​

Ω
jj,μ
	​

)=
	​

B
ij,μ
	​

−ϵ
a
∑
	​

K
ij,a
	​

∂
μ
	​

logW
a
	​

−ϵ
k=j+1
∑
i−1
	​

R
ik
	​

Ω
kj,μ
	​

.
	​

	​

(1)

The last term is the coupling among source blocks in the same row.

For CF254 sector 9,

∇
98
	​

R
98
	​

∇
97
	​

R
97
	​

∇
96
	​

R
96
	​

	​

=B
98
	​

−ϵK
98
	​

dlogW,
=B
97
	​

−ϵK
97
	​

dlogW−ϵR
98
	​

Ω
87
	​

,
=B
96
	​

−ϵK
96
	​

dlogW−ϵR
98
	​

Ω
86
	​

−ϵR
97
	​

Ω
76
	​

.
	​

(2)

The stored (9,7) solution is one element of a 16-dimensional affine family. Write the full solution as

R
97
	​

K
97,a
	​

	​

=R
97
(0)
	​

+
α=1
∑
16
	​

λ
α
	​

H
α
	​

,
=K
97,a
(0)
	​

+
α=1
∑
16
	​

λ
α
	​

L
αa
	​

,
	​

	​

(3)

where

λ
α
	​

∈Q(ϵ)

are constant with respect to both kinematic variables. Each pair
(H
α
	​

,L
αa
	​

) satisfies the corresponding homogeneous strip identity.

The (9,6) source then changes by

−ϵ
α=1
∑
16
	​

λ
α
	​

H
α
	​

Ω
76
	​

.
(4)

There is no theorem requiring the terms in Eq. (4) to be rationally exact modulo allowed dlog residues. Therefore a particular choice such as λ
α
	​

=0 can fail to extend even though another element of the (9,7) affine family extends.

This is a standard extension-of-extensions issue: an individually valid representative need not be compatible with the next extension in the filtration.

Minimal data that must be retained

It is unnecessary to store 16 fully expanded 4×4 gauges if that is expensive. The minimal exact row state is:

(p,N,M,D,K),
	​


where:

p(ϵ) is the particular coefficient vector;

N(ϵ) is a basis of the nullspace;

M(x,y) is the rational numerator basis used for the gauge;

D(x,y,ϵ) is its denominator;

K maps the same affine parameters into the dlog residue matrices.

For CF254, the 16 normalization columns already provide a natural coordinate system for N. At each modular epsilon sample, normalize the nullspace so that those 16 residue coordinates form the identity matrix, then interpolate the particular vector and the nullspace columns consistently.

The next strip should be solved as one affine system. If

u
97
	​

=p
97
	​

+N
97
	​

λ

and the (9,6) equations have unknown coefficient vector u
96
	​

, their finite system has the form

(
A
96
	​

	​

C
96
	​

N
97
	​

	​

)(
u
96
	​

λ
	​

)=b
96
	​

−C
96
	​

p
97
	​

.
	​

(5)

Row reduction of Eq. (5) produces a new particular solution and a new nullspace. This automatically:

fixes any previous affine parameters required by (9,6);

retains only combinations that remain free;

adds new homogeneous freedom from (9,6);

avoids exponential growth of independent parameter lists.

Repeating this downward is algebraically equivalent to solving the whole row at once, but considerably smaller.

Practical recommendation

For CF254 (9,6), include the 16 (9,7) parameters immediately. Adding 16 columns is negligible compared with the roughly 10
3
-level rational ansätze already measured.

The same issue applies in principle to the earlier (9,8) affine freedom. Since the accepted (9,7) proves that the currently selected (9,8) representative extends at least one step, do not reconstruct that older affine family immediately. Reintroduce it only if the coupled (9,7)+(9,6) system is exactly inconsistent.

A useful exact diagnostic is the rank of the map

Φ
96
	​

:λ⟼[
α
∑
	​

λ
α
	​

H
α
	​

Ω
76
	​

]
(6)

in the quotient of compatible one-forms by rational exact forms and permitted dlog residues. In practice, Eq. (5) computes this rank without constructing the quotient separately.

2. Full augmented Maple RationalSolutions
The construction is valid

For an m×n gauge R, let

r=vecR,d=mn.

With the same vectorization convention used by the current scripts,

M
μ
	​

=ϵ(E
μ
	​

⊗1
n
	​

−1
m
	​

⊗C
μ
T
	​

).
(7)

After solving the residue-compatibility equations, write the compatible forcing as

f
μ
	​

=f
μ,0
	​

+
ρ=1
∑
N
	​

κ
ρ
	​

f
μ,ρ
	​

.
(8)

Here the κ
ρ
	​

 are constants with respect to x,y, but may take values in Q(ϵ).

Introduce

Y=
	​

r
h
κ
	​

	​

,h=1,

and

A
μ
aug
	​

=
	​

M
μ
	​

0
0
	​

f
μ,0
	​

0
0
	​

F
μ
	​

0
0
	​

	​

,F
μ
	​

=(
f
μ,1
	​

	​

⋯
	​

f
μ,N
	​

	​

).
	​

(9)

Then

∂
μ
	​

Y=A
μ
aug
	​

Y
(10)

is homogeneous.

For the two current 4×4 strips,

d=16,N=17,

so the augmented connection is 34×34.

Why the appended parameters cannot become kinematic functions

The final N+1 rows of each augmented connection are zero. Therefore every simultaneous rational solution satisfies

∂
x
	​

h=∂
y
	​

h=0,∂
x
	​

κ
ρ
	​

=∂
y
	​

κ
ρ
	​

=0.

The constants of the two derivations in

Q(ϵ)(x,y)

are precisely Q(ϵ). Thus the solver cannot introduce spurious x- or y-dependent residue parameters, provided it solves the complete two-variable connection, not one equation in isolation.

Maple command sequence

The official IntegrableConnections interface accepts a list of connection matrices, a list of variables, and an optional parameter declaration. Its RationalSolutions output is a matrix whose columns form a basis of rational solutions; the inhomogeneous interface can separately return a homogeneous basis and a particular solution. 
Université de Limoges
+1

A concrete construction is:

maple
restart:
with(LinearAlgebra):
with(IntegrableConnections):


# d = m*n; N = number of affine residue parameters


A1aug := Matrix(d+1+N, d+1+N, 0):
A2aug := Matrix(d+1+N, d+1+N, 0):


A1aug[1..d, 1..d]       := M1:
A2aug[1..d, 1..d]       := M2:


A1aug[1..d, d+1]        := Vector(f10):
A2aug[1..d, d+1]        := Vector(f20):


A1aug[1..d, d+2..d+1+N] := F1:
A2aug[1..d, d+2..d+1+N] := F2:


Caug := [A1aug, A2aug]:


TestIntegrabilityConditions(Caug, [x,y]):


RS := RationalSolutions(
        Caug,
        [x,y],
        ['param', [eps]]
      ):

Before invoking RationalSolutions, independently require

∂
x
	​

A
y
aug
	​

−∂
y
	​

A
x
aug
	​

+[A
x
aug
	​

,A
y
aug
	​

]=0.
(11)
Extracting the affine slice

Let S be the matrix returned by Maple. Let

η
T
=e
d+1
T
	​

S

be its h-row.

If η=0, the augmented rational solution space contains no solution with h=1.

Otherwise choose c
0
	​

 satisfying

η
T
c
0
	​

=1.

Let N
η
	​

 be a basis of

kerη
T
.

Then

Y
p
	​

=Sc
0
	​

,Y
hom
	​

=SN
η
	​

(12)

give the complete affine family

Y=Y
p
	​

+Y
hom
	​

λ.

The first d entries are the rational gauge, and the final N entries give the compatible residue parameters.

Acceptance criterion

On CF231 or CF254 (9,7), accept Maple only if:

the augmented flatness identity (11) vanishes;

a solution with h

=0 exists;

the h=1 slice has affine dimension 16;

every extracted gauge satisfies both original Pfaffian equations exactly;

its solution space agrees with the modular one up to an invertible constant change of affine coordinates.

If Maple finds a larger rational solution space, that would be scientifically useful: it would show that the sharp numerator/denominator basis omitted rational homogeneous solutions.

Method decision

Run this once on the already solved CF231 fixture. It is an exact benchmark of the package and augmented formulation. Do not block the family calculation on it. The sharp finite-field method has already solved systems on which the earlier Maple route stalled, and FiniteFlow-type modular reconstruction is specifically designed to avoid large intermediate symbolic expressions. 
arXiv

A timeout or resource failure of RationalSolutions is not a nonexistence certificate.

3. Exact Källén involution test

Let the source and target systems be written in chart variables z
S
	​

 and z
T
	​

, with chart maps

χ
S
	​

:z
S
	​

⟼(v,w),χ
T
	​

:z
T
	​

⟼(v,w).

Let σ be a physical-channel permutation acting on the invariants. The rational chart pullback must satisfy

χ
S
	​

(φ(z
T
	​

))=σ(χ
T
	​

(z
T
	​

)).
	​

(13)

The attached chart source already records exact square identities and nonzero chart Jacobians for Kallen12, Kallen13, and Kallen23. 

Class77LowerChartSystem

Pullback of the source connection

If

A
S
=
ν
∑
	​

A
ν
S
	​

(z
S
	​

)dz
S,ν
	​

,

then

(φ
∗
A
S
)
μ
	​

=
ν
∑
	​

A
ν
S
	​

(φ(z
T
	​

))
∂z
T,μ
	​

∂φ
ν
	​

	​

.
	​

(14)

The derivative matrix in Eq. (14) is the coordinate Jacobian relevant to the Pfaffian system.

Rational basis map

Choose the convention

I
S
	​

(φ(z
T
	​

))=P(z
T
	​

,ϵ)I
T
	​

(z
T
	​

).
(15)

Then the exact module-isomorphism identity is

∂
μ
	​

P+PA
μ
T
	​

−(φ
∗
A
S
)
μ
	​

P=0,μ=1,2,
	​

(16)

together with

detP

≡0.
(17)

Equivalently,

A
μ
T
	​

=P
−1
(φ
∗
A
S
)
μ
	​

P−P
−1
∂
μ
	​

P.
(18)

Equation (16) must vanish entrywise over
Q(ϵ,z
T
	​

).

Physical cut-integral map

Equation (16) certifies an isomorphism of differential modules. To import physical boundary data, one must additionally establish an integral-level map:

affine loop/phase-space momentum map with exact Jacobian;

denominator-slot and index-vector map;

cut-slot map;

preservation of positive-energy cut orientations;

forward/conjugate virtual-side assignment;

normalized measure;

mapping of the physical chamber and root signs.

A connection isomorphism alone does not prove equality of the physical cut cycles.

Canonical-basis simplification

If both source and target are already in epsilon form, any rational transformation between their canonical forms is constant in the kinematic variables, under the hypotheses of the canonical-form uniqueness theorem. This gives a strong check:

∂
μ
	​

C=0,Ω
μ
T
	​

=C
−1
(φ
∗
Ω
S
)
μ
	​

C.
(19)

CANONICA’s multiscale algorithm and the uniqueness of canonical forms up to constant transformations are established in Meyer’s package paper. 
arXiv

Most plausible sources
CF231 / Kallen23

The first candidate should be the solved CF254 Kallen13 4×4 hard submodule, composed through the already derived closed-subsector map into CF305 and then through the exact within-class CF305–CF231 map.

This is favored by the measured matching signatures:

both hard gauges are 4×4;

both residue-compatibility spaces have dimension 17;

both final affine gauge spaces have dimension 16.

The relevant channel permutation exchanges the Källén labels 1↔2 while retaining the third root.

CF254 / Kallen13

The most plausible source class is a solved Kallen12 system under the exchange 2↔3. The archive lists several Kallen12 families but does not contain their complete block inventories, so it does not support naming one specific family.

Before solving for P, screen all solved Kallen12 candidates by:

block dimensions and incidence graph;

singular-divisor pullback;

characteristic polynomials of every divisor residue;

Jordan structure at generic epsilon;

rank and nullity of the corresponding Hom connection.

Any mismatch proves that candidate cannot provide the required full closed subsystem.

Stop condition

Do not allow the involution search to become another broad rational ansatz search. Abandon a candidate immediately after:

a block-dimension mismatch;

a divisor-set mismatch;

incompatible residue characteristic polynomials;

failure of an explicit integral-family relabeling.

Only candidates passing these invariants should be subjected to Eq. (16).

4. Deterministic stopping for modular reconstruction
The final criterion is the exact characteristic-zero identity

Once a reconstructed candidate satisfies

∂
μ
	​

R−ϵ(E
μ
	​

R−RC
μ
	​

)−B
μ
	​

+ϵ
a
∑
	​

K
a
	​

∂
μ
	​

logW
a
	​

=0
(20)

entrywise as a rational function over

Q(ϵ,x,y),

the reconstruction is exact. No additional prime is mathematically required. A different modular lift that also satisfies Eq. (20) would simply be another valid affine gauge.

This is why the ten-prime CF231 result is certified despite the earlier misleading degree stability.

Rational-reconstruction uniqueness

For one scalar coefficient reconstructed modulo M, if the intended bounds are

∣n∣≤N,0<d≤D,

then

2ND<M
(21)

makes n/d unique within that bounded range.

The symmetric Wang range uses

N=D=⌊
2
M−1
	​

	​

⌋.
(22)

The CF254 audit correctly retained this coefficientwise bound, modular back-substitution, and the final exact PDE identity.

Can a useful a priori height bound be derived?

In principle, yes. After choosing normalization columns and a square pivot submatrix, Cramer’s rule expresses every coefficient as a ratio of minors. Hadamard bounds on those minors give deterministic numerator and denominator bounds.

For systems of dimensions 1400–2000, these determinant bounds are generally enormous and operationally useless. The interpolation matrices introduce additional pessimistic height growth. They would usually require more primes than direct exact substitution.

Recommended stopping sequence

For each strip:

stable rank, augmented rank, pivot pattern, and affine nullity at several primes;

stable numerator/denominator degree support across disjoint prime subsets;

CRT plus rational reconstruction;

modular back-substitution to every reconstruction prime;

evaluation at at least one entirely unused prime and unused epsilon/kinematic points;

add the unused prime and check that the reconstructed candidate is unchanged, as a cheap early-termination filter;

exact two-variable residual in the original unspecialized equations.

Only step 7 is the final analytic certificate. Steps 5–6 are inexpensive protection against wasting time on a premature symbolic reduction; they are not substitutes for it.

5. Targeted balances
No current divisor justifies a balance

For an irreducible divisor q=0, the local Hom-connection operator governing a q
−k
 principal part is

L
q,k
	​

=k1+ϵ(E
q
	​

⊗1−1⊗C
q
T
	​

).
(23)

For every k≥1,

detL
q,k
	​

	​

ϵ=0
	​

=k
mn

=0.
	​

(24)

Thus, once both diagonal blocks are genuinely in epsilon form, a higher-pole principal-part equation cannot be identically resonant over Q(ϵ). Its solution may be large, but it exists uniquely at a generic divisor.

For the solved CF231 hard strip, the archive explicitly records that every local leading-pole Sylvester determinant is nonzero. Both hard strips now have exact rational gauges. Therefore none of their divisors should be balanced.

At a simple pole, equal Hom-residue eigenvalues may create homogeneous rational freedom. That is precisely the affine nullspace now being measured; it is not by itself a reason for a balance.

When a balance would be justified

A balance becomes defensible only if a future lower strip produces an exact local obstruction:

ℓ
T
L
q,k
	​

=0,ℓ
T
b
q,k
	​


=0,
(25)

or, at the logarithmic level, a nonzero class in the cokernel after all allowed K
a
	​

 are included.

One must then identify an exact invariant projector between generalized residue eigenspaces and prove that the balance:

removes the obstruction;

does not introduce a higher Poincaré rank elsewhere;

preserves or can exactly restore every diagonal epsilon form;

preserves all already solved strips after full-matrix transformation.

Fable’s statement that a targeted balance automatically preserves epsilon-form diagonal blocks is too strong. A Lee balance shifts residue eigenvalues by integers and generally changes the diagonal local lattices; the transformed diagonal blocks must be recertified. The standard Lee algorithm uses balances in its fuchsification/normalization stages, before final factorization. 
arXiv
+1

Therefore:

Do not run a balance now.
	​


The first divisor to test is not the one with the largest denominator power. It is the first divisor at which the sharp local system produces a certified cokernel obstruction. No such divisor is present in the attached results.

6. When to call TransformDlogToEpsForm
Complete the row first

The strip gauges currently produce a dlog row whose residues may depend rationally on epsilon. The exact CF231 certificate visibly contains such epsilon-dependent residues. TransformDlogToEpsForm is the subsequent factorization step that removes this residual epsilon dependence by a kinematics-independent transformation.

It is not a substitute for the rational gauges of remaining non-dlog strips.

The retained family driver explicitly follows the correct order:

construct the next effective strip using accumulated PrevD;

solve and append every lower strip in the row;

assemble the complete row transformation;

only then call TransformDlogToEpsForm. 

Class77LowerChartSystem

CF254

Proceed from the generated (9,6) input through

(9,6),(9,5),…,(9,1),

with the affine row state described above. After every sector-9 strip is dlog, call

Wolfram Language
TransformDlogToEpsForm

once on the complete 18-dimensional sector prefix.

Calling it now could mix the partially completed row, invalidate the current (9,6) source, and obscure the dependence on the (9,7) affine parameters.

CF231

First install the exact (8,7) gauge into a provenance-checked sector checkpoint and generate the exact (8,6) source. Then complete the row downwards and call TransformDlogToEpsForm only after all sector-8 strips are dlog.

One cheap CANONICA retry

After installing the new hard strips, it is reasonable to make one bounded retry of the whole-row

Wolfram Language
TransformOffDiagonalBlock

because the previous dominant obstruction has been removed. Accept it only if the complete transformed prefix passes the exact dlog gate. Do not interpret another timeout as mathematical evidence.

The solved hard strips already reduce all later work through NextEquationD; no early epsilon factorization is needed to obtain that benefit.

7. Prioritized finite calculation sequence
Stage 1 — retain exact affine states

For CF254 (9,7) and CF231 (8,7):

normalize every modular nullspace so the selected residue-coordinate block is the identity;

interpolate a particular vector and the 16 nullspace directions;

retain the corresponding residue directions;

check every affine basis direction in both Pfaffian equations exactly.

Continue if
Ap=b,AN=0

and all differential residuals vanish.

Fallback

If full exact lifting of all nullspace directions is too large, retain them as a modular evaluator and lift only the final affine row after the lower strips have constrained the parameter space.

Stage 2 — bounded cross-class involution test

Test, in this order:

CF254 Kallen13 → CF305 → CF231 Kallen23;

matching solved Kallen12 closed subsystems → CF254 Kallen13.

Perform the invariant screen before solving any rational intertwiner.

Continue if

block and divisor data match;

residue spectra match;

a cut-preserving family map exists;

Eqs. (13)–(18) vanish exactly.

Abandon if

any invariant mismatch appears. Do not enlarge an arbitrary rational ansatz after such a mismatch.

Stage 3 — retry the completed-prefix CANONICA row once

Compose:

CF254: (9,8) and (9,7);

CF231: (8,7).

Call the whole-row off-diagonal routine with the retained checkpoint.

Continue if

it returns a complete row and every entry is exact dlog.

Abandon if

the bounded run stalls or returns False; continue with the sharp solver rather than raising generic ansatz degrees.

Stage 4 — solve the next strips with upstream affine parameters

Start with:

CF254 (9,6),CF231 (8,6).

Use the simultaneous modular system (5), including the 16 parameters from the preceding hard strip.

At each lower strip:

derive divisor-specific pole bounds;

derive the infinity degree bound;

construct one simultaneous two-PDE sparse system;

solve for the new gauge, residues, and previous affine parameters;

reparameterize the complete row solution as one new affine space;

perform the unused-prime gate and exact residual.

This is the primary production route. FiniteFlow is an appropriate backend once the sharp finite ansatz is known; it does not replace divisor analysis or exact residual certification. 
arXiv

Continue if

the exact residual vanishes.

Escalate if

a proved complete bounded system is inconsistent. First reintroduce any older discarded row freedom, such as the (9,8) family. Only after that should a balance or alternative diagonal gauge be considered.

Stage 5 — benchmark augmented Maple on a solved fixture

Run the 34×34 augmented RationalSolutions construction on CF231 (8,7), where the expected answer is known.

Adopt it for future small strips if

it reproduces a nonempty h=1 slice;

the affine dimension is 16;

its gauge space matches the modular one exactly.

Abandon it as a production route if

it times out, swells badly, or returns an incomplete space. Such a failure says nothing about rational existence.

Stage 6 — sector factorization

After the complete row is dlog, call TransformDlogToEpsForm.

Accept only if

ϵ
A
μ
′
	​

	​


is epsilon-independent entrywise and

T
−1
A
μ
	​

T−T
−1
∂
μ
	​

T−A
μ
′
	​

=0

for both variables.

Stage 7 — full-family acceptance

For each family require:

detT
total
	​


≡0,
T
total
−1
	​

A
μ
	​

T
total
	​

−T
total
−1
	​

∂
μ
	​

T
total
	​

=ϵ
a
∑
	​

R
a
	​

∂
μ
	​

logW
a
	​

,
∂
ϵ
	​

R
a
	​

=0,

and exact flatness.

Only after this should boundary transport begin.

Final recommendation

For the immediate calculations:

CF254:
CF231:
	​

reconstruct the (9,7) affine nullspace, then solve (9,6)
with those 16 parameters included.
install (8,7) with full provenance, retain its affine basis,
then generate and solve (8,6).
	​

	​


Run the cross-class Källén test before further large interpolation, but place a strict invariant gate on it. Use full augmented Maple as an independent affine-space benchmark. Do not apply a balance unless a lower strip produces an exact local cokernel obstruction.

The main premise to reject is that another basis-construction search is now needed. The two difficult hard strips have demonstrated that the existing rational charts and sharp modular ansatz are sufficient. The remaining problem is consistent affine propagation down the block rows, followed by the already established sector-level epsilon factorization.