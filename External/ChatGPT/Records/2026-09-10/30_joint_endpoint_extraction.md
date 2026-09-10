# GPT-6 Pro review: weighted endpoint extraction

Verified model: gpt-6-pro. Conversation 6aa0f5dd-de10-83e8-b032-74f47d77da2a; message abcc5a32-c210-46e3-b1f3-a868cd319646. Retrieved 2026-09-10. Displayed mathematics is imperfectly preserved by the text export.

## Question

We have implemented the same compact-cut certificate's joint-domain specialization with all your conditions: transverse PSD, a smooth future timelike reference, unscaled Gram, constant-rank unit-cut affine elimination under the joint angular pushforward (thus no endpoint atoms), and explicit failure for unchecked mixed D-kinematic divisors. Six tests pass including x-z and D(1-x)-1 rejection and dotted-cut rejection. Production coefficient checks are running. No endpoint coefficient is inferred by this certificate.

New useful reduction: differentiating the 22-spanning-set relations against the old 55 DE produced two further independent relations. Closing them in BOTH x,z gives a 20-dimensional exact subsystem. The final embedding satisfies dR+R A20-A55 R=0 identically in both variables; A20 is flat. Physical recoil onsets restrict its 8-dimensional -2epsilon normal sector to SIX tangential boundary functions. Full-rank physical Gamma/3F2 corner matching determines TWO constants (both fixed), all unused matching conditions passed. This 20-master boundary construction took18s. This is still a spanning DE system, no unnecessary minimality claim.

Now we need the practical general algorithm to COMPUTE all RR joint endpoint distributions. Let rho=1-x,sigma=1-z. The old complete bulk coefficients through their sufficient epsilon powers have explicit GPL solutions. The final20 coefficients need upper epsilon powers {2,1,2,2,0,0,0,0,1,0,...,0} for bulk epsilon0. Endpoint demands are not included yet. We have exact generic-epsilon normal Frobenius coefficients at rho=0 (functions of z), and can solve the tangential DE, with known physical amplitudes. Existing code handles arbitrary strong normal powers including every Taylor moment, matrix powers/Jordan logs and omitted-order audits. It also handles jointly smooth tensor-product factors rho^(a+b epsilon)sigma^(c+d epsilon).

The concern is a non-normal-crossing algebraic divisor: (1+x)^2-4xz = rho^2+4(1-rho)sigma. Other one-root sectors are regular at the double corner or rationalizable. Ordered rho-first then sigma expansions of the full DE do NOT by themselves establish a uniform joint remainder near sigma~rho^2. We have not assumed they do.

Please propose a concrete mathematically sufficient and computationally small workflow using the ACTUAL rational flat DE and original unit-cut integral definitions to finish the joint delta/plus/regular extraction. In particular:
1) Can one prove that this root sector contributes only to the locally integrable remainder after the physical coefficient contraction, using weighted valuations of the contracted DE modes? What exact finite checks would establish this rather than guess it from fixed-axis limits?
2) If weighted blowups are needed, suggest a COMPLETE real sector cover of the corner, transformed Jacobians/test functions, and how to recover the standard distributions in x,z without losing corner terms or leaving integral representations in the hard coefficient. Charts sigma=rho^2 t and rho=sqrt(sigma)u suggest a cover, but I do not want an ad-hoc path prescription. Can we bound all higher jets using the regular-singular rational connection in these charts?
3) Can a matrix version of sector endpoint moments compute all contact terms directly from local Frobenius data, leaving the already explicit bulk GPL expression as the regular coefficient? At NLO we have the full normal-crossing formula; at NNLO edge subtraction and corner matching must be compatible.
4) Is there a simpler valid approach for this measured three-particle class, e.g. polynomial test moments of the EXACT unexpanded density reduced by IBP, that fixes all delta/plus coefficients without a complete symbolic two-variable resolution? A finite coefficient result containing unsolved moments is not acceptable, but universal inclusive phase-space masters/Gamma integrals are available.

For context the physical observable has test support away from x=0 and z=0. We need the x=1 and z=1 faces and their corner. Please distinguish a concrete sufficient certificate from a heuristic, and prioritize an approach that takes seconds/minutes, not a generic sector-decomposition explosion. No literature hard coefficients are production input; we compare only after derivation.


## Pro response

The next step should be a two-chart analysis of the contracted density, not a deeper expansion of all 20 masters. For the divisor

