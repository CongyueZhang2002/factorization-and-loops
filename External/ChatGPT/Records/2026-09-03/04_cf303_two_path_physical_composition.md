# CF303 Two Path Physical Composition

## Question

# CF303 singular two-path physical composition

Please continue the established **Assess Multiquadratic Pipeline** conversation.  We have now implemented the compact soft-mode construction you recommended and need an independent check of the shortest mathematically honest way to compose it with the accepted normal GPL/eMPL operator.

Current exact facts:

- The physical soft sheet is `rho=2 p-u -> 0+`, `0<p<1/Sqrt[2]`.
- The six CF303-owned physical masters have normal spectrum `{0,0,0,0,0,-2-4 eps}`.  The apparent moving-frame mismatch cancels exactly after the first Frobenius regular-prefactor jet.
- After a rational moving frame, integer shear, and the accepted T25 gauge, the tangential system splits into a four-source/two-target rational-in-epsilon layer.  The source blocks are strict epsilon form: two modes `-2 eps dp/p`, one `-8 eps dp/p`, and one `eps(4/p+16p/(1-2p^2)) dp`.  The target is strict epsilon form on letters `{p,1-p,1+p}`.  Only six incoming scalars remain.
- Our finite-field rational-layer engine now reconstructs the full rational gauge `H(p)` when the endpoint is symbolic.  On the actual CF303 layer it takes 0.048 s, uses three 31-bit primes plus one held-out modular point, and returns a 3.1 KB gauge; all input-backed checks pass.
- The accepted normal `z` operator is based at `z=1/2` and ends at generic `uFinal`.  It is a lazy one-incoming-edge GPL/eMPL operator with global gauge convention `F25=G25+H(z) F_source` and physical `I25=T25(z) F25`.  The physical boundary is the singular point `z=2p`, so `H(2p)` cannot be naively substituted before mode/Frobenius cancellation.
- Only seven normal-source state rows survive in `[T25 H,T25]`; they map to CF1{1}, CF12{4}, CF21{1}, CF199{1,2}, CF53{4,5}.  The projected deck is 92 rational GPL-only scalars.  Two distinct class-44/PID9 zero-mode series (CF199 and CF53) remain formal Stage-3 inputs; the CF21 free mode is exactly zero but its forced volume particular remains.

We want a paper-level result as a finite sum of products of a tangential `p` GPL word and a normal `z` GPL/eMPL word times exact/formal period coefficients.  We do **not** want a dense characteristic-zero H/K matrix, symbolic endpoint substitution into a singular gauge, or another redundant certificate layer.

Please answer concretely:

1. Is the correct composition to construct columns labelled `(p-word, period ID, epsilon order)`, use their rational coefficient maps as the regularized source/target selector deck at `z=2p`, and then let the existing lazy normal word operator act on those columns?  If not, give the correct minimal construction.
2. How exactly should the one nonzero normal mode `rho^(-4 eps)` be represented in that column/deck formalism?  Is a tangentially regularized Chen-word prescription plus its eigenmode vector sufficient, or must an explicit local Frobenius connection matrix multiply the normal words?
3. For the global gauge `F=G+H F_source`, state the correct regularized base selector for G at `z=2p`.  Which finite/principal combinations of H and the source Frobenius jets enter, and how do we avoid separately evaluating divergent `H(2p)`?
4. Give a minimal reusable API/data contract for this two-path composition that keeps words lazy, exposes the exact Stage-3 period list, and handles zero and nonzero endpoint exponents without family-specific code in `Private`.
5. Identify a decisive small control that would catch an omitted Frobenius jet or double-counted target extension without requiring full symbolic verification.

Please distinguish a mathematically required step from bookkeeping that can safely remain inert until numerical Stage 3.

## Pro response

Verdict: GO, with one mandatory regularized endpoint map

The proposed outer organization is correct:

p-word×normal z-word×physical period.

But the tangential columns cannot be inserted directly into the historical z=1/2-based operator. They must first be converted from physical soft-mode coefficients to the Levelt constants of the G-basis used by the normal operator, and then passed through the already implemented tangential endpoint rebase.

