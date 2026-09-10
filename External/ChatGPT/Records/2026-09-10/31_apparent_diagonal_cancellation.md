# GPT-6 Pro review: apparent diagonal cancellation

Verified model: gpt-6-pro. Conversation: 6aa0f5dd-de10-83e8-b032-74f47d77da2a.

Yes: steps 1–4 provide a sound, non-circular certificate of interior diagonal removability. Step 5 is also achievable, and your regular closed five-master subsystem offers a cheaper route than proving a new general cut-derivative theorem. Express the required external derivatives back in those same five unit-cut masters, then apply the existing joint convergence bound to those weighted combinations.

The distinction to preserve is:

interior diagonal cancellation

=uniform control where the diagonal meets the physical corner.
	​


The first is an exact finite-jet calculation. The second needs a bound, but it need not require new dotted-master evaluations or a general statement about Landau singularities.

1. Specializing the original polynomial IBPs is legitimate—with a restriction check

Let

h=x−z,M
0
	​

(z,D)=M(z,z,D)

for the first five masters.

At an interior diagonal point,

detG(p,q)=−
4z
2
Q
4
	​


=0.

Thus the external Gram matrix creates no obstruction. The linear measurement and particle-cut definitions must still be checked for constant rank there, as must the ordinary denominators.

There are two valid ways to justify the specialized equations:

Restriction of an already established identity. Every integral appearing in the relevant finite set of polynomial IBP rows has a well-defined, sufficiently regular restriction to h=0 in a common high-D domain. Then substituting x=z in the equation is valid.

Direct derivation at specialized kinematics. Substitute x=z in the actual denominator polynomials and cut records, and regard the specialized row as the same loop-total-derivative identity derived directly at that external point. This avoids requiring an off-diagonal limit for every auxiliary integral, but still requires the typed integrals at the specialized point to be defined and the cut-IBP theorem to apply.

The second interpretation is particularly natural for your retained polynomial momentum-IBP rows. Check that specialization commutes with their algebraic construction. It must not change the normal coordinates of particle or measurement cuts.

Polynomial coefficients alone are not enough

A relation

hI
aux
	​

+M
1
	​

=0

cannot be specialized by discarding the first term if I
aux
	​

 has no defined finite restriction and behaves like 1/h. The elementary model

I
aux
	​

=1/h,M
1
	​

=−1

shows the failure.

Consequently, inspect the specialized integral definitions, not just the row coefficients. Reject a required denominator that becomes identically zero, a loss of mandatory-cut rank, or an unsupported coincident-cut definition. Coalescing ordinary denominators can be handled algebraically when their prescriptions permit it; an ordinary denominator and a cut must not silently become the same slot.

Restriction of a distribution to a hypersurface is not automatic merely because its surrounding equation has polynomial coefficients. A high-D ordinary-integral construction, or direct derivation of the specialized cut integral, supplies the needed justification. 
DLMF

Retain the controlled equation source

Use the same config:false user-system path. Kira’s documented user-system mode can solve the supplied equations without using topology definitions; this is the appropriate boundary for keeping unaudited identifications out of this calculation. 
arXiv

Before solving, re-run your exact typed equivalence checks at the diagonal. Some integrals that were distinct generically may become literally identical there. That can expose the desired relations cheaply. Do not, however, infer equivalences only modulo differentiated cut constraints.

Omitting auxiliary DE rows with nonremovable diagonal poles is appropriate. It is conservative: an omitted relation might have a useful higher-jet limit, but it cannot create a false relation. Never specialize the generic solved reduction containing 1/h and treat the result as this independent diagonal calculation.

The output should be an exact witness for

L(z,D)M
0
	​

(z,D)=0,
	​

(1)

not a claim that L contains every possible diagonal relation.

2. The normal-jet recurrence is correct—but specialize only after differentiating

Suppose

∂
x
	​

M=A
x
	​

M.

Define matrices on the two-variable neighborhood by

T
0
	​

=I,
T
n+1
	​

=
n+1
∂
x
	​

T
n
	​

+T
n
	​

A
x
	​

	​

.
	​

(2)

Then

∂
x
n
	​

M=n!T
n
	​

M,

and

M(z+h,z)=
n=0
∑
k−1
	​

h
n
T
n
	​

∣
x=z
	​

M
0
	​

(z)+O(h
k
).
	​

(3)

Your recurrence is therefore correct. The implementation must not evaluate T
n
	​

 on the diagonal and then use a z-derivative as its next ∂
