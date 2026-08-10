$HistoryLength = 0;
$LoadFeynArts = True;
$FACETKernelLimit = 8;

root = "/home/maxzhang/FACET";
work = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "CoefficientSimplification",
  "UU_08_05_1"
}];
output = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "Validation",
  "SignatureGroupProfile_20260807.wl"
}];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

splitStructure[term_] := Module[
  {factors, rationalMask, rational, signature},
  factors = FeynFacet`Private`coefficientModuleTopFactors[term];
  rationalMask = FeynFacet`Private`coefficientModuleRationalQ /@ factors;
  rational = Times @@ Pick[factors, rationalMask, True];
  signature = Times @@ Pick[factors, rationalMask, False];
  If[! SameQ[term, rational signature], Return[$Failed]];
  <|
    "Signature" -> HoldComplete[signature],
    "Denominator" -> Denominator[rational]
  |>
];

profile[index_Integer] := Module[
  {file, expression, terms, entries, groups, valid, denominatorCounts},
  file = FileNameJoin[{
    work, "MasterRecords",
    "Master_" <> IntegerString[index, 10, 4] <> ".bin"
  }];
  expression = FeynFacet`Private`coefficientBalancedRecordTotal[file];
  If[expression === $Failed, Return[$Failed]];
  terms = FeynFacet`Private`coefficientModuleTopTerms[expression];
  entries = splitStructure /@ terms;
  If[MemberQ[entries, $Failed], Return[$Failed]];
  groups = GatherBy[
    entries,
    Hash[#1["Signature"], "SHA256"] &
  ];
  valid = AllTrue[
    groups,
    Function[group,
      AllTrue[
        Rest[group],
        SameQ[First[group]["Signature"], #1["Signature"]] &
      ]
    ]
  ];
  denominatorCounts = Length[DeleteDuplicates[Lookup[#1, "Denominator"]]] & /@ groups;
  <|
    "MasterIndex" -> index,
    "InputBytes" -> FileByteCount[file],
    "ExpressionBytes" -> ByteCount[expression],
    "TermCount" -> Length[terms],
    "SignatureCount" -> Length[groups],
    "ExactSignatureGrouping" -> valid,
    "MultiDenominatorSignatureCount" -> Count[denominatorCounts, value_ /; value > 1],
    "MaximumDenominatorsPerSignature" -> Max[denominatorCounts],
    "MeanTermsPerSignature" -> N[Length[entries]/Length[groups]],
    "MaximumTermsPerSignature" -> Max[Length /@ groups]
  |>
];

result = profile /@ {4};
Put[result, output];
Print[InputForm[result]];
