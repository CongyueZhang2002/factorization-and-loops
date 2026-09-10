# Multiple unobserved-gluon state sums

Verified outgoing model: gpt-6-pro, HTTP 200. Request: e593bd50-3268-4036-9de5-8aa23cf752ed.

## Question

Follow-up before connecting the generated current amplitudes to NNLO RR. The joint angular moment primitive now passes 11 checks, including correlated rank-two moments, degrees 1–4 against the one-vector Beta rule, and a positive-dimensional explicit angular integral. Its Gram system is reduced to integer-partition orbits, so degree four needs only a 5-by-5 symbolic system. Recursive massless phase-space volumes/measured light-cone-fraction densities pass ten normalization and moment checks.

An independent LL qg NLO run exposed and fixed a separate endpoint bug: an epsilon-only Laurent helper was incorrectly reused for a coordinate valuation and renamed epsilon to the coordinate. The epsilon-suppressed endpoint term was lost. A direct rational coordinate valuation fixes it, all poles now cancel, and a synthetic (z+eps)/eps*z^(-1-eps) distribution-moment regression passes. We are auditing the previously finished NLO coefficients. Drell–Yan NLO is complete for all six channels, all finite/epsilon-one coefficients match arXiv:1307.6925 exactly.

One nontrivial decision remains in the RR current frontend: sums over multiple unobserved gluons. Current NLO frontend uses normalized physical incoming-gluon PDF/observed-gluon FF projectors, and -g_D for a single unobserved gluon. This is validated. At RR q+gamma* -> observed q + g+g there are TWO unobserved gluons, so using two covariant sums without the corresponding ghost completion is unsafe. The old hadronic scattering path explicitly includes ghost components and passes complete INCNLO UU checks; its Real cards use AssemblyWeight 1/2 for two identical unobserved gluons and -1 for an unobserved ghost-antighost state. The current amplitude frontend has not yet been extended/tested for ghosts.

Please review a mathematically precise general implementation:
1. For two unobserved gluons with all other colored external legs physically projected, derive the covariant-gluon plus ghost replacement including symmetry factors, conjugation/order of the ghost and antighost momenta, and color/spin sums. Is one -1 times the generated ghost-antighost interference sufficient after the gg factor1/2, or must the conjugate ghost amplitude have exchanged ghost labels? Distinguish the ghost contribution already implicit in FeynArts diagram rules from the cut/statistics sign.
2. Is it cleaner/faster for this campaign to use explicit physical D-dimensional polarization sums for each unobserved gluon, with a fixed physical timelike reference P=p+q, rather than add ghost states? That gives denominators P.k_i (positive away from soft faces) and possibly squared gauge denominators, increasing the scalar denominator inventory. Please compare this against covariant+ghost sums in a shared IBP basis.
3. Give two cheap independent checks that do not import any published amplitude or hard coefficient: e.g. gauge-reference changes or the exact difference between physical and covariant sums plus generated ghosts at rational kinematics/epsilon, retaining integrated D-dimensional final momenta. Explain which equalities hold only after integrating the unobserved momenta and which hold pointwise.
4. We will add a per-card state-sum convention and require complete ghost-state coverage if that route is selected; unobserved ghosts must never enter PDFs/FFs or physical flavor sums. Any additional NNLO-only traps with an observed gluon and one/two other gluons?

Repo https://github.com/CongyueZhang2002/factorization-and-loops, latest edits local. Please review the general workflow, not a tuned coefficient.

## Pro response

Your warning is correct. For the particular tree process q+γ
∗
→q+gg, the weights 1/2 for the gluon state and −1 for one ghost–antighost state can be correct. But the general construction is an ordered ghost-line interference, not automatically a negative squared amplitude. The current frontend should either implement that pairing explicitly or use physical polarization sums until the corresponding generated identity has been established.

There is also a useful intermediate option: keep one unobserved gluon physically projected and use −g
D
	​

 for the other. With all remaining colored legs physically projected, this requires no external ghosts and introduces fewer gauge denominators than two physical sums.

1. Exact two-gluon completion
1.1 Start from a convention-independent identity

Let

M
αβ
μ,ab
	​

(k
2
	​

,k
3
	​

)

be the complete amplitude with the two unobserved gluon polarization vectors removed. The current index is μ; the gluon colors a,b remain associated with momentum slots k
2
	​

,k
3
	​

. All other colored external states are on shell and physically projected.

For a chosen Hermitian current projection and incoming density, write the remaining bilinear as

