# Boundary data

`reduce_master_integral_boundaries.wls INPUT.wl OUTPUT_DIRECTORY` applies the
general boundary-reduction pipeline to fresh family-local finite solutions.

The input supplies a campaign directory, canonical topology registry, reduction
manifest, integral normalization, boundary coordinate map, boundary kinematics
and an exact rational observation point. The driver contains no process or
family selection.

It writes the shared DE, the exact requested closure, integral identities,
physical boundary dimension bound and actual Laurent requirements. By default,
new solutions are written below the output directory; `ReplaceSourceSolutions`
requests atomic replacement of the campaign's source files.

The first driver applies ordinary-point sharing. The subsequent driver

    wolframscript -file Scripts/Boundary/match_singular_boundaries.wls INPUT.wxf OUTPUT_DIRECTORY

materializes singular-boundary substitutions and validates every family before
writing replacements. ReplaceSourceSolutions -> True requests replacement;
otherwise solutions are written below the supplied output directory.

The input supplies GlobalDifferentialSystem, RequestedDifferentialSystem,
NormalDifferentialSystem (or PreparedBoundarySystem), BoundarySeed with Basis
and a regular LeftInverse, OriginalMasterLaurentLowerBounds,
UnknownAmplitudeDefinitions, NormalCoordinates, SolutionFiles and
BranchPrescription. NormalCoordinates maps each family base point to its
coordinate on the declared one-variable normal path.

Optional exact inputs: KnownAmplitudeExpressions, KnownOriginalMasterExpressions
(indexed by requested-global-system row), AmplitudeLaurentLowerBounds, and
BoundaryAmplitudeOrders containing MatrixEntryLaurentLowerBounds.
Cores accepts 1 through 8. BoundaryConnection can reuse a completed finite
connection; it is checked for sufficient epsilon orders.

Physical mode selection and known normalization are process data. The package
implements general preparation, saturation, order determination, finite
connection construction and same-point embedding. The output is explicit
finite mathematical data. A reproduction input for the current process is
in Results/BoundaryValues/SingularMatching_2026-09-07.

The numerical singular endpoint uses Frobenius initialization and compiled
Taylor continuation. The shared evaluator propagates actual demands through
the seed, connection and gauge, and compares two matching-point calculations
after returning to the original master basis.

## Physical boundary commands

Each command accepts one WXF input specification. Outputs belong inside the
process Results directory.

- construct_physical_boundary_relations.wls: original integral definitions,
  singular construction input and a primary expansion/request. Constructs
  physical coefficients, extends the normal jet and matches powers/logarithms.
- determine_boundary_amplitudes.wls: selects independent established physical
  coefficient equations, derives sufficient orders after elimination and
  evaluates missing values. Seed-to-amplitude maps are explicit matrices;
  cached values must match their integral definitions.
- evaluate_boundary_integrals.wls: a bounded amplitude plan, selected input
  indices and output/scratch directories. Evaluates actual Euler integrals
  only through sufficient orders. Independent workers write separate files.
- assemble_evaluated_boundary_amplitudes.wls: attaches evaluated coefficient
  files to the exact reduction and checks definition/order coverage.
- apply_amplitude_relations.wls: substitutes finite Laurent relations,
  preserves lower bounds and updates family links/demands. Uses compressed WXF
  and atomic replacement when requested.
- evaluate_boundary_values.wls: shared definitions, singular numerical
  construction and supplied free-amplitude coefficients. Writes numerical
  ordinary-point boundary coefficients for the standalone reader.

Use CPU affinity for concurrent Wolfram jobs: native threads may exceed OMP
settings. Assign CPUs 0-3 and 4-7 to two workers with taskset, for example.
The total allowed budget is eight cores.

Current process inputs and values are in
Results/BoundaryValues/OvernightEvaluation_2026-09-07. A missing full-expression
marker means the explicit finite Laurent coefficient map must be used.
Omitted coefficients are never zero.

The completed reproduction input is `general_boundary_determination_input.wxf`
in the current process boundary result directory. Apply its output with
`general_physical_boundary_application_input.wxf`. The files require no free
constants. Normal numerical evaluation selects Frobenius initialization
automatically; the explicit boundary driver remains useful for caching.

`IntegrateEulerBoundaryIntegral` automatically uses classical-PL/digamma
formulas for supported cluster profiles. Forcing `SubTropica` remains an
independent integration route. Physical-limit proofs remain separate from
the integration backend.

The separate stage-3 and complete-master validation drivers are documented in
[../Validation/README.md](../Validation/README.md).
