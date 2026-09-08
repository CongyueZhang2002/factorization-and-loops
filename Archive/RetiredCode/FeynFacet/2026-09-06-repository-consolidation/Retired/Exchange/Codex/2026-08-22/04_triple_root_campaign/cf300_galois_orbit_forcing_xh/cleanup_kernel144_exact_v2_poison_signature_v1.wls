#!/usr/bin/env wolframscript

(* Narrow, one-use recovery gate for the exact poison left by
   run_hydration_context_poison_model_v2.wls.  No mutation is reachable until
   every definition table, attribute list, and whole-state fingerprint agrees
   with the independently observed read-only kernel-144 state. *)

$HistoryLength = 0;
BeginPackage["CodexCF300Kernel144ExactPoisonCleanupV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300Kernel144ExactPoisonCleanupV1`Private`*"]];
cleanupExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

canonicalPath = {"System`", "Global`"};
definitionComponents = {"OwnValues", "DownValues", "UpValues",
  "SubValues", "NValues", "DefaultValues", "FormatValues",
  "Attributes"};

SetAttributes[definitionSnapshot, HoldFirst];
definitionSnapshot[symbol_Symbol] := <|
  "OwnValues" -> OwnValues[symbol],
  "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol],
  "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol],
  "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
definitionSnapshot[___] := $Failed;

fingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = canonicalPath},
  Hash[ToString[InputForm[value]], "SHA256", "HexString"]];

