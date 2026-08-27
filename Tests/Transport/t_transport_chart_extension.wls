root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

catalog = FeynFacet`TransportChartCatalog[];
base = catalog["Kallen1"];
target = catalog["Kallen12"];
rootSquare = target["Roots"][[2]]["RootSquare"];
pulledBack = Together[rootSquare /. base["Subst"]];
extensionRules = Join[
  target["Parents"]["Kallen1"],
  {Sqrt[pulledBack] -> target["Roots"][[2]]["Root"]}
];

composed = FeynFacet`ComposeTransportChartExtension[
  base, rootSquare, extensionRules, target["Variables"]];
automatic = FeynFacet`RationalizeTransportChartExtension[
  base, rootSquare,
  "Name" -> "Kallen12AutomaticTest",
  "OutputVariables" -> {Global`r, Global`t},
  "AllCharts" -> False,
  "AllPoints" -> False,
  "TimeConstraint" -> 120
];

sameSubstitution = And @@ MapThread[
  TrueQ[Together[Last[#1] - Last[#2]] === 0] &,
  {composed["Subst"], target["Subst"]}
];
tests = <|
  "KnownCompositionExact" ->
    Lookup[composed, "Status", None] === "ExactChart",
  "KnownCompositionMatchesCatalog" -> sameSubstitution,
  "KnownCompositionCertificate" ->
    TrueQ[composed["ChartCertificate"]["OK"]],
  "AutomaticExtensionExact" ->
    Lookup[automatic, "Status", None] === "ExactChart",
  "AutomaticExtensionCertificate" ->
    TrueQ[automatic["ChartCertificate"]["OK"]],
  "AutomaticExtensionHasTwoRoots" ->
    Length[Lookup[automatic, "Roots", {}]] === 2
|>;

Print[InputForm[tests]];
If[! TrueQ[tests["AutomaticExtensionExact"]],
  Print[InputForm[automatic]]];
If[! And @@ Values[tests], Exit[1]];
