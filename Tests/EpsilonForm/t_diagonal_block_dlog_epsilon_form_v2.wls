#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

CloseKernels[];

Clear[vBlockV2, wBlockV2, xBlockV2, yBlockV2, tBlockV2,
  epsBlockV2, masterBlockV2];
v = vBlockV2; w = wBlockV2;
x = xBlockV2; y = yBlockV2; t = tBlockV2;
eps = epsBlockV2;

exactFlatness = <|
  "Status" -> "ConnectionFlatnessValidated",
  "Accepted" -> True,
  "Method" -> "CharacteristicZeroSymbolicIdentity",
  "Exact" -> True,
  "Probabilistic" -> False|>;

makeSystem[family_String, matrices_List] := Module[{dimension},
  dimension = Length[First[matrices]];
  <|
    "DataType" -> "FamilyDifferentialSystem",
    "SchemaVersion" -> 2,
    "Status" -> "FamilyDifferentialSystemValidated",
    "Family" -> family,
    "KinematicVariables" -> {v, w},
    "DimensionalRegulator" -> eps,
    "OriginalMasterIntegralBasis" ->
      Table[masterBlockV2[family, row], {row, dimension}],
    "ConnectionMatrices" -> matrices,
    "Validation" -> <|"ConnectionFlatness" -> exactFlatness|>|>
];

sourcePresentation = <|
  "DataType" -> "SourceVariableRepresentation",
  "SchemaVersion" -> 2,
  "Status" -> "CoefficientPresentationValidated",
  "SourceVariables" -> {v, w},
  "CoefficientVariables" -> {v, w},
  "SourceVariableSubstitution" -> {v -> v, w -> w},
  "DifferentialPullbackMatrix" -> IdentityMatrix[2],
  "JacobianDeterminant" -> 1|>;

FTAssert["the V2 diagonal-block API is exported",
  StringQ[ConstructDiagonalBlockDLogEpsilonForm::usage] &&
    StringQ[DiagonalBlockDLogEpsilonFormQ::usage] &&
    DownValues[ConstructDiagonalBlockDLogEpsilonForm] =!= {} &&
    DownValues[DiagonalBlockDLogEpsilonFormQ] =!= {}];

scalarSystem = makeSystem["DiagonalBlockScalarToy",
  {{{eps/v}}, {{eps/w}}}];
scalar = ConstructDiagonalBlockDLogEpsilonForm[
  scalarSystem, sourcePresentation, {1},
  "FiniteFieldPrimes" -> {1019, 1031},
  "PointsPerPrime" -> 2,
  "Seed" -> 1103];

expectedKeys = {"DataType", "SchemaVersion", "BlockRows",
  "CoefficientVariables", "DimensionalRegulator",
  "BasisTransformationMatrix", "Letters", "ConstantResidueMatrices",
  "Status", "Validation"};
FTAssert["automatic scalar construction emits only the V2 mathematical record",
  Sort[Keys[scalar]] === Sort[expectedKeys] &&
    scalar["DataType"] === "DiagonalBlockDLogEpsilonForm" &&
    scalar["Status"] === "DLogEpsilonFormValidated" &&
    scalar["BlockRows"] === {1} &&
    scalar["CoefficientVariables"] === {v, w} &&
    scalar["DimensionalRegulator"] === eps &&
    scalar["BasisTransformationMatrix"] === {{1}} &&
    scalar["Validation", "CandidateProvenance", "Type"] ===
      "ReexpressedDiagonalBlockEpsFormCandidateConstruction" &&
    scalar["Validation", "CandidateProvenance", "ConstructionPrimes"] === {} &&
    FreeQ[Keys[scalar],
      "EpsForm" | "CachedTransformedConnectionMatrices" |
      "CachedInverseBasisTransformationMatrix" | "Hash" | "SHA256"]];