x
	​

-derivative.

For example,

T
1
	​

=A
x
	​

,T
2
	​

=
2
∂
x
	​

A
x
	​

+A
x
2
	​

	​

.

The order of matrix multiplication matters at higher orders.

An alternative that avoids repeated differentiation of already constructed matrices is to expand

A
x
	​

(z+h,z)=
j≥0
∑
	​

h
j
A
j
	​

(z)

and solve the ordinary Taylor recurrence

U
0
	​

=I,U
n+1
	​

=
n+1
1
	​

j=0
∑
n
	​

A
j
	​

U
n−j
	​

.
	​

(4)

Here U
n
	​

=T
n
	​

∣
x=z
	​

. Both constructions should agree exactly.

The diagonal derivative is a different operator

Along the diagonal,

dz
dM
0
	​

	​

=B
Δ
	​

(z,D)M
0
	​

,B
Δ
	​

=(A
x
	​

+A
z
	​

)∣
x=z
	​

.
	​

(5)

This follows from the chain rule, whereas the normal derivative in (2) holds z fixed. 
DLMF

Closing the diagonal relations under

L⟼L
′
+LB
Δ
	​

(6)

can cheaply strengthen the relation space. Its rank is at most five. It is also a useful consistency check on the specialized reduction.

3. Principal-part cancellation is a finite rational row-space test

Expand the coefficient row at generic D:

C(z+h,z,D)=
j=−k
∑
∞
	​

h
j
C
j
	​

(z,D).

For a negative power h
−ℓ
, 1≤ℓ≤k, the complete coefficient is

R
−ℓ
	​

(z,D)M
0
	​

(z,D),R
−ℓ
	​

=
n=0
∑
k−ℓ
	​

C
−ℓ−n
	​

U
n
	​

.
	​

(7)

Therefore

R
−ℓ
	​

=V
ℓ
	​

L
	​

(8)

as an exact rational identity proves that this principal coefficient vanishes. Store the multiplier V
ℓ
	​

, or an equivalent exact elimination witness.

This uses only normal jets through k−1 to prove removability. The value of the regular quotient on the diagonal requires the next jet, through k.

A row-space failure is inconclusive, not evidence that the physical combination is singular. The specialized IBPs may not generate every relation satisfied by the chosen physical solution. In that event, close the relation space under (6), or use the diagonal DE and exact physical boundary amplitudes to test the remaining row. Do not set a residual to zero because low-weight GPL coefficients happen to agree.

An even simpler batched formulation

For each physical coefficient row, set

a
0
	​

(x,z,D)=h
k
C(x,z,D),F(x,z,D)=a
0
	​

M.

After exact cancellation, a
0
	​

 has no h-pole. Define

a
j+1
	​

=∂
x
	​

a
j
	​

+a
j
	​

A
x
	​

.
	​

(9)

Then

∂
x
j
	​

F=a
j
	​

M.

The cancellation test is simply

a
j
	​

∣
x=z
	​

∈rowspanL,j=0,…,k−1.
	​

(10)

This formulation computes exactly the derivative rows needed for the corner bound as well. It involves five-component rational rows, not derivatives of GPL expressions.

Keep all analytic normalization factors either inside F or accounted for through their logarithmic derivatives. A common factor depending only on D,Q
2
 may be kept outside. A factor depending on x,z cannot be ignored when forming (9).

Do not apply L(z)M
0
	​

(z)=0 as though it implied

L(z)M(x,z)=0

away from the diagonal. The relation constrains the boundary data; the normal transport is what determines its off-diagonal consequences.

4. Why steps 1–4 do not yet prove the corner bound

A regular diagonal DE can coexist with an unbounded quotient near the physical corner.

For example,

M
1
	​

=
1−x
1
	​

,M
2
	​

=
1−z
1
	​


form a closed system with no x−z denominator in either connection. On the diagonal,

M
1
	​

=M
2
	​

.

Nevertheless,

x−z
M
1
	​

−M
2
	​

	​

=
(1−x)(1−z)
1
	​

.
	​

(11)

The diagonal pole is removable at every z<1, but the quotient is not jointly integrable at (1,1).

Your actual high-D Gram suppression can rule out this behavior in its convergence domain. The absence of x−z from A
x
	​

,A
z
	​

 cannot do so by itself.

5. The cheapest step-5 proof uses the regular DE and the existing certificate

You need not first establish that every external derivative of every unit-cut master has a globally differentiated cut representation.

