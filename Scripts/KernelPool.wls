(* KernelPool.wls -- persistent kernel-pool server: ONE main kernel of ours holding N
   subkernels, watching a queue directory.  Anyone drops a mission (.wl file, evaluated
   with Get on a free subkernel) into <pool>/queue/; the server dispatches it, writes
   <pool>/logs/<name>.log (all Print/Message output of the mission), moves the file to
   <pool>/done/ or <pool>/failed/ with a <name>.status record, and keeps running.
   Missions can be submitted at ANY time (this is the difference from HCTMissionPool).

   Usage:  taskset -c 0-9 wolframscript -file Scripts/KernelPool.wls <pooldir> [nkernels] [preload]
           pooldir   directory (created); default scratchpad/kernelpool
           nkernels  requested subkernels (default 8; the license decides what launches)
           preload   True|False: Get Addon/Load/LoadFACET.wl in every subkernel at start
   Controls: touch <pool>/control/stop            graceful shutdown when running missions end
             touch <pool>/control/stopnow         shutdown now (aborts running missions)
             touch <pool>/control/<name>.cancel   cancel one running mission (its subkernel is
                                                  closed and replaced)
             write a positive integer to <pool>/control/native_cores to
                                                  resize the native CPU budget live
   Client:   Scripts/kpsubmit.sh <name> <script.wls> [args...]   (writes queue/<name>.wl)
   Status:   <pool>/status.txt (rewritten every loop), <pool>/pool.pid

   Ownership/seat rules (CLAUDE.md): this process IS our one main kernel; while it runs, no
   other main of ours may be launched -- everything goes through the queue.  Kill only by
   the PID in pool.pid or via control/stop. *)

args = Rest[$ScriptCommandLine];
poolDir = If[Length[args] >= 1, args[[1]],
  "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/kernelpool"];
nWanted = If[Length[args] >= 2, ToExpression[args[[2]]], 8];
preload = If[Length[args] >= 3, ToExpression[args[[3]]], True];
root = "/home/maxzhang/factorization-and-loops";
resourcePolicyFile = FileNameJoin[{root, "Scripts",
    "KernelPoolResourcePolicy.wl"}];
If[! FileExistsQ[resourcePolicyFile] ||
    Quiet[Check[Get[resourcePolicyFile]; True, False]] =!= True,
  WriteString["stdout", "KernelPool resource policy could not be loaded\n"];
  Exit[2]];
nativeCoreCapacity = Module[{value = Environment["FACET_NATIVE_CORE_COUNT"]},
  If[StringQ[value] && StringMatchQ[value, DigitCharacter ..] &&
      FromDigits[value] >= 1,
    FromDigits[value], Max[1, nWanted]]];

sub[d_] := FileNameJoin[{poolDir, d}];
Do[If[! DirectoryQ[sub[d]], CreateDirectory[sub[d], CreateIntermediateDirectories -> True]],
  {d, {"queue", "running", "done", "failed", "duplicates", "logs", "control"}}];
Export[sub["pool.pid"], ToString[$ProcessID], "Text"];
log[msg___] := (WriteString["stdout", DateString["ISODateTime"], " POOL ", StringJoin[ToString /@ {msg}], "\n"]);
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
If[! FileExistsQ[FileNameJoin[{sub["control"], "native_cores"}]],
  putAtomic[nativeCoreCapacity,
    FileNameJoin[{sub["control"], "native_cores"}]]];

currentNativeCoreCapacity[] := Module[{file, text, trimmed},
  file = FileNameJoin[{sub["control"], "native_cores"}];
  text = Quiet[Check[Import[file, "Text"], ""]];
  trimmed = If[StringQ[text], StringTrim[text], ""];
  If[StringMatchQ[trimmed, DigitCharacter ..] &&
      FromDigits[trimmed] >= 1,
    FromDigits[trimmed], nativeCoreCapacity]
];

Needs["Parallel`Developer`"];
(* NB: Parallel`Developer` exports the Protected state symbols running/queued/finished -- never use them as variables. *)
Off[OptionValue::optnf];   (* Libra Projector trap; harmless elsewhere *)

(* Launches are TIME-CONSTRAINED: with the license seat shared, LaunchKernels can hang waiting for a
   password ("No valid password found") -- measured 2026-08-16 23:14, it froze the whole loop.  A
   launch that does not return in 90 s is abandoned; the pool keeps serving with fewer kernels and
   retries every relaunchEvery seconds. *)
guardedLaunch[n_Integer] := If[n <= 0, {}, Quiet@TimeConstrained[Check[LaunchKernels[n], {}], 90, {}]];
kernelPids[] := Association[ParallelEvaluate[$KernelID -> $ProcessID]];
launched = guardedLaunch[nWanted];
nk = Length[Kernels[]];
log["requested ", nWanted, " subkernels, running ", nk, " (license/limits decide)"];
If[nk == 0, log["no subkernels; exiting"]; Exit[2]];
(* Orderly close-then-relaunch (2026-08-27, user fix for the seat
   race): after CLOSING a kernel the licence server needs a moment to
   register the returned seat, so the replacement launch waits a short
   grace (not instant, which gets refused) and a refusal retries in
   SECONDS, not the old 300 s hole that left the pool bleeding while
   missions were dispatched into phantom slots.  Only persistent
   refusals (a genuine seat shortage, e.g. the other assistant's
   campaign) fall back to the long interval. *)
