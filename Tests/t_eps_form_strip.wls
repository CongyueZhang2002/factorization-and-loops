$HistoryLength = 0;
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

testX = Symbol["FeynFacetStripSerializationTest`x"];
testY = Symbol["FeynFacetStripSerializationTest`y"];
testEpsilon = Symbol["FeynFacetStripSerializationTest`eps"];
scratchDirectory = FileNameJoin[{$TemporaryDirectory, "FeynFacet",
  "EpsFormStripTest"}];

(* The exact rational gauge D = 1/x removes this strip completely. *)
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{-1/testY}}},
  {{{-1/testX^2}}, {{-testEpsilon/(testX*testY)}}}
};

messageCount = Length[$MessageList];
result = FeynFacet`SolveResidueRationalGauge[
  strip, {testX, testY}, testEpsilon,
  "ScratchDirectory" -> scratchDirectory,
  "Tag" -> "known_rational_gauge",
  "TimeLimit" -> 120,
  "ResidueKernels" -> 1
];

checks = <|
  "MessageFree" -> Length[$MessageList] === messageCount,
  "Association" -> AssociationQ[result],
  "Gauge" -> If[AssociationQ[result],
    TrueQ[Together[result["Gauge"][[1, 1]] - 1/testX] === 0], False],
  "ODEEquation" -> If[AssociationQ[result],
    TrueQ[result["ODEEquationZero"]], False],
  "TransformedDLog" -> If[AssociationQ[result],
    TrueQ[result["TransformedDLogZero"]], False],
  "ExactDLog" -> If[AssociationQ[result],
    TrueQ[result["ExactDLog"]], False],
  "ContextFreeMaple" -> ! StringContainsQ[
    Import[FileNameJoin[{scratchDirectory,
      "known_rational_gauge_first_1.mpl"}], "Text"], "`"],
  "MapleExitCode" -> StringStartsQ[
    Import[FileNameJoin[{scratchDirectory,
      "known_rational_gauge_first_1.log"}], "Text"], "ExitCode: 0"]
|>;

Print[InputForm[checks]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
