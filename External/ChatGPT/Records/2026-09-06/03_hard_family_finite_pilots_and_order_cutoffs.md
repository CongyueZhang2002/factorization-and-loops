# Hard-family finite pilots and order cutoffs

## Question

We are continuing the overnight canonicalization/finite-DE work in https://github.com/CongyueZhang2002/factorization-and-loops (local edits are not committed). Please challenge the next decision and inspect the order-request change below.

New measurements under one KernelPool, eight shared cores:
- Fresh CF300 raw DE: 88.398 s with one Kira thread and another family active. Automatic finite solution from current hard-function coefficient upper demands: 15.23 s including bounds/preparation/writing; 24 closure masters, 2 requested masters through eps^0, lower bound -5, evolution through order 7, 12 explicit master coefficients, 1.49 MB compressed. No supplied homogeneous preparation.
- CF303: existing V2 DE plus already validated explicit homogeneous preparation, 192.09 s including writing; 45 closure masters, 6 requested masters, 36 explicit coefficients, 5.81 MB. Not a fresh full-family time.
- CF259: renewed 1800 s optional canonicalization trial advanced from sector 18 to 24/27 and stopped on budget, not obstruction. Its partial S has 481,743 leaves, inverse 1,139,507 leaves; explicit transformed A already 57,279,719 leaves versus 2,760,483 in the starting diagonally transformed A. In contrast, direct raw-DE automatic finite solution completed in 142.14 s including order determination/writing: 47 closure masters, 9 requested masters, actual demands through eps^1 for first 2 and eps^0 for other 7, derived -5 lower bound, 56 explicit coefficients, 5.68 MB.
- This strongly suggests NOT feeding the enormous CF259 partial expression through finite integration as the production default. Is the expression-size evidence plus completed raw solve enough to stop that optional comparison? Any inexpensive counter-check or intermediate representation that changes the conclusion?
- One supported left-null inconsistency witness replaced the full nullspace in negative-only screening. 6 new assertions plus 18 image and 58 screen assertions pass; witness microbench improves 3000x24 case 0.186 -> 0.018 s. Sampled negative scope remains weak. I plan not to delay all-family computation for the stronger constant-shift/nullspace characteristic-zero criterion.

Next: fresh concurrent 4-family pilot CF50, CF299, CF301, CF407 (source registry/master-list/Kira config current, one Kira thread each), followed by general finite integration. The general Python coordinator submits phase jobs to the SAME pool, stores atomic input snapshots/status and resumes without duplicate jobs. Full 91-family campaign only once complete-wave timings and failure pattern support it. Missing homogeneous solutions will be explicit failures, never symbolic arbitrary functions or lazy DE generators.

Order adapter correction: instead of independently calculating target lower bounds in a script, the package planner now accepts RequestedMasterIntegralUpperOrders -> <|row -> K_i|>. This is exclusive with explicit range requests. The existing planner fixes preparation/base point, derives integral bounds (or uses supplied dimensional recurrence with its shared point), derives all closure/boundary/evolution requirements, then returns ranges {Min[derived lower bound_i, K_i], K_i}. Unknown bounds remain unresolved, assumed bounds conditional. All code paths reuse existing explicit finite integration. Existing explicit-range and upper-only requests yield identical plans for a scalar control. The current coefficient record has K_i=N-valuation(c_i), before any unspecified endpoint/renormalization/PDF operations; no physical NNLO coverage inferred.

Questions:
1. Is this production route/stopping policy justified given the measurements? What result from the fresh wave would make you stop or change it?
2. Any mathematical issue with the upper-only adapter, especially using the derived ordinary-point master lower bound as the requested lower cutoff in a complete boundary-parameterized solution? The goal is every coefficient needed by the declared coefficient table, not silently discarding possible below-bound terms.
3. Any low-cost structural test worth adding now for the sampled negative criterion, or should that remain honestly scoped and be deferred?
Please be direct and distinguish mathematical correctness from optional presentation/canonicalization.


## Pro response

Yes: stop the optional CF259 comparison, proceed to the fresh four-family pilot, and defer stronger nonexistence certification. The upper-only interface is also appropriate, but an ordinary-point, per-master lower bound is not automatically a valid lower cutoff for the transported solution. That is the one mathematical condition I would check before treating the new outputs as complete.

I am reviewing the adapter as described, not its unseen local implementation. The pushed working branch remains at e8c62cce….

1. Production route: the evidence is sufficient to stop the optional comparison

From your measurements, CF259’s partial canonicalization has enlarged the explicit connection by approximately

2,760,483
57,279,719
	​

=20.75,

while the unsuccessful 1800-second trial consumed 12.7 times the completed raw finite solve’s 142.14 seconds.

Expression size alone does not prove that every partially transformed integration would be slower. Expression growth plus an already completed raw solve is nevertheless sufficient for the production decision. You do not need to finish an expensive comparison to justify declining it. Reaching sector 24/27 is not a reliable measure of the remaining cost.

My recommended default is now:

Use the raw DE or an already available, validated preparation that the finite solver needs. Start new optional canonicalization only when the direct finite route fails, is unsupported, or has a demonstrated bottleneck that a specific transformation could remove.

This does not diminish the mathematical result. Finite-order integration does not require a strict epsilon form; the substantive requirement is that the necessary homogeneous evolution is actually resolved rather than left as an unspecified solution operator. 
arXiv

The inexpensive counter-check should concern the raw result, not another representation

Reuse the existing acceptance machinery to check the emitted coefficients against the original raw DE, with the appropriate internal order coverage, and check the boundary normalization. For a two-variable solution, checking only the differential equation along the integration path is weaker than checking both original components.

If those checks and the lower-cutoff condition below are already satisfied, no further CF259 comparison is needed.

An existing factored transformation product or shared expression representation can preserve the partial canonicalization for later use without materializing its enormous connection. That is worth retaining if already supported. It is not worth building a new intermediate representation before this campaign, and it does not require changing the explicit finite-solution output format.

What should change the decision after the four-family wave?
Fresh-wave outcome	Decision
Wrong order coverage, below-cutoff leakage, failed DE/boundary checks, or unresolved functions marked “complete”	Stop the affected completion path and fix the mathematical defect before promoting more results.
A family genuinely lacks a supported homogeneous preparation	Preserve its DE and report it incomplete. Continue independent supported families; do not automatically launch a long canonicalization rescue. Repeated failures of the same type indicate a coverage gap worth addressing separately.
Memory contention, repeated preparation, oversubscription, or long closure/reduction tails dominate	Change scheduling or the identified expensive stage before expanding concurrency. Do not change the mathematical output requirement to improve the timing.

Measure whole-wave completion including fresh DE construction, preparation, finite integration, acceptance, and writing. CF300 provides a measured two-stage sum of 103.628 seconds; CF303 and CF259 still do not provide comparable fresh full-family timings.

For a rough four-worker-wave projection, with 25% contingency,

T
campaign
	​

≈1.25⌈
4
N
remaining
	​

	​

⌉T
wave
	​

.

For 91 families, a representative four-family wave of four minutes corresponds to about 1.9 hours; eight minutes corresponds to about 3.8 hours. This is a planning model, not a conclusion from one wave. It assumes comparable remaining work and the same sustained concurrency. Do not extrapolate to six or eight simultaneous families without measuring that configuration.

The same-pool coordinator and one-thread Kira policy are appropriate starting choices. Continue accounting for all active compute threads, including native libraries and helper work, rather than counting submitted family jobs.

2. Upper-only adapter: correct interface, conditional lower-cutoff justification

The interface separation is correct:

user supplies K
i
	​

,planner determines the necessary output and internal order ranges.

Mutual exclusion with explicit-range requests also avoids ambiguous precedence.

The important distinction is between

β
i
	​

:val
ϵ
	​

I
i
	​

(z
0
	​

,ϵ)≥β
i
	​


at the chosen base point, and

L
i
	​

:val
ϵ
	​

I
i
	​

(z,ϵ)≥L
i
	​


as a function of kinematics on the declared ordinary domain. These need not be equal.

A scalar control cannot detect the principal failure mode

Consider the flat rational system

dx
d
	​

(
I
1
	​

I
2
	​

	​

)=(
0
0
	​

1
0
	​

)(
I
1
	​

I
2
	​

	​

),I
1
	​

(0)=a,I
2
	​

(0)=
ϵ
b
	​

.

Its exact solution is

I
1
	​

(x)=a+
ϵ
xb
	​

,I
2
	​

(x)=
ϵ
b
	​

.

At the ordinary point x=0, row 1 has lower bound 0. Away from that point, it has an ϵ
−1
 coefficient. Using its boundary bound as its output cutoff loses a required coefficient—even though the connection is epsilon-independent and completely elementary.

There is a second failure mode with a common boundary bound:

dx
dI
	​

=
ϵ
1
	​

(
0
0
	​

1
0
	​

)I,I(0)=(
a
b
	​

).

Again,

I
1
	​

(x)=a+
ϵ
xb
	​

,I
2
	​

(x)=b.

All boundary components are finite, but the transported solution is not.

These are useful two-by-two adapter regressions. They test something that agreement between upper-only and explicit-range requests for a scalar system cannot establish.

A cheap sufficient certificate: preservation of the proposed bounds

Suppose the proposed bounds apply to every component of the closure basis. Define

D
β
	​

=diag(ϵ
β
1
	​

,…,ϵ
β
n
	​

),J=D
β
−1
	​

I.

Then

dJ=
A
J,
A
=D
β
−1
	​

AD
β
	​

.

If, for both kinematic components,

val
ϵ
	​

(A
μ
	​

)
ij
	​

+β
j
	​

−β
i
	​

≥0for every nonzero entry,
	​


the rescaled connection is epsilon-regular. With epsilon-regular rescaled boundary data at an ordinary point, the formal coefficient recurrence preserves epsilon-regularity. Consequently,

val
ϵ
	​

I
i
	​

