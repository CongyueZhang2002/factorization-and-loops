# Current Workflow Evaluation

## Question

Please perform an adversarial technical review of our current implementation workflow for the three-root epsilon-form families, continuing the prior consultation in this conversation. The attached overnight report is the evidence ledger. I want a decisive assessment, not reassurance: identify mathematical errors, insufficient certificates, wasted tests, and the shortest safe route to a completed exact CF300/CF303/CF259 result.

Current state and workflow

1. CF300 production reached an exact, preserved 22x22 state after sector 11. The first 20 rows/columns were certified through sector 10. The new sector-11 2x2 diagonal block is already epsilon times an epsilon-independent matrix; the upper-right 20x2 block is zero. In both differential one-form components, every regulator-dependent lower-left entry (rows 21-22, columns 1-20) has the same scalar factor

   q(epsilon) = P(epsilon)/epsilon^2,
   P(epsilon) = -2+13 epsilon-27 epsilon^2+18 epsilon^3
              = (2 epsilon-1)(3 epsilon-1)(3 epsilon-2).

   We propose the epsilon-only block rescaling

   T = diag(I_20, t I_2),   t = q/epsilon = P/epsilon^3.

   With the package convention A_new = T^{-1} A T, this changes every lower-left q factor to epsilon, leaves the diagonal block unchanged, and introduces no dT term because T is independent of v,w. The bookkeeping is S_new=S T and SInverse_new=T^{-1}SInverse. A fail-closed driver is being prepared that reloads the immutable state, proves these statements entrywise in both components, checks exact inverse and propagation seals, and atomically writes a distinct continuation state. It will not modify package code or the original state.

2. We accelerated rational finite-field screening with a direct sparse assembler and FLINT RREF. Measured warm speedup is about 22x over legacy assembly, and compiled-artifact rebind is about 56x versus rebuilding. Release/sanitizer/differential/adversarial tests passed. Independent prime/epsilon images and exact fingerprints are used.

3. For the current CF300 sector-12 rational-gauge search, increasingly broad rational ansatzes are inconsistent. A0, added support, added letters, their union, a second anisotropic support shell, and the complete square-free denominator closure over the five absent factors all fail consistently across four modular images. The maximal square-free denominator screen had 1728 unknowns, rank 1716 versus augmented rank 1717, nullity 12. This excludes that finite rational search space, not a multiquadratic gauge. Remaining rational axes include repeated poles, genuinely new monomial support, and new one-forms.

4. We are now testing the faithful split-point multiquadratic method from your prior advice: all eight Galois sign orbits at each accepted base point, character/Walsh projection, independent primes/epsilon values, and exact lifting gates. The current Galois-orbit pilot is isolated in a dedicated Wolfram context with exact artifact fingerprints. A separate repeated-pole/local-resonance pilot is being designed. We have not claimed success from one chosen square-root embedding.

