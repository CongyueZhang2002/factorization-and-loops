(* FeynFacet/Private/EpsForm/FiniteField/FiniteFieldDeferredForcing.wl
   (round 8, pass 3, 2026-09-02): the finite-field strip sampler fed from the
   deferred block-equation DAG WITHOUT materializing it in characteristic
   zero.

   On the chart route a strip whose forcing is a deferred preparation used to
   be pulled back exactly before the inner solve (materialization of every
   operand, then the Jacobian normalization: 53 + 60 s on CF300 (12,7),
   1477 s of materialization alone on CF303 (25,18)), only for the sampler
   to reduce the result modulo primes at random points.  Here the sampler
   gets the residue images directly: the chart point is mapped to the source
   frame modulo p, the declared roots take their rational chart images
   modulo p, the native evaluator flint_deferred_ast_eval (the same adapter
   the chartless engine uses) evaluates the DAG at every point in one call,
   the grade channels are contracted with the root values and the chain
   rule is applied modulo p.  Exactness: on CF300 (12,9) and (12,7) the
   images agree SameQ with the exact pull-back at every sample point
   (scratchpad/round4/M/r8/dag_r1.log, dag_r4.log, 2026-09-02).

   The three census items the sampler used to read off the materialized
   forcing (the regulator-free irreducible denominator factors, the gauge
   denominator Prod f^(k-1) over factors of pole order k > 1, the forcing's
   degree at infinity) are recovered modulo p as well: the candidate factors
   are the irreducible factors of the operand denominators and of the chart
   map pulled back into the chart (a structural superset), and every entry's
   true denominator is interpolated along two random lines in the chart with
   one nullspace at the structural degree bound, reduced by the gcd and
   validated on held-out points; the multiplicity of each candidate is read
   off by exact division of the line denominator.  Two lines must agree.
   The exact census counts a sign variant of the same irreducible factor
   twice (DeleteDuplicates with SameQ over FactorList output: CF300 (12,9)
   gauge denominator degrees {14, 11} where the true ones are {12, 10}); this
   census does not, so the ansatz is the minimal one and a solution is
   compared with the exact route's as a rational function, not as a vector.

   Nothing here is an acceptance step.  The unseen-prime residual of the
   sampler, the modular residual below (the numerical verifier's identity
   with the DAG image in place of the placeholder forcing) and the family
   certificate are the checks; exact materialization is left to the family
   certificate.  Every failure is typed; the in-frame solver falls back to
   the exact route on any of them. *)

Begin["FeynFacet`Private`"];

ClearAll[
  $finiteFieldDeferredForcingRegistry,
  finiteFieldDeferredForcingRouteQ,
  finiteFieldDeferredForcingModAt,
  finiteFieldDeferredForcingPlan,
  finiteFieldDeferredForcingPreflights,
  finiteFieldDeferredForcingImages,
  finiteFieldDeferredForcingLineFit,
  finiteFieldDeferredForcingCandidateFactors,
  finiteFieldDeferredForcingCensus,
  finiteFieldDeferredForcingResidualQ
];

$finiteFieldDeferredForcingRegistry = <||>;
(* images already evaluated, keyed by {plan key, prime, x, y, epsMod}: the
   regulator samples of a prime share their points, so a wave of samples is
   one native batch (finiteFieldStripSolve pre-warms it) and every
   per-sample request is served from here *)
$finiteFieldDeferredForcingImageCache = <||>;
(* images per native request: flint_deferred_ast_eval.c caps a request at
   MAX_TOTAL_IMAGES = 4096 channels, i.e. Floor[4096/gradeCount] images
   (ResourceLimit, exit 5); the chunk is the smaller of this and that cap *)
$finiteFieldDeferredForcingBatchLimit = 1024;

(* FACET_DEFERRED_FORCING=Off restores the exact pull-back before the inner
   solve (the pre-2026-09-02 route); anything else keeps the DAG route *)
finiteFieldDeferredForcingRouteQ[] :=
  Environment["FACET_DEFERRED_FORCING"] =!= "Off";

finiteFieldDeferredForcingModAt[expression_, values_Association, prime_Integer] :=
  With[{r = blockEquationDeferredModEvaluate[expression, values, {}, prime]},
    If[AssociationQ[r] && r["Status"] === "OK", r["Value"], $Failed]];

