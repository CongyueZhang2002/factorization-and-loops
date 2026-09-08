Verdict: GO, with two mandatory corrections

The proposed computation is the smallest independent discriminator. Do not derive the missing target contraction from the boundary intertwining equation itself; that would make the test tautological.

Two corrections are required before running it:

B_I = T25 (B_G + Q) is an embedding in the physical I
25
	​

 basis, not the G
25
	​

 basis. It must be paired with the physical-basis fixed-ρ connection. If the connection is in the G
25
	​

 basis, omit both T
25
	​

 and Q's conversion to F
25
	​

.

Modes 2,…,7 can be tested without the lazy mode-1 column only when the right action of Ω does not mix that column into them.

The accessible package source confirms the convention F
25
	​

=G
25
	​

+HF
S
	​

, with the primitive normalized at the reference point, while CF303JunctionRebase.wl only convolves stored source and G
25
	​

-target selector decks; it does not construct the missing H-action at the soft junction.

1. Minimal correct same-basis test

Let

D
∥
	​

≡
dp
d
	​

	​

ρ
	​

=∂
p
	​

∣
z
	​

+2∂
z
	​

∣
p
	​

,ρ=2p−z.

Let the complete boundary embedding into one declared ambient basis be B, with boundary functions satisfying

D
∥
	​

c=Ωc.

Then the defining relation is

Γ
∥
	​

B−D
∥
	​

B−BΩ=0.
	​

Physical-basis version

Let B
I,S
	​

 be the 43 source rows in the same physical basis as the connection, and let

B
I,T
	​

=T
25
	​

(B
G
	​

+Q),

where Q is the regularized action of H on the source Frobenius modes, not a naive value H(2p)B
S
	​

. The target-row residual is

E
T
	​

=Reg
ρ=0
	​

[Γ
∥,TS
I
	​

B
I,S
	​

+Γ
∥,TT
I
	​

B
I,T
	​

−D
∥
	​

B
I,T
	​

−B
I,T
	​

Ω].
	​

(1)

This is the correct object to test.

There is no need to construct or store the full 2×43 target-from-source connection. At each finite-field image, stream only the required target-row entries and contract them immediately with the corresponding 43×13 source jets.

G
25
	​

-basis version

Alternatively, test in the basis

X
G
	​

=(
F
S
	​

G
25
	​

	​

).

Then the embedding is simply

B
G
full
	​

=(
B
S
	​

B
G
	​

	​

),

and the equation uses Γ
∥
G
	​

. Neither T
25
	​

 nor Q appears.

A mixture such as T
25
	​

(B
G
	​

+Q) with Γ
∥
G
	​

 is mathematically wrong.

Why flatness does not replace the direct contraction

The flatness equation,

∂
ρ
	​

Γ
∥
	​

−D
∥
	​

A
ρ
	​

+[A
ρ
	​

,Γ
∥
	​

]=0,

recursively constrains the ρ-coefficients of Γ
∥
	​

, but it does not generally determine the components in the centralizer of the normal residue. In resonant sectors the recursion involves operators of the form

k−ad
R
	​

,

which can be singular. Those undetermined resonant components are precisely the dangerous ones here.

Once B and D
∥
	​

B are assumed known, one can algebraically define

Γ
∥,T,∗
	​

B=D
∥
	​

B
T
	​

+B
T
	​

Ω.

But that is only a rearrangement of the equation being tested. It provides no independent evidence that the embedding agrees with the original differential equation.

Therefore direct target-row extraction and contraction is the minimal independent calculation.

Can modes 2,…,7 avoid the lazy terms?

Let U denote the boundary-coordinate columns whose Q-entries are lazy; currently U={1}. For a tested set J, column j of BΩ is

(BΩ)
∙j
	​

=
k
∑
	​

B
∙k
	​

Ω
kj
	​

.

Thus the explicit-only pilot is independent of the lazy column exactly when

Ω
U,J
	​

=0.
	​

(2)

For J={2,…,7}, this requires

Ω
1j
	​

=0,j=2,…,7.

If (2) fails, either include the lazy derivative immediately or test linear combinations v satisfying Ω
U,∗
	​

