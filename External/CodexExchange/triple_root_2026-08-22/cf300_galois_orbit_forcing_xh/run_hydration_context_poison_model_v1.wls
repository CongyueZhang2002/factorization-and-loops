#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300HydrationContextPoisonModelV1`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300HydrationContextPoisonModelV1`Private`*"]];
modelExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);

fixtureFile = FileNameJoin[{DirectoryName[$InputFileName],
  "hydration_context_fixture_v1.wl"}];
expectedFixtureHash =
  "300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4";
canonicalPath = {"System`", "Global`",
  "CodexCF300HydrationContextPoisonModelV1`"};
isolatedContext = "CodexCF300HydrationIsolationModelV1`";
isolatedPath = {"System`", isolatedContext,
  "CodexCF300HydrationContextPoisonModelV1`"};

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
SetAttributes[definitionFingerprint, HoldFirst];
definitionFingerprint[symbol_] := fingerprint[{
  OwnValues[symbol], DownValues[symbol], UpValues[symbol],
  SubValues[symbol], Attributes[symbol]}];
canonicalRead[] := Internal`InheritedBlock[
  {Global`x, Global`y, Global`eps},
  Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
  Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
  ClearAll[Global`x, Global`y, Global`eps];
  Block[{$Context = "Global`", $ContextPath = canonicalPath},
    Quiet[Check[Get[fixtureFile], $Failed]]]
];
isolatedRead[] := Module[{value},
  Quiet[ClearAll["CodexCF300HydrationIsolationModelV1`*"]];
  value = Block[{$Context = isolatedContext,
      $ContextPath = isolatedPath},
    Quiet[Check[Get[fixtureFile], $Failed]]];
  value
];
contextFingerprint[value_, context_String, path_List] :=
  Block[{$Context = context, $ContextPath = path}, fingerprint[value]];

If[! FileExistsQ[fixtureFile] ||
    FileHash[fixtureFile, "SHA256", "HexString"] =!=
      expectedFixtureHash,
  Print["CF300_HYDRATION_MODEL FAIL fixture pin"];
  modelExit[66]];

Internal`InheritedBlock[{Global`x, Global`y, Global`eps},
  Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
  Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
  ClearAll[Global`x, Global`y, Global`eps];
  Global`x = 31337;
  Global`y = -27183;
  Global`eps = 65537;
  Protect[Global`x, Global`y, Global`eps];
  poisonFingerprintBefore = <|
    "x" -> definitionFingerprint[Global`x],
    "y" -> definitionFingerprint[Global`y],
    "eps" -> definitionFingerprint[Global`eps]|>;

  canonicalFirst = canonicalRead[];
  poisonFingerprintAfterFirst = <|
    "x" -> definitionFingerprint[Global`x],
    "y" -> definitionFingerprint[Global`y],
    "eps" -> definitionFingerprint[Global`eps]|>;
  canonicalSecond = canonicalRead[];
  poisonFingerprintAfterSecond = <|
    "x" -> definitionFingerprint[Global`x],
    "y" -> definitionFingerprint[Global`y],
    "eps" -> definitionFingerprint[Global`eps]|>;
  isolated = isolatedRead[];

  canonicalVariables = If[AssociationQ[canonicalFirst],
    Lookup[canonicalFirst, "Variables", $Failed], $Failed];
  isolatedVariables = If[AssociationQ[isolated],
    Lookup[isolated, "Variables", $Failed], $Failed];
  canonicalForms = If[AssociationQ[canonicalFirst],
    Lookup[canonicalFirst, "ExactChannelForms", $Failed], $Failed];
  canonicalFingerprint = contextFingerprint[
    canonicalForms, "Global`", canonicalPath];
  isolatedViewOfCanonicalFingerprint = contextFingerprint[
    canonicalForms, isolatedContext, isolatedPath];
  canonicalSecondFingerprint = contextFingerprint[
    Lookup[canonicalSecond, "ExactChannelForms", $Failed],
    "Global`", canonicalPath];

  diagnostics = <|
    "Status" -> "CF300HydrationContextPoisonModelV1",
    "FixtureSHA256" -> expectedFixtureHash,
    "SameKernelPoisonInstalled" -> True,
    "PoisonFingerprintBefore" -> poisonFingerprintBefore,
    "PoisonRestoredAfterFirstCanonicalRead" ->
      (poisonFingerprintAfterFirst === poisonFingerprintBefore),
    "PoisonRestoredAfterSecondCanonicalRead" ->
      (poisonFingerprintAfterSecond === poisonFingerprintBefore),
    "CanonicalAssociationQ" -> AssociationQ[canonicalFirst],
    "CanonicalStatus" -> If[AssociationQ[canonicalFirst],
      Lookup[canonicalFirst, "Status", Missing["Absent"]], $Failed],
    "CanonicalVariableNames" -> If[ListQ[canonicalVariables],
      SymbolName /@ canonicalVariables, $Failed],
    "CanonicalVariableContexts" -> If[ListQ[canonicalVariables],
      Context /@ canonicalVariables, $Failed],
    "CanonicalReadsValueIdentical" ->
      SameQ[canonicalFirst, canonicalSecond],
    "CanonicalFingerprint" -> canonicalFingerprint,
    "CanonicalSecondFingerprint" -> canonicalSecondFingerprint,
    "CanonicalFingerprintsStable" ->
      (canonicalFingerprint === canonicalSecondFingerprint),
    "IsolatedAssociationQ" -> AssociationQ[isolated],
    "IsolatedStatus" -> If[AssociationQ[isolated],
      Lookup[isolated, "Status", Missing["Absent"]], $Failed],
    "IsolatedVariableNames" -> If[ListQ[isolatedVariables],
      SymbolName /@ isolatedVariables, $Failed],
    "IsolatedVariableContexts" -> If[ListQ[isolatedVariables],
      Context /@ isolatedVariables, $Failed],
    "IsolatedViewOfCanonicalFingerprint" ->
      isolatedViewOfCanonicalFingerprint,
    "CanonicalVsIsolatedFingerprintDifferent" ->
      (canonicalFingerprint =!= isolatedViewOfCanonicalFingerprint)|>;

  passed = TrueQ[
    diagnostics["PoisonRestoredAfterFirstCanonicalRead"] &&
    diagnostics["PoisonRestoredAfterSecondCanonicalRead"] &&
    diagnostics["CanonicalStatus"] === "HydrationContextFixtureV1" &&
    diagnostics["CanonicalVariableNames"] === {"x", "y"} &&
    diagnostics["CanonicalVariableContexts"] ===
      {"Global`", "Global`"} &&
    diagnostics["CanonicalReadsValueIdentical"] &&
    diagnostics["CanonicalFingerprintsStable"] &&
    diagnostics["IsolatedStatus"] === "HydrationContextFixtureV1" &&
    diagnostics["IsolatedVariableNames"] === {"x", "y"} &&
    diagnostics["IsolatedVariableContexts"] ===
      {isolatedContext, isolatedContext} &&
    diagnostics["CanonicalVsIsolatedFingerprintDifferent"]];
  Print["CF300_HYDRATION_MODEL diagnostics=", InputForm[diagnostics]];
  Print["CF300_HYDRATION_MODEL pass=", passed];
  modelExit[If[passed, 0, 2]]
];

