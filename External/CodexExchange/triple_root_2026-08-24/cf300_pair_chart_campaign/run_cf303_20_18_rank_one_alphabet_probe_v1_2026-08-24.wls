#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{repositoryRoot, loadFile, multiquadraticFile, stripFile,
    referencePreparationFile, outdir, candidateFile, summaryFile,
    expectedHashes, hashHex, putAtomic, exportAtomic, fail, tag, result,
    badHashes, stripPayload, referencePreparation, frame, record,
    variables, epsilon, roots, delta, existingForms, existingKeys,
    oneFormKey, deduplicateForms, conjugateScalar, conjugateForm, dlog,
    sampledFunctions, functionChannels, conjugateFunctions,
    rationalFactor, polynomialFactors, factors, factorForms,
    conjugateExistingForms, algebraicDLogForms, newConjugateForms,
    newFactorForms, fullForms, strategies, offsets, records = {},
    preparation, assembly, sample, solve, seconds, consistentRecords,
    summary, strategy, strategyName, strategyForms, offset},
  repositoryRoot = "/home/maxzhang/factorization-and-loops";
  loadFile = FileNameJoin[{repositoryRoot, "Addon", "Load",
    "LoadFACET.wl"}];
  multiquadraticFile = FileNameJoin[{repositoryRoot, "FeynFacet",
    "Private", "MultiquadraticStripSolve.wl"}];
  stripFile = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/rank_one_strips.wxf";
  referencePreparationFile =
    "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_prepare_v1/preparation_20_18.wxf";
  outdir = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_20_18_rank_one_alphabet_probe_v1";
  candidateFile = FileNameJoin[{outdir, "candidate_alphabets.wxf"}];
  summaryFile = FileNameJoin[{outdir, "summary.wl"}];
  tag = Unique["CF3032018RankOneAlphabetProbeV1$"];
  expectedHashes = <|
    loadFile ->
      "fa6f10b2c971b6016d4955feeffeb7597659a5d86f86ad0829ba95136d81eb7e",
    multiquadraticFile ->
      "5c3493d02636cf51151baae47128d77a959f880a2e1b36dd4f8077598710dc09",
    stripFile ->
      "766ffcc218bf56ac85add02d441e84f54811d1b5dde40685af7cf3c308db50ef",
    referencePreparationFile ->
      "b070db79a1987306c98400aab69942c4ce59c61304ccb044203826a27c4198ba"|>;

  hashHex[file_String] := Quiet[Check[
    If[FileExistsQ[file], FileHash[file, "SHA256", "HexString"],
      Missing["NotFound"]], Missing["HashFailed"]]];
  putAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  exportAtomic[expression_, file_String] := Module[{temporary},
    temporary = file <> ".tmp." <>
      StringReplace[CreateUUID[], "-" -> ""];
    Export[temporary, expression, "WXF"];
    RenameFile[temporary, file, OverwriteTarget -> False]];
  fail[status_String, data_: <||>] := (
    Print["CF303 20->18 RANK-ONE ALPHABET PROBE FAILURE V1: ", status,
      " data=", data];
    Throw[$Failed, tag]);

  result = Catch[
    If[Rest[$ScriptCommandLine] =!= {},
      fail["WrapperTakesNoArguments"]];
    If[! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0,
      fail["SinglePoolWorkerRequired"]];
    If[DirectoryQ[outdir] || FileExistsQ[outdir],
      fail["OutputAlreadyExists"]];
    badHashes = Select[Keys[expectedHashes],
      hashHex[#] =!= expectedHashes[#] &];
    If[badHashes =!= {},
      fail["ImmutableInputHashMismatch", <|"Files" -> badHashes|>]];
    CreateDirectory[outdir];
    Print["CF3032018R1ALPHV1 stage=load"];
    Get[loadFile];
    stripPayload = Import[stripFile, "WXF"];
    referencePreparation = Import[referencePreparationFile, "WXF"];
    If[! AssociationQ[stripPayload] ||
        ! AssociationQ[referencePreparation] ||
        Lookup[stripPayload, "Status", None] =!=
          "CF303Sector20TopAnd181RankOneStripsPassedV1" ||
        Lookup[referencePreparation, "Status", None] =!=
          "PreparedMultiquadraticStripV1" ||
        referencePreparation["RootCount"] =!= 1,
      fail["InvalidPreparedInputABI"]];
    frame = stripPayload["Frame"];
    variables = referencePreparation["Variables"];
    epsilon = referencePreparation["Regulator"];
    roots = referencePreparation["Roots"];
    delta = First[referencePreparation["RootSquares"]];
    record = <|"Family" -> "CF303", "Sector" -> 20,
      "LowerSector" -> 18, "Variables" -> variables,
      "Regulator" -> epsilon, "Strip" -> stripPayload["Strip2018"]|>;
    existingForms = referencePreparation["OneForms"];
    oneFormKey[form_] :=
      FeynFacet`Private`multiquadraticOneFormKey[form, roots];
    deduplicateForms[forms_List] :=
      FeynFacet`Private`multiquadraticDeduplicateOneForms[
        forms, roots, variables];
    conjugateScalar[expression_] := Module[{channels, conjugate},
      channels = FeynFacet`Private`multiquadraticFieldDecompose[
        expression, roots];
      If[channels === $Failed, Return[$Failed]];
      conjugate = FeynFacet`Private`multiquadraticFieldCompose[
        {channels[[1]], -channels[[2]]}, roots];
      If[conjugate === $Failed, $Failed, Together[conjugate]]];
    conjugateForm[form : {_, _}] := conjugateScalar /@ form;
    dlog[function_] := {
      Together[D[function, variables[[1]]]/function],
      Together[D[function, variables[[2]]]/function]};
    polynomialFactors[expression_] := Module[
      {rational, numerator, denominator, pairs},
      rational = Together[expression];
      If[TrueQ[rational === 0], Return[{}]];
      numerator = Expand[Numerator[rational]];
      denominator = Expand[Denominator[rational]];
      pairs = Join[Rest[FactorList[numerator]],
        Rest[FactorList[denominator]]];
      Select[First /@ pairs,
        ! FreeQ[#, Alternatives @@ variables] &&
          FreeQ[#, epsilon] &]];
    rationalFactor[expression_] := Module[{channels},
      channels = FeynFacet`Private`multiquadraticFieldDecompose[
        expression, roots];
      If[channels === $Failed, {},
        Join[polynomialFactors[channels[[1]]],
          polynomialFactors[channels[[2]]],
          polynomialFactors[Together[
            channels[[1]]^2 - delta channels[[2]]^2]]]]];

    Print["CF3032018R1ALPHV1 stage=build-candidates"];
    sampledFunctions = DeleteDuplicates@Select[
      Flatten@Table[Together[entry /. epsilon -> value],
        {entry, Flatten[record["Strip"]]},
        {value, {0, 1, -1, 2, 3}}],
      ! TrueQ[Together[#] === 0] &&
        ! FreeQ[#, Alternatives @@ variables] &];
    functionChannels =
      FeynFacet`Private`multiquadraticFieldDecompose[#, roots] & /@
        sampledFunctions;
    If[MemberQ[functionChannels, $Failed],
      fail["SampledFunctionChannelDecompositionFailed"]];
    conjugateFunctions = conjugateScalar /@ sampledFunctions;
    If[MemberQ[conjugateFunctions, $Failed],
      fail["SampledFunctionConjugationFailed"]];
    conjugateExistingForms = conjugateForm /@ existingForms;
    If[! FreeQ[conjugateExistingForms, $Failed],
      fail["ExistingOneFormConjugationFailed"]];
    algebraicDLogForms = dlog /@ Join[
      sampledFunctions, conjugateFunctions];
    factors = DeleteDuplicates[Flatten[
      rationalFactor /@ sampledFunctions],
      Function[{left, right},
        TrueQ[Together[left - right] === 0] ||
          TrueQ[Together[left + right] === 0]]];
    factorForms = dlog /@ factors;
    existingKeys = oneFormKey /@ existingForms;
    newConjugateForms = Select[
      deduplicateForms[Join[conjugateExistingForms,
        algebraicDLogForms]],
      ! MemberQ[existingKeys, oneFormKey[#]] &];
    newFactorForms = Select[deduplicateForms[factorForms],
      ! MemberQ[existingKeys, oneFormKey[#]] &];
    fullForms = deduplicateForms[Join[existingForms,
      newConjugateForms, newFactorForms]];
    strategies = {
      {"Existing", existingForms},
      {"ConjugateClosed", deduplicateForms[
        Join[existingForms, newConjugateForms]]},
      {"RationalFactorClosed", deduplicateForms[
        Join[existingForms, newFactorForms]]},
      {"FullClosure", fullForms}};
    offsets = {{0, 0}, {1, 1}};

    Do[
      strategyName = strategy[[1]];
      strategyForms = strategy[[2]];
      Do[
        Print["CF3032018R1ALPHV1 strategy=", strategyName,
          " forms=", Length[strategyForms], " offset=", offset];
        seconds = First@AbsoluteTiming[
          preparation = FeynFacet`Private`multiquadraticStripPrepare[
            record, frame, "OneForms" -> strategyForms,
            "GaugeDenominator" ->
              referencePreparation["GaugeDenominator"],
            "DegreeOffset" -> offset];
          If[Lookup[preparation, "Status", None] ===
              "PreparedMultiquadraticStripV1",
            assembly = FeynFacet`Private`multiquadraticStripCompile[
              preparation];
            sample = If[Lookup[assembly, "Status", None] ===
                "CompiledMultiquadraticStripV1",
              FeynFacet`Private`multiquadraticStripAssembleSample[
                assembly, 1/13, 2147483423], assembly];
            solve = If[Lookup[sample, "Status", None] ===
                "AssembledMultiquadraticSampleV1",
              FeynFacet`Private`multiquadraticStripAffineSolve[
                sample["Matrix"], sample["RightHandSide"],
                2147483423], sample],
            assembly = Missing["NotCompiled"];
            sample = Missing["NotAssembled"];
            solve = preparation]];
        AppendTo[records, <|
          "Strategy" -> strategyName,
          "OneFormCount" -> Length[strategyForms],
          "DegreeOffset" -> offset,
          "UnknownCount" -> Lookup[preparation,
            "UnknownCount", Missing[]],
          "MatrixDimensions" -> Lookup[sample,
            "MatrixDimensions", Missing[]],
          "SolveStatus" -> Lookup[solve, "Status", None],
          "Rank" -> Lookup[solve, "Rank", Missing[]],
          "Nullity" -> Lookup[solve, "Nullity", Missing[]],
          "InconsistentRows" -> Lookup[solve,
            "InconsistentRows", {}],
          "Seconds" -> seconds|>];
        Print["CF3032018R1ALPHV1 result=", Last[records]],
        {offset, offsets}],
      {strategy, strategies}];
    consistentRecords = Select[records,
      Lookup[#, "SolveStatus", None] ===
        "MultiquadraticAffineSolution" &];
    exportAtomic[<|
      "Status" -> "CF303Sector2018RankOneAlphabetProbeCompletedV1",
      "Family" -> "CF303", "Sector" -> 20, "LowerSector" -> 18,
      "ExistingOneForms" -> existingForms,
      "NewConjugateOneForms" -> newConjugateForms,
      "NewRationalFactorOneForms" -> newFactorForms,
      "FullOneForms" -> fullForms,
      "RationalFactors" -> factors,
      "SampledFunctionCount" -> Length[sampledFunctions],
      "Records" -> records,
      "ConsistentRecords" -> consistentRecords,
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>, candidateFile];
    summary = <|
      "Status" -> "CF303Sector2018RankOneAlphabetProbeCompletedV1",
      "ExistingOneFormCount" -> Length[existingForms],
      "NewConjugateOneFormCount" -> Length[newConjugateForms],
      "NewRationalFactorOneFormCount" -> Length[newFactorForms],
      "FullOneFormCount" -> Length[fullForms],
      "RationalFactorCount" -> Length[factors],
      "Records" -> records,
      "ConsistentRecords" -> consistentRecords,
      "CandidateFile" -> candidateFile,
      "CandidateSHA256" -> hashHex[candidateFile],
      "InputHashes" -> expectedHashes,
      "PackageSourceModified" -> False,
      "Created" -> DateString[Now, "ISODateTime"]|>;
    putAtomic[summary, summaryFile];
    Print["CF3032018R1ALPHV1 status=COMPLETE consistent=",
      consistentRecords];
    0,
    tag];
  result
]
