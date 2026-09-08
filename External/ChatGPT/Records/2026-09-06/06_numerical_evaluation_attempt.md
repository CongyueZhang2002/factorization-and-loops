# Numerical evaluation review attempt

## Question

We completed the 91-family finite epsilon solutions as previously reviewed. User now explicitly wants dependable numerical evaluation and AMFlow comparisons, and correctly questions whether quadrature can match AMFlow's local-series DE accuracy. Please challenge the following numerical implementation plan. Current GitHub https://github.com/CongyueZhang2002/factorization-and-loops ; current edits remain local.

The exact artifact is a finite acyclic set F_i(s)=integral_0^s g_i(t, earlier F_j(t)) dt, each g_i explicitly stored (the DE solution has already been constructed). Scalar kernels K_i(t) are explicit arithmetic in earlier K. All coefficients and original-basis/C convolutions are explicit. Existing standalone evaluator samples all K and F on n Gauss-Legendre nodes; interpolatory indefinite integration matrix provides values of earlier F at all nodes. Only one fixed n, no convergence control, ordinary straight paths; C stays symbolic.

Proposed improvements: keep exact artifact; evaluate by piecewise high-order Gauss-Legendre integration carrying every F_i's endpoint value between panels. Compare order n and a distinctly higher n plus a subdivided mesh at elevated working precision, componentwise absolute+relative tolerance after C substitution (also coefficientwise without C); insufficient input precision and missing boundary orders must fail. Track convergence as an empirical estimate, never a rigorous error bound, and detect invalid singular/branch-crossing paths rather than silent crossing. For independently known regular kernels, a local power-series evaluator of the same fixed definitions is an alternative; differentiating F_i'=g_i does not replace the stored solution with a lazy DE generator. Benchmark direct quadrature on nontrivial stored hard families against an independent original-DE computation, matched target digits. If needed prefer local power-series evaluation for high precision. AMFlow at X0 supplies required boundary Laurent coefficients; evaluate stored U*C at X1 and compare direct AMFlow X1, explicitly only a test of transport when both use AMFlow boundaries.

Please recommend a concrete practical algorithm to implement now, especially (1) stable/efficient high-order evaluation of this finite dependency graph, (2) honest yet inexpensive convergence/roundoff/cancellation checks, (3) path/singularity requirements for the current ordinary-point domain, (4) whether a segmented Taylor implementation or using existing DiffExp adds decisive benefit over spectral integration. Is comparing quadrature resolution + mesh + precision sufficient as an operational accuracy criterion? Avoid proposing full generic symbolic re-verification.


## Delivery result

The desktop bridge returned HTTP 403 while waiting for the ChatGPT sentinel and subsequently failed with "composer missing". The prompt was not delivered and no Pro response was obtained. Local implementation proceeded with explicit analytic controls, independent AMFlow series comparisons, and a physical two-point auxiliary-mass-flow comparison.