relaunchGrace = 4; relaunchRetry = 15; relaunchEvery = 300;
relaunchRefusals = 0; nextRelaunchTry = AbsoluteTime[];

(* per-kernel setup: quiet Libra trap, generous recursion, preload package if asked, and
   trap Exit/Quit so that scripts ending in Exit[code] (TestKit's FTReport) do not kill the
   subkernel: the wrapper catches the throw and records the exit code in the status. *)
(* All per-kernel setup is TARGETED at an explicit kernel list.  ParallelEvaluate on ALL kernels
   blocks until every kernel is free -- measured 2026-08-17 00:08: a successful top-up launch was
   followed by a preload on all kernels, which waited behind four long missions and froze the loop. *)
poolRunFile = FileNameJoin[{poolDir, "poolrun_definition.m"}];
kernelSetup[ks_List] := If[ks =!= {}, ParallelEvaluate[(Off[OptionValue::optnf]; $RecursionLimit = 4096; $HistoryLength = 0;
   Unprotect[Exit, Quit];
   Exit[c_: 0] := Throw[{"EXIT", c}, "KernelPoolExit"];
   Quit[c_: 0] := Throw[{"EXIT", c}, "KernelPoolExit"];
   Protect[Exit, Quit];), ks]];
kernelPreload[ks_List] := If[ks =!= {} && TrueQ[preload],
   ParallelEvaluate[If[Names["FeynFacet`TransportFamily"] === {},
     Quiet[Get["/home/maxzhang/factorization-and-loops/Addon/Load/LoadFACET.wl"], General::shdw]], ks]];
kernelDefs[ks_List] := If[ks =!= {}, With[{f = poolRunFile}, ParallelEvaluate[Get[f], ks]]];
kernelSetup[Kernels[]];
If[TrueQ[preload],
  log["preloading FeynFacet in all subkernels ..."];
  t0 = AbsoluteTime[];
  kernelPreload[Kernels[]];
  log["preload done in ", Round[AbsoluteTime[] - t0], " s"]];

(* the wrapper that runs one mission on a subkernel; ALL output goes to the mission log *)
poolRun[file_String, logFile_String, kernelFile_String] := Module[
  {s, r, t0 = AbsoluteTime[], status, missionText, missionParseContext,
   missionGlobalBefore, missionNewGlobal, missionParsed,
   missionParseFailed, missionParseCleanup, nMsg0, hadMessages},
  (* CLAIM the mission atomically-enough: a mission that was resubmitted after it never
     started (measured 2026-08-17 01:47-01:52: three dispatched evaluations never ran --
     no kernel file, no log, slot counted busy) may later be started by the stale
     ParallelSubmit as well; the first kernel to write the kernel file wins and any
     later starter returns at once without touching the mission. *)
  (* the claim outlives the mission (a tiny file under running/claims/,
     never deleted): when a fresh_* kernel is closed, Parallel Tools may
     re-run its orphaned evaluation elsewhere, and the kernel file alone
     (deleted at finish) no longer stops that late start from rotating
     the finished log into a FILEGONE stub (measured 03:56) *)
  If[FileExistsQ[kernelFile] ||
      FileExistsQ[FileNameJoin[{DirectoryName[kernelFile], "claims", FileNameTake[file]}]],
    Return[<|"Mission" -> FileNameTake[file], "Status" -> "DUPLICATE",
      "Kernel" -> $KernelID, "Wall" -> 0.|>]];
  Quiet[CreateDirectory[FileNameJoin[{DirectoryName[kernelFile], "claims"}]]];
  Export[FileNameJoin[{DirectoryName[kernelFile], "claims", FileNameTake[file]}], ToString[$KernelID], "Text"];
  Export[kernelFile, ToString[$KernelID], "Text"];
  (* APPEND-ONLY LOGS (measured 2026-08-18: a cancel/re-dispatch race re-ran
     mission name sprobe4_CF48 and OpenWrite erased its 2,338 s calculation
     log with a 0-s stub -- evidence behind a recorded decision was lost).
     An existing log is preserved under <name>.log.<timestamp> and a fresh
     log is started; nothing is ever overwritten. *)
  If[FileExistsQ[logFile],
    Module[{dest, k = 0, stamp = DateString[{"Year", "Month", "Day", "-", "Hour", "Minute", "Second"}], ok},
      (* unique destination (timestamp + counter), verified rename; refuse
         to start rather than truncate an unpreserved log (Codex 08:29) *)
      dest = logFile <> "." <> stamp;
      While[FileExistsQ[dest], k++; dest = logFile <> "." <> stamp <> "-" <> ToString[k]];
      ok = Quiet[Check[RenameFile[logFile, dest]; FileExistsQ[dest] && ! FileExistsQ[logFile], False]];
      If[! TrueQ[ok],
        Export[kernelFile <> ".done", "done", "Text"];
        Return[<|"Mission" -> FileNameTake[file], "Status" -> "LOGPRESERVEFAIL",
          "Kernel" -> $KernelID, "Wall" -> 0.|>]]]];
  s = OpenWrite[logFile];
  WriteString[s, "MISSION ", FileNameTake[file], " kernel ", $KernelID, " start ", DateString["ISODateTime"], "\n"];
  status = "OK"; nMsg0 = Length[$MessageList];
  (* WRAPPER PARSE GATE (measured 2026-08-17, three times: fsmoke2, remed_mu, and
     the old fermatprobe): Get on an unparseable file can return Null, so
     the $Failed test below never fires and a wrapper that executed NOTHING
     is filed as OK with wall < 1 s.  Parse the wrapper text first; a mission
     that does not parse is a loud PARSEFAIL, never an OK.  kpsubmit.sh also
     parses the actual Get target under HoldComplete: parsing only this
     generated wrapper does not detect malformed target code. *)
  missionText = Quiet[Import[file, "Text"]];
  If[! StringQ[missionText],
    (* file vanished between dispatch and open (measured 22:45:56: a
       cancellation moved the .wl out of running/ while a stale re-dispatch
       opened it).  Benign; must NOT be labeled PARSEFAIL or the alert
       signal erodes (watchdog, 2026-08-17). *)
    WriteString[s, "MISSION FILE GONE (cancellation/re-dispatch race); nothing was executed\n"];
    WriteString[s, "MISSION end ", DateString["ISODateTime"], " wall 0 s status FILEGONE\n"];
    Close[s];
    Export[kernelFile <> ".done", "done", "Text"];
    Return[<|"Mission" -> FileNameTake[file], "Status" -> "FILEGONE",
      "Kernel" -> $KernelID, "Wall" -> 0.|>]];
  (* HoldComplete prevents evaluation, not symbol interning.  A wrapper
     validation must therefore parse in a disposable context with only
     System` visible.  Also remove any newly interned, explicitly-qualified
     Global` names before the real Get.  This makes the gate namespace-
     neutral even for wrappers not generated by kpsubmit.sh. *)
  missionParseContext = "KernelPoolWrapperParse`c" <>
    StringReplace[CreateUUID[], "-" -> ""] <> "`";
  missionGlobalBefore = System`Names["Global`*"];
  missionParseCleanup := (
    missionParsed =.;
    missionNewGlobal = Complement[
      System`Names["Global`*"], missionGlobalBefore];
    Scan[(Quiet[System`Remove[#]]) &, missionNewGlobal];
    Quiet[System`Remove[missionParseContext <> "*"]]);
  missionParsed = CheckAbort[
    Block[{$Context = missionParseContext, $ContextPath = {"System`"}},
      Quiet[Check[
        ToExpression[missionText, InputForm, HoldComplete], $Failed]]],
    (missionParseCleanup; Abort[])];
  missionParseFailed = missionParsed === $Failed ||
    Head[missionParsed] =!= HoldComplete;
  missionParseCleanup;
  If[TrueQ[missionParseFailed],
    WriteString[s, "MISSION PARSE FAILURE -- script did not parse; nothing was executed\n"];
    WriteString[s, "MISSION end ", DateString["ISODateTime"], " wall 0 s status PARSEFAIL\n"];
    Close[s];
    Export[kernelFile <> ".done", "done", "Text"];
    Return[<|"Mission" -> FileNameTake[file], "Status" -> "PARSEFAIL",
      "Kernel" -> $KernelID, "Wall" -> 0.|>]];
  (* WriteString["stdout", ...] bypasses $Output (measured: the tests' log[] helper vanished into
     pool.log); redirect the "stdout" stream name to the mission log for the mission's duration.
     Status follows the RETURN VALUE / exit code, never the mere presence of messages (measured
     2026-08-16: a Check-based rule filed five completed missions as failed); messages are
     recorded separately as "HadMessages". *)
  r = Block[{$Output = {s}, $Messages = {s}},
    Internal`InheritedBlock[{WriteString},
    Unprotect[WriteString];
    WriteString["stdout", a___] := WriteString[s, a];
    WriteString[OutputStream["stdout", _], a___] := WriteString[s, a];
    Protect[WriteString];
    CheckAbort[
      (* A Return[...] as the FINAL expression of a mission file makes Get
         return a Return VALUE, which unwinds every enclosing Module --
         including poolRun, skipping the MISSION end record and completion
         marker (CF303 V1 capture, Codex handoff 2026-08-23).  Measured on
         14.2 (t_kernelpool_return_marker probes): an anonymous-function
         boundary, Codex's prescribed fix, does NOT stop the value; Replace
         applied directly to Get's result does, and makes the escape typed.
         A Return in mid-file is inert stock semantics (Get continues). *)
      Catch[Replace[Get[file],
        Return[value_] :> {"KernelPoolReturnEscape", value}], "KernelPoolExit"],
      (status = "ABORTED"; $Aborted)]]];
  If[MatchQ[r, {"KernelPoolReturnEscape", _}],
    status = "FAILED"; r = r[[2]]];
  hadMessages = Length[$MessageList] > nMsg0;
  If[MatchQ[r, {"EXIT", _}], status = If[r[[2]] === 0, "OK", "EXIT" <> ToString[r[[2]]]]; r = r[[2]]];
  If[r === $Failed && status === "OK", status = "FAILED"];
  If[r === $Aborted && status === "OK", status = "ABORTED"];
  WriteString[s, "MISSION end ", DateString["ISODateTime"], " wall ", Round[AbsoluteTime[] - t0, 0.1], " s status ", status, "\n"];
  Close[s];
  (* A fresh_* result is also written before the completion marker.  The
     server now drains the EvaluationObject with WaitAll after seeing the
     marker and only then closes the kernel.  The former wrapper blocked
     forever here; closing that live EvaluationObject made Parallel Tools
     requeue an orphan, and after one test wave later missions stayed
     NEVERSTARTED despite idle kernels (reproduced 2026-08-23). *)
  If[StringStartsQ[FileNameTake[file], "fresh_"],
    Put[<|"Mission" -> FileNameTake[file], "Status" -> status, "HadMessages" -> hadMessages,
        "Wall" -> AbsoluteTime[] - t0, "Kernel" -> $KernelID, "Result" -> If[ByteCount[r] < 20000, r, Short[r]]|>,
      kernelFile <> ".result"]];
  Export[kernelFile <> ".done", "done", "Text"];   (* completion marker; the server collects on it *)
  <|"Mission" -> FileNameTake[file], "Status" -> status, "HadMessages" -> hadMessages, "Wall" -> AbsoluteTime[] - t0,
    "Kernel" -> $KernelID, "Result" -> If[ByteCount[r] < 20000, r, Short[r]]|>];
Save[poolRunFile, poolRun];   (* definition file for kernels; avoids DistributeDefinitions on busy kernels *)
kernelDefs[Kernels[]];

pids = kernelPids[];
log["subkernel PIDs: ", pids];
poolJobs = <||>;   (* name -> <|"EID"->eid, "File"->runningFile, "Start"->t|> *)
requeues = <||>;   (* name -> number of KERNELLOST requeues *)
doneCount = 0; failCount = 0;
lastHelperDispatch = <||>;
resourceEpoch = 0;
resourceGroups = {};

missionRecord[file_String] := Module[{text, metadata, date},
  text = Quiet[Check[Import[file, "Text"], ""]];
  metadata = KernelPoolResourcePolicy`KernelPoolResourceMetadata[text];
  date = Quiet[Check[AbsoluteTime[FileDate[file]], 0.]];
  Join[<|"File" -> file, "Date" -> date|>, metadata]
];

activeResourceGroups[] := Sort[DeleteDuplicates[Lookup[
  Select[Values[poolJobs], Function[job,
    AssociationQ[job] && Lookup[job, "Role", None] === "family" &&
      StringQ[Lookup[job, "Group", None]] &&
      Lookup[job, "Group", None] =!= "ungrouped"]], "Group", {}]]];

activeResourceOwners[] := Sort[DeleteDuplicates[Lookup[
  Select[Values[poolJobs], Function[job,
    AssociationQ[job] && Lookup[job, "Role", None] === "family" &&
      StringQ[Lookup[job, "Owner", None]]]], "Owner", {}]]];

runningResourceCounts[role_: All] := Counts[Lookup[
  Select[Values[poolJobs], Function[job,
    AssociationQ[job] && StringQ[Lookup[job, "Group", None]] &&
      Lookup[job, "Group", None] =!= "ungrouped" &&
      (role === All || Lookup[job, "Role", None] === role)]],
  "Group", {}]];

resourceSnapshot[] := Module[{groups, running, coreCapacity},
  groups = activeResourceGroups[];
  If[groups =!= resourceGroups,
    resourceGroups = groups;
    resourceEpoch++];
  running = runningResourceCounts[];
  coreCapacity = currentNativeCoreCapacity[];
  KernelPoolResourcePolicy`KernelPoolResourceAllocate[
    groups, Length[Kernels[]], coreCapacity, running, resourceEpoch]
];

writeResourceAllocations[] := Module[{allocation = resourceSnapshot[]},
  If[AssociationQ[allocation],
    putAtomic[allocation, sub["resource_allocations.wl"]]];
  allocation
];

selectNextMission[records_List] := Module[
  {primary, helper, allocation, runningHelpers, selected,
   activeGroups, activeOwners},
  If[records === {}, Return[Missing["QueueEmpty"]]];
  activeGroups = activeResourceGroups[];
  activeOwners = activeResourceOwners[];
  (* Admit a newly queued family before helper work.  The campaign's
     controller limit bounds family count; the next allocation snapshot then
     shrinks every family's helper/native share before another helper starts. *)
  primary = Select[records,
    Lookup[#1, "Role", "mission"] =!= "helper" &&
      ! (Lookup[#1, "Role", None] === "family" &&
        MemberQ[activeGroups, Lookup[#1, "Group", None]]) &];
  If[primary =!= {}, Return[First[SortBy[primary,
    {Lookup[#1, "Date", 0.] &, Lookup[#1, "File", ""] &}]]]];
  helper = Select[records,
    Lookup[#1, "Role", None] === "helper" &&
      (MemberQ[{None, "ungrouped"}, Lookup[#1, "Owner", None]] ||
        MemberQ[activeOwners, Lookup[#1, "Owner", None]]) &];
  If[helper === {}, Return[Missing["NoEligibleMission"]]];
  allocation = resourceSnapshot[];
  runningHelpers = runningResourceCounts["helper"];
  selected = KernelPoolResourcePolicy`KernelPoolResourceSelectHelper[
    helper, runningHelpers, allocation, lastHelperDispatch];
  If[AssociationQ[selected], Return[selected]];
  (* Legacy ungrouped helpers retain FIFO service.  A grouped helper whose
     family has already left is deliberately not dispatched: it is stale
     work from a cancelled/failed controller, not spare work that another
     family may safely inherit. *)
  helper = Select[helper,
    MemberQ[{None, "ungrouped"}, Lookup[#1, "Group", None]] &];
  If[helper === {}, selected, First[SortBy[helper,
    {Lookup[#1, "Date", 0.] &, Lookup[#1, "File", ""] &}]]]
];

quarantineQueuedOwnerHelpers[owner_String] := Module[
  {records, targets, file, name, destination},
  records = missionRecord /@ FileNames["*.wl", sub["queue"]];
  targets = Select[records,
    Lookup[#1, "Role", None] === "helper" &&
      Lookup[#1, "Owner", None] === owner &];
  Do[
    file = target["File"];
    name = FileBaseName[file];
    destination = FileNameJoin[{sub["failed"], name <> ".wl"}];
    Quiet[RenameFile[file, destination, OverwriteTarget -> True]];
    If[FileExistsQ[destination],
      failCount++;
      putAtomic[<|"Mission" -> name, "Status" -> "OWNERFINISHED",
        "Owner" -> owner,
        "Note" -> "helper was still queued when its controller finished"|>,
        FileNameJoin[{sub["failed"], name <> ".status"}]];
      log["quarantined stale helper ", name, " for owner ", owner]],
    {target, targets}]
];
(* startup recovery: missions left in running/ by a previous (crashed/hung) server *)
Do[Module[{name = FileBaseName[f], lg, ok, dest},
   lg = FileNameJoin[{sub["logs"], name <> ".log"}];
   ok = FileExistsQ[lg] && StringContainsQ[Import[lg, "Text"], "MISSION end" ~~ ___ ~~ "status OK"];
   dest = If[ok, sub["done"], sub["failed"]];
   Quiet@RenameFile[f, FileNameJoin[{dest, name <> ".wl"}], OverwriteTarget -> True];
   putAtomic[<|"Mission" -> name, "Status" -> If[ok, "OK", "POOLRESTART"],
      "Note" -> "recovered at pool start from running/; result record reconstructed from the log"|>,
     FileNameJoin[{dest, name <> ".status"}]];
   Quiet@DeleteFile[FileNameJoin[{sub["running"], name <> ".kernel"}]];
   Quiet@DeleteFile[FileNameJoin[{sub["running"], name <> ".kernel.done"}]];
   log["recovered stale running mission ", name, " -> ", If[ok, "done (log says OK)", "failed (POOLRESTART)"]]],
  {f, FileNames["*.wl", sub["running"]]}];
writeStatus[] := Module[{lines, allocation, resourceLines},
  allocation = writeResourceAllocations[];
  resourceLines = If[AssociationQ[allocation], KeyValueMap[
    Function[{group, grant}, StringJoin["  allocation ", group,
      " helpers<=", ToString[grant["HelperCeiling"]],
      " native=", ToString[grant["NativeCoreQuota"]],
      " workers=", ToString[grant["RunningWorkers"]],
      " threads/worker=", ToString[grant["NativeThreadsPerWorker"]]]],
    Lookup[allocation, "Groups", <||>]], {}];
  lines = Join[
    {"KernelPool status " <> DateString["ISODateTime"],
     "pool dir: " <> poolDir,
     "subkernels: " <> ToString[Length[Kernels[]]] <> "  busy: " <> ToString[Length[poolJobs]] <>
       "  free: " <> ToString[Length[Kernels[]] - Length[poolJobs]],
     "queued: " <> ToString[Length[FileNames["*.wl", sub["queue"]]]] <>
       "  done: " <> ToString[doneCount] <> "  failed: " <> ToString[failCount],
      "active families: " <> ToString[Lookup[allocation,
        "ActiveFamilyCount", 0]] <> "  native cores: " <>
        ToString[Lookup[allocation, "NativeCoreCapacity", nativeCoreCapacity]]}, resourceLines,
    Table["  running " <> k <> " group=" <>
      ToString[Lookup[poolJobs[k], "Group", None]] <> " role=" <>
      ToString[Lookup[poolJobs[k], "Role", "mission"]] <> " owner=" <>
      ToString[Lookup[poolJobs[k], "Owner", None]] <> " elapsed " <>
      ToString[Round[AbsoluteTime[] - poolJobs[k]["Start"]]] <> " s",
      {k, Keys[poolJobs]}]];
  Export[sub["status.txt"], StringRiffle[lines, "\n"] <> "\n", "Text"]];

finish[name_, res_] := Module[{ok, dest, kf, kid, k, job, owner},
  job = Lookup[poolJobs, name, <||>];
  owner = Lookup[job, "Owner", None];
  ok = AssociationQ[res] && res["Status"] === "OK";
  (* a DUPLICATE is the claim mechanism working, not a failure: the
     evaluation found another evaluation's claim on the same mission,
     executed nothing, and the claim OWNER writes the real verdict.
     Filing it under failed/ made passing tests look red (2026-08-27). *)
  dest = Which[ok, sub["done"],
    AssociationQ[res] && res["Status"] === "DUPLICATE", sub["duplicates"],
    True, sub["failed"]];
  Which[ok, doneCount++,
    AssociationQ[res] && res["Status"] === "DUPLICATE", Null,
    True, failCount++];
  (* fresh_* missions (regression tests, 2026-08-22): tests assume a
     clean Global` context, and two of 21 failed on a REUSED subkernel
     while passing standalone -- close the subkernel that ran a fresh_*
     mission; topUpKernels relaunches and preloads it (~40 s) *)
  kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
  If[StringStartsQ[name, "fresh_"] && FileExistsQ[kf],
    kid = Quiet[ToExpression[Import[kf, "Text"]]];
    k = If[IntegerQ[kid], Select[Kernels[], KernelID[#] === kid &], {}];
    If[k =!= {}, Quiet@CloseKernels[k];
      nextRelaunchTry = AbsoluteTime[] + relaunchGrace;
      log["fresh mission ", name, ": subkernel ", kid, " closed for relaunch"]]];
  Quiet@RenameFile[poolJobs[name]["File"], FileNameJoin[{dest, name <> ".wl"}], OverwriteTarget -> True];
  putAtomic[If[AssociationQ[res], res, <|"Mission" -> name, "Status" -> "KERNELLOST", "Result" -> res|>],
    FileNameJoin[{dest, name <> ".status"}]];
  Quiet@DeleteFile[FileNameJoin[{sub["running"], name <> ".kernel"}]];
  Quiet@DeleteFile[FileNameJoin[{sub["running"], name <> ".kernel.done"}]];
  Quiet@DeleteFile[FileNameJoin[{sub["running"], name <> ".kernel.result"}]];
  log["finished ", name, " -> ", If[ok, "done", "failed"], " (", If[AssociationQ[res], Round[res["Wall"], 0.1], "?"], " s)"];
  If[Lookup[job, "Role", None] === "family" && StringQ[owner] &&
      ! (AssociationQ[res] && Lookup[res, "Status", None] === "DUPLICATE"),
    quarantineQueuedOwnerHelpers[owner]];
  poolJobs = KeyDrop[poolJobs, name]];

(* Cancel policy (measured 2026-08-16 23:31): an OS SIGINT to a subkernel does NOT abort its
   evaluation -- the subkernel emits MenuPacket[1, Interrupt] which the Parallel Tools master
   discards -- so cancel = CLOSE the subkernel and relaunch it under the guarded, non-blocking
   launcher (a license draw that may fail; the pool keeps serving with fewer kernels and tops up
   every relaunchEvery seconds).  Cancelling therefore costs a subkernel; owners should cancel
   only what they really do not want. *)
cancelGrace = 0;
neverStartedAfter = 90;   (* s; a dispatched evaluation that has not written its kernel file by then is resubmitted *)
maxResubmits = 3;
interruptKernel[kid_] := Module[{k = Select[Kernels[], KernelID[#] === kid &]},
  If[k =!= {}, Quiet@CloseKernels[k]; log["kernel ", kid, " closed (cancel)"], log["kernel ", kid, " not found"]]];
topUpKernels[] := Module[{missing = nWanted - Length[Kernels[]], got},   (* target the REQUESTED count, not the startup count *)
  If[missing > 0 && AbsoluteTime[] >= nextRelaunchTry,
    got = guardedLaunch[missing];
    If[Length[got] > 0,
      relaunchRefusals = 0;
      nextRelaunchTry = AbsoluteTime[];
      kernelSetup[got]; kernelPreload[got]; kernelDefs[got];
      pids = Join[pids, Association[ParallelEvaluate[$KernelID -> $ProcessID, got]]];
      log["relaunched ", Length[got], " subkernel(s); now ", Length[Kernels[]]],
      relaunchRefusals++;
      nextRelaunchTry = AbsoluteTime[] +
        If[relaunchRefusals >= 4, relaunchEvery,
          relaunchRetry + RandomInteger[{0, 10}]];
      log["relaunch of ", missing, " subkernel(s) failed (license?); ",
        "serving with ", Length[Kernels[]], "; refusal ", relaunchRefusals,
        ", retry in ", Round[nextRelaunchTry - AbsoluteTime[]], " s"]]]];

log["serving; queue=", sub["queue"], "  status=", sub["status.txt"]];
stopping = False;
While[True,
  (* controls *)
  If[FileExistsQ[FileNameJoin[{sub["control"], "stopnow"}]],
    log["stopnow: aborting ", Length[poolJobs], " missions"]; AbortKernels[]; Break[]];
  stopping = FileExistsQ[FileNameJoin[{sub["control"], "stop"}]];   (* drain is reversible: delete control/stop to resume dispatch *)
  Do[Module[{name = StringDrop[FileNameTake[c], -7], kf, kid},
     If[KeyExistsQ[poolJobs, name],
       kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
       kid = If[FileExistsQ[kf], ToExpression[Import[kf, "Text"]], None];
       log["cancel ", name, " on kernel ", kid, " (close + guarded relaunch)"];
       If[IntegerQ[kid], interruptKernel[kid]];
       finish[name, <|"Mission" -> name, "Status" -> "CANCELLED", "Wall" -> AbsoluteTime[] - poolJobs[name]["Start"]|>];
       nextRelaunchTry = AbsoluteTime[] + 20;   (* relaunch ~20 s later: an immediate attempt races the license manager releasing the seat (measured 2026-08-17 00:2x) *),
       log["cancel ", name, ": not running (ignored)"]];
     Quiet@DeleteFile[c]],
    {c, FileNames["*.cancel", sub["control"]]}];
  (* a cancelled mission that has not come back within cancelGrace: close its kernel (guarded relaunch later) *)
  Do[Module[{j = poolJobs[name], kf, kid, k},
     If[KeyExistsQ[j, "CancelledAt"] && AbsoluteTime[] - j["CancelledAt"] > cancelGrace,
       kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
       kid = If[FileExistsQ[kf], ToExpression[Import[kf, "Text"]], None];
       log["cancel ", name, ": kernel ", kid, " did not return within ", cancelGrace, " s; closing it"];
       k = Select[Kernels[], KernelID[#] === kid &]; If[k =!= {}, Quiet@CloseKernels[k]];
       finish[name, <|"Mission" -> name, "Status" -> "CANCELLED", "Wall" -> AbsoluteTime[] - j["Start"]|>]]],
    {name, Keys[poolJobs]}];
  (* collect finished: the wrapper's completion marker is the signal (ProcessState semantics
     proved unreliable across contexts); a mission whose subkernel vanished is reported lost *)
  QueueRun[];
  Do[Module[{eid = poolJobs[name]["EID"], res, kf, kid},
     kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
     Which[
       FileExistsQ[kf <> ".done"],
         (* The marker is written immediately before poolRun returns.
            Drain the EvaluationObject first so CloseKernels cannot leave
            an orphan for the scheduler to requeue.  The sidecar is only
            a crash fallback. *)
         res = Quiet[Check[WaitAll[eid], $Failed]];
         If[! AssociationQ[res] && FileExistsQ[kf <> ".result"],
           res = Quiet[Check[Get[kf <> ".result"], $Failed]]];
         Quiet@DeleteFile[kf <> ".done"]; Quiet@DeleteFile[kf <> ".result"]; finish[name, res],
       FileExistsQ[kf] && (kid = ToExpression[Import[kf, "Text"]]; IntegerQ[kid] && ! MemberQ[KernelID /@ Kernels[], kid]),
         (* the kernel vanished under the mission: REQUEUE it (the log is
            preserved by the append-only rule; a second loss files it) *)
         Module[{n = Lookup[requeues, name, 0]},
           If[n < 2,
             requeues[name] = n + 1;
             log["mission ", name, ": its subkernel ", kid, " is gone; requeued (", n + 1, "/2)"];
             Quiet@RenameFile[poolJobs[name]["File"], FileNameJoin[{sub["queue"], name <> ".wl"}], OverwriteTarget -> True];
             Quiet@DeleteFile[FileNameJoin[{sub["running"], "claims", name <> ".wl"}]];
             Quiet@DeleteFile[kf]; Quiet@DeleteFile[kf <> ".done"]; Quiet@DeleteFile[kf <> ".result"];
             poolJobs = KeyDrop[poolJobs, name],
             log["mission ", name, ": its subkernel ", kid, " is gone (twice); filed KERNELLOST"];
             finish[name, <|"Mission" -> name, "Status" -> "KERNELLOST", "Wall" -> AbsoluteTime[] - poolJobs[name]["Start"]|>]]]]],
    {name, Keys[poolJobs]}];
  (* NEVER-STARTED detection (measured 2026-08-17): a dispatched mission whose evaluation has
     not begun after neverStartedAfter seconds -- no kernel file -- is RESUBMITTED (new
     evaluation, same files; the wrapper's claim check makes a late start of the stale
     evaluation harmless); after maxResubmits it is filed NEVERSTARTED. *)
  Do[Module[{j = poolJobs[name], kf, age, n},
     kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
     age = AbsoluteTime[] - Lookup[j, "LastSubmit", j["Start"]];
     n = Lookup[j, "Resubmits", 0];
     If[! FileExistsQ[kf] && ! FileExistsQ[kf <> ".done"] && age > neverStartedAfter,
       If[n >= maxResubmits,
         log["mission ", name, ": never started after ", n, " resubmits; filed NEVERSTARTED"];
         finish[name, <|"Mission" -> name, "Status" -> "NEVERSTARTED", "Wall" -> AbsoluteTime[] - j["Start"]|>],
         log["mission ", name, ": not started after ", Round[age], " s; resubmitting (", n + 1, "/", maxResubmits, ")"];
         poolJobs[name] = Join[j, <|"EID" -> With[{rf = j["File"], lf = FileNameJoin[{sub["logs"], name <> ".log"}], kf = kf},
             ParallelSubmit[poolRun[rf, lf, kf]]], "LastSubmit" -> AbsoluteTime[], "Resubmits" -> n + 1|>]]]],
    {name, Keys[poolJobs]}];
  (* kernel loss detection: fewer kernels than expected and no cancel in flight *)
  If[Length[Kernels[]] < nWanted && ! stopping, topUpKernels[]];
  (* dispatch *)
  If[! stopping,
    Module[{records, selected, q, name, rf, lf, kf, eid},
      records = missionRecord /@ FileNames["*.wl", sub["queue"]];
      While[Length[poolJobs] < Length[Kernels[]] && records =!= {},
        selected = selectNextMission[records];
        If[! AssociationQ[selected], Break[]];
        q = selected["File"];
        name = FileBaseName[q];
        rf = FileNameJoin[{sub["running"], name <> ".wl"}];
        lf = FileNameJoin[{sub["logs"], name <> ".log"}];
        kf = FileNameJoin[{sub["running"], name <> ".kernel"}];
        (* stale-record hygiene (2026-08-27): a re-run of a mission
           name must not be graded by, or collide with, an earlier
           verdict of the same name *)
        Quiet[DeleteFile[FileNameJoin[{sub["done"], name <> ".status"}]]];
        Quiet[DeleteFile[FileNameJoin[{sub["failed"], name <> ".status"}]]];
        Quiet[DeleteFile[FileNameJoin[{sub["running"], "claims",
          name <> ".wl"}]]];
        RenameFile[q, rf, OverwriteTarget -> True];
        eid = With[{rf = rf, lf = lf, kf = kf},
          ParallelSubmit[poolRun[rf, lf, kf]]];
        poolJobs[name] = Join[<|"EID" -> eid, "File" -> rf,
          "Start" -> AbsoluteTime[]|>,
          KeyTake[selected, {"Group", "Role", "Owner"}]];
        If[selected["Role"] === "helper" &&
            StringQ[selected["Group"]],
          lastHelperDispatch[selected["Group"]] = AbsoluteTime[]];
        records = Select[records, Lookup[#1, "File", None] =!= q &];
        log["dispatched ", name, " group ", selected["Group"],
          " role ", selected["Role"], " (", Length[poolJobs], "/",
          Length[Kernels[]], " busy)"]];
      (* Publish the new family count before QueueRun lets a just-admitted
         mission reach its first resource-sensitive stage. *)
      writeResourceAllocations[]]];
  (* THE PUMP (2026-08-27): ParallelSubmit only queues; without an
     explicit QueueRun the evaluations are handed to subkernels only
     when something else happens to pump the scheduler.  Under fresh_*
     kernel churn that pumping stalled: seven subkernels sat idle on
     their links for minutes while dispatched missions waited in the
     master queue (measured 02:04, all seven in futex wait).  One pump
     per loop pass keeps the queue moving; it is a no-op when empty. *)
  Quiet[Parallel`Developer`QueueRun[]];
  writeStatus[];
  If[stopping && Length[poolJobs] == 0, log["stop: queue drained, shutting down"]; Break[]];
  (* 1 s loop (was 3 s): the task broker's round trip is paid per sample
     batch, measured 2026-08-22 on CF254 (9,7) -- 6 s of a 21 s batch *)
  Pause[1]];
CloseKernels[];
Quiet@DeleteFile[sub["pool.pid"]];
log["exit"];
