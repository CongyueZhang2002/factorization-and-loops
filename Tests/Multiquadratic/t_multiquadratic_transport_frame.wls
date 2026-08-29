#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

v = Symbol["Global`v"];
w = Symbol["Global`w"];
x = Symbol["Global`mqx"];
y = Symbol["Global`mqy"];
eps = Symbol["Global`eps"];

lambda1 = (1 - v - w)^2 - 4 v w;
lambda2 = (1 + v - w)^2 + 4 v w;
lambda3 = (1 - v + w)^2 + 4 v w;

frame = BuildAlgebraicTransportFrame[
  {lambda1, lambda2, lambda3}, {v, w}, {x, y}];

FTAssert["the multiquadratic frame is exported",
  StringQ[BuildAlgebraicTransportFrame::usage]];
FTAssert["all three root-square identities and the identity Jacobian are exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame" &&
    TrueQ[frame["ChartCertificate"]["OK"]] &&
    frame["ChartCertificate"]["RootIdentities"] === {True, True, True} &&
    TrueQ[Together[frame["ChartCertificate"]["JacobianDet"] - 1] === 0]];

(* The per-family chart inventory is PROJECT data since 2026-08-23: the
   package ships an empty registry, so this test registers the project's
   own table before asking for its three-root families. *)
projectChartFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "TransportFamilyCharts.wl"}];
projectChartRegistration = FeynFacet`TransportFamilyChartLoad[projectChartFile];
FTAssert["the project's family chart table registers",
  Lookup[projectChartRegistration, "Status", None] === "FamilyChartsRegistered"];

familyFrames = TransportFamilyChart /@ {"CF259", "CF300", "CF303"};
FTAssert["the three-root inventory resolves to exact multiquadratic frames",
  AllTrue[familyFrames,
    AssociationQ[#] && #["Status"] === "ExactFrame" &&
      TrueQ[#["ChartCertificate"]["OK"]] &&
      Length[#["Roots"]] === 3 &]];

orderingFrame = First[familyFrames];
orderingRoots = orderingFrame["Roots"];
orderingForward = FeynFacet`Private`transportChartRootIndices[
  {orderingRoots[[1, "Root"]], orderingRoots[[3, "Root"]]},
  orderingRoots];
orderingReverse = FeynFacet`Private`transportChartRootIndices[
  {orderingRoots[[3, "Root"]], orderingRoots[[1, "Root"]]},
  orderingRoots];
FTAssert["root-channel indices follow frame order, not expression order",
  orderingForward["RootIndices"] === {1, 3} &&
    orderingReverse["RootIndices"] === {1, 3}];

cf300Roots = FeynFacet`Private`transportChartCurrentRoots[
  familyFrames[[2]], {v, w}];
zeroNoChartStrip = {
  {{{cf300Roots[[2, "Root"]]}}, {{cf300Roots[[2, "Root"]]}}},
  {{{cf300Roots[[3, "Root"]]}}, {{cf300Roots[[3, "Root"]]}}},
  {{{0}}, {{0}}}};
zeroNoChartSolution = SolveEpsFormStripInFrame[
  zeroNoChartStrip, {v, w}, eps, familyFrames[[2]],
  "FiniteFieldFirst" -> True, "Verbose" -> False];
FTAssert["zero forcing bypasses a missing joint root chart",
  AssociationQ[zeroNoChartSolution] &&
    zeroNoChartSolution["Status"] === "Solved" &&
    zeroNoChartSolution["Method"] === "ZeroForcing" &&
    zeroNoChartSolution["RootIndices"] === {2, 3} &&
    zeroNoChartSolution["Gauge"] === {{0}} &&
    TrueQ[zeroNoChartSolution["FrameCertificate", "Exact"]] &&
    zeroNoChartSolution["FrameCertificate", "SamplingEntered"] === False];

(* {lambda1, 4 v + w^2} was the negative control here until 2026-08-24,
   when the iterated-pencil chart KallenQ4a was derived for exactly that
   pair (Tests/Multiquadratic/t_kallen_q4_chart.wls); the negative control moved to a
   pair that still has no joint chart. *)
FTAssert["exact root-set lookup selects the known joint charts",
  TransportRootSetChart[{lambda1, lambda3}]["Name"] === "Kallen13" &&
    TransportRootSetChart[{lambda2, lambda3}]["Name"] === "Kallen23" &&
    TransportRootSetChart[{lambda1, 4 v + w^2}]["Name"] === "KallenQ4a" &&
    TransportRootSetChart[{lambda1, v^2 + 4 w}]["Name"] === "KallenQ4b" &&
    MissingQ[TransportRootSetChart[{lambda1, 1 - 4 v w}]]];

a = Symbol["Global`arbitraryA"];
b = Symbol["Global`arbitraryB"];
FTAssert["root-set lookup is independent of the source variable names",
  TransportRootSetChart[
    {lambda1 /. {v -> a, w -> b}, lambda3 /. {v -> a, w -> b}},
    {a, b}]["Name"] === "Kallen13"];

