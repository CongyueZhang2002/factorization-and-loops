recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_7_input.wl";
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
  "CF254_9_7_divisor_census.wl"}];

record = Get[recordPath];
{z1, z2} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];

ClearAll[entryFactorList, sectionCensus];
entryFactorList[entry_] := Module[{denominator, factors},
  denominator = Denominator[Together[entry]];
  If[TrueQ[denominator === 1], Return[{}]];
  factors = Rest[FactorList[denominator]];
  Select[factors, ! TrueQ[NumericQ[First[#]]] &]
];
sectionCensus[section_] := Module[{pairs, factors},
  pairs = Flatten[entryFactorList /@ Flatten[section], 1];
  If[pairs === {}, Return[{}]];
  factors = DeleteDuplicates[pairs[[All, 1]]];
  Table[<|
    "Factor" -> factor,
    "MaximumPower" -> Max[Cases[pairs, {factor, power_} :> power]],
    "EpsilonDependent" -> ! FreeQ[factor, epsilon],
    "Degrees" -> {Exponent[factor, z1], Exponent[factor, z2],
      Exponent[factor, epsilon]}
  |>, {factor, factors}]
];

result = <|
  "Family" -> record["Family"],
  "BlockPair" -> {record["Sector"], record["LowerSector"]},
  "Variables" -> {z1, z2},
  "Regulator" -> epsilon,
  "Dimensions" -> <|"E" -> Dimensions[e], "C" -> Dimensions[c],
    "BBar" -> Dimensions[bbar]|>,
  "E" -> sectionCensus[e],
  "C" -> sectionCensus[c],
  "BBar" -> sectionCensus[bbar]
|>;
Put[result, outputPath];
Print["Dimensions: ", result["Dimensions"]];
Do[
  Print[name, " divisors (", Length[result[name]], "):"];
  Scan[Print[InputForm[#]] &, result[name]],
  {name, {"E", "C", "BBar"}}
];
