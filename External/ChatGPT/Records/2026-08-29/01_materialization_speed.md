# Materialization Speed

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation. Please
review the attached current `FeynFacet/Private` source snapshot at commit
`b2f7891` and advise how to make the existing exact materialization route much
faster. The user explicitly wants materialization optimized, not merely removed
or bypassed by a different solver.

The relevant path begins in `BlockEquationDeferred.wl`, especially deferred
strip construction/materialization, operand interning and the shared TaskBroker
queue; it then feeds chart pullback/root-basis processing in
`TransportCharts.wl` and related multiquadratic code. Please trace the actual
code rather than answering generically.

Measured production evidence on current triple-root families:

- CF259 block `{27,15}`: strip construction 22.2 s; exact materialization
  793.1 s, of which operand interning was 778.1 s and phase 2 about 15 s.
  The earlier path took 1125.3 s, so heavy-operand queue work already gave a
  29.5% reduction.
- CF303 block `{25,18}`: construction 27.2 s; exact materialization 1582.3 s,
  of which interning was 1572.2 s and phase 2 about 10 s, over 86 operands.
- The expensive work is therefore almost entirely exact canonicalization of
  independent repeated/root-containing operands, often involving `Together`.
  Later finite-field solving is a separate issue.
- The current queue is now sorted approximately heavy-first by serialized
  operand size. A read-only simulation predicted only 7--11% scheduling gain,
  so we need to look beneath scheduling for the next large improvement.
- Production must preserve exact mathematical output, generality across easy
  and hard families, existing per-block modular acceptance, and concise code.
  No family names or special cases may enter `Private`.
- Do not recommend more hashes, duplicated verification, or new symbolic
  production checks. Reject complicated changes that buy only a few percent.

Please answer at implementation level:

1. What exact algebraic operations dominate `blockEquationDeferredMaterialize`
   and operand interning in the attached code, and which are duplicated?
2. Can common denominators, root-basis products, substitutions, coefficient
   extraction, or `Together`/`Cancel` be batched or structurally shared before
   operands are split across kernels? Identify exact functions and patch shape.
3. Would a sparse numerator/common-denominator representation, balanced
   denominator merging, common-subexpression DAG, or quotient-ring/root-basis
   canonicalizer materially beat general-purpose `Together` while still
   yielding the same exact materialized strip? Which is the best first pilot?
4. Is the work currently partitioned at the wrong granularity? Explain how to
   avoid serialization, kernel startup, repeated definitions, and tail effects
   without increasing peak memory pathologically.
5. Specify one bounded, decisive benchmark using existing saved blocks or
   fixtures. Give expected wall-time/memory thresholds and an abort criterion.
6. Rank recommendations by realistic speedup, implementation risk, and code
   complexity. Separate an immediate patch (hours) from deeper work (days).

Please focus on the mathematics, expression representation, and algorithmic
cost. Quote exact source paths/functions from the attachment.

## Pro response

Verdict

The next large speedup must come from replacing whole-expression Together canonicalization, not from further queue tuning.

The current implementation is already routing chartable blocks correctly: it postpones materialization until after chart substitution, deduplicates identical transformed operands, and schedules the expensive operands approximately heavy-first. The measured 778–1572 second “interning” phase is almost exactly the repeated call

Wolfram Language
Together[transformedOperand]

followed by denominator factorization for each distinct operand. The later target assembly is only 10–15 seconds and is not worth optimizing now.

I inspected the attached b2f7891 snapshot, principally BlockEquationDeferred.wl, TransportCharts.wl, TaskBroker.wl, MultiquadraticAlgebra.wl, and the relevant pullback routine in MasterTransport.wl. 

feynfacet_private_b2f7891

The recommended order is:

Immediate, low-risk: split rational combination and denominator factorization into separate globally deduplicated stages; retain the intern pool across a sector row/chart.

Decisive pilot: replace Together for the chart path by a structured sparse fraction-DAG canonicalizer.

Only after that succeeds: move the sparse polynomial arithmetic to FLINT.

Do not spend more effort on heavy-first scheduling or phase-2 assembly unless profiling changes materially.

