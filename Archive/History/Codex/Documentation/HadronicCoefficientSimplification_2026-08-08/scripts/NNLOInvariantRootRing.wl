(* Exact positive-invariant-root arithmetic for NNLO hard coefficients. *)

ClearAll[
  facetRs,
  nnloInvariantRootExactDataQ,
  nnloLiftablePositiveInvariantPowerQ,
  nnloInvariantRootSourceGrammarQ,
  nnloInvariantRootRationalGrammarQ,
  nnloInvariantRootLift,
  nnloInvariantRootPolynomialRestore,
  nnloInvariantRootEvenOddParts,
  nnloInvariantRootExactZeroQ,
  nnloInvariantRootDescendReduced,
  nnloInvariantRootDescend,
  nnloInvariantRootRestore
];

nnloInvariantRootExactDataQ[expression_] := FreeQ[expression, _Real];

nnloLiftablePositiveInvariantPowerQ[
    Power[base_, exponent_Rational],
    invariant_Symbol
  ] := SameQ[Unevaluated[base], invariant] && IntegerQ[2 exponent];

nnloLiftablePositiveInvariantPowerQ[
    Power[Power[base_, n_Integer], exponent_Rational],
    invariant_Symbol
  ] := SameQ[Unevaluated[base], invariant] &&
    IntegerQ[2 n exponent];

nnloLiftablePositiveInvariantPowerQ[_, _Symbol] := False;

nnloInvariantRootSourceGrammarQ[
    expression_,
    invariant_Symbol
  ] := Module[{walk},
  walk[node_] := Which[
    FreeQ[node, invariant], True,
    SameQ[Unevaluated[node], invariant], True,
    MatchQ[Unevaluated[node], _Plus | _Times],
      AllTrue[List @@ node, walk],
    Head[Unevaluated[node]] === Power,
      If[
        IntegerQ[node[[2]]],
        walk[node[[1]]],
        nnloLiftablePositiveInvariantPowerQ[node, invariant]
      ],
    True, False
  ];
  TrueQ[walk[expression]]
];

nnloInvariantRootRationalGrammarQ[
    expression_,
    root_Symbol : facetRs
  ] := Module[{walk},
  walk[node_] := Which[
    FreeQ[node, root], True,
    SameQ[Unevaluated[node], root], True,
    MatchQ[Unevaluated[node], _Plus | _Times],
      AllTrue[List @@ node, walk],
    Head[Unevaluated[node]] === Power && IntegerQ[node[[2]]],
      walk[node[[1]]],
    True, False
  ];
  TrueQ[walk[expression]]
];

nnloInvariantRootLift[
    expression_,
    invariant_Symbol : s,
    root_Symbol : facetRs
  ] := Module[{lifted},
  If[
    ! nnloInvariantRootExactDataQ[expression] ||
      ! FreeQ[expression, root] ||
      ! nnloInvariantRootSourceGrammarQ[expression, invariant],
    Return[$Failed]
  ];
  lifted = expression /. {
    HoldPattern[Power[Power[base_, n_Integer], exponent_Rational]] /;
        SameQ[Unevaluated[base], invariant] &&
          ! IntegerQ[exponent] && IntegerQ[2 n exponent] :>
      root^(2 n exponent),
    HoldPattern[Power[base_, exponent_Rational]] /;
        SameQ[Unevaluated[base], invariant] &&
          ! IntegerQ[exponent] && IntegerQ[2 exponent] :>
      root^(2 exponent),
    invariant -> root^2
  };
  If[
    FreeQ[lifted, invariant] &&
      nnloInvariantRootRationalGrammarQ[lifted, root],
    lifted,
    $Failed
  ]
];

