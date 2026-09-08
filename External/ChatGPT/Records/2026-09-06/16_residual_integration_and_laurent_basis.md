# Residual integration and Laurent basis

## Question

Your residual-counterterm identity is useful. We obtained the FULL346 normal system's normalized Fuchsian form in31s anyway (small diagonal integer exponent shifts + offdiagonal Sylvester pole removal); exact rational-point checks pass. All residue exponents are b epsilon with integer part zero. Its exact primary decomposition took17s; groups b=-2:48,-3:3,-4:32,0:232,-1:19,+1:12; Jordan nilpotency index<=2. An epsilon-only rescaling makes the normalized connection epsilon-regular (zero residue at eps0 is nilpotent). Original system's finite-integration preparation took44s and gives epsilon-regular connection B(z,eps), B0 strictly lower triangular; this retains previously solvable zero-order frame. Matrix G from normalized epsilon-regular frame to this original prepared frame has eps valuation>=0, z valuation>=-4. It includes some logs analytic atz0. Only84 local amplitudes retained (83negative-slope directions plus exceptional b0 column153); that exceptional residue basis column is supported only on the unobserved CF248 row153. Known volume fixesone.

Simplification to your method: use a finite normalized Frobenius jet Jbar_N (generic-epsilon physical subspace selected first), then J=G Jbar_N. D=J'-B J=G times normalized jet defect. Materialize epsilon coefficients and solve errors E=F-J via
E[k,i](z)=Integral_0^z (sum_{q>=0,j} B[q,i,j](t) E[k-q,j](t)-D[k,i](t))dt,
where q0 onlyj<i, so finite epsilon/row recursion. F=J+E. This uses no higher-epsilon homogeneous propagator and reuses original triangular B0. Since normalized defect=O(z^N logs), Jbar tail=O(z^(N+1)), G minnormalvaluation -4, N>=4 guarantees E_formal->0 in every prepared component. Uniqueness at each epsilon order follows triangular B0 with zero diagonal (no nonzero homogeneous vector can vanish in all rows atz0). To avoid relying on numerical cancellations, choose N also so each B_ij E_j term is integrable: N>=max_ij(poleorder(Bij)-1-normalLowerBound(G_j)), and N>=max_i(-normalLowerBound(G_i)); all pole bounds checked jointly inepsilon. Then each unrolled proper integral is well defined near0. Fullnormalized integer-zero residue also means nI-adR invertible at eps0 for n>=1; jet coefficients can safely be expanded AFTER exact physical seed projection, with no extra inverse-recurrence epsilon poles.

Please check this simplified exact finite-coefficient construction and the two cutoff bounds. Is there a subtle boundary-constant ambiguity or missing term?

For order/storage efficiency we may epsilon-saturate the retained seed columns: repeated exact constant column operations and division of columns vanishing at eps0 give a basis Bphys(eps) regular at eps0 and full column rank there. This preserves the generic physical subspace and every Jordan direction; inputs become explicit linear combinations of local amplitudes. A left inverse regular ineps gives conservative input pole bounds from known original-master pole bounds, the meromorphic gauge, and nonnegative-epsilon local transport. No need to call a pole of a coordinate projector a new physical divergence. Please flag pitfalls in this saturation/order argument too. We will still state this is an input-series basis, not boundary-IBP-minimal integrals.

## Pro response

Your simplified construction is correct, and both cutoff bounds are sufficient with the stated joint z,ϵ valuation bounds. There is no missing source term or boundary constant. The important qualifications are that endpoint vanishing is imposed coefficientwise in epsilon, that the integrability bounds apply to complete coefficient functions rather than arbitrarily distributed summands, and that input pole bounds require control of the inverse gauge and transport.

The saturation proposal is also sound. It removes avoidable degeneracy of the retained coordinates without changing the generic physical subspace. It does not, however, make the commuting spectral projector regular, nor does the reported generic Jordan index bound the logarithmic degree after expansion at ϵ=0.

