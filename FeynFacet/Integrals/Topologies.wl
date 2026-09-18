(* Cut-aware denominator parsing, partial fractions, and topology records. *)

(* Oriented cuts and exact denominator identities. *)

PartialFraction::loops =
  "Loop momenta must be given as a list, but received `1`.";

PartialFraction::cut =
  "Cut propagators must have the form Cut[SPD[q]] or Cut[SPD[q],direction], with direction equal to 1 or -1. Invalid objects: `1`.";

PartialFraction::cutorientation =
  "The same quadratic cut denominator was assigned incompatible positive-energy orientations: `1`.";

PartialFraction::nocut =
  "ApartFF produced no term retaining all required cut propagators `1`.";

PartialFraction::cutpower =
  "ApartFF produced an unsupported cut power `1` for cut momentum `2`.";

PartialFraction::collision =
  "The denominator core `1` occurs both as a Cut and as an ordinary propagator. This cannot be represented by one GLI index.";


momentumRelativeSign[q_, target_] := Which[
  exactZeroQ[q - target] && ! exactZeroQ[q + target], 1,
  exactZeroQ[q + target] && ! exactZeroQ[q - target], -1,
  True, 0
];

sameMomentumQ[q_, target_] :=
  MemberQ[{1, -1}, momentumRelativeSign[q, target]];

sameOrientedCutQ[first_List, second_List] := Module[{sign},
  sign = momentumRelativeSign[first[[1]], second[[1]]];
  MemberQ[{1, -1}, sign] &&
    TrueQ[first[[2]] sign === second[[2]]]
];

completeTopologyQ[topology_FeynCalc`FCTopology] := Module[{checks},
  checks = Quiet @ CheckAbort[
    Check[{
      FeynCalc`FCLoopValidTopologyQ[topology],
      FeynCalc`FCLoopBasisIncompleteQ[topology],
      FeynCalc`FCLoopBasisOverdeterminedQ[topology]
    }, $Failed],
    $Failed
  ];
  checks === {True, False, False}
];

completeTopologyQ[_] := False;

propagatorFactors[expr_] := Cases[
  FeynCalc`FCI[expr],
  denominator : (
      FeynCalc`PropagatorDenominator |
      FeynCalc`StandardPropagatorDenominator
    )[___] :> FeynCalc`FeynAmpDenominator[denominator],
  Infinity
];

parseHeldCut[HoldComplete[Cut[FeynCalc`SPD[q_]]]] := {q, 1};
parseHeldCut[
    HoldComplete[Cut[FeynCalc`SPD[q_], direction_]]
  ] := If[MemberQ[{1, -1}, direction], {q, direction}, $Failed];
parseHeldCut[_] := $Failed;

