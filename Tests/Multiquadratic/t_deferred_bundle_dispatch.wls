#!/usr/bin/env wolframscript
(* A deferred bundle carries the nonzero forcing while the materialized
   BBar slot is only a zero shape placeholder.  The in-frame dispatcher must
   authenticate that bundle before zero-forcing and must include roots used
   only by its DAG in the canonical root census.  Chartless root sets retain
   the direct-provider boundary, while bundle presence alone must not suppress
   a chart.  This test exercises those cheap dispatch boundaries. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{forcingOf, validateBundle, currentRoots} = mq /@
  {"blockEquationDeferredForcing", "blockEquationDeferredBundleValidate",
   "transportChartCurrentRoots"};

Clear[dbx, dby, dbe, dbcx, dbcy];
variables = {dbx, dby};
epsilon = dbe;
rootSquares = {dbx, dby, 1 - dbx - dby};
rawFrame = BuildSquareRootGeneratorsAndQuadraticRelations[rootSquares, variables, {dbcx, dbcy}];
FTAssert["D0 the independent triple-root frame is exact",
  Lookup[rawFrame, "Status", None] === "ExactFrame" &&
    MissingQ[LookupCataloguedRationalizingParametrizationForRoots[rootSquares, variables]]];

(* Deliberately scramble the catalog declaration.  The bundle compiler and
   the solver both use the canonical square/root order, not this order. *)
permutation = {3, 1, 2};
permutedRoots = rawFrame["Roots"][[permutation]];
frame = Join[rawFrame, <|"Roots" -> permutedRoots,
  "Root" -> permutedRoots[[1, "Root"]],
  "RootSquare" -> permutedRoots[[1, "RootSquare"]]|>];
frameRoots = currentRoots[frame, variables];

(* Two one-by-one diagonal blocks.  Every radical occurs only in the lower
   off-diagonal forcing; the strip handed to the dispatcher below contains
   none of them because its BBar is the provider placeholder. *)
connection = {
  {{0, 0}, {frameRoots[[2, "Root"]] + frameRoots[[3, "Root"]], 0}},
  {{0, 0}, {frameRoots[[1, "Root"]], 0}}
};
ranges = {{1}, {2}};
bundle = forcingOf[connection, ranges, 2, 1, <||>, variables, epsilon,
  "Output" -> "Bundle", "BundleRoots" -> frameRoots];
FTAssert["D1 the nonzero forcing bundle is authenticated",
  Lookup[bundle, "Status", None] === "PreparedDeferredBundle" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid" &&
    AnyTrue[Lookup[bundle, "Jobs", {}],
      Lookup[#1, "Terms", {}] =!= {} &]];

zeroPair = {{{0}}, {{0}}};
placeholderStrip = {zeroPair, zeroPair, zeroPair};
dispatched = SolveEpsFormStripInFrame[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False,
  "MultiquadraticOptions" -> {"DeferredBundle" -> bundle},
  "Verbose" -> False];

FTAssert["D2 an authenticated deferred forcing cannot become ZeroForcing",
  Lookup[dispatched, "Method", None] =!= "ZeroForcing" &&
    Lookup[dispatched, "Status", None] === "NoRationalStripChart" &&
    Lookup[dispatched, "MultiquadraticDispatch", None] === "Disabled"];
FTAssert["D3 forcing-only roots join the canonical frame order",
  Lookup[dispatched, "RootIndices", None] === {2, 3, 1} &&
    Lookup[dispatched, "RootSquares", None] === rootSquares];

fakeChart = <|"Name" -> "MustNotConsumeAPlaceholder"|>;
forcedChart = Block[{LookupCataloguedRationalizingParametrizationForRoots = Function[{squares, vars}, fakeChart]},
  SolveEpsFormStripInFrame[placeholderStrip, variables, epsilon, frame,
    "MultiquadraticDispatch" -> False,
    "MultiquadraticOptions" -> {"DeferredBundle" -> bundle},
    "Verbose" -> False]];
FTAssert["D4 bundle presence no longer suppresses an available chart",
  Lookup[forcedChart, "Status", None] === "ChartNotWellFormed"];

ordinaryZero = SolveEpsFormStripInFrame[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False, "Verbose" -> False];
FTAssert["D5 a genuine zero strip without a bundle keeps the exact fast path",
  Lookup[ordinaryZero, "Status", None] === "Solved" &&
    Lookup[ordinaryZero, "Method", None] === "ZeroForcing"];

mutated = ReplacePart[bundle, {"Jobs", 1, "Terms"} -> {{2, {1}}}];
refused = SolveEpsFormStripInFrame[placeholderStrip, variables, epsilon,
  frame, "MultiquadraticDispatch" -> False,
  "MultiquadraticOptions" -> {"DeferredBundle" -> mutated},
  "Verbose" -> False];
FTAssert["D6 a stale or mutated bundle is refused before dispatch",
  Lookup[refused, "Status", None] === "InvalidDeferredBundle" &&
    Lookup[Lookup[refused, "Detail", <||>], "Status", None] ===
      "BundleFingerprintMismatch"];

FTSummary[];
