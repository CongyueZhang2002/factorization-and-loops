BeginPackage["CodexCanonicalGlobalArtifactRuntimeV1`"];

ClearAll[CGARRun, CGARRequestExit, CGARDefinitionSnapshot,
  CGARDefinitionStateSameQ, CGARRestoreDefinitionState];

CGARRun::usage =
  "CGARRun[body] evaluates body with neutral Global`x/y/eps and a canonical artifact context, catches requested exits and aborts, restores exact definitions and caller context, and returns a fail-closed outcome.";
CGARRequestExit::usage =
  "CGARRequestExit[code] requests an integer mission exit from inside CGARRun without terminating the kernel before cleanup.";
CGARDefinitionSnapshot::usage =
  "CGARDefinitionSnapshot[symbol] returns the definition tables and attributes preserved by CGARRun.";
CGARDefinitionStateSameQ::usage =
  "CGARDefinitionStateSameQ[symbol,state] compares a symbol with an exact CGAR definition snapshot.";
CGARRestoreDefinitionState::usage =
  "CGARRestoreDefinitionState[symbol,state] explicitly restores one exact CGAR definition snapshot and verifies it.";

Begin["`Private`"];

ClearAll["CodexCanonicalGlobalArtifactRuntimeV1`Private`*"];

$cgarFormatVersion = 1;
cgarExitTag = Unique["CGARExitTagV1$"];
cgarExitToken = Unique["CGARExitTokenV1$"];
cgarAbortToken = Unique["CGARAbortTokenV1$"];
cgarUnexpectedThrowToken = Unique["CGARUnexpectedThrowTokenV1$"];

SetAttributes[CGARDefinitionSnapshot, HoldFirst];
CGARDefinitionSnapshot[symbol_Symbol] := <|
  "OwnValues" -> OwnValues[symbol],
  "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol],
  "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol],
  "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
CGARDefinitionSnapshot[___] := $Failed;

SetAttributes[CGARDefinitionStateSameQ, HoldFirst];
CGARDefinitionStateSameQ[symbol_Symbol, state_Association] :=
  SameQ[CGARDefinitionSnapshot[symbol], state];
CGARDefinitionStateSameQ[___] := False;

SetAttributes[cgarNeutralizeDefinition, HoldFirst];
cgarNeutralizeDefinition[symbol_Symbol] := Module[
  {remainingAttributes, changed},
  Quiet[Check[Unlock[symbol], Null]];
  Quiet[Check[Unprotect[symbol], Null]];
  remainingAttributes = Attributes[symbol];
  changed = Quiet[Check[
    If[remainingAttributes =!= {},
      ClearAttributes[symbol, remainingAttributes]];
    OwnValues[symbol] = {};
    DownValues[symbol] = {};
    UpValues[symbol] = {};
    SubValues[symbol] = {};
    NValues[symbol] = {};
    DefaultValues[symbol] = {};
    FormatValues[symbol] = {};
    True,
    False]];
  TrueQ[changed] && SameQ[CGARDefinitionSnapshot[symbol], <|
    "OwnValues" -> {}, "DownValues" -> {}, "UpValues" -> {},
    "SubValues" -> {}, "NValues" -> {}, "DefaultValues" -> {},
    "FormatValues" -> {}, "Attributes" -> {}|>]
];
cgarNeutralizeDefinition[___] := False;

SetAttributes[CGARRestoreDefinitionState, HoldFirst];
CGARRestoreDefinitionState[symbol_Symbol, state_Association] := Module[
  {requiredKeys, attributes, ordinaryAttributes, restored},
  requiredKeys = {"OwnValues", "DownValues", "UpValues", "SubValues",
    "NValues", "DefaultValues", "FormatValues", "Attributes"};
  If[Sort[Keys[state]] =!= Sort[requiredKeys], Return[False]];
  If[! cgarNeutralizeDefinition[symbol], Return[False]];
  attributes = state["Attributes"];
  If[! ListQ[attributes], Return[False]];
  ordinaryAttributes = DeleteCases[attributes, Protected | Locked];
  restored = Quiet[Check[
    DownValues[symbol] = state["DownValues"];
    UpValues[symbol] = state["UpValues"];
    SubValues[symbol] = state["SubValues"];
    NValues[symbol] = state["NValues"];
    DefaultValues[symbol] = state["DefaultValues"];
    FormatValues[symbol] = state["FormatValues"];
    OwnValues[symbol] = state["OwnValues"];
    If[ordinaryAttributes =!= {},
      SetAttributes[symbol, ordinaryAttributes]];
    If[MemberQ[attributes, Protected], Protect[symbol]];
    If[MemberQ[attributes, Locked], Lock[symbol]];
    True,
    False]];
  TrueQ[restored] && CGARDefinitionStateSameQ[symbol, state]
];
CGARRestoreDefinitionState[___] := False;

