#!/usr/bin/env wolframscript

BeginPackage["CodexKernelPoolQuarantineNoMutationV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexKernelPoolQuarantineNoMutationV1`Private`*"]];

quarantineExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexKernelPoolQuarantineNoMutationV1`*"]];
   System`Exit[code]);

parseUnsignedInteger[text_String] := If[
  StringLength[text] > 0 && StringMatchQ[text, DigitCharacter ..],
  FromDigits[text], $Failed];

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{3, 4}, Length[arguments]],
  Print["KERNEL_POOL_QUARANTINE FAIL usage=<sentinel-file> " <>
    "<max-seconds> <reservation-token> [heartbeat-seconds]"];
  quarantineExit[64]];

sentinelFile = ExpandFileName[arguments[[1]]];
maxSeconds = parseUnsignedInteger[arguments[[2]]];
reservationToken = arguments[[3]];
heartbeatSeconds = If[Length[arguments] === 4,
  parseUnsignedInteger[arguments[[4]]], 60];
If[! StringQ[sentinelFile] ||
    ! DirectoryQ[DirectoryName[sentinelFile]] ||
    FileExistsQ[sentinelFile] ||
    ! IntegerQ[maxSeconds] || ! (60 <= maxSeconds <= 86400) ||
    ! StringQ[reservationToken] ||
    ! StringMatchQ[reservationToken,
      RegularExpression["[A-Za-z0-9_.:-]{16,128}"]] ||
    ! IntegerQ[heartbeatSeconds] ||
    ! (5 <= heartbeatSeconds <= 300),
  Print["KERNEL_POOL_QUARANTINE FAIL invalid arguments"];
  quarantineExit[65]];

driverFile = ExpandFileName[$InputFileName];
driverHash = FileHash[driverFile, "SHA256", "HexString"];
startTime = AbsoluteTime[];
deadline = startTime + maxSeconds;
releaseReason = "DeadlineReached";
heartbeatCount = 0;
Print["KERNEL_POOL_QUARANTINE status=reserved token=",
  reservationToken, " max_s=", maxSeconds,
  " heartbeat_s=", heartbeatSeconds,
  " driver_sha=", driverHash];

While[AbsoluteTime[] < deadline,
  If[FileExistsQ[sentinelFile],
    releaseReason = "SentinelObserved";
    Break[]];
  If[FileHash[driverFile, "SHA256", "HexString"] =!= driverHash,
    Print["KERNEL_POOL_QUARANTINE FAIL source changed"];
    quarantineExit[66]];
  Pause[Min[heartbeatSeconds, Max[1, Floor[deadline - AbsoluteTime[]]]]];
  heartbeatCount++;
  Print["KERNEL_POOL_QUARANTINE heartbeat=", heartbeatCount,
    " remaining_s=", Max[0, Floor[deadline - AbsoluteTime[]]],
    " token=", reservationToken]];

Print["KERNEL_POOL_QUARANTINE status=released reason=", releaseReason,
  " elapsed_s=", N[AbsoluteTime[] - startTime],
  " token=", reservationToken,
  " source_stable=",
  FileHash[driverFile, "SHA256", "HexString"] === driverHash];
quarantineExit[0];
