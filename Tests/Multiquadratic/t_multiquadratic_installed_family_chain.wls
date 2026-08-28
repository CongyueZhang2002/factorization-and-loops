#!/usr/bin/env wolframscript
(* Cross-stage promotion of the installable multiquadratic strip ABI.

   A planted scalar off-diagonal strip uses a rank-three frame, an
   eight-grade gauge and three algebraic dlog letters.  The reconstructed
   rational-in-epsilon residues are deliberately proportional to 1 + eps:
   installation therefore produces a valid cumulative family connection
   which is not yet epsilon factored.  The family regulator factor removes
   that dependence in the graded algebra, and the whole-family certificate
   checks the composed transformation on all eight sheets at fresh primes.

   This fixture is completely synthetic.  It contains no family catalog
   literals and neither launches helpers nor requests subkernels. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label, " -> ", InputForm[ok]]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
zeroQ[value_] := Quiet[Check[TrueQ[Numerator[Together[value]] === 0],
  False]];
zeroMatrixQ[value_] := ListQ[value] && AllTrue[Flatten[value], zeroQ];

solve = mq["solveEpsFormStripMultiquadratic"];
rowForm = mq["familyRowGaugeDLogForm"];
rowApply = mq["familyRowGaugeApply"];
decompose = mq["multiquadraticFieldDecompose"];
currentRoots = mq["transportChartCurrentRoots"];

Clear[v, w, x, y, eps];
sourceVariables = {v, w};
variables = {x, y};
sourceSquares = {1 + v, 1 + w, 1 + v + w};
frame = FeynFacet`BuildAlgebraicTransportFrame[
  sourceSquares, sourceVariables, variables];
roots = currentRoots[frame, variables];
declaredRoots = Lookup[roots, "Root", {}];

check["C0 the planted transport frame has three independent roots",
  AssociationQ[frame] && ListQ[roots] && Length[roots] === 3 &&
    Length[declaredRoots] === 3];

maskFactor[mask_Integer] := Product[
  If[BitGet[mask, index - 1] === 1, declaredRoots[[index]], 1],
  {index, Length[declaredRoots]}];
gaugeDenominator = 2 + x + y;
knownGauge = {{Together[Sum[(mask + 1) maskFactor[mask], {mask, 0, 7}]/
  gaugeDenominator]}};
letters = ((1 + #)/(1 - #) &) /@ declaredRoots;
dlogs = ({Together[D[#, x]/#], Together[D[#, y]/#]} &) /@ letters;

(* Every active residue has the same removable regulator factor.  With
   zero diagonal blocks, Bbar = dG + installed form is exactly the strip
   equation used by familyRowGaugeApply. *)
installedTarget = Table[
  Together[eps (1 + eps) Total[dlogs[[All, direction]]]],
  {direction, 2}];
zeroDiagonal = {{{0}}, {{0}}};
bbar = Table[{{Together[
    D[knownGauge[[1, 1]], variables[[direction]]] +
      installedTarget[[direction]]]}}, {direction, 2}];
stripRecord = <|"Family" -> "PlantedInstalledRank3Chain",
  "Sector" -> 2, "LowerSector" -> 1, "Variables" -> variables,
  "Regulator" -> eps, "Strip" -> {zeroDiagonal, zeroDiagonal, bbar}|>;

solved = solve[stripRecord, frame,
  "CoefficientProvider" -> "SplitBranch",
  "PlanDiscoveryBackend" -> "Wolfram",
  "RowAlphabet" -> {}, "AdditionalLetters" -> {},
  "AlgebraicLetters" -> letters,
  "GaugeDenominator" -> gaugeDenominator, "Support" -> {{0, 0}},
  "RegulatorSampleCount" -> 3, "DLogKernels" -> 1,
  "IntegrabilityScreen" -> False, "ScreenFirst" -> False,
  "GaugeScreen" -> False, "RegulatorReconstruction" -> True,
  "RegulatorReconstructionCount" -> 4,
  "RegulatorReconstructionCheck" -> "ProviderPoints",
  "ReconstructionUnseenPrimeCount" -> 2,
  "ReconstructionFreshPointwiseChecksPerPrime" -> 3,
  "PointCount" -> 2, "MaximumAttempts" -> 128,
  "RandomSeed" -> 2026082703];
If[Lookup[solved, "Status", None] =!= "Solved",
  Print["SOLVER DIAGNOSTIC: ", Short[solved, 12]]];

check["C1 the rank-three provider reconstruction is authenticated Solved",
  Lookup[solved, "Status", None] === "Solved" &&
    Lookup[solved, "SolutionContract", None] ===
      "InstallableMultiquadraticDLogV1" &&
    Lookup[solved, "RootCount", 0] === 3 &&
    Lookup[solved, "GradeCount", 0] === 8 &&
    TrueQ[Lookup[solved, "OneFormsCertified", False]] &&
    ! TrueQ[Lookup[solved, "ResiduesEpsFree", True]] &&
    Lookup[Lookup[solved, "InstallationEvidence", <||>], "Status", None] ===
      "InstallationEvidenceAccepted"];
check["C1 fresh installation evidence uses two unseen primes and six images",
  Lookup[Lookup[solved, "InstallationEvidence", <||>],
      "ValidationPrimeCount", 0] >= 2 &&
    Lookup[Lookup[solved, "InstallationEvidence", <||>],
      "ValidationImageCount", 0] >= 6];

recoveredGauge = Lookup[solved, "Gauge", $Failed];
gaugeChannels = If[MatrixQ[recoveredGauge] && Dimensions[recoveredGauge] ===
    {1, 1}, decompose[recoveredGauge[[1, 1]], roots], $Failed];
check["C1 the installed gauge occupies every one of the eight grades",
  ListQ[gaugeChannels] && Length[gaugeChannels] === 8 &&
    AllTrue[gaugeChannels, ! zeroQ[#] &]];

installedForm = If[Lookup[solved, "Status", None] === "Solved",
  rowForm[solved, variables, eps, {1, 1}], $Failed];
check["C2 certified one-forms install without redifferentiating letters",
  ListQ[installedForm] && Dimensions[installedForm] === {2, 1, 1} &&
    zeroMatrixQ[installedForm - ({{#}} & /@ installedTarget)]];
installedChannels = If[ListQ[installedForm] &&
    Dimensions[installedForm] === {2, 1, 1},
  Table[decompose[installedForm[[direction, 1, 1]], roots],
    {direction, 2}], $Failed];
check["C2 the installed mathematical row genuinely uses all three roots",
  MatchQ[installedChannels, {{__}, {__}}] &&
    AllTrue[Range[Length[declaredRoots]], Function[rootIndex,
      AnyTrue[Range[Length[First[installedChannels]]],
        Function[channelIndex,
          BitGet[channelIndex - 1, rootIndex - 1] === 1 &&
            AnyTrue[installedChannels, Function[directionChannels,
              ! zeroQ[directionChannels[[channelIndex]]]]]]]]]];

(* Embed the solved 1 x 1 strip in the lower-left block of a two-master
   family.  The row update simultaneously constructs the cumulative
   connection, transformation and inverse used by the later stages. *)
rawConnection = Table[
  {{0, 0}, {bbar[[direction, 1, 1]], 0}}, {direction, 2}];
rowResult = If[MatrixQ[recoveredGauge] && ListQ[installedForm],
  rowApply[rawConnection, IdentityMatrix[2], IdentityMatrix[2], {2},
    recoveredGauge, variables, installedForm],
  <|"Status" -> "UpstreamStripFailure"|>];
expectedInstalledConnection = Table[
  {{0, 0}, {installedTarget[[direction]], 0}}, {direction, 2}];
check["C3 installation updates the complete cumulative family connection",
  Lookup[rowResult, "Status", None] === "OK" &&
    zeroMatrixQ[rowResult["Connection"] - expectedInstalledConnection] &&
    zeroMatrixQ[rowResult["Transformation"] . rowResult["Inverse"] -
      IdentityMatrix[2]]];

factor = If[Lookup[rowResult, "Status", None] === "OK",
  FeynFacet`FactorFamilyRegulatorDependenceInFrame[
    rowResult["Connection"], variables, eps, frame,
    "TimeLimit" -> 120, "PointLadder" -> {1, 2, 4},
    "GatePoints" -> 2, "ExactCheckTimeLimit" -> 30,
    "CorroborationPrimes" -> 2, "RoundTripSpotChecks" -> 2,
    "SpotCheckTimeLimit" -> 15],
  <|"Status" -> "UpstreamRowFailure"|>];
