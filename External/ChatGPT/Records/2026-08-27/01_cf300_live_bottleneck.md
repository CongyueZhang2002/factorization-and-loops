# CF300 Live Bottleneck

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation with its
full history. This is a focused follow-up in the same conversation. Review the
attached actual current `MultiquadraticStripSolve.wl`; it contains Codex's
uncommitted Round-B takeover work and is newer than the previously attached
archive.

We now have physical live evidence from the triple-root CF300 `(12,9)` block:

- rank-three SplitBranch provider, 2,260 unknowns, 53 one-forms;
- 64 equations per kinematic point; `Automatic` uses 37 points, plus 52
  normalization rows;
- the modal affine section is stable at rank 2,208 / nullity 52;
- support `{0,0}` passed with zero defect;
- CFFA4 multi-RHS now uses 8 FLINT threads and the native 2,260-square,
  53-RHS solve is about 0.5 seconds;
- nevertheless each post-plan regulator image takes roughly 2--3 minutes;
- a direct CPU trace shows one image sustaining about 14--17 cores during the
  dominant work, so simply running two Wolfram images concurrently may only
  contend for the same 16-core allowance;
- two CRT primes were insufficient and the adaptive reconstruction is now on
  its third prime.

The current code builds about 5.35 million modular matrix entries per image.
The scalar point-row assembler repeatedly constructs 64 length-2,260 rows at
each point. The SplitBranch evaluator also repeats the complete point loop,
all sparse monomial dot products, deferred-DAG evaluation, and row scaffolding
for every epsilon value at a fixed prime. Current fibres already reuse the same
deterministic candidate-point stream.

Please independently assess and rank these possible optimizations by expected
wall-clock benefit, implementation complexity, and correctness risk:

1. A brokered two-image wave (already implemented provisionally but now
   defaulted to serial pending a physical throughput A/B test).
2. Remove the successful FLINT core matrix replay: treat native output as
   provisional, perform normalization plus the already mandatory full original-
   row residual once, and retry Wolfram only if that validation fails.
3. Bulk/vectorize or natively compile `multiquadraticStripAssemblePointRows`
   while preserving its exact row/column ABI and staged modular arithmetic.
4. Batch 2--9 same-prime epsilon followers. Build an epsilon-free point
   context once; specialize each compiled SplitBranch numerator/denominator in
   all non-epsilon variables once to a univariate polynomial in epsilon;
   Horner-evaluate all fibres; reuse regulator-free roots, logs, one-forms,
   support monomials and row scaffolding; retain distinct image keys and
   per-epsilon pole rejection; solve/discard matrices one at a time.

Questions:

- Is same-prime epsilon batching mathematically sound for interpolation
  fibres, or does it weaken any evidence contract in a way the current fresh-
  prime validation does not repair?
- Is there a substantially simpler algorithmic route with comparable speed,
  especially for evaluating the sparse rational expressions or assembling the
  dense modular matrix?
- Which phase telemetry and physical A/B tests are decisive before keeping
  code? We will reject a complicated change that buys only a few percent.
- Do you see any correctness flaw in the provisional follower-wave or
  one-full-residual design in the attached source?

Be concrete about the mathematics and algorithm. Avoid proposing more hashes,
seals, or generic validation layers unless they close a specific false-positive
path. Lead with a go/no-go ranking and give the smallest high-value next step.

## Pro response

GO / NO-GO ranking
Rank	Optimization	Decision	Expected wall benefit	Complexity	Correctness risk
1	Same-prime epsilon batching	GO for a bounded 2-fibre pilot	Highest. Potentially 1.4–2× over several fibres if coefficient evaluation is the dominant phase	Medium-high	Moderate but controllable
2	Bulk/vectorized point-row assembly	CONDITIONAL GO after reading existing phase telemetry	Potentially large row-phase speedup; total benefit depends entirely on the row-assembly share	Medium	Moderate ABI/sign risk
3	Remove successful native core replay	Already implemented correctly; keep it	No remaining incremental gain	None	Low
4	Brokered two-image wave	NO-GO as default; retain only for a physical A/B test	Probably negligible or negative under the observed 14–17-core saturation	Low, already implemented	Resource contention plus a limited worker-record trust gap

The smallest high-value next step is not a full nine-epsilon batching rewrite. It is:

Extract the existing phase telemetry for one completed post-plan image, then run a frozen two-epsilon, provider-only batch prototype that leaves row assembly, constrained solving, interpolation, and reconstruction unchanged.

