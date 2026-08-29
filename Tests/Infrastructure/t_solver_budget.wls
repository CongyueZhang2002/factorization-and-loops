#!/usr/bin/env wolframscript
(* Cooperative budget enforcement in the strip solvers (2026-08-24).

   Until today the driver's per-sector budget (FACET_SECTOR_BUDGET) bound
   only the Maple/CANONICA routes: the finite-field and multiquadratic
   engines ran unbounded (CF300 (12,9) and CF303 sector 17 each ran past
   two hours on the multiquadratic engine).  Both engines now take an
   absolute "Deadline" (an AbsoluteTime[] value, Infinity by default) and
   stop COOPERATIVELY at their own unit boundaries -- between
   support-census candidates, between sample batches, between primes,
   between regulator values, between support-learning cycles.  The stop is
   never TimeConstrained (it does not bound task-broker helpers and has
   escaped in pool subkernels before), never $Aborted, and never an
   exception.

   Acceptance criteria, stated before the run:

   (a) REGRESSION.  Each fixture solved with "Deadline" -> Infinity gives
       the same result as the same fixture solved without the option:
       the same status, the same mathematical payload key by key, and the
       expectation the existing suite already records for that fixture
       (Tests/FiniteField/t_finite_field_strip_solve.wls: ExactPfaffianResidualsZero
       and DLogFormCertified; Tests/Multiquadratic/t_multiquadratic_strip_solve.wls:
       terminal status "ModularConsistent", never "Solved", the exact
       lift equal to the known coefficient vector).

   (b) EXPIRY.  The same fixture with "Deadline" -> AbsoluteTime[] + 0.01
       returns an Association with Status "BudgetExhausted" and a named
       "Stage" drawn from the declared stage vocabulary, in under 30 s of
       wall time, and returns neither $Aborted nor $Failed nor an
       exception.

   (c) PARTIAL PROGRESS.  The BudgetExhausted result carries the progress
       identifiers the surrounding code already tracks -- the current
       prime, the samples done, the support size, the elapsed time, the
       deadline it was given -- and declares itself resumable.

   The fixtures are the ones the existing finite-field and multiquadratic
   suites use: the synthetic 1x1 strip of
   Tests/FiniteField/t_finite_field_strip_solve.wls (the
   FACET_AUTOMATED_FINITE_FIELD_TEST record) and the rank-1 1x1
   constructed block of Tests/Multiquadratic/t_multiquadratic_strip_solve.wls. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 4]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
solveMultiquadratic = mq["solveEpsFormStripMultiquadratic"];
multiquadraticRootOrder = mq["multiquadraticStripRootOrder"];
multiquadraticPrepare = mq["multiquadraticStripPrepare"];

(* the stage vocabulary the two engines may name; a BudgetExhausted
   result outside it is a defect, not a pass *)
finiteFieldStages = {"Entry", "SupportLearningCycle", "SupportCensus",
  "EliminationPilot", "SupportLearning", "PrimeLoop", "SampleBatch",
  "UnseenPrimeResidual"};
(* the three screen stages joined the vocabulary on 2026-08-25 (Codex
   04:30 P1): the default-on screens now carry the cooperative deadline
   themselves, so an expired budget stops at the screen it was running
   instead of surviving until "Preparation" *)
multiquadraticStages = {"Entry", "IntegrabilityScreen", "Preparation",
  "GaugeScreen", "GaugeScreenLadder", "ModularSampling",
  "HeldOutGuard", "BranchCertificate", "ExactLift"};
(* multiquadraticStripPrepare became cooperatively deadline-aware on
   2026-08-25 (until then it was the one stage of this engine a sector
   budget could not stop: a mission measured 51 minutes inside a
   first-call prepare on CF300 sector 12 with no way out).  Its interior
   boundaries name themselves "Preparation:<substage>", so the stage
   vocabulary admits that form as well as the bare "Preparation" the
   entry gate still uses. *)
multiquadraticPrepareSubstages = {"Entry", "RootOrder", "ForcingChannels",
  "CandidateLetters", "GaugeDenominator", "ABIPayload", "CompileTensor"};
