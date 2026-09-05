# Private Hardening Review

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation with its full history. This is an independent code-review turn in that same conversation; do not create or suggest a new chat.

Please review the actual current package code, not merely the claims in this prompt. The public source is:

https://github.com/CongyueZhang2002/factorization-and-loops/tree/main/FeynFacet/Private

GitHub `main` and the attached source archive are pinned to commit
`f3738b1eac5d00537630dffb248855f3bc22975c`. The archive SHA-256 is
`15fd1c9610457315c13dbfa42a5ca431b68a76493652e7e1261bfb1e616162b4`.
It contains all `FeynFacet/Private`, the sector driver, the complete test tree,
Fable's review request, HANDOFF, and the hardening measurement README/summary.

Context: since Codex's earlier audit, Fable merged two waves:

- `366deac`: serial-stage telemetry, prepare deadlines, failed-interning repair,
  and top-level compile-option forwarding.
- `fbd856f`: cache/provenance hardening, V2 forcing-channel sealing, compact-dlog
  admission, byte-bounded caches, compile deadlines, recursive rank-3 tower
  inversion, resume gates, persistence, and new adversarial tests.

Fable reports 86 regression suites: 85 green, 1 diagnostic, 0 red, and measures
CF300 (12,9) preparation at 1439.7 seconds, of which 1400.5 seconds (97.3%) is
eight structurally distinct algebraic forcing-entry decompositions. It proposes
finite-field evaluate/interpolate/lift for `multiquadraticFieldDecompose`, with
mandatory exact recomposition and symbolic fallback.

Perform an adversarial, independent review of the code from four angles:

1. **Correctness.** Verify cache keys and seals, compact-dlog admission,
   recursive tower algebra, deadline/resume semantics, modular resume checking,
   failure typing, ABI compatibility, and whether tests genuinely establish the
   claims. Look for counterexamples, false-positive certificates, mutated-input
   acceptance, stale-cache reuse, and deadline paths that still cannot stop.

2. **Efficiency.** Determine whether any major speedup remains beyond the
   proposed modular evaluate/reconstruct route. Challenge the 97.3% attribution,
   distinguish work moved between stages from work removed, and identify the
   best algorithmic route for the eight ~140k-leaf entries. Assess interpolation
   variables, sparse/rational reconstruction, extension-field sampling,
   denominator discovery, batching/vectorization, parallelism, exact acceptance,
   and failure/fallback cost. Say explicitly whether re-timing the old commit is
   worth the kernel time.

3. **Generality.** Search for family identifiers, hard-coded current-family
   assumptions, fixed root rank/grade/variable names, process-specific paths,
   accidental two-variable assumptions that are undocumented, and behavior that
   works only for CF259/CF300/CF303. The implementation should remain general
   across easy rational families through hard rank-3 multiquadratic families
   described through the package's generic kinematic data (commonly s,t,u),
   without embedding a family inside `Private`.

4. **Conciseness and maintainability.** Identify incremental-rewrite complexity,
   duplicated abstractions, unnecessary compatibility layers, stale comments or
   options, unreachable/ghost code, redundant validation passes, and functions
   that can be substantially simplified or deleted without weakening contracts.
   Separate safe deletion/streamlining from risky redesign.

Also answer Fable's six questions in
`External/CodexExchange/fable_review_request_2026-08-25_2300.md`, especially:

- whether any prior blocker remains open;
- whether the compact-dlog certificate plus exact fallback is sufficient or the
  dlog relation must be checked unconditionally;
- whether `ResumeGate -> ModularThenExact` is the right default;
- design and required adversarial tests for modular decomposition;
- whether the old-commit timing should be repeated;
- every remaining improvement, including small cleanup, before family relaunch.

Output requirements:

- Lead with a clear GO / CONDITIONAL GO / NO-GO verdict for relaunch.
- List findings by severity and cite exact archive paths and line numbers or
  uniquely identifying function names. Do not infer correctness from comments.
- Distinguish verified defects from risks and optional improvements.
- Give concrete closing tests for every blocker.
- End with a non-overlapping prioritized action list: correctness blockers,
  major performance work, then cleanup/deletion opportunities.
- Be candid if the full 34-file directory is too large to exhaustively inspect;
  state what you actually opened and do not claim comprehensive coverage.

This is independent review evidence. Do not defer to Fable's or Codex's prior
conclusions, and do not suggest a whole symbolic production-family rerun as a
substitute for targeted tests.

## Pro response