Do not perturb the live third-prime reconstruction.

1. The native core replay has already been removed

The current multiquadraticStripConstrainedAffineSolve already implements the proposed design:

Native FLINT returns the 2260×53 candidate solution matrix.

Wolfram checks the fixed normalization columns.

Wolfram computes exactly one residual against all original rows:

AX−B=0(modp).

Wolfram LinearSolve is invoked only if the native result has the wrong shape, violates normalization, or fails the all-row residual.

The telemetry explicitly reports

ConstrainedSolveNativeCoreReplayCount -> 0

and separately counts the all-row residual replay. 

MultiquadraticStripSolve +1

This is mathematically sufficient. The normalization conditions

X
particular
	​

[J]=0,X
null
	​

[⋅,J]=I
52
	​


fix the affine representative and prove that the returned 52 null vectors are linearly independent. The all-row residual then proves that the particular solution and every null vector satisfy the complete original system. Re-solving the square core in Wolfram would add no independent mathematical fact.

No correctness flaw is present in this one-full-residual design. The only remaining question is whether the exact Wolfram matrix product used for that residual itself consumes significant time. The source already records "FullResidual" separately from "NativeCoreSolve", so profile rather than redesign it.

2. Same-prime epsilon batching is mathematically sound

Yes. For a fixed good prime p, the regulator fibres

ϵ=ϵ
1
	​

,…,ϵ
m
	​

∈F
p
	​


are interpolation data for rational functions of ϵ. Sharing kinematic evaluation work between them does not alter the equations at any fibre.

The present implementation already uses the same deterministic candidate-point stream for each fibre. It reruns preflight, coefficient evaluation, row assembly, normalization, and constrained solving separately. 

MultiquadraticStripSolve

 Batching changes computation, not the mathematical sample set.

It also does not change the number of CRT primes required. The third prime is needed because two moduli did not uniquely lift the coefficient heights; batching only reduces the cost of producing the several regulator images at each prime.

Mandatory invariants
Distinct regulator images

The rational values must give distinct elements modulo p:

ϵ
i
	​

modp

=ϵ
j
	​

modp.

Duplicate rational values are already prohibited at the schedule level, but different rationals can collide modulo a particular prime. The batch path must detect this before interpolation.

Every rational denominator occurring in ϵ
i
	​

 must also be invertible modulo p.

Per-fibre pole rejection

A point accepted for one ϵ
i
	​

 is not automatically valid for another. For each fibre separately, reject:

zero gauge denominator;

zero denominator of any compiled rational expression;

zero or degenerate root square;

singular normalization value;

any regulator pole.

The cleanest algorithm is to advance one common deterministic candidate stream while maintaining a separate accepted-point list for every fibre. Do not use the intersection of all valid points unless measurements show its rejection cost is negligible.

Reuse only data proved epsilon-free

The generic source does not impose that root squares, root logarithmic derivatives, gauge denominators, or one-forms are epsilon-independent. In the SplitBranch preflight it explicitly inserts the regulator image into scalarRules before evaluating all these objects. 

MultiquadraticStripSolve

For current CF300, many of these objects are presumably epsilon-free, but the batch compiler must establish this from its exact polynomial representation. A safe classification is:

exponent support in ϵ exactly {0}: reusable point datum;

otherwise: retain as a univariate polynomial or rational function in ϵ.

Do not infer regulator independence from a name such as “root” or “one-form.”

Preserve numerator and denominator separately

For each compiled rational expression, specialize the non-epsilon variables to obtain

D(ϵ)
N(ϵ)
	​

∈F
p
	​

(ϵ).

Horner-evaluate N and D separately at every fibre and reject D(ϵ
i
	​

)=0. Do not interpolate or simplify the quotient before these pole checks.

Full per-fibre solve contract

Every fibre must retain its own:

image key;

accepted points and training keys;

normalization rows;

constrained solution;

rank/nullity signature;

all-original-row residual;

canonical values.

Matrices may be solved and discarded one at a time.

Does fresh-prime validation repair all correlations?

It repairs the mathematical sampling correlation: a kinematic polynomial accidentally vanishing on one shared point set is tested at fresh primes and fresh points.

It does not repair a software error if the same new batching implementation is also used for every fresh-prime validation. For example, a wrong Horner coefficient order would be repeated at every prime.

Therefore retain one differential oracle:

At one held-out epsilon value per new batch implementation—not necessarily per production prime—compare the batched provider output and resulting matrix/RHS exactly against the existing scalar SplitBranch path.

