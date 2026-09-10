The subtraction is correct, and your verified leading-profile equalities are almost enough to establish the required remainder theorem. The remaining check is not another boundary integration: it is that the contracted, subtracted scalar expression, including its rational coefficient factors, has a convergent normal-crossing representation with integrable exponents in every chart.

Once that is established, the assembly needs exactly the upper orders you propose:

A,B through ϵ
1
,C through ϵ
2
,F
bulk
	​

 through ϵ
0
,

understood as orders of the complete contracted objects, with all lower poles retained. There is no additional corner constant to determine.

1. Define the subtraction before taking Laurent coefficients

Write

p
ϵ
	​

(v)=v
−1−2ϵ

as an ordinary function in the initial convergence domain. Define

a
ϵ
	​

(σ)
b
ϵ
	​

(ρ)
R
ϵ
	​

(ρ,σ)
	​

=A(σ,ϵ)−C(ϵ)p
ϵ
	​

(σ),
=B(ρ,ϵ)−C(ϵ)p
ϵ
	​

(ρ),
=F(ρ,σ,ϵ)−p
ϵ
	​

(ρ)A(σ,ϵ)−p
ϵ
	​

(σ)B(ρ,ϵ)
+C(ϵ)p
ϵ
	​

(ρ)p
ϵ
	​

(σ).
	​

	​

(1)

Then

F=Cp
ϵ
	​

(ρ)p
ϵ
	​

(σ)+p
ϵ
	​

(ρ)a
ϵ
	​

(σ)+b
ϵ
	​

(ρ)p
ϵ
	​

(σ)+R
ϵ
	​

.
	​

(2)

The three required analytic properties are distinct:

a
ϵ
	​

b
ϵ
	​

R
ϵ
	​

	​

 is meromorphic with coefficients locally L
1
(dσ),
 is meromorphic with coefficients locally L
1
(dρ),
 is meromorphic with coefficients jointly L
1
(dρdσ).
	​

	​

(3)

“Locally” here includes the upper physical endpoints ρ=0,σ=0, while remaining bounded away from x=0,z=0. These are conditions on regular distributions represented by locally integrable functions, not on globally smooth functions. 
DLMF

The subtracted edges

A particularly economical sufficient test is

σ
1+2ϵ
A(σ,ϵ)
ρ
1+2ϵ
B(ρ,ϵ)
	​

=C(ϵ)+σA
♯
(σ,ϵ),
=C(ϵ)+ρB
♯
(ρ,ϵ),
	​

	​

(4)

with A
♯
,B
♯
 analytic in their endpoint coordinate and meromorphic in epsilon with controlled finite pole order.

Then

a
ϵ
	​

=σ
−2ϵ
A
♯
,b
ϵ
	​

=ρ
−2ϵ
B
♯
.
	​

(5)

Both are integrable in a neighborhood of ϵ=0. Their Laurent coefficients can contain log
m
σ or log
m
ρ, especially when A
♯
,B
♯
 have epsilon poles. That does not compromise integrability.

If additional generic-epsilon logarithmic terms occur, apply the same test to their full finite logarithmic polynomial. Do not test only the coefficient without logarithms.

2. A particularly small joint-remainder certificate is available here

Let π
j
	​

 be your three charts and J
j
	​

 their absolute density Jacobians. Define

K
j
	​

=J
j
	​

p
ϵ
	​

(ρ∘π
j
	​

)p
ϵ
	​

(σ∘π
j
	​

).

Explicitly,

Chart
1:(ρ,σ)=(r,r
2
t)
2:(ρ,σ)=(r
2
t,r
2
t
2
)
3:(ρ,σ)=(r
2
t,r
2
)
	​

K
j
	​

r
−1−6ϵ
t
−1−2ϵ
2r
−1−8ϵ
t
−1−6ϵ
2r
−1−8ϵ
t
−1−2ϵ
	​

	​

	​

(6)

Now form the normalized subtracted scalar germ

U
j
	​

(r,t,ϵ)=
K
j
	​

J
j
	​

R
ϵ
	​

∘π
j
	​

	​

.
	​

(7)

