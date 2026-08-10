(* Weighted assembly of cut-contribution coefficient results.

   AssembleCutContributions combines finite-field CoefficientResult
   artifacts of one process that share a canonical family namespace,
   one fraction measure, one phase space, and one physical prefactor.
   Each contribution enters with the exact weight

     IdenticalParticleSymmetryFactor[setup] * (-1)^(ghost pairs),

   the Slavnov-Taylor completion of -g polarization sums documented in
   the ghost process cards: for the gg final state this realizes
   sigma_gg = (1/2!) x gluon grid - ghost grid. *)

AssembleCutContributions::input =
  "AssembleCutContributions expects a nonempty list of FeynFacet-IBP version-8 coefficient results or saved result files, but received `1`.";

AssembleCutContributions::weight =
  "Could not derive the assembly weight for contribution `1`: `2`.";

AssembleCutContributions::measure =
  "Contribution `1` does not share the fraction measure, phase space, or physical prefactor of the first contribution.";

AssembleCutContributions::namespace =
  "Master `1` carries different topology metadata in different contributions. The contributions do not share one canonical family namespace.";

AssembleCutContributions::exact =
  "The assembled result contains inexact numerical data.";

$assemblyFailure = "FeynFacetAssemblyFailure";

$assemblyFormat = "FeynFacet-CutAssembly";
$assemblyVersion = 1;


