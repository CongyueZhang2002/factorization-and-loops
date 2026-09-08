recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_divisor_census.wl"}];

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
  factors = DeleteDuplicates[pairs[[All, 1]]];
  Table[
    <|
      "Factor" -> factor,
      "MaximumPower" -> Max[Cases[pairs, {factor, power_} :> power]],
      "EpsilonDependent" -> ! FreeQ[factor, epsilon],
      "Degrees" -> {Exponent[factor, z1], Exponent[factor, z2],
        Exponent[factor, epsilon]}
    |>,
    {factor, factors}
  ]
];

result = <|
  "Family" -> record["Family"],
  "BlockPair" -> {record["Sector"], record["LowerSector"]},
  "Variables" -> {z1, z2},
  "Regulator" -> epsilon,
  "Dimensions" -> <|
    "E" -> Dimensions[e],
    "C" -> Dimensions[c],
    "BBar" -> Dimensions[bbar]
  |>,
  "E" -> sectionCensus[e],
  "C" -> sectionCensus[c],
  "BBar" -> sectionCensus[bbar],
  "InfinityDegrees" -> Association@MapThread[
    Function[{name, section},
      name -> Table[
        Map[
          Function[entry,
            With[{fraction = Together[entry]},
              Exponent[Numerator[fraction], variable] -
                Exponent[Denominator[fraction], variable]
            ]
          ],
          section[[mu]],
          {2}
        ],
        {variable, {z1, z2}}, {mu, 2}
      ]
    ],
    {{"E", "C", "BBar"}, {e, c, bbar}}
  ]
|>;

Put[result, outputPath];
Print["Variables: ", InputForm[{z1, z2}], ", regulator: ",
  InputForm[epsilon]];
Print["Dimensions: ", result["Dimensions"]];
Print["Infinity degree ranges:"];
Scan[
  Function[name,
    Print["  ", name, ": ",
      Map[{Min[#], Max[#]} &, result["InfinityDegrees"][name], {2}]]
  ],
  {"E", "C", "BBar"}
];
Scan[
  Function[name,
    Print["\n", name, " divisors (", Length[result[name]], "):"];
    Scan[
      Function[item,
        Print["  power=", item["MaximumPower"],
          ", epsDependent=", item["EpsilonDependent"],
          ", degrees=", item["Degrees"],
          ", factor=", InputForm[item["Factor"]]]
      ],
      result[name]
    ]
  ],
  {"E", "C", "BBar"}
];
Print["\nSaved: ", outputPath];