For the required finite order, equation (9) already gives

∂
x
k
	​

F=a
k
	​

M
	​

(12)

on the ordinary physical interior.

Because a
0
	​

 and A
x
	​

 have no diagonal pole, none of the a
j
	​

 introduces an x−z divisor. Differentiation can increase powers of their existing divisors, but cannot introduce a new zero set.

This yields a small sufficient procedure:

Construct the exact rows a
0
	​

,…,a
k
	​

.

Interpret each term a
j,i
	​

M
i
	​

 using the original unit-cut definition of M
i
	​

.

Apply the same joint-domain certificate to these weighted unit-cut terms, including their actual coefficient divisors.

Choose one common open high-D domain for this finite collection.

The last step is possible when every new spatial divisor has the already required zero containment on the full Gram boundary. On a compact semialgebraic domain, the corresponding Łojasiewicz inequalities give finite domination exponents. 
arXiv

What bound should the certificate return?

With residual scalar coordinates v in a common bounded box, write the weighted integral as

a
j,i
	​

M
i
	​

=∫dvf
j,i
	​

(x,z,v,D).

A sufficient output is, locally uniformly in D on the common pole-free domain,

∣f
j,i
	​

∣≤C
j,i
	​

(D)Δ
η
j,i
	​

(D)
,ℜη
j,i
	​

>0.
	​

(13)

The strict margin is useful for continuous zero extension across moving Gram boundaries. Integration over the fixed bounded v-box then gives a uniform bound on a
j
	​

M.

For the quotient’s boundedness, a uniform bound on a
k
	​

M is the essential one. Certifying j=0,…,k also supplies an uncomplicated regularity check.

This approach has three advantages:

all final objects remain the same five unit-cut masters;

no new dotted-cut endpoint family is evaluated;

the derivative order is finite and known from the maximum actual diagonal pole.

It is not circular. The DE identity is used only where it is already valid in the interior; the independent physical integral representations provide the uniform bounds on its right-hand side.

You still need the physical solutions to be continuous across an interior diagonal point. A regular matrix A
x
	​

 alone cannot exclude choosing unrelated solutions on the two sides. Your original compact unit-cut representation, with continuous zero extension in a sufficiently high-D domain, supplies that connection. Ordinary-point DE uniqueness then gives the normal derivatives across the diagonal. No general Landau-analyticity claim is needed.

The Taylor remainder proves the grouped bound

From (10),

∂
x
j
	​

F(z,z,D)=0,j<k.

Taylor’s integral remainder therefore gives

(x−z)
k
F(x,z,D)
	​

=
(k−1)!
1
	​

∫
0
1
	​

dt(1−t)
k−1
∂
x
k
	​

F(z+t(x−z),z,D).
	​

(14)

This holds for x>z and x<z. It is a repeated fundamental-theorem-of-calculus identity, with no contour prescription on x−z. Taylor expansion and differentiation under controlled integrals are the applicable tools here. 
DLMF

If

∣∂
x
k
	​

F∣≤B(D)

on the chosen square, then

	​

(x−z)
k
F
	​

	​

≤
k!
B(D)
	​

.
	​

(15)

For x,z∈[a,1), the segment

x
′
=z+t(x−z)

stays in the same square. Consequently, the bound is uniform as x=z=1 is approached from any direction.

At the interior diagonal,

(x−z)
k
F
	​

	​

x=z
	​

=
k!
1
	​

a
k
	​

M∣
x=z
	​

.
	​

(16)

All non-diagonal normalization factors must be included in F or separately bounded. It is not sufficient to bound derivatives of the bare M
i
	​

 and then multiply the result by an uncontrolled factor 1/(1−x)
r
.

The integral in (14) is a proof representation, not a required integral in your exported coefficient. The existing GPL combination can remain the computational expression, with the exact quotient certificate and a stable diagonal evaluation attached to the grouped node.

6. A direct finite-derivative extension of the cut proof is also possible

If you want this as a reusable theorem beyond regular closed subsystems, the direct route is valid under a finite-jet strengthening of the same certificate.

After unit-cut elimination, suppose

f
D
	​

=χ
Ω(x,z)
	​

R(x,z,v,D)Δ(x,z,v)
λ(D)
.

For the required finite derivative order q, record:

a common compact scalar domain and uniformly nonsingular affine cut elimination;

all moving physical boundary strata contained in Δ=0;

uniform Gram-dominance witnesses for all spatial denominators;

