(* The in-frame off-diagonal strip solver: SolveEpsFormStripInFrame and
   the helpers only it uses.  Moved VERBATIM out of Geometry/TransportCharts.wl
   on 2026-09-02 (round 7, Codex generality finding "the seven layers are not
   acyclic"): the solver calls the EpsForm solvers (SolveEpsFormStripFiniteField,
   VerifyEpsFormStrip, the multiquadratic engine, the deferred block-equation
   bundles, the finite-field gauge pull-back) and inherits
   Options[SolveEpsFormStrip] at load time, so it belongs to EpsForm; the
   chart catalog, verification, registry, extension, root census and the
   record-to-chart coordinate map stay in Geometry, which now loads BEFORE
   EpsForm.  Contents, in the original order: the success-path stage log,
   the broker-parallel Together / projection-decompose / Jacobian-pullback
   tasks, the success timings, the strip and deferred-bundle pullbacks, the
   frame-image canonicalization, the deadline bookkeeping, the option list
   (Join of Options[SolveEpsFormStrip] -- EpsFormStrip.wl loads first), the
   timings separation, the solver, and the RouteRetired stub of the Maple
   canonical gauge.  The usage of SolveEpsFormStripInFrame stays in
   FeynFacet.m; this file does not Clear the public symbol (TransportCharts.wl
   never did either). *)

ClearAll[  transportChartCanonicalizeFrameImages,
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
  transportChartProjectionDecomposeEntry,
  transportChartProjectionDecomposeTask,
  transportChartParallelProjectionDecompose,
  transportChartJacobianTogetherRecipe,
  transportChartJacobianTogetherTask,
  transportChartParallelJacobianPullBack,
  transportChartPullBackDeferredPreparation,
  transportChartMapleCanonicalGauge,
  $transportChartStageLog,
  $transportChartStageLastProgress,
  $transportChartStageProgressInterval,
  $transportChartZeroTestTag,
  transportChartPullBackStrip,
  transportChartPullBackDeferredBundle,
  transportChartTimingKeyQ,
  transportChartSeparateTimings,
  transportChartTimingsRecord,
  $transportChartMultiquadraticScopeRefusals,
  $transportChartSuccessLogInterval,
  $transportChartLastSuccessLogTime
];

(* Success-path stage visibility (Codex 08:30, performance addition 3).
   The two most expensive exact stages of the strip solve
   already MEASURE themselves -- timings["GaugePullBack"] and
   timings["SourceRepresentationIdentity"] -- but the numbers were only ever
   emitted on a budget STOP, so a successful strip left the whole
   interval unattributed (CF303 {17,12}: ~1558 s from strip start to
   exact acceptance, of which the cheap finite-field pilot and held-out
   checks are a small part and the rest was invisible).  The success
   payload contains the same mathematical result; this is one rate-limited
   log line and nothing else. *)
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
        "tctogether_" <> StringReplace[CreateUUID[], "-" -> ""],
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

transportChartProjectionDecomposeEntry[entry_, taggedRoots_List,
    transformedRoots_List, projectionTags_List,
    projectionRootImages_List] := Module[{channels, fallback = 0},
  channels = multiquadraticFieldDecompose[
    entry, taggedRoots, False, False];
  If[channels === $Failed,
    fallback = 1;
    channels = multiquadraticFieldDecompose[
      entry /. Thread[projectionTags -> projectionRootImages],
      transformedRoots, False]];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[taggedRoots],
    $Failed, <|"Channels" -> channels, "Fallback" -> fallback|>]
];
transportChartProjectionDecomposeEntry[___] := $Failed;

transportChartProjectionDecomposeTask[dataFile_String] := Module[
  {data = taskBrokerRead[dataFile], entries},
  If[! AssociationQ[data], Return[$Failed]];
  entries = Lookup[data, "Entries", $Failed];
  If[! ListQ[entries], Return[$Failed]];
  transportChartProjectionDecomposeEntry[#1,
      data["TaggedRoots"], data["TransformedRoots"], data["Tags"],
      data["SquareRootGeneratorImages"]] & /@ entries
];

