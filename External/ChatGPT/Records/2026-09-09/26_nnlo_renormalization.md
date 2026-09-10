# General NNLO UV and collinear assembly

Outgoing request verified gpt-6-pro, conversation 6aa0f5dd-de10-83e8-b032-74f47d77da2a, message 9a35a881-2de7-45e0-b9f3-c526b3976987. The response is retained as returned by the bridge; displayed mathematics has line-break artifacts.

## Question

Please review our general NNLO UV plus collinear assembly, especially a missed normalization or order demand. GPT-6 Pro is required. The working tree has unpushed changes, so the exact proposed convention is given here rather than claiming GitHub already has them.

SIDIS electromagnetic Born power p=0; general API also supports p>=0. Common PartonicResults already contain physical a^(p+r), with a=alpha_s/(2 Pi). Stored bare W_r are in the same mu_R, S_epsilon convention. We apply Z_alpha=1+a z1+a^2 z2, z1=-b0/epsilon, z2=b0^2/epsilon^2-b1/(2epsilon). At fixed source order s, the coefficient of a^d in Z_alpha^(p+s) is 1 (d0), (p+s)z1 (d1), (p+s)z2+(p+s)(p+s-1)z1^2/2 (d2). All leg transitions omit their a^k. We enumerate source s, UV shift d, each leg order k_i with s+d+sum k_i=N, and multiply each stored source by a^(N-s), the UV coefficient and correlated flavor multiplicity. One PDF leg uses kernel Z^S(source daughter <- target parent); one FF leg uses Z^T(target daughter <- source parent). Then C=Z^S transpose W_UV Z^T in the physical-parent-first FF matrix convention.

Full individual quark/antiquark/gluon sums are enumerated by equality classes with falling-factorial multiplicities, so two summed Born indices constrained equal give N_f, not N_f^2. Generic matrix test with five explicit species and noncommuting leg matrices agrees exactly at N2, including arbitrary p=2 UV terms. Actual splitting kernels are independently APFEL-verified.

Unequal scale kernels use L_i=log(mu_i^2/mu_R^2), eta_i=exp(-epsilon L_i):
Z_i1=eta_i P0/epsilon
Z_i2=eta_i^2 P0*P0/(2epsilon^2)+b0(eta_i^2-2eta_i)P0/(2epsilon^2)+eta_i^2 P1/(2epsilon).
For longitudinal PDFs we use raw Larin P1 before finite operator conversion. We plan final finite helicity conversion only after raw poles cancel, with C_MS2=C_L2-F1^T C_L1+(F1*F1-F2+b0 L_F F1)^T C0, expressed in a_R. Additional user finite kernels should be handled by the same transition-matrix engine and full inverse series.

Order planning: collect each kernel's delta/plus/regular Laurent coefficients to determine its exact minimum epsilon valuation; complete UV factor valuation is separate. For target epsilon<=n, source order s is requested through n-v_UV-sum_i v_i. Convolutions applied sequentially retain enough orders for all remaining factors, and every lower pole is retained for final cancellation. All scalar/collinear products invoke our omitted-term audit. Missing source is an error; only explicit exact zero can skip a channel.

Questions:
1. Any sign, transposition, coupling-counting, unequal-scale, or Larin conversion mistake in this setup? In particular should any residual S_epsilon or Born-dimensional prefactor be outside these identities?
2. Is termwise val counting sufficient and safe in this distributional assembly once each raw W_r has already been correctly endpoint-expanded? Identify possible over-conservatism vs an actual wrong-order scenario.
3. Is it valid to apply the finite scheme change as another instance of this same generic leg-transition engine with coupling renormalization disabled, provided input lower orders are the raw collinearly subtracted coefficients rather than bare W?
Keep this review concrete. We still must finish corrected RR integral coverage and regulated RR/RV endpoints; no finished hard result is claimed.

## Pro response

The proposed coupling counting, unequal-scale kernels, matrix orientations, and finite helicity conversion are correct. Your epsilon-demand rule is also safe once its inputs are genuine distribution-valued Laurent series. I do not find a missing universal factor or an additional blanket epsilon order.

The remaining conditions are specific: preserve each source’s dimensional normalization, propagate demands to the kernels as well as to the sources, and distinguish a four-dimensional finite scheme change from any chosen continuation of that change to positive epsilon orders.

