#!/usr/bin/env wolframscript
(* PHASE 4 of the CF300 (12,9) prepare-cost attribution.

   Phases 1-3 measured every stage of prepare on the CURRENT code:

     forcing channel decomposition   1400.5 s
     everything else, end to end       39.2 s   (phase 3, A9)
     ------------------------------------------
     current prepare                 1439.7 s

   against a REFERENCE prepare of 2710.9 s measured on 2026-08-25 at
   15:58, before the hardening wave.  The strip is byte-identical (both
   runs report StripLeafCount 1133532) and the stage inventory is now
   complete, so the ~1271 s difference cannot be an unmeasured stage.
   It has to be the DECOMPOSITION ITSELF costing less than it used to.

   The only change this wave made to that path is the recursive
   quadratic-tower inversion: multiquadraticFieldDecompose inverts the
   denominator channel vector once per entry through
   multiquadraticFieldInverse, which used to build the 2^r x 2^r
   multiplication matrix and solve it symbolically and now divides down
   the tower instead.  $multiquadraticFieldInverseMethod selects the
   route and BOTH are held to the same exact product check, so this is a
   cost comparison between two accepted answers, never a correctness
   question.

   THE MEASUREMENT IS DELIBERATELY BOUNDED: ONE forcing entry, both
   routes, not the whole 8-entry decomposition.  One entry of this block
   is ~1/8 of 1400.5 s on the tower route, so the pair costs minutes
   rather than the ~75 minutes a full two-route comparison would.  The
   whole-stage figure is then an EXTRAPOLATION and is labelled as such;
   the per-entry figures are measurements.

   USAGE
     cf300_inverse_route.wls gate    cheap predictive gate, seconds
     cf300_inverse_route.wls cf300   the real entry, ~10 min, one kernel

   The real mode REFUSES to start until the gate has left its record. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
here = DirectoryName[ExpandFileName[$InputFileName]];
mode = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "gate"];
If[! MemberQ[{"gate", "cf300"}, mode],
  Print["usage: cf300_inverse_route.wls [gate|cf300]"]; Exit[64]];
