# Taylor-step prediction

## Question

Raw-ball implementation now passes analytic logarithm/dilogarithm/Jordan-chain tests and 80 exact complex-ball identity handoffs (no radius inflation); lower precision retains original enclosures. Native endpoint polynomial evaluation produces the passed raw tokens, not unevaluated Taylor coefficients. Accepted-state tokens and center are unchanged on rejected trials; precision retries restart from original boundary data. Full CF385 comparison still running, but first matching-point continuation now succeeds at 80 digits: 91.8 s, Frobenius initialization7.75s, Taylor continuation84.0s. Previously complete evaluation984s and 80/160 failures before320. Request accuracy18+boundaryguards, no tolerance/order changes.

Next measured waste: first CF385 continuation has59 accepted steps and58 rejected trials. At every new step, current controller forgets the successful step fraction and again tries maximum1/4 of nearest-pole distance; almost every such trial fails last-eight-order-tail criterion and then half-step succeeds.

I will keep the completed raw-only comparison as an isolated timing baseline before changing step selection. Proposed general controller: retain an effective radius fraction <= configured maximum1/4; halve it whenever a trial is rejected. After acceptance, estimate next fraction from observed tail ratio: factor=clip((1e-5/ratio)^(1/(TaylorOrder-7)),1/2,5/4), cap by configured maximum. For exactly zero estimated tail, grow by5/4. The acceptance test remains ratio<1e-3 plus same arithmetic check; the entire quadratic contour arc/chord remains in the nearest-pole disk because effective fraction never exceeds configured maximum<=1/3. A rejected trial never changes accepted state. This is only a cost predictor; every actual trial is checked.

Please review this bounded controller and suggest simpler/sounder alternatives. This is not a claim of a rigorous truncation bound; tail test and separate matching-point comparisons remain as before. We want proportionate checking, avoiding repeated trials known likely to fail. Currentstep formula du=min(1-u,2*fraction*dist/(abs(z')+sqrt(abs(z')^2+4*abs(target*deform)*fraction*dist))).


## Pro response

Yes—the controller is sound as a cost predictor, with every trial still subject to the unchanged acceptance checks. Retaining the successful fraction directly addresses the measured waste. I would add no immediate growth after a rejected trial, and keep arithmetic-precision failures separate from tail-driven step reduction.

The proposed contour bound is also correct under the stated quadratic parametrization.

1. The step formula bounds the entire quadratic segment

Write

d=dist(z(u),nearest pole),a=∣z
′
(u)∣,b=∣targetdeform∣,f=effective fraction.

For the quadratic contour,

z(u+s)−z(u)=z
′
(u)s+cs
2
,∣c∣=b.

Therefore, for 0≤s≤h,

∣z(u+s)−z(u)∣≤as+bs
2
≤ah+bh
2
.

Your proposed unconstrained step,

h
∗
	​

=
a+
a
2
+4bfd
	​

2fd
	​

,

satisfies

ah
∗
	​

+bh
∗
2
	​

=fd.

Clipping to h=min(1−u,h
∗
	​

) can only decrease that bound. Hence

0≤s≤h
sup
	​

∣z(u+s)−z(u)∣≤fd.
	​


The chord also lies in this disk, by convexity. Thus retaining f≤f
max
	​

≤1/3 preserves the stated geometric margin.

This requires using the current accepted center’s pole distance and derivative each time. Retaining f must not mean retaining the previous absolute step or distance. Handle the degenerate a=b=0 case explicitly, and retain a zero-progress/nonfinite-step failure rather than allowing repeated ineffective halvings.

This geometric statement does not certify the omitted Taylor remainder.

2. Your predictor is reasonable, but its safety margin is smaller than it looks

When “Taylor order N” means the highest retained power, the last eight terms start at degree N−7. Consequently,

p=N−7

is a reasonable leading-power model for the tail’s dependence on step size. Check that the implementation’s order convention really means highest degree rather than number of coefficients.

The model remains approximate: the tail can cancel, its normalization can vary, and changing the center changes the coefficients. Also, the effective radius fraction is a proxy for the actual displacement in the Taylor variable. These are reasons to retain trial checks, not reasons to reject the predictor.

One important quantitative point: targeting 10
−5
 against an acceptance threshold of 10
−3
 does not provide a large step-size margin at high order. Under ρ∝f
p
,

f
acceptance boundary
	​

f
target
	​

	​

=(
10
−3
10
−5
	​

)
1/p
.

For N=64, this is approximately 0.922; for N=128, approximately 0.963. Thus two decades of tail margin correspond to only about 8% or 4% of fraction margin, respectively.

That is adequate for a predictor, but changes between neighboring centers can still cause occasional rejections.

