# Numerical evaluation of stored master-integral solutions, 2026-09-06

The general standalone evaluator now checks numerical convergence of the
explicit stored integrals. Full GPL/eMPL reduction and full epsilon-form
canonicalization are not prerequisites. The exact solution files were not
regenerated or replaced.

## Results and timing scope

For the first two rows, the reference is AMFlow 2.0's Mathematica local-series
DE solver acting on the original rational kinematic differential equations.
An explicitly specified finite Laurent polynomial supplies the test boundary;
these are not physical boundary constants. Only diagonal epsilon rescaling is
used before expanding the independent DE into a closed numerical coefficient
system. The reference does not read the stored integral definitions.

| Family | Compared coefficients | Requested tolerance | Largest normalized difference | AMFlow series time | Stored-integral evaluation |
|---|---:|---:|---:|---:|---:|
| CF269 | 16 | 10^-30 | 4.59 × 10^-59 | 2.01 s | 7.89 s |
| CF259 | 56 | 10^-30 | 1.65 × 10^-39 | 28.36 s | 55.72 s |

The normalized difference is
`Abs[a-b]/(1+Max[Abs[a],Abs[b]])`.
The series computations used 90-digit working precision and expansion order
60. Stored-integral timings include numerical refinement checks. DE preparation,
package startup, debugging, and earlier pilots are excluded from the two timing
columns. Concurrent jobs shared the same eight-core allocation; these are not
isolated hardware benchmarks.

CF303's stored coefficients also converged at a 10^-30 tolerance in 56.23 s,
with all final values numerical. Its 360-dimensional expanded reference
system was stopped after more than five minutes because the independent check
was becoming too costly. This is neither a discrepancy nor a completed
independent CF303 comparison. Three non-polynomial factors remain outside the
limited automatic path check.

### Physical CF3 comparison

**Scope correction from the optimization audit:** the saved boundary,
reference and transported coefficients are all zero at the tested orders.
These exports predate the corrected AMFlow order conversion and are not
accepted physical validation. The nonzero CF269/CF259 test-boundary comparisons
above remain transport checks. On 2026-09-07 a corrected nonzero physical CF198
comparison passed through epsilon^1; see PhysicalBoundaryResults_2026-09-07.md.

AMFlow independently computed all three closed-system masters at
`X0 = {1/4,1/6}` and `X1 = {13/50,7/40}`, with precision goal 25 and epsilon
coefficients through order 1. These calculations used auxiliary mass flow,
not the kinematic DE reference above. They took about 79 s each.

The stored symbolic solution then used the AMFlow boundary values at X0 to
predict the requested original master at X1. All six stored coefficients,
epsilon^-5 through epsilon^0, passed the 10^-18 absolute/relative comparison,
including estimates of numerical input uncertainty. Evaluation and convergence
checking took about 0.21 s. This checks physical kinematic transport and
evaluation; it does not independently validate the AMFlow boundary values or
an overall kinematics-independent normalization.

The reference export now obtains explicitly requested low coefficients from
the already computed AMFlow Laurent expansion, without another auxiliary-mass-flow
calculation. The re-export path was tested with the AMFlow runtime unavailable.

## Numerical method

`FeynFacet/Solution.m` remains independent of the DE construction
package. It evaluates the stored finite definitions with piecewise
Gauss-Legendre quadrature and polynomial interpolation. Each integral retains
its accumulated value between panels, including the values of all earlier
integrals on which it depends.

The default acceptance criterion compares:

1. two quadrature orders;
2. the higher order on a subdivided mesh;
3. that refined evaluation at higher working precision;
4. the arithmetic uncertainty after any boundary substitution.

The tests are componentwise, using
`10^-AccuracyGoal + 10^-PrecisionGoal Abs[value]`.
Without supplied boundary values, both evolution entries and coefficients of
individual boundary constants are checked. With supplied values, the requested
master coefficients after substitution are checked, so cancellations matter.