1. Exact formulation and uniqueness

Write the normalized system as

F
′
=
A
F
,
A
=
z
R(ϵ)
	​

+A
reg
	​

(z,ϵ),

and its local fundamental solution as

Φ
(z,ϵ)=H(z,ϵ)z
R(ϵ)
,H(0,ϵ)=1.

Let S(ϵ) contain the 84 retained seed columns, and let p(ϵ) be their amplitudes. With

H
N
	​

=
n=0
∑
N
	​

H
n
	​

(ϵ)z
n
,

your counterterm is

J
N
	​

=H
N
	​

z
R
Sp,J
N
	​

=G
J
N
	​

.

The exact gauge identity is

G
′
+G
A
=BG.

Consequently,

D=J
N
′
	​

−BJ
N
	​

=G(
J
N
′
	​

−
A
J
N
	​

).
	​

(1)

There is no additional G
′
 term to add. It has already cancelled through the gauge identity. Computing D by the right-hand side is preferable: it exposes the high-order normalized defect instead of manufacturing it through cancellation of large prepared-frame expressions.

Set F=J
N
	​

+E. Then

E
′
=BE−D.

For a Laurent expansion beginning at order ℓ, the explicit recurrence is

E
k,i
	​

(z)=∫
0
z
	​

[
j<i
∑
	​

B
0,ij
	​

(t)E
k,j
	​

(t)+
q=1
∑
k−ℓ
	​

j
∑
	​

B
q,ij
	​

(t)E
k−q,j
	​

(t)−D
k,i
	​

(t)]dt.
	​

(2)

Thus (k,i), ordered first by epsilon order and then by row, is a valid integration sequence. This is the usual epsilon-expanded DE hierarchy, with your strictly triangular B
0
	​

 making each same-order step a scalar integration rather than a coupled homogeneous problem. 
arXiv

Why the boundary condition is unique

Suppose two meromorphic coefficient solutions satisfy the same equation and

E
k,i
	​

(z)⟶0(z→0
+
)

for every k,i. At their lowest differing epsilon order, the difference obeys

δE
k
′
	​

=B
0
	​

δE
k
	​

.

Its first row is constant and therefore zero. Inductively, every subsequent row is constant after the preceding rows vanish, and is also zero. Repeating in epsilon proves uniqueness.

This argument does not require B
0
	​

 to be bounded or Fuchsian in the prepared frame. Strict lower triangularity is the decisive property.

The distinction from a fixed-epsilon boundary condition is essential. For example, z
ϵ
 vanishes for Reϵ>0, but its epsilon-zero coefficient is 1. A fixed-epsilon condition E(0)=0 could admit such additional solutions. Your coefficientwise zero-endpoint condition does not.

You have therefore removed the homogeneous-propagator requirement legitimately. It has not been hidden in another unspecified operation: the triangular recursion solves precisely the required zero-order problem.

2. Both cutoff inequalities have the correct offsets

Define O
log
	​

(z
r
) coefficientwise to allow a finite polynomial in logz multiplying z
r
. Let

g
i
	​

=a lower bound on the normal valuation of row G
i
	​

,

and let p
ij
	​

≥0 satisfy, over the epsilon orders being used,

B
q,ij
	​

=O
log
	​

(z
−p
ij
	​

).

Because the normalized jet includes terms through z
N
,

F
−
J
N
	​

=O
log
	​

(z
N+1
)

at every finite Laurent order. Therefore the actual prepared-frame remainder satisfies

E
k,i
	​

=O
log
	​

(z
N+1+g
i
	​

).
	​

(3)

The normalized differential defect starts one power earlier, giving

D
k,i
	​

=O
log
	​

(z
N+g
i
	​

).
	​

(4)

These are bounds on the exact local remainder and defect—not estimates obtained by treating the recursion terms independently.

First bound: zero endpoint and integrable defect

For E
k,i
	​

→0, its integer power must be strictly positive. Thus

N+1+g
i
	​

>0.

