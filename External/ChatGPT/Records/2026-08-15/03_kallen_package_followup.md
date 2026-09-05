# Kallen Package Followup

## Question

The attached KallenConnectionsForOre.json contains the exact 4 by 4 two-variable differential connections for FACET's four remaining Kallen blocks: CF258_B9, CF300_B10, CF230_B1, and CF231_B1. Please inspect the actual matrices rather than reasoning from this message alone.

New exact measurements since your previous review:

1. Sage ore_algebra uncouples rational specializations in one variable in 6-8 ms. At three nonzero rational epsilon values, CF258_B9, CF300_B10, and CF231_B1 each yield an irreducible order-four scalar operator. At epsilon=0, CF258_B9 factors into four first-order operators, while CF300_B10 and CF231_B1 factorization did not finish within 30 s. Generic uncoupling of CF258_B9 over Q(epsilon,y)(x) exceeded 300 s and about 1 GB resident memory.
2. FiniteFlow was built locally and its exact rational reconstruction was verified. INITIAL was then tested on the package's published eight-master elliptic-kite example: in 2.13 s it reproduced the stored transformation exactly and the transformed matrix divided by epsilon is epsilon-independent.
3. The 2026 twisted Griffiths-Dwork work of Vanhove is especially relevant because it treats dimensionally regulated relative periods, but its arXiv source contains no executable worksheet or package.

Please answer these concrete questions.

A. For each attached block, identify any exact structure visible directly in the matrices that should be tested before another rational epsilon-form search: reduction to one invariant, reducible submodule, symmetric-power structure, lower-order Picard-Fuchs factor, or a maximal-cut period that can seed INITIAL. Give exact algebraic criteria, not visual guesses.

B. Is INITIAL a sensible next engine for any of these four blocks? State precisely what seed integral or derivative relation it requires. If the current records do not contain enough information, say what exact maximal-cut object must be derived and whether an established public package can derive it.

C. Survey public exact software beyond CANONICA, Libra, ore_algebra, Singular dmodapp, Macaulay2 Dmodules, HyperFLINT, and SubTropica that could automate one of the missing steps for these matrices. Give priority to tools for Moser/Fuchs reduction, maximal-cut or Baikov periods, twisted Picard-Fuchs operators at symbolic epsilon, differential-operator factorization, and elliptic or more general canonical forms. Distinguish exact analytic output from fixed-point numerical evaluation.

D. Can Vanhove's twisted Griffiths-Dwork algorithm be implemented economically using Singular, Macaulay2, Sage, or another available algebra system, or does it require substantial new algebra? Identify a controlled FACET fixture that would test such an implementation before using a hard block.

E. Propose deterministic reusable functions and their exact acceptance identities. In particular consider: exact flatness and singular-divisor census; one-variable pullback detection; Fuchsian pole reduction; scalarization with bounded resource criteria; local indicial data; maximal-cut seed verification; INITIAL transformation verification; and physical boundary-source bookkeeping.

The project requires exact analytic cut masters with epsilon and physical-branch information. Numerical values are independent checks only. Do not recommend a numerical transport package as the main evaluator.

## Pro response

_No Pro response was recorded._

## Sources sent to Pro

- Original source reference: `../../MasterEvaluationWorkflow/PackageEvaluation/KallenConnectionsForOre.json` (not archived with this exchange)