1. Coupling renormalization and order enumeration

Separate notation temporarily:

W
s
	​

=a
R
p+s
	​

W
s
	​

(ϵ),a
R
	​

=
2π
α
s
	​

(μ
R
	​

)
	​

,

where W
s
	​

 denotes your coupling-containing stored object.

The bare-coupling replacement acts on that source as

W
s
	​

⟼W
s
	​

Z
α
p+s
	​

.

Therefore, for

s+d+
i
∑
	​

k
i
	​

=N,

the extra coupling power is

a
R
d+∑
i
	​

k
i
	​

	​

=a
R
N−s
	​

.

Multiplying it by the stored a
R
p+s
	​

 gives exactly a
R
p+N
	​

. There is no missing factor a
R
p
	​

, and it must not be inserted again.

Your expansion of Z
α
p+s
	​

 is the ordinary binomial expansion and is correct. In coupling-stripped notation it gives

W
0
UV
	​

W
1
UV
	​

W
2
UV
	​

	​

=W
0
	​

,
=W
1
	​

−
ϵ
pb
0
	​

	​

W
0
	​

,
=W
2
	​

−
ϵ
(p+1)b
0
	​

	​

W
1
	​

+[
2ϵ
2
p(p+1)b
0
2
	​

	​

−
2ϵ
pb
1
	​

	​

]W
0
	​

.
	​

	​

(1)

Thus SIDIS p=0 has

W
2
UV
	​

=W
2
	​

−
ϵ
b
0
	​

	​

W
1
	​

,

with no b
1
	​

W
0
	​

 term. For p=2, the Born counterterm is

(
ϵ
2
3b
0
2
	​

	​

−
ϵ
b
1
	​

	​

)W
0
	​

.

Make the b
1
	​

 convention explicit:

dlnμ
2
da
	​

=−ϵa−b
0
	​

a
2
−b
1
	​

a
3
+⋯,

so, for fundamental quarks,

b
1
	​

=
6
17
	​

C
A
2
	​

−
3
5
	​

C
A
	​

T
R
	​

n
f
	​

−C
F
	​

T
R
	​

n
f
	​

.
	​

(2)

This is β
1
	​

/4 when the reference uses α
s
	​

/(4π); similarly b
0
	​

=β
0
	​

/2. 
arXiv
+1

Use the common process-level p. A channel that first appears at source order s=1 must not redefine that contribution as s=0 for UV bookkeeping.

A complete NNLO expansion for testing the enumerator

Let K
i
[k]
	​

 be the coupling-stripped order-k transition acting on leg i, including its flavor sum and convolution. Define

A
p
	​

=pz
2
	​

+
2
p(p−1)
	​

z
1
2
	​

.

Your enumeration should reproduce

C
2
	​

=
	​

W
2
	​

+(p+1)z
1
	​

W
1
	​

+A
p
	​

W
0
	​

+
i
∑
	​

K
i
[1]
	​

(W
1
	​

+pz
1
	​

W
0
	​

)
+
i
∑
	​

K
i
[2]
	​

W
0
	​

+
i<j
∑
	​

K
i
[1]
	​

K
j
[1]
	​

W
0
	​

.
	​

	​

(3)

The last sum contains distinct legs only. A same-leg double insertion is already contained in K
i
[2]
	​

; adding another (K
i
[1]
	​

)
2
 would double count it.

This is coupling renormalization, not automatically every UV counterterm for every possible process. For the present massless electromagnetic calculation, there is no axial-current Z
5
	​

 on the vector vertex. Future cards with other operators or masses need their separately declared renormalizations. 
arXiv

2. No additional S
ϵ
	​

 is needed—provided the source normalization is literal

Write the bare-coupling relation as

a
0
	​

=B
R
	​

(ϵ)a
R
	​

Z
α
	​

,B
R
	​

=μ
R
2ϵ
	​

(4π)
−ϵ
e
γ
E
	​

ϵ

in your convention.

Your enumeration is correct when each stored source already contains the factor associated with its original bare-coupling power:

W
s
	​

=a
R
p+s
	​

B
R
p+s
	​

w
s
	​

.