Suppose the physical exponent selection and the scalar coefficient algebra establish that U
j
	​

 is analytic in r,t at the joint origin, with the epsilon qualifications discussed below. Your full-profile cancellations should then imply

U
j
	​

(0,t,ϵ)=0,U
j
	​

(r,0,ϵ)=0.
	​

(8)

For an analytic germ, these identities imply

U
j
	​

=rtH
j
	​

	​

(9)

with analytic H
j
	​

. This is simply divisibility by both coordinate functions:

(r)∩(t)=(rt)

in the local analytic ring.

Consequently,

J
1
	​

R
ϵ
	​

∘π
1
	​

J
2
	​

R
ϵ
	​

∘π
2
	​

J
3
	​

R
ϵ
	​

∘π
3
	​

	​

=r
−6ϵ
t
−2ϵ
H
1
	​

,
=2r
−8ϵ
t
−6ϵ
H
2
	​

,
=2r
−8ϵ
t
−2ϵ
H
3
	​

.
	​

	​

(10)

All coordinate powers are strictly integrable for sufficiently small ∣ϵ∣. For example, ∣ϵ∣≤1/16 leaves a positive integrability margin for every displayed exponent.

This is stronger and simpler than constructing an arbitrary large remainder jet.

Which data establish the two restrictions?

The restrictions in (8) come from different physical facts:

Chart	r=0 restriction	t=0 restriction
1	Exceptional profile equals CK
1
	​

	Exact ordinary σ=0 edge profile
2	Exceptional profile equals CK
2
	​

	Second exceptional profile equals CK
2
	​


3	Exceptional profile equals CK
3
	​

	Exact ordinary ρ=0 edge profile

Equation (4) makes the edge tails harmless on the exceptional faces. For example, in chart 1,

J
1
	​

p
ϵ
	​

(ρ)a
ϵ
	​

(σ)=r
1−6ϵ
t
−2ϵ
A
♯
(r
2
t,ϵ),

which cannot introduce an integer r
−1
 term. The other tail,

J
1
	​

b
ϵ
	​

(ρ)p
ϵ
	​

(σ)=r
−6ϵ
t
−1−2ϵ
B
♯
(r,ϵ),

is an ordinary-edge term, canceled by the full σ-edge subtraction.

Thus the exceptional matching and the exact ordinary edge profiles have complementary roles. Neither substitutes for the other.

The important remaining guard: inspect scalar coefficient divisors too

A logarithmic connection for the masters is not alone a logarithmic representation of an arbitrary rational linear combination.

For example, a constant master has a perfectly regular DE, but the scalar coefficient

(r+t)
3
r
	​


produces a nonintegrable joint corner. At fixed t>0, it even vanishes as r→0. The non-coordinate divisor r+t invalidates a conclusion based on those separate limits.

Therefore the normal-crossing gate must include:

DE gauge+physical coefficient row+subtraction prefactors.
	​


After collection, every remaining denominator near the chart origin must be a coordinate monomial times a nonvanishing analytic unit, or its cancellation must be established exactly. Your earlier diagonal cancellation should remain part of this scalar-level proof.

If a retained term has another exponent pair, do not force it into (7). Treat it separately as

r
a+bϵ
t
c+dϵ
(logr)
m
(logt)
n
h(r,t,ϵ),

and verify strict integrability after its required divisor jets have been removed.

3. What “removal of all nonintegrable divisor jets” must mean

Yes: removing all such jets in both coordinate directions is sufficient once a convergent, compatible normal-crossing representation is established. It means coefficient-function identities, not checking a few values of the ratio variable.

For

r
a+bϵ
t
c+dϵ
h(r,t,ϵ),

choose the smallest integers N
r
	​

,N
t
	​

≥0 satisfying

a+N
r
	​

>−1,c+N
t
	​

>−1.

Prove

∂
r
j
	​

h(0,t,ϵ)=0(0≤j<N
r
	​

),

and

∂
t
j
	​

h(r,0,ϵ)=0(0≤j<N
t
	​

).

Then

h=r
N
r
	​

t
N
t
	​

h
.

For your simple-pole situation, N
r
	​

=N
t
	​

=1, giving (9).

If logarithmic Frobenius blocks are present, perform this test on every coefficient of the generic-epsilon logarithmic polynomial. A value such as rlogr→0 does not justify omitting a logarithmic coefficient from the endpoint algebra.

