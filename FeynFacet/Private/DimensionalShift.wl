(* Topology-dependent BMHV and Tarasov dimensional shifts. *)

DimensionalShift::loops =
  "Loop momenta must be a nonempty list identical to the topology loop-momentum ordering. Received `1`; topology uses `2`.";

DimensionalShift::topology =
  "The supplied object is not a valid complete FCTopology: `1`.";

DimensionalShift::dimension =
  "The topology must use exactly one symbolic loop dimension. Found `1`.";

DimensionalShift::propagators =
  "Could not map the propagator product into the supplied topology: `1`.";

DimensionalShift::cut =
  "Could not identify the required Cut propagators in the supplied topology: `1`.";

DimensionalShift::numerator =
  "The numerator is outside the supported polynomial SP/SPD/SPE grammar: `1`.";

DimensionalShift::evanescent =
  "Evanescent scalar products may contain only declared loop momenta. Unsupported objects: `1`.";

DimensionalShift::shift =
  "The topology-dependent dimensional recurrence failed at `1`.";

DimensionalShift::families =
  "Integral families must be a nonempty list of associations containing Propagators and Topology. Received `1`.";

$dimensionalShiftFailure = "FeynFacetDimensionalShiftFailure";


dimensionalShiftGramMomentFunction[
    covariance_,
    componentDimension_
  ] := Module[
  {
    loopCount, pairs, variables, sourceMatrix,
    determinantRules, beta, coefficient
  },

  loopCount = Length[covariance];
  pairs = Flatten[
    Table[{i, j}, {i, loopCount}, {j, i, loopCount}],
    1
  ];
  variables = Array[gramSource, Length[pairs]];
  sourceMatrix = ConstantArray[0, {loopCount, loopCount}];
  Do[
    With[
      {
        i = pairs[[position, 1]],
        j = pairs[[position, 2]],
        value = variables[[position]]
      },
      If[
        i === j,
        sourceMatrix[[i, i]] = value,
        sourceMatrix[[i, j]] = value/2;
        sourceMatrix[[j, i]] = value/2
      ]
    ],
    {position, Length[pairs]}
  ];
  determinantRules = Select[
    CoefficientRules[
      Expand @ Det[
        IdentityMatrix[loopCount] - 2 covariance . sourceMatrix
      ],
      variables
    ],
    Total[First[#]] > 0 &
  ];
  beta = componentDimension/2;
  coefficient[powers_List] /; Total[powers] === 0 := 1;
  coefficient[powers_List] /; Total[powers] > 0 :=
    coefficient[powers] = Module[{position, admissible},
      position = First @ FirstPosition[powers, _?(# > 0 &)];
      admissible = Select[
        determinantRules,
        And @@ Thread[First[#] <= powers] &
      ];
      -Total[
        Last[#] *
          (powers[[position]] +
            (beta - 1) First[#][[position]]) *
          coefficient[powers - First[#]] & /@ admissible
      ]/powers[[position]]
    ];

  Function[bilinears,
    Module[{normalized, powers},
      normalized = Sort /@ bilinears;
      If[! AllTrue[normalized, MemberQ[pairs, #] &], Return[$Failed]];
      powers = Count[normalized, #] & /@ pairs;
      Times @@ (Factorial /@ powers) coefficient[powers]
    ]
  ]
];

dimensionalShiftParameterPolynomial[
    polynomial_,
    parameters_List,
    positions_List,
    base_FeynCalc`GLI
  ] := Module[{indices, rules, oneTerm},
  indices = base[[2]];
  rules = CoefficientRules[Expand[polynomial], parameters];
  oneTerm[powers_List -> coefficient_] := Module[{dots, factor},
    dots = ConstantArray[0, Length[indices]];
    Scan[
      Function[i, dots[[positions[[i]]]] = powers[[i]]],
      Range[Length[parameters]]
    ];
    factor = (-1)^Total[powers] Times @@ Table[
      Pochhammer[indices[[positions[[i]]]], powers[[i]]],
      {i, Length[powers]}
    ];
    coefficient factor FeynCalc`GLI[base[[1]], indices + dots]
  ];
  Total[oneTerm /@ rules]
];

dimensionalShiftRaiseOnce[
    expression_,
    topology_FeynCalc`FCTopology,
    offset_,
    dimension_
  ] := Module[{parts, glis, images, composed},
  parts = linearIntegralSum[expression];
  If[
    FailureQ[parts] || ! exactZeroQ[parts["Remainder"]],
    Return[$Failed]
  ];
  glis = Keys[parts["Terms"]];
  images = AssociationMap[
    Function[gli,
      With[{
          raised = CheckAbort[
            FeynCalc`FCLoopGLIRaiseDimension[
              gli,
              topology,
              FeynCalc`Collecting -> False,
              FeynCalc`FCE -> True
            ] /. dimension -> dimension + offset,
            $Failed
          ]
        },
        If[raised === $Failed, $Failed, linearIntegralSum[raised]]
      ]
    ],
    glis
  ];
  If[AnyTrue[Values[images], FailureQ], Return[$Failed]];
  composed = linearComposeReduction[parts, images];
  If[FailureQ[composed], $Failed, linearToExpression[composed]]
];

dimensionalShiftRaiseToD[
    expression_,
    topology_FeynCalc`FCTopology,
    rank_Integer?NonNegative,
    dimension_,
    cutIndices_List
  ] := Module[{current, offsets},
  current = dimensionalShiftPreserveCuts[expression, cutIndices];
  If[current === $Failed || rank === 0, Return[current]];
  offsets = 2 Reverse[Range[0, rank - 1]];
  Fold[
    Function[{accumulator, offset},
      If[accumulator === $Failed,
        $Failed,
        With[{
            raised = dimensionalShiftRaiseOnce[
              accumulator,
              topology,
              offset,
              dimension
            ]
          },
          If[
            raised === $Failed,
            $Failed,
            dimensionalShiftPreserveCuts[raised, cutIndices]
          ]
        ]
      ]
    ],
    current,
    offsets
  ]
];

dimensionalShiftMultiplyNumerator[
    numerator_,
    integral_,
    rules_List
  ] := Module[{converted},
  converted = FeynCalc`ExpandScalarProduct[numerator] /. rules;
  Expand[converted integral] /.
    FeynCalc`GLI -> FeynCalc`GLIMultiply /.
    FeynCalc`GLIMultiply -> FeynCalc`GLI
];

dimensionalShiftSplitNumerator[
    numerator_,
    loopMomenta_List
  ] := Module[{terms, splitTerm, grouped},
  terms = termList[Expand[numerator]];
  splitTerm[term_] := Module[{factors, loopFactors, scalarFactors},
    factors = If[Head[term] === Times, List @@ term, {term}];
    loopFactors = Select[
      factors,
      ! FreeQ[Unevaluated[#], Alternatives @@ loopMomenta] &
    ];
    scalarFactors = Select[
      factors,
      FreeQ[Unevaluated[#], Alternatives @@ loopMomenta] &
    ];
    Times @@ loopFactors -> Times @@ scalarFactors
  ];
  grouped = Merge[splitTerm /@ terms, Total];
  Select[grouped, ! exactZeroQ[#] &]
];

dimensionalShiftReduceNumerator[
    numerator_,
    integral_,
    topology_FeynCalc`FCTopology,
    baseDimension_,
    tensorDimension_,
    loopMomenta_List,
    rules_List,
    cutIndices_List,
    physicalVectors_List
  ] := Module[
  {
    parts, numeratorParts, tensorHead, reduceMonomial,
    contributions, sparse, topologyExternalMomenta, certifiedVectors
  },

  parts = linearIntegralSum[Expand[integral]];
  If[
    FailureQ[parts] ||
      ! exactZeroQ[parts["Remainder"]],
    Return[$Failed]
  ];
  numeratorParts = dimensionalShiftSplitNumerator[
    numerator,
    loopMomenta
  ];
  If[
    ! AssociationQ[numeratorParts] ||
      ! FreeQ[Values[numeratorParts], Alternatives @@ loopMomenta],
    Return[$Failed]
  ];
  tensorHead = FeynCalc`FCGV["GLIProduct"];
  topologyExternalMomenta = topology[[4]];
  certifiedVectors = DeleteDuplicates[physicalVectors];
  If[
    ! AllTrue[
      Join[topologyExternalMomenta, certifiedVectors],
      MatchQ[#, _Symbol] &
    ] ||
      ! SubsetQ[certifiedVectors, topologyExternalMomenta],
    Return[$Failed]
  ];
  reduceMonomial[loopPart_, gli_FeynCalc`GLI] :=
    reduceMonomial[loopPart, gli] = Module[
      {
        direct, tensorInput, tensorReduced, result, reducedParts,
        tensorDimensionSymbol,
        numeratorMomenta, extraVectors
      },
      direct = dimensionalShiftMultiplyNumerator[
        loopPart,
        gli,
        rules
      ];
      If[
        FreeQ[direct, Alternatives @@ loopMomenta],
        direct = dimensionalShiftPreserveCuts[direct, cutIndices];
        If[direct === $Failed, Return[$Failed]];
        Return[linearIntegralSum[direct]]
      ];
      numeratorMomenta = DeleteDuplicates @ Cases[
        FeynCalc`FCI[loopPart],
        FeynCalc`Momentum[momentum_Symbol, ___] :> momentum,
        Infinity
      ];
      extraVectors = Complement[
        numeratorMomenta,
        loopMomenta,
        topologyExternalMomenta
      ];
      If[! SubsetQ[certifiedVectors, extraVectors], Return[$Failed]];
      If[! FreeQ[loopPart, baseDimension], Return[$Failed]];
      tensorDimensionSymbol = Unique["tensorDimension$"];
      tensorInput = FeynCalc`FCI[tensorHead[loopPart, gli]];
      tensorReduced = CheckAbort[
        FeynCalc`FCLoopTensorReduce[
          tensorInput,
          {topology},
          Head -> tensorHead,
          FeynCalc`Uncontract -> extraVectors,
          FeynCalc`Dimension -> baseDimension,
          FeynCalc`Collecting -> False,
          FeynCalc`Contract -> True,
          FeynCalc`DiracSimplify -> False,
          FeynCalc`Factoring -> False,
          FeynCalc`FCI -> True,
          FeynCalc`FCE -> False,
          FeynCalc`FCVerbose -> False
        ],
        $Failed
      ];
      If[tensorReduced === $Failed, Return[$Failed]];
      tensorReduced = FeynCalc`FCI[
        FeynCalc`FCE[tensorReduced] /.
          baseDimension -> tensorDimensionSymbol /.
          tensorDimensionSymbol -> tensorDimension
      ];
      If[! FreeQ[tensorReduced, tensorDimensionSymbol], Return[$Failed]];
      result = tensorReduced /. HoldPattern[
        FeynCalc`FCGV["GLIProduct"][reducedNumerator_, reducedGLI_]
      ] :> dimensionalShiftMultiplyNumerator[
        reducedNumerator,
        reducedGLI,
        rules
      ];
      result = dimensionalShiftPreserveCuts[result, cutIndices];
      If[result === $Failed, Return[$Failed]];
      reducedParts = linearIntegralSum[result];
      If[
        FailureQ[reducedParts] ||
          ! exactZeroQ[reducedParts["Remainder"]] ||
          ! FreeQ[
            Values[reducedParts["Terms"]],
            Alternatives @@ loopMomenta
          ],
        $Failed,
        reducedParts
      ]
    ];
  contributions = Flatten @ KeyValueMap[
    Function[{gli, integralCoefficient},
      KeyValueMap[
        Function[{loopPart, scalarCoefficient},
          With[{reduced = reduceMonomial[loopPart, gli]},
            If[
              reduced === $Failed || FailureQ[reduced],
              $Failed,
              linearScale[
                reduced,
                integralCoefficient scalarCoefficient
              ]
            ]
          ]
        ],
        numeratorParts
      ]
    ],
    parts["Terms"]
  ];
  If[
    MemberQ[contributions, $Failed] ||
      ! AllTrue[contributions, linearIntegralSumQ],
    Return[$Failed]
  ];
  sparse = linearDropZeros @ linearAdd[contributions];
  If[FailureQ[sparse], $Failed, linearToExpression[sparse]]
];

dimensionalShiftPreserveCuts[expression_, cutIndices_List] := Module[
  {parts, keepIntegralQ, projected},
  parts = linearIntegralSum[expression];
  If[
    FailureQ[parts] || ! exactZeroQ[parts["Remainder"]],
    Return[$Failed]
  ];
  If[cutIndices === {}, Return[linearToExpression[parts]]];
  keepIntegralQ[gli_FeynCalc`GLI] := Module[{indices},
    indices = gli[[2, cutIndices]];
    If[! VectorQ[indices, IntegerQ], Return[$Failed]];
    AllTrue[indices, Positive]
  ];
  projected = Association @ Select[
    Normal[parts["Terms"]],
    TrueQ[keepIntegralQ[First[#]]] &
  ];
  If[
    AnyTrue[Keys[parts["Terms"]], keepIntegralQ[#] === $Failed &],
    $Failed,
    linearToExpression @ <|
      "Terms" -> canonicalizeLinearTerms[projected],
      "Remainder" -> 0
    |>
  ]
];

dimensionalShiftNormalizeNumerator[expression_, loopMomenta_List] := Module[
  {expanded, dependsOnLoopQ},
  dependsOnLoopQ[object_] :=
    ! FreeQ[Unevaluated[object], Alternatives @@ loopMomenta];
  expanded = FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expression];
  expanded = expanded /. {
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      dependsOnLoopQ[{a, b}] :>
        FeynCalc`SPD[a, b] - FeynCalc`SPE[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      dependsOnLoopQ[a] :>
        FeynCalc`SPD[a] - FeynCalc`SPE[a]
  };
  FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expanded]
];


DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_List,
    topology_FeynCalc`FCTopology,
    physicalVectors_List
  ] := Catch[
  Module[
    {
      dimensions, dimension,
      cutRecords, cutMomenta, cutDirections, cutIndices,
      algebraicPropagators, convertedPropagators, mappedPropagators,
      baseGLIs, base, propagatorCoefficient,
      rulesToGLI,
      expanded, denominatorObjects, speObjects, badSPE, validSPEQ,
      atoms, polynomial, coefficientRules,
      prepared, powers, matrix, parameters, positions, covariance,
      spePair, gramMoment, oneMonomial, result, unresolved,
      parts, diagnostics, certifiedPhysicalVectors
    },

    If[loopMomenta === {} || loopMomenta =!= topology[[3]],
      Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    If[! completeTopologyQ[topology],
      Message[DimensionalShift::topology, topology];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimensions = Quiet @ CheckAbort[
      FeynCalc`FCGetDimensions[FeynCalc`FCI[topology[[2]]]],
      $Failed
    ];
    If[! MatchQ[dimensions, {_Symbol}],
      Message[DimensionalShift::dimension, dimensions];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimension = First[dimensions];
    certifiedPhysicalVectors = DeleteDuplicates[physicalVectors];
    If[
      ! AllTrue[certifiedPhysicalVectors, MatchQ[#, _Symbol] &] ||
        ! SubsetQ[certifiedPhysicalVectors, topology[[4]]],
      Message[DimensionalShift::numerator, physicalVectors];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    cutRecords = cutData[propagators];
    If[cutRecords === $Failed,
      Message[DimensionalShift::cut, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    cutMomenta = First /@ cutRecords;
    cutDirections = Last /@ cutRecords;

    algebraicPropagators = propagators /. {
      HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
      HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
    };
    convertedPropagators = CheckAbort[
      FeynCalc`FCLoopToGLI[algebraicPropagators, loopMomenta],
      $Failed
    ];
    If[! MatchQ[
        convertedPropagators,
        {_, _FeynCalc`FCTopology}
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    mappedPropagators = CheckAbort[
      convertedPropagators[[1]] /.
        FeynCalc`FCLoopCreateRuleGLIToGLI[
          topology,
          convertedPropagators[[2]]
        ],
      $Failed
    ];
    baseGLIs = Cases[
      mappedPropagators,
      _FeynCalc`GLI,
      {0, Infinity}
    ];
    If[mappedPropagators === $Failed || Length[baseGLIs] =!= 1,
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    base = First[baseGLIs];
    rulesToGLI = CheckAbort[
      Flatten @ FeynCalc`FCLoopCreateRulesToGLI[topology],
      $Failed
    ];
    If[rulesToGLI === $Failed,
      Message[DimensionalShift::shift, "rules to GLI"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = mappedPropagators /. base -> 1;
    If[
      ! FreeQ[propagatorCoefficient, FeynCalc`GLI] ||
      ! FreeQ[
        propagatorCoefficient,
        Alternatives @@ loopMomenta
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = FeynCalc`FCE @
      FeynCalc`FeynAmpDenominatorExplicit[
        propagatorCoefficient,
        FeynCalc`FCI -> True
      ];

    cutIndices = topologyPropagatorIndex[
      FeynCalc`SFAD[#],
      topology,
      loopMomenta
    ] & /@ cutMomenta;
    If[! FreeQ[cutIndices, $Failed],
      Message[DimensionalShift::cut, cutMomenta];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    expanded = dimensionalShiftNormalizeNumerator[
      propagatorCoefficient integrand,
      loopMomenta
    ];
    denominatorObjects = Cases[
      expanded,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      {0, Infinity}
    ];
    If[denominatorObjects =!= {},
      Message[DimensionalShift::numerator, denominatorObjects];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    speObjects = DeleteDuplicates @ Cases[
      expanded,
      HoldPattern[FeynCalc`SPE[__]],
      {0, Infinity}
    ];
    validSPEQ[FeynCalc`SPE[a_]] := MemberQ[loopMomenta, a];
    validSPEQ[FeynCalc`SPE[a_, b_]] :=
      MemberQ[loopMomenta, a] && MemberQ[loopMomenta, b];
    validSPEQ[_] := False;
    badSPE = Select[speObjects, ! TrueQ[validSPEQ[#]] &];
    If[badSPE =!= {},
      Message[DimensionalShift::evanescent, badSPE];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    If[speObjects === {},
      result = dimensionalShiftReduceNumerator[
        expanded,
        base,
        topology,
        dimension,
        dimension,
        loopMomenta,
        rulesToGLI,
        cutIndices,
        certifiedPhysicalVectors
      ],
      atoms = Table[Unique["spe$"], Length[speObjects]];
      polynomial = Expand[
        expanded /. Thread[speObjects -> atoms]
      ];
      If[! PolynomialQ[polynomial, atoms],
        Message[DimensionalShift::numerator, integrand];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      coefficientRules = CoefficientRules[polynomial, atoms];
      prepared = CheckAbort[
        FeynCalc`FCFeynmanPrepare[base, topology],
        $Failed
      ];
      If[! MatchQ[prepared, {_, _, _, _, _, _, _, _}],
        Message[DimensionalShift::shift, "FCFeynmanPrepare"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      powers = prepared[[3]];
      matrix = prepared[[4]];
      If[exactZeroQ[Det[matrix]],
        Message[DimensionalShift::shift, "singular loop matrix"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      parameters = powers[[All, 1]];
      positions = topologyPropagatorIndex[
        #[[2]],
        topology,
        loopMomenta
      ] & /@ powers;
      If[
        ! FreeQ[positions, $Failed] ||
          Length[positions] =!= Length[parameters] ||
          ! DuplicateFreeQ[positions] ||
          ! AllTrue[
            positions,
            IntegerQ[#] && 1 <= # <= Length[base[[2]]] &
          ],
        Message[DimensionalShift::shift, "parameter mapping"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      covariance = Adjugate[matrix]/2;
      gramMoment = dimensionalShiftGramMomentFunction[
        covariance,
        dimension - 4
      ];
      spePair[FeynCalc`SPE[a_, b_]] := {
        First @ FirstPosition[loopMomenta, a],
        First @ FirstPosition[loopMomenta, b]
      };
      spePair[FeynCalc`SPE[a_]] := With[
        {index = First @ FirstPosition[loopMomenta, a]},
        {index, index}
      ];
      oneMonomial[atomPowers_List -> coefficient_] := Module[
        {rank, bilinears, moment, shifted},
        rank = Total[atomPowers];
        bilinears = Flatten[
          MapThread[
            ConstantArray[spePair[#1], #2] &,
            {speObjects, atomPowers}
          ],
          1
        ];
        moment = gramMoment[bilinears];
        If[moment === $Failed, Return[$Failed]];
        shifted = dimensionalShiftParameterPolynomial[
          moment,
          parameters,
          positions,
          base
        ];
        shifted = dimensionalShiftReduceNumerator[
          coefficient,
          shifted,
          topology,
          dimension,
          dimension + 2 rank,
          loopMomenta,
          rulesToGLI,
          cutIndices,
          certifiedPhysicalVectors
        ];
        If[shifted === $Failed, Return[$Failed]];
        shifted = dimensionalShiftRaiseToD[
          shifted,
          topology,
          rank,
          dimension,
          cutIndices
        ];
        If[shifted === $Failed, Return[$Failed]];
        shifted
      ];
      result = Total[oneMonomial /@ coefficientRules]
    ];

    If[result === $Failed || ! FreeQ[result, $Failed],
      Message[DimensionalShift::shift, "Tarasov recurrence"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    unresolved = DeleteDuplicates @ Cases[
      result,
      object : HoldPattern[
        (FeynCalc`SP | FeynCalc`SPD | FeynCalc`SPE)[___]
      ] /; ! FreeQ[object, Alternatives @@ loopMomenta],
      {0, Infinity}
    ];
    If[unresolved =!= {} || ! FreeQ[result, FeynCalc`SPE],
      Message[DimensionalShift::numerator, unresolved];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result = dimensionalShiftPreserveCuts[result, cutIndices];
    If[result === $Failed,
      Message[DimensionalShift::shift, "noninteger cut index"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    parts = linearIntegralSum[result];
    diagnostics = If[
      FailureQ[parts],
      <|"SparseFailure" -> parts|>,
      <|
        "RemainderZero" -> exactZeroQ[parts["Remainder"]],
        "LoopDependentCoefficientCount" -> Count[
          Values[parts["Terms"]],
          coefficient_ /; ! FreeQ[
            coefficient,
            Alternatives @@ loopMomenta
          ]
        ],
        "Exact" -> exactDataQ[parts]
      |>
    ];
    If[
      FailureQ[parts] ||
        ! exactZeroQ[parts["Remainder"]] ||
        ! FreeQ[Values[parts["Terms"]], Alternatives @@ loopMomenta] ||
        ! exactDataQ[parts],
      Message[
        DimensionalShift::numerator,
        diagnostics
      ];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    parts = linearDropZeros[parts];
    If[parts["Terms"] === <||>, 0, linearToExpression[parts]]
  ],
  $dimensionalShiftFailure
];

DimensionalShift[
    integrand_,
    families : {__Association},
    loopMomenta_List
  ] := Module[
  {shiftFamily, shifted, sparse, result, masters, size},

  If[! AllTrue[
      families,
      KeyExistsQ[#, "Propagators"] &&
        MatchQ[Lookup[#, "Topology", Missing[]], _FeynCalc`FCTopology] &
    ],
    Message[DimensionalShift::families, families];
    Return[$Failed]
  ];

  shiftFamily[family_Association] := DimensionalShift[
    integrand,
    family["Propagators"],
    loopMomenta,
    family["Topology"],
    Lookup[
      Lookup[family, "AnalyticContext", <||>],
      "SetEvanescentZero",
      family["Topology"][[4]]
    ]
  ];

  shifted = shiftFamily /@ families;
  If[MemberQ[shifted, $Failed], Return[$Failed]];
  sparse = linearAdd[linearIntegralSum /@ shifted];
  If[FailureQ[sparse],
    Message[DimensionalShift::families];
    Return[$Failed]
  ];
  sparse = linearDropZeros[sparse];
  result = linearToExpression[sparse];
  masters = Keys[sparse["Terms"]];
  size = Round[ByteCount[result]/1024., 0.01];
  Print @ Grid[
    {{"GLI terms", "Size (kB)"}, {Length[masters], size}},
    Frame -> All
  ];
  result
];

DimensionalShift[integrand_, {}, {}] := Module[{size},
  size = Round[ByteCount[integrand]/1024., 0.01];
  Print @ Grid[
    {{"GLI terms", "Size (kB)"}, {0, size}},
    Frame -> All
  ];
  integrand
];

DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_List,
    topology_FeynCalc`FCTopology
  ] := DimensionalShift[
  integrand,
  propagators,
  loopMomenta,
  topology,
  topology[[4]]
];

DimensionalShift[integrand_, families_List, loopMomenta_List] := (
  Message[DimensionalShift::families, families];
  $Failed
);

DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_,
    topology_FeynCalc`FCTopology,
    physicalVectors_
  ] := (
  Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
  $Failed
);

DimensionalShift[integrand_, propagators_, loopMomenta_, topology_] := (
  Message[DimensionalShift::topology, topology];
  $Failed
);