Q(ρ,σ)=ρ
2
+4(1−ρ)σ,

your proposed weighted charts form a complete real cover and turn Q into a radial monomial times a uniformly nonzero factor.

That resolves the geometry. It does not by itself prove that the root-dependent contribution is locally integrable, or that the final answer fits the tensor-product distribution format. Those questions can be settled by a finite set of contracted Frobenius coefficients and a controlled remainder.

My recommended route is:

open-edge extraction⟶two-chart integrability test⟶finite corner-contact determination.
	​


For the last step, a small number of exact weighted z-moments may be cheaper than explicitly pushing every sector distribution back to the square.

1. A complete two-chart cover

Write the scalar density, including its ordinary external normalization but before the dρdσ integration, as

H(ρ,σ,ϵ)=C(ρ,σ,ϵ)I(ρ,σ,ϵ).

Split the positive square into

S
A
	​

: σ≤ρ
2
,S
B
	​

: σ≥ρ
2
.

Use

A:
B:
	​

ρ=r,σ=r
2
t,
ρ=ru,σ=r
2
,
	​

0<r,t<1,
0<r,u<1.
	​

	​

(1)

Their interiors are disjoint; the seam has measure zero in the common convergence domain. The maps cover every approach to the corner, including σ/ρ
2
→0,∞.

The absolute Jacobians are

J
A
	​

=r
2
,J
B
	​

=2r
2
.
	​

(2)

The negative oriented determinant of chart B introduces no minus sign in the real density.

For any test function ϕ,

⟨T
ϵ
	​

,ϕ⟩=
	​

∫
0
1
	​

drdtr
2
H(r,r
2
t,ϵ)ϕ(r,r
2
t)
+∫
0
1
	​

drdu2r
2
H(ru,r
2
,ϵ)ϕ(ru,r
2
).
	​

	​

(3)

A test function supported near the physical corner simply restricts these integrals. Establish (3) in your certified high-D domain and then continue it. This is the appropriate distributional use of sector coordinates, rather than a change of variables applied to already expanded deltas. Sector decomposition uses precisely this order: resolve the geometry, subtract in the resolved coordinates, then continue. 
arXiv
+1

The problematic root is resolved

In these charts,

Q
A
	​

Q
B
	​

	​

=r
2
[1+4(1−r)t],
=r
2
[u
2
+4(1−ru)].
	​

	​

(4)

Both bracketed factors are strictly positive and uniformly bounded away from zero near r=0, including the entire closed angular interval.

Consequently, on the physical branch,

Q
	​

=r
U
A
	​

	​

orr
U
B
	​

	​

.

There is no new sign ambiguity.

The interpretation of the boundaries is important:

t=0 in chart A is the original σ=0 edge.

u=0 in chart B is the original ρ=0 edge.

r=0 is the exceptional boundary representing the original corner.

t=1 and u=1 are the common artificial seam, not physical distribution supports.

These two charts resolve this divisor. Before declaring the entire connection resolved, factor its other pulled-back denominators. For example, another divisor ρ+σ becomes r(u+r) in chart B, which still needs treatment at r=u=0. Cancel apparent divisors or add a targeted subdivision only when the actual pulled-back system requires it.

Pull back the rational DE directly

Define A
ρ
	​

=−A
x
	​

, A
σ
	​

=−A
z
	​

, so

dI=(A
ρ
	​

dρ+A
σ
	​

dσ)I.

Then

B
A,r
	​

=A
ρ
	​

+2rtA
σ
	​

,
B
B,r
	​

=uA
ρ
	​

+2rA
σ
	​

,
	​

B
A,t
	​

=r
2
A
σ
	​

,
B
B,u
	​

=rA
ρ
	​

,
	​

	​

(5)

evaluated at the respective maps.

All these matrices remain rational. You need not expand the large bulk GPL expressions to construct them.

2. A finite sufficient test for “root contribution is only regular”

The right object to test is the complete physical density, preferably after subtracting its already determined ordinary-edge singular models. A “root sector” in one homogeneous basis is not necessarily a separately meaningful physical contribution.

2.1 A useful elementary weighted criterion

For a scalar term

ρ
a
σ
b
Q
−c/2
,

the transformed densities are

A:
B:
	​

r
a+2b−c+2
t
b
U
A
−c/2
	​

,
2r
a+2b−c+2
u
a
U
B
−c/2
	​

.
	​

	​

(6)

Thus a sufficient absolute-integrability condition is

