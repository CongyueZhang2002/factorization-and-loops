# CF303 Deferred Endpoint Residue Followup

## Question

# Correction and follow-up: CF303 deferred soft residue

Continue this same Assess Multiquadratic Pipeline conversation. A critical
correction invalidates part of my preceding prompt: I had computed the soft
incoming residue from the 143 materialized labels but treated 226 deferred
circuit labels as regular. They are not. Resolving the 96 exact exception
labels through their accepted provider shows 84 nonzero soft residues. Thus
the earlier claims that only one incoming pole contributes, that B has 26
nonzeros/rank 2, and that the full residue has one length-two zero chain are
not established and must not be used.

The accepted final-layer operator has three deferred groups:

- 96 exact exception-K labels (12 entries times epsilon orders -3..4), whose
  exact standard GPL/eMPL terms resolve in about 12 seconds;
- 98 cross-K labels (2 target rows times 7 source columns times orders -2..4),
  available from the accepted finite-field recurrence as F_q2 rational
  functions of u at each rational p image;
- 32 block-1 delta-K labels, likewise resolved pointwise from its accepted
  circuit.

The existing Python evaluator needs about 31--39 seconds per p image and
already returns normalized rational functions of u, so the local residue at
u=2p can be obtained cheaply by numerator(u0)/denominator'(u0) for a simple
pole (and the corresponding elliptic channel factor). Separately, we derived
the exact fixed-rho tangential connection for CF303-owned source rows 40--43:
it is rational/GPL with kernels 1/p, 1/(1-p), 1/(1+p), and p/(1-2p^2), and
its extraction/algebra takes under 40 seconds.

Please advise concretely on the fastest mathematically complete recovery of
the full soft normal factor without reconstructing or expanding the complete
45x45 connection:

1. Should we reconstruct only the at-most 2x43 endpoint residue Laurent deck
   B_q(p) from finite-field p images, with exact exception leaves added
   directly, or keep the cross/block1 part as a provider-backed function of p?
2. How should the elliptic-channel local residue be represented at
   P4(2p)=64 p^2(1-p^2), including the selected sheet, so that reconstruction
   is over the smallest field?
3. Is there a way to construct the induced six-mode normal/tangential selector
   pointwise and reconstruct only that reduced selector, avoiding reconstruction
   of all 86 B coordinates?
4. What are the minimum decisive modular checks for simple-pole order, generic
   rank/Jordan structure, and equality to the accepted circuit? We do not want
   another symbolic certificate layer.
5. Please revise your ETA/risk assessment in light of the corrected complete
   residue content.

Prefer an implementable finite-field algorithm and identify which quantities
must be characteristic-zero rational/algebraic functions for a paper-facing
formal result versus which may remain sealed exact providers until Stage 3.

## Pro response

Verdict: GO on projection-before-reconstruction; do not lift the full 2×43 residue deck first

The earlier one-pole/rank-one/Jordan-chain conclusion is void. The corrected problem is still computationally manageable because the unresolved objects can be evaluated cheaply pointwise. The shortest complete route is:

assemble the full endpoint residue pointwise⟶contract it with the physical source-mode selectors⟶reconstruct only the reduced normal/tangential selector deck.
	​


Keep the 98 cross-K and 32 block-1 contributions provider-backed during this calculation. Add the 96 exact exception contributions before taking residues or projecting. Reconstruct the full B
q
	​

(p)∈K(p)
2×43
 only if the reduced projection unexpectedly has the same degree/height or a later application genuinely needs a basis-independent 45×45 normal factor.

This follows the successful architecture already established in the campaign: modular evaluation of a compact composition is cheap, whereas forming its characteristic-zero expanded representation can dominate the calculation. 

11_reconstruct_dont_simplify

 The measured triple-root bottleneck was likewise downstream symbolic normalization, not the finite-field solves. 

08_three_root_slowdown_and_reco…

 The deferred architecture was explicitly designed to evaluate leaves and combine channels without materializing a whole forcing expression. 

codex_overnight_optimization_tr…

1. Do not reconstruct all 86 entries unless you need the universal normal factor

Write the complete soft normal residue as

R(p,ϵ)=(
ϵR
S
	​

B(p,ϵ)
	​

0
0
2×2
	​

	​

),B(p,ϵ)=
q
∑
	​

ϵ
q
B
q
	​

(p).

Here B must include all three groups:

B=B
exception
	​

+B
cross
	​

+B
Δ1
	​

.

The actual nonzero Laurent window must be read from this summed deck. Since the exception records include order −3, the full B may again start at −3; neither the old −2 statement nor the mere presence of order-−3 labels determines the result before cancellation.