These are finite checks despite being function identities

Use the boundary maps and tangential DEs to establish each restriction. A residual row q(t,ϵ)b(t,ϵ) can be tested by closing

q⟼∂
t
	​

q+qA
t
	​


and checking the corresponding finite normalized initial data. You already have this machinery and the two physical constants.

There is no need to:

expand every GPL in the ratio variable;

sample a dense set of ratio values;

compute many subleading radial coefficients after the exact leading restriction has vanished.

For the current simple-pole class, the expensive part—the full leading profiles—has already been computed.

Convergence is an additional statement beyond formal recurrence identities

Use the exact logarithmic normal form and analytic coefficient units to obtain a convergent Frobenius majorant on a smaller polydisc. Formal normal-crossing algorithms alone should not be cited as a uniform remainder proof; the formal and convergent statements are distinct. 
arXiv
+1

A sufficient result is

∣ϵ
p
J
j
	​

R
ϵ
	​

∘π
j
	​

∣≤Mr
η
r
	​

t
η
t
	​

(1+∣logr∣+∣logt∣)
L
,η
r
	​

,η
t
	​

>−1,
	​

(11)

uniformly in a small epsilon neighborhood, with the finite explicit pole order p recorded.

You do not necessarily need a numerical value of M. Exact nonvanishing-unit checks, a common analytic neighborhood, and the normalized recurrence bounds establish its existence.

Cover the rest of each boundary collar by compact ordinary ratio intervals. In particular, chart 2 needs the t=0 collar up to its r=1 seam, not just the corner r=t=0. Use the physically regular grouped expression at removable seams; a singular auxiliary gauge must not create a spurious seam counterterm.

Parameter uniformity deserves one explicit guard

Coordinate analyticity at each fixed epsilon is not, by itself, finite-order meromorphy in epsilon. The elementary equation

∂
r
	​

Y=ϵ
−1
Y,Y(0)=1

has solution e
r/ϵ
.

For your physical solution, either use the existing epsilon-regular frame, or establish that the normal-form coefficients have a finite meromorphic pole envelope and uniform convergence on a small epsilon contour.

There is an economical alternative when finite-order distributional meromorphy is already proved. If the continued remainder on a small pole-free circle ∣ϵ∣=δ has a common L
1
 majorant, its Cauchy Laurent coefficients are L
1
 functions. The known distributional pole bound forces all sufficiently negative coefficients to vanish; injectivity of L
1
 into distributions then gives an L
1
-valued meromorphic family. This avoids estimating epsilon valuations of infinitely many normal Taylor coefficients.

That argument still requires the contour values to be the continuation of the original subtracted family, not merely an independently chosen interior function.

4. No later physical sector can appear from an analytic prefactor

With your complete physical germ already matched, a compatible local fundamental form is schematically

I=G(r,t,ϵ)H(r,t,ϵ)r
R(ϵ)
t
T(ϵ)
c
phys
	​

(ϵ).

The analytic factor H shifts integer powers and mixes master components. It cannot generate a new primary exponent class whose amplitude was exactly set to zero by the complete germ.

Therefore:

A genuinely excluded primary sector stays excluded at every Taylor order.

Higher integer coefficients in an allowed sector can populate many master rows.

Integer poles from G or the physical coefficient matrix must still be included before deciding that a term is subleading.

Generic-epsilon Jordan logarithms remain if the physical seed has a nonzero nilpotent component.

If your selected physical residues have no such nilpotent component and the analytic normal form exists, logarithms produced later by expanding

r
bϵ
t
dϵ

are not new physical modes. They preserve the strict integer-power integrability obtained in (10).

Conversely, a check that only the leading raw value belongs to a selected sector would be insufficient. Your premise is the stronger complete normalized-germ selection, which is what licenses this conclusion.

5. The final distribution algebra is simpler than a sector pushforward

Once (3) is established, define the canonical one-dimensional continuation

P
ϵ
	​

(v)=−
2ϵ
δ(v)
	​

+
m=0
∑
∞
	​

m!
(−2ϵ)
m
	​

D
m
	​

(v),D
m
	​

