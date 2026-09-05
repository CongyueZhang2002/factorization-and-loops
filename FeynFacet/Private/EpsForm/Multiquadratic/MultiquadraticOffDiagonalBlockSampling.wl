(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockSampling.wl -- part 5 of 8 of the
   multiquadratic off-diagonal block equation solver (split from MultiquadraticOffDiagonalBlockSolve.wl in
   round 4, 2026-09-02, pure moves): prime forms and regulator collapse, point and sample assembly, sign
   transforms and the differential certificate, the modular affine solve
   (Wolfram and native backends, constrained plans, follower and pilot images,
   the provider support ladder), unpacking and exact verification.
   Loads after the preceding parts (Private/LoadOrder.wl); the shared
   globals and the shared utilities are in MultiquadraticOffDiagonalBlockSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticOffDiagonalBlockMapRationals,
  multiquadraticOffDiagonalBlockReducePolynomial,
  multiquadraticOffDiagonalBlockReduceRational,
  multiquadraticOffDiagonalBlockCacheLookup,
  multiquadraticOffDiagonalBlockCacheInsert,
  multiquadraticOffDiagonalBlockPrimeForms,
  multiquadraticOffDiagonalBlockCollapsePolynomial,
  multiquadraticOffDiagonalBlockCollapseRational,
  multiquadraticOffDiagonalBlockCollapseEpsilon,
  multiquadraticOffDiagonalBlockMaximumExponents,
  multiquadraticOffDiagonalBlockEvaluatePolynomial,
  multiquadraticOffDiagonalBlockEvaluateRational,
  multiquadraticOffDiagonalBlockEvaluateForms,
  multiquadraticOffDiagonalBlockPolynomialImageValidQ,
  multiquadraticOffDiagonalBlockRationalImageValidQ,
  multiquadraticOffDiagonalBlockEpsilonFormsValidQ,
  multiquadraticOffDiagonalBlockMaskFactorMod,
  multiquadraticOffDiagonalBlockCharacter,
  multiquadraticOffDiagonalBlockAssemblePointInternal,
  multiquadraticOffDiagonalBlockAssemblePointRows,
  multiquadraticOffDiagonalBlockPointCoefficientsValidQ,
  multiquadraticOffDiagonalBlockNormalizationRows,
  multiquadraticOffDiagonalBlockAssembleSample,
  multiquadraticOffDiagonalBlockSignTransform,
  multiquadraticOffDiagonalBlockTransformPointToSigns,
  multiquadraticOffDiagonalBlockTransformSampleToSigns,
  multiquadraticOffDiagonalBlockSplitPointRows,
  multiquadraticOffDiagonalBlockDifferentialCheckPoint,
  multiquadraticOffDiagonalBlockAffineSolve,
  multiquadraticOffDiagonalBlockPlanDiscoveryBackendDecision,
  multiquadraticOffDiagonalBlockNativeAffineSolve,
  multiquadraticOffDiagonalBlockPlanDiscoverySolve,
  multiquadraticOffDiagonalBlockAffineConsistencyEvidence,
  $multiquadraticOffDiagonalBlockPlanDiscoveryNativeMinimumEntries,
  multiquadraticOffDiagonalBlockConstrainedPlanValidQ,
  multiquadraticOffDiagonalBlockConstrainedPlanDiscover,
  multiquadraticOffDiagonalBlockFullResidualEvidenceValidQ,
  multiquadraticOffDiagonalBlockConstrainedAffineSolve,
  multiquadraticOffDiagonalBlockConstrainedAffineFallback,
  multiquadraticOffDiagonalBlockFollowerImagePayload,
  multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ,
  multiquadraticOffDiagonalBlockFollowerImageSolve,
  multiquadraticOffDiagonalBlockFollowerImageAuthenticate,
  multiquadraticOffDiagonalBlockFollowerImageTask,
  multiquadraticOffDiagonalBlockFollowerImageKernelCount,
  multiquadraticOffDiagonalBlockFollowerImageWave,
  multiquadraticOffDiagonalBlockPilotImageRecord,
  multiquadraticOffDiagonalBlockPilotImageAuthenticate,
  multiquadraticOffDiagonalBlockProviderSupportLadder,
  multiquadraticOffDiagonalBlockUnpackVector,
  multiquadraticOffDiagonalBlockChannelMatrixProduct,
  multiquadraticOffDiagonalBlockExactChannelResidual
];

(* ------------------------------------------------------------------ *)
(* Prime forms and regulator collapse                                   *)
(* ------------------------------------------------------------------ *)

