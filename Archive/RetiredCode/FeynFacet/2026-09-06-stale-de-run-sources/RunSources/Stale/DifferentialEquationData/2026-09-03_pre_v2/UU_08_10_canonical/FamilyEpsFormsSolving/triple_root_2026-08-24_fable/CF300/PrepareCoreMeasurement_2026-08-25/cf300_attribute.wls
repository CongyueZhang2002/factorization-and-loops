#!/usr/bin/env wolframscript
(* WHERE the 2710.9 s of a first-call prepare on the real CF300 (12,9)
   actually goes.

   Measured 15:58 on 2026-08-25 on this descriptor: prepare 2710.9 s,
   compile 91.3 s.  That 30:1 split says the duplicated E/C/BBar
   decomposition the early-core change removes CANNOT be the dominant
   term -- the whole compile, which decomposes E and C and compiles every
   channel, is 91 s.  So prepare is spending its time somewhere else, and
   this run attributes it stage by stage, in prepare's own order.

   Nothing here changes anything; every call is the one prepare makes.

   USAGE
     cf300_attribute.wls cheap     the CHEAP PREDICTIVE GATE (house rule
                                   for a >10-minute stage): the identical
                                   instrumentation on a small synthetic
                                   rank-2 block, which must show every
                                   stage bucket nonzero and the sealed
                                   core reproducing the independent
                                   decomposition exactly.  Under 2 min.
     cf300_attribute.wls cf300     the real block.  ~53 min measured, one
                                   main kernel, no subkernels.
     cf300_attribute.wls payloadgate
                                   the CHEAP GATE for phase 2: the same
                                   phase-2 instrumentation on the small
                                   synthetic block. Seconds.
     cf300_attribute.wls payload   PHASE 2, added after the cf300 run left
                                   47.5% of the reference prepare
                                   unattributed.  It measures the stages
                                   the first pass did not: the gauge
                                   denominator MERGE and the ABI payload
                                   broken into its parts.  It reads the
                                   already-measured channel decomposition
                                   from the frozen fixture instead of
                                   re-paying its 1400.5 s, so it costs
                                   minutes rather than an hour.
   The output file is <this directory>/cf300_attribute_<mode>_result.wl.

   INPUTS.  The strip input is the FROZEN copy under
   FamilyEpsFormsSolving/FrozenTestFixtures_2026-08-25/ (2026-08-25: the
   live campaign directory rewrites it under a running job, and the
   scratchpad snapshot this script originally read no longer exists). *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
here = DirectoryName[ExpandFileName[$InputFileName]];
mode = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "cheap"];
If[! MemberQ[{"cheap", "cf300", "payload", "payloadgate",
    "assembly", "assemblygate"}, mode],
  Print["usage: cf300_attribute.wls \
[cheap|cf300|payload|payloadgate|assembly|assemblygate]"];
  Exit[64]];
(* "payloadgate" is the CHEAP PREDICTIVE GATE for "payload": the identical
   phase-2 instrumentation on the small synthetic block, so the code path
   is validated before the real one is entered (house rule for a stage
   whose cost is not yet known). *)
smallFixtureQ = MemberQ[{"cheap", "payloadgate", "assemblygate"}, mode];
phaseTwoQ = MemberQ[{"payload", "payloadgate"}, mode];
phaseThreeQ = MemberQ[{"assembly", "assemblygate"}, mode];
out = FileNameJoin[{here, "cf300_attribute_" <> mode <> "_result.wl"}];
$t0 = AbsoluteTime[];
say[a___] := WriteString["stdout",
  ToString[Round[AbsoluteTime[] - $t0, 0.01]], "s | ",
  StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}], "\n"];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticStripSolve.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];