5. Runtime discipline: a single eight-subkernel pool is centrally brokered; jobs do not launch nested Wolfram kernels. One reused worker was accidentally contaminated by a test that put Locked/Protected definitions on Global`x,y,epsilon. Because Locked is irreversible in the live process, we did not attempt destructive cleanup or restart the user's pool. That worker is quarantined by a no-mutation heartbeat, leaving seven usable workers. All newer artifact hydration uses a dedicated exact symbol context and verifies Global remains unchanged. Existing long jobs are source-pinned and are never killed.

6. In-package changes already made are confined to tested performance/resume paths and respect Fable's formats. Current live exploratory drivers write only to External exchange or temporary files. Known package/control-plane issues are recorded separately: target-level Return can escape the pool wrapper; compiled-artifact loading hardcodes Global and has context-sensitive fingerprints; Quiet[Check[Get,...]] can discard a valid value after a benign message; tests must never Lock shared symbols.

Please answer these questions explicitly.

A. Is the scalar CF300 regulator rescaling mathematically complete under the stated block structure and orientation? List every exact condition the continuation driver must check, including any issue caused by t having epsilon poles/zeros, transformation invertibility, future-sector propagation, or canonical-form normalization conventions. Is this a legitimate solution of the regulator-factorization stop, or merely a local cosmetic rewrite?

B. After that rescaling certifies, should we immediately resume sector 12, or first run another independent certificate on the 22x22 prefix? Specify the minimum acceptance certificate and the strongest cheap adversarial test.

C. Critique the finite-field search order. Given that the complete square-free denominator closure and two support shells fail, rank repeated poles, new one-forms, larger numerator support, all-eight-sign multiquadratic coefficients, direct exact algebraic solving, and pure-basis/leading-singularity information by expected value. State when continued rational ansatz expansion becomes unjustified.

D. For the all-eight-sign pilot, give a concrete fail-closed validation checklist. In particular, explain how to distinguish a genuine multiquadratic solution from an interpolation/sign-labeling artifact and how many independent primes, points, and characteristic-zero spot checks are minimally persuasive before production promotion.

E. Evaluate the runtime/testing architecture. Is the dedicated-context + immutable-artifact + hash/rebind strategy sound? What additional isolation is needed? Is quarantining one poisoned worker while preserving unrelated live jobs the correct response?

F. Give a revised ordered plan for the next 12-24 hours with sharp stop/continue criteria for CF300, then CF303 and CF259. Separate tasks that can safely run in parallel from those that depend on the new CF300 state. Identify any tests in the attached report that are redundant or give weaker assurance than we currently attribute to them.

End with a short verdict table: current decision, confidence, main risk, and next mandatory certificate for (i) the analytic regulator rescaling, (ii) rational finite-field optimization, (iii) multiquadratic Galois-orbit solving, (iv) package promotion, and (v) pooled runtime safety.

## Pro response

Overall assessment

The report is correctly labeled in progress, not a certification of CF300 or the other three-root families. 

codex_overnight_optimization_tr…

The decisive conclusions are:

The proposed CF300 scalar rescaling is mathematically valid for the 22-by-22 prefix, subject to a small number of exact conditions. It is a genuine regulator-factorization step, not merely cosmetic.

Do not reuse the current sector-12 ansatz exclusions without recapturing the sector-12 inputs from the rescaled state. The rescaling changes the basis seen by future sectors, so previous affine systems are not automatically equivalent.

Stop blind rational-ansatz expansion now. MAX5 and the second support shell have already shown that the missing direction is not another square-free denominator subset or nearby numerator shell.

Use direct multiquadratic grade arithmetic as the production representation. Use all-eight split signs as an independent oracle. The report has already eliminated the need for residue-only sampling in the main assembler. 

codex_overnight_optimization_tr…

The package is not ready for promotion. The mathematics can proceed through the hardened external continuation driver, but the target-level Return, hardcoded-Global loader, and reused-kernel isolation issues remain production blockers.

Quarantining the poisoned worker was the correct immediate response. It is containment, not remediation; that kernel must eventually be restarted under controlled conditions.

A. CF300 scalar regulator rescaling

Write each differential component, μ=v,w, in the stated block form

A
μ
	​

=
	​

A
μ
(0)
	​

A
μ
(10)
	​

	​

A
μ
(01)
	​

A
μ
(1)
	​

	​

	​

,

with block sizes 20+2. The proposed transformation is

T=diag(I
20
	​

,tI
2
	​

),t=
ϵ
q(ϵ)
	​

=
ϵ
3
P(ϵ)
	​

,
P(ϵ)=(2ϵ−1)(3ϵ−1)(3ϵ−2).

Under the convention

A
μ
new
	​

=T
−1
A
μ
	​

T

one obtains

A
μ
new
	​

=
	​

A
μ
(0)
	​

t
−1
A
μ
(10)
	​

	​

tA
μ
(01)
	​

A
μ
(1)
	​

	​

	​

.

Therefore, if

A
μ
(01)
	​

=0,A
μ
(10)
	​

=q(ϵ)B
μ
	​

,

then

t
−1
A
μ
(10)
	​

=
q
ϵ
	​

qB
μ
	​

=ϵB
μ
	​

.

If additionally

A
μ
(0)
	​

=ϵΩ
μ
(0)
	​

,A
μ
(1)
	​

=ϵΩ
μ
(1)
	​

,

with all three Ω
μ
(0)
	​

,Ω
μ
(1)
	​

,B
μ
	​

 independent of ϵ, then

A
μ
new
	​

=ϵ(
Ω
μ
(0)
	​

B
μ
	​

	​

0
Ω
μ
(1)
	​

	​

).

That is an exact epsilon form for the prefix. This is consistent with the standard canonical differential-equation criterion: the full connection, after the basis change, must be proportional to ϵ with an ϵ-independent coefficient matrix. 
arXiv
+1

Mandatory exact checks

The continuation driver must check all of the following.

1. Actual matrix orientation and index sets

The report describes the production stop as regulator-dependent residues in “rows 1–11” of the 22-by-22 truncation, while the present description identifies the affected entries as rows 21–22, columns 1–20. This may only be sector-number versus matrix-index terminology, but it is an ambiguity that must not survive into the certificate. 

codex_overnight_optimization_tr…

The driver should persist:

Dimensions(A
v
	​

),Dimensions(A
w
	​

),

the exact index sets being scaled, and the exact block partition. It must fail if the noncanonical entries occur anywhere outside the asserted lower-left block.

2. The complete lower-left entries, not merely their “regulator-dependent parts”

The required condition is

∂
ϵ
	​

[
ϵ
1
	​

t
−1
A
μ
(10)
	​

]=0
	​


entry by entry.

It is insufficient to prove only that each entry contains a factor q. For example,

A
μ
(10)
	​

=qB
μ
	​

+ϵC
μ
	​


would become

ϵB
μ
	​

+
P(ϵ)
ϵ
4
	​

C
μ
	​

,

which is not epsilon-factorized unless C
μ
	​

=0 or an additional exact cancellation occurs.

The safest check is therefore not “factor equals q,” but directly

Together(∂
ϵ
	​

ϵ
t
−1
A
μ,ij
(10)
	​

	​

)=0.

This must be performed after exact reduction to the declared multiquadratic basis.

3. Exact upper-right zero

Both components must satisfy

A
v
(01)
	​

=0,A
w
(01)
	​

=0.

Even one nonzero upper-right entry is multiplied by t and will generally acquire an ϵ
−3
P(ϵ) factor, destroying the proposed argument.

4. Exact canonicality of both diagonal blocks

Check independently

∂
ϵ
	​

(
ϵ
A
μ
(0)
	​

	​

)=0,∂
ϵ
	​

(
ϵ
A
μ
(1)
	​

	​

)=0.

Do not rely only on the prior sector certificates; the continuation artifact should contain its own direct prefix check.

5. The differential does not include dϵ

The absence of the derivative term is correct only for

d=dv∂
v
	​

+dw∂
w
	​

.

The driver should explicitly verify

∂
v
	​

t=∂
w
	​

t=0.

If any package layer treats ϵ as a differential variable, the correct transformation would contain

−T
−1
dT.
6. Invertibility in the declared coefficient ring

One has

detT=t
2
,T
−1
=diag(I
20
	​

,
P(ϵ)
ϵ
3
	​

I
2
	​

).

This is invertible in

Q(ϵ)andQ((ϵ)),

because P(0)=−2

=0. It is not an invertible matrix over the ordinary power-series ring Q[[ϵ]], since t has a third-order pole at ϵ=0.

The state certificate must therefore declare that allowed basis transformations lie in a Laurent field such as

GL
22
	​

(Q((ϵ))),

not only in GL
22
	​

(Q[[ϵ]]).

The exceptional regulator values are

ϵ=0,
2
1
	​

,
3
1
	​

,
3
2
	​

.

Every modular sampler and exact spot-check driver must reject images for which

ϵP(ϵ)=0(modp).

These exceptional values do not invalidate an expansion around ϵ=0; they only mean that the rational gauge is defined on a Zariski-open set in regulator space.

7. Laurent-depth propagation

The new sector-11 masters are

J
21:22
new
	​

=t
−1
J
21:22
old
	​

=
P(ϵ)
ϵ
3
	​

J
21:22
old
	​

.

Recovering the original normalization requires

J
21:22
old
	​

=
ϵ
3
P(ϵ)
	​

J
21:22
new
	​

.

Consequently, recovering an original master through order ϵ
n
 can require the new canonical master through order ϵ
n+3
. The required boundary and transport Laurent depths must be increased accordingly. This is easy to miss because it does not affect the exact differential equation.

8. Canonical form versus pure/UT normalization

The transformation proves epsilon factorization. It does not, by itself, prove that the new normalization is pure or uniformly transcendental.

The factor

P(ϵ)
ϵ
3
	​


contains a nontrivial power-series unit in addition to the monomial ϵ
3
. Such a unit can mix successive Laurent coefficients. Any later claim of purity or weight normalization must therefore be checked separately against the boundary constants or leading singularities. Leading-singularity methods can guide pure-basis normalization, but they are a separate criterion from epsilon factorization. 
arXiv
+1

9. Exact transformation bookkeeping

Given the stated package convention, verify exactly

S
new
	​

=ST,S
new
−1
	​

=T
−1
S
−1
,

and both identities

S
new
	​

S
new
−1
	​

=I,S
new
−1
	​

S
new
	​

=I.

The verifier should include wrong-side mutants such as TS, ST
−1
, and S
−1
T
−1
, and prove that they fail.

10. Full future-sector propagation

If the stored state contains unsolved future rows, use

T
=diag(I
20
	​

,tI
2
	​

,I
future
	​

).

Then future rows coupling into columns 21–22 transform as

A
future,21:22
new
	​

=A
future,21:22
	​

t.

Any current-prefix-to-future upper-right entries transform with t
−1
 and must be proved zero if sector triangularity is assumed.

It is not sufficient to modify only the 22-by-22 truncation if later sectors are extracted from an untransformed full connection. Either:

transform the full stored connection, or

store a basis-transformation ledger that every future strip extractor applies.

11. Invalidate or transform dependent caches

The following must not silently survive under the old basis:

installed row forms;

PrevD;

saved strip gauges;

forcing-block caches;

compiled finite-field artifacts;

normalization-column plans;

one-form fingerprints;

regulator seals.

The report’s resume logic already treats replay mismatches as reasons to invalidate a complete recovered row, which is the correct fail-closed behavior. 

codex_overnight_optimization_tr…

For the shortest safe continuation, clearing basis-dependent sector-12 artifacts is preferable to attempting a delicate metadata patch.

12. Exact canonical and flatness identities

For both components, verify

∂
ϵ
	​

(
ϵ
A
μ
new
	​

	​

)=0.

Then verify integrability:

∂
v
	​

A
w
new
	​

−∂
w
	​

A
v
new
	​

−[A
v
new
	​

,A
w
new
	​

]=0.

Since A
new
=ϵΩ, an exact polynomial-in-ϵ check also separates into

dΩ=0,Ω∧Ω=0.
Verdict on A

This is a legitimate solution of the current regulator-factorization stop, not a cosmetic rewrite, provided the driver proves the full block identity and propagates the basis change into future sectors.

It is only local in the sense that future sectors may generate new regulator-factorization problems. It does not by itself complete CF300.

B. Resume sector 12 only after one independent prefix certificate

Do not immediately resume sector 12 after the transformation driver reports success. Run one independent certificate first.

The production state was reached after a long exact row installation and was preserved under a distinct hash, so a single independent check is cheap relative to the cost of contaminating the continuation. 

codex_overnight_optimization_tr…

Minimum acceptance certificate

The independent verifier should:

Run in a clean mission-owned context on a nonquarantined worker.

Reload the immutable pre-rescaling state by its exact hash.

Construct T and T
−1
 independently, without calling the transformation driver’s helper routines.

Compute T
−1
A
μ
	​

T directly for μ=v,w.

Compare it exactly with the stored continuation matrices.

Verify

∂
ϵ
	​

(A
μ
new
	​

/ϵ)=0

entrywise in the multiquadratic basis.

Verify both inverse identities for S
new
	​

 and S
new
−1
	​

.

Recompute the prefix connection from the original family connection and S
new
	​

, at least through an independent evaluation path.

Verify full-state or deferred future-block propagation.

Verify the new Laurent-depth metadata.

Verify that all old sector-12 preparations and compiled artifacts are absent, invalidated, or explicitly transformed.

Write a distinct immutable state only after all checks pass.

Strongest cheap adversarial test

Use an unseen good prime and generic ϵ, evaluate all algebraic channels or all eight sign branches, and compare:

T
−1
A
old
	​

T

against the connection independently reconstructed from

S
new
	​

,S
new
−1
	​

,A
original
	​

.

Then run the same verifier against deliberate mutants:

TAT
−1
;

S
new
	​

=ST
−1
;

omitted scaling of future columns 21–22;

unchanged old SInverse;

a single altered lower-left entry.

All should fail.

This is stronger than simply adding more successful random evaluations because it directly attacks the likely implementation mistakes: orientation, block indexing, and incomplete propagation.

C. Finite-field search order
First correction: the documented (12,9) search is already rank-two multiquadratic

The ledger says that the physical (12,9) preparation used roots {2,3}, exact four-branch sampling, and a 624-unknown affine system. 

codex_overnight_optimization_tr…

 It later replaced explicit branches by a direct multiquadratic grade-channel assembler and proved equality after the grade-to-sign transform. 

codex_overnight_optimization_tr… +1

Therefore, unless the current Galois pilot targets a new post-rescaling rank-three strip, the A0/AS/AL/ASL/MAX5 results are not merely exclusions of a root-free rational gauge. They are exclusions of particular rational coefficient ansatzes inside the active rank-two multiquadratic field.

This distinction matters because adding the inactive third root to an affine strip equation cannot generally cure the inconsistency.

Suppose the strip equation is linear over

E
23
	​

=Q(v,w,ϵ)(r
2
	​

,r
3
	​

)

and the source and normalization conditions are invariant under r
1
	​

↦−r
1
	​

. If a solution in

E
23
	​

(r
1
	​

)

is written as

X=X
0
	​

+r
1
	​

X
1
	​

,

then an affine equation L(X)=b separates into

L(X
0
	​

)=b,L(X
1
	​

)=0.

Thus a solution over the larger field implies a solution X
0
	​

 over the original rank-two field. The extra root can add homogeneous freedom but cannot repair an affine contradiction.

All eight signs are mandatory for a genuinely rank-three input. They are wasted for a genuinely rank-two affine strip.

Second correction: the modular inconsistencies are strong screens, not yet exact no-go certificates

MAX5 proves exact column containment of all 31 square-free denominator subsets, and all four tested modular images are inconsistent. 

codex_overnight_optimization_tr…

 The second support shell is likewise inconsistent in all four images and contains every anisotropic sub-shell considered. 

codex_overnight_optimization_tr…

This is decisive enough to stop those searches. It is not yet a deterministic characteristic-zero obstruction.

A rational solution could, in principle, have regulator or coefficient denominators divisible by the finite set of tested primes or singular at the tested ϵ-images. Four unrelated images make that extremely implausible, but an exact project should distinguish screening from proof.

The shortest exact obstruction certificate is a lifted left witness. For an exact sampled affine system

Ax=b,

reconstruct

y
T
A=0,y
T
b=1

over Q, and verify these identities using the original exact row generator. For MAX5, one exact witness would also exclude all 31 contained square-free subsets.

Finite-field reconstruction is a standard exact strategy only after CRT/rational lifting and characteristic-zero verification; finite-field evaluations themselves remain modular evidence. 
arXiv
+1

Expected-value ranking
Rank	Axis	Assessment
1	Multiquadratic coefficients in the actual active field	Highest value. Use four grades for an active rank-two strip and eight for an active rank-three strip. Do not enlarge the field merely because the family globally has three roots.
2	Local resonance and pole-order analysis, followed by justified repeated poles	High value. Determine whether double or higher poles are mathematically required before constructing the corresponding ansatz.
3	Pure-basis/leading-singularity information	High diagnostic value. It can identify missing algebraic normalizations and candidate letters, although it does not guarantee the off-diagonal gauge.
4	New algebraic one-forms with exact closedness and potential checks	Plausible missing ingredient. The 12 naive factor dlogs have already failed; genuinely algebraic letters remain possible.
5	Direct exact algebraic solve of a reduced system	Valuable as a definitive oracle after the field, support, and pole bounds are fixed. Poor as a blind discovery method for a 600–1700-variable system.
6	Larger numerator support	Low value without a degree/asymptotic or left-obstruction argument. Two nearby support enlargements have added rank directions without spanning the missing forcing direction.
Last	All eight signs applied to the old rank-two (12,9) input	No expected mathematical value beyond testing infrastructure. The extra root contributes only homogeneous odd-grade sectors.

Leading-singularity and Baikov analyses are established ways to search for UT normalizations in multiscale systems, but their result must still be checked against the full differential equation, including lower sectors. 
arXiv
 Rational-reduction algorithms likewise rely on controlled pole and normalization information rather than unlimited support expansion. 
arXiv

Local resonance test before repeated poles

For every irreducible divisor f(v,w)=0, expand the relevant strip equation locally. Schematically, if

A=
f
Rdf
	​

+⋯,D=
k=−s
∑
∞
	​

D
k
	​

f
k
,

the highest-pole coefficient is governed by an indicial operator of the form

kD
k
	​

+R
left
	​

D
k
	​

−D
k
	​

R
right
	​

.

If this operator is invertible at the candidate order, the corresponding repeated pole is unnecessary. If it has a resonant kernel and the forcing projects into the obstruction, a higher pole or a modified normalization may be required.

The repeated-pole pilot should therefore output, for each divisor:

the local residue matrices;

the relevant indicial eigenvalue differences;

the predicted maximum pole order;

the exact obstruction projection.

A brute double-pole closure without this analysis is another large ansatz sweep with little information.

When rational ansatz expansion becomes unjustified

That threshold has been reached for the pre-rescaling input.

Do not add another rational support shell, denominator subset, or rational factor dlog unless at least one of the following is available:

an exact local-resonance calculation requiring it;

a reconstructed left obstruction that the proposed new columns pierce;

leading-singularity or maximal-cut information predicting the normalization;

an exact alphabet/divisor analysis identifying a missing one-form;

a new post-rescaling strip input that is not equivalent to the old one.

D. Fail-closed all-eight-sign validation
Production representation

The production solver should use the direct grade basis

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

}

with XOR multiplication and rational channel arithmetic.

The all-eight split-sign representation should be retained as an independent oracle, not as the primary sampler. The current direct assembler already accepts nonsplit points and confines explicit modular square roots to the held-out sign-basis check. 

codex_overnight_optimization_tr…

 This removes the approximate 1/8 split-point acceptance penalty and avoids sign-label bookkeeping in the main path.

Critical nullity issue

Do not solve eight branch systems independently and Walsh-project the eight returned solutions.

The documented systems have nonzero nullities—12 for several gauge ansatzes and 40 after letter enlargement. 

codex_overnight_optimization_tr…

 Independent RREF calls can choose different free-coordinate representatives on different branches. The Walsh projection of those unrelated representatives is not a coherent element of the multiquadratic field.

Use one of these two methods:

assemble and solve one coupled grade-channel system over F
p
	​

; or

impose a predetermined Galois-stable normalization and pivot plan shared by all branches.

The first is preferable.

Validation checklist
Field and source identity

Prove square-class rank three for the actual input.

Bind the ordered radicands and root order into the artifact hash.

Bind the original strip input, source closure, ABI, ansatz, one-form list, and regulator normalization.

Reject any artifact whose active-root set differs from the captured strip’s dependency closure.

Point admissibility

Require p

=2 and reject all declared bad primes.

Require every radicand and every algebraic denominator norm to be nonzero.

Require all rational ansatz denominators and normalization minors to be nonzero.

Reject ϵP(ϵ)=0 for the CF300-rescaled continuation.

Grade/sign equivalence

At held-out split points, define one root triple (ρ
1
	​

,ρ
2
	​

,ρ
3
	​

) and enumerate branches by an explicit three-bit mask.

Apply the Walsh transform to recover the eight grade coefficients.

Apply the inverse transform and reproduce all eight branch values exactly.

Randomly flip the base root representatives ρ
i
	​

↦−ρ
i
	​

; after branch relabeling, the reconstructed grade coefficients must be unchanged.

Randomly permute branch rows without updating their masks; the oracle must fail.

Compare the direct grade-channel matrix and RHS with the explicit sign-branch matrix after the exact grade-to-sign transform.

Solver coherence

Use one fixed Galois-stable normalization plan.

Verify the returned solution against every original equation, not only the constrained square core.

Verify all nullspace vectors against every original row.

If the input has active rank r<3, require all normalized solution grades involving inactive roots to vanish. Nonzero inactive odd grades indicate arbitrary homogeneous contamination.

Verify Galois equivariance:

σ(T
reconstructed
	​

)=T
separately evaluated on branch 
	​

σ

under the same normalization.

Reconstruction

Reconstruct each grade coefficient independently as an element of

Q(v,w,ϵ).

Require stable support and denominator profiles under different prime and point orderings.

Continue CRT until the modulus satisfies the stated rational-reconstruction uniqueness bound; merely using three primes is not an exact criterion.

Record the actual recovered numerator and denominator heights.

Use points not employed in support discovery, pivot discovery, or coefficient reconstruction.

Exact characteristic-zero acceptance

Substitute the lifted gauge into the original strip PDE and verify the residual exactly in all eight grades.

Perform that final residual through an implementation independent of the direct assembler—ordinary exact differentiation, matrix multiplication, and rational simplification.

Verify the installed strip, resulting row connection, and inverse basis maps.

Verify every claimed one-form is closed.

If package status is CanonicalDLog, verify an exact dlog potential for every one-form. Otherwise distinguish the weaker status EpsilonFactorized.

The report’s independent characteristic-zero residual using ordinary D, Dot, and entrywise Together is exactly the kind of independent oracle that should be retained. 

codex_overnight_optimization_tr…

Minimum prime and point evidence

There is no universal finite count that constitutes a proof. Counts only become deterministic when combined with degree and coefficient-height bounds.

A minimally persuasive engineering floor for one actual physical rank-three strip is:

three construction primes, continuing further until the CRT uniqueness bound is met;

two unseen primes;

at each unseen prime, at least eight held-out base points;

two unseen regulator values at each prime;

all eight branches at every split-oracle point;

at least two exact characteristic-zero kinematic points, each checked at two generic regulator values;

one full exact symbolic residual over

Q(v,w,ϵ)[r
1
	​

,r
2
	​

,r
3
	​

].

The last item is mandatory. No number of modular spot checks replaces it.

The report’s existing three-construction-prime, one-unseen-prime, all-branch oracle is adequate evidence for the prototype arithmetic, but not for production promotion of a physical strip. 

codex_overnight_optimization_tr…

Also, all eight branches at one base point are algebraic components of one specialized point, not eight statistically independent kinematic samples. Repeated branch-mask flips only permute those components; the report correctly recognizes that they do not add new branch semantics. 

codex_overnight_optimization_tr…

E. Runtime and testing architecture
What is sound

The following design choices are sound:

immutable source and state artifacts;

explicit SHA-256 binding;

mission-owned symbol contexts;

exact rebind validation;

atomic result commits;

one centrally brokered flat kernel pool;

prohibition of nested helper pools;

independent direct-versus-legacy assembly comparisons;

fail-closed typed statuses;

preserving unrelated source-pinned jobs.

The warm direct-assembler and ansatz-rebind improvements are substantial and well supported by exact output comparisons. The report measures a roughly 22-fold warm assembly speedup and a roughly 56-fold rebind speedup against recompilation. 

codex_overnight_optimization_tr…

Further performance work is not the current priority. The ledger already shows that native RREF is below one percent of the relevant campaign wall time and that the bottleneck moved to symbolic compilation and ansatz construction. 

codex_overnight_optimization_tr…

What remains unsafe
1. Dedicated contexts are necessary but not sufficient

The poisoned-kernel experiments showed that static namespace checks can pass while runtime hydration still fails. Two V2 drivers passed large static suites but failed during artifact hydration on reused kernels. 

codex_overnight_optimization_tr…

Every production artifact reader must be exercised in:

a fresh kernel;

a deliberately polluted but nonlocked kernel;

a kernel with unrelated `Global`` definitions;