CONDITIONAL GO — do not relaunch from f3738b as-is

The core algebra, finite-field machinery, recursive rank-three inversion, cache bounds, and default exact-after-modular resume policy are substantially hardened. I did not find a mathematical defect in the XOR-grade algebra or recursive quadratic-tower inversion.

I did find four relaunch-level contract gaps:

The V2 forcing-channel “seal” authenticates a self-consistent payload, but does not prove that the channels decompose the forcing; a fully re-sealed mutant is accepted. It also omits ordered root expressions/signs.

The compact-dlog certificate can be freshly minted for an incorrect letter/one-form pair and then bypass the exact dlog check.

The family deadline is not propagated into resume hydration or its replayed strip solvers; the regulator-factorization timeout can also leave brokered helpers running.

The sector driver still mutates Global`` and performs raw Get` on persistent kernels, bypassing the package’s hardened artifact reader.

These are targeted fixes, not reasons to redesign the pipeline.

I verified the archive SHA-256 exactly, confirmed its embedded commit, and independently confirmed that GitHub commit f3738b1eac5d00537630dffb248855f3bc22975c exists at the stated repository. I did not infer current correctness from the older overnight handoff, which explicitly described itself as in progress rather than a completed family certificate. 

codex_overnight_optimization_tr…

Review scope

The archive contains 130 files. FeynFacet/Private contains exactly 34 files and 50,743 source lines.

I performed repository-wide static scans over all 34 private files and deep-read the high-risk implementations:

MultiquadraticStripSolve.wl

MultiquadraticAlgebra.wl

FiniteFieldStripSolve.wl

FamilyRowGaugeResume.wl

FamilyRegulatorFactor.wl

FamilyEpsForm.wl

TransportCharts.wl

TaskBroker.wl

BlockEquationDeferred.wl

Scripts/family_epsform_sector.wls

I also inspected the relevant provenance, persistence, budget, generality, resume, and regulator-factor tests, Fable’s request, HANDOFF material, regression summary, and performance measurement README.

I did not line-by-line inspect all 50,743 lines or every assertion in all 86 suites. No Wolfram runtime was available in this review environment, so I did not rerun the suites. The reported regression artifact itself records 85 green suites, one diagnostic, and zero red, using a better-than-exit-code verdict classifier; that is credible evidence, but not an independent execution by this review.

Findings by severity
High — verified: forcing-channel V2 is not a semantic seal

Locations

FeynFacet/Private/MultiquadraticStripSolve.wl:478-555

multiquadraticStripForcingChannelContentHash

multiquadraticStripForcingChannelFingerprint

multiquadraticStripForcingChannelRecord

multiquadraticStripForcingChannelsAccept

Production use: MultiquadraticStripSolve.wl:3837-4041, 4218-4223

Incomplete adversarial coverage:
Tests/t_multiquadratic_provenance.wls:256-329

Counterexample 1: fully re-sealed wrong channels

Acceptance verifies:

H
content
	​

=H(Channels),

and

H
seal
	​

=H(forcing,root squares,dimensions,H
content
	​

).

It never verifies

Compose(Channels,roots)=forcing.

Consequently, the following logical sequence passes:

Mutate one channel.

Recompute ChannelsSHA256.

Recompute Fingerprint, or simply call
multiquadraticStripForcingChannelRecord on the mutated channels.

Submit the resulting record.

multiquadraticStripForcingChannelsAccept accepts it because all hashes now agree with the mutated payload.

The test at t_multiquadratic_provenance.wls:293-300 refreshes only ChannelsSHA256, deliberately leaving the old fingerprint, so it does not exercise this counterexample. The comments at MultiquadraticStripSolve.wl:3960-3965 claim that a mutated channel fails even if the checkpoint envelope is rebuilt, but the code does not establish that claim.

This is not a cryptographic-security objection. It is a semantic-correctness objection: an unkeyed self-hash proves that a record is internally uncorrupted, not that its channels are the decomposition of its forcing.

Counterexample 2: root-sign basis collision

multiquadraticStripForcingChannelFingerprint hashes the ordered root squares at lines 488-490, but not the ordered root expressions. For

r
2
=Δ,

the channel vector of an expression in basis {1,r} differs from its vector in basis {1,−r}, although the root square is unchanged.

The compile-core key correctly fixed this exact issue by including RootCanonicalExpressions at MultiquadraticStripSolve.wl:5104-5125. The forcing seal did not receive the corresponding fix. The forcing-seal tests use sealRoots = {} and therefore cannot expose it.

Impact

The direct multiquadratic solver’s best-effort characteristic-zero residual can catch this if reconstruction succeeds, and its terminal contract remains ModularConsistent / OneFormsNotCertified rather than package Solved. Therefore I am not claiming a demonstrated false final family installation.

The defect can nevertheless produce a wrong preparation, wrong compile cache, and false modular-consistency artifact. It invalidates the stated V2 provenance guarantee and must be closed before relaunch.

Required closing tests

Create a nonzero rank-one forcing and correct channels.

Mutate a channel, then recompute both hashes through the current record constructor.

Require typed refusal based on exact recomposition.

Replace r by −r with the same RootSquare; require typed refusal.

Permute two roots with unchanged squares; require typed refusal.

Verify both prepare and compile consumers reject all three mutants.

Required correction

At the first persistence/read boundary, require exactly

Compose(Channels,ordered roots)−forcing=0.

Also include ordered canonical root expressions and their ordering fingerprint in the cheap seal fingerprint. Cache a successful exact attestation by immutable artifact SHA so the exact recomposition is not repeated within one process.

High — verified: compact-dlog certificates are self-authorizing

Locations

Certificate:
FeynFacet/Private/MultiquadraticStripSolve.wl:1293-1356

multiquadraticStripLetterDLogCertificate

multiquadraticStripLetterDLogCertificateValidQ

Admission:
MultiquadraticStripSolve.wl:4807-4865

multiquadraticStripCompactDLogAdmission

Tests:
Tests/t_multiquadratic_provenance.wls:365-450

The code explicitly states at lines 1310-1312 that the certificate is “provenance, not a proof.” Admission nevertheless treats it as sufficient proof:

Wolfram Language
If[mode =!= "Exact" &&
    multiquadraticStripLetterDLogCertificateValidQ[...],
  Return[<|"Admitted" -> True, "Method" -> "CertifiedTag", ...|>]]

The certificate contains only:

source SHA;

hash of the letter;

hash of the supplied one-form.

It does not contain or verify

ω=dlogL.

A concrete counterexample is:

Wolfram Language
letter = 1 - x - y;
wrongForm = dlog[x y];

certificate =
  multiquadraticStripLetterDLogCertificate[
    letter, wrongForm, {x,y}, eps];

The certificate validates for that freshly supplied wrong pair because it was defined by hashing exactly that pair. CompactDLogAdmission -> "CertifiedOrExact" then returns Method -> "CertifiedTag" and never reaches the exact fallback.

The existing mutant test uses a wrong record without a certificate, so the fallback exact comparison correctly rejects it. The missing adversary is a wrong pair with a freshly recomputed certificate.

Impact

Again, later exact residual logic may catch the resulting wrong compiled system, and the direct multiquadratic route does not install OneFormsNotCertified results. But the compact compiler and its caches can operate on a false mathematical relation. The current test does not establish the claimed admission contract.

This also conflicts with the package’s otherwise correct promotion rule that closed one-forms cannot be treated as solved dlogs without verified potentials. 

codex_overnight_optimization_tr…

Required closing test

Construct a wrong pair, mint a fresh certificate with the current certificate function, and require:

Certified mode: typed rejection;

CertifiedOrExact: exact fallback followed by rejection;

entry compiler: Path -> "DecomposedForm", never compact-letter channels.

Required correction

Check the dlog relation unconditionally once per unique pair:

∂
x
	​

L/L=ω
x
	​

,∂
y
	​

L/L=ω
y
	​

.

Cache this exact verdict using the source SHA plus canonical hashes of L and ω. The certificate may then mean “this exact relation was previously verified,” but it cannot be minted by a function that merely hashes arbitrary inputs.

The extra two Together comparisons per unique letter are negligible compared with the measured algebraic decomposition cost.

High — verified: the deadline chain is incomplete
Resume hydration

Locations

FamilyRowGaugeResume.wl:807-819, 998-1008, 1178-1205

Driver call:
Scripts/family_epsform_sector.wls:965-974

familyRowGaugeHydrateResume has a Deadline option and checks it between strips. However:

The sector driver calls hydration without passing sectorDeadline.

Hydration’s calls to:

SolveEpsFormStripInFrame

SolveEpsFormStripFiniteField

do not forward resumeDeadline.

Therefore, in the actual driver:

resumeDeadline remains Infinity;

even if a caller passes a deadline directly to hydration, one replayed solver can run past it without seeing the deadline.

This is a verified wiring gap, not merely the unavoidable fact that one symbolic Together cannot be cooperatively interrupted internally.

Closing test

Use a stub replay solver that records its received options and blocks across the deadline:

Driver must pass the exact absolute sectorDeadline to hydration.

Hydration must pass the same deadline to both rational and multiquadratic replay solvers.

The result must be typed ResumeHydrationBudgetExhausted.

No subsequent strip may start.

Resume records completed before the stop must remain usable.

High — verified resource-safety gap: regulator timeout can orphan helper tasks

Locations

FamilyRegulatorFactor.wl:470-560

FamilyRegulatorFactor.wl:861-870

TaskBroker.wl:122-167

familyRegulatorGradedMatrices may submit broker tasks and collect them. The outer regulator stage then wraps that entire call in:

Wolfram Language
TimeConstrained[
  familyRegulatorGradedMatrices[...],
  remainingTime,
  "TimedOut"
]

taskBrokerCollect has no cancellation operation. If the outer TimeConstrained aborts while helper jobs are queued or running:

pending queue files are not removed;

helper missions are not cancelled;

late results can still be written;

the local cleanup in taskBrokerCollect is skipped.

The nonce prevents a late result from satisfying a later handle, which is good. It does not stop the orphaned work or its resource use.

This is specifically important because Tests/t_solver_budget.wls correctly states that TimeConstrained does not bound task-broker helpers, yet the regulator path still uses that combination.

Required closing test

With a real or deterministic fake broker:

Submit helper work that writes a sentinel after a delay.

Expire the regulator deadline before completion.

Require a typed deadline result.

Require zero queued/running handles for that exact submission.

Require no late sentinel and no late result artifact.

Confirm unrelated broker jobs remain untouched.

Until cancellation exists, the safe alternative is:

Wolfram Language
"Parallel" -> False

whenever a finite regulator deadline is active.

High for persistent-pool relaunch — verified: driver still mutates Global`` and uses raw Get`

