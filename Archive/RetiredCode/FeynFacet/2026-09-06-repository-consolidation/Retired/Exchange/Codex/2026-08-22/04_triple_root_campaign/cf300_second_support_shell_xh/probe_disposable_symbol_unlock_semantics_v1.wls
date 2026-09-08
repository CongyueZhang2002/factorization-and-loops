#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300DisposableSymbolUnlockSemanticsProbeV1`"];
probePackageSymbolV1::usage = "Disposable package-context probe symbol.";
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300DisposableSymbolUnlockSemanticsProbeV1`Private`*"]];
probeExit[code_Integer] :=
  (End[]; EndPackage[]; System`Exit[code]);

SetAttributes[definitionState, HoldFirst];
definitionState[symbol_] := <|
  "OwnValues" -> OwnValues[symbol],
  "DownValues" -> DownValues[symbol],
  "UpValues" -> UpValues[symbol],
  "SubValues" -> SubValues[symbol],
  "NValues" -> NValues[symbol],
  "DefaultValues" -> DefaultValues[symbol],
  "FormatValues" -> FormatValues[symbol],
  "Attributes" -> Attributes[symbol]|>;
fingerprint[value_] := Block[
  {$Context = "Global`", $ContextPath = {"System`", "Global`"}},
  Hash[ToString[InputForm[value]], "SHA256", "HexString"]];
SetAttributes[capture, HoldAll];
capture[expression_] := Module[{result, messages},
  Block[{$MessageList = {}},
    result = Quiet[Check[expression, $Failed]];
    messages = $MessageList];
  <|"Result" -> ToString[InputForm[result]],
    "Messages" -> ToString[InputForm[messages]]|>
];
SetAttributes[heldNeutralize, HoldFirst];
heldNeutralize[symbol_Symbol] := Module[
  {unlock, unprotect, clearAttributes, clearOwn, clearDown, clearUp,
   clearSub, clearN, clearDefault, clearFormat, finalState},
  unlock = capture[Unlock[symbol]];
  unprotect = capture[Unprotect[symbol]];
  clearAttributes = capture[Attributes[symbol] = {}];
  clearOwn = capture[OwnValues[symbol] = {}];
  clearDown = capture[DownValues[symbol] = {}];
  clearUp = capture[UpValues[symbol] = {}];
  clearSub = capture[SubValues[symbol] = {}];
  clearN = capture[NValues[symbol] = {}];
  clearDefault = capture[DefaultValues[symbol] = {}];
  clearFormat = capture[FormatValues[symbol] = {}];
  finalState = definitionState[symbol];
  <|"Unlock" -> unlock, "Unprotect" -> unprotect,
    "ClearAttributes" -> clearAttributes, "ClearOwn" -> clearOwn,
    "ClearDown" -> clearDown, "ClearUp" -> clearUp,
    "ClearSub" -> clearSub, "ClearN" -> clearN,
    "ClearDefault" -> clearDefault, "ClearFormat" -> clearFormat,
    "FinalState" -> finalState|>
];

