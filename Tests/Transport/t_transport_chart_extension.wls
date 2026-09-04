root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

catalog = FeynFacet`RationalizingParametrizationCatalog[];
base = catalog["Kallen1"];
target = catalog["Kallen12"];
rootSquare = target["RationalizedSquareRoots"][[2]]["SourceRadicand"];
pulledBack = Together[
  rootSquare /. base["SourceVariableSubstitution"]];
extensionRules = Join[
  target["ParentParametrizationMaps"]["Kallen1"],
  {Sqrt[pulledBack] ->
    target["RationalizedSquareRoots"][[2]]["RationalRoot"]}
];

composed = FeynFacet`ComposeRationalizingParametrizations[
  base, rootSquare, extensionRules, target["ParametrizingVariables"]];
automatic = FeynFacet`ExtendRationalizingParametrization[
  base, rootSquare,
  "Name" -> "Kallen12AutomaticTest",
  "OutputVariables" -> {Global`r, Global`t},
  "AllCharts" -> False,
  "AllPoints" -> False,
  "TimeConstraint" -> 120
];

sameSubstitution = And @@ MapThread[
  TrueQ[Together[Last[#1] - Last[#2]] === 0] &,
  {composed["SourceVariableSubstitution"],
   target["SourceVariableSubstitution"]}
];
tests = <|
  "KnownCompositionExact" ->
    Lookup[composed, "Status", None] ===
      "RationalizingParametrizationVerified",
  "KnownCompositionMatchesCatalog" -> sameSubstitution,
  "KnownCompositionCertificate" ->
    TrueQ[composed["RationalizingParametrizationVerification"][
      "Verified"]],
  "AutomaticExtensionExact" ->
    Lookup[automatic, "Status", None] ===
      "RationalizingParametrizationVerified",
  "AutomaticExtensionCertificate" ->
    TrueQ[automatic["RationalizingParametrizationVerification"][
      "Verified"]],
  "AutomaticExtensionHasTwoRoots" ->
    Length[Lookup[automatic, "RationalizedSquareRoots", {}]] === 2
|>;

Print[InputForm[tests]];
If[! TrueQ[tests["AutomaticExtensionExact"]],
  Print[InputForm[automatic]]];
If[! And @@ Values[tests], Exit[1]];
