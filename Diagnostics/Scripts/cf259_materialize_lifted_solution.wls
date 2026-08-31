#!/usr/bin/env wolframscript

(* Convert the accepted shifted-epsilon CRT lift into the package's
   installable direct-multiquadratic strip record.  This performs no symbolic
   differential-equation check; admission is tied to the fresh unseen-prime
   all-row residual produced by cf259_accept_active_modular_vector.wls. *)

$HistoryLength = 0;
args = Rest[$ScriptCommandLine];
trainingCount = If[Length[args] >= 1, ToExpression[args[[1]]], 5];
validationSeed = If[Length[args] >= 2, ToExpression[args[[2]]], 2026083481];
reconstructionMethod = If[Length[args] >= 3, args[[3]], "balanced"];
root = "/home/maxzhang/factorization-and-loops";
codexRoot = "/home/maxzhang/factorization-and-loops-codex";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
runtime = FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_cf259_shell3_multprime"}];
liftFile = FileNameJoin[{runtime, "rational_lift_" <>
  ToString[trainingCount] <> "_plus_1" <>
  If[reconstructionMethod === "guided", "_guided", ""] <> ".wl"}];
acceptanceFile = FileNameJoin[{runtime,
  "fresh_modular_acceptance_seed" <> ToString[validationSeed] <> ".wl"}];
If[! FileExistsQ[liftFile] || ! FileExistsQ[acceptanceFile],
  Print["accepted lift or fresh residual is missing"]; Exit[1]];
lift = Get[liftFile];
acceptance = Get[acceptanceFile];
If[Lookup[lift, "Status", None] =!= "CF259Shell3RationalLiftAcceptedV1" ||
    ! TrueQ[Lookup[lift, "Accepted", False]] ||
    ! TrueQ[Lookup[acceptance, "Accepted", False]] ||
    acceptance["Prime"] =!= lift["ValidationPrime"],
  Print["lift and unseen-prime acceptance do not form an accepted pair"];
  Exit[2]];

inputFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-28_codex_clean", "CF259",
  "sector_CF259_standard", "CF259_27_1_input.wl"}];
record = Get[inputFile];
census = Get[FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_rank3_modular_pole_census",
  "cf259_modular_pole_census.wl"}]];
supportData = Get[FileNameJoin[{codexRoot, "Runtime",
  "2026-08-31_rank3_modular_pole_census",
  "cf259_denominator_support.wl"}]];
