# CF259 Pullback Optimization

## Question

_The question was not preserved in the local bridge record._

## Pro response

Recommendation

GO: replace the repeated common-denominator ladder with shared sampling, one-time per-output degree discovery, and a shared numerator-elimination step.

At the observed degrees, this is a small rational-interpolation problem—not another gauge solve. Do not rerun the 11,764-variable system, and do not make a new symbolic denominator-factorization engine a prerequisite.

The immediate implementation should:

retain every existing fibre and successful degree model;

evaluate all four matrix entries and their four source grades together;

discover each reduced denominator separately;

recover all numerators through one shared interpolation matrix.

The earlier reconstruction proposal already separated the cheap composed black box from its unnecessarily large symbolic representation. That remains the correct boundary. 

11_reconstruct_dont_simplify

1. Infer degrees once; distinguish an undersized denominator from false sharing

Write the source gauge as

G
ij
	​

=
S∈{0,1,2,12}
∑
	​

f
ij,S
	​

(x,y,ϵ)r
S
	​

.

There are at most 16 rational outputs, indexed below by o=(i,j,S).

A common denominator always exists—but need not have the proposed degree

If the reduced outputs are f
o
	​

=N
o
	​

/D
o
	​

, then

D
common
	​

=lcm
o
	​

D
o
	​


is valid. Its bidegree is not generally the componentwise maximum of the individual denominator bidegrees.

Consequently, failures of shared models such as (10,13) do not distinguish:

an underestimated degree for even one output;

different denominator factors across outputs;

an unnecessarily restrictive numerator bound after common-denominator clearing.

Recover individual denominator models first. Share a denominator only when its factor profile—or an explicit common multiple—justifies it.

Use transverse univariate fibres to stop the degree ladder

Reuse the available fibres to reconstruct

f
o
	​

(x,y
0
	​

,ϵ
0
	​

),f
o
	​

(x
0
	​

,y,ϵ
0
	​

).

At generic anchors, the reduced univariate numerator/denominator degrees give the corresponding bidegrees. Use two anchors per direction to avoid interpreting a specialized cancellation or vanishing leading coefficient as the generic degree.

For the currently viable bounds:

in x: numerator degree 12, denominator degree 11 requires 24 coefficients after normalization;

in y: numerator degree 15, denominator degree 14 requires 30.

Thus short fibres—approximately 28 and 34 values respectively—are enough for construction. All 16 outputs share those evaluations. Univariate reconstruction followed by multivariate interpolation is an established finite-field reconstruction strategy. 
arXiv

Do not restart from (10,13) at each prime or entry. Preserve the successful (11,14)/(12,15) bounds as the starting envelope, with smaller output-specific bounds where already learned.

One important normalization issue: denominators made monic separately on y=y
0
	​

 are scaled by a generally y
0
	​

-dependent leading coefficient. Their coefficients cannot simply be polynomial-interpolated across fibres. Use the fibres for degree discovery, then recover the bivariate denominator with the small joint fit below.

Can the chart determine the denominator directly?

Yes, as a candidate divisor bound, usually not the reduced answer.

Starting from the actual chart-gauge denominator—not every alphabet letter—pull its factors and the inverse-coordinate denominators into the four-grade field. After integral denominator clearing, write

G
e
	​

=
B
A
e
	​

	​

.

Then

B
#
=
σ

=1
∏
	​

σ(B),D
∗
	​

=Norm(B)=BB
#

gives

G
e
	​

=
D
∗
	​

A
e
	​

B
#
	​

.

Hence all reduced source-channel denominators divide D
∗
	​

. Include inverse-map denominators and any root-generator rescalings; the original source-connection denominator list alone is not necessarily sufficient.

Retain D
∗
	​

 as a factored/evaluable circuit. Strip base-field content and use lower-rank norms for factors involving only one root, rather than automatically taking a fourth-degree norm of everything.

For this block, however, do not delay completion to reconstruct a potentially inflated D
∗
	​

. Denominators of bidegree around (11,14) are small enough to recover directly.

