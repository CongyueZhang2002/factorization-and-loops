Your weak square-root estimate is correct and sufficient for local joint L
1
 control. All the powers and numerical factors you list are correct; in the remainder, the edge-tail contributions carry minus signs. The new epsilon-regular normalization also supplies the missing route to a uniform meromorphic bound—provided the scalar coefficient rows, not just the connections, satisfy that bound in the joint (r,t,ϵ) local ring.

You do not need the stronger claim that the normalized A-edge is analytic in σ. Analyticity in 
σ
	​

, with the resulting half-power integrability margin, is enough. The outstanding work is confined to the boundary collars and seams, plus linking this local representation to the original jointly continued source.

1. What your epsilon-regular normalization establishes

Write a normalized chart system as

r∂
r
	​

Y=A(r,t,ϵ)Y,t∂
t
	​

Y=B(r,t,ϵ)Y.

Your checks establish that A,B are holomorphic near (0,0,0), with commuting corner residues

R(ϵ)=A(0,0,ϵ),T(ϵ)=B(0,0,ϵ).

Nilpotence of R(0) and T(0) eliminates the positive-degree resonance obstruction. For example, the analytic-normalizer recurrence contains

nI−ad
R(ϵ)
	​

,n=1,2,….

At ϵ=0, its inverse is a finite sum:

(nI−ad
R(0)
	​

)
−1
=
j=0
∑
N
R
	​

−1
	​

n
j+1
ad
R(0)
j
	​

	​

,

where N
R
	​

 is any nilpotency bound for ad
R(0)
	​

.

For finitely many small n, these inverses remain holomorphic after shrinking the epsilon disc. For sufficiently large n, a uniform Neumann-series estimate gives an O(1/n) bound. Together with the analytic coefficient bounds and exact compatibility, this gives the convergent, epsilon-holomorphic normalizer on a smaller common polydisc. This is the convergent recurrence argument, not merely an appeal to a formal normal-crossing algorithm. The formal compatibility problem and the convergent Frobenius statement should remain distinct in the proof record. 
arXiv
+1

Your exact physical seed eigenvalue equations then remove generic-epsilon logarithmic seed terms. Taylor corrections from the normalizer do not introduce new primary exponent classes. Epsilon expansion of the retained scalar powers still produces logarithms, but those are controlled by the same power bounds below.

One important remaining interpretation of “Laurent lower bound −3”

What you need is

ϵ
3
Q
j
	​

(r,t,ϵ) holomorphic near (0,0,0),
	​

(1)

where Q
j
	​

 now denotes the complete normalized physical scalar germ, including the analytic normalizer and physical boundary constants.

This is stronger than an epsilon valuation at fixed nonzero r,t, or coordinate analyticity at fixed generic epsilon. For example,

r+ϵ
1
	​


is coordinate-analytic at r=0 for each fixed ϵ

=0, but no finite power of ϵ makes it holomorphic near (r,ϵ)=(0,0).

A simple sufficient check on every collected rational scalar factor is

denominator=ϵ
m
U(r,t,ϵ),U(0,0,0)

=0,

after exact cancellation. Include the scalar row after the epsilon rescaling, its inverse-gauge factors, and the transformed seed. Your connection check alone does not cover those multipliers.

If your stated scalar-germ bound was established in this joint sense, this condition is already satisfied. The fixed Gamma/
3
	​

F
2
	​

 constants only need their established finite meromorphic pole bound on the same sufficiently small disc.

2. The weak edge-tail derivation is exact

To avoid confusing the edge tails with the original profiles, define

p
ϵ
	​

(v)=v
−1−2ϵ
,
a
ϵ
	​

(σ)=A(σ,ϵ)−C(ϵ)p
ϵ
	​

(σ),b
ϵ
	​

(ρ)=B(ρ,ϵ)−C(ϵ)p
ϵ
	​

(ρ).

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

(σ)+R.
(2)

In chart 3,

Q
3
	​

(r,0,ϵ)=r
2+4ϵ
A(r
2
,ϵ).

Since Q
3
	​

(0,0,ϵ)=C(ϵ), analytic divisibility gives

Q
3
	​

(r,0,ϵ)−C(ϵ)=ra
♯
(r,ϵ).

Consequently,

a
ϵ
	​

(σ)=σ
−1/2−2ϵ
a
♯
(
σ
	​

,ϵ).
	​

(3)

Likewise, chart 1 gives

Q
1
	​

