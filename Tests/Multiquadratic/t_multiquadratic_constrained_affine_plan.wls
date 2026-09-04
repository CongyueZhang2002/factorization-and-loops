#!/usr/bin/env wolframscript
(* Pilot/constrained-core equality and fallback tests. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{fullSolve, discover, plannedSolve, fallbackSolve, planValidQ,
  discoverySolve, backendDecision, consistencyEvidence,
  residualEvidenceValidQ} = mq /@ {
  "multiquadraticStripAffineSolve",
  "multiquadraticStripConstrainedPlanDiscover",
  "multiquadraticStripConstrainedAffineSolve",
  "multiquadraticStripConstrainedAffineFallback",
  "multiquadraticStripConstrainedPlanValidQ",
  "multiquadraticStripPlanDiscoverySolve",
  "multiquadraticStripPlanDiscoveryBackendDecision",
  "multiquadraticStripAffineConsistencyEvidence",
  "multiquadraticStripFullResidualEvidenceValidQ"};

prime = 1000003;
originalCheckLevel = Quiet[Environment["FACET_CHECK_LEVEL"]];
SetEnvironment["FACET_CHECK_LEVEL" -> ""];
coefficientData[tag_] := <|"Schema" -> "TestCoefficientDataV1",
  "Tag" -> tag|>;

(* rootRank controls the grade multiplicity of the synthetic block; the
   affine algebra itself is deliberately generic.  The first rank rows are
   an explicit basis and the trailing rows are dependent checks. *)
fixture[rootRank_Integer, shift_Integer] := Module[
  {unknowns = 6 + 2^rootRank, nullity, rank, base, extras, matrix, vector},
  nullity = Min[3, rootRank + 1]; rank = unknowns - nullity;
  base = Table[Join[UnitVector[rank, i], Table[
      Mod[(i + shift) (j + 2) + i j + shift, prime], {j, nullity}]],
    {i, rank}];
  extras = Table[Mod[base[[1 + Mod[k, rank]]] +
      (k + 1) base[[1 + Mod[2 k + 1, rank]]], prime], {k, 1, 3}];
  matrix = Join[base, extras];
  vector = Join[Table[Mod[17 i + 13 shift, prime], {i, rank}],
    ConstantArray[0, nullity]];
  <|"Matrix" -> matrix, "Vector" -> vector,
    "Right" -> Mod[matrix . vector, prime], "Rank" -> rank,
    "Nullity" -> nullity,
    "NormalizationColumns" -> (rank + Range[nullity])|>
];

Do[
  pilot = fixture[rootRank, 1];
  wolframPilot = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
    Length[First[pilot["Matrix"]]], 0, "Wolfram", 2, 0];
  nativePilot = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
    Length[First[pilot["Matrix"]]], 0, "FLINTAffineRREF", 2, 0];
  check["declared root rank " <> ToString[rootRank] <>
      " native and Wolfram affine data agree exactly",
    KeyTake[nativePilot, {"Rank", "Nullity", "PivotColumns",
        "FreeColumns", "ParticularSolution",
        "NullspaceBasis"}] ===
      KeyTake[wolframPilot, {"Rank", "Nullity", "PivotColumns",
        "FreeColumns", "ParticularSolution",
        "NullspaceBasis"}] &&
      nativePilot["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF" &&
      nativePilot["PlanDiscoveryBackendThreads"] === 2 &&
      NumericQ[nativePilot["PlanDiscoveryBackendSeconds"]]];
  pilotFull = fullSolve[pilot["Matrix"], pilot["Right"], prime];
  plan = discover[pilot["Matrix"], pilot["Right"], pilotFull,
    pilot["NormalizationColumns"], prime, coefficientData[rootRank]];
  later = fixture[rootRank, 7];
  laterFull = fullSolve[later["Matrix"], later["Right"], prime];
  laterCanonical = NormalizeEpsFormAffineSample[
    <|"ParticularSolution" -> laterFull["ParticularSolution"],
      "NullspaceBasis" -> laterFull["NullspaceBasis"]|>,
    pilot["NormalizationColumns"], prime];
  laterPlanned = plannedSolve[later["Matrix"], later["Right"], prime, plan];
  check["declared root rank " <> ToString[rootRank] <>
      " discovers an authenticated constrained plan",
    planValidQ[plan] &&
      Lookup[plan, "Status", None] ===
        "MultiquadraticConstrainedAffinePlanV1"];
  check["declared root rank " <> ToString[rootRank] <>
      " constrained solution equals the full affine section",
    Lookup[laterPlanned, "Status", None] ===
        "MultiquadraticConstrainedAffineSolution" &&
      laterPlanned["CanonicalValues"] ===
        laterCanonical["ParticularSolution"] &&
      TrueQ[laterPlanned["FullResidualZero"]] &&
      TrueQ[laterPlanned["NullspaceResidualZero"]] &&
      laterPlanned["FullResidualCheckMethod"] === "ExactMatrixMatrix" &&
      TrueQ[laterPlanned["FullResidualExact"]] &&
      laterPlanned["ConstrainedSolveFullResidualReplayCount"] === 1 &&
      residualEvidenceValidQ[laterPlanned, prime]],
  {rootRank, 0, 3}];