nnloInvariantRootPolynomialRestore[
  polynomial_,
    invariant_Symbol : s,
    root_Symbol : facetRs
  ] := Module[{direct, rules},
  direct = polynomial /. HoldPattern[Power[base_, power_Integer?EvenQ]] /;
      SameQ[Unevaluated[base], root] :>
    invariant^(power/2);
  If[FreeQ[direct, root], Return[direct]];
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  If[! AllTrue[rules, EvenQ[First[First[#]]] &], Return[$Failed]];
  Total[(Last[#] invariant^(First[First[#]]/2)) & /@ rules]
];

nnloInvariantRootEvenOddParts[
    polynomial_,
    invariant_Symbol : s,
    root_Symbol : facetRs
  ] := Module[{rules},
  If[! PolynomialQ[polynomial, root], Return[$Failed]];
  rules = CoefficientRules[polynomial, {root}];
  <|
    "Even" -> Total @ Cases[
      rules,
      Rule[{power_Integer?EvenQ}, coefficient_] :>
        coefficient invariant^(power/2)
    ],
    "Odd" -> Total @ Cases[
      rules,
      Rule[{power_Integer?OddQ}, coefficient_] :>
        coefficient invariant^((power - 1)/2)
    ]
  |>
];

nnloInvariantRootExactZeroQ[expression_, timeLimit_: 120] :=
  TimeConstrained[
    Quiet @ CheckAbort[
      Check[TrueQ[Cancel[Together[expression]] === 0], False],
      False
    ],
    timeLimit,
    $TimedOut
  ];

nnloInvariantRootDescendReduced[
    expression_,
    invariant_Symbol : s,
    root_Symbol : facetRs,
    timeLimit_: 120
  ] := Module[
  {
    rational, numerator, denominator, restoredNumerator,
    restoredDenominator, numeratorParts, denominatorParts,
    pe, po, qe, qo, invariantStatus, qeStatus, qoStatus, result
  },
  If[
    ! nnloInvariantRootExactDataQ[expression] ||
      ! nnloInvariantRootRationalGrammarQ[expression, root],
    Return[$Failed]
  ];
  rational = expression;
  numerator = Numerator[rational];
  denominator = Denominator[rational];

  restoredNumerator = nnloInvariantRootPolynomialRestore[
    numerator, invariant, root
  ];
  restoredDenominator = nnloInvariantRootPolynomialRestore[
    denominator, invariant, root
  ];
  If[
    FreeQ[{restoredNumerator, restoredDenominator}, $Failed],
    result = TimeConstrained[
      Quiet @ CheckAbort[
        Check[Cancel[restoredNumerator/restoredDenominator], $Failed],
        $Failed
      ],
      timeLimit,
      $TimedOut
    ];
    Return[result]
  ];

  numeratorParts = nnloInvariantRootEvenOddParts[
    numerator, invariant, root
  ];
  denominatorParts = nnloInvariantRootEvenOddParts[
    denominator, invariant, root
  ];
  If[
    MemberQ[{numeratorParts, denominatorParts}, $Failed],
    Return[$Failed]
  ];
  {pe, po} = Lookup[numeratorParts, {"Even", "Odd"}];
  {qe, qo} = Lookup[denominatorParts, {"Even", "Odd"}];
  invariantStatus = nnloInvariantRootExactZeroQ[
    pe qo - po qe,
    timeLimit
  ];
  If[invariantStatus =!= True, Return[invariantStatus /. False -> $Failed]];

  qeStatus = nnloInvariantRootExactZeroQ[qe, timeLimit];
  result = Which[
    qeStatus === False, pe/qe,
    qeStatus === True,
      qoStatus = nnloInvariantRootExactZeroQ[qo, timeLimit];
      Which[
        qoStatus === False, po/qo,
        qoStatus === $TimedOut, Return[$TimedOut],
        True, Return[$Failed]
      ],
    qeStatus === $TimedOut, Return[$TimedOut],
    True, Return[$Failed]
  ];
  result = TimeConstrained[
    Quiet @ CheckAbort[Check[Cancel[result], $Failed], $Failed],
    timeLimit,
    $TimedOut
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, result] ||
      ! FreeQ[result, root] ||
      ! nnloInvariantRootExactDataQ[result],
    If[MemberQ[{$Failed, $TimedOut}, result], result, $Failed],
    result
  ]
];

nnloInvariantRootDescend[
    expression_,
    invariant_Symbol : s,
    root_Symbol : facetRs,
    timeLimit_: 120
  ] := Module[{rational},
  rational = TimeConstrained[
    Quiet @ CheckAbort[Check[Cancel[Together[expression]], $Failed], $Failed],
    timeLimit,
    $TimedOut
  ];
  If[
    MemberQ[{$Failed, $TimedOut}, rational],
    rational,
    nnloInvariantRootDescendReduced[
      rational, invariant, root, timeLimit
    ]
  ]
];

nnloInvariantRootRestore[expression_, timeLimit_: 120] :=
  nnloInvariantRootDescend[expression, s, facetRs, timeLimit];
