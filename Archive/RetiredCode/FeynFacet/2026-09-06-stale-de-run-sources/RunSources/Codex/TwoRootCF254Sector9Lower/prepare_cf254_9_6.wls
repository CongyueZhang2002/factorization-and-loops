#!/usr/bin/env wolframscript

(* Exact preparation of the CF254 (9,6) strip for rational-gauge solving. *)

$HistoryLength = 0;

directory = DirectoryName[$InputFileName];
recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl";
$feynFacetRoot = "/home/maxzhang/factorization-and-loops";
packagePath =
  $feynFacetRoot <> "/FeynFacet/Private/" <>
    "EpsFormStrip.wl";

Get[packagePath];
record = Get[recordPath];
{e, c, bbar} = record["Strip"];
{z1, z2} = record["Variables"];
epsilon = record["Regulator"];

entryFactorList[entry_] := Module[{denominator},
  denominator = Denominator[Cancel[Together[entry]]];
  If[TrueQ[denominator === 1], {},
    Select[Rest[FactorList[denominator]],
      ! TrueQ[NumericQ[First[#]]] &]]
];

sectionCensus[section_] := Module[{pairs, factors},
  pairs = Flatten[entryFactorList /@ Flatten[section], 1];
  If[pairs === {}, Return[{}]];
  factors = DeleteDuplicates[pairs[[All, 1]], SameQ];
  Table[<|
    "Factor" -> factor,
    "MaximumPower" ->
      Max[Cases[pairs, {candidate_, power_} /;
          SameQ[candidate, factor] :> power]],
    "EpsilonDependent" -> ! FreeQ[factor, epsilon],
    "Degrees" -> {Exponent[factor, z1], Exponent[factor, z2],
      Exponent[factor, epsilon]}
  |>, {factor, factors}]
];

census = <|
  "Family" -> record["Family"],
  "BlockPair" -> {record["Sector"], record["LowerSector"]},
  "Variables" -> {z1, z2},
  "Regulator" -> epsilon,
  "Dimensions" -> <|"E" -> Dimensions[e], "C" -> Dimensions[c],
    "Bbar" -> Dimensions[bbar]|>,
  "E" -> sectionCensus[e],
  "C" -> sectionCensus[c],
  "Bbar" -> sectionCensus[bbar]
|>;

Put[census, FileNameJoin[{directory, "CF254_9_6_divisor_census.wl"}]];

{residueSeconds, residueData} = AbsoluteTiming[
  epsFormStripBuildResidueCompatibility[
    record["Strip"], record["Variables"], epsilon, 8]
];

If[! AssociationQ[residueData],
  Print[<|"ResidueResult" -> Head[residueData],
    "FailureStage" -> $epsFormStripResidueFailureStage,
    "Seconds" -> residueSeconds|>];
  Exit[1]
];

Put[residueData,
  FileNameJoin[{directory, "CF254_9_6_residue_data.wl"}]];

factorPairs = Flatten[entryFactorList /@ Flatten[bbar], 1];
factors = DeleteDuplicates[factorPairs[[All, 1]], SameQ];
factorPowers = Table[
  {factor, Max[Cases[factorPairs,
    {candidate_, power_} /; SameQ[candidate, factor] :> power]]},
  {factor, factors}];
gaugeFactorPowers = Select[factorPowers,
  Last[#] > 1 && ! FreeQ[First[#], z1 | z2] &];
gaugeDenominator = Times @@
  ((First[#]^(Last[#] - 1)) & /@ gaugeFactorPowers);

summary = <|
  "Family" -> record["Family"],
  "Pair" -> {record["Sector"], record["LowerSector"]},
  "StripDimensions" -> census["Dimensions"],
  "ResidueSeconds" -> residueSeconds,
  "AlphabetCount" -> Length[residueData["Alphabet"]],
  "ResidueVariableCount" -> Length[residueData["ResidueVariables"]],
  "FreeResidueCount" -> Length[residueData["FreeResidues"]],
  "EquationCount" -> residueData["EquationCount"],
  "CompatibilityZero" -> residueData["CompatibilityZero"],
  "GaugeDenominator" -> gaugeDenominator,
  "GaugeDenominatorBidegree" ->
    {Exponent[gaugeDenominator, z1], Exponent[gaugeDenominator, z2]},
  "GaugeFactorPowers" -> gaugeFactorPowers
|>;

Put[summary,
  FileNameJoin[{directory, "CF254_9_6_preparation_summary.wl"}]];
Print[InputForm[summary]];
Exit[If[TrueQ[residueData["CompatibilityZero"]], 0, 1]];