The existing scalar path should remain available as the fallback and independent checker.

3. Why epsilon batching has the highest expected value

The current SplitBranch path compiles each scalar expression sparsely, but then, for every entry and every sign branch at every point, it reconstructs power tables and evaluates the rational numerator and denominator. 

MultiquadraticStripSolve

multiquadraticStripProviderChannels repeats this for all entries in E,C,
B
ˉ
, the deferred bundle, and all 53 one-forms at every (p,ϵ,x,y). 

MultiquadraticStripSolve

A point-major batch can remove three nested repetitions:

kinematic powers repeated across expressions;

non-epsilon sparse dot products repeated across epsilon values;

provider/point-loop scaffolding repeated across epsilon values.

An Amdahl estimate is useful. If a fraction f of one image lies in coefficient evaluation and a fraction s of that phase can be shared across a batch of m, then

S
total
	​

≃
(1−f)+f[(1−s)+
m
s
	​

]
1
	​

.

For example, f=0.7, s=0.7, m=4 gives approximately 1.6×. A nine-fibre batch is not automatically nine times faster because Horner evaluation, row assembly, the full residual, and each constrained solve remain per-fibre.

Start with two fibres, then four. Nine should be attempted only after the memory and point-rejection behavior are measured.

4. A simpler precursor to full epsilon batching

Before writing a new reconstruction controller, add a provider-wide point context.

Currently multiquadraticStripSplitBranchEntry builds powerTables separately for each expression and branch. A lower-risk change is:

At provider construction, compute the union of required exponents for

x, y, ϵ, r
1
	​

, r
2
	​

, r
3
	​

.

At one point and branch, build these power tables once.

Evaluate every compiled sparse numerator and denominator from those shared tables.

Return the same coefficient record consumed by the unchanged row assembler.

This attacks repeated power-table construction and Wolfram call overhead within a single image. It is structurally simpler than cross-epsilon batching and naturally extends later to several epsilon values.

The required differential test is exact equality of all returned coefficient tensors with the current entry-by-entry evaluator at:

ranks 0,1,2,3;

all sign branches;

one physical CF300 point;

denominator-zero and unsupported-expression mutants.

If this point-context hoist already cuts coefficient evaluation substantially, extend it to univariate-in-ϵ specialization. If it gives only a few percent, skip the larger batch rewrite.

5. Point-row assembly is a credible second bottleneck

The current row assembler is exact but expensive at the Wolfram-language level.

For every point it:

computes monomial, basis, derivative, grade-product, and weight tables;

allocates 64 dense zero rows of length 2260;

builds every gauge row through a deeply nested Table and Flatten;

builds a mostly-zero residue row separately;

joins the two arrays.

The relevant loops explicitly traverse

(a,b,source grade,monomial)

for every target grade, direction, and matrix entry. 

MultiquadraticStripSolve

For the physical system,

37×64×2260=5,351,680

point-row entries per image, before the 52 normalization rows.

Recommended implementation order
First: vectorized/block Wolfram implementation

Precompute once per layout:

row-index maps;

gauge-column block offsets;

residue-column block offsets;

grade XOR table;

grade square-factor table;

the positions where the derivative term is nonzero;

the positions selected by E and C.

Then fill a preallocated packed matrix through block assignments. In particular, the residue portion has 212 columns per row but only the 53 columns belonging to the current (i,j) block can be nonzero.

This may remove most Table/If/Flatten overhead without introducing native code.

Second: native kernel only if necessary

A native assembler is reasonable because every input is already a packed modular integer array. It must preserve exactly:

row order:

(target grade,μ,i,j);

gauge column order:

(a,b,source grade,monomial);

residue column order:

(letter,a,b);

the derivative Kronecker condition;

the signs of the E and C terms;

staged modular reduction.

Since p<2
31
, a product of two reduced residues fits in signed 64-bit arithmetic, but a native implementation must reduce between products and must not accumulate long unreduced sums.

Acceptance gate

Use frozen coefficient records so provider evaluation is excluded. Require exact equality—not only equal ranks—of:

M
new
	​

=M
old
	​

,b
new
	​

=b
old
	​


for rank 0 through 3 and the complete 37-point CF300 image. Include mutants for:

swapped root-bit order;

transposed E or C;

derivative sign;

residue block ordering;

one shifted row or column.

Keep this optimization only if it either:

reduces row-assembly wall by at least 3×, and

predicts at least a 15–20% end-to-end image reduction,

or directly produces that end-to-end reduction.

