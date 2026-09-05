Verdict: GO, but transpose the proposed exact interpolation

The mathematically sound target is correct: reconstruct only the demanded Hermite primitive/remainder data, not the unused matrix or the original source expression.

The fastest exact route supported by the measurements is not to evaluate the 423,816-operation circuit repeatedly at fixed u over Q(ϵ). Instead:

fixed exact ϵ⟶source in Q(u)⟶exact Hermite reduction in u⟶interpolate the small outputs in ϵ.
	​


That uses the only characteristic-zero coefficient ordering already measured to complete in a controlled time. Fixed-u evaluation over Q(ϵ) is mathematically valid, but its relevant runtime has not been established, and it risks reproducing the rational-in-ϵ coefficient swell that defeated both nested symbolic orderings.

The current package’s rational-layer code already implements the required finite-dimensional Hermite normal forms: repeated-pole primitive denominators, squarefree remainders, polynomial primitives, and—in the quartic channel—the three residual classes 1,u,u
2
. It also rejects poles on the quartic branch divisor rather than silently applying the nonbranch ansatz.

A scope limitation: the four newly named paths in the prompt were not retrievable from the accessible public main; I therefore could not audit their current uncommitted line-level implementation. I inspected the current public rational-layer reducer and CF303JunctionRebase.wl. The latter indeed performs only sparse selector convolution and metadata rebasing; it does not construct the missing H(2p) action.

1. Recommended exact reconstruction route

For each demanded source component, write the Hermite decomposition schematically as

ω(u,ϵ)=d
u
	​

H(u,ϵ)+K(u,ϵ),H(u
b
	​

,ϵ)=0,u
b
	​

=
2
1
	​

.

For the quartic channel Y
2
=P
4
	​

(u),

f(u,ϵ)
Y
du
	​

=d(g(u,ϵ)Y)+K
ell
	​

(u,ϵ).
Primary route: exact ϵ-slices

At generic rational values ϵ=ϵ
i
	​

:

Evaluate every demanded deferred source entry in Q(u). Parse the postfix circuit once and reuse it for all ϵ
i
	​

.

Apply exact rational and quartic Hermite reduction in u.

Normalize the primitive at u
b
	​

=1/2.

Express every output in a fixed, nonreduced denominator and kernel basis independent of ϵ
i
	​

.

Interpolate only the resulting small coefficient vectors as rational functions of ϵ.

This eliminates interpolation in u completely. It also makes each exact slice a full rational function of u, so the Hermite identity can be tested as a rational-function identity at that slice rather than only at isolated u-points.

Secondary route: modular known-denominator collocation

If the proven regulator degree requires too many exact ϵ-slices, use the existing finite-field circuit:

(u,ϵ,q)↦ω(u,ϵ)modq

and solve the same finite Hermite ansatz modulo q. Reconstruct only the primitive and remainder coefficients across primes. Do not reconstruct the original source rational function.

This is preferable to fixed-u characteristic-zero evaluation because:

all expensive DAG operations stay in machine-word finite fields;

the Hermite system is small and shared by multiple matrix entries;

the exact denominator and support remove the adaptive degree ladder;

the accepted two-prime evaluator already supplies the end-to-end recurrence and basis-transformation comparison.

Fixed-u exact interpolation

It remains a valid fallback. Let

M(ϵ)x(ϵ)=b(ϵ)

be the collocation system, where x contains the primitive and remainder numerator coefficients. It is exact if the support below is exhaustive and M has full column rank over Q(ϵ).

It should not be the first production implementation unless one fixed-u Q(ϵ) evaluation demonstrates a substantial advantage over the measured 66-second fixed-ϵ Q(u) image.

2. Exact support bounds

No empirical total-degree shell is needed. The Hermite normal form gives the finite support.

Rational channel

Let the reduced source denominator in u be D, considered over the generic coefficient field Q(ϵ), and define

D
rep
	​

=gcd(D,∂
u
	​

D),D
sf
	​

=
D
rep
	​

D
	​

.

For a proper rational input, use

H
rat
	​

=
D
rep
	​

A
	​

,deg
u
	​

A<deg
u
	​

D
rep
	​

,

and

K
rat
	​

=
D
sf
	​

B
	​

du,deg
u
	​

B<deg
u
	​

D
sf
	​

.

Equivalently, decompose B/D
sf
	​

 into the declared root-free factor kernels

q
i
	​

(u)
u
k
du
	​

,0≤k<degq
i
	​

.

If the original input has a polynomial quotient of degree d
∞
	​

, include a polynomial primitive of degree at most d
∞
	​

+1.

Elliptic channel

Assume

gcd(D,P
4
	​

)=1.

Then use

g(u,ϵ)=
D
rep
	​

A
ell
	​

	​

+P
ell
	​

(u,ϵ),deg
u
	​

A
ell
	​

<deg
u
	​

D
rep
	​

,

and

K
ell
	​

