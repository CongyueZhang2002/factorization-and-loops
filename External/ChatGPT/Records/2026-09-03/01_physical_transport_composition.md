# Physical Transport Composition

## Question

# Follow-up: challenge the physical singular-boundary composition and CF303 endpoint route

Please continue this established **Assess Multiquadratic Pipeline** conversation. We have now implemented the general pieces, but I want a decisive mathematical critique before launching the overnight family campaign.

Current package design:

1. `BuildEndpointFrobenius` writes a regular-singular epsilon-form solution locally as
   `F(rho)=H(rho,eps) rho^(eps R) c`.
2. `BuildBoundaryModeMap` identifies and physically normalizes the allowed vectors/modes `c` from endpoint scalings.
3. `BuildTransportBoundaryVector[..., MissingPeriodAction -> Formal]` makes a rational selector basis whose independent constants are inert `BoundaryPeriodCoefficient[id,n]`; it emits the exact Stage-3 needs ledger.
4. `BuildRationalEpsilonLayerTransport` removes a rational-in-epsilon final-layer forcing by `F_T=G+H_path F_S`, now with a modular quartic-curve Hermite channel under development.
5. A lazy operator evaluates only requested words of grammar `D...D`, `D...D K_r S...S`, and the endpoint-gauge terms `H_r S...S`. GPLFactor/E4Factor letters split into marked GPL/eMPL letters only for the requested word. A physical output gauge such as CF303's `T25` still must be composed.

The historical CF303 scratch result already has an accepted 43-master mixed GPL/eMPL source operator, the complete 2x43 deferred path-gauge circuit (including seven exception forcings), and `T25`; it is lazy and finite-field evaluated, but remains family-specific scratch data and its boundary constants are not yet tied to the physical singular limit.

Please answer these concrete questions:

1. If the transport path starts at the singular physical endpoint, may the normalized mode vectors `c` be used directly as boundary selectors provided every word is interpreted as a tangentially regularized GPL/eMPL iterated integral? Precisely where do `H(rho,eps)` and the expansion of `rho^(eps R)` enter, and how do we avoid double-counting the logarithms/Jordan modes?
2. If direct tangential-base transport is not the best production representation, what is the shortest exact alternative that maps these modes to a regular interior base point without introducing a fictitious matching parameter or a large symbolic limit?
3. For CF303, should the existing deferred `H/K + T25` circuit be adapted as provider-backed lazy letters and composed with the formal physical-period selector basis, or is there a mathematical reason it must first be lifted to characteristic-zero rational functions? We accept complete random-point finite-field replay as production validation and explicitly do not want a dense symbolic reconstruction merely for checking.
4. What is the minimal paper-facing final object? Our intended output is a finite sum of rational/algebraic coefficients times regularized GPL/eMPL words times explicit boundary-period coefficients, plus a ledger naming exactly which period coefficients Stage 3 must evaluate. State any missing datum that prevents this from being a genuine physical transport rather than a formal interior-base operator.
5. Identify the single largest likely performance trap in this composition and the simplest way to avoid it. Any family phase over one hour will be stopped and profiled.

Please be concrete and critical. Do not propose extra hashes, redundant certificates, or a full symbolic identity pass.

## Pro response

Verdict: CORRECT FIRST, then GO

The endpoint machinery is conceptually correct, but the overnight CF303 composition should not start until two conventions are fixed explicitly:

The transport base point must match the boundary selector convention. The historical CF303 operator is an interior-base operator, so the singular-endpoint modes c cannot yet be inserted directly.

The physical-to-local endpoint-coordinate conversion must include the ϵ-dependent residue factor and Jordan mixing, not only the integer leading power.

The shortest production route is to retain the existing regular interior base point and compute one finite-order regularized endpoint-to-interior connection matrix. Then precompose that matrix with the formal period-selector basis before invoking the existing lazy GPL/eMPL and H/K+T
25
	​

 machinery.

This is downstream of the CF303 exceptional-block problem described in the project context. 

Pasted markdown

1. When the mode vectors c may be used directly

Near the singular endpoint, let the pulled-back canonical system be

dF=ϵ(R
ρ
dρ
	​

+A
reg
	​

(ρ)dρ)F,

with Frobenius solution

F(ρ,ϵ)=H(ρ,ϵ)ρ
ϵR
c,H(0,ϵ)=I.

The available BuildEndpointFrobenius implementation uses precisely this form and normalizes H(0,ϵ)=I.

Choose a tangential base point 
v
=∂
ρ
	​

, including a branch of logρ. The regularized fundamental matrix is characterized by

U
v
	​

(ρ,ϵ)ρ
−ϵR
⟶I(ρ→0),

so

U
v
	​

(ρ,ϵ)=H(ρ,ϵ)ρ
ϵR
.

Therefore

F(z,ϵ)=U
v
	​

(z,ϵ)c
	​


and the components of c may be used directly as boundary selector columns if and only if the GPL/eMPL operator itself is based at that same tangential base point.

