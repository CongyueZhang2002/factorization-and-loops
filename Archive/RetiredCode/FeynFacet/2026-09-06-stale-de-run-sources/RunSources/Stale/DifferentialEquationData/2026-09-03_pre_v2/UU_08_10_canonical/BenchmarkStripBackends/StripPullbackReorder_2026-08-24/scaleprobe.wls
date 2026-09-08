#!/usr/bin/env wolframscript
(* The rational square-class branch scaling under the NEW ordering.

   Measured in equiv.wls: on the real CF259 KallenQ4a strip the radicand
   CARRIED by the entries after the chart substitution equals the declared
   pulled-back square exactly (scale 1), because the kernel extracts a
   rational square factor only from a radicand that already has one at top
   level -- which is what Together MAKES of it.  So the c != 1 branch is
   reached by the OLD ordering, and this probe measures both:

     A. the carried bases of the OLD ordering (entries Together-normalized
        BEFORE the branch substitution) and their square class against the
        declared squares -- does the old order really need c != 1?
     B. a forced c != 1: the declared square is handed over as
        RootSquare/c^2 with the image as root/c, which is exactly the
        configuration transportChartRootBranchScale was written for.  Both
        orderings must then return the SAME result as the unscaled data.

   Acceptance criterion, stated before the run: in B the branch scale is
   exactly c, and the scaled OLD, scaled NEW and unscaled NEW outputs agree
   entrywise with Together-difference zero.                              *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
scratch = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{scratch, "old_path.wl"}]];

registration = FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "TransportFamilyCharts.wl"}]];
Print["chart registration: ", Lookup[registration, "Status", None]];
campaign = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-24_fable"}];

zeroQ[e_] := TrueQ[Together[e] === 0];
allZeroQ[a_, b_] := AllTrue[Flatten[{a - b}], zeroQ];

cases = {
  <|"Family" -> "CF303", "Label" -> "CF303 block 13_2, one root, Kallen2",
    "File" -> FileNameJoin[{campaign, "CF303", "sector_CF303_standard",
      "CF303_13_2_input.wl"}], "Scales" -> {2}|>,
  <|"Family" -> "CF259",
    "Label" -> "CF259 block 19_11, two roots, KallenQ4a",
    "File" -> FileNameJoin[{campaign, "CF259", "sector_CF259_standard",
      "CF259_19_11_input.wl"}], "Scales" -> {2, 4}|>};

verdicts = {};
Do[
 Module[{record, strip, variables, epsilon, frame, allRoots, classification,
   rootIndices, usedRoots, rootSquares, chart, chartVariables, rekeyed, data,
   chartRoots, rootImages, chartBranchRoots, newUnscaled, oldBases, oldScales,
   scales, scaledRoots, scaledImages, measuredScales, newScaled, oldScaled,
   substituted, ok},
  Print["\n==== ", case["Label"], " ===="];
  record = FeynFacet`FamilyArtifactRead[case["File"]];
  strip = record["Strip"]; variables = record["Variables"];
  epsilon = record["Regulator"];
  frame = FeynFacet`TransportFamilyChart[case["Family"]];
  allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
  classification = FeynFacet`Private`transportChartRootIndices[strip, allRoots];
  rootIndices = classification["RootIndices"];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  chart = FeynFacet`TransportRootSetChart[rootSquares, variables];
  chartVariables = {Symbol["FeynFacet`Private`stripChartX"],
    Symbol["FeynFacet`Private`stripChartY"]};
  rekeyed = FeynFacet`Private`transportChartRekey[chart, variables, chartVariables];
  data = FeynFacet`Private`masterTransportChartData[rekeyed, variables];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      zeroQ[#["RootSquare"] - usedRoots[[i]]["RootSquare"]] &, Missing[]]},
    matching["Root"]], {i, Length[usedRoots]}];
  chartBranchRoots = Map[
    <|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &, usedRoots];
  Print["  chart ", chart["Name"], ", roots ", rootIndices];

  (* ---- A. what the OLD ordering carries ---------------------------- *)
  substituted = Map[Together, strip /. data["Subst"], {4}];
  oldBases = DeleteDuplicates[
    FeynFacet`Private`transportChartRadicalBases[substituted]];
  oldScales = Table[Table[
    FeynFacet`Private`transportChartRootBranchScale[
      b, chartBranchRoots[[i]]["RootSquare"]], {i, Length[chartBranchRoots]}],
    {b, oldBases}];
  Print["  A. OLD ordering (Together BEFORE the branch substitution): ",
    Length[oldBases], " carried bases, square classes vs the declared \
squares = ", oldScales];
  Print["     -> the old ordering needed c != 1: ",
    AnyTrue[Flatten[oldScales], IntegerQ[#] && # =!= 1 &] ||
      AnyTrue[Flatten[oldScales], MatchQ[#, _Rational] &]];

  (* ---- B. forced c != 1 in the NEW ordering ------------------------ *)
  newUnscaled = FeynFacet`Private`newChartStripPipeline[
    strip, data, chartBranchRoots, rootImages];
  scales = case["Scales"];
  scaledRoots = Table[<|"RootSquare" ->
    Together[chartBranchRoots[[i]]["RootSquare"]/scales[[i]]^2]|>,
    {i, Length[chartBranchRoots]}];
  scaledImages = Table[Together[rootImages[[i]]/scales[[i]]],
    {i, Length[rootImages]}];
  measuredScales = Table[
    FeynFacet`Private`transportChartRootBranchScale[
      chartBranchRoots[[i]]["RootSquare"], scaledRoots[[i]]["RootSquare"]],
    {i, Length[scaledRoots]}];
  Print["  B. declared square handed over as RootSquare/c^2 with image \
root/c, c = ", scales];
  Print["     measured branch scales = ", measuredScales,
    "  (must equal c)"];
  newScaled = FeynFacet`Private`newChartStripPipeline[
    strip, data, scaledRoots, scaledImages];
  oldScaled = FeynFacet`Private`oldChartStripPipeline[
    strip, data, scaledRoots, scaledImages];
  ok = measuredScales === scales &&
    allZeroQ[newScaled, newUnscaled] && allZeroQ[oldScaled, newScaled];
  Print["     scaled NEW == unscaled NEW: ", allZeroQ[newScaled, newUnscaled]];
  Print["     scaled OLD == scaled NEW  : ", allZeroQ[oldScaled, newScaled]];
  Print["     VERDICT: ", ok];
  AppendTo[verdicts, ok];
 ], {case, cases}];

Print["\nall square-class checks passed: ", AllTrue[verdicts, TrueQ]];
Exit[If[AllTrue[verdicts, TrueQ], 0, 1]];