(* multiquadraticStripCompile became cooperatively deadline-aware on
   2026-08-25 (Codex 14:30: the public path checked the budget only
   AFTER compile returned, so a multi-minute symbolic compile could not
   be stopped).  Its boundaries name themselves "Compilation:<substage>"
   and the finer position inside a stage travels in the stop's own
   "Substage" key rather than in the stage name, which is what keeps
   this vocabulary closed. *)
multiquadraticCompileSubstages = {"Entry", "Core", "OneForms",
  "GaugeDenominator"};
multiquadraticStageQ[stage_] := StringQ[stage] &&
  (MemberQ[multiquadraticStages, stage] ||
    (StringStartsQ[stage, "Preparation:"] &&
      MemberQ[multiquadraticPrepareSubstages,
        StringDrop[stage, StringLength["Preparation:"]]]) ||
    (StringStartsQ[stage, "Compilation:"] &&
      MemberQ[multiquadraticCompileSubstages,
        StringDrop[stage, StringLength["Compilation:"]]]));

budgetExhaustedQ[r_] := AssociationQ[r] &&
  Lookup[r, "Status", None] === "BudgetExhausted";

(* the progress keys every BudgetExhausted result must carry *)
commonProgressKeys = {"Status", "Stage", "Elapsed", "Deadline", "Method",
  "Resumable"};
finiteFieldProgressKeys = Join[commonProgressKeys,
  {"Prime", "PrimesCompleted", "PrimesUsed", "SamplesDone", "SupportSize",
   "SelectedNumeratorDegreeOffset", "SelectedSupportShell", "ProbeCount",
   "BrokerActive"}];
multiquadraticProgressKeys = Join[commonProgressKeys,
  {"Family", "Sector", "LowerSector", "Prime", "RegulatorValue",
   "SamplesDone", "SupportSize", "UnknownCount", "RootCount"}];

progressComplete[r_, keys_List] :=
  AssociationQ[r] && And @@ (KeyExistsQ[r, #] & /@ keys) &&
    NumericQ[Lookup[r, "Elapsed", None]] &&
    Lookup[r, "Elapsed", -1] >= 0 &&
    TrueQ[Lookup[r, "Resumable", False]];

(* ------------------------------------------------------------------ *)
(* Fixture 1: the synthetic finite-field strip                          *)
(* ------------------------------------------------------------------ *)

Clear[xSynthetic, ySynthetic, epsSynthetic];
syntheticRecord = <|
  "Variables" -> {xSynthetic, ySynthetic},
  "Regulator" -> epsSynthetic,
  "Strip" -> {
    {{{1}}, {{0}}},
    {{{0}}, {{0}}},
    {{{1 - epsSynthetic xSynthetic}}, {{0}}}
  }
|>;
(* exactly the option set Tests/FiniteField/t_finite_field_strip_solve.wls uses for
   its automated solve, so the comparison is against a recorded
   expectation and not a fresh one *)
(* enlarged 2026-08-27: the round-3 port made the fixture solve in
   ~0.45 s, UNDER the 0.75 s floor of the self-calibrating mid-solve
   budget, so the mid-solve deadline could never fire (the solve
   completed first).  More epsilon samples and points stretch the solve
   back over the floor while keeping the budget self-calibrating. *)
finiteFieldOptions = {
  "Primes" -> {1000003},
  "EpsilonSamples" -> ((#/(# + 40)) & /@ Range[36]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}},
  "PointCount" -> 16,
  "KernelCount" -> 2,
  "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4,
  "MinimumPrimeCount" -> 1,
  "Verbose" -> False};

{baselineSeconds, finiteFieldBaseline} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
    Sequence @@ finiteFieldOptions]];
{infinitySeconds, finiteFieldInfinity} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
    Sequence @@ finiteFieldOptions, "Deadline" -> Infinity]];

check["finite field: the fixture solves without the option (the existing suite's expectation)",
  AssociationQ[finiteFieldBaseline] &&
    TrueQ[finiteFieldBaseline["ExactPfaffianResidualsZero"]] &&
    TrueQ[finiteFieldBaseline["DLogFormCertified"]]];
check["finite field: Deadline -> Infinity solves the fixture the same way",
  AssociationQ[finiteFieldInfinity] &&
    TrueQ[finiteFieldInfinity["ExactPfaffianResidualsZero"]] &&
    TrueQ[finiteFieldInfinity["DLogFormCertified"]]];
