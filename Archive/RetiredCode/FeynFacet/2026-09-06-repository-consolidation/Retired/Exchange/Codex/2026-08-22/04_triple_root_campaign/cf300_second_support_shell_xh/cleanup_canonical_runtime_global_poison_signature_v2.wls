#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300CanonicalRuntimeGlobalPoisonCleanupV2`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300CanonicalRuntimeGlobalPoisonCleanupV2`Private`*"]];
cleanupExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

emptyState = <|
  "OwnValues" -> {}, "DownValues" -> {}, "UpValues" -> {},
  "SubValues" -> {}, "NValues" -> {}, "DefaultValues" -> {},
  "FormatValues" -> {}, "Attributes" -> {}|>;
stateX[] := <|
  "OwnValues" -> OwnValues[Global`x],
  "DownValues" -> DownValues[Global`x],
  "UpValues" -> UpValues[Global`x],
  "SubValues" -> SubValues[Global`x],
  "NValues" -> NValues[Global`x],
  "DefaultValues" -> DefaultValues[Global`x],
  "FormatValues" -> FormatValues[Global`x],
  "Attributes" -> Attributes[Global`x]|>;
stateY[] := <|
  "OwnValues" -> OwnValues[Global`y],
  "DownValues" -> DownValues[Global`y],
  "UpValues" -> UpValues[Global`y],
  "SubValues" -> SubValues[Global`y],
  "NValues" -> NValues[Global`y],
  "DefaultValues" -> DefaultValues[Global`y],
  "FormatValues" -> FormatValues[Global`y],
  "Attributes" -> Attributes[Global`y]|>;
stateEpsilon[] := <|
  "OwnValues" -> OwnValues[Global`eps],
  "DownValues" -> DownValues[Global`eps],
  "UpValues" -> UpValues[Global`eps],
  "SubValues" -> SubValues[Global`eps],
  "NValues" -> NValues[Global`eps],
  "DefaultValues" -> DefaultValues[Global`eps],
  "FormatValues" -> FormatValues[Global`eps],
  "Attributes" -> Attributes[Global`eps]|>;
fingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Hash[ToString[InputForm[value]], "SHA256", "HexString"]];

expectedStates = <|
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
          Global`eps]] :>
        HoldComplete["eps-up"]},
    "SubValues" -> {
      HoldPattern[Global`eps[1][2]] :> HoldComplete["eps-sub"]},
    "NValues" -> {}, "DefaultValues" -> {}, "FormatValues" -> {},
    "Attributes" -> {Locked, Protected}|>|>;
expectedStateFingerprints = <|
  "x" -> "7a97decc0a3ba259b09e46ec40dae901d7f7d651e103a94ac503d8ee9452ae54",
  "y" -> "859b06b06037f21a7288b84c2cc7c112e10f7aa1e19accc46c4c1c289b561d4e",
  "eps" ->
    "57576170fe7259321a9ad57a9ebf35f286756cdef99b0700f9edf1ef8ad08968"|>;
expectedComponentFingerprints = <|
  "x" -> <|
    "OwnValues" ->
      "b5324621d678a828547665d829158d6c544f232caabce1ea5c6f7aa980071f71",
    "DownValues" ->
      "36ab877aba2d740b55d7af85b1cf97b4fb4bc9c9f6ac06275ec6f64773356b82",
    "UpValues" ->
      "7feca251d078ddcc77b214395c2299e57383c99a49db7d9b24cc786bdd85cb82",
    "SubValues" ->
      "9aa772e60aa12312996b4903f4de008af2aface04661f83a924b6529a8378484",
    "NValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "DefaultValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "FormatValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "Attributes" ->
      "44ab99c42dc4841d65a4bc624d8d2220e5a43d047f9c5205a2b08c24c8283a5e"|>,
  "y" -> <|
    "OwnValues" ->
      "ebd82965a529a0766885170391b09e745b7af7c0430c1e3323e6d307b5cfb06f",
    "DownValues" ->
      "4409f90693ae2584cd972e56255d0d80b82ee15d89ca83ba7872656ab5e392a2",
    "UpValues" ->
      "fae55cea0250f966231263706546ca5a97f035464d9ea63f06377a531df96fb5",
    "SubValues" ->
      "123dab234ef30b5e63cce9cad4996b8330f75971999695b1e30511bd5d65b3b9",
    "NValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "DefaultValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "FormatValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "Attributes" ->
      "44ab99c42dc4841d65a4bc624d8d2220e5a43d047f9c5205a2b08c24c8283a5e"|>,
  "eps" -> <|
    "OwnValues" ->
      "b1c0413a349cc5e260773d7d82d309cb2f74dee0c085b5372d76121220a0123f",
    "DownValues" ->
      "553cff6ad03679b948178c4c851e08b90f32f62f947678ae73f6205fb6177a0d",
    "UpValues" ->
      "dbdf26eece457d4c49720fbc2df0bd9d8639977af9716f20a01a7881457a4247",
    "SubValues" ->
      "906fd8423e4456404789fcf57b596c309e655bda8fea43e27339488325542ae5",
    "NValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "DefaultValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "FormatValues" ->
      "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "Attributes" ->
      "44ab99c42dc4841d65a4bc624d8d2220e5a43d047f9c5205a2b08c24c8283a5e"|>|>;