Because the zero eigenvalue of R
S
	​

 is semisimple, let

P
0
	​

:Q
43
→kerR
S
	​

,R
S
#
	​


be the zero-eigenspace projector and group inverse. The exact singular factor is

ρ
R
=(
ρ
ϵR
S
	​

BΦ
S
	​

(ρ)
	​

0
I
2
	​

	​

),

with

Φ
S
	​

(ρ)=logρP
0
	​

+
ϵ
1
	​

R
S
#
	​

(ρ
ϵR
S
	​

−I).
	​

(1)

This is the block exponential of the regular-singular residue; no diagonalization of the 45×45 matrix is needed. Levelt theory provides precisely such a holomorphic-prefactor-times-residue-power local form for Fuchsian systems. 
arXiv

For a physical source selector V
S
	​

, the lower rows only require

BΦ
S
	​

(ρ)V
S
	​

,
	​


not B as an abstract 2×43 matrix.

Recommended reconstruction objects

Precompute the exact primary decomposition of R
S
	​

. Then, at every finite-field p-image, reconstruct only one of these equivalent compact sets:

B
q
	​

P
0
	​

V
S
	​

,B
q
	​

R
S
#
	​

R
S
k
	​

V
S
	​

,

for the finite set of k required by the minimal polynomial of R
S
	​

; or, preferably, evaluate B
q
	​

Φ
S
	​

V
S
	​

 directly to the required finite ϵ- and logρ-orders.

For the four genuinely new source modes, let V
own
	​

 be their exact 43×4 source-mode embedding. Then the new homogeneous six-mode normal problem uses only

B
ˉ
q
	​

(p)=B
q
	​

(p)V
own
	​

(p),
	​

(2)

an at-most 2×4 deck per regulator order.

The inherited 39-source contribution should be treated separately:

B
q
	​

V
inh
	​

Π
inh
	​

.

It is a known inhomogeneous contribution proportional to already named inherited periods, not part of the six-dimensional new homogeneous mode space.

Important ordering

Add the exact and provider-backed groups first:

B
q
total
	​

=B
q,exception
	​

+B
q,cross
	​

+B
q,Δ1
	​

,

and only then apply P
0
	​

, V
own
	​

, or inherited selectors. Projection is linear, but assembling first permits cancellations of apparent higher poles and avoids giving separate significance to provider labels.

What may remain provider-backed

The following may remain internal modular providers:

the 98 cross-K labels;

the 32 block-1 labels;

the raw 2×43 residue entries;

intermediate Hermite and partial-fraction records.

For a paper-facing characteristic-zero result, at least one of the following must be exact over Q(p) or its declared quadratic extension:

the reduced selector deck B
q
	​

V
own
	​

 and inherited contractions;

the final six-mode endpoint-to-interior selector;

or an exact arithmetic circuit over characteristic-zero rational leaves defining them.

A finite collection of F
q
	​

 provider values is an evaluation oracle, not itself the characteristic-zero formal result. Finite-field black-box reconstruction is standard and well suited to producing the smaller projected objects. 
arXiv

2. Represent the elliptic endpoint residue over one quadratic extension

At the soft point

u
0
	​

=2p,P
4
	​

(p,u
0
	​

)=64p
2
(1−p
2
).

Introduce

χ
2
=1−p
2
,χ>0for0<p<
2
	​

1
	​

.

Then

Y
0
	​

=σ
Y
	​

8pχ,σ
Y
	​

∈{+1,−1},

where σ
Y
	​

 is fixed once by the accepted quartic sheet.

Because

D
curve
	​

(p,2p)=−4p,ρ
root
	​

=
D
curve
	​

Y
	​

,

the common physical choice ρ
root
	​

(2p)=+2χ corresponds to

Y
0
	​

=−8pχ.

Use whichever sign follows from the accepted provider; do not reselect it prime by prime.

The smallest coefficient field is therefore

K
soft
	​

=Q(p,χ),χ
2
=1−p
2
.
	​


No complete quartic function field is needed at the endpoint.

Residue formulas

Since

ρ=2p−u,
u−2p
du
	​

=
ρ
dρ
	​

,

there is no additional minus sign.

For a rational channel

D(u)
N(u)
	​

du

with a simple pole at u
0
	​

,

Res
ρ=0
	​

=
D
′
(u
0
	​

)
N(u
0
	​

)
	​

.

For a quartic channel

D(u)
N(u)
	​

Y(u)
du
	​

,

the residue is

D
′
(u
0
	​

)Y
0
	​