cutData[expr_] := Module[{objects, records, invalid, conflicts},
  objects = Cases[expr, cut_Cut :> HoldComplete[cut], Infinity];
  records = parseHeldCut /@ objects;
  invalid = Pick[
    objects,
    $Failed === # & /@ records
  ];
  If[invalid =!= {},
    Message[PartialFraction::cut, ReleaseHold /@ invalid];
    Return[$Failed]
  ];
  conflicts = Select[
    Subsets[records, {2}],
    sameMomentumQ[#[[1, 1]], #[[2, 1]]] &&
      ! sameOrientedCutQ[#[[1]], #[[2]]] &
  ];
  If[conflicts =!= {},
    Message[PartialFraction::cutorientation, conflicts];
    Return[$Failed]
  ];
  DeleteDuplicates[records, sameOrientedCutQ]
];


cutDescriptors[cutRecords_List] := Module[{descriptors},
  descriptors = Map[
    Function[record, Module[{descriptor},
      descriptor = propagatorDescriptor[FeynCalc`SFAD[First[record]]];
      If[descriptor === $Failed, Return[$Failed]];
      <|
        "Momentum" -> First[record],
        "Direction" -> Last[record],
        "UnitCore" -> descriptor["UnitCore"]
      |>
    ]],
    cutRecords
  ];
  If[MemberQ[descriptors, $Failed], $Failed, descriptors]
];

cutIndex[propagator_, descriptors_List] := Module[{descriptor},
  descriptor = propagatorDescriptor[propagator];
  If[descriptor === $Failed, Return[$Failed]];
  FirstCase[
  Range[Length[descriptors]],
  i_ /; exactZeroQ[
      descriptor["UnitCore"] - descriptors[[i, "UnitCore"]]
    ] :> i,
  Missing["NotCut"]
  ]
];

propagatorPower[propagator_] := Lookup[
  propagatorDescriptor[propagator],
  "Power",
  $Failed
];

cutOrdinaryCoreCollision[expr_, descriptors_List] := Module[
  {ordinary, ordinaryData, cutCores, collision},
  If[descriptors === {}, Return[Missing["NotFound"]]];
  ordinary = propagatorFactors[expr];
  ordinaryData = propagatorDescriptor /@ ordinary;
  If[MemberQ[ordinaryData, $Failed], Return[$Failed]];
  cutCores = Lookup[descriptors, "UnitCore"];
  collision = FirstCase[
    Tuples[{cutCores, Lookup[ordinaryData, "UnitCore"]}],
    {cutCore_, ordinaryCore_} /; exactZeroQ[cutCore - ordinaryCore] :>
      cutCore,
    Missing["NotFound"]
  ];
  collision
];

restoreCutTerm[term_, cutRecords_List, descriptors_List] := Module[
  {
    internal, propagators, indices, ordinary, coefficient,
    cutMomenta, powers, cutPowers, cutFactors, external
  },

  cutMomenta = First /@ cutRecords;
  internal = FeynCalc`FCI[term];
  propagators = Cases[
    internal,
    _FeynCalc`PropagatorDenominator |
      _FeynCalc`StandardPropagatorDenominator,
    Infinity
  ];
  indices = cutIndex[#, descriptors] & /@ propagators;
  If[MemberQ[indices, $Failed], Return[$Failed]];
  powers = propagatorPower /@ propagators;

  If[! ContainsAll[DeleteMissing[indices], Range[Length[cutMomenta]]],
    Return[Nothing]
  ];
  cutPowers = Table[
    Total @ Pick[powers, indices, cutPosition],
    {cutPosition, Length[cutMomenta]}
  ];
  If[! VectorQ[cutPowers, IntegerQ[#] && # > 0 &],
    With[{bad = FirstPosition[cutPowers, power_ /; ! IntegerQ[power] || power <= 0]},
      Message[
        PartialFraction::cutpower,
        cutPowers[[First[bad]]],
        cutMomenta[[First[bad]]]
      ]
    ];
    Return[$Failed]
  ];

  ordinary = Pick[propagators, MissingQ /@ indices];
  coefficient = internal /.
    HoldPattern[FeynCalc`FeynAmpDenominator[___]] -> 1;
  external = ToFeynFacetForm[
    coefficient If[
      ordinary === {},
      1,
      Apply[FeynCalc`FeynAmpDenominator, ordinary]
    ]
  ];
  If[external === $Failed, Return[$Failed]];
  cutFactors = MapIndexed[
    Function[{record, position},
      With[
        {
          power = cutPowers[[First[position]]],
          momentum = record[[1]],
          direction = record[[2]]
        },
        Cut[FeynCalc`SPD[momentum], direction]^power
      ]
    ],
    cutRecords
  ];

  external Times @@ cutFactors
];

restoreCutTerm[term_, cutRecords_List] := Module[{descriptors},
  descriptors = cutDescriptors[cutRecords];
  If[
    descriptors === $Failed,
    $Failed,
    restoreCutTerm[term, cutRecords, descriptors]
  ]
];


(* Outside an established ordinary-i0 limit, the proposed rational identity
   must also hold with the prescriptions retained. Common eta syntax alone
   does not permit cancellation of opposite cores across a pinch. *)
PartialFraction::prescription="The partial-fraction identity was not established with finite causal regulators. Supply an applicable whole-integral prescription proof or a regulator-preserving reduction.";
prescribedPartialFractionIdentityQ[source_,target_]:=Module[
 {eta=Unique["ordinaryEta"],cutObjects,cutCores,uniqueCores,cutTags,cutRules,convert,left,right,difference},
 cutObjects=DeleteDuplicates[Cases[{source,target},_Cut,Infinity],SameQ];
 cutCores=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[First[List@@#]]]& /@ cutObjects;
 uniqueCores=DeleteDuplicates[cutCores,SameQ];
 cutTags=AssociationThread[uniqueCores,Table[Unique["cutEta"],{Length[uniqueCores]}]];
 cutRules=MapThread[Function[{cut,core},cut->1/(core+I cutTags[core])],{cutObjects,cutCores}];
 convert[expr_]:=Module[{internal,objects,values,rules},
   internal=FeynCalc`ToSFAD[FeynCalc`FCI[expr/.cutRules]];
   objects=DeleteDuplicates[Cases[internal,_FeynCalc`StandardPropagatorDenominator,Infinity],SameQ];
   values=Map[Function[object,With[{descriptor=propagatorDescriptor[object]},
     If[descriptor===$Failed,$Failed,
       (descriptor["UnitCore"]+I object[[4,2]]eta)^(-descriptor["Power"])]]],objects];
   If[MemberQ[values,$Failed],Return[$Failed]];
   rules=Thread[objects->values];
   FeynCalc`ExpandScalarProduct[(internal/.rules)/.FeynCalc`FeynAmpDenominator->Times]
 ];
 left=convert[source];right=convert[target];
 If[MemberQ[{left,right},$Failed],Return[False]];
 difference=TimeConstrained[Cancel[Together[left-right]],3,$TimedOut];
 TrueQ[difference===0]
];

(* Cut-aware partial fractions. *)
PartialFraction[expr_, loopMomenta_List, OptionsPattern[]] := Module[
  {cutRecords, descriptors, collision, algebraic, reduced, result},

  cutRecords = cutData[expr];
  If[cutRecords === $Failed, Return[$Failed]];
  descriptors = cutDescriptors[cutRecords];
  If[descriptors === $Failed, Return[$Failed]];
  collision = cutOrdinaryCoreCollision[expr, descriptors];
  If[collision === $Failed, Return[$Failed]];
  If[! MissingQ[collision],
    Message[PartialFraction::collision, collision];
    Return[$Failed]
  ];
  If[loopMomenta === {}, Return[expr]];

  algebraic = expr /. {
    HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`FAD[q],
    HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`FAD[q]
  };
  algebraic = FeynCalc`FCLoopSwitchEtaSign[algebraic,1];
  reduced = FeynCalc`ApartFF[
    algebraic,
    loopMomenta,
    FeynCalc`DropScaleless -> OptionValue[FeynCalc`DropScaleless],
    FeynCalc`FDS -> OptionValue[FeynCalc`FDS],
    FeynCalc`FCE -> False
  ];

  If[cutRecords === {},result=ToFeynFacetForm[reduced],
    result = restoreCutTerm[#, cutRecords, descriptors] & /@ termList[reduced];
    If[MemberQ[result, $Failed], Return[$Failed]];
    If[result === {},Message[PartialFraction::nocut, cutRecords];Return[$Failed]];
    result=Total[result]
  ];
  If[!TrueQ[$ordinaryPrescriptionLimitEstablished] &&
    !prescribedPartialFractionIdentityQ[expr,result],
    Message[PartialFraction::prescription];Return[$Failed]];
  result
];

PartialFraction[expr_, loopMomenta_, OptionsPattern[]] := (
  Message[PartialFraction::loops, loopMomenta];
  $Failed
);


BuildTopologies::loops =
  "Loop momenta must be given as a list, but received `1`.";

BuildTopologies::zeroloop =
  "With no loop momenta, the propagator product must be 1 after external cuts and propagators have been separated. Received `1`.";

BuildTopologies::config =
  "SetMassZero in the setup must be a list, but received `1`.";

BuildTopologies::choice =
  "ForwardAmplitudes and ConjugateAmplitudes must identify one diagram each by a positive SelectedIndex. Received `1` and `2`.";

BuildTopologies::term =
  "Could not construct an integral topology from partial-fraction term `1`.";

BuildTopologies::partial =
  "Partial-fraction term `1` still contains linearly dependent propagators.";

BuildTopologies::rules =
  "The setup mass rules conflict with existing topology rules: `1`.";

BuildTopologies::topology =
  "The generated topology is not valid, complete and linearly independent: `1`.";

BuildTopologies::cut =
  "Could not map every cut propagator into the generated topology for term `1`.";

IdentifySafePropagator::setup =
  "Setup must define two incoming and at least two outgoing massless parton momenta, together with valid forward and conjugate loop-momentum lists.";

IdentifySafePropagator::form =
  "The ordinary propagator `1` is outside the supported massless quadratic or null-bilinear phase-space sign criterion.";

IdentifySafePropagator::virtual =
  "The propagator `1` contains a virtual loop momentum and is outside this phase-space sign check.";

IdentifySafePropagator::unsafe =
  "A strict interior sign was not established for `1`: its inverse denominator divided by s ranges from `2` to `3` on unrestricted massless phase space. This is not a slice-specific or endpoint-convergence test.";

$buildTopologiesFailure = "FeynFacetBuildTopologiesFailure";


(* Integral-family construction. *)
topologyPropagatorIndex[
    propagator_,
    topology_FeynCalc`FCTopology,
    loopMomenta_List
  ] := Module[{converted, mapped, glis, positions},
  converted = CheckAbort[
    FeynCalc`FCLoopToGLI[propagator, loopMomenta],
    $Failed
  ];
  If[! MatchQ[converted, {_, _FeynCalc`FCTopology}], Return[$Failed]];
  mapped = CheckAbort[
    converted[[1]] /.
      FeynCalc`FCLoopCreateRuleGLIToGLI[topology, converted[[2]]],
    $Failed
  ];
  If[mapped === $Failed, Return[$Failed]];
  glis = Cases[mapped, _FeynCalc`GLI, {0, Infinity}];
  If[Length[glis] =!= 1, Return[$Failed]];
  positions = Flatten @ Position[
    glis[[1, 2]],
    _?(# =!= 0 &),
    {1},
    Heads -> False
  ];
  If[Length[positions] =!= 1, Return[$Failed]];
  First[positions]
];


setupVirtualLoopMomenta[setup_Association] := Module[
  {forward, conjugate, loops},
  forward = Lookup[setup, "ForwardAmplitudes", <||>];
  conjugate = Lookup[setup, "ConjugateAmplitudes", <||>];
  If[! AssociationQ[forward] || ! AssociationQ[conjugate],
    Return[$Failed]
  ];
  loops = {
    Lookup[forward, "LoopMomenta", {}],
    Lookup[conjugate, "LoopMomenta", {}]
  };
  If[! AllTrue[loops, ListQ], Return[$Failed]];
  DeleteDuplicates[Flatten[loops]]
];


momentumCoordinates[q_, basis_List] := Module[{coefficients, remainder},
  coefficients = Coefficient[Expand[q], #] & /@ basis;
  remainder = Expand[q - coefficients . basis];
  If[
    AllTrue[coefficients, exactRationalQ] && exactZeroQ[remainder],
    coefficients,
    $Failed
  ]
];


masslessSquareBounds[coefficients_List, finalCount_Integer] := Module[
  {a, b, c, values},
  If[Length[coefficients] =!= finalCount + 2, Return[$Failed]];
  a = coefficients[[1]];
  b = coefficients[[2]];
  c = Drop[coefficients, 2];
  values = Flatten @ Table[
    If[i === j, Nothing, (a + c[[i]]) (b + c[[j]])],
    {i, finalCount},
    {j, finalCount}
  ];
  {Min @@ values, Max @@ values}
];


safePropagatorData[setup_Association, propagator_] := Module[
  {
    partonRule, incoming, outgoing, partonMomenta, massless,
    virtualLoops, descriptor, coefficients, squareScale = 1, squareCore, squareMomentum, squareCoordinates,
    pairObjects, pair, pairScale, pairMomenta, pairCoordinates,
    rawBounds, scaledBounds, lower, upper, a, b, c, key, coreKey, first
  },

  partonRule = Lookup[setup, "PartonMomentum", Missing["NotFound"]];
  massless = Lookup[setup, "SetMassZero", Missing["NotFound"]];
  virtualLoops = setupVirtualLoopMomenta[setup];
  If[
    ! MatchQ[partonRule, Rule[_List, _List]] ||
      ! ListQ[massless] || virtualLoops === $Failed,
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  {incoming, outgoing} = List @@ partonRule;
  partonMomenta = Join[incoming, outgoing];
  If[
    Length[incoming] =!= 2 || Length[outgoing] < 2 ||
      ! DuplicateFreeQ[partonMomenta] ||
      ! ContainsAll[massless, partonMomenta],
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  If[AnyTrue[virtualLoops, ! FreeQ[propagator, #] &],
    Message[IdentifySafePropagator::virtual, propagator];
    Return[$Failed]
  ];

  descriptor = propagatorDescriptor[propagator];
  If[descriptor === $Failed,
    Message[IdentifySafePropagator::form, propagator];
    Return[$Failed]
  ];

  (* Do not infer absence of a mass/constant shift from a quotient that
     could simplify on a preassigned kinematic slice. Inspect the field too. *)
  If[! FreeQ[FeynCalc`FCI[propagator],
      object_FeynCalc`StandardPropagatorDenominator /; ! exactZeroQ[object[[3]]]],
    Message[IdentifySafePropagator::form, propagator]; Return[$Failed]];

  coefficients = Switch[descriptor["Type"],
    "QuadraticLorentzian",
      (* Check the ACTUAL inverse propagator, including its scale and mass
         field. A momentum-only descriptor also describes shifted virtual
         propagators and must not certify their unshifted square here. *)
      squareMomentum = descriptor["Momentum"];
      squareCoordinates = momentumCoordinates[squareMomentum, partonMomenta];
      If[squareCoordinates === $Failed,
        squareMomentum = Expand[-I squareMomentum];
        squareCoordinates = momentumCoordinates[squareMomentum, partonMomenta]];
      squareCore = FeynCalc`ExpandScalarProduct[
        FeynCalc`FCI[FeynCalc`SPD[squareMomentum]]];
      squareScale = If[exactZeroQ[squareCore], $Failed,
        Quiet @ Check[Cancel[descriptor["UnitCore"]/squareCore], $Failed]];
      If[! exactRationalQ[squareScale] || exactZeroQ[squareScale],
        $Failed,
        squareCoordinates],
    "LinearLorentzian",
      pairObjects = Cases[
        descriptor["UnitCore"],
        pair_FeynCalc`Pair :> pair,
        {0, Infinity}
      ];
      If[Length[pairObjects] =!= 1, $Failed,
        pair = First[pairObjects];
        pairScale = Quiet @ Check[
          Cancel[Together[descriptor["UnitCore"]/pair]],
          $Failed
        ];
        pairMomenta = List @@ pair /. FeynCalc`Momentum[q_, ___] :> q;
        pairCoordinates = momentumCoordinates[#, partonMomenta] & /@
          pairMomenta;
        If[
          pairScale === $Failed || ! exactRationalQ[pairScale] ||
            exactZeroQ[pairScale] || MemberQ[pairCoordinates, $Failed] ||
            ! AllTrue[
              pairCoordinates,
              masslessSquareBounds[#, Length[outgoing]] === {0, 0} &
            ],
          $Failed,
          squareScale = pairScale/2;
          Total[pairCoordinates]
        ]
      ],
    _, $Failed
  ];
  If[coefficients === $Failed,
    Message[IdentifySafePropagator::form, propagator];
    Return[$Failed]
  ];

  a = coefficients[[1]];
  b = coefficients[[2]];
  c = Drop[coefficients, 2];
  rawBounds = masslessSquareBounds[coefficients, Length[outgoing]];
  scaledBounds = squareScale rawBounds;
  lower = Min @@ scaledBounds;
  upper = Max @@ scaledBounds;
  coreKey = Join[a + c, b + c];
  first = FirstCase[coreKey, value_ /; value =!= 0, 0];
  If[first < 0, coreKey = -coreKey];
  key = Prepend[coreKey, squareScale];

  {key, lower, upper, propagator}
];


IdentifySafePropagator[setup_Association, propagator_] := Module[{data},
  data = safePropagatorData[setup, propagator];
  If[data === $Failed, Return[$Failed]];
  If[TrueQ[
      (data[[2]] >= 0 && data[[3]] > 0) ||
        (data[[2]] < 0 && data[[3]] <= 0)
    ],
    True,
    Message[
      IdentifySafePropagator::unsafe,
      propagator,
      data[[2]],
      data[[3]]
    ];
    $Failed
  ]
];

IdentifySafePropagator[setup_, propagator_] := (
  Message[IdentifySafePropagator::setup];
  $Failed
);


checkCompletedPropagators[setup_Association, families_List, integrals_: Automatic] := Module[
  {virtualLoops, propagators, candidates, data, unique, targets, grouped, names, bad},
  targets = If[integrals === Automatic, If[families === {}, {}, Lookup[families, "BaseGLI"]], integrals];
  If[! ListQ[targets] || ! AllTrue[targets, MatchQ[#, FeynCalc`GLI[_, {_Integer ...}]] &],
    Return[$Failed]];
  names = #["Topology"][[1]] & /@ families;
  If[! ContainsAll[names, First /@ targets], Return[$Failed]];
  grouped = GroupBy[targets, First];
  bad = AnyTrue[families, Function[family,
    ! MatchQ[family["CutIndices"], {_Integer ...}] ||
    ! AllTrue[family["CutIndices"], 1 <= # <= Length[family["Topology"][[2]]] &] ||
    AnyTrue[Lookup[grouped, family["Topology"][[1]], {}],
      Length[#[[2]]] =!= Length[family["Topology"][[2]]] ||
        ! AllTrue[#[[2, family["CutIndices"]]], # > 0 &] &]]];
  If[bad, Return[$Failed]];
  virtualLoops = setupVirtualLoopMomenta[setup];
  If[virtualLoops === $Failed,
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  propagators = Flatten @ Map[
    Function[family,
      With[
        {
          all = family["Topology"][[2]],
          cuts = family["CutIndices"],
          active = Lookup[grouped, family["Topology"][[1]], {}]
        },
        all[[Select[Complement[Range[Length[all]], cuts],
          Function[position, AnyTrue[active, #[[2, position]] > 0 &]]]]]
      ]
    ],
    families
  ];
  candidates = Select[
    DeleteDuplicates[propagators, SameQ],
    Function[propagator,
      AllTrue[virtualLoops, FreeQ[propagator, #] &]
    ]
  ];
  data = safePropagatorData[setup, #] & /@ candidates;
  If[MemberQ[data, $Failed], Return[$Failed]];
  unique = DeleteDuplicatesBy[data, First];
  If[AnyTrue[
      unique,
      ! TrueQ[(#[[2]] >= 0 && #[[3]] > 0) ||
        (#[[2]] < 0 && #[[3]] <= 0)] &
    ],
    With[{bad = SelectFirst[
        unique,
        ! TrueQ[(#[[2]] >= 0 && #[[3]] > 0) ||
          (#[[2]] < 0 && #[[3]] <= 0)] &
      ]},
      Message[
        IdentifySafePropagator::unsafe,
        bad[[4]],
        bad[[2]],
        bad[[3]]
      ]
    ];
    Return[$Failed]
  ];
  True
];


(* Elimination of an unobserved external momentum does not remove its
   on-shell condition. Only impose it on an ordinary external topology:
   for a real cut momentum the corresponding condition remains a cut. *)
topologyExternalOnShellRules[config_Association, external_List, loops_List] := Module[
 {massless=Lookup[config,"SetMassZero",{}], rules, integrated, incoming,
  outgoing, eliminated, support, variables, pivot, coefficient},
 rules=FeynCalc`FCI[(FeynCalc`SPD[#]->0)& /@ Select[external,MemberQ[massless,#]&]];
 integrated=Lookup[config,"PartonIntegrated",{}];
 If[!MatchQ[integrated,{_Symbol}] || !MemberQ[massless,First[integrated]],Return[rules]];
 {incoming,outgoing}=List@@config["PartonMomentum"];
 eliminated=Expand[Total[incoming]-Total[DeleteCases[outgoing,First[integrated]]]];
 If[!FreeQ[eliminated,Alternatives@@loops] ||
   !SubsetQ[external,DeleteDuplicates[Cases[eliminated,_Symbol,{0,Infinity}]]],Return[rules]];
 support=Expand[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[eliminated]]]/.rules];
 If[support===0,Return[rules]];
 variables=DeleteDuplicates[Cases[support,_FeynCalc`Pair,{0,Infinity}]];
 If[variables==={},Return[rules]];
 pivot=Last[Sort[variables]];coefficient=Coefficient[support,pivot];
 If[!MatchQ[coefficient,_Integer|_Rational] || coefficient===0 || Exponent[support,pivot]=!=1,
  Return[rules]];
 Append[rules,pivot->Cancel[-(support-coefficient pivot)/coefficient]]
];

BuildTopologies[
    partialFractions_,
    loopMomenta_List,
    config_Association
  ] := Catch[
  Module[{
    massless, forwardAmplitudes, conjugateAmplitudes, pair,
    forwardTag, conjugateTag,
    terms, buildOne, families
  },

    If[loopMomenta === {},
      If[ToFeynFacetForm[partialFractions] =!= 1,
        Message[BuildTopologies::zeroloop, partialFractions];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      Print @ Grid[
        {
          {"Topology", "External momenta", "Cut indices", "Cut directions"},
          {"None", {}, {}, {}}
        },
        Frame -> All
      ];
      Return[{}]
    ];
    massless = Lookup[config, "SetMassZero", {}];
    If[! ListQ[massless],
      Message[BuildTopologies::config, massless];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    forwardAmplitudes = Lookup[config, "ForwardAmplitudes", <||>];
    conjugateAmplitudes = Lookup[config, "ConjugateAmplitudes", <||>];
    pair = selectedPairFromSetup[config];
    If[pair === $Failed,
      Message[
        BuildTopologies::choice,
        forwardAmplitudes,
        conjugateAmplitudes
      ];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    forwardTag = ToString[pair["Forward"]];
    conjugateTag = ToString[pair["Conjugate"]];
    terms = termList[partialFractions];

    buildOne[term_, index_Integer] := Module[
      {
        cutRecords, cutMomenta, cutDirections, algebraic, converted,
        topology, topologyID, external, massRules, conflicts, completed,
        missingExternal, extraPropagators, topologyDimension, etaSign,
        cutIndices, mappedFamily, baseGLIs, baseGLI,
        familyCoefficient
      },

      cutRecords = cutData[term];
      If[cutRecords === $Failed,
        Throw[$Failed, $buildTopologiesFailure]
      ];
      cutMomenta = First /@ cutRecords;
      cutDirections = Last /@ cutRecords;
      algebraic = term /. {
        HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
        HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
      };
      converted = Quiet @ CheckAbort[
        FeynCalc`FCLoopToGLI[algebraic, loopMomenta],
        $Failed
      ];
      If[! MatchQ[converted, {_, _FeynCalc`FCTopology}],
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topology = converted[[2]];
      If[
        topology[[3]] =!= loopMomenta ||
        TrueQ[Quiet @ FeynCalc`FCLoopBasisOverdeterminedQ[topology]],
        Message[BuildTopologies::partial, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topologyID = Symbol[
        "Global`TopologyF" <> forwardTag <>
          "C" <> conjugateTag <>
          "N" <> ToString[index]
      ];
      (* All families of one process use its independent external momenta.
         A triangle may not use one vector in its denominators, but Kira's
         common kinematics still requires that vector and a completed ISP. *)
      external = DeleteDuplicates[Join[topology[[4]],
        Select[Flatten[List@@config["PartonMomentum"]],
          !MemberQ[Join[loopMomenta,Lookup[config,"PartonIntegrated",{}]],#]&]]];
      external = Sort[external];
      missingExternal = Complement[external,topology[[4]]];
      topologyDimension = First[FeynCalc`FCGetDimensions[topology[[2]]]];
      etaSign = First[FeynCalc`FCLoopGetEtaSigns[topology]];
      extraPropagators = Flatten[Table[FeynCalc`FeynAmpDenominator[
        FeynCalc`StandardPropagatorDenominator[0,
          FeynCalc`Pair[FeynCalc`Momentum[l,topologyDimension],FeynCalc`Momentum[p,topologyDimension]],
          0,{1,etaSign}]],{l,loopMomenta},{p,missingExternal}]];
      massRules = topologyExternalOnShellRules[config, external, loopMomenta];
      conflicts = Select[
        topology[[5]],
        Function[rule,
          AnyTrue[
            massRules,
            SameQ[First[rule], First[#]] &&
              ! exactZeroQ[Last[rule] - Last[#]] &
          ]
        ]
      ];
      If[conflicts =!= {},
        Message[BuildTopologies::rules, conflicts];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      topology = FeynCalc`FCTopology[
        topologyID,
        Join[topology[[2]],extraPropagators],
        loopMomenta,
        external,
        DeleteDuplicates[Join[topology[[5]], massRules]],
        topology[[6]]
      ];
      completed = Quiet @ CheckAbort[
        FeynCalc`FCLoopBasisFindCompletion[
          topology,
          FeynCalc`Names -> (# &)
        ],
        $Failed
      ];
      If[! MatchQ[completed, _FeynCalc`FCTopology],
        Message[BuildTopologies::topology, topology];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      If[! completeTopologyQ[completed],
        Message[BuildTopologies::topology, completed];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      mappedFamily = Quiet @ CheckAbort[
        converted[[1]] /.
          FeynCalc`FCLoopCreateRuleGLIToGLI[completed, converted[[2]]],
        $Failed
      ];
      baseGLIs = DeleteDuplicates @ Cases[
        mappedFamily,
        _FeynCalc`GLI,
        {0, Infinity}
      ];
      If[Length[baseGLIs] =!= 1,
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      baseGLI = First[baseGLIs];
      familyCoefficient = mappedFamily /. baseGLI -> 1;
      If[
        ! FreeQ[familyCoefficient, _FeynCalc`GLI] ||
          ! exactZeroQ[mappedFamily - familyCoefficient baseGLI],
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      cutIndices = topologyPropagatorIndex[
        FeynCalc`SFAD[#],
        completed,
        loopMomenta
      ] & /@ cutMomenta;
      If[
        ! VectorQ[cutIndices, IntegerQ] ||
        Length[DeleteDuplicates[cutIndices]] =!= Length[cutIndices],
        Message[BuildTopologies::cut, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      Association[
        "Propagators" -> term,
        "Topology" -> completed,
        "BaseGLI" -> baseGLI,
        "FamilyCoefficient" -> familyCoefficient,
        "CutMomenta" -> cutMomenta,
        "CutIndices" -> cutIndices,
        "CutDirections" -> cutDirections
      ]
    ];

    families = MapIndexed[buildOne[#1, First[#2]] &, terms];
    If[checkCompletedPropagators[config, families] =!= True,
      Throw[$Failed, $buildTopologiesFailure]
    ];
    Print @ Grid[
      Prepend[
        {
          #["Topology"][[1]],
          #["Topology"][[4]],
          #["CutIndices"],
          #["CutDirections"]
        } & /@ families,
        {"Topology", "External momenta", "Cut indices", "Cut directions"}
      ],
      Frame -> All
    ];
    families
  ],
  $buildTopologiesFailure
];

BuildTopologies[partialFractions_, loopMomenta_, config_] := (
  If[! MatchQ[loopMomenta, {__}],
    Message[BuildTopologies::loops, loopMomenta],
    Message[BuildTopologies::config, config]
  ];
  $Failed
);

TopologyEquivalence::input =
  "Expected cut-aware topology records and their Setup association, but received `1`.";

TopologyEquivalence::record =
  "Topology record `1` is missing or has inconsistent topology or cut metadata.";

TopologyEquivalence::names =
  "Topology names must be unique, but received `1`.";

TopologyEquivalence::mapping =
  "FeynCalc could not determine topology mappings for `1`.";

TopologyEquivalence::coverage =
  "FeynCalc returned incomplete or inconsistent mapping coverage for `1`.";

$topologyEquivalenceFailure = "FeynFacetTopologyEquivalenceFailure";


topologyPropagatorCore[propagator_, shift_List, kinematics_List] :=
  Module[{mapped, explicit, core},
    mapped = FeynCalc`FCReplaceMomenta[
      FeynCalc`FCI[propagator],
      shift
    ];
    explicit = Quiet @ Check[
      FeynCalc`FeynAmpDenominatorExplicit[
        mapped,
        FeynCalc`FCI -> True
      ],
      $Failed
    ];
    If[explicit === $Failed || exactZeroQ[explicit], Return[$Failed]];
    core = Quiet @ Check[
      Cancel[Together[(1/explicit) /. kinematics]],
      $Failed
    ];
    If[
      core === $Failed ||
        ! FreeQ[
          core,
          FeynCalc`FeynAmpDenominator |
            FeynCalc`PropagatorDenominator |
            FeynCalc`StandardPropagatorDenominator
        ],
      $Failed,
      core
    ]
];

propagatorDescriptor[propagator_, kinematics_List : {}] := Module[
  {
    raw, internal, objects, denominator, standard, quadratic, linear,
    type, power, momentum, unitInternal, unitCore
  },
  raw = FeynCalc`FCI[propagator];
  internal = If[
    MatchQ[
      raw,
      (_FeynCalc`PropagatorDenominator |
        _FeynCalc`StandardPropagatorDenominator | _FeynCalc`GenericPropagatorDenominator)
    ],
    FeynCalc`FeynAmpDenominator[raw],
    raw
  ];
  objects = Cases[
    internal,
    denominator : (
        FeynCalc`PropagatorDenominator |
        FeynCalc`StandardPropagatorDenominator | FeynCalc`GenericPropagatorDenominator
      )[___] :> denominator,
    {0, Infinity}
  ];
  If[Length[objects] =!= 1, Return[$Failed]];
  denominator = First[objects];
  If[Head[denominator] === FeynCalc`GenericPropagatorDenominator,
    If[!MatchQ[denominator, FeynCalc`GenericPropagatorDenominator[_, {_Integer?Positive, 1 | -1}]],
      Return[$Failed]];
    unitCore = FeynCalc`ExpandScalarProduct[denominator[[1]]] /. kinematics;
    Return[<|"Representation" -> "Generic", "Momentum" -> Missing["PolynomialPropagator"],
      "Type" -> "PolynomialLorentzian", "Power" -> denominator[[2,1]], "UnitCore" -> unitCore|>]
  ];
  standard = Head[denominator] === FeynCalc`StandardPropagatorDenominator;
  If[standard,
    quadratic = ! exactZeroQ[denominator[[1]]];
    linear = ! exactZeroQ[denominator[[2]]];
    type = Which[
      quadratic && ! linear, "QuadraticLorentzian",
      ! quadratic && linear, "LinearLorentzian",
      True, $Failed
    ];
    If[! MatchQ[denominator[[4]], {_Integer?Positive, 1 | -1}],
      Return[$Failed]
    ];
    power = First[denominator[[4]]];
    unitInternal = internal /. HoldPattern[
        FeynCalc`StandardPropagatorDenominator[
          q_, sp_, mass_, {_, eta0_}
        ]
      ] :> FeynCalc`StandardPropagatorDenominator[
        q, sp, mass, {1, eta0}
      ],
    If[! exactZeroQ[denominator[[2]]], Return[$Failed]];
    type = "QuadraticLorentzian";
    power = 1;
    unitInternal = internal
  ];
  If[type === $Failed, Return[$Failed]];
  momentum = If[type === "QuadraticLorentzian",
    Expand[
      First[denominator] /. {
        FeynCalc`Momentum[q_, ___] :> q,
        I FeynCalc`Momentum[q_, ___] :> q
      }
    ],
    Missing["LinearPropagator"]
  ];
  unitCore = topologyPropagatorCore[unitInternal, {}, kinematics];
  If[unitCore === $Failed, Return[$Failed]];
  <|
    "Representation" -> If[standard, "Standard", "Legacy"],
    "Momentum" -> momentum,
    "Type" -> type,
    "Power" -> power,
    "UnitCore" -> unitCore
  |>
];

topologyRecordQ[record_Association] := TrueQ @ Quiet @ CheckAbort[Module[
  {
    required, topology, cutMomenta, cutIndices, cutDirections,
    propagatorInfo, propagatorMomenta, propagatorTypes, propagatorPowers,
    context, baseGLI, baseIndices, activeSlots, familyCoefficient
  },

  required = {
    "Type", "Version", "DiagramPair", "Topology", "BaseGLI",
    "FamilyCoefficient", "CutMomenta", "CutIndices", "CutDirections",
    "AnalyticContext"
  };
  If[! ContainsAll[Keys[record], required], Return[False]];
  If[
    record["Type"] =!= "FeynFacetTopologyRecord" ||
      record["Version"] =!= 3 ||
      ! AssociationQ[record["DiagramPair"]],
    Return[False]
  ];

  topology = record["Topology"];
  cutMomenta = record["CutMomenta"];
  cutIndices = record["CutIndices"];
  cutDirections = record["CutDirections"];
  context = record["AnalyticContext"];
  If[! MatchQ[topology, _FeynCalc`FCTopology], Return[False]];
  If[! analyticContextQ[context], Return[False]];

  baseGLI = record["BaseGLI"];
  familyCoefficient = record["FamilyCoefficient"];
  If[
    ! MatchQ[baseGLI, _FeynCalc`GLI] ||
      baseGLI[[1]] =!= topology[[1]] ||
      Length[baseGLI[[2]]] =!= Length[topology[[2]]] ||
      ! VectorQ[baseGLI[[2]], IntegerQ] ||
      ! FreeQ[familyCoefficient, _FeynCalc`GLI],
    Return[False]
  ];
  baseIndices = baseGLI[[2]];
  activeSlots = Flatten @ Position[
    baseIndices,
    _Integer?Positive,
    {1},
    Heads -> False
  ];

  propagatorInfo = propagatorDescriptor[#, topology[[5]]] & /@ topology[[2]];
  If[MemberQ[propagatorInfo, $Failed], Return[False]];
  propagatorMomenta = Lookup[propagatorInfo, "Momentum"];
  propagatorTypes = Lookup[propagatorInfo, "Type"];
  propagatorPowers = Lookup[propagatorInfo, "Power"];
  And[
    completeTopologyQ[topology],
    Length[cutMomenta] === Length[cutIndices] === Length[cutDirections],
    DuplicateFreeQ[cutIndices],
    AllTrue[
      cutIndices,
      IntegerQ[#] && 1 <= # <= Length[topology[[2]]] &
    ],
    ContainsAll[activeSlots, cutIndices],
    AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    AllTrue[cutMomenta, ! exactZeroQ[#] &],
    AllTrue[propagatorInfo, #1["Representation"] === "Standard" &],
    AllTrue[propagatorPowers, SameQ[#, 1] &],
    And @@ MapThread[
      MemberQ[{1, -1}, momentumRelativeSign[#1, #2]] &,
      {cutMomenta, propagatorMomenta[[cutIndices]]}
    ],
    AllTrue[
      propagatorTypes[[cutIndices]],
      SameQ[#, "QuadraticLorentzian"] &
    ],
    exactDataQ[KeyDrop[record, "Created"]]
  ]
], False];

topologyRecordQ[_] := False;

topologyRecordQ[record_, pair_Association] :=
  topologyRecordQ[record] &&
    SameQ[Lookup[record, "DiagramPair", Missing[]], pair];

AMFlowPrescription::topology =
  "The topology record is invalid or its loop momenta do not match Setup: `1`.";

AMFlowPrescription::mixed =
  "Active propagator slots `1` mix forward and conjugate virtual loop momenta.";

AMFlowPrescription::cutloop =
  "Cut propagator slots `1` contain a virtual loop momentum.";


topologyAMFlowData[setup_Association, record_Association] := Module[
  {
    topology, loopData, topologyLoops, virtualByMomentum, sideSets,
    activeIndices, mixedIndices, cutIndices, invalidCuts, cutMask
  },

  If[! topologyRecordQ[record],
    Message[AMFlowPrescription::topology, record];
    Return[$Failed]
  ];
  loopData = AMFlowPrescription[setup];
  If[! AssociationQ[loopData], Return[$Failed]];
  topology = record["Topology"];
  topologyLoops = topology[[3]];
  If[
    ! DuplicateFreeQ[topologyLoops] ||
      Sort[topologyLoops] =!= Sort[loopData["LoopMomenta"]],
    Message[AMFlowPrescription::topology, topology[[1]]];
    Return[$Failed]
  ];

  virtualByMomentum = AssociationThread[
    loopData["LoopMomenta"],
    loopData["Prescription"]
  ];
  sideSets = Function[propagator,
      DeleteDuplicates @ DeleteCases[
        Pick[
          Lookup[virtualByMomentum, topologyLoops],
          (! FreeQ[FeynCalc`FCI[propagator], #] &) /@ topologyLoops
        ],
        0
      ]
    ] /@ topology[[2]];
  activeIndices = Flatten @ Position[
    record["BaseGLI"][[2]],
    _Integer?Positive,
    {1},
    Heads -> False
  ];
  mixedIndices = Flatten @ Position[sideSets, sides_ /; Length[sides] > 1, {1}];
  If[Intersection[activeIndices, mixedIndices] =!= {},
    Message[AMFlowPrescription::mixed, Intersection[activeIndices, mixedIndices]];
    Return[$Failed]
  ];

  cutIndices = record["CutIndices"];
  invalidCuts = Select[cutIndices, sideSets[[#]] =!= {} &];
  If[invalidCuts =!= {},
    Message[AMFlowPrescription::cutloop, invalidCuts];
    Return[$Failed]
  ];
  cutMask = Boole[MemberQ[cutIndices, #]] & /@
    Range[Length[topology[[2]]]];
  Join[loopData, <|"Cut" -> cutMask|>]
];

AMFlowPrescription[setup_Association, record_Association] :=
  topologyAMFlowData[setup, record];

AMFlowPrescription[setup_, record_] := (
  Message[AMFlowPrescription::topology, HoldForm[{setup, record}]];
  $Failed
);

(* Certified affine topology equivalence. *)
parseTopologyMapping[
    {sourceTopology_FeynCalc`FCTopology, shift_List, gliRule_},
    recordByName_Association
  ] := Module[
  {indices, inputGLI, outputGLI, sourceName, targetName},

  If[
    ! MemberQ[{Rule, RuleDelayed}, Head[gliRule]] ||
      ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[Failure[
      "MalformedMapping",
      <|"Mapping" -> {sourceTopology, shift, gliRule}|>
    ]]
  ];
  sourceName = sourceTopology[[1]];
  If[! KeyExistsQ[recordByName, sourceName],
    Return[Failure[
      "UnknownMappingSource",
      <|"Source" -> sourceName|>
    ]]
  ];
  indices = Table[
    Unique["topologyIndex$"],
    {Length[sourceTopology[[2]]]}
  ];
  inputGLI = FeynCalc`GLI[sourceName, indices];
  outputGLI = Replace[inputGLI, gliRule, {0}];
  If[
    ! MatchQ[outputGLI, _FeynCalc`GLI] || outputGLI === inputGLI,
    Return[Failure[
      "InapplicableGLIRule",
      <|"Source" -> sourceName, "Rule" -> gliRule|>
    ]]
  ];
  targetName = outputGLI[[1]];
  If[! KeyExistsQ[recordByName, targetName],
    Return[Failure[
      "UnknownMappingTarget",
      <|"Source" -> sourceName, "Target" -> targetName|>
    ]]
  ];
  <|
    "Source" -> sourceName,
    "Target" -> targetName,
    "LoopMomentumRules" -> shift,
    "GLIRule" -> gliRule,
    "ProbeGLI" -> inputGLI,
    "ProbeIndices" -> indices,
    "MappedProbe" -> outputGLI
  |>
];

parseTopologyMapping[other_, _Association] := Failure[
  "MalformedMapping",
  <|"Mapping" -> other|>
];

topologyGLIIndexMap[parsed_Association, source_, target_] := Module[
  {indices, mappedIndices, positions},

  indices = parsed["ProbeIndices"];
  mappedIndices = parsed["MappedProbe"][[2]];
  If[
    Length[source[[2]]] =!= Length[target[[2]]] ||
      Length[mappedIndices] =!= Length[indices],
    Return[$Failed]
  ];
  If[! VectorQ[mappedIndices, MemberQ[indices, #] &], Return[$Failed]];
  positions = Position[
      mappedIndices,
      #,
      {1},
      Heads -> False
    ] & /@ indices;
  If[
    ! AllTrue[positions, MatchQ[#, {{_Integer}}] &],
    Return[$Failed]
  ];
  positions[[All, 1, 1]]
];

topologyVerifiedGLIRule[sourceName_, targetName_, indexMap_List] := Module[
  {count, variables, left, right},

  count = Length[indexMap];
  If[Sort[indexMap] =!= Range[count], Return[$Failed]];
  variables = Table[Unique["gliIndex$"], {count}];
  left = FeynCalc`GLI[
    sourceName,
    Pattern[#, Blank[]] & /@ variables
  ];
  right = FeynCalc`GLI[
    targetName,
    variables[[Ordering[indexMap]]]
  ];
  With[
    {verifiedLeft = left, verifiedRight = right},
    HoldPattern[verifiedLeft] :> verifiedRight
  ]
];

topologyCutMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceIndices, targetIndices, sourceMomenta, targetMomenta,
    sourceDirections, targetDirections, mappedIndices, targetPosition,
    sign, checks, failure
  },

  sourceIndices = source["CutIndices"];
  targetIndices = target["CutIndices"];
  sourceMomenta = source["CutMomenta"];
  targetMomenta = target["CutMomenta"];
  sourceDirections = source["CutDirections"];
  targetDirections = target["CutDirections"];
  mappedIndices = indexMap[[sourceIndices]];
  If[Sort[mappedIndices] =!= Sort[targetIndices],
    Return[{False, "cut indices do not map one-to-one"}]
  ];

  checks = Table[
    targetPosition = First @ FirstPosition[
      targetIndices,
      mappedIndices[[index]]
    ];
    sign = momentumRelativeSign[
      Expand[sourceMomenta[[index]] /. shift],
      targetMomenta[[targetPosition]]
    ];
    Which[
      sign === 0,
        {False, "mapped cut momentum is not the target cut momentum"},
      sign sourceDirections[[index]] =!= targetDirections[[targetPosition]],
        {False, "cut energy direction is reversed"},
      True,
        {True, Null}
    ],
    {index, Length[sourceIndices]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, mappedIndices}
];

topologyAffineMapping[source_, target_, shift_List] := Module[
  {
    sourceTopology, targetTopology, sourceLoops, targetLoops,
    sourceExternal, targetExternal, external, mappedLoops, matrix,
    translation, translationMatrix, remainder, determinant, coefficients,
    leftSides
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourceLoops = sourceTopology[[3]];
  targetLoops = targetTopology[[3]];
  sourceExternal = sourceTopology[[4]];
  targetExternal = targetTopology[[4]];
  If[Length[sourceLoops] =!= Length[targetLoops],
    Return[{False, "loop counts differ"}]
  ];
  If[
    Sort[sourceExternal] =!= Sort[targetExternal] ||
      Sort[sourceTopology[[5]]] =!= Sort[targetTopology[[5]]],
    Return[{False, "external momentum bases or kinematic rules differ"}]
  ];
  If[
    ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[{False, "loop mapping contains malformed rules"}]
  ];
  leftSides = First /@ shift;
  If[
    ! DuplicateFreeQ[leftSides] ||
      ! AllTrue[leftSides, MemberQ[sourceLoops, #] &],
    Return[{False, "mapping contains non-loop replacement rules"}]
  ];

  mappedLoops = Expand[sourceLoops /. shift];
  matrix = Table[
    Coefficient[mappedLoops[[i]], targetLoops[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[targetLoops]}
  ];
  external = Sort[sourceExternal];
  translation = Expand[mappedLoops - matrix.targetLoops];
  translationMatrix = Table[
    Coefficient[translation[[i]], external[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[external]}
  ];
  remainder = Expand[translation - translationMatrix.external];
  coefficients = Flatten[{matrix, translationMatrix}];
  If[! AllTrue[coefficients, exactRationalQ],
    Return[{False, "mapping coefficients are not exact real rationals"}]
  ];
  If[! And @@ (exactZeroQ /@ remainder),
    Return[{False, "loop mapping is not affine-linear in declared momenta"}]
  ];
  determinant = Cancel[Det[matrix]];
  If[
    ! exactZeroQ[determinant - 1] &&
      ! exactZeroQ[determinant + 1],
    Return[{False, "loop mapping does not have unit Jacobian"}]
  ];

  {True, <|
    "LoopMatrix" -> matrix,
    "TranslationMatrix" -> translationMatrix,
    "ExternalBasis" -> external,
    "Determinant" -> determinant
  |>}
];

topologyPropagatorMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceTopology, targetTopology, sourcePropagators, targetPropagators,
    sourceInfo, targetInfo, sourceTypes, targetTypes, sourcePowers,
    targetPowers, sourceCore, targetCore, checks, failure
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourcePropagators = sourceTopology[[2]];
  targetPropagators = targetTopology[[2]];
  sourceInfo = propagatorDescriptor[#, sourceTopology[[5]]] & /@
    sourcePropagators;
  targetInfo = propagatorDescriptor[#, targetTopology[[5]]] & /@
    targetPropagators;
  If[MemberQ[Join[sourceInfo, targetInfo], $Failed],
    Return[{False, "unsupported propagator representation"}]
  ];
  sourceTypes = Lookup[sourceInfo, "Type"];
  targetTypes = Lookup[targetInfo, "Type"];
  sourcePowers = Lookup[sourceInfo, "Power"];
  targetPowers = Lookup[targetInfo, "Power"];
  checks = Table[
    sourceCore = topologyPropagatorCore[
      sourcePropagators[[index]],
      shift,
      sourceTopology[[5]]
    ];
    targetCore = topologyPropagatorCore[
      targetPropagators[[indexMap[[index]]]],
      {},
      targetTopology[[5]]
    ];
    Which[
      sourceTypes[[index]] =!= targetTypes[[indexMap[[index]]]],
        {False, "propagator types do not match"},
      sourcePowers[[index]] =!= targetPowers[[indexMap[[index]]]],
        {False, "propagator powers do not match"},
      sourceCore === $Failed || targetCore === $Failed,
        {False, "could not extract a propagator polynomial"},
      ! exactZeroQ[sourceCore - targetCore],
        {False, "mapped propagator polynomials do not match"},
      True,
        {True, Null}
    ],
    {index, Length[sourcePropagators]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, "Verified"}
];

topologyLoopSectorMapping[
    source_, target_, matrix_, sectorData_Association
  ] := Module[
  {
    byMomentum, sourceSectors, targetSectors, targetPositions,
    checks, failure
  },

  byMomentum = AssociationThread[
    sectorData["LoopMomenta"],
    sectorData["Sectors"]
  ];
  sourceSectors = Lookup[
    byMomentum,
    source["Topology"][[3]],
    Missing["UnknownLoop"]
  ];
  targetSectors = Lookup[
    byMomentum,
    target["Topology"][[3]],
    Missing["UnknownLoop"]
  ];
  If[
    MemberQ[Join[sourceSectors, targetSectors], _Missing],
    Return[{False, "a topology contains a loop absent from Setup"}]
  ];

  checks = Table[
    targetPositions = Flatten @ Position[
      matrix[[i]],
      coefficient_ /; coefficient =!= 0,
      {1},
      Heads -> False
    ];
    If[
      targetPositions === {} ||
        ! AllTrue[
          targetSectors[[targetPositions]],
          SameQ[#, sourceSectors[[i]]] &
        ],
      {False, "loop sectors are mixed"},
      {True, Null}
    ],
    {i, Length[sourceSectors]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, True}
];

topologyPhysicalMapping[
    source_, target_, mapping_Association, sectorData_Association
  ] := Module[
  {
    shift, indexMap, affineCheck, propagatorCheck, cutCheck,
    sectorCheck, verifiedGLIRule
  },

  shift = mapping["LoopMomentumRules"];
  indexMap = topologyGLIIndexMap[
    mapping,
    source["Topology"],
    target["Topology"]
  ];
  If[indexMap === $Failed,
    Return[{False, "GLI rule is not a strict propagator permutation"}]
  ];
  affineCheck = topologyAffineMapping[source, target, shift];
  If[! TrueQ[First[affineCheck]], Return[affineCheck]];
  propagatorCheck = topologyPropagatorMapping[
    source,
    target,
    shift,
    indexMap
  ];
  If[! TrueQ[First[propagatorCheck]], Return[propagatorCheck]];
  cutCheck = topologyCutMapping[source, target, shift, indexMap];
  If[! TrueQ[First[cutCheck]], Return[cutCheck]];
  sectorCheck = topologyLoopSectorMapping[
    source,
    target,
    affineCheck[[2, "LoopMatrix"]],
    sectorData
  ];
  If[! TrueQ[First[sectorCheck]], Return[sectorCheck]];
  verifiedGLIRule = topologyVerifiedGLIRule[
    source["Topology"][[1]],
    target["Topology"][[1]],
    indexMap
  ];
  If[verifiedGLIRule === $Failed,
    Return[{False, "could not construct the verified GLI rule"}]
  ];
  If[
    ! SameQ[
      Replace[mapping["ProbeGLI"], verifiedGLIRule, {0}],
      mapping["MappedProbe"]
    ],
    Return[{False, "verified GLI rule disagrees with candidate mapping"}]
  ];

  {
    True,
    <|
      "Source" -> source["Topology"][[1]],
      "Target" -> target["Topology"][[1]],
      "LoopMomentumRules" -> shift,
      "LoopMomentumMatrix" -> affineCheck[[2, "LoopMatrix"]],
      "LoopTranslationMatrix" ->
        affineCheck[[2, "TranslationMatrix"]],
      "JacobianDeterminant" -> affineCheck[[2, "Determinant"]],
      "PropagatorIndexMap" -> indexMap,
      "CutIndexMap" -> Last[cutCheck],
      "AlgebraicPropagatorStatus" -> Last[propagatorCheck],
      "GLIRule" -> verifiedGLIRule,
      "FeynCalcCandidateGLIRule" -> mapping["GLIRule"]
    |>
  }
];

TopologyEquivalence[topologies_List, setup_Association] := Catch[
  Module[
    {
      names, recordByName, classes = {}, mappings = {},
      rejectedCandidates = {}, partition, classRows, representatives,
      searchStatus, sectorData
    },

    sectorData = Catch[loopSectorsFromSetup[setup], $collinearFailure];
    If[! AssociationQ[sectorData],
      Message[TopologyEquivalence::input, setup];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];

    If[! AllTrue[topologies, topologyRecordQ],
      Message[
        TopologyEquivalence::record,
        FirstCase[
          topologies,
          record_ /; ! topologyRecordQ[record],
          Missing["InvalidRecord"]
        ]
      ];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    If[topologies === {},
      Print @ Grid[
        {{"Representative", "Count", "Members"}, {"None", 0, {}}},
        Frame -> All
      ];
      Return[<|
        "Scope" -> "CutAwareIBP",
        "SearchStatus" -> "Complete",
        "Representatives" -> {},
        "Classes" -> {},
        "Mappings" -> {},
        "GLIRules" -> {},
        "RejectedCandidateMappings" -> {}
      |>]
    ];

    names = #["Topology"][[1]] & /@ topologies;
    If[! DuplicateFreeQ[names],
      Message[TopologyEquivalence::names, names];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    recordByName = AssociationThread[names, topologies];

    partition[records_List] := Module[
      {
        result, rawMappings, rawRepresentatives, parsedMappings,
        representativeNames, mappingSources, mappingTargets,
        mappingsByTarget, currentNames, targetName, sourceMaps,
        representative, members,
        incompatible, check
      },

      If[records === {}, Return[Null]];
      If[Length[records] === 1,
        AppendTo[classes, <|
          "Representative" -> records[[1, "Topology"]][[1]],
          "Members" -> {records[[1, "Topology"]][[1]]},
          "SearchStatus" -> "Singleton"
        |>];
        Return[Null]
      ];
      result = Quiet @ CheckAbort[
        FeynCalc`FCLoopFindTopologyMappings[
          Lookup[records, "Topology"],
          FeynCalc`Momentum -> {},
          FeynCalc`SubtopologyMarker -> False,
          FeynCalc`FCVerbose -> -1
        ],
        $Failed
      ];
      If[
        ! MatchQ[result, {{___List}, {___FeynCalc`FCTopology}}],
        Message[
          TopologyEquivalence::mapping,
          Lookup[records, "Topology"][[All, 1]]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      rawMappings = result[[1]];
      rawRepresentatives = result[[2]];
      parsedMappings = parseTopologyMapping[#, recordByName] & /@
        rawMappings;
      If[AnyTrue[parsedMappings, FailureQ],
        Message[
          TopologyEquivalence::mapping,
          FirstCase[parsedMappings, _Failure]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      currentNames = Lookup[records, "Topology"][[All, 1]];
      representativeNames = rawRepresentatives[[All, 1]];
      mappingSources = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Source"]
      ];
      mappingTargets = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Target"]
      ];
      mappingsByTarget = GroupBy[parsedMappings, #1["Target"] &];
      If[
        ! DuplicateFreeQ[mappingSources] ||
          Sort[Join[mappingSources, representativeNames]] =!=
            Sort[currentNames] ||
          Complement[mappingTargets, representativeNames] =!= {},
        Message[TopologyEquivalence::coverage, currentNames];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];

      Do[
        targetName = rawRepresentatives[[index, 1]];
        representative = recordByName[targetName];
        sourceMaps = Lookup[mappingsByTarget, targetName, {}];
        members = {targetName};
        incompatible = {};
        Do[
          check = topologyPhysicalMapping[
            recordByName[mapping["Source"]],
            representative,
            mapping,
            sectorData
          ];
          If[TrueQ[First[check]],
            AppendTo[members, mapping["Source"]];
            AppendTo[mappings, Last[check]],
            AppendTo[incompatible, recordByName[mapping["Source"]]];
            AppendTo[rejectedCandidates, <|
              "Source" -> mapping["Source"],
              "Candidate" -> targetName,
              "Reason" -> Last[check]
            |>]
          ],
          {mapping, sourceMaps}
        ];
        AppendTo[classes, <|
          "Representative" -> targetName,
          "Members" -> members,
          "SearchStatus" -> If[
            incompatible === {},
            "FeynCalcWitnessesAccepted",
            "ConservativelySeparated"
          ]
        |>];
        partition[incompatible],
        {index, Length[rawRepresentatives]}
      ]
    ];

    partition[topologies];
    classRows = {
      #["Representative"],
      Length[#["Members"]],
      #["Members"]
    } & /@ classes;
    Print @ Grid[
      Prepend[classRows, {"Representative", "Count", "Members"}],
      Frame -> All
    ];
    representatives = recordByName /@ Lookup[classes, "Representative"];
    searchStatus = If[
      rejectedCandidates === {},
      "AllFeynCalcCandidatesAccepted",
      "ConservativelySeparated"
    ];

    <|
      "Scope" -> "CutAwareIBP",
      "SearchStatus" -> searchStatus,
      "Representatives" -> representatives,
      "Classes" -> classes,
      "Mappings" -> mappings,
      "GLIRules" -> If[mappings === {}, {}, Lookup[mappings, "GLIRule"]],
      "RejectedCandidateMappings" -> rejectedCandidates
    |>
  ],
  $topologyEquivalenceFailure
];

TopologyEquivalence[arguments___] := (
  Message[TopologyEquivalence::input, HoldForm[TopologyEquivalence[arguments]]];
  $Failed
);
