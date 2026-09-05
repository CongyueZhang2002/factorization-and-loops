# CF259 Denominator Only

## Question

# Independent review request: denominator-only refinement for CF259 (27,9)

Please review the actual current package code in:

- `/home/maxzhang/factorization-and-loops/FeynFacet/Private/MultiquadraticStripSolve.wl`

This is a continuation of our existing **Assess Multiquadratic Pipeline** conversation. We need algorithmic advice on a measured production bottleneck, not more validation layers.

## Measured case

- Family/block: CF259 sector 27, lower sector 9.
- Genuine rank-3 multiquadratic frame; the forcing block is 2 x 2.
- The deferred bundle identifies 41 active factor records, merged into 21 exact denominator groups.
- Construction/materialization is now fast: the complete 66-job helper batch takes about 28--31 seconds; the active-grade census takes about 36 seconds.
- The conservative streamed pole bounds imply an absurd provisional ansatz: 273,245,832 unknowns and a 1.19e18-byte estimate. This is only an upper bound because it ignores cancellations in sums.
- The current refinement `multiquadraticStripBundleRefinedGaugeDenominator` calls `multiquadraticStripBundleExactChannels`, materializes the 8 scalar forcing entries, and fully decomposes each into all 8 radical-basis channels solely to determine the smaller rational gauge denominator. With 8 Wolfram kernels, none of the 8 entries completed after more than four minutes, so the run was stopped.

The only needed output of this stage is the rational denominator/pole support (and degree bounds) for the gauge ansatz. Final block correctness is already decided by the existing fresh random-point exact finite-field residual acceptance. Please do not propose an additional production check.

## Questions

1. What is the smallest general denominator-only algorithm that avoids full exact radical-channel reconstruction? Please inspect and reuse the package's deferred DAG, modular provider, and finite-field infrastructure where possible.
2. In particular, compare:
   - modular divisor-valuation/pole census directly on the deferred expression;
   - Maple or FLINT cancellation/factor extraction without channel reconstruction;
   - an adaptive low-pole gauge ansatz that enlarges only after modular inconsistency;
   - any more direct norm/resultant or local-series method over the multiquadratic extension.
3. Give a concrete data flow and pseudocode: candidate divisor generation, sampling/evaluation, how pole orders are inferred, how radical sheets/grades are handled, and when the method must escalate.
4. Can Fable's two checks from `Exchange/Fable/2026-08-29/04_check_before_raising_caps.md` (block-active denominator support and affine-section/nullity minimality) cheaply prevent this blow-up for (27,9), or do they address a later reconstruction problem rather than this pole-support refinement?
5. Identify any correctness trap that would make a modular pole census underestimate support. We prefer a conservative false-positive (slightly larger ansatz) to any false-negative, but do not want defensive complexity without measured value.

Constraints: no family-specific code, no new acceptance layer, and reject major complexity for a few-percent gain. We want a multi-fold improvement or the simplest reliable path through this block.

## Pro response

Recommendation

GO on a two-stage denominator-only refinement:

First replace the occurrence-based bound by exact denominator propagation through the already canonicalized operand DAG.

Only if that is still too large, compute modular univariate pole images of the complete deferred forcing.

Do not reconstruct the 64 characteristic-zero forcing channels merely to extract their denominators. Do not raise the matrix-size cap.

I inspected the public source at commit cce0e01, including the named refinement functions and Fable’s note. The absolute /home/maxzhang/... path is not mounted here, so I cannot certify differences confined to your uncommitted local file.

1. The current code contains an avoidable source of denominator inflation

The present path is exactly as described:

multiquadraticStripBundleRefinedGaugeDenominator
  -> blockEquationDeferredBundleEvaluate
  -> multiquadraticStripBundleExactChannels
  -> multiquadraticStripDecomposeScalar, for all eight scalar entries
  -> multiquadraticRationalGaugeDenominator

The resulting rational channels are used only to obtain denominator exponents and are not returned for subsequent reuse. This computes substantially more information than this stage needs.

There is an earlier, cheaper opportunity.

In BlockEquationDeferred.wl, the compiler maintains two different denominator records:

CanonicalDenominator: the denominator factors of the already normalized operand value;

ExplicitNegativePower: a scan of negative powers in the source expression.

The latter sums exponents across occurrences throughout an operand, including occurrences in different additive terms. The compiler takes the maximum of these two routes, sums across operands in a product, and stores the result as MaxEntryPoleOrderUpperBound.

multiquadraticStripBundleGaugeDenominator then consumes that pre-cancellation bound.

For example,

f
1
	​

+
f
1
	​


contains two negative-power occurrences but has denominator only f. On the large repeated-expression payloads seen in this campaign, the difference can be enormous.

