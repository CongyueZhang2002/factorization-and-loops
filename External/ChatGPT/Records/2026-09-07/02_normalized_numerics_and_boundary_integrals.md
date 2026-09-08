# Pro consultation: normalized numerical continuation and boundary integrals

Model: gpt-6-pro. Conversation: 6a9e2f8a-cdfc-83e8-a15a-3446863a8b35.

## Prompt

We are beginning the overnight implementation. Latest project state is in the working repository factorization-and-loops; prior consultation record 01_singular_endpoint_numerical_evaluation.md.

I will implement the numerical-only Frobenius patch you recommended, but continue the normalized Fuchsian vector directly, avoiding the prepared-frame poles. Please challenge the following precise design, especially epsilon truncation and error control.

Input: exact rational normalized A(z,eps), epsilon-regular, nilpotent R0 = Res_z A(z,0), index3, n=346; regular rational seed S(eps), n x84; amplitude Laurent bounds -8..; exact rational gauge to original masters. At fixed numerical amplitude Laurent coefficients, multiply S by amplitudes first to one Laurent seed vector. Determine normalized coefficient demands backwards through gauge and epsilon coefficient graph; take conservative common min/max if needed. For each normal power n and eps coefficient k construct logarithm polynomial P_n,k(log z) using (n I - R0) P + derivative_log P = sources, n0 via nilpotence. This is convergent Frobenius initialization, numerical normal order separate from symbolic subtraction N5. Then continue the epsilon-expanded normalized vector with sparse arbitrary-precision Taylor recurrence along z(u)=Z[u+i u(1-u)/4]. Prefer a moderate matching point inside radius of nearest fixed pole. Independent M and match-point refinements determine truncation empirically, degree/step refinements determine continuation error. Map to original only at target.

Does aggregation discard any information necessary for requested coefficients? Any traps in uniform epsilon closure when seed has mixed lower orders and gauge has poles? Is it better to construct matrix epsilon coefficients as rational functions then enlarge state, or keep epsilon convolution in the compiled recurrence? Suggest practical stopping/error criteria that don't become dominant work.

Second, before region construction: physical limit is vanishing three-particle recoil invariant z, v=1/4,w=3/4-z. Original inputs are reverse-unitarity cut masters. We have cut Baikov representations with Gram-domain restrictions and elementary Gamma/Beta evaluators. Need general code mapping physical regions to 83 Frobenius amplitudes, then reduced Euler integrals to SubTropica. What is the smallest mathematically honest vertical slice that can compute nontrivial new physical amplitudes without claiming completeness of an unsupported region finder? Please be explicit about raised-cut/domain derivatives and avoiding blind z=0.


## Retrieved response

Your numerical design is correct for a fixed amplitude vector. Aggregation loses no information needed to evaluate that vector’s requested coefficients. The main requirements are to make epsilon truncation a closed Laurent-coefficient problem, supply the n=0 logarithmic normalization explicitly, and judge convergence after mapping to the requested original-master coefficients.

For the physical-amplitude work, I would start with one certified leading coefficient of a unit-cut integral over the entire rescaled phase space. Your large-D moment bounds can support this without a complete region finder. Only after that should the first genuinely nonuniform endpoint region be added.

1. Epsilon closure: allocate the state before aggregation

Write

F
′
=A(z,ϵ)
F
,
F
=H(z,ϵ)z
R(ϵ)
b(ϵ),b=S(ϵ)p(ϵ),

and denote the normalized-to-original gauge by

I=T(z,ϵ)
F
.
Aggregation is valid

For specified numerical Laurent coefficients of p,

Hz
R
(Sp)

is exactly the same vector as the corresponding linear combination of the 84 transported columns. No amplitude labels are needed during numerical transport.

What aggregation does not retain is a reusable matrix of sensitivities to arbitrary amplitudes. Keep the exact seed matrix and symbolic solution separately; the region-to-amplitude matching described below still uses them.

