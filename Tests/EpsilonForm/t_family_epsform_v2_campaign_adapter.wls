(* The family campaign persists only schema-V2 mathematical records. The
   long-running sector solver's private working association is converted at
   one boundary, after the defining family equation has been validated. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts",
  "family_dlog_epsilon_form_v2.wl"}]];

Clear[v, w, x, y, eps, master];

sourceRepresentation = <|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "SourceVariables" -> {v, w},
  "CoefficientVariables" -> {v, w},
  "SourceVariableSubstitution" -> {v -> v, w -> w},
  "DifferentialPullbackMatrix" -> IdentityMatrix[2]|>;

rootSquares = {
  {},
  {1 + v},
  {1 + v, 1 + w},
  {1 + v, 1 + w, 1 + v + w}
};
presentations = Join[{sourceRepresentation},
  FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
      #, {v, w}, {x, y}] & /@ Rest[rootSquares]];

systemFor[family_] := <|
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family,
  "KinematicVariables" -> {v, w},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {master[family, 1]},
  "ConnectionMatrices" -> {{{eps/v}}, {{eps/w}}}|>;

referenceFor[family_] := <|
  "RelativePath" ->
    FileNameJoin[{"DifferentialEquations", family <> ".wl"}],
  "DataType" -> "FamilyDifferentialSystem",
  "SchemaVersion" -> 2,
  "Family" -> family|>;

workingResultFor[family_, presentation_] := Module[
  {variables, connection},
  variables = Lookup[presentation, "CoefficientVariables",
    Lookup[presentation, "ParametrizingVariables", {v, w}]];
  connection = If[variables === {v, w},
    {{{eps/v}}, {{eps/w}}},
    {{{eps/x}}, {{eps/y}}}];
  <|"Family" -> family,
    "CoefficientPresentation" -> presentation,
    "Variables" -> variables,
    "Regulator" -> eps,
    "Blocks" -> {{1}}, "Ranges" -> {{1}},
    "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
    "EpsFormX" -> connection[[1]],
    "EpsFormY" -> connection[[2]],
    "Letters" -> variables|>
];

results = MapIndexed[
  Function[{presentation, index}, Module[{family},
    family = "SyntheticRootCount" <> ToString[First[index] - 1];
    FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
      workingResultFor[family, presentation], systemFor[family],
      referenceFor[family], "IdentityMethod" -> "Symbolic"]]],
  presentations];

modularResult = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  workingResultFor["SyntheticRootCount0", sourceRepresentation],
  systemFor["SyntheticRootCount0"], referenceFor["SyntheticRootCount0"],
  "IdentityMethod" -> "Modular", "ModularPoints" -> 2,
  "ModularPrimes" -> 1];

rootCounts = Map[
  Length[Lookup[#1["CoefficientPresentation"],
      "SquareRootGenerators", {}]] &, results];

requiredKeys = {"DataType", "SchemaVersion", "Status", "Family",
  "CoefficientPresentation", "CoefficientVariables",
  "DimensionalRegulator", "OriginalMasterIntegralBasis",
  "BlockDecomposition", "BasisTransformationMatrix", "Letters",
  "ConstantResidueMatrices", "Validation"};
privateWorkingKeys = {"Variables", "Regulator", "Blocks", "Ranges",
  "TTotal", "TTotalInverse", "EpsFormX", "EpsFormY", "BasisPermutation",
  "IrreducibleDiagonalBlocks", "ComputationMetrics"};

(* A nontrivial block ordering checks the convention, not merely the schema.
   The worker uses the order {2,1}; the persisted transformation absorbs that
   constant permutation and therefore acts on the original system basis. *)
permutedFamily = "SyntheticPermutation";
permutedSystem = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> permutedFamily, "KinematicVariables" -> {v, w},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" ->
    {master[permutedFamily, 1], master[permutedFamily, 2]},
  "ConnectionMatrices" -> {
    DiagonalMatrix[{eps/v, 2 eps/v}],
    DiagonalMatrix[{3 eps/w, 4 eps/w}]}|>;
