Prioritized verdict

Boundary stratum: the boundary coefficients must be promoted from inert symbols to a flat tangential differential system. The minimal complete object is the induced boundary connection

Γ=Reg
ρ=0
	​

[Φ
−1
(A
∥
	​

Φ−d
∥
	​

Φ)],

followed by its evolution from a tangential base point. Treating the coefficients as constants is correct only when Γ=0.

Modular reconstruction: stop lifting the 71 partial-fraction coordinates. Use the exact denominator to convert every modular image to a canonically aligned numerator polynomial, then reconstruct its primitive integer coefficient vector with one common scalar denominator. This directly distinguishes insufficient modulus from partial-fraction alignment errors.

The distinction between mathematical transport and an implementation cache is already explicit in the package review: transport is propagation of specified data along a path, while free Frobenius coefficients are boundary constants rather than generic periods.

02_community_vocabulary_revisio…



community_terminology_rename_pl…

1. Boundary data on a positive-dimensional physical stratum
1.1 Local setup

Let ρ be a normal coordinate, with the physical boundary stratum

D={ρ=0},

and let t=(t
1
	​

,…,t
s
	​

) denote coordinates along D. Use the convention

dI=AI,A=A
ρ
	​

dρ+
i=1
∑
s
	​

A
i
	​

dt
i
	​

.

Regular singularity in the normal direction means

A
ρ
	​

(ρ,t,ϵ)=
ρ
R(t,ϵ)
	​

+A
ρ,0
	​

(t,ϵ)+O(ρ).

For a flat logarithmic connection, the residue is a horizontal endomorphism of the induced connection on the stratum; in a suitable splitting, the data are an integrable tangential connection together with commuting horizontal residue endomorphisms.
DNB

Let

Φ(ρ,t,ϵ)

be the normal Frobenius/Levelt solution matrix chosen by the package, normalized by its declared regularization convention and satisfying

∂
ρ
	​

Φ=A
ρ
	​

Φ.

In a nonresonant presentation this may be written as

Φ=H(ρ,t,ϵ)ρ
R(t,ϵ)
,H(0,t,ϵ)=I.

In resonant or Jordan sectors, Φ must denote the full object, including integer shears and all required powers of logρ. One should not replace it by a matrix of pointwise residue eigenvectors.

Every local solution has the form

I(ρ,t,ϵ)=Φ(ρ,t,ϵ)c(t,ϵ).
	​

(1)

The central question is the equation obeyed by c(t,ϵ).

1.2 The induced tangential equation

Insert (1) into the tangential equations

∂
t
i
	​

	​

I=A
i
	​

I.

This gives

∂
t
i
	​

	​

c=Γ
i
	​

(t,ϵ)c,Γ
i
	​

=Φ
−1
(A
i
	​

Φ−∂
t
i
	​

	​

Φ).
	​

(2)

For an exact flat connection and an exact normal fundamental matrix, the right-hand side is independent of ρ. In a truncated Frobenius computation, the operational definition is

Γ
i
	​

(t,ϵ)=Reg
ρ=0
	​

[Φ
−1
(A
i
	​

Φ−∂
t
i
	​

	​

Φ)],
	​

(3)

where Reg means the coefficient in the declared Levelt basis after removing the prescribed ρ-powers and logarithmic factors. It is not ordinary substitution ρ=0.

Define

Γ=
i
∑
	​

Γ
i
	​

dt
i
	​

.

The boundary functions obey

d
D
	​

c=Γc.
	​

(4)

This is the mathematically minimal complete replacement for treating c as an inert vector.

Moving eigenbasis term

Suppose a moving basis V(t,ϵ) is used to put the normal residue in a preferred form. Then the tangential connection transforms as

Γ
(V)
=V
−1
ΓV−V
−1
d
D
	​

V.
	​

(5)

The second term is mandatory. Omitting it gives the wrong boundary evolution even when the normal residue has been diagonalized correctly pointwise.

1.3 Compatibility conditions

The original system must be flat:

dA−A∧A=0.

This is also the integrability condition used for multivariate Feynman-integral differential equations.
SCOAP3 Production Backend

Flatness implies three relevant identities.

