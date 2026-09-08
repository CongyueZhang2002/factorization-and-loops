BeginPackage["CodexCF300ModularQepsWitnessReconstruction`", {
  "CodexDirectRootChannelAssembler`",
  "CodexCF300ExactQepsLeftObstruction`"}];

EQMRReconstruct::usage =
  "EQMRReconstruct[assembly,eps,points,plan,binary] evaluates the pinned CF300 witness core modulo several primes and epsilon images, solves each fixed square image with the pinned CFFA4 FLINT binary, reconstructs 889 rational functions by CRT, and certifies held-out images.";

Begin["`Private`"];

ClearAll[eqmrFailure, eqmrModRational, eqmrReducePoints,
  eqmrNativeSolve, eqmrModularImage, eqmrTrimCoefficients,
  eqmrEvaluateCoefficients, eqmrReduceRationalPair,
  eqmrInterpolationQ, eqmrCachedInterpolationValidQ,
  eqmrInterpolateCoordinate,
  eqmrPrimeArtifact, eqmrRationalReconstruct, eqmrCRTRecover,
  eqmrLiftCoordinate, eqmrTryLiftArtifacts, eqmrFunctionMod,
  eqmrHeldOutPrimeCheck,
  eqmrPlanValidQ];

$eqmrExpectedFiniteFieldSourceSHA256 =
  "8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70";
$eqmrExpectedNativeBinarySHA256 =
  "e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b";
$eqmrExpectedAssemblyFingerprint =
  "32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7";

eqmrFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "CF300ModularQepsWitnessReconstructionFailure",
    "FailureReason" -> reason|>, data];

eqmrPlanValidQ[plan_Association] := TrueQ[
  Lookup[plan, "MatrixDimensions", None] === {960, 912} &&
  Lookup[plan, "CoefficientRank", None] === 888 &&
  Lookup[plan, "AugmentedRank", None] === 889 &&
  Length[Lookup[plan, "AugmentedPivotColumns", {}]] === 889 &&
  Length[Lookup[plan, "AugmentedIndependentEquationRows", {}]] === 889 &&
  CodexCF300ExactQepsLeftObstruction`EQWFingerprint[
    plan["AugmentedPivotColumns"]] ===
      Lookup[plan, "AugmentedPivotFingerprint", None] &&
  CodexCF300ExactQepsLeftObstruction`EQWFingerprint[
    plan["AugmentedIndependentEquationRows"]] ===
      Lookup[plan, "AugmentedIndependentRowFingerprint", None]];

eqmrPlanValidQ[___] := False;

eqmrModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