CGARRequestExit[code_Integer] :=
  Throw[{cgarExitToken, code}, cgarExitTag];
CGARRequestExit[___] := Throw[{cgarExitToken, 99}, cgarExitTag];

SetAttributes[CGARRun, HoldAll];
CGARRun[body_] := Module[
  {callerContext, callerContextPath, canonicalContextPath, snapshots,
   neutralization, neutralizedQ, caught, abortedQ = False,
   unexpectedThrowQ = False, exitRequestedQ, requestedCode,
   restoration, definitionsRestoredQ, contextRestoredQ,
   contextPathRestoredQ, status, code},
  callerContext = $Context;
  callerContextPath = $ContextPath;
  canonicalContextPath = DeleteDuplicates[Join[
    {"System`", "Global`"},
    If[ListQ[callerContextPath], callerContextPath, {}]]];
  snapshots = <|
    "x" -> CGARDefinitionSnapshot[Global`x],
    "y" -> CGARDefinitionSnapshot[Global`y],
    "eps" -> CGARDefinitionSnapshot[Global`eps]|>;
  neutralization = <|
    "x" -> cgarNeutralizeDefinition[Global`x],
    "y" -> cgarNeutralizeDefinition[Global`y],
    "eps" -> cgarNeutralizeDefinition[Global`eps]|>;
  neutralizedQ = TrueQ[And @@ Values[neutralization]];
  caught = If[neutralizedQ,
    CheckAbort[
      Catch[
        Catch[
          Block[{$Context = "Global`",
            $ContextPath = canonicalContextPath}, body],
          cgarExitTag],
        _, Function[{value, tag},
          unexpectedThrowQ = True;
          cgarUnexpectedThrowToken]],
      abortedQ = True;
      cgarAbortToken],
    $Failed];
  restoration = <|
    "x" -> CGARRestoreDefinitionState[Global`x, snapshots["x"]],
    "y" -> CGARRestoreDefinitionState[Global`y, snapshots["y"]],
    "eps" -> CGARRestoreDefinitionState[Global`eps, snapshots["eps"]]|>;
  definitionsRestoredQ = TrueQ[And @@ Values[restoration]];
  contextRestoredQ = SameQ[$Context, callerContext];
  contextPathRestoredQ = SameQ[$ContextPath, callerContextPath];
  exitRequestedQ = MatchQ[caught, {cgarExitToken, _Integer}];
  requestedCode = If[exitRequestedQ, Last[caught], 99];
  status = Which[
    ! neutralizedQ, "CanonicalGlobalArtifactRuntimeNeutralizationFailedV1",
    ! definitionsRestoredQ || ! contextRestoredQ ||
      ! contextPathRestoredQ,
      "CanonicalGlobalArtifactRuntimeRestorationFailedV1",
    abortedQ, "CanonicalGlobalArtifactRuntimeAbortedV1",
    unexpectedThrowQ,
      "CanonicalGlobalArtifactRuntimeUnexpectedThrowV1",
    ! exitRequestedQ,
      "CanonicalGlobalArtifactRuntimeMissingExitRequestV1",
    True, "CanonicalGlobalArtifactRuntimeCompletedV1"];
  code = Which[
    ! neutralizedQ, 63,
    ! definitionsRestoredQ || ! contextRestoredQ ||
      ! contextPathRestoredQ, 99,
    abortedQ || unexpectedThrowQ || ! exitRequestedQ, 99,
    True, requestedCode];
  <|
    "Status" -> status,
    "FormatVersion" -> $cgarFormatVersion,
    "Code" -> code,
    "ExitRequestedQ" -> exitRequestedQ,
    "AbortedQ" -> abortedQ,
    "UnexpectedThrowQ" -> unexpectedThrowQ,
    "Neutralization" -> neutralization,
    "NeutralizedQ" -> neutralizedQ,
    "Restoration" -> restoration,
    "DefinitionsRestoredQ" -> definitionsRestoredQ,
    "ContextRestoredQ" -> contextRestoredQ,
    "ContextPathRestoredQ" -> contextPathRestoredQ|>
];
CGARRun[___] := <|
  "Status" -> "CanonicalGlobalArtifactRuntimeInvalidCallV1",
  "FormatVersion" -> $cgarFormatVersion,
  "Code" -> 99,
  "DefinitionsRestoredQ" -> False,
  "ContextRestoredQ" -> False,
  "ContextPathRestoredQ" -> False|>;

End[];
EndPackage[];