v=0. Otherwise the purported explicit-only test silently omits terms.

2. Exact ρ-order window

Write the relevant fixed-ρ tangential connection and one local mode as

Γ
∥
	​

(ρ)=
j=j
min
	​

∑
∞
	​

Γ
j
	​

ρ
j
,
B(ρ)=ρ
−2−4ϵ
k=0
∑
∞
	​

ℓ=0
∑
L
	​

B
k,ℓ
	​

ρ
k
(logρ)
ℓ
.

The exponent −2−4ϵ is independent of p, so D
∥
	​

 does not differentiate the power of ρ.

After factoring out ρ
−4ϵ
, testing the differential equation through absolute order ρ
0
 means retaining relative orders

−2,−1,0.

In the product Γ
∥
	​

B, the coefficient at relative order m contains all pairs

j+k=m.

Therefore, through ρ
0
,

j+k≤2.
	​

(3)
If the fixed-ρ tangential connection is regular

When j
min
	​

=0, the minimal data are

Γ
0
	​

,Γ
1
	​

,Γ
2
	​

,B
0
	​

,B
1
	​

,B
2
	​

.
	​

(4)

In particular:

testing only the leading ρ
−2
 coefficient needs Γ
0
	​

,B
0
	​

;

testing through ρ
−1
 needs coefficients through order 1;

testing through ρ
0
 needs coefficients through order 2;

testing through ρ
1
 needs coefficients through order 3.

The preserved six-master analysis reports that its homogeneous fixed-ρ tangential system is regular, but its inherited inhomogeneous blocks can carry negative ρ-powers. The valuation must therefore be taken blockwise rather than inferred from regular singularity alone.

General case

If the target-row connection begins at ρ
j
min
	​

, then through ρ
0
 one needs

Γ
j
	​

:j
min
	​

≤j≤2,B
k
	​

:0≤k≤2−j
min
	​

.
	​

(5)

Do not extract a rectangular jet larger than this. Enumerate only the pairs (j,k) satisfying j+k≤2 and for which the matrix supports overlap.

Regular singularity of the normal equation only bounds the dρ component. A sheared or physical basis can still produce negative powers in the fixed-ρ tangential component, so j
min
	​

=0 must be read from the actual target rows.

Each logarithmic/Jordan degree is checked separately.

3. Differentiating the 16 lazy endpoint functionals

Use the adjoint representation. Do not obtain D
∥
	​

Q from the connection equation that Q is supposed to test.

Suppose one Hermite reduction is represented by

M(p,ϵ)x(p,ϵ)=f(p,ϵ),

and the regularized endpoint quantity is

Q(p,ϵ)=ℓ(p,ϵ)
T
x(p,ϵ).

Let the adjoint vector y solve

M
T
y=ℓ.

Then

Q=y
T
f.

Differentiate the adjoint system:

M
T
D
∥
	​

y=D
∥
	​

ℓ−(D
∥
	​

M)
T
y,
	​

(6)

and then

D
∥
	​

Q=(D
∥
	​

y)
T
f+y
T
D
∥
	​

f.
	​

(7)

This is the preferred implementation because:

it reuses the same factorization of M
T
;

all 16 functionals can be treated as multiple right-hand sides;

it includes the p-dependence of the Hermite basis, quartic, denominators, and endpoint functional;

it does not reconstruct the primitive functions themselves.

A naive rule

D
∥
	​

Q
=
wrong
L
p
	​

[D
∥
	​

f]

misses the derivative of the functional L
p
	​

, namely the D
∥
	​

M and D
∥
	​

ℓ terms.

Fixed-ρ derivative and moving endpoint

The safest convention is to substitute

z=2p−ρ

first and then differentiate at fixed ρ. For an unnormalized primitive h(z,p),

H(z,p)=h(z,p)−h(1/2,p),

so

D
∥
	​

H(2p−ρ,p)=(∂
p
	​

+2∂
z
	​

)h(2p−ρ,p)−∂
p
	​

h(1/2,p).
	​

(8)

The base point z=1/2 is fixed; it does not receive the 2∂
z
	​

 term.

