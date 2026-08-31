#!/usr/bin/env wolframscript

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
gaugeAnsatz = mq["multiquadraticStripGaugeAnsatz"];
gaugeScreen = mq["multiquadraticStripGaugeScreen"];

Clear[x, y, eps];
forms = {{1/x, 0}, {0, 1/y}, {-1/(1 - x - y), -1/(1 - x - y)}};
e = {{{0}}, {{0}}};
c = {{{0}}, {{0}}};
gauge = {{(1 + x)/(1 - x - y)}};
residues = {{{0}}, {{0}}, {{3}}};
forcing = Table[
  Map[Together, D[gauge, {x, y}[[mu]]] +
    eps Sum[residues[[a]] forms[[a, mu]], {a, Length[forms]}], {2}],
  {mu, 2}];
record = <|"Family" -> "NATIVE_SCREEN_TEST", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {e, c, forcing}|>;

full = gaugeAnsatz[record, {}, forms, 1 - x - y];
missing = gaugeAnsatz[record, {}, Take[forms, 2], 1 - x - y];

Block[{FeynFacet`Private`$multiquadraticStripGaugeScreenNativeMinimumEntries = 0},
  consistent = gaugeScreen[full, "RegulatorValue" -> 1/13,
    "ExtraRowPoints" -> 2];
  obstructed = gaugeScreen[missing, "RegulatorValue" -> 1/13,
    "ExtraRowPoints" -> 2];
  witnessed = gaugeScreen[missing, "RegulatorValue" -> 1/13,
    "ExtraRowPoints" -> 2, "LeftNullSpace" -> True]];

checks = {
  Lookup[consistent, "Status", None] === "GaugeImageConsistent",
  Lookup[consistent, "Defect", None] === 0,
  Lookup[consistent, "RankBackend", None] === "FLINTAffineRREF",
  IntegerQ[Lookup[consistent, "Rank", None]],
  Lookup[obstructed, "Status", None] === "GaugeImageObstruction",
  Lookup[obstructed, "Defect", None] === 1,
  Lookup[obstructed, "RankBackend", None] === "FLINTAffineRREF",
  MissingQ[Lookup[obstructed, "Rank", None]],
  Lookup[witnessed, "RankBackend", None] === "Wolfram",
  AssociationQ[Lookup[witnessed, "Witness", None]]
};

Print[<|"Checks" -> checks,
  "Consistent" -> KeyTake[consistent, {"Status", "Defect", "Rank",
    "AugmentedRank", "RankBackend", "RankBackendThreads", "Seconds"}],
  "Obstructed" -> KeyTake[obstructed, {"Status", "Defect", "Rank",
    "AugmentedRank", "RankBackend", "RankBackendThreads", "Seconds"}],
  "Witnessed" -> KeyTake[witnessed, {"Status", "Defect", "Rank",
    "AugmentedRank", "RankBackend", "Seconds"}]|>];
Exit[If[And @@ checks, 0, 1]];
