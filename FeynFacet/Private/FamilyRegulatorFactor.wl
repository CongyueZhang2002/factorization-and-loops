(* Family-level regulator factorization (2026-08-22, replaces the
   per-sector CANONICA TransformDlogToEpsForm step of the sector script).

   After the off-diagonal completion the family connection is
     A_mu = eps Sum_a K_a(eps) dlog_mu L_a
   with letters free of the regulator and residue matrices K_a that may
   still depend on it (the dlog-form contract).  A CONSTANT (chart
   independent) transformation T(eps) with T^{-1} K_a T free of eps is
   found once for the whole family with Libra`FactorDependence on exact
   rational samples of A_mu/eps: the identity A(eps, x) T(eps) = T(eps)
   A(mu, x) at generic chart points is linear in T and the unsampled
   symbolic identity is the acceptance test (the method of
   Scripts/libra_checkpoint_factor_dependence.wls, "ExactRationalSamples").
   Since T is constant in the variables, dT = 0 and A' = T^{-1} A T. *)

Clear[FactorFamilyRegulatorDependence];
ClearAll[familyRegulatorFactoredQ, familyRegulatorSpecialize,
  familyRegulatorConjugate, familyRegulatorSparseDot,
  familyRegulatorPropagationSeal,
  familyRegulatorPropagateTruncation, familyRegulatorPointFactoredQ];

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
   sums.  Together preserves the historical full-conjugation path. *)
familyRegulatorPropagateTruncation[
    connection : {_List, _List}, transformedPrefix : {_List, _List},
    inverse_List, transformation_List, prefix_Integer?Positive,
    variables : {_Symbol, _Symbol}, seal_Association,
    futureMode_: "Together"] := Module[
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
  inverseExactQ = And @@ (AllTrue[
      Flatten[Map[Together, #, {2}]], SameQ[#, 0] &] & /@ {
        inverse . transformation - IdentityMatrix[prefix],
        transformation . inverse - IdentityMatrix[prefix]});
  If[! inverseExactQ,
    Return[<|"Status" ->
      "RegulatorTransformationInverseInvalid"|>]];
  expectedSeal = familyRegulatorPropagationSeal[
    connection[[All, Range[prefix], Range[prefix]]],
    transformedPrefix, inverse, transformation];
  If[expectedSeal === $Failed || ! SameQ[seal, expectedSeal],
    Return[<|"Status" -> "RegulatorPropagationSealMismatch"|>]];
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
   a fraction of a second; the symbolic identity remains the acceptance
   test for a candidate that passes. *)
familyRegulatorPointFactoredQ[inverse_List, {ax_List, ay_List}, candidate_List, rules_List, epsilon_Symbol] :=
  AllTrue[rules, Function[r, Module[{sx, sy},
    {sx, sy} = {ax, ay} /. r;
    If[! FreeQ[{sx, sy}, Indeterminate | ComplexInfinity | DirectedInfinity[_]], Return[True, Module]];
    familyRegulatorFactoredQ[familyRegulatorConjugate[inverse, sx, candidate], epsilon] &&
      familyRegulatorFactoredQ[familyRegulatorConjugate[inverse, sy, candidate], epsilon]]]];

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
   transformation = $Failed, inverse, raw, attempts = {}, newAx, newAy, pointsUsed = 0},
  If[! (MatrixQ[ax] && MatrixQ[ay] && Dimensions[ax] === Dimensions[ay] &&
      Length[ax] === Length[First[ax]]),
    Message[FactorFamilyRegulatorDependence::input]; Return[$Failed]];
  n = Length[ax];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[regulator-factor] ", args]];
  If[familyRegulatorFactoredQ[ax, epsilon] && familyRegulatorFactoredQ[ay, epsilon],
    log["the connection is already eps-factored"];
    Return[<|"Status" -> "AlreadyEpsFactored", "Transformation" -> IdentityMatrix[n],
      "Inverse" -> IdentityMatrix[n], "Connection" -> {ax, ay}, "Seconds" -> 0.|>]];
  backend = libraEpsFormLoadBackend[OptionValue["UseFermat"]];
  If[backend["Status"] =!= "OK", Return[<|"Status" -> backend["Status"]|>]];
  reference = Unique["regulatorReference"];
  rules = Table[{x -> Prime[k + 3]/Prime[k + 11], y -> Prime[2 k + 5]/Prime[2 k + 15]}, {k, 1, 24}];
  valid = Select[rules, Function[r, Module[{s = Map[Together, {ax, ay} /. r, {3}]},
    FreeQ[s, Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
      AllTrue[Flatten[s], Denominator[#] =!= 0 &]]]];
  Do[
    If[count > Length[valid], Break[]];
    Module[{matrices, result, candidate, ok = False, gate = False, seconds},
      matrices = Flatten[Table[{Map[Together, (ax/epsilon) /. valid[[k]], {2}],
        Map[Together, (ay/epsilon) /. valid[[k]], {2}]}, {k, count}], 1];
      log["FactorDependence on ", Length[matrices], " sampled matrices (", count, " points)"];
      {seconds, result} = AbsoluteTiming[Quiet[TimeConstrained[
        Libra`FactorDependence[matrices, epsilon, reference,
          DependentRowIndices -> Automatic, Sort -> True],
        OptionValue["TimeLimit"], "TimedOut"]]];
      candidate = If[MatrixQ[result], familyRegulatorSpecialize[result, reference, n], $Failed];
      If[MatrixQ[candidate],
        inverse = Map[Together, Inverse[candidate], {2}];
        gate = familyRegulatorPointFactoredQ[inverse, {ax, ay}, candidate,
          Take[Reverse[valid], UpTo[OptionValue["GatePoints"]]], epsilon];
        If[gate,
          newAx = familyRegulatorConjugate[inverse, ax, candidate];
          newAy = familyRegulatorConjugate[inverse, ay, candidate];
          ok = familyRegulatorFactoredQ[newAx, epsilon] && familyRegulatorFactoredQ[newAy, epsilon]]];
      AppendTo[attempts, <|"Points" -> count, "Seconds" -> seconds, "PointGate" -> gate, "ExactEpsFactor" -> ok,
        "Result" -> If[result === "TimedOut", "TimedOut", If[MatrixQ[result], "Matrix", Head[result]]]|>];
      log[count, " points: ", Round[seconds, 0.1], " s, point gate ", gate, ", exact eps-factorization ", ok];
      If[ok, transformation = candidate; raw = result; pointsUsed = count]];
    If[MatrixQ[transformation], Break[]],
    {count, OptionValue["PointLadder"]}];
  If[! MatrixQ[transformation],
    Return[<|"Status" -> "NotFactored", "Attempts" -> attempts,
      "Seconds" -> AbsoluteTime[] - start|>]];
  <|"Status" -> "OK", "Method" -> "ExactRationalSamples", "Points" -> pointsUsed,
    "Transformation" -> transformation, "Inverse" -> inverse,
    "Connection" -> {newAx, newAy}, "Attempts" -> attempts,
    "PropagationSeal" -> familyRegulatorPropagationSeal[
      {ax, ay}, {newAx, newAy}, inverse, transformation],
    "UseFermat" -> backend["UseFermat"], "Seconds" -> AbsoluteTime[] - start|>
];

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
                           rational chart -- the caller must stop
                           (typed), never continue with
                           regulator-dependent residues;
     other                 failures of the inner factorization or of
                           the frame round trip. *)
