#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["CF300R2CPSMOKE FAIL usage=<project-root> <output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
scriptDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[scriptDirectory];
If[! DirectoryQ[projectRoot] || FileExistsQ[outputFile],
  Print["CF300R2CPSMOKE FAIL invalid root or stale output"];
  Exit[65]];

dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "FeynFacetPublic" -> FileNameJoin[{projectRoot, "FeynFacet",
    "FeynFacet.m"}],
  "FiniteFieldStripSolve" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldStripSolve.wl"}],
  "FiniteFieldEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FiniteFieldEpsForm.wl"}],
  "FamilyEpsForm" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "FamilyEpsForm.wl"}],
  "TransportCharts" -> FileNameJoin[{projectRoot, "FeynFacet",
    "Private", "TransportCharts.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{
    exchangeDirectory, "TripleRootReconstructionPrototype.wl"}],
  "TripleRootRank2CF300Oracle" -> FileNameJoin[{exchangeDirectory,
    "TripleRootRank2CF300Oracle.wl"}]|>;
If[! AllTrue[Values[dependencyFiles], FileExistsQ],
  Print["CF300R2CPSMOKE FAIL missing dependency"];
  Exit[66]];

fingerprint[value_] := Hash[ToString[InputForm[value]],
  "SHA256", "HexString"];
writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  temporary = outputFile <> ".tmp." <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
      OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];

checks = {};
assert[name_String, condition_] := Module[{pass = TrueQ[condition]},
  AppendTo[checks, <|"Name" -> name, "Pass" -> pass|>];
  Print["CF300R2CPSMOKE ", If[pass, "PASS ", "FAIL "], name];
  pass
];

dependencyHashesBefore = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashBefore = FileHash[$InputFileName, "SHA256", "HexString"];
messageCount = Length[$MessageList];
Get[dependencyFiles["LoadFACET"]];
Get[dependencyFiles["TripleRootAlgebra"]];
Get[dependencyFiles["TripleRootStripAdapter"]];
Get[dependencyFiles["TripleRootAffinePilot"]];
Get[dependencyFiles["TripleRootReconstructionPrototype"]];
Get[dependencyFiles["TripleRootRank2CF300Oracle"]];

oracle = CodexTripleRootRank2Oracle`TRBuildCF300Rank2Oracle[];
preparation = If[Lookup[oracle, "Status", None] ===
    "ConstructedRank2Oracle",
  CodexTripleRootReconstruction`TRPrepareReconstruction[
    oracle["Record"], oracle["Frame"],
    "OneForms" -> oracle["OneForms"],
    "GaugeDenominator" -> oracle["GaugeDenominator"],
    "Support" -> oracle["GaugeSupport"],
    "NormalizationEquations" -> {}], <||>];
preparedQ = Lookup[preparation, "Status", None] ===
    "PreparedReconstruction" &&
  CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation];
assert["unnormalized_rank2_preparation_valid",
  preparedQ && preparation["RootCount"] === 2 &&
    preparation["GradeCount"] === 4 &&
    preparation["Normalizations"] === {}];

