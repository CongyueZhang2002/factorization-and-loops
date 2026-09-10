(* Formal linear combinations of master integrals and reduction rules. *)
topLevelFactors[expr_] := If[Head[expr] === Times, List @@ expr, {expr}];

commonFactorMultiset[lists : {__List}] := Module[{commonCounts},
  commonCounts = Merge[KeyIntersection[Counts /@ lists], Min];
  Flatten @ KeyValueMap[ConstantArray[#1, #2] &, commonCounts]
];

removeFactorOnce[list_List, factor_] := DeleteCases[list, factor, {1}, 1];


CommonFactorSafe[expr_, loopMomenta_List : {}] := Module[
  {
    external, protected, atoms, toAtoms, fromAtoms,
    factored, factors, prefactor
  },

  If[TrueQ[expr === 0], Return[{1, 0}]];

  external = ToFeynFacetForm[expr];
  If[external === $Failed, Return[$Failed]];
  protected = DeleteDuplicates @ Cases[
    external,
    object_ /; With[
      {head = Head[Unevaluated[object]]},
      MemberQ[
        {
          FeynCalc`FAD, FeynCalc`SFAD, FeynCalc`CFAD,
          FeynCalc`GFAD, FeynCalc`PD, FeynCalc`GLI,
          FeynFacet`dD, dFraction, Cut
        },
        head
      ] || (
        MemberQ[
          {
            FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE,
            FeynCalc`CSP, FeynCalc`CSPD, FeynCalc`CSPE
          },
          head
        ] &&
        loopMomenta =!= {} &&
        ! FreeQ[Unevaluated[object], Alternatives @@ loopMomenta]
      )
    ] :> object,
    Infinity
  ];
  If[protected === {},
    factors = If[
      Head[external] === Times,
      List @@ external,
      {external}
    ];
    prefactor = Times @@ Select[factors, Head[#] =!= Plus &];
    Return[{
      prefactor,
      Times @@ Select[factors, Head[#] === Plus &]
    }]
  ];

  atoms = Table[Unique["protected$"], Length[protected]];
  toAtoms = Thread[protected -> atoms];
  fromAtoms = Thread[atoms -> protected];
  factored = Factor[external /. toAtoms];
  factors = If[Head[factored] === Times, List @@ factored, {factored}];
  prefactor = Times @@ Select[
    factors,
    FreeQ[#, Alternatives @@ atoms] &
  ];

  {
    Factor[prefactor] /. fromAtoms,
    Factor[factored/prefactor] /. fromAtoms
  }
];

CommonFactorSafe::momenta =
  "Expected the loop momenta as a list, but received `1`.";

CommonFactorSafe[expr_, loopMomenta_] := (
  Message[CommonFactorSafe::momenta, loopMomenta];
  $Failed
);


linearIntegralSumPass[expression_] := Module[{walk, raw},
  walk[part_] := Module[{pieces, dependent, position, scalar, parsed},
    Which[
      FreeQ[part, _FeynCalc`GLI],
        {{}, part},

      MatchQ[part, _FeynCalc`GLI],
        {{part -> 1}, 0},

      Head[part] === Plus,
        pieces = walk /@ (List @@ part);
        If[AnyTrue[pieces, FailureQ],
          SelectFirst[pieces, FailureQ],
          {Flatten[pieces[[All, 1]], 1], Total[pieces[[All, 2]]]}
        ],

      Head[part] === Times,
        pieces = List @@ part;
        dependent = ! FreeQ[#, _FeynCalc`GLI] & /@ pieces;
        If[Count[dependent, True] =!= 1,
          Return[Failure["NonlinearIntegralTerm", <|"Term" -> part|>]]
        ];
        position = First @ FirstPosition[dependent, True];
        scalar = Times @@ Delete[pieces, position];
        parsed = walk[pieces[[position]]];
        If[FailureQ[parsed],
          parsed,
          {
            (#1 -> scalar #2) & @@@ parsed[[1]],
            scalar parsed[[2]]
          }
        ],

      True,
        Failure["NonlinearIntegralTerm", <|"Term" -> part|>]
    ]
  ];

  raw = walk[expression];
  If[FailureQ[raw], Return[raw]];
  <|
    "Terms" -> If[
      raw[[1]] === {},
      <||>,
      canonicalizeLinearTerms @ Merge[raw[[1]], Total]
    ],
    "Remainder" -> raw[[2]]
  |>
];

linearIntegralSum[expression_] := Module[{result},
  result = linearIntegralSumPass[expression];
  If[AssociationQ[result], result,
    Failure["NonlinearIntegralSum", <|"Expression" -> expression|>]
  ]
];

linearIntegralSumStructureQ[data_] := AssociationQ[data] &&
  AssociationQ[Lookup[data, "Terms", None]] &&
  AllTrue[Keys[data["Terms"]], MatchQ[#, _FeynCalc`GLI] &];

linearIntegralSumQ[data_] := linearIntegralSumStructureQ[data] &&
  FreeQ[Values[data["Terms"]], _FeynCalc`GLI] &&
  FreeQ[Lookup[data, "Remainder", 0], _FeynCalc`GLI];

canonicalizeLinearTerms[terms_Association] := KeySortBy[
  terms,
  ToString[InputForm[#]] &
];

linearToExpression[data_?linearIntegralSumQ] :=
  Total[KeyValueMap[#1 #2 &, data["Terms"]]] + data["Remainder"];

linearDropZeros[data_?linearIntegralSumQ, zeroTest_:exactZeroQ] := <|
  "Terms" -> canonicalizeLinearTerms @
    Select[data["Terms"], ! TrueQ[zeroTest[#]] &],
  "Remainder" -> If[TrueQ[zeroTest[data["Remainder"]]], 0, data["Remainder"]]
|>;

linearCanonicalize[data_?linearIntegralSumStructureQ] := <|
  "Terms" -> canonicalizeLinearTerms[data["Terms"]],
  "Remainder" -> data["Remainder"]
|>;

linearScale[data_?linearIntegralSumQ, factor_] :=
  linearCanonicalize @ <|
    "Terms" -> Map[factor # &, data["Terms"]],
    "Remainder" -> factor data["Remainder"]
  |>;

linearAdd[parts_List] := Module[{result},
  If[! AllTrue[parts, linearIntegralSumQ],
    Return[Failure["InvalidLinearIntegralSum", <||>]]
  ];
  result = linearCanonicalize @ <|
    "Terms" -> If[
      parts === {},
      <||>,
      Merge[Lookup[parts, "Terms"], Total]
    ],
    "Remainder" -> Total[Lookup[parts, "Remainder", 0]]
  |>;
  If[linearIntegralSumQ[result], result,
    Failure["InvalidLinearIntegralSum", <||>]
  ]
];

linearMapIntegrals[data_?linearIntegralSumQ, rules_] := Module[{terms, result},
  terms = KeyValueMap[(Replace[#1, rules, {0}] -> #2) &, data["Terms"]];
  If[! AllTrue[First /@ terms, MatchQ[#, _FeynCalc`GLI] &],
    Return[Failure["InvalidIntegralMap", <||>]]
  ];
  result = linearCanonicalize @ <|
    "Terms" -> If[terms === {}, <||>, Merge[terms, Total]],
    "Remainder" -> data["Remainder"]
  |>;
  If[linearIntegralSumQ[result], result,
    Failure["InvalidIntegralMap", <||>]
  ]
];

linearComposeReduction[
    data_?linearIntegralSumStructureQ,
    reduction_Association
  ] := Module[
  {
    missing, terms, remainder, result, chunks,
    chunkTerms, chunkRemainder
  },

  missing = Select[
    Keys[data["Terms"]],
    ! KeyExistsQ[reduction, #] &
  ];
  If[missing =!= {},
    Return[Failure["MissingReductionTarget", <|"Targets" -> missing|>]]
  ];

  terms = <||>;
  remainder = data["Remainder"];
  chunks = Partition[Keys[data["Terms"]], UpTo[512]];
  Scan[
    Function[chunk,
      chunkTerms = Merge[
        Function[target,
          With[{coefficient = data["Terms"][target]},
            Map[coefficient # &, reduction[target]["Terms"]]
          ]
        ] /@ chunk,
        Total
      ];
      KeyValueMap[
        Function[{integral, coefficient},
          AssociateTo[
            terms,
            integral -> (Lookup[terms, integral, 0] + coefficient)
          ]
        ],
        chunkTerms
      ];
      chunkRemainder = Total[
        Function[target,
          data["Terms"][target] reduction[target]["Remainder"]
        ] /@ chunk
      ];
      remainder += chunkRemainder
    ],
    chunks
  ];
  result = <|
    "Terms" -> canonicalizeLinearTerms[terms],
    "Remainder" -> remainder
  |>;
  If[linearIntegralSumStructureQ[result], result,
    Failure["InvalidLinearIntegralSum", <||>]
  ]
];

