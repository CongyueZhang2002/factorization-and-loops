#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 7,
  Print["CF300S12R2AGG FAIL usage=<project-root> <preparation.wl> <output.wl> <unseen-prime> <prime1.wl> <prime2.wl> <prime3.wl> [more-prime-artifacts...]"];
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
unseenPrime = parseStrictInteger[arguments[[4]]];
primeFiles = ExpandFileName /@ arguments[[5 ;;]];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];
nativeDirectory = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_wl_xh"}];
nativePrimeDriverFile = FileNameJoin[{nativeDirectory,
  "run_cf300_sector12_rank2_native_prime.wls"}];
nativeBinaryFile = FileNameJoin[{exchangeDirectory,
  "flint_affine_rref_xh", "bin", "flint_affine_rref"}];
fixedPlanFLINTBinaryFile = FileNameJoin[{projectRoot, "FeynFacet",
  "Backends", "flint", "bin", "flint_modular_solve"}];
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
nativeDependencyFiles = <|
  "FlintAffineRREFAdapter" -> FileNameJoin[{nativeDirectory,
    "FlintAffineRREFAdapter.wl"}],
  "NativeAffinePilotPrime" -> FileNameJoin[{nativeDirectory,
    "NativeAffinePilotPrime.wl"}]|>;
prototypeFile = dependencyFiles["TripleRootReconstructionPrototype"];

If[! DirectoryQ[projectRoot] || ! FileExistsQ[preparationFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    ! AllTrue[Values[nativeDependencyFiles], FileExistsQ] ||
    ! FileExistsQ[nativePrimeDriverFile] ||
    ! FileExistsQ[nativeBinaryFile] ||
    ! FileExistsQ[fixedPlanFLINTBinaryFile] ||
    Length[primeFiles] < 3 || ! DuplicateFreeQ[primeFiles] ||
    ! AllTrue[primeFiles, FileExistsQ] ||
    ! PrimeQ[unseenPrime] || !(2 < unseenPrime < 2^31) ||
    Mod[unseenPrime, 4] =!= 3 ||
    FileExistsQ[outputFile] || FileExistsQ[outputFile <> ".tmp"],
  Print["CF300S12R2AGG FAIL invalid or stale target"];
  Exit[65]];

preparationHashBefore = FileHash[preparationFile,
  "SHA256", "HexString"];
primeHashesBefore = FileHash[#1, "SHA256", "HexString"] & /@
  primeFiles;
prototypeHashBefore = FileHash[prototypeFile, "SHA256", "HexString"];
dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
nativeDependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, nativeDependencyFiles];
nativePrimeDriverHashBefore = FileHash[nativePrimeDriverFile,
  "SHA256", "HexString"];
nativeBinaryHashBefore = FileHash[nativeBinaryFile,
  "SHA256", "HexString"];
fixedPlanFLINTBinaryHashBefore = FileHash[fixedPlanFLINTBinaryFile,
  "SHA256", "HexString"];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];