transportChartParallelProjectionDecompose[image_, taggedRoots_List,
    transformedRoots_List, projectionTags_List,
    projectionRootImages_List, label_String] := Module[
  {started = AbsoluteTime[], dimensions = Dimensions[image], entries,
   gradeCount = 2^Length[taggedRoots], results, helpers, bytes,
   localIndex, helperIndices, helperBatches, batchLoads, targetBatch,
   payload, dataFiles, codes, handle, farmed, missing, channelVectors,
   route = "Serial"},
  If[Length[dimensions] =!= 3 || First[dimensions] =!= 2 ||
      Length[taggedRoots] =!= Length[transformedRoots] ||
      Length[taggedRoots] =!= Length[projectionTags] ||
      Length[taggedRoots] =!= Length[projectionRootImages],
    Return[<|"Status" -> "InvalidProjectionDecompositionInput"|>]];
  entries = Flatten[image];
  If[entries === {},
    Return[<|"Status" -> "OK", "Channels" ->
        ArrayReshape[{}, Append[dimensions, gradeCount]],
      "Fallbacks" -> 0, "Route" -> "Serial", "Helpers" -> 0,
      "Seconds" -> 0.|>]];
  results = ConstantArray[$Failed, Length[entries]];
  helpers = If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0];
  helpers = Min[helpers, Max[0, Length[entries] - 1]];
  If[helpers < 1,
    results = transportChartProjectionDecomposeEntry[#1, taggedRoots,
        transformedRoots, projectionTags, projectionRootImages] & /@ entries,
    route = "Parallel";
    bytes = ByteCount /@ entries;
    localIndex = First[Ordering[bytes, -1]];
    helperIndices = DeleteCases[Range[Length[entries]], localIndex];
    helperBatches = ConstantArray[{}, helpers];
    batchLoads = ConstantArray[0, helpers];
    Do[
      targetBatch = First[Ordering[batchLoads, 1]];
      helperBatches[[targetBatch]] = Append[
        helperBatches[[targetBatch]], index];
      batchLoads[[targetBatch]] += bytes[[index]],
      {index, SortBy[helperIndices, -bytes[[#1]] &]}];
    payload[batch_] := <|"Entries" -> entries[[batch]],
      "TaggedRoots" -> taggedRoots,
      "TransformedRoots" -> transformedRoots,
      "Tags" -> projectionTags,
      "SquareRootGeneratorImages" -> projectionRootImages|>;
    dataFiles = Map[Function[batch, taskBrokerDataFile[
        "tcprojection_" <> StringReplace[CreateUUID[], "-" -> ""],
        payload[batch]]], helperBatches];
    codes = StringJoin[
        "FeynFacet`Private`transportChartProjectionDecomposeTask[\"",
        #1, "\"]"] & /@ dataFiles;
    handle = taskBrokerSubmit[codes, "Label" -> label,
      "Timeout" -> 7200.];
    results[[localIndex]] = transportChartProjectionDecomposeEntry[
      entries[[localIndex]], taggedRoots, transformedRoots,
      projectionTags, projectionRootImages];
    farmed = taskBrokerCollect[handle];
    If[ListQ[farmed],
      Do[If[index <= Length[farmed] && ListQ[farmed[[index]]] &&
            Length[farmed[[index]]] === Length[helperBatches[[index]]],
          results[[helperBatches[[index]]]] = farmed[[index]]],
        {index, Length[helperBatches]}]];
    missing = Select[helperIndices, results[[#1]] === $Failed &];
    If[missing =!= {},
      results[[missing]] =
        transportChartProjectionDecomposeEntry[#1, taggedRoots,
          transformedRoots, projectionTags, projectionRootImages] & /@
            entries[[missing]]]];
  missing = Select[Range[Length[results]],
    ! AssociationQ[results[[#1]]] &];
  If[missing =!= {},
    Return[<|"Status" -> "ProjectionDecompositionFailed",
      "EntryIndices" -> missing, "Route" -> route,
      "Helpers" -> If[route === "Parallel", helpers, 0],
      "Seconds" -> N[AbsoluteTime[] - started]|>]];
  channelVectors = Lookup[results, "Channels", $Failed];
  <|"Status" -> "OK",
    "Channels" -> ArrayReshape[Flatten[channelVectors],
      Append[dimensions, gradeCount]],
    "Fallbacks" -> Total[Lookup[results, "Fallback", 0]],
    "Route" -> route, "Helpers" -> If[route === "Parallel", helpers, 0],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartParallelProjectionDecompose[___] :=
  <|"Status" -> "InvalidParallelProjectionDecompositionInput"|>;

(* Form the Jacobian combinations on the workers, not before dispatch.
   Passing an already formed A_v J + A_w J to transportChartParallelTogether
   still lets Times/Plus canonicalization monopolize the mission kernel before
   the broker sees any work.  A recipe contains only the two source entries
   and the two scalar Jacobian coefficients, so writing and distributing it
   does not construct the expensive product. *)
(* round 8 (2026-09-02, stage-1 speed): the normalization goes through the
   exact canonicalizer of Core/Algebra/RationalMaterialization.wl -- a
   1 s Together probe keeps every easy entry on Together, a hard entry is
   reduced by the FLINT multivariate gcd -- and falls back to Together on
   any refusal.  The value is the same canonical rational function
   (numerator over the product of the denominator factors, numeric content
   in the numerator); the finite-field sampler reads it through
   Numerator/Denominator/CoefficientRules, which see identical polynomials. *)
$transportChartJacobianNativeLeafCount = 150000;
transportChartJacobianTogetherRecipe[
    {av_, aw_, jv_, jw_}] := Module[{expression = av jv + aw jw, pair},
  (* measured 2026-09-02 on CF300: (12,7) recipes (strip leafCount 658936)
     60.1 s -> 22.1 s through the canonicalizer; (12,9) recipes (270935)
     10.1 s -> 14.5 s, the 1 s probes being pure loss on entries Together
     finishes in a few seconds -- hence the leaf-count gate *)
  If[LeafCount[expression] < $transportChartJacobianNativeLeafCount,
    Return[If[Environment["FACET_R8_RECIPE_LOG"] === "On",
      With[{r = AbsoluteTiming[Together[expression]]},
        Print["[jacobian-recipe] leaves ", LeafCount[expression], " Together ", Round[First[r], 0.01], " s"]; Last[r]],
      Together[expression]]]];
  pair = Quiet[Check[AbsoluteTiming[rationalMaterializationCanonicalValue[expression]],
    $Failed]];
  If[Environment["FACET_R8_RECIPE_LOG"] === "On",
    Print["[jacobian-recipe] leaves ", LeafCount[expression], " canonicalizer ",
      If[ListQ[pair], Round[First[pair], 0.01], "failed"], " s"]];
  pair = If[ListQ[pair], Last[pair], $Failed];
  If[MatchQ[pair, {_, _Association}],
    First[pair]/(Times @@ KeyValueMap[Power, Last[pair]]),
    Together[expression]]];
transportChartJacobianTogetherRecipe[___] := $Failed;

transportChartJacobianTogetherTask[dataFile_String] := Module[
  {data = taskBrokerRead[dataFile], recipes},
  If[! AssociationQ[data], Return[$Failed]];
  recipes = Lookup[data, "Recipes", $Failed];
  If[! ListQ[recipes], Return[$Failed]];
  transportChartJacobianTogetherRecipe /@ recipes
];

transportChartParallelJacobianPullBack[image_, jacobian_, label_String,
    deadline_: Infinity] := Module[
  {started = AbsoluteTime[], imageDimensions, outputDimensions, indices,
   recipes, values, helpers, bytes, localIndex, helperIndices,
   helperBatches, batchLoads, targetBatch, dataFiles, codes, handle,
   farmed, missing, timeout, parallel, route = "Serial"},
  imageDimensions = Dimensions[image];
  If[Length[imageDimensions] =!= 3 || First[imageDimensions] =!= 2 ||
      Dimensions[jacobian] =!= {2, 2},
    Return[<|"Status" -> "InvalidJacobianPullBackInput"|>]];
  If[! transportChartDeadlineQ[deadline],
    Return[<|"Status" -> "InvalidTogetherDeadline",
      "Deadline" -> deadline|>]];
  If[transportChartDeadlineExpiredQ[deadline],
    Return[<|"Status" -> "DeadlineExpired", "Seconds" -> 0.|>]];
  outputDimensions = {2, imageDimensions[[2]], imageDimensions[[3]]};
  indices = Tuples[Range /@ outputDimensions];
  recipes = Map[Function[index, {
      image[[1, index[[2]], index[[3]]]],
      image[[2, index[[2]], index[[3]]]],
      jacobian[[1, index[[1]]]], jacobian[[2, index[[1]]]]}], indices];
  If[recipes === {},
    Return[<|"Status" -> "OK", "Result" -> ArrayReshape[{},
        outputDimensions], "Route" -> "Serial", "Helpers" -> 0,
      "Tasks" -> 0, "Seconds" -> 0.|>]];
  helpers = If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0];
  helpers = Min[helpers, Max[0, Length[recipes] - 1]];
  bytes = Total[ByteCount /@ #1] & /@ recipes;
  parallel = helpers >= 1 && blockEquationDeferredParallelRouteQ[] &&
    (Length[recipes] >= 64 || Total[bytes] >= 2^20 ||
      Max[Append[bytes, 0]] >= 2^18);
  values = ConstantArray[$Failed, Length[recipes]];
  If[! TrueQ[parallel],
    values = transportChartJacobianTogetherRecipe /@ recipes,
    route = "Parallel";
    localIndex = First[Ordering[bytes, -1]];
    helperIndices = DeleteCases[Range[Length[recipes]], localIndex];
    helperBatches = ConstantArray[{}, helpers];
    batchLoads = ConstantArray[0, helpers];
    Do[
      targetBatch = First[Ordering[batchLoads, 1]];
      helperBatches[[targetBatch]] = Append[
        helperBatches[[targetBatch]], index];
      batchLoads[[targetBatch]] += bytes[[index]],
      {index, SortBy[helperIndices, -bytes[[#1]] &]}];
    dataFiles = Map[Function[batch, taskBrokerDataFile[
        "tcjacobian_" <> StringReplace[CreateUUID[], "-" -> ""],
        <|"Recipes" -> recipes[[batch]]|>]], helperBatches];
    codes = StringJoin[
        "FeynFacet`Private`transportChartJacobianTogetherTask[\"",
        #1, "\"]"] & /@ dataFiles;
    timeout = If[deadline === Infinity, 7200.,
      Max[0.25, N[deadline - AbsoluteTime[]]]];
    handle = taskBrokerSubmit[codes, "Label" -> label,
      "Timeout" -> timeout];
    values[[localIndex]] = transportChartJacobianTogetherRecipe[
      recipes[[localIndex]]];
    farmed = taskBrokerCollect[handle];
    If[ListQ[farmed],
      Do[If[index <= Length[farmed] && ListQ[farmed[[index]]] &&
            Length[farmed[[index]]] === Length[helperBatches[[index]]],
          values[[helperBatches[[index]]]] = farmed[[index]]],
        {index, Length[helperBatches]}]];
    missing = Select[helperIndices, values[[#1]] === $Failed &];
    If[transportChartDeadlineExpiredQ[deadline],
      Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
        "Helpers" -> helpers, "Tasks" -> Length[helperBatches],
        "Seconds" -> N[AbsoluteTime[] - started]|>]];
    If[missing =!= {}, values[[missing]] =
      transportChartJacobianTogetherRecipe /@ recipes[[missing]]]];
  missing = Select[Range[Length[values]], values[[#1]] === $Failed &];
  If[missing =!= {},
    Return[<|"Status" -> "JacobianPullBackNormalizationFailed",
      "Targets" -> indices[[missing]],
      "Route" -> route, "Helpers" -> If[route === "Parallel", helpers, 0],
      "Seconds" -> N[AbsoluteTime[] - started]|>]];
  If[transportChartDeadlineExpiredQ[deadline],
    Return[<|"Status" -> "DeadlineExpired", "Route" -> route,
      "Helpers" -> If[route === "Parallel", helpers, 0],
      "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
      "Seconds" -> N[AbsoluteTime[] - started]|>]];
  <|"Status" -> "OK", "Result" -> ArrayReshape[values, outputDimensions],
    "Route" -> route, "Helpers" -> If[route === "Parallel", helpers, 0],
    "Tasks" -> If[route === "Parallel", Length[helperBatches], 0],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartParallelJacobianPullBack[___] :=
  <|"Status" -> "InvalidParallelJacobianPullBackInput"|>;

transportChartLogSuccessTimings[timings_Association, chartName_,
    verboseQ_] := If[
  TrueQ[verboseQ] || AbsoluteTime[] - $transportChartLastSuccessLogTime >=
    $transportChartSuccessLogInterval,
  $transportChartLastSuccessLogTime = AbsoluteTime[];
  Print["[strip-in-frame] accepted in chart ", chartName,
    ": gauge pull-back ", Round[Lookup[timings, "GaugePullBack", 0.], 0.1],
    " s, source-representation identity ",
    Round[Lookup[timings, "SourceRepresentationIdentity", 0.], 0.1], " s"];
  True,
  False];


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
        # /. masterTransportPresentationSubstitution[data],
        branchRoots, images], {2}] &, pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]],
      data["DifferentialPullbackMatrix"]]
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
  {substitution, differentialPullback, transform, evaluated, image,
   survivingRadicals, pulled},
  substitution = masterTransportPresentationSubstitution[data];
  differentialPullback = Lookup[data, "DifferentialPullbackMatrix", $Failed];
  If[! MatchQ[substitution, {_Rule, _Rule}] ||
      ! MatchQ[differentialPullback, {{_, _}, {_, _}}] ||
      Length[branchRoots] =!= Length[images],
    Return[<|"Status" ->
      "DeferredBundleCoefficientPresentationInvalid"|>]];
  transform[expr_] := Together[transportChartApplyRootBranches[
    expr, branchRoots, images]];
  evaluated = blockEquationDeferredBundleEvaluate[bundle, substitution,
    "ExpressionTransform" -> transform];
  If[Lookup[evaluated, "Status", None] =!= "OK",
    Return[<|"Status" -> "DeferredBundleParametrizationEvaluationFailed",
      "Detail" -> evaluated|>]];
  image = evaluated["Image"];
  If[! MatchQ[Dimensions[image], {2, _, _}],
    Return[<|"Status" -> "DeferredBundleParametrizedImageInvalid"|>]];
  survivingRadicals = transportChartRadicalBases[image];
  If[survivingRadicals =!= {},
    Return[<|"Status" -> "DeferredBundleNotRationalized",
      "RadicalBases" -> survivingRadicals|>]];
  pulled = masterTransportPullBackOneForm[
    image[[1]], image[[2]], differentialPullback];
  <|"Status" -> "OK", "OneForm" -> pulled,
    "OperandEvaluations" -> evaluated["OperandEvaluations"]|>
];
transportChartPullBackDeferredBundle[___] :=
  <|"Status" -> "DeferredBundleParametrizationInputInvalid"|>;

(* Materialize the raw block-equation DAG only after its active roots and
   source coordinates have been replaced by the rational chart.  If modular
   routing proved that other declared roots cancel only after summation,
   decompose the four assembled scalars over precisely those inactive roots
   and retain their exact grade-zero channels.  This is result construction,
   not an additional acceptance layer: a nonzero inactive grade is a typed
   refusal and remains eligible for the direct multiquadratic route. *)
transportChartPullBackDeferredPreparation[record_Association,
    data_Association, branchRoots_List, images_List] := Module[
  {preparation, transform, materialized, dimensions, values, image,
   survivingRadicals, pulled, polynomialSymbols,
   sourceVariables, presentationVariables, substitution,
   differentialPullback, projectionPresentation,
   presentationSquareRootGenerators, projectionGeneratorIndices,
   projectionSquareRootGenerators,
   transformedProjectionSquareRootGenerators, projectionChannels,
   projectionTags, projectionGeneratorImages,
   taggedProjectionSquareRootGenerators,
   projectionParallel, projectionSeconds = 0., inactiveChannels,
   projectionRecord = None,
   projectionPreparedFallbacks = 0,
   jacobianPullBack},
  preparation = Lookup[record, "Preparation",
    Lookup[record, "DeferredPreparation", Missing["NoPreparation"]]];
  sourceVariables = Lookup[data, "SourceVariables", $Failed];
  presentationVariables = masterTransportPresentationVariables[data];
  substitution = masterTransportPresentationSubstitution[data];
  differentialPullback = Lookup[data, "DifferentialPullbackMatrix", $Failed];
  If[! TrueQ[blockEquationDeferredPreparationQ[preparation]] ||
      ! MatchQ[sourceVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[presentationVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[substitution, {_Rule, _Rule}] ||
      ! MatchQ[differentialPullback, {{_, _}, {_, _}}] ||
      Length[branchRoots] =!= Length[images],
    Return[<|"Status" ->
      "DeferredPreparationParametrizationInputInvalid"|>]];
  projectionPresentation = masterTransportCoefficientPresentationData[
    Lookup[record, "CoefficientPresentation", Missing[
      "NoCoefficientPresentation"]], sourceVariables];
  If[Lookup[projectionPresentation, "Status", None] =!= "OK",
    Return[<|"Status" ->
      "DeferredPreparationCoefficientPresentationInvalid",
      "Detail" -> projectionPresentation|>]];
  presentationSquareRootGenerators =
    coefficientPresentationSquareRootsInVariables[
      projectionPresentation, sourceVariables];
  projectionGeneratorIndices = Lookup[record,
    "ProjectionSquareRootGeneratorIndices", {}];
  If[! ListQ[presentationSquareRootGenerators] ||
      ! VectorQ[projectionGeneratorIndices, IntegerQ] ||
      ! ContainsOnly[projectionGeneratorIndices,
        Range[Length[presentationSquareRootGenerators]]] ||
      projectionGeneratorIndices =!=
        Sort[DeleteDuplicates[projectionGeneratorIndices]],
    Return[<|"Status" ->
      "DeferredPreparationSquareRootGeneratorsInvalid",
      "Detail" -> presentationSquareRootGenerators,
      "ProjectionSquareRootGeneratorIndices" ->
        projectionGeneratorIndices|>]];
  projectionSquareRootGenerators =
    presentationSquareRootGenerators[[projectionGeneratorIndices]];
  transformedProjectionSquareRootGenerators =
    projectionSquareRootGenerators /. substitution;
  projectionTags = Table[
    Unique["FeynFacet`Private`deferredProjectionRoot"],
    {Length[projectionSquareRootGenerators]}];
  projectionGeneratorImages =
    squareRootRecordExpression /@
      transformedProjectionSquareRootGenerators;
  taggedProjectionSquareRootGenerators = MapThread[
    <|"Generator" -> #1,
      "QuadraticRadicand" -> squareRootRecordRadicand[#2],
      "SourceRadicand" -> Lookup[#3, "SourceRadicand",
        squareRootRecordRadicand[#3]]|> &,
    {projectionTags, transformedProjectionSquareRootGenerators,
      projectionSquareRootGenerators}];
  transform[expr_] := Module[{activeImage},
    activeImage = transportChartApplyRootBranches[
      expr /. masterTransportPresentationSubstitution[data],
      branchRoots, images];
    (* Inactive roots are algebra generators during operand interning.  This
       prevents Together/FactorList from rationalizing their denominators
       separately in dozens of operands before the four target sums cancel
       those roots. *)
    transportChartApplyRootBranches[activeImage,
      transformedProjectionSquareRootGenerators, projectionTags]];
  polynomialSymbols = DeleteDuplicates[Join[
    presentationVariables,
    {Lookup[preparation, "Regulator", None]},
    Lookup[preparation, "Parameters", {}], projectionTags]];
  materialized = blockEquationDeferredMaterialize[preparation,
    "ExpressionTransform" -> transform,
    "PolynomialSymbols" -> polynomialSymbols,
    "Cancel" -> False, "CanonicalizeUntouched" -> False,
    "AlgebraicCanonicalize" -> False,
    "Parallel" -> If[projectionSquareRootGenerators === {}, Automatic,
      blockEquationDeferredParallelRouteQ[]],
    "Helpers" -> Automatic,
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
  If[projectionSquareRootGenerators =!= {},
    projectionParallel = transportChartParallelProjectionDecompose[
      image, taggedProjectionSquareRootGenerators,
      transformedProjectionSquareRootGenerators,
      projectionTags, projectionGeneratorImages,
      "chartprojection_" <> ToString[
        Lookup[preparation, "Sector", "block"]] <> "_" <>
        ToString[Lookup[preparation, "LowerSector", "source"]]];
    If[Lookup[projectionParallel, "Status", None] =!= "OK",
      Return[<|"Status" -> "DeferredPreparationInactiveProjectionFailed",
        "ProjectionSquareRootGeneratorCount" ->
          Length[projectionSquareRootGenerators],
        "Detail" -> KeyDrop[projectionParallel, "Channels"]|>]];
    projectionChannels = projectionParallel["Channels"];
    projectionSeconds = projectionParallel["Seconds"];
    projectionPreparedFallbacks = projectionParallel["Fallbacks"];
    inactiveChannels = Flatten[Map[Rest, projectionChannels, {3}]];
    If[! AllTrue[inactiveChannels, TrueQ[Together[#1] === 0] &],
      Return[<|"Status" ->
          "DeferredPreparationInactiveProjectionNonzero",
        "ProjectionSquareRootGeneratorCount" ->
          Length[projectionSquareRootGenerators]|>]];
    image = Map[First, projectionChannels, {3}];
    projectionRecord = <|"Status" -> "ExactInactiveGradeProjection",
      "SquareRootGeneratorCount" ->
        Length[projectionSquareRootGenerators],
      "PrecombinedFallbacks" -> projectionPreparedFallbacks,
      "Seconds" -> N[projectionSeconds]|>;
    Print["[deferred-router] exact inactive-generator projection: generators ",
      Length[projectionSquareRootGenerators], ", ",
      Round[N[projectionSeconds], 0.1], " s, precombined fallbacks ",
      projectionPreparedFallbacks, ", route ",
      projectionParallel["Route"], ", helpers ",
      projectionParallel["Helpers"]]];
  survivingRadicals = transportChartRadicalBases[image];
  If[survivingRadicals =!= {},
    Return[<|"Status" -> "DeferredPreparationNotRationalized",
      "RadicalBases" -> survivingRadicals|>]];
  (* The Jacobian combinations are independent exact rational
     normalizations.  Their cost depends on the materialized expressions,
     not on whether an inactive-root projection produced them, so the shared
     helper applies its size admission uniformly and keeps easy inputs local. *)
  jacobianPullBack = transportChartParallelJacobianPullBack[
    image, differentialPullback,
      "parametrized_inhomogeneity_" <> ToString[
      Lookup[preparation, "Sector", "block"]] <> "_" <>
      ToString[Lookup[preparation, "LowerSector", "source"]]];
  If[Lookup[jacobianPullBack, "Status", None] =!= "OK",
    Return[<|"Status" -> "DeferredPreparationJacobianPullBackFailed",
      "Detail" -> KeyDrop[jacobianPullBack, "Result"]|>]];
  pulled = jacobianPullBack["Result"];
  If[AssociationQ[projectionRecord],
    projectionRecord = Join[projectionRecord, <|
      "JacobianPullBack" -> KeyDrop[jacobianPullBack, "Result"]|>]];
  If[transportChartStageLogQ[],
    Print["[deferred-router] Jacobian pullback normalization: ",
      Round[Lookup[jacobianPullBack, "Seconds", 0.], 0.1],
      " s, route ", Lookup[jacobianPullBack, "Route", None],
      ", helpers ", Lookup[jacobianPullBack, "Helpers", 0]]];
  <|"Status" -> "OK", "OneForm" -> pulled,
    "Materialization" -> KeyDrop[materialized, "Values"],
    "InactiveSquareRootGeneratorProjection" -> projectionRecord|>
];
transportChartPullBackDeferredPreparation[___] :=
  <|"Status" -> "DeferredPreparationParametrizationInputInvalid"|>;

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
    "Method" -> "OffDiagonalBlockBasisTransformationConstruction",
    "Resumable" -> True|>,
  progress];

Options[SolveEpsFormStripInFrame] = Join[
  Options[SolveEpsFormStrip], {
    "FiniteFieldFallback" -> True,
    "FiniteFieldFirst" -> True,   (* production default since 2026-09-02; the CANONICA/Maple ladder is retired *)
    "FiniteFieldOptions" -> {},
    "MultiquadraticDispatch" -> True,
    "MultiquadraticOptions" -> {},
    "DeferredPreparation" -> Automatic,
    (* "Exact" (default): the package's exact Together pull-back of the
       chart gauge, then the historical exact frame gates below.
       "FiniteFieldReconstruct": reconstruct the reduced source-frame gauge
       from modular evaluations of the live compact chart gauge; it never
       materializes chartGauge /. inverseMap and is accepted by the
       post-pullback modular strip residual.  These two are the live
       allowed set; the Maple canonical mode ("MapleCanonical") is
       retired (overhaul 2026-09-02) and refused by name in the option
       gate -- its stub transportChartMapleCanonicalGauge stays only so
       that records naming it remain readable. *)
    "GaugePullBackMode" -> "Exact",
    "GaugePullBackFiniteFieldOptions" -> {},
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

(* A root set with no catalogued joint rationalizing parametrization is
   dispatched to the direct
   multiquadratic engine (Design/GeneralityFixes2.md F2, 2026-08-23).
   These statuses mean the ENGINE declined the input as outside its own
   scope, not that it ran and failed; only they keep the historical
   "NoCataloguedRationalizingParametrization" answer, with the engine's typed refusal
   attached so the caller can tell the two apart.  Every other engine
   status -- "ModularConsistent" and every typed failure -- is returned
   verbatim. *)
$transportChartMultiquadraticScopeRefusals = {
  "UnsupportedRootRank", "InvalidStripRecord",
  "StripContainsUndeclaredRadicals", "ContextSensitivePreparationData",
  "CoefficientPresentationNotWellFormed",
  "ForcingChannelDecompositionFailed",
  "GaugeDenominatorNotRational"};


(* U4 (user decision 2026-09-02): wall-clock timings stay in the result,
   but as ONE top-level "Timings" record, never inside the mathematical
   payload.  Every association key
   naming a duration is lifted out recursively; the flat key is the path
   through the record joined by "/". *)
transportChartTimingKeyQ[key_String] := StringMatchQ[key,
  ___ ~~ ("Seconds" | "Timing" | "Timings" | "Wall" | "Elapsed") ~~ ___];
transportChartTimingKeyQ[_] := False;
transportChartSeparateTimings[record_] := Module[{timings = <||>, walk},
  walk[assoc_Association, path_String] := Association[KeyValueMap[
    Function[{key, value},
      If[transportChartTimingKeyQ[key],
        (timings[If[path === "", key, path <> "/" <> key]] = value; Nothing),
        key -> walk[value, If[path === "", ToString[key], path <> "/" <> ToString[key]]]]],
    assoc]];
  walk[list_List, path_String] := walk[#, path] & /@ list;
  walk[other_, _] := other;
  <|"Record" -> walk[record, ""], "Timings" -> timings|>];
transportChartTimingsRecord[stages_Association, inner_Association] :=
  <|"Schema" -> "StripTimingsV1", "Stages" -> stages, "Inner" -> inner|>;


SolveEpsFormStripInFrame[
    strip : {e_List, c_List, bbar_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    coefficientPresentation_Association, opts : OptionsPattern[]] := Block[
  (* the stage lines follow this call's "Verbose" (Codex 14:30): a caller
     that asked for a quiet library gets one.  Block, so every exit path
     -- including a Return out of the Module below -- restores it. *)
  (* the EXPLICIT three-argument OptionValue: this sits in a Block
     variable initializer, which is held *)
  {$transportChartStageLog = TrueQ[OptionValue[
    SolveEpsFormStripInFrame, {opts}, "Verbose"]]},
  Module[
  {coefficientPresentationData, allRoots, classification, rootIndices,
   usedRoots, rootSquares, chart,
   chartVariables, rekeyed, data, chartStrip, inner, chartGauge,
   presentationVariables, presentationRoots,
   presentationToSourceRules, sourceCoordinateImages,
   coordinateMap, sourceGauge, chartRoots, rootImages,
   chartBranchRoots, mapCanonicalization, comparatorRefusals,
   signChoices, acceptedSigns, branchImages, branchedGauge,
   sourceTransformed, chartTransformed, pulledTransformed,
   sourceAlphabet, zeroMatrixNamedQ, zeroTestStop,
   identityHolds, pullPair, optionRules, parallelTogether,
   finiteFieldQ, finiteFieldFirstQ, finiteFieldOptions, canonicalKernelCount,
   scratchDirectory, stripTag, verbose, solveRationalStrip, innerSolvedQ,
   multiquadraticOptions, multiquadraticResult, multiquadraticStatus,
   bundlePullback, preparationPullback, rationalStrip,
   deferredBundle, bundleValidation, bundlePresentationData,
   bundlePresentationRoots, bundleGeneratorIndices, bundleRoots,
   bundleIndices, deferredPreparation, preparation,
   preparationPresentationData, preparationPresentationRoots,
   preparationGeneratorIndices, preparationRoots,
   preparationIndices, deferredSourceQ, deferredForcingDescriptor = None,
   deferredForcingPlan, deferredForcingCensus, deferredForcingFile,
   selectedIndices, bundleRecord,
   gaugePullBackMode, finiteFieldCanonicalQ,
   productionCanonicalQ, finiteFieldGauge,
   finiteFieldGaugeOptions,
   postPullBackCheckQ, postPullBackCandidates, postPullBackVerification,
   postPullBackGauge, sourceGaugeRadicalFreeQ,
   constructionStart = AbsoluteTime[], deadline, timings = <||>, innerSeparated,
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
  (* the retired "MapleCanonical" is not in this set: it is refused here
     like any unknown name (round 4, 2026-09-02) *)
  If[! MemberQ[{"Exact", "FiniteFieldReconstruct"}, gaugePullBackMode],
    Return[<|"Status" -> "InvalidGaugePullBackMode",
      "Allowed" -> {"Exact", "FiniteFieldReconstruct"},
      "Actual" -> gaugePullBackMode|>]];
  finiteFieldCanonicalQ = gaugePullBackMode === "FiniteFieldReconstruct";
  (* the one remaining production (post-pullback-residual) mode *)
  productionCanonicalQ = finiteFieldCanonicalQ;
  finiteFieldGaugeOptions = OptionValue["GaugePullBackFiniteFieldOptions"];
  If[! MatchQ[finiteFieldGaugeOptions, {___Rule}],
    Return[<|"Status" -> "InvalidGaugePullBackFiniteFieldOptions"|>]];
  (* what a construction stop reports: the substage wall times measured
     so far (this is the record that was missing tonight -- the budget
     passed with no evidence of which substage consumed it) and the
     identifiers of the strip being constructed.  Every key is defined
     whether or not the substage it belongs to was reached. *)
  budgetProgress[] := <|
    "ConstructionTimings" -> timings,
    "SquareRootGeneratorIndices" -> If[ListQ[rootIndices], rootIndices,
      Missing["NotClassified"]],
    "RationalizingParametrizationName" ->
      If[AssociationQ[chart], Lookup[chart, "Name", None], None],
    "StripDimensions" -> stripDimensions,
    "InnerStatus" -> If[AssociationQ[inner],
      Lookup[inner, "Status", None], Missing["NotSolved"]]|>;
  budgetExhausted[substage_String] := transportChartBudgetExhausted[
    substage, AbsoluteTime[] - constructionStart, deadline,
    budgetProgress[]];

  (* coefficient-presentation validation outranks a budget stop,
     exactly as the solvers' option gates do *)
  coefficientPresentationData =
    masterTransportCoefficientPresentationData[
      coefficientPresentation, variables];
  If[Lookup[coefficientPresentationData, "Status", None] =!= "OK",
    Return[coefficientPresentationData]];
  allRoots = coefficientPresentationSquareRootsInVariables[
    coefficientPresentationData, variables];
  If[! ListQ[allRoots],
    Return[If[AssociationQ[allRoots], allRoots,
      <|"Status" -> "CoefficientPresentationNotWellFormed"|>]]];
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
    {stageSeconds, bundleValidation} = AbsoluteTiming[
      blockEquationDeferredBundleValidate[deferredBundle]];
    timings["DeferredBundleValidation"] = stageSeconds;
    If[TrueQ[OptionValue["Verbose"]],
      Print["[strip-in-frame] deferred bundle validation: ",
        Round[stageSeconds, 0.1], " s"]];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[<|"Status" -> "InvalidDeferredBundle",
        "Detail" -> bundleValidation|>]];
    If[Lookup[deferredBundle, "Variables", None] =!= variables ||
        Lookup[deferredBundle, "Regulator", None] =!= epsilon ||
        Lookup[deferredBundle, "Dimensions", None] =!=
          Prepend[Dimensions[bbar[[1]]], 2],
      Return[<|"Status" ->
        "DeferredBundleCoefficientPresentationMismatch"|>]];
    bundlePresentationData = masterTransportCoefficientPresentationData[
      Lookup[deferredBundle, "CoefficientPresentation",
        Missing["NoCoefficientPresentation"]], variables];
    bundlePresentationRoots =
      coefficientPresentationSquareRootsInVariables[
        bundlePresentationData, variables];
    bundleGeneratorIndices = Lookup[deferredBundle,
      "SquareRootGeneratorIndices", $Failed];
    If[Lookup[bundlePresentationData, "Status", None] =!= "OK" ||
        ! ListQ[bundlePresentationRoots] ||
        ! VectorQ[bundleGeneratorIndices, IntegerQ] ||
        ! ContainsOnly[bundleGeneratorIndices,
          Range[Length[bundlePresentationRoots]]] ||
        bundleGeneratorIndices =!=
          Sort[DeleteDuplicates[bundleGeneratorIndices]],
      Return[<|"Status" ->
        "DeferredBundleCoefficientPresentationMismatch",
        "CoefficientPresentation" -> bundlePresentationData,
        "SquareRootGeneratorIndices" -> bundleGeneratorIndices|>]];
    bundleRoots = bundlePresentationRoots[[bundleGeneratorIndices]],
    If[! MissingQ[deferredBundle] && deferredBundle =!= Automatic,
      Return[<|"Status" -> "InvalidDeferredBundle"|>]]];
  deferredPreparation = OptionValue["DeferredPreparation"];
  If[AssociationQ[deferredPreparation],
    preparation = Lookup[deferredPreparation, "Preparation",
      Lookup[deferredPreparation, "DeferredPreparation",
        Missing["NoPreparation"]]];
    preparationPresentationData =
      masterTransportCoefficientPresentationData[
        Lookup[deferredPreparation, "CoefficientPresentation",
          Missing["NoCoefficientPresentation"]], variables];
    preparationPresentationRoots =
      coefficientPresentationSquareRootsInVariables[
        preparationPresentationData, variables];
    preparationGeneratorIndices = Lookup[deferredPreparation,
      "SquareRootGeneratorIndices", $Failed];
    If[! TrueQ[blockEquationDeferredPreparationQ[preparation]] ||
        Lookup[preparation, "Variables", None] =!= variables ||
        Lookup[preparation, "Regulator", None] =!= epsilon ||
        Lookup[preparation, "Dimensions", None] =!=
          Prepend[Dimensions[bbar[[1]]], 2] ||
        Lookup[preparationPresentationData, "Status", None] =!= "OK" ||
        ! ListQ[preparationPresentationRoots] ||
        ! VectorQ[preparationGeneratorIndices, IntegerQ] ||
        ! ContainsOnly[preparationGeneratorIndices,
          Range[Length[preparationPresentationRoots]]] ||
        preparationGeneratorIndices =!=
          Sort[DeleteDuplicates[preparationGeneratorIndices]],
      Return[<|"Status" ->
        "DeferredPreparationCoefficientPresentationMismatch"|>]];
    preparationRoots =
      preparationPresentationRoots[[preparationGeneratorIndices]],
    If[deferredPreparation =!= Automatic,
      Return[<|"Status" -> "InvalidDeferredPreparation"|>]]];
  If[AssociationQ[deferredBundle] && AssociationQ[deferredPreparation],
    Return[<|"Status" -> "AmbiguousDeferredForcing"|>]];
  deferredSourceQ =
    AssociationQ[deferredBundle] || AssociationQ[deferredPreparation];
  (* BOUNDARY 1 (entry): an already-expired deadline never starts the
     root classifier, which denests and square-class-matches every
     radical occurring in the strip *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["Entry"]]];
  {stageSeconds, classification} = AbsoluteTiming[
    transportChartRootIndices[strip, allRoots]];
  timings["SquareRootGeneratorClassification"] = stageSeconds;
  If[TrueQ[OptionValue["Verbose"]],
    Print["[strip-in-frame] root classification: ",
      Round[stageSeconds, 0.1], " s"]];
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
    (* Generators used only by the deferred forcing are invisible in the zero
       placeholder.  Match the bundle's declared generator subset into the
       strip coefficient presentation by its displayed generator and
       quadratic relation.  The strip presentation's order is authoritative. *)
    bundleIndices = Table[Module[{matches},
        matches = Flatten[Position[allRoots,
          candidate_ /; TrueQ[Together[
              squareRootRecordRadicand[candidate] -
                squareRootRecordRadicand[bundleRoot]] === 0] &&
            TrueQ[Together[squareRootRecordExpression[candidate] -
                squareRootRecordExpression[bundleRoot]] === 0],
          {1}, Heads -> False]];
        If[Length[matches] =!= 1,
          Return[<|"Status" ->
            "DeferredBundleCoefficientPresentationMismatch",
            "BundleSquareRootGenerator" -> bundleRoot,
            "Matches" -> matches|>, Module]];
        First[matches]],
      {bundleRoot, bundleRoots}];
    If[! VectorQ[bundleIndices, IntegerQ],
      Return[FirstCase[bundleIndices, failure_Association :> failure,
        <|"Status" ->
          "DeferredBundleCoefficientPresentationMismatch"|>]]];
    selectedIndices = Sort[DeleteDuplicates[
      Join[rootIndices, bundleIndices]]];
    rootIndices = selectedIndices];
  If[AssociationQ[deferredPreparation],
    preparationIndices = Table[Module[{matches},
        matches = Flatten[Position[allRoots,
          candidate_ /; TrueQ[Together[
              squareRootRecordRadicand[candidate] -
                squareRootRecordRadicand[preparationRoot]] === 0] &&
            TrueQ[Together[squareRootRecordExpression[candidate] -
                squareRootRecordExpression[preparationRoot]] === 0],
          {1}, Heads -> False]];
        If[Length[matches] =!= 1,
          Return[<|"Status" ->
            "DeferredPreparationCoefficientPresentationMismatch",
            "PreparationSquareRootGenerator" -> preparationRoot,
            "Matches" -> matches|>, Module]];
        First[matches]],
      {preparationRoot, preparationRoots}];
    If[! VectorQ[preparationIndices, IntegerQ],
      Return[FirstCase[preparationIndices, failure_Association :> failure,
        <|"Status" ->
          "DeferredPreparationCoefficientPresentationMismatch"|>]]];
    rootIndices = Sort[DeleteDuplicates[
      Join[rootIndices, preparationIndices]]]];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = squareRootRecordRadicand /@ usedRoots;
  (* dD = eps (e.D-D.c)+bbar is solved identically by D=0 when the
     forcing vanishes.  This must precede chart selection: the diagonal
     blocks may span a root set with no joint rational chart even though
     this off-diagonal problem needs no field arithmetic at all. *)
  If[! deferredSourceQ &&
      AllTrue[Flatten[bbar], SameQ[#, 0] &],
    Return[<|"Status" -> "Solved", "Method" -> "ZeroForcing",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "CoefficientPresentation" -> coefficientPresentationData,
      "SquareRootGeneratorIndices" -> rootIndices,
      "Alphabet" -> {}, "ExactDLog" -> True,
      "Certificate" -> "ExactDLog", "Validation" -> <|
        "RationalizingParametrizationName" -> None,
        "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True, "SourceDLog" -> True,
        "SamplingEntered" -> False, "Method" -> "Exact",
        "Passed" -> True|>|>]];
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
      MemberQ[{"NumericalResidual", "ModularResidual", "PendingPostPullBackResidual"},
        Lookup[candidate, "Certificate", None]]);
  solveRationalStrip = Function[{rationalStrip, rationalVariables},
    Module[{candidate, directory, defaults, finiteOptions,
        rationalRecord, rationalCoefficientPresentation,
        fallbackOptions, fallback,
        primaryFailure, candidateOptions, letterData, letterRecords,
        dlogRecords, expandedRecord, expandedOptions, expandedPrefix,
        suppliedLetterRecords, suppliedOneForms, recordsCertifiedQ},
      rationalRecord = Join[<|"Strip" -> rationalStrip,
        "Variables" -> rationalVariables, "Regulator" -> epsilon|>,
        If[AssociationQ[deferredForcingDescriptor],
          <|"DeferredForcing" -> deferredForcingDescriptor|>, <||>]];
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
        postPullBackCheckQ = productionCanonicalQ && rootIndices =!= {};
        If[postPullBackCheckQ,
          finiteOptions = Prepend[
            DeleteCases[finiteOptions, HoldPattern["FinalCheck" -> _]],
            "FinalCheck" -> "PostPullBack"]];
        candidate = SolveEpsFormStripFiniteField[
          rationalRecord, Sequence @@ finiteOptions];
      ];
      If[innerSolvedQ[candidate] || candidate =!= $Failed ||
          ! TrueQ[OptionValue["MultiquadraticDispatch"]] ||
          transportChartDeadlineExpiredQ[deadline],
        Return[candidate, Module]];
      primaryFailure = <|"Status" -> "SolverReturnedFailed"|>;
      rationalCoefficientPresentation =
        masterTransportCoefficientPresentationData[
          None, rationalVariables];
      (* Options tied to the source algebraic frame cannot be reused after
         chart substitution.  Resource, reconstruction, deadline and
         checkpoint options remain valid and are retained. *)
      fallbackOptions = DeleteCases[multiquadraticOptions,
        HoldPattern[("DeferredBundle" | "SquareRootGeneratorIndices" |
          "AdditionalLetters" | "AlgebraicLetters" |
          "GaugeDenominator" | "GaugeDenominatorFactor") -> _]];
      suppliedLetterRecords = FirstCase[fallbackOptions,
        HoldPattern["LetterRecords" -> value_] :> value, Automatic];
      suppliedOneForms = FirstCase[fallbackOptions,
        HoldPattern["OneForms" -> value_] :> value, Automatic];

      (* The conservative root-rank-zero route finds a broader exact dlog
         span, but its one-extra-copy denominator inflated the system
         from roughly 7k to 19k unknowns in the triggering hard block and
         crossed the dense-memory gate.  Build that alphabet once, then first
         retry the ordinary rational engine with its original A3 denominator. *)
      letterRecords = Which[
        MatchQ[suppliedLetterRecords, {___Association}],
          suppliedLetterRecords,
        suppliedOneForms =!= Automatic,
          Automatic,
        True,
          candidateOptions = DeleteDuplicatesBy[Join[
            FilterRules[fallbackOptions,
              Options[multiquadraticStripCandidateLetters]],
            {"Deadline" -> deadline}], First];
          If[verbose, Print[
            "[strip-in-frame] rational ansatz declined; deriving a broader ",
            "rank-zero dlog basis before denominator widening"]];
          letterData = multiquadraticStripCandidateLetters[rationalStrip, {},
            rationalVariables, epsilon, rationalRecord,
            Sequence @@ candidateOptions];
          If[Lookup[letterData, "Status", None] =!=
              "MultiquadraticCandidateLettersV1",
            Return[If[AssociationQ[letterData],
              Join[<|"PrimaryRationalFailure" -> primaryFailure|>, letterData],
              <|"Status" -> "RationalizedStripCandidateLettersUntyped",
                "PrimaryRationalFailure" -> primaryFailure,
                "CandidateResult" -> letterData|>], Module]];
          letterData["LetterRecords"]];
      recordsCertifiedQ = MatchQ[letterRecords, {__Association}] &&
        AllTrue[letterRecords,
          ! MissingQ[Lookup[#1, "Letter", Missing["Letter"]]] &&
            MatchQ[Lookup[#1, "OneForm", $Failed], {_, _}] &&
            TrueQ[Lookup[Lookup[#1, "Potential", <||>],
              "Verified", False]] &];
      dlogRecords = If[recordsCertifiedQ,
        KeyTake[#, {"Letter", "OneForm"}] & /@ letterRecords, {}];
      If[finiteFieldQ &&
          recordsCertifiedQ,
        expandedRecord = Join[rationalRecord,
          <|"DLogRecords" -> dlogRecords|>];
        expandedPrefix = Replace[FirstCase[finiteOptions,
            HoldPattern["ArtifactPrefix" -> value_] :> value, stripTag],
          {value_String :> value <> "_dlog_basis",
           _ :> stripTag <> "_dlog_basis"}];
        expandedOptions = Prepend[
          DeleteCases[finiteOptions, HoldPattern["ArtifactPrefix" -> _]],
          "ArtifactPrefix" -> expandedPrefix];
        candidate = SolveEpsFormStripFiniteField[expandedRecord,
          Sequence @@ expandedOptions];
        If[innerSolvedQ[candidate],
          Return[Join[candidate, <|
            "PrimaryRationalFailure" -> primaryFailure,
            "AlphabetRecovery" -> "RankZeroCandidateDLogs"|>], Module]];
        (* A typed stop/failure is authoritative; only the ordinary solver's
           historical untyped $Failed means this ansatz was exhausted. *)
        If[candidate =!= $Failed ||
            transportChartDeadlineExpiredQ[deadline],
          Return[candidate, Module]]];

      (* The richer alphabet with the small denominator was insufficient (or
         not wholly dlog-certified).  Only now enter the existing conservative
         denominator route, reusing the exact records already constructed. *)
      If[verbose, Print[
        "[strip-in-frame] broader dlog basis still declined; trying the ",
        "conservative root-rank-zero denominator"]];
      If[MatchQ[letterRecords, {___Association}],
        fallbackOptions = Prepend[
          DeleteCases[fallbackOptions, HoldPattern["LetterRecords" -> _]],
          "LetterRecords" -> letterRecords]];
      fallback = solveEpsFormStripMultiquadratic[
        rationalRecord, rationalCoefficientPresentation,
        Sequence @@ DeleteDuplicatesBy[Join[fallbackOptions,
          {"Deadline" -> deadline, "Verbose" -> verbose}], First]];
      If[AssociationQ[fallback],
        Join[<|"PrimaryRationalFailure" -> primaryFailure,
          "FallbackCoefficientPresentation" ->
            "SourceVariableRepresentationAfterRationalization"|>, fallback],
        <|"Status" -> "RationalizedStripMultiquadraticFallbackUntyped",
          "PrimaryRationalFailure" -> primaryFailure,
          "FallbackResult" -> fallback|>]
    ]
  ];

  If[rootIndices === {},
    rationalStrip = strip;
    If[deferredSourceQ,
      data = masterTransportCoefficientPresentationData[None, variables]];
    If[AssociationQ[deferredBundle],
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
    Return[Join[inner, <|
      "Method" -> "SourceVariableRepresentation/" <> inner["Method"],
      "CoefficientPresentation" -> coefficientPresentationData,
      "SquareRootGeneratorIndices" -> {}, "Validation" -> <|
        "RationalizingParametrizationName" -> None,
        "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True,
        "Method" -> "Exact", "Passed" -> True|>|>]]];

  (* BOUNDARY 2 (chart selection): the catalog walk re-verifies each
     candidate chart's exact root identities *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ParametrizationSelection"]]];
  {stageSeconds, chart} = AbsoluteTiming[
    LookupCataloguedRationalizingParametrizationForRoots[rootSquares, variables]];
  timings["ParametrizationSelection"] = stageSeconds;
  If[MissingQ[chart],
    (* F2 (Design/GeneralityFixes2.md, 2026-08-23): no joint rational
       chart is not the end of the road.  The direct multiquadratic
       engine solves such a strip in the grade basis of the declared
       root set.  A reconstructed gauge with certified active dlog
       potentials and independent fresh residuals returns the installable
       "Solved" result; an incomplete "ModularConsistent" result is recorded
       but never installed.  The result is returned exactly as the engine
       typed it. *)
    If[! TrueQ[OptionValue["MultiquadraticDispatch"]],
      Return[<|"Status" -> "NoCataloguedRationalizingParametrization",
        "CoefficientPresentation" -> coefficientPresentationData,
        "SquareRootGeneratorIndices" -> rootIndices,
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
      <|"Variables" -> variables, "Regulator" -> epsilon, "Strip" -> strip,
        "CoefficientPresentation" -> coefficientPresentationData|>,
      If[AssociationQ[deferredBundle],
        <|"DeferredBundle" -> deferredBundle|>, <||>],
      (* seam fix (Codex 2026-08-31 notes 02/04): the VALIDATED raw
         preparation travels to the engine so the native deferred-AST
         evaluator can be selected -- with no DeferredBundle interning,
         no Maple compile, and no materialization here.  The engine
         reads record["DeferredPreparation"] and pairs it with the
         "DeferredPreparationFile" option to form its native source. *)
      If[AssociationQ[deferredPreparation],
        <|"DeferredPreparation" -> deferredPreparation|>, <||>]];
    multiquadraticResult = solveEpsFormStripMultiquadratic[
      bundleRecord,
      coefficientPresentationData,
      Sequence @@ DeleteDuplicatesBy[
        Join[multiquadraticOptions,
          {"Deadline" -> deadline, "Verbose" -> TrueQ[verbose]}], First]];
    If[! AssociationQ[multiquadraticResult],
      Return[<|"Status" -> "MultiquadraticDispatchNotTyped",
        "CoefficientPresentation" -> coefficientPresentationData,
        "SquareRootGeneratorIndices" -> rootIndices,
        "Result" -> multiquadraticResult|>]];
    multiquadraticStatus = Lookup[multiquadraticResult, "Status", None];
    If[MemberQ[$transportChartMultiquadraticScopeRefusals, multiquadraticStatus],
      Return[<|"Status" -> "NoCataloguedRationalizingParametrization",
        "CoefficientPresentation" -> coefficientPresentationData,
        "SquareRootGeneratorIndices" -> rootIndices,
        "MultiquadraticDispatch" -> "OutOfScope",
        "MultiquadraticRefusal" -> multiquadraticResult|>]];
    (* verbatim, with the frame's own root census added where the engine
       does not carry it (the typed failures do not) *)
    Return[Join[
      <|"CoefficientPresentation" -> coefficientPresentationData,
        "SquareRootGeneratorIndices" -> rootIndices,
        "MultiquadraticDispatch" -> "Engine"|>,
      multiquadraticResult]]];

  (* BOUNDARY 3 (chart/identity preparation): rekeying, the chart data
     record, the root images and the pulled-back declared squares are one
     Together pass each over the chart's entries *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ParametrizationPreparation"]]];
  stageSeconds = AbsoluteTime[];
  chartVariables = {
    Symbol["FeynFacet`Private`stripChartX"],
    Symbol["FeynFacet`Private`stripChartY"]};
  rekeyed = rekeyCoefficientPresentation[chart, variables, chartVariables];
  data = masterTransportCoefficientPresentationData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  chartRoots = Lookup[rekeyed, "RationalizedSquareRoots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#["SourceRadicand"] -
          squareRootRecordRadicand[usedRoots[[i]]]] === 0] &,
      Missing["SquareRootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["RationalRoot"]]],
    {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ],
    Return[<|"Status" ->
      "RationalizingParametrizationSquareRootImageMissing"|>]];
  chartBranchRoots = Map[
    <|"QuadraticRadicand" -> Together[
        squareRootRecordRadicand[#] /.
          masterTransportPresentationSubstitution[data]],
      "Generator" -> squareRootRecordExpression[#],
      "SourceRadicand" -> squareRootRecordRadicand[#]|> &,
    usedRoots];
  timings["ParametrizationPreparation"] = AbsoluteTime[] - stageSeconds;
  (* BOUNDARY 4 (before the chart pullback): transportChartPullBackStrip
     is a SINGLE opaque pass -- substitution of the root images into
     every entry of the strip, then one Together over the result -- with
     no interior unit boundary to check.  It is therefore bracketed: the
     deadline is checked before it and again after it, and its measured
     wall time is recorded so a future log shows this substage's cost.
     It is deliberately NOT TimeConstrained (documented trap: a
     TimeConstrained step has escaped its bound in pool subkernels). *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ParametrizationPullBack"]]];
  (* the root images and the pulled-back declared squares are needed
     BEFORE the pullback, not after it: transportChartPullBackStrip
     substitutes them into the chart entries and only then normalizes
     (see the note at its definition) *)
  stageSeconds = AbsoluteTime[];
  chartStrip = transportChartPullBackStrip[
    strip, data, chartBranchRoots, rootImages];
  If[AssociationQ[deferredBundle],
    bundlePullback = transportChartPullBackDeferredBundle[
      deferredBundle, data, chartBranchRoots, rootImages];
    If[Lookup[bundlePullback, "Status", None] =!= "OK",
      Return[bundlePullback]];
    chartStrip[[3]] = bundlePullback["OneForm"]];
  (* round 8 pass 3 (2026-09-02): the DAG route.  The deferred preparation is
     NOT materialized before the inner solve: the finite-field sampler takes
     its forcing images from the native evaluator of the DAG at its own
     points and the census from modular line interpolation
     (FiniteFieldDeferredForcing.wl); chartStrip[[3]] stays the zero
     placeholder, which the source-frame identity below adds to both sides.
     Any typed failure of the plan or census falls back to the exact
     pull-back (FACET_DEFERRED_FORCING=Off forces it). *)
  deferredForcingDescriptor = None;
  If[AssociationQ[deferredPreparation] && finiteFieldDeferredForcingRouteQ[],
    deferredForcingFile = FirstCase[multiquadraticOptions,
      HoldPattern["DeferredPreparationFile" -> f_String] :> f, None];
    deferredForcingPlan = If[StringQ[deferredForcingFile],
      finiteFieldDeferredForcingPlan[deferredPreparation, deferredForcingFile,
        data, usedRoots, rootImages, chartVariables, variables, epsilon,
        Dimensions[bbar[[1]]]], <|"Status" -> "DeferredForcingNoFile"|>];
    deferredForcingCensus = If[Lookup[deferredForcingPlan, "Status", None] === "OK",
      finiteFieldDeferredForcingCensus[deferredForcingPlan["Key"], 2147483423],
      deferredForcingPlan];
    If[Lookup[deferredForcingCensus, "Status", None] === "OK",
      deferredForcingDescriptor = <|"Key" -> deferredForcingPlan["Key"],
        "Census" -> KeyTake[deferredForcingCensus,
          {"Letters", "GaugeFactorPowers", "ForcingInfinityDegree"}],
        (* R2 F2: the helper kernels rebuild the plan from this *)
        "Handle" -> finiteFieldDeferredForcingHandle[deferredForcingPlan]|>;
      timings["DeferredForcingCensus"] = deferredForcingCensus["Seconds"];
      If[verbose, Print["[strip-in-frame] deferred forcing: DAG route, census ",
        Round[deferredForcingCensus["Seconds"], 0.1], " s, letters ",
        Length[deferredForcingCensus["Letters"]], ", pole orders ",
        Lookup[deferredForcingCensus, "GaugeFactorPowers", {}][[All, 2]],
        ", infinity degree ", deferredForcingCensus["ForcingInfinityDegree"]]],
      If[verbose, Print["[strip-in-frame] deferred forcing: DAG route refused (",
        Lookup[deferredForcingCensus, "Status", None], "); exact pull-back"]]]];
  If[AssociationQ[deferredPreparation] && deferredForcingDescriptor === None,
    preparationPullback = transportChartPullBackDeferredPreparation[
      deferredPreparation, data, chartBranchRoots, rootImages];
    If[Lookup[preparationPullback, "Status", None] =!= "OK",
      Return[preparationPullback]];
    chartStrip[[3]] = preparationPullback["OneForm"]];
  timings["ParametrizationPullBack"] = AbsoluteTime[] - stageSeconds;
  (* BOUNDARY 5 (after the pullback; also the last boundary before a
     solver runs on the chart route) *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["ParametrizationPullBackComplete"]]];
  transportChartStageStart["inner solve",
    <|"chart" -> chart["Name"], "strip" -> stripDimensions,
      "leafCount" -> transportChartStageSize[chartStrip]|>];
  {stageSeconds, inner} = AbsoluteTiming[
    solveRationalStrip[chartStrip, chartVariables]];
  timings["InnerSolve"] = stageSeconds;
  transportChartStageDone["inner solve",
    <|"seconds" -> stageSeconds,
      "status" -> If[AssociationQ[inner],
        Lookup[inner, "Status", None], "SolverReturnedFailed"]|>];
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

  presentationVariables = masterTransportPresentationVariables[
    coefficientPresentationData];
  presentationRoots = coefficientPresentationSquareRootRecords[
    coefficientPresentationData];
  If[! MatchQ[presentationVariables, {_Symbol, _Symbol}] ||
      ! ListQ[presentationRoots],
    Return[<|"Status" -> "CoefficientPresentationInvalid",
      "CoefficientPresentation" -> coefficientPresentationData,
      "SquareRootGenerators" -> presentationRoots|>]];
  presentationToSourceRules =
    Thread[presentationVariables -> variables];
  coordinateMap = masterTransportRecordCoordinateMap[
    <|"CoefficientVariables" -> chartVariables,
      "RationalizingParametrization" -> rekeyed|>,
    coefficientPresentationData];
  If[Lookup[coordinateMap, "Status", None] =!= "OK",
    Return[<|"Status" -> "StripGaugePullBackFailed",
      "CoordinateMap" -> coordinateMap|>]];
  (* The coordinate composition is solved in the presentation's own
     coefficient variables.  This solver's contract returns its
     basis-transformation block in the supplied differential variables;
     these symbols name the same coefficient-variable slots, so re-key
     them positionally before all remaining exact checks. *)
  sourceCoordinateImages = Together /@
    ((Last /@ coordinateMap["CoefficientVariableRules"]) /.
      presentationToSourceRules);
  coordinateMap = Join[coordinateMap, <|
    "CoefficientVariableRules" -> MapThread[Rule,
      {First /@ coordinateMap["CoefficientVariableRules"],
        sourceCoordinateImages}],
    "CoefficientVariableImages" -> sourceCoordinateImages|>];
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
    sourceCoordinateImages, allRoots, variables];
  If[Lookup[mapCanonicalization, "Status", None] =!= "OK",
    Return[<|"Status" -> "StripGaugeMapNotInDeclaredField",
      "CoordinateMap" ->
        KeyDrop[coordinateMap, "CoefficientVariableImages"],
      "Canonicalization" -> mapCanonicalization|>]];
  If[verbose && mapCanonicalization["Rewritten"] > 0,
    Print["[strip-in-frame] ", mapCanonicalization["Rewritten"],
      " coordinate-map radical(s) rewritten in the declared field: ",
      mapCanonicalization["RewrittenBases"]]];
  coordinateMap = Join[coordinateMap, <|
    "CoefficientVariableRules" -> MapThread[Rule,
      {First /@ coordinateMap["CoefficientVariableRules"],
        mapCanonicalization["Images"]}],
    "CoefficientVariableImages" -> mapCanonicalization["Images"],
    "DeclaredSquareRootAlgebraRewrites" -> KeyTake[mapCanonicalization,
      {"Rewritten", "RewrittenBases", "NumericRadicalClasses"}]|>];
  transportChartStageMark["acceptance: coordinate map",
    <|"seconds" -> N[AbsoluteTime[] - stageSeconds],
      "rewritten" -> Lookup[mapCanonicalization, "Rewritten", 0],
      "route" -> Lookup[coordinateMap, "CompositionRoute", None]|>];

  Which[
   finiteFieldCanonicalQ,
    finiteFieldGauge = transportChartFiniteFieldCanonicalGauge[
      chartGauge, Lookup[inner, "GaugeDenominator", $Failed],
      chartVariables, coordinateMap["CoefficientVariableImages"],
      variables, epsilon,
      usedRoots,
      Sequence @@ DeleteDuplicatesBy[Join[finiteFieldGaugeOptions,
        {"Deadline" -> deadline, "Verbose" -> TrueQ[verbose]}], First]];
    If[Lookup[finiteFieldGauge, "Status", None] =!=
        "FiniteFieldCanonicalGaugePrepared",
      Return[<|"Status" -> "StripGaugeFiniteFieldReconstructionFailed",
        "Detail" -> KeyDrop[finiteFieldGauge, "Result"]|>],
      sourceGauge = finiteFieldGauge["Result"];
      substageSeconds = finiteFieldGauge["Seconds"];
      parallelTogether = <|"Route" -> "FiniteFieldReconstruct",
        "Helpers" -> 0|>],
   True,
    parallelTogether = transportChartParallelTogether[
      chartGauge, coordinateMap["CoefficientVariableRules"],
      "basis-transformation-block", deadline];
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
      (Lookup[inner, "Alphabet", {}] /.
        coordinateMap["CoefficientVariableRules"])] ];
  transportChartStageMark["acceptance: source alphabet",
    <|"seconds" -> N[substageSeconds], "letters" -> Length[sourceAlphabet]|>];

  (* In production the one block residual is deliberately run HERE, on the
     reconstructed gauge that will actually be installed.  Trying every
     chart-root sheet also fixes the unique branch.  This replaces (rather
     than duplicates) the inner solver's final residual; the latter returned
     PendingPostPullBackResidual above. *)
  If[productionCanonicalQ,
    sourceGaugeRadicalFreeQ = FreeQ[sourceGauge,
      Power[_, exponent_Rational /; Denominator[exponent] > 1]];
    signChoices = If[sourceGaugeRadicalFreeQ,
      {ConstantArray[1, Length[usedRoots]]},
      Tuples[{1, -1}, Length[usedRoots]]];
    postPullBackCandidates = Table[
      branchImages = MapThread[Times, {signs, rootImages}];
      postPullBackGauge = transportChartApplyRootBranches[
          sourceGauge, usedRoots, branchImages] /.
        masterTransportPresentationSubstitution[data];
      postPullBackVerification = If[AssociationQ[deferredForcingDescriptor],
        (* round 8 pass 3: the same residual with the DAG image of the forcing *)
        With[{r = finiteFieldDeferredForcingResidualQ[deferredForcingDescriptor["Key"],
            chartStrip[[1 ;; 2]], postPullBackGauge, inner["Alphabet"], inner["ResidueMatrices"]]},
          (* R2 F4: a modular check, named as such, with its seed, prime and points *)
          <|"DLogFormCertified" -> TrueQ[Lookup[r, "ResidualZero", False]] &&
              FreeQ[inner["Alphabet"], epsilon] &&
              FreeQ[inner["ResidueMatrices"], Alternatives @@ chartVariables],
            "ModularPfaffianResidualsZero" -> Lookup[r, "ResidualZero", False],
            "ModularResidual" -> KeyTake[r, {"Status", "Prime", "Points", "RequestedPoints", "Seed", "Seconds"}],
            "LettersEpsFree" -> FreeQ[inner["Alphabet"], epsilon],
            "ResiduesKinematicsFree" -> FreeQ[inner["ResidueMatrices"], Alternatives @@ chartVariables],
            "ResiduesEpsFree" -> FreeQ[inner["ResidueMatrices"], epsilon],
            "Points" -> Lookup[r, "Points", 0]|>],
        VerifyEpsFormStrip[
          <|"Strip" -> chartStrip, "Variables" -> chartVariables,
            "Regulator" -> epsilon|>,
          Join[KeyTake[inner, {"Alphabet", "ResidueMatrices"}],
            <|"Gauge" -> postPullBackGauge|>],
          "Method" -> "Numerical", "KernelCount" -> 1]];
      <|"Signs" -> signs, "Verification" -> postPullBackVerification|>,
      {signs, signChoices}];
    postPullBackCandidates = Select[postPullBackCandidates,
      TrueQ[Lookup[Lookup[#1, "Verification", <||>],
        "DLogFormCertified", False]] &];
    If[postPullBackCandidates === {},
      Return[<|"Status" -> "PostFiniteFieldResidualFailed",
        "PassingBranchCount" -> 0,
        "BranchCount" -> Length[signChoices]|>]];
    acceptedSigns = {
      Lookup[First[postPullBackCandidates], "Signs", Missing[]]};
    postPullBackVerification = Lookup[
      First[postPullBackCandidates], "Verification", <||>];
    inner = Join[inner,
      KeyTake[postPullBackVerification,
        {"NumericalPfaffianResidualsZero", "ModularPfaffianResidualsZero", "ModularResidual",
         "LettersEpsFree", "ResiduesKinematicsFree", "ResiduesEpsFree"}],
      <|"Certificate" -> If[AssociationQ[deferredForcingDescriptor],
          "ModularResidual", "NumericalResidual"],
        "ExactDLog" -> Missing["DeferredToFamilyCertificate"],
        "DLogFormCertified" -> Missing["DeferredToFamilyCertificate"]|>];
    timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
    transportChartStageDone["acceptance: gauge pull-back",
      <|"seconds" -> timings["GaugePullBack"],
        "route" -> "FiniteFieldReconstruct",
        "branchSigns" -> First[acceptedSigns],
        "familyCertificate" -> "Required"|>];
    transportChartLogSuccessTimings[timings, chart["Name"], verbose];
    innerSeparated = transportChartSeparateTimings[KeyDrop[inner, "Gauge"]];
    Return[<|"Status" -> "Solved",
      "Method" -> "RationalizingParametrization/" <>
        chart["Name"] <> "/" <>
        inner["Method"],
      "Gauge" -> sourceGauge,
      "CoefficientPresentation" -> coefficientPresentationData,
      "SquareRootGeneratorIndices" -> rootIndices,
      "Alphabet" -> sourceAlphabet,
      "InnerSolution" -> innerSeparated["Record"],
      "Timings" -> transportChartTimingsRecord[timings, innerSeparated["Timings"]],
      "ExactDLog" -> Lookup[inner, "ExactDLog", False],
      "Certificate" -> Lookup[inner, "Certificate", "ExactDLog"],
      "Validation" -> <|
        "RationalizingParametrizationName" -> chart["Name"],
        "CoordinateComposition" ->
          TrueQ[coordinateMap["CompositionVerified"]],
        "BranchSigns" -> First[acceptedSigns],
        "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True,
        "SourceDLog" -> Missing["DeferredToFamilyCertificate"],
        "Passed" -> True,
        "ValidationMode" -> "PostPullBackFiniteFieldResidual",
        "InnerCertificate" -> Lookup[inner, "Certificate", None],
        "UnseenPrime" -> Lookup[inner, "UnseenPrime", None],
        "NumericalPfaffianResidualsZero" -> Lookup[inner,
          "NumericalPfaffianResidualsZero", Missing["NotRun"]],
        "ModularPfaffianResidualsZero" -> Lookup[inner,
          "ModularPfaffianResidualsZero", Missing["NotRun"]],
        "ModularResidual" -> Lookup[inner, "ModularResidual", Missing["NotRun"]],
        "Normalizer" -> KeyDrop[finiteFieldGauge, "Result"]|>|>]];

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
          (branchedGauge /.
            masterTransportPresentationSubstitution[data]) -
              chartGauge]]],
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
          Lookup[coordinateMap,
            "DeclaredSquareRootAlgebraRewrites", <||>]|>]]];
  branchImages = MapThread[Times, {First[acceptedSigns], rootImages}];
  timings["GaugePullBack"] = AbsoluteTime[] - stageSeconds;
  transportChartStageDone["acceptance: gauge pull-back",
    <|"seconds" -> timings["GaugePullBack"],
      "branchSigns" -> First[acceptedSigns]|>];

  (* BOUNDARY 7 (before the source-representation identity check): the check
     re-derives the transformed one-form in the algebraic coefficient
     presentation, applies
     the branch images and pulls the pair back through the Jacobian --
     the most expensive exact step of the construction on a large
     strip. *)
  If[transportChartDeadlineExpiredQ[deadline],
    Return[budgetExhausted["SourceRepresentationIdentity"]]];
  stageSeconds = AbsoluteTime[];
  transportChartStageStart["acceptance: source-representation identity",
    <|"chart" -> chart["Name"], "gauge" -> Dimensions[sourceGauge],
      "sourceGaugeLeafCount" -> transportChartStageSize[sourceGauge],
      "chartGaugeLeafCount" -> transportChartStageSize[chartGauge],
      "roots" -> Length[usedRoots]|>];

  (* Same ordering rule as the pullback above: the source-representation
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
      Map[Together,
        # /. masterTransportPresentationSubstitution[data], {2}] &,
      pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]],
      data["DifferentialPullbackMatrix"]]
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
    zeroMatrixNamedQ["source-representation zero test mu=1",
        pulledTransformed[[1]] - chartTransformed[[1]]] &&
      zeroMatrixNamedQ["source-representation zero test mu=2",
        pulledTransformed[[2]] - chartTransformed[[2]]],
    $transportChartZeroTestTag,
    Function[{payload, tag}, zeroTestStop = payload; False]];
  If[AssociationQ[zeroTestStop],
    timings["SourceRepresentationIdentity"] =
      AbsoluteTime[] - stageSeconds;
    Return[Join[budgetExhausted["SourceRepresentationIdentity"],
      <|"ZeroTestSubstage" -> Lookup[zeroTestStop, "Substage", "ZeroTest"]|>,
      KeyDrop[zeroTestStop, "Substage"]]]];
  transportChartStageDone["acceptance: one-form zero test",
    <|"seconds" -> N[AbsoluteTime[] - stageSeconds],
      "identity" -> identityHolds|>];
  If[! identityHolds,
    Return[If[comparatorRefusals === {},
      <|"Status" -> "StripGaugeSourceRepresentationIdentityFailed"|>,
      <|"Status" -> "StripGaugeSourceRepresentationUndeclaredRadicals",
        "RadicalBases" -> DeleteDuplicates[Flatten[comparatorRefusals]]|>]]];
  timings["SourceRepresentationIdentity"] =
    AbsoluteTime[] - stageSeconds;
  transportChartStageDone["acceptance: source-representation identity",
    <|"seconds" -> timings["SourceRepresentationIdentity"]|>];
  (* one rate-limited success diagnostic: the payload below is unchanged *)
  transportChartLogSuccessTimings[timings, chart["Name"], verbose];

  (* the mathematical payload is byte-identical between solves: the
     wall-clock numbers of the inner solve and of this construction live
     in the one "Timings" record (U4, 2026-09-02) *)
  innerSeparated = transportChartSeparateTimings[KeyDrop[inner, "Gauge"]];
  <|"Status" -> "Solved",
    "Method" -> "RationalizingParametrization/" <>
      chart["Name"] <> "/" <> inner["Method"],
    "Gauge" -> sourceGauge,
    "CoefficientPresentation" -> coefficientPresentationData,
    "SquareRootGeneratorIndices" -> rootIndices,
    "Alphabet" -> sourceAlphabet,
    "InnerSolution" -> innerSeparated["Record"],
    "Timings" -> transportChartTimingsRecord[timings, innerSeparated["Timings"]],
    "ExactDLog" -> TrueQ[Lookup[inner, "ExactDLog", False]],
    "Certificate" -> Lookup[inner, "Certificate", "ExactDLog"],
    (* Coordinate-map canonicalization remains diagnostic evidence for a
       typed stop; the accepted result records the exact identities below. *)
    "Validation" -> <|
      "RationalizingParametrizationName" -> chart["Name"],
      "CoordinateComposition" -> coordinateMap["CompositionVerified"],
      "BranchSigns" -> First[acceptedSigns],
      "GaugeRoundTrip" -> True,
      "TransformedOneFormPullBack" -> True,
      "SourceDLog" -> True,
      "Method" -> "Exact",
      "Passed" -> True|>|>
]
];


(* Retired route (overhaul 2026-09-02, goal 1): the Maple canonical gauge
   normalizer behind GaugePullBackMode -> "MapleCanonical" lives in
   FeynFacet/Private_Backup/TransportCharts.wl and is not loaded; the
   modes "Exact" (default) and "FiniteFieldReconstruct" remain, and since
   round 4 (2026-09-02) the option gate of SolveEpsFormStripInFrame no
   longer admits "MapleCanonical" at all.  This stub is kept so that a
   stored record whose provenance names the mode stays readable and a
   direct call is answered by name, never by an unevaluated symbol. *)
transportChartMapleCanonicalGauge[___] := <|"Status" -> "RouteRetired",
  "Route" -> "GaugePullBackMode -> MapleCanonical",
  "Code" -> "FeynFacet/Private_Backup/TransportCharts.wl"|>;