permutedWorkingResult = <|
  "Family" -> permutedFamily,
  "CoefficientPresentation" -> sourceRepresentation,
  "Variables" -> {v, w}, "Regulator" -> eps,
  "Blocks" -> {{2}, {1}}, "Ranges" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> DiagonalMatrix[{2 eps/v, eps/v}],
  "EpsFormY" -> DiagonalMatrix[{4 eps/w, 3 eps/w}],
  "Letters" -> {v, w}|>;
permuted = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  permutedWorkingResult, permutedSystem, referenceFor[permutedFamily],
  "IdentityMethod" -> "Symbolic"];
permutationMatrix = {{0, 1}, {1, 0}};
permutedConnection = Table[
  eps Sum[permuted["ConstantResidueMatrices"][[letter]]
      D[Log[permuted["Letters"][[letter]]], {v, w}[[direction]]],
    {letter, Length[permuted["Letters"]]}],
  {direction, 2}];
transformation = permuted["BasisTransformationMatrix"];
inverseTransformation =
  permuted["CachedInverseBasisTransformationMatrix"];
transformationResidual = Table[
  Map[Together,
    inverseTransformation .
      permutedSystem["ConnectionMatrices"][[direction]] . transformation -
      inverseTransformation .
        D[transformation, {v, w}[[direction]]] -
      permutedConnection[[direction]], {2}],
  {direction, 2}];

legacyRefusal =
  FeynFacetCampaign`FamilyDifferentialSystemWorkingViewV2[
    <|"Family" -> "Legacy", "Av" -> {{0}}, "Aw" -> {{0}}|>];
badReference = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  workingResultFor["SyntheticRootCount0", sourceRepresentation],
  systemFor["SyntheticRootCount0"],
  <|"DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
    "Family" -> "SyntheticRootCount0"|>,
  "IdentityMethod" -> "Symbolic"];

tests = <|
  "AllFourRootCountsValidate" ->
    AllTrue[results,
      Lookup[#, "Status", None] === "FamilyDLogEpsilonFormValidated" &&
        FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[#] &&
        TrueQ[Lookup[Lookup[#, "Validation", <||>], "Exact", False]] &&
        ! TrueQ[Lookup[Lookup[#, "Validation", <||>],
          "Probabilistic", True]] &],
  "RootCountsPreserved" -> rootCounts === Range[0, 3],
  "ProductionFiniteFieldStatusIsProbabilistic" ->
    modularResult["Status"] === "FamilyDLogEpsilonFormValidated" &&
      FeynFacet`ValidatedFamilyDLogEpsilonFormQ[modularResult] &&
      ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[modularResult] &&
      modularResult["Validation"]["Method"] ===
        "ProbabilisticFiniteFieldSampling" &&
      TrueQ[modularResult["Validation"]["Probabilistic"]] &&
      ! TrueQ[modularResult["Validation"]["Exact"]],
  "OnlyV2PublicSchemaIsPersisted" -> AllTrue[results,
    ContainsAll[Keys[#], requiredKeys] &&
      Intersection[Keys[#], privateWorkingKeys] === {} &],
  "BlockReferenceIsExplicit" -> AllTrue[results,
    Lookup[#1["BlockDecomposition"], "FamilyDifferentialSystemReference",
      <||>]["Family"] === #1["Family"] &],
  "PermutationAbsorbedIntoTransformation" ->
    transformation === permutationMatrix &&
      inverseTransformation === permutationMatrix &&
      permuted["OriginalMasterIntegralBasis"] ===
        permutedSystem["OriginalMasterIntegralBasis"] &&
      permuted["BlockDecomposition"]["IrreducibleDiagonalBlocks"] ===
        {{2}, {1}} &&
      Union[Flatten[transformationResidual]] === {0},
  "LegacySystemRefused" ->
    legacyRefusal["Status"] ===
      "LegacyDifferentialEquationSchemaUnsupported",
  "IncompleteReferenceRefused" ->
    badReference["Status"] ===
      "FamilyDifferentialSystemReferenceInvalid"
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
