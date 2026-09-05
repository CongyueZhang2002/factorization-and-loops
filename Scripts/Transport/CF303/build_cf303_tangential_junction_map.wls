#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repositoryRoot = DirectoryName[scriptDirectory, 3];
Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

scriptArguments = Rest[$ScriptCommandLine];
interpolationDirectory = If[scriptArguments =!= {},
  ExpandFileName[First[scriptArguments]],
  "/tmp/cf303_junction_interpolations"];
validationPath = If[Length[scriptArguments] >= 2,
  ExpandFileName[scriptArguments[[2]]],
  "/tmp/cf303_junction_validation.json"];
outputPath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303TangentialJunctionMap.wl"}];
framePath = If[Length[scriptArguments] >= 3,
  ExpandFileName[scriptArguments[[3]]],
  FileNameJoin[{scriptDirectory, "Artifacts",
    "CF303SixModeEndpointFrame.wl"}]];
jetControlPath = If[Length[scriptArguments] >= 4,
  ExpandFileName[scriptArguments[[4]]],
  FileNameJoin[{scriptDirectory, "Artifacts",
    "CF303TangentialJunctionJetControl.wl"}]];
outputPath = If[Length[scriptArguments] >= 5,
  ExpandFileName[scriptArguments[[5]]], outputPath];