knownGauge = {{Sqrt[lambda1]}};
zeroOneForm = {ConstantArray[0, {1, 1}], ConstantArray[0, {1, 1}]};
algebraicStrip = {zeroOneForm, zeroOneForm,
  {D[knownGauge, v], D[knownGauge, w]}};
stripSolution = SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, frame,
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICATimeLimit" -> 30, "CANONICAKernels" -> 1,
  "MapleTimeLimit" -> 60, "MapleResidueKernels" -> 1,
  "Verbose" -> False];
FTAssert["a one-root algebraic strip is solved in its rational chart and pulled back exactly",
  AssociationQ[stripSolution] && stripSolution["Status"] === "Solved" &&
    StringStartsQ[stripSolution["Method"], "RationalChart/Kallen1/"] &&
    TrueQ[stripSolution["ExactDLog"]] &&
    TrueQ[stripSolution["FrameCertificate"]["CoordinateComposition"]] &&
    TrueQ[stripSolution["FrameCertificate"]["GaugeRoundTrip"]] &&
    TrueQ[stripSolution["FrameCertificate"]["TransformedOneFormPullBack"]] &&
    TrueQ[stripSolution["FrameCertificate"]["SourceDLog"]] &&
    TrueQ[stripSolution["FrameCertificate"]["Exact"]]];

compactStripSolution = SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, frame,
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICATimeLimit" -> 30, "CANONICAKernels" -> 1,
  "MapleTimeLimit" -> 60, "MapleResidueKernels" -> 1,
  "GaugePullBackMode" -> "CompactCompositional",
  "Verbose" -> False];
compactGaugeDifference = MapThread[Subtract,
  {compactStripSolution["Gauge"], stripSolution["Gauge"]}, 2];
FTAssert["compact chart composition preserves the exact gauge without a common-fraction pullback",
  AssociationQ[compactStripSolution] &&
    compactStripSolution["Status"] === "Solved" &&
    AllTrue[Flatten[compactGaugeDifference],
      TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
        #, frame["Roots"]]] &] &&
    FreeQ[compactStripSolution["Gauge"],
      FeynFacet`Private`stripChartX | FeynFacet`Private`stripChartY] &&
    compactStripSolution["FrameCertificate", "ValidationMode"] ===
      "ExactFunctorial" &&
    compactStripSolution["FrameCertificate", "GaugeRoundTripProof"] ===
      "ExactCoordinateComposition" &&
    TrueQ[compactStripSolution["FrameCertificate", "Exact"]]];

invalidCompactMode = SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, frame,
  "GaugePullBackMode" -> "NotAMode", "Verbose" -> False];
FTAssert["an unknown gauge pullback mode is refused before solving",
  AssociationQ[invalidCompactMode] &&
    invalidCompactMode["Status"] === "InvalidGaugePullBackMode"];

data = FeynFacet`Private`masterTransportChartData[frame, {v, w}];
FTAssert["chart data retains the declared multiquadratic coefficient field",
  data["Status"] === "OK" &&
    data["CoefficientField"] === "Multiquadratic"];

(* A two-variable Kallen chart must compose with the identity algebraic
   frame through the declared square root, without inventing another
   algebraic extension. *)
kallen = TransportChartCatalog[]["Kallen1"];
kallenRecord = <|"Variables" -> kallen["Variables"], "Chart" -> kallen|>;
composition = FeynFacet`Private`masterTransportRecordCoordinateMap[
  kallenRecord, data, Automatic];
FTAssert["a rational Kallen chart composes exactly into the multiquadratic frame",
  AssociationQ[composition] && composition["Status"] === "OK" &&
    TrueQ[composition["CompositionExact"]]];

(* The old rational-only gate is tested on an exact flat system whose
   basis transformation contains sqrt(1-4vw).  The multiquadratic call
   must retain the radical and re-derive the epsilon form; the rational
   call must refuse the same transformation. *)
