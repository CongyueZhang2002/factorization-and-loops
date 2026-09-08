# Cut integral pole bounds

Model: gpt-6-pro. Date: 2026-09-05 (America/Los_Angeles).
Conversation: 6a9c64ec-3cc4-83e8-b40c-9b568241fd3b.

## Question

We need a practical, sound automatic Laurent-pole bound for physical cut master integrals at a fixed ordinary rational kinematic point. Please critically assess the methods below and propose a concrete implementable algorithm, not a list of missing inputs.
Repository: https://github.com/CongyueZhang2002/factorization-and-loops . Current edits are LOCAL, not on GitHub; the facts below are the implementation specification. Our user wants a general NNLO framework, no hand-coded selected-family bounds; checks should not dominate computation, and AMFlow will check master values later.

Existing code: automatic exact normalized momentum definitions from GLI/FCTopology and physical cut data; ordinary-loop Feynman parameterization + bounded sector decomposition gives pole bounds. For pure phase space, it derives the exact real Baikov representation: external Gram G of E independent external vectors, transverse positive-semidefinite T=V G^-1 V^T-W, polynomial P=det T, density P^((D-E-L-1)/2), full energy inequalities, and
measureFactor * |det A|^-1 |det G|^-L/2 pi^(L(D-E)/2-L(L-1)/4) / product_j Gamma((D-E-j+1)/2).
A is the linear scalar-product to denominator coordinate map. AMFlow normalization: virtual dl/(i*pi^(D/2)), conjugate sign, physical phase-space (2*pi) factors.
Cut power a means (-1)^(a-1)/(a-1)! delta^(a-1)(z) with theta of oriented positive energy. We retain these as distributions on the whole domain; cannot naively differentiate only P and omit domain derivatives. Fully localized interior cuts and inclusive massless n-body phase volumes are already solved automatically.

Representative, NOT intended process-specific code: massless double real 2->4 with fixed observed p3. p1^2=p2^2=p3^2=0, 2p1.p2=1, 2p1.p3=v, 2p2.p3=w, v,w>0,v+w<1. Ptotal=p1+p2-p3 future timelike, two phase loops k1,k2 and three cuts k1^2, k2^2, (Ptotal-k1-k2)^2. External E=3,L=2, hence Baikov exponent -1-eps and one inverse Gamma(-eps) normalization zero. Full families have nine scalar-product denominators, including ordinary tree channels and numerator slots; 23 masters in one representative include repeated cuts. General direct semialgebraic domain resolution is not implemented.

Alternative to challenge: derive a rational dimensional recurrence I(D+2)=R(D) I(D) using Baikov P insertions and cut-aware IBP. At a fixed rational kinematic point this is only rational reconstruction in D. For compact pure-real phase space, sufficiently large D should suppress soft/collinear boundary divergences, even for fixed finite dotted-cut orders if handled in an initial convergence half-plane. Then I(4-2eps)=R(4-2eps)^-1 ... R(4+2k-2-2eps)^-1 I(4+2k-2eps), so entrywise valuations of the finite rational matrix product give a rigorous pole bound without computing any master value or global DE. Choosing unnecessarily large k need not keep widening the pole bound if later matrices are regular at those integer dimensions.
Questions:
1) Can this be made sound for the compact physical phase-space cuts, including distribution derivatives? How exactly prove a sufficient convergence dimension from topology/denominator data rather than hand-written power counting? Is there a computationally useful universal bound in terms of denominator powers, cut derivative orders, external rank, etc., under a checkable no-interior-singularity condition?
2) Tree inverse propagators vanish only on physical soft/collinear boundary strata. Is a polynomial inequality P <= C |D_j|^a or a real-algebraic nullstellensatz / Lojasiewicz certificate a practical way to guarantee high-D convergence? Give an efficient sufficient certificate, including numerator/delta-derivative and boundary-domain treatment.
3) Could avoid IBP by Bernstein-Sato functional equations in P with all other denominators held as rational weights? Which is realistic for L=2 E=3 versus general NNLO?
4) Contrast direct recursive phase-space parametrization + resolution against finite-basis/dimensional-recurrence pole bounds. If the proposed recurrence method fails, give the actual counterexample and the simplest reliable alternative. Do not invoke the blanket 1/eps^(2L) as a proven bound for arbitrary dotted cut masters.
5) How tight can the recurrence bounds be made cheaply (entrywise exact rational cancellation vs min-plus), and which pieces can be shared per family?
We have Kira and FeynCalc available and existing topology-driven Tarasov/IBP code. Please focus on a strategy we can implement now. State exactly which convergence/analytic-continuation hypotheses are needed; no claim that missing physical input can be inferred from a DE.


