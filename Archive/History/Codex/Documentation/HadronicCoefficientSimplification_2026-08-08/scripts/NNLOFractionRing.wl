(* Exact positive-root rational arithmetic for NNLO momentum fractions. *)

ClearAll[
  facetYa, facetYb, facetYh,
  nnloFractionVariables,
  nnloRootVariables,
  nnloExpectedDistributions,
  nnloUniversalRootExponent,
  nnloInexactNumberQ,
  nnloExactDataQ,
  nnloCanonicalCoefficient,
  nnloCoefficientZeroStatus,
  nnloExactZeroQ,
  nnloDistributionObjectQ,
  nnloStripDistributionFactor,
  nnloForbiddenFractionObjectQ,
  nnloFractionMonomialData,
  nnloCertifiedPositiveQ,
  nnloLiftPositiveFractionPowers,
  nnloPositiveRootLift,
  nnloValidExponentQ,
  nnloValidSparseMapQ,
  nnloSparseLookup,
  nnloSparsePolynomial,
  nnloSparseAdd,
  nnloSparseMultiply,
  nnloSparseShift,
  nnloPolynomialMap,
  nnloNormalizeFractionDenominator,
  nnloPolynomialQuotient,
  nnloFractionLeaf,
  nnloValidLeafQ,
  nnloMergeFractionLeaves,
  nnloValidEntryQ,
  nnloMergeFractionEntries,
  nnloCommonDenominatorStep,
  nnloCommonFractionDenominator,
  nnloAssembleFractionColumn,
  nnloCertifyUniversalFactor
];

nnloFractionVariables = {xa, xb, zh};
nnloRootVariables = {facetYa, facetYb, facetYh};
nnloExpectedDistributions = {f1[xa], f1[xb], D1[zh]};
nnloUniversalRootExponent = {-2, -2, -4};

nnloInexactNumberQ[value_] :=
  NumberQ[value] && Precision[value] =!= Infinity;

nnloExactDataQ[expression_] := FreeQ[
  HoldComplete[expression],
  value_ /; nnloInexactNumberQ[value]
];

nnloCanonicalCoefficient[expression_, timeLimit_: 60] := TimeConstrained[
  Quiet @ CheckAbort[
    Check[Cancel[Together[expression]], $Failed],
    $Failed
  ],
  timeLimit,
  $TimedOut
];

nnloCoefficientZeroStatus[expression_, timeLimit_: 60] := Module[
  {canonical},
  If[TrueQ[expression === 0], Return[True]];
  canonical = nnloCanonicalCoefficient[expression, timeLimit];
  Which[
    canonical === $TimedOut, $TimedOut,
    canonical === $Failed, $Failed,
    TrueQ[canonical === 0], True,
    True, False
  ]
];

nnloExactZeroQ[expression_, timeLimit_: 60] :=
  nnloCoefficientZeroStatus[expression, timeLimit];

nnloDistributionObjectQ[object_] := MatchQ[
  Unevaluated[object],
  (f1 | g1L | h1 | D1 | G1L | H1)[__]
];

