Verdict: CORRECT FIRST, then GO

I reviewed all 756 lines of the attached FiniteFieldDeferredInhomogeneity.wl, not the older GitHub version. The main design is now correct: the plan can declare all three roots, preserve the rational images of the selected pair, and reject unwanted grades before contracting the summed entry.

The remaining substantive corrections are:

remove ambiguous defaults in the full-root/selected-root mapping;

repair the nested provider identity when rebuilding a helper plan;

make point admission distinguish unusable points from mathematical failures, and use it before the main sampler’s prefetch;

replace the denominator radical-guessing path by small-factor residual norms;

replace the denominator census’s degree-only consistency test by actual polynomial coverage.

These changes do not require characteristic-zero materialization of the inhomogeneity.

Line numbers below refer to the attached source. This is a static review; the current native adapter and main finite-field sampler were not attached, so I identify their required interfaces without claiming to have executed them.

1. Full-root indexing: the separation is right; the defaults remain unsafe
What is already correct

In finiteFieldDeferredInhomogeneityPlan, the attached version distinguishes:

Roots                       complete evaluator root list
RationalizedRootIndices      positions assigned rational images
UnrationalizedRootIndices    complementary positions
RootImages                   images in selected-root order

It passes the complete list to both the coefficient tables and native provider. PointData compares the supplied rational images against dv[[rationalizedRootIndices]], then places those images into the corresponding positions of the complete root-value vector. That is the correct indexing operation.

FiniteFieldDeferredInhomogeneity +1

For complete order {r1,r2,r3} and selected pair {r1,r3}, the required interpretation is:

RationalizedRootIndices   = {1,3}
UnrationalizedRootIndices = {2}
RootImages                = {imageOfR1,imageOfR3}

These are positions in Roots, not necessarily family root IDs.

Correct lines 131–152

Two defaults can recreate the original underdeclaration:

Wolfram Language
allRoots = Lookup[coefficientPresentation,
  "SquareRootGenerators", usedRoots];

rationalizedRootIndices = Lookup[deferredPreparation,
  "SquareRootGeneratorIndices", Range[Length[usedRoots]]];

For a deferred preparation, the complete evaluator list must come from its complete declared coefficient presentation. Falling back to usedRoots silently restores the assumption that evaluation needs only the roots surviving in the final answer.

Similarly, Range[Length[usedRoots]] is not a valid default for a sparse subset such as {1,3}.

Smallest correction:

require the complete root declaration for this route, or obtain it from an explicitly documented equivalent preparation field;

derive selected positions by matching usedRoots against that declaration;

if supplied positions are retained, require that they identify those same generators;

return a plan-input failure when the complete declaration is unavailable—do not infer completeness from the selected pair.

The current full-association comparison

Wolfram Language
SameQ[allRoots[[rationalizedRootIndices]], usedRoots]

is stronger than the mathematical requirement. It can reject equivalent generator records merely because one contains additional fields. Compare the normalized generator-defining records used by the evaluator, not entire associations.

Do not weaken this to square-class equality alone. If one generator differs from another by a rational multiplier or sign, that multiplier belongs explicitly in the root-image map.

2. Helper rebuilding has a concrete nested-ID inconsistency

EnsurePlan calls Plan, which creates a new identifier and writes it into:

plan["Key"]
plan["Provider","ProviderID"]

The helper then replaces only the outer "Key" with the descriptor key:

Wolfram Language
$finiteFieldDeferredInhomogeneityRegistry[key] =
  Join[plan, <|"Key" -> key, "Slim" -> True|>];

But Preflights emits ProviderID -> plan["Key"]. The rebuilt provider and its preflights therefore carry different identifiers. The inconsistency is visible entirely within the attachment; whether the native adapter rejects it depends on that adapter’s current contract.

FiniteFieldDeferredInhomogeneity +1

Minimal correction at lines 222–225

Replace the rebinding with:

Wolfram Language
KeyDropFrom[$finiteFieldDeferredInhomogeneityRegistry, plan["Key"]];

plan = Join[plan, <|
  "Key" -> key,
  "Slim" -> True,
  "Provider" -> Join[plan["Provider"], <|"ProviderID" -> key|>]
|>];

