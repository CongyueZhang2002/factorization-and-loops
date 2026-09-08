#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 6 || Length[arguments] > 9,
  Print["CF300S12R2PRIME FAIL usage=<project-root> <preparation.wl> <output.wl> <prime> <discover|reuse> <plan-source-or-dash> [sample-count] [construction-count] [maximum-total-degree]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
preparationFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
parseStrictInteger[text_String] := Module[{digits, negative},
  If[! StringMatchQ[text,
      RegularExpression["0|-?[1-9][0-9]*"]], Return[$Failed]];
  negative = StringStartsQ[text, "-"];
  digits = If[negative, StringDrop[text, 1], text];
  If[negative, -FromDigits[digits], FromDigits[digits]]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
prime = parseStrictInteger[arguments[[4]]];
planMode = arguments[[5]];
planSourceToken = arguments[[6]];
planSourceFile = If[planMode === "reuse",
  ExpandFileName[planSourceToken], None];
sampleCount = If[Length[arguments] >= 7,
  parseStrictInteger[arguments[[7]]], 48];
constructionCount = If[Length[arguments] >= 8,
  parseStrictInteger[arguments[[8]]], 24];
maximumTotalDegree = If[Length[arguments] >= 9,
  parseStrictInteger[arguments[[9]]], 22];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet",
    "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{
    exchangeDirectory, "TripleRootReconstructionPrototype.wl"}]|>;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! PrimeQ[prime] || !(2 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
    ! MemberQ[{"discover", "reuse"}, planMode] ||
    (planMode === "discover" && planSourceToken =!= "-") ||
    (planMode === "reuse" &&
      (planSourceToken === "-" || ! FileExistsQ[planSourceFile])) ||
    ! IntegerQ[sampleCount] || sampleCount < 8 ||
    ! IntegerQ[constructionCount] || constructionCount < 1 ||
    sampleCount < constructionCount + 4 ||
    ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0 ||
    FileExistsQ[outputFile] || FileExistsQ[outputFile <> ".tmp"],
  Print["CF300S12R2PRIME FAIL invalid or stale target"];
  Exit[65]];

prototypeFile = FileNameJoin[{exchangeDirectory,
  "TripleRootReconstructionPrototype.wl"}];
preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
prototypeHashBefore =
  dependencyHashesBefore["TripleRootReconstructionPrototype"];
planSourceHashBefore = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];

Get[dependencyFiles["LoadFACET"]];
Get[dependencyFiles["TripleRootAlgebra"]];
Get[dependencyFiles["TripleRootStripAdapter"]];
Get[dependencyFiles["TripleRootAffinePilot"]];
Get[prototypeFile];
dependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashAfterLoad = FileHash[$InputFileName, "SHA256", "HexString"];

writeAtomic[value_] := Module[{temporary = outputFile <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""], written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
      OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];

writeAndExit[value_, code_Integer] := If[writeAtomic[value] === $Failed,
  Print["CF300S12R2PRIME FAIL atomic output race output=", outputFile];
  Exit[98], Exit[code]];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
