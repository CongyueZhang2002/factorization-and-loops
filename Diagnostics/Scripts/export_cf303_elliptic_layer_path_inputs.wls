#!/usr/bin/env wolframscript

(* Export only the exact path kernels needed for the first mixed eMPL
   milestone: the block-15 homogeneous connection and the accepted final
   row-25 <- block-15 residual form.  The latter is read directly from the
   accepted SolvedForms checkpoint; rebuilding the installed row creates
   million-leaf expressions for an object already stored compactly. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-30_cf303_25_2_exact_common_path/resume/" <>
  "sector_state_CF303_standard.wl";
checkpointFile = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-28_codex_clean", "CF303",
  "sector_CF303_standard", "CF303_25_strip_state.wl"}];
outputFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_elliptic_layer_path_inputs.maple";
metadataFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_elliptic_layer_path_inputs_metadata.wl";

LaunchKernels[6];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
private[name_] := Symbol["FeynFacet`Private`" <> name];

Print["PHASE load accepted connection and final-row residual form"];
{loadSeconds, inputs} = AbsoluteTiming[
  state = Get[stateFile];
  checkpoint = Get[checkpointFile]];
ranges = state["Ranges"];
If[Length[ranges] =!= 25 || ranges[[15]] =!= Range[23, 25] ||
    ranges[[25]] =!= Range[44, 45],
  Print["REFUSED unexpected CF303 range layout: ", InputForm[ranges]];
  CloseKernels[]; Exit[2]];
solvedForms = checkpoint["SolvedForms"];
If[! AssociationQ[solvedForms] || ! KeyExistsQ[solvedForms, 15] ||
    Dimensions[solvedForms[15]] =!= {2, 2, 3},
  Print["REFUSED missing accepted 25<-15 residual form"];
  CloseKernels[]; Exit[3]];

Clear[x, y, eps, p, u, rho];
delta1 = 1 - 2*x + x^2 + 2*y + 2*x*y + y^2;
delta2 = 1 + 2*x + x^2 - 2*y + 2*x*y + y^2;
delta3 = 1 - 4*x*y;
k = 4*p*(1 - p);
a = (k - 2*u)/(u^2 + k);
xPath = -a*p;
yPath = (1 - a)*(1 - p);
pathRules = {x -> xPath, y -> yPath};
sourceRoots = {
  <|"Root" -> Sqrt[delta1], "RootSquare" -> delta1|>,
  <|"Root" -> Sqrt[delta2], "RootSquare" -> delta2|>,
  <|"Root" -> Sqrt[delta3], "RootSquare" -> delta3|>};
pathRoots = Map[
  <|"Root" -> #1["Root"],
    "RootSquare" -> Together[#1["RootSquare"] /. pathRules]|> &,
  sourceRoots];
rootImages = {rho, a - p, 1 + u*a};

pullbackForm[form_] := Module[{raw},
  raw = D[xPath, u] (form[[1]] /. pathRules) +
    D[yPath, u] (form[[2]] /. pathRules);
  private["transportChartApplyRootBranches"][raw, pathRoots, rootImages]];

Print["PHASE exact targeted pullback"];
{pullbackSeconds, pulled} = AbsoluteTiming[
  block15FeederBlocks = {1, 6, 9, 11, 12, 14};
  block15FullColumns = Flatten[ranges[[Join[block15FeederBlocks, {15}]]]];
  block15Full = pullbackForm[
    state["A"][[All, ranges[[15]], block15FullColumns]]];
  block15Diagonal = pullbackForm[
    state["A"][[All, ranges[[15]], ranges[[15]]]]];
  row25FromBlock15 = pullbackForm[solvedForms[15]]];
residualRadicals = DeleteDuplicates[Cases[pulled,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :> base,
  Infinity]];
If[residualRadicals =!= {},
  Print[InputForm[<|"Status" -> "EllipticLayerBranchReductionFailed",
    "ResidualRadicands" -> residualRadicals|>]];
  CloseKernels[]; Exit[4]];

block15Targets = Flatten[Table[{row, column},
  {row, ranges[[15]]}, {column, ranges[[15]]}], 1];
block15FullTargets = Flatten[Table[{row, column},
  {row, ranges[[15]]}, {column, block15FullColumns}], 1];
row25Targets = Flatten[Table[{row, column},
  {row, ranges[[25]]}, {column, ranges[[15]]}], 1];
block15Entries = Extract[block15Diagonal,
  ({First[#1] - First[ranges[[15]]] + 1,
      Last[#1] - First[ranges[[15]]] + 1} &) /@ block15Targets];
block15FullEntries = Extract[block15Full,
  ({First[#1] - First[ranges[[15]]] + 1,
      First@FirstPosition[block15FullColumns, Last[#1]]} &) /@
    block15FullTargets];
row25Entries = Extract[row25FromBlock15,
  ({First[#1] - First[ranges[[25]]] + 1,
      Last[#1] - First[ranges[[15]]] + 1} &) /@ row25Targets];

mapleString[value_] := StringReplace[
  ToString[value, InputForm, PageWidth -> Infinity],
  {"Global`" -> "", "FeynFacet`Private`" -> ""}];
mapleList[list_] := "[" <> StringRiffle[mapleString /@ list, ","] <> "]";
mapleTargets[list_] := "[" <> StringRiffle[
  ("[" <> StringRiffle[ToString /@ #1, ","] <> "]") & /@ list,
  ","] <> "]";
text = StringRiffle[{
  "block15FeederBlocks := " <> mapleList[block15FeederBlocks] <> ":",
  "block15FullColumns := " <> mapleList[block15FullColumns] <> ":",
  "block15FullTargets := " <> mapleTargets[block15FullTargets] <> ":",
  "block15FullEntries := " <> mapleList[block15FullEntries] <> ":",
  "block15Targets := " <> mapleTargets[block15Targets] <> ":",
  "block15Entries := " <> mapleList[block15Entries] <> ":",
  "row25Targets := " <> mapleTargets[row25Targets] <> ":",
  "row25Entries := " <> mapleList[row25Entries] <> ":"}, "\n"] <> "\n";
Export[outputFile, text, "Text"];

metadata = <|
  "Status" -> "CF303EllipticLayerPathInputsV1",
  "StateFile" -> stateFile, "CheckpointFile" -> checkpointFile,
  "Row25Block15Route" -> "AcceptedSolvedForms[15]",
  "SubkernelCount" -> Length[Kernels[]],
  "Block15FeederBlocks" -> block15FeederBlocks,
  "Block15FullColumns" -> block15FullColumns,
  "Block15FullTargets" -> block15FullTargets,
  "Block15Targets" -> block15Targets,
  "Row25Targets" -> row25Targets,
  "Block15LeafCounts" -> (LeafCount /@ block15Entries),
  "Block15FullLeafCounts" -> (LeafCount /@ block15FullEntries),
  "Row25LeafCounts" -> (LeafCount /@ row25Entries),
  "ResidualRadicands" -> residualRadicals,
  "PhaseSeconds" -> <|"Load" -> loadSeconds,
    "Pullback" -> pullbackSeconds|>,
  "OutputBytes" -> FileByteCount[outputFile], "Output" -> outputFile|>;
Put[metadata, metadataFile];
Print[InputForm[metadata]];
CloseKernels[];
Exit[0];
