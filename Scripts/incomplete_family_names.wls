If[Length[$ScriptCommandLine] =!= 2,
  Print["usage: wolframscript -file incomplete_family_names.wls REPORT"];
  Exit[2]
];

report = Quiet[Check[Get[$ScriptCommandLine[[2]]], $Failed]];
If[! AssociationQ[report], Exit[3]];
Scan[Print, Lookup[report, "IncompleteFamilies", {}]];
