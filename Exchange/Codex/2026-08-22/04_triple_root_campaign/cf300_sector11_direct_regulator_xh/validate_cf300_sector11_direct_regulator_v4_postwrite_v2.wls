#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300Sector11PostwriteValidatorV2`"];
Begin["`Private`"];
Quiet[ClearAll["CodexCF300Sector11PostwriteValidatorV2`Private`*"]];

artifactContext = "CodexCF300Sector11RegulatorStateSymbolsV4`";
validatorExitTag = "CodexCF300Sector11PostwriteValidatorV2Exit";
validatorExit[code_Integer] := Throw[code, validatorExitTag];
bootstrapExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove["CodexCF300Sector11PostwriteValidatorV2`*"]];
   System`Exit[code]);

expectedInputFile =
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/" <>
  "CF300/sector_state_CF300_standard.wl";
expectedOutputFile =
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/" <>
  "CF300_direct_regulator_v4_candidate/sector_state_CF300_standard.wl";
expectedReportFile =
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-23/" <>
  "CF300_direct_regulator_v4_candidate/" <>
  "cf300_sector11_direct_regulator_report_v4.wl";
expectedFormalResultFile =
  "/home/maxzhang/factorization-and-loops/External/CodexExchange/" <>
  "triple_root_2026-08-22/cf300_sector11_direct_regulator_xh/" <>
  "cf300_sector11_postwrite_formal_inspector_v4_result.json";
expectedInputHash =
  "898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12";
expectedOutputHash =
  "daf3e994492b2b324d21f490f0436af941f53e7e472710cb2d3d88d891df9009";
expectedReportHash =
  "eec3a0b3120cb7109c300fdf0ac46a9c255d7307e3f7227a5f5a359bdc9d9a7e";
expectedInputBytes = 33012365;
expectedOutputBytes = 33009263;
expectedReportBytes = 3752;
expectedDriverHash =
  "369a05cfcc761b265059839365939cb06acbeb6e0bd9e67cf3f651706f5c3b6c";
expectedFormalInspectorHash =
  "554248efd8e62d293c8a4bfcef0e6774945b36b43965a8a65297d9609b764a8b";
expectedFormalResultHash =
  "18dbe8754e2feffa58e022dd582e5910f5cea6b5f6af3595d01dda7993a40128";
expectedFormalResultBytes = 966;
expectedPriorInspectorHash =
  "036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3";

globalDefinitionSnapshot[] := <|
  "x" -> {OwnValues[Global`x], DownValues[Global`x],
    UpValues[Global`x], SubValues[Global`x], NValues[Global`x],
    DefaultValues[Global`x], FormatValues[Global`x],
    Attributes[Global`x]},
  "y" -> {OwnValues[Global`y], DownValues[Global`y],
    UpValues[Global`y], SubValues[Global`y], NValues[Global`y],
    DefaultValues[Global`y], FormatValues[Global`y],
    Attributes[Global`y]},
  "eps" -> {OwnValues[Global`eps], DownValues[Global`eps],
    UpValues[Global`eps], SubValues[Global`eps], NValues[Global`eps],
    DefaultValues[Global`eps], FormatValues[Global`eps],
    Attributes[Global`eps]}|>;
SetAttributes[definitionFreeHeldQ, HoldAll];
definitionFreeHeldQ[symbol_Symbol] := TrueQ[
  OwnValues[symbol] === {} && DownValues[symbol] === {} &&
  UpValues[symbol] === {} && SubValues[symbol] === {} &&
  NValues[symbol] === {} && DefaultValues[symbol] === {} &&
  FormatValues[symbol] === {} && Attributes[symbol] === {}];
definitionFreeHeldQ[___] := False;
definitionFreeByNameQ[name_String] := ToExpression[
  name, InputForm,
  Function[heldSymbol, definitionFreeHeldQ[heldSymbol], HoldAll]];
dedicatedSymbolsCleanQ[] := Module[{names},
  names = Names[artifactContext <> "*"];
  Sort[Last[StringSplit[#1, "`"]] & /@ names] ===
      {"eps", "x", "y"} && AllTrue[names, definitionFreeByNameQ]];
removeDedicatedContext[] := Module[{names, outcome},
  names = Names[artifactContext <> "*"];
  outcome = If[names === {}, Null,
    Quiet[Check[Apply[Remove, names], $Failed]]];
  TrueQ[outcome =!= $Failed && Names[artifactContext <> "*"] === {}]];