(v)=[
v
log
m
v
	​

]
+
	​

,
	​

(12)

with the plus prescription referenced to [0,1].

The exact meromorphic assembly is then

T
ϵ
	​

=C(ϵ)P
ϵ
	​

(ρ)⊗P
ϵ
	​

(σ)+P
ϵ
	​

(ρ)⊗Reg(a
ϵ
	​

)+Reg(b
ϵ
	​

)⊗P
ϵ
	​

(σ)+Reg(R
ϵ
	​

).
	​

(13)

The charts are now proof infrastructure only. There is no need to export chart distributions or integrate exceptional angular profiles to determine an additional contact coefficient.

An L
1
 tangential factor is enough

For example,

⟨P
ϵ
	​

⊗a
ϵ
	​

,ϕ⟩=
	​

−
2ϵ
1
	​

∫dσa
ϵ
	​

(σ)ϕ(0,σ)
+∫dσa
ϵ
	​

(σ)∫
0
1
	​

dρρ
−1−2ϵ
[ϕ(ρ,σ)−ϕ(0,σ)].
	​

	​

(14)

The inner subtraction is uniformly controlled by a normal derivative of the smooth test function. The outer integral needs a
ϵ
	​

∈L
1
, not differentiability of a
ϵ
	​

 at σ=0.

Thus

D
m
	​

(ρ)⊗log
k
σ

is legitimate. There is no need to evaluate log
k
σ at zero. Tensor-product distribution theory permits precisely this separation of variables. 
DLMF

Your warning about JointlySmoothFactors is therefore correct. The tangential coefficient is a regular distribution, not a jointly smooth multiplier to which arbitrary endpoint restrictions may be applied.

Do not apply a second tangential plus operation to a
ϵ
	​

 or b
ϵ
	​

. Their singular corner part has already been extracted into CP
ϵ
	​

⊗P
ϵ
	​

.

Why no hidden contact term remains

Without a continuation prescription, interior data can leave distributions supported on the edges or corner undetermined. 
arXiv

Here the prescription is fixed. Establish (2) as an equality of ordinary integrable densities in the common high-D domain supplied by your joint certificate. Continue every term with its inherited branch and normalization.

The L
1
-meromorphic remainder has no atomic Laurent coefficients. Equality in the initial open regulator domain therefore fixes (13) uniquely. Adding a separate corner delta would violate that initial equality.

This proves equality of the extensions; it does not assert that the physical answer has no corner delta. The latter is already generated by the first term of (13).

Keep the full [0,1] plus convention. Introducing cutoffs or redefining a plus distribution on a shorter interval shifts finite edge/corner terms and must be accounted for explicitly.

6. The proposed epsilon windows are sufficient

Let

C(ϵ)=
k
∑
	​

ϵ
k
C
k
	​

,a
ϵ
	​

=
k
∑
	​

ϵ
k
a
k
	​

,b
ϵ
	​

=
k
∑
	​

ϵ
k
b
k
	​

.

The Laurent coefficients a
k
	​

,b
k
	​

 are L
1
 functions under the preceding proof.

For finite output:

Contribution	Required upper epsilon order
CP
ϵ
	​

⊗P
ϵ
	​

	C
2
	​


P
ϵ
	​

⊗a
ϵ
	​

	a
1
	​


b
ϵ
	​

⊗P
ϵ
	​

	b
1
	​


Reg(R
ϵ
	​

)	R
0
	​


Thus raw A,B through ϵ
1
, together with C through ϵ
2
, suffice to construct the subtracted edges. Bulk F
0
	​

 and the corresponding pointwise subtraction coefficients suffice for R
0
	​

, because the remainder has already been proved L
1
-meromorphic.

These orders are for the fully normalized, physically contracted quantities. A hidden factor 1/ϵ
q
 outside A,B,C changes the demands on its children. Your omitted-order API should continue to handle that.

For clarity, the finite coefficient of (13) is

[T
ϵ
	​

]
0
	​

=
	​

4
C
2
	​

	​

δ
ρ
	​

δ
σ
	​

−
2
1
	​

[δ
ρ
	​

a
1
	​

(σ)+b
1
	​

(ρ)δ
σ
	​

]+R
0
	​