a kernel whose $ContextPath omits `Global``;

a kernel with package-export name shadows.

2. The artifact format must not depend on `Global``

A public reader that hardcodes Global`` while fingerprints depend on the contexts of x, y`, or ϵ is not a stable serialization contract. The dedicated-context bypass is a valid external workaround, but the package artifact should instead serialize:

inert symbol identifiers;

an explicit symbol-role table;

a schema version;

root order;

variable order;

derivation variables;

normalization convention.

Deserialization should create mission-owned symbols and rebind by role, not by whatever context happens to be visible.

The report documents both the hardcoded-Global issue and successful mission-owned hydration while preserving the poisoned `Global`` state. 

codex_overnight_optimization_tr…

3. Target-level Return is a production blocker

An untagged target-level Return can escape the pool wrapper and leave the scheduler without a terminal marker. The fact that the worker survives does not make this safe. 

codex_overnight_optimization_tr…

The target should execute inside a function boundary or a tagged Catch, with terminal bookkeeping guaranteed by an unwind construct. Return, Exit, Quit, and abort paths must all map to typed terminal states.

4. Quiet[Check[Get,\ldots]] must be removed

A benign message followed by a valid returned artifact must not be converted into $Failed.

Load using:

CheckAbort;

explicit message capture;

separate validation of the returned value;

