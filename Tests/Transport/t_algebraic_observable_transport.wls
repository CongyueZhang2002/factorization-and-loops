#!/usr/bin/env wolframscript

(* Round 4 (2026-09-02): measured 5 s wall through the seat launcher
   (TestKit stamps 4 s; Codex's 180 s non-finish was a kernel-start
   hang, see round 3), so nothing here is gated behind FACET_TEST_LONG.
   The former duplicate run "constrainedTransport" (identical demand to
   "transport") is removed; the epsilon-valuation certificate of a
   transport-ready record (Codex correctness point 1) is exercised on
   the same 1x1 fixture: a good record certifies and transports, a
   stale/high claim is refused, a forged claim is refused, and the
   recorded points are re-evaluated on the actual transformation matrices. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
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
  "ConnectionTransformationEquation" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True
|>;

path = ChooseRegularBasePointAndFirstPathParameterScale[record];
demand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{2, 1}, {3, 1}},
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 2,
  "RegularBasePointAndFirstPathParameterScale" -> path
|>;
transport = ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  record, demand, "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];

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
  "ConnectionTransformationEquation" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True,
  "Checks" -> AssociationThread[
    {"EpsFactored", "DLog", "BlockLowerTriangular",
     "TransformationInverse", "ConnectionTransformationEquation", "SourceFlatness",
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
certifiedTransport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    certifiedRecord, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints",
    "IteratedIntegralCoefficientRepresentation" ->
      "IteratedIntegralCoefficientOperatorForRequestedOutputs"];
computedDLog = Join[record["DLog"], <|
  "Status" -> "ComputedDLogResidues",
  "Purpose" -> "RequestedOutputIteratedIntegralCoefficientOperatorInput",
  "CoefficientField" -> "Multiquadratic",
  "IdentityMethod" -> "FiniteFieldPointwise",
  "PointwiseReplay" -> True,
  "FreshPrimeValidation" -> True,
  "AllRootSheetsEvaluated" -> True,
  "ResiduesVerifiedAtAllPrimes" -> True,
  "CRTPrimes" -> {2147483647},
  "FreshValidationPrime" -> 2147483587|>];
(* TTotal = {{eps}}, TTotalInverse = {{1/eps}}: the true valuations are
   TMin = 1 and BlockLower = {-1}. *)
computedRecordUncertified = Join[
  KeyDrop[record, {"EpsFormX", "EpsFormY", "DLog"}],
  <|"Status" -> "TransportReadyEpsilonConnection",
    "EpsFormRepresentation" -> "ConstantResidueDLog",
    "DLog" -> computedDLog,
    "TransportEpsilonValuations" -> <|
      "TMin" -> 1, "BlockLower" -> {-1}|>,
    "BlockAssemblyEvidence" -> <|"CompletePairCoverage" -> True|>|>];
certification = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  computedRecordUncertified];
computedRecord = Lookup[certification, "Record", <||>];
computedTransport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    computedRecord, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];
computedWithoutValuations =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  KeyDrop[computedRecord, "TransportEpsilonValuations"], demand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];
computedUncertified =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  computedRecordUncertified, demand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];
(* a stale/high claim: TMin 2 where the transformation has order 1, and
   BlockLower 0 where the inverse has order -1 *)
staleTMin = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  Join[computedRecordUncertified, <|"TransportEpsilonValuations" ->
    <|"TMin" -> 2, "BlockLower" -> {-1}|>|>]];
staleBlockLower = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  Join[computedRecordUncertified, <|"TransportEpsilonValuations" ->
    <|"TMin" -> 1, "BlockLower" -> {0}|>|>]];
(* a forged record: the claim raised after certification, certificate kept *)
forgedRecord = Join[computedRecord, <|"TransportEpsilonValuations" ->
  Join[computedRecord["TransportEpsilonValuations"], <|"TMin" -> 2|>]|>];
forgedTransport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    forgedRecord, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];
(* A constant rescaling preserves both the transformation equation and the
   epsilon valuations; mathematical re-evaluation must accept it. *)
rescaledRecord = Join[computedRecord, <|"TTotal" -> {{2 eps}},
  "TTotalInverse" -> {{1/(2 eps)}}|>];