Get[dependencyFiles["LoadFACET"]];
Get[dependencyFiles["TripleRootAlgebra"]];
Get[dependencyFiles["TripleRootStripAdapter"]];
Get[dependencyFiles["TripleRootAffinePilot"]];
Get[prototypeFile];
dependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
nativeDependencyHashesAfterLoad = Map[
  FileHash[#1, "SHA256", "HexString"] &, nativeDependencyFiles];
nativePrimeDriverHashAfterLoad = FileHash[nativePrimeDriverFile,
  "SHA256", "HexString"];
nativeBinaryHashAfterLoad = FileHash[nativeBinaryFile,
  "SHA256", "HexString"];
fixedPlanFLINTBinaryHashAfterLoad = FileHash[fixedPlanFLINTBinaryFile,
  "SHA256", "HexString"];
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

finish[status_String, data_: <||>, code_: 2] := Module[{result},
  result = Join[<|"Status" -> status,
    "PreparationFile" -> preparationFile,
    "PrimeFiles" -> primeFiles,
    "UnseenPrime" -> unseenPrime|>, data];
  If[writeAtomic[result] === $Failed,
    Print["CF300S12R2AGG FAIL atomic output race output=", outputFile];
    Exit[98]];
  Print["CF300S12R2AGG RESULT status=", status,
    " output=", outputFile];
  Exit[code]
];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
exactRationalNumberQ[value_] := IntegerQ[value] ||
  MatchQ[value, _Rational];
reconstructedCoordinateSchemaQ[coordinate_] := Module[
  {requiredKeys, numerator, denominator, degrees},
  requiredKeys = {"Value", "Degrees", "NumeratorCoefficients",
    "DenominatorCoefficients", "TrainingPrimeImagesExact"};
  If[! AssociationQ[coordinate] ||
      ! AllTrue[requiredKeys, KeyExistsQ[coordinate, #1] &],
    Return[False]];
  numerator = coordinate["NumeratorCoefficients"];
  denominator = coordinate["DenominatorCoefficients"];
  degrees = coordinate["Degrees"];
  ListQ[numerator] && numerator =!= {} &&
    ListQ[denominator] && denominator =!= {} &&
    VectorQ[numerator, exactRationalNumberQ] &&
    VectorQ[denominator, exactRationalNumberQ] &&
    Last[denominator] === 1 &&
    TrueQ[coordinate["TrainingPrimeImagesExact"]] &&
    If[numerator === {0},
      degrees === {-Infinity, 0} && denominator === {1},
      MatchQ[degrees, {_Integer, _Integer}] &&
        Min[degrees] >= 0 &&
        Length[numerator] === degrees[[1]] + 1 &&
        Length[denominator] === degrees[[2]] + 1]
];
coefficientHeightSummary[coefficients_List] := Module[
  {maximumNumerator, maximumDenominator},
  maximumNumerator = Max[Abs[Numerator[#1]] & /@ coefficients];
  maximumDenominator = Max[Denominator /@ coefficients];
  <|"CoefficientCount" -> Length[coefficients],
    "MaxAbsRecoveredNumerator" -> maximumNumerator,
    "MaxRecoveredDenominator" -> maximumDenominator,
    "Height" -> Max[maximumNumerator, maximumDenominator]|>
];
directRawExactResidual[record_Association, gauge_List, residues_List,
    oneForms_List] := Module[
  {variables, epsilon, strip, dimensions, letterCount, residueTerm,
   residual, residualZero, nonzeroPositions},
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  dimensions = Dimensions[gauge];
  letterCount = Length[oneForms];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      Length[dimensions] =!= 2 ||
      ! VectorQ[dimensions, IntegerQ[#1] && #1 > 0 &] ||
      ! ListQ[strip] || Length[strip] =!= 3 ||
      Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]} ||
      Dimensions[strip[[3]]] =!= {2, dimensions[[1]], dimensions[[2]]} ||
      Dimensions[oneForms] =!= {letterCount, 2} ||
      If[letterCount === 0, residues =!= {},
        Dimensions[residues] =!=
          {letterCount, dimensions[[1]], dimensions[[2]]}],
    Return[<|"Status" -> "DirectRawExactInputSchemaInvalid",
      "ResidualZero" -> False|>]];
  residual = Quiet[Check[Table[
      residueTerm = If[letterCount === 0,
        ConstantArray[0, dimensions],
        Total[Table[residues[[letter]] oneForms[[letter, mu]],
          {letter, letterCount}]]];
      Map[Together,
        D[gauge, variables[[mu]]] -
          epsilon Dot[strip[[1, mu]], gauge] +
          epsilon Dot[gauge, strip[[2, mu]]] +
          epsilon residueTerm - strip[[3, mu]], {2}],
      {mu, 2}], $Failed]];
  If[residual === $Failed ||
      Dimensions[residual] =!=
        {2, dimensions[[1]], dimensions[[2]]},
    Return[<|"Status" -> "DirectRawExactEvaluationFailed",
      "ResidualZero" -> False|>]];
  residualZero = And @@ (TrueQ[#1 === 0] & /@ Flatten[residual]);
  nonzeroPositions = If[residualZero, {},
    Position[residual, entry_ /; ! TrueQ[entry === 0], {3}]];
  <|"Status" -> If[residualZero,
      "DirectRawOriginalPDEResidualZero",
      "DirectRawOriginalPDEResidualNonzero"],
    "ResidualZero" -> residualZero,
    "EvaluationPrimitives" -> {"D", "Dot", "Together"},
    "ResidualDimensions" -> Dimensions[residual],
    "NonzeroPositions" -> nonzeroPositions,
    "Residual" -> residual|>
];

preparationArtifact = FeynFacet`FamilyArtifactRead[preparationFile];
primeArtifacts = FeynFacet`FamilyArtifactRead /@ primeFiles;
preparationHashAfterRead = FileHash[preparationFile,
  "SHA256", "HexString"];
primeHashesAfterRead = FileHash[#1, "SHA256", "HexString"] & /@
  primeFiles;
If[preparationHashAfterRead =!= preparationHashBefore ||
    primeHashesAfterRead =!= primeHashesBefore ||
    dependencyHashesAfterLoad =!= dependencyHashesBefore ||
    nativeDependencyHashesAfterLoad =!= nativeDependencyHashesBefore ||
    nativePrimeDriverHashAfterLoad =!= nativePrimeDriverHashBefore ||
    nativeBinaryHashAfterLoad =!= nativeBinaryHashBefore ||
    fixedPlanFLINTBinaryHashAfterLoad =!=
      fixedPlanFLINTBinaryHashBefore ||
    driverHashAfterLoad =!= driverHashBefore,
  finish["InputArtifactsChangedDuringRead", <|
    "PreparationSHA256Before" -> preparationHashBefore,
    "PreparationSHA256AfterRead" -> preparationHashAfterRead,
    "PrimeSHA256Before" -> AssociationThread[
      primeFiles, primeHashesBefore],
    "PrimeSHA256AfterRead" -> AssociationThread[
      primeFiles, primeHashesAfterRead],
    "DependencyHashesBefore" -> dependencyHashesBefore,
    "DependencyHashesAfterLoad" -> dependencyHashesAfterLoad,
    "NativeDependencyHashesBefore" -> nativeDependencyHashesBefore,
    "NativeDependencyHashesAfterLoad" ->
      nativeDependencyHashesAfterLoad,
    "NativePrimeDriverSHA256Before" -> nativePrimeDriverHashBefore,
    "NativePrimeDriverSHA256AfterLoad" ->
      nativePrimeDriverHashAfterLoad,
    "NativeBinarySHA256Before" -> nativeBinaryHashBefore,
    "NativeBinarySHA256AfterLoad" -> nativeBinaryHashAfterLoad,
    "FixedPlanFLINTBinarySHA256Before" ->
      fixedPlanFLINTBinaryHashBefore,
    "FixedPlanFLINTBinarySHA256AfterLoad" ->
      fixedPlanFLINTBinaryHashAfterLoad,
    "DriverSHA256AfterLoad" -> driverHashAfterLoad|>, 96]];
If[! AssociationQ[preparationArtifact] ||
    Lookup[preparationArtifact, "Status", None] =!=
      "PreparedCF300Sector12Rank2Extension" ||
    ! AllTrue[primeArtifacts, AssociationQ] ||
    ! AllTrue[primeArtifacts, Lookup[#1, "Status", None] ===
      "RationalAffinePrimeInterpolated" &],
  finish["InputArtifactInvalid", <||>, 66]];

If[Lookup[preparationArtifact, "DependencyHashes", None] =!=
      dependencyHashesBefore ||
    ! AllTrue[primeArtifacts,
      Lookup[#1, "DependencyHashes", None] ===
        dependencyHashesBefore &],
  finish["InputArtifactDependencyHashMismatch", <|
    "PreparationDependencyHashes" -> Lookup[preparationArtifact,
      "DependencyHashes", None],
    "CurrentDependencyHashes" -> dependencyHashesBefore|>, 67]];

(* CFFR1_NATIVE_PROVENANCE_GATE_BEGIN *)
nativeDependencyHashRecords = Lookup[primeArtifacts,
  "NativeDependencyHashes", $Failed];
If[! AllTrue[nativeDependencyHashRecords, AssociationQ] ||
    ! AllTrue[nativeDependencyHashRecords,
      Sort[Keys[#1]] === Sort[Keys[nativeDependencyFiles]] &] ||
    ! AllTrue[primeArtifacts,
      Lookup[#1, "NativeDependencyHashes", None] ===
        nativeDependencyHashesBefore &] ||
    ! AllTrue[primeArtifacts,
      Lookup[#1, "NativeBinaryFile", None] === nativeBinaryFile &&
        Lookup[#1, "NativeBinarySHA256", None] ===
          nativeBinaryHashBefore &&
        Lookup[#1, "FixedPlanFLINTBinaryFile", None] ===
          fixedPlanFLINTBinaryFile &&
        Lookup[#1, "FixedPlanFLINTBinarySHA256", None] ===
          fixedPlanFLINTBinaryHashBefore &],
  finish["NativePrimeArtifactProvenanceMismatch", <|
    "ExpectedNativeDependencyHashes" -> nativeDependencyHashesBefore,
    "ObservedNativeDependencyHashes" ->
      nativeDependencyHashRecords,
    "ExpectedNativeBinaryFile" -> nativeBinaryFile,
    "ExpectedNativeBinarySHA256" -> nativeBinaryHashBefore,
    "ObservedNativeBinaryFiles" -> Lookup[primeArtifacts,
      "NativeBinaryFile", $Failed],
    "ObservedNativeBinarySHA256" -> Lookup[primeArtifacts,
      "NativeBinarySHA256", $Failed],
    "ExpectedFixedPlanFLINTBinaryFile" ->
      fixedPlanFLINTBinaryFile,
    "ExpectedFixedPlanFLINTBinarySHA256" ->
      fixedPlanFLINTBinaryHashBefore,
    "ObservedFixedPlanFLINTBinaryFiles" -> Lookup[primeArtifacts,
      "FixedPlanFLINTBinaryFile", $Failed],
    "ObservedFixedPlanFLINTBinarySHA256" -> Lookup[primeArtifacts,
      "FixedPlanFLINTBinarySHA256", $Failed]|>, 67]];
(* CFFR1_NATIVE_PROVENANCE_GATE_END *)

preparationDriverFile = Lookup[preparationArtifact, "DriverFile", $Failed];
primeDriverFiles = DeleteDuplicates[Lookup[primeArtifacts,
  "DriverFile", $Failed]];
If[! StringQ[preparationDriverFile] ||
    ! FileExistsQ[preparationDriverFile] ||
    FileHash[preparationDriverFile, "SHA256", "HexString"] =!=
      Lookup[preparationArtifact, "DriverSHA256", None] ||
    Length[primeDriverFiles] =!= 1 ||
    ! StringQ[First[primeDriverFiles]] ||
    First[primeDriverFiles] =!= nativePrimeDriverFile ||
    ! FileExistsQ[First[primeDriverFiles]] ||
    FileHash[First[primeDriverFiles], "SHA256", "HexString"] =!=
      nativePrimeDriverHashBefore ||
    ! AllTrue[primeArtifacts,
      Lookup[#1, "DriverFile", None] === nativePrimeDriverFile &&
        Lookup[#1, "DriverSHA256", None] ===
          nativePrimeDriverHashBefore &],
  finish["InputArtifactDriverHashMismatch", <|
    "PreparationDriverFile" -> preparationDriverFile,
    "PrimeDriverFiles" -> primeDriverFiles|>, 67]];

preparationHash = preparationHashBefore;
prototypeHash = prototypeHashBefore;
If[! AllTrue[primeArtifacts,
      Lookup[#1, "PreparationSHA256", None] === preparationHash &] ||
    ! AllTrue[primeArtifacts,
      Lookup[#1, "PrototypeSHA256", None] === prototypeHash &],
  finish["PrimeArtifactSourceHashMismatch", <|
    "PreparationSHA256" -> preparationHash,
    "PrototypeSHA256" -> prototypeHash|>, 67]];

preparation = preparationArtifact["Preparation"];
If[! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
  finish["ScaledPreparationABIInvalid", <||>, 68]];
If[Lookup[preparationArtifact, "RootOrderingFingerprint", None] =!=
    preparation["RootOrderingFingerprint"],
  finish["PreparationRootOrderingFingerprintMismatch", <||>, 68]];
sidecarCertificate = Lookup[preparationArtifact,
  "SidecarCertificate", $Failed];
sidecarRequiredKeys = {"RoundTripExact", "RoundTripSeconds",
  "ChannelEquationFingerprint", "SupportFingerprint",
  "TermGraphFingerprint", "ActiveGrades", "ActiveGradeRank",
  "GlobalRootSourceOrder", "StableLocalRootSourceOrder",
  "LocalToGlobalGradeMap", "LocalSquareClassCertificate"};
localSquareClassCertificate = If[AssociationQ[sidecarCertificate],
  Lookup[sidecarCertificate, "LocalSquareClassCertificate", $Failed],
  $Failed];
If[! AssociationQ[sidecarCertificate] ||
    ! AllTrue[sidecarRequiredKeys,
      KeyExistsQ[sidecarCertificate, #1] &] ||
    ! AssociationQ[localSquareClassCertificate] ||
    ! AllTrue[{"Independent", "Rank", "Masks", "Products", "Nonsquare"},
      KeyExistsQ[localSquareClassCertificate, #1] &] ||
    ! TrueQ[sidecarCertificate["RoundTripExact"]] ||
    ! TrueQ[And @@ (StringQ[sidecarCertificate[#1]] & /@
      {"ChannelEquationFingerprint", "SupportFingerprint",
       "TermGraphFingerprint"})] ||
    ! ListQ[sidecarCertificate["LocalToGlobalGradeMap"]],
  finish["SidecarCertificateSchemaInvalid", <||>, 68]];
If[! TrueQ[localSquareClassCertificate["Independent"]] ||
    localSquareClassCertificate["Rank"] =!= 2 ||
    sidecarCertificate["StableLocalRootSourceOrder"] =!=
      preparation["RootSourceIndices"] ||
    sidecarCertificate["LocalToGlobalGradeMap"] =!= Table[
      localMask -> Sum[
        BitGet[localMask, bit - 1] *
          2^(preparation["RootSourceIndices"][[bit]] - 1),
        {bit, preparation["RootCount"]}],
      {localMask, 0, preparation["GradeCount"] - 1}] ||
    preparationArtifact["OneFormOrderFingerprint"] =!=
      fingerprint[preparation["ABIPayload", "OneForms"]] ||
    preparation["Normalizations"] =!= {},
  finish["PreparationSemanticCertificateMismatch", <||>, 68]];
trainingPrimes = Lookup[primeArtifacts, "Prime", {}];
If[! VectorQ[trainingPrimes, IntegerQ] ||
    ! DuplicateFreeQ[trainingPrimes] ||
    ! AllTrue[trainingPrimes,
      PrimeQ[#1] && 2 < #1 < 2^31 && Mod[#1, 4] === 3 &],
  finish["TrainingPrimeSchemaInvalid", <|
    "TrainingPrimes" -> trainingPrimes|>, 69]];
If[MemberQ[trainingPrimes, unseenPrime],
  finish["UnseenPrimeWasTrainingPrime", <|
    "TrainingPrimes" -> trainingPrimes|>, 69]];

artifactOrderings = Lookup[primeArtifacts,
  "RootOrderingFingerprint", $Failed];
plans = Lookup[primeArtifacts, "EliminationPlan", $Failed];
planFingerprints = Lookup[primeArtifacts,
  "EliminationPlanFingerprint", $Failed];
degreeProfiles = Lookup[primeArtifacts, "DegreeProfile", $Failed];
degreeProfileFingerprints = Lookup[primeArtifacts,
  "DegreeProfileFingerprint", $Failed];
planModes = Lookup[primeArtifacts, "PlanAcquisitionMode", $Failed];
discoverPositions = Flatten[Position[planModes, "Discover"]];
reusePositions = Flatten[Position[planModes, "Reuse"]];
If[Length[discoverPositions] =!= 1 ||
    Sort[Join[discoverPositions, reusePositions]] =!=
      Range[Length[primeArtifacts]],
  finish["CrossPrimePlanRoleMismatch", <|
    "PlanAcquisitionModes" -> planModes|>, 69]];
If[! AllTrue[discoverPositions,
      TrueQ[Lookup[primeArtifacts[[#1]],
          "NativePilotPerformed", False]] &&
        Lookup[primeArtifacts[[#1]], "DensePilotPerformed", None] ===
          False &&
        AssociationQ[Lookup[primeArtifacts[[#1]],
          "NativePilotEvidence", $Failed]] &&
        AssociationQ[Lookup[primeArtifacts[[#1]],
          "NativePilotRequest", $Failed]] &&
        AssociationQ[Lookup[primeArtifacts[[#1]],
          "NativePilotCertificate", $Failed]] &] ||
    ! AllTrue[reusePositions,
      Lookup[primeArtifacts[[#1]], "NativePilotPerformed", None] ===
          False &&
        Lookup[primeArtifacts[[#1]], "NativePilotEvidence", $Failed] ===
          None &&
        Lookup[primeArtifacts[[#1]], "NativePilotRequest", $Failed] ===
          None &&
        Lookup[primeArtifacts[[#1]], "NativePilotCertificate", $Failed] ===
          None &],
  finish["NativePrimeArtifactRoleMismatch", <|
    "PlanAcquisitionModes" -> planModes,
    "NativePilotPerformed" -> Lookup[primeArtifacts,
      "NativePilotPerformed", $Failed],
    "DensePilotPerformed" -> Lookup[primeArtifacts,
      "DensePilotPerformed", $Failed]|>, 69]];
originPosition = First[discoverPositions];
originFile = primeFiles[[originPosition]];
originHash = primeHashesBefore[[originPosition]];
commonPlan = plans[[originPosition]];
If[! AllTrue[artifactOrderings,
      #1 === preparation["RootOrderingFingerprint"] &] ||
    ! AllTrue[plans, AssociationQ] ||
    ! AllTrue[plans, SameQ[#1, commonPlan] &] ||
    ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
      preparation, commonPlan] ||
    ! AllTrue[planFingerprints,
      #1 === commonPlan["PlanFingerprint"] &] ||
    trainingPrimes[[originPosition]] =!= commonPlan["PilotPrime"] ||
    Lookup[primeArtifacts[[originPosition]], "PlanSourceFile", $Failed] =!=
      None ||
    Lookup[primeArtifacts[[originPosition]], "PlanSourceSHA256", $Failed] =!=
      None ||
    ! AllTrue[reusePositions,
      Lookup[primeArtifacts[[#1]], "PlanSourceFile", $Failed] ===
          originFile &&
        Lookup[primeArtifacts[[#1]], "PlanSourceSHA256", $Failed] ===
          originHash &],
  finish["CrossPrimePlanProvenanceMismatch", <|
    "OriginPrimeFile" -> originFile,
    "OriginPrimeSHA256" -> originHash,
    "PlanFingerprints" -> planFingerprints|>, 69]];
If[! AllTrue[degreeProfiles, ListQ] ||
    ! AllTrue[degreeProfiles, SameQ[#1, First[degreeProfiles]] &] ||
    ! TrueQ[And @@ MapThread[SameQ, {degreeProfileFingerprints,
        fingerprint /@ degreeProfiles}]] ||
    ! AllTrue[primeArtifacts,
      Lookup[Lookup[#1, "Interpolations", {}], "Degrees", $Failed] ===
        First[degreeProfiles] &],
  finish["CrossPrimeDegreeProfileMismatch", <|
    "DegreeProfileFingerprints" -> degreeProfileFingerprints|>, 69]];

{liftSeconds, scaledResult} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRLiftRationalAffineBatch[
    preparation, primeArtifacts]];
If[Lookup[scaledResult, "Status", None] =!=
    "ExactRationalReconstruction",
  finish["ScaledRationalLiftFailed", <|
    "TrainingPrimes" -> trainingPrimes,
    "LiftSeconds" -> liftSeconds,
    "LiftResult" -> scaledResult|>, 70]];

reconstructedCoordinates = Lookup[scaledResult,
  "ReconstructedCoordinates", $Failed];
If[! ListQ[reconstructedCoordinates] ||
    Length[reconstructedCoordinates] =!= preparation["UnknownCount"] ||
    ! AllTrue[reconstructedCoordinates,
      reconstructedCoordinateSchemaQ] ||
    Lookup[reconstructedCoordinates, "Value", $Failed] =!=
      scaledResult["ReconstructedVector"] ||
    Lookup[reconstructedCoordinates, "Degrees", $Failed] =!=
      scaledResult["DegreeProfile"],
  finish["ReconstructedCoordinateSchemaInvalid", <|
    "ExpectedCoordinateCount" -> preparation["UnknownCount"],
    "ObservedCoordinateCount" -> If[ListQ[reconstructedCoordinates],
      Length[reconstructedCoordinates], $Failed]|>, 70]];
crtModulus = Times @@ trainingPrimes;
rationalReconstructionBound = Floor[Sqrt[crtModulus/2]];
recoveredNumeratorPolynomialCoefficients = Flatten[
  Lookup[reconstructedCoordinates, "NumeratorCoefficients"]];
recoveredDenominatorPolynomialCoefficients = Flatten[
  Lookup[reconstructedCoordinates, "DenominatorCoefficients"]];
recoveredAllCoefficients = Join[
  recoveredNumeratorPolynomialCoefficients,
  recoveredDenominatorPolynomialCoefficients];
recoveredCoefficientHeights = <|
  "NumeratorPolynomialCoefficients" -> coefficientHeightSummary[
    recoveredNumeratorPolynomialCoefficients],
  "DenominatorPolynomialCoefficients" -> coefficientHeightSummary[
    recoveredDenominatorPolynomialCoefficients],
  "AllReconstructedCoefficients" -> coefficientHeightSummary[
    recoveredAllCoefficients]|>;
reconstructionBudgetWithinBound =
  recoveredCoefficientHeights["AllReconstructedCoefficients",
      "MaxAbsRecoveredNumerator"] <= rationalReconstructionBound &&
    recoveredCoefficientHeights["AllReconstructedCoefficients",
      "MaxRecoveredDenominator"] <= rationalReconstructionBound;
If[! TrueQ[reconstructionBudgetWithinBound],
  finish["RationalReconstructionBudgetViolation", <|
    "CRTModulus" -> crtModulus,
    "RationalReconstructionBound" -> rationalReconstructionBound,
    "RecoveredCoefficientHeights" -> recoveredCoefficientHeights|>,
    70]];

originalInputFile = preparationArtifact["InputFile"];
originalInputHashBefore = FileHash[originalInputFile,
  "SHA256", "HexString"];
record = FeynFacet`FamilyArtifactRead[originalInputFile];
originalInputHashAfterRead = FileHash[originalInputFile,
  "SHA256", "HexString"];
regulatorClearFactor = preparationArtifact["RegulatorClearFactor"];
If[originalInputHashBefore =!= preparationArtifact["InputSHA256"] ||
    originalInputHashAfterRead =!= originalInputHashBefore ||
    ! AssociationQ[record] || TrueQ[Together[regulatorClearFactor] === 0],
  finish["OriginalInputReloadFailed", <||>, 71]];
{originalPreparationSeconds, originalPreparation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    record, FeynFacet`TransportFamilyChart["CF300"],
    "OneForms" -> preparation["OneForms"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "Support" -> preparation["GaugeSupport"]]];
If[Lookup[originalPreparation, "Status", None] =!=
      "PreparedReconstruction" ||
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      originalPreparation] ||
    originalPreparation["RootOrderingFingerprint"] =!=
      preparation["RootOrderingFingerprint"] ||
    originalPreparation["GaugeSupport"] =!= preparation["GaugeSupport"] ||
    fingerprint[originalPreparation["ABIPayload", "OneForms"]] =!=
      preparationArtifact["OneFormOrderFingerprint"],
  finish["OriginalPreparationFailed", <|
    "OriginalPreparationSeconds" -> originalPreparationSeconds,
    "OriginalPreparation" -> originalPreparation|>, 72]];

originalVector = Together /@
  (scaledResult["ReconstructedVector"]/regulatorClearFactor);
{originalExactSeconds, originalExact} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRExactChannelResidual[
    originalPreparation, originalVector]];
If[Lookup[originalExact, "Status", None] =!=
      "ExactChannelResidualZero" ||
    ! TrueQ[Lookup[originalExact, "ResidualZero", False]],
  finish["OriginalExactDLogResidualFailed", <|
    "OriginalExactSeconds" -> originalExactSeconds,
    "OriginalExactVerification" -> originalExact|>, 73]];

originalResult = Join[scaledResult, <|
  "Preparation" -> originalPreparation,
  "ABIFingerprint" -> originalPreparation["ABIFingerprint"],
  "ReconstructedVector" -> originalVector,
  "ExactVerification" -> originalExact|>];
validatedFingerprint = originalPreparation["ABIFingerprint"];
unseenEpsilonValues = {53/79, 59/83};
{unseenSeconds, allBranchVerification} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRVerifyReconstructionAllBranchMasksModPrime[
      originalResult, unseenPrime, unseenEpsilonValues,
      "RandomSeed" -> 741000]];
signChecks = Lookup[allBranchVerification, "Checks", {}];
unseenAccepted = Lookup[allBranchVerification, "Status", None] ===
    "AllBranchMasksVerified" &&
  TrueQ[Lookup[allBranchVerification, "ResidualZero", False]];
If[! TrueQ[unseenAccepted],
  finish["UnseenPrimeOrBranchVerificationFailed", <|
    "TrainingPrimes" -> trainingPrimes,
    "UnseenSeconds" -> unseenSeconds,
    "AllBranchVerification" -> allBranchVerification,
    "SignBranchVerifications" -> signChecks|>, 74]];

unpacked = CodexTripleRootReconstruction`TRUnpackReconstructedVector[
  originalPreparation, originalVector];
gauge = Map[CodexTripleRootStrip`TRFieldCompose[
      #1, originalPreparation["Roots"]] &,
    unpacked["GaugeChannels"], {2}];
If[Dimensions[gauge] =!= originalPreparation["Dimensions"],
  finish["ReconstructedGaugeShapeMismatch", <|
    "ObservedDimensions" -> Dimensions[gauge],
    "ExpectedDimensions" -> originalPreparation["Dimensions"]|>, 75]];
{rawOriginalExactSeconds, rawOriginalExact} = AbsoluteTiming[
  directRawExactResidual[record, gauge, unpacked["Residues"],
    originalPreparation["OneForms"]]];
If[Lookup[rawOriginalExact, "Status", None] =!=
      "DirectRawOriginalPDEResidualZero" ||
    ! TrueQ[Lookup[rawOriginalExact, "ResidualZero", False]],
  finish["IndependentRawOriginalPDEResidualFailed", <|
    "RawOriginalExactSeconds" -> rawOriginalExactSeconds,
    "RawOriginalExactVerification" -> rawOriginalExact|>, 76]];

result = <|"Status" -> "CF300Sector12Rank2ExtensionCertified",
  "InputFile" -> preparationArtifact["InputFile"],
  "InputSHA256" -> preparationArtifact["InputSHA256"],
  "Strip" -> {12, 9},
  "Method" -> "BiquadraticSplitFiniteFieldRationalEpsilonAffinePDE",
  "RootSourceIndices" -> originalPreparation["RootSourceIndices"],
  "RootOrderingFingerprint" ->
    originalPreparation["RootOrderingFingerprint"],
  "RegulatorClearFactor" -> regulatorClearFactor,
  "TrainingPrimes" -> trainingPrimes,
  "UnseenPrime" -> unseenPrime,
  "EliminationPlanFingerprint" -> commonPlan["PlanFingerprint"],
  "EliminationPlanOriginPrime" -> commonPlan["PilotPrime"],
  "DegreeProfileFingerprint" -> First[degreeProfileFingerprints],
  "CRTModulus" -> crtModulus,
  "RationalReconstructionBound" -> rationalReconstructionBound,
  "RecoveredCoefficientHeights" -> recoveredCoefficientHeights,
  "ReconstructionBudgetWithinBound" ->
    reconstructionBudgetWithinBound,
  "AllSplitBranchRowsPerPoint" -> True,
  "AllBranchFlipMasks" ->
    Range[0, originalPreparation["GradeCount"] - 1],
  "ExactDLog" -> True,
  "Gauge" -> gauge,
  "Residues" -> unpacked["Residues"],
  "GaugeChannels" -> unpacked["GaugeChannels"],
  "ReconstructedVector" -> originalVector,
  "ABIFingerprint" -> originalPreparation["ABIFingerprint"],
  "PreparationSHA256" -> preparationHash,
  "PrototypeSHA256" -> prototypeHash,
  "DependencyHashes" -> dependencyHashesBefore,
  (* CFFR1_NATIVE_PROVENANCE_OUTPUT_BEGIN *)
  "NativeDependencyHashes" -> nativeDependencyHashesBefore,
  "NativeAdapterFile" -> nativeDependencyFiles[
    "FlintAffineRREFAdapter"],
  "NativeAdapterSHA256" -> nativeDependencyHashesBefore[
    "FlintAffineRREFAdapter"],
  "NativeModuleFile" -> nativeDependencyFiles[
    "NativeAffinePilotPrime"],
  "NativeModuleSHA256" -> nativeDependencyHashesBefore[
    "NativeAffinePilotPrime"],
  "NativeBinaryFile" -> nativeBinaryFile,
  "NativeBinarySHA256" -> nativeBinaryHashBefore,
  "FixedPlanFLINTBinaryFile" -> fixedPlanFLINTBinaryFile,
  "FixedPlanFLINTBinarySHA256" -> fixedPlanFLINTBinaryHashBefore,
  "NativePrimeDriverFile" -> nativePrimeDriverFile,
  "NativePrimeDriverSHA256" -> nativePrimeDriverHashBefore,
  (* CFFR1_NATIVE_PROVENANCE_OUTPUT_END *)
  "DriverFile" -> $InputFileName,
  "DriverSHA256" -> driverHashBefore,
  "PrimeArtifactSHA256" -> AssociationThread[primeFiles,
    primeHashesBefore],
  "LiftSeconds" -> liftSeconds,
  "OriginalPreparationSeconds" -> originalPreparationSeconds,
  "OriginalExactSeconds" -> originalExactSeconds,
  "RawOriginalExactSeconds" -> rawOriginalExactSeconds,
  "UnseenSeconds" -> unseenSeconds,
  "ExactVerification" -> originalExact,
  "RawOriginalExactVerification" -> rawOriginalExact,
  "IndependentRawOriginalPDEResidualZero" -> True,
  "SignBranchVerifications" -> signChecks,
  "SidecarSeed" -> <|
    "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
    "InputSHA256" -> preparationArtifact["InputSHA256"],
    "TermGraphFingerprint" -> preparationArtifact[
      "SidecarCertificate", "TermGraphFingerprint"],
    "ChannelEquationFingerprint" -> preparationArtifact[
      "SidecarCertificate", "ChannelEquationFingerprint"],
    "SupportFingerprint" -> preparationArtifact[
      "SidecarCertificate", "SupportFingerprint"],
    "RootSourceIndices" -> originalPreparation["RootSourceIndices"],
    "RootOrderingFingerprint" ->
      originalPreparation["RootOrderingFingerprint"],
    "ABIFingerprint" -> originalPreparation["ABIFingerprint"],
    "DependencyHashes" -> dependencyHashesBefore,
    "NativeDependencyHashes" -> nativeDependencyHashesBefore,
    "NativeBinarySHA256" -> nativeBinaryHashBefore,
    "FixedPlanFLINTBinarySHA256" ->
      fixedPlanFLINTBinaryHashBefore,
    "NativePrimeDriverSHA256" -> nativePrimeDriverHashBefore,
    "GaugeFingerprint" -> fingerprint[gauge],
    "Gauge" -> gauge, "ExactDLog" -> True,
    "IndependentRawOriginalPDEResidualZero" -> True,
    "ConsumerMustRecheckExactDLog" -> True|>|>;
preparationHashAtCompletion = FileHash[preparationFile,
  "SHA256", "HexString"];
primeHashesAtCompletion = FileHash[#1, "SHA256", "HexString"] & /@
  primeFiles;
prototypeHashAtCompletion = FileHash[prototypeFile,
  "SHA256", "HexString"];
originalInputHashAtCompletion = FileHash[originalInputFile,
  "SHA256", "HexString"];
dependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
(* CFFR1_NATIVE_PROVENANCE_COMPLETION_BEGIN *)
nativeDependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, nativeDependencyFiles];
nativeBinaryHashAtCompletion = FileHash[nativeBinaryFile,
  "SHA256", "HexString"];
fixedPlanFLINTBinaryHashAtCompletion = FileHash[
  fixedPlanFLINTBinaryFile, "SHA256", "HexString"];
nativePrimeDriverHashAtCompletion = FileHash[nativePrimeDriverFile,
  "SHA256", "HexString"];
(* CFFR1_NATIVE_PROVENANCE_COMPLETION_END *)
driverHashAtCompletion = FileHash[$InputFileName,
  "SHA256", "HexString"];
preparationDriverHashAtCompletion = FileHash[preparationDriverFile,
  "SHA256", "HexString"];
primeDriverHashAtCompletion = FileHash[First[primeDriverFiles],
  "SHA256", "HexString"];
If[preparationHashAtCompletion =!= preparationHashBefore ||
    primeHashesAtCompletion =!= primeHashesBefore ||
    prototypeHashAtCompletion =!= prototypeHashBefore ||
    originalInputHashAtCompletion =!= originalInputHashBefore ||
    dependencyHashesAtCompletion =!= dependencyHashesBefore ||
    nativeDependencyHashesAtCompletion =!=
      nativeDependencyHashesBefore ||
    nativeBinaryHashAtCompletion =!= nativeBinaryHashBefore ||
    fixedPlanFLINTBinaryHashAtCompletion =!=
      fixedPlanFLINTBinaryHashBefore ||
    nativePrimeDriverHashAtCompletion =!=
      nativePrimeDriverHashBefore ||
    driverHashAtCompletion =!= driverHashBefore ||
    preparationDriverHashAtCompletion =!=
      preparationArtifact["DriverSHA256"] ||
    ! AllTrue[primeArtifacts,
      primeDriverHashAtCompletion === Lookup[#1,
        "DriverSHA256", None] &],
  finish["SourcesChangedBeforeCompletion", <|
    "PreparationSHA256AtCompletion" -> preparationHashAtCompletion,
    "PrimeSHA256AtCompletion" -> AssociationThread[
      primeFiles, primeHashesAtCompletion],
    "PrototypeSHA256AtCompletion" -> prototypeHashAtCompletion,
    "OriginalInputSHA256AtCompletion" ->
      originalInputHashAtCompletion,
    "DependencyHashesAtCompletion" ->
      dependencyHashesAtCompletion,
    "NativeDependencyHashesAtCompletion" ->
      nativeDependencyHashesAtCompletion,
    "ExpectedNativeDependencyHashes" -> nativeDependencyHashesBefore,
    "NativeBinarySHA256AtCompletion" ->
      nativeBinaryHashAtCompletion,
    "ExpectedNativeBinarySHA256" -> nativeBinaryHashBefore,
    "FixedPlanFLINTBinarySHA256AtCompletion" ->
      fixedPlanFLINTBinaryHashAtCompletion,
    "ExpectedFixedPlanFLINTBinarySHA256" ->
      fixedPlanFLINTBinaryHashBefore,
    "NativePrimeDriverSHA256AtCompletion" ->
      nativePrimeDriverHashAtCompletion,
    "ExpectedNativePrimeDriverSHA256" ->
      nativePrimeDriverHashBefore,
    "DriverSHA256AtCompletion" -> driverHashAtCompletion,
    "PreparationDriverSHA256AtCompletion" ->
      preparationDriverHashAtCompletion,
    "PrimeDriverSHA256AtCompletion" ->
      primeDriverHashAtCompletion|>, 97]];
If[writeAtomic[result] === $Failed,
  Print["CF300S12R2AGG FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300S12R2AGG RESULT status=", result["Status"],
  " primes=", trainingPrimes,
  " unseen=", unseenPrime,
  " all_signs=", Length[signChecks],
  " output=", outputFile];
Exit[0];
