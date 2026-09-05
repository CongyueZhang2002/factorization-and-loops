# FeynFacet

FeynFacet is a Wolfram Language package for NNLO hadronic cross sections by
collinear factorization and reverse unitarity: process cards -> diagrams ->
cut-aware IBP reduction (Kira) -> master integrals from their differential
equations (epsilon form, solution along paths, boundary data) -> endpoint
expansion -> assembly of the hard function. The process enters only through
its cards; the current application is pp -> h X (`ppHX_NLO/`,
`ppHX_NNLO_DoubleReal/`).

Read first: `STATUS.md` (current state),
`Design/DifferentialEquationDataSchemaV2.md` (record formats and the
acceptance statement each record carries),
`Design/FinishedTransportContract_2026-09-03.md` (when a family counts as
solved).

## Layout

- `FeynFacet/` the package; `Private/<Layer>/` holds the modules in the
  order of `Private/LoadOrder.wl`; `Private_Backup/` is retired code,
  never loaded.
- `Scripts/` drivers and launchers; `Tests/` the tests; each has a README.
- `<process>/Cards/` process definitions; `<process>/Results/` generated
  mathematical data; `Stale/` pre-V2 data, evidence only, never an input.
- `Design/` method records; `Exchange/`, `Goals/` correspondence and goals.
- Scratch lives in the session scratchpad, never in the tree.
- `~/FACET` is the frozen legacy tree, read-only.

## Rules

1. A result is reported only when everything it depends on (inputs,
   transformations, certificates) is in the tree under `Results/` and is
   found by repository-relative path. Nothing that exists only in a
   scratchpad is a result.
2. Kill processes by verified PID only, never by name pattern.
3. Never edit a script that is running, and never rewrite a file a running
   loop reads; append to it.
4. A production campaign (multi-family batch, overnight run, hours of
   compute) starts only on the user's explicit go to a concrete proposal
   naming scope and cost. Small probes inside an assigned task need no go.
5. Cheap scale first. A run whose cost is out of proportion to its input
   is a defect: kill it and fix the cause, never wait it out.
6. Never save, rewrite or export a `.nb` programmatically or through a
   hidden FrontEnd. A notebook is edited only on the user's explicit
   request, from a backup, with every FrontEnd closed.

## Traps (each one cost real time)