A potentially MUCH cheaper alternative occurred while inspecting this: use resolution-of-singularities only as a theorem to bound pole multiplicity, without computing sectors. Once cuts are eliminated in a convergence half-plane (and all dotted-cut normal derivatives taken there, justified because P^alpha vanishes to sufficient order at Gram/energy boundaries), each term is an n-dimensional compact semialgebraic integral of P^(alpha0-eps-m) times a rational function with fixed integer denominator powers. Here n=N_scalarproducts-n_cut (six for L=2 E=3). If every uncut-denominator zero on the closed physical domain belongs to P=0, semialgebraic Lojasiewicz gives a sufficiently high initial Re(alpha) for convergence. A proper normal-crossing resolution then gives at most n simple factors 1/(a+b eps) per sector, with b!=0 on every potentially singular divisor. Therefore the epsilon pole order is at most n, plus valuations of prefactors (including inverse Gamma zeros and polynomial alpha factors from cut derivatives). This would give e.g. lower bound -5, rather than an assumed -4, for full E=3 L=2 double-real integrals. It is conservative but sound, and could shrink for lower effective external rank, automatically integrated unused angles, and polynomial cancellation factors.
Is this theorem-based bound sound? Does a repeated cut ever increase the pole multiplicity beyond n remaining dimensions, after retaining the full-domain analytic continuation? Does zero-containment P=0 plus compactness suffice, or do we need stronger conditions at critical restrictions to the cut surface? If it works, what is the fastest exact certificate for zero-containment in our Lorentz-cone phase-space setting? Could use geometric Cauchy-Schwarz inequalities for tree channels, or bounded real-algebraic QE on D_j=0 and T positive definite. We need a sound usable bound now, not exact pole order at any cost. Please compare this route to IBP dimensional recurrence; the latter might be much more computation than is justified merely to avoid one extra epsilon order.


## Pro response

Your theorem-based proposal is sound once the cut-eliminated representation is justified, and I recommend it as the default pole-bound method. It avoids computing sectors, a convergence dimension, or a dimensional-recurrence matrix. For dotted cuts, however, containment of denominator zeros on the on-shell slice is not by itself a justification for differentiating the phase-space domain. That step needs an additional, checkable argument.

A practical choice is to certify a compact positive-mass deformation of the cuts. For massless tree channels, the same Lorentz-cone arguments that establish on-shell zero containment usually establish this stronger property. Under the conditions below, every fixed finite dotted-cut order obeys

ν
ϵ
	​

(I)≥ν
ϵ
	​

(N)−n,
	​


where N is the exact normalization, including any explicit meromorphic factors, and n is the number of remaining scalar-product integration variables.

For your E=3,L=2, three-cut representation, this gives ν
ϵ
	​

(I)≥−5 when the normalization has the stated single inverse-Gamma zero and no additional pole. This is a theorem-derived conservative bound, not an assumed NNLO pole count.

Repository access succeeds. The analysis below uses your local implementation specification rather than attributing the new functionality to the pushed code.

1. The dimension-counting theorem

Consider first an already justified representation

I(ϵ)=N(ϵ)
ρ
∑
	​

c
ρ
	​

(ϵ)∫
K
	​

P(x)
α
0
	​

−ϵ−m
ρ
	​

∏
j
	​

D
j
	​

(x)
b
ρj
	​

H
ρ
	​

(x)
	​

d
n
x,

where:

K is compact and semialgebraic, with a nonempty n-dimensional interior;

P>0 in that interior;

