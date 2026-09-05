# Triple Root

## Question

# FACET consultation: three simultaneous square roots

We need an independent, decisive assessment of how to extend an exact
epsilon-form pipeline from rational two-variable function fields to three
simultaneous square roots.  Please challenge the proposed route and cite
primary literature or established software/methods where relevant.

## Goal and constraints

The calculation is an exact analytic NNLO QCD differential-equation project.
The immediate goal is an exact family epsilon-form transformation; later the
system will be transported and boundary constants fixed.  Fixed-kinematics
numerics may validate, but cannot replace, the exact result.

All current fast machinery assumes coefficients in `Q(x,y,eps)`: finite-field
sampling, sparse support discovery, modular reconstruction of rational gauges,
obstruction certificates, regulator factorization, and the final modular
identity/dlog check.  The three remaining families naturally live over a
multiquadratic function field in `(v,w)`.

The root triples are

```text
lambda1(v,w) = (1-v-w)^2 - 4 v w
lambda2(v,w) = lambda1(-v,w)
lambda3(v,w) = lambda1(v,-w)

CF259: sqrt(lambda1), sqrt(lambda3), sqrt(4v+w^2)
CF300 and CF303: sqrt(lambda2), sqrt(lambda3), sqrt(1-4vw)
```

There are exact rational charts for every single root and joint charts for
each Kallen pair, but no catalogued two-variable chart rationalizing an entire
triple.  It has not been proved that no such chart exists.  Current code can
assemble the family in an identity multiquadratic frame and can solve a strip
by moving to a rational chart when that individual strip uses a rationalizable
root subset.  The new rational finite-field off-diagonal solver is not wired to
the multiquadratic branch.  Downstream transport already admits algebraic
quadratic path letters.

## Fable's proposed route

Fable argues that there is no fundamental obstruction and proposes extending
the modular machinery rather than first finding a global chart:

1. choose primes and points `(v,w)` where all three radicands are nonzero
   quadratic residues (claimed density about `1/8`);
2. choose the three square roots modulo `p`;
3. express the gauge ansatz and identities in the nominal eight-element basis
   `{1,r1,r2,r3,r1 r2,r1 r3,r2 r3,r1 r2 r3}`;
4. extend the sampler/support census, obstruction residues, assembly,
   regulator factorization, and modular final certificate to this basis.

The estimate was a few days of work.  The alternative proposed decision was
to search first for a joint rational chart, which is cheap if one exists but
could be impossible.

## Issues on which we want a precise answer

### 1. Is the split-point finite-field proposal faithful?

At a fixed finite-field point where all radicands are squares, one chosen sign
triple maps the eight-dimensional generic multiquadratic algebra to a single
copy of `F_p`; the eight basis values become scalars.  It therefore appears
that one embedding cannot separate the eight coefficient components.  Would a
correct implementation need all eight Galois-conjugate sign choices at every
base point, followed by character/Walsh-Hadamard projection, or an equivalent
representation of the specialized etale algebra `F_p^8`?

Conversely, adjoining square roots of constants to a finite field does not
produce independent quadratic extensions of degree eight: finite fields have
only one quadratic extension.  Please state the mathematically correct
finite-field model and reconstruction algorithm for the generic field

```text
Q(v,w)[r1,r2,r3]/(ri^2-Delta_i).
```

Address multiplication, inversion, differentiation, solving linear systems,
interpolation of the eight rational coefficient functions, sign consistency,
and exact characteristic-zero lifting.

Is the acceptance density actually `1/8`?  State the assumptions needed on the
three square classes and how correlations/bad primes and rejection sampling
alter the probability/certificate.

### 2. What must be proved about the extension degree?

Before using an eight-element basis, should we prove that every nonempty
product of the three radicands is nonsquare in `Q(v,w)`?  Give an efficient
exact square-class-independence test and explain what changes if the generic
degree is 2 or 4 rather than 8.

### 3. Is a global rational chart worth testing first?

Simultaneous rationalization is rationality of the compositum/multiquadratic
cover, a surface rather than merely a one-variable curve.  What exact
algebraic-geometry calculation can prove rationality or non-rationality for
these two explicit triples?

Please distinguish:

- parametrizing one or two roots and studying the remaining double cover;
- the genus of a generic fiber;
- rationality/unirationality of the full surface;
- invariants of `(Z/2)^3` covers (geometric genus, Kodaira dimension,
  canonical divisor, Brauer/unramified-cohomology obstructions, etc.).