(* The plan binds everything the images need: the preparation and its file
   (the adapter parses the file itself), the chart substitution, the
   Jacobian, the roots with their chart images.  Registered under a key
   derived from the file, the chart substitution and the root images, so a
   strip record carries only the small descriptor. *)
finiteFieldDeferredForcingPlan[deferredPreparation_Association,
    inputFile_String, data_Association, usedRoots_List, rootImages_List,
    chartVariables : {_Symbol, _Symbol}, variables : {_Symbol, _Symbol},
    epsilon_Symbol, dimensions : {_Integer, _Integer}] := Module[
  {preparation, key, plan},
  preparation = Lookup[deferredPreparation, "Preparation",
    Lookup[deferredPreparation, "DeferredPreparation", $Failed]];
  If[! AssociationQ[preparation] ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      ! FileExistsQ[inputFile] ||
      ! MatchQ[Lookup[data, "Subst", None], {_Rule, _Rule}] ||
      ! MatchQ[Lookup[data, "Jacobian", None], {{_, _}, {_, _}}] ||
      Length[usedRoots] =!= Length[rootImages] ||
      multiquadraticStripNativeDeferredBinary[] === None,
    Return[<|"Status" -> "DeferredForcingPlanInvalid"|>]];
  key = Hash[{inputFile, Lookup[preparation, "Fingerprint", None],
    data["Subst"], rootImages, Lookup[usedRoots, "RootSquare", {}]},
    "SHA256", "HexString"];
  plan = <|"Status" -> "OK", "Key" -> key,
    "InputFile" -> inputFile,
    "Tables" -> finiteFieldDeferredForcingTables[data, rootImages, usedRoots,
      chartVariables, variables, epsilon],
    "Preparation" -> preparation,
    "Variables" -> variables, "ChartVariables" -> chartVariables,
    "Regulator" -> epsilon, "Dimensions" -> dimensions,
    "Subst" -> data["Subst"], "Jacobian" -> data["Jacobian"],
    "Roots" -> usedRoots, "RootImages" -> rootImages,
    "Provider" -> <|"Variables" -> variables, "Regulator" -> epsilon,
      "Roots" -> usedRoots, "RootCount" -> Length[usedRoots],
      "GradeCount" -> 2^Length[usedRoots], "Dimensions" -> dimensions,
      "DeferredPreparation" -> preparation,
      "DeferredPreparationFile" -> inputFile,
      "SourceFingerprint" -> Lookup[preparation, "SourceFingerprint", None],
      "ProviderFingerprint" -> key|>|>;
  $finiteFieldDeferredForcingRegistry[key] = plan;
  plan
];
finiteFieldDeferredForcingPlan[___] := <|"Status" -> "DeferredForcingPlanInvalid"|>;

(* Coefficient tables of the small eps-free chart data (substitution,
   root images, root squares, Jacobian): a rational function becomes
   {numeratorRules, denominatorRules} with integer coefficients, and a batch
   of points is evaluated with packed-array arithmetic instead of one AST
   evaluation per point per expression (2 ms per image before). *)
