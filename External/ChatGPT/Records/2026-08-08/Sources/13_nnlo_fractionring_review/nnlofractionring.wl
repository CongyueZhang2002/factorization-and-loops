(* Exact positive-root rational arithmetic for NNLO momentum fractions. *)

ClearAll[
  facetYa, facetYb, facetYh,
  nnloFractionVariables,
  nnloRootVariables,
  nnloDistributionFactor,
  nnloUniversalRootExponent,
  nnloExactZeroQ,
  nnloPositiveRootLift,
  nnloSparsePolynomial,
  nnloSparseAdd,
  nnloSparseMultiply,
  nnloSparseShift,
  nnloPolynomialMap,
  nnloNormalizeFractionDenominator,
  nnloFractionLeaf,
  nnloMergeFractionLeaves,
  nnloMergeFractionEntries,
  nnloCommonFractionDenominator,
  nnloAssembleFractionColumn,
  nnloCertifyUniversalFactor
];

nnloFractionVariables = {xa, xb, zh};
nnloRootVariables = {facetYa, facetYb, facetYh};
nnloDistributionFactor = f1[xa] f1[xb] D1[zh];
nnloUniversalRootExponent = {-2, -2, -4};

nnloExactZeroQ[expression_, timeLimit_: 60] := TimeConstrained[
  TrueQ[Numerator[Cancel[Together[expression]]] === 0],
  timeLimit,
  $TimedOut
];

nnloPositiveRootLift[expression_] := Module[{badPowers, lifted},
  badPowers = Cases[
    expression,
    HoldPattern[Power[xa | xb | zh, exponent_]] /;
      !(MatchQ[exponent, _Integer | _Rational] && IntegerQ[2 exponent]),
    Infinity
  ];
  If[badPowers =!= {}, Return[$Failed]];
  lifted = expression /. {
    HoldPattern[Power[xa, exponent_Rational]] :> facetYa^(2 exponent),
    HoldPattern[Power[xb, exponent_Rational]] :> facetYb^(2 exponent),
    HoldPattern[Power[zh, exponent_Rational]] :> facetYh^(2 exponent)
  };
  lifted = lifted /. {
    xa -> facetYa^2,
    xb -> facetYb^2,
    zh -> facetYh^2
  };
  If[
    FreeQ[lifted, Alternatives @@ nnloFractionVariables] &&
      FreeQ[
        lifted,
        object_ /; (
          ttAnalyticObjectQ[Unevaluated[object]] &&
          ! FreeQ[Unevaluated[object], Alternatives @@ nnloRootVariables]
        )
      ],
    lifted,
    $Failed
  ]
];

nnloSparsePolynomial[map_Association] := Total @ KeyValueMap[
  Function[{exponent, coefficient},
    coefficient Times @@ MapThread[Power, {nnloRootVariables, exponent}]
  ],
  map
];

