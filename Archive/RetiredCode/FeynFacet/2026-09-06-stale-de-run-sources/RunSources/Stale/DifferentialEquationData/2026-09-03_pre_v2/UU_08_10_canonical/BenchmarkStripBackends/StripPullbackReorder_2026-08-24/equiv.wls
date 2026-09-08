#!/usr/bin/env wolframscript
(* Exact-equivalence and timing comparison of the OLD (HEAD 1833bf4) and
   NEW strip-pullback ordering in FeynFacet/Private/TransportCharts.wl.

   Acceptance criterion, stated before the run: for every case the NEW
   pipeline output equals the OLD one ENTRYWISE with Together-difference
   exactly zero, and both are free of symbolic radicals wherever the old
   one was.  Timing is reported as measured wall seconds of each pipeline.

   Usage: equiv.wls <caseIndex|ALL> [oldTimeLimitSeconds]                *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
scratch = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{scratch, "old_path.wl"}]];

Print["FeynFacet source hash: ", FeynFacet`Private`$feynFacetSourceHash];

argv = Rest[$ScriptCommandLine];
selection = If[Length[argv] >= 1, First[argv], "ALL"];
oldLimit = If[Length[argv] >= 2, ToExpression[argv[[2]]], 3600];
(* rows of e / bbar kept (All = the whole strip); a size series is how a
   pipeline that does not finish at full size is still measured *)
rowLimit = If[Length[argv] >= 3, ToExpression[argv[[3]]], All];
(* the box is shared with the production pool: a radical Together can
   allocate tens of GB (CF385, 2026-08-22, took the VM down twice) *)
memoryCap = 12 * 1024^3;
guard[expr_] := MemoryConstrained[TimeConstrained[expr, oldLimit, "TimedOut"],
  memoryCap, "OutOfMemory"];

registration = FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "TransportFamilyCharts.wl"}]];
Print["chart registration: ", Lookup[registration, "Status", None]];

campaign = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-24_fable"}];

cases = {
  <|"Tag" -> "rational", "Family" -> "CF303",
    "Label" -> "rational-only strip, no radicals (CF303 block 16_1)",
    "File" -> FileNameJoin[{campaign, "CF303", "sector_CF303_standard",
      "CF303_16_1_input.wl"}], "ForceChart" -> "Kallen1"|>,
  <|"Tag" -> "oneroot", "Family" -> "CF303",
    "Label" -> "single root lambda2 -> Kallen2 (CF303 block 13_2)",
    "File" -> FileNameJoin[{campaign, "CF303", "sector_CF303_standard",
      "CF303_13_2_input.wl"}], "ForceChart" -> None|>,
  <|"Tag" -> "tworoot", "Family" -> "CF303",
    "Label" -> "two roots {lambda2, lambda3} -> Kallen23 (CF303 block 15_1)",
    "File" -> FileNameJoin[{campaign, "CF303", "sector_CF303_standard",
      "CF303_15_1_input.wl"}], "ForceChart" -> None|>,
  <|"Tag" -> "squareclass", "Family" -> "CF259",
    "Label" -> "two roots {lambda1, 4v+w^2} -> KallenQ4a, rational square-class scaling (CF259 block 19_11)",
    "File" -> FileNameJoin[{campaign, "CF259", "sector_CF259_standard",
      "CF259_19_11_input.wl"}], "ForceChart" -> None|>,
  <|"Tag" -> "heavy", "Family" -> "CF303",
    "Label" -> "HEAVIEST real strip: single root lambda2 -> Kallen2 (CF303 block 13_1, 1.9 MB, 7776 radicals)",
    "File" -> FileNameJoin[{campaign, "CF303", "sector_CF303_standard",
      "CF303_13_1_input.wl"}], "ForceChart" -> None|>
};

