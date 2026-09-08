# Pro consultation: amplitude elimination with Laurent bounds

Model: gpt-6-pro.

## Prompt

Progress: normalized numerical Frobenius + sparse Taylor is implemented and passed the full 346-dimensional system under independent refinements after mapping 1,038 original coefficients. All demanded boundary coefficients in CF123/CF269/CF300 also pass, using closed componentwise epsilon demands. Physical coalescing-null constructor now verifies the small-positive-z spatial Gram signature, retains raw-to-standard measure factors and invariant fractions, canonicalizes six subset powers under S3, and evaluates elementary Dirichlet moments. 155 whole-domain coefficient integrals become 38 distinct fraction-power profiles. Exact generic-epsilon primary jets through z^2 take 36 seconds after block-triangular solves (309 residue blocks, max size2). Two new exact homogeneous relations arise from identical limiting integrals. No additional independent Gamma/Beta equations were found. These have not yet been applied to the saved shared solution.

I am starting the first genuinely non-elementary Euler integral. The existing sector/Taylor-subtraction pole-bound code proves lower order -2 (5 resolved sectors); propagating an actual requested amplitude demand through its coefficient row requires it through epsilon^2. I fixed a conservative positivity limitation by proving strict positivity on (0,1]^n for mixed-sign polynomial coefficients, while still accepting a resolved unit only after strict positivity on the closed cube.

Important remaining design question: preserving the original amplitude Laurent bounds while eliminating relations Q(eps)c = B(eps).
Old c bounds are -5 known c1, unknown -7/-6/-8. A generic rational RREF with arbitrary pivot columns can introduce epsilon poles into the map from free c's; arbitrary free coefficients might then violate an eliminated c's old lower bound. The old bound must not silently disappear.

My proposed fix:
1. Set c_i=eps^L_i d_i, d_i regular.
2. Transform each exact constraint row by these column powers and divide the row by its minimum epsilon valuation.
3. Select a coefficient that is a unit at eps0 as pivot. Eliminate its column from other rows using epsilon-regular operations, primitively renormalizing remaining rows when needed.
4. Track the RHS under exactly the same row operations. If it acquires negative epsilon powers, these coefficients are extra consistency constraints on the newly evaluated B series; do not discard them. For homogeneous constraints no problem arises.
5. The resulting affine map preserves the regular free d's. Propagate requested output orders through it; map back to original c if useful.
Could alternatively use existing Laurent lattice saturation on the row matrix, but it must return the row transformation to transform RHS.
Is this correct and preferable to a generic rational solve? Any epsilon-order trap in eliminating one newly evaluated B series? The first selected pivot minimizes the required B upper order, but I think it should additionally be restricted to minimal weighted valuation ord(Q_j)+L_j, so the remaining-amplitude coefficients cannot create poles below L_p.
Please suggest the minimal safe implementation, particularly when only a finite Laurent expansion of B is available. Also confirm that integrating the first B through the presently derived order is useful even if later lattice-preserving pivot selection requires extending it.


## Retrieved response

Yes. Your weighted unit-pivot elimination is correct and preferable here to an unconstrained rational solve. The minimal weighted-valuation restriction is essential when the remaining free amplitudes are to remain arbitrary series satisfying their old lower bounds.

The main additions are: preserve zero-row RHS identities as well as negative-power compatibility conditions; determine all row transformations exactly before truncating the RHS; and propagate orders through the assembled final map, not through individual elimination steps when exact cancellations can be retained.

Computing the first boundary integral through ϵ
2
 remains useful even if the final map requires extending it.

1. The invariant you should enforce

First move known amplitudes, including the known volume, to the RHS:

Q
U
	​

(ϵ)c
U
	​

(ϵ)=b(ϵ):=B(ϵ)−Q
K
	​

(ϵ)c
K
	​

(ϵ).

For the unknown amplitudes, set

c
U
	​

=D
L
	​

d,D
L
	​

=diag(ϵ
L
i
	​

),d
i
	​

∈O,

where O denotes series regular at epsilon zero. The coefficient matrix becomes

A=Q
U
	​

D
L
	​

.

Your aim is an exact row transformation U and a column permutation Π satisfying

UAΠ=(
I
r
	​

0
	​

C
0
	​

),C∈O
r×(n−r)
.
	​

(1)

Writing

Ub=(
h
h
0
	​

	​

),

the solution is

d=Π(
h−Cf
f
	​

),f∈O
n−r
,
	​

(2)

provided

h∈O
r
,h
0
	​

=0.
	​

(3)

This gives the precise guarantee you want: every regular choice of the free f's produces amplitudes satisfying all the original bounds, and every solution satisfying those bounds is represented.

The row transformation U itself can have epsilon poles. That is acceptable. It is C, the coefficients multiplying the free regular variables, that must be regular.

In original coordinates, the map need not be pole-free. A coefficient M
pj
	​

 multiplying c
j
	​

 is admissible when

ord
ϵ
	​

M
pj
	​

+L
j
	​

≥L
p
	​

.
	​

