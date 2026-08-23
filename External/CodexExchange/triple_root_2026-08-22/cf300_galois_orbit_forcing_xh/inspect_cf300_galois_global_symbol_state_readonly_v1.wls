#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300GlobalSymbolStateReadOnlyProbeV1`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300GlobalSymbolStateReadOnlyProbeV1`Private`*"]];

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

stateFingerprint[state_Association] :=
  Hash[state, "SHA256", "HexString"];
stateFingerprint[___] := $Failed;
componentFingerprints[state_Association] := AssociationMap[
  Hash[state[#1], "SHA256", "HexString"] &,
  Keys[state]];
componentFingerprints[___] := $Failed;

callerContextBefore = $Context;
callerContextPathBefore = $ContextPath;
driverHash = FileHash[$InputFileName, "SHA256", "HexString"];
statesBefore = <|
  "Global`x" -> definitionSnapshot[Global`x],
  "Global`y" -> definitionSnapshot[Global`y],
  "Global`eps" -> definitionSnapshot[Global`eps]|>;
statesAfter = <|
  "Global`x" -> definitionSnapshot[Global`x],
  "Global`y" -> definitionSnapshot[Global`y],
  "Global`eps" -> definitionSnapshot[Global`eps]|>;
callerContextAfter = $Context;
callerContextPathAfter = $ContextPath;

diagnostics = <|
  "Status" -> "CF300GlobalSymbolStateReadOnlyProbeV1",
  "DriverSHA256" -> driverHash,
  "ReadOnlySameQ" -> SameQ[statesBefore, statesAfter],
  "CallerContextBefore" -> callerContextBefore,
  "CallerContextAfter" -> callerContextAfter,
  "CallerContextSameQ" -> SameQ[callerContextBefore,
    callerContextAfter],
  "CallerContextPathBefore" -> callerContextPathBefore,
  "CallerContextPathAfter" -> callerContextPathAfter,
  "CallerContextPathSameQ" -> SameQ[callerContextPathBefore,
    callerContextPathAfter],
  "ExactDefinitionStates" -> statesBefore,
  "StateFingerprints" -> AssociationMap[
    stateFingerprint[statesBefore[#1]] &, Keys[statesBefore]],
  "ComponentFingerprints" -> AssociationMap[
    componentFingerprints[statesBefore[#1]] &, Keys[statesBefore]]|>;

passed = TrueQ[
  diagnostics["ReadOnlySameQ"] &&
  diagnostics["CallerContextSameQ"] &&
  diagnostics["CallerContextPathSameQ"] &&
  FreeQ[Values[diagnostics["ExactDefinitionStates"]], $Failed]];
Print["CF300_GLOBAL_STATE_READONLY diagnostics=",
  InputForm[diagnostics]];
Print["CF300_GLOBAL_STATE_READONLY pass=", passed];
finalCode = If[passed, 0, 2];
End[];
EndPackage[];
System`Exit[finalCode];
