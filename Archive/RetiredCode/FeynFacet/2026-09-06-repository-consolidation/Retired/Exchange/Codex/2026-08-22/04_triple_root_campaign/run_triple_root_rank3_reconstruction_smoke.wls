#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["TRR3SMOKE FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = DirectoryName[$InputFileName];
If[! DirectoryQ[projectRoot],
  Print["TRR3SMOKE FAIL missing_project_root=", projectRoot];
  Exit[65]];

Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAffinePilot.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootReconstructionPrototype.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootRank3CF300Oracle.wl"}]];

checks = {};
assert[name_String, condition_] := Module[{pass = TrueQ[condition]},
  AppendTo[checks, <|"Name" -> name, "Pass" -> pass|>];
  Print["TRR3SMOKE ", If[pass, "PASS ", "FAIL "], name];
  pass
];
modNumber[value_, prime_Integer] := Module[
  {r = Together[value], numerator, denominator},
  If[! MatchQ[r, _Integer | _Rational], Return[$Failed]];
  numerator = Mod[Numerator[r], prime];
  denominator = Mod[Denominator[r], prime];
  If[denominator === 0, $Failed,
    Mod[numerator PowerMod[denominator, -1, prime], prime]]
];

oracle = CodexTripleRootRank3Oracle`TRBuildCF300Rank3Oracle[];
assert["oracle_constructed",
  Lookup[oracle, "Status", None] === "ConstructedRank3Oracle"];
squareClasses =
  CodexTripleRootRank3Oracle`TRCF300Rank3SquareClassCertificate[oracle];
assert["three_independent_CF300_square_classes",
  Lookup[squareClasses, "Status", None] ===
      "IndependentSquareClasses" &&
    Lookup[squareClasses, "Rank", None] === 3 &&
    Lookup[squareClasses, "Nonsquare", {}] === ConstantArray[True, 7]];

preparation = CodexTripleRootReconstruction`TRPrepareReconstruction[
  oracle["Record"], oracle["Frame"],
  "OneForms" -> oracle["OneForms"],
  "GaugeDenominator" -> oracle["GaugeDenominator"],
  "Support" -> oracle["GaugeSupport"],
  "NormalizationEquations" -> oracle["NormalizationEquations"]];
preparedQ = Lookup[preparation, "Status", None] ===
  "PreparedReconstruction";
If[! preparedQ,
  Print["TRR3SMOKE preparation_failure=", InputForm[preparation]]];
assert["preparation_status_and_recomputed_ABI",
  preparedQ &&
    CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation]];
assert["rank_three_eight_grades",
  Lookup[preparation, "RootCount", None] === 3 &&
    Lookup[preparation, "GradeCount", None] === 8];
assert["stable_root_fingerprints_unique",
  DuplicateFreeQ[Lookup[preparation, "RootFingerprints", {}]] &&
    Length[Lookup[preparation, "RootFingerprints", {}]] === 3];
assert["rank3_unknown_and_equation_accounting",
  preparation["GaugeUnknownCount"] === 24 &&
    preparation["ResidueUnknownCount"] === 1 &&
    preparation["UnknownCount"] === 25 &&
    preparation["EquationsPerPoint"] === 16];

gaugeColumns = Flatten[Table[
  CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
    preparation, 1, 1, grade, monomial],
  {grade, 0, 7}, {monomial, preparation["GaugeSupport"]}]];
residueColumn = CodexTripleRootReconstruction`TRResidueIndex[
  preparation, 1, 1, 1];
assert["rank3_packed_columns_bijective_and_disjoint",
  gaugeColumns === Range[24] && residueColumn === 25];
assert["rank3_invalid_grade_rejected",
  CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
    preparation, 1, 1, 8, {0, 0}] === $Failed];

expected = CodexTripleRootRank3Oracle`TRCF300Rank3ExpectedVector[
  oracle, preparation];
assert["expected_vector_status",
  Lookup[expected, "Status", None] === "ExpectedOracleVector"];
assert["expected_vector_exercises_all_24_gauge_coefficients",
  AllTrue[Take[Lookup[expected, "Vector", {}], 24],
    ! TrueQ[Together[#1] === 0] &]];
assert["expected_vector_nonzero_residue",
  Last[Lookup[expected, "Vector", {0}]] === 37];

{exactSeconds, exact} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRExactChannelResidual[
    preparation, expected["Vector"]]];
assert["expected_exact_eight_channel_residual",
  Lookup[exact, "Status", None] === "ExactChannelResidualZero" &&
    TrueQ[Lookup[exact, "ResidualZero", False]]];
coverage =
  CodexTripleRootRank3Oracle`TRCF300Rank3ForcingGradeCoverage[
    oracle, preparation];
assert["forcing_all_eight_grades",
  Lookup[coverage, "Coverage", {}] === ConstantArray[True, 8] &&
    TrueQ[Lookup[coverage, "AllGradesNonzero", False]]];

