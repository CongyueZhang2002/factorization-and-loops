(* ::Package:: *)

(*
  External A2 prototype: incremental regulator sampling.

  This file is intentionally outside FeynFacet.  It implements the sampling
  policy assigned in fable_ff_round2_assignment_2026-08-21.md without editing
  package code:

    - construct a provisional rational interpolation from a small prefix;
    - test it at fresh held-out regulator images;
    - promote failed held-outs into construction data and refit only the
      unresolved/degree-growing coordinates;
    - accept a modular interpolation only after a fresh held-out round passes;
    - retain the deterministic 2(deg numerator + deg denominator)+1 bound as
      metadata, while marking the actual certification as probabilistic until
      an unseen-prime residual and the final exact Pfaffian check pass.

  Every failure grows the data set or rejects an unlucky prime.  No failed
  held-out check is accepted.
*)

ClearAll[
  CodexA2EpsilonMod,
  CodexA2EvaluateCoefficients,
  CodexA2TrimCoefficients,
  CodexA2ReduceRationalPair,
  CodexA2PairQ,
  CodexA2FitSplit,
  CodexA2FitCoordinateCandidates,
  CodexA2FitCoordinate,
  CodexA2IncrementalInterpolate,
  CodexA2CanonicalizeSamples,
  CodexA2SamplesFromInterpolation,
  CodexA2InterpolationCoreSameQ,
  CodexA2ReconstructionView,
  CodexA2LiftCandidate,
  CodexA2UnseenPrimeResidualCheck
];

CodexA2EpsilonMod[value_, prime_Integer] := Module[{denominator},
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[value] PowerMod[denominator, -1, prime], prime]
];