These are empirical convergence and arithmetic-error estimates, not rigorous
interval enclosures. Increasing precision never manufactures missing accuracy
in point coordinates or boundary values. AMFlow exports cap the reported
coefficient accuracy at the requested fitting accuracy rather than the much
higher internal working precision.

A polynomial check rejects detected poles or branch points on the integration
path. It also inspects factors written directly in integrands. Unsupported
factors are counted explicitly; the result never claims full analytic
continuation. The present methods apply to the stated ordinary-point domains.
Automatic changes of branch sheet, singular-endpoint regularization and general
contour deformation remain separate work.

## General code and interface

- `FeynFacet/Solution.m`: numerical evaluation, refinement, panel
  propagation, boundary substitution and error reporting.
- `Scripts/Transport/evaluate_master_integral_solution.wls`: validates the
  boundary basis/point and available accuracy, evaluates the result, and
  optionally compares endpoint reference coefficients.
- `Scripts/Transport/evaluate_masters_with_amflow.wls`: accepts integral
  definitions, master identifiers, kinematics and runtime paths as data.
  Computes boundary/reference values with AMFlow and exports exact row/order
  identifiers. An existing sufficient Laurent expansion can be re-exported
  without rerunning AMFlow. A failed new computation preserves a previous
  complete output.
- `Scripts/Transport/compare_finite_solution_with_amflow_desolver.wls`:
  independent local-series comparison for explicitly specified test boundary
  polynomials. Failure of diagonal epsilon rescaling remains unresolved in
  this optional comparison; it does not imply failure of the symbolic solver.

There are no family-name branches in these scripts or the evaluator.

```wl
Get["FeynFacet/Solution.m"];
data = FeynFacetSolution`ReadMasterIntegralSolution[solutionDirectory];
result = FeynFacetSolution`EvaluateMasterIntegralSolution[data, point,
  "InitialConstantValues" -> boundaryRules,
  "AccuracyGoal" -> 30, "PrecisionGoal" -> 30,
  "WorkingPrecision" -> 70];
```

`boundaryRules` uses labels such as ``FeynFacetSolution`C[j,n] -> value``.
Every constant used by the requested coefficients must be supplied. Omitted
orders are not assigned zero. Approximate zeros are assessed by absolute
accuracy. Without `InitialConstantValues`, numerical functions of the symbolic
constants are returned.

`CheckConvergence -> False` is explicitly labelled as an unchecked fixed-order
evaluation. Missing evolution entries remain `Missing["NotComputed"]`.

## Bugs fixed and validation

Numerical conversion previously changed integer boundary labels into floating
point labels, preventing substitution. Boundary labels and numerical master row
identifiers are now preserved. The physical comparison exercised both cases.

Validation passed:

- 18 focused numerical assertions, including logarithmic iterated integrals,
  subdivision, cancellation, insufficient input accuracy, singular paths,
  missing constants, time limits and preservation of identifiers;
- all 43 existing finite-solution assertions;
- driver checks rejecting wrong boundary points and insufficient reported
  AMFlow accuracy, plus re-export without an available AMFlow runtime;
- the two independent series comparisons and the physical CF3 comparison above.

Pro review was attempted, but the desktop bridge returned HTTP 403 and then
reported a missing composer before delivery. No Pro approval is claimed.

## Data

Numerical values, exact requests and comparison records are under
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/NumericalEvaluation_2026-09-06`.
Measurement records are under process Results/Validation. Retired source is
in the code backup; Kira workspaces are under the process Kira directory.

These checks establish useful high-precision evaluation on selected systems.
They do not establish numerical performance for all 91 families, all kinematic
regions, or independently known physical boundary constants for the whole
calculation. In the matched examples the local-series solver was faster than
the convergence-controlled quadrature; the latter directly tests the stored
symbolic expressions.

## Method references

- [AMFlow](https://arxiv.org/abs/2201.11669) and
  [AMFlow 2.0](https://arxiv.org/abs/2607.08477): auxiliary mass flow and the
  independent local-series reference implementation.
- [DiffExp](https://arxiv.org/abs/2006.05510): the established alternative of
  numerical evaluation through local series in kinematic variables.