expectedPoisonStates = <|
  "x" -> <|
    "OwnValues" -> {HoldPattern[Global`x] :> 31337},
    "DownValues" -> {
      HoldPattern[Global`x[
        CodexCF300HydrationContextPoisonModelV2`Private`argument_]] :>
        HoldComplete["x-down",
          CodexCF300HydrationContextPoisonModelV2`Private`argument]},
    "UpValues" -> {
      HoldPattern[
        CodexCF300HydrationContextPoisonModelV2`Private`poisonHeadX[
          Global`x]] :> HoldComplete["x-up"]},
    "SubValues" -> {
      HoldPattern[Global`x[1][2]] :> HoldComplete["x-sub"]},
    "NValues" -> {}, "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, Protected}|>,
  "y" -> <|
    "OwnValues" -> {HoldPattern[Global`y] :> -27183},
    "DownValues" -> {
      HoldPattern[Global`y[
        CodexCF300HydrationContextPoisonModelV2`Private`argument_]] :>
        HoldComplete["y-down",
          CodexCF300HydrationContextPoisonModelV2`Private`argument]},
    "UpValues" -> {
      HoldPattern[
        CodexCF300HydrationContextPoisonModelV2`Private`poisonHeadY[
          Global`y]] :> HoldComplete["y-up"]},
    "SubValues" -> {
      HoldPattern[Global`y[1][2]] :> HoldComplete["y-sub"]},
    "NValues" -> {}, "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, Protected}|>,
  "eps" -> <|
    "OwnValues" -> {HoldPattern[Global`eps] :> 65537},
    "DownValues" -> {
      HoldPattern[Global`eps[
        CodexCF300HydrationContextPoisonModelV2`Private`argument_]] :>
        HoldComplete["eps-down",
          CodexCF300HydrationContextPoisonModelV2`Private`argument]},
    "UpValues" -> {
      HoldPattern[
        CodexCF300HydrationContextPoisonModelV2`Private`poisonHeadEpsilon[
          Global`eps]] :> HoldComplete["eps-up"]},
    "SubValues" -> {
      HoldPattern[Global`eps[1][2]] :> HoldComplete["eps-sub"]},
    "NValues" -> {}, "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, Protected}|>|>;

expectedPoisonFingerprints = <|
  "x" ->
    "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
  "y" ->
    "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
  "eps" ->
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968"|>;

emptyDefinitionState = <|
  "OwnValues" -> {}, "DownValues" -> {}, "UpValues" -> {},
  "SubValues" -> {}, "NValues" -> {}, "DefaultValues" -> {},
  "FormatValues" -> {}, "Attributes" -> {}|>;
expectedCleanStates = <|"x" -> emptyDefinitionState,
  "y" -> emptyDefinitionState, "eps" -> emptyDefinitionState|>;

SetAttributes[restoreDefinitionState, HoldFirst];
restoreDefinitionState[symbol_Symbol, state_Association] := Module[
  {attributes, restored},
  attributes = state["Attributes"];
  Quiet[Check[Unlock[symbol], Null]];
  Quiet[Check[Unprotect[symbol], Null]];
  Quiet[Check[ClearAll[symbol], Null]];
  Quiet[Check[DownValues[symbol] = state["DownValues"], Null]];
  Quiet[Check[UpValues[symbol] = state["UpValues"], Null]];
  Quiet[Check[SubValues[symbol] = state["SubValues"], Null]];
  Quiet[Check[NValues[symbol] = state["NValues"], Null]];
  Quiet[Check[DefaultValues[symbol] = state["DefaultValues"], Null]];
  Quiet[Check[FormatValues[symbol] = state["FormatValues"], Null]];
  Quiet[Check[OwnValues[symbol] = state["OwnValues"], Null]];
  Quiet[Check[
    Attributes[symbol] = DeleteCases[attributes, Locked], Null]];
  If[MemberQ[attributes, Locked], Quiet[Check[Lock[symbol], Null]]];
  restored = definitionSnapshot[symbol];
  SameQ[restored, state]];
restoreDefinitionState[___] := False;

readAllStates[] := <|"x" -> definitionSnapshot[Global`x],
  "y" -> definitionSnapshot[Global`y],
  "eps" -> definitionSnapshot[Global`eps]|>;
stateFingerprints[states_Association] := AssociationMap[
  fingerprint[states[#1]] &, Keys[states]];

driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
preStates = readAllStates[];
preFingerprints = stateFingerprints[preStates];
expectedLiteralFingerprints = stateFingerprints[expectedPoisonStates];
exactTablesAndAttributesMatchQ = SameQ[preStates, expectedPoisonStates];
observedFingerprintsMatchPinQ =
  SameQ[preFingerprints, expectedPoisonFingerprints];
literalFingerprintsMatchPinQ =
  SameQ[expectedLiteralFingerprints, expectedPoisonFingerprints];
signatureMatchQ = TrueQ[exactTablesAndAttributesMatchQ &&
  observedFingerprintsMatchPinQ && literalFingerprintsMatchPinQ];

preflightDiagnostics = <|
  "Status" -> "CF300Kernel144ExactPoisonCleanupV1Preflight",
  "DriverSHA256" -> driverHash,
  "ExactTablesAndAttributesMatchQ" -> exactTablesAndAttributesMatchQ,
  "ObservedFingerprints" -> preFingerprints,
  "ExpectedPinnedFingerprints" -> expectedPoisonFingerprints,
  "ExpectedLiteralFingerprints" -> expectedLiteralFingerprints,
  "ObservedFingerprintsMatchPinQ" -> observedFingerprintsMatchPinQ,
  "LiteralFingerprintsMatchPinQ" -> literalFingerprintsMatchPinQ,
  "CompleteSignatureMatchQ" -> signatureMatchQ|>;
Print["CF300_KERNEL144_POISON_CLEANUP preflight=",
  InputForm[preflightDiagnostics]];

(* Fail closed before any call to a mutating helper. *)
If[! TrueQ[signatureMatchQ],
  Print["CF300_KERNEL144_POISON_CLEANUP FAIL signature mismatch; ",
    "no mutation attempted"];
  cleanupExit[2]];

cleanupTag = "CF300Kernel144ExactPoisonCleanupV1-" <> CreateUUID[];
cleanupCommitted = False;
cleanupAborted = False;
rollbackAttempted = False;
rollbackSucceeded = False;
rollbackResults = Missing["NotAttempted"];
postAttemptStates = Missing["NotAvailable"];
cleanupOutcome = Internal`WithLocalSettings[
  Null,
  CheckAbort[
    Catch[
      Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
      Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
      Quiet[Check[ClearAll[Global`x, Global`y, Global`eps], Null]];
      postAttemptStates = readAllStates[];
      If[! SameQ[postAttemptStates, expectedCleanStates],
        Throw["PostCleanStateMismatch", cleanupTag]];
      cleanupCommitted = True;
      "ExactPoisonRemoved",
      cleanupTag],
    cleanupAborted = True;
    cleanupCommitted = False;
    $Aborted],
  If[! TrueQ[cleanupCommitted],
    rollbackAttempted = True;
    rollbackResults = <|
      "x" -> Quiet[Check[
        restoreDefinitionState[Global`x, preStates["x"]], False]],
      "y" -> Quiet[Check[
        restoreDefinitionState[Global`y, preStates["y"]], False]],
      "eps" -> Quiet[Check[
        restoreDefinitionState[Global`eps, preStates["eps"]], False]]|>;
    rollbackSucceeded = TrueQ[
      And @@ Values[rollbackResults] &&
      SameQ[readAllStates[], preStates]]]];

finalStates = readAllStates[];
postCleanExactQ = SameQ[finalStates, expectedCleanStates];
finalSafeQ = TrueQ[
  (cleanupCommitted && postCleanExactQ && ! rollbackAttempted) ||
  (! cleanupCommitted && rollbackAttempted && rollbackSucceeded &&
    SameQ[finalStates, preStates])];
diagnostics = <|
  "Status" -> "CF300Kernel144ExactPoisonCleanupV1",
  "Preflight" -> preflightDiagnostics,
  "CleanupOutcome" -> cleanupOutcome,
  "CleanupAborted" -> cleanupAborted,
  "CleanupCommitted" -> cleanupCommitted,
  "PostCleanExactQ" -> postCleanExactQ,
  "RollbackAttempted" -> rollbackAttempted,
  "RollbackResults" -> rollbackResults,
  "RollbackSucceeded" -> rollbackSucceeded,
  "FinalStateFingerprints" -> stateFingerprints[finalStates],
  "FinalExactStates" -> finalStates,
  "FinalSafeQ" -> finalSafeQ|>;
Print["CF300_KERNEL144_POISON_CLEANUP diagnostics=",
  InputForm[diagnostics]];
Print["CF300_KERNEL144_POISON_CLEANUP pass=",
  TrueQ[cleanupCommitted && postCleanExactQ && finalSafeQ]];
cleanupExit[If[
  TrueQ[cleanupCommitted && postCleanExactQ && finalSafeQ], 0, 2]];