the H
ρ
	​

 are polynomial, or their additional denominators have been included among the D
j
	​

;

every denominator zero on K lies in P=0;

the c
ρ
	​

 are holomorphic in ϵ, or their valuations are explicitly included.

The physical prescription is defined by continuation from a half-plane where the integrals converge absolutely. In that half-plane, a tree denominator of fixed sign presents no ambiguity at its endpoint zero.

Why a convergence half-plane exists

Compact semialgebraic Łojasiewicz inequalities imply

D
j
−1
	​

(0)∩K⊆P
−1
(0)⟹P
h
j
	​

≤C
j
	​

∣D
j
	​

∣on K

for some positive integer h
j
	​

 and finite C
j
	​

. Thus

j
∏
	​

∣D
j
	​

∣
−b
ρj
	​

≤CP
−∑
j
	​

h
j
	​

b
ρj
	​

,

and sufficiently large Reα makes the integrand bounded, hence integrable. For the pole-multiplicity bound, the existence of these exponents suffices; they need not be computed. Effective versions of this inequality also exist, although their general degree bounds are much too large to be attractive convergence-dimension estimates. 
arXiv

Why the pole order is at most n

Resolve the polynomials and the semialgebraic boundary simultaneously. In each relevant chart, the integrand takes the form

u(y,ϵ)
ℓ=1
∏
n
	​

y
ℓ
A
ℓ
	​

−B
ℓ
	​

ϵ
	​

d
n
y,

with u smooth at the boundary and holomorphic in ϵ.

A potentially divergent divisor must have B
ℓ
	​


=0. Indeed, a divisor on which P has order zero but a denominator vanishes would contradict zero containment. Divisors introduced only by the integration domain, with no singular weight, are integrable.

Taylor subtraction in y
ℓ
	​

 produces factors

A
ℓ
	​

+k+1−B
ℓ
	​

ϵ
1
	​

.

Each is at most a simple pole. At most n such factors occur simultaneously in a chart. Summing charts does not add their pole orders.

This is the application of the resolution argument for meromorphic powers of analytic functions to your weighted integral. 
onlinelibrary.wiley.com

Consequently,

ν
ϵ
	​

(I)≥ν
ϵ
	​

(N)+
ρ
min
	​

ν
ϵ
	​

(c
ρ
	​

)−n.

Two useful consequences follow.

Arbitrarily high fixed integer propagator powers do not increase this multiplicity bound. They change the Taylor-subtraction depths and the locations of poles, but not the number of simultaneously singular integration variables.

Do not expand in ϵ before applying this argument. The unexpanded density has no added logarithmic powers from the Laurent expansion. Counting logarithms after expansion is a different calculation and obscures the simple multiplicity bound.

2. Dotted cuts: the extra justification and a practical certificate

Let z=(z
1
	​

,…,z
c
	​

) denote independent cut coordinates, x the remaining coordinates, and

r
a
	​

=a
a
	​

−1,r=
a
∑
	​

r
a
	​

.

Your cut convention gives, when the distributional pairing is legitimate,

∫
a
∏
	​

r
a
	​

!
(−1)
r
a
	​

	​

δ
(r
a
	​

)
(z
a
	​

)F(z,x)d
c
z=
∏
a
	​

r
a
	​

!
1
	​

∂
z
r
	​

F(z,x)∣
z=0
	​

.

Higher propagator powers representing derivatives of cut delta functions are standard in reverse unitarity; what still needs justification here is the full-domain differentiation, not that algebraic correspondence. 
arXiv

If all boundary contributions vanish in an initial convergence half-plane, the remaining derivatives have the structure

∂
z
r
	​

P
α
=
m=0
∑
r
	​

(α)
m
	​

	​

P
α−m
H
r,m
	​

(z,x),

with polynomial H
r,m
	​

.

The falling factorials are polynomials in α. There are no new ϵ-denominators. Derivatives of rational weights only raise their fixed integer powers. Therefore the resulting n-dimensional integrals still have pole multiplicity at most n.

The key is establishing the premise without ignoring the domain derivatives.

A sufficient certificate: positive-mass deformation

Replace each cut equation by

