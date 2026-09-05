# Exact Pfaffian Route

## Question

Continue our existing FACET master-integral discussion. I attached the exact
CF231 density, Cayley configuration, measured package results, and candidate
reusable stages in ExactPfaffianRouteAssessment_20260815.md. Please review that
file directly rather than relying on this prompt as a substitute.

The new decisive measurement is that Macaulay2 constructs the generic GKZ
ideal essentially instantly but finds generic holonomic rank 6, whereas a
direct exact Singular likelihood quotient for the physical density has rank 5.
The physical coefficients satisfy the algebraic relation displayed in the
attachment. A naive chain-rule substitution of generic 6x6 connection matrices
therefore is not justified.

Please give a concrete physicist-level recommendation for the next exact
calculation, with enough detail that I can test it immediately:

1. Check the Cayley matrix, beta vector, and the interpretation of b^epsilon.
2. Decide whether the right exact object is a D-module restriction of the GKZ
   system to the physical coefficient locus, or direct creative telescoping in
   (s,sx,sy). Explain why the measured rank changes from 6 to 5.
3. Name the strongest existing implementations for this exact rank-five case,
   including tools beyond our current Mathematica stack. Compare, in particular,
   Macaulay2 ConnectionMatrices/Drestriction, Singular
   annihilatorMultiFs+integralIdeal, Risa/Asir mt_mm and its Oaku/Heaviside
   routines, HolonomicFunctions, and any better package I missed.
4. State whether each candidate returns an exact analytic differential system,
   a telescoping certificate, relative-boundary source terms, or only numerical
   data. Our required output is analytic; AMFlow remains verification only.
5. Give an explicit staged algorithm for the physical open cut domain. Separate
   the homogeneous bulk connection, boundary-source periods, real chamber,
   oriented cycle, and branch choices.
6. Identify which stages can be deterministic reusable functions, their input
   and exact acceptance criterion, and which stage still requires a genuinely
   new boundary calculation.
7. If direct creative telescoping is your recommendation, sketch the concrete
   Singular or Risa/Asir commands for this density and point out where the
   physical endpoint faces enter. If a restriction is better, give the graph
   embedding/restriction construction explicitly.

Please challenge the proposed route if another community method is more direct.
Do not recommend a purely numerical evaluator as the main calculation.

## Pro response

_No Pro response was recorded._

## Sources sent to Pro

- Original source reference: `../../MasterEvaluationWorkflow/PackageEvaluation/ExactPfaffianRouteAssessment_20260815.md` (not archived with this exchange)