artifactReadTelemetry = <||>;
artifactRead[file_String, label_String] := Module[{value, messages},
  Block[{$MessageList = {}},
    value = Quiet[CheckAbort[Get[file], $Aborted]];
    messages = ToString[InputForm[#1]] & /@ $MessageList];
  artifactReadTelemetry[label] = <|
    "Messages" -> messages,
    "ReturnedHead" -> ToString[InputForm[Head[value]]]|>;
  value];
exactEntryEqualQ[left_, right_] := SameQ[left, right] ||
  TrueQ[Together[left - right] === 0];
makePropagationSeal[inputPrefix_, outputPrefix_, transformation_,
    inverse_, inputStateHash_String] := Module[{payload},
  payload = <|
    "Schema" -> "CF300DirectScalarRegulatorPropagationSeal",
    "SchemaVersion" -> 1,
    "InputStateSHA256" -> inputStateHash,
    "InputPrefixSHA256" ->
      Hash[inputPrefix, "SHA256", "HexString"],
    "OutputPrefixSHA256" ->
      Hash[outputPrefix, "SHA256", "HexString"],
    "TransformationScalarSHA256" ->
      Hash[transformation, "SHA256", "HexString"],
    "InverseScalarSHA256" ->
      Hash[inverse, "SHA256", "HexString"],
    "RegulatorDependentSubspace" -> {21, 22}|>;
  Join[payload, <|"Fingerprint" ->
    Hash[KeySort[payload], "SHA256", "HexString"]|>]];
matrixProductIdentityAudit[left_List, right_List] := Module[
  {dimension, validQ = True, firstFailure = Missing["None"],
    row, column, index, terms, value, target},
  dimension = Length[left];
  If[Dimensions[left] =!= {dimension, dimension} ||
      Dimensions[right] =!= {dimension, dimension},
    Return[<|"IdentityQ" -> False,
      "FirstFailure" -> Missing["InvalidDimensions"]|>]];
  Do[
    terms = Table[
      If[SameQ[left[[row, index]], 0] ||
          SameQ[right[[index, column]], 0], Nothing,
        left[[row, index]]*right[[index, column]]],
      {index, dimension}];
    value = Total[terms];
    target = If[row === column, 1, 0];
    If[! TrueQ[exactEntryEqualQ[value, target]],
      validQ = False;
      If[MissingQ[firstFailure], firstFailure = {row, column}]],
    {row, dimension}, {column, dimension}];
  <|"IdentityQ" -> validQ, "FirstFailure" -> firstFailure|>];

If[Names[artifactContext <> "*"] =!= {},
  Print["CF300_S11_POSTWRITE_V4 FAIL dedicated context preexists"];
  bootstrapExit[62]];

globalStateBefore = globalDefinitionSnapshot[];
dedicatedRuntimeCode = CheckAbort[
  Block[{$Context = artifactContext,
      $ContextPath = {"System`", artifactContext,
        "CodexCF300Sector11PostwriteValidatorV2`"}},
    Catch[
      arguments = Rest[$ScriptCommandLine];
      If[Length[arguments] =!= 4,
        Print["CF300_S11_POSTWRITE_V4 FAIL usage=<input> <output> " <>
          "<report> <formal-result.json>"];
        validatorExit[64]];
      inputFile = ExpandFileName[arguments[[1]]];
      outputFile = ExpandFileName[arguments[[2]]];
      reportFile = ExpandFileName[arguments[[3]]];
      formalResultFile = ExpandFileName[arguments[[4]]];
      If[{inputFile, outputFile, reportFile, formalResultFile} =!=
          {expectedInputFile, expectedOutputFile, expectedReportFile,
            expectedFormalResultFile},
        Print["CF300_S11_POSTWRITE_V4 FAIL noncanonical artifact paths"];
        validatorExit[64]];

      bundleDirectory = DirectoryName[$InputFileName];
      driverFile = FileNameJoin[{bundleDirectory,
        "run_cf300_sector11_direct_scalar_regulator_continuation_v4.wls"}];
      formalInspectorFile = FileNameJoin[{bundleDirectory,
        "inspect_cf300_sector11_postwrite_v4.py"}];
      priorInspectorFile = FileNameJoin[{bundleDirectory,
        "inspect_cf300_sector11_regulator_structure_v2.py"}];
      candidateDirectory = DirectoryName[outputFile];
      staleCandidates = {
        outputFile <> ".tmp", reportFile <> ".tmp",
        outputFile <> ".part", reportFile <> ".part",
        outputFile <> ".partial", reportFile <> ".partial",
        outputFile <> ".new", reportFile <> ".new"};
      visibleCandidateFiles = Sort[ExpandFileName /@
        FileNames["*", candidateDirectory]];
      filesystemGate = TrueQ[
        DirectoryQ[candidateDirectory] &&
        AllTrue[{inputFile, outputFile, reportFile, driverFile,
            formalInspectorFile, formalResultFile, priorInspectorFile},
          FileExistsQ] &&
        visibleCandidateFiles === Sort[{outputFile, reportFile}] &&
        NoneTrue[staleCandidates, FileExistsQ] &&
        FileByteCount[inputFile] === expectedInputBytes &&
        FileByteCount[outputFile] === expectedOutputBytes &&
        FileByteCount[reportFile] === expectedReportBytes &&
        FileByteCount[formalResultFile] === expectedFormalResultBytes];
      If[! filesystemGate,
        Print["CF300_S11_POSTWRITE_V4 FAIL missing/stale artifact"];
        validatorExit[65]];

      inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
      outputHashBefore = FileHash[outputFile, "SHA256", "HexString"];
      reportHashBefore = FileHash[reportFile, "SHA256", "HexString"];
      driverHashBefore = FileHash[driverFile, "SHA256", "HexString"];
      formalInspectorHashBefore =
        FileHash[formalInspectorFile, "SHA256", "HexString"];
      formalResultHashBefore =
        FileHash[formalResultFile, "SHA256", "HexString"];
      priorInspectorHashBefore =
        FileHash[priorInspectorFile, "SHA256", "HexString"];
      sourceAndArtifactPinsQ = TrueQ[
        inputHashBefore === expectedInputHash &&
        outputHashBefore === expectedOutputHash &&
        reportHashBefore === expectedReportHash &&
        driverHashBefore === expectedDriverHash &&
        formalInspectorHashBefore === expectedFormalInspectorHash &&
        formalResultHashBefore === expectedFormalResultHash &&
        priorInspectorHashBefore === expectedPriorInspectorHash];
      If[! sourceAndArtifactPinsQ,
        Print["CF300_S11_POSTWRITE_V4 FAIL source/artifact hash mismatch"];
        validatorExit[66]];

      formalResultMessages = {};
      Block[{$MessageList = {}},
        formalResult = Quiet[CheckAbort[
          Import[formalResultFile, "RawJSON"], $Aborted]];
        formalResultMessages =
          ToString[InputForm[#1]] & /@ $MessageList];
      formalGate = TrueQ[
        formalResult =!= $Aborted && formalResultMessages === {} &&
        AssociationQ[formalResult] &&
        Lookup[formalResult, "Status", None] === "PASS" &&
        Lookup[formalResult, "InputStateSHA256", None] ===
          expectedInputHash &&
        Lookup[formalResult, "OutputStateSHA256", None] ===
          expectedOutputHash &&
        Lookup[formalResult, "FormalPrefixEntriesChecked", None] === 968 &&
        Lookup[formalResult, "FormalEpsilonNonzeroChannels", None] === 317 &&
        Lookup[formalResult, "FormalZeroChannels", None] === 651 &&
        Lookup[formalResult, "PrefixToFutureZeroChannels", None] === 88 &&
        Lookup[formalResult, "OldPrefixEntrywiseUnchangedQ", None] === True &&
        Lookup[formalResult, "AlgebraicallyEliminatedInputChannels", None] ===
          {{1, 22, 11}}];
      Print["CF300_S11_POSTWRITE_V4 formal_inspector=",
        InputForm[<|"GateQ" -> formalGate,
          "PinnedResultSHA256" -> formalResultHashBefore,
          "Messages" -> formalResultMessages,
          "Result" -> formalResult|>]];
      If[! formalGate, validatorExit[67]];

      inputState = artifactRead[inputFile, "InputState"];
      outputState = artifactRead[outputFile, "OutputState"];
      report = artifactRead[reportFile, "Report"];
      stateNames = Names[artifactContext <> "*"];
      epsilon = Symbol[artifactContext <> "eps"];
      xVariable = Symbol[artifactContext <> "x"];
      yVariable = Symbol[artifactContext <> "y"];
      hydrationGate = TrueQ[
        AssociationQ[inputState] && AssociationQ[outputState] &&
        AssociationQ[report] && dedicatedSymbolsCleanQ[] &&
        AllTrue[Values[artifactReadTelemetry],
          Lookup[#1, "Messages", $Failed] === {} &] &&
        SameQ[globalDefinitionSnapshot[], globalStateBefore]];
      Print["CF300_S11_POSTWRITE_V4 hydration=",
        InputForm[<|"GateQ" -> hydrationGate,
          "Telemetry" -> artifactReadTelemetry,
          "DedicatedNames" -> stateNames,
          "DedicatedSymbolsCleanQ" -> dedicatedSymbolsCleanQ[],
          "GlobalStateUnchangedQ" ->
            SameQ[globalDefinitionSnapshot[], globalStateBefore]|>]];
      If[! hydrationGate, validatorExit[68]];

      inputFactors = Lookup[inputState, "RegulatorFactorizations", $Failed];
      outputFactors = Lookup[outputState, "RegulatorFactorizations", $Failed];
      outputCertificates = Lookup[outputState, "SectorCertificates", $Failed];
      outputStripSolvers = Lookup[outputState, "StripSolvers", $Failed];
      factorRecord = If[ListQ[outputFactors] && outputFactors =!= {},
        Last[outputFactors], $Failed];
      unchangedKeys = {"Sector", "OriginalA", "Ranges", "Blocks",
        "ChartFingerprint", "StripSolvers", "SectorCertificates",
        "TDiagonal", "TDiagonalInverse"};
      unchangedMetadataQ = AllTrue[unchangedKeys,
        SameQ[Lookup[inputState, #1, $Failed],
          Lookup[outputState, #1, $Failed]] &];
      sector12RecaptureRequiredQ = TrueQ[
        Lookup[outputState, "Sector", None] === 11 &&
        ! KeyExistsQ[outputState, "Stop"] &&
        ListQ[outputCertificates] && Length[outputCertificates] === 10 &&
        ! AnyTrue[outputCertificates,
          Lookup[#1, "Sector", None] === 12 &] &&
        ListQ[outputStripSolvers] &&
        ! AnyTrue[outputStripSolvers,
          Lookup[#1, "Sector", None] === 12 &]];
      familySectorDimensionGate = TrueQ[
        Lookup[inputState, "Sector", None] === 11 &&
        Lookup[outputState, "Sector", None] === 11 &&
        Lookup[outputState, "Ranges", $Failed][[11]] === {21, 22} &&
        Lookup[outputState, "Ranges", $Failed][[12]] === {23, 24} &&
        Dimensions[Lookup[inputState, "A", {}]] === {2, 24, 24} &&
        Dimensions[Lookup[outputState, "A", {}]] === {2, 24, 24} &&
        Dimensions[Lookup[inputState, "S", {}]] === {24, 24} &&
        Dimensions[Lookup[outputState, "S", {}]] === {24, 24} &&
        Dimensions[Lookup[inputState, "SInverse", {}]] === {24, 24} &&
        Dimensions[Lookup[outputState, "SInverse", {}]] === {24, 24} &&
        unchangedMetadataQ && sector12RecaptureRequiredQ &&
        ListQ[inputFactors] && Length[inputFactors] === 9 &&
        ListQ[outputFactors] && Length[outputFactors] === 10 &&
        SameQ[Take[outputFactors, 9], inputFactors] &&
        AssociationQ[factorRecord] &&
        Lookup[factorRecord, "Rows", None] === 11 &&
        Lookup[factorRecord, "RootIndices", None] === {1, 2, 3} &&
        Lookup[factorRecord, "RegulatorDependentSubspace", None] ===
          {21, 22}];
      reportGate = TrueQ[
        Lookup[report, "Status", None] === "OK" &&
        Lookup[report, "Schema", None] ===
          "CF300Sector11DirectScalarRegulatorContinuation" &&
        Lookup[report, "SchemaVersion", None] === 4 &&
        Lookup[report, "InputState", None] === inputFile &&
        Lookup[report, "InputStateSHA256", None] === expectedInputHash &&
        Lookup[report, "FormalInspectorSHA256", None] ===
          expectedPriorInspectorHash &&
        Lookup[report, "DriverSHA256", None] === expectedDriverHash &&
        Lookup[report, "OutputState", None] === outputFile &&
        Lookup[report, "OutputStateSHA256", None] === expectedOutputHash &&
        Lookup[report, "OutputStateBytes", None] === expectedOutputBytes &&
        Lookup[Lookup[report, "ArtifactReadTelemetry", <||>],
          "Messages", $Failed] === {} &&
        Lookup[report, "GlobalStateUnchangedBeforeCommitQ", None] === True &&
        Lookup[report, "TransformationNonzeroRationalFunctionQ", None] === True &&
        Lookup[report, "ExceptionalEpsilonValues", None] ===
          {0, 1/3, 1/2, 2/3} &&
        Lookup[report, "PropagationSealRecomputedQ", None] === True];
      Print["CF300_S11_POSTWRITE_V4 metadata=",
        InputForm[<|"FamilySectorDimensionGateQ" ->
            familySectorDimensionGate,
          "UnchangedMetadataQ" -> unchangedMetadataQ,
          "Sector12RecaptureRequiredQ" -> sector12RecaptureRequiredQ,
          "ReportGateQ" -> reportGate|>]];
      If[! TrueQ[familySectorDimensionGate && reportGate],
        validatorExit[69]];

      regulatorPolynomial =
        (2*epsilon - 1)*(3*epsilon - 1)*(3*epsilon - 2);
      lowerLeftScalar = Together[regulatorPolynomial/epsilon^2];
      transformation = Together[regulatorPolynomial/epsilon^3];
      inverseScalar = Together[1/transformation];
      rowScales = Table[
        If[MemberQ[{21, 22}, row], inverseScalar, 1], {row, 24}];
      columnScales = Table[
        If[MemberQ[{21, 22}, column], transformation, 1],
        {column, 24}];
      poleOrderAtEpsilonZero =
        Exponent[Denominator[Together[transformation]], epsilon];
      scalarFieldGate = TrueQ[
        Together[inverseScalar*lowerLeftScalar - epsilon] === 0 &&
        Together[transformation*inverseScalar - 1] === 0 &&
        Together[epsilon*transformation - lowerLeftScalar] === 0 &&
        FreeQ[{transformation, inverseScalar},
          Alternatives[xVariable, yVariable]] &&
        Together[D[transformation, xVariable]] === 0 &&
        Together[D[transformation, yVariable]] === 0 &&
        PolynomialQ[Numerator[Together[transformation]], epsilon] &&
        PolynomialQ[Denominator[Together[transformation]], epsilon] &&
        poleOrderAtEpsilonZero === 3 &&
        (Numerator[Together[transformation]] /. epsilon -> 0) =!= 0 &&
        Lookup[factorRecord, "TransformationNonzeroRationalFunction", None] ===
          True &&
        Lookup[factorRecord, "ExceptionalEpsilonValues", None] ===
          {0, 1/3, 1/2, 2/3}];
      Print["CF300_S11_POSTWRITE_V4 scalar_field=",
        InputForm[<|"GateQ" -> scalarFieldGate,
          "Convention" -> "G=diag(I20,t I2,I2); Anew=G^-1 Aold G",
          "CoefficientField" -> "Q(x,y,roots)(eps)",
          "KinematicDerivativesZeroQ" -> TrueQ[
            Together[D[transformation, xVariable]] === 0 &&
            Together[D[transformation, yVariable]] === 0],
          "PoleOrderAtEpsilonZero" -> poleOrderAtEpsilonZero,
          "RequiredEpsilonExpansionDepthShift" -> 3|>]];
      If[! scalarFieldGate, validatorExit[70]];

      identityAudit = TimeConstrained[Module[
        {aIdentityQ = True, sIdentityQ = True,
          sInverseIdentityQ = True,
          firstA = Missing["None"], firstS = Missing["None"],
          firstSInverse = Missing["None"], expected, actual,
          mu, row, column},
        Do[
          expected = rowScales[[row]]*
            inputState["A"][[mu, row, column]]*
            columnScales[[column]];
          actual = outputState["A"][[mu, row, column]];
          If[! TrueQ[exactEntryEqualQ[actual, expected]],
            aIdentityQ = False;
            If[MissingQ[firstA], firstA = {mu, row, column}]],
          {mu, 2}, {row, 24}, {column, 24}];
        Do[
          expected = inputState["S"][[row, column]]*
            columnScales[[column]];
          actual = outputState["S"][[row, column]];
          If[! TrueQ[exactEntryEqualQ[actual, expected]],
            sIdentityQ = False;
            If[MissingQ[firstS], firstS = {row, column}]],
          {row, 24}, {column, 24}];
        Do[
          expected = rowScales[[row]]*
            inputState["SInverse"][[row, column]];
          actual = outputState["SInverse"][[row, column]];
          If[! TrueQ[exactEntryEqualQ[actual, expected]],
            sInverseIdentityQ = False;
            If[MissingQ[firstSInverse],
              firstSInverse = {row, column}]],
          {row, 24}, {column, 24}];
        <|"AIdentityQ" -> aIdentityQ, "FirstAFailure" -> firstA,
          "SIdentityQ" -> sIdentityQ, "FirstSFailure" -> firstS,
          "SInverseIdentityQ" -> sInverseIdentityQ,
          "FirstSInverseFailure" -> firstSInverse|>], 300, $Aborted];
      identityGate = TrueQ[AssociationQ[identityAudit] &&
        Lookup[identityAudit, "AIdentityQ", False] &&
        Lookup[identityAudit, "SIdentityQ", False] &&
        Lookup[identityAudit, "SInverseIdentityQ", False]];
      Print["CF300_S11_POSTWRITE_V4 propagation_identities=",
        InputForm[<|"GateQ" -> identityGate,
          "Audit" -> identityAudit|>]];
      If[! identityGate, validatorExit[71]];

      changedAudit = TimeConstrained[Module[
        {lowerQ = True, diagonalQ = True, futureQ = True,
          prefixFutureQ, upperRightQ, lowerCount = 0,
          diagonalCount = 0, futureCount = 0,
          outputLowerCount = 0, firstLower = Missing["None"],
          firstDiagonal = Missing["None"],
          firstFuture = Missing["None"],
          wrongLowerWitness = Missing["None"],
          wrongFutureWitness = Missing["None"], old, new, coefficient,
          mu, row, column},
        Do[
          old = inputState["A"][[mu, row, column]];
          new = outputState["A"][[mu, row, column]];
          If[! SameQ[new, 0], outputLowerCount++];
          If[SameQ[old, 0],
            If[! SameQ[new, 0], lowerQ = False;
              If[MissingQ[firstLower], firstLower = {mu, row, column}]],
            lowerCount++;
            coefficient = Together[old/lowerLeftScalar];
            If[! TrueQ[FreeQ[coefficient, epsilon] &&
                exactEntryEqualQ[new, epsilon*coefficient]],
              lowerQ = False;
              If[MissingQ[firstLower], firstLower = {mu, row, column}]];
            If[MissingQ[wrongLowerWitness] &&
                ! TrueQ[exactEntryEqualQ[new, transformation*old]],
              wrongLowerWitness = {mu, row, column}]],
          {mu, 2}, {row, 21, 22}, {column, 1, 20}];
        Do[
          old = inputState["A"][[mu, row, column]];
          new = outputState["A"][[mu, row, column]];
          If[! SameQ[old, 0],
            diagonalCount++;
            coefficient = Together[new/epsilon];
            If[! TrueQ[exactEntryEqualQ[new, old] &&
                FreeQ[coefficient, epsilon]],
              diagonalQ = False;
              If[MissingQ[firstDiagonal],
                firstDiagonal = {mu, row, column}]],
            If[! SameQ[new, 0], diagonalQ = False;
              If[MissingQ[firstDiagonal],
                firstDiagonal = {mu, row, column}]]],
          {mu, 2}, {row, 21, 22}, {column, 21, 22}];
        Do[
          old = inputState["A"][[mu, row, column]];
          new = outputState["A"][[mu, row, column]];
          If[! SameQ[old, 0],
            futureCount++;
            If[! TrueQ[exactEntryEqualQ[new, old*transformation]],
              futureQ = False;
              If[MissingQ[firstFuture],
                firstFuture = {mu, row, column}]];
            If[MissingQ[wrongFutureWitness] &&
                ! TrueQ[exactEntryEqualQ[new, old*inverseScalar]],
              wrongFutureWitness = {mu, row, column}],
            If[! SameQ[new, 0], futureQ = False;
              If[MissingQ[firstFuture],
                firstFuture = {mu, row, column}]]],
          {mu, 2}, {row, 23, 24}, {column, 21, 22}];
        prefixFutureQ = AllTrue[
          Flatten[outputState["A"][[All, 1 ;; 22, 23 ;; 24]]],
          SameQ[#1, 0] &];
        upperRightQ = AllTrue[
          Flatten[outputState["A"][[All, 1 ;; 20, 21 ;; 22]]],
          SameQ[#1, 0] &];
        <|"LowerLeftIdentityQ" -> lowerQ,
          "FirstLowerLeftFailure" -> firstLower,
          "InputLowerLeftChannels" -> lowerCount,
          "OutputLowerLeftChannels" -> outputLowerCount,
          "DiagonalIdentityQ" -> diagonalQ,
          "FirstDiagonalFailure" -> firstDiagonal,
          "DiagonalChannels" -> diagonalCount,
          "FutureIdentityQ" -> futureQ,
          "FirstFutureFailure" -> firstFuture,
          "FutureChannels" -> futureCount,
          "PrefixToFutureZeroQ" -> prefixFutureQ,
          "PrefixToFutureZeroChannels" -> 88,
          "UpperRightZeroQ" -> upperRightQ,
          "UpperRightZeroChannels" -> 80,
          "WrongSideLowerLeftRejectedQ" ->
            ! MissingQ[wrongLowerWitness],
          "WrongSideLowerLeftWitness" -> wrongLowerWitness,
          "WrongSideFutureRejectedQ" ->
            ! MissingQ[wrongFutureWitness],
          "WrongSideFutureWitness" -> wrongFutureWitness|>],
        300, $Aborted];
      changedGate = TrueQ[AssociationQ[changedAudit] &&
        Lookup[changedAudit, "LowerLeftIdentityQ", False] &&
        Lookup[changedAudit, "InputLowerLeftChannels", None] === 26 &&
        Lookup[changedAudit, "OutputLowerLeftChannels", None] === 25 &&
        Lookup[changedAudit, "DiagonalIdentityQ", False] &&
        Lookup[changedAudit, "DiagonalChannels", None] === 8 &&
        Lookup[changedAudit, "FutureIdentityQ", False] &&
        Lookup[changedAudit, "FutureChannels", None] === 8 &&
        Lookup[changedAudit, "PrefixToFutureZeroQ", False] &&
        Lookup[changedAudit, "UpperRightZeroQ", False] &&
        Lookup[changedAudit, "WrongSideLowerLeftRejectedQ", False] &&
        Lookup[changedAudit, "WrongSideFutureRejectedQ", False]];
      Print["CF300_S11_POSTWRITE_V4 changed_blocks=",
        InputForm[<|"GateQ" -> changedGate,
          "Audit" -> changedAudit|>]];
      If[! changedGate, validatorExit[73]];

      inverseAudit = TimeConstrained[
        <|"Right" -> matrixProductIdentityAudit[
            outputState["S"], outputState["SInverse"]],
          "Left" -> matrixProductIdentityAudit[
            outputState["SInverse"], outputState["S"]]|>,
        600, $Aborted];
      inverseGate = TrueQ[AssociationQ[inverseAudit] &&
        Lookup[inverseAudit["Right"], "IdentityQ", False] &&
        Lookup[inverseAudit["Left"], "IdentityQ", False]];
      Print["CF300_S11_POSTWRITE_V4 inverse_consistency=",
        InputForm[<|"GateQ" -> inverseGate,
          "Audit" -> inverseAudit|>]];
      If[! inverseGate, validatorExit[74]];

      recomputedSeal = makePropagationSeal[
        inputState["A"][[All, 1 ;; 22, 1 ;; 22]],
        outputState["A"][[All, 1 ;; 22, 1 ;; 22]],
        transformation, inverseScalar, expectedInputHash];
      sealGate = TrueQ[
        SameQ[Lookup[report, "PropagationSeal", $Failed],
          recomputedSeal] &&
        SameQ[Lookup[factorRecord, "PropagationSeal", $Failed],
          recomputedSeal] &&
        Lookup[recomputedSeal, "Fingerprint", Missing["None"]] ===
          Lookup[Lookup[report, "PropagationSeal", <||>],
            "Fingerprint", Missing["Other"]]];
      Print["CF300_S11_POSTWRITE_V4 seal=",
        InputForm[<|"GateQ" -> sealGate,
          "Fingerprint" -> Lookup[recomputedSeal, "Fingerprint",
            Missing["None"]]|>]];
      If[! sealGate, validatorExit[75]];

      hashesAfter = <|
        "InputStateSHA256" -> FileHash[inputFile, "SHA256", "HexString"],
        "OutputStateSHA256" -> FileHash[outputFile, "SHA256", "HexString"],
        "ReportSHA256" -> FileHash[reportFile, "SHA256", "HexString"],
        "DriverSHA256" -> FileHash[driverFile, "SHA256", "HexString"],
        "FormalInspectorSHA256" ->
          FileHash[formalInspectorFile, "SHA256", "HexString"],
        "FormalResultSHA256" ->
          FileHash[formalResultFile, "SHA256", "HexString"]|>;
      finalArtifactGate = TrueQ[
        hashesAfter === <|
          "InputStateSHA256" -> expectedInputHash,
          "OutputStateSHA256" -> expectedOutputHash,
          "ReportSHA256" -> expectedReportHash,
          "DriverSHA256" -> expectedDriverHash,
          "FormalInspectorSHA256" -> expectedFormalInspectorHash,
          "FormalResultSHA256" -> expectedFormalResultHash|> &&
        Sort[ExpandFileName /@ FileNames["*", candidateDirectory]] ===
          Sort[{outputFile, reportFile}] &&
        NoneTrue[staleCandidates, FileExistsQ] &&
        SameQ[globalDefinitionSnapshot[], globalStateBefore]];
      If[! finalArtifactGate, validatorExit[76]];

      Print["CF300_S11_POSTWRITE_V4 PASS ",
        InputForm[<|
          "Family" -> "CF300", "CompletedSector" -> 11,
          "NextRequiredSector" -> 12,
          "Sector12RecaptureRequiredQ" -> sector12RecaptureRequiredQ,
          "OutputStateSHA256" -> expectedOutputHash,
          "ReportSHA256" -> expectedReportHash,
          "FormalDegreeFingerprintSHA256" ->
            Lookup[formalResult,
              "OutputPrefixDegreeFingerprintSHA256", Missing["None"]],
          "PropagationSealFingerprint" ->
            Lookup[recomputedSeal, "Fingerprint", Missing["None"]],
          "FullTransformedVsPriorConnectionReconstructionQ" ->
            Lookup[identityAudit, "AIdentityQ", False],
          "InverseConsistencyQ" -> inverseGate,
          "RequiredEpsilonExpansionDepthShift" -> 3|>]];
      validatorExit[0], validatorExitTag]],
  $Aborted];

inputState =.; outputState =.; report =.; inputFactors =.; outputFactors =.;
outputCertificates =.; outputStripSolvers =.; factorRecord =.;
regulatorPolynomial =.; lowerLeftScalar =.; transformation =.;
inverseScalar =.; rowScales =.; columnScales =.;
formalResult =.; identityAudit =.; changedAudit =.;
inverseAudit =.; recomputedSeal =.; epsilon =.; xVariable =.; yVariable =.;
dedicatedContextRemovedQ = removeDedicatedContext[];
globalStateUnchangedQ =
  SameQ[globalDefinitionSnapshot[], globalStateBefore];
finalCode = Which[
  dedicatedRuntimeCode === $Aborted, 90,
  ! IntegerQ[dedicatedRuntimeCode], 91,
  dedicatedRuntimeCode =!= 0, dedicatedRuntimeCode,
  ! TrueQ[dedicatedContextRemovedQ && globalStateUnchangedQ], 92,
  True, 0];
Print["CF300_S11_POSTWRITE_V4 cleanup=",
  InputForm[<|"DedicatedContextRemovedQ" -> dedicatedContextRemovedQ,
    "GlobalStateUnchangedQ" -> globalStateUnchangedQ,
    "ExitCode" -> finalCode|>]];

End[];
EndPackage[];
System`Exit[CodexCF300Sector11PostwriteValidatorV2`Private`finalCode];