q
a
2
	​

=m
a
2
	​

+μ
a
	​

,μ
a
	​

≥0,

keeping its future-energy orientation. Dotted cuts can then be obtained as finite derivatives at μ=0
+
, initially where these derivatives converge.

Certify the following for a compact mass-deformed domain, either for sufficiently small μ or for the whole physically allowed nonnegative mass range:

The oriented cut momenta are future causal and sum to a fixed future-timelike momentum.

Their loop-momentum coefficient matrix has rank L.

The cut coordinates are independent scalar-product coordinates.

Every uncancelled ordinary-denominator zero on this mass-deformed domain belongs to P=0.

The only moving physical boundaries are the Gram and energy boundaries, or any additional moving boundary has been separately included.

The first two conditions establish compactness automatically: in the total rest frame, all cut energies and spatial momenta are bounded, and the independent loop momenta are affine combinations of these bounded momenta.

For ordinary on-shell positive-energy cuts, an energy boundary q
a
0
	​

=0 implies q
a
	​

=0, or is impossible for positive mass. A nonzero loop combination then has zero transverse norm, so T is singular and P=0.

The scalar-product map is a submersion where G is nonsingular and T is positive definite. Independent cut coordinates therefore exclude an interior critical cut restriction there. Possible critical behavior at soft or Gram-degenerate configurations is confined to P=0.

Uniform Łojasiewicz bounds on the compact mass-deformed domain then give a sufficiently large Reα for every required finite derivative. The differentiated densities vanish to sufficient order at the moving boundaries. In this half-plane, the domain contributions really vanish; meromorphic continuation preserves that identity.

This certifies omitting the boundary terms after proving that they vanish. It is not a rule to omit them by definition.

What slice-only containment does not establish

For example,

P(z,x)=x
2
+z,D(x)=x,−1≤x≤1.

At z=0, the denominator zero lies in P=0, and

∫
−1
1
	​

x
2
∣x∣
2s
	​

dx

converges for sufficiently large Res. But for every z>0,

∫
−1
1
	​

x
2
(x
2
+z)
s
	​

dx

has an interior nonintegrable singularity, regardless of s.

This does not prove that a suitably distributionally defined cut derivative violates the n-pole bound. It proves that on-shell zero containment alone does not justify the positive-mass differentiation argument.

Likewise, a critical constraint such as δ(t
2
) at t=0, with no vanishing regulator weight there, is not made well-defined by counting “one variable minus one cut.”

The mass-deformation certificate is sufficient, not necessary. Failing it must not be reported as proof that the integral has no meromorphic continuation.

3. Fast zero-containment certificates for the physical families

I would use Lorentz-cone identities first, and exact real-algebraic feasibility only for denominators not recognized by those identities.

Final-state channel sums

For future-causal outgoing momenta,

K
A
	​

=
a∈A
∑
	​

q
a
	​

,

one has

K
A
2
	​

=
a∈A
∑
	​

q
a
2
	​

+2
a<b
∑
	​

q
a
	​

⋅q
b
	​

≥0.

If K
A
2
	​

=0, all nonzero summands are massless and collinear.

The program then checks that this collinearity implies a nontrivial linear dependence among the loop transverse vectors. When it does,

K
A
2
	​

=0⟹detT=0.

This last rank check matters. A fixed external channel should instead be evaluated directly, and a denominator duplicating a cut coordinate must be handled according to the cut algebra rather than treated as an independent ordinary pole.

Channels separating two massless incoming beams

Let

p
1
	​

+p
2
	​

=K
A
	​

+K
B
	​

,q=p
1
	​

−K
A
	​

=K
B
	​

−p
2
	​

,

where K
A
	​

,K
B
	​

 are sums of future-causal outgoing momenta and p
1
	​

,p
2
	​

 are future null.

Then q cannot be future timelike, since p
1
	​

=K
A
	​

+q would be timelike. It cannot be past timelike, since p
2
	​

=K
B
	​

−q would be timelike. Hence q
2
≤0.

If q
2
=0, one of the two decompositions forces a final-state cluster to be collinear with its incoming beam. Again, an exact loop-coefficient rank check turns this into P=0.