If[! smallFixtureQ,
  FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root,
     "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
     "TransportFamilyCharts.wl"}]];
  frame = FeynFacet`TransportFamilyChart["CF300"];
  stripFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
     "UU_08_10_canonical", "FamilyEpsFormsSolving",
     "FrozenTestFixtures_2026-08-25", "cf300_frozen_strip_12_9_input.wl"}];
  If[! FileExistsQ[stripFile],
    say["!! frozen strip input missing: ", stripFile]; Exit[2]];
  record = FeynFacet`FamilyArtifactRead[stripFile, "Global`"];
  ,
  (* the CHEAP GATE fixture: the rank-2 block the acceptance suite builds
     from a known gauge and known residues.  Same shape, same code path,
     three orders of magnitude smaller. *)
  Clear[x, y, eps, v, w, cx, cy];
  frame = BuildAlgebraicTransportFrame[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
  dlogOf[letter_] := {D[Log[letter], x], D[Log[letter], y]};
  cheapLetters = {x, y, 1 - x - y};
  cheapForms = dlogOf /@ cheapLetters;
  cheapDenominator = 1 - x - y;
  cheapSupport = Sort[{{0, 0}, {0, 1}, {1, 0}}];
  cheapOrder = mq["multiquadraticStripRootOrder"][frame, {x, y}, {1, 2}, eps];
  cheapRoots = Lookup[cheapOrder["Roots"], "Root", {}];
  gradeFactor[grade_, rr_] :=
    Product[If[BitGet[grade, k - 1] === 1, rr[[k]], 1], {k, Length[rr]}];
  cheapCoefficients = BlockRandom[SeedRandom[20260825];
    Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
      {2}, {2}, {4}, {3}]];
  cheapResidues = BlockRandom[SeedRandom[20260826];
    Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}], {3}, {2}, {2}]];
  cheapGauge = Table[
    Sum[cheapCoefficients[[i, j, g + 1, m]] x^cheapSupport[[m, 1]]
        y^cheapSupport[[m, 2]] gradeFactor[g, cheapRoots]/cheapDenominator,
      {g, 0, 3}, {m, 3}], {i, 2}, {j, 2}];
  cheapDiagonal[res_] := Table[
    Sum[res[[a]] cheapForms[[a, mu]], {a, 3}], {mu, 2}];
  cheapE = BlockRandom[SeedRandom[20260827];
    cheapDiagonal[Table[RandomInteger[{-2, 2}, {2, 2}], {3}]]];
  cheapC = BlockRandom[SeedRandom[20260828];
    cheapDiagonal[Table[RandomInteger[{-2, 2}, {2, 2}], {3}]]];
  cheapB = Table[Map[Together,
    Sum[cheapResidues[[a]] eps cheapForms[[a, mu]], {a, 3}] +
      D[cheapGauge, {x, y}[[mu]]] -
      eps (cheapE[[mu]] . cheapGauge - cheapGauge . cheapC[[mu]]), {2}],
    {mu, 2}];
  record = <|"Family" -> "CHEAPGATE", "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {cheapE, cheapC, cheapB}|>];

variables = record["Variables"]; regulator = record["Regulator"];
allRoots = mq["transportChartCurrentRoots"][frame, variables];
census = mq["multiquadraticStripRootCensus"][record["Strip"], allRoots];
order = mq["multiquadraticStripRootOrder"][frame, variables,
   census["RootIndices"], regulator];
roots = order["Roots"];
strip = record["Strip"];
bbar = strip[[3]];
say["mode ", mode, "; BBar ", Dimensions[bbar], " leaves ", LeafCount[bbar],
  "; E leaves ", LeafCount[strip[[1]]], "; C leaves ", LeafCount[strip[[2]]],
  "; rank ", Length[roots]];

clear = mq["multiquadraticStripCompileCacheClear"];