If[! MemberQ[{"OK", "AlreadyEpsFactored"},
    Lookup[factor, "Status", None]],
  Print["FACTOR DIAGNOSTIC: ", Short[factor, 12]]];
check["C4 regulator factorization takes the genuine rank-three graded route",
  Lookup[factor, "Status", None] === "OK" &&
    Sort[Lookup[factor, "RootIndices", {}]] === {1, 2, 3} &&
    StringMatchQ[Lookup[factor, "Method", ""],
      "MultiquadraticGradedAlgebra/*"] &&
    TrueQ[Lookup[factor, "ExactEpsFactorization", False]] &&
    TrueQ[Lookup[factor, "ExactInverse", False]]];
check["C4 the factored family connection is linear in the regulator",
  AssociationQ[factor] && ListQ[Lookup[factor, "Connection", None]] &&
    AllTrue[Flatten[factor["Connection"]],
      zeroQ[#] || FreeQ[Together[#/eps], eps] &]];

factorTransformation = Lookup[factor, "Transformation", $Failed];
factorInverse = Lookup[factor, "Inverse", $Failed];
totalTransformation = If[MatrixQ[factorTransformation] &&
    Lookup[rowResult, "Status", None] === "OK",
  Map[Together, rowResult["Transformation"] . factorTransformation, {2}],
  $Failed];
totalInverse = If[MatrixQ[factorInverse] &&
    Lookup[rowResult, "Status", None] === "OK",
  Map[Together, factorInverse . rowResult["Inverse"], {2}], $Failed];
check["C5 row installation and regulator factor compose in gauge order",
  MatrixQ[totalTransformation] && MatrixQ[totalInverse] &&
    zeroMatrixQ[totalTransformation . totalInverse - IdentityMatrix[2]] &&
    zeroMatrixQ[totalInverse . totalTransformation - IdentityMatrix[2]]];

factorConnection = Lookup[factor, "Connection", $Failed];
familyRecord = If[ListQ[factorConnection] && MatrixQ[totalTransformation],
  <|"Family" -> "PlantedInstalledRank3Chain",
    "Chart" -> frame["Name"], "ChartRecord" -> frame,
    "Variables" -> variables, "Regulator" -> eps,
    "Blocks" -> {{1}, {2}}, "Ranges" -> {{1}, {2}},
    "TTotal" -> totalTransformation, "TTotalInverse" -> totalInverse,
    "EpsFormX" -> factorConnection[[1]],
    "EpsFormY" -> factorConnection[[2]],
    "Letters" -> Lookup[solved, "Alphabet", {}]|>,
  <|"Status" -> "UpstreamFactorFailure"|>];
sourceConnection = rawConnection /.
  Thread[variables -> sourceVariables];
system = <|"Av" -> sourceConnection[[1]],
  "Aw" -> sourceConnection[[2]]|>;
certificateOptions = Sequence[
  "SourceVariables" -> sourceVariables,
  "MultiquadraticTrainingPoints" -> 2,
  "MultiquadraticValidationPoints" -> 2,
  "MultiquadraticPrimes" -> 2,
  "MultiquadraticMaxPrimes" -> 5,
  "MultiquadraticFreshValidationPrimes" -> 2,
  "MultiquadraticMaxPrimeAttempts" -> 24,
  "MultiquadraticMaxPointAttempts" -> 240];
certified = If[KeyExistsQ[familyRecord, "TTotal"],
  FeynFacet`CertifyFamilyEpsilonForm[
    familyRecord, system, certificateOptions],
  <|"Status" -> "UpstreamFactorFailure"|>];
certificate = Lookup[certified, "EpsilonFormCertificate", <||>];
modular = Lookup[certificate, "Modular", <||>];

check["C6 the installed and factored family is high-confidence certified",
  Lookup[certified, "Status", None] === "CertifiedEpsilonForm" &&
    FeynFacet`CertifiedFamilyEpsilonFormQ[certified] &&
    TrueQ[Lookup[certificate, "Certified", False]] &&
    Lookup[certificate, "CertificationLevel", None] ===
      "HighConfidenceFiniteField"];
check["C6 every certificate point checks all eight rank-three sheets",
  Lookup[modular, "RootCount", 0] === 3 &&
    Lookup[modular, "GradeCount", 0] === 8 &&
    TrueQ[Lookup[modular, "AllRootSheetsChecked", False]] &&
    AllTrue[Lookup[modular, "PointsDone", {}],
      Lookup[#, "AllSheetsPerPoint", 0] === 8 &]];
check["C6 the rational lift is replayed at disjoint fresh primes",
  Length[Lookup[modular, "ValidationPrimes", {}]] >= 2 &&
    Intersection[Lookup[modular, "CRTPrimes", {}],
      Lookup[modular, "ValidationPrimes", {}]] === {} &&
    AllTrue[Lookup[modular, "FreshValidationEvidence", {}],
      TrueQ[Lookup[#, "ResidueCoefficientMatch", False]] &&
        TrueQ[Lookup[#, "TrainingReplay", False]] &&
        TrueQ[Lookup[#, "ValidationReplay", False]] &&
        AllTrue[Lookup[#, "Points", {}],
          Lookup[#, "SheetCount", 0] === 8 &] &]];

(* Change one active dlog residue while retaining the alphabet and the
   authenticated cumulative transformation.  The altered target is still
   a perfectly good dlog form, so rejection must come from the mathematical
   gauge identity rather than from a missing-letter/schema shortcut. *)
mutationForm = If[MatchQ[Lookup[solved, "OneForms", {}], {{_, _} ..}],
  First[solved["OneForms"]], $Failed];
mutatedRecord = If[AssociationQ[familyRecord] &&
    MatchQ[mutationForm, {_, _}],
  ReplacePart[familyRecord, {"EpsFormX", 2, 1} -> Together[
    familyRecord["EpsFormX", 2, 1] + eps mutationForm[[1]]]],
  <|"Status" -> "MutationFixtureUnavailable"|>];
mutated = If[KeyExistsQ[mutatedRecord, "TTotal"],
  FeynFacet`CertifyFamilyEpsilonForm[
    mutatedRecord, system, certificateOptions],
  <|"Status" -> "MutationFixtureUnavailable"|>];
mutationChecks = Lookup[mutated, "Checks", <||>];
mutationModular = Lookup[mutated, "Modular", <||>];
check["N1 an active mathematical residue mutation is rejected",
  MemberQ[{"EpsilonFormCertificationFailed", "ModularCertificateFailed"},
      Lookup[mutated, "Status", None]] &&
    ! TrueQ[Lookup[mutationChecks, "GaugeIdentity",
      Lookup[mutationModular, "GaugeIdentity", False]]]];

Print["t_multiquadratic_installed_family_chain: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