Do not infer structural zeros or improved pole bounds from accidental cancellations for a particular numerical assignment. Likewise, missing amplitude coefficients must not silently become zero.

A common Laurent interval is a good first implementation

Let

ℓ=
a
min
	​

ord
ϵ
	​

p
a
	​

.

Because S and the normalized connection are epsilon-regular, the normalized vector has no coefficients below ℓ. With your conservative bound, take ℓ=−8.

Suppose original row i is required through ϵ
K
i
	​

, and

τ
ij
	​

=ord
ϵ
	​

T
ij
	​

.

A sufficient common normalized upper order is

K=
i,j:T
ij
	​


=0
max
	​

(K
i
	​

−τ
ij
	​

).
	​

(1)

Now transport the complete interval [ℓ,K]. This interval is closed because

F
k
′
	​

=
q=0
∑
k−ℓ
	​

A
q
	​

F
k−q
	​

.

No coefficient above K can feed back into it.

The required connection expansion is through K−ℓ, not through K. The same conservative depth applies to S. Thus, if the normalized state runs from −8 through +11, coefficients of A and S through +19 can matter.

For the final gauge multiplication,

I
i,k
	​

=
j
∑
	​

r
∑
	​

T
ij,r
	​

F
j,k−r
	​

.
(2)

Gauge coefficients can be needed through r=K
i
	​

−ℓ, in addition to their negative orders.

A simple regression detects this mistake:

y
′
=ϵ
11
y,y(0)=ϵ
−8
,I=ϵ
−3
y.

Then

[I]
ϵ
0
	​

=z.

Although only y through order +3 is needed, dropping A
11
	​

 loses the answer.

Sparse componentwise demands can come later

The backward rule for a connection entry whose first nonzero epsilon order is q
ij
	​

 is

U
j
	​

≥U
i
	​

−q
ij
	​

.

Iterate these inequalities, including all order-zero coupling closures, and combine them with the gauge and seed demands.

That optimization is legitimate, but a common interval is much harder to get wrong. In particular, do not allocate each row independently from its final requested order while neglecting same-order coupling through A
0
	​

(z).

2. The proposed Frobenius initialization needs one normalization condition

Write

zA(z,ϵ)=R(ϵ)+
m≥1
∑
	​

C
m
	​

(ϵ)z
m
,

and expand

F
(z,ϵ)=
n≥0
∑
	​

z
n
k=ℓ
∑
K
	​

ϵ
k
P
n,k
	​

(L),L=\Logz.

Your recurrence is

(nI−R
0
	​

)P
n,k
	​

+∂
L
	​

P
n,k
	​

=
q=1
∑
k−ℓ
	​

R
q
	​

P
n,k−q
	​

+
m=1
∑
n
	​

q=0
∑
k−ℓ
	​

C
m,q
	​

P
n−m,k−q
	​

.
	​

(3)

This construction is compatible with numerical continuation by generalized local series; an explicit symbolic zero-order homogeneous fundamental matrix is not needed for this numerical evaluator. Such epsilon-expanded series continuation is an established DE evaluation method. 
arXiv

At n=0, impose P
0,k
	​

(0)=b
k
	​


The normalization is

P
0
	​

(L,ϵ)=e
R(ϵ)L
b(ϵ),P
0,k
	​

(0)=b
k
	​

.
	​

(4)

Here L=0 is a normalization of the logarithm polynomial, not an instruction to evaluate the full solution at z=1.

For

Q
k
	​

(L)=
q≥1
∑
	​

R
q
	​

P
0,k−q
	​

(L),

solve

P
0,k
′
	​

=R
0
	​

P
0,k
	​

+Q
k
	​

,P
0,k
	​

(0)=b
k
	​

.

Since R
0
3
	​

=0, this is finite polynomial arithmetic at each epsilon order.

Do not cap the log degree at two. That cap applies only to e
R
0
	​

L
. Insertions of R
1
	​

,R
2
	​

,… produce higher powers of L. A safe bound under these assumptions is