neutralizeX[] := Quiet[Check[
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
  SameQ[stateX[], emptyState],
  False]];
neutralizeY[] := Quiet[Check[
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
  SameQ[stateY[], emptyState],
  False]];
neutralizeEpsilon[] := Quiet[Check[
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
  SameQ[stateEpsilon[], emptyState],
  False]];
restoreX[state_Association] := Module[{attributes},
  attributes = state["Attributes"];
  If[! TrueQ[neutralizeX[]], Return[False]];
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
    SameQ[stateX[], state],
    False]]
];
restoreY[state_Association] := Module[{attributes},
  attributes = state["Attributes"];
  If[! TrueQ[neutralizeY[]], Return[False]];
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
    SameQ[stateY[], state],
    False]]
];
restoreEpsilon[state_Association] := Module[{attributes},
  attributes = state["Attributes"];
  If[! TrueQ[neutralizeEpsilon[]], Return[False]];
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
    SameQ[stateEpsilon[], state],
    False]]
];

observedStates = <|"x" -> stateX[], "y" -> stateY[],
  "eps" -> stateEpsilon[]|>;
observedStateFingerprints = AssociationMap[
  fingerprint[observedStates[#1]] &, Keys[observedStates]];
observedComponentFingerprints = AssociationMap[
  Function[symbolName,
    AssociationMap[
      Function[componentName,
        fingerprint[observedStates[symbolName][componentName]]],
      Keys[observedStates[symbolName]]]],
  Keys[observedStates]];
literalSignatureQ = SameQ[observedStates, expectedStates];
stateFingerprintSignatureQ =
  SameQ[observedStateFingerprints, expectedStateFingerprints];
componentFingerprintSignatureQ =
  SameQ[observedComponentFingerprints, expectedComponentFingerprints];
signatureQ = TrueQ[literalSignatureQ && stateFingerprintSignatureQ &&
  componentFingerprintSignatureQ];
mutationAttempted = False;
cleanupResults = <|"x" -> False, "y" -> False, "eps" -> False|>;
rollbackAttempted = False;
rollbackResults = <|"x" -> False, "y" -> False, "eps" -> False|>;

If[signatureQ,
  mutationAttempted = True;
  cleanupResults = <|"x" -> neutralizeX[], "y" -> neutralizeY[],
    "eps" -> neutralizeEpsilon[]|>;
  cleanupQ = TrueQ[And @@ Values[cleanupResults] &&
    SameQ[stateX[], emptyState] && SameQ[stateY[], emptyState] &&
    SameQ[stateEpsilon[], emptyState]];
  If[! cleanupQ,
    rollbackAttempted = True;
    rollbackResults = <|
      "x" -> restoreX[observedStates["x"]],
      "y" -> restoreY[observedStates["y"]],
      "eps" -> restoreEpsilon[observedStates["eps"]]|>;
    rollbackQ = TrueQ[And @@ Values[rollbackResults] &&
      SameQ[stateX[], observedStates["x"]] &&
      SameQ[stateY[], observedStates["y"]] &&
      SameQ[stateEpsilon[], observedStates["eps"]]],
    rollbackQ = True],
  cleanupQ = False;
  rollbackQ = True];
diagnostics = <|
  "Status" -> "CF300CanonicalRuntimeGlobalPoisonCleanupV2",
  "LiteralSignatureQ" -> literalSignatureQ,
  "StateFingerprintSignatureQ" -> stateFingerprintSignatureQ,
  "ComponentFingerprintSignatureQ" -> componentFingerprintSignatureQ,
  "MutationAttempted" -> mutationAttempted,
  "CleanupResults" -> cleanupResults,
  "CleanupQ" -> cleanupQ,
  "RollbackAttempted" -> rollbackAttempted,
  "RollbackResults" -> rollbackResults,
  "RollbackQ" -> rollbackQ,
  "FinalStatesEmptyQ" -> TrueQ[
    SameQ[stateX[], emptyState] && SameQ[stateY[], emptyState] &&
      SameQ[stateEpsilon[], emptyState]]|>;
Print["CF300_CGAR_SIGNATURE_CLEANUP diagnostics=", InputForm[diagnostics]];
cleanupExit[Which[
  ! signatureQ, 2,
  cleanupQ, 0,
  rollbackQ, 3,
  True, 4]];
