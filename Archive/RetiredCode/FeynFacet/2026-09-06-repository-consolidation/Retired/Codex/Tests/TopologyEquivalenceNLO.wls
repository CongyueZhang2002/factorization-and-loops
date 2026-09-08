root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

resultDirectory = FileNameJoin[
  {root, "ppHX_NLO", "Results", "08_02_1", "results"}
];
files = Select[
  FileNames["F*C*.wl", resultDirectory],
  StringMatchQ[
    FileNameTake[#],
    "F" ~~ DigitCharacter .. ~~ "C" ~~ DigitCharacter .. ~~ ".wl"
  ] &
];
inputs = Get /@ files;
records = Flatten[Lookup[inputs, "Topologies"]];
setup = First[inputs]["Setup"];
result = FeynFacet`TopologyEquivalence[records, setup];

expectedRepresentatives = {
  TopologyF10C10N1,
  TopologyF10C2N2,
  TopologyF10C9N2,
  TopologyF10C9N3,
  TopologyF1C1N1,
  TopologyF1C2N1,
  TopologyF2C9N1,
  TopologyF3C3N1
};
checks = <|
  "InputRecords" -> Length[records] === 39,
  "EightClasses" -> Length[result["Classes"]] === 8,
  "ThirtyOneMappings" -> Length[result["Mappings"]] === 31,
  "NoCandidateRejections" ->
    result["RejectedCandidateMappings"] === {},
  "CutAwareScopeReported" -> And[
    result["Scope"] === "CutAwareIBP",
    result["SearchStatus"] === "AllFeynCalcCandidatesAccepted"
  ],
  "ExpectedRepresentatives" ->
    Sort[Lookup[result["Representatives"], "Topology"][[All, 1]]] ===
      Sort[expectedRepresentatives]
|>;

Print[checks];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