Independence from the normal coordinate
∂
ρ
	​

Γ
i
	​

=0.
	​

(6)

Failure of (6), after the stored truncation order is accounted for, means either:

the Frobenius/Levelt factor is incomplete;

the moving-basis derivative was omitted;

or insufficient regular-prefactor jets were retained.

Flatness on the stratum
d
D
	​

Γ−Γ∧Γ=0.
	​

(7)

For one tangential variable this is automatic as a two-form statement, but the equation still defines the evolution. For a higher-dimensional stratum, it is essential: it ensures that transport is locally path independent up to monodromy.

Horizontality of the normal residue

In the original boundary basis,

d
D
	​

R=[Γ,R].
	​

(8)

If the moving basis makes the chosen residue representative J constant, then

[Γ
(V)
,J]=0.
	​

(9)

Thus the tangential evolution preserves the generalized normal-exponent sectors in that chosen logarithmic extension.

In resonant/Jordan sectors, this does not mean that each eigenvector evolves independently. It means that the complete generalized eigenspace and Jordan filtration are preserved. Mixing within a degenerate generalized eigenspace is allowed and must be retained.

A common false shortcut is:

diagonalize R(t), retain only the eigenvalues and eigenvectors, and set their coefficients constant.

That misses both V
−1
dV and the allowed tangential mixing of degenerate or resonant modes.

1.4 Reduction to constants at a tangential base point

Choose a regular or tangentially regularized base point t
0
	​

 on the boundary stratum. Then

c(t,ϵ)=U
D
	​

(t,t
0
	​

;ϵ)c
0
	​

(ϵ),

with

U
D
	​

(t,t
0
	​

;ϵ)=Pexp(∫
t
0
	​

t
	​

Γ).
	​

(10)

The vector c
0
	​

(ϵ) consists of genuine integration constants. All dependence on coordinates along the boundary stratum is now represented by U
D
	​

.

The complete local solution is

I(ρ,t,ϵ)=Φ(ρ,t,ϵ)U
D
	​

(t,t
0
	​

;ϵ)c
0
	​

(ϵ).
	​

(11)

If the stratum has several independent coordinates and only one tangential equation has been solved, the remaining coefficients are still functions of the unsolved coordinates. They must not yet be labeled boundary constants.

1.5 Composition with evolution into the bulk

Let x
∗
	​

 be a regular interior reference point. Define the regularized boundary-to-reference map

C
∗
	​

(t,ϵ)=Reg
ρ→0
	​

[U(x
∗
	​

,(ρ,t);ϵ)Φ(ρ,t,ϵ)],
(12)

where U(x
∗
	​

,(ρ,t)) is the bulk evolution operator along the selected branch and path.

Then

I(x,ϵ)=U(x,x
∗
	​

;ϵ)C
∗
	​

(t,ϵ)U
D
	​

(t,t
0
	​

;ϵ)c
0
	​

(ϵ).
	​

(13)

This is the clean factorization into:

tangential evolution on the boundary stratum;

regularized matching/evolution from the stratum to a reference point;

bulk evolution.

No fictitious matching parameter ρ=δ is needed.

1.6 Which existing solution engine can be reused?
Tangential connection in dlog epsilon form

If

Γ=ϵ
a
∑
	​

C
a
	​

dlogL
a
	​

(t),C
a
	​

 constant,

the same generic sparse Chen-iterated-integral coefficient operator may be used, with:

a separate tangential alphabet;

a declared tangential base point;

the boundary-mode coefficient vector as input.

An epsilon form need not be multiple-polylogarithmic: elliptic examples remain solvable order by order as iterated integrals of their actual kernels.
SCOAP3 Production Backend
+1

Rational dependence on epsilon

If Γ(t,ϵ) is rational in ϵ but not epsilon-factorized, the ordinary rule “one letter raises epsilon weight by one” is invalid.

Use either:

finite Laurent deckororder-recursive variation of constants/path gauge.

This is the same mathematical class as the rational-in-epsilon final-layer treatment already developed for CF303.

Elliptic tangential system

If the tangential subsystem is epsilon-factorized but uses elliptic kernels, a Chen operator still applies, but it must store the genuine elliptic kernels, curve, base point and branch.

