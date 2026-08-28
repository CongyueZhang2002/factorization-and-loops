(* Whole-family multiquadratic certificate: a planted rank-3 gauge is
   certified on all eight embeddings at fresh split points.  Corruptions,
   undeclared/dependent roots, the configured rank ceiling and insufficient
   usable points all fail closed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, verdict_] := If[TrueQ[verdict], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label, " -> ", InputForm[verdict]]];

Clear[v, w, x, y, eps];
sourceVariables = {v, w}; variables = {x, y};
sourceSquares = {1 + v, 1 + w, 1 + v + w};
frame = FeynFacet`BuildAlgebraicTransportFrame[
  sourceSquares, sourceVariables, variables];
roots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
{r1, r2, r3} = Lookup[roots, "Root"];
letters = {(1 + r1)/(1 - r1), (1 + r2)/(1 - r2),
  (1 + r3)/(1 - r3)};
residues = {DiagonalMatrix[{1, 2}], DiagonalMatrix[{-2, 3}],
  DiagonalMatrix[{4, -1}]};
dlog[letter_] := {D[letter, x]/letter, D[letter, y]/letter};
b = Table[eps Sum[residues[[a]] dlog[letters[[a]]][[mu]],
    {a, Length[letters]}], {mu, 2}];
s = {{1, r1/(2 + x)}, {0, 1}};
si = {{1, -r1/(2 + x)}, {0, 1}};
aChart = Table[
  s . b[[mu]] . si + D[s, variables[[mu]]] . si, {mu, 2}];
aSource = aChart /. Thread[variables -> sourceVariables];

record = <|"Family" -> "SyntheticMultiquadraticCertificate",
  "Chart" -> frame["Name"], "ChartRecord" -> frame,
  "Variables" -> variables, "Regulator" -> eps,
  "Blocks" -> {Range[2]}, "Ranges" -> {Range[2]},
  "TTotal" -> s, "TTotalInverse" -> si,
  "EpsFormX" -> b[[1]], "EpsFormY" -> b[[2]],
  "Letters" -> letters|>;
system = <|"Av" -> aSource[[1]], "Aw" -> aSource[[2]]|>;

opts = Sequence["SourceVariables" -> sourceVariables,
  "MultiquadraticTrainingPoints" -> 2,
  "MultiquadraticValidationPoints" -> 2,
  "MultiquadraticPrimes" -> 2,
  "MultiquadraticMaxPrimes" -> 5,
  "MultiquadraticMaxPrimeAttempts" -> 24,
  "MultiquadraticMaxPointAttempts" -> 240];

certified = FeynFacet`CertifyFamilyEpsilonForm[record, system, opts];
certificate = Lookup[certified, "EpsilonFormCertificate", <||>];
modular = Lookup[certificate, "Modular", <||>];
check["rank-3 planted family is high-confidence certified",
  certified["Status"] === "CertifiedEpsilonForm" &&
    FeynFacet`CertifiedFamilyEpsilonFormQ[certified]];
check["finite-field evidence is not branded characteristic-zero exact",
  ! FeynFacet`ExactFamilyEpsilonFormQ[certified] &&
    TrueQ[certificate["Certified"]] &&
    ! TrueQ[certificate["Exact"]] &&
    TrueQ[certificate["Probabilistic"]] &&
    certificate["CertificationLevel"] === "HighConfidenceFiniteField" &&
    certificate["CoefficientField"] === "Multiquadratic" &&
    certified["CertificationMethod"] ===
      "HighConfidenceWholeFamilyFiniteField"];
forgedExactBrand = Join[certified, <|"Status" -> "ExactEpsilonForm"|>];
check["changing only the status cannot forge exact certification",
  ! FeynFacet`ExactFamilyEpsilonFormQ[forgedExactBrand]];
unsafeLegacyBrand = ReplacePart[forgedExactBrand,
  {"EpsilonFormCertificate", "Exact"} -> True];
check["an old probabilistic multiquadratic exact flag is not trusted",
  ! FeynFacet`ExactFamilyEpsilonFormQ[unsafeLegacyBrand]];
tamperedModularStatus = ReplacePart[certified,
  {"EpsilonFormCertificate", "Modular", "Status"} ->
    "CertificateFailed"];