The shortest exact composition is

U
⊥
	​

(u
final
	​

,
v
2p
	​

)S
soft
	​

(p,ϵ)U
∥
	​

(p,p
0
	​

)Π,
	​


followed by

I
25
	​

(u
final
	​

)=T
25
	​

(u
final
	​

)[G
25
	​

(u
final
	​

)+H
⊥
	​

(u
final
	​

)F
S
	​

(u
final
	​

)].
	​


Here:

U
∥
	​

 is the tangential p-GPL operator;

S
soft
	​

 is the regularized physical-to-(F
S
	​

,G
25
	​

) endpoint selector;

U
⊥
	​

(u
final
	​

,
v
2p
	​

) is the normal operator rebased to the inward tangent at ρ=2p−u=0;

H
⊥
	​

 denotes the normal path gauge, distinct from any tangential rational-layer gauge.

CF303 is the localized exceptional component of the otherwise nearly completed three-root campaign. 

Pasted markdown

1. Correct two-path column construction

Write the tangential soft-mode solution as

c
phys
	​

(p,ϵ)=
α,w
p
	​

,n
∑
	​

ϵ
n
v
α,w
p
	​

,n
	​

(p)G
p
	​

(w
p
	​

;p)Π
α
	​

,

where:

Π
α
	​

 is a named Stage-3 physical period at the chosen tangential reference point p
0
	​

;

w
p
	​

 is a tangential GPL word;

v
α,w
p
	​

,n
	​

 is a sparse six-component vector in one explicitly declared soft-mode basis.

For each such column, form

c
normal
	​

=S
soft
	​

(p,ϵ)v
α,w
p
	​

,n
	​

(p).

Then either use the directly rebased normal operator

U
⊥
	​

(u
final
	​

,
v
2p
	​

),

or, equivalently,

U
⊥
	​

(u
final
	​

,
v
2p
	​

)=U
⊥
	​

(u
final
	​

,1/2)U
⊥
	​

(1/2,
v
2p
	​

).

The second factor must be the regularized endpoint-to-interior connection, not ordinary evaluation at u=2p.

Therefore the proposed key

{pWordID, PeriodID, EpsilonOrder}

is correct, with a sparse normal-boundary vector as its value. If S
soft
	​

 and the rebase have nontrivial epsilon series, their orders must be convolved before the resulting column is handed to the normal word operator:

b
∗,w
p
	​

,α
(N)
	​

=
n+s+c=N
∑
	​

C
soft→∗
(c)
	​

S
soft
(s)
	​

v
α,w
p
	​

,n
	​

.

The final ancillary should keep the result indexed by

{epsilonOrder, pWordID, zWordID, PeriodID}

rather than expanding the Cartesian product into one enormous expression.

A direct tangential rebase is preferable across the entire interval because the historical point u=1/2 coincides with the soft endpoint when p=1/4. The regularized operator U
⊥
	​

(u,
v
2p
	​

) avoids presenting that auxiliary interior-base collision as a physical singularity.

2. The ρ
−4ϵ
 mode

After the integer shear, the nonzero mode has the local form

Ψ
−4
	​

(ρ,p,ϵ)=P(ρ,p,ϵ)ρ
−4ϵ
v
−4
	​

(p,ϵ),P(0,p,ϵ)=I.

Before the shear, the corresponding physical mode carries the additional integer behavior ρ
−2
. That integer valuation belongs in the mode metadata and physical basis map; it must not be inserted again into the sheared normal operator.

For ρ>0,

ρ
−4ϵ
=exp[−4ϵlogρ]=
k≥0
∑
	​

k!
(−4ϵ)
k
	​

log
k
ρ.

Thus:

if the normal operator is genuinely based at the tangential point 
v
2p
	​

, repeated endpoint-letter words encode this factor;

if the operator remains based at 1/2, the regularized rebase U
⊥
	​

(1/2,
v
2p
	​

) must encode it.

