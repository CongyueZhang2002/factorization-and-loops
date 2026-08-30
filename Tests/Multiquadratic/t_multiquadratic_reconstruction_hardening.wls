#!/usr/bin/env wolframscript
(* Round-B B2 acceptance: exceptional images are replaced, the accepted
   good-prime set grows adaptively, and the lifted generic vector is checked
   at disjoint fresh provider images.  This suite does not claim that the
   implementation updates CRT coordinates incrementally. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, layoutBuilder, directProvider, reconstruct, residualImage,
  assembleSample, discoverySolve, pilotRecord, wideScheduleQ, splitEntry} =
  mq /@ {"multiquadraticStripPrepare",
    "multiquadraticStripAssemblyLayout",
    "multiquadraticStripDirectProvider",
    "multiquadraticStripReconstructRegulator",
    "multiquadraticStripProviderResidualImage",
    "multiquadraticStripAssembleSample",
    "multiquadraticStripPlanDiscoverySolve",
    "multiquadraticStripPilotImageRecord",
    "multiquadraticStripWidePrimeScheduleQ",
    "multiquadraticStripSplitBranchEntry"};

Clear[bx, by, be];
badPrime = 2147483423;
primePool = {badPrime, 2147483399, 2147483587, 2147483579};
height = 10^12/badPrime;
delta = 1 + bx;
rootRecord = <|"Root" -> Sqrt[delta], "RootSquare" -> delta|>;
frame = <|"Name" -> "AdaptiveReconstructionRank1",
  "Kind" -> "TwoVariable", "CoefficientField" -> "Algebraic",
  "Variables" -> {bx, by}, "Subst" -> {bx -> bx, by -> by},
  "Roots" -> {rootRecord}|>;
zero11 = {{{0}}, {{0}}};
knownGauge = {{Together[height be Sqrt[delta]/((be - 1) (1 - by))]}};
forcing = Table[{{Together[D[knownGauge[[1, 1]], {bx, by}[[mu]]]]}},
  {mu, 2}];
record = <|"Family" -> "ADAPTIVE_RECONSTRUCTION", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {bx, by}, "Regulator" -> be,
  "Strip" -> {zero11, zero11, forcing}|>;

prepared = prepare[record, frame, "RootIndices" -> {1}, "OneForms" -> {},
  "GaugeDenominator" -> 1 - by, "Support" -> {{0, 0}},
  "CoefficientProvider" -> "SplitBranch"];
layout = layoutBuilder[prepared];
provider = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "CoefficientABIFingerprint" -> layout["CoefficientABIFingerprint"],
  "SourceFingerprint" -> prepared["ABIFingerprint"]];

result = reconstruct[prepared, layout, provider,
  "SamplePrimes" -> Take[primePool, 2], "PrimePool" -> primePool,
  "MinimumGoodPrimeCount" -> 2, "MaximumGoodPrimeCount" -> 3,
  "MaximumRejectedPrimeCount" -> 4,
  "ExactVerification" -> "ProviderPoints"];

regulatorImageCounts = Lookup[result, "PrimeRegulatorImageCounts", <||>];
liftHistory = Lookup[result, "LiftAttemptHistory", {}];

check["B2 adaptive reconstruction succeeds after adding good primes",
  Lookup[result, "Status", None] ===
      "ReconstructedRegulatorDependenceV1" &&
    Length[result["GoodPrimes"]] === 3 &&
    result["LiftAttemptCount"] >= 2];
check["B2 later primes start from the first accepted prime's consumed regulator count",
  result["LearnedRegulatorSampleCount"] === 7 &&
    Keys[regulatorImageCounts] === result["GoodPrimes"] &&
    First[Values[regulatorImageCounts]] >= 7 &&
    Rest[Values[regulatorImageCounts]] ===
      ConstantArray[7, Length[result["GoodPrimes"]] - 1]];
check["B2 a prime dividing source coefficients is replaced, not fatal",
  MemberQ[result["RejectedPrimes"], badPrime] &&
    FreeQ[result["GoodPrimes"], badPrime]];
