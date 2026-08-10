(* Canonical cut-aware integral families (Design/CanonicalFamilies.md).

   A topology record is reduced to a canonical key by the marker-mass trick:
   every cut slot receives a fictitious marker mass, so no Pak ordering can
   mix cut and uncut propagators, and the key is the SHA-256 of the canonical
   characteristic polynomial together with the sorted cut directions.

   Equal keys make two records candidates only. The propagator permutation is
   read off the two Pak orderings, the affine momentum map is obtained from
   FCLoopFindMomentumShifts, and the pair is then verified by the existing
   topologyPhysicalMapping before any GLI rule is emitted. A candidate that
   fails verification is logged and the record opens a new canonical family
   with status "CollisionRegistered"; an unverified rule is never returned. *)


CanonicalFamilyRegistryCreate::setup =
  "A canonical family registry needs a process card that declares the phase-space, integrated, forward-loop and conjugate-loop momenta, but received `1`.";

CanonicalizeTopologyRecord::record =
  "CanonicalizeTopologyRecord expects a complete cut-aware topology record, a canonical family registry and optionally a process card, but received `1`.";

CanonicalizeTopologyRecord::registry =
  "The canonical family registry is malformed: `1`.";

CanonicalizeTopologyRecord::sectors =
  "The canonical family registry carries no loop sector data, or the supplied process card disagrees with it. Create the registry with CanonicalFamilyRegistryCreate[setup].";

CanonicalizeTopologyRecord::pak =
  "Could not construct the cut-aware Pak canonical form of topology `1`.";

CanonicalizeTopologyRecord::identity =
  "Registering topology `1` as its own canonical family failed verification: `2`.";

CanonicalizeTopologyRecords::input =
  "CanonicalizeTopologyRecords expects a list of topology records together with a process card or a registry, or a list of saved pre-IBP pair artifacts sharing one loop-sector partition, but received `1`.";


$canonicalFamilyRegistryVersion = 1;

$canonicalFamilyPrefix = "CF";

$canonicalFamilyFailure = "FeynFacetCanonicalFamilyFailure";

(* Fictitious marker mass injected into cut slots. It never leaves this
   module: it only enters the Pak polynomial used to build the key. *)
canonicalCutMarker;


canonicalFamilyName[index_Integer] :=
  Symbol["Global`" <> $canonicalFamilyPrefix <> ToString[index]];

canonicalFamilyCollisionName[index_Integer, variant_Integer] :=
  Symbol[
    "Global`" <> $canonicalFamilyPrefix <> ToString[index] <>
      "c" <> ToString[variant]
  ];


(* Structural gate. Every full topology record (topologyRecordQ) satisfies it;
   it deliberately omits the record bookkeeping and the analytic context,
   which canonicalization never reads, so that saved pre-IBP artifacts remain
   usable. Physical correctness is not weakened: every emitted rule still has
   to pass topologyPhysicalMapping. *)
