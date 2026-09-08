BeginPackage["CodexCF300ExactQepsLeftObstruction`", {
  "CodexDirectRootChannelAssembler`"}];

EQWRequirementsFromV6d::usage =
  "EQWRequirementsFromV6d[result] extracts the exact point/plan capture requirements pinned by a frozen CF300 V6d result.";
EQWPrerequisiteValidQ::usage =
  "EQWPrerequisiteValidQ[artifact,requirements] validates a captured 30-point V6d plan without discovering or changing its pivots.";
EQWAssembleExactSample::usage =
  "EQWAssembleExactSample[assembly,eps,points] assembles the direct multiquadratic grade equations exactly over Q(eps) at fixed rational points.";
EQWConstruct::usage =
  "EQWConstruct[A,b,eps,plan,reconstruction] verifies a source-pinned modularly reconstructed canonical left witness and proves y^T A=0, y^T b=1 after clearing denominators; it never performs the 889-by-889 symbolic solve.";
EQWFingerprint::usage =
  "EQWFingerprint[value] is the InputForm SHA256 convention used by the V6d artifacts.";
EQWCanonicalQeps::usage =
  "EQWCanonicalQeps[value,eps] cancels a rational function and normalizes its epsilon denominator to be monic.";

Begin["`Private`"];

ClearAll[eqwFailure, eqwQepsQ, eqwCanonicalQeps,
  eqwClearedIdentity, eqwNonzeroIndices, eqwImageByID,
  eqwBalancedResidue, eqwCanonicalRationalLift,
  eqwDeltaMaskFactor, eqwGaugeIndex, eqwResidueIndex,
  eqwPointRowIndex, eqwAssemblePoint, eqwNormalizationRows,
  eqwPlanArraysValidQ];

$eqwExpectedV6dArtifactSHA256 =
  "20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf";
$eqwExpectedOrbitCoreV6dSHA256 =
  "7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed";
$eqwExpectedMaximalAssemblyFingerprint =
  "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7";
$eqwExpectedAnchorPointFingerprint =
  "f4ac00e6c1636c2f20028a2de449ea66a816ea017a84de6874dd63e54e155b50";
$eqwExpectedCoefficientPivotFingerprint =
  "ccc7fa776fdcf55017e98e8d57ee2480690db3c27e0dc8f8625acebd79bfe377";
$eqwExpectedCoefficientFreeFingerprint =
  "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534";
$eqwExpectedCoefficientRowFingerprint =
  "9924c7eef76fea745d5451876be6012810e205e7ca28e021dd99cb2c720d9914";
$eqwExpectedAugmentedPivotFingerprint =
  "8a9731fd7c345e781d71102d9cb3f8f0d745de3b17264e11b62ef538af0cb761";
$eqwExpectedAugmentedFreeFingerprint =
  "2c25a885fd903d2e0f828c13ecd6e2a9a36babfbe6decb4f4f3af3335cdc9534";
$eqwExpectedAugmentedRowFingerprint =
  "3f35c25a1819c8c11ee28d300e252c47beda7f8213bcd45ac54f417fba3023a7";

eqwFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "CF300ExactQepsLeftObstructionFailure",
    "FailureReason" -> reason|>, data];

EQWFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

