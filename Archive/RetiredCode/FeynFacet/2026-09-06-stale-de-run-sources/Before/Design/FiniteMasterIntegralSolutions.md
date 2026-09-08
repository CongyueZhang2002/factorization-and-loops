# Finite master-integral solutions at an ordinary point

Implemented 2026-09-05. All algorithms accept the process, family, variables,
matrix dimensions and epsilon orders as data. No family-specific cases occur
in the package or the export driver.

## Mathematical output

For a fixed ordinary point X0 the stored answer is

    I(X,epsilon) = U(X,X0;epsilon) C(epsilon),
    U(X0,X0;epsilon) = 1,    C(epsilon) = I(X0,epsilon).

Every component of C is independent of every kinematic variable. The output
contains explicit requested coefficients of I in the constants C[j,m], or
complete selected coefficients of U when that interface is requested. It is a finite-order local analytic
solution. Physical boundary values and global analytic continuation are
separate problems.

The input is dJ=A J, I=T J. An optional explicitly known
epsilon-independent H can first change J=H P. General preparation then:

1. Determines exact epsilon valuations and solves the integer difference
   constraints for diagonal epsilon rescaling by Bellman-Ford.
2. When diagonal rescaling fails, tries a common constant nilpotent flag for
   the negative-order coefficient matrices. A negative cycle alone does not
   prove that a Laurent solution is impossible.
3. Decomposes the epsilon-zero connection into strongly connected blocks.
   It searches for rational/algebraic horizontal sections, invariant
   subspaces, and explicit scalar or matrix homogeneous solutions.
   Previously computed block reductions can be supplied and checked against
   the current input.
4. Permutes the resulting acyclic epsilon-zero graph into triangular order.

Applying a saved preparation also retains its source connection and basis.
The constructor can expand the smaller source connection first and perform
the exact gauge transformation coefficient by coefficient. This avoids a
large global epsilon expansion of elementary-function quotients; the final
coefficient arrays and integrands are still fully materialized.

The resulting dP=B P must have nonnegative epsilon powers and strictly
lower triangular B0. This includes strict epsilon forms, non-dlog kernels,
and supplied elliptic homogeneous functions in supported standard special
functions. Rational epsilon dependence need not be polynomial.

The searches for horizontal sections and homogeneous solutions are bounded
sufficient constructions. Failure is not a proof that the DE is unsolvable.
An irreducible period module still needs an explicit homogeneous basis if
the available solvers do not find one. An unspecified matrix, unknown
function, unevaluated DSolve, or essential epsilon singularity cannot be
exported as a finite Laurent solution.

## What the files actually contain

Pull back each Bq to gamma(t)=X0+t(X-X0). Variation of constants terminates
in epsilon order and then row order: positive epsilon orders use completed
orders, and order-zero couplings use completed rows.

Every scalar function has a fixed definition

    F_i(s) = Integral[g_i(t_i), {t_i,0,s}],

where g_i is explicit finite arithmetic containing known scalar kernels
K_j(t_i) and earlier F_j(t_i), j<i. Every K_j has a stored explicit
expression using only earlier K_l at the same argument. These scalar
definitions share repeated coefficient expressions before the path
substitution. The factors d gamma/dt are then included in the integration
kernels. Their dependency order is checked by both the constructor and
standalone reader. The final basis convolutions use separate a_i definitions.

KernelDefinitionCounts distinguishes shared scalar expressions from final
integration kernels. Both are fixed expressions, with no deferred coefficient
calculation. The optional exact verifier expands earlier definitions; the
numerical verifier and standalone reader evaluate each once per point.

All required integrands, epsilon coefficients and both basis-change
convolutions are constructed before export. Reading the answer does not
enumerate words, run a recurrence, call a DE solver or obtain more
coefficients from a generator. Common expressions remain shared to avoid
duplicating large nested integrals. Full substitution into one expanded
expression is possible but unnecessary.

## Public interface

    FindEpsilonRescaling[connectionMatrices, epsilon]
    PrepareDifferentialSystemForFiniteIntegration[system, options]
    ApplyFiniteIntegrationPreparation[system, preparation]
    ConstructMasterIntegralSolution[system, request, options]
    MasterIntegralSolutionQ[result]
    MasterIntegralSolutionCoefficient[result, row, order]
    ExpandMasterIntegralSolutionInInitialConstants[result, lowerBounds, orders]
    VerifyMasterIntegralSolution[result, options]
    WriteMasterIntegralSolution[result, directory, options]

