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

linearDropZeros[data_?linearIntegralSumQ] := <|
  "Terms" -> canonicalizeLinearTerms @
    Select[data["Terms"], ! exactZeroQ[#] &],
  "Remainder" -> If[exactZeroQ[data["Remainder"]], 0, data["Remainder"]]
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


(* ================================================================== *)
(*  Layer-neutral helpers moved DOWN into Core (layer pass 2026-09-02) *)
(*                                                                     *)
(*  Every block below is a verbatim move; the names keep their         *)
(*  historical prefixes.  Origins and reasons:                         *)
(*    FamilyArtifactRead/Write  <- EpsForm/FamilyEpsForm.wl: read by    *)
(*      Infrastructure (TaskBroker), Geometry and Transport as well;    *)
(*    coefficient*Record         <- Reduction/CoefficientStore.wl:      *)
(*      length-prefixed binary record files, used by the Process        *)
(*      family registry (CanonicalFamilies.wl) and the store;           *)
(*    masterTransport* (regulator/variable resolution, the radical      *)
(*      zero tests, check level, exact-point zero test, chart-record    *)
(*      data and the chain-rule pullbacks) <- Transport/               *)
(*      MasterTransport.wl: called by EpsForm (FamilyEpsForm.wl,        *)
(*      FamilyRegulatorFactor.wl) and Geometry (TransportCharts.wl),    *)
(*      both of which load before Transport.  masterTransportZeroQ     *)
(*      keeps its word-aware branch; TransportWord is the public,       *)
(*      retired word head and is only matched as a pattern here.        *)
(* ================================================================== *)

(* public symbols: Clear, not ClearAll (FeynFacet.m defines their usage
   messages before this file loads) *)
(* Round 5 (2026-09-02, substructure ruling): the helpers listed in the
   banner above are now split by responsibility into
   Core/Artifacts/Artifacts.wl (the artifact reader/writer and the binary
   record I/O), Core/Algebra/Radicals.wl (the radical algebra) and
   Core/Charts/ChartData.wl (chart-record data and the chain-rule
   pullbacks); this file keeps the regulator/variable resolution, the word
   collector and the zero tests.  Each file clears only the symbols it
   defines. *)

ClearAll[
  $masterTransportRegulatorNames,
  $masterTransportZeroTimeLimit,
  masterTransportDefaultVariables,
  masterTransportDetectRegulator,
  masterTransportResolveVariables,
  masterTransportResolveRegulator,
  masterTransportNormalize,
  masterTransportWordFreeQ,
  masterTransportNormalizeWords,
  masterTransportCollect,
  masterTransportSimplifyZeroQ,
  masterTransportZeroQ,
  observableTransportZeroQ, observableTransportZeroMatrixQ,
  observableTransportBlockLowerQ,
  masterTransportZeroMatQ,
  masterTransportCheckLevel,
  masterTransportPointZeroQ
];

$masterTransportRegulatorNames = {"eps", "Eps", "epsilon", "Epsilon", "ep"};


(* Every symbolic zero test gets a budget.  Simplify on a 2F1 residual
   can run without bound, and a check that has not returned is neither a
   pass nor a failure -- it is a check that was not performed, and it
   must be reported as "Inconclusive" rather than hang the stage. *)
$masterTransportZeroTimeLimit = 120;


masterTransportDefaultVariables[] :=
  {Symbol["Global`v"], Symbol["Global`w"]};

masterTransportDetectRegulator[expr_, variables_List] := Module[{symbols},
  symbols = DeleteDuplicates @ Cases[
    expr,
    s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]],
    {0, Infinity},
    Heads -> True
  ];
  symbols = DeleteCases[symbols, Alternatives @@ variables];
  If[Length[symbols] === 1, First[symbols], $Failed]
];

masterTransportResolveVariables[value_] := Switch[value,
  Automatic, masterTransportDefaultVariables[],
  {_Symbol, __Symbol}, value,
  _, $Failed
];

masterTransportResolveRegulator[value_, expr_, variables_] := Switch[value,
  Automatic, masterTransportDetectRegulator[expr, variables],
  _Symbol, value,
  _, $Failed
];

(* The one place symbol identity changes.  Matching on SymbolName keeps a
   Global`eps system and a Global`Epsilon system on one code path, and it
   is applied to EVERY input before any backend package can load and
   claim those names for itself (trap P2). *)
masterTransportNormalize[expr_, regulator_Symbol, variables_List] :=
  Module[{names, rules},
    names = SymbolName /@ variables;
    rules = Join[
      {(s_Symbol /; MemberQ[$masterTransportRegulatorNames, SymbolName[s]] &&
          SymbolName[s] =!= SymbolName[regulator]) :> regulator},
      MapThread[
        Function[{nm, target},
          (s_Symbol /; SymbolName[s] === nm && s =!= target) :> target],
        {names, variables}]
    ];
    expr /. rules
  ];




masterTransportWordFreeQ[e_] := FreeQ[e, TransportWord];


(* Collect an expression by its transcendental monomial.  Returns
   <| wordMonomial -> rationalCoefficient |>, with key 1 for the purely
   rational part. *)
(* Word keys must be CANONICAL before anything is collected against
   them.  The indices are rational functions of the kinematics, and the
   same pole reaches the expression in more than one syntactic form
   (1/(1-4v) from one leg, -1/(4v-1) from another).  Collecting on the
   raw form puts equal words in different buckets, and a residual that
   is mathematically zero then survives as two nonvanishing
   coefficients -- an "inconclusive" verdict manufactured by
   bookkeeping rather than by mathematics. *)
