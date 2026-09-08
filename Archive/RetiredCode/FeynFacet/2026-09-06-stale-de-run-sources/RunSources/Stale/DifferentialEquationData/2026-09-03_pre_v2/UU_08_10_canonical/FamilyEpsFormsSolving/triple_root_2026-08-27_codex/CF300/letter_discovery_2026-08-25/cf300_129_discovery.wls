#!/usr/bin/env wolframscript
(* WITNESS-GUIDED MIXED-GRADE LETTER DISCOVERY on CF300 (12,9).
   Build the measured ansatz (54 letters, merged denominator, degrees
   {9,9}, support 100, 1816 unknowns), run the full-gauge per-image
   screen, take its left obstruction witness, and score every
   mixed-grade candidate letter against it: y.C != 0 is necessary,
   subset defect 0 is sufficient.  Confirm any repair at a second
   independent image. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
$t0 = AbsoluteTime[];
say[a___] := (WriteString["stdout", ToString[Round[AbsoluteTime[] - $t0, 0.01]],
   "s | ", StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}],
   "\n"]; );
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];
out = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/cf300_discovery_wide_result.wl";

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
{vx, vy} = variables;
allRoots = FeynFacet`Private`transportChartCurrentRoots[chart, variables];
census = mq["multiquadraticStripRootCensus"][record["Strip"], allRoots];
order = mq["multiquadraticStripRootOrder"][chart, variables,
   census["RootIndices"], regulator];
roots = order["Roots"];
say["strip ", {record["Sector"], record["LowerSector"]}, ", root rank ",
  Length[roots], ", squares ", Lookup[roots, "RootSquare", {}]];

{lt, letters} = AbsoluteTiming[mq["multiquadraticStripCandidateLetters"][
   record["Strip"], roots, variables, regulator, record,
   "RegulatorSampleCount" -> 2]];
say["letters (", Round[lt, 0.1], " s): ", letters["Counts"], " total ",
  Length[letters["OneForms"]]];

channelForcing = Get[FileNameJoin[{base, "gauge_screen_2026-08-25",
   "channelForcing.wl"}]];
engineDenominator = mq["multiquadraticRationalGaugeDenominator"][
   channelForcing, variables];
merged = mq["multiquadraticStripMergeGaugeDenominator"][engineDenominator,
   mq["multiquadraticStripNormDenominatorFactor"][letters["LetterRecords"],
     variables], variables];
ansatz = mq["multiquadraticStripGaugeAnsatz"][record, roots,
   letters["OneForms"], merged];
say["ansatz: degrees ", ansatz["GaugeDenominatorDegrees"], ", support ",
  Length[ansatz["GaugeSupport"]], ", unknowns ", ansatz["UnknownCount"]];

(* --- the polar census factor set, from the MEASURED channel census --- *)
censusFactors = mq["multiquadraticStripRationalPolarCurves"][
   Flatten[channelForcing], Lookup[roots, "RootSquare", {}], variables];
(* Codex Q2/Q3: the candidate divisor set is the UNION of the measured
   channel-denominator census and the strip's own polar alphabet, not
   either alone *)
censusFactors = mq["multiquadraticStripRationalPolarCurves"][
   {}, Join[censusFactors, letters["Alphabet"]], variables];
say["polar census factors (channel census UNION strip alphabet): ",
  censusFactors];

{gt, mixed} = AbsoluteTiming[mq["multiquadraticStripMixedGradeLetters"][
   roots, censusFactors, variables, "MaximumDegree" -> 3,
   "Alphabet" -> censusFactors, "MaximumSolutionsPerPrime" -> 40,
   "CombinationOrder" -> 2, "CombinationBasisLimit" -> 16]];
say["mixed-grade generator (", Round[gt, 0.1], " s): ", mixed["Count"],
  " letters, ", mixed["TrivialSolutionCount"], " trivial skipped, ",
  mixed["CandidatesTested"], " solution-space points tested"];
Do[say["   split ", KeyTake[d, {"Factor", "Status", "SplitGrades",
   "RamifiedGrades", "FullSplit"}]], {d, mixed["Diagnostics"]}];

(* candidate one-forms: dlog of each mixed-grade letter, keeping only the
   ones that are genuinely NEW (not already an alphabet one-form) *)
existingKeys = Association[(mq["multiquadraticStripFormTextKey"][#,
     variables, regulator] -> True) & /@ letters["OneForms"]];
candidateRecords = {}; candidateForms = {};
Do[
  Module[{form, key},
   form = mq["multiquadraticStripLetterOneForm"][entry["Letter"], variables];
   If[form === $Failed || ! MatchQ[form, {_, _}], Continue[]];
   If[! mq["multiquadraticStripFieldMemberQ"][form[[1]], roots] ||
      ! mq["multiquadraticStripFieldMemberQ"][form[[2]], roots], Continue[]];
   key = mq["multiquadraticStripFormTextKey"][form, variables, regulator];
   If[KeyExistsQ[existingKeys, key], Continue[]];
   AssociateTo[existingKeys, key -> True];
   AppendTo[candidateRecords, Join[entry, <|"OneForm" -> form|>]];
   AppendTo[candidateForms, form]],
  {entry, mixed["LetterRecords"]}];