selected = If[selection === "ALL", cases,
  Select[cases, #["Tag"] === selection &]];
If[selected === {}, Print["no such case: ", selection]; Exit[2]];

zeroQ[e_] := TrueQ[Together[e] === 0];
allZeroQ[a_, b_] := AllTrue[Flatten[{a - b}], zeroQ];
symbolicRadicalQ[expr_] := ! FreeQ[expr,
  Power[b_ /; ! NumericQ[b], r_Rational /; Denominator[r] === 2]];
leaf[expr_] := LeafCount[expr];

results = {};

Do[
 Module[{record, strip, variables, epsilon, frame, allRoots, classification,
   rootIndices, usedRoots, rootSquares, chart, chartVariables, rekeyed,
   data, chartRoots, rootImages, chartBranchRoots, carriedBases, scales,
   tOld, oldChart, tNew, newChart, sourceGauge, m, n, branchImages,
   tOldId, oldId, tNewId, newId, chartEqual, idEqual, dims, entry},
  Print["\n==== ", case["Label"], " ===="];
  record = FeynFacet`FamilyArtifactRead[case["File"]];
  If[! AssociationQ[record], Print["  artifact unreadable"]; Continue[]];
  strip = record["Strip"]; variables = record["Variables"];
  epsilon = record["Regulator"];
  If[rowLimit =!= All,
    strip = {strip[[1, All, 1 ;; rowLimit, 1 ;; rowLimit]], strip[[2]],
      strip[[3, All, 1 ;; rowLimit, All]]};
    Print["  TRUNCATED to the first ", rowLimit, " rows of e / bbar"]];
  dims = Dimensions /@ (First /@ strip);
  Print["  variables ", variables, ", regulator ", epsilon,
    ", block dims e/c/bbar = ", dims,
    ", strip leaf count = ", leaf[strip]];
  (* exactly as Scripts/family_epsform_sector.wls builds it *)
  frame = FeynFacet`TransportFamilyChart[case["Family"]];
  Print["  frame: ", Lookup[frame, "Status", None], ", variables ",
    Lookup[frame, "Variables", None], ", roots ",
    Length[Lookup[frame, "Roots", {}]]];
  allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
  classification = FeynFacet`Private`transportChartRootIndices[strip, allRoots];
  rootIndices = classification["RootIndices"];
  Print["  root indices ", rootIndices,
    ", undeclared bases ", classification["UnclassifiedRadicalBases"]];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  chart = If[case["ForceChart"] === None,
    FeynFacet`TransportRootSetChart[rootSquares, variables],
    FeynFacet`TransportChartCatalog[][case["ForceChart"]]];
  If[! AssociationQ[chart], Print["  no chart: ", chart]; Continue[]];
  Print["  chart: ", Lookup[chart, "Name", None]];
  chartVariables = {Symbol["FeynFacet`Private`stripChartX"],
    Symbol["FeynFacet`Private`stripChartY"]};
  rekeyed = FeynFacet`Private`transportChartRekey[chart, variables, chartVariables];
  data = FeynFacet`Private`masterTransportChartData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK",
    Print["  chart data failed: ", data]; Continue[]];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      zeroQ[#["RootSquare"] - usedRoots[[i]]["RootSquare"]] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]],
    {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ],
    Print["  root map missing"]; Continue[]];
  chartBranchRoots = Map[
    <|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &, usedRoots];
  (* does the pullback really produce a base OFF the declared square by a
     rational square class?  (the branch scaling under test) *)
  carriedBases = DeleteDuplicates[
    FeynFacet`Private`transportChartRadicalBases[strip /. data["Subst"]]];
  scales = Table[
    Table[FeynFacet`Private`transportChartRootBranchScale[
      b, chartBranchRoots[[i]]["RootSquare"]], {i, Length[chartBranchRoots]}],
    {b, carriedBases}];
  Print["  carried radical bases after Subst: ", Length[carriedBases],
    ", branch scales against the declared squares: ", scales];

  (* ---- pipeline 1: the chart pullback of the strip ---------------- *)
  {tOld, oldChart} = AbsoluteTiming[guard[
    FeynFacet`Private`oldChartStripPipeline[strip, data, chartBranchRoots, rootImages]]];
  Print["  OLD chart pullback: ", Round[tOld, 0.01], " s",
    If[StringQ[oldChart], " (" <> oldChart <> ", limit " <> ToString[oldLimit] <> " s / 12 GB)", ""]];
  {tNew, newChart} = AbsoluteTiming[guard[
    FeynFacet`Private`newChartStripPipeline[strip, data, chartBranchRoots, rootImages]]];
  Print["  NEW chart pullback: ", Round[tNew, 0.01], " s",
    If[StringQ[newChart], " (" <> newChart <> ")",
      ", leaf count " <> ToString[leaf[newChart]] <>
      ", symbolic radicals left: " <> ToString[symbolicRadicalQ[newChart]]]];
  chartEqual = If[StringQ[oldChart] || StringQ[newChart],
    "OldStopped:" <> ToString[oldChart], allZeroQ[newChart, oldChart]];
  Print["  chart pullback OLD == NEW (entrywise Together difference zero): ",
    chartEqual,
    ";  structurally identical (SameQ, matters for the SameQ resume gate of FamilyRowGaugeResume): ",
    If[StringQ[oldChart] || StringQ[newChart], "n/a", SameQ[newChart, oldChart]]];

  (* ---- pipeline 2: the source-frame identity check ---------------- *)
  (* a synthetic gauge of the right shape carrying the declared radicals:
     the comparison is of the two ORDERINGS, not of a solved gauge *)
  m = Length[strip[[1, 1]]]; n = Length[strip[[2, 1]]];
  sourceGauge = Table[
    Together[(1 + i variables[[1]] + j variables[[2]] +
        Total[Table[(i + j + k) Sqrt[usedRoots[[k]]["RootSquare"]],
          {k, Length[usedRoots]}]]) /
      (1 + (i + j) variables[[1]] variables[[2]])],
    {i, m}, {j, n}];
  branchImages = rootImages;
  {tOldId, oldId} = AbsoluteTiming[guard[
    FeynFacet`Private`oldSourceIdentityPipeline[strip, data, variables,
      epsilon, sourceGauge, usedRoots, branchImages]]];
  Print["  OLD source identity: ", Round[tOldId, 0.01], " s",
    If[StringQ[oldId], " (" <> oldId <> ")", ""]];
  {tNewId, newId} = AbsoluteTiming[guard[
    FeynFacet`Private`newSourceIdentityPipeline[strip, data, variables,
      epsilon, sourceGauge, usedRoots, branchImages]]];
  Print["  NEW source identity: ", Round[tNewId, 0.01], " s",
    If[StringQ[newId], " (" <> newId <> ")",
      ", symbolic radicals left: " <> ToString[symbolicRadicalQ[newId]]]];
  idEqual = If[StringQ[oldId] || StringQ[newId],
    "OldStopped:" <> ToString[oldId], allZeroQ[newId, oldId]];
  Print["  source identity OLD == NEW (entrywise Together difference zero): ",
    idEqual, ";  structurally identical (SameQ): ",
    If[StringQ[oldId] || StringQ[newId], "n/a", SameQ[newId, oldId]]];

  entry = <|"Tag" -> case["Tag"], "Label" -> case["Label"],
    "Dims" -> dims, "RootIndices" -> rootIndices,
    "Chart" -> Lookup[chart, "Name", None],
    "BranchScales" -> scales,
    "PullBackOldSeconds" -> tOld, "PullBackNewSeconds" -> tNew,
    "PullBackEqual" -> chartEqual,
    "IdentityOldSeconds" -> tOldId, "IdentityNewSeconds" -> tNewId,
    "IdentityEqual" -> idEqual,
    "PullBackSameQ" -> If[StringQ[oldChart] || StringQ[newChart], "n/a",
      SameQ[newChart, oldChart]],
    "IdentitySameQ" -> If[StringQ[oldId] || StringQ[newId], "n/a",
      SameQ[newId, oldId]],
    "RowLimit" -> rowLimit,
    "NewRadicalFree" -> If[StringQ[newChart], newChart,
      ! symbolicRadicalQ[newChart]]|>;
  AppendTo[results, entry];
  Print["  RECORD: ", InputForm[KeyDrop[entry, "Label"]]];
 ], {case, selected}];

Print["\n===== SUMMARY ====="];
Do[Print[InputForm[r]], {r, results}];
Put[results, FileNameJoin[{scratch, "equiv_" <> selection <> "_" <> ToString[rowLimit] <> ".wl"}]];
Print["all equal: ", AllTrue[results,
  TrueQ[#["PullBackEqual"]] && TrueQ[#["IdentityEqual"]] &]];
Exit[If[AllTrue[results, TrueQ[#["PullBackEqual"]] && TrueQ[#["IdentityEqual"]] &], 0, 1]];