(r,0,ϵ)=r
1+2ϵ
B(r,ϵ),

so

Q
1
	​

(r,0,ϵ)−C(ϵ)=rb
♯
(r,ϵ),

and

b
ϵ
	​

(ρ)=ρ
−2ϵ
b
♯
(ρ,ϵ).
	​

(4)

These factorizations are ordinary analytic division by a coordinate. They can equivalently be written as integrals of first derivatives, making the parameter uniformity explicit. 
DLMF

If (1) holds, then

ϵ
3
a
♯
,ϵ
3
b
♯

are holomorphic and bounded on smaller compact polydiscs. Division by r after an exact vanishing identity introduces no new epsilon pole.

Equation (3) is sufficient. Neither analyticity in σ, nor boundedness of a
ϵ
	​

 itself at σ=0, is required. What is required is integrability of its Laurent coefficients.

3. The three remainder formulas, including signs

Define analytic quotient functions by

Q
1
	​

(r,t)−Q
1
	​

(r,0)
Q
2
	​

(r,t)−C
Q
3
	​

(r,t)−Q
3
	​

(r,0)
	​

=rtH
1
	​

(r,t),
=rtH
2
	​

(r,t),
=rtH
3
	​

(r,t).
	​

	​

(5)

The first and third use Q
j
	​

(0,t)=C. The second uses both Q
2
	​

(0,t)=C and Q
2
	​

(r,0)=C.

All are exact generic-epsilon identities. In particular, the 216 finite-order comparisons corroborate them but are not their all-epsilon justification.

Using

K
1
	​

K
2
	​

K
3
	​

	​

=r
−1−6ϵ
t
−1−2ϵ
,
=2r
−1−8ϵ
t
−1−6ϵ
,
=2r
−1−8ϵ
t
−1−2ϵ
,
	​


direct substitution into (2) gives the following.

Chart 1: (ρ,σ)=(r,r
2
t)
J
1
	​

R=r
−6ϵ
t
−2ϵ
H
1
	​

(r,t)−r
−6ϵ
t
−1/2−2ϵ
a
♯
(r
t
	​

).
	​

(6)

The B-tail was removed in forming Q
1
	​

−Q
1
	​

(r,0). The remaining square-root term is exactly the pulled-back A-tail.

Chart 2: (ρ,σ)=(r
2
t,r
2
t
2
)
J
2
	​

R=2r
−8ϵ
t
−6ϵ
[H
2
	​

(r,t)−a
♯
(rt)−rb
♯
(r
2
t)].
	​

(7)

Thus both edge-tail terms subtract. Your factors 2, radial powers, and ratio powers are correct.

Chart 3: (ρ,σ)=(r
2
t,r
2
)
J
3
	​

R=2r
−8ϵ
t
−2ϵ
[H
3
	​

(r,t)−rb
♯
(r
2
t)].
	​

(8)

Again, the remaining B-tail carries a minus sign.

The composition a
♯
(r
t
	​

) in (6) need not be analytic in t at zero. That is harmless: it is bounded and measurable on the real chart, and holomorphic in epsilon. The analytic-ring argument is used for the H
j
	​

 and a
♯
,b
♯
, not falsely applied to their square-root pullbacks.

Explicit integrability margins

Take

0<δ≤
32
1
	​


small enough to lie strictly inside the common holomorphy domain. For ∣ϵ∣≤δ, the worst powers at δ=1/32 are:

Term	Radial power	Ratio power
Chart-1 H
1
	​

 term	−3/16	−1/16
Chart-1 a
♯
 term	−3/16	−9/16
Chart-2 terms	−1/4	−3/16
Chart-3 terms	−1/4	−1/16

The extra factors of r in (7)–(8) only improve these bounds. Every exponent is strictly greater than −1.

Similarly,

∣ϵ
3
a
ϵ
	​

(σ)∣≤Mσ
−9/16
,∣ϵ
3
b
ϵ
	​

(ρ)∣≤Mρ
−1/16
.
	​

(9)

These bounds prove the desired local integrability without the stronger edge-tail statement from the previous review.

A useful sharp regression

The square-root case is not merely a weak estimate that can always be replaced by an integer Taylor estimate. Consider

F=p
ϵ
	​

(ρ)p
ϵ
	​

(σ)[C+
ρ
2
+σ
	​

−ρ].

Its normalized germs are analytic in all three of your charts, with the stated exceptional restrictions, but