+
m≥0
∑
	​

m!
(−2)
m
	​

[D
m
	​

(ρ)a
−m
	​

(σ)+b
−m
	​

(ρ)D
m
	​

(σ)]
−
m≥0
∑
	​

2m!
(−2)
m
C
1−m
	​

	​

[δ
ρ
	​

D
m
	​

(σ)+D
m
	​

(ρ)δ
σ
	​

]
+
m,n≥0
∑
	​

m!n!
(−2)
m+n
C
−m−n
	​

	​

D
m
	​

(ρ)D
n
	​

(σ).
	​

	​

(15)

The sums are finite because the source Laurent series have finite lower bounds.

This shows why the upper demands remain 1,1,2, even when A,B,C have poles. Those lower poles instead increase the maximum plus-log index appearing in the finite answer. They must not be dropped.

Apply the same convolution of Laurent coefficients to all pole orders required for the final RR+RV+VV+counterterm cancellation. The interior numerical cancellation is a useful check, but it does not test the supported coefficients in (15).

7. A general stratified representation

A reusable internal object can have the structure

Wolfram Language
StratumTerm[
  NormalVariables -> {...},
  NormalKernels -> {...},
  TangentialCoefficient -> L1MeromorphicCoefficient[...],
  NormalizationDomain -> {0, 1},
  IntegrabilityCertificate -> certificate
]

For the present result, store four components:

Normal variables
{ρ,σ}
{ρ}
{σ}
∅
	​

Kernel
P
ϵ
	​

(ρ)⊗P
ϵ
	​

(σ)
P
ϵ
	​

(ρ)
P
ϵ
	​

(σ)
1
	​

Tangential coefficient
C
a
ϵ
	​

(σ)
b
ϵ
	​

(ρ)
R
ϵ
	​

(ρ,σ)
	​

	​


The coefficient record should contain the finite epsilon pole bound, known upper window, chartwise integrability margins, and permitted operations. In particular, an L1MeromorphicCoefficient should not automatically permit endpoint evaluation or tangential differentiation.

For more measured variables, this becomes a sparse collection indexed by faces. Normal kernels use the existing monomial moment engine; coefficients are independently certified L
1
 distributions in the remaining coordinates. The intersection coefficients must be fixed by the same inclusion–exclusion convention, not inferred by evaluating an L
1
 coefficient at a point.

8. Three inexpensive final regressions
Test	What it detects
Divide an analytic U(r,t) with U(0,t)=U(r,0)=0 by rt, then compare the chartwise bound	Correct joint divisor cancellation, rather than separate fixed-ratio limits
Use r/(r+t)
3
 multiplying a constant master	Ensures the scalar-coefficient divisor check is not replaced by the master-DE check
Use logarithmically nonsmooth L
1
 edge coefficients	Ensures the tensor engine does not invoke invalid corner restrictions

For the last test, take

C=1,a
ϵ
	​

(σ)=σ
−ϵ
logσ,b
ϵ
	​

(ρ)=ρ
−ϵ
logρ,

and

R
ϵ
	​

=ρ
−ϵ
σ
−ϵ
logρlogσ.

The exact constant-test-function moment is

∫
0
1
	​

dρdσF
ϵ
	​

=
4ϵ
2
1
	​

+
ϵ(1−ϵ)
2
1
	​

+
(1−ϵ)
4
1
	​

.
	​

(16)

Its finite term is 3. Equation (15) must reproduce it without assigning a value to logσ or logρ at zero.

Recommendation

Proceed with the subtraction, but make the acceptance condition the vanishing of the full nonintegrable face restrictions of the subtracted scalar germ. In your present one-branch situation, the most economical certificate is exactly

U
j
	​

∣
r=0
	​

=U
j
	​

∣
t=0
	​

=0⟹U
j
	​

=rtH
j
	​

,

followed by the explicit integrable weights in (10) and a convergent, parameter-controlled remainder.

Once those checks pass on the joint corners and the remaining boundary collars, the output is (13)–(15). The already available bulk GPL expression supplies the ordinary remainder after subtraction; the existing edge GPLs and corner Gamma data supply every supported term. No new physical boundary constant, sector integral in the export, or reference-derived normalization is needed.