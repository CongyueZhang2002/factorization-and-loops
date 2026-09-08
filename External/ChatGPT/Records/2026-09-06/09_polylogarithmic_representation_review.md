# Polylogarithmic representation review

## Question

Please challenge a proposed polylogarithm conversion layer for our general NNLO framework. Keep the response focused (roughly 700 words); no implementation is requested.

Current state: 91 raw closed master DEs and explicit finite epsilon solutions up to initial constants have been stored. Each coefficient uses a finite acyclic list of scalar integral definitions F_i(s)=integral_0^s g_i(t) dt, with explicit kernels and earlier F_j; repeated expressions are shared. The general solver removes homogeneous blocks and epsilon poles until B(eps) has nonnegative epsilon powers and strictly lower triangular B0. Full strict epsilon form is optional. Arbitrary-precision Wolfram and compiled FLINT evaluation and local Taylor/DE evaluation exist. Physical constants/global continuation unfinished.

User asks whether to expand into GPL and other polylogarithms, recalls all our two-root families are GPL, and asks whether community packages will evaluate faster.
We have explicit verified forward rationalizing parametrizations for Kallen12, Kallen13, Kallen23 and other pairs in TransportCharts.wl; these verify forward root identities and nonzero Jacobian, not inverse branches or a family-wide GPL theorem. Raw DE coefficients being rational is not sufficient by itself (period modules). Current generic solutions use a straight path in original variables; a straight path can generate unnecessarily complicated algebraic curves even if the full kinematic surface admits a rational parametrization.

