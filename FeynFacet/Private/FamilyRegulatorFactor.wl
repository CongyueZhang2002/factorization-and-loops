(* Family-level regulator factorization (2026-08-22, replaces the
   per-sector CANONICA TransformDlogToEpsForm step of the sector script).

   After the off-diagonal completion the family connection is
     A_mu = eps Sum_a K_a(eps) dlog_mu L_a
   with letters free of the regulator and residue matrices K_a that may
   still depend on it (the dlog-form contract).  A CONSTANT (chart
   independent) transformation T(eps) with T^{-1} K_a T free of eps is
   found once for the whole family with Libra`FactorDependence on exact
   rational samples of A_mu/eps: the identity A(eps, x) T(eps) = T(eps)
   A(mu, x) at generic chart points is linear in T.  Development audits
   the unsampled symbolic identity here; Production defers acceptance to
   the final family certificate (the method of
   Scripts/Libra/libra_checkpoint_factor_dependence.wls, "ExactRationalSamples").
   Since T is constant in the variables, dT = 0 and A' = T^{-1} A T. *)

Clear[FactorFamilyRegulatorDependence];
ClearAll[familyRegulatorFactoredQ, familyRegulatorSpecialize,
  familyRegulatorConjugate, familyRegulatorSparseDot,
  familyRegulatorConjugateDeferred, familyRegulatorSparseDotDeferred,
  familyRegulatorPropagationSeal,
  familyRegulatorPropagateTruncation, familyRegulatorPointFactoredQ,
  familyRegulatorSampleFactoredQ,
  familyRegulatorFactorFromPointEvaluator,
  familyRegulatorChartPointConnection,
  familyRegulatorLiteralRootClassification,
  familyRegulatorDeadlineActiveQ, familyRegulatorRemainingSeconds,
  familyRegulatorDeadlineExpiredQ, familyRegulatorBoundedLimit,
  familyRegulatorDeadlineStop];

(* ---- the cooperative absolute deadline (Codex 0830 P2) --------------
   "TimeLimit" bounds ONE subcall; the regulator stage makes many of them
   (grade decomposition, a point ladder, an exact check, spot checks, a
   modular corroboration), so "TimeLimit" -> 600 was never a 600 s stage
   budget and the stage did not cooperate with the driver's sector
   deadline.  "Deadline" is an ABSOLUTE AbsoluteTime[]; Infinity (the
   default) reproduces the former unbounded behaviour exactly.  Every
   bounded subcall is capped by the remaining time and every stage
   boundary is a checkpoint that returns a typed, resumable stop. *)
familyRegulatorDeadlineActiveQ[deadline_] :=
  NumericQ[deadline] && TrueQ[deadline < Infinity];
familyRegulatorRemainingSeconds[deadline_] :=
  If[familyRegulatorDeadlineActiveQ[deadline],
    deadline - AbsoluteTime[], Infinity];
familyRegulatorDeadlineExpiredQ[deadline_] :=
  familyRegulatorDeadlineActiveQ[deadline] && AbsoluteTime[] >= deadline;
(* the bounded subcall's own limit, never above the time that is left *)
familyRegulatorBoundedLimit[limit_, deadline_] := Module[
  {remaining = familyRegulatorRemainingSeconds[deadline]},
  Which[
    remaining === Infinity, limit,
    NumericQ[limit], Min[limit, Max[remaining, 0]],
    True, Max[remaining, 0]]];
familyRegulatorDeadlineStop[stage_String, deadline_, start_,
    extra_Association : <||>] := Join[
  <|"Status" -> "RegulatorFactorizationDeadlineExpired",
    "Module" -> "FamilyRegulatorFactor", "Stage" -> stage,
    "Deadline" -> deadline, "Resumable" -> True,
    "Seconds" -> AbsoluteTime[] - start|>, extra];

(* products with a constant (variable-free) matrix, entry by entry over
   its nonzero pattern, Together applied as each entry is formed: the
   plain Dot builds all n^3 symbolic terms at once (44 masters: ~30 GB on
   CF385, 2026-08-22) *)
familyRegulatorSparseDot[left_List, right_List, leftConstantQ_] := Module[{n = Length[left], m = Length[First[right]], pattern},
  If[leftConstantQ,
    pattern = Table[Flatten[Position[left[[i]], Except[0], {1}, Heads -> False]], {i, n}];
    Table[Together[Sum[left[[i, a]] right[[a, j]], {a, pattern[[i]]}]], {i, n}, {j, m}],
    pattern = Table[Flatten[Position[right[[All, j]], Except[0], {1}, Heads -> False]], {j, m}];
    Table[Together[Sum[left[[i, a]] right[[a, j]], {a, pattern[[j]]}]], {i, n}, {j, m}]]];
familyRegulatorConjugate[inverse_List, matrix_List, transformation_List] :=
  familyRegulatorSparseDot[familyRegulatorSparseDot[inverse, matrix, True], transformation, False];

(* Production keeps exact sparse sums in deferred form until the final family
   certificate.  This performs the same algebra as familyRegulatorSparseDot
   without canonicalizing every symbolic entry with Together. *)
familyRegulatorSparseDotDeferred[left_List, right_List,
    leftConstantQ_] := Module[{n = Length[left], m = Length[First[right]],
    pattern, combine},
  combine[terms_List] := Which[
    terms === {}, 0,
    Length[terms] === 1, First[terms],
    True, Total[terms]];
  If[leftConstantQ,
    pattern = Table[Flatten[Position[left[[i]], Except[0], {1},
      Heads -> False]], {i, n}];
    Table[combine[(left[[i, #]] right[[#, j]] &) /@ pattern[[i]]],
      {i, n}, {j, m}],
    pattern = Table[Flatten[Position[right[[All, j]], Except[0], {1},
      Heads -> False]], {j, m}];
    Table[combine[(left[[i, #]] right[[#, j]] &) /@ pattern[[j]]],
      {i, n}, {j, m}]]];
familyRegulatorConjugateDeferred[inverse_List, matrix_List,
    transformation_List] := familyRegulatorSparseDotDeferred[
  familyRegulatorSparseDotDeferred[inverse, matrix, True],
  transformation, False];

(* The seal is created inside the accepted factor routine, where the input
   prefix is authoritative.  The propagation helper recomputes it before
   installing any caller-supplied transformed prefix. *)
familyRegulatorPropagationSeal[
    inputPrefix : {_List, _List}, transformedPrefix : {_List, _List},
    inverse_List, transformation_List] := Module[{payload},
  payload = <|
    "Schema" -> "FeynFacetRegulatorPropagationSeal",
    "SchemaVersion" -> 1,
    "InputPrefixSHA256" ->
      Hash[inputPrefix, "SHA256", "HexString"],
    "TransformedPrefixSHA256" ->
      Hash[transformedPrefix, "SHA256", "HexString"],
    "InverseSHA256" -> Hash[inverse, "SHA256", "HexString"],
    "TransformationSHA256" ->
      Hash[transformation, "SHA256", "HexString"]|>;
  Join[payload, <|"Fingerprint" ->
    Hash[KeySort[payload], "SHA256", "HexString"]|>]
];
familyRegulatorPropagationSeal[___] := $Failed;

(* Propagate a constant regulator factor found and certified on the leading
   prefix.  For G = diag(T,I) and a block-lower-triangular connection,
     G^-1 A G = {{T^-1 A00 T, 0}, {A10 T, A11}}.
   Deferred changes representation only: the sealed transformed prefix is
   installed, while future/lower entries retain exact sparse right-product
   sums.  Together preserves the historical full-conjugation path.  The
   inverse replay is an audit-mode check; Production leaves it to the final
   family certificate. *)
familyRegulatorPropagateTruncation[
    connection : {_List, _List}, transformedPrefix : {_List, _List},
    inverse_List, transformation_List, prefix_Integer?Positive,
    variables : {_Symbol, _Symbol}, seal_,
    futureMode_: "Together", validateInverse_: True] := Module[
  {n, futureRows, upperRightZeroQ, newConnection = connection,
   transformationColumnSupport, left, leftRowSupport, support, terms,
   value, products = 0, touched = 0, deferred = 0, singleTerm = 0,
   tFull, tInverse, inverseExactQ, expectedSeal, mu, i, j},
  If[! And @@ (MatrixQ /@ connection) ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      Length[connection[[1]]] =!= Length[First[connection[[1]]]],
    Return[<|"Status" -> "InvalidConnectionDimensions"|>]];
  n = Length[connection[[1]]];
  If[prefix > n || Dimensions[transformedPrefix] =!= {2, prefix, prefix} ||
      Dimensions[inverse] =!= {prefix, prefix} ||
      Dimensions[transformation] =!= {prefix, prefix} ||
      ! FreeQ[transformedPrefix,
        Alternatives[_Missing, Automatic, $Failed]],
    Return[<|"Status" -> "InvalidTruncationDimensions"|>]];
  If[! FreeQ[{inverse, transformation}, Alternatives @@ variables],
    Return[<|"Status" ->
      "RegulatorTransformationNotConstant"|>]];
  inverseExactQ = If[TrueQ[validateInverse],
    And @@ (AllTrue[
      Flatten[Map[Together, #, {2}]], SameQ[#, 0] &] & /@ {
        inverse . transformation - IdentityMatrix[prefix],
        transformation . inverse - IdentityMatrix[prefix]}),
    Missing["DeferredToFamilyCertificate"]];
  If[TrueQ[validateInverse] && ! inverseExactQ,
    Return[<|"Status" ->
      "RegulatorTransformationInverseInvalid"|>]];
  If[TrueQ[validateInverse],
    expectedSeal = familyRegulatorPropagationSeal[
      connection[[All, Range[prefix], Range[prefix]]],
      transformedPrefix, inverse, transformation];
    If[expectedSeal === $Failed || ! SameQ[seal, expectedSeal],
      Return[<|"Status" -> "RegulatorPropagationSealMismatch"|>]],
    expectedSeal = Missing["DeferredToFamilyCertificate"]];
  If[! MemberQ[{"Together", "Deferred"}, futureMode],
    Return[<|"Status" -> "InvalidFutureAMode",
      "Actual" -> futureMode|>]];
  upperRightZeroQ = prefix === n || AllTrue[
    Flatten[connection[[All, Range[prefix], Range[prefix + 1, n]]]],
    SameQ[#, 0] &];
  If[! upperRightZeroQ,
    Return[<|"Status" -> "InvalidBlockStructure",
      "Reason" -> "the leading-prefix upper-right block must be structurally zero"|>]];
  If[futureMode === "Together",
    tFull = IdentityMatrix[n];
    tFull[[1 ;; prefix, 1 ;; prefix]] = transformation;
    tInverse = IdentityMatrix[n];
    tInverse[[1 ;; prefix, 1 ;; prefix]] = inverse;
    Return[<|"Status" -> "OK",
      "Connection" -> Table[
        familyRegulatorConjugate[tInverse, connection[[mu]], tFull],
        {mu, 2}],
      "Statistics" -> <|"FutureAMode" -> "Together",
        "FutureCandidateEntries" -> 2 (n - prefix) prefix,
        "FutureProducts" -> Missing["CanonicalFullConjugation"],
        "FutureTouched" -> Missing["CanonicalFullConjugation"],
        "DeferredFutureEntries" -> 0,
        "SingleTermFastPath" ->
          Missing["CanonicalFullConjugation"]|>|>]];
  newConnection[[All, Range[prefix], Range[prefix]]] =
    transformedPrefix;
  futureRows = Range[prefix + 1, n];
  transformationColumnSupport = Table[
    Flatten[Position[transformation[[All, j]], Except[0], {1},
      Heads -> False]], {j, prefix}];
  Do[
    left = connection[[mu, futureRows, Range[prefix]]];
    leftRowSupport = Table[Flatten[Position[left[[i]], Except[0], {1},
      Heads -> False]], {i, Length[futureRows]}];
    Do[
      support = Intersection[leftRowSupport[[i]],
        transformationColumnSupport[[j]]];
      products += Length[support];
      terms = (left[[i, #]] transformation[[#, j]] &) /@ support;
      value = Which[terms === {}, 0,
        Length[terms] === 1, singleTerm++; First[terms],
        True, deferred++; Total[terms]];
      If[! SameQ[value, connection[[mu, futureRows[[i]], j]]],
        newConnection[[mu, futureRows[[i]], j]] = value;
        touched++],
      {i, Length[futureRows]}, {j, prefix}],
    {mu, 2}];
  <|"Status" -> "OK", "Connection" -> newConnection,
    "Statistics" -> <|"FutureAMode" -> "Deferred",
      "FutureCandidateEntries" -> 2 Length[futureRows] prefix,
      "FutureProducts" -> products, "FutureTouched" -> touched,
      "DeferredFutureEntries" -> deferred,
      "SingleTermFastPath" -> singleTerm|>|>
];
familyRegulatorPropagateTruncation[___] :=
  <|"Status" -> "InvalidArguments"|>;

FactorFamilyRegulatorDependence::input =
  "The connection must be a pair of equally sized square matrices.";

Options[FactorFamilyRegulatorDependence] = {
  "TimeLimit" -> 900,
  "Deadline" -> Infinity,
  (* False means the caller already has the strip solver's residue
     metadata proving that regulator factorization is needed.  It skips
     only the redundant whole-connection precheck. *)
  "InputResiduesEpsFree" -> Automatic,
  "ValidationMode" -> "Exact",
  "UseFermat" -> Automatic,
  "PointLadder" -> {2, 4, 8, 16},
  "GatePoints" -> 2,
  "Verbose" -> False
};

(* Cheap gate before the symbolic acceptance test (profiled on the 41x41
   CF408 connection, 2026-08-22): a candidate from too few sampled points
   is a dense wrong T whose symbolic conjugation costs ~90 s, against ~4 s
   for the true sparse one.  Conjugating the connection evaluated at a
   few random rational chart points (rational functions of the regulator
   only) and testing eps-factorization there rejects such a candidate in
   a fraction of a second.  Development then performs the symbolic audit;
   Production defers acceptance to the final family certificate. *)
familyRegulatorPointFactoredQ[inverse_List, {ax_List, ay_List}, candidate_List, rules_List, epsilon_Symbol] :=
  AllTrue[rules, Function[r, Module[{sx, sy},
    {sx, sy} = {ax, ay} /. r;
    If[! FreeQ[{sx, sy}, Indeterminate | ComplexInfinity | DirectedInfinity[_]], Return[True, Module]];
    familyRegulatorFactoredQ[familyRegulatorConjugate[inverse, sx, candidate], epsilon] &&
      familyRegulatorFactoredQ[familyRegulatorConjugate[inverse, sy, candidate], epsilon]]]];

familyRegulatorSampleFactoredQ[inverse_List, samples_List,
    candidate_List, epsilon_Symbol] := AllTrue[samples,
  Function[sample,
    ListQ[sample] && sample =!= {} && AllTrue[sample,
      Function[matrix, MatrixQ[matrix] && familyRegulatorFactoredQ[
        familyRegulatorConjugate[inverse, matrix, candidate], epsilon]]]]];

(* Find the constant regulator transformation from an exact point evaluator.
   The evaluator substitutes kinematics before Together, so a rational chart
   never has to materialize a giant symbolic bivariate pullback.  Samples are
   drawn lazily from opposite ends of the deterministic pool: the ladder sees
   only as many training points as it requests, and the point gate is disjoint.
   This routine constructs T(eps); Production's final family certificate is
   still the acceptance boundary for the unsampled connection. *)
Options[familyRegulatorFactorFromPointEvaluator] = Join[
  Options[FactorFamilyRegulatorDependence], {"BatchEvaluator" -> None}];

familyRegulatorFactorFromPointEvaluator[evaluator_, n_Integer?Positive,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    opts : OptionsPattern[]] := Module[
  {start = AbsoluteTime[], verbose, log, deadline, validationMode,
   deferAcceptanceQ, rules, head = 1, tail, training = {}, gates = {},
   trainingRules = {}, gateRules = {}, expired = False, sampleTimedOut = False,
   sampleAt, sampleBatchAt, validSampleQ, ensurePointSets,
   batchEvaluator, backend = None,
   fermatRequested, reference = Unique["regulatorReference"],
   transformation = $Failed, inverse, raw, pointsUsed = 0, attempts = {},
   ladderLimit},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose,
    Print["[regulator-factor/evaluated] ", args]];
  deadline = OptionValue["Deadline"];
  validationMode = OptionValue["ValidationMode"];
  deferAcceptanceQ = validationMode === "DeferredToFamilyCertificate";
  batchEvaluator = OptionValue["BatchEvaluator"];
  If[! deferAcceptanceQ,
    Return[<|"Status" -> "EvaluatedRouteRequiresDeferredValidation"|>]];
  rules = Table[{variables[[1]] -> Prime[k + 3]/Prime[k + 11],
      variables[[2]] -> Prime[2 k + 5]/Prime[2 k + 15]}, {k, 1, 24}];
  tail = Length[rules];
  validSampleQ[sample_] := ListQ[sample] && sample =!= {} &&
    AllTrue[sample, MatrixQ[#1] && Dimensions[#1] === {n, n} &] &&
    FreeQ[sample, Indeterminate | ComplexInfinity | DirectedInfinity[_]];
  sampleAt[rule_] := Module[{remaining, sampled},
    If[familyRegulatorDeadlineExpiredQ[deadline],
      expired = True; Return[$Failed]];
    remaining = familyRegulatorBoundedLimit[OptionValue["TimeLimit"],
      deadline];
    sampled = Quiet[TimeConstrained[evaluator[rule], remaining,
      "TimedOut"]];
    If[sampled === "TimedOut",
      sampleTimedOut = True; Return[$Failed]];
    sampled];
  sampleBatchAt[pointRules_List] := Module[{remaining, sampled},
    If[pointRules === {}, Return[{}]];
    If[batchEvaluator === None, Return[sampleAt /@ pointRules]];
    If[familyRegulatorDeadlineExpiredQ[deadline],
      expired = True; Return[ConstantArray[$Failed, Length[pointRules]]]];
    remaining = familyRegulatorBoundedLimit[OptionValue["TimeLimit"],
      deadline];
    sampled = Quiet[TimeConstrained[batchEvaluator[pointRules], remaining,
      "TimedOut"]];
    If[sampled === "TimedOut",
      sampleTimedOut = True;
      Return[ConstantArray[$Failed, Length[pointRules]]]];
    If[ListQ[sampled] && Length[sampled] === Length[pointRules], sampled,
      ConstantArray[$Failed, Length[pointRules]]]];
  (* A Production candidate needs one training image and two disjoint gate
     images.  They are independent exact specializations of the same large
     connection, so request the whole missing set together.  The default
     scalar evaluator keeps the historical sequential behavior; the graded
     route supplies a brokered batch evaluator. *)
  ensurePointSets[trainingCount_Integer, gateCount_Integer] := Module[
    {requestedRules, requestedKinds, sampled, neededTraining, neededGates},
    While[(Length[training] < trainingCount || Length[gates] < gateCount) &&
        head <= tail,
      requestedRules = {}; requestedKinds = {};
      neededTraining = trainingCount - Length[training];
      While[neededTraining > 0 && head <= tail,
        AppendTo[requestedRules, rules[[head]]];
        AppendTo[requestedKinds, "Training"];
        head++; neededTraining--];
      neededGates = gateCount - Length[gates];
      While[neededGates > 0 && head <= tail,
        AppendTo[requestedRules, rules[[tail]]];
        AppendTo[requestedKinds, "Gate"];
        tail--; neededGates--];
      If[requestedRules === {}, Break[]];
      sampled = sampleBatchAt[requestedRules];
      Do[If[validSampleQ[sampled[[index]]],
        If[requestedKinds[[index]] === "Training",
          AppendTo[training, sampled[[index]]];
          AppendTo[trainingRules, requestedRules[[index]]],
          AppendTo[gates, sampled[[index]]];
          AppendTo[gateRules, requestedRules[[index]]]]],
        {index, Length[requestedRules]}]];
    Length[training] >= trainingCount && Length[gates] >= gateCount];
  Do[
    If[! ensurePointSets[count, OptionValue["GatePoints"]], Break[]];
    If[backend === None,
      fermatRequested = OptionValue["UseFermat"];
      If[! libraEpsFormFermatCompatibleQ[First[training]],
        fermatRequested = False];
      backend = libraEpsFormLoadBackend[fermatRequested];
      If[Lookup[backend, "Status", None] =!= "OK", Return[backend]]];
    ladderLimit = familyRegulatorBoundedLimit[OptionValue["TimeLimit"],
      deadline];
    If[familyRegulatorDeadlineExpiredQ[deadline] ||
        (NumericQ[ladderLimit] && ladderLimit <= 0),
      expired = True; Break[]];
    Module[{matrices, result, candidate, gate = False, ok = False, seconds},
      matrices = Flatten[Table[
        Map[Together, #1/epsilon, {2}] & /@ training[[k]],
        {k, count}], 1];
      log["FactorDependence on ", Length[matrices],
        " evaluated matrices (", count, " points)"];
      {seconds, result} = AbsoluteTiming[Quiet[TimeConstrained[
        Libra`FactorDependence[matrices, epsilon, reference,
          DependentRowIndices -> Automatic, Sort -> True],
        ladderLimit, "TimedOut"]]];
      candidate = If[MatrixQ[result],
        familyRegulatorSpecialize[result, reference, n], $Failed];
      If[MatrixQ[candidate],
        inverse = Map[Together, Inverse[candidate], {2}];
        gate = familyRegulatorSampleFactoredQ[inverse, gates, candidate,
          epsilon];
        ok = gate];
      AppendTo[attempts, <|"Points" -> count, "Seconds" -> seconds,
        "PointGate" -> gate,
        "ExactEpsFactor" -> Missing["DeferredToFamilyCertificate"],
        "TrainingRules" -> Take[trainingRules, count],
        "GateRules" -> gateRules,
        "Result" -> If[result === "TimedOut", "TimedOut",
          If[MatrixQ[result], "Matrix", Head[result]]]|>];
      log[count, " points: ", Round[seconds, 0.1],
        " s, point gate ", gate];
      If[ok, transformation = candidate; raw = result; pointsUsed = count]];
    If[MatrixQ[transformation], Break[]],
    {count, OptionValue["PointLadder"]}];
  If[! MatrixQ[transformation],
    If[TrueQ[expired] || TrueQ[sampleTimedOut],
      Return[familyRegulatorDeadlineStop[
        If[sampleTimedOut, "EvaluatedChartPoint", "PointLadder"],
        deadline, start, <|"Attempts" -> attempts,
          "TrainingPointCount" -> Length[training],
          "GatePointCount" -> Length[gates]|>]]];
    Return[<|"Status" -> "NotFactored", "Attempts" -> attempts,
      "TrainingPointCount" -> Length[training],
      "GatePointCount" -> Length[gates],
      "Seconds" -> AbsoluteTime[] - start|>]];
  <|"Status" -> "OK", "Method" -> "EvaluatedRationalSamples",
    "Points" -> pointsUsed, "Transformation" -> transformation,
    "Inverse" -> inverse, "Attempts" -> attempts,
    "TrainingPointCount" -> Length[training],
    "GatePointCount" -> Length[gates],
    "UseFermat" -> Lookup[backend, "UseFermat", False],
    "Seconds" -> AbsoluteTime[] - start|>
];
familyRegulatorFactorFromPointEvaluator[___] := $Failed;