nnloStripDistributionFactor[expression_, timeLimit_: 60] := Module[
  {
    found, expectedHeld, atoms, frozen, atomProduct, quotient, directQuotient,
    reconstructionStatus
  },
  If[! nnloExactDataQ[expression], Return[$Failed]];
  If[TrueQ[expression === 0], Return[0]];
  found = DeleteDuplicates @ Cases[
    HoldComplete[expression],
    object_ /; nnloDistributionObjectQ[Unevaluated[object]] :>
      HoldComplete[object],
    Infinity
  ];
  expectedHeld = HoldComplete /@ nnloExpectedDistributions;
  If[Sort[found] =!= Sort[expectedHeld], Return[$Failed]];
  atoms = Array[Unique["nnloDistribution$"] &, Length[expectedHeld]];
  frozen = expression /. Thread[nnloExpectedDistributions -> atoms];
  atomProduct = Times @@ atoms;
  directQuotient = frozen /. Thread[atoms -> 1];
  If[FreeQ[directQuotient, Alternatives @@ atoms],
    reconstructionStatus = nnloExactZeroQ[
      frozen - atomProduct directQuotient,
      timeLimit
    ];
    If[reconstructionStatus === True, Return[directQuotient]];
    If[MemberQ[{$Failed, $TimedOut}, reconstructionStatus],
      Return[reconstructionStatus]
    ]
  ];
  quotient = nnloCanonicalCoefficient[frozen/atomProduct, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, quotient], Return[quotient]];
  If[! FreeQ[quotient, Alternatives @@ atoms], Return[$Failed]];
  reconstructionStatus = nnloExactZeroQ[
    frozen - atomProduct quotient,
    timeLimit
  ];
  If[reconstructionStatus =!= True, Return[reconstructionStatus]];
  quotient
];

nnloForbiddenFractionObjectQ[expression_] := Module[
  {fractionSymbols, forbiddenHeads, badHeadObjects, badPowers},
  fractionSymbols = Alternatives @@ nnloFractionVariables;
  forbiddenHeads =
    _Log | _Gamma | _Beta | _Pochhammer | _Hypergeometric2F1 |
    _PolyLog | _Piecewise | _ConditionalExpression | _Abs | _Sign |
    _UnitStep | _DiracDelta;
  badHeadObjects = Cases[
    HoldComplete[expression],
    object : forbiddenHeads /;
      ! FreeQ[Unevaluated[object], fractionSymbols] :>
        HoldComplete[object],
    Infinity
  ];
  badPowers = Cases[
    HoldComplete[expression],
    object : Power[base_, exponent_] /; (
      ! FreeQ[Unevaluated[object], fractionSymbols] &&
      ! IntegerQ[exponent] &&
      ! (
        MemberQ[nnloFractionVariables, Unevaluated[base]] &&
        MatchQ[Unevaluated[exponent], _Integer | _Rational] &&
        IntegerQ[2 exponent]
      )
    ) :> HoldComplete[object],
    Infinity
  ];
  badHeadObjects =!= {} || badPowers =!= {}
];