Locations

Scripts/family_epsform_sector.wls:40-55

family_epsform_sector.wls:157-166

family_epsform_sector.wls:213

The driver:

unprotects and clears a fixed list of `Global`` symbols;

creates Globalv, Globalw, Globaleps, Globalx, Globaly`;

normalizes arbitrary input symbols into `Global``;

loads artifacts with raw Get;

loads cached state with raw Get.

This bypasses FamilyArtifactRead, which was specifically hardened against valid values accompanied by benign messages and against context-sensitive loading.

It also remains incompatible with irreversibly Locked symbols on a reused kernel. The current long-running campaign has already encountered exactly that class of persistent-worker contamination.

Closing test

Run the complete driver bootstrap in a disposable reused kernel with:

locked/protected Globalx,y,eps`;

unrelated `Global`` definitions;

$ContextPath without `Global``;

a valid artifact whose Get emits a benign message;

a shadowing package export.

The driver must either:

hydrate into a fresh mission-owned context and leave `Global`` byte-identical; or

fail typed before mutating anything.

Correction

Use a mission-owned exact-symbol context and FamilyArtifactRead consistently. Rebind by declared roles, not symbol names. The fixed name list at lines 159-166 should not be the serialization ABI.

Medium findings
Resume seal authenticates fields it never compares

Location

FamilyRowGaugeResume.wl:482-539

The V2 strip-input seal includes:

VariablesHash

WriterSourceSHA256

but familyRowGaugeStripInputSealVerdict never compares either field with a current expected value.

It also hashes:

Wolfram Language
KeyTake[solvedBlocks, seal["SolvedBlockKeys"]]

without requiring the sealed key set to equal the expected prefix key set.

Default exact replay and the modular relation check provide much stronger downstream protection, so this is not presently a final false-accept path. It does mean the two named provenance fields are informational rather than enforced, and a shortened sealed key set can authenticate a subset.

Close by:

accepting current expected VariablesHash and writer/source protocol as verdict arguments;

requiring exact equality of solved-block key sets;

or removing fields that are not intended to constrain acceptance.

Native plan discovery is not resume-ABI compatible

Locations

FamilyRowGaugeResume.wl:872-890

solver-configuration helpers near the start of FamilyRowGaugeResume.wl

driver: family_epsform_sector.wls:141-145

Hydration rejects every plan-discovery backend except "Wolfram":

Wolfram Language
planDiscoveryBackend =!= "Wolfram"

FiniteFieldStripSolve.wl supports "FLINTAffineRREF" as a distinct, fail-closed plan-discovery backend. A strip solved with that backend cannot currently pass resume hydration under the same solver configuration.

The current driver explicitly chooses "Wolfram", so this does not invalidate the current default. It is an ABI blocker if the relaunch is intended to use the installed native plan-discovery adapter.

Close by: schema-versioning solver provenance to support both "Wolfram" and "FLINTAffineRREF", then replaying a native-plan checkpoint and rejecting backend/source/binary mutants.

Public family certifier silently truncates three variables to two

Location

FeynFacet/Private/FamilyEpsForm.wl:226-242

Wolfram Language
If[... Length[sourceVariables] < 2, ...];
sourceVariables = sourceVariables[[{1,2}]];

A three-variable list is not rejected; its third variable is silently discarded. The private modular function is tested as a two-variable statement, but the public CertifyFamilyEpsilonForm path is not tested for this truncation.

The package is internally and intentionally two-dimensional in many places—there are 49 explicit two-variable function signatures in Private. That is acceptable if made an explicit contract. Silent truncation is not.

Closing test: call the public certifier with {s,t,u} and a record whose untested dependence or third component matters. Require typed UnsupportedSourceVariableCount, not use of {s,t}.

For the present two-variable CF campaign this is not a mathematical blocker. It is a blocker to describing the package as generic in variable arity.

Correctness assessment by requested subsystem
Cache keys and cache bounds
Verified strong

Compile-core keys now include ordered canonical root expressions and squares:
MultiquadraticStripSolve.wl:5104-5138.

One-form intern keys include:

compact versus decomposed route;

letter provenance;

grade support;

admission mode.

Scalar/rational/core pools are byte-bounded and bypass oversized entries.

$Failed values are not retained as valid interned results.

Cache hits use SameQ collision semantics, not hash equality alone.

Compiled native backend source/binary identities are pinned.

Remaining weakness

The compact-dlog provenance used inside the one-form key is not semantically valid until the dlog defect above is closed. A precise cache key for a false relation is still a false cache entry.

The forcing record similarly has a precise self-hash but does not prove its underlying algebraic relation.

Recursive tower algebra

I found no correctness blocker in the recursive quadratic-tower inversion:

inversion descends one quadratic generator at a time;

norms are formed in the lower-rank field;

the old LinearSolve route remains as a fallback/oracle;

the result is accepted only after an exact product check.

The rank-zero, rank-one, rank-two, and rank-three algebra and differential tests are meaningful. The measured 15.76-fold speedup applies to one real entry only; it does not establish a stage-level speedup.

Keep the old route as an oracle for now. Removing it would save little and would reduce independent checking.

Compact dlog admission

Not closed, for the reason above. The exact relation must be checked at least once unconditionally.

The current downstream rule that direct multiquadratic results remain:

Status -> ModularConsistent
SolutionContract -> OneFormsNotCertified

is correct and prevents a closed-form-only result from being installed as solved.

Deadline and resume semantics

The top-level finite-field, multiquadratic prepare, compile, transport, and strip-construction stages have useful cooperative deadline checks. They are not hard preemption and should not be described as such: one opaque scalar decomposition may still run until its boundary.

The open paths are:

driver → hydration deadline not passed;

hydration → replayed solver deadline not passed;

regulator TimeConstrained → broker helpers not cancelled.

ResumeGate -> ModularThenExact itself is the right default once those plumbing defects are fixed.

Failure typing

Failure typing is generally improved:

V1 forcing seals are refused rather than upgraded;

malformed prepared artifacts fail typed;

unsupported root rank and undeclared radicals fail typed;

native backend does not silently fall back;

modular resume identifies the failed image;

direct multiquadratic results are not mislabeled Solved.

Remaining weak points:

raw driver Get can emit or partially evaluate outside the typed artifact interface;

broker timeout returns failed results but has no typed cancellation/cleanup state;

some internal decomposition routines still return bare $Failed, although public callers usually wrap them.

ABI compatibility
Strong

Little-endian root-grade ordering is consistently declared.

Root order is stable and explicitly fingerprinted in the compile core.

Rank-zero through rank-three grade lifting is implemented.

Family chart assignments have been moved out of package code into data registration.

No executable Private code embeds CF259, CF300, or CF303 as dispatch conditions; occurrences are comments and measurement narratives.

Open

forcing seal omits root expressions;

native plan-discovery provenance is not accepted by resume;

driver symbol rebinding is based on names and `Global`` rather than a role/schema ABI.

