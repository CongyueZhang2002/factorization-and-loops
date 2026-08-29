(* Stage 2: the catalog of rationalizing charts, the per-family chart
   assignment, and the composition of a class record's own chart with a
   target chart.

   WHY (measured 2026-08-17, coordinator census over all 91 families;
   scratch chart_census / conic_census / alphabet missions, recorded in
   TransportProductionPlan.md):

     * 20 conic-chart classes and 3 two-variable classes need a SQUARE
       ROOT to have a rational eps-form; only FIVE distinct quadratics
       occur:
           lambda1 = (1-v-w)^2 - 4 v w          (Kallen; classes 26,49,95,101,
                                                  130,165,166,171; two-var 77,97)
           lambda2 = lambda1(-v, w)              (classes 33,62,80,118,122,123;
                                                  two-var 79)
           lambda3 = lambda1(v, -w)              (classes 75,90,91,92,93)
           4 v + w^2                             (class 98; v^2 + 4 w for its
                                                  v<->w members)
           1 - 4 v w                             (class 115, one-variable u)
       and a class member may carry the v<->w image of its
       representative's quadratic (measured: CF53/CF57 host classes
       90/93/91 with lambda2, CF48/CF52 host class 98 with v^2 + 4 w).
     * A family needs ONE chart in which every class form it hosts is
       rational.  Single-root families take the chart of their root;
       two-root families take a JOINT chart built on the Kallen chart by
       a rational point on the second conic (derived and verified
       exactly 2026-08-17 01:42, pool mission jcharts2); the three
       triple-root families (CF259, CF300, CF303) are not covered here
       yet.
     * Polynomial letters that are quadratic in the moving path variable
       in every rational chart (1 - w + v w in the Kallen chart is a
       (2,2)-curve on P^1 x P^1) are handled by ALGEBRAIC LETTERS
       (MasterTransport.wl, masterTransportMonicCheck), not by charts.
       Charts exist to make the block transformations rational, nothing
       else.

   Every chart in the catalog carries the exact identities that license
   it (root^2 == RootSquare o Subst, Jacobian nondegenerate) and
   TransportChartVerify re-derives them; nothing is believed from the
   record.

   Physics bookkeeping (chamber, branch, sign of the root) is NOT done
   here -- same discipline as TransportFamilyInChart: the chart and its
   Jacobian determinant are recorded so that stage 3 can choose. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[TransportChartCatalog, TransportChartVerify, ComposeTransportChartExtension, RationalizeTransportChartExtension, TransportFamilyChartRegister, TransportFamilyChartLoad, TransportFamilyChart];
ClearAll[
  masterTransportChartByName,
  masterTransportComposeTwoVariableRecord,
  transportChartRationalExpressionQ,
  transportChartLoadRationalizeRoots,
  transportChartExtensionCandidates,
  transportFamilyChartEntryKind,
  transportFamilyChartAlias,
  transportChartNumericSquareClass,
  transportChartSquareSplit,
  transportChartExactSquareRoot,
  transportChartSquareClassData,
  transportChartDenestRadicalBase,
  transportChartDenestSign,
  transportChartCanonicalizeDenestedRadicals,
  transportChartDeclaredRadicalGenerators,
  transportChartAlgebraicZeroQ,
  transportChartCanonicalizeFrameImages,
  transportChartDeadlineQ,
  transportChartDeadlineExpiredQ,
  transportChartBudgetExhausted,
  transportChartLogSuccessTimings,
  transportChartStageLogQ,
  transportChartStageSize,
  transportChartStageText,
  transportChartStageStart,
  transportChartStageDone,
  transportChartStageMark,
  transportChartStageProgress,
  transportChartTogetherTask,
  transportChartParallelTogether,
  transportChartPullBackDeferredPreparation,
  transportChartMapleCanonicalGauge,
  $transportChartStageLog,
  $transportChartStageLastProgress,
  $transportChartStageProgressInterval,
  $transportChartZeroTestTag
];

(* Success-path stage visibility (Codex 08:30, performance addition 3).
   The two most expensive exact stages of the in-frame strip solve
   already MEASURE themselves -- timings["GaugePullBack"] and
   timings["SourceFrameIdentity"] -- but the numbers were only ever
   emitted on a budget STOP, so a successful strip left the whole
   interval unattributed (CF303 {17,12}: ~1558 s from strip start to
   exact acceptance, of which the cheap finite-field pilot and held-out
   checks are a small part and the rest was invisible).  The success
   PAYLOAD stays byte-identical -- it is pinned by hash in
   t_construction_budget and fingerprinted by other records -- so this is
   one rate-limited log line and nothing else. *)
$transportChartSuccessLogInterval = 60.;
$transportChartLastSuccessLogTime = -Infinity;

(* Stage STARTS, added 2026-08-25 after CF259 sector 24 spent more than
   23 minutes inside this acceptance with nothing printed: the timings
   above are emitted when the stage has already finished, which tells a
   watchdog nothing while it is running.  These lines name the stage
   before it costs anything and carry the SIZE of the object it is about
   to work on, so a later decision about front-running the exact
   comparison has measured input.  Acceptance semantics are untouched --
   every zero test, branch search and identity check below is the same
   one, in the same order.

   They FOLLOW "Verbose" (Codex 14:30): SolveEpsFormStripInFrame Blocks
   $transportChartStageLog from its own option, so a caller that asked
   for a quiet library gets a quiet library and the production sector
   driver -- which already solves strips with Verbose -> True -- gets the
   lines.  FACET_STRIP_STAGE_LOG=On/Off forces the decision for a run
   that cannot pass an option. *)
$transportChartStageLog = False;
$transportChartStageLastProgress = <||>;
$transportChartStageProgressInterval = 60.;

(* the per-entry zero test leaves by Throw on a budget stop: Return
   inside a Do terminates only the loop (documented Wolfram trap) *)
$transportChartZeroTestTag = "TransportChartZeroTestBudget";

transportChartStageLogQ[] := Module[
  {value = Environment["FACET_STRIP_STAGE_LOG"]},
  Which[value === "On", True, value === "Off", False,
    True, TrueQ[$transportChartStageLog]]];

(* a size probe is a full traversal: taken only when it will be printed *)
transportChartStageSize[expression_] :=
  If[transportChartStageLogQ[], LeafCount[expression],
    Missing["StageLogDisabled"]];

transportChartStageText[stage_String, data_Association] :=
  stage <> If[data === <||>, "",
    ": " <> StringRiffle[KeyValueMap[
      Function[{key, value},
        key <> " " <> ToString[
          If[Head[value] === Real, Round[value, 0.1], value],
          InputForm]], data], ", "]];

transportChartStageStart[stage_String, data_Association : <||>] := (
  If[transportChartStageLogQ[],
    $transportChartStageLastProgress[stage] = AbsoluteTime[];
    Print["[strip-in-frame] ", transportChartStageText[stage <> " start", data]]];
  True);

transportChartStageDone[stage_String, data_Association : <||>] := (
  If[transportChartStageLogQ[],
    Print["[strip-in-frame] ", transportChartStageText[stage <> " done", data]]];
  True);

(* A MARK is a completed measurement of a sub-step that had no separate
   announcement; it is deliberately not spelled "done", so that every
   "start" printed by this module has exactly one matching "done". *)
transportChartStageMark[stage_String, data_Association : <||>] := (
  If[transportChartStageLogQ[],
    Print["[strip-in-frame] ", transportChartStageText[stage, data]]];
  True);

transportChartStageProgress[stage_String, data_Association] := If[
  transportChartStageLogQ[] &&
    AbsoluteTime[] - Lookup[$transportChartStageLastProgress, stage,
      -Infinity] >= $transportChartStageProgressInterval,
  $transportChartStageLastProgress[stage] = AbsoluteTime[];
  Print["[strip-in-frame] ", transportChartStageText[stage, data]];
  True,
  False];

(* Exact Together of independent array entries.  A chart gauge can have only
   four entries yet spend tens of minutes substituting its inverse map; each
   entry is mathematically independent.  The largest entry stays local and
   the remainder is byte-balanced across no more than the family's live
   helper grant.  Failed helper values are recomputed locally while the same
   cooperative deadline remains. *)
transportChartTogetherTask[dataFile_String] := Module[
  {data = taskBrokerRead[dataFile]},
  If[! AssociationQ[data], Return[$Failed]];
  Together /@ (data["Expressions"] /. data["Rules"])
];

