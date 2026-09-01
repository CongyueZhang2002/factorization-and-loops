#!/usr/bin/env wolframscript

(* Reconstruct one missing block-25 coupling from the authoritative accepted
   row gauges, then restrict it to the same direct-u path used by the
   elliptic operator.  The exception gauge itself is literal zero, hence

     Omega_(25,m) = A_(25,m) - Sum_(m<l<25) D_(25,l) A_(l,m).

   Pullback is performed before the products are assembled. *)

$HistoryLength = 0;
$RecursionLimit = Infinity;
requestedText = Environment["CF303_EXCEPTION_BLOCK"];
If[! StringQ[requestedText] || requestedText === "",
  Print["CF303_EXCEPTION_BLOCK is required"]; Exit[2]];
requestedBlock = ToExpression[requestedText];
If[! MemberQ[{1, 2, 11, 14, 18}, requestedBlock],
  Print["exception block must be 1,2,11,14,18"]; Exit[2]];

stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-30_cf303_25_2_exact_common_path/resume/" <>
  "sector_state_CF303_standard.wl";
checkpointFile = "/home/maxzhang/factorization-and-loops/" <>
  "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/" <>
  "FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF303/" <>
  "sector_CF303_standard/CF303_25_strip_state.wl";
outputRoot = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues";
outputFile = FileNameJoin[{outputRoot,
  "cf303_block25_exception_" <> ToString[requestedBlock] <>
    "_direct_u_path.maple"}];
metadataFile = FileNameJoin[{outputRoot,
  "cf303_block25_exception_" <> ToString[requestedBlock] <>
    "_direct_u_path_metadata.wl"}];

{loadSeconds, loaded} = AbsoluteTiming[
  state = Get[stateFile]; checkpoint = Get[checkpointFile]];
ranges = state["Ranges"];
connection = state["A"];
If[Dimensions[checkpoint["PrevD"]] =!= {2, 43} ||
    ranges[[25]] =!= {44, 45},
  Print["REFUSED unexpected final row layout"]; Exit[3]];

gauges = Association@Table[block ->
  checkpoint["PrevD"][[All, ranges[[block]]]], {block, 24}];
If[! AllTrue[{1, 2, 11, 14, 18},
    Flatten[gauges[#]] === ConstantArray[0, Length[Flatten[gauges[#]]]] &],
  Print["REFUSED exception gauge is not literal zero"]; Exit[4]];

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
pathRoots = Map[<|"Root" -> #["Root"],
    "RootSquare" -> Together[#["RootSquare"] /. pathRules]|> &,
  sourceRoots];
rootImages = {rho, a - p, 1 + u*a};

rootBranchScale[base_, rootSquare_] := Module[{ratio, scale},
  If[SameQ[base, rootSquare] ||
      TrueQ[Together[base - rootSquare] === 0], Return[1]];
  If[TrueQ[Together[rootSquare] === 0], Return[None]];
  ratio = Together[base/rootSquare];
  If[! MatchQ[ratio, _Integer | _Rational] || ! TrueQ[ratio > 0],
    Return[None]];
  scale = Sqrt[ratio];
  If[MatchQ[scale, _Integer | _Rational], scale, None]];

applyRootBranches[expr_] := Fold[Function[{current, index},
  current /. Power[base_, exponent_Rational] :> Module[
    {factor = If[Denominator[exponent] === 2,
       rootBranchScale[base, pathRoots[[index, "RootSquare"]]], None]},
    If[factor === None, Power[base, exponent],
      (factor rootImages[[index]])^(2 exponent)]]],
  expr, Range[Length[sourceRoots]]];

(* The branch table is expressed on the path.  Substitute the path first,
   then replace the resulting square roots by their chosen images. *)
functionOnPath[expr_] := applyRootBranches[expr /. pathRules];
formOnPath[form_] := applyRootBranches[
  D[xPath, u] (form[[1]] /. pathRules) +
    D[yPath, u] (form[[2]] /. pathRules)];

activeFeeders = Select[Range[requestedBlock + 1, 24],
  ! AllTrue[Flatten[gauges[#]], SameQ[#, 0] &] &];
{pullSeconds, pulled} = AbsoluteTiming[
  rawPath = formOnPath[
    connection[[All, ranges[[25]], ranges[[requestedBlock]]]]];
  feederGaugePaths = AssociationMap[functionOnPath[gauges[#]] &,
    activeFeeders];
  feederConnectionPaths = AssociationMap[formOnPath[
      connection[[All, ranges[[#]], ranges[[requestedBlock]]]]] &,
    activeFeeders];
  pulled = rawPath - Total[Table[
      feederGaugePaths[feeder] . feederConnectionPaths[feeder],
      {feeder, activeFeeders}]]];

residualRadicands = DeleteDuplicates[Cases[pulled,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :> base,
  Infinity]];
If[residualRadicands =!= {},
  Print["REFUSED residual radicals ", InputForm[residualRadicands]];
  Exit[5]];

targets = Flatten[Table[{row, column}, {row, ranges[[25]]},
  {column, ranges[[requestedBlock]]}], 1];
entries = Flatten[pulled];
mapleString[value_] := StringReplace[
  ToString[value, InputForm, PageWidth -> Infinity],
  {"Global`" -> "", "FeynFacet`Private`" -> ""}];
mapleList[list_] := "[" <> StringRiffle[mapleString /@ list, ","] <> "]";
mapleTargets[list_] := "[" <> StringRiffle[
  ("[" <> StringRiffle[ToString /@ #, ","] <> "]") & /@ list,
  ","] <> "]";
text = "exceptionBlock := " <> ToString[requestedBlock] <> ":\n" <>
  "exceptionTargets := " <> mapleTargets[targets] <> ":\n" <>
  "exceptionEntries := " <> mapleList[entries] <> ":\n";
Export[outputFile, text, "Text"];
metadata = <|"Status" -> "CF303Block25ExceptionDirectUPathV1",
  "Block" -> requestedBlock, "Rows" -> ranges[[25]],
  "Columns" -> ranges[[requestedBlock]], "Targets" -> targets,
  "EntryCount" -> Length[entries], "ActiveFeeders" -> activeFeeders,
  "LeafCounts" -> LeafCount /@ entries,
  "ResidualRadicands" -> residualRadicands,
  "Seconds" -> <|"Load" -> loadSeconds, "Pullback" -> pullSeconds|>,
  "OutputBytes" -> FileByteCount[outputFile], "Output" -> outputFile|>;
Put[metadata, metadataFile];
Print[InputForm[metadata]];
Exit[0];
