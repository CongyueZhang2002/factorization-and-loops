# CF303 Modular Structure

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation. Please
independently review the attached current sources and the actual CF303 `(25,18)`
production log, then advise on the mathematical/algorithmic fix rather than
additional defensive hashes or redundant verification.

The live facts are:

1. Exact rational-chart materialization completed in 1477.2 s. The standard
   rational finite-field ansatz in chart `Kallen2Bilinear115` has a certified
   total-degree-58 simplex, matrix `7152 x 7144`, and was inconsistent over the
   full offset/rectangle ladder. The same simplex remained inconsistent at an
   independent prime 2147483423 and regulator 1/11. This is generic ansatz
   failure, not a bad modular image.
2. The standard gauge denominator has bidegree `(50,37)`. The rank-zero
   SplitBranch fallback uses the conservative denominator of bidegree `(78,58)`
   (one extra copy of each of 16 active curves), support 4661, 18836 unknowns.
3. Both exact diagonal blocks are epsilon-independent. At an extra pole copy
   of a curve f, the leading equation is
   `-m H - eps E_f H + eps H C_f = 0`; its determinant has constant term
   `m^4`, so no extra kinematic pole is possible over Q(eps). Therefore all 16
   extra conservative copies must cancel. Do not recommend a denominator
   promotion unless you find a flaw in this valuation argument.
4. The important fallback difference is the one-form span: 48 installed
   letters = 32 dlogs of forcing entries sampled at regulator values
   `{1,2,3,5}` plus 16 rational polar factors. Its residue-only integrability
   system was consistent, rank 80/80 in an 80 x 192 system.
5. The fallback then prepared and built a SplitBranch provider, but regulator
   reconstruction returned `ModularStructureUnstable` immediately (0.2 s),
   before an actual gauge solve. Please trace this status in the attached
   current code and identify exactly which structure changes between images,
   whether it is a genuine mathematical instability or an overly strict
   reconstruction contract, and the minimal correct repair.
6. Performance evidence: candidate dlog construction was serial for 1513.8 s
   while seven KernelPool helpers were idle. The attached uncommitted source
   now has a general TaskBroker shard path, tested 7/7 plus provenance 69/69;
   a deadline-scope correction is still being applied. Review its algorithm
   and flag any remaining correctness/pooling issue. Realistic target is
   3--5 minutes.
7. A finite-field materialization pilot on the hardest 27 MB operand took
   34.3 s per prime but needs about 203 CRT bits (seven current primes), i.e.
   ~240 worker-seconds before lift versus 140.6 s exact. We therefore rejected
   it as a universal tonight fix.

Questions:

- What is the root cause of `ModularStructureUnstable` here, at the exact code
  branch in the archive?
- Should the fastest robust recovery reuse the expanded forcing-dlog alphabet
  as `ExtraLetters` in the rational finite-field solver with the original
  minimal denominator, or repair the rank-zero regulator reconstruction?
- How should we reduce the 32 sampled forcing dlogs to the smallest sufficient
  epsilon-independent residue span without 32 full re-solves? A cokernel/span
  projection is preferred if valid.
- Is there a cheaper exact way to construct those forcing dlogs than symbolic
  whole-expression differentiation/Together, beyond the broker parallelism?
- Review the broker patch for mathematical equivalence, dynamic pooling,
  deadlines, cancellation, and concise generality.

Please give a prioritized concrete implementation plan and identify any
dead-end we should avoid. The user wants production modular checks at random
points, not new full symbolic verification layers.

## Pro response

Verdict

GO: reuse the expanded forcing-letter information in the ordinary rational finite-field solver, with the original minimal gauge denominator and a cokernel-selected subset of ExtraLetters.

NO-GO: do not pursue the current rank-zero reconstruction for this block. Its reported ModularStructureUnstable is not a mathematical instability; it is a misclassified dense-matrix resource refusal before any structural solve occurs.

I reviewed the extracted current source files, focused broker test, and fresh_sol_CF303.log from the attached archive. 

cf303_modular_structure_sources…

1. Exact cause of ModularStructureUnstable

No rank, nullity, or pivot structure changed between regulator images. No structural image was successfully assembled.

The fallback has:

n=18,836unknowns,e=8equations per point.

The provider sampler chooses automatically

N
pt
	​

=⌈
e
n+e
	​

⌉=2356

points; see MultiquadraticStripSolve.wl:8312–8314. This produces at least

2356⋅8=18,848

rows. The code’s own conservative peak lower bound is therefore