2. Share the numerator elimination—not an unjustified common denominator

For a fixed prime and regulator value, store one table

Y
ko
	​

=f
o
	​

(x
k
	​

,y
k
	​

,ϵ),

with source points as rows and the 16 outputs as columns.

The same point evaluation should reuse inverse-map coordinates, root arithmetic, chart monomials, and the chart denominator across all entries. Whether this uses the existing four-sheet evaluator or quotient-grade evaluator need not change for the first patch.

Concrete small linear algebra

For the observed rectangular bounds,

n
N
	​

=(12+1)(15+1)=208,n
D
	​

=(11+1)(14+1)=180.

A scalar rational fit has

208+180−1=387

free coefficients. Use roughly 400 existing or accumulated generic points, not a sequence of repeated fits on freshly evaluated points.

Build once:

(V
N
	​

)
km
	​

=x
k
a
m
	​

	​

y
k
b
m
	​

	​

,(V
D
	​

)
kn
	​

=x
k
c
n
	​

	​

y
k
d
n
	​

	​

.

For output o,

V
N
	​

n
o
	​

−diag(Y
o
	​

)V
D
	​

d
o
	​

=0.

Choose 208 rows I for which V
N,I
	​

 is invertible, let R denote the other rows, and compute once

T=V
N,R
	​

V
N,I
−1
	​

.

The denominator alone satisfies

K
o
	​

d
o
	​

=0,K
o
	​

=diag(Y
R,o
	​

)V
D,R
	​

−Tdiag(Y
I,o
	​

)V
D,I
	​

.
	​


With 400 points, each denominator problem is only

192×180.
	​


After normalizing d
o
	​

, recover

n
o
	​

=V
N,I
−1
	​

[diag(Y
I,o
	​

)V
D,I
	​

d
o
	​

].

Collect these RHS vectors and recover all numerators in one multi-RHS solve. FLINT already supplies matrix-RHS solves and reusable triangular solves; no new numerical backend is needed. 
Flint Library

What does and does not share

Shares: source evaluations, power tables, V
N
	​

,V
D
	​

, the numerator factorization, and the final numerator multi-RHS solve.

Does not share automatically: K
o
	​

, because it contains the output values Y
o
	​

. Four unknown rational denominators do not turn into four RHS columns of one identical rational-fitting matrix.

For outputs with smaller support, group equal support layouts. If the union is modest, use the common envelope initially and reduce the resulting numerator/denominator pair. A kernel larger than the expected scaling freedom can indicate polynomial multiples introduced by loose bounds; it is not automatically a failure of the rational function.

3. The best middle path

Use individual or small-group denominator multiples, then polynomial multi-output interpolation. A globally reduced common denominator is unnecessary.

Once any sufficient denominator 
D
o
	​

 is known,

P
o
	​

=
D
o
	​

f
o
	​


is polynomial. Different 
D
o
	​

 values are perfectly compatible with one shared numerator interpolation:

V
N
	​

C=(
D
1
	​

Y
1
	​

	​

D
2
	​

Y
2
	​

	​

⋯
	​

D
16
	​

Y
16
	​

	​

).

The denominators may differ; only the numerator support matrix must agree.

At these degrees, use this order:

Recover each denominator once with the 192×180 projected solve.

Normalize/reduce the resulting modular fractions.

Learn their sparse supports and identify genuinely shared denominator profiles.

On later fibres, reuse those profiles and the common numerator matrix.

If the denominator candidates from the chart map are already available, factor-by-factor valuation recovery can replace step 1. On a generic fibre, compare the reduced denominator with restrictions of the candidate factors and recover their multiplicities. Factor the small candidates, not a large symbolic source composition. FLINT’s multivariate factor interface supplies factors and exponents directly. 
Flint Library

If the chart denominator and inverse map are epsilon-free, the generic kinematic pole factors are fixed across epsilon. Special epsilon values can cancel factors, but should not redefine the generic denominator model. Learn that model once per prime rather than repeating the same degree search at every epsilon.

