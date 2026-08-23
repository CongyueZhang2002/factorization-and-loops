#!/usr/bin/env wolframscript

(* Targeted adversarial checks for the 2026-08-21 diagonal- and
   off-diagonal epsilon-form implementations.  This script intentionally
   runs against the packaged implementation, without loading any Codex
   candidate override. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
If[! NameQ["FeynFacet`DiagonalBlockEpsForm"],
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "FeynFacet", "Private", "FiniteFieldEpsForm.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "FiniteFieldStripSolve.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "DiagonalBlockEpsForm.wl"}]];
End[];

Clear[xStress, yStress, epsStress];
x = xStress; y = yStress; eps = epsStress;
checks = <||>;

(* A canonical identity may be exact while its alleged letter still
   depends on the regulator.  Such a form is not an epsilon form. *)
diagGate = FeynFacet`CertifyDiagonalBlockEpsForm[
  {{{eps/(x + eps)}}, {{0}}}, {x, y}, eps,
  {{1}}, {x + eps}, {{{1}}}];
diagScalar = FeynFacet`DiagonalBlockEpsForm[
  {{{eps/(x + eps)}}, {{0}}}, {x, y}, eps];
checks["PackagedDiagonalGateAcceptsEpsilonDependentLetter"] =
  AssociationQ[diagGate] && diagGate["Status"] === "Certified";
checks["PackagedScalarRouteAcceptsEpsilonDependentLetter"] =
  AssociationQ[diagScalar] && diagScalar["Status"] === "Certified" &&
    ! FreeQ[diagScalar["Letters"], eps];

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
checks["PackagedOffDiagonalVerifierAcceptsEpsilonDependentLetter"] =
  AssociationQ[letterVerification] &&
    TrueQ[letterVerification["ExactPfaffianResidualsZero"]];

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
checks["PackagedOffDiagonalVerifierAcceptsNonconstantResidue"] =
  AssociationQ[residueVerification] &&
    TrueQ[residueVerification["ExactPfaffianResidualsZero"]];

(* The reserve-prime code searches only a fixed 65-prime window.  A
   legal finite schedule can exhaust that window before the unseen-prime
   certificate is attempted. *)
reserveSchedule = NestList[NextPrime[#, -1] &, 2147483399, 64];
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
  $Failed]], 20, $TimedOut];
checks["PackagedReserveWindowCanBeExhausted"] =
  ! (AssociationQ[reserveResult] &&
      PrimeQ[Lookup[reserveResult, "UnseenPrime", 0]] &&
      ! MemberQ[reserveSchedule, reserveResult["UnseenPrime"]]);

Print[InputForm[<|
  "Checks" -> checks,
  "DiagonalGate" -> KeyDrop[diagGate, "EpsForm"],
  "DiagonalScalar" -> KeyTake[diagScalar,
    {"Status", "Method", "Letters", "Residues", "Gate"}],
  "OffDiagonalLetterVerification" -> KeyDrop[letterVerification, "Residuals"],
  "OffDiagonalResidueVerification" -> KeyDrop[residueVerification, "Residuals"],
  "ReserveResultHead" -> Head[reserveResult],
  "ReserveResultStatus" -> If[AssociationQ[reserveResult],
    Lookup[reserveResult, "Status", "AssociationWithoutStatus"], Missing[]]
|>]];

Exit[If[And @@ Values[checks], 0, 1]];