16(18,848)(18,836)=5,680,334,848 bytes≈5.29 GiB.

The configured ceiling is 4.0×10
9
 bytes:

MultiquadraticStripSolve.wl:3081

size estimate: 3110–3116

refusal: 3120–3128

provider-sample admission: 8330–8335

Thus every structural-pilot attempt immediately returns

SampleMatrixResourceLimit
Reason -> DenseMatrixByteCeilingExceeded

before evaluating points or performing RREF.

The reconstruction controller then:

records each failed sample as StructuralPilotSampleFailed;

records the prime as NoUsableStructuralPilot;

obtains no StructuralPilotSignature;

reaches modalStructuralSignature === Automatic;

returns ModularStructureUnstable.

That path is at MultiquadraticStripSolve.wl:14053–14162.

So the exact diagnosis is:

ModularStructureUnstable=misclassified “no admissible structural pilot,” not changing structure.
	​


This also explains the 0.2 second turnaround in fresh_sol_CF303.log:255–259.

Minimal correction

Separate three cases:

Zero successful structural samples: propagate the dominant typed reason, here SampleMatrixResourceLimit, or return StructuralPilotUnavailable.

Successful samples with stable rank/nullity but unusable reference minors: mark those images or primes exceptional and continue.

Successful samples with genuinely conflicting generic rank/nullity: only this case is ModularStructureUnstable.

There is a second, latent overconstraint. The structural signature currently is

Wolfram Language
{Rank, Nullity, PivotSignature}

at MultiquadraticStripSolve.wl:14126–14128, and two identical signatures are required at 14142–14146. A pivot set is not a generic mathematical invariant: a valid pivot minor can vanish at one otherwise good prime while rank and nullity remain unchanged.

The controller should vote on

(rank,nullity)

and then choose one reference affine section. Follower images should be tested against that fixed section; a singular reference minor makes an image exceptional, not structurally different.

This repair is necessary for accurate failure typing, but it does not make the 18,836-unknown dense route practical.

2. Recovery route: rational solver plus selected ExtraLetters

The fastest robust route is:

minimal denominator+certified degree-58 support+selected forcing-entry letters
	​


inside SolveEpsFormStripFiniteField.

FiniteFieldStripSolve.wl:1063–1070 already appends

Wolfram Language
record["ExtraLetters"]

to the ordinary rational alphabet and constructs their dlogs.

Why the denominator should remain minimal

Your valuation argument is sound under the stated logarithmic-pole hypotheses.

For an additional pole f
−m
H, m>0, the leading divisorial equation is

−mH−ϵE
f
	​

H+ϵHC
f
	​

=0.

After vectorizing the 2×2 block, its coefficient determinant is

m
4
+O(ϵ),

which is nonzero in Q(ϵ). Hence H=0. Therefore an additional copy of f cannot occur in the gauge.

This assumes:

f is treated at its generic reduced divisor;

E and C have at most logarithmic poles there;

the target one-forms also have at most simple poles;

m>0.

Those are precisely the conditions in the supplied local/projective census. The 16 conservative extra factors should not be promoted.

Why the rank-zero fallback is the wrong recovery level

The conservative fallback changes:

support from the certified degree-58 simplex to 4,661 monomials;

unknowns to 18,836;

required dense sampling to approximately 18,848 rows.

That is a large answer to a problem whose only useful new ingredient appears to be the one-form span. Repairing the status and increasing the byte ceiling would merely expose a much larger sampling and elimination problem.

Adding all 32 forcing letters to the ordinary 2×2 rational strip adds at most

32×4=128

residue coordinates, while retaining the existing gauge support and denominator. A selected subset adds fewer.

The integrability result is weaker than it looks

The residue-only system was

80×192,rank=80.

Because it has full row rank, every 80-component right-hand side is in its column space. Thus its consistency is effectively automatic at that image.

It proves no obstruction, but it gives almost no positive evidence that the complete strip PDE is solvable. The decisive test must use the cokernel of the full rational gauge system, including gauge columns and normalization rows.

3. Select the forcing letters through the full-system cokernel

This avoids 32 full rational solves.

At one of the already established generic images, let

M
0
	​

=[
M
gauge
	​

	​

M
default residues
	​

	​

],M
0
	​

x=b

be the inconsistent ordinary rational system with the minimal denominator and certified support.

For each forcing-derived candidate letter L
j
	​

, let

C
j
	​


be its block of four residue columns. Assemble

C=[
C
1
	​

	​

⋯
	​

C
32
	​

	​

].

