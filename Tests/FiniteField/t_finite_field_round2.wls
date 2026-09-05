#!/usr/bin/env wolframscript
(* A2 (held-out regulator sampling), A3 (a-priori sparse support) and A4
   (FLINT backend), standardized 2026-08-21 from Codex's round-2
   prototypes; extended the same evening after an independent check.
   - the support census on the frozen CF254 (9,6) block reproduces the
     measured numbers (124 of 169 monomials at offset {1,0}, 548 of 728
     unknowns, certificate True) and the sparse probe is consistent;
   - on a small synthetic block the held-out solve is exact, uses fewer
     regulator images than the deterministic schedule, records the
     certification mode, and agrees with the deterministic solve;
   - the held-out interpolation itself, on synthetic coordinates of
     degrees up to (3,3)/(5,1): 4 -> 7 -> 10 images, correct degrees,
     exact at fresh regulator values, profile-change rejection, growth
     requests, learned profile on a second prime;
   - the unseen-prime residual accepts the true CF254 (9,6) lift (from
     the stored A4 acceptance artifacts) and rejects corrupted lifts;
   - the reserve prime is never in the schedule, even when the schedule
     contains the former fixed reserves;
   - the point evaluator refuses primes at or above 2^31 (packed width);
   - the degree-probe order is shell 0, rectangle, then the intermediate
     shells. *)
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
checks = <||>;

fixture = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "BenchmarkStripBackends", "fixtures", "fixture_CF254_9_6.wl"}]];
prep = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[fixture];
census = prep["SupportCensus"];
checks["SupportCertified"] = TrueQ[census["CertifiedQ"]];
checks["SupportBound15"] = census["NumeratorTotalDegreeBound"] === 15;
support = FeynFacet`Private`finiteFieldOffDiagonalBlockSupport[prep, prep["DenominatorDegrees"] + {1, 0}, Automatic, 0];
(* 2026-08-22: the certified support is the whole total-degree simplex
   (bound 15 -> 136 monomials); it was the bidegree rectangle cut by the
   bound (124) before, which excluded numerators the bound allows
   (CF305 block (18,15)) *)
checks["Support136"] = Length[support] === 136 && Max[Total /@ support] === 15;
checks["LadderEndsAtRectangle"] = Last[FeynFacet`Private`finiteFieldOffDiagonalBlockSupportLadder[prep, prep["DenominatorDegrees"] + {1, 0}]] === "Rectangle";
probe = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[fixture, 1/21, 1000003,
  "NumeratorDegreeOffset" -> {1, 0}, "SolveAffineSystem" -> False,
  "Preparation" -> prep];
checks["SparseProbeConsistent"] = AssociationQ[probe] && TrueQ[probe["Consistent"]] &&
  probe["OffDiagonalBasisTransformationUnknownCount"] + probe["FreeResidueCount"] === 596 && probe["OffDiagonalBasisTransformationNumeratorSupportCount"] === 136;

Clear[xH, yH, epsH];
record = <|"Variables" -> {xH, yH}, "Regulator" -> epsH,
  "OffDiagonalBlockEquation" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}}, {{{1 - epsH xH}}, {{0}}}}|>;
common = {"Primes" -> {1000003, 2147483423, 2147483477},
  "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}}, "PointCount" -> 8, "KernelCount" -> 1,
  "ConstructionCount" -> 6, "MaximumTotalDegree" -> 4, "MinimumPrimeCount" -> 3,
  "AdaptiveValidationMargin" -> 4, "Verbose" -> False};
heldOut = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, "RegulatorSampling" -> "HeldOut", Sequence @@ common];
deterministic = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, "RegulatorSampling" -> "Deterministic", Sequence @@ common];
explicitSupport = If[AssociationQ[heldOut], heldOut["OffDiagonalBasisTransformationNumeratorSupport"], {{0, 0}}];
explicitSupportSolve = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record,
  "RegulatorSampling" -> "HeldOut", "Support" -> explicitSupport,
  "SupportLearning" -> False, Sequence @@ common];
