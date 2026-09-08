# Native complex-ball boundary continuation

## Question

We are further optimizing our general NNLO DE numerical evaluator, keeping accuracy goals, Laurent orders and independent AMFlow comparisons. Previous AMFlow native/Kira optimizations are deployed. We now profile CF385: complete physical DE evaluation 984 s, boundary precision attempts 80->160->320 digits; first two fail TaylorArithmeticPrecisionInsufficient. Ordinary finite-integral transport converges on quadrature 16/24, one/two panels and 50/70 digits. Thus boundary continuation precision is suspicious.

Please critically review a targeted idea, independent of any process: preserve native complex-ball midpoint/radius data across Taylor steps instead of round-tripping through Wolfram arbitrary-precision numbers. Current implementation:
1. Native FLINT step returns real/imag midpoint mantissa*2^exponent and radius mantissa*2^exponent for each coefficient.
2. WL converts each real ball: accuracy=Floor[-Log10(radius)]-2; SetAccuracy[midpoint,Min[accuracy,workingDigits-Log10(abs(midpoint))]]. Complex result = re + I im.
3. Next step serializes Re[value] and Im[value] via Rationalize[component,0] plus a radius rounded UP to 2^Ceiling[-Accuracy[component]*log2(10)].
This introduces at least ~2 decimal digits of artificial radius inflation per step, beyond genuine arithmetic/conditioning, and can force restarts. Idea: carry the original exact native ball tokens to the next native step; still compute WL values for tail/roundoff diagnostics and final output, but do not feed that padded conversion back. Never drop real radius, never replace by a midpoint-only value. Input point/seed uncertainties remain included. Existing two independent matching-point continuations and AMFlow comparison stay intact.

Questions: Is this reasoning valid? Any mathematical/protocol correctness traps (complex component uncertainties, changing precision, rejected steps, contour points, input/output endpoints)? Is a general per-step raw-ball protocol a sensible bounded change, versus changing step fraction or wholesale persistent native transport? The current native recurrence separately propagates arithmetic balls but uses last-eight-order tail estimates (not a rigorous truncation enclosure); report continues saying non-rigorous, with matching-point checks. We must not accidentally claim full rigorous bounds. No need web searches. I will test preservation and failure diagnostics then complete hard-family comparisons.


## Pro response

Yes. Your reasoning is valid, and preserving native balls is the right targeted change before altering the step fraction or introducing persistent native transport. It removes avoidable uncertainty growth without reducing the accuracy goal. The remaining qualification is causal: CF385’s precision escalation is consistent with this mechanism, but the first rejection must show whether the inflated solution balls—not some independently evaluated DE coefficient or denominator—triggered the failure.

1. The artificial inflation can be substantially larger than 100×

Consider one nonzero real-component radius r. Ignoring the working-precision cap and subsequent complex-number operations, your conversion assigns

A=⌊−log
10
	​

r⌋−2,

and reconstructs an input radius

R=2
⌈−Alog
2
	​

10⌉
.

Writing −log
10
	​

r=k+f, with 0≤f<1, gives

r
10
−A
	​

=10
2+f
,10
−A
≤R<210
−A
.

Thus, when the Wolfram conversion retains the assigned accuracy, the radius formula alone gives

100≤
r
R
	​

<2000.
	​


For an entirely dyadic example,

r=2
−300
⟹A=88,R=2
−292
,

so an unchanged value returns with 256 times the native radius. An active working-precision cap can enlarge it further.

This is not merely a two-digit output safety margin: it becomes a repeated input uncertainty. On an identity transport, repeated conversions alone can consume roughly two or more decimal digits per handoff. Actual transport can damp or amplify that uncertainty, so the loss is not necessarily linear in the number of steps.

Also handle zero native radius separately. A diagnostic conversion to a finite-accuracy Wolfram number must not turn an exactly represented native component into an uncertain input merely because the display representation has finite accuracy.

2. The principal invariant: raw balls must represent the actual next-step input

The import/export contract should be

Import(Export(B))⊇B.