If the homogeneous tangential system is not epsilon-factorized, first construct its HomogeneousSolutionMatrix, then use variation of constants. It cannot be forced through a GPL-style weight recursion.

1.7 Smallest honest output contract

One may claim a complete master-integral solution in terms of constants at a tangential base point only when the object contains:

the normal Frobenius/Levelt factor Φ, through every required ρ, logρ, and epsilon order;

the induced tangential connection Γ;

its evolution operator U
D
	​

(t,t
0
	​

);

the physical-boundary-mode to Frobenius-coordinate map;

the regularized boundary-to-reference map C
∗
	​

;

the subsequent bulk evolution;

the final basis transformations;

the analytic branch, tangent, and integration paths;

an independent list of constants c
0
	​

, including all relations and known zeros;

the precise epsilon-order demand for every constant.

Boundary constants may remain unevaluated and explicitly named. But no unresolved arbitrary function of a boundary coordinate may remain. If such functions remain, the honest object is a solution in terms of boundary functions, not yet in terms of constants.

The mathematically essential controls are:

the normal Frobenius equation for Φ;

cancellation of all unwanted ρ- and logρ-dependence in (3);

flatness of Γ;

residue horizontality, or equivalently preservation of the chosen generalized exponent sectors;

normalization at t
0
	​

;

the composed differential equation and base-point relation.

These can be evaluated in exact modular arithmetic on the compact representation; they do not require a dense symbolic limit.

The prior CF303 campaign correctly distinguishes a genuine machine-verified obstruction from an unfinished computation. A failure to solve a boundary-function equation or to lift a modular coefficient is not itself a mathematical no-go.

Pasted markdown

2. CF303 rational-function reconstruction
2.1 What the current evidence establishes

The exact monic degree-66 denominator replaying at all six construction primes is strong evidence that the denominator polynomial is correct.

It does not yet establish that the 71 partial-fraction coordinates are canonically aligned across primes. Modular partial fractions can differ through:

permutation of factors;

unit rescaling of factors;

different choices within split factor or conjugate-factor bases;

different polynomial-part conventions.

Each prime can therefore define the same rational function while producing a coordinate vector that is unsuitable for coefficientwise CRT.

The 344-bit LLL candidates replaying at all six construction primes proves only that they belong to the construction congruence lattice. Their failure at the held-out value shows they are not the physical characteristic-zero vector. It does not distinguish insufficient modulus from a bad partial-fraction coordinate alignment.

The clean discriminator is to abandon partial fractions temporarily and reconstruct the numerator in a canonical polynomial basis.

2.2 Canonical numeratorization using the exact denominator

Let the exact monic denominator be D(p)∈Q[p]. Clear its coefficient denominators and primitive content:

D
(p)=d
D
	​

D(p)∈Z[p],content(
D
)=1.

At every construction prime q
j
	​

, reduce
D
 modulo q
j
	​

 and compute

N
j
	​

(p)=
D
j
	​

(p)
f
	​

j
	​

(p)∈F
q
j
	​

	​

[p].
	​

(14)

The product must be a polynomial. Operationally, polynomial division must have zero remainder and no residual denominator.

This gives an immediate alignment test:

Alignment/normalization failure

Stop and correct the modular representation if any good prime has:

a nonzero residual denominator;

a nonzero polynomial-division remainder;

an inconsistent numerator degree;

or inconsistent structural support not explained by a vanishing leading coefficient at that prime.

Canonical alignment established

If all six primes give polynomial numerators in the same monomial positions, the coordinate alignment is canonical. Factor permutations and partial-fraction normalizations have disappeared.

At that point, failure to lift is an information/height problem, not a partial-fraction alignment problem.

A prime dividing a coefficient denominator, leading coefficient, or normalization content should be classified as bad and discarded rather than interpreted as an alignment failure.

2.3 Reconstruct one primitive numerator vector

Write the exact function as

f(p)=
s
D
(p)
n(p)
	​

,
	​

(15)

where

n(p)=
i=0
∑
d
N
	​

	​

n
i
	​

p
i
∈Z[p],s∈Z
>0
	​

,

and

gcd(s,n
0
	​

,…,n
d
N
	​

	​

)=1.

