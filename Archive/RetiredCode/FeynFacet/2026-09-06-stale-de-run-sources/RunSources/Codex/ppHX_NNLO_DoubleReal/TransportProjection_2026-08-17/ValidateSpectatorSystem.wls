If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file ValidateSpectatorSystem.wls <record>"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];

Print[{
  AssociationQ[record],
  record["Shape"],
  Length[record["ConnectionEntries"]],
  record["MaximumPoleOrderAtBase"],
  record["ResidueRank"],
  record["InvariantSubspaceCertificate"]
}];
