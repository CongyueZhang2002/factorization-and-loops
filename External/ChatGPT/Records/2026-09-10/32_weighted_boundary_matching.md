# GPT-6 Pro: weighted boundary matching

Verified gpt-6-pro; conversation6aa0f5dd-de10-83e8-b032-74f47d77da2a.

Do not yet discard the other radial sectors solely from the ordered slopes (−2ϵ,−2ϵ). The −8ϵ-only result is a well-motivated candidate, and there is a finite exact way to certify it. The required extra step is a comparison of the complete normalized ordered germ with a jointly logarithmic local frame at chart 3’s corner.

Once that comparison establishes that the physical constants have zero projection onto the other radial primary spaces, higher Taylor coefficients cannot regenerate those radial exponent classes. They can, however, populate all 20 master components through the regular part of the fundamental solution. “Only a two-dimensional radial seed sector” does not mean “discard the other 18 rows of the DE.”

A second important point is geometric: chart 3 meets chart 2 at t=1, but chart 2 meets chart 1 at r
2
	​

=1. The latter transfer requires the t
2
	​

-normal boundary system; it cannot be made by substituting r
2
	​

=1 into a finite r
2
	​

-series.

1. What the ordered slopes establish—and what they do not

For a genuine joint monomial

ρ
λ
ρ
	​

σ
λ
σ
	​

,

the chart transformations give:

| Chart | Radial exponent | Ratio exponent | ∣∂(ρ,σ)/∂(r,t)∣ |
|---|---:|---:|---:|
| 1: (r,r
2
t) | λ
ρ
	​

+2λ
σ
	​

 | λ
σ
	​

 | r
2
 |
| 2: (r
2
t,r
2
t
2
) | 2λ
ρ
	​

+2λ
σ
	​

 | λ
ρ
	​

+2λ
σ
	​

 | 2r
3
t
2
 |
| 3: (r
2
t,r
2
) | 2λ
ρ
	​

+2λ
σ
	​

 | λ
ρ
	​

 | 2r
3
 |

Thus the expected exponent pairs are

(−6ϵ,−2ϵ),(−8ϵ,−6ϵ),(−8ϵ,−2ϵ).
	​

(1)

These are the right candidate pairs, not yet a proof that the complete solution has no others.

Counterexample: every ordered coefficient has the expected slope

Consider

f(ρ,σ,ϵ)=ρ
−2ϵ
σ
−2ϵ
(1+
σ
2
ρ
	​

)
−2ϵ
.

At fixed σ>0,

f=
n≥0
∑
	​

(
n
−2ϵ
	​

)ρ
n−2ϵ
σ
−2n−2ϵ
.

Every coefficient has sigma exponent integer minus 2ϵ, and the leading ordered coefficient has exactly the proposed pair.

But chart 3 gives

f(r
2
t,r
2
,ϵ)=r
−4ϵ
t
−2ϵ
(r
2
+t)
−2ϵ
∼r
−4ϵ
t
−4ϵ
	​


as r→0 at fixed t>0.

This is a rank-one flat rational DE. Its separate normal and tangential limits exist, but its chart-3 connection retains the non-coordinate divisor r
2
+t. It is not jointly logarithmic at (0,0). This is exactly the failure your proposed additional check must exclude.

Counterexample: leading raw values can miss a sector even after resolution

Let

f
0
	​

=ρ
−2ϵ
σ
−2ϵ
,g=ρf
0
	​

(ρ
2
+σ)
2ϵ
.

The vectors (f
0
	​

,f
0
	​

+g) have the same leading raw ρ-data as (f
0
	​

,f
0
	​

). Yet

g(r
2
t,r
2
)=r
2−4ϵ
t
1−2ϵ
(1+r
2
t
2
)
2ϵ

contains another radial slope in an otherwise regular chart.

Your full-rank physical construction should distinguish this contribution through its normalized source amplitudes. The example explains why the transfer must use that construction rather than only each raw master’s leading value.

There is no new undetectable solution once the complete regular-singular germ has been fixed. The issue is whether the data used by the transfer are an injective representation of that germ.

2. The sufficient local certificate in chart 3
2.1 Require one compatible logarithmic frame

In a single exact gauge,

I∘π
3
	​

=G
3
	​