variables = record["Variables"];
epsilon = record["Regulator"];
strip = record["Strip"];
rawPreparation = record["DeferredPreparation"]["Preparation"];
roots = (<|"Root" -> Sqrt[#1], "RootSquare" -> #1|> &) /@
  record["DeferredPreparation"]["RootSquares"];
frame = <|"Name" -> "CF259RawRank3Installable",
  "Kind" -> "TwoVariable", "CoefficientField" -> "Algebraic",
  "Variables" -> variables, "Subst" -> Thread[variables -> variables],
  "Roots" -> roots|>;
allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, variables];
classification = FeynFacet`Private`multiquadraticStripRootCensusWithBundle[
  strip, allRoots, variables, epsilon, Missing["NoDeferredBundle"]];
stableFrame = FeynFacet`Private`blockEquationDeferredRootFrame[
  KeyTake[#1, {"Root", "RootSquare"}] & /@ allRoots, variables, epsilon];
classification = Join[classification, <|
  "BundleRootIndices" -> Range[Length[allRoots]],
  "RequiredRootIndices" -> Lookup[stableFrame["Roots"],
    "SourceIndex", {}]|>];
stableOrder = FeynFacet`Private`multiquadraticStripRootOrder[
  frame, variables, Sort[classification["RequiredRootIndices"]], epsilon];
If[Lookup[stableOrder, "Status", None] =!= "StableRootOrder", Exit[3]];
directOptions = FeynFacet`Private`familyRowGaugeDirectAlphabetOptions[
  record["DeferredPreparation"]];
candidate = FeynFacet`Private`multiquadraticStripCandidateLetters[
  strip, stableOrder["Roots"], variables, epsilon, record,
  "AdditionalLetters" -> directOptions["AdditionalLetters"],
  "AlgebraicLetters" -> directOptions["AlgebraicLetters"],
  "DLogKernels" -> 1, "Deadline" -> Infinity];
If[Lookup[candidate, "Status", None] =!=
    "MultiquadraticCandidateLettersV1", Exit[3]];
prepared = FeynFacet`Private`multiquadraticStripPrepare[record, frame,
  "RootClassification" -> classification,
  "CoefficientProvider" -> "SplitBranch", "CompileCore" -> False,
  "LetterRecords" -> candidate["LetterRecords"],
  "GaugeDenominatorFactor" -> 1,
  "GaugeDenominator" -> census["GaugeDenominator"],
  "Support" -> supportData["Shells"][3], "Deadline" -> Infinity];
If[Lookup[prepared, "Status", None] =!= "PreparedMultiquadraticStripV1" ||
    prepared["UnknownCount"] =!= lift["UnknownCount"], Exit[3]];

t = epsilon - lift["ExpansionPoint"];
vector = Table[
  item = lift["LiftedInterpolations"][[coordinate]];
  numerator = Total[item["NumeratorCoefficients"]
    t^Range[0, Length[item["NumeratorCoefficients"]] - 1]];
  denominator = Total[item["DenominatorCoefficients"]
    t^Range[0, Length[item["DenominatorCoefficients"]] - 1]];
  numerator/denominator,
  {coordinate, lift["UnknownCount"]}];
{unpackSeconds, unpacked} = AbsoluteTiming[
  FeynFacet`Private`multiquadraticStripUnpackVector[prepared, vector]];
If[Lookup[unpacked, "Status", None] =!=
    "UnpackedMultiquadraticSolution", Exit[4]];
residues = unpacked["Residues"];
letterRecords = candidate["LetterRecords"];
activeCertification =
  FeynFacet`Private`multiquadraticStripActivePotentialCertification[
    letterRecords, residues, True];
If[! TrueQ[Lookup[activeCertification, "Certified", False]],
  Print["active one-form potentials are not installable: ",
    InputForm[KeyDrop[activeCertification,
      {"ActiveOneForms", "ActiveResidues"}]]]; Exit[5]];
alphabet = Lookup[letterRecords, "Letter", {}];
lettersEpsFree = FreeQ[alphabet, epsilon] &&
  FreeQ[prepared["OneForms"], epsilon];
residuesKinematicsFree = FreeQ[residues, Alternatives @@ variables];
If[! lettersEpsFree || ! residuesKinematicsFree, Exit[6]];

certificate = "NumericalResidual";
solution = <|"Status" -> "Solved",
  "Method" -> "DirectMultiquadraticFiniteField",
  "Gauge" -> unpacked["Gauge"],
  "GaugeChannels" -> unpacked["GaugeChannels"],
  "Alphabet" -> alphabet, "ResidueMatrices" -> residues,
  "OneForms" -> prepared["OneForms"], "OneFormsCertified" -> True,
  "LettersEpsFree" -> lettersEpsFree,
  "ResiduesKinematicsFree" -> residuesKinematicsFree,
  "ResiduesEpsFree" -> FreeQ[residues, epsilon],
  "RootIndices" -> prepared["RootIndices"],
  "RootSquares" -> prepared["RootSquares"],
  "GaugeSupport" -> prepared["GaugeSupport"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "SolutionContract" -> "InstallableMultiquadraticDLogV1",
  "Certificate" -> certificate,
  "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
  "DLogFormCertified" -> Missing["DeferredToFamilyCertificate"],
  "NumericalPfaffianResidualsZero" -> True,
  "UnseenPrime" -> lift["ValidationPrime"],
  "InstallationEvidence" -> <|
    "Status" -> "InstallationEvidenceAccepted",
    "Certificate" -> certificate,
    "ValidationMode" -> "FreshUnseenPrimeAllRowResidual",
    "RandomSeed" -> acceptance["RandomSeed"],
    "RegulatorValue" -> acceptance["RegulatorValue"],
    "Rows" -> Lookup[acceptance["ResidualTelemetry"], "rows", Missing[]],
    "Defects" -> Lookup[acceptance["ResidualTelemetry"], "defects", Missing[]],
    "LiftTrainingPrimes" -> lift["TrainingPrimes"],
    "LiftValidationPrime" -> lift["ValidationPrime"]|>,
  "Provider" -> "SplitBranch/FixedShell3Plan",
  "Primes" -> lift["TrainingPrimes"],
  "ModularPrimeCount" -> Length[lift["TrainingPrimes"]],
  "MaximumRegulatorDegree" -> 8,
  "ActivePotentialCertification" -> KeyDrop[activeCertification,
    {"ActiveOneForms", "ActiveResidues"}],
  "Family" -> "CF259", "Sector" -> 27, "LowerSector" -> 1,
  "Dimensions" -> prepared["Dimensions"],
  "PhaseSeconds" -> <|"Materialization" -> N[unpackSeconds]|>|>;
If[! TrueQ[FeynFacet`Private`familyRowGaugeStripAcceptanceRecordQ[solution]],
  Print["package strip-acceptance record rejected the solution"]; Exit[7]];
form = FeynFacet`Private`familyRowGaugeDLogForm[
  solution, variables, epsilon, prepared["Dimensions"]];
If[! ListQ[form] || Dimensions[form] =!=
    Prepend[prepared["Dimensions"], 2],
  Print["installable dlog form did not materialize"]; Exit[8]];
outputFile = FileNameJoin[{runtime, "cf259_27_1_lifted_solution.wl"}];
Put[solution, outputFile];
Print[InputForm[<|"Status" -> "CF259Block1InstallableSolutionV1",
  "GaugeDimensions" -> Dimensions[solution["Gauge"]],
  "AlphabetCount" -> Length[alphabet],
  "ActiveLetterCount" -> Lookup[activeCertification,
    "ActiveCount", Missing[]],
  "ResiduesEpsFree" -> solution["ResiduesEpsFree"],
  "MaterializationSeconds" -> N[unpackSeconds],
  "Output" -> outputFile|>]];
Exit[0];
