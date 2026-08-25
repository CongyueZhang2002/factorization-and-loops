#!/usr/bin/env wolframscript
(* Adaptive task-broker engagement in the finite-field strip solver
   (2026-08-24).

   THE DEFECT.  SolveEpsFormStripFiniteField decided ONCE per block
   whether to farm the per-prime sample batches to the KernelPool
   helpers, from the PILOT: one sample's build time times the regulator
   schedule.  The pilot measures the build only, and the build is not
   where a hard block spends its time.  Measured in production on family
   CF303, off-diagonal block (17, 13): the pilot estimate was about 0.6 s
   per prime, so farming was declined, while a prime actually cost about
   ten minutes (tall rational coefficients: five primes and a heavy
   modular solve per regulator value).  One kernel ground for an hour
   while six pool helpers idled -- an estimator wrong by three orders of
   magnitude, because it does not measure the dominant cost.

   THE CHANGE.  The pilot estimate is now only the FIRST decision.  The
   first prime the solver actually computes is timed end to end --
   sampling (build plus modular elimination), canonicalization, held-out
   interpolation and its validation, and the artifact write, which is
   exactly the work a helper can take -- and if that MEASURED time
   clears "BrokerMinimumSeconds" while the pool is serving and farming is
   off, farming is engaged for the remaining primes.  The farming path
   itself is untouched (taskBrokerSampleBatch); only the on/off decision
   point moved.  The option default may be moved once per kernel session
   by FACET_BROKER_MINIMUM_SECONDS.

   ACCEPTANCE CRITERIA, stated before the run.

   (a) REGRESSION.  With the broker inactive, the synthetic fixture
       returns what the HEAD solver returned for it: every key HEAD
       produced is present with an identical value (the measured-seconds
       keys excepted, which differ by construction), no key is lost, and
       the only added keys are the six broker-record keys.  The recorded
       HEAD values below were measured on 2026-08-24 from
       git HEAD 1833bf4's FiniteFieldStripSolve.wl, loaded over the
       working tree in one kernel session, same fixture, same options.

   (b) RE-DECISION.  On the GAP fixture -- the same block sampled the way
       the defect looks in production, so that the pilot estimate
       underruns the first prime's real cost -- with the broker active
       and a minimum set STRICTLY BETWEEN the pilot estimate and the
       first prime's measured time (the geometric mean of the two, both
       read from a preceding run of the same fixture at an unreachable
       minimum),
       the solver declines farming at the pilot and engages it after the
       first prime: it logs one line "Broker re-decision after prime
       <p>: measured <t> s per prime -> engaging helpers", returns
       "BrokerReDecision" naming that prime and that measurement, ends
       with "BrokerActive" -> True, and the solution is still exact --
       ExactPfaffianResidualsZero and DLogFormCertified -- with the same
       payload as the run that never farmed.  The farming path is really
       entered (the broker's data files appear).  With a tiny minimum
       (0.001 s) farming is on for the whole solve and the payload is
       still identical.

   (c) BUDGET FIRST.  An expired deadline still returns the typed
       BudgetExhausted association with the broker active, and that
       association reports the broker state it stopped in.

   (d) ARTIFACTS AND RESUME.  The per-prime artifact layout is unchanged
       (one <prefix>_mod_<prime>.wl per prime), and a resumed solve that
       reloads every prime measures nothing and re-decides nothing.

   (e) ENVIRONMENT OVERRIDE.  FACET_BROKER_MINIMUM_SECONDS parses as a
       nonnegative decimal number, is read once per session, moves the
       option DEFAULT (never an explicit option), and a malformed value
       is ignored in favour of the built-in 8.0.

   THE LIVE POOL IS NEVER TOUCHED.  The test builds its own pool
   directory in a temporary location and pins the helper ceiling to 0, so
   taskBrokerSampleBatch takes its documented local path: the farming
   decision and the farming entry point are exercised, no task is ever
   queued, and no helper kernel is ever asked for. *)

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
(* the broker environment is neutralized BEFORE FeynFacet loads: nothing
   in this test may reach a real KernelPool queue, and the option default
   must bind the built-in 8.0 *)