runProbe[] := Module[
  {trackedGlobalPattern, trackedPackagePattern, preexistingGlobalNames,
   preexistingPackageNames, xBefore, yBefore, epsilonBefore,
   xAfter, yAfter, epsilonAfter, directTrace, heldTrace, stringTrace,
   packageTrace, multiArgumentTrace, listArgumentTrace,
   stringPatternTrace, cleanupTrace, remainingGlobalNames,
   remainingPackageNames, cleanupQ, protectedSymbolsUntouchedQ,
   diagnostics},
  trackedGlobalPattern = "Global`CodexCGARDisposableSemanticsV1*";
  trackedPackagePattern =
    "CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1";
  preexistingGlobalNames = Names[trackedGlobalPattern];
  preexistingPackageNames = Names[trackedPackagePattern];
  xBefore = definitionState[Global`x];
  yBefore = definitionState[Global`y];
  epsilonBefore = definitionState[Global`eps];

  Quiet[Unlock[
    Global`CodexCGARDisposableSemanticsV1Direct,
    Global`CodexCGARDisposableSemanticsV1Held,
    Global`CodexCGARDisposableSemanticsV1String,
    Global`CodexCGARDisposableSemanticsV1MultiA,
    Global`CodexCGARDisposableSemanticsV1MultiB,
    CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1]];
  Quiet[Unprotect[
    Global`CodexCGARDisposableSemanticsV1Direct,
    Global`CodexCGARDisposableSemanticsV1Held,
    Global`CodexCGARDisposableSemanticsV1String,
    Global`CodexCGARDisposableSemanticsV1MultiA,
    Global`CodexCGARDisposableSemanticsV1MultiB,
    CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1]];
  Quiet[ClearAll[
    Global`CodexCGARDisposableSemanticsV1Direct,
    Global`CodexCGARDisposableSemanticsV1Held,
    Global`CodexCGARDisposableSemanticsV1String,
    Global`CodexCGARDisposableSemanticsV1MultiA,
    Global`CodexCGARDisposableSemanticsV1MultiB,
    CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1]];

  Global`CodexCGARDisposableSemanticsV1Direct[argument_] := argument + 1;
  Global`CodexCGARDisposableSemanticsV1Direct = 101;
  SetAttributes[Global`CodexCGARDisposableSemanticsV1Direct,
    {Protected, Locked}];
  Global`CodexCGARDisposableSemanticsV1Held[argument_] := argument + 2;
  Global`CodexCGARDisposableSemanticsV1Held = 202;
  SetAttributes[Global`CodexCGARDisposableSemanticsV1Held,
    {Protected, Locked}];
  Global`CodexCGARDisposableSemanticsV1String[argument_] := argument + 3;
  Global`CodexCGARDisposableSemanticsV1String = 303;
  SetAttributes[Global`CodexCGARDisposableSemanticsV1String,
    {Protected, Locked}];
  Global`CodexCGARDisposableSemanticsV1MultiA = 404;
  Global`CodexCGARDisposableSemanticsV1MultiB = 505;
  SetAttributes[Global`CodexCGARDisposableSemanticsV1MultiA,
    {Protected, Locked}];
  SetAttributes[Global`CodexCGARDisposableSemanticsV1MultiB,
    {Protected, Locked}];
  CodexCF300DisposableSymbolUnlockSemanticsProbeV1`
    probePackageSymbolV1[argument_] := argument + 6;
  CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1 =
    606;
  SetAttributes[
    CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1,
    {Protected, Locked}];

  directTrace = <|
    "InitialState" ->
      definitionState[Global`CodexCGARDisposableSemanticsV1Direct],
    "Unlock" -> capture[
      Unlock[Global`CodexCGARDisposableSemanticsV1Direct]],
    "AfterUnlockAttributes" ->
      Attributes[Global`CodexCGARDisposableSemanticsV1Direct],
    "Unprotect" -> capture[
      Unprotect[Global`CodexCGARDisposableSemanticsV1Direct]],
    "AfterUnprotectAttributes" ->
      Attributes[Global`CodexCGARDisposableSemanticsV1Direct],
    "SetEmptyAttributes" -> capture[
      Attributes[Global`CodexCGARDisposableSemanticsV1Direct] = {}],
    "SetEmptyOwnValues" -> capture[
      OwnValues[Global`CodexCGARDisposableSemanticsV1Direct] = {}],
    "SetEmptyDownValues" -> capture[
      DownValues[Global`CodexCGARDisposableSemanticsV1Direct] = {}],
    "FinalState" ->
      definitionState[Global`CodexCGARDisposableSemanticsV1Direct]|>;
  heldTrace = <|
    "InitialState" ->
      definitionState[Global`CodexCGARDisposableSemanticsV1Held],
    "HelperResult" -> heldNeutralize[
      Global`CodexCGARDisposableSemanticsV1Held]|>;
  stringTrace = <|
    "InitialState" ->
      definitionState[Global`CodexCGARDisposableSemanticsV1String],
    "UnlockString" -> capture[
      Unlock["Global`CodexCGARDisposableSemanticsV1String"]],
    "UnprotectString" -> capture[
      Unprotect["Global`CodexCGARDisposableSemanticsV1String"]],
    "ClearAllString" -> capture[
      ClearAll["Global`CodexCGARDisposableSemanticsV1String"]],
    "FinalState" ->
      definitionState[Global`CodexCGARDisposableSemanticsV1String]|>;
  packageTrace = <|
    "InitialState" -> definitionState[
      CodexCF300DisposableSymbolUnlockSemanticsProbeV1`
        probePackageSymbolV1],
    "UnlockDirect" -> capture[Unlock[
      CodexCF300DisposableSymbolUnlockSemanticsProbeV1`
        probePackageSymbolV1]],
    "UnprotectDirect" -> capture[Unprotect[
      CodexCF300DisposableSymbolUnlockSemanticsProbeV1`
        probePackageSymbolV1]],
    "ClearAllString" -> capture[ClearAll[
      "CodexCF300DisposableSymbolUnlockSemanticsProbeV1`probePackageSymbolV1"]],
    "FinalState" -> definitionState[
      CodexCF300DisposableSymbolUnlockSemanticsProbeV1`
        probePackageSymbolV1]|>;
  multiArgumentTrace = capture[Unlock[
    Global`CodexCGARDisposableSemanticsV1MultiA,
    Global`CodexCGARDisposableSemanticsV1MultiB]];
  listArgumentTrace = capture[Unlock[{
    Global`CodexCGARDisposableSemanticsV1MultiA,
    Global`CodexCGARDisposableSemanticsV1MultiB}]];
  stringPatternTrace = capture[
    Unlock["Global`CodexCGARDisposableSemanticsV1Multi*"]];

  cleanupTrace = <|
    "UnlockGlobalPattern" -> capture[Unlock[trackedGlobalPattern]],
    "UnprotectGlobalPattern" -> capture[Unprotect[trackedGlobalPattern]],
    "ClearGlobalPattern" -> capture[ClearAll[trackedGlobalPattern]],
    "RemoveGlobalPattern" -> capture[Remove[trackedGlobalPattern]],
    "UnlockPackagePattern" -> capture[Unlock[trackedPackagePattern]],
    "UnprotectPackagePattern" -> capture[Unprotect[trackedPackagePattern]],
    "ClearPackagePattern" -> capture[ClearAll[trackedPackagePattern]],
    "RemovePackagePattern" -> capture[Remove[trackedPackagePattern]]|>;
  remainingGlobalNames = Names[trackedGlobalPattern];
  remainingPackageNames = Names[trackedPackagePattern];
  xAfter = definitionState[Global`x];
  yAfter = definitionState[Global`y];
  epsilonAfter = definitionState[Global`eps];
  cleanupQ = remainingGlobalNames === {} &&
    remainingPackageNames === {};
  protectedSymbolsUntouchedQ = SameQ[xAfter, xBefore] &&
    SameQ[yAfter, yBefore] && SameQ[epsilonAfter, epsilonBefore];
  diagnostics = <|
    "Status" -> "CF300DisposableSymbolUnlockSemanticsProbeV1",
    "PreexistingGlobalNames" -> preexistingGlobalNames,
    "PreexistingPackageNames" -> preexistingPackageNames,
    "ProtectedXYZStateFingerprintsBefore" -> <|
      "x" -> fingerprint[xBefore], "y" -> fingerprint[yBefore],
      "eps" -> fingerprint[epsilonBefore]|>,
    "DirectSymbolTrace" -> directTrace,
    "HoldFirstHelperTrace" -> heldTrace,
    "StringFormTrace" -> stringTrace,
    "PackageSymbolTrace" -> packageTrace,
    "MultiArgumentUnlockTrace" -> multiArgumentTrace,
    "ListArgumentUnlockTrace" -> listArgumentTrace,
    "StringPatternUnlockTrace" -> stringPatternTrace,
    "CleanupTrace" -> cleanupTrace,
    "RemainingGlobalNames" -> remainingGlobalNames,
    "RemainingPackageNames" -> remainingPackageNames,
    "DisposableSymbolsRemovedQ" -> cleanupQ,
    "GlobalXYZUntouchedQ" -> protectedSymbolsUntouchedQ|>;
  diagnostics
];

probeDiagnostics = runProbe[];
Print["CF300_DISPOSABLE_UNLOCK_SEMANTICS diagnostics=",
  InputForm[probeDiagnostics]];
probeExit[If[
  TrueQ[probeDiagnostics["DisposableSymbolsRemovedQ"]] &&
    TrueQ[probeDiagnostics["GlobalXYZUntouchedQ"]],
  0,
  2]];