(* Cross the production fixed-core threshold with a genuinely wide affine
   section.  This is intentionally unrelated to a named family: the direct
   solver must route any sufficiently large authenticated constrained core
   through the existing CFFA4 multi-RHS adapter and retain the canonical
   section without a redundant Wolfram all-row replay. *)
wideFixture[shift_Integer] := Module[
  {unknowns = 260, nullity = 12, rank = 248, base, extras, matrix, vector},
  base = Table[Join[UnitVector[rank, i], Table[
      Mod[(i + shift) (j + 3) + 2 i j + 17, prime], {j, nullity}]],
    {i, rank}];
  extras = Table[Mod[base[[1 + Mod[3 k, rank]]] +
      (k + shift + 1) base[[1 + Mod[5 k + 1, rank]]], prime],
    {k, 1, 16}];
  matrix = Join[base, extras];
  vector = Join[Table[Mod[31 i + 19 shift, prime], {i, rank}],
    ConstantArray[0, nullity]];
  <|"Matrix" -> matrix, "Vector" -> vector,
    "Right" -> Mod[matrix . vector, prime],
    "NormalizationColumns" -> (rank + Range[nullity])|>
];
widePilot = wideFixture[2];
widePilotFull = discoverySolve[widePilot["Matrix"], widePilot["Right"], prime,
  Length[First[widePilot["Matrix"]]], 0, "FLINTAffineRREF", 8, 0];
widePlan = discover[widePilot["Matrix"], widePilot["Right"], widePilotFull,
  widePilot["NormalizationColumns"], prime, coefficientData["wide"],
  widePilotFull["IndependentEquationRows"]];
wideLater = wideFixture[9];
widePlanned = plannedSolve[wideLater["Matrix"], wideLater["Right"], prime,
  widePlan];