oldBroker = Environment["FACET_TASK_BROKER"];
oldLimit = Environment["FACET_TASK_BROKER_MAX_HELPERS"];
oldMinimum = Environment["FACET_BROKER_MINIMUM_SECONDS"];
SetEnvironment["FACET_TASK_BROKER" -> ""];
SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "0"];
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> ""];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];

solve = FeynFacet`SolveEpsFormStripFiniteField;
brokerActiveQ = FeynFacet`Private`taskBrokerActiveQ;
parseMinimum = FeynFacet`Private`finiteFieldStripBrokerMinimumSecondsParse;
resolveMinimum = FeynFacet`Private`finiteFieldStripBrokerMinimumSeconds;

(* ------------------------------------------------------------------ *)
(* The fixture: the synthetic 1x1 strip of                             *)
(* Tests/t_finite_field_strip_solve.wls, on three primes so that a     *)
(* re-decision after the first prime has later primes to act on        *)
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
fixturePrimes = {1000003, 1000033, 1000037};
fixtureOptions = {
  "Primes" -> fixturePrimes,
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}},
  "PointCount" -> 8,
  "KernelCount" -> 1,
  "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4,
  "MinimumPrimeCount" -> 3,
  "Verbose" -> False};
(* THE GAP FIXTURE: the same block, sampled the way the defect looks in
   production.  The pilot estimate is one sample's build times the length
   of the regulator SCHEDULE (here 1); the prime really samples the
   held-out construction prefix plus the held-out round (here 20 values),
   so the estimate underruns the truth by an order of magnitude -- the
   production case underran it by three.  A rule given before the fixture
   list wins, so these three replace their counterparts. *)
gapOptions = Join[{
  "EpsilonSamples" -> {1/21},
  "InitialConstructionCount" -> 60,
  "HeldOutCount" -> 20},
  fixtureOptions];
(* the block's mathematics, which no sampling schedule may change *)
mathKeys = {"Status", "Method", "Gauge", "Alphabet", "ResidueMatrices",
  "GaugeDenominator", "GaugeDenominatorDegrees", "GaugeNumeratorDegrees",
  "GaugeSupport", "GaugeSupportCount", "NormalizationColumns", "Primes",
  "CombinedModulus", "LettersEpsFree", "ResiduesKinematicsFree",
  "ResiduesEpsFree", "ExactPfaffianResidualsZero",
  "ExactPfaffianIdentitiesZero", "ConstantResidues", "DLogFormCertified",
  "CanonicalEpsFormCertified", "ExactDLog", "SelectedNumeratorDegreeOffset",
  "SelectedSupportShell", "ModularPrimeCount", "UnseenPrime"};
mathPayload[r_] := If[AssociationQ[r], KeyTake[r, mathKeys], r];

(* keys whose values are measured wall times and differ between runs by
   construction; everything else is payload *)
secondsKeys = {"PrimeSamplingSeconds", "PrimeInterpolationSeconds",
  "TotalSamplingSeconds", "TotalInterpolationSeconds", "ExactCheckSeconds",
  "LiftingSeconds", "PrimeWallSeconds", "BrokerPilotSeconds",
  "BrokerEstimatedPrimeSeconds"};
brokerKeys = {"BrokerActive", "BrokerMinimumSeconds", "BrokerPilotSeconds",
  "BrokerEstimatedPrimeSeconds", "BrokerReDecision", "PrimeWallSeconds"};
payload[r_] := If[AssociationQ[r], KeyDrop[r, Join[secondsKeys, brokerKeys]], r];

(* the fake pool: alive (its pid is this process), four helpers
   advertised, ceiling 0 so no task is ever queued *)
poolDirectory = CreateDirectory[];
CreateDirectory[FileNameJoin[{poolDirectory, "queue"}]];
Export[FileNameJoin[{poolDirectory, "status.txt"}],
  "KernelPool status (t_broker_adaptive)\nsubkernels: 8  busy: 4  free: 4\n", "Text"];
Export[FileNameJoin[{poolDirectory, "pool.pid"}], ToString[$ProcessID], "Text"];
brokerOn[] := (SetEnvironment["FACET_TASK_BROKER" -> poolDirectory];
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> "0"]);
brokerOff[] := SetEnvironment["FACET_TASK_BROKER" -> ""];
brokerDataFiles[] := FileNames["*.wl", FileNameJoin[{poolDirectory, "data"}]];
queuedFiles[] := FileNames["*", FileNameJoin[{poolDirectory, "queue"}]];

(* ------------------------------------------------------------------ *)
(* (a) REGRESSION against the recorded HEAD behaviour                   *)
(* ------------------------------------------------------------------ *)

brokerOff[];
check["the task broker is inactive for the regression run", ! TrueQ[brokerActiveQ[]]];
{inactiveSeconds, inactive} = AbsoluteTiming[solve[syntheticRecord, Sequence @@ fixtureOptions]];

(* RECORDED FROM HEAD 1833bf4 ON 2026-08-24 (see the header) *)
headKeys = {"Status", "Method", "Gauge", "Alphabet", "ResidueMatrices", "Primes", 
 "CombinedModulus", "NormalizationColumns", "GaugeDenominator", 
 "GaugeDenominatorDegrees", "GaugeNumeratorDegrees", "GaugeSupport", 
 "GaugeSupportCount", "CoefficientLiftChecks", "LiftingSeconds", 
 "CertificationMode", "LettersEpsFree", "ResiduesKinematicsFree", 
 "ResiduesEpsFree", "ExactPfaffianResidualsZero", 
 "ExactPfaffianIdentitiesZero", "ConstantResidues", "DLogFormCertified", 
 "CanonicalEpsFormCertified", "CheckMethod", "StructuralFailureReasons", 
 "ExactCheckSeconds", "EquationCount", "ExactDLog", "EliminationPlan", 
 "EliminationPlanFingerprint", "BackendRequested", "BackendThreads", 
 "BackendConfiguration", "BackendsUsed", "PlanDiscoveryBackendRequested", 
 "PlanDiscoveryBackendUsed", "SelectedNumeratorDegreeOffset", 
 "SelectedSupportShell", "SupportStrategy", "ProbeCount", "DegreeProbe", 
 "SelectedSupportKind", "ModularPrimeCount", "MaximumPrimeCount", 
 "AdaptivePrimeSampling", "RegulatorSampling", "UnseenPrimeCheck", 
 "UnseenPrime", "PrimeSampleCounts", "PrimeConstructionCounts", 
 "PrimeMaximumTotalDegrees", "PrimeSamplingSeconds", 
 "PrimeInterpolationSeconds", "TotalSamplingSeconds", 
 "TotalInterpolationSeconds"};

headPayload = <|"Status" -> "Solved", "Method" -> "SimultaneousFiniteFieldAffinePDE", 
 "Gauge" -> {{xSynthetic}}, "Alphabet" -> {xSynthetic, ySynthetic}, 
 "ResidueMatrices" -> {{{0}}, {{0}}}, 
 "Primes" -> {1000003, 1000033, 1000037}, 
 "CombinedModulus" -> 1000073001431003663, "NormalizationColumns" -> {}, 
 "GaugeDenominator" -> 1, "GaugeDenominatorDegrees" -> {0, 0}, 
 "GaugeNumeratorDegrees" -> {1, 0}, "GaugeSupport" -> {{0, 0}, {1, 0}}, 
 "GaugeSupportCount" -> 2, "CoefficientLiftChecks" -> 
  {True, True, True, True}, "CertificationMode" -> "HeldOut", 
 "LettersEpsFree" -> True, "ResiduesKinematicsFree" -> True, 
 "ResiduesEpsFree" -> True, "ExactPfaffianResidualsZero" -> True, 
 "ExactPfaffianIdentitiesZero" -> True, "ConstantResidues" -> True, 
 "DLogFormCertified" -> True, "CanonicalEpsFormCertified" -> True, 
 "CheckMethod" -> "Exact", "StructuralFailureReasons" -> {}, 
 "EquationCount" -> 2, "ExactDLog" -> True, 
 "EliminationPlan" -> <|"Status" -> "OK", "NormalizationColumns" -> {}, 
   "IndependentEquationRows" -> {11, 13, 15, 16}, "GenericRank" -> 4, 
   "Nullity" -> 0, "UnknownCount" -> 4, "GaugeUnknownCount" -> 2, 
   "FreeResidueCount" -> 2, "GaugeNumeratorDegrees" -> {1, 0}, 
   "GaugeDenominatorDegrees" -> {0, 0}, "PilotPrime" -> 1000003, 
   "GaugeSupport" -> {{0, 0}, {1, 0}}, "PlanSchema" -> 
    "FeynFacetFiniteFieldStripEliminationPlan", "PlanSchemaVersion" -> 1, 
   "PreparationFingerprint" -> 
    "a4d8520061e391d827165d2a9bd4debcab0035dde6ad33ed41ca41889af25e09", 
   "SolverProvenance" -> <|"Discoverer" -> "WolframMatrixRankNullSpace", 
     "IndependentRows" -> "WolframLeftNullspacePivots", 
     "PlanDiscoveryBackend" -> "Wolfram", "Implementation" -> 
      "FiniteFieldStripSolve", "ImplementationVersion" -> 1|>, 
   "PlanDiscoveryBackendRequested" -> "Wolfram", 
   "PlanDiscoveryBackendUsed" -> "Wolfram", "PlanFingerprint" -> 
    "7b922293cecd60f96be34de73ca8bbdde794d34ba316b11aad85eb2c2fab4081"|>, 
 "EliminationPlanFingerprint" -> 
  "7b922293cecd60f96be34de73ca8bbdde794d34ba316b11aad85eb2c2fab4081", 
 "BackendRequested" -> Automatic, "BackendThreads" -> 2, 
 "BackendConfiguration" -> 
  <|"Schema" -> "FeynFacetFiniteFieldFixedCoreBackendConfiguration", 
   "SchemaVersion" -> 1, "Contract" -> "FixedConstrainedCore", 
   "BackendProtocol" -> "CFFA4V1/CFFA4X1OrWolfram", 
   "BackendRequested" -> Automatic, "BackendThreads" -> 2, 
   "FiniteFieldStripSolveSHA256" -> 
    "8b28be1fc297ad7d1b9b6e736bfa7047053f5e08d381d9d7603eb9b8461caa18", 
   "FLINTBinarySHA256" -> 
    "e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b", 
   "Fingerprint" -> 
    "959e5ac447d985128989e3ce8237225267a1c94e540182c7518a9538663b6a7e"|>, 
 "BackendsUsed" -> {"Wolfram"}, "PlanDiscoveryBackendRequested" -> 
  "Wolfram", "PlanDiscoveryBackendUsed" -> "Wolfram", 
 "SelectedNumeratorDegreeOffset" -> {1, 0}, 
 "SelectedSupportShell" -> "Rectangle", "SupportStrategy" -> 
  "SimplexFirst", "ProbeCount" -> 2, "DegreeProbe" -> 
  <|"GaugeSupportCount" -> 2, "GaugeUnknownCount" -> 2, 
   "FreeResidueCount" -> 2, "Rank" -> 4, "SupportMaximumDegrees" -> 
    {1, 0}|>, "SelectedSupportKind" -> "Rectangle", 
 "ModularPrimeCount" -> 3, "MaximumPrimeCount" -> 40, 
 "AdaptivePrimeSampling" -> True, "RegulatorSampling" -> "HeldOut", 
 "UnseenPrimeCheck" -> True, "UnseenPrime" -> 2147483399, 
 "PrimeSampleCounts" -> {7, 4, 4}, "PrimeConstructionCounts" -> 
  {4, 1, 1}, "PrimeMaximumTotalDegrees" -> {4, 4, 4}|>;

check["the fixture solves with the broker inactive",
  AssociationQ[inactive] && inactive["Status"] === "Solved" &&
    TrueQ[inactive["ExactPfaffianResidualsZero"]] &&
    TrueQ[inactive["DLogFormCertified"]]];
check["no key HEAD returned is lost",
  AssociationQ[inactive] && Complement[headKeys, Keys[inactive]] === {}];
check["the only added keys are the six broker-record keys",
  AssociationQ[inactive] &&
    Sort[Complement[Keys[inactive], headKeys]] === Sort[brokerKeys]];
check["every HEAD payload value is reproduced exactly",
  payload[inactive] === headPayload];
check["the broker record of an inactive-broker solve is off and empty",
  AssociationQ[inactive] && inactive["BrokerActive"] === False &&
    inactive["BrokerReDecision"] === None &&
    inactive["BrokerMinimumSeconds"] === 8.0];
check["the per-prime wall times are measured for every computed prime",
  AssociationQ[inactive] &&
    Length[inactive["PrimeWallSeconds"]] === inactive["ModularPrimeCount"] &&
    AllTrue[inactive["PrimeWallSeconds"], NumericQ[#] && # > 0 &]];
report["inactive-broker solve seconds", Round[inactiveSeconds, 0.01]];
report["per-prime measured seconds", Round[inactive["PrimeWallSeconds"], 0.01]];
report["pilot estimate for one prime", Round[inactive["BrokerEstimatedPrimeSeconds"], 0.01]];

(* ------------------------------------------------------------------ *)
(* (b) THE RE-DECISION                                                  *)
(* ------------------------------------------------------------------ *)

(* the gap fixture with a minimum no run can reach: nothing farms, and
   the two quantities the defect is about are both recorded *)
{gapSeconds, gapBaseline} = AbsoluteTiming[
  solve[syntheticRecord, "BrokerMinimumSeconds" -> 10^6,
    Sequence @@ gapOptions]];
check["the gap fixture reproduces the HEAD mathematics of the block",
  mathPayload[gapBaseline] === mathPayload[headPayload]];
check["the gap fixture farms nothing at an unreachable minimum",
  AssociationQ[gapBaseline] && gapBaseline["BrokerActive"] === False &&
    gapBaseline["BrokerReDecision"] === None];

estimated = gapBaseline["BrokerEstimatedPrimeSeconds"];
measured = First[gapBaseline["PrimeWallSeconds"]];
check["the fixture reproduces the estimator gap (pilot estimate below the measured prime)",
  NumericQ[estimated] && NumericQ[measured] && estimated < measured];
report["estimate vs measurement (s)", Round[{estimated, measured}, 0.0001]];
report["ratio measured/estimated", Round[measured/Max[estimated, 10^-6], 0.1]];
report["gap fixture seconds", Round[gapSeconds, 0.01]];

(* a minimum strictly between them.  Half the measurement, not the
   geometric mean: the pilot is a few milliseconds and its NOISE is also
   milliseconds, so the minimum is kept far above it and still a factor
   two below the measured prime.  HEAD would decline farming for the
   whole block; the re-decision engages it after the first prime. *)
between = measured/2;
check["the calibrated minimum lies strictly between the estimate and the measurement",
  NumericQ[between] && estimated < between < measured];
report["calibrated minimum (s)", Round[between, 0.001]];
brokerOn[];
check["the task broker is active for the re-decision run", TrueQ[brokerActiveQ[]]];
check["no helper is offered, so no task can be queued",
  FeynFacet`Private`taskBrokerFreeKernels[] === 0];
logFile = FileNameJoin[{poolDirectory, "redecision.log"}];
(* OutputForm and an unbounded page width: a file stream would otherwise
   quote every string and wrap the line, and the assertion is about the
   line an operator reads in a mission log *)
logStream = OpenWrite[logFile, FormatType -> OutputForm, PageWidth -> Infinity];
(* an option given BEFORE the fixture list wins: OptionValue takes the
   first rule for a name *)
{betweenSeconds, betweenResult} = AbsoluteTiming[Block[{$Output = {logStream}},
  solve[syntheticRecord, "Verbose" -> True,
    "BrokerMinimumSeconds" -> between, Sequence @@ gapOptions]]];
Close[logStream];
logText = Import[logFile, "Text"];

check["the pilot of the re-decision run declined farming",
  AssociationQ[betweenResult] &&
    NumericQ[betweenResult["BrokerEstimatedPrimeSeconds"]] &&
    betweenResult["BrokerEstimatedPrimeSeconds"] < between];
check["the measurement engaged farming after the first prime",
  AssociationQ[betweenResult] && betweenResult["BrokerActive"] === True &&
    AssociationQ[betweenResult["BrokerReDecision"]]];
report["re-decision run: pilot estimate, minimum, first prime (s)",
  Round[{Lookup[betweenResult, "BrokerEstimatedPrimeSeconds", None], between,
    First[Lookup[betweenResult, "PrimeWallSeconds", {}], None]}, 0.0001]];
check["the re-decision names the first prime and its measured time",
  AssociationQ[betweenResult] &&
    AssociationQ[betweenResult["BrokerReDecision"]] &&
    betweenResult["BrokerReDecision"]["Prime"] === First[fixturePrimes] &&
    betweenResult["BrokerReDecision"]["PrimesCompleted"] === 1 &&
    TrueQ[betweenResult["BrokerReDecision"]["Engaged"]] &&
    NumericQ[betweenResult["BrokerReDecision"]["MeasuredSeconds"]] &&
    betweenResult["BrokerReDecision"]["MeasuredSeconds"] >= between &&
    betweenResult["BrokerReDecision"]["MinimumSeconds"] === between];
check["the re-decision logs exactly one line, in the declared wording",
  StringQ[logText] &&
    Length[StringCases[logText, "Broker re-decision after prime " ~~ Except["\n"] ..]] === 1 &&
    StringContainsQ[logText, "-> engaging helpers"] &&
    StringContainsQ[logText,
      "Broker re-decision after prime " <>
        ToString[betweenResult["BrokerReDecision"]["Prime"]] <> ": measured "]];
check["the farmed run is still exact and validated",
  AssociationQ[betweenResult] && betweenResult["Status"] === "Solved" &&
    TrueQ[betweenResult["ExactPfaffianResidualsZero"]] &&
    TrueQ[betweenResult["DLogFormCertified"]] &&
    TrueQ[betweenResult["LettersEpsFree"]] &&
    TrueQ[betweenResult["ResiduesKinematicsFree"]]];
check["engaging the helpers changes no mathematics",
  mathPayload[betweenResult] === mathPayload[headPayload]];
check["the remaining primes really went through the farming path",
  brokerDataFiles[] =!= {} &&
    AnyTrue[brokerDataFiles[], StringContainsQ[FileNameTake[#], "record_"] &] &&
    AnyTrue[brokerDataFiles[], StringContainsQ[FileNameTake[#], "opts_"] &]];
check["no task was queued to any pool",
  queuedFiles[] === {}];
report["re-decision", betweenResult["BrokerReDecision"]];
report["re-decision run seconds", Round[betweenSeconds, 0.01]];
report["re-decision log line", First[StringCases[logText,
  "Broker re-decision after prime " ~~ Except["\n"] .., 1], "none"]];

(* the instruction's tiny threshold: farming is on for the whole solve *)
{tinySeconds, tinyResult} = AbsoluteTiming[
  solve[syntheticRecord, Sequence @@ fixtureOptions,
    "BrokerMinimumSeconds" -> 0.001]];
check["a 0.001 s minimum farms and still returns the exact payload",
  AssociationQ[tinyResult] && tinyResult["BrokerActive"] === True &&
    TrueQ[tinyResult["ExactPfaffianResidualsZero"]] &&
    TrueQ[tinyResult["DLogFormCertified"]] &&
    payload[tinyResult] === headPayload];
report["0.001 s minimum: engaged at the pilot (no re-decision needed)",
  tinyResult["BrokerReDecision"] === None];
report["0.001 s minimum seconds", Round[tinySeconds, 0.01]];

(* an active broker at the production default (8.0 s): the decision now
   follows the MEASURED prime, so a fixture this cheap keeps farming off
   -- and if this machine were slow enough to spend 8 s on one prime,
   engaging would be the correct answer.  Either way the payload stands. *)
{quietSeconds, quietResult} = AbsoluteTiming[
  solve[syntheticRecord, Sequence @@ fixtureOptions]];
check["at the default minimum the decision follows the measured prime",
  AssociationQ[quietResult] && payload[quietResult] === headPayload &&
    If[First[quietResult["PrimeWallSeconds"], 0.] >= 8.0,
      AssociationQ[quietResult["BrokerReDecision"]],
      quietResult["BrokerActive"] === False &&
        quietResult["BrokerReDecision"] === None]];
report["active broker, default minimum: seconds, first prime, re-decision",
  {Round[quietSeconds, 0.01], Round[First[quietResult["PrimeWallSeconds"], 0.], 0.01],
    quietResult["BrokerReDecision"]}];

(* ------------------------------------------------------------------ *)
(* (c) THE BUDGET STILL OUTRANKS THE BROKER                             *)
(* ------------------------------------------------------------------ *)

expired = solve[syntheticRecord, Sequence @@ fixtureOptions,
  "BrokerMinimumSeconds" -> 0.001, "Deadline" -> AbsoluteTime[] + 0.01];
check["an expired deadline still returns the typed budget stop with the broker active",
  AssociationQ[expired] && expired["Status"] === "BudgetExhausted" &&
    expired =!= $Aborted && expired =!= $Failed &&
    StringQ[expired["Stage"]] && TrueQ[expired["Resumable"]]];
check["the budget stop reports the broker state it stopped in",
  AssociationQ[expired] && KeyExistsQ[expired, "BrokerActive"] &&
    KeyExistsQ[expired, "BrokerReDecision"] &&
    expired["BrokerReDecision"] === None &&
    expired["BrokerMinimumSeconds"] === 0.001];
(* a deadline INSIDE the solve, scaled to the solve this machine just
   measured (a fixed number of seconds would be an entry gate on a fast
   box and no gate at all on a slow one) *)
{midSeconds, mid} = AbsoluteTiming[
  solve[syntheticRecord, Sequence @@ fixtureOptions,
    "BrokerMinimumSeconds" -> 0.001,
    "Deadline" -> AbsoluteTime[] + inactiveSeconds/3]];
check["a mid-solve deadline stops the farmed solve at a loop boundary",
  AssociationQ[mid] && mid["Status"] === "BudgetExhausted" &&
    mid["Stage"] =!= "Entry" && midSeconds < 30];
report["mid-solve budget stop", KeyTake[mid,
  {"Stage", "Prime", "PrimesCompleted", "BrokerActive", "BrokerReDecision"}]];

(* ------------------------------------------------------------------ *)
(* (d) ARTIFACT LAYOUT AND RESUME                                       *)
(* ------------------------------------------------------------------ *)

artifactDirectory = CreateDirectory[];
{firstSeconds, firstPass} = AbsoluteTiming[
  solve[syntheticRecord, "BrokerMinimumSeconds" -> 0.001,
    "ArtifactDirectory" -> artifactDirectory, Sequence @@ fixtureOptions]];
artifacts = Sort[FileNameTake /@ FileNames["*.wl", artifactDirectory]];
check["the per-prime artifact layout is one file per prime, unchanged",
  AssociationQ[firstPass] &&
    artifacts === Sort[("finite_field_strip_mod_" <> ToString[#] <> ".wl") & /@
      firstPass["Primes"]]];
{resumeSeconds, resumed} = AbsoluteTiming[
  solve[syntheticRecord, "BrokerMinimumSeconds" -> 0.001,
    "ArtifactDirectory" -> artifactDirectory, Sequence @@ fixtureOptions]];
check["the resumed solve returns the same payload",
  payload[resumed] === headPayload];
check["a resumed prime is not timed and cannot trigger a re-decision",
  AssociationQ[resumed] && resumed["PrimeWallSeconds"] === {} &&
    resumed["BrokerReDecision"] === None];
report["first pass / resume seconds", Round[{firstSeconds, resumeSeconds}, 0.01]];
report["artifacts", artifacts];

(* ------------------------------------------------------------------ *)
(* (e) THE ENVIRONMENT OVERRIDE                                         *)
(* ------------------------------------------------------------------ *)

optionDefault[] := Lookup[Options[solve], "BrokerMinimumSeconds", None];
(* the minimum a call actually resolved, read off an entry-stage budget
   stop -- instant, and it is the solver's own option resolution *)
resolvedMinimum[opts___] := Lookup[
  solve[syntheticRecord, opts, "Deadline" -> AbsoluteTime[] + 0.01,
    Sequence @@ fixtureOptions],
  "BrokerMinimumSeconds", None];

check["the option default is the built-in 8.0 when the variable is unset",
  optionDefault[] === 8.0 &&
    FeynFacet`Private`$finiteFieldStripBrokerMinimumSecondsDefault === 8.0];
check["well-formed values parse",
  parseMinimum["12", 8.0] === 12. && parseMinimum["0.001", 8.0] === 0.001 &&
    parseMinimum["  2.5  ", 8.0] === 2.5 && parseMinimum["1e-3", 8.0] === 0.001 &&
    parseMinimum[".5", 8.0] === 0.5 && parseMinimum["0", 8.0] === 0.];
check["malformed values fall back to the option default",
  parseMinimum["abc", 8.0] === 8.0 && parseMinimum["", 8.0] === 8.0 &&
    parseMinimum["8 s", 8.0] === 8.0 && parseMinimum["-1", 8.0] === 8.0 &&
    parseMinimum["1/2", 8.0] === 8.0 && parseMinimum["3.5.2", 8.0] === 8.0 &&
    parseMinimum["Infinity", 8.0] === 8.0 && parseMinimum[None, 8.0] === 8.0 &&
    parseMinimum["Run[\"true\"]", 8.0] === 8.0];

(* read once per session: the second call keeps the first value *)
FeynFacet`Private`$finiteFieldStripBrokerMinimumSecondsCache = None;
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> "2.5"];
firstRead = resolveMinimum[];
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> "9.5"];
secondRead = resolveMinimum[];
FeynFacet`Private`$finiteFieldStripBrokerMinimumSecondsCache = None;
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> "not a number"];
malformedRead = resolveMinimum[];
FeynFacet`Private`$finiteFieldStripBrokerMinimumSecondsCache = None;
check["the variable is read once per kernel session",
  firstRead === 2.5 && secondRead === 2.5];
check["a malformed variable resolves to the built-in default",
  malformedRead === 8.0];

(* end to end: the variable moves the option DEFAULT, and an explicit
   option still wins over it.  Reloading the private file is exactly how
   FeynFacet.m binds that default. *)
loadPrivate[] := (BeginPackage["FeynFacet`"]; Begin["`Private`"];
  Quiet[Get[FileNameJoin[{root, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]],
    General::shdw];
  End[]; Quiet[EndPackage[], General::shdw];);
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> "2.5"];
loadPrivate[];
check["the variable moves the option default",
  optionDefault[] === 2.5 && resolvedMinimum[] === 2.5];