Tangentially regularized iterated integrals are normalized by taking the regularized constant at the endpoint; repeated endpoint letters generate the logarithmic polynomial associated with the singular residue. This is standard for hyperlogarithmic transport and is also the prescription used for endpoint-simple-pole iterated integrals in current Feynman-integral applications. 
arXiv
+1

Where H and ρ
ϵR
 enter

There are two equivalent representations, but they must not be mixed.

Tangential-word representation

F(z)=U
v
	​

(z)c.

Here the regularized Chen series of the full connection already contains:

the expansion of ρ
ϵR
 through words made only from the endpoint letter;

the analytic Frobenius factor H through mixed words involving regular and singular kernels.

Do not multiply by another explicit Hρ
ϵR
.

Explicit Frobenius-factor representation

F(ρ)=H(ρ)ρ
ϵR
c.

Here one transports a desingularized problem and inserts Hρ
ϵR
 explicitly. One must not also let the ordinary word engine generate the same endpoint logarithms.

For a Jordan block R=λI+N,

ρ
ϵR
=ρ
ϵλ
j=0
∑
dimN−1
	​

j!
(ϵlogρ)
j
	​

N
j
.

These logarithmic/Jordan modes are generated either by the matrix exponential or by repeated endpoint letters—not both.

Mandatory physical-coordinate conversion

Suppose the physical endpoint variable t and package local coordinate satisfy

t=αρ
κ
(1+O(ρ)).

For a mode t
m+ϵλ
,

t
m+ϵλ
=α
m+ϵλ
ρ
κm+κϵλ
(1+O(ρ)).

At matrix level the local and physical boundary vectors differ by

c
ρ
	​

=α
M
exp(ϵR
t
	​

logα)c
t
	​

,R
ρ
	​

=κR
t
	​

,
	​


where M contains the integer endpoint valuations. For nontrivial Jordan blocks, the exponential in logα mixes generalized modes.

In the available BuildBoundaryModeMap script, LeadingCoefficient is raised to the integer valuation, while the ϵ-exponent and generalized level are carried separately. If the current package still behaves this way, it is correct only when BoundaryPeriodCoefficient[id,n] is defined in the local-ρ convention. If those coefficients are intended to be physical-t endpoint periods, the factor exp(ϵR
t
	​

logα), including Jordan mixing, is missing.

Elliptic caveat

Direct tangential eMPL transport is straightforward only when the resulting connection is logarithmic in a local uniformizer on the selected elliptic sheet. If the quartic degenerates at the physical endpoint, or individual eMPL kernels have higher-order endpoint poles whose cancellation occurs only after matrix summation, regularizing each letter independently is not justified. In that case the interior-base representation below is the safer one. eMPLs are iterated integrals on elliptic curves, but their base point and sheet are part of their definition. 
APS Journals
+1

2. Shortest exact alternative: one regularized endpoint-to-interior matrix

For CF303, retain the historical regular interior base point u
∗
	​

 used by the accepted mixed GPL/eMPL operator.

Define

C
∗
	​

(ϵ)=U(u
∗
	​

,
v
0
	​

;ϵ),
	​


the regularized transport matrix from the physical tangential base point 
v
0
	​

 to u
∗
	​

. Then

F(u
∗
	​

,ϵ)=C
∗
	​

(ϵ)c,

and for a general endpoint u,

F(u,ϵ)=U(u,u
∗
	​

;ϵ)C
∗
	​

(ϵ)c.
	​


This exactly reuses the existing interior-base CF303 operator.

Equivalently,

C
∗
	​

(ϵ)=Reg
ρ→0
	​

[U(u
∗
	​

,ρ;ϵ)H(ρ,ϵ)ρ
ϵR
].

Reg means the regularized constant term in the ρ- and logρ-expansion, not evaluation at a small matching parameter. There is:

no fictitious cutoff ρ=δ;

no extrapolation δ→0;

no large symbolic Limit;

no dependence on a chosen overlap point.

Compute C
∗
	​

 only through the epsilon orders demanded by the final observable. It can remain a sparse matrix of regularized GPL/eMPL constants.

This representation is preferable for the current campaign because it:

reuses the existing CF303 path operator;

isolates all singular-endpoint conventions in one matrix;

avoids rebuilding the H/K+T
25
	​

 engine with singular lower limits;

handles a potentially degenerating elliptic curve through the full Frobenius system rather than through letterwise endpoint prescriptions.

Tangential-base transport composes with ordinary path transport by the usual path-composition/deconcatenation law for iterated integrals. 
arXiv

3. CF303 H/K+T
25
	​

: provider-backed is acceptable, but modular values alone are not the exact result

The existing deferred circuit should be adapted directly:

physical periods⟶c⟶C
∗
	​

c⟶lazy source operator⟶H/K⟶T
25
	​

.

There is no mathematical reason to flatten every coefficient into one expanded characteristic-zero rational function.

An acceptable exact representation is either:

a lifted finite Laurent deck over Q and the declared algebraic extension; or

an exact arithmetic circuit whose leaves and operations are defined over Q, with the quartic relation and Hermite operators specified exactly.