rescaledTransport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    rescaledRecord, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints"];
(* a conservative claim (below the observed orders) certifies, not tight *)
conservative = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  Join[computedRecordUncertified, <|"TransportEpsilonValuations" ->
    <|"TMin" -> 0, "BlockLower" -> {-2}|>|>]];
conservativeTransport =
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
  Lookup[conservative, "Record", <||>], demand,
  "BoundaryConstraintSubspaceRepresentation" ->
    "AmbientSpaceWithBasePointConstraints"];
(* a record without valuations: the certifier derives them from the trials *)
derived = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  KeyDrop[computedRecordUncertified, "TransportEpsilonValuations"]];
(* radicals in the gauge: the declared root Sqrt[1 - x], a rescaled one
   Sqrt[(1 - x)/45] (stored by Wolfram as Sqrt[1 - x]/(3 Sqrt[5]), so the
   constant 5 enters through it) and a negative-ratio one Sqrt[x - 1]
   (imaginary unit); true orders 1 and {-1} *)
radicalRecord = Join[computedRecordUncertified, <|
  "TTotal" -> {{eps Sqrt[1 - x] + eps^2 Sqrt[(1 - x)/45] +
    eps^3 Sqrt[x - 1]}},
  "TTotalInverse" -> {{1/(eps Sqrt[1 - x])}},
  "TransportEpsilonValuations" -> <|"TMin" -> 1, "BlockLower" -> {-1}|>|>];
radicalCertification = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  radicalRecord];
undeclaredRadical = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
  Join[radicalRecord, <|"TTotal" -> {{eps Sqrt[1 + x^3]}}|>]];
(* round 7: the bounded route (rigorous lower bounds, exact evaluation of
   the candidates only) must agree with the exhaustive route on a 3x3
   basis-transformation matrix
   with nested quotients, a hidden zero, poles of two orders and radicals *)
boundedBasisTransformationMatrix = {{eps Sqrt[1 - x] + 1/(eps^2 (1 + 2 eps)), (1 + Sqrt[1 - x])/(eps (1 + eps)) - 1/eps, 0},
  {0, (Sqrt[6/5] - Sqrt[30]/5)/eps^3 + eps^2, eps (1 + eps Sqrt[1 - x])/(1 + 5 eps)},
  {(3 + eps (1 - x))/(eps^3 (1 + 2 eps) (1 + 5 eps)) - 3/(eps^3 (1 + 2 eps) (1 + 5 eps)), 1, eps^4}};
boundedRecord = Join[computedRecordUncertified, <|"Dim" -> 3, "Ranges" -> {{1}, {2, 3}},
  "TTotal" -> boundedBasisTransformationMatrix, "TTotalInverse" -> Transpose[boundedBasisTransformationMatrix],
  "TransportEpsilonValuations" -> <|"TMin" -> -2, "BlockLower" -> {-2, -1}|>|>];
boundedCertification = FeynFacet`Private`observableTransportCertifyEpsilonValuations[boundedRecord];
exhaustiveCertification = FeynFacet`Private`observableTransportCertifyEpsilonValuations[boundedRecord, "Exhaustive" -> True];
(* the in-place certifier for records on disk: dry run, write, re-read *)
fileFixture = FileNameJoin[{$TemporaryDirectory,
  "t_algebraic_valuations_" <> ToString[$ProcessID] <> ".wl"}];
Put[computedRecordUncertified, fileFixture];
fileStatus[] := FeynFacet`Private`observableTransportEpsilonValuationStatus[
  FamilyArtifactRead[fileFixture]]["Status"];
fileDry = FeynFacet`Private`observableTransportCertifyEpsilonValuationsFile[
  fileFixture, "Write" -> False];
fileStatusAfterDry = fileStatus[];
fileWet = FeynFacet`Private`observableTransportCertifyEpsilonValuationsFile[
  fileFixture];
fileStatusAfterWrite = fileStatus[];
fileAgain = FeynFacet`Private`observableTransportCertifyEpsilonValuationsFile[
  fileFixture];
