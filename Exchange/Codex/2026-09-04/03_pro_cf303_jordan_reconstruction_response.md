Verdict

GO, but do not reconstruct C(p,ϵ) by unconstrained Padé fitting.

The strongest definition is the pair of exact equations

R
ρ
	​

M=MJ
	​


and

∂
p
	​

J∣
ρ
	​

=[Ω,J].
	​


The first is the normal-residue intertwining equation; it determines C algebraically at each (p,ϵ). The second follows from flatness and determines its p-dependence once one value C(p
0
	​

,ϵ) is known.

For the physical transport, the shortest exact route is even smaller:

Reconstruct C only at one regular tangential base point p
0
	​

, and carry the normal Jordan coupling in the parallel-transported boundary-mode basis.

This preserves every generalized logarithmic chain without constructing a global rational expression for C(p,ϵ). Reconstruct the full rational function only if another package consumer genuinely requires it.

The existing public junction builder already treats nonzero eigenmodes by the relation Bv/(λϵ), retains zero-eigenvalue residue projections separately, and stores the latter only as a finite Laurent deck; it therefore has exactly the all-orders gap described in the question. The committed endpoint frame uses the moving-basis convention

Ω=V
−1
A
∥
	​

V−V
−1
∂
p
	​

V,

which is the convention under which the horizontality equation above holds.

1. Direct defining equations for C(p,ϵ)

Let

R
ρ
	​

(p,ϵ) be the full normal residue in the current source-plus-target basis;

M(p,ϵ) be the leading local mode map from the 13 boundary-function coordinates to the master-integral basis;

E
Z
	​

 select the four inherited zero modes;

E
T
	​

 select the two independent target zero modes;

J
known
	​

 contain the 13 known normal exponents and all already determined Jordan blocks.

Write

J(p,ϵ)=J
known
	​

(p,ϵ)+E
T
	​

C(p,ϵ)E
Z
T
	​

.

The exact normal equation is

R
ρ
	​

(p,ϵ)M(p,ϵ)=M(p,ϵ)J(p,ϵ).
	​

(1)

This is the primary definition. It is independent of any rational-interpolation ansatz.

Projected formula

Let P
tar
	​

 select the two target master rows, and define the 2×2 target homogeneous-mode matrix

U
T
	​

=P
tar
	​

ME
T
	​

.

Assuming U
T
	​

 is invertible, project (1) onto the target rows and the four resonant columns:

C=U
T
−1
	​

P
tar
	​

(R
ρ
	​

M−MJ
known
	​

)E
Z
	​

.
	​

(2)

In the current G
25
	​

 convention, where

the target normal residue is zero;

the target homogeneous columns are the standard 2×2 basis;

the resonant inherited columns have zero target finite part;

this reduces to

C(p,ϵ)=B
−1
	​

(p,ϵ)V
Z
	​

(p,ϵ),
	​

(3)

where V
Z
	​

=M
S
	​

E
Z
	​

 is the 43×4 source zero-mode map and B
−1
	​

 is the source-to-target coefficient of dρ/ρ.

Equation (2), rather than a Padé fit, should be the evaluator used at every modular sample.

Basis dependence

The numerical entries of C depend on the chosen bases of the four source zero modes and two target zero modes:

V
Z
	​

↦V
Z
	​

S
Z
	​

,U
T
	​

↦U
T
	​

S
T
	​

⟹C↦S
T
−1
	​

CS
Z
	​

.

The exact mode ordering and target homogeneous basis must therefore be fixed before reconstruction.

A finite shift of a resonant particular solution by target homogeneous modes,

(
V
Z
	​

0
	​

)↦(
V
Z
	​

U
T
	​

K
	​

),

does not change C: the corresponding lower-triangular shear commutes with the square-zero Jordan block. Thus the FinitePartMatrix -> 0 convention fixes the local mode representatives, but it is not what fixes the residue coupling C.

Tangential defining equation

Because the tangential derivative is taken at fixed

ρ=2p−u,

flatness gives

∂
p
	​

J∣
ρ
	​

=[Ω,J].
	​

(4)

