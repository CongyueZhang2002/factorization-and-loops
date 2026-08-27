(* A mission target whose FINAL expression is Return[...] must still produce
   the MISSION end record and a typed FAILED status (Codex handoff
   2026-08-23: Get returns the Return VALUE, which unwinds every enclosing
   Module including poolRun; the CF303 V1 capture lost its marker that way).
   Measured 14.2 semantics pinned here too: a Return in MID-file is inert --
   Get continues past it -- so the target deliberately prints after a
   mid-file Return and the test asserts that print HAPPENS.  Live one-shot:
   a 1-subkernel pool, one mission with mid-file + final Return, one control. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
pool = FileNameJoin[{$TemporaryDirectory, "kp_return_test_" <> ToString[$ProcessID]}];
target1 = FileNameJoin[{pool, "target_return.wls"}];
target2 = FileNameJoin[{pool, "target_ok.wls"}];
CreateDirectory[pool, CreateIntermediateDirectories -> True];
Put["placeholder", target1];
Export[target1, "Print[\"before return\"];\nReturn[\"midfile\"];\nPrint[\"after midfile return\"];\nReturn[$Failed]\n", "Text"];
Export[target2, "Print[\"plain ok\"];\n", "Text"];
run[cmd_] := RunProcess[{"/bin/bash", "-c", cmd}];
launch = run["cd " <> root <> " && (taskset -c 10-17 nohup wolframscript -file Scripts/KernelPool.wls " <> pool <> " 1 False > " <> pool <> "/pool.log 2>&1 &) ; for i in $(seq 1 60); do grep -q 'preload done\\|ready' " <> pool <> "/pool.log 2>/dev/null && break; sleep 2; done; grep -c '' " <> pool <> "/pool.log"];
check["pool came up", launch["ExitCode"] === 0];
run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpsubmit.sh ret_probe " <> target1 <> " > /dev/null 2>&1; POOL=" <> pool <> " Scripts/kpsubmit.sh ok_probe " <> target2 <> " > /dev/null 2>&1"];
wait1 = run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpwait.sh ret_probe 300 2>/dev/null | grep -o '\"Status\" -> \"[A-Z0-9]*\"' | head -1"];
wait2 = run["cd " <> root <> " && POOL=" <> pool <> " Scripts/kpwait.sh ok_probe 300 2>/dev/null | grep -o '\"Status\" -> \"[A-Z0-9]*\"' | head -1"];
log1 = Quiet[Check[Import[FileNameJoin[{pool, "logs", "ret_probe.log"}], "Text"], ""]];
log2 = Quiet[Check[Import[FileNameJoin[{pool, "logs", "ok_probe.log"}], "Text"], ""]];
check["Return target: MISSION end record written", StringContainsQ[log1, "MISSION end"]];
check["Return target: typed FAILED status filed", StringContainsQ[wait1["StandardOutput"], "FAILED"] || StringContainsQ[log1, "status FAILED"]];
check["mid-file Return is inert (stock Get semantics)", StringContainsQ[log1, "after midfile return"]];
check["control mission still OK", StringContainsQ[wait2["StandardOutput"], "OK"] && StringContainsQ[log2, "MISSION end"]];
run["touch " <> pool <> "/control/stopnow; sleep 5"];
Print["t_kernelpool_return_marker: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
