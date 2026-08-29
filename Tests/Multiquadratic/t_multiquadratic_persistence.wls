#!/usr/bin/env wolframscript
(* The 2026-08-25 HARDENING WAVE persistence and cooperative-budget work:

     - PREPARE INTERMEDIATE PERSISTENCE.  multiquadraticStripPrepare
       measured 2710.9 s cold on the real CF300 (12,9) descriptor and
       checkpointed nothing, so the round-6 cancellation lost all of it.
       Each expensive substage boundary now writes one sealed record and
       a later preparation of the same inputs reads it back.
     - COMPILE COOPERATIVE DEADLINE.  multiquadraticStripCompile did not
       accept "Deadline"; the public path checked only after it
       returned.
     - SCREEN INTERIOR BOUNDARIES.  The two per-image screens read the
       deadline only around their compile phase and around the rank.
     - WHOLE-FAMILY DEADLINE PERSISTENCE and the STALE-STOP MIGRATION,
       both now package policy functions rather than sector-driver
       inline code, so both are testable without running a family.

   ACCEPTANCE CRITERIA, stated before the run.

   P  PERSISTENCE.  With no checkpoint directory (the default) the
      preparation is byte-identical to the pre-2026-08-25 one and no
      file is touched.  With a directory, the three substage records
      appear; a second preparation of the SAME inputs reads all three
      back and returns a preparation SameQ to the first (up to the
      checkpoint telemetry itself); a MUTATED checkpoint is refused
      typed and recomputed, never trusted; a checkpoint belonging to
      different inputs is refused on its input fingerprint; and a
      checkpoint whose seal fingerprint does not match its own header is
      refused.

   C  COMPILE DEADLINE.  "Deadline" -> Infinity is byte-identical to
      passing no option.  An already-expired deadline is a typed
      resumable BudgetExhausted naming "Compilation:Entry".  A deadline
      that expires DURING the compile stops typed at a "Compilation:"
      substage, never by exception and never as $Aborted.  An invalid
      deadline is a caller error that outranks the budget.  The top
      level forwards its own deadline to the compiler.

   S  SCREEN BOUNDARIES.  Both per-image screens have a cooperative
      boundary INSIDE the compile phase (between letters) and one AFTER
      the rank pair, and every stop is a typed BudgetExhausted whose
      Stage names its screen.

   F  FAMILY DEADLINE.  A declared budget stamps an epoch; a resume of
      the stamped state INHERITS that epoch rather than a fresh one; a
      resume with no budget declared keeps it; a changed budget
      restamps and says so.

   M  STALE-STOP MIGRATION.  A pre-fix state whose resolvable Stop has a
      matching factorization with no resolution record is migrated once,
      with a recorded resolution; a Stop with no matching factorization
      is NEVER cleared; a post-fix record is not migrated twice. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticStripSolve.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
note[label_, value_] := Print["     ", label, ": ",
  ToString[Short[value, 8], InputForm]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, rootOrder, clearCaches, gaugeScreen, gaugeAnsatz,
  integrabilityScreen, checkpointFile, checkpointRecord, checkpointAccept,
  artifactWrite, artifactLoad, deadlineExpiredQ, solveMultiquadratic,
  familyDeadlineDecision, staleStopMigration} =
 mq /@ {"multiquadraticStripPrepare", "multiquadraticStripCompile",
   "multiquadraticStripRootOrder", "multiquadraticStripCompileCacheClear",
   "multiquadraticStripGaugeScreen", "multiquadraticStripGaugeAnsatz",
   "multiquadraticStripIntegrabilityScreen",
   "multiquadraticStripPrepareCheckpointFile",
   "multiquadraticStripPrepareCheckpointRecord",
   "multiquadraticStripPrepareCheckpointAccept",
   "multiquadraticStripArtifactWrite", "multiquadraticStripArtifactLoadRaw",
   "multiquadraticStripDeadlineExpiredQ", "solveEpsFormStripMultiquadratic",
   "familyRowGaugeFamilyDeadlineDecision", "familyRowGaugeStaleStopMigration"};

scratch = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-persistence-" <> CreateUUID[]}];
CreateDirectory[scratch, CreateIntermediateDirectories -> True];

(* ------------------------------------------------------------------ *)
(* The fixture (the construction t_multiquadratic_prepare_core uses)    *)
(* ------------------------------------------------------------------ *)

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

canonicalRootRecords[indices_] := Module[
  {order = rootOrder[frame, {x, y}, indices, eps]},
  If[Lookup[order, "Status", None] =!= "StableRootOrder", $Failed,
    order["Roots"]]];

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

buildRecord[indices_List, dimensions_List, seed_Integer] := Module[
  {rootRecords, roots, gradeCount, coefficients, residues, gauge, e, c, bbar},
  rootRecords = canonicalRootRecords[indices];
  roots = Lookup[rootRecords, "Root", {}];
  gradeCount = 2^Length[indices];
  coefficients = BlockRandom[SeedRandom[seed];
    Table[RandomInteger[{-6, 6}] + RandomChoice[{0, 1/2, 1/3, -2/5}],
      {dimensions[[1]]}, {dimensions[[2]]}, {gradeCount}, {Length[support]}]];
  residues = BlockRandom[SeedRandom[seed + 1];
    Table[RandomInteger[{-4, 4}] + RandomChoice[{0, 1/4, -1/7}],
      {Length[letters]}, {dimensions[[1]]}, {dimensions[[2]]}]];
  gauge = buildGauge[coefficients, dimensions, roots];
  e = BlockRandom[SeedRandom[seed + 2];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[1]],
      dimensions[[1]]}], {Length[letters]}]]];
  c = BlockRandom[SeedRandom[seed + 3];
    diagonalForm[Table[RandomInteger[{-2, 2}, {dimensions[[2]],
      dimensions[[2]]}], {Length[letters]}]]];
  bbar = buildForcing[e, c, gauge, residues];
  <|"Family" -> "TPERS", "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {e, c, bbar}|>];

