(* Rationalized coefficient variables (Design/RationalizedCoefficients.md):
   the finite-field path now trades the positive quantities of the card
   region for square-root substitution variables instead of lifting
   fraction roots and canceling the lifted rational.  The rewrite is
   exact, so two independently stored baselines must be reproduced
   bit-for-bit in value.

   Acceptance criteria, per data set (TT = polarized NLO baseline,
   Ghost = NNLO double-real ghost grid on the shared namespace):
   A. The stored reference loads and is a FormatVersion-8 FeynFacet-IBP
      result.
   B. A fresh coefficient reconstruction over the same pairs and Kira
      artifact completes.  It runs the project-form computation - the
      current card supplies the late setup keys, exactly as
      coefficientRunProject does, which the stored ghost pairs need
      because they carry the older LaurentValuation -> Automatic - but
      calls the core directly, so no CoefficientResult.wl is written and
      the stored reference is never overwritten.
   C. Identical master integral sets.
   D. For every master the full product
      globalPreFactor x masterPreFactor x Coefficient agrees exactly
      with the reference, and the Remainders agree exactly.
   E. The shared measure fields (FractionMeasure, PhaseSpace) agree.
   F. The result records the substitution set actually used in
      HadronicNormalization["RootSubstitutions"], as exact
      quantity -> constant rootVariable^2 rules. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

dataSets = {
  <|
    "Label" -> "TT",
    "Directory" -> FileNameJoin[{root, "ppHX_NLO", "Results", "TT_08_10_1"}],
    "Card" -> FileNameJoin[{root, "ppHX_NLO", "Cards", "TT.wl"}]
  |>,
  <|
    "Label" -> "Ghost",
    "Directory" -> FileNameJoin[{
      root, "ppHX_NNLO_DoubleReal", "Results", "UU_Ghost_08_10_shared"
    }],
    "Card" -> FileNameJoin[{
      root, "ppHX_NNLO_DoubleReal", "Cards", "UU_Ghost.wl"
    }]
  |>
};

reconstruct[pairFiles_List, kiraFile_String, card_Association] :=
  FeynFacet`Private`finiteFieldCoefficientSimplificationCore[
    pairFiles,
    kiraFile,
    <|
      "RatracerExecutable" -> Automatic,
      "Threads" -> 6,
      "NormalizationKernels" -> 6,
      "TargetTimeLimit" -> 300,
      "MaximumTargets" -> All,
      "KeepWorkingFiles" -> True,
      "FactorScan" -> True,
      "ShiftScan" -> True,
      "CoefficientSetup" -> card
    |>
  ];

masterKeyOf[entry_] := ToString[entry["Master"], InputForm];

fullCoefficient[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] entry["Coefficient"];

(* Same exact predicate as the NLO golden test, in the cheap order:
   exactZeroQ expands before it cancels, and at NNLO coefficient size
   (tens of MB per master) that expansion is the whole cost.  Canceling
   the common denominator first decides the largest ghost master in
   155 s instead of running for an hour. *)
exactlyEqualQ[first_, second_] := TrueQ @ FeynFacet`Private`exactZeroQ[
  Cancel @ Together[first - second]
];

rootSubstitutionRuleQ[quantity_, value_] :=
  MatchQ[quantity, _Symbol] &&
  MatchQ[
    value,
    Power[_Symbol, 2] | Times[_Integer | _Rational, Power[_Symbol, 2]]
  ] &&
  StringStartsQ[
    SymbolName[First @ Cases[value, Power[symbol_Symbol, 2] :> symbol, {0, 2}]],
    "FACETroot"
  ] &&
  FeynFacet`Private`exactDataQ[value];

recordedRootSubstitutionsQ[result_] := Module[{normalization, substitutions},
  normalization = Lookup[result, "HadronicNormalization", <||>];
  substitutions = Lookup[normalization, "RootSubstitutions", Missing["None"]];
  AssociationQ[substitutions] && Length[substitutions] > 0 &&
    AllTrue[
      Normal[substitutions],
      rootSubstitutionRuleQ[First[#], Last[#]] &
    ]
];

checkDataSet[dataSet_Association] := Module[
  {
    label, directory, referenceFile, reference, pairFiles, kiraFile,
    card, result, referenceMasters, resultMasters, sameMasters,
    coefficientDifferences, sameFieldQ
  },
  label = dataSet["Label"];
  directory = dataSet["Directory"];
  referenceFile = FileNameJoin[{directory, "CoefficientResult.wl"}];
  kiraFile = FileNameJoin[{directory, "KiraResult.wl"}];
  pairFiles = SortBy[
    FileNames["F*_C*.wl", FileNameJoin[{directory, "Pairs"}]],
    FeynFacet`Private`coefficientPairFileKey
  ];
  card = If[FileExistsQ[dataSet["Card"]], Get[dataSet["Card"]], $Failed];
  reference = If[FileExistsQ[referenceFile], Get[referenceFile], $Failed];

  FTTest`FTAssert[
    label <> " A. stored reference is a FormatVersion-8 FeynFacet-IBP result",
    AssociationQ[reference] &&
      reference["Format"] === "FeynFacet-IBP" &&
      reference["FormatVersion"] === 8 &&
      AssociationQ[card] &&
      pairFiles =!= {} && FileExistsQ[kiraFile]
  ];
  If[! AssociationQ[card], Return[$Failed]];

  result = reconstruct[pairFiles, kiraFile, card];

  FTTest`FTAssert[
    label <> " B. fresh finite-field reconstruction completes",
    AssociationQ[result] &&
      result["Format"] === "FeynFacet-IBP" &&
      result["FormatVersion"] === 8
  ];
  If[! AssociationQ[result] || ! AssociationQ[reference], Return[$Failed]];

  referenceMasters = Association[masterKeyOf[#] -> # & /@ reference["Masters"]];
  resultMasters = Association[masterKeyOf[#] -> # & /@ result["Masters"]];
  sameMasters = Sort[Keys[referenceMasters]] === Sort[Keys[resultMasters]];
  FTTest`FTAssert[label <> " C. identical master integral sets", sameMasters];

  coefficientDifferences = If[
    sameMasters,
    Map[
      Function[key,
        key -> exactlyEqualQ[
          fullCoefficient[reference, referenceMasters[key]],
          fullCoefficient[result, resultMasters[key]]
        ]
      ],
      Keys[referenceMasters]
    ],
    {}
  ];

  FTTest`FTAssert[
    label <> " D1. every master coefficient product agrees exactly",
    coefficientDifferences =!= {} &&
      AllTrue[Last /@ coefficientDifferences, TrueQ]
  ];
  FTTest`FTAssert[
    label <> " D2. the remainders agree exactly",
    exactlyEqualQ[
      reference["PreFactor"] reference["Remainder"],
      result["PreFactor"] result["Remainder"]
    ]
  ];

  sameFieldQ[key_] := TrueQ[
    SameQ[reference[key], result[key]] ||
      exactlyEqualQ[reference[key], result[key]]
  ];
  FTTest`FTAssert[
    label <> " E. FractionMeasure and PhaseSpace agree",
    sameFieldQ["FractionMeasure"] && sameFieldQ["PhaseSpace"]
  ];

  FTTest`FTAssert[
    label <> " F. HadronicNormalization records RootSubstitutions",
    recordedRootSubstitutionsQ[result]
  ];

  Print["    ", label, ": masters compared ", Length[coefficientDifferences]];
  Print["    ", label, ": root substitutions ",
    ToString[
      Lookup[result["HadronicNormalization"], "RootSubstitutions", <||>],
      InputForm
    ]
  ];
  If[! AllTrue[Last /@ coefficientDifferences, TrueQ],
    Print["    ", label, ": differing masters ",
      Select[coefficientDifferences, ! TrueQ[Last[#]] &][[All, 1]]]
  ];
  result
];

Scan[checkDataSet, dataSets];

FTTest`FTReport[];
