# Review of the solution representation before boundary evaluation

This is a design assessment, not a claim that the package has completed stage 2.
It challenges the existing completion conditions. No production solver or
existing result was changed during this review.

## What the current files establish

The V2 results directory contains family dlog epsilon forms for CF269
(23 master integrals, 6 letters) and CF48 (27 master integrals, 14 letters).
Their validation methods are explicitly probabilistic finite-field sampling.
The CF259 and CF265 V2 work remains incomplete. Historical timings or
pre-V2 path operators do not establish current completion.

CF303 has a tangential boundary evolution record through epsilon order six.
Its normal-direction record instead reports
CF303NormalBulkFixedRhoTangentialConnectionMissing. In particular, the current
physical-boundary construction lacks the full tangential connection at fixed
rho in the same basis as its normal solution, or an independently validated
equivalent mode-matching calculation. With rho=2p-z, this connection is
A_p|rho=A_p|z+2 A_z. The record also identifies required characteristic-zero
coefficient construction that remains deferred. These are substantive gaps,
not merely serialization costs.

The current ConstructMasterIntegralSolution can emit an
OrderedSparseCoefficientOperatorProduct and DemandCoverage=Complete.
That does not establish that every requested coefficient is stored as a
finite expression. The requested-output interface and the finished analytic
expression must be assessed separately.

The preserved hard-function coefficient-valuation input has 347 entries over
91 family labels, including two explicit ZeroColumn entries. This is an
inventory, not a completed-solution count. Exact epsilon-order requirements
must be derived from the physical request, pole orders, basis transformations,
and known zeros before any claim of complete coverage.

## A small measured size experiment

Starting from the two stored dlog forms, I constructed all nonzero products
R_{a1}...R_{ak} for k=1,...,4 and wrote the actual sparse matrices and their
explicit letter sequences. No generator substitutes for the stored entries.

| Family | Masters | Letters | Nonzero sequences at order 4 | Scalar nonzeros at order 4 | Plain-text bytes, orders 1–4 |
|---|---:|---:|---:|---:|---:|
| CF269 | 23 | 6 | 1,025 | 61,891 | 1,117,845 |
| CF48 | 27 | 14 | 9,772 | 403,598 | 7,720,616 |

The same stored tables compress with gzip to 143,786 bytes for CF269 and
879,107 bytes for CF48. Compression changes neither content nor completeness.
The small supporting script and JSON measurements are retained in the
companion sources directory.

These are canonical fundamental-matrix coefficient tables only. They do not
include original-basis conversion, initial-data convolution, branch/path
packaging, or proof that order four covers the requested physical outputs.
They support a bounded explicit-output pilot, not a claim that all families
will fit these sizes. There was no need for a large symbolic solve to
construct these tables.

The earlier 636 MB CF48 output and 59 MiB finite-state representation,
recorded in PerformanceBaselines_2026-09-04.md, describe a different, more
composed result. They must not be presented as directly comparable timings
or compression ratios.

## Separate the two questions

Choose a nonsingular base point x0 in the analytic domain of the intended
branch, and write

\[
 I(x,\epsilon)=U(x,x_0;\epsilon)C(\epsilon),\qquad
 U(x_0,x_0;\epsilon)=1,\quad C(\epsilon)=I(x_0,\epsilon).
\]

The coordinates of x0 are fixed numbers, not spectator variables.
The entries of C are therefore constants with respect to every kinematic
variable. Choosing a Euclidean point is optional; for cut integrals an
ordinary point in an appropriate physical analytic domain may be preferable.

A stage-2 result stores the required coefficients of U as explicit functions.
Stage 3 determines C from physical boundary conditions, region expansions,
known integrals, or independently evaluated initial values. Singular-boundary
matching is still necessary when those are the chosen conditions, but should
not be the only allowed normalization of a stage-2 solution.

This choice can make constants more complicated than at a singular boundary.
It does not prove that the constants are known, nor that all desired
boundary-matching equations have already been constructed. A practical result
should also carry enough local asymptotic information to formulate those
equations for C. An unevaluated c(p,epsilon) on a boundary stratum still fails
the requirement.

## Recommended finite representation

For each required original-master coefficient store a finite expression

\[
 I_r^{(n)}(x)=
 \sum_{j,m,\alpha} R_{rj\alpha}^{(n,m)}(x)
 F_\alpha(x;x_0)\,C_j^{(m)}.
\]