A raw full norm that inflates a roughly 208-monomial numerator to thousands of monomials is not the fastest route. At these modest degrees, the small independent denominator solves are preferable.

Later, when denominators are known and new samples are needed, a 13×16 Cartesian grid permits tensor-product polynomial interpolation rather than dense elimination. Do not discard existing irregular samples just to adopt a grid. FLINT already supports univariate interpolation and reusable interpolation data for that tensor-product implementation. 
Flint Library

4. Persist reconstruction progress at the correct boundary

The retry boundary should be after the completed chart solve and inside source pullback, not at the original strip solver.

State	What must survive a retry
Completed chart solve	Exact chart gauge, its denominator/support, residue result, inverse map and ordered root relations
Sample bank	Prime, epsilon, source point, all available output values; retain samples from failed degree models
Degree discovery	Successful per-output bidegrees, fitted univariate fibres, and already excluded model bounds
Bivariate fitting	Numerator/denominator support lists, denominator normalization choice, interpolation row selection and reusable factorization
Partial reconstruction	Completed output coefficients per prime/epsilon, partial CRT accumulators, lifted coordinates, unresolved-coordinate list
Progress	Next required fibre/prime and which entries or grades are already complete

The most important rule is:

Changing a denominator model must not invalidate the black-box sample table.

Those values are evaluations of the same fixed gauge, irrespective of which interpolation model failed.

The four-dimensional affine gauge freedom was fixed by the completed inner solve. Pullback reconstruction must not rediscover it. Its rational fits have only the usual numerator/denominator scaling ambiguity.

Future solve-startup caching is separate: preserving the 11,764-variable preparation and FLINT discovery plan helps interrupted or repeated inner solves. It provides no speedup to the current pullback beyond preventing the orchestrator from mistakenly restarting that completed stage. The prior campaign already separated completed finite-field solve artifacts from downstream canonicalization work. 

08_three_root_slowdown_and_reco…

5. Bounded implementation order
Immediate patch

Implement the shared sample bank and successful-degree reuse first. Then add the shared numerator-elimination formula above.

For one existing construction prime and epsilon:

reuse all saved samples;

fill only missing point/output values;

start with the successful per-output bounds;

use approximately 400 points for the largest (12,15)/(11,14) envelope;

solve the small denominator systems;

recover the numerators together.

This is a localized replacement for the adaptive pullback fitter. It does not touch the gauge PDE or its 8-minute discovery stage.

Second step, only where inexpensive

Use known chart-denominator factors to turn recurring denominators into fixed polynomial models. Do not build a general factor-lifting subsystem merely to avoid a 192×180 solve.

If epsilon denominators of the chart coefficients are explicitly known, reuse them too: multiply by the known regulator denominator and interpolate polynomially in epsilon instead of rediscovering rational degree profiles.

Performance expectation and stopping rule

Measured: the current pair of prime jobs takes 53.7 seconds, with individual jobs around 48 seconds. The supplied evidence does not separate evaluation, rejected degree trials, interpolation, and lifting.

Plausible improvement: eliminating repeated model trials and cross-entry evaluations can give a multi-fold reduction. Shrinking only the linear algebra cannot guarantee that if black-box evaluation already dominates.

Use the same two-prime construction workload as the bounded decision:

Keep the new fitter if it completes in 25 seconds or less, at the same resources and comparable cache state.

If it remains around 40–50 seconds, retain the simple sample/resume improvements but do not harden a larger denominator-inference framework.

Permit one output-specific correction beyond the currently successful degree envelope if a fibre establishes that it is necessary; do not resume a block-wide Cartesian degree ladder.

Leave the existing per-block random-point acceptance unchanged.

Bottom line

The next implementation should be:

one vector-valued sample bank→per-output denominator discovery→shared numerator elimination/interpolation→existing epsilon reconstruction and CRT.
	​


This distinguishes genuine denominator differences from underestimated degrees, reuses almost all expensive work, and replaces repeated adaptive searches with small algebra. A universal shared denominator is optional—not the organizing principle of the pullback reconstruction.