Clear[FactorFamilyRegulatorDependenceInFrame];
FactorFamilyRegulatorDependenceInFrame::input =
  "The connection must be a pair of equally sized square matrices.";

Options[FactorFamilyRegulatorDependenceInFrame] = Options[FactorFamilyRegulatorDependence];

FactorFamilyRegulatorDependenceInFrame[{ax_List, ay_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol, frame_Association,
    opts : OptionsPattern[]] := Module[
  {n, start = AbsoluteTime[], allRoots, classification, rootIndices, usedRoots,
   rootSquares, chart, chartVariables, rekeyed, data, components, chartConnection,
   chartRoots, rootImages, chartBranchRoots, inner, transformation, inverse,
   newAx, newAy, factoredQ, inverseQ},
  If[! (MatrixQ[ax] && MatrixQ[ay] && Dimensions[ax] === Dimensions[ay] &&
      Length[ax] === Length[First[ax]]),
    Message[FactorFamilyRegulatorDependenceInFrame::input]; Return[$Failed]];
  n = Length[ax];
  If[familyRegulatorFactoredQ[ax, epsilon] && familyRegulatorFactoredQ[ay, epsilon],
    Return[<|"Status" -> "AlreadyEpsFactored", "Transformation" -> IdentityMatrix[n],
      "Inverse" -> IdentityMatrix[n], "Connection" -> {ax, ay}, "RootIndices" -> {},
      "Chart" -> None, "Seconds" -> 0.|>]];
  allRoots = transportChartCurrentRoots[frame, variables];
  If[allRoots === $Failed, Return[<|"Status" -> "AlgebraicFrameNotWellFormed"|>]];
  classification = transportChartRootIndices[{ax, ay}, allRoots];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[<|"Status" -> "ConnectionContainsUndeclaredRadicals",
      "RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]];
  rootIndices = classification["RootIndices"];
  If[rootIndices === {},
    inner = FactorFamilyRegulatorDependence[{ax, ay}, variables, epsilon, opts];
    Return[If[AssociationQ[inner], Join[inner, <|"RootIndices" -> {}, "Chart" -> None|>], inner]]];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  chart = TransportRootSetChart[rootSquares, variables];
  If[! AssociationQ[chart],
    Return[<|"Status" -> "NoRationalChart", "RootIndices" -> rootIndices,
      "RootSquares" -> rootSquares, "Seconds" -> AbsoluteTime[] - start|>]];
  chartVariables = {Symbol["FeynFacet`Private`regulatorChartX"],
    Symbol["FeynFacet`Private`regulatorChartY"]};
  rekeyed = transportChartRekey[chart, variables, chartVariables];
  data = masterTransportChartData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  components = Map[Map[Together, # /. data["Subst"], {2}] &, {ax, ay}];
  chartConnection = masterTransportPullBackOneForm[
    components[[1]], components[[2]], data["Jacobian"]];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#["RootSquare"] - usedRoots[[i]]["RootSquare"]] === 0] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]], {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ], Return[<|"Status" -> "ChartRootMapMissing"|>]];
  chartBranchRoots = Map[<|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &, usedRoots];
  chartConnection = Map[Together,
    transportChartApplyRootBranches[chartConnection, chartBranchRoots, rootImages], {3}];
  If[! FreeQ[chartConnection, Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[<|"Status" -> "ChartStillAlgebraic", "RootIndices" -> rootIndices,
      "Chart" -> chart["Name"]|>]];
  inner = FactorFamilyRegulatorDependence[chartConnection, chartVariables, epsilon, opts];
  If[! (AssociationQ[inner] && inner["Status"] === "OK"),
    Return[Join[If[AssociationQ[inner], inner, <|"Status" -> "InnerFactorizationFailed"|>],
      <|"RootIndices" -> rootIndices, "Chart" -> chart["Name"]|>]]];
  transformation = inner["Transformation"]; inverse = inner["Inverse"];
  If[! FreeQ[{transformation, inverse}, Alternatives @@ Join[variables, chartVariables]],
    Return[<|"Status" -> "TransformationNotConstant", "RootIndices" -> rootIndices,
      "Chart" -> chart["Name"]|>]];
  (* the statement is made in the source (identity) frame *)
  newAx = familyRegulatorConjugate[inverse, ax, transformation];
  newAy = familyRegulatorConjugate[inverse, ay, transformation];
  factoredQ = familyRegulatorFactoredQ[newAx, epsilon] && familyRegulatorFactoredQ[newAy, epsilon];
  inverseQ = AllTrue[Flatten[Map[Together, transformation . inverse - IdentityMatrix[n], {2}]], TrueQ[# === 0] &] &&
    AllTrue[Flatten[Map[Together, inverse . transformation - IdentityMatrix[n], {2}]], TrueQ[# === 0] &];
  If[! (factoredQ && inverseQ),
    Return[<|"Status" -> "SourceFrameNotFactored", "SourceFrameEpsFactored" -> factoredQ,
      "InverseExact" -> inverseQ, "RootIndices" -> rootIndices, "Chart" -> chart["Name"]|>]];
  <|"Status" -> "OK",
    "Method" -> "RationalChart/" <> chart["Name"] <> "/" <> inner["Method"],
    "Chart" -> chart["Name"], "RootIndices" -> rootIndices, "Points" -> inner["Points"],
    "Transformation" -> transformation, "Inverse" -> inverse,
    "Connection" -> {newAx, newAy}, "Attempts" -> inner["Attempts"],
    "PropagationSeal" -> familyRegulatorPropagationSeal[
      {ax, ay}, {newAx, newAy}, inverse, transformation],
    "SourceFrameEpsFactored" -> True, "InverseExact" -> True,
    "Seconds" -> AbsoluteTime[] - start|>
];