(z,ϵ)≥β
i
	​


throughout the ordinary domain of continuation.

This is a sufficient mathematical certificate, not a new canonicalization algorithm. It can use conservative, certified entry-valuation bounds already available to the planner. It does not require sharp valuations, and it does not require an epsilon form.

For the common bound −5, the condition simplifies: an epsilon-regular connection preserves that common bound, provided it bounds all relevant closure boundary components, not just the requested output rows.

Two qualifications matter:

Apply the test to the actual basis whose boundary bounds are being used. An epsilon-regular prepared connection does not by itself justify bounds after an epsilon-singular reconstruction map.

Failure of this test does not prove the proposed bounds wrong. It means this inexpensive argument does not establish them.

If the existing integral-bound derivation already proves a generic-kinematics bound, do not add a duplicate proof merely for formality. But a dimensional-recurrence bound derived only at the shared point is a boundary bound until a transport argument supplies the next step. Sharing the point avoids a mismatch; it does not eliminate this distinction.

General transport formula

If the complete map from the chosen boundary vector to the requested original masters is

I
i
	​

(z,ϵ)=
j
∑
	​

U
ij
	​

(z,z
0
	​

;ϵ)B
j
	​

(ϵ),

and

val
ϵ
	​

B
j
	​

≥β
j
	​

,val
ϵ
	​

U
ij
	​

≥τ
ij
	​

,

then a conservative output bound is

L
i
	​

=
j
min
	​

(β
j
	​

+τ
ij
	​

).
	​


Here U must include all preparation, evolution, and reconstruction maps. Cancellations can improve the bound; ignoring them makes it conservative.

This is the conceptual rule your existing closure/boundary/evolution planner must implement or replace with an equivalent proof. It is not a request to construct a large full transfer matrix just to obtain bounds.

Boundary-parameterized completeness needs one explicit interpretation

A bound on the physical masters is not permission to erase terms produced for arbitrary boundary constants.

Either the declared boundary class is preserved by transport, or additional relations among boundary constants are needed to ensure the physical bounds. In the latter case, those relations must be retained explicitly. Do not drop a generated below-bound coefficient while leaving the constants that generate it unconstrained.

Thus “complete boundary-parameterized solution” should mean complete within the declared Laurent boundary class and its stated constraints, not within an unrestricted class of meromorphic-in-ϵ constants.

The Min[lower, K] rule has one edge case to protect

Once L
i
	​

 is a valid output bound,

{min(L
i
	​

,K
i
	​

),K
i
	​

}

is a reasonable nonempty output-range convention.

When K
i
	​

<L
i
	​

, however, the result is a provably zero requested coefficient. The adapter must not reinterpret the lowered request endpoint K
i
	​

 as permission to introduce a new boundary constant at that order. Output-range normalization and boundary lower bounds must remain separate.

Your reported counts are consistent with the stated inclusive ranges:

CF300:2×6=12,
CF259:2×7+7×6=56.

That checks enumeration, not the validity of the starting order. Likewise, evolution through order seven may be justified by internal transformations and dependencies; it should not be shortened merely because the requested masters stop at order zero.

Recommendation: keep the adapter, inspect which of the above arguments justifies its output lower bounds, and add the two coupled regressions plus the K
i
	​

<L
i
	​

 zero case. Unknown bounds remaining unresolved and assumed bounds remaining conditional are correct decisions.

The rule

K
i
	​

=N−val
ϵ
	​

c
i
	​


is appropriate for the declared coefficient-table scope. Your exclusion of unspecified endpoint, renormalization, and PDF operations is necessary and should remain explicit.

3. Sampled negatives: retain the optimization and defer stronger certification

One valid left witness is sufficient to prove inconsistency of the sampled linear system. Computing its full left nullspace is unnecessary:

λ
T
M=0,λ
T
v

=0

already supplies the contradiction.

The useful low-cost check is to verify these identities modulo the sampled prime against the original sampled equations, or the original supported row subset—not merely an already row-reduced matrix. If your new assertions and runtime path already do that, no additional witness machinery is needed.

One optional structural regression is also inexpensive:

Whenever the assembled right-hand side C
b
	​

 is identically zero, the residue-only system is homogeneous, so R=0 must be accepted as consistent.

That catches assembly/classification errors. It does not apply indiscriminately to non-adjacent blocks, where C
b
	​

 need not vanish.

Neither check upgrades the result to a characteristic-zero no-go. In particular, one left witness does not establish a characteristic-zero rank upper bound; the historical 188/189 result in 192 columns remains outside the automatic full-column-rank certificate.

Do not delay the family campaign for constant-shift nullspace construction or witness lifting. Keep the current sampled scope, including its field/branch assumptions, and reserve stronger promotion for a later bounded task.

The priorities are therefore: stop further CF259 canonicalization, verify the adapter’s boundary-to-output lower-bound justification, run the fresh complete wave, and retain honestly scoped sampled negatives. The lower-bound check protects the requested mathematics; more canonicalization or stronger negative certificates do not presently improve the completed deliverable.