a typed policy for unexpected messages.

For production, an unexpected message may still cause failure, but the valid return value and message record must be preserved for diagnosis.

5. Mutation tests must never run in production workers

Any test that sets Locked, alters Protected, or installs broad definitions should run in a disposable kernel or a dedicated destructive-test pool.

A mission-owned Wolfram context does not protect a kernel from changes to:

symbol attributes;

$ContextPath;

$Path;

$Assumptions;

package definitions;

options;

$Pre and $Post;

global hooks.

6. Worker health must be broker state, not only a resident mission

The current heartbeat quarantine is a sound emergency mechanism because it pins the exact poisoned worker and fails if scheduled elsewhere. The report demonstrates that wrong-worker submissions returned a typed failure rather than touching a clean worker. 

codex_overnight_optimization_tr…

Longer term, the broker should maintain a worker health registry and exclude worker 144 from scheduling without requiring a resident heartbeat job.

Was quarantining correct?

Yes.

Because the critical symbols were irreversibly locked in that process, attempts at cleanup would have added uncertainty. Preserving unrelated jobs and occupying the exact poisoned worker with a no-mutation guard was the safest immediate action.

It should not be treated as permanent recovery. At the next controlled maintenance boundary:

stop scheduling new work;

allow source-pinned jobs to complete or checkpoint;