With unchanged exact native representations, equality should normally be achievable. Where importing involves rounding, outward containment is sufficient.

But that contract alone is not enough: the ball being preserved must belong to the state that the next step actually consumes.

Taylor coefficients versus endpoint values

This is the most important implementation check.

Suppose native output consists of coefficient balls C
k
	​

, while Wolfram computes the endpoint state

Y
next
	​

=
k=0
∑
N
	​

C
k
	​

h
k
.

Then the next input must contain balls for that polynomial evaluation, including the uncertainty in h. You cannot attach the original coefficient tokens to a Wolfram-computed endpoint midpoint and treat them as its uncertainty.

A small native endpoint-evaluation operation, using the same ball arithmetic, is sufficient where needed. That remains a bounded change; it does not require a persistent transport engine.

The same condition applies to any intervening basis transformation, normalization, Laurent-coefficient convolution, asymptotic prefactor, or linear combination. Either the transformation produces updated balls, or the old tokens cease to be a valid representation of the transformed state.

Deliberately added uncertainty must survive

Separate the automatic SetAccuracy padding from uncertainty intentionally introduced elsewhere.

If the Wolfram layer currently adds a seed-error allowance, matching/extrapolation error estimate, or Taylor-tail allowance before producing the next input, bypassing the Wolfram number must not bypass that addition. Carry it explicitly, retaining its existing status as rigorous or heuristic.

If tail estimates have always been diagnostic-only, keep that behavior. The raw-ball change need not introduce a new error model—but it must not silently remove an existing one.

3. Complex components and precision changes
Preserve the rectangular complex enclosure

Keep

ℜy∈[m
R
	​

−r
R
	​

,m
R
	​

+r
R
	​

],ℑy∈[m
I
	​

−r
I
	​

,m
I
	​

+r
I
	​

]

as separate components throughout the handoff.

In particular, m
I
	​

=0 with r
I
	​

>0 is not an exactly real value. A tiny imaginary midpoint must not disappear from the propagated representation merely because the diagnostic Wolfram complex number suppresses it.

For a scalar complex-error diagnostic, a conservative radius around m
R
	​

+im
I
	​

 is

ρ=
r
R
2
	​

+r
I
2
	​

	​

,

or the simpler upper bound r
R
	​

+r
I
	​

. Using max(r
R
	​

,r
I
	​

) alone would not bound the Euclidean displacement. There is no need to convert to such a scalar radius for propagation; preserving the original component enclosures is preferable.

Importing at a different precision must preserve containment

If the imported midpoint changes from m to m
′
, the new radius must satisfy

r
′
≥r+∣m
′
−m∣.

Do not round the midpoint to the new arithmetic precision and simply retain the old radius. Radius conversion itself must also round outward.

Increasing working precision does not justify shrinking an inherited radius. It can reduce additional rounding error, but it cannot recover uncertainty already present in the input state. When inherited uncertainty is already too large, recovery requires recomputation from an earlier sufficiently accurate state or seed.

Keep these quantities distinct:

the requested arithmetic precision for the native operation;

the uncertainty encoded in its input balls;

the precision of the Wolfram diagnostic representation.

In particular, do not infer the first from Precision[diagnosticValue].

Keep token handling exact

Mantissas and exponents must reach the importer as exact integers or exact integer strings, never through a machine-number parser. Preserve signs, zero components, and nonnegative radii. Invalid or nonfinite tokens should produce an explicit failure, not a midpoint-only fallback.

You do not need a broad new serialization framework. An explicit raw-ball payload alongside the existing diagnostic values is enough.

4. Accepted steps, rejected steps, and contour coordinates

Treat the accepted state as one unit: endpoint, ordered coefficient vector, and its raw balls.

A rejected trial must not replace any of those. A retry with a different step length, order, or precision starts from the last accepted state, not from the rejected endpoint. This matters especially when mutable Wolfram symbols currently hold “the latest native result.”

Likewise, the next Taylor expansion must use the same endpoint representation at which the previous endpoint state was evaluated. Do not evaluate the state using one rounded contour point and then recenter it at a separately reconstructed point without accounting for the difference.