(* the mathematical payload, key by key; the timing fields differ by
   construction and are excluded by name *)
finiteFieldPayloadKeys = {"Status", "Method", "Gauge", "Alphabet",
  "ResidueMatrices", "GaugeNumeratorDegrees", "GaugeDenominatorDegrees",
  "LettersEpsFree", "ResiduesKinematicsFree", "ExactDLog",
  "DLogFormCertified", "ExactPfaffianResidualsZero", "Primes",
  "SelectedNumeratorDegreeOffset", "SelectedSupportShell",
  "ModularPrimeCount", "UnseenPrime"};
check["finite field: Deadline -> Infinity changes no payload key",
  AssociationQ[finiteFieldBaseline] && AssociationQ[finiteFieldInfinity] &&
    KeyTake[finiteFieldBaseline, finiteFieldPayloadKeys] ===
      KeyTake[finiteFieldInfinity, finiteFieldPayloadKeys]];
check["finite field: Deadline -> Infinity changes no result key set",
  AssociationQ[finiteFieldBaseline] && AssociationQ[finiteFieldInfinity] &&
    Keys[finiteFieldBaseline] === Keys[finiteFieldInfinity]];
report["finite field baseline / Deadline -> Infinity seconds",
  Round[{baselineSeconds, infinitySeconds}, 0.01]];

{expirySeconds, finiteFieldExpired} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
    Sequence @@ finiteFieldOptions,
    "Deadline" -> AbsoluteTime[] + 0.01]];
check["finite field: an expired deadline returns Status BudgetExhausted",
  budgetExhaustedQ[finiteFieldExpired]];
check["finite field: the stop is typed, never $Aborted and never $Failed",
  finiteFieldExpired =!= $Aborted && finiteFieldExpired =!= $Failed &&
    AssociationQ[finiteFieldExpired]];
check["finite field: the stop names a stage from the declared vocabulary",
  MemberQ[finiteFieldStages, Lookup[finiteFieldExpired, "Stage", None]]];
check["finite field: the stop returns in under 30 s of wall time",
  expirySeconds < 30];
check["finite field: the stop carries the partial-progress identifiers",
  progressComplete[finiteFieldExpired, finiteFieldProgressKeys]];
check["finite field: the reported progress counters are well formed",
  budgetExhaustedQ[finiteFieldExpired] &&
    IntegerQ[finiteFieldExpired["PrimesCompleted"]] &&
    finiteFieldExpired["PrimesCompleted"] >= 0 &&
    IntegerQ[finiteFieldExpired["SamplesDone"]] &&
    finiteFieldExpired["SamplesDone"] >= 0 &&
    IntegerQ[finiteFieldExpired["ProbeCount"]] &&
    MatchQ[finiteFieldExpired["Prime"], _Integer | None]];
report["finite field expiry", KeyTake[finiteFieldExpired,
  {"Stage", "Elapsed", "Prime", "PrimesCompleted", "SamplesDone",
   "SupportSize", "ProbeCount", "SupportLearningPass"}]];
report["finite field expiry wall seconds", Round[expirySeconds, 0.01]];