The explicit-negative-power census is useful provenance and candidate-divisor information. It should not determine multiplicities once an exact canonical operand denominator is available.

I cannot quantify how much of the reported 273,245,832-unknown bound this explains without the live bundle. But the inflation mechanism is present in the inspected code, and removing it requires no new algebraic reconstruction.

2. First implementation: exact canonical-factor propagation

Each OperandTable record already contains

Numerator
DenominatorFactors
RootMask

and each job is a sum of products of those operand IDs. Use these value denominators, not the historical negative-power counts.

Rational clearing factors

For every distinct algebraic denominator factor a, obtain a rational clearing polynomial N
a
	​

 such that

aJ
a
	​

=N
a
	​

,

where J
a
	​

 is integral in the declared root basis.

The existing orbit norm supplies such a polynomial:

N
a
	​

=
σ∈Orbit(a)
∏
	​

σ(a).

For rational a, take N
a
	​

=a, not its degree-eight field norm. Reuse the already computed GaloisOrbits; do not form new norms of complete forcing entries.

Factor the small clearing polynomials into primitive rational curves:

N
a
	​

=
f
∏
	​

f
n
a,f
	​

.

Different orbit norms can share rational factors, so merge at the irreducible-factor level, not merely by equality of whole norm polynomials.

For an operand

O=
∏
a
	​

a
e
a
	​

P
	​

,

a safe rational channel-denominator bound is

u
f
	​

(O)=
a
∑
	​

e
a
	​

n
a,f
	​

.

This assumes P and the chosen root generators are integral over the base polynomial ring. If a root square or numerator coefficient is rational rather than polynomial, include its base-field denominators explicitly.

Propagate through the DAG

For a scalar product term

T=c
j
∏
	​

O
j
	​

,

use

u
f
	​

(T)=u
f
	​

(c)+
j
∑
	​

u
f
	​

(O
j
	​

).

For a complete target entry

B=
T
∑
	​

T,

use

u
f
	​

(B)=
T
max
	​

u
f
	​

(T).
	​


Take the maximum over the eight scalar forcing components.

Also combine identical scalar operand multisets with their exact coefficients before taking the maximum: an exactly cancelled term should not contribute a denominator bound.

Include denominators of each job’s scalar coefficient. The bundle’s Jobs carry those coefficients separately from operand IDs; they must not be assumed to be units.

This bound still ignores cancellations between genuinely different summands, but it is an exact upper bound based on the current values—not on how many times a denominator was written in the original expression.

Output

Pass the resulting forcing exponents through the package’s existing gauge-pole rule and letter correction:

Q
gauge
	​

=lcm
	​

f
∏
	​

f
max(0,u
f
	​

(B)−1)
, Q
letter
	​

	​

.

Retain the assumptions under which that pole rule is used; this proposal changes denominator computation, not the mathematical gauge/target contract.

Keep the result factored. Compute degrees by addition,

deg
x
	​

Q
gauge
	​

=
f
∑
	​

e
f
	​

deg
x
	​

f,deg
y
	​

Q
gauge
	​

=
f
∑
	​

e
f
	​

deg
y
	​

f,

rather than expanding the product. The current public code already carries GaugeDenominatorDegrees through the factor stream.

If this produces a tractable layout, stop refining and solve. There is no reason to discover the absolutely minimal denominator first.

3. If necessary: modular univariate slice-and-gcd pole census

The smallest general next algorithm is specialize the bivariate DAG to a generic affine line over a finite field, evaluate in the eight-grade algebra over F
ℓ
	​

(t), and retain only denominator valuations.

This is not bivariate channel reconstruction. There is:

no characteristic-zero forcing expansion;

no coefficient interpolation or CRT;

no solution of a large affine system;

no need for modular square roots.

The only temporary channel objects are univariate polynomials over a small prime field.

Specialization

Choose a generic regulator value ϵ
0
	​

 and line

x=x
0
	​

+at,y=y
0
	​

+bt

over F
ℓ
	​

. Restrict each root square:

r
i
2
	​

=Δ
i
	​

(x
0
	​

+at,y
0
	​

+bt,ϵ
0
	​

).

Retain the formal eight-element basis. Evaluate the interned operand DAG once and form all eight scalar forcing entries by the existing sum/product incidence.

The current multiquadraticStripBundleProviderChannels already has exactly that decomposition: unique operand evaluation followed by Jobs-indexed products and sums. Its arithmetic is presently scalar modular arithmetic; the new backend changes the coefficient ring to univariate rational functions.

Restrict the scalar coefficients of both one-form components separately. Do not pull the one-form onto the line as (aB
x
	​

+bB
y
	​

)dt: that combination can cancel a pole you need to detect.