Since the quantities are integers, this is

N≥−g
i
	​

.
	​

(5)

The same inequality makes D
k,i
	​

 integrable, because its power is then at least zero.

With min
i
	​

g
i
	​

=−4, N=4 is sufficient for these two requirements. There is no extra +1 missing.

Second bound: integrability of each coupling term

Using (3),

B
q,ij
	​

E
k−q,j
	​

=O
log
	​

(z
N+1+g
j
	​

−p
ij
	​

).

Ordinary endpoint integrability requires the exponent to exceed −1. Equivalently,

N≥p
ij
	​

−1−g
j
	​

.
	​

(6)

Your combined sufficient bound is therefore exactly

N≥max{0, 
i
max
	​

(−g
i
	​

), 
B
ij
	​


=0
max
	​

(p
ij
	​

−1−g
j
	​

)}.
	​

(7)

The second maximum can require N>4; the minimum valuation of G alone does not settle it.

Why this proves existence as well as uniqueness

The normalized Frobenius solution provides a local solution whose remainder has (3). Under (7), every term in its coefficient equation is integrable and its endpoint value is zero. It therefore satisfies (2).

Uniqueness identifies that remainder with the recursively constructed one. Analytic continuation along the chosen nonsingular path then supplies the exact finite-coefficient expression at the ordinary points.

This also explains why the finite jet need not approximate the solution numerically there. It is a counterterm; the residual integrations restore all omitted kinematic dependence.

The “joint in epsilon” qualification is necessary

A generic-epsilon z-valuation is not enough. For example,

z+ϵ
1
	​

=
q≥0
∑
	​

(−ϵ)
q
z
−q−1

has increasingly severe normal poles in its epsilon coefficients, although its generic-epsilon normal valuation is zero.

Your stated joint checks address this issue. In implementation, g
i
	​

 and p
ij
	​

 must bound the actual epsilon coefficients being used, or follow from a genuinely uniform local factorization.

3. One limitation of the termwise-integrability claim

Your bounds certify integrability of

D
k,i
	​

andB
q,ij
	​

E
k−q,j
	​


as complete functions. They do not automatically certify every summand produced by flattening the finite-expression DAG.

For example, let

E
j
	​

(t)=∫
0
t
	​

1du+∫
0
t
	​

(−1+3u
2
)du=t
3
.

Then

∫
0
z
	​

t
−2
E
j
	​

(t)dt

converges. But distributing the outer integral over those two inner-integral terms produces two separately divergent integrals proportional to ∫
0
z
	​

dt/t.

Thus the safe storage rule is:

Keep each previously constructed E
k,j
	​

 as a complete shared coefficient function when it appears under a singular outer kernel. Distribute further only after proving the distributed pieces separately integrable.

The same applies to D. Use (1), and preserve the exact cancellations that give the normalized defect its z
N
 factor. Do not integrate J
′
 and BJ separately.

This is compatible with your finite scalar-integral DAG. It does not introduce a lazy generator or a finite-part prescription. Numerical evaluation may still benefit from factoring the certified endpoint power or using a local evaluation series to avoid loss of precision; such a series would be an evaluation aid, not the definition of the solution.

Also, (7) only controls the endpoint at zero. Check that the prepared connection and gauge introduce no additional poles or branch discontinuities on the integration path to the ordinary points.

4. The normalized Frobenius recurrence introduces no new epsilon poles

For

A
reg
	​

=
m≥0
∑
	​

A
m
	​

(ϵ)z
m
,

the prefactor recurrence is

(n1−ad
R(ϵ)
	​

)H
n
	​

=
m=0
∑
n−1
	​

A
m
	​

H
n−1−m
	​

,n≥1.
	​

(8)

This is a general local Frobenius construction; strict epsilon form is unnecessary. 
arXiv

Your conclusion about its inverse is correct. Since R(0) is nilpotent, ad
R(0)
	​

 is nilpotent, so

n1−ad
R(0)
	​


