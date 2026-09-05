#!/usr/bin/env wolframscript
(* Active-subfield pruning can leave a deferred inhomogeneity rational or
   chartable even though its family frame is multiquadratic.  The bundle is
   the real inhomogeneity while the Strip Inhomogeneity slot is a zero shape placeholder.
   These cases must reconstruct/pull the bundle before the rational solver.
   A joint chart remains the primary route; the direct engine may be reused
   at rank zero only after that rational ansatz returns no gauge. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{inhomogeneityOf, prepareDeferred, chartDecision, validateBundle, currentRoots,
  pullBundle, pullPreparation, bundleEvaluate, directAlphabet, chartRekey,
  chartData, rootExpression, rootRadicand, pullEquation} = mq /@ {
  "blockEquationDeferredInhomogeneity", "blockEquationDeferredPrepare",
  "blockEquationDeferredChartDecision",
  "blockEquationDeferredBundleValidate",
  "coefficientPresentationSquareRootsInVariables",
  "transportChartPullBackDeferredBundle",
  "transportChartPullBackDeferredPreparation",
  "blockEquationDeferredBundleEvaluate",
  "familyRowBasisTransformationDirectAlphabetOptions", "rekeyCoefficientPresentation",
  "masterTransportCoefficientPresentationData",
  "squareRootRecordExpression", "squareRootRecordRadicand",
  "transportChartPullBackOffDiagonalBlockEquation"};

Clear[cbx, cby, cbe, cbfx, cbfy, cbtx, cbty];
variables = {cbx, cby};
epsilon = cbe;
zeroPair = {{{0}}, {{0}}};
placeholderStrip = {zeroPair, zeroPair, zeroPair};
ranges = {{1}, {2}};

(* Root-free inhomogeneity inside a larger declared frame. *)
declaredSquares = {cbx, cby, 1 - cbx - cby};
declaredFrame = BuildSquareRootGeneratorsAndQuadraticRelations[
  declaredSquares, variables, {cbfx, cbfy}];
declaredRoots = currentRoots[declaredFrame, variables];
rationalConnection = {
  {{0, 0}, {1, 0}},
  {{0, 0}, {0, 0}}
};
rationalBundle = inhomogeneityOf[rationalConnection, ranges, 2, 1, <||>,
  variables, epsilon, "Output" -> "Bundle",
  "BundleRoots" -> declaredRoots];
FTAssert["C1 root-free inhomogeneity compiles to an authenticated empty frame",
  Lookup[validateBundle[rationalBundle], "Status", None] === "BundleValid" &&
    rationalBundle["SquareRootGeneratorIndices"] === {} &&
    rationalBundle["Statistics", "PrunedRootCount"] === 3];
FTAssert["C2 an empty divisor census yields the neutral direct alphabet payload",
  directAlphabet[rationalBundle] === <|
    "AdditionalLetters" -> {}, "AlgebraicLetters" -> Automatic|>];
identityData = chartData[None, variables];
rationalPull = pullBundle[rationalBundle, identityData, {}, {}];
FTAssert["C3 the root-free deferred inhomogeneity is reconstructed, not the placeholder",
  Lookup[rationalPull, "Status", None] === "OK" &&
    rationalPull["OneForm"] === {{{1}}, {{0}}}];

(* A one-root inhomogeneity whose exact Kallen chart is in the catalog. *)
lambda = (1 - cbx - cby)^2 - 4 cbx cby;
oneFrame = BuildSquareRootGeneratorsAndQuadraticRelations[{lambda}, variables, {cbfx, cbfy}];
oneRoots = currentRoots[oneFrame, variables];
oneRoot = rootExpression[First[oneRoots]];
oneConnection = {
  {{0, 0}, {D[oneRoot, cbx], 0}},
  {{0, 0}, {D[oneRoot, cby], 0}}
};
oneBundle = inhomogeneityOf[oneConnection, ranges, 2, 1, <||>, variables,
  epsilon, "Output" -> "Bundle", "BundleRoots" -> oneRoots];
FTAssert["C4 one-root inhomogeneity retains exactly one active generator",
  Lookup[validateBundle[oneBundle], "Status", None] === "BundleValid" &&
    oneBundle["SquareRootGeneratorIndices"] === {1}];
chart = LookupCataloguedRationalizingParametrizationForRoots[{lambda}, variables];
FTAssert["C5 the active one-root set has the registered Kallen1 chart",
  AssociationQ[chart] && chart["Name"] === "Kallen1"];
chartVariables = {cbtx, cbty};
rekeyed = chartRekey[chart, variables, chartVariables];
data = chartData[rekeyed, variables];
chartRoots = currentRoots[rekeyed, chartVariables];
chartRoot = SelectFirst[chartRoots,
  TrueQ[Together[Lookup[#1, "SourceRadicand", 0] - lambda] === 0] &];
branchRoots = {<|"Generator" -> Sqrt[Together[
      lambda /. mq["masterTransportPresentationSubstitution"][data]]],
    "QuadraticRadicand" -> Together[
      lambda /. mq["masterTransportPresentationSubstitution"][data]],
    "SourceRadicand" -> lambda|>};
rootImages = {rootExpression[chartRoot]};
onePull = pullBundle[oneBundle, data, branchRoots, rootImages];
materialized = bundleEvaluate[oneBundle, {}];
referencePull = pullEquation[
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
rationalSolution = SolveOffDiagonalBasisTransformationBlock[
  placeholderStrip, variables, epsilon, declaredFrame,
  "FiniteFieldOptions" -> commonFiniteOptions["root_free"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> rationalBundle},
  "Verbose" -> False];
FTAssert["C7 root-free bundle dispatch solves the reconstructed rational inhomogeneity",
  Lookup[rationalSolution, "Status", None] === "Solved" &&
    StringStartsQ[rationalSolution["Method"],
      "SourceVariableRepresentation/"] &&
    rationalSolution["SquareRootGeneratorIndices"] === {} &&
    TrueQ[rationalSolution["ExactDLog"]]];
oneSolution = SolveOffDiagonalBasisTransformationBlock[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> oneBundle},
  "Verbose" -> False];
FTAssert["C8 chartable deferred inhomogeneity uses the rational chart and solves exactly",
  Lookup[oneSolution, "Status", None] === "Solved" &&
    StringStartsQ[oneSolution["Method"],
      "RationalizingParametrization/Kallen1/"] &&
    oneSolution["SquareRootGeneratorIndices"] === {1} &&
    TrueQ[oneSolution["ExactDLog"]] &&
    TrueQ[oneSolution["Validation", "SourceDLog"]]];

oneChartFast = inhomogeneityOf[oneConnection, ranges, 2, 1, <||>, variables,
  epsilon, "Output" -> "ChartOrBundle", "BundleRoots" -> oneRoots];
oneChartPreparation = <|
  "Preparation" -> oneChartFast["DeferredPreparation"],
  "CoefficientPresentation" -> oneChartFast["CoefficientPresentation"],
  "SquareRootGeneratorIndices" ->
    oneChartFast["SquareRootGeneratorIndices"],
  "ProjectionSquareRootGeneratorIndices" ->
    oneChartFast["ProjectionSquareRootGeneratorIndices"]|>;
FTAssert["C9 chart-aware production bypasses provider compilation and \
source-frame materialization",
  Lookup[oneChartFast, "Status", None] === "PreparedChartDeferred" &&
    ! KeyExistsQ[oneChartFast, "DeferredBundle"] &&
    ! KeyExistsQ[oneChartFast, "Inhomogeneity"] &&
    Lookup[oneChartFast["Census"], "Status", None] ===
      "SkippedForChart" &&
    TrueQ[oneChartFast["ChartDecision", "ChartAvailableQ"]]];
oneChartFastSolution = SolveOffDiagonalBasisTransformationBlock[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldOptions" -> commonFiniteOptions["one_root_preparation"],
  "DeferredPreparation" -> oneChartPreparation,
  "Verbose" -> False];
FTAssert["C10 deferred preparation materializes in the chart and gives the \
same exact gauge",
    Lookup[oneChartFastSolution, "Status", None] === "Solved" &&
    StringStartsQ[oneChartFastSolution["Method"],
      "RationalizingParametrization/Kallen1/"] &&
    AllTrue[Flatten[oneChartFastSolution["OffDiagonalBasisTransformationBlock"] - oneSolution["OffDiagonalBasisTransformationBlock"]],
      TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[#1,
        oneRoots]] &]];
ambiguousDeferredSolution = SolveOffDiagonalBasisTransformationBlock[
  placeholderStrip, variables, epsilon, oneFrame,
  "FiniteFieldOptions" -> commonFiniteOptions["ambiguous_deferred"],
  "MultiquadraticOptions" -> {"DeferredBundle" -> oneBundle},
  "DeferredPreparation" -> oneChartPreparation,
  "Verbose" -> False];
FTAssert["C10b simultaneous bundle and preparation are refused before solve",
  Lookup[ambiguousDeferredSolution, "Status", None] ===
    "AmbiguousDeferredInhomogeneity"];

(* Cancellation can make the assembled source live in a strict subfield even
   when its raw DAG operands mention the full declared frame.  The route-only
   all-sheet census must see the assembled grades before provider compilation. *)
kallenSquares = {
  (1 - cbx - cby)^2 - 4 cbx cby,
  (1 + cbx - cby)^2 + 4 cbx cby,
  (1 - cbx + cby)^2 + 4 cbx cby};
kallenFrame = BuildSquareRootGeneratorsAndQuadraticRelations[
  kallenSquares, variables, {cbfx, cbfy}];
kallenRoots = currentRoots[kallenFrame, variables];
kallenRootExpressions = rootExpression /@ kallenRoots;
subsetConnection = {
  {{0, 0, 0}, {0, 0, 0},
    {kallenRootExpressions[[1]] + kallenRootExpressions[[3]], 0, 0}},
  ConstantArray[0, {3, 3}]};
subsetChartFast = inhomogeneityOf[subsetConnection, {{1}, {2}, {3}}, 3, 1,
  <||>, variables, epsilon, "Output" -> "ChartOrBundle",
  "BundleRoots" -> kallenRoots];
FTAssert["C10c0 a chartable raw subfield bypasses modular grade sampling",
  Lookup[subsetChartFast, "Status", None] === "PreparedChartDeferred" &&
    Lookup[subsetChartFast["ChartDecision"], "Method", None] ===
      "SyntacticRootUnion" &&
    subsetChartFast["ChartDecision", "RootIndices"] === {1, 3} &&
    subsetChartFast["ChartDecision", "Chart"] === "Kallen13" &&
    MissingQ[subsetChartFast["ChartDecision", "ActiveGradeCensus"]]];
cancelConnection = {
  {{0, 0, 0},
   {kallenRootExpressions[[2]] + kallenRootExpressions[[3]], 0, 0},
   {Total[kallenRootExpressions], 0, 0}},
  ConstantArray[0, {3, 3}]};
cancelSolved = <|2 -> {{1}}|>;
cancelChartFast = inhomogeneityOf[cancelConnection, {{1}, {2}, {3}}, 3, 1,
  cancelSolved, variables, epsilon, "Output" -> "ChartOrBundle",
  "BundleRoots" -> kallenRoots];
FTAssert["C10c an assembled one-root inhomogeneity bypasses a syntactic three-root provider",
  Lookup[cancelChartFast, "Status", None] === "PreparedChartDeferred" &&
    Lookup[cancelChartFast["ChartDecision"], "Method", None] ===
      "ModularActiveGrades" &&
    MissingQ[Lookup[cancelChartFast["ChartDecision"],
      "SyntacticRootIndices", None]] &&
    Lookup[cancelChartFast["ChartDecision", "ActiveGradeCensus"],
      "DirectPlaceholderCount", 0] > 0 &&
    Lookup[cancelChartFast["ChartDecision", "ActiveGradeCensus"],
      "CanonicalizedPlaceholderCount", -1] === 0 &&
    Lookup[cancelChartFast["ChartDecision", "ActiveGradeCensus"],
      "DenominatorRootIndices", None] === {} &&
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
FTAssert["C10d canceled inactive algebraic denominators route through exact post-sum projection",
  Lookup[denominatorDecision, "Status", None] === "OK" &&
    TrueQ[denominatorDecision["ChartAvailableQ"]] &&
    Lookup[denominatorDecision, "Method", None] ===
      "ModularActiveGradesProjected" &&
    Lookup[denominatorDecision, "ProjectionRootIndices", None] === {2, 3} &&
    Lookup[denominatorDecision["ActiveGradeCensus"], "Status", None] ===
      "ActiveGradeCensus" &&
    ContainsAll[Lookup[denominatorDecision["ActiveGradeCensus"],
      "DenominatorRootIndices", {}], {2, 3}]];

denominatorChart = LookupCataloguedRationalizingParametrizationForRoots[
  denominatorDecision["RootSquares"], variables];
denominatorRekeyed = chartRekey[
  denominatorChart, variables, chartVariables];
denominatorData = chartData[denominatorRekeyed, variables];
denominatorChartRoots = currentRoots[denominatorRekeyed, chartVariables];
denominatorChartRoot = SelectFirst[denominatorChartRoots,
  TrueQ[Together[Lookup[#1, "SourceRadicand", 0] -
    First[denominatorDecision["RootSquares"]]] === 0] &];
denominatorBranchRoots = {
  <|"Generator" -> Sqrt[Together[
      First[denominatorDecision["RootSquares"]] /.
        mq["masterTransportPresentationSubstitution"][denominatorData]]],
    "QuadraticRadicand" -> Together[
    First[denominatorDecision["RootSquares"]] /.
      mq["masterTransportPresentationSubstitution"][denominatorData]],
    "SourceRadicand" ->
      First[denominatorDecision["RootSquares"]]|>};
denominatorRootImages = {rootExpression[denominatorChartRoot]};
denominatorDeferredRecord = <|
  "Preparation" -> denominatorPreparation,
  "CoefficientPresentation" -> kallenFrame,
  "SquareRootGeneratorIndices" -> denominatorDecision["RootIndices"],
  "ProjectionSquareRootGeneratorIndices" ->
    denominatorDecision["ProjectionRootIndices"]|>;
denominatorPull = pullPreparation[denominatorDeferredRecord,
  denominatorData, denominatorBranchRoots, denominatorRootImages];
FTAssert["C10e exact post-sum projection removes canceled inactive roots before rational solving",
  Lookup[denominatorPull, "Status", None] === "OK" &&
    Lookup[denominatorPull["InactiveSquareRootGeneratorProjection"],
      "Status", None] ===
      "ExactInactiveGradeProjection" &&
    Lookup[denominatorPull["InactiveSquareRootGeneratorProjection"],
      "SquareRootGeneratorCount", None] === 2 &&
    FeynFacet`Private`transportChartRadicalBases[
      denominatorPull["OneForm"]] === {} &&
    FreeQ[denominatorPull["OneForm"],
      symbol_Symbol /; StringStartsQ[SymbolName[symbol],
        "deferredProjectionRoot"]]];

unsupportedPreparation = prepareDeferred[unsupportedConnection,
  {{1}, {2}, {3}}, 3, 1, cancelSolved, variables, epsilon];
unsupportedDecision = chartDecision[unsupportedConnection,
  unsupportedPreparation, kallenRoots];
FTAssert["C10f an inconclusive active-grade census stays on the direct route",
  Lookup[unsupportedDecision, "Status", None] === "OK" &&
    ! TrueQ[unsupportedDecision["ChartAvailableQ"]] &&
    Lookup[unsupportedDecision, "Method", None] === "SyntacticRootUnion" &&
    Lookup[unsupportedDecision["ActiveGradeCensus"], "Status", None] ===
      "ActiveGradeCensusInconclusive"];

fullRootConnection = {
  {{0, 0}, {Total[rootExpression /@ declaredRoots], 0}},
  {{0, 0}, {0, 0}}
};
chartlessDirect = inhomogeneityOf[fullRootConnection, ranges, 2, 1, <||>,
  variables, epsilon, "Output" -> "ChartOrBundle",
  "BundleRoots" -> declaredRoots];
FTAssert["C11 chartless production returns the direct provider without a \
materialized oracle",
  Lookup[chartlessDirect, "Status", None] === "PreparedDeferredBundle" &&
  Lookup[validateBundle[chartlessDirect], "Status", None] ===
      "BundleValid" &&
    chartlessDirect["SquareRootGeneratorIndices"] === {1, 2, 3}];

plainRationalSolution = SolveOffDiagonalBasisTransformationBlock[
  {zeroPair, zeroPair, {{{1}}, {{0}}}}, variables, epsilon, declaredFrame,
  "FiniteFieldOptions" -> commonFiniteOptions["plain_rational"],
  "Verbose" -> False];
FTAssert["C12 an ordinary nonzero rational strip still uses RationalFrame",
  Lookup[plainRationalSolution, "Status", None] === "Solved" &&
    StringStartsQ[plainRationalSolution["Method"],
      "SourceVariableRepresentation/"] &&
    plainRationalSolution["SquareRootGeneratorIndices"] === {} &&
    TrueQ[plainRationalSolution["ExactDLog"]]];

(* A chartless full-rank bundle remains on the direct-provider contract;
   the existing t_deferred_bundle_dispatch covers that disabled boundary. *)
FTSummary[];