Denominator-only representation

Store each intermediate element as

Z=
D
N
0
	​

+N
1
	​

r
1
	​

+⋯+N
7
	​

r
1
	​

r
2
	​

r
3
	​

	​

,N
s
	​

,D∈F
ℓ
	​

[t].

Use:

the existing XOR multiplication law;

recursive quadratic-tower inversion;

univariate polynomial gcd and exact division;

local common-denominator cancellation.

At completion, the common denominator of all eight rational channels is simply

D
reduced
	​

=
gcd(D,N
0
	​

,…,N
7
	​

)
D
	​

.
	​


You do not need eight separately reduced rational functions, much less their bivariate characteristic-zero lifts.

FLINT’s nmod_poly supplies the required multiplication, gcd, division, and series operations. This is a small coefficient-ring adapter, not a new reconstruction framework. 
Flint Library

Match the denominator to the known source curves

For every candidate curve f, compute

h
f
	​

(t)=f(x
0
	​

+at,y
0
	​

+bt,ϵ
0
	​

).

Require a good line on which:

the expected degree of each candidate is retained;

h
f
	​

 is squarefree;

distinct candidate curves do not acquire a common factor;

no denominator becomes identically zero.

Then determine the largest exponent of any factor of h
f
	​

 in D
reduced
	​

.

Full univariate factorization is unnecessary. Repeatedly compute

g=gcd(D
work
	​

,h
f
	​

),D
work
	​

←D
work
	​

/g

until g=1. The number of iterations is the maximum multiplicity among components of h
f
	​

.

Take the maximum across:

all eight scalar forcing entries;

independent lines;

generic regulator values;

primes used by the census.

This captures cancellation after the complete recurrence sum, which the streamed upper bound cannot.

Ramified curves

This univariate quotient-algebra route handles divisors contained in a root square without requiring Puiseux branches. The rational coefficients are computed in the declared basis before their denominators are inspected.

That is safer than measuring the pole order on one square-root sheet. The desired quantity is the pole order of the rational channel coefficients, not merely the valuation of the algebraic scalar on one branch.

If univariate polynomial degrees themselves become large, change only the difficult curve calculation to arithmetic modulo h
f
k
	​

, extracting the required principal part. That local-series route is a second optimization, not the first implementation.

4. Concrete data flow

The following describes new denominator-only logic, not existing function names.

RefineBundleDenominator(bundle, roots, letters):

    factors = canonical rational factors of:
        canonical operand denominator clearings
        job-coefficient denominator clearings
        required root-presentation denominators
        existing letter correction

    upper = propagate canonical factor orders:
        product -> sum of orders
        target sum -> maximum of term orders
        block -> maximum over target components

    Q = existingGaugePoleRule(upper, letters)

    if projected_layout(Q) is tractable:
        return Q, factored degrees, method="CanonicalOperandBound"

    observed = zero pole-order vector
    unresolved = empty set

    for a small collection of good (prime, epsilon, affine-line) images:

        delta_i(t) = restrict root squares
        factor_images = restrict candidate factors

        reject degenerate line before evaluating the large DAG

        operand_images =
            evaluate each unique OperandTable entry once
            in the 8-grade algebra over F_prime(t)

        for each Job:
            image = sum of its complete coefficient-times-product terms
            Djob = common denominator / joint numerator gcd

            update observed[f] from gcd multiplicities of Djob
            against the image of f

    uncertain factors retain their exact structural upper bounds

    proposal = existingGaugePoleRule(observed, letters)
    return proposal, unresolved upper bounds, factored degrees

No forcing-channel tensor is returned or reconstructed.

Where to patch

Replace the body of multiquadraticStripBundleRefinedGaugeDenominator, keeping its downstream denominator/degree interface.

Reuse:

bundle["OperandTable"], bundle["Jobs"];

DivisorSummary["GaloisOrbits"];

the modular provider’s unique-leaf and occurrence maps;

the existing grade multiplication and tower-inversion formulas;

multiquadraticStripMergeGaugeDenominatorSourceData;

existing layout-size estimation.

Do not construct a full preparation merely to run the census: denominator refinement occurs before that preparation’s support can safely be allocated.

The present helper also hardcodes a 7,200-second task timeout and recomputes missing full decompositions locally. Those semantics are particularly unhelpful for this stage; a failed denominator image should leave only that image or divisor unresolved, not restart a complete characteristic-zero entry decomposition.

