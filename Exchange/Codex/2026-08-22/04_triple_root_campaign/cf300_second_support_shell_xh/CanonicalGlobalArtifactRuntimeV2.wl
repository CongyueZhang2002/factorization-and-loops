BeginPackage["CodexCanonicalGlobalArtifactRuntimeV2`"];

ClearAll[CGARRun, CGARRequestExit, CGARDefinitionSnapshot,
  CGARDefinitionStateSameQ, CGARRestoreDefinitionState];

CGARRun::usage =
  "CGARRun[body] evaluates body with neutral Global`x/y/eps and a canonical artifact context, catches requested exits and aborts, restores exact definitions and caller context, and returns a fail-closed outcome.";
CGARRequestExit::usage =
  "CGARRequestExit[code] requests an integer mission exit from inside CGARRun without terminating the kernel before cleanup.";
CGARDefinitionSnapshot::usage =
  "CGARDefinitionSnapshot[name] returns the definition tables and attributes preserved by CGARRun for name x, y or eps.";
CGARDefinitionStateSameQ::usage =
  "CGARDefinitionStateSameQ[name,state] compares x, y or eps with an exact CGAR definition snapshot.";
CGARRestoreDefinitionState::usage =
  "CGARRestoreDefinitionState[name,state] explicitly restores one exact x, y or eps snapshot and verifies it.";

Begin["`Private`"];

ClearAll["CodexCanonicalGlobalArtifactRuntimeV2`Private`*"];

$cgarFormatVersion = 2;
cgarExitTag = Unique["CGARExitTagV2$"];
cgarExitToken = Unique["CGARExitTokenV2$"];
cgarAbortToken = Unique["CGARAbortTokenV2$"];
cgarUnexpectedThrowToken = Unique["CGARUnexpectedThrowTokenV2$"];

$cgarRequiredStateKeys = {"OwnValues", "DownValues", "UpValues",
  "SubValues", "NValues", "DefaultValues", "FormatValues",
  "Attributes"};
$cgarEmptyState = <|
  "OwnValues" -> {}, "DownValues" -> {}, "UpValues" -> {},
  "SubValues" -> {}, "NValues" -> {}, "DefaultValues" -> {},
  "FormatValues" -> {}, "Attributes" -> {}|>;
cgarStateX[] := <|
  "OwnValues" -> OwnValues[Global`x],
  "DownValues" -> DownValues[Global`x],
  "UpValues" -> UpValues[Global`x],
  "SubValues" -> SubValues[Global`x],
  "NValues" -> NValues[Global`x],
  "DefaultValues" -> DefaultValues[Global`x],
  "FormatValues" -> FormatValues[Global`x],
  "Attributes" -> Attributes[Global`x]|>;
cgarStateY[] := <|
  "OwnValues" -> OwnValues[Global`y],
  "DownValues" -> DownValues[Global`y],
  "UpValues" -> UpValues[Global`y],
  "SubValues" -> SubValues[Global`y],
  "NValues" -> NValues[Global`y],
  "DefaultValues" -> DefaultValues[Global`y],
  "FormatValues" -> FormatValues[Global`y],
  "Attributes" -> Attributes[Global`y]|>;
cgarStateEpsilon[] := <|
  "OwnValues" -> OwnValues[Global`eps],
  "DownValues" -> DownValues[Global`eps],
  "UpValues" -> UpValues[Global`eps],
  "SubValues" -> SubValues[Global`eps],
  "NValues" -> NValues[Global`eps],
  "DefaultValues" -> DefaultValues[Global`eps],
  "FormatValues" -> FormatValues[Global`eps],
  "Attributes" -> Attributes[Global`eps]|>;
CGARDefinitionSnapshot["x"] := cgarStateX[];
CGARDefinitionSnapshot["y"] := cgarStateY[];
CGARDefinitionSnapshot["eps"] := cgarStateEpsilon[];
CGARDefinitionSnapshot[___] := $Failed;
CGARDefinitionStateSameQ[name_String, state_Association] :=
  SameQ[CGARDefinitionSnapshot[name], state];
CGARDefinitionStateSameQ[___] := False;

cgarNeutralizeX[] := Quiet[Check[
  Unlock[Global`x];
  Unprotect[Global`x];
  Attributes[Global`x] = {};
  OwnValues[Global`x] = {};
  DownValues[Global`x] = {};
  UpValues[Global`x] = {};
  SubValues[Global`x] = {};
  NValues[Global`x] = {};
  DefaultValues[Global`x] = {};
  FormatValues[Global`x] = {};
  SameQ[cgarStateX[], $cgarEmptyState],
  False]];
cgarNeutralizeY[] := Quiet[Check[
  Unlock[Global`y];
  Unprotect[Global`y];
  Attributes[Global`y] = {};
  OwnValues[Global`y] = {};
  DownValues[Global`y] = {};
  UpValues[Global`y] = {};
  SubValues[Global`y] = {};
  NValues[Global`y] = {};
  DefaultValues[Global`y] = {};
  FormatValues[Global`y] = {};
  SameQ[cgarStateY[], $cgarEmptyState],
  False]];
cgarNeutralizeEpsilon[] := Quiet[Check[
  Unlock[Global`eps];
  Unprotect[Global`eps];
  Attributes[Global`eps] = {};
  OwnValues[Global`eps] = {};
  DownValues[Global`eps] = {};
  UpValues[Global`eps] = {};
  SubValues[Global`eps] = {};
  NValues[Global`eps] = {};
  DefaultValues[Global`eps] = {};
  FormatValues[Global`eps] = {};
  SameQ[cgarStateEpsilon[], $cgarEmptyState],
  False]];
