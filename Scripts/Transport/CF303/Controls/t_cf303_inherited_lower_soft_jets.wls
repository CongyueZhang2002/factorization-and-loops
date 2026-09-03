$HistoryLength = 0;
here = DirectoryName[ExpandFileName[$InputFileName]];
artifact = Get[FileNameJoin[{DirectoryName[here], "Artifacts",
  "CF303InheritedLowerSoftJets.wl"}]];
checks = <||>;
check[name_, value_] := AssociateTo[checks, name -> TrueQ[value]];

families = artifact["Families"];
check["AcceptedScope",
  artifact["Status"] === "CF303InheritedLowerSoftJetsAcceptedV1" &&
  Lookup[families, "Family"] === {"CF1", "CF12", "CF21", "CF199", "CF53"} &&
  And @@ (Lookup[#, "CoefficientField"] === "Rational" &&
      Lookup[#, "FunctionClass"] === "GPL" & /@ families)];
check["MinimalResidueClosures",
  Lookup[families, "ActiveCanonicalColumns"] ===
    {{1}, {1, 6}, {1, 4}, {1, 7, 8, 9}, {1, 10, 11, 12}}];
check["DemandedWindows",
  artifact["DemandedCoefficientWindows"] === <|
    "CF1" -> <|"Rho" -> {0, 2}, "Epsilon" -> {0, 5}|>,
    "CF12" -> <|"Rho" -> {0, 2}, "Epsilon" -> {0, 5}|>,
    "CF21" -> <|"Rho" -> {0, 2}, "Epsilon" -> {0, 5}|>,
    "CF199" -> <|"Rho" -> {0, 2}, "Epsilon" -> {0, 6}|>,
    "CF53" -> <|"Rho" -> {0, 2}, "Epsilon" -> {0, 6}|>|>];

coefficient[record_, rhoOrder_, epsilonOrder_] := SelectFirst[
  record["SelectedFrobeniusPrefactor"]["NonzeroCoefficients"],
  Lookup[#, "RhoOrder"] === rhoOrder &&
    Lookup[#, "EpsilonOrder"] === epsilonOrder &, <|"Entries" -> {}|>];
check["LeadingFrameOrientation",
  (Lookup[coefficient[#, 0, 0], "Entries"] & /@ families) === {
    {<|"Row" -> 1, "Column" -> 1, "Value" -> 1|>},
    {<|"Row" -> 1, "Column" -> 2, "Value" -> 1|>},
    {<|"Row" -> 1, "Column" -> 2, "Value" -> 1|>},
    {<|"Row" -> 1, "Column" -> 3, "Value" -> 1|>,
      <|"Row" -> 2, "Column" -> 4, "Value" -> 1|>},
    {<|"Row" -> 1, "Column" -> 3, "Value" -> 1|>,
      <|"Row" -> 2, "Column" -> 4, "Value" -> 1|>}}];
check["RestrictedResidueDimensions",
  Lookup[Lookup[families, "Residue"], "Dimensions"] ===
    {{1, 1}, {2, 2}, {2, 2}, {4, 4}, {4, 4}}];

failed = Keys@Select[checks, Not];
If[failed =!= {}, Print["FAIL ", failed]; Quit[2]];
Print["PASS checks=", Length[checks], " families=5 activeColumns=13",
  " buildSeconds=", artifact["TotalBuildSeconds"]];
Quit[];
