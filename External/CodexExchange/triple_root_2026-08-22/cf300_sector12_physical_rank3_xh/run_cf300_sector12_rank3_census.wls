#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["CF300S12CENSUS FAIL usage=<project-root> <input-directory> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputDirectory = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];

If[! DirectoryQ[projectRoot] || ! DirectoryQ[inputDirectory],
  Print["CF300S12CENSUS FAIL missing project or input directory"];
  Exit[65]];

staleOutputTargets = Select[{outputFile, outputFile <> ".tmp"}, FileExistsQ];
If[staleOutputTargets =!= {},
  Print["CF300S12CENSUS FAIL stale output target: ", staleOutputTargets];
  Exit[93]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAffinePilot.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootReconstructionPrototype.wl"}]];

zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#1] === 0] &];

polynomialMinimumDegree[polynomial_, variable_Symbol] := Module[{rules},
  If[TrueQ[Expand[polynomial] === 0], Return[Infinity]];
  rules = CoefficientRules[Expand[polynomial], {variable}];
  If[rules === {}, Infinity, Min[First[First[#1]] & /@ rules]]
];

rationalValuation[expression_, variable_Symbol] := Module[
  {rational = Together[expression], numeratorDegree, denominatorDegree},
  If[TrueQ[rational === 0], Return[Infinity]];
  numeratorDegree = polynomialMinimumDegree[Numerator[rational], variable];
  denominatorDegree = polynomialMinimumDegree[Denominator[rational], variable];
  numeratorDegree - denominatorDegree
];

nonsquarePolynomialQ[polynomial_, variables_List] := Module[{factors},
  If[! PolynomialQ[polynomial, variables] ||
      TrueQ[Expand[polynomial] === 0], Return[False]];
  factors = Rest[FactorList[polynomial]];
  AnyTrue[factors, OddQ[Last[#1]] &]
];

squareClassCertificate[squares_List, variables_List] := Module[
  {masks, products, nonsquare},
  masks = Range[1, 2^Length[squares] - 1];
  products = Expand[
      CodexTripleRoot`TRMaskFactor[#1, squares]] & /@ masks;
  nonsquare = nonsquarePolynomialQ[#1, variables] & /@ products;
  <|"Masks" -> masks, "Products" -> products, "Nonsquare" -> nonsquare,
    "Independent" -> AllTrue[nonsquare, TrueQ],
    "Rank" -> If[AllTrue[nonsquare, TrueQ], Length[squares],
      Missing["NotCertified"]]|>
];

gradeSupport[channelComponent_List] := Select[
  Range[0, Last[Dimensions[channelComponent]] - 1],
  ! zeroQ[channelComponent[[All, All, All, #1 + 1]]] &];

writeAtomic[value_] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, outputFile, OverwriteTarget -> False]
];

finishBlocked[status_String, details_: <||>, code_: 2] := Module[{blocked},
  blocked = Join[<|"Status" -> status,
    "InputDirectory" -> inputDirectory,
    "CheckedAt" -> DateString["ISODateTime"]|>, details];
  writeAtomic[blocked];
  Print["CF300S12CENSUS RESULT status=", status,
    " output=", outputFile];
  Exit[code]
];

regularInputLowerSector[file_String] := Module[{matches},
  matches = StringCases[FileNameTake[file],
    RegularExpression["^CF300_12_([0-9]+)_input\\.wl$"] -> "$1"];
  If[Length[matches] =!= 1, $Failed, FromDigits[First[matches]]]
];

physicalInputLowerSector[file_String] := Module[{matches},
  matches = StringCases[FileNameTake[file],
    RegularExpression[
      "^CF300_12_([0-9]+)_physical_rank3_input\\.wl$"] -> "$1"];
  If[Length[matches] =!= 1, $Failed, FromDigits[First[matches]]]
];

stableArtifactRead[file_String] := Module[{hashBefore, artifact, hashAfter},
  hashBefore = Quiet[Check[
    FileHash[file, "SHA256", "HexString"], $Failed]];
  artifact = Quiet[Check[FeynFacet`FamilyArtifactRead[file], $Failed]];
  hashAfter = Quiet[Check[
    FileHash[file, "SHA256", "HexString"], $Failed]];
  <|"Status" -> If[StringQ[hashBefore] && hashBefore === hashAfter &&
        AssociationQ[artifact],
      "StableArtifactRead", "ArtifactReadFailed"],
    "File" -> file, "SHA256Before" -> hashBefore,
    "SHA256After" -> hashAfter, "Artifact" -> artifact|>
];

currentHashMatchesQ[binding_Rule] := Quiet[Check[
  StringQ[First[binding]] && StringQ[Last[binding]] &&
    FileExistsQ[First[binding]] &&
    FileHash[First[binding], "SHA256", "HexString"] === Last[binding],
  False]];

preparationABISummary[preparation_Association] := KeyTake[preparation,
  {"Status", "RootCount", "GradeCount", "RootSourceIndices",
    "RootFingerprints", "RootOrderingFingerprint", "Dimensions",
    "OneFormMetadata", "GaugeDenominator", "GaugeDenominatorDegrees",
    "GaugeSupport", "GaugeUnknownCount", "ResidueUnknownCount",
    "UnknownCount", "EquationsPerPoint", "ABIFingerprint",
    "ABIPayload"}];

sidecarResultFile = FileNameJoin[{inputDirectory, "sidecar_result.wl"}];
sidecarSuccessFile = sidecarResultFile <> ".mission_success.wl";
sidecarFailureFile = sidecarResultFile <> ".mission_failure.wl";
If[! FileExistsQ[sidecarResultFile] || ! FileExistsQ[sidecarSuccessFile] ||
    FileExistsQ[sidecarFailureFile],
  finishBlocked["CleanCheckedSidecarEvidenceMissing", <|
    "SidecarResultFile" -> sidecarResultFile,
    "SidecarResultExists" -> FileExistsQ[sidecarResultFile],
    "SuccessSentinelFile" -> sidecarSuccessFile,
    "SuccessSentinelExists" -> FileExistsQ[sidecarSuccessFile],
    "FailureSentinelExists" -> FileExistsQ[sidecarFailureFile]|>, 67]];

sidecarResultRead = stableArtifactRead[sidecarResultFile];
sidecarSuccessRead = stableArtifactRead[sidecarSuccessFile];
sidecarResult = Lookup[sidecarResultRead, "Artifact", $Failed];
sidecarSuccess = Lookup[sidecarSuccessRead, "Artifact", $Failed];
If[Lookup[sidecarResultRead, "Status", None] =!= "StableArtifactRead" ||
    Lookup[sidecarSuccessRead, "Status", None] =!= "StableArtifactRead" ||
    Lookup[sidecarResult, "Status", None] =!=
      "FoundPhysicalRank3Sector12Strip" ||
    Lookup[sidecarSuccess, "Status", None] =!=
      "CleanPhysicalMissionSuccess" ||
    ExpandFileName[Lookup[sidecarSuccess, "ResultFile", ""]] =!=
      sidecarResultFile ||
    Lookup[sidecarSuccess, "ResultSHA256", None] =!=
      sidecarResultRead["SHA256After"] ||
    Lookup[sidecarSuccess, "SourceHashes", None] =!=
      Lookup[sidecarResult, "SourceHashes", Missing["SourceHashes"]] ||
    Lookup[sidecarSuccess, "SourceIdentity", None] =!=
      Lookup[sidecarResult, "SourceIdentity", Missing["SourceIdentity"]] ||
    Lookup[sidecarSuccess, "MessageCount", None] =!= 0 ||
    ! TrueQ[Lookup[Lookup[sidecarResult, "SourceIdentity", <||>],
      "StableAtCompletionQ", False]],
  finishBlocked["CheckedSidecarEvidenceInvalid", <|
    "SidecarResultRead" -> KeyDrop[sidecarResultRead, {"Artifact"}],
    "SuccessSentinelRead" -> KeyDrop[sidecarSuccessRead, {"Artifact"}],
    "SidecarStatus" -> Lookup[sidecarResult, "Status", None],
    "SuccessStatus" -> Lookup[sidecarSuccess, "Status", None]|>, 68]];

selectedPhysicalInputFile = ExpandFileName[
  Lookup[sidecarResult, "SelectedInputFile", ""]];
selectedLowerSector = physicalInputLowerSector[selectedPhysicalInputFile];
If[selectedLowerSector === $Failed ||
    DirectoryName[selectedPhysicalInputFile] =!= inputDirectory ||
    ! FileExistsQ[selectedPhysicalInputFile],
  finishBlocked["SelectedPhysicalInputInvalid", <|
    "SelectedInputFile" -> selectedPhysicalInputFile,
    "ParsedLowerSector" -> selectedLowerSector|>, 69]];
selectedRegularInputFile = FileNameJoin[{inputDirectory,
  "CF300_12_" <> ToString[selectedLowerSector] <> "_input.wl"}];
If[! FileExistsQ[selectedRegularInputFile],
  finishBlocked["SelectedRegularInputMissing", <|
    "SelectedRegularInputFile" -> selectedRegularInputFile|>, 70]];

selectedPhysicalRead = stableArtifactRead[selectedPhysicalInputFile];
selectedRegularRead = stableArtifactRead[selectedRegularInputFile];
selectedPhysicalRecord = Lookup[selectedPhysicalRead, "Artifact", $Failed];
selectedRegularRecord = Lookup[selectedRegularRead, "Artifact", $Failed];
selectedStripProvenance = Select[
  Lookup[sidecarResult, "StripRecords", {}],
  Lookup[#1, "LowerSector", None] === selectedLowerSector &];
If[Lookup[selectedPhysicalRead, "Status", None] =!= "StableArtifactRead" ||
    Lookup[selectedRegularRead, "Status", None] =!= "StableArtifactRead" ||
    selectedPhysicalRead["SHA256After"] =!=
      Lookup[sidecarResult, "SelectedInputSHA256", None] ||
    ! SameQ[selectedPhysicalRecord, selectedRegularRecord] ||
    Length[selectedStripProvenance] =!= 1 ||
    ExpandFileName[Lookup[First[selectedStripProvenance], "InputFile", ""]]
      =!= selectedRegularInputFile ||
    Lookup[First[selectedStripProvenance], "InputSHA256", None] =!=
      selectedRegularRead["SHA256After"] ||
    Lookup[First[selectedStripProvenance], "ActiveGradeRank", None] =!= 3,
  finishBlocked["SelectedInputProvenanceMismatch", <|
    "SelectedLowerSector" -> selectedLowerSector,
    "PhysicalRead" -> KeyDrop[selectedPhysicalRead, {"Artifact"}],
    "RegularRead" -> KeyDrop[selectedRegularRead, {"Artifact"}],
    "SidecarSelectedInputSHA256" ->
      Lookup[sidecarResult, "SelectedInputSHA256", None],
    "SelectedStripProvenance" -> selectedStripProvenance,
    "PhysicalRegularAssociationSameQ" ->
      SameQ[selectedPhysicalRecord, selectedRegularRecord]|>, 71]];

sidecarEvidence = <|
  "SidecarResultFile" -> sidecarResultFile,
  "SidecarResultSHA256" -> sidecarResultRead["SHA256After"],
  "SuccessSentinelFile" -> sidecarSuccessFile,
  "SuccessSentinelSHA256" -> sidecarSuccessRead["SHA256After"],
  "SelectedLowerSector" -> selectedLowerSector,
  "PhysicalInputFile" -> selectedPhysicalInputFile,
  "PhysicalInputSHA256" -> selectedPhysicalRead["SHA256After"],
  "RegularInputFile" -> selectedRegularInputFile,
  "RegularInputSHA256" -> selectedRegularRead["SHA256After"],
  "PhysicalRegularAssociationSameQ" -> True,
  "SourceHashes" -> sidecarResult["SourceHashes"],
  "SourceIdentity" -> sidecarResult["SourceIdentity"]|>;

frame = FeynFacet`TransportFamilyChart["CF300"];
If[! AssociationQ[frame] ||
    Lookup[frame, "CoefficientField", None] =!= "Multiquadratic",
  Print["CF300S12CENSUS FAIL invalid CF300 multiquadratic frame"];
  Exit[66]];

inputCandidates = FileNames["CF300_12_*_input.wl", inputDirectory];
files = Select[inputCandidates,
  regularInputLowerSector[#1] =!= $Failed &];
files = SortBy[files, regularInputLowerSector];
rejectedInputCandidates = Complement[inputCandidates, files];
unexpectedInputCandidates = Complement[rejectedInputCandidates,
  {selectedPhysicalInputFile}];
If[! MemberQ[rejectedInputCandidates, selectedPhysicalInputFile] ||
    unexpectedInputCandidates =!= {},
  finishBlocked["UnexpectedSector12InputFilename", <|
    "SelectedPhysicalInputFile" -> selectedPhysicalInputFile,
    "RejectedInputCandidates" -> rejectedInputCandidates,
    "UnexpectedInputCandidates" -> unexpectedInputCandidates|>, 72]];
If[files === {},
  finishBlocked["NoSector12Inputs", <|
    "RejectedInputCandidates" -> rejectedInputCandidates|>,
    If[Environment["FACET_CENSUS_ALLOW_EMPTY"] === "True", 0, 2]]];

recordReads = stableArtifactRead /@ files;
If[! AllTrue[recordReads,
    Lookup[#1, "Status", None] === "StableArtifactRead" &],
  finishBlocked["Sector12InputReadFailed", <|
    "InputReads" -> (KeyDrop[#1, {"Artifact"}] & /@ recordReads)|>, 72]];
records = Lookup[recordReads, "Artifact"];
recordHashes = Lookup[recordReads, "SHA256After"];
census = MapThread[
  Function[{file, record, inputHash}, Module[
    {classificationSeconds, classification, decompositionSeconds,
     decomposition, channelStrip, componentSupports, activeGrades,
     activeRank, dimensions, forcingZero, forcingValuations,
     regulatorScale, filenameLowerSector},
    filenameLowerSector = regularInputLowerSector[file];
    If[filenameLowerSector === $Failed,
      Return[<|"File" -> file, "InputSHA256" -> inputHash,
        "Status" -> "InvalidInputFilename"|>]];
    If[! AssociationQ[record], Return[<|"File" -> file,
      "InputSHA256" -> inputHash, "Status" -> "InvalidArtifact"|>]];
    If[Lookup[record, "Family", None] =!= "CF300" ||
        Lookup[record, "Sector", None] =!= 12 ||
        Lookup[record, "LowerSector", None] =!= filenameLowerSector,
      Return[<|"File" -> file, "InputSHA256" -> inputHash,
        "Status" -> "InputMetadataMismatch",
        "FilenameLowerSector" -> filenameLowerSector,
        "RecordFamily" -> Lookup[record, "Family", None],
        "RecordSector" -> Lookup[record, "Sector", None],
        "RecordLowerSector" -> Lookup[record, "LowerSector", None]|>]];
    {classificationSeconds, classification} = AbsoluteTiming[
      CodexTripleRootStrip`TRClassifyStripRecord[record, frame]];
    If[Lookup[classification, "Status", None] =!=
        "ExactRootClassification",
      Return[Join[<|"File" -> file, "InputSHA256" -> inputHash,
        "ClassificationSeconds" -> classificationSeconds|>,
        classification]]];
    {decompositionSeconds, decomposition} = AbsoluteTiming[
      CodexTripleRootStrip`TRDecomposeStripRecord[record, frame]];
    If[Lookup[decomposition, "Status", None] =!=
        "ExactChannelDecomposition",
      Return[Join[<|"File" -> file, "InputSHA256" -> inputHash,
        "ClassificationSeconds" -> classificationSeconds,
        "DecompositionSeconds" -> decompositionSeconds|>,
        decomposition]]];
    channelStrip = decomposition["ChannelStrip"];
    componentSupports = gradeSupport /@ channelStrip;
    activeGrades = Union @@ componentSupports;
    activeRank = CodexTripleRoot`TRActiveRank[activeGrades,
      decomposition["RootCount"]];
    dimensions = Dimensions[record["Strip"][[3, 1]]];
    forcingZero = zeroQ[record["Strip"][[3]]];
    forcingValuations = DeleteCases[
      rationalValuation[#1, record["Regulator"]] & /@
        Flatten[channelStrip[[3]]], Infinity];
    regulatorScale = If[forcingValuations === {}, 0,
      Max[0, -Min[forcingValuations]]];
    <|"File" -> file, "InputSHA256" -> inputHash,
      "FileBytes" -> FileByteCount[file],
      "Status" -> "ExactPhysicalStripCensus",
      "Family" -> Lookup[record, "Family", None],
      "Sector" -> Lookup[record, "Sector", None],
      "LowerSector" -> Lookup[record, "LowerSector", None],
      "Dimensions" -> dimensions,
      "MatrixElementCount" -> Times @@ dimensions,
      "LeafCount" -> LeafCount[record["Strip"]],
      "RootIndices" -> decomposition["RootIndices"],
      "RootCount" -> decomposition["RootCount"],
      "RootSquares" -> decomposition["RootSquares"],
      "ChannelCount" -> decomposition["ChannelCount"],
      "RoundTripExact" -> decomposition["RoundTripExact"],
      "ComponentGradeSupport" -> AssociationThread[
        {"UpperDiagonal", "LowerDiagonal", "Forcing"},
        componentSupports],
      "ActiveGrades" -> activeGrades,
      "ActiveGradeRank" -> activeRank,
      "ForcingZero" -> forcingZero,
      "ForcingEpsilonValuations" -> forcingValuations,
      "SuggestedRegulatorScalePower" -> regulatorScale,
      "ClassificationSeconds" -> classificationSeconds,
      "DecompositionSeconds" -> decompositionSeconds|>
  ]], {files, records, recordHashes}];

invalidInputRecords = Select[census, MemberQ[
    {"InvalidInputFilename", "InvalidArtifact", "InputMetadataMismatch"},
    Lookup[#1, "Status", None]] &];
If[invalidInputRecords =!= {},
  finishBlocked["Sector12InputProvenanceInvalid", <|
    "InvalidInputRecords" -> invalidInputRecords,
    "SidecarEvidence" -> sidecarEvidence|>, 73]];

rank3 = Select[census,
  Lookup[#1, "Status", None] === "ExactPhysicalStripCensus" &&
    Lookup[#1, "RootCount", 0] === 3 &&
    Lookup[#1, "ActiveGradeRank", 0] === 3 &&
    ! TrueQ[Lookup[#1, "ForcingZero", True]] &];

If[rank3 === {},
  finishBlocked["SidecarSelectedRank3NotReproduced", <|
    "SidecarEvidence" -> sidecarEvidence,
    "RejectedInputCandidates" -> rejectedInputCandidates,
    "Census" -> census|>, 3]];

selected = First[SortBy[rank3,
  {Lookup[#1, "MatrixElementCount", Infinity],
    Lookup[#1, "LeafCount", Infinity],
    Lookup[#1, "FileBytes", Infinity],
    Lookup[#1, "LowerSector", Infinity]} &]];
boundRank3 = Select[rank3,
  ExpandFileName[Lookup[#1, "File", ""]] ===
    selectedRegularInputFile &];
If[Length[boundRank3] =!= 1 ||
    ! SameQ[selected, First[boundRank3]] ||
    Lookup[First[boundRank3], "InputSHA256", None] =!=
      sidecarEvidence["RegularInputSHA256"],
  finishBlocked["SidecarSelectedRank3Mismatch", <|
    "SidecarEvidence" -> sidecarEvidence,
    "RejectedInputCandidates" -> rejectedInputCandidates,
    "Census" -> census, "Rank3Candidates" -> rank3,
    "HeuristicSelection" -> selected|>, 5]];
selected = First[boundRank3];
selectedRecord = records[[First@FirstPosition[files, selected["File"]]]];
variables = selectedRecord["Variables"];
roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
squareClasses = squareClassCertificate[
  Lookup[roots, "RootSquare", {}], variables];

scalePower = selected["SuggestedRegulatorScalePower"];
scaledRecord = Join[selectedRecord, <|"Strip" -> ReplacePart[
  selectedRecord["Strip"], 3 ->
    Map[Together[selectedRecord["Regulator"]^scalePower #1] &,
      selectedRecord["Strip"][[3]], {2}]]|>];

Print["CF300S12CENSUS selected=", {12, selected["LowerSector"]},
  " dimensions=", selected["Dimensions"],
  " roots=", selected["RootIndices"],
  " grades=", selected["ActiveGrades"],
  " scale=eps^", scalePower];

{preparationSeconds, preparation} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    scaledRecord, frame]];
preparationSummary = If[AssociationQ[preparation],
  preparationABISummary[preparation], preparation];

evidenceHashBindings = {
  sidecarEvidence["SidecarResultFile"] ->
    sidecarEvidence["SidecarResultSHA256"],
  sidecarEvidence["SuccessSentinelFile"] ->
    sidecarEvidence["SuccessSentinelSHA256"],
  sidecarEvidence["PhysicalInputFile"] ->
    sidecarEvidence["PhysicalInputSHA256"],
  sidecarEvidence["RegularInputFile"] ->
    sidecarEvidence["RegularInputSHA256"]};
If[! AllTrue[evidenceHashBindings, currentHashMatchesQ],
  finishBlocked["SidecarEvidenceChangedDuringCensus", <|
    "SidecarEvidence" -> sidecarEvidence,
    "EvidenceHashBindings" -> evidenceHashBindings,
    "PreparationSeconds" -> preparationSeconds|>, 74]];

result = <|"Status" -> If[
    TrueQ[squareClasses["Independent"]] &&
      Lookup[preparation, "Status", None] === "PreparedReconstruction" &&
      CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
    "PreparedPhysicalRank3Strip", "PhysicalRank3PreparationBlocked"],
  "InputDirectory" -> inputDirectory,
  "RejectedInputCandidates" -> rejectedInputCandidates,
  "SidecarEvidence" -> sidecarEvidence, "Census" -> census,
  "Selected" -> selected, "SquareClassCertificate" -> squareClasses,
  "ScaledEquation" -> <|"ScalePower" -> scalePower,
    "Meaning" -> "The forcing, gauge and residue variables are multiplied by eps^ScalePower; divide reconstructed gauge and residues by that power for the original strip."|>,
  "PreparationSeconds" -> preparationSeconds,
  "PreparationSummary" -> preparationSummary|>;
writeAtomic[result];
Print["CF300S12CENSUS RESULT status=", result["Status"],
  " prep_seconds=", Round[preparationSeconds, 0.001],
  " output=", outputFile];
Exit[If[result["Status"] === "PreparedPhysicalRank3Strip", 0, 4]];
