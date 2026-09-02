root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Overhaul 2026-09-02: the production transport consumes CERTIFIED
   records (their certificate carries the dlog residues and the
   coefficient field); the uncertified FamilyEpsForms/ record of CF27
   has no certificate and is refused with DLogResiduesRequired by
   design.  The certified record's residues are modular, so the accepted
   status is ModularlyVerifiedObservableTransport; an exact status is
   also accepted.  Acceptance goes through the public predicate. *)
record = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsCertified", "family_epsform_CF27.wl"}]];
acceptedStatusQ[value_] := MemberQ[
  {"ExactObservableTransport", "ModularlyVerifiedObservableTransport"},
  Lookup[value, "Status", None]];
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
  "ExactStatus" -> acceptedStatusQ[actual],
  "CartesianStatus" -> acceptedStatusQ[cartesian],
  "ConstraintRank" -> actual["ConstraintRank"] === 8,
  "BoundaryCoordinates" -> actual["BoundaryCoordinates"] === 28,
  "PhysicalRows" -> actual["PhysicalRows"] ===
    demand["PhysicalDemandPairs"],
  (* the active letters of the first segment are, by definition, the
     record letters whose derivative in the first variable is nonzero;
     the index set depends on the record's letter order, so it is
     computed here rather than pinned to one fixture's numbering *)
  "ActiveLetters" -> actual["FirstSegmentActiveLetters"] ===
    Select[Range[Length[actual["DLogLetters"]]],
      ! TrueQ[Together[D[actual["DLogLetters"][[#]], v]] === 0] &],
  "MapCounts" -> actual["FirstSegmentMapCountsByWeight"] ===
    {1, 3, 9, 21, 0, 0},
  "ExactMapAgreement" -> mapAgreement,
  "Certificates" -> And @@ Values[actual["Certificates"]],
  "Accepted" -> TrueQ[FeynFacet`AcceptedObservableTransportQ[actual]] &&
    TrueQ[FeynFacet`AcceptedObservableTransportQ[cartesian]]
|>;
Print["statuses: ", actual["Status"], " / ", cartesian["Status"]];

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
