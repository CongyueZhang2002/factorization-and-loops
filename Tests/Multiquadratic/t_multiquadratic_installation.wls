#!/usr/bin/env wolframscript
(* Promotion of the reconstructed provider-backed strip installation
   contract.  The fixture is pure conversion: no solver or helper runs. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{build, activeCert, rowForm, prepare, layoutBuilder,
  candidateLetters} =
  mq /@ {"multiquadraticOffDiagonalBlockBuildInstallableSolution",
    "multiquadraticOffDiagonalBlockActivePotentialCertification",
    "familyRowBasisTransformationDLogForm", "multiquadraticOffDiagonalBlockPrepare",
    "multiquadraticOffDiagonalBlockAssemblyLayout",
    "multiquadraticOffDiagonalBlockCandidateLetters"};

Clear[ix, iy, ie, icx, icy];
dimensions = {1, 1};
provider = "SplitBranch";
forms = {{1/ix, 0}, {0, 1/iy}};
zero11 = {{{0}}, {{0}}};
installFrame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {}, {ix, iy}, {icx, icy}];
installRecord = <|"Family" -> "INSTALLATION_CONTRACT", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {ix, iy}, "Regulator" -> ie,
  "OffDiagonalBlockEquation" -> {zero11, zero11, zero11}|>;
makePreparation[installedForms_List] := prepare[installRecord, installFrame,
  "RootIndices" -> {}, "OneForms" -> installedForms,
  "OffDiagonalBasisTransformationDenominator" -> ix - 1, "Support" -> {{0, 0}},
  "CompileCore" -> False];
preparation = makePreparation[forms];
layout = layoutBuilder[preparation];
records = MapThread[
  <|"Kind" -> "RationalFactor", "Letter" -> #1, "OneForm" -> #2,
    "Potential" -> <|"Status" -> "PotentialVerified",
      "Verified" -> True, "Letter" -> #1, "OneForm" -> #2|>|> &,
  {{ix, iy}, forms}];
allResidues = {{{1 + ie}}, {{0}}};
vector = {1 + ie, 1 + ie, 0};
trainingKeys = Flatten[Table[
  {prime, value, {value, value + 1}},
  {prime, {10037, 10039}}, {value, {1, 2}}], 1];
reconstruction = <|
  "Status" -> "ReconstructedRegulatorDependenceV1",
  "Method" -> "CanonicalAffineSectionRationalInRegulator",
  "Provider" -> provider,
  "CoefficientData" -> layout["CoefficientData"],
  "Variables" -> {ix, iy}, "Regulator" -> ie,
  "Vector" -> vector,
  "OffDiagonalBasisTransformationBlockComponents" -> {{{(1 + ie)/(ix - 1)}}},
  "OffDiagonalBasisTransformationBlock" -> {{(1 + ie)/(ix - 1)}},
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
    keys = ({prime, value, #1} &) /@ points;
    <|"Status" -> "ProviderPointwiseResidualZero", "Passed" -> True,
      "Prime" -> prime, "RegulatorValue" -> value, "Points" -> points,
      "ValidationImageKeys" -> keys|>]],
  validationPrimes];
probabilistic = <|"Status" -> "FreshProviderResidualZero",
  "Provider" -> provider,
  "Primes" -> validationPrimes, "Checks" -> checks,
  (* Deliberately advisory: the converter must recompute this fact. *)
  "FreshProviderValidationDisjointFromCRT" -> True|>;

check["I0 the installation fixture carries its explicit coefficient data",
  Lookup[preparation, "Status", None] ===
      "PreparedMultiquadraticOffDiagonalBlockV1" &&
    reconstruction["CoefficientData"] === layout["CoefficientData"]];
solved = build[preparation, reconstruction, active, probabilistic,
  dimensions];
If[Lookup[solved, "Status", None] =!= "Solved",
  Print["INSTALLATION DIAGNOSTIC: ", InputForm[solved]]];
check["I1 fresh provider evidence produces the solved result",
  Lookup[solved, "Status", None] === "Solved" &&
    solved["Certificate"] === "NumericalResidual" &&
    solved["SolutionContract"] === "InstallableMultiquadraticDLogV1"];
check["I2 zero-residue candidates are absent from every active payload",
  solved["ActiveIndices"] === {1} && solved["Alphabet"] === {ix} &&
    solved["OneForms"] === {{1/ix, 0}} &&
    solved["ResidueMatrices"] === {{{1 + ie}}}];
check["I3 the generic reconstructed gauge, not a sampled fibre, is installed",
  solved["OffDiagonalBasisTransformationBlock"] === reconstruction["OffDiagonalBasisTransformationBlock"] &&
    ! FreeQ[solved["OffDiagonalBasisTransformationBlock"], ie]];
check["I4 certified one-forms are published and consumable",
  TrueQ[solved["OneFormsCertified"]] &&
    rowForm[solved, {ix, iy}, ie, dimensions] ===
      {{{Together[ie (1 + ie)/ix]}}, {{0}}}];

emptyRecords = {records[[2]]};
emptyResidues = {{{0}}};
emptyActive = activeCert[emptyRecords, emptyResidues, True];
emptyVector = {1 + ie, 0};
emptyPreparation = makePreparation[{forms[[2]]}];
emptyLayout = layoutBuilder[emptyPreparation];
emptyReconstruction = Join[reconstruction, <|
  "Vector" -> emptyVector, "Residues" -> emptyResidues,
  "CoefficientData" -> emptyLayout["CoefficientData"]|>];
