#!/usr/bin/env wolframscript
(* Promotion of the reconstructed provider-backed strip installation
   contract.  The fixture is pure conversion: no solver or helper runs. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{build, activeCert, verifyPotential, vectorFingerprint, rowForm, prepare,
  candidateLetters} =
  mq /@ {"multiquadraticStripBuildInstallableSolution",
    "multiquadraticStripActivePotentialCertification",
    "multiquadraticStripVerifyPotential",
    "multiquadraticStripReconstructedVectorFingerprint",
    "familyRowGaugeDLogForm", "multiquadraticStripPrepare",
    "multiquadraticStripCandidateLetters"};

Clear[ix, iy, ie];
dimensions = {1, 1};
layoutFingerprint = StringRepeat["1", 64];
providerFingerprint = StringRepeat["2", 64];
provider = "SplitBranch";
forms = {{1/ix, 0}, {0, 1/iy}};
zero11 = {{{0}}, {{0}}};
installFrame = <|"Name" -> "InstallationRationalFrame",
  "Kind" -> "TwoVariable", "CoefficientField" -> "Rational",
  "Variables" -> {ix, iy}, "Subst" -> {ix -> ix, iy -> iy},
  "Roots" -> {}|>;
installRecord = <|"Family" -> "INSTALLATION_CONTRACT", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {ix, iy}, "Regulator" -> ie,
  "Strip" -> {zero11, zero11, zero11}|>;
makePreparation[installedForms_List] := prepare[installRecord, installFrame,
  "RootIndices" -> {}, "OneForms" -> installedForms,
  "GaugeDenominator" -> 1 - ix, "Support" -> {{0, 0}},
  "CompileCore" -> False];
preparation = makePreparation[forms];
records = MapThread[
  <|"Kind" -> "RationalFactor", "Letter" -> #1, "OneForm" -> #2,
    "Potential" -> KeyDrop[verifyPotential[#1, #2, {ix, iy}, ie],
      "Cached"]|> &,
  {{ix, iy}, forms}];
allResidues = {{{1 + ie}}, {{0}}};
vector = {1 + ie, 1 + ie, 0};
vectorSeal = vectorFingerprint[vector, layoutFingerprint,
  providerFingerprint];
trainingKeys = Flatten[Table[
  {layoutFingerprint, providerFingerprint, prime, value, {value, value + 1}},
  {prime, {10037, 10039}}, {value, {1, 2}}], 1];
reconstruction = <|
  "Status" -> "ReconstructedRegulatorDependenceV1",
  "Method" -> "CanonicalAffineSectionRationalInRegulator",
  "LayoutFingerprint" -> layoutFingerprint,
  "Provider" -> provider,
  "ProviderFingerprint" -> providerFingerprint,
  "ReconstructedVectorFingerprint" -> vectorSeal,
  "Variables" -> {ix, iy}, "Regulator" -> ie,
  "Vector" -> vector,
  "GaugeChannels" -> {{{(1 + ie)/(1 - ix)}}},
  "Gauge" -> {{(1 + ie)/(1 - ix)}},
  "Residues" -> allResidues,
  "SamplePrimes" -> {10037, 10039},
  "UnseenPrimes" -> {10061, 10067},
  "TrainingImageKeys" -> trainingKeys,
  "RegulatorValues" -> {1, 2, 3}, "NormalizationColumns" -> {},
  "DegreeHistogram" -> <|{1, 0} -> 2|>|>;
active = activeCert[records, allResidues, True];

validationPrimes = {10061, 10067};
checks = MapIndexed[Function[{prime, index}, Module[
    {value = First[index], points, keys},
    points = {{2 + value, 7 + value}, {3 + value, 11 + value},
      {5 + value, 13 + value}};
    keys = ({layoutFingerprint, providerFingerprint, prime, value, #1} &) /@
      points;
    <|"Status" -> "ProviderPointwiseResidualZero", "Passed" -> True,
      "Prime" -> prime, "RegulatorValue" -> value, "Points" -> points,
      "ValidationImageKeys" -> keys,
      "LayoutFingerprint" -> layoutFingerprint,
      "ProviderFingerprint" -> providerFingerprint,
      "ReconstructedVectorFingerprint" -> vectorSeal|>]],
  validationPrimes];
probabilistic = <|"Status" -> "FreshProviderResidualZero",
  "Provider" -> provider, "LayoutFingerprint" -> layoutFingerprint,
  "ProviderFingerprint" -> providerFingerprint,
  "ReconstructedVectorFingerprint" -> vectorSeal,
  "Primes" -> validationPrimes, "Checks" -> checks,
  (* Deliberately advisory: the converter must recompute this fact. *)
  "FreshProviderValidationDisjointFromCRT" -> True|>;

check["I0 the installation fixture has an authenticated preparation ABI",
  Lookup[preparation, "Status", None] ===
    "PreparedMultiquadraticStripV1"];
solved = build[preparation, reconstruction, active, probabilistic,
  dimensions];
If[Lookup[solved, "Status", None] =!= "Solved",
  Print["INSTALLATION DIAGNOSTIC: ", InputForm[solved]]];
check["I1 bound fresh provider evidence produces the Solved ABI",
  Lookup[solved, "Status", None] === "Solved" &&
    solved["Certificate"] === "NumericalResidual" &&
    solved["SolutionContract"] === "InstallableMultiquadraticDLogV1"];
check["I2 zero-residue candidates are absent from every active payload",
  solved["ActiveIndices"] === {1} && solved["Alphabet"] === {ix} &&
    solved["OneForms"] === {{1/ix, 0}} &&
    solved["ResidueMatrices"] === {{{1 + ie}}}];
check["I3 the generic reconstructed gauge, not a sampled fibre, is installed",
  solved["Gauge"] === reconstruction["Gauge"] &&
    ! FreeQ[solved["Gauge"], ie]];
check["I4 certified one-forms are published and consumable",
  TrueQ[solved["OneFormsCertified"]] &&
    rowForm[solved, {ix, iy}, ie, dimensions] ===
      {{{Together[ie (1 + ie)/ix]}}, {{0}}}];

emptyRecords = {records[[2]]};
emptyResidues = {{{0}}};
emptyActive = activeCert[emptyRecords, emptyResidues, True];
emptyVector = {1 + ie, 0};
emptyReconstruction = Join[reconstruction, <|
  "Vector" -> emptyVector, "Residues" -> emptyResidues,
  "ReconstructedVectorFingerprint" -> vectorFingerprint[emptyVector,
    layoutFingerprint, providerFingerprint]|>];
emptyEvidence = probabilistic /. vectorSeal ->
  emptyReconstruction["ReconstructedVectorFingerprint"];
emptyPreparation = makePreparation[{forms[[2]]}];
emptySolved = build[emptyPreparation, emptyReconstruction, emptyActive,
  emptyEvidence, dimensions];
check["I5 an empty active alphabet is a valid gauge-only solution",
  emptySolved["Status"] === "Solved" && emptySolved["Alphabet"] === {} &&
    emptySolved["OneForms"] === {} &&
    emptySolved["ResidueMatrices"] === {} &&
    rowForm[emptySolved, {ix, iy}, ie, dimensions] ===
      ConstantArray[0, {2, 1, 1}]];

exactEvidence = <|"Status" -> "ExactChannelResidualZero",
  "Provider" -> provider, "LayoutFingerprint" -> layoutFingerprint,
  "ProviderFingerprint" -> providerFingerprint,
  "ReconstructedVectorFingerprint" -> vectorSeal|>;
exactSolved = build[preparation, reconstruction, active, exactEvidence,
  dimensions];
check["I6 content-bound exact evidence produces an exact certificate",
  exactSolved["Status"] === "Solved" &&
    exactSolved["Certificate"] === "ExactResidual" &&
    exactSolved["ExactDLog"] === True];

mutatedVectorEvidence = ReplacePart[probabilistic,
  {"Checks", 1, "ReconstructedVectorFingerprint"} ->
    StringRepeat["3", 64]];
check["N1 a residual record with mutated vector evidence is refused",
  build[preparation, reconstruction, active, mutatedVectorEvidence,
    dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];
mutatedLayoutEvidence = ReplacePart[probabilistic,
  {"Checks", 1, "LayoutFingerprint"} -> StringRepeat["4", 64]];
check["N2 a residual record with mutated layout evidence is refused",
  build[preparation, reconstruction, active, mutatedLayoutEvidence,
    dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];
mutatedProviderEvidence = ReplacePart[probabilistic,
  {"Checks", 1, "ProviderFingerprint"} -> StringRepeat["5", 64]];
check["N3 a residual record with mutated provider evidence is refused",
  build[preparation, reconstruction, active, mutatedProviderEvidence,
    dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

mutatedVector = ReplacePart[reconstruction, {"Vector", 1} -> 2 + ie];
check["N4 a mutated reconstructed vector invalidates its own seal",
  build[preparation, mutatedVector, active, probabilistic,
    dimensions]["Status"] ===
    "ReconstructedVectorFingerprintMismatch"];

overlapReconstruction = Join[reconstruction,
  <|"TrainingImageKeys" -> Append[trainingKeys,
    First[checks]["ValidationImageKeys"][[1]]],
    "FreshProviderValidationDisjointFromCRT" -> True|>];
check["N5 training/validation overlap is recomputed, not trusted",
  build[preparation, overlapReconstruction, active, probabilistic,
    dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

staleActive = Join[active, <|"ActiveIndices" -> {} ,
  "ActiveLetterRecords" -> {}, "ActiveOneForms" -> {},
  "ActiveResidues" -> {}|>];
check["N6 nonzero reconstructed residues cannot be omitted",
  build[preparation, reconstruction, staleActive, probabilistic,
    dimensions]["Status"] ===
    "ActiveSupportPayloadMismatch"];

mutatedGauge = Join[reconstruction,
  <|"Gauge" -> {{2 (1 + ie)/(1 - ix)}}|>];
check["N7 a gauge not unpacked from the certified vector is refused",
  build[preparation, mutatedGauge, active, probabilistic,
    dimensions]["Status"] === "ReconstructionPayloadMismatch"];
mutatedResidues = Join[reconstruction,
  <|"Residues" -> {{{2 + ie}}, {{0}}}|>];
check["N8 residues not unpacked from the certified vector are refused",
  build[preparation, mutatedResidues, active, probabilistic,
    dimensions]["Status"] === "ReconstructionPayloadMismatch"];
mutatedForms = Join[active, <|"ActiveOneForms" -> {forms[[2]]}|>];
check["N9 the active one-form order is bound to the preparation ABI",
  build[preparation, reconstruction, mutatedForms, probabilistic,
    dimensions]["Status"] === "ActiveSupportPayloadMismatch"];

(* Internally constructed dlogs use retained field channels.  Their potential
   seal must nevertheless be the same canonical (letter, one-form) PairKey
   that the installation boundary independently recomputes. *)
zero11 = {{{0}}, {{0}}};
constructed = candidateLetters[{zero11, zero11, zero11}, {}, {ix, iy}, ie,
  <|"StripSolvers" -> {}|>, "RegulatorSampleCount" -> 1,
  "RowAlphabet" -> {}, "AdditionalLetters" -> {ix},
  "AlgebraicLetters" -> {}, "DLogKernels" -> 1];
constructedRecords = Select[Lookup[constructed, "LetterRecords", {}],
  TrueQ[Lookup[#1, "Letter", None] === ix] &];
constructedResidues = ConstantArray[{{1 + ie}}, Length[constructedRecords]];
constructedActive = activeCert[constructedRecords, constructedResidues, True];
(* The preparation ABI orders the reconstructed vector as gauge coefficients
   followed by the flattened residue matrices.  Bind the constructed fixture
   to that ABI instead of supplying a different value in its residue slot. *)
constructedVector = Join[{1 + ie}, Flatten[constructedResidues]];
constructedSeal = vectorFingerprint[constructedVector, layoutFingerprint,
  providerFingerprint];
constructedReconstruction = Join[reconstruction, <|
  "Vector" -> constructedVector, "Residues" -> constructedResidues,
  "ReconstructedVectorFingerprint" -> constructedSeal|>];
constructedEvidence = probabilistic /. vectorSeal -> constructedSeal;
constructedPreparation = makePreparation[
  Lookup[constructedActive, "ActiveOneForms", {}]];
constructedSolved = build[constructedPreparation, constructedReconstruction,
  constructedActive, constructedEvidence, dimensions];
If[Lookup[constructedSolved, "Status", None] =!= "Solved",
  Print["CONSTRUCTED INSTALLATION DIAGNOSTIC: ",
    InputForm[constructedSolved]]];
check["I7 an internally constructed active dlog passes installation",
  Length[constructedRecords] === 1 &&
    Lookup[constructedSolved, "Status", None] === "Solved" &&
    constructedSolved["Alphabet"] === {ix}];

(* The installed ABI carries authenticated one-forms specifically so the row
   assembler never differentiates a hard algebraic alphabet again. *)
heldAlphabetSolution = Join[solved, <|"Alphabet" -> {HoldForm[hard[ix, iy]]}|>];
check["I8 the row assembler consumes certified one-forms directly",
  rowForm[heldAlphabetSolution, {ix, iy}, ie, dimensions] ===
    {{{Together[ie (1 + ie)/ix]}}, {{0}}}];

Print["t_multiquadratic_installation: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