CRT the modular numerator coefficients across the six primes:

a
i
	​

(modM),M=
j=1
∏
6
	​

q
j
	​

.

The exact vector obeys

n
i
	​

≡sa
i
	​

(modM).
	​

(16)

This is a vector rational reconstruction with a common denominator, not 71 unrelated scalar rational reconstructions.

The relevant lattice is

L
M
	​

={(n
0
	​

,…,n
d
N
	​

	​

,s)∈Z
d
N
	​

+2
:n
i
	​

−sa
i
	​

≡0(modM)}.
(17)

Vector rational reconstruction is specifically designed to exploit a common denominator and can require a substantially smaller modulus than independent elementwise reconstruction.
Cheriton School of Computer Science
+2
Cheriton School of Computer Science
+2

Practical order

Use denominators already recovered among the solved numerator coordinates to seed a candidate common scalar s
0
	​

.

Try integer reconstruction of s
0
	​

a
i
	​

modM.

If incomplete, run vector rational reconstruction on (17).

Normalize the result to a primitive vector.

Derive partial fractions over Q only after n(p) has been recovered.

The partial-fraction representation should be an output of exact reconstruction, not the CRT coordinate system.

2.4 A cheap secondary basis trial

If the monomial numerator vector remains unusually high, use the same six modular numerator polynomials in one additional integral basis, such as a Newton/falling-factorial basis around a small regular rational point.

This requires no new modular evaluations. It is merely an invertible integral triangular transformation of the coefficient vector.

This can help when large monomial coefficients arise from expanding a compact shifted or factored polynomial. It should be tried before purchasing another full prime, but only in one or two simple bases—not as a broad basis search.

2.5 The held-out scalar congruence is a filter, not a reconstruction engine

At the held-out prime q
∗
	​

 and point p
∗
	​

, the exact numerator obeys

i=0
∑
d
N
	​

	​

n
i
	​

p
∗
i
	​

−s
D
(p
∗
	​

)f
∗
	​

(p
∗
	​

)≡0(modq
∗
	​

).
	​

(18)

It is mathematically legitimate to intersect L
M
	​

 with this congruence and reduce the resulting sublattice.

It is nevertheless severely underdetermined.

For the current 71-coordinate projective representation, the lattice dimension is approximately 72. One scalar congruence multiplies the lattice determinant by only q
∗
	​

, so its Gaussian-heuristic shortest-vector scale increases by approximately

72
log
2
	​

q
∗
	​

	​

≈
72
61
	​

≈0.85 bits.

By contrast, one full new 71-coordinate prime image multiplies the determinant by approximately q
∗
71
	​

, increasing that scale by

72
71
	​

61≈60.2 bits.

Therefore:

use the scalar congruence to reject candidates or remove the current shortest spurious vectors;

do not expect it to replace a full additional prime image.

It is worth one inexpensive LLL pass after converting to the direct-numerator basis. It is not worth designing the recovery around it.

2.6 Why maximal-quotient reconstruction is not enough here

Maximal-quotient rational reconstruction is highly effective for one scalar a/b when numerator and denominator heights are asymmetric. Its practical threshold tracks ∣a∣b, rather than the symmetric max(∣a∣,b)
2
 bound, but its improvement is probabilistic and its worst-case guarantee remains larger.
CECM
+1

Your remaining object is not one scalar. It is a 71-dimensional projective coefficient vector. The relevant next operation is vector/common-denominator reconstruction, not another independent maximal-quotient pass on each partial-fraction coefficient.

2.7 Estimating the number of additional primes

Let

d=d
N
	​

+2

be the dimension of the primitive numerator-plus-scale lattice, and let

B=log
2
	​

M.

The determinant of the projective lattice is of order M
d−1
. A useful Gaussian-heuristic scale for its shortest generic vector is

h
GH
	​

(B,d)≈
d
d−1
	​

B+
2
1
	​

log
2
	​

(
2πe
d
	​

).
	​

(19)

This is a planning estimate, not a uniqueness theorem.

For the existing 71-coordinate representation, d=72 and B≃366, giving

h
GH
	​

≈362 bits.