Quiet[DeleteFile[fileFixture]];
If[Lookup[computedTransport, "Status", None] =!=
    "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated",
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
If[Lookup[transport, "Status", None] =!=
    "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated",
  Print["Algebraic coefficient-operator diagnostic: ",
    InputForm[KeyTake[transport,
      {"Status", "Prime", "Point", "BranchMask", "SpaceRank",
       "JoinedRank", "CoefficientField", "Accepted", "Required",
       "RejectedReasons", "RootSquares", "RecordDLogUsable",
       "CertificateDLogUsable", "FamilyEpsilonFormExact"}]]]];

FTAssert["the algebraic family record is admitted only after exact certificates",
  ExactFamilyEpsilonFormQ[record]];
FTAssert["an endpoint-regular two-segment path is selected automatically",
  AssociationQ[path] && path["Status"] ===
    "RegularBasePointAndFirstPathParameterScaleSelected"];
FTAssert["the requested-output coefficient operator is constructed over the declared square-root presentation",
  AssociationQ[transport] &&
    transport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[transport]];
FTAssert["the first segment uses the exact certified dlog residue",
  transport["FirstPathSegmentKernelMethod"] === "DLogResidues" &&
    Length[transport["FirstPathSegmentIteratedIntegralKernels"]] === 1];
FTAssert["the second zero connection is represented without spurious kernels",
  transport["SecondPathSegmentKernelMethod"] === "DLogResidues" &&
    transport["SecondPathSegmentIteratedIntegralKernels"] === {}];
FTAssert["all demand-driven transport identities are exact",
  And @@ (TrueQ /@ Values[transport["Certificates"]])];
FTAssert["constrained algebraic closure is certified at split finite-field points",
  AssociationQ[transport] &&
    transport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    transport["ConstraintRank"] > 0 &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[transport]];
FTAssert["an exact record's valuations come from the exact gauge scan and are bound",
  transport["TransportEpsilonValuationSource"] === "ComputedFromBasisTransformationMatrix" &&
    transport["TransportEpsilonValuationCertificate"]["Status"] ===
      "ExactBasisTransformationEpsilonValuationScan" &&
    TrueQ[transport["Certificates"]["TransportEpsilonValuationsBound"]]];
FTAssert["a modular multiquadratic record is admitted by its finite-field certificate",
  CertifiedFamilyEpsilonFormQ[certifiedRecord] &&
    ! ExactFamilyEpsilonFormQ[certifiedRecord]];
FTAssert["certified dlog residues bypass algebraic entry decomposition",
  certifiedTransport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    certifiedTransport["FirstPathSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    certifiedTransport["SecondPathSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    certifiedTransport["Certificates"]["FirstKernelIdentity"] &&
    ! certifiedTransport["Certificates"]["FirstKernelIdentityExact"] &&
    certifiedTransport["Certificates"]["FirstKernelIdentityCertified"] &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      certifiedTransport]];
FTAssert["certified residue transport remains exact matrix arithmetic",
  ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
      certifiedTransport, {}, {}]["Status"] ===
      "IteratedIntegralCoefficientMatrixComputed" &&
    TrueQ[ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[
      certifiedTransport, {}, {}]["MatrixArithmeticExact"]]];
FTAssert["computed dlog input transports without materialized epsilon matrices",
  computedTransport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    computedTransport["FamilyInputRoute"] === "ComputedDLog" &&
    computedTransport["TransportEpsilonValuationSource"] ===
      "FamilyRecord" &&
    computedTransport["TransportEpsilonValuations"] === <|
      "TMin" -> 1, "BlockLower" -> {-1}|> &&
    computedTransport["FirstPathSegmentKernelMethod"] ===
      "CertifiedDLogResidues" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      computedTransport]];
FTAssert["computed dlog production never falls back to a symbolic gauge scan",
  computedWithoutValuations["Status"] ===
    "TransportEpsilonValuationsRequired"];