Efficiency assessment
The 97.3% attribution is valid; the per-entry story is not

The measurement supports:

1439.7 s=1400.5 s decomposition+39.2 s everything else.

Therefore targeting multiquadraticFieldDecompose is correct.

However, Fable’s statement that this consists of eight approximately 175-second, approximately 140000-leaf entries is contradicted by the measurement README itself:

the tested 72,021-leaf entry took 2.7 seconds;

it contributed only 0.19% of the 1400.5-second stage;

the other seven entries contributed 1397.8 seconds;

the README explicitly rejects linear extrapolation across the eight entries.

The total attribution is sound. Uniform-entry attribution is not.

Best algorithmic route
1. Reduce field rank before decomposition

Before the proposed modular reconstruction, classify each scalar’s active root subset and decompose over only that local subset, then lift into the global ABI.

The package already has the key abstraction:

multiquadraticLiftLocalChannels

Use it at forcing-entry preparation, with exact local and global recomposition. A rank-one or rank-two entry should not pay rank-three inversion merely because the surrounding strip has three roots.

This is likely the cheapest major improvement and is complementary to modular reconstruction.

2. Preserve and evaluate the expression DAG

The existing deferred architecture is the correct basis:

retain base + sum(products);

canonicalize/decompose leaves independently;

perform products in grade arithmetic;