=[
D
sf
	​

B
ell
	​

	​

+c
0
	​

+c
1
	​

u+c
2
	​

u
2
]
Y
du
	​

,deg
u
	​

B
ell
	​

<deg
u
	​

D
sf
	​

.

If the polynomial quotient of the input has degree d
∞
	​

, the polynomial part of g requires degree at most

d
∞
	​

−3

when d
∞
	​

≥3. This is the complete quartic infinity basis currently encoded by the package, including the second-kind u
2
 class.

If gcd(D,P
4
	​

)

=1, refuse this ansatz. Branch-point poles require a different local reduction.

Primitive normalization

Do not add an unconstrained constant to H. Either impose

H(
2
1
	​

,ϵ)=0

as one linear condition, or parameterize

H(u,ϵ)=
H
(u,ϵ)−
H
(
2
1
	​

,ϵ)

from the start.

For a pair-valued primitive

H
=h
0
	​

+h
1
	​

Y,

the subtraction is

H(u)=h
0
	​

(u)−[h
0
	​

(u
b
	​

)+Y
b
	​

h
1
	​

(u
b
	​

)]+h
1
	​

(u)Y(u).

The current reducer follows this convention before computing endpoint values.

3. Regulator degree and sample count

A fitted degree is not a proof. The cleanest proof uses a known regulator clearing denominator.

Let Q
ϵ
	​

(ϵ) be a proven common denominator for the demanded Hermite coefficients, and suppose

deg
ϵ
	​

(Q
ϵ
	​

c
j
	​

)≤d
j
	​


for every scalar output coefficient c
j
	​

(ϵ). Then

N
ϵ
	​

=1+
j
max
	​

d
j
	​

	​


generic exact ϵ-images determine all coefficients. They can all use the same Newton or Vandermonde interpolation matrix.

One additional exact ϵ-image may be held out as an implementation discriminator. It is not mathematically necessary once the degree bound and full-rank interpolation are proved.

If only entrywise rational bounds are known,

degP
j
	​

≤n
j
	​

,degQ
j
	​

≤d
j
	​

,Q
j
	​

(0)=1,

then the minimum generic count is

N
ϵ
	​

=
j
max
	​

(n
j
	​

+d
j
	​

+1).
	​


A proven Q
ϵ
	​

 is preferable because it converts reconstruction to polynomial interpolation and lets all outputs share one multi-right-hand-side solve.

What must enter Q
ϵ
	​


It must include any regulator factors coming from:

the deferred source coefficients;

prior H
n−1
	​

 terms in

B
n
	​

+DH
n−1
	​

−H
n−1
	​

S;

leading coefficients used to make the u-denominators monic;

discriminants, resultants, or small Hermite-system determinants when the pole factors themselves depend on ϵ.

If the quartic, pole factors, and Hermite basis are ϵ-independent, the Hermite map is Q(ϵ)-linear and introduces no new regulator singularities beyond those already present in its input coefficients. That is the favorable case.

A denominator merely observed on several modular images is a candidate, not a proof of the bound. A conservative nonreduced denominator propagated from the exact input circuit is sufficient.

4. Obtaining the boundary action without constructing all of H(u,ϵ)

Yes. There are two levels.

Regular endpoint

If H is regular at u=2p,

H
∂
	​

(p,ϵ)=H(2p,p,ϵ)

is obtained by evaluating the reconstructed numerator and denominator. An expanded rational function is unnecessary; Newton, Lagrange, or arithmetic-circuit form can be evaluated directly.

Singular endpoint

At the soft point, ordinary substitution is generally not the correct object. The required source-to-target boundary action is

H
∂
	​

V
S
	​

=Reg
ρ=0
	​

[H(2p−ρ,p,ϵ)Φ
S
	​

(ρ,p,ϵ)V
S
	​

(p,ϵ)],
	​

(1)

where Φ
S
	​

 contains the required source Frobenius powers, logarithms, and regular jets.

If

H(2p−ρ)=
k=−m
∑
∞
	​

H
k
	​

ρ
k

and the relevant source regular factor is

Φ
S
	​

(ρ)V
S
	​

=
ℓ≥0
∑
	​

V
ℓ
	​

ρ
ℓ

within one fixed exponent/logarithmic sector, the finite term includes

k=−m
∑
0
	​

H
k
	​

V
−k
	​

.
	​


Thus a pole of order m requires source jets through order m. The same operation is performed separately at each logarithmic/Jordan level.

The current public rational-layer implementation directly evaluates the normalized primitive at its endpoint and returns a typed failure if that endpoint lies on a pole. It does not perform the regularized product (1).

Direct endpoint functional

For a collocation system

M(ϵ)x(ϵ)=b(ϵ),

let ℓ
∂
	​

 be the linear functional that extracts either H(2p) or the regularized jet combination (1). Instead of recovering every component of x, solve

M(ϵ)
T
y(ϵ)=ℓ
∂
T
	​