For prescribed rational or otherwise exact contour coordinates, retaining the exact definition is preferable. For uncertain coordinates, preserve their uncertainty and include it in the step displacement and coefficient evaluation. A precision increase must not silently turn an uncertain input point into an exact one.

The raw-ball handoff does not change the continuation path, branch choices, endpoint prescriptions, or matching-point identity. Keep both matching-point continuations’ state separate. In particular, a smaller reconstructed radius is not permission to bypass a genuine zero-containing denominator enclosure or alter a contour vertex.

5. Use native radii for arithmetic diagnostics

There is one related change worth making immediately:

TaylorArithmeticPrecisionInsufficient should inspect the native uncertainty, not uncertainty inferred from the padded Wolfram preview.

Otherwise, you can eliminate feedback inflation but still reject a step because its diagnostic representation deliberately understates its accuracy.

Read the component radii directly, or derive a conservative scalar error measure from them using your existing absolute/relative acceptance rule. Near zero, an absolute criterion is necessary; relative precision alone is not meaningful.

Wolfram values can remain useful for tail estimates and other diagnostics, provided their evaluation precision is sufficient. However, their precision metadata should not serve as the authoritative storage of the native enclosure.

For CF385, distinguish these failure sources in the first rejection record:

Failing quantity	Relevance of raw-state preservation
Propagated solution or Laurent-coefficient ball	Directly addresses repeated input-radius inflation.
DE coefficient or denominator depending only on the center and parameters	Helps only if those inputs also suffered the round-trip; preserving the solution vector alone may have no effect.
Endpoint polynomial evaluation	Requires raw-ball endpoint evaluation, not just coefficient preservation.
Tail estimate or matching discrepancy	Not resolved merely by reducing arithmetic radii.

That is enough discrimination; no expensive symbolic analysis is needed.

6. Keep the non-rigorous status explicit

Your existing qualification remains necessary.

Assuming correctly enclosing native operations, the arithmetic balls track input uncertainty and rounding through the finite recurrence and polynomial evaluation. Without an enclosed Taylor remainder, they do not establish an enclosure of the exact continued DE solution.

In particular,

small arithmetic radius

⇒small total continuation error.

The last-eight-order tail estimate remains heuristic. The two matching-point continuations and independent AMFlow comparisons remain validation checks, not proofs of enclosure.

Also, once one accepted step omits a truncation remainder from its propagated ball, the next step’s arithmetic enclosure cannot be described as containing all uncertainty of the exact solution. Smaller, better-preserved arithmetic radii make this distinction more visible; they do not create it.

A suitable interpretation remains: native arithmetic enclosures, heuristic truncation assessment, and independent numerical cross-checks—not rigorous end-to-end bounds.

7. A proportionate test sequence

First, test the handoff without transport. Export/import repeatedly and verify exact equality of the represented balls, or outward containment where rounding is intentional. Include nonzero midpoint with zero radius, zero midpoint with nonzero radius, very unequal real/imaginary scales, and a precision decrease followed by an increase. The final increase must not erase uncertainty introduced by the decrease. Compare represented enclosures, not necessarily token bytes.

Second, rerun the CF385 boundary at 80 digits with a narrow trace. For the first problematic component, record the native exported radius, the radius the legacy conversion would reconstruct, the actual raw-import radius, the accepted step count, and the precise rejection operand. Compute the legacy radius for diagnostics only; it need not drive a second full continuation. This directly tests whether the apparent precision requirement was accumulated bookkeeping inflation.

Third, compare the complete result. Retain the existing matching-point tests, compare against the retained higher-precision boundary result, and run all requested physical coefficients through the unchanged AMFlow comparison. Endpoint arithmetic-radius improvements alone are not the acceptance criterion.

Approve the raw-ball protocol first. Changing the step fraction now would mix two effects: genuine continuation behavior and the number of artificial reinflations. Remove the latter, then evaluate whether any remaining precision escalation comes from conditioning, truncation, or a specific coefficient evaluation. Persistent native transport is unnecessary for establishing—and obtaining—the benefit of this fix.