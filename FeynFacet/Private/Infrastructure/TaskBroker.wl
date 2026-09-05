(* Task broker: farm the parallelizable pieces of a mission to the FREE
   subkernels of the same KernelPool through its file queue.

   Why (2026-08-21): Wolfram forbids parallel programming inside a
   subkernel (LaunchKernels::subnopar) and the licence allows two main
   kernels on this machine, so "one main kernel + N subkernels, several
   families at once, each family parallelized" needs the MAIN to dispatch
   every parallel piece.  The KernelPool owns the live family allocation:
   a family mission writes sample/degree tasks into the same flat queue,
   and the main kernel admits them fairly under its current helper ceiling.
   Native threads are divided separately over its simultaneous workers.

   Activation: the environment variable FACET_TASK_BROKER names the pool
   directory (set when the pool is started; subkernels inherit it).  A
   task never brokers (it would wait for itself), and a kernel that owns
   real subkernels (kernelCount > 1) keeps using ParallelMap.
   A zero helper grant is not a deadlock: the family computes locally.
   The campaign driver nevertheless keeps two helper seats available for
   worthwhile concurrent batches.

   Cost model: a broker round trip has fixed overhead, so a task must carry a few
   seconds of work; the finite-field sampler brokers only when the pilot
   sample measured at least "BrokerMinimumSeconds" of build time, and the
   CANONICA ladder runs degree 0 locally and farms the rest. *)

ClearAll[
  taskBrokerDirectory,
  taskBrokerActiveQ,
  taskBrokerPoolAliveQ,
  taskBrokerResourceGroup,
  taskBrokerResourceOwner,
  taskBrokerResourceAllocation,
  taskBrokerActiveFamilyCount,
  taskBrokerNativeCoreQuota,
  taskBrokerNativeThreadLimit,
  taskBrokerNativeCommand,
  taskBrokerPutAtomic,
  taskBrokerDataFile,
  taskBrokerRead,
  taskBrokerCached,
  taskBrokerFreeKernels,
  taskBrokerNewName,
  taskBrokerTogetherTask,
  taskBrokerParallelTogether,
  taskBrokerRun,
  taskBrokerSubmit,
  taskBrokerCancel,
  taskBrokerCollect,
  $taskBrokerInsideTask,
  $taskBrokerCache,
  $taskBrokerCounter,
  $taskBrokerNonce,
  $taskBrokerLog
];

$taskBrokerInsideTask = False;
$taskBrokerCache = <||>;
$taskBrokerCounter = 0;
$taskBrokerNonce = StringReplace[CreateUUID[], "-" -> ""];
$taskBrokerLog = True;

taskBrokerDirectory[] := With[{d = Environment["FACET_TASK_BROKER"]},
  If[StringQ[d] && DirectoryQ[FileNameJoin[{d, "queue"}]] &&
      FileExistsQ[FileNameJoin[{d, "pool.pid"}]], d, None]];

taskBrokerPoolAliveQ[] := With[{d = taskBrokerDirectory[]},
  d =!= None && Quiet[Check[
    RunProcess[{"kill", "-0", StringTrim[Import[FileNameJoin[{d, "pool.pid"}], "Text"]]}]["ExitCode"] === 0,
    False]]];

(* usable from a mission: a pool exists, is alive, and we are not a task *)
taskBrokerActiveQ[] := ! TrueQ[$taskBrokerInsideTask] && taskBrokerPoolAliveQ[];

