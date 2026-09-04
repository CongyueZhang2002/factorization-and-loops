#!/usr/bin/env wolframscript
(* Cooperative budget enforcement in the STRIP-CONSTRUCTION stage
   (2026-08-24, the second budget gap of the same night).

   The cooperative "Deadline" of Tests/Infrastructure/t_solver_budget.wls lands only
   INSIDE the solvers.  MEASURED in production the same night: both
   campaign missions sat more than two hours in the work BETWEEN the
   driver's "strip {i,j}" announcement and the first solver call --
   CANONICA NextEquationD (or the blockwise block equation), the
   strip-input write, the zero-forcing probe, and then, inside
   SolveEpsFormStripInFrame, the chart pullback, the gauge pullback and
   the source-representation identity check -- where no deadline was ever checked,
   so the 7200 s sector budget passed silently on both families with no
   record of where the time went.

   Acceptance criteria, stated before the run:

   (a) EXPIRY BEFORE CONSTRUCTION.  SolveEpsFormStripInFrame called with
       an already-expired deadline returns an Association with
       Status "BudgetExhausted" and Stage "StripConstruction:Entry", and
       INVOKES NO SOLVER: SolveEpsFormStripFiniteField, SolveEpsFormStrip
       and solveEpsFormStripMultiquadratic are each called zero times
       (counted by Block-scoped stand-ins).  The stop is never $Aborted,
       never $Failed and never an exception.

   (a') EXPIRY AT A LATER BOUNDARY, AND THE BRACKETED WALL TIME.  With
       chart selection made deliberately slow (a Block-scoped stand-in
       that pauses and then returns the true chart) and a deadline placed
       inside that pause, the construction stops at the boundary AFTER
       chart selection, not at the entry gate, and the typed stop's
       "ConstructionTimings" reports the measured wall time of the
       bracketed chart-selection call.  This is the criterion for the
       bracketing rule: an opaque call is checked before and after and
       has its wall time recorded, and is never TimeConstrained.

   (a'') THE DEADLINE REACHES THE SOLVER.  A solver dispatched to by the
       construction stage receives the same absolute deadline through the
       existing option plumbing, and an explicit "Deadline" in
       "FiniteFieldOptions" still wins over it.

   (b) IDENTITY AT Deadline -> Infinity.  On the chart-path strip fixture
       of Tests/Multiquadratic/t_multiquadratic_transport_frame.wls (the one-root
       algebraic strip solved in Kallen1 and pulled back to the
       square-root-generator presentation), the result with
       "Deadline" -> Infinity is byte-identical to the result without the
       option after removing wall-clock timings.  The success payload gains
       no construction-stop key.

   (c) PROPAGATION THROUGH THE DRIVER.  The driver
       Scripts/family_epsform_sector.wls contains EXACTLY ONE
       StripBudgetExhausted stop record (there is no parallel path for
       construction stops), its strip-solve dispatch is guarded by
       ! stripBudgetExhaustedQ[solution], and its SolveEpsFormStripInFrame
       call site passes "Deadline" -> sectorDeadline (the Legacy
       CANONICA/Maple dispatch was removed on 2026-09-02).  Evaluating that single stop record verbatim --
       the text is EXTRACTED from the driver source, never copied into
       this test -- on a real construction stop yields a state Stop
       record with Status "StripBudgetExhausted", a Stage of the form
       "StripConstruction:<substage>", Resumable True, and a Progress
       association carrying the substage wall times.  The driver's own
       construction stop (stripConstructionStop, also extracted from the
       source) feeds the same record. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];

(* the substage vocabulary each construction stage may name; a
   BudgetExhausted result outside it is a defect, not a pass *)
inFrameSubstages = {"Entry", "ParametrizationSelection",
  "ParametrizationPreparation", "ParametrizationPullBack",
  "ParametrizationPullBackComplete", "GaugePullBack",
  "SourceRepresentationIdentity", "SolverDispatch",
  "MultiquadraticDispatch"};
driverSubstages = {"Entry", "EquationConstructed", "StripInputWritten",
  "ZeroForcingProbe", "SolverDispatch"};

budgetExhaustedQ[r_] := AssociationQ[r] &&
  Lookup[r, "Status", None] === "BudgetExhausted";
constructionStopQ[r_, vocabulary_List] := budgetExhaustedQ[r] &&
  StringQ[Lookup[r, "Stage", None]] &&
  StringStartsQ[r["Stage"], "StripConstruction:"] &&
  MemberQ[vocabulary, Lookup[r, "Substage", None]] &&
  r["Stage"] === "StripConstruction:" <> r["Substage"] &&
  NumericQ[Lookup[r, "Elapsed", None]] && r["Elapsed"] >= 0 &&
  TrueQ[Lookup[r, "Resumable", False]] &&
  AssociationQ[Lookup[r, "ConstructionTimings", None]];

(* a deterministic canonical serialization: the context path must not
   decide how a private symbol prints *)
canonicalString[expr_] := Block[{$ContextPath = {"System`"},
  $Context = "Global`"}, ToString[stripTimings[expr], InputForm]];
(* Byte identity is asserted on the mathematical result, not on wall-clock
   diagnostics (measured 2026-09-02: two consecutive solves differed only in
   "InnerSolution" -> ... "LiftingSeconds" -> 0.0009 vs 0.000871).  Every
   association key naming a duration is dropped recursively. *)
timingKeyQ[key_String] := StringMatchQ[key,
  ___ ~~ ("Seconds" | "Timing" | "Timings" | "Wall" | "Elapsed") ~~ ___];
timingKeyQ[_] := False;
stripTimings[assoc_Association] :=
  Map[stripTimings, KeySelect[assoc, ! timingKeyQ[#] &]];
stripTimings[list_List] := stripTimings /@ list;
stripTimings[other_] := other;

(* ------------------------------------------------------------------ *)
(* the fixture: the chart-path strip of                                 *)
(* Tests/Multiquadratic/t_multiquadratic_transport_frame.wls                           *)
(* ------------------------------------------------------------------ *)

v = Symbol["Global`v"];
w = Symbol["Global`w"];
x = Symbol["Global`mqx"];
y = Symbol["Global`mqy"];
eps = Symbol["Global`eps"];

lambda1 = (1 - v - w)^2 - 4 v w;
lambda2 = (1 + v - w)^2 + 4 v w;
lambda3 = (1 - v + w)^2 + 4 v w;

coefficientPresentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {lambda1, lambda2, lambda3}, {v, w}, {x, y}];
check["the three-generator quadratic relations are verified",
  AssociationQ[coefficientPresentation] &&
    coefficientPresentation["Status"] ===
      "SquareRootGeneratorRelationsVerified"];

knownGauge = {{Sqrt[lambda1]}};
zeroOneForm = {ConstantArray[0, {1, 1}], ConstantArray[0, {1, 1}]};
algebraicStrip = {zeroOneForm, zeroOneForm,
  {D[knownGauge, v], D[knownGauge, w]}};
fixtureOptions = {
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICATimeLimit" -> 30, "CANONICAKernels" -> 1,
  "MapleTimeLimit" -> 60, "MapleResidueKernels" -> 1,
  "Verbose" -> False};

(* ------------------------------------------------------------------ *)
(* (b) identity at Deadline -> Infinity                                 *)
(* ------------------------------------------------------------------ *)

{baselineSeconds, baseline} = AbsoluteTiming[SolveEpsFormStripInFrame[
  algebraicStrip, {v, w}, eps, coefficientPresentation,
  Sequence @@ fixtureOptions]];
{infinitySeconds, infinityResult} = AbsoluteTiming[
  SolveEpsFormStripInFrame[
    algebraicStrip, {v, w}, eps, coefficientPresentation,
    Sequence @@ fixtureOptions, "Deadline" -> Infinity]];

check["the fixture solves without the option (the existing suite's expectation)",
  AssociationQ[baseline] && baseline["Status"] === "Solved" &&
    StringStartsQ[baseline["Method"],
      "RationalizingParametrization/Kallen1/"] &&
    TrueQ[baseline["ExactDLog"]] &&
    TrueQ[baseline["Validation"]["CoordinateComposition"]] &&
    TrueQ[baseline["Validation"]["GaugeRoundTrip"]] &&
    TrueQ[baseline["Validation"]["TransformedOneFormPullBack"]] &&
    TrueQ[baseline["Validation"]["SourceDLog"]] &&
    baseline["Validation"]["Method"] === "Exact" &&
    TrueQ[baseline["Validation"]["Passed"]]];
check["Deadline -> Infinity reproduces the fixture byte-identically",
  canonicalString[baseline] === canonicalString[infinityResult]];
check["Deadline -> Infinity adds no key to the success payload",
  AssociationQ[baseline] && AssociationQ[infinityResult] &&
    Keys[baseline] === Keys[infinityResult] &&
    ! KeyExistsQ[infinityResult, "ConstructionTimings"] &&
    ! KeyExistsQ[infinityResult, "Substage"]];

report["fixture baseline / Deadline -> Infinity seconds",
  Round[{baselineSeconds, infinitySeconds}, 0.01]];

check["a malformed deadline is a typed refusal, not a crash",
  Lookup[SolveEpsFormStripInFrame[
    algebraicStrip, {v, w}, eps, coefficientPresentation,
    Sequence @@ fixtureOptions, "Deadline" -> "soon"],
    "Status", None] === "InvalidDeadline"];

(* ------------------------------------------------------------------ *)
(* (a) an expired deadline stops before construction and reaches no     *)
(*     solver                                                           *)
(* ------------------------------------------------------------------ *)

(* Block clears Options together with the definitions, and the
   construction stage reads Options[SolveEpsFormStrip] to filter its own
   option list; the saved lists are reinstated inside the Block so the
   ONLY thing the stand-ins change is whether a call is counted. *)
savedFiniteFieldOptions = Options[FeynFacet`SolveEpsFormStripFiniteField];
savedStripOptions = Options[FeynFacet`SolveEpsFormStrip];
savedMultiquadraticOptions =
  Options[FeynFacet`Private`solveEpsFormStripMultiquadratic];
solverCalls = 0;
capturedSolverOptions = {};
SetAttributes[withSolverStandIns, HoldAll];
withSolverStandIns[body_] := Block[
  {FeynFacet`SolveEpsFormStripFiniteField, FeynFacet`SolveEpsFormStrip,
   FeynFacet`Private`solveEpsFormStripMultiquadratic},
  Options[FeynFacet`SolveEpsFormStripFiniteField] = savedFiniteFieldOptions;
  Options[FeynFacet`SolveEpsFormStrip] = savedStripOptions;
  Options[FeynFacet`Private`solveEpsFormStripMultiquadratic] =
    savedMultiquadraticOptions;
  FeynFacet`SolveEpsFormStripFiniteField[record_, options___] := (
    solverCalls++;
    capturedSolverOptions = Join[capturedSolverOptions, {options}];
    <|"Status" -> "StandIn"|>);
  FeynFacet`SolveEpsFormStrip[strip_, variables_, epsilon_, options___] := (
    solverCalls++;
    capturedSolverOptions = Join[capturedSolverOptions, {options}];
    <|"Status" -> "StandIn"|>);
  FeynFacet`Private`solveEpsFormStripMultiquadratic[record_, algebraicFrame_,
      options___] := (
    solverCalls++;
    capturedSolverOptions = Join[capturedSolverOptions, {options}];
    <|"Status" -> "StandIn"|>);
  body];

solverCalls = 0; capturedSolverOptions = {};
{expirySeconds, expired} = AbsoluteTiming[withSolverStandIns[
  SolveEpsFormStripInFrame[
    algebraicStrip, {v, w}, eps, coefficientPresentation,
    Sequence @@ fixtureOptions, "Deadline" -> AbsoluteTime[] - 1]]];

check["an expired deadline returns Status BudgetExhausted at the entry boundary",
  constructionStopQ[expired, inFrameSubstages] &&
    expired["Stage"] === "StripConstruction:Entry"];
check["the construction stop is typed, never $Aborted and never $Failed",
  expired =!= $Aborted && expired =!= $Failed && AssociationQ[expired]];
check["no solver is invoked when the deadline has already expired",
  solverCalls === 0];
check["the entry stop carries the construction identifiers",
  budgetExhaustedQ[expired] &&
    expired["Method"] ===
      "OffDiagonalBlockBasisTransformationConstruction" &&
    expired["ConstructionTimings"] === <||> &&
    expired["SquareRootGeneratorIndices"] === Missing["NotClassified"] &&
    expired["InnerStatus"] === Missing["NotSolved"] &&
    expired["RationalizingParametrizationName"] === None &&
    expired["StripDimensions"] === {1, 1} &&
    expired["Deadline"] < AbsoluteTime[]];
check["the entry stop returns in under 30 s of wall time", expirySeconds < 30];
report["entry stop", KeyTake[expired,
  {"Stage", "Substage", "Elapsed", "ConstructionTimings",
   "RationalizingParametrizationName",
   "StripDimensions", "InnerStatus"}]];

(* an input error outranks a budget stop, and still reaches no solver *)
solverCalls = 0; capturedSolverOptions = {};
malformedPresentation = withSolverStandIns[
  SolveEpsFormStripInFrame[algebraicStrip, {v, w}, eps,
    <|"Status" -> "Malformed"|>, "Deadline" -> AbsoluteTime[] - 1]];
check["a malformed coefficient presentation outranks the budget stop and reaches no solver",
  Lookup[malformedPresentation, "Status", None] ===
      "CoefficientPresentationNotWellFormed" &&
    solverCalls === 0];

(* ------------------------------------------------------------------ *)
(* (a') a LATER boundary fires, and the bracketed call's wall time is   *)
(*      recorded                                                        *)
(* ------------------------------------------------------------------ *)
(* Chart selection is made deliberately slow by a Block-scoped stand-in
   that pauses and then returns the TRUE chart, computed outside the
   Block.  The pause and the deadline are set from the MEASURED cost of
   the substages that precede chart selection, so the boundary that fires
   is determined, not raced: the run reaches chart selection at about
   classificationSeconds, well before the deadline at
   2 classificationSeconds + pause/2, and leaves it at about
   classificationSeconds + pause, well after.  Nothing is
   TimeConstrained. *)
allRootsProbe =
  FeynFacet`Private`coefficientPresentationSquareRootsInVariables[
    coefficientPresentation, {v, w}];
{classificationSeconds, classificationProbe} = AbsoluteTiming[
  FeynFacet`Private`transportChartRootIndices[algebraicStrip, allRootsProbe]];
check["the fixture's roots classify to the presentation's first generator",
  AssociationQ[classificationProbe] &&
    classificationProbe["RootIndices"] === {1}];
report["root classification seconds", Round[classificationSeconds, 0.001]];

trueChart = LookupCataloguedRationalizingParametrizationForRoots[{Together[lambda1]}, {v, w}];
check["the fixture's root set resolves to the Kallen1 chart",
  AssociationQ[trueChart] && trueChart["Name"] === "Kallen1"];

chartSelectionPause = Max[4.0, 8 classificationSeconds];
lateDeadlineOffset = 2 classificationSeconds + chartSelectionPause/2;
solverCalls = 0; capturedSolverOptions = {};
{lateSeconds, late} = AbsoluteTiming[withSolverStandIns[Block[
  {LookupCataloguedRationalizingParametrizationForRoots},
  LookupCataloguedRationalizingParametrizationForRoots[___] := (Pause[chartSelectionPause]; trueChart);
  SolveEpsFormStripInFrame[
    algebraicStrip, {v, w}, eps, coefficientPresentation,
    Sequence @@ fixtureOptions,
    "Deadline" -> AbsoluteTime[] + lateDeadlineOffset]]]];

check["a deadline reached during construction stops at a LATER boundary, not the entry gate",
  constructionStopQ[late, inFrameSubstages] && late["Substage"] =!= "Entry"];
check["the boundary that fires is the one after the slow bracketed call",
  budgetExhaustedQ[late] &&
    late["Substage"] === "ParametrizationPreparation"];
check["the bracketed call's measured wall time is recorded in the stop",
  budgetExhaustedQ[late] &&
    AssociationQ[Lookup[late, "ConstructionTimings", None]] &&
    KeyExistsQ[late["ConstructionTimings"],
      "SquareRootGeneratorClassification"] &&
    KeyExistsQ[late["ConstructionTimings"],
      "ParametrizationSelection"] &&
    late["ConstructionTimings"]["ParametrizationSelection"] >=
      chartSelectionPause &&
    ! KeyExistsQ[late["ConstructionTimings"],
      "ParametrizationPullBack"] &&
    ! KeyExistsQ[late["ConstructionTimings"], "InnerSolve"]];
check["the late stop reaches no solver either", solverCalls === 0];
check["the late stop identifies the chart it had selected",
  budgetExhaustedQ[late] &&
    late["RationalizingParametrizationName"] === "Kallen1" &&
    late["SquareRootGeneratorIndices"] === {1}];
check["the late stop returns promptly after its deadline",
  lateSeconds < chartSelectionPause + 30];
report["late stop", KeyTake[late,
  {"Stage", "Substage", "Elapsed", "ConstructionTimings",
   "RationalizingParametrizationName"}]];
report["late stop wall seconds", Round[lateSeconds, 0.01]];

(* ------------------------------------------------------------------ *)
(* (a''') the ACCEPTANCE zero tests are preemptible PER ENTRY           *)
(* ------------------------------------------------------------------ *)
(* Until 2026-08-25 the acceptance stages normalized the WHOLE matrix
   (Map[Together, matrix, {2}]) and only then tested entries, so a
   deadline could not be read until the normalization finished: CF259
   sector 24 sat more than 23 minutes inside this stage with no way to
   stop it.  The test now runs entry by entry, reads the deadline BETWEEN
   entries, and stops typed.

   Determined, not raced, and independent of how long any entry happens
   to take: the deadline PREDICATE itself is replaced by a counting
   stand-in.  Phase 1 counts how many times a successful run reads the
   deadline; phase 2 makes the LAST of those reads report expiry.  If the
   deadline were still read only at stage boundaries, that last read
   would be a boundary and the stop would carry no entry; the assertions
   below require it to carry one, which is exactly the per-entry claim.
   Nothing is TimeConstrained and no wall clock decides anything. *)
deadlineReads = 0;
SetAttributes[withCountingDeadline, HoldRest];
withCountingDeadline[expireAt_, body_] := Block[
  {FeynFacet`Private`transportChartDeadlineExpiredQ},
  (* expireAt = 0 means "never expire": it is the counting phase *)
  FeynFacet`Private`transportChartDeadlineExpiredQ[d_] := (
    deadlineReads++;
    NumericQ[d] && IntegerQ[expireAt] && expireAt > 0 &&
      deadlineReads >= expireAt);
  body];

deadlineReads = 0;
countingBaseline = withCountingDeadline[0,
  SolveEpsFormStripInFrame[
    algebraicStrip, {v, w}, eps, coefficientPresentation,
    Sequence @@ fixtureOptions, "Deadline" -> AbsoluteTime[] + 3600]];
totalDeadlineReads = deadlineReads;
check["the counting stand-in does not disturb the successful fixture",
  AssociationQ[countingBaseline] &&
    countingBaseline["Status"] === "Solved" && totalDeadlineReads > 0];
report["deadline reads in a successful in-frame construction",
  totalDeadlineReads];

deadlineReads = 0;
solverCalls = 0; capturedSolverOptions = {};
{acceptanceSeconds, acceptanceStop} = AbsoluteTiming[
  withCountingDeadline[totalDeadlineReads,
    SolveEpsFormStripInFrame[
      algebraicStrip, {v, w}, eps, coefficientPresentation,
      Sequence @@ fixtureOptions, "Deadline" -> AbsoluteTime[] + 3600]]];

check["a deadline reached inside an acceptance zero test stops typed",
  constructionStopQ[acceptanceStop, inFrameSubstages]];
check["the acceptance stop names an acceptance substage, not the entry gate",
  budgetExhaustedQ[acceptanceStop] &&
    MemberQ[{"GaugePullBack", "SourceRepresentationIdentity"},
      acceptanceStop["Substage"]]];
check["the LAST deadline read of a construction is inside a zero test, \
i.e. the test is preemptible per entry and not only per stage",
  budgetExhaustedQ[acceptanceStop] &&
    StringQ[Lookup[acceptanceStop, "ZeroTestSubstage", None]] &&
    IntegerQ[Lookup[acceptanceStop, "Entry", None]] &&
    IntegerQ[Lookup[acceptanceStop, "Of", None]] &&
    acceptanceStop["Entry"] >= 1 &&
    acceptanceStop["Entry"] <= acceptanceStop["Of"]];
report["acceptance stop", KeyTake[acceptanceStop,
  {"Stage", "Substage", "ZeroTestSubstage", "Entry", "Of", "Elapsed"}]];
report["acceptance stop wall seconds", Round[acceptanceSeconds, 0.01]];

(* ------------------------------------------------------------------ *)
(* (a'') the deadline reaches the solver through the option plumbing    *)
(* ------------------------------------------------------------------ *)
(* a RATIONAL strip: no radicals, so the construction goes straight to
   the solver dispatch and the finite-field stand-in records what it was
   given *)
rationalGauge = {{v}};
rationalStrip = {zeroOneForm, zeroOneForm,
  {D[rationalGauge, v], D[rationalGauge, w]}};
handedDeadline = AbsoluteTime[] + 3600;
solverCalls = 0; capturedSolverOptions = {};
handed = withSolverStandIns[
  SolveEpsFormStripInFrame[
    rationalStrip, {v, w}, eps, coefficientPresentation,
    "FiniteFieldFirst" -> True, "Verbose" -> False,
    "Deadline" -> handedDeadline]];
check["a rational strip reaches the solver and the solver gets the deadline",
  solverCalls === 1 &&
    Lookup[Association[capturedSolverOptions], "Deadline", None] ===
      handedDeadline];

explicitDeadline = AbsoluteTime[] + 12345;
solverCalls = 0; capturedSolverOptions = {};
handedExplicit = withSolverStandIns[
  SolveEpsFormStripInFrame[
    rationalStrip, {v, w}, eps, coefficientPresentation,
    "FiniteFieldFirst" -> True, "Verbose" -> False,
    "FiniteFieldOptions" -> {"Deadline" -> explicitDeadline},
    "Deadline" -> handedDeadline]];
check["an explicit FiniteFieldOptions deadline still wins over the inherited one",
  solverCalls === 1 &&
    Lookup[Association[capturedSolverOptions], "Deadline", None] ===
      explicitDeadline];
report["deadlines handed to the solver",
  {handedDeadline, explicitDeadline}];

(* ------------------------------------------------------------------ *)
(* (c) propagation through the driver's StripBudgetExhausted handling   *)
(* ------------------------------------------------------------------ *)

driverPath = FileNameJoin[{root, "Scripts", "family_epsform_sector.wls"}];
driverSource = Import[driverPath, "Text"];
check["the sector driver source is readable", StringQ[driverSource]];

extractSpan[source_String, head_String, terminator_String] :=
  Module[{heads = StringPosition[source, head], from, to},
    If[heads === {}, Return[$Failed]];
    from = heads[[1, 1]];
    to = SelectFirst[StringPosition[source, terminator], #[[1]] > from &,
      None];
    If[to === None, $Failed, StringTake[source, {from, to[[2]]}]]];

stopHeader = "state[\"Stop\"] = <|\"Status\" -> \"StripBudgetExhausted\"";
stopTail = "\"StripCheckpointFile\" -> stripCheckpointFile|>";
check["the driver has EXACTLY ONE StripBudgetExhausted stop record (no parallel path)",
  StringCount[driverSource, stopHeader] === 1];
stopText = extractSpan[driverSource, stopHeader, stopTail];
check["the driver's stop record extracts as one expression",
  StringQ[stopText] && StringLength[stopText] > 0];

deadlinePredicateText = extractSpan[driverSource,
  "stripDeadlineExpiredQ[d_] :=", "AbsoluteTime[] >= d;"];
constructionStopText = extractSpan[driverSource,
  "stripConstructionStop[substage_String,",
  "\"ConstructionTimings\" -> stageTimings|>;"];
check["the driver's construction-stage helpers extract as expressions",
  StringQ[deadlinePredicateText] && StringQ[constructionStopText]];

(* Evaluate the extracted driver text on the REAL construction stops
   produced above.  The record built here is the driver's own source
   text, not a copy of it. *)
driverStopRecord[solutionValue_] := If[! StringQ[stopText], $Failed,
  Block[
    {Global`state = <||>, Global`k = 12, Global`nlow = 9,
     Global`sectorBudget = 7200,
     Global`stripCheckpointFile = "/nonexistent/CF300_12_strip_state.wl",
     Global`solution = solutionValue},
    ToExpression[stopText];
    Global`state["Stop"]]];

packageStopRecord = driverStopRecord[expired];
lateStopRecord = driverStopRecord[late];

check["the package construction stop becomes a StripBudgetExhausted state record",
  AssociationQ[packageStopRecord] &&
    packageStopRecord["Status"] === "StripBudgetExhausted" &&
    packageStopRecord["Strip"] === {12, 9} &&
    packageStopRecord["Stage"] === "StripConstruction:Entry" &&
    packageStopRecord["SectorBudget"] === 7200 &&
    packageStopRecord["Method"] ===
      "OffDiagonalBlockBasisTransformationConstruction" &&
    TrueQ[packageStopRecord["Resumable"]] &&
    NumericQ[packageStopRecord["Elapsed"]] &&
    packageStopRecord["StripCheckpointFile"] ===
      "/nonexistent/CF300_12_strip_state.wl"];
check["the state record's Progress carries the construction evidence",
  AssociationQ[packageStopRecord] &&
    AssociationQ[packageStopRecord["Progress"]] &&
    packageStopRecord["Progress"]["Substage"] === "Entry" &&
    KeyExistsQ[packageStopRecord["Progress"], "ConstructionTimings"] &&
    KeyExistsQ[packageStopRecord["Progress"], "StripDimensions"]];
check["a later-boundary stop records its substage wall times in the state record",
  AssociationQ[lateStopRecord] &&
    lateStopRecord["Status"] === "StripBudgetExhausted" &&
    lateStopRecord["Stage"] ===
      "StripConstruction:ParametrizationPreparation" &&
    lateStopRecord["Progress", "ConstructionTimings",
      "ParametrizationSelection"] >=
      chartSelectionPause];
report["driver state Stop record (entry)", packageStopRecord];

(* the driver's own construction stop, built by its own extracted
   definition, has the same shape and feeds the same record *)
driverOwnStop = If[
  ! (StringQ[deadlinePredicateText] && StringQ[constructionStopText]),
  $Failed,
  Block[{Global`sectorDeadline = AbsoluteTime[] - 1},
    ToExpression[deadlinePredicateText];
    ToExpression[constructionStopText];
    Global`stripConstructionStop["EquationConstructed",
      AbsoluteTime[] - 12.5, {12, 9}, <|"NextEquationD" -> 12.4|>]]];
check["the driver's own construction stop has the solver stop's shape",
  constructionStopQ[driverOwnStop, driverSubstages] &&
    driverOwnStop["Stage"] === "StripConstruction:EquationConstructed" &&
    driverOwnStop["Method"] === "StripConstructionDriver" &&
    driverOwnStop["ConstructionTimings"]["NextEquationD"] === 12.4 &&
    driverOwnStop["Elapsed"] >= 12.4];
check["the driver's expiry predicate is a no-op at an unbounded deadline",
  StringQ[deadlinePredicateText] &&
    ! TrueQ[Global`stripDeadlineExpiredQ[Infinity]] &&
    TrueQ[Global`stripDeadlineExpiredQ[AbsoluteTime[] - 1]]];

driverOwnStopRecord = driverStopRecord[driverOwnStop];
check["the driver's own construction stop becomes the same state record",
  AssociationQ[driverOwnStopRecord] &&
    driverOwnStopRecord["Status"] === "StripBudgetExhausted" &&
    driverOwnStopRecord["Stage"] ===
      "StripConstruction:EquationConstructed" &&
    driverOwnStopRecord["Progress"]["ConstructionTimings"] ===
      <|"NextEquationD" -> 12.4|> &&
    TrueQ[driverOwnStopRecord["Resumable"]]];

(* structural guards: no solve route may run after a construction stop,
   and the in-frame call site must carry the sector deadline.  Since
   2026-09-02 (round 2) the driver has ONE strip-solve dispatch: the
   Legacy CANONICA/Maple dispatch was removed with its route. *)
check["the driver's strip-solve dispatch is guarded by the budget stop and no legacy dispatch remains",
  StringCount[driverSource,
      "blockwiseRouteQ && ! stripBudgetExhaustedQ[solution]"] === 1 &&
    StringCount[driverSource,
      "! blockwiseRouteQ && ! stripBudgetExhaustedQ[solution]"] === 0];

normalizeSource[s_String] := StringReplace[s, {
  RegularExpression["(?s)\\(\\*.*?\\*\\)"] -> "",
  RegularExpression["\\s+"] -> " "}];
inFrameChunks = Rest[StringSplit[driverSource,
  "FeynFacet`SolveEpsFormStripInFrame["]];
check["every driver SolveEpsFormStripInFrame call site carries the sector deadline",
  Length[inFrameChunks] === 1 &&
    AllTrue[inFrameChunks, Function[chunk,
      Module[{normalized = normalizeSource[
          StringTake[chunk, UpTo[4000]]]},
        StringContainsQ[normalized,
          "\"Deadline\" -> sectorDeadline"] &&
          StringContainsQ[normalized,
            "\"ScratchDirectory\" -> scratch"]]]]];
check["the driver checks the construction deadline at every declared substage",
  And @@ (StringContainsQ[driverSource,
    "constructionCheck[\"" <> # <> "\"]"] & /@ driverSubstages)];
check["the construction stage is never TimeConstrained",
  ! StringContainsQ[driverSource, "TimeConstrained[canonicaNextEq"] &&
    ! StringContainsQ[driverSource, "TimeConstrained[blockEquation"] &&
    ! StringContainsQ[
      Import[FeynFacet`Private`feynFacetPrivateFile["EpsFormStripInFrame.wl"],
        "Text"],
      "TimeConstrained[transportChartPullBackStrip"]];

Print["t_construction_budget: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