This fixed-ρ qualification is essential; using a fixed-u derivative would omit the coordinate-motion contribution.

Projecting (4) onto the T←Z block gives

∂
p
	​

C=Ω
TT
	​

C−CΩ
ZZ
	​

+K
known
	​

,
	​

(5)

where

K
known
	​

=E
T
T
	​

([Ω,J
known
	​

]−∂
p
	​

J
known
	​

)E
Z
	​

.

If the only relevant known normal data are diagonal and both selected sectors have exponent zero, then normally K
known
	​

=0, giving

∂
p
	​

C=Ω
TT
	​

C−CΩ
ZZ
	​

.

Equation (5), together with (2) at one regular p
0
	​

, uniquely specifies the required horizontal C within the chosen boundary-mode basis. It is the best global reconstruction equation.

2. The eight Laurent coefficients do not determine a rational function

The coefficients from ϵ
−3
 through ϵ
4
 provide eight consecutive terms. Without proven degree bounds, infinitely many rational functions share them. For example, adding

ϵ
5
X(p,ϵ)

for any rational 2×4 matrix X leaves the stored deck unchanged.

A successful Padé fit is therefore not evidence of uniqueness unless the numerator and denominator bounds have been established independently.

Derive the denominator from equation (2)

Use the exact factorized representations of

R
ρ
	​

,M,J
known
	​

,U
T
−1
	​

.

Propagate denominator factors through (2):

multiplication adds factor multiplicities;

addition takes their componentwise maxima/LCM;

the 2×2 inverse of U
T
	​

 contributes its determinant;

exact cancellations may be ignored.

This produces a proven, possibly nonreduced common denominator

Q
C
	​

(p,ϵ)

for all eight entries. A nonminimal denominator is harmless; it converts the problem to polynomial numerator reconstruction.

Do not treat low measured degrees in related transformations as a proof. They are useful initial guesses only.

Normalize the rational function

Separate the known Laurent valuation:

C(p,ϵ)=ϵ
−3
C
(p,ϵ).

After removing all explicit powers of ϵ, normalize the common denominator by either

Q
C
	​

(p,0)=1,

when possible, or by fixing the coefficient of one specified leading monomial in (p,ϵ) to one. Do not use a point-dependent monic normalization that can differ across p-images.

Then write

C
i
	​

(p,ϵ)=
Q
C
	​

(p,ϵ)
N
i
	​

(p,ϵ)
	​

,i=1,…,8.

The numerator support can be bounded by exact degree/support propagation through (2), or by substituting N
i
	​

/Q
C
	​

 into (5) and clearing denominators.

3. Minimum additional information

Let L=8 denote the number of stored coefficients after removing the ϵ
−3
 factor.

Exact denominator known

If Q
C
	​

 is known and

deg
ϵ
	​

N
i
	​

≤n
i
	​

,

the first n
i
	​

+1 Laurent coefficients determine N
i
	​

. Therefore the number of additional construction coefficients needed is

i
max
	​

max(0,n
i
	​

+1−8).
	​

(6)

Then use either:

one additional Laurent coefficient vector; or

one generic nonzero ϵ-evaluation

as an independent held-out test.

Thus the current eight coefficients are already construction-complete if a proven common denominator exists and every numerator has epsilon degree at most seven.

Denominator unknown, entrywise reconstruction

For one entry with bounds

degN
i
	​

≤n
i
	​

,degQ
i
	​

≤d
i
	​

,

and normalized Q
i
	​

(0)=1, one needs

n
i
	​

+d
i
	​

+1
	​


consecutive coefficients for construction, plus at least one held-out coefficient or point. The current additional requirement is

max(0,n
i
	​

+d
i
	​

+1−8).
Unknown denominator shared by all eight entries

A shared-denominator vector Padé problem can require fewer coefficients.

Let the common denominator degree be d, and suppose L
′
 coefficients of every entry are known. The denominator coefficients receive

i=1
∑
8
	​

max(0,L
′
−n
i
	​

−1)

linear constraints. A necessary generic condition is

i=1
∑
8
	​

max(0,L
′
−n
i
	​

−1)≥d,
	​

(7)

