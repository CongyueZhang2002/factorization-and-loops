(* Regression test for the pool's DUPLICATE-verdict defect (overhaul
   2026-09-02, bug B2 of Design/PrivateOverhaul_2026-09-01.md).

   Failure mode: a mission's kernel is closed right after the scheduler
   handed it the evaluation; Parallel Tools re-runs the orphaned
   evaluation elsewhere, that re-run claims the mission and finishes
   (writing the result sidecar and the completion marker), and the
   server's own re-dispatch returns DUPLICATE from the claim check.  The
   server drained ITS evaluation object, saw DUPLICATE, and filed the
   mission under duplicates/ with Wall 0 -- a passing 261 s test vanished
   from done/ (baseline batch attempt 1, 03:16-03:21).

   Deterministic reproduction: the state the resurrected run leaves
   behind is placed by hand BEFORE the mission is dispatched -- a claim
   file, an OK result sidecar and the completion marker for the mission
   name.  The server dispatches the mission, its wrapper finds the claim
   and returns DUPLICATE, the server sees the marker and drains the
   DUPLICATE.  Acceptance criterion: the mission is filed under done/
   with the sidecar's Status OK and Wall, and nothing is filed under
   duplicates/.  The pre-fix server files a DUPLICATE record instead.
   Live one-shot: a 1-subkernel pool, one prepared mission, one control. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
pool = FileNameJoin[{$TemporaryDirectory, "kp_duplicate_test_" <> ToString[$ProcessID]}];
target = FileNameJoin[{pool, "target_ok.wls"}];
CreateDirectory[FileNameJoin[{pool, "running", "claims"}], CreateIntermediateDirectories -> True];
Export[target, "Print[\"plain ok\"];\n", "Text"];
run[cmd_] := RunProcess[{"/bin/bash", "-c", cmd}];
launch = run["cd " <> root <> " && (taskset -c 10-17 nohup wolframscript -file Scripts/KernelPool.wls " <> pool <> " 1 False > " <> pool <> "/pool.log 2>&1 &) ; for i in $(seq 1 60); do grep -q 'serving; queue=' " <> pool <> "/pool.log 2>/dev/null && exit 0; sleep 2; done; exit 1"];
check["pool came up", launch["ExitCode"] === 0];
(* the resurrected run's leftovers for mission dup_probe: claim, OK sidecar, marker *)
kernelFile = FileNameJoin[{pool, "running", "dup_probe.kernel"}];
Export[FileNameJoin[{pool, "running", "claims", "dup_probe.wl"}], "999", "Text"];
Put[<|"Mission" -> "dup_probe.wl", "Status" -> "OK", "HadMessages" -> False,
    "Wall" -> 261.7, "Kernel" -> 999, "Result" -> 0|>, kernelFile <> ".result"];
Export[kernelFile <> ".done", "done", "Text"];
run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpsubmit.sh dup_probe " <> target <> " > /dev/null 2>&1; POOL=" <> pool <> " Scripts/kpsubmit.sh ctl_probe " <> target <> " > /dev/null 2>&1"];
wait1 = run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpwait.sh dup_probe 300 2>/dev/null"];
wait2 = run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpwait.sh ctl_probe 300 2>/dev/null"];
doneStatus = Quiet[Check[Get[FileNameJoin[{pool, "done", "dup_probe.status"}]], $Failed]];
duplicates = FileNames["*", FileNameJoin[{pool, "duplicates"}]];
check["mission filed under done/ with the sidecar's OK verdict",
  AssociationQ[doneStatus] && doneStatus["Status"] === "OK" && doneStatus["Wall"] == 261.7];
check["nothing filed under duplicates/", duplicates === {}];
check["control mission still OK", StringContainsQ[wait2["StandardOutput"], "\"Status\" -> \"OK\""]];
run["touch " <> pool <> "/control/stopnow; sleep 5"];
Print["t_kernelpool_duplicate_verdict: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