For elliptic components, the derivative also acts on:

the quartic coefficients;

the selected value of Y;

algebraic marked points;

source Frobenius jets and moving mode vectors;

the regularization basis itself when it depends on p.

Equivalently,

D
∥
	​

Q=Reg
ρ=0
	​

D
∥
	​

[H(2p−ρ,p)Φ
S
	​

(ρ,p)V
S
	​

(p)].

The existing rational-layer implementation already normalizes H at its base point before storing endpoint values, so differentiating the base-point subtraction is required by its semantics.

4. Basis and derivative terms that must be present

The target embedding

B
I,T
	​

=T
25
	​

(B
G
	​

+Q)

has derivative

D
∥
	​

B
I,T
	​

=(D
∥
	​

T
25
	​

)(B
G
	​

+Q)+T
25
	​

(D
∥
	​

B
G
	​

+D
∥
	​

Q).
	​

(9)

The first term is mandatory.

If the connection is transformed consistently to the I basis, its target-target block contains the corresponding derivative term:

Γ
∥,TT
I
	​

=(D
∥
	​

T
25
	​

)T
25
−1
	​

+T
25
	​

Γ
∥,TT
F
	​

T
25
−1
	​

.

These terms cancel appropriately in the residual. Omitting D
∥
	​

T
25
	​

, or combining an I-basis selector with an F-basis connection, will leave a false residual.

Additional conditions are:

D
∥
	​

T
25
	​

 is the total fixed-ρ derivative. If T
25
	​

=T
25
	​

(p,z), use ∂
p
	​

+2∂
z
	​

 before setting z=2p.

The top 43 rows must be in the same source basis as the target-source block. If a source transformation T
S
	​

 is present, use B
I,S
	​

=T
S
	​

B
S
	​

.

Q must be added exactly once. If it already denotes the regularized action of H on the source modes, do not separately add HB
S
	​

.

B
G
	​

 must mean the target embedding in the G
25
	​

 basis, rather than a target embedding already shifted to F
25
	​

.

The 45-row ordering used by the connection must match the row ordering of the embedding.

Every tested epsilon order must have a complete convolution window under T
25
	​

, Ω, B
G
	​

, and Q. Differentiation does not change epsilon order, but multiplication does.

The selected root/elliptic branch must be differentiated on the same sheet; no new principal-square-root choice may be made at the test point.

Cheapest sequence

Choose the test basis explicitly.
Prefer the physical basis if the purpose is to test T
25
	​

's sign and multiplication order. Construct (1) entirely in that basis.

Determine the actual ρ-valuations.
For each target-source and target-target contribution, compute j
min
	​

 and retain only pairs satisfying (3).

Check whether modes 2,…,7 close under the right action.
Require (2). If it fails, do not call the pilot independent of mode 1.

At the first 61-bit prime and one fresh p:

stream target rows 5 and 6;

contract directly with the embedding jets;

test the explicit columns through the required ρ and epsilon orders.

A failure here means sign, row order, T
25
	​

, or basis orientation is wrong. Stop before differentiating the lazy functionals.

Differentiate the 16 lazy functionals using (6)–(8).
Reuse the adjoint factorization and complete the full residual.

Repeat the complete calculation at the second unused prime.

Only after both pass, reconstruct whatever reduced characteristic-zero target contraction or derivative object the portable solution actually needs.

Refusal conditions

Stop this route when:

the selector and connection are not in the same basis;

Ω
U,J
	​


=0 but the lazy columns were omitted;

the actual j
min
	​

 requires Frobenius jets beyond those available;

the endpoint/curve becomes singular at the selected p;

the Levelt exponent/Jordan type changes inside the sampled chamber;

the lazy derivative omits D
∥
	​

M, D
∥
	​

ℓ, or the derivative of the base-point subtraction.

Final ruling: the proposed target-row modular computation is the correct discriminating step. Its cheapest form is a streamed, truncated-ρ contraction in one declared basis, followed by an adjoint derivative of the 16 lazy endpoint functionals. Flatness and the already-known Ω,B cannot replace that independent contraction.