Is a simple "genus test" a theorem-level stop here, or only an obstruction to
a particular fibration-preserving parametrization?  Suggest concrete CAS
workflows (Sage, Magma, Singular, Maple, or another established system) and a
finite sequence of tests for these exact radicands.

### 4. What does the community normally do with several roots?

Rank the following for this project, and say which solve the epsilon-form
construction problem versus only the later integration problem:

1. exact computation directly in the multiquadratic function field;
2. different rationalizations for different pieces/path segments, with exact
   branch matching;
3. retaining algebraic dlog letters and using Chen iterated integrals;
4. generalized power-series/path-continuation methods such as DiffExp;
5. changing to a pure/UT basis found from Baikov leading singularities;
6. elliptic or more general iterated-integral technology if the cover is
   genuinely nonrational;
7. searching for a global rational parametrization.

We know of the 2025 paper "Rationalisation of multiple square roots in
Feynman integrals" (Papathanasiou, Weinzierl, Wu, Zhang), which treats seven
roots using different parametrizations of the same path.  Explain exactly how
far that method helps here: can it construct a coherent two-variable family
epsilon form and gauge, or does it mainly solve the subsequent path
integration once an algebraic epsilon form is already known?

### 5. Recommend a minimal pilot

Give a prioritized finite sequence of calculations, each with a sharp
continue/abandon criterion.  We especially want to know whether the first
pilot should be:

- an algebraic-geometry rationality test;
- a root census proving every actual off-diagonal strip uses at most two roots,
  allowing the existing per-strip chart method to finish without a full
  extension solver;
- a small multiquadratic finite-field prototype using all Galois conjugates;
- or a pure-basis/segment-wise route.

Please estimate which components are genuinely new and which can reuse a
rational finite-field sampler.  Identify any reason the claimed "few days"
estimate is too optimistic.  End with a decisive route recommendation and the
exact acceptance certificate that would justify promoting these families to
the production pipeline.

## Pro response

Decisive assessment

The proposal is not correct as stated. Fable is right that exact modular computation in the multiquadratic field is viable. Fable is wrong on three material points:

A single split-point sign choice is not faithful. A general element requires all eight Galois conjugates, or an equivalent eight-dimensional finite étale algebra representation.

The implementation is not merely an extension of the sampler. Linear-system normalization, inversion, pole/residue logic, differentiation, and exact certification all change.

A global two-variable rational chart is not merely uncatalogued. It is impossible for both root triples. The simultaneous-root cover is a nodal K3 surface, so it is not even unirational in characteristic zero.

The best route is therefore:

First perform a dependency-closed root census of the actual off-diagonal solves. If every solve component has square-class rank at most two, finish with the existing chart machinery. Otherwise implement an eight-conjugate multiquadratic modular solver. Do not spend further effort searching for a global chart.

1. The correct finite-field model

Let

K=Q(v,w,ϵ),E=K(r
1
	​

,r
2
	​

,r
3
	​

),r
i
2
	​

=Δ
i
	​

.

Once the three square classes are independent, E/K is a Galois extension of degree eight with

G=Gal(E/K)≅(Z/2Z)
3
.

A convenient basis is

e
S
	​

=
i∈S
∏
	​

r
i
	​

,S⊆{1,2,3}.
Why one split embedding fails

At a modular point a=(v
0
	​

,w
0
	​

,ϵ
0
	​

), let

δ
i
	​

=Δ
i
	​

(a)∈F
p
×
	​

.

If every δ
i
	​

 is a square and ρ
i
2
	​

=δ
i
	​

, then a sign choice

r
i
	​

⟼ρ
i
	​


is only one projection

F
p
	​

[t
1
	​

,t
2
	​

,t
3
	​

]/(t
i
2
	​

−δ
i
	​

)⟶F
p
	​

.

It has a large kernel. For example, t
1
	​

−ρ
1
	​

 is nonzero in the specialized algebra but maps to zero. Consequently, a nonzero obstruction, matrix entry, or gauge coefficient can disappear in one chosen embedding.

The correct split specialization is

A
a
	​

=F
p
	​

[t
1
	​

,t
2
	​

,t
3
	​

]/(t
i
2
	​

−δ
i
	​

)≅F
p
8
	​

.

All eight factors correspond to

t
i
	​

↦σ
i
	​

ρ
i
	​

,σ
i
	​

∈{±1}.

Thus the user's concern is exactly correct: one must use all eight signs or an equivalent representation of A
a
	​

.

Why adjoining constants does not give F
p
8
	​


For every odd finite field,