nnloSparseAdd[maps_List] := Select[
  Merge[maps, Total],
  ! TrueQ[# === 0] &
];

nnloSparseMultiply[first_Association, second_Association] := Module[
  {terms},
  terms = Flatten @ KeyValueMap[
    Function[{firstExponent, firstCoefficient},
      KeyValueMap[
        Function[{secondExponent, secondCoefficient},
          (firstExponent + secondExponent) ->
            (firstCoefficient secondCoefficient)
        ],
        second
      ]
    ],
    first
  ];
  Select[Merge[Association /@ terms, Total], ! TrueQ[# === 0] &]
];

nnloSparseShift[map_Association, shift_List] := Association @ KeyValueMap[
  (#1 + shift) -> #2 &,
  map
];

nnloPolynomialMap[polynomial_] := Module[{rules},
  If[! PolynomialQ[polynomial, nnloRootVariables], Return[$Failed]];
  rules = Quiet @ Check[
    CoefficientRules[polynomial, nnloRootVariables],
    $Failed
  ];
  If[rules === $Failed, $Failed, Association[rules]]
];

nnloNormalizeFractionDenominator[denominator_] := Module[
  {rules, leading, leadingCoefficient, normalized},
  If[! PolynomialQ[denominator, nnloRootVariables], Return[$Failed]];
  rules = CoefficientRules[denominator, nnloRootVariables];
  If[rules === {}, Return[$Failed]];
  leading = First @ Reverse @ SortBy[rules, First];
  leadingCoefficient = Last[leading];
  If[! FreeQ[leadingCoefficient, Alternatives @@ nnloRootVariables],
    Return[$Failed]
  ];
  normalized = Cancel[denominator/leadingCoefficient];
  If[
    PolynomialQ[normalized, nnloRootVariables],
    {normalized, leadingCoefficient},
    $Failed
  ]
];

nnloFractionLeaf[expression_, timeLimit_: 60] := Module[
  {
    quotient, distributionCertificate, lifted, rational, numerator,
    denominator, denominatorData, normalizedDenominator,
    leadingCoefficient, normalizedNumerator, numeratorMap,
    reconstructed, reconstructionCertificate
  },
  quotient = Cancel[expression/nnloDistributionFactor];
  distributionCertificate = nnloExactZeroQ[
    expression - nnloDistributionFactor quotient,
    timeLimit
  ];
  If[distributionCertificate =!= True, Return[$Failed]];
  lifted = nnloPositiveRootLift[quotient];
  If[lifted === $Failed, Return[$Failed]];
  rational = TimeConstrained[
    Cancel[Together[lifted]],
    timeLimit,
    $TimedOut
  ];
  If[rational === $TimedOut, Return[$TimedOut]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[
    ! PolynomialQ[numerator, nnloRootVariables] ||
      ! PolynomialQ[denominator, nnloRootVariables],
    Return[$Failed]
  ];
  denominatorData = nnloNormalizeFractionDenominator[denominator];
  If[denominatorData === $Failed, Return[$Failed]];
  {normalizedDenominator, leadingCoefficient} = denominatorData;
  normalizedNumerator = Cancel[numerator/leadingCoefficient];
  numeratorMap = nnloPolynomialMap[normalizedNumerator];
  If[numeratorMap === $Failed, Return[$Failed]];
  reconstructed = nnloSparsePolynomial[numeratorMap]/normalizedDenominator;
  reconstructionCertificate = nnloExactZeroQ[
    reconstructed - rational,
    timeLimit
  ];
  If[reconstructionCertificate =!= True, Return[$Failed]];
  <|
    "Denominator" -> normalizedDenominator,
    "Numerator" -> numeratorMap,
    "InputBytes" -> ByteCount[expression],
    "LiftedBytes" -> ByteCount[rational]
  |>
];

nnloMergeFractionLeaves[leaves_List] := Module[
  {groups, entries},
  groups = GroupBy[leaves, HoldComplete[#1["Denominator"]] &];
  entries = KeyValueMap[
    Function[{heldDenominator, group},
      <|
        "Denominator" -> ReleaseHold[heldDenominator],
        "Numerator" -> nnloSparseAdd[Lookup[group, "Numerator"]],
        "LeafCount" -> Length[group],
        "InputBytes" -> Total[Lookup[group, "InputBytes"]],
        "LiftedBytes" -> Total[Lookup[group, "LiftedBytes"]]
      |>
    ],
    groups
  ];
  entries
];

nnloMergeFractionEntries[entries_List] := Module[{groups},
  groups = GroupBy[entries, HoldComplete[#1["Denominator"]] &];
  KeyValueMap[
    Function[{heldDenominator, group},
      <|
        "Denominator" -> ReleaseHold[heldDenominator],
        "Numerator" -> nnloSparseAdd[Lookup[group, "Numerator"]],
        "LeafCount" -> Total[Lookup[group, "LeafCount"]],
        "InputBytes" -> Total[Lookup[group, "InputBytes"]],
        "LiftedBytes" -> Total[Lookup[group, "LiftedBytes"]]
      |>
    ],
    groups
  ]
];

nnloCommonFractionDenominator[denominators_List, timeLimit_: 60] := Module[
  {common = 1, previous, candidate, quotientChecks, normalized},
  Scan[
    Function[denominator,
      previous = common;
      candidate = TimeConstrained[
        Quiet @ PolynomialLCM[previous, denominator],
        timeLimit,
        $TimedOut
      ];
      If[
        candidate === $TimedOut ||
          ! PolynomialQ[candidate, nnloRootVariables],
        candidate = previous denominator
      ];
      normalized = nnloNormalizeFractionDenominator[candidate];
      If[normalized === $Failed, Return[$Failed, Module]];
      common = First[normalized];
      quotientChecks = {
        Cancel[common/denominator],
        Cancel[common/previous]
      };
      If[
        ! AllTrue[quotientChecks, PolynomialQ[#, nnloRootVariables] &],
        common = First @ nnloNormalizeFractionDenominator[
          previous denominator
        ]
      ]
    ],
    DeleteDuplicates[denominators, SameTest -> SameQ]
  ];
  common
];

nnloAssembleFractionColumn[entries_List, timeLimit_: 60] := Module[
  {
    commonDenominator, numeratorMaps, quotient, quotientMap,
    assembledNumerator, normalizedNumerator
  },
  If[entries === {}, Return[$Failed]];
  commonDenominator = nnloCommonFractionDenominator[
    Lookup[entries, "Denominator"],
    timeLimit
  ];
  If[commonDenominator === $Failed, Return[$Failed]];
  numeratorMaps = Map[
    Function[entry,
      quotient = Cancel[commonDenominator/entry["Denominator"]];
      If[! PolynomialQ[quotient, nnloRootVariables], Return[$Failed, Module]];
      quotientMap = nnloPolynomialMap[quotient];
      If[quotientMap === $Failed, Return[$Failed, Module]];
      nnloSparseMultiply[entry["Numerator"], quotientMap]
    ],
    entries
  ];
  If[MemberQ[numeratorMaps, $Failed], Return[$Failed]];
  assembledNumerator = nnloSparseAdd[numeratorMaps];
  normalizedNumerator = Map[
    TimeConstrained[
      Cancel[Together[#]],
      timeLimit,
      #
    ] &,
    assembledNumerator
  ];
  <|
    "Denominator" -> commonDenominator,
    "Numerator" -> normalizedNumerator,
    "DenominatorCount" -> Length[entries],
    "LeafCount" -> Total[Lookup[entries, "LeafCount"]]
  |>
];

nnloCertifyUniversalFactor[column_Association, timeLimit_: 60] := Module[
  {
    numeratorMap, denominatorMap, universalMap, allExponents,
    minimumExponent, shift, shiftedNumerator, shiftedUniversal,
    keys, pivot, n0, v0, checks, hardCoefficient
  },
  numeratorMap = column["Numerator"];
  denominatorMap = nnloPolynomialMap[column["Denominator"]];
  If[denominatorMap === $Failed, Return[$Failed]];
  universalMap = nnloSparseShift[
    denominatorMap,
    nnloUniversalRootExponent
  ];
  allExponents = Join[Keys[numeratorMap], Keys[universalMap]];
  minimumExponent = Min /@ Transpose[allExponents];
  shift = Map[Max[0, -#] &, minimumExponent];
  shiftedNumerator = nnloSparseShift[numeratorMap, shift];
  shiftedUniversal = nnloSparseShift[universalMap, shift];
  keys = Union[Keys[shiftedNumerator], Keys[shiftedUniversal]];
  pivot = SelectFirst[
    keys,
    ! TrueQ[Lookup[shiftedUniversal, #, 0] === 0] &,
    Missing["NoPivot"]
  ];
  If[MissingQ[pivot], Return[$Failed]];
  n0 = Lookup[shiftedNumerator, pivot, 0];
  v0 = Lookup[shiftedUniversal, pivot, 0];
  checks = AssociationMap[
    nnloExactZeroQ[
      Lookup[shiftedNumerator, #, 0] v0 -
        n0 Lookup[shiftedUniversal, #, 0],
      timeLimit
    ] &,
    keys
  ];
  If[! AllTrue[Values[checks], TrueQ],
    Return[<|
      "Verified" -> False,
      "Checks" -> checks,
      "UnresolvedCount" -> Count[Values[checks], $TimedOut],
      "NonzeroCount" -> Count[Values[checks], False]
    |>]
  ];
  hardCoefficient = Cancel[n0/v0];
  <|
    "Verified" -> True,
    "HardCoefficient" -> hardCoefficient,
    "FractionFree" -> FreeQ[
      hardCoefficient,
      Alternatives @@ Join[nnloFractionVariables, nnloRootVariables]
    ],
    "Checks" -> checks,
    "Shift" -> shift
  |>
];
