# Variable-scattering-angle endpoint assembly

## Question

We are starting general NNLO double-real distribution assembly after completing the stored 91-family/345-master/2220-coefficient physical AMFlow audit at (v,w)=(1/4,1/5). All passes, independent boundaries; no AMFlow boundary substitution.

Current symbolic output is explicit finite epsilon coefficients of a closed two-variable rational/algebraic DE dI=(Av dv+Aw dw)I, stored as finite shared iterated-integral definitions. Full epsilon-form canonicalization is optional. The physical boundary normalization is fixed on v=1/4, w=3/4-z, z=1-v-w=Q_X^2/s. Along that line, local normalization gives a Fuchsian z system with nilpotent epsilon-zero residue, explicit Frobenius seeds, epsilon-dependent powers and logarithms; all stored physical constants are determined. Evaluation uses arbitrary-precision Frobenius/Taylor recurrence and finite ordinary-point expressions. The user wants general code, not family cases or lazy generators. Checks must stay proportionate.

We now need coefficients delta(z), [log^k z/z]_+, and a locally integrable regular remainder, with tangential scattering v SYMBOLIC. Our physical constants at v=1/4 are normalization data, not the variable-v endpoint functions. Bare double-real epsilon poles remain; RV/VV/UV/PDF/FF counterterms are outside current steps1-4. Main ud->udgg and ghost coefficients must first be merged using exact master identities; input audit found 2 main dotted-master identities and27 ghost namespace entries outside current requested list, which may reduce to existing basis. We will resolve those and propagate actual coefficient/endpoint epsilon demands rather than assume2220 coefficients suffice.

Please critically design the general mathematical construction for tangential endpoint amplitude functions from the original integrable two-variable DE:
- Coordinates z=1-v-w, tangential v give Az=-Aw and Bv=Av-Aw. Existing normalized gauge was computed at v=1/4; cannot simply differentiate that frozen gauge.
- Should we construct a symbolic-v local Fuchsian/Frobenius gauge, use compatibility to induce a closed DE on leading amplitude functions, or use a larger finite collection of local coefficient states and eliminate only exact relations? How to handle resonances/Jordan logs and epsilon-dependent exponents without noncommutative differentiation mistakes in z^R(v,eps)?
- Which exact hypotheses let one restrict a gauge-transformed tangential connection to z=0? If not regular, what coefficient matching/projection avoids assuming it is?
- How to reuse our explicit finite-DE constructor for the v-dependent boundary functions, matched at v0=1/4, so results remain finite solved coefficients rather than generators?
- Give a practical sufficient-order dependency algorithm for endpoint-local delta demands vs global regular demands, preserving truncated main coefficient input through epsilon^5 and symbolic analytic prefactors.
- Suggest the smallest general implementation sequence with explicit unsupported-case failures rather than false generality. Keep exact normalization, branches, v-domain endpoints and overlapping singularities explicit. No need to solve every future geometry now.

Provide equations/algorithm details that can guide implementation and explain what must be established before presenting a paper-level double-real distribution result.


## Pro response

Construct a symbolic-v local normalization and transport the complete Frobenius-amplitude space. Do not transport the numerical values of individual “leading constants,” and do not identify the endpoint connection with B
v
	​

∣
z=0
	​

 until its applicability has been established.

The preferred first implementation is narrower than a general theory of resonant specialization: obtain a locally normalized Fuchsian system with no nonzero integer differences between residue eigenvalues, derive its tangential connection, and reuse your finite-DE constructor. Repeated eigenvalues and Jordan logarithms are allowed. Complete Frobenius-seed projection is the appropriate fallback when that normalization is unavailable—not an arbitrary truncation to the first few local coefficients.

Below is a sufficient construction, including the conditions under which each simplification is valid.

1. Start from the merged physical density and the correct connection

Write

I
(v,z,ϵ)=I(v,1−v−z,ϵ),∂
z
	​

I
=A
I
,∂
v
	​

I
=B
I
,

where

A=−A
w
	​

,B=A
v
	​

−A
w
	​


are evaluated at w=1−v−z. Flatness is

∂
v
	​