nnloFractionMonomialData[base_] := Module[
  {factors, exponents, coefficient = 1, position},
  factors = If[Head[base] === Times, List @@ base, {base}];
  exponents = ConstantArray[0, Length[nnloFractionVariables]];
  Do[
    position = SelectFirst[
      Range[Length[nnloFractionVariables]],
      SameQ[nnloFractionVariables[[#]], factor] &,
      Missing["NotFound"]
    ];
    Which[
      ! MissingQ[position],
        exponents[[position]]++,
      Head[factor] === Power && IntegerQ[factor[[2]]] &&
          AnyTrue[
            nnloFractionVariables,
            SameQ[#, factor[[1]]] &
          ],
        position = SelectFirst[
          Range[Length[nnloFractionVariables]],
          SameQ[nnloFractionVariables[[#]], factor[[1]]] &
        ];
        exponents[[position]] += factor[[2]],
      FreeQ[factor, Alternatives @@ nnloFractionVariables],
        coefficient *= factor,
      True,
        coefficient = $Failed;
        Break[]
    ],
    {factor, factors}
  ];
  If[coefficient === $Failed, Return[$Failed]];
  If[
    ! FreeQ[coefficient, Alternatives @@ nnloFractionVariables],
    Return[$Failed]
  ];
  <|"Coefficient" -> coefficient, "Exponents" -> exponents|>
];

nnloCertifiedPositiveQ[expression_, assumptions_, timeLimit_: 60] := Module[
  {result},
  If[TrueQ[expression > 0], Return[True]];
  result = TimeConstrained[
    Quiet @ CheckAbort[
      Check[
        FullSimplify[expression > 0, Assumptions -> assumptions],
        $Failed
      ],
      $Failed
    ],
    timeLimit,
    $TimedOut
  ];
  TrueQ[result]
];

nnloLiftPositiveFractionPowers[
    expression_,
    assumptions_,
    timeLimit_: 60
  ] := Module[
  {powers, rules, data, coefficient, exponents, rootExponents, lifted},
  powers = DeleteDuplicates @ Cases[
    expression,
    power : Power[base_, exponent_Rational] /; (
      ! IntegerQ[exponent] &&
      ! FreeQ[base, Alternatives @@ nnloFractionVariables]
    ) :> power,
    Infinity
  ];
  rules = Catch @ Map[
    Function[power,
      data = nnloFractionMonomialData[power[[1]]];
      If[data === $Failed, Throw[$Failed]];
      coefficient = data["Coefficient"];
      exponents = data["Exponents"];
      rootExponents = 2 power[[2]] exponents;
      If[
        ! AllTrue[rootExponents, IntegerQ] ||
          ! nnloCertifiedPositiveQ[
            coefficient,
            assumptions,
            Min[10, timeLimit]
          ],
        Throw[$Failed]
      ];
      power -> (
        coefficient^power[[2]] (
          Times @@ MapThread[Power, {nnloRootVariables, rootExponents}]
        )
      )
    ],
    powers
  ];
  If[rules === $Failed, Return[$Failed]];
  lifted = expression /. Dispatch[rules];
  If[
    ! FreeQ[
      lifted,
      Power[base_, exponent_] /; (
        ! IntegerQ[exponent] &&
        ! FreeQ[base, Alternatives @@ nnloFractionVariables]
      )
    ],
    Return[$Failed]
  ];
  lifted
];

nnloPositiveRootLift[
    expression_,
    timeLimit_: 60,
    assumptions_: True
  ] := Module[
  {prepared, lifted, rational, numerator, denominator},
  If[
    ! nnloExactDataQ[expression],
    Return[$Failed]
  ];
  prepared = nnloLiftPositiveFractionPowers[
    expression,
    assumptions,
    timeLimit
  ];
  If[prepared === $Failed || nnloForbiddenFractionObjectQ[prepared],
    Return[$Failed]
  ];
  lifted = prepared /. {
    HoldPattern[Power[xa, exponent_Rational]] :> facetYa^(2 exponent),
    HoldPattern[Power[xb, exponent_Rational]] :> facetYb^(2 exponent),
    HoldPattern[Power[zh, exponent_Rational]] :> facetYh^(2 exponent),
    xa -> facetYa^2,
    xb -> facetYb^2,
    zh -> facetYh^2
  };
  If[
    ! FreeQ[lifted, Alternatives @@ nnloFractionVariables],
    Return[$Failed]
  ];
  numerator = Numerator[lifted];
  denominator = Denominator[lifted];
  If[
    PolynomialQ[numerator, nnloRootVariables] &&
      PolynomialQ[denominator, nnloRootVariables],
    Return[lifted]
  ];
  rational = nnloCanonicalCoefficient[lifted, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, rational], Return[rational]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[
    ! PolynomialQ[numerator, nnloRootVariables] ||
      ! PolynomialQ[denominator, nnloRootVariables],
    Return[$Failed]
  ];
  rational
];

nnloValidExponentQ[exponent_] :=
  MatchQ[exponent, {_Integer, _Integer, _Integer}];

nnloValidSparseMapQ[map_] := AssociationQ[map] &&
  AllTrue[Keys[map], nnloValidExponentQ] &&
  nnloExactDataQ[Values[map]] &&
  FreeQ[
    Values[map],
    Alternatives @@ Join[nnloFractionVariables, nnloRootVariables]
  ];

nnloSparseLookup[map_Association, exponent_List] := If[
  KeyExistsQ[map, exponent],
  map[exponent],
  0
];

nnloSparsePolynomial[map_Association] := If[
  nnloValidSparseMapQ[map],
  Total @ KeyValueMap[
    Function[{exponent, coefficient},
      coefficient Times @@ MapThread[Power, {nnloRootVariables, exponent}]
    ],
    map
  ],
  $Failed
];

nnloSparseAdd[maps_List] := Module[{result},
  If[! AllTrue[maps, nnloValidSparseMapQ], Return[$Failed]];
  result = Select[Merge[maps, Total], ! TrueQ[# === 0] &];
  If[nnloValidSparseMapQ[result], result, $Failed]
];

nnloSparseMultiply[first_Association, second_Association] := Module[
  {terms, result},
  If[
    ! nnloValidSparseMapQ[first] || ! nnloValidSparseMapQ[second],
    Return[$Failed]
  ];
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
  result = Select[Merge[Association /@ terms, Total], ! TrueQ[# === 0] &];
  If[nnloValidSparseMapQ[result], result, $Failed]
];

nnloSparseShift[map_Association, shift_List] := Module[{result},
  If[
    ! nnloValidSparseMapQ[map] || ! nnloValidExponentQ[shift],
    Return[$Failed]
  ];
  result = Association @ KeyValueMap[(#1 + shift) -> #2 &, map];
  If[nnloValidSparseMapQ[result], result, $Failed]
];

nnloPolynomialMap[polynomial_] := Module[{rules, map},
  If[
    ! nnloExactDataQ[polynomial] ||
      ! PolynomialQ[polynomial, nnloRootVariables],
    Return[$Failed]
  ];
  If[FreeQ[polynomial, Alternatives @@ nnloRootVariables],
    Return[If[TrueQ[polynomial === 0], <||>, <|{0, 0, 0} -> polynomial|>]]
  ];
  rules = Quiet @ Check[CoefficientRules[polynomial, nnloRootVariables], $Failed];
  If[rules === $Failed, Return[$Failed]];
  map = Association[rules];
  If[nnloValidSparseMapQ[map], map, $Failed]
];

nnloNormalizeFractionDenominator[denominator_, timeLimit_: 60] := Module[
  {
    canonical, rules, leadingRule, leadingCoefficient,
    leadingStatus, normalized, reconstructionStatus
  },
  canonical = If[
    nnloExactDataQ[denominator] &&
      PolynomialQ[denominator, nnloRootVariables],
    denominator,
    nnloCanonicalCoefficient[denominator, timeLimit]
  ];
  If[MemberQ[{$Failed, $TimedOut}, canonical], Return[canonical]];
  If[
    ! PolynomialQ[canonical, nnloRootVariables] ||
      nnloCoefficientZeroStatus[canonical, timeLimit] =!= False,
    Return[$Failed]
  ];
  rules = CoefficientRules[canonical, nnloRootVariables];
  If[rules === {}, Return[$Failed]];
  leadingRule = First @ Reverse @ SortBy[rules, First];
  leadingCoefficient = nnloCanonicalCoefficient[Last[leadingRule], timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, leadingCoefficient],
    Return[leadingCoefficient]
  ];
  leadingStatus = nnloCoefficientZeroStatus[leadingCoefficient, timeLimit];
  If[leadingStatus =!= False, Return[leadingStatus /. True -> $Failed]];
  normalized = nnloCanonicalCoefficient[
    canonical/leadingCoefficient,
    timeLimit
  ];
  If[MemberQ[{$Failed, $TimedOut}, normalized], Return[normalized]];
  If[! PolynomialQ[normalized, nnloRootVariables], Return[$Failed]];
  reconstructionStatus = nnloExactZeroQ[
    canonical - leadingCoefficient normalized,
    timeLimit
  ];
  If[reconstructionStatus =!= True, Return[reconstructionStatus]];
  {normalized, leadingCoefficient}
];

nnloPolynomialQuotient[dividend_, divisor_, timeLimit_: 60] := Module[
  {quotient, reconstructionStatus},
  If[nnloCoefficientZeroStatus[divisor, timeLimit] =!= False,
    Return[$Failed]
  ];
  quotient = nnloCanonicalCoefficient[dividend/divisor, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, quotient], Return[quotient]];
  If[! PolynomialQ[quotient, nnloRootVariables],
    Return[Missing["NotDivisible"]]
  ];
  reconstructionStatus = nnloExactZeroQ[
    dividend - divisor quotient,
    timeLimit
  ];
  Which[
    reconstructionStatus === True, quotient,
    reconstructionStatus === $TimedOut, $TimedOut,
    True, $Failed
  ]
];

nnloFractionLeaf[
    expression_,
    timeLimit_: 60,
    assumptions_: True
  ] := Module[
  {
    quotient, lifted, numerator, denominator, denominatorData,
    normalizedDenominator, leadingCoefficient, normalizedNumerator,
    numeratorMap, reconstructed, reconstructionStatus
  },
  quotient = nnloStripDistributionFactor[expression, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, quotient], Return[quotient]];
  lifted = nnloPositiveRootLift[quotient, timeLimit, assumptions];
  If[MemberQ[{$Failed, $TimedOut}, lifted], Return[lifted]];
  numerator = Numerator[lifted];
  denominator = Denominator[lifted];
  denominatorData = nnloNormalizeFractionDenominator[denominator, timeLimit];
  If[MemberQ[{$Failed, $TimedOut}, denominatorData], Return[denominatorData]];
  {normalizedDenominator, leadingCoefficient} = denominatorData;
  normalizedNumerator = numerator/leadingCoefficient;
  If[! nnloExactDataQ[normalizedNumerator], Return[$Failed]];
  numeratorMap = nnloPolynomialMap[normalizedNumerator];
  If[numeratorMap === $Failed, Return[$Failed]];
  reconstructed = nnloSparsePolynomial[numeratorMap]/normalizedDenominator;
  If[reconstructed === $Failed, Return[$Failed]];
  reconstructionStatus = nnloExactZeroQ[
    nnloSparsePolynomial[numeratorMap] leadingCoefficient - numerator,
    timeLimit
  ];
  If[reconstructionStatus =!= True,
    reconstructionStatus = nnloExactZeroQ[reconstructed - lifted, timeLimit]
  ];
  If[reconstructionStatus =!= True, Return[reconstructionStatus]];
  <|
    "Denominator" -> normalizedDenominator,
    "Numerator" -> numeratorMap,
    "InputBytes" -> ByteCount[expression],
    "LiftedBytes" -> ByteCount[lifted]
  |>
];

nnloValidLeafQ[leaf_] := AssociationQ[leaf] &&
  ContainsAll[Keys[leaf], {"Denominator", "Numerator", "InputBytes", "LiftedBytes"}] &&
  nnloValidSparseMapQ[leaf["Numerator"]] &&
  PolynomialQ[leaf["Denominator"], nnloRootVariables] &&
  nnloExactDataQ[leaf];

nnloMergeFractionLeaves[leaves_List] := Module[
  {groups, entries},
  If[! AllTrue[leaves, nnloValidLeafQ], Return[$Failed]];
  groups = GroupBy[leaves, HoldComplete[#1["Denominator"]] &];
  entries = KeyValueMap[
    Function[{heldDenominator, group},
      With[{numerator = nnloSparseAdd[Lookup[group, "Numerator"]]},
        If[numerator === $Failed,
          $Failed,
          <|
            "Denominator" -> ReleaseHold[heldDenominator],
            "Numerator" -> numerator,
            "LeafCount" -> Length[group],
            "InputBytes" -> Total[Lookup[group, "InputBytes"]],
            "LiftedBytes" -> Total[Lookup[group, "LiftedBytes"]]
          |>
        ]
      ]
    ],
    groups
  ];
  If[MemberQ[entries, $Failed], $Failed, entries]
];

nnloValidEntryQ[entry_] := AssociationQ[entry] &&
  ContainsAll[
    Keys[entry],
    {"Denominator", "Numerator", "LeafCount", "InputBytes", "LiftedBytes"}
  ] &&
  nnloValidSparseMapQ[entry["Numerator"]] &&
  PolynomialQ[entry["Denominator"], nnloRootVariables] &&
  nnloExactDataQ[entry];

nnloMergeFractionEntries[entries_List] := Module[
  {groups, merged},
  If[! AllTrue[entries, nnloValidEntryQ], Return[$Failed]];
  groups = GroupBy[entries, HoldComplete[#1["Denominator"]] &];
  merged = KeyValueMap[
    Function[{heldDenominator, group},
      With[{numerator = nnloSparseAdd[Lookup[group, "Numerator"]]},
        If[numerator === $Failed,
          $Failed,
          <|
            "Denominator" -> ReleaseHold[heldDenominator],
            "Numerator" -> numerator,
            "LeafCount" -> Total[Lookup[group, "LeafCount"]],
            "InputBytes" -> Total[Lookup[group, "InputBytes"]],
            "LiftedBytes" -> Total[Lookup[group, "LiftedBytes"]]
          |>
        ]
      ]
    ],
    groups
  ];
  If[MemberQ[merged, $Failed], $Failed, merged]
];

nnloCommonDenominatorStep[common_, denominator_, timeLimit_] := Module[
  {commonOverDenominator, denominatorOverCommon, normalized},
  If[common === $Failed || common === $TimedOut,
    common,
    commonOverDenominator = nnloPolynomialQuotient[
      common,
      denominator,
      timeLimit
    ];
    denominatorOverCommon = nnloPolynomialQuotient[
      denominator,
      common,
      timeLimit
    ];
    Which[
      commonOverDenominator === $Failed ||
        commonOverDenominator === $TimedOut,
        commonOverDenominator,
      ! MissingQ[commonOverDenominator],
        common,
      denominatorOverCommon === $Failed ||
        denominatorOverCommon === $TimedOut,
        denominatorOverCommon,
      ! MissingQ[denominatorOverCommon],
        normalized = nnloNormalizeFractionDenominator[denominator, timeLimit];
        If[ListQ[normalized], First[normalized], $Failed],
      True,
        normalized = nnloNormalizeFractionDenominator[
          common denominator,
          timeLimit
        ];
        If[ListQ[normalized], First[normalized], $Failed]
    ]
  ]
];

nnloCommonFractionDenominator[denominators_List, timeLimit_: 60] := Fold[
  nnloCommonDenominatorStep[#1, #2, timeLimit] &,
  1,
  DeleteDuplicates[denominators, SameQ]
];

nnloAssembleFractionColumn[entries_List, timeLimit_: 60] := Module[
  {commonDenominator, numeratorMaps, assembledNumerator},
  If[entries === {} || ! AllTrue[entries, nnloValidEntryQ], Return[$Failed]];
  commonDenominator = nnloCommonFractionDenominator[
    Lookup[entries, "Denominator"],
    timeLimit
  ];
  If[commonDenominator === $Failed, Return[$Failed]];
  numeratorMaps = Catch @ Map[
    Function[entry,
      Module[{quotient, quotientMap, product},
        quotient = nnloPolynomialQuotient[
          commonDenominator,
          entry["Denominator"],
          timeLimit
        ];
        If[
          quotient === $Failed || quotient === $TimedOut || MissingQ[quotient],
          Throw[$Failed]
        ];
        quotientMap = nnloPolynomialMap[quotient];
        If[quotientMap === $Failed, Throw[$Failed]];
        product = nnloSparseMultiply[entry["Numerator"], quotientMap];
        If[product === $Failed, Throw[$Failed]];
        product
      ]
    ],
    entries
  ];
  If[numeratorMaps === $Failed, Return[$Failed]];
  assembledNumerator = nnloSparseAdd[numeratorMaps];
  If[assembledNumerator === $Failed, Return[$Failed]];
  <|
    "Denominator" -> commonDenominator,
    "Numerator" -> assembledNumerator,
    "DenominatorCount" -> Length[entries],
    "LeafCount" -> Total[Lookup[entries, "LeafCount"]]
  |>
];

nnloCertifyUniversalFactor[column_Association, timeLimit_: 60] := Module[
  {
    numeratorMap, denominator, denominatorMap, universalMap, keys,
    pivot, pivotStatuses = <||>, status, n0, v0, checks, values,
    invalidCount, hardCoefficient
  },
  numeratorMap = Lookup[column, "Numerator", $Failed];
  denominator = Lookup[column, "Denominator", $Failed];
  If[! nnloValidSparseMapQ[numeratorMap], Return[$Failed]];
  denominatorMap = nnloPolynomialMap[denominator];
  If[denominatorMap === $Failed || denominatorMap === <||>, Return[$Failed]];
  universalMap = nnloSparseShift[
    denominatorMap,
    nnloUniversalRootExponent
  ];
  If[universalMap === $Failed, Return[$Failed]];
  keys = Union[Keys[numeratorMap], Keys[universalMap]];
  pivot = SelectFirst[
    keys,
    Function[key,
      status = nnloCoefficientZeroStatus[
        nnloSparseLookup[universalMap, key],
        timeLimit
      ];
      AssociateTo[pivotStatuses, key -> status];
      status === False
    ],
    Missing["NoCertifiedNonzeroPivot"]
  ];
  If[MissingQ[pivot],
    Return[<|
      "Verified" -> False,
      "Status" -> "Unresolved",
      "Reason" -> "No certified nonzero universal coefficient",
      "PivotStatuses" -> pivotStatuses
    |>]
  ];
  n0 = nnloSparseLookup[numeratorMap, pivot];
  v0 = nnloSparseLookup[universalMap, pivot];
  If[TrueQ[v0 === 0], Return[$Failed]];
  checks = AssociationMap[
    nnloCoefficientZeroStatus[
      nnloSparseLookup[numeratorMap, #] v0 -
        n0 nnloSparseLookup[universalMap, #],
      timeLimit
    ] &,
    keys
  ];
  values = Values[checks];
  invalidCount = Count[values, Except[True | False | $TimedOut]];
  If[invalidCount > 0,
    Return[<|
      "Verified" -> False,
      "Status" -> "InvalidInput",
      "Checks" -> checks,
      "FailureCount" -> invalidCount
    |>]
  ];
  If[MemberQ[values, $TimedOut],
    Return[<|
      "Verified" -> False,
      "Status" -> "Unresolved",
      "Checks" -> checks,
      "TimeoutCount" -> Count[values, $TimedOut]
    |>]
  ];
  If[MemberQ[values, False],
    Return[<|
      "Verified" -> False,
      "Status" -> "FormalMismatch",
      "Checks" -> checks,
      "FormalNonzeroCount" -> Count[values, False]
    |>]
  ];
  hardCoefficient = Which[
    TrueQ[v0 === 1], n0,
    TrueQ[v0 === -1], -n0,
    True, TimeConstrained[
      Quiet @ CheckAbort[Check[Cancel[n0/v0], $Failed], $Failed],
      timeLimit,
      $TimedOut
    ]
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, hardCoefficient] ||
      ! FreeQ[
        hardCoefficient,
        Alternatives @@ Join[nnloFractionVariables, nnloRootVariables]
      ],
    Return[$Failed]
  ];
  <|
    "Verified" -> True,
    "Status" -> "Verified",
    "HardCoefficient" -> hardCoefficient,
    "FractionFree" -> True,
    "DistributionFactor" -> nnloDistributionFactor,
    "UniversalRootExponent" -> nnloUniversalRootExponent,
    "ColumnReconstructionVerified" -> True,
    "CoefficientFieldConvention" ->
      "FormalRationalFunctionsWithInertAnalyticAtoms",
    "Pivot" -> pivot,
    "Checks" -> checks
  |>
];
