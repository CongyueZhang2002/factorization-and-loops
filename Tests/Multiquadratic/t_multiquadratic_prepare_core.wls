#!/usr/bin/env wolframscript
(* The 2026-08-25 preparation work in
   FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripSolve.wl:

     - prepare CONSUMES the sealed compile core instead of decomposing the
       forcing independently (so E, C and BBar are decomposed once for
       prepare and compile together, not twice);
     - the intern pools never cache a NEGATIVE result (Codex P1,
       2026-08-25: a failed early core stored $Failed under the core key
       and the later compile hit it, failing a solvable block);
     - "CompileCore" reaches BOTH prepare and the compiler (Codex P2);
     - prepare is cooperatively deadline-aware at interior boundaries;
     - the stage log follows "Verbose" and does not override it.

   Acceptance criteria, stated before the run.

   EQUIVALENCE.  On the same fixture, the preparation returned with the
   early core is SameQ -- byte-identical as an expression, not merely
   equal -- to the preparation returned with "CompileCore" -> False,
   which is the pre-2026-08-25 route; and the two compiled assemblies
   carry the same AssemblyFingerprint and the same
   ExactChannelFormsFingerprint.  A wall clock appears in neither.

   NEGATIVE CACHING.  A build that returns $Failed leaves the pool
   exactly as it found it: the probe after it is Missing, a later good
   build for the same key succeeds and IS cached, and the pool reports
   the refusal in its "Rejected" counter.  End to end, with the first
   early-core build faulted: prepare falls back and succeeds, the Core
   pool holds no entry for that key, and the compile that follows
   rebuilds the core and succeeds.

   DEADLINE.  "Deadline" -> Infinity is byte-identical to passing no
   option at all.  An already-expired deadline returns a typed
   BudgetExhausted whose Stage names a "Preparation:" substage, never an
   exception and never $Aborted.  A deadline that expires while the
   decomposition is running is caught at an INTERIOR boundary, and the
   interior checkpoint throws under an expired dynamic deadline and is
   silent under Infinity.

   TELEMETRY.  A library call is quiet by default; the stage lines appear
   when the top level is asked to be Verbose; and every "start" line
   printed has a matching "done" line. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FeynFacet`Private`feynFacetPrivateFile["MultiquadraticAlgebra.wl"]];
(* the strip solver is eight files since round 4 (2026-09-02); the manifest
   names them in load order *)