(4)

For example, ϵ
−2
c
j
	​

 is compatible with L
p
	​

=−8 and L
j
	​

=−6.

2. Your pivot restriction is exactly the right one

For a single residual equation

j
∑
	​

Q
j
	​

c
j
	​

=b,

eliminating c
p
	​

 gives

c
p
	​

=
Q
p
	​

b
	​

−
j

=p
∑
	​

Q
p
	​

Q
j
	​

	​

c
j
	​

.

To preserve c
p
	​

's bound for arbitrary allowed remaining amplitudes, require

ordQ
j
	​

−ordQ
p
	​

+L
j
	​

≥L
p
	​


for every j. Equivalently,

ordQ
p
	​

+L
p
	​

=
j
min
	​

(ordQ
j
	​

+L
j
	​

).
	​

(5)

The independent RHS condition is

ordb≥
j
min
	​

(ordQ
j
	​

+L
j
	​

).
	​

(6)

Thus “minimize the required B upper order” is a tie-breaker among admissible unit pivots, not a replacement for (5).

For example, let

c
a
	​

+c
b
	​

=B,L
a
	​

=−7,L
b
	​

=−6.

The normalized equation is

d
a
	​

+ϵd
b
	​

=ϵ
7
B.

Eliminating c
a
	​

 preserves arbitrary allowed c
b
	​

. Eliminating c
b
	​

 while leaving c
a
	​

 arbitrary would allow a nonzero c
a,−7
	​

, forcing c
b
	​

 below its permitted bound. A rational solve with that pivot is algebraically valid, but it must additionally retain the constraint c
a,−7
	​

=0. Your method avoids creating such constraints on nominally free coordinates.

Apply this to the current coordinates, not necessarily the original ones

Apply the verified homogeneous relations first. Suppose the current representation is

c=c
part
	​

+Kf,f∈O
m
,

with all old bounds already preserved. A new relation becomes

Q
new
	​

Kf=B
new
	​

−Q
new
	​

c
part
	​

.

Now choose pivots using valuations of the entries of Q
new
	​

K, because the current free variables have lower bound zero.

Do not select the new pivot from the original Q
new,j
	​

 and original L
j
	​

 while ignoring the earlier substitutions.

3. Row normalization is safe, but it moves divisibility requirements to the RHS

Your elimination steps preserve regular coefficients:

Normalize each nonzero active row by its minimum epsilon valuation.

Choose a unit entry and divide by that unit.

Eliminate its column using regular multipliers.

Renormalize the remaining active rows whenever their entries acquire a common epsilon factor.

Keep the exact transformation of the RHS throughout. A local Smith form with transformation matrices would encode the same divisibility information, but a full Smith computation is unnecessary for this task. Returning only invariant factors or a saturated row basis would not provide the required inhomogeneous map. 
arXiv
+1

Your negative-power check is necessary

A primitive row has a regular left-hand side. Therefore every negative Laurent coefficient of its transformed RHS must vanish.

These are compatibility conditions implied jointly by the exact relations and the assumed old bounds. A failure should trigger investigation of the relation, bound, normalization, or evaluated integral—not deletion of the offending coefficient.

In particular, taking the regular part of the transformed RHS is not a valid repair.

Also retain exact zero-row conditions

If coefficient elimination produces

0=h
0
	​

(ϵ),

the requirement is the full identity h
0
	​

=0, not merely absence of its negative powers.

With a finite expansion, you can verify this identity only through the available order unless an independent exact argument supplies the all-order equality. Keep the exact RHS expression or relation in the mathematical record.

Epsilon-order loss can arise after apparently harmless unit pivots

Consider

d
1
	​

+d
2
	​

=b
1
	​

,d
1
	​

+(1+ϵ
2
)d
2
	​

=b
2
	​

.

Both original rows are primitive and contain units. Eliminating the first pivot gives

ϵ
2
d
2
	​

=b
2
	​

−b
1
	​

.

Hence

d
2
	​

=
ϵ
2
b
2
	​

−b
1
	​

	​

,b
2
	​

−b
1
	​

=O(ϵ
2
).
	​

(7)

Determining d
2
	​

 through order K generally requires the difference b
2
	​

−b
1
	​

 through K+2.

Saturating the coefficient row does not eliminate this requirement; it transfers the epsilon division to the RHS. This is why the initial pivot's cost alone is not a reliable estimate of the final demand.

4. Separate exact elimination from finite RHS evaluation

The smallest safe implementation uses two layers.

Exact layer

Keep

b=W(ϵ)β(ϵ),

where β contains distinct boundary-integral series and known analytic inputs, each with a stable identifier.

Perform coefficient elimination over exact rational functions. Track either the row-operation list or the exact matrix U, and form

V=UW
	​

(8)

exactly before evaluating its Laurent coefficients.

This matters for precision as well as storage. In the preceding example, suppose

b
1
	​

=B,b
2
	​

=(1+ϵ
2
)B.

Then d
2
	​

=B exactly. Expanding b
1
	​

 and b
