(* Canonical integral families (Design/CanonicalFamilies.md) reproduce the
   NLO ground truth.

   Acceptance criteria:
   1. Over all saved NLO UU 10x10 pair records: exactly 11 canonical
      families, zero CollisionRegistered.
   2. Class membership identical to the partition induced by the saved
      KiraResult.wl TopologyEquivalence classes.
   3. Every emitted GLI rule passes topologyPhysicalMapping verification
      (this test re-verifies independently).
   4. Determinism: a second run over the same inputs yields an identical
      registry and identical rules.
   5. Exactness: no inexact numbers anywhere in the registry or the rules. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

ftResultDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1"
}];

ftPairFiles = Sort @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{ftResultDirectory, "Pairs"}]
];

FTTest`FTAssert["100 saved NLO pair artifacts", Length[ftPairFiles] === 100];

ftArtifacts = Get /@ ftPairFiles;
ftRecords = Join @@ Lookup[ftArtifacts, "Topologies"];
ftSetup = First[Lookup[ftArtifacts, "Setup"]];
ftSectors = Catch[
  FeynFacet`Private`loopSectorsFromSetup[ftSetup],
  FeynFacet`Private`$collinearFailure
];

FTTest`FTAssert["178 saved NLO topology records", Length[ftRecords] === 178];
FTTest`FTAssert["loop sectors available from the process card",
  AssociationQ[ftSectors]];

ftKira = Get[FileNameJoin[{ftResultDirectory, "KiraResult.wl"}]];
ftTruthClasses = ftKira["TopologyEquivalence"]["Classes"];
ftTruthPartition = Sort[Sort /@ Lookup[ftTruthClasses, "Members"]];

FTTest`FTAssert["ground truth has 11 TopologyEquivalence classes",
  Length[ftTruthClasses] === 11];

(* ---------------------------------------------------------------- run 1 *)

ftRun1 = FeynFacet`Private`CanonicalizeTopologyRecords[ftRecords, ftSetup];

FTTest`FTAssert["canonicalization returns the documented result association",
  AssociationQ[ftRun1] &&
    ContainsAll[Keys[ftRun1], {"Registry", "Rules", "Classes", "Rejected"}]];

ftFamilies = ftRun1["Registry"]["Families"];
ftStatus = Lookup[ftRun1["Mappings"], "Status"];

(* --- criterion 1: exactly 11 canonical families, no collisions --------- *)

FTTest`FTAssert["1a. exactly 11 canonical families",
  Length[ftRun1["Classes"]] === 11 && Length[ftFamilies] === 11];
FTTest`FTAssert["1b. zero CollisionRegistered records",
  Count[ftStatus, "CollisionRegistered"] === 0];
FTTest`FTAssert["1c. every record is Registered or Mapped",
  Length[ftStatus] === Length[ftRecords] &&
    Complement[ftStatus, {"Registered", "Mapped"}] === {}];
