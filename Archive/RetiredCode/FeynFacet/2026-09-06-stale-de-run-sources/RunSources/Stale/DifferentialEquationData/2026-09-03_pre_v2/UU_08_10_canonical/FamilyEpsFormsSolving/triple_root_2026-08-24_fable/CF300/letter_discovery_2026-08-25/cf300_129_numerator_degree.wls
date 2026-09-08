#!/usr/bin/env wolframscript
(* Does the CF300 (12,9) defect survive a gauge pole AT INFINITY?
   The 2026-08-25 census enlargement raised the DENOMINATOR (degrees
   {13,12}, support 182) and kept the support rectangular at the
   denominator degree.  That function space does NOT contain
   {x^p y^q r_g / Q_merged} with p,q above deg Q_merged: writing the
   latter over Q_enlarged = Q_merged R needs numerator degree up to
   (11+4, 11+3), beyond the enlarged rectangle.  So a numerator degree
   ABOVE the denominator degree -- a gauge pole at infinity -- is a
   direction not yet measured.  Codex Q2 lists infinity explicitly. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
$t0 = AbsoluteTime[];
say[a___] := WriteString["stdout", ToString[Round[AbsoluteTime[] - $t0, 0.01]],
   "s | ", StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}], "\n"];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];
out = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/cf300_offset_confirm_result.wl";

FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`TransportFamilyChart["CF300"];
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "triple_root_2026-08-24_fable", "CF300"}];
record = FeynFacet`FamilyArtifactRead[
   FileNameJoin[{base, "sector_CF300_standard", "CF300_12_9_input.wl"}],
   "Global`"];
state = FeynFacet`FamilyArtifactRead[
   FileNameJoin[{base, "sector_state_CF300_standard.wl"}], "Global`"];
record = Join[record, <|"StripSolvers" -> Lookup[state, "StripSolvers", {}]|>];
state =.;
variables = record["Variables"]; regulator = record["Regulator"];
allRoots = FeynFacet`Private`transportChartCurrentRoots[chart, variables];
census = mq["multiquadraticStripRootCensus"][record["Strip"], allRoots];
order = mq["multiquadraticStripRootOrder"][chart, variables,
   census["RootIndices"], regulator];
roots = order["Roots"];
letters = mq["multiquadraticStripCandidateLetters"][record["Strip"], roots,
   variables, regulator, record, "RegulatorSampleCount" -> 2];
say["letters ", Length[letters["OneForms"]]];
channelForcing = Get[FileNameJoin[{base, "gauge_screen_2026-08-25",
   "channelForcing.wl"}]];
merged = mq["multiquadraticStripMergeGaugeDenominator"][
   mq["multiquadraticRationalGaugeDenominator"][channelForcing, variables],
   mq["multiquadraticStripNormDenominatorFactor"][letters["LetterRecords"],
     variables], variables];

results = {};
Do[
  Module[{an, r, t},
   an = mq["multiquadraticStripGaugeAnsatz"][record, roots,
      letters["OneForms"], merged, "DegreeOffset" -> offset];
   {t, r} = AbsoluteTiming[mq["multiquadraticStripGaugeScreenImages"][an,
      "Images" -> {{2147483423, 1/13}, {2147483399, 3/17}},
      "ConfirmConsistency" -> True, "LeftNullSpace" -> False]];
   say["DegreeOffset ", offset, ": support ",
     Length[an["GaugeSupport"]], ", unknowns ", an["UnknownCount"], " -> ",
     KeyTake[r, {"Status", "ImageCount", "Defects"}], " images ",
     KeyTake[#, {"Defect", "Rank", "AugmentedRank", "Nullity",
       "MatrixDimensions"}] & /@ r["ImageResults"],
     "  (", Round[t, 0.1], " s)"];
   AppendTo[results, <|"DegreeOffset" -> offset,
     "SupportCount" -> Length[an["GaugeSupport"]],
     "UnknownCount" -> an["UnknownCount"],
     "Verdict" -> KeyTake[r, {"Status", "ImageCount", "Defects", "Images"}],
     "ImageResults" -> (KeyDrop[#, {"Witness", "Ansatz"}] & /@
        r["ImageResults"]), "Seconds" -> t|>]],
  {offset, {{2, 2}, {3, 3}, {2, 0}, {0, 2}}}];

Put[<|"Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9,
   "GaugeDenominator" -> merged, "AlphabetSize" -> Length[letters["OneForms"]],
   "Offsets" -> results|>, out];
say["written ", out];
say["DONE"];