eqmrReducePoints[points_List, prime_Integer] := Module[{reduced},
  reduced = Map[eqmrModRational[#1, prime] &, points, {2}];
  If[! MatchQ[reduced, {{_Integer, _Integer} ..}] ||
      MemberQ[Flatten[reduced], $Failed] || ! DuplicateFreeQ[reduced],
    $Failed, reduced]
];

(* Exact copy of the package's source-pinned CFFA4V1/CFFA4X1 fixed-square
   wire protocol, kept external to the package.  Plan discovery is not part
   of this adapter. *)
eqmrNativeSolve[core_?MatrixQ, right_List, prime_Integer,
    threads_Integer, binary_String] := Module[
  {directory, input, output, stream, rows, columns, process, magic,
   header, values, solution, result = $Failed},
  If[! FileExistsQ[binary] ||
      FileHash[binary, "SHA256", "HexString"] =!=
        $eqmrExpectedNativeBinarySHA256 ||
      ! PrimeQ[prime] || !(3 < prime < 2^31) ||
      ! Between[threads, {1, 4}],
    Return[eqmrFailure["InvalidNativeFixedSquareArguments"]]];
  {rows, columns} = Dimensions[core];
  If[rows =!= columns || Length[right] =!= rows || rows =!= 889,
    Return[eqmrFailure["InvalidNativeFixedSquareShape", <|
      "CoreDimensions" -> {rows, columns},
      "RightLength" -> Length[right]|>]]];
  directory = CreateDirectory[];
  Internal`WithLocalSettings[
    Null,
    result = Catch[
      input = FileNameJoin[{directory, "core.bin"}];
      output = FileNameJoin[{directory, "solution.bin"}];
      stream = OpenWrite[input, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["CFFA4V1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {rows, columns, 1, prime},
        "UnsignedInteger64", ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[Normal[core]],
        "UnsignedInteger64", ByteOrdering -> -1];
      BinaryWrite[stream, right, "UnsignedInteger64",
        ByteOrdering -> -1];
      Close[stream]; stream = None;
      process = Quiet[Check[
        RunProcess[{binary, input, output, ToString[threads]}], $Failed]];
      If[! AssociationQ[process],
        Throw[eqmrFailure["NativeProcessDidNotReturnAssociation", <|
          "ProcessHead" -> ToString[Head[process], InputForm]|>],
          "CFFA4"]];
      If[Lookup[process, "ExitCode", Missing["Absent"]] =!= 0,
        Throw[eqmrFailure["NativeProcessNonzeroExit", <|
          "ExitCode" -> Lookup[process, "ExitCode", Missing["Absent"]],
          "StandardError" -> StringTake[
            ToString[Lookup[process, "StandardError", ""]],
            UpTo[4096]],
          "StandardOutput" -> StringTake[
            ToString[Lookup[process, "StandardOutput", ""]],
            UpTo[4096]]|>], "CFFA4"]];
      If[! FileExistsQ[output],
        Throw[eqmrFailure["NativeOutputMissing"], "CFFA4"]];
      stream = OpenRead[output, BinaryFormat -> True];
      magic = BinaryReadList[stream, "UnsignedInteger8", 8];
      header = BinaryReadList[stream, "UnsignedInteger64", 3,
        ByteOrdering -> -1];
      If[magic =!= ToCharacterCode["CFFA4X1\000"] ||
          header =!= {columns, 1, prime},
        Throw[eqmrFailure["NativeOutputHeaderInvalid", <|
          "ObservedMagic" -> magic, "ObservedHeader" -> header|>],
          "CFFA4"]];
      values = BinaryReadList[stream, "UnsignedInteger64",
        Times @@ Take[header, 2], ByteOrdering -> -1];
      Close[stream]; stream = None;
      If[Length[values] =!= columns,
        Throw[eqmrFailure["NativeOutputPayloadLengthInvalid", <|
          "Expected" -> columns, "Observed" -> Length[values]|>],
          "CFFA4"]];
      solution = Mod[values, prime];
      If[Mod[core.solution - right, prime] =!=
          ConstantArray[0, rows],
        Throw[eqmrFailure["NativeSolutionResidualFailed"], "CFFA4"]];
      <|"Status" -> "VerifiedCFFA4FixedSquareSolveV1",
        "Solution" -> solution, "ExitCode" -> 0,
        "StandardError" -> StringTake[
          ToString[Lookup[process, "StandardError", ""]], UpTo[4096]],
        "StandardOutput" -> StringTake[
          ToString[Lookup[process, "StandardOutput", ""]], UpTo[4096]]|>,
      "CFFA4"],
    If[Head[stream] === OutputStream || Head[stream] === InputStream,
      Quiet[Check[Close[stream], Null]]];
    If[DirectoryQ[directory],
      Quiet[Check[DeleteDirectory[directory, DeleteContents -> True],
        Null]]]
  ];
  If[AssociationQ[result], result,
    eqmrFailure["NativeFixedSquareUnknownFailure"]]
];

eqmrModularImage[assembly_Association, epsilonValue_, prime_Integer,
    points_List, plan_Association, binary_String, threads_Integer] := Module[
  {pointResidues, sample, matrix, right, rightColumn, augmented,
   selectedBlock, pivotRight, seconds, nativeRun, support, witness,
   leftResidual, rightResidual, rejectionReasons, primeStaticFailure},
  pointResidues = eqmrReducePoints[points, prime];
  If[pointResidues === $Failed,
    Return[eqmrFailure["PointReductionFailed", <|"Prime" -> prime|>]]];
  If[! MatchQ[epsilonValue, _Integer | _Rational] ||
      eqmrModRational[epsilonValue, prime] === $Failed,
    Return[eqmrFailure["InvalidEpsilonImage", <|
      "Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  If[With[{epsilonMod = eqmrModRational[epsilonValue, prime]},
      Mod[epsilonMod (2 epsilonMod - 1) (3 epsilonMod - 1)
        (3 epsilonMod - 2), prime] === 0],
    Return[eqmrFailure["RegulatorExceptionalEpsilonImage", <|
      "Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  {seconds, sample} = AbsoluteTiming[
    CodexDirectRootChannelAssembler`DRCAAssembleSample[
      assembly, epsilonValue, prime, "PointCount" -> 30,
      "MaximumAttempts" -> 30, "CandidatePoints" -> pointResidues,
      "RandomSeed" -> 2026082335, "BranchFlipMask" -> 0]];
  If[Lookup[sample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      Lookup[sample, "MatrixDimensions", None] =!= {960, 912} ||
      Lookup[sample, "AcceptedPoints", None] =!= pointResidues,
    rejectionReasons = Lookup[
      Lookup[sample, "RejectedPoints", {}], "FailureReason", {}];
    primeStaticFailure = rejectionReasons =!= {} &&
      AllTrue[rejectionReasons, MemberQ[{
        "ZeroPointCoordinate", "DegenerateRootImage",
        "ZeroGaugeDenominator", "DuplicatePointModuloPrime"}, #1] &];
    Return[eqmrFailure["ModularSampleFailed", <|
      "Prime" -> prime, "EpsilonValue" -> epsilonValue,
      "SampleStatus" -> Lookup[sample, "Status", None],
      "RejectedPointReasons" -> rejectionReasons,
      "PrimeStaticPointFailure" -> primeStaticFailure|>]]];
  matrix = SparseArray[sample["Matrix"]];
  right = sample["RightHandSide"];
  rightColumn = SparseArray[
    MapIndexed[{First[#2], 1} -> #1 &, right], {960, 1}];
  augmented = Join[matrix, rightColumn, 2];
  selectedBlock = augmented[[
    plan["AugmentedIndependentEquationRows"],
    plan["AugmentedPivotColumns"]]];
  pivotRight = Boole[#1 === 913] & /@
    plan["AugmentedPivotColumns"];
  nativeRun = eqmrNativeSolve[Transpose[selectedBlock], pivotRight,
    prime, threads, binary];
  If[Lookup[nativeRun, "Status", None] =!=
      "VerifiedCFFA4FixedSquareSolveV1",
    Return[eqmrFailure["NativeFixedSquareSolveFailed", <|
      "Prime" -> prime, "EpsilonValue" -> epsilonValue,
      "NativeSolveAttempted" -> True,
      "NativeDiagnostics" -> nativeRun|>]]];
  support = nativeRun["Solution"];
  witness = SparseArray[Thread[
    plan["AugmentedIndependentEquationRows"] -> support], 960];
  leftResidual = Mod[Transpose[matrix].witness, prime];
  rightResidual = Mod[right.witness, prime];
  If[leftResidual =!= ConstantArray[0, 912] || rightResidual =!= 1,
    Return[eqmrFailure["FullModularWitnessResidualFailed", <|
      "Prime" -> prime, "EpsilonValue" -> epsilonValue|>]]];
  <|"Status" -> "VerifiedCF300ModularWitnessImageV1",
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> eqmrModRational[epsilonValue, prime],
    "PointResidueFingerprint" ->
      CodexCF300ExactQepsLeftObstruction`EQWFingerprint[pointResidues],
    "SupportValues" -> support,
    "SupportFingerprint" ->
      CodexCF300ExactQepsLeftObstruction`EQWFingerprint[support],
    "SampleSeconds" -> seconds, "NativeBackend" -> "CFFA4-FLINT",
    "NativeSolveAttempted" -> True,
    "NativeExitCode" -> nativeRun["ExitCode"],
    "LeftResidualZero" -> True, "RightPairing" -> 1|>
];

eqmrTrimCoefficients[coefficients_List] := Module[{indices},
  indices = Select[Range[Length[coefficients]],
    coefficients[[#1]] =!= 0 &];
  If[indices === {}, {0}, Take[coefficients, Last[indices]]]
];

eqmrEvaluateCoefficients[coefficients_List, value_Integer,
    prime_Integer] := Fold[Mod[#1 value + #2, prime] &, 0,
  Reverse[coefficients]];

eqmrReduceRationalPair[numeratorInput_List, denominatorInput_List,
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
  numeratorCoefficients = eqmrTrimCoefficients[
    Mod[CoefficientList[numerator, z], prime]];
  denominatorCoefficients = eqmrTrimCoefficients[
    Mod[CoefficientList[denominator, z], prime]];
  normalization = PowerMod[Last[denominatorCoefficients], -1, prime];
  {Mod[normalization numeratorCoefficients, prime],
    Mod[normalization denominatorCoefficients, prime]}
];

eqmrInterpolationQ[pair_List, data_List, prime_Integer] :=
  AllTrue[data, Function[datum, Module[{numerator, denominator},
    numerator = eqmrEvaluateCoefficients[pair[[1]], datum[[1]], prime];
    denominator = eqmrEvaluateCoefficients[pair[[2]], datum[[1]], prime];
    denominator =!= 0 &&
      Mod[numerator - datum[[2]] denominator, prime] === 0]]];

eqmrCachedInterpolationValidQ[record_Association, data_List,
    prime_Integer] := Module[{pair, denominatorValues},
  If[Lookup[record, "Status", None] =!=
        "VerifiedModularRationalInterpolationV1" ||
      ! MatchQ[Lookup[record, "Numerator", $Failed], {_Integer ..}] ||
      ! MatchQ[Lookup[record, "Denominator", $Failed], {_Integer ..}],
    Return[False]];
  pair = {record["Numerator"], record["Denominator"]};
  denominatorValues = eqmrEvaluateCoefficients[pair[[2]], #1[[1]],
      prime] & /@ data;
  ! MemberQ[denominatorValues, 0] &&
    TrueQ[eqmrInterpolationQ[pair, data, prime]]
];

eqmrCachedInterpolationValidQ[___] := False;

eqmrInterpolateCoordinate[data_List, prime_Integer,
    maximumTotalDegree_Integer] := Module[
  {matrix, nullspace, vector, pair, degrees,
   denominatorValues, expectedNullity},
  If[Length[data] =!= 2 maximumTotalDegree + 1 ||
      ! MatchQ[data, {{_Integer, _Integer} ..}] ||
      ! DuplicateFreeQ[data[[All, 1]]],
    Return[eqmrFailure["RationalInterpolationDataInvalid", <|
      "KernelCallCount" -> 0|>]]];
  If[AllTrue[data, Last[#1] === 0 &],
    Return[<|"Status" -> "VerifiedModularRationalInterpolationV1",
      "Numerator" -> {0}, "Denominator" -> {1},
      "Degrees" -> {-Infinity, 0},
      "UniquenessPointRequirement" -> 1,
      "BasisPairReductionCount" -> 0,
      "KernelCallCount" -> 0|>]];
  (* One type-(D,D) kernel per coordinate/stage.  A genuine reduced pair
     N/Q of total degree <= D lies in this kernel even for a very
     asymmetric split.  Its polynomial multiples make nullity > 1
     expected, not an error.  Since deg(P Q - N R) <= 2D at every kernel
     vector (P,R), vanishing at 2D+1 distinct images makes it the zero
     polynomial; coprimality of N,Q then makes every kernel vector a
     common polynomial multiple.  Reduce one deterministic basis vector,
     validate it on all images, and require the observed nullity to equal
     the dimension of its polynomial-multiple subspace; equality proves
     that this is the entire kernel.  A generic spurious type-(D,D) pair
     is rejected because its reduced total degree exceeds D. *)
  matrix = Table[Join[
      Table[PowerMod[datum[[1]], power, prime],
        {power, 0, maximumTotalDegree}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime],
        prime], {power, 0, maximumTotalDegree}]],
    {datum, data}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[nullspace === {},
    Return[eqmrFailure["RationalInterpolationKernelEmpty", <|
      "KernelCallCount" -> 1|>]]];
  vector = First[nullspace];
  If[! AnyTrue[vector[[maximumTotalDegree + 2 ;;]], #1 =!= 0 &],
    Return[eqmrFailure["RationalInterpolationDenominatorZero", <|
      "ObservedNullity" -> Length[nullspace],
      "BasisPairReductionCount" -> 0,
      "KernelCallCount" -> 1|>]]];
  pair = Quiet[Check[eqmrReduceRationalPair[
    vector[[1 ;; maximumTotalDegree + 1]],
    vector[[maximumTotalDegree + 2 ;;]], prime], $Failed]];
  If[pair === $Failed,
    Return[eqmrFailure["RationalInterpolationReductionFailed", <|
      "ObservedNullity" -> Length[nullspace],
      "BasisPairReductionCount" -> 1,
      "KernelCallCount" -> 1|>]]];
  degrees = Length[#1] - 1 & /@ pair;
  If[Total[degrees] > maximumTotalDegree,
    Return[eqmrFailure["SpuriousTypeDDInterpolation", <|
      "ReducedDegrees" -> degrees,
      "BasisPairReductionCount" -> 1,
      "KernelCallCount" -> 1|>]]];
  expectedNullity = Min[maximumTotalDegree - degrees[[1]],
      maximumTotalDegree - degrees[[2]]] + 1;
  If[Length[nullspace] =!= expectedNullity,
    Return[eqmrFailure["RationalInterpolationNullityMismatch", <|
      "ReducedDegrees" -> degrees,
      "ObservedNullity" -> Length[nullspace],
      "ExpectedNullity" -> expectedNullity,
      "BasisPairReductionCount" -> 1,
      "KernelCallCount" -> 1|>]]];
  denominatorValues = eqmrEvaluateCoefficients[pair[[2]], #1[[1]],
      prime] & /@ data;
  If[MemberQ[denominatorValues, 0],
    Return[eqmrFailure["RationalInterpolationDenominatorVanished", <|
      "ZeroDenominatorImageCount" -> Count[denominatorValues, 0],
      "BasisPairReductionCount" -> 1,
      "KernelCallCount" -> 1|>]]];
  If[! eqmrInterpolationQ[pair, data, prime],
    Return[eqmrFailure["RationalInterpolationResidualFailed", <|
      "BasisPairReductionCount" -> 1,
      "KernelCallCount" -> 1|>]]];
  <|"Status" -> "VerifiedModularRationalInterpolationV1",
    "Numerator" -> pair[[1]], "Denominator" -> pair[[2]],
    "Degrees" -> degrees,
    "UniquenessPointRequirement" -> 2 maximumTotalDegree + 1,
    "KernelNullity" -> Length[nullspace],
    "ExpectedKernelNullity" -> expectedNullity,
    "KernelEqualsPolynomialMultipleSubspace" -> True,
    "BasisPairReductionCount" -> 1,
    "KernelCallCount" -> 1|>
];

eqmrPrimeArtifact[assembly_Association, epsilon_Symbol, points_List,
    plan_Association, binary_String, threads_Integer, prime_Integer,
    degreeLadder_List, epsilonCandidates_List,
    expectedDegrees_] := Module[
  {images = {}, failures = {}, candidateIndex = 0, degree,
   required, image, data, interpolations, degrees, seconds,
   pointResidues, triedEpsilonResidues = {}, epsilonValue, epsilonMod,
   nativeSolveAttempts = 0, degreeEvidence = {}, failedCoordinates,
   interpolationCoordinateAttempts = 0, interpolationKernelCalls = 0,
   interpolationBasisPairReductions = 0, failureReasonCounts,
   interpolationCache = <||>, cacheCandidateCount, cacheHits,
   cacheMisses, coordinateRecomputes,
   cacheRevalidationAttempts = 0, cacheRevalidationHits = 0,
   cacheRevalidationMisses = 0, cached, interpolation},
  seconds = AbsoluteTime[];
  pointResidues = eqmrReducePoints[points, prime];
  If[pointResidues === $Failed,
    Return[eqmrFailure["PrimeStaticPointReductionFailed", <|
      "Prime" -> prime, "NativeSolveAttemptCount" -> 0,
      "PrimeSeconds" -> N[AbsoluteTime[] - seconds]|>]]];
  Do[
      required = 2 degree + 1;
      While[Length[images] < required &&
          candidateIndex < Length[epsilonCandidates],
        candidateIndex++;
        epsilonValue = epsilonCandidates[[candidateIndex]];
        epsilonMod = If[MatchQ[epsilonValue, _Integer | _Rational],
          eqmrModRational[epsilonValue, prime], $Failed];
        If[epsilonMod === $Failed ||
            MemberQ[triedEpsilonResidues, epsilonMod],
          AppendTo[failures, eqmrFailure[
            If[epsilonMod === $Failed, "InvalidEpsilonCandidate",
              "DuplicateEpsilonResidue"], <|"Prime" -> prime,
              "EpsilonValue" -> epsilonValue,
              "NativeSolveAttempted" -> False|>]];
          Continue[]];
        AppendTo[triedEpsilonResidues, epsilonMod];
        If[Mod[epsilonMod (2 epsilonMod - 1) (3 epsilonMod - 1)
              (3 epsilonMod - 2), prime] === 0,
          AppendTo[failures, eqmrFailure[
            "RegulatorExceptionalEpsilonImage", <|"Prime" -> prime,
              "EpsilonValue" -> epsilonValue,
              "EpsilonMod" -> epsilonMod,
              "NativeSolveAttempted" -> False|>]];
          Continue[]];
        image = eqmrModularImage[assembly,
          epsilonValue, prime, points, plan,
          binary, threads];
        If[TrueQ[Lookup[image, "NativeSolveAttempted", False]],
          nativeSolveAttempts++];
        If[TrueQ[Lookup[image, "PrimeStaticPointFailure", False]],
          Return[eqmrFailure["PrimeStaticPointAssemblyFailed", <|
            "Prime" -> prime,
            "FirstFailure" -> image,
            "NativeSolveAttemptCount" -> nativeSolveAttempts,
            "PrimeSeconds" -> N[AbsoluteTime[] - seconds]|>]]];
        If[Lookup[image, "Status", None] ===
            "VerifiedCF300ModularWitnessImageV1" &&
            ! MemberQ[Lookup[images, "EpsilonMod", {}],
              image["EpsilonMod"]],
          AppendTo[images, image],
          AppendTo[failures, KeyDrop[image, "SupportValues"]]]];
      If[Length[images] < required, Continue[]];
      data[coordinate_Integer] := ({#1["EpsilonMod"],
          #1["SupportValues", coordinate]} &) /@ images;
      cacheCandidateCount = Length[interpolationCache];
      cacheHits = 0; cacheMisses = 0; coordinateRecomputes = 0;
      interpolations = Table[
        cached = Lookup[interpolationCache, coordinate, None];
        If[AssociationQ[cached],
          cacheRevalidationAttempts++;
          If[eqmrCachedInterpolationValidQ[cached, data[coordinate],
              prime],
            cacheHits++; cacheRevalidationHits++;
            Join[cached, <|
              "CacheRevalidatedAtDegree" -> degree,
              "KernelCallCount" -> 0,
              "BasisPairReductionCount" -> 0|>],
            cacheMisses++; cacheRevalidationMisses++;
            coordinateRecomputes++;
            interpolation = eqmrInterpolateCoordinate[
              data[coordinate], prime, degree];
            If[Lookup[interpolation, "Status", None] ===
                "VerifiedModularRationalInterpolationV1",
              AssociateTo[interpolationCache,
                coordinate -> interpolation],
              interpolationCache = KeyDrop[interpolationCache,
                coordinate]];
            interpolation],
          coordinateRecomputes++;
          interpolation = eqmrInterpolateCoordinate[
            data[coordinate], prime, degree];
          If[Lookup[interpolation, "Status", None] ===
              "VerifiedModularRationalInterpolationV1",
            AssociateTo[interpolationCache, coordinate -> interpolation]];
          interpolation],
        {coordinate, 889}];
      interpolationCoordinateAttempts += coordinateRecomputes;
      interpolationKernelCalls += Total[
        Lookup[interpolations, "KernelCallCount", 0]];
      interpolationBasisPairReductions += Total[
        Lookup[interpolations, "BasisPairReductionCount", 0]];
      failedCoordinates = Pick[Range[Length[interpolations]],
        Map[Lookup[#1, "Status", None] =!=
          "VerifiedModularRationalInterpolationV1" &,
          interpolations]];
      failureReasonCounts = Counts[DeleteCases[
        Lookup[interpolations, "FailureReason", None], None]];
      AppendTo[degreeEvidence, <|
        "DegreeCap" -> degree,
        "AcceptedImageCount" -> Length[images],
        "RequiredImageCount" -> required,
        "InterpolatedCoordinateCount" ->
          Length[interpolations] - Length[failedCoordinates],
        "FailedCoordinateCount" -> Length[failedCoordinates],
        "FailureReasonCounts" -> failureReasonCounts,
        "CoordinateInterpolationAttemptCount" ->
          coordinateRecomputes,
        "CacheCandidateCount" -> cacheCandidateCount,
        "CacheRevalidationPassCount" -> cacheHits,
        "CacheRevalidationFailureCount" -> cacheMisses,
        "CacheSizeAfterStage" -> Length[interpolationCache],
        "NullSpaceKernelCallCount" ->
          Total[Lookup[interpolations, "KernelCallCount", 0]],
        "BasisPairReductionCount" ->
          Total[Lookup[interpolations,
            "BasisPairReductionCount", 0]],
        "FailedCoordinateFingerprint" ->
          CodexCF300ExactQepsLeftObstruction`EQWFingerprint[
            failedCoordinates]|>];
      If[failedCoordinates === {},
        degrees = Lookup[interpolations, "Degrees", $Failed];
        If[expectedDegrees === Automatic || degrees === expectedDegrees,
          Return[<|"Status" ->
              "ReconstructedCF300ModularWitnessPrimeV1",
            "Prime" -> prime, "DegreeCap" -> degree,
            "DegreeProfile" -> degrees,
            "DegreeProfileFingerprint" ->
              CodexCF300ExactQepsLeftObstruction`EQWFingerprint[degrees],
            "ImageCount" -> Length[images],
            "ImageSummaries" -> (KeyDrop[#1, "SupportValues"] & /@ images),
            "InterpolationRecords" -> interpolations,
            "RejectedImageCount" -> Length[failures],
            "RejectedImages" -> failures,
            "NativeSolveAttemptCount" -> nativeSolveAttempts,
            "InterpolationCoordinateAttemptCount" ->
              interpolationCoordinateAttempts,
            "InterpolationKernelCallCount" ->
              interpolationKernelCalls,
            "InterpolationBasisPairReductionCount" ->
              interpolationBasisPairReductions,
            "CacheRevalidationAttemptCount" ->
              cacheRevalidationAttempts,
            "CacheRevalidationHitCount" ->
              cacheRevalidationHits,
            "CacheRevalidationMissCount" ->
              cacheRevalidationMisses,
            "DegreeEvidence" -> degreeEvidence,
            "PrimeSeconds" -> N[AbsoluteTime[] - seconds]|>],
          Return[eqmrFailure["PrimeDegreeProfileMismatch", <|
            "Prime" -> prime, "DegreeCap" -> degree,
            "ExpectedDegreeProfile" -> expectedDegrees,
            "ObservedDegreeProfile" -> degrees,
            "ExpectedDegreeProfileFingerprint" ->
              CodexCF300ExactQepsLeftObstruction`EQWFingerprint[
                expectedDegrees],
            "ObservedDegreeProfileFingerprint" ->
              CodexCF300ExactQepsLeftObstruction`EQWFingerprint[degrees],
            "AcceptedImageSummaries" ->
              (KeyDrop[#1, "SupportValues"] & /@ images),
            "DegreeEvidence" -> degreeEvidence,
            "NativeSolveAttemptCount" -> nativeSolveAttempts,
            "InterpolationCoordinateAttemptCount" ->
              interpolationCoordinateAttempts,
            "InterpolationKernelCallCount" ->
              interpolationKernelCalls,
            "InterpolationBasisPairReductionCount" ->
              interpolationBasisPairReductions,
            "CacheRevalidationAttemptCount" ->
              cacheRevalidationAttempts,
            "CacheRevalidationHitCount" ->
              cacheRevalidationHits,
            "CacheRevalidationMissCount" ->
              cacheRevalidationMisses,
            "PrimeSeconds" -> N[AbsoluteTime[] - seconds]|>]]]],
    {degree, degreeLadder}];
  eqmrFailure["PrimeInterpolationDegreeCapReached", <|"Prime" -> prime,
    "MaximumTotalDegreeCap" -> Last[degreeLadder],
    "MaximumRequiredImageCount" -> 2 Last[degreeLadder] + 1,
    "DegreeLadder" -> degreeLadder,
    "AcceptedImageCount" -> Length[images],
    "AcceptedImageSummaries" ->
      (KeyDrop[#1, "SupportValues"] & /@ images),
    "RejectedImageCount" -> Length[failures],
    "RejectedImages" -> failures,
    "DegreeEvidence" -> degreeEvidence,
    "DegreeBoundDerivedFromMatrix" -> False,
    "ResumeReady" -> False,
    "ResumeReason" ->
      "No cross-run modular-image checkpoint is trusted in this frozen pilot; the summaries and failed-coordinate fingerprints target a bounded higher-degree rerun.",
    "NativeSolveAttemptCount" -> nativeSolveAttempts,
    "InterpolationCoordinateAttemptCount" ->
      interpolationCoordinateAttempts,
    "InterpolationKernelCallCount" -> interpolationKernelCalls,
    "InterpolationBasisPairReductionCount" ->
      interpolationBasisPairReductions,
    "CacheRevalidationAttemptCount" -> cacheRevalidationAttempts,
    "CacheRevalidationHitCount" -> cacheRevalidationHits,
    "CacheRevalidationMissCount" -> cacheRevalidationMisses,
    "MaximumInterpolationKernelCallsPerPrime" ->
      889 Length[degreeLadder],
    "MaximumBasisPairReductionsPerPrime" ->
      889 Length[degreeLadder],
    "PrimeSeconds" -> N[AbsoluteTime[] - seconds]|>]
];

eqmrRationalReconstruct[residue_Integer, modulus_Integer] := Module[
  {bound, r0 = modulus, r1 = Mod[residue, modulus], t0 = 0,
   t1 = 1, quotient, nextR, nextT, numerator, denominator},
  If[modulus <= 1, Return[$Failed]];
  If[r1 === 0, Return[0]];
  bound = Floor[Sqrt[modulus/2]];
  While[Abs[r1] > bound && r1 =!= 0,
    quotient = Quotient[r0, r1];
    nextR = r0 - quotient r1;
    nextT = t0 - quotient t1;
    {r0, r1} = {r1, nextR}; {t0, t1} = {t1, nextT}];
  If[r1 === 0 || t1 === 0, Return[$Failed]];
  numerator = r1; denominator = t1;
  If[denominator < 0,
    numerator = -numerator; denominator = -denominator];
  If[Abs[numerator] > bound || denominator > bound ||
      ! CoprimeQ[numerator, denominator] ||
      Mod[denominator residue - numerator, modulus] =!= 0,
    $Failed, numerator/denominator]
];

eqmrCRTRecover[residues_List, primes_List] := Module[{combined, modulus},
  If[residues === {} || Length[residues] =!= Length[primes],
    Return[$Failed]];
  combined = ChineseRemainder[MapThread[Mod, {residues, primes}], primes];
  modulus = Times @@ primes;
  eqmrRationalReconstruct[combined, modulus]
];

eqmrLiftCoordinate[artifacts_List, coordinate_Integer, primes_List,
    epsilon_Symbol] := Module[
  {records, degrees, numerator, denominator, value, imagesExact},
  records = Table[artifacts[[primeIndex,
    "InterpolationRecords", coordinate]],
    {primeIndex, Length[artifacts]}];
  degrees = Lookup[records, "Degrees", $Failed];
  If[Length[DeleteDuplicates[degrees]] =!= 1, Return[$Failed]];
  numerator = Table[eqmrCRTRecover[
    Table[records[[primeIndex, "Numerator", coefficient]],
      {primeIndex, Length[records]}], primes],
    {coefficient, Length[First[records]["Numerator"]]}];
  denominator = Table[eqmrCRTRecover[
    Table[records[[primeIndex, "Denominator", coefficient]],
      {primeIndex, Length[records]}], primes],
    {coefficient, Length[First[records]["Denominator"]]}];
  If[! FreeQ[{numerator, denominator}, $Failed], Return[$Failed]];
  imagesExact = And @@ Flatten[Table[
    eqmrModRational[numerator[[coefficient]], primes[[primeIndex]]] ===
      records[[primeIndex, "Numerator", coefficient]],
    {primeIndex, Length[primes]},
    {coefficient, Length[numerator]}]] &&
    And @@ Flatten[Table[
      eqmrModRational[denominator[[coefficient]],
        primes[[primeIndex]]] ===
        records[[primeIndex, "Denominator", coefficient]],
      {primeIndex, Length[primes]},
      {coefficient, Length[denominator]}]];
  If[! TrueQ[imagesExact], Return[$Failed]];
  value = Cancel[Together[
    FromDigits[Reverse[numerator], epsilon]/
      FromDigits[Reverse[denominator], epsilon]]];
  <|"Value" -> value, "Degrees" -> First[degrees],
    "NumeratorCoefficients" -> numerator,
    "DenominatorCoefficients" -> denominator,
    "TrainingPrimeImagesExact" -> True|>
];

eqmrTryLiftArtifacts[artifacts_List, epsilon_Symbol] := Module[
  {primes, fullRecords, prefixRecords, functions, prefixFunctions,
   modulus, heights, maximumHeight, reconstructionBound},
  If[Length[artifacts] < 4,
    Return[eqmrFailure["TooFewTrainingArtifactsForLift"]]];
  primes = Lookup[artifacts, "Prime", $Failed];
  fullRecords = Table[eqmrLiftCoordinate[artifacts, coordinate,
    primes, epsilon], {coordinate, 889}];
  If[MemberQ[fullRecords, $Failed],
    Return[eqmrFailure["CRTSupportLiftNeedsMorePrimes", <|
      "TrainingPrimeCount" -> Length[artifacts]|>]]];
  prefixRecords = Table[eqmrLiftCoordinate[Most[artifacts], coordinate,
    Most[primes], epsilon], {coordinate, 889}];
  If[MemberQ[prefixRecords, $Failed],
    Return[eqmrFailure["PrefixCRTSupportLiftNeedsMorePrimes", <|
      "TrainingPrimeCount" -> Length[artifacts]|>]]];
  functions = CodexCF300ExactQepsLeftObstruction`EQWCanonicalQeps[
      #1, epsilon] & /@ Lookup[fullRecords, "Value"];
  prefixFunctions = CodexCF300ExactQepsLeftObstruction`EQWCanonicalQeps[
      #1, epsilon] & /@
    Lookup[prefixRecords, "Value"];
  If[functions =!= prefixFunctions,
    Return[eqmrFailure["PrefixReconstructionNotStable", <|
      "TrainingPrimeCount" -> Length[artifacts]|>]]];
  modulus = Times @@ primes;
  heights = Flatten[Table[
    {Abs[Numerator[coefficient]], Denominator[coefficient]},
    {record, fullRecords},
    {coefficient, Join[record["NumeratorCoefficients"],
      record["DenominatorCoefficients"]]}]];
  maximumHeight = If[heights === {}, 0, Max[heights]];
  reconstructionBound = Floor[Sqrt[modulus/2]];
  If[maximumHeight > reconstructionBound,
    Return[eqmrFailure["RecoveredPairOutsideRationalReconstructionBound",
      <|"CRTModulus" -> modulus,
        "MaximumRecoveredCoefficientHeight" -> maximumHeight,
        "RationalReconstructionBound" -> reconstructionBound|>]]];
  <|"Status" -> "StableCF300QepsSupportLiftV1",
    "TrainingPrimes" -> primes,
    "FullLiftRecords" -> fullRecords,
    "ReconstructedSupportFunctions" -> functions,
    "CRTModulus" -> modulus,
    "MaximumRecoveredCoefficientHeight" -> maximumHeight,
    "RationalReconstructionBound" -> reconstructionBound,
    "RationalReconstructionBoundSatisfied" -> True,
    "PrefixReconstructionStable" -> True,
    "APrioriCoefficientHeightBoundCertified" -> False,
    "UniquenessQualification" ->
      "No independent a-priori height bound is claimed; qualification uses stable prefix reconstruction, held-out prime images, and terminal exact cleared identities."|>
];

eqmrFunctionMod[value_, epsilon_Symbol, epsilonValue_,
    prime_Integer] := eqmrModRational[
  Together[value /. epsilon -> epsilonValue], prime];

eqmrHeldOutPrimeCheck[assembly_Association, epsilon_Symbol,
    points_List, plan_Association, binary_String, threads_Integer,
    prime_Integer, epsilonValues_List, trainingEpsilonValues_List,
    functions_List] := Module[
  {records, image, predicted, epsilonValue, nativeSolveAttempts = 0,
   epsilonResidues, trainingEpsilonResidues},
  epsilonResidues = eqmrModRational[#1, prime] & /@ epsilonValues;
  trainingEpsilonResidues =
    eqmrModRational[#1, prime] & /@ trainingEpsilonValues;
  If[MemberQ[epsilonResidues, $Failed] ||
      ! DuplicateFreeQ[epsilonResidues],
    Return[eqmrFailure["HeldOutEpsilonResiduesInvalid", <|
      "Prime" -> prime, "EpsilonValues" -> epsilonValues,
      "EpsilonResidues" -> epsilonResidues,
      "NativeSolveAttemptCount" -> 0|>]]];
  If[MemberQ[trainingEpsilonResidues, $Failed] ||
      Intersection[epsilonResidues, trainingEpsilonResidues] =!= {},
    Return[eqmrFailure["HeldOutTrainingEpsilonResidueOverlap", <|
      "Prime" -> prime, "HeldOutEpsilonValues" -> epsilonValues,
      "HeldOutEpsilonResidues" -> epsilonResidues,
      "NativeSolveAttemptCount" -> 0|>]]];
  If[AnyTrue[epsilonResidues, Function[epsilonMod,
      Mod[epsilonMod (2 epsilonMod - 1) (3 epsilonMod - 1)
        (3 epsilonMod - 2), prime] === 0]],
    Return[eqmrFailure["HeldOutExceptionalEpsilonResidue", <|
      "Prime" -> prime, "EpsilonValues" -> epsilonValues,
      "EpsilonResidues" -> epsilonResidues,
      "NativeSolveAttemptCount" -> 0|>]]];
  records = Table[
    epsilonValue = epsilonValues[[epsilonIndex]];
    image = eqmrModularImage[assembly, epsilonValue, prime, points,
      plan, binary, threads];
    If[TrueQ[Lookup[image, "NativeSolveAttempted", False]],
      nativeSolveAttempts++];
    If[Lookup[image, "Status", None] =!=
        "VerifiedCF300ModularWitnessImageV1",
      Return[eqmrFailure["HeldOutModularImageFailed", <|
        "Prime" -> prime, "EpsilonValue" -> epsilonValue,
        "NativeSolveAttemptCount" -> nativeSolveAttempts|>]]];
    predicted = eqmrFunctionMod[#1, epsilon, epsilonValue, prime] & /@
      functions;
    If[MemberQ[predicted, $Failed] ||
        predicted =!= image["SupportValues"],
      Return[eqmrFailure["HeldOutPredictionMismatch", <|
        "Prime" -> prime, "EpsilonValue" -> epsilonValue,
        "NativeSolveAttemptCount" -> nativeSolveAttempts|>]]];
    <|"EpsilonValue" -> epsilonValue,
      "EpsilonMod" -> image["EpsilonMod"],
      "PredictedSupportExact" -> True,
      "SupportFingerprint" -> image["SupportFingerprint"]|>,
    {epsilonIndex, Length[epsilonValues]}];
  <|"Status" -> "HeldOutCF300WitnessPrimePassedV1",
    "Prime" -> prime, "ImageRecords" -> records,
    "HeldOutEpsilonResidues" -> epsilonResidues,
    "TrainingEpsilonResidueDisjoint" -> True,
    "NativeSolveAttemptCount" -> nativeSolveAttempts|>
];

Options[EQMRReconstruct] = {
  "PrimeCandidates" -> {10007, 10039, 1000003, 1000033, 1000037,
    1000039, 1000081, 1000099, 1000117, 1000121, 1000133,
    1000151, 1000159, 1000171, 1000183, 1000187, 1000193,
    1000199},
  "MinimumTrainingPrimeCount" -> 4,
  "MaximumTrainingPrimeCount" -> 12,
  "HeldOutPrimeCount" -> 2,
  "DegreeLadder" -> {8, 16, 24, 32, 48, 64, 80},
  "EpsilonCandidates" -> Join[{1/21, 1/11}, Range[2, 160]],
  "HeldOutEpsilonValues" -> {163, 167, 173, 179, 181, 191, 193},
  "NativeThreads" -> 4,
  "FiniteFieldSourceFile" -> Automatic
};

EQMRReconstruct[assembly_Association, epsilon_Symbol, points_List,
    plan_Association, binary_String, OptionsPattern[]] := Module[
  {primeCandidates, heldOutPrimeCount,
   minimumTrainingPrimeCount, maximumTrainingPrimeCount,
   degreeLadder, epsilonCandidates, heldOutEpsilonValues, threads,
   finiteFieldSource, trainingArtifacts = {}, rejectedPrimes = {},
   rejectedTrainingPrimes = {}, rejectedHeldOutPrimes = {},
   provisionalArtifacts = {}, expectedDegrees = Automatic,
   consensusProfileFingerprint = None, profileGroups,
   consensusGroups, consensusGroup, minorityArtifacts,
   primeIndex = 0, artifact,
   trainingPrimes, fullLiftRecords, functions, modulus, maximumHeight,
   reconstructionBound, liftAttempt = $Failed,
   heldOutRecords = {}, heldOut,
   trainingSeconds, liftSeconds, heldOutSeconds,
   trainingNativeSolveAttempts, heldOutNativeSolveAttempts,
   trainingInterpolationCoordinateAttempts,
   trainingInterpolationKernelCalls,
   trainingInterpolationBasisPairReductions,
   trainingCacheRevalidationAttempts, trainingCacheRevalidationHits,
   trainingCacheRevalidationMisses,
   hardBounds},
  primeCandidates = OptionValue["PrimeCandidates"];
  minimumTrainingPrimeCount = OptionValue["MinimumTrainingPrimeCount"];
  maximumTrainingPrimeCount = OptionValue["MaximumTrainingPrimeCount"];
  heldOutPrimeCount = OptionValue["HeldOutPrimeCount"];
  degreeLadder = OptionValue["DegreeLadder"];
  epsilonCandidates = OptionValue["EpsilonCandidates"];
  heldOutEpsilonValues = OptionValue["HeldOutEpsilonValues"];
  threads = OptionValue["NativeThreads"];
  finiteFieldSource = Replace[OptionValue["FiniteFieldSourceFile"],
    Automatic :> FileNameJoin[{DirectoryName[DirectoryName[
      DirectoryName[DirectoryName[DirectoryName[
        assembly["PrototypeSourceFile"]]]]]], "FeynFacet", "Private",
      "FiniteFieldStripSolve.wl"}]];
  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly] || assembly["AssemblyFingerprint"] =!=
        $eqmrExpectedAssemblyFingerprint || ! eqmrPlanValidQ[plan] ||
      ! MatchQ[points, {{_Integer | _Rational,
          _Integer | _Rational} ..}] || Length[points] =!= 30 ||
      ! FileExistsQ[binary] ||
      FileHash[binary, "SHA256", "HexString"] =!=
        $eqmrExpectedNativeBinarySHA256 ||
      ! FileExistsQ[finiteFieldSource] ||
      FileHash[finiteFieldSource, "SHA256", "HexString"] =!=
        $eqmrExpectedFiniteFieldSourceSHA256 ||
      ! VectorQ[primeCandidates, PrimeQ] ||
      ! DuplicateFreeQ[primeCandidates] ||
      ! AllTrue[primeCandidates, 3 < #1 < 2^31 &] ||
      ! IntegerQ[minimumTrainingPrimeCount] ||
      minimumTrainingPrimeCount < 4 ||
      ! IntegerQ[maximumTrainingPrimeCount] ||
      maximumTrainingPrimeCount < minimumTrainingPrimeCount ||
      ! IntegerQ[heldOutPrimeCount] || heldOutPrimeCount < 2 ||
      maximumTrainingPrimeCount + heldOutPrimeCount >
        Length[primeCandidates] ||
      ! MatchQ[degreeLadder, {_Integer ..}] ||
      ! OrderedQ[degreeLadder] || ! DuplicateFreeQ[degreeLadder] ||
      Min[degreeLadder] < 1 ||
      ! MatchQ[epsilonCandidates, {(_Integer | _Rational) ..}] ||
      ! DuplicateFreeQ[epsilonCandidates] ||
      ! MatchQ[heldOutEpsilonValues,
        {(_Integer | _Rational) ..}] ||
      ! DuplicateFreeQ[heldOutEpsilonValues] ||
      Intersection[epsilonCandidates, heldOutEpsilonValues] =!= {} ||
      ! Between[threads, {1, 4}],
    Return[eqmrFailure["InvalidReconstructionArguments"]]];
  hardBounds = <|
    "MaximumTotalEpsilonDegree" -> 80,
    "MaximumPrimeCandidates" -> 18,
    "MaximumEpsilonCandidatesPerTrainingPrime" -> 161,
    "MaximumHeldOutEpsilonValuesPerPrime" -> 7,
    "MaximumTrainingNativeSolveAttempts" -> 2898,
    "MaximumHeldOutNativeSolveAttempts" -> 126,
    "MaximumTotalNativeSolveAttempts" -> 3024,
    "MaximumTrainingPrimesExamined" -> 16,
    "MaximumInterpolationStagesPerPrime" -> 7,
    "MaximumInterpolationCoordinateAttemptsPerPrime" -> 6223,
    "MaximumInterpolationKernelCallsPerPrime" -> 6223,
    "MaximumBasisPairReductionsPerPrime" -> 6223,
    "MaximumCacheRevalidationsPerPrime" -> 5334,
    "MaximumTrainingInterpolationKernelCalls" -> 99568,
    "MaximumTrainingBasisPairReductions" -> 99568,
    "MaximumTrainingCacheRevalidations" -> 85344|>;
  If[minimumTrainingPrimeCount =!= 4 ||
      maximumTrainingPrimeCount =!= 12 || heldOutPrimeCount =!= 2 ||
      degreeLadder =!= {8, 16, 24, 32, 48, 64, 80} ||
      Length[epsilonCandidates] > 161 ||
      heldOutEpsilonValues =!= {163, 167, 173, 179, 181, 191, 193} ||
      Length[primeCandidates] > 18,
    Return[eqmrFailure["ReconstructionScheduleNotHardBounded", <|
      "HardBounds" -> hardBounds|>]]];

  {trainingSeconds, Null} = AbsoluteTiming[
    While[Length[trainingArtifacts] < maximumTrainingPrimeCount &&
        primeIndex < Length[primeCandidates] - heldOutPrimeCount,
      primeIndex++;
      artifact = eqmrPrimeArtifact[assembly, epsilon, points, plan,
        binary, threads, primeCandidates[[primeIndex]], degreeLadder,
        epsilonCandidates, expectedDegrees];
      If[Lookup[artifact, "Status", None] ===
          "ReconstructedCF300ModularWitnessPrimeV1",
        If[expectedDegrees === Automatic,
          AppendTo[provisionalArtifacts, artifact];
          profileGroups = GatherBy[provisionalArtifacts,
            Lookup[#1, "DegreeProfileFingerprint", None] &];
          consensusGroups = Select[profileGroups, Length[#1] >= 2 &];
          If[consensusGroups =!= {},
            consensusGroup = First[SortBy[consensusGroups,
              {-Length[#1], First[#1]["DegreeProfileFingerprint"]} &]];
            consensusProfileFingerprint =
              First[consensusGroup]["DegreeProfileFingerprint"];
            expectedDegrees = First[consensusGroup]["DegreeProfile"];
            trainingArtifacts = consensusGroup;
            minorityArtifacts = Select[provisionalArtifacts,
              Lookup[#1, "DegreeProfileFingerprint", None] =!=
                consensusProfileFingerprint &];
            rejectedTrainingPrimes = Join[rejectedTrainingPrimes,
              (Join[KeyDrop[#1, "InterpolationRecords"], <|
                "Status" -> "ProvisionalDegreeProfileMinorityRejected",
                "FailureReason" ->
                  "ProvisionalDegreeProfileMinority"|>] & /@
                minorityArtifacts)];
            rejectedPrimes = Join[rejectedPrimes,
              Take[rejectedTrainingPrimes, -Length[minorityArtifacts]]],
            If[Length[provisionalArtifacts] >= 3,
              Return[eqmrFailure[
                "ProvisionalDegreeProfileConsensusFailed", <|
                  "ConsensusPolicy" -> "TwoMatchingProfilesWithinThreeQualifiedPrimes",
                  "ProvisionalPrimeSummaries" ->
                    (KeyDrop[#1, "InterpolationRecords"] & /@
                      provisionalArtifacts),
                  "FurtherPrimesSkipped" -> True|>]]]],
          AppendTo[trainingArtifacts, artifact]];
        If[Length[trainingArtifacts] >= minimumTrainingPrimeCount,
          liftAttempt = eqmrTryLiftArtifacts[trainingArtifacts, epsilon];
          If[Lookup[liftAttempt, "Status", None] ===
              "StableCF300QepsSupportLiftV1", Break[]]],
        If[provisionalArtifacts === {} &&
            Lookup[artifact, "FailureReason", None] ===
              "PrimeInterpolationDegreeCapReached" &&
            Lookup[artifact, "AcceptedImageCount", 0] ===
              2 Last[degreeLadder] + 1,
          Return[eqmrFailure[
            "ExploratoryDegreeCapReachedAtFirstQualifiedPrime", <|
              "DegreeCapEvidence" -> artifact,
              "MaximumTotalDegreeCap" -> Last[degreeLadder],
              "DegreeBoundDerivedFromMatrix" -> False,
              "FurtherTrainingPrimesSkipped" -> True,
              "NextAction" ->
                "Inspect failed-coordinate fingerprints, extend the bounded epsilon candidate schedule and degree ladder, then rerun; degree 80 is an exploratory cap, not a mathematical bound."|>]]];
        AppendTo[rejectedTrainingPrimes, artifact];
        AppendTo[rejectedPrimes, artifact]]]];
  If[Lookup[liftAttempt, "Status", None] =!=
      "StableCF300QepsSupportLiftV1",
    Return[eqmrFailure["AdaptiveTrainingPrimeLimitReached", <|
      "AcceptedTrainingPrimeCount" -> Length[trainingArtifacts],
      "MinimumTrainingPrimeCount" -> minimumTrainingPrimeCount,
      "MaximumTrainingPrimeCount" -> maximumTrainingPrimeCount,
      "ProvisionalDegreeProfileCount" ->
        Length[provisionalArtifacts],
      "ConsensusProfileFingerprint" ->
        consensusProfileFingerprint,
      "LastLiftAttempt" -> If[AssociationQ[liftAttempt],
        KeyDrop[liftAttempt, {"FullLiftRecords",
          "ReconstructedSupportFunctions"}], liftAttempt],
      "RejectedPrimes" -> rejectedPrimes|>]]];
  {liftSeconds, Null} = AbsoluteTiming[
    trainingPrimes = liftAttempt["TrainingPrimes"];
    fullLiftRecords = liftAttempt["FullLiftRecords"];
    functions = liftAttempt["ReconstructedSupportFunctions"];
    modulus = liftAttempt["CRTModulus"];
    maximumHeight = liftAttempt["MaximumRecoveredCoefficientHeight"];
    reconstructionBound = liftAttempt["RationalReconstructionBound"]];

  {heldOutSeconds, Null} = AbsoluteTiming[
    While[Length[heldOutRecords] < heldOutPrimeCount &&
        primeIndex < Length[primeCandidates],
      primeIndex++;
      heldOut = eqmrHeldOutPrimeCheck[assembly, epsilon, points, plan,
        binary, threads, primeCandidates[[primeIndex]],
        heldOutEpsilonValues, epsilonCandidates, functions];
      If[AssociationQ[heldOut] && Lookup[heldOut, "Status", None] ===
          "HeldOutCF300WitnessPrimePassedV1",
        AppendTo[heldOutRecords, heldOut],
        AppendTo[rejectedHeldOutPrimes, If[AssociationQ[heldOut],
          heldOut, <|"Status" -> "HeldOutPrimeRejected",
            "Prime" -> primeCandidates[[primeIndex]],
            "NativeSolveAttemptCount" -> 0|>]];
        AppendTo[rejectedPrimes, Last[rejectedHeldOutPrimes]]]]];
  If[Length[heldOutRecords] < heldOutPrimeCount,
    Return[eqmrFailure["InsufficientHeldOutPrimeCertificates", <|
      "HeldOutPrimeCount" -> Length[heldOutRecords]|>]]];

  functions = CodexCF300ExactQepsLeftObstruction`EQWCanonicalQeps[
      #1, epsilon] & /@ functions;
  trainingNativeSolveAttempts = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "NativeSolveAttemptCount", 0]];
  heldOutNativeSolveAttempts = Total[Lookup[
    Join[heldOutRecords, rejectedHeldOutPrimes],
    "NativeSolveAttemptCount", 0]];
  trainingInterpolationCoordinateAttempts = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "InterpolationCoordinateAttemptCount", 0]];
  trainingInterpolationKernelCalls = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "InterpolationKernelCallCount", 0]];
  trainingInterpolationBasisPairReductions = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "InterpolationBasisPairReductionCount", 0]];
  trainingCacheRevalidationAttempts = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "CacheRevalidationAttemptCount", 0]];
  trainingCacheRevalidationHits = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "CacheRevalidationHitCount", 0]];
  trainingCacheRevalidationMisses = Total[Lookup[
    Join[trainingArtifacts, rejectedTrainingPrimes],
    "CacheRevalidationMissCount", 0]];
  If[trainingNativeSolveAttempts >
        hardBounds["MaximumTrainingNativeSolveAttempts"] ||
      heldOutNativeSolveAttempts >
        hardBounds["MaximumHeldOutNativeSolveAttempts"] ||
      trainingInterpolationKernelCalls >
        hardBounds["MaximumTrainingInterpolationKernelCalls"] ||
      trainingInterpolationBasisPairReductions >
        hardBounds["MaximumTrainingBasisPairReductions"] ||
      trainingCacheRevalidationAttempts >
        hardBounds["MaximumTrainingCacheRevalidations"],
    Return[eqmrFailure["RuntimeSolveCountBoundExceeded", <|
      "TrainingNativeSolveAttempts" -> trainingNativeSolveAttempts,
      "HeldOutNativeSolveAttempts" -> heldOutNativeSolveAttempts,
      "TrainingInterpolationCoordinateAttempts" ->
        trainingInterpolationCoordinateAttempts,
      "TrainingInterpolationKernelCalls" ->
        trainingInterpolationKernelCalls,
      "TrainingInterpolationBasisPairReductions" ->
        trainingInterpolationBasisPairReductions,
      "TrainingCacheRevalidationAttempts" ->
        trainingCacheRevalidationAttempts,
      "HardBounds" -> hardBounds|>]]];
  <|"Status" -> "ReconstructedCF300ExactQepsWitnessSupportV1",
    "Field" -> "Q(eps)",
    "PinnedPlanFingerprint" ->
      CodexCF300ExactQepsLeftObstruction`EQWFingerprint[plan],
    "ReconstructedSupportFunctions" -> functions,
    "SupportFunctionCount" -> Length[functions],
    "SupportFunctionFingerprint" ->
      CodexCF300ExactQepsLeftObstruction`EQWFingerprint[functions],
    "DegreeProfile" -> expectedDegrees,
    "DegreeProfileFingerprint" ->
      CodexCF300ExactQepsLeftObstruction`EQWFingerprint[expectedDegrees],
    "DegreeProfileStableAcrossTrainingPrimes" -> True,
    "DegreeProfileConsensusPolicy" ->
      "TwoMatchingProfilesWithinThreeQualifiedPrimes",
    "DegreeProfileConsensusFingerprint" ->
      consensusProfileFingerprint,
    "DegreeProfileConsensusQualifiedPrimeCount" ->
      Length[provisionalArtifacts],
    "TrainingPrimes" -> trainingPrimes,
    "TrainingPrimeSummaries" -> (KeyDrop[#1,
      "InterpolationRecords"] & /@ trainingArtifacts),
    "TrainingPrimeCount" -> Length[trainingPrimes],
    "CRTModulus" -> modulus,
    "MaximumRecoveredCoefficientHeight" -> maximumHeight,
    "RationalReconstructionBound" -> reconstructionBound,
    "RationalReconstructionBoundSatisfied" -> True,
    "APrioriCoefficientHeightBoundCertified" -> False,
    "UniquenessQualification" ->
      liftAttempt["UniquenessQualification"],
    "PrefixReconstructionStable" -> True,
    "HeldOutPrimeImagesExact" -> True,
    "HeldOutPrimeCertificates" -> heldOutRecords,
    "RejectedPrimeRecords" -> rejectedPrimes,
    "Backend" -> "SourcePinnedCFFA4FLINTFixedSquare",
    "NativeBinarySHA256" -> $eqmrExpectedNativeBinarySHA256,
    "FiniteFieldStripSolveSHA256" ->
      $eqmrExpectedFiniteFieldSourceSHA256,
    "NativeThreads" -> threads,
    "AdaptiveTrainingPrimeBounds" -> <|
      "Minimum" -> minimumTrainingPrimeCount,
      "Maximum" -> maximumTrainingPrimeCount,
      "Used" -> Length[trainingPrimes]|>,
    "HardScheduleBounds" -> hardBounds,
    "ActualNativeSolveAttempts" -> <|
      "Training" -> trainingNativeSolveAttempts,
      "HeldOut" -> heldOutNativeSolveAttempts,
      "Total" -> trainingNativeSolveAttempts +
        heldOutNativeSolveAttempts|>,
    "ActualRationalInterpolationWork" -> <|
      "CoordinateAttempts" ->
        trainingInterpolationCoordinateAttempts,
      "NullSpaceKernelCalls" -> trainingInterpolationKernelCalls,
      "BasisPairReductions" ->
        trainingInterpolationBasisPairReductions,
      "CacheRevalidationAttempts" ->
        trainingCacheRevalidationAttempts,
      "CacheRevalidationHits" -> trainingCacheRevalidationHits,
      "CacheRevalidationMisses" -> trainingCacheRevalidationMisses,
      "ComplexityClass" ->
        "O(889 * number-of-degree-stages * training-primes)"|>,
    "PhaseTelemetrySeconds" -> <|
      "AdaptiveTrainingImagesInterpolationAndCRT" -> trainingSeconds,
      "FinalLiftExtraction" -> liftSeconds,
      "HeldOutPrimeValidation" -> heldOutSeconds|>|>
];

EQMRReconstruct[___] := eqmrFailure["InvalidReconstructionArguments"];

End[];
EndPackage[];
