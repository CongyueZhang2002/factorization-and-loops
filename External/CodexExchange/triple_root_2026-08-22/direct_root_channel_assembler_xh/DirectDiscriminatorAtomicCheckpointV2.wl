BeginPackage["CodexDirectDiscriminatorAtomicCheckpointV2`"];

DDACRejectedReasonHistogram::usage =
  "DDACRejectedReasonHistogram[rejected] returns a fail-closed histogram and handles the empty list without emitting Counts::invrp.";
DDACWriteAtomic::usage =
  "DDACWriteAtomic[target, payload, commitCheck] writes a sealed association with typed stage diagnostics and never deletes failed evidence.";
DDACReadSealed::usage =
  "DDACReadSealed[file] validates and returns a sealed checkpoint or final artifact.";
DDACRankSummary::usage =
  "DDACRankSummary[variantResults, imageID] extracts the compact two-rank result for every variant.";
DDACPrintRankSummary::usage =
  "DDACPrintRankSummary[prefix, imageID, summary] prints one compact, machine-readable line per variant.";

Begin["`Private`"];

$ddacStatus = "CF300DirectDiscriminatorAtomicCommitV2";
$ddacIntegrityKey = "AtomicCommitV2";

ddacFingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];

SetAttributes[ddacMessages, HoldFirst];
ddacMessages[expression_] := Module[{result, messages},
  Block[{$MessageList = {}},
    result = Quiet[Check[expression, $Failed]];
    messages = ToString[InputForm[$MessageList]]];
  <|"Result" -> result, "Messages" -> messages|>
];

ddacFailure[stage_String, target_String, temporary_, start_, data_: <||>] :=
  Join[<|"Status" -> "AtomicWriteFailedV2", "Stage" -> stage,
    "Target" -> target, "TemporaryFile" -> temporary,
    "EvidencePreserved" -> True,
    "ElapsedSeconds" -> N[AbsoluteTime[] - start]|>, data];

ddacCommitCheck[Automatic] := <|"Passed" -> True,
  "Messages" -> "{}"|>;
ddacCommitCheck[check_] := Module[{capture},
  capture = ddacMessages[check[]];
  <|"Passed" -> TrueQ[capture["Result"]],
    "Messages" -> capture["Messages"]|>
];

ddacSealedPayload[payload_Association, target_String] := Module[
  {plain, fingerprint},
  plain = KeyDrop[payload, {$ddacIntegrityKey}];
  fingerprint = ddacFingerprint[plain];
  Append[plain, $ddacIntegrityKey -> <|
    "Status" -> $ddacStatus,
    "PayloadFingerprint" -> fingerprint,
    "TargetFileName" -> FileNameTake[target]|>]
];

ddacValidSealedQ[value_, target_String] := Module[
  {integrity, plain},
  If[! AssociationQ[value] || ! KeyExistsQ[value, $ddacIntegrityKey],
    Return[False]];
  integrity = value[$ddacIntegrityKey];
  plain = KeyDrop[value, {$ddacIntegrityKey}];
  AssociationQ[integrity] &&
    Lookup[integrity, "Status", None] === $ddacStatus &&
    StringQ[Lookup[integrity, "PayloadFingerprint", None]] &&
    Lookup[integrity, "PayloadFingerprint", None] ===
      ddacFingerprint[plain] &&
    Lookup[integrity, "TargetFileName", None] === FileNameTake[target]
];

DDACRejectedReasonHistogram[rejected_List] := Module[{reasons},
  If[rejected === {}, Return[<||>]];
  If[! AllTrue[rejected, AssociationQ], Return[$Failed]];
  reasons = Lookup[rejected, "FailureReason", Missing["FailureReason"]];
  If[MemberQ[reasons, _Missing], Return[$Failed]];
  Counts[reasons]
];
DDACRejectedReasonHistogram[___] := $Failed;

