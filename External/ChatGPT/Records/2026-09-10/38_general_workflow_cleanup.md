# General workflow cleanup review

Verified model: gpt-6-pro; outgoing request HTTP 200.
Conversation: 6aa2e32f-d030-83e8-ba05-fba7933c5ed3.

## Question

Please review a bounded maintenance refactor of FeynFacet after the SIDIS NNLO campaign. This is an architecture/invariant review, not a request to change the mathematics. Use GPT-6 Pro. Production remains generated diagrams -> cut IBP -> master differential equations -> physical boundaries -> explicit solutions -> distributions/renormalization. References stay validation-only.

Observed duplication:
1. Coefficients/PartonicResults.wl owns recursive per-axis Delta/Plus/Regular epsilon records; scalar flattening lives unnecessarily in Numerics/PartonicResults.wl. Numerical VerifyPartonicPoleCancellation and finite extraction FinalizePartonicResults share that latter file. NLO scattering and current drivers each separately check exact pole cancellation and reject unresolved integral expressions with three inconsistent blacklists.
2. Projects/NLO.wl owns shared request/identity/path helpers also called privately by ~20 current and NNLO drivers. ReadProcessCard[directory,name] re-reads/merges the card even immediately after ReadContributionCard; scripts independently reconstruct component paths. Current/scattering NLO Born dependencies have duplicate epsilon/path/reuse code with slightly different validation; scattering assemble mode can regenerate missing Borns, current assemble mode rejects them.
3. Python final-assembly runner hardcodes CPUs 0-7, lacks the process-group interruption cleanup used by the current-stage runner, and checks a completion sentinel differently.

Proposed boundary:
A. Keep one recursive result schema. Put scalar indexing with structural result code. Put shared finalization and exact pole-zero checking in Coefficients/PartonicFinalization.wl; keep the numeric evaluation overload in Numerics. Both checks produce the same record with explicit Method/AlgebraicIdentityProof distinction and exact input pole coefficients, so finite extraction source-matches identically. Do not replace exact NLO proofs with numerical ones, or do a fresh expensive symbolic simplification just to verify. Require stored input starts at its known Laurent lower bound; preserve finite truncation as a truncation, never invent unknown coefficients.
B. Expose compiled-card process/request access once and move shared project helpers out of NLO. Share Born dependency resolution/loading/generation; assemble mode must never regenerate. Contribution algorithms remain separate where physics differs.
C. Share small Python Wolfram runner infrastructure for affinity, completion sentinels, strict startup-only retry and whole-owned-process-group cleanup. No general workflow DSL, generic plugin registry, compatibility aliases or process-specific exceptions.

Please challenge this scope. What mathematical invariants could this refactor accidentally weaken, especially vector-valued structure functions, multiple endpoint axes, Laurent coverage and exact-versus-numerical certificates? Suggest only concrete issues worth addressing now; avoid suggesting broad redesign or further physics tests with no changed physics.


## Pro response

A–C are appropriate boundaries for this refactor. The main qualification is that shared storage and shared control flow must not imply interchangeable mathematical meaning. In particular, “all stored poles passed” is weaker than “every required pole of every requested component and distribution sector was checked.”

On the design as described, these are the concrete issues I would address before merging.

1. Scalar indexing must preserve components and complete endpoint paths

Moving scalar indexing into Coefficients/PartonicResults.wl is correct. Its contract should be lossless structural traversal, not mathematical scalarization.

A scalar coefficient needs an unambiguous key equivalent to

(structure-function component, complete endpoint path, ϵ power).

The endpoint path must retain each axis’s identity, its Delta/Plus/Regular branch, and the logarithmic index for each plus term. Associated axis conventions must remain attached to the record. For example,

δ(1−x)D
1
	​

(z),D
1
	​

(x)δ(1−z),δ(1−x)δ(1−z)

must never collide through a shortened key.

For vector-valued structure functions, a pole vector

ϵ
−1
(f,−f)

does not cancel merely because its components sum to zero. Likewise, coefficients in different distribution sectors cannot cancel through a numerical sum over flattened entries. Check scalar coefficients individually after the existing assembly and distribution collection, without introducing a new projection or distribution normalization.

Two less obvious requirements matter here:

Regular is local to an axis. Being regular in the first axis does not terminate traversal when another endpoint axis remains.

Zero and missing structure are different. An explicitly zero vector component retains its component identity; an absent requested component is not automatically zero. An empty traversal cannot establish success unless the validated schema identifies the object as a genuine zero result.

Both verification methods and finite extraction should use this same traversal. The finite result must reconstruct the original component and axis structure, rather than return an unlabeled flat list.

2. Laurent coverage needs an upper bound as well as a lower bound

Your lower-bound requirement is essential, but it needs a precise interpretation. For each scalar leaf, the contract is effectively

F
ℓ
	​

(ϵ)=
n=L
ℓ
	​

∑
U
ℓ
	​

	​

c
ℓ,n
	​

ϵ
n
+O(ϵ
U
ℓ
	​

+1
),

with a justified absence of powers below L
ℓ
	​