FTAssert["the valuation certificate is tight on the good record: three exact trials at distinct rational points, observed orders 1 and {-1}",
  certification["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[certification["Tight"]] &&
    certification["Certificate"]["Status"] ===
      "RationalPointEpsilonValuationCertificate" &&
    Length[certification["Certificate"]["Trials"]] === 3 &&
    DuplicateFreeQ[Lookup[certification["Certificate"]["Trials"], "Point"]] &&
    certification["Certificate"]["ObservedTMin"] === 1 &&
    certification["Certificate"]["ObservedBlockLower"] === {-1} &&
    FeynFacet`Private`observableTransportEpsilonValuationStatus[
      computedRecord]["Status"] === "TransportEpsilonValuationsCertified"];
FTAssert["the accepted transport carries the verified certificate",
  computedTransport["TransportEpsilonValuationCertificate"]["Status"] ===
      "RationalPointEpsilonValuationCertificate" &&
    TrueQ[computedTransport["TransportEpsilonValuationCertificate"][
      "DefiningDataRevalidated"]] &&
    TrueQ[computedTransport["Certificates"]["TransportEpsilonValuationsBound"]]];
FTAssert["uncertified valuations are refused with a typed status",
  computedUncertified["Status"] === "TransportEpsilonValuationsUncertified" &&
    FeynFacet`Private`observableTransportEpsilonValuationStatus[
      computedRecordUncertified]["Status"] ===
      "TransportEpsilonValuationsUncertified"];
FTAssert["a stale/high TMin is refused by the certifier with the observed order",
  staleTMin["Status"] === "TransportEpsilonValuationsTooHigh" &&
    staleTMin["ClaimedTMin"] === 2 && staleTMin["ObservedTMin"] === 1];
FTAssert["a stale/high BlockLower is refused by the certifier",
  staleBlockLower["Status"] === "TransportEpsilonValuationsTooHigh" &&
    staleBlockLower["ObservedBlockLower"] === {-1}];
FTAssert["a claim raised after certification is refused: certificate does not name it",
  forgedTransport["Status"] === "TransportEpsilonValuationCertificateInvalid"];
FTAssert["a mathematically equivalent constant basis rescaling is accepted after direct valuation re-evaluation",
  rescaledTransport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      rescaledTransport]];
FTAssert["a conservative claim certifies as not tight and transports accepted",
  conservative["Status"] === "TransportEpsilonValuationsCertified" &&
    conservative["Tight"] === False &&
    conservativeTransport["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    conservativeTransport["TransportEpsilonValuations"] ===
      <|"TMin" -> 0, "BlockLower" -> {-2}|> &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      conservativeTransport]];
