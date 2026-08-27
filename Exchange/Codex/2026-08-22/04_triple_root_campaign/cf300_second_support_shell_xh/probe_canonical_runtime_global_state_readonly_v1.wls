#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300CanonicalRuntimeGlobalStateReadOnlyProbeV1`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300CanonicalRuntimeGlobalStateReadOnlyProbeV1`Private`*"]];
probeExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

fingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Hash[ToString[InputForm[value]], "SHA256", "HexString"]];
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
stateSummary[state_Association] := <|
  "ComponentCounts" -> AssociationMap[Length[state[#1]] &,
    Keys[state]],
  "Attributes" -> state["Attributes"],
  "ProtectedQ" -> MemberQ[state["Attributes"], Protected],
  "LockedQ" -> MemberQ[state["Attributes"], Locked],
  "ComponentFingerprints" -> AssociationMap[fingerprint[state[#1]] &,
    Keys[state]],
  "StateFingerprint" -> fingerprint[state]|>;

callerContext = $Context;
callerContextPath = $ContextPath;
firstStates = <|"x" -> stateX[], "y" -> stateY[],
  "eps" -> stateEpsilon[]|>;
secondStates = <|"x" -> stateX[], "y" -> stateY[],
  "eps" -> stateEpsilon[]|>;
diagnostics = <|
  "Status" -> "CF300CanonicalRuntimeGlobalStateReadOnlyProbeV1",
  "StrictlyReadOnlyGlobalSymbols" -> {"Global`x", "Global`y",
    "Global`eps"},
  "CallerContext" -> callerContext,
  "CallerContextPath" -> callerContextPath,
  "StatesStableAcrossTwoReadsQ" -> SameQ[firstStates, secondStates],
  "StateSummaries" -> AssociationMap[stateSummary[firstStates[#1]] &,
    Keys[firstStates]],
  "ExactStates" -> firstStates|>;
Print["CF300_CGAR_READONLY_STATE diagnostics=", InputForm[diagnostics]];
probeExit[If[diagnostics["StatesStableAcrossTwoReadsQ"], 0, 2]];
