#!/usr/bin/env wolframscript

$HistoryLength = 0;
BeginPackage["CodexCF300Sector11DirectRegulatorContinuationV4`"];
Begin["`Private`"];
Quiet[ClearAll[
  "CodexCF300Sector11DirectRegulatorContinuationV4`Private`*"]];

artifactContext = "CodexCF300Sector11RegulatorStateSymbolsV4`";
continuationExitTag =
  "CodexCF300Sector11DirectRegulatorContinuationV4Exit";
continuationExit[code_Integer] := Throw[code, continuationExitTag];
bootstrapExit[code_Integer] :=
  (End[]; EndPackage[];
   Quiet[Remove[
     "CodexCF300Sector11DirectRegulatorContinuationV4`*"]];
   System`Exit[code]);

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
  TrueQ[outcome =!= $Failed &&
    Names[artifactContext <> "*"] === {}]];

expectedStateHash =
  "898e4283c39fcdb457b7857a4609e48b5ca0417b1d06cb07750779b187c33a12";
expectedStateBytes = 33012365;
expectedInspectorHash =
  "036d15b1735efd30a0b0f1049559b7f61c84edc662a94d3eae806953589944c3";
artifactReadTelemetry = <||>;
artifactRead[file_String] := Module[{value, messages},
  Block[{$MessageList = {}},
    value = Quiet[CheckAbort[Get[file], $Aborted]];
    messages = ToString[InputForm[#1]] & /@ $MessageList];
  artifactReadTelemetry = <|
    "Messages" -> messages,
    "ReturnedHead" -> ToString[InputForm[Head[value]]]|>;
  value];
safeRemoveTemporary[file_String] := If[FileExistsQ[file],
  Quiet[Check[DeleteFile[file], $Failed]], Null];
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

If[Names[artifactContext <> "*"] =!= {},
  Print["CF300_S11_DIRECT_REGULATOR FAIL dedicated context preexists"];
  bootstrapExit[62]];

globalStateBefore = globalDefinitionSnapshot[];
temporaryFiles = {};
dedicatedRuntimeCode = CheckAbort[
  Block[{$Context = artifactContext,
      $ContextPath = {"System`", artifactContext,
        "CodexCF300Sector11DirectRegulatorContinuationV4`"}},
    Catch[
      arguments = Rest[$ScriptCommandLine];
      If[Length[arguments] =!= 3,
        Print["CF300_S11_DIRECT_REGULATOR FAIL usage=<input-state.wl> " <>
          "<output-state.wl> <report.wl>"];
        continuationExit[64]];

      inputFile = ExpandFileName[arguments[[1]]];
      outputFile = ExpandFileName[arguments[[2]]];
      reportFile = ExpandFileName[arguments[[3]]];
      inspectorFile = FileNameJoin[{DirectoryName[$InputFileName],
        "inspect_cf300_sector11_regulator_structure_v2.py"}];
      temporaryOutput = outputFile <> ".tmp";
      temporaryReport = reportFile <> ".tmp";
      temporaryFiles = {temporaryOutput, temporaryReport};
      If[! FileExistsQ[inputFile] ||
          FileByteCount[inputFile] =!= expectedStateBytes ||
          ! FileExistsQ[inspectorFile] ||
          ! DirectoryQ[DirectoryName[outputFile]] ||
          ! DirectoryQ[DirectoryName[reportFile]] ||
          ! DuplicateFreeQ[{inputFile, outputFile, reportFile,
              temporaryOutput, temporaryReport}] ||
          AnyTrue[{outputFile, reportFile, temporaryOutput,
              temporaryReport}, FileExistsQ],
        Print["CF300_S11_DIRECT_REGULATOR FAIL invalid target or stale output"];
        continuationExit[65]];

      driverHashBefore =
        FileHash[$InputFileName, "SHA256", "HexString"];
      inputHashBefore = FileHash[inputFile, "SHA256", "HexString"];
      inspectorHashBefore =
        FileHash[inspectorFile, "SHA256", "HexString"];
      If[inputHashBefore =!= expectedStateHash ||
          inspectorHashBefore =!= expectedInspectorHash,
        Print["CF300_S11_DIRECT_REGULATOR FAIL pinned input mismatch"];
        continuationExit[66]];

      state = artifactRead[inputFile];
      stateNames = Names[artifactContext <> "*"];
      epsilon = Symbol[artifactContext <> "eps"];
      xVariable = Symbol[artifactContext <> "x"];
      yVariable = Symbol[artifactContext <> "y"];
      stop = If[AssociationQ[state], Lookup[state, "Stop", $Failed],
        $Failed];
      factors = If[AssociationQ[state],
        Lookup[state, "RegulatorFactorizations", $Failed], $Failed];
      certificates = If[AssociationQ[state],
        Lookup[state, "SectorCertificates", $Failed], $Failed];
      expectedRootSquares = {
        1 + 2*xVariable + xVariable^2 - 2*yVariable +
          2*xVariable*yVariable + yVariable^2,
        1 - 2*xVariable + xVariable^2 + 2*yVariable +
          2*xVariable*yVariable + yVariable^2,
        1 - 4*xVariable*yVariable};
      stateGate = TrueQ[
        AssociationQ[state] && dedicatedSymbolsCleanQ[] &&
        Lookup[artifactReadTelemetry, "Messages", $Failed] === {} &&
        SameQ[globalDefinitionSnapshot[], globalStateBefore] &&
        Lookup[state, "Sector", None] === 11 &&
        Lookup[state, "Ranges", $Failed][[11]] === {21, 22} &&
        Lookup[state, "Ranges", $Failed][[12]] === {23, 24} &&
        AssociationQ[stop] &&
        Lookup[stop, "Status", None] ===
          "NeedsMultiquadraticRegulatorFactorization" &&
        Lookup[stop, "Rows", None] === 11 &&
        Lookup[stop, "RootIndices", None] === {1, 2, 3} &&
        Lookup[stop, "RootSquares", None] === expectedRootSquares &&
        ListQ[factors] && Length[factors] === 9 &&
        Lookup[Last[factors], "Rows", None] === 10 &&
        Lookup[Last[factors], "RootIndices", None] === {1, 2} &&
        Lookup[Last[factors], "Method", None] ===
          "RationalChart/Kallen23/ExactRationalSamples" &&
        ListQ[certificates] && Length[certificates] === 10 &&
        Lookup[Last[certificates], "Sector", None] === 11 &&
        Dimensions[Lookup[state, "A", {}]] === {2, 24, 24} &&
        Dimensions[Lookup[state, "S", {}]] === {24, 24} &&
        Dimensions[Lookup[state, "SInverse", {}]] === {24, 24}];
      Print["CF300_S11_DIRECT_REGULATOR hydration=",
        InputForm[<|"StateAssociationQ" -> AssociationQ[state],
          "ArtifactReadTelemetry" -> artifactReadTelemetry,
          "DedicatedNames" -> stateNames,
          "DedicatedSymbolsCleanQ" -> dedicatedSymbolsCleanQ[],
          "GlobalStateUnchangedQ" ->
            SameQ[globalDefinitionSnapshot[], globalStateBefore],
          "StateGateQ" -> stateGate|>]];
      If[! stateGate,
        Print["CF300_S11_DIRECT_REGULATOR FAIL state schema"];
        continuationExit[67]];

      continuationStart = AbsoluteTime[];
      core = TimeConstrained[
        Module[{connection, transformation, inverseScalar,
          regulatorPolynomial, lowerLeftScalar, newConnection,
          newS, newSInverse, coefficient, entry, lowerLeftCount = 0,
          diagonalCount = 0, futureCount = 0, sCount = 0,
          sInverseCount = 0, upperRightZeroQ, prefixToFutureZeroQ,
          scalarIdentityQ, determinantNonzeroQ, rowScales, columnScales,
          lowerLeftIdentityQ = True, diagonalFactoredQ = True,
          transformedAIdentityQ = True, sIdentityQ = True,
          sInverseIdentityQ = True, fullPrefixEpsFormQ,
          inheritedFormalCertificateQ, inheritedSpotIndices,
          inheritedSpotResults, inheritedSpotProofQ, expectedEntry,
          actualEntry, entryIdentityQ, firstAFailure = Missing["None"],
          firstSFailure = Missing["None"],
          firstSInverseFailure = Missing["None"],
          legacyStructuralPrefixEpsFormQ = True,
          legacyStructuralFirstFailure = Missing["None"],
          propagationSeal, sealVerifiedQ,
          mu, row, column, factorRecord, newState},
          connection = state["A"];
          regulatorPolynomial =
            (2*epsilon - 1)*(3*epsilon - 1)*(3*epsilon - 2);
          lowerLeftScalar = Together[regulatorPolynomial/epsilon^2];
          transformation = Together[regulatorPolynomial/epsilon^3];
          inverseScalar = Together[1/transformation];
          rowScales = Table[
            If[MemberQ[{21, 22}, row], inverseScalar, 1],
            {row, 24}];
          columnScales = Table[
            If[MemberQ[{21, 22}, column], transformation, 1],
            {column, 24}];
          determinantNonzeroQ = TrueQ[
            Numerator[Together[transformation]] =!= 0 &&
            Denominator[Together[transformation]] =!= 0 &&
            Numerator[Together[transformation^2]] =!= 0 &&
            Denominator[Together[transformation^2]] =!= 0];
          scalarIdentityQ = TrueQ[
            Together[epsilon*transformation - lowerLeftScalar] === 0 &&
            Together[transformation*inverseScalar - 1] === 0 &&
            FreeQ[{transformation, inverseScalar},
              Alternatives[xVariable, yVariable]]];
          upperRightZeroQ = AllTrue[
            Flatten[connection[[All, 1 ;; 20, 21 ;; 22]]],
            SameQ[#1, 0] &];
          prefixToFutureZeroQ = AllTrue[
            Flatten[connection[[All, 1 ;; 22, 23 ;; 24]]],
            SameQ[#1, 0] &];
          Print["CF300_S11_DIRECT_REGULATOR predicate_stage=precheck ",
            InputForm[<|
              "ScalarIdentityQ" -> scalarIdentityQ,
              "DeterminantNonzeroRationalFunctionQ" ->
                determinantNonzeroQ,
              "UpperRightZeroQ" -> upperRightZeroQ,
              "PrefixToFutureZeroQ" -> prefixToFutureZeroQ|>]];
          If[! TrueQ[scalarIdentityQ && determinantNonzeroQ &&
              upperRightZeroQ && prefixToFutureZeroQ],
            continuationExit[68]];

          newConnection = connection;
          Do[
            entry = connection[[mu, row, column]];
            If[! SameQ[entry, 0],
              coefficient = Together[entry/lowerLeftScalar];
              lowerLeftIdentityQ = lowerLeftIdentityQ &&
                FreeQ[coefficient, epsilon] &&
                TrueQ[Together[
                  entry - lowerLeftScalar*coefficient] === 0];
              newConnection[[mu, row, column]] = epsilon*coefficient;
              lowerLeftCount++],
            {mu, 2}, {row, 21, 22}, {column, 1, 20}];
          Do[
            entry = connection[[mu, row, column]];
            If[! SameQ[entry, 0],
              coefficient = Together[entry/epsilon];
              diagonalFactoredQ = diagonalFactoredQ &&
                FreeQ[coefficient, epsilon] &&
                TrueQ[Together[entry - epsilon*coefficient] === 0];
              diagonalCount++],
            {mu, 2}, {row, 21, 22}, {column, 21, 22}];
          Print["CF300_S11_DIRECT_REGULATOR predicate_stage=prefix_blocks ",
            InputForm[<|
              "LowerLeftIdentityQ" -> lowerLeftIdentityQ,
              "LowerLeftNonzeroChannels" -> lowerLeftCount,
              "DiagonalFactoredQ" -> diagonalFactoredQ,
              "DiagonalNonzeroChannels" -> diagonalCount|>]];
          If[! TrueQ[lowerLeftIdentityQ && diagonalFactoredQ] ||
              lowerLeftCount =!= 26 || diagonalCount =!= 8,
            continuationExit[69]];

          (* G=diag(I20,t I2,I2).  Only the two nonidentity columns of
             future rows change; this is the exact specialized form of
             familyRegulatorPropagateTruncation. *)
          Do[
            entry = connection[[mu, row, column]];
            If[! SameQ[entry, 0],
              newConnection[[mu, row, column]] =
                Together[entry*transformation];
              futureCount++],
            {mu, 2}, {row, 23, 24}, {column, 21, 22}];

          newS = state["S"];
          Do[
            entry = newS[[row, column]];
            If[! SameQ[entry, 0],
              newS[[row, column]] = Together[entry*transformation];
              sCount++],
            {row, 24}, {column, 21, 22}];
          newSInverse = state["SInverse"];
          Do[
            entry = newSInverse[[row, column]];
            If[! SameQ[entry, 0],
              newSInverse[[row, column]] =
                Together[inverseScalar*entry];
              sInverseCount++],
            {row, 21, 22}, {column, 24}];
          Print["CF300_S11_DIRECT_REGULATOR predicate_stage=propagation_counts ",
            InputForm[<|"FutureATouched" -> futureCount,
              "SColumnsTouched" -> sCount,
              "SInverseRowsTouched" -> sInverseCount|>]];
          If[futureCount =!= 8 || sCount =!= 2 ||
              sInverseCount =!= 14,
            continuationExit[70]];

          (* Full sparse identity checks.  Scale 1 entries use SameQ and
             never enter Together; only entries touched by G are reduced. *)
          Do[
            expectedEntry = rowScales[[row]]*
              connection[[mu, row, column]]*columnScales[[column]];
            actualEntry = newConnection[[mu, row, column]];
            entryIdentityQ = SameQ[actualEntry, expectedEntry] ||
              TrueQ[Together[actualEntry - expectedEntry] === 0];
            If[! TrueQ[entryIdentityQ],
              transformedAIdentityQ = False;
              If[MissingQ[firstAFailure],
                firstAFailure = {mu, row, column}]],
            {mu, 2}, {row, 24}, {column, 24}];
          Do[
            expectedEntry = state["S"][[row, column]]*
              columnScales[[column]];
            actualEntry = newS[[row, column]];
            entryIdentityQ = SameQ[actualEntry, expectedEntry] ||
              TrueQ[Together[actualEntry - expectedEntry] === 0];
            If[! TrueQ[entryIdentityQ],
              sIdentityQ = False;
              If[MissingQ[firstSFailure],
                firstSFailure = {row, column}]],
            {row, 24}, {column, 24}];
          Do[
            expectedEntry = rowScales[[row]]*
              state["SInverse"][[row, column]];
            actualEntry = newSInverse[[row, column]];
            entryIdentityQ = SameQ[actualEntry, expectedEntry] ||
              TrueQ[Together[actualEntry - expectedEntry] === 0];
            If[! TrueQ[entryIdentityQ],
              sInverseIdentityQ = False;
              If[MissingQ[firstSInverseFailure],
                firstSInverseFailure = {row, column}]],
            {row, 24}, {column, 24}];

          (* V2 used FreeQ[value/epsilon,epsilon] as the full-prefix gate.
             It is too syntactic: eps*(a+b) cancels, while
             (eps*a+eps*b)/eps need not factor automatically.  Preserve the
             old predicate as telemetry, but bind the unchanged 20x20 region
             to the exact input+inspector hashes and prove the changed
             regions algebraically above. *)
          Do[
            actualEntry = newConnection[[mu, row, column]];
            entryIdentityQ = SameQ[actualEntry, 0] ||
              FreeQ[actualEntry/epsilon, epsilon];
            If[! TrueQ[entryIdentityQ],
              legacyStructuralPrefixEpsFormQ = False;
              If[MissingQ[legacyStructuralFirstFailure],
                legacyStructuralFirstFailure = {mu, row, column}]],
            {mu, 2}, {row, 22}, {column, 22}];
          inheritedFormalCertificateQ = TrueQ[
            inputHashBefore === expectedStateHash &&
            inspectorHashBefore === expectedInspectorHash &&
            Lookup[Last[factors], "Rows", None] === 10 &&
            Lookup[Last[factors], "RootIndices", None] === {1, 2}];
          inheritedSpotIndices = {
            {1, 1, 1}, {1, 6, 1}, {1, 10, 1}, {1, 20, 1},
            {2, 1, 1}, {2, 6, 1}, {2, 10, 1}, {2, 20, 1}};
          inheritedSpotResults = AssociationMap[
            Function[index, Module[{value, quotient},
              value = Extract[newConnection, index];
              quotient = Together[value/epsilon];
              TrueQ[! SameQ[value, 0] && FreeQ[quotient, epsilon] &&
                Together[value - epsilon*quotient] === 0]]],
            inheritedSpotIndices];
          inheritedSpotProofQ = And @@ Values[inheritedSpotResults];
          fullPrefixEpsFormQ = TrueQ[
            inheritedFormalCertificateQ && upperRightZeroQ &&
            lowerLeftIdentityQ && diagonalFactoredQ &&
            inheritedSpotProofQ];
          Print["CF300_S11_DIRECT_REGULATOR predicate_stage=exact_validation ",
            InputForm[<|
              "FullTransformedAIdentityQ" -> transformedAIdentityQ,
              "FirstAFailure" -> firstAFailure,
              "FullSIdentityQ" -> sIdentityQ,
              "FirstSFailure" -> firstSFailure,
              "FullSInverseIdentityQ" -> sInverseIdentityQ,
              "FirstSInverseFailure" -> firstSInverseFailure,
              "LegacyStructuralPrefixEpsFormQ" ->
                legacyStructuralPrefixEpsFormQ,
              "LegacyStructuralFirstFailure" ->
                legacyStructuralFirstFailure,
              "InheritedFormalCertificateQ" ->
                inheritedFormalCertificateQ,
              "InheritedSpotResults" -> inheritedSpotResults,
              "InheritedTogetherSpotProofQ" -> inheritedSpotProofQ,
              "FullPrefixEpsFormQ" -> fullPrefixEpsFormQ|>]];
          If[! TrueQ[transformedAIdentityQ && sIdentityQ &&
              sInverseIdentityQ && fullPrefixEpsFormQ &&
              inheritedSpotProofQ],
            continuationExit[71]];

          propagationSeal = makePropagationSeal[
            connection[[All, 1 ;; 22, 1 ;; 22]],
            newConnection[[All, 1 ;; 22, 1 ;; 22]],
            transformation, inverseScalar, inputHashBefore];
          sealVerifiedQ = AssociationQ[propagationSeal] &&
            SameQ[propagationSeal,
              makePropagationSeal[
                connection[[All, 1 ;; 22, 1 ;; 22]],
                newConnection[[All, 1 ;; 22, 1 ;; 22]],
                transformation, inverseScalar, inputHashBefore]];
          If[! TrueQ[sealVerifiedQ], continuationExit[72]];

          factorRecord = <|
            "Rows" -> 11,
            "Method" ->
              "DirectInvariantSubspace/ScalarSectorBlock",
            "Points" -> 0,
            "Seconds" -> N[AbsoluteTime[] - continuationStart],
            "Chart" -> None,
            "RootIndices" -> {1, 2, 3},
            "RegulatorDependentSubspace" -> {21, 22},
            "TransformationDeterminant" -> transformation^2,
            "TransformationNonzeroRationalFunction" -> True,
            "ExceptionalEpsilonValues" -> {0, 1/3, 1/2, 2/3},
            "PropagationSeal" -> propagationSeal,
            "PropagationStatistics" -> <|
              "FutureAMode" -> "Together",
              "FutureCandidateEntries" -> 88,
              "FutureTouched" -> futureCount,
              "SpecializedNonIdentityColumns" -> 2,
              "SColumnsTouched" -> sCount,
              "SInverseRowsTouched" -> sInverseCount|>|>;
          newState = Join[KeyDrop[state, {"Stop"}], <|
            "A" -> newConnection,
            "S" -> newS,
            "SInverse" -> newSInverse,
            "RegulatorFactorizations" -> Append[factors,
              factorRecord]|>];
          <|"State" -> newState,
            "Statistics" -> <|
              "OldPrefixDimension" -> 20,
              "CompletedPrefixDimension" -> 22,
              "RegulatorDependentSubspace" -> {21, 22},
              "DenseTransformationUnknowns" -> 484,
              "ReducedScalarUnknowns" -> 1,
              "LowerLeftNonzeroChannels" -> lowerLeftCount,
              "DiagonalNonzeroChannels" -> diagonalCount,
              "UpperRightZeroChannels" -> 80,
              "PrefixToFutureZeroChannels" -> 88,
              "FutureATouched" -> futureCount,
              "SColumnsTouched" -> sCount,
              "SInverseRowsTouched" -> sInverseCount,
              "ScalarIdentityQ" -> scalarIdentityQ,
              "DeterminantNonzeroRationalFunctionQ" ->
                determinantNonzeroQ,
              "LowerLeftIdentityQ" -> lowerLeftIdentityQ,
              "DiagonalFactoredQ" -> diagonalFactoredQ,
              "FullTransformedAIdentityQ" -> transformedAIdentityQ,
              "FirstAFailure" -> firstAFailure,
              "FullSIdentityQ" -> sIdentityQ,
              "FirstSFailure" -> firstSFailure,
              "FullSInverseIdentityQ" -> sInverseIdentityQ,
              "FirstSInverseFailure" -> firstSInverseFailure,
              "FullPrefixEpsFormQ" -> fullPrefixEpsFormQ,
              "LegacyStructuralPrefixEpsFormQ" ->
                legacyStructuralPrefixEpsFormQ,
              "LegacyStructuralFirstFailure" ->
                legacyStructuralFirstFailure,
              "InheritedFormalCertificateQ" ->
                inheritedFormalCertificateQ,
              "InheritedTogetherSpotProofQ" -> inheritedSpotProofQ,
              "PropagationSealVerifiedQ" -> sealVerifiedQ,
              "OldTopLeftCertificate" ->
                <|"Method" ->
                    "PinnedFormalDegreeCensusPlusEightTogetherSpotsV4",
                  "InputStateSHA256" -> inputHashBefore,
                  "InspectorSHA256" -> inspectorHashBefore|>|>,
            "PropagationSeal" -> propagationSeal,
            "TransformationScalar" -> transformation,
            "InverseScalar" -> inverseScalar|>],
        900, $Aborted];
      If[core === $Aborted || ! AssociationQ[core],
        Print["CF300_S11_DIRECT_REGULATOR FAIL bounded core"];
        continuationExit[71]];
      newState = core["State"];
      statistics = core["Statistics"];
      propagationSeal = core["PropagationSeal"];
      recomputedSeal = makePropagationSeal[
        state["A"][[All, 1 ;; 22, 1 ;; 22]],
        newState["A"][[All, 1 ;; 22, 1 ;; 22]],
        core["TransformationScalar"], core["InverseScalar"],
        inputHashBefore];
      If[KeyExistsQ[newState, "Stop"] ||
          Length[newState["RegulatorFactorizations"]] =!= 10 ||
          Lookup[Last[newState["RegulatorFactorizations"]],
            "Rows", None] =!= 11 ||
          ! SameQ[propagationSeal, recomputedSeal] ||
          ! SameQ[
            Lookup[Last[newState["RegulatorFactorizations"]],
              "PropagationSeal", $Failed], propagationSeal],
        continuationExit[74]];

      If[FileHash[inputFile, "SHA256", "HexString"] =!=
            inputHashBefore ||
          FileHash[$InputFileName, "SHA256", "HexString"] =!=
            driverHashBefore ||
          FileHash[inspectorFile, "SHA256", "HexString"] =!=
            inspectorHashBefore,
        Print["CF300_S11_DIRECT_REGULATOR FAIL source changed"];
        continuationExit[75]];

      Put[newState, temporaryOutput];
      If[! FileExistsQ[temporaryOutput], continuationExit[76]];
      outputHash =
        FileHash[temporaryOutput, "SHA256", "HexString"];
      report = <|
        "Status" -> "OK",
        "Schema" -> "CF300Sector11DirectScalarRegulatorContinuation",
        "SchemaVersion" -> 4,
        "InputState" -> inputFile,
        "InputStateSHA256" -> inputHashBefore,
        "FormalInspectorSHA256" -> inspectorHashBefore,
        "DriverSHA256" -> driverHashBefore,
        "OutputState" -> outputFile,
        "OutputStateSHA256" -> outputHash,
        "OutputStateBytes" -> FileByteCount[temporaryOutput],
        "ArtifactReadTelemetry" -> artifactReadTelemetry,
        "DedicatedArtifactNames" -> stateNames,
        "GlobalStateUnchangedBeforeCommitQ" ->
          SameQ[globalDefinitionSnapshot[], globalStateBefore],
        "RegulatorPolynomial" ->
          "P(eps)=(2 eps-1)(3 eps-1)(3 eps-2)",
        "LowerLeftScalar" -> "q(eps)=P(eps)/eps^2",
        "TransformationScalar" -> "t(eps)=P(eps)/eps^3",
        "PreviousDriverFailureDiagnosis" ->
          "V2 used a syntactic FreeQ[value/eps,eps] gate on homogeneous " <>
          "entries with distributed eps terms",
        "TransformationDeterminant" -> "det(G)=t(eps)^2",
        "TransformationNonzeroRationalFunctionQ" -> True,
        "ExceptionalEpsilonValues" -> {0, 1/3, 1/2, 2/3},
        "PropagationSeal" -> propagationSeal,
        "PropagationSealRecomputedQ" ->
          SameQ[propagationSeal, recomputedSeal],
        "Statistics" -> statistics,
        "Seconds" -> N[AbsoluteTime[] - continuationStart]|>;
      Put[report, temporaryReport];
      If[! FileExistsQ[temporaryReport] ||
          FileHash[inputFile, "SHA256", "HexString"] =!=
            inputHashBefore,
        continuationExit[77]];
      outputCommit = Quiet[Check[
        RenameFile[temporaryOutput, outputFile,
          OverwriteTarget -> False], $Failed]];
      If[outputCommit === $Failed, continuationExit[78]];
      reportCommit = Quiet[Check[
        RenameFile[temporaryReport, reportFile,
          OverwriteTarget -> False], $Failed]];
      If[reportCommit === $Failed, continuationExit[79]];
      Print["CF300_S11_DIRECT_REGULATOR PASS output=", outputFile,
        " output_sha256=", outputHash,
        " lower_left_channels=", statistics["LowerLeftNonzeroChannels"],
        " future_touched=", statistics["FutureATouched"],
        " seconds=", Round[report["Seconds"], 0.01]];
      continuationExit[0], continuationExitTag]],
  $Aborted];

state =.; stop =.; factors =.; certificates =.; core =.; newState =.;
report =.; propagationSeal =.; recomputedSeal =.;
epsilon =.; xVariable =.; yVariable =.;
If[dedicatedRuntimeCode =!= 0,
  Scan[safeRemoveTemporary, temporaryFiles]];
dedicatedContextRemovedQ = removeDedicatedContext[];
globalStateUnchangedQ =
  SameQ[globalDefinitionSnapshot[], globalStateBefore];
finalCode = Which[
  dedicatedRuntimeCode === $Aborted, 90,
  ! IntegerQ[dedicatedRuntimeCode], 91,
  dedicatedRuntimeCode =!= 0, dedicatedRuntimeCode,
  ! TrueQ[dedicatedContextRemovedQ && globalStateUnchangedQ], 92,
  True, 0];
Print["CF300_S11_DIRECT_REGULATOR cleanup=",
  InputForm[<|"DedicatedContextRemovedQ" -> dedicatedContextRemovedQ,
    "GlobalStateUnchangedQ" -> globalStateUnchangedQ,
    "ExitCode" -> finalCode|>]];

End[];
EndPackage[];
System`Exit[
  CodexCF300Sector11DirectRegulatorContinuationV4`Private`finalCode];
