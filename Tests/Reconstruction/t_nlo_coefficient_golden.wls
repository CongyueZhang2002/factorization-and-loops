(* Coefficient-level golden regression: the finite-field master
   coefficients of the regenerated NLO UU 10x10 set must reproduce the
   2026-08-09 reference CoefficientResult.wl exactly.

   Acceptance criteria:
   A. The reference loads and is a FormatVersion-8 FeynFacet-IBP result.
   B. CoefficientSimplification (finite-field path) completes on the
      regenerated pairs + their fresh KiraResult.
   C. Identical master integral sets.
   D. For every master, the full product
      globalPreFactor x masterPreFactor x Coefficient agrees exactly,
      and the Remainders agree exactly.
   E. The shared measure fields (FractionMeasure, PhaseSpace) agree. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

referenceFile = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "CoefficientResult.wl"
}];
reference = Get[referenceFile];

FTTest`FTAssert["A. reference is a FormatVersion-8 FeynFacet-IBP result",
  AssociationQ[reference] &&
    reference["Format"] === "FeynFacet-IBP" &&
    reference["FormatVersion"] === 8];

pairFiles = Sort @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen", "Pairs"}]
];
kiraFile = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen", "KiraResult.wl"
}];

result = FeynFacet`CoefficientSimplification[
  pairFiles,
  kiraFile,
  "Threads" -> 6,
  "NormalizationKernels" -> 6
];

FTTest`FTAssert["B. finite-field coefficient reconstruction completes",
  AssociationQ[result] &&
    result["Format"] === "FeynFacet-IBP" &&
    result["FormatVersion"] === 8];

masterKeyOf[entry_] := ToString[entry["Master"], InputForm];

referenceMasters = Association[
  masterKeyOf[#] -> # & /@ reference["Masters"]
];
resultMasters = Association[
  masterKeyOf[#] -> # & /@ result["Masters"]
];

FTTest`FTAssert["C. identical master integral sets",
  Sort[Keys[referenceMasters]] === Sort[Keys[resultMasters]]];

fullCoefficient[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] entry["Coefficient"];

coefficientDifferences = If[
  Sort[Keys[referenceMasters]] === Sort[Keys[resultMasters]],
  Map[
    Function[key,
      key -> TrueQ @ FeynFacet`Private`exactZeroQ[
        fullCoefficient[reference, referenceMasters[key]] -
          fullCoefficient[result, resultMasters[key]]
      ]
    ],
    Keys[referenceMasters]
  ],
  {}
];

FTTest`FTAssert["D1. every master coefficient product agrees exactly",
  coefficientDifferences =!= {} &&
    AllTrue[Last /@ coefficientDifferences, TrueQ]];
FTTest`FTAssert["D2. the remainders agree exactly",
  TrueQ @ FeynFacet`Private`exactZeroQ[
    reference["PreFactor"] reference["Remainder"] -
      result["PreFactor"] result["Remainder"]
  ]];

sameFieldQ[key_] := TrueQ[
  SameQ[reference[key], result[key]] ||
    FeynFacet`Private`exactZeroQ[reference[key] - result[key]]
];
FTTest`FTAssert["E. FractionMeasure and PhaseSpace agree",
  sameFieldQ["FractionMeasure"] && sameFieldQ["PhaseSpace"]];

Print["    masters compared: ", Length[coefficientDifferences]];
If[! AllTrue[Last /@ coefficientDifferences, TrueQ],
  Print["    differing masters: ",
    Select[coefficientDifferences, ! TrueQ[Last[#]] &][[All, 1]]]
];

FTTest`FTReport[];