and the resulting constraint matrix must have rank d.

The smallest L
′
 satisfying (7) is the minimum series depth for common-denominator reconstruction. One further full coefficient vector should remain held out.

Generic epsilon-point evaluations instead

At fixed p, rational interpolation with one common denominator requires at least

N
ϵ
	​

≥max[
i
max
	​

(n
i
	​

+1),⌈
8
d+∑
i
	​

(n
i
	​

+1)
	​

⌉]
	​

(8)

generic epsilon values, provided the sampled linear system reaches full rank. Add one further epsilon value for validation.

These counts concern epsilon dependence only. Reconstruction in p additionally requires either:

a proven numerator support in p; or

equation (5), which determines the p-dependence from one anchor.

4. Preferred reconstruction algorithm
First choice: residue-intertwining–anchored horizontal solve

Construct a proven common denominator Q
C
	​

(p,ϵ) from equation (2).

Write

C=N/Q
C
	​


with the degree/support bound obtained from the exact arithmetic circuit.

Substitute into the tangential equation (5). After clearing denominators, the result is a linear polynomial system in the coefficients of the eight numerator polynomials N
i
	​

.

Add equation (2) at one generic rational or modular base value p=p
0
	​

. This fixes any homogeneous horizontal freedom left by (5).

Solve the resulting coefficient system over finite fields and lift the numerator coefficients.

This is not Padé interpolation. It is a rational-solution problem for the exact residue/horizontality equations, with interpolation used only as finite-field linear algebra.

Second choice: known denominator, multi-output interpolation

If coefficient matching in (5) is inconvenient, evaluate (2) directly at generic (p,ϵ) points and reconstruct

N
i
	​

(p,ϵ)=Q
C
	​

(p,ϵ)C
i
	​

(p,ϵ).

Use one monomial-evaluation matrix and eight right-hand sides. Do not run eight independent rational reconstructions.

This is likely inexpensive:

the unknown object is only 2×4;

target-basis inversion is at most 2×2;

the current junction machinery has already handled substantially larger mode maps and modular comparison sets.

Common denominator versus entrywise denominators

Use the proven common, possibly nonreduced denominator for reconstruction. After lifting, individual entries may be reduced by

gcd(N
i
	​

,Q
C
	​

).

Entrywise rational reconstruction should be only a fallback when the common denominator inflates the polynomial numerator support substantially. It throws away the shared singularity structure and usually needs more modulus information.

Symbolic versus modular

A direct symbolic evaluation of (2) is appropriate only when all input matrices remain compact. Otherwise use modular evaluation and coefficient reconstruction.

There is no reason to symbolically solve a 45×45 problem. The relevant algebraic relation is a 2×4 projection.

5. Acceptance of C and the normal residue

Let

J
⋆
=J
known
	​

+E
T
	​

C
⋆
E
Z
T
	​


be the reconstructed candidate.

At fresh primes and generic (p,ϵ) points not used for reconstruction, evaluate the original local differential-equation provider and require:

Normal residue intertwining
R
ρ
	​

M−MJ
⋆
=0.
	​

(9)

This is the decisive comparison against the original construction.

Tangential horizontality
∂
p
	​

J
⋆
−[Ω,J
⋆
]=0.
	​

(10)

This catches a rational fit that agrees with several normal-residue samples but has the wrong p-dependence or moving-basis convention.

Jordan structure

Set

N
⋆
=E
T
	​

C
⋆
E
Z
T
	​

.

Require structurally

[N
⋆
,J
diag
	​

]=0,(N
⋆
)
2
=0.
	​

(11)

The generic rank

r=rankC
⋆
≤2

is the number of independent length-two zero-exponent Jordan chains. Rank may drop at special p-values; the generic value should be the maximum observed on the regular chamber.

Strictly, the matrix with a general C(p,ϵ) is a Levelt exponent/residue matrix in the selected mode basis, not necessarily pointwise Jordan canonical form. It becomes a literal constant Jordan matrix in the parallel frame described below.

Minimum modular replay

Under the existing acceptance philosophy, one unused 61-bit prime with three generic (p,ϵ) pairs is sufficient as the basic replay, provided all denominator factors are nonzero. At every pair, test both (9) and (10).

