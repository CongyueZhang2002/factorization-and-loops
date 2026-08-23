#!/usr/bin/env wolframscript

root = DirectoryName[DirectoryName[$InputFileName]];
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

If[StringQ[oldBroker], SetEnvironment["FACET_TASK_BROKER" -> oldBroker],
  SetEnvironment["FACET_TASK_BROKER" -> ""]];
If[StringQ[oldLimit],
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> oldLimit],
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> ""]];
DeleteDirectory[directory, DeleteContents -> True];

FTTest`FTReport[];
