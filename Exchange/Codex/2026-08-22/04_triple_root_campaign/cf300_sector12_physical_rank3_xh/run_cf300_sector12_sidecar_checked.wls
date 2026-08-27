#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 5,
  Print["CF300S12CHECKED FAIL usage=<project-root> <state.wl> <checkpoint.wl> <output-directory> <result.wl>"];
  Exit[64]];

targetOverride = Environment["FACET_CF300_SIDECAR_TARGET_OVERRIDE"];
target = If[StringQ[targetOverride] && targetOverride =!= "",
  ExpandFileName[targetOverride],
  FileNameJoin[{DirectoryName[$InputFileName],
    "run_cf300_sector12_sidecar_derivation.wls"}]];
resultFile = ExpandFileName[arguments[[5]]];
sentinelFile = resultFile <> ".mission_success.wl";
failureFile = resultFile <> ".mission_failure.wl";

writeAtomic[value_, file_String] := Module[{temporary},
  If[! DirectoryQ[DirectoryName[file]],
    CreateDirectory[DirectoryName[file],
      CreateIntermediateDirectories -> True]];
  temporary = file <> ".tmp";
  Put[value, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

If[AnyTrue[{resultFile, sentinelFile, failureFile}, FileExistsQ],
  Print["CF300S12CHECKED FAIL stale terminal/result target: ",
    Select[{resultFile, sentinelFile, failureFile}, FileExistsQ]];
  Exit[93]];

targetHashBefore = FileHash[target, "SHA256", "HexString"];
sourceText = Quiet[Check[Import[target, "Text"], $Failed]];
targetHashAfterImport = FileHash[target, "SHA256", "HexString"];
If[! StringQ[sourceText],
  writeAtomic[<|"Status" -> "TargetImportFailed", "Target" -> target|>,
    failureFile];
  Exit[90]];
sourceLines = StringSplit[sourceText, "\n"];
parseText = If[sourceLines =!= {} &&
    StringStartsQ[First[sourceLines], "#!"],
  StringRiffle[Rest[sourceLines], "\n"], sourceText];
parsed = Quiet[Check[
  ToExpression[parseText, InputForm, HoldComplete], $Failed]];
If[targetHashBefore =!= targetHashAfterImport ||
    parsed === $Failed || Head[parsed] =!= HoldComplete,
  writeAtomic[<|"Status" -> "TargetSyntaxFailed", "Target" -> target,
    "TargetSHA256Before" -> targetHashBefore,
    "TargetSHA256AfterImport" -> targetHashAfterImport|>,
    failureFile];
  Print["CF300S12CHECKED FAIL target syntax"];
  Exit[90]];

messageCount = Length[$MessageList];
targetOutcome = Catch[
  Internal`InheritedBlock[{Exit, Quit},
    Unprotect[Exit, Quit];
    Clear[Exit, Quit];
    Exit[code_: 0] := Throw[
      <|"Status" -> "TargetExit", "Code" -> code|>,
      "CF300SidecarLocalExit"];
    Quit[code_: 0] := Throw[
      <|"Status" -> "TargetQuit", "Code" -> code|>,
      "CF300SidecarLocalExit"];
    Protect[Exit, Quit];
    CheckAbort[ReleaseHold[parsed],
      <|"Status" -> "TargetAborted"|>]], _,
  Function[{value, tag}, <|"Status" -> "TargetThrew",
    "ThrowValue" -> HoldForm[value], "ThrowTag" -> HoldForm[tag]|>]];
newMessages = Drop[$MessageList, messageCount];
targetHashAfterRun = FileHash[target, "SHA256", "HexString"];
result = targetOutcome;
cleanQ = targetHashAfterRun === targetHashBefore &&
  AssociationQ[result] && Lookup[result, "Status", None] ===
    "FoundPhysicalRank3Sector12Strip" &&
  TrueQ[Lookup[Lookup[result, "SourceIdentity", <||>],
    "StableAtCompletionQ", False]] &&
  newMessages === {} && FileExistsQ[resultFile] &&
  SameQ[FeynFacet`FamilyArtifactRead[resultFile], result];
If[! cleanQ,
  writeAtomic[<|"Status" -> "PhysicalMissionNotClean",
    "Target" -> target,
    "TargetSHA256Before" -> targetHashBefore,
    "TargetSHA256AfterRun" -> targetHashAfterRun,
    "MessageNames" -> newMessages,
    "ReturnedStatus" -> If[AssociationQ[result],
      Lookup[result, "Status", None], Head[result]],
    "ResultArtifactExists" -> FileExistsQ[resultFile]|>, failureFile];
  Print["CF300S12CHECKED FAIL physical mission not clean"];
  Exit[91]];

sentinel = <|"Status" -> "CleanPhysicalMissionSuccess",
  "Target" -> target,
  "TargetSHA256" -> targetHashBefore,
  "ExecutionMode" -> "ImmutableHeldSource",
  "ResultFile" -> resultFile,
  "ResultSHA256" -> FileHash[resultFile, "SHA256", "HexString"],
  "SourceHashes" -> result["SourceHashes"],
  "SourceIdentity" -> result["SourceIdentity"],
  "MessageCount" -> 0|>;
writeAtomic[sentinel, sentinelFile];
Print["CF300S12CHECKED RESULT status=", sentinel["Status"],
  " sentinel=", sentinelFile];
Exit[0];