1. What the current code actually computes
Hot-path trace

For a chartable block, blockEquationDeferredForcing returns a raw PreparedChartDeferred object before source-frame factorization:

BlockEquationDeferred.wl:3023–3040

transportChartPullBackDeferredPreparation then defines the operand transformation

Wolfram Language
expr /. data["Subst"]

followed by active-root branch substitution and replacement of any inactive roots by formal projection generators:

TransportCharts.wl:1431–1439

It invokes

Wolfram Language
blockEquationDeferredMaterialize[
  ...,
  "ExpressionTransform" -> transform,
  "Cancel" -> False,
  "AlgebraicCanonicalize" -> False,
  ...
]

at:

TransportCharts.wl:1444–1456

Those options are important. On the measured path:

the factor-by-factor cancellation loop in phase 2 is disabled;

the final algebraic-denominator Together is disabled;

the phase-2 target assembly is therefore mainly one common-denominator expansion.

The dominant work is phase 1.

Exact phase-1 operation

For every distinct transformed operand, the current canonicalizer does:

Wolfram Language
q = Together[expression];
numerator = Numerator[q];
denominator = Denominator[q];
factorList = FactorList[denominator];
...
Cancel[numerator/content]

in:

BlockEquationDeferred.wl:807–820

function blockEquationDeferredCanonicalOperandValue

This operation is distributed by:

blockEquationDeferredInternTask, BlockEquationDeferred.wl:1029–1038

phase-1 scheduling, BlockEquationDeferred.wl:1192–1366

The timing field called InternSeconds includes:

applying the chart/root transformation;

discovering and deduplicating operands;

serializing the transformed expressions;

every operand-level Together;

every denominator FactorList;

helper collection and any local recomputation.

The current telemetry does not separate Together from FactorList, so the code does not support a stronger claim about which of those two dominates individually.

Phase 2

Once operands are represented as

{numerator, factor↦exponent},

blockEquationDeferredAssembleJob:

multiplies operand numerators within each term;

merges denominator exponents;

takes the per-factor maximum across terms;

builds one common numerator with a large Expand;

optionally cancels factors;

optionally applies a final algebraic Together.

See:

BlockEquationDeferred.wl:898–998

For the chart path, steps 5 and 6 are disabled. Your measurements of 10–15 seconds for phase 2 agree with the code structure. Optimizing this routine cannot materially improve a 793–1582 second materialization.

2. Duplicated work in the current implementation
A. Denominators are factored independently

Different numerators frequently share the same chart denominator. Nevertheless, every transformed operand independently executes

Wolfram Language
FactorList[denominator]

inside blockEquationDeferredCanonicalOperandValue.

The existing cache is keyed by the complete transformed expression:

Wolfram Language
pool[expression]

at BlockEquationDeferred.wl:824–827. It cannot share denominator factorization between two distinct expressions with the same denominator.

This is the easiest exact duplication to remove.

B. Shared chart substitution structure is repeatedly recombined

The same compact chart images occur in almost every operand, but the current sequence is:

source expression
⟶
/.
	​

large nested rational expression
⟶
Together
	​

D
N
	​

.

Together rediscovers the same denominator algebra independently for every operand.

For example, powers and products of the same coordinate-map denominators are recomputed inside each whole-expression rational combination. The code shares syntactically identical complete operands, but not their common subexpressions.

C. Branch-scale memoization is local to one expression

transportChartApplyRootBranches memoizes

Wolfram Language
scale[base,index]

inside one invocation:

TransportCharts.wl:1573–1585

The memo table is discarded when that operand finishes. The same radicand/root comparison can therefore be repeated for the next operand. This is probably secondary to Together, but it should be moved into the chart materialization context when building a structural evaluator.

D. The operand pool is local to one materialization

blockEquationDeferredMaterialize initializes:

Wolfram Language
pool = <||>

at BlockEquationDeferred.wl:1127, unless supplied with "SeedPool".

The non-chart compatibility route obtains a pool from blockEquationDeferredCompileBundleWithCache and passes it back as "SeedPool":