A−∂
z
	​

B+[A,B]=0.
	​


First resolve the two main dotted-master identities and the 27 ghost namespace entries into a common exact basis. An unmatched ghost entry is not automatically a new master, but it is an unresolved dependency until its exact reduction is known. Preserve the reductions’ ϵ-poles, z-poles, cut conventions, and normalization factors.

The object to expand distributionally is then the complete density

F(v,z,ϵ)=
i
∑
	​

c
i
	​

(v,z,ϵ)
I
i
	​

(v,z,ϵ),

including the relevant phase-space Jacobian and analytic normalization factors. Endpoint cancellations and order demands belong to this combined expression, not separately to the main and ghost namespaces.

Work initially on a tangential interval U containing v
0
	​

=1/4, away from other singular divisors and algebraic discriminants. Fix the physical algebraic sheets and the branch of logz there. A local result on U is not yet a result uniform at v=0,1.

For a symbolic gauge 
I
=TJ, both transformed matrices must be computed:

A=T
−1
AT−T
−1
∂
z
	​

T,B=T
−1
BT−T
−1
∂
v
	​

T.

Here ∂
v
	​

 holds z fixed. A gauge known only after substituting v=v
0
	​

 supplies matching data, not the missing derivative ∂
v
	​

T.

2. Preferred route: normalized Fuchsian form implies a closed amplitude DE
Sufficient hypotheses

Seek a symbolic-v local gauge such that

A=
z
R(v,ϵ)
	​

+
j≥0
∑
	​

A
j
	​

(v,ϵ)z
j
.

Require, on the chosen patch:

T is invertible on the punctured neighborhood and its algebraic branch is fixed; B is meromorphic in z.

The residue satisfies

λ
i
	​

(R)−λ
j
	​

(R)∈
/
Z∖{0}.

The chosen frame and matching maps are nonsingular at v
0
	​

, apart from explicitly tracked Laurent dependence on ϵ.

This is local normalized Fuchsian reduction, not global ϵ-form reduction. Normalizing eigenvalues by integer shifts and excluding nonzero integer differences are standard ingredients of normalized Fuchsian form; repeated eigenvalues are not excluded. 
arXiv

A particularly convenient sufficient check for your setting is:

R(v,ϵ) is regular at ϵ=0,R(v,0) is nilpotent symbolically on U.

Then nid±ad
R
	​

 are invertible as formal ϵ-series for every positive integer n. Nilpotence established only at v
0
	​

 is not this symbolic certificate.

Why tangential poles must vanish

Suppose

B=z
−p
B
−p
	​

+⋯,p>0.

The most singular coefficient of flatness gives

(pid+ad
R
	​

)B
−p
	​

=0.

The nonresonance condition makes this operator invertible. Therefore B
−p
	​

=0, contradicting the assumed leading pole. Hence

B=C(v,ϵ)+O(z).
	​


Thus, once the hypotheses are established, tangential regularity follows from compatibility. In implementation, checking the computed principal part still provides a small, useful guard against transformation errors.

The z
−1
 coefficient of flatness gives

R
′
=[C,R].
	​


This is the horizontality of the residue: the tangential connection transports its conjugacy class. Restricting a logarithmic connection to a stratum, after choosing the normal-coordinate splitting, produces a tangential connection together with horizontal residue endomorphisms. 
arXiv

One is not substituting z=0 into the whole one-form Rdz/z+⋯. One restricts its regular tangential part in the chosen logarithmic frame.

Constructing the complete Frobenius amplitudes

There is a normalized radial factor

H(v,z,ϵ)=1+
n≥1
∑
	​

H
n
	​

(v,ϵ)z
n
,J=Hz
R(v,ϵ)
a(v,ϵ).

Its recurrence is

(nid−ad
R
	​

)H
n
	​

=
j=0
∑
n−1
	​

A
j
	​

H
n−1−j
	​

.
	​


Only finitely many H
n
	​

 will be needed for endpoint extraction.

After transformation by H, the radial connection is exactly R/z. Write the resulting tangential connection as Q=∑
n≥0
	​

Q
n
	​