Compute a full basis W of the left cokernel:

WM
0
	​

=0.

Then

M
0
	​

x+C
S
	​

y=b

is solvable exactly when

WC
S
	​

y=Wb
	​


is solvable. Equivalently,

rank(WC
S
	​

)=rank[
WC
S
	​

	​

Wb
	​

].

This replaces repeated 7000-dimensional solves by a small projected span problem.

Recommended selection procedure

Build M
0
	​

,b once on the certified degree-58 simplex.

Compute W=kerM
0
T
	​

 once with the native homogeneous-nullspace/RREF machinery.

Evaluate all 32 candidate dlog blocks and form P
j
	​

=WC
j
	​

.

First test the complete set:

rank(P)=rank[P∣Wb].

If this fails, the sampled forcing alphabet cannot repair the rational ansatz.

If it passes, select letter blocks greedily by rank gain, then remove every block whose deletion preserves solvability.

Repeat at the independent prime/regulator image.

The selected letter set must work at both images, but its residue coefficients may differ between images. Do not demand one common residue vector in ϵ.

This gives an irredundant subset. Finding the absolute minimum number of four-column blocks is a group-sparse selection problem, not a single RREF operation. With only 32 blocks and a small cokernel, branch-and-bound is feasible if exact cardinal minimality matters; it is not needed for the production solve.

Practical insertion

The chart fallback currently deletes source-frame "AdditionalLetters" at TransportCharts.wl:2127–2138, correctly, because those letters may belong to a different algebraic frame.

For this recovery, construct the selected letters in the materialized rational chart and call the ordinary solver using:

Wolfram Language
<|
  "Strip" -> rationalStrip,
  "Variables" -> rationalVariables,
  "Regulator" -> epsilon,
  "ExtraLetters" -> selectedChartLetters
|>

Retain:

the original gauge denominator;

the certified total-degree-58 simplex;

the existing normalization convention.

Do not route these through the conservative rank-zero AdditionalLetters path.

4. Avoid constructing 32 symbolic dlogs

The current expensive rank-zero route uses:

Wolfram Language
Together[letter]
Together[D[letter,x]/letter]
Together[D[letter,y]/letter]

in multiquadraticStripLetterOneForm, MultiquadraticStripSolve.wl:1432–1440.

That is the direct source of the 1,513.8-second candidate-dlog stage.

For cokernel selection, symbolic dlog expressions are unnecessary.

Exact modular candidate-column evaluator

Compile each candidate letter as a rational function

L
j
	​

=
D
j
	​

N
j
	​

	​

.

The existing screen evaluator already returns its value and both partial derivatives exactly modulo p:

polynomial value/derivatives:
MultiquadraticStripSolve.wl:2997–3014

rational value/derivatives:
3016–3027

At a point where L
j
	​


=0, obtain

dlogL
j
	​

=(
L
j
	​

∂
x
	​

L
j
	​

	​

,
L
j
	​

∂
y
	​

L
j
	​

	​

)

by one modular inversion. These values directly generate the four residue columns C
j
	​

.

Thus the selection phase can operate entirely on:

the raw epsilon-specialized forcing entries;

their compiled rational numerator/denominator maps;

exact modular derivatives.

No symbolic D/Together dlog needs to be formed.

Exact representation after selection

Only the selected letters need exact dlog construction. Even then, avoid whole-expression combination. If

L=
D
N
	​

,

retain

dlogL=
N
dN
	​

−
D
dD
	​

	​


as a two-term structured form. Differentiation of sparse N,D is linear in their term counts.

The letter L itself is the exact potential, so there is no mathematical need to collapse this into one giant rational expression. The ordinary rational solver can either:

receive the selected letters and perform its existing preparation; or

later be taught to compile the structured log-derivative pair directly.

For tonight, selecting a small subset first and letting FiniteFieldStripSolve.wl construct only those dlogs is the smaller patch.

5. Broker patch review
Mathematical equivalence

The brokered computation is mathematically equivalent to the serial map.

multiquadraticStripDLogShardTask applies the same

Wolfram Language
multiquadraticStripLetterDLogDataInField

independently to each requested index (MultiquadraticStripSolve.wl:1499–1519). The controller restores results by their original index, and malformed groups are recomputed locally.

Formal replacement of the chart variables by \[FormalX],\[FormalY] is exact and avoids helper-context rebinding.

There is no family-specific assumption in this code.

Pooling is only partially dynamic