check["B2 singular regulator images are replaced",
  AnyTrue[result["ExceptionalRegulatorImages"],
    Lookup[#1, "RegulatorValue", None] === 1 &] &&
    FreeQ[result["RegulatorValues"], 1]];
check["B2 the high rational coefficient is reconstructed exactly",
  TrueQ[Together[result["Gauge"][[1, 1]] - knownGauge[[1, 1]]] === 0]];
(* At two good primes the symmetric routine admits the small congruent alias
   -354482253/1212112003.  It is not a $Failed height reconstruction: the
   disjoint provider image rejects it, and the third prime resolves the true
   10^12/2147483423 coefficient. *)
check["B2 lift history retains the failed prefix and successful prefix",
  Length[liftHistory] === result["LiftAttemptCount"] &&
    Length[liftHistory] >= 2 &&
    liftHistory[[-2, "Status"]] ===
      "CandidateLiftRejectedByFreshProviderResidual" &&
    liftHistory[[-2, "UnresolvedCoefficientCount"]] === 0 &&
    liftHistory[[-2, "UnresolvedCoefficientLocations"]] === {} &&
    liftHistory[[-2, "PrimeCountEstimate", "Method"]] ===
      "FreshProviderRejectionV1" &&
    liftHistory[[-2, "PrimeCountEstimate", "Lower"]] === 3 &&
    liftHistory[[-2, "PrimeCountEstimate", "Likely"]] === 3 &&
    liftHistory[[-2, "PrimeCountEstimate", "Conservative"]] === 4 &&
    Last[liftHistory]["Status"] === "AdaptiveRegulatorLiftValidated"];
check["B2 exact coefficient heights recover the minimum prime prefix",
  result["CoefficientHeight"] >= Numerator[height] &&
    IntegerQ[result["CoefficientHeightBitLength"]] &&
    result["RationalReconstructionMinimumPrimeCount"] === 3 &&
    result["ActualMinimumPrimeCount"] === 3 &&
    result["ActualPrimeCount"] === Length[result["GoodPrimes"]] &&
    result["PrimeCountOvershoot"] === 0 &&
    result["ActualMinimumPrimeCountBasis"] ===
      "ExactSymmetricHeightBoundOverAcceptedPrimePrefixes"];
check["B2 fresh checks use two primes and three images per prime",
  result["FreshProviderPointwiseCheckCount"] === 6 &&
    Length[DeleteDuplicates[
      Lookup[result["FreshProviderPointwiseChecks"], "Prime"]]] === 2 &&
    TrueQ[result["FreshProviderValidationDisjointFromCRT"]]];
check["B2 every fresh provider residual vanishes",
  AllTrue[result["FreshProviderPointwiseChecks"],
    Lookup[#1, "Status", None] === "ProviderPointwiseResidualZero" &]];
check["B2 validation image keys are disjoint from training keys",
  Intersection[result["TrainingImageKeys"], Flatten[
      Lookup[result["FreshProviderPointwiseChecks"],
        "ValidationImageKeys", {}], 1]] === {}];

(* SplitBranch's native sparse evaluator and native row assembler both use
   FLINT nmod arithmetic and a 64-bit word protocol.  Its Automatic schedule
   therefore uses 61-bit reconstruction primes, while the fresh final replay
   deliberately remains on the disjoint historical 31-bit validation pool. *)
widePool = FeynFacet`Private`$multiquadraticStripWidePrimePool;
check["the native SplitBranch prime pool is a full valid 61-bit schedule",
  Length[widePool] === 32 && DuplicateFreeQ[widePool] &&
    AllTrue[widePool, PrimeQ[#1] && Mod[#1, 4] === 3 &&
      2^60 < #1 < 2^61 &]];
check["Automatic wide primes require a completely native split plan",
  TrueQ[wideScheduleQ[provider]] &&
    Internal`InheritedBlock[{
      FeynFacet`Private`$multiquadraticStripSplitSparseCompilation,
      FeynFacet`Private`$multiquadraticStripSplitSparsePlanCache,
      FeynFacet`Private`$multiquadraticStripSplitSparseExactPlanCache},
      FeynFacet`Private`$multiquadraticStripSplitSparseCompilation = False;
      FeynFacet`Private`$multiquadraticStripSplitSparsePlanCache = <||>;
      FeynFacet`Private`$multiquadraticStripSplitSparseExactPlanCache = <||>;
      ! TrueQ[wideScheduleQ[provider]]]];
wideFallback = splitEntry[bx + Sqrt[delta], {rootRecord}, {1},
  <|bx -> 3, by -> 5, be -> 7|>, {4}, {2}, First[widePool]];
check["an explicit wide-prime Wolfram fallback uses exact substitution",
  Lookup[wideFallback, "Status", None] === "OK" &&
    Lookup[wideFallback, "Method", None] === "Substitution" &&
    wideFallback["Channels"] === {3, 1}];
discoveryPilotPrimes = {2147483399, 2147483587};
discoveryPilots = Table[Module[{sample, solution},
    sample = assembleSample[layout, provider, 2, p,
      "PointCount" -> 2, "MaximumAttempts" -> 80,
      "RandomSeed" -> 2026083100 + Mod[p, 997]];
    solution = discoverySolve[sample["Matrix"], sample["RightHandSide"], p,
      prepared["GaugeUnknownCount"], prepared["ResidueUnknownCount"],
      Automatic, 2, Automatic];
    pilotRecord[p, 2, sample, solution]],
  {p, discoveryPilotPrimes}];
wideDefault = reconstruct[prepared, layout, provider,
  "MinimumGoodPrimeCount" -> 2, "MaximumGoodPrimeCount" -> 2,
  "MaximumRejectedPrimeCount" -> 4,
  "UnseenPrimeCount" -> 1, "FreshPointwiseChecksPerPrime" -> 1,
  "PilotImages" -> discoveryPilots,
  "ExactVerification" -> "ProviderPoints"];
check["31-bit discovery pilots do not enter the wide CRT schedule",
  Lookup[wideDefault, "Status", None] ===
      "ReconstructedRegulatorDependenceV1" &&
    wideDefault["ModalReferencePrime"] === First[discoveryPilotPrimes] &&
    wideDefault["SamplePrimes"] === Take[widePool, 2] &&
    Intersection[wideDefault["GoodPrimes"], discoveryPilotPrimes] === {} &&
    AllTrue[wideDefault["GoodPrimes"], 2^60 < #1 < 2^61 &] &&
    AllTrue[wideDefault["UnseenPrimes"], #1 < 2^31 &] &&
    TrueQ[Together[wideDefault["Gauge"][[1, 1]] -
      knownGauge[[1, 1]]] === 0]];

corrupted = ReplacePart[result["Vector"], 1 -> result["Vector"][[1]] + 1];
corruptCheck = residualImage[layout, provider, corrupted, be, 37,
  First[result["UnseenPrimes"]], "PointCount" -> 2,
  "RandomSeed" -> 2026082799, "SplitPointsOnly" -> True];
check["B2 a corrupted reconstructed coordinate fails fresh replay",
  Lookup[corruptCheck, "Status", None] ===
    "ProviderPointwiseResidualNonzero"];

exhausted = reconstruct[prepared, layout, provider,
  "SamplePrimes" -> Take[primePool, 2],
  "PrimePool" -> Take[primePool, 3],
  "MinimumGoodPrimeCount" -> 2, "MaximumGoodPrimeCount" -> 2,
  "MaximumRejectedPrimeCount" -> 4,
  "ExactVerification" -> "ProviderPoints"];
check["B2 a capped lift preserves fresh rejection, never an obstruction",
  Lookup[exhausted, "Status", None] ===
      "CandidateLiftRejectedByFreshProviderResidual" &&
    StringFreeQ[Lookup[exhausted, "Status", ""], "Obstruction"] &&
    IntegerQ[Lookup[exhausted, "ModulusBitLength", None]] &&
    Lookup[exhausted, "UnresolvedCoefficientCount", None] === 0 &&
    Lookup[exhausted, "UnresolvedCoefficientLocations", None] === {} &&
    Lookup[exhausted["PrimeCountEstimate"], "Method", None] ===
      "FreshProviderRejectionV1" &&
    Lookup[exhausted["PrimeCountEstimate"], "Lower", None] === 3 &&
    Lookup[exhausted["PrimeCountEstimate"], "Likely", None] === 3 &&
    Lookup[exhausted["PrimeCountEstimate"], "Conservative", None] === 4];

Print["t_multiquadratic_reconstruction_hardening: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