check["an explicit option outranks the variable",
  resolvedMinimum["BrokerMinimumSeconds" -> 0.001] === 0.001];
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> "eight"];
loadPrivate[];
check["a malformed variable leaves the built-in default in the options",
  optionDefault[] === 8.0 && resolvedMinimum[] === 8.0];
SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> ""];
loadPrivate[];
check["the reloaded solver still solves the fixture exactly",
  With[{r = solve[syntheticRecord, Sequence @@ fixtureOptions]},
    AssociationQ[r] && TrueQ[r["ExactPfaffianResidualsZero"]] &&
      payload[r] === headPayload]];

(* ------------------------------------------------------------------ *)

If[StringQ[oldBroker], SetEnvironment["FACET_TASK_BROKER" -> oldBroker],
  SetEnvironment["FACET_TASK_BROKER" -> ""]];
If[StringQ[oldLimit], SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> oldLimit],
  SetEnvironment["FACET_TASK_BROKER_MAX_HELPERS" -> ""]];
If[StringQ[oldMinimum], SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> oldMinimum],
  SetEnvironment["FACET_BROKER_MINIMUM_SECONDS" -> ""]];
Quiet[DeleteDirectory[poolDirectory, DeleteContents -> True]];
Quiet[DeleteDirectory[artifactDirectory, DeleteContents -> True]];

Print["t_broker_adaptive: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