a
♯
=1,b
♯
=0,

and

R=p
ϵ
	​

(ρ)p
ϵ
	​

(σ)[
ρ
2
+σ
	​

−ρ−
σ
	​

].

It exercises exactly (6)–(8), including the genuinely necessary half-power edge estimate.

4. The result is L
1
-valued meromorphy, not just termwise integrability

On a smaller chart neighborhood, equations (6)–(9) give a single integrable majorant for

ϵ
3
J
j
	​

R∘π
j
	​


uniformly on the epsilon disc. The integrands are pointwise holomorphic in epsilon for r,t>0, using real logarithms for positive coordinate powers.

Dominated Cauchy integration, or Morera’s theorem followed by Fubini, then shows that

ϵ
3
R
ϵ
	​

 is holomorphic with values in L
loc
1
	​

.
	​

(10)

The analogous statement holds for a
ϵ
	​

,b
ϵ
	​

. Cauchy’s formula supplies the Laurent-coefficient bounds and permits coefficient extraction under the integrals. 
DLMF

Consequently,

R
ϵ
	​

=
k≥−3
∑
	​

ϵ
k
R
k
	​


has R
k
	​

∈L
loc
1
	​

, and truncation through any fixed order has a controlled remainder in the L
1
 norm.

This is stronger than:

pointwise meromorphy at fixed r,t;

integrability for each selected real epsilon;

an O(ϵ
n
) statement valid only away from the endpoint.

The logarithms generated by expanding r
−aϵ
 and t
−bϵ
 are covered automatically. Their fixed-order products remain integrable because the power margins are strict.

An L
1
 Laurent coefficient defines a regular distribution and contains no separate atomic contribution. 
DLMF
 This conclusion concerns R, not the full F: the latter still has the intended edge and corner distributions generated by its explicit normal factors.

5. The remaining collars and seams are real checks, but small ones

Your origin proofs cover neighborhoods of the three joint origins. They do not, by themselves, cover every limiting direction of the original corner.

Chart 2’s r
2
	​

=1 seam

The overlap

r
1
	​

=r
2
2
	​

t
2
	​

,t
1
	​

=r
2
−2
	​


shows that t
2
	​

→0, r
2
	​

≈1 is covered by chart 1 with

r
1
	​

→0,t
1
	​

≈1.

This is the correct use of chart 1 beyond its joint-origin neighborhood.

On a compact positive interval in t
1
	​

, verify the normalized r
1
	​

-connection, physical scalar row, and seed continuation together. After extracting the known radial power, require:

no remaining denominator zero on the collar;

a common epsilon-regular representation;

the same exact leading scalar profile;

uniformly controlled normal Taylor coefficients.

Compactness then turns local analytic bounds into one collar bound. You do not need another physical boundary integration.

The chart-2/chart-3 diagonal seam

The overlap is

r
3
	​

=r
2
	​

t
2
	​

,t
3
	​

=t
2
−1
	​

.

Near t
2
	​

=t
3
	​

=1, all scale factors in this change are positive analytic units.

Your specialized diagonal IBPs and the finite-derivative high-D proof establish removability and fix the continued physical quotient. That is the correct non-circular foundation.

But the high-D bound alone does not establish the small-ϵ, normalized collar bound needed for (10). Use the same exact cancellation inside the epsilon-regular radial representation.

A minimal sufficient check is the following. Put τ=t−1. After extracting the common radial factor, suppose the grouped scalar is

Q(r,τ,ϵ)=
τ
k
N(r,τ,ϵ)
	​

,k≤2.

Verify

ϵ
3
N holomorphic on a common collar,

and

∂
τ
j
	​

N(r,0,ϵ)=0,0≤j<k,
	​

(11)

as exact identities in the remaining variables. Then

Q=
(k−1)!
1
	​

∫
0
1
	​

(1−s)
k−1
∂
τ
k
	​

N(r,sτ,ϵ)ds
	​

(12)

is epsilon-meromorphic and uniformly analytic on a smaller collar.

This is the same finite quotient argument you already implemented, now applied after stripping the known radial powers. It can be checked with the regular five-master subsystem and its scalar rows; it need not be expanded into GPLs.

The distinction matters. For example,

r
2
+(1−t)
2
r
	​


is analytic at the joint origin (r,t)=(0,0) and finite on t=1 for every fixed r>0, but is unbounded near (0,1). The collar check must exclude such a remaining divisor or prove its cancellation. “Removable diagonal at each ordinary point” is not enough.