F
p
×
	​

/(F
p
×
	​

)
2
≅Z/2Z.

There is only one nontrivial quadratic extension, F
p
2
	​

. Therefore:

A
a
	​

≅
⎩
⎨
⎧
	​

F
p
8
	​

,
(F
p
2
	​

)
4
,
	​

all δ
i
	​

 are squares,
at least one δ
i
	​

 is a nonsquare,
	​


provided all δ
i
	​


=0. It is never a degree-eight field obtained by adjoining three constant square roots.

If a radicand vanishes, the specialization is not étale and contains nilpotents; those points must be rejected.

Walsh–Hadamard reconstruction

Write

f=
S⊆{1,2,3}
∑
	​

c
S
	​

e
S
	​

,c
S
	​

∈K.

For σ=(σ
1
	​

,σ
2
	​

,σ
3
	​

), define

f
σ
	​

(a)=f(a;σ
1
	​

ρ
1
	​

,σ
2
	​

ρ
2
	​

,σ
3
	​

ρ
3
	​

),
χ
S
	​

(σ)=
i∈S
∏
	​

σ
i
	​

,ρ
S
	​

=
i∈S
∏
	​

ρ
i
	​

.

Character orthogonality gives

c
S
	​

(a)=
8ρ
S
	​

1
	​

σ∈{±1}
3
∑
	​

χ
S
	​

(σ)f
σ
	​

(a)
	​

.

This is the Fourier transform of G=(Z/2)
3
, equivalently a scaled Walsh–Hadamard transform.

The same formula works over F
p
2
	​

 at nonsplit points. Since the desired coefficients c
S
	​

(a) lie in F
p
	​

, Frobenius invariance of the projected coefficients provides an additional diagnostic.

Required arithmetic

For subsets S,T,

e
S
	​

e
T
	​

=(
i∈S∩T
∏
	​

Δ
i
	​

)e
S△T
	​

	​

.

The principal operations should be implemented as follows.

Operation	Correct implementation
Multiplication	Use the subset-XOR formula above, or transform to the eight sign components, multiply componentwise, and transform back.
Scalar inversion	At a split point, invert all eight f
σ
	​

, reject if any is zero, and project back. Symbolically, solve the 8×8 multiplication-matrix system; its determinant is Norm
E/K
	​

(f).
Matrix inversion	Invert every conjugate matrix. Reject the point if any conjugate determinant vanishes. A chosen embedding being invertible is insufficient.
Differentiation	Extend the derivations by ∂
x
	​

r
i
	​

=(∂
x
	​

Δ
i
	​

)/(2Δ
i
	​

)r
i
	​

. Root parity is preserved.
Linear systems	Solve all eight conjugate field-valued systems and project, or solve the expanded 8n-dimensional base-field system.
Rational reconstruction	Apply the existing rational reconstruction independently to the eight c
S
	​

(v,w,ϵ).
Exact equality	Reduce to the eight-element basis and require every rational coefficient to vanish.

Explicitly,

∂
x
	​

(c
S
	​

e
S
	​

)=[∂
x
	​

c
S
	​

+
2
c
S
	​

	​

i∈S
∑
	​

Δ
i
	​

∂
x
	​

Δ
i
	​

	​

]e
S
	​

,x∈{v,w}.

Pointwise values alone cannot be numerically differentiated. The implementation must differentiate the ansatz before evaluation, propagate derivative jets, or reconstruct first and differentiate exactly.

The important linear-system caveat

If the conjugate system has a unique normalized solution, solving all eight conjugates and projecting is valid.

Gauge construction is often underdetermined because of residual constant transformations. Eight independent row reductions may then choose eight unrelated representatives. Their Walsh projection need not define a coherent element of E.

Therefore the solver needs one of:

normalization conditions defined over K, imposed identically in every conjugate;

predetermined Galois-stable pivots, rejecting points where the pivot pattern changes;

or a coupled solve in the eight coefficient channels.

This is one of the main reasons the production implementation is substantially more than adding a root loop.

Existing finite-field reconstruction frameworks such as Peraro's reconstruction algorithms, FiniteFlow, and FireFly can be reused for the eight rational channels, but they do not remove the need for this algebra/Galois layer. 
arXiv
+2
arXiv
+2

Sign consistency

The modular roots ρ
i
	​

 may be chosen independently at each point. There is no requirement to make them continuous across finite-field samples.

The projected c
S
	​

(a) is invariant under

ρ
i
	​

↦−ρ
i
	​