masterTransportNormalizeWords[e_] :=
  e /. TransportWord[idx_List, z_] :>
    TransportWord[masterTransportRadicalNormalize[Together[#]] & /@ idx,
      Together[z]];


masterTransportCollect[e_] := Module[{ex, terms, res},
  ex = Expand[masterTransportNormalizeWords[e]];
  If[ex === 0, Return[<||>]];
  terms = If[Head[ex] === Plus, List @@ ex, {ex}];
  res = <||>;
  Do[
    Module[{factors, wordPart, coefficientPart},
      factors = If[Head[term] === Times, List @@ term, {term}];
      wordPart = Times @@ Select[factors, ! FreeQ[#, TransportWord] &];
      coefficientPart = Times @@ Select[factors, FreeQ[#, TransportWord] &];
      res[wordPart] = Lookup[res, wordPart, 0] + coefficientPart
    ],
    {term, terms}];
  res
];

(* Sound zero test.  Coefficient-wise vanishing PROVES the expression is
   zero.  It is not a decision procedure: Libra's words are not
   shuffle-reduced, so a nonzero coefficient list does not prove the
   expression is nonzero.  The verdict is therefore True or
   "Inconclusive", never a claim of nonvanishing.  Over an algebraic
   extension (radicals in the frozen variable) the coefficient test is
   the exact one above. *)
masterTransportSimplifyZeroQ[e_] :=
  TrueQ[Together[e] === 0] ||
  (masterTransportRadicalQ[e] && TrueQ[masterTransportRadicalZeroQ[e]]) ||
  TrueQ[TimeConstrained[Simplify[e], $masterTransportZeroTimeLimit, $Failed] === 0];

masterTransportZeroQ[e_] := Module[{collected, residual},
  If[e === 0, Return[True]];
  If[masterTransportWordFreeQ[e],
    Return[If[masterTransportSimplifyZeroQ[e], True, "Inconclusive"]]];
  collected = masterTransportCollect[e];
  residual = Select[Values[collected], ! TrueQ[Together[#] === 0] &];
  residual = Select[residual, ! masterTransportSimplifyZeroQ[#] &];
  If[residual === {}, True, "Inconclusive"]
];

masterTransportZeroMatQ[m_] :=
  AllTrue[Flatten[{m}], TrueQ[masterTransportZeroQ[#]] &];

(* Moved verbatim from Transport/Observable/ObservableTransport.wl (round 7,
   2026-09-02): the Boolean wrappers of masterTransportZeroQ and the
   block-lower-triangularity predicate; FamilyEpsForm.wl (EpsForm) and the
   observable transport both use them. *)
observableTransportZeroQ[x_] :=
  TrueQ[masterTransportZeroQ[x]];

observableTransportZeroMatrixQ[m_] :=
  AllTrue[Flatten[{Normal[m]}], observableTransportZeroQ];

observableTransportBlockLowerQ[matrices : {_, _}, ranges_List] := Module[
  {n = Length[First[matrices]]},
  If[! AllTrue[ranges, VectorQ[#, IntegerQ] &] ||
      Sort[Flatten[ranges]] =!= Range[n], Return[False]];
  AllTrue[
    Flatten[Table[
      If[i < j,
        {matrices[[1, ranges[[i]], ranges[[j]]]],
         matrices[[2, ranges[[i]], ranges[[j]]]]},
        {}],
      {i, Length[ranges]}, {j, Length[ranges]}]],
    observableTransportZeroMatrixQ
  ]
];


(* Check level (user decision 2026-08-22: checks stay separate from the
   calculation).  "Development": every identity exact (the default).
   "Production" (FACET_CHECK_LEVEL=Production): the identities that only
   guard the bookkeeping of an assembly -- curvature of the source and of
   the conjugated connection, per-block inverses, diagonal-equals-declared-
   form -- are evaluated EXACTLY AT RANDOM RATIONAL POINTS instead of as
   rational-function identities (a wrong matrix passes with probability
   ~ degree / 10^6 per point; two points are used), and the single exact
   statement is the family certificate made afterwards.  Measured on
   CF254 (dim 23, 2026-08-22): the exact identities were 446 s of a 626 s
   assembly; the conjugation itself 49 s. *)
masterTransportCheckLevel[requested_: Automatic] := Which[
  MemberQ[{"Production", "Development"}, requested], requested,
  Environment["FACET_CHECK_LEVEL"] === "Production", "Production",
  True, "Development"];

(* exact-rational evaluation of every entry at count random points; a
   point hitting a pole is replaced *)
masterTransportPointZeroQ[expr_, symbols_List, count_Integer: 2] := Module[
  {flat = Flatten[{expr}], tries = 0, done = 0, point, values},
  If[flat === {} || AllTrue[flat, TrueQ[# === 0] &], Return[True]];
  While[done < count && tries < 6 count,
    tries++;
    point = Thread[symbols -> RandomInteger[{3, 10^6}, Length[symbols]]/
      RandomInteger[{10^6, 10^7}, Length[symbols]]];
    (* Substitute first, then normalize the now-small exact numbers.
       Plain ==0 does not reduce relations among square roots and gave a
       false SourceSystemNotFlat on the multiquadratic CF303 subsystem. *)
    values = Quiet[Check[Together /@ (flat /. point), $Failed]];
    If[values === $Failed || ! FreeQ[values, ComplexInfinity | Indeterminate | DirectedInfinity],
      Continue[]];
    If[! AllTrue[values,
        TrueQ[# === 0] ||
          (masterTransportRadicalQ[#] &&
            TrueQ[masterTransportRadicalZeroQ[#]]) &], Return[False]];
    done++];
  done >= count];
