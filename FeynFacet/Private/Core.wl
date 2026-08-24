(* Shared exact algebra, basis definitions, and result metadata. *)

NA = Missing["NotApplicable"];

(* --- installation geometry ---------------------------------------- *)

(* The directory under which the package creates its OWN scratch
   workspaces (Kira projects, coefficient stores).  That is a property
   of the installation, not of the package's parent directory: a user
   whose result tree lives on one filesystem and whose scratch space
   lives on another sets Global`$FACETWorkspaceRoot before loading.  The
   default is the repository root, which is where every workspace this
   repository already contains was created (generality pass
   2026-08-23). *)
$feynFacetWorkspaceRoot = If[StringQ[Global`$FACETWorkspaceRoot],
  Global`$FACETWorkspaceRoot,
  $feynFacetRoot
];

(* Machine size.  The kernel ceiling 8 and the CPU-list width 16 used to
   be literals; they are MEASURED caps of this installation (the shared
   licence accepts 8 subkernels; the CPU list was written for a 16-core
   budget) and stay as caps, but the machine size behind them is now
   read from the system.  The two counts differ and both are needed:
   $ProcessorCount is what the Wolfram kernel will parallelize over (8
   on this box), while a taskset CPU list must name OPERATING-SYSTEM
   cpus (20 on this box), so the OS count is read where the kernel can
   see it and $ProcessorCount is the floor. *)
$facetKernelCeiling = 8;
$facetCPUCap = 16;

facetProcessorCount[] := facetProcessorCount[] = Module[{count = 0, text},
  If[FileExistsQ["/proc/cpuinfo"],
    text = Quiet @ Check[Import["/proc/cpuinfo", "Text"], $Failed];
    If[StringQ[text],
      count = Length @ StringCases[text,
        StartOfLine ~~ "processor" ~~ WhitespaceCharacter ... ~~ ":"]]];
  Max[count, $ProcessorCount, 1]
];

GlobalBasisGram = {
  {0, 1, 0, 0},
  {1, 0, 0, 0},
  {0, 0, -1, 0},
  {0, 0, 0, -1}
};

globalBasis = Missing["NotSet"];
internalSetEvanescentZero = Missing["NotSet"];

facetKernelCount[requested_: Automatic, workload_: Infinity] := Module[
  {environment, ceiling, count},
  environment = Environment["FACET_KERNEL_COUNT"];
  ceiling = Which[
    ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
    StringQ[environment] && StringLength[environment] > 0 &&
        IntegerQ[Quiet[Check[ToExpression[environment], $Failed]]] &&
        ToExpression[environment] > 0,
      ToExpression[environment],
    True, $facetKernelCeiling
  ];
  ceiling = Min[$facetKernelCeiling, Max[1, $ProcessorCount], ceiling];
  count = If[IntegerQ[requested] && requested > 0,
    Min[requested, ceiling], ceiling];
  If[IntegerQ[workload] && workload > 0, Min[count, workload], count]
];

facetCPUList[] := Module[
  {value = Environment["FACET_CPU_LIST"], width, fallback, parts, cpus},
  width = Min[$facetCPUCap, facetProcessorCount[]];
  fallback = StringRiffle[ToString /@ Range[0, width - 1], ","];
  If[! StringQ[value] ||
      ! StringMatchQ[value,
        RegularExpression["[0-9]+(?:[-,][0-9]+)*"]],
    Return[fallback]];
  parts = StringSplit[value, ","];
  cpus = Flatten[parts /. part_String :>
      If[StringContainsQ[part, "-"],
        With[{bounds = ToExpression /@ StringSplit[part, "-"]},
          If[bounds[[1]] <= bounds[[2]], Range @@ bounds, {}]],
        {ToExpression[part]}]];
  cpus = Take[DeleteDuplicates[cpus], UpTo[width]];
  If[cpus === {}, fallback, StringRiffle[ToString /@ cpus, ","]]
];

resultHeader[format_, version_Integer] := <|
  "Format" -> format,
  "FormatVersion" -> version,
  "Created" -> DateString[{"ISODate", "T", "Time"}]
|>;

resultContext[data_Association] := KeyTake[
  data,
  {"CardName", "ResultDirectory", "Pairs", "Setup", "AnalyticContext"}
];

reductionFingerprint[payload_] := Hash[payload, "SHA256", "HexString"];

artifactHeaderQ[data_, format_String, version_Integer] :=
  AssociationQ[data] &&
    Lookup[data, "Format", None] === format &&
    Lookup[data, "FormatVersion", None] === version;

(* The regulator a context is written in: its own "Regulator" entry when
   it carries one, the package symbol otherwise.  A context that names no
   regulator is read in the package's own, which is what every context
   this repository has stored does (generality pass 2026-08-23). *)
analyticContextRegulator[context_] := With[
  {declared = Lookup[context, "Regulator", Automatic]},
  If[MatchQ[declared, _Symbol] && declared =!= Automatic,
    declared, $feynFacetEpsilon]
];

(* The dimension rule is validated by SHAPE, not by identity with the
   package global.  What the package actually requires of a dimension
   rule is D -> a - 2 regulator with an INTEGER a and a SYMBOL
   regulator: that is the form every dimensional shift, expansion and
   pole-counting rule here is written for.  Testing identity with
   $dimensionRule additionally demanded a = 4 and the one global symbol
   Global`Epsilon, which is a property of this front end and not of the
   algebra; D -> 6 - 2 ep is an equally valid analytic context and used
   to be refused with no diagnosis. *)
