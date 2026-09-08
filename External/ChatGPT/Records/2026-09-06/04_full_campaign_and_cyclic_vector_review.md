# Full campaign and cyclic-vector review

## Question

Follow-up to your pilot/order review in this conversation. The transported lower cutoff min_j(tau_ij+beta_j) is implemented using the existing valuation matrix, with both coupled counterexamples and the K<L zero case passing. The five existing outputs' requested ranges also pass that bound, so no reintegration was needed. Matching-input resumes can reconstruct missing lower master coefficients from the saved explicit finite evolution; execution tests cover this.

The clean six-family pilot now has complete explicit solutions, using current coefficient-table demands and fresh DEs. DE + finite computation seconds:
CF3 11.218 + 0.964;
CF48 159.336 + 13.380;
CF50 80.879 + 83.434;
CF299 69.777 + 4.469;
CF384 87.276 + 5.893;
CF407 123.108 + 7.491.
Total 288 master coefficients, 5.95 MB. The elapsed pilot included debugging/recovery of a JSON operational summary; I am not claiming an uninterrupted 173-second wave.

CF50 preparation was resolved by rewriting exponentials of ArcTanh/log sums using principal-log identities, expanding polynomial radicands but never combining square roots. CF407's DSolve vector failed its equation even though one proposed scalar component provided valid solutions. We use the standard cyclic-vector matrix rows l_0=e_i, l_{k+1}=d l_k+l_k A to reconstruct columns from f,f',...,f^(n-1), then require exact vector identities and nonzero determinant. This is a bounded fallback; all original kinematic identities remain checked. Whole CF407 preparation now completes in 2.72 seconds. Six new controls and the existing 43 finite-solution tests pass.

I have launched fresh DE -> explicit finite solutions for all 91 current families through the same pool, six concurrent families, one Kira thread each, eight shared cores, 900-second phase limits, durable per-family outputs and continued processing after independent failures. CF303 explicitly uses its validated homogeneous preparation, CF269 its existing point-specific recurrence; these are process specifications, not core-family branches. Full canonicalization and physical endpoint/renormalization/PDF coverage are not inferred.

Please challenge any remaining correctness or stopping-policy issue in these specific choices. Current repository: https://github.com/CongyueZhang2002/factorization-and-loops ; these edits remain local, so do not assume the remote includes them.


## Pro response

The production route is justified, and the transported-bound correction resolves the principal order-completeness issue raised earlier. The cyclic-vector fallback is mathematically valid with the acceptance checks you describe. I would continue the campaign, not reopen full canonicalization or delay it for stronger negative certificates.

The remaining points to verify are narrow: branch-consistent preparation and boundary normalization; invertibility of the reconstructed fundamental matrix; and genuinely cumulative timeout enforcement. This is a review of the reported local behavior, not certification of the unseen implementation.

1. Lower cutoffs and saved-evolution recovery: no further change indicated

With

L
i
	​

=
j
min
	​

(τ
ij
	​

+β
j
	​

),

where τ includes preparation, evolution, and reconstruction into the requested master basis, the planner now distinguishes boundary lower bounds from transported output lower bounds correctly.

The coupled counterexamples and K<L test address the specific failure modes. If the five existing outputs already contain every coefficient in the resulting requested ranges, no reintegration is warranted merely because the adapter changed.

Reconstructing missing output coefficients from saved explicit finite evolution is also legitimate: it is further coefficient extraction from an already computed solution, not a lazy replacement for solving the DE. The relevant condition is that the saved evolution and boundary selectors contain the terms needed for those coefficients. Your matching-input execution tests are the appropriate place to establish that.

Two existing distinctions should remain intact: assumed boundary bounds produce conditional results, and extending output coverage must not silently enlarge the allowed boundary-constant class. Nothing in your update suggests either distinction has been lost.

2. CF50: the rewrite is acceptable, but “never combine square roots” is not the entire branch condition

Expanding a polynomial inside an unchanged radicand is harmless:

P(z)
	​

⟼
ExpandP(z)
	​

.

The argument of the root has not changed.