These are generic channel identities, not selected-family bounds. They remain valid when cut masses are deformed nonnegatively; positive masses simply exclude some equality cases.

They do not establish the same statement for arbitrary massive internal propagators. A massive resonance can go on shell in the physical interior.

Exact feasibility for the remaining denominators

After imposing the cut equations, test whether

∃x:x∈K,T(x)≻0,D
j
	​

(x)=0.

If the answer is false, zero containment is proved.

For L=2, positive definiteness needs only

T
11
	​

>0,detT>0.

The full energy inequalities remain in the query.

Because an ordinary denominator is linear in scalar-product coordinates, eliminate D
j
	​

=0 by exact linear substitution before calling real quantifier elimination. This reduces the dimension and avoids building a complete decomposition of the physical domain. Test denominators separately rather than replacing them by a large product.

For dotted cuts, use the mass-deformed feasible set unless the Lorentz-cone argument already establishes the stronger property.

These certificates are shared by every master using that denominator, irrespective of its positive power. There is no reason to repeat the geometric work for all dotted variants.

Quantitative inequalities are optional

When useful, the geometric proofs can provide inequalities such as

P
h
j
	​

≤C
j
	​

∣D
j
	​

∣.

For example, a beam-collinear channel can be bounded through a transverse norm and a Gram determinant inequality. For a two-beam partition, light-cone variables give

−q
2
=sβ(1−α)+∣K
A⊥
	​

∣
2
,

which can yield a product bound and, in suitable layouts, an inequality of the form P
2
≤C(−q
2
).

For the default multiplicity bound, however, do not calculate the optimal h
j
	​

, C
j
	​

, or a Positivstellensatz representation. Proving zero containment is enough. General effective Łojasiewicz bounds depend on polynomial degrees and dimension and can be enormous; using them to choose a long dimensional-recurrence chain defeats the economy of the theorem route. 
arXiv

4. The bound for your representative and the algorithm to implement

For generic-dimensional scalar products,

N
sp
	​

=LE+
2
L(L+1)
	​

,n=N
sp
	​

−c.

Here,

N
sp
	​

=9,c=3,n=6.

At D=4−2ϵ,

α=
2
D−E−L−1
	​

=−1−ϵ,

and the Gamma part of the stated normalization is

Γ(
2
1
	​

−ϵ)Γ(−ϵ)
1
	​

.

Its valuation is +1. Consequently,

ν
ϵ
	​

(I)≥1−6=−5.
	​


Finite cut derivatives do not weaken this bound. In this example the falling factorials of α=−1−ϵ do not themselves introduce poles or provide automatic additional zeros.

The powers of π, physical 2π factors, nonzero Gram determinants, constant Jacobians, and conjugation phases are analytic nonzero factors in ϵ. Explicit rational rescalings, Gamma factors, and dimension-shift normalization factors must nevertheless be included exactly.

Do not impose four-dimensional Gram identities before this analysis. The Baikov representation is being defined in a higher-dimensional convergence region and analytically continued; its inverse-Gamma zero accounts for part of the degeneration at four dimensions.

Concrete procedure
For each physical cut family at the fixed kinematic point:

1. Determine the actual scalar-product rank, independent cut coordinates,
   external Gram signature, and exact normalization.

2. Prove compactness from future-causal cut momenta, fixed timelike total
   momentum, and full loop-coefficient rank.

3. For each distinct uncancelled ordinary denominator:
      use a Lorentz-cone channel certificate;
      otherwise eliminate its linear zero equation and run a bounded
      exact real-feasibility test.

4. For dotted cuts:
      establish the corresponding mass-deformed certificate and
      confinement of moving Gram/energy boundaries to P=0.

5. Return, for each master:
      lower_bound = valuation(exact meromorphic prefactors) - n.
   Improve only with already established cancellations or exact
   simpler representations.

No explicit sectors, master values, convergence dimension, or expanded cut derivatives are needed for this first bound. The cut derivative order enters the proof that a convergence half-plane exists, but not the final multiplicity count.

Cheap improvements

