#!/usr/bin/env wolframscript

(* Targeted, single-kernel export of the three CF303 elliptic layers that
   follow block 15.  This deliberately reads only the accepted family state
   and the completed block-25 row checkpoint.  It does not load FeynFacet or
   rebuild any family data. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;

stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-30_cf303_25_2_exact_common_path/resume/" <>
  "sector_state_CF303_standard.wl";
checkpointFile = "/home/maxzhang/factorization-and-loops/" <>
  "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/" <>
  "FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF303/" <>
  "sector_CF303_standard/CF303_25_strip_state.wl";
outputFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_remaining_elliptic_layer_path_inputs.maple";
metadataFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_remaining_elliptic_layer_path_inputs_metadata.wl";

Print["PID ", $ProcessID, " OUTPUT ", outputFile];
Print["PHASE load accepted state/checkpoint (one main kernel, no subkernels)"];
{loadSeconds, loaded} = AbsoluteTiming[
  state = Get[stateFile];
  checkpoint = Get[checkpointFile]];
If[! AssociationQ[state] || ! AssociationQ[checkpoint],
  Print["REFUSED invalid accepted input"]; Exit[2]];
ranges = state["Ranges"];
connection = state["A"];
If[Length[ranges] =!= 25 || Dimensions /@ connection =!=
    {{45, 45}, {45, 45}} || ranges[[15]] =!= Range[23, 25] ||
    ranges[[25]] =!= Range[44, 45],
  Print["REFUSED unexpected CF303 layout"]; Exit[3]];

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

(* Exact local copy of the generic branch matcher used by TransportCharts.
   Keeping it here avoids loading the package merely to perform this one
   targeted export. *)
rootBranchScale[base_, rootSquare_] := Module[{ratio, scale},
  If[SameQ[base, rootSquare] ||
      TrueQ[Together[base - rootSquare] === 0], Return[1]];
  If[TrueQ[Together[rootSquare] === 0], Return[None]];
  ratio = Together[base/rootSquare];
  If[! MatchQ[ratio, _Integer | _Rational] || ! TrueQ[ratio > 0],
    Return[None]];
  scale = Sqrt[ratio];
  If[MatchQ[scale, _Integer | _Rational], scale, None]];

applyRootBranches[expr_, roots_List, images_List] := Module[{scale},
  scale[base_, index_] := scale[base, index] =
    rootBranchScale[base, roots[[index]]["RootSquare"]];
  Fold[Function[{current, index},
    current /. Power[base_, exponent_Rational] :>
      Module[{factor = If[Denominator[exponent] === 2,
          scale[base, index], None]},
        If[factor === None, Power[base, exponent],
          (factor images[[index]])^(2 exponent)]]],
    expr, Range[Length[roots]]]];

pullbackForm[form_] := Module[{raw},
  raw = D[xPath, u] (form[[1]] /. pathRules) +
    D[yPath, u] (form[[2]] /. pathRules);
  applyRootBranches[raw, pathRoots, rootImages]];

activeColumns[form_, columns_] := Pick[columns,
  Map[! AllTrue[Flatten[form[[All, #]]], SameQ[#, 0] &] &,
    Range[Length[columns]]]];

extractEntries[form_, rows_, columns_, active_] := Flatten[Table[
  form[[row - First[rows] + 1,
    First@FirstPosition[columns, column]]],
  {row, rows}, {column, active}]];

entryTargets[rows_, active_] := Flatten[
  Table[{row, column}, {row, rows}, {column, active}], 1];

joinForms[forms_List] := Fold[Join[#1, #2, 2] &, First[forms],
  Rest[forms]];

Print["PHASE targeted path pullbacks for blocks 17 and 21"];
{middleSeconds, middleData} = AbsoluteTiming[
  middleData = AssociationMap[Function[block, Module[
      {rows, columns, full, active},
      rows = ranges[[block]];
      columns = Range[Last[rows]];
      full = pullbackForm[connection[[All, rows, columns]]];
      active = activeColumns[full, columns];
      <|"Rows" -> rows, "Columns" -> active,
        "Targets" -> entryTargets[rows, active],
        "Entries" -> extractEntries[full, rows, columns, active]|>]],
    {17, 21}]];

Print["PHASE accepted block-25 solved-form path pullback"];
{block25Seconds, block25Data} = AbsoluteTiming[
  solvedForms = Lookup[checkpoint, "SolvedForms", <||>];
  solvedKeys = Sort[Keys[solvedForms]];
  If[! AssociationQ[solvedForms] || solvedKeys === {} ||
      ! AllTrue[solvedKeys, Dimensions[solvedForms[#]] ===
        {2, 2, Length[ranges[[#]]]} &],
    Print["REFUSED malformed block-25 solved forms"]; Exit[4]];
  lowerPathForms = pullbackForm /@ Lookup[solvedForms, solvedKeys];
  diagonalPathForm = pullbackForm[
    connection[[All, ranges[[25]], ranges[[25]]]]];
  block25Full = joinForms[Append[lowerPathForms, diagonalPathForm]];
  block25MissingBlocks = Complement[Range[24], solvedKeys];
  block25Columns = Join[Flatten[ranges[[solvedKeys]]], ranges[[25]]];
  block25Active = activeColumns[block25Full, block25Columns];
  block25Data = <|"Rows" -> ranges[[25]],
    "Columns" -> block25Active,
    "Targets" -> entryTargets[ranges[[25]], block25Active],
    "Entries" -> extractEntries[block25Full, ranges[[25]],
      block25Columns, block25Active]|>];

allEntries = Join @@ Lookup[Values[
  Append[middleData, 25 -> block25Data]], "Entries"];
residualRadicals = DeleteDuplicates[Cases[allEntries,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :> base,
  Infinity]];
If[residualRadicals =!= {},
  Print[InputForm[<|"Status" -> "RemainingEllipticBranchReductionFailed",
    "ResidualRadicands" -> residualRadicals|>]]; Exit[5]];

mapleString[value_] := StringReplace[
  ToString[value, InputForm, PageWidth -> Infinity],
  {"Global`" -> "", "FeynFacet`Private`" -> ""}];
mapleList[list_] := "[" <> StringRiffle[mapleString /@ list, ","] <> "]";
mapleTargets[list_] := "[" <> StringRiffle[
  ("[" <> StringRiffle[ToString /@ #1, ","] <> "]") & /@ list,
  ","] <> "]";

text = StringRiffle[Flatten@Table[With[{data = If[block === 25,
      block25Data, middleData[block]], tag = "block" <> ToString[block]},
    {tag <> "Rows := " <> mapleList[data["Rows"]] <> ":",
     tag <> "Columns := " <> mapleList[data["Columns"]] <> ":",
     tag <> "Targets := " <> mapleTargets[data["Targets"]] <> ":",
     tag <> "Entries := " <> mapleList[data["Entries"]] <> ":"}],
  {block, {17, 21, 25}}], "\n"] <> "\n";
Export[outputFile, text, "Text"];

metadata = <|"Status" -> "CF303RemainingEllipticLayerPathInputsV1",
  "StateFile" -> stateFile, "CheckpointFile" -> checkpointFile,
  "Block25Route" -> "AcceptedSolvedFormsPlusDiagonal",
  "Block25SolvedBlocks" -> solvedKeys,
  "Block25DeferredExceptionBlocks" -> block25MissingBlocks,
  "MainKernelCount" -> 1, "SubkernelCount" -> Length[Kernels[]],
  "Blocks" -> AssociationMap[Function[block, With[
      {data = If[block === 25, block25Data, middleData[block]]},
      <|"Rows" -> data["Rows"], "Columns" -> data["Columns"],
        "EntryCount" -> Length[data["Entries"]],
        "LeafCounts" -> (LeafCount /@ data["Entries"])|>]],
    {17, 21, 25}],
  "ResidualRadicands" -> residualRadicals,
  "PhaseSeconds" -> <|"Load" -> loadSeconds,
    "Blocks17And21" -> middleSeconds, "Block25" -> block25Seconds|>,
  "OutputBytes" -> FileByteCount[outputFile], "Output" -> outputFile|>;
Put[metadata, metadataFile];
Print[InputForm[metadata]];
Exit[0];