check["large constrained follower uses the CFFA4-certified core directly",
  Lookup[widePlanned, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution" &&
    widePlanned["ConstrainedSolveBackendUsed"] === "FLINT" &&
    widePlanned["ConstrainedSolveBackendThreads"] === 8 &&
    widePlanned["ConstrainedSolveNativeCoreReplayCount"] === 0 &&
    (* U2 (2026-09-02): the native core is trusted for the core rows and
       ALL original rows are replayed by Freivalds projections *)
    widePlanned["ConstrainedSolveFullResidualReplayCount"] === 1 &&
    widePlanned["FullResidualCheckMethod"] ===
      "NativeCoreVerifiedFreivaldsAllRows" &&
    ! TrueQ[widePlanned["FullResidualExact"]] &&
    TrueQ[widePlanned["FullResidualZero"]] &&
    widePlanned["FreivaldsProjections"] === 2 &&
    TrueQ[widePlanned["NativeCoreResidualZero"]] &&
    TrueQ[widePlanned["NativeCoreResidualExact"]] &&
    widePlanned["ConstrainedSolveNativeValidationFailure"] === None &&
    ! TrueQ[widePlanned["ConstrainedSolveNativeValidationRecovered"]] &&
    widePlanned["CanonicalValues"] === wideLater["Vector"] &&
    residualEvidenceValidQ[widePlanned, prime]];

wideNativeMatrix = Transpose[Prepend[widePlanned["NullspaceBasis"],
  widePlanned["ParticularSolution"]]];
wideNormalizationCorrupt = ReplacePart[wideNativeMatrix,
  {First[widePlan["NormalizationColumns"]], 2} -> 0];
wideNormalizationRecovered = Internal`InheritedBlock[
  {FeynFacet`Private`finiteFieldStripFLINTSolve},
  Unprotect[FeynFacet`Private`finiteFieldStripFLINTSolve];
  Clear[FeynFacet`Private`finiteFieldStripFLINTSolve];
  FeynFacet`Private`finiteFieldStripFLINTSolve[___] :=
    wideNormalizationCorrupt;
  Protect[FeynFacet`Private`finiteFieldStripFLINTSolve];
  plannedSolve[wideLater["Matrix"], wideLater["Right"], prime, widePlan]];
check["normalization is exact and precedes the all-row residual replay",
  Lookup[wideNormalizationRecovered, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution" &&
    wideNormalizationRecovered["ConstrainedSolveNativeValidationFailure"] ===
      "FLINTNormalizationValidationFailed" &&
    wideNormalizationRecovered["ConstrainedSolveFullResidualReplayCount"] ===
      1 && Length[wideNormalizationRecovered["FullResidualChecks"]] === 1 &&
    wideNormalizationRecovered["FullResidualChecks"][[1, "Status"]] ===
      "Accepted"];

SetEnvironment["FACET_CHECK_LEVEL" -> "Production"];
productionExact = plannedSolve[wideLater["Matrix"], wideLater["Right"],
  prime, widePlan];
SetEnvironment["FACET_CHECK_LEVEL" -> ""];
check["Production trusts the exact native core and replays all rows by Freivalds projection (U2)",
  Lookup[productionExact, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution" &&
    productionExact["FullResidualCheckMethod"] ===
      "NativeCoreVerifiedFreivaldsAllRows" &&
    ! TrueQ[productionExact["FullResidualExact"]] &&
    TrueQ[productionExact["FullResidualZero"]] &&
    productionExact["ConstrainedSolveFullResidualReplayCount"] === 1 &&
    residualEvidenceValidQ[productionExact, prime]];

wideUnavailable = Block[{FeynFacet`Private`$feynFacetDirectory =
      FileNameJoin[{$TemporaryDirectory,
        "cffa4-follower-definitely-absent"}]},
  plannedSolve[wideLater["Matrix"], wideLater["Right"], prime, widePlan]];
check["large constrained follower falls back exactly when CFFA4 is absent",
  Lookup[wideUnavailable, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution" &&
    wideUnavailable["ConstrainedSolveBackendUsed"] === "Wolfram" &&
    wideUnavailable["ConstrainedSolveBackendFallbackReason"] ===
      "FLINTAdapterUnavailable" &&
    wideUnavailable["CanonicalValues"] === wideLater["Vector"] &&
    TrueQ[wideUnavailable["FullResidualZero"]] &&
    TrueQ[wideUnavailable["NullspaceResidualZero"]]];

pilot = fixture[3, 11];
nativePilot = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
  Length[First[pilot["Matrix"]]], 0, "FLINTAffineRREF", 3, 0];
nativePlan = discover[pilot["Matrix"], pilot["Right"], nativePilot,
  pilot["NormalizationColumns"], prime, coefficientData["native-plan"],
  nativePilot["IndependentEquationRows"]];
wolframPilot = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
  Length[First[pilot["Matrix"]]], 0, "Wolfram", 3, 0];
wolframPlan = discover[pilot["Matrix"], pilot["Right"], wolframPilot,
  pilot["NormalizationColumns"], prime, coefficientData["native-plan"]];
check["native discovery translates to the exact constrained-plan semantics",
  planValidQ[nativePlan] && nativePlan["PilotReplayMethod"] ===
      "CFFRFullOriginalRowResiduals" &&
    KeyTake[nativePlan, {"Rank", "Nullity", "IndependentEquationRows",
       "NormalizationColumns", "PivotColumns", "FreeColumns",
       "CoefficientData"}] ===
     KeyTake[wolframPlan, {"Rank", "Nullity", "IndependentEquationRows",
       "NormalizationColumns", "PivotColumns", "FreeColumns",
       "CoefficientData"}]];

automaticNative = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
  Length[First[pilot["Matrix"]]], 0, Automatic, 4, 0];
automaticWolfram = discoverySolve[pilot["Matrix"], pilot["Right"], prime,
  Length[First[pilot["Matrix"]]], 0, Automatic, 4, 10^9];
check["Automatic uses the declared size threshold honestly",
  automaticNative["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF" &&
    automaticWolfram["PlanDiscoveryBackendUsed"] === "Wolfram" &&
    automaticNative["NativeMinimumMatrixEntries"] === 0 &&
    automaticWolfram["NativeMinimumMatrixEntries"] === 10^9];

absent = Block[{FeynFacet`Private`$feynFacetDirectory =
      FileNameJoin[{$TemporaryDirectory, "cffr-definitely-absent"}]},
  backendDecision["FLINTAffineRREF", 2, {10, 10}, 0]];
check["an explicitly absent native adapter is typed and never falls back",
  Lookup[absent, "Status", None] === "PlanDiscoveryBackendUnavailable" &&
    Lookup[absent, "PlanDiscoveryBackendUsed", Missing[]] === None];

badNative = discoverySolve[{{1/2}}, {0}, prime, 1, 0,
  "FLINTAffineRREF", 2, 0];
check["an explicit native request or execution failure is typed",
  Lookup[badNative, "Status", None] === "PlanDiscoveryBackendFailed" &&
    AssociationQ[Lookup[badNative, "BackendFailure", None]]];

automaticFailureFallback = discoverySolve[{{1/2}}, {0}, prime, 1, 0,
  Automatic, 2, 0];
automaticAbsenceFallback = Block[{
    FeynFacet`Private`$feynFacetDirectory =
      FileNameJoin[{$TemporaryDirectory, "cffr-definitely-absent"}]},
  discoverySolve[pilot["Matrix"], pilot["Right"], prime,
    Length[First[pilot["Matrix"]]], 0, Automatic, 2, 0]];
check["Automatic falls back only for adapter failure or absence",
  automaticFailureFallback["Status"] ===
      "MultiquadraticAffineSolution" &&
    automaticFailureFallback["PlanDiscoveryBackendUsed"] === "Wolfram" &&
    automaticFailureFallback["PlanDiscoveryBackendFallbackReason"] ===
      "CFFRRequestMatrixInvalid" &&
    automaticAbsenceFallback["PlanDiscoveryBackendUsed"] === "Wolfram" &&
    automaticAbsenceFallback["PlanDiscoveryBackendFallbackReason"] ===
      "CFFRAdapterUnavailable"];

inconsistent = consistencyEvidence[{{1, 0}, {0, 0}}, {1, 1}, prime,
  2, 0, Automatic, 2, 0];
check["a native inconsistent verdict is preserved without Wolfram fallback",
  inconsistent["Status"] === "ProviderSupportImageInconsistent" &&
    MissingQ[inconsistent["Rank"]] &&
    MissingQ[inconsistent["AugmentedRank"]] &&
    inconsistent["Defect"] === 1 &&
    inconsistent["DefectEvidence"] ===
      "SingleRightHandSideAffineInconsistency" &&
    inconsistent["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF"];

nativeSolveCalls = 0;
countedInconsistent = Internal`InheritedBlock[
  {FeynFacet`Private`multiquadraticStripNativeAffineSolve},
  Unprotect[FeynFacet`Private`multiquadraticStripNativeAffineSolve];
  Clear[FeynFacet`Private`multiquadraticStripNativeAffineSolve];
  FeynFacet`Private`multiquadraticStripNativeAffineSolve[___] :=
    (nativeSolveCalls++;
      <|"Status" -> "InconsistentModularSystem",
        "Module" -> "MultiquadraticStripSolve"|>);
  Protect[FeynFacet`Private`multiquadraticStripNativeAffineSolve];
  consistencyEvidence[{{1, 0}, {0, 0}}, {1, 1}, prime,
    2, 0, "FLINTAffineRREF", 2, 0]];
check["one-RHS native inconsistency does not launch a homogeneous RREF",
  nativeSolveCalls === 1 &&
    countedInconsistent["Status"] === "ProviderSupportImageInconsistent" &&
    countedInconsistent["Defect"] === 1 &&
    countedInconsistent["DefectEvidence"] ===
      "SingleRightHandSideAffineInconsistency"];

(* Make one selected pilot row vanish, but move that exact row to a
   nonselected slot.  The planned core is singular while the full affine
   space, pivot columns, and locked section are unchanged. *)
pilot = fixture[3, 3];
pilotFull = fullSolve[pilot["Matrix"], pilot["Right"], prime];
plan = discover[pilot["Matrix"], pilot["Right"], pilotFull,
  pilot["NormalizationColumns"], prime, coefficientData["adversarial"]];
selected = First[plan["IndependentEquationRows"]];
replacement = First[Complement[Range[Length[pilot["Matrix"]]],
  plan["IndependentEquationRows"]]];
singularMatrix = pilot["Matrix"];
singularMatrix[[replacement]] = singularMatrix[[selected]];
singularMatrix[[selected]] = ConstantArray[0, Length[First[singularMatrix]]];
singularRight = Mod[singularMatrix . pilot["Vector"], prime];
singularPlanned = plannedSolve[singularMatrix, singularRight, prime, plan];
singularFallback = fallbackSolve[singularMatrix, singularRight, prime, plan];
check["a singular reused core is a typed refusal",
  MemberQ[{"ConstrainedCoreSingular", "ConstrainedFullResidualNonzero"},
    Lookup[singularPlanned, "Status", None]]];
check["a singular reused core falls back under the identical section",
  Lookup[singularFallback, "Status", None] ===
      "MultiquadraticConstrainedAffineFallbackSolution" &&
    singularFallback["SolvePath"] === "FullAffineSameSectionFallback" &&
    singularFallback["FallbackReason"] ===
      Lookup[singularPlanned, "Status", None] &&
    singularFallback["CanonicalValues"] === pilot["Vector"]];

check["constrained telemetry separates core solve and full residual",
  AssociationQ[laterPlanned["PhaseSeconds"]] &&
    And @@ (NumericQ[Lookup[laterPlanned["PhaseSeconds"], #, None]] & /@
      {"CoreSolve", "FullResidual"})];

mutatedPlan = ReplacePart[plan, "NormalizationColumns" ->
  ConstantArray[First[plan["NormalizationColumns"]], plan["Nullity"]]];
check["a malformed normalization-column list is rejected",
  ! TrueQ[planValidQ[mutatedPlan]] &&
    Lookup[plannedSolve[pilot["Matrix"], pilot["Right"], prime,
       mutatedPlan], "Status", None] === "InvalidConstrainedAffinePlan"];

SetEnvironment["FACET_CHECK_LEVEL" -> If[StringQ[originalCheckLevel],
  originalCheckLevel, ""]];
Print["t_multiquadratic_constrained_affine_plan: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