Use the exact phase volumes and fully localized cases you already have before assigning the general bound.

Also determine the effective external span of each requested integral, not necessarily the union used by the largest family. If a master depends only on the total momentum and not on the individual beam directions, recomputing its lower-rank Baikov representation can improve the bound.

But recompute the normalization at the same time. Removing variables by exact angular integration can introduce Gamma factors; one cannot simply subtract variables from n while keeping the old prefactor.

Polynomial cancellation should remove spurious denominators before certification. It does not automatically lower the universal n-pole count unless it establishes more—for example, holomorphy at the target dimension or a smaller effective representation.

5. Dimensional recurrence: sound, but a refinement rather than the default

Your recurrence route is valid when the common high-dimensional convergence statement has been established and the cut-aware reduction preserves the chosen normalization and cut prescription. Dimensional recurrence matrices for physical cut integrals are an established computational tool. 
arXiv

Suppose

I(D+2)=R(D)I(D),S(D)=R(D)
−1
,

with a generically invertible basis and known analytic normalization factors extracted where necessary. Then

I(4−2ϵ)=M
k
	​

(ϵ)I(4+2k−2ϵ),
M
k
	​

(ϵ)=S(4−2ϵ)S(6−2ϵ)⋯S(4+2k−2−2ϵ).

If the high-dimensional components have bounds h
j
	​

, then

ν
ϵ
	​

(I
i
	​

)≥
j
min
	​

{ν
ϵ
	​

((M
k
	​

)
ij
	​

)+h
j
	​

}.
	​


For absolutely convergent, holomorphically normalized high-dimensional masters, h
j
	​

=0 is sufficient. Their values need not be calculated.

How to obtain a sufficient convergence dimension

With quantitative certificates

P
h
j
	​

≤C
j
	​

∣D
j
	​

∣,

suppose the required differentiated terms have denominator powers at most u
j
	​

, and at most r powers of P have been lost through normal differentiation. Then

Reα>r+
j
∑
	​

h
j
	​

u
j
	​


is a simple sufficient condition making the densities vanish at the relevant boundaries.

Thus a sufficient dimension is

D
⋆
	​

>E+L+1+2(r+
j
∑
	​

h
j
	​

u
j
	​

).
	​


For a conservative derivative envelope, u
j
	​

=b
j
	​

+r suffices for ordinary rational weights. In your independent denominator coordinates, normal differentiation often leaves the uncut powers unchanged, permitting a sharper envelope.

This is a proof-based convergence dimension, not hand-written soft/collinear power counting. It is usually far from optimal. It also illustrates why the existence-only multiplicity argument is cheaper: that argument does not need the h
j
	​

, u
j
	​

, or D
⋆
	​

 numerically.

Tightness of recurrence bounds

Min-plus propagation,

ν((AB)
ij
	​

)≥
k
min
	​

{ν(A
ik
	​

)+ν(B
kj
	​

)},

is safe and cheap. Exact rational addition can only improve this lower bound by exposing cancellations.

At a fixed rational kinematic point, a useful refinement is to compute only the leading Laurent coefficients of the matrix product needed to decide whether a suspected lowest order cancels. A full symbolic product in D is not always necessary.

Your observation about unnecessarily large k is correct with one clarification: it is the inverse matrices S(D) that must be ϵ-regular at the additional integer dimensions. Regularity of R(D) does not imply regularity of its inverse. Once the appended inverse factors are regular, the row-wise conservative lower bound cannot worsen.

The generic recurrence, its scalar denominator factors, and its block structure can be shared across the family. Nevertheless, constructing a new cut-aware IBP recurrence merely to try to replace −5 by −4 is not the first expenditure I would recommend.

6. Why Bernstein–Sato and direct phase-space resolution are secondary routes
Bernstein–Sato does not keep the rational weight inert

For the generic symmetric 2×2 determinant

P=ac−b
2
,

there is the simple Cayley identity

(∂
a
	​

∂
c
	​

−
4
1
	​

∂
b
2
	​

)P
s+1
=(s+1)(s+
2
3
	​

)P
s
.

Such determinant identities are a special case of Bernstein–Sato functional equations. 
arXiv

