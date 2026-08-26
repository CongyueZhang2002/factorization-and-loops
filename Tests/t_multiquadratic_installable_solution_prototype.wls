#!/usr/bin/env wolframscript
(* Test-only installation seam for a reconstructed multiquadratic strip.
   No production dispatch is changed by this suite. *)

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Prototypes",
  "MultiquadraticInstallableSolution.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

build = mq["multiquadraticStripBuildInstallableSolution"];
activeCert = mq["multiquadraticStripActivePotentialCertification"];
verifyPotential = mq["multiquadraticStripVerifyPotential"];
rowForm = mq["familyRowGaugeDLogForm"];

Clear[ix, iy, ie];
dimensions = {1, 1};
forms = {{1/ix, 0}, {0, 1/iy}};
records = MapThread[
  <|"Kind" -> "RationalFactor", "Letter" -> #1, "OneForm" -> #2,
    "Potential" -> KeyDrop[verifyPotential[#1, #2, {ix, iy}, ie],
      "Cached"]|> &,
  {{ix, iy}, forms}];
allResidues = {{{1 + ie}}, {{0}}};
reconstruction = <|
  "Status" -> "ReconstructedRegulatorDependenceV1",
  "Method" -> "CanonicalAffineSectionRationalInRegulator",
  "Variables" -> {ix, iy}, "Regulator" -> ie,
  "Gauge" -> {{(1 + ie)/(1 - ix)}},
  "Residues" -> allResidues,
  "SamplePrimes" -> {10007, 10039}, "UnseenPrime" -> 10067,
  "RegulatorValues" -> {1, 2, 3}, "NormalizationColumns" -> {},
  "DegreeHistogram" -> <|{1, 0} -> 2|>|>;
active = activeCert[records, allResidues, True];

checks = Flatten[Table[
  <|"Prime" -> prime, "RegulatorValue" -> k,
    "Point" -> {2 + k, 7 + k}, "ResidualZero" -> True,
    "ExcludedFromTraining" -> True|>,
  {prime, {10007, 10039}}, {k, 1, 3}], 1];
probabilistic = <|"Status" -> "FreshProviderResidualZero",
  "Provider" -> "SplitBranch",
  "ProviderFingerprint" -> StringRepeat["a", 64],
  "Primes" -> {10007, 10039}, "Checks" -> checks|>;

solved = build[reconstruction, active, probabilistic, dimensions];
check["I1 fresh provider evidence produces the existing Solved ABI",
  Lookup[solved, "Status", None] === "Solved" &&
    solved["Certificate"] === "NumericalResidual" &&
    solved["SolutionContract"] === "InstallableMultiquadraticDLogV1"];
check["I2 only the nonzero active residue/letter is installed",
  solved["ActiveIndices"] === {1} && solved["Alphabet"] === {ix} &&
    solved["ResidueMatrices"] === {{{1 + ie}}}];
check["I3 the generic reconstructed gauge, not a sampled fibre, is installed",
  solved["Gauge"] === reconstruction["Gauge"] &&
    ! FreeQ[solved["Gauge"], ie]];
check["I4 regulator-dependent residues are allowed for downstream family factorization",
  solved["ResiduesEpsFree"] === False &&
    solved["ResiduesKinematicsFree"] === True];
expectedForm = {{{Together[ie (1 + ie)/ix]}}, {{0}}};
check["I5 the existing row-gauge consumer materializes the compact dlog form",
  rowForm[solved, {ix, iy}, ie, dimensions] === expectedForm];

emptyRecords = {records[[2]]};
emptyResidues = {{{0}}};
emptyActive = activeCert[emptyRecords, emptyResidues, True];
emptyReconstruction = Join[reconstruction,
  <|"Residues" -> emptyResidues|>];
emptySolved = build[emptyReconstruction, emptyActive, probabilistic,
  dimensions];
check["I6 an empty active alphabet is a valid gauge-only solution",
  emptySolved["Status"] === "Solved" && emptySolved["Alphabet"] === {} &&
    rowForm[emptySolved, {ix, iy}, ie, dimensions] ===
      ConstantArray[0, {2, 1, 1}]];

exactSolved = build[reconstruction, active,
  <|"Status" -> "ExactChannelResidualZero"|>, dimensions];
check["I7 exact evidence produces an exact solution certificate",
  exactSolved["Certificate"] === "ExactResidual" &&
    exactSolved["ExactDLog"] === True];

unverifiedRecords = ReplacePart[records,
  1 -> Join[records[[1]], <|"Potential" -> <|"Status" ->
    "PotentialRefused", "Verified" -> False|>|>]];
unverifiedActive = activeCert[unverifiedRecords, allResidues, True];
check["R1 an active unverified letter is refused",
  build[reconstruction, unverifiedActive, probabilistic, dimensions][
    "Status"] === "ActivePotentialCertificationUnavailable"];

staleActive = Join[active,
  <|"ActiveResidues" -> {{{2 + ie}}}|>];
check["R2 stale active residues cannot detach from reconstruction",
  build[reconstruction, staleActive, probabilistic, dimensions]["Status"] ===
    "ActiveSupportPayloadMismatch"];

epsilonRecord = <|"Kind" -> "Supplied", "Letter" -> ie ix,
  "OneForm" -> {1/ix, 0},
  "Potential" -> KeyDrop[verifyPotential[ie ix, {1/ix, 0},
    {ix, iy}, ie], "Cached"]|>;
epsilonActive = activeCert[{epsilonRecord}, {{{1}}}, True];
epsilonReconstruction = Join[reconstruction, <|"Residues" -> {{{1}}}|>];
check["R3 a regulator-dependent installed letter is refused",
  build[epsilonReconstruction, epsilonActive, probabilistic, dimensions][
    "Status"] === "ActiveDLogPayloadUncertified"];

kinematicReconstruction = Join[reconstruction,
  <|"Residues" -> {{{ix}}, {{0}}}|>];
kinematicActive = activeCert[records, kinematicReconstruction["Residues"],
  True];
check["R4 kinematic residues are refused",
  build[kinematicReconstruction, kinematicActive, probabilistic,
    dimensions]["Status"] === "ReconstructedSolutionShapeInvalid"];

fewPrimes = Join[probabilistic,
  <|"Primes" -> {10007},
    "Checks" -> Select[checks, #1["Prime"] === 10007 &]|>];
check["R5 one unseen prime is insufficient",
  build[reconstruction, active, fewPrimes, dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

fewChecks = Join[probabilistic,
  <|"Checks" -> Select[checks, #1["RegulatorValue"] <= 2 &]|>];
check["R6 fewer than three checks per prime is insufficient",
  build[reconstruction, active, fewChecks, dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

trainingOverlap = Join[probabilistic,
  <|"Checks" -> ReplacePart[checks,
    1 -> Join[checks[[1]], <|"ExcludedFromTraining" -> False|>]]|>];
check["R7 training-overlap evidence is refused",
  build[reconstruction, active, trainingOverlap, dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

duplicateChecks = Join[probabilistic,
  <|"Checks" -> Append[checks, First[checks]]|>];
check["R8 duplicate validation images do not increase confidence",
  build[reconstruction, active, duplicateChecks, dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

missingProvider = KeyDrop[probabilistic, "ProviderFingerprint"];
check["R9 provider evidence without a provider fingerprint is refused",
  build[reconstruction, active, missingProvider, dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

wrongGauge = Join[reconstruction, <|"Gauge" -> {{1, 0}}|>];
check["R10 a wrong gauge shape is refused",
  build[wrongGauge, active, probabilistic, dimensions]["Status"] ===
    "ReconstructedSolutionShapeInvalid"];

Print["t_multiquadratic_installable_solution_prototype: ", pass,
  " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];

