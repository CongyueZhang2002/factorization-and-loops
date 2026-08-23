#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["TRRECONSMOKE FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = DirectoryName[$InputFileName];
If[! DirectoryQ[projectRoot],
  Print["TRRECONSMOKE FAIL missing_project_root=", projectRoot];
  Exit[65]];

Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootAffinePilot.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootReconstructionPrototype.wl"}]];
Get[FileNameJoin[{exchangeDirectory,
  "TripleRootRank2CF300Oracle.wl"}]];

checks = {};
assert[name_String, condition_] := Module[{pass = TrueQ[condition]},
  AppendTo[checks, <|"Name" -> name, "Pass" -> pass|>];
  Print["TRRECONSMOKE ", If[pass, "PASS ", "FAIL "], name];
  pass
];
modNumber[value_, prime_Integer] := Module[
  {r = Together[value], numerator, denominator},
  numerator = Mod[Numerator[r], prime];
  denominator = Mod[Denominator[r], prime];
  If[denominator === 0, $Failed,
    Mod[numerator PowerMod[denominator, -1, prime], prime]]
];

(* Exhaustively exercise the packed ABI on a nonsquare synthetic shape.
   This catches 0/1-based slips, dropped factors at line boundaries, and
   collisions between matrix, root-grade, support, and residue axes. *)
syntheticPreparation = <|
  "Dimensions" -> {2, 3},
  "GradeCount" -> 8,
  "GaugeSupport" -> {{0, 0}, {0, 1}, {2, 0}},
  "GaugeUnknownCount" -> 2 * 3 * 8 * 3,
  "OneForms" -> {{1, 0}, {0, 1}}|>;
syntheticGaugeColumns = Flatten[Table[
  CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
    syntheticPreparation, i, j, grade,
    syntheticPreparation["GaugeSupport"][[monomial]]],
  {i, 2}, {j, 3}, {grade, 0, 7}, {monomial, 3}]];
syntheticResidueColumns = Flatten[Table[
  CodexTripleRootReconstruction`TRResidueIndex[
    syntheticPreparation, letter, i, j],
  {letter, 2}, {i, 2}, {j, 3}]];
assert["packed_gauge_axes_bijective",
  syntheticGaugeColumns === Range[144]];
assert["packed_residue_axes_bijective_and_disjoint",
  syntheticResidueColumns === Range[145, 156] &&
    Intersection[syntheticGaugeColumns, syntheticResidueColumns] === {}];
assert["packed_index_invalid_coordinates_rejected",
  And[
    CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
      syntheticPreparation, 0, 1, 0, {0, 0}] === $Failed,
    CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
      syntheticPreparation, 1, 1, 8, {0, 0}] === $Failed,
    CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
      syntheticPreparation, 1, 1, 0, {9, 9}] === $Failed,
    CodexTripleRootReconstruction`TRResidueIndex[
      syntheticPreparation, 3, 1, 1] === $Failed]];
assert["modular_number_accepts_integer_and_rational",
  And[
    CodexTripleRootReconstruction`Private`trModNumber[5, 10007] === 5,
    CodexTripleRootReconstruction`Private`trModNumber[2/3, 10007] ===
      Mod[2 PowerMod[3, -1, 10007], 10007],
    CodexTripleRootPilot`Private`trModNumber[-5, 10007] === 10002,
    CodexTripleRootPilot`Private`trModNumber[2/3, 10007] ===
      Mod[2 PowerMod[3, -1, 10007], 10007]]];
assert["modular_number_rejects_symbol_and_pole",
  And[
    CodexTripleRootReconstruction`Private`trModNumber[
      Symbol["Global`x"], 10007] === $Failed,
    CodexTripleRootReconstruction`Private`trModNumber[1/10007, 10007] ===
      $Failed,
    CodexTripleRootPilot`Private`trModNumber[
      Symbol["Global`x"], 10007] === $Failed,
    CodexTripleRootPilot`Private`trModNumber[1/10007, 10007] === $Failed]];