(* Exact chart pullback at one rational chart point.  Source invariants and
   every declared root are specialized first; only then are rational entries
   combined with the numeric Jacobian. *)
familyRegulatorChartPointConnection[connection : {_List, _List},
    rootTags_List, data_Association, rootImages_List, rule_List] := Module[
  {sourceRules, pointRootImages, jacobian, components},
  sourceRules = Map[Function[item,
      First[item] -> Together[Last[item] /. rule]], data["Subst"]];
  pointRootImages = Together /@ (rootImages /. rule);
  jacobian = Map[Together, data["Jacobian"] /. rule, {2}];
  components = Map[Function[matrix,
      Map[Together, matrix /. sourceRules /.
        Thread[rootTags -> pointRootImages], {2}]],
    connection];
  If[! MatchQ[components, {{__List}, {__List}}] ||
      ! MatrixQ[jacobian] || Dimensions[jacobian] =!= {2, 2},
    Return[$Failed]];
  masterTransportPullBackOneForm[
    components[[1]], components[[2]], jacobian]
];
familyRegulatorChartPointConnection[___] := $Failed;

familyRegulatorFactoredQ[expression_, epsilon_Symbol] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];

(* Libra returns free constants C[i]; any specialization with a
   nonsingular matrix is a valid transformation *)