The UV correction to that source retains that same
B
R
p+s
	​

. Raising its perturbative order through Z
α
	​

 does not manufacture another B
R
	​

.

Therefore:

Do not promote every lower-order contribution to the target order’s dimensional prefactor. If an output convention factors out B
R
p+N
	​

, the contribution from source s must retain the compensating ratio

B
R
s−N
	​

.

Your current use of the complete stored source avoids this trap, provided later normalization does not undo it.

The same principle applies to Born dimensional factors. A factor such as 1−ϵ, a gluon 1/(D−2) average, or a source-specific Gamma normalization remains in its source and must be expanded to the requested depth.

A genuinely common scalar factor may remain outside the full assembly if it is independent of species and convolution variables. A species-dependent spin normalization generally does not commute with flavor mixing; changing it requires the corresponding transformation of the leg matrices. There is no additional target/source spin-average ratio to append when the source and kernels already use the same normalized partonic convention.

3. The leg orientation and unequal-scale formulas are consistent

For incoming-first storage,

F=(f
bare
)
T
⊗
x
	​

W
UV
	​

⊗
z
	​

D
bare
.

With

f
bare
=Z
S
f,D
bare
=Z
T
D,

the coefficient is

C
ab
	​

=
i,j
∑
	​

Z
ia
S
	​

⊗
x
	​

W
ij
UV
	​

⊗
z
	​

Z
jb
T
	​

.
	​

(4)

Thus your arrows mean:

Z
ia
S
	​

: source hard-process daughter i← target incoming parent a;

Z
jb
T
	​

: source fragmenting parent j→ target daughter b.

The FF matrix is parent-first. If a kernel routine exposes daughter-first indices, transpose at that adapter boundary—not again in (4). This is consistent with the PDF–coefficient–FF factorization structure. 
arXiv

Your correlated flavor counting is the right approach. One further restriction is that falling-factorial multiplicities represent unweighted equivalent choices. With symbolic electromagnetic charges, a class carrying Q
f
2
	​

 contributes the corresponding charge sum, not automatically n
f
	​

Q
representative
2
	​

. Keep charge weights attached until the equality-class sum is performed.

Unequal scales

At a leg scale μ
i
	​

, define

L
i
	​

=ln
μ
R
2
	​

μ
i
2
	​

	​

,η
i
	​

=e
−ϵL
i
	​

.

Dimensional running gives

a
i
	​

=η
i
	​

a
R
	​

+
ϵ
b
0
	​

	​

(η
i
2
	​

−η
i
	​

)a
R
2
	​

+O(a
R
3
	​

).

Substituting into the pole matrix at μ
i
	​

 gives exactly

Z
i
[2]
	​

=
2ϵ
2
η
i
2
	​

P
0
	​

⊗P
0
	​

	​

+
2ϵ
2
b
0
	​

(η
i
2
	​

−2η
i
	​

)P
0
	​

	​

+
2ϵ
η
i
2
	​

P
1
	​

	​

.
	​

(5)

A useful expansion regression is

Z
i
[2]
	​

=
	​

2ϵ
2
P
0
	​

⊗P
0
	​

−b
0
	​

P
0
	​

	​

+
ϵ
P
1
	​

/2−L
i
	​

P
0
	​

⊗P
0
	​

	​

+L
i
2
	​

P
0
	​

⊗P
0
	​

+
2
b
0
	​

L
i
2
	​

	​

P
0
	​

−L
i
	​

P
1
	​

+O(ϵ).
	​

	​

(6)

In particular, the combined expression contains no
b
0
	​

L
i
	​

P
0
	​

/ϵ term.

An exact symbolic test, stronger than checking individual expansion coefficients, is

∂
L
i
	​

	​

Z
i
	​

=−Z
i
	​

⊗P(a
i
	​

)
	​

(7)

at fixed a
R
	​

, through the requested perturbative order. The evolution and beta-function conventions entering this identity are those used above. 
arXiv

The appearances of b
0
	​

 in coupling renormalization and in (5) are not double counting: one renormalizes the source’s bare coupling; the other enforces the scale dependence of the collinear operator transition.

4. Termwise valuation counting is safe in the distributional Laurent algebra

Let

A(ϵ)=
r≥v
A
	​