emptyEvidence = probabilistic;
emptySolved = build[emptyPreparation, emptyReconstruction, emptyActive,
  emptyEvidence, dimensions];
check["I5 an empty active alphabet is a valid gauge-only solution",
  emptySolved["Status"] === "Solved" && emptySolved["Alphabet"] === {} &&
    emptySolved["OneForms"] === {} &&
    emptySolved["ResidueMatrices"] === {} &&
    rowForm[emptySolved, {ix, iy}, ie, dimensions] ===
      ConstantArray[0, {2, 1, 1}]];

exactEvidence = <|"Status" -> "ExactChannelResidualZero",
  "Provider" -> provider|>;
exactSolved = build[preparation, reconstruction, active, exactEvidence,
  dimensions];
check["I6 an exact residual produces an exact certificate",
  exactSolved["Status"] === "Solved" &&
    exactSolved["Certificate"] === "ExactResidual" &&
    exactSolved["ExactDLog"] === True];

overlapReconstruction = Join[reconstruction,
  <|"TrainingImageKeys" -> Append[trainingKeys,
    First[checks]["ValidationImageKeys"][[1]]],
    "FreshProviderValidationDisjointFromCRT" -> True|>];
check["N1 training and validation images must be disjoint",
  build[preparation, overlapReconstruction, active, probabilistic,
    dimensions]["Status"] ===
    "IndependentResidualEvidenceInsufficient"];

staleActive = Join[active, <|"ActiveIndices" -> {} ,
  "ActiveLetterRecords" -> {}, "ActiveOneForms" -> {},
  "ActiveResidues" -> {}|>];
check["N2 nonzero reconstructed residues cannot be omitted",
  build[preparation, reconstruction, staleActive, probabilistic,
    dimensions]["Status"] ===
    "ActiveSupportPayloadMismatch"];

mutateoffDiagonalBasisTransformationBlock = Join[reconstruction,
  <|"OffDiagonalBasisTransformationBlock" -> {{2 (1 + ie)/(1 - ix)}}|>];
check["N3 a basis-transformation block inconsistent with the vector is refused",
  build[preparation, mutateoffDiagonalBasisTransformationBlock, active, probabilistic,
    dimensions]["Status"] === "ReconstructionPayloadMismatch"];
mutatedResidues = Join[reconstruction,
  <|"Residues" -> {{{2 + ie}}, {{0}}}|>];
check["N4 residues inconsistent with the reconstructed vector are refused",
  build[preparation, mutatedResidues, active, probabilistic,
    dimensions]["Status"] === "ReconstructionPayloadMismatch"];
mutatedForms = Join[active, <|"ActiveOneForms" -> {forms[[2]]}|>];
check["N5 the active one-form order follows the preparation data",
  build[preparation, reconstruction, mutatedForms, probabilistic,
    dimensions]["Status"] === "ActiveSupportPayloadMismatch"];

(* Internally constructed dlogs use retained field channels.  Their potential
   seal must nevertheless be the same canonical (letter, one-form) PairKey
   that the installation boundary independently recomputes. *)
zero11 = {{{0}}, {{0}}};
constructed = candidateLetters[{zero11, zero11, zero11}, {}, {ix, iy}, ie,
  <|"OffDiagonalBlockSolutions" -> {}|>, "RegulatorSampleCount" -> 1,
  "RowAlphabet" -> {}, "AdditionalLetters" -> {ix},
  "AlgebraicLetters" -> {}, "DLogKernels" -> 1];
constructedRecords = Select[Lookup[constructed, "LetterRecords", {}],
  TrueQ[Lookup[#1, "Letter", None] === ix] &];
constructedResidues = ConstantArray[{{1 + ie}}, Length[constructedRecords]];
constructedActive = activeCert[constructedRecords, constructedResidues, True];
(* The preparation orders the reconstructed vector as basis-transformation
   coefficients followed by the flattened residue matrices. *)
constructedVector = Join[{1 + ie}, Flatten[constructedResidues]];
constructedPreparation = makePreparation[
  Lookup[constructedActive, "ActiveOneForms", {}]];
constructedLayout = layoutBuilder[constructedPreparation];
constructedReconstruction = Join[reconstruction, <|
  "Vector" -> constructedVector, "Residues" -> constructedResidues,
  "CoefficientData" -> constructedLayout["CoefficientData"]|>];
constructedEvidence = probabilistic;
constructedSolved = build[constructedPreparation, constructedReconstruction,
  constructedActive, constructedEvidence, dimensions];
If[Lookup[constructedSolved, "Status", None] =!= "Solved",
  Print["CONSTRUCTED INSTALLATION DIAGNOSTIC: ",
    InputForm[constructedSolved]]];
check["I7 an internally constructed active dlog passes installation",
  Length[constructedRecords] === 1 &&
    Lookup[constructedSolved, "Status", None] === "Solved" &&
    constructedSolved["Alphabet"] === {ix}];

(* The installed result carries verified one-forms so the row
   assembler never differentiates a hard algebraic alphabet again. *)
heldAlphabetSolution = Join[solved, <|"Alphabet" -> {HoldForm[hard[ix, iy]]}|>];
check["I8 the row assembler consumes certified one-forms directly",
  rowForm[heldAlphabetSolution, {ix, iy}, ie, dimensions] ===
    {{{Together[ie (1 + ie)/ix]}}, {{0}}}];

Print["t_multiquadratic_installation: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