taskBrokerResourceGroup[] := Module[{scoped, inherited},
  scoped = If[ValueQ[KernelPoolMission`$TaskBrokerResourceGroup],
    KernelPoolMission`$TaskBrokerResourceGroup, None];
  inherited = Environment["FACET_RESOURCE_GROUP"];
  Which[
    StringQ[scoped] && StringMatchQ[scoped,
      RegularExpression["[A-Za-z0-9][A-Za-z0-9._-]{0,179}"]], scoped,
    StringQ[inherited] && StringMatchQ[inherited,
      RegularExpression["[A-Za-z0-9][A-Za-z0-9._-]{0,179}"]], inherited,
    True, "ungrouped"]
];

taskBrokerResourceOwner[] := Module[{scoped, inherited},
  scoped = If[ValueQ[KernelPoolMission`$TaskBrokerResourceOwner],
    KernelPoolMission`$TaskBrokerResourceOwner, None];
  inherited = Environment["FACET_RESOURCE_OWNER"];
  Which[
    StringQ[scoped] && StringMatchQ[scoped,
      RegularExpression["[A-Za-z0-9][A-Za-z0-9._-]{0,179}"]], scoped,
    StringQ[inherited] && StringMatchQ[inherited,
      RegularExpression["[A-Za-z0-9][A-Za-z0-9._-]{0,179}"]], inherited,
    True, "ungrouped"]
];

(* The main KernelPool owns this snapshot and replaces it atomically whenever
   the active family or running-worker set changes.  Readers never reserve a
   seat themselves; fair dispatch remains centralized in the main kernel. *)
taskBrokerResourceAllocation[] := Module[
  {directory = taskBrokerDirectory[], file, allocation, groups, record},
  If[directory === None, Return[<||>]];
  file = FileNameJoin[{directory, "resource_allocations.wl"}];
  If[! FileExistsQ[file], Return[<||>]];
  allocation = Quiet[Check[Get[file], $Failed]];
  If[! AssociationQ[allocation] ||
      Lookup[allocation, "Schema", None] =!=
        "KernelPoolResourceAllocationV1", Return[<||>]];
  groups = Lookup[allocation, "Groups", <||>];
  If[! AssociationQ[groups], Return[<||>]];
  record = Lookup[groups, taskBrokerResourceGroup[], <||>];
  If[! AssociationQ[record] ||
      ! IntegerQ[Lookup[record, "HelperCeiling", None]] ||
      Lookup[record, "HelperCeiling", -1] < 0 ||
      ! IntegerQ[Lookup[record, "NativeCoreQuota", None]] ||
      Lookup[record, "NativeCoreQuota", 0] < 1 ||
      ! IntegerQ[Lookup[record, "NativeThreadsPerWorker", None]] ||
      ! Between[Lookup[record, "NativeThreadsPerWorker", 0], {1, 8}],
    Return[<||>]];
  Join[KeyTake[allocation, {"ActiveFamilyCount", "HelperCapacity",
      "SubkernelCapacity", "NativeCoreCapacity"}], record]
];

taskBrokerActiveFamilyCount[] := Max[1, Lookup[
  taskBrokerResourceAllocation[], "ActiveFamilyCount", 1]];
taskBrokerNativeCoreQuota[] := Module[{allocation, processors},
  allocation = taskBrokerResourceAllocation[];
  If[IntegerQ[Lookup[allocation, "NativeCoreQuota", None]],
    Return[Max[1, allocation["NativeCoreQuota"]]]];
  processors = Quiet[Check[$ProcessorCount, 1]];
  If[IntegerQ[processors] && processors > 0, processors, 1]
];
taskBrokerNativeThreadLimit[requested_Integer] := Module[{limit},
  If[! Between[requested, {1, 8}], Return[requested]];
  limit = Lookup[taskBrokerResourceAllocation[],
    "NativeThreadsPerWorker", requested];
  If[IntegerQ[limit] && Between[limit, {1, 8}], Min[requested, limit],
    requested]
];
taskBrokerNativeThreadLimit[value_] := value;

(* A published quota alone cannot shrink an adapter that is already running.
   Every native subprocess therefore also takes a process-shared lease.  The
   wrapper may reduce the final thread argument or wait for older calls to
   drain; standalone calls retain the direct command. *)
taskBrokerNativeCommand[command_List, requested_Integer] := Module[
  {effective, adjusted, directory, root, wrapper},
  If[command === {} || ! AllTrue[command, StringQ] ||
      ! Between[requested, {1, 8}], Return[command]];
  effective = taskBrokerNativeThreadLimit[requested];
  adjusted = ReplacePart[command, -1 -> ToString[effective]];
  directory = taskBrokerDirectory[];
  If[directory === None || ! taskBrokerPoolAliveQ[], Return[adjusted]];
  root = Quiet[Check[
    DirectoryName[DirectoryName[$feynFacetPrivateDirectory]], None]];
  If[! StringQ[root], Return[adjusted]];
  wrapper = FileNameJoin[{root, "Scripts", "native_core_lease.sh"}];
  If[! FileExistsQ[wrapper], Return[adjusted]];
  Join[{wrapper, directory, ToString[effective], "--"}, adjusted]
];
taskBrokerNativeCommand[command_, _] := command;

taskBrokerPutAtomic[expr_, file_String] := (
  Put[expr, file <> ".tmp"];
  RenameFile[file <> ".tmp", file, OverwriteTarget -> True]; file);

(* shared data written once per key (the strip record, the options) *)
taskBrokerDataFile[key_String, expr_] := Module[{dir, file},
  dir = FileNameJoin[{taskBrokerDirectory[], "data"}];
  If[! DirectoryQ[dir], Quiet[CreateDirectory[dir]]];
  file = FileNameJoin[{dir, key <> ".wl"}];
  If[! FileExistsQ[file], taskBrokerPutAtomic[expr, file]];
  file];

(* context-guarded read, memoized per kernel by path and modification time
   (helpers reuse a strip record and its preparation across tasks) *)
taskBrokerRead[file_String] := taskBrokerCached[{"file", file, FileDate[file]}, FamilyArtifactRead[file]];

SetAttributes[taskBrokerCached, HoldRest];
taskBrokerCached[key_, expr_] := Module[{value},
  If[KeyExistsQ[$taskBrokerCache, key], Return[$taskBrokerCache[key]]];
  value = expr;
  (* a helper serves several strips of several families: keep the cache
     bounded (preparations are tens of MB) *)
  If[Length[$taskBrokerCache] >= 8, $taskBrokerCache = Take[$taskBrokerCache, -4]];
  $taskBrokerCache[key] = value];

(* Helper seats worth planning for.  A grouped family uses at least its
   pool-owned entitlement even when every subkernel is momentarily busy:
   submitting into the fair queue is what lets the pool reclaim borrowed
   capacity for that family.  It plans enough queued work for the pool's full
   current helper capacity, so a sibling family finishing immediately exposes
   useful work instead of a controller-sized static tail; the pool remains
   the authority that distributes those seats fairly.  Ungrouped/legacy
   callers retain the live-free count.  Mission and pool-wide safety ceilings
   remain final bounds. *)
taskBrokerFreeKernels[] := Module[
  {status, m, free, limitText, environmentLimit, missionLimit,
   allocation, familyLimit, helperCapacity, available},
  status = Quiet[Import[FileNameJoin[{taskBrokerDirectory[], "status.txt"}], "Text"]];
  m = If[StringQ[status], StringCases[status, "free: " ~~ n : DigitCharacter .. :> ToExpression[n]], {}];
  free = If[m === {}, 1, First[m]];
  limitText = Environment["FACET_TASK_BROKER_MAX_HELPERS"];
  environmentLimit = If[StringQ[limitText] && StringMatchQ[limitText,
      DigitCharacter ..], FromDigits[limitText], Infinity];
  (* kpsubmit.sh dynamically scopes this value around one mission.  An
     environment variable set by the submitting shell cannot alter the
     environment of an already-running pool subkernel, so the scoped
     value is the actual per-mission control; the inherited environment
     remains a pool-wide safety ceiling. *)
  missionLimit = If[ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
      IntegerQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
      KernelPoolMission`$TaskBrokerMaxHelpers >= 0,
    KernelPoolMission`$TaskBrokerMaxHelpers, Infinity];
  allocation = taskBrokerResourceAllocation[];
  familyLimit = Lookup[allocation, "HelperCeiling", Infinity];
  helperCapacity = Lookup[allocation, "HelperCapacity", 0];
  available = If[IntegerQ[familyLimit],
    Max[free, familyLimit,
      If[IntegerQ[helperCapacity], helperCapacity, 0]], free];
  Min[available, environmentLimit, missionLimit]];

(* FeynFacet is reloaded on persistent pool subkernels, resetting the local
   counter while the PID stays fixed.  A per-load filesystem-safe nonce keeps
   late results from a timed-out task from satisfying a later handle with the
   same label and counter. *)
taskBrokerNewName[label_String] := (
  $taskBrokerCounter++;
  StringJoin["tb_", label, "_", ToString[$ProcessID], "_",
    $taskBrokerNonce, "_", IntegerString[$taskBrokerCounter, 10, 5]]);

(* Exact entrywise rational simplification shared by coefficient-presentation
   pullbacks and off-diagonal block re-expression.  The largest entry stays
   on the controller; the remaining entries are byte-balanced across the
   helper queue. *)
taskBrokerTogetherTask[dataFile_String] := Module[
  {data = taskBrokerRead[dataFile]},
  If[! AssociationQ[data], Return[$Failed]];
  Together /@ (data["Expressions"] /. data["Rules"])
];

taskBrokerParallelTogether[array_, rules_List, label_String,
    deadline_: Infinity] := Module[
  {started = AbsoluteTime[], dimensions = Dimensions[array],
   expressions = Flatten[array], values, helpers, bytes, localIndex,
   helperIndices, helperBatches, batchLoads, targetBatch, dataFiles,
   codes, handle, farmed, missing, timeout, route = "Serial",
   deadlineQ, expiredQ, boundedTogether, timedOutQ},
  deadlineQ = deadline === Infinity ||
    (NumericQ[deadline] && Positive[deadline]);
  expiredQ[] := NumericQ[deadline] && AbsoluteTime[] >= deadline;
  boundedTogether[expression_] := Module[{remaining},
    If[deadline === Infinity, Return[Together[expression]]];
    remaining = N[deadline - AbsoluteTime[]];
    If[remaining <= 0, Return[$Aborted]];
    Quiet[TimeConstrained[Together[expression], remaining, $Aborted]]];
  timedOutQ[value_] := value === $Aborted;
  If[! AllTrue[rules, MatchQ[#1, _Rule] &],
    Return[<|"Status" -> "InvalidTogetherRules"|>]];
  If[! deadlineQ,
    Return[<|"Status" -> "InvalidTogetherDeadline",
      "Deadline" -> deadline|>]];
  If[expiredQ[],
    Return[<|"Status" -> "DeadlineExpired", "Seconds" -> 0.|>]];
  If[expressions === {},
    Return[<|"Status" -> "OK", "Result" -> array, "Route" -> "Serial",
      "Helpers" -> 0, "Tasks" -> 0, "Seconds" -> 0.|>]];
  helpers = If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0];
  helpers = Min[helpers, Max[0, Length[expressions] - 1]];
  values = ConstantArray[$Failed, Length[expressions]];
  If[helpers < 1,
    Do[
      values[[index]] = boundedTogether[
        expressions[[index]] /. rules];
      If[timedOutQ[values[[index]]],
        Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
          "Helpers" -> 0, "Tasks" -> 0,
          "Seconds" -> N[AbsoluteTime[] - started]|>]],
      {index, Length[expressions]}],
    route = "Parallel";
    bytes = ByteCount /@ expressions;
    localIndex = First[Ordering[bytes, -1]];
    helperIndices = DeleteCases[Range[Length[expressions]], localIndex];
    helperBatches = ConstantArray[{}, helpers];
    batchLoads = ConstantArray[0, helpers];
    Do[
      targetBatch = First[Ordering[batchLoads, 1]];
      helperBatches[[targetBatch]] = Append[
        helperBatches[[targetBatch]], index];
      batchLoads[[targetBatch]] += bytes[[index]],
      {index, SortBy[helperIndices, -bytes[[#1]] &]}];
    dataFiles = Map[Function[batch, taskBrokerDataFile[
        taskBrokerNewName["together_data"],
        <|"Expressions" -> expressions[[batch]], "Rules" -> rules|>]],
      helperBatches];
    codes = StringJoin[
        "FeynFacet`Private`taskBrokerTogetherTask[\"", #1, "\"]"] & /@
      dataFiles;
    timeout = If[deadline === Infinity, 7200.,
      Max[0.25, N[deadline - AbsoluteTime[]]]];
    handle = taskBrokerSubmit[codes, "Label" -> label,
      "Timeout" -> timeout];
    values[[localIndex]] = boundedTogether[
      expressions[[localIndex]] /. rules];
    If[timedOutQ[values[[localIndex]]],
      taskBrokerCancel[handle];
      Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
        "Helpers" -> helpers, "Tasks" -> Length[helperBatches],
        "Seconds" -> N[AbsoluteTime[] - started]|>]];
    farmed = taskBrokerCollect[handle];
    If[ListQ[farmed],
      Do[If[index <= Length[farmed] && ListQ[farmed[[index]]] &&
            Length[farmed[[index]]] === Length[helperBatches[[index]]],
          values[[helperBatches[[index]]]] = farmed[[index]]],
        {index, Length[helperBatches]}]];
    missing = Select[helperIndices, values[[#1]] === $Failed &];
    If[expiredQ[],
      Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
        "Helpers" -> helpers, "Tasks" -> Length[helperBatches],
        "Seconds" -> N[AbsoluteTime[] - started]|>]];
    If[missing =!= {},
      Do[
        values[[index]] = boundedTogether[
          expressions[[index]] /. rules];
        If[timedOutQ[values[[index]]],
          Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
            "Helpers" -> helpers, "Tasks" -> Length[helperBatches],
            "Seconds" -> N[AbsoluteTime[] - started]|>]],
        {index, missing}]]];
  If[expiredQ[],
    Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
      "Helpers" -> If[route === "Parallel", helpers, 0],
      "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
      "Seconds" -> N[AbsoluteTime[] - started]|>]];
  <|"Status" -> "OK", "Result" -> ArrayReshape[values, dimensions],
    "Route" -> route,
    "Helpers" -> If[route === "Parallel", helpers, 0],
    "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
taskBrokerParallelTogether[___] :=
  <|"Status" -> "InvalidParallelTogetherInput"|>;

(* run a list of task codes (strings of Wolfram code evaluated in a helper
   kernel) and return their results in order; $Failed for a task that
   failed, timed out, or whose result file is unreadable *)
Options[taskBrokerRun] = {"Timeout" -> 7200, "Label" -> "task"};
taskBrokerRun[codes_List, opts : OptionsPattern[]] :=
  taskBrokerCollect[taskBrokerSubmit[codes, opts]];

(* submit the tasks and return a handle; the caller may compute its own
   share before collecting (the mission kernel no longer idles while the
   helpers work, 2026-08-22) *)
Options[taskBrokerSubmit] = Options[taskBrokerRun];
taskBrokerSubmit[codes_List, OptionsPattern[]] := Module[
  {dir = taskBrokerDirectory[], names, files, resultDir, resultFiles, t0 = AbsoluteTime[],
   timeout = OptionValue["Timeout"], label = OptionValue["Label"],
   resourceGroup, resourceOwner, resourceLiteral, resourceOwnerLiteral},
  If[dir === None, Return[<|"Directory" -> None, "Codes" -> codes|>]];
  resourceGroup = taskBrokerResourceGroup[];
  resourceOwner = taskBrokerResourceOwner[];
  resourceLiteral = ToString[resourceGroup, InputForm];
  resourceOwnerLiteral = ToString[resourceOwner, InputForm];
  resultDir = FileNameJoin[{dir, "data", "results"}];
  If[! DirectoryQ[resultDir], Quiet[CreateDirectory[resultDir, CreateIntermediateDirectories -> True]]];
  names = Table[taskBrokerNewName[label], {Length[codes]}];
  resultFiles = FileNameJoin[{resultDir, # <> ".wl"}] & /@ names;
  files = MapThread[Function[{name, code, resultFile},
    Module[{q = FileNameJoin[{dir, "queue", name <> ".wl"}], text},
      text = StringJoin["(* broker task ", name, " *)\n",
        "(* FACET_RESOURCE group=", resourceGroup, " role=helper owner=",
        resourceOwner, " *)\n",
        "Block[{KernelPoolMission`$TaskBrokerResourceGroup = ",
        resourceLiteral, ", KernelPoolMission`$TaskBrokerResourceRole = \"helper\", ",
        "KernelPoolMission`$TaskBrokerResourceOwner = ",
        resourceOwnerLiteral, "},\n",
        " Module[{taskResult}, FeynFacet`Private`$taskBrokerInsideTask = True;\n",
        "  taskResult = Quiet[Check[", code, ", $Failed]];\n",
        "  FeynFacet`Private`$taskBrokerInsideTask = False;\n",
        "  FeynFacet`Private`taskBrokerPutAtomic[taskResult, \"", resultFile, "\"]; Null]]\n"];
      Export[q <> ".tmp", text, "Text"];
      RenameFile[q <> ".tmp", q, OverwriteTarget -> True]; q]],
    {names, codes, resultFiles}];
  <|"Directory" -> dir, "Names" -> names, "ResultFiles" -> resultFiles, "Start" -> t0,
    "Timeout" -> timeout, "Label" -> label, "Codes" -> codes|>];

(* A surrounding TimeConstrained aborts the collector, not the helper
   evaluations.  Remove work that is still queued and ask the pool to close
   anything already running, so a bounded call cannot leak duplicate jobs. *)
taskBrokerCancel[handle_Association] := Module[
  {dir = Lookup[handle, "Directory", None], names, queueFile, controlFile},
  If[dir === None, Return[Null]];
  names = Lookup[handle, "Names", {}];
  Do[
    queueFile = FileNameJoin[{dir, "queue", name <> ".wl"}];
    If[FileExistsQ[queueFile], Quiet[DeleteFile[queueFile]]];
    controlFile = FileNameJoin[{dir, "control", name <> ".cancel"}];
    taskBrokerPutAtomic[Null, controlFile],
    {name, names}];
  Null];
taskBrokerCancel[___] := Null;

taskBrokerCollect[handle_Association] := CheckAbort[Module[
  {dir = handle["Directory"], names, resultFiles, t0, timeout, label, pending, done, results},
  If[dir === None, Return[ConstantArray[$Failed, Length[handle["Codes"]]]]];
  {names, resultFiles, t0, timeout, label} = Lookup[handle, {"Names", "ResultFiles", "Start", "Timeout", "Label"}];
  pending = names;
  While[pending =!= {} && AbsoluteTime[] - t0 < timeout,
    Pause[0.25];
    done = Select[pending, Function[name,
      FileExistsQ[FileNameJoin[{dir, "done", name <> ".status"}]] ||
      FileExistsQ[FileNameJoin[{dir, "failed", name <> ".status"}]]]];
    pending = Complement[pending, done]];
  If[pending =!= {}, taskBrokerCancel[handle]];
  results = MapThread[Function[{name, resultFile},
    Module[{r = If[FileExistsQ[resultFile], FamilyArtifactRead[resultFile], $Failed]},
      Quiet[DeleteFile[resultFile]];
      Quiet[DeleteFile[FileNameJoin[{dir, "done", name <> ".status"}]]];
      Quiet[DeleteFile[FileNameJoin[{dir, "done", name <> ".wl"}]]];
      Quiet[DeleteFile[FileNameJoin[{dir, "failed", name <> ".status"}]]];
      Quiet[DeleteFile[FileNameJoin[{dir, "failed", name <> ".wl"}]]];
      r]], {names, resultFiles}];
  If[TrueQ[$taskBrokerLog],
    Print["[broker] ", label, ": ", Length[names], " tasks, ",
      Count[results, Except[$Failed]], " results, ", Round[AbsoluteTime[] - t0, 0.1], " s",
      If[pending =!= {}, " (TIMEOUT on " <> ToString[Length[pending]] <> ")", ""]]];
  results],
  taskBrokerCancel[handle]; Abort[]];