say["candidate one-forms NEW to the alphabet: ", Length[candidateForms]];
Do[say["   C", i, " L=", candidateRecords[[i]]["Letter"], "  grades ",
   candidateRecords[[i]]["GradeSupport"], "  norm ",
   Factor[candidateRecords[[i]]["Norm"]]], {i, Length[candidateRecords]}];

pairs = If[Length[candidateForms] >= 2,
   Subsets[Range[Length[candidateForms]], {2}], {}];
subsets = Join[pairs, If[Length[candidateForms] >= 1,
   {Range[Length[candidateForms]]}, {}]];

{s1, image1} = AbsoluteTiming[mq["multiquadraticStripGaugeScreen"][ansatz,
   "Prime" -> 2147483423, "RegulatorValue" -> 1/13,
   "RandomSeed" -> 20260825, "CandidateOneForms" -> candidateForms,
   "CandidateSubsets" -> subsets]];
say["IMAGE 1 (", Round[s1, 0.1], " s): ", KeyTake[image1, {"Status", "Defect",
  "Rank", "AugmentedRank", "Nullity", "LeftNullity", "MatrixDimensions",
  "PointCount"}]];
say["  witness: ", If[AssociationQ[image1["Witness"]],
   KeyTake[image1["Witness"], {"TransposeResidualZero",
     "RightHandSidePairing", "Support"}], image1["Witness"]]];
Do[say["  score C", s["Index"], " pierces ", s["PiercesWitness"],
   " rankContribution ", s["RankContribution"], " defect ", s["Defect"],
   "   norm ", Factor[candidateRecords[[s["Index"]]]["Norm"]]],
  {s, image1["CandidateScores"]}];
say["  candidates with a NEW column direction (rank contribution > 0): ",
  Length[Select[image1["CandidateScores"], #["RankContribution"] > 0 &]],
  " of ", Length[image1["CandidateScores"]]];
say["  total rank contribution of ALL candidates together: ",
  If[image1["CandidateSubsetResults"] === {}, 0,
   Last[image1["CandidateSubsetResults"]]["Defect"]], " (defect of the full set)"];
repairing = Select[image1["CandidateSubsetResults"], #["Defect"] === 0 &];
say["  subsets with defect 0: ", Length[repairing], " of ",
  Length[image1["CandidateSubsetResults"]]];
Do[say["   repairing subset ", r["Indices"]], {r, Take[repairing, UpTo[20]]}];

singletonRepair = Select[image1["CandidateScores"], #["Defect"] === 0 &];
piercing = Select[image1["CandidateScores"], TrueQ[#["PiercesWitness"]] &];
say["  singletons that repair: ", Lookup[singletonRepair, "Index", {}]];
say["  singletons that pierce the witness: ", Lookup[piercing, "Index", {}]];

(* confirm any repair at a SECOND independent image *)
best = Which[
   singletonRepair =!= {}, {First[singletonRepair]["Index"]},
   repairing =!= {}, First[repairing]["Indices"],
   True, {}];
image2 = Missing["NotRun"];
If[best =!= {},
  say["confirming subset ", best, " at a second image"];
  {s2, image2} = AbsoluteTiming[mq["multiquadraticStripGaugeScreen"][
     mq["multiquadraticStripGaugeAnsatz"][record, roots,
       Join[letters["OneForms"], candidateForms[[best]]], merged],
     "Prime" -> 2147483399, "RegulatorValue" -> 3/17,
     "RandomSeed" -> 77123]];
  say["IMAGE 2 with the repair (", Round[s2, 0.1], " s): ",
    KeyTake[image2, {"Status", "Defect", "Rank", "AugmentedRank",
      "Nullity", "MatrixDimensions", "UnknownCount"}]],
  say["NO candidate subset (singleton or pair) reaches defect 0 -- ",
    "measured NEGATIVE at mixed-grade degree bound 2 over ",
    Length[censusFactors], " census factors"]];

Put[<|"Family" -> "CF300", "Sector" -> record["Sector"],
   "LowerSector" -> record["LowerSector"],
   "Ansatz" -> KeyTake[ansatz, {"GaugeDenominator",
     "GaugeDenominatorDegrees", "GaugeSupport", "UnknownCount",
     "GaugeUnknownCount", "ResidueUnknownCount"}],
   "AlphabetSize" -> Length[letters["OneForms"]],
   "CensusFactors" -> censusFactors,
   "MixedGradeDiagnostics" -> mixed["Diagnostics"],
   "MixedGradeCount" -> mixed["Count"],
   "CandidateRecords" -> (KeyDrop[#, {"OneForm"}] & /@ candidateRecords),
   "Image1" -> KeyDrop[image1, {"Witness"}],
   "WitnessSummary" -> If[AssociationQ[image1["Witness"]],
     KeyDrop[image1["Witness"], {"Vector"}], image1["Witness"]],
   "RepairingSubsets" -> repairing,
   "ConfirmedSubset" -> best,
   "Image2" -> If[AssociationQ[image2], KeyDrop[image2, {"Witness"}], image2]|>,
  out];
say["written ", out];
say["DONE"];