fitPaths = Sort[FileNames["q*.json", interpolationDirectory]];
fits = Import[#, "RawJSON"] & /@ fitPaths;
validation = If[FileExistsQ[validationPath],
  Import[validationPath, "RawJSON"], Missing["ValidationPoint"]];
If[Length[fits] < 2 || MissingQ[validation] ||
    ! AllTrue[fits, Lookup[#, "status", None] === "HeldOutValidated" &] ||
    Lookup[validation, "status", None] =!=
      "CF303TangentialJunctionPointV1" ||
    Lookup[validation, "galois_orbit", None] =!= "Full16",
  Print["FAIL CF303TangentialJunctionMultiPrimeInputsMissing"];
  Quit[2]];
primes = Lookup[fits, "prime"];
If[! DuplicateFreeQ[primes] || MemberQ[primes, validation["prime"]],
  Print["FAIL CF303TangentialJunctionIndependentPrimeRequired"];
  Quit[2]];

keyString[mode_, order_, target_, mask_] :=
  StringRiffle[ToString /@ {mode, order, target, mask}, ":"];
expectedKeys = Flatten[Table[keyString[mode, order, target, 0],
  {mode, 7}, {order, -3, 4}, {target, {44, 45}}]];
recordsByFit = Association /@ Map[
  (Lookup[#, "key"] -> #) &, Lookup[fits, "coordinates"], {2}];
If[! AllTrue[recordsByFit,
    Sort[Keys[#]] === Sort[expectedKeys] &],
  Print["FAIL CF303TangentialJunctionCoordinateSet"];
  Quit[2]];

sampleValues[sample_] := Association[
  (keyString[Lookup[#, "mode_index"], Lookup[#, "epsilon_order"],
      Lookup[#, "target_master"],
      Lookup[#, "radical_mask_bits", 0]] -> Lookup[#, "value"]) & /@
    sample["normal_residue_projection"]];
validationValues = sampleValues[validation];
validationPrime = validation["prime"];
validationPoint = validation["p_mod_prime"];
modularValue[expression_] := Module[{value, numerator, denominator},
  value = Together[expression /. p -> validationPoint];
  numerator = Mod[Numerator[value], validationPrime];
  denominator = Mod[Denominator[value], validationPrime];
  If[denominator === 0, Missing["Pole"],
    Mod[numerator*PowerMod[denominator, -1, validationPrime],
      validationPrime]]
];

normalizeDegrees[{-1, 0}] := {-Infinity, 0};
normalizeDegrees[value_] := value;
polynomialFrom[coefficients_] := coefficients .
  p^Range[0, Length[coefficients] - 1];
polynomialImage[polynomial_, prime_] := polynomialFrom[
  (Mod[Numerator[#]*PowerMod[Mod[Denominator[#], prime], -1, prime],
      prime] &) /@ CoefficientList[polynomial, p]];

liftSmallRationalVector[imagesByPrime_, validationFunction_: (True &)] := Module[
  {direct, homogeneous, combined, dimension, modulus, basis, reduced,
   shortRows, candidates, valid, vector},
  direct = FeynFacet`Private`modularLift[imagesByPrime, primes];
  If[direct =!= $Failed && TrueQ[validationFunction[direct]],
    Return[<|"Values" -> direct,
    "Method" -> "Scalar"|>]];
  homogeneous = Append[#, 1] & /@ imagesByPrime;
  combined = ChineseRemainder[#, primes] & /@ Transpose[homogeneous];
  dimension = Length[combined]; modulus = Times @@ primes;
  basis = Join[Table[ReplacePart[ConstantArray[0, dimension],
      index -> modulus], {index, dimension - 1}],
    {Join[Most[combined], {1}]}];
  reduced = SortBy[LatticeReduce[basis], Max[Abs[#]] &];
  shortRows = Take[reduced, UpTo[12]];
  shortRows = Join[shortRows, Flatten[Table[
      {shortRows[[left]] + shortRows[[right]],
       shortRows[[left]] - shortRows[[right]]},
      {left, Min[6, Length[shortRows]]},
      {right, left + 1, Min[6, Length[shortRows]]}], 2]];
  candidates = DeleteDuplicates[(With[
      {gcd = Apply[GCD, Abs[#]]},
      If[Last[#] < 0, -#/gcd, #/gcd]]) & /@
    shortRows];
  valid = Select[candidates, Function[candidate,
    Last[candidate] =!= 0 && And @@ MapThread[
      Function[{image, prime}, Mod[Last[candidate], prime] =!= 0 &&
        Mod[Most[candidate]*PowerMod[
          Mod[Last[candidate], prime], -1, prime], prime] === image],
      {imagesByPrime, primes}] &&
      TrueQ[validationFunction[Most[candidate]/Last[candidate]]]]];
  If[valid === {}, Return[$Failed]];
  vector = First[valid];
  <|"Values" -> Most[vector]/Last[vector],
    "Method" -> "ProjectiveCommonScale",
    "HeightBits" -> IntegerLength[Max[Abs[vector]], 2]|>
];

projectivePolynomialCoefficientLift[records_, key_] := Catch@Module[
  {vectors, coefficientImages, modulus, split, dimension, center,
   primitive, constructionValid, independentPointValid, nonzero,
   subsetFamilies, localImages, localDimension, reduced, shortRows,
   scaleCandidates, candidates, acceptedCandidates, individual, successful,
   seed, candidate,
   numerator, denominator, function},
  vectors = Join[#["numerator"], #["denominator"]] & /@ records;
  If[! SameQ @@ (Length /@ vectors), Throw[$Failed]];
  coefficientImages = ChineseRemainder[#, primes] & /@ Transpose[vectors];
  modulus = Times @@ primes;
  split = Length[First[records]["numerator"]];
  dimension = Length[coefficientImages];
  center[value_] := With[{residue = Mod[value, modulus]},
    If[2*residue > modulus, residue - modulus, residue]];
  primitive[vector_] := Module[{divisor = Apply[GCD, Abs[vector]], result},
    If[divisor === 0, Return[vector]];
    result = vector/divisor;
    If[Last[result] < 0, -result, result]];
  constructionValid[vector_] := Last[vector] =!= 0 && And @@ MapThread[
    Function[{image, prime}, Mod[Last[vector], prime] =!= 0 &&
      Mod[vector*PowerMod[Mod[Last[vector], prime], -1, prime], prime] ===
        image], {vectors, primes}];
  independentPointValid[vector_] := Module[{n, d},
    n = Take[vector, split]; d = Drop[vector, split];
    modularValue[polynomialFrom[n]/polynomialFrom[d]] ===
      Lookup[validationValues, key, 0]];
  nonzero = Flatten@Position[coefficientImages, Except[0], {1},
    Heads -> False];
  individual = Table[FeynFacet`Private`modularLift[
      List /@ vectors[[All, index]], primes], {index, dimension}];
  successful = Cases[individual, {value_} :> value];
  seed = Apply[LCM, Denominator /@ successful];
  scaleCandidates = {seed};
  Do[
    subsetFamilies = DeleteCases[DeleteDuplicates[Map[
      Sort@DeleteCases[Take[DeleteDuplicates[#], UpTo[count]],
        index_ /; index < 1 || index >= dimension] &,
      {Take[nonzero, UpTo[count]],
       Take[Reverse[nonzero], UpTo[count]],
       Extract[nonzero, List /@ DeleteDuplicates[Round[Subdivide[
         1, Length[nonzero], Min[count, Length[nonzero]] - 1]]]],
       Flatten@Table[{index, split + 1 - index, split + index,
         dimension + 1 - index}, {index, Ceiling[count/2]}],
       Select[Range[split + 1, dimension - 1],
         Mod[#, Max[1, Floor[(dimension - split - 1)/count]]] === 0 &],
       Select[Range[1, split],
         Mod[#, Max[1, Floor[split/count]]] === 0 &]}]], {}];
    Do[
      localImages = coefficientImages[[subset]];
      localDimension = Length[localImages] + 1;
      reduced = SortBy[LatticeReduce[Join[
        Table[ReplacePart[ConstantArray[0, localDimension], index -> modulus],
          {index, localDimension - 1}], {Join[localImages, {1}]}]],
        Max[Abs[#]] &];
      shortRows = Take[reduced, UpTo[12]];
      shortRows = Join[shortRows, Flatten[Table[
          {shortRows[[left]] + shortRows[[right]],
           shortRows[[left]] - shortRows[[right]]},
          {left, Min[6, Length[shortRows]]},
          {right, left + 1, Min[6, Length[shortRows]]}], 2]];
      scaleCandidates = Join[scaleCandidates, Last /@ shortRows];
      candidates = DeleteDuplicates[
        primitive[center /@ (coefficientImages*#)] & /@ scaleCandidates];
      acceptedCandidates = Cases[candidates,
        item_ /; constructionValid[item] && independentPointValid[item]];
      If[acceptedCandidates =!= {},
        candidate = First[acceptedCandidates];
        numerator = Take[candidate, split];
        denominator = Drop[candidate, split];
        function = polynomialFrom[numerator]/polynomialFrom[denominator];
        Throw[<|"Function" -> function, "Numerator" -> numerator,
          "Denominator" -> denominator,
          "Method" -> "ProjectivePolynomialCoefficientReconstruction",
          "CoefficientHeightBits" ->
            IntegerLength[Max[Abs[candidate]], 2]|>]],
      {subset, subsetFamilies}],
    {count, {4, 6, 8, 10, 12, 16}}];
  $Failed
];

factorPartialLift[records_, key_] := Module[
  {denominators, numerators, firstPrime, modularFactors, liftProduct,
   remaining, exactFactors = {}, multiplicityGroups, candidateSubsets,
   firstLift, candidate, exactDenominator,
   denominatorValid, tryNumeratorLift, numeratorImages,
   shiftedNumeratorImages, partialImage, partialImages, quotientLength,
   pieceKeys, pieceAssociation, pieceAssociations, pieceLengths,
   combinedImages, functionFromCombined, combinedLift, function,
   coefficients},
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
    exactPolynomial = Expand[exactPolynomial/Coefficient[
      exactPolynomial, p, Exponent[exactPolynomial, p]]];
    valid = And @@ MapThread[Function[{denominator, prime},
      PolynomialRemainder[denominator,
        polynomialImage[exactPolynomial, prime]^exponent, p,
        Modulus -> prime] === 0], {denominators, primes}];
    If[!valid, $Failed, <|"Indices" -> indices,
      "Factor" -> exactPolynomial, "Exponent" -> exponent|>]
  ];
  firstLift[subsets_] := Module[{lifted = $Failed},
    Do[
      lifted = liftProduct[indices];
      If[AssociationQ[lifted], Break[]],
      {indices, subsets}];
    lifted];
  remaining = Range[Length[modularFactors]];
  While[remaining =!= {},
    (* Over a finite field, one rational square-free factor may split into
       many irreducible factors.  All factors carrying the same multiplicity
       can be recombined safely: their product is still square-free and is
       coprime to every other multiplicity block.  Try those complete blocks
       first.  This avoids an artificial subset-size ceiling (the CF303
       degree-66 denominator has eight modular factors in one multiplicity
       block), and it is much cheaper than a combinatorial search.  Smaller
       subsets remain a fallback when a multiplicity block contains several
       rational factors whose product is too large for one-prime lifting. *)
    multiplicityGroups = Values[GroupBy[remaining,
      modularFactors[[#, 2]] &]];
    candidate = firstLift[multiplicityGroups];
    If[! AssociationQ[candidate],
      candidateSubsets = Flatten[Table[Subsets[remaining, {size}],
        {size, 1, Min[8, Length[remaining]]}], 1];
      candidate = firstLift[candidateSubsets]];
    If[! AssociationQ[candidate], Return[$Failed]];
    AppendTo[exactFactors, candidate];
    remaining = Complement[remaining, candidate["Indices"]]];
  exactDenominator = Expand[Times @@
    ((#["Factor"]^#["Exponent"]) & /@ exactFactors)];
  denominatorValid = And @@ MapThread[Function[{denominator, prime},
    Expand[polynomialImage[exactDenominator, prime] - denominator,
      Modulus -> prime] === 0], {denominators, primes}];
  If[!denominatorValid, Return[$Failed]];
  tryNumeratorLift[images_, numeratorFunction_, basis_] := Module[
    {supports, lift, commonDenominator, primitive, candidateFunction},
    supports = Flatten@Position[#, Except[0], {1}, Heads -> False] & /@ images;
    If[! SameQ @@ (Length /@ images) || ! SameQ @@ supports,
      Return[$Failed]];
    lift = liftSmallRationalVector[images,
      modularValue[numeratorFunction[#]/exactDenominator] ===
          Lookup[validationValues, key, 0] &];
    If[lift === $Failed, Return[$Failed]];
    commonDenominator = Apply[LCM, Denominator /@ lift["Values"]];
    primitive = commonDenominator*lift["Values"];
    candidateFunction = numeratorFunction[primitive]/
      (commonDenominator*exactDenominator);
    If[modularValue[candidateFunction] =!= Lookup[validationValues, key, 0],
      Return[$Failed]];
    <|"Function" -> candidateFunction,
      "Method" -> "ExactDenominatorCommonScaleNumerator",
      "CoefficientLiftMethod" -> lift["Method"],
      "NumeratorBasis" -> basis,
      "PrimitiveNumerator" -> primitive,
      "CommonScalarDenominator" -> commonDenominator,
      "ExactDenominatorFactors" ->
        ({#["Factor"], #["Exponent"]} & /@ exactFactors),
      "CoefficientHeightBits" -> IntegerLength[Max[Abs[Join[
        primitive, {commonDenominator}]]], 2]|>
  ];
  numeratorImages = Lookup[records, "numerator"];
  candidate = tryNumeratorLift[numeratorImages, polynomialFrom,
    <|"Type" -> "Monomial", "Variable" -> p|>];
  If[AssociationQ[candidate], Return[candidate]];
  shiftedNumeratorImages = MapThread[CoefficientList[
      PolynomialMod[polynomialFrom[#1] /. p ->
        p + PowerMod[2, -1, #2], #2], p] &,
    {numeratorImages, primes}];
  candidate = tryNumeratorLift[shiftedNumeratorImages,
    polynomialFrom[#] /. p -> p - 1/2 &,
    <|"Type" -> "ShiftedMonomial", "Variable" -> p,
      "Center" -> 1/2|>];
  If[AssociationQ[candidate], Return[candidate]];
  partialImage[numerator_, denominator_, prime_] := Module[
    {quotient, remainder, pieces, factor, exponent, block, cofactor,
     gcd, bezout, local, localCoefficients},
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
        localCoefficients = PadRight[CoefficientList[
          PolynomialRemainder[local, factor, p, Modulus -> prime], p],
          Exponent[factor, p]];
        local = PolynomialQuotient[
          local - polynomialFrom[localCoefficients], factor, p,
          Modulus -> prime];
        <|"FactorIndex" -> First[factorIndex],
          "Power" -> exponent - level,
          "Coefficients" -> localCoefficients|>,
        {level, 0, exponent - 1}]], exactFactors]];
    <|"Quotient" -> CoefficientList[quotient, p],
      "Pieces" -> pieces|>
  ];
  partialImages = MapThread[partialImage,
    {numerators, denominators, primes}];
  quotientLength = Max[Length /@ Lookup[partialImages, "Quotient"]];
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
  pieceLengths = Length /@ Lookup[First[pieceAssociations], pieceKeys];
  combinedImages = MapThread[Join[
      PadRight[#1["Quotient"], quotientLength],
      Flatten[Lookup[#2, pieceKeys]]] &,
    {partialImages, pieceAssociations}];
  functionFromCombined[values_] := Module[
    {pieces = TakeList[values,
       Prepend[pieceLengths, quotientLength]], quotient, pieceValues},
    quotient = First[pieces];
    pieceValues = AssociationThread[pieceKeys, Rest[pieces]];
    polynomialFrom[quotient] + Total[Flatten[
      Table[polynomialFrom[pieceValues[{factorIndex, power}]]/
        exactFactors[[factorIndex, "Factor"]]^power,
        {factorIndex, Length[exactFactors]},
        {power, exactFactors[[factorIndex, "Exponent"]], 1, -1}], 1]]];
  combinedLift = liftSmallRationalVector[combinedImages,
    modularValue[functionFromCombined[#]] ===
        Lookup[validationValues, key, 0] &];
  If[combinedLift === $Failed, Return[$Failed]];
  function = functionFromCombined[combinedLift["Values"]];
  If[modularValue[function] =!= Lookup[validationValues, key, 0],
    Return[$Failed]];
  coefficients = combinedLift["Values"];
  <|"Function" -> function, "Method" -> "FactorAwarePartialFraction",
    "PartialFractionCount" -> Length[pieceKeys],
    "CoefficientLiftMethod" -> combinedLift["Method"],
    "ExactDenominatorFactors" ->
      ({#["Factor"], #["Exponent"]} & /@ exactFactors),
    "CoefficientHeightBits" -> Max[IntegerLength[
      Max[Abs[Numerator[#]], Abs[Denominator[#]]], 2] & /@ coefficients]|>
];

liftOne[key_] := Module[
  {records, degrees, numerator, denominator, function, projective, partial},
  records = Lookup[recordsByFit, key];
  degrees = normalizeDegrees /@ Lookup[records, "degrees"];
  If[! SameQ @@ degrees, Return[<|"Status" -> "DegreeMismatch",
    "Key" -> key, "Degrees" -> degrees|>]];
  numerator = FeynFacet`Private`modularLift[
    Lookup[records, "numerator"], primes];
  denominator = FeynFacet`Private`modularLift[
    Lookup[records, "denominator"], primes];
  If[numerator =!= $Failed && denominator =!= $Failed,
    function = polynomialFrom[numerator]/polynomialFrom[denominator];
    If[modularValue[function] === Lookup[validationValues, key, 0],
      Return[<|"Status" -> "Lifted", "Key" -> key,
        "Degrees" -> First[degrees], "Numerator" -> numerator,
        "Denominator" -> denominator, "Function" -> function,
        "Method" -> "ScalarRationalReconstruction"|>]]];
  partial = factorPartialLift[records, key];
  If[partial =!= $Failed,
    Return[Join[<|"Status" -> "Lifted", "Key" -> key,
      "Degrees" -> First[degrees]|>, partial]]];
  projective = projectivePolynomialCoefficientLift[records, key];
  If[projective =!= $Failed,
    Return[Join[<|"Status" -> "Lifted", "Key" -> key,
      "Degrees" -> First[degrees]|>, projective]]];
  <|"Status" -> "FactorPartialLiftFailed", "Key" -> key,
    "Degrees" -> First[degrees],
    "ModulusBits" -> IntegerLength[Times @@ primes, 2]|>
];
lifted = liftOne /@ expectedKeys;
failed = Select[lifted, #Status =!= "Lifted" &];
If[failed =!= {},
  Print["FAIL CF303TangentialJunctionLift count=", Length[failed],
    " modulusBits=", IntegerLength[Times @@ primes, 2],
    " first=", InputForm[Take[failed, UpTo[10]]]];
  Quit[3]];
reconstructions = Association[(#Key -> #) & /@ lifted];
validationComparisons = Count[expectedKeys, key_ /;
  modularValue[reconstructions[key, "Function"]] ===
    Lookup[validationValues, key, 0]];
If[validationComparisons =!= Length[expectedKeys],
  Print["FAIL CF303TangentialJunctionIndependentPrimeValidation ",
    validationComparisons, "/", Length[expectedKeys]];
  Quit[4]];

modeOrder = validation["mode_order"];
modeEigenvalues = {-2, 0, 0, 0, -4, 0, -4};
radicalSquares = {
  (4*p^4 - 8*p^3 + 4*p^2 + 1)/(p - 1)^2,
  (p - 1)*(4*p^2 + p - 1)/p^2,
  p*(4*p^2 + p - 4), p*(p - 1)};
residueRecords = DeleteCases[Flatten[Table[With[
  {candidate = reconstructions[keyString[mode, order, target, 0]]},
  If[candidate["Function"] === 0, Nothing,
    <|"ModeIndex" -> mode, "ModeID" -> modeOrder[[mode]],
      "EpsilonOrder" -> order, "TargetMaster" -> target,
      "Function" -> candidate["Function"],
      "Degrees" -> candidate["Degrees"]|>]],
  {mode, 7}, {order, -3, 4}, {target, {44, 45}}]], Nothing];
targetRecords = DeleteCases[Map[Function[record, With[
  {eigenvalue = modeEigenvalues[[record["ModeIndex"]]]},
  If[eigenvalue === 0, Nothing,
    Join[KeyDrop[record, "EpsilonOrder"],
      <|"EpsilonOrder" -> record["EpsilonOrder"] - 1,
        "Function" -> Cancel[record["Function"]/eigenvalue],
        "Relation" -> "B.v/(lambda*eps)"|>]]]], residueRecords],
  Nothing];
zeroChainRecords = Select[residueRecords,
  modeEigenvalues[[#ModeIndex]] === 0 &];

frame = Get[framePath];
jetControl = Get[jetControlPath];
If[Lookup[jetControl, "Status", None] =!=
      "CF303TangentialJunctionIntertwiningJetsAcceptedV1" ||
    ! TrueQ[jetControl["PhysicalNormalization", "TargetGModeMapComplete"]],
  Print["FAIL CF303TangentialJunctionJetControlRequired"];
  Quit[5]];
junction = frame["ProductionInput", "AcceptedZPathJunction"];
ownSourceMap = Normal[junction["SourceModeMap"]];
eta = -1/((2 + 3*eps)*(1 + 4*eps));
ownTargetMap = {{0, 0, 0, eta, 1, 0},
  {0, 0, 0, eta, 0, 1}};
acceptedRows = junction["AcceptedSourceStateRows"];
inheritedWeights = {
  {1 -> 1}, {2 -> 1}, {12 -> 1}, {21 -> 2, 22 -> -3},
  {22 -> 1}, {29 -> 2, 30 -> -3}, {30 -> 1}};
inheritedSourceMap = ConstantArray[0, {43, 7}];
Do[Scan[(inheritedSourceMap[[First@FirstPosition[acceptedRows, First[#]],
      mode]] = Last[#]) &, inheritedWeights[[mode]]], {mode, 7}];
exactSourceMap = Join[ownSourceMap, inheritedSourceMap, 2];

epsilonWindow = {-4, 3};
sourceDeck = Association@Table[order -> SparseArray[Map[
  SeriesCoefficient[#, {eps, 0, order}] &, exactSourceMap, {2}]],
  {order, epsilonWindow[[1]], epsilonWindow[[2]]}];
inheritedTargetDeck = Association@Table[order -> SparseArray[
  ({First@FirstPosition[{44, 45}, #TargetMaster], #ModeIndex} -> #Function) & /@
    Select[targetRecords, #EpsilonOrder === order &], {2, 7}],
  {order, epsilonWindow[[1]], epsilonWindow[[2]]}];
ownTargetDeck = Association@Table[order -> SparseArray[Map[
  SeriesCoefficient[#, {eps, 0, order}] &, ownTargetMap, {2}]],
  {order, epsilonWindow[[1]], epsilonWindow[[2]]}];
targetDeck = Association@Table[order -> SparseArray[Join[
  Normal[ownTargetDeck[order]], Normal[inheritedTargetDeck[order]], 2]],
  {order, epsilonWindow[[1]], epsilonWindow[[2]]}];
resonantModeOrder = {2, 3, 4, 6};
zeroLogDeck = Association@Table[order -> SparseArray[
  ({First@FirstPosition[{44, 45}, #TargetMaster],
       First@FirstPosition[resonantModeOrder, #ModeIndex]} -> #Function) & /@
    Select[zeroChainRecords, #EpsilonOrder === order &], {2, 4}],
  {order, -3, 4}];
zeroFiniteDeck = Association@Table[order -> SparseArray[{}, {2, 4}],
  {order, epsilonWindow[[1]], epsilonWindow[[2]]}];

coefficientHeights = Cases[
  Flatten[Lookup[Values[reconstructions], {"Numerator", "Denominator"}]],
  value : (_Integer | _Rational) :>
    Max[Abs[Numerator[value]], Abs[Denominator[value]]]];
partialCoefficientHeightBits = Cases[
  Lookup[Values[reconstructions], "CoefficientHeightBits"], _Integer];
maximumCoefficientHeightBits = Max[Join[
  IntegerLength[#, 2] & /@ coefficientHeights,
  partialCoefficientHeightBits]];
result = <|
  "Status" -> "CF303TangentialJunctionMapReconstructedV1",
  "Family" -> "CF303", "Primes" -> primes,
  "ModulusBits" -> IntegerLength[Times @@ primes, 2],
  "MaximumCoefficientHeightBits" -> maximumCoefficientHeightBits,
  "LiftMethods" -> Counts[Lookup[Values[reconstructions], "Method"]],
  "CoefficientField" -> <|
    "Field" -> "Q(p)", "RawRadicalSquares" -> radicalSquares,
    "Reduction" ->
      "All four raw radicals cancel after demanded D/S records are grouped by matrix coordinate"|>,
  "Scope" -> "Six own plus seven inherited soft modes; no raw 2x43 deck",
  "SampleProvider" ->
    "Scripts/Transport/CF303/cf303_tangential_junction_point.py",
  "InterpolationProvider" ->
    "Scripts/Transport/CF303/cf303_tangential_junction_interpolate.py",
  "ConstructionPPointsByPrime" -> Lookup[fits, "construction_points"],
  "HeldOutPPointsByPrime" -> Lookup[fits, "held_out_point"],
  "IndependentValidationPrime" -> validationPrime,
  "IndependentValidationPPoint" -> validation["p"],
  "IndependentValidationComparisonCount" -> validationComparisons,
  "InterpolationSecondsByPrime" -> Lookup[fits, "interpolation_seconds"],
  "MaximumObservedTotalDegree" -> Max[Total /@
    Cases[Lookup[Values[reconstructions], "Degrees"],
      {_Integer, _Integer}]],
  "InheritedModeOrder" -> modeOrder,
  "CombinedModeOrder" -> Join[
    frame["ProductionInput", "BoundaryCoordinateOrder"], modeOrder],
  "CanonicalNormalExponents" -> Join[
    junction["CanonicalNormalExponents"], eps*modeEigenvalues],
  "ModeJordanLevels" -> Join[ConstantArray[0, 6],
    {0, 1, 1, 1, 0, 1, 0}],
  "SourceModeMapRationalEpsilon" -> SparseArray[exactSourceMap],
  "SourceModeMapWindow" -> epsilonWindow,
  "SourceModeMap" -> sourceDeck,
  "TargetGModeMapWindow" -> epsilonWindow,
  "TargetGModeMap" -> targetDeck,
  "TargetGModeMapComplete" -> True,
  "TargetGModeMapCompleteWithinWindow" -> True,
  "OwnTargetGModeMapRationalEpsilon" -> SparseArray[ownTargetMap],
  "InheritedNormalResidueProjection" -> residueRecords,
  "InheritedTargetGNonzeroEigenmodes" -> targetRecords,
  "InheritedZeroModeJordanCouplings" -> zeroChainRecords,
  "ResonantZeroSector" -> <|
    "InheritedModeOrder" -> resonantModeOrder,
    "TargetHomogeneousModeOrder" ->
      {"IndependentTargetMode1", "IndependentTargetMode2"},
    "LogarithmicJordanCoefficientC" -> zeroLogDeck,
    "RankBoundC" -> 2,
    "FreshPointRankC" -> jetControl["MaximumRankC"],
    "FinitePartMatrix" -> zeroFiniteDeck,
    "CanonicalParticular" -> "K=0",
    "HomogeneousShiftFreedom" ->
      jetControl["HomogeneousShiftFreedom"],
    "Stage3Policy" ->
      "Finite K is absorbed by a triangular redefinition of the existing two independent target periods; no new periods"|>,
  "GeneralizedModePolicy" ->
    "Zero-eigenvalue B.v terms are retained as level-one chains, not divided by zero",
  "Regularization" -> <|
    "Formula" -> HoldForm[Reg[Inverse[PhiG].Inverse[UH].PsiPhysical]],
    "EquivalentImplementation" ->
      "Contracted normal Frobenius recurrence in the accepted G25 basis",
    "CheckedRhoOrders" -> jetControl["CheckedRhoOrders"],
    "EpsilonCoefficientWindow" ->
      jetControl["EpsilonCoefficientWindow"],
    "CheckCount" -> jetControl["CheckCount"],
    "Status" -> "TangentialJunctionIntertwiningJetsAccepted"|>,
  "TangentialTargetConnection" ->
    frame["ProductionInput", "Layer", "Diagonal"],
  "RawResidueDeckEmitted" -> False|>;
If[! DirectoryQ[DirectoryName[outputPath]],
  CreateDirectory[DirectoryName[outputPath],
    CreateIntermediateDirectories -> True]];
Put[result, outputPath];
Print["PASS status=", result["Status"], " primes=", Length[primes],
  " validation=", validationComparisons,
  " maxDegree=", result["MaximumObservedTotalDegree"],
  " modulusBits=", result["ModulusBits"],
  " heightBits=", result["MaximumCoefficientHeightBits"],
  " output=", outputPath];
