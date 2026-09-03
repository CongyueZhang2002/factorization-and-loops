#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 4];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
fits = Import[#, "RawJSON"] & /@ Sort[FileNames["q*.json",
  "/tmp/cf303_junction_interpolations"]];
primes = Lookup[fits, "prime"];
key = If[Rest[$ScriptCommandLine] === {}, "1:-2:44:0",
  First[Rest[$ScriptCommandLine]]];
records = (SelectFirst[#["coordinates"], #["key"] === key &] &) /@ fits;
modularImage[value_, prime_] := Mod[Numerator[value]*PowerMod[
  Mod[Denominator[value], prime], -1, prime], prime];
polynomialFrom[coefficients_] := coefficients .
  p^Range[0, Length[coefficients] - 1];
polynomialImage[polynomial_, prime_] := Module[{coefficients},
  coefficients = modularImage[#, prime] & /@ CoefficientList[polynomial, p];
  polynomialFrom[coefficients]];
denominators = polynomialFrom[#["denominator"]] & /@ records;
numerators = polynomialFrom[#["numerator"]] & /@ records;
firstPrime = First[primes];
modularFactors = Rest[FactorList[First[denominators],
    Modulus -> firstPrime]];
liftProduct[indices_] := Module[{exponents, modularPolynomial,
    liftedCoefficients, exactPolynomial, exponent, valid},
  exponents = modularFactors[[indices, 2]];
  If[! SameQ @@ exponents, Return[$Failed]];
  exponent = First[exponents];
  modularPolynomial = PolynomialMod[Times @@
    modularFactors[[indices, 1]], firstPrime];
  liftedCoefficients = FeynFacet`Private`modularRationalReconstruct[
      #, firstPrime] & /@ CoefficientList[modularPolynomial, p];
  If[MemberQ[liftedCoefficients, $Failed], Return[$Failed]];
  exactPolynomial = polynomialFrom[liftedCoefficients];
  exactPolynomial = Expand[exactPolynomial/
    Coefficient[exactPolynomial, p, Exponent[exactPolynomial, p]]];
  valid = And @@ MapThread[Function[{denominator, prime},
    PolynomialRemainder[denominator,
      polynomialImage[exactPolynomial, prime]^exponent, p,
      Modulus -> prime] === 0], {denominators, primes}];
  If[!valid, $Failed, <|"Indices" -> indices,
    "Factor" -> exactPolynomial, "Exponent" -> exponent|>]];
remaining = Range[Length[modularFactors]];
exactFactors = {};
While[remaining =!= {},
  candidate = SelectFirst[Flatten[Table[
      liftProduct[#] & /@ Subsets[remaining, {size}],
      {size, 1, Min[6, Length[remaining]]}], 1],
    AssociationQ, Missing["NotFound"]];
  If[MissingQ[candidate],
    Print["FAIL factor cover remaining=", remaining]; Quit[2]];
  AppendTo[exactFactors, candidate];
  remaining = Complement[remaining, candidate["Indices"]]];
exactDenominator = Expand[Times @@
  ((#["Factor"]^#["Exponent"]) & /@ exactFactors)];
denominatorValid = And @@ MapThread[Function[{denominator, prime},
  Expand[polynomialImage[exactDenominator, prime] - denominator,
    Modulus -> prime] === 0], {denominators, primes}];
Print[InputForm[<|"Key" -> key,
  "Factorization" -> ({#["Factor"], #["Exponent"]} & /@ exactFactors),
  "DenominatorValid" -> denominatorValid|>]];
If[!denominatorValid, Quit[3]];

partialImage[numerator_, denominator_, prime_] := Module[
  {quotient, remainder, pieces, factor, exponent, block, cofactor,
   gcd, bezout, local, coefficients},
  {quotient, remainder} = PolynomialQuotientRemainder[
    numerator, denominator, p, Modulus -> prime];
  pieces = Flatten[MapIndexed[Function[{record, factorIndex},
    factor = polynomialImage[record["Factor"], prime];
    exponent = record["Exponent"];
    block = factor^exponent;
    cofactor = PolynomialQuotient[denominator, block, p,
      Modulus -> prime];
    {gcd, bezout} = PolynomialExtendedGCD[cofactor, block, p,
      Modulus -> prime];
    local = PolynomialRemainder[remainder*First[bezout]/gcd,
      block, p, Modulus -> prime];
    Table[
      coefficients = PadRight[CoefficientList[
        PolynomialRemainder[local, factor, p, Modulus -> prime], p],
        Exponent[factor, p]];
      local = PolynomialQuotient[
        local - polynomialFrom[coefficients], factor, p,
        Modulus -> prime];
      <|"FactorIndex" -> First[factorIndex],
        "Power" -> exponent - level,
        "Coefficients" -> coefficients|>,
      {level, 0, exponent - 1}]], exactFactors]];
  <|"Quotient" -> CoefficientList[quotient, p],
    "Pieces" -> pieces|>];
partialImages = MapThread[partialImage, {numerators, denominators, primes}];
liftRationalVector[imagesByPrime_] := Module[
  {direct, homogeneous, combined, dimension, modulus, basis, reduced,
   candidates, primitive, valid, constructionImages, constructionPrimes,
   checkImage, checkPrime, checkPosition, imageVectorQ, allDirect},
  checkPosition = First@FirstPosition[primes, 2305843009213693921];
  constructionImages = Delete[imagesByPrime, checkPosition];
  constructionPrimes = Delete[primes, checkPosition];
  checkImage = imagesByPrime[[checkPosition]];
  checkPrime = primes[[checkPosition]];
  imageVectorQ[values_] := And @@ MapThread[
    (modularImage[#1, checkPrime] === #2 &), {values, checkImage}];
  direct = FeynFacet`Private`modularLift[constructionImages,
    constructionPrimes];
  If[direct =!= $Failed && imageVectorQ[direct], Return[<|"Values" -> direct,
    "Method" -> "ScalarRationalReconstruction"|>]];
  homogeneous = Append[#, 1] & /@ constructionImages;
  combined = ChineseRemainder[#, constructionPrimes] & /@
    Transpose[homogeneous];
  dimension = Length[combined]; modulus = Times @@ constructionPrimes;
  basis = Join[Table[ReplacePart[ConstantArray[0, dimension],
      index -> modulus], {index, dimension - 1}],
    {Join[Most[combined], {1}]}];
  reduced = SortBy[LatticeReduce[basis], Max[Abs[#]] &];
  candidates = Take[reduced, UpTo[12]];
  primitive = DeleteDuplicates[(With[{gcd = Apply[GCD, Abs[#]]},
      If[Last[#] < 0, -#/gcd, #/gcd]]) & /@ candidates];
  valid = Select[primitive, Function[vector,
    Last[vector] =!= 0 && And @@ MapThread[
      Function[{image, prime}, Mod[Last[vector], prime] =!= 0 &&
        Mod[Most[vector]*PowerMod[Mod[Last[vector], prime], -1, prime],
          prime] === image], {constructionImages, constructionPrimes}]]];
  valid = Select[valid, imageVectorQ[Most[#]/Last[#]] &];
  If[valid =!= {}, Return[<|"Values" ->
    Most[First[valid]]/Last[First[valid]],
    "Method" -> "ProjectivePartialFractionThreePlusOne"|>]];
  allDirect = FeynFacet`Private`modularLift[imagesByPrime, primes];
  If[allDirect =!= $Failed, Return[<|"Values" -> allDirect,
    "Method" -> "ScalarSixPrimeUnvalidated",
    "HeightBits" -> Max[IntegerLength[Max[Abs[Numerator[#]],
      Abs[Denominator[#]]], 2] & /@ allDirect]|>]];
  homogeneous = Append[#, 1] & /@ imagesByPrime;
  combined = ChineseRemainder[#, primes] & /@ Transpose[homogeneous];
  dimension = Length[combined]; modulus = Times @@ primes;
  basis = Join[Table[ReplacePart[ConstantArray[0, dimension],
      index -> modulus], {index, dimension - 1}],
    {Join[Most[combined], {1}]}];
  reduced = SortBy[LatticeReduce[basis], Max[Abs[#]] &];
  primitive = DeleteDuplicates[(With[{gcd = Apply[GCD, Abs[#]]},
      If[Last[#] < 0, -#/gcd, #/gcd]]) & /@
    Take[reduced, UpTo[12]]];
  valid = Select[primitive, Function[vector,
    Last[vector] =!= 0 && And @@ MapThread[
      Function[{image, prime}, Mod[Last[vector], prime] =!= 0 &&
        Mod[Most[vector]*PowerMod[Mod[Last[vector], prime], -1, prime],
          prime] === image], {imagesByPrime, primes}]]];
  If[valid === {}, $Failed, <|"Values" ->
    Most[First[valid]]/Last[First[valid]],
    "Method" -> "ProjectiveSixPrimeUnvalidated",
    "HeightBits" -> IntegerLength[Max[Abs[First[valid]]], 2]|>]];
quotientLength = Max[Length /@ Lookup[partialImages, "Quotient"]];
quotientImages = PadRight[#, quotientLength] & /@
  Lookup[partialImages, "Quotient"];
quotientLift = liftRationalVector[quotientImages];
pieceKeys = Flatten[Table[{factorIndex, power},
  {factorIndex, Length[exactFactors]},
  {power, exactFactors[[factorIndex, "Exponent"]], 1, -1}], 1];
pieceAssociation[image_] := Association[Flatten[Table[
  With[{piece = SelectFirst[image["Pieces"],
      #["FactorIndex"] === factorIndex && #["Power"] === power &]},
    {{factorIndex, power} -> piece["Coefficients"]}],
  {factorIndex, Length[exactFactors]},
  {power, exactFactors[[factorIndex, "Exponent"]], 1, -1}], 1]];
pieceAssociations = pieceAssociation /@ partialImages;
pieceLift = Association@Table[pieceKey -> liftRationalVector[
    (#[pieceKey] & /@ pieceAssociations)],
  {pieceKey, pieceKeys}];
liftFailed = quotientLift === $Failed || MemberQ[Values[pieceLift], $Failed];
Print[InputForm[<|"PartialCoefficientCount" ->
  (quotientLength + Total[Length[#["Values"]] & /@
    Values[pieceLift]]), "LiftFailed" -> liftFailed,
  "Methods" -> Counts[Lookup[Values[pieceLift], "Method"]],
  "UnvalidatedPieces" -> Select[pieceLift,
    StringContainsQ[#["Method"], "Unvalidated"] &]|>]];
If[liftFailed, Quit[4]];
function = polynomialFrom[quotientLift["Values"]] + Total[Flatten[Table[
  polynomialFrom[pieceLift[{factorIndex, power}, "Values"]]/
    exactFactors[[factorIndex, "Factor"]]^power,
  {factorIndex, Length[exactFactors]},
  {power, exactFactors[[factorIndex, "Exponent"]], 1, -1}], 1]];
validation = Import[
  "/tmp/cf303_junction_validation_q2305843009213693693_p3.json", "RawJSON"];
validationPrime = validation["prime"];
validationPoint = validation["p_mod_prime"];
expected = Lookup[Association[(StringRiffle[ToString /@
      {#["mode_index"], #["epsilon_order"], #["target_master"],
       Lookup[#, "radical_mask_bits", 0]}, ":"] -> #["value"]) & /@
    validation["normal_residue_projection"]], key, 0];
actual = modularImage[function /. p -> validationPoint, validationPrime];
Print[InputForm[<|"FreshValid" -> (actual === expected),
  "Function" -> function|>]];
If[actual =!= expected, Quit[5]];