, and complete knowledge of the retained interval.

The certified lower bound is not necessarily the first nonzero stored power. Leading coefficients can be known zeros. Sparse omission may mean zero only where the schema explicitly guarantees that meaning; it cannot turn an unavailable coefficient into zero.

The coverage metadata must describe the object being finalized—not an earlier master expansion before endpoint distribution expansion, normalization, or counterterm multiplication. Coefficients indexed by an epsilon power must also have no unaccounted epsilon dependence left inside them.

The upper-bound issue is particularly important for shared Born loading. For two series starting at powers a and b, known through U
A
	​

 and U
B
	​

, respectively, their product is conservatively known through

U
AB
	​

=min(U
A
	​

+b, U
B
	​

+a).

Thus a Born contribution

B(ϵ)=B
0
	​

+ϵB
1
	​

+O(ϵ
2
)

multiplied by 1/ϵ contributes B
1
	​

 to the finite term. A cached B
0
	​

-only result is insufficient even when it reproduces every supplied pole correctly.

The same observation applies to epsilon-dependent component transformations: in general,

[ϵ
0
](P(ϵ)F(ϵ))

=P(0)[ϵ
0
]F(ϵ).

Do not move finite extraction across such transformations or counterterm operations merely because both now use a shared helper.

For implementation, preserve the retained interval when converting a series into coefficient records. Wolfram’s SeriesData explicitly represents omitted higher-order terms, while conversion with Normal truncates them; the resulting ordinary expression cannot by itself distinguish a truncated expansion from an exact polynomial. 
Wolfram Documentation Center

A finite coefficient may be extracted from sufficient coverage; an unknown tail must remain unknown. No extra symbolic calculation is needed to enforce that distinction.

3. One certificate schema is sound; one undifferentiated success condition is not

Keeping Method, AlgebraicIdentityProof, and the exact input pole coefficients is the right direction. The critical remaining issue is how consumers interpret that record.

For a caller requiring exact cancellation, the acceptance condition should amount to

complete pole coverage ∧ source match ∧ successful check ∧ algebraic identity proof,

with a consistent exact Method. A generic "Passed" -> True is insufficient.

The numerical overload may retain its existing finalization policy, but its output must retain the numerical status. It must not become an exact certificate through shared record construction, serialization, or default options. Similarly, an unsuccessful exact attempt must not silently fall back to numerical checking while preserving the exact caller’s success contract.

Source matching must include the keyed mathematical scope

Compare the complete keyed pole slice, not just a list of values. Matching must retain component identities, endpoint conventions, the checked Laurent interval, and any assumptions or branch conditions needed by the check.

The numerical method should store numerical evaluations separately; it must not overwrite InputPoleCoefficients with sampled values or zeros.

Use deterministic structural matching of the exact stored source, not a fresh equivalence proof. SameQ distinguishes structural identity from mathematical equivalence, which is the appropriate distinction for checking whether a certificate refers to the supplied representation. An algebraically equivalent but differently represented source can require a new check rather than trigger expensive simplification during finalization. 
Wolfram Documentation Center

There is an important scope limit: a pole certificate need not certify the finite coefficient. Two results with identical complete pole slices but different finite coefficients can legitimately share the same pole-cancellation statement. Finalization must extract the finite coefficient from its actual input and independently enforce that coefficient’s coverage and explicitness. Requiring whole-result algebraic equivalence would add work without strengthening the pole statement.

Preserve the existing exact proof operation

Move the current exact normalization/checking logic; do not replace it with a more permissive zero predicate or run a second expensive simplification merely to confirm its result.

In particular, default PossibleZeroQ is unsuitable as the definition of an algebraic identity certificate: Wolfram documents that it uses symbolic and numerical methods and can return true for nonzero expressions. Its guaranteed exact-algebraic mode has a narrower scope and is not a general substitute for your existing symbolic checks. 
Wolfram Documentation Center

For numerical checking, failed or unevaluated leaves must remain failures or inconclusive results—not disappear from the checked set. Evaluate scalar coefficient functions, not distributions pointwise, and retain the existing precision and tolerance policy.

Finally, keep the dependency direction one-way: Numerics depends on structural results and finalization; exact finalization does not require Numerics. Loading the numerical overload must not alter exact dispatch or defaults.

4. Unresolved-expression rejection and pole cancellation are separate obligations

Centralizing the three inconsistent rejection predicates is worthwhile, but mechanically taking their union could also change the accepted mathematics.

The shared check should distinguish unresolved computational objects from accepted explicit solution representations. An unevaluated master-integral placeholder is not equivalent to a fully specified finite nested-integral solution with resolved physical boundary data. A blanket prohibition on every integral-like head could accidentally reject your explicit-solution representation.

Apply the predicate to the retained result coefficients and their live solution dependencies. Do not reject a result because its preserved source expressions or unused auxiliary definitions still contain master integrals. Conversely, an apparently harmless named solution must not hide an unresolved dependency required by the retained coefficient.

