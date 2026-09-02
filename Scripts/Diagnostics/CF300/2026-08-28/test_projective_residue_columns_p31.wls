#!/usr/bin/env wolframscript

Module[{repo, runtime, capture, prime, records, fixedColumns,
    complementColumns, frames, badFreeColumns = Range[16],
    particularColumn = 53, badColumns, stableRows, anchors,
    normalizeColumns, projectiveFrames, homogeneousFrames,
    makeSamples, projectiveTiming, projectiveInterpolation,
    homogeneousTiming, homogeneousInterpolation, summarizeFailures,
    supportByColumn, result},
  repo = "/home/maxzhang/factorization-and-loops";
  runtime = "/home/maxzhang/factorization-and-loops-codex/Runtime";
  SetDirectory[repo];
  If[Names["FeynFacet`SolveEpsFormBlockwise"] === {},
    Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]]];
  Block[{$Context = "FeynFacet`Private`",
      $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
    Get[FileNameJoin[{repo, "FeynFacet", "Private", "EpsForm",
      "FiniteFieldStripSolve.wl"}]]];
  capture = Import[FileNameJoin[{runtime,
    "cf300_aligned_schur_p31_76_checkpoint.wxf"}], "WXF"];
  prime = capture["Prime"];
  records = Rest[capture["Records"]];
  fixedColumns = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 129, 130, 131, 132, 133, 134, 135, 136, 138, 140, 141, 145,
    146, 147, 148, 149, 153, 154, 155, 156, 157, 158, 159, 160, 169,
    170, 171, 172, 177, 178, 179, 180, 181, 182, 183, 184};
  complementColumns = Complement[Range[212], fixedColumns];
  frames = Table[Module[{reduced, coefficient, right, core, rhs},
      reduced = records[[index, "RawReduced"]];
      coefficient = reduced[[All, 1 ;; 212]];
      right = reduced[[All, 213]];
      core = coefficient[[All, complementColumns]];
      rhs = Join[-coefficient[[All, fixedColumns]], List /@ right, 2];
      Mod[LinearSolve[core, rhs, Modulus -> prime], prime]],
    {index, Length[records]}];
  badColumns = Join[badFreeColumns, {particularColumn}];
  stableRows = Table[Select[Range[Length[complementColumns]],
      Function[row, AllTrue[frames, #[[row, column]] =!= 0 &]]],
    {column, badColumns}];
  If[MemberQ[stableRows, {}],
    Put[<|"Status" -> "NoStableProjectiveColumnAnchor",
      "Columns" -> Pick[badColumns, stableRows, {}]|>,
      FileNameJoin[{runtime,
        "cf300_projective_residue_columns_p31_summary.wl"}]];
    Return[$Failed]];
  anchors = First /@ stableRows;
  normalizeColumns[frame_, columns_List] := Module[{result = frame,
      position, column, anchor, inverse},
    Do[
      column = columns[[position]];
      anchor = anchors[[First[First[Position[badColumns, column]]]]];
      inverse = PowerMod[frame[[anchor, column]], -1, prime];
      result[[All, column]] = Mod[frame[[All, column]] inverse, prime],
      {position, Length[columns]}];
    result
  ];
  projectiveFrames = normalizeColumns[#, badColumns] & /@ frames;
  homogeneousFrames = normalizeColumns[#, badFreeColumns] & /@ frames;
  makeSamples[data_] := MapThread[
    <|"EpsilonValue" -> #1["RegulatorValue"],
      "EpsilonMod" -> #1["EpsilonMod"],
      "Values" -> Flatten[#2[[All, badColumns]]]|> &,
    {records, data}];
  {projectiveTiming, projectiveInterpolation} = AbsoluteTiming[
    FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
      makeSamples[projectiveFrames], prime,
      "InitialConstructionCount" -> 4, "HeldOutCount" -> 3,
      "MaximumTotalDegree" -> 64]];
  {homogeneousTiming, homogeneousInterpolation} = AbsoluteTiming[
    FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
      makeSamples[homogeneousFrames], prime,
      "InitialConstructionCount" -> 4, "HeldOutCount" -> 3,
      "MaximumTotalDegree" -> 64]];
  summarizeFailures[interpolation_] := Module[{failed, locations},
    failed = Lookup[interpolation, "DegreeBoundExceededCoordinates", {}];
    locations = ({Quotient[# - 1, Length[badColumns]] + 1,
         Mod[# - 1, Length[badColumns]] + 1} &) /@ failed;
    <|"Status" -> Lookup[interpolation, "Status", None],
      "ConsumedSampleCount" -> Lookup[interpolation,
        "ConsumedSampleCount", Missing[]],
      "FailureCount" -> Length[failed],
      "FailureColumns" -> Counts[If[locations === {}, {},
        locations[[All, 2]]]],
      "FailureRows" -> Counts[If[locations === {}, {},
        locations[[All, 1]]]],
      "CoordinateStatusHistogram" -> Lookup[interpolation,
        "CoordinateStatusHistogram", Missing[]],
      "DegreeHistogram" -> Lookup[interpolation,
        "DegreeHistogram", Missing[]]|>
  ];
  supportByColumn = AssociationThread[badColumns,
    Table[<|"AlwaysNonzeroRows" -> Length[stableRows[[position]]],
      "UnionNonzeroRows" -> Count[Range[Length[complementColumns]],
        row_ /; AnyTrue[frames,
          #[[row, badColumns[[position]]]] =!= 0 &]]|>,
      {position, Length[badColumns]}]];
  result = <|"Status" -> "CF300ProjectiveResidueColumnsTested",
    "Prime" -> prime, "ImageCount" -> Length[records],
    "BadColumns" -> badColumns, "Anchors" -> anchors,
    "SupportByColumn" -> supportByColumn,
    "AllColumnsProjectiveSeconds" -> projectiveTiming,
    "AllColumnsProjective" -> summarizeFailures[projectiveInterpolation],
    "HomogeneousColumnsOnlySeconds" -> homogeneousTiming,
    "HomogeneousColumnsOnly" -> summarizeFailures[homogeneousInterpolation]|>;
  Export[FileNameJoin[{runtime,
    "cf300_projective_residue_columns_p31.wxf"}],
    <|"Summary" -> result,
      "AllColumnsProjectiveInterpolation" -> projectiveInterpolation,
      "HomogeneousColumnsOnlyInterpolation" ->
        homogeneousInterpolation|>, "WXF"];
  Put[result, FileNameJoin[{runtime,
    "cf300_projective_residue_columns_p31_summary.wl"}]];
  Print[InputForm[result]];
  Null
]