DDACWriteAtomic[target_String, payload_Association,
    commitCheck_: Automatic] := Module[
  {start = AbsoluteTime[], temporary, sealed, putCapture, temporaryBytes,
   sealCapture, temporaryHash, temporaryRead, preCommit, renameCapture,
   targetHash, targetRead, postCommit},
  If[! DirectoryQ[DirectoryName[target]],
    Return[ddacFailure["TargetDirectoryMissing", target, None, start]]];
  If[KeyExistsQ[payload, $ddacIntegrityKey],
    Return[ddacFailure["ReservedIntegrityKeyPresent", target, None,
      start]]];
  If[FileExistsQ[target],
    Return[ddacFailure["TargetAlreadyExists", target, None, start,
      <|"TargetByteCount" -> Quiet[Check[FileByteCount[target], $Failed]],
        "TargetSHA256" -> Quiet[Check[
          FileHash[target, "SHA256", "HexString"], $Failed]]|>]]];
  temporary = target <> ".tmp." <> StringReplace[CreateUUID[], "-" -> ""];
  sealCapture = ddacMessages[ddacSealedPayload[payload, target]];
  sealed = sealCapture["Result"];
  If[! AssociationQ[sealed],
    Return[ddacFailure["PayloadSealFailed", target, temporary, start,
      <|"Messages" -> sealCapture["Messages"]|>]]];
  putCapture = ddacMessages[Put[sealed, temporary]];
  If[putCapture["Result"] === $Failed || ! FileExistsQ[temporary],
    Return[ddacFailure["TemporaryPutFailed", target, temporary, start,
      <|"Messages" -> putCapture["Messages"]|>]]];
  temporaryBytes = Quiet[Check[FileByteCount[temporary], $Failed]];
  temporaryHash = Quiet[Check[
    FileHash[temporary, "SHA256", "HexString"], $Failed]];
  If[! IntegerQ[temporaryBytes] || temporaryBytes <= 0 ||
      ! StringQ[temporaryHash],
    Return[ddacFailure["TemporaryStatOrHashFailed", target, temporary,
      start, <|"TemporaryByteCount" -> temporaryBytes,
        "TemporarySHA256" -> temporaryHash|>]]];
  temporaryRead = ddacMessages[Get[temporary]];
  If[temporaryRead["Result"] === $Failed ||
      ! ddacValidSealedQ[temporaryRead["Result"], target],
    Return[ddacFailure["TemporaryReadbackInvalid", target, temporary,
      start, <|"Messages" -> temporaryRead["Messages"],
        "TemporaryByteCount" -> temporaryBytes,
        "TemporarySHA256" -> temporaryHash|>]]];
  preCommit = ddacCommitCheck[commitCheck];
  If[! TrueQ[preCommit["Passed"]],
    Return[ddacFailure["PreCommitCheckFailed", target, temporary, start,
      <|"Messages" -> preCommit["Messages"],
        "TemporaryByteCount" -> temporaryBytes,
        "TemporarySHA256" -> temporaryHash|>]]];
  renameCapture = ddacMessages[RenameFile[temporary, target,
    OverwriteTarget -> False]];
  If[renameCapture["Result"] === $Failed || ! FileExistsQ[target] ||
      FileExistsQ[temporary],
    Return[ddacFailure["AtomicRenameFailed", target, temporary, start,
      <|"Messages" -> renameCapture["Messages"],
        "TemporaryExists" -> FileExistsQ[temporary],
        "TargetExists" -> FileExistsQ[target],
        "TemporaryByteCount" -> temporaryBytes,
        "TemporarySHA256" -> temporaryHash|>]]];
  targetHash = Quiet[Check[
    FileHash[target, "SHA256", "HexString"], $Failed]];
  If[targetHash =!= temporaryHash,
    Return[ddacFailure["CommittedByteHashMismatch", target, temporary,
      start, <|"TemporarySHA256" -> temporaryHash,
        "TargetSHA256" -> targetHash,
        "TargetPreserved" -> True|>]]];
  targetRead = ddacMessages[Get[target]];
  If[targetRead["Result"] === $Failed ||
      ! ddacValidSealedQ[targetRead["Result"], target],
    Return[ddacFailure["CommittedReadbackInvalid", target, temporary,
      start, <|"Messages" -> targetRead["Messages"],
        "TargetSHA256" -> targetHash, "TargetPreserved" -> True|>]]];
  postCommit = ddacCommitCheck[commitCheck];
  If[! TrueQ[postCommit["Passed"]],
    Return[ddacFailure["PostCommitCheckFailed", target, temporary,
      start, <|"Messages" -> postCommit["Messages"],
        "TargetSHA256" -> targetHash, "TargetPreserved" -> True|>]]];
  <|"Status" -> "AtomicWriteCommittedV2", "Stage" -> "Complete",
    "Target" -> target, "TemporaryFile" -> temporary,
    "TargetByteCount" -> temporaryBytes, "TargetSHA256" -> targetHash,
    "PayloadFingerprint" ->
      targetRead["Result"][$ddacIntegrityKey]["PayloadFingerprint"],
    "ElapsedSeconds" -> N[AbsoluteTime[] - start]|>
];
DDACWriteAtomic[___] := <|"Status" -> "AtomicWriteFailedV2",
  "Stage" -> "InvalidArguments", "EvidencePreserved" -> True|>;

