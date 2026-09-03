#!/usr/bin/env wolframscript

(* A multiquadratic transport base should split its declared roots over Q
   whenever the bounded rational-height grid supplies such a regular point.
   Rational records retain the historical first-candidate path, and an
   algebraic record with no split candidate retains the regular fallback. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`splitPathX"];
y = Symbol["Global`splitPathY"];
eps = Symbol["Global`eps"];

baseRecord = <|
  "Status" -> "ExactEpsilonForm",
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Dim" -> 1,
  "Ranges" -> {{1}},
  "TTotal" -> {{1}},
  "TTotalInverse" -> {{1}},
  "EpsFormX" -> {{0}},
  "EpsFormY" -> {{0}},
  "Letters" -> {x, y, 1 - x, 1 - y}
|>;

algebraicRecord = Join[baseRecord, <|
  "CoefficientField" -> "Multiquadratic",
  "ChartRecord" -> <|
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y},
    "Subst" -> {x -> x, y -> y},
    "Roots" -> {
      <|"Root" -> Sqrt[1 - x], "RootSquare" -> 1 - x|>,
      <|"Root" -> Sqrt[1 - y], "RootSquare" -> 1 - y|>}
  |>
|>];
algebraicPath = FindObservableTransportPath[algebraicRecord];
algebraicBase = Lookup[algebraicPath, {"FirstBase", "SecondBase"}, {}];
algebraicSquares = ({1 - x, 1 - y} /.
  Thread[{x, y} -> algebraicBase]);

FTAssert["a multiquadratic planner prefers a regular rational split base",
  Lookup[algebraicPath, "Status", None] === "ExactPathData" &&
    algebraicBase === {3/4, 3/4} &&
    FeynFacet`Private`observableTransportRecordRegularQ[algebraicRecord,
      Thread[{x, y} -> algebraicBase]]];
FTAssert["every declared root is nonzero and rational at that base",
  algebraicSquares === {1/4, 1/4} &&
    VectorQ[Sqrt[algebraicSquares],
      MatchQ[#, _Integer | _Rational] && # =!= 0 &]];

rationalPath = FindObservableTransportPath[
  Join[baseRecord, <|"CoefficientField" -> "Rational"|>]];
FTAssert["rational-family path ordering is unchanged",
  Lookup[rationalPath,
    {"FirstBase", "SecondBase", "FirstTargetSample"}, {}] ===
      {1/4, 1/4, 1/3}];

fallbackRecord = Join[algebraicRecord, <|"ChartRecord" ->
  Join[algebraicRecord["ChartRecord"], <|"Roots" ->
    {<|"Root" -> Sqrt[2], "RootSquare" -> 2|>}|>]|>];
fallbackPath = FindObservableTransportPath[fallbackRecord,
  "Candidates" -> {{1/4, 1/4, 1/3}}];
FTAssert["a multiquadratic record with no split candidate uses the regular fallback",
  Lookup[fallbackPath,
    {"Status", "FirstBase", "SecondBase", "FirstTargetSample"}, {}] ===
      {"ExactPathData", 1/4, 1/4, 1/3}];

FTReport[];