B(A,B)=
remaining states
∑
	​

P
μν
	​

A
μ∗
B
ν
,B(A,B)
∗
=B(B,A).

This notation applies to UU and LL. In LL it need not be positive.

The relevant on-shell Slavnov–Taylor identities have the form

k
2
α
	​

M
αβ
μ
	​

=k
3β
	​

U
μ
,k
3
β
	​

M
αβ
μ
	​

=k
2α
	​

V
μ
.
	​


Here U,V are the two oriented ghost-line amplitudes, with their conventions fixed by these identities. The double contraction vanishes, but a single unprojected contraction generally does not. This is the distinction from the unrestricted QED Ward identity. 
Eldorado Repository

Define

C
i
αβ
	​

=−g
D
αβ
	​

,

and

d
i
αβ
	​

=C
i
αβ
	​

+k
i
α
	​

b
i
β
	​

+b
i
α
	​

k
i
β
	​

,b
i
α
	​

=
k
i
	​

⋅n
i
	​

n
i
α
	​

	​

−
2(k
i
	​

⋅n
i
	​

)
2
n
i
2
	​

k
i
α
	​

	​

.

Since k
i
2
	​

=0,

k
i
	​

⋅b
i
	​

=1.

Let Σ
XY
	​

 denote the complete scalar density obtained using X for gluon 2 and Y for gluon 3. Expanding the projectors and applying the two identities gives

Σ
dd
	​

=Σ
CC
	​

−B(U,V)−B(V,U).
	​


The two single-projector corrections each contribute
−[B(U,V)+B(V,U)]; the double correction contributes one copy with the opposite sign. This derivation works for timelike as well as null admissible references.

With the usual labeled phase space for two identical unobserved gluons,

2
1
	​

Σ
dd
	​

=
2
1
	​

Σ
CC
	​

−ReB(U,V).
	​

(1)

Equation (1) is the safest normalization statement. It neither assumes that U=V nor depends on a guess about how a diagram generator orders external ghosts.

1.2 How this appears with outgoing ghost and antighost labels

Define two outgoing-state amplitudes at the same momentum/color slots:

G
+
ab
	​

=A(…→c
a
(k
2
	​

)
c
ˉ
b
(k
3
	​

)),
G
−
ab
	​

=A(…→
c
ˉ
a
(k
2
	​

)c
b
(k
3
	​

)).

In the ordered outgoing-ghost convention where

G
+
	​

=U,G
−
	​

=−V,

equation (1) becomes

2
1
	​

Σ
dd
	​

=
2
1
	​

Σ
CC
	​

+
2
1
	​

[B(G
+
	​

,G
−
	​

)+B(G
−
	​

,G
+
	​

)].
	​

(2)

The conjugate side therefore involves the ghost–antighost exchanged state, not automatically the same state. This cross-pairing is what follows from cutting an oriented ghost line. The literature explicitly demonstrates that replacing such cross terms universally by signed absolute squares fails once additional covariantly summed gluon slots are present. 
arXiv

The distinction between operations is important:

Exchanging c↔
c
ˉ
 while keeping k
2
	​

,a and k
3
	​

,b fixed produces G
−
	​

.

Reordering the external list to put the ghost first also permutes momenta and colors and carries the corresponding Grassmann-order sign.

Complex conjugation of the scalar expression alone performs neither operation.

The diagram adapter must map its external-field convention to this ordered cut convention. Do not independently choose overall signs for G
+
	​

 and G
−
	​

: their squares are insensitive to those signs, but their interference is not.

1.3 Why a single −1 ghost square works for the stated SIDIS tree channel

At order eg
s
2
	​

, the ghost pair in

q+γ
∗
→q+c+
c
ˉ

attaches through a single ghost–ghost–gluon vertex to the quark current emitting an off-shell gluon with

K=k
2
	​

+k
3
	​

.

Let J
C
μρ
	​

 be that generated quark current, including both possible photon attachments on the quark line. The Dirac equations and the sum of those attachments give

K
ρ
	​

J
C
μρ
	​

=0.
	​


This holds with the outgoing quark momentum fully D-dimensional and with the photon current off shell.

The two oriented ghost-line amplitudes are proportional, with a common convention-dependent overall phase, to

U
μ
∝f
abC
K
2
k
2ρ
	​

J
C
μρ
	​

	​

,V
μ
∝−f
abC
K
2
k
3ρ
	​

J
C
μρ
	​

	​

.

Consequently,

U=V,