finiteFieldDeferredForcingTable[expression_, vars_List] := Module[{t, rn, rd, lcm},
  t = Together[expression];
  rn = CoefficientRules[Numerator[t], vars]; rd = CoefficientRules[Denominator[t], vars];
  lcm = LCM @@ Denominator /@ Join[rn[[All, 2]], rd[[All, 2]]];
  {MapAt[lcm # &, rn, {All, 2}], MapAt[lcm # &, rd, {All, 2}]}
];
finiteFieldDeferredForcingTables[data_Association, rootImages_List, usedRoots_List,
    chartVariables_List, variables_List, epsilon_Symbol] := Module[
  {chartVars = Append[chartVariables, epsilon], sourceVars = Append[variables, epsilon],
   subst, images, squares, jacobian, degrees},
  subst = finiteFieldDeferredForcingTable[#, chartVars] & /@ data["Subst"][[All, 2]];
  images = finiteFieldDeferredForcingTable[#, chartVars] & /@ rootImages;
  jacobian = Map[finiteFieldDeferredForcingTable[#, chartVars] &, data["Jacobian"], {2}];
  squares = finiteFieldDeferredForcingTable[#, sourceVars] & /@ Lookup[usedRoots, "RootSquare", {}];
  degrees[tables_] := Max /@ Transpose[Join[ConstantArray[0, {1, 3}],
    Flatten[Cases[tables, (exponents_List -> _) :> exponents, Infinity], 0]]];
  <|"Subst" -> subst, "RootImages" -> images, "Jacobian" -> jacobian,
    "Squares" -> squares,
    "ChartDegrees" -> degrees[{subst, images, jacobian}],
    "SquareDegrees" -> degrees[squares]|>
];
(* powers 0..degree of a packed vector of residues: dims {degree + 1, n} *)
finiteFieldDeferredForcingPowers[values_List, degree_Integer, prime_Integer] :=
  NestList[Mod[# values, prime] &, ConstantArray[1, Length[values]], degree];
finiteFieldDeferredForcingPolynomialAt[rules_List, powers_List, prime_Integer, count_Integer] :=
  Module[{acc = ConstantArray[0, count]},
    Do[acc = Mod[acc + Mod[Mod[rule[[2]], prime]
      Fold[Mod[#1 #2, prime] &, MapThread[#1[[#2 + 1]] &, {powers, rule[[1]]}]], prime], prime],
      {rule, rules}];
    acc];
(* the values of a rational function at the batch; $Failed with the first
   singular position when a denominator vanishes *)
finiteFieldDeferredForcingRationalAt[{numRules_, denRules_}, powers_List, prime_Integer,
    count_Integer] := Module[{num, den, zero},
  num = finiteFieldDeferredForcingPolynomialAt[numRules, powers, prime, count];
  den = finiteFieldDeferredForcingPolynomialAt[denRules, powers, prime, count];
  zero = FirstPosition[den, 0, None, {1}, Heads -> False];
  If[zero =!= None, Return[{$Failed, First[zero]}]];
  Mod[num PowerMod[den, -1, prime], prime]
];

(* one preflight per image {x, y, epsMod}: source point, root squares and
   root values modulo p, evaluated for the whole batch at once from the
   coefficient tables; a point where the chart map or a root image has a
   pole is a typed rejection of the whole request *)
finiteFieldDeferredForcingPreflights[plan_Association, prime_Integer,
    images_List] := Module[
  {tables = plan["Tables"], count = Length[images], powers, sv, rv, dv, sourcePowers,
   bad, mismatch},
  powers = MapThread[finiteFieldDeferredForcingPowers[#1, #2, prime] &,
    {Transpose[images], tables["ChartDegrees"]}];
  sv = finiteFieldDeferredForcingRationalAt[#, powers, prime, count] & /@ tables["Subst"];
  rv = finiteFieldDeferredForcingRationalAt[#, powers, prime, count] & /@ tables["RootImages"];
  bad = FirstCase[Join[sv, rv], {$Failed, position_} :> position, None];
  If[bad =!= None,
    Return[<|"Status" -> "DeferredForcingSingularChartPoint", "Image" -> images[[bad]]|>]];
  sourcePowers = MapThread[finiteFieldDeferredForcingPowers[#1, #2, prime] &,
    {Append[sv, images[[All, 3]]], tables["SquareDegrees"]}];
  dv = finiteFieldDeferredForcingRationalAt[#, sourcePowers, prime, count] & /@ tables["Squares"];
  bad = FirstCase[dv, {$Failed, position_} :> position, None];
  If[bad =!= None,
    Return[<|"Status" -> "DeferredForcingRootImageMismatch", "Image" -> images[[bad]]|>]];
  mismatch = If[rv === {}, None,
    FirstPosition[Total[Mod[Mod[rv rv, prime] - dv, prime]], _?Positive, None, {1}, Heads -> False]];
  If[mismatch =!= None,
    Return[<|"Status" -> "DeferredForcingRootImageMismatch", "Image" -> images[[First[mismatch]]]|>]];
  Table[<|"Status" -> "MultiquadraticProviderPreflightV1", "Prime" -> prime,
      "ProviderFingerprint" -> plan["Key"], "Point" -> sv[[All, b]], "EpsilonMod" -> images[[b, 3]],
      "RootSquares" -> dv[[All, b]], "RootValues" -> rv[[All, b]]|>, {b, count}]
];
(* the per-point reference (AST evaluation of the chart data at every image);
   the exactness probe and the test compare the batch evaluator against it *)
finiteFieldDeferredForcingPreflightsReference[plan_Association, prime_Integer,
    images_List] := Module[{X, Y, subst, rootImages, squares, variables, epsilon},
  {X, Y} = plan["ChartVariables"]; subst = plan["Subst"];
  rootImages = plan["RootImages"]; variables = plan["Variables"];
  squares = Lookup[plan["Roots"], "RootSquare", {}];
  epsilon = plan["Regulator"];
  Catch[Table[Module[{x = image[[1]], y = image[[2]], eps = image[[3]], values, sv, rv, dv},
      values = <|X -> x, Y -> y, epsilon -> eps|>;
      sv = finiteFieldDeferredForcingModAt[#, values, prime] & /@ subst[[All, 2]];
      rv = finiteFieldDeferredForcingModAt[#, values, prime] & /@ rootImages;
      If[MemberQ[sv, $Failed] || MemberQ[rv, $Failed],
        Throw[<|"Status" -> "DeferredForcingSingularChartPoint", "Image" -> image|>, "dfp"]];
      dv = finiteFieldDeferredForcingModAt[#,
        Join[AssociationThread[variables, sv], <|epsilon -> eps|>], prime] & /@ squares;
      If[MemberQ[dv, $Failed] || Mod[rv^2 - dv, prime] =!= ConstantArray[0, Length[rv]],
        Throw[<|"Status" -> "DeferredForcingRootImageMismatch", "Image" -> image|>, "dfp"]];
      <|"Status" -> "MultiquadraticProviderPreflightV1", "Prime" -> prime,
        "ProviderFingerprint" -> plan["Key"], "Point" -> sv, "EpsilonMod" -> eps,
        "RootSquares" -> dv, "RootValues" -> rv|>],
    {image, images}], "dfp"]
];

(* the forcing images: one native batch; per image an array
   {2, d1, d2} of residues (the chart one-form after the Jacobian) *)
finiteFieldDeferredForcingImages[key_String, prime_Integer, images_List] := Module[
  {plan, preflights, batch, gradeCount, jacobian, powers, masks, started = AbsoluteTime[],
   cacheKeys, missing, batchSeconds = 0.},
  plan = Lookup[$finiteFieldDeferredForcingRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredForcingPlanUnknown"|>]];
  If[images === {}, Return[<|"Status" -> "OK", "Values" -> {}, "Seconds" -> 0.|>]];
  cacheKeys = Join[{key, prime}, #] & /@ images;
  missing = Pick[Range[Length[images]], KeyExistsQ[$finiteFieldDeferredForcingImageCache, #] & /@ cacheKeys, False];
  (* the native evaluator caps the images per request (ResourceLimit above
     ~1000): the missing images go in chunks of $finiteFieldDeferredForcingBatchLimit *)
  Do[
    preflights = finiteFieldDeferredForcingPreflights[plan, prime, images[[chunk]]];
    If[AssociationQ[preflights], Return[preflights, Module]];
    (* 8 threads: 2x over 4 on CF300 (12,7) (960 images 1.36 -> 0.69 s); the
       seat launcher pins the process to 8 CPUs *)
    batch = multiquadraticStripNativeDeferredEvaluateBatch[plan["Provider"], preflights,
      "Threads" -> Clip[$ProcessorCount, {1, 8}]];
    If[Lookup[batch, "Status", None] =!= "MultiquadraticNativeDeferredBatchV1",
      Return[<|"Status" -> "DeferredForcingBatchFailed", "Detail" -> batch|>, Module]];
    batchSeconds += batch["Seconds"];
    gradeCount = batch["GradeCount"];
    If[Length[$finiteFieldDeferredForcingImageCache] > 400000,
      $finiteFieldDeferredForcingImageCache = <||>];
    (* grade contraction with the root values (one Dot per image) and the
       Jacobian from its tables, both for the whole chunk *)
    powers = MapThread[finiteFieldDeferredForcingPowers[#1, #2, prime] &,
      {Transpose[images[[chunk]]], plan["Tables"]["ChartDegrees"]}];
    jacobian = Map[finiteFieldDeferredForcingRationalAt[#, powers, prime, Length[chunk]] &,
      plan["Tables"]["Jacobian"], {2}];
    If[! FreeQ[jacobian, $Failed, {3}], Return[<|"Status" -> "DeferredForcingSingularJacobian"|>, Module]];
    masks = Table[multiquadraticMaskFactor[g, #["RootValues"]], {g, 0, gradeCount - 1}] & /@ preflights;
    Do[Module[{av = Mod[batch["BBarBatch"][[b]] . masks[[b]], prime]},
      $finiteFieldDeferredForcingImageCache[cacheKeys[[chunk[[b]]]]] =
        {Mod[Mod[av[[1]] jacobian[[1, 1, b]], prime] + Mod[av[[2]] jacobian[[2, 1, b]], prime], prime],
         Mod[Mod[av[[1]] jacobian[[1, 2, b]], prime] + Mod[av[[2]] jacobian[[2, 2, b]], prime], prime]}],
      {b, Length[chunk]}],
    {chunk, Partition[missing, UpTo[Min[$finiteFieldDeferredForcingBatchLimit,
      Floor[4096/Lookup[plan["Provider"], "GradeCount", 8]]]]]}];
  <|"Status" -> "OK",
    "Values" -> Lookup[$finiteFieldDeferredForcingImageCache, cacheKeys],
    "BatchedImages" -> Length[missing],
    "BatchSeconds" -> batchSeconds,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

(* rational interpolation in one variable modulo p: one nullspace at the
   degree bound, reduced by the gcd, validated on held-out points *)
finiteFieldDeferredForcingLineFit[data_List, bound_Integer, prime_Integer, t_Symbol] := Module[
  {construction, validation, matrix, nullspace, vector, numPoly, denPoly, g},
  If[Length[data] < 2 bound + 6, Return[$Failed]];
  construction = Take[data, 2 bound + 2]; validation = Drop[data, 2 bound + 2];
  matrix = Table[Join[Table[PowerMod[datum[[1]], power, prime], {power, 0, bound}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime], prime], {power, 0, bound}]],
    {datum, construction}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[nullspace === {}, Return[$Failed]];
  vector = First[nullspace];
  numPoly = FromDigits[Reverse[vector[[1 ;; bound + 1]]], t];
  denPoly = FromDigits[Reverse[vector[[bound + 2 ;;]]], t];
  If[denPoly === 0, Return[$Failed]];
  g = PolynomialGCD[numPoly, denPoly, Modulus -> prime];
  numPoly = PolynomialQuotient[numPoly, g, t, Modulus -> prime];
  denPoly = PolynomialQuotient[denPoly, g, t, Modulus -> prime];
  If[! AllTrue[validation, Mod[denPoly /. t -> #[[1]], prime] =!= 0 &&
      Mod[(numPoly /. t -> #[[1]]) - #[[2]] (denPoly /. t -> #[[1]]), prime] === 0 &],
    Return[$Failed]];
  <|"Numerator" -> numPoly, "Denominator" -> denPoly,
    "Degrees" -> {Exponent[numPoly, t], Exponent[denPoly, t]}|>
];

(* A source root whose square becomes a perfect square under the chart map
   reaches the candidates as Sqrt[p^2/q^2]: reduced to p/q (the sign is
   irrelevant for a factor candidate; an irreducible radical is left and its
   piece dropped, which the census's degree consistency then reports). *)
finiteFieldDeferredForcingPolynomialRoot[poly_] := Module[{factors = Rest[FactorList[poly]]},
  If[AllTrue[factors[[All, 2]], EvenQ], Times @@ (Power[#[[1]], #[[2]]/2] & /@ factors), $Failed]];
finiteFieldDeferredForcingReduceRadicals[expr_, sign_Integer: 1] := expr //.
  Power[s_, exponent_Rational /; Denominator[exponent] == 2] :> With[{t = Together[s]},
    With[{n = finiteFieldDeferredForcingPolynomialRoot[Numerator[t]],
        d = finiteFieldDeferredForcingPolynomialRoot[Denominator[t]]},
      If[n === $Failed || d === $Failed, Power[s, exponent], sign Power[n/d, 2 exponent]]]];

(* the structural superset of the pulled-back denominator factors *)
finiteFieldDeferredForcingCandidateFactors[plan_Association] := Module[
  {records, operands, basesOf, sourceFactors, subst, X, Y, epsilon, pieces},
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"]; subst = plan["Subst"];
  records = Lookup[plan["Preparation"], "Records", {}];
  (* the operands and the terms' coefficients: both carry denominators *)
  operands = DeleteDuplicates[Flatten[{Lookup[#, "Operands", {}], Lookup[#, "Coefficient", 1]} & /@
    Flatten[Lookup[records, "Terms", {}]]]];
  (* every denominator base at every level (Denominator is structural and
     misses the denominators nested inside sums: CF303 (25,18)'s missing
     quartic and degree-7 factors), radicals' squares included *)
  basesOf[expr_] := Module[{den = Denominator[expr], list},
    list = If[Head[den] === Times, List @@ den, {den}];
    Select[Join[Replace[list, Power[base_, _Integer] :> base, {1}],
      Cases[expr, Power[base_, exponent_?Negative] :> base, {0, Infinity}]], ! NumericQ[#] &]];
  sourceFactors = DeleteDuplicates[Flatten[(First /@ Rest[FactorList[#]]) & /@
    DeleteDuplicates[Flatten[basesOf /@ operands]]]];
  (* a factor a + b r is inverted in the multiquadratic algebra through its
     norm a^2 - b^2 r^2, which pulls back to (a q + b p)(a q - b p)/q^2 for
     r -> p/q: both sign variants are candidates (CF303 (25,18): the
     conjugate variants were the missing quartic and degree-7 factors) *)
  pieces = Join[Together[finiteFieldDeferredForcingReduceRadicals[# /. subst, 1]] & /@ sourceFactors,
    Together[finiteFieldDeferredForcingReduceRadicals[# /. subst, -1]] & /@ sourceFactors];
  pieces = Join[Numerator /@ pieces, Denominator /@ pieces,
    Denominator /@ Together /@ subst[[All, 2]],
    Denominator /@ Together /@ plan["RootImages"],
    Numerator /@ Together /@ plan["RootImages"],
    Denominator /@ Flatten[Together /@ plan["Jacobian"]],
    Numerator /@ Flatten[Together /@ plan["Jacobian"]]];
  pieces = DeleteDuplicates[Flatten[(First /@ Rest[FactorList[#]]) & /@
    Select[pieces, ! NumericQ[#] &]]];
  pieces = Select[pieces, ! FreeQ[#, X | Y] && PolynomialQ[#, {X, Y, epsilon}] &];
  DeleteDuplicates[pieces, TrueQ[Together[#1 - #2] === 0] || TrueQ[Together[#1 + #2] === 0] &]
];

(* The census: candidate factors, their maximal pole orders over the
   entries and the forcing's degree at infinity, from two random lines
   (a + t, b + s t) in the chart at a random regulator image. *)
Options[finiteFieldDeferredForcingCensus] = {
  "DegreeBound" -> 110, "Seed" -> 20260902};
finiteFieldDeferredForcingCensus[key_String, prime_Integer,
    OptionsPattern[]] := Module[
  {plan, started = AbsoluteTime[], candidates, X, Y, epsilon, bound, t, lineCount,
   epsilonMod, lineCensus, results, letters, powers, infinity},
  plan = Lookup[$finiteFieldDeferredForcingRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredForcingPlanUnknown"|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"];
  bound = OptionValue["DegreeBound"]; lineCount = 2 bound + 20;
  t = Symbol["FeynFacet`Private`deferredForcingLineT"];
  candidates = finiteFieldDeferredForcingCandidateFactors[plan];
  lineCensus[seed_] := Module[{a0, b0, slope, tValues, images, evaluated, fits, factorLines,
      multiplicity, entryPowers},
    BlockRandom[SeedRandom[seed];
      {a0, b0, slope} = RandomInteger[{2, prime - 2}, 3];
      epsilonMod = RandomInteger[{2, prime - 2}]];
    tValues = Table[Mod[a0 + 7 k, prime], {k, lineCount}];
    images = Table[{Mod[a0 + tv, prime], Mod[b0 + slope tv, prime], epsilonMod}, {tv, tValues}];
    evaluated = finiteFieldDeferredForcingImages[key, prime, images];
    If[Lookup[evaluated, "Status", None] =!= "OK", Return[evaluated, Module]];
    fits = Table[finiteFieldDeferredForcingLineFit[
        Table[{tValues[[k]], Flatten[evaluated["Values"][[k]]][[entry]]}, {k, lineCount}],
        bound, prime, t], {entry, 2 Times @@ plan["Dimensions"]}];
    If[MemberQ[fits, $Failed], Return[<|"Status" -> "DeferredForcingLineFitFailed"|>, Module]];
    factorLines = PolynomialMod[Expand[# /. {X -> a0 + t, Y -> b0 + slope t, epsilon -> epsilonMod}], prime] & /@ candidates;
    multiplicity[denominator_, factorLine_] := Module[{den = Expand[denominator], count = 0, q, r},
      If[factorLine === 0 || FreeQ[factorLine, t], Return[0]];
      While[Exponent[den, t] >= Exponent[factorLine, t],
        {q, r} = PolynomialQuotientRemainder[den, factorLine, t, Modulus -> prime];
        If[r =!= 0, Break[]]; den = q; count++];
      count];
    entryPowers = Table[Table[multiplicity[fit["Denominator"], line], {line, factorLines}], {fit, fits}];
    <|"Status" -> "OK",
      "MaxPowers" -> (Max /@ Transpose[entryPowers]),
      "Infinity" -> Max[Table[fit["Degrees"][[1]] - fit["Degrees"][[2]], {fit, fits}]],
      "LineDegrees" -> Lookup[fits, "Degrees"],
      "DegreeConsistent" -> And @@ Table[
        Total[entryPowers[[k]] (Exponent[#, t] & /@ factorLines)] === fits[[k]]["Degrees"][[2]],
        {k, Length[fits]}]|>];
  results = lineCensus /@ {OptionValue["Seed"], OptionValue["Seed"] + 1};
  If[AnyTrue[results, Lookup[#, "Status", None] =!= "OK" &],
    Return[FirstCase[results, r_ /; Lookup[r, "Status", None] =!= "OK"]]];
  If[results[[1]]["MaxPowers"] =!= results[[2]]["MaxPowers"] ||
      results[[1]]["Infinity"] =!= results[[2]]["Infinity"] ||
      ! TrueQ[results[[1]]["DegreeConsistent"]] || ! TrueQ[results[[2]]["DegreeConsistent"]],
    Return[<|"Status" -> "DeferredForcingCensusLinesDisagree", "Lines" -> results|>]];
  powers = results[[1]]["MaxPowers"];
  letters = Pick[candidates, Table[powers[[k]] > 0 && FreeQ[candidates[[k]], epsilon], {k, Length[candidates]}]];
  <|"Status" -> "OK", "Key" -> key, "Prime" -> prime,
    "Letters" -> letters,
    "GaugeFactorPowers" -> Select[Transpose[{candidates, powers}], Last[#] > 1 &],
    "ForcingInfinityDegree" -> results[[1]]["Infinity"],
    "LineDegrees" -> results[[1]]["LineDegrees"],
    "CandidateCount" -> Length[candidates],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

(* the numerical verifier's identity with the DAG image in place of the
   placeholder forcing: d G - eps (e G - G c) - bbar + eps Sum K dlog == 0
   at random points modulo a fresh prime; every regular point must vanish.
   Everything is evaluated from coefficient tables (derivatives by exponent
   shift), so the 64751-leaf chart gauge of CF300 (12,7) is never
   differentiated or substituted symbolically (20 s per check before). *)
finiteFieldDeferredForcingDerivativeRules[rules_List, index_Integer] :=
  Cases[rules, (exponents_List -> coefficient_) /; exponents[[index]] > 0 :>
    (exponents - UnitVector[Length[exponents], index] -> coefficient exponents[[index]])];
finiteFieldDeferredForcingResidualQ[key_String, {e_, c_}, gauge_, alphabet_List,
    residueMatrices_List, pointCount_Integer: 16] := Module[
  {plan, X, Y, epsilon, vars, prime, points, images, started = AbsoluteTime[],
   gaugeTables, eTables, cTables, letterTables, residueTables, residues, degrees, powers, poly, bad = {},
   inverse, at, dAt, dlogAt, gaugeValues, gaugeDerivatives, eValues, cValues, dlogValues,
   epsValues, product, residual, good, ok, dims, tableSeconds},
  plan = Lookup[$finiteFieldDeferredForcingRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredForcingPlanUnknown"|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"]; vars = {X, Y, epsilon};
  If[! FreeQ[{e, c, gauge, alphabet}, Power[_, _Rational]],
    Return[<|"Status" -> "DeferredForcingResidualRadical"|>]];
  dims = Dimensions[gauge];
  tableSeconds = First[AbsoluteTiming[
    gaugeTables = Map[finiteFieldDeferredForcingTable[#, vars] &, gauge, {2}];
    eTables = Map[finiteFieldDeferredForcingTable[#, vars] &, e, {3}];
    cTables = Map[finiteFieldDeferredForcingTable[#, vars] &, c, {3}];
    letterTables = finiteFieldDeferredForcingTable[#, vars] & /@ alphabet;
    (* the residue matrices may carry eps (the verifier reports ResiduesEpsFree separately) *)
    residueTables = Map[finiteFieldDeferredForcingTable[#, vars] &, residueMatrices, {3}]]];
  prime = RandomPrime[{2^30, 2^31 - 1}];
  points = Table[RandomInteger[{3, prime - 3}, 3], {pointCount}];
  images = finiteFieldDeferredForcingImages[key, prime, points];
  If[Lookup[images, "Status", None] =!= "OK", Return[images]];
  degrees = Max /@ Transpose[Join[ConstantArray[0, {1, 3}],
    Cases[{gaugeTables, eTables, cTables, letterTables, residueTables}, (exponents_List -> _) :> exponents, Infinity]]];
  powers = MapThread[finiteFieldDeferredForcingPowers[#1, #2, prime] &, {Transpose[points], degrees}];
  poly[rules_] := finiteFieldDeferredForcingPolynomialAt[rules, powers, prime, pointCount];
  (* a vanishing denominator marks the point as a pole (dropped, as before) *)
  inverse[values_] := (bad = Join[bad, Flatten[Position[values, 0, {1}, Heads -> False]]];
    PowerMod[values /. 0 -> 1, -1, prime]);
  at[{rn_, rd_}] := Mod[poly[rn] inverse[poly[rd]], prime];
  dAt[{rn_, rd_}, mu_] := With[{n = poly[rn], d = poly[rd],
      dn = poly[finiteFieldDeferredForcingDerivativeRules[rn, mu]],
      dd = poly[finiteFieldDeferredForcingDerivativeRules[rd, mu]]},
    With[{inv = inverse[d]}, Mod[Mod[Mod[dn d, prime] - Mod[n dd, prime], prime] Mod[inv inv, prime], prime]]];
  dlogAt[{rn_, rd_}, mu_] := With[{n = poly[rn], d = poly[rd],
      dn = poly[finiteFieldDeferredForcingDerivativeRules[rn, mu]],
      dd = poly[finiteFieldDeferredForcingDerivativeRules[rd, mu]]},
    Mod[Mod[dn inverse[n], prime] - Mod[dd inverse[d], prime], prime]];
  gaugeValues = Map[at, gaugeTables, {2}];
  gaugeDerivatives = Table[Map[dAt[#, mu] &, gaugeTables, {2}], {mu, 2}];
  eValues = Map[at, eTables, {3}]; cValues = Map[at, cTables, {3}];
  residues = Map[at, residueTables, {3}];
  dlogValues = Table[dlogAt[letterTables[[a]], mu], {a, Length[alphabet]}, {mu, 2}];
  epsValues = points[[All, 3]];
  (* matrix products with the point index innermost *)
  product[a_, b_] := Table[Mod[Total[Table[Mod[a[[i, k]] b[[k, j]], prime], {k, Length[b]}]], prime],
    {i, Length[a]}, {j, Length[First[b]]}];
  residual = Table[Mod[
      gaugeDerivatives[[mu]] -
        Map[Mod[epsValues #, prime] &, Mod[product[eValues[[mu]], gaugeValues] - product[gaugeValues, cValues[[mu]]], prime], {2}] -
        Transpose[images["Values"][[All, mu]], {3, 1, 2}] +
        Map[Mod[epsValues #, prime] &,
          Mod[Sum[Map[Mod[dlogValues[[a, mu]] #, prime] &, residues[[a]], {2}], {a, Length[alphabet]}], prime], {2}],
      prime], {mu, 2}];
  good = Complement[Range[pointCount], bad];
  ok = Length[good] >= Ceiling[pointCount/2] &&
    Flatten[residual[[All, All, All, good]]] === ConstantArray[0, 2 Times @@ dims Length[good]];
  <|"Status" -> "OK", "ResidualZero" -> ok, "Prime" -> prime,
    "Points" -> Length[good], "TableSeconds" -> tableSeconds,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

End[];