check["the general certified predicate fails closed on altered evidence",
  ! FeynFacet`CertifiedFamilyEpsilonFormQ[tamperedModularStatus]];
check["all eight embeddings are checked at every point",
  modular["RootCount"] === 3 && modular["GradeCount"] === 8 &&
    TrueQ[modular["AllRootSheetsChecked"]] &&
    AllTrue[modular["PointsDone"], #AllSheetsPerPoint === 8 &]];
check["inverse, gauge, both flatness identities and eps factorization pass",
  And @@ (TrueQ[Lookup[certified["Checks"], #, False]] & /@
    {"TransformationInverse", "GaugeIdentity", "SourceFlatness",
     "Flatness", "EpsFactored"})];
check["constant residues are reconstructed and replayed at every prime",
  TrueQ[modular["ConstantResidues"]] &&
    TrueQ[modular["ResiduesVerifiedAtAllPrimes"]] &&
    Length[certified["EpsilonFormCertificate", "DLog", "Residues"]] ===
      Length[letters]];
check["training and validation point sets are disjoint by construction",
  AllTrue[modular["Trials"],
    Count[Lookup[#Points, "Partition", {}], "Training"] === 2 &&
    Count[Lookup[#Points, "Partition", {}], "Validation"] === 2 &]];
check["the rational lift is replayed at two unseen primes",
  Length[modular["ValidationPrimes"]] >= 2 &&
    Intersection[modular["CRTPrimes"], modular["ValidationPrimes"]] === {} &&
    AllTrue[modular["FreshValidationEvidence"],
      #ResidueCoefficientMatch && #TrainingReplay && #ValidationReplay &&
        AllTrue[#Points, #SheetCount === 8 &] &]];

numericOnlyFrame = FeynFacet`Private`familyRegulatorGradedFrameEvidence[
  {<|"Root" -> Sqrt[3], "RootSquare" -> 3|>}, sourceVariables, eps];
numericOnlyRecord = <|
  "Family" -> "SyntheticNumericConstantFieldCertificate",
  "Chart" -> None, "Variables" -> sourceVariables, "Regulator" -> eps,
  "Blocks" -> {{1}}, "Ranges" -> {{1}},
  "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
  "EpsFormX" -> {{0}}, "EpsFormY" -> {{0}}, "Letters" -> {},
  "RegulatorFactorization" -> <|
    "Method" -> "MultiquadraticGradedAlgebra/Synthetic",
    "GradedRootFrame" -> numericOnlyFrame|>|>;
numericOnlyCertified = FeynFacet`CertifyFamilyEpsilonForm[
  numericOnlyRecord, <|"Av" -> {{0}}, "Aw" -> {{0}}|>,
  "SourceVariables" -> sourceVariables,
  "MultiquadraticTrainingPoints" -> 1,
  "MultiquadraticValidationPoints" -> 1,
  "MultiquadraticPrimes" -> 2,
  "MultiquadraticMaxPrimes" -> 4,
  "MultiquadraticFreshValidationPrimes" -> 2,
  "MultiquadraticMaxPrimeAttempts" -> 24,
  "MultiquadraticMaxPointAttempts" -> 80];
check["whole-family certification consumes an authenticated numeric constant-field frame",
  numericOnlyCertified["Status"] === "CertifiedEpsilonForm" &&
    numericOnlyCertified["EpsilonFormCertificate", "Modular", "RootCount"] === 1 &&
    numericOnlyCertified["EpsilonFormCertificate", "Modular",
      "RegulatorRootFrameEvidenceCount"] === 1];
missingNumericFrame = FeynFacet`CertifyFamilyEpsilonForm[
  ReplacePart[numericOnlyRecord,
    "RegulatorFactorization" -> <|
      "Method" -> "MultiquadraticGradedAlgebra/Synthetic"|>],
  <|"Av" -> {{0}}, "Aw" -> {{0}}|>,
  "SourceVariables" -> sourceVariables];
check["a graded regulator factorization without root-frame evidence fails closed",
  missingNumericFrame["Status"] === "RegulatorRootFrameMetadataMissing"];

freshTrialFixture = <|"Status" -> "UsablePrime", "Prime" -> 7,
  "PivotColumns" -> {1}, "Coefficients" -> {{4}},
  "TrainingRows" -> {{2}}, "TrainingRhs" -> {{1}},
  "ValidationRows" -> {{4}}, "ValidationRhs" -> {{2}},
  "TrainingPoints" -> 1, "ValidationPoints" -> 1,
  "AllSheetsPerPoint" -> 8,
  "Checks" -> AssociationThread[
    {"TransformationInverse", "GaugeIdentity", "Flatness", "EpsFactored",
     "SourceFlatness", "DLog", "ConstantResidues"},
    ConstantArray[True, 7]]|>;
goodLiftFixture = <|"Status" -> "ReconstructedResidues",
  "PivotColumns" -> {1}, "PivotCoefficientTable" -> {{1/2}}|>;
wrongLiftFixture = ReplacePart[goodLiftFixture,
  "PivotCoefficientTable" -> {{3/2}}];
check["fresh-prime validator accepts the correct lift and rejects a wrong one",
  FeynFacet`Private`familyCertMQValidateResiduesAtTrial[
    goodLiftFixture, freshTrialFixture]["Status"] === "FreshPrimeValidated" &&
  FeynFacet`Private`familyCertMQValidateResiduesAtTrial[
    wrongLiftFixture, freshTrialFixture]["Status"] ===
      "FreshPrimeResidueMismatch"];

pivotTrial[prime_, pivots_] := <|"Status" -> "UsablePrime",
  "Prime" -> prime, "PivotColumns" -> pivots,
  "DLogRank" -> Length[pivots],
  "DLogPivotSignature" -> {Length[pivots], pivots},
  "DLogPivotSignatureFingerprint" ->
    Hash[{Length[pivots], pivots}, "SHA256", "HexString"]|>;
modalPivot = FeynFacet`Private`familyCertMQSelectModalPivotTrials[
  {pivotTrial[7, {1}], pivotTrial[11, {2}], pivotTrial[19, {2}]}, 2];
check["a poisoned first-prime pivot cannot override a two-prime modal quorum",
  modalPivot["Status"] === "ModalDLogPivotSignature" &&
    modalPivot["PivotColumns"] === {2} &&
    Lookup[modalPivot["Trials"], "Prime", {}] === {11, 19} &&
    Lookup[modalPivot["RejectedTrials"], "Prime", {}] === {7}];
unstablePivot = FeynFacet`Private`familyCertMQSelectModalPivotTrials[
  {pivotTrial[7, {1}], pivotTrial[11, {2}], pivotTrial[19, {3}]}, 2];
check["three distinct pivot signatures fail typed instead of locking the first",
  unstablePivot["Status"] === "DLogPivotStructureUnstable"];

constantBasisChange = {{1, 1}, {0, 1}};
badGaugeRecord = Join[record, <|
  "TTotal" -> s . constantBasisChange,
  "TTotalInverse" -> Inverse[constantBasisChange] . si|>];
badGauge = FeynFacet`CertifyFamilyEpsilonForm[badGaugeRecord, system, opts];
check["a corrupted target connection is rejected at the gauge identity",
  badGauge["Status"] === "EpsilonFormCertificationFailed" &&
    ! TrueQ[Lookup[badGauge["Checks"], "GaugeIdentity", True]]];

badEpsilonRecord = ReplacePart[record,
  "EpsFormY" -> (1 + eps) record["EpsFormY"]];
badEpsilon = FeynFacet`CertifyFamilyEpsilonForm[badEpsilonRecord, system, opts];
check["nonlinear regulator dependence is rejected",
  badEpsilon["Status"] === "EpsilonFormCertificationFailed" &&
    ! TrueQ[Lookup[badEpsilon["Checks"], "EpsFactored", True]]];

noLetters = FeynFacet`CertifyFamilyEpsilonForm[
  Join[record, <|"Letters" -> {}|>], system, opts];
check["a nonzero algebraic form with an empty alphabet is rejected",
  noLetters["Status"] === "EpsilonFormCertificationFailed" &&
    ! TrueQ[Lookup[noLetters["Checks"], "DLog", True]]];

undeclaredRecord = ReplacePart[record,
  {"EpsFormX", 1, 1} -> record["EpsFormX", 1, 1] +
    eps Sqrt[2 + 3 x]/(7 + x)];
undeclared = FeynFacet`CertifyFamilyEpsilonForm[undeclaredRecord, system, opts];
check["an undeclared radical fails closed before sampling",
  undeclared["Status"] === "ModularCertificateFailed" &&
    Lookup[undeclared["Modular"], "Status", None] === "UndeclaredRadicals"];

minimalObjects = <|"S" -> {{1}}, "Si" -> {{1}}, "B1" -> {{0}},
  "B2" -> {{0}}, "dSx" -> {{0}}, "dSy" -> {{0}},
  "dB1y" -> {{0}}, "dB2x" -> {{0}}, "Av" -> {{0}}, "Aw" -> {{0}},
  "dAvw" -> {{0}}, "dAwv" -> {{0}}, "Jacobian" -> IdentityMatrix[2],
  "Letters" -> {}, "LetterX" -> {}, "LetterY" -> {}|>;
dependentRoots = {<|"Root" -> Sqrt[1 + x], "RootSquare" -> 1 + x|>,
  <|"Root" -> Sqrt[1 + y], "RootSquare" -> 1 + y|>,
  <|"Root" -> Sqrt[(1 + x) (1 + y)],
    "RootSquare" -> (1 + x) (1 + y)|>};
dependent = FeynFacet`Private`familyCertMQPrepare[minimalObjects,
  dependentRoots, variables, eps, 3];
check["a dependent declared root frame is refused",
  dependent["Status"] === "DependentRootSquares"];

rankFourRoots = Append[roots,
  <|"Root" -> Sqrt[2 + x + 3 y], "RootSquare" -> 2 + x + 3 y|>];
rankFour = FeynFacet`Private`familyCertMQPrepare[minimalObjects,
  rankFourRoots, variables, eps, 3];
check["rank three is a configurable resource ceiling",
  rankFour["Status"] === "RootRankTooLarge" &&
    rankFour["RootCount"] === 4];

numericFrameEvidence = FeynFacet`Private`familyRegulatorGradedFrameEvidence[
  Append[roots, <|"Root" -> Sqrt[3], "RootSquare" -> 3|>],
  variables, eps];
authenticatedNumericFrame =
  FeynFacet`Private`familyCertMQAuthenticateRegulatorRootFrames[
    roots, {numericFrameEvidence}, variables, eps, 5];
check["declared numeric square classes extend and authenticate the certificate frame",
  authenticatedNumericFrame["Status"] ===
      "AuthenticatedRegulatorRootFrames" &&
    authenticatedNumericFrame["RootCount"] === 4 &&
    authenticatedNumericFrame["GradeCount"] === 16 &&
    authenticatedNumericFrame["EvidenceCount"] === 1];
rankLimitedNumericFrame =
  FeynFacet`Private`familyCertMQAuthenticateRegulatorRootFrames[
    roots, {numericFrameEvidence}, variables, eps, 3];
check["an explicit certificate ceiling still refuses a larger authenticated producer frame",
  rankLimitedNumericFrame["Status"] === "RootRankTooLarge" &&
    rankLimitedNumericFrame["RootCount"] === 4 &&
    rankLimitedNumericFrame["RootRankLimit"] === 3 &&
    rankLimitedNumericFrame["ProducerMaximumRank"] === 5];
tamperedNumericFrame = ReplacePart[numericFrameEvidence,
  "OrderingFingerprint" -> StringReverse[
    numericFrameEvidence["OrderingFingerprint"]]];
check["altered regulator root-frame metadata fails authentication",
  FeynFacet`Private`familyCertMQAuthenticateRegulatorRootFrames[
    roots, {tamperedNumericFrame}, variables, eps, 5]["Status"] ===
      "RegulatorRootFrameAuthenticationFailed"];

sparseNoDenestObjects = Join[minimalObjects,
  <|"B1" -> SparseArray[{{0}}]|>];
sparseNoDenest = FeynFacet`Private`familyCertMQPrepare[
  sparseNoDenestObjects, {}, variables, eps, 5];
check["the no-denesting branch consumes normalized sparse containers",
  sparseNoDenest["Status"] === "PreparedMultiquadraticCertificate" &&
    ListQ[sparseNoDenest["Objects", "B1"]]];
sparseDenestRoots = {
  <|"Root" -> Sqrt[1 + x], "RootSquare" -> 1 + x|>,
  <|"Root" -> Sqrt[2], "RootSquare" -> 2|>};
(* Keep the radicand expanded.  Sqrt[2 (1 + x)] evaluates immediately to
   the product of the two declared radicals and therefore (correctly) takes
   the direct-substitution path with DenestedRadicals -> 0.  The expanded
   but algebraically identical base remains one syntactic radical, forcing
   the exact active-denesting branch this fixture is meant to cover. *)
sparseDenestObjects = Join[minimalObjects,
  <|"B1" -> SparseArray[{{eps Sqrt[2 + 2 x]}}]|>];
sparseDenest = FeynFacet`Private`familyCertMQPrepare[
  sparseDenestObjects, sparseDenestRoots, variables, eps, 5];
check["the active-denesting branch consumes the same normalized containers",
  sparseDenest["Status"] === "PreparedMultiquadraticCertificate" &&
    ListQ[sparseDenest["Objects", "B1"]] &&
    sparseDenest["DenestedRadicals"] >= 1];

constantRoot = {<|"Root" -> Sqrt[3], "RootSquare" -> 3|>};
constantObjects = Join[minimalObjects,
  <|"B1" -> {{eps Sqrt[3]}}, "Letters" -> {Exp[x Sqrt[3]]},
    "LetterX" -> {{Sqrt[3]}}, "LetterY" -> {{0}}|>];
preparedConstant = FeynFacet`Private`familyCertMQPrepare[
  constantObjects, constantRoot, variables, eps, 1];
insufficient = FeynFacet`Private`familyCertMQTrial[preparedConstant,
  variables, eps, 7, 1, 1, 4];
check["too few usable split points is a typed refusal",
  insufficient["Status"] === "InsufficientUsablePoints" &&
    insufficient["UsablePoints"] === 0];

Print["t_family_certificate_multiquadratic: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