z
n
. Flatness implies

Q
0
	​

=C,(nid−ad
R
	​

)Q
n
	​

=0(n≥1).

Therefore Q=C, and the desired endpoint system is

a
′
(v,ϵ)=C(v,ϵ)a(v,ϵ).
	​


This transports the full normalized amplitude vector, including modes that first appear at subleading powers in the original masters.

Noncommutative differentiation is handled covariantly

Generally,

∂
v
	​

z
R

=(logz)R
′
z
R
.

The correct derivative is

∂
v
	​

z
R
=∫
0
logz
	​

e
(logz−t)R
R
′
e
tR
dt.

Using R
′
=[C,R], this becomes

∂
v
	​

z
R
=Cz
R
−z
R
C.
	​


This identity is exactly what makes a
′
=Ca consistent. There is no need to diagonalize R, assume [R,R
′
]=0, or construct a full tangential fundamental matrix merely to make R constant.

Jordan blocks remain intact:

z
λ1+N
=z
λ
ℓ=0
∑
d−1
	​

ℓ!
N
ℓ
	​

log
ℓ
z,N
d
=0.

Keep the ϵ-dependent powers before distributional expansion. Their endpoint and ϵ limits need not commute, and retaining the scaling modes is essential for distinguishing them. 
arXiv

3. When restriction is insufficient: complete seed projection

Without normalization, even a Fuchsian radial matrix need not justify the preceding amplitude formula.

For example,

A=
z
1
	​

(
0
0
	​

0
1
	​

),B=
z
1
	​

(
0
0
	​

1
0
	​

)

is flat. Its radial solutions have the form

J=(
za
2
	​

(v)
a
1
	​

(v)
	​

),

and tangential evolution is

a
1
′
	​

=a
2
	​

,a
2
′
	​

=0.

Keeping only the componentwise z
0
 coefficients loses the amplitude that drives a
1
	​

. The shear diag(1,z) fixes this example, but it illustrates why leading-coefficient projection is not intrinsically closed.

There is a further distinction: regularity of B alone is insufficient in an unnormalized resonant frame. Replacing the example’s tangential matrix by zE
21
	​

 gives B(0)=0, yet a
2
′
	​

=a
1
	​

.

Coefficient-matching construction

Use generalized Frobenius series, keeping integer-related exponents in the same exponent class:

J=
α
∑
	​

z
λ
α
	​

(ϵ)
n
∑
	​

ℓ≥0
∑
	​

z
n
(logz)
ℓ
f
αnℓ
	​

(v,ϵ).

Generalized power/log expansions and their recurrences are an established route for Feynman-integral DEs without canonical form. 
arXiv

For one exponent class, radial matching gives

((λ+n)1−R)f
nℓ
	​

+(ℓ+1)f
n,ℓ+1
	​

=
j≥0
∑
	​

A
j
	​

f
n−1−j,ℓ
	​

.

If

B=
j=−p
∑
∞
	​

B
j
	​

z
j
,

tangential matching gives

f
nℓ
′
	​

=
j=−p
∑
∞
	​

B
j
	​

f
n−j,ℓ
	​

.

If an exponent has not been established to be v-independent, the left side instead contains

f
nℓ
′
	​

+λ
′
(v,ϵ)f
n,ℓ−1
	​

.

A tangential pole of order p can therefore require coefficients p orders beyond a retained slot. Resonant radial equations must retain their free seed coefficients and logarithmic constraints rather than invert a singular recurrence matrix.

The clean formulation uses a complete formal fundamental matrix Ψ:

K=Ψ
−1
(BΨ−∂
v
	​

Ψ).

Flatness gives

∂
z
	​

K=0.

You need not construct an infinite Ψ. Determine K by matching a finite set of coefficient slots that uniquely determines every radial solution. The proof of sufficiency is completeness of the Frobenius seed parametrization—not apparent stabilization of a few sampled coefficients.

An overcomplete finite coefficient state is acceptable. Eliminate only exact relations. For a v-dependent parametrization f=W(v,ϵ)b, the induced equation must satisfy

Wb
′
=(MW−W
′
)b,

