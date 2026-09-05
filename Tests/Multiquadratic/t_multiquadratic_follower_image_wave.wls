#!/usr/bin/env wolframscript
(* Post-plan follower images are pure worker records.  The focused dispatcher
   seam exercises ordered bounded-wave admission and serial recomputation
   without launching a helper kernel. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{prepare, compile, layoutBuilder, compiledProvider, assembleSample,
  discoverySolve, planDiscover, payloadRecord, payloadValidQ, followerSolve,
  followerAuthenticate, followerWave, kernelCount} = mq /@ {
  "multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockCompile",
  "multiquadraticOffDiagonalBlockAssemblyLayout",
  "multiquadraticOffDiagonalBlockCompiledProvider",
  "multiquadraticOffDiagonalBlockAssembleSample",
  "multiquadraticOffDiagonalBlockPlanDiscoverySolve",
  "multiquadraticOffDiagonalBlockConstrainedPlanDiscover",
  "multiquadraticOffDiagonalBlockFollowerImagePayload",
  "multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ",
  "multiquadraticOffDiagonalBlockFollowerImageSolve",
  "multiquadraticOffDiagonalBlockFollowerImageAuthenticate",
  "multiquadraticOffDiagonalBlockFollowerImageWave",
  "multiquadraticOffDiagonalBlockFollowerImageKernelCount"};

Clear[px, py, pe, psx, psy];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {}, {psx, psy}, {px, py}];
record = <|"Family" -> "FOLLOWER_WAVE_TEST", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {px, py}, "Regulator" -> pe,
  "OffDiagonalBlockEquation" -> {{{{0}}, {{0}}}, {{{1}}, {{0}}}, {{{0}}, {{0}}}}|>;
preparation = prepare[record, frame, "OneForms" -> {},
  "OffDiagonalBasisTransformationDenominator" -> 1, "Support" -> {{0, 0}}];
assembly = compile[preparation];
layout = layoutBuilder[preparation];
provider = compiledProvider[assembly];
prime = First[FeynFacet`Private`$multiquadraticOffDiagonalBlockPrimePool];
sample = assembleSample[layout, provider, 1, prime, "PointCount" -> 2,
  "MaximumAttempts" -> 40, "RandomSeed" -> 2026082711];
solution = discoverySolve[sample["Matrix"], sample["RightHandSide"],
  prime, preparation["OffDiagonalBasisTransformationUnknownCount"],
  preparation["ResidueUnknownCount"], "Wolfram", 1, Automatic];
normalizationColumns = If[solution["Nullity"] === 0, {},
  FeynFacet`Private`finiteFieldOffDiagonalBlockNormalizationColumns[
    Normal[solution["NullspaceBasis"]], preparation["OffDiagonalBasisTransformationUnknownCount"],
    preparation["ResidueUnknownCount"], prime]];
plan = planDiscover[sample["Matrix"], sample["RightHandSide"], solution,
  normalizationColumns, prime, layout["CoefficientData"]];
payload = payloadRecord[layout, provider, plan, 2, 40, 2026082711];
requests = {<|"Prime" -> prime, "RegulatorValue" -> 2|>,
  <|"Prime" -> prime, "RegulatorValue" -> 3|>};
