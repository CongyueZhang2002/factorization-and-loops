Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];

ClearAll[referencePairings, referenceMoment];

referencePairings[{}] := {{}};
referencePairings[list_List] := Module[{first, rest},
  first = First[list];
  rest = Rest[list];
  Flatten[
    Table[
      (Prepend[#, {first, rest[[i]]}] &) /@
        referencePairings[Delete[rest, i]],
      {i, Length[rest]}
    ],
    1
  ]
];

referenceMoment[bilinears_List, covariance_, componentDimension_] := Module[
  {rank, slots, onePairing},
  rank = Length[bilinears];
  If[rank === 0, Return[1]];
  slots = Flatten[
    Table[
      {{i, bilinears[[i, 1]]}, {i, bilinears[[i, 2]]}},
      {i, rank}
    ],
    1
  ];
  onePairing[pairing_] := Module[{edges, labels, old, new},
    edges = ({#[[1, 1]], #[[2, 1]]} &) /@ pairing;
    labels = Range[rank];
    Scan[
      Function[edge,
        If[edge[[1]] =!= edge[[2]],
          old = labels[[edge[[2]]]];
          new = labels[[edge[[1]]]];
          labels = labels /. old -> new
        ]
      ],
      edges
    ];
    componentDimension^Length[DeleteDuplicates[labels]] *
      Times @@ (
        covariance[[#[[1, 2]], #[[2, 2]]]] & /@ pairing
      )
  ];
  Total[onePairing /@ referencePairings[slots]]
];

covariance = {{c11, c12}, {c12, c22}};
gramMoment = FeynFacet`Private`dimensionalShiftGramMomentFunction[
  covariance,
  nu
];
bilinears[{m11_, m12_, m22_}] := Join[
  ConstantArray[{1, 1}, m11],
  ConstantArray[{1, 2}, m12],
  ConstantArray[{2, 2}, m22]
];

powers = Select[Tuples[Range[0, 4], 3], Total[#] <= 4 &];
checks = Association[
  "MomentCount" -> Length[powers] === 35,
  "ExactThroughRankFour" -> AllTrue[
    powers,
    TrueQ[
      Expand[
        referenceMoment[bilinears[#], covariance, nu] -
          gramMoment[bilinears[#]]
      ] === 0
    ] &
  ],
  "RankSeven" -> TrueQ[
    Expand[
      referenceMoment[bilinears[{7, 0, 0}], covariance, nu] -
        gramMoment[bilinears[{7, 0, 0}]]
    ] === 0
  ]
];

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