The eigenmode vector plus exponent is enough to define the local mode normalization, but not enough by itself to map the mode to the interior base. The regular Frobenius prefactor P(ρ) contributes to that map. The package’s endpoint builder uses precisely the structure H(ρ,ϵ)ρ
ϵR
c.

No Frobenius matrix should multiply every normal word afterward. It enters once, through S
soft
	​

 and the regularized rebase. Multiplying an explicit ρ
−4ϵ
 factor after using the tangentially normalized normal operator would double-count the endpoint logarithms.

3. Correct regularized selector for G
25
	​


Let

U
H
−1
	​

(ρ,p,ϵ)=(
I
−H
⊥
	​

(ρ,p,ϵ)
	​

0
I
	​

),

corresponding to

F
25
	​

=G
25
	​

+H
⊥
	​

F
S
	​

.

Let:

Ψ
phys
	​

(ρ,p,ϵ) be the local physical soft-mode matrix after the tangential construction;

Φ
G
	​

(ρ,p,ϵ) be the full six-mode Frobenius matrix of the transformed normal system (F
S
	​

,G
25
	​

), including the off-diagonal normal extension and the regular prefactor jets.

Then the endpoint selector is

S
soft
	​

(p,ϵ)=Reg
ρ=0
	​

[Φ
G
	​

(ρ,p,ϵ)
−1
U
H
−1
	​

(ρ,p,ϵ)Ψ
phys
	​

(ρ,p,ϵ)].
	​

(1)

Reg means the coefficient in the prescribed Levelt mode basis after stripping the integer powers, the factors ρ
ϵR
, and the associated Jordan logarithms. It is not the ordinary finite part of H
⊥
	​

.

Equivalently, for a particular physical column,

c
G
	​

=Reg
ρ=0
	​

[Φ
G
−1
	​

(F
25
	​

−H
⊥
	​

F
S
	​

)].
	​

(2)

This is the correct way to avoid evaluating a divergent H
⊥
	​

(2p).

Which Frobenius jets enter?

Suppose H
⊥
	​

 has pole order m,

H
⊥
	​

(ρ)=
k=−m
∑
∞
	​

ρ
k
H
k
	​

,

and write the regular factors schematically as

P
G
−1
	​

(ρ)=
i≥0
∑
	​

ρ
i
Q
i
	​

,P
S
	​

(ρ)=
j≥0
∑
	​

ρ
j
P
j
	​

.

The regularized constant receives contributions with

i+j+k=0.

Therefore a pole of order m requires Frobenius jets through total order m. For a simple pole,

CT[P
G
−1
	​

H
⊥
	​

P
S
	​

]=H
0
	​

+Q
1
	​

H
−1
	​

+H
−1
	​

P
1
	​

,

before resolving the residue-eigenvalue and Jordan sectors.

This explains the observed cancellation after the first regular-prefactor jet. Keeping only H
0
	​

, or substituting H
⊥
	​

(2p), misses the two terms involving H
−1
	​

.

The full matrix formula (1) is preferable to separate source/target formulas because the transformed normal system still contains its incoming K coupling. Its off-diagonal Frobenius jet may contribute to the regularized selector.

Basis convention for T
25
	​


Use exactly one of the following:

If the tangential soft deck outputs F
25
	​

, apply (1) directly.

If it outputs the physical I
25
	​

, include T
25
−1
	​

 inside Ψ
phys
	​

 before applying U
H
−1
	​

.

At the final endpoint apply

I
25
	​

=T
25
	​

(G
25
	​

+H
⊥
	​

F
S
	​

)

exactly once.

The package’s rational-layer construction uses the same F
T
	​

=G+HF
S
	​

 convention.

4. Minimal reusable API

A generic package-level object can be organized as:

BuildSingularTwoPathTransport[
    TangentialSelectorDeck,
    SoftModeMap,
    NormalLeveltDeck,
    EndpointGaugeDeck,
    NormalRebaseOperator,
    NormalWordOperator,
    OutputGaugeDeck,
    Demand
]
Required input fields
TangentialSelectorDeck
  {epsilonOrder, pWordID, PeriodID} -> sparse physical-mode vector