Pole cancellation and explicitness must remain separate because either can hold without the other. An expression can have exactly vanishing poles while its finite coefficient still contains an unresolved master. Conversely, unresolved symbols can cancel completely in a pole coefficient without needing their individual values.

A particularly relevant Wolfram trap is broad use of Normal during this cleanup: beyond truncating series, it can convert associations and remove the condition wrapper from ConditionalExpression. Use head-specific conversion where needed, and preserve conditions rather than treating normalization as harmless formatting. 
Wolfram Documentation Center

This needs one shared predicate for the currently supported representations—not a new registry of arbitrary symbolic functions.

5. Share compiled-card access and Born mechanics, not contribution semantics

The compiled-card change should establish one straightforward invariant:

Within an invocation, the process view, request view, identity, and component paths all derive from the same already-merged card.

Accessors should not reread the filesystem, reapply defaults, or perform a second merge. Otherwise moving the helpers can change override precedence even when every individual helper looks equivalent.

Preserve the existing precedence explicitly, and prevent contribution-local overrides from contaminating another contribution’s process view. Path construction should consume this resolved identity; scripts should not reconstruct a second identity from names or directory fragments.

For Born dependencies, separate what is required from how it is obtained. The contribution algorithm should continue to determine its Born request and required epsilon coverage. The shared helper should resolve the location, load and validate an available result, or invoke the appropriate existing generation route when the mode permits it.

The reuse criterion should be:

compatible Born identity+stored coverage contains required coverage,

not “a file exists,” and not exact equality of the stored and requested truncation depths.

Compatibility must preserve the distinctions already relevant to the current/scattering drivers: ordered partonic roles, requested polarization and structure-function basis, dimensional projector/normalization conventions, and applicable scheme conventions. Do not collapse two records merely because their four-dimensional Born expressions agree.

Generated and reused Borns must pass the same validation. This is where the slightly different current implementations should be reconciled deliberately rather than selecting whichever implementation is easiest to move.

For assemble mode, missing, incompatible, or insufficiently deep Born data must produce an actionable dependency failure. The common helper must enforce this itself; a driver-only check leaves a regeneration path open through another caller. Generation should be unreachable in that mode.

6. The runner extraction is useful, with three strict lifecycle rules

Affinity should respect the inherited allocation. On supported systems, select from the CPUs returned by os.sched_getaffinity(0), rather than assuming CPU identifiers start at zero. That API reports the set to which the current process is restricted. An explicit affinity request should be checked against that set; without an explicit restriction, preserving the inherited affinity is a sensible default. 
Python Documentation

Completion must belong to the current attempt. Use one sentinel contract shared by the runners: exact matching, a clean or attempt-specific source, and emission only after the required outputs have been written successfully. Require a successful exit as well. A stale marker must not rescue a failed attempt, and a zero exit must not rescue a missing completion marker. Artifact reuse and execution completion are separate questions.

Retry requires positive evidence of a startup failure. Absence of the completion sentinel does not establish that work never began. Recognize only the existing explicitly retryable pre-work failures; place a script-entry marker before project work, and never retry after entry or on user interruption. Complete cleanup before launching another attempt.

For the POSIX cleanup implementation, use an owned session/process group, signal that group, and finish handling the direct child and its output. Python provides start_new_session for session creation and os.killpg for group signaling; Popen.communicate() timing out does not itself kill the child. 
Python Documentation
+2
Python Documentation
+2

Do not stop group cleanup merely because the launcher has exited: other group members may remain. Also keep the guarantee accurately scoped to the owned group, rather than claiming that group signaling reaches independently detached descendants. No general process-tree framework is needed here.

Merge criteria

I would use a small set of refactor-level checks:

Changed boundary	Decisive regression case
Recursive indexing/finalization	A two-component, two-axis record round-trips exactly; opposite poles in different components do not cancel.
Coverage	Missing required orders are rejected; an epsilon-suppressed Born term multiplied by a pole contributes to the finite result.
Certificates and explicitness	A numerical pass cannot satisfy the exact gate; a source-scope mismatch fails; a live unresolved finite dependency is rejected.
Cards and Born dependencies	All views use the same merged card; richer compatible Born data are reusable; assemble never calls generation.
Runner lifecycle	A stale sentinel cannot pass; post-entry failure cannot retry; interruption removes surviving owned-group workers.

The refactor should centralize interpretation and enforcement, not strengthen or weaken the mathematics being accepted. With those conditions, the proposed file moves and small shared helpers are sufficient; the contribution algorithms and production/reference separation can remain untouched.


## Implemented follow-up

Shared scalar indexing retains every axis branch and structure-function label.
Both pole checks require complete Laurent coverage and match source conventions.
Exact NLO callers explicitly require algebraic evidence. Positive epsilon slices
retain the finite Laurent lower bound. Finalization stays in Coefficients;
numerical evaluation stays in Numerics.

Compiled-card process/request views and Born dependencies are shared.
Assemble cannot regenerate. The Python runners use current-attempt output,
strict pre-entry startup retries, inherited CPU allocations and owned-group
cleanup, including workers surviving an exited launcher.