If the cleared residual numerators have total degree bounded by D, the probability for a nonzero residual to vanish at m independent random points is bounded in the usual polynomial-identity model by approximately

(D/q)
m
.

No symbolic residual is needed.

The previously stored coefficients through ϵ
4
 should agree with the candidate, but that agreement is construction consistency, not the independent acceptance test.

The package’s rational-layer endpoint-residue builder currently assembles the normal residue order by order from the incoming Laurent deck, confirming that the present object is a finite deck rather than an all-orders rational coupling.

6. Avoiding global reconstruction of C(p,ϵ)

Yes. This is the shortest route for the actual boundary-function evolution.

Choose a regular tangential base point p
0
	​

 in the physical chamber, away from every pole. Reconstruct only

C
0
	​

(ϵ)=C(p
0
	​

,ϵ).

Let U(p,p
0
	​

;ϵ) solve the exact tangential system

∂
p
	​

U=ΩU,U(p
0
	​

,p
0
	​

)=I.

Define

J
0
	​

(ϵ)=J
known
	​

(p
0
	​

,ϵ)+E
T
	​

C
0
	​

(ϵ)E
Z
T
	​

.

Horizontality implies

J(p,ϵ)=U(p,p
0
	​

;ϵ)J
0
	​

(ϵ)U(p
0
	​

,p;ϵ).
	​

(12)

Consequently,

ρ
J(p,ϵ)
U(p,p
0
	​

;ϵ)=U(p,p
0
	​

;ϵ)ρ
J
0
	​

(ϵ)
.
	​

(13)

If the local normal Frobenius matrix is

Φ(ρ,p,ϵ)=P(ρ,p,ϵ)ρ
J(p,ϵ)
,

then the complete local solution may be written as

I(ρ,p,ϵ)=P(ρ,p,ϵ)U(p,p
0
	​

;ϵ)ρ
J
0
	​

(ϵ)
c
0
	​

(ϵ).
	​

(14)

All generalized logarithmic chains are retained through the constant matrix J
0
	​

. No diagonal-exponent replacement has occurred.

Advantages

Only a 2×4 rational function of epsilon at one rational p
0
	​

 must be reconstructed.

The exact tangential evolution operator is already required for the boundary functions.

The boundary constants c
0
	​

 are naturally constants at the tangential base point.

There is no high-degree rational reconstruction in p.

The number and structure of the Jordan chains remain explicit.

Exact output contract

The parallel-frame representation must record:

the tangential base point p
0
	​

;

J
0
	​

(ϵ), including C
0
	​

(ϵ);

the exact tangential evolution operator U(p,p
0
	​

;ϵ);

the regular normal prefactor P(ρ,p,ϵ);

the source/target mode basis at p
0
	​

;

the physical branch and path convention.

Then C(p,ϵ) remains available implicitly through (12).

This is a genuine characteristic-zero representation if U and C
0
	​

 are exact. A finite-field black-box evaluator for C
0
	​

 alone would not be enough.

Recommended order

Adopt equations (1) and (4) as the definition of the missing coupling.

For physical transport, choose a regular p
0
	​

 and reconstruct only C
0
	​

(ϵ).

Use the exact tangential operator to work in the parallel Levelt frame, equation (14).

Reconstruct a global rational C(p,ϵ) only if an independent consumer needs it:

derive a common denominator from (2);

solve the numerator coefficients using (5) plus the p
0
	​

 anchor;

use entrywise reduction only afterward.

Accept through fresh-prime replay of both the residue intertwiner and tangential horizontality.

The eight stored Laurent coefficients are sufficient only if the proven numerator/denominator bounds satisfy the counting conditions above. Without such a bound, they are a truncation, not an exact rational coupling.

I could inspect the current public junction builder, endpoint frame, and endpoint-residue implementation. The two named local files build_cf303_boundary_function_evolution.wls and BoundaryFunctionDifferentialSystem.wl, together with the cited Stale/... inputs, are not present on the accessible public main; I have therefore not made implementation-specific claims about their internal code.