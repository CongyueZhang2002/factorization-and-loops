#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
If[! NameQ["FeynFacet`DiagonalBlockSliceEpsForm"],
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

Clear[xEdge, yEdge, epsEdge];
x = xEdge; y = yEdge; eps = epsEdge;
zeroPair = {{{0}}, {{0}}};
record = <|
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {{{{1}}, {{0}}}, zeroPair, {{{1 - eps x}}, {{0}}}}
|>;

invalidSupport = TimeConstrained[Quiet[Check[
  FeynFacet`SampleEpsFormStripAffine[record, 1/21, 1000003,
    "PointCount" -> 8, "NumeratorDegreeOffset" -> {0, 0},
    "Support" -> {{99, 0}}, "SolveAffineSystem" -> False],
  $Failed]], 10, $TimedOut];

(* At eps=1/q, Round[lambda] identifies an epsilon coefficient only
   modulo q.  Residues above q/2 expose the ambiguity immediately. *)
rx = DiagonalMatrix[{60, 61}];
ax = eps rx/x;
ay = ConstantArray[0, {2, 2}];
numeric = TimeConstrained[
  FeynFacet`DiagonalBlockSliceEpsForm[{ax, ay}, {x, y}, eps,
    "Engine" -> "NumericalEps", "RegulatorValues" -> {1/101},
    "MaximumBalances" -> 10], 20, <|"Status" -> "TimedOut"|>];
symbolic = TimeConstrained[
  FeynFacet`DiagonalBlockSliceEpsForm[{ax, ay}, {x, y}, eps,
    "Engine" -> "Symbolic", "MaximumBalances" -> 10],
  20, <|"Status" -> "TimedOut"|>];

Print[InputForm[<|
  "InvalidSupportHead" -> Head[invalidSupport],
  "InvalidSupportStatus" -> If[AssociationQ[invalidSupport],
    Lookup[invalidSupport, "Status", "AssociationWithoutStatus"], Missing[]],
  "NumericSlice" -> If[AssociationQ[numeric],
    KeyTake[numeric, {"Status", "Engine", "RegulatorValue",
      "SliceResidues", "BalanceCount"}], numeric],
  "SymbolicSlice" -> If[AssociationQ[symbolic],
    KeyTake[symbolic, {"Status", "Engine", "SliceResidues",
      "BalanceCount"}], symbolic],
  "SpectraAgree" -> If[AssociationQ[numeric] && AssociationQ[symbolic] &&
      numeric["Status"] === "OK" && symbolic["Status"] === "OK",
    (Sort[Eigenvalues[#]] & /@ numeric["SliceResidues"]) ===
      (Sort[Eigenvalues[#]] & /@ symbolic["SliceResidues"]), False]
|>]];

Exit[0];
