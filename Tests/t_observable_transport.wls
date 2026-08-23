root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

record = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsForms", "family_epsform_CF27.wl"}]];
system = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF27.wl"}]];
valuations = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "MasterCoefficientValuations.wl"}]];
path = <|
  "FirstVariable" -> v,
  "FirstBase" -> 1/4,
  "SecondBase" -> 1/4,
  "FirstTargetSample" -> 2/7|>;

demand = FeynFacet`BuildObservableTransportDemand[
  record, system, valuations,
  "HardFunctionOrders" -> {0},
  "SafetyOrders" -> 1,
  "MasterValuation" -> 0,
  "Path" -> path
  ];
actual = FeynFacet`BuildObservableTransport[record, demand];
cartesian = FeynFacet`BuildObservableTransport[record, <|
  "PhysicalRows" -> {7, 8},
  "PhysicalOrders" -> {0, 1, 2},
  "PhysicalValuation" -> 0,
  "Path" -> path|>];

actualMaps = Association[
  (ToString[#[[1]], InputForm] -> Normal[#[[2]]]) & /@
    actual["FirstSegmentWordMaps"]];
cartesianMaps = Association[
  (ToString[#[[1]], InputForm] -> Normal[#[[2]]]) & /@
    cartesian["FirstSegmentWordMaps"]];

mapAgreement = Sort[Keys[actualMaps]] === Sort[Keys[cartesianMaps]] &&
  AllTrue[Keys[cartesianMaps],
    And @@ (TrueQ[Cancel[Together[#]] === 0] & /@
      Flatten[actualMaps[#] - cartesianMaps[#]]) &];

tests = <|
  "DemandStatus" -> demand["Status"] === "ExactObservableDemand",
  "DemandPairs" -> demand["PhysicalDemandPairs"] ===
    {{0, 7}, {0, 8}, {1, 7}, {1, 8}, {2, 7}, {2, 8}},
  "ExactStatus" -> actual["Status"] === "ExactObservableTransport",
  "CartesianStatus" ->
    cartesian["Status"] === "ExactObservableTransport",
  "ConstraintRank" -> actual["ConstraintRank"] === 8,
  "BoundaryCoordinates" -> actual["BoundaryCoordinates"] === 28,
  "PhysicalRows" -> actual["PhysicalRows"] ===
    demand["PhysicalDemandPairs"],
  "ActiveLetters" -> actual["FirstSegmentActiveLetters"] === {1, 2, 3},
  "MapCounts" -> actual["FirstSegmentMapCountsByWeight"] ===
    {1, 3, 9, 21, 0, 0},
  "ExactMapAgreement" -> mapAgreement,
  "Certificates" -> And @@ Values[actual["Certificates"]]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
