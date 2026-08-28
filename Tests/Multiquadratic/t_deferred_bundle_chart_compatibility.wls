#!/usr/bin/env wolframscript
(* Active-subfield pruning can leave a deferred forcing rational or
   chartable even though its family frame is multiquadratic.  The bundle is
   the real forcing while the Strip BBar slot is a zero shape placeholder.
   These cases must reconstruct/pull the bundle before the rational solver;
   only a root set without a joint chart belongs to the direct MQ engine. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{forcingOf, validateBundle, currentRoots, pullBundle, bundleEvaluate,
  directAlphabet, chartRekey, chartData} = mq /@ {
  "blockEquationDeferredForcing", "blockEquationDeferredBundleValidate",
  "transportChartCurrentRoots", "transportChartPullBackDeferredBundle",
  "blockEquationDeferredBundleEvaluate",
  "familyRowGaugeDirectAlphabetOptions", "transportChartRekey",
  "masterTransportChartData"};

Clear[cbx, cby, cbe, cbfx, cbfy, cbtx, cbty];
variables = {cbx, cby};
epsilon = cbe;
zeroPair = {{{0}}, {{0}}};
placeholderStrip = {zeroPair, zeroPair, zeroPair};
ranges = {{1}, {2}};

(* Root-free forcing inside a larger declared frame. *)
declaredSquares = {cbx, cby, 1 - cbx - cby};
declaredFrame = BuildAlgebraicTransportFrame[
  declaredSquares, variables, {cbfx, cbfy}];
declaredRoots = currentRoots[declaredFrame, variables];
rationalConnection = {
  {{0, 0}, {1, 0}},
  {{0, 0}, {0, 0}}
};
rationalBundle = forcingOf[rationalConnection, ranges, 2, 1, <||>,
  variables, epsilon, "Output" -> "Bundle",
  "BundleRoots" -> declaredRoots];
FTAssert["C1 root-free forcing compiles to an authenticated empty frame",
  Lookup[validateBundle[rationalBundle], "Status", None] === "BundleValid" &&
    rationalBundle["RootFrame", "Roots"] === {} &&
    rationalBundle["Statistics", "PrunedRootCount"] === 3];
FTAssert["C2 an empty divisor census yields the neutral direct alphabet payload",
  directAlphabet[rationalBundle] === <|
    "AdditionalLetters" -> {}, "AlgebraicLetters" -> Automatic|>];
identityData = <|"Status" -> "OK", "Variables" -> variables,
  "SourceVariables" -> variables,
  "Subst" -> Thread[variables -> variables],
  "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1|>;
rationalPull = pullBundle[rationalBundle, identityData, {}, {}];
FTAssert["C3 the root-free deferred forcing is reconstructed, not the placeholder",
  Lookup[rationalPull, "Status", None] === "OK" &&
    rationalPull["OneForm"] === {{{1}}, {{0}}}];

(* A one-root forcing whose exact Kallen chart is in the catalog. *)
lambda = (1 - cbx - cby)^2 - 4 cbx cby;
oneFrame = BuildAlgebraicTransportFrame[{lambda}, variables, {cbfx, cbfy}];
oneRoots = currentRoots[oneFrame, variables];
oneRoot = oneRoots[[1, "Root"]];
oneConnection = {
  {{0, 0}, {D[oneRoot, cbx], 0}},
  {{0, 0}, {D[oneRoot, cby], 0}}
};
oneBundle = forcingOf[oneConnection, ranges, 2, 1, <||>, variables,
  epsilon, "Output" -> "Bundle", "BundleRoots" -> oneRoots];
FTAssert["C4 one-root forcing retains exactly one active generator",
  Lookup[validateBundle[oneBundle], "Status", None] === "BundleValid" &&
    Length[oneBundle["RootFrame", "Roots"]] === 1];
chart = TransportRootSetChart[{lambda}, variables];
FTAssert["C5 the active one-root set has the registered Kallen1 chart",
  AssociationQ[chart] && chart["Name"] === "Kallen1"];
chartVariables = {cbtx, cbty};
rekeyed = chartRekey[chart, variables, chartVariables];
data = chartData[rekeyed, variables];
chartRoot = SelectFirst[rekeyed["Roots"],
  TrueQ[Together[#1["RootSquare"] - lambda] === 0] &];
branchRoots = {<|"RootSquare" -> Together[lambda /. data["Subst"]]|>};
rootImages = {chartRoot["Root"]};
onePull = pullBundle[oneBundle, data, branchRoots, rootImages];
materialized = bundleEvaluate[oneBundle, {}];
referencePull = mq["transportChartPullBackStrip"][
  {zeroPair, zeroPair, materialized["Image"]}, data,
  branchRoots, rootImages][[3]];
FTAssert["C6 operandwise bundle pullback equals materialize-then-pullback exactly",
  Lookup[onePull, "Status", None] === "OK" &&
    onePull["OneForm"] === referencePull &&
    onePull["OperandEvaluations"] === Length[oneBundle["OperandTable"]]];

artifactRoot = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "FeynFacet-deferred-chart-compat-" <> CreateUUID[]}]];
commonFiniteOptions[prefix_String] := {
  "KernelCount" -> 1,
  "ArtifactDirectory" -> FileNameJoin[{artifactRoot, prefix}],
  "ArtifactPrefix" -> prefix,
  "Backend" -> "Wolfram", "BackendThreads" -> 1,
  "PlanDiscoveryBackend" -> "Wolfram",
  "FinalCheck" -> "Exact", "Verbose" -> False};
rationalSolution = SolveEpsFormStripInFrame[
  placeholderStrip, variables, epsilon, declaredFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["root_free"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> rationalBundle},
  "Verbose" -> False];
FTAssert["C7 root-free bundle dispatch solves the reconstructed rational forcing",
  Lookup[rationalSolution, "Status", None] === "Solved" &&
    StringStartsQ[rationalSolution["Method"], "RationalFrame/"] &&
    rationalSolution["RootIndices"] === {} &&
    TrueQ[rationalSolution["ExactDLog"]]];
oneSolution = SolveEpsFormStripInFrame[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> oneBundle},
  "Verbose" -> False];
FTAssert["C8 chartable deferred forcing uses the rational chart and solves exactly",
  Lookup[oneSolution, "Status", None] === "Solved" &&
    StringStartsQ[oneSolution["Method"], "RationalChart/Kallen1/"] &&
    oneSolution["RootIndices"] === {1} &&
    TrueQ[oneSolution["ExactDLog"]] &&
    TrueQ[oneSolution["FrameCertificate", "SourceDLog"]]];

plainRationalSolution = SolveEpsFormStripInFrame[
  {zeroPair, zeroPair, {{{1}}, {{0}}}}, variables, epsilon, declaredFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["plain_rational"],
  "Verbose" -> False];
FTAssert["C9 an ordinary nonzero rational strip still uses RationalFrame",
  Lookup[plainRationalSolution, "Status", None] === "Solved" &&
    StringStartsQ[plainRationalSolution["Method"], "RationalFrame/"] &&
    plainRationalSolution["RootIndices"] === {} &&
    TrueQ[plainRationalSolution["ExactDLog"]]];

(* A chartless full-rank bundle remains on the direct-provider contract;
   the existing t_deferred_bundle_dispatch covers that disabled boundary. *)
FTSummary[];