5. Comparison of the alternatives
Method	Recommendation	Reason
Canonical operand denominators + DAG order propagation	First	Exact, minimal patch, uses work already completed; can remove syntactic multiplicity inflation
Modular univariate grade evaluation + denominator gcd	Second	Detects full-sum cancellations without bivariate reconstruction; reuses the DAG
Local divisor-adic/Laurent-series evaluation	Escalation for expensive curves	Computes only principal parts, but needs careful precision and nonunit handling
Maple normalization of complete forcing entries	Not first	Again asks a CAS for the entire algebraic value rather than the needed poles
Full FLINT multivariate channel cancellation	Not first	Faster arithmetic on the same overlarge intermediate is not the smallest algorithmic change
Adaptive low-pole ansatz, enlarged after inconsistency	Fallback policy only	Inconsistency does not identify whether the missing ingredient is a pole, numerator mode, or target form
Norm/resultant of the complete forcing	Reject	Can hide poles through cancellation against conjugate zeros

For the last point, let r
2
=d and

z=
r−1
r+1
	​

.

Its field norm is 1, yet

z=
d−1
d+1+2r
	​


has rational channel denominators d−1. Norms are useful for candidate denominator clearings, not for measuring the actual poles of the complete forcing.

6. What the two Fable checks can establish

I read Exchange/Fable/2026-08-29/04_check_before_raising_caps.md. It asks whether the denominator is block-active and whether a solved affine section is minimal modulo its homogeneous kernel.

Block-active denominator support

This is relevant but insufficient.

It can eliminate dead family-wide factors. It cannot distinguish:

one active factor appearing 200 times syntactically;

that factor appearing once in a canonical operand denominator;

the factor cancelling after the final forcing sum.

Your 41 records merged into 21 groups can all be genuinely block-active while their multiplicities are grossly inflated.

Affine-section/nullity minimality

This concerns the representation of a solved gauge and its later reconstruction or pullback. There is not yet a tractable affine system here.

It cannot explain or reduce a pre-solve 273-million-unknown denominator proposal. Apply that check later, not as a reason to regard the current pole bound as genuine.

7. Underestimation traps—and the limit of modular evidence

There is a fundamental distinction:

A generic modular pole image usually reveals the correct pole order, but an observed pole order is a lower bound on the generic order, not a deterministic upper-bound certificate.

A leading coefficient can vanish at a special regulator value, line, or prime. Taking maxima across images reduces that risk; it does not turn sampling into an absolute no-false-negative theorem.

Accordingly:

The canonical-factor propagation in stage 1 is a genuine conservative upper bound.

A lowered modular result is an ansatz proposal unless the removed principal parts are proved identically zero.

Failure of the resulting gauge ansatz must not be reported as a mathematical no-go; unresolved poles remain eligible for targeted restoration.

The existing final block residual catches an incorrect reconstructed gauge. It cannot reveal a valid gauge that was excluded because its necessary denominator was omitted.

The specific traps to prevent are:

Using a minimum or modal pole order. Use the maximum observed order.

One regulator specialization. It can cancel a leading pole coefficient.

One radical sheet. Use the complete grade algebra; no single embedding separates the channels.

Restricting the one-form instead of its scalar components. Keep B
x
	​

,B
y
	​

 separate.

Ignoring job-coefficient denominators.

Dropping factors whose specialized degree vanishes. Reject that specialization.

Confusing a split norm factor with an independently identified source curve.

Truncated series reported as zero. Insufficient precision is unresolved, not cancellation.

Omitting infinity growth. Finite denominator orders do not alone give the numerator-degree bound. Keep the established projective support rule, or measure infinity valuations separately.

Adding a universal “one extra pole” safety margin. It is not a guarantee and can recreate the present support explosion.

If strictly certified denominator lowering is required for a particular uncertain factor, compute only its disputed high-order principal parts in the divisor-local algebra. That is part of denominator determination—not another production acceptance layer—and is much smaller than reconstructing every forcing coefficient.

Immediate implementation decision

First implement canonical-denominator DAG propagation in the existing refinement entry point. It should use the completed operand normalization and the 21 small denominator groups, without touching the eight large forcing expressions.

If the resulting layout is still oversized, run one native univariate slice image for all eight scalar components together. Use a bounded decision:

continue if one image completes within roughly 30 seconds and a small collection produces a tractable denominator in under two minutes;

if one image exceeds 60 seconds because univariate degrees grow excessively, switch the costly factors to local divisor-adic arithmetic rather than extending the global computation;

retain the existing per-block random-point acceptance unchanged.

Those are pilot thresholds, not measured speed predictions.

The best first patch is smaller than a new reconstruction engine: stop letting cancelled source-expression occurrences control denominator multiplicities. Then use modular one-variable pole arithmetic only for the cancellations that remain invisible to the exact DAG bound.
