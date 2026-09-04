# Scientific language rules

Public package names, documentation, status reports, plans, and exchange
summaries must use standard mathematics or amplitude terminology whenever a
mathematical object exists.  Coding terms are restricted to private
implementation details.  Everything must be readable by a physicist without
requiring knowledge of the package implementation.

## Rules

1. One name per concept, fixed at first use and anchored to the literature;
   use the same name in code, chat, plans, artifacts, and agent briefs.
2. Never use physics-domain vocabulary for scheduling/software concepts.
3. No metaphors in status reports: state the literal mechanism or the
   measured number.
4. Do not use a stronger mathematical term than the code establishes.  In
   particular, distinguish epsilon factorization from dlog epsilon form,
   parametrizations from birational coordinate changes, and sign-change
   images from Galois conjugates.
5. A genuinely coding-only object gets a literal implementation name that
   states what it stores or does.  Do not invent an abstract mathematical
   noun for it.

## Banned-word library (word → replacement)

- arm → start
- blocker → the thing stopping X
- cut / channel / current / propagate (operational use) → literal description
- drain → finish
- fire (a job fires) → starts
- gate → check/test
- goal state → the stated mathematical property has been verified
- green / red → passing / failing
- in flight → running
- land / ship → finished
- lever → option / change
- meticulous → no need for meaningless adjective
- mortem / post-mortem → record of the terminated run / what happened
- phase (operational use) → stage, batch, step
- port → carrying over
- spawn → start
- suite → test
- wall (metaphor) → the measured limit
- wave → batch

## Mathematical distinctions that names must preserve

- `BasisTransformationMatrix` is a complete invertible change of master-
  integral basis.  A rectangular subblock is an
  `OffDiagonalBasisTransformationBlock`, not a gauge.
- `EpsilonFactorizedSystem` means that the connection is proportional to
  epsilon.  `DLogEpsilonForm` additionally requires constant matrices
  multiplying dlog one-forms.  A system with only epsilon-form diagonal
  blocks is described exactly that way; it is not a whole-family epsilon
  form.
- "passed the exact dlog epsilon-form check" means that transformation by
  the accepted basis-transformation matrix gives
  `epsilon Sum_a R_a dlog(phi_a)` in both variables with constant `R_a`.
- `RationalizingParametrization` does not imply a rational inverse.
  `MultiquadraticFunctionFieldPresentation` and `GaloisConjugates` require a
  proof of square-class independence; otherwise use
  `SquareRootGeneratorsAndQuadraticRelations` and
  `SquareRootSignChangeImages`.
- A candidate matrix of homogeneous solutions is not an accepted matrix of
  homogeneous solutions until its differential equation has been validated.
- `LocalExpansionPoint` is classified separately as `OrdinaryPoint` or
  `RegularSingularPoint`.  A normal-residue eigenbasis is not called a Levelt
  basis unless the general Jordan/logarithmic Levelt construction is present.
- Distinguish `BoundaryConstantID`, `BoundaryFunctionID`, `FrobeniusModeID`,
  `BoundaryIntegralID`, and relations among them.  `BoundaryData` is allowed
  only as the standard collective differential-equation term.
- Use `FormalChenIteratedIntegral`, `IteratedIntegralLetterSequence`, and
  `IteratedIntegralIndexSequence` according to the stored object.  A product
  of integrals over path segments is not one integral over the concatenated
  path unless Chen's deconcatenation sum has been implemented.
- `MatrixOfHomogeneousSolutions` is the public phrase for a complete square
  nonsingular solution matrix of the homogeneous differential system.
- `Materialize` is allowed only for a private conversion from a lazy coding
  representation to an explicit one.  Do not use `Manifest` for a
  mathematical object.

## Fixed project descriptions

- "constructing the off-diagonal basis-transformation blocks" for completing
  a block-triangular basis transformation
- "diagonal-block epsilon forms" for the stage-1 per-class results;
  "solving the differential equations along a path" for transport;
  "couplings" or Lee's "off-diagonal blocks" for `B_ij`
- "single-root batch / two-root batch / triple-root batch" (not
  phase 1/2/3); no term for transitions — "when the single-root batch
  finishes"
- "diagonal block" = irreducible diagonal subsystem (stage-1 unit);
  "off-diagonal connection block (k,j)" = its coupling into the lower
  diagonal block `j`; "strip", "sector", and unqualified "block" are retired
  from public prose