For exponential simplification, a safe principal-branch form is

exp(b+
j
∑
	​

a
j
	​

Logq
j
	​

)=e
b
j
∏
	​

q
j
a
j
	​

	​

,q
j
a
j
	​

	​

:=exp(a
j
	​

Logq
j
	​

),

on the declared domain with the same logarithm determinations. This does not authorize replacing the sum of principal logarithms by the logarithm of a product, or flattening nested noninteger powers. Wolfram explicitly documents that unrestricted power expansions require assumptions and can change values. 
Wolfram Documentation Center

Likewise, the principal-log representation

ArcTanhz=
2
1
	​

[Log(1+z)−Log(1−z)]

is suitable on the common cut domain; values on the cuts require the chosen boundary limit. Principal values at independently sampled points must not be confused with analytic continuation along a path. DLMF states the cut-domain restriction and the different upper/lower boundary values explicitly. 
DLMF

The bounded check worth retaining is a branch-sensitive control, not a larger simplifier. If the six new controls already include nonreal arguments or both sides of a relevant cut, plus the actual base-point convention, no additional test campaign is needed. Testing only a positive-real region would leave the branch issue largely untested.

A useful relaxation: a different valid fundamental basis is not an error

You do not necessarily need the rewritten homogeneous matrix to equal the original DSolve expression entry by entry.

If U and V are invertible and solve the same homogeneous system in all relevant variables, then, directly,

d(U
−1
V)=0,

so

V(z)=U(z)C

for a kinematics-independent invertible matrix C. Consequently,

V(z)V(z
0
	​

)
−1
=U(z)U(z
0
	​

)
−1
.

Thus a constant phase or constant basis change introduced during preparation is harmless when the inverse, boundary map, and forcing transformation are updated consistently. The necessary object is the correctly normalized evolution, not a particular DSolve presentation.

What is not harmless is switching branches inconsistently between the base point, the integration kernel, and the endpoint. Exact differential identities alone can miss a constant sheet mismatch; normalization and the declared continuation convention supply the missing information.

3. CF407: the cyclic reconstruction is a sound general fallback

For the homogeneous system

Y
′
(t)=A(t)Y(t),

take

ℓ
0
	​

=e
i
	​

,ℓ
k+1
	​

=ℓ
k
′
	​

+ℓ
k
	​

A,C(t)=
	​

ℓ
0
	​

ℓ
1
	​

⋮
ℓ
n−1
	​

	​

	​

.

Then f=e
i
	​

Y satisfies

	​

f
f
′
⋮
f
(n−1)
	​

	​

=C(t)Y(t).

This is the standard cyclic-vector construction underlying uncoupling of first-order systems into scalar equations. 
arXiv

Given scalar candidates f
1
	​

,…,f
n
	​

, form

W
kj
	​

=f
j
(k)
	​

,k=0,…,n−1,U=C
−1
W.

The decisive conditions are

U
′
=AU,detU

≡0.
	​


They establish that U is a fundamental matrix on its regular domain. The incorrect DSolve vector is then irrelevant. Using a component of that output as a candidate source is legitimate because the reconstructed result is independently checked against the original equation. Direct substitution is also the verification procedure recommended in Wolfram’s DSolve documentation. 
Wolfram Documentation Center

Three details deserve explicit interpretation, but not another algorithm:

The determinant must be that of U, not only C. Invertibility of C establishes that the selected component is cyclic. It does not establish independence of the scalar candidates. Repeated or dependent scalar solutions give singular W and therefore singular U.

Check the matrix against the homogeneous block it is intended to solve. If this is preparation for A
0
	​

, the preparation identity is dU=A
0
	​

U, followed by the existing acceptance checks for the full finite solution. There is no need to demand that U itself solve the full epsilon-dependent connection.

Failure of one cyclic component is only a fallback failure. A singular C does not imply that the system lacks explicit solutions. Zeros introduced through C
−1
 can also be apparent singularities of the representation rather than singularities of the original DE. Use another inexpensive component or the existing alternative route; do not turn this into an unbounded cyclic-vector search.

