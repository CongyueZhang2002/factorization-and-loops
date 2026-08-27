#!/usr/bin/env wolframscript

$HistoryLength = 0;
missionStarted = AbsoluteTime[];
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 5,
  Print["CF300S12SIDECAR FAIL usage=<project-root> <sector10-state.wl> <sector11-checkpoint.wl> <output-directory> <result.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
stateFile = ExpandFileName[arguments[[2]]];
checkpointFile = ExpandFileName[arguments[[3]]];
outputDirectory = ExpandFileName[arguments[[4]]];
resultFile = ExpandFileName[arguments[[5]]];
exchangeDirectory = DirectoryName[DirectoryName[$InputFileName]];
sourceStateFile = stateFile;
sourceCheckpointFile = checkpointFile;

If[! DirectoryQ[projectRoot] || ! FileExistsQ[stateFile] ||
    ! FileExistsQ[checkpointFile],
  Print["CF300S12SIDECAR FAIL missing project/state/checkpoint"];
  Exit[65]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];

zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#1] === 0] &];
kinematicEpsilonFreeQ[expression_, epsilon_Symbol] :=
  FreeQ[Map[Together[#1/epsilon] &, expression, {3}], epsilon];

writeAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file],
      CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

finish[status_String, data_: <||>, code_: 2] := Module[{value},
  value = Join[<|"Status" -> status, "StateFile" -> stateFile,
    "CheckpointFile" -> checkpointFile,
    "TotalSeconds" -> N[AbsoluteTime[] - missionStarted]|>, data];
  writeAtomic[value, resultFile];
  Print["CF300S12SIDECAR RESULT status=", status,
    " output=", resultFile];
  Exit[code]
];

epsilonOnlyPart[polynomial_, variables_List, epsilon_Symbol] := Module[
  {factorization, selected},
  factorization = Quiet[Check[FactorList[polynomial], $Failed]];
  If[factorization === $Failed || factorization === {}, Return[$Failed]];
  selected = Select[Rest[factorization],
    FreeQ[First[#1], Alternatives @@ variables] &&
      ! FreeQ[First[#1], epsilon] &];
  Times @@ (First[#1]^Last[#1] & /@ selected)
];

regulatorFactorCandidate[expression_, variables_List,
    epsilon_Symbol] := Module[
  {q, sampled, sampleRules, numeratorPart, denominatorPart},
  q = Together[expression/epsilon];
  (* Bilinear115 rational point: 1-4 x y = (9/10)^2.  Candidate
     discovery is univariate in eps; acceptance remains the exact
     unspecialized division gate over every installed-row entry. *)
  sampleRules = Thread[variables -> {1/10, 19/40}];
  sampled = Quiet[Check[Together[q /. sampleRules], $Failed]];
  If[sampled === $Failed ||
      ! FreeQ[sampled,
        Indeterminate | ComplexInfinity | DirectedInfinity[_]],
    Return[$Failed]];
  numeratorPart = epsilonOnlyPart[
    Numerator[sampled], variables, epsilon];
  denominatorPart = epsilonOnlyPart[
    Denominator[sampled], variables, epsilon];
  If[MemberQ[{numeratorPart, denominatorPart}, $Failed] ||
      TrueQ[denominatorPart === 0], $Failed,
    Together[numeratorPart/denominatorPart]]
];

gradeSupport[channelComponent_List] := Select[
  Range[0, Last[Dimensions[channelComponent]] - 1],
  ! zeroQ[channelComponent[[All, All, All, #1 + 1]]] &];

nonsquarePolynomialQ[polynomial_, variables_List] := Module[{factors},
  If[! PolynomialQ[polynomial, variables] ||
      TrueQ[Expand[polynomial] === 0], Return[False]];
  factors = Rest[FactorList[polynomial]];
  AnyTrue[factors, OddQ[Last[#1]] &]
];

squareClassCertificate[squares_List, variables_List] := Module[
  {masks = Range[1, 2^Length[squares] - 1], products, nonsquare},
  products = Expand[
      CodexTripleRoot`TRMaskFactor[#1, squares]] & /@ masks;
  nonsquare = nonsquarePolynomialQ[#1, variables] & /@ products;
  <|"Masks" -> masks, "Products" -> products,
    "Nonsquare" -> nonsquare,
    "Independent" -> AllTrue[nonsquare, TrueQ],
    "Rank" -> If[AllTrue[nonsquare, TrueQ], Length[squares],
      Missing["NotCertified"]]|>
];

(* Pin immutable byte-identical snapshots before any semantic read.  The
   live sector state may advance after row 11; this mission either uses the
   exact sector-10 bytes announced at launch or fails closed. *)
sourceSnapshotDirectory = FileNameJoin[{outputDirectory,
  "source_identity_snapshot"}];
stateSnapshotFile = FileNameJoin[{sourceSnapshotDirectory,
  FileNameTake[sourceStateFile]}];
checkpointSnapshotFile = FileNameJoin[{sourceSnapshotDirectory,
  FileNameTake[sourceCheckpointFile]}];
If[FileExistsQ[stateSnapshotFile] ||
    FileExistsQ[checkpointSnapshotFile],
  finish["StaleSourceSnapshotTarget", <|
    "SnapshotDirectory" -> sourceSnapshotDirectory|>, 93]];
If[! DirectoryQ[sourceSnapshotDirectory],
  CreateDirectory[sourceSnapshotDirectory,
    CreateIntermediateDirectories -> True]];
stateHashBefore = FileHash[sourceStateFile, "SHA256", "HexString"];
checkpointHashBefore = FileHash[sourceCheckpointFile,
  "SHA256", "HexString"];
CopyFile[sourceStateFile, stateSnapshotFile];
CopyFile[sourceCheckpointFile, checkpointSnapshotFile];
stateHashAfterCopy = FileHash[sourceStateFile, "SHA256", "HexString"];
checkpointHashAfterCopy = FileHash[sourceCheckpointFile,
  "SHA256", "HexString"];
stateSnapshotHash = FileHash[stateSnapshotFile, "SHA256", "HexString"];
checkpointSnapshotHash = FileHash[checkpointSnapshotFile,
  "SHA256", "HexString"];
sourceIdentityPinnedQ = stateHashBefore === stateHashAfterCopy ===
    stateSnapshotHash &&
  checkpointHashBefore === checkpointHashAfterCopy ===
    checkpointSnapshotHash;
If[! sourceIdentityPinnedQ,
  finish["SourceIdentityChangedDuringSnapshot", <|
    "SourceHashesBefore" -> <|"State" -> stateHashBefore,
      "Checkpoint" -> checkpointHashBefore|>,
    "SourceHashesAfterCopy" -> <|"State" -> stateHashAfterCopy,
      "Checkpoint" -> checkpointHashAfterCopy|>,
    "SnapshotHashes" -> <|"State" -> stateSnapshotHash,
      "Checkpoint" -> checkpointSnapshotHash|>|>, 94]];
stateHash = stateSnapshotHash;
checkpointHash = checkpointSnapshotHash;
state = FeynFacet`FamilyArtifactRead[stateSnapshotFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointSnapshotFile];
stateSnapshotHashAfterRead = FileHash[stateSnapshotFile,
  "SHA256", "HexString"];
checkpointSnapshotHashAfterRead = FileHash[checkpointSnapshotFile,
  "SHA256", "HexString"];
If[stateSnapshotHashAfterRead =!= stateHash ||
    checkpointSnapshotHashAfterRead =!= checkpointHash ||
    ! AssociationQ[state] || ! AssociationQ[checkpoint],
  finish["SourceArtifactReadFailed", <||>, 66]];
sourceIdentityCurrentQ[] := Quiet[Check[
  FileHash[sourceStateFile, "SHA256", "HexString"] === stateHash &&
    FileHash[sourceCheckpointFile, "SHA256", "HexString"] ===
      checkpointHash &&
    FileHash[stateSnapshotFile, "SHA256", "HexString"] === stateHash &&
    FileHash[checkpointSnapshotFile, "SHA256", "HexString"] ===
      checkpointHash, False]];

ranges = Lookup[state, "Ranges", $Failed];
connection = Lookup[state, "A", $Failed];
transformation = Lookup[state, "S", $Failed];
inverse = Lookup[state, "SInverse", $Failed];
If[Lookup[state, "Sector", None] =!= 10 ||
    ! MatchQ[ranges, {{__Integer} ..}] || Length[ranges] =!= 12 ||
    Flatten[ranges] =!= Range[24] ||
    Dimensions[connection] =!= {2, 24, 24} ||
    Dimensions[transformation] =!= {24, 24} ||
    Dimensions[inverse] =!= {24, 24},
  finish["InvalidSector10StateShape", <|
    "StateSector" -> Lookup[state, "Sector", None],
    "ConnectionDimensions" -> Quiet[Check[Dimensions[connection], None]]|>,
    67]];

variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilonCandidates = DeleteDuplicates[Cases[
  {connection, Lookup[checkpoint, "PrevD", {}]},
  symbol_Symbol /; SymbolName[symbol] === "eps", Infinity]];
If[Length[epsilonCandidates] =!= 1,
  finish["RegulatorSymbolAmbiguous", <|
    "Candidates" -> HoldForm /@ epsilonCandidates|>, 68]];
epsilon = First[epsilonCandidates];
frame = FeynFacet`TransportFamilyChart["CF300"];
frameCertificate = If[AssociationQ[frame],
  FeynFacet`TransportChartVerify[frame], $Failed];
frameFingerprint = If[AssociationQ[frame], Hash[
    KeyTake[frame, {"Name", "Variables", "Subst", "Roots", "Parents"}],
    "SHA256", "HexString"], $Failed];
If[! AssociationQ[frame] ||
    Lookup[frame, "Name", None] =!= "Multiquadratic3" ||
    Lookup[frame, "CoefficientField", None] =!= "Multiquadratic" ||
    ! TrueQ[Lookup[frameCertificate, "OK", False]] ||
    Lookup[state, "ChartFingerprint", None] =!= frameFingerprint,
  finish["InvalidCF300Frame", <|
    "FrameName" -> Lookup[frame, "Name", None],
    "FrameCertificate" -> frameCertificate,
    "StateChartFingerprint" -> Lookup[state, "ChartFingerprint", None],
    "CurrentChartFingerprint" -> frameFingerprint|>, 69]];

row11 = ranges[[11]];
row12 = ranges[[12]];
lower11 = Range[First[row11] - 1];
prefix11 = Range[Last[row11]];
checkpointConnectionHash = Hash[
  connection[[All, prefix11, prefix11]] /.
    epsilon -> CANONICA`eps, "SHA256", "HexString"];
If[Lookup[checkpoint, "Sector", None] =!= 11 ||
    Lookup[checkpoint, "SubSize", None] =!= Length[row11] ||
    Lookup[checkpoint, "Truncation", None] =!= Last[row11] ||
    Lookup[checkpoint, "ConnectionHash", None] =!=
      checkpointConnectionHash,
  finish["CheckpointConnectionIdentityMismatch", <|
    "CheckpointSector" -> Lookup[checkpoint, "Sector", None],
    "StoredConnectionHash" -> Lookup[checkpoint, "ConnectionHash", None],
    "RecomputedConnectionHash" -> checkpointConnectionHash|>, 70]];

gauge11 = Lookup[checkpoint, "PrevD", $Failed];
forms11 = Lookup[checkpoint, "SolvedForms", $Failed];
stripSolvers11 = Lookup[checkpoint, "StripSolvers", $Failed];
lowerBlockSizes11 = Length /@ ranges[[Range[10]]];
checkpointGaugeShapeQ =
  FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
    gauge11, Length[row11], lowerBlockSizes11];
checkpointSolverShapeQ =
  FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
    stripSolvers11, gauge11, 11, lowerBlockSizes11];
orderedSolverProvenanceQ = ListQ[stripSolvers11] &&
  Length[stripSolvers11] === 10 &&
  Lookup[stripSolvers11, "Sector", {}] === ConstantArray[11, 10] &&
  Lookup[stripSolvers11, "LowerSector", {}] === Reverse[Range[10]] &&
  AllTrue[stripSolvers11, Function[solver,
    If[Lookup[solver, "Method", None] === "ZeroForcing",
      TrueQ[Lookup[solver, "ExactDLog", False]],
      TrueQ[Lookup[Lookup[solver, "FrameCertificate", <||>],
        "Exact", False]]]]];
If[Dimensions[gauge11] =!= {Length[row11], Length[lower11]} ||
    ! AssociationQ[forms11] || Sort[Keys[forms11]] =!= Range[10] ||
    ! checkpointGaugeShapeQ || ! checkpointSolverShapeQ ||
    ! orderedSolverProvenanceQ,
  finish["IncompleteSector11Checkpoint", <|
    "GaugeDimensions" -> Quiet[Check[Dimensions[gauge11], None]],
    "SolvedFormKeys" -> Quiet[Check[Sort[Keys[forms11]], None]],
    "CheckpointGaugeShapeQ" -> checkpointGaugeShapeQ,
    "CheckpointSolverShapeQ" -> checkpointSolverShapeQ,
    "OrderedSolverProvenanceQ" -> orderedSolverProvenanceQ,
    "ObservedSolverOrder" -> If[ListQ[stripSolvers11],
      Lookup[stripSolvers11, "LowerSector", {}], None]|>, 71]];

solved11 = Association@Table[
  lowerSector -> gauge11[[All, ranges[[lowerSector]]]],
  {lowerSector, Range[10]}];
blockColumns11 = Association@Table[
  lowerSector -> ranges[[lowerSector]], {lowerSector, Range[10]}];
If[! sourceIdentityCurrentQ[],
  finish["SourceIdentityAdvancedBeforeReplay", <|
    "PinnedStateSHA256" -> stateHash,
    "PinnedCheckpointSHA256" -> checkpointHash|>, 95]];
{resumeReplaySeconds, resumeReplay11} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeHydrateResume[
    checkpoint, checkpointSnapshotFile, solved11, forms11,
    "CF300", 11, variables, epsilon, frame, ranges,
    DirectoryName[sourceCheckpointFile], connection,
    "KernelCount" -> 1, "FinalCheck" -> "Exact",
    "MinimumCachedPrimeCount" -> 3, "Verbose" -> True]];
sourceIdentityStableAfterReplayQ = sourceIdentityCurrentQ[];
replayRecords11 = Lookup[resumeReplay11, "ReplayRecords", {}];
replayExactPolicyQ = ListQ[replayRecords11] &&
  Length[replayRecords11] === 10 &&
  Lookup[replayRecords11, "LowerSector", {}] === Range[10] &&
  Lookup[replayRecords11, "Action", {}] ===
    ConstantArray["VerifiedExisting", 10] &&
  AllTrue[replayRecords11,
    TrueQ[Lookup[#1, "CheckpointStripSameQ", False]] &&
      TrueQ[Lookup[#1, "GaugeSameQ", False]] &&
      TrueQ[Lookup[#1, "FrameCertificate", False]] &&
      TrueQ[Lookup[#1, "CopiedArtifactsUnchanged", False]] &] &&
  AllTrue[Range[10], Function[lowerSector,
    Module[{replay, summary},
      replay = SelectFirst[replayRecords11,
        Lookup[#1, "LowerSector", None] === lowerSector &,
        Missing["NoReplay"]];
      summary = SelectFirst[stripSolvers11,
        Lookup[#1, "LowerSector", None] === lowerSector &,
        Missing["NoSummary"]];
      AssociationQ[replay] && AssociationQ[summary] &&
        TrueQ[Lookup[replay, "ExactDLog", False]] &&
        Lookup[replay, "Method", None] ===
          Lookup[summary, "Method", None]
    ]]];
installedRow11 = Lookup[resumeReplay11, "InstalledRow", Automatic];
forms11 = Lookup[resumeReplay11, "SolvedForms", $Failed];
If[Lookup[resumeReplay11, "Status", None] =!= "Verified" ||
    ! TrueQ[Lookup[resumeReplay11, "ActivateInstalledRow", False]] ||
    Lookup[resumeReplay11, "MissingLowerSectors", None] =!= {} ||
    ! sourceIdentityStableAfterReplayQ ||
    ! replayExactPolicyQ || ! AssociationQ[forms11] ||
    ! SameQ[forms11, Lookup[checkpoint, "SolvedForms", $Failed]] ||
    ! ListQ[installedRow11] ||
    Dimensions[installedRow11] =!= {2, Length[row11], Length[lower11]} ||
    ! FreeQ[installedRow11, Alternatives[_Missing, Automatic, $Failed]],
  finish["Sector11ReplayVerificationFailed", <|
    "ResumeReplaySeconds" -> resumeReplaySeconds,
    "SourceIdentityStableAfterReplayQ" ->
      sourceIdentityStableAfterReplayQ,
    "ReplayExactPolicyQ" -> replayExactPolicyQ,
    "ResumeReplay" -> resumeReplay11|>, 72]];

nonzeroInstalled = Select[Flatten[installedRow11],
  ! TrueQ[Together[#1] === 0] &];
factorCandidates = DeleteCases[DeleteDuplicates[
  regulatorFactorCandidate[#1, variables, epsilon] & /@
    nonzeroInstalled, SameTest ->
      (TrueQ[Together[#1 - #2] === 0] &)], $Failed];
validFactors = Select[factorCandidates, Function[candidate,
  ! TrueQ[Together[candidate] === 0] &&
    AllTrue[nonzeroInstalled, Function[entry,
      FreeQ[Together[(entry/epsilon)/candidate], epsilon]]]]];
If[validFactors === {},
  finish["Sector11CommonRegulatorFactorNotFound", <|
    "CandidateCount" -> Length[factorCandidates],
    "InstalledNonzeroCount" -> Length[nonzeroInstalled]|>, 73]];
regulatorFactor = First[SortBy[validFactors, LeafCount]];

Print["CF300S12SIDECAR row11_common_factor=",
  InputForm[regulatorFactor],
  " installed_nonzero=", Length[nonzeroInstalled]];

{deferredSeconds, deferred} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeApply[
    connection, transformation, inverse, row11, gauge11,
    variables, installedRow11, "Deferred"]];
If[Lookup[deferred, "Status", None] =!= "OK",
  finish["DeferredSector11ApplyFailed", <|
    "DeferredSeconds" -> deferredSeconds,
    "DeferredResult" -> deferred|>, 74]];

deferredConnection = deferred["Connection"];
factorizedConnection = deferredConnection;
(* Prefix transformation diag(1,...,1,f,f).  Only the installed row and
   the sector-12 bottom-left block can change.  Keep every additive
   bottom-left term separate; do not Together the future block. *)
prefixFactor = DiagonalMatrix[ReplacePart[
  ConstantArray[1, Length[prefix11]], Thread[row11 -> regulatorFactor]]];
prefixFactorInverse = DiagonalMatrix[ReplacePart[
  ConstantArray[1, Length[prefix11]],
  Thread[row11 -> 1/regulatorFactor]]];
Do[
  factorizedConnection[[mu, row11, lower11]] =
    Map[Together[#1/regulatorFactor] &,
      deferredConnection[[mu, row11, lower11]], {2}],
  {mu, 2}];
rawTerms[expression_] := If[SameQ[expression, 0], {},
  If[Head[expression] === Plus, List @@ expression, {expression}]];
rawBottomLeftTerms = Table[
  Map[<|"SourceColumn" -> column,
      "PrefixCoefficient" -> If[MemberQ[row11, column],
        regulatorFactor, 1],
      "SourceTerm" -> #1,
      "Expression" -> #1 If[MemberQ[row11, column],
        regulatorFactor, 1]|> &,
    rawTerms[deferredConnection[[mu, row12[[i]], column]]]],
  {mu, 2}, {i, Length[row12]}, {column, prefix11}];
Do[
  factorizedConnection[[mu, row12[[i]], column]] =
    Total[Lookup[rawBottomLeftTerms[[mu, i, column]],
      "Expression", {}]],
  {mu, 2}, {i, Length[row12]}, {column, prefix11}];

prefixFactoredQ = kinematicEpsilonFreeQ[
  factorizedConnection[[All, prefix11, prefix11]], epsilon];
inverseFactorQ = zeroQ[Map[Together,
    prefixFactor . prefixFactorInverse -
      IdentityMatrix[Length[prefix11]], {2}]] &&
  zeroQ[Map[Together,
    prefixFactorInverse . prefixFactor -
      IdentityMatrix[Length[prefix11]], {2}]];
prefixConjugationQ = And @@ Table[zeroQ[Map[Together,
    factorizedConnection[[mu, prefix11, prefix11]] -
      prefixFactorInverse .
        deferredConnection[[mu, prefix11, prefix11]] . prefixFactor,
    {2}]], {mu, 2}];
If[! prefixFactoredQ || ! inverseFactorQ || ! prefixConjugationQ,
  finish["Sector11PrefixFactorExactGateFailed", <|
    "RegulatorFactor" -> regulatorFactor,
    "PrefixFactoredQ" -> prefixFactoredQ,
    "InverseFactorQ" -> inverseFactorQ,
    "PrefixConjugationQ" -> prefixConjugationQ,
    "DeferredSeconds" -> deferredSeconds,
    "DeferredStatistics" -> deferred["Statistics"]|>, 75]];

roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
squareClasses = squareClassCertificate[
  Lookup[roots, "RootSquare", {}], variables];
If[! TrueQ[squareClasses["Independent"]] ||
    squareClasses["Rank"] =!= 3,
  finish["CF300SquareClassRankGateFailed", <|
    "SquareClassCertificate" -> squareClasses|>, 76]];

canonicalRational[expression_] := Module[{q = Together[expression]},
  {Expand[Numerator[q]], Expand[Denominator[q]]}];
fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

(* Preserve the sector-12 bbar as an additive term graph.  Base leaves
   come directly from the deferred row-11 update/right prefix action;
   every recursive -D.A contraction is one separate product leaf. *)
blockTermGraph[lowerSector_Integer, solved_Association] := Module[
  {upperRows = row12, lowerRows = ranges[[lowerSector]], higher,
   topTerms, bottomTerms, forcingTerms},
  higher = Reverse[Sort[Select[Keys[solved], lowerSector < # < 12 &]]];
  topTerms = Table[Module[{expression = Together[
      factorizedConnection[[mu, upperRows[[i]], upperRows[[j]]]] /
        epsilon]},
    If[TrueQ[expression === 0], {}, {<|"Kind" -> "TopDiagonal",
      "Component" -> 1, "Mu" -> mu, "Row" -> i, "Column" -> j,
      "Expression" -> expression|>}]],
    {mu, 2}, {i, Length[upperRows]}, {j, Length[upperRows]}];
  bottomTerms = Table[Module[{expression = Together[
      factorizedConnection[[mu, lowerRows[[i]], lowerRows[[j]]]] /
        epsilon]},
    If[TrueQ[expression === 0], {}, {<|"Kind" -> "BottomDiagonal",
      "Component" -> 2, "Mu" -> mu, "Row" -> i, "Column" -> j,
      "Expression" -> expression|>}]],
    {mu, 2}, {i, Length[lowerRows]}, {j, Length[lowerRows]}];
  forcingTerms = Table[Module[{column = lowerRows[[j]], base,
      corrections},
    base = Map[Join[#1, <|"Kind" -> "DeferredBase",
        "Component" -> 3, "Mu" -> mu, "Row" -> i,
        "Column" -> j, "GlobalColumn" -> column|>] &,
      rawBottomLeftTerms[[mu, i, column]]];
    corrections = Cases[Table[Module[{gaugeEntry, connectionEntry},
        gaugeEntry = solved[m][[i, k]];
        connectionEntry = factorizedConnection[[mu,
          ranges[[m, k]], column]];
        If[SameQ[gaugeEntry, 0] || SameQ[connectionEntry, 0], Nothing,
          <|"Kind" -> "RecursiveProduct", "Component" -> 3,
            "Mu" -> mu, "Row" -> i, "Column" -> j,
            "GlobalColumn" -> column, "IntermediateSector" -> m,
            "IntermediateIndex" -> k,
            "Expression" -> -gaugeEntry connectionEntry|>]
      ], {m, higher}, {k, Length[ranges[[m]]]}], _Association,
      Infinity];
    Join[base, corrections]],
    {mu, 2}, {i, Length[upperRows]}, {j, Length[lowerRows]}];
  {topTerms, bottomTerms, forcingTerms}
];

liftLocalChannels[channels_List, indices_List, rank_Integer] :=
  CodexTripleRootStrip`TRLiftLocalChannels[channels, indices, rank];

channelizeLeaf[leaf_Association, frame_Association, rank_Integer,
    lowerSector_Integer] := Module[
  {component, mu, expression, leafStrip, leafRecord, classification,
   decomposition, localChannels, globalChannels, leafFingerprint},
  component = leaf["Component"];
  mu = leaf["Mu"];
  expression = leaf["Expression"];
  leafStrip = ConstantArray[0, {3, 2, 1, 1}];
  leafStrip[[component, mu, 1, 1]] = expression;
  leafRecord = <|"Family" -> "CF300", "Sector" -> 12,
    "LowerSector" -> lowerSector, "Variables" -> variables,
    "Regulator" -> epsilon, "Strip" -> leafStrip|>;
  classification = CodexTripleRootStrip`TRClassifyStripRecord[
    leafRecord, frame];
  If[Lookup[classification, "Status", None] =!=
      "ExactRootClassification",
    Return[Join[leaf, <|"Status" -> "LeafClassificationFailed",
      "Classification" -> classification|>]]];
  decomposition = CodexTripleRootStrip`TRDecomposeStripRecord[
    leafRecord, frame];
  If[Lookup[decomposition, "Status", None] =!=
        "ExactChannelDecomposition" ||
      ! TrueQ[Lookup[decomposition, "RoundTripExact", False]] ||
      Lookup[decomposition, "RootIndices", {}] =!=
        Lookup[classification, "RootIndices", {}],
    Return[Join[leaf, <|"Status" -> "LeafDecompositionFailed",
      "Classification" -> classification,
      "Decomposition" -> KeyDrop[decomposition, {"ChannelStrip"}]|>]]];
  localChannels =
    decomposition["ChannelStrip"][[component, mu, 1, 1]];
  globalChannels = liftLocalChannels[localChannels,
    classification["RootIndices"], rank];
  If[globalChannels === $Failed ||
      Length[globalChannels] =!= 2^rank,
    Return[Join[leaf, <|"Status" -> "LeafChannelLiftFailed",
      "RootIndices" -> classification["RootIndices"],
      "LocalChannelCount" -> Length[localChannels],
      "GlobalRank" -> rank|>]]];
  leafFingerprint = fingerprint[<|
    "Provenance" -> KeyDrop[leaf, {"Expression", "SourceTerm"}],
    "RootIndices" -> classification["RootIndices"],
    "Channels" -> (canonicalRational /@ globalChannels)|>];
  Join[leaf, <|"Status" -> "LeafChannelized",
    "RootIndices" -> classification["RootIndices"],
    "RadicalBases" -> classification["RadicalBases"],
    "GlobalChannels" -> globalChannels,
    "RoundTripExact" -> True,
    "LeafFingerprint" -> leafFingerprint|>]
];

channelizeCell[leaves_List, component_Integer, mu_Integer,
    row_Integer, column_Integer, frame_Association, rank_Integer,
    lowerSector_Integer] := Module[{processed, failure, channels},
  processed = channelizeLeaf[#1, frame, rank, lowerSector] & /@ leaves;
  failure = SelectFirst[processed,
    Lookup[#1, "Status", None] =!= "LeafChannelized" &,
    Missing["NoFailure"]];
  If[! MissingQ[failure], Return[<|
    "Status" -> "CellChannelizationFailed", "Component" -> component,
    "Mu" -> mu, "Row" -> row, "Column" -> column,
    "Failure" -> failure|>]];
  channels = If[processed === {}, ConstantArray[0, 2^rank],
    Together /@ (Total /@
      Transpose[(Lookup[#1, "GlobalChannels"] &) /@ processed])];
  <|"Status" -> "ChannelizedCell", "Leaves" -> processed,
    "Channels" -> channels|>
];

channelizeComponent[componentGraph_List, component_Integer,
    frame_Association, rank_Integer, lowerSector_Integer] := Module[
  {rows, columns, cells, failure},
  rows = Length[componentGraph[[1]]];
  columns = Length[componentGraph[[1, 1]]];
  cells = Table[channelizeCell[
      componentGraph[[mu, i, j]], component, mu, i, j,
      frame, rank, lowerSector],
    {mu, 2}, {i, rows}, {j, columns}];
  failure = SelectFirst[Flatten[cells],
    Lookup[#1, "Status", None] =!= "ChannelizedCell" &,
    Missing["NoFailure"]];
  If[! MissingQ[failure], Return[failure]];
  <|"Status" -> "ChannelizedComponent",
    "ProcessedTerms" -> Map[Lookup[#1, "Leaves"] &, cells, {3}],
    "Channels" -> Map[Lookup[#1, "Channels"] &, cells, {3}]|>
];

channelizeTermGraph[termGraph_List, frame_Association,
    lowerSector_Integer] := Module[
  {rank, components, failure, processed, channels, leaves,
   rootIndices, componentSupports, activeGrades, activeRank,
   channelCanonical, termFingerprint, channelFingerprint,
   supportFingerprint},
  rank = Length[CodexTripleRootStrip`TRCurrentRoots[frame, variables]];
  components = Table[channelizeComponent[
      termGraph[[component]], component, frame, rank, lowerSector],
    {component, 3}];
  failure = SelectFirst[components,
    Lookup[#1, "Status", None] =!= "ChannelizedComponent" &,
    Missing["NoFailure"]];
  If[! MissingQ[failure], Return[failure]];
  processed = Lookup[components, "ProcessedTerms"];
  channels = Lookup[components, "Channels"];
  leaves = Cases[processed,
    leaf_Association /;
      Lookup[leaf, "Status", None] === "LeafChannelized", Infinity];
  rootIndices = If[leaves === {}, {},
    Union @@ Lookup[leaves, "RootIndices", {}]];
  componentSupports = gradeSupport /@ channels;
  activeGrades = Union @@ componentSupports;
  activeRank = CodexTripleRoot`TRActiveRank[activeGrades, rank];
  channelCanonical = Map[canonicalRational, channels, {5}];
  termFingerprint = fingerprint[
    Lookup[leaves, "LeafFingerprint", {}]];
  channelFingerprint = fingerprint[channelCanonical];
  supportFingerprint = fingerprint[<|
    "ComponentGradeSupport" -> componentSupports,
    "ActiveGrades" -> activeGrades, "ActiveGradeRank" -> activeRank|>];
  <|"Status" -> "ExactTermwiseChannelDecomposition",
    "ChannelSidecarVersion" -> 1,
    "ChannelRootSourceOrder" -> Range[rank],
    "ChannelRootSquares" -> Lookup[
      CodexTripleRootStrip`TRCurrentRoots[frame, variables],
      "RootSquare", {}],
    "RootIndices" -> rootIndices, "RootCount" -> Length[rootIndices],
    "RootSquares" -> Lookup[
      CodexTripleRootStrip`TRCurrentRoots[frame, variables][[rootIndices]],
      "RootSquare", {}],
    "ProcessedTermGraph" -> processed, "ChannelStrip" -> channels,
    "LeafCount" -> Length[leaves], "LeafRoundTripExact" ->
      AllTrue[leaves, TrueQ[Lookup[#1, "RoundTripExact", False]] &],
    "ChannelCount" -> 2^rank,
    "ComponentGradeSupport" -> componentSupports,
    "ActiveGrades" -> activeGrades, "ActiveGradeRank" -> activeRank,
    "TermGraphFingerprint" -> termFingerprint,
    "ChannelEquationFingerprint" -> channelFingerprint,
    "SupportFingerprint" -> supportFingerprint|>
];

composeChannelStrip[channelStrip_List, roots_List] :=
  Map[CodexTripleRootStrip`TRFieldCompose[#1, roots] &,
    channelStrip, {4}];

solved12 = <||>;
stripRecords = {};
rank3Record = Missing["NotFound"];
rank3Decomposition = Missing["NotRun"];
sidecarBlocker = None;

Do[Module[{strip, record, inputFile, classificationSeconds,
    classification, decompositionSeconds = 0., decomposition = None,
    componentSupports = {}, activeGrades = {}, activeRank = 0,
    zeroForcing, solveSeconds = 0., solution = None, gauge,
    termGraph, globalRoots, channelSidecar},
  termGraph = blockTermGraph[lowerSector, solved12];
  globalRoots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
  {decompositionSeconds, decomposition} = AbsoluteTiming[
    channelizeTermGraph[termGraph, frame, lowerSector]];
  If[Lookup[decomposition, "Status", None] =!=
      "ExactTermwiseChannelDecomposition",
    sidecarBlocker = <|"Status" -> "TermwiseDecompositionBlocked",
      "LowerSector" -> lowerSector, "Seconds" -> decompositionSeconds,
      "Decomposition" -> decomposition|>; Break[]];
  strip = composeChannelStrip[decomposition["ChannelStrip"],
    globalRoots];
  channelSidecar = KeyTake[decomposition,
    {"Status", "ChannelSidecarVersion", "ChannelRootSourceOrder",
      "ChannelRootSquares", "RootIndices", "RootCount", "RootSquares",
      "ProcessedTermGraph", "ChannelStrip", "LeafCount",
      "LeafRoundTripExact", "ChannelCount", "ComponentGradeSupport",
      "ActiveGrades", "ActiveGradeRank", "TermGraphFingerprint",
      "ChannelEquationFingerprint", "SupportFingerprint"}];
  record = <|"Family" -> "CF300", "Sector" -> 12,
    "LowerSector" -> lowerSector, "Variables" -> variables,
    "Regulator" -> epsilon, "Strip" -> strip,
    "PrecomputedChannelSidecar" -> channelSidecar|>;
  inputFile = FileNameJoin[{outputDirectory,
    "CF300_12_" <> ToString[lowerSector] <> "_input.wl"}];
  writeAtomic[record, inputFile];
  classificationSeconds = 0.;
  classification = <|"Status" -> "ExactTermwiseRootClassification",
    "RootIndices" -> decomposition["RootIndices"],
    "RootCount" -> decomposition["RootCount"],
    "RootSquares" -> decomposition["RootSquares"]|>;
  zeroForcing = zeroQ[decomposition["ChannelStrip"][[3]]];
  componentSupports = decomposition["ComponentGradeSupport"];
  activeGrades = decomposition["ActiveGrades"];
  activeRank = decomposition["ActiveGradeRank"];
  AppendTo[stripRecords, <|"LowerSector" -> lowerSector,
    "InputFile" -> inputFile,
    "InputSHA256" -> FileHash[inputFile, "SHA256", "HexString"],
    "Dimensions" -> Dimensions[strip[[3, 1]]],
    "MaterializedLeafCount" -> LeafCount[strip],
    "ForcingZero" -> zeroForcing,
    "ClassificationSeconds" -> classificationSeconds,
    "Classification" -> classification,
    "DecompositionSeconds" -> decompositionSeconds,
    "LeafCount" -> decomposition["LeafCount"],
    "LeafRoundTripExact" -> decomposition["LeafRoundTripExact"],
    "TermGraphFingerprint" -> decomposition["TermGraphFingerprint"],
    "ChannelEquationFingerprint" ->
      decomposition["ChannelEquationFingerprint"],
    "SupportFingerprint" -> decomposition["SupportFingerprint"],
    "ComponentGradeSupport" -> componentSupports,
    "ActiveGrades" -> activeGrades,
    "ActiveGradeRank" -> activeRank|>];
  Print["CF300S12SIDECAR strip=", {12, lowerSector},
    " zero=", zeroForcing,
    " roots=", Lookup[classification, "RootIndices", {}],
    " active_rank=", activeRank,
    " dimensions=", Dimensions[strip[[3, 1]]]];
  If[! zeroForcing &&
      Lookup[classification, "Status", None] ===
        "ExactTermwiseRootClassification" &&
      Lookup[classification, "RootCount", 0] === 3 &&
      Lookup[decomposition, "Status", None] ===
        "ExactTermwiseChannelDecomposition" && activeRank === 3,
    rank3Record = record; rank3Decomposition = decomposition;
    Break[]];
  If[zeroForcing,
    solved12[lowerSector] = ConstantArray[0,
      Dimensions[strip[[3, 1]]]],
    If[Lookup[classification, "Status", None] =!=
        "ExactTermwiseRootClassification" ||
       Lookup[classification, "RootCount", 4] > 2,
      sidecarBlocker = <|"Status" -> "PreRank3ClassificationBlocked",
        "LowerSector" -> lowerSector,
        "Classification" -> classification|>; Break[]];
    {solveSeconds, solution} = AbsoluteTiming[
      FeynFacet`SolveEpsFormStripInFrame[
        strip, variables, epsilon, frame,
        "FiniteFieldFirst" -> True,
        "FiniteFieldOptions" -> {"KernelCount" -> 1,
          "FinalCheck" -> "Exact", "Verbose" -> True},
        "ScratchDirectory" -> outputDirectory,
        "Tag" -> "CF300_12_" <> ToString[lowerSector],
        "Verbose" -> True]];
    If[! AssociationQ[solution] ||
        Lookup[solution, "Status", None] =!= "Solved" ||
        ! TrueQ[Lookup[solution, "ExactDLog", False]],
      sidecarBlocker = <|"Status" -> "PreRank3StripSolveBlocked",
        "LowerSector" -> lowerSector, "Seconds" -> solveSeconds,
        "Solution" -> solution|>; Break[]];
    gauge = Lookup[solution, "Gauge", $Failed];
    If[Dimensions[gauge] =!= Dimensions[strip[[3, 1]]],
      sidecarBlocker = <|"Status" -> "PreRank3GaugeShapeMismatch",
        "LowerSector" -> lowerSector|>; Break[]];
    solved12[lowerSector] = gauge;
    stripRecords[[-1]] = Join[stripRecords[[-1]], <|
      "SolveSeconds" -> solveSeconds,
      "SolveSummary" -> KeyTake[solution,
        {"Status", "Method", "ExactDLog", "RootIndices",
          "Alphabet", "FrameCertificate"}]|>]]
], {lowerSector, Reverse[Range[11]]}];

If[AssociationQ[sidecarBlocker],
  finish["Sector12SidecarBlockedBeforeRank3", <|
    "SourceHashes" -> <|"State" -> stateHash,
      "Checkpoint" -> checkpointHash|>,
    "SourceIdentity" -> <|"PinnedQ" -> sourceIdentityPinnedQ,
      "StableAfterReplayQ" -> sourceIdentityStableAfterReplayQ,
      "StateSnapshot" -> stateSnapshotFile,
      "CheckpointSnapshot" -> checkpointSnapshotFile|>,
    "ChartProvenance" -> <|"Family" -> "CF300",
      "FrameName" -> frame["Name"],
      "ChartFingerprint" -> frameFingerprint,
      "CertificateOK" -> True|>,
    "ResumeReplaySeconds" -> resumeReplaySeconds,
    "ResumeReplayRecords" -> replayRecords11,
    "CheckpointProvenance" -> <|
      "GaugeShapeQ" -> checkpointGaugeShapeQ,
      "StripSolverShapeQ" -> checkpointSolverShapeQ,
      "OrderedSolverProvenanceQ" -> orderedSolverProvenanceQ|>,
    "RegulatorFactor" -> regulatorFactor,
    "SquareClassCertificate" -> squareClasses,
    "DeferredSeconds" -> deferredSeconds,
    "DeferredStatistics" -> deferred["Statistics"],
    "PrefixFactoredQ" -> prefixFactoredQ,
    "PrefixConjugationQ" -> prefixConjugationQ,
    "RawBottomLeftTermCount" ->
      Count[rawBottomLeftTerms, _Association, Infinity],
    "StripRecords" -> stripRecords,
    "Blocker" -> sidecarBlocker|>, 77]];

If[! AssociationQ[rank3Record],
  finish["NoGenuineRank3Sector12Strip", <|
    "SourceHashes" -> <|"State" -> stateHash,
      "Checkpoint" -> checkpointHash|>,
    "SourceIdentity" -> <|"PinnedQ" -> sourceIdentityPinnedQ,
      "StableAfterReplayQ" -> sourceIdentityStableAfterReplayQ,
      "StateSnapshot" -> stateSnapshotFile,
      "CheckpointSnapshot" -> checkpointSnapshotFile|>,
    "ChartProvenance" -> <|"Family" -> "CF300",
      "FrameName" -> frame["Name"],
      "ChartFingerprint" -> frameFingerprint,
      "CertificateOK" -> True|>,
    "ResumeReplaySeconds" -> resumeReplaySeconds,
    "ResumeReplayRecords" -> replayRecords11,
    "CheckpointProvenance" -> <|
      "GaugeShapeQ" -> checkpointGaugeShapeQ,
      "StripSolverShapeQ" -> checkpointSolverShapeQ,
      "OrderedSolverProvenanceQ" -> orderedSolverProvenanceQ|>,
    "RegulatorFactor" -> regulatorFactor,
    "SquareClassCertificate" -> squareClasses,
    "DeferredSeconds" -> deferredSeconds,
    "DeferredStatistics" -> deferred["Statistics"],
    "PrefixFactoredQ" -> prefixFactoredQ,
    "PrefixConjugationQ" -> prefixConjugationQ,
    "RawBottomLeftTermCount" ->
      Count[rawBottomLeftTerms, _Association, Infinity],
    "StripRecords" -> stripRecords|>, 3]];

If[! sourceIdentityCurrentQ[],
  finish["SourceIdentityAdvancedAfterDerivation", <|
    "PinnedStateSHA256" -> stateHash,
    "PinnedCheckpointSHA256" -> checkpointHash,
    "ResumeReplaySeconds" -> resumeReplaySeconds,
    "StripRecords" -> stripRecords|>, 96]];

rank3InputFile = FileNameJoin[{outputDirectory,
  "CF300_12_" <> ToString[rank3Record["LowerSector"]] <>
    "_physical_rank3_input.wl"}];
writeAtomic[rank3Record, rank3InputFile];
result = <|"Status" -> "FoundPhysicalRank3Sector12Strip",
  "TotalSeconds" -> N[AbsoluteTime[] - missionStarted],
  "SourceHashes" -> <|"State" -> stateHash,
    "Checkpoint" -> checkpointHash|>,
  "SourceIdentity" -> <|"PinnedQ" -> sourceIdentityPinnedQ,
    "StableAfterReplayQ" -> sourceIdentityStableAfterReplayQ,
    "StableAtCompletionQ" -> True,
    "StateSnapshot" -> stateSnapshotFile,
    "CheckpointSnapshot" -> checkpointSnapshotFile|>,
  "ChartProvenance" -> <|"Family" -> "CF300",
    "FrameName" -> frame["Name"],
    "ChartFingerprint" -> frameFingerprint,
    "CertificateOK" -> True|>,
  "ResumeReplaySeconds" -> resumeReplaySeconds,
  "ResumeReplayStatus" -> resumeReplay11["Status"],
  "ResumeReplayRecords" -> replayRecords11,
  "CheckpointProvenance" -> <|
    "GaugeShapeQ" -> checkpointGaugeShapeQ,
    "StripSolverShapeQ" -> checkpointSolverShapeQ,
    "OrderedSolverProvenanceQ" -> orderedSolverProvenanceQ|>,
  "CheckpointConnectionHash" -> checkpointConnectionHash,
  "RegulatorFactor" -> regulatorFactor,
  "RegulatorFactorMethod" -> "CommonSector11ResidueScalar",
  "SquareClassCertificate" -> squareClasses,
  "DeferredSeconds" -> deferredSeconds,
  "DeferredStatistics" -> deferred["Statistics"],
  "PrefixFactoredQ" -> prefixFactoredQ,
  "PrefixConjugationQ" -> prefixConjugationQ,
  "RawBottomLeftTermCount" ->
    Count[rawBottomLeftTerms, _Association, Infinity],
  "StripRecords" -> stripRecords,
  "SelectedInputFile" -> rank3InputFile,
  "SelectedInputSHA256" ->
    FileHash[rank3InputFile, "SHA256", "HexString"],
  "SelectedDecomposition" -> KeyTake[rank3Decomposition,
    {"Status", "ChannelSidecarVersion", "ChannelRootSourceOrder",
      "RootIndices", "RootCount", "RootSquares",
      "ChannelCount", "LeafCount", "LeafRoundTripExact",
      "ComponentGradeSupport", "ActiveGrades", "ActiveGradeRank",
      "TermGraphFingerprint", "ChannelEquationFingerprint",
      "SupportFingerprint"}]|>;
writeAtomic[result, resultFile];
Print["CF300S12SIDECAR RESULT status=", result["Status"],
  " selected=", {12, rank3Record["LowerSector"]},
  " input=", rank3InputFile, " output=", resultFile];
result