Required system fields are KinematicVariables, DimensionalRegulator and
ConnectionMatrices. Optional fields include OriginalMasterIntegralBasis,
BasisTransformationMatrix and its inverse, HomogeneousFundamentalMatrix
and its inverse, OriginalConnectionMatrices, and InputValidation.

The main request interface now accepts different ranges for each original master:

```wl
solution = ConstructMasterIntegralSolution[system,
  <|"RequestedMasterIntegralOrderRanges" -> <|1 -> {-2,0}, 2 -> {-1,1}|>|>];
WriteMasterIntegralSolution[solution, directory, "FileFormat" -> "WXF"];
```

When only upper cutoffs are supplied, use
`"RequestedMasterIntegralUpperOrders" -> <|1 -> 0, 2 -> 1|>`.
This is exclusive with explicit range requests. If the declared boundary
bounds are beta[j] and the complete original-basis evolution has entry bounds
tau[i,j], the output lower cutoff is min_j(tau[i,j]+beta[j]). A bound at the
ordinary point alone is insufficient: another boundary component, or an
epsilon pole in the evolution, can produce lower orders away from that point.
The existing valuation calculation supplies tau without constructing another
transfer matrix. A target below this bound is stored as zero and never lowers
the allowed boundary-constant orders.

The result is a complete finite solution within the declared Laurent class
of boundary constants. Further physical relations between constants are not
inferred or used to delete coefficients.

Topology/kinematic references in `system` supply the defining integrals.
The call derives Laurent bounds, prepares the DE, determines entrywise
evolution and boundary orders, constructs every required finite integral,
and performs the convolution into `MasterIntegralCoefficients`.
`ExpansionOrderDetermination` preserves the mathematical order report;
`RequiredInitialConstantCoefficients` gives the actual pairs {j,m} occurring
in the answer. Unknown bounds stop construction. Explicitly supplied bounds
are accepted as assumptions and labelled conditional.

The point, basis and constant normalization are shared by the order calculation
and solution. With this interface, `BasePoint` is optional: the planner checks
ordinary-point conditions, the supplied `BasePointRegion`, and supported
physical cut conditions. A saved dimensional recurrence supplies its point
when no explicit point is requested. The default domain is a simply connected
ordinary neighborhood containing the integration paths. Supply
`AnalyticDomain` and `BranchPrescription` when more precise information is
available. Point choice does not optimize boundary-evaluation cost.

Only U entries needed for the requested master coefficients are computed.
Entries above their recorded upper orders are `Missing["NotComputed"]`;
known vanishing coefficients are zero. These have different mathematical
meanings. A request for a whole uncomputed U row returns failure.
The final requested master coefficients contain no missing entries.

For direct U output, specify `BasePoint`, `RequestedEpsilonOrders`,
`AnalyticDomain`, `BranchPrescription`, and optionally `RequestedRows`.
Here `RequestedEpsilonOrders` refers to U. The separate
`RequestedMasterIntegralEpsilonOrders` plus
`InitialConstantLaurentLowerBounds` interface is also available.

The integrated master-range export uses ordinary constants C=I(X0).
The order planner also supports Frobenius-normalized constants, but exporting
a solution in those singular constants requires an explicit matching matrix;
the ordinary constructor rejects such a normalization request.

The hard-function requirement producer accepts justified master Laurent
lower bounds as its third argument. Without them it reports upper bounds
only. Known zero coefficients have valuation Infinity and demand no
master coefficients.

## Validation policy

Checks should take a small fraction of the computation. The production
default is NumericalPoints: evaluate at 80-digit precision at three
deterministic nearby rational offsets from X0, with distinct rational
epsilon values. Relative residual tolerance is 10^-50. Explicit
ValidationPoints can replace these points and must specify all coordinates
and epsilon. The declared analytic patch must contain the validation points
as well as the integration paths.