CodexA2EvaluateCoefficients[coefficients_List, value_Integer,
    prime_Integer] := Fold[Mod[#1 value + #2, prime] &, 0,
  Reverse[coefficients]];

CodexA2TrimCoefficients[coefficients_List] := Module[{nonzero},
  nonzero = Select[Range[Length[coefficients]],
    coefficients[[#]] =!= 0 &];
  If[nonzero === {}, {0}, Take[coefficients, Last[nonzero]]]
];

CodexA2ReduceRationalPair[numeratorInput_List, denominatorInput_List,
    prime_Integer] := Module[
  {z, numerator, denominator, divisor, numeratorCoefficients,
   denominatorCoefficients, normalization},
  numerator = FromDigits[Reverse[numeratorInput], z];
  denominator = FromDigits[Reverse[denominatorInput], z];
  divisor = PolynomialGCD[numerator, denominator, Modulus -> prime];
  numerator = PolynomialQuotient[numerator, divisor, z,
    Modulus -> prime];
  denominator = PolynomialQuotient[denominator, divisor, z,
    Modulus -> prime];
  numeratorCoefficients = CodexA2TrimCoefficients[
    Mod[CoefficientList[numerator, z], prime]];
  denominatorCoefficients = CodexA2TrimCoefficients[
    Mod[CoefficientList[denominator, z], prime]];
  If[denominatorCoefficients === {0}, Return[$Failed]];
  normalization = PowerMod[Last[denominatorCoefficients], -1, prime];
  {Mod[normalization numeratorCoefficients, prime],
   Mod[normalization denominatorCoefficients, prime]}
];

CodexA2PairQ[pair_Association, data_List, prime_Integer] :=
  AllTrue[data, Function[datum, Module[{numerator, denominator},
    numerator = CodexA2EvaluateCoefficients[
      pair["Numerator"], datum[[1]], prime];
    denominator = CodexA2EvaluateCoefficients[
      pair["Denominator"], datum[[1]], prime];
    denominator =!= 0 &&
      Mod[numerator - datum[[2]] denominator, prime] === 0
  ]]];
CodexA2PairQ[_, _, _] := False;

CodexA2FitSplit[data_List, prime_Integer, numeratorDegree_Integer,
    denominatorDegree_Integer] := Module[
  {matrix, nullspace, vector, pair, degrees},
  matrix = Table[Join[
      Table[PowerMod[datum[[1]], power, prime],
        {power, 0, numeratorDegree}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime], prime],
        {power, 0, denominatorDegree}]],
    {datum, data}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[Length[nullspace] =!= 1, Return[$Failed]];
  vector = First[nullspace];
  If[! AnyTrue[vector[[numeratorDegree + 2 ;;]], # =!= 0 &],
    Return[$Failed]];
  pair = CodexA2ReduceRationalPair[
    vector[[1 ;; numeratorDegree + 1]],
    vector[[numeratorDegree + 2 ;;]], prime];
  If[pair === $Failed, Return[$Failed]];
  degrees = Length[#] - 1 & /@ pair;
  If[! CodexA2PairQ[
      <|"Numerator" -> pair[[1]], "Denominator" -> pair[[2]]|>,
      data, prime], Return[$Failed]];
  <|
    "Numerator" -> pair[[1]],
    "Denominator" -> pair[[2]],
    "Degrees" -> degrees,
    "ConstructionNullity" -> 1,
    "ConstructionPointCount" -> Length[data],
    "DeterministicUniquenessPointRequirement" -> 2 Total[degrees] + 1
  |>
];

CodexA2FitCoordinateCandidates[data_List, prime_Integer,
    maximumTotalDegree_Integer] := Module[
  {totalDegreeCeiling, totalDegree, candidates},
  If[data === {} || ! AllTrue[data,
      MatchQ[#, {_Integer, _Integer}] &], Return[$Failed]];
  If[AllTrue[data, Last[#] === 0 &],
    Return[{<|
      "Numerator" -> {0}, "Denominator" -> {1},
      "Degrees" -> {-Infinity, 0}, "ConstructionNullity" -> 1,
      "ConstructionPointCount" -> Length[data],
      "DeterministicUniquenessPointRequirement" -> 1
    |>}]];
  totalDegreeCeiling = Min[maximumTotalDegree, Length[data] - 1];
  Do[
    candidates = DeleteCases[
      Table[CodexA2FitSplit[data, prime, numeratorDegree,
        totalDegree - numeratorDegree],
        {numeratorDegree, 0, totalDegree}],
      $Failed];
    candidates = DeleteDuplicatesBy[candidates,
      Lookup[#, {"Numerator", "Denominator", "Degrees"}] &];
    If[candidates =!= {}, Break[]],
    {totalDegree, 0, totalDegreeCeiling}];
  If[candidates === {}, $Failed, candidates]
];

CodexA2FitCoordinate[data_List, prime_Integer,
    maximumTotalDegree_Integer] := Module[{candidates},
  candidates = CodexA2FitCoordinateCandidates[
    data, prime, maximumTotalDegree];
  If[ListQ[candidates] && candidates =!= {}, First[candidates], $Failed]
];

Options[CodexA2IncrementalInterpolate] = {
  "InitialConstructionCount" -> 4,
  "HeldOutCount" -> 3,
  "MaximumTotalDegree" -> 22,
  "ExpectedDegrees" -> Automatic
};

CodexA2IncrementalInterpolate[canonicalSamples_List, prime_Integer,
    OptionsPattern[]] := Module[
  {initialConstructionCount, heldOutCount, maximumTotalDegree,
   expectedDegrees, coordinateCount, constructionIndices, consumed,
   candidateSets, candidates, active, fitted, unresolved,
   validationIndices, validationSurvivors, failures, ambiguous,
   degreeMismatches, trace = {},
   round = 0, interpolationSeconds = 0., fitSeconds,
   finalInterpolations, degreeHistogram, deterministicShortfall,
   loopResult},

  initialConstructionCount = OptionValue["InitialConstructionCount"];
  heldOutCount = OptionValue["HeldOutCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  expectedDegrees = OptionValue["ExpectedDegrees"];
  If[! PrimeQ[prime] || canonicalSamples === {} ||
      ! AllTrue[canonicalSamples, AssociationQ] ||
      ! IntegerQ[initialConstructionCount] ||
        initialConstructionCount < 2 ||
      ! IntegerQ[heldOutCount] || heldOutCount < 2 ||
      ! IntegerQ[maximumTotalDegree] || maximumTotalDegree < 0 ||
      Length[canonicalSamples] < initialConstructionCount + heldOutCount,
    Return[$Failed]];
  coordinateCount = Length[First[canonicalSamples]["Values"]];
  If[coordinateCount < 1 ||
      ! AllTrue[canonicalSamples,
        VectorQ[Lookup[#, "Values", {}], IntegerQ] &&
          Length[#Values] === coordinateCount &], Return[$Failed]];
  If[expectedDegrees =!= Automatic &&
      (! ListQ[expectedDegrees] ||
        Length[expectedDegrees] =!= coordinateCount), Return[$Failed]];

  constructionIndices = Range[initialConstructionCount];
  consumed = initialConstructionCount;
  candidateSets = ConstantArray[$Failed, coordinateCount];

  loopResult = Catch[While[True,
    round++;
    (* Retain every degree split that predicts all construction data already
       promoted into the fit.  A coordinate is refit only when no retained
       split survives. *)
    Do[If[ListQ[candidateSets[[coordinate]]],
      candidateSets[[coordinate]] = Select[
        candidateSets[[coordinate]],
        CodexA2PairQ[#,
          Table[{canonicalSamples[[index, "EpsilonMod"]],
            canonicalSamples[[index, "Values", coordinate]]},
            {index, constructionIndices}], prime] &];
      If[candidateSets[[coordinate]] === {},
        candidateSets[[coordinate]] = $Failed]],
      {coordinate, coordinateCount}];
    active = Select[Range[coordinateCount], Function[coordinate,
      candidateSets[[coordinate]] === $Failed]];

    (* The explicit Table below is intentionally used instead of depending on
       the compact active-test expression above for fitting. *)
    {fitSeconds, fitted} = AbsoluteTiming[Association@Table[
      coordinate -> CodexA2FitCoordinateCandidates[
        Table[{canonicalSamples[[index, "EpsilonMod"]],
          canonicalSamples[[index, "Values", coordinate]]},
          {index, constructionIndices}],
        prime, maximumTotalDegree],
      {coordinate, active}]];
    interpolationSeconds += fitSeconds;
    Do[candidateSets[[coordinate]] = fitted[coordinate],
      {coordinate, active}];
    unresolved = Select[Range[coordinateCount],
      candidateSets[[#]] === $Failed &];
    AppendTo[trace, <|
      "Round" -> round,
      "Event" -> "Fit",
      "ConstructionIndices" -> constructionIndices,
      "ConstructionCount" -> Length[constructionIndices],
      "RefitCoordinateCount" -> Length[active],
      "UnresolvedCoordinateCount" -> Length[unresolved],
      "FitSeconds" -> fitSeconds
    |>];

    If[unresolved =!= {},
      If[consumed >= Length[canonicalSamples],
        Throw[<|"Status" -> "GrowRequired",
          "ConsumedSampleCount" -> consumed,
          "ConstructionIndices" -> constructionIndices,
          "UnresolvedCoordinates" -> unresolved,
          "Trace" -> trace|>, "CodexA2IncrementalExit"]];
      consumed++;
      AppendTo[constructionIndices, consumed];
      Continue[]];

    If[consumed + heldOutCount > Length[canonicalSamples],
      Throw[<|"Status" -> "MoreHeldOutSamplesRequired",
        "ConsumedSampleCount" -> consumed,
        "RequiredAdditionalSampleCount" ->
          consumed + heldOutCount - Length[canonicalSamples],
        "Trace" -> trace|>, "CodexA2IncrementalExit"]];
    validationIndices = Range[consumed + 1, consumed + heldOutCount];
    validationSurvivors = Table[
      Select[candidateSets[[coordinate]], CodexA2PairQ[#,
        Table[{canonicalSamples[[index, "EpsilonMod"]],
          canonicalSamples[[index, "Values", coordinate]]},
          {index, validationIndices}], prime] &],
      {coordinate, coordinateCount}];
    failures = Select[Range[coordinateCount],
      validationSurvivors[[#]] === {} &];
    ambiguous = Select[Range[coordinateCount],
      Length[validationSurvivors[[#]]] > 1 &];
    AppendTo[trace, <|
      "Round" -> round,
      "Event" -> "HeldOutValidation",
      "ValidationIndices" -> validationIndices,
      "HeldOutCount" -> heldOutCount,
      "FailedCoordinateCount" -> Length[failures],
      "FailedCoordinates" -> failures,
      "AmbiguousCoordinateCount" -> Length[ambiguous],
      "AmbiguousCoordinates" -> ambiguous
    |>];
    consumed += heldOutCount;
    candidateSets = validationSurvivors;
    If[failures === {} && ambiguous === {}, Break[]];
    If[failures === {}, Continue[]];

    (* Grow, never accept: failed held-outs become construction data.  Only
       failed coordinates are invalidated; candidates that predicted the new
       data remain cached. *)
    constructionIndices = Join[constructionIndices, validationIndices];
    candidateSets[[failures]] = ConstantArray[$Failed, Length[failures]];
  ], "CodexA2IncrementalExit"];
  If[AssociationQ[loopResult], Return[loopResult]];

  candidates = First /@ candidateSets;

  degreeMismatches = If[expectedDegrees === Automatic, {},
    Select[Range[coordinateCount],
      candidates[[#, "Degrees"]] =!= expectedDegrees[[#]] &]];
  If[degreeMismatches =!= {},
    Return[<|
      "Status" -> "RejectPrimeDegreeProfileChanged",
      "ConsumedSampleCount" -> consumed,
      "DegreeMismatchCoordinates" -> degreeMismatches,
      "Trace" -> trace
    |>]];

  finalInterpolations = Map[
    Join[#, <|
      "ValidatedPointCount" -> consumed,
      "HeldOutPointCount" -> heldOutCount,
      "CertificationMode" -> "IncrementalHeldOutGrowOnFailure",
      (* Kept under the package key for transparent downstream auditing.  A2
         does not claim this deterministic bound has been met. *)
      "UniquenessPointRequirement" ->
        #["DeterministicUniquenessPointRequirement"]
    |>] &, candidates];
  degreeHistogram = Counts[Lookup[finalInterpolations, "Degrees"]];
  deterministicShortfall = Select[Range[coordinateCount],
    finalInterpolations[[#, "ValidatedPointCount"]] <
      finalInterpolations[[#, "DeterministicUniquenessPointRequirement"]] &];
  <|
    "Status" -> "HeldOutValidated",
    "Prime" -> prime,
    "SampleCount" -> consumed,
    "ConstructionCount" -> Length[constructionIndices],
    "ValidationCount" -> heldOutCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "InterpolationSeconds" -> interpolationSeconds,
    "UnresolvedCoordinates" -> {},
    "HeldOutChecksPassed" -> True,
    "DeterministicShortfallCoordinates" -> deterministicShortfall,
    "DegreeHistogram" -> degreeHistogram,
    "Interpolations" -> finalInterpolations,
    "Trace" -> trace
  |>
];

CodexA2CanonicalizeSamples[samples_List, prime_Integer,
    normalizationColumns_List] := Module[
  {genericSamples, normalized, grouped},
  If[samples === {} || ! AllTrue[samples, AssociationQ], Return[$Failed]];
  genericSamples = Select[samples,
    TrueQ[Lookup[#, "Consistent", False]] &&
      TrueQ[Lookup[#, "ParticularCheckZero", False]] &&
      TrueQ[Lookup[#, "NullspaceCheckZero", False]] &];
  If[Length[genericSamples] =!= Length[samples], Return[$Failed]];
  normalized = Table[With[{canonical = NormalizeEpsFormAffineSample[
      sample, normalizationColumns, prime]},
    If[canonical === $Failed, $Failed, <|
      "EpsilonValue" -> sample["EpsilonValue"],
      "EpsilonMod" -> CodexA2EpsilonMod[sample["EpsilonValue"], prime],
      "Values" -> canonical["ParticularSolution"]
    |>]], {sample, genericSamples}];
  If[MemberQ[normalized, $Failed], Return[$Failed]];
  grouped = GatherBy[normalized, #EpsilonMod &];
  If[AnyTrue[grouped,
      Length[DeleteDuplicates[Lookup[#, "Values"]]] =!= 1 &],
    Return[$Failed]];
  First /@ grouped
];

CodexA2SamplesFromInterpolation[interpolation_Association,
    epsilonValues_List] := Module[{prime, pairs, samples},
  prime = interpolation["Prime"];
  pairs = interpolation["Interpolations"];
  samples = Table[With[{epsilonMod = CodexA2EpsilonMod[value, prime]},
    If[epsilonMod === $Failed, $Failed, <|
      "EpsilonValue" -> value,
      "EpsilonMod" -> epsilonMod,
      "Values" -> Table[Module[{denominator},
        denominator = CodexA2EvaluateCoefficients[
          pair["Denominator"], epsilonMod, prime];
        If[denominator === 0, $Failed,
          Mod[CodexA2EvaluateCoefficients[
              pair["Numerator"], epsilonMod, prime]
            PowerMod[denominator, -1, prime], prime]]
      ], {pair, pairs}]
    |>]], {value, epsilonValues}];
  If[! FreeQ[samples, $Failed], $Failed, samples]
];

CodexA2InterpolationCoreSameQ[left_Association, right_Association] :=
  SameQ[
    KeyTake[#, {"Numerator", "Denominator", "Degrees"}] & /@
      left["Interpolations"],
    KeyTake[#, {"Numerator", "Denominator", "Degrees"}] & /@
      right["Interpolations"]
  ];

(* Convert a held-out-certified A2 record into a view accepted by the current
   exact lifting routine.  The original deterministic bound is preserved
   separately; this view is external-only and must be followed by an unseen-
   prime residual before the exact check. *)
CodexA2ReconstructionView[data_Association] := Module[{sampleCount},
  sampleCount = data["SampleCount"];
  Join[data, <|"Interpolations" ->
    (Join[#, <|
      "ValidatedPointCount" -> sampleCount,
      "UniquenessPointRequirement" -> sampleCount
    |>] & /@ data["Interpolations"])|>]
];

(* Lift only: this deliberately stops before either probabilistic or exact
   verification, so the certification order is held-out values, unseen prime,
   then VerifyEpsFormStrip.  It is an external copy of the algebraic lifting
   portion of ReconstructEpsFormStrip, not a package override. *)
CodexA2LiftCandidate[record_Association, modularData_List] := Module[
  {strip, variables, epsilon, bbar, primes, coordinateCount,
   combinedModulus, combined, liftedPairs, liftedVector,
   coefficientChecks, numeratorDegrees, gaugeDenominator,
   gaugeDenominatorDegrees, dimensions, upperDimension, lowerDimension,
   gaugeUnknownCount, residueCount, alphabet, residueMatrices, gauge,
   columnIndex, liftingSeconds},
  If[modularData === {} || ! AllTrue[modularData, AssociationQ] ||
      ! And @@ (KeyExistsQ[record, #] & /@
        {"Strip", "Variables", "Regulator"}), Return[$Failed]];
  primes = Lookup[modularData, "Prime", Missing["Prime"]];
  If[! DuplicateFreeQ[primes] || ! AllTrue[primes, PrimeQ] ||
      Length[DeleteDuplicates[Lookup[modularData,
        "GaugeUnknownCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "FreeResidueCount"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "GaugeNumeratorDegrees"]]] =!= 1 ||
      Length[DeleteDuplicates[Lookup[modularData,
        "NormalizationColumns"]]] =!= 1 ||
      Length[DeleteDuplicates[Length /@
        Lookup[modularData, "Interpolations"]]] =!= 1,
    Return[$Failed]];
  coordinateCount = Length[First[modularData]["Interpolations"]];
  combinedModulus = Times @@ primes;
  combined = Table[
    FeynFacet`Private`epsFormFiniteFieldCombineCoordinate[
      modularData[[All, "Interpolations", coordinate]], primes],
    {coordinate, coordinateCount}];
  If[MemberQ[combined, $Failed], Return[$Failed]];
  {liftingSeconds, liftedPairs} = AbsoluteTiming[Map[
    Function[data, <|
      "NumeratorCoefficients" ->
        (FeynFacet`Private`epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ data["Numerator"]),
      "DenominatorCoefficients" ->
        (FeynFacet`Private`epsFormFiniteFieldRationalReconstruct[
            #, combinedModulus] & /@ data["Denominator"])
      |>], combined]];
  If[! FreeQ[liftedPairs, $Failed], Return[$Failed]];
  coefficientChecks = MapThread[
    Function[{integers, rationals}, And[
      And @@ MapThread[
        Function[{integer, rational}, AllTrue[primes,
          FeynFacet`Private`epsFormFiniteFieldImageQ[
            integer, rational, #] &]],
        {integers["Numerator"],
          rationals["NumeratorCoefficients"]}],
      And @@ MapThread[
        Function[{integer, rational}, AllTrue[primes,
          FeynFacet`Private`epsFormFiniteFieldImageQ[
            integer, rational, #] &]],
        {integers["Denominator"],
          rationals["DenominatorCoefficients"]}]
      ]], {combined, liftedPairs}];
  If[! And @@ coefficientChecks, Return[$Failed]];
  strip = record["Strip"];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  bbar = strip[[3]];
  liftedVector = Together[
      FromDigits[Reverse[#NumeratorCoefficients], epsilon]/
        FromDigits[Reverse[#DenominatorCoefficients], epsilon]] & /@
    liftedPairs;
  numeratorDegrees = First[modularData]["GaugeNumeratorDegrees"];
  gaugeDenominator =
    FeynFacet`Private`epsFormFiniteFieldGaugeDenominator[
      bbar, variables];
  gaugeDenominatorDegrees = Exponent[gaugeDenominator, #] & /@ variables;
  dimensions = Dimensions[bbar[[1]]];
  {upperDimension, lowerDimension} = dimensions;
  gaugeUnknownCount = upperDimension lowerDimension
    (numeratorDegrees[[1]] + 1) (numeratorDegrees[[2]] + 1);
  alphabet = FeynFacet`Private`epsFormStripAlphabet[
    strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  residueCount = Length[alphabet] upperDimension lowerDimension;
  If[gaugeUnknownCount =!= First[modularData]["GaugeUnknownCount"] ||
      residueCount =!= First[modularData]["FreeResidueCount"] ||
      Length[liftedVector] =!= gaugeUnknownCount + residueCount,
    Return[$Failed]];
  columnIndex[i_, j_, px_, py_] :=
    (((i - 1) lowerDimension + (j - 1))
      (numeratorDegrees[[1]] + 1) + px)
      (numeratorDegrees[[2]] + 1) + py + 1;
  gauge = Table[
    Sum[liftedVector[[columnIndex[i, j, px, py]]]
        variables[[1]]^px variables[[2]]^py,
      {px, 0, numeratorDegrees[[1]]},
      {py, 0, numeratorDegrees[[2]]}]/gaugeDenominator,
    {i, upperDimension}, {j, lowerDimension}];
  residueMatrices = ArrayReshape[
    Drop[liftedVector, gaugeUnknownCount],
    {Length[alphabet], upperDimension, lowerDimension}];
  <|
    "Status" -> "LiftedUnverified",
    "Gauge" -> gauge,
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "Primes" -> primes,
    "CombinedModulus" -> combinedModulus,
    "NormalizationColumns" ->
      First[modularData]["NormalizationColumns"],
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeDenominatorDegrees" -> gaugeDenominatorDegrees,
    "GaugeNumeratorDegrees" -> numeratorDegrees,
    "CoefficientLiftChecks" -> coefficientChecks,
    "LiftingSeconds" -> liftingSeconds
  |>
];

Options[CodexA2UnseenPrimeResidualCheck] = {
  "EpsilonValues" -> {37/97, 41/103},
  "KinematicPoints" -> {{17, 29}, {43, 71}, {101, 131}}
};

CodexA2UnseenPrimeResidualCheck[record_Association,
    solution_Association, unseenPrime_Integer, OptionsPattern[]] := Module[
  {strip, variables, epsilon, e, c, bbar, gauge, alphabet,
   residueMatrices, dlog, residuals, epsilonValues, points, checks = {},
   value, point, substituted, rational, denominator, modular,
   start = AbsoluteTime[]},
  If[! PrimeQ[unseenPrime] ||
      ! And @@ (KeyExistsQ[record, #] & /@
        {"Strip", "Variables", "Regulator"}) ||
      ! And @@ (KeyExistsQ[solution, #] & /@
        {"Gauge", "Alphabet", "ResidueMatrices"}), Return[$Failed]];
  strip = record["Strip"];
  variables = record["Variables"];
  epsilon = record["Regulator"];
  {e, c, bbar} = strip;
  gauge = solution["Gauge"];
  alphabet = solution["Alphabet"];
  residueMatrices = solution["ResidueMatrices"];
  dlog = Table[D[Log[alphabet[[a]]], variables[[mu]]],
    {a, Length[alphabet]}, {mu, 2}];
  residuals = Table[
    D[gauge, variables[[mu]]] -
      epsilon (e[[mu]].gauge - gauge.c[[mu]]) - bbar[[mu]] +
      epsilon Sum[residueMatrices[[a]] dlog[[a, mu]],
        {a, Length[alphabet]}],
    {mu, 2}];
  epsilonValues = OptionValue["EpsilonValues"];
  points = OptionValue["KinematicPoints"];
  Do[
    substituted = Flatten[residuals] /.
      {epsilon -> value, variables[[1]] -> point[[1]],
       variables[[2]] -> point[[2]]};
    modular = Map[Function[entry,
      rational = Together[entry];
      denominator = Mod[Denominator[rational], unseenPrime];
      If[denominator === 0, Missing["SingularPoint"],
        Mod[Numerator[rational] PowerMod[denominator, -1, unseenPrime],
          unseenPrime]]], substituted];
    AppendTo[checks, <|"EpsilonValue" -> value,
      "Point" -> point, "Values" -> modular,
      "Zero" -> VectorQ[modular, # === 0 &]|>],
    {value, epsilonValues}, {point, points}];
  <|
    "Prime" -> unseenPrime,
    "CheckCount" -> Length[checks],
    "AllResidualsZero" -> AllTrue[checks, TrueQ[#Zero] &],
    "Checks" -> checks,
    "WallSeconds" -> AbsoluteTime[] - start
  |>
];
