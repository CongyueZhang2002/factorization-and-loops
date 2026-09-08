$AllowInternet = False;
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 4];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
fits = Import[#, "RawJSON"] & /@ Sort[FileNames["q*.json",
  "/tmp/cf303_junction_interpolations"]];
primes = Lookup[fits, "prime"];
modulus = Times @@ primes;
scriptArguments = Rest[$ScriptCommandLine];
key = If[scriptArguments === {}, "1:-2:44:0", First[scriptArguments]];
records = (SelectFirst[#coordinates, #key === key &] &) /@ fits;
vectors = Join[#numerator, #denominator] & /@ records;
images = Map[ChineseRemainder[#, primes] &, Transpose[vectors]];
n = Length[images];
basis = Join[Table[ReplacePart[ConstantArray[0, n], i -> modulus],
    {i, n - 1}], {Join[Most[images], {1}]}];
timing = AbsoluteTiming[reduced = LatticeReduce[basis]];
validation = Import[
  "/tmp/cf303_junction_validation_q2305843009213693951.json", "RawJSON"];
q = validation["prime"];
point = validation["p_mod_prime"];
expected = Lookup[Association[(StringRiffle[ToString /@
      {#["mode_index"], #["epsilon_order"], #["target_master"],
       Lookup[#, "radical_mask_bits", 0]}, ":"] -> #["value"]) & /@
    validation["normal_residue_projection"]], key, 0];
candidate[row_] := Module[{primitive, split, numerator, denominator,
    numeratorValue, denominatorValue},
  primitive = row/Apply[GCD, Abs[row]];
  If[Last[primitive] < 0, primitive = -primitive];
  split = Length[First[records]["numerator"]];
  numerator = Take[primitive, split]; denominator = Drop[primitive, split];
  numeratorValue = Mod[numerator . PowerMod[point, Range[0,
      Length[numerator] - 1], q], q];
  denominatorValue = Mod[denominator . PowerMod[point, Range[0,
      Length[denominator] - 1], q], q];
  <|"Vector" -> primitive,
    "HeightBits" -> IntegerLength[Max[Abs[primitive]], 2],
    "Valid" -> denominatorValue =!= 0 &&
      Mod[numeratorValue*PowerMod[denominatorValue, -1, q], q] === expected|>
];
candidates = candidate /@ Take[reduced, UpTo[20]];
Print[InputForm[<|"Key" -> key, "Dimension" -> n,
  "LatticeReduceSeconds" -> First[timing],
  "CandidateHeightBits" -> Lookup[candidates, "HeightBits"],
  "ValidPositions" -> Flatten@Position[Lookup[candidates, "Valid"], True]|>]];

firstRecord = First[records];
denominatorPolynomial = firstRecord["denominator"] .
  x^Range[0, Length[firstRecord["denominator"]] - 1];
factorization = Rest[FactorList[denominatorPolynomial,
    Modulus -> First[primes]]];
liftFactor[factor_] := Module[{coefficients, lifted},
  coefficients = CoefficientList[First[factor], x];
  lifted = FeynFacet`Private`modularRationalReconstruct[#, First[primes]] & /@
    coefficients;
  If[MemberQ[lifted, $Failed], Return[$Failed]];
  {lifted . x^Range[0, Length[lifted] - 1], Last[factor]}];
liftedFactors = liftFactor /@ factorization;
If[! MemberQ[liftedFactors, $Failed],
  Print[InputForm[<|"LiftedFactors" -> liftedFactors|>]];
  denominatorExact = Expand[Times @@ ((First[#]^Last[#]) & /@
      liftedFactors)];
  denominatorExact = Expand[denominatorExact/
    Coefficient[denominatorExact, x, Exponent[denominatorExact, x]]];
  denominatorCoefficients = CoefficientList[denominatorExact, x];
  modularImage[value_, modulus_] := Mod[Numerator[value]*PowerMod[
    Mod[Denominator[value], modulus], -1, modulus], modulus];
  denominatorValid = And @@ MapThread[
    Function[{recordDenominator, modulusPrime},
      (modularImage[#, modulusPrime] & /@ denominatorCoefficients) ===
        recordDenominator],
    {Lookup[records, "denominator"], primes}];
  commonScale = Apply[LCM, Denominator /@ denominatorCoefficients];
  numeratorIntegers = Map[Function[imagesAtCoefficient, With[
      {combined = ChineseRemainder[MapThread[
        Mod[#1*#2, #3] &, {imagesAtCoefficient,
          Mod[commonScale, primes], primes}], primes]},
      If[combined > modulus/2, combined - modulus, combined]]],
    Transpose[Lookup[records, "numerator"]]];
  numeratorExact = numeratorIntegers/commonScale;
  functionExact = (numeratorExact . x^Range[0, Length[numeratorExact] - 1])/
    denominatorExact;
  factorCandidateValue = modularImage[functionExact /. x -> point, q];
  Print[InputForm[<|"FactorLifted" -> True,
    "FactorDegrees" -> ({Exponent[First[#], x], Last[#]} &) /@
      liftedFactors, "DenominatorValid" -> denominatorValid,
    "CommonScaleBits" -> IntegerLength[commonScale, 2],
    "NumeratorIntegerHeightBits" ->
      IntegerLength[Max[Abs[numeratorIntegers]], 2],
    "FreshPointValid" -> (factorCandidateValue === expected)|>]],
  Print["factor lift failed"]];