prime = First[Select[Range[10000, 10200],
  PrimeQ[#1] && Mod[#1, 4] === 3 &]];
epsilonValue = 2/3;
{sampleSeconds, sample} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRAssembleReconstructionSample[
    preparation, epsilonValue, prime, "RandomSeed" -> 83001]];
sampleQ = Lookup[sample, "Status", None] ===
  "AssembledReconstructionSample";
If[! sampleQ,
  Print["TRR3SMOKE sample_failure=", InputForm[
    If[AssociationQ[sample], KeyDrop[sample, {"Matrix"}], sample]]]];
assert["rank3_sample_assembled",
  sampleQ && sample["MatrixDimensions"] === {65, 25}];
{solveSeconds, solve} = AbsoluteTiming[
  If[sampleQ,
    CodexTripleRootReconstruction`TRCanonicalAffineSolve[
      sample["Matrix"], sample["RightHandSide"], prime], <||>]];
assert["rank3_canonical_modular_solve_full_rank",
  Lookup[solve, "Status", None] === "CanonicalAffineSolution" &&
    Lookup[solve, "Rank", None] === 25 &&
    Lookup[solve, "Nullity", None] === 0];
expectedMod = modNumber[#1, prime] & /@ expected["Vector"];
assert["rank3_modular_solution_matches_oracle",
  Lookup[solve, "ParticularSolution", Missing[]] === expectedMod];

{branchSeconds, branchSolves} = AbsoluteTiming[Table[
  branchSample =
    CodexTripleRootReconstruction`TRAssembleReconstructionSample[
      preparation, epsilonValue, prime, "RandomSeed" -> 83001,
      "BranchFlipMask" -> branchMask];
  If[Lookup[branchSample, "Status", None] ===
      "AssembledReconstructionSample",
    CodexTripleRootReconstruction`TRCanonicalAffineSolve[
      branchSample["Matrix"], branchSample["RightHandSide"], prime],
    branchSample],
  {branchMask, 0, 7}]];
assert["all_eight_root_sign_masks_preserve_solution",
  AllTrue[branchSolves,
    Lookup[#1, "Status", None] === "CanonicalAffineSolution" &&
      Lookup[#1, "ParticularSolution", Missing[]] === expectedMod &]];
invalidBranch =
  CodexTripleRootReconstruction`TRAssembleReconstructionSample[
    preparation, epsilonValue, prime, "BranchFlipMask" -> 8];
assert["out_of_range_sign_mask_typed_rejection",
  Lookup[invalidBranch, "Status", None] === "InvalidBranchFlipMask"];

rootPermutations = Permutations[oracle["Frame"]["Roots"]];
catalogPreparations = Table[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"],
    Join[oracle["Frame"], <|"Roots" -> rootPermutation|>],
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> oracle["GaugeSupport"],
    "NormalizationEquations" -> oracle["NormalizationEquations"]],
  {rootPermutation, rootPermutations}];
supportPermutations = Permutations[oracle["GaugeSupport"]];
supportPreparations = Table[
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], oracle["Frame"],
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> supportPermutation,
    "NormalizationEquations" -> oracle["NormalizationEquations"]],
  {supportPermutation, supportPermutations}];
assert["all_catalog_root_permutations_have_canonical_ABI",
  Length[catalogPreparations] === 6 && AllTrue[catalogPreparations,
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, #1] &]];
assert["all_support_permutations_have_canonical_ABI",
  Length[supportPreparations] === 6 && AllTrue[supportPreparations,
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, #1] &]];

duplicateRootFrame = Join[oracle["Frame"],
  <|"Roots" -> Append[oracle["Frame"]["Roots"],
    First[oracle["Frame"]["Roots"]]]|>];
duplicateRootPreparation =
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], duplicateRootFrame,
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> oracle["GaugeSupport"],
    "NormalizationEquations" -> oracle["NormalizationEquations"]];
assert["duplicate_root_square_typed_rejection",
  Lookup[duplicateRootPreparation, "Status", None] ===
    "DuplicateRootSquares"];

tamperedStrip = ReplacePart[preparation["Record"]["Strip"],
  {3, 1, 1, 1} ->
    preparation["Record"]["Strip"][[3, 1, 1, 1]] + 1];
tamperedPreparation = Join[preparation,
  <|"Record" -> Join[preparation["Record"],
    <|"Strip" -> tamperedStrip|>]|>];
tamperedResult = <|
  "Preparation" -> tamperedPreparation,
  "ReconstructedVector" -> expected["Vector"],
  "ABIFingerprint" -> preparation["ABIFingerprint"]|>;
assert["stale_equation_ABI_is_recomputed_and_rejected",
  ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      tamperedPreparation] &&
    Lookup[CodexTripleRootReconstruction`TRVerifyReconstructionExact[
      tamperedResult], "Status", None] === "ReconstructionABIMismatch"];

allPassed = AllTrue[checks, TrueQ[Lookup[#1, "Pass", False]] &];
result = <|"Status" -> If[allPassed, "OK", "FAILED"],
  "Checks" -> checks,
  "Prime" -> prime,
  "EpsilonValue" -> epsilonValue,
  "SquareClassCertificate" -> KeyDrop[squareClasses, {"Products"}],
  "PreparationSummary" -> KeyTake[preparation,
    {"Status", "RootCount", "GradeCount", "RootSourceIndices",
      "RootFingerprints", "GaugeUnknownCount", "ResidueUnknownCount",
      "UnknownCount", "EquationsPerPoint", "ABIFingerprint"}],
  "SolveSummary" -> If[AssociationQ[solve], KeyTake[solve,
    {"Status", "MatrixDimensions", "Rank", "Nullity",
      "PivotSignature", "ResidualZero", "NullspaceResidualZero"}], <||>],
  "TimingSeconds" -> <|"ExactCertificate" -> exactSeconds,
    "SampleAssembly" -> sampleSeconds, "ModularSolve" -> solveSeconds,
    "AllEightSignMasks" -> branchSeconds|>,
  "PermutationCounts" -> <|"CatalogRoots" -> Length[rootPermutations],
    "Support" -> Length[supportPermutations]|>|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRR3SMOKE RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks], " unknowns=", preparation["UnknownCount"],
  " sample_seconds=", Round[sampleSeconds, 0.001],
  " solve_seconds=", Round[solveSeconds, 0.001]];
Exit[If[allPassed, 0, 1]];
