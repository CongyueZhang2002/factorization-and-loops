$HistoryLength = 0;

files = {
  "/home/maxzhang/FACET/ppHX_NLO/Results/UU_08_05_2/IBPResult.wl",
  "/home/maxzhang/FACET/Codex/ppHX_NLO/HadronicSimplification/TTOrdering/TTMasterCoefficients_01.wl",
  "/home/maxzhang/FACET/Codex/ppHX_NLO/HadronicSimplification/TTOrdering/TargetThenMaster_02.wl"
};

Do[
  data = Get[file];
  Print[FileNameTake[file], "\t", InputForm[Keys[data]]];
  KeyValueMap[
    If[AssociationQ[#2],
      Print["  ", #1, "\t", InputForm[Keys[#2]]]
    ] &,
    data
  ];
  If[KeyExistsQ[data, "Masters"],
    Print["  Masters head\t", Head[data["Masters"]]];
    If[ListQ[data["Masters"]] && data["Masters"] =!= {},
      Print["  First master\t", InputForm[Keys[First[data["Masters"]]]]]
    ];
    If[AssociationQ[data["Masters"]] && data["Masters"] =!= <||>,
      Print[
        "  First master value head\t",
        Head[First[Values[data["Masters"]]]]
      ]
    ]
  ];
  If[KeyExistsQ[data, "Data"] && AssociationQ[data["Data"]],
    KeyValueMap[
      Function[{stageName, stageValue},
        If[AssociationQ[stageValue],
          Print[
            "  Data/", stageName, "\t",
            InputForm[Keys[stageValue]]
          ];
          KeyValueMap[
            Function[{partName, partValue},
              If[AssociationQ[partValue],
                Print[
                  "    Data/", stageName, "/", partName, "\t",
                  InputForm[Keys[partValue]]
                ]
              ]
            ],
            stageValue
          ]
        ]
      ],
      data["Data"]
    ]
  ];
  Clear[data],
  {file, files}
];
Quit[0];
