#!/usr/bin/env wolframscript

$HistoryLength = 0;
$RecursionLimit = Infinity;
repo = "/home/maxzhang/factorization-and-loops";
stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-30_cf303_25_2_exact_common_path/resume/" <>
  "sector_state_CF303_standard.wl";
outputFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_block25_source_gauge.maple";
metadataFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/" <>
  "2026-08-31_cf303_native_dlog_residues/" <>
  "cf303_block25_source_gauge_metadata.wl";

LaunchKernels[6];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];

{loadSeconds, state} = AbsoluteTiming[Get[stateFile]];
range = state["Ranges"][[25]];
sourceIDs = Flatten[state["Blocks"]][[range]];
sBlock = state["S"][[range, range]];
tDiagonalBlock = state["TDiagonal"][[range, range]];
If[sBlock =!= IdentityMatrix[2],
  Print["REFUSED nonidentity block-25 diagonal slice of S: ",
    InputForm[sBlock]]; CloseKernels[]; Exit[2]];
sourceFromCanonical = tDiagonalBlock . sBlock;

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
{pullbackSeconds, pathGauge} = AbsoluteTiming[
  FeynFacet`Private`transportChartApplyRootBranches[
    sourceFromCanonical /. pathRules, pathRoots, rootImages]];
residualRadicals = DeleteDuplicates[Cases[pathGauge,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :> base,
  Infinity]];
If[residualRadicals =!= {},
  Print["REFUSED residual radicals: ", InputForm[residualRadicals]];
  CloseKernels[]; Exit[3]];

mapleString[value_] := StringReplace[
  ToString[value, InputForm, PageWidth -> Infinity],
  {"Global`" -> "", "FeynFacet`Private`" -> ""}];
entries = Flatten[pathGauge];
text = "sourceIDs := [" <> StringRiffle[ToString /@ sourceIDs, ","] <>
  "]:\nsourceGaugeEntries := [" <>
  StringRiffle[mapleString /@ entries, ","] <> "]:\n";
Export[outputFile, text, "Text"];
metadata = <|"Status" -> "CF303Block25SourceGaugeV1",
  "SourceIDs" -> sourceIDs, "AssemblyRange" -> range,
  "Orientation" -> "I_source_block25=T25.F_canonical_block25",
  "SBlockIdentity" -> True, "SubkernelCount" -> Length[Kernels[]],
  "ResidualRadicands" -> residualRadicals,
  "LeafCounts" -> (LeafCount /@ entries),
  "PhaseSeconds" -> <|"Load" -> loadSeconds,
    "Pullback" -> pullbackSeconds|>,
  "OutputBytes" -> FileByteCount[outputFile], "Output" -> outputFile|>;
Put[metadata, metadataFile];
Print[InputForm[metadata]];
CloseKernels[];
Exit[0];