2
	​

 independently to the same finite order and then dividing their difference by ϵ
2
 would introduce an artificial loss of two orders.

Combining their exact multipliers first avoids that loss.

Finite-series layer

Store each evaluated series as

β
a
	​

=
k=ℓ
a
	​

∑
N
a
	​

	​

β
a,k
	​

ϵ
k
+O(ϵ
N
a
	​

+1
),

with its proven lower bound and absolute truncation order. The omitted coefficients are unknown, not zero. This distinction is the standard absolute-precision semantics of power-series arithmetic. 
SageMath Documentation

For an exact rational multiplier v(ϵ) of valuation ν,

vβ
a
	​

is known throughN
a
	​

+ν.

Therefore, to obtain

h
i
	​

=
a
∑
	​

V
ia
	​

β
a
	​


through order K
i
	​

, a conservative requirement is

N
a
	​

≥
i:V
ia
	​


=0
max
	​

(K
i
	​

−ord
ϵ
	​

V
ia
	​

).
	​

(9)

Use the same rule for negative-power compatibility checks: request enough input coefficients to determine the transformed RHS through order −1. If those coefficients are unavailable, the check is undetermined, not passed.

Division by a unit does not lower the absolute truncation order, but its inverse must still be expanded far enough. Replacing the unit by its epsilon-zero value is not sufficient.

Propagate from the final requested outputs

After composing the affine elimination with your saved solution, write

Y=M
f
	​

f+M
β
	​

β.

For requested coefficient Y
i
	​

 through order K
i
	​

, calculate

N
a
needed
	​

=
i
max
	​

(K
i
	​

−ord
ϵ
	​

(M
β
	​

)
ia
	​

).
	​

(10)

Combine exact coefficients before taking their valuations. This catches cancellations that reduce the demand.

The same principle applies to the free-series demands. A single common order is safe, but the existing componentwise demand machinery can do better.

What a finite B expansion permits

If

B=
k=−2
∑
2
	​

B
k
	​

ϵ
k
+O(ϵ
3
),

then

ϵ
−2
B=
k=−2
∑
2
	​

B
k
	​

ϵ
k−2
+O(ϵ)

is known only through order zero.

You can nevertheless store an exact symbolic substitution involving the defined integral B(ϵ). Attach the evaluated coefficient range separately, and prevent numerical evaluation of outputs needing unavailable coefficients. Do not replace that exact symbol by its finite polynomial in the saved mathematical solution.

5. A minimal implementation contract

I would use the following outputs from the elimination routine:

	​

free normalized variables f,
c=c
part
	​

(β)+Kf,
exact RHS transformation and zero-row identities,
regularity conditions on transformed RHS prefixes,
coefficient availability and outstanding demands.
	​


The exact acceptance checks are

UAΠ=(
I
0
	​

C
0
	​

),ordC
ij
	​

≥0,

and, in original coordinates,

ordK
ij
	​

≥L
i
	​

.
	​

(11)

The particular part must separately satisfy

ordc
part,i
	​

≥L
i
	​

,

using the retained RHS compatibility conditions.

For a small number of new relations, exact rational arithmetic and a sparse row-operation log are sufficient. There is no need to introduce a general module package merely to perform this update.

Your existing row-saturation implementation is an acceptable alternative if it returns the transformation, preserves the omitted zero-row equations, and does not use truncated RHS coefficients to determine rank. Exact Q(ϵ) should determine pivots and rank independently of how much of B has been evaluated.

The essential regressions are already contained in the examples above: unequal old bounds; the two-row ϵ
2
 divisibility condition; repeated appearances of the same B whose exact multipliers cancel; and a zero coefficient row with a nonzero RHS.

6. Computing B through ϵ
2
 is still useful

Yes—those coefficients remain valid and reusable under every later pivot choice. The integral and its coefficients do not depend on the amplitude coordinates. A later lattice-preserving map may need additional coefficients, but it cannot invalidate the ones already computed.

With the proved bound ordB≥−2, computing through ϵ
2
 supplies five potentially nonzero coefficients. They can already validate the normalization, test RHS compatibility conditions, and determine every requested output whose composed multiplier needs no more than that range.

There is a separate integration-side order issue: a sector term

ϵ
−2
G(ϵ)

requires G through ϵ
4
 to assemble that term through ϵ
2
. Track this before summing sectors. A lower bound on the assembled integral does not justify dropping higher-order information needed to cancel deeper intermediate poles.

Since the rational elimination is inexpensive relative to a non-elementary Euler evaluation, compute the lattice-safe map and its composed demand now. But there is no reason to discard or postpone a valid −2,…,2 coefficient calculation merely because extension might later be needed.

The preferred sequence is: preserve the old bounds by scaling, eliminate with primitive unit pivots, retain exact RHS identities, compose the exact map into the requested outputs, and only then decide the final evaluation depth. Generic rational RREF is not mathematically wrong; it is simply incomplete unless it also carries the induced restrictions on its free Laurent series. Your proposed construction builds those restrictions into the parametrization instead.