multiquadraticOffDiagonalBlockMapRationals[expression_, sourceType_String, function_] := Which[
  AssociationQ[expression] && Lookup[expression, "Type", None] === sourceType,
    function[expression],
  AssociationQ[expression],
    Map[multiquadraticOffDiagonalBlockMapRationals[#1, sourceType, function] &, expression],
  ListQ[expression],
    multiquadraticOffDiagonalBlockMapRationals[#1, sourceType, function] & /@ expression,
  True, expression
];

multiquadraticOffDiagonalBlockReducePolynomial[polynomial_Association, prime_Integer] := Module[
  {rows},
  rows = Map[multiquadraticOffDiagonalBlockModRational[#1, prime] &,
    polynomial["EpsilonCoefficientRows"], {2}];
  If[! FreeQ[rows, $Failed], Return[$Failed]];
  <|"Type" -> "MultiquadraticPolynomialPrimeV1",
    "XExponents" -> polynomial["XExponents"],
    "YExponents" -> polynomial["YExponents"],
    "EpsilonCoefficientRows" -> Developer`ToPackedArray[rows], "Prime" -> prime|>
];

multiquadraticOffDiagonalBlockReduceRational[rational_Association, prime_Integer] := Module[
  {numerator, denominator},
  numerator = multiquadraticOffDiagonalBlockReducePolynomial[rational["Numerator"], prime];
  denominator = multiquadraticOffDiagonalBlockReducePolynomial[rational["Denominator"], prime];
  If[numerator === $Failed || denominator === $Failed, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalPrimeV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

SetAttributes[multiquadraticOffDiagonalBlockCacheInsert, HoldFirst];
SetAttributes[multiquadraticOffDiagonalBlockCacheLookup, HoldFirst];
multiquadraticOffDiagonalBlockCacheLookup[cacheSymbol_Symbol, predicate_] := Module[
  {entry},
  If[! AssociationQ[cacheSymbol], Return[Missing["NotFound"]]];
  entry = SelectFirst[Values[cacheSymbol], predicate, Missing["NotFound"]];
  If[AssociationQ[entry], Lookup[entry, "Data", Missing["NotFound"]],
    Missing["NotFound"]]
];

multiquadraticOffDiagonalBlockCacheInsert[cacheSymbol_Symbol, key_, value_,
    maximum_Integer] := (
  If[! AssociationQ[cacheSymbol], cacheSymbol = <||>];
  If[Length[cacheSymbol] >= maximum,
    KeyDropFrom[cacheSymbol, First[Keys[cacheSymbol]]]];
  AssociateTo[cacheSymbol, key -> value];
  value);

multiquadraticOffDiagonalBlockPrimeForms[assembly_Association, prime_Integer] := Module[
  {cached, forms, data},
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPrimeFormsInput"]]];
  cached = multiquadraticOffDiagonalBlockCacheLookup[$multiquadraticOffDiagonalBlockPrimeCache,
    AssociationQ[#1] && Lookup[#1, "Prime", None] === prime &&
      SameQ[Lookup[#1, "SourceForms", None], assembly["CompiledForms"]] &];
  If[AssociationQ[cached], Return[cached]];
  forms = multiquadraticOffDiagonalBlockMapRationals[assembly["CompiledForms"],
    "MultiquadraticRationalExactV1",
    multiquadraticOffDiagonalBlockReduceRational[#1, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticOffDiagonalBlockFailure["PrimeReductionFailed",
      <|"Prime" -> prime|>]]];
  data = <|
    "Status" -> "MultiquadraticOffDiagonalBlockPrimeFormsV1",
    "Prime" -> prime, "Forms" -> forms|>;
  multiquadraticOffDiagonalBlockCacheInsert[$multiquadraticOffDiagonalBlockPrimeCache,
    CreateUUID[], <|"SourceForms" -> assembly["CompiledForms"],
      "Prime" -> prime, "Data" -> data|>, 8];
  data
];

multiquadraticOffDiagonalBlockCollapsePolynomial[polynomial_Association, epsilonMod_Integer,
    prime_Integer] := Module[{coefficients, keep},
  If[polynomial["EpsilonCoefficientRows"] === {},
    Return[<|"Type" -> "MultiquadraticPolynomialImageV1", "XExponents" -> {},
      "YExponents" -> {}, "Coefficients" -> {}, "Prime" -> prime|>]];
  coefficients = Fold[Mod[#1 epsilonMod + #2, prime] &, 0, Reverse[#1]] & /@
    polynomial["EpsilonCoefficientRows"];
  keep = Flatten[Position[coefficients, Except[0], {1}, Heads -> False]];
  <|"Type" -> "MultiquadraticPolynomialImageV1",
    "XExponents" -> Developer`ToPackedArray[polynomial["XExponents"][[keep]]],
    "YExponents" -> Developer`ToPackedArray[polynomial["YExponents"][[keep]]],
    "Coefficients" -> Developer`ToPackedArray[coefficients[[keep]]],
    "Prime" -> prime|>
];

multiquadraticOffDiagonalBlockCollapseRational[rational_Association, epsilonMod_Integer,
    prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticOffDiagonalBlockCollapsePolynomial[rational["Numerator"],
    epsilonMod, prime];
  denominator = multiquadraticOffDiagonalBlockCollapsePolynomial[rational["Denominator"],
    epsilonMod, prime];
  If[denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalImageV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

multiquadraticOffDiagonalBlockMaximumExponents[forms_] := Module[{polynomials, nonzero},
  polynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  nonzero = Select[polynomials, Lookup[#1, "Coefficients", {}] =!= {} &];
  If[nonzero === {}, {0, 0},
    {Max[Max /@ Lookup[nonzero, "XExponents"]],
     Max[Max /@ Lookup[nonzero, "YExponents"]]}]
];

multiquadraticOffDiagonalBlockCollapseEpsilon[assembly_Association, prime_Integer,
    epsilonValue_] := Module[
  {cached, primeForms, epsilonMod, forms, maximum, data},
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCollapseInput"]]];
  epsilonMod = multiquadraticOffDiagonalBlockModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  cached = multiquadraticOffDiagonalBlockCacheLookup[$multiquadraticOffDiagonalBlockEpsilonCache,
    AssociationQ[#1] && Lookup[#1, "Prime", None] === prime &&
      Lookup[#1, "EpsilonMod", None] === epsilonMod &&
      SameQ[Lookup[#1, "SourceForms", None], assembly["CompiledForms"]] &];
  If[AssociationQ[cached], Return[cached]];
  primeForms = multiquadraticOffDiagonalBlockPrimeForms[assembly, prime];
  If[Lookup[primeForms, "Status", None] =!= "MultiquadraticOffDiagonalBlockPrimeFormsV1",
    Return[primeForms]];
  forms = multiquadraticOffDiagonalBlockMapRationals[primeForms["Forms"],
    "MultiquadraticRationalPrimeV1",
    multiquadraticOffDiagonalBlockCollapseRational[#1, epsilonMod, prime] &];
  If[! FreeQ[forms, $Failed],
    Return[multiquadraticOffDiagonalBlockFailure["RegulatorCollapseFailed",
      <|"Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  maximum = multiquadraticOffDiagonalBlockMaximumExponents[forms];
  data = <|
    "Status" -> "MultiquadraticOffDiagonalBlockEpsilonFormsV1",
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "MaximumExponents" -> maximum,
    "Forms" -> forms|>;
  multiquadraticOffDiagonalBlockCacheInsert[$multiquadraticOffDiagonalBlockEpsilonCache,
    CreateUUID[], <|"SourceForms" -> assembly["CompiledForms"],
      "Prime" -> prime, "EpsilonMod" -> epsilonMod, "Data" -> data|>, 32];
  data
];

multiquadraticOffDiagonalBlockPolynomialImageValidQ[polynomial_Association, prime_Integer,
    allowZero_: True] := Module[{xExponents, yExponents, coefficients},
  If[Sort[Keys[polynomial]] =!= Sort[{"Type", "XExponents", "YExponents",
      "Coefficients", "Prime"}] ||
      polynomial["Type"] =!= "MultiquadraticPolynomialImageV1" ||
      polynomial["Prime"] =!= prime, Return[False]];
  xExponents = polynomial["XExponents"];
  yExponents = polynomial["YExponents"];
  coefficients = polynomial["Coefficients"];
  TrueQ[VectorQ[xExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[yExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[coefficients, IntegerQ[#1] && 0 <= #1 < prime &] &&
    Length[xExponents] === Length[yExponents] === Length[coefficients] &&
    (TrueQ[allowZero] || coefficients =!= {})]
];

multiquadraticOffDiagonalBlockRationalImageValidQ[rational_Association, prime_Integer] :=
  TrueQ[
    Sort[Keys[rational]] === Sort[{"Type", "Numerator", "Denominator", "Prime"}] &&
    rational["Type"] === "MultiquadraticRationalImageV1" &&
    rational["Prime"] === prime && AssociationQ[rational["Numerator"]] &&
    AssociationQ[rational["Denominator"]] &&
    multiquadraticOffDiagonalBlockPolynomialImageValidQ[rational["Numerator"], prime, True] &&
    multiquadraticOffDiagonalBlockPolynomialImageValidQ[rational["Denominator"], prime, False]];

multiquadraticOffDiagonalBlockEpsilonFormsValidQ[assembly_Association, forms_Association,
    prime_Integer] := Module[
  {imageForms, rationalLeaves, epsilonMod, maximumExponents, expectedKeys},
  expectedKeys = {"Status", "Prime", "EpsilonValue", "EpsilonMod",
    "MaximumExponents", "Forms"};
  If[Sort[Keys[forms]] =!= Sort[expectedKeys] ||
      Lookup[forms, "Status", None] =!= "MultiquadraticOffDiagonalBlockEpsilonFormsV1" ||
      Lookup[forms, "Prime", None] =!= prime, Return[False]];
  epsilonMod = Lookup[forms, "EpsilonMod", $Failed];
  maximumExponents = Lookup[forms, "MaximumExponents", $Failed];
  imageForms = Lookup[forms, "Forms", $Failed];
  If[! IntegerQ[epsilonMod] || ! (0 <= epsilonMod < prime) ||
      multiquadraticOffDiagonalBlockModRational[forms["EpsilonValue"], prime] =!= epsilonMod ||
      ! MatchQ[maximumExponents, {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! AssociationQ[imageForms], Return[False]];
  rationalLeaves = Cases[imageForms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticRationalImageV1" :>
      association, {0, Infinity}];
  TrueQ[rationalLeaves =!= {} &&
    AllTrue[rationalLeaves, multiquadraticOffDiagonalBlockRationalImageValidQ[#1, prime] &] &&
    multiquadraticOffDiagonalBlockMaximumExponents[imageForms] === maximumExponents &&
    multiquadraticOffDiagonalBlockFormShape[imageForms] ===
      multiquadraticOffDiagonalBlockFormShape[assembly["CompiledForms"]]]
];

multiquadraticOffDiagonalBlockEvaluatePolynomial[polynomial_Association,
    xPowers_Association, yPowers_Association, prime_Integer] := Module[
  {monomials, terms},
  If[polynomial["Coefficients"] === {}, Return[0]];
  monomials = Mod[Lookup[xPowers, polynomial["XExponents"]]
    Lookup[yPowers, polynomial["YExponents"]], prime];
  terms = Mod[polynomial["Coefficients"] monomials, prime];
  Mod[Total[terms], prime]
];

multiquadraticOffDiagonalBlockEvaluateRational[rational_Association, xPowers_Association,
    yPowers_Association, prime_Integer] := Module[{numerator, denominator},
  numerator = multiquadraticOffDiagonalBlockEvaluatePolynomial[rational["Numerator"],
    xPowers, yPowers, prime];
  denominator = multiquadraticOffDiagonalBlockEvaluatePolynomial[rational["Denominator"],
    xPowers, yPowers, prime];
  If[denominator === 0, Throw[$Failed, "MultiquadraticOffDiagonalBlockBadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

multiquadraticOffDiagonalBlockEvaluateForms[forms_, xPowers_Association,
    yPowers_Association, prime_Integer] :=
  multiquadraticOffDiagonalBlockMapRationals[forms, "MultiquadraticRationalImageV1",
    multiquadraticOffDiagonalBlockEvaluateRational[#1, xPowers, yPowers, prime] &];

multiquadraticOffDiagonalBlockMaskFactorMod[mask_Integer, deltaValues_List, prime_Integer] :=
  Fold[Mod[#1 #2, prime] &, 1,
    Pick[deltaValues, BitGet[mask,
      If[deltaValues === {}, {}, Range[0, Length[deltaValues] - 1]]], 1]];

multiquadraticOffDiagonalBlockCharacter[signMask_Integer, grade_Integer, rank_Integer] :=
  If[Mod[Total[BitGet[BitAnd[signMask, grade],
      If[rank === 0, {}, Range[0, rank - 1]]]], 2] === 0, 1, -1];

(* ------------------------------------------------------------------ *)
(* Point and sample assembly (production: no branch flip)               *)
(* ------------------------------------------------------------------ *)

multiquadraticOffDiagonalBlockAssemblePointInternal[assembly_Association,
    epsilonForms_Association, prime_Integer,
    point : {_Integer, _Integer}] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["OffDiagonalBasisTransformationNumeratorSupport"], supportCount, unknownCount,
   offDiagonalBasisTransformationUnknownCount, oneFormCount, epsilonMod, forms, imagePolynomials,
   requiredXExponents, requiredYExponents, x, y, xPowers, yPowers, evaluated,
   primitiveEvaluated, primitiveDeltaValues, primitiveDenominatorValue,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   offDiagonalBasisTransformationDenominatorLogDerivatives, rootLogDerivatives, eValues, cValues, inhomogeneityValues,
   oneFormValues, monomialValues, basisValues, basisDerivatives, xInverse,
   yInverse, half, logarithmicDerivative, targetGrade, sourceGrade,
   productGrade, productFactor, mu, i, j, a, b, letter, monomial,
   productWeight, productGrades, productWeights, rowIndex, rowCount, rows,
   right, row, offDiagonalBasisTransformationCoefficientRow, residueRow, residueRowExpectedWidth, assemblySeconds,
   coefficients, assembled},
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  offDiagonalBasisTransformationUnknownCount = assembly["OffDiagonalBasisTransformationUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = epsilonForms["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroRegulatorImage"],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  {x, y} = Mod[point, prime];
  If[x === 0 || y === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroPointCoordinate", <|"Point" -> point|>],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  forms = epsilonForms["Forms"];
  imagePolynomials = Cases[forms, association_Association /;
    Lookup[association, "Type", None] === "MultiquadraticPolynomialImageV1" :>
      association, {0, Infinity}];
  requiredXExponents = Union[support[[All, 1]],
    Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
  requiredYExponents = Union[support[[All, 2]],
    Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
  xPowers = AssociationThread[requiredXExponents,
    PowerMod[x, #1, prime] & /@ requiredXExponents];
  yPowers = AssociationThread[requiredYExponents,
    PowerMod[y, #1, prime] & /@ requiredYExponents];
  evaluated = Catch[multiquadraticOffDiagonalBlockEvaluateForms[forms, xPowers, yPowers,
    prime], "MultiquadraticOffDiagonalBlockBadPoint"];
  If[evaluated === $Failed,
    (* separate the two admissible reasons for a bad point: a ramified
       or non-split root image, and a zero of the basis-transformation block denominator *)
    primitiveEvaluated = Catch[multiquadraticOffDiagonalBlockEvaluateForms[
      KeyTake[forms, {"QuadraticRadicands", "OffDiagonalBasisTransformationDenominator"}], xPowers, yPowers,
      prime], "MultiquadraticOffDiagonalBlockBadPoint"];
    If[AssociationQ[primitiveEvaluated],
      primitiveDeltaValues = primitiveEvaluated["QuadraticRadicands"];
      If[VectorQ[primitiveDeltaValues, IntegerQ] &&
          Length[primitiveDeltaValues] === assembly["RootCount"] &&
          MemberQ[primitiveDeltaValues, 0],
        Throw[multiquadraticOffDiagonalBlockFailure["DegenerateRootImage",
          <|"Point" -> point,
            "QuadraticRadicandValues" -> primitiveDeltaValues|>],
          "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
      primitiveDenominatorValue = primitiveEvaluated["OffDiagonalBasisTransformationDenominator"];
      If[IntegerQ[primitiveDenominatorValue] && primitiveDenominatorValue === 0,
        Throw[multiquadraticOffDiagonalBlockFailure["ZeroOffDiagonalBasisTransformationDenominator",
          <|"Point" -> point|>], "MultiquadraticOffDiagonalBlockAssemblyFailure"]]];
    Throw[multiquadraticOffDiagonalBlockFailure["RationalChannelPole", <|"Point" -> point|>],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  deltaValues = evaluated["QuadraticRadicands"];
  If[! VectorQ[deltaValues, IntegerQ] ||
      Length[deltaValues] =!= assembly["RootCount"] || MemberQ[deltaValues, 0],
    Throw[multiquadraticOffDiagonalBlockFailure["DegenerateRootImage",
      <|"Point" -> point, "QuadraticRadicandValues" -> deltaValues|>],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  denominatorValue = evaluated["OffDiagonalBasisTransformationDenominator"];
  If[! IntegerQ[denominatorValue] || denominatorValue === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroOffDiagonalBasisTransformationDenominator", <|"Point" -> point|>],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  (* ---- THE PROVIDER INTERFACE (round-2 item 10).  Everything above is
     the COMPILED-CHANNEL PROVIDER: it answers "what are the coefficient
     values at this point?" out of the compiled exact channels.  The row
     equation itself is one equation and lives in ONE place, which the
     two direct providers feed with the same association. *)
  coefficients = <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "CompiledChannel", "Prime" -> prime,
    "Point" -> {x, y},
    "RegulatorValue" -> epsilonForms["EpsilonValue"],
    "EpsilonMod" -> epsilonMod,
    "QuadraticRadicands" -> deltaValues,
    "SquareRootGeneratorValues" -> If[AllTrue[deltaValues,
      modularResidueQ[#1, prime] &],
      multiquadraticSquareRoots[deltaValues, prime],
      ConstantArray[0, Length[deltaValues]]],
    "SplitPointQ" -> AllTrue[deltaValues,
      modularResidueQ[#1, prime] &],
    "OffDiagonalBasisTransformationDenominator" -> denominatorValue,
    "OffDiagonalBasisTransformationDenominatorLogDerivatives" -> evaluated["OffDiagonalBasisTransformationDenominatorLogDerivatives"],
    "RootLogDerivatives" -> evaluated["RootLogDerivatives"],
    "E" -> evaluated["E"], "C" -> evaluated["C"],
    "Inhomogeneity" -> evaluated["Inhomogeneity"], "OneForms" -> evaluated["OneForms"]|>;
  assembled = multiquadraticOffDiagonalBlockAssemblePointRows[assembly, coefficients];
  If[Lookup[assembled, "Status", None] =!= "AssembledMultiquadraticPointV1",
    Throw[assembled, "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  Join[assembled,
    <|"AssemblySeconds" -> N[AbsoluteTime[] - startTime]|>]
], "MultiquadraticOffDiagonalBlockAssemblyFailure"];

multiquadraticOffDiagonalBlockNormalizationRows[assembly_Association, epsilonValue_,
    prime_Integer] := Module[
  {unknownCount = assembly["UnknownCount"], epsilon = assembly["Regulator"],
   rows, right},
  rows = Table[Developer`ToPackedArray[ReplacePart[
      ConstantArray[0, unknownCount], normalization["Column"] -> 1]],
    {normalization, assembly["Normalizations"]}];
  right = multiquadraticOffDiagonalBlockModRational[
      #1["Value"] /. epsilon -> epsilonValue, prime] & /@
    assembly["Normalizations"];
  If[MemberQ[right, $Failed], $Failed,
    {Developer`ToPackedArray[rows], Developer`ToPackedArray[right]}]
];

(* The production sampler.  It has NO branch-flip option: a direct
   grade row is branch invariant, so a flip mask changes no equation
   and recording one would suggest the sample depended on it (package
   bug handoff 2026-08-23, External gap 1).  Passing the option is a
   typed error.
   The grade rows need no split point at all -- that is the point of
   the direct channel basis -- so "SplitPointsOnly" defaults to False.
   A caller that will transform the sample into sign branches (the
   certificate path) asks for split points explicitly. *)
Options[multiquadraticOffDiagonalBlockAssembleSample] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "CandidatePoints" -> Automatic,
  "SplitPointsOnly" -> False,
  "SplitSparseEvaluationPlan" -> Automatic,
  "MaximumMatrixBytes" -> Automatic
};

multiquadraticOffDiagonalBlockAssembleSample[assembly_Association, epsilonValue_,
    prime_Integer, opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, epsilonForms, pointCount, maximumAttempts,
   randomSeed, candidatePoints, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0, point,
   pointResult, pointRows, pointRight, normalization, matrix, right,
   pointRanges, equationCount, splitOnly, maximumMatrixBytes,
   matrixEstimate, matrixAdmission},
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[OptionValue["SplitSparseEvaluationPlan"] =!= Automatic,
    Return[multiquadraticOffDiagonalBlockFailure[
      "SplitSparseEvaluationPlanNotApplicable"]]];
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      ! (3 < prime < 2^31),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSampleAssemblyInput"]]];
  epsilonForms = multiquadraticOffDiagonalBlockCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticOffDiagonalBlockEpsilonFormsV1" ||
      ! multiquadraticOffDiagonalBlockEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[If[AssociationQ[epsilonForms] &&
        Lookup[epsilonForms, "Status", None] =!=
          "MultiquadraticOffDiagonalBlockEpsilonFormsV1", epsilonForms,
      multiquadraticOffDiagonalBlockFailure["RegulatorFormsInvalid"]]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(assembly["UnknownCount"] + assembly["EquationsPerPoint"])/
      assembly["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  splitOnly = TrueQ[OptionValue["SplitPointsOnly"]];
  maximumMatrixBytes = Replace[OptionValue["MaximumMatrixBytes"],
    Automatic :> $multiquadraticOffDiagonalBlockSampleMaximumBytes];
  If[! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[maximumAttempts] ||
      maximumAttempts < pointCount || ! IntegerQ[randomSeed] ||
      ! (NumericQ[maximumMatrixBytes] && maximumMatrixBytes > 0) ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSampleAssemblyOptions"]]];
  matrixEstimate = multiquadraticOffDiagonalBlockSampleSizeEstimate[pointCount,
    assembly["EquationsPerPoint"], Length[assembly["Normalizations"]],
    assembly["UnknownCount"]];
  matrixAdmission = multiquadraticOffDiagonalBlockSampleAdmissionRefusal[
    matrixEstimate, maximumMatrixBytes];
  If[AssociationQ[matrixAdmission], Return[matrixAdmission]];
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts,
      attempts++;
      point = If[candidatePoints === Automatic,
        RandomInteger[{2, prime - 2}, 2],
        candidateIndex++;
        If[candidateIndex > Length[candidatePoints], Break[]];
        candidatePoints[[candidateIndex]]];
      pointResult = multiquadraticOffDiagonalBlockAssemblePointInternal[assembly,
        epsilonForms, prime, point];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1" &&
          splitOnly && ! AllTrue[pointResult["QuadraticRadicandValues"],
            modularResidueQ[#1, prime] &],
        pointResult = multiquadraticOffDiagonalBlockFailure["PointNotSplitOverPrime",
          <|"Point" -> point|>]];
      If[Lookup[pointResult, "Status", None] === "AssembledMultiquadraticPointV1",
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> point,
            "FailureReason" -> "DuplicatePointModuloPrime"|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, pointResult]],
        AppendTo[rejected, <|"Point" -> point,
          "FailureReason" -> Lookup[pointResult, "Status", None]|>]]]
  ];
  If[Length[accepted] < pointCount,
    Return[multiquadraticOffDiagonalBlockFailure["InsufficientDirectChannelPoints",
      <|"AcceptedPointCount" -> Length[accepted], "AttemptCount" -> attempts,
        "RejectedPoints" -> rejected|>]]];
  normalization = multiquadraticOffDiagonalBlockNormalizationRows[assembly, epsilonValue,
    prime];
  If[normalization === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure["NormalizationValueSingular"]]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[If[Length[normalization[[1]]] === 0,
    pointRows, Join[pointRows, Normal[normalization[[1]]]]]];
  right = Developer`ToPackedArray[Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = assembly["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsilonForms["EpsilonMod"],
    "Matrix" -> matrix, "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointQuadraticRadicandValues" ->
      Lookup[accepted, "QuadraticRadicandValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "SplitPointsOnly" -> splitOnly,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> assembly["ColumnOrder"], "RowOrder" -> assembly["RowOrder"],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];

(* The provider-backed production sampler.  This is the only five-
   argument implementation: every provider supplies coefficients, and
   every coefficient record reaches multiquadraticOffDiagonalBlockAssemblePointRows.
   The historical compiled signature above remains a compatibility
   oracle until its callers are migrated, but contains no independent
   row equation. *)
multiquadraticOffDiagonalBlockAssembleSample[layout_Association,
    provider_Association, epsilonValue_, prime_Integer,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, pointCount, maximumAttempts,
   randomSeed, candidatePoints, splitOnly, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey, attempts = 0, candidateIndex = 0,
   point, preflight, coefficients, pointResult, normalization,
   normalizationSeconds, pointRows, pointRight, matrix, right, pointRanges,
   equationCount, preflightSeconds = 0., coefficientSeconds = 0.,
   rowSeconds = 0., largeEntryEvaluations = 0, preflightRejects = 0,
   providerCalls = 0, trainingImageKeys,
   splitCompileAttempts = 0, splitCompileCacheHits = 0,
   splitCompileCacheMisses = 0, splitSparseSuccesses = 0,
   splitSubstitutionFallbacks = 0, splitCompileSeconds = 0.,
   splitEvaluationSeconds = 0., splitFallbackSeconds = 0.,
   requestedSplitPlan, splitPlan = Automatic, splitPlanBuildSeconds = 0.,
   splitPlanBuildCompileInvocations = 0,
   splitUniqueLeafEvaluationSeconds = 0., splitOccurrenceGatherSeconds = 0.,
   splitBundleCompositionSeconds = 0., splitNativeSuccesses = 0,
   preflightBatch, nativeBatch, suppliedChannels, batchIndex,
   candidateExhausted = False, nativeBatchEligible = False,
   nativeBatchAttemptCount = 0, nativeBatchSuccessCount = 0,
   nativeBatchFallbackCount = 0, nativeBatchSeconds = 0.,
   nativePlanWriteSeconds = 0., nativePointWriteSeconds = 0.,
   nativeAdapterSeconds = 0., nativeResponseReadSeconds = 0.,
   coefficientBatch, nativeRowBatch, suppliedPointResults,
   nativeRowBatchEligible = False, nativeRowBatchAttemptCount = 0,
   nativeRowBatchSuccessCount = 0, nativeRowBatchFallbackCount = 0,
   nativeRowBatchSeconds = 0., nativeRowInputWriteSeconds = 0.,
   nativeRowAdapterSeconds = 0., nativeRowResponseReadSeconds = 0.,
   nativePreflightBatch, nativePreflightRecords = Automatic,
   nativeCandidatePoints, nativePreflightBatchEligible = False,
   nativePreflightBatchAttemptCount = 0,
   nativePreflightBatchSuccessCount = 0,
   nativePreflightBatchFallbackCount = 0,
   nativePreflightBatchSeconds = 0.,
   nativePreflightCompileSeconds = 0.,
   nativePreflightEvaluationSeconds = 0.,
   nativePreflightDecodeSeconds = 0.,
   deferredNativeSourceQ = False, deferredNativeBatch,
   deferredNativeInhomogeneityBatch = Automatic,
   deferredNativeBatchAttemptCount = 0,
   deferredNativeBatchSuccessCount = 0,
   deferredNativeBatchFailureCount = 0,
   deferredNativeBatchSeconds = 0.,
   deferredNativeParseSeconds = 0.,
   deferredNativeEvaluationSeconds = 0., maximumMatrixBytes,
   matrixEstimate, matrixAdmission},
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockAssembleSample]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticOffDiagonalBlockAssemblyLayoutEvaluationValidQ[layout] ||
      ! multiquadraticOffDiagonalBlockProviderEvaluationValidQ[provider] ||
      ! PrimeQ[prime] ||
      (Lookup[provider, "RootCount", 0] > 0 && Mod[prime, 4] =!= 3) ||
      ! (3 < prime < $multiquadraticOffDiagonalBlockWordPrimeLimit),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidProviderSampleInput"]]];
  If[! SameQ[layout["CoefficientData"], provider["CoefficientData"]],
    Return[multiquadraticOffDiagonalBlockFailure["ProviderLayoutMismatch",
      <|"LayoutCoefficientData" -> layout["CoefficientData"],
        "ProviderCoefficientData" -> provider["CoefficientData"],
        "LargeEntryEvaluationCount" -> 0|>]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(layout["UnknownCount"] + layout["EquationsPerPoint"])/
      layout["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  splitOnly = TrueQ[OptionValue["SplitPointsOnly"]];
  requestedSplitPlan = OptionValue["SplitSparseEvaluationPlan"];
  maximumMatrixBytes = Replace[OptionValue["MaximumMatrixBytes"],
    Automatic :> $multiquadraticOffDiagonalBlockSampleMaximumBytes];
  If[! IntegerQ[pointCount] || pointCount < 1 ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount ||
      ! IntegerQ[randomSeed] ||
      ! (NumericQ[maximumMatrixBytes] && maximumMatrixBytes > 0) ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSampleAssemblyOptions"]]];
  matrixEstimate = multiquadraticOffDiagonalBlockSampleSizeEstimate[pointCount,
    layout["EquationsPerPoint"], Length[layout["Normalizations"]],
    layout["UnknownCount"]];
  matrixAdmission = multiquadraticOffDiagonalBlockSampleAdmissionRefusal[
    matrixEstimate, maximumMatrixBytes];
  If[AssociationQ[matrixAdmission], Return[matrixAdmission]];
  deferredNativeSourceQ =
    AssociationQ[Lookup[provider, "DeferredPreparation", None]];
  If[provider["Kind"] === "SplitBranch",
    If[deferredNativeSourceQ,
      (* The ordinary split plan includes every deferred-bundle operand.
         Native Inhomogeneity makes those leaves dead work; E/C and one-forms take
         the existing unplanned direct path until a filtered plan is shown
         to pay on a physical block. *)
      If[! MemberQ[{Automatic, None}, requestedSplitPlan],
        Return[multiquadraticOffDiagonalBlockFailure[
          "SplitSparseEvaluationPlanNotApplicable"]]];
      splitPlan = Automatic,
      Which[
      requestedSplitPlan === Automatic,
        {splitPlanBuildSeconds, splitPlan} = AbsoluteTiming[
          multiquadraticOffDiagonalBlockSplitSparseEvaluationPlan[provider, prime]];
        If[Lookup[splitPlan, "Status", None] =!=
            "MultiquadraticSplitSparseEvaluationPlanV1",
          Return[multiquadraticOffDiagonalBlockFailure[
            "SplitSparseEvaluationPlanBuildFailed",
            <|"Detail" -> splitPlan|>]]];
        splitPlanBuildCompileInvocations = Lookup[splitPlan,
          "BuildCompileInvocationCount", 0],
      requestedSplitPlan === None,
        splitPlan = Automatic,
      AssociationQ[requestedSplitPlan] &&
          multiquadraticOffDiagonalBlockSplitSparseEvaluationPlanValidQ[
            requestedSplitPlan, provider, prime],
        splitPlan = requestedSplitPlan,
      True,
        Return[multiquadraticOffDiagonalBlockFailure[
          "InvalidSplitSparseEvaluationPlan",
          <|"Prime" -> prime|>]]]];
    If[splitPlan =!= Automatic &&
        ! SameQ[Lookup[splitPlan, "CoefficientData", None],
          layout["CoefficientData"]],
      Return[multiquadraticOffDiagonalBlockFailure[
        "SplitSparseEvaluationPlanLayoutMismatch"]]],
    If[! MemberQ[{Automatic, None}, requestedSplitPlan],
      Return[multiquadraticOffDiagonalBlockFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]]];
  nativeBatchEligible = AssociationQ[splitPlan] &&
    StringQ[multiquadraticOffDiagonalBlockNativeSparseBinary[]] &&
    AllTrue[Lookup[splitPlan["Leaves"], "Compiled", {}], AssociationQ];
  nativeRowBatchEligible =
    StringQ[multiquadraticOffDiagonalBlockNativeRowBinary[]];
  nativePreflightBatchEligible = provider["Kind"] === "SplitBranch" &&
    StringQ[multiquadraticOffDiagonalBlockNativeSparseBinary[]] &&
    maximumAttempts <= 100000;
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    If[nativePreflightBatchEligible,
      nativeCandidatePoints = If[candidatePoints === Automatic,
        Table[RandomInteger[{2, prime - 2}, 2], {maximumAttempts}],
        Take[candidatePoints, UpTo[maximumAttempts]]];
      nativePreflightBatchAttemptCount++;
      nativePreflightBatch = multiquadraticOffDiagonalBlockNativePreflightBatch[
        provider, epsilonValue, prime, nativeCandidatePoints, 1];
      nativePreflightBatchSeconds += Lookup[nativePreflightBatch,
        "Seconds", 0.];
      candidatePoints = nativeCandidatePoints;
      If[Lookup[nativePreflightBatch, "Status", None] ===
          "MultiquadraticNativePreflightBatchV1",
        nativePreflightBatchSuccessCount++;
        nativePreflightRecords = nativePreflightBatch["Records"];
        preflightSeconds += nativePreflightBatch["Seconds"];
        nativePreflightCompileSeconds += Lookup[nativePreflightBatch,
          "CompileSeconds", 0.];
        nativePreflightEvaluationSeconds += Lookup[nativePreflightBatch,
          "NativeBatchSeconds", 0.];
        nativePreflightDecodeSeconds += Lookup[nativePreflightBatch,
          "DecodeSeconds", 0.],
        nativePreflightBatchFallbackCount++]];
    While[Length[accepted] < pointCount && attempts < maximumAttempts &&
        ! candidateExhausted,
      preflightBatch = {};
      While[Length[preflightBatch] < pointCount - Length[accepted] &&
          attempts < maximumAttempts && ! candidateExhausted,
        attempts++;
        If[candidatePoints === Automatic,
          point = RandomInteger[{2, prime - 2}, 2],
          candidateIndex++;
          If[candidateIndex > Length[candidatePoints],
            candidateExhausted = True; Break[]];
          point = candidatePoints[[candidateIndex]]];
        preflight = If[ListQ[nativePreflightRecords],
          nativePreflightRecords[[candidateIndex]],
          multiquadraticOffDiagonalBlockProviderPreflight[provider,
            epsilonValue, prime, point]];
        preflightSeconds += Lookup[preflight, "PreflightSeconds", 0.];
        If[Lookup[preflight, "Status", None] =!=
            "MultiquadraticProviderPreflightV1",
          preflightRejects++;
          AppendTo[rejected, Join[<|"Point" -> Mod[point, prime],
            "FailureReason" -> Lookup[preflight, "Status", None],
            "LargeEntryEvaluationCount" -> 0|>,
            KeyTake[preflight,
              {"QuadraticRadicandValues", "RootIndices"}]]];
          Continue[]];
        If[splitOnly && ! TrueQ[preflight["SplitPointQ"]],
          preflightRejects++;
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> "PointNotSplitOverPrime",
            "LargeEntryEvaluationCount" -> 0|>];
          Continue[]];
        AppendTo[preflightBatch, preflight]];
      If[preflightBatch === {}, Continue[]];
      suppliedChannels = ConstantArray[Automatic, Length[preflightBatch]];
      If[nativeBatchEligible,
        nativeBatchAttemptCount++;
        nativeBatch = multiquadraticOffDiagonalBlockNativeSparseEvaluateBatch[
          splitPlan, preflightBatch, 1];
        nativeBatchSeconds += Lookup[nativeBatch, "Seconds", 0.];
        If[Lookup[nativeBatch, "Status", None] ===
            "MultiquadraticNativeSparseBatchV1",
          nativeBatchSuccessCount++;
          coefficientSeconds += Lookup[nativeBatch, "Seconds", 0.];
          splitUniqueLeafEvaluationSeconds += Lookup[nativeBatch,
            "Seconds", 0.];
          nativePlanWriteSeconds += Lookup[nativeBatch,
            "PlanWriteSeconds", 0.];
          nativePointWriteSeconds += Lookup[nativeBatch,
            "PointWriteSeconds", 0.];
          nativeAdapterSeconds += Lookup[nativeBatch,
            "AdapterSeconds", 0.];
          nativeResponseReadSeconds += Lookup[nativeBatch,
            "ResponseReadSeconds", 0.];
          Do[If[VectorQ[nativeBatch["LeafStatuses"][[batchIndex]],
                #1 === 0 &],
              suppliedChannels[[batchIndex]] =
                nativeBatch["Channels"][[batchIndex]],
              nativeBatchFallbackCount++],
            {batchIndex, Length[preflightBatch]}],
          nativeBatchFallbackCount++]];
      deferredNativeInhomogeneityBatch = Automatic;
      If[deferredNativeSourceQ,
        deferredNativeBatchAttemptCount++;
        deferredNativeBatch =
          multiquadraticOffDiagonalBlockNativeDeferredEvaluateBatch[provider,
            preflightBatch];
        deferredNativeBatchSeconds += Lookup[deferredNativeBatch,
          "Seconds", 0.];
        coefficientSeconds += Lookup[deferredNativeBatch, "Seconds", 0.];
        If[Lookup[deferredNativeBatch, "Status", None] ===
              "MultiquadraticNativeDeferredBatchV1" &&
            Length[Lookup[deferredNativeBatch, "InhomogeneityBatch", {}]] ===
              Length[preflightBatch],
          deferredNativeBatchSuccessCount++;
          deferredNativeInhomogeneityBatch = deferredNativeBatch["InhomogeneityBatch"];
          deferredNativeParseSeconds += Lookup[deferredNativeBatch,
            "ParseSeconds", 0.];
          deferredNativeEvaluationSeconds += Lookup[deferredNativeBatch,
            "EvaluationSeconds", 0.],
          deferredNativeBatchFailureCount++]];
      coefficientBatch = Table[
        preflight = preflightBatch[[batchIndex]];
        point = preflight["Point"];
        providerCalls++;
        coefficients = If[deferredNativeSourceQ &&
            ! ListQ[deferredNativeInhomogeneityBatch],
          multiquadraticOffDiagonalBlockFailure[
            "NativeDeferredInhomogeneityUnavailable",
            <|"Point" -> point, "Prime" -> prime,
              "RegulatorValue" -> epsilonValue,
              "Detail" -> If[AssociationQ[deferredNativeBatch],
                KeyDrop[deferredNativeBatch, "InhomogeneityBatch"],
                deferredNativeBatch]|>],
          If[ListQ[suppliedChannels[[batchIndex]]],
            multiquadraticOffDiagonalBlockPlannedProviderChannels[provider, preflight,
              splitPlan, suppliedChannels[[batchIndex]]],
            multiquadraticOffDiagonalBlockProviderChannels[provider, epsilonValue,
              prime, point, preflight, splitPlan,
              If[deferredNativeSourceQ, "NativeDeferredAST",
                Automatic]]]];
        coefficientSeconds += Lookup[coefficients, "Seconds", 0.];
        splitCompileAttempts += Lookup[coefficients,
          "SplitSparseCompileAttemptCount", 0];
        splitCompileCacheHits += Lookup[coefficients,
          "SplitSparseCompileCacheHitCount", 0];
        splitCompileCacheMisses += Lookup[coefficients,
          "SplitSparseCompileCacheMissCount", 0];
        splitSparseSuccesses += Lookup[coefficients,
          "SplitSparseEvaluationCount", 0];
        splitNativeSuccesses += Lookup[coefficients,
          "SplitSparseNativeEvaluationCount", 0];
        splitSubstitutionFallbacks += Lookup[coefficients,
          "SplitSubstitutionFallbackCount", 0];
        splitCompileSeconds += Lookup[coefficients,
          "SplitSparseCompileSeconds", 0.];
        splitEvaluationSeconds += Lookup[coefficients,
          "SplitSparseEvaluationSeconds", 0.];
        splitFallbackSeconds += Lookup[coefficients,
          "SplitSubstitutionFallbackSeconds", 0.];
        splitUniqueLeafEvaluationSeconds += Lookup[coefficients,
          "SplitSparseUniqueLeafEvaluationSeconds", 0.];
        splitOccurrenceGatherSeconds += Lookup[coefficients,
          "SplitSparseOccurrenceGatherSeconds", 0.];
        splitBundleCompositionSeconds += Lookup[coefficients,
          "SplitSparseDeferredBundleCompositionSeconds", 0.];
        largeEntryEvaluations += Lookup[coefficients,
          "LargeEntryEvaluationCount", 0];
        If[deferredNativeSourceQ &&
            Lookup[coefficients, "Status", None] ===
              "MultiquadraticPointCoefficientsV1",
          coefficients = Join[coefficients, <|
            "Inhomogeneity" -> deferredNativeInhomogeneityBatch[[batchIndex]],
            "InhomogeneityProvider" -> "NativeDeferredASTV1",
            "NativeDeferredASTTermCount" ->
              Lookup[deferredNativeBatch, "TermCount", 0],
            "NativeDeferredASTUniqueExpressionCount" ->
              Lookup[deferredNativeBatch, "UniqueExpressionCount", 0]|>]];
        coefficients,
        {batchIndex, Length[preflightBatch]}];
      suppliedPointResults = ConstantArray[Automatic,
        Length[preflightBatch]];
      If[nativeRowBatchEligible && AllTrue[coefficientBatch,
          Lookup[#1, "Status", None] ===
            "MultiquadraticPointCoefficientsV1" &],
        nativeRowBatchAttemptCount++;
        nativeRowBatch = multiquadraticOffDiagonalBlockNativeRowAssembleBatch[
          layout, coefficientBatch, 1];
        nativeRowBatchSeconds += Lookup[nativeRowBatch, "Seconds", 0.];
        If[Lookup[nativeRowBatch, "Status", None] ===
            "MultiquadraticNativeRowBatchV1",
          nativeRowBatchSuccessCount++;
          nativeRowInputWriteSeconds += Lookup[nativeRowBatch,
            "InputWriteSeconds", 0.];
          nativeRowAdapterSeconds += Lookup[nativeRowBatch,
            "AdapterSeconds", 0.];
          nativeRowResponseReadSeconds += Lookup[nativeRowBatch,
            "ResponseReadSeconds", 0.];
          suppliedPointResults = Table[
            multiquadraticOffDiagonalBlockPointResult[layout,
              coefficientBatch[[batchIndex]],
              nativeRowBatch["Rows"][[batchIndex]],
              nativeRowBatch["RightHandSides"][[batchIndex]],
              nativeRowBatch["Seconds"]/Length[coefficientBatch]],
            {batchIndex, Length[coefficientBatch]}],
          nativeRowBatchFallbackCount++]];
      Do[
        preflight = preflightBatch[[batchIndex]];
        point = preflight["Point"];
        coefficients = coefficientBatch[[batchIndex]];
        If[Lookup[coefficients, "Status", None] =!=
            "MultiquadraticPointCoefficientsV1",
          AppendTo[rejected, Join[<|"Point" -> Mod[point, prime],
              "FailureReason" -> Lookup[coefficients, "Status", None],
              "LargeEntryEvaluationCount" -> Lookup[coefficients,
                "LargeEntryEvaluationCount", 0]|>,
            KeyTake[coefficients, {"RadicalBase", "NativeStatusCode",
              "DetailIndex", "DetailOffset"}]]];
          Continue[]];
        pointResult = If[AssociationQ[suppliedPointResults[[batchIndex]]],
          suppliedPointResults[[batchIndex]],
          multiquadraticOffDiagonalBlockAssemblePointRows[layout, coefficients]];
        rowSeconds += Lookup[pointResult, "AssemblySeconds", 0.];
        If[Lookup[pointResult, "Status", None] =!=
            "AssembledMultiquadraticPointV1",
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> Lookup[pointResult, "Status", None],
            "LargeEntryEvaluationCount" -> Lookup[coefficients,
              "LargeEntryEvaluationCount", 0]|>];
          Continue[]];
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> Mod[point, prime],
            "FailureReason" -> "DuplicatePointModuloPrime",
            "LargeEntryEvaluationCount" -> Lookup[coefficients,
              "LargeEntryEvaluationCount", 0]|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, Join[pointResult,
            <|"SplitPointQ" -> preflight["SplitPointQ"],
              "PreflightSeconds" -> preflight["PreflightSeconds"],
              "CoefficientSeconds" -> Lookup[coefficients, "Seconds", 0.],
              "LargeEntryEvaluationCount" -> Lookup[coefficients,
                "LargeEntryEvaluationCount", 0]|>]]],
        {batchIndex, Length[preflightBatch]}]
      ]
   ];
  If[Length[accepted] < pointCount,
    Return[multiquadraticOffDiagonalBlockFailure["InsufficientProviderPoints",
      <|"AcceptedPointCount" -> Length[accepted],
        "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
        "RejectedPointReasonCounts" -> Counts[
          Lookup[rejected, "FailureReason", Missing["NoReason"]]],
        "PreflightRejectCount" -> preflightRejects,
        "LargeEntryEvaluationCount" -> largeEntryEvaluations,
        "ProviderCallCount" -> providerCalls|>]]];
  {normalizationSeconds, normalization} = AbsoluteTiming[
    multiquadraticOffDiagonalBlockNormalizationRows[layout, epsilonValue, prime]];
  If[normalization === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure["NormalizationValueSingular"]]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[If[Length[normalization[[1]]] === 0,
    pointRows, Join[pointRows, Normal[normalization[[1]]]]]];
  right = Developer`ToPackedArray[
    Mod[Join[pointRight, normalization[[2]]], prime]];
  equationCount = layout["EquationsPerPoint"];
  pointRanges = Table[{1 + (index - 1) equationCount,
    index equationCount}, {index, Length[accepted]}];
  trainingImageKeys = Table[
    {prime, epsilonValue, accepted[[index, "Point"]]},
    {index, Length[accepted]}];
  <|"Status" -> "AssembledMultiquadraticSampleV1",
    "CoefficientData" -> layout["CoefficientData"],
    "Provider" -> provider["Kind"],
    "TrainingImageKeys" -> trainingImageKeys,
    "Prime" -> prime,
    "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> multiquadraticOffDiagonalBlockModRational[epsilonValue, prime],
    "Matrix" -> matrix, "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointQuadraticRadicandValues" ->
      Lookup[accepted, "QuadraticRadicandValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "SplitPointsOnly" -> splitOnly,
    "PreflightRejectCount" -> preflightRejects,
    "ProviderCallCount" -> providerCalls,
    "LargeEntryEvaluationCount" -> largeEntryEvaluations,
    "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
    "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
    "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
    "SplitSparseEvaluationCount" -> splitSparseSuccesses,
    "SplitSparseNativeEvaluationCount" -> splitNativeSuccesses,
    "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
    "SplitSparseCompileSeconds" -> splitCompileSeconds,
    "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
    "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
    "SplitSparsePlanCacheHit" -> If[AssociationQ[splitPlan],
      TrueQ[Lookup[splitPlan, "PlanCacheHit", False]], False],
    "SplitSparsePlanUniqueLeafCount" -> If[AssociationQ[splitPlan],
      splitPlan["UniqueLeafCount"], 0],
    "SplitSparsePlanOccurrenceCount" -> If[AssociationQ[splitPlan],
      splitPlan["OccurrenceCount"], 0],
    "SplitSparsePlanCompileInvocationCount" -> If[AssociationQ[splitPlan],
      splitPlanBuildCompileInvocations, 0],
    "SplitSparsePlanFallbackLeafCount" -> If[AssociationQ[splitPlan],
      splitPlan["FallbackLeafCount"], 0],
    "SplitSparsePlanConstructionSeconds" -> splitPlanBuildSeconds,
    "SplitSparseNativeBatchEligible" -> nativeBatchEligible,
    "SplitSparseNativeBatchAttemptCount" -> nativeBatchAttemptCount,
    "SplitSparseNativeBatchSuccessCount" -> nativeBatchSuccessCount,
    "SplitSparseNativeBatchFallbackCount" -> nativeBatchFallbackCount,
    "SplitSparseNativeBatchSeconds" -> nativeBatchSeconds,
    "SplitSparseNativePlanWriteSeconds" -> nativePlanWriteSeconds,
    "SplitSparseNativePointWriteSeconds" -> nativePointWriteSeconds,
    "SplitSparseNativeAdapterSeconds" -> nativeAdapterSeconds,
    "SplitSparseNativeResponseReadSeconds" -> nativeResponseReadSeconds,
    "NativeRowBatchEligible" -> nativeRowBatchEligible,
    "NativeRowBatchAttemptCount" -> nativeRowBatchAttemptCount,
    "NativeRowBatchSuccessCount" -> nativeRowBatchSuccessCount,
    "NativeRowBatchFallbackCount" -> nativeRowBatchFallbackCount,
    "NativeRowBatchSeconds" -> nativeRowBatchSeconds,
    "NativeRowInputWriteSeconds" -> nativeRowInputWriteSeconds,
    "NativeRowAdapterSeconds" -> nativeRowAdapterSeconds,
    "NativeRowResponseReadSeconds" -> nativeRowResponseReadSeconds,
    "NativePreflightBatchEligible" -> nativePreflightBatchEligible,
    "NativePreflightBatchAttemptCount" -> nativePreflightBatchAttemptCount,
    "NativePreflightBatchSuccessCount" -> nativePreflightBatchSuccessCount,
    "NativePreflightBatchFallbackCount" -> nativePreflightBatchFallbackCount,
    "NativePreflightBatchSeconds" -> nativePreflightBatchSeconds,
    "NativePreflightCompileSeconds" -> nativePreflightCompileSeconds,
    "NativePreflightEvaluationSeconds" ->
      nativePreflightEvaluationSeconds,
    "NativePreflightDecodeSeconds" -> nativePreflightDecodeSeconds,
    "NativeDeferredSourceQ" -> deferredNativeSourceQ,
    "NativeDeferredBatchAttemptCount" ->
      deferredNativeBatchAttemptCount,
    "NativeDeferredBatchSuccessCount" ->
      deferredNativeBatchSuccessCount,
    "NativeDeferredBatchFailureCount" ->
      deferredNativeBatchFailureCount,
    "NativeDeferredBatchSeconds" -> deferredNativeBatchSeconds,
    "NativeDeferredParseSeconds" -> deferredNativeParseSeconds,
    "NativeDeferredEvaluationSeconds" ->
      deferredNativeEvaluationSeconds,
    "SplitSparseUniqueLeafEvaluationSeconds" ->
      splitUniqueLeafEvaluationSeconds,
    "SplitSparseOccurrenceGatherSeconds" -> splitOccurrenceGatherSeconds,
    "SplitSparseDeferredBundleCompositionSeconds" ->
      splitBundleCompositionSeconds,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> layout["ColumnOrder"],
    "RowOrder" -> layout["RowOrder"],
    "PhaseSeconds" -> <|"Preflight" -> preflightSeconds,
      "NativePreflightBatch" -> nativePreflightBatchSeconds,
      "CoefficientEvaluation" -> coefficientSeconds,
      "RowAssembly" -> rowSeconds,
      "Normalization" -> normalizationSeconds,
      "SplitSparsePlanConstruction" -> splitPlanBuildSeconds,
      "SplitSparseNativeBatch" -> nativeBatchSeconds,
      "NativeDeferredBatch" -> deferredNativeBatchSeconds,
      "NativeRowBatch" -> nativeRowBatchSeconds,
      "SplitSparseUniqueLeafEvaluation" ->
        splitUniqueLeafEvaluationSeconds,
      "SplitSparseOccurrenceGather" -> splitOccurrenceGatherSeconds,
      "SplitSparseDeferredBundleComposition" ->
        splitBundleCompositionSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticOffDiagonalBlockAssembleSample[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidSampleAssemblyArguments"];

(* ------------------------------------------------------------------ *)
(* Sign transforms and the differential certificate                     *)
(* ------------------------------------------------------------------ *)

(* The only place a branch sign exists: the invertible map from grade
   rows to the 2^r split-sign rows at a point.  A flip mask permutes
   the sign blocks and is the object under test, never a production
   parameter. *)
multiquadraticOffDiagonalBlockSignTransform[rootValues_List, prime_Integer] := Module[
  {rank = Length[rootValues], gradeCount, rootProducts},
  If[! PrimeQ[prime] || rank > $multiquadraticOffDiagonalBlockMaximumRootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSignTransformInput"]]];
  gradeCount = 2^rank;
  rootProducts = multiquadraticOffDiagonalBlockMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  Developer`ToPackedArray[Table[
    Mod[multiquadraticOffDiagonalBlockCharacter[signMask, grade, rank]
      rootProducts[[grade + 1]], prime],
    {signMask, 0, gradeCount - 1}, {grade, 0, gradeCount - 1}]]
];

multiquadraticOffDiagonalBlockTransformPointToSigns[pointResult_Association,
    rootValues_List, prime_Integer, flipMask_Integer: 0] := Module[
  {rootCount, gradeCount, equationsPerGrade, unknownCount, deltaValues,
   pointRows, pointRight, transform, rowsByGrade, rightByGrade, rows, right,
   transformedRow, transformedRight, sourceSign, targetGrade},
  If[Lookup[pointResult, "Status", None] =!= "AssembledMultiquadraticPointV1" ||
      Lookup[pointResult, "Prime", None] =!= prime,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPointTransformInput"]]];
  rootCount = Lookup[pointResult, "RootCount", $Failed];
  gradeCount = Lookup[pointResult, "GradeCount", $Failed];
  equationsPerGrade = Lookup[pointResult, "EquationsPerGrade", $Failed];
  unknownCount = Lookup[pointResult, "UnknownCount", $Failed];
  deltaValues = Lookup[pointResult, "QuadraticRadicandValues", $Failed];
  pointRows = Lookup[pointResult, "Rows", $Failed];
  pointRight = Lookup[pointResult, "RightHandSide", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 || ! IntegerQ[gradeCount] ||
      gradeCount =!= 2^rootCount || ! IntegerQ[equationsPerGrade] ||
      equationsPerGrade < 1 || ! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! MatrixQ[pointRows, IntegerQ] ||
      Dimensions[pointRows] =!= {gradeCount equationsPerGrade, unknownCount} ||
      ! AllTrue[Flatten[pointRows], 0 <= #1 < prime &] ||
      ! VectorQ[pointRight, IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[pointRight] =!= gradeCount equationsPerGrade ||
      ! VectorQ[deltaValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Length[deltaValues] =!= rootCount || Length[rootValues] =!= rootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Mod[rootValues^2 - deltaValues, prime] =!= ConstantArray[0, rootCount] ||
      ! IntegerQ[flipMask] || flipMask < 0 || flipMask >= gradeCount,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPointTransformParameters"]]];
  transform = multiquadraticOffDiagonalBlockSignTransform[rootValues, prime];
  If[! ListQ[transform],
    Return[multiquadraticOffDiagonalBlockFailure["SignTransformFailed"]]];
  rowsByGrade = ArrayReshape[pointRows,
    {gradeCount, equationsPerGrade, unknownCount}];
  rightByGrade = ArrayReshape[pointRight, {gradeCount, equationsPerGrade}];
  rows = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRow = ConstantArray[0, unknownCount];
      Do[transformedRow = Mod[transformedRow +
          transform[[sourceSign + 1, targetGrade + 1]]
            rowsByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      Developer`ToPackedArray[transformedRow],
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  right = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRight = 0;
      Do[transformedRight = Mod[transformedRight +
          transform[[sourceSign + 1, targetGrade + 1]]
            rightByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      transformedRight,
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  <|"Status" -> "TransformedMultiquadraticPointToSignsV1", "Prime" -> prime,
    "Point" -> pointResult["Point"], "RootValues" -> rootValues,
    "BranchFlipMask" -> flipMask, "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "SignTransform" -> transform|>
];
multiquadraticOffDiagonalBlockTransformPointToSigns[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidPointTransformArguments"];

multiquadraticOffDiagonalBlockTransformSampleToSigns[assembly_Association,
    sample_Association, prime_Integer, flipMask_Integer: 0] := Module[
  {pointCount, equationCount, normalizationCount, pointResults, transformed,
   deltaValues, rootValues, rows, right, normalizationRows, normalizationRight,
   index, range, expectedRanges, totalRows},
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3 ||
      Lookup[sample, "Status", None] =!= "AssembledMultiquadraticSampleV1" ||
      sample["Prime"] =!= prime ||
      Lookup[sample, "ColumnOrder", None] =!= assembly["ColumnOrder"] ||
      Lookup[sample, "RowOrder", None] =!= assembly["RowOrder"],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSampleTransformInput"]]];
  pointCount = Length[sample["AcceptedPoints"]];
  equationCount = assembly["EquationsPerPoint"];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  totalRows = pointCount equationCount + normalizationCount;
  expectedRanges = Table[{1 + (index - 1) equationCount, index equationCount},
    {index, pointCount}];
  If[pointCount < 1 || ! IntegerQ[normalizationCount] || normalizationCount < 0 ||
      ! MatchQ[sample["AcceptedPoints"], {{_Integer, _Integer} ..}] ||
      ! ListQ[Lookup[sample, "PointQuadraticRadicandValues", None]] ||
      Length[sample["PointQuadraticRadicandValues"]] =!= pointCount ||
      Lookup[sample, "PointRowRanges", None] =!= expectedRanges ||
      ! MatrixQ[Lookup[sample, "Matrix", None], IntegerQ] ||
      Dimensions[sample["Matrix"]] =!= {totalRows, assembly["UnknownCount"]} ||
      ! VectorQ[Lookup[sample, "RightHandSide", None],
        IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[sample["RightHandSide"]] =!= totalRows,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSampleTransformShape"]]];
  pointResults = Table[
    range = sample["PointRowRanges"][[index]];
    <|"Status" -> "AssembledMultiquadraticPointV1", "Prime" -> prime,
      "Point" -> sample["AcceptedPoints"][[index]],
      "Rows" -> sample["Matrix"][[range[[1]] ;; range[[2]]]],
      "RightHandSide" -> sample["RightHandSide"][[range[[1]] ;; range[[2]]]],
      "QuadraticRadicandValues" ->
        sample["PointQuadraticRadicandValues"][[index]],
      "RootCount" -> assembly["RootCount"], "GradeCount" -> assembly["GradeCount"],
      "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
      "UnknownCount" -> assembly["UnknownCount"]|>,
    {index, pointCount}];
  (* Return inside Table does not leave the enclosing function: the
     Codex original (DirectRootChannelAssembler.wl lines 1088-1099)
     leaves an unevaluated Return in the result list, which then
     degrades into a generic transform failure.  Tag the target. *)
  transformed = Table[
    deltaValues = sample["PointQuadraticRadicandValues"][[index]];
    If[! AllTrue[deltaValues, modularResidueQ[#1, prime] &],
      Return[multiquadraticOffDiagonalBlockFailure["PointNotSplitOverPrime",
        <|"PointIndex" -> index,
          "QuadraticRadicandValues" -> deltaValues|>], Module]];
    rootValues = multiquadraticSquareRoots[deltaValues, prime];
    If[rootValues === $Failed,
      Return[multiquadraticOffDiagonalBlockFailure["PointSquareRootFailure",
        <|"PointIndex" -> index|>], Module]];
    multiquadraticOffDiagonalBlockTransformPointToSigns[
      pointResults[[index]], rootValues, prime, flipMask],
    {index, pointCount}];
  If[! AllTrue[transformed, Lookup[#1, "Status", None] ===
      "TransformedMultiquadraticPointToSignsV1" &],
    Return[multiquadraticOffDiagonalBlockFailure[
      "SamplePointTransformFailed", <|
        "PointFailures" -> Select[transformed,
          Lookup[#1, "Status", None] =!=
            "TransformedMultiquadraticPointToSignsV1" &]|>]]];
  rows = Join @@ Lookup[transformed, "Rows"];
  right = Join @@ Lookup[transformed, "RightHandSide"];
  If[normalizationCount > 0,
    normalizationRows = Take[sample["Matrix"], -normalizationCount];
    normalizationRight = Take[sample["RightHandSide"], -normalizationCount];
    rows = Join[rows, normalizationRows];
    right = Join[right, normalizationRight]];
  <|"Status" -> "TransformedMultiquadraticSampleToSignsV1", "Prime" -> prime,
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows], "BranchFlipMask" -> flipMask|>
];
multiquadraticOffDiagonalBlockTransformSampleToSigns[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidSampleTransformArguments"];

(* The independent reference: the same equations built one sign branch
   at a time by substituting +-root values into the exact off-diagonal block equation, with no
   channel decomposition and no compiled representation.  It shares nothing with
   the direct assembler except the index formulas, so agreement is a
   real differential statement. *)
multiquadraticOffDiagonalBlockSplitPointRows[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Catch[Module[
  {variables, epsilon, record, offDiagonalBlockEquation, e, c, inhomogeneity, roots, oneForms, support,
   offDiagonalBasisTransformationDenominator, dimensions, upperDimension, lowerDimension, rank,
   gradeCount, supportCount, offDiagonalBasisTransformationUnknownCount, unknownCount, epsilonMod,
   deltaValues, rootValues, denominatorValue, denominatorInverse,
   denominatorDerivatives, deltaLogDerivatives, rootProducts, signs,
   branchValue, branchMatrix, branchPair, basisValue, basisDerivative,
   eValues, cValues, inhomogeneityValues, oneFormValues, rows, right, row, rowIndex,
   sourceSign, xPower, yPower, monomialValue, monomialLog, value},
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  record = assembly["Record"];
  roots = assembly["Roots"];
  oneForms = assembly["OneForms"];
  support = assembly["OffDiagonalBasisTransformationNumeratorSupport"];
  offDiagonalBasisTransformationDenominator = assembly["OffDiagonalBasisTransformationDenominator"];
  offDiagonalBlockEquation = record["OffDiagonalBlockEquation"];
  {e, c, inhomogeneity} = offDiagonalBlockEquation;
  dimensions = assembly["Dimensions"];
  {upperDimension, lowerDimension} = dimensions;
  rank = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  supportCount = Length[support];
  offDiagonalBasisTransformationUnknownCount = assembly["OffDiagonalBasisTransformationUnknownCount"];
  unknownCount = assembly["UnknownCount"];
  epsilonMod = multiquadraticOffDiagonalBlockModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["InvalidRegulatorImage"],
      "MultiquadraticOffDiagonalBlockSplitFailure"]];
  deltaValues = multiquadraticOffDiagonalBlockModRational[
      #1 /. Thread[variables -> point], prime] & /@
        (squareRootRecordRadicand /@ roots);
  If[MemberQ[deltaValues, $Failed | 0] ||
      ! AllTrue[deltaValues, modularResidueQ[#1, prime] &],
    Throw[multiquadraticOffDiagonalBlockFailure["PointNotSplitOverPrime",
      <|"Point" -> point|>], "MultiquadraticOffDiagonalBlockSplitFailure"]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Throw[multiquadraticOffDiagonalBlockFailure["PointSquareRootFailure"],
      "MultiquadraticOffDiagonalBlockSplitFailure"]];
  denominatorValue = multiquadraticOffDiagonalBlockModRational[
    offDiagonalBasisTransformationDenominator /. Thread[variables -> point] /. epsilon -> epsilonValue,
    prime];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroOffDiagonalBasisTransformationDenominator"],
      "MultiquadraticOffDiagonalBlockSplitFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  denominatorDerivatives = multiquadraticOffDiagonalBlockModRational[
      D[offDiagonalBasisTransformationDenominator, #1] /. Thread[variables -> point] /.
        epsilon -> epsilonValue, prime] & /@ variables;
  If[MemberQ[denominatorDerivatives, $Failed],
    Throw[multiquadraticOffDiagonalBlockFailure["OffDiagonalBasisTransformationDenominatorDerivativeSingular"],
      "MultiquadraticOffDiagonalBlockSplitFailure"]];
  deltaLogDerivatives = Table[
    value = multiquadraticOffDiagonalBlockModRational[
      D[squareRootRecordRadicand[roots[[a]]], variables[[mu]]] /
        squareRootRecordRadicand[roots[[a]]] /.
          Thread[variables -> point], prime];
    If[value === $Failed,
      Throw[multiquadraticOffDiagonalBlockFailure["RootLogDerivativeSingular"],
        "MultiquadraticOffDiagonalBlockSplitFailure"]];
    value,
    {a, rank}, {mu, 2}];
  rootProducts = multiquadraticOffDiagonalBlockMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  branchValue[expression_, signList_] := Module[{branched, image},
    branched = transportChartApplyRootBranches[expression, roots,
      Mod[signList rootValues, prime]];
    image = multiquadraticOffDiagonalBlockModRational[
      branched /. Thread[variables -> point] /. epsilon -> epsilonValue, prime];
    If[image === $Failed,
      Throw[multiquadraticOffDiagonalBlockFailure["BranchValueSingular"],
        "MultiquadraticOffDiagonalBlockSplitFailure"]];
    image];
  branchMatrix[matrix_, signList_] := Map[branchValue[#1, signList] &, matrix, {2}];
  branchPair[pair_, signList_] := branchMatrix[#1, signList] & /@ pair;
  eValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[e, signs], {signMask, 0, gradeCount - 1}];
  cValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[c, signs], {signMask, 0, gradeCount - 1}];
  inhomogeneityValues = Table[signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchPair[inhomogeneity, signs], {signMask, 0, gradeCount - 1}];
  oneFormValues = Table[
    signs = Table[If[BitGet[signMask, a - 1] === 0, 1, -1], {a, rank}];
    branchValue[oneForms[[letter, mu]], signs],
    {signMask, 0, gradeCount - 1}, {letter, Length[oneForms]}, {mu, 2}];
  rows = Table[ConstantArray[0, unknownCount], gradeCount 2 upperDimension lowerDimension];
  right = ConstantArray[0, gradeCount 2 upperDimension lowerDimension];
  Do[
    sourceSign = BitXor[signMask, flipMask];
    rowIndex = multiquadraticOffDiagonalBlockPointRowIndex[signMask, mu, i, j,
      upperDimension, lowerDimension];
    row = ConstantArray[0, unknownCount];
    Do[
      {xPower, yPower} = support[[monomial]];
      monomialValue = Mod[PowerMod[Mod[point[[1]], prime], xPower, prime]
        PowerMod[Mod[point[[2]], prime], yPower, prime], prime];
      basisValue = Mod[multiquadraticOffDiagonalBlockCharacter[sourceSign, grade, rank]
        rootProducts[[grade + 1]] monomialValue denominatorInverse, prime];
      monomialLog = If[mu === 1,
        If[xPower === 0, 0,
          Mod[xPower PowerMod[Mod[point[[1]], prime], -1, prime], prime]],
        If[yPower === 0, 0,
          Mod[yPower PowerMod[Mod[point[[2]], prime], -1, prime], prime]]];
      basisDerivative = Mod[basisValue Mod[monomialLog -
        denominatorDerivatives[[mu]] denominatorInverse +
        PowerMod[2, -1, prime] Sum[If[BitGet[grade, a - 1] === 1,
          deltaLogDerivatives[[a, mu]], 0], {a, rank}], prime], prime];
      row[[multiquadraticOffDiagonalBasisTransformationBlockIndex[upperDimension, lowerDimension,
        gradeCount, supportCount, i, j, grade, monomial]]] +=
        basisDerivative;
      Do[row[[multiquadraticOffDiagonalBasisTransformationBlockIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, a, j, grade, monomial]]] +=
          -epsilonMod eValues[[sourceSign + 1, mu, i, a]] basisValue,
        {a, upperDimension}];
      Do[row[[multiquadraticOffDiagonalBasisTransformationBlockIndex[upperDimension, lowerDimension,
          gradeCount, supportCount, i, b, grade, monomial]]] +=
          epsilonMod cValues[[sourceSign + 1, mu, b, j]] basisValue,
        {b, lowerDimension}],
      {grade, 0, gradeCount - 1}, {monomial, supportCount}];
    Do[row[[multiquadraticOffDiagonalBlockResidueIndex[offDiagonalBasisTransformationUnknownCount, upperDimension,
        lowerDimension, letter, i, j]]] +=
        epsilonMod oneFormValues[[sourceSign + 1, letter, mu]],
      {letter, Length[oneForms]}];
    rows[[rowIndex]] = Mod[row, prime];
    right[[rowIndex]] = Mod[inhomogeneityValues[[sourceSign + 1, mu, i, j]], prime],
    {signMask, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  <|"Status" -> "MultiquadraticSplitPointRowsV1", "Prime" -> prime,
    "Point" -> Mod[point, prime],
    "QuadraticRadicandValues" -> deltaValues,
    "RootValues" -> rootValues, "BranchFlipMask" -> flipMask,
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "UnknownCount" -> unknownCount|>
], "MultiquadraticOffDiagonalBlockSplitFailure"];

multiquadraticOffDiagonalBlockDifferentialCheckPoint[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Module[
  {startTime = AbsoluteTime[], epsilonForms, direct, deltaValues, rootValues,
   transformed, reference, matrixEqual, rightEqual, passed},
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDifferentialAssembly"]]];
  epsilonForms = multiquadraticOffDiagonalBlockCollapseEpsilon[assembly, prime, epsilonValue];
  If[Lookup[epsilonForms, "Status", None] =!=
        "MultiquadraticOffDiagonalBlockEpsilonFormsV1" ||
      ! multiquadraticOffDiagonalBlockEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[multiquadraticOffDiagonalBlockFailure["DifferentialRegulatorCollapseFailed"]]];
  direct = multiquadraticOffDiagonalBlockAssemblePointInternal[assembly, epsilonForms,
    prime, point];
  If[Lookup[direct, "Status", None] =!= "AssembledMultiquadraticPointV1",
    Return[direct]];
  deltaValues = direct["QuadraticRadicandValues"];
  If[! AllTrue[deltaValues, modularResidueQ[#1, prime] &],
    Return[multiquadraticOffDiagonalBlockFailure["DifferentialPointNotSplit",
      <|"QuadraticRadicandValues" -> deltaValues|>]]];
  rootValues = multiquadraticSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure["DifferentialSquareRootFailure"]]];
  transformed = multiquadraticOffDiagonalBlockTransformPointToSigns[direct, rootValues,
    prime, flipMask];
  If[Lookup[transformed, "Status", None] =!=
      "TransformedMultiquadraticPointToSignsV1",
    Return[Join[transformed, <|
      "DirectPointResultHead" -> Head[direct],
      "RootValuesHead" -> Head[rootValues],
      "RootValues" -> rootValues|>]]];
  reference = multiquadraticOffDiagonalBlockSplitPointRows[assembly, epsilonValue, prime,
    point, flipMask];
  If[Lookup[reference, "Status", None] =!= "MultiquadraticSplitPointRowsV1",
    Return[reference]];
  matrixEqual = TrueQ[Normal[transformed["Rows"]] === Normal[reference["Rows"]]];
  rightEqual = TrueQ[Normal[transformed["RightHandSide"]] ===
    Normal[reference["RightHandSide"]]];
  passed = TrueQ[matrixEqual && rightEqual];
  <|"Status" -> If[passed, "MultiquadraticPointDifferentialPassed",
      "MultiquadraticPointDifferentialFailed"],
    "Passed" -> passed, "MatrixEqual" -> matrixEqual,
    "RightHandSideEqual" -> rightEqual, "Prime" -> prime,
    "EpsilonValue" -> epsilonValue, "Point" -> point,
    "RootCount" -> assembly["RootCount"], "BranchFlipMask" -> flipMask,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticOffDiagonalBlockDifferentialCheckPoint[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidDifferentialPointArguments"];

(* ------------------------------------------------------------------ *)
(* Modular solve, unpacking, exact verification                         *)
(* ------------------------------------------------------------------ *)

(* Deterministic RREF: a particular solution with every free column
   zero, plus the nullspace basis, plus the residual check.  The pivot
   columns must not move between primes or regulator values. *)
multiquadraticOffDiagonalBlockAffineSolve[matrix_?MatrixQ, right_List, prime_Integer] :=
  Module[
  {dimensions = Dimensions[matrix], unknownCount, augmented, reduced,
   coefficientPart, pivotRows = {}, pivotColumns = {}, position,
   inconsistentRows, freeColumns, particular, nullspace, residual, nullResidual},
  If[! PrimeQ[prime],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPrime", <|"Prime" -> prime|>]]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[multiquadraticOffDiagonalBlockFailure["AffineDimensionMismatch"]]];
  unknownCount = dimensions[[2]];
  augmented = MapThread[Append, {Mod[Normal[matrix], prime], Mod[right, prime]}];
  reduced = RowReduce[augmented, Modulus -> prime];
  coefficientPart = reduced[[All, 1 ;; unknownCount]];
  Do[
    position = SelectFirst[Range[unknownCount],
      Mod[coefficientPart[[row, #1]], prime] =!= 0 &, Missing["NotFound"]];
    If[! MissingQ[position],
      AppendTo[pivotRows, row]; AppendTo[pivotColumns, position]],
    {row, Length[coefficientPart]}];
  If[! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, IntegerQ[#1] && 1 <= #1 <= unknownCount &] ||
      Length[pivotColumns] > Min[dimensions],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPivotStructure",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "PivotColumns" -> pivotColumns|>]]];
  inconsistentRows = Select[Range[Length[coefficientPart]],
    multiquadraticOffDiagonalBlockZeroQ[Mod[coefficientPart[[#1]], prime]] &&
      Mod[reduced[[#1, -1]], prime] =!= 0 &];
  If[inconsistentRows =!= {},
    (* the rank of the coefficient part and the affine defect belong to
       the typed failure: without them a recorded inconsistency says only
       that the system had no solution, and the driver's failure summary
       cannot tell a missing letter from too small an ansatz
       (2026-08-24) *)
    Return[multiquadraticOffDiagonalBlockFailure["InconsistentModularSystem",
      <|"Prime" -> prime, "MatrixDimensions" -> dimensions,
        "InconsistentRows" -> inconsistentRows,
        "Rank" -> Length[pivotColumns],
        "AugmentedRank" -> Length[pivotColumns] + Length[inconsistentRows],
        "Defect" -> Length[inconsistentRows],
        "Nullity" -> unknownCount - Length[pivotColumns]|>]]];
  freeColumns = Complement[Range[unknownCount], pivotColumns];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] = Mod[reduced[[pivotRows[[k]], -1]], prime],
    {k, Length[pivotColumns]}];
  nullspace = Table[Module[{vector = ConstantArray[0, unknownCount]},
    vector[[free]] = 1;
    Do[vector[[pivotColumns[[k]]]] = Mod[-reduced[[pivotRows[[k]], free]], prime],
      {k, Length[pivotColumns]}];
    vector], {free, freeColumns}];
  residual = AllTrue[Mod[matrix . particular - right, prime], #1 === 0 &];
  nullResidual = AllTrue[nullspace,
    Function[vector, AllTrue[Mod[matrix . vector, prime], #1 === 0 &]]];
  If[! (TrueQ[residual] && TrueQ[nullResidual]),
    Return[multiquadraticOffDiagonalBlockFailure["AffineResidualNonzero",
      <|"Prime" -> prime, "ResidualZero" -> residual,
        "NullspaceResidualZero" -> nullResidual|>]]];
  <|"Status" -> "MultiquadraticAffineSolution", "Prime" -> prime,
    "MatrixDimensions" -> dimensions, "Rank" -> Length[pivotColumns],
    "Nullity" -> Length[freeColumns], "PivotColumns" -> pivotColumns,
    "FreeColumns" -> freeColumns,
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace|>
];
multiquadraticOffDiagonalBlockAffineSolve[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidAffineSolveArguments"];

(* The rectangular first image is the one place where a full affine RREF is
   unavoidable.  CFFR1 is already the authenticated native adapter used by
   FiniteFieldOffDiagonalBlockSolve.wl; this layer only translates its response into the
   multiquadratic affine solve.  Automatic uses the declared matrix-entry
   threshold below.  Its fallback is deliberately narrow: adapter absence or
   execution/authentication failure may use Wolfram, but an adapter exit 5 is
   the mathematical verdict for that image and is never retried by a different
   solver. *)
$multiquadraticOffDiagonalBlockPlanDiscoveryNativeMinimumEntries = 250000;

multiquadraticOffDiagonalBlockPlanDiscoveryBackendDecision[requested_, threads_,
    dimensions : {_Integer, _Integer}, minimumEntries_: Automatic] := Module[
  {threshold = Replace[minimumEntries, Automatic :>
      $multiquadraticOffDiagonalBlockPlanDiscoveryNativeMinimumEntries], entries,
   available, reported},
  reported = If[MemberQ[{Automatic, "Wolfram", "FLINTAffineRREF"}, requested],
    requested, If[StringQ[requested], requested,
      ToString[Head[requested], InputForm]]];
  If[! MemberQ[{Automatic, "Wolfram", "FLINTAffineRREF"}, requested],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPlanDiscoveryBackend",
      <|"PlanDiscoveryBackendRequested" -> reported,
        "AllowedBackends" -> {Automatic, "Wolfram", "FLINTAffineRREF"}|>]]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPlanDiscoveryBackendThreads",
      <|"PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendThreads" -> threads,
        "AllowedRange" -> {1, 8}|>]]];
  If[! IntegerQ[threshold] || threshold < 0 || Min[dimensions] < 0,
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPlanDiscoveryBackendThreshold",
      <|"PlanDiscoveryBackendMinimumEntries" -> threshold,
        "MatrixDimensions" -> dimensions|>]]];
  entries = Times @@ dimensions;
  available = StringQ[finiteFieldOffDiagonalBlockCFFRBinary[]] &&
    FileExistsQ[finiteFieldOffDiagonalBlockCFFRBinary[]];
  Which[
    requested === "Wolfram",
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendUsed" -> "Wolfram",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> False,
        "PlanDiscoveryBackendSelectionReason" -> "ExplicitWolfram",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    requested === "FLINTAffineRREF" && ! available,
      multiquadraticOffDiagonalBlockFailure["PlanDiscoveryBackendUnavailable",
        <|"PlanDiscoveryBackendRequested" -> requested,
          "PlanDiscoveryBackendUsed" -> None,
          "PlanDiscoveryBackendThreads" -> threads,
          "AvailableBackends" -> {"Wolfram"},
          "MatrixEntries" -> entries,
          "NativeMinimumMatrixEntries" -> threshold|>],
    requested === "FLINTAffineRREF",
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> requested,
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> False,
        "PlanDiscoveryBackendSelectionReason" -> "ExplicitNative",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    available && entries >= threshold,
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> Automatic,
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> True,
        "PlanDiscoveryBackendSelectionReason" -> "AutomaticSizeThreshold",
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>,
    True,
      <|"Status" -> "OK", "PlanDiscoveryBackendRequested" -> Automatic,
        "PlanDiscoveryBackendUsed" -> "Wolfram",
        "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendFallbackAllowed" -> True,
        "PlanDiscoveryBackendSelectionReason" -> If[available,
          "AutomaticBelowSizeThreshold", "AutomaticAdapterUnavailable"],
        "MatrixEntries" -> entries,
        "NativeMinimumMatrixEntries" -> threshold|>]
];
multiquadraticOffDiagonalBlockPlanDiscoveryBackendDecision[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidPlanDiscoveryBackendDecisionArguments"];

multiquadraticOffDiagonalBlockNativeAffineSolve[matrix_?MatrixQ, right_List,
    prime_Integer, offDiagonalBasisTransformationUnknownCount_Integer, residueUnknownCount_Integer,
    threads_Integer] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[matrix], preference,
   runSeconds, run, response, verificationSeconds, verification, solution},
  If[! PrimeQ[prime] || Length[dimensions] =!= 2 ||
      dimensions[[1]] =!= Length[right] ||
      dimensions[[2]] =!= offDiagonalBasisTransformationUnknownCount + residueUnknownCount ||
      ! Between[threads, {1, 8}],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidNativeAffineInput"]]];
  preference = Join[Reverse[Range[offDiagonalBasisTransformationUnknownCount]],
    offDiagonalBasisTransformationUnknownCount + Range[residueUnknownCount]];
  {runSeconds, run} = AbsoluteTiming[finiteFieldOffDiagonalBlockCFFRRun[matrix, right,
    prime, preference, threads, Automatic]];
  If[Lookup[run, "Status", None] =!= "OK",
    Return[Join[run, <|"PlanDiscoveryBackendRequested" ->
        "FLINTAffineRREF", "PlanDiscoveryBackendUsed" ->
        "FLINTAffineRREF", "PlanDiscoveryBackendThreads" -> threads,
        "PlanDiscoveryBackendSeconds" -> runSeconds,
        "MatrixDimensions" -> dimensions|>]]];
  response = run["Response"];
  {verificationSeconds, verification} = AbsoluteTiming[
    finiteFieldOffDiagonalBlockCFFRVerify[matrix, right, prime, response, Automatic]];
  If[Lookup[verification, "Status", None] =!= "OK",
    Return[multiquadraticOffDiagonalBlockFailure["PlanDiscoveryBackendVerificationFailed",
      <|"PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "BackendFailure" -> verification,
        "PhaseSeconds" -> <|"Adapter" -> runSeconds,
          "FullOriginalRowReplay" -> verificationSeconds|>|>]]];
  solution = <|"Status" -> "MultiquadraticAffineSolution",
    "Prime" -> prime, "MatrixDimensions" -> dimensions,
    "Rank" -> response["Rank"], "Nullity" -> response["Nullity"],
    "PivotColumns" -> response["PivotColumns"],
    "FreeColumns" -> response["FreeColumns"],
    "ParticularSolution" -> response["ParticularSolution"],
    "NullspaceBasis" -> response["NullspaceBasis"],
    "IndependentEquationRows" -> response["IndependentEquationRows"],
    "NativeNormalizationColumns" -> response["NormalizationColumns"],
    "FullResidualZero" -> True, "NullspaceResidualZero" -> True,
    "PlanDiscoveryBackendRequested" -> "FLINTAffineRREF",
    "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
    "PlanDiscoveryBackendThreads" -> run["Threads"],
    "PhaseSeconds" -> <|"Adapter" -> runSeconds,
      "FullOriginalRowReplay" -> verificationSeconds|>,
    "PlanDiscoveryBackendSeconds" -> N[AbsoluteTime[] - startTime]|>;
  solution
];
multiquadraticOffDiagonalBlockNativeAffineSolve[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidNativeAffineArguments"];

multiquadraticOffDiagonalBlockPlanDiscoverySolve[matrix_?MatrixQ, right_List,
    prime_Integer, offDiagonalBasisTransformationUnknownCount_Integer, residueUnknownCount_Integer,
    requested_, threads_Integer, minimumEntries_: Automatic] := Module[
  {startTime = AbsoluteTime[], decision, native, wolframSeconds, wolfram,
   fallbackReason = None},
  decision = multiquadraticOffDiagonalBlockPlanDiscoveryBackendDecision[requested,
    threads, Dimensions[matrix], minimumEntries];
  If[Lookup[decision, "Status", None] =!= "OK", Return[decision]];
  If[decision["PlanDiscoveryBackendUsed"] === "FLINTAffineRREF",
    native = multiquadraticOffDiagonalBlockNativeAffineSolve[matrix, right, prime,
      offDiagonalBasisTransformationUnknownCount, residueUnknownCount, threads];
    If[Lookup[native, "Status", None] === "MultiquadraticAffineSolution",
      Return[Join[native, KeyTake[decision, {
        "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
        "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
        "MatrixEntries", "NativeMinimumMatrixEntries"}]]]];
    (* Exit 5 is an exact verdict about this affine image.  It is not an
       adapter failure and therefore has no Automatic fallback. *)
    If[Lookup[native, "Status", None] === "InconsistentModularSystem",
      Return[Join[native, KeyTake[decision, {
        "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
        "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
        "MatrixEntries", "NativeMinimumMatrixEntries"}]]]];
    If[! TrueQ[decision["PlanDiscoveryBackendFallbackAllowed"]],
      Return[multiquadraticOffDiagonalBlockFailure["PlanDiscoveryBackendFailed",
        Join[KeyTake[decision, {"PlanDiscoveryBackendRequested",
          "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads",
          "PlanDiscoveryBackendSelectionReason", "MatrixEntries",
          "NativeMinimumMatrixEntries"}], <|"BackendFailure" -> native|>]]]];
    fallbackReason = Lookup[native, "Status", "NativeExecutionFailed"]];
  If[fallbackReason === None &&
      decision["PlanDiscoveryBackendSelectionReason"] ===
        "AutomaticAdapterUnavailable",
    fallbackReason = "CFFRAdapterUnavailable"];
  {wolframSeconds, wolfram} = AbsoluteTiming[
    multiquadraticOffDiagonalBlockAffineSolve[matrix, right, prime]];
  If[! AssociationQ[wolfram], Return[wolfram]];
  Join[wolfram, <|"PlanDiscoveryBackendRequested" -> requested,
    "PlanDiscoveryBackendUsed" -> "Wolfram",
    "PlanDiscoveryBackendThreads" -> threads,
    "PlanDiscoveryBackendSelectionReason" ->
      decision["PlanDiscoveryBackendSelectionReason"],
    "PlanDiscoveryBackendFallbackReason" -> fallbackReason,
    "MatrixEntries" -> decision["MatrixEntries"],
    "NativeMinimumMatrixEntries" -> decision["NativeMinimumMatrixEntries"],
    "PlanDiscoveryBackendSeconds" -> wolframSeconds,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>]
];
multiquadraticOffDiagonalBlockPlanDiscoverySolve[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidPlanDiscoverySolveArguments"];

(* A support rung needs only consistency evidence, not a selected affine
   representative.  A successful native response supplies both ranks.  On
   exit 5 CFFR1 has already established affine inconsistency; because there is
   exactly one RHS column, rank([A|b])-rank(A) is then exactly one.  Absolute
   ranks are deliberately left Missing instead of paying a second homogeneous
   RREF solely for telemetry.  The inconsistent verdict is never sent to
   Wolfram. *)
multiquadraticOffDiagonalBlockAffineConsistencyEvidence[matrix_?MatrixQ, right_List,
    prime_Integer, offDiagonalBasisTransformationUnknownCount_Integer, residueUnknownCount_Integer,
    requested_, threads_Integer, minimumEntries_: Automatic] := Module[
  {startTime = AbsoluteTime[], solution},
  solution = multiquadraticOffDiagonalBlockPlanDiscoverySolve[matrix, right, prime,
    offDiagonalBasisTransformationUnknownCount, residueUnknownCount, requested, threads,
    minimumEntries];
  Which[
    Lookup[solution, "Status", None] === "MultiquadraticAffineSolution",
      <|"Status" -> "ProviderSupportImageConsistent", "Prime" -> prime,
        "Rank" -> solution["Rank"], "AugmentedRank" -> solution["Rank"],
        "Defect" -> 0, "MatrixDimensions" -> Dimensions[matrix],
        "Solution" -> solution,
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> solution["PlanDiscoveryBackendUsed"],
        "PlanDiscoveryBackendThreads" ->
          solution["PlanDiscoveryBackendThreads"],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    Lookup[solution, "Status", None] === "InconsistentModularSystem" &&
        Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
          "FLINTAffineRREF",
      <|"Status" -> "ProviderSupportImageInconsistent", "Prime" -> prime,
        "Rank" -> Missing["NotComputedForInconsistentImage"],
        "AugmentedRank" -> Missing["NotComputedForInconsistentImage"],
        "Defect" -> 1, "MatrixDimensions" -> Dimensions[matrix],
        "DefectEvidence" -> "SingleRightHandSideAffineInconsistency",
        "InconsistentVerdict" -> KeyDrop[solution,
          {"RequestFile", "ResponseFile"}],
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> "FLINTAffineRREF",
        "PlanDiscoveryBackendThreads" -> threads,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    Lookup[solution, "Status", None] === "InconsistentModularSystem",
      <|"Status" -> "ProviderSupportImageInconsistent", "Prime" -> prime,
        "Rank" -> solution["Rank"],
        "AugmentedRank" -> solution["AugmentedRank"],
        "Defect" -> solution["AugmentedRank"] - solution["Rank"],
        "MatrixDimensions" -> Dimensions[matrix],
        "PlanDiscoveryBackendRequested" ->
          solution["PlanDiscoveryBackendRequested"],
        "PlanDiscoveryBackendUsed" -> solution["PlanDiscoveryBackendUsed"],
        "PlanDiscoveryBackendThreads" ->
          solution["PlanDiscoveryBackendThreads"],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>,
    True, solution]
];
multiquadraticOffDiagonalBlockAffineConsistencyEvidence[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidAffineConsistencyEvidenceArguments"];

(* A pilot image pays for one full RREF.  It fixes three pieces of the
   affine section which must not drift with the regulator or the prime: an
   independent set of equation rows, the pivot columns, and the columns
   which define the canonical affine section.  Later images solve the one
   square constrained core with nullity+1 right-hand sides.  The additional
   right-hand sides reconstruct a basis of the kernel in the SAME section;
   checking them against every original row certifies that the generic rank
   has neither risen nor fallen without doing another RREF. *)
multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan_Association] := Module[
  {unknownCount, equationCount, rank, nullity, rows, columns, pivotColumns,
   freeColumns, coefficientData},
  If[Lookup[plan, "Status", None] =!=
      "MultiquadraticConstrainedAffinePlanV1", Return[False]];
  unknownCount = Lookup[plan, "UnknownCount", $Failed];
  equationCount = Lookup[plan, "EquationCount", $Failed];
  rank = Lookup[plan, "Rank", $Failed];
  nullity = Lookup[plan, "Nullity", $Failed];
  rows = Lookup[plan, "IndependentEquationRows", $Failed];
  columns = Lookup[plan, "NormalizationColumns", $Failed];
  pivotColumns = Lookup[plan, "PivotColumns", $Failed];
  freeColumns = Lookup[plan, "FreeColumns", $Failed];
  coefficientData = Lookup[plan, "CoefficientData", $Failed];
  If[! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! IntegerQ[equationCount] || equationCount < 1 ||
      ! IntegerQ[rank] || rank < 0 || rank > Min[unknownCount, equationCount] ||
      ! IntegerQ[nullity] || nullity =!= unknownCount - rank ||
      ! VectorQ[rows, IntegerQ] || Length[rows] =!= rank ||
      ! DuplicateFreeQ[rows] || ! AllTrue[rows, 1 <= #1 <= equationCount &] ||
      ! VectorQ[columns, IntegerQ] || Length[columns] =!= nullity ||
      ! DuplicateFreeQ[columns] ||
      ! AllTrue[columns, 1 <= #1 <= unknownCount &] ||
      ! VectorQ[pivotColumns, IntegerQ] || Length[pivotColumns] =!= rank ||
      ! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, 1 <= #1 <= unknownCount &] ||
      ! VectorQ[freeColumns, IntegerQ] || Length[freeColumns] =!= nullity ||
      Sort[Join[pivotColumns, freeColumns]] =!= Range[unknownCount] ||
      ! AssociationQ[coefficientData], Return[False]];
  True
];
multiquadraticOffDiagonalBlockConstrainedPlanValidQ[___] := False;

(* Native follower solves inherit the adapter's exact constrained-core
   verification.  They do not repeat an all-original-row matrix product;
   the reconstructed block is accepted later at fresh modular points.
   The Wolfram fallback still certifies all rows itself. *)
multiquadraticOffDiagonalBlockFullResidualEvidenceValidQ[evidence_Association,
    prime_Integer] := Module[{method, nullity},
  method = Lookup[evidence, "FullResidualCheckMethod", None];
  nullity = Lookup[evidence, "Nullity", $Failed];
  If[! PrimeQ[prime] || ! IntegerQ[nullity] || nullity < 0,
    Return[False]];
  If[method === "NativeCoreVerifiedFreivaldsAllRows",
    Return[Lookup[evidence, "ConstrainedSolveBackendUsed", None] ===
        "FLINT" &&
      TrueQ[Lookup[evidence, "NativeCoreResidualZero", False]] &&
      TrueQ[Lookup[evidence, "NativeCoreResidualExact", False]] &&
      TrueQ[Lookup[evidence, "FullResidualZero", False]] &&
      IntegerQ[Lookup[evidence, "FreivaldsProjections", None]] &&
      Lookup[evidence, "FreivaldsProjections", 0] >= 2]];
  (* records written before 2026-09-02 carry the core-only method *)
  If[method === "NativeConstrainedCoreVerified",
    Return[Lookup[evidence, "ConstrainedSolveBackendUsed", None] ===
        "FLINT" &&
      TrueQ[Lookup[evidence, "NativeCoreResidualZero", False]] &&
      TrueQ[Lookup[evidence, "NativeCoreResidualExact", False]]]];
  MemberQ[{"ExactMatrixMatrix", "ExactFullAffineRREF"}, method] &&
    TrueQ[Lookup[evidence, "FullResidualZero", False]] &&
    TrueQ[Lookup[evidence, "NullspaceResidualZero", False]] &&
    TrueQ[Lookup[evidence, "FullResidualExact", False]]
];
multiquadraticOffDiagonalBlockFullResidualEvidenceValidQ[___] := False;

multiquadraticOffDiagonalBlockConstrainedAffineSolve[matrix_?MatrixQ, right_List,
    prime_Integer, plan_Association] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[matrix], unknownCount,
   equationCount, rank, nullity, rows, columns, selector, core, rhsMatrix,
   solveSeconds = 0., residualSeconds = 0.,
   nativeSolveSeconds = 0., wolframSolveSeconds = 0.,
   particular, nullspace, normalizationOK, backendThreads,
   backendDecision, backendUsed = "Wolfram", backendFallbackReason = None,
   nativeAttempted = False, nativeValidationFailure = None,
   nativeValidationRecovered = False, fullResidualReplayCount = 0,
   residualCheckEvidence = {},
   nativeSolution = $Failed, wolframSolution = $Failed, validation = <||>,
   solutionShapeQ, nativeSolutionShapeQ, validateSolution,
   validationFailureReason, needWolfram = True},
  If[! PrimeQ[prime] || ! multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidConstrainedAffinePlan"]]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right] ||
      ! MatrixQ[matrix, IntegerQ] || ! VectorQ[right, IntegerQ],
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedAffineDimensionMismatch"]]];
  {equationCount, unknownCount} = dimensions;
  If[{equationCount, unknownCount} =!=
      Lookup[plan, {"EquationCount", "UnknownCount"}, {$Failed, $Failed}],
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedPlanDimensionMismatch",
      <|"Expected" -> Lookup[plan, {"EquationCount", "UnknownCount"}],
        "Observed" -> dimensions|>]]];
  rank = plan["Rank"]; nullity = plan["Nullity"];
  rows = plan["IndependentEquationRows"];
  columns = plan["NormalizationColumns"];
  selector = SparseArray[MapIndexed[{First[#2], #1} -> 1 &, columns],
    {nullity, unknownCount}];
  core = Which[
    nullity === 0, matrix[[rows]],
    rank === 0, selector,
    True, Join[matrix[[rows]], selector]];
  rhsMatrix = Which[
    nullity === 0, List /@ right[[rows]],
    rank === 0,
      Join[ConstantArray[0, {nullity, 1}], IdentityMatrix[nullity], 2],
    True,
      Join[
        Join[List /@ right[[rows]], ConstantArray[0, {rank, nullity}], 2],
        Join[ConstantArray[0, {nullity, 1}], IdentityMatrix[nullity], 2]]];
  If[Dimensions[core] =!= {unknownCount, unknownCount} ||
      Dimensions[rhsMatrix] =!= {unknownCount, nullity + 1},
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedCoreDimensionMismatch",
      <|"CoreDimensions" -> Dimensions[core],
        "RightHandSideDimensions" -> Dimensions[rhsMatrix]|>]]];
  solutionShapeQ[candidate_] := MatrixQ[candidate, IntegerQ] &&
    Dimensions[candidate] === {unknownCount, nullity + 1};
  nativeSolutionShapeQ[candidate_] := solutionShapeQ[candidate] &&
    AllTrue[Flatten[candidate], 0 <= #1 < prime &];
  validateSolution[candidate_, nativeCoreVerified_: False] := Module[
    {candidateMatrix = Mod[candidate, prime], candidateParticular,
     candidateNullspace, candidateNormalizationOK, targetMatrix,
     residual, residualZero, replaySeconds, certificateSummary},
    candidateParticular = candidateMatrix[[All, 1]];
    candidateNullspace = If[nullity === 0, {},
      Transpose[candidateMatrix[[All, 2 ;;]]]];
    candidateNormalizationOK =
      candidateParticular[[columns]] === ConstantArray[0, nullity] &&
      (nullity === 0 ||
        candidateNullspace[[All, columns]] === IdentityMatrix[nullity]);
    If[! TrueQ[candidateNormalizationOK],
      Return[<|"Status" -> "NormalizationMismatch",
        "SolutionMatrix" -> candidateMatrix,
        "ParticularSolution" -> candidateParticular,
        "NullspaceBasis" -> candidateNullspace,
        "NormalizationOK" -> False|>]];
    If[TrueQ[nativeCoreVerified],
      (* U2 (user decision 2026-09-02): a native solve is verified on the
         constrained core only by the adapter; the ORIGINAL rows are now
         replayed as well, by Freivalds projection -- two random row
         combinations r.M.X == r.B mod p -- at O(m n) per projection
         instead of the O(m n (nullity+1)) exact product, with a false
         acceptance probability of at most p^-2 per image (p >= 2^30). *)
      targetMatrix = Join[List /@ Mod[right, prime],
        ConstantArray[0, {equationCount, nullity}], 2];
      {replaySeconds, residualZero} = AbsoluteTiming[Module[{ok = True},
        Do[Module[{r = RandomInteger[{1, prime - 1}, equationCount], lhs, rhs},
          lhs = Mod[Mod[r . matrix, prime] . candidateMatrix, prime];
          rhs = Mod[r . targetMatrix, prime];
          If[lhs =!= rhs, ok = False]], {$multiquadraticOffDiagonalBlockFreivaldsProjections}];
        ok]];
      residualSeconds += replaySeconds;
      fullResidualReplayCount++;
      certificateSummary = <|
        "Status" -> If[residualZero, "Accepted", "FullResidualNonzero"],
        "FullResidualZero" -> residualZero,
        "NullspaceResidualZero" -> residualZero,
        "FullResidualCheckMethod" -> "NativeCoreVerifiedFreivaldsAllRows",
        "FullResidualExact" -> False,
        "FreivaldsProjections" -> $multiquadraticOffDiagonalBlockFreivaldsProjections,
        "NativeCoreResidualZero" -> True,
        "NativeCoreResidualExact" -> True, "Seconds" -> replaySeconds|>;
      AppendTo[residualCheckEvidence, certificateSummary];
      Return[Join[certificateSummary, <|
        "SolutionMatrix" -> candidateMatrix,
        "ParticularSolution" -> candidateParticular,
        "NullspaceBasis" -> candidateNullspace,
        "NormalizationOK" -> True|>]]];
    targetMatrix = Join[List /@ Mod[right, prime],
      ConstantArray[0, {equationCount, nullity}], 2];
    {replaySeconds, residual} = AbsoluteTiming[
      Mod[matrix . candidateMatrix - targetMatrix, prime]];
    residualSeconds += replaySeconds;
    fullResidualReplayCount++;
    residualZero = MatrixQ[residual, #1 === 0 &];
    certificateSummary = <|
      "Status" -> If[residualZero, "Accepted", "FullResidualNonzero"],
      "FullResidualZero" -> residualZero,
      "NullspaceResidualZero" -> residualZero,
      "FullResidualCheckMethod" -> "ExactMatrixMatrix",
      "FullResidualExact" -> True,
      "NonzeroResidualCount" -> If[residualZero, 0,
        Count[Flatten[residual], Except[0]]],
      "Seconds" -> replaySeconds|>;
    AppendTo[residualCheckEvidence, certificateSummary];
    Join[certificateSummary, <|
      "SolutionMatrix" -> candidateMatrix,
      "ParticularSolution" -> candidateParticular,
      "NullspaceBasis" -> candidateNullspace,
      "NormalizationOK" -> True|>]
  ];
  validationFailureReason["NormalizationMismatch"] :=
    "FLINTNormalizationValidationFailed";
  validationFailureReason["FullResidualNonzero"] :=
    "FLINTFullResidualValidationFailed";
  validationFailureReason[_] := "FLINTResponseStructureInvalid";
  (* The same authenticated fixed-core adapter already used by the rational
     finite-field solver is substantially faster for the very wide
     nullity+1 systems occurring in direct multiquadratic reconstruction.
     Its protocol admits at most eight native threads.  Automatic
     remains fail-open only to the historical Wolfram solve; every imported
     solution is provisional until the canonical normalization and all-row
     residual checks below. *)
  backendThreads = Lookup[plan, "PlanDiscoveryBackendThreads", 2];
  If[! IntegerQ[backendThreads], backendThreads = 2];
  backendThreads = Clip[backendThreads, {1, 8}];
  backendDecision = finiteFieldOffDiagonalBlockBackendDecision[Automatic,
    backendThreads, unknownCount];
  If[Lookup[backendDecision, "Status", None] === "OK" &&
      Lookup[backendDecision, "UseBackend", None] === "FLINT",
    nativeAttempted = True;
    {nativeSolveSeconds, nativeSolution} = AbsoluteTiming[
      finiteFieldOffDiagonalBlockFLINTSolve[core, rhsMatrix, prime, backendThreads]];
    solveSeconds += nativeSolveSeconds;
    If[nativeSolutionShapeQ[nativeSolution],
      validation = validateSolution[nativeSolution, True];
      If[Lookup[validation, "Status", None] === "Accepted",
        backendUsed = "FLINT";
        needWolfram = False,
        nativeValidationFailure = validationFailureReason[
          Lookup[validation, "Status", None]];
        backendFallbackReason = nativeValidationFailure],
      backendFallbackReason = If[nativeSolution === $Failed,
        "FLINTExecutionFailed", "FLINTResponseStructureInvalid"];
      If[nativeSolution =!= $Failed,
        nativeValidationFailure = backendFallbackReason]],
    If[Lookup[backendDecision, "Status", None] =!= "OK",
      backendFallbackReason = Lookup[backendDecision, "Status",
        "BackendDecisionFailed"],
      If[unknownCount >= 256 &&
          Lookup[backendDecision, "UseBackend", None] === "Wolfram",
        backendFallbackReason = "FLINTAdapterUnavailable"]]];
  If[needWolfram,
    {wolframSolveSeconds, wolframSolution} = AbsoluteTiming[
      Quiet[Check[LinearSolve[core, rhsMatrix, Modulus -> prime], $Failed]]];
    solveSeconds += wolframSolveSeconds;
    backendUsed = "Wolfram";
    If[solutionShapeQ[wolframSolution],
      validation = validateSolution[wolframSolution];
      If[Lookup[validation, "Status", None] === "Accepted" &&
          nativeValidationFailure =!= None,
        nativeValidationRecovered = True],
      validation = <|"Status" -> "StructureInvalid"|>]];
  If[Lookup[validation, "Status", None] === "StructureInvalid",
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedCoreSingular",
      <|"Prime" -> prime, "CoreDimensions" -> Dimensions[core],
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" -> backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  particular = validation["ParticularSolution"];
  nullspace = validation["NullspaceBasis"];
  normalizationOK = validation["NormalizationOK"];
  If[! TrueQ[normalizationOK],
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanNormalizationMismatch",
      <|"Prime" -> prime, "NormalizationColumns" -> columns,
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" ->
          backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  If[Lookup[validation, "Status", None] === "FullResidualNonzero",
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedFullResidualNonzero",
      <|"Prime" -> prime,
        "NonzeroResidualCount" -> Lookup[validation,
          "NonzeroResidualCount", Missing["NotRecorded"]],
        "ConstrainedSolveBackendUsed" -> backendUsed,
        "ConstrainedSolveBackendThreads" -> backendThreads,
        "ConstrainedSolveBackendFallbackReason" ->
          backendFallbackReason,
        "ConstrainedSolveNativeAttempted" -> nativeAttempted,
        "ConstrainedSolveNativeValidationFailure" ->
          nativeValidationFailure,
        "ConstrainedSolveNativeValidationRecovered" -> False,
        "ConstrainedSolveFullResidualReplayCount" ->
          fullResidualReplayCount,
        "FullResidualChecks" -> residualCheckEvidence,
        "ConstrainedSolveNativeCoreReplayCount" -> 0,
        "CoreSolveSeconds" -> solveSeconds,
        "FullResidualSeconds" -> residualSeconds|>]]];
  <|"Status" -> "MultiquadraticConstrainedAffineSolution",
    "Prime" -> prime, "Rank" -> rank, "Nullity" -> nullity,
    "PivotColumns" -> plan["PivotColumns"],
    "FreeColumns" -> plan["FreeColumns"],
    "NormalizationColumns" -> columns,
    "ParticularSolution" -> particular, "NullspaceBasis" -> nullspace,
    "CanonicalValues" -> particular,
    "SolvePath" -> "ConstrainedCoreMultiRHS",
    "ConstrainedSolveBackendRequested" -> Automatic,
    "ConstrainedSolveBackendUsed" -> backendUsed,
    "ConstrainedSolveBackendThreads" -> backendThreads,
    "ConstrainedSolveBackendFallbackReason" -> backendFallbackReason,
    "ConstrainedSolveNativeAttempted" -> nativeAttempted,
    "ConstrainedSolveNativeValidationFailure" ->
      nativeValidationFailure,
    "ConstrainedSolveNativeValidationRecovered" ->
      nativeValidationRecovered,
    "ConstrainedSolveFullResidualReplayCount" -> fullResidualReplayCount,
    "ConstrainedSolveNativeCoreReplayCount" -> 0,
    "FullResidualZero" -> Lookup[validation, "FullResidualZero",
      Missing["NotChecked"]],
    "NullspaceResidualZero" -> Lookup[validation,
      "NullspaceResidualZero", Missing["NotChecked"]],
    "NativeCoreResidualZero" -> Lookup[validation,
      "NativeCoreResidualZero", Missing["NotApplicable"]],
    "NativeCoreResidualExact" -> Lookup[validation,
      "NativeCoreResidualExact", Missing["NotApplicable"]],
    "FullResidualCheckMethod" -> validation["FullResidualCheckMethod"],
    "FullResidualExact" -> validation["FullResidualExact"],
    "FreivaldsProjections" -> Lookup[validation, "FreivaldsProjections",
      Missing["NotApplicable"]],
    "FullResidualChecks" -> residualCheckEvidence,
    "PhaseSeconds" -> <|"CoreSolve" -> solveSeconds,
      "NativeCoreSolve" -> nativeSolveSeconds,
      "WolframCoreSolve" -> wolframSolveSeconds,
      "FullResidual" -> residualSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticOffDiagonalBlockConstrainedAffineSolve[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidConstrainedAffineArguments"];

multiquadraticOffDiagonalBlockConstrainedPlanDiscover[matrix_?MatrixQ, right_List,
    solution_Association, normalizationColumns_List, prime_Integer,
    coefficientData_Association,
    suppliedIndependentRows_: Automatic] := Module[
  {dimensions = Dimensions[matrix], rank, nullity, independentRows,
   plan, canonical, replay},
  If[Lookup[solution, "Status", None] =!= "MultiquadraticAffineSolution" ||
      ! PrimeQ[prime] || Length[dimensions] =!= 2 ||
      dimensions[[1]] =!= Length[right],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidConstrainedPlanPilot"]]];
  rank = solution["Rank"]; nullity = solution["Nullity"];
  If[Length[normalizationColumns] =!= nullity ||
      ! VectorQ[normalizationColumns, IntegerQ] ||
      ! DuplicateFreeQ[normalizationColumns] ||
      ! AllTrue[normalizationColumns, 1 <= #1 <= dimensions[[2]] &],
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanNormalizationInvalid",
      <|"Nullity" -> nullity,
        "NormalizationColumns" -> normalizationColumns|>]]];
  canonical = Quiet[NormalizeEpsFormAffineSample[
    <|"ParticularSolution" -> solution["ParticularSolution"],
      "NullspaceBasis" -> solution["NullspaceBasis"]|>,
    normalizationColumns, prime]];
  If[canonical === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanNormalizationSingular"]]];
  independentRows = Replace[suppliedIndependentRows, Automatic :>
    finiteFieldOffDiagonalBlockIndependentRows[Normal[matrix], rank, prime]];
  If[independentRows === $Failed || Length[independentRows] =!= rank,
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanIndependentRowsFailed"]]];
  If[! VectorQ[independentRows, IntegerQ] ||
      ! DuplicateFreeQ[independentRows] ||
      ! AllTrue[independentRows, 1 <= #1 <= dimensions[[1]] &] ||
      (suppliedIndependentRows === Automatic && rank > 0 &&
        MatrixRank[matrix[[independentRows]], Modulus -> prime] =!= rank),
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanIndependentRowsInvalid"]]];
  plan = <|"Status" -> "MultiquadraticConstrainedAffinePlanV1",
    "UnknownCount" -> dimensions[[2]], "EquationCount" -> dimensions[[1]],
    "Rank" -> rank, "Nullity" -> nullity,
    "IndependentEquationRows" -> independentRows,
    "NormalizationColumns" -> normalizationColumns,
    "PivotColumns" -> solution["PivotColumns"],
    "FreeColumns" -> solution["FreeColumns"],
    "CoefficientData" -> coefficientData|>;
  plan = Join[plan, KeyTake[solution, {
    "PlanDiscoveryBackendRequested", "PlanDiscoveryBackendUsed",
    "PlanDiscoveryBackendThreads", "PlanDiscoveryBackendSelectionReason",
    "PlanDiscoveryBackendFallbackReason", "PlanDiscoveryBackendSeconds"}]];
  If[! multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan],
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanInvalid"]]];
  If[Lookup[solution, "PlanDiscoveryBackendUsed", None] ===
      "FLINTAffineRREF",
    (* finiteFieldOffDiagonalBlockCFFRVerify already replayed the imported particular
       and every imported nullspace vector on every original row.  Re-solving
       the pilot's square core here would pay a second O(n^3) elimination and
       add no independent check. *)
    Return[Join[plan, <|"PilotPrime" -> prime,
      "PilotReplaySeconds" -> Lookup[solution,
        "PlanDiscoveryBackendSeconds", Missing["NotMeasured"]],
      "PilotReplayMethod" -> "CFFRFullOriginalRowResiduals",
      "PilotParticularResidualZero" -> True,
      "PilotNullspaceResidualZero" -> True|>]]];
  replay = multiquadraticOffDiagonalBlockConstrainedAffineSolve[matrix, right, prime,
    plan];
  If[Lookup[replay, "Status", None] =!=
        "MultiquadraticConstrainedAffineSolution" ||
      replay["CanonicalValues"] =!= canonical["ParticularSolution"],
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedPlanPilotReplayFailed",
      <|"Detail" -> KeyDrop[replay, {"ParticularSolution",
          "NullspaceBasis", "CanonicalValues"}]|>]]];
  Join[plan, <|"PilotPrime" -> prime,
    "PilotReplaySeconds" -> replay["Seconds"]|>]
];
multiquadraticOffDiagonalBlockConstrainedPlanDiscover[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidConstrainedPlanArguments"];

(* A valid plan which is singular at an exceptional image is not discarded
   and is never replaced by a different section.  The full solver may rescue
   that image only when it reproduces the pilot rank/pivots and the locked
   normalization columns remain nonsingular. *)
multiquadraticOffDiagonalBlockConstrainedAffineFallback[matrix_?MatrixQ, right_List,
    prime_Integer, plan_Association] := Module[
  {startTime = AbsoluteTime[], planned, full, fullSeconds, canonical},
  If[! multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidConstrainedAffinePlan"]]];
  planned = multiquadraticOffDiagonalBlockConstrainedAffineSolve[matrix, right, prime,
    plan];
  If[Lookup[planned, "Status", None] ===
      "MultiquadraticConstrainedAffineSolution", Return[planned]];
  {fullSeconds, full} = AbsoluteTiming[
    multiquadraticOffDiagonalBlockAffineSolve[matrix, right, prime]];
  If[Lookup[full, "Status", None] =!= "MultiquadraticAffineSolution",
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedPlanFallbackFailed",
      <|"PlanFailure" -> planned, "FullSolveFailure" -> full,
        "FullSolveSeconds" -> fullSeconds|>]]];
  If[{full["Rank"], full["Nullity"], full["PivotColumns"]} =!=
      {plan["Rank"], plan["Nullity"], plan["PivotColumns"]},
    Return[multiquadraticOffDiagonalBlockFailure["ConstrainedPlanStructureMismatch",
      <|"Expected" -> {plan["Rank"], plan["Nullity"],
          plan["PivotColumns"]},
        "Observed" -> {full["Rank"], full["Nullity"],
          full["PivotColumns"]}, "PlanFailure" -> planned|>]]];
  canonical = Quiet[NormalizeEpsFormAffineSample[
    <|"ParticularSolution" -> full["ParticularSolution"],
      "NullspaceBasis" -> full["NullspaceBasis"]|>,
    plan["NormalizationColumns"], prime]];
  If[canonical === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure[
      "ConstrainedPlanSectionSingular",
      <|"NormalizationColumns" -> plan["NormalizationColumns"],
        "PlanFailure" -> planned|>]]];
  <|"Status" -> "MultiquadraticConstrainedAffineFallbackSolution",
    "Prime" -> prime, "Rank" -> full["Rank"],
    "Nullity" -> full["Nullity"],
    "PivotColumns" -> full["PivotColumns"],
    "FreeColumns" -> full["FreeColumns"],
    "NormalizationColumns" -> plan["NormalizationColumns"],
    "ParticularSolution" -> full["ParticularSolution"],
    "NullspaceBasis" -> full["NullspaceBasis"],
    "CanonicalValues" -> canonical["ParticularSolution"],
    "SolvePath" -> "FullAffineSameSectionFallback",
    "FallbackReason" -> Lookup[planned, "Status", None],
    "FullResidualZero" -> True, "NullspaceResidualZero" -> True,
    "FullResidualCheckMethod" -> "ExactFullAffineRREF",
    "FullResidualExact" -> True,
    "FullResidualChecks" -> Lookup[planned, "FullResidualChecks", {}],
    "ConstrainedSolveFullResidualReplayCount" -> Lookup[planned,
      "ConstrainedSolveFullResidualReplayCount", 0],
    "ConstrainedSolveNativeCoreReplayCount" -> Lookup[planned,
      "ConstrainedSolveNativeCoreReplayCount", 0],
    "PhaseSeconds" -> <|"ConstrainedAttempt" ->
        Lookup[planned, "Seconds", 0.], "FullFallback" -> fullSeconds|>,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticOffDiagonalBlockConstrainedAffineFallback[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidConstrainedFallbackArguments"];

(* After the modal image has fixed the affine section, each remaining image
   is independent.  This immutable payload contains the layout, provider and
   constrained plan needed by a helper. *)
multiquadraticOffDiagonalBlockFollowerImagePayload[layout_Association,
    provider_Association, plan_Association, pointCount_, maximumAttempts_,
    randomSeed_Integer] := Module[{payload},
  If[! multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[layout] ||
      ! multiquadraticOffDiagonalBlockProviderHotValidQ[provider] ||
      ! multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan] ||
      ! SameQ[layout["CoefficientData"], provider["CoefficientData"]] ||
      ! SameQ[plan["CoefficientData"], layout["CoefficientData"]] ||
      ! (pointCount === Automatic || IntegerQ[pointCount] && pointCount > 0) ||
      ! (maximumAttempts === Automatic ||
        IntegerQ[maximumAttempts] && maximumAttempts > 0),
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidFollowerImagePayloadArguments"]]];
  payload = <|"Schema" -> "MultiquadraticFollowerImagePayloadV1",
    "PointCount" -> pointCount, "MaximumAttempts" -> maximumAttempts,
    "RandomSeed" -> randomSeed,
    "Layout" -> layout, "Provider" -> provider, "Plan" -> plan|>;
  payload
];
multiquadraticOffDiagonalBlockFollowerImagePayload[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidFollowerImagePayloadArguments"];

multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[payload_Association] := Module[
  {layout = Lookup[payload, "Layout", $Failed],
   provider = Lookup[payload, "Provider", $Failed],
   plan = Lookup[payload, "Plan", $Failed]},
  If[! AssociationQ[layout] || ! AssociationQ[provider] ||
      ! AssociationQ[plan] ||
      Lookup[payload, "Schema", None] =!=
        "MultiquadraticFollowerImagePayloadV1" ||
      ! multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[layout] ||
      ! multiquadraticOffDiagonalBlockProviderHotValidQ[provider] ||
      ! multiquadraticOffDiagonalBlockConstrainedPlanValidQ[plan] ||
      ! SameQ[layout["CoefficientData"], provider["CoefficientData"]] ||
      ! SameQ[plan["CoefficientData"], layout["CoefficientData"]] ||
      ! (Lookup[payload, "PointCount", None] === Automatic ||
        IntegerQ[Lookup[payload, "PointCount", None]] &&
          payload["PointCount"] > 0) ||
      ! (Lookup[payload, "MaximumAttempts", None] === Automatic ||
        IntegerQ[Lookup[payload, "MaximumAttempts", None]] &&
          payload["MaximumAttempts"] > 0) ||
      ! IntegerQ[Lookup[payload, "RandomSeed", None]],
    Return[False]];
  True
];
multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[___] := False;

(* A follower task has no access to the reconstruction's caches, counters or
   telemetry.  The sampled matrix stays on the worker. *)
multiquadraticOffDiagonalBlockFollowerImageSolve[payload_Association,
    request_Association, payloadValidated_: False] := Module[
  {prime = Lookup[request, "Prime", $Failed],
   value = Lookup[request, "RegulatorValue", $Failed], sample,
   samplingTiming, solveResult, eliminationTiming, imageStatus, result,
   record, workerKernelID = Quiet[Check[$KernelID, 0]]},
  If[(! TrueQ[payloadValidated] &&
        ! multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[payload]) ||
      ! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidFollowerImageSolveArguments"]]];
  {samplingTiming, sample} = AbsoluteTiming[
    multiquadraticOffDiagonalBlockAssembleSample[payload["Layout"],
      payload["Provider"], value, prime,
      "PointCount" -> payload["PointCount"],
      "MaximumAttempts" -> payload["MaximumAttempts"],
      "RandomSeed" -> payload["RandomSeed"]]];
  If[Lookup[sample, "Status", None] =!=
      "AssembledMultiquadraticSampleV1",
    eliminationTiming = 0.;
    result = <|"Status" -> "ReconstructionSampleFailed",
      "Prime" -> prime, "RegulatorValue" -> value, "Detail" -> sample,
      "SamplingSeconds" -> samplingTiming, "EliminationSeconds" -> 0.,
      "SolvePath" -> "FollowerSampleFailed"|>,
    {eliminationTiming, solveResult} = AbsoluteTiming[
      multiquadraticOffDiagonalBlockConstrainedAffineFallback[sample["Matrix"],
        sample["RightHandSide"], prime, payload["Plan"]]];
    imageStatus = Lookup[solveResult, "Status", None];
    If[! MemberQ[{"MultiquadraticConstrainedAffineSolution",
          "MultiquadraticConstrainedAffineFallbackSolution"}, imageStatus],
      result = <|"Status" -> "ReconstructionConstrainedSolveFailed",
        "Prime" -> prime, "RegulatorValue" -> value,
        "Detail" -> solveResult, "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming,
        "SolvePath" -> "ConstrainedPlanRejectedImage"|>,
      result = Join[<|"Status" -> "OK", "Prime" -> prime,
        "RegulatorValue" -> value, "EpsilonMod" -> sample["EpsilonMod"],
        "TrainingImageKeys" -> sample["TrainingImageKeys"],
        "SamplePhaseSeconds" -> sample["PhaseSeconds"],
        "Rank" -> solveResult["Rank"],
        "Nullity" -> solveResult["Nullity"],
        "PivotColumns" -> solveResult["PivotColumns"],
        "FreeColumns" -> solveResult["FreeColumns"],
        "CanonicalValues" -> solveResult["CanonicalValues"],
        "SolvePath" -> solveResult["SolvePath"],
        "FullResidualZero" -> solveResult["FullResidualZero"],
        "SamplingSeconds" -> samplingTiming,
        "EliminationSeconds" -> eliminationTiming,
        "FollowerSolveKind" -> If[imageStatus ===
          "MultiquadraticConstrainedAffineSolution", "Constrained",
          "FullAffineFallback"]|>,
        KeyTake[solveResult, {"ConstrainedSolveBackendRequested",
          "ConstrainedSolveBackendUsed", "ConstrainedSolveBackendThreads",
          "ConstrainedSolveBackendFallbackReason",
          "ConstrainedSolveNativeAttempted",
          "ConstrainedSolveNativeValidationFailure",
          "ConstrainedSolveNativeValidationRecovered",
          "ConstrainedSolveFullResidualReplayCount",
          "ConstrainedSolveNativeCoreReplayCount",
          "FullResidualCheckMethod", "FullResidualExact",
          "FullResidualChecks", "NullspaceResidualZero",
          "NativeCoreResidualZero", "NativeCoreResidualExact",
          "PhaseSeconds"}]]]];
  record = <|"Status" -> "MultiquadraticFollowerImageRecordV1",
    "Prime" -> prime, "RegulatorValue" -> value,
    "WorkerKernelID" -> If[IntegerQ[workerKernelID], workerKernelID, 0],
    "Result" -> result|>;
  record
];
multiquadraticOffDiagonalBlockFollowerImageSolve[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidFollowerImageSolveArguments"];

multiquadraticOffDiagonalBlockFollowerImageAuthenticate[record_Association,
    payload_Association, request_Association,
    payloadValidated_: False] := Module[
  {prime = Lookup[request, "Prime", $Failed],
   value = Lookup[request, "RegulatorValue", $Failed], result, status,
   trainingKeys},
  If[(! TrueQ[payloadValidated] &&
        ! multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[payload]) ||
      ! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticOffDiagonalBlockFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "InvalidAuthenticationArguments"|>]]];
  If[Lookup[record, "Status", None] =!=
        "MultiquadraticFollowerImageRecordV1" ||
      Lookup[record, {"Prime", "RegulatorValue"}, None] =!= {prime, value} ||
      ! IntegerQ[Lookup[record, "WorkerKernelID", None]] ||
      record["WorkerKernelID"] < 0,
    Return[multiquadraticOffDiagonalBlockFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageRecordKeyMismatch"|>]]];
  result = Lookup[record, "Result", $Failed];
  If[! AssociationQ[result] ||
      Lookup[result, {"Prime", "RegulatorValue"}, None] =!= {prime, value},
    Return[multiquadraticOffDiagonalBlockFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageResultKeyMismatch"|>]]];
  status = Lookup[result, "Status", None];
  If[status === "OK",
    trainingKeys = Lookup[result, "TrainingImageKeys", $Failed];
    If[Lookup[result, "EpsilonMod", None] =!=
          multiquadraticOffDiagonalBlockModRational[value, prime] ||
        {Lookup[result, "Rank", None], Lookup[result, "Nullity", None],
          Lookup[result, "PivotColumns", None]} =!=
          Lookup[payload["Plan"], {"Rank", "Nullity", "PivotColumns"}] ||
        Lookup[result, "FreeColumns", None] =!=
          payload["Plan", "FreeColumns"] ||
        ! multiquadraticOffDiagonalBlockFullResidualEvidenceValidQ[result, prime] ||
        ! ListQ[trainingKeys] || trainingKeys === {} ||
        ! AllTrue[trainingKeys, MatchQ[#1,
          {prime, value, {_Integer, _Integer}}] &] ||
        ! VectorQ[Lookup[result, "CanonicalValues", None],
          Function[item, IntegerQ[item] && 0 <= item < prime]] ||
        Length[result["CanonicalValues"]] =!=
          payload["Plan", "UnknownCount"] ||
        ! MemberQ[{"Constrained", "FullAffineFallback"},
          Lookup[result, "FollowerSolveKind", None]],
      Return[multiquadraticOffDiagonalBlockFailure[
        "FollowerImageAuthenticationFailed",
        <|"Reason" -> "FollowerImageResultCertificateInvalid"|>]]],
    If[! MemberQ[{"ReconstructionSampleFailed",
          "ReconstructionConstrainedSolveFailed"}, status],
      Return[multiquadraticOffDiagonalBlockFailure[
        "FollowerImageAuthenticationFailed",
        <|"Reason" -> "FollowerImageResultStatusInvalid"|>]]]];
  If[! AllTrue[Lookup[result,
        {"SamplingSeconds", "EliminationSeconds"}, {-1, -1}],
      NumericQ[#1] && #1 >= 0 &],
    Return[multiquadraticOffDiagonalBlockFailure[
      "FollowerImageAuthenticationFailed",
      <|"Reason" -> "FollowerImageTimingInvalid"|>]]];
  <|"Status" -> "AuthenticatedMultiquadraticFollowerImageV1",
    "Prime" -> prime, "RegulatorValue" -> value|>
];
multiquadraticOffDiagonalBlockFollowerImageAuthenticate[___] :=
  multiquadraticOffDiagonalBlockFailure["FollowerImageAuthenticationFailed",
    <|"Reason" -> "InvalidAuthenticationArguments"|>];

(* Broker helper entry: taskBrokerRead memoizes the immutable payload by file
   and modification time on a persistent helper. *)
multiquadraticOffDiagonalBlockFollowerImageTask[dataFile_String,
    request_Association] := Module[{payload = taskBrokerRead[dataFile], valid},
  valid = taskBrokerCached[
    {"mqfollow-payload-valid", dataFile, FileDate[dataFile]},
    multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[payload]];
  If[! TrueQ[valid], $Failed,
    multiquadraticOffDiagonalBlockFollowerImageSolve[
      payload, request, True]]
];
multiquadraticOffDiagonalBlockFollowerImageTask[___] := $Failed;

(* Concurrency counts helper-evaluated images.  Resolve Automatic against the
   pool-owned family/core grant and helpers that are actually free; the
   TaskBroker remains the only owner of Wolfram kernels.  FLINT's dense modular
   solve is effectively single-threaded at the image sizes used here, while the
   native evaluation stages are short.  Throughput therefore comes from one
   core per independent image, not from reserving two cores for each image.
   Multi-family waves stay serial so the pool can divide resources among
   families instead of creating nested image fan-out. *)
multiquadraticOffDiagonalBlockFollowerImageKernelCount[requested_,
    nativeThreads_Integer] := Module[
  {processors, free, requestedCount, processorCount, activeFamilies},
  If[! (requested === Automatic ||
        IntegerQ[requested] && Between[requested, {1, 8}]) ||
      ! Between[nativeThreads, {1, 8}], Return[1]];
  activeFamilies = Quiet[Check[taskBrokerActiveFamilyCount[], 1]];
  If[IntegerQ[activeFamilies] && activeFamilies > 1, Return[1]];
  requestedCount = Replace[requested, Automatic -> 8];
  If[requestedCount === 1, Return[1]];
  processors = Quiet[Check[taskBrokerNativeCoreQuota[], 1]];
  processorCount = If[IntegerQ[processors] && processors > 0,
    processors, 1];
  If[processorCount < 2, Return[1]];
  If[! TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]], Return[1]];
  free = Quiet[Check[taskBrokerFreeKernels[], 0]];
  If[! IntegerQ[free] || free < 1, Return[1]];
  Max[1, Min[8, requestedCount, processorCount, free]]
];
multiquadraticOffDiagonalBlockFollowerImageKernelCount[___] := 1;

(* One wave gives as many requests as possible to clean broker helpers.  The
   coordinator retains all reconstructed images and can become much slower
   than a helper as that cache grows, so it participates only if the available
   helper count changed after the wave width was chosen.  Results are restored
   to request order before use.  A missing, timed-out or malformed helper
   result is recomputed locally only while the absolute reconstruction deadline
   remains; otherwise it is abandoned with typed budget evidence.  dispatcher
   is a private test seam; production uses only the TaskBroker data-file
   protocol.  A supplied payloadDataFile is immutable and shared by every wave,
   allowing persistent helpers to reuse taskBrokerRead's parsed payload. *)
multiquadraticOffDiagonalBlockFollowerImageWave[payload_Association, requests_List,
    concurrency_Integer, timeout_Integer, absoluteDeadline_,
    dispatcher_: Automatic, payloadDataFile_: Automatic,
    payloadValidated_: False] := Module[
  {startTime = AbsoluteTime[], serial, dataFile, codes, handle, farmed,
   helperResults, localResults, results, resultRoutes, authentication,
   fallbackIndices = {}, route, dataKey, free, helperCount = 0,
   helperIndices = {}, localIndices = {}, actualConcurrency = 1,
   batchSize = Length[requests], localPosition, fallbackPosition, index},
  serial[] := multiquadraticOffDiagonalBlockFollowerImageSolve[payload, #1] & /@
    requests;
  If[(! TrueQ[payloadValidated] &&
        ! multiquadraticOffDiagonalBlockFollowerImagePayloadValidQ[payload]) ||
      ! MatchQ[requests, {__Association}] || Length[requests] > 8 ||
      ! AllTrue[requests, IntegerQ[Lookup[#1, "Prime", None]] &&
        PrimeQ[#1["Prime"]] && MatchQ[
          Lookup[#1, "RegulatorValue", None], _Integer | _Rational] &] ||
      ! Between[concurrency, {1, 8}] || timeout < 1 ||
      ! multiquadraticOffDiagonalBlockDeadlineQ[absoluteDeadline],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidFollowerImageWaveArguments"]]];
  If[concurrency < 2,
    Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
      "Route" -> "Serial", "Concurrency" -> 1,
      "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
      "BrokerHelperCount" -> 0, "FallbackIndices" -> {},
      "Timeout" -> timeout,
      "Results" -> serial[],
      "ResultRoutes" -> ConstantArray["SerialFollower", batchSize],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
  If[dispatcher === Automatic,
    free = Quiet[Check[taskBrokerFreeKernels[], 0]];
    If[! TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]] ||
        ! IntegerQ[free] || free < 1,
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout, "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    helperCount = Min[concurrency, batchSize, free];
    If[helperCount < 1,
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout, "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    dataFile = If[StringQ[payloadDataFile] && FileExistsQ[payloadDataFile],
      payloadDataFile,
      If[payloadDataFile === Automatic,
        dataKey = StringReplace[CreateUUID[], "-" -> ""];
        taskBrokerDataFile["mqfollow_" <> dataKey, payload], $Failed]];
    If[! StringQ[dataFile],
      Return[<|"Status" -> "MultiquadraticFollowerImageWaveV1",
        "Route" -> "SerialFallback", "Concurrency" -> 1,
        "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
        "BrokerHelperCount" -> 0,
        "Timeout" -> timeout,
        "FallbackIndices" -> Range[batchSize],
        "Results" -> serial[],
        "ResultRoutes" -> ConstantArray["SerialFollowerFallback",
          batchSize],
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
    helperIndices = Range[helperCount];
    localIndices = Range[helperCount + 1, batchSize];
    codes = ("FeynFacet`Private`multiquadraticOffDiagonalBlockFollowerImageTask[" <>
        ToString[dataFile, InputForm] <> "," <>
        ToString[#1, InputForm] <> "]" &) /@ requests[[helperIndices]];
    handle = taskBrokerSubmit[codes, "Label" -> "mqfollow",
      "Timeout" -> timeout];
    localResults = Table[
      index = localIndices[[localPosition]];
      If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[absoluteDeadline],
        Return[multiquadraticOffDiagonalBlockBudgetExhausted[
          "RegulatorReconstruction:FollowerWaveLocal",
          AbsoluteTime[] - startTime, absoluteDeadline,
          <|"AbandonedIndices" ->
              Drop[localIndices, localPosition - 1],
            "AbandonedRequests" -> requests[[
              Drop[localIndices, localPosition - 1]]],
            "LateBrokerWorkNotCancelled" -> True|>], Module]];
      multiquadraticOffDiagonalBlockFollowerImageSolve[payload, requests[[index]]],
      {localPosition, Length[localIndices]}];
    farmed = taskBrokerCollect[handle];
    helperResults = If[ListQ[farmed] && Length[farmed] === helperCount,
      farmed, ConstantArray[$Failed, helperCount]];
    results = Join[helperResults, localResults];
    resultRoutes = Join[ConstantArray["TaskBrokerFollower", helperCount],
      ConstantArray["SerialFollower", Length[localIndices]]];
    route = "TaskBroker",
    helperCount = Min[concurrency, batchSize];
    helperIndices = Range[helperCount];
    localIndices = Range[helperCount + 1, batchSize];
    helperResults = (Quiet[Check[dispatcher[payload, #1], $Failed]] &) /@
      requests[[helperIndices]];
    localResults = multiquadraticOffDiagonalBlockFollowerImageSolve[payload, #1] & /@
      requests[[localIndices]];
    results = Join[helperResults, localResults];
    resultRoutes = Join[ConstantArray["InjectedFollower", helperCount],
      ConstantArray["SerialFollower", Length[localIndices]]];
    route = "InjectedDispatcher"];
  actualConcurrency = helperCount + If[localIndices === {}, 0, 1];
  authentication = MapThread[
    multiquadraticOffDiagonalBlockFollowerImageAuthenticate[
      #1, payload, #2, True] &,
    {results, requests}];
  fallbackIndices = Flatten[Position[
    Lookup[authentication, "Status", None],
    Except["AuthenticatedMultiquadraticFollowerImageV1"], {1},
    Heads -> False]];
  Do[index = fallbackIndices[[fallbackPosition]];
    If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[absoluteDeadline],
      Return[multiquadraticOffDiagonalBlockBudgetExhausted[
        "RegulatorReconstruction:FollowerWaveFallback",
        AbsoluteTime[] - startTime, absoluteDeadline,
        <|"WaveRoute" -> route,
          "AbandonedFallbackIndices" ->
            Drop[fallbackIndices, fallbackPosition - 1],
          "AbandonedRequests" -> requests[[
            Drop[fallbackIndices, fallbackPosition - 1]]],
          "LateBrokerWorkNotCancelled" ->
            (dispatcher === Automatic)|>], Module]];
    results[[index]] = multiquadraticOffDiagonalBlockFollowerImageSolve[payload,
      requests[[index]]];
    resultRoutes[[index]] = "SerialFollowerFallback",
    {fallbackPosition, Length[fallbackIndices]}];
  <|"Status" -> "MultiquadraticFollowerImageWaveV1",
    "Route" -> If[fallbackIndices === {}, route,
      route <> "WithSerialFallback"],
    "Concurrency" -> actualConcurrency,
    "RequestedConcurrency" -> concurrency, "BatchSize" -> batchSize,
    "BrokerHelperCount" -> If[dispatcher === Automatic, helperCount, 0],
    "FallbackIndices" -> fallbackIndices, "Timeout" -> timeout,
    "Results" -> results, "ResultRoutes" -> resultRoutes,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticOffDiagonalBlockFollowerImageWave[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidFollowerImageWaveArguments"];

(* Construct a reusable pilot envelope.  Prime and regulator metadata are
   copied into the solution as well as the outer record. *)
multiquadraticOffDiagonalBlockPilotImageRecord[prime_Integer, value_,
    sample_Association, solution_Association] := Module[{pilot},
  If[! MatchQ[value, _Integer | _Rational],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidPilotImageRecordArguments"]]];
  pilot = <|"Prime" -> prime, "RegulatorValue" -> value,
    "Sample" -> sample,
    "Solution" -> Join[solution, <|"RegulatorValue" -> value,
      "EpsilonMod" -> Lookup[sample, "EpsilonMod", $Failed]|>]|>;
  pilot
];
multiquadraticOffDiagonalBlockPilotImageRecord[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidPilotImageRecordArguments"];

(* Full cache-admission check.  The direct residual replay proves that the
   response solves this sample, including an independent kernel basis.  The
   free-column identity fixes the deterministic affine section and proves
   nullspace rank without paying for another RREF. *)
multiquadraticOffDiagonalBlockPilotImageAuthenticate[pilot_Association,
    layout_Association, provider_Association] := Module[
  {prime, value, epsilonMod, sample, solution, matrix, right, dimensions,
   unknownCount, rank, nullity, pivots, free, particular, nullspace,
   particularResidualQ, particularCanonicalQ, nullResidualQ,
   nullIndependentQ, acceptedPoints, trainingKeys, normalizationCount,
   expectedRows, failure},
  failure[reason_String, detail_Association : <||>] :=
    multiquadraticOffDiagonalBlockFailure["PilotImageAuthenticationFailed",
      Join[<|"Reason" -> reason,
        "PilotKey" -> Lookup[pilot, {"Prime", "RegulatorValue"}, None]|>,
        detail]];
  {prime, value} = Lookup[pilot, {"Prime", "RegulatorValue"}, $Failed];
  sample = Lookup[pilot, "Sample", $Failed];
  solution = Lookup[pilot, "Solution", $Failed];
  If[! multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[layout] ||
      ! multiquadraticOffDiagonalBlockProviderHotValidQ[provider] ||
      ! SameQ[layout["CoefficientData"], provider["CoefficientData"]] ||
      ! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! MatchQ[value, _Integer | _Rational] ||
      ! AssociationQ[sample] || ! AssociationQ[solution],
    Return[failure["MalformedPilotEnvelope"]]];
  epsilonMod = multiquadraticOffDiagonalBlockModRational[value, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[failure["InvalidPilotRegulatorImage"]]];
  If[Lookup[sample, "Status", None] =!=
        "AssembledMultiquadraticSampleV1" ||
      Lookup[sample, "Prime", None] =!= prime ||
      Lookup[sample, "EpsilonValue", None] =!= value ||
      Lookup[sample, "EpsilonMod", None] =!= epsilonMod ||
      ! SameQ[Lookup[sample, "CoefficientData", None],
        layout["CoefficientData"]] ||
      Lookup[sample, "Provider", None] =!= provider["Kind"] ||
      Lookup[sample, "ColumnOrder", None] =!= layout["ColumnOrder"] ||
      Lookup[sample, "RowOrder", None] =!= layout["RowOrder"],
    Return[failure["PilotSampleDataMismatch"]]];
  If[Lookup[solution, "Status", None] =!=
        "MultiquadraticAffineSolution" ||
      Lookup[solution, "Prime", None] =!= prime ||
      Lookup[solution, "RegulatorValue", None] =!= value ||
      Lookup[solution, "EpsilonMod", None] =!= epsilonMod,
    Return[failure["PilotSolutionKeyMismatch"]]];
  matrix = Lookup[sample, "Matrix", $Failed];
  right = Lookup[sample, "RightHandSide", $Failed];
  acceptedPoints = Lookup[sample, "AcceptedPoints", $Failed];
  trainingKeys = Lookup[sample, "TrainingImageKeys", $Failed];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  dimensions = Quiet[Check[Dimensions[matrix], $Failed]];
  expectedRows = If[ListQ[acceptedPoints] && IntegerQ[normalizationCount],
    Length[acceptedPoints] layout["EquationsPerPoint"] +
      normalizationCount, $Failed];
  If[! MatrixQ[matrix,
        Function[item, IntegerQ[item] && 0 <= item < prime]] ||
      ! VectorQ[right,
        Function[item, IntegerQ[item] && 0 <= item < prime]] ||
      ! MatchQ[dimensions, {_Integer?Positive, _Integer?Positive}] ||
      Length[right] =!= dimensions[[1]] ||
      dimensions[[2]] =!= layout["UnknownCount"] ||
      ! MatchQ[acceptedPoints, {{_Integer, _Integer} ..}] ||
      ! DuplicateFreeQ[acceptedPoints] ||
      ! AllTrue[Flatten[acceptedPoints], 0 <= #1 < prime &] ||
      ! IntegerQ[normalizationCount] || normalizationCount < 0 ||
      dimensions[[1]] =!= expectedRows ||
      ! ListQ[trainingKeys] || ! DuplicateFreeQ[trainingKeys] ||
      trainingKeys =!= ({prime, value, Mod[#1, prime]} & /@ acceptedPoints) ||
      Lookup[sample, "MatrixDimensions", None] =!= dimensions ||
      Lookup[solution, "MatrixDimensions", None] =!= dimensions,
    Return[failure["PilotMatrixShapeMismatch"]]];
  unknownCount = dimensions[[2]];
  {rank, nullity} = Lookup[solution, {"Rank", "Nullity"}, $Failed];
  pivots = Lookup[solution, "PivotColumns", $Failed];
  free = Lookup[solution, "FreeColumns", $Failed];
  particular = Lookup[solution, "ParticularSolution", $Failed];
  nullspace = Lookup[solution, "NullspaceBasis", $Failed];
  If[! IntegerQ[rank] || ! IntegerQ[nullity] || rank < 0 || nullity < 0 ||
      rank + nullity =!= unknownCount || rank > dimensions[[1]] ||
      ! VectorQ[pivots, IntegerQ] || Length[pivots] =!= rank ||
      ! VectorQ[free, IntegerQ] || Length[free] =!= nullity ||
      ! DuplicateFreeQ[Join[pivots, free]] ||
      Sort[Join[pivots, free]] =!= Range[unknownCount] ||
      ! VectorQ[particular, IntegerQ] ||
      Length[particular] =!= unknownCount ||
      ! If[nullity === 0, nullspace === {},
        MatrixQ[nullspace, IntegerQ] &&
          Dimensions[nullspace] === {nullity, unknownCount}] ||
      ! AllTrue[Join[particular, Flatten[nullspace]],
        0 <= #1 < prime &],
    Return[failure["PilotAffineStructureInvalid"]]];
  particularResidualQ = VectorQ[
    Mod[matrix . particular - right, prime], #1 === 0 &];
  particularCanonicalQ = nullity === 0 ||
    particular[[free]] === ConstantArray[0, nullity];
  nullResidualQ = nullity === 0 || MatrixQ[
    Normal[Mod[matrix . Transpose[nullspace], prime]], #1 === 0 &];
  nullIndependentQ = nullity === 0 ||
    Normal[Mod[nullspace[[All, free]], prime]] ===
      Normal[IdentityMatrix[nullity]];
  If[! TrueQ[particularResidualQ] || ! TrueQ[particularCanonicalQ],
    Return[failure[If[! TrueQ[particularResidualQ],
      "PilotParticularResidualNonzero",
      "PilotParticularFreeCoordinatesNonzero"]]]];
  If[! TrueQ[nullResidualQ] || ! TrueQ[nullIndependentQ],
    Return[failure["PilotNullspaceInvalid",
      <|"NullspaceResidualZero" -> nullResidualQ,
        "NullspaceIndependent" -> nullIndependentQ|>]]];
  <|"Status" -> "AuthenticatedMultiquadraticPilotImageV1",
    "Prime" -> prime, "RegulatorValue" -> value,
    "ParticularResidualZero" -> True,
    "ParticularFreeCoordinatesZero" -> True,
    "NullspaceResidualZero" -> True,
    "NullspaceIndependent" -> True|>
];
multiquadraticOffDiagonalBlockPilotImageAuthenticate[___] :=
  multiquadraticOffDiagonalBlockFailure["PilotImageAuthenticationFailed",
    <|"Reason" -> "InvalidPilotAuthenticationArguments"|>];

Options[multiquadraticOffDiagonalBlockProviderSupportLadder] = {
  "BaseDegreeOffset" -> {0, 0},
  "DegreeOffsetLadder" -> Automatic,
  "Images" -> Automatic,
  "MaximumImageAttempts" -> 6,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082701,
  "PlanDiscoveryBackend" -> Automatic,
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> Automatic,
  "Deadline" -> Infinity
};

(* The deferred bundle's materialized Inhomogeneity is a shape placeholder, so its
   support question is decided only after the authenticated provider exists.
   A rung is admitted by two usable, unanimous (prime, regulator) images
   assembled by the production provider and row equations.  Failed samples/evidence are
   replaced from a bounded candidate schedule.  Mixed usable verdicts stop
   typed and inconclusive; only two unanimous inconsistencies may advance to
   the next rung or, at ladder exhaustion, support an obstruction.  Only
   layout/support are rebuilt: the builder supplied by the driver reuses the
   full letter records, the exact bundle-derived denominator and, whenever
   its coefficient data still agree, the provider object itself. *)
multiquadraticOffDiagonalBlockProviderSupportLadder[basePreparation_Association,
    baseLayout_Association, baseProvider_Association, rungBuilder_,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], gate, baseOffset, ladder, offsets, images,
   maximumImageAttempts, pointCount, maximumAttempts, randomSeed,
   requestedBackend, threads,
   minimumEntries, deadline, skipped = {}, rungs = {}, offset, built,
   preparation, layout, provider, providerReused, imageEvidence, pilotImages,
   unusableEvidence, attemptedImages, sampleSeconds, sample,
   evidenceSeconds, evidence, statuses, rungStatus, boundPilot,
   pilotAuthentication,
   adopted = None},
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockProviderSupportLadder]]]];
  If[AssociationQ[gate], Return[gate]];
  If[! multiquadraticOffDiagonalBlockPreparationValidQ[basePreparation] ||
      ! multiquadraticOffDiagonalBlockAssemblyLayoutValidQ[baseLayout] ||
      ! multiquadraticOffDiagonalBlockProviderValidQ[baseProvider] ||
      ! SameQ[baseLayout["Preparation"], basePreparation] ||
      ! SameQ[baseLayout["CoefficientData"],
        baseProvider["CoefficientData"]],
    Return[multiquadraticOffDiagonalBlockFailure[
      "InvalidProviderSupportLadderInput"]]];
  baseOffset = OptionValue["BaseDegreeOffset"];
  ladder = Replace[OptionValue["DegreeOffsetLadder"],
    Automatic :> multiquadraticOffDiagonalBlockDegreeOffsetLadder[]];
  If[! MatchQ[baseOffset, {_Integer, _Integer}] || Min[baseOffset] < 0 ||
      ! MatchQ[ladder, {} | {{_Integer, _Integer} ..}] ||
      ! AllTrue[Flatten[ladder], IntegerQ[#1] && #1 >= 0 &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDegreeOffsetLadder",
      <|"BaseDegreeOffset" -> baseOffset,
        "DegreeOffsetLadder" -> ladder|>]]];
  offsets = {baseOffset};
  Do[If[offset[[1]] <= baseOffset[[1]] &&
        offset[[2]] <= baseOffset[[2]],
      AppendTo[skipped, offset], AppendTo[offsets, offset]],
    {offset, ladder}];
  offsets = DeleteDuplicates[offsets];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticOffDiagonalBlockDefaultPrimes,
      $multiquadraticOffDiagonalBlockDefaultRegulatorValues}]];
  maximumImageAttempts = OptionValue["MaximumImageAttempts"];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}] ||
      Length[images] < 2 || Length[DeleteDuplicates[images]] < 2 ||
      ! IntegerQ[maximumImageAttempts] || maximumImageAttempts < 2 ||
      ! AllTrue[images[[All, 1]],
        PrimeQ[#1] && Mod[#1, 4] === 3 &&
          3 < #1 < $multiquadraticOffDiagonalBlockWordPrimeLimit &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidProviderSupportImages",
      <|"Images" -> images,
        "MaximumImageAttempts" -> maximumImageAttempts,
        "Required" -> "two usable distinct (prime, regulator) images"|>]]];
  images = Take[DeleteDuplicates[images], UpTo[maximumImageAttempts]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  randomSeed = OptionValue["RandomSeed"];
  requestedBackend = OptionValue["PlanDiscoveryBackend"];
  threads = OptionValue["PlanDiscoveryBackendThreads"];
  minimumEntries = OptionValue["PlanDiscoveryBackendMinimumEntries"];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticOffDiagonalBlockDeadlineQ[deadline],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDeadline"]]];
  Do[
    If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline],
      Return[multiquadraticOffDiagonalBlockBudgetExhausted[
        "DeferredProviderSupportLadder", AbsoluteTime[] - startTime,
        deadline, <|"NextDegreeOffset" -> offset,
          "LadderRungs" -> rungs|>], Module]];
    built = If[offset === baseOffset,
      <|"Preparation" -> basePreparation, "Layout" -> baseLayout,
        "Provider" -> baseProvider|>, rungBuilder[offset]];
    If[! AssociationQ[built] ||
        ! multiquadraticOffDiagonalBlockPreparationValidQ[
          Lookup[built, "Preparation", <||>]] ||
        ! multiquadraticOffDiagonalBlockAssemblyLayoutValidQ[
          Lookup[built, "Layout", <||>]] ||
        ! multiquadraticOffDiagonalBlockProviderValidQ[
          Lookup[built, "Provider", <||>]],
      Return[multiquadraticOffDiagonalBlockFailure[
        "ProviderSupportRungPreparationFailed",
        <|"DegreeOffset" -> offset, "Detail" -> built,
          "LadderRungs" -> rungs|>], Module]];
    preparation = built["Preparation"];
    layout = built["Layout"];
    provider = built["Provider"];
    If[! SameQ[layout["Preparation"], preparation] ||
        ! SameQ[layout["CoefficientData"], provider["CoefficientData"]],
      Return[multiquadraticOffDiagonalBlockFailure["ProviderSupportRungDataMismatch",
        <|"DegreeOffset" -> offset|>],
        Module]];
    providerReused = SameQ[provider, baseProvider];
    imageEvidence = {}; pilotImages = {}; unusableEvidence = {};
    attemptedImages = {};
    Do[
      If[Length[imageEvidence] >= 2, Break[]];
      AppendTo[attemptedImages, image];
      {sampleSeconds, sample} = AbsoluteTiming[
        multiquadraticOffDiagonalBlockAssembleSample[layout, provider, image[[2]],
          image[[1]], "PointCount" -> pointCount,
          "MaximumAttempts" -> maximumAttempts,
          "RandomSeed" -> randomSeed + 1009 imageIndex]];
      If[Lookup[sample, "Status", None] =!=
          "AssembledMultiquadraticSampleV1",
        AppendTo[unusableEvidence, <|"Image" -> image,
          "Reason" -> "ProviderSupportImageAssemblyFailed",
          "Detail" -> sample, "SamplingSeconds" -> sampleSeconds|>];
        Continue[]];
      {evidenceSeconds, evidence} = AbsoluteTiming[
        multiquadraticOffDiagonalBlockAffineConsistencyEvidence[sample["Matrix"],
          sample["RightHandSide"], image[[1]],
          preparation["OffDiagonalBasisTransformationUnknownCount"],
          preparation["ResidueUnknownCount"], requestedBackend, threads,
          minimumEntries]];
      If[! MemberQ[{"ProviderSupportImageConsistent",
            "ProviderSupportImageInconsistent"},
          Lookup[evidence, "Status", None]],
        AppendTo[unusableEvidence, <|"Image" -> image,
          "Reason" -> "ProviderSupportImageEvidenceFailed",
          "Detail" -> evidence, "SamplingSeconds" -> sampleSeconds,
          "EvidenceSeconds" -> evidenceSeconds|>];
        Continue[]];
      AppendTo[imageEvidence, Join[KeyDrop[evidence, {"Solution"}],
        <|"RegulatorValue" -> image[[2]],
          "AcceptedPoints" -> sample["AcceptedPoints"],
          "SamplingSeconds" -> sampleSeconds,
          "EvidenceSeconds" -> evidenceSeconds|>]];
      If[Lookup[evidence, "Status", None] ===
          "ProviderSupportImageConsistent",
        boundPilot = multiquadraticOffDiagonalBlockPilotImageRecord[
          image[[1]], image[[2]], sample, evidence["Solution"]];
        pilotAuthentication = If[AssociationQ[boundPilot],
          multiquadraticOffDiagonalBlockPilotImageAuthenticate[
            boundPilot, layout, provider],
          multiquadraticOffDiagonalBlockFailure["PilotImageAuthenticationFailed",
            <|"Reason" -> "PilotRecordConstructionFailed"|>]];
        If[! AssociationQ[boundPilot] ||
            Lookup[pilotAuthentication, "Status", None] =!=
              "AuthenticatedMultiquadraticPilotImageV1",
          AppendTo[unusableEvidence, <|"Image" -> image,
            "Reason" -> "ProviderSupportPilotAuthenticationFailed",
            "Detail" -> pilotAuthentication|>];
          imageEvidence = Most[imageEvidence],
          AppendTo[pilotImages, boundPilot]]],
      {imageIndex, Length[images]}, {image, {images[[imageIndex]]}}];
    statuses = Lookup[imageEvidence, "Status", {}];
    rungStatus = Which[
      Length[statuses] < 2, "ProviderSupportRungInconclusive",
      statuses === ConstantArray["ProviderSupportImageConsistent", 2],
        "ProviderSupportRungConsistent",
      statuses === ConstantArray["ProviderSupportImageInconsistent", 2],
        "ProviderSupportRungInconsistent",
      True, "ProviderSupportRungMixedEvidence"];
    AppendTo[rungs, <|"DegreeOffset" -> offset,
      "SupportCount" -> Length[preparation["OffDiagonalBasisTransformationNumeratorSupport"]],
      "UnknownCount" -> preparation["UnknownCount"],
      "ProviderReused" -> providerReused,
      "ImageCount" -> Length[imageEvidence],
      "AttemptCount" -> Length[attemptedImages],
      "Images" -> ({Lookup[#1, "Prime", None],
          Lookup[#1, "RegulatorValue", None]} & /@ imageEvidence),
      "AttemptedImages" -> attemptedImages,
      "UnusableImageEvidence" -> unusableEvidence,
      "Ranks" -> Lookup[imageEvidence, "Rank", {}],
      "AugmentedRanks" -> Lookup[imageEvidence, "AugmentedRank", {}],
      "Defects" -> Lookup[imageEvidence, "Defect", {}],
      "ImageEvidence" -> imageEvidence,
      "Status" -> rungStatus|>];
    If[MemberQ[{"ProviderSupportRungInconclusive",
          "ProviderSupportRungMixedEvidence"}, rungStatus],
      Return[<|"Status" -> "DeferredProviderSupportLadderInconclusive",
        "Method" -> "ProviderBackedRankAugmentedRankLadder",
        "Reason" -> If[rungStatus === "ProviderSupportRungMixedEvidence",
          "MixedConsistencyEvidence", "UsableImageQuorumUnavailable"],
        "AdoptedDegreeOffset" -> Missing["NoConsistentRung"],
        "BaseDegreeOffset" -> baseOffset,
        "DegreeOffsetLadder" -> ladder,
        "SkippedDegreeOffsets" -> skipped,
        "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
        "LadderDefects" ->
          ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
        "RequiredUsableImageCount" -> 2,
        "MaximumImageAttempts" -> maximumImageAttempts,
        "FiniteFieldAnsatzInconsistencyEvidenceComplete" -> False,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>, Module]];
    If[rungStatus === "ProviderSupportRungConsistent",
      adopted = <|"Preparation" -> preparation, "Layout" -> layout,
        "Provider" -> provider, "PilotImages" -> pilotImages|>;
      Break[]],
    {offset, offsets}];
  If[AssociationQ[adopted],
    Join[<|"Status" -> "DeferredProviderSupportLadderAdopted",
      "Method" -> "ProviderBackedRankAugmentedRankLadder",
      "AdoptedDegreeOffset" -> Last[rungs]["DegreeOffset"],
      "BaseDegreeOffset" -> baseOffset,
      "DegreeOffsetLadder" -> ladder,
      "SkippedDegreeOffsets" -> skipped,
      "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
      "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
      "ImageCountPerRung" -> 2,
      "MaximumImageAttempts" -> maximumImageAttempts,
      "SuccessfulPilotReuseCount" -> Length[adopted["PilotImages"]],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>, adopted],
    <|"Status" -> "DeferredProviderSupportLadderExhausted",
      "Method" -> "ProviderBackedRankAugmentedRankLadder",
      "AdoptedDegreeOffset" -> Missing["NoConsistentRung"],
      "BaseDegreeOffset" -> baseOffset,
      "DegreeOffsetLadder" -> ladder,
      "SkippedDegreeOffsets" -> skipped,
      "RungCount" -> Length[rungs], "LadderRungs" -> rungs,
      "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
      "ImageCountPerRung" -> 2,
      "MaximumImageAttempts" -> maximumImageAttempts,
      "FiniteFieldAnsatzInconsistencyEvidenceComplete" -> True,
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]
];
multiquadraticOffDiagonalBlockProviderSupportLadder[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidProviderSupportLadderArguments"];

multiquadraticOffDiagonalBlockUnpackVector[preparation_Association, vector_List] := Module[
  {dimensions, gradeCount, support, denominator, variables, offDiagonalBasisTransformationUnknownCount,
   offDiagonalBasisTransformationCoefficients, offDiagonalBasisTransformationBlockComponents, residues},
  If[! multiquadraticOffDiagonalBlockPreparationValidQ[preparation],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPreparation"]]];
  If[Length[vector] =!= preparation["UnknownCount"],
    Return[multiquadraticOffDiagonalBlockFailure["ReconstructedVectorLengthMismatch",
      <|"Expected" -> preparation["UnknownCount"],
        "Observed" -> Length[vector]|>]]];
  dimensions = preparation["Dimensions"];
  gradeCount = preparation["GradeCount"];
  support = preparation["OffDiagonalBasisTransformationNumeratorSupport"];
  denominator = preparation["OffDiagonalBasisTransformationDenominator"];
  variables = preparation["Variables"];
  offDiagonalBasisTransformationUnknownCount = preparation["OffDiagonalBasisTransformationUnknownCount"];
  offDiagonalBasisTransformationCoefficients = Table[
    vector[[multiquadraticOffDiagonalBasisTransformationBlockIndex[dimensions[[1]], dimensions[[2]],
      gradeCount, Length[support], i, j, grade, monomial]]],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, 0, gradeCount - 1},
    {monomial, Length[support]}];
  offDiagonalBasisTransformationBlockComponents = Table[Together[
      Sum[offDiagonalBasisTransformationCoefficients[[i, j, grade, monomial]]
          variables[[1]]^support[[monomial, 1]]
          variables[[2]]^support[[monomial, 2]],
        {monomial, Length[support]}]/denominator],
    {i, dimensions[[1]]}, {j, dimensions[[2]]}, {grade, gradeCount}];
  residues = If[preparation["ResidueUnknownCount"] === 0, {},
    Table[vector[[multiquadraticOffDiagonalBlockResidueIndex[offDiagonalBasisTransformationUnknownCount,
      dimensions[[1]], dimensions[[2]], letter, i, j]]],
      {letter, Length[preparation["OneForms"]]}, {i, dimensions[[1]]},
      {j, dimensions[[2]]}]];
  <|"Status" -> "UnpackedMultiquadraticSolution",
    "OffDiagonalBasisTransformationCoefficients" -> offDiagonalBasisTransformationCoefficients, "OffDiagonalBasisTransformationBlockComponents" -> offDiagonalBasisTransformationBlockComponents,
    "OffDiagonalBasisTransformationBlock" -> Table[multiquadraticFieldCompose[offDiagonalBasisTransformationBlockComponents[[i, j]],
        preparation["Roots"]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    "Residues" -> residues|>
];
multiquadraticOffDiagonalBlockUnpackVector[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidUnpackArguments"];

multiquadraticOffDiagonalBlockChannelMatrixProduct[left_List, right_List, deltas_List] :=
  Module[{leftDimensions = Dimensions[left], rightDimensions = Dimensions[right],
    inner},
  If[Length[leftDimensions] =!= 3 || Length[rightDimensions] =!= 3 ||
      leftDimensions[[2]] =!= rightDimensions[[1]] ||
      leftDimensions[[3]] =!= rightDimensions[[3]], Return[$Failed]];
  inner = leftDimensions[[2]];
  Table[Together /@ Total[Table[
      multiquadraticMultiply[left[[i, k]], right[[k, j]], deltas], {k, inner}]],
    {i, leftDimensions[[1]]}, {j, rightDimensions[[2]]}]
];

(* The exact statement about a reconstructed vector: every grade of
   d_mu G - eps (E G - G C) + eps R omega - Bbar vanishes identically in
   the chart variables.  With a regulator VALUE the identity is made at
   that value, which is what a per-value lift certifies.

   SPECIALIZATION (fixed 2026-08-26, round-2 item 2, Codex review 1.3).
   Until this fix the off-diagonal block equation and the one-forms were specialized at
   epsilonImage while the GAUGE and the RESIDUES were left symbolic in
   eps, and the numeric epsilonImage was then multiplied against them.
   That is wrong whenever the reconstructed object carries eps, which
   the ansatz permits in two ways: the basis-transformation block DENOMINATOR is built from
   the inhomogeneity and routinely carries eps (multiquadraticOffDiagonalBlockUnpackVector
   divides by it), and after the rational-in-eps reconstruction the
   coefficients themselves are rational functions of eps.

   Codex's minimal counterexample, now Tests/Multiquadratic/t_multiquadratic_exact_
   verifier.wls: G = 1/(1 + eps x), Bbar_x = -eps/(1 + eps x)^2,
   E = C = 0, no letters.  The identity is exact at every eps; at
   eps = 2 the pre-fix verifier compared -eps/(1+eps x)^2 against
   -2/(1+2x)^2 and reported a nonzero residual.

   Everything that enters the identity is now specialized at exactly one
   place, before any differentiation or multiplication. *)
multiquadraticOffDiagonalBlockExactChannelResidual[preparation_Association, vector_List,
    epsilonValue_: Automatic] := Module[
  {unpacked, basisTransformationBlock, residues, record, roots, deltas, variables, epsilon,
   epsilonImage, offDiagonalBlockEquation, decompose, eChannels, cChannels, inhomogeneityChannels,
   oneFormChannels, derivative, leftProduct, rightProduct, residueTerm, residual},
  unpacked = multiquadraticOffDiagonalBlockUnpackVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedMultiquadraticSolution",
    Return[unpacked]];
  record = preparation["Record"];
  roots = preparation["Roots"];
  deltas = squareRootRecordRadicand /@ roots;
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  epsilonImage = If[epsilonValue === Automatic, epsilon, epsilonValue];
  (* the reconstructed object at THIS regulator image, not the generic
     one multiplied by a number *)
  (* Quiet: a coefficient singular AT this image is a typed refusal
     below, not a message storm in a campaign log *)
  basisTransformationBlock = Quiet[Map[Together,
    unpacked["OffDiagonalBasisTransformationBlockComponents"] /. epsilon -> epsilonImage, {3}]];
  residues = If[unpacked["Residues"] === {}, {},
    Quiet[Map[Together,
      unpacked["Residues"] /. epsilon -> epsilonImage, {3}]]];
  If[! FreeQ[{basisTransformationBlock, residues}, DirectedInfinity | Indeterminate],
    Return[multiquadraticOffDiagonalBlockFailure["ExactChannelOffDiagonalBasisTransformationSystemSingularAtRegulator",
      <|"EpsilonValue" -> epsilonImage|>]]];
  offDiagonalBlockEquation = record["OffDiagonalBlockEquation"] /. epsilon -> epsilonImage;
  decompose[matrix_] := Map[multiquadraticFieldDecompose[#1, roots] &, matrix, {2}];
  eChannels = decompose /@ offDiagonalBlockEquation[[1]];
  cChannels = decompose /@ offDiagonalBlockEquation[[2]];
  inhomogeneityChannels = decompose /@ offDiagonalBlockEquation[[3]];
  oneFormChannels = Table[
    multiquadraticFieldDecompose[
      preparation["OneForms"][[letter, mu]] /. epsilon -> epsilonImage, roots],
    {letter, Length[preparation["OneForms"]]}, {mu, 2}];
  If[! FreeQ[{eChannels, cChannels, inhomogeneityChannels, oneFormChannels}, $Failed],
    Return[multiquadraticOffDiagonalBlockFailure["ExactChannelDecompositionFailed"]]];
  residual = Table[
    derivative = Map[multiquadraticDerivative[#1, deltas, variables[[mu]]] &,
      basisTransformationBlock, {2}];
    leftProduct = multiquadraticOffDiagonalBlockChannelMatrixProduct[eChannels[[mu]], basisTransformationBlock,
      deltas];
    rightProduct = multiquadraticOffDiagonalBlockChannelMatrixProduct[basisTransformationBlock, cChannels[[mu]],
      deltas];
    If[leftProduct === $Failed || rightProduct === $Failed,
      Return[multiquadraticOffDiagonalBlockFailure["ExactChannelDimensionMismatch"], Module]];
    residueTerm = If[Length[preparation["OneForms"]] === 0,
      ConstantArray[0, Append[preparation["Dimensions"], preparation["GradeCount"]]],
      Table[Together /@ Total[Table[
          residues[[letter, i, j]] oneFormChannels[[letter, mu]],
          {letter, Length[preparation["OneForms"]]}]],
        {i, preparation["Dimensions"][[1]]}, {j, preparation["Dimensions"][[2]]}]];
    Map[Together, derivative - epsilonImage leftProduct +
      epsilonImage rightProduct + epsilonImage residueTerm -
      inhomogeneityChannels[[mu]], {3}],
    {mu, 2}];
  <|"Status" -> If[multiquadraticOffDiagonalBlockZeroQ[residual],
      "ExactChannelResidualZero", "ExactChannelResidualNonzero"],
    "ResidualZero" -> multiquadraticOffDiagonalBlockZeroQ[residual],
    "EpsilonValue" -> epsilonImage, "ResidualChannels" -> residual|>
];

(* ---- ONE ROW ASSEMBLER OVER THE PROVIDER INTERFACE ------------------
   (2026-08-26, round-2 item 10; Codex review 4.1)

   There were three copies of the same PDE row: the screen's row
   assembler, the compiled-channel assembler, and
   multiquadraticOffDiagonalBlockSplitPointRows.  The equation is one equation; only
   the way its COEFFICIENTS are obtained differs.  So the coefficients
   become an interface --

     <|"Status" -> "MultiquadraticPointCoefficientsV1",
       "Point", "Prime", "EpsilonMod",
       "QuadraticRadicands", "OffDiagonalBasisTransformationDenominator",
       "OffDiagonalBasisTransformationDenominatorLogDerivatives", "RootLogDerivatives",
       "E", "C", "Inhomogeneity", "OneForms"|>

   -- and this ONE function turns any provider's answer into rows.  Three
   providers implement the interface: the compiled-channel provider (the
   historical route, now the fallback and the artifact oracle), the
   split-branch provider and the quotient-grade provider.

   multiquadraticOffDiagonalBlockSplitPointRows is deliberately NOT folded in: it
   builds the same rows by an independent route (sign-branch rows
   transformed back), and Codex 4.1 asks that it be retained "as an
   independent differential test".  It is exactly that, and the test that
   holds this function to it is the differential one. *)

multiquadraticOffDiagonalBlockPointCoefficientsValidQ[assembly_Association,
    coefficients_Association] := Module[
  {layoutQ, compiledOracleQ, dimensions, upper, lower, gradeCount,
   rootCount, oneFormCount, prime, modularValues, modularQ},
  layoutQ = multiquadraticOffDiagonalBlockAssemblyLayoutEvaluationValidQ[assembly];
  compiledOracleQ = ! layoutQ && multiquadraticOffDiagonalBlockCompiledValidQ[assembly];
  If[! layoutQ && ! compiledOracleQ, Return[False]];
  dimensions = assembly["Dimensions"];
  {upper, lower} = dimensions;
  gradeCount = assembly["GradeCount"];
  rootCount = assembly["RootCount"];
  oneFormCount = Length[assembly["OneForms"]];
  prime = Lookup[coefficients, "Prime", None];
  If[! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticOffDiagonalBlockWordPrimeLimit),
    Return[False]];
  modularValues = Lookup[coefficients,
    {"EpsilonMod", "QuadraticRadicands", "SquareRootGeneratorValues",
     "OffDiagonalBasisTransformationDenominator",
     "OffDiagonalBasisTransformationDenominatorLogDerivatives", "RootLogDerivatives", "E", "C", "Inhomogeneity",
     "OneForms"}, {}];
  modularQ = True;
  Scan[If[! IntegerQ[#1] || ! (0 <= #1 < prime), modularQ = False] &,
    modularValues, {-1}];
  TrueQ[
    Lookup[coefficients, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" && modularQ &&
    MatchQ[Lookup[coefficients, "Point", None], {_Integer, _Integer}] &&
    Length[coefficients["QuadraticRadicands"]] === rootCount &&
    Length[Lookup[coefficients, "SquareRootGeneratorValues", {}]] ===
      rootCount &&
    Length[coefficients["OffDiagonalBasisTransformationDenominatorLogDerivatives"]] === 2 &&
    If[rootCount === 0,
      Lookup[coefficients, "RootLogDerivatives", Missing["RootLogDerivatives"]]
        === {},
      Dimensions[coefficients["RootLogDerivatives"]] === {rootCount, 2}] &&
    Dimensions[Lookup[coefficients, "E", {}]] ===
      {2, upper, upper, gradeCount} &&
    Dimensions[Lookup[coefficients, "C", {}]] ===
      {2, lower, lower, gradeCount} &&
    Dimensions[Lookup[coefficients, "Inhomogeneity", {}]] ===
      {2, upper, lower, gradeCount} &&
    If[oneFormCount === 0,
      Lookup[coefficients, "OneForms", Missing["OneForms"]] === {},
      Dimensions[Lookup[coefficients, "OneForms", {}]] ===
        {oneFormCount, 2, gradeCount}] &&
    If[layoutQ,
      SameQ[Lookup[coefficients, "CoefficientData", None],
        assembly["CoefficientData"]],
      Lookup[coefficients, "Provider", None] === "CompiledChannel"]]
];

multiquadraticOffDiagonalBlockAssemblePointRows[assembly_Association,
    coefficients_Association] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["OffDiagonalBasisTransformationNumeratorSupport"], supportCount, unknownCount,
   offDiagonalBasisTransformationUnknownCount, oneFormCount, prime, epsilonMod, x, y,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   offDiagonalBasisTransformationDenominatorLogDerivatives, rootLogDerivatives, eValues, cValues, inhomogeneityValues,
   oneFormValues, monomialValues, basisValues, basisDerivatives, xInverse,
   yInverse, half, logarithmicDerivative, targetGrade, sourceGrade,
   productGrade, productFactor, mu, i, j, a, b, letter, monomial,
   productWeight, productGrades, productWeights, rowIndex, rowCount, rows,
   right, row, offDiagonalBasisTransformationCoefficientRow, residueRow, residueRowExpectedWidth},
  If[! multiquadraticOffDiagonalBlockPointCoefficientsValidQ[assembly, coefficients],
    Throw[multiquadraticOffDiagonalBlockFailure["InvalidPointCoefficients"],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  prime = coefficients["Prime"];
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  offDiagonalBasisTransformationUnknownCount = assembly["OffDiagonalBasisTransformationUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = coefficients["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroRegulatorImage"],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  {x, y} = coefficients["Point"];
  If[x === 0 || y === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroPointCoordinate",
      <|"Point" -> {x, y}|>], "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  deltaValues = coefficients["QuadraticRadicands"];
  If[MemberQ[deltaValues, 0],
    Throw[multiquadraticOffDiagonalBlockFailure["DegenerateRootImage",
      <|"Point" -> {x, y},
        "QuadraticRadicandValues" -> deltaValues|>],
      "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  denominatorValue = coefficients["OffDiagonalBasisTransformationDenominator"];
  If[denominatorValue === 0,
    Throw[multiquadraticOffDiagonalBlockFailure["ZeroOffDiagonalBasisTransformationDenominator",
      <|"Point" -> {x, y}|>], "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  deltaMaskFactors = Developer`ToPackedArray[
    multiquadraticOffDiagonalBlockMaskFactorMod[#1, deltaValues, prime] & /@
      Range[0, gradeCount - 1]];
  offDiagonalBasisTransformationDenominatorLogDerivatives = coefficients["OffDiagonalBasisTransformationDenominatorLogDerivatives"];
  rootLogDerivatives = coefficients["RootLogDerivatives"];
  eValues = coefficients["E"];
  cValues = coefficients["C"];
  inhomogeneityValues = coefficients["Inhomogeneity"];
  oneFormValues = coefficients["OneForms"];
  xInverse = PowerMod[x, -1, prime];
  yInverse = PowerMod[y, -1, prime];
  half = PowerMod[2, -1, prime];
  monomialValues = Developer`ToPackedArray[Table[
    Mod[PowerMod[x, support[[monomial, 1]], prime]
      PowerMod[y, support[[monomial, 2]], prime], prime],
    {monomial, supportCount}]];
  basisValues = Developer`ToPackedArray[Table[
    Mod[monomialValues[[monomial]] denominatorInverse, prime],
    {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  (* d_mu (x^p y^q / Q r_grade) / r_grade *)
  basisDerivatives = Developer`ToPackedArray[Table[
    logarithmicDerivative = Mod[
      If[mu === 1, support[[monomial, 1]] xInverse,
        support[[monomial, 2]] yInverse] - offDiagonalBasisTransformationDenominatorLogDerivatives[[mu]] +
      half Sum[If[BitGet[sourceGrade, a - 1] === 1,
        rootLogDerivatives[[a, mu]], 0], {a, assembly["RootCount"]}], prime];
    Mod[basisValues[[sourceGrade + 1, monomial]] logarithmicDerivative, prime],
    {mu, 2}, {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  productGrades = Developer`ToPackedArray[Table[BitXor[targetGrade, sourceGrade],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1}]];
  productWeights = Developer`ToPackedArray[Table[
    productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
    productFactor = deltaMaskFactors[[BitAnd[productGrade, sourceGrade] + 1]];
    Mod[Mod[epsilonMod basisValues[[sourceGrade + 1, monomial]], prime]
      productFactor, prime],
    {targetGrade, 0, gradeCount - 1}, {sourceGrade, 0, gradeCount - 1},
    {monomial, supportCount}]];
  rowCount = assembly["EquationsPerPoint"];
  rows = Table[ConstantArray[0, unknownCount], rowCount];
  right = ConstantArray[0, rowCount];
  Do[
    rowIndex = multiquadraticOffDiagonalBlockPointRowIndex[targetGrade, mu, i, j,
      upperDimension, lowerDimension];
    offDiagonalBasisTransformationCoefficientRow = Flatten[Table[
      productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
      productWeight = productWeights[[targetGrade + 1, sourceGrade + 1, monomial]];
      Mod[Mod[
          If[targetGrade === sourceGrade && a === i && b === j,
            basisDerivatives[[mu, sourceGrade + 1, monomial]], 0] +
          If[b === j, -productWeight eValues[[mu, i, a, productGrade + 1]], 0],
          prime] +
        If[a === i, productWeight cValues[[mu, b, j, productGrade + 1]], 0],
        prime],
      {a, upperDimension}, {b, lowerDimension},
      {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
    residueRow = Flatten[Table[
      If[a === i && b === j,
        Mod[epsilonMod oneFormValues[[letter, mu, targetGrade + 1]], prime], 0],
      {letter, oneFormCount}, {a, upperDimension}, {b, lowerDimension}]];
    If[Length[residueRow] =!= residueRowExpectedWidth,
      Throw[multiquadraticOffDiagonalBlockFailure["ResidueRowWidthMismatch",
        <|"Expected" -> residueRowExpectedWidth,
          "Observed" -> Length[residueRow]|>],
        "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
    row = Join[offDiagonalBasisTransformationCoefficientRow, residueRow];
    If[Length[row] =!= unknownCount,
      Throw[multiquadraticOffDiagonalBlockFailure["RowWidthMismatch",
        <|"Expected" -> unknownCount, "Observed" -> Length[row]|>],
        "MultiquadraticOffDiagonalBlockAssemblyFailure"]];
    rows[[rowIndex]] = Developer`ToPackedArray[row];
    right[[rowIndex]] = Mod[inhomogeneityValues[[mu, i, j, targetGrade + 1]], prime],
    {targetGrade, 0, gradeCount - 1}, {mu, 2}, {i, upperDimension},
    {j, lowerDimension}];
  multiquadraticOffDiagonalBlockPointResult[assembly, coefficients, rows, right,
    N[AbsoluteTime[] - startTime]]
], "MultiquadraticOffDiagonalBlockAssemblyFailure"];
multiquadraticOffDiagonalBlockAssemblePointRows[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidAssemblePointRowsArguments"];

End[];