Get[FeynFacet`Private`feynFacetPrivateFile[#]] & /@
  Select[Lookup[Get[FileNameJoin[{root, "FeynFacet", "Private", "LoadOrder.wl"}]],
    "EpsForm"], StringStartsQ[FileNameTake[#], "MultiquadraticStrip"] &];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, rootOrder, coreKeyOf, coreRecord, intern, internProbe,
  internStatistics, internReset, clearCaches, deadlineCheckpoint,
  stageStart, stageDone, tensorInterned} =
 mq /@ {"multiquadraticStripPrepare", "multiquadraticStripCompile",
   "multiquadraticStripRootOrder", "multiquadraticStripCompileCoreKey",
   "multiquadraticStripCompileCoreRecord", "multiquadraticStripIntern",
   "multiquadraticStripInternProbe", "multiquadraticStripInternStatistics",
   "multiquadraticStripInternReset", "multiquadraticStripCompileCacheClear",
   "multiquadraticStripDeadlineCheckpoint", "multiquadraticStripStageStart",
   "multiquadraticStripStageDone",
   "multiquadraticStripCompileTensorInterned"};

deadlineTag = mq["$multiquadraticStripDeadlineTag"];

(* ------------------------------------------------------------------ *)
(* The fixture: the same construction t_multiquadratic_strip_solve uses  *)
(* -- a block BUILT from a known gauge and known residues, so that the   *)
(* preparation under test is a preparation of a real solvable block.     *)
(* ------------------------------------------------------------------ *)

Clear[x, y, eps, v, w, cx, cy];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
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
  {order = rootOrder[frame, {x, y}, indices, eps]},
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

buildRecord[indices_List, dimensions_List, seed_Integer] := Module[
  {roots, gradeCount, coefficients, residues, gauge, e, c, bbar},
  roots = canonicalRoots[indices];
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
  <|"Family" -> "TFIX", "Sector" -> 4, "LowerSector" -> 2,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {e, c, bbar}|>];

record = buildRecord[{1, 2}, {2, 2}, 20260825];
check["the fixture record is a well-formed strip",
  MatchQ[Lookup[record, "Strip", None], {_List, _List, _List}]];

prepareArgs = {"OneForms" -> oneForms, "GaugeDenominator" -> denominator,
  "Support" -> support, "RootIndices" -> {1, 2}};

(* ------------------------------------------------------------------ *)
(* E1-E4  equivalence of the early-core route and the HEAD route        *)
(* ------------------------------------------------------------------ *)

clearCaches[];
{coreSeconds, prepCore} = AbsoluteTiming[
  prepare[record, frame, Sequence @@ prepareArgs, "CompileCore" -> True]];
clearCaches[];
{plainSeconds, prepPlain} = AbsoluteTiming[
  prepare[record, frame, Sequence @@ prepareArgs, "CompileCore" -> False]];

check["E1 both preparation routes succeed",
  Lookup[prepCore, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[prepPlain, "Status", None] === "PreparedMultiquadraticStripV1"];

(* The channel-path counters are process TELEMETRY of the decomposition
   actually performed, and the early core legitimately performs more of
   it: it decomposes E and C as well, which is the entire point -- the
   compiler then decomposes neither.  t_solver_budget already classifies
   these two keys as timing/telemetry rather than result.  Everything
   else -- the ABI payload, the fingerprints, the sealed forcing
   channels, the support, the one-forms, the normalizations -- must be
   byte-identical. *)
telemetryKeys = {"RootFreeFastPathCount", "ChannelPathStatistics"};
check["E2 the early-core preparation is SameQ to the HEAD-route \
preparation, up to channel-path telemetry",
  SameQ[KeyDrop[prepCore, telemetryKeys], KeyDrop[prepPlain, telemetryKeys]]];

check["E2b the sealed forcing channels and the whole ABI are identical",
  SameQ[prepCore["ForcingChannels"], prepPlain["ForcingChannels"]] &&
    SameQ[prepCore["ABIPayload"], prepPlain["ABIPayload"]] &&
    prepCore["ABIFingerprint"] === prepPlain["ABIFingerprint"]];

check["E3 no wall clock entered the preparation record",
  FreeQ[KeyDrop[prepCore, {"Record", "Frame", "Roots", "OneForms",
    "OneFormMetadata", "LetterRecords", "ForcingChannels",
    "GaugeDenominator", "GaugeDenominatorFactor"}], _Real]];

clearCaches[];
asmCore = compile[prepare[record, frame, Sequence @@ prepareArgs,
  "CompileCore" -> True], "PreparationValidated" -> True,
  "CompileCore" -> True];
clearCaches[];
asmPlain = compile[prepare[record, frame, Sequence @@ prepareArgs,
  "CompileCore" -> False], "PreparationValidated" -> True,
  "CompileCore" -> False];
check["E4 both compiled assemblies agree on every semantic fingerprint",
  Lookup[asmCore, "Status", None] === "CompiledMultiquadraticStripV1" &&
    Lookup[asmPlain, "Status", None] === "CompiledMultiquadraticStripV1" &&
    asmCore["AssemblyFingerprint"] === asmPlain["AssemblyFingerprint"] &&
    asmCore["ExactChannelFormsFingerprint"] ===
      asmPlain["ExactChannelFormsFingerprint"] &&
    asmCore["CompiledFormsFingerprint"] ===
      asmPlain["CompiledFormsFingerprint"]];

(* ------------------------------------------------------------------ *)
(* R1-R3  the core is built ONCE for prepare and compile together       *)
(* ------------------------------------------------------------------ *)

clearCaches[];
prep2 = prepare[record, frame, Sequence @@ prepareArgs, "CompileCore" -> True];
statsAfterPrepare = internStatistics[];
asm2 = compile[prep2, "PreparationValidated" -> True,
  "ForcingChannels" -> Lookup[prep2, "ForcingChannels", Automatic]];
statsAfterCompile = internStatistics[];

check["R1 prepare builds the core exactly once (one miss, no hit)",
  Lookup[Lookup[statsAfterPrepare, "Core", <||>], "Misses", 0] === 1 &&
    Lookup[Lookup[statsAfterPrepare, "Core", <||>], "Hits", 0] === 0];

check["R2 the compiler that follows HITS that core and rebuilds nothing",
  Lookup[Lookup[statsAfterCompile, "Core", <||>], "Misses", 0] === 1 &&
    Lookup[Lookup[statsAfterCompile, "Core", <||>], "Hits", 0] === 1 &&
    Lookup[asm2, "Status", None] === "CompiledMultiquadraticStripV1"];

check["R3 a SECOND ansatz on the same equation hits the same core",
  Module[{prep3, stats3},
    prep3 = prepare[record, frame, "OneForms" -> oneForms,
      "GaugeDenominator" -> denominator, "RootIndices" -> {1, 2},
      "Support" -> Sort[{{0, 0}, {0, 1}, {1, 0}, {1, 1}}],
      "CompileCore" -> True];
    stats3 = internStatistics[];
    Lookup[prep3, "Status", None] === "PreparedMultiquadraticStripV1" &&
      Lookup[Lookup[stats3, "Core", <||>], "Misses", 0] === 1 &&
      Lookup[Lookup[stats3, "Core", <||>], "Hits", 0] === 2]];

(* ------------------------------------------------------------------ *)
(* N1-N4  a negative result is NEVER cached (Codex P1)                  *)
(* ------------------------------------------------------------------ *)

clearCaches[];
negKey = {"t_multiquadratic_prepare_core", "N1"};
negValue = intern["Core", negKey, Function[$Failed]];
check["N1 a failed build returns $Failed to its caller",
  negValue === $Failed];
check["N2 and leaves NO entry in the pool",
  MissingQ[internProbe["Core", negKey]] &&
    Lookup[Lookup[internStatistics[], "Core", <||>], "Entries", 0] === 0 &&
    Lookup[Lookup[internStatistics[], "Core", <||>], "Rejected", 0] === 1];

goodCore = <|"E" -> <||>, "C" -> <||>, "BBar" -> <||>,
  "RootSquares" -> <||>, "RootLogDerivatives" -> <||>|>;
check["N3 a later GOOD build for the same key succeeds and is cached",
  intern["Core", negKey, Function[goodCore]] === goodCore &&
    internProbe["Core", negKey] === goodCore];

check["N4 a MALFORMED core (no $Failed, but members missing) is refused too",
  Module[{key = {"t_multiquadratic_prepare_core", "N4"}},
    intern["Core", key, Function[<|"E" -> <||>|>]] === <|"E" -> <||>|> &&
      MissingQ[internProbe["Core", key]]]];

(* ------------------------------------------------------------------ *)
(* F1-F3  fault injection: the first early-core build fails             *)
(* ------------------------------------------------------------------ *)

(* the injection replaces the interned TENSOR compiler for the duration,
   so the core build fails exactly the way a field refusal would make it
   fail, and every other route is untouched *)
(* The whole definition is replaced for the duration -- not prepended to
   -- because Wolfram re-orders DownValues by specificity on assignment
   and a prepended conditional rule is not guaranteed to be tried first.
   The stub fails the way a genuine field refusal fails: THROUGH the
   intern layer, so the test exercises exactly the path that used to
   store $Failed under the core key. *)
(* DownValues has attribute HoldAll: DownValues[coreSymbol] would read the
   TEST VARIABLE's own (empty) down values and the patch would silently
   land on nothing.  With[] injects the resolved symbol. *)
coreSymbol = mq["multiquadraticStripCompileCoreRecord"];
savedCore = With[{sym = coreSymbol}, DownValues[sym]];
check["F0 the fault-injection point has a definition to replace",
  savedCore =!= {}];
faultFired = 0;
With[{sym = coreSymbol},
  DownValues[sym] = {
    HoldPattern[sym[strip_, roots_, vars_, ep_, reused_, key_, cache_]] :>
      (faultFired++; intern["Core", key, Function[$Failed]])}];

clearCaches[];
prepFaulted = prepare[record, frame, Sequence @@ prepareArgs,
  "CompileCore" -> True];
With[{sym = coreSymbol}, DownValues[sym] = savedCore];

check["F1 the fault fired and prepare still succeeded via the fallback",
  faultFired > 0 &&
    Lookup[prepFaulted, "Status", None] === "PreparedMultiquadraticStripV1"];

faultedKey = coreKeyOf[prepFaulted, {x, y}, eps];
check["F2 the Core pool holds NO negative entry for the faulted key",
  faultedKey =!= $Failed && MissingQ[internProbe["Core", faultedKey]] &&
    Lookup[Lookup[internStatistics[], "Core", <||>], "Rejected", 0] >= 1];

asmAfterFault = compile[prepFaulted, "PreparationValidated" -> True,
  "ForcingChannels" -> Lookup[prepFaulted, "ForcingChannels", Automatic]];
check["F3 the compile that follows rebuilds the core and succeeds",
  Lookup[asmAfterFault, "Status", None] === "CompiledMultiquadraticStripV1" &&
    asmAfterFault["AssemblyFingerprint"] === asmCore["AssemblyFingerprint"]];
check["F3b the faulted preparation is SameQ to the unfaulted one, up to \
channel-path telemetry",
  SameQ[KeyDrop[prepFaulted, telemetryKeys], KeyDrop[prepCore, telemetryKeys]]];

(* ------------------------------------------------------------------ *)
(* D1-D5  cooperative deadline inside prepare                           *)
(* ------------------------------------------------------------------ *)

clearCaches[];
prepNoOption = prepare[record, frame, Sequence @@ prepareArgs];
clearCaches[];
prepInfinity = prepare[record, frame, Sequence @@ prepareArgs,
  "Deadline" -> Infinity];
check["D1 Deadline -> Infinity is byte-identical to passing no option",
  SameQ[prepNoOption, prepInfinity]];

expired = prepare[record, frame, Sequence @@ prepareArgs,
  "Deadline" -> AbsoluteTime[] - 1];
check["D2 an expired deadline is a typed BudgetExhausted naming a \
Preparation substage",
  Lookup[expired, "Status", None] === "BudgetExhausted" &&
    StringQ[Lookup[expired, "Stage", None]] &&
    StringStartsQ[Lookup[expired, "Stage", ""], "Preparation:"] &&
    TrueQ[Lookup[expired, "Resumable", False]]];

check["D3 an invalid deadline is a caller error and outranks the budget",
  Lookup[prepare[record, frame, Sequence @@ prepareArgs,
    "Deadline" -> "soon"], "Status", None] === "InvalidDeadline"];

(* the INTERIOR boundary: a deadline placed inside the measured cost of
   this very preparation *)
clearCaches[];
{baseSeconds, ignored} = AbsoluteTiming[
  prepare[record, frame, Sequence @@ prepareArgs]];
clearCaches[];
interior = prepare[record, frame, Sequence @@ prepareArgs,
  "Deadline" -> AbsoluteTime[] + baseSeconds/2];
check["D4 a deadline expiring mid-preparation stops typed, not by exception",
  Lookup[interior, "Status", None] === "BudgetExhausted" &&
    StringStartsQ[Lookup[interior, "Stage", ""], "Preparation:"]];

check["D5 the interior checkpoint throws when expired and is silent at \
Infinity",
  Module[{thrown, quiet},
    thrown = Catch[
      Block[{FeynFacet`Private`$multiquadraticStripActiveDeadline =
          AbsoluteTime[] - 1},
        deadlineCheckpoint["ForcingChannels", <|"Entry" -> 3, "Of" -> 9|>]],
      deadlineTag, Function[{payload, tag}, payload]];
    quiet = Catch[
      Block[{FeynFacet`Private`$multiquadraticStripActiveDeadline = Infinity},
        deadlineCheckpoint["ForcingChannels", <|"Entry" -> 3, "Of" -> 9|>]],
      deadlineTag, Function[{payload, tag}, "THREW"]];
    AssociationQ[thrown] && Lookup[thrown, "Entry", None] === 3 &&
      Lookup[thrown, "Substage", None] === "ForcingChannels" &&
      quiet === False]];

(* ------------------------------------------------------------------ *)
(* O1-O2  option plumbing (Codex P2)                                    *)
(* ------------------------------------------------------------------ *)

check["O1 CompileCore is a public option of the top-level solver",
  MemberQ[Keys[Association[
    Options[mq["solveEpsFormStripMultiquadratic"]]]], "CompileCore"]];

check["O2 the option list declares Deadline exactly once",
  Count[Options[mq["solveEpsFormStripMultiquadratic"]],
    HoldPattern["Deadline" -> _] | HoldPattern["Deadline" :> _]] === 1];

check["O3 CompileShards is NOT a public option (private test control)",
  ! MemberQ[Keys[Association[
    Options[mq["solveEpsFormStripMultiquadratic"]]]], "CompileShards"] &&
    MemberQ[Keys[Association[Options[mq["multiquadraticStripCompile"]]]],
      "CompileShards"]];

(* The DEFAULT is a measured decision and a test protects it.  Cold on
   the real CF300 (12,9) descriptor, both routes reach the same
   byte-identical preparation and the same assembly fingerprints, and:
     CompileCore -> False  prepare 2710.9 s + compile 91.3 s = 2802.2 s
     CompileCore -> True   prepare 2810.7 s + compile 89.8 s = 2900.5 s
   Building the core early cost 99.8 s and returned 1.5 s, because the
   compiler already receives prepare's sealed channels and its entire
   core stage is 0.16 s of that 91.3 s.  So prepare's Automatic is OFF;
   the compiler's own Automatic stays ON. *)
clearCaches[];
defaultPrep = prepare[record, frame, Sequence @@ prepareArgs];
check["O5 prepare's early core is OFF by default: a default preparation \
builds no core at all",
  Lookup[defaultPrep, "Status", None] === "PreparedMultiquadraticStripV1" &&
    Lookup[Lookup[internStatistics[], "Core", <||>], "Misses", 0] === 0 &&
    Lookup[Lookup[internStatistics[], "Core", <||>], "Entries", 0] === 0];
check["O5b the default preparation is SameQ to the explicit CompileCore \
-> False preparation",
  SameQ[KeyDrop[defaultPrep, telemetryKeys],
    KeyDrop[prepPlain, telemetryKeys]]];
check["O5c the compiler's own core cache is still ON by default",
  Module[{asm},
    clearCaches[];
    asm = compile[prepare[record, frame, Sequence @@ prepareArgs],
      "PreparationValidated" -> True];
    Lookup[asm, "Status", None] === "CompiledMultiquadraticStripV1" &&
      TrueQ[Lookup[Lookup[asm, "CompileStatistics", <||>], "CompileCore",
        False]]]];

solveSource = StringJoin[Import[FeynFacet`Private`feynFacetPrivateFile[#], "Text"] & /@
  Select[Lookup[Get[FileNameJoin[{root, "FeynFacet", "Private", "LoadOrder.wl"}]],
    "EpsForm"], StringStartsQ[FileNameTake[#], "MultiquadraticStrip"] &]];  (* all eight solver files *)
check["O4 the top level forwards the compile-architecture options to the \
compiler",
  StringContainsQ[solveSource,
    "\"CompileCore\" -> OptionValue[\"CompileCore\"]"] &&
    StringContainsQ[solveSource,
      "\"LetterChannels\" -> OptionValue[\"LetterChannels\"]"] &&
    StringContainsQ[solveSource,
      "\"LegacyCompiler\" -> OptionValue[\"LegacyCompiler\"]"]];

(* ------------------------------------------------------------------ *)
(* T1-T3  telemetry follows Verbose and pairs its lines                 *)
(* ------------------------------------------------------------------ *)

SetAttributes[capture, HoldFirst];
capture[expr_] := Module[{file = CreateTemporary[], stream, result, text},
  stream = OpenWrite[file];
  result = Block[{$Output = {stream}}, expr];
  Close[stream];
  text = Quiet[Check[Import[file, "Text"], ""]];
  Quiet[DeleteFile[file]];
  {result, If[StringQ[text], text, ""]}];

clearCaches[];
{quietResult, quietText} = capture[
  prepare[record, frame, Sequence @@ prepareArgs]];
check["T1 a library call is QUIET by default",
  Lookup[quietResult, "Status", None] === "PreparedMultiquadraticStripV1" &&
    ! StringContainsQ[quietText, "[multiquadratic]"]];

clearCaches[];
{loudResult, loudText} = capture[
  Block[{FeynFacet`Private`$multiquadraticStripStageLog = True},
    prepare[record, frame, Sequence @@ prepareArgs]]];
check["T2 the stage lines appear when the stage log is enabled",
  Lookup[loudResult, "Status", None] === "PreparedMultiquadraticStripV1" &&
    StringContainsQ[loudText, "[multiquadratic] prepare: forcing channel"] &&
    StringContainsQ[loudText, " start"] &&
    StringContainsQ[loudText, " done"]];

check["T3 every stage START printed has a matching stage DONE",
  Module[{starts, dones},
    starts = Sort[StringTrim /@ StringCases[loudText,
      "[multiquadratic] " ~~ s : Except["\n"] .. ~~ " start" :> s]];
    dones = Sort[StringTrim /@ StringCases[loudText,
      "[multiquadratic] " ~~ s : Except["\n"] .. ~~ " done" :> s]];
    starts =!= {} && starts === dones]];

check["T4 FACET_MQ_STAGE_LOG=Off silences an enabled stage log",
  Module[{text},
    SetEnvironment["FACET_MQ_STAGE_LOG" -> "Off"];
    text = Last[capture[
      Block[{FeynFacet`Private`$multiquadraticStripStageLog = True},
        stageStart["probe", <|"a" -> 1|>]; stageDone["probe"]]]];
    SetEnvironment["FACET_MQ_STAGE_LOG" -> "On"];
    ! StringContainsQ[text, "[multiquadratic] probe"]]];

check["T5 FACET_MQ_STAGE_LOG=On forces a disabled stage log on",
  Module[{text},
    text = Last[capture[
      Block[{FeynFacet`Private`$multiquadraticStripStageLog = False},
        stageStart["probe", <|"a" -> 1|>]; stageDone["probe"]]]];
    SetEnvironment["FACET_MQ_STAGE_LOG" -> ""];
    StringContainsQ[text, "[multiquadratic] probe start"] &&
      StringContainsQ[text, "[multiquadratic] probe done"]]];

Print["t_multiquadratic_prepare_core: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