All index sets and all nonzero coefficients are explicitly stored.
R is rational or algebraic over a declared coefficient field. Each F is
defined by a fixed finite integral expression. Products of functions may be
retained; they need not be expanded with shuffle identities.

Use a shared finite spanning set of functions first. Calling it a basis
requires the relevant independence statement, and proving minimality is not
a prerequisite for a correct portable answer. Start with explicit Chen
iterated integrals, MPLs, or justified elliptic integrals. Reduce duplicate
definitions and repeated subexpressions before attempting expensive global
function-space reductions.

For an epsilon-form system, a Chen integral definition includes an actual
ordered letter sequence, explicit one-forms, a path and its orientation,
base point, endpoint, and branch/regularization prescription. Merely declaring
F_alpha to be 'the solution of this DE' or 'the coefficient returned by this
operator' is not an acceptable definition.

A small directory per family can contain:

- conventions.m: basis ordering, kinematic variables, base point, domain,
  paths, branches, epsilon ranges, and initial-constant definitions;
- kernels.m: the exact differential one-forms and any defining algebraic curves;
- functions.m: every used function's explicit finite integral definition;
- coefficients_order_n.m: sparse original-master expressions linear in the
  initial constants, with shared finite subexpressions;
- boundary_asymptotics.m: computed local expansions and matching equations,
  when available, with the known normal powers and logarithms retained;
- validation.m: identities checked, retained orders, and validation methods.

These names are examples of file organization, not new mathematical jargon.
Plain-text Wolfram expressions suit this package and the community examples
below. Compress and separate files by family and epsilon order; a WXF cache
may accelerate reads, but the text definitions should remain portable.
Do not set a speculative universal size limit before measuring the actual
required orders of CF269, CF48 and CF303.

## What is and is not a solved expression

| Representation | Assessment for this request |
|---|---|
| Finite sparse sums of explicit iterated integrals | Acceptable |
| Finite shared functions, each defined by explicit integrals | Recommended |
| Finite arithmetic expressions sharing already-known subexpressions | Acceptable; expansion of every product is unnecessary |
| Product of already-solved finite path-segment matrices | Acceptable if every coefficient of every factor is stored and only finite algebra remains |
| Product of coefficient generators or finite-field evaluators | Not a completed solution |
| Bare path-ordered exponential or recurrence | Formal solution, insufficient as the requested deliverable |
| Symbol alone | Insufficient: lower-weight and constant information is missing |
| Finite Taylor/Frobenius expansion | Useful local result or numerical companion; not a general analytic solution on its own |

The critical test is whether any coefficient reconstruction, Hermite reduction,
basis-transformation solve, differential-equation solve, or search over
unstored letter sequences is still needed when reading a requested answer.
Evaluating a defined special function or performing finite algebra on fully
stored expressions is a different operation and is allowed.

## A finite quadrature is an explicit function definition

For example, suppose
dJ1=0, dJ2=epsilon J1 dx/x, and dJ3=epsilon J2 dx/(1-x).
At a nonsingular fixed x0, the solution contains the definite function

F(x)=Integral[log(t/x0)/(1-t), {t,x0,x}],

and J3=C3-epsilon log((1-x)/(1-x0)) C2+epsilon^2 F(x) C1.
Storing F with this explicit integrand and limits is a solution in quadratures.
Declaring instead that F is whatever a DE solver or coefficient query returns
is not. The same distinction applies to shared scalar integrals at higher
epsilon orders: every integrand and finite dependency must be supplied.

## CF303 need not wait for a global dlog epsilon form

For a block equation with known homogeneous fundamental matrix H,

\[
 F_T(u)=H(u)\left[
 C_T+\int_{u_0}^{u} H(t)^{-1}B(t)F_S(t)\,dt
 \right],
\]

variation of constants is a legitimate solution when H, B and F_S are
explicitly known and the displayed finite epsilon coefficients are stored.
An elliptic homogeneous solution need not be forced into rational dlog form.
Finite nested quadratures with fully specified kernels are admissible.

The formula is not a solution if H is an unknown fundamental matrix, if B
still requires reconstruction, or if F_S is a generator. All independent
kinematic equations must be checked, including the derivative of any moving
basis and the dependence of later path segments on earlier endpoint variables.
Laurent poles in epsilon require explicit order bookkeeping.

## Concrete community precedents