compose only where required.

Whole-block Together destroys this advantage. That conclusion is already supported by the prior measured architecture. 

codex_overnight_optimization_tr…

For the eight hard entries, compile each expression into an immutable arithmetic DAG and evaluate the DAG over the finite-field grade algebra. Do not repeatedly substitute roots into a symbolic Wolfram expression at every point.

3. Sample in the grade algebra, not only at split points

At a prime p, evaluate directly in

F
p
	​

[r
1
	​

,…,r
d
	​

]/(r
i
2
	​

−Δ
i
	​

).

No modular square roots are needed. Invert denominator elements through the same recursive norm/tower algebra, rejecting samples where the norm is zero.

Use all Galois sign branches only as held-out validation at split points.

4. Reconstruct channel coefficients sparsely

For each channel

c
S
	​

(x,y,ϵ),

use:

sparse/projective support discovery rather than a blind bidegree rectangle;

separate univariate rational interpolation in ϵ where practical;

shared kinematic support across ϵ images;

a common denominator across channels when the structural DAG justifies one.

The earlier campaign’s projective-simplex result is a warning against inferring numerator support from separate denominator bidegrees.

5. Denominator discovery

Use, in order:

rational denominator factors already present in the DAG;

norms of algebraic denominator elements;

modular factorization and local valuation to determine multiplicities;

