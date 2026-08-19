$HistoryLength = 0;
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`x"];
y = Symbol["Global`y"];
eps = Symbol["Global`eps"];

(* The exact rational gauge D = 1/x removes this strip completely. *)
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{-1/y}}},
  {{{-1/x^2}}, {{-eps/(x*y)}}}
};

result = FeynFacet`SolveResidueRationalGauge[
  strip, {x, y}, eps,
  "ScratchDirectory" -> FileNameJoin[{$TemporaryDirectory, "FeynFacet", "EpsFormStripTest"}],
  "Tag" -> "known_rational_gauge",
  "TimeLimit" -> 120,
  "ResidueKernels" -> 1
];

checks = <|
  "Association" -> AssociationQ[result],
  "Gauge" -> If[AssociationQ[result],
    TrueQ[Together[result["Gauge"][[1, 1]] - 1/x] === 0], False],
  "ODEEquation" -> If[AssociationQ[result],
    TrueQ[result["ODEEquationZero"]], False],
  "TransformedDLog" -> If[AssociationQ[result],
    TrueQ[result["TransformedDLogZero"]], False]
|>;

Print[InputForm[checks]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