not merely select a submatrix of M.

Likewise, after obtaining a
′
=Ca, selected endpoint functions h=W
0
	​

a can be closed by adjoining rows under

W⟼W
′
+WC.

The resulting row space has dimension at most the amplitude-space dimension. This is a principled way to enlarge an insufficient set of leading functions; numerical zeros at v
0
	​

 are not grounds for eliminating states.

4. Match once at v
0
	​

, then materialize finite solved coefficients

Your existing physical boundary data supplies the initial condition. Match the new and old local representations in the common master basis:

Ψ
new
	​

(v
0
	​

,z,ϵ)a
0
	​

(ϵ)=Ψ
old
	​

(z,ϵ)b
phys
	​

(ϵ).
	​


Use complete seed coefficients, including resonant/subleading seeds where necessary. This is an exact finite linear matching problem. It introduces no new physical constants and requires no AMFlow substitution.

Propagate its actual ϵ-order requirements through the matching matrix.

For clarity, suppose an admitted endpoint basis has

C=
r≥0
∑
	​

ϵ
r
C
r
	​

,a=
n≥n
min
	​

∑
	​

ϵ
n
a
n
	​

.

Then

a
n
′
	​

=C
0
	​

a
n
	​

+
r=1
∑
n−n
min
	​

	​

C
r
	​

a
n−r
	​

.

If U
0
′
	​

=C
0
	​

U
0
	​

, U
0
	​

(v
0
	​

)=1, the construction is

a
n
	​

(v)=U
0
	​

(v)[a
n
	​

(v
0
	​

)+∫
v
0
	​

v
	​

U
0
	​

(t)
−1
r=1
∑
n−n
min
	​

	​

C
r
	​

(t)a
n−r
	​

(t)dt].

Feed this through your existing finite-solution machinery and store the requested coefficients with their complete finite shared-definition closure.

The displayed formula is not itself an acceptable solved output if U
0
	​

 remains an unnamed fundamental solution. Reuse the constructor’s actual supported block class, including its treatment of ϵ-poles and zeroth-order systems. Do not replace an unsupported block by a path-ordered exponential or a lazy recurrence and call it complete.

In particular, nilpotence of the normal residue R(v,0) says nothing sufficient about solvability of the tangential system C
0
	​

: R=0 is compatible with arbitrary C
0
	​

(v). Failure of the supported finite-function construction should remain an explicit unsupported case, not trigger mandatory global canonicalization.

5. Extract distributions from the assembled endpoint expansion
Extract the singular density, not just leading master terms

Expand the combined expression

F=c
T
THz
R
a

only far enough in z to capture every potentially nonintegrable term.

For a prefactor/gauge term z
p
, a Frobenius coefficient H
n
	​

, and an exponent λ
α
	​

, the relevant criterion is

Re(p+n+λ
α
	​

(0))≤−1.

Thus a coefficient with a high-order z-pole can require several subleading master coefficients. Replacing every smooth-looking prefactor by its endpoint value before this accounting is unsafe.

After the physical combination, the requested distribution basis is sufficient only if its surviving singular part has the form

S(v,z,ϵ)=
ρ,ℓ
∑
	​

E
ρℓ
	​

(v,ϵ)z
−1+α
ρ
	​

(ϵ)
log
ℓ
z,α
ρ
	​

(0)=0,

and every remaining term is locally integrable at z=0.

Surviving stronger powers, such as z
−2+α
, generally require derivative delta functions and higher-subtraction distributions. They must cancel at the relevant distributional ϵ-depth or produce an explicit unsupported result. A nonzero unregulated z
−1
log
ℓ
z mode with α≡0 likewise cannot be assigned a contact term by inventing an ϵ-slope.

Specify the plus prescription

Let the upper support at fixed v be Z(v)>0. On the triangle v>0,w>0,z>0, this is Z(v)=1−v. Define

⟨D
k
Z
	​

,φ⟩=∫
0
Z(v)
	​

z
log
k
z
	​

[φ(z)−φ(0)]dz,⟨δ,φ⟩=φ(0).

Subtracting the endpoint test-function value gives the meromorphic identity