(r,t,ϵ)Y,

require

r∂
r
	​

Y=A(r,t,ϵ)Y,t∂
t
	​

Y=B(r,t,ϵ)Y,
	​

(2)

where A,B are analytic in (r,t) near (0,0), meromorphic in ϵ, and all integer powers in G
3
	​

,G
3
−1
	​

 are recorded.

This means checking that every remaining denominator through the origin is a power of r or t, with the rest an analytic nonvanishing unit. Separate Fuchsian gauges are not enough if applying one creates poles in the other component. Compatible normalization is a central issue for multivariable Pfaffian systems. 
arXiv

Set

R=A(0,0,ϵ),S=B(0,0,ϵ).

Flatness gives

[R,S]=0.
	​

(3)

After integer normalization, suppose the usual positive-integer resonance obstructions have been removed, or retained explicitly in your existing Levelt construction. In the uncomplicated normalized case,

Y=H(r,t,ϵ)r
R
t
S
c
3
	​

(ϵ),H(0,0,ϵ)=I,
	​

(4)

with H analytic. Repeated eigenvalues and commuting nilpotent parts are allowed; diagonalizability is unnecessary.

For completeness, the analytic-gauge recurrences are

(iI−ad
R
	​

)H
ij
	​

(jI−ad
S
	​

)H
ij
	​

	​

=
a≤i, b≤j
a+b>0
	​

∑
	​

A
ab
	​

H
i−a,j−b
	​

,
=
a≤i, b≤j
a+b>0
	​

∑
	​

B
ab
	​

H
i−a,j−b
	​

.
	​

	​

(5)

Use either nonsingular equation to compute a coefficient and the other as an exact compatibility check. For i=0,j>0, use the second; for j=0,i>0, use the first.

With analytic coefficients and normalized nonresonant integer differences, the inverse operators have the large-order bounds needed for a convergent majorant. This is stronger than merely checking a formal truncation. Resonant logarithms must be retained rather than deleted when a recurrence becomes singular. 
DLMF

For your −4ϵ Jordan block,

r
−4ϵI+N
=r
−4ϵ
(I+Nlogr)

when N
2
=0. Preserve the complete generalized eigenspace and the exact epsilon dependence of N.

2.2 A finite matching problem determines the physical sector

Construct the chart-3 fundamental columns from (4), retaining all 20 candidate constants initially. Pull the known ordered physical germ into the same frame:

G
3
−1
	​

(r,t,ϵ)I
ord
	​

(r
2
t,r
2
,ϵ).

Choose coefficient functionals that extract specified

r
λ+i
t
μ+j
(logr)
a
(logt)
b

terms. Applying them to both expressions gives a finite system

J
3
	​

(ϵ)c
3
	​

(ϵ)=B
3
	​

(ϵ)c
ord
	​

(ϵ).
	​

(6)

The source vector contains your two already fixed Gamma/
3
	​

F
2
	​

 constants and the exact source constraints. There are no new physical parameters.

Increase the selected jet rows until they determine the required chart amplitudes. A full-column-rank J
3
	​

 is the simplest stopping certificate.

A cheaper targeted version suffices to exclude unwanted sectors. Let P
bad
	​

 be the sum of the radial primary projectors for

0, −2ϵ, −4ϵ.

For a solution c
∗
	​

 of (6) and a basis N
J
	​

 of its nullspace, it is enough to verify

P
bad
	​

c
∗
	​

=0,P
bad
	​

N
J
	​

=0.
	​

(7)

Then every completion compatible with the extracted physical germ has zero unwanted radial amplitudes. Determine the remaining two amplitudes with the next independent rows.

Use primary projectors, not just eigenvectors. Construct them from the minimal polynomial, including the squared factor for the Jordan block. Work at generic epsilon: setting ϵ=0 merges all the listed eigenvalues and destroys this test.

If the unwanted projections vanish with the two original constants treated symbolically, the result holds for the whole selected two-parameter source space. If cancellation uses their physical values, substitute those values exactly. Numerical negative-epsilon checks do not establish an all-epsilon sector exclusion.

2.3 Why finite source jets suffice here

A source term transforms as

ρ
a+n+λ
σ
b+m+μ
⟼r
2(a+n+b+m)+2λ+2μ
t
a+n+λ
.
(8)

