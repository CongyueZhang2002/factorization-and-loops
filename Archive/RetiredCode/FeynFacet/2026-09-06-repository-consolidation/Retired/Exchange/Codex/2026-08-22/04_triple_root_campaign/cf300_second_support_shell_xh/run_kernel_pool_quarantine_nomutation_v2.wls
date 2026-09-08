#!/usr/bin/env wolframscript

BeginPackage["CodexKernelPoolQuarantineNoMutationV2`"];
Begin["`Private`"];
Quiet[ClearAll["CodexKernelPoolQuarantineNoMutationV2`Private`*"]];

quarantineExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexKernelPoolQuarantineNoMutationV2`*"]];
   System`Exit[code]);

parseUnsignedInteger[text_String] := If[
  StringLength[text] > 0 && StringMatchQ[text, DigitCharacter ..],
  FromDigits[text], $Failed];
fingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Hash[ToString[InputForm[value]], "SHA256", "HexString"]];
stateX[] := <|
  "OwnValues" -> OwnValues[Global`x],
  "DownValues" -> DownValues[Global`x],
  "UpValues" -> UpValues[Global`x],
  "SubValues" -> SubValues[Global`x],
  "NValues" -> NValues[Global`x],
  "DefaultValues" -> DefaultValues[Global`x],
  "FormatValues" -> FormatValues[Global`x],
  "Attributes" -> Attributes[Global`x]|>;
stateY[] := <|
  "OwnValues" -> OwnValues[Global`y],
  "DownValues" -> DownValues[Global`y],
  "UpValues" -> UpValues[Global`y],
  "SubValues" -> SubValues[Global`y],
  "NValues" -> NValues[Global`y],
  "DefaultValues" -> DefaultValues[Global`y],
  "FormatValues" -> FormatValues[Global`y],
  "Attributes" -> Attributes[Global`y]|>;
stateEpsilon[] := <|
  "OwnValues" -> OwnValues[Global`eps],
  "DownValues" -> DownValues[Global`eps],
  "UpValues" -> UpValues[Global`eps],
  "SubValues" -> SubValues[Global`eps],
  "NValues" -> NValues[Global`eps],
  "DefaultValues" -> DefaultValues[Global`eps],
  "FormatValues" -> FormatValues[Global`eps],
  "Attributes" -> Attributes[Global`eps]|>;
poisonStates[] := <|"x" -> stateX[], "y" -> stateY[],
  "eps" -> stateEpsilon[]|>;
poisonFingerprints[states_Association] := AssociationMap[
  fingerprint[states[#1]] &, Keys[states]];

requiredKernelID = 144;
expectedPoisonFingerprints = <|
  "x" ->
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
  "y" ->
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
  "eps" ->
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968"|>;

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{4, 5}, Length[arguments]],
  Print["KERNEL_POOL_QUARANTINE FAIL usage=<expected-kernel-id> " <>
    "<sentinel-file> <max-seconds> <reservation-token> " <>
    "[heartbeat-seconds]"];
  quarantineExit[64]];

expectedKernelID = parseUnsignedInteger[arguments[[1]]];
sentinelFile = ExpandFileName[arguments[[2]]];
maxSeconds = parseUnsignedInteger[arguments[[3]]];
reservationToken = arguments[[4]];
heartbeatSeconds = If[Length[arguments] === 5,
  parseUnsignedInteger[arguments[[5]]], 60];
If[expectedKernelID =!= requiredKernelID ||
    ! StringQ[sentinelFile] ||
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
firstStates = poisonStates[];
secondStates = poisonStates[];
firstFingerprints = poisonFingerprints[firstStates];
secondFingerprints = poisonFingerprints[secondStates];
preflight = <|
  "ExpectedKernelID" -> expectedKernelID,
  "ObservedKernelID" -> $KernelID,
  "KernelIDMatchesQ" -> SameQ[$KernelID, expectedKernelID],
  "ExpectedPoisonFingerprints" -> expectedPoisonFingerprints,
  "FirstPoisonFingerprints" -> firstFingerprints,
  "SecondPoisonFingerprints" -> secondFingerprints,
  "PoisonStatesStableAcrossTwoReadsQ" -> SameQ[firstStates, secondStates],
  "PoisonFingerprintsMatchQ" -> TrueQ[
    firstFingerprints === expectedPoisonFingerprints ===
      secondFingerprints],
  "SentinelInitiallyAbsentQ" -> ! FileExistsQ[sentinelFile],
  "SourceStableQ" ->
    FileHash[driverFile, "SHA256", "HexString"] === driverHash|>;
Print["KERNEL_POOL_QUARANTINE preflight=", InputForm[preflight]];
If[! TrueQ[preflight["KernelIDMatchesQ"] &&
    preflight["PoisonStatesStableAcrossTwoReadsQ"] &&
    preflight["PoisonFingerprintsMatchQ"] &&
    preflight["SentinelInitiallyAbsentQ"] &&
    preflight["SourceStableQ"]],
  Print["KERNEL_POOL_QUARANTINE FAIL preflight mismatch"];
  quarantineExit[67]];

startTime = AbsoluteTime[];
deadline = startTime + maxSeconds;
releaseReason = "DeadlineReached";
heartbeatCount = 0;
finalCode = 0;
Print["KERNEL_POOL_QUARANTINE status=reserved kernel=", $KernelID,
  " token=", reservationToken, " max_s=", maxSeconds,
  " heartbeat_s=", heartbeatSeconds, " driver_sha=", driverHash];

While[AbsoluteTime[] < deadline,
  If[FileExistsQ[sentinelFile],
    releaseReason = "SentinelObserved";
    Break[]];
  If[FileHash[driverFile, "SHA256", "HexString"] =!= driverHash,
    releaseReason = "SourceChanged";
    finalCode = 68;
    Break[]];
  currentStates = poisonStates[];
  currentFingerprints = poisonFingerprints[currentStates];
  If[currentFingerprints =!= expectedPoisonFingerprints,
    releaseReason = "PoisonFingerprintDrift";
    finalCode = 69;
    Break[]];
  Pause[Min[heartbeatSeconds, Max[1,
    Floor[deadline - AbsoluteTime[]]]]];
  heartbeatCount++;
  Print["KERNEL_POOL_QUARANTINE heartbeat=", heartbeatCount,
    " kernel=", $KernelID,
    " remaining_s=", Max[0, Floor[deadline - AbsoluteTime[]]],
    " token=", reservationToken]];

finalStates = poisonStates[];
finalFingerprints = poisonFingerprints[finalStates];
If[finalFingerprints =!= expectedPoisonFingerprints && finalCode === 0,
  releaseReason = "FinalPoisonFingerprintDrift";
  finalCode = 69];
Print["KERNEL_POOL_QUARANTINE status=released reason=", releaseReason,
  " code=", finalCode, " kernel=", $KernelID,
  " elapsed_s=", N[AbsoluteTime[] - startTime],
  " token=", reservationToken,
  " final_poison_fingerprints=", InputForm[finalFingerprints],
  " source_stable=",
  FileHash[driverFile, "SHA256", "HexString"] === driverHash];
quarantineExit[finalCode];