(* (-1) per ghost-antighost pair among the outgoing partons. *)
assemblyGhostSign[setup_Association] := Module[
  {partons, outgoing, ghostCount},
  partons = Lookup[setup, "Partons", Missing["NotFound"]];
  If[! MatchQ[partons, Rule[_List, _List]], Return[$Failed]];
  outgoing = Last[partons];
  ghostCount = Count[
    outgoing,
    field_ /; ! FreeQ[Hold[field], FeynArts`U]
  ];
  If[OddQ[ghostCount], Return[$Failed]];
  (-1)^(ghostCount/2)
];

assemblyWeight[setup_Association] := Module[{symmetry, sign},
  symmetry = IdenticalParticleSymmetryFactor[setup];
  sign = assemblyGhostSign[setup];
  If[symmetry === $Failed || sign === $Failed,
    $Failed,
    symmetry sign
  ]
];

assemblyContributionQ[result_] :=
  AssociationQ[result] &&
    result["Format"] === "FeynFacet-IBP" &&
    result["FormatVersion"] === 8 &&
    AssociationQ[Lookup[result, "Setup", None]] &&
    ListQ[Lookup[result, "Masters", None]];

assemblySameQ[first_, second_] := TrueQ[
  SameQ[first, second] || exactZeroQ[first - second]
];

assemblyLoad[item_String] := Module[{result},
  result = Quiet @ Check[Get[ExpandFileName[item]], $Failed];
  If[assemblyContributionQ[result], result, $Failed]
];

assemblyLoad[item_Association] :=
  If[assemblyContributionQ[item], item, $Failed];

assemblyLoad[_] := $Failed;


AssembleCutContributions[items_List] := Catch[
  Module[
    {
      contributions, weights, reference, masterEntries, mergedMasters,
      remainder, provenance, expression, mergedRecords, result
    },

    If[items === {},
      Message[AssembleCutContributions::input, items];
      Throw[$Failed, $assemblyFailure]
    ];
    contributions = assemblyLoad /@ items;
    If[MemberQ[contributions, $Failed],
      Message[AssembleCutContributions::input, items];
      Throw[$Failed, $assemblyFailure]
    ];

    weights = assemblyWeight[#["Setup"]] & /@ contributions;
    MapThread[
      If[#2 === $Failed,
        Message[
          AssembleCutContributions::weight,
          #1["CardName"],
          #1["Setup"]["Partons"]
        ];
        Throw[$Failed, $assemblyFailure]
      ] &,
      {contributions, weights}
    ];

    reference = First[contributions];
    Do[
      If[
        ! assemblySameQ[
            contribution["FractionMeasure"],
            reference["FractionMeasure"]
          ] ||
          ! assemblySameQ[
            contribution["PhaseSpace"],
            reference["PhaseSpace"]
          ] ||
          ! assemblySameQ[
            contribution["PreFactor"],
            reference["PreFactor"]
          ],
        Message[
          AssembleCutContributions::measure,
          contribution["CardName"]
        ];
        Throw[$Failed, $assemblyFailure]
      ],
      {contribution, Rest[contributions]}
    ];

    (* Merge master entries GLI by GLI; the cut and topology metadata
       of a shared master must agree exactly, which is precisely the
       shared-canonical-namespace requirement. *)
    masterEntries = Flatten @ MapThread[
      Function[{contribution, weight},
        Function[entry,
          <|
            "Master" -> entry["Master"],
            "Coefficient" ->
              weight entry["PreFactor"] entry["Coefficient"],
            "Metadata" -> KeyTake[
              entry,
              {"TopologyName", "CutMomenta", "CutIndices",
                "CutDirections"}
            ]
          |>
        ] /@ contribution["Masters"]
      ],
      {contributions, weights}
    ];
    mergedMasters = Values @ GroupBy[
      masterEntries,
      ToString[#["Master"], InputForm] &,
      Function[group,
        If[
          Length[DeleteDuplicates[Lookup[group, "Metadata"], SameQ]] =!= 1,
          Message[
            AssembleCutContributions::namespace,
            group[[1, "Master"]]
          ];
          Throw[$Failed, $assemblyFailure]
        ];
        Join[
          <|
            "Master" -> group[[1, "Master"]],
            "PreFactor" -> 1,
            "Coefficient" -> Total[Lookup[group, "Coefficient"]]
          |>,
          group[[1, "Metadata"]]
        ]
      ]
    ];
    mergedMasters = SortBy[
      mergedMasters,
      ToString[#["Master"], InputForm] &
    ];

    remainder = Total @ MapThread[
      #2 Lookup[#1, "Remainder", 0] &,
      {contributions, weights}
    ];

    mergedRecords = Values @ GroupBy[
      Flatten[Lookup[contributions, "Topologies"]],
      #["Topology"][[1]] &,
      Function[group,
        If[
          Length[DeleteDuplicates[
            KeyDrop[#, {"DiagramPair", "Created"}] & /@ group,
            SameQ
          ]] =!= 1,
          Message[
            AssembleCutContributions::namespace,
            group[[1]]["Topology"][[1]]
          ];
          Throw[$Failed, $assemblyFailure]
        ];
        First[group]
      ]
    ];

    provenance = MapThread[
      <|
        "CardName" -> #1["CardName"],
        "ResultDirectory" -> Lookup[
          #1, "ResultDirectory", Missing["NotAvailable"]
        ],
        "Weight" -> #2,
        "MasterCount" -> Length[#1["Masters"]],
        "SourceInputFingerprint" -> Lookup[
          #1, "SourceInputFingerprint", Missing["NotAvailable"]
        ]
      |> &,
      {contributions, weights}
    ];

    expression = reference["PreFactor"] (
      Total[#["Coefficient"] #["Master"] & /@ mergedMasters] + remainder
    );

    result = Join[
      resultHeader[$assemblyFormat, $assemblyVersion],
      <|
        "Contributions" -> provenance,
        "FractionMeasure" -> reference["FractionMeasure"],
        "PhaseSpace" -> reference["PhaseSpace"],
        "PreFactor" -> reference["PreFactor"],
        "Masters" -> mergedMasters,
        "Remainder" -> remainder,
        "Expression" -> expression,
        "Topologies" -> mergedRecords,
        "Assumptions" -> reference["Assumptions"],
        "AnalyticContexts" -> DeleteDuplicates[
          Lookup[contributions, "AnalyticContext"],
          SameQ
        ]
      |>
    ];
    If[! exactDataQ[KeyDrop[result, "Created"]],
      Message[AssembleCutContributions::exact];
      Throw[$Failed, $assemblyFailure]
    ];

    Print @ Grid[
      Prepend[
        MapThread[
          {#1["CardName"], #2, Length[#1["Masters"]]} &,
          {contributions, weights}
        ],
        {"Contribution", "Weight", "Masters"}
      ],
      Frame -> All
    ];
    Print @ Grid[
      {
        {"Assembled masters", Length[mergedMasters]},
        {"Topology records", Length[mergedRecords]}
      },
      Frame -> All
    ];

    result
  ],
  $assemblyFailure
];

AssembleCutContributions[arguments___] := (
  Message[
    AssembleCutContributions::input,
    HoldForm[AssembleCutContributions[arguments]]
  ];
  $Failed
);