Input gauge and flatness checks evaluate the matrix factors numerically
before multiplying them. Their records explicitly say ExactIdentity=False.
A sampled result is evidence, not a generic symbolic proof. Exact symbolic
checking is available through FlatnessCheck->"Exact". RationalPoints checks
flatness at explicitly supplied exact points; the basis identity is still
checked exactly in this mode.

The optional VerifyMasterIntegralSolution pass checks the *stored*
integrands, kernel pullbacks, normalization and final convolutions, including the master/C convolution.
The checks respect declared uncomputed U entries and reject inconsistent
order masks or a base point that differs from the order calculation.
IdentityCheck->"NumericalPoints" samples expensive identities while retaining
the inexpensive exact finite-integral and convolution identities.
IdentityCheck->"Exact" proves all these identities at generic kinematics.
Exact flatness and exact gauges then imply all coordinate DEs by the
endpoint-variation equation along the path. A check only at X0 would not
establish this.

The driver does not repeat the full coefficient verification unless
VerifyCoefficientIdentities->True is requested. Independent numerical
evaluation of the finite integrals is available for spot checks; routine
production does not run a costly second DE computation. AMFlow comparison
of physically normalized master integrals remains the eventual independent
numerical validation after the boundary constants are known.

## Portable data and evaluation

With `"FileFormat" -> "WXF"`, the directory contains one compressed
`solution.wxf`. It contains the full finite solution association, including
all explicit integral definitions, coefficient expressions, order derivations
and validation records. `Import[path,"WXF"]` reads it directly.
There is no coefficient generator in the file. Binary serialization uses
Wolfram compression and writes atomically.

The default `"FileFormat" -> "WolframText"` stores schema version 3 as:

- conventions.m: variables, row order, base point, branches and requests;
- kernels.m: source/prepared connections and exact basis matrices;
- kernel_functions.m: every explicit scalar kernel;
- functions.m: every fixed scalar integral definition;
- transformed_solution_coefficients.m: finite coefficients before basis change;
- basis_convolutions.m: both finite basis-change convolutions;
- algebraic_expressions.m: shared arithmetic in dependency order;
- coefficients_order_n.m: row -> list of U[r,j,n];
- master_integrals_order_n.m: optional expressions in C[j,m];
- validation.m: check methods, scope and inherited input evidence;
- order_determination.wxf: the complete order report, when present.

Both formats contain explicit Wolfram expressions and symbol contexts.
The writer rejects mixed text/WXF output directories to prevent ambiguous reads.
FeynFacetSolution`F, K, a and C have the meanings above. The standalone reader
loads no FeynFacet package:

    Get["FeynFacet/FiniteSolutionData.wl"];
    data = FeynFacetSolution`ReadMasterIntegralSolution[directory];
    FeynFacetSolution`EvaluateMasterIntegralSolution[data, point,
      "QuadratureOrder"->20, "WorkingPrecision"->60]

Evaluation applies piecewise Gauss-Legendre quadrature and interpolation to
the stored finite definitions. The default checks changes in quadrature order,
subdivision and working precision against componentwise absolute/relative
goals. It reports empirical convergence, not a rigorous error bound.

`InitialConstantValues` supplies numerical rules for C[j,m]. The convergence
test then applies to the master coefficients after substitution and includes
arithmetic uncertainty from cancellations. Without that option the constants
remain symbolic. Missing boundary orders are rejected; integer labels are
preserved. `InputGuardDigits` defaults to 5. `CheckConvergence -> False` requests
an explicitly unchecked fixed-order evaluation. No DE is solved.

A limited polynomial path check rejects detected poles/branch points and
reports unresolved factors. General branch continuation and singular endpoint
evaluation are not provided by this reader.
See [numerical evaluation and AMFlow comparisons](NumericalMasterIntegralEvaluation_2026-09-06.md).

The process-independent driver accepts a dlog form or a general system:

    wolframscript -file Scripts/Transport/export_finite_master_integral_solution.wls \
      FORM.wl REQUEST.wl OUTPUT_DIRECTORY

It can read OriginalDifferentialSystemFile, or discover the sibling original
DE for a dlog form and pull back its coordinates. It refuses a changed master
ordering. FiniteIntegrationPreparationFile and
EpsilonZeroBlockReductionFiles reuse computed general reductions.
ConstructionCheckpointFile optionally saves exact constructed expressions
before a separately requested verification pass; it is not a verified result.

The former lazy coefficient-operator intermediates and their public constructors
are retired. Use the [general production drivers](../Scripts/Transport/README.md)
for every family; the backup is not a computation input.

## Several families and resumable execution

The general batch driver accepts any family labels and data:

```sh
wolframscript -file Scripts/Transport/solve_master_integral_families.wls \
  INPUT.wl OUTPUT_DIRECTORY
