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

(* one preflight per image {x, y, epsMod}: source point, root squares and
   root values modulo p; a point where the chart map or a root image has a
   pole is a typed rejection of the whole request *)
finiteFieldDeferredForcingPreflights[plan_Association, prime_Integer,
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
  {plan, preflights, batch, X, Y, epsilon, gradeCount, jacobian, started = AbsoluteTime[]},
  plan = Lookup[$finiteFieldDeferredForcingRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredForcingPlanUnknown"|>]];
  If[images === {}, Return[<|"Status" -> "OK", "Values" -> {}, "Seconds" -> 0.|>]];
  preflights = finiteFieldDeferredForcingPreflights[plan, prime, images];
  If[AssociationQ[preflights], Return[preflights]];
  batch = multiquadraticStripNativeDeferredEvaluateBatch[plan["Provider"], preflights,
    "Threads" -> Clip[$ProcessorCount, {1, 4}]];
  If[Lookup[batch, "Status", None] =!= "MultiquadraticNativeDeferredBatchV1",
    Return[<|"Status" -> "DeferredForcingBatchFailed", "Detail" -> batch|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"];
  gradeCount = batch["GradeCount"]; jacobian = plan["Jacobian"];
  <|"Status" -> "OK",
    "Values" -> Table[Module[{image = images[[b]], rv = preflights[[b]]["RootValues"],
        channels = batch["BBarBatch"][[b]], av, jv, values},
      values = <|X -> image[[1]], Y -> image[[2]], epsilon -> image[[3]]|>;
      av = Map[Mod[Total[Table[Mod[#[[g + 1]] multiquadraticMaskFactor[g, rv], prime],
        {g, 0, gradeCount - 1}]], prime] &, channels, {3}];
      jv = Map[finiteFieldDeferredForcingModAt[#, values, prime] &, jacobian, {2}];
      If[MemberQ[Flatten[jv], $Failed], Return[<|"Status" -> "DeferredForcingSingularJacobian"|>, Module]];
      {Mod[av[[1]] jv[[1, 1]] + av[[2]] jv[[2, 1]], prime],
       Mod[av[[1]] jv[[1, 2]] + av[[2]] jv[[2, 2]], prime]}], {b, Length[images]}],
    "BatchSeconds" -> batch["Seconds"], "Seconds" -> N[AbsoluteTime[] - started]|>
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

(* the structural superset of the pulled-back denominator factors *)
finiteFieldDeferredForcingCandidateFactors[plan_Association] := Module[
  {records, operands, basesOf, sourceFactors, subst, X, Y, epsilon, pieces},
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"]; subst = plan["Subst"];
  records = Lookup[plan["Preparation"], "Records", {}];
  operands = DeleteDuplicates[Flatten[Lookup[#, "Operands", {}] & /@
    Flatten[Lookup[records, "Terms", {}]]]];
  basesOf[expr_] := Module[{den = Denominator[expr], list},
    list = If[Head[den] === Times, List @@ den, {den}];
    Select[Replace[list, Power[base_, _Integer] :> base, {1}], ! NumericQ[#] &]];
  sourceFactors = DeleteDuplicates[Flatten[(First /@ Rest[FactorList[#]]) & /@
    DeleteDuplicates[Flatten[basesOf /@ operands]]]];
  pieces = Together[# /. subst] & /@ sourceFactors;
  pieces = Join[Numerator /@ pieces, Denominator /@ pieces,
    Denominator /@ Together /@ subst[[All, 2]],
    Denominator /@ Together /@ plan["RootImages"],
    Denominator /@ Flatten[Together /@ plan["Jacobian"]],
    Numerator /@ Flatten[Together /@ plan["Jacobian"]]];
  pieces = DeleteDuplicates[Flatten[(First /@ Rest[FactorList[#]]) & /@
    Select[pieces, ! NumericQ[#] &]]];
  pieces = Select[pieces, ! FreeQ[#, X | Y] &];
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
   at random points modulo a fresh prime; every point must vanish *)
finiteFieldDeferredForcingResidualQ[key_String, {e_, c_}, gauge_, alphabet_List,
    residueMatrices_List, pointCount_Integer: 16] := Module[
  {plan, X, Y, epsilon, variables, dlog, symbolic, prime, points, images, values, ok = True,
   started = AbsoluteTime[], evaluate, tries = 0},
  plan = Lookup[$finiteFieldDeferredForcingRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredForcingPlanUnknown"|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"]; variables = {X, Y};
  dlog = Table[Together[D[Log[alphabet[[a]]], variables[[mu]]]], {a, Length[alphabet]}, {mu, 2}];
  symbolic = Table[D[gauge, variables[[mu]]] - epsilon (e[[mu]].gauge - gauge.c[[mu]]) +
    epsilon Sum[residueMatrices[[a]] dlog[[a, mu]], {a, Length[alphabet]}], {mu, 2}];
  prime = RandomPrime[{2^30, 2^31 - 1}];
  evaluate[expr_, pt_] := Module[{v = Quiet[Check[Together[expr /. pt], $Failed]]},
    If[! MatchQ[v, _Integer | _Rational] || Mod[Denominator[v], prime] === 0, $Failed,
      Mod[Numerator[v] PowerMod[Denominator[v], -1, prime], prime]]];
  points = Table[RandomInteger[{3, prime - 3}, 3], {pointCount}];
  images = finiteFieldDeferredForcingImages[key, prime, points];
  If[Lookup[images, "Status", None] =!= "OK", Return[images]];
  values = Table[Module[{pt = Thread[{X, Y, epsilon} -> points[[k]]], sym},
      sym = Map[evaluate[#, pt] &, symbolic, {3}];
      If[! FreeQ[sym, $Failed], Missing["Pole"],
        Mod[Flatten[sym] - Flatten[images["Values"][[k]]], prime]]], {k, pointCount}];
  values = DeleteCases[values, _Missing];
  ok = Length[values] >= Ceiling[pointCount/2] && AllTrue[values, # === ConstantArray[0, Length[#]] &];
  <|"Status" -> "OK", "ResidualZero" -> ok, "Prime" -> prime,
    "Points" -> Length[values], "Seconds" -> N[AbsoluteTime[] - started]|>
];

End[];
