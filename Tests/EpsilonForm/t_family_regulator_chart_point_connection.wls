#!/usr/bin/env wolframscript

(* The production rational-chart regulator route contracts the connection
   one-form before specializing a chart point.  This is the same exact map as
   the former two-pass implementation, but it permits one deduplicated,
   pool-aware rational simplification pass. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

v = Symbol["Global`v"];
w = Symbol["Global`w"];
x = Symbol["Global`x"];
y = Symbol["Global`y"];
eps = Symbol["Global`eps"];
r = Symbol["Global`rho"];

connection = {
  {{eps/(v + r), (1 + eps w)/(1 - v)}, {0, r/(v w)}},
  {{v/(1 + w), eps r/(v - w)}, {(v + w)/(1 + r), 0}}};
data = <|
  "Subst" -> {v -> x + y, w -> x - y},
  "Jacobian" -> {{1, 1}, {1, -1}}|>;
rule = {x -> 2/3, y -> 1/5};
rootImages = {7/11};

sourceRules = Map[
  Function[item, First[item] -> Together[Last[item] /. rule]],
  data["Subst"]];
components = Map[
  Function[matrix,
    Map[Together,
      matrix /. sourceRules /. Thread[{r} -> rootImages], {2}]],
  connection];
expected = FeynFacet`Private`masterTransportPullBackOneForm[
  components[[1]], components[[2]],
  Map[Together, data["Jacobian"] /. rule, {2}]];
actual = FeynFacet`Private`familyRegulatorChartPointConnection[
  connection, {r}, data, rootImages, rule];

FTAssert["the contracted single-pass chart-point evaluation is a matrix pair",
  MatchQ[actual, {{__List}, {__List}}] &&
    Dimensions[actual] === Dimensions[expected]];
FTAssert["the contracted single-pass evaluation equals the former two-pass map",
  And @@ Flatten[Map[TrueQ[Together[#] === 0] &,
    actual - expected, {3}]]];
FTAssert["the root image and both source substitutions were applied",
  FreeQ[actual, v | w | x | y | r]];

FTReport[];