(* ================================================================== *)
(* PHASE 2 (mode "payload").  The first cf300 pass attributed 1422.0 s *)
(* of the 2710.9 s reference prepare and left 1288.9 s (47.5%)         *)
(* UNATTRIBUTED.  The stages it did not measure are the gauge          *)
(* denominator MERGE and the ABI payload -- of which the first pass    *)
(* timed only multiquadraticStripCoreCanonicalData (the equation and   *)
(* root texts), not the payload's own work: canonicalizing 52 one-forms*)
(* (two Together + two Expand each), the context-freedom traversal of  *)
(* the whole payload, and the InputForm + Hash of a payload carrying a *)
(* 3.7-million-character equation text.                                *)
(*                                                                     *)
(* The parts below are the calls multiquadraticStripABIPayload makes,  *)
(* in its order.  The WHOLE function is timed as well, so the parts    *)
(* can be checked against it rather than trusted.                      *)
(* ================================================================== *)
(* THE CHEAP GATE IS A PRECONDITION, not a convention: the real phase-2
   run REFUSES to start until the gate has run and left its record.  That
   puts the house rule in the driver rather than in whatever shell
   happens to invoke it. *)
If[mode === "assembly" &&
    ! FileExistsQ[FileNameJoin[{here,
      "cf300_attribute_assemblygate_result.wl"}]],
  say["!! refusing: the cheap gate has not been run.  Run \
`cf300_attribute.wls assemblygate` first (seconds); it writes \
cf300_attribute_assemblygate_result.wl, which this mode requires."];
  Exit[3]];

If[mode === "payload" &&
    ! FileExistsQ[FileNameJoin[{here,
      "cf300_attribute_payloadgate_result.wl"}]],
  say["!! refusing: the cheap gate has not been run.  Run \
`cf300_attribute.wls payloadgate` first (seconds); it writes \
cf300_attribute_payloadgate_result.wl, which this mode requires."];
  Exit[3]];

(* ================================================================== *)
(* PHASE 3 (mode "assembly").  Phases 1-2 attributed 1435.7 s of the   *)
(* 2710.9 s reference prepare and left 1275.2 s (47.0%) unlocated.     *)
(* The stages NEITHER pass measured are the ones that run BEFORE the   *)
(* decomposition (the root census over a 1.13M-leaf strip, the root    *)
(* order) and the ones that close the record after it (support and     *)
(* normalization construction, the sealed forcing-channel record, the  *)
(* final Together calls).                                             *)
(*                                                                     *)
(* The decisive measurement is not the bucket sum but A8: prepare RUN  *)
(* END TO END with the forcing channels AND the letter records         *)
(* supplied, so the 1400.5 s decomposition is skipped entirely.  That  *)
(* brackets the gap by SUBTRACTION -- whatever A8 costs is everything  *)
(* prepare does other than decompose -- and the buckets then say where *)
(* inside it the time sits.  Nothing here re-pays the decomposition.   *)
(* ================================================================== *)
If[phaseThreeQ,
  Module[{channelFile, channels, sealRecord, sealSeconds, allRootsSeconds,
      allRoots3, censusSeconds, census3, rootIndices3, orderSeconds, order3,
      roots3, letterSeconds3, letterData3, letterRecords3, oneForms3,
      normSeconds3, normFactor3, rationalSeconds3, rationalDenominator3,
      mergeSeconds3, gaugeDenominator3, degrees3, supportSeconds, support3,
      normalizationSeconds, normalizations3, dimensions3, gradeCount3,
      gaugeUnknownCount3, togetherSeconds, endToEndSeconds, prepared,
      bucketTotal, prepareArgs3},
    channelFile = If[smallFixtureQ, None,
      FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
        "UU_08_10_canonical", "FamilyEpsFormsSolving",
        "FrozenTestFixtures_2026-08-25", "cf300_frozen_channel_forcing.wl"}]];
    If[smallFixtureQ,
      channels = mq["multiquadraticStripDecomposeForcing"][bbar, roots],
      If[! FileExistsQ[channelFile],
        say["!! frozen channel forcing missing: ", channelFile]; Exit[2]];
      channels = Get[channelFile]];
    If[! ArrayQ[channels, 4],
      say["!! channel forcing is not a rank-4 array"]; Exit[2]];
    say["A0 channels ", If[smallFixtureQ, "decomposed for the gate",
      "read from the frozen fixture"], ": ", Dimensions[channels]];

    (* A1-A3: everything prepare does BEFORE the decomposition *)
    {allRootsSeconds, allRoots3} = AbsoluteTiming[
      mq["transportChartCurrentRoots"][frame, variables]];
    say["A1 transportChartCurrentRoots: ", Round[allRootsSeconds, 0.1], " s"];
    {censusSeconds, census3} = AbsoluteTiming[
      mq["multiquadraticStripRootCensus"][strip, allRoots3]];
    say["A2 multiquadraticStripRootCensus over the whole strip: ",
      Round[censusSeconds, 0.1], " s, root indices ",
      census3["RootIndices"]];
    rootIndices3 = census3["RootIndices"];
    {orderSeconds, order3} = AbsoluteTiming[
      mq["multiquadraticStripRootOrder"][frame, variables, rootIndices3,
        regulator]];
    say["A3 multiquadraticStripRootOrder (denest + square-class match): ",
      Round[orderSeconds, 0.1], " s, status ",
      Lookup[order3, "Status", None]];
    roots3 = order3["Roots"];

    (* the alphabet: NOT part of the 2710.9 s (the reference supplied
       LetterRecords), but prepare needs it to build the ansatz *)
    {letterSeconds3, letterData3} = AbsoluteTiming[
      mq["multiquadraticStripCandidateLetters"][strip, roots3, variables,
        regulator, record, "RegulatorSampleCount" -> 2]];
    letterRecords3 = Lookup[letterData3, "LetterRecords", {}];
    oneForms3 = Lookup[letterData3, "OneForms", {}];
    say["A4 candidate letters (EXCLUDED from the reference): ",
      Round[letterSeconds3, 0.1], " s, ", Length[oneForms3], " one-forms"];

    (* A5-A7: everything prepare does AFTER the decomposition *)
    {normSeconds3, normFactor3} = AbsoluteTiming[
      mq["multiquadraticStripNormDenominatorFactor"][letterRecords3,
        variables]];
    {rationalSeconds3, rationalDenominator3} = AbsoluteTiming[
      mq["multiquadraticRationalGaugeDenominator"][channels, variables]];
    {mergeSeconds3, gaugeDenominator3} = AbsoluteTiming[
      mq["multiquadraticStripMergeGaugeDenominator"][rationalDenominator3,
        normFactor3, variables]];
    degrees3 = Exponent[gaugeDenominator3, #] & /@ variables;
    say["A5 norm factor / rational denominator / merge: ",
      Round[{normSeconds3, rationalSeconds3, mergeSeconds3}, 0.1],
      " s, degrees ", degrees3];

    {supportSeconds, support3} = AbsoluteTiming[
      Flatten[Table[{i, j}, {i, 0, degrees3[[1]]}, {j, 0, degrees3[[2]]}], 1]];
    dimensions3 = Dimensions[strip[[3, 1]]];
    gradeCount3 = 2^Length[roots3];
    gaugeUnknownCount3 = (Times @@ dimensions3) gradeCount3 Length[support3];
    {normalizationSeconds, normalizations3} = AbsoluteTiming[
      mq["multiquadraticStripCompileNormalizations"][{}, dimensions3,
        gradeCount3, support3, oneForms3, gaugeUnknownCount3]];
    say["A6 support (", Length[support3], " points) + normalizations: ",
      Round[{supportSeconds, normalizationSeconds}, 0.1], " s"];

    (* THE SEALED FORCING-CHANNEL RECORD.  This is WAVE-ADDED cost: the
       V1 seal the 2710.9 s reference paid hashed only the forcing, and
       the V2 seal added a full ChannelsSHA256 over the channel array.
       Measured here so the wave's own contribution is separated from
       the pre-existing cost rather than hidden inside it. *)
    {sealSeconds, sealRecord} = AbsoluteTiming[
      mq["multiquadraticStripForcingChannelRecord"][channels, strip[[3]],
        roots3, variables, regulator]];
    say["A7 sealed forcing-channel record (V2, WAVE-ADDED): ",
      Round[sealSeconds, 0.1], " s"];
    {togetherSeconds, gaugeDenominator3} = AbsoluteTiming[
      {Together[normFactor3], Together[gaugeDenominator3]}];
    say["A8 final Together on the denominator pair: ",
      Round[togetherSeconds, 0.1], " s"];

    (* A9: THE BRACKET.  prepare end to end with the channels AND the
       letters supplied -- everything except the 1400.5 s decomposition. *)
    prepareArgs3 = {"ForcingChannels" -> sealRecord,
      "LetterRecords" -> letterRecords3, "RootIndices" -> rootIndices3};
    {endToEndSeconds, prepared} = AbsoluteTiming[
      mq["multiquadraticStripPrepare"][record, frame,
        Sequence @@ prepareArgs3]];
    say["A9 PREPARE END TO END with channels+letters supplied (i.e. \
everything except the decomposition): ", Round[endToEndSeconds, 0.1],
      " s, status ", Lookup[prepared, "Status", None], ", unknowns ",
      Lookup[prepared, "UnknownCount", None], ", support ",
      Length[Lookup[prepared, "GaugeSupport", {}]]];

    bucketTotal = allRootsSeconds + censusSeconds + orderSeconds +
      normSeconds3 + rationalSeconds3 + mergeSeconds3 + supportSeconds +
      normalizationSeconds + sealSeconds + togetherSeconds;
    say["PHASE 3 buckets (excluding the alphabet): ",
      Round[bucketTotal, 0.1], " s; end-to-end minus decomposition: ",
      Round[endToEndSeconds, 0.1], " s"];
    If[! smallFixtureQ,
      say["  reference prepare 2710.9 s; decomposition 1400.5 s; so \
prepare-without-decomposition SHOULD be about ", Round[2710.9 - 1400.5, 0.1],
        " s and A9 measured ", Round[endToEndSeconds, 0.1], " s"],
      say["  GATE: synthetic block, no reference prepare exists; this run \
validates the instrumentation only"]];

    Put[<|"Schema" -> "CF300PrepareAttributionPhase3V1", "Mode" -> mode,
      "Descriptor" -> {record["Family"], record["Sector"],
        record["LowerSector"]},
      "StripSHA256" -> If[smallFixtureQ, Missing["SyntheticFixture"],
        FileHash[stripFile, "SHA256", "HexString"]],
      "CurrentRootsSeconds" -> allRootsSeconds,
      "RootCensusSeconds" -> censusSeconds,
      "RootOrderSeconds" -> orderSeconds,
      "CandidateLetterSeconds" -> letterSeconds3,
      "CandidateLetterCount" -> Length[oneForms3],
      "NormDenominatorFactorSeconds" -> normSeconds3,
      "RationalGaugeDenominatorSeconds" -> rationalSeconds3,
      "GaugeDenominatorMergeSeconds" -> mergeSeconds3,
      "GaugeDenominatorDegrees" -> degrees3,
      "SupportSeconds" -> supportSeconds, "SupportSize" -> Length[support3],
      "NormalizationSeconds" -> normalizationSeconds,
      "SealedForcingChannelRecordSeconds" -> sealSeconds,
      "SealIsWaveAdded" -> True,
      "FinalTogetherSeconds" -> togetherSeconds,
      "PrepareWithoutDecompositionSeconds" -> endToEndSeconds,
      "PrepareStatus" -> Lookup[prepared, "Status", None],
      "PrepareUnknownCount" -> Lookup[prepared, "UnknownCount", None],
      "BucketTotalSeconds" -> bucketTotal,
      "ReferencePrepareSeconds" -> If[smallFixtureQ,
        Missing["SyntheticFixture"], 2710.9],
      "ReferenceDecompositionSeconds" -> If[smallFixtureQ,
        Missing["SyntheticFixture"], 1400.5],
      "PeakMemoryBytes" -> MaxMemoryUsed[],
      "RunAt" -> DateString["ISODateTime"]|>, out];
    say["written ", out]];
  Exit[0]];