q = 1 - 4 v w;
t = {{Sqrt[q], 0}, {0, 1}};
ti = Simplify[Inverse[t]];
ev = eps {{1, 0}, {0, 2}}/v;
ew = eps {{3, 0}, {0, 4}}/w;
av = Map[Together, t . ev . ti + D[t, v] . ti, {2}];
aw = Map[Together, t . ew . ti + D[t, w] . ti, {2}];
system = <|"Family" -> "MultiquadraticToy", "Av" -> av, "Aw" -> aw|>;
pulledSystem = FeynFacet`Private`masterTransportPullBackSystem[
  system, frame, "SourceVariables" -> {v, w}];
record = <|"Variables" -> {v, w}, "Transformation" -> t,
  "EpsForm" -> {ev, ew}|>;

accepted = FeynFacet`Private`masterTransportPullBackClassForm[
  record, frame, "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "BlockSystem" -> {pulledSystem["Ax"], pulledSystem["Ay"]},
  "CoefficientField" -> "Multiquadratic"];
refused = FeynFacet`Private`masterTransportPullBackClassForm[
  record, frame, "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "BlockSystem" -> {pulledSystem["Ax"], pulledSystem["Ay"]},
  "CoefficientField" -> "Rational"];

FTAssert["an algebraic basis transformation is accepted only in the declared field",
  accepted["Status"] === "OK" &&
    accepted["Certificate"]["CoefficientField"] === "Multiquadratic" &&
    accepted["Certificate"]["TransformationRationalInChart"] === False &&
    TrueQ[accepted["Certificate"]["TransformationInverseVerified"]] &&
    TrueQ[accepted["Certificate"]["EpsFormLinear"]] &&
    TrueQ[accepted["Certificate"]["StoredEpsFormPullbackMatches"]] &&
    refused["Status"] === "ClassFormTransformationNotRationalInChart"];

assembled = TransportFamilyInChart[system, frame,
  "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "AssemblyOnly" -> True,
  "Blocks" -> {{{1, 2}, <|"Type" -> "EpsForm", "T" -> t,
    "Ev" -> ev, "Ew" -> ew|>}}, "Verbose" -> False];
FTAssert["assembly-only returns the exactly certified whole-family connection",
  AssociationQ[assembled] && assembled["Status"] === "ExactFamilyAssembly" &&
    assembled["Assembly"]["Status"] === "OK" &&
    And @@ (TrueQ /@ Values[
      KeyTake[assembled["Assembly"]["Certificate"],
        {"BlockLowerTriangular", "FlatnessOriginal",
          "DiagonalEqualsDeclaredForm", "EpsFormLinear",
          "TransformationInverseVerified"}]]) &&
    MemberQ[{"Verified", "ByGaugeCovariance"},
      assembled["Assembly"]["Certificate"]["FlatnessConjugatedRoute"]]];

censusAssembly = <|"Status" -> "OK", "Family" -> "RootCensusToy",
  "Blocks" -> {{1}, {2}}, "Ranges" -> {{1}, {2}},
  "Apv" -> {{0, 0}, {1/frame["Roots"][[1]]["Root"], 0}},
  "Apw" -> ConstantArray[0, {2, 2}]|>;
census = FamilyAlgebraicRootCensus[censusAssembly, frame];
FTAssert["the root census classifies every radical against the declared field",
  census["Status"] === "ExactRootCensus" &&
    census["UnclassifiedRadicalBases"] === {} &&
    census["MaximumRootCount"] === 1 &&
    census["RootCountHistogram"] === <|1 -> 1|>];

(* Exact entrywise substitution is the expensive chart-gauge transport
   primitive.  Its broker and serial routes must be SameQ, not merely equal
   at points. *)
togetherInput = {{1/(1 + x) + y/(1 - x y), (x + y)^3/(2 - x)},
  {(1 + x y)/(1 - y)^2, x^2/(1 + y) + 1/(1 - x)}};
togetherRules = {x -> (v + w)/(1 - v w),
  y -> (v - w)/(1 + v w)};
togetherExpected = Map[Together, togetherInput /. togetherRules, {2}];
togetherResult = FeynFacet`Private`transportChartParallelTogether[
  togetherInput, togetherRules, "tctest"];
FTAssert["parallel chart Together preserves exact entrywise substitution",
  togetherResult["Status"] === "OK" &&
    togetherResult["Result"] === togetherExpected];
expiredTogether = FeynFacet`Private`transportChartParallelTogether[
  togetherInput, togetherRules, "tctest_expired", AbsoluteTime[] - 1];
FTAssert["chart Together refuses before work when its deadline has expired",
  expiredTogether["Status"] === "DeadlineExpired"];

FTReport[];
