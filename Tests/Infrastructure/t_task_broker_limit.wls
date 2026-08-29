#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "TaskBroker.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

directory = CreateDirectory[];
CreateDirectory[FileNameJoin[{directory, "queue"}]];
Export[FileNameJoin[{directory, "status.txt"}],
  "KernelPool status test\nsubkernels: 8  busy: 3  free: 5\n", "Text"];
Export[FileNameJoin[{directory, "pool.pid"}], ToString[$ProcessID], "Text"];
oldBroker = Environment["FACET_TASK_BROKER"];
oldLimit = Environment["FACET_TASK_BROKER_MAX_HELPERS"];
SetEnvironment["FACET_TASK_BROKER" -> directory];
expectedMissionLimit = If[Length[$ScriptCommandLine] >= 2 &&
    StringMatchQ[Last[$ScriptCommandLine], DigitCharacter ..],
  FromDigits[Last[$ScriptCommandLine]], Infinity];
FTTest`FTAssert["kpsubmit captures a mission helper ceiling",
  expectedMissionLimit === Infinity ||
    KernelPoolMission`$TaskBrokerMaxHelpers === expectedMissionLimit];

Block[{KernelPoolMission`$TaskBrokerMaxHelpers = Infinity},
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "2"];
  FTTest`FTAssert["task broker applies a pool-wide helper ceiling",
    FeynFacet`Private`taskBrokerFreeKernels[] === 2];
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "0"];
  FTTest`FTAssert["task broker accepts a serial zero-helper ceiling",
    FeynFacet`Private`taskBrokerFreeKernels[] === 0];
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "17"];
  FTTest`FTAssert["task broker never exceeds the live free count",
    FeynFacet`Private`taskBrokerFreeKernels[] === 5];
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "invalid"];
  FTTest`FTAssert["an invalid helper ceiling leaves the live count intact",
    FeynFacet`Private`taskBrokerFreeKernels[] === 5]];
FTTest`FTAssert["a mission-scoped ceiling overrides a missing shell update",
  Block[{KernelPoolMission`$TaskBrokerMaxHelpers = 2},
    FeynFacet`Private`taskBrokerFreeKernels[]] === 2];
FTTest`FTAssert["a mission may forbid helpers without changing the pool",
  Block[{KernelPoolMission`$TaskBrokerMaxHelpers = 0},
    FeynFacet`Private`taskBrokerFreeKernels[]] === 0];

oldNonceHandle = Block[
  {FeynFacet`Private`$taskBrokerNonce =
      "11111111111111111111111111111111",
   FeynFacet`Private`$taskBrokerCounter = 0},
  FeynFacet`Private`taskBrokerSubmit[{"1"}, "Label" -> "nonce"]];
Put["stale", First[oldNonceHandle["ResultFiles"]]];
newNonceHandle = Block[
  {FeynFacet`Private`$taskBrokerNonce =
      "22222222222222222222222222222222",
   FeynFacet`Private`$taskBrokerCounter = 0},
  FeynFacet`Private`taskBrokerSubmit[{"2"}, "Label" -> "nonce"]];
FTTest`FTAssert["a TaskBroker reload cannot reuse a stale task result name",
  Intersection[oldNonceHandle["Names"], newNonceHandle["Names"]] === {} &&
    Intersection[oldNonceHandle["ResultFiles"],
      newNonceHandle["ResultFiles"]] === {} &&
    ! MemberQ[newNonceHandle["ResultFiles"],
      First[oldNonceHandle["ResultFiles"]]]];

Clear[brokerSpySubmit, brokerSpyCollect, brokerSpyCanonica,
  submittedCodes];
brokerSpySubmit[codes_List, ___Rule] := (
  submittedCodes = codes; <|"Codes" -> codes|>);
brokerSpyCollect[handle_Association] :=
  ConstantArray[<|"Origin" -> "Farmed"|>, Length[handle["Codes"]]];
brokerSpyCanonica[_, _, _, _, _, _, degree_Integer] :=
  <|"Origin" -> "Local", "NumeratorDegree" -> degree,
    "ExactDLog" -> False|>;

submittedCodes = None;
zeroQuotaLadder = Block[
  {KernelPoolMission`$TaskBrokerMaxHelpers = 0,
   FeynFacet`Private`taskBrokerSubmit = brokerSpySubmit,
   FeynFacet`Private`taskBrokerCollect = brokerSpyCollect,
   FeynFacet`Private`epsFormStripRunCanonicaOne = brokerSpyCanonica},
  FeynFacet`Private`taskBrokerCanonicaLadder[
    {{}, {}, {}}, {x, y}, eps, {}, {0, 1, 2, 3}, 0, 1]];
FTTest`FTAssert["a zero helper quota submits no CANONICA degree tasks",
  submittedCodes === None &&
    Lookup[zeroQuotaLadder, "NumeratorDegree"] === {0, 1, 2, 3}];

submittedCodes = None;
limitedQuotaLadder = Block[
  {KernelPoolMission`$TaskBrokerMaxHelpers = 2,
   FeynFacet`Private`taskBrokerSubmit = brokerSpySubmit,
   FeynFacet`Private`taskBrokerCollect = brokerSpyCollect,
   FeynFacet`Private`epsFormStripRunCanonicaOne = brokerSpyCanonica},
  FeynFacet`Private`taskBrokerCanonicaLadder[
    {{}, {}, {}}, {x, y}, eps, {}, {0, 1, 2, 3}, 0, 1]];
FTTest`FTAssert["a positive helper quota farms only that many CANONICA degrees",
  Length[submittedCodes] === 2 &&
    Lookup[limitedQuotaLadder, "Origin"] ===
      {"Local", "Farmed", "Farmed", "Local"} &&
    Lookup[limitedQuotaLadder, "NumeratorDegree", Missing["Farmed"]] ===
      {0, Missing["Farmed"], Missing["Farmed"], 3}];

failedName = "tb_failed_cleanup";
failedResultFile = FileNameJoin[{directory, "data", "results",
  failedName <> ".wl"}];
CreateDirectory[DirectoryName[failedResultFile],
  CreateIntermediateDirectories -> True];
CreateDirectory[FileNameJoin[{directory, "failed"}]];
Put[$Failed, failedResultFile];
Put[<|"Status" -> "FAILED"|>,
  FileNameJoin[{directory, "failed", failedName <> ".status"}]];
Put[Null, FileNameJoin[{directory, "failed", failedName <> ".wl"}]];
Block[{FeynFacet`Private`$taskBrokerLog = False},
  FeynFacet`Private`taskBrokerCollect[<|
    "Directory" -> directory, "Names" -> {failedName},
    "ResultFiles" -> {failedResultFile}, "Start" -> AbsoluteTime[],
    "Timeout" -> 0, "Label" -> "cleanup"|>]];
FTTest`FTAssert["failed broker missions leave no status or mission artifacts",
  ! FileExistsQ[FileNameJoin[{directory, "failed",
      failedName <> ".status"}]] &&
    ! FileExistsQ[FileNameJoin[{directory, "failed",
      failedName <> ".wl"}]]];

resourceFile = FileNameJoin[{directory, "resource_allocations.wl"}];
allocation[helpers_, native_, perWorker_] := <|
  "Schema" -> "KernelPoolResourceAllocationV1",
  "SubkernelCapacity" -> 8, "NativeCoreCapacity" -> 16,
  "ActiveFamilyCount" -> 2, "HelperCapacity" -> 6,
  "Groups" -> <|"CF300" -> <|"HelperCeiling" -> helpers,
    "NativeCoreQuota" -> native, "RunningWorkers" -> 2,
    "NativeThreadsPerWorker" -> perWorker|>|>|>;
Put[allocation[2, 8, 4], resourceFile];
SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "invalid"];
dynamicGrant = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerMaxHelpers = Infinity},
  {FeynFacet`Private`taskBrokerFreeKernels[],
   FeynFacet`Private`taskBrokerActiveFamilyCount[],
   FeynFacet`Private`taskBrokerNativeCoreQuota[],
   FeynFacet`Private`taskBrokerNativeThreadLimit[8]}];
FTTest`FTAssert["pool-owned family grant caps helpers and native threads",
  dynamicGrant === {2, 2, 8, 4}];

Export[FileNameJoin[{directory, "status.txt"}],
  "KernelPool status test\nsubkernels: 8  busy: 8  free: 0\n", "Text"];
contendedGrant = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerMaxHelpers = Infinity},
  FeynFacet`Private`taskBrokerFreeKernels[]];
FTTest`FTAssert[
  "a family queues against its grant when borrowed helpers occupy the pool",
  contendedGrant === 2];
Export[FileNameJoin[{directory, "status.txt"}],
  "KernelPool status test\nsubkernels: 8  busy: 3  free: 5\n", "Text"];

Put[allocation[4, 12, 8], resourceFile];
rebalancedGrant = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerMaxHelpers = Infinity},
  {FeynFacet`Private`taskBrokerFreeKernels[],
   FeynFacet`Private`taskBrokerNativeCoreQuota[],
   FeynFacet`Private`taskBrokerNativeThreadLimit[8]}];
FTTest`FTAssert["a replaced allocation is observed without reloading the mission",
  rebalancedGrant === {4, 12, 8}];

Clear[brokerSampleSubmit, brokerSampleCollect, brokerSampleAffine,
  capturedSampleCodes, capturedLocalThreads];
brokerSampleSubmit[codes_List, ___Rule] := (
  capturedSampleCodes = codes; <|"Codes" -> codes|>);
brokerSampleCollect[handle_Association] :=
  Table[{index}, {index, Length[handle["Codes"]]}];
brokerSampleAffine[_, value_, _, opts___Rule] := (
  capturedLocalThreads = Lookup[Association[{opts}],
    "BackendThreads", None]; value);
capturedSampleCodes = {}; capturedLocalThreads = None;
balancedSample = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerMaxHelpers = Infinity,
   FeynFacet`Private`taskBrokerSubmit = brokerSampleSubmit,
   FeynFacet`Private`taskBrokerCollect = brokerSampleCollect,
   FeynFacet`SampleEpsFormStripAffine = brokerSampleAffine},
  FeynFacet`Private`taskBrokerSampleBatch[<||>, {1, 2, 3, 4},
    1000003, {"ExpectedFingerprint" -> "sample-balance",
      "BackendThreads" -> 8}]];
balancedOptionsFile = First[FileNames[
  "opts_sample-balance_*.wl", FileNameJoin[{directory, "data"}]], None];
balancedHelperThreads = If[StringQ[balancedOptionsFile], Lookup[
  Association[Get[balancedOptionsFile]], "BackendThreads", None], None];
FTTest`FTAssert["a family native quota is divided across all sample workers",
  Length[capturedSampleCodes] === 3 && capturedLocalThreads === 3 &&
    balancedHelperThreads === 3 && balancedSample === {1, 2, 3, 4}];

Put[allocation[4, 3, 1], resourceFile];
capturedLocalThreads = None;
Block[{KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerMaxHelpers = Infinity,
   FeynFacet`Private`taskBrokerSubmit = brokerSampleSubmit,
   FeynFacet`Private`taskBrokerCollect = brokerSampleCollect,
   FeynFacet`SampleEpsFormStripAffine = brokerSampleAffine},
  FeynFacet`Private`taskBrokerSampleBatch[<||>, {1, 2, 3, 4},
    1000003, {"ExpectedFingerprint" -> "sample-balance-small",
      "BackendThreads" -> 8}]];
smallOptionsFile = First[FileNames["opts_sample-balance-small_*.wl",
  FileNameJoin[{directory, "data"}]], None];
FTTest`FTAssert["oversubscribed sample workers fall back to one native thread",
  capturedLocalThreads === 1 && StringQ[smallOptionsFile] &&
    Lookup[Association[Get[smallOptionsFile]], "BackendThreads", None] === 1];

CreateDirectory[FileNameJoin[{directory, "control"}]];
Export[FileNameJoin[{directory, "control", "native_cores"}], "3\n", "Text"];
leasedCommand = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerResourceOwner = "fresh_sol_CF300"},
  FeynFacet`Private`taskBrokerNativeCommand[
    {"adapter", "input", "output", "8"}, 8]];
FTTest`FTAssert["native adapters are routed through the live lease with the current cap",
  FileNameTake[First[leasedCommand]] === "native_core_lease.sh" &&
    leasedCommand[[2]] === directory && leasedCommand[[3]] === "1" &&
    leasedCommand[[4]] === "--" && Last[leasedCommand] === "1"];

groupedHandle = Block[
  {KernelPoolMission`$TaskBrokerResourceGroup = "CF300",
   KernelPoolMission`$TaskBrokerResourceOwner = "fresh_sol_CF300"},
  FeynFacet`Private`taskBrokerSubmit[{"1"}, "Label" -> "grouped"]];
groupedMission = Import[FileNameJoin[{directory, "queue",
  First[groupedHandle["Names"]] <> ".wl"}], "Text"];
FTTest`FTAssert["broker helpers inherit resource group metadata",
  StringContainsQ[groupedMission,
    "FACET_RESOURCE group=CF300 role=helper owner=fresh_sol_CF300"] &&
  StringContainsQ[groupedMission,
    "KernelPoolMission`$TaskBrokerResourceGroup = \"CF300\""] &&
  StringContainsQ[groupedMission,
    "KernelPoolMission`$TaskBrokerResourceOwner = \"fresh_sol_CF300\""]];

If[StringQ[oldBroker], SetEnvironment["FACET_TASK_BROKER" -> oldBroker],
  SetEnvironment["FACET_TASK_BROKER" -> ""]];
If[StringQ[oldLimit],
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> oldLimit],
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> ""]];
DeleteDirectory[directory, DeleteContents -> True];

FTTest`FTReport[];