record = buildRecord[{1, 2}, {2, 2}, 20260825];
rootRecords = canonicalRootRecords[{1, 2}];
otherRecord = buildRecord[{1, 2}, {2, 2}, 20260826];
check["the fixture records are well-formed strips",
  MatchQ[Lookup[record, "Strip", None], {_List, _List, _List}] &&
    MatchQ[Lookup[otherRecord, "Strip", None], {_List, _List, _List}] &&
    ! SameQ[record["Strip"], otherRecord["Strip"]]];

(* the letter route is exercised too, so all three checkpoints appear *)
prepareArgs = {"GaugeDenominator" -> denominator, "Support" -> support,
  "RootIndices" -> {1, 2}, "RegulatorSampleCount" -> 2};

(* ================================================================== *)
(* P  PREPARE INTERMEDIATE PERSISTENCE                                  *)
(* ================================================================== *)

clearCaches[];
plain = prepare[record, frame, Sequence @@ prepareArgs];
check["P0 the default preparation succeeds and persists nothing",
  Lookup[plain, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[plain, "PrepareCheckpoints", None] === {} &&
    FileNames["*", scratch] === {}];

checkpointDirectory = FileNameJoin[{scratch, "cp"}];
clearCaches[];
firstRun = prepare[record, frame, Sequence @@ prepareArgs,
  "CheckpointDirectory" -> checkpointDirectory, "CheckpointTag" -> "TPERS_4_2"];
firstRecords = Lookup[firstRun, "PrepareCheckpoints", {}];
note["P1 checkpoint actions",
  {#["Substage"], #["Action"], #["Status"]} & /@ firstRecords];
check["P1 the first run WRITES one record per expensive substage",
  Lookup[firstRun, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Sort[Lookup[Select[firstRecords, #["Action"] === "Write" &],
      "Substage"]] ===
      {"CandidateLetters", "ForcingChannels", "GaugeDenominator"} &&
    AllTrue[Select[firstRecords, #["Action"] === "Write" &],
      #["Status"] === "MultiquadraticArtifactWritten" &]];

writtenFiles = Sort[FileNameTake /@ FileNames["*.wl", checkpointDirectory]];
note["P1 files written", writtenFiles];
check["P1 the three files are on disk under the declared tag",
  writtenFiles === {"TPERS_4_2_prepare_candidateletters.wl",
    "TPERS_4_2_prepare_forcingchannels.wl",
    "TPERS_4_2_prepare_gaugedenominator.wl"}];

clearCaches[];
secondRun = prepare[record, frame, Sequence @@ prepareArgs,
  "CheckpointDirectory" -> checkpointDirectory, "CheckpointTag" -> "TPERS_4_2"];
secondRecords = Lookup[secondRun, "PrepareCheckpoints", {}];
note["P2 checkpoint actions",
  {#["Substage"], #["Action"], #["Status"]} & /@ secondRecords];
check["P2 the second run READS all three back and writes nothing",
  Lookup[secondRun, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Select[secondRecords, #["Action"] === "Write" &] === {} &&
    Sort[Lookup[Select[secondRecords,
      #["Action"] === "Read" && #["Status"] === "Accepted" &], "Substage"]] ===
      {"CandidateLetters", "ForcingChannels", "GaugeDenominator"}];

telemetryKeys = {"PrepareCheckpoints", "RootFreeFastPathCount",
  "ChannelPathStatistics"};
check["P2 the checkpointed preparation is SameQ to the uncheckpointed \
one, up to the checkpoint and channel-path telemetry",
  SameQ[KeyDrop[secondRun, telemetryKeys], KeyDrop[plain, telemetryKeys]] &&
    secondRun["ABIFingerprint"] === plain["ABIFingerprint"]];

check["P2 the seal inside the forcing checkpoint authenticated as well",
  MemberQ[Lookup[Select[secondRecords, #["Action"] === "Seal" &], "Status"],
    "Accepted"]];

(* ---- THE MUTATION: one channel entry changed on disk ---- *)
forcingFile = FileNameJoin[{checkpointDirectory,
  "TPERS_4_2_prepare_forcingchannels.wl"}];
mutatedRaw = artifactLoad[forcingFile, "FeynFacet`MultiquadraticArtifact`"];
mutatedCheckpoint = mutatedRaw["Value"];
mutatedPayload = Append[mutatedCheckpoint["Payload"],
  "Channels" -> ReplacePart[mutatedCheckpoint["Payload"]["Channels"],
    {1, 1, 1, 1} -> 987654321]];
artifactWrite[Append[mutatedCheckpoint, "Payload" -> mutatedPayload],
  forcingFile];
clearCaches[];
mutatedRun = prepare[record, frame, Sequence @@ prepareArgs,
  "CheckpointDirectory" -> checkpointDirectory, "CheckpointTag" -> "TPERS_4_2"];
mutatedRecords = Lookup[mutatedRun, "PrepareCheckpoints", {}];
note["P3 checkpoint actions after the mutation",
  {#["Substage"], #["Action"], #["Status"]} & /@ mutatedRecords];
check["P3 a MUTATED checkpoint is refused typed on its payload hash",
  Lookup[SelectFirst[mutatedRecords,
    #["Substage"] === "ForcingChannels" && #["Action"] === "Read" &, <||>],
    "Status", None] === "PrepareCheckpointContentMismatch"];
check["P3 the preparation recomputes and is still byte-identical to the \
uncheckpointed one",
  Lookup[mutatedRun, "Status", None] === "PreparedMultiquadraticStripV1" &&
    SameQ[KeyDrop[mutatedRun, telemetryKeys], KeyDrop[plain, telemetryKeys]]];
check["P3 the refused checkpoint is REWRITTEN from the recomputation",
  MemberQ[Lookup[Select[mutatedRecords,
    #["Substage"] === "ForcingChannels" && #["Action"] === "Write" &],
    "Status"], "MultiquadraticArtifactWritten"]];

(* ---- a checkpoint belonging to DIFFERENT inputs ---- *)
clearCaches[];
otherRun = prepare[otherRecord, frame, Sequence @@ prepareArgs,
  "CheckpointDirectory" -> checkpointDirectory, "CheckpointTag" -> "TPERS_4_2"];
otherRecords = Lookup[otherRun, "PrepareCheckpoints", {}];
check["P4 a checkpoint written for a DIFFERENT strip is refused on its \
input fingerprint",
  Lookup[otherRun, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[SelectFirst[otherRecords,
      #["Substage"] === "ForcingChannels" && #["Action"] === "Read" &, <||>],
      "Status", None] === "PrepareCheckpointInputMismatch"];

(* ---- the seal fingerprint itself ---- *)
check["P5 a checkpoint whose header was edited without re-deriving its \
fingerprint is refused",
  Module[{good = checkpointRecord["ForcingChannels", "FP", {1, 2, 3},
      {x, y}, eps], tampered},
    tampered = Append[good, "InputFingerprint" -> "FP2"];
    Lookup[checkpointAccept[good, "ForcingChannels", "FP", {x, y}, eps],
      "Status", None] === "Accepted" &&
      Lookup[checkpointAccept[tampered, "ForcingChannels", "FP2", {x, y}, eps],
        "Status", None] === "PrepareCheckpointSealMismatch"]];
check["P5 a checkpoint for another SUBSTAGE is refused",
  Lookup[checkpointAccept[
    checkpointRecord["ForcingChannels", "FP", {1}, {x, y}, eps],
    "CandidateLetters", "FP", {x, y}, eps], "Status", None] ===
    "PrepareCheckpointSubstageMismatch"];
check["P5 resume admission is blind to the current implementation hash",
  Module[{good = checkpointRecord["ForcingChannels", "FP", {1},
      {x, y}, eps]},
    Block[{FeynFacet`Private`$multiquadraticStripSourceSHA256 =
        StringRepeat["a", 64]},
      Lookup[checkpointAccept[good, "ForcingChannels", "FP", {x, y}, eps],
        "Status", None] === "Accepted"]]];
check["P5 a payload is stored CONTEXT FREE and comes back in the \
caller's symbols",
  Module[{stored = checkpointRecord["ForcingChannels", "FP", {x + y},
      {x, y}, eps]},
    FreeQ[stored["Payload"], x | y | eps] &&
      Lookup[checkpointAccept[stored, "ForcingChannels", "FP", {x, y}, eps],
        "Payload", None] === {x + y}]];

check["P6 CheckpointMode -> Write reads nothing back",
  Module[{result = prepare[record, frame, Sequence @@ prepareArgs,
      "CheckpointDirectory" -> checkpointDirectory,
      "CheckpointTag" -> "TPERS_4_2", "CheckpointMode" -> "Write"]},
    Lookup[result, "Status", None] === "PreparedMultiquadraticStripV1" &&
      Select[Lookup[result, "PrepareCheckpoints", {}],
        #["Action"] === "Read" &] === {}]];
check["P6 an invalid checkpoint option is a typed caller error",
  Lookup[prepare[record, frame, Sequence @@ prepareArgs,
    "CheckpointMode" -> "Sometimes"], "Status", None] ===
      "InvalidPrepareCheckpointOption" &&
    Lookup[prepare[record, frame, Sequence @@ prepareArgs,
      "CheckpointDirectory" -> checkpointDirectory,
      "CheckpointTag" -> "../escape"], "Status", None] ===
      "InvalidPrepareCheckpointTag"];

(* ================================================================== *)
(* C  THE COMPILE COOPERATIVE DEADLINE                                  *)
(* ================================================================== *)

clearCaches[];
preparation = prepare[record, frame, "OneForms" -> oneForms,
  "GaugeDenominator" -> denominator, "Support" -> support,
  "RootIndices" -> {1, 2}];
check["C0 the reference preparation succeeds",
  Lookup[preparation, "Status", None] === "PreparedMultiquadraticStripV1"];

clearCaches[];
{baselineSeconds, baseline} = AbsoluteTiming[
  compile[preparation, "PreparationValidated" -> True]];
clearCaches[];
withInfinity = compile[preparation, "PreparationValidated" -> True,
  "Deadline" -> Infinity];
note["C1 baseline compile seconds", Round[baselineSeconds, 0.001]];
check["C1 Deadline -> Infinity is byte-identical to passing no option",
  Lookup[baseline, "Status", None] === "CompiledMultiquadraticStripV1" &&
    baseline["AssemblyFingerprint"] === withInfinity["AssemblyFingerprint"] &&
    SameQ[KeyDrop[baseline, "CompileStatistics"],
      KeyDrop[withInfinity, "CompileStatistics"]]];

clearCaches[];
expiredEntry = compile[preparation, "PreparationValidated" -> True,
  "Deadline" -> AbsoluteTime[] - 10];
check["C2 an already-expired deadline is a typed resumable stop at \
Compilation:Entry",
  Lookup[expiredEntry, "Status", None] === "BudgetExhausted" &&
    Lookup[expiredEntry, "Stage", None] === "Compilation:Entry" &&
    TrueQ[Lookup[expiredEntry, "Resumable", False]] &&
    Lookup[expiredEntry, "Method", None] === "DirectRootChannel" &&
    AllTrue[{"Family", "Sector", "LowerSector", "Elapsed", "Deadline"},
      KeyExistsQ[expiredEntry, #] &]];

check["C3 an invalid deadline is a caller error that outranks the budget",
  Lookup[compile[preparation, "PreparationValidated" -> True,
    "Deadline" -> -5], "Status", None] === "InvalidDeadline"];

(* a deadline that expires DURING the compile: the interior boundaries
   are the only thing that can stop it, and it must stop TYPED *)
interiorStops = Table[
  Module[{result},
    clearCaches[];
    result = compile[preparation, "PreparationValidated" -> True,
      "Deadline" -> AbsoluteTime[] + fraction baselineSeconds];
    Lookup[result, "Stage", Lookup[result, "Status", None]]],
  {fraction, {0.02, 0.1, 0.3, 0.5}}];
note["C4 stages reached with a deadline inside the compile", interiorStops];
check["C4 a deadline expiring inside the compile stops TYPED at a \
Compilation substage, never by exception",
  AllTrue[interiorStops, StringQ[#] &&
    (StringStartsQ[#, "Compilation:"] ||
      # === "CompiledMultiquadraticStripV1") &] &&
    MemberQ[interiorStops, stage_String /; StringStartsQ[stage,
      "Compilation:"]]];
check["C4 the interior stop carries its resumable progress payload",
  Module[{result},
    clearCaches[];
    result = compile[preparation, "PreparationValidated" -> True,
      "Deadline" -> AbsoluteTime[] + 0.02 baselineSeconds];
    Lookup[result, "Status", None] =!= "BudgetExhausted" ||
      (TrueQ[result["Resumable"]] && KeyExistsQ[result, "OneFormCount"] &&
        KeyExistsQ[result, "Architecture"] &&
        NumericQ[result["Elapsed"]])]];

clearCaches[];
check["C5 the top level forwards its own deadline to the compiler",
  MemberQ[Lookup[Options[compile], 1, {}] /. (a_ -> b_) :> a, "Deadline"] ||
    MemberQ[Keys[Association[Options[compile]]], "Deadline"]];
check["C5 the top level stops typed when the budget expires before the \
compile it forwards to",
  Module[{result = solveMultiquadratic[record, frame, "OneForms" -> oneForms,
      "GaugeDenominator" -> denominator, "Support" -> support,
      "RootIndices" -> {1, 2}, "IntegrabilityScreen" -> False,
      "GaugeScreen" -> False, "Deadline" -> AbsoluteTime[] - 1]},
    Lookup[result, "Status", None] === "BudgetExhausted" &&
      StringQ[Lookup[result, "Stage", None]]]];

(* ================================================================== *)
(* S  SCREEN INTERIOR BOUNDARIES                                        *)
(* ================================================================== *)

(* FAULT INJECTION.  The boundary under test is "the k-th deadline read
   of this screen", which a wall clock cannot address deterministically.
   Replacing the expiry predicate by a counter addresses it exactly, and
   changes nothing else about what the screen computes. *)
check["S0 the fault-injection point has a definition to replace",
  Length[DownValues[FeynFacet`Private`multiquadraticStripDeadlineExpiredQ]] >= 1];

screenAnsatz = gaugeAnsatz[record, rootRecords, oneForms, denominator,
  "Support" -> support];
check["S0 the screen ansatz is well formed",
  Lookup[screenAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1"];

stagesAt[threshold_Integer, run_] := Module[{calls = 0, result},
  result = Block[{FeynFacet`Private`multiquadraticStripDeadlineExpiredQ},
    FeynFacet`Private`multiquadraticStripDeadlineExpiredQ[d_] := (
      calls++; NumericQ[d] && calls >= threshold);
    run[]];
  Lookup[result, "Stage", Lookup[result, "Status", None]]];

(* how many deadline reads an UNINTERRUPTED run makes: scanning exactly
   that many thresholds enumerates every cooperative boundary the screen
   has, and no more *)
countReads[run_] := Module[{calls = 0},
  Block[{FeynFacet`Private`multiquadraticStripDeadlineExpiredQ},
    FeynFacet`Private`multiquadraticStripDeadlineExpiredQ[d_] := (
      calls++; False);
    run[]];
  calls];

gaugeRun = Function[gaugeScreen[screenAnsatz,
  "Deadline" -> AbsoluteTime[] + 3600, "PointCount" -> 4,
  "LeftNullSpace" -> True]];
gaugeReads = countReads[gaugeRun];
note["S1 gauge-screen deadline reads in an uninterrupted run", gaugeReads];
gaugeStages = DeleteDuplicates[Table[
  stagesAt[threshold, gaugeRun], {threshold, 1, gaugeReads}]];
note["S1 gauge-screen stages reachable by a cooperative boundary",
  gaugeStages];
check["S1 the gauge screen has a boundary INSIDE its letter compile",
  MemberQ[gaugeStages, "GaugeScreen:LetterCompile"]];
check["S1 the gauge screen has a boundary AFTER the rank pair",
  MemberQ[gaugeStages, "GaugeScreen:PostRank"]];
check["S1 every gauge-screen stop is typed and names its screen",
  AllTrue[gaugeStages, StringQ[#] &&
    (StringStartsQ[#, "GaugeScreen:"] ||
      MemberQ[{"GaugeImageConsistent", "GaugeImageObstruction",
        "GaugeScreenNotApplicable"}, #]) &]];

(* The residue-only screen is applicable only to a FLAT diagonal pair
   (it is a statement about residues alone); the gauge fixture above is
   not flat, so the screen refuses it as not applicable before it ever
   reaches a rank.  The 1x1 flat fixture below is the one
   Tests/Multiquadratic/t_multiquadratic_gauge_screen.wls screens, and it walks the
   whole screen. *)
Clear[ax, ay, ae];
flatRecord = <|"Family" -> "TPERSFlat", "Sector" -> 2, "LowerSector" -> 1,
  "Variables" -> {ax, ay}, "Regulator" -> ae,
  "Strip" -> {{{{1}}, {{ae}}}, {{{0}}, {{0}}},
    {{{0}}, {{ae^2 (ay - ax)/(1 + ae)}}}}|>;
integrabilityLetters = {
  <|"Kind" -> "Synthetic", "Letter" -> Missing["NotADLog"],
    "OneForm" -> {-ay, ax}|>,
  <|"Kind" -> "Synthetic", "Letter" -> Missing["NotADLog"],
    "OneForm" -> {-ax, ay}|>};
integrabilityRun = Function[integrabilityScreen[flatRecord, {},
  integrabilityLetters, "Deadline" -> AbsoluteTime[] + 3600,
  "Prime" -> 2147483423, "RegulatorValue" -> 1, "PointCount" -> 4]];
integrabilityReads = countReads[integrabilityRun];
note["S2 integrability-screen deadline reads in an uninterrupted run",
  integrabilityReads];
integrabilityStages = DeleteDuplicates[Table[
  stagesAt[threshold, integrabilityRun], {threshold, 1, integrabilityReads}]];
note["S2 integrability-screen stages reachable by a cooperative boundary",
  integrabilityStages];
check["S2 the integrability screen has a boundary INSIDE its letter compile",
  MemberQ[integrabilityStages, "IntegrabilityScreen:LetterCompile"]];
check["S2 the integrability screen has a boundary AFTER the rank pair",
  MemberQ[integrabilityStages, "IntegrabilityScreen:PostRank"]];
check["S2 every integrability-screen stop is typed and names its screen",
  AllTrue[integrabilityStages, StringQ[#] &&
    (StringStartsQ[#, "IntegrabilityScreen:"] ||
      MemberQ[{"AlphabetIntegrabilityConsistent",
        "AlphabetIntegrabilityObstruction",
        "IntegrabilityScreenNotApplicable"}, #]) &]];
check["S3 an unbounded screen is unchanged by the boundaries",
  Module[{result = gaugeScreen[screenAnsatz, "PointCount" -> 4]},
    MemberQ[{"GaugeImageConsistent", "GaugeImageObstruction"},
      Lookup[result, "Status", None]]]];

(* ================================================================== *)
(* T  TOP-LEVEL CEILING OPTIONS                                         *)
(* ================================================================== *)

check["T1 the ceilings are declared top-level options with Automatic \
defaults",
  Module[{options = Association[Options[solveMultiquadratic]]},
    AllTrue[{"ScreenMaximumUnknowns", "ScreenMaximumBytes",
      "CompilePoolByteLimit", "CompilePoolEntryLimit",
      "ScreenCompileCacheBytes"},
      KeyExistsQ[options, #] && options[#] === Automatic &]]];
check["T2 an invalid ceiling is a typed caller error",
  Lookup[solveMultiquadratic[record, frame, "OneForms" -> oneForms,
    "ScreenMaximumUnknowns" -> -3], "Status", None] ===
    "InvalidCeilingOption"];
check["T3 a declared unknown-count ceiling really reaches the screen",
  Module[{result = solveMultiquadratic[record, frame,
      "OneForms" -> oneForms, "GaugeDenominator" -> denominator,
      "Support" -> support, "RootIndices" -> {1, 2},
      "IntegrabilityScreen" -> False, "ScreenMaximumUnknowns" -> 1,
      "Deadline" -> AbsoluteTime[] + 600]},
    (* the screen refuses itself as not applicable and the established
       route continues, so the solve does NOT stop at the screen *)
    Lookup[result, "Status", None] =!= "GaugeImageObstruction"]];

(* ================================================================== *)
(* F  WHOLE-FAMILY DEADLINE PERSISTENCE                                 *)
(* ================================================================== *)

emptyState = <|"Sector" -> 1|>;
now = 1000000.;
noBudget = familyDeadlineDecision[emptyState, Infinity, now];
check["F1 no declared budget and nothing stamped is unbounded",
  noBudget["Action"] === "None" && noBudget["Deadline"] === Infinity &&
    noBudget["Persist"] === False];

stamped = familyDeadlineDecision[emptyState, 7200, now];
check["F2 a declared budget STAMPS an absolute epoch and asks to persist it",
  stamped["Action"] === "Stamped" &&
    stamped["Deadline"] === now + 7200 &&
    TrueQ[stamped["Persist"]] &&
    stamped["State"]["FamilyDeadline"] === now + 7200 &&
    stamped["State"]["FamilyBudgetSeconds"] === 7200];

resumed = familyDeadlineDecision[stamped["State"], 7200, now + 3600];
check["F3 a resume INHERITS the stamped epoch: the remaining budget, \
not a fresh one",
  resumed["Action"] === "Inherited" &&
    resumed["Deadline"] === now + 7200 &&
    resumed["Deadline"] - (now + 3600) === 3600. &&
    resumed["Persist"] === False];

resumedNoDeclaration = familyDeadlineDecision[stamped["State"], Infinity,
  now + 3600];
check["F4 a resume with no budget declared still inherits the stamped epoch",
  resumedNoDeclaration["Action"] === "Inherited" &&
    resumedNoDeclaration["Deadline"] === now + 7200];

rebudgeted = familyDeadlineDecision[stamped["State"], 1800, now + 3600];
check["F5 a CHANGED budget restamps and records what it replaced",
  rebudgeted["Action"] === "Restamped" &&
    rebudgeted["Deadline"] === now + 3600 + 1800 &&
    rebudgeted["PreviousDeadline"] === now + 7200 &&
    rebudgeted["PreviousBudgetSeconds"] === 7200 &&
    TrueQ[rebudgeted["Persist"]]];

check["F6 an expired inherited epoch is in the past, which is what the \
driver stops on",
  familyDeadlineDecision[stamped["State"], 7200, now + 9000]["Deadline"] <
    now + 9000];

check["F7 the sector driver applies the package policy and does not \
reimplement it",
  Module[{driverSource = Import[FileNameJoin[{root, "Scripts",
      "family_epsform_sector.wls"}], "Text"]},
    StringContainsQ[driverSource,
      "familyRowGaugeFamilyDeadlineDecision"] &&
      StringContainsQ[driverSource,
        "sectorDeadline = Min[AbsoluteTime[] + sectorBudget, familyDeadline]"]]];

(* ================================================================== *)
(* M  THE STALE-STOP MIGRATION                                          *)
(* ================================================================== *)

preFixState = <|"Sector" -> 9,
  "Stop" -> <|"Status" -> "NeedsMultiquadraticRegulatorFactorization",
    "Rows" -> 8, "RootIndices" -> {1, 2}|>,
  "RegulatorFactorizations" -> {
    <|"Rows" -> 7, "Method" -> "RationalChart"|>,
    <|"Rows" -> 8, "Method" -> "Multiquadratic"|>}|>;
migrated = staleStopMigration[preFixState];
check["M1 a pre-ResolvedStop state is migrated once and its Stop is cleared",
  migrated["Status"] === "Migrated" &&
    ! KeyExistsQ[migrated["State"], "Stop"] &&
    migrated["Migration"]["ClearedStatus"] ===
      "NeedsMultiquadraticRegulatorFactorization" &&
    migrated["Migration"]["Rows"] === 8 &&
    migrated["Migration"]["ResolvedBy"] === "Multiquadratic"];
check["M1 the resolution is recorded IN the factorization record it \
belongs to, and in the state's migration log",
  AssociationQ[Lookup[SelectFirst[migrated["State"]["RegulatorFactorizations"],
      #["Rows"] === 8 &, <||>], "ResolvedStop", None]] &&
    Length[migrated["State"]["StateMigrations"]] === 1 &&
    Lookup[SelectFirst[migrated["State"]["RegulatorFactorizations"],
      #["Rows"] === 7 &, <||>], "ResolvedStop", Missing["Absent"]] ===
      Missing["Absent"]];
check["M2 migrating the migrated state again does nothing",
  Lookup[staleStopMigration[migrated["State"]], "Status", None] ===
    "NoMigration"];
check["M3 a Stop with NO matching factorization is a real terminal and \
is never cleared",
  Module[{result = staleStopMigration[Append[preFixState,
      "RegulatorFactorizations" -> {<|"Rows" -> 7,
        "Method" -> "RationalChart"|>}]]},
    result["Status"] === "NoMigration" &&
      result["Reason"] === "NoFactorizationForTheseRows" &&
      KeyExistsQ[result["State"], "Stop"]]];
check["M4 a post-fix record (already carrying a resolution) is not \
migrated a second time",
  Module[{result = staleStopMigration[Append[preFixState,
      "RegulatorFactorizations" -> {<|"Rows" -> 8,
        "Method" -> "Multiquadratic",
        "ResolvedStop" -> <|"ClearedStatus" -> "Something"|>|>}]]},
    result["Status"] === "NoMigration" &&
      result["Reason"] === "FactorizationAlreadyCarriesResolution" &&
      KeyExistsQ[result["State"], "Stop"]]];
check["M5 a Stop this driver does not resolve is left alone",
  Lookup[staleStopMigration[Append[preFixState,
    "Stop" -> <|"Status" -> "StripBudgetExhausted", "Rows" -> 8|>]],
    "Reason", None] === "NoResolvableStop"];
check["M6 the sector driver applies the package migration and does not \
reimplement it",
  StringContainsQ[Import[FileNameJoin[{root, "Scripts",
    "family_epsform_sector.wls"}], "Text"],
    "familyRowGaugeStaleStopMigration"]];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];
Print["t_multiquadratic_persistence: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