The observed incorrect 344-bit candidates are only about 18 bits below that scale, so the present lattice has no compelling uniqueness gap.

One full additional 61-bit prime raises the scale to approximately

h
GH
	​

(427,72)≈422 bits.

Thus:

one additional full prime is the smallest justified next image.
	​


It is plausibly enough if the true direct-numerator vector has height below roughly 390–400 bits. There is no theorem from the current data guaranteeing that.

For an estimated primitive-vector height h and desired separation margin g, use

k
min
	​

=max[0, ⌈
61
d−1
d
	​

(h+g−
2
1
	​

log
2
	​

2πe
d
	​

)−B
	​

⌉].
	​

(20)

A reasonable diagnostic margin is g=20–30 bits. The estimate h should come from the shortest vectors in the direct-numerator, held-out-constrained lattice, not from the current partial-fraction lattice.

3. Smallest decisive experiment
Stage A — no new prime

For the unresolved function:

Reduce the exact
D
(p) modulo all six primes.

Form
N
j
	​

=
D
j
	​

f
	​

j
	​

.

Require a polynomial result with stable degree/support.

Compare the stored partial-fraction record, after recomposition, with
N
j
	​

/
D
j
	​

 at each prime.

CRT the direct numerator coefficients.

Run common-denominator vector reconstruction in:

the monomial basis;

one simple Newton/falling-factorial basis.

Use the held-out scalar congruence only as a candidate filter.

Interpretation

Numeratorization fails: alignment or normalization defect. Do not generate another prime.

Numeratorization passes and a candidate passes the held-out value: reconstruction complete.

Numeratorization passes but no candidate passes: current modulus information is insufficient for this representation.

This is the cleanest separation between a representation bug and insufficient modulus.

Stage B — exactly one new full prime

If Stage A establishes canonical alignment but produces no candidate:

generate one complete new modular numerator image;

enlarge M from about 366 to 427 bits;

update the vector-reconstruction lattice incrementally;

reconstruct the primitive numerator;

validate at an unused prime/value.

Do not spend the new prime reconstructing partial-fraction coordinates.

Stage C — bounded continuation

Generate a second additional full prime only when the updated lattice lengths and (20) predict that another 61 bits should produce a 20-bit or larger separation.

After two additional full primes:

if direct numeratorization remains stable but no candidate is separated, classify the problem as a genuinely high-height exact numerator representation;

stop investing in partial-fraction or arbitrary LLL-coordinate searches;

choose between further output-sensitive prime accumulation and a lower-height exact representation, such as a factored numerator or exact arithmetic circuit.

Do not label this a mathematical obstruction. The earlier CF303 work explicitly reserved “obstruction” for a machine-verified incompatibility, not failed reconstruction of a valid modular object.

Pasted markdown

Final recommendation table
Decision	Recommendation
Boundary coefficients on a stratum	Solve d
D
	​

c=Γc; never treat them as inert unless Γ=0
Resonant/Jordan sectors	Use the complete Frobenius/Levelt factor in (3); preserve generalized exponent sectors
Tangential dlog epsilon form	Reuse the sparse Chen coefficient operator
Rational-in-epsilon tangential system	Finite Laurent/variation-of-constants layer
Elliptic tangential system	Use elliptic kernels in the same Chen framework, or a homogeneous solution matrix if not epsilon-factorized
Current partial-fraction CRT coordinates	Abandon as the primary lift basis
Exact denominator	Use it to produce canonical modular numerator polynomials
Reconstruction object	Primitive numerator vector plus one common scalar denominator
Held-out scalar congruence	Candidate filter only; underdetermined as recovery data
Additional modular data	One full prime first; at most one further prime under the height estimate before changing representation

The modular recommendation is consistent with the package’s measured architecture: the source composition is a cheap function in a bad symbolic representation, so exact reconstruction should operate on a compact, canonically aligned black box rather than on swollen or prime-dependent coordinates.

11_reconstruct_dont_simplify

 The campaign already found that modular solving was functioning while downstream symbolic normalization was the dominant bottleneck.

08_three_root_slowdown_and_reco…

 Its deferred strategy likewise evaluates algebraic leaves and reconstructs only the required rational channels.

codex_overnight_optimization_tr…