planSourceArtifact = If[planMode === "reuse",
  FeynFacet`FamilyArtifactRead[planSourceFile], None];
preparationHashAfterRead = FileHash[preparationFile,
  "SHA256", "HexString"];
planSourceHashAfterRead = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];
If[preparationHashAfterRead =!= preparationHashBefore,
  writeAndExit[<|"Status" -> "PreparationChangedDuringRead",
    "PreparationFile" -> preparationFile,
    "PreparationSHA256Before" -> preparationHashBefore,
    "PreparationSHA256AfterRead" -> preparationHashAfterRead|>, 96]];
If[planMode === "reuse" &&
    planSourceHashAfterRead =!= planSourceHashBefore,
  writeAndExit[<|"Status" -> "PlanSourceChangedDuringRead",
    "PlanSourceFile" -> planSourceFile,
    "PlanSourceSHA256Before" -> planSourceHashBefore,
    "PlanSourceSHA256AfterRead" -> planSourceHashAfterRead|>, 96]];
If[dependencyHashesAfterLoad =!= dependencyHashesBefore ||
    driverHashAfterLoad =!= driverHashBefore,
  writeAndExit[<|"Status" -> "DependencyChangedDuringLoad",
    "DependencyHashesBefore" -> dependencyHashesBefore,
    "DependencyHashesAfterLoad" -> dependencyHashesAfterLoad,
    "DriverSHA256AfterLoad" -> driverHashAfterLoad|>, 95]];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension",
  writeAndExit[<|"Status" -> "PreparationArtifactInvalid",
    "PreparationFile" -> preparationFile|>, 66]];
If[Lookup[preparationArtifact, "DependencyHashes", None] =!=
    dependencyHashesBefore,
  writeAndExit[<|"Status" -> "PreparationDependencyHashMismatch",
    "PreparationDependencyHashes" -> Lookup[preparationArtifact,
      "DependencyHashes", None],
    "CurrentDependencyHashes" -> dependencyHashesBefore|>, 66]];
preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
If[! StringQ[preparationDriverFile] ||
    ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None],
  writeAndExit[<|"Status" -> "PreparationDriverHashMismatch",
    "PreparationDriverFile" -> preparationDriverFile|>, 66]];
preparation = Lookup[preparationArtifact, "Preparation", $Failed];
If[! AssociationQ[preparation] ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] ||
    Lookup[preparationArtifact, "RootOrderingFingerprint", None] =!=
      Lookup[preparation, "RootOrderingFingerprint", Missing["RootOrder"]],
  writeAndExit[<|"Status" -> "PreparationABIInvalid",
    "PreparationFile" -> preparationFile|>, 67]];

eliminationPlan = None;
expectedDegreeProfile = Automatic;
If[planMode === "reuse",
  If[! AssociationQ[planSourceArtifact] ||
      Lookup[planSourceArtifact, "Status", None] =!=
        "RationalAffinePrimeInterpolated" ||
      Lookup[planSourceArtifact, "PlanAcquisitionMode", None] =!=
        "Discover" ||
      Lookup[planSourceArtifact, "PreparationSHA256", None] =!=
        preparationHashBefore ||
      Lookup[planSourceArtifact, "PrototypeSHA256", None] =!=
        prototypeHashBefore ||
      Lookup[planSourceArtifact, "DependencyHashes", None] =!=
        dependencyHashesBefore ||
      Lookup[planSourceArtifact, "RootOrderingFingerprint", None] =!=
        preparation["RootOrderingFingerprint"] ||
      Lookup[planSourceArtifact, "Prime", None] =!=
        Lookup[Lookup[planSourceArtifact, "EliminationPlan", <||>],
          "PilotPrime", Missing["PilotPrime"]],
    writeAndExit[<|"Status" -> "PlanSourceProvenanceMismatch",
      "PlanSourceFile" -> planSourceFile,
      "PlanSourceSHA256" -> planSourceHashBefore|>, 68]];
  planSourceDriverFile = Lookup[planSourceArtifact, "DriverFile", $Failed];
  If[! StringQ[planSourceDriverFile] ||
      ! FileExistsQ[planSourceDriverFile] ||
      FileHash[planSourceDriverFile, "SHA256", "HexString"] =!=
        Lookup[planSourceArtifact, "DriverSHA256", None] ||
      FileHash[planSourceDriverFile, "SHA256", "HexString"] =!=
        driverHashBefore,
    writeAndExit[<|"Status" -> "PlanSourceDriverHashMismatch",
      "PlanSourceDriverFile" -> planSourceDriverFile|>, 68]];
  eliminationPlan = Lookup[planSourceArtifact,
    "EliminationPlan", $Failed];
  expectedDegreeProfile = Lookup[planSourceArtifact,
    "DegreeProfile", $Failed];
  If[! AssociationQ[eliminationPlan] ||
      ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
        preparation, eliminationPlan] ||
      Lookup[planSourceArtifact, "EliminationPlanFingerprint", None] =!=
        eliminationPlan["PlanFingerprint"] ||
      Lookup[planSourceArtifact, "DegreeProfileFingerprint", None] =!=
        fingerprint[expectedDegreeProfile] ||
      expectedDegreeProfile =!= Lookup[
        Lookup[planSourceArtifact, "Interpolations", {}],
        "Degrees", $Failed],
    writeAndExit[<|"Status" -> "PlanSourceSemanticMismatch",
      "PlanSourceFile" -> planSourceFile,
      "PlanSourceSHA256" -> planSourceHashBefore|>, 68]]];

epsilonValues = (#1/(#1 + 20) &) /@ Range[sampleCount];
Print["CF300S12R2PRIME prime=", prime,
  " plan_mode=", planMode,
  " samples=", sampleCount,
  " construction=", constructionCount,
  " maximum_total_degree=", maximumTotalDegree,
  " unknowns=", preparation["UnknownCount"]];
{seconds, interpolation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRInterpolateRationalAffinePrime[
    preparation, epsilonValues, prime,
    "ConstructionCount" -> constructionCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "RandomSeed" -> 730000 + Mod[prime, 100000],
    "EliminationPlanMode" -> If[planMode === "discover",
      "Discover", "Require"],
    "EliminationPlan" -> eliminationPlan,
    "ExpectedDegreeProfile" -> expectedDegreeProfile,
    "Verbose" -> True]];
result = If[AssociationQ[interpolation], Join[interpolation, <|
    "PreparationFile" -> preparationFile,
    "PreparationSHA256" -> preparationHashBefore,
    "InputFile" -> preparationArtifact["InputFile"],
    "InputSHA256" -> preparationArtifact["InputSHA256"],
    "PlanAcquisitionMode" -> If[planMode === "discover",
      "Discover", "Reuse"],
    "PlanSourceFile" -> If[planMode === "reuse", planSourceFile, None],
    "PlanSourceSHA256" -> If[planMode === "reuse",
      planSourceHashBefore, None],
    "PrimeSeconds" -> seconds,
    "PrototypeSHA256" -> prototypeHashBefore,
    "DependencyHashes" -> dependencyHashesBefore,
    "DriverFile" -> $InputFileName,
    "DriverSHA256" -> driverHashBefore|>],
  <|"Status" -> "PrimeInterpolationNotAssociation",
    "Prime" -> prime, "PrimeSeconds" -> seconds|>];
If[Lookup[result, "Status", None] ===
      "RationalAffinePrimeInterpolated" &&
    (Lookup[result, "RootOrderingFingerprint", None] =!=
        preparation["RootOrderingFingerprint"] ||
      Lookup[result, "EliminationPlanMode", None] =!=
        If[planMode === "discover", "Discover", "Require"] ||
      ! AssociationQ[Lookup[result, "EliminationPlan", $Failed]] ||
      Lookup[result, "EliminationPlanFingerprint", None] =!=
        Lookup[Lookup[result, "EliminationPlan", <||>],
          "PlanFingerprint", Missing["PlanFingerprint"]] ||
      Lookup[result, "DegreeProfileFingerprint", None] =!=
        fingerprint[Lookup[result, "DegreeProfile", $Failed]] ||
      (planMode === "reuse" &&
        (Lookup[result, "EliminationPlan", $Failed] =!= eliminationPlan ||
          Lookup[result, "DegreeProfile", $Failed] =!=
            expectedDegreeProfile))),
  result = <|"Status" -> "PrimeResultSemanticMismatch",
    "Prime" -> prime, "PlanAcquisitionMode" -> planMode|>];
preparationHashAtCompletion = FileHash[preparationFile,
  "SHA256", "HexString"];
prototypeHashAtCompletion = FileHash[prototypeFile,
  "SHA256", "HexString"];
dependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashAtCompletion = FileHash[$InputFileName,
  "SHA256", "HexString"];
preparationDriverHashAtCompletion = FileHash[preparationDriverFile,
  "SHA256", "HexString"];
planSourceHashAtCompletion = If[planMode === "reuse",
  FileHash[planSourceFile, "SHA256", "HexString"], None];
If[preparationHashAtCompletion =!= preparationHashBefore ||
    prototypeHashAtCompletion =!= prototypeHashBefore ||
    dependencyHashesAtCompletion =!= dependencyHashesBefore ||
    driverHashAtCompletion =!= driverHashBefore ||
    preparationDriverHashAtCompletion =!=
      preparationArtifact["DriverSHA256"] ||
    planSourceHashAtCompletion =!= planSourceHashBefore,
  result = <|"Status" -> "SourceChangedBeforeCompletion",
    "Prime" -> prime,
    "PreparationSHA256Before" -> preparationHashBefore,
    "PreparationSHA256AtCompletion" -> preparationHashAtCompletion,
    "PrototypeSHA256Before" -> prototypeHashBefore,
    "PrototypeSHA256AtCompletion" -> prototypeHashAtCompletion,
    "DependencyHashesAtCompletion" ->
      dependencyHashesAtCompletion,
    "DriverSHA256AtCompletion" -> driverHashAtCompletion,
    "PreparationDriverSHA256AtCompletion" ->
      preparationDriverHashAtCompletion,
    "PlanSourceSHA256AtCompletion" ->
      planSourceHashAtCompletion|>];
If[writeAtomic[result] === $Failed,
  Print["CF300S12R2PRIME FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300S12R2PRIME RESULT status=", result["Status"],
  " prime=", prime,
  " seconds=", Round[seconds, 0.001],
  " output=", outputFile];
Exit[If[result["Status"] === "RationalAffinePrimeInterpolated", 0, 2]];
