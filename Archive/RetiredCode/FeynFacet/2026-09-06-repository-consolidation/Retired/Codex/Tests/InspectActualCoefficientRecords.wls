$HistoryLength = 0;

root = "/home/maxzhang/FACET";

uu = Get @ FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_2", "IBPResult.wl"
}];
Print["UU overall factor\t", InputForm[uu["PreFactor"]]];
Print[
  "UU first local factor\t",
  InputForm[First[uu["Masters"]]["PreFactor"]]
];
Print[
  "UU first coefficient bytes\t",
  ByteCount[First[uu["Masters"]]["Coefficient"]]
];

tt = Get @ FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "TTOrdering",
  "TargetThenMaster_02.wl"
}];
ttFinal = tt["Data", "Final"];
Print["TT factor\t", InputForm[ttFinal["PreFactor"]]];
Print["TT relative factor\t", InputForm[ttFinal["RelativePreFactor"]]];
Print["TT hard terms head\t", Head[ttFinal["HardPart", "Terms"]]];
Print["TT hard term count\t", Length[ttFinal["HardPart", "Terms"]]];
Print[
  "TT first hard term bytes\t",
  ByteCount[First[Values[ttFinal["HardPart", "Terms"]]]]
];
Print[
  "TT hard term bytes\t",
  InputForm[ByteCount /@ Values[ttFinal["HardPart", "Terms"]]]
];

uuFinal = Get @ FileNameJoin[{
  root, "Codex", "ppHX_NLO", "HadronicSimplification", "Production",
  "UU_08_08_3", "IBPResult.wl"
}];
Print["UU final keys\t", InputForm[Keys[uuFinal]]];
Print["UU final factor\t", InputForm[uuFinal["PreFactor"]]];
Print["UU final masters head\t", Head[uuFinal["Masters"]]];
If[ListQ[uuFinal["Masters"]] && uuFinal["Masters"] =!= {},
  Print["UU final first master keys\t", InputForm[Keys[First[uuFinal["Masters"]]]]];
  Print[
    "UU final first coefficient bytes\t",
    ByteCount[First[uuFinal["Masters"]]["Coefficient"]]
  ];
  Print[
    "UU final local factors\t",
    InputForm[Lookup[uuFinal["Masters"], "PreFactor"]]
  ];
  Print[
    "UU final coefficients\t",
    InputForm[Lookup[uuFinal["Masters"], "Coefficient"]]
  ]
];

Quit[0];
