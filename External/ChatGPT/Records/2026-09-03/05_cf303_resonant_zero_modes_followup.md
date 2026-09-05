# CF303 Resonant Zero Modes Followup

## Question

# CF303 follow-up: resonant inherited zero modes at the soft junction

Please continue the established **Assess Multiquadratic Pipeline** analysis. We implemented the regularized-junction route from your preceding reply and have now reached a precise resonance issue. We need a mathematically decisive answer, not additional defensive certification.

Current facts, all from the accepted CF303 artifacts and fresh modular evaluations:

- Normal coordinate: `rho = 2 p - u -> 0+`; final relation is `I25 = T25 (G25 + H F_source)`.
- We project the normal endpoint problem onto six CF303-owned modes plus seven inherited lower-family source modes. Only seven inherited source coordinates survive in `[T25 H,T25]`.
- For the seven inherited modes, the full 16-sheet modular orbit cancels to the rational component. Their projected rational functions in `p` interpolate at degree cap 204; exact coefficient lifting is now proceeding by multi-prime CRT.
- Three inherited modes have nonzero normal-residue eigenvalues and their leading target-G columns follow from the nonresonant relation `g = B_{-1} v/(lambda eps)`.
- Four inherited modes have source eigenvalue zero but `B_{-1} v != 0`. They therefore generate generalized/logarithmic target chains. Their finite target-G `rho^0` normalization is not fixed by division by an eigenvalue or by the connection recurrence alone.
- `CF303InheritedObservableExtensions` and `CF303InheritedLowerSoftJets` contain only lower-family `F_source` rows/jets/period words. They do not contain physical `I44,I45` endpoint columns.
- `CF303PhysicalSoftSixSystem` gives the exact local six-row differential system; `CF303SixModeEndpointFrame` gives five zero modes plus the `rho^{-2-4 eps}` mode, the accepted `T25` gauge, and tangential evolution, but no evaluated physical target boundary constants.
- The two target homogeneous zero modes already occur among the six owned CF303 modes. Consequently, a finite shift of a resonant inherited particular solution might merely redefine those independent homogeneous constants. We need to know whether this makes a canonical choice (for example zero finite part in a specified Levelt gauge) mathematically sufficient, or whether the physical master-integral normalization fixes an additional datum that must be computed by regions/direct boundary integration.

Please answer concretely:

1. In a block-triangular regular-singular system with resonant source zero mode `v`, target block with zero modes, and `B_{-1}v != 0`, is the finite `rho^0` part of a particular target solution physically new data, or is its ambiguity exactly a linear combination of target homogeneous zero modes already carrying independent boundary constants?
2. If it is absorbable, give the clean canonical Levelt/variation-of-constants prescription that sets the finite particular part and explain how the boundary-period basis must be transformed so the full physical solution is unchanged. State what must be recorded in the transport artifact.
3. If it is not absorbable here, identify the minimum additional physical input needed for `I44,I45`: which expansion-by-regions coefficient or endpoint integral/jump data, at what rho and epsilon orders, and whether it can be reduced to the existing lower-family periods.
4. For either answer, give the exact small `rho^0,rho^1` intertwining/ODE test that distinguishes a legitimate resonant normalization from an omitted logarithmic term. We accept finite-field evaluation at fresh modular points; no giant symbolic identity is desired.
5. Does the paper-level transported result remain a finite sum indexed by `(epsilon order, p-word, normal-word, PeriodID)` if these resonant chains introduce powers of `log rho`? Give the minimal extra index/letter convention.

Please explicitly separate: (a) determined logarithmic coefficients, (b) arbitrary homogeneous shifts, and (c) genuinely new physical boundary data.

## Pro response

Verdict: GO — choose the zero-finite-part Levelt convention

For a resonant inherited source zero mode, the logarithmic target coefficient is fixed by the residue. The finite ρ
0
 part of the associated particular solution is not a new independent physical period: its ambiguity is exactly a linear combination of the two target homogeneous zero modes already present in the six-mode system.

The physical calculation still needs the two target homogeneous period series unless topology or regions eliminate them. What it does not need is one additional period for each resonant inherited mode.

This remains a localized endpoint issue in the exceptional CF303 sector, rather than a new obstruction for the general pipeline. 

Pasted markdown

 The compact provider-backed treatment is also the correct computational level: the composed functions are cheap to evaluate, while expanded symbolic representations were the measured bottleneck. 

11_reconstruct_dont_simplify

 

08_three_root_slowdown_and_reco…

1. Determined logarithms versus arbitrary finite parts

Let V
0
	​

 be a matrix whose columns are the relevant inherited source zero modes,

R
S
	​

V
0
	​

=0,

and let

C(p,ϵ)=B
−1
	​

(p,ϵ)V
0
	​


be the 2×m residue map into the two target rows. Here B
−1
	​

 denotes the coefficient of dρ/ρ, not an epsilon Laurent coefficient.