check["finite field: a malformed deadline is a typed refusal, not a crash",
  Lookup[FeynFacet`SolveEpsFormStripFiniteField[syntheticRecord,
    Sequence @@ finiteFieldOptions, "Deadline" -> "soon"],
    "Status", None] === "InvalidDeadline"];

(* ------------------------------------------------------------------ *)
(* Fixture 2: the rank-1 constructed multiquadratic block               *)
(* ------------------------------------------------------------------ *)
(* the construction is the one of Tests/Multiquadratic/t_multiquadratic_strip_solve.wls:
   the block is BUILT from a known gauge and known residues written in
   the solver's own ansatz basis, so the expectation is recorded, not
   discovered here *)

Clear[x, y, eps, v, w, cx, cy];
frame = BuildAlgebraicTransportFrame[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
check["the rank-three multiquadratic frame is exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame"];

dlog[letter_] := {D[Log[letter], x], D[Log[letter], y]};
letters = {x, y, 1 - x - y};
oneForms = dlog /@ letters;
denominator = 1 - x - y;
support = Sort[{{0, 0}, {0, 1}, {1, 0}}];
diagonalForm[residues_List] := Table[
  Sum[residues[[a]] oneForms[[a, mu]], {a, Length[letters]}], {mu, 2}];
canonicalRoots[indices_] := Module[
  {order = multiquadraticRootOrder[frame, {x, y}, indices, eps]},
  If[Lookup[order, "Status", None] =!= "StableRootOrder", $Failed,
    Lookup[order["Roots"], "Root", {}]]];
gradeFactor[grade_, roots_] :=
  Product[If[BitGet[grade, k - 1] === 1, roots[[k]], 1], {k, Length[roots]}];
buildGauge[coefficients_, dimensions_, roots_] := Table[
  Sum[coefficients[[i, j, grade + 1, monomial]]
      x^support[[monomial, 1]] y^support[[monomial, 2]] gradeFactor[grade, roots]/
      denominator,
    {grade, 0, 2^Length[roots] - 1}, {monomial, Length[support]}],
  {i, dimensions[[1]]}, {j, dimensions[[2]]}];
buildForcing[e_, c_, gauge_, residues_] := Table[
  Map[Together, Sum[residues[[a]] eps oneForms[[a, mu]], {a, Length[letters]}] +
    D[gauge, {x, y}[[mu]]] - eps (e[[mu]] . gauge - gauge . c[[mu]]), {2}],
  {mu, 2}];
randomCoefficients[dimensions_, gradeCount_, seed_] := BlockRandom[
  SeedRandom[seed];
  Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
    {dimensions[[1]]}, {dimensions[[2]]}, {gradeCount}, {Length[support]}]];
randomResidues[dimensions_, seed_] := BlockRandom[SeedRandom[seed];
  Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
    {Length[letters]}, {dimensions[[1]]}, {dimensions[[2]]}]];
randomDiagonal[size_, seed_] := BlockRandom[SeedRandom[seed];
  diagonalForm[Table[RandomInteger[{-2, 2}, {size, size}], {Length[letters]}]]];

(* RANK1_1x1 of the multiquadratic suite: indices {1}, dimensions {1, 1},
   seed 202 *)
mqIndices = {1}; mqDimensions = {1, 1}; mqSeed = 202;
mqRoots = canonicalRoots[mqIndices];
mqCoefficients = randomCoefficients[mqDimensions, 2^Length[mqIndices], mqSeed];
mqResidues = randomResidues[mqDimensions, mqSeed + 1];
mqGauge = buildGauge[mqCoefficients, mqDimensions, mqRoots];
mqE = randomDiagonal[mqDimensions[[1]], mqSeed + 2];
mqC = randomDiagonal[mqDimensions[[2]], mqSeed + 3];
mqRecord = <|"Family" -> "BUDGET_RANK1_1x1", "Sector" -> 4,
  "LowerSector" -> 2, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {mqE, mqC, buildForcing[mqE, mqC, mqGauge, mqResidues]}|>;
mqOptions = {"OneForms" -> oneForms, "GaugeDenominator" -> denominator,
  "Support" -> support};

{mqBaselineSeconds, mqBaseline} = AbsoluteTiming[
  solveMultiquadratic[mqRecord, frame, Sequence @@ mqOptions]];
{mqInfinitySeconds, mqInfinity} = AbsoluteTiming[
  solveMultiquadratic[mqRecord, frame, Sequence @@ mqOptions,
    "Deadline" -> Infinity]];

check["multiquadratic: the fixture is modular-consistent without the option (the existing suite's expectation)",
  AssociationQ[mqBaseline] && mqBaseline["Status"] === "ModularConsistent" &&
    mqBaseline["Status"] =!= "Solved"];
check["multiquadratic: Deadline -> Infinity is modular-consistent the same way",
  AssociationQ[mqInfinity] && mqInfinity["Status"] === "ModularConsistent" &&
    mqInfinity["Status"] =!= "Solved"];
(* Runtime counters and the CFFR nonce-bound plan provenance differ by
   construction.  Compare every mathematical field, including the plan's
   rank, section and pivots, after removing only those operational fields. *)
mqTimingKeys = {"Seconds", "ChannelPathStatistics", "RootFreeFastPathCount"};
mqComparable[result_] := Module[{copy, reconstruction, plan},
  copy = KeyDrop[result, mqTimingKeys];
  reconstruction = Lookup[copy, "RegulatorReconstruction", None];
  If[! AssociationQ[reconstruction], Return[copy]];
  reconstruction = KeyDrop[reconstruction,
    {"ImagePhaseRecords", "PhaseSeconds", "PlanDiscoveryTelemetry",
     "Seconds"}];
  plan = Lookup[reconstruction, "ConstrainedEliminationPlan", None];
  If[AssociationQ[plan],
    reconstruction["ConstrainedEliminationPlan"] = KeyTake[plan,
      {"Status", "UnknownCount", "EquationCount", "Rank", "Nullity",
       "NormalizationColumns", "PivotColumns", "FreeColumns",
       "PivotSignature", "LayoutFingerprint", "ProviderFingerprint",
       "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
       "PlanDiscoveryBackendThreads", "PilotPrime", "PilotReplayMethod",
       "PilotParticularResidualZero", "PilotNullspaceResidualZero"}]];
  copy["RegulatorReconstruction"] = reconstruction;
  copy];
check["multiquadratic: Deadline -> Infinity changes no payload key",
  AssociationQ[mqBaseline] && AssociationQ[mqInfinity] &&
    mqComparable[mqBaseline] === mqComparable[mqInfinity]];
(* the recorded expectations of the unpinned case in
   Tests/Multiquadratic/t_multiquadratic_strip_solve.wls: the nullity is exactly the
   constant-gauge freedom, every sign branch has zero residual, and the
   direct rows agree with the split-sign assembly *)
check["multiquadratic: Deadline -> Infinity keeps the unpinned expectations",
  AssociationQ[mqInfinity] &&
    mqInfinity["Nullity"] === Times @@ mqDimensions &&
    mqInfinity["RootCount"] === Length[mqIndices] &&
    Length[mqInfinity["BranchCertificate"]] === 2^Length[mqIndices] &&
    AllTrue[mqInfinity["BranchCertificate"], TrueQ[#["ResidualZero"]] &] &&
    mqInfinity["DifferentialCheck"]["Status"] ===
      "MultiquadraticPointDifferentialPassed"];
report["multiquadratic baseline / Deadline -> Infinity seconds",
  Round[{mqBaselineSeconds, mqInfinitySeconds}, 0.01]];

{mqExpirySeconds, mqExpired} = AbsoluteTiming[
  solveMultiquadratic[mqRecord, frame, Sequence @@ mqOptions,
    "Deadline" -> AbsoluteTime[] + 0.01]];
check["multiquadratic: an expired deadline returns Status BudgetExhausted",
  budgetExhaustedQ[mqExpired]];
check["multiquadratic: the stop is typed, never $Aborted and never $Failed",
  mqExpired =!= $Aborted && mqExpired =!= $Failed && AssociationQ[mqExpired]];
check["multiquadratic: the stop names a stage from the declared vocabulary",
  multiquadraticStageQ[Lookup[mqExpired, "Stage", None]]];
check["multiquadratic: the stop returns in under 30 s of wall time",
  mqExpirySeconds < 30];
check["multiquadratic: the stop carries the partial-progress identifiers",
  progressComplete[mqExpired, multiquadraticProgressKeys]];
check["multiquadratic: the stop identifies the block it was solving",
  budgetExhaustedQ[mqExpired] &&
    mqExpired["Family"] === "BUDGET_RANK1_1x1" &&
    mqExpired["Sector"] === 4 && mqExpired["LowerSector"] === 2 &&
    IntegerQ[mqExpired["SamplesDone"]] && mqExpired["SamplesDone"] >= 0];
report["multiquadratic expiry", KeyTake[mqExpired,
  {"Stage", "Elapsed", "Prime", "RegulatorValue", "SamplesDone",
   "SupportSize", "UnknownCount", "RootCount"}]];
report["multiquadratic expiry wall seconds", Round[mqExpirySeconds, 0.01]];

check["multiquadratic: a malformed deadline is a typed refusal, not a crash",
  Lookup[solveMultiquadratic[mqRecord, frame, Sequence @@ mqOptions,
    "Deadline" -> "soon"], "Status", None] === "InvalidDeadline"];
check["multiquadratic: Deadline is an accepted option, not an unknown one",
  Lookup[solveMultiquadratic[mqRecord, frame, Sequence @@ mqOptions,
    "Deadline" -> Infinity], "Status", None] =!= "UnknownOption"];

(* the preparation stage itself, which until 2026-08-25 had no deadline
   coverage at all: its typed stop must be shape-compatible with every
   other typed stop of this engine, or a driver's failure summary cannot
   read it *)
mqPrepareExpired = multiquadraticPrepare[mqRecord, frame,
  "Deadline" -> AbsoluteTime[] - 1];
check["multiquadratic prepare: an expired deadline is a typed \
BudgetExhausted naming a Preparation substage",
  budgetExhaustedQ[mqPrepareExpired] &&
    multiquadraticStageQ[Lookup[mqPrepareExpired, "Stage", None]] &&
    StringStartsQ[Lookup[mqPrepareExpired, "Stage", ""], "Preparation:"]];
check["multiquadratic prepare: the stop carries the engine's common \
partial-progress identifiers",
  progressComplete[mqPrepareExpired, multiquadraticProgressKeys]];
check["multiquadratic prepare: Deadline -> Infinity is byte-identical to \
passing no option",
  SameQ[multiquadraticPrepare[mqRecord, frame],
    multiquadraticPrepare[mqRecord, frame, "Deadline" -> Infinity]]];
check["multiquadratic prepare: a malformed deadline is a typed refusal",
  Lookup[multiquadraticPrepare[mqRecord, frame, "Deadline" -> "soon"],
    "Status", None] === "InvalidDeadline"];
report["multiquadratic prepare expiry", KeyTake[mqPrepareExpired,
  {"Stage", "Elapsed", "Family", "Sector", "LowerSector", "RootCount",
   "ForcingChannelsDone", "LetterCount", "SupportSize"}]];

(* the COMPILE stage, cooperatively deadline-aware since 2026-08-25: its
   typed stop must be shape-compatible with every other stop of this
   engine for the same reason prepare's is *)
mqPreparation = multiquadraticPrepare[mqRecord, frame];
mqCompileExpired = If[Lookup[mqPreparation, "Status", None] ===
    "PreparedMultiquadraticStripV1",
  FeynFacet`Private`multiquadraticStripCompile[mqPreparation,
    "PreparationValidated" -> True, "Deadline" -> AbsoluteTime[] - 1],
  <|"Status" -> "PreparationFailed"|>];
check["multiquadratic compile: an expired deadline is a typed \
BudgetExhausted naming a Compilation substage",
  budgetExhaustedQ[mqCompileExpired] &&
    multiquadraticStageQ[Lookup[mqCompileExpired, "Stage", None]] &&
    StringStartsQ[Lookup[mqCompileExpired, "Stage", ""], "Compilation:"]];
check["multiquadratic compile: the stop carries the engine's common \
partial-progress identifiers",
  progressComplete[mqCompileExpired, multiquadraticProgressKeys]];
check["multiquadratic compile: Deadline -> Infinity is byte-identical to \
passing no option",
  Module[{withOption, without},
    withOption = FeynFacet`Private`multiquadraticStripCompile[mqPreparation,
      "PreparationValidated" -> True, "Deadline" -> Infinity];
    without = FeynFacet`Private`multiquadraticStripCompile[mqPreparation,
      "PreparationValidated" -> True];
    SameQ[KeyDrop[withOption, "CompileStatistics"],
      KeyDrop[without, "CompileStatistics"]]]];
check["multiquadratic compile: a malformed deadline is a typed refusal",
  Lookup[FeynFacet`Private`multiquadraticStripCompile[mqPreparation,
    "PreparationValidated" -> True, "Deadline" -> "soon"], "Status", None] ===
    "InvalidDeadline"];
report["multiquadratic compile expiry", KeyTake[mqCompileExpired,
  {"Stage", "Elapsed", "Family", "Sector", "LowerSector", "RootCount",
   "OneFormCount", "UnknownCount", "Architecture"}]];

Print["t_solver_budget: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
