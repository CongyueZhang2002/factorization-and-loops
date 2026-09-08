#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["TRR3SCALE FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
exchangeDirectory = DirectoryName[$InputFileName];
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
  Print["TRR3SCALE ", If[pass, "PASS ", "FAIL "], name];
  pass
];
sameVectorQ[left_List, right_List] :=
  Length[left] === Length[right] &&
    AllTrue[MapThread[Together[#1 - #2] &, {left, right}],
      TrueQ[#1 === 0] &];

oracle = CodexTripleRootRank3Oracle`TRBuildCF300Rank3Oracle[];
support = Flatten[Table[{i, j}, {i, 0, 3}, {j, 0, 3}], 1];
preparation = CodexTripleRootReconstruction`TRPrepareReconstruction[
  oracle["Record"], oracle["Frame"],
  "OneForms" -> oracle["OneForms"],
  "GaugeDenominator" -> oracle["GaugeDenominator"],
  "Support" -> support,
  "NormalizationEquations" -> oracle["NormalizationEquations"]];
expected = CodexTripleRootRank3Oracle`TRCF300Rank3ExpectedVector[
  oracle, preparation];
assert["s16_rank3_preparation",
  Lookup[preparation, "Status", None] === "PreparedReconstruction" &&
    CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation] &&
    Length[preparation["GaugeSupport"]] === 16 &&
    preparation["GaugeUnknownCount"] === 128 &&
    preparation["UnknownCount"] === 129 &&
    preparation["EquationsPerPoint"] === 16];
assert["s16_expected_vector",
  Lookup[expected, "Status", None] === "ExpectedOracleVector" &&
    Length[expected["Vector"]] === 129];

trainingPrimes = {10007, 10039, 10067};
epsilonSamples = {1/2, 2/3, 3/5};
{reconstructionSeconds, reconstruction} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRReconstructAffineBatch[
    preparation, epsilonSamples, trainingPrimes,
    "EpsilonDegree" -> 0,
    "RandomSeed" -> 88417,
    "Verbose" -> True]];
assert["s16_three_prime_exact_reconstruction",
  Lookup[reconstruction, "Status", None] === "ExactReconstruction" &&
    reconstruction["Rank"] === 129 && reconstruction["Nullity"] === 0];
assert["s16_reconstructed_vector_matches_oracle",
  sameVectorQ[reconstruction["ReconstructedVector"],
    expected["Vector"]]];
assert["s16_exact_channel_certificate",
  TrueQ[Lookup[reconstruction["ExactVerification"],
    "ResidualZero", False]]];

unseenPrime = 1000003;
{unseenSeconds, unseen} = AbsoluteTiming[
  CodexTripleRootReconstruction`TRVerifyReconstructionModPrime[
    reconstruction, unseenPrime, {4/7, 5/8},
    "RandomSeed" -> 99421, "BranchFlipMask" -> 7]];
assert["s16_held_out_prime_epsilon_and_sign",
  Lookup[unseen, "Status", None] === "UnseenPrimeVerified" &&
    TrueQ[Lookup[unseen, "ResidualZero", False]]];

allPassed = AllTrue[checks, TrueQ[Lookup[#1, "Pass", False]] &];
result = <|"Status" -> If[allPassed, "OK", "FAILED"],
  "Checks" -> checks,
  "TrainingPrimes" -> trainingPrimes,
  "UnseenPrime" -> unseenPrime,
  "EpsilonSamples" -> epsilonSamples,
  "SupportCount" -> 16,
  "MatchedRank2UnknownCount" -> 65,
  "Rank3UnknownCount" -> preparation["UnknownCount"],
  "UnknownRatio" -> N[preparation["UnknownCount"]/65],
  "EquationRowsPerPointRatio" -> 2,
  "ReconstructionSeconds" -> reconstructionSeconds,
  "UnseenVerificationSeconds" -> unseenSeconds,
  "ReconstructionSummary" -> KeyTake[reconstruction,
    {"Status", "Rank", "Nullity", "EpsilonDegree"}],
  "UnseenSummary" -> KeyDrop[unseen, {"Checks"}]|>;

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];
Print["TRR3SCALE RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks], " unknowns=129 reconstruction_seconds=",
  Round[reconstructionSeconds, 0.001]];
Exit[If[allPassed, 0, 1]];