or equivalently G
−
	​

=−G
+
	​

 in the outgoing-state convention above. Thus

2
1
	​

Σ
dd
	​

=
2
1
	​

Σ
CC
	​

−B(G
+
	​

,G
+
	​

).
	​

(3)

For this channel, one ghost–antighost contribution of weight −1 is therefore sufficient once the generator’s ordering convention has been mapped correctly. The equality is pointwise on the on-shell phase space, not merely an identity after integrating the unobserved momenta. It applies after summing the relevant diagrams, not to each photon-attachment diagram individually.

This is a useful exact generated test of the shortcut. It should not be promoted to a universal rule based only on counting ghost pairs.

1.4 Symmetry, color, spin, and cut signs

In the labeled phase-space convention:

gg:
2!
1
	​

,c
c
ˉ
:1.

The ghost and antighost are distinguishable. Once equation (3) is used, do not add a second 
c
ˉ
c channel with another weight −1: that would double the subtraction. In equation (2), the two orientations instead occur explicitly with the displayed 1/2 and Hermitian pairing.

Each ghost cut carries the ordinary massless positive-energy measure. There is no ghost spin sum, no D−2 multiplicity, no outgoing spin/color average, and no flavor multiplicity. Sum its adjoint color index normally. The negative contribution is a statistics/state-metric effect, not a negative-energy cut.

FeynArts already supplies model vertex signs, propagator phases, and its diagram-level Grassmann signs, including minus signs for closed ghost loops. A tree amplitude with an open external ghost line does not contain the additional closed Grassmann cycle formed when the two sides are sewn across the cut. That sewing information belongs to the state-sum layer. 
FeynArts

One can describe the same sewing either as a minus sign multiplying oppositely oriented cut amplitudes, or as the exchanged outgoing-state pairing in equation (2). Do not apply both prescriptions as independent signs.

FeynArts also documents that external ordering affects amplitude signs. Retain those signs explicitly while establishing the ghost adapter; do not infer relative ghost phases from absolute squares. 
FeynCalc

The public assembly helper currently computes a sign from the number of outgoing ghosts alone. Treat that as a restricted, validated diagonal convention—not as the general definition of a ghost-state metric. This observation concerns the public version, not your local edits.

2. Physical sums versus covariant sums plus ghosts
2.1 A timelike reference P=p+q is legitimate

For each unobserved massless gluon,

d
D
αβ
	​

(k
i
	​

,P)=−g
D
αβ
	​

+
P⋅k
i
	​

k
i
α
	​

P
β
+P
α
k
i
β
	​

	​

−
(P⋅k
i
	​

)
2
P
2
k
i
α
	​

k
i
β
	​

	​

.
	​


The final term is mandatory because P
2
=s
X
	​

>0. This is a physical D−2-state sum, not an average. FeynCalc supports the corresponding general-reference tensor and its D-dimensional version. 
FeynCalc

In the rest frame of P,

P⋅k
i
	​

=
s
X
	​

	​

E
i
	​

>0

away from a soft face. For three massless final momenta,

2P⋅k
i
	​

=s
ij
	​

+s
ik
	​

.

Thus this reference avoids a spurious zero at an ordinary finite-energy collinear configuration. It is generally safer for a phase-space integrand than a null beam reference whose dot product can vanish on a beam-collinear surface.

All components of k
i
	​

, including the hatted components, must occur in the projector. Choosing P physical does not make k
i
	​

 physical four-dimensional.

Since P∈span{p,q}, the denominators P⋅k
i
	​

 are invariant under your joint transverse rotations. The angular-moment primitive remains applicable.

2.2 A cheaper ghost-free option: one physical, one covariant

With every other colored external leg physically projected,

Σ
dC
	​

=Σ
dd
	​

,Σ
Cd
	​

=Σ
dd
	​

.
	​

(4)

For example, when gluon 2 is physical, replacing the sum on gluon 3 by −g
D
	​

 changes it only by terms containing

k
3
β
	​

M
αβ
	​

.

That is proportional to k
2α
	​

, which is annihilated by the physical projector on gluon 2.

Equation (4) holds pointwise. It does not authorize replacing the remaining physical projector too. That second replacement is precisely where the ghost correction becomes necessary.

For a general card, a valid hybrid policy is therefore:

Keep all factorized gluon legs physical; among unobserved gluons, permit at most one covariant sum unless ghost completion is explicitly enabled.

This requires no new ghost amplitude support and only one timelike-reference projector in the two-unobserved-gluon case.