records = followerSolve[payload, #1] & /@ requests;

If[! TrueQ[payloadValidQ[payload]] ||
    ! AllTrue[records, AssociationQ],
  Print["DIAGNOSTIC follower fixture: ", InputForm[<|
    "Preparation" -> Lookup[preparation, "Status", Head[preparation]],
    "Assembly" -> Lookup[assembly, "Status", Head[assembly]],
    "Sample" -> Lookup[sample, "Status", Head[sample]],
    "Solution" -> Lookup[solution, "Status", Head[solution]],
    "Plan" -> Lookup[plan, "Status", Head[plan]],
    "Payload" -> If[AssociationQ[payload],
      KeyTake[payload, {"Status", "Schema", "Reason"}], Head[payload]],
    "Records" -> If[AssociationQ[#],
        KeyTake[#, {"Status", "Reason", "Detail"}], Head[#]] & /@ records|>]]];

FTTest`FTAssert["the helper payload and both immutable records authenticate",
  payloadValidQ[payload] &&
    AllTrue[MapThread[followerAuthenticate, {records,
        ConstantArray[payload, 2], requests}],
      Lookup[#1, "Status", None] ===
        "AuthenticatedMultiquadraticFollowerImageV1" &] &&
    AllTrue[records, ! KeyExistsQ[#1["Result"], "Matrix"] &&
      AllTrue[#1["Result", "TrainingImageKeys"],
        MatchQ[#, {_Integer, _Integer | _Rational,
          {_Integer, _Integer}}] &] &]];

mutant = records[[1]];
mutant["Result", "PivotColumns"] = {999};
mutantAuthentication = followerAuthenticate[mutant, payload, requests[[1]]];
FTTest`FTAssert["a result with different pivot columns is refused",
  mutantAuthentication["Status"] === "FollowerImageAuthenticationFailed" &&
    mutantAuthentication["Reason"] ===
      "FollowerImageResultCertificateInvalid"];

keyMutant = records[[1]];
keyMutant["RegulatorValue"] = 5;
keyAuthentication = followerAuthenticate[keyMutant, payload, requests[[1]]];
FTTest`FTAssert["a cross-image record is refused",
  keyAuthentication["Status"] === "FollowerImageAuthenticationFailed" &&
    keyAuthentication["Reason"] === "FollowerImageRecordKeyMismatch"];

(* The injected helper deliberately returns the second image for the first
   request.  Admission must reject it, recompute request one locally and keep
   the original request order. *)
misroute[payload_, request_] := followerSolve[payload, requests[[2]]];
wave = followerWave[payload, requests, 2, 60, Infinity, misroute];
If[! TrueQ[wave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    wave["FallbackIndices"] === {1} &&
    wave["ResultRoutes"] ===
      {"SerialFollowerFallback", "InjectedFollower"}],
  Print["DIAGNOSTIC misrouted wave: ", InputForm[KeyDrop[wave,
    {"Results"}]]]];
FTTest`FTAssert["a misrouted helper result is recomputed in schedule order",
  wave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    wave["FallbackIndices"] === {1} &&
    wave["ResultRoutes"] ===
      {"SerialFollowerFallback", "InjectedFollower"} &&
    (Lookup[#1, {"Prime", "RegulatorValue"}] & /@ wave["Results"]) ===
      ({prime, #1} & /@ {2, 3}) &&
    AllTrue[MapThread[followerAuthenticate,
      {wave["Results"], ConstantArray[payload, 2], requests}],
      Lookup[#1, "Status", None] ===
        "AuthenticatedMultiquadraticFollowerImageV1" &]];

wideRequests = (<|"Prime" -> prime, "RegulatorValue" -> #1|> &) /@
  {8, 9, 10, 11};
identityDispatcher[currentPayload_, request_] :=
  followerSolve[currentPayload, request];
wideWave = followerWave[payload, wideRequests, 4, 60, Infinity,
  identityDispatcher];
FTTest`FTAssert["four-wide waves preserve request order and keep the coordinator out",
  wideWave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    wideWave["Route"] === "InjectedDispatcher" &&
    wideWave["Concurrency"] === 4 &&
    wideWave["RequestedConcurrency"] === 4 &&
    wideWave["BatchSize"] === 4 &&
    wideWave["FallbackIndices"] === {} &&
    wideWave["ResultRoutes"] ===
      ConstantArray["InjectedFollower", 4] &&
    (Lookup[#1, {"Prime", "RegulatorValue"}] & /@
        wideWave["Results"]) === ({prime, #1} & /@ {8, 9, 10, 11})];

serialWave = followerWave[payload, requests, 1, 60, Infinity];
FTTest`FTAssert["serial fallback retains the same deterministic record order",
  serialWave["Route"] === "Serial" && serialWave["Concurrency"] === 1 &&
    serialWave["Timeout"] === 60 &&
    serialWave["ResultRoutes"] ===
      {"SerialFollower", "SerialFollower"} &&
    (Lookup[#1, {"Prime", "RegulatorValue"}] & /@
        serialWave["Results"]) ===
      ({prime, #1} & /@ {2, 3})];

expiredWave = followerWave[payload, requests, 2, 60,
  AbsoluteTime[] - 1, misroute];
If[! TrueQ[expiredWave["Status"] === "BudgetExhausted" &&
    expiredWave["AbandonedFallbackIndices"] === {1}],
  Print["DIAGNOSTIC expired wave: ", InputForm[KeyDrop[expiredWave,
    {"Results", "AbandonedRequests"}]]]];
FTTest`FTAssert["an expired malformed-helper fallback is abandoned typed",
  expiredWave["Status"] === "BudgetExhausted" &&
    expiredWave["Stage"] ===
      "RegulatorReconstruction:FollowerWaveFallback" &&
    expiredWave["AbandonedFallbackIndices"] === {1} &&
    expiredWave["LateBrokerWorkNotCancelled"] === False];

serialResolution = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerActiveQ},
  Unprotect[FeynFacet`Private`taskBrokerActiveQ];
  Clear[FeynFacet`Private`taskBrokerActiveQ];
  FeynFacet`Private`taskBrokerActiveQ[] := False;
  kernelCount[Automatic, 8]];
parallelResolution = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerActiveQ,
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
  FeynFacet`Private`taskBrokerFreeKernels[] := 1;
  FeynFacet`Private`taskBrokerActiveFamilyCount[] := 1;
  FeynFacet`Private`taskBrokerNativeCoreQuota[] := 8;
  FeynFacet`Private`taskBrokerNativeThreadLimit[value_] := value;
  kernelCount[2, 8]];
multiFamilyResolution = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerActiveQ,
   FeynFacet`Private`taskBrokerFreeKernels,
   FeynFacet`Private`taskBrokerActiveFamilyCount,
   FeynFacet`Private`taskBrokerNativeCoreQuota,
   FeynFacet`Private`taskBrokerNativeThreadLimit},
  Unprotect[FeynFacet`Private`taskBrokerActiveQ,
    FeynFacet`Private`taskBrokerFreeKernels,
    FeynFacet`Private`taskBrokerActiveFamilyCount,
    FeynFacet`Private`taskBrokerNativeCoreQuota,
    FeynFacet`Private`taskBrokerNativeThreadLimit];
  FeynFacet`Private`taskBrokerActiveQ[] := True;
  FeynFacet`Private`taskBrokerFreeKernels[] := 7;
  FeynFacet`Private`taskBrokerActiveFamilyCount[] := 2;
  FeynFacet`Private`taskBrokerNativeCoreQuota[] := 8;
  FeynFacet`Private`taskBrokerNativeThreadLimit[value_] := value;
  kernelCount[Automatic, 1]];
wideResolution = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerActiveQ,
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
  FeynFacet`Private`taskBrokerFreeKernels[] := 7;
  FeynFacet`Private`taskBrokerActiveFamilyCount[] := 1;
  FeynFacet`Private`taskBrokerNativeCoreQuota[] := 8;
  FeynFacet`Private`taskBrokerNativeThreadLimit[value_] := value;
  {kernelCount[Automatic, 8], kernelCount[Automatic, 4],
    kernelCount[2, 8]}];
limitedResolution = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerActiveQ,
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
  FeynFacet`Private`taskBrokerFreeKernels[] := 7;
  FeynFacet`Private`taskBrokerActiveFamilyCount[] := 1;
  FeynFacet`Private`taskBrokerNativeThreadLimit[value_] := value;
  Module[{quota = 4},
    FeynFacet`Private`taskBrokerNativeCoreQuota[] := quota;
    {kernelCount[Automatic, 8],
      quota = 1; kernelCount[Automatic, 8]}]];
FTTest`FTAssert["Automatic is serial without a broker helper",
  serialResolution === 1 &&
    Internal`InheritedBlock[{FeynFacet`Private`taskBrokerActiveQ,
       FeynFacet`Private`taskBrokerFreeKernels},
      Unprotect[FeynFacet`Private`taskBrokerActiveQ,
        FeynFacet`Private`taskBrokerFreeKernels];
      Clear[FeynFacet`Private`taskBrokerActiveQ,
        FeynFacet`Private`taskBrokerFreeKernels];
      FeynFacet`Private`taskBrokerActiveQ[] := True;
      FeynFacet`Private`taskBrokerFreeKernels[] := 0;
      Block[{$ProcessorCount = 16}, kernelCount[Automatic, 8]]] === 1];
FTTest`FTAssert["multi-family operation suppresses nested image waves",
  multiFamilyResolution === 1];
FTTest`FTAssert["an explicit request remains an upper bound on helper-image concurrency",
  parallelResolution === 1 && kernelCount[1, 8] === 1];
FTTest`FTAssert["Automatic uses every free one-core helper lane for one family",
  wideResolution === {7, 7, 2}];
FTTest`FTAssert["Automatic follower-image lanes respect smaller native grants",
  limitedResolution === {4, 1}];

(* Normal suite runs have no broker and therefore prove the serial fallback.
   When this file is submitted as a KernelPool mission, the same fixture also
   exercises the real data-file/task/result protocol rather than the injected
   dispatcher seam. *)
brokerActive = TrueQ[Quiet[Check[
    FeynFacet`Private`taskBrokerActiveQ[], False]]];
brokerWave = If[brokerActive,
  followerWave[payload, requests, 2, 120, Infinity],
  <|"Status" -> "BrokerIntegrationNotRequested"|>];
FTTest`FTAssert["an active TaskBroker returns the ordered two-wide result",
  ! brokerActive ||
    brokerWave["Status"] === "MultiquadraticFollowerImageWaveV1" &&
    brokerWave["Route"] === "TaskBroker" &&
    brokerWave["FallbackIndices"] === {} &&
    brokerWave["ResultRoutes"] ===
      {"TaskBrokerFollower", "TaskBrokerFollower"} &&
    (Lookup[#1, {"Prime", "RegulatorValue"}] & /@
        brokerWave["Results"]) === ({prime, #1} & /@ {2, 3}) &&
    AllTrue[MapThread[followerAuthenticate,
      {brokerWave["Results"], ConstantArray[payload, 2], requests}],
      Lookup[#1, "Status", None] ===
        "AuthenticatedMultiquadraticFollowerImageV1" &]];

FTTest`FTReport[];
