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

generatorData = BuildSquareRootGeneratorsAndQuadraticRelations[
  {lambda1, lambda2, lambda3}, {v, w}, {x, y}];

FTAssert["the square-root generator constructor is exported",
  StringQ[BuildSquareRootGeneratorsAndQuadraticRelations::usage]];
FTAssert["all three quadratic relations and the identity Jacobian are exact",
  AssociationQ[generatorData] &&
    generatorData["Status"] === "SquareRootGeneratorRelationsVerified" &&
    TrueQ[generatorData["QuadraticRelationVerification", "Verified"]] &&
    generatorData["QuadraticRelationVerification", "PerGenerator"] ===
      {True, True, True} &&
    TrueQ[Together[
      generatorData["QuadraticRelationVerification",
        "CoordinateJacobianDeterminant"] - 1] === 0] &&
    generatorData["SquareClassIndependenceStatus"] === "NotChecked" &&
    generatorData["GaloisConjugatesCertified"] === False];

(* Family root data is project input.  This test registers the live schema
   directly; generated V1 campaign artifacts are regenerated separately. *)
projectRootDataRegistration = FeynFacet`RegisterFamilyRootData[<|
  "CF259" -> <|"SourceRadicands" -> {lambda1, lambda3, 4 v + w^2}|>,
  "CF300" -> <|"SourceRadicands" -> {lambda2, lambda3, 1 - 4 v w}|>,
  "CF303" -> <|"SourceRadicands" -> {lambda2, lambda3, 1 - 4 v w}|>
|>];
FTAssert["the project's family root data registers",
  Lookup[projectRootDataRegistration, "Status", None] ===
    "FamilyRootDataRegistered"];

familyGeneratorData = FamilyRootData /@ {"CF259", "CF300", "CF303"};
FTAssert["the three-root inventory resolves to verified generator relations",
  AllTrue[familyGeneratorData,
    AssociationQ[#] &&
      #["Status"] === "SquareRootGeneratorRelationsVerified" &&
      TrueQ[#["QuadraticRelationVerification", "Verified"]] &&
      Length[#["SquareRootGenerators"]] === 3 &]];

orderingGeneratorData = First[familyGeneratorData];
orderingRoots = orderingGeneratorData["SquareRootGenerators"];
orderingForward = FeynFacet`Private`transportChartRootIndices[
  {orderingRoots[[1, "Generator"]],
   orderingRoots[[3, "Generator"]]},
  orderingRoots];
orderingReverse = FeynFacet`Private`transportChartRootIndices[
  {orderingRoots[[3, "Generator"]],
   orderingRoots[[1, "Generator"]]},
  orderingRoots];
FTAssert["root-channel indices follow generator order, not expression order",
  orderingForward["RootIndices"] === {1, 3} &&
    orderingReverse["RootIndices"] === {1, 3}];

cf300Roots =
  FeynFacet`Private`coefficientPresentationSquareRootsInVariables[
  familyGeneratorData[[2]], {v, w}];
zeroNoChartStrip = {
  {{{cf300Roots[[2, "Generator"]]}},
    {{cf300Roots[[2, "Generator"]]}}},
  {{{cf300Roots[[3, "Generator"]]}},
    {{cf300Roots[[3, "Generator"]]}}},
  {{{0}}, {{0}}}};
zeroNoChartSolution = SolveEpsFormStripInFrame[
  zeroNoChartStrip, {v, w}, eps, familyGeneratorData[[2]],
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
  LookupCataloguedRationalizingParametrizationForRoots[{lambda1, lambda3}]["Name"] === "Kallen13" &&
    LookupCataloguedRationalizingParametrizationForRoots[{lambda2, lambda3}]["Name"] === "Kallen23" &&
    LookupCataloguedRationalizingParametrizationForRoots[{lambda1, 4 v + w^2}]["Name"] === "KallenQ4a" &&
    LookupCataloguedRationalizingParametrizationForRoots[{lambda1, v^2 + 4 w}]["Name"] === "KallenQ4b" &&
    MatchQ[LookupCataloguedRationalizingParametrizationForRoots[
      {lambda1, 1 - 4 v w}],
      Missing["NoCataloguedRationalizingParametrization", _]]];

a = Symbol["Global`arbitraryA"];
b = Symbol["Global`arbitraryB"];
FTAssert["root-set lookup is independent of the source variable names",
  LookupCataloguedRationalizingParametrizationForRoots[
    {lambda1 /. {v -> a, w -> b}, lambda3 /. {v -> a, w -> b}},
    {a, b}]["Name"] === "Kallen13"];

