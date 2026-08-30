#!/usr/bin/env wolframscript
(* Focused TaskBroker coverage for the independent candidate-letter dlog
   batch.  The injected broker executes task code in-process so this suite is
   bounded and does not require or interfere with a live KernelPool. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

batch = mq["multiquadraticStripConstructDLogBatch"];
shard = mq["multiquadraticStripDLogShardTask"];
candidate = mq["multiquadraticStripCandidateLetters"];
dlogData = mq["multiquadraticStripLetterDLogDataInField"];
pairKey = mq["multiquadraticStripPotentialPairKey"];
letters = {x, y, 1 - x - y, x + y, x^2 + y, 1 + x y, x - 2 y};
serial = batch[letters, {}, {x, y}, 1];
check["constructed dlogs retain their canonical pair key and zero verdict",
  And @@ MapThread[
    StringQ[Lookup[#2, "PotentialPairKey", None]] &&
      Lookup[#2, "PotentialPairKey", None] ===
        pairKey[#1, #2["OneForm"], {x, y}, \[FormalE]] &&
      Lookup[#2, "ChannelZeroQ", None] === False &,
    {letters, serial["Data"]}]];

runBroker[malformed_, deadlineSeconds_: 100] := Module[
  {file = FileNameJoin[{$TemporaryDirectory,
       "facet_mq_dlog_broker_test_" <> StringReplace[CreateUUID[], "-" ->
          ""] <> ".wl"}], capturedPayload = None, capturedTimeout = None,
   submittedCodes = {}, result, deadline = AbsoluteTime[] + deadlineSeconds,
   payloadExistsAfter},
  result = Internal`InheritedBlock[
    {FeynFacet`Private`taskBrokerActiveQ,
     FeynFacet`Private`taskBrokerFreeKernels,
     FeynFacet`Private`taskBrokerDataFile,
     FeynFacet`Private`taskBrokerRead,
     FeynFacet`Private`taskBrokerSubmit,
     FeynFacet`Private`taskBrokerCollect,
     FeynFacet`Private`taskBrokerCancel},
    Unprotect[FeynFacet`Private`taskBrokerActiveQ,
      FeynFacet`Private`taskBrokerFreeKernels,
      FeynFacet`Private`taskBrokerDataFile,
      FeynFacet`Private`taskBrokerRead,
      FeynFacet`Private`taskBrokerSubmit,
      FeynFacet`Private`taskBrokerCollect,
      FeynFacet`Private`taskBrokerCancel];
    Clear[FeynFacet`Private`taskBrokerActiveQ,
      FeynFacet`Private`taskBrokerFreeKernels,
      FeynFacet`Private`taskBrokerDataFile,
      FeynFacet`Private`taskBrokerRead,
      FeynFacet`Private`taskBrokerSubmit,
      FeynFacet`Private`taskBrokerCollect,
      FeynFacet`Private`taskBrokerCancel];
    FeynFacet`Private`taskBrokerActiveQ[] := True;
    (* The caller requests eight workers, but its current fair allocation
       grants exactly two helpers. *)
    FeynFacet`Private`taskBrokerFreeKernels[] := 2;
    FeynFacet`Private`taskBrokerDataFile[_, payload_] :=
      (capturedPayload = payload; Put[payload, file]; file);
    FeynFacet`Private`taskBrokerRead[path_String] := Get[path];
    FeynFacet`Private`taskBrokerSubmit[codes_List, opts___] :=
      (capturedTimeout = Lookup[Association[{opts}], "Timeout", None];
       submittedCodes = codes;
       <|"Codes" -> codes|>);
    FeynFacet`Private`taskBrokerCollect[handle_Association] := Module[
      {values = shard[capturedPayload, #1] & /@ {{1, 4, 7}, {2, 5}}},
      If[malformed === "Expired", Pause[0.25]];
      If[MemberQ[{True, "Expired"}, malformed] && values =!= {},
        ReplacePart[values, 1 -> <|"Indices" -> {-1}, "Data" -> {}|>],
        values]];
    FeynFacet`Private`taskBrokerCancel[___] := Null;
    Block[{$KernelID = 37},
      batch[letters, {}, {x, y}, 8, deadline]]];
  payloadExistsAfter = FileExistsQ[file];
  If[FileExistsQ[file], Quiet[DeleteFile[file]]];
  <|"Result" -> result, "Payload" -> capturedPayload,
    "Timeout" -> capturedTimeout, "SubmittedCodes" -> submittedCodes,
    "PayloadExistsAfter" -> payloadExistsAfter|>
];

broker = runBroker[False];
check["a non-main mission kernel uses the TaskBroker with its fair helper cap",
  broker["Result", "Route"] === "TaskBrokerShards" &&
    broker["Result", "BrokerHelperCount"] === 2 &&
    broker["Result", "Subkernels"] === 2];
check["broker sharding preserves deterministic input order and exact data",
  SameQ[broker["Result", "Data"], serial["Data"]]];
check["the immutable broker payload uses only formal chart variables",
  AssociationQ[broker["Payload"]] &&
    FreeQ[broker["Payload"], Alternatives[x, y]] &&
    ! FreeQ[broker["Payload"], Alternatives[\[FormalX], \[FormalY]]]];
check["the broker timeout respects the active cooperative deadline",
  IntegerQ[broker["Timeout"]] && Between[broker["Timeout"], {1, 100}]];
check["one task is submitted for each broker helper shard",
  Length[broker["SubmittedCodes"]] === 2];

candidateDeadline = AbsoluteTime[] + 60;
capturedCandidateDeadline = None;
zero11 = {{{0}}, {{0}}};
candidateResult = Internal`InheritedBlock[
  {FeynFacet`Private`multiquadraticStripConstructDLogBatch},
  Unprotect[FeynFacet`Private`multiquadraticStripConstructDLogBatch];
  Clear[FeynFacet`Private`multiquadraticStripConstructDLogBatch];
  FeynFacet`Private`multiquadraticStripConstructDLogBatch[
      batchLetters_List, batchRoots_List, batchVariables_List,
      kernelCount_Integer, deadline_] :=
    (capturedCandidateDeadline = deadline;
     <|"Data" -> (dlogData[#1, batchRoots, batchVariables] & /@ batchLetters),
       "Route" -> "DeadlineCapture", "Subkernels" -> 0,
       "BrokerHelperCount" -> 0, "Seconds" -> 0.|>);
  candidate[{zero11, zero11, zero11}, {}, {cx, cy}, ce,
    <|"StripSolvers" -> {}|>, "RegulatorSampleCount" -> 1,
    "RowAlphabet" -> {}, "AdditionalLetters" -> {},
    "AlgebraicLetters" -> {}, "DLogKernels" -> 1,
    "Deadline" -> candidateDeadline]];
check["the production candidate-letter option passes its absolute deadline",
  Lookup[candidateResult, "Status", None] ===
      "MultiquadraticCandidateLettersV1" &&
    SameQ[capturedCandidateDeadline, candidateDeadline]];

malformed = runBroker[True];
check["a malformed helper shard is recomputed locally without changing data",
  malformed["Result", "Route"] === "TaskBrokerShards" &&
    SameQ[malformed["Result", "Data"], serial["Data"]]];
expired = runBroker["Expired", 0.15];
check["deadline expiry refuses malformed helper replay with a typed result",
  Lookup[expired["Result"], "Status", None] === "BudgetExhausted" &&
    Lookup[expired["Result"], "Stage", None] === "CandidateDLogs" &&
    Lookup[expired["Result"], "MissingShardIndices", {}] === {1, 4, 7}];
check["the typed deadline exit removes its immutable broker payload",
  expired["PayloadExistsAfter"] === False];
check["the shard entry point rejects invalid index payloads",
  shard[<|"Entries" -> {\[FormalX]}, "Roots" -> {}|>, {0}] === $Failed &&
    shard[<|"Entries" -> {\[FormalX]}|>, {1}] === $Failed];

Print["t_multiquadratic_dlog_broker: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