familyRegulatorSpecialize[transformation_, reference_, n_Integer] := Module[
  {constants, candidates},
  constants = DeleteDuplicates[Cases[transformation, _C, Infinity]];
  candidates = If[constants === {}, {{}},
    {Thread[constants -> Range[Length[constants]]],
     Thread[constants -> Prime[Range[Length[constants]]]],
     Thread[constants -> (Range[Length[constants]] + 1)]}];
  SelectFirst[
    (Map[Together, transformation /. # /. reference -> 1, {2}] &) /@ candidates,
    MatrixQ[#] && Dimensions[#] === {n, n} && ! TrueQ[Together[Det[#]] === 0] &, $Failed]
];

FactorFamilyRegulatorDependence[{ax_List, ay_List}, {x_Symbol, y_Symbol}, epsilon_Symbol,
    OptionsPattern[]] := Module[
  {n, start = AbsoluteTime[], verbose, log, backend, reference, rules, valid,
   transformation = $Failed, inverse, raw, attempts = {}, newAx, newAy,
   pointsUsed = 0, fermatRequested, deadline, expired = False, ladderLimit,
   validationMode, deferAcceptanceQ},
  If[! (MatrixQ[ax] && MatrixQ[ay] && Dimensions[ax] === Dimensions[ay] &&
      Length[ax] === Length[First[ax]]),
    Message[FactorFamilyRegulatorDependence::input]; Return[$Failed]];
  n = Length[ax];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[regulator-factor] ", args]];
  deadline = OptionValue["Deadline"];
  validationMode = OptionValue["ValidationMode"];
  deferAcceptanceQ = validationMode === "DeferredToFamilyCertificate";
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["Entry", deadline, start]]];
  If[OptionValue["InputResiduesEpsFree"] =!= False &&
      familyRegulatorFactoredQ[ax, epsilon] &&
      familyRegulatorFactoredQ[ay, epsilon],
    log["the connection is already eps-factored"];
    Return[<|"Status" -> "AlreadyEpsFactored", "Transformation" -> IdentityMatrix[n],
      "Inverse" -> IdentityMatrix[n], "Connection" -> {ax, ay}, "Seconds" -> 0.|>]];
  (* Fermat's algebra engine is a RATIONAL function engine.  Since
     2026-08-24 the connection may legitimately carry numeric radical
     constants (Sqrt[2] and the like: the square-class constants of the
     denesting layer, chart independent by construction), and those are
     not Fermat input.  The existing compatibility predicate decides;
     an explicit "UseFermat" -> True is a request, not a licence to feed
     Fermat an algebraic number. *)
  fermatRequested = OptionValue["UseFermat"];
  If[! libraEpsFormFermatCompatibleQ[{ax, ay}],
    log["the connection is not Fermat compatible (algebraic constants); \
using the Wolfram backend"];
    fermatRequested = False];
  backend = libraEpsFormLoadBackend[fermatRequested];
  If[backend["Status"] =!= "OK", Return[<|"Status" -> backend["Status"]|>]];
  reference = Unique["regulatorReference"];
  rules = Table[{x -> Prime[k + 3]/Prime[k + 11], y -> Prime[2 k + 5]/Prime[2 k + 15]}, {k, 1, 24}];
  valid = Select[rules, Function[r, Module[{s = Map[Together, {ax, ay} /. r, {3}]},
    FreeQ[s, Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
      AllTrue[Flatten[s], Denominator[#] =!= 0 &]]]];
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["SamplePoints", deadline, start]]];
  Do[
    If[count > Length[valid], Break[]];
    (* the deadline is checked at EVERY ladder rung: without it each rung
       received a fresh full "TimeLimit" and the stage budget was the
       limit times the ladder length *)
    ladderLimit = familyRegulatorBoundedLimit[OptionValue["TimeLimit"], deadline];
    If[familyRegulatorDeadlineExpiredQ[deadline] ||
        (NumericQ[ladderLimit] && ladderLimit <= 0),
      expired = True; Break[]];
    Module[{matrices, result, candidate, ok = False, gate = False, seconds},
      matrices = Flatten[Table[{Map[Together, (ax/epsilon) /. valid[[k]], {2}],
        Map[Together, (ay/epsilon) /. valid[[k]], {2}]}, {k, count}], 1];
      log["FactorDependence on ", Length[matrices], " sampled matrices (", count, " points)"];
      {seconds, result} = AbsoluteTiming[Quiet[TimeConstrained[
        Libra`FactorDependence[matrices, epsilon, reference,
          DependentRowIndices -> Automatic, Sort -> True],
        ladderLimit, "TimedOut"]]];
      candidate = If[MatrixQ[result], familyRegulatorSpecialize[result, reference, n], $Failed];
      If[MatrixQ[candidate],
        inverse = Map[Together, Inverse[candidate], {2}];
        gate = familyRegulatorPointFactoredQ[inverse, {ax, ay}, candidate,
          Take[Reverse[valid], UpTo[OptionValue["GatePoints"]]], epsilon];
        If[gate,
          newAx = If[deferAcceptanceQ,
            familyRegulatorConjugateDeferred[inverse, ax, candidate],
            familyRegulatorConjugate[inverse, ax, candidate]];
          newAy = If[deferAcceptanceQ,
            familyRegulatorConjugateDeferred[inverse, ay, candidate],
            familyRegulatorConjugate[inverse, ay, candidate]];
          ok = deferAcceptanceQ ||
            (familyRegulatorFactoredQ[newAx, epsilon] &&
              familyRegulatorFactoredQ[newAy, epsilon])]];
      AppendTo[attempts, <|"Points" -> count, "Seconds" -> seconds,
        "PointGate" -> gate,
        "ExactEpsFactor" -> If[deferAcceptanceQ,
          Missing["DeferredToFamilyCertificate"], ok],
        "Result" -> If[result === "TimedOut", "TimedOut", If[MatrixQ[result], "Matrix", Head[result]]]|>];
      log[count, " points: ", Round[seconds, 0.1], " s, point gate ", gate,
        If[deferAcceptanceQ,
          "; exact acceptance deferred to family certificate",
          ", exact eps-factorization " <> ToString[ok]]];
      If[ok, transformation = candidate; raw = result; pointsUsed = count]];
    If[MatrixQ[transformation], Break[]],
    {count, OptionValue["PointLadder"]}];
  If[! MatrixQ[transformation],
    If[TrueQ[expired],
      Return[familyRegulatorDeadlineStop["PointLadder", deadline, start,
        <|"Attempts" -> attempts|>]]];
    Return[<|"Status" -> "NotFactored", "Attempts" -> attempts,
      "Seconds" -> AbsoluteTime[] - start|>]];
  <|"Status" -> "OK", "Method" -> "ExactRationalSamples", "Points" -> pointsUsed,
    "Transformation" -> transformation, "Inverse" -> inverse,
    "Connection" -> {newAx, newAy}, "Attempts" -> attempts,
    "ValidationMode" -> validationMode,
    "ExactEpsFactorization" -> If[deferAcceptanceQ,
      Missing["DeferredToFamilyCertificate"], True],
    "PropagationSeal" -> If[deferAcceptanceQ,
      Missing["DeferredToFamilyCertificate"],
      familyRegulatorPropagationSeal[
        {ax, ay}, {newAx, newAy}, inverse, transformation]],
    "UseFermat" -> backend["UseFermat"], "Seconds" -> AbsoluteTime[] - start|>
];

(* ------------------------------------------------------------------ *)
(*  Multiquadratic regulator factorization (2026-08-25, CF259)          *)
(* ------------------------------------------------------------------ *)
(* WHY.  CF259 stopped typed at rows 1..23 (2026-08-25 07:50): the three
   declared roots of the completed 41x41 truncation have NO joint
   rational chart (TransportRootSetChart is Missing["NoRationalChart"];
   the triple cover is a K3 surface, not a rational one), so the chart
   route of FactorFamilyRegulatorDependenceInFrame has nothing to pull
   back to.  The constant T(eps) must therefore be found in the graded
   algebra R = F(x,y)[r_1,...,r_k]/(r_i^2 - q_i) itself.

   THE OBSERVATION THAT MAKES IT LINEAR AND EXACT.  T is an element of
   GL(n, Q(eps)): it is constant in (x, y) AND it lies in GRADE 0 of the
   algebra.  Multiplication by a grade-0 element preserves the grading,
   so conjugation acts grade by grade:

     (T^-1 A_mu T)^(g) = T^-1 A_mu^(g) T   for every grade mask g.

   Decomposing the connection into its 2^k grade components -- each a
   matrix of ordinary RATIONAL functions of (x, y) with eps-dependent
   coefficients -- therefore turns the problem into exactly the rational
   route's problem, on 2 * 2^k matrices instead of 2.  No rational chart,
   no split-point search over the K3 (the "all three q_i simultaneously
   rational squares" locus), and no Together on an expression carrying a
   radical -- the trap this repository has paid for -- is needed
   anywhere: every object the acceptance test sees is a rational
   function.  Sampling the grade components at exact rational (x, y)
   points and running Libra`FactorDependence is the same
   "ExactRationalSamples" strategy as the rational route, per grade
   component.

   ACCEPTANCE is exact and is made in the graded algebra: every grade of
   T^-1 A_mu T is eps-factored identically in (x, y) (Together on a
   rational function is canonical), T T^-1 = 1 exactly, and the composed
   algebraic connection is spot-checked against the direct triple product
   with transportChartAlgebraicZeroQ (the r-symbol reduction of commit
   5a8cf88).  A modular corroboration at fresh primes evaluates the SAME
   conjugated object on all 2^k sign sheets of a split point and checks
   that each sheet is eps-independent; it is recorded as corroboration,
   never as the proof. *)

Clear[FactorFamilyRegulatorDependenceMultiquadratic];
ClearAll[familyRegulatorNonSquareRationalQ, familyRegulatorGradedRoots,
  familyRegulatorGradedRootFrame, familyRegulatorGradedDecompose,
  familyRegulatorGradedFrameEvidence,
  familyRegulatorGradedDecomposeUnchecked, familyRegulatorGradedMatrices,
  familyRegulatorTaggedGradeDecompose, familyRegulatorGradedPointSample,
  familyRegulatorGradedPointSampleTask,
  familyRegulatorGradedPointSampleBatch,
  familyRegulatorGradedDecomposeTask,
  familyRegulatorGradedPointFactoredQ, familyRegulatorModularImage,
  familyRegulatorGradedCorroborate, familyRegulatorGradedSpotCheck,
  familyRegulatorGradedSampleMatrix, $familyRegulatorMaximumGradedRank,
  $familyRegulatorGradedSampleCache, $familyRegulatorGradedSampleCacheLimit];

(* rank 3 declared roots + the square classes of the numeric constants a
   denesting can introduce (CF259 carries Sqrt[2]); the neutral algebra
   is rank-agnostic, the strip module's own ceiling of 3 is an ABI of the
   strip solver and is deliberately not touched here *)
$familyRegulatorMaximumGradedRank = 5;

familyRegulatorNonSquareRationalQ[value_] :=
  MatchQ[value, _Integer | _Rational] && value =!= 0 &&
    ! MatchQ[Sqrt[value], _Integer | _Rational];

(* The graded algebra has one sign bit per independent square class.
   Distinct root squares are not sufficient: {q1,q2,q1 q2} would create
   a fake third generator.  Use the same exact square-class predicate as
   the deferred-bundle and strip root-frame validators, while preserving
   the caller's established root order. *)
familyRegulatorGradedRootFrame[roots_List] := Module[
  {squares, duplicates, dependent},
  If[! AllTrue[roots, AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
      KeyExistsQ[#1, "RootSquare"] &&
      TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[<|"Status" -> "InvalidRootMetadata"|>]];
  squares = Together /@ Lookup[roots, "RootSquare", {}];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[squares[[#1[[1]]]] - squares[[#1[[2]]]]] === 0] &];
  If[duplicates =!= {},
    Return[<|"Status" -> "DuplicateRootSquares",
      "DuplicatePairs" -> duplicates|>]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; TrueQ[multiquadraticStripSquareClassSquareQ[
      Times @@ squares[[subset]]]] :> subset, None];
  If[dependent =!= None,
    Return[<|"Status" -> "DependentRootSquares",
      "RootIndices" -> dependent|>]];
  <|"Status" -> "StableRootFrame", "Roots" -> roots,
    "RootSquares" -> squares|>
];
familyRegulatorGradedRootFrame[___] := <|"Status" -> "InvalidRootMetadata"|>;

(* Persistable, self-authenticating description of the actual graded field.
   The factorizer may extend the chart roots by independent numeric square
   classes, so RootIndices/RootSquares from the chart alone are not enough to
   replay a later whole-family certificate.  The shared canonical root-frame
   builder supplies branch-sensitive fingerprints and a stable ordering; the
   remaining fields bind the exponential grade ABI and its resource ceiling. *)
familyRegulatorGradedFrameEvidence[roots_List,
    variables : {_Symbol, _Symbol}, regulator_Symbol] := Module[
  {frame, numericIndices, semantic},
  If[Length[roots] > $familyRegulatorMaximumGradedRank,
    Return[<|"Status" -> "GradedRankTooLarge", "Rank" -> Length[roots],
      "MaximumRank" -> $familyRegulatorMaximumGradedRank|>]];
  frame = blockEquationDeferredRootFrame[roots, variables, regulator];
  If[Lookup[frame, "Status", None] =!= "StableRootOrder", Return[frame]];
  If[AnyTrue[Lookup[frame["Roots"], "RootSquare", {}],
      ! FreeQ[#1, regulator] &],
    Return[<|"Status" -> "RegulatorDependentRootSquare"|>]];
  numericIndices = Flatten[Position[
    Lookup[frame["Roots"], "RootSquare", {}],
    value_ /; familyRegulatorNonSquareRationalQ[value], {1},
    Heads -> False]];
  semantic = <|
    "Schema" -> "FamilyRegulatorGradedRootFrameV1",
    "Status" -> "StableRootFrame",
    "Roots" -> frame["Roots"],
    "RootCount" -> Length[frame["Roots"]],
    "GradeCount" -> 2^Length[frame["Roots"]],
    "MaximumRank" -> $familyRegulatorMaximumGradedRank,
    "RootFingerprints" -> frame["RootFingerprints"],
    "OrderingFingerprint" -> frame["OrderingFingerprint"],
    "NumericRootIndices" -> numericIndices,
    "NumericRootSquares" ->
      Lookup[frame["Roots"][[numericIndices]], "RootSquare", {}]|>;
  Append[semantic, "FrameFingerprint" -> Hash[KeyTake[semantic,
    {"Schema", "RootCount", "GradeCount", "MaximumRank",
     "RootFingerprints", "OrderingFingerprint", "NumericRootIndices",
     "NumericRootSquares"}], "SHA256", "HexString"]]
];
familyRegulatorGradedFrameEvidence[___] :=
  <|"Status" -> "InvalidRootMetadata"|>;

(* A numeric square class (Sqrt[2] and the like) is a constant of the
   coefficient field, not a function of the chart variables, so the chart
   route may ignore it.  The graded route may NOT: 1/(1 + Sqrt[2]) and
   Sqrt[2] - 1 are the same element and Together does not know it, so the
   eps-factorization test would be decided on a non-canonical form.
   Carrying the class as one more graded generator makes every channel an
   honest rational function over Q and the test canonical. *)
familyRegulatorGradedRoots[usedRoots_List, numericClasses_List] := Module[
  {classes, candidates, frame},
  classes = Select[DeleteDuplicates[Together /@ numericClasses],
    familyRegulatorNonSquareRationalQ];
  candidates = Join[usedRoots,
    Map[<|"Root" -> Sqrt[#], "RootSquare" -> #|> &, classes]];
  frame = familyRegulatorGradedRootFrame[candidates];
  If[Lookup[frame, "Status", None] =!= "StableRootFrame", frame,
    frame["Roots"]]
];

(* multiquadraticFieldDecompose with the strip module's rank-3 ABI
   ceiling lifted (see above).  The exact compose replay is retained for
   audit mode and skipped in Production.  Root symbols are Module locals:
   nothing is interned, nothing survives the call (pool defect 8). *)
familyRegulatorGradedDecomposeUnchecked[expression_, roots_List,
    validateRoundTrip_: True] := Module[
  {rank = Length[roots], symbols, deltas,
   replaced, rational, numerator, denominator, numeratorChannels,
   denominatorChannels, denominatorInverse, channels, reconstructed,
   difference},
  If[rank > $familyRegulatorMaximumGradedRank, Return[$Failed]];
  deltas = Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]];
  If[Length[deltas] =!= rank || ! FreeQ[deltas, $Failed], Return[$Failed]];
  deltas = Together /@ deltas;
  symbols = Table[Unique["FeynFacet`Private`familyRegulatorGradeRoot"],
    {rank}];
  replaced = If[rank === 0, expression,
    transportChartApplyRootBranches[expression, roots, symbols]];
  If[replaced === $Failed, Return[$Failed]];
  (* a radical the declared roots do not account for is not decomposable
     in this field: fail closed, never report a wrong grade-0 channel *)
  If[! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Together[replaced];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  If[rank === 0 || FreeQ[rational, Alternatives @@ symbols],
    channels = PadRight[{rational}, 2^rank, 0],
    numerator = Numerator[rational]; denominator = Denominator[rational];
    If[! PolynomialQ[numerator, symbols] || ! PolynomialQ[denominator, symbols],
      Return[$Failed]];
    numeratorChannels = multiquadraticFromPolynomial[numerator, symbols, deltas];
    denominatorChannels = multiquadraticFromPolynomial[denominator, symbols, deltas];
    If[numeratorChannels === $Failed || denominatorChannels === $Failed,
      Return[$Failed]];
    denominatorInverse = multiquadraticFieldInverse[denominatorChannels, deltas];
    If[denominatorInverse === $Failed, Return[$Failed]];
    channels = Together /@ multiquadraticMultiply[numeratorChannels,
      denominatorInverse, deltas]];
  If[Length[channels] =!= 2^rank, Return[$Failed]];
  If[! TrueQ[validateRoundTrip], Return[channels]];
  reconstructed = multiquadraticToExpression[channels, Lookup[roots, "Root", {}]];
  difference = reconstructed - expression;
  If[! (TrueQ[Together[difference] === 0] ||
        TrueQ[transportChartAlgebraicZeroQ[difference, roots] === True]),
    Return[$Failed]];
  channels
];

(* Production samples kinematics before grade decomposition.  At that point
   the declared radicals have already been replaced by inert generators and
   their squares are exact rationals.  Reducing this small univariate-in-eps
   object is algebraically the same field operation as the symbolic route,
   but it never constructs giant bivariate grade expressions. *)
familyRegulatorTaggedGradeDecompose[expression_, tags_List,
    deltas_List] := Module[
  {rank = Length[tags], reducedDeltas, rational, numerator, denominator,
   numeratorChannels, denominatorChannels, denominatorInverse, channels},
  If[Length[deltas] =!= rank || rank > $familyRegulatorMaximumGradedRank,
    Return[$Failed]];
  reducedDeltas = Together /@ deltas;
  If[! AllTrue[reducedDeltas, MatchQ[#1, _Integer | _Rational] &],
    Return[$Failed]];
  rational = Together[expression];
  If[! FreeQ[rational,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  If[rank === 0 || FreeQ[rational, Alternatives @@ tags],
    Return[PadRight[{rational}, 2^rank, 0]]];
  numerator = Numerator[rational]; denominator = Denominator[rational];
  If[! PolynomialQ[numerator, tags] || ! PolynomialQ[denominator, tags],
    Return[$Failed]];
  numeratorChannels = multiquadraticFromPolynomial[
    numerator, tags, reducedDeltas];
  denominatorChannels = multiquadraticFromPolynomial[
    denominator, tags, reducedDeltas];
  If[numeratorChannels === $Failed || denominatorChannels === $Failed,
    Return[$Failed]];
  denominatorInverse = multiquadraticFieldInverse[
    denominatorChannels, reducedDeltas];
  If[denominatorInverse === $Failed, Return[$Failed]];
  channels = Together /@ multiquadraticMultiply[
    numeratorChannels, denominatorInverse, reducedDeltas];
  If[Length[channels] === 2^rank, channels, $Failed]
];
familyRegulatorTaggedGradeDecompose[___] := $Failed;

familyRegulatorGradedPointSample[connection : {_List, _List}, tags_List,
    rootSquares_List, rule_List] := Module[
  {rank = Length[tags], gradeCount, n, deltas, specialized, channels},
  If[Length[rootSquares] =!= rank || ! MatrixQ[connection[[1]]] ||
      ! MatrixQ[connection[[2]]] ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      Length[connection[[1]]] =!= Length[First[connection[[1]]]],
    Return[$Failed]];
  n = Length[connection[[1]]]; gradeCount = 2^rank;
  deltas = Together /@ (rootSquares /. rule);
  If[! AllTrue[deltas, MatchQ[#1, _Integer | _Rational] &],
    Return[$Failed]];
  If[MemberQ[deltas, 0] || AnyTrue[
      Rest[Subsets[Range[rank]]],
      multiquadraticStripSquareClassSquareQ[
        Times @@ deltas[[#1]]] &],
    Return[$Failed]];
  specialized = connection /. rule;
  channels = Map[
    If[TrueQ[#1 === 0], ConstantArray[0, gradeCount],
      familyRegulatorTaggedGradeDecompose[#1, tags, deltas]] &,
    specialized, {3}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  Flatten[Table[
    Table[channels[[mu, i, j, grade]], {i, n}, {j, n}],
    {mu, 2}, {grade, gradeCount}], 1]
];
familyRegulatorGradedPointSample[___] := $Failed;

familyRegulatorGradedPointSampleTask[payload_Association,
    indices_List] := Module[{rules, samples},
  rules = Lookup[payload, "Rules", $Failed];
  If[! ListQ[rules] || ! VectorQ[indices, IntegerQ] ||
      ! AllTrue[indices, Between[#1, {1, Length[rules]}] &],
    Return[$Failed]];
  samples = familyRegulatorGradedPointSample[
      payload["Connection"], payload["Tags"], payload["RootSquares"],
      #1] & /@ rules[[indices]];
  <|"Indices" -> indices, "Samples" -> samples|>
];
familyRegulatorGradedPointSampleTask[dataFile_String,
    indices_List] := Module[{payload = taskBrokerRead[dataFile]},
  If[AssociationQ[payload],
    familyRegulatorGradedPointSampleTask[payload, indices], $Failed]
];
familyRegulatorGradedPointSampleTask[___] := $Failed;

familyRegulatorGradedPointSampleBatch[connection : {_List, _List},
    tags_List, rootSquares_List, rules_List] := Module[
  {count = Length[rules], free = 0, workerCount, groups, helperGroups,
   localGroup, payload, dataFile, codes, handle, helperResults,
   localResult, results, samples, result, indices, values, missing},
  If[count === 0, Return[{}]];
  If[TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
    free = Quiet[Check[taskBrokerFreeKernels[], 0]]];
  If[! IntegerQ[free] || free < 0, free = 0];
  workerCount = Min[count, free + 1];
  groups = TakeList[Range[count],
    Ceiling[(count - Range[workerCount] + 1)/workerCount]];
  helperGroups = Most[groups]; localGroup = Last[groups];
  payload = <|"Connection" -> connection, "Tags" -> tags,
    "RootSquares" -> rootSquares, "Rules" -> rules|>;
  dataFile = If[helperGroups === {}, None,
    taskBrokerDataFile["frfpoints_" <>
      StringReplace[CreateUUID[], "-" -> ""], payload]];
  If[helperGroups =!= {} && StringQ[dataFile],
    codes = Table[
      "FeynFacet`Private`familyRegulatorGradedPointSampleTask[" <>
        ToString[dataFile, InputForm] <> "," <>
        ToString[group, InputForm] <> "]", {group, helperGroups}];
    handle = taskBrokerSubmit[codes, "Label" -> "frfpoints",
      "Timeout" -> 7200.],
    helperGroups = {}; localGroup = Range[count]; handle = None];
  localResult = familyRegulatorGradedPointSampleTask[payload, localGroup];
  helperResults = If[AssociationQ[handle], taskBrokerCollect[handle], {}];
  results = Join[helperResults, {localResult}];
  samples = ConstantArray[$Failed, count];
  Do[
    result = results[[k]];
    If[AssociationQ[result],
      indices = Lookup[result, "Indices", {}];
      values = Lookup[result, "Samples", {}];
      If[VectorQ[indices, IntegerQ] && Length[indices] === Length[values],
        MapThread[(samples[[#1]] = #2) &, {indices, values}]]],
    {k, Length[results]}];
  missing = Select[Range[count], samples[[#1]] === $Failed &];
  If[missing =!= {},
    result = familyRegulatorGradedPointSampleTask[payload, missing];
    If[AssociationQ[result],
      MapThread[(samples[[#1]] = #2) &,
        {result["Indices"], result["Samples"]}]]];
  samples
];
familyRegulatorGradedPointSampleBatch[___] := $Failed;

familyRegulatorGradedDecompose[expression_, roots_List] := Module[{frame},
  If[Length[roots] > $familyRegulatorMaximumGradedRank, Return[$Failed]];
  frame = familyRegulatorGradedRootFrame[roots];
  If[Lookup[frame, "Status", None] =!= "StableRootFrame", Return[$Failed]];
  familyRegulatorGradedDecomposeUnchecked[expression, frame["Roots"]]
];

(* helper side of the optional brokered decomposition: one task = one
   contiguous slice of the UNIQUE entry expressions.  Roots and
   expressions are written once per call and read once per helper kernel
   (taskBrokerRead memoizes by path and modification time). *)
familyRegulatorGradedDecomposeTask[dataFile_String, indices_List] :=
  Module[{data = taskBrokerRead[dataFile], frame},
    If[! AssociationQ[data], Return[$Failed]];
    frame = familyRegulatorGradedRootFrame[Lookup[data, "Roots", $Failed]];
    If[Lookup[frame, "Status", None] =!= "StableRootFrame",
      Return[$Failed]];
    Function[expression,
      Quiet[Check[familyRegulatorGradedDecomposeUnchecked[expression,
        frame["Roots"], Lookup[data, "ValidateRoundTrip", True]],
        $Failed]]] /@ data["Expressions"][[indices]]];

(* {Ax, Ay} -> the 2 * 2^k grade-component matrices.  A zero entry keeps
   its zero channels without a decomposition call; a failure is reported
   with the offending positions, never absorbed.

   INTERNING (2026-08-25, Codex's 08:30 performance item 1; the stage was
   measured at 134.1 of the 153.9 s the whole CF259 rows-1..23
   factorization took, against 3.1 s for Libra and 0.9 s for the exact
   grade check).  Structurally identical nonzero entries are interned in
   an Association keyed by the expression -- a hash map with SameQ
   collision semantics -- and each UNIQUE expression is decomposed once,
   in first-encounter order.  A connection's entries repeat: the same
   coefficient appears in several rows, and the truncation's zero blocks
   and shared residues make the repetition systematic.

   The unique expressions are immutable independent jobs, so a bounded
   brokered map over them is safe (his explicit condition).  It is taken
   only when the pool has a free helper, the estimated payload clears a
   byte gate, and there is more than one unique expression to give away;
   results come back in the deterministic order of the unique list, a
   task that fails or times out is recomputed locally, and with no free
   helper the loop is exactly the serial one.  Nothing about the
   decomposition itself changes. *)
Options[familyRegulatorGradedMatrices] = {
  "Intern" -> True, "Parallel" -> Automatic, "Helpers" -> Automatic,
  "ValidateRoundTrip" -> True,
  "BatchByteCap" -> Automatic, "BatchDispatcher" -> Automatic,
  "BatchTimeout" -> 3600};

familyRegulatorGradedMatrices[connection : {_List, _List}, roots_List,
    OptionsPattern[]] := Module[
  {rank = Length[roots], gradeCount, n = Length[connection[[1]]], channels,
   failures = {}, decomposed, entry, active, started = AbsoluteTime[],
   internQ, unique = {}, uniqueIndex = <||>, entryIds,
   nonzeroCount = 0, values, helpers = 0, byteCap, dispatcher, parallel,
   batches = {}, bytes, dataFile, codes, handle, farmed, localBatch,
   missing, decomposeLocal, route = "Serial", batchSeconds = 0., frame,
   validateRoundTrip},
  If[rank > $familyRegulatorMaximumGradedRank,
    Return[<|"Status" -> "GradedRankTooLarge", "Rank" -> rank,
      "MaximumRank" -> $familyRegulatorMaximumGradedRank|>]];
  frame = familyRegulatorGradedRootFrame[roots];
  If[Lookup[frame, "Status", None] =!= "StableRootFrame", Return[frame]];
  gradeCount = 2^rank;
  internQ = TrueQ[OptionValue["Intern"]];
  validateRoundTrip = TrueQ[OptionValue["ValidateRoundTrip"]];

  If[! internQ,
    channels = Table[
      entry = connection[[mu, i, j]];
      If[TrueQ[entry === 0], ConstantArray[0, gradeCount],
        nonzeroCount++;
        decomposed = familyRegulatorGradedDecomposeUnchecked[entry, roots,
          validateRoundTrip];
        If[ListQ[decomposed] && Length[decomposed] === gradeCount, decomposed,
          If[Length[failures] < 4, AppendTo[failures, {mu, i, j}]];
          ConstantArray[0, gradeCount]]],
      {mu, 2}, {i, n}, {j, n}],

    (* pass 1: intern the nonzero entries in deterministic position order *)
    entryIds = Table[
      entry = connection[[mu, i, j]];
      If[TrueQ[entry === 0], 0,
        nonzeroCount++;
        If[KeyExistsQ[uniqueIndex, entry], uniqueIndex[entry],
          AppendTo[unique, entry];
          uniqueIndex[entry] = Length[unique]]],
      {mu, 2}, {i, n}, {j, n}];

    (* pass 2: decompose each unique expression once.  The call is NOT
       wrapped in Check here: the per-entry route was not, and a benign
       message must not be read as a failed decomposition.  The helper
       task does wrap it, so a message on a HELPER only sends that
       expression back to this kernel to be decomposed unwrapped. *)
    decomposeLocal[indices_List] := Map[
      Function[index, familyRegulatorGradedDecomposeUnchecked[
        unique[[index]], roots, validateRoundTrip]],
      indices];
    bytes = ByteCount /@ unique;
    byteCap = Replace[OptionValue["BatchByteCap"], Automatic :> 2^28];
    dispatcher = OptionValue["BatchDispatcher"];
    helpers = OptionValue["Helpers"];
    If[helpers === Automatic,
      helpers = If[dispatcher === Automatic,
        If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0], 1]];
    If[! IntegerQ[helpers] || helpers < 0, helpers = 0];
    helpers = Min[helpers, Max[0, Length[unique] - 1]];
    parallel = With[{requestedParallel = OptionValue["Parallel"]},
      Which[
        requestedParallel === Automatic,
          helpers >= 1 && blockEquationDeferredParallelRouteQ[],
        TrueQ[requestedParallel], helpers >= 1,
        True, False]];
    batches = If[unique === {}, {},
      blockEquationDeferredBatchPlan[bytes, helpers + 1, byteCap]];
    values = ConstantArray[$Failed, Length[unique]];
    If[! parallel || Length[batches] <= 1,
      Do[values[[batches[[b]]]] = decomposeLocal[batches[[b]]],
        {b, Length[batches]}],
      route = "Parallel";
      batchSeconds = First[AbsoluteTiming[
        If[dispatcher === Automatic,
          dataFile = taskBrokerDataFile[
            "frfgrade_v2_" <> Hash[{unique, roots, validateRoundTrip},
              "SHA256", "HexString"],
            <|"Expressions" -> unique, "Roots" -> roots,
              "ValidateRoundTrip" -> validateRoundTrip|>];
          codes = StringJoin[
            "FeynFacet`Private`familyRegulatorGradedDecomposeTask[\"",
            dataFile, "\", ", ToString[#, InputForm], "]"] & /@ Most[batches];
          handle = taskBrokerSubmit[codes, "Label" -> "frfgrade",
            "Timeout" -> OptionValue["BatchTimeout"]];
          localBatch = decomposeLocal[Last[batches]];
          farmed = taskBrokerCollect[handle],
          farmed = dispatcher[<|"Expressions" -> unique, "Roots" -> roots,
              "ValidateRoundTrip" -> validateRoundTrip|>,
            Most[batches]];
          localBatch = decomposeLocal[Last[batches]]]]];
      values[[Last[batches]]] = localBatch;
      Do[
        If[ListQ[farmed] && b <= Length[farmed] && ListQ[farmed[[b]]] &&
            Length[farmed[[b]]] === Length[batches[[b]]],
          values[[batches[[b]]]] = farmed[[b]]],
        {b, Length[batches] - 1}];
      missing = Select[Range[Length[unique]],
        ! (ListQ[values[[#]]] && Length[values[[#]]] === gradeCount) &];
      If[missing =!= {}, values[[missing]] = decomposeLocal[missing]]];

    (* pass 3: place the decompositions back, position by position *)
    channels = Table[
      Module[{id = entryIds[[mu, i, j]]},
        If[id === 0, ConstantArray[0, gradeCount],
          decomposed = values[[id]];
          If[ListQ[decomposed] && Length[decomposed] === gradeCount,
            decomposed,
            If[Length[failures] < 4, AppendTo[failures, {mu, i, j}]];
            ConstantArray[0, gradeCount]]]],
      {mu, 2}, {i, n}, {j, n}]];

  If[failures =!= {},
    Return[<|"Status" -> "GradeDecompositionFailed", "Positions" -> failures,
      "Rank" -> rank|>]];
  active = Flatten[Table[
    If[AllTrue[Flatten[channels[[mu, All, All, g]]], TrueQ[# === 0] &],
      Nothing, {mu, g}], {mu, 2}, {g, gradeCount}], 1];
  <|"Status" -> "OK", "Channels" -> channels, "Rank" -> rank,
    "GradeCount" -> gradeCount, "ActiveGrades" -> active,
    "Grades" -> Table[channels[[mu, All, All, g]], {mu, 2}, {g, gradeCount}],
    "Statistics" -> <|"NonzeroEntries" -> nonzeroCount,
      "UniqueEntries" -> If[internQ, Length[unique], nonzeroCount],
      "Interned" -> internQ, "Route" -> route, "Helpers" -> helpers,
      "RoundTripValidated" -> validateRoundTrip,
      "Batches" -> Length[batches], "BatchSeconds" -> batchSeconds,
      "DecomposeSeconds" -> N[AbsoluteTime[] - started]|>|>
];

(* Sampling a grade component at a rational chart point.  The channels
   come out of the decomposition already Together-normalized, so a zero
   entry needs no work at all -- and a grade component of a real
   connection is very sparse (CF259 rows 1..23: 336 nonzero entries of
   1681, spread over 16 grades).  Skipping the zeros is what keeps the
   ladder affordable at 2 * 2^k matrices per point instead of 2.

   MEMOIZED per (grade component, point) since 2026-08-25 (Codex 08:30
   performance item 1, second half).  The point ladder {1, 2, 4, 8}
   rebuilds every prefix: at 8 points it samples 1 + 2 + 4 + 8 = 15
   point-sets where 8 distinct ones exist.  The key is a SHA-256
   fingerprint of the component, the point and the regulator symbol with
   its context -- the same fingerprint discipline the artifact ABIs of
   this repository use -- and the cache stores only the SAMPLED matrix,
   which is a matrix of rational functions of the regulator alone and far
   smaller than the two-variable component; keeping the component itself
   would pin the whole grade decomposition of every family a persistent
   pool subkernel has served.  The pool is bounded for the same reason. *)
$familyRegulatorGradedSampleCache = <||>;
$familyRegulatorGradedSampleCacheLimit = 128;

familyRegulatorGradedSampleMatrix[matrix_List, rule_List, epsilon_Symbol] :=
  Module[{key, hit, sampled},
    key = Hash[{matrix, rule, Context[epsilon], SymbolName[epsilon]},
      "SHA256", "HexString"];
    hit = Lookup[$familyRegulatorGradedSampleCache, Key[key], None];
    If[hit =!= None, Return[hit]];
    sampled = Map[Function[entry,
      If[TrueQ[entry === 0], 0, Together[(entry /. rule)/epsilon]]],
      matrix, {2}];
    If[Length[$familyRegulatorGradedSampleCache] >=
        $familyRegulatorGradedSampleCacheLimit,
      $familyRegulatorGradedSampleCache = Take[
        $familyRegulatorGradedSampleCache,
        -Quotient[$familyRegulatorGradedSampleCacheLimit, 2]]];
    $familyRegulatorGradedSampleCache[key] = sampled;
    sampled];

(* the rational route's cheap point gate, per grade component *)
familyRegulatorGradedPointFactoredQ[inverse_List, gradeMatrices_List,
    candidate_List, rules_List, epsilon_Symbol] :=
  AllTrue[rules, Function[r,
    AllTrue[gradeMatrices, Function[matrix, Module[{sampled},
      sampled = Map[Function[entry,
        If[TrueQ[entry === 0], 0, Together[entry /. r]]], matrix, {2}];
      If[! FreeQ[sampled, Indeterminate | ComplexInfinity | DirectedInfinity[_]],
        True,
        familyRegulatorFactoredQ[
          familyRegulatorConjugate[inverse, sampled, candidate], epsilon]]]]]]];

familyRegulatorModularImage[expression_, rules_List, prime_Integer] := Module[
  {value = Quiet[expression /. rules]},
  If[! (IntegerQ[value] || Head[value] === Rational),
    value = Quiet[Together[value]]];
  If[! (IntegerQ[value] || Head[value] === Rational), Return[$Failed]];
  multiquadraticStripModRational[value, prime]
];

(* Sign-sheet corroboration at FRESH primes.  At a split point every
   declared square is a nonzero quadratic residue, so each of the 2^k
   embeddings r_i -> +-sqrt(q_i) sends the graded connection to an
   ordinary matrix over F_p.  Conjugating that matrix by T at two
   regulator values and comparing is a necessary condition for the
   eps-factorization, on every sheet at once; it corroborates the exact
   grade-wise statement and independently exercises the algebra ABI
   (decompose/compose, the Hadamard character table).  It is never the
   proof: the exact statement is the grade-wise Together identity. *)
familyRegulatorGradedCorroborate[gradeMatrices_List, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, candidate_List,
    inverse_List, primeCount_Integer] := Module[
  {rank = Length[roots], gradeCount, n = Length[candidate], deltas, primes,
   records = {}, hadamard, masks, prime, point, deltaValues, rootValues,
   rootProducts, epsilonValues, conjugatedByValue, sheetVerdicts,
   gradeVerdicts, ok = True, seed = 0, tries, x0, y0, matrices, tMatrix,
   tInverse, image, identityOK, sheets},
  deltas = Together /@ Lookup[roots, "RootSquare", ConstantArray[$Failed, rank]];
  If[! FreeQ[deltas, $Failed], Return[<|"Status" -> "CorroborationRootsInvalid"|>]];
  gradeCount = 2^rank;
  masks = multiquadraticBasisMasks[rank];
  hadamard = multiquadraticHadamardMatrix[rank];
  (* fresh primes: p = 3 (mod 4) so that multiquadraticSquareRoots
     applies, taken from a window the strip solver's own schedules do not
     use, and DISTINCT -- NextPrime over a coarse grid returns the same
     prime twice and two identical primes are one corroboration, not two *)
  (* the local must NOT be named after a pattern variable of this
     definition: the pattern is substituted into the body BEFORE Module
     scopes anything, and the loop then never runs (measured 2026-08-25:
     "Primes" came back as an unevaluated Module and the corroboration
     reported "Corroborated" on an EMPTY record list) *)
  primes = Module[{probe = 7 10^8, found = {}},
    While[Length[found] < primeCount && probe < 7 10^8 + 10^6,
      probe = NextPrime[probe];
      If[Mod[probe, 4] === 3, AppendTo[found, probe]]];
    found];
  If[! VectorQ[primes, PrimeQ] ||
      Length[DeleteDuplicates[primes]] < primeCount,
    Return[<|"Status" -> "CorroborationPrimesUnavailable",
      "Primes" -> primes|>]];
  BlockRandom[SeedRandom[20260825];
  Do[
    point = None;
    Do[
      x0 = RandomInteger[{2, prime - 2}]; y0 = RandomInteger[{2, prime - 2}];
      (* Codex 0830 P2: a root SQUARE need not be a polynomial.  Raw Mod
         leaves a rational value a Rational, so VectorQ[..., IntegerQ]
         rejected every otherwise valid split point of a strip whose
         q_i is e.g. (1 + x)/(1 - y).  The modular-rational image
         utility is the same one the rest of the module uses: it turns
         numerator/denominator into numerator times the inverse
         denominator over F_p and fails closed (as $Failed) when the
         denominator vanishes mod p, which the split-point loop then
         retries at another point. *)
      deltaValues = Quiet[familyRegulatorModularImage[#1,
        Thread[variables -> {x0, y0}], prime] & /@ deltas];
      If[VectorQ[deltaValues, IntegerQ] &&
          AllTrue[deltaValues, #1 =!= 0 && JacobiSymbol[#1, prime] === 1 &],
        point = {x0, y0}; Break[]],
      {tries, 400}];
    If[point === None,
      AppendTo[records, <|"Prime" -> prime, "Status" -> "NoSplitPointFound"|>];
      ok = False; Continue[]];
    rootValues = multiquadraticSquareRoots[deltaValues, prime];
    If[! VectorQ[rootValues, IntegerQ],
      AppendTo[records, <|"Prime" -> prime, "Status" -> "SquareRootFailed"|>];
      ok = False; Continue[]];
    rootProducts = Mod[multiquadraticMaskFactor[#1, rootValues] & /@ masks, prime];
    epsilonValues = {RandomInteger[{2, prime - 2}], RandomInteger[{2, prime - 2}]};
    If[SameQ @@ epsilonValues,
      epsilonValues[[2]] = If[epsilonValues[[2]] === prime - 2,
        epsilonValues[[2]] - 1, epsilonValues[[2]] + 1]];
    conjugatedByValue = Table[
      Module[{rules = Thread[Append[variables, epsilon] ->
          Append[point, epsilonValue]], t, ti, gradeImages},
        t = Map[familyRegulatorModularImage[#1, rules, prime] &, candidate, {2}];
        ti = Map[familyRegulatorModularImage[#1, rules, prime] &, inverse, {2}];
        If[! (MatrixQ[t, IntegerQ] && MatrixQ[ti, IntegerQ]),
          Return[$Failed, Module]];
        identityOK = Mod[t . ti, prime] === IdentityMatrix[n];
        If[! identityOK, Return[$Failed, Module]];
        gradeImages = Table[
          image = Map[familyRegulatorModularImage[#1, rules, prime] &,
            gradeMatrices[[mu, g]], {2}];
          If[! MatrixQ[image, IntegerQ], Return[$Failed, Module]];
          (* the sampled object is A/eps, exactly as the linear solve saw it *)
          Mod[ti . Mod[image PowerMod[epsilonValue, -1, prime], prime] . t, prime],
          {mu, 2}, {g, gradeCount}];
        gradeImages],
      {epsilonValue, epsilonValues}];
    If[! FreeQ[conjugatedByValue, $Failed] ||
        ! ArrayQ[conjugatedByValue, 5, IntegerQ],
      AppendTo[records, <|"Prime" -> prime, "Point" -> point,
        "Status" -> "ModularEvaluationFailed"|>];
      ok = False; Continue[]];
    gradeVerdicts = Table[
      conjugatedByValue[[1, mu, g]] === conjugatedByValue[[2, mu, g]],
      {mu, 2}, {g, gradeCount}];
    sheets = Table[
      Mod[Sum[hadamard[[sheet + 1, g]] rootProducts[[g]]
          conjugatedByValue[[value, mu, g]], {g, gradeCount}], prime],
      {value, 2}, {mu, 2}, {sheet, 0, gradeCount - 1}];
    sheetVerdicts = Table[sheets[[1, mu, sheet]] === sheets[[2, mu, sheet]],
      {mu, 2}, {sheet, gradeCount}];
    ok = ok && And @@ Flatten[gradeVerdicts] && And @@ Flatten[sheetVerdicts];
    AppendTo[records, <|"Prime" -> prime, "Point" -> point,
      "RootValues" -> rootValues, "RegulatorValues" -> epsilonValues,
      "Status" -> "OK", "InverseIdentity" -> True,
      "GradeEpsilonIndependent" -> And @@ Flatten[gradeVerdicts],
      "SheetCount" -> gradeCount,
      "SheetsEpsilonIndependent" -> Flatten[sheetVerdicts],
      "AllSheetsAgree" -> And @@ Flatten[sheetVerdicts]|>],
    {prime, primes}]];
  (* an EMPTY record list is not a corroboration: AllTrue[{}, ...] is
     True and would report a vacuous verdict as evidence *)
  ok = TrueQ[ok] && Length[records] === Length[primes] &&
    AllTrue[records, Lookup[#1, "Status", None] === "OK" &];
  <|"Status" -> If[ok, "Corroborated", "NotCorroborated"],
    "Corroborated" -> ok, "Primes" -> primes,
    "RecordCount" -> Length[records], "Records" -> records|>
];

(* The composed algebraic connection must be the direct triple product.
   The full n x n product on entries that carry radicals is the cost the
   grade route exists to avoid, so a bounded number of entries is checked
   -- exactly, with the r-symbol reduction, not with Together. *)
familyRegulatorGradedSpotCheck[inverse_List, sourceMatrices : {_List, _List},
    transformation_List, composed : {_List, _List}, roots_List,
    count_Integer, timeLimit_: 120] := Module[
  {n = Length[transformation], candidates, positions, verdicts, decided,
   direct, mu, i, j},
  If[count <= 0,
    Return[<|"Checked" -> 0, "Total" -> 2 n^2, "Verdicts" -> {},
      "Undecided" -> 0, "Zero" -> True|>]];
  candidates = BlockRandom[SeedRandom[20260825];
    DeleteDuplicates[Table[
      {RandomInteger[{1, 2}], RandomInteger[{1, n}], RandomInteger[{1, n}]},
      {8 count}]]];
  (* an entry that is zero on both sides carries no information *)
  positions = Take[DeleteDuplicates[Join[
    Select[candidates, ! TrueQ[composed[[#1[[1]], #1[[2]], #1[[3]]]] === 0] &],
    candidates]], UpTo[count]];
  verdicts = Table[
    {mu, i, j} = position;
    TimeConstrained[
      direct = Sum[
        inverse[[i, a]] sourceMatrices[[mu, a, b]] transformation[[b, j]],
        {a, n}, {b, n}];
      transportChartAlgebraicZeroQ[direct - composed[[mu, i, j]], roots] === True,
      timeLimit, Missing["SpotCheckTimedOut"]],
    {position, positions}];
  decided = DeleteCases[verdicts, _Missing];
  (* An undecided entry is reported, never counted as evidence; a DECIDED
     nonzero difference is a refusal.  "Zero" is the evidence, "Refuted"
     is the refusal criterion -- they are not each other's negation when
     nothing could be decided. *)
  <|"Checked" -> Length[decided], "Total" -> 2 n^2,
    "Positions" -> positions, "Verdicts" -> verdicts,
    "Undecided" -> Count[verdicts, _Missing],
    "Refuted" -> MemberQ[decided, False],
    "Zero" -> (decided =!= {} && And @@ decided)|>
];

FactorFamilyRegulatorDependenceMultiquadratic::input =
  "The connection must be a pair of equally sized square matrices.";

Options[FactorFamilyRegulatorDependenceMultiquadratic] = {
  "TimeLimit" -> 900,
  "Deadline" -> Infinity,
  "InputResiduesEpsFree" -> Automatic,
  "ValidationMode" -> "Exact",
  "UseFermat" -> Automatic,
  "PointLadder" -> {1, 2, 4, 8},
  "GatePoints" -> 2,
  "ExactCheckTimeLimit" -> Automatic,
  "CorroborationPrimes" -> 2,
  "RoundTripSpotChecks" -> 3,
  "SpotCheckTimeLimit" -> 120,
  "Verbose" -> False
};

FactorFamilyRegulatorDependenceMultiquadratic[{ax_List, ay_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    OptionsPattern[]] := Module[
  {n, start = AbsoluteTime[], verbose, log, rank, gradeCount, decomposition,
   grades, activeGrades, activeMatrices, rules, valid, denominators, backend,
   reference, fermatRequested, transformation = $Failed, inverse, attempts = {},
   pointsUsed = 0, exactLimit, conjugated, factoredQ, inverseQ, newAx, newAy,
   spot, corroboration, exactSeconds, gradeFailure = None,
   deadline, expired = False, ladderLimit, decompositionSeconds,
   numericGradeCount = 0, skippedStages = {}, rootFrame,
   gradedFrameEvidence, validationMode, deferAcceptanceQ,
   evaluated, rootTags, taggedConnection, rootSquares,
   sourceConjugationSeconds = 0.},
  If[! (MatrixQ[ax] && MatrixQ[ay] && Dimensions[ax] === Dimensions[ay] &&
      Length[ax] === Length[First[ax]]),
    Message[FactorFamilyRegulatorDependenceMultiquadratic::input];
    Return[$Failed]];
  n = Length[ax];
  rank = Length[roots];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[multiquadratic-regulator-factor] ", args]];
  deadline = OptionValue["Deadline"];
  validationMode = OptionValue["ValidationMode"];
  deferAcceptanceQ = validationMode === "DeferredToFamilyCertificate";
  (* the numeric square classes of the graded generator list.  A root
     whose square is a plain non-square rational is a CONSTANT of the
     coefficient field: the completeness caveat of Codex 0830 P2 is
     about exactly these, and a refusal has to say so. *)
  numericGradeCount = Count[Lookup[roots, "RootSquare", {}],
    value_ /; familyRegulatorNonSquareRationalQ[value]];
  If[rank > $familyRegulatorMaximumGradedRank,
    Return[<|"Status" -> "GradedRankTooLarge", "Rank" -> rank,
      "MaximumRank" -> $familyRegulatorMaximumGradedRank,
      "Seconds" -> AbsoluteTime[] - start|>]];
  rootFrame = familyRegulatorGradedRootFrame[roots];
  If[Lookup[rootFrame, "Status", None] =!= "StableRootFrame",
    Return[Join[rootFrame, <|"Module" -> "FamilyRegulatorFactor",
      "Rank" -> rank, "Seconds" -> AbsoluteTime[] - start|>]]];
  gradedFrameEvidence = familyRegulatorGradedFrameEvidence[
    roots, variables, epsilon];
  If[Lookup[gradedFrameEvidence, "Status", None] =!= "StableRootFrame",
    Return[Join[gradedFrameEvidence,
      <|"Module" -> "FamilyRegulatorFactor", "Rank" -> rank,
        "Seconds" -> AbsoluteTime[] - start|>]]];
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["Entry", deadline, start,
      <|"Rank" -> rank|>]]];
  gradeCount = 2^rank;

  (* Production needs T(eps), not symbolic bivariate grade matrices.  Tag
     the roots while their square classes are still distinct, specialize
     (x,y) exactly, and only then reduce the resulting small algebra over
     Q(eps).  Held-out exact rational points select the candidate; the final
     family certificate remains the acceptance boundary.  Development keeps
     the full symbolic grade path below. *)
  If[deferAcceptanceQ,
    log["sampling kinematics before grade decomposition (", gradeCount,
      " grades)"];
    rootTags = Table[
      Unique["FeynFacet`Private`familyRegulatorSampleRoot"], {rank}];
    taggedConnection = Map[
      transportChartApplyRootBranches[#1, roots, rootTags] &,
      {ax, ay}];
    rootSquares = Lookup[roots, "RootSquare", {}];
    evaluated = familyRegulatorFactorFromPointEvaluator[
      Function[{pointRules}, familyRegulatorGradedPointSample[
        taggedConnection, rootTags, rootSquares, pointRules]],
      n, variables, epsilon,
      "BatchEvaluator" -> Function[{pointRuleBatch},
        familyRegulatorGradedPointSampleBatch[
          taggedConnection, rootTags, rootSquares, pointRuleBatch]],
      "TimeLimit" -> OptionValue["TimeLimit"],
      "Deadline" -> deadline,
      "InputResiduesEpsFree" -> OptionValue["InputResiduesEpsFree"],
      "ValidationMode" -> validationMode,
      "UseFermat" -> OptionValue["UseFermat"],
      "PointLadder" -> OptionValue["PointLadder"],
      "GatePoints" -> OptionValue["GatePoints"],
      "Verbose" -> verbose];
    If[AssociationQ[evaluated] && evaluated["Status"] === "OK",
      transformation = evaluated["Transformation"];
      inverse = evaluated["Inverse"];
      If[! FreeQ[{transformation, inverse}, Alternatives @@ variables],
        Return[<|"Status" -> "TransformationNotConstant", "Rank" -> rank,
          "Attempts" -> evaluated["Attempts"],
          "Seconds" -> AbsoluteTime[] - start|>]];
      {sourceConjugationSeconds, {newAx, newAy}} = AbsoluteTiming[{
        familyRegulatorConjugateDeferred[inverse, ax, transformation],
        familyRegulatorConjugateDeferred[inverse, ay, transformation]}];
      log["sample-first factorization and deferred source conjugation completed; ",
        "source conjugation ", Round[sourceConjugationSeconds, 0.1],
        " s; acceptance deferred to family certificate"];
      Return[<|"Status" -> "OK",
        "Method" -> "MultiquadraticEvaluatedGradeSamples",
        "DeadlineSkippedStages" -> {},
        "GradeDecompositionSeconds" ->
          Missing["SpecializedBeforeDecomposition"],
        "GradeDecompositionStatistics" -> <|
          "Route" -> "EvaluatedPoints", "Interned" -> False,
          "RoundTripValidated" -> False|>,
        "Points" -> evaluated["Points"], "Rank" -> rank,
        "GradeCount" -> gradeCount,
        "ActiveGrades" -> Missing["PointwiseGrades"],
        "GradedRootFrame" -> gradedFrameEvidence,
        "Transformation" -> transformation, "Inverse" -> inverse,
        "Connection" -> {newAx, newAy},
        "Attempts" -> evaluated["Attempts"],
        "ValidationMode" -> validationMode,
        "ExactEpsFactorization" -> Missing["DeferredToFamilyCertificate"],
        "ExactInverse" -> Missing["DeferredToFamilyCertificate"],
        "GradeConjugationSeconds" -> sourceConjugationSeconds,
        "ExactCheckSeconds" -> Missing["NotRun"],
        "CompositionSpotCheck" -> Missing["DeferredToFamilyCertificate"],
        "ModularCorroboration" -> Missing["DeferredToFamilyCertificate"],
        "UseFermat" -> evaluated["UseFermat"],
        "PropagationSeal" -> Missing["DeferredToFamilyCertificate"],
        "Seconds" -> AbsoluteTime[] - start|>]];
    log["sample-first route returned ",
      If[AssociationQ[evaluated], Lookup[evaluated, "Status", "Unknown"],
        Head[evaluated]], "; using the symbolic grade fallback"]];

  log["grade decomposition of a ", n, "x", n, " connection at rank ", rank,
    " (", gradeCount, " grades)"];
  (* the decomposition is the measured 87% of this stage (CF259 rows
     1..23: 134.1 s of 153.9 s), so it is the one subcall that MUST be
     capped by the remaining time rather than run to completion *)
  {decompositionSeconds, decomposition} = AbsoluteTiming[
    TimeConstrained[familyRegulatorGradedMatrices[{ax, ay}, roots,
        "ValidateRoundTrip" -> ! deferAcceptanceQ],
      familyRegulatorBoundedLimit[Infinity, deadline], "TimedOut"]];
  If[decomposition === "TimedOut" || familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["GradeDecomposition", deadline, start,
      <|"Rank" -> rank, "GradeCount" -> gradeCount,
        "GradeDecompositionSeconds" -> decompositionSeconds|>]]];
  If[Lookup[decomposition, "Status", None] =!= "OK",
    Return[Join[decomposition,
      <|"GradeDecompositionSeconds" -> decompositionSeconds,
        "Seconds" -> AbsoluteTime[] - start|>]]];
  grades = decomposition["Grades"];
  activeGrades = decomposition["ActiveGrades"];
  activeMatrices = grades[[#1[[1]], #1[[2]]]] & /@ activeGrades;
  log[Length[activeGrades], " active grade components of ", 2 gradeCount];
  If[activeMatrices === {} ||
      (OptionValue["InputResiduesEpsFree"] =!= False &&
        AllTrue[activeMatrices, familyRegulatorFactoredQ[#1, epsilon] &]),
    log["every grade component is already eps-factored"];
    Return[<|"Status" -> "AlreadyEpsFactored", "Method" -> "MultiquadraticGrades",
      "Transformation" -> IdentityMatrix[n], "Inverse" -> IdentityMatrix[n],
      "Connection" -> {ax, ay}, "Rank" -> rank, "GradeCount" -> gradeCount,
      "ActiveGrades" -> activeGrades,
      "GradedRootFrame" -> gradedFrameEvidence,
      "Seconds" -> AbsoluteTime[] - start|>]];
  (* every grade component is an ORDINARY rational function: the sampled
     matrices are rational in the regulator and Fermat is admissible even
     though the source connection carries radicals *)
  rules = Table[{variables[[1]] -> Prime[k + 3]/Prime[k + 11],
    variables[[2]] -> Prime[2 k + 5]/Prime[2 k + 15]}, {k, 1, 24}];
  (* a point is admissible iff no channel denominator vanishes there; the
     channels are Together-normalized, so the DISTINCT denominators (a
     handful) decide, not every one of the 2 * 2^k * n^2 entries *)
  denominators = DeleteDuplicates[Denominator /@
    DeleteCases[Flatten[activeMatrices], entry_ /; TrueQ[entry === 0]]];
  valid = Select[rules, Function[r, AllTrue[denominators,
    Module[{value = Together[#1 /. r]},
      ! TrueQ[value === 0] &&
        FreeQ[value, Indeterminate | ComplexInfinity | DirectedInfinity[_]]] &]]];
  log[Length[valid], " admissible rational sample points (",
    Length[denominators], " distinct channel denominators)"];
  If[valid === {},
    Return[<|"Status" -> "NoAdmissibleSamplePoint", "Rank" -> rank,
      "Seconds" -> AbsoluteTime[] - start|>]];
  fermatRequested = OptionValue["UseFermat"];
  backend = libraEpsFormLoadBackend[fermatRequested];
  If[backend["Status"] =!= "OK",
    Return[<|"Status" -> backend["Status"], "Rank" -> rank|>]];
  reference = Unique["regulatorReference"];
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["SamplePoints", deadline, start,
      <|"Rank" -> rank,
        "GradeDecompositionSeconds" -> decompositionSeconds|>]]];
  Do[
    If[count > Length[valid], Break[]];
    ladderLimit = familyRegulatorBoundedLimit[OptionValue["TimeLimit"], deadline];
    If[familyRegulatorDeadlineExpiredQ[deadline] ||
        (NumericQ[ladderLimit] && ladderLimit <= 0),
      expired = True; Break[]];
    Module[{matrices, result, candidate, ok = False, gate = False, seconds},
      matrices = DeleteCases[
        Flatten[Table[familyRegulatorGradedSampleMatrix[activeMatrices[[a]],
          valid[[k]], epsilon], {k, count}, {a, Length[activeMatrices]}], 1],
        matrix_ /; AllTrue[Flatten[matrix], TrueQ[#1 === 0] &]];
      log["FactorDependence on ", Length[matrices], " sampled grade matrices (",
        count, " points)"];
      {seconds, result} = AbsoluteTiming[Quiet[TimeConstrained[
        Libra`FactorDependence[matrices, epsilon, reference,
          DependentRowIndices -> Automatic, Sort -> True],
        ladderLimit, "TimedOut"]]];
      candidate = If[MatrixQ[result],
        familyRegulatorSpecialize[result, reference, n], $Failed];
      If[MatrixQ[candidate],
        inverse = Map[Together, Inverse[candidate], {2}];
        gate = familyRegulatorGradedPointFactoredQ[inverse, activeMatrices,
          candidate, Take[Reverse[valid], UpTo[OptionValue["GatePoints"]]], epsilon];
        If[gate, transformation = candidate; pointsUsed = count; ok = True]];
      AppendTo[attempts, <|"Points" -> count, "Seconds" -> seconds,
        "SampledMatrices" -> Length[matrices], "PointGate" -> gate,
        "Result" -> If[result === "TimedOut", "TimedOut",
          If[MatrixQ[result], "Matrix", Head[result]]]|>];
      log[count, " points: ", Round[seconds, 0.1], " s, point gate ", gate]];
    If[MatrixQ[transformation], Break[]],
    {count, OptionValue["PointLadder"]}];
  If[! MatrixQ[transformation],
    If[TrueQ[expired],
      Return[familyRegulatorDeadlineStop["PointLadder", deadline, start,
        <|"Rank" -> rank, "GradeCount" -> gradeCount,
          "ActiveGrades" -> activeGrades, "Attempts" -> attempts,
          "GradeDecompositionSeconds" -> decompositionSeconds|>]]];
    (* Codex 0830 P2 -- THE COMPLETENESS CAVEAT, made typed.
       This solve feeds ORDINARY RATIONAL grade matrices to Libra and
       therefore admits only a T with entries in Q(eps): the grade-zero
       argument ("a constant T lies in grade zero") is sound for the
       non-isotrivial roots, whose squares depend on the chart variables,
       but NOT for the numeric square classes the same routine adds as
       graded generators.  A perfectly valid constant transformation may
       carry Sqrt[2] eps off-diagonally: it is constant in {x, y} and yet
       has nonzero numeric-root grade, so this route can miss it.  When
       numeric classes are present the refusal is therefore narrowed --
       "no RATIONAL-grade-zero T was found over the declared constant
       field", not "no constant T exists" -- and says which generators
       carry the restriction.  A completeness fix is to split
       variable-dependent root grades from constant number-field grades
       (preserve the former under conjugation, let T live in the latter),
       or to run FactorDependence over a rational regular representation
       of the constant number field. *)
    If[numericGradeCount > 0,
      Return[<|"Status" -> "ConstantFieldRestriction",
        "Module" -> "FamilyRegulatorFactor",
        "Method" -> "MultiquadraticGradedSamples",
        "Reason" -> "no rational grade-zero transformation was found; \
this solver admits T over Q(eps) only, while the declared constant field \
carries numeric square classes in which a valid constant T may live",
        "NumericGradeGenerators" -> Select[Lookup[roots, "RootSquare", {}],
          familyRegulatorNonSquareRationalQ],
        "NumericGradeGeneratorCount" -> numericGradeCount,
        "Complete" -> False, "Rank" -> rank, "GradeCount" -> gradeCount,
        "ActiveGrades" -> activeGrades, "Attempts" -> attempts,
        "GradeDecompositionSeconds" -> decompositionSeconds,
        "Seconds" -> AbsoluteTime[] - start|>]];
    Return[<|"Status" -> "NotFactored", "Method" -> "MultiquadraticGradedSamples",
      "Rank" -> rank, "GradeCount" -> gradeCount,
      "ActiveGrades" -> activeGrades, "Attempts" -> attempts,
      "GradeDecompositionSeconds" -> decompositionSeconds,
      "Seconds" -> AbsoluteTime[] - start|>]];
  If[! FreeQ[{transformation, inverse}, Alternatives @@ variables],
    Return[<|"Status" -> "TransformationNotConstant", "Rank" -> rank,
      "Attempts" -> attempts, "Seconds" -> AbsoluteTime[] - start|>]];
  (* Conjugation and grade composition construct the transformed source
     connection.  Development also performs the exact intermediate audit;
     Production leaves acceptance to the one final family certificate. *)
  exactLimit = familyRegulatorBoundedLimit[
    Replace[OptionValue["ExactCheckTimeLimit"],
      Automatic :> OptionValue["TimeLimit"]], deadline];
  If[familyRegulatorDeadlineExpiredQ[deadline] ||
      (NumericQ[exactLimit] && exactLimit <= 0),
    Return[familyRegulatorDeadlineStop[
      If[deferAcceptanceQ, "GradeConjugation", "ExactGradeCheck"],
      deadline, start,
      <|"Rank" -> rank, "GradeCount" -> gradeCount,
        "ActiveGrades" -> activeGrades, "Attempts" -> attempts,
        "GradeDecompositionSeconds" -> decompositionSeconds|>]]];
  conjugated = Table[ConstantArray[0, {n, n}], {mu, 2}, {g, gradeCount}];
  exactSeconds = First[AbsoluteTiming[
    factoredQ = TimeConstrained[
      Catch[Do[
        Module[{mu = activeGrades[[a, 1]], g = activeGrades[[a, 2]], image},
          image = familyRegulatorConjugate[inverse, activeMatrices[[a]], transformation];
          conjugated[[mu, g]] = image;
          If[! deferAcceptanceQ && ! familyRegulatorFactoredQ[image, epsilon],
            gradeFailure = {mu, g - 1};
            Throw[False, "FeynFacetGradedEpsFactor"]]],
        {a, Length[activeGrades]}]; True, "FeynFacetGradedEpsFactor"],
      exactLimit, "TimedOut"]]];
  If[factoredQ === "TimedOut",
    Return[<|"Status" -> If[deferAcceptanceQ,
        "GradeConjugationTimedOut", "ExactGradeCheckTimedOut"], "Rank" -> rank,
      "GradeCount" -> gradeCount, "ActiveGrades" -> activeGrades,
      "ExactCheckTimeLimit" -> exactLimit, "Attempts" -> attempts,
      "Seconds" -> AbsoluteTime[] - start|>]];
  If[! deferAcceptanceQ && ! TrueQ[factoredQ],
    Return[<|"Status" -> "GradeNotEpsFactored", "Rank" -> rank,
      "FailingGrade" -> gradeFailure, "ActiveGrades" -> activeGrades,
      "Attempts" -> attempts, "Seconds" -> AbsoluteTime[] - start|>]];
  inverseQ = If[deferAcceptanceQ,
    Missing["DeferredToFamilyCertificate"],
    AllTrue[Flatten[Map[Together,
      {transformation . inverse - IdentityMatrix[n],
       inverse . transformation - IdentityMatrix[n]}, {3}]], TrueQ[#1 === 0] &]];
  If[! deferAcceptanceQ && ! inverseQ,
    Return[<|"Status" -> "TransformationInverseInvalid", "Rank" -> rank,
      "Attempts" -> attempts, "Seconds" -> AbsoluteTime[] - start|>]];
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["GradeComposition", deadline, start,
      <|"Rank" -> rank, "GradeCount" -> gradeCount,
        "ActiveGrades" -> activeGrades, "Attempts" -> attempts,
        "ExactEpsFactorization" -> If[deferAcceptanceQ,
          Missing["DeferredToFamilyCertificate"], True],
        "GradeDecompositionSeconds" -> decompositionSeconds,
        "ExactCheckSeconds" -> exactSeconds|>]]];
  newAx = Table[multiquadraticFieldCompose[
    Table[conjugated[[1, g, i, j]], {g, gradeCount}], roots], {i, n}, {j, n}];
  newAy = Table[multiquadraticFieldCompose[
    Table[conjugated[[2, g, i, j]], {g, gradeCount}], roots], {i, n}, {j, n}];
  If[! FreeQ[{newAx, newAy}, $Failed],
    Return[<|"Status" -> "GradeCompositionFailed", "Rank" -> rank,
      "Seconds" -> AbsoluteTime[] - start|>]];
  spot = If[deferAcceptanceQ,
    Missing["DeferredToFamilyCertificate"],
    If[familyRegulatorDeadlineExpiredQ[deadline],
      AppendTo[skippedStages, "CompositionSpotCheck"];
      <|"Checked" -> 0, "Total" -> 2 n^2, "Verdicts" -> {}, "Undecided" -> 0,
        "Refuted" -> False, "Zero" -> Missing["SpotCheckSkippedDeadline"],
        "Skipped" -> "Deadline"|>,
      familyRegulatorGradedSpotCheck[inverse, {ax, ay}, transformation,
        {newAx, newAy}, roots, OptionValue["RoundTripSpotChecks"],
        familyRegulatorBoundedLimit[OptionValue["SpotCheckTimeLimit"],
          deadline]]]];
  If[! deferAcceptanceQ && TrueQ[spot["Refuted"]],
    Return[<|"Status" -> "CompositionRoundTripFailed", "Rank" -> rank,
      "SpotCheck" -> spot, "Seconds" -> AbsoluteTime[] - start|>]];
  corroboration = If[deferAcceptanceQ,
    Missing["DeferredToFamilyCertificate"],
    If[familyRegulatorDeadlineExpiredQ[deadline],
      AppendTo[skippedStages, "ModularCorroboration"];
      <|"Status" -> "CorroborationSkippedDeadline", "Corroborated" -> False,
        "Primes" -> {}, "RecordCount" -> 0, "Records" -> {},
        "Skipped" -> "Deadline"|>,
      familyRegulatorGradedCorroborate[grades, roots, variables,
        epsilon, transformation, inverse, OptionValue["CorroborationPrimes"]]]];
  log[If[deferAcceptanceQ,
      "grade conjugation completed in ",
      "exact grade-wise eps-factorization verified in "],
    Round[exactSeconds, 0.1], " s",
    If[deferAcceptanceQ, "; acceptance deferred to family certificate",
      "; modular corroboration " <>
        ToString[Lookup[corroboration, "Status", corroboration]]]];
  <|"Status" -> "OK", "Method" -> "MultiquadraticGradedSamples",
    "DeadlineSkippedStages" -> skippedStages,
    "GradeDecompositionSeconds" -> decompositionSeconds,
    "GradeDecompositionStatistics" -> decomposition["Statistics"],
    "Points" -> pointsUsed, "Rank" -> rank, "GradeCount" -> gradeCount,
    "ActiveGrades" -> activeGrades,
    "GradedRootFrame" -> gradedFrameEvidence,
    "Transformation" -> transformation, "Inverse" -> inverse,
    "Connection" -> {newAx, newAy}, "Attempts" -> attempts,
    "ValidationMode" -> validationMode,
    "ExactEpsFactorization" -> If[deferAcceptanceQ,
      Missing["DeferredToFamilyCertificate"], True],
    "ExactInverse" -> inverseQ,
    "GradeConjugationSeconds" -> exactSeconds,
    "ExactCheckSeconds" -> If[deferAcceptanceQ,
      Missing["NotRun"], exactSeconds],
    "CompositionSpotCheck" -> spot,
    "ModularCorroboration" -> corroboration,
    "UseFermat" -> backend["UseFermat"],
    "PropagationSeal" -> If[deferAcceptanceQ,
      Missing["DeferredToFamilyCertificate"],
      familyRegulatorPropagationSeal[
        {ax, ay}, {newAx, newAy}, inverse, transformation]],
    "Seconds" -> AbsoluteTime[] - start|>
];
FactorFamilyRegulatorDependenceMultiquadratic[___] :=
  <|"Status" -> "InvalidArguments"|>;

(* A connection assembled from already-canonical strip records normally
   carries the declared radicands literally.  In that common case an exact
   denesting census over every large matrix entry computes a known answer.
   Recognize only structural declared roots and numeric square classes here;
   any scaled, nested, or otherwise nonliteral radical falls through to the
   existing exact classifier.  The fast path therefore cannot broaden the
   coefficient field or misclassify an algebraic square class. *)
familyRegulatorLiteralRootClassification[expression_, roots_List] := Module[
  {rootSquares, radicals, indices = {}, numericClasses = {}, unmatched = {},
   index, split, numericClass},
  rootSquares = Lookup[roots, "RootSquare", $Failed];
  If[! ListQ[rootSquares] || Length[rootSquares] =!= Length[roots] ||
      ! FreeQ[rootSquares, $Failed],
    Return[<|"Status" -> "LiteralRootFrameInvalid"|>]];
  (* This path is deliberately structural.  The general classifier below
     normalizes and denests nonliteral radicands; doing Together here would
     repeat that expensive work across a family-sized connection before we
     know it is needed. *)
  radicals = DeleteDuplicates[Cases[Unevaluated[expression],
    Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
      base, {0, Infinity}, Heads -> True]];
  Do[
    index = SelectFirst[Range[Length[rootSquares]],
      SameQ[base, rootSquares[[#1]]] &, 0];
    Which[
      index > 0, AppendTo[indices, index],
      MatchQ[base, _Integer | _Rational],
        split = transportChartSquareSplit[base];
        If[split === $Failed,
          AppendTo[unmatched, base],
          numericClass = First[split];
          If[numericClass =!= 1 && numericClass =!= 0,
            AppendTo[numericClasses, numericClass]]],
      True, AppendTo[unmatched, base]],
    {base, radicals}];
  <|"Status" -> If[unmatched === {},
      "LiteralRootClassification", "NeedsExactRootClassification"],
    "RootIndices" -> Sort[DeleteDuplicates[indices]],
    "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unmatched,
    "NumericRadicalClasses" ->
      DeleteDuplicates[numericClasses],
    "DenestedRadicalBases" -> <||>|>
];
familyRegulatorLiteralRootClassification[___] :=
  <|"Status" -> "LiteralRootFrameInvalid"|>;

(* Frame-aware dispatcher (Codex package bug report 2026-08-22, CF300
   (8,5)): for a family whose global coefficient frame is multiquadratic
   the completed truncation 1..m may still be rational in a catalogued
   subchart -- its roots are a subset of the family's.  The constant
   T(eps) found there is independent of the chart variables, hence of
   the frame: it is applied to the identity-frame connection directly
   and the eps-factorization is verified there.  Statuses:
     "AlreadyEpsFactored"  nothing to do (identity);
     "OK"                  factored; "Chart", "RootIndices" recorded;
     "NoRationalChart"     the roots of the truncation have no joint
                           rational chart AND the multiquadratic graded
                           route below also refused -- the caller must
                           stop (typed), never continue with
                           regulator-dependent residues; the graded
                           route's own diagnostics travel in
                           "MultiquadraticFactorization";
     other                 failures of the inner factorization or of
                           the frame round trip.
   Since 2026-08-25 a root set without a joint rational chart is no
   longer an immediate stop: FactorFamilyRegulatorDependenceMultiquadratic
   is attempted first and the typed stop is what remains when IT
   refuses. *)
Clear[FactorFamilyRegulatorDependenceInFrame];
FactorFamilyRegulatorDependenceInFrame::input =
  "The connection must be a pair of equally sized square matrices.";

Options[FactorFamilyRegulatorDependenceInFrame] =
  Options[FactorFamilyRegulatorDependenceMultiquadratic];

FactorFamilyRegulatorDependenceInFrame[{ax_List, ay_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol, frame_Association,
    opts : OptionsPattern[]] := Module[
  {n, start = AbsoluteTime[], allRoots, classification, rootIndices, usedRoots,
   rootSquares, chart, chartVariables, rekeyed, data, components, chartConnection,
   chartRoots, rootImages, chartBranchRoots, inner, transformation, inverse,
   newAx, newAy, factoredQ, inverseQ, canonicalization, numericClasses,
   canonicalAx, canonicalAy, canonicalRecord, gradedRoots, multiquadratic,
   deadline, validationMode, deferAcceptanceQ, rootTags, taggedConnection,
   factorOptions, literalClassification, classificationSeconds = 0.,
   canonicalizationSeconds = 0., classificationMethod},
  If[! (MatrixQ[ax] && MatrixQ[ay] && Dimensions[ax] === Dimensions[ay] &&
      Length[ax] === Length[First[ax]]),
    Message[FactorFamilyRegulatorDependenceInFrame::input]; Return[$Failed]];
  n = Length[ax];
  deadline = OptionValue["Deadline"];
  validationMode = OptionValue["ValidationMode"];
  deferAcceptanceQ = validationMode === "DeferredToFamilyCertificate";
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["FrameEntry", deadline, start]]];
  If[OptionValue["InputResiduesEpsFree"] =!= False &&
      familyRegulatorFactoredQ[ax, epsilon] &&
      familyRegulatorFactoredQ[ay, epsilon],
    Return[<|"Status" -> "AlreadyEpsFactored", "Transformation" -> IdentityMatrix[n],
      "Inverse" -> IdentityMatrix[n], "Connection" -> {ax, ay}, "RootIndices" -> {},
      "Chart" -> None, "Seconds" -> 0.|>]];
  allRoots = transportChartCurrentRoots[frame, variables];
  If[allRoots === $Failed, Return[<|"Status" -> "AlgebraicFrameNotWellFormed"|>]];
  {classificationSeconds, literalClassification} = AbsoluteTiming[
    familyRegulatorLiteralRootClassification[{ax, ay}, allRoots]];
  If[Lookup[literalClassification, "Status", None] ===
      "LiteralRootClassification",
    classification = literalClassification;
    classificationMethod = "LiteralDeclaredRoots";
    canonicalization = <|"Status" -> "OK", "Expression" -> {ax, ay},
      "Rewrites" -> <||>, "Rewritten" -> 0|>,
    {classificationSeconds, classification} = AbsoluteTiming[
      transportChartRootIndices[{ax, ay}, allRoots]];
    classificationMethod = "ExactSquareClass"];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[<|"Status" -> "ConnectionContainsUndeclaredRadicals",
      "RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]];
  rootIndices = classification["RootIndices"];
  numericClasses = Lookup[classification, "NumericRadicalClasses", {}];
  (* Radical canonicalization (2026-08-24, CF303).  A radicand that is
     not itself a declared square -- a nested one such as
     q2 (u + v Sqrt[q1]), or a bare numeric one -- is now classified by
     exact denesting instead of refused, and the chart pullback below
     rationalizes only radicals whose radicand IS a declared square.  So
     every denested radical is first rewritten in terms of the declared
     radicals and numeric class constants:
        Sqrt[base] -> sigma Factor (alpha + beta Sqrt[q]) Sqrt[c] Prod Sqrt[q_i],
     with the identity rewrite^2 == base checked exactly (sign
     independent) inside transportChartDenestRadicalBase and the global
     sign sigma fixed by numeric evaluation at two rational points of the
     region where every declared square is positive.  Numeric radicals
     are constants of the coefficient field and are left as they are;
     they commute with everything and the chart never has to see them. *)
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["RadicalCanonicalization", deadline,
      start, <|"RootIndices" -> rootIndices|>]]];
  If[classificationMethod === "ExactSquareClass",
    {canonicalizationSeconds, canonicalization} = AbsoluteTiming[
      transportChartCanonicalizeDenestedRadicals[
        {ax, ay}, allRoots, variables,
        Lookup[classification, "DenestedRadicalBases", <||>]]]];
  If[Lookup[canonicalization, "Status", None] =!= "OK",
    Return[Join[canonicalization,
      <|"RootIndices" -> rootIndices, "Seconds" -> AbsoluteTime[] - start|>]]];
  {canonicalAx, canonicalAy} = canonicalization["Expression"];
  canonicalRecord = <|
    "Rewritten" -> canonicalization["Rewritten"],
    "Bases" -> Keys[canonicalization["Rewrites"]],
    "Signs" -> Lookup[Values[canonicalization["Rewrites"]], "Sign", {}],
    "Witnesses" -> Lookup[Values[canonicalization["Rewrites"]], "Witness", {}],
    "NumericRadicalClasses" -> numericClasses,
    "ClassificationMethod" -> classificationMethod,
    "ClassificationSeconds" -> N[classificationSeconds],
    "CanonicalizationSeconds" -> N[canonicalizationSeconds]|>;
  Print["[regulator-factor/frame] root classification: ",
    classificationMethod, ", roots ", rootIndices, ", numeric classes ",
    numericClasses, ", ", Round[N[classificationSeconds], 0.1], " s",
    If[canonicalizationSeconds > 0,
      "; canonicalization " <>
        ToString[Round[N[canonicalizationSeconds], 0.1]] <> " s", ""]];
  If[rootIndices === {},
    inner = FactorFamilyRegulatorDependence[{canonicalAx, canonicalAy},
      variables, epsilon,
      FilterRules[{opts}, Options[FactorFamilyRegulatorDependence]]];
    Return[If[AssociationQ[inner],
      Join[inner, <|"RootIndices" -> {}, "Chart" -> None,
        "RadicalCanonicalization" -> canonicalRecord,
        "NumericRadicalClasses" -> numericClasses|>], inner]]];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  chart = TransportRootSetChart[rootSquares, variables];
  If[! AssociationQ[chart],
    (* No joint rational chart (CF259 rows 1..23, 2026-08-25: the triple
       cover of {q1, q2, q3} is a K3 surface).  The constant T(eps) is
       sought in the graded algebra itself; the typed stop is what
       remains if THAT route refuses, and it then carries the graded
       route's diagnostics. *)
    gradedRoots = familyRegulatorGradedRoots[usedRoots, numericClasses];
    If[! ListQ[gradedRoots],
      Return[<|"Status" -> "InvalidGradedRootFrame",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "GradedRootFrame" -> gradedRoots,
        "RadicalCanonicalization" -> canonicalRecord,
        "NumericRadicalClasses" -> numericClasses,
        "Seconds" -> AbsoluteTime[] - start|>]];
    multiquadratic = FactorFamilyRegulatorDependenceMultiquadratic[
      {canonicalAx, canonicalAy}, variables, epsilon, gradedRoots,
      FilterRules[{opts},
        Options[FactorFamilyRegulatorDependenceMultiquadratic]]];
    If[AssociationQ[multiquadratic] &&
        MemberQ[{"OK", "AlreadyEpsFactored"}, multiquadratic["Status"]],
      Return[Join[multiquadratic, <|
        "Method" -> "MultiquadraticGradedAlgebra/" <>
          Lookup[multiquadratic, "Method", "Unknown"],
        "Chart" -> None, "RootIndices" -> rootIndices,
        "RootSquares" -> rootSquares,
        "GradedRootSquares" -> Lookup[gradedRoots, "RootSquare", {}],
        "RadicalCanonicalization" -> canonicalRecord,
        "NumericRadicalClasses" -> numericClasses,
        "SourceFrameEpsFactored" -> Lookup[multiquadratic,
          "ExactEpsFactorization",
          Missing["DeferredToFamilyCertificate"]],
        "InverseExact" -> Lookup[multiquadratic, "ExactInverse",
          Missing["DeferredToFamilyCertificate"]],
        (* the seal is taken on the caller's own input prefix, exactly as
           on the chart route: the propagation helper recomputes it from
           the connection it is given *)
        "PropagationSeal" -> If[deferAcceptanceQ,
          Missing["DeferredToFamilyCertificate"],
          familyRegulatorPropagationSeal[
            {ax, ay}, multiquadratic["Connection"],
            multiquadratic["Inverse"], multiquadratic["Transformation"]]],
        "Seconds" -> AbsoluteTime[] - start|>]]];
    (* a deadline expiry inside the graded route is NOT the typed
       terminal: "NoRationalChart" says the block is unsolvable by both
       routes and the driver stops the family on it.  A stage that simply
       ran out of budget is resumable and must propagate as such. *)
    If[AssociationQ[multiquadratic] &&
        multiquadratic["Status"] === "RegulatorFactorizationDeadlineExpired",
      Return[Join[multiquadratic,
        <|"RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
          "Chart" -> None,
          "GradedRootSquares" -> Lookup[gradedRoots, "RootSquare", {}]|>]]];
    Return[<|"Status" -> "NoRationalChart", "RootIndices" -> rootIndices,
      "RootSquares" -> rootSquares,
      "GradedRootSquares" -> Lookup[gradedRoots, "RootSquare", {}],
      "RadicalCanonicalization" -> canonicalRecord,
      "NumericRadicalClasses" -> numericClasses,
      "MultiquadraticFactorization" -> If[AssociationQ[multiquadratic],
        KeyDrop[multiquadratic, {"Transformation", "Inverse", "Connection",
          "Channels", "Grades"}],
        <|"Status" -> "MultiquadraticRouteFailed", "Result" -> multiquadratic|>],
      "Seconds" -> AbsoluteTime[] - start|>]];
  chartVariables = {Symbol["FeynFacet`Private`regulatorChartX"],
    Symbol["FeynFacet`Private`regulatorChartY"]};
  rekeyed = transportChartRekey[chart, variables, chartVariables];
  data = masterTransportChartData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#["RootSquare"] - usedRoots[[i]]["RootSquare"]] === 0] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]], {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ], Return[<|"Status" -> "ChartRootMapMissing"|>]];
  chartBranchRoots = Map[<|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &, usedRoots];
  (* Order matters (measured 2026-08-24 on the 27x27 CF303 truncation:
     the old order did not finish this pullback in 50 minutes).  Together
     applied while the entries still carry radicals RATIONALIZES radical
     denominators by conjugation -- the trap this repository has paid for
     -- and multiplies every entry out.  Substituting the chart's own
     RATIONAL root images first leaves Together a purely rational job.
     The branch substitution matches on the Together-difference against
     the substituted declared square, so it does not need a normalized
     entry to fire. *)
  If[familyRegulatorDeadlineExpiredQ[deadline],
    Return[familyRegulatorDeadlineStop["ChartPullBack", deadline, start,
      <|"RootIndices" -> rootIndices, "Chart" -> chart["Name"]|>]]];
  factorOptions = FilterRules[{opts},
    Options[FactorFamilyRegulatorDependence]];
  If[numericClasses =!= {},
    factorOptions = Append[
      DeleteCases[factorOptions, HoldPattern["UseFermat" -> _]],
      "UseFermat" -> False]];
  If[deferAcceptanceQ,
    (* Tag roots while their source-frame square classes are still distinct.
       Specializing root squares first would make unrelated roots differ by
       rational squares at a point and could select the wrong branch. *)
    rootTags = Table[Unique["FeynFacet`Private`regulatorRoot"],
      {Length[usedRoots]}];
    taggedConnection = Map[
      transportChartApplyRootBranches[#, usedRoots, rootTags] &,
      {canonicalAx, canonicalAy}];
    inner = familyRegulatorFactorFromPointEvaluator[
      Function[{chartPointRules}, familyRegulatorChartPointConnection[
        taggedConnection, rootTags, data, rootImages, chartPointRules]],
      n, chartVariables, epsilon, Sequence @@ factorOptions],
    components = Map[
      Function[matrix, Map[Together, transportChartApplyRootBranches[
        matrix /. data["Subst"], chartBranchRoots, rootImages], {2}]],
      {canonicalAx, canonicalAy}];
    chartConnection = masterTransportPullBackOneForm[
      components[[1]], components[[2]], data["Jacobian"]];
    (* Numeric radicals survive the chart by construction: they are
       constants, not functions of the chart variables, and a chart cannot
       and need not rationalize them.  Only a SYMBOLIC radical left in the
       chart means the pullback did not rationalize the connection. *)
    If[! FreeQ[chartConnection,
        Power[base_ /; ! NumericQ[base],
          exponent_Rational /; Denominator[exponent] === 2]],
      Return[<|"Status" -> "ChartStillAlgebraic", "RootIndices" -> rootIndices,
        "Chart" -> chart["Name"],
        "RadicalCanonicalization" -> canonicalRecord,
        "ResidualRadicalBases" -> DeleteDuplicates[Cases[chartConnection,
          Power[base_ /; ! NumericQ[base],
            exponent_Rational /; Denominator[exponent] === 2] :> Together[base],
          {0, Infinity}, Heads -> True]]|>]];
    inner = FactorFamilyRegulatorDependence[chartConnection, chartVariables,
      epsilon, Sequence @@ factorOptions]];
  If[! (AssociationQ[inner] && inner["Status"] === "OK"),
    Return[Join[If[AssociationQ[inner], inner, <|"Status" -> "InnerFactorizationFailed"|>],
      <|"RootIndices" -> rootIndices, "Chart" -> chart["Name"],
        "RadicalCanonicalization" -> canonicalRecord|>]]];
  transformation = inner["Transformation"]; inverse = inner["Inverse"];
  If[! FreeQ[{transformation, inverse}, Alternatives @@ Join[variables, chartVariables]],
    Return[<|"Status" -> "TransformationNotConstant", "RootIndices" -> rootIndices,
      "Chart" -> chart["Name"]|>]];
  (* the statement is made in the source (identity) frame, on the
     canonicalized connection: it is the same connection written in the
     declared radicals (each rewrite certified by rewrite^2 == base plus
     the numeric sign), and only in that form can the eps-factorization
     be decided by Together *)
  newAx = If[deferAcceptanceQ,
    familyRegulatorConjugateDeferred[inverse, canonicalAx, transformation],
    familyRegulatorConjugate[inverse, canonicalAx, transformation]];
  newAy = If[deferAcceptanceQ,
    familyRegulatorConjugateDeferred[inverse, canonicalAy, transformation],
    familyRegulatorConjugate[inverse, canonicalAy, transformation]];
  factoredQ = If[deferAcceptanceQ,
    Missing["DeferredToFamilyCertificate"],
    familyRegulatorFactoredQ[newAx, epsilon] &&
      familyRegulatorFactoredQ[newAy, epsilon]];
  inverseQ = If[deferAcceptanceQ,
    Missing["DeferredToFamilyCertificate"],
    AllTrue[Flatten[Map[Together,
      transformation . inverse - IdentityMatrix[n], {2}]], TrueQ[# === 0] &] &&
      AllTrue[Flatten[Map[Together,
        inverse . transformation - IdentityMatrix[n], {2}]], TrueQ[# === 0] &]];
  If[! deferAcceptanceQ && ! (factoredQ && inverseQ),
    Return[<|"Status" -> "SourceFrameNotFactored", "SourceFrameEpsFactored" -> factoredQ,
      "InverseExact" -> inverseQ, "RootIndices" -> rootIndices, "Chart" -> chart["Name"]|>]];
  <|"Status" -> "OK",
    "Method" -> "RationalChart/" <> chart["Name"] <> "/" <> inner["Method"],
    "Chart" -> chart["Name"], "RootIndices" -> rootIndices, "Points" -> inner["Points"],
    "Transformation" -> transformation, "Inverse" -> inverse,
    "Connection" -> {newAx, newAy}, "Attempts" -> inner["Attempts"],
    (* the seal is taken on the caller's own input prefix: the
       propagation helper recomputes it from the connection it is given *)
    "PropagationSeal" -> If[deferAcceptanceQ,
      Missing["DeferredToFamilyCertificate"],
      familyRegulatorPropagationSeal[
        {ax, ay}, {newAx, newAy}, inverse, transformation]],
    "RadicalCanonicalization" -> canonicalRecord,
    "NumericRadicalClasses" -> numericClasses,
    "SourceFrameEpsFactored" -> factoredQ, "InverseExact" -> inverseQ,
    "Seconds" -> AbsoluteTime[] - start|>
];