BlockEquationDeferred.wl:3049–3053

BlockEquationDeferred.wl:3077–3091

The chart-fast path returns before bundle compilation and therefore receives no such reusable pool. After one lower strip finishes, all canonicalized transformed operands are discarded even if the same gauge entries recur in the next lower strip.

For a recursively propagated row, this is a genuine campaign-level duplication.

One complication is that inactive projection generators are created with Unique on every chart materialization:

TransportCharts.wl:1423–1430

Those changing symbols defeat cross-call syntactic cache hits. A row-scoped cache requires stable formal generator identities for the ordered inactive-root frame.

E. Every helper deserializes the entire expression list

In the heavy-operand mode, each expensive operand becomes a singleton task. But the controller writes one data file containing all canonicalExpressions:

BlockEquationDeferred.wl:1321–1329

A helper asked to canonicalize one index executes:

Wolfram Language
data = taskBrokerRead[dataFile]

and therefore loads the complete list:

BlockEquationDeferred.wl:1032–1038

taskBrokerRead memoizes that file per persistent helper, so it is loaded once per helper, not once per task. That avoids repeated parsing on a single worker, but it means every participating helper retains all transformed operands even when it processes only a small subset.

This is primarily a memory and parsing inefficiency. It is unlikely to explain 1500 seconds by itself, but it can aggravate memory pressure and reduce effective parallel throughput.

F. A final rational Together remains after the Jacobian

After materialization, masterTransportPullBackOneForm forms the two chart one-form components using entrywise Together:

MasterTransport.wl:1938–1940

This is mathematically necessary under the current representation, but your phase measurements show it is not the present dominant cost. It should eventually consume structured fraction records directly, but it is not the first patch.

3. Immediate patch: separate combination from factorization

The current canonicalizer conflates two expensive operations. Refactor it into:

Wolfram Language
blockEquationDeferredRationalPairValue[expression_] := Module[{q},
  q = Together[expression];
  {Numerator[q], Denominator[q]}
];

blockEquationDeferredDenominatorFactorValue[denominator_] := Module[
  {factorList, content, factors},
  ...
];

Then change phase 1 to:

Compute {numerator, denominator} for every unique transformed operand.

Normalize each denominator up to rational content and a fixed sign.

Intern identical normalized denominators globally.

Run FactorList once per unique denominator.

Reattach the shared factor record to every numerator.

This changes no mathematics and no downstream representation.

Why this patch is worthwhile even before the deeper rewrite

It supplies the missing attribution:

RationalCombinationSeconds

UniqueDenominatorCount

DenominatorFactorSeconds

DenominatorReuseCount

The outcome determines the next action:

If FactorList is a large fraction of the 1572 seconds, denominator interning provides an immediate substantial gain.

If almost all time remains in Together, the code should proceed directly to the structural fraction evaluator.

The implementation is localized to:

blockEquationDeferredCanonicalOperandValue

phase-1 storage around BlockEquationDeferred.wl:1235–1365

blockEquationDeferredInternTask

It should not alter blockEquationDeferredAssembleJob.

Additional low-risk improvement: row-scoped cache

Retain completed

transformed expression⟼{numerator,factor map}

records for one accumulated sector row and one chart.

Do not make this an unbounded global cache. Use a byte cap and discard it when:

the chart changes;

the source frame changes;

the row finishes;

or the inactive-root basis changes.

The materializer already accepts "SeedPool". The missing part is returning or mutating a row-scoped pool on the chart path. A concise implementation is preferable to a new persistence subsystem.

Before using that cache across strips, replace per-call Unique projection tags with stable row-local formal generators. Otherwise identical algebraic operands will have distinct syntactic keys.

This cache will not accelerate the first isolated block, but it can remove repeated gauge-entry normalization from all later lower blocks of the same row.

4. The major algorithmic change: structured fraction-DAG materialization

The only route likely to turn 1500 seconds into a few hundred seconds is to stop constructing the swollen rational expression on which Together operates.

Representation

Represent an exact value as

F=(N,D),

where:

N is a sparse polynomial or a small multiquadratic-grade vector of sparse polynomials;

