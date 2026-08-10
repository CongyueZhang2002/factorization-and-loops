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
  (* The rule has to fire and to land on the canonical family. Firing is
     tested on the pattern, not on the image: canonicalizing already
     canonical artifacts registers a family under the name its own source
     already carries, and there the verified rule is the identity, so the
     image legitimately equals the probe. *)
  If[
    ! MatchQ[mapped, _FeynCalc`GLI] ||
      ! MatchQ[probe, First[rule]] ||
      mapped[[1]] =!= targetName,
    Return[$Failed]
  ];
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


(* ------------------------------------------------------------------ *)
(* Post-pass over saved pre-IBP pair artifacts                         *)
(* (Design/CanonicalFamiliesIntegration.md).                           *)
(*                                                                     *)
(* Pair generation runs on parallel subkernels, so the registry is not *)
(* built during generation but folded here, sequentially, in sorted    *)
(* file order: the registry order, the family numbering and therefore  *)
(* the registry fingerprint are deterministic functions of the input   *)
(* artifacts alone.                                                    *)
(* ------------------------------------------------------------------ *)

CanonicalizePairArtifacts::input =
  "CanonicalizePairArtifacts expects a nonempty list of saved pre-IBP pair artifact files and an output directory, but received `1`.";

CanonicalizePairArtifacts::artifact =
  "`1` is missing or is not a valid saved pre-IBP pair artifact.";

CanonicalizePairArtifacts::records =
  "The topology records of the supplied pair artifacts could not be canonicalized.";

CanonicalizePairArtifacts::collision =
  "`1` topology record(s) opened a colliding canonical family. Canonicalization is fail-closed; pass \"AllowCollisions\" -> True to accept them.";

CanonicalizePairArtifacts::rule =
  "The verified GLI rule of topology record `1` does not map it onto its canonical family.";

CanonicalizePairArtifacts::directory =
  "Could not create the output directory `1`.";

CanonicalizePairArtifacts::pair =
  "The canonicalized artifact of `1` is invalid: `2`.";

CanonicalizePairArtifacts::write =
  "Could not write and verify `1`.";


(* Family-intrinsic data of one canonical record.

   A canonicalized artifact carries ONE record per canonical family, so the
   record can no longer be the image of one partial-fraction term: several
   records of one pair, and records of different pairs, share a family while
   their BaseGLI powers and FamilyCoefficient differ. The record therefore
   declares the family itself: the corner integral of the propagator slots
   that the family's members actually raise, with unit coefficient. This is
   the only choice that is a function of the family alone, which is what
   makes the identical records of different pairs deduplicable downstream
   (ibpInputData) and canonicalization idempotent. The integrals really used
   by the pair are carried, exactly, by the rewritten Integrand. *)
canonicalActiveSlots[gli_FeynCalc`GLI] := Flatten @ Position[
  gli[[2]],
  _Integer?Positive,
  {1},
  Heads -> False
];

canonicalUnitBaseGLI[name_, slots_List, count_Integer] := FeynCalc`GLI[
  name,
  Table[If[MemberQ[slots, slot], 1, 0], {slot, count}]
];

canonicalPairRecord[
    entry_Association,
    slots_List,
    pair_Association,
    context_Association
  ] := <|
  "Type" -> "FeynFacetTopologyRecord",
  "Version" -> 3,
  "DiagramPair" -> pair,
  "Topology" -> entry["Topology"],
  "BaseGLI" -> canonicalUnitBaseGLI[
    entry["Name"],
    slots,
    Length[entry["Topology"][[2]]]
  ],
  "FamilyCoefficient" -> 1,
  "CutMomenta" -> entry["CutMomenta"],
  "CutIndices" -> entry["CutIndices"],
  "CutDirections" -> entry["CutDirections"],
  "CanonicalKey" -> entry["Key"],
  "AnalyticContext" -> context
|>;


(* The fingerprint identifies the registry as a mathematical object: the
   per-entry FirstSource records which topology happened to open a family
   and is dropped, so canonicalizing already canonical artifacts reproduces
   it. There are no timestamps in the registry itself. *)
canonicalRegistryPayload[registry_Association] := <|
  "Type" -> Lookup[registry, "Type", None],
  "Version" -> Lookup[registry, "Version", None],
  "Families" -> (
    KeyDrop[#, {"FirstSource", "Created"}] & /@
      Lookup[registry, "Families", {}]
  ),
  "Index" -> Lookup[registry, "Index", <||>],
  "SectorData" -> Lookup[registry, "SectorData", Missing["NotSet"]],
  "Rejected" -> Lookup[registry, "Rejected", {}]
|>;

canonicalRegistryFingerprint[registry_Association] :=
  reductionFingerprint[canonicalRegistryPayload[registry]];


canonicalizeOnePairArtifact[
    artifact_Association,
    rules_List,
    names_List,
    entryByName_Association,
    slotsByName_Association,
    output_String,
    fingerprint_String
  ] := Module[
  {pair, context, parts, mapped, integrand, used, imageFamilies, records},

  pair = artifact["Pair"];
  context = artifact["AnalyticContext"];
  parts = linearIntegralSum[artifact["Integrand"]];
  If[! linearIntegralSumQ[parts],
    Return[{$Failed, "the integrand is not a linear combination of GLIs"}]
  ];
  mapped = linearMapIntegrals[parts, rules];
  If[! linearIntegralSumQ[mapped],
    Return[{$Failed, "the integrand GLIs could not be mapped"}]
  ];
  integrand = linearToExpression[mapped];
  used = DeleteDuplicates[names];
  imageFamilies = DeleteDuplicates[First /@ Keys[mapped["Terms"]]];
  If[! ContainsAll[used, imageFamilies],
    Return[{$Failed, "the rewritten integrand keeps a non-canonical family"}]
  ];
  records = Function[name,
    canonicalPairRecord[
      entryByName[name],
      slotsByName[name],
      pair,
      context
    ]
  ] /@ used;
  If[! AllTrue[records, topologyRecordQ[#, pair] &],
    Return[{$Failed, "a canonical topology record is invalid"}]
  ];
  If[! AllTrue[records, SameQ[#["AnalyticContext"], context] &],
    Return[{$Failed, "a canonical topology record carries a foreign context"}]
  ];
  {
    Join[
      artifact,
      <|
        "Created" -> DateString[{"ISODate", "T", "Time"}],
        "ResultDirectory" -> output,
        "Integrand" -> integrand,
        "Topologies" -> records,
        "CanonicalRegistryFingerprint" -> fingerprint
      |>
    ],
    "canonicalized"
  }
];


canonicalPutArtifact[result_Association, file_String] := Module[
  {temporary, saved, valid},

  temporary = file <> ".tmp-" <> StringReplace[CreateUUID[], "-" -> ""];
  If[
    Quiet @ Check[
      Put[result, temporary];
      FileExistsQ[temporary] && FileByteCount[temporary] > 0,
      False
    ] =!= True,
    Quiet @ Check[DeleteFile[temporary], Null];
    Return[$Failed]
  ];
  saved = Quiet @ Check[Get[temporary], $Failed];
  valid = validPreIBPResultQ[saved] && SameQ[saved, result];
  Clear[saved];
  If[! TrueQ[valid],
    Quiet @ Check[DeleteFile[temporary], Null];
    Return[$Failed]
  ];
  If[
    Quiet @ Check[
      RenameFile[temporary, file, OverwriteTarget -> True];
      True,
      False
    ] =!= True,
    Quiet @ Check[DeleteFile[temporary], Null];
    Return[$Failed]
  ];
  file
];


Options[CanonicalizePairArtifacts] = {"AllowCollisions" -> False};

CanonicalizePairArtifacts[
    pairFiles_List,
    outputDirectory_String,
    options : OptionsPattern[]
  ] := Catch[
  Module[
    {
      files, artifacts, counts, allRecords, sourceNames, run, registry,
      families, mappings, rules, names, statuses, collisions, mappedBases,
      slotsByName, entryByName, fingerprint, output, pairDirectory,
      rulesByPair, namesByPair, canonicalized, written, registryFile,
      manifestFile, registryRecord, manifest, verification
    },

    If[
      pairFiles === {} || ! AllTrue[pairFiles, StringQ] ||
        StringLength[StringTrim[outputDirectory]] === 0,
      Message[
        CanonicalizePairArtifacts::input,
        HoldForm[CanonicalizePairArtifacts[pairFiles, outputDirectory]]
      ];
      Throw[$Failed, $canonicalFamilyFailure]
    ];

    files = Sort[ExpandFileName /@ pairFiles];
    Do[
      If[! FileExistsQ[file],
        Message[CanonicalizePairArtifacts::artifact, file];
        Throw[$Failed, $canonicalFamilyFailure]
      ],
      {file, files}
    ];
    artifacts = (Quiet @ Check[Get[#], $Failed]) & /@ files;
    Do[
      If[! validPreIBPResultQ[artifacts[[position]]],
        Message[CanonicalizePairArtifacts::artifact, files[[position]]];
        Throw[$Failed, $canonicalFamilyFailure]
      ],
      {position, Length[files]}
    ];

    output = FileNameJoin @ FileNameSplit @ ExpandFileName[outputDirectory];
    pairDirectory = FileNameJoin[{output, "Pairs"}];
    If[! DirectoryQ[pairDirectory],
      Quiet @ Check[
        CreateDirectory[pairDirectory, CreateIntermediateDirectories -> True],
        Null
      ]
    ];
    If[! DirectoryQ[pairDirectory],
      Message[CanonicalizePairArtifacts::directory, pairDirectory];
      Throw[$Failed, $canonicalFamilyFailure]
    ];

    counts = Length[#["Topologies"]] & /@ artifacts;
    allRecords = Join @@ Lookup[artifacts, "Topologies"];
    sourceNames = #["Topology"][[1]] & /@ allRecords;

    run = CanonicalizeTopologyRecords[artifacts];
    If[! AssociationQ[run] || ! canonicalFamilyRegistryQ[run["Registry"]],
      Message[CanonicalizePairArtifacts::records];
      Throw[$Failed, $canonicalFamilyFailure]
    ];
    registry = run["Registry"];
    families = registry["Families"];
    mappings = run["Mappings"];
    rules = run["Rules"];
    names = Lookup[mappings, "Name"];
    statuses = Lookup[mappings, "Status"];
    collisions = Count[statuses, "CollisionRegistered"];
    If[collisions > 0 && ! TrueQ[OptionValue["AllowCollisions"]],
      Message[CanonicalizePairArtifacts::collision, collisions];
      Throw[$Failed, $canonicalFamilyFailure]
    ];

    (* Each record's BaseGLI moves to its canonical family through the same
       verified rule that rewrites the integrand; only the propagator slots
       are permuted, the scalar FamilyCoefficient is untouched by it. *)
    mappedBases = MapThread[
      Replace[#1["BaseGLI"], #2, {0}] &,
      {allRecords, rules}
    ];
    Do[
      If[
        ! MatchQ[mappedBases[[position]], _FeynCalc`GLI] ||
          mappedBases[[position]][[1]] =!= names[[position]],
        Message[CanonicalizePairArtifacts::rule, sourceNames[[position]]];
        Throw[$Failed, $canonicalFamilyFailure]
      ],
      {position, Length[allRecords]}
    ];
    slotsByName = Merge[
      MapThread[#1 -> canonicalActiveSlots[#2] &, {names, mappedBases}],
      Union @@ # &
    ];

    entryByName = AssociationThread[Lookup[families, "Name"], families];
    fingerprint = canonicalRegistryFingerprint[registry];
    rulesByPair = TakeList[rules, counts];
    namesByPair = TakeList[names, counts];

    canonicalized = Table[
      canonicalizeOnePairArtifact[
        artifacts[[position]],
        rulesByPair[[position]],
        namesByPair[[position]],
        entryByName,
        slotsByName,
        output,
        fingerprint
      ],
      {position, Length[files]}
    ];
    Do[
      If[First[canonicalized[[position]]] === $Failed,
        Message[
          CanonicalizePairArtifacts::pair,
          files[[position]],
          Last[canonicalized[[position]]]
        ];
        Throw[$Failed, $canonicalFamilyFailure]
      ],
      {position, Length[files]}
    ];

    written = Table[
      canonicalPutArtifact[
        First[canonicalized[[position]]],
        FileNameJoin[{pairDirectory, FileNameTake[files[[position]]]}]
      ],
      {position, Length[files]}
    ];
    Do[
      If[written[[position]] === $Failed,
        Message[
          CanonicalizePairArtifacts::write,
          FileNameJoin[{pairDirectory, FileNameTake[files[[position]]]}]
        ];
        Throw[$Failed, $canonicalFamilyFailure]
      ],
      {position, Length[files]}
    ];

    registryFile = FileNameJoin[{output, "CanonicalRegistry.wxf"}];
    manifestFile = FileNameJoin[{output, "CanonicalRegistry.wl"}];
    registryRecord = <|
      "Type" -> "FeynFacetCanonicalFamilyRegistryRecord",
      "Version" -> $canonicalFamilyRegistryVersion,
      "Created" -> DateString[{"ISODate", "T", "Time"}],
      "Fingerprint" -> fingerprint,
      "OutputDirectory" -> output,
      "PairFiles" -> FileNameTake /@ files,
      "Registry" -> registry,
      "Classes" -> run["Classes"],
      "Rejected" -> run["Rejected"],
      "Mappings" -> mappings,
      "GLIRules" -> rules,
      "SourceNames" -> sourceNames,
      "CanonicalNames" -> names,
      "Statuses" -> statuses,
      "FamilyBaseGLI" -> Association[
        Function[entry,
          entry["Name"] -> canonicalUnitBaseGLI[
            entry["Name"],
            slotsByName[entry["Name"]],
            Length[entry["Topology"][[2]]]
          ]
        ] /@ families
      ]
    |>;
    If[coefficientWriteRecord[registryFile, registryRecord] === $Failed,
      Message[CanonicalizePairArtifacts::write, registryFile];
      Throw[$Failed, $canonicalFamilyFailure]
    ];
    verification = Quiet @ Check[coefficientReadRecord[registryFile], $Failed];
    If[verification =!= registryRecord,
      Message[CanonicalizePairArtifacts::write, registryFile];
      Throw[$Failed, $canonicalFamilyFailure]
    ];
    Clear[verification];

    manifest = <|
      "Type" -> "FeynFacetCanonicalFamilyManifest",
      "Version" -> $canonicalFamilyRegistryVersion,
      "Created" -> registryRecord["Created"],
      "Fingerprint" -> fingerprint,
      "OutputDirectory" -> output,
      "PairFileCount" -> Length[files],
      "RecordCount" -> Length[allRecords],
      "FamilyCount" -> Length[families],
      "Statuses" -> Sort @ Tally[statuses],
      "Collisions" -> collisions,
      "Families" -> Function[entry,
        <|
          "Name" -> entry["Name"],
          "Key" -> entry["Key"],
          "FirstSource" -> entry["FirstSource"],
          "BaseGLI" -> registryRecord["FamilyBaseGLI"][entry["Name"]],
          "CutIndices" -> entry["CutIndices"],
          "CutDirections" -> entry["CutDirections"],
          "Members" -> FirstCase[
            run["Classes"],
            class_ /; class["Name"] === entry["Name"] :> class["Members"],
            {}
          ]
        |>
      ] /@ families,
      "Rejected" -> run["Rejected"],
      "PairFiles" -> FileNameTake /@ files
    |>;
    Put[manifest, manifestFile];
    If[! FileExistsQ[manifestFile] || Get[manifestFile] =!= manifest,
      Message[CanonicalizePairArtifacts::write, manifestFile];
      Throw[$Failed, $canonicalFamilyFailure]
    ];

    Print @ Grid[
      {
        {"Canonicalized pairs", Length[written]},
        {"Topology records", Length[allRecords]},
        {"Canonical families", Length[families]},
        {"Collisions", collisions},
        {"Rejected candidates", Length[run["Rejected"]]},
        {"Registry fingerprint", StringTake[fingerprint, 12]},
        {"Output directory", output}
      },
      Frame -> All
    ];

    <|
      "OutputDirectory" -> output,
      "PairDirectory" -> pairDirectory,
      "Files" -> written,
      "SourceFiles" -> files,
      "RegistryFile" -> registryFile,
      "ManifestFile" -> manifestFile,
      "Registry" -> registry,
      "Fingerprint" -> fingerprint,
      "Families" -> families,
      "FamilyCount" -> Length[families],
      "FamilyBaseGLI" -> registryRecord["FamilyBaseGLI"],
      "Classes" -> run["Classes"],
      "Rejected" -> run["Rejected"],
      "Mappings" -> mappings,
      "GLIRules" -> rules,
      "SourceNames" -> sourceNames,
      "CanonicalNames" -> names,
      "Statuses" -> statuses,
      "Collisions" -> collisions,
      "Manifest" -> manifest
    |>
  ],
  $canonicalFamilyFailure
];

CanonicalizePairArtifacts[arguments___] := (
  Message[
    CanonicalizePairArtifacts::input,
    HoldForm[CanonicalizePairArtifacts[arguments]]
  ];
  $Failed
);