z
−1+α
=
α
Z
α
	​

δ(z)+
k≥0
∑
	​

k!
α
k
	​

D
k
Z
	​

(z).
	​


This is the endpoint-subtraction mechanism used in distributional extraction of dimensionally regulated real radiation. 
arXiv

Generate explicit logarithms by differentiating the kernel, holding the amplitude E
ρℓ
	​

 fixed:

z
−1+α
log
ℓ
z=∂
α
ℓ
	​

z
−1+α
.

Consequently,

D
δ
	​

(v,ϵ)=
ρ,ℓ
∑
	​

E
ρℓ
	​

(v,ϵ)∂
α
ℓ
	​

α
Z(v)
α
	​

	​

α=α
ρ
	​

(ϵ)
	​

,
	​


and

D
k
	​

(v,ϵ)=
ρ
∑
	​

ℓ≤k
∑
	​

E
ρℓ
	​

(v,ϵ)
(k−ℓ)!
α
ρ
	​

(ϵ)
k−ℓ
	​

.
	​


The global regular coefficient functions come from the existing full solution:

R
n
	​

(v,z)=[ϵ
n
](F(v,z,ϵ)−S(v,z,ϵ)),z>0.
	​


Do not replace R
n
	​

 by its endpoint Taylor expansion.

A unit-interval plus prescription changes the delta coefficient. With the usual restriction to 0≤z≤Z,

D
k
1
	​

	​

[0,Z]
	​

=D
k
Z
	​

+
k+1
log
k+1
Z
	​

δ(z).

This conversion, or any rescaling z=Z(v)t, must be explicit.

A useful matrix implementation for Jordan blocks

For a regulated invertible exponent block M,

z
−1
z
M
=Z
M
M
−1
δ(z)+
k≥0
∑
	​

k!
M
k
	​

D
k
Z
	​

(z).
	​


Contract this with the endpoint row and amplitude vector.

This avoids eigenvector denominators and automatically retains Jordan logarithms. Use it only on regulated blocks, or after exact removal of unregulated projections; a pseudoinverse does not supply the missing distributional definition. Expand and materialize only the finitely many terms needed at the requested ϵ-order.

6. Sufficient-order planning: separate local and global demands

Maintain a lower Laurent bound ν(X) and a known-through order for every truncated quantity. Exact analytic prefactors have no artificial upper truncation, but still require expansion to each consumer’s requested depth.

For a product XY needed through ϵ
N
, sufficient demands are

N
X
	​

=N−ν(Y),N
Y
	​

=N−ν(X).

Use conservative lower bounds unless cancellations are established exactly.

Endpoint integration can require more than one extra order

Let

α
ρ
	​

(ϵ)=ϵ
q
ρ
	​

u
ρ
	​

(ϵ),u
ρ
	​

(0)

=0.

Since

∂
α
ℓ
	​

α
Z
α
	​

=
α
ℓ+1
(−1)
ℓ
ℓ!
	​

+less singular terms,

the sufficient amplitude demands are:

Consumer, through ϵ
N
	Required E
ρℓ
	​

 through
Delta coefficient	N+q
ρ
	​

(ℓ+1)
Coefficient of D
k
Z
	​

, k≥ℓ	N−q
ρ
	​

(k−ℓ)
Subtraction in the ordinary-point remainder	N

For the usual α=bϵ, a logarithm-free mode needs one extra local order; a log
ℓ
z mode can need ℓ+1 extra orders. Exact combinations can improve these bounds, but that improvement must be demonstrated.

If e
ρℓ
	​

 is a lower bound for E
ρℓ
	​

, only

k≤ℓ+⌊
q
ρ
	​

N−e
ρℓ
	​

	​

⌋

can contribute through order N.

For the matrix implementation, propagate the actual entrywise valuations of Z
M
M
−1
 and M
k
. A finite conservative cutoff also follows from M(0)
d
=0: the coefficient of order ϵ
r
 in M
k
 vanishes for k>d(r+1)−1.

Backward dependency propagation

Seed separate requests for D
δ
	​

, the required D
k
	​