Since you already check all original kinematic identities, the usual danger of obtaining an integration “constant” that is actually a function of a second kinematic variable is addressed. With the stated checks, the 2.72-second preparation is a successful replacement, not a provisional workaround requiring a second solver.

4. The launch is supported; the 900-second limit needs one operational qualification

The reported phase times sum to 647.225 seconds across six families, with a mean complete-family time of 107.871 seconds and a largest sum of 172.716 seconds. These are calculations from your reported durations, not an uninterrupted-wave measurement or a sum of CPU time.

They support launching the broader campaign. They do not support changing its scope or claiming that the remaining families have the same cost distribution.

Make 900 seconds cumulative over the phase

The phase deadline should include its internal solver candidates, Kira closure rounds, normalization attempts, and bounded fallbacks. It must not restart each time a helper retries.

At the extreme, even two 900-second phases for every family would consume

6
91×2×900
	​

=27,300 s≈7.6 hours

of idealized six-worker occupancy before additional overhead. Therefore, per-phase limits bound individual attempts, not the desired campaign duration.

I would retain the existing caps for the first pass, but apply this stopping policy:

Event	Action
A candidate fails its equation check, but the bounded fallback succeeds	Accept the verified replacement and continue. No global intervention is needed.
A phase times out or has no supported homogeneous solution	Preserve the DE and any valid intermediate result; mark the family incomplete and continue. Do not automatically double the budget or requeue the same attempt.
An accepted output fails an order, normalization, branch, or original-DE check	Suspend the affected shared route and review outputs that used it. Continue demonstrably independent routes.
Timeouts leave active subprocesses, memory grows without release, or workers use inconsistent definitions	Pause dispatch and repair the execution state before adding work.

One practical distinction is important: a timeout exception is not necessarily process termination. For example, Python’s Popen.communicate(timeout=...) does not kill the child on timeout; cleanup must terminate and reap it. The coordinator should confirm that timed-out Kira work no longer occupies the shared resources before reusing that capacity. 
Python documentation

Six concurrent families with one Kira thread each remain a reasonable configuration. The eight-core limit should still include helper and native-library threads. There is no reason to change concurrency solely because one family is slow; change it when aggregate resource measurements show contention.

Because the edits are local and the pool is persistent, also avoid changing loaded core definitions midway through a job. Apply fixes at controlled worker boundaries and rerun only affected results. Atomic input snapshots are useful, but they do not by themselves prevent an active worker from seeing a changed implementation if it loads additional code during execution.

5. CF303 and CF269 specifications are appropriate—with mathematical input matching

Supplying a homogeneous preparation or a dimensional recurrence through a process specification is compatible with a general framework. Generality requires a common interface and common acceptance conditions, not that every family rediscover all reusable mathematics from scratch.

For CF303, the relevant match is to the current ordered basis, normalization, homogeneous connection, and branch/base-point convention—not merely the family name or matrix dimension. Reuse the existing defining-identity check; do not recompute an expensive preparation already known to apply.

For CF269, a point-specific recurrence can supply the boundary bounds at its declared point, after which your implemented τ+β propagation supplies the transported cutoffs. It does not need to become a generic-kinematics recurrence. The important prohibition is silently moving the base point while retaining the old point-specific bound.

Neither case requires a new format or a core family-name branch.

6. Keep scientific completion separate from summary recovery

The JSON-summary incident should remain an operational failure, not a reason to recompute mathematics. A valid, complete, matching-input explicit solution should survive regeneration of its operational summary.

Conversely, a success summary must not substitute for the actual requested coefficient coverage and the retained acceptance result. Your durable outputs and tested recovery path are the right basis for this distinction.

My recommendation is to let the current campaign continue. The only immediate checks are whether CF50’s controls cover branch-sensitive values and normalization, whether CF407’s determinant test applies to the reconstructed U, and whether phase deadlines include all retries and actually release subprocess resources. If those are already true, no further pre-completion work is warranted. Full canonicalization, stronger sampled-negative certificates, and physical endpoint/renormalization/PDF completion remain separate tasks.