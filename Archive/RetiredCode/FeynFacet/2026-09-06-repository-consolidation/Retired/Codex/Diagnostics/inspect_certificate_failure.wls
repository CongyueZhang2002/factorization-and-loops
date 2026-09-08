If[Length[$ScriptCommandLine] =!= 3,
  Print["usage: wolframscript -file inspect_certificate_failure.wls RECORD SYSTEM"];
  Exit[2]
];

root = DirectoryName[DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

record = Get[$ScriptCommandLine[[2]]];
system = Get[$ScriptCommandLine[[3]]];
result = FeynFacet`CertifyFamilyEpsilonForm[record, system];

Print[InputForm[KeyTake[result, {
  "Status", "Family", "Reason", "BasisPermutation", "ChartCertificate",
  "EpsilonFormCertificate", "GateVerdict", "GaugeIdentity", "Flatness"
}]]];

If[Lookup[result, "Status", None] === "EpsilonFormCertificationFailed" &&
    Lookup[record, "Frame", None] === "SourceVW",
  variables = {Global`v, Global`w};
  transformation = record["TTotal"];
  inverse = record["TTotalInverse"];
  epsilonForm = {record["EpsFormX"], record["EpsFormY"]};
  permutation = Flatten[record["Blocks"]];
  inversePermutation = Ordering[permutation];
  connections = <|
    "Original" -> {system["Av"], system["Aw"]},
    "BlockOrder" -> ({system["Av"], system["Aw"]}[[All,
      permutation, permutation]]),
    "InverseBlockOrder" -> ({system["Av"], system["Aw"]}[[All,
      inversePermutation, inversePermutation]])
  |>;
  zeroMatrixQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] &];
  conventionResult = AssociationMap[Function[connection,
    Module[{residual = Table[Map[Together,
        inverse . connection[[direction]] . transformation -
          inverse . D[transformation, variables[[direction]]] -
          epsilonForm[[direction]], {2}], {direction, 2}]},
      <|"Exact" -> zeroMatrixQ[residual],
        "NonzeroEntries" -> Count[Flatten[residual], x_ /;
          ! TrueQ[Together[x] === 0]],
        "LeafCount" -> LeafCount[residual]|>]], connections];
  Print[InputForm[<|"ConventionDiagnostics" -> conventionResult|>]]
];