ℜa>−1,ℜb>−1,ℜ(a+2b−c)>−3.
	​

(7)

The last inequality is the genuinely weighted corner condition. Fixed-axis limits do not test it.

For Frobenius sums, apply this reasoning to the contracted modes, including Jacobians, integer gauge shifts, rational coefficient valuations, and logarithms. Polynomial logarithms do not spoil integrability when the inequalities are strict.

After factoring explicit epsilon poles, a strict margin at ϵ=0 supplies a small common epsilon neighborhood in which the remainder is integrable. Its Laurent coefficients are then ordinary locally integrable functions.

Equality at a borderline exponent is not sufficient. A term r
−1
log
m
r is not integrable merely because its coefficient vanishes at ϵ=0.

2.2 What to compute from the actual DE

For each chart, use the existing normalizer to produce the radial Frobenius expansion

I(r,v,ϵ)=G(r,v,ϵ)
λ,j,m
∑
	​

r
λ(ϵ)+j
(logr)
m
b
λjm
	​

(v,ϵ),
(8)

where v=t or u. Contract before deciding which modes matter:

J
chart
	​

CI.

Only compute those radial jets whose contracted exponent at ϵ=0 is ≤−1, together with the finite extra orders required by your omitted-term audit. Once a remainder begins at a strictly integrable exponent, higher integer Taylor terms cannot reintroduce a radial divergence.

The coefficient functions b
λjm
	​

(v,ϵ) satisfy induced one-variable equations on the exceptional boundary. They must also be checked at v=0. Ordinary-edge subtraction is valuable here: subtracting the full edge profile, rather than only its corner value, removes infinitely many otherwise irrelevant radial coefficients multiplying the same angular edge singularity.

Do not obtain (8) by substituting into a finite number of terms of the old ordered expansion. Infinitely many old ρ-Taylor terms can contribute to one exceptional radial order when their σ-coefficients become singular. The pulled-back radial DE performs the required resummation.

2.3 Exact cancellation tests without GPL simplification

Suppose a dangerous coefficient is

q(v,ϵ)b(v,ϵ),∂
v
	​

b=A
E
	​

(v,ϵ)b.

First test whether q annihilates the allowed physical boundary subspace identically.

If not, close the rational row space under

∇
v
	​

q=∂
v
	​

q+qA
E
	​

.
	​

(9)

For a stable row basis R, the vector Rb obeys a closed homogeneous DE. If its full normalized initial data vanish, the coefficient vanishes identically.

This uses your exact Gamma boundary amplitudes only where necessary. Checking a single endpoint value is insufficient: a nonzero solution can vanish there. Use the complete Frobenius amplitudes or sufficient normalized jets.

The row-space closure is finite-dimensional. It is an efficient way to prove cancellation of forbidden weighted modes before generating identities between explicit GPLs.

2.4 The remainder needs a genuine regular-singular certificate

Rationality and flatness alone do not imply regular singularity. Even a scalar connection proportional to dr/r
2
 is flat and can have exponential behavior.

A concrete sufficient check is to exhibit an exact gauge, with all integer powers accounted for, in which the pulled-back connection has logarithmic poles only at the relevant coordinate faces:

Ω=Γ
r
	​

(r,v,ϵ)
r
dr
	​

+Γ
v
	​

(r,v,ϵ)
v
dv
	​

,
	​

(10)

with the coefficient matrices analytic on a neighborhood of the real chart after excluding any separately handled endpoint. Inspect the actual denominator factors and epsilon dependence; a divisor moving toward the corner as ϵ→0 cannot be treated as a uniformly nonzero unit.

Then the convergent Frobenius recurrences and analytic coefficient bounds control all higher jets. Resonances must retain their logarithmic solutions, rather than be handled by deleting singular recurrence equations. The ordinary Frobenius theory supplies both the recurrence and convergence distinction from an irregular formal series. 
DLMF

For implementation, record a remainder bound of the form

∣Rem∣≤Cr
η
r
	​

v
η
v
	​

(1+∣logr∣+∣logv∣)
M
,η
r
	​

,η
v
	​

>−1,
	​

(11)

locally uniformly in epsilon after explicit poles have been factored. Exact recurrence residuals plus bounds on the nonvanishing rational units supply this certificate. A numerical fit to the first few powers does not.

Initializing the exceptional-boundary solution

Use your known ordered data as boundary data for the ratio DE:

chart B, u→0, is the overlap with ρ≪
σ
	​

;

transport the corresponding exceptional-boundary functions to u=1;

match the master vector there to chart A at t=1;

continue toward t=0, checking the other edge.

This introduces no new physical constants. It may require additional normalized jets to transfer the already fixed constants. Check the rank of that transfer; do not assume one value fixes a resonant block.

3. A regression showing exactly what the weighted check must catch

Consider

F
ϵ
	​

(ρ,σ)=(ρ
2
+4σ)
−3/2−ϵ
.

It is regular at either open edge when the other coordinate is held positive. Nevertheless, both charts give the radial factor

r
−1−2ϵ
.

The sum of the angular residues at ϵ=0 is

	​

∫
0
1
	​

(1+4t)
3/2
dt
	​

+2∫
0
1
	​

(u
2
+4)
3/2
du
	​

=(
2
1
	​

−
2
5
	​

1
	​

)+
2
5
	​

1
	​

=
2
1
	​

.
	​


Thus

F
ϵ
	​

=−
4ϵ
1
	​

δ(ρ)δ(σ)+O(ϵ
0
),
	​

(12)

and, more sharply,

ϵF
ϵ
	​

=−
4
1
	​

δ(ρ)δ(σ)+O(ϵ).
	​

(13)

Equation (13) has zero ordinary interior coefficient at ϵ
0
, but a nonzero finite corner contact term. It is an appropriate regression for the endpoint planner, especially given the earlier epsilon-suppressed-term bug.

The same leading corner residue occurs with 4σ replaced by 4(1−ρ)σ; the difference modifies the analytic radial unit, not its value at r=0.

4. Matrix sector moments can compute contacts—but must act on pulled-back tests

For a matrix radial power, the basic moment is

∫
0
R
	​

drr
k
r
Λ(ϵ)
=R
Λ+(k+1)I
[Λ+(k+1)I]
−1
.
	​

(14)

This is first established where the lower limit converges, then continued. Logarithmic moments are derivatives with respect to k, or are read directly from Jordan blocks.

Use the full inverse matrix. A nilpotent Jordan part can increase the epsilon-pole order:

(βϵI+N)
−1
=
j=0
∑
s−1
	​

(βϵ)
j+1
(−N)
j
	​

,N
s
=0.

The valuations of N and all prefactors remain part of the demand calculation.

The original corner jets are weighted jets

The pulled-back test functions expand as

ϕ(r,r
2
t)
ϕ(ru,r
2
)
	​

=
i,j≥0
∑
	​

i!j!
r
i+2j
t
j
	​

∂
ρ
i
	​

∂
σ
j
	​

ϕ(0,0),
=
i,j≥0
∑
	​

i!j!
r
i+2j
u
i
	​

∂
ρ
i
	​

∂
σ
j
	​

ϕ(0,0).
	​

	​

(15)

Therefore radial moments couple to weighted degree i+2j, not to i+j. If a contracted chart density begins at r
ℓ
, only jets satisfying

i+2j≤−ℜℓ(0)−1
(16)

can require a nonintegrable Taylor moment, before accounting for cancellations and epsilon suppression. This gives a finite candidate contact list.

For example, with the chart Jacobian already included,

(π
A
	​

)
∗
	​

[w(t)δ
′′
(r)]=(∫wdt)δ
′′
(ρ)δ(σ)−2(∫twdt)δ(ρ)δ
′
(σ).
	​

(17)

The analogous chart B formula uses ∫u
2
wdu for the first coefficient and ∫wdu for the second.

This is why sector deltas cannot simply be renamed. Distributional derivatives act on the composed test function, including all chain-rule terms. 
DLMF

For ordinary edge deltas:

(π
A
	​

)
∗
	​

[h(r)δ(t)]
(π
B
	​

)
∗
	​

[h(r)δ(u)]
	​

=h(ρ)δ(σ),
=
2
σ
	​

h(
σ
	​

)
	​

δ(ρ).
	​

	​

(18)

Again, h here already includes the chart’s density Jacobian.

Only a few angular moments need integration

After the radial moments, the unknown quantities are one-variable moments of exceptional-boundary functions. Compute only those required by (15)–(16).

If

b
′
(v)=A
E
	​

(v)b(v),

a required integral

∫w(v)b(v)dv

can be implemented by appending an accumulator row to the existing one-variable DE, or by finding a primitive row

Q
′
(v)+Q(v)A
E
	​