provided the corresponding sign components are relabelled consistently. This invariance should be a mandatory unit test.

These modular signs have no relation to the physical branches. The physical sheet is fixed later by choosing root values at a physical base point and analytically continuing them along the transport path.

Acceptance density

For quadratic character χ,

N
p
	​

=
8
1
	​

(v,w)∈F
p
2
	​

Δ
1
	​

Δ
2
	​

Δ
3
	​


=0
	​

∑
	​

i=1
∏
3
	​

(1+χ(Δ
i
	​

)).

If every nonempty product

Δ
S
	​

=
i∈S
∏
	​

Δ
i
	​


remains nonsquare in 
F
p
	​

(v,w)
	​

, character-sum estimates give

N
p
	​

=
8
p
2
	​

+O(p
3/2
),Pr(all three residues)=
8
1
	​

+O(p
−1/2
).

The zero loci and additional rejected denominator/pivot loci remove O(p) points and therefore contribute O(p
−1
) to the probability.

Thus “about 1/8” is asymptotically correct, not exact. It assumes:

square-class rank three after reduction;

no product becoming a constant times a square;

p

=2;

nonzero radicands;

no vanishing gauge denominators, pivots, determinants, or norms;

sufficiently large good primes.

If the square-class rank is d<3, the character triples lie in a subgroup or coset. When the all-positive pattern is compatible, its expected density is approximately 2
−d
; a nonsquare constant relation can make it impossible for some primes.

Rejection sampling does not weaken the final certificate if the reconstructed characteristic-zero identities are checked exactly. It only changes sampling efficiency. Since Legendre-symbol rejection is cheap, the primary expensive overhead is approximately eight conjugate solves per accepted base point, not 8×8 expensive solves.

2. The generic degree is exactly eight for both triples

Yes, the degree must be proved before adopting the eight-element basis. Otherwise the representation is redundant and coefficient reconstruction is nonunique.

General exact test

For each Δ
i
	​

∈Q(v,w)
×
:

Factor its numerator and denominator in the UFD Q[v,w].

Record every irreducible valuation modulo two.

Record the rational unit in Q
×
/Q
×2
, including sign and prime-content exponents.

Form an F
2
	​

 matrix whose columns are the square-class vectors of the Δ
i
	​

.

Compute its rank d.

Then

[E:K]=2
d
.

This proves all nonempty products nonsquare exactly; there is no need to test the seven products separately once the rank is known.

Application to these radicands

Homogenize with z:

Λ
1
	​

Λ
2
	​

Λ
3
	​

Q
4
	​

Q
5
	​

	​

=(z−v−w)
2
−4vw,
=(z+v−w)
2
+4vw,
=(z−v+w)
2
+4vw,
=w
2
+4vz,
=z
2
−4vw.
	​


The symmetric 3×3 matrix of each ternary quadratic has determinant

−4.

Hence every one is a smooth, absolutely irreducible projective conic in characteristic zero. Within either triple, the three conics are distinct and coprime.

Consequently, any nonempty product of the three selected radicands has odd valuation along at least one conic that occurs in no other factor. It cannot be a square.

Therefore,

[Q(v,w)(r
1
	​

,r
2
	​

,r
3
	​

):Q(v,w)]=8
	​


for CF259 and for CF300/CF303. Adjoining the independent transcendental ϵ does not change this.

If the rank were smaller

If d=1 or 2, choose independent square classes β
1
	​

,…,β
d
	​

 and write

Δ
i
	​

=q
i
2
	​

j=1
∏
d
	​

β
j
a
ij
	​

	​

,a
ij
	​

∈F
2
	​

.

Use the 2
d
-element basis generated by 
β
j
	​

	​

, and only 2
d
 conjugates. Retaining a nominal eight-element basis would give linearly dependent basis elements, nonunique projected coefficients, and unreliable support reconstruction.

3. A global rational chart is impossible

This can be settled exactly without a prolonged parametrization search.

The full simultaneous-root cover

For either triple, introduce homogeneous root coordinates R
1
	​

,R
2
	​

,R
3
	​

 and define

X={R
1
2
	​

=C
1
	​

(v,w,z),R
2
2
	​

=C
2
	​

(v,w,z),R
3
2
	​

=C
3
	​

(v,w,z)}⊂P
5
.

Here C
i
	​

 are the three relevant homogeneous conics. Because the square classes are independent, this is a connected degree-eight cover of P
2
. It is a complete intersection of three quadrics.

Adjunction gives

K
X
	​

=O
P
5
	​

(−6+2+2+2)
	​