A gauge coefficient r
i
t
j
 shifts the two integer degrees by i,j.

Therefore, for any fixed target t-jet order, only finitely many source ρ-orders contribute. For those finitely many coefficients, only finitely many sigma jets are needed to obtain the selected radial orders.

This is the correct way to use rectangular jets:

Bound the source ρ-order from the requested chart ratio order, including negative powers of the gauge.

For each retained ρ-coefficient, bound its sigma order from the requested radial order.

Preserve regulator exponents and logarithms as labels throughout.

It is not a claim that a fixed truncated ρ-series approximates the whole weighted sector uniformly. The joint logarithmic frame guarantees that these finite coefficient extractions belong to a common local expansion and separate the finite-dimensional solution space.

The logarithms transform exactly:

logρ=2logr+logt,logσ=2logr.

Include every term from those binomials.

Consequence if the test passes

Then

P
−8ϵ
	​

c
3
	​

=c
3
	​

	​

(9)

proves that the chart-3 solution has only r
integer−8ϵ
, with any allowed logs of that branch.

The analytic factor H can mix this branch into all master components. It cannot create a new fractional radial exponent. This is the justified reduction to two radial seed amplitudes, not a truncation of the 20-row connection.

3. Transfer along the boundary, using one-variable systems

Once the physical radial seed sector is known, the expensive-looking transfer becomes a sequence of small boundary transports.

3.1 Transport the chart-3 radial boundary functions

Before making the residue constant by a tangential gauge, let

R
r
	​

(t)=
r=0
Res
	​

B
r
	​

(r,t),A
E
	​

(t)=B
t
	​

(0,t).

Flatness implies

dt
dR
r
	​

	​

=[A
E
	​

,R
r
	​

].
	​

(10)

The radial primary subspaces are therefore transported by the tangential equation.

Choose a rational basis V(t,ϵ) for the selected primary subspace and write the leading boundary vector as

f
0
	​

(t)=V(t)h(t).

With a left inverse LV=I, the induced system is

h
′
=L(A
E
	​

V−V
′
)h,
	​

(11)

together with the exact invariance check

(I−VL)(A
E
	​

V−V
′
)=0.

If the selected space is two-dimensional, this is a two-dimensional leading boundary problem.

Higher radial coefficients generally still have 20 components, but are forced recursively. For a branch

Y=r
λ
n,m
∑
	​

r
n
(logr)
m
f
nm
	​

(t),
[(λ+n)I−R
r
	​

(t)]f
nm
	​

+(m+1)f
n,m+1
	​

=
j=1
∑
n
	​

A
j
	​

(t)f
n−j,m
	​

.
	​

(12)

They do not require new integration constants at every n.

3.2 Chart 3 to chart 2

The exact overlap transformation is

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

=
t
2
	​

1
	​

.
	​

(13)

It preserves the original ρ,σ. Hence

r
3
λ
	​

=r
2
λ
	​

t
2
λ
	​

,logr
3
	​

=logr
2
	​

+logt
2
	​

.

Transport the chart-3 boundary solution to the seam t
3
	​

=1, continue in a regular physical frame, and represent it on the chart-2 side. The two radial gauges must be compared explicitly:

G
2
−1
	​

(r
2
	​

,t
2
	​

)G
3
	​

(r
2
	​

t
2
	​

,1/t
2
	​

).

Integer powers, powers of positive units, and logarithmic tangent normalizations all belong in that comparison.

If a gauge has a pole at t=1, do not substitute into it term by term. Either remove the apparent singularity with an exact local gauge, or match finite jets of a raw analytic vector or a full-rank physical observation map.

Removability of the final scalar density is not automatically removability of every normalized master-frame component. Use the level at which removability has actually been proved.

There is generally a real one-dimensional connection problem between t=0 and t=1. Residues alone do not determine its connection matrix. Use the existing finite solver on the induced boundary system. If its epsilon-regular preparation reduces the required orders to rational kernels with letters 0,1, your GPL machinery already supplies the integration and regularized limits. 
arXiv

Do not evaluate a finite Taylor series about t=0 at t=1 and call it exact transport.

3.3 The passage to chart 1 requires changing the normal variable