Minimal adjustment: suppress growth immediately after rejection

Use the fraction that actually succeeded, after any halvings, as the predictor’s base:

g
0
	​

=
⎩
⎨
⎧
	​

5/4,
clip[exp(
p
log(10
−5
)−logρ
	​

),1/2,5/4],
	​

ρ=0,
ρ>0.
	​


Then apply

g={
min(g
0
	​

,1),
g
0
	​

,
	​

the accepted step required a rejected trial,
otherwise,
	​

f
next
	​

=min(f
max
	​

,f
accepted
	​

g).

This allows a further predicted reduction but prevents an immediately recovered step from immediately growing again. It adds only one Boolean state and directly counters rejection cycles.

Do not combine this with additional safety constants initially. Your existing target, growth cap, and this one hysteresis rule are enough for the first measurement.

Two small details:

Endpoint clipping: do not use an artificially short final step to infer a favorable fraction for another segment or continuation. Within the completed arc there is no next step anyway.

Zero/nonfinite tail: modest growth for an exactly zero estimate is acceptable after the arithmetic check passes. A negative, nonfinite, or failed estimate must not enter that branch. Computing the positive-ratio update in logarithms avoids unnecessary extreme intermediate values.

3. Keep arithmetic rejection separate

The part I would qualify is “halve whenever a trial is rejected.”

A tail rejection supplies evidence that the trial displacement is too large for the retained expansion. Halving the fraction is appropriate.

An arithmetic rejection may instead come from inherited seed uncertainty, a coefficient evaluation, or another precision floor. Repeatedly shrinking the geometric step need not fix those, and can turn a precision problem into excessive steps or zero progress.

Keep the existing arithmetic retry/escalation policy. A smaller trial may remain appropriate for an identified step-dependent arithmetic failure, but do not replace precision recovery with unconditional geometric halving. In particular, do not repeatedly reduce the remembered fraction merely because the same precision-insufficient input is retried.

Your existing separation of accepted state from rejected trial state, and precision restarts from original boundary data, is the correct foundation.

4. An even simpler alternative fits the observed profile

For CF385, persistence alone may deliver nearly all the benefit.

If the accepted fractions are indeed 1/8 throughout, apart from endpoint clipping, retaining 1/8 reproduces essentially the existing accepted mesh while eliminating the repeated 1/4 attempts. It does not need a power-law estimate to discover what the trace already established.

A simple general controller with recovery in easier regions is:

Halve on a tail rejection and retain the successful fraction.

Hold that fraction normally.

Grow by at most 5/4 only after two consecutive first-attempt acceptances with ρ≤10
−5
; reset the growth counter after growth or rejection.

Use this instead of, not in addition to, the continuous predictor. It is less responsive but avoids depending on an effective tail exponent. Holding forever without any growth mechanism is less suitable generally: one locally difficult region could otherwise impose unnecessarily small steps on the rest of the path.

Either version is defensible. For the smallest production patch, I favor persistence plus this short success streak. Your power-law predictor with no-growth-after-rejection is appropriate when reducing the accepted-step count as well as the rejection count matters.

5. Expected benefit and proportionate validation

The current continuation performed

59+58=117

trials. If persistence retains the same accepted steps and only the first rejection remains, that becomes

59+1=60.

With comparable trial costs, the measured 84 seconds of Taylor continuation would scale approximately to

84
117
60
	​

≃43 s.

Adding the 7.75-second initialization gives roughly 51 seconds for this first matching-point continuation. This is only an illustrative estimate: it is not a prediction for complete CF385 evaluation, and rejected-trial timing will determine the actual saving.

After the raw-only baseline completes, one controlled CF385 run should record accepted steps, rejected trials, time spent on each, precision attempts, and the existing final comparison results. An increase in accepted steps is not automatically a regression; total continuation time at unchanged validation quality is the relevant metric.

One secondary opportunity is worth checking only if rejection cost remains significant: at a fixed accepted center, input state, precision, and Taylor order, the Taylor coefficients do not depend on the trial endpoint. Halving can reuse those coefficients and redo only endpoint evaluation and the tail test. This is a local per-step reuse opportunity, not a requirement for persistent native transport.

Proceed with fraction persistence and one hysteresis rule. Keep the raw-only baseline isolated, preserve the separate arithmetic failure policy, and retain the existing non-rigorous truncation qualification and full matching-point/AMFlow checks.

## Implementation

Accepted native states remain separate from trial states. Arithmetic failures retain precision escalation; only tail failures halve the step. The continuous predictor is retained and immediate growth after a rejected trial is suppressed. Degree means highest retained power, so the first of the last eight terms has degree N-7. All trial acceptance checks and both matching-point calculations remain.
