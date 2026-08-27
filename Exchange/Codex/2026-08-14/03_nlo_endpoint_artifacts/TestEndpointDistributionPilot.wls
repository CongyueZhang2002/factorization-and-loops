$HistoryLength = 0;

directory = "/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/NLOEndpoint";
Get[FileNameJoin[{directory, "EndpointDistributionPilot.wl"}]];
record = Get[FileNameJoin[{directory, "NLOUUEndpointDistributions.wl"}]];

families = AssociationMap[
  <|
    "PowerSlope" -> #,
    "LaurentCoefficients" -> record["LaurentCoefficients", #]
  |> &,
  {1, 2}
];
expanded = ExpandEndpointFamilies[families, Epsilon, {-2, 0}];

reconstructed = <|
  "Delta" -> Total @ KeyValueMap[#2 Epsilon^#1 &, expanded["Total", "Delta"]],
  "Plus0" -> Total @ KeyValueMap[
    #2 Epsilon^#1 &,
    expanded["Total", "Plus", 0]
  ],
  "Plus1" -> Total @ KeyValueMap[
    #2 Epsilon^#1 &,
    expanded["Total", "Plus", 1]
  ],
  "Plus2" -> 0
|>;

differences = AssociationMap[
  Together[
    reconstructed[#] -
      record["TotalDistributionThroughFiniteOrder", #]
  ] &,
  Keys[reconstructed]
];

Print["STRUCTURED_RESULT=", InputForm[expanded]];
Print["DIFFERENCES=", InputForm[differences]];
If[AllTrue[Values[differences], TrueQ[# === 0] &], Exit[0], Exit[1]];