DDACReadSealed[file_String] := Module[{capture, value},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "AtomicArtifactAbsentV2", "File" -> file|>]];
  capture = ddacMessages[Get[file]];
  value = capture["Result"];
  If[value === $Failed,
    Return[<|"Status" -> "AtomicArtifactReadFailedV2", "File" -> file,
      "Messages" -> capture["Messages"]|>]];
  If[! ddacValidSealedQ[value, file],
    Return[<|"Status" -> "AtomicArtifactInvalidV2", "File" -> file,
      "Messages" -> capture["Messages"],
      "FileSHA256" -> Quiet[Check[
        FileHash[file, "SHA256", "HexString"], $Failed]]|>]];
  <|"Status" -> "AtomicArtifactReadV2", "File" -> file,
    "FileSHA256" -> FileHash[file, "SHA256", "HexString"],
    "Payload" -> KeyDrop[value, {$ddacIntegrityKey}],
    "Integrity" -> value[$ddacIntegrityKey]|>
];
DDACReadSealed[___] := <|"Status" -> "AtomicArtifactReadFailedV2",
  "FailureReason" -> "InvalidArguments"|>;

DDACRankSummary[variantResults_Association, imageID_String] := Module[
  {extract},
  extract[entries_] := Module[{entry, full, summary, expectedKeys},
    If[! ListQ[entries] || Length[entries] =!= 1 ||
        ! AssociationQ[First[entries]], Return[$Failed]];
    entry = First[entries];
    full = Lookup[entry, "FullImageResult", $Failed];
    If[Lookup[entry, "ImageID", None] =!= imageID ||
        ! AssociationQ[full], Return[$Failed]];
    expectedKeys = {"Tag", "Consistent", "CoefficientRank",
      "AugmentedRank", "CoefficientNullity"};
    summary = KeyTake[full, expectedKeys];
    If[Sort[Keys[summary]] =!= Sort[expectedKeys] ||
        ! StringQ[summary["Tag"]] ||
        ! MemberQ[{True, False}, summary["Consistent"]] ||
        ! IntegerQ[summary["CoefficientRank"]] ||
        ! IntegerQ[summary["AugmentedRank"]] ||
        ! IntegerQ[summary["CoefficientNullity"]] ||
        Min[summary["CoefficientRank"], summary["AugmentedRank"],
          summary["CoefficientNullity"]] < 0 ||
        ! MemberQ[{summary["CoefficientRank"],
            summary["CoefficientRank"] + 1},
          summary["AugmentedRank"]], Return[$Failed]];
    summary
  ];
  With[{summary = Association@KeyValueMap[
      #1 -> extract[#2] &, variantResults]},
    If[MemberQ[Values[summary], $Failed], $Failed, summary]]
];
DDACRankSummary[___] := $Failed;

DDACPrintRankSummary[prefix_String, imageID_String,
    summary_Association] := Module[{},
  KeyValueMap[(Print[prefix, " rank_summary image=", imageID,
      " variant=", #1,
      " coefficient_rank=", Lookup[#2, "CoefficientRank", None],
      " augmented_rank=", Lookup[#2, "AugmentedRank", None],
      " nullity=", Lookup[#2, "CoefficientNullity", None],
      " consistent=", Lookup[#2, "Consistent", None]]) &,
    summary];
  Null
];
DDACPrintRankSummary[___] := $Failed;

End[];
EndPackage[];