[PentagonMI](https://gitlab.com/pentagon-functions/PentagonMI/-/raw/master/datafiles/README.md)
stores master integrals using 1,917 shared combinations of pentagon functions,
with separate files defining those combinations, the functions, and constants.
Its text data are intended to be understandable outside the package; a
binary cache is optional.

The [one-mass pentagon-function paper](https://arxiv.org/html/2110.10111v2)
provides mi2pfuncs.m for master-to-function expressions,
pfuncs_iterated_integrals.m for function definitions, and
pfuncs_expressions.m for alternative explicit representations.
The associated [evaluation library](https://gitlab.com/pentagon-functions/PentagonFunctions-cpp/-/raw/master/README.md)
evaluates higher-weight functions using one-fold integrals.
Thus a definite integral representation can be a published solved result;
it need not be reduced to elementary functions.

The [quarkonium master-integral ancillary data](https://gitlab.com/onium_pseudo_scalar/master_integrals/-/raw/main/README.md)
provide replacement rules order by order in epsilon.
Their [elliptic-function definitions](https://gitlab.com/onium_pseudo_scalar/master_integrals/-/raw/main/elliptics/README.md)
specify eMPLs, iterated Eisenstein integrals, periods and curve data separately.
This illustrates why the general function definitions must accompany the
coefficient tables.

[DiffExp](https://arxiv.org/abs/2006.05510) instead constructs truncated local
series along paths. It is a strong numerical cross-check, but storing only
the instructions for those series does not meet this user's analytic
deliverable requirement.

A particularly relevant elliptic precedent is
[Adams, Chaubey and Weinzierl, arXiv:1806.04981](https://arxiv.org/pdf/1806.04981).
Their system has A=A^(0)+epsilon A^(1), with A^(0) strictly lower triangular.
Appendix E describes an ASCII Maple file containing the basis, transformations,
connection, explicit integration kernels, and a separate J with master-integral
answers through epsilon^4. A full strict epsilon form was not required to
publish the solved expressions.

## Independent ChatGPT Pro review

I requested a new gpt-6-pro conversation specifically to challenge this
assessment. The complete question and retrieved response are saved in
[the dated exchange](../External/ChatGPT/Records/2026-09-05/01_pre_stage3_solution_representation_review.md).
Pro inspected the pushed constructor code, while its assessment of local
artifacts relied on the facts supplied in the prompt. The local measurements
above are my own.

Pro agrees on ordinary-point normalization, finite explicit function
definitions, and allowing fixed arithmetic products without globally expanding
them. Its most useful additional qualifications are:

- Do not hide unknown initial constants inside the shared function definitions.
  Keep every required initial-data coefficient visibly linear.
- A physical solution may be much smaller than a fundamental matrix acting on
  arbitrary initial data. Compact published amplitudes are not size guarantees
  for a generic 45-master solution.
- For stage 3, compute enough independent asymptotic constraints on the
  ordinary-point constants; it is not always necessary to construct the
  complete physical-boundary-to-bulk map.
- Negative epsilon powers require a terminating order structure. For example,
  df/dx=f/epsilon has exp(x/epsilon) solutions, not a lower-bounded Laurent
  fundamental solution for arbitrary initial data. This is a caution for the
  construction method, not a claim about CF303.
- Validate with several independent initial-data vectors, so cancellations in
  one physical combination cannot hide missing columns.
- A nonsingular straight path on a declared patch may avoid unnecessary
  normal/tangential composition. It is not a claim of global coverage.

Pro proposes a language-neutral expression grammar stored in JSON. I would
start with documented, data-only Wolfram text because this project already
uses it and several cited ancillary archives do too. Inventing a new symbolic
serialization system should not delay the first completed example. A neutral
export can be added if a real external consumer needs it.

## Next decisive work

1. Fix the completion test around explicit finite expressions and genuinely
   constant initial data; keep physical-branch completion separate.
2. Finish one CF269 export at the actual required epsilon orders, reload it
   without the solver, and verify both kinematic differential equations,
   normalization and linearity in constants.
3. Repeat for CF48, measuring total text/compressed size, peak memory, and
   the cost of retrieving one coefficient. Compare sparse word sums with
   shared-function expressions on exactly the same requested outputs.
4. For CF303, resolve the missing mathematical input and construct a complete
   requested final-block coefficient, including all contributing lower blocks
   and epsilon orders. Compare ordinary-base normalization and the existing
   physical-boundary construction, with no demand pruning based on
   unproved values of arbitrary initial constants.
5. Only then commit to broad family regeneration.

There is no defensible percentage completion or full-project ETA from the
current evidence. Ordinary dlog families are close to a concrete export
experiment. CF303 and unfinished family constructions retain mathematical
work beyond that export.
