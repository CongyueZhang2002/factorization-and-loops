(* Physical-variable coefficient trace: the finite-field path lifts each
   additive entry into the root ring only transiently and descends it
   back, so the trace is emitted in the physical variables themselves
   (no root variable, no doubled degree).  The rewrite is exact, so two
   independently stored baselines must be reproduced bit-for-bit in
   value.

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
   F. The result records the descend provenance in
      HadronicNormalization["RootDescend"]: the roots that were
      eliminated, as exact quantity -> constant rootVariable^2
      relations, and a trace-variable list that contains none of them. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Cost discipline (2026-09-02): the default run checks the full exact
   contract on the NLO data set only.  The NNLO double-real ghost grid
   (49 pairs, a 10 MB Kira artifact) is the bulk of the 51-minute
   baseline and is checked only with FACET_TEST_LONG=1. *)
longTestsQ = Environment["FACET_TEST_LONG"] === "1";

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

eliminatedRootRuleQ[quantity_, value_] :=
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

rootVariablesOf[eliminated_Association] := DeleteDuplicates @ Cases[
  Values[eliminated],
  Power[symbol_Symbol, 2] :> symbol,
  {0, 3}
];

recordedRootDescendQ[result_] := Module[
  {normalization, descend, eliminated, variables},
  normalization = Lookup[result, "HadronicNormalization", <||>];
  descend = Lookup[normalization, "RootDescend", Missing["None"]];
  If[! AssociationQ[descend], Return[False]];
  eliminated = Lookup[descend, "EliminatedRoots", Missing["None"]];
  variables = Lookup[descend, "TraceVariables", Missing["None"]];
  AssociationQ[eliminated] && Length[eliminated] > 0 &&
    AllTrue[
      Normal[eliminated],
      eliminatedRootRuleQ[First[#], Last[#]] &
    ] &&
    ListQ[variables] && variables =!= {} &&
    (* the whole point of the rewrite: not one root variable reaches
       the reconstruction *)
    Intersection[variables, rootVariablesOf[eliminated]] === {} &&
    AssociationQ[Lookup[descend, "Statistics", Missing["None"]]]
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
    label <> " F. HadronicNormalization records a root-free descend",
    recordedRootDescendQ[result]
  ];

  Print["    ", label, ": masters compared ", Length[coefficientDifferences]];
  Print["    ", label, ": root descend ",
    ToString[
      Lookup[result["HadronicNormalization"], "RootDescend", <||>],
      InputForm
    ]
  ];
  If[! AllTrue[Last /@ coefficientDifferences, TrueQ],
    Print["    ", label, ": differing masters ",
      Select[coefficientDifferences, ! TrueQ[Last[#]] &][[All, 1]]]
  ];
  result
];

If[! longTestsQ,
  dataSets = Select[dataSets, #["Label"] === "TT" &];
  Print["Ghost data set skipped: set FACET_TEST_LONG=1 to reconstruct the NNLO ghost grid too"]];
Scan[checkDataSet, dataSets];

FTTest`FTReport[];
