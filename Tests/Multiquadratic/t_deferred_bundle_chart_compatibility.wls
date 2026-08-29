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
{forcingOf, prepareDeferred, chartDecision, validateBundle, currentRoots,
  pullBundle, bundleEvaluate, directAlphabet, chartRekey, chartData} = mq /@ {
  "blockEquationDeferredForcing", "blockEquationDeferredPrepare",
  "blockEquationDeferredChartDecision",
  "blockEquationDeferredBundleValidate",
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

oneMaterialized = forcingOf[oneConnection, ranges, 2, 1, <||>, variables,
  epsilon, "Output" -> "BundleAndMaterialized",
  "BundleRoots" -> oneRoots];
oneChartFast = forcingOf[oneConnection, ranges, 2, 1, <||>, variables,
  epsilon, "Output" -> "ChartOrBundle", "BundleRoots" -> oneRoots];
oneChartPreparation = <|
  "Preparation" -> oneChartFast["DeferredPreparation"],
  "RootSquares" -> oneChartFast["ChartDecision", "RootSquares"]|>;
FTAssert["C9 chart-aware production bypasses provider compilation and \
source-frame materialization",
  Lookup[oneChartFast, "Status", None] === "PreparedChartDeferred" &&
    ! KeyExistsQ[oneChartFast, "DeferredBundle"] &&
    ! KeyExistsQ[oneChartFast, "Forcing"] &&
    Lookup[oneChartFast["Census"], "Status", None] ===
      "SkippedForChart" &&
    TrueQ[oneChartFast["ChartDecision", "ChartAvailableQ"]]];
oneChartFastSolution = SolveEpsFormStripInFrame[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root_preparation"],
  "DeferredPreparation" -> oneChartPreparation,
  "Verbose" -> False];
FTAssert["C10 deferred preparation materializes in the chart and gives the \
same exact gauge",
  Lookup[oneChartFastSolution, "Status", None] === "Solved" &&
    StringStartsQ[oneChartFastSolution["Method"],
      "RationalChart/Kallen1/"] &&
    AllTrue[Flatten[oneChartFastSolution["Gauge"] - oneSolution["Gauge"]],
      TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[#1,
        oneRoots]] &]];
ambiguousDeferredSolution = SolveEpsFormStripInFrame[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["ambiguous_deferred"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> oneBundle},
  "DeferredPreparation" -> oneChartPreparation,
  "Verbose" -> False];
FTAssert["C10b simultaneous bundle and preparation are refused before solve",
  Lookup[ambiguousDeferredSolution, "Status", None] ===
    "AmbiguousDeferredForcing"];

(* Cancellation can make the assembled source live in a strict subfield even
   when its raw DAG operands mention the full declared frame.  The route-only
   all-sheet census must see the assembled grades before provider compilation. *)
kallenSquares = {
  (1 - cbx - cby)^2 - 4 cbx cby,
  (1 + cbx - cby)^2 + 4 cbx cby,
  (1 - cbx + cby)^2 + 4 cbx cby};
kallenFrame = BuildAlgebraicTransportFrame[
  kallenSquares, variables, {cbfx, cbfy}];
kallenRoots = currentRoots[kallenFrame, variables];
kallenRootExpressions = Lookup[kallenRoots, "Root"];
cancelConnection = {
  {{0, 0, 0},
   {kallenRootExpressions[[2]] + kallenRootExpressions[[3]], 0, 0},
   {Total[kallenRootExpressions], 0, 0}},
  ConstantArray[0, {3, 3}]};
cancelSolved = <|2 -> {{1}}|>;
cancelChartFast = forcingOf[cancelConnection, {{1}, {2}, {3}}, 3, 1,
  cancelSolved, variables, epsilon, "Output" -> "ChartOrBundle",
  "BundleRoots" -> kallenRoots];
FTAssert["C10c an assembled one-root forcing bypasses a syntactic three-root provider",
  Lookup[cancelChartFast, "Status", None] === "PreparedChartDeferred" &&
    Lookup[cancelChartFast["ChartDecision"], "Method", None] ===
      "ModularActiveGrades" &&
    MissingQ[Lookup[cancelChartFast["ChartDecision"],
      "SyntacticRootIndices", None]] &&
    Lookup[cancelChartFast["ChartDecision", "ActiveGradeCensus"],
      "DirectPlaceholderCount", 0] > 0 &&
    Lookup[cancelChartFast["ChartDecision", "ActiveGradeCensus"],
      "CanonicalizedPlaceholderCount", -1] === 0 &&
    Length[cancelChartFast["ChartDecision", "RootSquares"]] === 1 &&
    TrueQ[Together[First[cancelChartFast["ChartDecision", "RootSquares"]] -
      kallenSquares[[1]]] === 0] &&
    cancelChartFast["ChartDecision", "Chart"] === "Kallen1"];

unsupportedConnection = ReplacePart[cancelConnection,
  {1, 3, 1} -> Sin[cbx] Total[kallenRootExpressions]];
inactiveDenominator = 1/(1 + kallenRootExpressions[[2]]) +
  1/(1 + kallenRootExpressions[[3]]);