cgarNeutralizeNamed["x"] := cgarNeutralizeX[];
cgarNeutralizeNamed["y"] := cgarNeutralizeY[];
cgarNeutralizeNamed["eps"] := cgarNeutralizeEpsilon[];
cgarNeutralizeNamed[___] := False;

cgarValidStateQ[state_Association] := TrueQ[
  Sort[Keys[state]] === Sort[$cgarRequiredStateKeys] &&
  ListQ[state["Attributes"]]];
cgarValidStateQ[___] := False;
cgarRestoreX[state_Association] := Module[{attributes},
  If[! cgarValidStateQ[state], Return[False]];
  attributes = state["Attributes"];
  If[! TrueQ[cgarNeutralizeX[]], Return[False]];
  Quiet[Check[
    DownValues[Global`x] = state["DownValues"];
    UpValues[Global`x] = state["UpValues"];
    SubValues[Global`x] = state["SubValues"];
    NValues[Global`x] = state["NValues"];
    DefaultValues[Global`x] = state["DefaultValues"];
    FormatValues[Global`x] = state["FormatValues"];
    OwnValues[Global`x] = state["OwnValues"];
    Attributes[Global`x] = DeleteCases[attributes, Locked];
    If[MemberQ[attributes, Locked], Lock[Global`x]];
    SameQ[cgarStateX[], state],
    False]]
];
cgarRestoreY[state_Association] := Module[{attributes},
  If[! cgarValidStateQ[state], Return[False]];
  attributes = state["Attributes"];
  If[! TrueQ[cgarNeutralizeY[]], Return[False]];
  Quiet[Check[
    DownValues[Global`y] = state["DownValues"];
    UpValues[Global`y] = state["UpValues"];
    SubValues[Global`y] = state["SubValues"];
    NValues[Global`y] = state["NValues"];
    DefaultValues[Global`y] = state["DefaultValues"];
    FormatValues[Global`y] = state["FormatValues"];
    OwnValues[Global`y] = state["OwnValues"];
    Attributes[Global`y] = DeleteCases[attributes, Locked];
    If[MemberQ[attributes, Locked], Lock[Global`y]];
    SameQ[cgarStateY[], state],
    False]]
];
cgarRestoreEpsilon[state_Association] := Module[{attributes},
  If[! cgarValidStateQ[state], Return[False]];
  attributes = state["Attributes"];
  If[! TrueQ[cgarNeutralizeEpsilon[]], Return[False]];
  Quiet[Check[
    DownValues[Global`eps] = state["DownValues"];
    UpValues[Global`eps] = state["UpValues"];
    SubValues[Global`eps] = state["SubValues"];
    NValues[Global`eps] = state["NValues"];
    DefaultValues[Global`eps] = state["DefaultValues"];
    FormatValues[Global`eps] = state["FormatValues"];
    OwnValues[Global`eps] = state["OwnValues"];
    Attributes[Global`eps] = DeleteCases[attributes, Locked];
    If[MemberQ[attributes, Locked], Lock[Global`eps]];
    SameQ[cgarStateEpsilon[], state],
    False]]
];
CGARRestoreDefinitionState["x", state_Association] :=
  cgarRestoreX[state];
CGARRestoreDefinitionState["y", state_Association] :=
  cgarRestoreY[state];
CGARRestoreDefinitionState["eps", state_Association] :=
  cgarRestoreEpsilon[state];
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
    "x" -> CGARDefinitionSnapshot["x"],
    "y" -> CGARDefinitionSnapshot["y"],
    "eps" -> CGARDefinitionSnapshot["eps"]|>;
  neutralization = <|
    "x" -> cgarNeutralizeNamed["x"],
    "y" -> cgarNeutralizeNamed["y"],
    "eps" -> cgarNeutralizeNamed["eps"]|>;
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
    "x" -> CGARRestoreDefinitionState["x", snapshots["x"]],
    "y" -> CGARRestoreDefinitionState["y", snapshots["y"]],
    "eps" -> CGARRestoreDefinitionState["eps", snapshots["eps"]]|>;
  definitionsRestoredQ = TrueQ[And @@ Values[restoration]];
  contextRestoredQ = SameQ[$Context, callerContext];
  contextPathRestoredQ = SameQ[$ContextPath, callerContextPath];
  exitRequestedQ = MatchQ[caught, {cgarExitToken, _Integer}];
  requestedCode = If[exitRequestedQ, Last[caught], 99];
  status = Which[
    ! neutralizedQ, "CanonicalGlobalArtifactRuntimeNeutralizationFailedV2",
    ! definitionsRestoredQ || ! contextRestoredQ ||
      ! contextPathRestoredQ,
      "CanonicalGlobalArtifactRuntimeRestorationFailedV2",
    abortedQ, "CanonicalGlobalArtifactRuntimeAbortedV2",
    unexpectedThrowQ,
      "CanonicalGlobalArtifactRuntimeUnexpectedThrowV2",
    ! exitRequestedQ,
      "CanonicalGlobalArtifactRuntimeMissingExitRequestV2",
    True, "CanonicalGlobalArtifactRuntimeCompletedV2"];
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
  "Status" -> "CanonicalGlobalArtifactRuntimeInvalidCallV2",
  "FormatVersion" -> $cgarFormatVersion,
  "Code" -> 99,
  "DefinitionsRestoredQ" -> False,
  "ContextRestoredQ" -> False,
  "ContextPathRestoredQ" -> False|>;

End[];
EndPackage[];