X
	​

=O
X
	​

.

The exact intersection geometry is:

Family	Tangent pair	Tangency point	Third conic there
CF259	Λ
1
	​

,Λ
3
	​

	[1:0:1]	Q
4
	​

=4
CF300/303	Λ
2
	​

,Λ
3
	​

	[1:−1:0]	Q
5
	​

=4

The relevant identities are

Λ
3
	​

−Λ
1
	​

=4w(v+z),

and

Λ
3
	​

−Λ
2
	​

=−4z(v−w).

In each case:

the indicated pair has one simple tangency and two further transverse intersections;

every intersection involving the third conic is transverse;

there are no triple intersections.

Over a transverse intersection of two branch conics, the full (Z/2)
3
 cover is locally smooth:

u
2
=x,v
2
=y.

Over the simple tangency it has two ordinary double points, one for each sign of the nonvanishing third root. Thus X has precisely two A
1
	​

 singularities. Their resolution is crepant.

The minimal resolution 
X
 therefore satisfies

K
X
	​

=0,h
1
(
X
,O
X
	​

)=0,p
g
	​

(
X
)=1.

Hence:

X
 is a K3 surface.
	​


The same conclusion follows from the product-root quotient

Y:q
2
=C
1
	​

C
2
	​

C
3
	​

⊂P(1,1,1,3).

Its branch sextic consists of the three conics. It has ten transverse pair-intersection points and one simple tangency, so the double cover has ten A
1
	​

 singularities and one A
3
	​

; its minimal resolution is again a K3 surface.

The general abelian-cover framework is treated by Pardini. 
European Digital Mathematics Library
 Similar K3-based nonrationalizability arguments have been applied directly to square roots arising in Drell–Yan integrals: a rational variable change would give a unirational parametrization of the K3 surface, which is impossible in characteristic zero. 
arXiv
+2
arXiv
+2

Consequence for a chart

A two-variable rational substitution that rationalizes all roots over a kinematically open set would define a dominant rational map

P
2
⇢X.

In characteristic zero this map is generically separable. A nonzero holomorphic two-form on the K3 resolution would pull back to a holomorphic two-form on a rational surface, but none exists. Therefore X is not unirational.

So:

No dominant rational two-variable simultaneous rationalization exists.
	​


This excludes not only a birational chart but any useful dominant rational parametrization of the full kinematic surface.

It does not exclude one-dimensional rational paths on the K3 surface. That distinction is precisely why path-by-path rationalization can still work later.

Why a generic-fiber genus test is weaker

Suppose one first rationalizes one or two roots and regards the remaining equation as a double cover over a chosen base parameter. The generic fiber may have genus g>0.

That proves only:

no rationalization exists that preserves that particular fibration and makes its generic fiber rational.

It is not a proof that the full surface is nonrational. Rational surfaces can carry genus-one fibrations, so generic-fiber genus is not a birational invariant of the underlying surface independently of the chosen fibration.

For these triples, the K3 calculation—p
g
	​

=1, K=0, κ=0—is the theorem-level stop. Brauer-group or unramified-cohomology calculations are unnecessary. Those subtler invariants are most useful when elementary birational invariants such as p
g
	​

 fail to decide rationality.

Concrete CAS workflow

A finite exact workflow is:

Sage or Singular: homogenize and factor the five quadrics; compute their symmetric-matrix determinants.

For every selected pair C
i
	​

,C
j
	​

, compute the saturated nontransversality ideal

⟨C
i
	​

,C
j
	​

,all 2×2 minors of (
∇C
i
	​

∇C
j
	​

	​

)⟩:(v,w,z)
∞
.

Compute

⟨C
1
	​

,C
2
	​

,C
3
	​

⟩:(v,w,z)
∞

to exclude triple intersections.

Construct X⊂P
5
, compute the Jacobian-rank singular locus, and verify the two local A
1
	​

 normal forms.

Magma: independently check normality, simple singularities, geometric genus, irregularity, Kodaira dimension, or resolve the surface. Magma documents direct functions for these surface invariants and resolutions. 
Magma Handbook

Use Maple's algcurves or Sage curve functionality only for a chosen generic fiber. That is a curve calculation, not a surface-rationality proof.

RationalizeRoots remains useful as a positive-search tool for individual roots or rationalizable pairs, but failure of its line-parametrization algorithm is not itself a nonrationality proof. 
arXiv
+1

