#!/usr/bin/env wolframscript
(* A deferred bundle carries the nonzero inhomogeneity while the materialized
   Inhomogeneity slot is only a zero shape placeholder.  The in-frame dispatcher must
   authenticate that bundle before zero-inhomogeneity and must include roots used
   only by its DAG in the canonical root census.  Chartless root sets retain
   the direct-provider boundary, while bundle presence alone must not suppress
   a chart.  This test exercises those cheap dispatch boundaries. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{inhomogeneityOf, validateBundle, currentRoots} = mq /@
  {"blockEquationDeferredInhomogeneity", "blockEquationDeferredBundleValidate",
   "coefficientPresentationSquareRootsInVariables"};

Clear[dbx, dby, dbe, dbcx, dbcy];
sourceVariables = {dbx, dby};
variables = {dbcx, dbcy};
epsilon = dbe;
sourceRootSquares = {dbx, dby, 1 - dbx - dby};
rootSquares = {dbcx, dbcy, 1 - dbcx - dbcy};
rawFrame = BuildSquareRootGeneratorsAndQuadraticRelations[
  sourceRootSquares, sourceVariables, variables];
FTAssert["D0 the independent triple-root frame is exact",
  Lookup[rawFrame, "Status", None] ===
      "SquareRootGeneratorRelationsVerified" &&
    MissingQ[LookupCataloguedRationalizingParametrizationForRoots[
      sourceRootSquares, sourceVariables]]];

(* Deliberately scramble the catalog declaration.  The bundle compiler and
   the solver both use the canonical square/root order, not this order. *)
permutation = {3, 1, 2};
permutedRoots = rawFrame["SquareRootGenerators"][[permutation]];
frame = Join[rawFrame, <|"SquareRootGenerators" -> permutedRoots|>];
frameRoots = currentRoots[frame, variables];

(* Two one-by-one diagonal blocks.  Every radical occurs only in the lower
   off-diagonal inhomogeneity; the strip handed to the dispatcher below contains
   none of them because its Inhomogeneity is the provider placeholder. *)
connection = {
  {{0, 0}, {frameRoots[[2, "Generator"]] + frameRoots[[3, "Generator"]], 0}},
  {{0, 0}, {frameRoots[[1, "Generator"]], 0}}
};
ranges = {{1}, {2}};
bundle = inhomogeneityOf[connection, ranges, 2, 1, <||>, variables, epsilon,
  "Output" -> "Bundle", "BundleRoots" -> frameRoots];
FTAssert["D1 the nonzero inhomogeneity bundle is authenticated",
  Lookup[bundle, "Status", None] === "PreparedDeferredBundle" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid" &&
    AnyTrue[Lookup[bundle, "Jobs", {}],
      Lookup[#1, "Terms", {}] =!= {} &]];

zeroPair = {{{0}}, {{0}}};
placeholderStrip = {zeroPair, zeroPair, zeroPair};
dispatched = SolveOffDiagonalBasisTransformationBlock[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False,
  "MultiquadraticOptions" -> {"DeferredBundle" -> bundle},
  "Verbose" -> False];

FTAssert["D2 an authenticated deferred inhomogeneity cannot become ZeroInhomogeneity",
  Lookup[dispatched, "Method", None] =!= "ZeroInhomogeneity" &&
    Lookup[dispatched, "Status", None] ===
      "NoCataloguedRationalizingParametrization" &&
    Lookup[dispatched, "MultiquadraticDispatch", None] === "Disabled"];
FTAssert["D3 inhomogeneity-only roots use the declared generator order",
  Lookup[dispatched, "SquareRootGeneratorIndices", None] === {1, 2, 3}];

fakeChart = <|"Name" -> "MustNotConsumeAPlaceholder"|>;
forcedChart = Block[{LookupCataloguedRationalizingParametrizationForRoots = Function[{squares, vars}, fakeChart]},
  SolveOffDiagonalBasisTransformationBlock[placeholderStrip, variables, epsilon, frame,
    "MultiquadraticDispatch" -> False,
    "MultiquadraticOptions" -> {"DeferredBundle" -> bundle},
    "Verbose" -> False]];
FTAssert["D4 bundle presence no longer suppresses an available chart",
  Lookup[forcedChart, "Status", None] ===
    "CoefficientPresentationNotWellFormed"];

ordinaryZero = SolveOffDiagonalBasisTransformationBlock[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False, "Verbose" -> False];
FTAssert["D5 a genuine zero strip without a bundle keeps the exact fast path",
  Lookup[ordinaryZero, "Status", None] === "Solved" &&
    Lookup[ordinaryZero, "Method", None] === "ZeroInhomogeneity"];

mutated = ReplacePart[bundle, {"OperandTable", 1, "RootMask"} ->
  Mod[bundle["OperandTable", 1, "RootMask"] + 1, 2^Length[frameRoots]]];
refused = SolveOffDiagonalBasisTransformationBlock[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False,
  "MultiquadraticOptions" -> {"DeferredBundle" -> mutated},
  "Verbose" -> False];
FTAssert["D6 a stale or mutated bundle is refused before dispatch",
  Lookup[refused, "Status", None] === "InvalidDeferredBundle" &&
    Lookup[Lookup[refused, "Detail", <||>], "Status", None] ===
      "OperandRootMaskMismatch"];

FTSummary[];