, and the full R
n
	​

(v,z). Propagate them backward through physical coefficients, reductions, local projection matrices, Frobenius recurrences, endpoint transport, and the seed-matching map.

For a linear dependence y
i
	​

=∑
j
	​

M
ij
	​

x
j
	​

,

N
x
j
	​

	​

≥N
y
i
	​

	​

−ν(M
ij
	​

).

For a
′
=Ca, an entry beginning at ϵ
r
 can require a
j
	​

 through N
a
i
	​

	​

−r. Handle same-order coupled blocks together. A cycle that makes demands grow without bound signals an inadequate ϵ-basis or unsupported coupled construction; it is not permission to truncate the cycle.

Crucially, deeper delta demands should extend local amplitudes and their boundary data, not automatically all ordinary-point two-variable coefficients.

Preserve the ϵ
5
 input boundary

Store

c
main
	​

=
r≤5
∑
	​

ϵ
r
c
r
	​

+O(ϵ
6
),

not an exact polynomial.

For illustration, an unknown O(ϵ
6
) coefficient multiplying an endpoint amplitude beginning at ϵ
−4
 and a logz kernel with a double contact pole can affect the finite delta term:

ϵ
6
ϵ
−4
ϵ
−2
=ϵ
0
.

The corresponding ordinary-point uncertainty starts at ϵ
2
. This is precisely why global sufficiency does not imply delta sufficiency.

If an unknown input remainder can reach any requested output order, return the missing coefficient demands. Expanding exact prefactors to higher orders does not recover the unknown main coefficients.

7. Smallest implementation sequence and publication threshold

I would implement four stages:

Exact physical merge and demand planning. Resolve the main/ghost basis, preserve truncation remainders, and derive separate global and endpoint requirements. New basis dependencies receive new demands rather than inheriting the old 2220-coefficient coverage.

Parameterized endpoint reduction. Implement the normalized, unramified logarithmic route first: symbolic T, residue R, tangential C, complete initial matching, and demand-limited H
n
	​

. Support existing algebraic branches; require explicit support for ramification or fail. Add complete-seed projection only where its completeness and closure are established.

Finite endpoint solution. Reuse the finite-DE constructor and store actual requested coefficient expressions with complete shared dependencies. Unsupported zeroth-order blocks, unresolved seed relations, or insufficient boundary orders remain visible failures.

Distribution assembly. Extract the complete singular density, apply one recorded plus convention, store the delta/plus coefficients and full regular remainder, and reject surviving unsupported endpoint powers.

The checks can remain proportionate. The decisive mathematical checks are the transformed connection identities, tangential principal-part cancellation, R
′
=[C,R], complete seed matching, and the finite-coefficient DE identities. Validate the new endpoint layer at a few additional v-values and decreasing positive z against your existing full two-variable solution. Test-function moments are useful implementation checks; the subtraction identity and local integrability establish the distributional result.

Before a paper-level claim, three scope issues must also be settled.

The distributional extension must be fixed. Equality for z>0 alone does not exclude endpoint-supported terms. Use the meromorphic continuation of the original dimensionally regulated phase-space density, carrying any explicitly endpoint-supported input separately. This fixes the contact-term prescription rather than leaving an arbitrary delta ambiguity.

State the domain honestly. The construction above initially proves a distribution in z with coefficient functions on U, and a remainder locally integrable at z=0 for tangential variables in compact subsets of U. It does not prove joint integrability at v=0,1, w=0, or another divisor colliding with z=0. Entangled limits require a joint local analysis or appropriate sector coordinates, not independent one-dimensional plus expansions. 
arXiv

Call the result a bare double-real distribution. Its Laurent poles need not cancel at these stages. RV, VV, UV renormalization, and the relevant PDF/FF factorization contributions remain outside this result; the general need to combine real and virtual pieces and collinear counterterms is separate from successfully extracting the double-real distributions. 
arXiv

Your fixed-line physical normalization is sufficient to initialize this construction. What remains to establish is the symbolic tangential differential module, its finite solved coefficients at the actual demanded orders, and the distributional extension on the stated domain—not another numerical normalization campaign.