For modular work, conservatively exclude p=2, primes where the conic-intersection resultants or discriminants change, and all primes arising from DE denominators. In this compactification, p=5 changes some pair-intersection multiplicities, so it should also be blacklisted for geometry-sensitive tests even though the generic square-class rank remains three.

4. Ranking the available routes

For the immediate task—constructing an exact family epsilon transformation—the ranking is:

Priority	Route	Constructs the family epsilon gauge?	Assessment
1	Exact computation in E	Yes	General production solution once a rank-three solve occurs.
2	Separate rational charts for solve blocks	Conditionally	Best shortcut if every dependency-closed solve block has root rank ≤2.
3	Pure/UT basis from Baikov leading singularities	Sometimes	Strong parallel attempt; may make the transformation explicit or simpler, but does not guarantee completion.
4	Algebraic dlog letters and Chen integrals	No	Exact formal transport after the epsilon form is known.
5	Different path rationalizations	No	Can convert later path integrals to MPLs or simpler forms.
6	DiffExp/generalized path series	No	Numerical or high-precision transport and validation.
7	Elliptic/K3 iterated-integral technology	Not presently	Adopt only if the actual maximal cuts/Picard–Fuchs system demands it.
8	Global rational parametrization	No	Ruled out by the K3 calculation.
1. Direct multiquadratic arithmetic

This is the only general route among those listed that directly addresses the gauge problem under the assumption

T(v,w,ϵ)∈Mat
n
	​

(E).

It preserves exactness and allows the existing modular rational reconstruction to be used channel by channel.

One remaining mathematical risk is that the required gauge may lie in an extension larger than E. The fact that the input connection lies in E does not prove that an epsilon transformation exists in E. The pilot must therefore either construct T∈E or reconstruct a nonzero obstruction certificate.

2. Different rationalizations

Two different ideas are being grouped here and must be separated.

For matrix strips or solve blocks: this can construct the epsilon form if every complete solve dependency lies in a rank-one or rank-two subfield that has a known rational chart.

For path segments or path-independent integral combinations: this concerns the later integration of an already epsilon-factorized connection. It does not construct the two-variable gauge.

A recent multiroot calculation exploited definite root parity to factor out the algebraic part and reduce coefficient fits to rational problems. This supports doing a root-parity census before implementing a full extension solver, but that work started from a canonical system rather than solving a general algebraic gauge problem. 
arXiv

3. Algebraic dlogs and Chen integrals

Once

dJ=ϵΩJ,Ω=
k
∑
	​

C
k
	​

dlogL
k
	​

,L
k
	​

∈E
×
,

the formal solution is an exact Chen series. No global rational chart is required.

This is already compatible with the stated downstream transport. It solves the function-representation and transport problem, not the gauge-construction problem.

4. Papathanasiou–Weinzierl–Wu–Zhang

The 2025 paper explicitly starts from an epsilon-factorized differential equation with algebraic dlog arguments. It then uses path independence and reparametrization independence to apply different rationalizations to different path-independent subsets or to different parameterizations of the same path. Their seven-root pentagon example demonstrates that simultaneous global rationalizability is sufficient but not necessary for an MPL representation. 
arXiv
+2
arXiv
+2

For FACET, the method can:

rationalize root subsets along transport paths;

organize path-independent boundary-constant contributions;

potentially convert algebraic Chen integrals to MPLs;

permit different charts on different path portions with exact branch matching.

It does not provide:

the two-variable gauge T(v,w,ϵ);

a finite-field solver over E;

a coherent global rational chart;

or an obstruction certificate for the epsilon transformation.

Thus it is a downstream integration method here, unless the off-diagonal gauge construction has already decomposed into independently rationalizable blocks for unrelated reasons.

5. UT/Baikov route

Baikov leading singularities and dlog-integrand methods can identify algebraic normalizations and candidate UT bases. They have successfully produced canonical systems in complicated multiscale examples. 
arXiv
+1

For these families, this should run in parallel on the top sectors. It is successful as a replacement for the gauge solver only if the resulting full, including lower-sector and off-diagonal, connection satisfies

A
new
	​

=ϵΩ

exactly. A top-sector UT normalization alone does not settle the family.

6. DiffExp

DiffExp transports differential equations along one-dimensional lines using truncated generalized series. It is appropriate for high-precision validation, boundary matching, and checking physical branches. It neither constructs the family epsilon transformation nor gives the requested exact two-variable analytic result. 
arXiv

7. Elliptic or K3 technology

The simultaneous-root cover being K3 does not imply that the master integrals require K3 periods or even elliptic functions.