N(u
0
	​

)
	​

=σ
Y
	​

8p(1−p
2
)D
′
(u
0
	​

)
N(u
0
	​

)χ
	​

.
	​

(3)

The second expression keeps the result in the polynomial pair basis

a(p)+b(p)χ

and avoids an inverse algebraic generator.

If the provider instead stores a Y-channel,

D(u)
N(u)Y(u)
	​

du,

its residue is

D
′
(u
0
	​

)
N(u
0
	​

)Y
0
	​

	​

.
Finite-field implementation

Do not identify χ with an arbitrarily chosen element of F
q
2
	​

 and try to align it across primes. Either:

evaluate in the formal pair algebra

F
q
	​

[χ]/(χ
2
−(1−p
2
));

or

evaluate both conjugate sheets and project onto the 1,χ channels.

This gives stable characteristic-zero reconstruction and makes the physical sign a final explicit factor σ
Y
	​

.

3. Reconstructing the six-mode selector directly is sound

Yes, provided the inherited 39-dimensional source subsystem is first treated as a known submodule.

Let

0⟶S
inh
	​

⟶S⟶S
own
	​

⟶0,dimS
own
	​

=4.

Choose exact quotient data

V
own
	​

:Q
4
→Q
43
,Q
own
	​

:Q
43
→Q
4
,

with

Q
own
	​

V
own
	​

=I
4
	​

,Q
own
	​

V
inh
	​

=0.

The induced source normal residue is

R
own
	​

=Q
own
	​

R
S
	​

V
own
	​

.

The six-mode normal residue is then

R
6
	​

=(
ϵR
own
	​

BV
own
	​

	​

0
0
2×2
	​

	​

).
	​

(4)

Any contribution from inherited modes is carried as a known particular selector and precomposed with the inherited period columns.

This reduces reconstruction from 86 scalar functions per order to at most eight for the homogeneous new modes. If the actual physical mode basis contains fewer than four independent own-source columns, contract further before reconstruction.

Direct selector reconstruction

An even smaller object is obtained by evaluating the complete normal factor on the six selected columns:

C
6
	​

(ρ,p,ϵ)=(
ρ
ϵR
S
	​

V
own
	​

BΦ
S
	​

(ρ)V
own
	​

	​

0
I
2
	​

	​

).
	​

(5)

Expand this only through the demanded finite ϵ- and logρ-orders and reconstruct those coefficient functions in p,χ.

This is mathematically preferable to reconstructing B first because:

it is exactly the object entering the physical selector;

source spectral cancellations occur before reconstruction;

integer heights and p-degrees can be materially lower;

unused source directions never become outputs.

Tangential selector: one missing ingredient

The exact fixed-ρ tangential source connection for rows 40–43 is not, by itself, enough to determine the full six-mode tangential system.

In coordinates (p,ρ),

u=2p−ρ

gives

A
∥
	​

=A
p
	​

+2A
u
	​

.

For a local Levelt selector Φ
6
	​

, the induced mode connection is

Γ
6
	​

=Reg
ρ=0
	​

[Φ
6
−1
	​

(A
∥
	​

Φ
6
	​

−∂
p
	​

Φ
6
	​

)].
	​

(6)

To construct Γ
6
	​

, one also needs the target-row tangential finite part, or equivalently the already rebased endpoint-to-interior selector as a function of p.

Flatness gives

∂
p
	​

R=[Γ,R],

but this does not uniquely determine Γ: its part in the centralizer of R, including zero-mode components, remains undetermined. Therefore:

normal six-mode selector: can be built from R
S
	​

 and B;

tangential six-mode connection: requires the target tangential data or a declared tangential gauge.

The efficient implementation is to evaluate the target tangential rows pointwise from the same deferred circuit, immediately reduce them to the six-mode quotient, and reconstruct only Γ
6
	​

. Do not reconstruct the full 45×45 tangential connection.

If Stage 3 instead defines the remaining six periods as explicit boundary-integral functions of p, Γ
6
	​

 may remain absent; the ledger must then name those functions rather than treating them as constants.

4. Minimum decisive modular checks

These checks should be performed on the assembled total residue or on the final reduced contractions, not on individual labels.

A. Simple-pole order

At each chosen (q,p,ϵ), expand the assembled provider in

ρ=2p−u

far enough to determine

B(ρ)=
j=−J
∑
0
	​

B
[j]
ρ
j
+O(ρ).

Require

B
[j]
=0(j<−1)

in both the rational and χ channels. Then set

B
soft
	​

=B
[−1]
.