D is a map

f
α
	​

⟼n
α
	​


representing the factored denominator

D=
α
∏
	​

f
α
n
α
	​

	​

.

For the fully rationalized chart path, N has one channel. When inactive roots remain, use

N=(N
0
	​

,…,N
2
r
−1
	​

)

in the declared root basis.

A separate divisor/letter ledger should retain algebraic factors when required by the downstream alphabet. This is important because the existing code correctly warns that norm-rationalizing an algebraic denominator can erase an algebraic letter from the denominator inventory:

BlockEquationDeferred.wl:974–988

Therefore the value normal form and the alphabet/divisor provenance must not be conflated.

Arithmetic
Multiplication
(N
1
	​

,D
1
	​

)(N
2
	​

,D
2
	​

)=(N
1
	​

N
2
	​

,D
1
	​

+D
2
	​

).

For root channels, use the existing XOR-grade multiplication law, but without applying Together to every product. The current generic routine

Wolfram Language
multiquadraticMultiply

is algebraically useful but calls Together /@ out in characteristic zero:

MultiquadraticAlgebra.wl:68–84

A sparse-polynomial backend should implement the same multiplication table while keeping coefficient maps structured.

Integer powers

Use binary exponentiation and multiply denominator exponent maps arithmetically. Do not expand repeated powers through ordinary Wolfram Power followed by Together.

Addition

For

D
1
	​

N
1
	​

	​

+
D
2
	​

N
2
	​

	​

,

compute the denominator LCM from the factor maps:

D=lcm(D
1
	​

,D
2
	​

),
N=N
1
	​

D
1
	​

D
	​

+N
2
	​

D
2
	​

D
	​

.

Merge a large sum through a balanced tree, preferably grouping terms first by denominator signature. After each merge, remove any denominator factor that divides every numerator grade exactly.

This is materially different from naively splitting a base expression into all additive terms and then doing one huge cofactor expansion. The latter can increase work and is already warned against in the source comments. Balanced progressive merging permits cancellations before the largest intermediate is formed.

Substitution

Precanonicalize every chart image:

x
i
	​

↦
Q
i
	​

P
i
	​

	​

,r
a
	​

↦
S
a
	​

R
a
	​

	​

,

as structured fractions. Traverse each source operand as an expression DAG, replacing these atoms by the precomputed records.

Memoize nontrivial shared subexpressions across all operands in the materialization. This shares:

coordinate-map powers;

repeated root images;

repeated gauge denominators;

repeated polynomial factors.

Final emission

Only after a target is assembled should the materializer emit the ordinary exact expression

∏
α
	​

f
α
n
α
	​

	​

∑
g
	​

N
g
	​

r
g
	​

	​

.

If a structurally canonical expression is required, one final target-level Together remains permissible. There are only a few target entries, and the current phase-2 measurement indicates this level is inexpensive.

5. Common denominators and root-basis work that can be shared
Before distributing operands

The controller should build a chart-materialization context containing:

canonical fraction records for every substitution image;

cached powers needed by all operands;

the branch-scale table for all declared roots;

the stable inactive-root generators;

a global table of denominator factors;

a common-subexpression DAG for sufficiently large repeated nodes.

Workers should receive references to this compact context plus their operand DAGs, rather than complete already-substituted expressions.

Denominator handling

The current code calls full FactorList only after Together has created a denominator. In the structural route, most denominator factors are known from:

chart coordinate denominators;

rational root-image denominators;

source operand denominator factors;

integer powers in the source expression.

Their exponents can be propagated without factoring the expanded product.

Invoke FactorList only for a genuinely new denominator generated by an additive merge. Deduplicate that result globally.

Root-basis processing

When projection roots survive the active chart substitution, do not first build a polynomial in opaque root tags and later call multiquadraticFieldDecompose entry by entry.

Carry the numerator in the local grade basis from the start and lift it into the package’s global ABI when necessary. Multiplication then uses:

r
S
	​

r
T
	​

=(
i∈S∩T
∏
	​

Δ
i
	​

)r
S△T
	​

