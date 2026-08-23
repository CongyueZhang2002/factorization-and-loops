If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file inspect_epsform_record_schema.wls FILE ..."];
  Exit[2]
];

Do[
  record = Quiet[Check[Get[file], $Failed]];
  Print[file];
  If[! AssociationQ[record],
    Print["  unreadable"],
    Print["  keys: ", InputForm[Keys[record]]];
    Print["  summary: ", InputForm[AssociationMap[
      Function[value, Which[
        MatrixQ[value], Dimensions[value],
        AssociationQ[value], Keys[value],
        ListQ[value], {Head[value], Length[value]},
        True, value
      ]],
      KeyTake[record, {
        "Status", "Method", "Frame", "Chart", "Variables", "Regulator",
        "TTotal", "TTotalInverse", "EpsFormX", "EpsFormY", "Gate",
        "Checks", "Certificate", "ChartCertificate", "PullBack"
      }]
    ]]]
  ],
  {file, Rest[$ScriptCommandLine]}
];