- Regulator symbols differ per package (`eps`, `ep`, `Epsilon`,
  `CANONICA`eps`): normalize by `SymbolName` at every boundary, never by
  symbol identity.
- After LoadFACET a bare `Names` binds to the empty `FeynCalc`Names`
  shadow: write `System`Names` in scripts and tests.
- Packages dump symbols into `Global`` (asy, SubTropica's `line`,
  PolyLogTools).
- `Lookup[{}, key, default]` returns the default: check the container's
  head before `Lookup` on a possibly-empty list.
- `Return` inside `Do` discards results; `Module` initializers are not
  sequentially scoped; `Missing[] =!= None` in both directions.
- `Put` is not atomic: write to a temporary file and `RenameFile`.
- `Together` rationalizes square-root denominators and destroys
  algebraic-letter expressions.
- Libra `Projector` returns a zero matrix on Wolfram 14.2 unless
  `Off[OptionValue::optnf]` is set; `Fuchsify` only walks off-diagonal
  blocks.
- `wolframscript -file` on a missing path exits 0: a run with no printed
  tally is void, not passing.
- Libra's Fermat banner puts a raw 0xA9 byte in solve logs and the shell's
  `grep` skips binary streams silently: use `command grep -a`.
- Kernel start can hang on a paclet-server fetch; `$AllowInternet = False`
  is set in `~/.Wolfram/Kernel/init.m` for that reason.

## Language

Public names, documentation, reports, plans and exchange notes use standard
mathematics or amplitude terminology whenever a mathematical object exists.
Coding terms are confined to private implementation. Everything must be
readable by a physicist without knowledge of the implementation.

Rules:

1. One name per concept, fixed at first use and anchored to the literature;
   the same name in code, chat, plans, artifacts and agent briefs.
2. Never physics vocabulary for scheduling or software concepts; no
   metaphors in status reports: state the mechanism or the measured number.
3. Never a stronger mathematical term than the code establishes: epsilon
   factorization is not dlog epsilon form; a parametrization is not a
   birational change of variables; a sign-change image is not a Galois
   conjugate.
4. A coding-only object gets a literal implementation name saying what it
   stores or does, not an invented mathematical noun.
5. Call an executed calculation a test and report its measured result;
   state the acceptance criterion before saying it passed, otherwise
   report the observed values without "pass". "Regression test" only for a
   repetition of an established test after a code change. Every number is
   marked measured or estimated.

Banned words (word -> replacement): arm -> start; blocker -> the thing
stopping X; cut, channel, current, propagate (operational) -> literal
description; drain -> finish; fire -> starts; gate -> check or test; goal
state -> the stated property has been verified; green, red -> passing,
failing; in flight -> running; land, ship -> finished; lever -> option or
change; meticulous -> drop it; post-mortem -> record of what happened;
phase (operational) -> stage, batch, step; port -> carrying over;
spawn -> start; suite -> test; wall (metaphor) -> the measured limit;
wave -> batch.

Distinctions names must preserve:

- `BasisTransformationMatrix` is a complete invertible change of
  master-integral basis; a rectangular subblock is an
  `OffDiagonalBasisTransformationBlock`, never a gauge.
- `EpsilonFactorizedSystem`: the connection is proportional to epsilon.
  `DLogEpsilonForm` additionally has constant matrices multiplying dlog
  one-forms. A system with only epsilon-form diagonal blocks is described
  exactly that way, not as a whole-family epsilon form. "Passed the exact
  dlog epsilon-form check" means the transformed connection equals
  `epsilon Sum_a R_a dlog(phi_a)` in both variables with constant `R_a`.
- `RationalizingParametrization` does not imply a rational inverse.
  `MultiquadraticFunctionFieldPresentation` and `GaloisConjugates` require
  proven square-class independence; otherwise
  `SquareRootGeneratorsAndQuadraticRelations` and
  `SquareRootSignChangeImages`.
- A candidate matrix of homogeneous solutions is accepted only after its
  differential equation is validated; the public phrase is
  `MatrixOfHomogeneousSolutions`.
- `LocalExpansionPoint` is classified `OrdinaryPoint` or
  `RegularSingularPoint`; a normal-residue eigenbasis is not a Levelt
  basis unless the general Jordan/logarithmic construction is present.
- `BoundaryConstantID`, `BoundaryFunctionID`, `FrobeniusModeID`,
  `BoundaryIntegralID` and relations among them are distinct objects;
  `BoundaryData` only as the standard collective term; no generic
  "period" in the live API.
- `FormalChenIteratedIntegral`, `IteratedIntegralLetterSequence`,
  `IteratedIntegralIndexSequence` according to the stored object; a product
  of integrals over path segments is not one integral over the
  concatenated path unless Chen's deconcatenation is implemented.
- `Materialize` only privately, for converting a lazy representation to an
  explicit one; never `Manifest` for a mathematical object.

Fixed descriptions: "constructing the off-diagonal basis-transformation
blocks" (completing a block-triangular transformation); "diagonal-block
epsilon forms" (stage-1 per-class results); "solving the differential
equations along a path" (stage 2); "couplings" or Lee's "off-diagonal
blocks" for `B_ij`; "diagonal block" = irreducible diagonal subsystem,
"off-diagonal connection block (k,j)" = its coupling into lower block `j`;
"single-root, two-root, triple-root batch"; "strip", "sector", "chart",
"frame", "word", "gauge" (for a basis change) and unqualified "block" are
retired from public prose and public names.