deg
L
	​

P
n,k
	​

≤3(k−ℓ)+2,

although actual degrees may be much smaller. Use the algebraic bound or exact structural information to terminate the recurrence, not numerical “smallness” of the last coefficient.

At n>0, no integration constants are introduced

Because R
0
3
	​

=0,

(nI−R
0
	​

)
−1
=
n
I
	​

+
n
2
R
0
	​

	​

+
n
3
R
0
2
	​

	​

.
	​

(5)

There is no need for repeated 346×346 matrix inversion. Applying R
0
	​

 twice to a vector is sufficient.

If the right-hand side of (3) is

Q(L)=
j=0
∑
d
	​

Q
j
	​

L
j
,

solve downward in log degree:

P
d+1
	​

=0,P
j
	​

=(nI−R
0
	​

)
−1
(Q
j
	​

−(j+1)P
j+1
	​

).
(6)

This is likely simpler and cheaper than materializing derivative powers of Q.

The unique polynomial solution at n>0 is the desired one. Adding the nonpolynomial homogeneous solution of this auxiliary L-equation would duplicate lower normal powers and change the seed normalization.

3. Keep epsilon convolution implicit in the Taylor continuation

I recommend a hybrid:

Precompute exact sparse epsilon-coefficient data, but execute the enlarged system implicitly through coefficient convolution. Do not materialize a large block-Toeplitz matrix unless it is useful for a small regression test.

For the path

z(u)=Z[u+
4
i
	​

u(1−u)],

use

A(u,ϵ)=z
′
(u)A(z(u),ϵ).

At a center u
c
	​

, let h=u−u
c
	​

 and write

A(u
c
	​

+h,ϵ)=
m,q
∑
	​

A
m,q
	​

h
m
ϵ
q
,
F
(u
c
	​

+h,ϵ)=
n,k
∑
	​

f
n,k
	​

h
n
ϵ
k
.

Then

(n+1)f
n+1,k
	​

=
m=0
∑
n
	​

q=0
∑
k−ℓ
	​

A
m,q
	​

f
n−m,k−q
	​

.
	​

(7)

This remains explicit even though A
0
	​

 is not triangular: the Taylor order on the right is lower.

For implementation, retain shared denominator data and sparse coefficient arrays. Compute local Taylor coefficients by truncated polynomial arithmetic at the numerical center. Avoid repeatedly expanding large symbolic rational expressions in both the center and epsilon.

If exact rational A
q
	​

(z) swell substantially, retain a shared rational-expression representation and perform the required truncated bivariate arithmetic numerically. The essential requirements are exact epsilon-order allocation and controlled-precision arithmetic—not a particular expanded representation.

For ℓ=−8, K=11, the transported state has 346×20=6920 scalar coefficient values, not 346 generic-epsilon values and not 346 times 84 columns.

Two path details

Use distances to singularities in the actual Taylor variable u. These are the preimages of the z-plane poles under z(u), including the preimages of z=0. A distance measured directly in the z-plane is not automatically the convergence radius of a Taylor series in u.

Also, keep the initial \Logζ branch consistent with the prescribed physical sheet. Thereafter the ordinary DE continuation carries the branch; do not reselect logarithm branches independently at intermediate points.

4. Error control: inexpensive estimates, but acceptance at the original outputs

Your proposed refinements are appropriate as empirical convergence tests, not rigorous enclosures. In coupled systems, bounding the truncated connection or a local series tail alone need not bound the final solution by the same amount; DiffExp’s documentation explicitly notes this distinction. 
arXiv

Initialization

Choose ζ=z(u
c
	​

) at a moderate fraction of a verified local convergence radius. A starting choice such as 0.2–0.4 of that radius is reasonable, subject to the actual coefficient behavior. Increase the Frobenius order M, rather than pushing ζ toward zero.

Evaluate the complete blocks

ζ
n
P
n,k
	​

(\Logζ),