.

This fuses:

root-power reduction;

coefficient extraction;

product reduction;

inactive-grade tracking.

The later exact projection at TransportCharts.wl:1465–1488 becomes a check that the nonzero final grades are absent, rather than another expensive decomposition stage.

This optimization is valuable only when inactive roots are present. For a completely rationalized chart, the one-channel fraction DAG is simpler and should be used.

6. Best implementation level
First pilot: custom sparse maps in Wolfram Language

Implement the fraction representation and arithmetic as Associations keyed by exponent tuples. This is not intended as the final high-performance backend. It is the fastest way to establish whether avoiding Together removes the observed asymptotic problem.

The pilot should operate through the existing InternDispatcher seam:

BlockEquationDeferred.wl:1111–1114

BlockEquationDeferred.wl:1256–1340

That permits replacing only phase-1 canonicalization while leaving:

target assembly;

chart Jacobian;

downstream solver;

existing modular acceptance

unchanged.

Production backend if the pilot succeeds: FLINT sparse multivariates

Use:

fmpz_mpoly for primitive integer multivariate polynomials plus explicit rational content; or

fmpq_mpoly when rational coefficients are frequent enough to justify it.

The extension arithmetic itself should remain custom fixed-rank channel arithmetic. FLINT should handle only base polynomial:

multiplication;

exact division;

gcd;

content normalization;

optional factorization.

This is a substantially smaller interface than sending arbitrary Wolfram expressions to a general CAS.

Not recommended as the main implementation

Maple evala(Normal): too general and already measured as unsuitable.

Singular Gröbner reduction: unnecessary for monic quadratic root relations with an explicit basis.

Current multiquadraticFromPolynomial: it calls Expand, PolynomialReduce, and Together /@ out, so it reproduces much of the same characteristic-zero swell.

More ordinary Together workers: the individual operands themselves are the long serial tasks; more workers do not shorten the largest operand and can increase memory pressure.

7. Work granularity
Current granularity is too coarse for the long tail

The heavy mode deliberately schedules one large operand per task:

BlockEquationDeferred.wl:1280–1313

This is better than source order and explains the observed 29.5% reduction. It cannot reduce a single 400–900 second operand.

However, arbitrary additive-term sharding would be unsafe for performance. It can destroy early cancellation and create a massive final common numerator.

Correct internal sharding

Only the largest one or two operands should be split, and only after compiling them to a structured fraction DAG.

Partition at nodes that satisfy one of:

distinct denominator signatures;

independent large product subtrees;

balanced groups of additive terms with similar denominator support.

Each shard should return a fraction record, not an expanded expression. Merge the shard results through the balanced fraction tree.

Target roughly 30–120 seconds of estimated work per shard. That is large enough to amortize broker traffic but small enough to remove a 900-second tail.

Serialization patch

In singleton mode, do not place all transformed operands in one helper data file. Write one file per batch, containing:

the compact shared chart context reference;

only the operand DAGs assigned to that batch.

The current persistent pool already avoids kernel startup, and taskBrokerRead already memoizes a file per helper. The avoidable cost is loading and retaining all 86 expressions on every helper.

This change should be considered secondary. Retain it only if measured import/deserialization plus memory pressure is significant; it is unlikely to provide a multi-fold speedup by itself.

Concurrency should be memory-limited

A sparse fraction canonicalization can have high transient memory even when its final value is compact. Limit simultaneous heavy tasks by measured peak bytes, not only by the number of free kernels. Starting every large operand concurrently can exchange wall time for paging or garbage-collection pressure.

8. One decisive benchmark

Use the saved CF303 block {25,18}:

86 operands;

current construction 27.2 seconds;

current interning 1572.2 seconds;

current phase 2 about 10 seconds.

This is preferable to a synthetic fixture because it contains the actual chart substitution and denominator structure causing the slowdown.

Benchmark design

Run only transportChartPullBackDeferredPreparation through materialization, using the same prepared deferred record and chart map. Do not run the finite-field solver.

Inject the candidate canonicalizer through InternDispatcher, while leaving the current phase-2 assembly unchanged.

