# Stage 1 costs and epsilon-form criteria

The implemented changes reduce repeated algebra in the general stage-1 code.
They also correct diagnostics that had been described as epsilon-form
nonexistence proofs. No family-specific branch was added to the package.

## Measured scope

| Operation | Before | After | What completed |
|---|---:|---:|---|
| CF259 initial assembly, Production | about 206 s | 16.81 s | All 47 masters, 27 diagonal blocks; explicit transformed lower blocks |
| CF259 sectors 1–12, including initial assembly | 470 s | 82 s | Same transformations and inverse; same transformed DE at rational points |
| Three-root integrability screen, letter scoring enabled | 1.063 s | 0.766 s | Same 768 x 48 matrix dimensions, rank 40, augmented rank 40 |
| Three-root screen, production settings | 1.063 s | 0.743 s | Same result; optional per-letter rank calculations omitted |

CF259 is a physical three-root family. The small screen measurement is a
controlled constructed example with three independent quadratic extensions,
eight sign choices per point, twelve points, and a known transformation.
It is not a timing for a physical hard block.

The initial CF259 assembly excludes all subsequent off-diagonal solves,
regulator factorization and final family validation. The before number is
rounded from the driver log; the after number includes startup and input
checking in the assembly-only script. It is approximately a twelvefold
reduction, not a claim that complete canonicalization is twelve times faster.
The accidental Development-mode baseline did not complete initial assembly
before it was stopped; its elapsed lower bound is retained, but no completed
speedup is inferred from that run.

All computations were restricted to the same eight CPU cores
0,1,6,7,8,9,18,19. The family driver used one coordinating kernel and up to
eight native threads. The small screen uses the Wolfram evaluator. The
`/usr/bin/time` CPU and memory fields refer to the launcher and do not measure
the separately launched Wolfram kernel, so they are not used as kernel costs.

