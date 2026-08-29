#!/usr/bin/env wolframscript
(* Resume semantics of the sector driver's in-sector regulator
   factorization (Codex bihourly assessment 2026-08-25 08:30, P1).

   BEFORE 2026-08-25 the success path transformed A, S and SInverse and
   appended a RegulatorFactorizations record, but

     - never removed the obsolete "Stop" key, so the NEXT persisted state
       still advertised the terminal condition that had just been solved;
     - returned without writing the state at all, so the next atomic
       write was only after the whole sector's strip work: an
       interruption in between lost an accepted 153.9 s factorization and
       repeated the 134.1 s grade decomposition on resume.

   The acceptance criteria of this test are the review's own: starting
   from a state that carries the old typed stop, after ONE accepted
   factorization the PERSISTED state is eps-factored, carries the
   factorization record, and has no unresolved Stop; and a second
   invocation does not re-enter the factorization routine (the
   already-eps-factored fast path).  A stale stop whose rows do NOT match
   must survive: the clearing is a resolution, not a cleanup.

   The driver's own source text is evaluated here -- the definitions are
   extracted from Scripts/family_epsform_sector.wls, never copied. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]]);

x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];

(* ------------------------------------------------------------------ *)
(* the driver's own definitions, extracted from its source              *)
(* ------------------------------------------------------------------ *)
driverPath = FileNameJoin[{root, "Scripts", "family_epsform_sector.wls"}];
driverSource = Import[driverPath, "Text"];
check["the sector driver source is readable", StringQ[driverSource]];

extractSpan[source_String, head_String, terminator_String] :=
  Module[{heads = StringPosition[source, head], from, to},
    If[heads === {}, Return[$Failed]];
    from = heads[[1, 1]];
    to = SelectFirst[StringPosition[source, terminator], #[[1]] > from &, None];
    If[to === None, $Failed, StringTake[source, {from, to[[2]]}]]];

putAtomicText = extractSpan[driverSource, "putAtomic[expr_, file_] :=",
  "OverwriteTarget -> True]];"];
checkpointText = extractSpan[driverSource, "staleStripCheckpointFile[m_] :=",
  "\"_strip_state.wl\"}];"];
resolvableText = extractSpan[driverSource, "$regulatorResolvableStops = {",
  "\"RegulatorPropagationRejected\"};"];
staleStopText = extractSpan[driverSource, "staleRegulatorStop[m_] :=",
  "Missing[\"NoMatchingStop\"]]];"];
factorText = extractSpan[driverSource, "factorTruncated[m_] := Module[",
  "\n  True];"];
check["the driver's regulator-resume definitions extract as expressions",
  AllTrue[{putAtomicText, checkpointText, resolvableText, staleStopText,
    factorText}, StringQ]];
check["the driver has EXACTLY ONE factorTruncated definition (no parallel path)",
  StringCount[driverSource, "factorTruncated[m_] := Module["] === 1];
(* the sector loop must no longer carry its own checkpoint deletion:
   factorTruncated owns discard-then-persist, in that order *)
check["the sector loop no longer deletes the strip checkpoint itself",
  StringFreeQ[driverSource,
    "If[FileExistsQ[cp], DeleteFile[cp]; log[\"  strip checkpoint of sector \""]];

Scan[ToExpression, {putAtomicText, checkpointText, resolvableText,
  staleStopText, factorText}];

(* ------------------------------------------------------------------ *)
(* a real, small factorization problem for the leading 2x2 prefix       *)
(* ------------------------------------------------------------------ *)
dl[L_] := Map[Together, {D[Log[L], x], D[Log[L], y]}];
kA = {{1, 0}, {0, -1}}; kB = {{0, 1}, {2, 0}};
canonical2 = Table[
  eps (kA dl[x][[mu]] + kB dl[1 - x - y][[mu]]), {mu, 2}];
tPlanted = {{1, eps}, {0, 1 + 3 eps}};
tPlantedInverse = Map[Together, Inverse[tPlanted], {2}];
prefix = Table[
  Map[Together, tPlanted . canonical2[[mu]] . tPlantedInverse, {2}], {mu, 2}];
check["the planted prefix is NOT eps-factored",
  ! AllTrue[Flatten[prefix],
    TrueQ[Together[#] === 0] || FreeQ[Together[#/eps], eps] &]];

(* a third master fed by the prefix: block-lower-triangular, structurally
   zero upper right (the propagation helper's precondition) *)
feed = {eps/(x (1 - x - y)), eps (1 + eps)/(y (1 - x - y))};
buildA[pre_] := Table[
  Join[
    Table[Append[pre[[mu, i]], 0], {i, 2}],
    {{feed[[mu]], 2 feed[[mu]], eps dl[y][[mu]]}}],
  {mu, 2}];
A0 = buildA[prefix];
check["the assembled 3x3 connection is block-lower-triangular",
  AllTrue[Flatten[A0[[All, 1 ;; 2, 3]]], TrueQ[# === 0] &]];

(* the package routine on its own, before the driver wrapper runs it *)
standalone = FeynFacet`FactorFamilyRegulatorDependence[
  prefix, {x, y}, eps, "PointLadder" -> {2, 4}, "TimeLimit" -> 120];
check["the package factorizes the planted prefix (fixture precondition)",
  AssociationQ[standalone] && standalone["Status"] === "OK"];

(* ------------------------------------------------------------------ *)
(* the driver's stand-in environment                                    *)
(* ------------------------------------------------------------------ *)
scratchRoot = FileNameJoin[{$TemporaryDirectory,
  "ft_regfactor_resume_" <> ToString[$ProcessID]}];
Quiet[DeleteDirectory[scratchRoot, DeleteContents -> True]];
CreateDirectory[scratchRoot, CreateIntermediateDirectories -> True];

Global`scratch = scratchRoot;
Global`family = "CFTEST";
Global`stateFile = FileNameJoin[{scratchRoot, "sector_state_CFTEST.wl"}];
Global`bounds = {{1, 2}, {3, 3}};
Global`nMasters = 3;
Global`algebraicFrameQ = False;
Global`chart = <||>;
Global`productionQ = False;
Global`sectorBudget = 600;
Global`xx = x; Global`yy = y; Global`ee = eps;
Global`epsFormQ[m_] := AllTrue[Flatten[m],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/eps], eps] &];
logLines = {};
Global`log[a___] := AppendTo[logLines,
  StringJoin[ToString[#, InputForm] & /@ {a}]];

checkpointFile = FileNameJoin[{scratchRoot, "CFTEST_2_strip_state.wl"}];
freshState[stopRows_] := (
  Global`sectorDeadline = AbsoluteTime[] + 600;
  Quiet[DeleteFile[Global`stateFile]];
  Export[checkpointFile, "stale strip checkpoint", "Text"];
  logLines = {};
  Global`state = <|"A" -> A0, "S" -> IdentityMatrix[3],
    "SInverse" -> IdentityMatrix[3], "SectorCertificates" -> {},
    "Stop" -> <|"Status" -> "NeedsMultiquadraticRegulatorFactorization",
      "Rows" -> stopRows, "RootIndices" -> {1, 2, 3}|>|>);

check["the driver's checkpoint path is the NEXT sector's strip state",
  Global`staleStripCheckpointFile[1] === checkpointFile];

(* ---- (a) the matching stale stop, one accepted factorization ---- *)
freshState[1];
check["the fixture starts from a state carrying the old typed stop",
  Global`state["Stop"]["Status"] === "NeedsMultiquadraticRegulatorFactorization" &&
    FileExistsQ[checkpointFile]];
{firstSeconds, firstResult} = AbsoluteTiming[Global`factorTruncated[1]];
Print["factorTruncated[1]: ", firstResult, " in ", Round[firstSeconds, 0.1], " s"];
Scan[Print["  driver log | ", #] &, logLines];

check["the factorization is applied (factorTruncated returns True)",
  TrueQ[firstResult]];
check["the IN-MEMORY state's prefix is eps-factored",
  Global`epsFormQ[Global`state["A"][[1, 1 ;; 2, 1 ;; 2]]] &&
    Global`epsFormQ[Global`state["A"][[2, 1 ;; 2, 1 ;; 2]]]];
check["the resolved stop is removed from the in-memory state",
  ! KeyExistsQ[Global`state, "Stop"]];
check["the stale strip checkpoint of the next sector is deleted",
  ! FileExistsQ[checkpointFile]];
check["the driver reports both the discard and the resolution",
  AnyTrue[logLines, StringContainsQ[#, "strip checkpoint of sector"] &&
      StringContainsQ[#, "discarded (connection transformed)"] &] &&
    AnyTrue[logLines, StringContainsQ[#, "stale"] &&
      StringContainsQ[#, "cleared and the resolution recorded"] &]];

(* THE RESUME CRITERION: what is ON DISK before the next strip begins *)
check["the state was persisted before returning (the file exists)",
  FileExistsQ[Global`stateFile]];
persisted = If[FileExistsQ[Global`stateFile], Get[Global`stateFile], $Failed];
check["the persisted state is an Association", AssociationQ[persisted]];
check["the PERSISTED prefix is eps-factored",
  AssociationQ[persisted] &&
    Global`epsFormQ[persisted["A"][[1, 1 ;; 2, 1 ;; 2]]] &&
    Global`epsFormQ[persisted["A"][[2, 1 ;; 2, 1 ;; 2]]]];
check["the PERSISTED state carries no unresolved Stop",
  AssociationQ[persisted] && ! KeyExistsQ[persisted, "Stop"]];
record = If[AssociationQ[persisted],
  Last[Lookup[persisted, "RegulatorFactorizations", {<||>}]], <||>];
check["the PERSISTED state carries the factorization record for rows 1",
  AssociationQ[record] && record["Rows"] === 1 &&
    record["Method"] === "ExactRationalSamples" &&
    NumericQ[record["Seconds"]] &&
    AssociationQ[Lookup[record, "PropagationStatistics", None]]];
check["the record states which stop the factorization resolved",
  AssociationQ[record] && AssociationQ[Lookup[record, "ResolvedStop", None]] &&
    record["ResolvedStop"]["ClearedStatus"] ===
      "NeedsMultiquadraticRegulatorFactorization" &&
    record["ResolvedStop"]["Rows"] === 1 &&
    record["ResolvedStop"]["ResolvedBy"] === "ExactRationalSamples" &&
    StringQ[record["ResolvedStop"]["ResolvedAt"]]];
check["the persisted transformation and its inverse are still mutual inverses",
  AssociationQ[persisted] &&
    AllTrue[Flatten[Map[Together,
      persisted["S"] . persisted["SInverse"] - IdentityMatrix[3], {2}]],
      TrueQ[# === 0] &]];
(* the gauge identity on the persisted objects: S^-1 A_original S is the
   persisted connection (S is constant, so no dS term) *)
check["the persisted connection is the exact conjugate of the input",
  AssociationQ[persisted] && AllTrue[Flatten[Table[
    Together[Sum[persisted["SInverse"][[i, a]] A0[[mu, a, b]] persisted["S"][[b, j]],
      {a, 3}, {b, 3}] - persisted["A"][[mu, i, j]]], {mu, 2}, {i, 3}, {j, 3}]],
    TrueQ[# === 0] &]];

(* ---- (b) the second invocation must not re-enter the factorizer ---- *)
factorizerEntries = 0;
secondResult = Block[{FeynFacet`FactorFamilyRegulatorDependence,
    FeynFacet`FactorFamilyRegulatorDependenceInFrame},
  FeynFacet`FactorFamilyRegulatorDependence[___] :=
    (factorizerEntries++; <|"Status" -> "TestStandInMustNotBeCalled"|>);
  FeynFacet`FactorFamilyRegulatorDependenceInFrame[___] :=
    (factorizerEntries++; <|"Status" -> "TestStandInMustNotBeCalled"|>);
  Global`factorTruncated[1]];
check["a second invocation returns False (nothing applied)",
  secondResult === False];
check["a second invocation does NOT re-enter the factorization routine \
(already-eps-factored fast path, so no Libra)",
  factorizerEntries === 0];

(* ---- (c) a stale stop that does not match is NOT cleared ---- *)
freshState[99];
thirdResult = Global`factorTruncated[1];
check["a factorization still applies with a non-matching stop present",
  TrueQ[thirdResult]];
check["a stop for OTHER rows survives (clearing is a resolution, not a cleanup)",
  AssociationQ[Lookup[Global`state, "Stop", None]] &&
    Global`state["Stop"]["Rows"] === 99];
persisted3 = If[FileExistsQ[Global`stateFile], Get[Global`stateFile], $Failed];
check["the non-matching stop is persisted unchanged",
  AssociationQ[persisted3] && AssociationQ[Lookup[persisted3, "Stop", None]] &&
    persisted3["Stop"]["Rows"] === 99];
record3 = If[AssociationQ[persisted3],
  Last[Lookup[persisted3, "RegulatorFactorizations", {<||>}]], <||>];
check["the record says no stale stop was resolved",
  AssociationQ[record3] && MissingQ[Lookup[record3, "ResolvedStop", None]]];

(* ---- (d) Production consumes residue metadata, not epsFormQ ---------- *)
freshState[99];
Global`state["StripSolvers"] = {
  <|"Sector" -> 1, "LowerSector" -> 0,
    "ResiduesEpsFree" -> False|>};
Global`productionQ = True;
precheckCalls = 0;
productionResult = Block[{Global`epsFormQ},
  Global`epsFormQ[___] := (precheckCalls++; False);
  Global`factorTruncated[1]];
check["Production routes from accepted residue metadata without a prefix epsFormQ",
  TrueQ[productionResult] && precheckCalls === 0];
Global`productionQ = False;

(* ---- (e) the driver threads its sector deadline into the stage ---- *)
check["the driver hands the sector deadline to both factorization routes",
  StringCount[driverSource,
    "\"TimeLimit\" -> Min[sectorBudget, 600], \"Deadline\" -> sectorDeadline"] === 2];
check["Production defers the propagation inverse replay to the family certificate",
  StringContainsQ[driverSource,
    "Lookup[factor, \"PropagationSeal\", <||>], futureAMode, ! productionQ"]];
check["the driver has a typed, resumable stop for a regulator budget expiry",
  StringContainsQ[driverSource,
    "\"Status\" -> \"RegulatorFactorizationBudgetExhausted\""]];

Quiet[DeleteDirectory[scratchRoot, DeleteContents -> True]];
Print["t_family_regulator_factor_resume: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
