#!/usr/bin/env wolframscript

(* Load the external candidate implementations over the package, exercise
   the adversarial cases, then restore the packaged definitions before
   returning this persistent KernelPool worker to the pool. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{root, "External", "CodexExchange",
  "codex_epsform_stress_2026-08-21"}];
If[! NameQ["FeynFacet`DiagonalBlockEpsForm"],
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

Begin["FeynFacet`Private`"];
Get[FileNameJoin[{exchange, "CodexFiniteFieldEpsFormCandidate.wl"}]];
Get[FileNameJoin[{exchange, "CodexFiniteFieldStripSolveCandidate.wl"}]];
Get[FileNameJoin[{exchange, "CodexDiagonalBlockEpsFormCandidate.wl"}]];
End[];

Clear[xCandidate, yCandidate, epsCandidate];
x = xCandidate; y = yCandidate; eps = epsCandidate;
checks = <||>;

diagGate = FeynFacet`CertifyDiagonalBlockEpsForm[
  {{{eps/(x + eps)}}, {{0}}}, {x, y}, eps,
  {{1}}, {x + eps}, {{{1}}}];
diagScalar = FeynFacet`DiagonalBlockEpsForm[
  {{{eps/(x + eps)}}, {{0}}}, {x, y}, eps];
diagValid = FeynFacet`DiagonalBlockEpsForm[
  {{{eps/x}}, {{0}}}, {x, y}, eps];
checks["DiagonalGateRejectsEpsilonDependentLetter"] =
  AssociationQ[diagGate] && diagGate["Status"] === "GateFailed" &&
    TrueQ[diagGate["GateX"]] && TrueQ[diagGate["GateY"]] &&
    ! TrueQ[diagGate["LettersEpsFree"]];
checks["ScalarRouteRejectsEpsilonDependentLetter"] =
  AssociationQ[diagScalar] && diagScalar["Status"] === "GateFailed" &&
    ! TrueQ[diagScalar["Gate"]["LettersEpsFree"]];
checks["ValidScalarRouteStillCertifies"] =
  AssociationQ[diagValid] && diagValid["Status"] === "Certified" &&
    TrueQ[diagValid["Gate"]["LettersEpsFree"]];

zeroPair = {{{0}}, {{0}}};
letterRecord = <|
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {zeroPair, zeroPair, {{{eps/(x + eps)}}, {{0}}}}
|>;
letterSolution = <|
  "Gauge" -> {{0}}, "Alphabet" -> {x + eps},
  "ResidueMatrices" -> {{{1}}}
|>;
letterVerification = FeynFacet`VerifyEpsFormStrip[
  letterRecord, letterSolution, "KernelCount" -> 1];
checks["OffDiagonalRejectsEpsilonDependentLetter"] =
  AssociationQ[letterVerification] &&
    MissingQ[letterVerification["ExactPfaffianIdentitiesZero"]] &&
    MissingQ[letterVerification["ExactPfaffianResidualsZero"]] &&
    ! TrueQ[letterVerification["LettersEpsFree"]] &&
    TrueQ[letterVerification["ConstantResidues"]] &&
    ! TrueQ[letterVerification["CanonicalEpsFormCertified"]];

residueRecord = <|
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {zeroPair, zeroPair, {{{eps^2/x}}, {{0}}}}
|>;
residueSolution = <|
  "Gauge" -> {{0}}, "Alphabet" -> {x},
  "ResidueMatrices" -> {{{eps}}}
|>;
residueVerification = FeynFacet`VerifyEpsFormStrip[
  residueRecord, residueSolution, "KernelCount" -> 1];
checks["OffDiagonalRejectsNonconstantResidue"] =
  AssociationQ[residueVerification] &&
    MissingQ[residueVerification["ExactPfaffianIdentitiesZero"]] &&
    MissingQ[residueVerification["ExactPfaffianResidualsZero"]] &&
    TrueQ[residueVerification["LettersEpsFree"]] &&
    ! TrueQ[residueVerification["ConstantResidues"]] &&
    ! TrueQ[residueVerification["CanonicalEpsFormCertified"]];

validRecord = <|
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {zeroPair, zeroPair, {{{eps/x}}, {{0}}}}
|>;
validSolution = <|
  "Gauge" -> {{0}}, "Alphabet" -> {x},
  "ResidueMatrices" -> {{{1}}}
|>;
validVerification = FeynFacet`VerifyEpsFormStrip[
  validRecord, validSolution, "KernelCount" -> 1];
checks["ValidOffDiagonalCertificateStillPasses"] =
  AssociationQ[validVerification] &&
    And @@ (TrueQ[validVerification[#]] & /@
      {"ExactPfaffianIdentitiesZero", "LettersEpsFree",
       "ConstantResidues", "ExactPfaffianResidualsZero",
       "CanonicalEpsFormCertified"});

checkpoint = <|"Sector" -> 7, "PrevD" -> {{0}}, "StripSolvers" -> {}|>;
installMetadata = <|
  "GaugeNumeratorDegrees" -> {0, 0},
  "GaugeDenominatorDegrees" -> {0, 0},
  "Primes" -> {1000003},
  (* Deliberately spoof the legacy boolean: installation must recompute. *)
  "ExactPfaffianResidualsZero" -> True
|>;
validInstalled = Quiet[Check[FeynFacet`InstallEpsFormStripSolution[
  checkpoint, validRecord, Join[validSolution, installMetadata], 7, 6],
  $Failed]];
invalidInstalled = Quiet[Check[FeynFacet`InstallEpsFormStripSolution[
  checkpoint, residueRecord, Join[residueSolution, installMetadata], 7, 6],
  $Failed]];
checks["InstallerRecomputesStructuralCertificate"] =
  AssociationQ[validInstalled] && invalidInstalled === $Failed;

reserveSchedule = NestList[NextPrime[#, -1] &, 2147483399, 64];
reservePrimes = FeynFacet`Private`finiteFieldStripReservePrimes[
  reserveSchedule, 3];
checks["ReserveGeneratorEscapesArbitraryFiniteWindow"] =
  Length[reservePrimes] === 3 && DuplicateFreeQ[reservePrimes] &&
    AllTrue[reservePrimes, PrimeQ] &&
    AllTrue[reservePrimes, # < 2^31 && ! MemberQ[reserveSchedule, #] &];

solveRecord = <|
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {{{{1}}, {{0}}}, zeroPair, {{{1 - eps x}}, {{0}}}}
|>;
reserveResult = TimeConstrained[Quiet[Check[
  FeynFacet`SolveEpsFormStripFiniteField[solveRecord,
    "Primes" -> reserveSchedule,
    "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
    "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}},
    "PointCount" -> 8, "KernelCount" -> 1,
    "ConstructionCount" -> 6, "MaximumTotalDegree" -> 4,
    "MinimumPrimeCount" -> 1, "AdaptiveValidationMargin" -> 4,
    "InitialConstructionCount" -> 4, "HeldOutCount" -> 3,
    "UnseenPrimeCheck" -> True, "Verbose" -> False],
  $Failed]], 30, $TimedOut];
checks["FullSolveUsesPrimeOutsideExhaustedWindow"] =
  AssociationQ[reserveResult] &&
    TrueQ[reserveResult["ExactPfaffianResidualsZero"]] &&
    TrueQ[reserveResult["CanonicalEpsFormCertified"]] &&
    PrimeQ[reserveResult["UnseenPrime"]] &&
    ! MemberQ[reserveSchedule, reserveResult["UnseenPrime"]];

report = <|
  "Checks" -> checks,
  "DiagonalGate" -> KeyDrop[diagGate, "EpsForm"],
  "OffDiagonalLetterVerification" -> KeyDrop[letterVerification, "Residuals"],
  "OffDiagonalResidueVerification" -> KeyDrop[residueVerification, "Residuals"],
  "InstallerAcceptedValid" -> AssociationQ[validInstalled],
  "InstallerRejectedSpoofedRawResidues" -> (invalidInstalled === $Failed),
  "ReservePrimes" -> reservePrimes,
  "FullSolve" -> If[AssociationQ[reserveResult],
    KeyTake[reserveResult, {"Status", "ExactPfaffianResidualsZero",
      "CanonicalEpsFormCertified", "UnseenPrime", "ModularPrimeCount",
      "PrimeSampleCounts"}],
    reserveResult]
|>;
Print[InputForm[report]];

(* Leave the persistent worker with the package implementation, not the
   experimental override. *)
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "FeynFacet", "Private", "FiniteFieldEpsForm.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "DiagonalBlockEpsForm.wl"}]];
End[];

Exit[If[And @@ Values[checks], 0, 1]];