bounded smooth coordinate/prefactor coefficients;

exclusion or control of mixed D-kinematic divisors;

the common meromorphic forward-tip convention.

Finite differentiation produces terms whose denominator powers and inverse-Gram powers increase only finitely. Schematically,

∣∂
x,z
α
	​

(RΔ
λ
)∣≤C
α
	​

(D)Δ
ℜλ−K
q
	​

,∣α∣≤q.
	​

(17)

Choose a sufficiently large-ℜD domain where the required interior jets vanish at the moving boundary. A conservative implementation can establish this through order q+1, then justify the C
q
 zero extension.

This is how boundary terms disappear: the relevant weighted traces vanish in the initial convergence domain. It is not the assertion that derivatives of the domain’s theta functions are zero. Distributional differentiation retains boundary terms unless the weighted traces eliminate them. 
DLMF

For the present five-master block, the DE route in section 5 is smaller and avoids expanding those derivatives of the cut graph. The direct theorem can be added later without changing the present certificate.

7. What meromorphic continuation then establishes

In the common high-D domain:

the original prescribed source is an atom-free integrable joint density;

the grouped diagonal quotient has the bounded representation (14);

they agree away from x=z, by the already established exact reduction;

both are therefore equal almost everywhere, hence as joint distributions.

Continue that equality meromorphically in D. It excludes an arbitrary difference supported on the diagonal, the physical faces, or their intersection.

It does not assert that the physical continuation has no endpoint deltas. Genuine δ(1−x), δ(1−z), and corner terms can be generated by continuation; the result is that both representations generate the same ones.

Crucially, certify the group

(x−z)
k
F
	​

.

Do not use the certificate to approve its individually singular summands C
i
	​

M
i
	​

. Those summands can still lack a separate joint extension in your declared scheme.

Likewise, equality is continued from an open D-domain. Agreement at a few D-values or through a few epsilon coefficients does not establish the generic-D cancellation.

8. Minimal implementation order

I would implement this as a general smooth-divisor quotient certificate with two acceptance stages.

Stage	Exact data to record
Interior restriction	Specialized typed definitions, nondegenerate external/cut coordinates, validity of the finite specialized IBP set
Diagonal relation	Exact LM
0
	​

=0 witnesses and any exceptional tangent-parameter denominators
Normal jets	Choice ∂
x
	​

 at fixed z, recurrence (2) or (9), actual pole order k
Principal cancellation	Witnesses for every row in (10), at generic D,z,Q
2

Joint bound	Existing certificate on the finite weighted unit-cut rows representing the required derivatives
Continuation	Original source equality, common open high-D domain, and grouped—not termwise—extension

The efficient execution is:

Form only the actual principal rows or the equivalent a
j
	​

∣
x=z
	​

.

Ask the specialized Kira system to prove those combinations zero; a complete diagonal reduction of unrelated targets is unnecessary.

Close L under (6) if the first row space is insufficient.

Generate the highest required derivative rows and pass them to the existing joint certificate.

Preserve the grouped quotient for weighted endpoint extraction.

For a general smooth divisor g=0, replace ∂
x
	​

 by a declared transverse vector field V satisfying Vg=1. The proof also needs its local normal flow to remain in the physical chart, with bounded coefficients. The diagonal’s straight segment has this property automatically on a square; an arbitrary divisor meeting a physical corner may require a different local cover.

Two inexpensive regressions

Use

f
λ
	​

(t)=(1−t)
λ
.

Test both

x−z
f
λ
	​

(x)−f
λ
	​

(z)
	​


and

(x−z)
2
f
λ
	​

(x)−f
λ
	​

(z)−(x−z)f
λ
′
	​

(z)
	​

.

They verify the factorials, normal/tangential distinction, and diagonal limits. Their first and second derivative bounds are uniform in suitable domains ℜλ>1 and ℜλ>2.

Then set λ=−1 in the first example. The diagonal cancellation must still pass, but a claim of a bounded corner remainder must fail, reproducing (11). This tests that the two acceptance stages have not been conflated.

Recommendation: proceed with the specialized polynomial-IBP cancellation test, and use the regular five-master DE to certify the finite derivative combinations needed by the Taylor remainder. That is a general, exact way to remove the apparent diagonal singularity without another basis search, a GPL identity campaign, or an uncontrolled analyticity assumption. The subsequent weighted corner analysis remains necessary to compute the uniquely defined physical endpoint distributions.