This is attractive before imposing cuts. But after integration by parts the derivatives act on the rational weight, cut distributions, and domain data. They generate changed propagator powers and cut powers. After eliminating the cuts, the restricted polynomial is also no longer a determinant in independent a,b,c coordinates.

Thus the simple determinant identity does not provide a closed scalar recurrence for every weighted physical cut integral while holding the other denominators fixed.

One can formulate the appropriate localized differential-module problem, but that becomes another way to compute integral shift relations, not a free replacement for their reduction. Parametric annihilator methods explicitly connect such differential operators with Feynman-integral relations. 
arXiv

For L=2, retain the Cayley identity as a possible specialized algebraic simplification. I would not make general Bernstein–Sato computation the default pole-bound engine for six-variable weighted cut integrals.

Direct recursive phase-space parametrization is the reliable constructive fallback

The standard recursion

dΦ
n
	​

(Q)=
2π
ds
	​

dΦ
2
	​

(Q;q
n
	​

,K)dΦ
n−1
	​

(K),K
2
=s,

constructs the domain from two-body factors. At double real, this requires only a short recursion, but all angles relevant to the denominators must be retained.

The resulting parameter integrals can be sent to a bounded resolution/sector-decomposition procedure. Sector decomposition has established applications to infrared-divergent real-radiation phase-space integrals. 
arXiv

This is appropriate when a genuinely tighter bound is worth obtaining, or when a geometric certificate fails without identifying a physical obstruction. It should not be mandatory when zero containment already proves the dimension-counting bound.

An actual failure of “large D cures it”

Consider

J(s)=∫
0
1
	​

(x−
2
1
	​

)
2
[x(1−x)]
s
	​

dx.

No large Res makes this absolutely convergent: the numerator is nonzero at the interior pole. A massive internal resonance can produce precisely this type of obstruction in physical phase space.

An i0 distribution may define a different, meaningful integral, but absolute convergence in high dimension is no longer the justification. Raising D does not resolve a pinch or supply a missing physical prescription.

Likewise, for real–virtual or virtual integrals, increasing D can worsen ultraviolet behavior. Published cut-integral recurrence calculations explicitly distinguish infrared suppression from remaining ultraviolet subdivergences. 
arXiv

For those cases, use the appropriate existing virtual parameterization or a causal parameter-integral treatment—not the compact pure-real theorem.

7. Cost control and the recommended decision

The substantial certificate work should be shared by physical cut family and kinematic point: compactness, cut-coordinate rank, Gram structure, denominator zero containment, and admissibility of the mass deformation. A different numerator or higher positive denominator power normally does not require another geometric proof.

For exceptional failures, the next cheapest possibility is often an already available IBP relation to integrals with proved bounds:

I
i
	​

=
j
∑
	​

c
ij
	​

J
j
	​

⟹ν(I
i
	​

)≥
j
min
	​

{ν(c
ij
	​

)+ℓ
j
	​

}.

This can avoid both fresh dimensional recurrence and fresh domain resolution.

A real-feasibility timeout must remain “not certified,” not be interpreted as absence of an interior zero. An actual interior-zero witness should route the integral to the causal/interior-singularity treatment. Neither event invalidates the theorem for the families that pass.

The recommended priority is:

Route	Role
Exact phase volumes, localized cuts, already proved simpler representations	Use immediately when applicable
Compact-domain, zero-containment theorem with the dotted-cut certificate	Default automatic bound
Existing IBP relations or already available dimensional recurrences	Cheap refinement when available
New dimensional recurrence or direct phase-space resolution	Targeted refinement or exception handling
General Bernstein–Sato computation	Not a default pole-bound method

For the stated massless double-real setting, the immediate target should be a family-level geometric certificate followed by the automatic bound ν
ϵ
	​

(I)≥−5, including finite dotted-cut powers. That provides a usable answer without sectors or master evaluation. Tighten it only where the extra Laurent order demonstrably costs enough to justify additional algebra.

AMFlow can later test the physical master values. It is not needed to establish this bound, and its sample values should not be used to infer cancellation of an uncomputed leading pole.