not individual log monomials when estimating truncation. Compare orders M and M+ΔM, and inspect several final normal-order blocks rather than only the last term.

Also evaluate the truncated Frobenius solution’s residual against the untruncated rational connection coefficients at independent points. This detects coefficient gaps that can fool a last-term test.

A second matching point is particularly useful. Compare the two initializations after continuation to the same target; agreement only at the starting point does not account for subsequent amplification.

Ordinary continuation

Use a radius-limited step and moderate Taylor degree. Extend the already computed coefficients by several orders to estimate truncation; this is cheaper than recomputing an unrelated approximation. Split the step when the tail does not decrease reliably.

For selected panels, compare one full step with two half-steps. This need not be done for every panel once a run is behaving consistently.

A few independent residual evaluations per panel are useful:

R
k
	​

=
F
k
′
	​

−
q
∑
	​

A
q
	​

F
k−q
	​

.

Checking only identities used to construct the Taylor coefficients is not an independent test.

Final gauge amplification

At the target, error bounds or estimates η
j,k
	​

 for normalized coefficients propagate as

η
i,k
orig
	​

≤
j,r
∑
	​

∣T
ij,r
	​

(Z)∣η
j,k−r
	​

+η
i,k
gauge
	​

.
	​

(8)

Use this estimate and direct refinement differences to accept the requested original coefficients.

A tolerance of the form

atol
i,k
	​

+rtol∣I
i,k
	​

∣

needs a meaningful absolute tolerance for coefficients that vanish or are very small. Report absolute uncertainty there rather than an inflated number of relative digits.

If the gauge convolution involves cancellation, inspect

∣I
i,k
	​

∣
∑
j,r
	​

∣T
ij,r
	​

F
j,k−r
	​

∣
	​


as a conditioning indicator. It indicates arithmetic guard digits that may be necessary; it does not replace step or series refinement.

Error propagation need not require a connection matrix

A conservative coefficientwise comparison equation is

η
i,k
′
	​

≤
q,j
∑
	​

∣A
q,ij
	​

∣η
j,k−q
	​

+ρ
i,k
	​

,
(9)

with initialization uncertainty and numerical residual bounds included. It uses the same sparse convolution pattern.

For the first implementation, use this selectively or with scaled norm bounds, and retain empirical target-level refinements as the acceptance check. A certified mode would additionally need genuine interval/supremum bounds on the coefficients and residuals; sampled maxima are not certificates.

Minimal numerical regressions

Before a full evaluation, require these independent tests:

Test	What it detects
Aggregated seed versus the sum of two separately propagated seeds	Linearity and aggregation errors
The scalar ϵ
11
 example above	Incorrect epsilon closure
Constant R(ϵ)/z with R
0
3
	​

=0 and distinct generic slopes	Missing collision-generated log powers
Increasing K without changing the lower seed coefficients	Feedback from incorrectly truncated high orders
Two M's, two matching points, and one refined continuation	Initialization versus continuation error

Use exact rational test amplitudes where possible. Their values should not introduce an unrelated input-precision limitation.

5. The first physical-amplitude calculation should be a certified whole-domain limit

This recoil edge is not the earlier c→0 corner. Here v+w→1, while c remains nonzero. The old substitution and its seven boundary integrals cannot simply be reused.

For a selected unit-cut integral, seek an exact rescaled representation

I(z,D)=z
D−3−M
N(D)∫
Ω
	​

f
z
	​

(x,D)dμ
D
	​

(x),
(10)

where Ω is a fixed unit-mass phase-space domain and all factors from the measure, ordinary denominators, numerators, and normalization are retained.

Your existing moment argument can certify the leading coefficient

The useful strengthening is not merely

	​

∫f
z
	​

dμ
D
	​

	​

≤C(D).

Establish, for some δ>0 and a real interval of sufficiently large D,

f
z
	​

⟶f
0
	​

almost everywhere,
0<z<z
0
	​

sup
	​

∫
Ω
	​

∣f
z
	​

∣
1+δ
dμ
D
	​

