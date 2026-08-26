#!/usr/bin/env wolframscript
(* Old vs new FIRST-CALL PREPARE on the REAL CF300 (12,9) descriptor.

   Two routes, each from a COLD cache, on the same letters (built once
   and supplied to both, so the only difference measured is the forcing
   channel decomposition and what it leaves behind):

     HEAD   "CompileCore" -> False -- prepare decomposes the forcing on
            its own, the compiler afterwards decomposes E, C and BBar;
     NEW    "CompileCore" -> True  -- prepare consumes the sealed compile
            core, and the compiler finds it already built.

   Reported per route: prepare seconds, compile seconds, prepare+compile
   seconds (Codex 14:30: moving work into prepare must not be allowed to
   make compile look faster), Core pool hits/misses, peak RSS.

   Equivalence: the two preparations must be SameQ up to the
   channel-path telemetry counters, and the two compiled assemblies must
   agree on every semantic fingerprint. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
snap = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/opt/snap";
out = "/tmp/claude-1000/-home-maxzhang/9e941be4-c161-4634-89fb-8d0804f16b66/scratchpad/opt/cf300_prepare_result.wl";
$t0 = AbsoluteTime[];
say[a___] := (WriteString["stdout",
   ToString[Round[AbsoluteTime[] - $t0, 0.01]], "s | ",
   StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}], "\n"];
  Run["true"]);
rss[] := Quiet[Check[ToExpression[StringTrim[
   ReadString["!grep VmRSS /proc/" <> ToString[$ProcessID] <> "/status | \
tr -dc '0-9'"]]]/1024., -1]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];
prepare = mq["multiquadraticStripPrepare"];
compile = mq["multiquadraticStripCompile"];
clearCaches = mq["multiquadraticStripCompileCacheClear"];
internStats = mq["multiquadraticStripInternStatistics"];

FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
   "Results", "UU_08_10_canonical", "TransportFamilyCharts.wl"}]];
chart = FeynFacet`TransportFamilyChart["CF300"];
record = FeynFacet`FamilyArtifactRead[
   FileNameJoin[{snap, "CF300", "sector_CF300_standard",
     "CF300_12_9_input.wl"}], "Global`"];
say["record read: ", {record["Sector"], record["LowerSector"]},
  ", strip leaves ", LeafCount[record["Strip"]], ", RSS ", rss[], " MB"];

variables = record["Variables"]; regulator = record["Regulator"];
allRoots = mq["transportChartCurrentRoots"][chart, variables];
census = mq["multiquadraticStripRootCensus"][record["Strip"], allRoots];
order = mq["multiquadraticStripRootOrder"][chart, variables,
   census["RootIndices"], regulator];
roots = order["Roots"];
say["root rank ", Length[roots], ", squares ", Lookup[roots, "RootSquare", {}]];

(* the alphabet ONCE, so both routes prepare the same ansatz *)
{letterSeconds, letterData} = AbsoluteTiming[
  mq["multiquadraticStripCandidateLetters"][record["Strip"], roots,
    variables, regulator, record, "RegulatorSampleCount" -> 2]];
letterRecords = letterData["LetterRecords"];
say["letters (", Round[letterSeconds, 0.1], " s): ",
  Length[letterRecords], " ", letterData["Counts"], ", RSS ", rss[], " MB"];

prepareArgs = {"LetterRecords" -> letterRecords,
  "RootIndices" -> census["RootIndices"]};

runRoute[label_String, coreQ_] := Module[
  {prepSeconds, prep, compSeconds, asm, statsPrep, statsComp, rssPeak},
  clearCaches[];
  say[label, ": prepare start (cold cache), RSS ", rss[], " MB"];
  {prepSeconds, prep} = AbsoluteTiming[
    prepare[record, chart, Sequence @@ prepareArgs, "CompileCore" -> coreQ]];
  statsPrep = internStats[];
  say[label, ": prepare ", Round[prepSeconds, 0.1], " s -> ",
    Lookup[prep, "Status", None], ", unknowns ",
    Lookup[prep, "UnknownCount", None], ", support ",
    Length[Lookup[prep, "GaugeSupport", {}]], ", RSS ", rss[], " MB"];
  If[Lookup[prep, "Status", None] =!= "PreparedMultiquadraticStripV1",
    Return[<|"Label" -> label, "PrepareSeconds" -> prepSeconds,
      "Status" -> Lookup[prep, "Status", None]|>]];
  say[label, ": compile start"];
  {compSeconds, asm} = AbsoluteTiming[
    compile[prep, "PreparationValidated" -> True,
      "ForcingChannels" -> Lookup[prep, "ForcingChannels", Automatic],
      "CompileCore" -> coreQ]];
  statsComp = internStats[];
  rssPeak = rss[];
  say[label, ": compile ", Round[compSeconds, 0.1], " s -> ",
    Lookup[asm, "Status", None], ", total ",
    Round[prepSeconds + compSeconds, 0.1], " s, RSS ", rssPeak, " MB"];
  <|"Label" -> label, "CompileCore" -> coreQ,
    "PrepareSeconds" -> prepSeconds, "CompileSeconds" -> compSeconds,
    "TotalSeconds" -> prepSeconds + compSeconds,
    "Status" -> Lookup[asm, "Status", None],
    "CorePoolAfterPrepare" -> Lookup[statsPrep, "Core", <||>],
    "CorePoolAfterCompile" -> Lookup[statsComp, "Core", <||>],
    "CompileStatistics" -> KeyDrop[
      Lookup[asm, "CompileStatistics", <||>], "Pools"],
    "PeakRSSMB" -> rssPeak,
    "Preparation" -> prep, "Assembly" -> asm|>];