6. Brokered two-image wave
Performance recommendation

Keep

ImageKernelCount -> Automatic

serial.

The code’s admission heuristic determines whether two images can run by dividing $ProcessorCount by the requested native FLINT thread count. 

MultiquadraticStripSolve

 That is not a valid predictor for this physical workload: the FLINT phase lasts roughly 0.5 seconds, while the dominant Wolfram sampling phase already sustains 14–17 cores.

Two concurrent images are therefore likely to:

oversubscribe the same 16-core allowance;

increase cache and memory-bandwidth contention;

raise peak RSS;

provide little or negative throughput gain.

The main reconstruction correctly permits waves only for consecutive uncached followers after the plan is fixed and restores schedule order before admission. 

MultiquadraticStripSolve

 There is no mathematical problem with computing the two fibres concurrently.

Specific correctness limitation

The helper performs the full residual check, but the parent-side multiquadraticStripFollowerImageAuthenticate does not independently verify the returned canonical vector. It checks:

request and fingerprint fields;

rank/nullity/pivots;

the boolean FullResidualZero;

value range and vector length.

An arbitrary in-range canonical vector accompanied by a structurally matching record and FullResidualZero -> True can pass this authentication function. 

MultiquadraticStripSolve

This is not presently a final theorem-level false positive because later interpolation, held-out fibres, and unseen-prime checks should reject the corruption. It is nevertheless a concrete weakness in promoting the wave to a default data path.

Before defaulting to two-image execution, add one cheap parent challenge:

choose one deterministic point not in the worker’s training set;

evaluate the 64 strip equations for the returned canonical vector;

require zero residual.

That costs approximately one point rather than returning or rebuilding the entire matrix.

The wave also acknowledges that a timed-out broker helper is not cancelled. 

MultiquadraticStripSolve

 With seven inherited jobs, this is another reason to keep the wave experimental.

Physical A/B gate

Use the same prime, same two epsilon requests, same candidate stream, and warm caches.

Run serial and wave in alternating order at least three times. Record:

wall time to two authenticated images;

total CPU-seconds;

peak RSS;

accepted attempts and rejected-point histograms;

coefficient and row-assembly phases;

canonical-value equality;

helper fallback or late-work count.

Promote wave execution only if it gives at least 20% lower wall time with no material increase in failures and no severe CPU/RSS increase. A 5–10% gain does not justify the scheduling complexity.

During this A/B test, use one or two FLINT threads per image; the native solve is too short to justify eight threads while two samplers contend.

7. Decisive telemetry

Most required telemetry already exists.

multiquadraticStripAssembleSample records:

preflight;

coefficient evaluation;

row assembly;

normalization;

sparse compilation;

sparse evaluation;

substitution fallback.

MultiquadraticStripSolve +1

The constrained solver separately records:

native core solve;

Wolfram fallback;

full residual.

MultiquadraticStripSolve

For one representative warm post-plan image, report these as percentages of wall time and add externally measured:

process CPU-seconds;

peak RSS;

average effective core count;

garbage-collection or memory-allocation pressure if available.

Use the following routing rule:

Coefficient evaluation >50%: implement the two-epsilon provider batch first.

Row assembly >25%: implement the block/vectorized assembler first.

Full residual >15%: optimize that exact matrix product, but do not replace it with a purely probabilistic check.

No phase >25%: first implement the provider-wide point context, because it touches several repeated subphases with a small interface change.

Minimal next sequence

Let the live third-prime reconstruction continue unchanged.

Extract one completed warm image’s existing phase telemetry.

Freeze one prime, two good epsilon values, and the deterministic candidate stream.

Implement a provider-wide point context with shared sparse power tables.

Extend that context to specialize non-epsilon variables once and Horner-evaluate the two epsilon fibres.

Leave row assembly, normalization, FLINT solving, and interpolation unchanged.

Compare every resulting matrix, RHS, accepted-point list, canonical vector, and full residual against two independent scalar executions.

Keep the change only if the two-image serial wall falls by at least 20–25%.

If row assembly remains the largest residual phase, proceed to the block/vectorized assembler.

Bottom line: same-prime epsilon batching is the best remaining algorithmic direction, but the safest first implementation is a narrow provider-level batch. The two-image wave should remain off by default, and the native-core replay optimization is already correctly complete in the attached source.

## Sources sent to Pro

- Original source reference: `/home/maxzhang/factorization-and-loops/FeynFacet/Private/MultiquadraticStripSolve.wl` (not archived with this exchange)
