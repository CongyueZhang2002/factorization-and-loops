root = "/home/maxzhang/FACET";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

reference[lists : {__List}] := Module[{first, unique},
  first = First[lists];
  unique = DeleteDuplicates[first];
  Flatten[
    Table[
      factor,
      {factor, unique},
      {Min[Count[#, factor] & /@ lists]}
    ],
    1
  ]
];

canonical[list_List] := SortBy[list, ToString[InputForm[#]] &];
SeedRandom[20260804];
samples = Table[
  Table[
    RandomChoice[{Global`a, Global`b, Global`c, Global`d},
      RandomInteger[{1, 12}]],
    {RandomInteger[{1, 7}]}
  ],
  {500}
];

checks = <|
  "RandomMultisetsAgree" -> AllTrue[
    samples,
    canonical[FeynFacet`Private`commonFactorMultiset[#]] ===
      canonical[reference[#]] &
  ],
  "MultiplicityPreserved" ->
    canonical @ FeynFacet`Private`commonFactorMultiset[
      {{Global`a, Global`a, Global`b},
       {Global`a, Global`a, Global`a, Global`b, Global`c}}
    ] === {Global`a, Global`a, Global`b}
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