2.3 Which route is likely to be faster?
State sum	Main implementation advantage	Main symbolic cost
Two physical sums	No external-ghost ordering machinery	Two projector expansions and potentially squared P⋅k
i
	​

 denominators
One physical, one covariant	No ghosts; smaller projector expansion	One reference-dependent intermediate
Two covariant sums plus ordered ghost completion	Compact numerator contractions; no polarization-reference denominators	Additional ghost amplitudes and a correct non-diagonal state-pairing interface

For this specific tree channel, the ghost amplitudes are structurally simpler than the full qgg amplitudes. Their propagators are drawn from the same parent-gluon/quark structures already present in the physical process. They therefore offer a strong prospect of keeping the scalar-family inventory smaller.

That is not a measured timing conclusion. The actual cost depends on how much reference-denominator cancellation your rational simplifier can accomplish before family construction.

For immediate frontend validation, the hybrid route is the lowest-risk extension. For compact production integrands, covariant plus correctly paired ghosts is a sensible target. Keep the physical or hybrid route as the independent state-sum check.

Do not send the expanded physical-projector denominators directly to Kira without first combining the complete scalar density. The physical answer is reference-independent, so many apparent gauge denominators can cancel before IBP. The Ward contractions U,V also provide a direct algebraic way to expose that cancellation.

The denominators introduced by a polarization reference are algebraic gauge factors, not new Feynman propagators with independently chosen causal prescriptions. Nor does selecting these external projectors change the gauge of internal propagators. Internal ghost diagrams remain required wherever the chosen loop formulation requires them.

At x→1, P
2
→0 and the real-emission geometry degenerates. Establish state-sum equivalence at finite ϵ on the open physical chamber and retain the complete expression through endpoint assembly. Do not interpret positivity at interior points as a uniform lower bound at unresolved endpoints.

3. Two independent checks before integration
Check A: physical/hybrid equality and reference changes, without ghosts

Generate the complete qγ
∗
→qgg current amplitude and compare

Σ
d(P)d(P)
	​

,Σ
d(P)C
	​

,Σ
Cd(P)
	​

.

Also replace a physical reference by

P
λ
	​

=P+λp,λ>0.

It remains future timelike because

P
λ
2
	​

=P
2
+2λP⋅p>0.

All these complete densities must agree pointwise, for each declared UU/LL projection. The corresponding economical amplitude check is

k
2
α
	​

M
αβ
	​

d
3
βγ
	​

=0,

and the exchanged identity. Do not demand the generally false unprojected identity
k
2
α
	​

M
αβ
	​

=0.

Retain nonzero hatted final-state components. An explicit rational on-shell configuration in, for example, D=6 is useful; a purely four-dimensional configuration would not test evanescent terms. Alternatively, reduce the tensor expressions to consistent full/hatted Gram invariants and retain symbolic D.

Exact evaluation at rational kinematics is a strong diagnostic, but a finite collection of zero residuals is not a proof for all kinematics. The tree-level identities can be established as rational identities after applying the exact on-shell, momentum-conservation, and color relations—without any integration or IBP.

Check B: ordered ghost completion against the physical density

Generate G
+
	​

 and G
−
	​

 independently with the same current and physical spectator projectors, retaining their external-order signs. Test

E=Σ
dd
	​

−Σ
CC
	​

−B(G
+
	​

,G
−
	​

)−B(G
−
	​

,G
+
	​

)=0
	​


in the outgoing-state convention of equation (2).

For this channel, additionally establish the generated identity

G
−
	​

+G
+
	​

=0

after the exact convention map. Then test the diagonal form

Σ
dd
	​

−Σ
CC
	​

+2B(G
+
	​

,G
+
	​

)=0.

This separately verifies the negative-square shortcut instead of assuming it in the comparison.

The parent-current identity

K
ρ
	​

J
C
μρ
	​

=0

is a particularly cheap way to check why the two orientations coincide in the cut convention. None of these tests needs a published amplitude or hard coefficient.

For g
1
	​

, apply the Hermitian current projector before taking scalar real parts, or retain the Hermitian current tensor throughout. Componentwise real-part projection of an open current tensor would erase the relevant antisymmetric contribution.

Pointwise versus integrated statements

The following hold pointwise after the complete diagram sum and on-shell constraints:

Σ
dd
	​

 is reference-independent,Σ
dC
	​

=Σ
dd
	​

,

and the correctly paired covariant-plus-ghost identity.