$finiteFieldDeferredInhomogeneityRegistry[key] = plan;

The full-root order and selected positions are otherwise carried through the handle correctly. Preserve that.

Also normalize generator records once, before constructing either the original plan or its handle. Currently only Handle strips them to "Generator", "QuadraticRadicand" and "SourceRadicand". The main and helper providers should consume the same mathematical generator representation, including every field actually required to recognize the source radical spelling.

3. Point selection: fix admission, then connect it to the actual sampler

The new SelectSplitImages is called by both Census and ResidualQ. That is progress beyond the older implementation. However, it is not yet a robust admissible-point collector.

A. One singular candidate currently aborts the whole selection

RationalAt returns at the first zero denominator. PointData propagates that failure for the entire candidate batch. Consequently, a batch containing hundreds of useful points and one chart pole cannot be filtered: it fails before SelectSplitImages receives a mask. A pole in a radicand denominator is additionally labeled RootImageMismatch, although it is simply an undefined evaluation point.

FiniteFieldDeferredInhomogeneity

This matters because the new census deliberately oversamples:

Wolfram Language
4 splitFactor lineCount

The larger the candidate batch, the more likely it includes an isolated bad point.

Change the candidate-admission path to return values plus a per-point validity mask.

A masked rational evaluator can replace zero denominators by one only for performing the vector arithmetic, while marking those positions invalid. Never expose the resulting placeholder values as accepted samples.

Accumulate masks for:

substitution denominators;

radicand denominators;

rational-root-image denominators;

zero radicands;

Jacobian poles and zero determinant.

Compare root identities only on positions where their inputs are defined.

The distinction must remain:

Event	Treatment
Undefined chart/radicand value, zero radicand, nonsplit residual root, singular Jacobian	Reject that point and replenish
Rational image does not square to the declared radicand at a regular point	Reject the plan/image as an error
Summed entry has a nonzero unwanted grade	Reject the rationalized-subfield route
Malformed declaration or undeclared radical	Reject the input; do not resample

The attached code checks Jacobian denominators but not its determinant in Images, lines 469–473. Include the determinant in the small-data preflight rather than discovering degeneracy after evaluating the large DAG.

FiniteFieldDeferredInhomogeneity

B. Compute square roots only for residual generators

Lines 315–324 currently test and compute modular square roots for all generators, then overwrite the rationalized ones with their known images.

Instead:

initialize the complete root-value vector;

install the signed rational images at RationalizedRootIndices;

reject a zero installed image;

perform residue tests and modular square-root extraction only at UnrationalizedRootIndices.

This avoids unnecessary square-root work and makes the distinction explicit. It does not change the mathematical result.

C. Reuse accepted preflight data

SelectSplitImages computes all point data, discards it, and Images → Preflights computes it again. Return the selected preflight records alongside "Images" and "Indices" and allow the internal batch call to reuse them.

This is a small change, not a new evaluation architecture.

D. Replenish and deduplicate

SelectSplitImages currently selects from one supplied list and returns InsufficientSplitPoints otherwise. It neither replenishes nor removes duplicates. The census and residual callers likewise make only one oversampled draw.

FiniteFieldDeferredInhomogeneity +1

Keep the selector as a filter if convenient, but put it inside a bounded acquisition loop:

draw candidate batch
→ classify admissibility
→ retain distinct accepted coordinates
→ append
→ replenish until requested count or attempt limit

For the line census, retain the actual selected tValues exactly as the current code does. Do not renumber accepted points to a fictitious consecutive sequence.

A line on which the residual radicand is a nonsquare constant can supply no split points. That is a reason to choose another line, not evidence that the inhomogeneity is outside the rational subfield.

E. The main finite-field sampler must select before prefetch

The attachment contains the selector’s census and residual call sites, but not the main affine sampler. Therefore it does not establish that the production solve uses admissible points.

In FiniteFieldOffDiagonalBlockSolve.wl, apply this admission step at all three places:

the initial kinematic-point draw;

the multi-epsilon prefetch batch;

the refill after an equation point is rejected.

Ensure the helper plan exists before invoking selection on a helper kernel.

