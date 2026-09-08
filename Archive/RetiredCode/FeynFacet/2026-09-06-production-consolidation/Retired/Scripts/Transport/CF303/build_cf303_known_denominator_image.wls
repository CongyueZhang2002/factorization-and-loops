#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repositoryRoot = DirectoryName[scriptDirectory, 3];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 4,
  Print["usage: build_cf303_known_denominator_image.wls " <>
    "FIT_DIRECTORY SAMPLE_DIRECTORY HELD_OUT OUTPUT"];
  Quit[2]];
{fitDirectory, sampleDirectory, heldOutPath, outputPath} =
  ExpandFileName /@ arguments;
fits = Import[#, "RawJSON"] & /@ Sort[FileNames["q*.json", fitDirectory]];
samples = Import[#, "RawJSON"] & /@ SortBy[
  FileNames["p*.json", sampleDirectory],
  ToExpression[StringDrop[FileBaseName[#], 1]] &];
heldOut = Import[heldOutPath, "RawJSON"];
prime = heldOut["prime"];
If[Length[fits] < 2 || Length[samples] < 1 ||
    MemberQ[Lookup[fits, "prime"], prime] ||
    ! AllTrue[samples, Lookup[#, "prime", None] === prime &] ||
    Lookup[heldOut, "prime", None] =!= prime,
  Print["FAIL CF303KnownDenominatorInputs"];
  Quit[2]];
primes = Lookup[fits, "prime"];

keyString[mode_, order_, target_, mask_: 0] :=
  StringRiffle[ToString /@ {mode, order, target, mask}, ":"];
keys = Flatten[Table[keyString[mode, order, target],
  {mode, 7}, {order, -3, 4}, {target, {44, 45}}]];
recordsByFit = Association /@ Map[
  (Lookup[#, "key"] -> #) &, Lookup[fits, "coordinates"], {2}];
sampleValues[sample_] := Association[
  (keyString[Lookup[#, "mode_index"], Lookup[#, "epsilon_order"],
      Lookup[#, "target_master"],
      Lookup[#, "radical_mask_bits", 0]] -> Lookup[#, "value"]) & /@
    sample["normal_residue_projection"]];
valuesBySample = sampleValues /@ samples;
heldOutValues = sampleValues[heldOut];
abscissae = Lookup[samples, "p_mod_prime"];
heldOutPoint = heldOut["p_mod_prime"];

polynomialFrom[coefficients_] := coefficients .
  p^Range[0, Length[coefficients] - 1];
modularImage[value_, modulus_] := Mod[Numerator[value]*PowerMod[
  Mod[Denominator[value], modulus], -1, modulus], modulus];
polynomialImage[polynomial_, modulus_] := polynomialFrom[
  modularImage[#, modulus] & /@ CoefficientList[polynomial, p]];
polynomialValue[coefficients_, point_, modulus_] := Fold[
  Mod[#1*point + #2, modulus] &, 0, Reverse[coefficients]];

exactDenominator[records_] := Module[
  {denominators, firstPrime, modularFactors, liftProduct, remaining,
   factors = {}, candidate, result},
  denominators = polynomialFrom[#["denominator"]] & /@ records;
  If[Max[Exponent[#, p] & /@ denominators] === 0, Return[1]];
  firstPrime = First[primes];
  modularFactors = Rest[FactorList[First[denominators],
      Modulus -> firstPrime]];
  liftProduct[indices_] := Module[{exponents, modularPolynomial,
      liftedCoefficients, exactPolynomial, exponent},
    exponents = modularFactors[[indices, 2]];
    If[! SameQ @@ exponents, Return[$Failed]];
    exponent = First[exponents];
    modularPolynomial = PolynomialMod[Times @@
      modularFactors[[indices, 1]], firstPrime];
    liftedCoefficients = FeynFacet`Private`modularRationalReconstruct[
        #, firstPrime] & /@ CoefficientList[modularPolynomial, p];
    If[MemberQ[liftedCoefficients, $Failed], Return[$Failed]];
    exactPolynomial = polynomialFrom[liftedCoefficients];
    exactPolynomial = Expand[exactPolynomial/Coefficient[
      exactPolynomial, p, Exponent[exactPolynomial, p]]];
    If[And @@ MapThread[Function[{denominator, imagePrime},
        PolynomialRemainder[denominator,
          polynomialImage[exactPolynomial, imagePrime]^exponent, p,
          Modulus -> imagePrime] === 0], {denominators, primes}],
      <|"Indices" -> indices, "Factor" -> exactPolynomial,
        "Exponent" -> exponent|>, $Failed]
  ];
  remaining = Range[Length[modularFactors]];
  While[remaining =!= {},
    candidate = SelectFirst[Flatten[Table[
        liftProduct[#] & /@ Subsets[remaining, {size}],
        {size, 1, Min[6, Length[remaining]]}], 1],
      AssociationQ, Missing["NotFound"]];
    If[MissingQ[candidate], Return[$Failed]];
    AppendTo[factors, candidate];
    remaining = Complement[remaining, candidate["Indices"]]];
  result = Expand[Times @@
    ((#["Factor"]^#["Exponent"]) & /@ factors)];
  If[And @@ MapThread[Function[{denominator, imagePrime},
      Expand[polynomialImage[result, imagePrime] - denominator,
        Modulus -> imagePrime] === 0], {denominators, primes}],
    result, $Failed]
];

interpolatePolynomial[xs_, ys_, modulus_] := Module[
  {count = Length[xs], differences = ys, basis = {1}, result = {0},
   order, index, inverse, term, nextBasis},
  For[order = 2, order <= count, order++,
    For[index = count, index >= order, index--,
      inverse = PowerMod[Mod[xs[[index]] -
        xs[[index - order + 1]], modulus], -1, modulus];
      differences[[index]] = Mod[(differences[[index]] -
        differences[[index - 1]])*inverse, modulus]]];
  For[order = 1, order <= count, order++,
    term = Mod[differences[[order]]*basis, modulus];
    result = PadRight[result, Max[Length[result], Length[term]]] +
      PadRight[term, Max[Length[result], Length[term]]];
    result = Mod[result, modulus];
    nextBasis = ConstantArray[0, Length[basis] + 1];
    Do[
      nextBasis[[index]] = Mod[nextBasis[[index]] -
        xs[[order]]*basis[[index]], modulus];
      nextBasis[[index + 1]] = Mod[nextBasis[[index + 1]] +
        basis[[index]], modulus],
      {index, Length[basis]}];
    basis = nextBasis];
  result
];

denominatorCache = <||>;
buildRecord[key_] := Module[
  {records, degrees, signature, denominator, denominatorCoefficients,
   numeratorDegree, count, xs, functionValues, numeratorValues,
   numeratorCoefficients, heldOutDenominator, actual, expected},
  records = Lookup[recordsByFit, key];
  degrees = Lookup[records, "degrees"];
  If[! SameQ @@ degrees, Return[$Failed]];
  If[First[degrees] === {-1, 0}, Return[<|"key" -> key,
    "status" -> 0, "degrees" -> {-1, 0}, "consumed" -> 1,
    "numerator" -> {0}, "denominator" -> {1}|>]];
  signature = ToString[First[records]["denominator"], InputForm];
  denominator = Lookup[denominatorCache, signature, Missing["Absent"]];
  If[MissingQ[denominator],
    denominator = exactDenominator[records];
    If[denominator === $Failed, Return[$Failed]];
    AssociateTo[denominatorCache, signature -> denominator]];
  denominatorCoefficients = modularImage[#, prime] & /@
    CoefficientList[denominator, p];
  numeratorDegree = First[First[degrees]];
  count = numeratorDegree + 1;
  If[count > Length[samples], Return[$Failed]];
  xs = Take[abscissae, count];
  functionValues = Lookup[Take[valuesBySample, count], key, 0];
  numeratorValues = MapThread[Mod[#1*polynomialValue[
      denominatorCoefficients, #2, prime], prime] &,
    {functionValues, xs}];
  numeratorCoefficients = interpolatePolynomial[
    xs, numeratorValues, prime];
  If[Length[numeratorCoefficients] =!= count ||
      Last[numeratorCoefficients] === 0, Return[$Failed]];
  heldOutDenominator = polynomialValue[
    denominatorCoefficients, heldOutPoint, prime];
  If[heldOutDenominator === 0, Return[$Failed]];
  actual = Mod[polynomialValue[numeratorCoefficients,
      heldOutPoint, prime]*PowerMod[heldOutDenominator, -1, prime], prime];
  expected = Lookup[heldOutValues, key, 0];
  If[actual =!= expected, Return[$Failed]];
  <|"key" -> key, "status" -> 0, "degrees" -> First[degrees],
    "consumed" -> count + 1, "numerator" -> numeratorCoefficients,
    "denominator" -> denominatorCoefficients|>
];

timing = AbsoluteTiming[records = buildRecord /@ keys];
failures = Flatten@Position[records, $Failed];
If[failures =!= {},
  Print["FAIL CF303KnownDenominatorImage count=", Length[failures],
    " first=", Take[failures, UpTo[10]]];
  Quit[3]];
result = <|"status" -> "HeldOutValidated", "prime" -> prime,
  "sample_count" -> Length[samples] + 1,
  "mode" -> "KnownDenominator", "reason_code" -> 0,
  "consumed" -> Max[Lookup[records, "consumed"]],
  "construction_count" -> Length[samples], "required_additional" -> 0,
  "threads" -> 1, "coordinates" -> records,
  "interpolation_seconds" -> First[timing],
  "construction_points" -> Lookup[samples, "p"],
  "held_out_point" -> heldOut["p"],
  "maximum_total_degree" -> Max[Total /@ Cases[
    Lookup[records, "degrees"], {_Integer, _Integer}]]|>;
Export[outputPath, result, "RawJSON"];
Print["PASS status=", result["status"], " coordinates=", Length[records],
  " construction=", Length[samples], " seconds=", First[timing],
  " output=", outputPath];