FTAssert["a record without valuations gets them derived and tight",
  derived["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[derived["Tight"]] &&
    derived["Valuations"]["TMin"] === 1 &&
    derived["Valuations"]["BlockLower"] === {-1}];
FTAssert["radicals in the gauge (declared, rescaled with Sqrt[5], negative-ratio giving I) certify tight with exact orders",
  radicalCertification["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[radicalCertification["Tight"]] &&
    Length[radicalCertification["Certificate"]["Trials"]] === 3 &&
    radicalCertification["Certificate"]["RootSquares"] === {1 - x}];
FTAssert["a hidden zero and a hidden cancellation of orders are decided exactly (RootReduce), not numerically",
  With[{cancelling = FeynFacet`Private`observableTransportCertifyEpsilonValuations[
      Join[computedRecordUncertified, <|
        "TTotal" -> {{(Sqrt[1 - x] Sqrt[(1 - x)/5] - (1 - x)/Sqrt[5])/eps^3 +
          eps (Sqrt[6/5] - Sqrt[30]/5) + eps^2 Sqrt[1 - x]}},
        "TTotalInverse" -> {{1/(eps^2 Sqrt[1 - x])}},
        "TransportEpsilonValuations" -> <|"TMin" -> 2, "BlockLower" -> {-2}|>|>]]},
    cancelling["Status"] === "TransportEpsilonValuationsCertified" &&
      TrueQ[cancelling["Tight"]]]];
FTAssert["an undeclared radical whose radicand vanishes at no point certifies too: the exact route needs no declaration (typed failure only for an undecidable coefficient)",
  undeclaredRadical["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[undeclaredRadical["Tight"]]];
FTAssert["bounded and exhaustive routes agree on a 3x3 gauge with nested quotients, a hidden zero and poles: tight at TMin -2, BlockLower {-2, -1}, and the bounded route skipped entries",
  boundedCertification["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[boundedCertification["Tight"]] &&
    exhaustiveCertification["Status"] === "TransportEpsilonValuationsCertified" &&
    TrueQ[exhaustiveCertification["Tight"]] &&
    boundedCertification["Certificate"]["ObservedTMin"] === -2 &&
    boundedCertification["Certificate"]["ObservedBlockLower"] === {-2, -1} &&
    exhaustiveCertification["Certificate"]["ObservedBlockLower"] === {-2, -1} &&
    AllTrue[boundedCertification["Certificate"]["Trials"], #["BoundedEntries"] > 0 &] &&
    AllTrue[exhaustiveCertification["Certificate"]["Trials"], #["BoundedEntries"] === 0 &]];
FTAssert["the truncated coefficient route agrees with the exact order on nested quotients, a sum-of-quotients denominator, a hidden zero and a zero entry, and answers Above beyond the cutoff",
  With[{px = 3/7, sumDen = 1/(1/(1 + 2 eps) + 2/(1 + eps) - 3 + eps^2)},
    And @@ Table[With[{o = FeynFacet`Private`observableTransportEpsilonOrderAtPoint[e, eps],
        b = FeynFacet`Private`observableTransportEpsilonOrderBelow[e, eps, 3]},
      If[IntegerQ[o] && o <= 3, b === o, b === Above || b === $Failed]],
      {e, {eps Sqrt[1 - px] + 1/(eps^2 (1 + 2 eps)), (Sqrt[6/5] - Sqrt[30]/5)/eps^3 + eps^2,
        (3 + eps (1 - px))/(eps^3 (1 + 2 eps) (1 + 5 eps)) - 3/(eps^3 (1 + 2 eps) (1 + 5 eps)),
        0, eps^4, sumDen, sumDen (1 + eps)^3/eps^2, (1 + eps)^2/(eps (1 + 2 eps))^2 - 1/eps^2}}] &&
    FeynFacet`Private`observableTransportEpsilonOrderBelow[eps^4, eps, 3] === Above &&
    FeynFacet`Private`observableTransportEpsilonOrderBelow[(1 + eps)^2/(eps (1 + 2 eps))^2 - 1/eps^2, eps, 3] === -1]];
FTAssert["a lower bound never exceeds the exact order (nested quotient, hidden zero, radical, zero entry)",
  With[{e0 = Symbol["Global`eps"], px = 3/7},
    AllTrue[{eps Sqrt[1 - px] + 1/(eps^2 (1 + 2 eps)), (Sqrt[6/5] - Sqrt[30]/5)/eps^3 + eps^2,
        (3 + eps (1 - px))/(eps^3 (1 + 2 eps) (1 + 5 eps)) - 3/(eps^3 (1 + 2 eps) (1 + 5 eps)), 0, eps^4, 1/(1 + Sqrt[2] - Sqrt[2] + eps)},
      FeynFacet`Private`observableTransportEpsilonOrderLowerBound[#, eps] <=
        FeynFacet`Private`observableTransportEpsilonOrderAtPoint[#, eps] &]]];
FTAssert["the in-place certifier: a dry run leaves the file uncertified, the write certifies it, a repeat reports it certified",
  fileDry["Status"] === "TransportEpsilonValuationsCertified" &&
    fileDry["OutputFile"] === None &&
    fileStatusAfterDry === "TransportEpsilonValuationsUncertified" &&
    fileWet["Status"] === "TransportEpsilonValuationsCertified" &&
    fileWet["OutputFile"] === fileFixture &&
    fileWet["PriorStatus"] === "TransportEpsilonValuationsUncertified" &&
    fileStatusAfterWrite === "TransportEpsilonValuationsCertified" &&
    TrueQ[fileAgain["AlreadyCertified"]]];
FTAssert["the accept predicate refuses a result without its valuation certificate or with an altered one",
  ! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
    KeyDrop[computedTransport,
      "TransportEpsilonValuationCertificate"]] &&
    ! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      Join[computedTransport,
      <|"TransportEpsilonValuationCertificate" -> Join[
        computedTransport["TransportEpsilonValuationCertificate"],
        <|"TMin" -> 0|>]|>]] &&
    ! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      Join[computedTransport,
      <|"Certificates" -> KeyDrop[computedTransport["Certificates"],
        "TransportEpsilonValuationsBound"]|>]]];
FTAssert["tampered residue evidence is rejected fail closed",
  ! IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
    tamperedTransport]];

FTReport[];