checks["HeldOutExact"] = AssociationQ[heldOut] && TrueQ[heldOut["ExactPfaffianResidualsZero"]];
checks["HeldOutMode"] = AssociationQ[heldOut] && heldOut["CertificationMode"] === "HeldOut";
checks["HeldOutFewerImages"] = AssociationQ[heldOut] && AssociationQ[deterministic] &&
  Total[heldOut["PrimeSampleCounts"]] < Total[deterministic["PrimeSampleCounts"]];
checks["HeldOutAgreesWithDeterministic"] = AssociationQ[heldOut] && AssociationQ[deterministic] &&
  Map[Together, heldOut["OffDiagonalBasisTransformationBlock"], {2}] === Map[Together, deterministic["OffDiagonalBasisTransformationBlock"], {2}] &&
  heldOut["ResidueMatrices"] === deterministic["ResidueMatrices"];
checks["TopLevelExplicitSupportIsHonored"] =
  AssociationQ[explicitSupportSolve] &&
  explicitSupportSolve["OffDiagonalBasisTransformationNumeratorSupport"] === explicitSupport;
(* A4: the FLINT adapter, when built, must reproduce the Wolfram modular
   solution exactly; when absent the backend selection must say so *)
If[FeynFacet`Private`finiteFieldOffDiagonalBlockFLINTBinary[] =!= None,
  Module[{p = 2147483647, A, X, B, sol},
    SeedRandom[11]; A = RandomInteger[{0, p - 1}, {300, 300}]; X = RandomInteger[{0, p - 1}, {300, 3}];
    B = Mod[A . X, p];
    sol = FeynFacet`Private`finiteFieldOffDiagonalBlockFLINTSolve[A, B, p, 1];
    checks["FLINTSolveMatchesWolfram"] = sol === LinearSolve[A, B, Modulus -> p] && sol === X;
    checks["FLINTAutomaticForLargeCores"] = FeynFacet`Private`finiteFieldOffDiagonalBlockBackendQ[Automatic, 600] &&
      ! FeynFacet`Private`finiteFieldOffDiagonalBlockBackendQ[Automatic, 100]],
  checks["FLINTAbsentFallsBackToWolfram"] = ! FeynFacet`Private`finiteFieldOffDiagonalBlockBackendQ[Automatic, 600] &&
    ! FeynFacet`Private`finiteFieldOffDiagonalBlockBackendQ["FLINT", 600]];