<∞.
(11)

Then uniform integrability gives

z→0
+
lim
	​

z
−(D−3−M)
I(z,D)=N(D)∫
Ω
	​

f
0
	​

(x,D)dμ
D
	​

.
	​

(12)

Your higher inverse-moment/Hölder bounds are well suited to proving (11): increase the denominator powers in the estimate and raise the large-D convergence threshold. This can handle moving, coalescing external directions without requiring a single pointwise dominating function.

This is a coefficient of the full physical integral, not merely a guessed contribution from one region. After identifying it with the generic-D DE expansion, continue the resulting meromorphic coefficient identity toward D=4.

It will normally address a coefficient in the b=−2 sector. It does not determine the b=−3,−4 sectors, which can be subleading in the large-D domain.

A finite limit also excludes logarithms at that exact leading power. Thus it can yield equations

Q
0
	​

(ϵ)p=C(ϵ),Q
log
j
	​

(ϵ)p=0(j≥1),

not just a value for one scalar coefficient.

Do not infer a fixed domain from a raw Baikov polynomial

Cut Baikov representations include physical integration-domain restrictions, not only an algebraic integrand. Their construction explicitly requires identifying the appropriate domain. 
arXiv

For (10), supply an exact coordinate map to a fixed domain, or retain the varying-domain indicator and prove the corresponding convergence on a fixed ambient space. A shrinking domain with a compensating singular density is precisely where blind substitution can discard a contribution.

At minimum, retain the Gram inequalities, cut-energy orientations, root branches, Jacobian and multiplicity of each domain component. Setting the Gram determinant or z to zero before doing this is not an admissible limit operation.

6. Make the first limit rank-increasing before spending integration effort

The exact local solution already gives, for any candidate original integral,

I(z,ϵ)=T(z,ϵ)H(z,ϵ)z
R(ϵ)
S(ϵ)p(ϵ).

Extract a finite set of generic-epsilon coefficients:

C
α
	​

I=Q
α
	​

(ϵ)p(ϵ).
(13)

Here α specifies the integer power, epsilon slope, and logarithmic level. Include enough prefactor and gauge jets to extract the requested original-basis coefficient correctly.

Before integrating a candidate boundary expression, test whether its Q
α
	​

 adds rank modulo the known volume and any already established amplitude relations. This prevents spending the first implementation effort on another representation of the volume.

A Beta/Gamma evaluation can still be a substantive new result: what matters is whether it supplies a new equation on the currently unresolved amplitudes.

The first successful end-to-end calculation should be

one unit-cut integral⟶certified full leading coefficient⟶reduced Euler integral⟶Q
α
	​

p=C
α
	​

(ϵ).
	​

(14)

Require rank gain at least one and actually substitute the relation into the amplitude representation.

One region, one slope, and one amplitude are not interchangeable. Saturation can mix slopes across seed columns, and a physical coefficient can constrain several amplitudes. Keep the exact linear equation.

First genuinely nonuniform region: use an exact subtraction identity

After the whole-domain limit works, choose a candidate whose Beta integrations leave one unresolved endpoint. Implement explicit endpoint subtraction for that selected integral rather than a general completeness claim.

A useful synthetic regression is

J(z,ϵ)=z
−2ϵ
∫
0
1
	​

x+z
x
−ϵ
(1−x)
−ϵ
	​

dx.
(15)

It has two leading branches,

J=z
−2ϵ
[B(−ϵ,1−ϵ)+O(z)]+z
−3ϵ
[B(1−ϵ,ϵ)+O(z)].
	​

(16)

This follows from the exact split

(1−x)
−ϵ
=1+[(1−x)
−ϵ
−1].

In the first integral use x=zy, retaining the finite upper endpoint and subtracting the large-y tail. In the second, the bracket improves the endpoint behavior and permits its leading limit in a suitable convergence strip.

This tests region matching, analytic continuation and cancellation between the two generic-epsilon branches. At epsilon zero the separate 1/ϵ terms cancel to produce the expected −logz. It is a regression example, not a claimed representation of one of your masters.

