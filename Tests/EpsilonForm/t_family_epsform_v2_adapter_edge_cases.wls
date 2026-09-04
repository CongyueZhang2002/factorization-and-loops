(* Focused edge cases for the script-side V2 family epsilon-form boundary. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts",
  "family_dlog_epsilon_form_v2.wl"}]];

Clear[v, w, x, y, eps, delta, master];

sourceRepresentation = <|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "SourceVariables" -> {v, w},
  "CoefficientVariables" -> {v, w},
  "SourceVariableSubstitution" -> {v -> v, w -> w},
  "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>;

systemFor[family_, regulator_, basis_, connections_] := <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family,
  "KinematicVariables" -> {v, w},
  "DimensionalRegulator" -> regulator,
  "OriginalMasterIntegralBasis" -> basis,
  "ConnectionMatrices" -> connections|>;

referenceFor[family_] := <|
  "RelativePath" ->
    FileNameJoin[{"DifferentialEquations", family <> ".wl"}],
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family|>;

scalarWorking[family_, regulator_, presentation_, connections_] := <|
  "Family" -> family,
  "CoefficientPresentation" -> presentation,
  "Variables" -> Lookup[presentation, "CoefficientVariables", {v, w}],
  "Regulator" -> regulator,
  "Blocks" -> {{1}}, "Ranges" -> {{1}},
  "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
  "EpsFormX" -> connections[[1]],
  "EpsFormY" -> connections[[2]],
  "Letters" -> Lookup[presentation, "CoefficientVariables", {v, w}]|>;

(* The dimensional regulator is data, not a spelling convention. *)
nonEpsFamily = "SyntheticNonEpsRegulator";
nonEpsConnections = {{{delta/v}}, {{delta/w}}};
nonEpsSystem = systemFor[nonEpsFamily, delta,
  {master[nonEpsFamily, 1]}, nonEpsConnections];