pilotPrime = 10007;
reusePrime = First[Select[Range[pilotPrime + 1, pilotPrime + 1000],
  PrimeQ[#1] && Mod[#1, 4] === 3 &]];
epsilonValues = (#1/(#1 + 7) &) /@ Range[5];
pilot = If[preparedQ,
  CodexTripleRootReconstruction`TRInterpolateRationalAffinePrime[
    preparation, epsilonValues, pilotPrime,
    "ConstructionCount" -> 1,
    "MaximumTotalDegree" -> 0,
    "DenseByteCap" -> 67108864,
    "Backend" -> "Wolfram",
    "BackendThreads" -> 1,
    "EliminationPlanMode" -> "Discover",
    "EliminationPlan" -> None,
    "ExpectedDegreeProfile" -> Automatic,
    "RandomSeed" -> 880001,
    "Verbose" -> False], <||>];
plan = Lookup[pilot, "EliminationPlan", <||>];
degreeProfile = Lookup[pilot, "DegreeProfile", $Failed];
pilotQ = Lookup[pilot, "Status", None] ===
    "RationalAffinePrimeInterpolated" &&
  AssociationQ[plan] &&
  CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
    preparation, plan];
assert["single_discover_pilot_constructs_valid_plan",
  pilotQ && TrueQ[Lookup[pilot, "DensePilotPerformed", False]] &&
    plan["PilotPrime"] === pilotPrime];
assert["pilot_exercises_nonzero_nullity_normalization",
  pilotQ && plan["Nullity"] >= 1 &&
    Length[plan["NormalizationColumns"]] === plan["Nullity"]];
assert["pilot_accepted_points_inside_split_domain",
  pilotQ && AllTrue[Flatten[plan["PilotAcceptedPoints"]],
    IntegerQ[#1] && 2 <= #1 <= pilotPrime - 2 &]];

(* Accidental payload mutation must invalidate the stored fingerprint. *)
staleFingerprintPlan = If[pilotQ,
  ReplacePart[plan, "PilotRandomSeed" -> plan["PilotRandomSeed"] + 1],
  <||>];
assert["altered_plan_payload_rejected",
  pilotQ &&
    ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
      preparation, staleFingerprintPlan]];

(* Even a self-consistently re-fingerprinted plan is rejected when its
   root-order ABI or accepted split-point domain is altered. *)
rootOrderPlan = If[pilotQ,
  ReplacePart[plan, "RootOrderingFingerprint" ->
    "intentionally-altered-root-order"], <||>];
If[AssociationQ[rootOrderPlan] && rootOrderPlan =!= <||>,
  rootOrderPlan = ReplacePart[rootOrderPlan, "PlanFingerprint" ->
    CodexTripleRootReconstruction`Private`trCrossPrimeEliminationPlanFingerprint[
      rootOrderPlan]]];
assert["altered_root_order_rejected_after_refingerprint",
  pilotQ &&
    ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
      preparation, rootOrderPlan]];

badPointPlan = If[pilotQ,
  ReplacePart[plan, {"PilotAcceptedPoints", 1, 1} -> 0], <||>];
If[AssociationQ[badPointPlan] && badPointPlan =!= <||>,
  badPointPlan = ReplacePart[badPointPlan, "PlanFingerprint" ->
    CodexTripleRootReconstruction`Private`trCrossPrimeEliminationPlanFingerprint[
      badPointPlan]]];
assert["out_of_range_pilot_point_rejected_after_refingerprint",
  pilotQ &&
    ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
      preparation, badPointPlan]];

rootOrderPreparation = If[preparedQ,
  ReplacePart[preparation, "RootOrderingFingerprint" ->
    "intentionally-altered-root-order"], <||>];
assert["altered_preparation_root_order_breaks_abi",
  preparedQ &&
    ! CodexTripleRootReconstruction`TRPreparationABIValidQ[
      rootOrderPreparation] &&
    ! CodexTripleRootReconstruction`TRCrossPrimeEliminationPlanValidQ[
      rootOrderPreparation, plan]];

(* Require mode is evaluated while both full canonical-RREF discovery
   entry points are replaced by traps.  A regression cannot hide behind
   a slow dense calculation: it increments a counter and returns a typed
   failure immediately. *)
canonicalDenseCalls = 0;
planDiscoveryCalls = 0;
correctReuse = <||>;
wrongDegreeReuse = <||>;
wrongDegreeProfile = If[ListQ[degreeProfile] && degreeProfile =!= {},
  ReplacePart[degreeProfile, 1 ->
    If[degreeProfile[[1]] === {0, 0}, {1, 0}, {0, 0}]], $Failed];
If[pilotQ,
  Block[{CodexTripleRootReconstruction`TRCanonicalAffineSolve,
      FeynFacet`Private`finiteFieldStripDiscoverPlan},
    CodexTripleRootReconstruction`TRCanonicalAffineSolve[___] :=
      (canonicalDenseCalls++;
       <|"Status" -> "DenseCanonicalRREFTrapInvoked"|>);
    FeynFacet`Private`finiteFieldStripDiscoverPlan[___] :=
      (planDiscoveryCalls++;
       <|"Status" -> "DensePlanDiscoveryTrapInvoked"|>);
    correctReuse =
      CodexTripleRootReconstruction`TRInterpolateRationalAffinePrime[
        preparation, epsilonValues, reusePrime,
        "PointCount" -> plan["PointCount"],
        "ConstructionCount" -> 1,
        "MaximumTotalDegree" -> 0,
        "DenseByteCap" -> 1,
        "Backend" -> "Wolfram",
        "BackendThreads" -> 1,
        "EliminationPlanMode" -> "Require",
        "EliminationPlan" -> plan,
        "ExpectedDegreeProfile" -> degreeProfile,
        "RandomSeed" -> 880002,
        "Verbose" -> False];
    wrongDegreeReuse =
      CodexTripleRootReconstruction`TRInterpolateRationalAffinePrime[
        preparation, epsilonValues, reusePrime,
        "PointCount" -> plan["PointCount"],
        "ConstructionCount" -> 1,
        "MaximumTotalDegree" -> 0,
        "DenseByteCap" -> 1,
        "Backend" -> "Wolfram",
        "BackendThreads" -> 1,
        "EliminationPlanMode" -> "Require",
        "EliminationPlan" -> plan,
        "ExpectedDegreeProfile" -> wrongDegreeProfile,
        "RandomSeed" -> 880002,
        "Verbose" -> False]]];
assert["require_mode_never_enters_canonical_rref",
  pilotQ && canonicalDenseCalls === 0];
assert["require_mode_never_enters_plan_discovery",
  pilotQ && planDiscoveryCalls === 0];
assert["require_mode_succeeds_with_one_byte_dense_cap",
  Lookup[correctReuse, "Status", None] ===
      "RationalAffinePrimeInterpolated" &&
    ! TrueQ[Lookup[correctReuse, "DensePilotPerformed", True]] &&
    Lookup[correctReuse, "EliminationPlan", $Failed] === plan &&
    Lookup[correctReuse, "DegreeProfile", $Failed] === degreeProfile];
assert["altered_degree_profile_is_typed_rejection",
  wrongDegreeProfile =!= degreeProfile &&
    Lookup[wrongDegreeReuse, "Status", None] ===
      "RejectPrimeDegreeProfileChanged" &&
    Lookup[wrongDegreeReuse, "DegreeMismatchCoordinates", {}] =!= {}];

(* Exercise the fixed constrained core directly.  This independently
   checks A.p=b and A.N=0 on all rows and the canonical {0,I}
   normalization block, including the nonzero-nullity path. *)
directSample = If[pilotQ,
  CodexTripleRootReconstruction`TRAssembleReconstructionSample[
    preparation, First[epsilonValues], reusePrime,
    "PointCount" -> plan["PointCount"],
    "RandomSeed" -> 880003], <||>];
directSolve = If[Lookup[directSample, "Status", None] ===
    "AssembledReconstructionSample",
  CodexTripleRootReconstruction`Private`trSolveReconstructionWithPlan[
      preparation,
      directSample["Matrix"], directSample["RightHandSide"], plan,
      reusePrime, "Wolfram", 1, True], <||>];
assert["fixed_core_all_row_residuals_zero",
  Lookup[directSolve, "Status", None] ===
      "CanonicalAffineSolution" &&
    TrueQ[Lookup[directSolve, "ResidualZero", False]] &&
    TrueQ[Lookup[directSolve, "NullspaceResidualZero", False]]];
assert["fixed_core_canonical_zero_identity_normalization",
  Lookup[directSolve, "Status", None] ===
      "CanonicalAffineSolution" &&
    TrueQ[Lookup[directSolve, "NormalizationCheck", False]] &&
    directSolve["ParticularSolution"][[
      plan["NormalizationColumns"]]] ===
        ConstantArray[0, plan["Nullity"]] &&
    directSolve["NullspaceBasis"][[All,
      plan["NormalizationColumns"]]] === IdentityMatrix[plan["Nullity"]]];

nonCoreRows = If[pilotQ && AssociationQ[directSample],
  Complement[Range[Length[directSample["RightHandSide"]]],
    plan["IndependentEquationRows"]], {}];
corruptRow = If[nonCoreRows === {}, None, First[nonCoreRows]];
corruptRight = If[IntegerQ[corruptRow],
  ReplacePart[directSample["RightHandSide"], corruptRow ->
    Mod[directSample["RightHandSide"][[corruptRow]] + 1, reusePrime]],
  {}];
corruptSolve = If[IntegerQ[corruptRow],
  CodexTripleRootReconstruction`Private`trSolveReconstructionWithPlan[
      preparation,
      directSample["Matrix"], corruptRight, plan, reusePrime,
      "Wolfram", 1, True], <||>];
assert["noncore_row_corruption_caught_by_full_residual",
  IntegerQ[corruptRow] &&
    Lookup[corruptSolve, "Status", None] ===
      "ConstrainedResidualNonzero" &&
    ! TrueQ[Lookup[corruptSolve, "ResidualZero", True]] &&
    TrueQ[Lookup[corruptSolve, "NormalizationCheck", False]]];

(* The physical driver binds reuse to the immutable SHA256 of its
   Discover artifact.  Exercise the same file-hash invariant with two
   serialized source artifacts, without launching another kernel. *)
sourceToken = StringReplace[CreateUUID[], "-" -> ""];
sourceFile = FileNameJoin[{$TemporaryDirectory,
  ".cf300-r2-plan-source-" <> sourceToken <> ".wl"}];
sourceHashBefore = $Failed;
alteredSourceHash = $Failed;
If[pilotQ && ! FileExistsQ[sourceFile],
  Put[pilot, sourceFile];
  sourceHashBefore = FileHash[sourceFile, "SHA256", "HexString"]];
assert["discover_source_sha256_is_stable",
  StringQ[sourceHashBefore] &&
    FileHash[sourceFile, "SHA256", "HexString"] === sourceHashBefore];
If[StringQ[sourceHashBefore],
  Put[Join[pilot, <|"DegreeProfileFingerprint" ->
      "intentionally-altered-source"|>], sourceFile];
  alteredSourceHash = FileHash[sourceFile, "SHA256", "HexString"]];
assert["altered_plan_source_sha256_is_rejected",
  StringQ[sourceHashBefore] && StringQ[alteredSourceHash] &&
    alteredSourceHash =!= sourceHashBefore &&
    FileHash[sourceFile, "SHA256", "HexString"] =!=
      sourceHashBefore];
If[FileExistsQ[sourceFile], DeleteFile[sourceFile]];

dependencyHashesAtCompletion = Map[
  FileHash[#1, "SHA256", "HexString"] &, dependencyFiles];
driverHashAtCompletion = FileHash[$InputFileName,
  "SHA256", "HexString"];
newMessages = Drop[$MessageList, messageCount];
assert["dependencies_and_driver_unchanged",
  dependencyHashesAtCompletion === dependencyHashesBefore &&
    driverHashAtCompletion === driverHashBefore];
assert["no_unexpected_messages", newMessages === {}];

allPassed = AllTrue[checks,
  TrueQ[Lookup[#1, "Pass", False]] &];
result = <|
  "Status" -> If[allPassed,
    "CrossPrimePlanAdversarialSmokePassed",
    "CrossPrimePlanAdversarialSmokeFailed"],
  "Checks" -> checks,
  "PilotPrime" -> pilotPrime,
  "ReusePrime" -> reusePrime,
  "EpsilonValues" -> epsilonValues,
  "DenseTrapCounts" -> <|
    "CanonicalRREF" -> canonicalDenseCalls,
    "PlanDiscovery" -> planDiscoveryCalls|>,
  "PlanSummary" -> If[AssociationQ[plan], KeyTake[plan,
    {"Status", "PlanVersion", "PlanFingerprint", "PointCount",
      "MatrixDimensions", "GenericRank", "Nullity",
      "NormalizationColumns", "PilotPrime"}], <||>],
  "DegreeProfileFingerprint" -> If[ListQ[degreeProfile],
    fingerprint[degreeProfile], $Failed],
  "DirectSolveSummary" -> If[AssociationQ[directSolve],
    KeyTake[directSolve, {"Status", "Rank", "Nullity",
      "ResidualZero", "NullspaceResidualZero", "NormalizationCheck",
      "Backend", "SolvePath"}], <||>],
  "CorruptSolveSummary" -> If[AssociationQ[corruptSolve],
    KeyTake[corruptSolve, {"Status", "ResidualZero",
      "NullspaceResidualZero", "NormalizationCheck"}], <||>],
  "SourceHashEvidence" -> <|
    "OriginalSHA256" -> sourceHashBefore,
    "AlteredSHA256" -> alteredSourceHash|>,
  "DependencyHashes" -> dependencyHashesBefore,
  "DriverSHA256" -> driverHashBefore,
  "MessageNames" -> newMessages|>;
If[writeAtomic[result] === $Failed,
  Print["CF300R2CPSMOKE FAIL atomic output race output=", outputFile];
  Exit[98]];
Print["CF300R2CPSMOKE RESULT status=", result["Status"],
  " passed=", Count[Lookup[checks, "Pass", {}], True],
  "/", Length[checks], " output=", outputFile];
Exit[If[allPassed, 0, 1]];