transportChartParallelTogether[array_, rules_List, label_String,
    deadline_: Infinity] := Module[
  {started = AbsoluteTime[], dimensions = Dimensions[array],
   expressions = Flatten[array], values, helpers, bytes, localIndex,
   helperIndices, helperBatches, batchLoads, targetBatch,
   dataFiles, codes, handle, farmed, missing,
   timeout, route = "Serial"},
  If[! AllTrue[rules, MatchQ[#1, _Rule] &],
    Return[<|"Status" -> "InvalidTogetherRules"|>]];
  If[! transportChartDeadlineQ[deadline],
    Return[<|"Status" -> "InvalidTogetherDeadline",
      "Deadline" -> deadline|>]];
  If[transportChartDeadlineExpiredQ[deadline],
    Return[<|"Status" -> "DeadlineExpired", "Seconds" -> 0.|>]];
  If[expressions === {},
    Return[<|"Status" -> "OK", "Result" -> array, "Route" -> "Serial",
      "Helpers" -> 0, "Tasks" -> 0, "Seconds" -> 0.|>]];
  helpers = If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0];
  helpers = Min[helpers, Max[0, Length[expressions] - 1]];
  values = ConstantArray[$Failed, Length[expressions]];
  If[helpers < 1,
    values = Together /@ (expressions /. rules),
    route = "Parallel";
    bytes = ByteCount /@ expressions;
    localIndex = First[Ordering[bytes, -1]];
    helperIndices = DeleteCases[Range[Length[expressions]], localIndex];
    helperBatches = ConstantArray[{}, helpers];
    batchLoads = ConstantArray[0, helpers];
    Do[
      targetBatch = First[Ordering[batchLoads, 1]];
      helperBatches[[targetBatch]] = Append[
        helperBatches[[targetBatch]], index];
      batchLoads[[targetBatch]] += bytes[[index]],
      {index, SortBy[helperIndices, -bytes[[#1]] &]}];
    dataFiles = Map[Function[batch, taskBrokerDataFile[
        "tctogether_" <> Hash[{expressions[[batch]], rules},
          "SHA256", "HexString"],
        <|"Expressions" -> expressions[[batch]], "Rules" -> rules|>]],
      helperBatches];
    codes = StringJoin[
        "FeynFacet`Private`transportChartTogetherTask[\"", #1, "\"]"] & /@
      dataFiles;
    timeout = If[deadline === Infinity, 7200.,
      Max[0.25, N[deadline - AbsoluteTime[]]]];
    handle = taskBrokerSubmit[codes, "Label" -> label,
      "Timeout" -> timeout];
    values[[localIndex]] = Together[expressions[[localIndex]] /. rules];
    farmed = taskBrokerCollect[handle];
    If[ListQ[farmed],
      Do[If[index <= Length[farmed] && ListQ[farmed[[index]]] &&
            Length[farmed[[index]]] === Length[helperBatches[[index]]],
          values[[helperBatches[[index]]]] = farmed[[index]]],
        {index, Length[helperBatches]}]];
    missing = Select[helperIndices,
      values[[#1]] === $Failed &];
    If[transportChartDeadlineExpiredQ[deadline],
      Return[<|"Status" -> "DeadlineExpired",
        "Route" -> route, "Helpers" -> helpers,
        "Tasks" -> Length[helperBatches],
        "Seconds" -> N[AbsoluteTime[] - started]|>]];
    If[missing =!= {},
      values[[missing]] = Together /@ (expressions[[missing]] /. rules)]];
  If[transportChartDeadlineExpiredQ[deadline],
    Return[<|"Status" -> "DeadlineExpired",
      "Route" -> route,
      "Helpers" -> If[route === "Parallel", helpers, 0],
      "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
      "Seconds" -> N[AbsoluteTime[] - started]|>]];
  <|"Status" -> "OK", "Result" -> ArrayReshape[values, dimensions],
    "Route" -> route, "Helpers" -> If[route === "Parallel", helpers, 0],
    "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartParallelTogether[___] :=
  <|"Status" -> "InvalidParallelTogetherInput"|>;

Options[transportChartMapleCanonicalGauge] = {
  "MapleExecutable" -> "maple",
  "ScratchDirectory" -> Automatic,
  "Tag" -> "chart_gauge",
  "TimeLimit" -> 1800,
  "Runner" -> Automatic,
  "Verbose" -> False
};

transportChartMapleCanonicalGauge[before_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], normalized, after},
  normalized = epsFormStripMapleCanonicalize[before,
    "MapleExecutable" -> OptionValue["MapleExecutable"],
    "ScratchDirectory" -> OptionValue["ScratchDirectory"],
    "Tag" -> OptionValue["Tag"], "TimeLimit" -> OptionValue["TimeLimit"],
    "Runner" -> OptionValue["Runner"], "Verbose" -> OptionValue["Verbose"]];
  If[Lookup[normalized, "Status", None] =!= "MapleCanonicalGaugeV1",
    Return[<|"Status" -> "MapleGaugeCanonicalizationFailed",
      "Detail" -> normalized|>]];
  after = normalized["Result"];
  If[Dimensions[after] =!= Dimensions[before],
    Return[<|"Status" -> "MapleGaugeCanonicalShapeMismatch"|>]];
  <|"Status" -> "MapleCanonicalGaugePrepared", "Result" -> after,
    "Normalizer" -> KeyDrop[normalized, "Result"],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartMapleCanonicalGauge[___] :=
  <|"Status" -> "MapleGaugeCanonicalizationInvalidInput"|>;

transportChartLogSuccessTimings[timings_Association, chartName_,
    verboseQ_] := If[
  TrueQ[verboseQ] || AbsoluteTime[] - $transportChartLastSuccessLogTime >=
    $transportChartSuccessLogInterval,
  $transportChartLastSuccessLogTime = AbsoluteTime[];
  Print["[strip-in-frame] accepted in chart ", chartName,
    ": gauge pull-back ", Round[Lookup[timings, "GaugePullBack", 0.], 0.1],
    " s, source-frame identity ",
    Round[Lookup[timings, "SourceFrameIdentity", 0.], 0.1], " s"];
  True,
  False];



(* the source variables and the chart variables, by NAME; callers
   re-key by SymbolName as everywhere in this module *)
$transportChartV = Symbol["Global`v"];
$transportChartW = Symbol["Global`w"];
$transportChartX = Symbol["Global`x"];
$transportChartY = Symbol["Global`y"];
$transportChartS = Symbol["Global`s"];
$transportChartU = Symbol["Global`u"];
$transportChartP = Symbol["Global`p"];
(* the second parameter of the iterated pencil (KallenQ4a/b); "tau" in
   the derivation note, kept short to match the rest of the catalog *)
$transportChartT = Symbol["Global`t"];

transportChartLambda1[v_, w_] := (1 - v - w)^2 - 4 v w;
transportChartLambda2[v_, w_] := transportChartLambda1[-v, w];
transportChartLambda3[v_, w_] := transportChartLambda1[v, -w];

TransportChartCatalog[] := With[
  {v = $transportChartV, w = $transportChartW, x = $transportChartX,
   y = $transportChartY, s = $transportChartS, u = $transportChartU,
   p = $transportChartP, t = $transportChartT},
  Module[{k1, k2, k3, q4a, q4b, b115, k12, k13, k23, x12, x13, x23,
    k3b115k, k3b115a, k2b115, k3b115, kq4av, kq4a, kq4b},
  (* ---- single-root charts ------------------------------------------ *)
  k1 = <|"Name" -> "Kallen1", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> x y, w -> (1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda1[v, w]|>},
    "Notes" -> "sqrt(lambda1) = x - y, lambda1 = (1-v-w)^2 - 4 v w; Jacobian det x - y"|>;
  k2 = <|"Name" -> "Kallen2", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> -x y, w -> (1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda2[v, w]|>},
    "Notes" -> "lambda2(v,w) = lambda1(-v,w) = (x-y)^2"|>;
  k3 = <|"Name" -> "Kallen3", "Kind" -> "TwoVariable", "Variables" -> {x, y},
    "Subst" -> {v -> x y, w -> -(1 - x) (1 - y)},
    "Root" -> x - y, "RootSquare" -> transportChartLambda3[v, w],
    "Roots" -> {<|"Root" -> x - y, "RootSquare" -> transportChartLambda3[v, w]|>},
    "Notes" -> "lambda3(v,w) = lambda1(v,-w) = (x-y)^2"|>;
  (* The Q4 charts keep the OTHER kinematic variable as a chart
     variable (v = p or w = p) and rationalize the root through the
     conic parametrization w = (p - s^2)/s (resp. v = ...), so that
     4v + w^2 = ((p + s^2)/s)^2.  MEASURED 2026-08-17 (chart probes on
     CF48/CF232): the naive parametrization v = (s^2 - u^2)/4, w = u
     turns the letter v + w - w^2 of CF48/CF52 into a QUARTIC in the
     path variable (not admissible as algebraic letters); with p linear
     in the frozen variable every letter of these families is of degree
     <= 2 in s (letters quadratic in s: roots algebraic in p, admissible). *)
  q4a = <|"Name" -> "Q4a", "Kind" -> "TwoVariable", "Variables" -> {p, s},
    "Subst" -> {v -> p, w -> (p - s^2)/s},
    "Root" -> (p + s^2)/s, "RootSquare" -> 4 v + w^2,
    "Roots" -> {<|"Root" -> (p + s^2)/s, "RootSquare" -> 4 v + w^2|>},
    "Notes" -> "4 v + w^2 = t^2 with the first kinematic variable kept, v = p: t = (p + s^2)/s; Jacobian det -(p + s^2)/s^2"|>;
  q4b = <|"Name" -> "Q4b", "Kind" -> "TwoVariable", "Variables" -> {p, s},
    "Subst" -> {v -> (p - s^2)/s, w -> p},
    "Root" -> (p + s^2)/s, "RootSquare" -> v^2 + 4 w,
    "Roots" -> {<|"Root" -> (p + s^2)/s, "RootSquare" -> v^2 + 4 w|>},
    "Notes" -> "the v<->w image, v^2 + 4 w = t^2 with w = p kept; Jacobian det (p + s^2)/s^2"|>;
  b115 = <|"Name" -> "Bilinear115", "Kind" -> "TwoVariable", "Variables" -> {p, u},
    "Subst" -> {v -> p, w -> (1 - u^2)/(4 p)},
    "Root" -> u, "RootSquare" -> 1 - 4 v w,
    "Roots" -> {<|"Root" -> u, "RootSquare" -> 1 - 4 v w|>},
    "Notes" -> "one-variable in u, u^2 = 1 - 4 v w; Jacobian det -u/(2p)"|>;
  (* ---- joint charts (derived 2026-08-17 by a rational point on the
          second conic in the base Kallen chart, verified exactly) ------ *)
  x12 = -2 (-3 y + s y + 2 y^2)/(-1 + s^2 + 4 y - 4 y^2);
  k12 = <|"Name" -> "Kallen12", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[x12 y], w -> Together[(1 - x12) (1 - y)]},
    "Root" -> Together[x12 - y], "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[x12 - y], "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[y + s x12], "RootSquare" -> transportChartLambda2[v, w]|>},
    "Parents" -> <|"Kallen1" -> {x -> x12, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = y + s x through the rational point \
(x, z) = (0, y) of z^2 = lambda2|_{Kallen1}; sqrt(lambda1) = x - y, \
sqrt(lambda2) = y + s x"|>;
  x13 = (1 + s) (-3 + s + 2 y)/(-1 + s^2 + 4 y - 4 y^2);
  k13 = <|"Name" -> "Kallen13", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[x13 y], w -> Together[(1 - x13) (1 - y)]},
    "Root" -> Together[x13 - y], "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[x13 - y], "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(1 - y) + s (x13 - 1)], "RootSquare" -> transportChartLambda3[v, w]|>},
    "Parents" -> <|"Kallen1" -> {x -> x13, y -> y}|>,
    "Notes" -> "Kallen1 base; the line z = (1-y) + s (x-1) through the rational \
point (x, z) = (1, 1-y) of z^2 = lambda3|_{Kallen1}"|>;
  x23 = (-3 + s) (1 + s - 2 y)/(-1 + s^2);
  k23 = <|"Name" -> "Kallen23", "Kind" -> "TwoVariable", "Variables" -> {y, s},
    "Subst" -> {v -> Together[-x23 y], w -> Together[(1 - x23) (1 - y)]},
    "Root" -> Together[x23 - y], "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {
      <|"Root" -> Together[x23 - y], "RootSquare" -> transportChartLambda2[v, w]|>,
      <|"Root" -> Together[(1 + y) + s (x23 - 1)], "RootSquare" -> transportChartLambda3[v, w]|>},
    "Parents" -> <|"Kallen2" -> {x -> x23, y -> y}|>,
    "Notes" -> "Kallen2 base; the line z = (1+y) + s (x-1) through the rational \
point (x, z) = (1, 1+y) of z^2 = lambda3|_{Kallen2}"|>;
  (* lambda3 together with the bilinear root sqrt(1-4 v w).  Begin with
     the Kallen3 parametrization v = a p, w = -(1-a)(1-p), for which
     sqrt(lambda3) = a-p.  Writing sqrt(1-4 v w) = 1 + u a makes the
     second square identity linear in a and gives

       a = (4 p (1-p) - 2 u)/(u^2 + 4 p (1-p)).

     This chart was first derived for a difficult family strip, but the
     formula and lookup key are root-square data only: no family identity
     belongs in the package catalog. *)
  k3b115k = p (1 - p);
  k3b115a = Together[(4 k3b115k - 2 u)/(u^2 + 4 k3b115k)];
  (* lambda2(v,w) = lambda3(-v,-w), while 1-4 v w is invariant
     under the simultaneous sign flip.  The lambda2 joint chart is
     therefore the exact sign image of the lambda3 chart below, with
     the same chart variables and rationalized roots. *)
  k2b115 = <|
    "Name" -> "Kallen2Bilinear115", "Kind" -> "TwoVariable",
    "Variables" -> {p, u},
    "Subst" -> {v -> Together[-k3b115a p],
      w -> Together[(1 - k3b115a) (1 - p)]},
    "Root" -> Together[k3b115a - p],
    "RootSquare" -> transportChartLambda2[v, w],
    "Roots" -> {
      <|"Root" -> Together[k3b115a - p],
        "RootSquare" -> transportChartLambda2[v, w]|>,
      <|"Root" -> Together[1 + u k3b115a],
        "RootSquare" -> 1 - 4 v w|>},
    "Parents" -> <|"Kallen2" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "the simultaneous source sign image of Kallen3Bilinear115: \
lambda2(v,w)=lambda3(-v,-w), while 1-4vw is invariant"|>;
  k3b115 = <|
    "Name" -> "Kallen3Bilinear115", "Kind" -> "TwoVariable",
    "Variables" -> {p, u},
    "Subst" -> {v -> Together[k3b115a p],
      w -> Together[-(1 - k3b115a) (1 - p)]},
    "Root" -> Together[k3b115a - p],
    "RootSquare" -> transportChartLambda3[v, w],
    "Roots" -> {
      <|"Root" -> Together[k3b115a - p],
        "RootSquare" -> transportChartLambda3[v, w]|>,
      <|"Root" -> Together[1 + u k3b115a],
        "RootSquare" -> 1 - 4 v w|>},
    "Parents" -> <|"Kallen3" -> {x -> k3b115a, y -> p}|>,
    "Notes" -> "Kallen3 base v=a p, w=-(1-a)(1-p); imposing \
sqrt(1-4 v w)=1+u a gives a=(4 p(1-p)-2u)/(u^2+4 p(1-p))"|>;
  (* ---- joint charts for {lambda1, 4 v + w^2} and its v<->w image,
          derived 2026-08-24 by the ITERATED PENCIL and verified exactly
          (CF259 rows 1..16 carry exactly this pair; the pair has no
          entry above, which is what stopped the family solve with
          NeedsMultiquadraticRegulatorFactorization).

     Step 1.  4 v + w^2 is quadratic in w with leading coefficient 1, so
       the pencil sqrt(4 v + w^2) = w + t is rational:
         w = (4 v - t^2)/(2 t),   sqrt(4 v + w^2) = (4 v + t^2)/(2 t).
     Step 2.  lambda1 pulled back through step 1 is N(v,t)/(4 t^2) with
         N = 4 (t-2)^2 v^2 + 4 t (t^2 - 4 t - 4) v + t^2 (2 + t)^2,
       a quadratic in v whose leading coefficient 4 (t-2)^2 is a PERFECT
       SQUARE, so the pencil applies a second time: sqrt(N) =
       2 (t-2) v + s is LINEAR in v and solves for v rationally,
         v = (t^2 (2+t)^2 - s^2)/(4 (t-2) s - 4 t (t^2 - 4 t - 4)),
         sqrt(lambda1) = (2 (t-2) v + s)/(2 t).
     The chart is therefore an extension of Q4a along its own kept
     variable: Q4a at {p -> v(s,t), s -> t/2} reproduces Subst exactly
     (recorded as "Parents" and re-derived by TransportChartVerify).

     KallenQ4b is the v<->w image.  lambda1 is v<->w symmetric and
     v^2 + 4 w = (4 v + w^2)|_{v<->w}, so the same two pencils run with
     the roles of v and w exchanged (sqrt(v^2 + 4 w) = v + t first) and
     produce v_b = w_a, w_b = v_a with both root images unchanged. *)
  kq4av = (t^2 (2 + t)^2 - s^2)/(4 (t - 2) s - 4 t (t^2 - 4 t - 4));
  kq4a = <|"Name" -> "KallenQ4a", "Kind" -> "TwoVariable", "Variables" -> {s, t},
    "Subst" -> {v -> Together[kq4av], w -> Together[(4 kq4av - t^2)/(2 t)]},
    "Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
    "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(4 kq4av + t^2)/(2 t)],
        "RootSquare" -> 4 v + w^2|>},
    "Parents" -> <|"Q4a" -> {p -> Together[kq4av], s -> t/2}|>,
    "Notes" -> "iterated pencil: sqrt(4 v + w^2) = w + t gives \
w = (4 v - t^2)/(2 t); lambda1 pulls back to N(v,t)/(4 t^2) with a square \
leading coefficient, and sqrt(N) = 2 (t-2) v + s solves for v linearly; \
sqrt(lambda1) = (2 (t-2) v + s)/(2 t), sqrt(4 v + w^2) = (4 v + t^2)/(2 t)"|>;
  kq4b = <|"Name" -> "KallenQ4b", "Kind" -> "TwoVariable", "Variables" -> {s, t},
    "Subst" -> {v -> Together[(4 kq4av - t^2)/(2 t)], w -> Together[kq4av]},
    "Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
    "RootSquare" -> transportChartLambda1[v, w],
    "Roots" -> {
      <|"Root" -> Together[(2 (t - 2) kq4av + s)/(2 t)],
        "RootSquare" -> transportChartLambda1[v, w]|>,
      <|"Root" -> Together[(4 kq4av + t^2)/(2 t)],
        "RootSquare" -> v^2 + 4 w|>},
    "Parents" -> <|"Q4b" -> {p -> Together[kq4av], s -> t/2}|>,
    "Notes" -> "the v<->w image of KallenQ4a: sqrt(v^2 + 4 w) = v + t \
gives v = (4 w - t^2)/(2 t), the pulled-back lambda1 is the SAME N with v \
replaced by w (lambda1 is v<->w symmetric), and sqrt(N) = 2 (t-2) w + s \
solves for w linearly; sqrt(lambda1) = (2 (t-2) w + s)/(2 t), \
sqrt(v^2 + 4 w) = (4 w + t^2)/(2 t)"|>;
  <|"Kallen1" -> k1, "Kallen2" -> k2, "Kallen3" -> k3, "Q4a" -> q4a, "Q4b" -> q4b,
    "Bilinear115" -> b115, "Kallen12" -> k12, "Kallen13" -> k13, "Kallen23" -> k23,
    "Kallen2Bilinear115" -> k2b115,
    "Kallen3Bilinear115" -> k3b115,
    "KallenQ4a" -> kq4a, "KallenQ4b" -> kq4b|>
]];

masterTransportChartByName[name_String] := Lookup[TransportChartCatalog[], name, None];

(* exact re-derivation of what a chart record claims.
   The SOURCE variables are read from the record's own substitution, not
   from the package's Global v/w (generality pass 2026-08-23): a frame
   built by BuildAlgebraicTransportFrame in a caller's symbols declares
   its root squares in THOSE symbols, and verifying it against v/w
   compared two different expressions and refused a correct frame.  For
   every catalog chart the substitution keys ARE v and w, so this is the
   same computation as before. *)
TransportChartVerify[chart_Association] := Module[
  {vars, subst, sourceVariables, f, g, jac, det, roots, rootChecks, parents,
    parentCharts, parentChecks, ok},
    vars = chart["Variables"]; subst = chart["Subst"];
    sourceVariables = First /@ subst;
    {f, g} = Together /@ (Last /@ subst);
    jac = {{D[f, vars[[1]]], D[f, vars[[2]]]}, {D[g, vars[[1]]], D[g, vars[[2]]]}};
    det = Together[Det[jac]];
    roots = Lookup[chart, "Roots", {<|"Root" -> chart["Root"], "RootSquare" -> chart["RootSquare"]|>}];
    rootChecks = Table[
      TrueQ[Together[r["Root"]^2 -
        (r["RootSquare"] /. Thread[sourceVariables -> {f, g}])] === 0],
      {r, roots}];
    parents = Lookup[chart, "Parents", <||>];
    parentCharts = Lookup[chart, "ParentCharts", <||>];
    parentChecks = Association @ KeyValueMap[
      Function[{parentName, map},
        Module[{parent = Lookup[parentCharts, parentName,
            masterTransportChartByName[parentName]], pf, pg},
          If[parent === None, parentName -> False,
            {pf, pg} = Last /@ parent["Subst"];
            parentName -> (TrueQ[Together[(pf /. map) - f] === 0] &&
              TrueQ[Together[(pg /. map) - g] === 0])]]],
      parents];
    ok = AllTrue[rootChecks, TrueQ] && ! TrueQ[det === 0] &&
      AllTrue[Values[parentChecks], TrueQ];
    <|"OK" -> ok, "Name" -> Lookup[chart, "Name", "?"], "RootIdentities" -> rootChecks,
      "JacobianDet" -> Factor[det], "ParentMaps" -> parentChecks|>];

BuildAlgebraicTransportFrame[rootSquares_List,
    sourceVariables : {_Symbol, _Symbol},
    chartVariables : {_Symbol, _Symbol}] := Module[
  {substitution, pulledSquares, roots, chart, certificate, name},
  If[Length[DeleteDuplicates[SymbolName /@
        Join[sourceVariables, chartVariables]]] =!= 4,
    Return[<|"Status" -> "AlgebraicFrameVariablesCollide"|>]];
  substitution = Thread[sourceVariables -> chartVariables];
  pulledSquares = Together /@ (rootSquares /. substitution);
  roots = MapThread[
    <|"Root" -> Sqrt[#1], "RootSquare" -> #2|> &,
    {pulledSquares, rootSquares}];
  name = "Multiquadratic" <> ToString[Length[roots]];
  chart = <|
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "FieldKind" -> "Multiquadratic",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> chartVariables,
    "Subst" -> substitution,
    "Root" -> If[roots === {}, None, roots[[1, "Root"]]],
    "RootSquare" -> If[roots === {}, None, roots[[1, "RootSquare"]]],
    "Roots" -> roots,
    "Notes" -> "identity change of variables with every declared square root retained exactly"
  |>;
  certificate = TransportChartVerify[chart];
  If[! TrueQ[certificate["OK"]],
    Return[<|"Status" -> "AlgebraicFrameIdentityFailed",
      "Frame" -> chart, "Certificate" -> certificate|>]];
  Join[chart, <|"Status" -> "ExactFrame",
    "ChartCertificate" -> certificate|>]
];

transportChartRadicalBases[expr_] := DeleteDuplicates[Cases[
  Unevaluated[expr],
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
    Together[base], {0, Infinity}, Heads -> True]];

(* ------------------------------------------------------------------ *)
(*  Square classes and the denesting of nested radical bases            *)
(* ------------------------------------------------------------------ *)
(* WHY (2026-08-24, CF303).  The syntactic matcher below classifies a
   radical only when its radicand IS a declared root square.  The CF303
   family connection carries radicands that are declared squares times a
   NESTED radical, e.g.

     q2 (u + v Sqrt[q1]),  u = 1+2x+x^2+2xy+y^2, v = 1+x+y,

   and bare numeric radicands (Sqrt[2]).  Both live in the declared
   multiquadratic field: with w^2 = u^2 - v^2 q1 = (2y)^2 exactly,
   u + w = (1+x+y)^2, hence 2 (u + v Sqrt[q1]) = ((1+x+y) + Sqrt[q1])^2
   and the radicand's square class is 2 q2 -- declared root 2 times the
   numeric class 2, no new field extension.  Refusing such a connection
   as "undeclared radicals" was a matcher limitation, not a mathematical
   obstruction.  The classification is exact throughout (Fermat
   denesting); only the global SIGN of a rewrite is fixed numerically,
   in transportChartDenestSign, and the identity rewrite^2 == base is
   checked exactly and is sign-independent. *)

(* Sqrt[p/q] = Sqrt[p q]/q, so the square class of a rational number is
   the squarefree part of numerator*denominator.  The sign is kept: a
   negative class means the radical is imaginary, which is data, not an
   error. *)
transportChartNumericSquareClass[value_] := Module[{r, sign, n, d},
  r = Together[value];
  If[! MatchQ[r, _Integer | _Rational], Return[$Failed]];
  If[r === 0, Return[0]];
  sign = Sign[r]; r = Abs[r];
  n = Numerator[r]; d = Denominator[r];
  sign Times @@ (First[#]^Mod[Last[#], 2] & /@ FactorInteger[n d])];

(* g = class h^2 with class squarefree: the squarefree rational content
   times every irreducible factor of odd multiplicity, once. *)
transportChartSquareSplit[g_] := Module[
  {expression, list, numeric, polynomials, sign, n, d, k, m, class, h},
  expression = Together[g];
  If[TrueQ[expression === 0], Return[{0, 0}]];
  list = FactorList[expression];
  numeric = Times @@ (First[#]^Last[#] & /@ Select[list, NumericQ[First[#]] &]);
  If[! MatchQ[numeric, _Integer | _Rational], Return[$Failed]];
  polynomials = Select[list, ! NumericQ[First[#]] &];
  sign = Sign[numeric];
  n = Numerator[Abs[numeric]]; d = Denominator[Abs[numeric]];
  k = transportChartNumericSquareClass[Abs[numeric]];
  m = Sqrt[(n d)/k];
  If[! IntegerQ[m], Return[$Failed]];
  class = sign k Times @@ (First[#]^Mod[Last[#], 2] & /@ polynomials);
  h = (m/d) Times @@
    (First[#]^Quotient[Last[#] - Mod[Last[#], 2], 2] & /@ polynomials);
  {Together[class], Together[h]}];

(* the exact square root of a rational function, or $Failed *)
transportChartExactSquareRoot[g_] := Module[{split},
  split = transportChartSquareSplit[g];
  If[split === $Failed, Return[$Failed]];
  If[TrueQ[Together[First[split] - 1] === 0] &&
      TrueQ[Together[Last[split]^2 - g] === 0],
    Together[Last[split]], $Failed]];

(* expr == NumericClass Product[declared squares] Factor^2, verified
   exactly, or a typed refusal naming the factors that match no declared
   square.  Matching is sign- and numeric-multiple-insensitive: a factor
   equal to a rational multiple of a declared square contributes that
   root index and moves the multiple into the numeric class. *)
transportChartSquareClassData[expr_, rootBases_List] := Module[
  {class, h, split, list, numeric = 1, indices = {}, unmatched = {}, whole,
   numericClass, mu, factor},
  split = transportChartSquareSplit[expr];
  If[split === $Failed,
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  {class, h} = split;
  If[class === 0, Return[<|"Status" -> "ZeroSquareClass"|>]];
  (* the whole class first: a declared square may be reducible *)
  whole = SelectFirst[Range[Length[rootBases]],
    Module[{ratio = Together[class/rootBases[[#]]]},
      MatchQ[ratio, _Integer | _Rational] && ratio =!= 0] &, 0];
  If[whole > 0,
    indices = {whole}; numeric = Together[class/rootBases[[whole]]],
    list = FactorList[class];
    Do[Module[{f = First[entry], e = Last[entry], match},
      Which[
        NumericQ[f], numeric *= f^e,
        EvenQ[e], Null,
        True,
          match = SelectFirst[Range[Length[rootBases]],
            Module[{ratio = Together[f/rootBases[[#]]]},
              MatchQ[ratio, _Integer | _Rational] && ratio =!= 0] &, 0];
          If[match > 0,
            AppendTo[indices, match];
            numeric *= Together[f/rootBases[[match]]]^e,
            AppendTo[unmatched, f^e]]]],
      {entry, list}]];
  If[unmatched =!= {},
    Return[<|"Status" -> "UnmatchedSquareClassFactors",
      "Unmatched" -> unmatched|>]];
  numericClass = transportChartNumericSquareClass[numeric];
  If[numericClass === $Failed,
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  mu = Sqrt[Together[numeric/numericClass]];
  If[! MatchQ[mu, _Integer | _Rational],
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  factor = Together[mu h];
  indices = Sort[DeleteDuplicates[indices]];
  If[! TrueQ[Together[
      numericClass Times @@ rootBases[[indices]] factor^2 - expr] === 0],
    Return[<|"Status" -> "SquareClassIdentityFailed"|>]];
  <|"Status" -> "OK", "RootIndices" -> indices,
    "NumericClass" -> numericClass, "Factor" -> factor|>];

(* Denest ONE radical base against the declared root set.  Returns
     <|"Status" -> "Denested", "RootIndices" -> {...} (the square class),
       "NumericClass" -> c, "Residual" -> 1, "InnerRootIndices" -> {...}
       (declared roots that survive INSIDE the rewrite),
       "Rewrite" -> expression in declared radicals, up to a global sign,
       "SquareIdentity" -> True, "Witness" -> <|"u","v","w","Square"|>|>
   or one of the typed refusals "NotDenestable" (with a "Reason") and
   "NestedMultiRootRadical".  The variables are the chart variables of
   the frame; the algorithm itself is variable-agnostic and treats any
   other symbol (the regulator, say) as a parameter of the coefficient
   field. *)
transportChartDenestRadicalBase[base_, roots_List, variables_List] := Module[
  {rootBases, symbols, substitute, reduceRules, reduce, toRatio, zeroQ,
   ratio, num, den, normal, list, numeric, sign, n, d, k, m, hPoly, rFree,
   fRaw, fPart, present, index, u, v, discriminant, w, branch, g, c, h, split,
   alpha, beta, verified, solved, classExpr, classData, rootImages, rewrite,
   witness, check},
  If[! MatchQ[variables, {___Symbol}],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "InvalidVariables"|>]];
  rootBases = Together /@ (#["Root"]^2 & /@ roots);

  (* (i) a purely numeric radicand is chart independent *)
  If[NumericQ[base] && FreeQ[base, _Complex],
    k = transportChartNumericSquareClass[base];
    If[k === $Failed, Return[<|"Status" -> "NotDenestable",
      "Reason" -> "NonRationalNumericRadicand"|>]];
    Return[<|"Status" -> "Denested", "RootIndices" -> {},
      "NumericClass" -> k, "Residual" -> 1, "InnerRootIndices" -> {},
      "Rewrite" -> Sqrt[Together[base/k]] Sqrt[k], "SquareIdentity" -> True,
      "Witness" -> <|"Kind" -> "Numeric", "u" -> base, "v" -> 0, "w" -> 0,
        "Square" -> Together[base/k]|>|>]];

  (* (ii) declared radicals become polynomial generators r_i, r_i^2 = q_i *)
  symbols = Table[Unique["FeynFacet`Private`denestRoot"], {Length[rootBases]}];
  substitute[expression_] := expression /.
    Power[b_, e_Rational /; Denominator[e] === 2] :>
      Module[{position = FirstPosition[rootBases,
          q_ /; TrueQ[Together[b - q] === 0], Missing["NoRoot"], {1},
          Heads -> False]},
        If[MissingQ[position], Power[b, e], symbols[[First[position]]]^(2 e)]];
  reduceRules = Table[With[{s = symbols[[i]], q = rootBases[[i]]},
      s^e_Integer /; e >= 2 :> q^Quotient[e, 2] s^Mod[e, 2]],
    {i, Length[symbols]}];
  reduce[p_] := FixedPoint[Expand[# /. reduceRules] &, Expand[p]];
  (* {numerator, denominator} with the generators cleared from the
     denominator by conjugation and every generator power reduced.
     Numeric radicals (the class constants our own rewrite introduces)
     ride along as exact constants; an undeclared SYMBOLIC radical is
     refused before this is reached. *)
  toRatio[expression_] := Module[{c0, nu, de, i},
    c0 = Together[substitute[expression]];
    nu = reduce[Numerator[c0]]; de = reduce[Denominator[c0]];
    Do[If[! FreeQ[de, symbols[[i]]],
        Module[{conjugate = reduce[de /. symbols[[i]] -> -symbols[[i]]]},
          nu = reduce[nu conjugate]; de = reduce[de conjugate]]],
      {i, Length[symbols]}];
    If[! FreeQ[de, Alternatives @@ symbols], $Failed, {nu, de}]];
  zeroQ[e1_, e2_] := Module[{a = toRatio[e1], b = toRatio[e2]},
    a =!= $Failed && b =!= $Failed &&
      TrueQ[Together[reduce[a[[1]] b[[2]] - b[[1]] a[[2]]]] === 0]];

  If[! FreeQ[substitute[base], Power[_, e_Rational /; Denominator[e] =!= 1]],
    Return[<|"Status" -> "NotDenestable",
      "Reason" -> "UndeclaredInnerRadical"|>]];
  ratio = toRatio[base];
  If[ratio === $Failed,
    Return[<|"Status" -> "NotDenestable",
      "Reason" -> "RootDenominatorNotCleared"|>]];
  {num, den} = ratio;
  (* Sqrt[num/den] = Sqrt[num den]/den *)
  normal = reduce[num den];
  If[TrueQ[normal === 0],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "ZeroRadicand"|>]];

  (* (iii) split off the generator-free factors *)
  list = FactorList[normal];
  numeric = Times @@ (First[#]^Last[#] & /@ Select[list, NumericQ[First[#]] &]);
  If[! MatchQ[numeric, _Integer | _Rational],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "NonRationalContent"|>]];
  sign = Sign[numeric]; n = Numerator[Abs[numeric]]; d = Denominator[Abs[numeric]];
  k = transportChartNumericSquareClass[Abs[numeric]];
  m = Sqrt[(n d)/k]/d;
  hPoly = m Times @@ (First[#]^Quotient[Last[#], 2] & /@
    Select[list, ! NumericQ[First[#]] &]);
  rFree = Times @@ (First[#]^Mod[Last[#], 2] & /@ Select[list,
    ! NumericQ[First[#]] && FreeQ[First[#], Alternatives @@ symbols] &]);
  fRaw = Times @@ (First[#]^Mod[Last[#], 2] & /@ Select[list,
    ! NumericQ[First[#]] && ! FreeQ[First[#], Alternatives @@ symbols] &]);
  fPart = reduce[fRaw];
  If[FreeQ[fPart, Alternatives @@ symbols],
    rFree = Together[rFree fPart]; fPart = 1];

  If[TrueQ[fPart === 1],
    (* (iv) no residual radical: a plain square class *)
    classExpr = Together[sign k rFree];
    classData = transportChartSquareClassData[classExpr, rootBases];
    If[Lookup[classData, "Status", None] =!= "OK",
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "UnclassifiedSquareClass", "Detail" -> classData|>]];
    rootImages = Sqrt /@ rootBases[[classData["RootIndices"]]];
    rewrite = Together[hPoly classData["Factor"]/den] *
      Sqrt[classData["NumericClass"]] Times @@ rootImages;
    witness = <|"Kind" -> "SquareClass", "u" -> classExpr, "v" -> 0, "w" -> 0,
      "Square" -> Together[hPoly^2]|>;
    index = 0,
    (* (v) a residual radical: Fermat denesting of u + v r *)
    present = Select[Range[Length[symbols]], ! FreeQ[fPart, symbols[[#]]] &];
    If[Length[present] =!= 1,
      Return[<|"Status" -> "NestedMultiRootRadical",
        "InnerRootIndices" -> present|>]];
    index = First[present];
    If[Exponent[fPart, symbols[[index]]] =!= 1,
      Return[<|"Status" -> "NotDenestable", "Reason" -> "ResidualNotLinear"|>]];
    u = Together[Coefficient[fPart, symbols[[index]], 0]];
    v = Together[Coefficient[fPart, symbols[[index]], 1]];
    discriminant = Together[u^2 - v^2 rootBases[[index]]];
    w = transportChartExactSquareRoot[discriminant];
    If[w === $Failed,
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "DiscriminantNotASquare"|>]];
    (* Both Fermat branches can denest; their c differ by a declared
       square, which IS a square of Q(x,y)[r]/(r^2 - q), so the square
       class is defined only modulo that square and both rewrites are
       exact.  The branch whose class uses the FEWEST declared roots is
       taken: it keeps the chart demand minimal. *)
    verified = {}; solved = {};
    Do[
      g = Together[branch/2];
      If[TrueQ[g === 0], Continue[]];
      split = transportChartSquareSplit[g];
      If[split === $Failed, Continue[]];
      {c, h} = split;
      alpha = Together[c h];
      If[TrueQ[alpha === 0], Continue[]];
      beta = Together[c v/(2 alpha)];
      If[TrueQ[Together[alpha^2 + beta^2 rootBases[[index]] - c u] === 0] &&
          TrueQ[Together[2 alpha beta - c v] === 0],
        Module[{candidateClass = Together[sign k rFree c], candidateData},
          candidateData = transportChartSquareClassData[candidateClass, rootBases];
          AppendTo[verified, <|"Class" -> candidateClass, "Data" -> candidateData,
            "Coefficient" -> c, "Alpha" -> alpha, "Beta" -> beta|>];
          If[Lookup[candidateData, "Status", None] === "OK",
            AppendTo[solved, Last[verified]]]]],
      {branch, {Together[u + w], Together[u - w]}}];
    If[verified === {},
      Return[<|"Status" -> "NotDenestable", "Reason" -> "NoDenestingBranch"|>]];
    If[solved === {},
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "UnclassifiedSquareClass",
        "Detail" -> First[verified]["Data"]|>]];
    solved = First[SortBy[solved,
      {Length[#["Data"]["RootIndices"]] &, LeafCount[#["Class"]] &}]];
    c = solved["Coefficient"]; alpha = solved["Alpha"]; beta = solved["Beta"];
    classExpr = solved["Class"]; classData = solved["Data"];
    rootImages = Sqrt /@ rootBases[[classData["RootIndices"]]];
    rewrite = Together[hPoly classData["Factor"] *
        (alpha + beta Sqrt[rootBases[[index]]])/(c den)] *
      Sqrt[classData["NumericClass"]] Times @@ rootImages;
    witness = <|"Kind" -> "Fermat", "u" -> u, "v" -> v, "w" -> w,
      "Square" -> Together[c fPart /.
        symbols[[index]] -> Sqrt[rootBases[[index]]]],
      "Alpha" -> alpha, "Beta" -> beta, "Coefficient" -> c,
      "InnerRootIndex" -> index|>];

  rewrite = rewrite /. Thread[symbols -> (Sqrt /@ rootBases)];
  (* the decisive exact identity, independent of the global sign *)
  check = zeroQ[rewrite^2, base];
  If[! TrueQ[check],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "RewriteIdentityFailed",
      "Rewrite" -> rewrite|>]];

  <|"Status" -> "Denested", "RootIndices" -> classData["RootIndices"],
    "NumericClass" -> classData["NumericClass"], "Residual" -> 1,
    "InnerRootIndices" -> If[index === 0, {}, {index}],
    "Rewrite" -> rewrite, "SquareIdentity" -> check, "Witness" -> witness|>];

(* The exact identity rewrite^2 == base fixes a rewrite up to a global
   sign; the sign is fixed by numeric evaluation at rational points of
   the chart region where EVERY declared square is positive.  The points
   must agree, otherwise the answer is the typed "DenestSignAmbiguous".
   This is the only numeric step of the denesting layer. *)
transportChartDenestSign[base_, rewrite_, roots_List,
    variables : {__Symbol}, pointCount_Integer: 2] := Module[
  {rootBases, candidates, signs = {}, used = {}, tolerance = 10^-20,
   precision = 30},
  rootBases = Together /@ (#["Root"]^2 & /@ roots);
  candidates = Table[Thread[variables ->
      PadRight[{Prime[k + 2]/Prime[k + 12], Prime[2 k + 3]/Prime[2 k + 17]},
        Length[variables], 1/(k + 3)]], {k, 1, 60}];
  Do[
    Module[{squares, value, lhs, rhs},
      squares = Quiet[N[rootBases /. point, precision]];
      If[! AllTrue[squares, MatchQ[#, _Real] && # > 0 &], Continue[]];
      value = Quiet[N[base /. point, precision]];
      rhs = Quiet[N[rewrite /. point, precision]];
      If[! FreeQ[{value, rhs}, Indeterminate | _DirectedInfinity], Continue[]];
      If[! (NumericQ[value] && NumericQ[rhs]), Continue[]];
      If[Abs[value] < 10^-10, Continue[]];
      lhs = Sqrt[value];
      Which[
        Abs[lhs - rhs] <= tolerance Max[1, Abs[lhs]],
          AppendTo[signs, 1]; AppendTo[used, point],
        Abs[lhs + rhs] <= tolerance Max[1, Abs[lhs]],
          AppendTo[signs, -1]; AppendTo[used, point],
        True, AppendTo[signs, 0]; AppendTo[used, point]]];
    If[Length[signs] >= pointCount, Break[]],
    {point, candidates}];
  If[Length[signs] < pointCount || MemberQ[signs, 0] ||
      Length[DeleteDuplicates[signs]] =!= 1,
    Return[<|"Status" -> "DenestSignAmbiguous", "Signs" -> signs,
      "Points" -> used|>]];
  <|"Status" -> "OK", "Sign" -> First[signs], "Points" -> used,
    "Precision" -> precision, "Tolerance" -> tolerance|>];

(* Rewrite every denested SYMBOLIC radical of an expression in terms of
   the declared radicals (numeric radicands are already constants of the
   coefficient field and are left alone).  The classification is exact;
   each rewrite carries its numerically fixed global sign. *)
transportChartCanonicalizeDenestedRadicals[expr_, roots_List,
    variables : {__Symbol}, denested_Association] := Module[
  {records, rewrites, failures = {}, lookup, canonical, count = 0},
  records = KeySelect[denested, ! NumericQ[#] &];
  If[records === <||>,
    Return[<|"Status" -> "OK", "Expression" -> expr, "Rewrites" -> <||>,
      "Rewritten" -> 0|>]];
  rewrites = Association @ KeyValueMap[Function[{base, record},
    Module[{signData},
      If[! TrueQ[Lookup[record, "SquareIdentity", False]],
        AppendTo[failures, <|"Base" -> base,
          "Reason" -> "DenestIdentityNotVerified"|>]; Nothing,
        signData = transportChartDenestSign[base,
          Lookup[record, "Rewrite", 0], roots, variables];
        If[Lookup[signData, "Status", None] =!= "OK",
          AppendTo[failures, <|"Base" -> base,
            "Reason" -> "DenestSignAmbiguous", "Detail" -> signData|>]; Nothing,
          base -> <|"Rewrite" -> Together[signData["Sign"] record["Rewrite"]],
            "Sign" -> signData["Sign"], "SignPoints" -> signData["Points"],
            "RootIndices" -> Lookup[record, "RootIndices", {}],
            "NumericClass" -> Lookup[record, "NumericClass", 1],
            "Witness" -> Lookup[record, "Witness", <||>]|>]]]],
    records];
  If[failures =!= {},
    Return[<|"Status" -> "DenestSignAmbiguous", "Failures" -> failures|>]];
  lookup[b_] := lookup[b] = SelectFirst[Keys[rewrites],
    TrueQ[Together[b - #] === 0] &, None];
  canonical = expr /.
    Power[b_ /; ! NumericQ[b], e_Rational /; Denominator[e] === 2] :>
      With[{match = lookup[b]},
        If[match === None, Power[b, e], count++; rewrites[match]["Rewrite"]^(2 e)]];
  <|"Status" -> "OK", "Expression" -> canonical, "Rewrites" -> rewrites,
    "Rewritten" -> count|>];

transportChartRootIndices[expr_, roots_List] := Module[
  {rootBases, radicals, matches, indices, unknown, denested, denestedBases,
   numericClasses, variables},
  rootBases = Together /@ (#["Root"]^2 & /@ roots);
  radicals = transportChartRadicalBases[expr];
  (* level 1 only, no heads: an all-level Position tests SUBexpressions of
     each root square, so a radical equal to a subexpression of another
     square contributed flattened position specs as bogus root indices
     (Sqrt[x] against {x, y, 1+x+y} classified as rank 3; found by the
     multiquadratic port's census differential, 2026-08-23) *)
  matches[base_] := Flatten[Position[rootBases, candidate_ /;
    TrueQ[Together[base - candidate] === 0], {1}, Heads -> False]];
  (* Root grade masks are an artifact ABI: discovery order can change
     when an algebraically identical expression is reordered.  Keep the
     declared frame order so channel 2^i always names the same root. *)
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#] === {} &];
  (* 2026-08-24: a radicand that is not itself a declared square may
     still lie in the declared field (nested or numeric).  Such a base is
     denested exactly, contributes the declared roots of its square class
     AND the declared roots surviving inside its rewrite, and leaves the
     unclassified list.  Discovery order is untouched and the declared
     frame order still fixes the grade mask, so recorded masks stay
     valid; the index set can only GAIN correctly classified entries. *)
  variables = DeleteDuplicates[Flatten[Variables /@ rootBases]];
  variables = Select[variables, MatchQ[#, _Symbol] &];
  denested = Association @ Map[
    Function[base, base -> transportChartDenestRadicalBase[base, roots, variables]],
    unknown];
  denestedBases = Select[denested,
    Lookup[#, "Status", None] === "Denested" &];
  indices = Sort[DeleteDuplicates[Join[indices,
    Flatten[Lookup[Values[denestedBases], "RootIndices", {}]],
    Flatten[Lookup[Values[denestedBases], "InnerRootIndices", {}]]]]];
  numericClasses = DeleteDuplicates[DeleteCases[
    Flatten[Lookup[Values[denestedBases], "NumericClass", {}]], 1]];
  unknown = Select[unknown, ! KeyExistsQ[denestedBases, #] &];
  <|"RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    "NumericRadicalClasses" -> numericClasses,
    "DenestedRadicalBases" -> denestedBases|>
];

FamilyAlgebraicRootCensus[assembly_Association, frame_Association] := Module[
  {roots, zeroBlockQ, blocks, ranges,
   connection, records, unmatched},
  If[Lookup[assembly, "Status", None] =!= "OK" ||
      ! ListQ[Lookup[assembly, "Blocks", None]] ||
      ! ListQ[Lookup[assembly, "Ranges", None]],
    Return[<|"Status" -> "FamilyAssemblyInvalid"|>]];
  roots = Lookup[frame, "Roots", {}];
  If[! ListQ[roots], Return[<|"Status" -> "AlgebraicFrameRootsInvalid"|>]];
  zeroBlockQ[expr_] := AllTrue[Flatten[expr],
    TrueQ[Together[#] === 0] &];
  blocks = assembly["Blocks"];
  ranges = assembly["Ranges"];
  connection = {assembly["Apv"], assembly["Apw"]};
  records = Flatten[Table[
    If[i > j,
      Module[{block, classification},
        block = connection[[All, ranges[[i]], ranges[[j]]]];
        If[zeroBlockQ[block], Nothing,
          classification = transportChartRootIndices[block, roots];
          <|"BlockPair" -> {i, j},
            "FamilyRows" -> {blocks[[i]], blocks[[j]]},
            "RootIndices" -> classification["RootIndices"],
            "RootCount" -> Length[classification["RootIndices"]],
            "RadicalBases" -> classification["RadicalBases"],
            "UnclassifiedRadicalBases" ->
              classification["UnclassifiedRadicalBases"],
            "DenestedRadicalBases" ->
              Keys[Lookup[classification, "DenestedRadicalBases", <||>]],
            "NumericRadicalClasses" ->
              Lookup[classification, "NumericRadicalClasses", {}]|>]],
      Nothing],
    {i, Length[blocks]}, {j, Length[blocks]}], 1];
  unmatched = DeleteDuplicates[Flatten[
    Lookup[records, "UnclassifiedRadicalBases", {}]]];
  <|"Status" -> If[unmatched === {}, "ExactRootCensus",
      "UnclassifiedRadicals"],
    "Family" -> Lookup[assembly, "Family", None],
    "RootSquares" -> Lookup[roots, "RootSquare", {}],
    "NonzeroOffDiagonalBlocks" -> Length[records],
    "RootCountHistogram" -> Counts[Lookup[records, "RootCount", {}]],
    "MaximumRootCount" -> Max[Append[Lookup[records, "RootCount", {}], 0]],
    "ThreeRootBlocks" -> Select[records, #["RootCount"] >= 3 &],
    "UnclassifiedRadicalBases" -> unmatched,
    (* radicands accepted by exact denesting rather than by a direct
       match (2026-08-24): classified, but not literally declared *)
    "DenestedRadicalBases" -> DeleteDuplicates[Flatten[
      Lookup[records, "DenestedRadicalBases", {}]]],
    "NumericRadicalClasses" -> DeleteDuplicates[Flatten[
      Lookup[records, "NumericRadicalClasses", {}]]],
    "Blocks" -> records|>
];

TransportRootSetChart[rootSquares_List,
    sourceVariables : {_Symbol, _Symbol}] := Module[
  {wanted, candidates},
  wanted = DeleteDuplicates[Together /@
    (rootSquares /. Thread[sourceVariables ->
      {$transportChartV, $transportChartW}])];
  If[wanted === {}, Return[None]];
  candidates = Select[Values[TransportChartCatalog[]], Function[chart,
    Module[{chartSquares = Together /@ Lookup[
        Lookup[chart, "Roots", {}], "RootSquare", {}]},
      AllTrue[wanted, Function[q, AnyTrue[chartSquares,
        Function[candidate, TrueQ[Together[q - candidate] === 0]]]]]]]];
  If[candidates === {},
    Missing["NoRationalChart", wanted],
    First[SortBy[candidates,
      {Function[chart, Length[Lookup[chart, "Roots", {}]]],
       Function[chart, LeafCount[Lookup[chart, "Subst", {}]]]}]]]
];

TransportRootSetChart[rootSquares_List] := TransportRootSetChart[
  rootSquares, {$transportChartV, $transportChartW}];

transportChartRekey[chart_Association, sourceVariables : {_Symbol, _Symbol},
    chartVariables : {_Symbol, _Symbol}] := Module[
  {oldSubstitution, oldSource, oldVariables, sourceRules, variableRules,
   substitution, roots},
  oldSubstitution = Lookup[chart, "Subst", $Failed];
  oldVariables = Lookup[chart, "Variables", $Failed];
  If[! MatchQ[oldSubstitution, {_Rule, _Rule}] ||
      ! MatchQ[oldVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "ChartNotWellFormed"|>]];
  oldSource = First /@ oldSubstitution;
  sourceRules = Thread[oldSource -> sourceVariables];
  variableRules = Thread[oldVariables -> chartVariables];
  substitution = Map[
    Function[rule, (First[rule] /. sourceRules) ->
      Together[Last[rule] /. variableRules]], oldSubstitution];
  roots = Map[
    <|"Root" -> Together[#["Root"] /. variableRules],
      "RootSquare" -> Together[#["RootSquare"] /. sourceRules]|> &,
    Lookup[chart, "Roots", {}]];
  <|"Name" -> Lookup[chart, "Name", "Chart"] <> "Rekeyed",
    "Kind" -> "TwoVariable", "CoefficientField" -> "Rational",
    "Variables" -> chartVariables, "Subst" -> substitution,
    "Root" -> If[roots === {}, None, roots[[1]]["Root"]],
    "RootSquare" -> If[roots === {}, None, roots[[1]]["RootSquare"]],
    "Roots" -> roots|>
];

(* Order matters (measured 2026-08-24 on the 27x27 CF303 truncation; the
   same trap and the same cure as in FactorFamilyRegulatorDependenceInFrame).
   Together applied while the entries STILL CARRY RADICALS rationalizes
   radical denominators by conjugation -- the documented Wolfram trap of
   this repository -- and multiplies every entry out.  Substituting the
   chart's own RATIONAL root images first (branchRoots are the declared
   squares pulled back into the chart, images their rational roots there)
   leaves Together a purely rational job; the canonical Together then
   happens twice, once here on the rational chart entries and once inside
   masterTransportPullBackOneForm after the Jacobian contraction.  The
   branch substitution matches on the Together-difference against the
   substituted declared square, so it does not need a normalized entry to
   fire. *)
transportChartPullBackStrip[strip : {e_List, c_List, bbar_List},
    data_Association, branchRoots_List, images_List] := Module[{pull},
  pull[pair_] := Module[{components},
    components = Map[
      Map[Together, transportChartApplyRootBranches[
        # /. data["Subst"], branchRoots, images], {2}] &, pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]], data["Jacobian"]]
  ];
  pull /@ {e, c, bbar}
];

(* Pull a deferred forcing into a rational chart without first forming its
   source-frame sum.  Each interned operand is substituted and rationalized
   once, then the immutable jobs assemble the chart image.  This preserves
   the bundle's main performance property for root-free and chartable rooted
   strips; bundle presence is not itself a reason to select the direct
   multiquadratic engine. *)
transportChartPullBackDeferredBundle[bundle_Association,
    data_Association, branchRoots_List, images_List] := Module[
  {transform, evaluated, image, survivingRadicals, pulled},
  If[! MatchQ[Lookup[data, "Subst", None], {___Rule}] ||
      ! MatchQ[Lookup[data, "Jacobian", None], {{_, _}, {_, _}}] ||
      Length[branchRoots] =!= Length[images],
    Return[<|"Status" -> "DeferredBundleChartDataInvalid"|>]];
  transform[expr_] := Together[transportChartApplyRootBranches[
    expr, branchRoots, images]];
  evaluated = blockEquationDeferredBundleEvaluate[bundle, data["Subst"],
    "ExpressionTransform" -> transform];
  If[Lookup[evaluated, "Status", None] =!= "OK",
    Return[<|"Status" -> "DeferredBundleChartEvaluationFailed",
      "Detail" -> evaluated|>]];
  image = evaluated["Image"];
  If[! MatchQ[Dimensions[image], {2, _, _}],
    Return[<|"Status" -> "DeferredBundleChartImageInvalid"|>]];
  survivingRadicals = transportChartRadicalBases[image];
  If[survivingRadicals =!= {},
    Return[<|"Status" -> "DeferredBundleChartStillAlgebraic",
      "RadicalBases" -> survivingRadicals|>]];
  pulled = masterTransportPullBackOneForm[
    image[[1]], image[[2]], data["Jacobian"]];
  <|"Status" -> "OK", "OneForm" -> pulled,
    "OperandEvaluations" -> evaluated["OperandEvaluations"]|>
];
transportChartPullBackDeferredBundle[___] :=
  <|"Status" -> "DeferredBundleChartInputInvalid"|>;

(* Materialize the raw block-equation DAG only after its roots and source
   coordinates have been replaced by the rational chart.  This is the
   chartable-block production path: it performs the arithmetic the rational
   solver needs and none of the direct multiquadratic provider's divisor,
   orbit, provenance, fingerprint or source-frame factorization work. *)
transportChartPullBackDeferredPreparation[record_Association,
    data_Association, branchRoots_List, images_List] := Module[
  {preparation, transform, materialized, dimensions, values, image,
   survivingRadicals, pulled, polynomialSymbols},
  preparation = Lookup[record, "Preparation",
    Lookup[record, "DeferredPreparation", Missing["NoPreparation"]]];
  If[! AssociationQ[preparation] ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      ! MatchQ[Lookup[data, "Subst", None], {___Rule}] ||
      ! MatchQ[Lookup[data, "Jacobian", None], {{_, _}, {_, _}}] ||
      Length[branchRoots] =!= Length[images],
    Return[<|"Status" -> "DeferredPreparationChartInputInvalid"|>]];
  transform[expr_] := transportChartApplyRootBranches[
    expr /. data["Subst"], branchRoots, images];
  polynomialSymbols = DeleteDuplicates[Join[
    Lookup[data, "Variables", {}],
    {Lookup[preparation, "Regulator", None]},
    Lookup[preparation, "Parameters", {}]]];
  materialized = blockEquationDeferredMaterialize[preparation,
    "ValidatePreparation" -> False,
    "ExpressionTransform" -> transform,
    "PolynomialSymbols" -> polynomialSymbols,
    "Cancel" -> False, "CanonicalizeUntouched" -> False,
    "AlgebraicCanonicalize" -> False,
    "Parallel" -> Automatic, "Helpers" -> Automatic,
    "Progress" -> transportChartStageLogQ[],
    "Label" -> "chart_" <> ToString[
      Lookup[preparation, "Sector", "block"]] <> "_" <>
      ToString[Lookup[preparation, "LowerSector", "source"]]];
  If[Lookup[materialized, "Status", None] =!= "OK",
    Return[<|"Status" -> "DeferredPreparationMaterializationFailed",
      "Detail" -> materialized|>]];
  dimensions = preparation["Dimensions"];
  values = materialized["Values"];
  image = Table[values[{mu, i, j}],
    {mu, dimensions[[1]]}, {i, dimensions[[2]]},
    {j, dimensions[[3]]}];
  survivingRadicals = transportChartRadicalBases[image];
  If[survivingRadicals =!= {},
    Return[<|"Status" -> "DeferredPreparationChartStillAlgebraic",
      "RadicalBases" -> survivingRadicals|>]];
  pulled = masterTransportPullBackOneForm[
    image[[1]], image[[2]], data["Jacobian"]];
  <|"Status" -> "OK", "OneForm" -> pulled,
    "Materialization" -> KeyDrop[materialized, "Values"]|>
];
transportChartPullBackDeferredPreparation[___] :=
  <|"Status" -> "DeferredPreparationChartInputInvalid"|>;

transportChartCurrentRoots[frame_Association,
    variables : {_Symbol, _Symbol}] := Module[
  {frameVariables, substitution, variableRules},
  frameVariables = Lookup[frame, "Variables", $Failed];
  substitution = Lookup[frame, "Subst", $Failed];
  If[! MatchQ[frameVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[substitution, {_Rule, _Rule}], Return[$Failed]];
  variableRules = Thread[frameVariables -> variables];
  Map[
    <|"Root" -> Together[#["Root"] /. variableRules],
      "RootSquare" -> Together[(#["RootSquare"] /. substitution) /.
        variableRules]|> &,
    Lookup[frame, "Roots", {}]]
];

(* The radicand carried by an expression need not be the declared root
   square itself: the kernel AUTOMATICALLY pulls a rational square factor
   out of a radical (Sqrt[N/4] evaluates to Sqrt[N]/2, Sqrt[4 N] to
   2 Sqrt[N]), so after a chart pullback the surviving base is c^2 times
   the pulled-back root square for some positive rational c.  MEASURED
   2026-08-24 on the CF259 rows 1..16 truncation in KallenQ4a: the two
   bases were exactly 4 and 16 times the declared squares (the chart's
   own root images carry denominators 2 t and 4 t), the branch rule
   matched neither, and FactorFamilyRegulatorDependenceInFrame refused a
   correct chart with "ChartStillAlgebraic".  Matching up to the square
   class of a positive RATIONAL NUMBER is exact -- base == c^2 Q gives
   (c image)^2 == c^2 Q == base -- and is a strict generalization: c is 1
   for every chart whose pullback needs no such factor, which is what the
   catalog's older charts produce.  Symbolic square factors are NOT
   admitted: the kernel never extracts one (the sign of a symbol is
   unknown), so a symbolic ratio means the base is a different quadratic
   and must stay untouched. *)
transportChartRootBranchScale[base_, rootSquare_] := Module[{ratio, scale},
  If[TrueQ[Together[base - rootSquare] === 0], Return[1]];
  If[TrueQ[Together[rootSquare] === 0], Return[None]];
  ratio = Together[base/rootSquare];
  If[! MatchQ[ratio, _Integer | _Rational] || ! TrueQ[ratio > 0],
    Return[None]];
  scale = Sqrt[ratio];
  If[MatchQ[scale, _Integer | _Rational], scale, None]
];

transportChartApplyRootBranches[expr_, roots_List, images_List] := Module[
  {scale},
  (* one Together per distinct (radicand, root) pair, not one per
     occurrence: the same radical appears in most entries of a connection *)
  scale[base_, index_] := scale[base, index] =
    transportChartRootBranchScale[base, roots[[index]]["RootSquare"]];
  Fold[Function[{current, index},
    current /. Power[base_, exponent_Rational] :>
      Module[{factor = If[Denominator[exponent] === 2,
          scale[base, index], None]},
        If[factor === None, Power[base, exponent],
          (factor images[[index]])^(2 exponent)]]],
    expr, Range[Length[roots]]]];

(* ------------------------------------------------------------------ *)
(*  Canonical comparison over the declared multiquadratic field        *)
(* ------------------------------------------------------------------ *)
(* WHY (2026-08-25, CF303 off-diagonal block {17,12}).  Every acceptance
   test of the in-frame strip construction below reduced to
   Together[lhs - rhs] === 0.  Together is canonical on RATIONAL entries
   only; on entries that still carry a radical it compares two
   non-canonical forms, so an exactly equal pair is reported UNEQUAL --
   the documented trap of this repository.  MEASURED that night: the
   {17,12} gauge round trip rejected all four branch choices although the
   objects were exactly equal, because one coordinate-map image carried a
   NESTED radical the branch substitution above cannot match (it matches
   only rational-square multiples of a declared root square), so radicals
   survived into the comparison.  A generic rational 1x1 gauge reproduced
   the rejection, which is what proves the defect is in the comparison
   layer and not in any solved object.

   The test below is exact: every radical is matched against the declared
   root set (same square-class rule the branch substitution uses) and
   against the numeric square classes, each match becomes a generator
   r with r^2 = q, the generators are cleared from the denominator by
   conjugation and the numerator is reduced as a polynomial.  This is the
   same reduction transportChartDenestRadicalBase uses internally.

   It is STRICTER than the Together test, never weaker: a genuinely
   unequal pair has a nonzero reduced numerator (the declared squares are
   independent generators of the frame -- a dependency among them could
   only make the test reject more, never accept more), and a radical that
   is NOT in the declared field returns $Failed so the caller refuses
   with a TYPED status instead of reading a false negative as failure. *)

transportChartDeclaredRadicalGenerators[expr_, roots_List] := Module[
  {rootBases, radicals, records, unmatched = {}},
  rootBases = Together /@ Lookup[roots, "RootSquare", {}];
  radicals = transportChartRadicalBases[expr];
  records = Map[Function[base, Module[{index = 0, scale = None, split},
      Do[scale = transportChartRootBranchScale[base, rootBases[[i]]];
         If[scale =!= None, index = i; Break[]], {i, Length[rootBases]}];
      Which[
        index > 0,
          (* base == scale^2 q, so Sqrt[base] == scale r: the same rule
             transportChartApplyRootBranches substitutes with *)
          base -> <|"Kind" -> "Declared", "Index" -> index,
            "Class" -> rootBases[[index]], "Factor" -> scale|>,
        MatchQ[Together[base], _Integer | _Rational],
          split = transportChartSquareSplit[base];
          If[split === $Failed || First[split] === 0,
            AppendTo[unmatched, base]; Nothing,
            base -> <|"Kind" -> "Numeric", "Index" -> 0,
              "Class" -> First[split], "Factor" -> Last[split]|>],
        True, AppendTo[unmatched, base]; Nothing]]],
    radicals];
  If[unmatched =!= {},
    Return[<|"Status" -> "UndeclaredRadicalBases", "Unmatched" -> unmatched|>]];
  (* one generator per square CLASS, compared exactly: a syntactic
     DeleteDuplicates would give the same class two generators and the
     reduction would then not be canonical *)
  <|"Status" -> "OK", "Records" -> Association[records],
    "Classes" -> Fold[
      Function[{accumulated, class},
        If[AnyTrue[accumulated, TrueQ[Together[class - #] === 0] &],
          accumulated, Append[accumulated, class]]],
      {}, #["Class"] & /@ Values[Association[records]]]|>];

(* True / False / $Failed.  $Failed means "not decidable in the declared
   field" and is NEVER a synonym for False. *)
transportChartAlgebraicZeroQ[expr_, roots_List] := Module[
  {together, generatorData, records, classes, symbols, classIndex,
   substitute, reduceRules, reduce, converted, nu, de, i},
  together = Together[expr];
  If[FreeQ[together, Power[_, _Rational]],
    Return[TrueQ[together === 0]]];
  generatorData = transportChartDeclaredRadicalGenerators[together, roots];
  If[Lookup[generatorData, "Status", None] =!= "OK", Return[$Failed]];
  records = generatorData["Records"];
  classes = generatorData["Classes"];
  If[classes === {}, Return[TrueQ[together === 0]]];
  symbols = Table[Unique["FeynFacet`Private`fieldRoot"], {Length[classes]}];
  classIndex[class_] := classIndex[class] = SelectFirst[
    Range[Length[classes]], TrueQ[Together[classes[[#]] - class] === 0] &, 0];
  substitute[expression_] := expression /.
    Power[b_, e_Rational /; Denominator[e] === 2] :>
      Module[{record = SelectFirst[Keys[records],
          TrueQ[Together[b - #] === 0] &, None], k},
        If[record === None, Power[b, e],
          k = classIndex[records[record]["Class"]];
          If[k === 0, Power[b, e],
            (records[record]["Factor"] symbols[[k]])^(2 e)]]];
  reduceRules = Table[With[{s = symbols[[i]], q = classes[[i]]},
      s^e_Integer /; e >= 2 :> q^Quotient[e, 2] s^Mod[e, 2]],
    {i, Length[symbols]}];
  reduce[p_] := FixedPoint[Expand[# /. reduceRules] &, Expand[p]];
  converted = Together[substitute[together]];
  If[! FreeQ[converted, Power[_, _Rational]], Return[$Failed]];
  nu = reduce[Numerator[converted]]; de = reduce[Denominator[converted]];
  (* clear the generators from the denominator by conjugation *)
  Do[If[! FreeQ[de, symbols[[i]]],
      Module[{conjugate = reduce[de /. symbols[[i]] -> -symbols[[i]]]},
        nu = reduce[nu conjugate]; de = reduce[de conjugate]]],
    {i, Length[symbols]}];
  If[! FreeQ[de, Alternatives @@ symbols], Return[$Failed]];
  If[TrueQ[Together[de] === 0], Return[$Failed]];
  TrueQ[Together[reduce[nu]] === 0]];

(* Rewrite the images of a chart/frame map so that every radical they
   carry is a DECLARED one: the nested and numeric radicands Solve emits
   when it inverts a joint chart are denested exactly against the frame's
   root set (transportChartDenestRadicalBase; its global sign is fixed
   numerically and its square identity exactly).  Typed refusal
   otherwise: an image outside the declared field must stop the
   construction, not travel into a solved gauge. *)
transportChartCanonicalizeFrameImages[images_List, roots_List,
    variables : {__Symbol}] := Module[
  {classification, denested, canonical},
  classification = transportChartRootIndices[images, roots];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[<|"Status" -> "ImagesCarryUndeclaredRadicals",
      "RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]];
  denested = Lookup[classification, "DenestedRadicalBases", <||>];
  If[KeySelect[denested, ! NumericQ[#] &] === <||>,
    Return[<|"Status" -> "OK", "Images" -> images, "Rewritten" -> 0,
      "RewrittenBases" -> {},
      "NumericRadicalClasses" ->
        Lookup[classification, "NumericRadicalClasses", {}]|>]];
  canonical = transportChartCanonicalizeDenestedRadicals[
    images, roots, variables, denested];
  If[Lookup[canonical, "Status", None] =!= "OK",
    Return[<|"Status" -> "ImageDenestingFailed", "Detail" -> canonical|>]];
  <|"Status" -> "OK",
    "Images" -> Together /@ canonical["Expression"],
    "Rewritten" -> canonical["Rewritten"],
    "RewrittenBases" -> Keys[canonical["Rewrites"]],
    "NumericRadicalClasses" ->
      Lookup[classification, "NumericRadicalClasses", {}]|>];

(* ---------------------------------------------------------------------
   Cooperative deadline in the STRIP-CONSTRUCTION stage (2026-08-24).

   The cooperative "Deadline" added to the solvers on 2026-08-24 bounded
   only the solvers.  MEASURED the same night on both campaign missions:
   a strip sat more than two hours between the driver's "strip {i,j}"
   announcement and the first solver call -- root classification, chart
   selection, the chart pullback, the gauge pullback and the source-frame
   identity check all run here -- so the 7200 s sector budget passed
   silently on both families with no stop and no record of where the time
   went.  This stage now checks the SAME absolute deadline at its own
   stage boundaries and stops with the SAME typed shape the solvers use.

   The stop is COOPERATIVE, never TimeConstrained: TimeConstrained does
   not bound the task-broker helpers and has escaped in pool subkernels
   before (CLAUDE.md).  A boundary check is placed before and after each
   opaque call -- transportChartPullBackStrip is one Together-heavy pass
   over the whole strip and cannot be checked internally -- and the
   measured wall time of every substage is carried in the stop, so a
   future log shows which substage consumed the budget instead of only
   that the budget passed.

   "Deadline" is an absolute AbsoluteTime[] value; Infinity (the default)
   makes every check below a no-op, so every existing caller and every
   recorded result is unchanged.  Nothing here is resumable state of its
   own: the construction is a pure function of the strip and the frame,
   and the driver's strip input file plus the solvers' per-prime
   artifacts already on disk are what the next run picks up, so the stop
   declares itself resumable in exactly that sense. *)
transportChartDeadlineQ[deadline_] :=
  deadline === Infinity || (NumericQ[deadline] && Positive[deadline]);

transportChartDeadlineExpiredQ[deadline_] :=
  NumericQ[deadline] && AbsoluteTime[] >= deadline;

transportChartBudgetExhausted[substage_String, elapsed_, deadline_,
    progress_Association] := Join[
  <|"Status" -> "BudgetExhausted",
    "Stage" -> "StripConstruction:" <> substage,
    "Substage" -> substage,
    "Elapsed" -> elapsed,
    "Deadline" -> deadline,
    "Method" -> "StripConstructionInFrame",
    "Resumable" -> True|>,
  progress];

Options[SolveEpsFormStripInFrame] = Join[
  Options[SolveEpsFormStrip], {
    "FiniteFieldFallback" -> True,
    "FiniteFieldFirst" -> False,
    "FiniteFieldOptions" -> {},
    "MultiquadraticDispatch" -> True,
    "MultiquadraticOptions" -> {},
    "DeferredPreparation" -> Automatic,
    "DeferredMaterializationCertificate" -> Automatic,
    (* Existing callers retain the package's exact Together route.
       "MapleCanonical" is the explicit external-normalizer route: Maple
       returns an entrywise algebraic normal form, but the package accepts it
       only after exact multiquadratic equality and four modular images, then
       runs the historical exact frame gates below. *)
    "GaugePullBackMode" -> "Exact",
    (* absolute AbsoluteTime[] value; Infinity = unbounded (the default,
       so every existing caller is unchanged).  It bounds the
       construction stage of this function AND is handed to whichever
       solver this function dispatches to, unless the caller already put
       an explicit "Deadline" in "FiniteFieldOptions" /
       "MultiquadraticOptions" -- the explicit inner option always wins,
       so the driver's existing plumbing keeps its meaning. *)
    "Deadline" -> Infinity
  }
];

(* A root set with no joint rational chart is dispatched to the direct
   multiquadratic engine (Design/GeneralityFixes2.md F2, 2026-08-23).
   These statuses mean the ENGINE declined the input as outside its own
   scope, not that it ran and failed; only they keep the historical
   "NoRationalStripChart" answer, with the engine's typed refusal
   attached so the caller can tell the two apart.  Every other engine
   status -- "ModularConsistent" and every typed failure -- is returned
   verbatim. *)
$transportChartMultiquadraticScopeRefusals = {
  "UnsupportedRootRank", "InvalidStripRecord",
  "StripContainsUndeclaredRadicals", "ContextSensitiveStripABI",
  "AlgebraicFrameNotWellFormed", "ForcingChannelDecompositionFailed",
  "GaugeDenominatorNotRational"};

SolveEpsFormStripInFrame[
    strip : {e_List, c_List, bbar_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    frame_Association, opts : OptionsPattern[]] := Block[
  (* the stage lines follow this call's "Verbose" (Codex 14:30): a caller
     that asked for a quiet library gets one.  Block, so every exit path
     -- including a Return out of the Module below -- restores it. *)
  (* the EXPLICIT three-argument OptionValue: this sits in a Block
     variable initializer, which is held *)
  {$transportChartStageLog = TrueQ[OptionValue[
    SolveEpsFormStripInFrame, {opts}, "Verbose"]]},
  Module[
  {allRoots, classification, rootIndices, usedRoots, rootSquares, chart,
   chartVariables, rekeyed, data, chartStrip, inner, chartGauge,
   identityData, coordinateMap, sourceGauge, chartRoots, rootImages,
   chartBranchRoots, mapCanonicalization, comparatorRefusals,
   signChoices, acceptedSigns, branchImages, branchedGauge,
   sourceTransformed, chartTransformed, pulledTransformed,
   sourceAlphabet, zeroMatrixNamedQ, zeroTestStop,
   identityHolds, pullPair, optionRules, parallelTogether,
   finiteFieldQ, finiteFieldFirstQ, finiteFieldOptions, canonicalKernelCount,
   scratchDirectory, stripTag, verbose, solveRationalStrip, innerSolvedQ,
   multiquadraticOptions, multiquadraticResult, multiquadraticStatus,
   bundlePullback, preparationPullback, rationalStrip,
   deferredBundle, bundleValidation, bundleRoots, bundleIndices,
   deferredPreparation, preparation, preparationRootSquares,
   preparationIndices, deferredSourceQ,
   materializationCertificate, materializationValidation,
   deferredForcingMaterializedQ,
   selectedIndices, stableFrame, bundleRecord,
   gaugePullBackMode, mapleCanonicalQ, mapleGauge, preNormalizationGauge,
   postPullBackCheckQ, postPullBackCandidates, postPullBackVerification,
   postPullBackGauge, sourceGaugeRadicalFreeQ,
   constructionStart = AbsoluteTime[], deadline, timings = <||>,
   stageSeconds, substageSeconds, stripDimensions, budgetProgress,
   budgetExhausted},

  (* precomputed, NOT read inside budgetProgress: a pattern variable in
     the body of a delayed definition is substituted when the outer rule
     fires, which would embed the whole strip in that definition *)
  stripDimensions = Dimensions[bbar[[1]]];
  deadline = OptionValue["Deadline"];
  If[! transportChartDeadlineQ[deadline],
    Return[<|"Status" -> "InvalidDeadline", "Deadline" -> deadline,
      "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]];
  gaugePullBackMode = OptionValue["GaugePullBackMode"];
  If[! MemberQ[{"Exact", "MapleCanonical"}, gaugePullBackMode],
    Return[<|"Status" -> "InvalidGaugePullBackMode",
      "Allowed" -> {"Exact", "MapleCanonical"},
      "Actual" -> gaugePullBackMode|>]];
  mapleCanonicalQ = gaugePullBackMode === "MapleCanonical";
  (* what a construction stop reports: the substage wall times measured
     so far (this is the record that was missing tonight -- the budget
     passed with no evidence of which substage consumed it) and the
     identifiers of the strip being constructed.  Every key is defined
     whether or not the substage it belongs to was reached. *)
  budgetProgress[] := <|
    "ConstructionTimings" -> timings,
    "RootIndices" -> If[ListQ[rootIndices], rootIndices,
      Missing["NotClassified"]],
    "RootSquares" -> If[ListQ[rootSquares], rootSquares,
      Missing["NotClassified"]],
    "Chart" -> If[AssociationQ[chart], Lookup[chart, "Name", None], None],
    "StripDimensions" -> stripDimensions,
    "InnerStatus" -> If[AssociationQ[inner],
      Lookup[inner, "Status", None], Missing["NotSolved"]]|>;
  budgetExhausted[substage_String] := transportChartBudgetExhausted[
    substage, AbsoluteTime[] - constructionStart, deadline,
    budgetProgress[]];

  (* the frame gate is pure input validation and outranks a budget stop,
     exactly as the solvers' option gates do *)
  allRoots = transportChartCurrentRoots[frame, variables];
  If[allRoots === $Failed,
    Return[<|"Status" -> "AlgebraicFrameNotWellFormed"|>]];
  (* A deferred forcing bundle is part of the strip's mathematical input,
     even though the materialized BBar slot is intentionally a zero shape
     placeholder.  Authenticate it before either the zero-forcing shortcut
     or the root census can draw conclusions from that placeholder. *)
  multiquadraticOptions = OptionValue["MultiquadraticOptions"];
  If[! MatchQ[multiquadraticOptions, {___Rule}],
    Return[<|"Status" -> "InvalidMultiquadraticOptions"|>]];
  deferredBundle = FirstCase[multiquadraticOptions,
    HoldPattern["DeferredBundle" -> value_] :> value,
    Missing["NoDeferredBundle"]];
  If[AssociationQ[deferredBundle],
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[<|"Status" -> "InvalidDeferredBundle",
        "Detail" -> bundleValidation|>]];
    If[Lookup[deferredBundle, "Variables", None] =!= variables ||
        Lookup[deferredBundle, "Regulator", None] =!= epsilon ||
        Lookup[deferredBundle, "Dimensions", None] =!=
          Prepend[Dimensions[bbar[[1]]], 2],
      Return[<|"Status" -> "DeferredBundleFrameMismatch"|>]],
    If[! MissingQ[deferredBundle] && deferredBundle =!= Automatic,
      Return[<|"Status" -> "InvalidDeferredBundle"|>]]];
  deferredPreparation = OptionValue["DeferredPreparation"];
  If[AssociationQ[deferredPreparation],
    preparation = Lookup[deferredPreparation, "Preparation",
      Lookup[deferredPreparation, "DeferredPreparation",
        Missing["NoPreparation"]]];
    preparationRootSquares = Lookup[deferredPreparation,
      "RootSquares", Missing["NoRootSquares"]];
    If[! AssociationQ[preparation] ||
        Lookup[preparation, "Status", None] =!= "Prepared" ||
        Lookup[preparation, "ABIVersion", None] =!=
          $blockEquationDeferredABIVersion ||
        Lookup[preparation, "Variables", None] =!= variables ||
        Lookup[preparation, "Regulator", None] =!= epsilon ||
        Lookup[preparation, "Dimensions", None] =!=
          Prepend[Dimensions[bbar[[1]]], 2] ||
        ! ListQ[preparationRootSquares],
      Return[<|"Status" -> "DeferredPreparationFrameMismatch"|>]],
    If[deferredPreparation =!= Automatic,
      Return[<|"Status" -> "InvalidDeferredPreparation"|>]]];
  If[AssociationQ[deferredBundle] && AssociationQ[deferredPreparation],
    Return[<|"Status" -> "AmbiguousDeferredForcing"|>]];
  materializationCertificate =
    OptionValue["DeferredMaterializationCertificate"];
  deferredForcingMaterializedQ = False;
  If[materializationCertificate =!= Automatic,
    If[! AssociationQ[deferredBundle] ||
        ! AssociationQ[materializationCertificate],
      Return[<|"Status" -> "InvalidDeferredMaterializationCertificate"|>]];
    materializationValidation =
      blockEquationDeferredMaterializationCertificateValidate[
        materializationCertificate, deferredBundle, bbar,
        variables, epsilon];
    If[Lookup[materializationValidation, "Status", None] =!=
        "MaterializationCertificateValid",
      Return[<|"Status" -> "InvalidDeferredMaterializationCertificate",
        "Detail" -> materializationValidation|>]];
    deferredForcingMaterializedQ = True];
  deferredSourceQ =
    (AssociationQ[deferredBundle] && ! deferredForcingMaterializedQ) ||
      AssociationQ[deferredPreparation];
  (* BOUNDARY 1 (entry): an already-expired deadline never starts the
     root classifier, which denests and square-class-matches every
     radical occurring in the strip *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Entry"]]];
  {stageSeconds, classification} = AbsoluteTiming[
    transportChartRootIndices[strip, allRoots]];
  timings["RootClassification"] = stageSeconds;
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[<|"Status" -> "StripContainsUndeclaredRadicals",
      "RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]];
  (* 2026-08-24: the classifier now also accepts nested and numeric
     radicands by exact denesting.  Everything downstream of this solver
     -- CANONICA/Libra, the finite-field sampler, the multiquadratic
     grade engine -- works over a RATIONAL chart, and neither a numeric
     radical constant nor a rewritten nested radical has been carried
     through it.  The strip therefore still STOPS here, now with the
     denesting recorded, instead of proceeding on an untested path. *)
  If[Lookup[classification, "DenestedRadicalBases", <||>] =!= <||>,
    Return[<|"Status" -> "StripContainsDenestedRadicals",
      "RadicalBases" -> Keys[classification["DenestedRadicalBases"]],
      "NumericRadicalClasses" ->
        Lookup[classification, "NumericRadicalClasses", {}]|>]];
  rootIndices = classification["RootIndices"];
  If[AssociationQ[deferredBundle],
    (* Roots used only by the deferred forcing are invisible in the zero
       placeholder.  Match the authenticated bundle frame back to the
       caller's frame, then canonicalize the UNION.  Source indices remain
       provenance; declaration order is not allowed to become a grade ABI. *)
    bundleRoots = Lookup[deferredBundle["RootFrame"], "Roots", {}];
    bundleIndices = Table[Module[{matches},
        matches = Flatten[Position[allRoots,
          candidate_ /; TrueQ[Together[candidate["RootSquare"] -
                bundleRoot["RootSquare"]] === 0] &&
            TrueQ[Together[candidate["Root"] - bundleRoot["Root"]] === 0],
          {1}, Heads -> False]];
        If[Length[matches] =!= 1,
          Return[<|"Status" -> "DeferredBundleRootFrameMismatch",
            "BundleRoot" -> bundleRoot, "Matches" -> matches|>, Module]];
        First[matches]],
      {bundleRoot, bundleRoots}];
    If[! VectorQ[bundleIndices, IntegerQ],
      Return[FirstCase[bundleIndices, failure_Association :> failure,
        <|"Status" -> "DeferredBundleRootFrameMismatch"|>]]];
    selectedIndices = DeleteDuplicates[Join[rootIndices, bundleIndices]];
    stableFrame = blockEquationDeferredRootFrame[
      KeyTake[#1, {"Root", "RootSquare"}] & /@ allRoots[[selectedIndices]],
      variables, epsilon];
    If[Lookup[stableFrame, "Status", None] =!= "StableRootOrder",
      Return[<|"Status" -> "DeferredBundleRootUnionInvalid",
        "Detail" -> stableFrame|>]];
    rootIndices = selectedIndices[[Lookup[stableFrame["Roots"],
      "SourceIndex", {}]]]];
  If[AssociationQ[deferredPreparation],
    preparationIndices = Table[Module[{matches},
        matches = Flatten[Position[allRoots,
          candidate_ /; TrueQ[Together[
              candidate["RootSquare"] - square] === 0],
          {1}, Heads -> False]];
        If[Length[matches] =!= 1,
          Return[<|"Status" -> "DeferredPreparationRootFrameMismatch",
            "RootSquare" -> square, "Matches" -> matches|>, Module]];
        First[matches]],
      {square, preparationRootSquares}];
    If[! VectorQ[preparationIndices, IntegerQ],
      Return[FirstCase[preparationIndices, failure_Association :> failure,
        <|"Status" -> "DeferredPreparationRootFrameMismatch"|>]]];
    rootIndices = Sort[DeleteDuplicates[
      Join[rootIndices, preparationIndices]]]];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  (* dD = eps (e.D-D.c)+bbar is solved identically by D=0 when the
     forcing vanishes.  This must precede chart selection: the diagonal
     blocks may span a root set with no joint rational chart even though
     this off-diagonal problem needs no field arithmetic at all. *)
  If[! deferredSourceQ &&
      AllTrue[Flatten[bbar], SameQ[#, 0] &],
    Return[<|"Status" -> "Solved", "Method" -> "ZeroForcing",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
      "Chart" -> None, "Alphabet" -> {}, "ExactDLog" -> True,
      "Certificate" -> "ExactDLog", "FrameCertificate" -> <|
        "Chart" -> None, "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True, "SourceDLog" -> True,
        "SamplingEntered" -> False, "Exact" -> True|>|>]];
  optionRules = FilterRules[{opts}, Options[SolveEpsFormStrip]];
  finiteFieldQ = TrueQ[OptionValue["FiniteFieldFallback"]] ||
    TrueQ[OptionValue["FiniteFieldFirst"]];
  finiteFieldFirstQ = TrueQ[OptionValue["FiniteFieldFirst"]];
  finiteFieldOptions = OptionValue["FiniteFieldOptions"];
  If[! MatchQ[finiteFieldOptions, {___Rule}],
    Return[<|"Status" -> "InvalidFiniteFieldOptions"|>]];
  canonicalKernelCount = OptionValue["CANONICAKernels"];
  scratchDirectory = OptionValue["ScratchDirectory"];
  stripTag = OptionValue["Tag"];
  verbose = OptionValue["Verbose"];
  (* a solved inner strip: exact dlog, or (production check level) the
     finite-field solve's numerical certificate, whose exact statement is
     deferred to the family certificate (2026-08-23) *)
  innerSolvedQ[candidate_] := AssociationQ[candidate] &&
    Lookup[candidate, "Status", None] === "Solved" &&
    (TrueQ[Lookup[candidate, "ExactDLog", False]] ||
      MemberQ[{"NumericalResidual", "PendingPostPullBackResidual"},
        Lookup[candidate, "Certificate", None]]);
  solveRationalStrip = Function[{rationalStrip, rationalVariables},
    Module[{candidate, directory, defaults, finiteOptions},
      (* "FiniteFieldFirst" -> True: no CANONICA/Maple ladder in the
         production loop (user decision 2026-08-22); the finite field
         solves the strip in the targeted chart directly *)
      candidate = If[finiteFieldFirstQ, $Failed,
        SolveEpsFormStrip[
          rationalStrip, rationalVariables, epsilon,
          Sequence @@ optionRules]];
      If[finiteFieldQ && ! innerSolvedQ[candidate],
        directory = Replace[scratchDirectory, {
          Automatic :> FileNameJoin[{$TemporaryDirectory,
            "FeynFacetFiniteField", stripTag}],
          value_String :> FileNameJoin[{value,
            stripTag <> "_finite_field"}]
        }];
        defaults = {
          "KernelCount" -> canonicalKernelCount,
          "ArtifactDirectory" -> directory,
          "ArtifactPrefix" -> stripTag,
          (* the solver inherits THIS call's absolute deadline, so the
             construction stage and the solve share one wall allowance;
             an explicit "Deadline" in "FiniteFieldOptions" comes first
             in the Join below and still wins *)
          "Deadline" -> deadline,
          "Verbose" -> verbose
        };
        finiteOptions = DeleteDuplicatesBy[
          Join[FilterRules[finiteFieldOptions,
            Options[SolveEpsFormStripFiniteField]], defaults], First];
        postPullBackCheckQ = mapleCanonicalQ && rootIndices =!= {};
        If[postPullBackCheckQ,
          finiteOptions = Prepend[
            DeleteCases[finiteOptions, HoldPattern["FinalCheck" -> _]],
            "FinalCheck" -> "PostPullBack"]];
        candidate = SolveEpsFormStripFiniteField[
          <|"Strip" -> rationalStrip, "Variables" -> rationalVariables,
            "Regulator" -> epsilon|>, Sequence @@ finiteOptions];
      ];
      candidate
    ]
  ];

  If[rootIndices === {},
    rationalStrip = strip;
    If[deferredSourceQ,
      data = <|"Status" -> "OK", "Variables" -> variables,
        "SourceVariables" -> variables,
        "Subst" -> Thread[variables -> variables],
        "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1|>];
    If[AssociationQ[deferredBundle] && ! deferredForcingMaterializedQ,
      bundlePullback = transportChartPullBackDeferredBundle[
        deferredBundle, data, {}, {}];
      If[Lookup[bundlePullback, "Status", None] =!= "OK",
        Return[bundlePullback]];
      rationalStrip = ReplacePart[strip, 3 -> bundlePullback["OneForm"]]];
    If[AssociationQ[deferredPreparation],
      preparationPullback = transportChartPullBackDeferredPreparation[
        deferredPreparation, data, {}, {}];
      If[Lookup[preparationPullback, "Status", None] =!= "OK",
        Return[preparationPullback]];
      rationalStrip = ReplacePart[strip, 3 ->
        preparationPullback["OneForm"]]];
    (* BOUNDARY (solver dispatch, rational frame): no solver is entered
       past the deadline *)
    If[transportChartDeadlineExpiredQ[deadline],
      Return[budgetExhausted["SolverDispatch"]]];
    inner = solveRationalStrip[rationalStrip, variables];
    If[! innerSolvedQ[inner], Return[inner]];
    Return[Join[inner, <|"Method" -> "RationalFrame/" <> inner["Method"],
      "RootIndices" -> {}, "FrameCertificate" -> <|
        "Chart" -> None, "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True, "Exact" -> True|>|>]]];

  (* BOUNDARY 2 (chart selection): the catalog walk re-verifies each
     candidate chart's exact root identities *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ChartSelection"]]];
  {stageSeconds, chart} = AbsoluteTiming[
    TransportRootSetChart[rootSquares, variables]];
  timings["ChartSelection"] = stageSeconds;
  If[MissingQ[chart],
    (* F2 (Design/GeneralityFixes2.md, 2026-08-23): no joint rational
       chart is not the end of the road.  The direct multiquadratic
       engine solves such a strip in the grade basis of the declared
       root set.  A reconstructed gauge with certified active dlog
       potentials and independent fresh residuals returns the installable
       "Solved" ABI; an incomplete "ModularConsistent" result is recorded
       but never installed.  The result is returned exactly as the engine
       typed it. *)
    If[! TrueQ[OptionValue["MultiquadraticDispatch"]],
      Return[<|"Status" -> "NoRationalStripChart",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "Disabled"|>]];
    If[verbose, Print["[strip-in-frame] no rational chart for root squares ",
      rootSquares, "; dispatching to the multiquadratic engine"]];
    (* BOUNDARY (solver dispatch, multiquadratic): no engine is entered
       past the deadline, and the engine that IS entered inherits the
       same absolute deadline (an explicit "Deadline" in
       "MultiquadraticOptions" comes first in the Join and still wins) *)
    If[transportChartDeadlineExpiredQ[deadline],
      Return[budgetExhausted["MultiquadraticDispatch"]]];
    bundleRecord = Join[
      <|"Variables" -> variables, "Regulator" -> epsilon, "Strip" -> strip|>,
      If[AssociationQ[deferredBundle],
        <|"DeferredBundle" -> deferredBundle|>, <||>]];
    multiquadraticResult = solveEpsFormStripMultiquadratic[
      bundleRecord,
      frame,
      Sequence @@ DeleteDuplicatesBy[
        Join[multiquadraticOptions,
          {"Deadline" -> deadline, "Verbose" -> TrueQ[verbose]}], First]];
    If[! AssociationQ[multiquadraticResult],
      Return[<|"Status" -> "MultiquadraticDispatchNotTyped",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "Result" -> multiquadraticResult|>]];
    multiquadraticStatus = Lookup[multiquadraticResult, "Status", None];
    If[MemberQ[$transportChartMultiquadraticScopeRefusals, multiquadraticStatus],
      Return[<|"Status" -> "NoRationalStripChart",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "OutOfScope",
        "MultiquadraticRefusal" -> multiquadraticResult|>]];
    (* verbatim, with the frame's own root census added where the engine
       does not carry it (the typed failures do not) *)
    Return[Join[
      <|"RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "Engine"|>,
      multiquadraticResult]]];

  (* BOUNDARY 3 (chart/identity preparation): rekeying, the chart data
     record, the root images and the pulled-back declared squares are one
     Together pass each over the chart's entries *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ChartPreparation"]]];
  stageSeconds = AbsoluteTime[];
  chartVariables = {
    Symbol["FeynFacet`Private`stripChartX"],
    Symbol["FeynFacet`Private`stripChartY"]};
  rekeyed = transportChartRekey[chart, variables, chartVariables];
  data = masterTransportChartData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#["RootSquare"] -
          usedRoots[[i]]["RootSquare"]] === 0] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]],
    {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ],
    Return[<|"Status" -> "StripChartRootMapMissing"|>]];
  chartBranchRoots = Map[
    <|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &,
    usedRoots];
  timings["ChartPreparation"] = AbsoluteTime[] - stageSeconds;
  (* BOUNDARY 4 (before the chart pullback): transportChartPullBackStrip
     is a SINGLE opaque pass -- substitution of the root images into
     every entry of the strip, then one Together over the result -- with
     no interior unit boundary to check.  It is therefore bracketed: the
     deadline is checked before it and again after it, and its measured
     wall time is recorded so a future log shows this substage's cost.
     It is deliberately NOT TimeConstrained (documented trap: a
     TimeConstrained step has escaped its bound in pool subkernels). *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ChartPullBack"]]];
  (* the root images and the pulled-back declared squares are needed
     BEFORE the pullback, not after it: transportChartPullBackStrip
     substitutes them into the chart entries and only then normalizes
     (see the note at its definition) *)
  stageSeconds = AbsoluteTime[];
  chartStrip = transportChartPullBackStrip[
    strip, data, chartBranchRoots, rootImages];
  If[AssociationQ[deferredBundle] && ! deferredForcingMaterializedQ,
    bundlePullback = transportChartPullBackDeferredBundle[
      deferredBundle, data, chartBranchRoots, rootImages];
    If[Lookup[bundlePullback, "Status", None] =!= "OK",
      Return[bundlePullback]];
    chartStrip[[3]] = bundlePullback["OneForm"]];
  If[AssociationQ[deferredPreparation],
    preparationPullback = transportChartPullBackDeferredPreparation[
      deferredPreparation, data, chartBranchRoots, rootImages];
    If[Lookup[preparationPullback, "Status", None] =!= "OK",
      Return[preparationPullback]];
    chartStrip[[3]] = preparationPullback["OneForm"]];
  timings["ChartPullBack"] = AbsoluteTime[] - stageSeconds;
  (* BOUNDARY 5 (after the pullback; also the last boundary before a
     solver runs on the chart route) *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ChartPullBackComplete"]]];
  transportChartStageStart["inner solve",
    <|"chart" -> chart["Name"], "strip" -> stripDimensions,
      "leafCount" -> transportChartStageSize[chartStrip]|>];
  {stageSeconds, inner} = AbsoluteTiming[
    solveRationalStrip[chartStrip, chartVariables]];
  timings["InnerSolve"] = stageSeconds;
  transportChartStageDone["inner solve",
    <|"seconds" -> stageSeconds,
      "status" -> Lookup[inner, "Status", None]|>];
  If[! innerSolvedQ[inner], Return[inner]];
  chartGauge = inner["Gauge"];

  (* BOUNDARY 6 (gauge pullback): the coordinate-map composition is
     re-verified exactly and the branch search evaluates 2^r sign
     choices, each a full Together of the gauge.  A stop here discards no
     solved work: the inner solver's per-prime artifacts are on disk and
     the construction is a pure function of the strip and the frame, so
     the next run replays it. *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["GaugePullBack"]]];
  stageSeconds = AbsoluteTime[];
  transportChartStageStart["acceptance: gauge pull-back",
    <|"chart" -> chart["Name"], "gauge" -> Dimensions[chartGauge],
      "gaugeLeafCount" -> transportChartStageSize[chartGauge],
      "roots" -> Length[usedRoots],
      "branches" -> 2^Length[usedRoots],
      "alphabet" -> Length[Lookup[inner, "Alphabet", {}]]|>];

  identityData = <|"Status" -> "OK", "Kind" -> "TwoVariable",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> variables, "SourceVariables" -> variables,
    "Subst" -> Thread[variables -> variables],
    "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
    "Root" -> If[allRoots === {}, None, allRoots[[1]]["Root"]],
    "RootSquare" -> If[allRoots === {}, None,
      allRoots[[1]]["RootSquare"]], "Roots" -> allRoots|>;
  coordinateMap = masterTransportRecordCoordinateMap[
    <|"Variables" -> chartVariables, "Chart" -> rekeyed|>,
    identityData, Automatic];
  If[Lookup[coordinateMap, "Status", None] =!= "OK",
    Return[<|"Status" -> "StripGaugePullBackFailed",
      "CoordinateMap" -> coordinateMap|>]];
  (* The INVERSE of a joint chart is obtained by solving, and Solve emits
     the second chart variable with a NESTED radicand -- for CF303
     {17,12} in Kallen23 the image carried
     Sqrt[2] Sqrt[q2 (u + v Sqrt[q1])] -- which lies in the declared field
     (2 (u + v Sqrt[q1]) == ((1+x+y) + Sqrt[q1])^2 there) but is not a
     rational-square multiple of any declared square, so neither the
     branch substitution nor any comparison below can handle it.  It is
     rewritten in the declared radicals ONCE, here, before it reaches the
     gauge: the pulled-back gauge that this function RETURNS is then an
     element of the frame's own multiquadratic field, which is what every
     consumer of the record assumes.  A frame image that cannot be
     rewritten stops the construction typed. *)
  mapCanonicalization = transportChartCanonicalizeFrameImages[
    Last /@ coordinateMap["Map"], allRoots, variables];
  If[Lookup[mapCanonicalization, "Status", None] =!= "OK",
    Return[<|"Status" -> "StripGaugeMapNotInDeclaredField",
      "CoordinateMap" -> KeyDrop[coordinateMap, "Images"],
      "Canonicalization" -> mapCanonicalization|>]];
  If[verbose && mapCanonicalization["Rewritten"] > 0,
    Print["[strip-in-frame] ", mapCanonicalization["Rewritten"],
      " coordinate-map radical(s) rewritten in the declared field: ",
      mapCanonicalization["RewrittenBases"]]];
  coordinateMap = Join[coordinateMap, <|
    "Map" -> MapThread[Rule, {First /@ coordinateMap["Map"],
      mapCanonicalization["Images"]}],
    "Images" -> mapCanonicalization["Images"],
    "DeclaredFieldRewrites" -> KeyTake[mapCanonicalization,
      {"Rewritten", "RewrittenBases", "NumericRadicalClasses"}]|>];
  transportChartStageMark["acceptance: coordinate map",
    <|"seconds" -> N[AbsoluteTime[] - stageSeconds],
      "rewritten" -> Lookup[mapCanonicalization, "Rewritten", 0]|>];

  If[mapleCanonicalQ,
    preNormalizationGauge = chartGauge /. coordinateMap["Map"];
    If[! FreeQ[preNormalizationGauge, Alternatives @@ chartVariables],
      Return[<|"Status" -> "MapleGaugeCarriesChartVariables",
        "ChartVariables" -> chartVariables|>]];
    mapleGauge = transportChartMapleCanonicalGauge[
      preNormalizationGauge, variables, epsilon, allRoots,
      "MapleExecutable" -> OptionValue["MapleExecutable"],
      "ScratchDirectory" -> scratchDirectory,
      "Tag" -> ToString[stripTag] <> "_chart_gauge",
      "TimeLimit" -> OptionValue["MapleTimeLimit"],
      "Verbose" -> verbose];
    If[Lookup[mapleGauge, "Status", None] =!=
        "MapleCanonicalGaugePrepared",
      Return[<|"Status" -> "StripGaugeMapleCanonicalizationFailed",
        "Detail" -> KeyDrop[mapleGauge, "Result"]|>]];
    sourceGauge = mapleGauge["Result"];
    substageSeconds = mapleGauge["Seconds"];
    parallelTogether = <|"Route" -> "MapleCanonical",
      "Helpers" -> 0|>,
    parallelTogether = transportChartParallelTogether[
      chartGauge, coordinateMap["Map"], "chartgauge", deadline];
    If[Lookup[parallelTogether, "Status", None] === "DeadlineExpired",
      timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
      Return[budgetExhausted["GaugePullBack"]]];
    If[Lookup[parallelTogether, "Status", None] =!= "OK",
      Return[<|"Status" -> "StripGaugeSubstitutionFailed",
        "Detail" -> parallelTogether|>]];
    sourceGauge = parallelTogether["Result"];
    substageSeconds = parallelTogether["Seconds"]];
  transportChartStageMark["acceptance: source gauge substitution",
    <|"seconds" -> N[substageSeconds],
      "leafCount" -> transportChartStageSize[sourceGauge],
      "route" -> parallelTogether["Route"],
      "helpers" -> parallelTogether["Helpers"]|>];
  {substageSeconds, sourceAlphabet} = AbsoluteTiming[
    DeleteDuplicates[Together /@
      (Lookup[inner, "Alphabet", {}] /. coordinateMap["Map"])]];
  transportChartStageMark["acceptance: source alphabet",
    <|"seconds" -> N[substageSeconds], "letters" -> Length[sourceAlphabet]|>];

  (* In production the one block residual is deliberately run HERE, on the
     Maple-normalized gauge that will actually be installed.  Trying every
     chart-root sheet also fixes the unique branch.  This replaces (rather
     than duplicates) the inner solver's final residual; the latter returned
     PendingPostPullBackResidual above. *)
  If[mapleCanonicalQ,
    sourceGaugeRadicalFreeQ = FreeQ[sourceGauge,
      Power[_, exponent_Rational /; Denominator[exponent] > 1]];
    signChoices = If[sourceGaugeRadicalFreeQ,
      {ConstantArray[1, Length[usedRoots]]},
      Tuples[{1, -1}, Length[usedRoots]]];
    postPullBackCandidates = Table[
      branchImages = MapThread[Times, {signs, rootImages}];
      postPullBackGauge = transportChartApplyRootBranches[
          sourceGauge, usedRoots, branchImages] /. data["Subst"];
      postPullBackVerification = VerifyEpsFormStrip[
        <|"Strip" -> chartStrip, "Variables" -> chartVariables,
          "Regulator" -> epsilon|>,
        Join[KeyTake[inner, {"Alphabet", "ResidueMatrices"}],
          <|"Gauge" -> postPullBackGauge|>],
        "Method" -> "Numerical", "KernelCount" -> 1];
      <|"Signs" -> signs, "Verification" -> postPullBackVerification|>,
      {signs, signChoices}];
    postPullBackCandidates = Select[postPullBackCandidates,
      TrueQ[Lookup[Lookup[#1, "Verification", <||>],
        "DLogFormCertified", False]] &];
    If[postPullBackCandidates === {},
      Return[<|"Status" -> "PostMapleResidualFailed",
        "PassingBranchCount" -> 0,
        "BranchCount" -> Length[signChoices]|>]];
    acceptedSigns = {
      Lookup[First[postPullBackCandidates], "Signs", Missing[]]};
    postPullBackVerification = Lookup[
      First[postPullBackCandidates], "Verification", <||>];
    inner = Join[inner,
      KeyTake[postPullBackVerification,
        {"NumericalPfaffianResidualsZero", "LettersEpsFree",
         "ResiduesKinematicsFree", "ResiduesEpsFree"}],
      <|"Certificate" -> "NumericalResidual",
        "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
        "DLogFormCertified" -> Missing["DeferredToFamilyCertificate"]|>];
    timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
    transportChartStageDone["acceptance: gauge pull-back",
      <|"seconds" -> timings["GaugePullBack"],
        "route" -> "MapleCanonical",
        "branchSigns" -> First[acceptedSigns],
        "familyCertificate" -> "Required"|>];
    transportChartLogSuccessTimings[timings, chart["Name"], verbose];
    Return[<|"Status" -> "Solved",
      "Method" -> "RationalChart/" <> chart["Name"] <> "/" <>
        inner["Method"],
      "Gauge" -> sourceGauge, "RootIndices" -> rootIndices,
      "RootSquares" -> rootSquares, "Chart" -> chart,
      "Alphabet" -> sourceAlphabet,
      "InnerSolution" -> KeyDrop[inner, "Gauge"],
      "ExactDLog" -> Lookup[inner, "ExactDLog", False],
      "Certificate" -> Lookup[inner, "Certificate", "ExactDLog"],
      "FrameCertificate" -> <|
        "CoordinateComposition" ->
          TrueQ[coordinateMap["CompositionExact"]],
        "BranchSigns" -> First[acceptedSigns],
        "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True,
        "SourceDLog" -> Missing["DeferredToFamilyCertificate"],
        "Exact" -> False,
        "ValidationMode" -> "PostMapleFiniteFieldResidual",
        "InnerCertificate" -> Lookup[inner, "Certificate", None],
        "UnseenPrime" -> Lookup[inner, "UnseenPrime", None],
        "NumericalPfaffianResidualsZero" -> Lookup[inner,
          "NumericalPfaffianResidualsZero", Missing["NotRun"]],
        "Normalizer" -> KeyDrop[mapleGauge, "Result"]|>|>]];

  signChoices = Tuples[{1, -1}, Length[usedRoots]];
  (* Together is canonical on rational entries only.  When the branch
     substitution has left a radical standing, a Together comparison is a
     FALSE NEGATIVE machine (2026-08-25): the exact test over the
     declared field decides those entries, and an entry that is not in
     the declared field is recorded and refused typed -- never silently
     counted as "not zero". *)
  comparatorRefusals = {};
  (* Ordered PER-ENTRY loop (Codex 14:30).  The verdict is exactly the
     one the previous whole-matrix form returned -- the same predicate
     over the same entries in the same order, and AllTrue already stopped
     at the first False -- but the normalization now happens INSIDE the
     loop instead of over the whole matrix up front, so:
       - a certified nonzero entry ends the test without normalizing the
         rest of the matrix (the early exit is now real, not just an
         early Boolean);
       - the absolute deadline is read BETWEEN entries and leaves by
         Throw with a typed budget payload.  Not TimeConstrained: it does
         not bound broker helpers and has escaped in pool subkernels
         (CLAUDE.md);
       - progress is rate limited to done/total.
     A 20-minute entry normalization is still not preemptible inside a
     single Together; the boundary is the entry, which is the finest one
     that exists without changing what is computed. *)
  zeroMatrixNamedQ[stage_String, matrix_] := Module[
    {entries, total, index = 0, started = AbsoluteTime[], verdict, entry,
     normalized, result = True},
    entries = Flatten[matrix];
    total = Length[entries];
    (* seed the rate limiter at the START of this test, so a zero test
       that finishes inside one interval prints nothing at all and only a
       genuinely slow one narrates itself *)
    If[transportChartStageLogQ[],
      $transportChartStageLastProgress["acceptance: " <> stage] =
        AbsoluteTime[]];
    Do[
      index++;
      (* BOUNDARY: between entries, before this entry is normalized *)
      If[transportChartDeadlineExpiredQ[deadline],
        Throw[<|"Substage" -> stage, "Entry" -> index, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>,
          $transportChartZeroTestTag]];
      transportChartStageProgress["acceptance: " <> stage,
        <|"entry" -> index, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      normalized = Together[entry];
      verdict = If[FreeQ[normalized, Power[_, _Rational]],
        TrueQ[normalized === 0],
        (* the FRAME's declared roots, not just the strip's: a rewrite may
           legitimately name a declared root the strip itself never used *)
        Module[{algebraic = transportChartAlgebraicZeroQ[normalized, allRoots]},
          If[algebraic === $Failed,
            AppendTo[comparatorRefusals,
              transportChartRadicalBases[normalized]];
            False,
            TrueQ[algebraic]]]];
      If[! verdict, result = False; Break[]],
      {entry, entries}];
    result];
  zeroTestStop = None;
  {substageSeconds, acceptedSigns} = AbsoluteTiming[
    Catch[
      Select[signChoices, Function[signs,
        branchImages = MapThread[Times, {signs, rootImages}];
        branchedGauge = transportChartApplyRootBranches[
          sourceGauge, usedRoots, branchImages];
        zeroMatrixNamedQ["gauge round-trip zero test",
          (branchedGauge /. data["Subst"]) - chartGauge]]],
      $transportChartZeroTestTag,
      Function[{payload, tag}, zeroTestStop = payload; {}]]];
  transportChartStageMark["acceptance: branch round trip",
    <|"seconds" -> N[substageSeconds], "branches" -> Length[signChoices],
      "accepted" -> Length[acceptedSigns],
      "refusals" -> Length[comparatorRefusals]|>];
  (* the SUBSTAGE vocabulary is unchanged -- t_construction_budget
     declares it and a stop outside it is a defect -- so the zero test's
     own position travels in its own keys, not in the substage name *)
  If[AssociationQ[zeroTestStop],
    timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
    Return[Join[budgetExhausted["GaugePullBack"],
      <|"ZeroTestSubstage" -> Lookup[zeroTestStop, "Substage", "ZeroTest"]|>,
      KeyDrop[zeroTestStop, "Substage"]]]];
  If[acceptedSigns === {},
    Return[If[comparatorRefusals === {},
      <|"Status" -> "StripGaugeRoundTripFailed"|>,
      <|"Status" -> "StripGaugeRoundTripUndeclaredRadicals",
        "RadicalBases" -> DeleteDuplicates[Flatten[comparatorRefusals]],
        "CoordinateMapRewrites" ->
          Lookup[coordinateMap, "DeclaredFieldRewrites", <||>]|>]]];
  branchImages = MapThread[Times, {First[acceptedSigns], rootImages}];
  timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
  transportChartStageDone["acceptance: gauge pull-back",
    <|"seconds" -> timings["GaugePullBack"],
      "branchSigns" -> First[acceptedSigns]|>];

  (* BOUNDARY 7 (before the source-frame identity check): the check
     re-derives the transformed one-form in the ALGEBRAIC frame, applies
     the branch images and pulls the pair back through the Jacobian --
     the most expensive exact step of the construction on a large
     strip. *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["SourceFrameIdentity"]]];
  stageSeconds = AbsoluteTime[];
  transportChartStageStart["acceptance: source-frame identity",
    <|"chart" -> chart["Name"], "gauge" -> Dimensions[sourceGauge],
      "sourceGaugeLeafCount" -> transportChartStageSize[sourceGauge],
      "chartGaugeLeafCount" -> transportChartStageSize[chartGauge],
      "roots" -> Length[usedRoots]|>];

  (* Same ordering rule as the pullback above: the source-frame
     transformed one-form carries the declared radicals in every entry,
     so it is NOT normalized here.  The branch images are substituted
     first and the canonical Together is taken inside pullPair, on
     entries that are rational in the chart variables.  The chart-frame
     side is rational from the start and is normalized as before.  For a
     deferred bundle, its forcing was already pulled back operandwise and
     checked to be radical-free above; add that exact chart one-form after
     pulling the gauge terms instead of materializing the source-frame sum. *)
  {substageSeconds, sourceTransformed} = AbsoluteTiming[Table[
    If[deferredSourceQ,
      0, bbar[[mu]]] +
      epsilon (e[[mu]] . sourceGauge -
      sourceGauge . c[[mu]]) - D[sourceGauge, variables[[mu]]],
    {mu, 2}]];
  transportChartStageMark["acceptance: source one-form",
    <|"seconds" -> N[substageSeconds],
      "leafCount" -> transportChartStageSize[sourceTransformed]|>];
  {substageSeconds, chartTransformed} = AbsoluteTiming[Table[Map[Together,
    chartStrip[[3, mu]] + epsilon (chartStrip[[1, mu]] . chartGauge -
      chartGauge . chartStrip[[2, mu]]) -
      D[chartGauge, chartVariables[[mu]]], {2}], {mu, 2}]];
  transportChartStageMark["acceptance: chart one-form",
    <|"seconds" -> N[substageSeconds],
      "leafCount" -> transportChartStageSize[chartTransformed]|>];
  branchedGauge = transportChartApplyRootBranches[
    sourceTransformed, usedRoots, branchImages];
  pullPair[pair_] := Module[{components},
    components = Map[
      Map[Together, # /. data["Subst"], {2}] &, pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]], data["Jacobian"]]
  ];
  {substageSeconds, pulledTransformed} = AbsoluteTiming[Module[{pulled},
    pulled = pullPair[branchedGauge];
    If[deferredSourceQ,
      Map[Together, pulled + chartStrip[[3]], {2}], pulled]]];
  transportChartStageMark["acceptance: Jacobian pull-back",
    <|"seconds" -> N[substageSeconds],
      "leafCount" -> transportChartStageSize[pulledTransformed]|>];
  comparatorRefusals = {};
  transportChartStageStart["acceptance: one-form zero test",
    <|"entries" -> 2 Times @@ Take[Dimensions[chartTransformed], {2, 3}],
      "roots" -> Length[usedRoots]|>];
  zeroTestStop = None;
  identityHolds = Catch[
    zeroMatrixNamedQ["source-frame zero test mu=1",
        pulledTransformed[[1]] - chartTransformed[[1]]] &&
      zeroMatrixNamedQ["source-frame zero test mu=2",
        pulledTransformed[[2]] - chartTransformed[[2]]],
    $transportChartZeroTestTag,
    Function[{payload, tag}, zeroTestStop = payload; False]];
  If[AssociationQ[zeroTestStop],
    timings["SourceFrameIdentity"] = AbsoluteTime[] - stageSeconds;
    Return[Join[budgetExhausted["SourceFrameIdentity"],
      <|"ZeroTestSubstage" -> Lookup[zeroTestStop, "Substage", "ZeroTest"]|>,
      KeyDrop[zeroTestStop, "Substage"]]]];
  transportChartStageDone["acceptance: one-form zero test",
    <|"seconds" -> N[AbsoluteTime[] - stageSeconds],
      "identity" -> identityHolds|>];
  If[! identityHolds,
    Return[If[comparatorRefusals === {},
      <|"Status" -> "StripGaugeSourceFrameIdentityFailed"|>,
      <|"Status" -> "StripGaugeSourceFrameUndeclaredRadicals",
        "RadicalBases" -> DeleteDuplicates[Flatten[comparatorRefusals]]|>]]];
  timings["SourceFrameIdentity"] = AbsoluteTime[] - stageSeconds;
  transportChartStageDone["acceptance: source-frame identity",
    <|"seconds" -> timings["SourceFrameIdentity"]|>];
  (* one rate-limited success diagnostic: the payload below is unchanged *)
  transportChartLogSuccessTimings[timings, chart["Name"], verbose];

  (* the success payload is byte-identical to the pre-deadline result:
     the substage timings are diagnostics of a STOP and are deliberately
     not added here (2026-08-24) *)
  <|"Status" -> "Solved",
    "Method" -> "RationalChart/" <> chart["Name"] <> "/" <> inner["Method"],
    "Gauge" -> sourceGauge, "RootIndices" -> rootIndices,
    "RootSquares" -> rootSquares, "Chart" -> chart,
    "Alphabet" -> sourceAlphabet,
    "InnerSolution" -> KeyDrop[inner, "Gauge"],
    "ExactDLog" -> TrueQ[Lookup[inner, "ExactDLog", False]],
    "Certificate" -> Lookup[inner, "Certificate", "ExactDLog"],
    (* the success payload is byte-identical to the pre-2026-08-25 record:
       the coordinate-map canonicalization is EVIDENCE OF A STOP and of
       the verbose log, never a new key -- t_construction_budget pins this
       payload by hash and other records fingerprint it *)
    "FrameCertificate" -> <|
      "CoordinateComposition" -> coordinateMap["CompositionExact"],
      "BranchSigns" -> First[acceptedSigns],
      "GaugeRoundTrip" -> True,
      "TransformedOneFormPullBack" -> True,
      "SourceDLog" -> True,
      "Exact" -> True|>|>
]
];

transportChartRationalExpressionQ[expr_, variables_List] :=
  FreeQ[Unevaluated[expr], _Root |
    Power[_, exponent_Rational /; Denominator[exponent] > 1]] &&
  PolynomialQ[Numerator[Together[expr]], variables] &&
  PolynomialQ[Denominator[Together[expr]], variables];

ComposeTransportChartExtension[baseChart_Association, rootSquare_,
    extensionRules_List, newVariables : {_Symbol, _Symbol}] := Module[
  {baseVariables, sourceVariables, baseSubst, pullBack, variableRules,
   rootRules, extensionRootRule, extensionRoot, subst, inheritedRoots,
   roots, parentName, name, chart, certificate},

  baseVariables = Lookup[baseChart, "Variables", Missing[]];
  baseSubst = Lookup[baseChart, "Subst", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseChartNotWellFormed"|>]
  ];
  sourceVariables = First /@ baseSubst;
  pullBack = Together[rootSquare /. baseSubst];
  variableRules = Select[extensionRules,
    MemberQ[baseVariables, First[#]] &];
  If[Sort[First /@ variableRules] =!= Sort[baseVariables],
    Return[<|"Status" -> "ExtensionVariablesNotMapped",
      "Expected" -> baseVariables|>]
  ];
  variableRules = Table[
    variable -> (variable /. variableRules), {variable, baseVariables}];
  If[! AllTrue[Last /@ variableRules,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ExtensionMapNotRational"|>]
  ];

  rootRules = Select[extensionRules,
    ! MemberQ[baseVariables, First[#]] &];
  extensionRootRule = SelectFirst[rootRules,
    TrueQ[Together[(Last[#] /. variableRules)^2 -
          (pullBack /. variableRules)] === 0] &&
      transportChartRationalExpressionQ[
        Last[#] /. variableRules, newVariables] &,
    Missing["NoRootRule"]];
  If[MissingQ[extensionRootRule],
    Return[<|"Status" -> "ExtensionRootNotMapped",
      "PulledBackRootSquare" -> pullBack|>]
  ];
  extensionRoot = Together[Last[extensionRootRule] /. variableRules];

  subst = Map[
    Function[rule, First[rule] -> Together[Last[rule] /. variableRules]],
    baseSubst];
  If[! AllTrue[Last /@ subst,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ComposedMapNotRational"|>]
  ];
  inheritedRoots = Lookup[baseChart, "Roots",
    {<|"Root" -> baseChart["Root"],
       "RootSquare" -> baseChart["RootSquare"]|>}];
  inheritedRoots = Map[
    <|"Root" -> Together[#["Root"] /. variableRules],
      "RootSquare" -> #["RootSquare"]|> &,
    inheritedRoots];
  roots = Append[inheritedRoots,
    <|"Root" -> extensionRoot, "RootSquare" -> rootSquare|>];
  parentName = Lookup[baseChart, "Name", "BaseChart"];
  name = parentName <> "+" <>
    StringTake[IntegerString[Hash[rootSquare, "SHA256"], 16], 12];
  chart = <|
    "Status" -> "Candidate",
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "Variables" -> newVariables,
    "SourceVariables" -> sourceVariables,
    "Subst" -> subst,
    "Root" -> extensionRoot,
    "RootSquare" -> rootSquare,
    "Roots" -> roots,
    "Parents" -> <|parentName -> variableRules|>,
    "ParentCharts" -> <|parentName -> baseChart|>,
    "Extension" -> <|
      "BaseChart" -> parentName,
      "PulledBackRootSquare" -> pullBack,
      "Rules" -> extensionRules|>
  |>;
  certificate = TransportChartVerify[chart];
  If[! TrueQ[certificate["OK"]],
    Return[<|"Status" -> "ExtensionIdentityFailed",
      "Chart" -> chart, "Certificate" -> certificate|>]
  ];
  Join[chart, <|"Status" -> "ExactChart",
    "ChartCertificate" -> certificate|>]
];

ComposeTransportChartExtension[___] :=
  <|"Status" -> "InvalidChartExtensionArguments"|>;

transportChartLoadRationalizeRoots[] := Module[{file, function},
  function = ToExpression["RationalizeRoots`RationalizeRoot"];
  If[DownValues[Evaluate[function]] =!= {}, Return[True]];
  file = FileNameJoin[{$feynFacetAddonRoot, "Addon", "Mathematica_Addon",
    "RationalizeRoots", "RationalizeRoots.m"}];
  If[! FileExistsQ[file], Return[False]];
  Quiet[Check[Get[file], Return[False]]];
  DownValues[Evaluate[function]] =!= {}
];

transportChartExtensionCandidates[raw_, baseVariables_List] :=
  DeleteDuplicates[Cases[raw,
    rules : {__Rule} /;
      ContainsAll[First /@ rules, baseVariables] :> rules,
    {0, Infinity}], SameTest -> SameQ];

Options[RationalizeTransportChartExtension] = {
  "Name" -> Automatic,
  "OutputVariables" -> Automatic,
  "AllCharts" -> True,
  "AllPoints" -> True,
  "TimeConstraint" -> 1800
};

RationalizeTransportChartExtension[baseChart_Association, rootSquare_,
    OptionsPattern[]] := Module[
  {baseVariables, baseSubst, pullBack, outputVariables, allCharts,
   allPoints, timeConstraint, raw, candidates, charts, exactCharts,
   selected, requestedName},

  If[! transportChartLoadRationalizeRoots[],
    Return[<|"Status" -> "RationalizeRootsUnavailable"|>]
  ];
  baseVariables = Lookup[baseChart, "Variables", Missing[]];
  baseSubst = Lookup[baseChart, "Subst", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseChartNotWellFormed"|>]
  ];
  pullBack = Together[rootSquare /. baseSubst];
  (* C4 (generality pass 2026-08-23): the default output variables were
     Global`r and Global`t, which collide with any caller working in those
     symbols (and with packages that dump short names into Global`).  The
     default is now a fresh package-private pair, and an explicit choice
     that meets the base chart's own variables is refused rather than
     silently identified with them. *)
  outputVariables = Replace[OptionValue["OutputVariables"],
    Automatic :> {Unique["FeynFacet`Private`chartExtensionU"],
      Unique["FeynFacet`Private`chartExtensionV"]}];
  If[! MatchQ[outputVariables, {_Symbol, _Symbol}] ||
      ! DuplicateFreeQ[outputVariables],
    Return[<|"Status" -> "InvalidOutputVariables"|>]
  ];
  If[Intersection[outputVariables, baseVariables] =!= {},
    Return[<|"Status" -> "OutputVariablesCollideWithBaseChart",
      "OutputVariables" -> outputVariables,
      "BaseVariables" -> baseVariables|>]
  ];
  allCharts = TrueQ[OptionValue["AllCharts"]];
  allPoints = TrueQ[OptionValue["AllPoints"]];
  timeConstraint = OptionValue["TimeConstraint"];
  raw = TimeConstrained[
    RationalizeRoots`RationalizeRoot[
      Sqrt[pullBack],
      Variables -> baseVariables,
      RationalizeRoots`OutputVariables -> outputVariables,
      RationalizeRoots`RootOutput -> True,
      RationalizeRoots`MultipleSolutions -> True,
      RationalizeRoots`AllCharts -> allCharts,
      RationalizeRoots`AllPoints -> allPoints],
    timeConstraint, $TimedOut];
  If[raw === $TimedOut,
    Return[<|"Status" -> "RationalizationTimedOut",
      "Seconds" -> timeConstraint,
      "PulledBackRootSquare" -> pullBack|>]
  ];
  candidates = transportChartExtensionCandidates[raw, baseVariables];
  charts = ComposeTransportChartExtension[
      baseChart, rootSquare, #, outputVariables] & /@ candidates;
  exactCharts = Select[charts,
    Lookup[#, "Status", None] === "ExactChart" &];
  If[exactCharts === {},
    Return[<|"Status" -> "NoExactRationalExtension",
      "PulledBackRootSquare" -> pullBack,
      "CandidateCount" -> Length[candidates],
      "CandidateResults" -> charts|>]
  ];
  selected = First@MinimalBy[exactCharts,
    LeafCount[Lookup[#, "Subst", {}]] +
      LeafCount[Lookup[#, "Roots", {}]] &];
  requestedName = OptionValue["Name"];
  If[StringQ[requestedName], selected["Name"] = requestedName];
  Join[selected, <|
    "RationalizeRootsCandidateCount" -> Length[candidates],
    "ExactCandidateCount" -> Length[exactCharts]|>]
];

(* ------------------------------------------------------------------ *)
(*  The per-family chart REGISTRY                                       *)
(* ------------------------------------------------------------------ *)
(* Generality pass 2026-08-23 (user directive: the package is general,
   the inventory is project data).  The literal per-family table that
   lived here until then -- 47 entries of the ppHX NNLO double-real
   inventory, measured 2026-08-17 from the class assignment, the class
   forms and each family's raw alphabet -- was moved verbatim to
   ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/TransportFamilyCharts.wl
   after an entry-by-entry round trip (44 catalog-chart names identical
   and present in TransportChartCatalog[], 3 root-square lists
   Together-zero against the package table).  The package now ships an
   EMPTY registry; a campaign registers its own inventory.

   A registered value is one of
     "ChartName"    a key of TransportChartCatalog[];
     "RootSquares"  <|"RootSquares" -> {polynomials in the source
                    variables}|>, the exact multiquadratic identity frame
                    for a root set with no global rational chart;
     "ChartAlias"   <|"ChartAlias" -> catalog name|>, a legacy record
                    string (a descriptive substitution) that stands for a
                    catalog chart -- the table this replaces lived in
                    FamilyEpsForm.wl until 2026-08-23 (A3).
   An UNREGISTERED family is Missing["FamilyChartNotRegistered", family],
   never None: None means "root-free, transport in the source variables"
   and would silently mistransport a rooted family whose registration is
   merely absent. *)
$transportFamilyChartRegistry = <||>;

transportFamilyChartEntryKind[value_] := Module[{squares, alias},
  Which[
    StringQ[value],
      If[KeyExistsQ[TransportChartCatalog[], value], "ChartName",
        <|"Status" -> "ChartNameNotInCatalog", "Value" -> value|>],
    ! AssociationQ[value],
      <|"Status" -> "EntryNotStringOrAssociation",
        "Head" -> ToString[Head[value], InputForm]|>,
    KeyExistsQ[value, "RootSquares"],
      If[Keys[value] =!= {"RootSquares"},
        Return[<|"Status" -> "RootSquareEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      squares = value["RootSquares"];
      Which[
        ! ListQ[squares] || squares === {},
          <|"Status" -> "RootSquaresNotANonemptyList"|>,
        ! AllTrue[squares, FreeQ[#, _Root | Power[_, _Rational]] &],
          <|"Status" -> "RootSquareContainsRadicals"|>,
        ! AllTrue[squares, PolynomialQ[#, Variables[#]] &],
          <|"Status" -> "RootSquareNotPolynomial"|>,
        ! AllTrue[squares, Variables[#] =!= {} &],
          <|"Status" -> "RootSquareHasNoVariables"|>,
        True, "RootSquares"],
    KeyExistsQ[value, "ChartAlias"],
      alias = value["ChartAlias"];
      If[Keys[value] =!= {"ChartAlias"},
        Return[<|"Status" -> "ChartAliasEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      If[StringQ[alias] && KeyExistsQ[TransportChartCatalog[], alias],
        "ChartAlias",
        <|"Status" -> "ChartAliasNotInCatalog", "Value" -> alias|>],
    True,
      <|"Status" -> "EntryKeysNotRecognized", "Keys" -> Keys[value]|>]
];

(* All or nothing: a rejected entry registers nothing, so a partly
   mistyped project table cannot leave the session half configured. *)
TransportFamilyChartRegister[entries_Association] := Module[
  {kinds, invalid},
  If[! AllTrue[Keys[entries], StringQ],
    Return[<|"Status" -> "FamilyChartKeysNotStrings",
      "Keys" -> Select[Keys[entries], ! StringQ[#] &]|>]];
  kinds = Association @ KeyValueMap[
    #1 -> transportFamilyChartEntryKind[#2] &, entries];
  invalid = Select[kinds, ! StringQ[#] &];
  If[invalid =!= <||>,
    Return[<|"Status" -> "InvalidFamilyChartEntries",
      "Invalid" -> invalid|>]];
  $transportFamilyChartRegistry = Join[
    $transportFamilyChartRegistry, entries];
  <|"Status" -> "FamilyChartsRegistered",
    "Registered" -> Length[entries],
    "Families" -> Sort[Keys[entries]],
    "Kinds" -> Counts[Values[kinds]],
    "RegistrySize" -> Length[$transportFamilyChartRegistry]|>
];
TransportFamilyChartRegister[___] :=
  <|"Status" -> "InvalidFamilyChartRegistration"|>;

TransportFamilyChartLoad[file_String] := Module[{value},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "FamilyChartFileMissing", "File" -> file|>]];
  value = FamilyArtifactRead[file];
  If[! AssociationQ[value],
    Return[<|"Status" -> "FamilyChartFileNotAnAssociation",
      "File" -> file|>]];
  Join[TransportFamilyChartRegister[value], <|"File" -> file|>]
];
TransportFamilyChartLoad[___] :=
  <|"Status" -> "InvalidFamilyChartRegistration"|>;

(* the catalog name a legacy record string stands for, or Missing *)
transportFamilyChartAlias[value_String] := Module[
  {entry = Lookup[$transportFamilyChartRegistry, value, Missing[]]},
  If[AssociationQ[entry] && StringQ[Lookup[entry, "ChartAlias", None]] &&
      KeyExistsQ[TransportChartCatalog[], entry["ChartAlias"]],
    entry["ChartAlias"], Missing["ChartAliasNotRegistered", value]]];
transportFamilyChartAlias[___] := Missing["ChartAliasNotRegistered"];

TransportFamilyChart[family_String] := TransportFamilyChart[family,
  {$transportChartV, $transportChartW}, Automatic];

TransportFamilyChart[family_String,
    sourceVariables : {_Symbol, _Symbol}] :=
  TransportFamilyChart[family, sourceVariables, Automatic];

TransportFamilyChart[family_String,
    sourceVariables : {_Symbol, _Symbol},
    chartVariables : ({_Symbol, _Symbol} | Automatic)] := Module[
  {entry, kind, record, targetVariables},
  entry = Lookup[$transportFamilyChartRegistry, family,
    Missing["FamilyChartNotRegistered", family]];
  If[MissingQ[entry], Return[Missing["FamilyChartNotRegistered", family]]];
  kind = transportFamilyChartEntryKind[entry];
  If[! StringQ[kind],
    Return[Join[<|"Status" -> "RegisteredFamilyChartInvalid",
      "Family" -> family|>, kind]]];
  Switch[kind,
    "RootSquares",
      targetVariables = Replace[chartVariables,
        Automatic -> {$transportChartX, $transportChartY}];
      BuildAlgebraicTransportFrame[
        entry["RootSquares"] /. Thread[
          {$transportChartV, $transportChartW} -> sourceVariables],
        sourceVariables, targetVariables],
    "ChartName" | "ChartAlias",
      record = masterTransportChartByName[
        If[kind === "ChartAlias", entry["ChartAlias"], entry]];
      (* the catalog record is written in the package's own source and
         chart variables; only a caller asking for other symbols pays the
         rekey (which drops "Parents"/"Notes" by construction) *)
      If[chartVariables === Automatic &&
          sourceVariables === {$transportChartV, $transportChartW},
        record,
        transportChartRekey[record, sourceVariables,
          Replace[chartVariables,
            Automatic -> Lookup[record, "Variables",
              {$transportChartX, $transportChartY}]]]],
    _, Missing["FamilyChartNotRegistered", family]]
];

(* Compose a class record written in ITS OWN two-variable chart with a
   TARGET two-variable chart that rationalizes the record's root:
   solve the record's substitution for the record's variables using the
   target chart's rational root for the same quadratic (both signs), and
   accept a candidate only if the record's Subst at that candidate
   reproduces the target Subst EXACTLY.  Uses the kernel's Solve; the
   acceptance is the identity, never Solve's return shape.

   record chart:  <|"Variables" -> {x', y'}, "Subst" -> {v -> f(x',y'), w -> g(x',y')},
                    "Root" -> rho(x',y'), "RootSquare" -> Q(v,w)|>
   target data:   masterTransportChartData's record ("Subst", "Variables",
                  "Roots" or "Root"/"RootSquare")
   Returns <|"Status" -> "OK", "Map" -> {x' -> ..., y' -> ...}, "Images" -> {...},
             "Sign" -> +-1|> or a named refusal. *)
masterTransportComposeTwoVariableRecord[recordChart_Association,
    targetData_Association, sourceVariables_List] := Module[
  {recVars, recSubst, recRoot, recSquare, tgtVars, tgtSubst, tf, tg, tgtRoots,
   matching, candidates, verified, eqs, sols, coefficientField},
  recVars = Lookup[recordChart, "Variables", $Failed];
  recSubst = Lookup[recordChart, "Subst", $Failed];
  recRoot = Lookup[recordChart, "Root", None];
  recSquare = Lookup[recordChart, "RootSquare", None];
  If[! MatchQ[recVars, {_Symbol, _Symbol}] || ! MatchQ[recSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "RecordChartNotWellFormed"|>]];
  tgtVars = targetData["Variables"];
  coefficientField = Lookup[targetData, "CoefficientField", "Rational"];
  {tf, tg} = Together /@ (Last /@ targetData["Subst"]);
  tgtRoots = Lookup[targetData, "Roots", None];
  If[! ListQ[tgtRoots],
    tgtRoots = If[Lookup[targetData, "Root", None] === None, {},
      {<|"Root" -> targetData["Root"], "RootSquare" -> targetData["RootSquare"]|>}]];
  (* the target root that rationalizes the RECORD's quadratic *)
  matching = If[recSquare === None || recRoot === None, {},
    Select[tgtRoots, TrueQ[Together[#["RootSquare"] - recSquare] === 0] &]];
  (* the record's variables are renamed to FRESH symbols before solving:
     a joint chart keeps the parent's y as its own y, so the record's y
     and the target's y are the same symbol, and Solve would otherwise be
     asked to solve for a symbol that also appears on the right *)
  Module[{fresh, rename, back, fRec, gRec, rhoRec},
    fresh = Table[Unique["masterTransportChartVar"], {2}];
    rename = Thread[recVars -> fresh];
    back = Thread[fresh -> recVars];
    fRec = Last[recSubst[[1]]] /. rename;
    gRec = Last[recSubst[[2]]] /. rename;
    rhoRec = If[recRoot === None, None, recRoot /. rename];
    eqs = {fRec == tf, gRec == tg};
    candidates = If[matching === {},
      (* no root available: try the plain algebraic solve and keep only
         rational solutions *)
      Quiet[Solve[eqs, fresh]],
      (* Table over {root, sign} of Solve's solution LISTS: flatten two
         levels to a plain list of rule lists (one level left each
         candidate as {{rules}} and the identity check below then compared
         a LIST -- measured 2026-08-17 03:20 on class 79 in Kallen23) *)
      Flatten[Table[
        Quiet[Solve[Append[eqs, rhoRec == sign m["Root"]], fresh]],
        {m, matching}, {sign, {1, -1}}], 2]];
    candidates = Select[candidates,
      Which[
        coefficientField === "Rational" || matching === {},
          FreeQ[#, Power[_, _Rational] | _Root],
        coefficientField === "Multiquadratic",
          FreeQ[#, _Root],
        True, False] &];
    verified = Select[candidates,
      TrueQ[Together[(fRec /. #) - tf] === 0] &&
      TrueQ[Together[(gRec /. #) - tg] === 0] &];
    If[verified === {},
      Return[<|"Status" -> "TwoVariableChartsNotComposable",
        "RecordVariables" -> recVars, "TargetVariables" -> tgtVars,
        "MatchingRoots" -> Length[matching], "Candidates" -> Length[candidates]|>]];
    <|"Status" -> "OK",
      "Map" -> Map[Together, First[verified] /. back, {2}],
      "Images" -> Map[Together, fresh /. First[verified]],
      "Candidates" -> Length[candidates], "Verified" -> Length[verified]|>]];