SoftModeMap
  physical-mode basis, p-dependent moving frame,
  integer valuation, epsilon exponent, Jordan level

NormalLeveltDeck
  normal coordinate rho
  endpoint map uSoft(p)
  inward tangent
  full residue matrix
  integer shear
  regular-prefactor jets
  mode basis

EndpointGaugeDeck
  compact principal/Laurent deck for U_H^-1
  basis convention: physical I, F, or G

NormalRebaseOperator
  lazy U_normal(1/2, tangent at uSoft(p))
  or directly U_normal(uFinal, tangent at uSoft(p))

NormalWordOperator
  single-word coefficient accessor

OutputGaugeDeck
  H_perp(uFinal)
  T25(uFinal)

Demand
  requested physical rows and epsilon orders
Output fields
RegularizedEndpointSelectors
  {epsilonOrder, pWordID, PeriodID} -> sparse normal-mode vector

TwoPathCoefficientAccessor
  {epsilonOrder, pWordID, zWordID, PeriodID} -> exact coefficient

FormalPeriods
  independent Stage-3 period identifiers only

Stage3Needs
  PeriodID
  owner family / topology
  tangential reference point p0
  required epsilon orders
  soft integer valuation
  epsilon exponent
  Jordan level
  inherited / CF303-owned
  known-zero / forced-particular / unevaluated

The two class-44/PID9 series remain entries in FormalPeriods. The exactly zero CF21 free mode should not receive a period ID; its forced-volume particular is a derived column referencing the periods that generate it.

The authoritative result should remain a sparse tensor-product word table. A p-word and a normal z-word should remain separate IDs; they are words on two ordered legs, not one shuffle alphabet.

This is consistent with the project’s demonstrated performance architecture: compact modular evaluation is cheap relative to materializing a swollen symbolic composition. 

11_reconstruct_dont_simplify

 The measured bottleneck was symbolic post-solve normalization rather than finite-field solving. 

08_three_root_slowdown_and_reco…

 The established deferred route therefore keeps additive leaves and combines only the required exact channels. 

codex_overnight_optimization_tr…

5. One decisive small control

Use one endpoint intertwining jet at a fresh modular p-image.

Choose a generic linear combination v of:

the nonzero ρ
−4ϵ
 mode;

at least one source-fed zero mode;

one independent target mode.

In the truncated ring in ρ, ϵ, and formal L=logρ, compare

U
H
−1
	​

(ρ)Ψ
phys
	​

(ρ)v−Φ
G
	​

(ρ)S
soft
	​

v.
	​

(3)

Require its coefficients through the regularized constant and the first positive power of ρ to vanish. If H
⊥
	​

 has pole order m, construct the Frobenius jets through at least m+1.

Equivalently, include the inverse endpoint transformation and test the commutative square

T
25
	​

U
H
	​

Φ
G
	​

S
soft
	​

v=Ψ
phys
	​

v+O(ρ).
	​

(4)

This single small test detects both requested defects:

omitting the first Frobenius jet leaves the H
−1
	​

P
1
	​

 or Q
1
	​

H
−1
	​

 contribution unmatched at ρ
0
;

applying the target extension H
⊥
	​

 twice gives a nonzero source-to-target mismatch in (4).

It uses only compact truncated jets at one generic finite-field image; it does not require a dense symbolic connection or a new production certificate.

Immediate execution order

Construct the tangential columns (p-word,Π
α
	​

,n).

Map them to the exact physical soft-mode basis.

Apply the regularized endpoint transformation (1), including the required first Frobenius jet.

Feed the resulting selectors to the normal operator rebased to the inward tangent at u=2p.

Apply F
25
	​

=G
25
	​

+H
⊥
	​

F
S
	​

, then T
25
	​

, only at the final point.

Store the result as sparse coefficients indexed by

(n,w
p
	​

,w
z
	​

,Π
α
	​

).

Run the single endpoint intertwining-jet control before the overnight campaign.

The boundary periods and their numerical values may remain inert until Stage 3. The regularized endpoint mode map, by contrast, is part of the exact physical transport and cannot be deferred.
