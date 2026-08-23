#!/usr/bin/env wolframscript

(* Read-only, source-derived Global-state preflight for the CF300 recapture.
   The caller localizes $ContextPath/$Packages.  No absent Global symbol is
   interned: exact definition states are read only for names already returned
   by System`Names.  The package cleans its own namespace before returning. *)

BeginPackage["CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`"];
Begin["`Private`"];

preflightFinalReport = Module[
  {bundleDirectory, repositoryRoot, driver, censusFile, inspectorFile,
   feynCalcEntryPoint, feynArtsEntryPoint, feynCalcVersion, feynArtsVersion,
   expectedDriverHash, expectedCensusHash, expectedInspectorHash,
   hashHex, census, importMessages, censusGateQ, qualifiedCensusNames,
   globalNamesBefore, globalNamesAfter, packageContexts, packageBaseNames,
   existingPackageNames, packageListHazards, explicitScopeNames,
   sourceCandidateNames, shadowNames, inspectedNames,
   definitionComponents, symbolDefinitionState,
   symbolDefinitionStateByNameHeld, symbolDefinitionStateByName,
   definitionFreeStateQ, definitionSummary, statesBefore, statesAfter,
   dirtyDefinitionNames, unsafeDirtyDefinitionNames,
   unsafePackageShadowNames, allowedDirtyNames,
   packageDefinitionFingerprint, packageFingerprintBefore,
   packageFingerprintAfter, stateReadGateQ, readOnlyGateQ, report,
   preflightResult},

  bundleDirectory = DirectoryName[ExpandFileName[System`$InputFileName]];
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  driver = FileNameJoin[{repositoryRoot, "Scripts",
    "family_epsform_sector.wls"}];
  censusFile = FileNameJoin[{bundleDirectory,
    "family_sector_driver_global_census_v1.json"}];
  inspectorFile = FileNameJoin[{bundleDirectory,
    "inspect_family_sector_driver_global_census_v1.py"}];
  feynCalcEntryPoint = FileNameJoin[{repositoryRoot, "Addon",
    "Mathematica_Addon", "FeynCalc", "FeynCalc.m"}];
  feynArtsEntryPoint = FileNameJoin[{repositoryRoot, "Addon",
    "Mathematica_Addon", "FeynArts", "FeynArts.m"}];
  expectedDriverHash =
    "6786d5ee1ccefe101f6d70d1f8a977cd5de039b8673e20d54062f8b4915895f1";
  expectedCensusHash =
    "990e086691cd0651823df256e019e6d7e32042b64951ded39f4f31ad8e16c377";
  expectedInspectorHash =
    "89d27f01e6ab92bcf64fff60085f8c87115edab02d86b8ebf9691886735da6ae";
  hashHex[file_String] := Quiet[Check[
    If[System`FileExistsQ[file],
      IntegerString[System`FileHash[file, "SHA256"], 16, 64],
      Missing["NotFound"]], Missing["HashFailed"]]];

  definitionComponents = {"OwnValues", "DownValues", "UpValues",
    "SubValues", "NValues", "DefaultValues", "FormatValues",
    "Attributes", "Messages", "Options"};
  System`SetAttributes[symbolDefinitionState, HoldFirst];
  symbolDefinitionState[symbol_] := <|
    "OwnValues" -> System`OwnValues[symbol],
    "DownValues" -> System`DownValues[symbol],
    "UpValues" -> System`UpValues[symbol],
    "SubValues" -> System`SubValues[symbol],
    "NValues" -> System`NValues[symbol],
    "DefaultValues" -> System`DefaultValues[symbol],
    "FormatValues" -> System`FormatValues[symbol],
    "Attributes" -> System`Attributes[symbol],
    "Messages" -> System`Messages[symbol],
    "Options" -> System`Options[System`Unevaluated[symbol]]|>;
  System`SetAttributes[symbolDefinitionStateByNameHeld, HoldAll];
  symbolDefinitionStateByNameHeld[symbol_] :=
    symbolDefinitionState[symbol];
  symbolDefinitionStateByName[name_String] := System`ToExpression[
    name, InputForm,
    Function[heldSymbol,
      symbolDefinitionStateByNameHeld[heldSymbol], HoldAll]];
  definitionFreeStateQ[state_Association] := TrueQ[
    Lookup[state, definitionComponents, $Failed] ===
      ConstantArray[{}, Length[definitionComponents]]];
  definitionFreeStateQ[___] := False;
  definitionSummary[state_Association] := <|
    "OwnValueCount" -> Length[Lookup[state, "OwnValues", {$Failed}]],
    "DownValueCount" -> Length[Lookup[state, "DownValues", {$Failed}]],
    "UpValueCount" -> Length[Lookup[state, "UpValues", {$Failed}]],
    "SubValueCount" -> Length[Lookup[state, "SubValues", {$Failed}]],
    "NValueCount" -> Length[Lookup[state, "NValues", {$Failed}]],
    "DefaultValueCount" ->
      Length[Lookup[state, "DefaultValues", {$Failed}]],
    "FormatValueCount" ->
      Length[Lookup[state, "FormatValues", {$Failed}]],
    "Attributes" -> Lookup[state, "Attributes", {$Failed}],
    "MessageCount" -> Length[Lookup[state, "Messages", {$Failed}]],
    "OptionCount" -> Length[Lookup[state, "Options", {$Failed}]]|>;
  definitionSummary[___] := $Failed;

  preflightResult = CheckAbort[
    Catch[
    If[! IntegerQ[System`$KernelID] || System`$KernelID <= 0 ||
        Length[System`Kernels[]] =!= 0 ||
        ! (ValueQ[KernelPoolMission`$TaskBrokerMaxHelpers] &&
          KernelPoolMission`$TaskBrokerMaxHelpers === 0),
      Throw[<|"GateQ" -> False,
        "Failure" -> "worker/helper preflight"|>]];
    If[hashHex[driver] =!= expectedDriverHash ||
        hashHex[censusFile] =!= expectedCensusHash ||
        hashHex[inspectorFile] =!= expectedInspectorHash ||
        hashHex[feynCalcEntryPoint] =!=
          "4238350af2ff91a6687ea937446b9e6077318914593afe963d4d10026dfc5165" ||
        hashHex[feynArtsEntryPoint] =!=
          "7c23eed024fa4666a024c84e956f832960026c46b38edd91d90f4016422b1476",
      Throw[<|"GateQ" -> False,
        "Failure" -> "driver/census/inspector hash drift"|>]];

    importMessages = {};
    Block[{System`$MessageList = {}},
      census = Quiet[Check[Import[censusFile, "RawJSON"], $Failed]];
      importMessages = ToString[InputForm[#1]] & /@ System`$MessageList];
    qualifiedCensusNames = If[AssociationQ[census],
      Lookup[census, "QualifiedGlobalNames", $Failed], $Failed];
    censusGateQ = TrueQ[
      importMessages === {} && AssociationQ[census] &&
      Lookup[census, "Schema", None] ===
        "FACETFamilySectorDriverGlobalCensusV1" &&
      Lookup[census, "DriverSHA256", None] === expectedDriverHash &&
      TrueQ[Lookup[Lookup[census, "Extraction", <||>],
        "AssignmentLHSCoveredQ", False]] &&
      TrueQ[Lookup[Lookup[census, "Extraction", <||>],
        "ConservativeSupersetQ", False]] &&
      IntegerQ[Lookup[census, "QualifiedGlobalNameCount", None]] &&
      Lookup[census, "QualifiedGlobalNameCount", None] === 637 &&
      ListQ[qualifiedCensusNames] &&
      Length[qualifiedCensusNames] === 637 &&
      DuplicateFreeQ[qualifiedCensusNames] &&
      AllTrue[qualifiedCensusNames,
        StringQ[#1] && StringStartsQ[#1, "Global`"] &] &&
      And @@ (MemberQ[qualifiedCensusNames, #1] & /@
        {"Global`tau", "Global`s", "Global`u", "Global`p",
         "Global`x", "Global`y", "Global`eps", "Global`v",
         "Global`w", "Global`nb", "Global`n", "Global`xhat",
         "Global`yhat",
         "Global`$LoadFeynArts", "Global`$LoadAddOns",
         "Global`A0"})];
    If[! censusGateQ,
      Throw[<|"GateQ" -> False,
        "Failure" -> "census schema/content gate",
        "ImportMessages" -> importMessages|>]];

    globalNamesBefore = System`Names["Global`*"];
    explicitScopeNames = {
      "Global`tau", "Global`s", "Global`u", "Global`p",
      "Global`x", "Global`y", "Global`eps", "Global`v", "Global`w",
      "Global`t", "Global`r", "Global`mu", "Global`xi", "Global`xx",
      "Global`Eps", "Global`epsilon", "Global`Epsilon", "Global`ep",
      "Global`sqrtLambda", "Global`gli", "Global`nb", "Global`n",
      "Global`xhat", "Global`yhat", "Global`GlobalBasis",
      "Global`$LoadFeynArts", "Global`$LoadAddOns", "Global`A0",
      "Global`$FACETKernelLimit", "Global`$FACETRatracerExecutable",
      "Global`$FeynCalcStartupMessages", "Global`$PolyLogPath",
      "Global`FeynFacetFermatCheckVariable", "Global`root",
      "Global`ranges", "Global`t0", "Global`variables", "Global`dD"};
    packageContexts = {"FeynCalc`", "FeynArts`", "FeynFacet`",
      "FeynHelpers`", "FeynCalcLegacy`", "CANONICA`"};
    existingPackageNames = Union @@
      (System`Names[#1 <> "*"] & /@ packageContexts);
    packageListHazards = Select[System`$Packages,
      Function[packageName,
        MemberQ[packageContexts, packageName] ||
          AnyTrue[packageContexts,
            Function[packageContext,
              StringStartsQ[packageName, packageContext]]]]];
    packageBaseNames = DeleteDuplicates[
      Last[StringSplit[#1, "`"]] & /@
        Flatten[System`Names[#1 <> "*"] & /@ packageContexts]];
    sourceCandidateNames = Intersection[
      globalNamesBefore, Union[qualifiedCensusNames, explicitScopeNames]];
    shadowNames = Select[globalNamesBefore,
      MemberQ[packageBaseNames, Last[StringSplit[#1, "`"]]] &];
    inspectedNames = Union[sourceCandidateNames, shadowNames];
    statesBefore = AssociationMap[
      symbolDefinitionStateByName, inspectedNames];
    dirtyDefinitionNames = Select[inspectedNames,
      ! definitionFreeStateQ[statesBefore[#1]] &];
    allowedDirtyNames = explicitScopeNames;
    unsafeDirtyDefinitionNames = Complement[
      dirtyDefinitionNames, allowedDirtyNames];
    unsafePackageShadowNames = Complement[shadowNames, allowedDirtyNames];
    packageDefinitionFingerprint[] := IntegerString[
      Hash[ToString[InputForm[AssociationMap[
        symbolDefinitionStateByName, existingPackageNames]]], "SHA256"], 16, 64];
    packageFingerprintBefore = packageDefinitionFingerprint[];
    feynCalcVersion = Quiet[Check[
      System`ToExpression["FeynCalc`$FeynCalcVersion"], $Failed]];
    feynArtsVersion = Quiet[Check[
      System`ToExpression["FeynArts`$FeynArtsVersion"], $Failed]];
    statesAfter = AssociationMap[
      symbolDefinitionStateByName, inspectedNames];
    packageFingerprintAfter = packageDefinitionFingerprint[];
    globalNamesAfter = System`Names["Global`*"];
    stateReadGateQ = TrueQ[
      AssociationQ[statesBefore] && FreeQ[Values[statesBefore], $Failed] &&
      SameQ[statesAfter, statesBefore]];
    readOnlyGateQ = TrueQ[
      SameQ[globalNamesAfter, globalNamesBefore] && stateReadGateQ];
    report = <|
      "Status" -> "CF300Sector12RecaptureV5bRecoveredK146GlobalStatePreflight",
      "GateQ" -> TrueQ[censusGateQ && readOnlyGateQ &&
        System`$KernelID === 146 &&
        Sort[packageListHazards] === Sort[
          {"CANONICA`", "FeynFacet`", "FeynArts`", "FeynCalc`"}] &&
        unsafeDirtyDefinitionNames === {} &&
        unsafePackageShadowNames === {} &&
        feynCalcVersion === "10.2.1" &&
        feynArtsVersion === "FeynArts 3.12 (27 Mar 2025)" &&
        StringMatchQ[packageFingerprintBefore,
          Repeated[HexadecimalCharacter, {64}]] &&
        packageFingerprintAfter === packageFingerprintBefore],
      "DriverSHA256" -> expectedDriverHash,
      "CensusSHA256" -> expectedCensusHash,
      "InspectorSHA256" -> expectedInspectorHash,
      "CensusNameCount" -> Length[qualifiedCensusNames],
      "ExplicitScopeNameCount" -> Length[explicitScopeNames],
      "GlobalNameCountBefore" -> Length[globalNamesBefore],
      "SourceCandidateExistingCount" -> Length[sourceCandidateNames],
      "PackageShadowCount" -> Length[shadowNames],
      "PackageShadows" -> Take[shadowNames, UpTo[40]],
      "ExistingRelevantPackageNameCount" -> Length[existingPackageNames],
      "ExistingRelevantPackageNames" ->
        Take[existingPackageNames, UpTo[40]],
      "RelevantPackageListHazardCount" -> Length[packageListHazards],
      "RelevantPackageListHazards" ->
        Take[packageListHazards, UpTo[40]],
      "InspectedNameCount" -> Length[inspectedNames],
      "DirtyDefinitionCount" -> Length[dirtyDefinitionNames],
      "DirtyDefinitionNames" -> Take[dirtyDefinitionNames, UpTo[40]],
      "UnsafeDirtyDefinitionNames" -> unsafeDirtyDefinitionNames,
      "UnsafePackageShadowNames" -> unsafePackageShadowNames,
      "PackageDefinitionFingerprintSHA256" -> packageFingerprintBefore,
      "PackageDefinitionFingerprintStableQ" ->
        SameQ[packageFingerprintAfter, packageFingerprintBefore],
      "FeynCalcVersion" -> feynCalcVersion,
      "FeynArtsVersion" -> feynArtsVersion,
      "FeynCalcEntryPointSHA256" -> hashHex[feynCalcEntryPoint],
      "FeynArtsEntryPointSHA256" -> hashHex[feynArtsEntryPoint],
      "DirtyDefinitionSummaries" -> AssociationMap[
        definitionSummary[statesBefore[#1]] &,
        Take[dirtyDefinitionNames, UpTo[20]]],
      "StateReadGateQ" -> stateReadGateQ,
      "GlobalNamespaceReadOnlyQ" -> readOnlyGateQ,
      "ImportMessages" -> importMessages|>;
    report["GateQ"] = TrueQ[report["GateQ"] &&
      Length[existingPackageNames] === 1685];
    report],
    <|"GateQ" -> False,
      "Failure" -> "caught abort in V5b preflight"|>];

  preflightResult
];

With[
  {resolvedReport = preflightFinalReport,
   resolvedNames = System`Join[
     System`Names["CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*"],
     System`Names[
       "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"]]},
  End[];
  EndPackage[];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"]];
  Quiet[System`Remove[
    "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*"]];
  With[{cleanupQ = System`Join[
      System`Names["CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`*"],
      System`Names[
        "CodexCF300Sector12RecaptureV5bRecoveredK146Preflight`Private`*"]] === {}},
    <|"Status" -> "CF300Sector12RecaptureV5bRecoveredK146PreflightEnvelope",
      "Report" -> resolvedReport,
      "DedicatedNameCleanupQ" -> cleanupQ,
      "NamesBeforeCleanupCount" -> Length[resolvedNames]|>]]
