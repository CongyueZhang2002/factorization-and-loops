#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["TRR3TEST FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = DirectoryName[$InputFileName];
If[! DirectoryQ[projectRoot],
  Print["TRR3TEST FAIL missing_project_root=", projectRoot];
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
  Print["TRR3TEST ", If[pass, "PASS ", "FAIL "], name];
  pass
];
sameVectorQ[left_List, right_List] :=
  Length[left] === Length[right] &&
    AllTrue[MapThread[Together[#1 - #2] &, {left, right}],
      TrueQ[#1 === 0] &];

oracle = CodexTripleRootRank3Oracle`TRBuildCF300Rank3Oracle[];
preparation = CodexTripleRootReconstruction`TRPrepareReconstruction[
  oracle["Record"], oracle["Frame"],
  "OneForms" -> oracle["OneForms"],
  "GaugeDenominator" -> oracle["GaugeDenominator"],
  "Support" -> oracle["GaugeSupport"],
  "NormalizationEquations" -> oracle["NormalizationEquations"]];
expected = If[Lookup[preparation, "Status", None] ===
    "PreparedReconstruction",
  CodexTripleRootRank3Oracle`TRCF300Rank3ExpectedVector[
    oracle, preparation], <||>];

assert["prepared_rank3_identity_frame_with_valid_ABI",
  Lookup[preparation, "Status", None] === "PreparedReconstruction" &&
    preparation["RootCount"] === 3 && preparation["GradeCount"] === 8 &&
    CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation]];
assert["expected_rank3_oracle_vector",
  Lookup[expected, "Status", None] === "ExpectedOracleVector"];
squareClasses =
  CodexTripleRootRank3Oracle`TRCF300Rank3SquareClassCertificate[oracle];
assert["square_class_rank_is_exactly_three",
  Lookup[squareClasses, "Status", None] ===
      "IndependentSquareClasses" && squareClasses["Rank"] === 3];

trainingPrimes = Take[Select[Range[10000, 11000],
  PrimeQ[#1] && Mod[#1, 4] === 3 &], 3];
unseenPrime = First[Select[Range[1000000, 1003000],
  PrimeQ[#1] && Mod[#1, 4] === 3 &&
    ! MemberQ[trainingPrimes, #1] &]];
epsilonSamples = {1/2, 2/3, 3/5};

Print["TRR3TEST training_primes=", trainingPrimes,
  " unseen_prime=", unseenPrime,
  " epsilon_samples=", epsilonSamples,
  " unknowns=", preparation["UnknownCount"]];
{reconstructionSeconds, reconstruction} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRReconstructAffineBatch[
    preparation, epsilonSamples, trainingPrimes,
    "EpsilonDegree" -> 0,
    "RandomSeed" -> 88317,
    "Verbose" -> True]];

assert["three_prime_exact_reconstruction",
  Lookup[reconstruction, "Status", None] === "ExactReconstruction" &&
    Lookup[reconstruction, "Primes", {}] === trainingPrimes];
assert["stable_full_rank_normalized_solution",
  Lookup[reconstruction, "Nullity", None] === 0 &&
    Lookup[reconstruction, "Rank", None] === preparation["UnknownCount"]];
assert["reconstructed_vector_matches_oracle",
  AssociationQ[expected] && AssociationQ[reconstruction] &&
    sameVectorQ[reconstruction["ReconstructedVector"],
      expected["Vector"]]];
assert["reconstructed_nonzero_residue",
  Lookup[reconstruction, "Residues", Missing[]] === {{{37}}}];
assert["reconstructed_all_eight_grades_and_support_columns",
  AssociationQ[reconstruction] &&
    Dimensions[reconstruction["GaugeChannels"]] === {1, 1, 8} &&
    AllTrue[Take[reconstruction["ReconstructedVector"], 24],
      ! TrueQ[Together[#1] === 0] &]];
assert["exact_eight_channel_certificate",
  Lookup[Lookup[reconstruction, "ExactVerification", <||>],
      "Status", None] === "ExactChannelResidualZero" &&
    TrueQ[Lookup[Lookup[reconstruction, "ExactVerification", <||>],
      "ResidualZero", False]]];

coverage =
  CodexTripleRootRank3Oracle`TRCF300Rank3ForcingGradeCoverage[
    oracle, preparation];
assert["forcing_exercises_every_rank3_grade",
  Lookup[coverage, "Coverage", {}] === ConstantArray[True, 8]];

{unseenSeconds, unseen} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reconstruction, unseenPrime, {4/7, 5/8},
    "RandomSeed" -> 99321]];
assert["held_out_unseen_prime_and_epsilon_verification",
  Lookup[unseen, "Status", None] === "UnseenPrimeVerified" &&
    TrueQ[Lookup[unseen, "ResidualZero", False]]];

{allSignSeconds, signBranchChecks} = AbsoluteTiming[Table[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reconstruction, unseenPrime, {6/11, 7/13},
    "RandomSeed" -> 99322 + branchMask,
    "BranchFlipMask" -> branchMask],
  {branchMask, 0, 7}]];
assert["all_eight_root_sign_masks_at_unseen_prime",
  Length[signBranchChecks] === 8 && AllTrue[signBranchChecks,
    Lookup[#1, "Status", None] === "UnseenPrimeVerified" &&
      TrueQ[Lookup[#1, "ResidualZero", False]] &]];
assert["all_sign_mask_labels_preserved",
  Map[Lookup[First[Lookup[#1, "Checks", {<||>}]],
      "BranchFlipMask", Missing[]] &, signBranchChecks] === Range[0, 7]];

reorderedFrame = Join[oracle["Frame"],
  <|"Roots" -> RotateLeft[oracle["Frame"]["Roots"]]|>];
reorderedPreparation =
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], reorderedFrame,
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> Reverse[oracle["GaugeSupport"]],
    "NormalizationEquations" -> oracle["NormalizationEquations"]];
assert["root_catalog_and_support_reorder_stable_ABI",
  Lookup[reorderedPreparation, "Status", None] ===
      "PreparedReconstruction" &&
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, reorderedPreparation]];
reorderedResult = Join[reconstruction,
  <|"Preparation" -> reorderedPreparation|>];
reorderedUnseen =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reorderedResult, unseenPrime, {8/15}, "RandomSeed" -> 99323,
    "BranchFlipMask" -> 7];
assert["reordered_ABI_unseen_prime_verification",
  Lookup[reorderedUnseen, "Status", None] === "UnseenPrimeVerified"];

trainingPrimeRejected =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reconstruction, First[trainingPrimes], {9/17}];
assert["seen_prime_is_typed_rejection",
  Lookup[trainingPrimeRejected, "Status", None] ===
    "PrimeWasUsedForReconstruction"];

badVector = ReplacePart[reconstruction["ReconstructedVector"],
  1 -> reconstruction["ReconstructedVector"][[1]] + 1];
corrupted = Join[reconstruction,
  <|"ReconstructedVector" -> badVector|>];
corruptedExact =
  CodexTripleRootReconstruction`TRVerifyReconstructionExact[corrupted];
corruptedUnseen =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    corrupted, unseenPrime, {10/19}, "RandomSeed" -> 99324];
assert["gauge_corruption_breaks_exact_and_unseen_certificates",
  Lookup[corruptedExact, "Status", None] ===
      "ExactChannelResidualNonzero" &&
    Lookup[corruptedUnseen, "Status", None] ===
      "UnseenPrimeVerificationFailed" &&
    ! TrueQ[Lookup[corruptedUnseen, "ResidualZero", True]]];

badResidueVector = ReplacePart[reconstruction["ReconstructedVector"],
  preparation["GaugeUnknownCount"] + 1 ->
    reconstruction["ReconstructedVector"][[
      preparation["GaugeUnknownCount"] + 1]] + 1];
residueCorrupted = Join[reconstruction,
  <|"ReconstructedVector" -> badResidueVector|>];
residueCorruptedUnseen =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    residueCorrupted, unseenPrime, {11/23}, "RandomSeed" -> 99325];
assert["residue_corruption_caught_at_unseen_prime",
  Lookup[residueCorruptedUnseen, "Status", None] ===
      "UnseenPrimeVerificationFailed" &&
    ! TrueQ[Lookup[residueCorruptedUnseen, "ResidualZero", True]]];

abiCorrupted = Join[reconstruction,
  <|"ABIFingerprint" -> "intentionally-corrupted"|>];
abiCorruptedExact =
  CodexTripleRootReconstruction`TRVerifyReconstructionExact[
    abiCorrupted];
abiCorruptedMod =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    abiCorrupted, unseenPrime, {12/25}];
assert["result_ABI_fingerprint_corruption_rejected",
  Lookup[abiCorruptedExact, "Status", None] ===
      "ReconstructionABIMismatch" &&
    Lookup[abiCorruptedMod, "Status", None] ===
      "ReconstructionABIMismatch"];

tamperedStrip = ReplacePart[preparation["Record"]["Strip"],
  {3, 2, 1, 1} ->
    preparation["Record"]["Strip"][[3, 2, 1, 1]] + 1];
staleEquationPreparation = Join[preparation,
  <|"Record" -> Join[preparation["Record"],
    <|"Strip" -> tamperedStrip|>]|>];
staleEquationResult = Join[reconstruction,
  <|"Preparation" -> staleEquationPreparation|>];
assert["stale_equation_payload_rejected_before_verification",
  ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      staleEquationPreparation] &&
    Lookup[CodexTripleRootReconstruction`TRVerifyReconstructionExact[
      staleEquationResult], "Status", None] ===
      "ReconstructionABIMismatch" &&
    Lookup[CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
      staleEquationResult, unseenPrime, {13/27}], "Status", None] ===
      "ReconstructionABIMismatch"];

staleSupportPreparation = Join[preparation,
  <|"GaugeSupport" -> Reverse[preparation["GaugeSupport"]]|>];
assert["stale_support_payload_rejected_but_fresh_reorder_accepted",
  ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      staleSupportPreparation] &&
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, reorderedPreparation]];

matchedRank2UnknownCount =
  (Times @@ preparation["Dimensions"]) 4 *
    Length[preparation["GaugeSupport"]] +
  Length[preparation["OneForms"]] (Times @@ preparation["Dimensions"]);
scaling = <|
  "Formula" -> "U_r = m n 2^r S + L m n; E_point = 2 m n 2^r",
  "Dimensions" -> preparation["Dimensions"],
  "SupportCount" -> Length[preparation["GaugeSupport"]],
  "OneFormCount" -> Length[preparation["OneForms"]],
  "MatchedRank2UnknownCount" -> matchedRank2UnknownCount,
  "Rank3UnknownCount" -> preparation["UnknownCount"],
  "UnknownRatioRank3OverMatchedRank2" ->
    N[preparation["UnknownCount"]/matchedRank2UnknownCount],
  "EquationRowsPerPointRank2" -> 8,
  "EquationRowsPerPointRank3" -> preparation["EquationsPerPoint"],
  "BranchRowRatio" -> 2|>;
assert["rank_scaling_accounting",
  matchedRank2UnknownCount === 13 &&
    scaling["Rank3UnknownCount"] === 25 &&
    scaling["EquationRowsPerPointRank3"] === 16 &&
    scaling["BranchRowRatio"] === 2];

allPassed = AllTrue[checks, TrueQ[Lookup[#1, "Pass", False]] &];
result = <|"Status" -> If[allPassed, "OK", "FAILED"],
  "Checks" -> checks,
  "TrainingPrimes" -> trainingPrimes,
  "UnseenPrime" -> unseenPrime,
  "EpsilonSamples" -> epsilonSamples,
  "ReconstructionSeconds" -> reconstructionSeconds,
  "UnseenVerificationSeconds" -> unseenSeconds,
  "AllEightSignMasksSeconds" -> allSignSeconds,
  "Scaling" -> scaling,
  "PreparationSummary" -> KeyTake[preparation,
    {"Status", "RootCount", "GradeCount", "RootSourceIndices",
      "RootFingerprints", "GaugeUnknownCount", "ResidueUnknownCount",
      "UnknownCount", "EquationsPerPoint", "ABIFingerprint"}],
  "ReconstructionSummary" -> If[AssociationQ[reconstruction],
    KeyTake[reconstruction, {"Status", "EpsilonDegree", "Rank",
      "Nullity", "PivotColumns", "FreeColumns"}], <||>],
  "UnseenPrimeSummary" -> KeyDrop[unseen, {"Checks"}],
  "SignBranchSummaries" -> (KeyDrop[#1, {"Checks"}] & /@
    signBranchChecks),
  "GaugeCorruptionSummary" -> KeyDrop[corruptedUnseen, {"Checks"}],
  "ResidueCorruptionSummary" ->
    KeyDrop[residueCorruptedUnseen, {"Checks"}],
  "ABICorruptionSummary" -> abiCorruptedExact|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRR3TEST RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks],
  " reconstruction_seconds=", Round[reconstructionSeconds, 0.001],
  " all_sign_seconds=", Round[allSignSeconds, 0.001]];
Exit[If[allPassed, 0, 1]];