For actual region decompositions, a coefficient is complete only after omitted domains are controlled or an exact partition/subtraction establishes their contribution. Overlap terms cannot be discarded solely because a region algorithm normally expects them to be scaleless. 
arXiv

7. Raised cuts must remain outside the first limit implementation

Use unit cuts for the first physical calculation and transfer the result through exact IBP/DE relations where possible. Leave the genuinely unobserved raised-cut input unresolved until its own treatment is implemented.

With

Δ
ν
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

[(D
q
	​

−i0)
−ν
−(D
q
	​

+i0)
−ν
],D
q
	​

=q
2
−m
2
,

the convention is

Δ
ν
	​

(D
q
	​

)=
(ν−1)!
(−1)
ν−1
	​

θ(q
0
)δ
(ν−1)
(D
q
	​

),
Δ
ν
	​

=
(ν−1)!
1
	​

∂
m
2
ν−1
	​

Δ
1
	​

.
	​

(17)

This is the distributional meaning of higher cut powers, rather than a product of delta functions. 
APS Journals

Three implementation consequences follow.

Differentiate the complete representation. The mass derivative acts on induced dependence in the Jacobian, Gram polynomial, integration limits, numerator, and remaining denominators. It is not just a derivative of the displayed Gram power after the cut variables have already been set to zero.

Control boundary terms. For example,

dm
2
d
	​

∫
a(m
2
)
b(m
2
)
	​

f(x,m
2
)dx=∫
a
b
	​

∂
m
2
	​

fdx+f(b,m
2
)b
′
−f(a,m
2
)a
′
.
(18)

In a Gram-domain representation these terms are encoded in derivatives of domain indicators. They may vanish in a sufficiently convergent large-D domain, but that must be proved to the required derivative order before meromorphic continuation.

The mass and recoil limits do not commute automatically. The natural scaled variables are

m
i
2
	​

=zμ
i
	​

,∂
m
i
2
	​

	​

	​

z
	​

=z
−1
∂
μ
i
	​

	​

.
(19)

Fixed positive masses eventually eliminate the recoil phase space as z→0. Therefore differentiating an already massless limiting integral is not justified by the formal integer factor z
−1
. Establish differentiation in the scaled massive domain, including possible nonanalytic behavior at μ
i
	​

=0.

This is a reason to defer the exceptional dotted-cut amplitude, not a reason to delay rank-increasing unit-cut amplitude determinations.

8. Euler reduction and the stopping condition for the first physical result

After the coefficient is established as physical, reduce its integral representation exactly: partial fractions, valid boundary IBPs, and elementary Beta/Gamma integrations. Feed the remaining Euler integrals to SubTropica only with their normalization, domain and branch information intact.

SubTropica targets linearly reducible Euler integrals and symbolic hyperlogarithmic integration. An arbitrary Gram-domain integral is not automatically in that supported class. Unsupported linear reducibility or geometry should leave an explicit unevaluated integral, not a claimed analytic amplitude. 
arXiv

With auxiliary regulators, combine all contributions to the selected physical coefficient and account for their cancellations before removing those regulators. Then determine the epsilon depth needed by solving Q
α
	​

p=C
α
	​

: poles in that coordinate relation may require additional coefficients of the Euler result.

For each accepted new relation, retain only the mathematical essentials: the original unit-cut integral and normalization; the exact domain map and limit/subtraction justification; the reduced Euler definition; and the exact coefficient row Q
α
	​

.

The numerical milestone is convergence of the requested original coefficients under independent initialization and continuation refinements. The physical milestone is one new, rank-increasing amplitude relation with an evaluated right-hand side and an actual substitution. Neither requires a full transport matrix or a complete campaign-wide region finder.

I did not locate 01_singular_endpoint_numerical_evaluation.md in the available repository or Library searches; this reviews the supplied current design rather than the uncommitted implementation.