is invertible for every positive integer n. Hence the inverse in (8) is regular at epsilon zero.

Provided the A
m
	​

(ϵ) themselves are regular there, H
n
	​

(ϵ) is regular by induction. No recurrence-induced epsilon padding is required. Padding can still come from the seed representation, other gauges, the unknown amplitudes, and later anchor elimination.

This normalization also removes the persistent positive-integer resonance issue from the prefactor recurrence near epsilon zero. The Jordan structure at equal exponents is carried by z
R
.

Generic Jordan index ≤2 does not imply R(0)
2
=0

Different primary sectors can coalesce at epsilon zero. For example,

R(ϵ)=
	​

−2ϵ
0
0
	​

1
−3ϵ
0
	​

0
1
−4ϵ
	​

	​


is diagonalizable at generic epsilon, but R(0) is a three-step nilpotent Jordan block. Consequently,

z
R(0)
=1+R(0)logz+
2
1
	​

R(0)
2
log
2
z.

Do not cap the logarithmic degree using the generic primary Jordan indices.

A cancellation-safe alternative to expanding singular spectral projectors is to form

V(L,ϵ)=e
R(ϵ)L
S(ϵ),L=logz,

directly. Its coefficients satisfy

∂
L
	​

V
k
	​

=R
0
	​

V
k
	​

+
q=1
∑
k
	​

R
q
	​

V
k−q
	​

,V
k
	​

(0)=S
k
	​

.
(9)

Because R
0
	​

 is nilpotent, each step has a finite polynomial-in-L solution:

V
k
	​

(L)=e
R
0
	​

L
[S
k
	​

+∫
0
L
	​

e
−R
0
	​

u
q=1
∑
k
	​

R
q
	​

V
k−q
	​

(u)du].
(10)

This retains all collision-generated logarithms without exposing artificial projector poles.

5. Epsilon saturation is valid, with two distinctions

Let O be the ring of exact coefficient functions regular at ϵ=0, and let

W=span
FracO
	​

S
old
	​


be the retained generic subspace.

Your algorithm constructs a basis of

W∩O
346
.

Concretely, after making the columns regular, a nonzero vector

c∈kerS(0)

gives a column combination S(ϵ)c divisible by epsilon. Complete c to an invertible constant column transformation and divide that column by epsilon. The generic span is unchanged. Repeating removes the degeneracy until a maximal minor is nonzero at epsilon zero.

At that point an exact regular left inverse follows immediately. If P selects rows of a unit minor, take

L=(PS)
−1
P,LS=1.
	​

(11)

The old-to-new amplitude map must accompany the column map. If

S=S
old
	​

T,

then

p
old
	​

=Tp
new
	​

.

These are genuine coordinate transformations, not assumptions about vanishing amplitudes.

A regular left inverse is not a regular spectral projector

When retained and excluded eigenvalues collide, the commuting projector onto the retained eigenspaces can have unavoidable epsilon poles. Saturation does not prove otherwise.

The regular projector SL supplied by (11) generally has a different kernel and need not commute with R. It is valid for extracting coordinates of a vector already known to lie in the retained subspace. It must not replace the generic-epsilon physical projection on an arbitrary vector of old constants.

This does not obstruct your construction: you are building the physical columns from S, not projecting arbitrary data using SL.

If you exploit a smaller retained residue matrix, verify

RS=SR
phys
	​

.

For an invariant retained subspace,

R
phys
	​

=LRS

is regular, and

e
RL
S=Se
R
phys
	​

L
.

Saturation may mix slope groups, so individual new columns need not carry a single slope label. The generic subspace, not the label of each saturated column, is what remains invariant.

Handle the volume constraint after the coordinate transformation

A known-volume relation must be transformed along with the amplitudes. It is not generally still “set the original volume column to its known value” after arbitrary saturation.

Saturating all 84 columns first, then imposing the transformed independent volume relation, is clean. If eliminating a pivot introduces an epsilon pole, retain that valuation in the order calculation. It is a coordinate effect, but it can still increase the required Laurent depth.

