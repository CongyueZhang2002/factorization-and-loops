#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["TRRECONTEST FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = DirectoryName[$InputFileName];
If[! DirectoryQ[projectRoot],
  Print["TRRECONTEST FAIL missing_project_root=", projectRoot];
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
  Print["TRRECONTEST ", If[pass, "PASS ", "FAIL "], name];
  pass
];
sameVectorQ[left_List, right_List] :=
  Length[left] === Length[right] &&
    AllTrue[MapThread[Together[#1 - #2] &, {left, right}],
      TrueQ[#1 === 0] &];

oracle = CodexTripleRootRank2Oracle`TRBuildCF300Rank2Oracle[];
preparation = CodexTripleRootReconstruction`TRPrepareReconstruction[
  oracle["Record"], oracle["Frame"],
  "OneForms" -> oracle["OneForms"],
  "GaugeDenominator" -> oracle["GaugeDenominator"],
  "Support" -> oracle["GaugeSupport"],
  "NormalizationEquations" -> oracle["NormalizationEquations"]];
expected = If[Lookup[preparation, "Status", None] ===
    "PreparedReconstruction",
  CodexTripleRootRank2Oracle`TRCF300Rank2ExpectedVector[
    oracle, preparation], <||>];

assert["prepared_rank2_identity_frame",
  Lookup[preparation, "Status", None] === "PreparedReconstruction" &&
    preparation["RootCount"] === 2 && preparation["GradeCount"] === 4];
assert["expected_oracle_vector",
  Lookup[expected, "Status", None] === "ExpectedOracleVector"];

trainingPrimes = Take[Select[Range[10000, 11000],
  PrimeQ[#1] && Mod[#1, 4] === 3 &], 3];
unseenPrime = First[Select[Range[1000000, 1003000],
  PrimeQ[#1] && Mod[#1, 4] === 3 &&
    ! MemberQ[trainingPrimes, #1] &]];
epsilonSamples = {1/2, 2/3, 3/5};

Print["TRRECONTEST training_primes=", trainingPrimes,
  " unseen_prime=", unseenPrime,
  " epsilon_samples=", epsilonSamples];
{reconstructionSeconds, reconstruction} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRReconstructAffineBatch[
    preparation, epsilonSamples, trainingPrimes,
    "EpsilonDegree" -> 0,
    "RandomSeed" -> 88117,
    "Verbose" -> True]];

assert["batch_exact_reconstruction",
  Lookup[reconstruction, "Status", None] === "ExactReconstruction"];
assert["stable_full_rank_normalized_solution",
  Lookup[reconstruction, "Nullity", None] === 0 &&
    Lookup[reconstruction, "Rank", None] === preparation["UnknownCount"]];
assert["reconstructed_vector_matches_oracle",
  AssociationQ[expected] && AssociationQ[reconstruction] &&
    sameVectorQ[reconstruction["ReconstructedVector"],
      expected["Vector"]]];
assert["reconstructed_nonzero_residue",
  Lookup[reconstruction, "Residues", Missing[]] === {{{11}}}];
assert["reconstructed_all_four_gauge_grades",
  AssociationQ[reconstruction] &&
    AllTrue[Flatten[reconstruction["GaugeChannels"], 2],
      ! TrueQ[Together[#1] === 0] &]];
assert["exact_channel_certificate",
  TrueQ[Lookup[Lookup[reconstruction, "ExactVerification", <||>],
    "ResidualZero", False]]];

coverage = CodexTripleRootRank2Oracle`TRCF300Rank2ForcingGradeCoverage[
  oracle, preparation];
assert["forcing_exercises_every_grade",
  TrueQ[Lookup[coverage, "AllGradesNonzero", False]]];

unseen = CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
  reconstruction, unseenPrime, {4/7, 5/8},
  "RandomSeed" -> 99221];
assert["unseen_prime_and_epsilon_verification",
  Lookup[unseen, "Status", None] === "UnseenPrimeVerified" &&
    TrueQ[Lookup[unseen, "ResidualZero", False]]];

signBranchChecks = Table[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reconstruction, unseenPrime, {6/11, 7/13},
    "RandomSeed" -> 99222 + branchMask,
    "BranchFlipMask" -> branchMask],
  {branchMask, 0, 3}];
assert["all_four_root_sign_branch_permutations_verified",
  AllTrue[signBranchChecks,
    Lookup[#1, "Status", None] === "UnseenPrimeVerified" &&
      TrueQ[Lookup[#1, "ResidualZero", False]] &]];

reversedFrame = Join[oracle["Frame"],
  <|"Roots" -> Reverse[oracle["Frame"]["Roots"]]|>];
reversedPreparation =
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], reversedFrame,
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> Reverse[oracle["GaugeSupport"]],
    "NormalizationEquations" -> oracle["NormalizationEquations"]];
assert["root_and_support_order_stable_abi",
  Lookup[reversedPreparation, "Status", None] ===
      "PreparedReconstruction" &&
    CodexTripleRootReconstruction`TRPreparationABICompatibleQ[
      preparation, reversedPreparation]];
reversedResult = Join[reconstruction,
  <|"Preparation" -> reversedPreparation|>];
reversedUnseen =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reversedResult, unseenPrime, {8/15}, "RandomSeed" -> 99223];
assert["reordered_frame_unseen_prime_verification",
  Lookup[reversedUnseen, "Status", None] === "UnseenPrimeVerified"];

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
assert["corruption_breaks_exact_certificate",
  Lookup[corruptedExact, "Status", None] ===
      "ExactChannelResidualNonzero" &&
    ! TrueQ[Lookup[corruptedExact, "ResidualZero", True]]];
corruptedUnseen =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    corrupted, unseenPrime, {10/19}, "RandomSeed" -> 99224];
assert["corruption_caught_at_unseen_prime",
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
    residueCorrupted, unseenPrime, {11/23}, "RandomSeed" -> 99225];
assert["residue_corruption_caught_at_unseen_prime",
  Lookup[residueCorruptedUnseen, "Status", None] ===
      "UnseenPrimeVerificationFailed" &&
    ! TrueQ[Lookup[residueCorruptedUnseen, "ResidualZero", True]]];

abiCorrupted = Join[reconstruction,
  <|"ABIFingerprint" -> "intentionally-corrupted"|>];
abiCorruptedExact =
  CodexTripleRootReconstruction`TRVerifyReconstructionExact[abiCorrupted];
abiCorruptedMod =
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    abiCorrupted, unseenPrime, {12/25}];
assert["abi_fingerprint_corruption_rejected",
  Lookup[abiCorruptedExact, "Status", None] ===
      "ReconstructionABIMismatch" &&
    Lookup[abiCorruptedMod, "Status", None] ===
      "ReconstructionABIMismatch"];

allPassed = AllTrue[checks, TrueQ[Lookup[#1, "Pass", False]] &];
result = <|"Status" -> If[allPassed, "OK", "FAILED"],
  "Checks" -> checks,
  "TrainingPrimes" -> trainingPrimes,
  "UnseenPrime" -> unseenPrime,
  "EpsilonSamples" -> epsilonSamples,
  "ReconstructionSeconds" -> reconstructionSeconds,
  "PreparationSummary" -> If[AssociationQ[preparation],
    KeyTake[preparation, {"Status", "RootCount", "GradeCount",
      "RootSourceIndices", "RootFingerprints", "GaugeUnknownCount",
      "ResidueUnknownCount", "UnknownCount", "ABIFingerprint"}], <||>],
  "ReconstructionSummary" -> If[AssociationQ[reconstruction],
    KeyTake[reconstruction, {"Status", "EpsilonDegree", "Rank",
      "Nullity", "PivotColumns", "FreeColumns"}], <||>],
  "UnseenPrimeSummary" -> KeyDrop[unseen, {"Checks"}],
  "SignBranchSummaries" -> (KeyDrop[#1, {"Checks"}] & /@ signBranchChecks),
  "CorruptionSummary" -> KeyDrop[corruptedUnseen, {"Checks"}],
  "ResidueCorruptionSummary" ->
    KeyDrop[residueCorruptedUnseen, {"Checks"}],
  "ABICorruptionSummary" -> abiCorruptedExact|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRRECONTEST RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks],
  " reconstruction_seconds=", Round[reconstructionSeconds, 0.1]];
Exit[If[allPassed, 0, 1]];