(v)=w(v).

No new two-variable integration is involved.

At r=0, the two algebraic factors are

1+4t
	​

,
u
2
+4
	​

.

They are rationalized by

t=
4
s
2
−1
	​

,u=s−
s
1
	​

,

respectively. Thus, when the actual angular dependency graph contains only these conics and your established GPL kernels, the required moments fall within your existing rational-pullback and Hermite/GPL integration machinery. Rational functions times hyperlogarithms are precisely the class addressed by those integration algorithms. 
arXiv

Keep the subtraction interval and normalization explicit. Local Frobenius residues determine the singular part, but a few leading coefficients alone do not fix every finite corner coefficient relative to a chosen global plus prescription. Changes of subtraction convention shift finite contact terms and the accompanying remainder together.

5. Recover the standard square format without exporting sector integrals

I recommend reconstructing the standard form in the original coordinates, rather than symbolically converting every radial-plus pushforward.

5.1 First fix the distribution away from the corner

Use the existing ordinary-edge machinery to determine the full edge coefficient functions, not just their values at the corner.

Construct a candidate S in the standard tensor-product format, using the fixed [0,1] plus convention and compatible edge/corner overlap subtraction. Leave genuinely undetermined corner contacts as explicit unknowns.

Let f
0
	​

 be the already known complete interior coefficient at the desired Laurent order. Define

R
0
	​

=f
0
	​

−S
interior
	​

.
	​

(19)

Use the two-chart test to prove that R
0
	​

 is jointly locally integrable at the corner. Being separately integrable along every fixed-axis limit is not enough.

Then

K
0
	​

=S+Reg(R
0
	​

)

agrees with the physical coefficient on the square minus the corner, including the open edges. The remaining difference is supported at the corner:

T
0
	​

−K
0
	​

=
i,j
∑
	​

c
ij
	​

δ
(i)
(ρ)δ
(j)
(σ).
	​

(20)

The weighted scaling bound limits the finite set of (i,j). This is the standard supported-distribution ambiguity, now fixed by your common continued physical definition rather than by an arbitrary extension. 
arXiv

If the weighted bound permits only degree zero, one number remains: c
00
	​

.

5.2 Failure of the L
1
 test is meaningful

The finite part of F
ϵ
	​

 in (12) contains a genuinely joint singular distribution. Its ordinary bulk function (ρ
2
+4σ)
−3/2
 is not locally integrable.

It cannot be placed in a field labeled “regular” and repaired merely by appending a corner delta. A finite number of ordinary tensor-product plus terms does not automatically represent that mixed finite part.

Therefore, if such a residual survives in the physical contraction, you must either:

prove its cancellation against other contributions before export; or

retain an explicitly defined joint finite-part distribution internally until that cancellation occurs.

The anticipated simple exported format is an acceptance condition, not a permission to discard the obstruction.

For epsilon-suppressed modes, first apply the regulated sector moments: a mode can leave only a contact through the target order, as in (13), while its nonlocal finite-part contribution starts at a higher epsilon order. This is another place where exact valuation counting saves work.

6. The cheapest contact normalization may be an inclusive moment

Once the open-edge data and the jointly integrable remainder have been established, you need not integrate the two-variable bulk GPL expression to determine c
00
	​

.

Define an exact regulated moment

M
N
	​

(x,ϵ)=∫
0
1
	​

dzz
N
T
ϵ
	​

(x,z).
	​

(21)

For a source whose only explicit z-dependence is the measurement,

∫
0
1
	​

dzz
N
Jδ(2p⋅k
1
	​

−Jz)=(
J
2p⋅k
1
	​

	​

)
N
.
	​

(22)

Thus the measurement cut disappears under an actual integration, leaving an unmeasured phase-space integral with a polynomial numerator insertion. No cut has been silently replaced and no extra Jacobian appears.

If other source factors depend explicitly on z, substitute z=2p⋅k
1
	​

/J into those factors too.

Reduce only the few required moment insertions. You need the endpoint-supported part of the resulting one-variable x-distribution, not necessarily its complete interior solution.

Why the regular bulk need not be integrated

From (20),

∫
0
1
	​

dσ(1−σ)
N
δ
(j)
(σ)=N
j
	​

,

where N
j
	​

=N!/(N−j)!. Therefore

Coeff
δ
(i)
(ρ)
	​

[M
N
	​

−∫
0
1
	​

dzz
N
S]=
j
∑
	​