simpleAffineSolve =
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    {{1, 0}, {0, 1}, {1, 1}}, {3, 5, 8}, 10007];
assert["canonical_affine_solver_rectangular_unit",
  Lookup[simpleAffineSolve, "Status", None] ===
      "CanonicalAffineSolution" &&
    Lookup[simpleAffineSolve, "Rank", None] === 2 &&
    Lookup[simpleAffineSolve, "Nullity", None] === 0 &&
    Lookup[simpleAffineSolve, "ParticularSolution", None] === {3, 5}];
underdeterminedAffineSolve =
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    {{1, 1, 0}, {0, 1, 1}}, {3, 5}, 10007];
assert["canonical_affine_solver_nullspace_unit",
  Lookup[underdeterminedAffineSolve, "Status", None] ===
      "CanonicalAffineSolution" &&
    Lookup[underdeterminedAffineSolve, "Rank", None] === 2 &&
    Lookup[underdeterminedAffineSolve, "Nullity", None] === 1 &&
    TrueQ[Lookup[underdeterminedAffineSolve, "ResidualZero", False]] &&
    TrueQ[Lookup[underdeterminedAffineSolve,
      "NullspaceResidualZero", False]]];
inconsistentAffineSolve =
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    {{1}, {1}}, {0, 1}, 10007];
assert["canonical_affine_solver_inconsistency_unit",
  Lookup[inconsistentAffineSolve, "Status", None] ===
    "InconsistentModularSystem"];

oracle = CodexTripleRootRank2Oracle`TRBuildCF300Rank2Oracle[];
assert["oracle_constructed",
  Lookup[oracle, "Status", None] === "ConstructedRank2Oracle"];

preparation = CodexTripleRootReconstruction`TRPrepareReconstruction[
  oracle["Record"], oracle["Frame"],
  "OneForms" -> oracle["OneForms"],
  "GaugeDenominator" -> oracle["GaugeDenominator"],
  "Support" -> oracle["GaugeSupport"],
  "NormalizationEquations" -> oracle["NormalizationEquations"]];
preparedQ = Lookup[preparation, "Status", None] ===
  "PreparedReconstruction";
If[! preparedQ,
  Print["TRRECONSMOKE preparation_failure=", InputForm[preparation]]];
assert["preparation_status",
  preparedQ];
assert["rank_two_four_grades",
  Lookup[preparation, "RootCount", None] === 2 &&
    Lookup[preparation, "GradeCount", None] === 4];
assert["stable_root_fingerprints_unique",
  DuplicateFreeQ[Lookup[preparation, "RootFingerprints", {}]] &&
    Length[Lookup[preparation, "RootFingerprints", {}]] === 2];
assert["packed_first_gauge_column_is_one",
  preparedQ &&
    CodexTripleRootReconstruction`TRGaugeCoefficientIndex[
      preparation, 1, 1, 0, {0, 0}] === 1 &&
    Lookup[First[Lookup[preparation, "Normalizations", {<||>}]],
      "Column", None] === 1];

expected = If[preparedQ,
  CodexTripleRootRank2Oracle`TRCF300Rank2ExpectedVector[
    oracle, preparation], <|"Status" -> "PreparationFailed"|>];
expectedQ = Lookup[expected, "Status", None] === "ExpectedOracleVector";
assert["expected_vector_status",
  expectedQ];