On the corresponding zero-eigenvalue sector, the full normal residue is

R
0
	​

=(
0
C
	​

0
0
	​

),R
0
2
	​

=0.

Therefore

ρ
R
0
	​

=(
I
Clogρ
	​

0
I
	​

).

For source-period coefficients a, the target logarithm is exactly

C(p,ϵ)alogρ.
	​


This part is completely determined by the inherited source periods and the soft residue.

A general particular solution may instead contain

Calogρ+K(p,ϵ)a

in the target rows, for an arbitrary 2×m matrix K. But Ka is a target zero-mode solution. If b
T
	​

 denotes the two target homogeneous constants, then

Calogρ+Ka+b
T
	​

=Calogρ+
b
T
	​

,
b
T
	​

=b
T
	​

+Ka.

Hence:

finite resonant particular ambiguity=target homogeneous-period redefinition.
	​


Four inherited columns satisfying B
−1
	​

v

=0 do not imply four Jordan chains. The number of independent length-two chains is

r=rank(B
−1
	​

V
0
	​

)≤2.
	​

Separation of the three kinds of data
Quantity	Status
Ca, the coefficient of logρ	Determined by the residue and inherited periods
Ka, the finite part assigned to the particular solution	Convention-dependent; absorbable into target zero modes
The two target homogeneous coefficients b
T
	​

	Genuine physical boundary data unless regions constrain them

The physical target components I
44
	​

,I
45
	​

 may still have determined finite contributions from T
25
	​

, the path gauge, and the regular Frobenius prefactor. “Set the finite particular part to zero” refers to the regularized G-basis Levelt coordinate, not to setting the raw physical ρ
0
 coefficient of I
44
	​

,I
45
	​

 to zero.

2. Canonical Levelt prescription

Use the normalized Frobenius factor

P(ρ,p,ϵ)=I+P
1
	​

(p,ϵ)ρ+⋯,P(0,p,ϵ)=I.

Choose the generalized source columns to have zero target projection at ρ
0
:

V
0
	​

=(
V
0
	​

0
	​

).

The canonical local columns are then

Ψ
src
	​

(ρ)=P(ρ)[
V
0
	​

+(
0
C
	​

)logρ].
	​

(1)

The two pure target columns are

Ψ
T
	​

(ρ)=P(ρ)(
0
I
2
	​

	​

).
	​

(2)

Equivalently, in variation-of-constants language, define

Reg∫
0
ρ
	​

t
Cdt
	​

=Clogρ

with zero regularized constant. This is the cleanest convention.

The residue is rational in epsilon rather than proportional to epsilon, so this is a generalized Levelt construction with

ρ
R(p,ϵ)
,

not the ordinary package form ρ
ϵR
. On the resonant zero sector, however, the exact expression above already solves the problem; no full symbolic 45×45 Jordan decomposition is needed.

Changing the finite-part convention

If another convention uses K

=0, define

U
K
	​

=(
I
K
	​

0
I
2
	​

	​

).

Its local basis is

Φ
K
	​

=Φ
0
	​

U
K
	​

.

The boundary coefficients must transform as

a
K
	​

=a
0
	​

,b
T,0
	​

=Ka
K
	​

+b
T,K
	​

.
	​

(3)

Thus the complete physical solution is unchanged.

If K depends on p, the tangential boundary connection must also transform:

Γ
K
	​

=U
K
−1
	​

Γ
0
	​

U
K
	​

−U
K
−1
	​

∂
p
	​

U
K
	​

.
	​

(4)

Choosing K=0 globally avoids introducing an arbitrary p-dependent boundary-basis gauge.

What the transport artifact should record

The endpoint selector deck should retain:

the ordered source zero-mode basis V
0
	​

;

the target homogeneous basis;

the residue map C=B
−1
	​

V
0
	​

;

r=rankC;

the canonical convention FinitePartMatrix -> 0;

the generalized-chain map from source PeriodIDs to target log directions;

the two target homogeneous PeriodIDs;

the Frobenius jets needed by the endpoint gauge;

the epsilon Laurent window of C;

the tangential connection in this same K=0 basis.

The generalized chains should not be assigned new independent PeriodIDs. They are determined actions of inherited period columns.

3. What physical information is still missing

Because the ambiguity is absorbable, no additional region coefficient is required merely to normalize each resonant inherited particular solution.

The genuinely missing physical information is the pair of regularized target constants

Π
T
	​

(p,ϵ)=(
Π
44
	​

(p,ϵ)
Π
45
	​

(p,ϵ)
	​

)

in the declared K=0 Levelt gauge, subject to any relations from topology or regions.

They are defined by:

undoing T
25
	​

 and the normal path gauge;

stripping the integer powers and nonzero epsilon exponents;

subtracting the determined inherited-source logarithms Calogρ;