(* 15:57: the HEAD route was measured first and was STOPPED at the time
   box after more than 41 minutes inside prepare alone, still running.
   That is a measured LOWER BOUND, not a completed time.  This run
   measures the NEW route to completion, so the pair is
   "NEW = <measured>" against "HEAD > 41 min". *)
routes = Environment["CF300_ROUTES"];
headRun = If[routes === "NewOnly",
  <|"Label" -> "HEAD (CompileCore False)", "Status" -> "StoppedAtTimeBox",
    "PrepareSeconds" -> Missing["StoppedAfter2470s"],
    "CompileSeconds" -> Missing["NotReached"],
    "TotalSeconds" -> Missing["StoppedAfter2470s"],
    "Preparation" -> <||>, "Assembly" -> <||>|>,
  runRoute["HEAD (CompileCore False)", False]];
newRun = runRoute["NEW (CompileCore True)", True];

telemetryKeys = {"RootFreeFastPathCount", "ChannelPathStatistics"};
equivalent = AssociationQ[Lookup[headRun, "Preparation", None]] &&
  Lookup[headRun, "Preparation", <||>] =!= <||> && SameQ[
  KeyDrop[Lookup[headRun, "Preparation", <||>], telemetryKeys],
  KeyDrop[Lookup[newRun, "Preparation", <||>], telemetryKeys]];
fingerprintsAgree = routes =!= "NewOnly" && AssociationQ[headRun["Assembly"]] &&
  AssociationQ[newRun["Assembly"]] &&
  headRun["Assembly"]["AssemblyFingerprint"] ===
    newRun["Assembly"]["AssemblyFingerprint"] &&
  headRun["Assembly"]["ExactChannelFormsFingerprint"] ===
    newRun["Assembly"]["ExactChannelFormsFingerprint"] &&
  headRun["Assembly"]["CompiledFormsFingerprint"] ===
    newRun["Assembly"]["CompiledFormsFingerprint"];

If[routes === "NewOnly",
  say["EQUIVALENCE not evaluated in this run: the HEAD route was stopped \
at the time box, so there is no second preparation to compare against. \
Equivalence of the two routes is established at fixture scale by \
Tests/t_multiquadratic_prepare_core.wls (E2, E2b, E4)."];
  say["HEAD  prepare > 2470 s (stopped, still running), compile not reached"],
  say["EQUIVALENCE preparation SameQ (up to channel telemetry): ", equivalent];
  say["EQUIVALENCE assembly fingerprints agree: ", fingerprintsAgree];
  say["HEAD  prepare ", Round[headRun["PrepareSeconds"], 0.1],
    " s, compile ", Round[headRun["CompileSeconds"], 0.1],
    " s, total ", Round[headRun["TotalSeconds"], 0.1], " s"]];
say["NEW   prepare ", Round[newRun["PrepareSeconds"], 0.1],
  " s, compile ", Round[newRun["CompileSeconds"], 0.1],
  " s, total ", Round[newRun["TotalSeconds"], 0.1], " s"];

Put[<|"Schema" -> "CF300PrepareCoreMeasurementV1",
  "Descriptor" -> {record["Family"], record["Sector"], record["LowerSector"]},
  "StripLeafCount" -> LeafCount[record["Strip"]],
  "RootRank" -> Length[roots],
  "LetterSeconds" -> letterSeconds,
  "LetterCount" -> Length[letterRecords],
  "LetterCounts" -> letterData["Counts"],
  "Head" -> KeyDrop[headRun, {"Preparation", "Assembly"}],
  "New" -> KeyDrop[newRun, {"Preparation", "Assembly"}],
  "PreparationEquivalent" -> equivalent,
  "AssemblyFingerprintsAgree" -> fingerprintsAgree,
  "HeadAssemblyFingerprint" ->
    Lookup[headRun["Assembly"], "AssemblyFingerprint", None],
  "NewAssemblyFingerprint" ->
    Lookup[newRun["Assembly"], "AssemblyFingerprint", None]|>, out];
say["written ", out];
Exit[0];