knownGauge = {{Sqrt[lambda1]}};
zeroOneForm = {ConstantArray[0, {1, 1}], ConstantArray[0, {1, 1}]};
algebraicStrip = {zeroOneForm, zeroOneForm,
  {D[knownGauge, v], D[knownGauge, w]}};
stripSolution = SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, generatorData,
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

FTAssert["exact chart pullback remains the default",
  ("GaugePullBackMode" /.
      Options[FeynFacet`SolveEpsFormStripInFrame]) === "Exact"];

invalidPullBackMode = SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, generatorData,
  "GaugePullBackMode" -> "NotAMode", "Verbose" -> False];
FTAssert["an unknown gauge pullback mode is refused before solving",
  AssociationQ[invalidPullBackMode] &&
    invalidPullBackMode["Status"] === "InvalidGaugePullBackMode"];

data = FeynFacet`Private`masterTransportCoefficientPresentationData[
  generatorData, {v, w}];
FTAssert["core data preserves the generator-and-relation presentation",
  data["Status"] === "OK" &&
    data["PresentationKind"] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
    data["CoefficientVariables"] === {x, y} &&
    data["SourceToCoefficientVariableRules"] === {v -> x, w -> y} &&
    AllTrue[data["SquareRootGenerators"],
      Sort[Keys[#]] ===
        Sort[{"Generator", "QuadraticRadicand", "SourceRadicand"}] &] &&
    TrueQ[data["QuadraticRelationVerification", "Verified"]] &&
    data["SquareClassIndependenceStatus"] === "NotChecked" &&
    data["GaloisConjugatesCertified"] === False &&
    Intersection[Keys[data],
      {"Variables", "Subst", "Roots", "Root", "RootSquare",
       "CoefficientField", "Frame", "Chart", "QuadraticRelations",
       "GeneratorOrdering", "GeneratorExpression", "GeneratorIndex"}] === {}];

hybridGeneratorData = Append[generatorData, "Frame" -> "LegacyLeak"];
normalizedHybridData =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    hybridGeneratorData, {v, w}];
legacyPresentation = <|"Variables" -> {x, y},
  "Subst" -> {v -> x, w -> y}, "Roots" -> {}|>;
legacyPresentationResult =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    legacyPresentation, {v, w}];
FTAssert["the core strips hybrid legacy keys and refuses a V1-only record",
  normalizedHybridData["Status"] === "OK" &&
    ! KeyExistsQ[normalizedHybridData, "Frame"] &&
    legacyPresentationResult["Status"] ===
      "LegacyCoefficientPresentationSchemaUnsupported"];

contradictoryGenerator = ReplacePart[generatorData,
  {"SquareRootGenerators", 1, "QuadraticRadicand"} -> 17];
contradictoryGeneratorResult =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    contradictoryGenerator, {v, w}];
ambiguousPresentation = Join[generatorData,
  RationalizingParametrizationCatalog[]["Kallen1"]];
ambiguousPresentationResult =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    ambiguousPresentation, {v, w}];
FTAssert["the core refuses contradictory or ambiguous canonical presentations",
  contradictoryGeneratorResult["Status"] ===
      "SquareRootGeneratorRelationVerificationFailed" &&
    ambiguousPresentationResult["Status"] ===
      "CoefficientPresentationSchemaAmbiguous"];

sourceVariableData =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    None, {v, w}];
FTAssert["None denotes the unchanged source-variable representation",
  sourceVariableData["Status"] === "OK" &&
    sourceVariableData["PresentationKind"] === "SourceVariables" &&
    sourceVariableData["CoefficientVariables"] === {v, w} &&
    sourceVariableData["SourceVariableSubstitution"] === {v -> v, w -> w} &&
    sourceVariableData["DifferentialPullbackMatrix"] === IdentityMatrix[2] &&
    sourceVariableData["JacobianDeterminant"] === 1 &&
    Intersection[Keys[sourceVariableData],
      {"RationalizedSquareRoots", "SquareRootGenerators",
       "QuadraticRelations"}] === {}];
sourceVariableDataRoundTrip =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    sourceVariableData, {v, w}];
nonidentitySourceVariableData = ReplacePart[sourceVariableData,
  "DifferentialPullbackMatrix" -> {{1, 1}, {0, 1}}];
nonidentitySourceVariableResult =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    nonidentitySourceVariableData, {v, w}];
FTAssert["the explicit source-variable case is idempotent and requires the identity map",
  sourceVariableDataRoundTrip === sourceVariableData &&
    nonidentitySourceVariableResult["Status"] ===
      "SourceVariableRepresentationIdentityFailed"];

(* A Kallen rationalizing parametrization must compose with the declared
   square-root generators without inventing another algebraic extension. *)
kallen = RationalizingParametrizationCatalog[]["Kallen1"];
kallenRecord = <|
  "CoefficientVariables" -> kallen["ParametrizingVariables"],
  "RationalizingParametrization" -> kallen|>;
composition = FeynFacet`Private`masterTransportRecordCoordinateMap[
  kallenRecord, data];
FTAssert["a rational Kallen parametrization composes with generator data",
  AssociationQ[composition] && composition["Status"] === "OK" &&
    TrueQ[composition["CompositionVerified"]] &&
    Intersection[Keys[composition], {"Frame", "Chart", "Map", "Images"}] === {}];

(* The old rational-only gate is tested on an exact flat system whose
   basis transformation contains sqrt(1-4vw).  The multiquadratic call
   must retain the radical and re-derive the epsilon form; the rational
   call must refuse the same transformation. *)
q = lambda1;
t = {{Sqrt[q], 0}, {0, 1}};
ti = Simplify[Inverse[t]];
ev = eps {{1, 0}, {0, 2}}/v;
ew = eps {{3, 0}, {0, 4}}/w;
av = Map[Together, t . ev . ti + D[t, v] . ti, {2}];
aw = Map[Together, t . ew . ti + D[t, w] . ti, {2}];
system = <|"Family" -> "MultiquadraticToy", "Av" -> av, "Aw" -> aw|>;
pulledSystem = FeynFacet`Private`masterTransportPullBackSystem[
  system, generatorData, "SourceVariables" -> {v, w}];
record = <|
  "CoefficientVariables" -> {v, w},
  "BasisTransformationMatrix" -> t,
  "InverseBasisTransformationMatrix" -> ti,
  "RationalizingParametrization" -> None|>;

accepted = FeynFacet`Private`masterTransportPullBackClassForm[
  record, generatorData, "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "BlockSystem" -> {pulledSystem["Ax"], pulledSystem["Ay"]},
  "Swap" -> False];
incompleteGeneratorData = BuildSquareRootGeneratorsAndQuadraticRelations[
  {lambda2, lambda3}, {v, w}, {x, y}];
refused = FeynFacet`Private`masterTransportPullBackClassForm[
  record, incompleteGeneratorData,
  "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "BlockSystem" -> {pulledSystem["Ax"], pulledSystem["Ay"]},
  "Swap" -> False];
nonrationalInKallen2 = FeynFacet`Private`masterTransportPullBackClassForm[
  record, RationalizingParametrizationCatalog[]["Kallen2"],
  "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "BlockSystem" -> {pulledSystem["Ax"], pulledSystem["Ay"]},
  "Swap" -> False];

FTAssert["an algebraic basis transformation is accepted only in the declared square-root algebra",
  accepted["Status"] === "DiagonalBlockDLogEpsilonFormReexpressed" &&
    accepted["Certificate"]["CoefficientPresentationKind"] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
    accepted["Certificate"][
      "BasisTransformationRationalInCoefficientVariables"] === False &&
    TrueQ[accepted["Certificate"][
      "BasisTransformationUsesOnlyDeclaredSquareRootGenerators"]] &&
    TrueQ[accepted["Certificate"]["TransformationInverseVerified"]] &&
    TrueQ[accepted["Certificate"]["EpsFormLinear"]] &&
    refused["Status"] ===
      "BasisTransformationOutsideDeclaredSquareRootAlgebra" &&
    nonrationalInKallen2["Status"] ===
      "BasisTransformationNotRationalInParametrizingVariables"];

assembled = AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
  system, generatorData,
  "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "Blocks" -> {{{1, 2}, record}}, "Verbose" -> False];
FTAssert["assembly-only returns the family system with certified epsilon-form diagonal blocks",
  AssociationQ[assembled] && assembled["Status"] ===
      "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks" &&
    assembled["FamilyDifferentialSystem"]["Status"] === "OK" &&
    And @@ (TrueQ /@ Values[
      KeyTake[assembled["FamilyDifferentialSystem"]["Certificate"],
        {"BlockLowerTriangular", "FlatnessOriginal",
          "DiagonalEqualsDeclaredForm", "EpsFormLinear",
          "TransformationInverseVerified"}]]) &&
    MemberQ[{"Verified", "ByGaugeCovariance"},
      assembled["FamilyDifferentialSystem"]["Certificate"]["FlatnessConjugatedRoute"]]];

rootFreeRecord = <|
  "CoefficientVariables" -> {v, w},
  "BasisTransformationMatrix" -> IdentityMatrix[2],
  "InverseBasisTransformationMatrix" -> IdentityMatrix[2],
  "CachedTransformedConnectionMatrices" -> {ev, ew}|>;
rootFreeSystem = <|"Family" -> "RootFreeToy", "Av" -> ev, "Aw" -> ew|>;
rootFreeAssembly =
  AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
    rootFreeSystem, None,
    "SourceVariables" -> {v, w}, "Regulator" -> eps,
    "Blocks" -> {{{1, 2}, rootFreeRecord}}, "Verbose" -> False];
FTAssert["a root-free assembly records the unchanged source-variable representation",
  AssociationQ[rootFreeAssembly] && rootFreeAssembly["Status"] ===
      "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks" &&
    rootFreeAssembly["CoefficientPresentation", "DataType"] ===
      "SourceVariableRepresentation" &&
    rootFreeAssembly["CoefficientPresentation",
      "SourceVariableSubstitution"] === {v -> v, w -> w} &&
    Intersection[Keys[rootFreeAssembly],
      {"RationalizingParametrization",
       "SquareRootGeneratorsAndQuadraticRelations"}] === {}];

censusAssembly = <|"Status" -> "OK", "Family" -> "RootCensusToy",
  "Blocks" -> {{1}, {2}}, "Ranges" -> {{1}, {2}},
  "Apv" -> {{0, 0},
    {1/generatorData["SquareRootGenerators"][[1]][
      "Generator"], 0}},
  "Apw" -> ConstantArray[0, {2, 2}]|>;
census = FamilySquareRootGeneratorCensus[censusAssembly, generatorData];
FTAssert["the root census classifies every radical against the declared generators",
  census["Status"] === "ExactSquareRootGeneratorCensus" &&
    census["UnclassifiedRadicalBases"] === {} &&
    census["MaximumSquareRootGeneratorCount"] === 1 &&
    census["SquareRootGeneratorCountHistogram"] === <|1 -> 1|>];

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

jacobianImage = {
  {{1/(1 + x), y/(1 - x y)}},
  {{x/(1 - y), (1 + x y)/(2 - x)}}};
jacobianMatrix = {{1 + x, y/(1 + x)}, {x/(1 - y), 1 - x y}};
jacobianExpected = {
  Map[Together,
    jacobianImage[[1]] jacobianMatrix[[1, 1]] +
      jacobianImage[[2]] jacobianMatrix[[2, 1]], {2}],
  Map[Together,
    jacobianImage[[1]] jacobianMatrix[[1, 2]] +
      jacobianImage[[2]] jacobianMatrix[[2, 2]], {2}]};
jacobianResult =
  FeynFacet`Private`transportChartParallelJacobianPullBack[
    jacobianImage, jacobianMatrix, "tcjacobiantest"];
FTAssert["recipe-first Jacobian pullback preserves the exact one-form",
  jacobianResult["Status"] === "OK" &&
    jacobianResult["Result"] === jacobianExpected];
expiredJacobian =
  FeynFacet`Private`transportChartParallelJacobianPullBack[
    jacobianImage, jacobianMatrix, "tcjacobiantest_expired",
    AbsoluteTime[] - 1];
FTAssert["recipe-first Jacobian pullback honors an expired deadline",
  expiredJacobian["Status"] === "DeadlineExpired"];

FTReport[];