restart the poisoned subkernel or the whole pool;

run a fresh-kernel health attestation;

remove the quarantine only after the attestation passes.

F. Revised 12–24-hour execution plan
Parallel lane 1: CF300 analytic rescaling
Step 1 — Freeze inputs

Use the immutable current state and sector-11 checkpoint hashes. Do not update package source during this certificate.

Step 2 — Run the analytic transformation driver

Require every condition listed in section A.

Continue only if:

∂
ϵ
	​

(A
v
new
	​

/ϵ)=∂
ϵ
	​

(A
w
new
	​

/ϵ)=0

exactly, the inverse identities pass, and future propagation is sealed.

Abandon this transformation if:

any lower-left remainder survives;

any upper-right entry is nonzero;

the state convention places T on the opposite side;

full future rows cannot be transformed or deferred coherently.

Step 3 — Independent prefix certificate

Run the separate verifier described in B.

Continue only after the independent verifier passes.

Step 4 — Atomically write a distinct continuation state

Record:

parent-state hash;

exact T and T
−1
;

transformation convention;

exceptional regulator factors;

Laurent-depth shift;

invalidated cache list;

new state hash.

Parallel lane 2: multiquadratic infrastructure

Allow the current Galois-orbit pilot to finish only as an infrastructure test. Its result must be labeled according to the actual pinned input:

rank two: four-grade solver test;

rank three: eight-grade solver test;

synthetic/oracle: not a physical CF300 solution.

Do not independently solve each sign branch if the affine system has nullity.

No package promotion should occur from this pilot alone. The report shows the latest Galois launch was still active and had not produced a physical certification result. 

codex_overnight_optimization_tr…

Parallel lane 3: exact local diagnostics

Prepare, but do not yet apply, the following reusable tools:

local divisor/resonance analysis;

exact left-witness lifting;

algebraic one-form closedness and potential checks;

leading-singularity/root-normalization comparison.

These are safe to develop against the immutable old input, but their mathematical conclusions must be rerun on the post-rescaling strip.

CF300 continuation after the new state exists
Step 5 — Recapture sector 12 from the new state

This is mandatory.

Do not assume that the existing A0/MAX5/second-shell matrices remain valid. The sector-11 rescaling changes future couplings, and the recursive solution of 12 -> 11 can propagate into 12 -> 10, 12 -> 9, and later strips.

Compare the new and old strip inputs exactly.

Reuse an old inconsistency result only if an explicit invertible transformation proves the two affine systems equivalent. Matching dimensions, support, or modular ranks is not enough.

Step 6 — Recompute the dependency-closed root rank

For each strip after recursive forcing has been assembled, determine the actual active square-class span.

