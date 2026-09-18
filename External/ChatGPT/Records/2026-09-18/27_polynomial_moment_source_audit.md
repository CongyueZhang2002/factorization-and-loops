# Polynomial measurement moment source audit

Actual ChatGPT6 Pro,7m38s, inspected pushed
d993fb5522f995e896de2f152232e5fba0e5788f in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
It read MeasurementMoments.wl, its regression, Prescriptions.wl,
Convergence.wl, MeasurementPushforward.wl, InvariantPhaseSpace.wl,
CutFamilies.wl and EndpointRegularity.wl. Static source/mathematical review;
it did not execute tests or inspect the running native job or saved records.

The existing parent certificate is sufficient and stronger than the moment
identity needs. At unit cuts it includes one inverse measurement-slope
majorant in addition to the actual ordinary product. Polynomial F^(N+1)
insertions are bounded on the compact parent domain. The wrapper pairs the
measurement variable with test functions before taking the causal limit;
its generic-kinematic status does not mean only pointwise interior equality.
Pair the polynomial weight with a smooth compactly supported extension
agreeing with it near[0,1], rather than a discontinuous interval indicator.
The dominated initial cut limit fixes the F=0 boundary; subsequent unique
continuation still does not prove ordinary-delta-only Laurent coefficients.

Pro found no missing Jacobian,2Pi, phase-space normalization, state factor or
changed prescription in the generated GLI combinations. Both sides correctly
retain MeasurePrefactor and labeled particles; the compiled observable's own
MeasurementNumerator must not be multiplied in again for a scalar master.
The explicit exponent-one Gram witness from review26 is optional here.

Three repairs requested and implemented afterward:

1. The inherited geometric certificate omits the external measure factor.
   Independently check finite external coefficients and meromorphic regulator
   dependence. A measure divided by(alpha-beta) under alpha==beta, or multiplied
   by Exp[1/epsilon], must fail. The shared logic was extracted from endpoint
   regularity into Normalization/AnalyticFactors.wl; no endpoint certificate
   is fabricated for a normalization check.
2. Require the requested regulator to equal the chart regulator and the family
   dimension, after D->4-2epsilon, to agree. Do not silently label a chart in
   one regulator with a certificate in another.
3. Preserve the full source family identity, including its context, when
   naming the unmeasured family. Retain the slot map. Rename the moment record's
   G field to ObservableNumerator so MeasurementNumerator keeps its existing
   compiled-Jacobian meaning elsewhere.

The updated moment test has11 passing assertions,6.269s including startup.
The18 endpoint-regularity assertions pass with the extracted shared logic,
2.966s. These tests were run locally after Pro's review, not by Pro.

Conservative limits: deleting the measurement slot can require explicit affine
basis completion; current code correctly refuses incomplete families. Requiring
a root-solving pushforward is stronger than the moment theorem needs and can
reject valid alternative charts. Separating physical-chart compatibility from
measurement-root construction is a future general improvement. Neither issue
justifies relaxing support or dimensional checks.
