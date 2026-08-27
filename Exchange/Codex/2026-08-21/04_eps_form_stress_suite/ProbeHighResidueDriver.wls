#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
If[! NameQ["FeynFacet`DiagonalBlockEpsForm"],
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

Clear[xDriver, yDriver, epsDriver];
x = xDriver; y = yDriver; eps = epsDriver;
rx0 = {{1, 1}, {0, 0}};
ry0 = {{0, 0}, {1, 1}};
rxy0 = -(rx0 + ry0);
scale = 60;
ax = eps scale (rx0/x + rxy0/(x - y));
ay = eps scale (ry0/y - rxy0/(x - y));
common = {
  "Primes" -> {1000003},
  "EpsilonSampleCount" -> 16,
  "MaximumEpsilonSampleCount" -> 32,
  "SpectatorSampleCount" -> Automatic,
  "MultiplicitySlack" -> {0},
  "NumeratorDegreeOffsets" -> {{0, 0}},
  "Shears" -> {}, "ChartRetry" -> False,
  "Verbose" -> False
};

numericSlice = FeynFacet`DiagonalBlockSliceEpsForm[{ax, ay}, {x, y}, eps,
  "Engine" -> "NumericalEps", "RegulatorValues" -> {1/101}];
symbolicSlice = FeynFacet`DiagonalBlockSliceEpsForm[{ax, ay}, {x, y}, eps,
  "Engine" -> "Symbolic"];

numericDriver = TimeConstrained[
  FeynFacet`DiagonalBlockEpsForm[{ax, ay}, {x, y}, eps,
    "Engine" -> "NumericalEps", "RegulatorValues" -> {1/101},
    Sequence @@ common], 30, <|"Status" -> "TimedOut"|>];
symbolicDriver = TimeConstrained[
  FeynFacet`DiagonalBlockEpsForm[{ax, ay}, {x, y}, eps,
    "Engine" -> "Symbolic", Sequence @@ common],
  30, <|"Status" -> "TimedOut"|>];

Print[InputForm[<|
  "NumericSliceResidues" -> If[AssociationQ[numericSlice],
    Lookup[numericSlice, "SliceResidues", Missing[]], numericSlice],
  "SymbolicSliceResidues" -> If[AssociationQ[symbolicSlice],
    Lookup[symbolicSlice, "SliceResidues", Missing[]], symbolicSlice],
  "SliceSpectraAgree" -> If[AssociationQ[numericSlice] &&
      AssociationQ[symbolicSlice] && numericSlice["Status"] === "OK" &&
      symbolicSlice["Status"] === "OK",
    (Sort[Eigenvalues[#]] & /@ numericSlice["SliceResidues"]) ===
      (Sort[Eigenvalues[#]] & /@ symbolicSlice["SliceResidues"]), False],
  "NumericDriver" -> If[AssociationQ[numericDriver],
    KeyTake[numericDriver, {"Status", "Frame", "Method", "Attempts", "Timing"}],
    numericDriver],
  "SymbolicDriver" -> If[AssociationQ[symbolicDriver],
    KeyTake[symbolicDriver, {"Status", "Frame", "Method", "Attempts", "Timing"}],
    symbolicDriver]
|>]];

Exit[0];
