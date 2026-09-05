#!/usr/bin/env wolframscript

(* Scheduling-only regression for follower waves.  The mathematical image
   evaluator and authenticator are replaced by exact keyed records, so this
   test exercises no sampling, row reduction, native backend or subkernel. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{wave, kernelCount} = mq /@ {
  "multiquadraticOffDiagonalBlockFollowerImageWave",
  "multiquadraticOffDiagonalBlockFollowerImageKernelCount"};

prime = 2147483423;
payload = <|"Schema" -> "SyntheticFollowerPayload"|>;
requests = (<|"Prime" -> prime, "RegulatorValue" -> #|> &) /@
  Range[7];
syntheticRecord[request_Association, site_String] := <|
  "Status" -> "SyntheticFollowerImageRecord",
  "Prime" -> request["Prime"],
  "RegulatorValue" -> request["RegulatorValue"],
  "WorkerKernelID" -> If[site === "Helper", 1, 0],
  "SyntheticExecutionSite" -> site|>;
dispatcher[_Association, request_Association] :=
  syntheticRecord[request, "Helper"];

{wholeWave, reducedWave, singletonTailWave} = Internal`InheritedBlock[{
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageSolve,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageAuthenticate},
  Unprotect[
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageSolve,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageAuthenticate];
  Clear[
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageSolve,
    FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageAuthenticate];
  FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[
      _Association] := True;
  FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageSolve[
      _Association, request_Association] :=
    syntheticRecord[request, "Coordinator"];
  FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageAuthenticate[
      record_Association, _Association, request_Association,
      _ : False] :=
    If[Lookup[record, {"Prime", "RegulatorValue"}, None] ===
        Lookup[request, {"Prime", "RegulatorValue"}, None],
      <|"Status" -> "AuthenticatedMultiquadraticFollowerImageV1"|>,
      <|"Status" -> "FollowerImageAuthenticationFailed"|>];
  {wave[payload, requests, 7, 60, Infinity, dispatcher],
   wave[payload, requests, 3, 60, Infinity, dispatcher],
   wave[payload, Take[requests, 1], 7, 60, Infinity, dispatcher]}
];

requestKeys = Lookup[#, {"Prime", "RegulatorValue"}] & /@ requests;
FTAssert["seven free helpers consume the whole wave in request order",
  wholeWave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    wholeWave["Route"] === "InjectedDispatcher" &&
    wholeWave["RequestedConcurrency"] === 7 &&
    wholeWave["Concurrency"] === 7 &&
    wholeWave["BatchSize"] === 7 &&
    wholeWave["FallbackIndices"] === {} &&
    wholeWave["ResultRoutes"] ===
      ConstantArray["InjectedFollower", 7] &&
    (Lookup[#, {"Prime", "RegulatorValue"}] & /@
        wholeWave["Results"]) === requestKeys &&
    Lookup[wholeWave["Results"], "SyntheticExecutionSite"] ===
      ConstantArray["Helper", 7]];

FTAssert["reduced helper capacity retains order and computes only its tail locally",
  reducedWave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    reducedWave["RequestedConcurrency"] === 3 &&
    reducedWave["Concurrency"] === 4 &&
    reducedWave["FallbackIndices"] === {} &&
    reducedWave["ResultRoutes"] === Join[
      ConstantArray["InjectedFollower", 3],
      ConstantArray["SerialFollower", 4]] &&
    (Lookup[#, {"Prime", "RegulatorValue"}] & /@
        reducedWave["Results"]) === requestKeys &&
    Lookup[reducedWave["Results"], "SyntheticExecutionSite"] === Join[
      ConstantArray["Helper", 3], ConstantArray["Coordinator", 4]]];

FTAssert["an available helper consumes a singleton tail without coordinator evaluation",
  singletonTailWave["Status"] ===
      "MultiquadraticFollowerImageWaveV1" &&
    singletonTailWave["Concurrency"] === 1 &&
    singletonTailWave["ResultRoutes"] === {"InjectedFollower"} &&
    Lookup[First[singletonTailWave["Results"]],
      "SyntheticExecutionSite", None] === "Helper"];

capacityResolution = Internal`InheritedBlock[{
    FeynFacet`Private`taskBrokerActiveQ,
    FeynFacet`Private`taskBrokerFreeKernels,
    FeynFacet`Private`taskBrokerActiveFamilyCount,
    FeynFacet`Private`taskBrokerNativeCoreQuota,
    FeynFacet`Private`taskBrokerNativeThreadLimit},
  Unprotect[FeynFacet`Private`taskBrokerActiveQ,
    FeynFacet`Private`taskBrokerFreeKernels,
    FeynFacet`Private`taskBrokerActiveFamilyCount,
    FeynFacet`Private`taskBrokerNativeCoreQuota,
    FeynFacet`Private`taskBrokerNativeThreadLimit];
  Clear[FeynFacet`Private`taskBrokerActiveQ,
    FeynFacet`Private`taskBrokerFreeKernels,
    FeynFacet`Private`taskBrokerActiveFamilyCount,
    FeynFacet`Private`taskBrokerNativeCoreQuota,
    FeynFacet`Private`taskBrokerNativeThreadLimit];
  FeynFacet`Private`taskBrokerActiveQ[] := True;
  FeynFacet`Private`taskBrokerFreeKernels[] := freeHelpers;
  FeynFacet`Private`taskBrokerActiveFamilyCount[] := 1;
  FeynFacet`Private`taskBrokerNativeCoreQuota[] := 8;
  FeynFacet`Private`taskBrokerNativeThreadLimit[value_] := value;
  {freeHelpers = 7; kernelCount[Automatic, 8],
   freeHelpers = 3; kernelCount[Automatic, 8],
   freeHelpers = 0; kernelCount[Automatic, 8]}
];
FTAssert["one-family capacity resolves to seven or three helpers and the serial sentinel",
  capacityResolution === {7, 3, 1}];

FTReport[];
