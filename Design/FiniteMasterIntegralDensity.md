# Finite physical interior density

`AssembleFiniteMasterIntegralDensity[physicalTable, solutions, request]`
contracts a physical-master coefficient table with existing finite master
solutions. It returns the complete interior coefficients through the requested
epsilon order, with one finite set of scalar algebraic, kernel and integral
definitions. It does not perform an endpoint expansion or replace the interior
remainder by a local Taylor polynomial.

The coefficient table must have
`PhysicalMasterNormalizationApplied -> True` and
`CoefficientConvention -> "PhysicalMasterAtReferenceScale"`, as returned by
`ConstructPhysicalMasterCoefficientDensity`. All scalar terms and analytic
normalizations are retained. The epsilon-independent part of the table's
global prefactor is factored out of the scalar coefficient functions and
included once in each final density coefficient. Coefficient functions must
be explicit expressions. Unscoped `a`, `F`, `K`, `B`, or `C` references from the solution context in
the coefficient table are rejected; their finite definitions belong in the
supplied solution records.

`solutions` is an association from distinct string labels to saved solution
directories, solution WXF files, or explicit `MasterIntegralSolution` records.
Every selected record must declare physical boundary completeness for its
stored orders, `RequestedMasterIntegralOrderRanges`,
`OriginalMasterIntegralBasis`, `MasterIntegralCoefficients`, and the finite
`AlgebraicDefinitions`, `IntegralDefinitions`, `KernelDefinitions` lists.
For an in-memory record with a relative `SharedBoundaryDefinitionFile`, also
supply `SourceDirectory`. A fully resolved record needs no shared file.

The request is:

```wolfram
<|"ThroughOrder" -> 0,
  "KinematicVariables" -> {v,w},
  "SolutionReferenceScale" -> 1|>
```

The reference scale must equal the physical table's declared reference scale.
This request asserts the scale of the supplied physical solution data; it
does not rescale those solutions. Every solution must use the same declared
kinematic coordinates. Its analytic domain, integration path and branch
prescription remain explicit in the output. Equality is asserted on their
common valid domain; no new analytic continuation is constructed.

For each master, the planner uses the transported Laurent lower bound from
its stored order range and the actual coefficient/prefactor Laurent bound.
For target `q`, master coefficients are needed through `q - coefficientBound`
and coefficient functions through `q - masterBound`. Finite coefficient tails
also include a sufficient prefactor Laurent lower bound. The common
`DetermineMeromorphicLaurentLowerBound` helper in `LaurentBounds.wl` uses exact
polynomial exponents, structural sum/product bounds and established denominator
valuations. Exponents of analytic powers are normalized algebraically first. Missing master coefficients and
insufficient finite coefficient ranges are reported together in
`Failure["FiniteDensityOrdersInsufficient", ...]`; they are never zero filled.
Bounds are conservative if the supplied expressions have unproved cancellations.

Finite coefficient materialization delegates to the common
`ExpandMasterIntegralCoefficient` implementation. Its exact coefficient-field
substitution keeps epsilon-independent rational expressions factored during
series arithmetic; every temporary symbol is restored in the finite output.

Only required master coefficients and their finite definition closure are
selected. Shared physical boundary files are pruned and installed once, even
when many families refer to them. Each finite boundary coefficient becomes a
shared algebraic definition. Family-local solution-context `a`, `F`, and `K`
indices are shifted into disjoint global ranges; their integration parameters
remain bound in their own definitions. Explicit master coefficients are then
stored once as algebraic definitions and reused in every density order.
All required initial constants and boundary references must resolve, and the
combined definition lists must remain in dependency order.

The output contains:

- `Coefficients`: every scalar density coefficient in `EpsilonOrderRange`.
- `Expression`: their explicit finite Laurent sum.
- `MasterCoefficientVector` and `MasterCoefficientIndex`: the finite master
  coefficients and their identity, solution, row, and epsilon-order labels.
- `CoefficientFunctionIndex` and `CoefficientConvolutionMatrices`: explicit
  finite coefficient functions and sparse rows contracting the master vector.
- `AlgebraicDefinitions`, `IntegralDefinitions`, `KernelDefinitions`, and
  `DefinitionScopes`: the complete finite scalar definitions and source scopes.
- `MasterOrderRequirements`: the separate master and coefficient upper demands.
- The physical density normalization and original solution domain conventions.

`EndpointSubtractionsApplied -> False` is deliberate. The later regular
coefficient is this full interior coefficient minus the expanded singular
density for positive normal coordinate. Endpoint delta and plus terms must be
obtained from the retained regulated endpoint modes, with their own deeper
local epsilon demands. No total NNLO or observed-variable cross-section
coverage is inferred.

Run the general command with a Wolfram request file containing
`PhysicalCoefficientTable`, `FiniteSolutions`, and `Request`:

```sh
wolframscript -file Scripts/Coefficients/assemble_finite_master_density.wls \
  REQUEST.wl OUTPUT.wxf
```

Paths in the request may be relative to its directory. Success writes the
complete result, a lightweight `.index.wxf` with master/row/order references,
and a JSON count report. Insufficient inputs write `.failure.wxf` with the exact
missing demands and exit nonzero. Serialization is checked before replacing
the named output.

The CLI also writes complete per-master finite coefficient functions under
`OUTPUT.wxf.coefficients/`. It resumes these files on repeated requests.
Files have readable master/range names and numbered versions. Each stores its
weighted input entry, regulator and requested range for exact equality checks
before reuse. Changed coefficients or
order requests therefore receive separate files. These are reusable finite
functions; the consolidated result remains self-contained. The request file
may set `CoefficientFunctionDirectory` to a different path or `None` to disable
them. Direct API callers use the option of the same name, defaulting to `None`.

Serialization compares every ordinary field with exact `SameQ`. The
`CoefficientConvolutionMatrices` field is compared row by row with exact
`SameQ` after extracting each sparse row: Wolfram associations can otherwise
hold sparse objects in different internal evaluation states across WXF
restoration. The exception does not permit changed coefficient or row values.