FTAssert["default production validation is bounded and honestly probabilistic",
  scalar["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling" &&
    ! TrueQ[scalar["Validation", "Exact"]] &&
    TrueQ[scalar["Validation", "Probabilistic"]] &&
    Length[scalar["Validation", "Samples"]] === 4 &&
    AllTrue[scalar["Validation", "Samples"],
      #1["SquareRootSheetCount"] === 1 &&
        TrueQ[#1["AllSquareRootSheetsChecked"]] &] &&
    DiagonalBlockDLogEpsilonFormQ[
      scalar, scalarSystem, sourcePresentation]];

legacyScalar = DiagonalBlockEpsForm[
  scalarSystem["ConnectionMatrices"], {v, w}, eps];
candidateOnlyScalar = DiagonalBlockEpsForm[
  scalarSystem["ConnectionMatrices"], {v, w}, eps,
  "ReturnCandidateBeforeCertification" -> True];
FTAssert["legacy exact acceptance remains the default and the V2 candidate route is opt-in",
  legacyScalar["Status"] === "Certified" &&
    legacyScalar["Gate", "Status"] === "Certified" &&
    candidateOnlyScalar["Status"] === "CandidateConstructed" &&
    ! KeyExistsQ[candidateOnlyScalar, "Gate"] &&
    ("ReturnCandidateBeforeCertification" /.
        Options[DiagonalBlockEpsForm]) === False &&
    ("ReturnCandidateBeforeExactEquationCheck" /.
        Options[SolveDiagonalBlockBasisTransformationFiniteField]) === False &&
    Intersection[
      ("FiniteFieldPrimes" /.
        Options[ConstructDiagonalBlockDLogEpsilonForm]),
      ("Primes" /.
        Options[SolveDiagonalBlockBasisTransformationFiniteField])] === {}];

automaticRx = {{1, 1}, {0, 0}};
automaticRy = {{0, 0}, {1, 1}};
automaticRvw = -(automaticRx + automaticRy);
automaticNonScalarSystem = makeSystem[
  "DiagonalBlockAutomaticNonScalarToy", {
    eps (automaticRx/v + automaticRvw/(v - w)),
    eps (automaticRy/w - automaticRvw/(v - w))}];
automaticNonScalar = ConstructDiagonalBlockDLogEpsilonForm[
  automaticNonScalarSystem, sourcePresentation, {1, 2},
  "FiniteFieldPrimes" -> {1019, 1031},
  "PointsPerPrime" -> 1, "Seed" -> 1451];
automaticConstructionPrimes = Lookup[
  Lookup[automaticNonScalar, "Validation", <||>],
  "CandidateProvenance", <||>]["ConstructionPrimes"];
FTAssert["automatic non-scalar construction stabilizes before an independent modular gate",
  automaticNonScalar["Status"] === "DLogEpsilonFormValidated" &&
    automaticNonScalar["Validation", "CandidateProvenance", "Type"] ===
      "ReexpressedDiagonalBlockEpsFormCandidateConstruction" &&
    MatchQ[automaticConstructionPrimes, {__Integer}] &&
    Length[automaticConstructionPrimes] >= 2 &&
    Intersection[automaticConstructionPrimes,
      automaticNonScalar["Validation", "Primes"]] === {} &&
    DiagonalBlockDLogEpsilonFormQ[automaticNonScalar,
      automaticNonScalarSystem, sourcePresentation]];

permutedSystem = makeSystem["DiagonalBlockPermutedRowsToy", {
  DiagonalMatrix[{eps/v, 0, 2 eps/v}],
  DiagonalMatrix[{0, 3 eps/w, eps/w}]}];
permutation = {{0, 1}, {1, 0}};
permutedCandidate = <|
  "DataType" -> "DiagonalBlockDLogEpsilonForm",
  "SchemaVersion" -> 2,
  "BlockRows" -> {3, 1},
  "CoefficientVariables" -> {v, w},
  "DimensionalRegulator" -> eps,
  "BasisTransformationMatrix" -> permutation,
  "Letters" -> {v, w},
  "ConstantResidueMatrices" -> {
    DiagonalMatrix[{1, 2}], DiagonalMatrix[{0, 1}]}|>;
permuted = ConstructDiagonalBlockDLogEpsilonForm[
  permutedSystem, sourcePresentation, {3, 1},
  "CandidateDiagonalBlockDLogEpsilonForm" -> permutedCandidate,
  "FiniteFieldPrimes" -> {1019}, "PointsPerPrime" -> 2,
  "Seed" -> 1907];

FTAssert["noncontiguous row order and nontrivial block permutation are preserved",
  permuted["BlockRows"] === {3, 1} &&
    permuted["BasisTransformationMatrix"] === permutation &&
    permuted["ConstantResidueMatrices"] ===
      permutedCandidate["ConstantResidueMatrices"] &&
    DiagonalBlockDLogEpsilonFormQ[
      permuted, permutedSystem, sourcePresentation]];

symbolic = ConstructDiagonalBlockDLogEpsilonForm[
  permutedSystem, sourcePresentation, {3, 1},
  "CandidateDiagonalBlockDLogEpsilonForm" -> permutedCandidate,
  "ValidationMethod" -> "CharacteristicZeroSymbolicIdentity"];
FTAssert["characteristic-zero validation is an explicit development route",
  symbolic["Status"] === "DLogEpsilonFormValidated" &&
    symbolic["Validation", "Method"] ===
      "CharacteristicZeroSymbolicIdentity" &&
    TrueQ[symbolic["Validation", "Exact"]] &&
    ! TrueQ[symbolic["Validation", "Probabilistic"]] &&
    DiagonalBlockDLogEpsilonFormQ[
      symbolic, permutedSystem, sourcePresentation]];

rationalizingSystem = makeSystem["DiagonalBlockRationalizingToy", {{
    {eps/(2 v)}}, {{0}}}];
radicalSystem = makeSystem["DiagonalBlockRadicalToy", {{
    {eps/(2 Sqrt[v] (1 + Sqrt[v]))}}, {{0}}}];
rationalizingPresentation = <|
  "DataType" -> "RationalizingParametrization",
  "SchemaVersion" -> 2,
  "Status" -> "CoefficientPresentationValidated",
  "Name" -> "SquareCoordinateToy",
  "Kind" -> "TwoVariable",
  "SourceVariables" -> {v, w},
  "ParametrizingVariables" -> {x, y},
  "SourceVariableSubstitution" -> {v -> x^2, w -> y},
  "RationalizedSquareRoots" -> {<|
    "RationalRoot" -> x, "SourceRadicand" -> v|>},
  "ParentParametrizationMaps" -> <||>,
  "ParentParametrizations" -> <||>|>;
rationalized = ConstructDiagonalBlockDLogEpsilonForm[
  rationalizingSystem, rationalizingPresentation, {1},
  "FiniteFieldPrimes" -> {1019}, "PointsPerPrime" -> 2,
  "Seed" -> 2203];

FTAssert["a source-variable candidate is reexpressed in a rationalizing presentation",
  rationalized["Status"] === "DLogEpsilonFormValidated" &&
    rationalized["CoefficientVariables"] === {x, y} &&
    Length[rationalized["Letters"]] === 1 &&
    TrueQ[Together[First[rationalized["Letters"]] - x^2] === 0] &&
    rationalized["ConstantResidueMatrices"] === {{{1/2}}} &&
    DiagonalBlockDLogEpsilonFormQ[
      rationalized, rationalizingSystem, rationalizingPresentation]];

squareRootPresentation = <|
  "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
  "SchemaVersion" -> 2,
  "Status" -> "CoefficientPresentationValidated",
  "SourceVariables" -> {v, w},
  "CoefficientVariables" -> {x, y},
  "SourceToCoefficientVariableRules" -> {v -> x, w -> y},
  "SquareRootGenerators" -> {<|
    "Generator" -> Sqrt[x], "QuadraticRadicand" -> x,
    "SourceRadicand" -> v|>},
  "QuadraticRelationVerification" -> <|"Verified" -> True|>,
  "SquareClassIndependenceStatus" -> "NotChecked"|>;
localCandidate = <|
  "Status" -> "Certified",
  "Transformation" -> {{1}},
  "Letters" -> {1 + t},
  "Residues" -> {{{1}}},
  "Variables" -> {w, t},
  "Regulator" -> eps,
  "Method" -> "ScalarDLog",
  "Chart" -> <|"Fixed" -> w, "Subst" -> (v -> t^2),
    "Root" -> t, "Branch" -> "LinearSolve"|>,
  "SourceVariables" -> {v, w},
  "Gate" -> <|
    "Status" -> "Certified", "GateX" -> True, "GateY" -> True,
    "ConstantResidues" -> True, "LettersEpsFree" -> True,
    "Flat" -> True, "Invertible" -> True|>|>;
squareRoot = ConstructDiagonalBlockDLogEpsilonForm[
  radicalSystem, squareRootPresentation, {1},
  "CandidateDiagonalBlockDLogEpsilonForm" -> localCandidate,
  "FiniteFieldPrimes" -> {1019, 1031},
  "PointsPerPrime" -> 2, "Seed" -> 2909];
selectedPresentationData =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    squareRootPresentation, {v, w}];
selectedCoordinateMap =
  FeynFacet`Private`masterTransportRecordCoordinateMap[
    squareRoot, selectedPresentationData];

FTAssert["a local rationalizing result is composed into the family square-root presentation",
  squareRoot["Status"] === "DLogEpsilonFormValidated" &&
    squareRoot["CoefficientVariables"] === {x, y} &&
    squareRoot["Letters"] === {1 + Sqrt[x]} &&
    squareRoot["ConstantResidueMatrices"] === {{{1}}} &&
    squareRoot["Validation", "CandidateProvenance", "Type"] ===
      "ReexpressedLocalDiagonalBlockEpsFormExactGate" &&
    selectedCoordinateMap["Status"] === "OK" &&
    selectedCoordinateMap["CoefficientVariableRules"] ===
      {x -> x, y -> y}];

FTAssert["every stored algebraic sample checks both square-root sheets and replays",
  Length[squareRoot["Validation", "Samples"]] === 4 &&
    AllTrue[squareRoot["Validation", "Samples"],
      #1["SquareRootSheetCount"] === 2 &&
        TrueQ[#1["AllSquareRootSheetsChecked"]] &] &&
    DiagonalBlockDLogEpsilonFormQ[
      squareRoot, radicalSystem, squareRootPresentation]];

FTAssert["tampered mathematics and tampered replay points are rejected",
  ! DiagonalBlockDLogEpsilonFormQ[
      ReplacePart[permuted,
        {"ConstantResidueMatrices", 1, 1, 1} -> 7],
      permutedSystem, sourcePresentation] &&
    ! DiagonalBlockDLogEpsilonFormQ[
      ReplacePart[squareRoot,
        {"Validation", "Samples", 1,
          "SquareRootGeneratorBaseValues", 1} -> 0],
      radicalSystem, squareRootPresentation] &&
    ! DiagonalBlockDLogEpsilonFormQ[
      ReplacePart[squareRoot,
        {"Validation", "Primes", 1} -> 1031],
      radicalSystem, squareRootPresentation]];

rootDependentResidue = ConstructDiagonalBlockDLogEpsilonForm[
  radicalSystem, squareRootPresentation, {1},
  "CandidateDiagonalBlockDLogEpsilonForm" ->
    ReplacePart[squareRoot,
      "ConstantResidueMatrices" -> {{{Sqrt[x]}}}],
  "FiniteFieldPrimes" -> {1019}, "PointsPerPrime" -> 1];
FTAssert["constant residues cannot depend on a declared square-root generator",
  rootDependentResidue["Status"] ===
      "DiagonalBlockDLogEpsilonFormValidationFailed" &&
    ! TrueQ[rootDependentResidue[
      "Validation", "Conditions", "ConstantResidueMatrices"]]];

FTAssert["malformed systems, presentations, rows, and local gates are typed refusals",
  ConstructDiagonalBlockDLogEpsilonForm[
      KeyDrop[scalarSystem, "Validation"], sourcePresentation, {1}][
        "Status"] === "FamilyDifferentialSystemNotWellFormed" &&
    ConstructDiagonalBlockDLogEpsilonForm[
      scalarSystem, sourcePresentation, {1, 1}]["Status"] ===
        "BlockRowsInvalid" &&
    ConstructDiagonalBlockDLogEpsilonForm[
      scalarSystem,
      ReplacePart[sourcePresentation, "Status" -> "Unvalidated"], {1}][
        "Status"] === "CoefficientPresentationNotValidated" &&
    ConstructDiagonalBlockDLogEpsilonForm[
      radicalSystem, squareRootPresentation, {1},
      "CandidateDiagonalBlockDLogEpsilonForm" ->
        ReplacePart[localCandidate,
          {"Gate", "GateX"} -> False]]["Status"] ===
      "CandidateDiagonalBlockDLogEpsilonFormNotWellFormed"];

cliSource = Import[FileNameJoin[{root, "Scripts", "DifferentialEquations",
  "build_diagonal_block_dlog_epsilon_form_v2.wls"}], "Text"];
FTAssert["the file producer requires explicit paths and rows without project dispatch",
  AllTrue[{"--family-differential-system", "--coefficient-presentation",
      "--block-rows", "--output"}, StringContainsQ[cliSource, #] &] &&
    ! AnyTrue[{"CF303", "ClassID", "FileBaseName", "SHA256", "Hash"},
      StringContainsQ[cliSource, #] &]];

FTAssert["the focused producer opens no subkernels",
  $KernelCount === 0];

FTReport[];
