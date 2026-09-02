#!/usr/bin/env wolframscript

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`algebraicX"];
y = Symbol["Global`algebraicY"];
eps = Symbol["Global`eps"];

record = <|
  "Status" -> "ExactEpsilonForm",
  "Family" -> "AlgebraicObservableToy",
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Dim" -> 1,
  "Ranges" -> {{1}},
  "TTotal" -> {{eps}},
  "TTotalInverse" -> {{1/eps}},
  "EpsFormX" ->
    eps {{-1/(2 Sqrt[1 - x] (1 + Sqrt[1 - x]))}},
  "EpsFormY" -> eps {{0}},
  "Letters" -> {1 + Sqrt[1 - x]},
  "DLog" -> <|
    "Valid" -> True,
    "Dimension" -> 1,
    "Variables" -> {x, y},
    "Regulator" -> eps,
    "Letters" -> {1 + Sqrt[1 - x]},
    "Residues" -> {{{1}}},
    "ConstantResidues" -> True|>,
  "ChartRecord" -> <|"CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y}, "Subst" -> {x -> x, y -> y},
    "Roots" -> {<|"Root" -> Sqrt[1 - x],
      "RootSquare" -> 1 - x|>}|>,
  "GateVerdict" -> True,
  "GaugeIdentity" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True
|>;

path = FindObservableTransportPath[record];
demand = <|
  "PhysicalRows" -> {1},
  "PhysicalOrders" -> {2, 3},
  "PhysicalValuation" -> 2,
  "Path" -> path
|>;
transport = BuildObservableTransport[record, demand,
  "BoundaryEvolution" -> "AmbientBasePoint"];
constrainedDemand = <|
  "PhysicalRows" -> {1},
  "PhysicalOrders" -> {2, 3},
  "PhysicalValuation" -> 2,
  "Path" -> path
|>;
constrainedTransport = BuildObservableTransport[record, constrainedDemand,
  "BoundaryEvolution" -> "AmbientBasePoint"];

certifiedDLog = <|
  "Valid" -> True,
  "Dimension" -> 1,
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Letters" -> {1 - x},
  "Residues" -> {{{1}}},
  "ConstantResidues" -> True,
  "ResiduesVerifiedAtAllPrimes" -> True|>;
certifiedRecord = <|
  "Status" -> "CertifiedEpsilonForm",
  "Family" -> "CertifiedAlgebraicObservableToy",
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Dim" -> 1,
  "Ranges" -> {{1}},
  "TTotal" -> {{eps}},
  "TTotalInverse" -> {{1/eps}},
  "EpsFormX" -> eps {{-1/(1 - x)}},
  "EpsFormY" -> eps {{0}},
  "Letters" -> {1 - x},
  "ChartRecord" -> <|"CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y}, "Subst" -> {x -> x, y -> y},
    "Roots" -> {<|"Root" -> Sqrt[1 - x],
      "RootSquare" -> 1 - x|>}|>,
  "GateVerdict" -> True,
  "GaugeIdentity" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True,
  "Checks" -> AssociationThread[
    {"EpsFactored", "DLog", "BlockLowerTriangular",
     "TransformationInverse", "GaugeIdentity", "SourceFlatness",
     "Flatness", "ChartIdentity"} -> ConstantArray[True, 8]],
  "EpsilonFormCertificate" -> <|
    "Version" -> 1,
    "Exact" -> False,
    "Certified" -> True,
    "CertificationLevel" -> "HighConfidenceFiniteField",
    "CoefficientField" -> "Multiquadratic",
    "IdentityMethod" -> "Modular",
    "Probabilistic" -> True,
    "IdentityPoints" -> {<|
      "Prime" -> 2147483647,
      "TrainingPoints" -> 3,
      "ValidationPoints" -> 2,
      "DLogRank" -> 1,
      "AllSheetsPerPoint" -> 2|>},
    "Modular" -> <|
      "Status" -> "CertifiedMultiquadraticFamily",
      "CoefficientField" -> "Multiquadratic",
      "Method" -> "AllSignSheetsAtFreshSplitPoints",
      "Probabilistic" -> True,
      "AllRootSheetsChecked" -> True,
      "FreshLiftValidation" -> True,
      "ConstantResidues" -> True,
      "ResiduesVerifiedAtAllPrimes" -> True|>,
    "DLog" -> certifiedDLog|>|>;
certifiedTransport = BuildObservableTransport[certifiedRecord, demand,
  "BoundaryEvolution" -> "AmbientBasePoint",
  "WordRepresentation" -> "OperatorAutomaton"];
computedDLog = Join[record["DLog"], <|
  "Status" -> "ComputedDLogResidues",
  "Purpose" -> "ObservableTransportInput",
  "CoefficientField" -> "Multiquadratic",
  "IdentityMethod" -> "FiniteFieldPointwise",
  "PointwiseReplay" -> True,
  "FreshPrimeValidation" -> True,
  "AllRootSheetsEvaluated" -> True,
  "ResiduesVerifiedAtAllPrimes" -> True,
  "CRTPrimes" -> {2147483647},
  "FreshValidationPrime" -> 2147483587|>];
