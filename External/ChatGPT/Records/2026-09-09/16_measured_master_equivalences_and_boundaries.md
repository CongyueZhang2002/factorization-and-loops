# Measured master equivalences and analytic boundaries

Verified model: gpt-6-pro. Request: 0aec74e6-0a70-47aa-8eb6-1634c629f03d. HTTP 200.

## Question

Continue the integrated electromagnetic SIDIS NNLO review for the general first-principles FeynFacet framework (repository https://github.com/CongyueZhang2002/factorization-and-loops, local changes ahead of pushed branch). No hard coefficients/masters/boundaries from literature in production. Universal operator/splitting kernels are allowed.

Progress: UU q->qgg cut IBP/derivative closure now yields 56 spanning masters in 14 denominator bases. All epsilon-zero coupled blocks admit rational triangularizing gauges; entire 56-row preparation takes 3.3 seconds. Other q-q RR quark-pair DEs are also constructed. Exact NLO real tests of the joint BMHV-current/PDF angular shortcut pass, and the full flavor Z1/Z2 kernels match 2510.00100 Appendix A and independently 1409.5131 A.2/A.3, including the axial nonsinglet first moment. RV joint loop treatment remains to be checked.

Please critically review the next general step: eliminate repeated integrals across complete denominator bases BEFORE solving/evaluating boundary values. Existing exact equivalence code chooses new loop coordinates from L independent oriented on-shell particle momenta with integer/rational affine transformation determinant +/-1, transforms all inverse propagators and powers, keeps external kinematics and all active ordinary i0 signs. For measured families I will extend its signature to:
* particle cuts: exact transformed quadratic polynomial, positive-energy oriented momentum, derivative power;
* measurement cuts: exact transformed linear polynomial and derivative power; do not give these an energy theta or use them as loop-coordinate vectors;
* common explicit Lorentz-invariant phase-space prefactor, cut-discontinuity normalization, D, external frame/time direction, and stated domain;
* ordinary factors: exact transformed polynomial, i0 sign, nonzero integer power, retaining numerator powers too.
Only identical signatures imply equality with factor one. No rescaling of cut arguments, no removal of i0, no external-variable transformations or endpoint limits.
Then construct a shared DE from these identities, retaining differential compatibility and all original target substitutions. Is anything missing for differentiated measurement cuts or the meromorphically continued particle-tip extension?

Also give a focused strategy for analytic boundary values of the resulting RR master system, which should be generic code for this measured three-body class. Available exact chart:
s23=S(1-z)t,
s12=S[y+zt-(1+z)ty-2 sqrt(zt(1-t)y(1-y)) (1-2a)],
s13=S-s12-s23,
2p.ki/J={z,(1-z)y,(1-z)(1-y)},
measure V3(z)*Beta(t;1-e,1-e)*Beta(y;1-e,1-e)*Beta(a;1/2-e,1/2-e), V3=S/(2pi) Phi2(S)^2 z^-e (1-z)^(1-2e).
We have generic regular-singular/Frobenius mode matching, Gamma/Beta Euler integration and SubTropica fallback, but cannot treat this unit-cut massless chart as a dotted-particle-cut identity. Which boundary stratum/physical matching is most likely to yield simple exact Gamma/Beta constants, and what would a sound automatic implementation need? Distinguish proven usable steps from suggestions. No ad hoc family-specific boundary constants.


## Pro response

Your proposed factor-one equivalence is sufficient under the stated restrictions, including for differentiated measurement cuts. The important additions are to verify the identities off the cut surfaces, carry the common meromorphic forward-cut definition, and close the resulting relations under both differential equations before assigning boundary constants.

For boundary evaluation, I recommend the ordered double-threshold corner

ρ=1−x→0,σ=1−z→0,

starting with the ρ-expansion at generic z. This has a useful uniform-expansion argument for a recognizable class of your denominators. However, the subsequent σ-limit retains correlated angular singularities: it is not generally a product of elementary beta integrals.

1. The exact-equivalence contract

Let a candidate routing be

ℓ
r
′
	​

=A
rs
	​

ℓ
s
	​

+B
ra
	​

p
a
	​

,A,B∈Q(x,z),detA=±1,

real and nonsingular throughout its declared physical chart.

For a factor-one identity, require the pullback of the complete integrand and integration cycle to agree. Matching denominator polynomials without the cycle is insufficient for cut integrals; the distinction between integrand and contour is fundamental. 
arXiv

Your signature captures the necessary data, subject to the following implementation details.

Exact means before imposing the cuts

For every particle slot, verify

q
i
′
	​

∘F=q
π(i)
	​

,D
i
′
	​

∘F=D
π(i)
	​

,ν
i
′
	​

=ν
π(i)
	​


as affine-vector and polynomial identities using only the declared external kinematic relations.

Do not establish the polynomial identity modulo

k
i
2
	​

=0,G
m
	​

=0.

For example,

G
m
′
	​

∘F=G
m
	​

+ck
2
2
	​


is not the identity required by your proposed signature. It agrees on the unit-cut support but changes the normal coordinates of dotted cuts.

The same rule applies to numerator powers. Inactive ordinary slots with power zero should not participate in the signature: otherwise different denominator completions of the same integral remain artificially distinct. Active numerator factors must participate, including their transformed polynomial, rather than merely their position in the original basis.

A transformed numerator that becomes a sum is not a failure of the mathematical routing, but it lies outside your single-signature, factor-one matcher. Retaining it as unmatched is safe. Linear relations can handle it separately.

The determinant contributes no sign

For the real loop-component measure,

r
∏
	​

d
D
ℓ
r
′
	​

=∣detA∣
D
r
∏
	​

d
D
ℓ
r
	​

=
r
∏
	​

d
D
ℓ
r
	​

.

Thus detA=−1 introduces neither (−1)
D
 nor an extra i. The normalized-loop-measure phases remain whatever is already specified in the common integral normalization.

Keep the route witness along with the canonical signature. A signature match should be reproducible by an actual allowed map, not only by polynomial sorting.

Measurement derivatives need no extra rule under an exact normal-coordinate match

If

G
m
′
	​

∘F=G
m
	​


exactly, then

C
n
	​

(G
m
′
	​

)∘F=C
n
	​

(G
m
	​

)

for every finite n, with the same definition

C
n
	​

(G)=
(n−1)!
(−1)
n−1
	​

δ
(n−1)
(G).

There is no new factorial or sign: those are already part of C
n
	​

. Your decision to prohibit rescaling avoids the corresponding normal-coordinate factors entirely. Distributional derivatives retain precisely this dependence on the defining function, not just its zero set. 
DLMF

Preserve the measurement Jacobian J=Q
2
/x, any other external normalization, and all ordinary prescriptions. Ghost/state-sum weights, charges, and channel multiplicities should remain outside the scalar-master identity; they belong in the target coefficients.

Particle tips are covered by the same change-of-variables proof

An exact permutation of the directed momenta maps

q
i
	​

=0⟷q
π(i)
	​

=0.

It preserves the forward cones, not just their smooth nonzero parts.

To justify equality of the continued dotted cuts, use the same meromorphic forward-cut definition on both sides. Establish the change of variables in a common regulated domain and continue that identity. Equivalently, where your auxiliary mass construction is used, the routing must extend with the independent mass labels permuted:

q
i
′2
	​

−μ
i
′
	​

⟼q
π(i)
2
	​

−μ
π(i)
	​

.

This does not require additional tip constants. It requires that the two records have not independently selected different extensions at the massless tip. A shared cut-definition contract is enough; arbitrary per-family contact-term conventions would not be.

A kinematics-dependent routing is acceptable at each fixed interior point. Its external derivative can differ from the derivative in another routing by loop total derivatives. That is a reason to check differential compatibility after reduction, not to reject the equivalence.

The resulting equivalence is sufficient, not complete. Failure to match these signatures does not establish independence. Do not enlarge the matcher to prescription-changing, cut-rescaling, or parameter-changing transformations merely to obtain a preferred master count.

2. Close the identities under differentiation before solving boundaries

This step can remove more redundancy than direct duplicate detection alone.

Suppose the original spanning vector satisfies

∂
t
	​

I=A
t
	​

I,t=x,z.

After direct identifications, write

I=EJ,

where E repeats the selected representatives. Choose a row selector S with SE=1, and define

B
t
	​

=SA
t
	​

E.

The necessary compatibility condition is

A
t
	​

E=EB
t
	​

.
	​

(1)

If the residual does not vanish as a matrix, it is not automatically a contradiction. Since the original equations and identifications are exact, it supplies a further relation

(A
t
	​

E−EB
t
	​

)J=0.

Your 56 objects are explicitly a spanning set, so additional rational relations are possible.

More generally, if

R(x,z,ϵ)I=0,

differentiate it:

(∂
t
	​

R+RA
t
	​

)I=0.
	​

(2)

Add independent rows and repeat until the rational relation space is stable under both derivatives. Its rank can increase only finitely many times.

After choosing independent representatives with

I=T(x,z,ϵ)J,

the reduced connection must satisfy

A
t
	​

T−∂
t
	​

T=TB
t
	​

.
	​

(3)

For pure factor-one identifications, T=E is constant and the derivative term vanishes. It generally reappears after the additional relations from (2).

This is a useful, bounded operation before boundary integration: it uses your exact equations and exact routing identities, not conjectured numerical equalities or boundary values. Work over the generic rational field in x,z,ϵ; specializing ϵ=0 can change rank.

Then verify

∂
x
	​

B
z
	​

−∂
z
	​

B
x
	​

+B
z
	​

B
x
	​

−B
x
	​

B
z
	​

=0

on the resulting independent system. Preserve the complete substitution

I
original
	​

=TJ

for every original amplitude and derivative target.

Recompute the inexpensive triangular preparation on this shared system. Do not retain separate integration constants for pre-merge blocks. Conversely, rational triangularization at ϵ=0 does not itself determine the number of physical boundary constants.

3. Preferred boundary: the ordered double-threshold corner

Use

ρ=1−x,σ=1−z,J=
x
Q
2
	​

,S=Jρ.

From your chart,

V
3
	​

(z)=N(ϵ)S
1−2ϵ
z
−ϵ
σ
1−2ϵ
,

where

N(ϵ)=
128π
3
(4π)
2ϵ
	​

Γ(2−2ϵ)
2
Γ(1−ϵ)
2
	​

.

Thus its leading double-corner normalization follows directly:

V
3
	​

∼N(ϵ)(Q
2
)
1−2ϵ
ρ
1−2ϵ
σ
1−2ϵ
.

The same double-threshold corner is useful in independent SIDIS master calculations, but those calculations also encounter a non-Gamma hypergeometric boundary constant. That supports choosing the corner, not importing their constant count, vanishing modes, or values. 
arXiv

3.1 A useful provable simplification of the x→1 limit

For a future-causal final-state subset K, define

α
K
	​

=
J
2p⋅K
	​

,f
K
	​

=
S
K
2
	​

.

On the physical phase space,

0≤f
K
	​

≤α
K
	​

≤1.
	​

(4)

To see the nontrivial inequality, work in the P rest frame with M=
S
	​

, K=(E,K), R=∣K∣, and angle θ to p. Then

α
K
	​

=
M
E−Rcosθ
	​

,

and future causality of K,P−K gives E+R≤M. Hence

α
K
	​

f
K
	​

	​

=
M(E−Rcosθ)
E
2
−R
2
	​

≤
M
E+R
	​

≤1.

Therefore

(p−K)
2
=−Jα
K
	​

(1−ρ
α
K
	​

f
K
	​

	​

).
	​

(5)

For ρ in a sufficiently small fixed neighborhood of zero,

(1−ρ
α
K
	​

f
K
	​

	​

)
−ν

has a uniformly convergent Taylor expansion because 0≤f
K
	​

/α
K
	​

≤1. Points with α
K
	​

=0 are understood by the corresponding bounded limiting ratio.

Pure final-subset denominators are simply

K
2
=Sf
K
	​

.

Reference denominators such as P⋅k
i
	​

 also carry an explicit overall factor S.

For unit-particle-cut integrals built from these recognized factors, the ρ-dependence can therefore be factored and expanded without generating a new angular boundary layer from (5), provided the remaining angular weight is dominated in the chosen analytic-regulator domain.

This gives a particularly useful automatic rule:

Recognize the subset-denominator form, factor its exact powers of S,J, and expand the uniformly bounded 1−ρf
K
	​

/α
K
	​

 factors.

It can establish allowed x-asymptotic powers and eliminate incompatible Frobenius modes from first principles.

This argument does not remove an i0, establish a convergence bound for arbitrary denominator powers, or authorize mass derivatives of the massless chart. It is a controlled expansion of the displayed ratio, conditional on the corresponding regulated integral. Unrecognized auxiliary denominators require separate analysis.

3.2 Then close the boundary functions at z→1

Take the ρ-Frobenius expansion at generic z, retaining its coefficient functions of z. Derive their induced z-system from the shared DE, then fix those functions at σ→0.

This ordered construction avoids assuming that the two limits commute. It also avoids arbitrarily selecting a ray σ=cρ, which can hide independent corner modes.

The main angular kernel remaining at z=1 is

F(t,y,a)=t+y−2ty−2
t(1−t)y(1−y)
	​

(1−2a).
	​

(6)

At that limit,

S
s
12
	​

	​

→F,
S
s
13
	​

	​

→1−F,
Sσ
s
23
	​

	​

=t.

The measured fractions give

2p⋅k
2
	​

=Jσy,2p⋅k
3
	​

=Jσ(1−y).

The external variables have disappeared from many leading angular kernels. This is why the corner is promising. But F is a correlated angular denominator, not a monomial in t,y,a.

4. What can be integrated automatically—and where regions are needed
4.1 Exact Gamma/Beta seeds available immediately

Let

α=1−ϵ,β=
2
1
	​

−ϵ,

and let ⟨⋅⟩
β
	​

 denote the three normalized beta averages in your chart.

For monomials,

	​

⟨t
u
t
	​

(1−t)
v
t
	​

y
u
y
	​

(1−y)
v
y
	​

a
u
a
	​

(1−a)
v
a
	​

⟩
β
	​

=
B(α,α)
B(α+u
t
	​

,α+v
t
	​

)
	​

B(α,α)
B(α+u
y
	​

,α+v
y
	​

)
	​

B(β,β)
B(β+u
a
	​

,β+v
a
	​

)
	​

.
	​

(7)

Initially require convergence of the Euler integrals, then continue meromorphically. 
DLMF

For example, your chart directly derives the unit-particle-cut family

V
r,m,n
	​

=∫[dΦ
3
	​

]
z
	​

s
23
r
	​

(2p⋅k
2
	​

)
m
(2p⋅k
3
	​

)
n
1
	​


as

V
r,m,n
	​

=V
3
	​

(z)S
−r
J
−m−n
σ
−r−m−n
B(α,α)
B(α−r,α)
	​

B(α,α)
B(α−m,α−n)
	​

.
	​

(8)

This is a reusable Euler integration rule derived from your measure. The volume is its r=m=n=0 case. Apply separately any signs or phases required when an actual ordinary denominator is the negative of one used in (8).

There is a second useful generic angular simplification. In the normalized measure, t and y are polar variables of two independent directions, and F is their relative-angle fraction. Rotational invariance gives

⟨F
−u
(1−F)
−v
⟩
β
	​

=
B(α,α)
B(α−u,α−v)
	​

.
	​

(9)

More generally, if there is no additional y,a dependence, the conditional average of a function of F is independent of t. This can factor a remaining monomial t-integral.

Use this only when its invariance conditions hold. Independent weights in both t and y generally preserve nontrivial correlations.

4.2 Do not force all remaining constants into Gamma functions

An angular integral can produce a 
2
	​

F
1
	​

, followed by an Euler integration that produces a 
3
	​

F
2
	​

(1). For example,

∫
0
1
	​

duu
A−1
(1−u)
B−1
2
	​

F
1
	​

(a,b;c;u)=B(A,B)
3
	​

F
2
	​

(a,b,A;c,A+B;1)

in a convergence domain, with subsequent analytic continuation. This is a standard Euler transformation of generalized hypergeometric functions. 
DLMF

That is an acceptable exact boundary result. It should be derived from the generated kernel and expanded to the required epsilon depth—not replaced by a remembered constant or declared zero because the current Beta integrator cannot finish it.

The efficient fallback order is: simplify angular invariances, perform one exact Euler/angular integral, then call the existing more general integrator on the reduced kernel.

4.3 A concrete nonuniform z-region in the supplied chart

Consider a denominator P⋅k
2
	​

, when present in an active family. Exactly,

S
2P⋅k
2
	​

	​

=
S
s
12
	​

	​

+σt.

Near z=1, a=0, and t=y, with y bounded away from 0 and 1,

F(t,y,a)=
4y(1−y)
(t−y)
2
	​

+4ay(1−y)+⋯.

Consequently,

S
2P⋅k
2
	​

	​

∼
4y(1−y)
(t−y)
2
	​

+4ay(1−y)+σy.
(10)

There is a boundary layer

t−y∼
σ
	​

,a∼σ.
	​

(11)

For a factor (P⋅k
2
	​

)
−h
, its local angular contribution scales as

σ
1−ϵ−h
,

before the overall measured-volume power and other factors are included. Here

dtdaa
−1/2−ϵ
∼σ
1−ϵ
.

Simply substituting z=1 misses this region. Even if it is subleading in a convergence domain, its coefficient may be needed to match a subleading Frobenius mode.

This example also shows why a generic boundary routine must inspect the actual active denominator set, including reference denominators, rather than import a “single-region” conclusion from a simpler basis. Expansion-by-regions methods for angular integrals explicitly address such small-parameter angular limits. 
arXiv

For automation, detect the correlated zero loci before relying on Newton-polytope analysis of an expanded signed polynomial. The positive-square form in (10) is more informative than a cancellation-prone expanded expression. Resolve the locus with suitable local coordinates, track overlaps, and retain any auxiliary analytic regulators until region sums are combined. Region completeness and overlap treatment are genuine conditions of the method. 
arXiv

5. Dotted cuts: prefer avoiding their boundary integration, not ignoring them

The best boundary basis is not necessarily the original master basis. First seek a set of unit-particle-cut seed integrals or linear combinations whose asymptotic data have full rank on the remaining homogeneous constants. Ordinary dots and numerator insertions are harmless for use of the chart.

You do not need to transform every master into that seed basis if selected seed asymptotics already determine all constants.

Measurement dots can often be obtained by differentiation

With G
m
	​

=J(f−z), J independent of z, and no other explicit z-dependence in the integration weight,

I
n
	​

(z)=
(n−1)!
J
1−n
	​

∂
z
n−1
	​

I
1
	​

(z).
	​

(12)

There is no additional sign in this equation; the alternating sign appears when the derivative acts on a test function. 
DLMF

If the remaining integrand depends explicitly on z, use the differentiated-integrand rule instead. In particular,

∂
z
	​

I
ν
	​

[W]=νJI
ν+1
	​

[W]+I
ν
	​

[∂
z
	​

W].

Do not use (12) after a family normalization has introduced unaccounted explicit z-dependence.

For endpoint asymptotics, derivatives can lower powers and generate supported terms. Keep the regulated asymptotic expansion deep enough before differentiating.

Particle dots require an actual normal extension

Let μ
i
	​

 be independent cut mass-squared parameters. With all other defining polynomials held as declared,

I
ν
1
	​

,ν
2
	​

,ν
3
	​

	​

=
i=1
∏
3
	​

(ν
i
	​

−1)!
1
	​

∂
μ
i
	​

ν
i
	​

−1
	​

I
1,1,1
	​

(μ)
	​

μ=0
	​

	​

(13)

means a distributional normal derivative, or an ordinary derivative first established in a common convergence domain and then continued.

The massless chart does not supply the right-hand side. In a massive recursive construction, the phase-space boundaries, Källén factors, angular transformations, and measurement solution all depend on the masses. They must all be differentiated.

The corner introduces additional scales such as S and Sσ. A mass-deformed region must retain the corresponding mass ratios until the required normal derivatives have been taken or their commutation with the limit proved. Taking a massive integral’s naive μ→0 limit after differentiation can fail.

Therefore build only the finite mass-jet depth actually needed for a boundary rank deficit. Do not make a general all-mass/all-dot integration engine the next prerequisite.

6. Physical mode matching and the next implementation order

After equivalence and differential closure, construct the ordered corner expansion of the shared system. At the first boundary it has the schematic form

J(ρ,z,ϵ)=
λ,r
∑
	​

ρ
λ(ϵ)
(logρ)
r
F
λr
	​

(ρ,z,ϵ).

The leading coefficient functions satisfy an induced system in z. Their σ-expansion then produces the corner constants.

Use your exact gauges and raw-master map when converting physical asymptotics into these modes. A singular basis transformation can make a subleading raw term necessary for a leading normalized mode.

Choose physical boundary functionals B
α
	​

 and assemble

B
α
	​

[J]=
b
∑
	​

L
αb
	​

(ϵ)c
b
	​

(ϵ).
	​

(14)

Evaluate the cheapest independent rows first: volume, monomial Beta seeds such as (8), rotational reductions such as (9), then nontrivial angular or region integrals.

Stop only when the matching matrix has the required rank. A mode may be set to zero because a proved physical asymptotic excludes it—not because its exponent looks unfamiliar or because another basis used fewer constants. If rank remains deficient, compute additional asymptotic orders or another independently integrable boundary functional.

The recommended sequence is:

Step	Deliverable
1. Exact routing quotient	Factor-one classes with witnesses, inactive ordinary slots ignored, and every original target mapped
2. Differential closure	Stable exact relations, shared x,z connection, updated epsilon-order requirements
3. Boundary rank analysis	Ordered corner modes and a minimal set of physical data needed to fix them
4. Unit-cut Euler integration	Generated Gamma/Beta seeds and angular reductions from the existing chart
5. Resolve only the remaining difficulties	Nonuniform angular regions, generalized Euler integrals, and necessary finite particle-mass jets

Two particularly inexpensive checks are worth attaching to this sequence. First, for every accepted routing, compare both x- and z-derivatives after the shared substitution; a mismatch can reveal either a normalization error or an additional exact relation. Second, compare exact chart moments and leading region coefficients against direct integration at convergent regulator values, while retaining the analytic derivation as the proof.

The main gain is to reduce the number of independent boundary data before integrating anything difficult. The exact-routing quotient is justified now. The double-threshold corner is the strongest boundary candidate, with a controlled first x-limit for the recognized unit-cut class. What remains to be established from your generated denominator set is the complete z-region content and the rank of the resulting physical matching—not a presumed Gamma-only answer or a prescribed number of masters.