Specialized IBP validity

Your proposed rank and typed-definition checks are appropriate. Add the existing finite-power convergence/continuation scope for the auxiliary integrals in the specialized witness, where it is not already inherited.

Polynomial rows alone are insufficient if a coefficient vanishing at x=z multiplies an auxiliary integral with no defined restriction there. Direct regeneration of the loop IBPs at the specialized kinematics avoids specializing a solved rational division, but the specialized cut integrals must still have their declared physical definition.

There is no need to establish joint endpoint validity for every intermediate IBP row. Establish the interior diagonal relation from valid specialized integrals, and apply the joint/high-D and epsilon-regular quotient arguments to the final grouped scalar.

Your all-family audit is conservative. Mathematically, only the families and powers actually used by the exact diagonal witnesses need this restriction proof.

6. No additional contact matching is needed once the continuation is linked

After the collars are covered, you have

a
ϵ
	​

, b
ϵ
	​

, R
ϵ
	​


as L
1
-valued meromorphic families on the required physical support. The distributional assembly remains

T
ϵ
	​

=
	​

C(ϵ)P
ϵ
	​

(ρ)⊗P
ϵ
	​

(σ)
+P
ϵ
	​

(ρ)⊗Reg(a
ϵ
	​

)
+Reg(b
ϵ
	​

)⊗P
ϵ
	​

(σ)+Reg(R
ϵ
	​

),
	​

	​

(13)

where

P
ϵ
	​

(v)=−
2ϵ
δ(v)
	​

+
m≥0
∑
	​

m!
(−2ϵ)
m
	​

[
v
log
m
v
	​

]
+
	​

.

The nonsmooth edges are valid tensor factors. The normal plus distribution acts on the smooth test function in its own variable; it does not evaluate a
ϵ
	​

 or b
ϵ
	​

 at their tangential endpoint. Regular distributions and their multivariable actions are defined by exactly this integration against test functions. 
DLMF

Continue to prohibit:

a JointlySmoothFactors interpretation of a
ϵ
	​

 or b
ϵ
	​

;

tangential endpoint evaluation merely because a coefficient is L
1
;

tangential differentiation without a new domain/order check;

a second subtraction of their already removed C-corner component.

The weak estimate changes none of the upper order demands:

A,B:ϵ
1
,C:ϵ
2
,F
bulk
	​

:ϵ
0
,
	​


with the complete lower Laurent tails retained and all quantities physically contracted and normalized.

Where uniqueness enters

Local analytic normal forms and L
1
 bounds alone do not identify an arbitrary interior function with the original cut distribution. The final link is your original prescribed joint high-D equality:

The source and the subtraction are ordinary integrable densities in a common open regulator domain.

Their algebraic decomposition holds there.

The local and collar solutions carry the same fixed physical amplitudes.

Continue that equality meromorphically to the small epsilon disc.

That excludes an additional distribution supported on a face, corner, or artificial seam. It does not eliminate genuine contacts already produced by (13). Uniqueness is the analytic-continuation statement applied after pairing with test functions. 
DLMF

Do not introduce sectorwise contact constants or independently chosen subtraction normalizations while making this link. The disjoint chart cover and the fixed [0,1] plus convention already determine the bookkeeping.

7. The remaining acceptance conditions

The mathematical endpoint construction can now be accepted once these three finite items are attached to it:

Item	Required statement
Joint epsilon pole envelope	ϵ
3
Q
j
	​

, including scalar rows and transformed seeds, is holomorphic in the joint local variables—not merely at fixed coordinates
Collar completion	The same normalized power and epsilon bounds hold on finite covers of the remaining ordinary intervals and removable seams
Physical continuation link	The grouped subtracted expression is the continuation of the original prescribed joint high-D density

The reported residue, scalar-row, and seed checks address the first item substantially. The weak-tail calculation above establishes the local L
1
 result without a separate all-epsilon univariate edge normalization. The seam work you describe addresses the second and third items; its only additional requirement is to retain the small-epsilon uniform bound after the diagonal quotient is removed.

There is no reason to strengthen the square-root edge estimate. The half-power is safely integrable, survives the chart substitutions with the factors in (6)–(8), and supports an L
1
-meromorphic remainder with the same conservative pole envelope. Once the pending collar and source-definition checks are completed, the existing tensor assembler has the right mathematical input class; no new boundary constant or endpoint integration is indicated.