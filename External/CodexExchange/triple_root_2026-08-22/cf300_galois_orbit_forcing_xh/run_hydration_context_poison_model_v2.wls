#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300HydrationContextPoisonModelV2`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300HydrationContextPoisonModelV2`Private`*"]];
modelExit[code_Integer] := (End[]; EndPackage[]; System`Exit[code]);

fixtureFile = FileNameJoin[{DirectoryName[$InputFileName],
  "hydration_context_fixture_v1.wl"}];
expectedFixtureHash =
  "300f3a68e77469f6558431fcbe8e0e42e99ae9ecb468965f507a09967c3e09f4";
canonicalPath = {"System`", "Global`",
  "CodexCF300HydrationContextPoisonModelV2`"};
isolatedContext = "CodexCF300HydrationIsolationModelV2`";
isolatedPath = {"System`", isolatedContext,
  "CodexCF300HydrationContextPoisonModelV2`"};

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
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
stateDigest[state_] := Block[
  {$Context = "Global`", $ContextPath = canonicalPath},
  fingerprint[state]];

restoreGlobalAttributes[xAttributes_List, yAttributes_List,
    epsilonAttributes_List] := Module[{},
  Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
  Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
  Attributes[Global`x] = DeleteCases[xAttributes, Locked];
  Attributes[Global`y] = DeleteCases[yAttributes, Locked];
  Attributes[Global`eps] = DeleteCases[epsilonAttributes, Locked];
  If[MemberQ[xAttributes, Locked], Lock[Global`x]];
  If[MemberQ[yAttributes, Locked], Lock[Global`y]];
  If[MemberQ[epsilonAttributes, Locked], Lock[Global`eps]]
];

SetAttributes[withCanonicalGlobalArtifactSymbols, HoldAll];
withCanonicalGlobalArtifactSymbols[body_] := Module[
  {xAttributes = Attributes[Global`x],
   yAttributes = Attributes[Global`y],
   epsilonAttributes = Attributes[Global`eps]},
  Internal`WithLocalSettings[
    Null,
    Internal`InheritedBlock[{Global`x, Global`y, Global`eps},
      Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
      Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
      ClearAll[Global`x, Global`y, Global`eps];
      Block[{$Context = "Global`", $ContextPath = canonicalPath},
        body]],
    restoreGlobalAttributes[
      xAttributes, yAttributes, epsilonAttributes]]
];

canonicalRead[] := withCanonicalGlobalArtifactSymbols[
  Quiet[Check[Get[fixtureFile], $Failed]]];

isolatedRead[] := Module[{value, messages},
  Internal`InheritedBlock[{
      CodexCF300HydrationIsolationModelV2`x,
      CodexCF300HydrationIsolationModelV2`y,
      CodexCF300HydrationIsolationModelV2`eps},
    Quiet[Check[Unlock[
      CodexCF300HydrationIsolationModelV2`x,
      CodexCF300HydrationIsolationModelV2`y,
      CodexCF300HydrationIsolationModelV2`eps], Null]];
    Quiet[Check[Unprotect[
      CodexCF300HydrationIsolationModelV2`x,
      CodexCF300HydrationIsolationModelV2`y,
      CodexCF300HydrationIsolationModelV2`eps], Null]];
    ClearAll[CodexCF300HydrationIsolationModelV2`x,
      CodexCF300HydrationIsolationModelV2`y,
      CodexCF300HydrationIsolationModelV2`eps];
    Block[{$Context = isolatedContext, $ContextPath = isolatedPath,
        $MessageList = {}},
      value = Quiet[Check[Get[fixtureFile], $Failed]];
      messages = $MessageList]];
  <|"Value" -> value, "Messages" -> messages|>
];
contextFingerprint[value_, context_String, path_List] :=
  Block[{$Context = context, $ContextPath = path}, fingerprint[value]];

If[! FileExistsQ[fixtureFile] ||
    FileHash[fixtureFile, "SHA256", "HexString"] =!=
      expectedFixtureHash,
  Print["CF300_HYDRATION_MODEL_V2 FAIL fixture pin"];
  modelExit[66]];

originalXState = definitionState[Global`x];
originalYState = definitionState[Global`y];
originalEpsilonState = definitionState[Global`eps];
originalXAttributes = originalXState["Attributes"];
originalYAttributes = originalYState["Attributes"];
originalEpsilonAttributes = originalEpsilonState["Attributes"];
passed = False;
diagnostics = <|"Status" -> "ModelNotRun"|>;