Proposed reasoning:
- A rationalizing chart plus rational finite recursive kernels/elementary algebraic prefactors, with higher poles reduced by integration by parts, gives finite GPL expressions over algebraic endpoint-dependent letters. Strict epsilon form not required once the finite triangular recursion exists. A GPL's letters must be constant with respect to its own integration variable; nested inner arguments depending on outer variables need actual reduction rather than a renamed head.
- Prefer choosing a path in rationalized coordinates and fixing constants at the same physical ordinary point, with correct lift/branch; coordinatewise paths can reduce alphabet size, but changing paths requires flatness and homotopy in a nonsingular domain.
- Convert at block/coefficient order granularity and preserve mixed GPL/elliptic/unconverted expressions; root count alone is no function-class classifier, and non-simultaneous rationalizability is not proof of non-GPL.
- Store explicit finite GPL coefficient tables with shared functions/subexpressions and branch/basepoint metadata, not a generator. Do not expand shuffle products indiscriminately or require reduction to classical Li_n.
- Benchmark total time and file size versus current compiled evaluator/Taylor route at matched achieved accuracy including cancellations. GiNaC arbitrary precision; handyG fixed double/quad precision; GiNaC 1.8.10 released Feb 11 2026 now includes Gt arbitrary-argument elliptic MPLs (https://www.ginac.de/News.html and arXiv:2602.09956). Conversion to eMPLs needs the actual elliptic curve, kernels, periods and marked points; multiple/higher-genus structures are not automatically eMPLs.
- Useful paper: Papathanasiou et al. arXiv:2501.07490 permits different rationalizations of the SAME integration path and demonstrates MPL expressions for seven roots.

What is mathematically missing/incorrect in this proposed criterion or path change? In particular, distinguish a finite rational recursive integrand class that closes under GPL integration from merely a rational connection or individually rationalizable kernels. Is GPL conversion a good next optimization priority versus more numerical continuation? Recommend a minimal general proof-of-concept and honest expectations on speed. Please do not infer that all two-root families or all 91 have already passed the criterion.

## Pro response

The proposal is sound as an optional representation layer, but the GPL criterion needs a stronger closure condition. Neither the two-root labels nor the 91 completed finite solutions establish that condition.

1. The sufficient criterion concerns the whole recursive integrand

For fixed endpoint parameters X, a sufficient class is

g
i
	​

(t;X)=
α
∑
	​

R
iα
	​

(t;X)
j<i
∏
	​

F
j
	​

(t;X)
n
αj
	​

,n
αj
	​

≥0,

where the R
iα
	​

 are rational in one common integration parameter, over an algebraic extension of the endpoint-parameter field, and earlier F
j
	​

 are already GPLs in that parameter. Rational-function partial fractions, shuffle identities, and integration by parts then close the finite recursion in rational functions times GPLs. Higher poles are not an obstruction. This is the integration class treated by Panzer’s HyperInt algorithms. 
arXiv

Polynomial dependence on earlier GPLs is important. Arbitrary rational dependence is insufficient. For example,

F
1
	​

(t)=log(1+t),F
2
′
	​

(t)=
1+F
1
	​

(t)
1
	​


is finite and acyclic, but its primitive involves

e
−1
Ei(1+log(1+t)),

rather than following the GPL closure rule.

Likewise, algebraic prefactors outside the integrals are acceptable, but any prefactor subsequently entering another integral must pass the integrand criterion. Rationalizing the original roots does not automatically rationalize homogeneous-preparation factors or remove period dependence.

Your nonnegative-epsilon, triangular-zero-order construction supplies finiteness, not this additional function-class property. Once both hold, strict epsilon form is unnecessary.

Endpoint-dependent letters are legitimate when constant with respect to their own GPL variable. If such an endpoint becomes a later integration variable, the resulting GPL must be reduced into the later variable’s hyperlogarithm algebra. Merely nesting GPL heads does not establish closure. 
arXiv

2. Path changes require more than a rationalizing substitution

The forward identities establish a candidate parametrization. For use at a physical point, additionally identify the base-point and endpoint lifts, ensure regularity there, and maintain the chosen sheet along the path. A globally rational inverse is unnecessary; a correctly selected local inverse/lift suffices.

Change the path of the complete transport solution, not individual stored auxiliary integrals. Those F
i
	​

, or individual iterated words, need not be homotopy-invariant separately. Reconstruct the finite recursion on the new path with the same boundary vector and appropriate basis normalization. Flatness permits comparison along homotopic nonsingular paths; it does not erase monodromy or allow independent path choices for arbitrary summands. Papathanasiou et al. explicitly distinguish path-independent combinations from individual path-dependent words. 
arXiv

Their seven-root example supports your proposed alternative: different rationalizations can reparametrize the same path. That does not license separately rationalizing successive kernels while ignoring their shared nested integration variables. For convergent ordinary-point integrals, endpoint-preserving reparametrization suffices; if singular-basepoint regularization is introduced, its tangential normalization must also be preserved. The paper explicitly imposes an additional condition for trailing-zero regularization. 
arXiv
+1

Coordinatewise paths are therefore useful candidates, not automatic improvements or family-wide GPL certificates.

3. Priority, package expectations, and a minimal experiment

Do not make wholesale GPL conversion the next production requirement. Keep it optional and preserve mixed expressions. Ordinary-domain numerical transport/reuse serves more of the current solution inventory; conversion should earn priority through measured performance.

The package claims check out: GiNaC supports arbitrary-precision MPL evaluation; handyG supplies double/quadruple-precision configurations, not the 80–100 working digits sometimes needed in your cancellation-sensitive evaluations. 
arXiv
+1
 GiNaC 1.8.10, released February 11, 2026, adds Gt for arbitrary-argument eMPL evaluation. That is an evaluator for a defined elliptic function class—not automatic recognition or conversion of arbitrary algebraic integrals. The actual curve, period normalization, marked points, kernels, and continuation prescription still have to match its supported representation. 
GiNaC
+1

For a minimal proof-of-concept, select one rational control and one already rationalized two-root block, including their dependency closure, at one nontrivial requested order. Establish recursive closure, retain base-point terms, and verify primitive derivative identities plus numerical agreement on a fixed branch. Store explicit shared GPL expressions without indiscriminate shuffle expansion or classical-Li
n
	​

 reduction.

Benchmark conversion cost, unique GPL calls, file size, cold/warm evaluation, and achieved accuracy after boundary substitution against FLINT and Taylor reuse. Compact GPL expressions may win; expanded high-weight expressions may lose badly. The seven-root paper itself warns that sufficiently large MPL expressions can favor numerical integral or DE representations instead. A named special-function representation is an interoperability benefit, not a speed certificate. 
arXiv