.

Then

H
∂
	​

=y(ϵ)
T
b(ϵ).
	​


This is the smallest route when only the junction action H
∂
	​

V
S
	​

 is required. Multiple source-mode columns are handled as multiple right-hand sides.

The full H(u,ϵ) still needs reconstruction only for entries that enter the generic bulk relation

F
25
	​

=G
25
	​

+HF
S
	​

.
5. Boundary embedding and tangential closure

Let

F=(
F
S
	​

F
25
	​

	​

),G=(
F
S
	​

G
25
	​

	​

),F
25
	​

=G
25
	​

+HF
S
	​

.

Then

F=U
H
	​

G,U
H
	​

=(
I
H
	​

0
I
	​

).

If

B
G
	​

=(
V
S
	​

V
G
	​

	​

)

is the boundary-mode embedding in the G basis, then

B
F
	​

=U
H
	​

B
G
	​

=(
V
S
	​

V
G
	​

+HV
S
	​

	​

).
	​

(2)

So the displayed block orientation is correct.

At a singular boundary, however, the second line of (2) must mean the regularized action (1), not independent substitution of H(2p) and V
S
	​

(0).

Tangential derivative

Let

A=A
p
	​

dp+A
z
	​

dz,z=2p,ρ=2p−z.

The derivative tangent to the soft stratum, equivalently at fixed ρ, is

∂
p
	​

	​

ρ
	​

=∂
p
	​

	​

z
	​

+2∂
z
	​

	​

p
	​

.
	​


Therefore the pulled-back ambient connection is

A
∥
	​

=A
p
	​

+2A
z
	​

.

If the boundary functions obey

dp
dc
	​

=Ωc

and F
∂
	​

=B
F
	​

c, then

(A
p
	​

+2A
z
	​

)B
F
	​

−
dp
dB
F
	​

	​

−B
F
	​

Ω=0
	​

(3)

is correct.

Here dB
F
	​

/dp must be the total derivative after restriction to z=2p. In particular,

dp
d
	​

H(2p,p)=∂
p
	​

H+2∂
z
	​

H

and it must differentiate the p-dependent base normalization

−
H
(1/2,p)

as well.

Basis conditions

Equation (3) is valid only when:

A
p
	​

,A
z
	​

 and B
F
	​

 are all in the same F basis;

V
G
	​

 is genuinely the target embedding in the G basis and has not already been shifted by HV
S
	​

;

Ω acts on the boundary-coordinate columns with the convention c
′
=Ωc;

all moving-basis derivatives are included.

If the embedding is instead in the physical basis

I
25
	​

=T
25
	​

F
25
	​

,

then use

B
I
	​

=T
25
	​

B
F
	​


and the correspondingly transformed ambient connection. Applying T
25
	​

 to the selector while retaining the F-basis A
p
	​

,A
z
	​

 would be a basis mismatch.

The current CF303JunctionRebase.wl only convolves the stored source and target selector decks and labels the target representation as G
25
	​

; it does not perform the H
∂
	​

V
S
	​

 conversion.

Smallest implementation sequence

Freeze the Hermite normal-form layout
from the exact primitive/remainder denominators, including polynomial and quartic cohomology terms.

Derive a conservative exact Q
ϵ
	​

 and numerator-degree bounds.
Refuse interpolation if these remain empirical only.

Run two exact fixed-ϵ Q(u) images as the physical pilot.
Parse the DAG once and reduce all demanded entries per image.

Proceed with exact ϵ-slice interpolation when:

the Hermite layout is identical at both generic images;

the declared denominator specializes without degree loss;

the full required image count is modest—approximately twelve or fewer is a reasonable operational cutoff.

Otherwise use modular known-denominator reconstruction of the same small output coefficient vectors.

Construct the endpoint action separately as the regularized functional (1), preferably through a transposed solve if the full H entry is not required in the bulk.

Acceptance
should be the existing fresh-prime normal-factor evaluation after replacing the reconstructed node. It must compare the defining Hermite equation, H(1/2)=0, the recurrence, and the final T
25
	​

 combinations. If the existing test already covers those identities, no additional production test is needed.

Refusal conditions

Stop this route for a component when:

a source or primitive denominator shares a factor with P
4
	​

;

the generic denominator multiplicity changes across admissible ϵ-images;

the normalized Hermite system remains rank-deficient after imposing H(1/2)=0;

a reconstructed coefficient lies outside the proven regulator denominator or degree bound;

the endpoint requires a pole order beyond the available source Frobenius jets;

the first unused-prime defining-equation replay is nonzero.

Final recommendation: use exact fixed-ϵ Q(u) Hermite images as the primary characteristic-zero route. The fixed-u Q(ϵ) interpolation is mathematically valid, but it is not the best-supported computational direction. The only new endpoint object needed for the tangential system is the regularized action H
∂
	​

V
S
	​

, not a dense materialization of H(u,ϵ).