Do not make finiteFieldDeferredInhomogeneityImages silently discard points. Its return values must stay in one-to-one correspondence with its input images; otherwise the equation rows and cached RHS values can become misaligned.

Root splitting may be reused across epsilon values only when the relevant substitution and radicands are epsilon-independent. DAG denominator poles can still depend on epsilon.

Finally, a native SingularImage can occur even at a split point because an intermediate denominator vanishes on one sign choice. Isolate/reject that point—using existing denominator exclusions or failure-only batch isolation. Do not turn all native failures into resampling.

4. Unwanted-grade projection is implemented correctly

The new check at lines 453–466 is the right statement for the complete source-grade representation:

Wolfram Language
unrationalizedMask =
  Total[2^(plan["UnrationalizedRootIndices"] - 1)];

It checks all grades whose bit mask intersects that mask, before contraction. For complete order {r1,r2,r3} with residual root r2:

forbidden grades={2,3,6,7},Wolfram slots={3,4,7,8}.

That is exactly what the code constructs. It also checks all bases, differential components and matrix entries.

FiniteFieldDeferredInhomogeneity

Keep this check after complete-entry summation. The native adapter must return grade coefficients of the summed record, not of unsummed operands.

After this check, contracting all eight grades as the current code does is mathematically equivalent to contracting only the allowed grades: the forbidden ones are zero. There is no need to rewrite the contraction merely for appearance.

The contraction must use the signed rational images of roots 1 and 3. The current overwrite in PointData accomplishes that.

Keep one interface requirement explicit

The indexing assumes:

InhomogeneityBatch:
    {base point, one-form component, matrix row, matrix column, grade}

with GradeCount == 2^Length[plan["Roots"]].

That shape and grade order must be the native adapter’s actual contract. A returned status name alone cannot establish them. The current C/writer is not part of this attachment, so I cannot confirm its V2 field translation here.

Do not oversell the result

Zero unwanted grades on sampled points are exact finite-field equalities and probabilistic evidence of generic subfield membership. They are not a characteristic-zero proof merely because many points were used.

Use the same gate in the existing fresh-point block residual. Never select points according to whether unwanted grades happen to vanish.

Restriction to split points does not change interpolation equations. Its effect is on sample availability and the probability of missing a nonzero residual; it requires no statistical reweighting.

5. Denominator construction needs the largest mathematical correction
A. Residual-root norms are still absent

CandidateFactors, lines 574–590, still attempts radical variants and then drops pieces that remain non-polynomial. Thus it does not yet cover denominators whose residual-root dependence cancels only in the final sum.

FiniteFieldDeferredInhomogeneity

For example,

a+R
1
	​

+
a−R
1
	​

=
a
2
−δ
2a
	​

,R
2
=δ.

Dropping the two algebraic denominator bases misses the rational factor a
2
−δ.

Replace this step with norms of individual denominator bases. Do not norm the full inhomogeneity.

For each distinct denominator base:

apply the declared rationalized-root images and coordinate substitution;

retain the residual generator formally;

reduce that small factor to

d=
h
A+BR
	​

,R
2
=
D
δ
	​

N
δ
	​

	​

;

include the polynomial

A
2
D
δ
	​

−B
2
N
δ
	​

	​


among the denominator candidates;

retain the rational clearing factors from h, D
δ
	​

, the substitution and the Jacobian as conservative candidates;

factor and deduplicate those small polynomials.

Prefer existing factor/norm information in the preparation when available. With more residual roots, eliminate them successively by conjugate multiplication on each factor.

This is characteristic-zero manipulation of small denominator factors, not materialization of a summed matrix entry. The final line census determines which candidates actually survive.

B. PolynomialRoot has a real scalar-content defect

At lines 526–527:

Wolfram Language
factors = Rest[FactorList[poly]]

discards the overall numerical factor before deciding whether the polynomial is a rational square. FactorList explicitly puts that numerical factor first.
Wolfram Documentation
 The attached helper therefore cannot correctly handle scalar content.

FiniteFieldDeferredInhomogeneity

For example, its formula returns x+1 for

4(x+1)
2
,

rather than 2(x+1); it also treats 2(x+1)
2
 as though it had a rational square root.

The preferred correction is to stop using this rediscovery mechanism for declared roots: use their accepted rational images. If the helper remains for other small factors, fix it:

Wolfram Language
finiteFieldDeferredInhomogeneityPolynomialRoot[poly_] := Module[
  {fl, scalar, scalarRoot, factors},
  If[TrueQ[poly === 0], Return[0]];
  fl = FactorList[poly];
  scalar = fl[[1, 1]]^fl[[1, 2]];
  scalarRoot = Sqrt[scalar];
  factors = Rest[fl];

  If[
    ! MatchQ[scalarRoot, _Integer | _Rational] ||
    ! AllTrue[factors, EvenQ[Last[#]] &],
    Return[$Failed]
  ];

  scalarRoot Times @@
    (#[[1]]^(#[[2]]/2) & /@ factors)
];

This helper assumes polynomial input over the rational coefficient field. It should not silently introduce algebraic constant extensions.

The related RadicalVariants routine also infers independent sign choices from syntactic square-root expressions. For the proposed route, the declared generator map is a better source of sign relationships than that inference.

6. The denominator census’s degree check is not enough

At lines 647–649, "DegreeConsistent" checks only

i
∑
	​

m
i
	​

degf
i
	​

=degD.

It does not check that the candidate product actually equals the fitted denominator. Each multiplicity is currently computed against a fresh copy of D.

FiniteFieldDeferredInhomogeneity

A small counterexample is:

D(t)=t(t−1),f
1
	​

(t)=t,f
2
	​

(t)=2t.

Both multiplicities are one, so the degree sum is two and the current check passes. But the proposed product is proportional to t
2
, not t(t−1).

Distinct multivariate candidates can become proportional or share factors after restriction to an exceptional line, so this is relevant even if the global list was deduplicated.

Minimal correction

Normalize the line factors up to nonzero scalars. Reject/rechoose a line when active candidate factors lose the required degree or collide.

Then either:

divide the fitted denominator successively by the candidates and require the final quotient to be constant; or

compare the normalized fitted denominator directly with

i
∏
	​

f
i
m
i
	​

	​

.

Use this instead of the degree-sum test. It is a tiny finite-field polynomial operation, not an additional production verification layer.

If an unexplained denominator factor remains, return it as the census failure. Do not treat matching total degrees as coverage, and do not respond by materializing the source expression.

One integration detail also needs explicit interpretation: line 661 stores the observed inhomogeneity pole multiplicities k>1 under

OffDiagonalBasisTransformationDenominatorFactorPowers

without subtracting one. The consumer must know whether these are source pole orders or final ansatz exponents. Under the current adopted k−1 rule, that subtraction must occur exactly once. The attachment does not contain the consumer, so this is an interface condition rather than a demonstrated exponent bug.

7. Shortest corrected production route

Keep the current full-orbit native evaluator and rational solver. The required changes are local:

Component	Action
Plan	Require the complete evaluator root declaration; derive selected positions without prefix assumptions
EnsurePlan	Rebind both the outer key and nested provider ID
PointData	Return per-point admissibility; compute roots only for residual generators; include Jacobian regularity
Point acquisition	Replenish distinct accepted points before census, solve prefetch and residual evaluation
Images	Keep the existing unwanted-grade gate and signed contraction
CandidateFactors	Replace unresolved-radical dropping with small-factor residual norms
Census	Require actual denominator coverage, not equality of degrees
Main sampler	Preserve point/value alignment in initial batches, epsilon waves and refills

The focused closing cases are correspondingly small: a permuted root declaration, helper rebuilding, a candidate batch with one singular point, a cancelling conjugate denominator pair, and the same pair with an added nonzero residual-root term. The latter must produce DeferredInhomogeneityOutsideRationalizedSubfield, not another sampled point.

Do not start a native residual-only or quadratic-pair backend rewrite to finish this patch. Those can later reduce eight sign evaluations to two, or eliminate split filtering, but the attached full-orbit implementation is already the shortest route through the present CF259 case.

Bottom line: the full-root evaluation and unwanted-grade projection are now substantially in place. The critical remaining work is correct point acquisition and complete denominator-factor generation, plus the small helper-rebinding repair. None requires Together on the full inhomogeneity, exact chart projection of all entries, or any return to the pathological materialization path.