Nonrationality of the letter cover says only that all roots cannot be globally rationalized. If the connection is algebraic dlog and epsilon-factorized, Chen iterated integrals remain sufficient. More general function classes should be introduced only if the actual maximal cuts or Picard–Fuchs operators exhibit irreducible higher-genus periods or the dlog epsilon-form hypothesis fails.

5. Minimal pilot with sharp decisions
Stage 0 — Record the exact geometry certificate

This is now settled:

square-class rank 3;

degree-eight compositum;

simultaneous cover is a nodal K3;

no global rational chart.

Decision: abandon global chart searching for these triples. Continue positive chart searches only for individual roots and known rank-two subsets.

Stage 1 — Dependency-closed root census

This should be the first engineering pilot.

Represent root parity by

s=(s
1
	​

,s
2
	​

,s
3
	​

)∈F
2
3
	​

,r
s
=r
1
s
1
	​

	​

r
2
s
2
	​

	​

r
3
s
3
	​

	​

.

For every off-diagonal solve node, collect parities from:

the coefficient matrix being solved;

its inhomogeneous/source term;

upstream diagonal and off-diagonal transformations;

any T
−1
 factors already required;

normalization conditions;

regulator-factorization operations;

subsequent products needed before the next solve.

Take the F
2
	​

-span of this complete set. Multiplication corresponds to XOR, differentiation preserves parity, and inversion stays inside the subfield generated by the union of parities.

Continue with existing per-strip charts if and only if

dim
F
2
	​

	​

V
solve
	​

≤2

for every complete solve component, not merely for every individual entry or displayed strip.

A matrix whose separate entries each contain two roots can still generate rank three after inversion or coupling. The census must propagate through the solve DAG to a fixed point.

Abandon the chart-only construction immediately if any solve node has rank-three closure.

If all solve nodes pass, the assembled global T may still collectively involve all three roots. That is acceptable provided the results are mapped back to the identity multiquadratic frame and the final global identity can be checked there. In that case only a lean rank-three verifier is needed, not a full rank-three off-diagonal solver.

Stage 2 — Eight-conjugate prototype

If any actual rank-three solve appears, implement the smallest possible prototype:

exact eight-channel multiplication and differentiation;

split-point generation with nonzero roots;

all eight sign evaluations;

Walsh–Hadamard projection;

scalar and matrix inversion with norm/pivot rejection;

a uniquely normalized linear system;

one underdetermined system with explicitly Galois-stable normalization;

componentwise use of the existing reconstruction code.

Use three tests:

a synthetic element/system with all eight channels known;

a known rank-two strip, comparing against its rational chart;

the smallest actual rank-three off-diagonal block.

Continue to production only when the actual block reconstructs an exact T∈E and satisfies the characteristic-zero transformed-connection identity.

Abandon the assumption T∈E if a stable, reconstructed obstruction remains nonzero or if all generic conjugate systems demonstrate that a required algebraic normalization lies outside E. Failure of a low-degree ansatz alone is not such a certificate.

Stage 3 — UT/Baikov pilot in parallel

Apply maximal-cut/leading-singularity analysis to the top sectors and test candidate root normalizations.

Promote it to the primary route only if the full transformed DE, including lower sectors, is exactly epsilon-factorized.

Otherwise retain the UT information as a complexity reducer for the multiquadratic solve.

Stage 4 — Production integration

Only after the block prototype passes should the following be generalized:

sparse support discovery in eight channels;

obstruction residues;

assembly and inverse transformations;

regulator factorization;

algebraic pole and norm handling;

final dlog decomposition;

deterministic exact certification.

Stage 5 — Transport and boundaries

After the algebraic epsilon form is fixed:

retain algebraic dlog letters and use Chen transport;

use Papathanasiou-type path rationalizations where their path-independence conditions hold;

use DiffExp or fixed-kinematics numerical solvers for validation;

record physical root signs and monodromy separately from modular root choices.

6. What can be reused, and what is genuinely new
Directly reusable

prime and point generation;

the scalar F
p
	​

 linear solver;

sparse monomial support machinery after projection;

multivariate rational interpolation;

CRT and rational reconstruction;

held-out-prime and held-out-point checks;

rational per-strip charts;

scheduling and caching infrastructure.

Genuinely new

square-class and Galois-group metadata;

eight-conjugate batching;

Walsh–Hadamard projection;

multiquadratic multiplication, derivation, trace, and norm;

zero-divisor and conjugate-determinant rejection;

Galois-stable gauge normalization and pivot policy;

componentwise obstruction certificates;