black-box rational reconstruction only for unresolved factors.

Do not symbolically expand a characteristic-zero rank-three norm merely to discover a candidate denominator if its modular images suffice.

6. Batch and parallelize by actual measured cost

The eight entries are mathematically independent but very uneven. A fixed equal shard is inappropriate. Use a dynamic queue:

one entry per task;

largest measured/estimated entries first;

per-task byte and time caps;

checkpoint each reconstructed entry separately.

Within one entry, evaluate all eight channels and all requested points in a packed/vectorized batch. Root-square evaluations, monomial tables, denominator factors, and epsilon powers should be shared.

Fable’s claim that there is “no loop to shard” is incorrect at the algorithmic level. There is an entry map; the problem is load imbalance, not absence of parallel structure.

7. Exact acceptance

A modularly reconstructed entry must pass:

held-out points, regulators, and primes;

split-sign/all-branch oracle;

root-order, root-sign, and root-rank mutants;

unsupported-radical and zero-norm rejection;

exact characteristic-zero recomposition:

S
∑
	​

c
S
	​

r
S
	​

−original expression=0.

For the last gate, clear denominators and reduce coefficientwise in the multiquadratic basis. That is generally safer than one giant global Together.

8. Failure and fallback cost

Fallback must be per entry, not per forcing block:

persist every successful reconstructed entry;

if support/degree/height bounds do not stabilize, symbolically decompose only that entry;

do not discard seven successful modular entries because the eighth fails;

never write a reusable cache before exact recomposition passes.

This prevents paying the modular discovery cost and then the full 1400-second symbolic cost again.

Is another major speedup available beyond modular reconstruction?

Yes:

local active-root decomposition and global lifting;

dependency-DAG preservation;