assert["expected_vector_all_four_grades",
  expectedQ && AllTrue[expected["GaugeChannels"],
    ! TrueQ[Together[#1] === 0] &]];

exact = If[expectedQ,
  CodexTripleRootReconstruction`TRExactChannelResidual[
    preparation, expected["Vector"]], <||>];
assert["expected_exact_channel_residual",
  TrueQ[Lookup[exact, "ResidualZero", False]]];

coverage = If[preparedQ,
  CodexTripleRootRank2Oracle`TRCF300Rank2ForcingGradeCoverage[
    oracle, preparation], <||>];
assert["forcing_all_four_grades",
  TrueQ[Lookup[coverage, "AllGradesNonzero", False]]];

prime = First[Select[Range[10000, 10200],
  PrimeQ[#1] && Mod[#1, 4] === 3 &]];
epsilonValue = 2/3;
sample = If[preparedQ,
  CodexTripleRootReconstruction`TRAssembleReconstructionSample[
    preparation, epsilonValue, prime, "RandomSeed" -> 73001], <||>];
sampleQ = Lookup[sample, "Status", None] ===
  "AssembledReconstructionSample";
If[! sampleQ,
  Print["TRRECONSMOKE sample_failure=", InputForm[
    If[AssociationQ[sample], KeyDrop[sample, {"Matrix"}], sample]]]];
assert["sample_assembled",
  sampleQ];
solve = If[sampleQ,
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    sample["Matrix"], sample["RightHandSide"], prime], <||>];
If[Lookup[solve, "Status", None] =!= "CanonicalAffineSolution",
  Print["TRRECONSMOKE solve_failure=", InputForm[KeyDrop[solve,
    {"ParticularSolution", "NullspaceBasis"}]]]];
assert["canonical_modular_solve",
  Lookup[solve, "Status", None] === "CanonicalAffineSolution"];
assert["normalization_removes_nullity",
  Lookup[solve, "Nullity", None] === 0];
expectedMod = If[expectedQ,
  modNumber[#1, prime] & /@ expected["Vector"], {}];
assert["modular_solution_matches_oracle",
  Lookup[solve, "ParticularSolution", Missing[]] === expectedMod];

flippedSample = If[preparedQ,
  CodexTripleRootReconstruction`TRAssembleReconstructionSample[
    preparation, epsilonValue, prime, "RandomSeed" -> 73001,
    "BranchFlipMask" -> 3], <||>];
flippedSolve = If[Lookup[flippedSample, "Status", None] ===
    "AssembledReconstructionSample",
  CodexTripleRootReconstruction`TRCanonicalAffineSolve[
    flippedSample["Matrix"], flippedSample["RightHandSide"], prime],
  <||>];
assert["branch_sign_permutation_invariant",
  Lookup[flippedSolve, "Status", None] === "CanonicalAffineSolution" &&
    Lookup[flippedSolve, "ParticularSolution", Missing[]] === expectedMod];

reversedFrame = Join[oracle["Frame"],
  <|"Roots" -> Reverse[oracle["Frame"]["Roots"]]|>];
reversedPreparation = If[preparedQ,
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], reversedFrame,
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> Reverse[oracle["GaugeSupport"]],
    "NormalizationEquations" -> oracle["NormalizationEquations"]], <||>];
assert["catalog_and_support_order_invariant_abi",
  Lookup[reversedPreparation, "Status", None] ===
      "PreparedReconstruction" &&
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, reversedPreparation]];

allPassed = AllTrue[checks, TrueQ[Lookup[#1, "Pass", False]] &];
result = <|"Status" -> If[allPassed, "OK", "FAILED"],
  "Checks" -> checks,
  "Prime" -> prime,
  "EpsilonValue" -> epsilonValue,
  "PreparationSummary" -> If[AssociationQ[preparation],
    KeyTake[preparation, {"Status", "Equation", "ResolvedColumn",
      "Dimensions", "SupportContainsMonomial",
      "RootCount", "GradeCount",
      "RootSourceIndices", "RootFingerprints", "GaugeUnknownCount",
      "ResidueUnknownCount", "UnknownCount", "ABIFingerprint"}], <||>],
  "SolveSummary" -> If[AssociationQ[solve],
    KeyTake[solve, {"Status", "MatrixDimensions", "Rank", "Nullity",
      "PivotSignature", "ResidualZero", "NullspaceResidualZero"}], <||>]|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRRECONSMOKE RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks], " prime=", prime];
Exit[If[allPassed, 0, 1]];