nonEpsView =
  FeynFacetCampaign`FamilyDifferentialSystemWorkingViewV2[nonEpsSystem];
nonEpsResult = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  scalarWorking[nonEpsFamily, delta, sourceRepresentation,
    nonEpsConnections],
  nonEpsSystem, referenceFor[nonEpsFamily],
  "IdentityMethod" -> "Symbolic"];

(* Every defining field of the unchanged-source presentation is checked
   before the adapter translates it to the validator's private None form. *)
malformedPresentations = {
  Join[sourceRepresentation, <|"SchemaVersion" -> 1|>],
  Join[sourceRepresentation, <|"SourceVariables" -> {w, v}|>],
  Join[sourceRepresentation, <|"CoefficientVariables" -> {x, y}|>],
  Join[sourceRepresentation,
    <|"SourceVariableSubstitution" -> {v -> w, w -> v}|>],
  Join[sourceRepresentation,
    <|"DifferentialPullbackMatrix" -> {{0, 1}, {1, 0}}|>]
};
malformedResults = Map[
  FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
    scalarWorking[nonEpsFamily, delta, #, nonEpsConnections],
    nonEpsSystem, referenceFor[nonEpsFamily],
    "IdentityMethod" -> "Symbolic"] &,
  malformedPresentations];

(* A three-cycle distinguishes P from Transpose[P]. *)
cycleFamily = "SyntheticNonInvolutivePermutation";
cyclePermutation = {2, 3, 1};
cycleMatrix = IdentityMatrix[3][[cyclePermutation]];
cycleSystem = systemFor[cycleFamily, eps,
  Table[master[cycleFamily, row], {row, 3}], {
    DiagonalMatrix[eps {1, 2, 3}/v],
    DiagonalMatrix[eps {4, 5, 6}/w]}];
cycleWorking = <|
  "Family" -> cycleFamily,
  "CoefficientPresentation" -> sourceRepresentation,
  "Variables" -> {v, w}, "Regulator" -> eps,
  "Blocks" -> (List /@ cyclePermutation),
  "Ranges" -> (List /@ Range[3]),
  "TTotal" -> IdentityMatrix[3],
  "TTotalInverse" -> IdentityMatrix[3],
  "EpsFormX" -> cycleMatrix .
    cycleSystem["ConnectionMatrices"][[1]] . Transpose[cycleMatrix],
  "EpsFormY" -> cycleMatrix .
    cycleSystem["ConnectionMatrices"][[2]] . Transpose[cycleMatrix],
  "Letters" -> {v, w}|>;
cycleResult = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  cycleWorking, cycleSystem, referenceFor[cycleFamily],
  "IdentityMethod" -> "Symbolic"];
cycleTransformation = Lookup[cycleResult,
  "BasisTransformationMatrix", $Failed];
cycleInverse = Lookup[cycleResult,
  "CachedInverseBasisTransformationMatrix", $Failed];
cycleDLogConnection = If[MatrixQ[cycleTransformation],
  Table[eps Total[MapThread[
      D[#1, {v, w}[[direction]]]/#1 Normal[#2] &,
      {cycleResult["Letters"],
        cycleResult["ConstantResidueMatrices"]}]],
    {direction, 2}], $Failed];
cycleResidual = If[ListQ[cycleDLogConnection],
  Table[Map[Together,
    cycleInverse . cycleSystem["ConnectionMatrices"][[direction]] .
        cycleTransformation -
      cycleInverse . D[cycleTransformation, {v, w}[[direction]]] -
      cycleDLogConnection[[direction]], {2}],
    {direction, 2}], $Failed];

(* Exercise the production multiquadratic branch with letters that genuinely
   use every declared root, not merely presentations carrying inert roots. *)
rootSquares = {
  {1 + v},
  {1 + v, 1 + w},
  {1 + v, 1 + w, 1 + v + w}
};
rootPresentations =
  FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
      #, {v, w}, {x, y}] & /@ rootSquares;
rootResults = MapIndexed[Function[{presentation, index}, Module[
    {count = First[index], family, sourceLetters, coefficientLetters,
     connections, working},
    family = "SyntheticActiveRootCount" <> ToString[count];
    sourceLetters = (1 + Sqrt[#] &) /@ rootSquares[[count]];
    coefficientLetters = sourceLetters /. {v -> x, w -> y};
    connections = Table[{{eps Total[
        D[Log[#], {v, w}[[direction]]] & /@ sourceLetters]}},
      {direction, 2}];
    working = <|
      "Family" -> family,
      "CoefficientPresentation" -> presentation,
      "Variables" -> {x, y}, "Regulator" -> eps,
      "Blocks" -> {{1}}, "Ranges" -> {{1}},
      "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
      "EpsFormX" -> {{eps Total[
        D[Log[#], x] & /@ coefficientLetters]}},
      "EpsFormY" -> {{eps Total[
        D[Log[#], y] & /@ coefficientLetters]}},
      "Letters" -> coefficientLetters|>;
    FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
      working,
      systemFor[family, eps, {master[family, 1]}, connections],
      referenceFor[family], "IdentityMethod" -> "Modular"]]],
  rootPresentations];
rootEvidence = Lookup[Lookup[#, "Validation", <||>],
    "SamplingEvidence", <||>] & /@ rootResults;

tests = <|
  "DeclaredNonEpsRegulatorIsPreserved" ->
    Lookup[nonEpsView, "Regulator", Missing[]] === delta &&
      Lookup[nonEpsResult, "Status", None] ===
        "FamilyDLogEpsilonFormValidated" &&
      Lookup[nonEpsResult, "DimensionalRegulator", Missing[]] === delta,
  "MalformedSourceRepresentationsAreRefused" ->
    AllTrue[malformedResults,
      Lookup[#, "Status", None] ===
        "SourceVariableRepresentationInvalid" &],
  "NonInvolutivePermutationIsAbsorbed" ->
    cycleTransformation === Transpose[cycleMatrix] &&
      cycleInverse === cycleMatrix &&
      ListQ[cycleResidual] && Union[Flatten[cycleResidual]] === {0},
  "ActiveOneTwoThreeRootModularValidation" ->
    And @@ MapIndexed[
      Lookup[#1, "Status", None] ===
          "FamilyDLogEpsilonFormValidated" &&
        Lookup[Lookup[#1, "Validation", <||>], "Method", None] ===
          "ProbabilisticFiniteFieldSampling" &&
        Lookup[rootEvidence[[First[#2]]], "RootCount", None] ===
          First[#2] &&
        Lookup[rootEvidence[[First[#2]]], "RootIndicesUsed", None] ===
          Range[First[#2]] &&
        TrueQ[Lookup[rootEvidence[[First[#2]]],
          "AllRootSheetsChecked", False]] &,
      rootResults]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests],
  Print["ROOT STATUSES: ", InputForm[Lookup[rootResults, "Status"]]];
  Print["MALFORMED STATUSES: ",
    InputForm[Lookup[malformedResults, "Status"]]];
  Exit[1]];