Record per operand:

chart-transform time;

fraction-combination or Together time;

denominator-factor time;

maximum numerator term count;

maximum denominator-factor count;

peak worker RSS.

Use the previously saved exact materialized strip as the comparison result; no old full rerun is needed.

Acceptance thresholds
Immediate two-stage/cache patch

Because this is a small localized change, retain it if:

T
intern
	​

≤1100 s,

approximately a 30% reduction over 1572 seconds, with no material increase in aggregate peak memory.

Reject it as an optimization if it saves only the predicted scheduling-scale 7–11%.

Structured fraction-DAG implementation

Require:

T
intern
	​

≤500 s

and

T
materialize
	​

≤550 s.

That is approximately a factor-three improvement and is sufficient to justify the added representation.

Abort the pilot if:

wall time reaches 600 seconds without completion;

aggregate peak RSS exceeds 1.25× the measured current-materializer peak;

an individual structured merge grows beyond four times the corresponding final numerator term count without subsequently contracting;

the candidate falls back to general Together for more than a small minority of operands.

A result between 500 and 900 seconds is only worth retaining if the implementation remains very small and does not introduce a new native backend. A multi-day representation should not be accepted for a 20–30% improvement.

After a pass on CF303, run the same candidate on CF259 {27,15}. The second block is a generality check and should show at least a factor-two improvement over the current 793-second materialization.

9. Ranked recommendations
Priority	Change	Realistic benefit	Risk	Complexity
1	Structured sparse fraction-DAG materializer in the rational chart	3–10× phase-1 potential	Medium	Days
2	Row/chart-scoped canonical operand cache	Potentially large campaign-level reuse; no first-block gain	Low–medium	Hours
3	Split Together from denominator factorization and factor each distinct denominator once	1.1–2×, profile-dependent	Low	Hours
4	Internal sharding of only the largest structured fraction DAGs	1.2–3× on long-tail blocks	Medium	1–2 days
5	FLINT sparse-polynomial backend for the successful fraction representation	Additional 2–5× over a slow Wolfram prototype	Medium–high	Several days
6	Batch-local serialization instead of every helper loading all operands	Likely 5–20%; memory benefit may be larger	Low	Hours
7	Further heavy-first scheduling changes	Measured ceiling about 7–11%	Low	Not justified
8	Phase-2 Expand/Jacobian optimization	Below a few percent of current total	Low	Not justified now
Immediate patch versus deeper work
Immediate patch — hours

Split blockEquationDeferredCanonicalOperandValue into rational-pair and denominator-factor stages.

Deduplicate normalized denominators before FactorList.

Add exact per-operand timing for those two stages.

Retain a byte-bounded operand pool across lower strips of one row/chart.

Use stable inactive-root generator identities within that cache scope.

In singleton mode, send only each batch’s expressions to its helper.

This preserves the existing expression representation and downstream code.

Deeper work — days

Implement a chart-aware exact fraction-DAG evaluator.

Precompile chart substitutions and root images as fraction leaves.

Use balanced denominator-aware addition and binary-power evaluation.

Carry inactive roots as grade channels and reduce products by XOR.

Preserve divisor/alphabet metadata separately from the normalized value.

Emit the ordinary exact materialized expression only at the final target boundary.

Move base sparse-polynomial operations to FLINT only after the Wolfram prototype demonstrates at least a factor-three wall reduction.

Bottom line

The current materializer already removes obvious duplicate complete operands and already schedules the long tasks reasonably. Its central remaining defect is representational:

compact exact operand⟶large substituted expression⟶Together
	​


is the wrong algorithm for a chart map whose denominators and algebraic basis are known.

The strongest immediate low-risk improvement is denominator-stage sharing and a row-scoped cache. The strongest substantive improvement is to materialize through a sparse factored fraction DAG, using the explicit quotient-ring basis only when roots remain. General-purpose Together should become a fallback for unsupported expression nodes, not the primary canonicalization engine.

## Sources sent to Pro

- [feynfacet_private_sources.zip](Sources/01_materialization_speed/feynfacet_private_sources.zip)