exact algebraic pole/residue handling;

rank-three assembly and inversion;

exact eight-channel dlog verification;

separation of modular signs from physical branch sheets.

Why “a few days” is too optimistic

A few days is plausible for a toy implementation that round-trips an algebraic scalar and solves a unique small linear system. It is not credible for production integration.

The main costs are not the Hadamard transform itself:

eight expensive conjugate solves per accepted base point;

up to eight rational functions reconstructed per matrix entry;

denominator growth through field norms;

possible loss of sparsity after inversion;

conjugate-dependent accidental pivots;

residual-gauge alignment across conjugates;

algebraic divisors whose rational norms combine several sheets;

modifications to obstruction, regulator, and dlog certificates;

exact characteristic-zero verification;

regression against all existing rational and pair-chart families.

The runtime increase can also exceed a simple factor of eight because a compact algebraic inverse may acquire a dense rational denominator equal to a degree-eight norm.

Decisive route recommendation and production certificate
Recommended route

Adopt the K3 result as a permanent no-go certificate for global rationalization.

Run the dependency-closed root census first.

If every solve block has rank at most two, finish using the existing charts and add only a rank-three exact verifier.

On the first genuine rank-three block, implement the all-eight-conjugate solver; do not use a single split embedding.

Run a UT/Baikov normalization search in parallel, but accept it as a replacement only after an exact full-family epsilon check.

Reserve Chen/path rationalization/DiffExp for transport and validation after the gauge is known.

Exact acceptance certificate

A family should be promoted to the production pipeline only when a machine-checkable certificate contains all of the following.

A. Field certificate

Exact factorization or valuation matrix proving square-class rank three.

The ordered basis

{1,r
1
	​

,r
2
	​

,r
3
	​

,r
1
	​

r
2
	​

,r
1
	​

r
3
	​

,r
2
	​

r
3
	​

,r
1
	​

r
2
	​

r
3
	​

}.

Explicit multiplication and Galois-action tables.

A prime blacklist including 2, geometry/denominator/resultant primes, and family-specific bad primes.

B. Modular-algebra certificate

At every accepted sample:

all δ
i
	​


=0;

all eight conjugates evaluated;

all required conjugate pivots and determinants nonzero;

Hadamard forward/inverse round-trip succeeds;

random local sign flips leave projected coefficients unchanged;

underdetermined solves use the same Galois-stable normalization;

optional nonsplit F
p
2
	​

 results agree and project to the Frobenius-fixed F
p
	​

 subfield.

C. Reconstruction certificate

For every matrix entry and every subset S:

T
ij,S
	​

(v,w,ϵ)=
Q
ij,S
	​

P
ij,S
	​

	​

∈Q(v,w,ϵ)

is reconstructed in a fixed primitive normalization and is stable under:

additional primes;

held-out points;

increased support bounds;

comparison with known pair-chart pullbacks.

D. Exact gauge certificate

With a fixed convention, for example

I=TJ,

verify exactly

A
can
	​

=T
−1
AT−T
−1
dT=ϵΩ.

Required identities are:

TT
−1
=1,
Norm
E/K
	​

(detT)

=0,
∂
ϵ
	​

(
ϵ
A
can
	​

	​

)=0,
dΩ−ϵΩ∧Ω=0,

and, when a dlog form is claimed,

Ω=
k
∑
	​

C
k
	​

dlogL
k
	​

,C
k
	​

 constant,L
k
	​

∈E
×
.

Every identity must be reduced to the eight-element basis, denominators cleared, and all eight resulting polynomials in Q[v,w,ϵ] shown to vanish identically.

The obstruction residues and regulator-factorization identities must pass the same eight-component test.

E. Exactness standard

Fresh-prime/all-conjugate evaluations are strong regression tests but remain probabilistic unless supplemented by bounds.

The final certificate must use either:

direct characteristic-zero polynomial reduction; or

a deterministic modular proof with established multidegree and coefficient-height bounds, an unisolvent evaluation set, and a CRT modulus exceeding the uniqueness bound.

Without one of these, the final “modular identity check” is not an exact certificate.

F. Physical branch certificate

Separately record:

the physical base point;

the characteristic-zero signs of all r
i
	​

 there;

the path or path homotopy class;

branch-locus avoidance or prescribed crossings;

analytic-continuation and monodromy conventions.

This branch record is required for transport but must not be inferred from finite-field square-root choices.

Production promotion is justified only after one actual rank-three block and then the full family satisfy this exact eight-component characteristic-zero certificate.