out = FileNameJoin[{here, "cf300_inverse_route_" <> mode <> "_result.wl"}];
$t0 = AbsoluteTime[];
say[a___] := WriteString["stdout",
  ToString[Round[AbsoluteTime[] - $t0, 0.01]], "s | ",
  StringJoin[If[StringQ[#], #, ToString[#, InputForm]] & /@ {a}], "\n"];

If[mode === "cf300" &&
    ! FileExistsQ[FileNameJoin[{here, "cf300_inverse_route_gate_result.wl"}]],
  say["!! refusing: the cheap gate has not been run.  Run \
`cf300_inverse_route.wls gate` first."];
  Exit[3]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticStripSolve.wl"}]];
mq[n_String] := Symbol["FeynFacet`Private`" <> n];

If[mode === "cf300",
  FeynFacet`TransportFamilyChartLoad[FileNameJoin[{root,
     "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
     "TransportFamilyCharts.wl"}]];
  frame = FeynFacet`TransportFamilyChart["CF300"];
  stripFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
     "UU_08_10_canonical", "FamilyEpsFormsSolving",
     "FrozenTestFixtures_2026-08-25", "cf300_frozen_strip_12_9_input.wl"}];
  If[! FileExistsQ[stripFile], say["!! missing ", stripFile]; Exit[2]];
  record = FeynFacet`FamilyArtifactRead[stripFile, "Global`"],
  Clear[x, y, eps, v, w, cx, cy];
  frame = BuildAlgebraicTransportFrame[{v, w, 1 + v + w}, {v, w}, {cx, cy}];
  (* The gate fixture must be a GENUINE element of the declared field,
     or the census returns rank 0, the decomposition returns $Failed and
     the gate certifies nothing.  (First attempt did exactly that: it
     used radicals that were not the frame's declared roots.  The gate
     caught it, which is what a gate is for.)  The roots are therefore
     taken FROM THE FRAME and the entry is built out of them, with a
     nontrivial denominator so the inversion path is actually entered. *)
  gateRoots = Lookup[FeynFacet`Private`multiquadraticStripRootOrder[
    frame, {x, y}, {1, 2}, eps]["Roots"], "Root", {}];
  If[Length[gateRoots] =!= 2,
    Print["!! gate fixture could not resolve two frame roots"]; Exit[2]];
  record = <|"Family" -> "GATE", "Sector" -> 2, "LowerSector" -> 1,
    "Variables" -> {x, y}, "Regulator" -> eps,
    "Strip" -> {{{{1}}, {{eps}}}, {{{0}}, {{0}}},
      {{{(1 + x + gateRoots[[1]] + y gateRoots[[2]])/
         (2 - y + gateRoots[[1]] gateRoots[[2]])}},
       {{(2 - y)/(3 + x + gateRoots[[2]])}}}}|>];

variables = record["Variables"]; regulator = record["Regulator"];
strip = record["Strip"]; bbar = strip[[3]];
allRoots = mq["transportChartCurrentRoots"][frame, variables];
census = mq["multiquadraticStripRootCensus"][strip, allRoots];
order = mq["multiquadraticStripRootOrder"][frame, variables,
  census["RootIndices"], regulator];
roots = order["Roots"];
say["mode ", mode, "; rank ", Length[roots], "; BBar ", Dimensions[bbar],
  " leaves ", LeafCount[bbar]];

(* ONE entry: the first component of the forcing, which is the object
   multiquadraticStripDecomposeForcing maps over *)
entry = bbar[[1, 1, 1]];
say["entry leaves ", LeafCount[entry]];

measure[method_String] := Module[{seconds, channels},
  mq["multiquadraticStripCompileCacheClear"][];
  {seconds, channels} = AbsoluteTiming[
    Block[{FeynFacet`Private`$multiquadraticFieldInverseMethod = method},
      mq["multiquadraticFieldDecompose"][entry, roots]]];
  say[method, ": ", Round[seconds, 0.1], " s, channels ",
    If[ListQ[channels], Length[channels], $Failed]];
  {seconds, channels}];

{towerSeconds, towerChannels} = measure["RecursiveTower"];
{solveSeconds, solveChannels} = measure["LinearSolve"];

identical = ListQ[towerChannels] && ListQ[solveChannels] &&
  AllTrue[Together /@ (towerChannels - solveChannels), TrueQ[# === 0] &];
say["the two routes agree exactly on this entry: ", identical];
ratio = If[towerSeconds > 0, solveSeconds/towerSeconds, Missing["Zero"]];
say["per-entry speedup (LinearSolve / RecursiveTower): ",
  If[NumericQ[ratio], Round[ratio, 0.01], ratio], "x"];

If[mode === "cf300",
  say["MEASURED per entry: tower ", Round[towerSeconds, 0.1],
    " s, linear solve ", Round[solveSeconds, 0.1], " s"];
  say["EXTRAPOLATED to the 8-entry stage (NOT measured): tower ",
    Round[8 towerSeconds, 0.1], " s vs linear solve ",
    Round[8 solveSeconds, 0.1], " s; the measured whole stage on the ",
    "tower route was 1400.5 s"];
  say["the reference prepare implies a pre-wave decomposition of ",
    Round[2710.9 - 39.2, 0.1], " s"]];

(* A FAILING GATE MUST NOT WRITE THE RECORD THAT UNLOCKS THE REAL RUN.
   The first gate attempt returned $Failed channels and still wrote its
   result file, which would have let the 10-minute run start on a
   harness that certifies nothing. *)
If[! (identical && ListQ[towerChannels] && FreeQ[towerChannels, $Failed] &&
      Length[towerChannels] === 2^Length[roots] && Length[roots] > 0),
  say["!! GATE FAILED: rank ", Length[roots], ", routes agree ", identical,
    ", channels valid ",
    ListQ[towerChannels] && FreeQ[towerChannels, $Failed],
    " -- no record written, the real run stays locked"];
  Exit[4]];

Put[<|"Schema" -> "CF300InverseRouteComparisonV1", "Mode" -> mode,
  "Descriptor" -> {record["Family"], record["Sector"],
    record["LowerSector"]},
  "StripSHA256" -> If[mode === "cf300",
    FileHash[stripFile, "SHA256", "HexString"], Missing["SyntheticFixture"]],
  "RootRank" -> Length[roots],
  "EntryLeafCount" -> LeafCount[entry],
  "RecursiveTowerSeconds" -> towerSeconds,
  "LinearSolveSeconds" -> solveSeconds,
  "RoutesAgreeExactly" -> identical,
  "PerEntrySpeedup" -> ratio,
  "EntryCount" -> If[mode === "cf300", 8, 1],
  "ExtrapolatedTowerStageSeconds" -> 8 towerSeconds,
  "ExtrapolatedLinearSolveStageSeconds" -> 8 solveSeconds,
  "MeasuredTowerStageSeconds" -> If[mode === "cf300", 1400.5,
    Missing["SyntheticFixture"]],
  "ReferencePrepareSeconds" -> If[mode === "cf300", 2710.9,
    Missing["SyntheticFixture"]],
  "PrepareWithoutDecompositionSeconds" -> If[mode === "cf300", 39.2,
    Missing["SyntheticFixture"]],
  "PeakMemoryBytes" -> MaxMemoryUsed[],
  "RunAt" -> DateString["ISODateTime"]|>, out];
say["written ", out];
Exit[0];