By contrast, collapsing several equivalent tag assignments or ghost momentum assignments to one representative may rely on changing integration variables. That step requires the measure and measurement to transform with the permutation.

For an observed quark, the measurement is independent of which unobserved slot is called 2 or 3, so k
2
	​

↔k
3
	​

 is an allowed unobserved permutation. This does not mean that an unsymmetrized, potentially complex ghost cross term equals its Hermitian completion pointwise. Keep the explicit Hermitian combination unless the stronger identity has been established.

4. State-sum architecture and observed-gluon traps
4.1 Store the paired states, not just an integer weight

A proposed state-sum component needs information of the following kind:

Wolfram Language
<|
  "PhysicalSlots" -> {...},
  "CovariantGluonSlots" -> {...},
  "AmplitudeFields" -> {...},
  "ConjugateFields" -> {...},
  "CutSlotMatching" -> {...},
  "GhostOrderConvention" -> convention,
  "IdenticalParticleFactor" -> symmetryFactor,
  "StateMetricFactor" -> metricFactor
|>

The important property is that ConjugateFields may differ from AmplitudeFields by ghost–antighost exchange at fixed cut slots. A generic scalar-interference builder must not silently force them to be the same.

A certified diagonal reduction can then replace this pairing by the legacy −1 ghost square where justified. If more than two gluon slots are covariantly summed, reject the shortcut until all required ghost assignments and pairings are implemented. Even a term containing only one ghost pair can require a genuine cross term when other gluons remain covariantly summed. 
arXiv

4.2 Factorized gluon legs must really remain physical

Audit the actual tensor inserted, not the label “PDF projector” or “FF projector.” An earlier simplification

d
D
	​

(k,n)→−g
D
	​


that was safe when only one gluon was covariantly summed may become unsafe when reused in RR.

For this policy, incoming and tagged gluon legs retain their normalized physical projectors in every gluon and ghost component. No incoming ghosts are introduced, no ghost receives a PDF or FF, and no ghost is eligible for the physical tag sum.

The unobserved ghost momenta are still full-D integration momenta. Their derivative vertices use those full momenta; being spinless does not justify setting their hatted components to zero.

4.3 Count unobserved covariant slots after selecting the tag

For a physical final state containing m identical gluons, the inclusive tag prescription is

m!
1
	​

t=1
∑
m
	​

∫dΦM
t
	​

Σ
physical
	​

,

where M
t
	​

 denotes the measurement attached to gluon t. When all tag choices are related by exact relabeling, fixing one tag yields the residual factor

(m−1)!
1
	​

.

Thus, for a fixed observed gluon plus two unobserved gluons, the latter have factor 1/2!. Their ghost replacement has a fixed physical observed gluon and distinguishable unobserved c,
c
ˉ
, with factor one. Neither the tag nor the observed FF is moved to a ghost in the conjugate component.

For the actual electromagnetic SIDIS NNLO tree inventory, the qγ
∗
→qgg state has:

two unobserved gluons when the quark is tagged;

only one unobserved gluon when a gluon is tagged.

The latter needs no external ghost completion when the incoming and observed legs remain physical. Likewise, a generated γ
∗
g→q
q
ˉ
	​

g contribution has at most one unobserved gluon under the stated tagging choices. Do not infer extra ghost sectors merely from the total number of gluons appearing anywhere in the diagram.

4.4 Two additional safeguards

Do not impose transversality prematurely on a gluon intended for a covariant sum. Dropping terms proportional to k⋅ϵ before performing −g
D
	​

 contractions changes the unphysical-state contribution that the ghosts are meant to cancel. FeynCalc explicitly warns against this combination. 
FeynCalc

Use these identities on the original on-shell state sum before generating dotted-cut descendants. The statement that a numerator difference vanishes on unit mass-shell cuts does not authorize setting the same difference to zero against arbitrary delta derivatives. Subsequent IBP descendants must follow from the established unit-cut distribution with its normal information preserved.

Finally, the state-sum identities must survive at generic D, including regulator-suppressed endpoint terms. A finite helicity-PDF scheme conversion cannot repair an incorrect gluon/ghost completion, and cancellation only after discarding O(ϵ) terms would not be sufficient for RR.

The recommended implementation boundary is a general ordered state-sum layer, with the two-ghost diagonal shortcut admitted only by an exact identity. Use the hybrid physical/covariant route to validate the current frontend now; use covariant plus paired ghosts for production once that identity passes. Both routes should feed the same joint angular reduction, measured cut families, and master assembly.