Internal`WithLocalSettings[
  Null,
  Internal`InheritedBlock[{Global`x, Global`y, Global`eps},
    Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
    Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
    ClearAll[Global`x, Global`y, Global`eps];

    Global`x[1][2] = HoldComplete["x-sub"];
    Global`y[1][2] = HoldComplete["y-sub"];
    Global`eps[1][2] = HoldComplete["eps-sub"];
    Global`x[argument_] := HoldComplete["x-down", argument];
    Global`y[argument_] := HoldComplete["y-down", argument];
    Global`eps[argument_] := HoldComplete["eps-down", argument];
    Global`x /: poisonHeadX[Global`x] = HoldComplete["x-up"];
    Global`y /: poisonHeadY[Global`y] = HoldComplete["y-up"];
    Global`eps /: poisonHeadEpsilon[Global`eps] =
      HoldComplete["eps-up"];
    Global`x = 31337;
    Global`y = -27183;
    Global`eps = 65537;
    SetAttributes[Global`x, {Protected, Locked}];
    SetAttributes[Global`y, {Protected, Locked}];
    SetAttributes[Global`eps, {Protected, Locked}];

    poisonXBefore = definitionState[Global`x];
    poisonYBefore = definitionState[Global`y];
    poisonEpsilonBefore = definitionState[Global`eps];
    canonicalFirst = canonicalRead[];
    poisonXAfterFirst = definitionState[Global`x];
    poisonYAfterFirst = definitionState[Global`y];
    poisonEpsilonAfterFirst = definitionState[Global`eps];
    canonicalSecond = canonicalRead[];
    poisonXAfterSecond = definitionState[Global`x];
    poisonYAfterSecond = definitionState[Global`y];
    poisonEpsilonAfterSecond = definitionState[Global`eps];
    cleanupProbeTag = "CF300HydrationCleanupProbe-" <> CreateUUID[];
    cleanupProbeOutcome = Catch[
      withCanonicalGlobalArtifactSymbols[
        Throw["ExpectedCleanupProbeThrow", cleanupProbeTag]],
      cleanupProbeTag];
    poisonXAfterCleanupThrow = definitionState[Global`x];
    poisonYAfterCleanupThrow = definitionState[Global`y];
    poisonEpsilonAfterCleanupThrow = definitionState[Global`eps];
    isolatedResult = isolatedRead[];
    isolated = isolatedResult["Value"];

    (* Reproduce V1's raw InheritedBlock cleanup last, after all corrected
       helper probes.  The enclosing model scope will restore the caller even
       though this legacy probe intentionally omits attribute cleanup. *)
    legacyCanonical = Internal`InheritedBlock[
      {Global`x, Global`y, Global`eps},
      Quiet[Check[Unlock[Global`x, Global`y, Global`eps], Null]];
      Quiet[Check[Unprotect[Global`x, Global`y, Global`eps], Null]];
      ClearAll[Global`x, Global`y, Global`eps];
      Block[{$Context = "Global`", $ContextPath = canonicalPath},
        Quiet[Check[Get[fixtureFile], $Failed]]]];
    legacyXAfter = definitionState[Global`x];
    legacyYAfter = definitionState[Global`y];
    legacyEpsilonAfter = definitionState[Global`eps];
    definitionComponents = {"OwnValues", "DownValues", "UpValues",
      "SubValues", "NValues", "DefaultValues", "FormatValues",
      "Attributes"};
    legacyRestorationByComponent = AssociationMap[
      Function[component, And[
        SameQ[poisonXBefore[component], legacyXAfter[component]],
        SameQ[poisonYBefore[component], legacyYAfter[component]],
        SameQ[poisonEpsilonBefore[component],
          legacyEpsilonAfter[component]]]], definitionComponents];
    legacyAttributeOnlyFailureObserved = And[
      AllTrue[Values[KeyDrop[legacyRestorationByComponent,
        "Attributes"]], TrueQ],
      ! TrueQ[legacyRestorationByComponent["Attributes"]]];

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
      "Status" -> "CF300HydrationContextPoisonModelV2",
      "FixtureSHA256" -> expectedFixtureHash,
      "PoisonStateDigestsBefore" -> <|
        "x" -> stateDigest[poisonXBefore],
        "y" -> stateDigest[poisonYBefore],
        "eps" -> stateDigest[poisonEpsilonBefore]|>,
      "PoisonContainsOwnDownUpSubValues" -> And @@ Map[
        Function[key, AllTrue[Lookup[{poisonXBefore, poisonYBefore,
          poisonEpsilonBefore}, key], #1 =!= {} &]],
        {"OwnValues", "DownValues", "UpValues", "SubValues"}],
      "PoisonContainsProtectedLocked" -> AllTrue[
        Lookup[{poisonXBefore, poisonYBefore, poisonEpsilonBefore},
          "Attributes"],
        MemberQ[#1, Protected] && MemberQ[#1, Locked] &],
      "LegacyRestorationByExactComponent" ->
        legacyRestorationByComponent,
      "LegacyAttributeOnlyFailureObserved" ->
        legacyAttributeOnlyFailureObserved,
      "XStateRestoredAfterFirstCanonicalRead" ->
        SameQ[poisonXAfterFirst, poisonXBefore],
      "YStateRestoredAfterFirstCanonicalRead" ->
        SameQ[poisonYAfterFirst, poisonYBefore],
      "EpsilonStateRestoredAfterFirstCanonicalRead" ->
        SameQ[poisonEpsilonAfterFirst, poisonEpsilonBefore],
      "XStateRestoredAfterSecondCanonicalRead" ->
        SameQ[poisonXAfterSecond, poisonXBefore],
      "YStateRestoredAfterSecondCanonicalRead" ->
        SameQ[poisonYAfterSecond, poisonYBefore],
      "EpsilonStateRestoredAfterSecondCanonicalRead" ->
        SameQ[poisonEpsilonAfterSecond, poisonEpsilonBefore],
      "CleanupThrowOutcome" -> cleanupProbeOutcome,
      "XStateRestoredAfterCleanupThrow" ->
        SameQ[poisonXAfterCleanupThrow, poisonXBefore],
      "YStateRestoredAfterCleanupThrow" ->
        SameQ[poisonYAfterCleanupThrow, poisonYBefore],
      "EpsilonStateRestoredAfterCleanupThrow" ->
        SameQ[poisonEpsilonAfterCleanupThrow, poisonEpsilonBefore],
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
        SameQ[canonicalFingerprint, canonicalSecondFingerprint],
      "IsolatedAssociationQ" -> AssociationQ[isolated],
      "IsolatedMessages" -> isolatedResult["Messages"],
      "IsolatedStatus" -> If[AssociationQ[isolated],
        Lookup[isolated, "Status", Missing["Absent"]], $Failed],
      "IsolatedVariableNames" -> If[ListQ[isolatedVariables],
        SymbolName /@ isolatedVariables, $Failed],
      "IsolatedVariableContexts" -> If[ListQ[isolatedVariables],
        Context /@ isolatedVariables, $Failed],
      "IsolatedViewOfCanonicalFingerprint" ->
        isolatedViewOfCanonicalFingerprint,
      "CanonicalVsIsolatedFingerprintDifferent" ->
        UnsameQ[canonicalFingerprint,
          isolatedViewOfCanonicalFingerprint]|>;

    passed = TrueQ[
      diagnostics["PoisonContainsOwnDownUpSubValues"] &&
      diagnostics["PoisonContainsProtectedLocked"] &&
      diagnostics["LegacyAttributeOnlyFailureObserved"] &&
      diagnostics["XStateRestoredAfterFirstCanonicalRead"] &&
      diagnostics["YStateRestoredAfterFirstCanonicalRead"] &&
      diagnostics["EpsilonStateRestoredAfterFirstCanonicalRead"] &&
      diagnostics["XStateRestoredAfterSecondCanonicalRead"] &&
      diagnostics["YStateRestoredAfterSecondCanonicalRead"] &&
      diagnostics["EpsilonStateRestoredAfterSecondCanonicalRead"] &&
      diagnostics["CleanupThrowOutcome"] ===
        "ExpectedCleanupProbeThrow" &&
      diagnostics["XStateRestoredAfterCleanupThrow"] &&
      diagnostics["YStateRestoredAfterCleanupThrow"] &&
      diagnostics["EpsilonStateRestoredAfterCleanupThrow"] &&
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
      diagnostics["CanonicalVsIsolatedFingerprintDifferent"]]],
  restoreGlobalAttributes[originalXAttributes, originalYAttributes,
    originalEpsilonAttributes]];

postModelXState = definitionState[Global`x];
postModelYState = definitionState[Global`y];
postModelEpsilonState = definitionState[Global`eps];
diagnostics = Join[diagnostics, <|
  "CallerXStateRestoredAfterModelScope" ->
    SameQ[postModelXState, originalXState],
  "CallerYStateRestoredAfterModelScope" ->
    SameQ[postModelYState, originalYState],
  "CallerEpsilonStateRestoredAfterModelScope" ->
    SameQ[postModelEpsilonState, originalEpsilonState]|>];
passed = TrueQ[passed &&
  diagnostics["CallerXStateRestoredAfterModelScope"] &&
  diagnostics["CallerYStateRestoredAfterModelScope"] &&
  diagnostics["CallerEpsilonStateRestoredAfterModelScope"]];

Print["CF300_HYDRATION_MODEL_V2 diagnostics=", InputForm[diagnostics]];
Print["CF300_HYDRATION_MODEL_V2 pass=", passed];
modelExit[If[passed, 0, 2]];