eqwImageByID[result_Association, imageID_String] := Module[{matches},
  matches = Select[Lookup[result, "ImageResults", {}],
    AssociationQ[#1] && Lookup[#1, "ImageID", None] === imageID &];
  If[Length[matches] === 1, First[matches], $Failed]
];

EQWRequirementsFromV6d[result_Association] := Module[
  {images, anchor, fullRanks, coefficientCertificates,
   augmentedCertificates, scoreRecords, scoreIndexBugDetected},
  If[Lookup[result, "Status", None] =!=
      "CF300Sector12GaloisOrbitForcingScreenPassedV6d" ||
      Lookup[result, "MaximalAssemblyFingerprint", None] =!=
        $eqwExpectedMaximalAssemblyFingerprint ||
      Lookup[result, "PointCount", None] =!= 30,
    Return[eqwFailure["InvalidFrozenV6dResult"]]];
  images = Lookup[result, "ImageResults", $Failed];
  anchor = eqwImageByID[result, "I00"];
  If[! MatchQ[images, {_Association, _Association, _Association,
        _Association}] || anchor === $Failed,
    Return[eqwFailure["IncompleteFrozenV6dImages"]]];
  fullRanks = Lookup[images, "FullRank", $Failed];
  coefficientCertificates = Lookup[fullRanks,
    "CoefficientCertificate", $Failed];
  augmentedCertificates = Lookup[fullRanks,
    "AugmentedCertificate", $Failed];
  scoreRecords = Lookup[images,
    "AppendedOrbitColumnWitnessScore", $Failed];
  If[! AllTrue[fullRanks, AssociationQ] ||
      ! AllTrue[coefficientCertificates, AssociationQ] ||
      ! AllTrue[augmentedCertificates, AssociationQ] ||
      ! AllTrue[scoreRecords, AssociationQ],
    Return[eqwFailure["IncompleteFrozenV6dCertificates"]]];

  (* V6d's recorded score columns contain 0..288 for a 288-column
     matrix.  This is metadata only: never use those indices or Position
     with head traversal to construct the exact witness. *)
  scoreIndexBugDetected = AllTrue[scoreRecords, Function[score,
    Lookup[score, "CandidateMatrixDimensions", {0, 0}][[2]] === 288 &&
    Lookup[score, "NonzeroScoreCount", -1] === 289 &&
    Lookup[score, "NonzeroScoreColumns", {}] === Range[0, 288]]];

  If[Lookup[anchor, "AcceptedPointsFingerprint", None] =!=
        $eqwExpectedAnchorPointFingerprint ||
      ! AllTrue[coefficientCertificates,
        Lookup[#1, "PivotFingerprint", None] ===
            $eqwExpectedCoefficientPivotFingerprint &&
          Lookup[#1, "FreeColumnFingerprint", None] ===
            $eqwExpectedCoefficientFreeFingerprint &&
          Lookup[#1, "RowWitnessFingerprint", None] ===
            $eqwExpectedCoefficientRowFingerprint &] ||
      ! AllTrue[augmentedCertificates,
        Lookup[#1, "PivotFingerprint", None] ===
            $eqwExpectedAugmentedPivotFingerprint &&
          Lookup[#1, "FreeColumnFingerprint", None] ===
            $eqwExpectedAugmentedFreeFingerprint &&
          Lookup[#1, "RowWitnessFingerprint", None] ===
            $eqwExpectedAugmentedRowFingerprint &],
    Return[eqwFailure["FrozenV6dFingerprintMismatch"]]];

  <|"Status" -> "CF300V6dExactLiftRequirementsV1",
    "SourceV6dArtifactSHA256" -> $eqwExpectedV6dArtifactSHA256,
    "OrbitCoreV6dSHA256" -> $eqwExpectedOrbitCoreV6dSHA256,
    "MaximalAssemblyFingerprint" ->
      $eqwExpectedMaximalAssemblyFingerprint,
    "MatrixDimensions" -> {960, 912},
    "CoefficientRank" -> 888, "AugmentedRank" -> 889,
    "AnchorImageID" -> "I00", "AnchorPrime" -> 10007,
    "AnchorEpsilonValue" -> 1/21, "PointCount" -> 30,
    "AnchorAcceptedPointsFingerprint" ->
      $eqwExpectedAnchorPointFingerprint,
    "CoefficientPivotFingerprint" ->
      $eqwExpectedCoefficientPivotFingerprint,
    "CoefficientFreeFingerprint" ->
      $eqwExpectedCoefficientFreeFingerprint,
    "CoefficientIndependentRowFingerprint" ->
      $eqwExpectedCoefficientRowFingerprint,
    "AugmentedPivotFingerprint" ->
      $eqwExpectedAugmentedPivotFingerprint,
    "AugmentedFreeFingerprint" ->
      $eqwExpectedAugmentedFreeFingerprint,
    "AugmentedIndependentRowFingerprint" ->
      $eqwExpectedAugmentedRowFingerprint,
    "CrossImagePlanFingerprintStable" -> True,
    "V6dScorePositionHeadTraversalBugDetected" ->
      scoreIndexBugDetected,
    "V6dPersistedAcceptedPointValues" ->
      KeyExistsQ[anchor, "AcceptedPoints"],
    "V6dPersistedPivotAndRowArrays" -> And @@ {
      KeyExistsQ[First[coefficientCertificates], "PivotColumns"],
      KeyExistsQ[First[coefficientCertificates], "FreeColumns"],
      KeyExistsQ[First[coefficientCertificates],
        "IndependentEquationRows"],
      KeyExistsQ[First[augmentedCertificates], "PivotColumns"],
      KeyExistsQ[First[augmentedCertificates], "FreeColumns"],
      KeyExistsQ[First[augmentedCertificates],
        "IndependentEquationRows"]}|>
];

EQWRequirementsFromV6d[___] :=
  eqwFailure["InvalidFrozenV6dResult"];

eqwPlanArraysValidQ[plan_Association, rows_Integer,
    columns_Integer] := Module[
  {coefficientPivots, coefficientFree, coefficientRows,
   augmentedPivots, augmentedFree, augmentedRows},
  coefficientPivots = Lookup[plan, "CoefficientPivotColumns", $Failed];
  coefficientFree = Lookup[plan, "CoefficientFreeColumns", $Failed];
  coefficientRows = Lookup[plan,
    "CoefficientIndependentEquationRows", $Failed];
  augmentedPivots = Lookup[plan, "AugmentedPivotColumns", $Failed];
  augmentedFree = Lookup[plan, "AugmentedFreeColumns", $Failed];
  augmentedRows = Lookup[plan,
    "AugmentedIndependentEquationRows", $Failed];
  TrueQ[
    Lookup[plan, "MatrixDimensions", None] === {rows, columns} &&
    Lookup[plan, "CoefficientRank", None] === 888 &&
    Lookup[plan, "AugmentedRank", None] === 889 &&
    VectorQ[coefficientPivots, IntegerQ] &&
    VectorQ[coefficientFree, IntegerQ] &&
    VectorQ[coefficientRows, IntegerQ] &&
    VectorQ[augmentedPivots, IntegerQ] &&
    VectorQ[augmentedFree, IntegerQ] &&
    VectorQ[augmentedRows, IntegerQ] &&
    DuplicateFreeQ /@ {coefficientPivots, coefficientFree,
        coefficientRows, augmentedPivots, augmentedFree,
        augmentedRows} === ConstantArray[True, 6] &&
    Length[coefficientPivots] === 888 &&
    Length[coefficientFree] === 24 &&
    Length[coefficientRows] === 888 &&
    Length[augmentedPivots] === 889 &&
    Length[augmentedFree] === 24 &&
    Length[augmentedRows] === 889 &&
    Sort[Join[coefficientPivots, coefficientFree]] ===
      Range[columns] &&
    Sort[Join[augmentedPivots, augmentedFree]] ===
      Range[columns + 1] &&
    Complement[augmentedPivots, coefficientPivots] ===
      {columns + 1} &&
    augmentedFree === coefficientFree &&
    Min[coefficientRows] >= 1 && Max[coefficientRows] <= rows &&
    Min[augmentedRows] >= 1 && Max[augmentedRows] <= rows &&
    EQWFingerprint[coefficientPivots] ===
      $eqwExpectedCoefficientPivotFingerprint &&
    Lookup[plan, "CoefficientPivotFingerprint", None] ===
      $eqwExpectedCoefficientPivotFingerprint &&
    EQWFingerprint[coefficientFree] ===
      $eqwExpectedCoefficientFreeFingerprint &&
    Lookup[plan, "CoefficientFreeFingerprint", None] ===
      $eqwExpectedCoefficientFreeFingerprint &&
    EQWFingerprint[coefficientRows] ===
      $eqwExpectedCoefficientRowFingerprint &&
    Lookup[plan, "CoefficientIndependentRowFingerprint", None] ===
      $eqwExpectedCoefficientRowFingerprint &&
    EQWFingerprint[augmentedPivots] ===
      $eqwExpectedAugmentedPivotFingerprint &&
    Lookup[plan, "AugmentedPivotFingerprint", None] ===
      $eqwExpectedAugmentedPivotFingerprint &&
    EQWFingerprint[augmentedFree] ===
      $eqwExpectedAugmentedFreeFingerprint &&
    Lookup[plan, "AugmentedFreeFingerprint", None] ===
      $eqwExpectedAugmentedFreeFingerprint &&
    EQWFingerprint[augmentedRows] ===
      $eqwExpectedAugmentedRowFingerprint &&
    Lookup[plan, "AugmentedIndependentRowFingerprint", None] ===
      $eqwExpectedAugmentedRowFingerprint]
];

eqwPlanArraysValidQ[___] := False;

eqwBalancedResidue[value_Integer, prime_Integer] := Module[
  {residue = Mod[value, prime]},
  If[2 residue > prime, residue - prime, residue]
];

eqwCanonicalRationalLift[residue_Integer, prime_Integer] := Module[
  {bound = Floor[Sqrt[prime]], candidates, numerator, value},
  candidates = DeleteDuplicates[Table[
    numerator = eqwBalancedResidue[residue denominator, prime];
    value = Cancel[numerator/denominator];
    If[Denominator[value] <= bound &&
        Mod[Numerator[value] PowerMod[Denominator[value], -1, prime],
          prime] === Mod[residue, prime], value, Nothing],
    {denominator, 1, bound}]];
  If[candidates === {}, $Failed,
    First[SortBy[candidates, Function[candidate,
      {Max[Abs[Numerator[candidate]], Denominator[candidate]],
       Abs[Numerator[candidate]] + Denominator[candidate],
       Denominator[candidate], Numerator[candidate]}]]]]
];

EQWPrerequisiteValidQ[artifact_Association,
    requirements_Association] := Module[
  {assembly, residues, points, plan, lift, coordinateRecords,
   capturePolicy, revalidation},
  assembly = Lookup[artifact, "MaximalAssembly", $Failed];
  residues = Lookup[artifact, "AnchorAcceptedPointResidues", $Failed];
  points = Lookup[artifact, "ExactRationalPointLifts", $Failed];
  plan = Lookup[artifact, "StablePlan", $Failed];
  lift = Lookup[artifact, "PointLiftCertificate", $Failed];
  coordinateRecords = If[AssociationQ[lift],
    Lookup[lift, "CoordinateRecords", $Failed], $Failed];
  capturePolicy = Lookup[artifact, "CapturePolicy", $Failed];
  revalidation = Lookup[artifact, "AnchorPlanRevalidation", $Failed];
  TrueQ[
    Lookup[artifact, "Status", None] ===
      "CF300V6dExactLiftPrerequisiteV1" &&
    Lookup[requirements, "Status", None] ===
      "CF300V6dExactLiftRequirementsV1" &&
    Lookup[artifact, "SourceV6dArtifactSHA256", None] ===
      requirements["SourceV6dArtifactSHA256"] &&
    Lookup[artifact, "OrbitCoreV6dSHA256", None] ===
      requirements["OrbitCoreV6dSHA256"] &&
    Lookup[artifact, "MaximalAssemblyFingerprint", None] ===
      requirements["MaximalAssemblyFingerprint"] &&
    AssociationQ[assembly] &&
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      assembly] &&
    Lookup[assembly, "AssemblyFingerprint", None] ===
      requirements["MaximalAssemblyFingerprint"] &&
    Lookup[artifact, "AnchorImageID", None] === "I00" &&
    Lookup[artifact, "AnchorPrime", None] === 10007 &&
    Lookup[artifact, "AnchorEpsilonValue", None] === 1/21 &&
    MatchQ[residues, {{_Integer, _Integer} ..}] &&
    Length[residues] === 30 && DuplicateFreeQ[residues] &&
    AllTrue[Flatten[residues], 0 <= #1 < 10007 &] &&
    EQWFingerprint[residues] ===
      requirements["AnchorAcceptedPointsFingerprint"] &&
    Lookup[artifact, "AnchorAcceptedPointsFingerprint", None] ===
      requirements["AnchorAcceptedPointsFingerprint"] &&
    MatchQ[points, {{_Integer | _Rational,
        _Integer | _Rational} ..}] && Length[points] === 30 &&
    DuplicateFreeQ[points] &&
    points === Map[eqwCanonicalRationalLift[#1, 10007] &,
      residues, {2}] &&
    AssociationQ[lift] &&
    Lookup[lift, "Status", None] ===
      "CertifiedBalancedRationalPointLiftV1" &&
    Lookup[lift, "Prime", None] === 10007 &&
    Lookup[lift, "SearchDenominatorBound", None] === 100 &&
    Lookup[lift, "TieBreak", None] ===
      "Lexicographic {Max[Abs[a],b],Abs[a]+b,b,a}" &&
    Lookup[lift, "ResidueFingerprint", None] ===
      requirements["AnchorAcceptedPointsFingerprint"] &&
    Lookup[lift, "LiftFingerprint", None] === EQWFingerprint[points] &&
    MatchQ[coordinateRecords, {_Association ..}] &&
    Length[coordinateRecords] === 60 &&
    And @@ Lookup[lift, {"AllDenominatorsInvertible",
      "AllReductionsExact", "ExactPointsDistinctOverQ",
      "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon",
      "CapturedPlanRevalidatedAtLiftedResidues"}, False] &&
    AllTrue[coordinateRecords, Function[record,
      IntegerQ[Lookup[record, "PointIndex", None]] &&
      Between[record["PointIndex"], {1, 30}] &&
      MemberQ[{1, 2}, Lookup[record, "CoordinateIndex", None]] &&
      IntegerQ[Lookup[record, "Residue", None]] &&
      IntegerQ[Lookup[record, "Numerator", None]] &&
      IntegerQ[Lookup[record, "Denominator", None]] &&
      record["Denominator"] > 0 && record["Denominator"] <= 100 &&
      TrueQ[Lookup[record, "ReductionMatches", False]] &&
      Mod[record["Numerator"] PowerMod[
        record["Denominator"], -1, 10007], 10007] ===
        record["Residue"]]] &&
    And @@ Flatten[Table[With[{record =
        coordinateRecords[[2 (pointIndex - 1) + coordinateIndex]],
        value = Together[points[[pointIndex, coordinateIndex]]]},
      record["PointIndex"] === pointIndex &&
      record["CoordinateIndex"] === coordinateIndex &&
      record["Residue"] === residues[[pointIndex, coordinateIndex]] &&
      record["Numerator"] === Numerator[value] &&
      record["Denominator"] === Denominator[value] &&
      Lookup[record, "Height", None] ===
        Max[Abs[Numerator[value]], Denominator[value]] &&
      Lookup[record, "Reduction", None] ===
        residues[[pointIndex, coordinateIndex]]],
      {pointIndex, 30}, {coordinateIndex, 2}]] &&
    AssociationQ[revalidation] &&
    Lookup[revalidation, "Prime", None] === 10007 &&
    Lookup[revalidation, "EpsilonValue", None] === 1/21 &&
    TrueQ[Lookup[revalidation, "PlanArraysRevalidated", False]] &&
    TrueQ[Lookup[revalidation, "FullResidualRevalidated", False]] &&
    Lookup[revalidation, "CoefficientRank", None] === 888 &&
    Lookup[revalidation, "AugmentedRank", None] === 889 &&
    AssociationQ[capturePolicy] &&
    And @@ Lookup[capturePolicy, {
      "ReproduceOriginalV6dSeedAndCandidateOrder",
      "CompareRecoveredPointFingerprintBeforeLift",
      "CompareAllPlanArrayFingerprintsBeforeLift",
      "RequireCrossImageFingerprintStability"}, False] &&
    TrueQ[Lookup[capturePolicy,
      "AllowPlanRediscoveryInExactDriver", True] === False] &&
    TrueQ[Lookup[capturePolicy,
      "ConsumeV6dScoreColumnIndices", True] === False] &&
    AssociationQ[plan] &&
    eqwPlanArraysValidQ[plan, 960, 912]]
];

EQWPrerequisiteValidQ[___] := False;

eqwQepsQ[value_, epsilon_Symbol] := Module[{rational, numerator,
    denominator, coefficients},
  rational = Quiet[Check[Cancel[Together[value]], $Failed]];
  If[rational === $Failed || ! FreeQ[rational,
      Indeterminate | ComplexInfinity | DirectedInfinity | _Overflow],
    Return[False]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[! PolynomialQ[numerator, epsilon] ||
      ! PolynomialQ[denominator, epsilon] ||
      TrueQ[denominator === 0], Return[False]];
  coefficients = Join[CoefficientList[numerator, epsilon],
    CoefficientList[denominator, epsilon]];
  AllTrue[coefficients,
    IntegerQ[#1] || Head[#1] === Rational &]
];

eqwCanonicalQeps[value_, epsilon_Symbol] := Module[
  {rational, numerator, denominator, degree, leading},
  rational = Cancel[Together[value]];
  numerator = Expand[Numerator[rational]];
  denominator = Expand[Denominator[rational]];
  degree = Exponent[denominator, epsilon];
  leading = Coefficient[denominator, epsilon, degree];
  Cancel[(numerator/leading)/(denominator/leading)]
];

EQWCanonicalQeps[value_, epsilon_Symbol] :=
  eqwCanonicalQeps[value, epsilon];
EQWCanonicalQeps[___] := $Failed;

eqwClearedIdentity[value_, epsilon_Symbol] := Module[
  {rational, numerator, denominator},
  rational = Quiet[Check[Cancel[Together[value]], $Failed]];
  If[rational === $Failed,
    Return[<|"Status" -> "ClearedIdentityFailure"|>]];
  numerator = Expand[Numerator[rational]];
  denominator = Expand[Denominator[rational]];
  <|"Status" -> "ExactClearedDenominatorIdentityV1",
    "NumeratorZero" -> TrueQ[numerator === 0],
    "DenominatorNonzero" -> ! TrueQ[denominator === 0],
    "NumeratorFingerprint" -> EQWFingerprint[numerator],
    "DenominatorFingerprint" -> EQWFingerprint[denominator],
    "DenominatorDegree" -> Exponent[denominator, epsilon]|>
];

(* Pick over an explicit 1-based range cannot visit the list head.  This
   deliberately replaces the erroneous Position[..., Heads -> True]
   pattern seen in the recorded V6d score metadata. *)
eqwNonzeroIndices[values_List] := Pick[Range[Length[values]],
  Map[Function[value, ! TrueQ[value === 0]], values]];

eqwDeltaMaskFactor[mask_Integer, deltaValues_List] := Times @@
  Pick[deltaValues, BitGet[mask,
    If[deltaValues === {}, {}, Range[0, Length[deltaValues] - 1]]], 1];

eqwGaugeIndex[i_Integer, j_Integer, grade_Integer,
    monomial_Integer, lowerDimension_Integer, gradeCount_Integer,
    supportCount_Integer] :=
  (((i - 1) lowerDimension + (j - 1)) gradeCount + grade)
    supportCount + monomial;

eqwResidueIndex[letter_Integer, i_Integer, j_Integer,
    gaugeUnknownCount_Integer, upperDimension_Integer,
    lowerDimension_Integer] := gaugeUnknownCount +
  ((letter - 1) upperDimension + (i - 1)) lowerDimension + j;

eqwPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1))
    lowerDimension + j;

eqwAssemblePoint[assembly_Association, epsilon_Symbol,
    point : {_Integer | _Rational, _Integer | _Rational}] :=
  Catch[Module[
    {variables = assembly["Variables"], dimensions = assembly["Dimensions"],
     upperDimension, lowerDimension, rootCount = assembly["RootCount"],
     gradeCount = assembly["GradeCount"], support = assembly["GaugeSupport"],
     supportCount, gaugeUnknownCount = assembly["GaugeUnknownCount"],
     unknownCount = assembly["UnknownCount"], exact, leaves,
     deltaValues, deltaMaskFactors, denominatorValue,
     gaugeLogDerivatives, rootLogDerivatives, eValues, cValues,
     bbarValues, oneFormValues, monomialValues, basisValues,
     basisDerivatives, productGrades, productWeights, rows, right,
     rowIndex, gaugeRow, residueRow, sourceGrade, targetGrade, mu,
     i, j, a, b, monomial, letter, productGrade, productWeight},
    {upperDimension, lowerDimension} = dimensions;
    supportCount = Length[support];
    If[MemberQ[point, 0] || ! FreeQ[point, epsilon],
      Throw[eqwFailure["InvalidExactPoint", <|"Point" -> point|>]]];
    exact = assembly["ExactChannelForms"] /.
      Thread[variables -> point];
    leaves = Flatten[Values[exact]];
    If[! AllTrue[leaves, eqwQepsQ[#1, epsilon] &],
      Throw[eqwFailure["PointNotOverQeps", <|"Point" -> point|>]]];
    deltaValues = exact["RootSquares"];
    denominatorValue = exact["GaugeDenominator"];
    If[Length[deltaValues] =!= rootCount ||
        AnyTrue[deltaValues, TrueQ[Cancel[Together[#1]] === 0] &] ||
        TrueQ[Cancel[Together[denominatorValue]] === 0],
      Throw[eqwFailure["ExactPointSingular", <|"Point" -> point|>]]];
    gaugeLogDerivatives = exact["GaugeLogDerivatives"];
    rootLogDerivatives = exact["RootLogDerivatives"];
    eValues = exact["E"];
    cValues = exact["C"];
    bbarValues = exact["BBar"];
    oneFormValues = exact["OneForms"];
    deltaMaskFactors = eqwDeltaMaskFactor[#1, deltaValues] & /@
      Range[0, gradeCount - 1];
    monomialValues = (point[[1]]^#1[[1]] point[[2]]^#1[[2]] &) /@
      support;
    basisValues = monomialValues/denominatorValue;
    basisDerivatives = Table[
      basisValues[[monomial]] (
        If[mu === 1, support[[monomial, 1]]/point[[1]],
          support[[monomial, 2]]/point[[2]]] -
        gaugeLogDerivatives[[mu]] + 1/2 Sum[
          If[BitGet[sourceGrade, a - 1] === 1,
            rootLogDerivatives[[a, mu]], 0], {a, rootCount}]),
      {mu, 2}, {sourceGrade, 0, gradeCount - 1},
      {monomial, supportCount}];
    productGrades = Table[BitXor[targetGrade, sourceGrade],
      {targetGrade, 0, gradeCount - 1},
      {sourceGrade, 0, gradeCount - 1}];
    productWeights = Table[
      productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
      epsilon basisValues[[monomial]]
        deltaMaskFactors[[BitAnd[productGrade, sourceGrade] + 1]],
      {targetGrade, 0, gradeCount - 1},
      {sourceGrade, 0, gradeCount - 1},
      {monomial, supportCount}];
    rows = Table[ConstantArray[0, unknownCount],
      assembly["EquationsPerPoint"]];
    right = ConstantArray[0, assembly["EquationsPerPoint"]];
    Do[
      rowIndex = eqwPointRowIndex[targetGrade, mu, i, j,
        upperDimension, lowerDimension];
      gaugeRow = Flatten[Table[
        productGrade = productGrades[[targetGrade + 1,
          sourceGrade + 1]];
        productWeight = productWeights[[targetGrade + 1,
          sourceGrade + 1, monomial]];
        If[targetGrade === sourceGrade && a === i && b === j,
            basisDerivatives[[mu, sourceGrade + 1, monomial]], 0] +
          If[b === j,
            -productWeight eValues[[mu, i, a, productGrade + 1]], 0] +
          If[a === i,
            productWeight cValues[[mu, b, j, productGrade + 1]], 0],
        {a, upperDimension}, {b, lowerDimension},
        {sourceGrade, 0, gradeCount - 1},
        {monomial, supportCount}]];
      residueRow = Flatten[Table[
        If[a === i && b === j,
          epsilon oneFormValues[[letter, mu, targetGrade + 1]], 0],
        {letter, Length[assembly["OneForms"]]},
        {a, upperDimension}, {b, lowerDimension}]];
      rows[[rowIndex]] = Join[gaugeRow, residueRow];
      right[[rowIndex]] =
        bbarValues[[mu, i, j, targetGrade + 1]],
      {targetGrade, 0, gradeCount - 1}, {mu, 2},
      {i, upperDimension}, {j, lowerDimension}];
    If[! MatrixQ[rows] || Dimensions[rows] =!=
        {assembly["EquationsPerPoint"], unknownCount} ||
        Length[right] =!= assembly["EquationsPerPoint"],
      Throw[eqwFailure["ExactPointShapeMismatch", <|"Point" -> point|>]]];
    <|"Status" -> "AssembledCF300ExactQepsPointV1",
      "Point" -> point, "DeltaValues" -> deltaValues,
      "Rows" -> SparseArray[rows], "RightHandSide" -> right|>
  ]];

eqwNormalizationRows[assembly_Association, epsilon_Symbol] := Module[
  {unknownCount = assembly["UnknownCount"], rows, right},
  rows = Table[SparseArray[{normalization["Column"] -> 1},
      unknownCount], {normalization, assembly["Normalizations"]}];
  right = (normalization["Value"] /.
      assembly["Regulator"] -> epsilon) & /@
    assembly["Normalizations"];
  {rows, right}
];

EQWAssembleExactSample[assembly_Association, epsilon_Symbol,
    points_List] := Module[
  {pointResults, normalization, pointMatrix, normalizationMatrix,
   matrix, right, allEntries},
  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly] ||
      Lookup[assembly, "AssemblyFingerprint", None] =!=
        $eqwExpectedMaximalAssemblyFingerprint ||
      ! MatchQ[points, {{_Integer | _Rational,
          _Integer | _Rational} ..}] || Length[points] =!= 30 ||
      ! DuplicateFreeQ[points] || ! FreeQ[points, epsilon],
    Return[eqwFailure["InvalidExactSampleArguments"]]];
  pointResults = eqwAssemblePoint[assembly, epsilon, #1] & /@ points;
  If[! AllTrue[pointResults, AssociationQ[#1] &&
        Lookup[#1, "Status", None] ===
          "AssembledCF300ExactQepsPointV1" &],
    Return[eqwFailure["ExactPointAssemblyFailed", <|
      "PointStatuses" -> Lookup[pointResults, "Status", None]|>]]];
  normalization = eqwNormalizationRows[assembly, epsilon];
  pointMatrix = Join @@ Lookup[pointResults, "Rows"];
  normalizationMatrix = If[normalization[[1]] === {},
    SparseArray[{}, {0, assembly["UnknownCount"]}],
    SparseArray[Normal /@ normalization[[1]]]];
  matrix = Join[pointMatrix, normalizationMatrix];
  right = Join[Join @@ Lookup[pointResults, "RightHandSide"],
    normalization[[2]]];
  If[Dimensions[matrix] =!= {960, 912} || Length[right] =!= 960,
    Return[eqwFailure["ExactSampleShapeMismatch", <|
      "MatrixDimensions" -> Dimensions[matrix],
      "RightLength" -> Length[right]|>]]];
  allEntries = Join[Flatten[Normal[matrix]], right];
  If[! AllTrue[allEntries, eqwQepsQ[#1, epsilon] &],
    Return[eqwFailure["ExactSampleNotOverQeps"]]];
  <|"Status" -> "AssembledCF300ExactQepsSampleV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "PointCount" -> 30, "AcceptedPoints" -> points,
    "AcceptedPointsFingerprint" -> EQWFingerprint[points],
    "ExactRationalPointsNonsingularOverQeps" -> True,
    "Matrix" -> SparseArray[matrix], "RightHandSide" -> right,
    "MatrixDimensions" -> {960, 912},
    "RowBasis" -> "MultiquadraticGradeBasisOverQeps",
    "ColumnOrder" -> assembly["ColumnOrder"],
    "RowOrder" -> assembly["RowOrder"]|>
];

EQWAssembleExactSample[___] :=
  eqwFailure["InvalidExactSampleArguments"];

EQWConstruct[matrix_?MatrixQ, right_List, epsilon_Symbol,
    plan_Association, reconstruction_Association] := Module[
  {dimensions, rows, columns, independentRows, supportSolution,
   witness, leftResidual, rightResidual,
   leftCertificates, rightCertificate, supportIndices,
   canonicalWitness},
  dimensions = Dimensions[matrix];
  If[dimensions =!= {960, 912} || Length[right] =!= 960 ||
      ! eqwPlanArraysValidQ[plan, 960, 912] ||
      Lookup[reconstruction, "Status", None] =!=
        "ReconstructedCF300ExactQepsWitnessSupportV1" ||
      Lookup[reconstruction, "Field", None] =!= "Q(eps)" ||
      Lookup[reconstruction, "PinnedPlanFingerprint", None] =!=
        EQWFingerprint[plan] ||
      ! TrueQ[Lookup[reconstruction,
        "DegreeProfileStableAcrossTrainingPrimes", False]] ||
      ! TrueQ[Lookup[reconstruction,
        "RationalReconstructionBoundSatisfied", False]] ||
      ! TrueQ[Lookup[reconstruction,
        "PrefixReconstructionStable", False]] ||
      ! TrueQ[Lookup[reconstruction,
        "HeldOutPrimeImagesExact", False]],
    Return[eqwFailure["InvalidExactWitnessArguments"]]];
  {rows, columns} = dimensions;
  independentRows = plan["AugmentedIndependentEquationRows"];
  supportSolution = Lookup[reconstruction,
    "ReconstructedSupportFunctions", $Failed];
  If[supportSolution === $Failed ||
      ! VectorQ[supportSolution, eqwQepsQ[#1, epsilon] &] ||
      Length[supportSolution] =!= Length[independentRows],
    Return[eqwFailure["PinnedModularReconstructionInvalid"]]];
  supportSolution = eqwCanonicalQeps[#1, epsilon] & /@
    supportSolution;
  If[EQWFingerprint[supportSolution] =!=
      Lookup[reconstruction, "SupportFunctionFingerprint", None],
    Return[eqwFailure["PinnedModularReconstructionFingerprintMismatch"]]];
  witness = SparseArray[Thread[independentRows -> supportSolution], rows];
  leftResidual = Transpose[SparseArray[matrix]].witness;
  rightResidual = right.witness - 1;
  leftCertificates = eqwClearedIdentity[#1, epsilon] & /@
    Normal[leftResidual];
  rightCertificate = eqwClearedIdentity[rightResidual, epsilon];
  If[! AllTrue[leftCertificates,
        TrueQ[Lookup[#1, "NumeratorZero", False]] &&
          TrueQ[Lookup[#1, "DenominatorNonzero", False]] &] ||
      ! TrueQ[Lookup[rightCertificate, "NumeratorZero", False]] ||
      ! TrueQ[Lookup[rightCertificate, "DenominatorNonzero", False]],
    Return[eqwFailure["ExactClearedDenominatorResidualFailed", <|
      "FailedLeftCoordinateCount" -> Count[leftCertificates,
        certificate_ /; ! TrueQ[Lookup[certificate,
          "NumeratorZero", False]]],
      "RightCertificate" -> rightCertificate|>]]];
  canonicalWitness = SparseArray[Map[eqwCanonicalQeps[#1, epsilon] &,
    witness]];
  supportIndices = eqwNonzeroIndices[Normal[canonicalWitness]];
  <|"Status" -> "CertifiedCF300ExactQepsLeftObstructionV1",
    "Field" -> "Q(eps)", "MatrixDimensions" -> dimensions,
    "CoefficientRankFromPinnedPlan" -> 888,
    "AugmentedRankFromPinnedPlan" -> 889,
    "Canonicalization" ->
      "Modularly reconstructed functions on pinned augmented independent rows; all other witness coordinates zero; monic epsilon denominators",
    "PinnedPlanFingerprint" -> EQWFingerprint[plan],
    "Witness" -> canonicalWitness,
    "WitnessFingerprint" -> EQWFingerprint[canonicalWitness],
    "WitnessSupportIndices" -> supportIndices,
    "WitnessSupportCount" -> Length[supportIndices],
    "LeftResidualCoordinateCount" -> columns,
    "LeftClearedNumeratorsAllZero" -> True,
    "RightClearedNumeratorZero" -> True,
    "RightPairing" -> 1,
    "ReconstructionCertificate" -> KeyDrop[reconstruction,
      "ReconstructedSupportFunctions"],
    "LeftClearedIdentityFingerprint" ->
      EQWFingerprint[leftCertificates],
    "RightClearedIdentityCertificate" -> rightCertificate,
    "WitnessScoreIndexPolicy" ->
      "Pick[Range[Length[values]],mask]; no Position head traversal"|>
];

EQWConstruct[___] := eqwFailure["InvalidExactWitnessArguments"];

End[];
EndPackage[];
