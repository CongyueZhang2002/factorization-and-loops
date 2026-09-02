#!/usr/bin/env wolframscript
(* Overhaul benchmark harness (2026-09-02, goal 6: measurement first).

   Times a fixed list of representative operations of the package and
   appends one TSV row per item to the output file, so that the same
   script run before and after a change gives a before/after table.

   Usage: benchmark_overhaul.wls <output.tsv> [item ...]
   Items (default: all):
     load          package load (this kernel's own load is measured by
                   AbsoluteTiming around LoadFACET)
     ot_CF27       observable transport of CF27 (rational, 8 masters)
     ot_CF230      observable transport of CF230 (Kallen1 chart, 13 masters)
     ot_CF385      observable transport of CF385 (modular acceptance family)
     ff_strip      finite-field affine strip solve on the frozen (9,6)
                   fixture of BenchmarkStripBackends/frozen_M0 (if present)
     dbe_synthetic diagonal-block eps-form on the 2x2 synthetic block of
                   Tests/EpsilonForm/t_diagonal_block_epsform.wls
     dbe_class<N>  diagonal-block eps-form on class N of the repository's
                   block-class ledger (stage-1 production route; class 97
                   is one of the three hard classes)
   Inputs are read from the repository's Results tree; nothing is written
   there.  Every row records the item, the status of the result, the
   wall seconds and the peak memory in MiB. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
args = Rest[$ScriptCommandLine];
If[Length[args] < 1, Print["usage: benchmark_overhaul.wls <output.tsv> [item ...]"]; Exit[64]];
outputFile = args[[1]];
items = If[Length[args] > 1, Rest[args],
  {"load", "ot_CF27", "ot_CF230", "ot_CF385", "dbe_synthetic", "dbe_class1", "dbe_class97"}];
results = "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
row[item_, status_, seconds_, extra_: ""] := Module[{line},
  line = StringRiffle[{DateString["ISODateTime"], item, ToString[status],
    ToString[NumberForm[N[seconds], {8, 3}]],
    ToString[Round[MaxMemoryUsed[]/2^20]], extra}, "\t"];
  Print["[benchmark] ", line];
  WriteString[OpenAppend[outputFile], line <> "\n"]; Close[outputFile]];

loadSeconds = First[AbsoluteTiming[
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]]];
If[MemberQ[items, "load"], row["load", "OK", loadSeconds,
  "commit=" <> StringTrim[Quiet[Check[Import["!cd " <> root <> " && git rev-parse --short HEAD", "Text"], "?"]]]]];

observableTransportItem[family_String] := Module[
  {epsFile, deFile, valFile, eps, de, val, demand, result, seconds},
  epsFile = FileNameJoin[{root, results, "FamilyEpsFormsCertified", "family_epsform_" <> family <> ".wl"}];
  deFile = FileNameJoin[{root, results, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}];
  valFile = FileNameJoin[{root, results, "MasterCoefficientValuations.wl"}];
  If[! FileExistsQ[epsFile] || ! FileExistsQ[deFile] || ! FileExistsQ[valFile],
    Return[row["ot_" <> family, "InputMissing", 0]]];
  eps = FeynFacet`FamilyArtifactRead[epsFile];
  de = FeynFacet`FamilyArtifactRead[deFile];
  val = Get[valFile];
  demand = FeynFacet`BuildObservableTransportDemand[eps, de, val];
  If[Lookup[demand, "Status", None] =!= "ExactObservableDemand",
    Return[row["ot_" <> family, Lookup[demand, "Status", "DemandFailed"], 0]]];
  {seconds, result} = AbsoluteTiming[FeynFacet`BuildObservableTransport[eps, demand]];
  row["ot_" <> family, Lookup[result, "Status", "?"], seconds,
    "pairs=" <> ToString[Length[Lookup[result, "PhysicalDemandPairs", {}]]] <>
    " weight=" <> ToString[Lookup[result, "MaximumWeight", "?"]] <>
    " boundary=" <> ToString[Lookup[result, "BoundaryCoordinates", "?"]]];
  ClearAll[eps, de, val, demand, result]];

Do[Which[
  item === "load", Null,
  StringStartsQ[item, "ot_"], observableTransportItem[StringDrop[item, 3]],
  item === "dbe_synthetic", Module[{x, y, ep, Rx, Ry, Rxy, Bx, By, T0, T0i, Ax, Ay, tog, seconds, result},
    (* the synthetic irreducible 2x2 block of Tests/EpsilonForm/t_diagonal_block_epsform.wls:
       a flat KZ-type dlog form hidden behind a rational gauge with an eps-dependent apparent locus *)
    {x, y, ep} = {Symbol["Global`x"], Symbol["Global`y"], Symbol["Global`eps"]};
    tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
    Rx = {{1, 1}, {0, 0}}; Ry = {{0, 0}, {1, 1}}; Rxy = -(Rx + Ry);
    Bx = ep (Rx/x + Rxy/(x - y)); By = ep (Ry/y - Rxy/(x - y));
    T0 = {{1, ep x/(x - y)}, {y/x, 1 + y}}; T0i = tog[Inverse[T0]];
    Ax = tog[T0 . Bx . T0i + D[T0, x] . T0i]; Ay = tog[T0 . By . T0i + D[T0, y] . T0i];
    {seconds, result} = AbsoluteTiming[Quiet[FeynFacet`DiagonalBlockEpsForm[{Ax, Ay}, {x, y}, ep]]];
    row["dbe_synthetic", Lookup[result, "Status", Head[result]], seconds]],
  StringStartsQ[item, "dbe_class"], Module[{id, ledger, classes, class, v, w, ep, matrices, seconds, result},
    (* a REAL block class from the repository's ledger (stage 1 stays a
       maintained route, user ruling 2026-09-02): DiagonalBlockEpsForm on
       the class representative, as DiagonalBlockClassCampaign runs it *)
    id = ToExpression[StringDrop[item, 9]];
    ledger = FileNameJoin[{root, results, "BlockClasses", "classes.wl"}];
    If[! FileExistsQ[ledger], row[item, "InputMissing", 0],
      classes = FeynFacet`FamilyArtifactRead[ledger];
      classes = If[AssociationQ[classes] && KeyExistsQ[classes, "Classes"], classes["Classes"], classes];
      class = SelectFirst[classes, AssociationQ[#] && Lookup[#, "ClassID", None] === id &, None];
      If[class === None, row[item, "ClassMissing", 0],
        {v, w, ep} = {Symbol["Global`v"], Symbol["Global`w"], Symbol["Global`eps"]};
        matrices = FeynFacet`Private`diagonalBlockTogether /@ {class["RepAv"], class["RepAw"]};
        {seconds, result} = AbsoluteTiming[Quiet[FeynFacet`DiagonalBlockEpsForm[matrices, {v, w}, ep]]];
        row[item, Lookup[result, "Status", Head[result]], seconds,
          "dimension=" <> ToString[Length[matrices[[1]]]] <> " method=" <> ToString[Lookup[result, "Method", "?"]]]]]],
  True, row[item, "UnknownItem", 0]], {item, items}];
Print["[benchmark] done"];