FTTest`FTAssert["1d. no rejected candidate mappings",
  ftRun1["Rejected"] === {}];
FTTest`FTAssert["1e. canonical family names are Global` CF symbols",
  AllTrue[
    Lookup[ftFamilies, "Name"],
    Head[#] === Symbol && Context[#] === "Global`" &&
      StringMatchQ[SymbolName[#], "CF" ~~ DigitCharacter ..] &
  ]];

(* --- criterion 2: partition equals the KiraResult ground truth --------- *)

ftPartition = Sort[Sort /@ Lookup[ftRun1["Classes"], "Members"]];

FTTest`FTAssert["2. class membership equals the TopologyEquivalence partition",
  ftPartition === ftTruthPartition];

Print["    class sizes (canonical): ", Length /@ Lookup[ftRun1["Classes"], "Members"]];
Print["    class sizes (Kira, sorted): ", Sort[Length /@ Lookup[ftTruthClasses, "Members"]]];

(* --- criterion 3: independent re-verification of every emitted rule ---- *)

ftFamilyByName = AssociationThread[Lookup[ftFamilies, "Name"], ftFamilies];

ftReverify[record_, rule_, mapping_] := Module[
  {entry, target, indices, probe, mapped, candidate, check},

  entry = Lookup[ftFamilyByName, mapping["Name"], Missing[]];
  If[! AssociationQ[entry], Return[False]];
  target = <|
    "Topology" -> entry["Topology"],
    "CutMomenta" -> entry["CutMomenta"],
    "CutIndices" -> entry["CutIndices"],
    "CutDirections" -> entry["CutDirections"]
  |>;
  indices = Table[Unique["ftIndex$"], {Length[record["Topology"][[2]]]}];
  probe = FeynCalc`GLI[record["Topology"][[1]], indices];
  mapped = Replace[probe, rule, {0}];
  If[! MatchQ[mapped, _FeynCalc`GLI] || mapped[[1]] =!= entry["Name"],
    Return[False]
  ];
  candidate = <|
    "Source" -> record["Topology"][[1]],
    "Target" -> entry["Name"],
    "LoopMomentumRules" -> mapping["LoopMomentumRules"],
    "GLIRule" -> rule,
    "ProbeGLI" -> probe,
    "ProbeIndices" -> indices,
    "MappedProbe" -> mapped
  |>;
  check = FeynFacet`Private`topologyPhysicalMapping[
    record, target, candidate, ftSectors
  ];
  TrueQ[First[check]] &&
    SameQ[Replace[probe, Last[check]["GLIRule"], {0}], mapped]
];

ftVerified = MapThread[
  ftReverify,
  {ftRecords, ftRun1["Rules"], ftRun1["Mappings"]}
];

FTTest`FTAssert["3a. one emitted GLI rule per topology record",
  Length[ftRun1["Rules"]] === Length[ftRecords] &&
    AllTrue[ftRun1["Rules"], MatchQ[#, _RuleDelayed] &]];
FTTest`FTAssert["3b. every emitted GLI rule passes topologyPhysicalMapping",
  Length[ftVerified] === Length[ftRecords] && AllTrue[ftVerified, TrueQ]];

(* --- criterion 4: determinism ------------------------------------------ *)

ftRun2 = FeynFacet`Private`CanonicalizeTopologyRecords[ftRecords, ftSetup];

(* Emitted rules carry freshly created pattern variables, so they are
   compared through the substitution they perform on a fixed probe. *)
ftRuleSignature[record_, rule_] := Replace[
  FeynCalc`GLI[
    record["Topology"][[1]],
    Range[Length[record["Topology"][[2]]]]
  ],
  rule,
  {0}
];

FTTest`FTAssert["4a. the registry is reproduced exactly",
  AssociationQ[ftRun2] && ftRun2["Registry"] === ftRun1["Registry"]];
FTTest`FTAssert["4b. the emitted rules are reproduced exactly",
  AssociationQ[ftRun2] &&
    SameQ[
      MapThread[ftRuleSignature, {ftRecords, ftRun1["Rules"]}],
      MapThread[ftRuleSignature, {ftRecords, ftRun2["Rules"]}]
    ]];
FTTest`FTAssert["4c. the class partition is reproduced exactly",
  AssociationQ[ftRun2] && ftRun2["Classes"] === ftRun1["Classes"]];

(* --- criterion 5: exact arithmetic only -------------------------------- *)

FTTest`FTAssert["5a. the registry contains no inexact numbers",
  FeynFacet`Private`exactDataQ[ftRun1["Registry"]]];
FTTest`FTAssert["5b. the emitted rules contain no inexact numbers",
  FeynFacet`Private`exactDataQ[ftRun1["Rules"]]];
FTTest`FTAssert["5c. the mapping records contain no inexact numbers",
  FeynFacet`Private`exactDataQ[ftRun1["Mappings"]]];
FTTest`FTAssert["5d. every canonical key is a SHA-256 hex string",
  AllTrue[
    Lookup[ftFamilies, "Key"],
    StringQ[#] && StringLength[#] === 64 &&
      StringMatchQ[#, RegularExpression["[0-9a-f]{64}"]] &
  ]];

FTTest`FTReport[];