rank zero: rational solver;

rank one: two-grade solver or rational chart;

rank two: four-grade direct solver;

rank three: eight-grade direct solver.

Do not select eight signs from the family-wide root count alone.

Step 7 — Test the smallest post-rescaling ansatz

Start with the transformed analogue of A0, using the direct grade assembler.

Use two primes and two regulator images for a fast discriminator.

If generically consistent: move directly to reconstruction.

If inconsistent: lift an exact or high-confidence left obstruction before deciding the next axis.

Do not immediately repeat AS, AL, ASL, MAX5, and the second shell.

Step 8 — Choose the next axis from diagnostics

Use this decision order:

local resonance requires repeated poles;

leading singularities require a missing root normalization;

exact alphabet analysis produces a new algebraic one-form;

obstruction projection identifies a specific missing support direction;

only then enlarge numerator support.

Step 9 — Reconstruct the actual physical gauge

Use direct grade arithmetic for construction and split signs only for the independent oracle.

Accept only after:

CRT uniqueness;

unseen-prime checks;

all active Galois branches;

exact characteristic-zero strip residual;

exact row installation;

exact prefix canonicality;

exact inverse and propagation seals.

Step 10 — Continue CF300 sector by sector

A solved strip should not receive a generic package Solved status unless all installed one-forms satisfy the intended final contract. The ledger itself notes that closed forms require verified dlog potentials before package-level solved status. 

codex_overnight_optimization_tr…

Use two distinct statuses if necessary:

EpsilonFactorized;

CanonicalDLog.

This avoids treating failure to identify a dlog potential as failure of epsilon factorization itself.

CF303

The identity-frame capture can safely continue in parallel, but no CF300 preparation, prime artifact, or elimination plan should be reused. CF303 shares the same ordered degree-eight field, not the same strip matrices or recursive state. 

codex_overnight_optimization_tr…

Before using the capture:

fix persistence of the typed algebraic failure status;

verify the capture was produced in a clean dedicated context;

