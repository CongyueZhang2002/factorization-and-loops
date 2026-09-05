# Private Hardening Review Algorithm Followup

## Question

Please add a second, independent review focused ONLY on the actual mathematics, algorithms, and performance architecture of the code already attached in this same conversation. The previous answer spent too much attention on hashes, seals, deadlines, and provenance. Do not repeat those topics unless they expose a mathematical false positive. Do not give another release-hardening checklist.

Please inspect and cite the actual implementation, especially `MultiquadraticStripSolve.wl`, `MultiquadraticAlgebra.wl`, `BlockEquationDeferred.wl`, `FiniteFieldStripSolve.wl`, `FamilyRowGauge.wl`, `FamilyRowGaugeResume.wl`, and `TransportCharts.wl`, and answer these questions:

1. Does the multiquadratic route actually solve one epsilon-form problem, or only unrelated finite-field fibers at sampled epsilon values? In particular, distinguish epsilon-dependent gauge coefficients from epsilon-independent constant residue matrices. Does the code enforce one common residue solution across epsilon images, reconstruct a rational gauge in epsilon, and certify/integrate the returned one-forms into actual dlog potentials? Identify the exact missing algorithm, if any.

2. Is global characteristic-zero decomposition of every large forcing entry mathematically necessary before the finite-field solve? Compare three routes: (a) current global channel decomposition, (b) direct evaluation of the original deferred expression on all Galois sign branches at split finite-field points followed by Walsh/Hadamard channel recovery, and (c) direct evaluation in the quotient/grade algebra F_p[r_i]/(r_i^2-Delta_i), including nonsplit points. We measured on the real frozen CF300 (12,9) record at p=10007, point {2,8}, eps=5: exact decomposition of the smallest 72,021-leaf entry about 2.75 s; all four branch values for it about 0.072 s; all 8 forcing entries over all 4 branches about 1.165 s; all 32 values agreed with the frozen exact channels. Fable measured 1400.5 s for the global decomposition stage. Explain which evaluator should be primary and how to compile/reuse the deferred DAG.

3. Assess the mathematical completeness of the automatic alphabet and gauge ansatz: A +/- sqrt(Delta_i) letters, limited norm products, mixed-grade letters, denominator valuations, support rectangles/ladders, and the meaning of a modular obstruction. Propose a general divisor/S-unit or quotient-ring method that covers rank 0 through rank 3 without family-specific assumptions.

4. Identify the largest remaining asymptotic improvements after removing global decomposition: support learning/Newton polytopes, incremental sparse modular elimination, pivot-plan reuse, FLINT, vectorization over Galois branches/epsilon images, dynamic point scheduling, local active-root reduction, and per-entry fallback. Rank these by expected impact.

5. Review mathematical generality and conciseness. Which parallel implementations are genuinely redundant (old/new alphabet builders, three row assemblers, inverse implementations, rational versus multiquadratic affine solvers), and what minimal coefficient-provider architecture would unify them without losing independent mathematical oracles?

Please validate or refute the hypotheses with exact code locations and concrete equations/counterexamples where possible. The deliverable should be concise and method-first: correctness of the epsilon-form mathematics, the fastest sound algorithm, completeness limits, and a prioritized redesign. No hashes/checks discussion.

## Pro response

_No Pro response was recorded._