6. The input pole-bound argument works through inverse transport

Let I(z,ϵ) be the original master vector and let

F
=T
norm←orig
	​

(z,ϵ)I

be the complete original-to-normalized gauge. At a fixed ordinary point z
∗
	​

,

F
(z
∗
	​

,ϵ)=
Φ
(z
∗
	​

,ϵ)S(ϵ)p(ϵ).

Thus

p=L
Φ
(z
∗
	​

,ϵ)
−1
T
norm←orig
	​

(z
∗
	​

,ϵ)I(z
∗
	​

,ϵ).
	​

(12)

Here the inverse normalized transport is regular in epsilon: H is regular, H
0
	​

 is an invertible fundamental solution along the nonsingular path, and z
R(0)
 is invertible. Forward regularity alone would not suffice, but these additional properties establish what you need.

For known bounds

ord
ϵ
	​

I
i
	​

≥ℓ
i
	​

,

a conservative uniform bound is therefore

ord
ϵ
	​

p
a
	​

≥
j,i:T
ji
	​


=0
min
	​

[ord
ϵ
	​

T
ji
	​

+ℓ
i
	​

].
	​

(13)

No full analytic transport calculation is required merely to obtain this bound.

Use the gauge in the direction shown. A forward gauge regular in epsilon can suppress a pole: F
prepared
	​

=ϵp does not imply that p has the same pole bound as F
prepared
	​

. Its inverse contributes 1/ϵ.

Sharper componentwise bounds require the relevant inverse-map support or another exact argument; a forward sparsity pattern alone is insufficient.

Construct transfer columns before multiplying unknown Laurent series

After saturation, S, G, the Frobenius prefactor and the prepared connection are epsilon-regular. Therefore the prepared-frame connection columns can be built from epsilon order zero upward. Keep the unknown p
a
	​

(ϵ) outside this construction.

Only afterward perform the Laurent convolutions and undo the prepared-to-original gauge. For

I
i
	​

=
a
∑
	​

M
ia
	​

p
a
	​


through order K
i
	​

, the demands remain

p
a
	​

:K
i
	​

−ord
ϵ
	​

M
ia
	​

,M
ia
	​

:K
i
	​

−ord
ϵ
	​

p
a
	​

.
(14)

Saturation improves these coordinates; it does not justify discarding the valuation calculation.

7. A sharp regression for the cutoff

A small example tests your actual −4 valuation and a higher-pole triangular B
0
	​

. Let

K=(
0
1
	​

0
0
	​

),R=−2ϵ1+K,

and choose

A
=
z
R
	​

+ϵ1,H=e
ϵz
1,G=1+z
−4
K.

Then

B=
z
R
	​

+ϵ1−
z
5
4
	​

K,B
0
	​

=(
z
1
	​

−
z
5
4
	​

)K.

Thus B
0
	​

 is strictly lower triangular, g
1
	​

=0, g
2
	​

=−4, and p
21
	​

=5. Both cutoff conditions give N≥4.

At N=3, the first omitted scalar prefactor term is

4!
ϵ
4
z
4
	​

.

Multiplication by the z
−4
 entry of G produces a nonzero constant remainder at that epsilon order. The associated B
21
	​

E
1
	​

 term also contains 1/z. The proposed zero-endpoint recursion therefore fails at N=3.

At N=4, the omitted term starts at z
5
, the prepared remainder vanishes, and the coupling integrand is integrable. This checks that the offsets in (7) are not merely conservative notation.

The construction now has the ingredients needed for actual substitution with at most 83 unknown series. Its mathematical basis is: an exact normalized jet with the generic physical subspace already selected, the defect identity (1), the two valuation bounds, and coefficientwise triangular uniqueness. Preserve cancellation-dependent coefficient nodes, expand the full residue exponential rather than singular projectors, and use inverse-gauge bounds for the saturated inputs. No additional boundary-matching constant is required.