```

`INPUT.wl` contains `Families -> <|name -> specification,...|>`. Each
specification supplies `Data` or `DataFile`, `Request`, optional `Options`,
and optionally `FiniteIntegrationPreparationFile`. Relative file paths resolve
against the input file. The driver writes a compressed complete solution,
an exact input record, and a summary for each family; `report.wxf` is updated
after each result. Unresolved families do not prevent later independent
families from running.

Resume requires exact equality of the saved system, request and options.
Changed inputs are refused in an existing output directory. Reused results
are reported explicitly. The numerical validation method remains in the
solution; a resume does not claim to rerun it. Conditional pole assumptions
remain conditional in the batch report.

## Earlier five-family examples and current scope

[The executable five-family input](../Examples/Transport/pre_stage3_family_solutions.wl)
is retained as a five-family demonstration. The table below records the earlier
pre-optimization measurements; the later all-family campaign supersedes its scope.
These are demonstration master ranges, not final NNLO observable requirements:

| Family | Master positions | Requested master orders | Prepared evolution through | Construction, s | Compressed solution, MB |
|---|---:|---|---:|---:|---:|
| CF269 | 23 | -3 to 0 | 4 | 6.19 | 1.06 |
| CF48 | 27 | -5 to 0 | 6 | 42.89 | 2.10 |
| CF265 | 32 | -5 to 0 | 7 | 28.06 | 3.31 |
| CF259 | 47 | -5 to 0 | 7 | 150.77 | 9.54 |
| CF303 | 45 | -5 to 0 | 7 | 225.33 | 20.27 |

All 998 requested master coefficients are stored explicitly, with established
integral Laurent bounds. The files total 36,277,487 bytes. The 453.25 seconds
include automatic preparation for CF265/CF259; the other inputs reuse their
saved preparations/forms and CF269's dimensional recurrence. Package startup
and earlier input construction are outside these timings.

All master positions within a coupled system share one point. CF48 uses
(1/6,1/4) in its rationalizing coordinates, corresponding to source coordinates
(v,w)=(5/12,1/6). The others use (1/4,1/3). Its previous source-variable
substitution bug is fixed: the defining integrals are evaluated in the
same coordinates as the DE.

The standalone reader evaluated CF269's master coefficients at
(13/50,17/50), without loading a DE constructor. At 50-digit precision,
12- and 18-node quadrature differed by at most 1.62e-38 when every stored
C[j,m] was set to one for this convergence comparison. This does not
determine the physical constants or replace AMFlow validation.

The current all-family run has regenerated all 91 DEs and constructed 2,220
explicit coefficients for the current coefficient-table demands of 345 masters.
It occupies 79.1 MB compressed and took 31.2 minutes elapsed with family
parallelism. [The campaign report](Stage1And2FullCampaign_2026-09-06.md)
records the inputs and scope. The 174 positions in the earlier table include
lower sectors and are not 174 distinct requested masters.

The remaining general limitations are explicit: coupled real/virtual
parametrization and unsupported integral domains; homogeneous blocks for
which no explicit solution has yet been supplied or found; and a complete
observable calculation specifying endpoint, renormalization and
factorization demands. Physical constants and global continuation are
subsequent work. Ordinary-point solutions themselves contain no unknown
kinematic boundary functions.

[Earlier demonstration measurements](FiniteMasterIntegralSolutions_sources/master_range_measurements.json),
[focused check results](FiniteMasterIntegralSolutions_sources/master_range_checks.json),
[the family inventory](FiniteMasterIntegralSolutions_sources/family_input_inventory.json),
and [the output description](../ppHX_NNLO_DoubleReal/Results/RequestedMasterIntegralSolutions/README.md)
record the completed examples. Earlier U-only exports and their historical
timings remain in `FiniteMasterIntegralSolutions_sources/measurements.json`;
they have not been relabelled as master-range solutions.