∑
	​

ϵ
r
A
r
	​

,

where each A
r
	​

 is a correctly defined endpoint distribution, including its delta, plus, and regular pieces.

For the standard Mellin convolutions on the positive-fraction domain,

v
ϵ
	​

(A⊗B)≥v
ϵ
	​

(A)+v
ϵ
	​

(B).
	​

(8)

Convolution can annihilate leading terms and raise the valuation. It does not create an additional epsilon pole when applied to already defined, epsilon-independent distribution coefficients.

The needed scope is distributions on (0,1], tested locally away from the small-fraction endpoint, or an explicitly justified extension beyond that domain. Under t=−lnx, this becomes the familiar convolution of distributions supported on a half-line. A divergent small-x moment is a separate operation and does not inherit this conclusion automatically. Distributional convergence must be understood through test functions, not interior point values. 
DLMF

For one enumerated contribution,

T=U
d
	​

(ϵ)[
i
∏
	​

K
i
[k
i
	​

]
	​

(ϵ)]W
s
	​

(ϵ),

your source requirement

d(W
s
	​

)=n−v
ϵ
	​

(U
d
	​

)−
i
∑
	​

v
ϵ
	​

(K
i
[k
i
	​

]
	​

)
	​

(9)

is therefore sufficient.

A certified lower bound on each valuation is sufficient too. Expensive exact simplification solely to improve that lower bound is an optimization, not a prerequisite for correctness.

The planner must request upper orders of every factor

The companion requirement for kernel j is

d(K
j
	​

)=n−v
ϵ
	​

(W
s
	​

)−v
ϵ
	​

(U
d
	​

)−
i

=j
∑
	​

v
ϵ
	​

(K
i
	​

).
	​

(10)

Likewise for the UV factor and any separately stored normalization.

For example, if

W
s
	​

=
ϵ
A
	​

+B+ϵC+⋯,

then

[
ϵ
e
−ϵL
	​

W
s
	​

]
ϵ
0
	​

=C−LB+
2
L
2
	​

A.
	​

(11)

The source through ϵ
1
 is necessary, but not sufficient unless the kernel’s smooth exponential is also retained through ϵ
2
.

Intermediate truncation must anticipate the remaining factors

Suppose a Born series is

B
0
	​

+ϵB
1
	​

+ϵ
2
B
2
	​

,

and two subsequent leg factors each have a simple pole. After the first multiplication, the intermediate ϵ
1
B
2
	​

 must survive because the second pole makes it finite.

Thus, after applying a prefix of the factors, retain through

n−
remaining factors j
∑
	​

v
ϵ
	​

(K
j
	​

).
	​

(12)

Your stated sequential rule covers this. The omitted-term audit should enforce (12) at every intermediate object, not just check the original source request.

What is conservative, and what is actually wrong?

Using the minimum valuation over an entire matrix, all support components, or individual RR/RV/VV pieces can over-request orders. Cancellations and flavor selection can make particular transitions less singular. Support- and entry-resolved demands can improve efficiency.

Actual under-requesting occurs when:

a source’s epsilon expansion is only pointwise, not distributional;

a delta/corner term or an epsilon-suppressed endpoint term was omitted;

a truncated kernel is treated as exact;

an intermediate is truncated before accounting for remaining poles;

a coefficient is declared zero from its unavailable tail or from a special scale/color value;

an extra regulator or a singular endpoint extension remains hidden inside a nominally “regular” convolution.

A simple diagnostic is

ϵ(1−x)
−1−ϵ
=−δ(1−x)+O(ϵ).

It is pointwise O(ϵ) in the interior but has distributional valuation zero. Once that expansion has been correctly performed, no second “endpoint order penalty” should be added during mass factorization.

For NNLO finite assembly, the generic distribution-source requirements remain

W
2
	​

:ϵ
0
,W
1
	​

:ϵ
1
,W
0
	​

:ϵ
2
.

Those are not master-integral order requirements. Producing the required endpoint-expanded W
2
	​

 can demand deeper edge, corner, and scalar-master data.

5. Reusing the transition engine for finite schemes is correct

Define the finite operator transformation at the PDF scale by

f
MS
	​

=F(a
F
	​

)⊗f
L
	​