To reach the ray σ∼ρ
2
, analyze chart 2 at t
2
	​

→0, with r
2
	​

 now the tangential coordinate. Construct that normal system and match its amplitudes at the joint corner (r
2
	​

,t
2
	​

)=(0,0).

The chart-3 ratio equation having only finite poles at 0,1 does not settle this limit: a polynomial part may be irregular at t
3
	​

=∞. Verify the transformed chart-2 t
2
	​

=0 system explicitly.

Then transport its boundary functions from r
2
	​

=0 to r
2
	​

=1. The chart-2/chart-1 overlap is

r
2
	​

=t
1
−1/2
	​

,t
2
	​

=r
1
	​

t
1
	​

,
	​

(14)

with the positive square root. The seam is

r
2
	​

=1⟷t
1
	​

=1.

For a joint chart-2 mode,

r
2
λ
	​

t
2
μ
	​

=r
1
μ
	​

t
1
μ−λ/2
	​

.
	​

(15)

Thus

(λ,μ)=(−8ϵ,−6ϵ)

gives exactly

r
1
−6ϵ
	​

t
1
−2ϵ
	​

.

This is the precise certificate for the expected −6ϵ chart-1 sector: establish that the physical chart-2 t
2
	​

-normal amplitudes occupy only μ=−6ϵ. Do not infer that from its r
2
	​

-spectrum alone.

Again, a physical solution fixed by two constants can have components in several t
2
	​

-primary sectors. Test their projectors. There are no new free constants, but there may be several fixed amplitudes until the test proves otherwise.

The corresponding logarithms are

logr
2
	​

=−
2
1
	​

logt
1
	​

,logt
2
	​

=logr
1
	​

+logt
1
	​

.

Keep them exactly when transferring Jordan chains.

4. Determine endpoint jet demands after physical contraction

Use the actual pulled-back physical density,

H
j
	​

(r,t,ϵ)=J
j
	​

(r,t)C(π
j
	​

(r,t),ϵ)G
j
	​

(r,t,ϵ)Y
j
	​

(r,t,ϵ).
	​

(16)

The measure Jacobian belongs here. It does not belong in the master-to-master basis transformation.

Your lowest gauge orders alone give

−3+2=−1in chart 1,−4+3=−1in charts 2 and 3.

That is useful, but not a bound on the final density: rational amplitude coefficients can add poles, and physical contractions can cancel them.

For a surviving radial branch r
λ(ϵ)
, let q be the lowest integer radial order of the collected multiplier in (16). With normalized λ(0)=0, only jets

0≤n≤−1−q
	​

(17)

can be radially nonintegrable. If q≥0, no radial subtraction is needed for that term.

Compute those jets, collect exact cancellations, and update the bound. Do not generate an arbitrary global depth based on the worst unreduced entry.

The coefficient of a radial jet is a function of the ratio variable. Analyze its endpoint powers in the same way. Chart 2 needs both normals: the physical corner can be approached by r
2
	​

→0 or by t
2
	​

→0 with the other coordinate fixed.

A finite rectangle alone is not an L
1
 remainder

Suppose a branch has the form

r
a+λ(ϵ)
t
b+μ(ϵ)
(logr)
p
(logt)
q
A(r,t,ϵ),

with A analytic. Subtracting a finite rectangular polynomial from A does not necessarily remove the open-edge singularities.

Use the product Taylor subtraction on the analytic coefficient:

R=(1−T
r
N
r
	​

	​

)(1−T
t
N
t
	​

	​

)A.
	​

(18)

Here T
r
N
r
	​

	​

A retains coefficient functions of t, and conversely. Then

R=O(r
N
r
	​

+1
t
N
t
	​

+1
).

A sufficient condition is

a+ℜλ(0)+N
r
	​

+1>−1,b+ℜμ(0)+N
t
	​

+1>−1.
	​

(19)

The edge functions are obtained from the one-variable systems already described; they need not be reconstructed from an enormous two-variable Taylor series.

Logarithms do not alter strict power-integrability inequalities. They do matter at the borderline exponent and in the epsilon demand.

Bounding the tail

Once the logarithmic frame is analytic with nonvanishing units, the Frobenius recurrence gives a convergent majorant on a smaller neighborhood. After extracting explicit epsilon poles, require a bound of the form

