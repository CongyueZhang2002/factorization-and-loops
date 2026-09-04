#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

sourceV = Symbol["Global`geometryVocabularySourceV"];
sourceW = Symbol["Global`geometryVocabularySourceW"];
coefficientX = Symbol["Global`geometryVocabularyCoefficientX"];
coefficientY = Symbol["Global`geometryVocabularyCoefficientY"];

lambda1[v_, w_] := (1 - v - w)^2 - 4 v w;
lambda3[v_, w_] := (1 - v + w)^2 + 4 v w;

catalog = FeynFacet`RationalizingParametrizationCatalog[];
kallen1 = catalog["Kallen1"];
kallen1Verification =
  FeynFacet`VerifyRationalizingParametrization[kallen1];

FTAssert["catalog entries use only the rationalizing-parametrization schema",
  AssociationQ[kallen1] &&
    kallen1["DataType"] === "RationalizingParametrization" &&
    kallen1["SchemaVersion"] === 2 &&
    Intersection[Keys[kallen1],
      {"Variables", "Subst", "Root", "RootSquare", "Roots", "Parents",
       "ParentCharts", "ChartCertificate"}] === {} &&
    MatchQ[kallen1["ParametrizingVariables"], {_Symbol, _Symbol}] &&
    MatchQ[kallen1["SourceVariableSubstitution"], {_Rule, _Rule}] &&
    ListQ[kallen1["RationalizedSquareRoots"]]];

FTAssert["forward verification does not claim a rational inverse or birationality",
  kallen1Verification["Status"] ===
      "RationalizingParametrizationVerified" &&
    TrueQ[kallen1Verification["Verified"]] &&
    AllTrue[kallen1Verification["SourceCoordinateImagesRational"], TrueQ] &&
    AllTrue[kallen1Verification["RationalizedRootImagesRational"], TrueQ] &&
    AllTrue[kallen1Verification["RationalizedSquareRootIdentities"], TrueQ] &&
    kallen1Verification["RationalInverseVerified"] === False &&
    kallen1Verification["BirationalityVerified"] === False];