canonicalRecordQ[record_Association] := TrueQ @ Quiet @ CheckAbort[Module[
  {
    topology, cutMomenta, cutIndices, cutDirections, baseGLI,
    propagatorInfo, propagatorMomenta, propagatorTypes, propagatorPowers
  },

  If[
    ! ContainsAll[
      Keys[record],
      {"Topology", "BaseGLI", "CutMomenta", "CutIndices", "CutDirections"}
    ],
    Return[False]
  ];
  topology = record["Topology"];
  If[! MatchQ[topology, _FeynCalc`FCTopology], Return[False]];
  cutMomenta = record["CutMomenta"];
  cutIndices = record["CutIndices"];
  cutDirections = record["CutDirections"];
  baseGLI = record["BaseGLI"];
  If[
    ! MatchQ[baseGLI, _FeynCalc`GLI] ||
      baseGLI[[1]] =!= topology[[1]] ||
      Length[baseGLI[[2]]] =!= Length[topology[[2]]] ||
      ! VectorQ[baseGLI[[2]], IntegerQ],
    Return[False]
  ];
  If[
    ! ListQ[cutMomenta] || ! ListQ[cutIndices] || ! ListQ[cutDirections],
    Return[False]
  ];
  If[
    ! AllTrue[cutIndices, IntegerQ[#] && 1 <= # <= Length[topology[[2]]] &],
    Return[False]
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

canonicalRecordQ[_] := False;


canonicalMarkCutSlots[topology_FeynCalc`FCTopology, cutIndices_List] := Module[
  {marked},

  marked = ReplacePart[
    topology,
    2 -> MapIndexed[
      Function[{propagator, position},
        If[MemberQ[cutIndices, First[position]],
          propagator /. FeynCalc`StandardPropagatorDenominator[
              momentum_, product_, mass_, rest_
            ] :> FeynCalc`StandardPropagatorDenominator[
              momentum, product, mass - canonicalCutMarker, rest
            ],
          propagator
        ]
      ],
      topology[[2]]
    ]
  ];
  If[
    Length[Select[marked[[2]], ! FreeQ[#, canonicalCutMarker] &]] =!=
      Length[cutIndices],
    Return[$Failed]
  ];
  marked
];

canonicalMarkCutSlots[_, _] := $Failed;


(* The default Function option of FCLoopToPakForm discards the Pak ordering
   sigma. Restoring it gives the propagator permutation exactly, instead of
   matching the reordered propagators back onto the topology by hand. *)
canonicalPakForm[topology_FeynCalc`FCTopology, cutIndices_List] := Module[
  {marked, raw, polynomial, order, count},

  count = Length[topology[[2]]];
  marked = canonicalMarkCutSlots[topology, cutIndices];
  If[marked === $Failed, Return[$Failed]];
  raw = Quiet @ CheckAbort[
    FeynCalc`FCLoopToPakForm[
      marked,
      System`Names -> FeynCalc`FCGV["x"],
      System`Head -> canonicalPakHead,
      System`Function -> Function[
        {uPolynomial, fPolynomial, characteristic, powers, head, integral,
          sigma},
        {integral, head[ExpandAll[characteristic], Transpose[powers], sigma]}
      ],
      FeynCalc`FCVerbose -> -1
    ],
    $Failed
  ];
  If[! MatchQ[raw, {_, canonicalPakHead[_, _List, _List]}], Return[$Failed]];
  polynomial = raw[[2, 1]];
  order = raw[[2, 3]];
  If[! VectorQ[order, IntegerQ] || Sort[order] =!= Range[count],
    Return[$Failed]
  ];
  If[! exactDataQ[polynomial] || ! FreeQ[polynomial, canonicalPakHead],
    Return[$Failed]
  ];
  <|"Polynomial" -> polynomial, "Order" -> order|>
];

canonicalPakForm[_, _] := $Failed;


canonicalFamilyKey[polynomial_, cutDirections_List] :=
  Hash[{polynomial, Sort[cutDirections]}, "SHA256", "HexString"];


canonicalFamilyRegistryQ[registry_Association] :=
  Lookup[registry, "Type", None] === "FeynFacetCanonicalFamilyRegistry" &&
    Lookup[registry, "Version", None] === $canonicalFamilyRegistryVersion &&
    ListQ[Lookup[registry, "Families", None]] &&
    AssociationQ[Lookup[registry, "Index", None]] &&
    ListQ[Lookup[registry, "Rejected", None]] &&
    KeyExistsQ[registry, "SectorData"];

canonicalFamilyRegistryQ[_] := False;


CanonicalFamilyRegistryCreate[] := <|
  "Type" -> "FeynFacetCanonicalFamilyRegistry",
  "Version" -> $canonicalFamilyRegistryVersion,
  "Families" -> {},
  "Index" -> <||>,
  "SectorData" -> Missing["NotSet"],
  "Rejected" -> {}
|>;

CanonicalFamilyRegistryCreate[setup_Association] := Module[{sectorData},
  sectorData = Catch[loopSectorsFromSetup[setup], $collinearFailure];
  If[! AssociationQ[sectorData],
    Message[CanonicalFamilyRegistryCreate::setup, setup];
    Return[$Failed]
  ];
  Join[CanonicalFamilyRegistryCreate[], <|"SectorData" -> sectorData|>]
];

CanonicalFamilyRegistryCreate[arguments___] := (
  Message[
    CanonicalFamilyRegistryCreate::setup,
    HoldForm[CanonicalFamilyRegistryCreate[arguments]]
  ];
  $Failed
);


(* The minimal record topologyPhysicalMapping needs on the target side. *)
canonicalEntryTarget[entry_Association] := <|
  "Topology" -> entry["Topology"],
  "CutMomenta" -> entry["CutMomenta"],
  "CutIndices" -> entry["CutIndices"],
  "CutDirections" -> entry["CutDirections"]
|>;


(* Compose the two Pak orderings: canonical position j is occupied by source
   propagator sourceOrder[[j]] and by target propagator targetOrder[[j]]. *)
canonicalIndexMap[sourceOrder_List, targetOrder_List] := Module[{map},
  If[Length[sourceOrder] =!= Length[targetOrder], Return[$Failed]];
  map = ConstantArray[0, Length[sourceOrder]];
  map[[sourceOrder]] = targetOrder;
  If[Sort[map] =!= Range[Length[map]], Return[$Failed]];
  map
];

canonicalIndexMap[_, _] := $Failed;


canonicalInvertShift[shift_List, loops_List] := Module[
  {variables, image, solution},

  variables = Table[Unique["canonicalLoop$"], {Length[loops]}];
  image = Expand[(loops /. shift) /. Thread[loops -> variables]];
  solution = Quiet @ Check[Solve[Thread[image == loops], variables], $Failed];
  If[! MatchQ[solution, {{__Rule}}] || ! exactDataQ[solution],
    Return[$Failed]
  ];
  Thread[loops -> Expand[variables /. First[solution]]]
];


canonicalMomentumShiftFallback[from_, to_] := Module[
  {raw, mappings, direct, reverse},

  raw = Quiet @ CheckAbort[
    FeynCalc`FCLoopFindTopologyMappings[
      {from, to},
      FeynCalc`Momentum -> {},
      FeynCalc`SubtopologyMarker -> False,
      FeynCalc`FCVerbose -> -1
    ],
    $Failed
  ];
  If[! MatchQ[raw, {{___List}, {___FeynCalc`FCTopology}}], Return[$Failed]];
  mappings = Cases[
    raw[[1]],
    {_FeynCalc`FCTopology, {(_Rule | _RuleDelayed) ...}, _}
  ];
  direct = FirstCase[
    mappings,
    {topology_, shift_, _} /; topology[[1]] === from[[1]] :> shift,
    $Failed
  ];
  If[MatchQ[direct, {(_Rule | _RuleDelayed) ..}], Return[direct]];
  reverse = FirstCase[
    mappings,
    {topology_, shift_, _} /; topology[[1]] === to[[1]] :> shift,
    $Failed
  ];
  If[MatchQ[reverse, {(_Rule | _RuleDelayed) ..}],
    Return[canonicalInvertShift[reverse, from[[3]]]]
  ];
  $Failed
];


canonicalMomentumShift[
    source_FeynCalc`FCTopology, sourceOrder_List,
    target_FeynCalc`FCTopology, targetOrder_List
  ] := Module[{from, to, raw},

  from = ReplacePart[source, 2 -> source[[2]][[sourceOrder]]];
  to = ReplacePart[target, 2 -> target[[2]][[targetOrder]]];
  raw = Quiet @ CheckAbort[
    FeynCalc`FCLoopFindMomentumShifts[
      {from},
      to,
      System`Abort -> False,
      FeynCalc`FCVerbose -> -1
    ],
    $Failed
  ];
  If[MatchQ[raw, {{(_Rule | _RuleDelayed) ..}}], Return[raw[[1]]]];
  canonicalMomentumShiftFallback[from, to]
];

canonicalMomentumShift[__] := $Failed;


canonicalCandidateMapping[
    sourceName_, targetName_, indexMap_List, shift_List
  ] := Module[{rule, indices, probe, mapped},

  rule = topologyVerifiedGLIRule[sourceName, targetName, indexMap];
  If[rule === $Failed, Return[$Failed]];
  indices = Table[Unique["canonicalIndex$"], {Length[indexMap]}];
  probe = FeynCalc`GLI[sourceName, indices];
  mapped = Replace[probe, rule, {0}];
  If[! MatchQ[mapped, _FeynCalc`GLI] || mapped === probe, Return[$Failed]];
  <|
    "Source" -> sourceName,
    "Target" -> targetName,
    "LoopMomentumRules" -> shift,
    "GLIRule" -> rule,
    "ProbeGLI" -> probe,
    "ProbeIndices" -> indices,
    "MappedProbe" -> mapped
  |>
];

canonicalCandidateMapping[__] := $Failed;


canonicalMappingAttempt[
    record_Association, pak_Association, entry_Association,
    sectorData_Association
  ] := Module[{topology, name, indexMap, shift, mapping, check},

  topology = record["Topology"];
  name = topology[[1]];
  indexMap = canonicalIndexMap[pak["Order"], entry["Order"]];
  If[indexMap === $Failed,
    Return[<|
      "Verified" -> False,
      "Entry" -> entry,
      "Reason" -> "the Pak orderings are not a propagator permutation"
    |>]
  ];
  shift = canonicalMomentumShift[
    topology, pak["Order"], entry["Topology"], entry["Order"]
  ];
  If[shift === $Failed,
    Return[<|
      "Verified" -> False,
      "Entry" -> entry,
      "Reason" -> "no loop momentum shift onto the canonical family"
    |>]
  ];
  mapping = canonicalCandidateMapping[name, entry["Name"], indexMap, shift];
  If[mapping === $Failed,
    Return[<|
      "Verified" -> False,
      "Entry" -> entry,
      "Reason" -> "could not build the candidate GLI rule"
    |>]
  ];
  check = topologyPhysicalMapping[
    record,
    canonicalEntryTarget[entry],
    mapping,
    sectorData
  ];
  If[! TrueQ[First[check]],
    Return[<|
      "Verified" -> False,
      "Entry" -> entry,
      "Reason" -> Last[check]
    |>]
  ];
  <|"Verified" -> True, "Entry" -> entry, "Payload" -> Last[check]|>
];


canonicalRegisterFamily[
    record_Association, pak_Association, key_String, registry_Association,
    sectorData_Association, collisions_Integer
  ] := Module[
  {
    topology, name, index, canonicalName, entry, indexMap, shift,
    mapping, check
  },

  topology = record["Topology"];
  name = topology[[1]];
  index = Length[registry["Families"]] + 1;
  canonicalName = If[collisions === 0,
    canonicalFamilyName[index],
    canonicalFamilyCollisionName[index, collisions]
  ];
  entry = <|
    "Name" -> canonicalName,
    "Key" -> key,
    "Topology" -> ReplacePart[topology, 1 -> canonicalName],
    "CutMomenta" -> record["CutMomenta"],
    "CutIndices" -> record["CutIndices"],
    "CutDirections" -> record["CutDirections"],
    "Order" -> pak["Order"],
    "FirstSource" -> name
  |>;
  indexMap = Range[Length[topology[[2]]]];
  shift = (# -> #) & /@ topology[[3]];
  mapping = canonicalCandidateMapping[name, canonicalName, indexMap, shift];
  check = If[mapping === $Failed,
    {False, "could not build the identity GLI rule"},
    topologyPhysicalMapping[
      record,
      canonicalEntryTarget[entry],
      mapping,
      sectorData
    ]
  ];
  If[! TrueQ[First[check]],
    Message[CanonicalizeTopologyRecord::identity, name, Last[check]];
    Return[$Failed]
  ];
  <|"Entry" -> entry, "Payload" -> Last[check], "Name" -> canonicalName|>
];


canonicalizeVerifiedRecord[
    record_Association, registry_Association, sectorData_Association
  ] := Module[
  {
    topology, name, pak, key, positions, attempts, accepted, rejected,
    registration, entry, index, updated, status
  },

  topology = record["Topology"];
  name = topology[[1]];
  pak = canonicalPakForm[topology, record["CutIndices"]];
  If[pak === $Failed,
    Message[CanonicalizeTopologyRecord::pak, name];
    Return[$Failed]
  ];
  key = canonicalFamilyKey[pak["Polynomial"], record["CutDirections"]];
  positions = Lookup[registry["Index"], key, {}];
  attempts = Table[
    canonicalMappingAttempt[
      record,
      pak,
      registry["Families"][[position]],
      sectorData
    ],
    {position, positions}
  ];
  accepted = FirstCase[
    attempts,
    attempt_ /; TrueQ[attempt["Verified"]],
    Missing["NoCanonicalFamily"]
  ];
  rejected = Cases[
    attempts,
    attempt_ /; ! TrueQ[attempt["Verified"]] :> <|
      "Source" -> name,
      "Candidate" -> attempt[["Entry", "Name"]],
      "Key" -> key,
      "Reason" -> attempt["Reason"]
    |>
  ];

  If[! MissingQ[accepted],
    Return[<|
      "Registry" -> registry,
      "Name" -> accepted[["Entry", "Name"]],
      "Key" -> key,
      "GLIRule" -> accepted[["Payload", "GLIRule"]],
      "Status" -> "Mapped",
      "Mapping" -> Join[
        accepted["Payload"],
        <|
          "Key" -> key,
          "Name" -> accepted[["Entry", "Name"]],
          "Status" -> "Mapped"
        |>
      ]
    |>]
  ];

  status = If[positions === {}, "Registered", "CollisionRegistered"];
  registration = canonicalRegisterFamily[
    record, pak, key, registry, sectorData, Length[positions]
  ];
  If[registration === $Failed, Return[$Failed]];
  entry = registration["Entry"];
  index = Length[registry["Families"]] + 1;
  updated = Join[
    registry,
    <|
      "Families" -> Append[registry["Families"], entry],
      "Index" -> Append[registry["Index"], key -> Append[positions, index]],
      "Rejected" -> Join[registry["Rejected"], rejected]
    |>
  ];
  <|
    "Registry" -> updated,
    "Name" -> entry["Name"],
    "Key" -> key,
    "GLIRule" -> registration[["Payload", "GLIRule"]],
    "Status" -> status,
    "Mapping" -> Join[
      registration["Payload"],
      <|"Key" -> key, "Name" -> entry["Name"], "Status" -> status|>
    ]
  |>
];


CanonicalizeTopologyRecord[record_, registry_] := Module[{sectorData},
  If[! canonicalFamilyRegistryQ[registry],
    Message[CanonicalizeTopologyRecord::registry, registry];
    Return[$Failed]
  ];
  sectorData = registry["SectorData"];
  If[! AssociationQ[sectorData],
    Message[CanonicalizeTopologyRecord::sectors];
    Return[$Failed]
  ];
  If[! canonicalRecordQ[record],
    Message[CanonicalizeTopologyRecord::record, record];
    Return[$Failed]
  ];
  canonicalizeVerifiedRecord[record, registry, sectorData]
];

CanonicalizeTopologyRecord[record_, registry_, setup_Association] := Module[
  {sectorData},

  If[! canonicalFamilyRegistryQ[registry],
    Message[CanonicalizeTopologyRecord::registry, registry];
    Return[$Failed]
  ];
  sectorData = Catch[loopSectorsFromSetup[setup], $collinearFailure];
  If[! AssociationQ[sectorData],
    Message[CanonicalFamilyRegistryCreate::setup, setup];
    Return[$Failed]
  ];
  If[
    AssociationQ[registry["SectorData"]] &&
      registry["SectorData"] =!= sectorData,
    Message[CanonicalizeTopologyRecord::sectors];
    Return[$Failed]
  ];
  CanonicalizeTopologyRecord[
    record,
    Join[registry, <|"SectorData" -> sectorData|>]
  ]
];

CanonicalizeTopologyRecord[arguments___] := (
  Message[
    CanonicalizeTopologyRecord::record,
    HoldForm[CanonicalizeTopologyRecord[arguments]]
  ];
  $Failed
);


canonicalizeRecordList[records_List, initialRegistry_Association] := Catch[
  Module[
    {registry = initialRegistry, rules = {}, mappings = {}, result, classes},

    Do[
      result = CanonicalizeTopologyRecord[record, registry];
      If[! AssociationQ[result], Throw[$Failed, $canonicalFamilyFailure]];
      registry = result["Registry"];
      AppendTo[rules, result["GLIRule"]];
      AppendTo[mappings, result["Mapping"]],
      {record, records}
    ];

    classes = Function[entry,
      <|
        "Name" -> entry["Name"],
        "Key" -> entry["Key"],
        "FirstSource" -> entry["FirstSource"],
        "Members" -> Cases[
          mappings,
          mapping_ /; mapping["Name"] === entry["Name"] :> mapping["Source"]
        ]
      |>
    ] /@ registry["Families"];

    Print @ Grid[
      Prepend[
        {#["Name"], Length[#["Members"]], #["FirstSource"]} & /@ classes,
        {"Family", "Count", "FirstSource"}
      ],
      Frame -> All
    ];

    <|
      "Registry" -> registry,
      "Rules" -> rules,
      "Classes" -> classes,
      "Rejected" -> registry["Rejected"],
      "Mappings" -> mappings
    |>
  ],
  $canonicalFamilyFailure
];


CanonicalizeTopologyRecords[records_List, context_Association] := Module[
  {registry},

  registry = If[canonicalFamilyRegistryQ[context],
    context,
    CanonicalFamilyRegistryCreate[context]
  ];
  If[! canonicalFamilyRegistryQ[registry], Return[$Failed]];
  If[! AssociationQ[registry["SectorData"]],
    Message[CanonicalizeTopologyRecord::sectors];
    Return[$Failed]
  ];
  canonicalizeRecordList[records, registry]
];

(* Convenience fold over saved pre-IBP pair artifacts. Topology records carry
   no process card, so the loop sectors are taken from the artifacts, which
   must all describe the same loop-sector partition. *)
CanonicalizeTopologyRecords[artifacts_List] := Module[{sectors, records},
  If[
    artifacts === {} ||
      ! AllTrue[
        artifacts,
        AssociationQ[#] && AssociationQ[Lookup[#, "Setup", None]] &&
          ListQ[Lookup[#, "Topologies", None]] &
      ],
    Message[
      CanonicalizeTopologyRecords::input,
      HoldForm[CanonicalizeTopologyRecords[artifacts]]
    ];
    Return[$Failed]
  ];
  sectors = DeleteDuplicates[
    Catch[loopSectorsFromSetup[#], $collinearFailure] & /@
      Lookup[artifacts, "Setup"]
  ];
  If[Length[sectors] =!= 1 || ! AssociationQ[First[sectors]],
    Message[
      CanonicalizeTopologyRecords::input,
      HoldForm[CanonicalizeTopologyRecords[artifacts]]
    ];
    Return[$Failed]
  ];
  records = Join @@ Lookup[artifacts, "Topologies"];
  CanonicalizeTopologyRecords[records, First[Lookup[artifacts, "Setup"]]]
];

CanonicalizeTopologyRecords[arguments___] := (
  Message[
    CanonicalizeTopologyRecords::input,
    HoldForm[CanonicalizeTopologyRecords[arguments]]
  ];
  $Failed
);