per-entry checkpointing and dynamic scheduling;

vectorized grade-algebra evaluation.

After those, modular evaluate/reconstruct is still the main route for the genuinely hard entries.

Further FLINT/RREF tuning is not a priority. The campaign already established that modular elimination is negligible once the system is assembled.

Should the old commit be retimed?

No.

The old 2710.9-second result is superseded, and a full old-commit timing does not affect the next algorithmic decision. It would establish a historical speedup magnitude, not improve the current bottleneck.

The useful measurement is instead:

time all eight entries separately on current code;

identify the dominant one or two;

run the modular prototype and symbolic oracle on those entries.

That gives both implementation guidance and a meaningful acceptance benchmark.

Generality assessment
Family-specific assumptions

I found no executable dispatch in FeynFacet/Private keyed to:

CF259

CF300

CF303

the current ppHX result directory.

Those names occur extensively in comments and performance narratives, but not as runtime family branches. The family-to-chart assignment table is externally registered rather than shipped inside Private, which is the correct architecture.

The sector driver remains project-specific—it discovers nnlo_de_<family>.wl, BlockClasses, and current result-tree conventions—but that is a control-plane concern rather than a hidden family inside the mathematical package.

Root rank

The strip engine is explicitly capped at rank three; regulator factorization has its own larger rank cap. These are legitimate scope boundaries, but they should appear in public capability documentation rather than only as internal constants and typed errors.

Variables

The implementation is generic in variable names, not in variable count.

The two-variable assumption is pervasive and mathematically coherent for the current systems. It should be documented as:

Two independent kinematic variables plus one regulator; additional symbols such as s,t,u must first be reduced to two independent coordinates.

Silent truncation in CertifyFamilyEpsilonForm must be replaced by an exact arity check.

Conciseness and maintainability
Safe streamlining before relaunch

Fix or delete unenforced seal fields

VariablesHash

WriterSourceSHA256

Do not retain fields that appear to constrain acceptance but do not.

Require exact solved-block key equality
in familyRowGaugeStripInputSealVerdict.

Remove stale resume commentary
around FamilyRowGaugeResume.wl:1058-1064, which still describes modular resume steps as nonexistent.

Replace driver raw loading
with FamilyArtifactRead and a shared symbol-role rebind utility.

Unify plan-backend protocol
across solver, checkpoint, and resume rather than hardcoding "Wolfram" in one layer.

Move long campaign postmortems out of implementation
MultiquadraticStripSolve.wl and BlockEquationDeferred.wl contain extensive dated CF-specific measurement narratives. Keep a short invariant comment and move the evidence to Design/Measurement documents.

Retire CompileShards
once its tests are replaced by tests against the actual per-entry decomposition API. Its fixed private timeout and incomplete contract are ghost complexity.

Retire V1 schema branches
only after an artifact inventory proves no supported checkpoint still needs typed V1 refusal. Do not remove them immediately.

Risky redesign to defer

Splitting the 7,627-line MultiquadraticStripSolve.wl into:

field algebra;

preparation/persistence;

compile caches;

modular reconstruction;

exact certification.

This is desirable, but should follow family relaunch, not precede it.

Consolidating duplicated multiquadratic decomposition between:

MultiquadraticStripSolve.wl

FamilyRegulatorFactor.wl

Their contracts and rank limits differ; merge only after parity tests exist.

Replacing bounded reset-all caches with an LRU. Current caches are bounded and correct; this is not relaunch work.

Removing the LinearSolve inverse fallback. Keep it as an independent oracle until the tower route has broader production mileage.

Answers to Fable’s six questions
1. Do any previous blockers remain open?

Yes.

Prior item	Review result
Ordered root expression/sign in compile-core key	Closed
Forcing-channel content authentication	Still open: self-resealed wrong channels pass; root signs omitted
Compact-dlog admission	Still open: freshly minted wrong-pair certificate passes
Cooperative prepare/compile deadlines	Mostly closed, but resume propagation and broker cancellation remain open
Compile sharding	Demotion is acceptable
Cache byte bounds and one-form key	Closed except dependence on invalid dlog certificate
Rank-three inversion	Closed; no algebraic defect found
2. Is the compact certificate plus fallback sufficient?

No. The exact dlog relation must be checked unconditionally once per unique pair.

The fallback is skipped precisely when the self-minted certificate validates. Hash consistency is not a proof of the dlog relation.

3. Is ResumeGate -> ModularThenExact the correct default?