N
j
	​

c
ij
	​

.
	​

(23)

The moment of R
0
	​

 contributes no ρ-delta: a suitably weighted jointly L
1
 function remains L
1
 after integration over z.

If only c
00
	​

 is allowed, one exact moment fixes it, and a second moment checks it. For higher contact order, a finite set of N’s gives an invertible falling-factorial moment matrix.

This avoids a double GPL integration and avoids converting every sector-plus term to the original coordinates.

Required moment eligibility checks

Your observable test space excludes z=0. Polynomial weights do not literally have support away from zero. Before using (21), verify that the chosen power N makes both the original moment and the candidate’s weighted remainder well defined at the lower endpoint, including the required Laurent orders.

A sufficiently large N often removes ordinary small-z poles, but choose it from the actual power bound. Alternatively use a compactly supported weight, accepting that its direct integral may be less convenient.

The energy-weighted identity

eligible tags
∑
	​

z
i
	​

=1

is especially useful for the complete tag sum at N=1, which produces the inclusive current tensor. It fixes a channel sum, not each separate tagged coefficient. Per-channel moments remain valid, but must be evaluated from their own generated numerator insertions.

Do not assume that every such moment is a Gamma function. Test coverage in the existing unmeasured integral library; compute an additional universal integral if genuinely required. This is a small, selected moment calculation, not permission to use a published inclusive hard coefficient.

Finite polynomial moments cannot determine arbitrary unknown edge functions. They become sufficient here only after those functions are known, or after a finite-dimensional ansatz for them has an exact full-rank moment map.

7. Endpoint order demands remain lower-dimensional

Do not extend every two-variable master to the highest corner order.

After physical contraction, a sector moment has the schematic form

A
τ
	​

(ϵ)=
j
∑
	​

K
τj
	​

(ϵ)b
j
	​

(ϵ),

where K includes rational coefficients, the chart Jacobian, gauge normalization, radial/edge moment matrices, and any Gamma prefactors.

For output through ϵ
N
,

d(b
j
	​

)=
τ:K
τj
	​


=0
max
	​

[N−val
ϵ
	​

K
τj
	​

].
	​

(24)

This is the appropriate demand rule for the exceptional-boundary functions and their moments.

A Jordan block or a second angular endpoint moment can cost more than one epsilon order. Conversely, exact physical contraction can annihilate the leading moment and reduce the demand. Compute those cancellations before expanding scalar functions.

Your listed bulk orders remain the bulk requirements. Extra work should be confined to:

the ordinary edge combinations;

the finitely many nonintegrable weighted radial jets;

their angular moments and Gamma boundary coefficients;

the few inclusive moment sources used in (23).

An interior O(ϵ) remainder is not discarded until this analysis shows that no endpoint moment promotes it to finite order.

8. Recommended implementation order
Step	Exact output required
1. Ordinary faces	Full edge distributions with a fixed plus convention and compatible overlap subtraction
2. Two-chart pullback	Equations (1)–(5), all remaining divisor factors, and correct physical branches
3. Contracted weighted jets	Only dangerous modes, exact physical zero tests, and a certified integrable tail
4. Standard-form residual test	R
0
	​

 in (19) proved jointly L
1
, or an explicit unresolved joint distribution
5. Corner normalization	Selected matrix sector moments or, preferably when cheaper, the exact moments (21)–(23)
6. Final export audit	No unresolved moments, unsupported joint finite parts, or unexplained delta derivatives

Three inexpensive tests directly exercise this extension:

Measure cover: monomials must satisfy

(n+1)(m+2n+3)
1
	​

+
(m+1)(m+2n+3)
2
	​

=
(m+1)(n+1)
1
	​

.

These are the two-chart integrals of ρ
m
σ
n
.

Hidden finite contact: reproduce equation (13) exactly.

Nonlinear normal jets: reproduce the pushforward of δ
′′
(r) in (17), including the −2δ
′
(σ) contribution.

The computationally small route is therefore a hybrid: use the rational DE to certify and compute the finite dangerous weighted jets, retain the existing GPL bulk expression for the integrable remainder, and use a minimal number of exact unmeasured moments to normalize any remaining corner contacts.

The two-chart construction resolves the identified geometric obstruction without revisiting the full three-body sector decomposition. Whether the root-dependent physical remainder is actually L
1
 cannot be inferred from the root or the ordered limits alone; the contracted residue/jet checks above are the finite, sufficient test.