taking the regularized ρ
0
(logρ)
0
 target coefficient.

Schematically,

Π
T
	​

=P
T
	​

Reg
ρ=0
	​

[ρ
−R
P(ρ)
−1
F
local
	​

(ρ)],
	​

(5)

where P
T
	​

 projects onto the two target homogeneous coordinates.

Minimum Stage-3 input

Stage 3 must provide either:

the two target boundary-integral series; or

the two independent ρ
0
(logρ)
0
 region coefficients after subtracting the known inherited logarithmic part.

Only the epsilon orders demanded by the existing final convolution are needed. For pure target zero modes, the incoming-edge valuation does not enlarge that window: with T
25
	​

 beginning at epsilon order zero, the target periods are needed from their actual leading epsilon order through order 2.

The source-induced log coefficients and any finite terms generated by the accepted endpoint gauges are reducible to the already named lower-family periods. The remaining target homogeneous constants are not reducible to lower-family periods from residue algebra alone. A boundary IBP relation, a vanishing region, or a direct endpoint integral could reduce or eliminate them, but that is topology/region input.

4. Minimal ρ
0
,ρ
1
 control

Let the local connection be

A(ρ)=
ρ
R
	​

+A
0
	​

+O(ρ),

and let

P(ρ)=I+ρP
1
	​

+O(ρ
2
).

For the resonant source basis, define

V
=(
V
0
	​

0
	​

),E=(
0
I
2
	​

	​

),C=B
−1
	​

V
0
	​

.

The canonical truncated columns are

Ψ
0
	​

(ρ)=(I+ρP
1
	​

)(
V
+EClogρ).
	​

(6)

At one fresh modular (p,ϵ) point, check the coefficients of

(∂
ρ
	​

−A(ρ))Ψ
0
	​


at

ρ
−1
(logρ)
0
,ρ
0
(logρ)
0
,ρ
0
(logρ)
1
.

They must vanish. An omitted logarithmic term leaves the unmistakable leading residual

−
ρ
EC
	​

.

To test a shifted finite convention K, form

Ψ
K
	​

(ρ)=(I+ρP
1
	​

)(
V
+EK+EClogρ),

and verify through ρ
1
, separately for (logρ)
0
 and (logρ)
1
,

Ψ
K
	​

−Ψ
0
	​

−Ψ
T
	​

K=0,Ψ
T
	​

=(I+ρP
1
	​

)E.
	​

(7)

Finally verify the coefficient transformation (3) on one generic formal period vector.

These two checks distinguish the issues cleanly:

the ODE residual detects a missing or incorrectly normalized logarithm;

equation (7) confirms that a finite shift is a legitimate target homogeneous redefinition.

The ODE alone cannot reject a finite shift, because such a shift is genuinely a homogeneous solution.

5. Paper-facing word convention

The result remains a finite sum at every fixed epsilon order:

[I
i
	​

]
ϵ
n
	​

=
α,w
p
	​

,w
ρ
	​

,j
∑
	​

C
i;α,w
p
	​

,w
ρ
	​

,j
(n)
	​

G
p
	​

(w
p
	​

)E
ρ
	​

(w
ρ
	​

)
j!
log
j
ρ
	​

Π
α
	​

.

For the zero-residue chains discussed here,

j∈{0,1},

because R
0
2
	​

=0.

There are two equivalent conventions:

Endpoint-letter convention: include dρ/ρ as a normal-word letter. The chain logarithm is one occurrence of that letter, and no extra index is needed.

Levelt-factor convention: keep the Frobenius logarithms outside the Chen words and add

JordanLevel -> 0 | 1

to the coefficient key.

Use one convention only. Since the existing normal operator is tangentially regularized, the endpoint-letter convention is likely the smaller integration change. If the endpoint singular factor is already external to that operator, retain JordanLevel instead.

The authoritative ancillary should remain compact. The project’s deferred architecture already treats additive leaves and algebraic channels without materializing the complete expression, which is the appropriate pattern here as well. 

codex_overnight_optimization_tr…

Final classification
Category	CF303 resonant inherited zero modes
Determined	B
−1
	​

V
0
	​

Π
S
	​

, the coefficients of the target logρ terms
Convention-dependent	The finite target part assigned to each inherited particular solution; encoded by K
Absorbable into existing constants	Yes, through b
T
	​

↦b
T
	​

+KΠ
S
	​


Genuinely new physical data	At most the two target homogeneous period series, reduced further only by region/topology constraints
Number of generalized chains	rank(B
−1
	​

V
0
	​

)≤2, not the count of nonzero inherited columns
Recommended convention	K=0: zero regularized finite target projection for inherited generalized columns

Immediate action: adopt K=0, keep the two target homogeneous period columns in the Stage-3 ledger, and run the compact tests (6)–(7). Do not introduce four additional resonant period functions.