A collection of finite-field values—even with complete fresh-prime replay—is a validation oracle, not by itself a characteristic-zero analytic coefficient. Several characteristic-zero functions can have the same finite set of modular images.

This matters particularly for the path gauge. The current package source describes a route in which the K
n
	​

 residues are reconstructed while H
n
	​

 may remain at modular images. But the final solution contains

F
T
	​

=G+HF
S
	​

.

Consequently, a paper-facing analytic result needs either:

the demanded H
n
	​

 lifted exactly; or

an exact characteristic-zero circuit defining each H
n
	​

.

No dense symbolic simplification is required.

This is consistent with the campaign’s successful architecture: treat source compositions as compact black boxes rather than swollen symbolic expressions, and retain deferred leaf/channel structure through reconstruction. 

11_reconstruct_dont_simplify

 The measured runs already showed that symbolic normalization, rather than the modular solve, was the dominant historical bottleneck. 

08_three_root_slowdown_and_reco…

 The deferred production route likewise keeps additive leaves and reconstructs only the required rational-grade channels. 

codex_overnight_optimization_tr…

Thus:

provider-backed exact circuit: GO;modular-only coefficient oracle: not yet paper-facing exact.
	​

4. Minimal paper-facing final object

The intended structure is appropriate:

[I
i
	​

]
ϵ
N
	​

(z)=
α,m,w
∑
	​

C
i;αmw
(N)
	​

(z)I
w
reg
	​

(z;
v
0
	​

)Π
α,m
	​

,
	​


where:

C
i;αmw
(N)
	​

 is an exact rational/algebraic coefficient or exact arithmetic circuit;

I
w
reg
	​

 is a GPL/eMPL word with the stated tangential or interior-base convention;

Π
α,m
	​

 is BoundaryPeriodCoefficient[α,m];

the ledger identifies the Stage-3 period attached to every (α,m).

An epsilon-factorized differential equation plus boundary values supplies an order-by-order iterated-integral solution, including in elliptic settings; the boundary data are therefore part of the mathematical result rather than auxiliary bookkeeping. 
arXiv

Data still needed for a genuinely physical transport

The following are mathematical data, not extra validation layers:

Endpoint coordinate and tangent

ρ,
v
0
	​

,t=αρ
κ
(1+O(ρ)).

Analytic branch

branch of logρ;

physical +i0/−i0 continuation;

lift to the relevant algebraic/elliptic sheet.

Mode-to-period map

normalized right mode or Jordan-chain vector;

integer valuation;

epsilon exponent;

generalized-log level;

the α
ϵR
 conversion described above.

Base-point connection

either declaration that all words begin at the same tangential base point;

or the exact matrix C
∗
	​

(ϵ) mapping those modes to the interior base point.

Exact coefficient representation

lifted finite deck or exact circuit for the CF303 H/K contribution;

exact T
25
	​

.

Demanded epsilon depth

including the effect of negative valuations and the endpoint/output gauges.

Without item 4, the historical CF303 object remains an interior-base operator. Without item 3, the inert period coefficients are not yet tied to physical asymptotic modes.

The periods themselves may remain unevaluated: the result is legitimately “exact up to the explicitly named boundary periods.”

5. Largest likely performance trap

The dominant risk is the eager Cartesian expansion

endpoint modes×Jordan/log terms×GPL/eMPL words×H/K×T
25
	​

.

This would reproduce the word explosion already avoided by the lazy CF303 engine. It can also double the endpoint-log sector if both ρ
ϵR
 and tangential endpoint words are expanded.

Simplest avoidance

Precompose the endpoint data at matrix level:

B
∗
	​

(ϵ)=C
∗
	​

(ϵ)M
mode
	​

(ϵ),
	​


where M
mode
	​

 maps the formal period coefficients into c-space. Use the columns of B
∗
	​

 as the interior boundary selectors.

Then:

discard zero selector columns;

request only the physical source rows and epsilon orders needed;

propagate those sparse columns through the existing weighted word operator;

apply H/K as pair-valued sparse coefficient circuits;

apply T
25
	​

 only at the requested output rows/orders;

split composite GPL/eMPL letters into marked points only during final export.

Do not materialize:

a full Frobenius series for every mode;

explicit powers of logρ separately from tangential words;

the full word table;

all Stage-3 period columns before sparse mode projection.

The regularized endpoint matrix is computed once per family. It should not be recomputed per master, word, or period coefficient.

Launch decision

Do not launch the overnight family composition with physical mode coefficients inserted directly into the historical interior-base CF303 operator.

Launch after these minimum corrections:

define whether BoundaryPeriodCoefficient is normalized in physical t or local ρ;

include α
ϵR
 and Jordan mixing when converting between those conventions;

construct the finite-order regularized matrix C
∗
	​

(ϵ) from the physical tangential base point to the existing interior base point;

ensure the CF303 H contribution is represented by an exact finite deck or exact characteristic-zero circuit;

precompose C
∗
	​

M
mode
	​

 before lazy word traversal.

After those changes, the proposed final object is mathematically complete up to the explicitly listed Stage-3 periods, and the provider-backed lazy implementation is the correct performance architecture.