,F=I+a
F
	​

F
1
	​

+a
F
2
	​

F
2
	​

+⋯.

For the incoming-first coefficient,

C
MS
	​

=F
−T
⊗
x
	​

C
L
	​

.

The input C
L
	​

 must be UV-renormalized and collinearly subtracted in the raw Larin scheme. This is the operator transformation direction used in the flavor-resolved formulation. 
arXiv

At ϵ=0,

a
F
	​

=a
R
	​

−b
0
	​

L
F
	​

a
R
2
	​

+⋯,

so

F=I+a
R
	​

F
1
	​

+a
R
2
	​

(F
2
	​

−b
0
	​

L
F
	​

F
1
	​

)+⋯.

Its inverse gives

C
MS
(1)
	​

C
MS
(2)
	​

	​

=C
L
(1)
	​

−F
1
T
	​

C
0
	​

,
=C
L
(2)
	​

−F
1
T
	​

C
L
(1)
	​

+(F
1
	​

⊗F
1
	​

−F
2
	​

+b
0
	​

L
F
	​

F
1
	​

)
T
C
0
	​

.
	​

	​

(13)

Your sign of b
0
	​

L
F
	​

F
1
	​

 is correct.

The raw splitting kernel must remain

ΔP
1,L
	​

=ΔP
1,MS
	​

−[F
1
	​

,ΔP
0
	​

]+b
0
	​

F
1
	​

,
	​

(14)

with all quantities converted to the same coupling convention. The commutator and beta-function terms follow from the scheme transformation of the evolution equation. 
arXiv

Reuse the engine, not the bare-coupling interpretation

For the finite pass, supply

K
F
[0]
	​

=I,K
F
[1]
	​

=−F
1
	​

,K
F
[2]
	​

=F
1
	​

⊗F
1
	​

−F
2
	​

+b
0
	​

L
F
	​

F
1
	​

,

and explicitly disable coupling renormalization:

U
0
	​

=1,U
d>0
	​

=0.

Do not attempt to disable it merely by setting p=0: a source with s>0 would still be renormalized by the rule Z
α
p+s
	​

.

For a physical finite result, this pass needs only the finite parts of C
L
(0,1,2)
	​

, because the finite kernels have no negative epsilon powers. It does not introduce additional Born or NLO positive-epsilon demands.

Positive-epsilon scheme-converted outputs require a declared continuation. Four-dimensional F
1
	​

,F
2
	​

 do not uniquely define the ϵ
1
,ϵ
2
 extension of the transformed coefficient. You may choose an explicit extension, but do not present it as determined by the physical finite scheme alone. Preserve the raw positive-epsilon objects separately for future counterterm use.

For arbitrary user schemes, declare the operator direction. If

f
new
	​

=Ff
old
	​

,D
new
	​

=HD
old
	​

,

then

C
new
	​

=F
−T
C
old
	​

H
−1
.

Same-leg transformations must compose in their actual noncommuting order. Different-leg products are already handled by your multi-leg enumeration. The conventional polarized conversion does not alter the unpolarized FF. 
arXiv

Recommended final acceptance tests

Your existing explicit-species, noncommuting-matrix test already addresses the most difficult combinatorial issue. Add three focused checks:

Check	Failure it detects
Equations (1) and (3), with an arbitrary source normalization 1+c
1
	​

ϵ+c
2
	​

ϵ
2
+⋯	Lost Born factors, wrong UV exponent, double-counted same-leg insertions
Exact scale equation (7), plus expansion (6)	Wrong unequal-scale beta term or misplaced η
A two-leg Laurent chain with known B
2
	​

, and finite-scheme round trip F
−1
F=I+O(a
3
)	Premature intermediate truncation and incorrect scheme composition

Pole cancellation must be checked for the complete distribution in each physical flavor/charge component—not just at interior kinematics or after taking a moment that annihilates part of the result.

No new normalization patch is indicated. The assembly design is mathematically consistent; its correctness now depends on delivering the corrected RR/RV sources as valid endpoint-expanded Laurent distributions with certified coverage and sufficient source and kernel windows. The same transition engine can then perform both pole subtraction and finite operator conversion, provided those are distinct input stages and the UV operation is disabled in the latter.