taskBrokerFreeKernels deliberately returns the family’s queueable helper entitlement, not merely the instantaneous idle count (TaskBroker.wl:173–206). That is compatible with dynamic pool reclamation.

However, multiquadraticStripConstructDLogBatch submits exactly one coarse shard per helper:

Wolfram Language
groups = Table[Range[offset,count,helperCount+1], ...]

at MultiquadraticStripSolve.wl:1575–1582.

Once a helper begins a shard, another worker cannot take its remaining letters. Therefore the pool is dynamic only between shards, not within a heterogeneous shard. One expensive forcing entry can determine the tail.

For 32 expensive forcing dlogs, the better shape is:

one task per forcing letter, or

two to four cost-weighted microshards per available helper;

queue heavy letters first;

compute the 16 trivial rational-factor dlogs locally.

Because every helper memoizes the common payload through taskBrokerRead, one-letter tasks do not repeatedly reload it on the same worker.

The ideal lower bound is approximately

1513.8/8≃189 s,

so the reported 3–5 minute target is realistic if the expensive entries balance.

Deadline handling remains incomplete

The current patch checks the deadline before entering the batch, but:

multiquadraticStripDLogShardTask receives no deadline and processes its complete index list.

The mission kernel executes its local group synchronously at line 1589 with no per-letter deadline.

Malformed groups are recomputed locally at lines 1604–1611 without checks between entries.

The final whole-batch serial fallback at lines 1686–1689 can begin after the deadline.

The minimum correction is:

pass the absolute deadline into each shard;

check it before every letter;

wrap a single expensive dlog evaluation in the remaining TimeConstrained budget if a hard bound is required;

after expiry, return BudgetExhausted without any local fallback;

never launch the final serial fallback after expiry.

TaskBroker.wl:260–301 correctly removes queued work and writes .cancel controls on timeout or abort. The attached source does not include the KernelPool executor, so it does not establish that a running, noncooperative Together is immediately interrupted. Per-letter bounded tasks are therefore also the safest cancellation granularity.

What the attached tests establish

t_multiquadratic_dlog_broker.wls verifies:

helper-cap use;

deterministic ordering;

exact equality with serial data;

formal variables;

timeout propagation;

malformed-shard fallback;

typed expiry.

It does not establish:

live pool preemption of a running symbolic dlog;

dynamic work stealing within a shard;

physical 3–5 minute throughput.

Those are the only meaningful gaps.

Prioritized implementation plan
1. Correct the false status

In multiquadraticStripReconstructRegulator:

propagate SampleMatrixResourceLimit when no structural sample was assembled;

reserve ModularStructureUnstable for conflicting successful rank/nullity results;

remove PivotSignature from the modal-structure vote.

This is a small correctness fix, not the recovery algorithm.

2. Run a full-system cokernel letter selector

Using the existing minimal-denominator, degree-58 rational matrix:

compute its left cokernel once;

evaluate all 32 candidate dlogs modularly from raw letters;

test the complete candidate span;

select an irredundant common subset over two independent images.

This is the decisive next computation.

3. Re-enter the ordinary rational solver

Run one rational reconstruction using:

original minimal denominator;

certified simplex;

selected chart-frame ExtraLetters.

No denominator promotion and no 18,836-unknown fallback.

4. Construct only selected exact dlogs

Use the existing broker after its deadline correction, or simply construct serially if the cokernel leaves only a few letters. Longer term, compile dN/N−dD/D structurally rather than materializing Together[D[L]/L].

5. Generalize the broker only if still needed

Replace one-shard-per-helper with heavy-first microtasks. Retain the current exact index aggregation and formal-variable mechanism.

Dead ends to avoid

Raising the rank-zero dense-matrix byte ceiling.

Promoting the 16 extra denominator copies.

Treating ModularStructureUnstable as evidence about rank or pivots.

Using the 80/80 residue-integrability result as positive evidence; it is full-row-rank and therefore nondiscriminating.

Performing 32 complete rational finite-field solves.

Constructing all 32 forcing dlogs symbolically before determining which ones matter.

Relying on the rank-zero conservative fallback simply because its alphabet was larger.

Returning to finite-field source materialization as a universal normalization method; the measured seven-prime cost is already unfavorable here.

The current evidence isolates the likely missing object as the residue alphabet, not the gauge denominator or numerator support. The full-system cokernel projection tests that hypothesis directly and cheaply.

## Sources sent to Pro

- [cf303_modular_structure_sources.zip](Sources/01_cf303_modular_structure/cf303_modular_structure_sources.zip)