The [assembly check](../Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/Stage1CostsAndEpsilonFormCriteria_2026-09-06/assembly-validation.json)
compares the complete transformed connection with the previous Production
assembly and independently checks
\(A_\mu T-\partial_\mu T-T A'_\mu=0\) and \(T^{-1}T=1\), at three rational
points using 80-digit arithmetic. All residuals are consistent with zero,
with at least 59 decimal digits of absolute accuracy.

## What changed

1. The sector driver now propagates its selected `FACET_CHECK_LEVEL` into the
   package. Previously an unset environment variable made the driver report
   Production while the package defaulted to Development, repeating large
   symbolic identities.
2. Production assembly retains ordinary explicit sums and products in
   \(T_i^{-1}A_{ij}T_j\), instead of applying `Together` to every off-diagonal
   coefficient before any block is selected. This is a finite expression,
   with no unevaluated transformation or generator. The public
   `OffDiagonalSimplification` option accepts `PreserveProducts` or `Together`;
   Development defaults to the latter.
3. The multiquadratic integrability screen evaluates each scalar and its
   first derivatives once per point/sign choice. Previously values and
   derivatives repeated the same evaluation. Per-letter rank scoring is
   opt-in at the production driver.
4. Exact zero block transformations bypass prime reconstruction, while
   retaining the coefficient representation needed by the usual final
   modular DE residual. A sampled zero is insufficient for this shortcut.
   Malformed root metadata is still refused.
5. The rational expansion diagnostic no longer automatically consumes up
   to 900 seconds after a failed solve. It is opt-in through
   `FACET_OBSTRUCTION_ANALYSIS_SECONDS` and bounded by the remaining block
   deadline.
6. The integrability screen checks closedness of supplied target one-forms
   at its samples. The transformation-elimination formula assumed this
   condition but previously did not test it.
7. The rational pole/degree support certificate now requires
   epsilon-independent diagonal coefficients and target forms. The usual
   invertibility argument for the leading pole coefficient relies on that
   hypothesis. Its metadata distinguishes a kinematic support bound from
   completeness in epsilon or a nonexistence theorem.

The current CF259 block-decomposition file used an obsolete field. The
benchmark recomputed its decomposition from the current V2 DE and verified
that both the partition and ordering agree. It did not load a pre-V2 result.
The original saved artifact was preserved.

## What the negative criteria actually establish

Write a fixed block-completion equation as
\[
 dG=\epsilon(eG-Gc)+b-\epsilon\sum_k R_k\omega_k,
\]
with fixed diagonal connections \(e,c\), effective inhomogeneity \(b\),
closed target one-forms \(\omega_k\), and kinematics-independent residues
\(R_k\). Cross-differentiation, using diagonal flatness, eliminates \(G\)
and gives a linear compatibility system for the residues.

There are three distinct conclusions:

- An exactly inconsistent compatibility system in characteristic zero
  excludes every \(G\) for **these fixed data and target forms**. No polynomial
  degree or denominator bound on \(G\) is needed for that statement.
- Inconsistency of a finite transformation ansatz excludes only that
  enumerated support. A larger support, or a different parameterization of
  that support, can succeed.
- Inconsistency at sampled finite-field images is exact arithmetic at those
  images. Repetition supplies probabilistic evidence, not by itself the
  characteristic-zero or arbitrary-basis theorem.

The code retains the useful sampled decisions, including independent fresh
images and their witnesses. It now records the fixed target, whether the
transformation ansatz was eliminated, arithmetic scope, and the absence of
proved generic nonexistence, alphabet completeness or arbitrary-basis
exclusion. Formal generator sign changes are distinguished from a certified
Galois interpretation. The high-level root-order routine already rejects
detected square-class dependencies; directly supplied low-level root records
do not become a field certificate merely by being sampled.

Independent solves at different epsilon values allow independent residue
unknowns at those images. That is a relaxation of a strictly
epsilon-independent residue matrix, not an explicit rational-in-epsilon
solution.

### A cheap route to a rigorous fixed-target result

A certified characteristic-zero upper bound
\(\operatorname{rank}M\leq r_*\), together with an admissible modular image
having \(\operatorname{rank}[M|b]>r_*\), proves incompatibility. In particular,
if \(M\) has \(n\) columns and the augmented rank is \(n+1\), the upper bound
\(n\) is automatic. Reduction must respect the algebraic relations and all
denominators, and the flatness used in eliminating \(G\) needs exact or
inherited justification.

The existing repeated rank measurements alone do not supply that upper
bound in a rank-deficient case. This optional certificate construction was
not added to the computation path. It should be attempted when cheap, not
made a prerequisite for every block.

A claim under every admissible basis needs more: a basis-invariant
obstruction, or a proof that all admissible transformations reduce to the
fixed problem being tested. A claim about all rational transformations
obtained by searching a finite space additionally needs justified pole
bounds, a complete numerator space, regulator scope, and a complete target
class.

The one-variable criterion of
[Lee and Pomeransky](https://arxiv.org/html/1707.07856)
concerns rational systems on the Riemann sphere, normalized Fuchsian forms,
and rational transformations. It cannot simply be applied to a two-variable
multiquadratic surface. The multivariable rational-ansatz methods of
[Meyer](https://arxiv.org/abs/1611.01087) and
[CANONICA](https://arxiv.org/abs/1705.06252)
are relevant constructions; choosing one finite ansatz is not itself a
proof that the whole permitted class has been searched.

## Concrete corrections

### Distinct geometric residue components

The previous helper returned `NonConstantResidue` for
\[
 \omega=\frac{dx}{1+x^2}
       =\frac{d\log(x-i)-d\log(x+i)}{2i}.
\]
The residues \(1/(2i)\) and \(-1/(2i)\) are different constants on different
components. Their inequality does not mean variation along a component.

The helper now returns `ResidueComponentsNotResolved` when its transverse
samples have not resolved that distinction. Failure of `Integrate` to
construct a rational primitive is `RationalPrimitiveNotConstructed`, also
inconclusive. The helper refuses algebraic coefficient fields and negative
epsilon input orders rather than silently using its rational Taylor model.
Its expansion starts at order zero, and its primitive integration constants
are fixed to zero; every result is explicitly conditional on that choice.
`NoObstructionToOrder` is a finite expansion result, not a proof of a
rational-in-epsilon transformation.

Eleven old test failures exposed a non-closed target form in the exceptional
epsilon fixture. The replacement uses closed forms and explicit generic
residues, preserving the intended exceptional-specialization test. The
corrected test passes all 58 assertions. A separate control verifies that a
non-closed target is refused.

### CF300 is not certified noncanonical as a family

The retained
[CF300 (12,9) result](../Archive/History/Exchange/Codex/2026-08-24/01_cf300_cf303_pair_chart_campaign/cf300_pair_chart_campaign/CF300_PAIR_CHART_V2_SOLVE_REPORT_2026-08-24.md)
reports an exact successful transformation with vanishing Pfaffian residuals.
This block has two active roots, despite the family having three.

For identical sampled rows, its conventional rectangle gave ranks
1636/1637, while the complete total-degree-26 simplex gave ranks 1564/1564.
The rectangle contained 396 monomials and the simplex only 378: the issue was
which monomials were included, not simply the number. A successful
reconstruction was retained with the expanded target letters.

This historical isolated result was not installed into a fresh V2 family
state during this audit. It does invalidate treating that rectangle failure
as an unconditional obstruction for CF300 (12,9). It says nothing by itself
about every other CF300 block.

### CF303 historical claims also need narrower scope

The [2026-08-30 note](../Archive/History/Exchange/Codex/2026-08-30/05_cf303_dlog_no_go_and_rational_kernel_route.md)
records, for example, ranks 188/189 with 192 residue columns at three images.
Those ranks establish inconsistency of the sampled fixed-target systems.
They do not alone prove a characteristic-zero rank upper bound of 188,
alphabet completeness on the permitted algebraic field, or invariance under
all previously unfixed basis choices. Claims that the exceptional-image
caveat is mathematically closed by repetition, or that no rational dlog form
exists in any basis, are stronger than the retained evidence.

The historical note and the later overhaul report now begin with a visible
correction; their original measurements remain intact. No new universal
nonexistence claim is substituted.

The [Pro exchange](../External/ChatGPT/Records/2026-09-06/01_stage1_costs_and_epsilon_form_nonexistence.md)
contains the independent review and counterexamples. Its recommendations
were assessed against the local code and records.

## Validation and remaining work

The focused checks cover source-coordinate reconstruction, zero
transformations, malformed root metadata, exceptional epsilon images,
independent confirming images, closedness, residue components, rational
support hypotheses, native deferred evaluation, the multiquadratic assembly,
Production/Development equivalence, package generality and public usage.

The three-root screen returns the same ranks as before, and the full CF259
initial assembly passes the independent numerical DE identities described
above. There are 213 passing focused assertions/checks, plus the numerical
assembly and prefix comparisons. The [test summary](../Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/Validation/Stage1CostsAndEpsilonFormCriteria_2026-09-06/test-results.json)
and per-file logs distinguish the final passing runs from the earlier
invalid-fixture failures.

### Fresh CF259 continuation

The final fresh run completed sectors 1–17 (28 master positions) and solved
additional blocks in sector 18. The formerly rejected zero transformation
(13,12) passed the ordinary post-reconstruction modular DE residual; later
zero blocks also passed. It stopped at block (18,13) during regulator-sample
generation because the 600-second family allowance had expired. That block's
initial support system was consistent. This is a budget stop, not an
epsilon-form obstruction.

The final log reports 522 seconds through sector 17 and 617 seconds at the
budget stop, from its driver clock. The allowance starts after initial
assembly, explaining the additional approximately 17 seconds. Launcher
elapsed time was 623 seconds including startup; the separately recorded Python
monotonic duration differs and is not used in the comparisons. Two short
read-only numerical comparisons overlapped this final continuation, so it
is a progress profile rather than a matched full-family benchmark.

The earlier matched prefix comparison used the before/after states at sector
12: S and SInverse agree as exact expressions, and the represented connection
agrees at two rational points with 65-digit arithmetic. Initial assembly,
repeated preparation and coefficient simplification all contribute to the
470-to-82-second reduction.

A fully canonical CF259 family was not produced in this bounded run.
No all-family regeneration or universal nonexistence certification is claimed.
General stage-2 integration remains available for supported non-epsilon-form
connections; an unresolved stage-1 search is not a reason to label the DE
unsolvable.
