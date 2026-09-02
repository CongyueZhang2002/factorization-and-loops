$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

Clear[v, w, x, y, eps];
system = <|"Family" -> "LibraChartTest",
  "Av" -> eps {{1/v, 0}, {0, 1/(1 - v)}},
  "Aw" -> eps {{1/w, 0}, {0, 2/w}}|>;
chart = <|"Kind" -> "TwoVariable", "Name" -> "IdentityChart",
  "Variables" -> {x, y}, "Subst" -> {v -> x, w -> y}|>;

result = FeynFacet`LibraFamilyEpsForm[
  system, chart, "SourceVariables" -> {v, w}, "Regulator" -> eps,
  "UseFermat" -> False, "TimeLimit" -> 30];

checks = <|
  "Association" -> AssociationQ[result],
  "Status" -> If[AssociationQ[result], result["Status"] === "EpsForm", False],
  "ExactCertificates" -> If[AssociationQ[result],
    And @@ (TrueQ /@ Values[result["Checks"]]), False],
  "ChartVariables" -> If[AssociationQ[result],
    result["Variables"] === {x, y}, False]
|>;

Print[InputForm[checks]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
