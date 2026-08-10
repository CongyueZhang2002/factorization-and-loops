facetRoot = "/home/maxzhang/FACET";
workDirectory = FileNameJoin[{
  facetRoot, "Codex", "ppHX_NLO", "HadronicSimplification", "UU_10x10"
}];

Get[FileNameJoin[{facetRoot, "Addon", "Load", "LoadFACET.wl"}]];
Global`$FACETKernelLimit = 4;
hybrid = Get[FileNameJoin[{workDirectory, "HybridMasterCoefficients.wl"}]];
radicalTest = Get[FileNameJoin[{
  workDirectory, "RadicalNormalizationTest.wl"
}]];

physicalFactor =
  FeynFacet`\[Alpha]s^3*FeynFacet`D1[zh]*FeynFacet`f1[xa]*
    FeynFacet`f1[xb]/(xa*xb*zh^2);

positivePowerRules = {
  Power[4, power_] :> Power[2, 2 power],
  Power[Times[4, Pi], power_] :>
    Power[2, 2 power] Power[Pi, power],
  Power[base : (2 | Pi), power_Plus] :>
    Times @@ (Power[base, #] & /@ List @@ power)
};

canonicalInput[expression_] :=
  expression /. Dispatch[radicalTest["Rules"]] //. positivePowerRules;

stripPhysicalFactor[expression_] := Total[
  Cancel[#/physicalFactor] & /@
    FeynFacet`Private`additiveTerms[canonicalInput[expression]]
];

colorSectorCleanup[expression_] := Module[{rules},
  rules = CoefficientRules[Expand[expression], {CA, CF}];
  Total[
    Function[rule,
      CA^rule[[1, 1]] CF^rule[[1, 2]]
        Factor[Cancel[Together[rule[[2]]]]]
    ] /@ rules
  ]
];

cleanup[expression_] := Module[{stripped, factorData, result},
  stripped = stripPhysicalFactor[expression];
  factorData = FeynFacet`Private`structuralAdditiveFactor[stripped];
  result = First[factorData] colorSectorCleanup[Last[factorData]];
  <|
    "LocalFactor" -> First[factorData],
    "Coefficient" -> result
  |>
];

input = Values[hybrid["Terms"]];
LaunchKernels[4];
DistributeDefinitions[
  cleanup, canonicalInput, stripPhysicalFactor, colorSectorCleanup,
  physicalFactor, positivePowerRules, radicalTest
];
{seconds, cleaned} = AbsoluteTiming[
  ParallelMap[cleanup, input, Method -> "FinestGrained"]
];
CloseKernels[];

reconstructed = physicalFactor (
  Lookup[cleaned, "LocalFactor"] Lookup[cleaned, "Coefficient"]
);
differences = MapThread[
  Function[{before, after},
    TimeConstrained[
      TrueQ[Cancel[Together[canonicalInput[before] - after]] === 0],
      120,
      Missing["TimeLimit"]
    ]
  ],
  {input, reconstructed}
];

result = <|
  "Seconds" -> seconds,
  "InputBytes" -> ByteCount[input],
  "OutputBytes" -> ByteCount[cleaned],
  "Compression" -> N[ByteCount[input]/ByteCount[cleaned]],
  "LocalFactors" -> Lookup[cleaned, "LocalFactor"],
  "FractionFree" -> FreeQ[
    Lookup[cleaned, "Coefficient"],
    Alternatives[xa, xb, zh]
  ],
  "ExactReconstruction" -> differences,
  "Cleaned" -> AssociationThread[Keys[hybrid["Terms"]], cleaned]
|>;

Put[result, FileNameJoin[{
  workDirectory, "SignatureCleanupBenchmark.wl"
}]];
Print[InputForm[KeyDrop[result, "Cleaned"]]];
