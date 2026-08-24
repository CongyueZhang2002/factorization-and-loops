#!/usr/bin/env wolframscript
(* Adjacent microbenchmark: rational scalars inside a declared rank-three
   field.  The candidate path pads grade zero and independently recomposes;
   it is an oracle for the staged scalar-local root-free optimization. *)

projectRoot = FixedPoint[
  If[FileExistsQ[FileNameJoin[{#1, "FeynFacet", "FeynFacet.m"}]], #1,
    DirectoryName[#1]] &,
  DirectoryName[ExpandFileName[$InputFileName]]
];
Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];

private[name_String] := Symbol["FeynFacet`Private`" <> name];
decompose = private["multiquadraticFieldDecompose"];
compose = private["multiquadraticFieldCompose"];
currentRoots = private["transportChartCurrentRoots"];

Clear[s, t, eta, cs, ct];
frame = FeynFacet`BuildAlgebraicTransportFrame[
  {1 + s, 2 + t, 3 + s + t + s t}, {s, t}, {cs, ct}];
roots = currentRoots[frame, {s, t}];
rank = Length[roots]; gradeCount = 2^rank;

scalars = Table[Together[
  (i + (1 + Mod[i, 7]) s + (1 + Mod[2 i, 11]) t +
     (1 + Mod[i, 5]) s t + eta (1 + Mod[i, 3]))/
  (17 + i + (1 + Mod[3 i, 13]) s + (1 + Mod[5 i, 17]) t +
     (1 + Mod[i, 4]) s^2 + (1 + Mod[i, 6]) t^2)],
  {i, 1, 240}];

fastPath[expression_] := Module[{rational, channels, reconstructed},
  rational = Together[expression];
  If[! FreeQ[rational,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]], Return[$Failed]];
  channels = PadRight[{rational}, gradeCount, 0];
  reconstructed = compose[channels, roots];
  If[TrueQ[Together[reconstructed - expression] === 0], channels, $Failed]
];

(* Warm both code paths outside the measurement. *)
decompose[First[scalars], roots];
fastPath[First[scalars]];

baselineTimes = Table[
  First[AbsoluteTiming[baseline = decompose[#1, roots] & /@ scalars]],
  {3}];
fastTimes = Table[
  First[AbsoluteTiming[candidate = fastPath /@ scalars]],
  {3}];

same = SameQ[baseline, candidate] && FreeQ[baseline, $Failed] &&
  AllTrue[baseline, Length[#1] === gradeCount &] &&
  AllTrue[baseline, Rest[#1] === ConstantArray[0, gradeCount - 1] &];
baselineMedian = Median[baselineTimes];
fastMedian = Median[fastTimes];
speedup = If[fastMedian > 0, baselineMedian/fastMedian, Infinity];

Print["rank=", rank, " gradeCount=", gradeCount,
  " rationalScalars=", Length[scalars]];
Print["baselineSeconds=", InputForm[baselineTimes],
  " median=", InputForm[baselineMedian]];
Print["candidateSeconds=", InputForm[fastTimes],
  " median=", InputForm[fastMedian]];
Print["speedup=", InputForm[speedup]];
Print["exactSameQ=", same];
Exit[If[TrueQ[same], 0, 1]];
