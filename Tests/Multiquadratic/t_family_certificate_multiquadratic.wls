(* Family-level finite-field validation with three independent square-root
   generators.  Every sign-change image is sampled, but the result remains
   probabilistic. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, verdict_] := If[TrueQ[verdict], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label, " -> ", InputForm[verdict]]];

Clear[v, w, x, y, eps];
sourceVariables = {v, w};
coefficientVariables = {x, y};
presentation = FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
  {1 + v, 1 + w, 1 + v + w}, sourceVariables,
  coefficientVariables];
roots = FeynFacet`Private`coefficientPresentationSquareRootsInVariables[
  presentation, coefficientVariables];
{r1, r2, r3} = FeynFacet`Private`squareRootRecordExpression /@ roots;
letters = {(1 + r1)/(1 - r1), (1 + r2)/(1 - r2),
  (1 + r3)/(1 - r3)};
residues = {DiagonalMatrix[{1, 2}], DiagonalMatrix[{-2, 3}],
  DiagonalMatrix[{4, -1}]};
dlog[letter_] := {D[letter, x]/letter, D[letter, y]/letter};
epsilonForm = Table[
  eps Sum[residues[[a]] dlog[letters[[a]]][[direction]],
    {a, Length[letters]}], {direction, 2}];
basisTransformation = {{1, r1/(2 + x)}, {0, 1}};
inverseBasisTransformation = {{1, -r1/(2 + x)}, {0, 1}};
sourceInCoefficientVariables = Table[
  basisTransformation . epsilonForm[[direction]] .
      inverseBasisTransformation +
    D[basisTransformation, coefficientVariables[[direction]]] .
      inverseBasisTransformation,
  {direction, 2}];
sourceConnection = sourceInCoefficientVariables /.
  Thread[coefficientVariables -> sourceVariables];

candidate = <|
  "Family" -> "SyntheticThreeSquareRootFamily",
  "CoefficientPresentation" -> presentation,
  "Variables" -> coefficientVariables, "Regulator" -> eps,
  "Blocks" -> {Range[2]}, "Ranges" -> {Range[2]},
  "TTotal" -> basisTransformation,
  "TTotalInverse" -> inverseBasisTransformation,
  "EpsFormX" -> epsilonForm[[1]],
  "EpsFormY" -> epsilonForm[[2]], "Letters" -> letters|>;
system = <|"Av" -> sourceConnection[[1]], "Aw" -> sourceConnection[[2]]|>;
options = Sequence[
  "SourceVariables" -> sourceVariables,
  "MultiquadraticTrainingPoints" -> 2,
  "MultiquadraticValidationPoints" -> 2,
  "MultiquadraticPrimes" -> 2,
  "MultiquadraticMaxPrimes" -> 5,
  "MultiquadraticMaxPrimeAttempts" -> 24,
  "MultiquadraticMaxPointAttempts" -> 240];

validated = FeynFacet`ValidateFamilyDLogEpsilonForm[
  candidate, system, options];
evidence = validated["Validation", "SamplingEvidence"];
check["three-root family is probabilistically validated",
  validated["Status"] ===
      "FamilyDLogEpsilonFormValidated" &&
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[validated] &&
    ! FeynFacet`ExactlyValidatedFamilyDLogEpsilonFormQ[validated] &&
    validated["Validation", "Method"] ===
      "ProbabilisticFiniteFieldSampling"];
check["all eight sign-change images are evaluated",
  evidence["RootCount"] === 3 && evidence["GradeCount"] === 8 &&
    TrueQ[evidence["AllRootSheetsChecked"]] &&
    AllTrue[evidence["PointsDone"], #AllSheetsPerPoint === 8 &]];
check["connection transformation and both flatness conditions pass",
  And @@ (TrueQ[validated["Validation", "Conditions", #]] & /@ {
    "BasisTransformationInverse", "ConnectionTransformationEquation",
    "SourceConnectionFlatness", "TransformedConnectionFlatness",
    "EpsilonFactorized"})];
check["constant residues are reconstructed and replayed",
  TrueQ[evidence["ConstantResidues"]] &&
    TrueQ[evidence["ResiduesVerifiedAtAllPrimes"]] &&
    Length[validated["ConstantResidueMatrices"]] === Length[letters]];
check["training and validation point sets are disjoint",
  AllTrue[evidence["Trials"],
    Count[Lookup[#Points, "Partition", {}], "Training"] >= 2 &&
      Count[Lookup[#Points, "Partition", {}], "Validation"] >= 2 &]];

badTransformation = Join[candidate, <|
  "TTotal" -> basisTransformation . {{1, 1}, {0, 1}},
  "TTotalInverse" -> {{1, -1}, {0, 1}} .
    inverseBasisTransformation|>];
rejected = FeynFacet`ValidateFamilyDLogEpsilonForm[
  badTransformation, system, options];
check["a wrong connection transformation is rejected",
  rejected["Status"] === "FamilyDLogEpsilonFormValidationFailed" &&
    ! TrueQ[rejected["Validation", "Conditions",
      "ConnectionTransformationEquation"]]];

dependentRoots = {<|"Generator" -> Sqrt[1 + x],
    "QuadraticRadicand" -> 1 + x, "SourceRadicand" -> 1 + x|>,
  <|"Generator" -> Sqrt[1 + y], "QuadraticRadicand" -> 1 + y,
    "SourceRadicand" -> 1 + y|>,
  <|"Generator" -> Sqrt[(1 + x) (1 + y)],
    "QuadraticRadicand" -> (1 + x) (1 + y),
    "SourceRadicand" -> (1 + x) (1 + y)|>};
minimalObjects = <|"S" -> {{1}}, "Si" -> {{1}}, "B1" -> {{0}},
  "B2" -> {{0}}, "dSx" -> {{0}}, "dSy" -> {{0}},
  "dB1y" -> {{0}}, "dB2x" -> {{0}}, "Av" -> {{0}},
  "Aw" -> {{0}}, "dAvw" -> {{0}}, "dAwv" -> {{0}},
  "Jacobian" -> IdentityMatrix[2], "Letters" -> {},
  "LetterX" -> {}, "LetterY" -> {}|>;
dependent = FeynFacet`Private`familyCertMQPrepare[
  minimalObjects, dependentRoots, coefficientVariables, eps, 3];
check["dependent radicands are refused before sampling",
  dependent["Status"] === "DependentRootSquares"];

pivotTrial[prime_, pivots_] := <|"Status" -> "UsablePrime",
  "Prime" -> prime, "PivotColumns" -> pivots,
  "DLogRank" -> Length[pivots],
  "DLogPivotSignature" -> {Length[pivots], pivots}|>;
modalPivot = FeynFacet`Private`familyCertMQSelectModalPivotTrials[
  {pivotTrial[7, {1}], pivotTrial[11, {2}], pivotTrial[19, {2}]}, 2];
check["the pivot plan is chosen by its mathematical signature",
  modalPivot["Status"] === "ModalDLogPivotSignature" &&
    modalPivot["Signature"] === {1, {2}} &&
    Lookup[modalPivot["Trials"], "Prime", {}] === {11, 19}];

Print["t_family_certificate_multiquadratic: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