computedRecord = Join[
  KeyDrop[record, {"EpsFormX", "EpsFormY", "DLog"}],
  <|"Status" -> "TransportReadyEpsilonConnection",
    "EpsFormRepresentation" -> "ConstantResidueDLog",
    "DLog" -> computedDLog,
    "TransportEpsilonValuations" -> <|
      "TMin" -> 1, "BlockLower" -> {-1}|>,
    "BlockAssemblyEvidence" -> <|"CompletePairCoverage" -> True|>|>];
computedTransport = BuildObservableTransport[computedRecord, demand,
  "BoundaryEvolution" -> "AmbientBasePoint",
  "WordRepresentation" -> "OperatorAutomaton"];
computedWithoutValuations = BuildObservableTransport[
  KeyDrop[computedRecord, "TransportEpsilonValuations"], demand,
  "BoundaryEvolution" -> "AmbientBasePoint",
  "WordRepresentation" -> "OperatorAutomaton"];
If[Lookup[computedTransport, "Status", None] =!=
    "ModularlyVerifiedObservableTransport",
  Print["Computed-dlog diagnostic: ",
    InputForm[KeyTake[computedTransport,
      {"Status", "Step", "FamilyInputRoute", "Certificates",
       "ProbabilisticCertificates"}]]]];
tamperedDLogEvidence = Join[
  certifiedTransport["ProbabilisticCertificates"]["FamilyDLogResidues"],
  <|"ResiduesVerifiedAtAllPrimes" -> False|>];
tamperedProbabilistic = Join[
  certifiedTransport["ProbabilisticCertificates"],
  <|"FamilyDLogResidues" -> tamperedDLogEvidence|>];
tamperedTransport = Join[certifiedTransport,
  <|"ProbabilisticCertificates" -> tamperedProbabilistic|>];
If[Lookup[constrainedTransport, "Status", None] =!=
    "ModularlyVerifiedObservableTransport",
  Print["Constrained algebraic diagnostic: ",
    InputForm[KeyTake[constrainedTransport,
      {"Status", "Prime", "Point", "BranchMask", "SpaceRank",
       "JoinedRank", "CoefficientField", "Accepted", "Required",
       "RejectedReasons", "RootSquares", "RecordDLogUsable",
       "CertificateDLogUsable", "FamilyEpsilonFormExact"}]]]];

FTAssert["the algebraic family record is admitted only after exact certificates",
  ExactFamilyEpsilonFormQ[record]];
FTAssert["an endpoint-regular two-segment path is selected automatically",
  AssociationQ[path] && path["Status"] === "ExactPathData"];
FTAssert["observable-only transport finishes over the declared algebraic field",
  AssociationQ[transport] &&
    transport["Status"] === "ModularlyVerifiedObservableTransport" &&
    AcceptedObservableTransportQ[transport]];
FTAssert["the first segment uses the exact certified dlog residue",
  transport["FirstSegmentKernelMethod"] === "DLogResidues" &&
    Length[transport["FirstSegmentKernels"]] === 1];
FTAssert["the second zero connection is represented without spurious kernels",
  transport["SecondSegmentKernelMethod"] === "DLogResidues" &&
    transport["SecondSegmentKernels"] === {}];
FTAssert["all demand-driven transport identities are exact",
  And @@ (TrueQ /@ Values[transport["Certificates"]])];
FTAssert["constrained algebraic closure is certified at split finite-field points",
  AssociationQ[constrainedTransport] &&
    constrainedTransport["Status"] ===
      "ModularlyVerifiedObservableTransport" &&
    AcceptedObservableTransportQ[constrainedTransport]];
FTAssert["a modular multiquadratic record is admitted by its finite-field certificate",
  CertifiedFamilyEpsilonFormQ[certifiedRecord] &&
    ! ExactFamilyEpsilonFormQ[certifiedRecord]];
FTAssert["certified dlog residues bypass algebraic entry decomposition",
  certifiedTransport["Status"] ===
      "ModularlyVerifiedObservableTransport" &&
    certifiedTransport["FirstSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    certifiedTransport["SecondSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    certifiedTransport["Certificates"]["FirstKernelIdentity"] &&
    ! certifiedTransport["Certificates"]["FirstKernelIdentityExact"] &&
    certifiedTransport["Certificates"]["FirstKernelIdentityCertified"] &&
    AcceptedObservableTransportQ[certifiedTransport]];
FTAssert["certified residue transport remains exact matrix arithmetic",
  ObservableTransportWordMap[certifiedTransport, {}, {}]["Status"] ===
      "ModularlyVerifiedWordMap" &&
    TrueQ[ObservableTransportWordMap[
      certifiedTransport, {}, {}]["MatrixArithmeticExact"]]];
FTAssert["computed dlog input transports without materialized epsilon matrices",
  computedTransport["Status"] ===
      "ModularlyVerifiedObservableTransport" &&
    computedTransport["FamilyInputRoute"] === "ComputedDLog" &&
    computedTransport["TransportEpsilonValuationSource"] ===
      "FamilyRecord" &&
    computedTransport["TransportEpsilonValuations"] === <|
      "TMin" -> 1, "BlockLower" -> {-1}|> &&
    computedTransport["FirstSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    AcceptedObservableTransportQ[computedTransport]];
FTAssert["computed dlog production never falls back to a symbolic gauge scan",
  computedWithoutValuations["Status"] ===
    "TransportEpsilonValuationsRequired"];
FTAssert["tampered residue evidence is rejected fail closed",
  ! AcceptedObservableTransportQ[tamperedTransport]];

FTReport[];
