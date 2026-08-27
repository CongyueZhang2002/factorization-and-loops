(* Read-only/no-op diagnostic for the live KernelPool worker contract.
   It evaluates DownValues before converting them to text.  It neither calls
   the intercepted control functions nor writes an artifact. *)

Module[
  {poolRunValues, exitValues, quitValues, poolRunText, exitText, quitText,
   formerHeldText, result},
  poolRunValues = DownValues[Global`poolRun];
  exitValues = DownValues[System`Exit];
  quitValues = DownValues[System`Quit];
  poolRunText = ToString[poolRunValues, InputForm];
  exitText = ToString[exitValues, InputForm];
  quitText = ToString[quitValues, InputForm];
  formerHeldText =
    ToString[HoldComplete[DownValues[Global`poolRun]], InputForm];
  result = <|
    "Status" -> "CF303PoolExitContractNoOpProbe",
    "KernelID" -> $KernelID,
    "ProcessID" -> $ProcessID,
    "Context" -> $Context,
    "ContextPath" -> $ContextPath,
    "PoolRunDownValueCount" -> Length[poolRunValues],
    "ExitDownValueCount" -> Length[exitValues],
    "QuitDownValueCount" -> Length[quitValues],
    "PoolRunHasKernelPoolExit" ->
      StringContainsQ[poolRunText, "KernelPoolExit"],
    "PoolRunHasMissionEnd" ->
      StringContainsQ[poolRunText, "MISSION end"],
    "PoolRunHasDoneMarker" -> StringContainsQ[poolRunText, ".done"],
    "ExitHasKernelPoolExit" ->
      StringContainsQ[exitText, "KernelPoolExit"],
    "QuitHasKernelPoolExit" ->
      StringContainsQ[quitText, "KernelPoolExit"],
    "FormerHeldExpressionEvaluated" ->
      StringContainsQ[formerHeldText, "MISSION end"],
    "FormerHeldExpressionText" -> formerHeldText|>;
  Print["CF303 POOL EXIT CONTRACT NO-OP PROBE: ", result];
  result
]
