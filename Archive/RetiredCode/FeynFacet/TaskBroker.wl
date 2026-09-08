(* TaskBroker.wl: nothing retained here. taskBrokerCanonicaLadder was
   moved back into Private/Infrastructure/TaskBroker.wl on 2026-09-02 06:08
   because Tests/Infrastructure/t_task_broker_limit.wls uses it directly. *)

(* ==== moved from Private/TaskBroker.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: CANONICA ladder farming (user decision N3, 2026-09-02); t_task_broker_limit retired with it
   Symbols: taskBrokerCanonicaLadder, taskBrokerCanonicaTask
   This file is never loaded by FeynFacet.m. *)


(* ---- CANONICA numerator-degree ladder ---- *)

taskBrokerCanonicaTask[stripFile_String, denominatorDegree_Integer, timeLimit_, degree_Integer] :=
 Module[{data = taskBrokerRead[stripFile]},
  epsFormStripRunCanonicaOne[data["Strip"], data["Variables"], data["Regulator"],
    data["Alphabet"], denominatorDegree, timeLimit, degree]];

(* Restored 2026-09-02 06:08 from Private_Backup: the reachability scan
   counted only package callers (SolveEpsFormStrip, retired), but
   Tests/Infrastructure/t_task_broker_limit.wls drives this helper directly
   and its collaborators (epsFormStripRunCanonicaOne, taskBrokerCanonicaTask)
   are live; it stays as the generic farmed-ladder helper. *)
(* mission side: degree 0 locally (the usual success, too cheap to farm),
   then farm only the prefix permitted by the helper ceiling while this
   kernel evaluates the overflow locally.  Preserve the serial ladder's
   deterministic degree order and result shape. *)
taskBrokerCanonicaLadder[strip_List, variables_List, epsilon_Symbol, alphabet_List,
    degrees_List, denominatorDegree_Integer, timeLimit_] :=
 Module[{first, rest, results = {}, stripFile, helperCount, farmedDegrees,
   localDegrees, codes, handle, farmed, local},
  first = First[degrees]; rest = Rest[degrees];
  AppendTo[results, epsFormStripRunCanonicaOne[strip, variables, epsilon, alphabet,
    denominatorDegree, timeLimit, first]];
  If[TrueQ[Lookup[Last[results], "ExactDLog", False]] || rest === {}, Return[results]];
  helperCount = Min[taskBrokerFreeKernels[], Length[rest]];
  farmedDegrees = Take[rest, helperCount];
  localDegrees = Drop[rest, helperCount];
  If[farmedDegrees === {},
    Return[Join[results,
      (epsFormStripRunCanonicaOne[strip, variables, epsilon, alphabet,
        denominatorDegree, timeLimit, #] &) /@ localDegrees]]];
  stripFile = taskBrokerDataFile["strip_" <> Hash[{strip, variables, epsilon, alphabet}, "SHA256", "HexString"],
    <|"Strip" -> strip, "Variables" -> variables, "Regulator" -> epsilon, "Alphabet" -> alphabet|>];
  codes = StringJoin["FeynFacet`Private`taskBrokerCanonicaTask[\"", stripFile, "\", ",
    ToString[denominatorDegree], ", ", ToString[timeLimit, InputForm], ", ", ToString[#], "]"] & /@ farmedDegrees;
  handle = taskBrokerSubmit[codes, "Timeout" -> timeLimit + 300,
    "Label" -> "canonica"];
  local = (epsFormStripRunCanonicaOne[strip, variables, epsilon, alphabet,
      denominatorDegree, timeLimit, #] &) /@ localDegrees;
  farmed = taskBrokerCollect[handle];
  Join[results, MapThread[Function[{degree, r},
    If[AssociationQ[r], r,
      epsFormStripRunCanonicaOne[strip, variables, epsilon, alphabet, denominatorDegree, timeLimit, degree]]],
    {farmedDegrees, farmed}], local]];
