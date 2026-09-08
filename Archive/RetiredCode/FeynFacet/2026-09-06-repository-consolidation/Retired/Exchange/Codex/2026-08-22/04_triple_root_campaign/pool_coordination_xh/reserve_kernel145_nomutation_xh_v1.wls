#!/usr/bin/env wolframscript

BeginPackage["CodexReserveKernel145NoMutationXH`"];
Begin["`Private`"];
Quiet[ClearAll["CodexReserveKernel145NoMutationXH`Private`*"]];

reservationExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexReserveKernel145NoMutationXH`*"]];
   System`Exit[code]);

parseUnsignedInteger[text_String] := If[
  StringLength[text] > 0 && StringMatchQ[text, DigitCharacter ..],
  FromDigits[text], $Failed];

observedState[] := <|
  "GlobalNames" -> Names["Global`*"],
  "Packages" -> $Packages,
  "Context" -> $Context,
  "ContextPath" -> $ContextPath,
  "Path" -> $Path,
  "Assumptions" -> $Assumptions,
  "MaxExtraPrecision" -> $MaxExtraPrecision,
  "RecursionLimit" -> $RecursionLimit,
  "HistoryLength" -> $HistoryLength|>;

If[$KernelID =!= 145,
  Print["KERNEL145_RESERVATION FAIL wrong dispatch expected=145 observed=",
    $KernelID];
  reservationExit[97]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["KERNEL145_RESERVATION FAIL usage=<release-sentinel> " <>
    "<max-seconds> <reservation-token>"];
  reservationExit[64]];

releaseSentinel = ExpandFileName[arguments[[1]]];
maxSeconds = parseUnsignedInteger[arguments[[2]]];
reservationToken = arguments[[3]];
helperCeiling = If[NameQ["KernelPoolMission`$TaskBrokerMaxHelpers"],
  ToExpression["KernelPoolMission`$TaskBrokerMaxHelpers"], Missing["Absent"]];
driverFile = ExpandFileName[$InputFileName];

If[! DirectoryQ[DirectoryName[releaseSentinel]] ||
    FileExistsQ[releaseSentinel] ||
    ! IntegerQ[maxSeconds] || ! (60 <= maxSeconds <= 7200) ||
    ! StringQ[reservationToken] ||
    ! StringMatchQ[reservationToken,
      RegularExpression["[A-Za-z0-9_.:-]{16,128}"]] ||
    helperCeiling =!= 0,
  Print["KERNEL145_RESERVATION FAIL invalid arguments or helper ceiling"];
  reservationExit[65]];

driverHash = FileHash[driverFile, "SHA256", "HexString"];
initialState = observedState[];
initialStateHash = Hash[ToString[InputForm[initialState]],
  "SHA256", "HexString"];
startTime = AbsoluteTime[];
deadline = startTime + maxSeconds;
releaseReason = "DeadlineReached";
finalCode = 0;
heartbeatCount = 0;

Print["KERNEL145_RESERVATION status=reserved kernel=", $KernelID,
  " token=", reservationToken,
  " max_s=", maxSeconds,
  " helper_ceiling=", helperCeiling,
  " state_sha=", initialStateHash,
  " source_sha=", driverHash];

While[AbsoluteTime[] < deadline,
  If[FileExistsQ[releaseSentinel],
    releaseReason = "SentinelObserved";
    Break[]];
  If[FileHash[driverFile, "SHA256", "HexString"] =!= driverHash,
    releaseReason = "SourceChanged";
    finalCode = 68;
    Break[]];
  currentState = observedState[];
  If[currentState =!= initialState,
    releaseReason = "ObservedStateDrift";
    finalCode = 69;
    Break[]];
  Pause[5];
  heartbeatCount++;
  If[Mod[heartbeatCount, 12] === 0,
    Print["KERNEL145_RESERVATION heartbeat=", heartbeatCount/12,
      " kernel=", $KernelID,
      " remaining_s=", Max[0, Floor[deadline - AbsoluteTime[]]],
      " token=", reservationToken]]];

finalState = observedState[];
If[finalState =!= initialState && finalCode === 0,
  releaseReason = "FinalObservedStateDrift";
  finalCode = 69];
Print["KERNEL145_RESERVATION status=released reason=", releaseReason,
  " code=", finalCode,
  " kernel=", $KernelID,
  " elapsed_s=", N[AbsoluteTime[] - startTime],
  " token=", reservationToken,
  " state_stable=", SameQ[finalState, initialState],
  " source_stable=",
    FileHash[driverFile, "SHA256", "HexString"] === driverHash];
reservationExit[finalCode];