∣R∣≤Kr
η
r
	​

t
η
t
	​

(1+∣logr∣+∣logt∣)
M
,η
r
	​

,η
t
	​

>−1,
(20)

uniformly on a small epsilon contour or punctured neighborhood used for Laurent extraction.

Cover the ratio interval by the normalized endpoint neighborhoods and a compact ordinary interval. Treat the removable seam in its regular frame. Bounded square-root units help establish this, but do not replace checks of the complete rational connection and gauge denominators.

A finite list of recurrence residuals is not itself the tail bound. The certificate consists of those residuals plus the analytic-unit bounds and the nonresonant/logarithmic recurrence theorem.

5. Preserve epsilon-suppressed modes until the endpoint moments are applied

A branch coefficient that is O(ϵ) can still produce a finite contact. For example,

ϵr
+
−1−8ϵ
	​

=−
8
1
	​

δ(r)+O(ϵ).
	​

(21)

Likewise, a Jordan logarithm changes the moment denominator:

∫
0
1
	​

r
−1+ω
(logr)
m
dr=
ω
m+1
(−1)
m
m!
	​

.

These are identities of analytically continued distributions, not ordinary pointwise limits. 
DLMF

Use exact generic-epsilon primary selection. Only afterward propagate Laurent demands through the matching matrices and endpoint moment maps:

d(input j)=
τ
max
	​

[N
out
	​

−val
ϵ
	​

K
τj
	​

].
	​

(22)

The coefficients K
τj
	​

 must include spectral-projector denominators, inverse matching matrices, gauge normalizations, Jacobians, and logarithmic moments.

The twelve-dimensional −4ϵ primary sector’s Jordan chain is either excluded as a whole primary component by the exact matching or retained with all of its logarithmic data. Testing only ordinary eigenvectors can miss the generalized eigenvector.

6. The minimal implementation I recommend

The new functionality can remain a small extension of the existing normal/tangential solver:

Operation	Finite acceptance condition
Joint chart-3 normalization	One compatible logarithmic frame; no unchecked divisor through (0,0); commuting corner residues
Ordered-to-chart matching	Exact coefficient map with full rank, or the targeted projector/nullspace condition (7)
Chart-3 sector selection	All unwanted primary amplitudes vanish at generic epsilon, with physical constants included where necessary
Boundary transport	Exact induced one-variable system, preserved tangent normalization, and regular seam matching
Chart-2 t-normal selection	Exact projector test for the candidate −6ϵ amplitudes
Endpoint jet demand	Contracted coordinate valuations, finite dangerous jets, and a convergent L
1
 tail bound

The computational sequence should be:

Check the joint logarithmic condition at chart 3’s origin. If it fails, locate the actual residual divisor or incompatible gauge; do not compensate by requesting more source jets.

Match a finite separating jet set to the complete ordered source. Use the source’s known constraints and constants, not only leading raw master values.

Prove or reject the −8ϵ-only seed selection.

Transport the resulting leading boundary system through chart 3 and chart 2.

At chart 2’s other normal, determine the physical t
2
	​

-sectors and transport them to chart 1.

Generate only the contracted jets required by (17)–(19).

This is boundary transport on a small resolved atlas. It does not require re-expanding the complete bulk GPL solution or computing a full connection matrix for irrelevant physical directions. Formal normal-crossing algorithms explicitly exploit the compatibility of the component systems; your existing exact gauge and finite-solver infrastructure is the appropriate place to implement the restricted version needed here. 
arXiv

Three focused regressions should accompany it:

The first counterexample above must fail the joint-logarithmic gate despite its correct ordered slopes.

A subleading mode such as g above must be detected unless excluded by the complete source-amplitude map.

The three Jacobians should give areas 1/3, 1/6, 1/2 for the constant density on the square, summing to one. This catches a lost ramification factor before distributional pushforward.

The likely simplification is indeed a two-dimensional physical radial seed sector in chart 3. The rigorous way to obtain it is finite, but it is a result of the common logarithmic frame and injective germ matching—not a consequence of adding the two ordered slopes alone. Once certified, the remaining work is a small number of one-variable boundary transports and coefficient-driven local jets, with every regulator-suppressed amplitude and Jordan logarithm retained until its endpoint contribution is known.