(* ---- held-out interpolation mechanics at nontrivial degrees ---- *)
Module[{p = 2147483647, p2 = 2147483629, modQ, fs, trueDeg, epsVals, canon, canon2, ev, r, r2, r3, r4, r5, r6, fresh, e},
  modQ[q_, v_] := Mod[Mod[Numerator[v], q] PowerMod[Mod[Denominator[v], q], -1, q], q];
  fs = {(3 e^3 + 2 e + 1)/(e^3 - 5 e^2 + 7), (e + 2)/(4 e^2 + 1), 5, 0, e^5/(e + 3), (e^2 - 1)/(e^2 + 2 e + 1)};
  trueDeg = {{3, 3}, {1, 2}, {0, 0}, {-Infinity, 0}, {5, 1}, {1, 1}};
  epsVals = Table[k/(k + 20), {k, 1, 24}];
  canon = Table[<|"EpsilonValue" -> v, "EpsilonMod" -> modQ[p, v], "Values" -> (modQ[p, # /. e -> v] & /@ fs)|>, {v, epsVals}];
  canon2 = Table[<|"EpsilonValue" -> v, "EpsilonMod" -> modQ[p2, v], "Values" -> (modQ[p2, # /. e -> v] & /@ fs)|>, {v, epsVals}];
  ev[q_, c_, x_] := Fold[Mod[#1 x + #2, q] &, 0, Reverse[c]];
  r = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[canon, p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3];
  checks["HeldOutMechanicsValidatedAtTen"] = r["Status"] === "HeldOutValidated" && r["SampleCount"] === 10 && r["ConstructionCount"] === 7;
  checks["HeldOutMechanicsDegrees"] = r["Status"] === "HeldOutValidated" && Lookup[r["Interpolations"], "Degrees"] === trueDeg;
  fresh = {101/7, 55/3, 1000/999};
  checks["HeldOutMechanicsExactAtFreshValues"] = r["Status"] === "HeldOutValidated" && And @@ Table[AllTrue[fresh, Function[x,
    Mod[ev[p, r["Interpolations"][[i]]["Numerator"], modQ[p, x]] - modQ[p, fs[[i]] /. e -> x] ev[p, r["Interpolations"][[i]]["Denominator"], modQ[p, x]], p] === 0]], {i, Length[fs]}];
  r2 = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[canon, p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3, "ExpectedDegrees" -> ReplacePart[trueDeg, 1 -> {2, 2}]];
  checks["HeldOutRejectsChangedProfile"] = r2["Status"] === "RejectPrimeDegreeProfileChanged" && r2["DegreeMismatchCoordinates"] === {1};
  r3 = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[Take[canon, 6], p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3];
  r4 = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[Take[canon, 8], p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3];
  checks["HeldOutAsksForMoreSamples"] = r3["Status"] === "MoreSamplesRequired" && r4["Status"] === "MoreSamplesRequired" && r4["RequiredAdditionalSampleCount"] === 2;
  r5 = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[canon2, p2, "InitialConstructionCount" -> 7, "HeldOutCount" -> 3, "ExpectedDegrees" -> trueDeg];
  checks["HeldOutLearnedProfileSecondPrime"] = r5["Status"] === "HeldOutValidated" &&
    r5["SampleCount"] === 10 && r5["CertificationMode"] === "HeldOut" &&
    Lookup[r5["Interpolations"], "Degrees"] === trueDeg;
  r6 = FeynFacet`Private`finiteFieldOffDiagonalBlockHeldOutInterpolate[Take[canon2, 9], p2,
    "InitialConstructionCount" -> 7, "HeldOutCount" -> 3, "ExpectedDegrees" -> trueDeg];
  checks["HeldOutExpectedProfileRequestsExactShortfall"] =
    r6["Status"] === "MoreSamplesRequired" &&
      r6["RequiredAdditionalSampleCount"] === 1 &&
      r6["Reason"] === "ExpectedDegreeHeldOutRound"];

(* ---- unseen-prime residual on the real (9,6) A4 acceptance artifacts ---- *)
Module[{files, modular, lifted, opts, bad, bad2},
  files = FileNames["*_mod_*.wl", FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
    "BenchmarkStripBackends", "frozen_M0", "a4_run", "ff_artifacts_A4_CF254_9_6_155035"}]];
  modular = FeynFacet`FamilyArtifactRead /@ files;
  lifted = FeynFacet`ReconstructOffDiagonalBasisTransformationBlock[fixture, modular, "KernelCount" -> 1, "ExactCheck" -> False];
  checks["A4ArtifactsLiftUnverified"] = Length[files] === 7 && AssociationQ[lifted] && lifted["Status"] === "LiftedUnverified" &&
    lifted["CertificationMode"] === "HeldOut" && Length[lifted["LiftedVector"]] === 548;
  opts = {"PointCount" -> Automatic, "NumeratorDegreeOffset" -> {1, 0}, "Support" -> Automatic, "SupportShell" -> 0,
    "SolveAffineSystem" -> True, "Preparation" -> prep};
  checks["UnseenPrimeAcceptsTrueLift"] = AssociationQ[lifted] &&
    FeynFacet`Private`finiteFieldOffDiagonalBlockUnseenPrimeResidualQ[fixture, lifted, prep, 2147483399, 43/63, opts];
  If[AssociationQ[lifted],
    bad = lifted; bad["LiftedVector"] = ReplacePart[lifted["LiftedVector"], 5 -> lifted["LiftedVector"][[5]] + 1];
    bad2 = lifted; bad2["LiftedVector"] = ReplacePart[lifted["LiftedVector"], 5 -> lifted["LiftedVector"][[5]] + fixture["Regulator"]/7];
    checks["UnseenPrimeRejectsCorruptedLifts"] =
      ! FeynFacet`Private`finiteFieldOffDiagonalBlockUnseenPrimeResidualQ[fixture, bad, prep, 2147483399, 43/63, opts] &&
      ! FeynFacet`Private`finiteFieldOffDiagonalBlockUnseenPrimeResidualQ[fixture, bad2, prep, 2147483399, 43/63, opts],
    checks["UnseenPrimeRejectsCorruptedLifts"] = False]];

(* ---- reserve prime never in the schedule; width guard; probe order ---- *)
Module[{sol, wide = 2305843009213693951, probeWide, solWide},
  sol = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, "RegulatorSampling" -> "HeldOut",
    Sequence @@ Join[{"Primes" -> {2147483399, 2147483353, 2147483323}}, DeleteCases[common, "Primes" -> _]]];
  checks["ReservePrimeOutsideSchedule"] = AssociationQ[sol] && TrueQ[sol["ExactPfaffianResidualsZero"]] &&
    PrimeQ[sol["UnseenPrime"]] && ! MemberQ[{2147483399, 2147483353, 2147483323}, sol["UnseenPrime"]] && sol["UnseenPrime"] < 2^31;
  probeWide = Quiet[Check[FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[fixture, 1/21, wide, "NumeratorDegreeOffset" -> {1, 0},
    "SolveAffineSystem" -> False, "Preparation" -> prep], "messaged",
    FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage::width], FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage::width];
  solWide = Quiet[Check[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, Sequence @@ Join[{"Primes" -> {wide}}, DeleteCases[common, "Primes" -> _]]],
    "messaged", FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage::width], FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage::width];
  checks["WidthGuardRefusesWidePrimes"] = probeWide === "messaged" && solWide === "messaged";
  checks["ProbeOrderShellRectangleThenShells"] =
    FeynFacet`Private`finiteFieldOffDiagonalBlockProbeOrder[{"Rectangle"}] === {"Rectangle"} &&
    FeynFacet`Private`finiteFieldOffDiagonalBlockProbeOrder[{0, "Rectangle"}] === {0, "Rectangle"} &&
    FeynFacet`Private`finiteFieldOffDiagonalBlockProbeOrder[{0, 1, 2, 3, "Rectangle"}] === {0, "Rectangle", 1, 2, 3}];

(* ---- dimension-3 block: the monomial-table pattern collision (found 2026-08-22) ----
   a row of three {numerator, denominator} pairs matched the old leaf pattern
   {_List, _List, _List} and coefficient residues were read as exponents:
   power tables of p - 1 entries per point, 9 s per sample on this 48-unknown
   strip, kernel death by memory at 31-bit primes *)
Module[{strip, prep, sample, sol, t},
  strip = FeynFacet`FamilyArtifactRead[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "BenchmarkStripBackends", "fixtures", "cf254_strips_2026-08-19", "CF254_12_11_input.wl"}]];
  prep = FeynFacet`Private`PrepareOffDiagonalBlockFiniteFieldSystem[strip];
  sample = FeynFacet`Private`ComputeOffDiagonalBlockFiniteFieldImage[strip, 1/21, 2147483647, "NumeratorDegreeOffset" -> {1, 0},
    "SolveAffineSystem" -> False, "Preparation" -> prep];
  checks["Dim3BlockTableExponentsSmall"] = AssociationQ[sample] && Dimensions[strip["OffDiagonalBlockEquation"][[3, 1]]] === {1, 3} &&
    MatchQ[sample["TableExponents"], {a_Integer, b_Integer} /; a < 40 && b < 40];
  {t, sol} = AbsoluteTiming[FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[strip, "KernelCount" -> 1, "Verbose" -> False]];
  checks["Dim3BlockSolvesQuickly"] = AssociationQ[sol] && sol["Status"] === "Solved" &&
    TrueQ[sol["DLogFormCertified"]] && t < 60];

Print[InputForm[checks]];
If[AssociationQ[heldOut], Print["held-out sample counts ", heldOut["PrimeSampleCounts"], " deterministic ", deterministic["PrimeSampleCounts"]]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#] &]]];
Exit[If[And @@ Values[checks], 0, 1]];