denominatorConnection = ReplacePart[cancelConnection, {
  {1, 2, 1} -> inactiveDenominator,
  {1, 3, 1} -> kallenRootExpressions[[1]] + inactiveDenominator}];
denominatorPreparation = prepareDeferred[denominatorConnection,
  {{1}, {2}, {3}}, 3, 1, cancelSolved, variables, epsilon];
denominatorDecision = chartDecision[denominatorConnection,
  denominatorPreparation, kallenRoots];
FTAssert["C10d a canceled inactive algebraic denominator stays direct",
  Lookup[denominatorDecision, "Status", None] === "OK" &&
    ! TrueQ[denominatorDecision["ChartAvailableQ"]] &&
    Lookup[denominatorDecision, "Method", None] ===
      "ModularDeclaredFrame" &&
    Lookup[denominatorDecision["ActiveGradeCensus"], "Status", None] ===
      "ActiveGradeCensus"];

unsupportedPreparation = prepareDeferred[unsupportedConnection,
  {{1}, {2}, {3}}, 3, 1, cancelSolved, variables, epsilon];
unsupportedDecision = chartDecision[unsupportedConnection,
  unsupportedPreparation, kallenRoots];
FTAssert["C10e an inconclusive active-grade census stays on the direct route",
  Lookup[unsupportedDecision, "Status", None] === "OK" &&
    ! TrueQ[unsupportedDecision["ChartAvailableQ"]] &&
    Lookup[unsupportedDecision, "Method", None] === "SyntacticRootUnion" &&
    Lookup[unsupportedDecision["ActiveGradeCensus"], "Status", None] ===
      "ActiveGradeCensusInconclusive"];

fullRootConnection = {
  {{0, 0}, {Total[Lookup[declaredRoots, "Root"]], 0}},
  {{0, 0}, {0, 0}}
};
chartlessDirect = forcingOf[fullRootConnection, ranges, 2, 1, <||>,
  variables, epsilon, "Output" -> "ChartOrBundle",
  "BundleRoots" -> declaredRoots];
FTAssert["C11 chartless production returns the direct provider without a \
materialized oracle",
  Lookup[chartlessDirect, "Status", None] === "PreparedDeferredBundle" &&
    Lookup[validateBundle[chartlessDirect], "Status", None] ===
      "BundleValid" &&
    Length[chartlessDirect["RootFrame", "Roots"]] === 3];

certifiedMaterializedSolution = SolveEpsFormStripInFrame[
  {zeroPair, zeroPair, oneMaterialized["Forcing"]},
  variables, epsilon, oneFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root_certified"],
  "MultiquadraticOptions" -> {
    "DeferredBundle" -> oneMaterialized["DeferredBundle"]},
  "DeferredMaterializationCertificate" ->
    oneMaterialized["DeferredMaterializationCertificate"],
  "Verbose" -> False];
FTAssert["C12 certified materialized forcing skips redundant bundle pullback \
without changing the exact gauge",
  Lookup[certifiedMaterializedSolution, "Status", None] === "Solved" &&
    StringStartsQ[certifiedMaterializedSolution["Method"],
      "RationalChart/Kallen1/"] &&
    AllTrue[Flatten[certifiedMaterializedSolution["Gauge"] -
        oneSolution["Gauge"]],
      TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[#1,
        oneRoots]] &]];
mutatedForcing = ReplacePart[oneMaterialized["Forcing"],
  {1, 1, 1} -> 2 oneMaterialized["Forcing"][[1, 1, 1]]];
mutatedMaterializedSolution = SolveEpsFormStripInFrame[
  {zeroPair, zeroPair, mutatedForcing}, variables, epsilon, oneFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root_mutated"],
  "MultiquadraticOptions" -> {
    "DeferredBundle" -> oneMaterialized["DeferredBundle"]},
  "DeferredMaterializationCertificate" ->
    oneMaterialized["DeferredMaterializationCertificate"],
  "Verbose" -> False];
FTAssert["C13 a mutated BBar cannot reuse a bundle materialization certificate",
  Lookup[mutatedMaterializedSolution, "Status", None] ===
    "InvalidDeferredMaterializationCertificate"];

plainRationalSolution = SolveEpsFormStripInFrame[
  {zeroPair, zeroPair, {{{1}}, {{0}}}}, variables, epsilon, declaredFrame,
  "FiniteFieldFirst" -> True,
  "FiniteFieldOptions" -> commonFiniteOptions["plain_rational"],
  "Verbose" -> False];
FTAssert["C14 an ordinary nonzero rational strip still uses RationalFrame",
  Lookup[plainRationalSolution, "Status", None] === "Solved" &&
    StringStartsQ[plainRationalSolution["Method"], "RationalFrame/"] &&
    plainRationalSolution["RootIndices"] === {} &&
    TrueQ[plainRationalSolution["ExactDLog"]]];

(* A chartless full-rank bundle remains on the direct-provider contract;
   the existing t_deferred_bundle_dispatch covers that disabled boundary. *)
FTSummary[];