analyticDimensionRuleQ[rule_, regulator_] := Module[{right},
  If[! MatchQ[rule, Rule[System`D, _]] || ! MatchQ[regulator, _Symbol],
    Return[False]];
  right = Last[rule];
  TrueQ[PolynomialQ[right, regulator]] &&
    TrueQ[Exponent[right, regulator] === 1] &&
    TrueQ[Coefficient[right, regulator, 1] === -2] &&
    IntegerQ[Coefficient[right, regulator, 0]]
];

analyticContextQ[context_] := Module[{required},
  required = {
    "Gamma5Scheme", "GlobalBasis", "GlobalBasisGram",
    "SetEvanescentZero", "SetMassZero", "SetDistributionZero",
    "CollinearRelations", "Assumptions", "CoefficientKinematics",
    "KinematicMassDimensions",
    "LoopDimension", "DimensionRule", "CutConvention",
    "DistributionConvention", "FeynFacetSourceHash", "Fingerprint"
  };
  AssociationQ[context] &&
    ContainsAll[Keys[context], required] &&
    (* the front end declares BMHV and nothing else: the evanescent
       bookkeeping downstream is written for that scheme *)
    context["Gamma5Scheme"] === "BMHV" &&
    analyticDimensionRuleQ[context["DimensionRule"],
      analyticContextRegulator[context]] &&
    StringQ[context["FeynFacetSourceHash"]] &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context]
];


DeclareScalar[scalars_List] := Module[{pieces},
  pieces = DeleteDuplicates @ Cases[
    scalars,
    x_ /; ! ListQ[Unevaluated[x]] &&
      ! MatchQ[x, _Integer | _Rational] &&
      ! TrueQ[x === 0],
    {1, Infinity},
    Heads -> False
  ];
  Scan[(FeynCalc`DataType[#, FeynCalc`FCVariable] = True) &, pieces];
  scalars
];

DeclareScalar[scalar_] := First[DeclareScalar[{scalar}]];

BuildBasis::length = "Expected four basis vectors, but received `1`.";
BuildBasis::relation = "Basis relations failed: `1`.";


BuildBasis[basis_List, assumptions_: True] := Module[
  {heads, expected, actual, bad},

  If[Length[basis] =!= 4,
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  expected = {
    GlobalBasisGram,
    GlobalBasisGram,
    ConstantArray[0, {4, 4}]
  };
  actual = FullSimplify[
    Table[
      FeynCalc`ExpandScalarProduct[
        heads[[kind]][basis[[i]], basis[[j]]]
      ],
      {kind, 3}, {i, 4}, {j, 4}
    ],
    Assumptions -> assumptions
  ];
  bad = Position[MapThread[SameQ, {actual, expected}, 3], False];

  If[bad =!= {},
    Message[
      BuildBasis::relation,
      Function[pos, {
        heads[[pos[[1]]]],
        basis[[pos[[2]]]],
        basis[[pos[[3]]]],
        expected[[Sequence @@ pos]],
        actual[[Sequence @@ pos]]
      }] /@ bad
    ];
    Return[$Failed]
  ];

  basis
];

BuildBasis[basis_, assumptions_: True] := (
  Message[BuildBasis::length, basis];
  $Failed
);


Build4Vec::arguments =
  "Expected coordinate and basis lists of equal length, but received `1` and `2`.";

Build4Vec[coordinates_List, basis_List] /;
    Length[coordinates] === Length[basis] := (
  DeclareScalar[coordinates];
  Total[coordinates basis]
);

Build4Vec[coordinates_, basis_] := (
  Message[Build4Vec::arguments, coordinates, basis];
  $Failed
);


declareGlobalBasis[basis_List] := Do[
  With[
    {p = basis[[i]], q = basis[[j]], value = GlobalBasisGram[[i, j]]},
    FeynCalc`SP[p, q] = value;
    FeynCalc`SPD[p, q] = value;
    FeynCalc`SPE[p, q] = 0
  ],
  {i, 4}, {j, i, 4}
];

BuildGlobalBasis[basis_List] := Module[
  {heads, oldDefinitions, oldBasis, oldEvanescent, result},
  If[
    Length[basis] =!= 4 ||
      ! AllTrue[basis, MatchQ[#, _Symbol] &] ||
      ! DuplicateFreeQ[basis],
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  oldDefinitions = DownValues /@ heads;
  oldBasis = globalBasis;
  oldEvanescent = internalSetEvanescentZero;
  declareGlobalBasis[basis];
  result = BuildBasis[basis];
  If[result === $Failed,
    MapThread[(DownValues[#1] = #2) &, {heads, oldDefinitions}];
    globalBasis = oldBasis;
    internalSetEvanescentZero = oldEvanescent;
    Return[$Failed]
  ];
  globalBasis = basis;
  internalSetEvanescentZero = basis[[{2, 1, 3, 4}]];
  result
];

BuildGlobalBasis[basis_] := (
  Message[BuildBasis::length, basis];
  $Failed
);


SimplifyAssum[expr_, assumptions_: True] :=
  Simplify[expr, Assumptions -> assumptions];

FullSimplifyAssum[expr_, assumptions_: True] :=
  FullSimplify[expr, Assumptions -> assumptions];


ToFeynFacetForm::convert =
  "FeynCalc could not convert the expression to its external form.";

ToFeynFacetForm::internal =
  "Internal FeynCalc scalar-product objects remain after conversion: `1`.";

internalScalarProductObjects[expr_] := DeleteDuplicates[
  Cases[
    HoldComplete[expr],
    object : HoldPattern[
      (FeynCalc`Pair | FeynCalc`CartesianPair | FeynCalc`TemporalPair)[___]
    ] :> object,
    Infinity
  ],
  SameTest -> SameQ
];

feynFacetFormQ[expr_] := internalScalarProductObjects[expr] === {};

ToFeynFacetForm[expr_] := Module[{converted, remaining},
  converted = Check[FeynCalc`FCE[expr], $Failed];
  If[converted === $Failed,
    Message[ToFeynFacetForm::convert];
    Return[$Failed]
  ];
  remaining = internalScalarProductObjects[converted];
  If[! feynFacetFormQ[converted],
    Message[ToFeynFacetForm::internal, Take[remaining, UpTo[3]]];
    Return[$Failed]
  ];
  converted
];


termList[expr_] := With[{expanded = Expand[expr]},
  If[Head[expanded] === Plus, List @@ expanded, {expanded}]
];

exactZeroQ[expr_] := TrueQ[
  Quiet[Cancel[Together[Expand[expr]]]] === 0
];

exactRationalQ[value_] := MatchQ[value, _Integer | _Rational];

inexactNumberQ[value_] := NumberQ[value] && Precision[value] =!= Infinity;

exactDataQ[expression_] := FreeQ[
  HoldComplete[expression],
  value_ /; inexactNumberQ[value]
];

remainingDeclaredMomenta[expression_, momenta_List] := Select[
  DeleteDuplicates[momenta, SameTest -> SameQ],
  ! FreeQ[HoldComplete[expression], #] &
];

protectedAnalyticObjects[expression_] := Module[{walk},
  walk[value_?AtomQ] := {};
  walk[value_Plus] := Flatten[walk /@ List @@ value];
  walk[value_Times] := Flatten[walk /@ List @@ value];
  walk[Power[base_, power_Integer]] := walk[base];
  walk[value_] := {value};
  DeleteDuplicates[walk[expression], SameQ]
];

atomizeProtectedAnalyticObjects[expression_] := Module[
  {protected, atoms},
  protected = protectedAnalyticObjects[expression];
  atoms = Table[Unique["analytic$"], Length[protected]];
  <|
    "Expression" -> expression,
    "Atoms" -> atoms,
    "Forward" -> Dispatch[Thread[protected -> atoms]],
    "Backward" -> Dispatch[Thread[atoms -> protected]]
  |>
];

topLevelFactors[expr_] := If[Head[expr] === Times, List @@ expr, {expr}];

commonFactorMultiset[lists : {__List}] := Module[{commonCounts},
  commonCounts = Merge[KeyIntersection[Counts /@ lists], Min];
  Flatten @ KeyValueMap[ConstantArray[#1, #2] &, commonCounts]
];

removeFactorOnce[list_List, factor_] := DeleteCases[list, factor, {1}, 1];

removeFactorMultiset[list_List, factors_List] :=
  Fold[removeFactorOnce, list, factors];

structuralCommonFactor[expressions_List] := Module[
  {factorLists, shared},
  If[expressions === {}, Return[{1, {}}]];
  factorLists = topLevelFactors /@ expressions;
  shared = commonFactorMultiset[factorLists];
  {
    Times @@ shared,
    Times @@@ (removeFactorMultiset[#, shared] & /@ factorLists)
  }
];


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

linearDropZeros[data_?linearIntegralSumQ] := <|
  "Terms" -> canonicalizeLinearTerms @
    Select[data["Terms"], ! exactZeroQ[#] &],
  "Remainder" -> If[exactZeroQ[data["Remainder"]], 0, data["Remainder"]]
|>;

linearCanonicalize[data_?linearIntegralSumStructureQ] := <|
  "Terms" -> canonicalizeLinearTerms[data["Terms"]],
  "Remainder" -> data["Remainder"]
|>;

linearMapCoefficients[data_?linearIntegralSumStructureQ, function_] := <|
  "Terms" -> Map[function, data["Terms"]],
  "Remainder" -> function[data["Remainder"]]
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

compileSparseReduction[
    targets_List,
    rules_,
    coefficientFunction_: Identity
  ] := Module[{images},
  images = AssociationMap[
    Function[target,
      With[{image = linearIntegralSum[Replace[target, rules, {0}]]},
        If[FailureQ[image], image,
          linearMapCoefficients[image, coefficientFunction]
        ]
      ]
    ],
    targets
  ];
  If[AnyTrue[Values[images], FailureQ],
    Failure["InvalidReductionImage", <||>],
    images
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

linearApplyReduction[data_?linearIntegralSumQ, rules_, reverseRules_] := Module[
  {reduction},
  reduction = compileSparseReduction[
    Keys[data["Terms"]],
    Dispatch[(rules /. reverseRules)]
  ];
  If[FailureQ[reduction], reduction,
    linearComposeReduction[data /. reverseRules, reduction]
  ]
];