If[phaseTwoQ,
  Module[{channelFile, channels, letterSeconds2, letterData2, letterRecords2,
      oneForms2, normSeconds2, normFactor2, mergeSeconds, rationalSeconds,
      rationalDenominator, gaugeDenominator2, rules, denominatorTextSeconds,
      oneFormTextSeconds, normalizationTextSeconds, contextSeconds,
      fingerprintSeconds, payloadSeconds2, payload2, support2,
      denominatorDegrees2, canonicalTexts, partsTotal},
    (* the real run reads the ALREADY MEASURED decomposition rather than
       re-paying its 1400.5 s; the gate decomposes its tiny block, which
       the cheap run measured at 0.0 s *)
    channelFile = If[smallFixtureQ, None,
      FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
        "UU_08_10_canonical", "FamilyEpsFormsSolving",
        "FrozenTestFixtures_2026-08-25", "cf300_frozen_channel_forcing.wl"}]];
    If[smallFixtureQ,
      channels = mq["multiquadraticStripDecomposeForcing"][bbar, roots],
      If[! FileExistsQ[channelFile],
        say["!! frozen channel forcing missing: ", channelFile]; Exit[2]];
      channels = Get[channelFile]];
    If[! ArrayQ[channels, 4],
      say["!! channel forcing is not a rank-4 array: ", Dimensions[channels]];
      Exit[2]];
    say["P0 channel forcing ",
      If[smallFixtureQ, "decomposed for the gate", "read from the frozen fixture"],
      ": ", Dimensions[channels], ", leaves ", LeafCount[channels]];

    {letterSeconds2, letterData2} = AbsoluteTiming[
      mq["multiquadraticStripCandidateLetters"][strip, roots, variables,
        regulator, record, "RegulatorSampleCount" -> 2]];
    letterRecords2 = Lookup[letterData2, "LetterRecords", {}];
    oneForms2 = Lookup[letterData2, "OneForms", {}];
    say["P1 candidate letters: ", Round[letterSeconds2, 0.1], " s, ",
      Length[oneForms2], " one-forms (NOT part of the 2710.9 s: the reference run supplied LetterRecords)"];

    {normSeconds2, normFactor2} = AbsoluteTiming[
      mq["multiquadraticStripNormDenominatorFactor"][letterRecords2,
        variables]];
    say["P2 norm denominator factor: ", Round[normSeconds2, 0.1], " s"];

    {rationalSeconds, rationalDenominator} = AbsoluteTiming[
      mq["multiquadraticRationalGaugeDenominator"][channels, variables]];
    say["P3 rational gauge denominator: ", Round[rationalSeconds, 0.1], " s"];

    {mergeSeconds, gaugeDenominator2} = AbsoluteTiming[
      mq["multiquadraticStripMergeGaugeDenominator"][rationalDenominator,
        normFactor2, variables]];
    denominatorDegrees2 = Exponent[gaugeDenominator2, #] & /@ variables;
    say["P4 gauge denominator MERGE: ", Round[mergeSeconds, 0.1],
      " s, degrees ", denominatorDegrees2];

    support2 = Flatten[Table[{i, j}, {i, 0, denominatorDegrees2[[1]]},
      {j, 0, denominatorDegrees2[[2]]}], 1];
    rules = mq["multiquadraticStripCanonicalRules"][variables, regulator];

    (* the ABI payload, WHOLE *)
    {payloadSeconds2, payload2} = AbsoluteTiming[
      mq["multiquadraticStripABIPayload"][record, roots, variables, regulator,
        Dimensions[strip[[3, 1]]], gaugeDenominator2, support2, oneForms2, {}]];
    say["P5 multiquadraticStripABIPayload (WHOLE): ",
      Round[payloadSeconds2, 0.1], " s, ok ", AssociationQ[payload2]];

    (* and its parts, in its own order *)
    {denominatorTextSeconds, canonicalTexts} = AbsoluteTiming[
      mq["multiquadraticStripCanonicalText"][gaugeDenominator2, rules]];
    say["P6 canonical text of the gauge denominator: ",
      Round[denominatorTextSeconds, 0.1], " s"];
    {oneFormTextSeconds, canonicalTexts} = AbsoluteTiming[
      Map[mq["multiquadraticStripCanonicalText"][#, rules] &, oneForms2, {2}]];
    say["P7 canonical text of ", Length[oneForms2],
      " ONE-FORMS (2 Together + 2 Expand each): ",
      Round[oneFormTextSeconds, 0.1], " s"];
    {normalizationTextSeconds, canonicalTexts} = AbsoluteTiming[
      Map[mq["multiquadraticStripCanonicalText"][#, rules] &, {}, {2}]];
    say["P8 canonical text of the normalizations (none here): ",
      Round[normalizationTextSeconds, 0.1], " s"];
    {contextSeconds, canonicalTexts} = AbsoluteTiming[
      mq["multiquadraticStripContextFreeQ"][payload2]];
    say["P9 context-freedom traversal of the whole payload: ",
      Round[contextSeconds, 0.1], " s, context free ", canonicalTexts];
    {fingerprintSeconds, canonicalTexts} = AbsoluteTiming[
      mq["multiquadraticStripFingerprint"][payload2]];
    say["P10 ABI fingerprint (InputForm + SHA-256 of the payload): ",
      Round[fingerprintSeconds, 0.1], " s"];

    partsTotal = mergeSeconds + payloadSeconds2;
    say["PHASE 2 ATTRIBUTION (stages the first pass did NOT measure): merge ", Round[mergeSeconds, 0.1], " s + ABI payload ",
      Round[payloadSeconds2, 0.1], " s = ", Round[partsTotal, 0.1], " s"];
    If[! smallFixtureQ,
      say["  first pass attributed 1422.0 s of 2710.9 s; with phase 2 that becomes ", Round[1422.0 + partsTotal, 0.1], " s (",
        Round[100. (1422.0 + partsTotal)/2710.9, 0.1], "%)"],
      say["  GATE: no reference prepare exists for the synthetic block; this run validates the instrumentation only"]];

    Put[<|"Schema" -> "CF300PrepareAttributionPhase2V1",
      "Mode" -> mode,
      "Descriptor" -> {record["Family"], record["Sector"],
        record["LowerSector"]},
      "StripSHA256" -> If[smallFixtureQ, Missing["SyntheticFixture"],
        FileHash[stripFile, "SHA256", "HexString"]],
      "ChannelForcingSHA256" -> If[smallFixtureQ,
        Missing["DecomposedForTheGate"],
        FileHash[channelFile, "SHA256", "HexString"]],
      "ChannelForcingLeafCount" -> LeafCount[channels],
      "CandidateLetterSeconds" -> letterSeconds2,
      "CandidateLetterCount" -> Length[oneForms2],
      "NormDenominatorFactorSeconds" -> normSeconds2,
      "RationalGaugeDenominatorSeconds" -> rationalSeconds,
      "GaugeDenominatorMergeSeconds" -> mergeSeconds,
      "GaugeDenominatorDegrees" -> denominatorDegrees2,
      "SupportSize" -> Length[support2],
      "ABIPayloadSeconds" -> payloadSeconds2,
      "ABIPayloadPartSeconds" -> <|
        "GaugeDenominatorText" -> denominatorTextSeconds,
        "OneFormTexts" -> oneFormTextSeconds,
        "NormalizationTexts" -> normalizationTextSeconds,
        "ContextFreedomTraversal" -> contextSeconds,
        "Fingerprint" -> fingerprintSeconds|>,
      "PhaseTwoTotalSeconds" -> partsTotal,
      "FirstPassAttributedSeconds" -> If[smallFixtureQ,
        Missing["SyntheticFixture"], 1422.0],
      "ReferencePrepareSeconds" -> If[smallFixtureQ,
        Missing["SyntheticFixture"], 2710.9],
      "PeakMemoryBytes" -> MaxMemoryUsed[],
      "RunAt" -> DateString["ISODateTime"]|>, out];
    say["written ", out]];
  Exit[0]];

(* 1. the forcing channel decomposition, interned -- what BOTH routes do *)
clear[];
{decomposeSeconds, channels} = AbsoluteTiming[
  mq["multiquadraticStripDecomposeForcing"][bbar, roots]];
say["1 forcing channel decomposition (interned): ",
  Round[decomposeSeconds, 0.1], " s"];

(* 1b. the SAME decomposition without interning.  Measured only in the
   CHEAP mode: on the real block this doubles a ~40-minute stage to
   learn something the distinct-entry count below already bounds, which
   is not a defensible use of a shared machine.  The cheap mode is where
   the identity "interned == uninterned" is established; the real run
   inherits that statement rather than re-paying for it. *)
If[mode === "cheap",
  clear[];
  {rawDecomposeSeconds, rawChannels} = AbsoluteTiming[
    Map[mq["multiquadraticStripDecomposeScalar"][#, roots] &, bbar, {3}]];
  say["1b forcing channel decomposition (NOT interned): ",
    Round[rawDecomposeSeconds, 0.1], " s; interning saves ",
    Round[rawDecomposeSeconds - decomposeSeconds, 0.1], " s"];
  decompositionIdentical = SameQ[channels, rawChannels];
  say["  interned == uninterned decomposition: ", decompositionIdentical],
  rawDecomposeSeconds = Missing["NotMeasuredOnRealBlock"];
  decompositionIdentical = Missing["EstablishedByTheCheapGate"];
  say["1b uninterned decomposition NOT measured on the real block (see \
the cheap gate)"]];

(* 1c. the population: how many entries, how many DISTINCT entries, and
   how many are root free (the scalar-local fast path) *)
entries = Flatten[bbar];
distinctEntries = Length[DeleteDuplicates[entries]];
pathStatistics = mq["multiquadraticFieldPathStatistics"][];
say["1c BBar entries ", Length[entries], ", structurally distinct ",
  distinctEntries, ", root-free fast path ",
  Lookup[pathStatistics, "RootFreeFastPathCount", 0], ", algebraic ",
  Lookup[pathStatistics, "AlgebraicPathCount", 0]];

(* 2. the same through the sealed compile core: E and C as well *)
clear[];
{coreSeconds, core} = AbsoluteTiming[
  mq["multiquadraticStripCompileCoreRecord"][strip, roots, variables,
    regulator, Missing["NotSupplied"], {"cf300-attribution"}, True]];
say["2 sealed compile core (E + C + BBar, decomposed AND compiled): ",
  Round[coreSeconds, 0.1], " s, ok ", AssociationQ[core]];
sameChannels = AssociationQ[core] &&
  SameQ[channels, Lookup[Lookup[core, "BBar", <||>], "Channels", $Failed]];
say["  core BBar channels SameQ the independent decomposition: ",
  sameChannels];

(* 3. the gauge denominator, built FROM those channels *)
{denominatorSeconds, gaugeDenominator} = AbsoluteTiming[
  mq["multiquadraticRationalGaugeDenominator"][channels, variables]];
say["3 rational gauge denominator from the channels: ",
  Round[denominatorSeconds, 0.1], " s, degrees ",
  Exponent[gaugeDenominator, #] & /@ variables];

(* 4. the ABI payload: the whole-strip canonical InputForm *)
{payloadSeconds, canonical} = AbsoluteTiming[
  mq["multiquadraticStripCoreCanonicalData"][record, roots, variables,
    regulator]];
say["4 ABI canonical data (whole-strip InputForm + root texts): ",
  Round[payloadSeconds, 0.1], " s, equation text ",
  StringLength[canonical["EquationCanonical"]], " chars"];

(* 5. the candidate-letter construction, the one prepare stage not yet
   attributed anywhere.  On the production route the top level builds
   the alphabet and hands it to prepare, so this is the cost a
   FIRST-CALL prepare pays when it builds its own. *)
{letterSeconds, letterData} = AbsoluteTiming[
  mq["multiquadraticStripCandidateLetters"][strip, roots, variables,
    regulator, record, "RegulatorSampleCount" -> 2]];
say["5 candidate letters: ", Round[letterSeconds, 0.1], " s, status ",
  Lookup[letterData, "Status", None], ", letters ",
  Length[Lookup[letterData, "LetterRecords", {}]]];

(* 6. the norm denominator factor, which the gauge denominator merges *)
{normSeconds, normFactor} = AbsoluteTiming[
  If[MatchQ[Lookup[letterData, "LetterRecords", None], {___Association}],
    mq["multiquadraticStripNormDenominatorFactor"][
      letterData["LetterRecords"], variables], 1]];
say["6 algebraic-letter norm denominator factor: ",
  Round[normSeconds, 0.1], " s"];

total = decomposeSeconds + denominatorSeconds + payloadSeconds +
  letterSeconds + normSeconds;
say["ATTRIBUTION: decomposition ", Round[decomposeSeconds, 0.1],
  " s + gauge denominator ", Round[denominatorSeconds, 0.1],
  " s + ABI canonical ", Round[payloadSeconds, 0.1],
  " s + candidate letters ", Round[letterSeconds, 0.1],
  " s + norm factor ", Round[normSeconds, 0.1], " s = ",
  Round[total, 0.1], " s of the stages measured here"];
say["dominant stage: ", First[Keys[ReverseSort[<|
  "ForcingDecomposition" -> decomposeSeconds,
  "GaugeDenominator" -> denominatorSeconds,
  "ABICanonical" -> payloadSeconds,
  "CandidateLetters" -> letterSeconds,
  "NormFactor" -> normSeconds|>]]]];

Put[<|"Schema" -> "CF300PrepareAttributionV2",
  "Mode" -> mode,
  "Descriptor" -> {record["Family"], record["Sector"], record["LowerSector"]},
  "SourceSHA256" -> If[! smallFixtureQ,
    FileHash[stripFile, "SHA256", "HexString"], Missing["SyntheticFixture"]],
  "BBarDimensions" -> Dimensions[bbar],
  "BBarLeafCount" -> LeafCount[bbar],
  "BBarEntryCount" -> Length[entries],
  "BBarDistinctEntryCount" -> distinctEntries,
  "ELeafCount" -> LeafCount[strip[[1]]],
  "CLeafCount" -> LeafCount[strip[[2]]],
  "RootRank" -> Length[roots],
  "ForcingDecompositionSeconds" -> decomposeSeconds,
  "ForcingDecompositionUninternedSeconds" -> rawDecomposeSeconds,
  "DecompositionIdentical" -> decompositionIdentical,
  "ChannelPathStatistics" -> pathStatistics,
  "SealedCoreSeconds" -> coreSeconds,
  "CoreChannelsSameQ" -> sameChannels,
  "GaugeDenominatorSeconds" -> denominatorSeconds,
  "GaugeDenominatorDegrees" -> (Exponent[gaugeDenominator, #] & /@ variables),
  "ABICanonicalSeconds" -> payloadSeconds,
  "ABIEquationTextLength" -> StringLength[canonical["EquationCanonical"]],
  "CandidateLetterSeconds" -> letterSeconds,
  "CandidateLetterCount" -> Length[Lookup[letterData, "LetterRecords", {}]],
  "NormDenominatorFactorSeconds" -> normSeconds,
  "MeasuredStageTotalSeconds" -> total,
  "ReferencePrepareSeconds" -> If[! smallFixtureQ, 2710.9,
    Missing["SyntheticFixture"]],
  "ReferenceCompileSeconds" -> If[! smallFixtureQ, 91.3,
    Missing["SyntheticFixture"]],
  "PeakMemoryBytes" -> MaxMemoryUsed[],
  "RunAt" -> DateString["ISODateTime"]|>, out];
say["written ", out];
Exit[0];
