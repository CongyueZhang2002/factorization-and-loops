
(* ==== moved from Private/TaskBroker.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: broker task of the CANONICA degree ladder; its only caller SolveEpsFormStrip moved to Private_Backup/EpsFormStrip.wl
   Symbols: taskBrokerCanonicaLadder
   This file is never loaded by FeynFacet.m. *)


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