FTAssert["every catalogued forward parametrization verifies",
  AllTrue[Values[catalog],
    TrueQ[FeynFacet`VerifyRationalizingParametrization[#]["Verified"]] &]];

nonRationalRootRecord = <|
  "DataType" -> "RationalizingParametrization",
  "SchemaVersion" -> 2,
  "Status" -> "RationalizingParametrizationDeclared",
  "Name" -> "NotARationalizingParametrization",
  "Kind" -> "TwoVariable",
  "SourceVariables" -> {sourceV, sourceW},
  "ParametrizingVariables" -> {coefficientX, coefficientY},
  "SourceVariableSubstitution" ->
    {sourceV -> coefficientX, sourceW -> coefficientY},
  "RationalizedSquareRoots" -> {
    <|"RationalRoot" -> Sqrt[lambda1[coefficientX, coefficientY]],
      "SourceRadicand" -> lambda1[sourceV, sourceW]|>},
  "ParentParametrizationMaps" -> <||>,
  "ParentParametrizations" -> <||>
|>;
nonRationalRootVerification =
  FeynFacet`VerifyRationalizingParametrization[nonRationalRootRecord];
FTAssert["a square-root expression is not accepted as a rationalized root",
  nonRationalRootVerification["Status"] ===
      "RationalizingParametrizationVerificationFailed" &&
    nonRationalRootVerification["RationalizedRootImagesRational"] ===
      {False}];

legacyParametrizationVerification =
  FeynFacet`VerifyRationalizingParametrization[<|
    "Name" -> "LegacyParametrization",
    "Variables" -> {coefficientX, coefficientY},
    "Subst" -> {sourceV -> coefficientX, sourceW -> coefficientY},
    "Roots" -> {
      <|"Root" -> coefficientX, "RootSquare" -> sourceV^2|>}
  |>];
FTAssert["a V1 parametrization is refused typed rather than converted",
  legacyParametrizationVerification["Status"] ===
      "LegacyCoefficientPresentationSchemaUnsupported" &&
    legacyParametrizationVerification["Verified"] === False];

known = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {lambda1[sourceV, sourceW], lambda3[sourceV, sourceW]},
  {sourceV, sourceW}];
miss = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
  {lambda1[sourceV, sourceW], 1 + sourceV^3}, {sourceV, sourceW}];
FTAssert["root-set lookup returns a catalogued rationalizing parametrization",
  AssociationQ[known] && known["Name"] === "Kallen13"];
FTAssert["a catalog miss is represented only as absence from the catalog",
  MatchQ[miss,
    Missing["NoCataloguedRationalizingParametrization", _]] &&
    ! MatchQ[miss, Missing["NoRationalizingParametrization", _]]];

generatorData =
  FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
    {sourceV, sourceV}, {sourceV, sourceW},
    {coefficientX, coefficientY}];
generators = Lookup[generatorData["SquareRootGenerators"],
  "Generator"];
formalSignChoices = Tuples[{1, -1}, Length[generators]];
formalSignChangeImages =
  MapThread[Times, {#, generators}] & /@ formalSignChoices;
dependencyCompatibleImages = Select[formalSignChangeImages,
  TrueQ[Together[#[[1]] - #[[2]]] === 0] &];

FTAssert["the constructor emits generators and quadratic relations, not a frame or field",
  generatorData["DataType"] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
    generatorData["SchemaVersion"] === 2 &&
    generatorData["Status"] === "SquareRootGeneratorRelationsVerified" &&
    Length[generatorData["SquareRootGenerators"]] === 2 &&
    AllTrue[generatorData["SquareRootGenerators"],
      Sort[Keys[#]] ===
        Sort[{"Generator", "QuadraticRadicand", "SourceRadicand"}] &] &&
    generatorData["QuadraticRelationVerification", "PerGenerator"] ===
      {True, True} &&
    Intersection[Keys[generatorData],
      {"Frame", "FieldKind", "CoefficientField", "Roots",
       "ChartCertificate", "GaloisConjugates", "QuadraticRelations",
       "GeneratorOrdering", "GeneratorExpression", "GeneratorIndex"}] === {}];

FTAssert["formal generator sign changes are not certified as Galois conjugates",
  Length[formalSignChangeImages] === 4 &&
    Length[dependencyCompatibleImages] === 2 &&
    generatorData["SquareClassIndependenceStatus"] === "NotChecked" &&
    generatorData["SquareClassIndependenceVerified"] === False &&
    generatorData["SignChangeImageInterpretation"] ===
      "FormalGeneratorSignChangesOnly" &&
    generatorData["GaloisConjugatesCertified"] === False];

secondConstructorOutput = BuildSquareRootGeneratorsAndQuadraticRelations[
  {sourceV}, {sourceV, sourceW}, {coefficientX, coefficientY}];
secondLookupMiss = LookupCataloguedRationalizingParametrizationForRoots[
  {lambda1[sourceV, sourceW], 1 + sourceV^3}, {sourceV, sourceW}];
FTAssert["public constructors emit only the V2 vocabulary",
  secondConstructorOutput["SchemaVersion"] === 2 &&
    secondConstructorOutput["Status"] ===
      "SquareRootGeneratorRelationsVerified" &&
    Intersection[Keys[secondConstructorOutput],
      {"Frame", "FieldKind", "CoefficientField", "Roots",
       "ChartCertificate"}] === {} &&
    MatchQ[secondLookupMiss,
      Missing["NoCataloguedRationalizingParametrization", _]]];

legacyGeneratorPresentation = <|
  "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
  "SchemaVersion" -> 1,
  "SourceVariables" -> {sourceV, sourceW},
  "CoefficientVariables" -> {coefficientX, coefficientY},
  "SourceToCoefficientVariableRules" ->
    {sourceV -> coefficientX, sourceW -> coefficientY},
  "SquareRootGenerators" -> {
    <|"GeneratorIndex" -> 1,
      "GeneratorExpression" -> Sqrt[coefficientX],
      "QuadraticRadicand" -> coefficientX,
      "SourceRadicand" -> sourceV|>},
  "QuadraticRelations" -> {
    <|"GeneratorIndex" -> 1,
      "GeneratorExpression" -> Sqrt[coefficientX],
      "QuadraticRadicand" -> coefficientX|>}
|>;
legacyGeneratorResult =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    legacyGeneratorPresentation, {sourceV, sourceW}];
FTAssert["a V1 generator record is refused rather than normalized",
  legacyGeneratorResult["Status"] ===
    "LegacyCoefficientPresentationSchemaUnsupported"];

staleProjectRegistration = FeynFacet`RegisterFamilyRootData[<|
  "CF300" -> <|"RootSquares" ->
    {lambda1[sourceV, sourceW], lambda3[sourceV, sourceW]}|>|>];

FTAssert["a V1 project root-data artifact is refused typed and not installed",
  staleProjectRegistration["Status"] === "InvalidFamilyRootDataEntries" &&
    staleProjectRegistration["Invalid", "CF300", "Status"] ===
      "LegacyFamilyRootDataSchemaUnsupported" &&
    MissingQ[FeynFacet`FamilyRootData["CF300"]]];

FTReport[];