Yes.

It gives a cheap independent corruption screen while retaining exact reconstruction as the acceptance decision. Keep:

ModularThenExact as default;

Exact as audit mode;

Modular as explicitly probabilistic/non-final and opt-in.

Fix deadline propagation and semantic seal checks first.

4. Is modular evaluate/reconstruct the right decomposition design?

Yes, with these required changes:

evaluate the expression DAG in the finite-field grade algebra;

reconstruct each entry independently;

exploit local active-root subsets;

use sparse/projective support;

share denominator structure and epsilon sampling;

accept only after exact coefficientwise recomposition;

checkpoint entries independently;

fallback symbolically only per failed entry.

Mandatory adversarial tests include:

all ranks zero through three;

rational-only entry;

every singleton and pair root subset lifted into rank three;

nonsplit finite-field points;

zero norm/zero denominator;

wrong root order and wrong root sign;

omitted and extra support monomials;

incorrect denominator multiplicity;

coefficient-height overflow;

one corrupted sample;

one corrupted reconstructed coefficient;

cache-source and ABI mutation;

unsupported radical;

exact recomposition failure;

partial-success plus one-entry fallback;

abort/resume after each interpolation phase.

5. Should the old commit be retimed?

No.

The in-kind explanation is adequate for the historical record. Current per-entry timing and a dominant-entry modular pilot are more informative and cost less.

6. Anything else before relaunch?

Before family relaunch:

close the forcing semantic-seal defect;

close the dlog self-certificate defect;

propagate/cancel deadlines correctly;

remove persistent-driver Global`` mutation/raw Get`;

add exact public two-variable arity rejection;

align native plan-discovery resume ABI if native discovery will be used;

run only the targeted closing suites below.

Required closing tests

These replace a production-family rerun.

Correctness blockers

Forcing semantic seal

fully re-sealed wrong channels;

root-sign mutant;

root-order mutant;

both prepare and compile consumers.

Compact dlog

freshly certified wrong pair;

wrong letter/right form;

right letter/wrong form;

cached exact admission reused only for the exact same pair.

Resume deadline

driver-to-hydration propagation;

hydration-to-rational replay;

hydration-to-multiquadratic replay;

completed-prefix persistence after stop.

Broker cleanup

timed-out regulator helper leaves no queue, handle, process, or late result.

Driver isolation

locked/protected `Global`` symbols;

benign Get message;

package shadow;

`Global`` unchanged before/after.

Variable arity

public certifier rejects three independent variables typed.

Compatibility gates

Native plan-discovery checkpoint hydrates under the exact same native source/binary/protocol and refuses each mutant.

Resume seal rejects:

changed variable role/hash;

changed writer/source protocol;

missing or extra solved-block key.

No whole symbolic CF300/CF303 rerun is required to close these code findings.

Prioritized non-overlapping action list
I. Correctness and relaunch blockers

Replace forcing self-hash admission with exact channel-to-forcing recomposition; include ordered root expressions.

Replace compact-dlog self-certification with one exact dlog check per unique pair.

Wire the absolute deadline through driver → hydration → replayed solver.

Add exact broker-task cancellation or disable brokered regulator decomposition under finite deadlines.

Move the sector driver to mission-owned symbols plus FamilyArtifactRead.

Reject unsupported source-variable arity explicitly.

II. Major performance work

Instrument and checkpoint the eight forcing entries individually.

Add local active-root decomposition followed by exact global lifting.

Implement per-entry modular grade-algebra evaluation and sparse rational reconstruction.

Batch points/channels, use dynamic entry scheduling, and fall back only per entry.

Measure the modular prototype on the current dominant entry; do not retime the old commit.

III. Cleanup and deletion

Enforce or remove dead resume-seal fields and exact key-set semantics.

Generalize resume provenance to native plan discovery.

Remove stale resume comments and relocate campaign narratives from source.

Retire CompileShards after equivalent tests exist on the production entry API.

Later, split MultiquadraticStripSolve.wl and consolidate duplicate algebra implementations; do not make that a relaunch prerequisite.

Relaunch recommendation: hold at f3738b, apply items 1–5, run the targeted closing tests, and then relaunch the current two-variable CF families without waiting for the modular decomposition optimization. The performance work can proceed independently after correctness gates are green.

## Sources sent to Pro

- [private_hardening_review_feynfacet_private_sources.zip](Sources/01_private_hardening_review/private_hardening_review_feynfacet_private_sources.zip)