wait for the CF300 multiquadratic strip consumer and installer to pass on an actual physical strip;

replay CF303 until its first typed stop;

distinguish:

NoRationalStripChart;

NeedsMultiquadraticRegulatorFactorization.

A raw pre-recursion grade census is not sufficient because earlier row gauges can introduce new grades; the report correctly identifies this limitation. 

codex_overnight_optimization_tr…

CF259

Run only field-level preparation in parallel:

exact Q
4
	​

=4v+w
2
 square-class metadata;

differentiation and multiplication tests;

rank-zero through rank-three grade/sign equivalence;

active-root denominator-norm tests;

one actual Källén+Q
4
	​

 physical oracle.

Do not reuse CF300/CF303 field fingerprints or compiled artifacts merely by replacing the third radicand. CF259 requires fresh root-order, ABI, denominator, and sign-oracle coverage. 

codex_overnight_optimization_tr…

Start its recursive production continuation only after the CF303 consumer has shown that the generalized solver is not accidentally specialized to the CF300 root triple.

Tests that are redundant or weaker than currently implied
1. Individual square-free denominator subsets

MAX5, together with exact column embeddings, supersedes further runs of the 31 square-free denominator subsets. Repeating them adds no mathematical information. 

codex_overnight_optimization_tr…

2. Repeating A0/AS/AL/ASL through both assemblers

After exact equality of the full matrices and RHS under the grade-to-sign transform, rerunning the same four variants through both assemblers adds backend-differential and timing evidence, not independent evidence that the ansatz is mathematically inconsistent. 

codex_overnight_optimization_tr… +1

3. Repeated branch-flip masks

These permute branch rows. They test label handling but do not create new Galois information. 

codex_overnight_optimization_tr…

4. Redundant dense rank calculations

The extra constrained-core rank calculation after a canonical affine RREF and verified witnesses was already identified as theoretically redundant. 

codex_overnight_optimization_tr…

 Do not repeat it in production.

5. Test counts as confidence metrics

Counts such as 109/109 or 120/120 show coverage of the enumerated fixtures. They do not measure independence of the oracles. Many tests share:

the same decomposition code;

the same symbol canonicalization;

the same matrix assembly;

the same artifact loader.

The strongest tests are those using genuinely independent computations:

direct branch substitution versus grade assembly;

ordinary D/Dot/Together versus custom field arithmetic;

exact lifted PDE residual;

fresh-kernel hydration versus reused-kernel hydration;

deliberate wrong-orientation and wrong-root mutants.

6. Sanitizer and binary reproducibility tests

ASan/UBSan, byte-identical outputs, and binary hashes are important software-engineering evidence. They do not certify that the mathematical system being solved is the correct strip PDE.

7. Empty message streams

“No Wolfram messages” is useful operational evidence, not a mathematical certificate.

8. Matching modular pivot fingerprints

Stable pivot patterns across primes are useful for reconstruction planning. They do not prove characteristic-zero consistency or inconsistency.

9. A necessary left-witness screen

A candidate piercing the current left witness is only a necessary condition. The report itself found denominator candidates that pierced the cheap witness but remained inconsistent under full rank checks. 

codex_overnight_optimization_tr…

10. Static CF303/CF259 strip censuses

They cannot predict grades introduced by recursively installed row gauges. They are useful only for initial inventory, not for selecting the eventual field rank of a production strip.

Verdict table
Component	Current decision	Confidence	Main risk	Next mandatory certificate
Analytic regulator rescaling	Proceed conditionally. It is a valid epsilon-factorization transformation for the prefix if the complete block identities hold.	High	Factoring only the “regulator-dependent part,” wrong orientation, incomplete future propagation, or unrecorded Laurent-depth shift	Independent exact 22-by-22 canonicality check, full-state propagation seal, inverse check, and raw-connection reconstruction
Rational finite-field optimization	Freeze performance work and use the direct assembler.	High	Shared-code oracle correlations and stale post-rescaling inputs	Exact equality on the newly recaptured physical strip plus an independent exact residual; no more benchmark-only work
Multiquadratic Galois-orbit solving	Not production-certified. Use grade arithmetic in production and split signs as oracle.	Medium	Independent branch representatives under nonzero nullity; using eight signs on a rank-two strip; interpolation/sign-label artifacts	One actual physical rank-three coupled solve, CRT uniqueness, two unseen primes, all signs, and exact characteristic-zero PDE residual
Package promotion	Do not promote yet. Complete CF300 externally first.	High	Target-level Return, hardcoded Global, message-swallowing load path, context-sensitive fingerprints, unverified dlog potentials	Fresh-kernel end-to-end physical strip solve and install; fixed terminal-state wrapper; context-independent serialization; poisoned-kernel runtime gate
Pooled runtime safety	Contained but not restored. Quarantine was correct.	Medium-high	Scheduler leakage to worker 144, future shared-state mutation, treating heartbeat quarantine as permanent cleanup	Broker-level unhealthy-worker exclusion, controlled kernel restart, disposable mutation-test pool, and fresh health attestation

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/External/CodexExchange/codex_overnight_optimization_triple_root_2026-08-23.md` (not archived with this exchange)