This catches cancellations of higher poles between exception, cross, and block-1 groups. Applying N(u
0
	​

)/D
′
(u
0
	​

) separately is sufficient only after each summand is known to have at most a simple pole.

B. Generic zero-Jordan structure

No full 45×45 power sequence is necessary.

Because the source zero eigenspace is semisimple and the target normal residue is zero, define

r
0
	​

=rank(B
soft
	​

P
0
	​

).

Then, generically:

number of length-2 zero Jordan chains
dimkerR
dimkerR
k
rankR
	​

=r
0
	​

,
=38−r
0
	​

,
=38,k≥2,
=7+r
0
	​

.
	​

	​

(7)

Thus the corrected chain count can only be 0,1, or 2. Determine the generic value as the maximum rank observed at ordinary images; special points can only lower it.

C. Equality to the accepted circuit

If the production object is the reduced deck, compare only the complete contractions actually retained:

B
q
	​

V
own
	​

,B
q
	​

P
0
	​

V
phys
	​

,Γ
6
	​

,

against direct provider evaluations at unused images.

A minimal practical pattern is:

discovery: one prime, three unused p-values and two generic ϵ-values;

confirmation: a second prime, two unused p-values and two ϵ-values;

both χ conjugates, or direct pair-grade equality.

At every image check:

no pole below ρ
−1
;

reconstructed residue contraction equals the total provider contraction;

the rank r
0
	​

 is stable generically;

the reduced normal/tangential selector equations hold pointwise.

This is enough under the project’s random-point modular acceptance policy. It does not require reconstructing a validation-prime B deck or performing a symbolic identity.

5. Revised time and risk assessment

The earlier low-cost conclusion based on one pole and one zero chain was too optimistic. There are now three distinct tasks:

Task	Cost/risk
Assemble the complete soft residue at one p-image	Measured 31–39 s, plus about 12 s once for exact exception resolution
Determine generic pole order and r
0
	​

=rank(BP
0
	​

)	Low; a handful of images
Reconstruct the reduced selector in p	Main remaining uncertainty
Obtain target tangential six-mode data	Main mathematical dependency
Realistic pilot

Five to six p-images distributed across two primes give a decisive pole/rank pilot. At the measured rate this is roughly:

3–4 minutes serial;

below 1–2 minutes if four images run concurrently.

Reduced selector reconstruction

If the contracted 2×4 normal deck and six-mode tangential entries have the same low-degree p-alphabet suggested by the extracted source tangential kernels, a 12–24-image construction plus held-outs should remain in the 10–30 minute range on a small pool.

That is an engineering projection, not a degree guarantee.

Full B-deck reconstruction

The physical point-evaluation cost is shared across all 86 entries, so reconstructing full B would not multiply the evaluator time by 86. Its disadvantages are instead:

larger coefficient storage;

potentially higher maximum p-degree;

larger coefficient heights;

reconstruction of many functions that disappear after mode projection.

Given the earlier extreme-height behavior in CF303 coefficient lifts, this is the principal reason to project first.

Revised risk ranking

Highest mathematical risk: the target tangential six-mode connection is not yet supplied by the source-row tangential extraction.

Highest performance risk: reconstructing raw B
q
	​

(p) instead of its selector action.

Moderate risk: generic rank of BP
0
	​

 may be two, changing the local period/log ledger.

Low risk: elliptic endpoint branch handling, once represented in Q(p,χ).

Low risk: residue extraction itself; the current provider already returns normalized rational functions of u.

The broader project remains localized: CF303’s exceptional completion is the remaining nonstandard component after the other family machinery has largely succeeded. 

Pasted markdown

Immediate implementation sequence

Resolve the 96 exact exception labels once.

At each finite-field image, evaluate the 98 cross and 32 block-1 providers.

Convert every elliptic endpoint value into the pair basis

{1,χ},χ
2
=1−p
2
.

Sum complete local Laurent jets and extract the total B
q
[−1]
	​

(p).

Compute r
0
	​

=rank(BP
0
	​

); discard all prior Jordan conclusions.

Contract immediately with:

inherited physical selectors;

the four own-source mode columns;

the source primary projectors needed by (1).

Reconstruct only these reduced contractions in p.

Extract the target tangential finite part and form Γ
6
	​

 through (6), or explicitly define the six remaining periods as boundary-integral functions of p.

Feed the resulting exact six-mode selector deck into the already implemented endpoint-to-interior lazy rebase and H/K+T
25
	​

 operator.

Do not launch a full 2×43 characteristic-zero residue reconstruction first. The corrected residue content requires a new pointwise census, but projection-before-reconstruction remains the shortest mathematically complete route.
