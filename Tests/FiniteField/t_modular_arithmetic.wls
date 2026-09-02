#!/usr/bin/env wolframscript
(* The shared finite-field primitives of FeynFacet/Private/ModularArithmetic.wl.

   Acceptance criteria, all stated before the run and all checked
   against INDEPENDENT values (a brute-force search over the
   representable rationals, ChineseRemainder, JacobiSymbol, NextPrime,
   or the existing implementation being replaced) -- never against the
   module's own output:

     - modularRationalReconstruct agrees, at EVERY residue of two small
       moduli, with an exhaustive search for the unique rational
       |n| <= B, 0 < d <= B, gcd(n,d) = 1, n == a d (mod m); it round
       trips random in-bound rationals at five moduli and reports
       $Failed exactly on the residues the exhaustive search finds
       unrepresentable;
     - the explicit-bound form obeys |n| <= nBound, 0 < d <= dBound,
       refuses an ambiguous request (2 nBound dBound >= m), and agrees
       with the exhaustive search at every residue of one modulus;
     - it agrees with BOTH existing implementations
       (epsFormFiniteFieldRationalReconstruct and
       familyCertRationalReconstruct) on 200 random inputs each, at
       small and at large moduli, and those two agree with each other
       there (they differ in source: the family-certificate version
       omits the numerator bound and the residual check, which are loop
       invariants, so the agreement is a theorem this test pins);
     - modularCRT equals ChineseRemainder, lands in [0, Times@@moduli),
       fails typed on an inconsistent system, and its list form equals
       epsFormFiniteFieldCombineLists including the zero padding;
     - modularImageQ equals epsFormFiniteFieldImageQ at primes and is
       False for a denominator that is not a unit;
     - modularLift reconstructs a vector of known rationals through
       three primes, verifies every coordinate at every prime, and
       returns $Failed for a coordinate that the exhaustive search
       proves unrepresentable at that modulus while the SAME vector
       lifts exactly through three 31-bit primes;
     - modularSquareRoot returns a verified root for p == 3 (mod 4)
       (2^31-1) and for p == 1 (mod 4) (1000000009, Tonelli-Shanks),
       returns 0 at 0, rejects every non-residue and every modulus that
       is not an odd prime, and its p == 3 (mod 4) representative is
       multiquadraticSquareRoots' representative;
     - modularSplitPointQ agrees with multiquadraticSplitPointQ at both
       primes on random points, is correct on a rational-coefficient
       radicand, and fails typed when a coefficient denominator
       vanishes;
     - modularSplitPoints is deterministic in its seed, admits
       p == 1 (mod 4), returns points whose root squares and roots are
       the independently evaluated radicands and their verified square
       roots, and reports the exhausted status when the attempt budget
       is spent;
     - modularPrimes reproduces the descending NextPrime schedule
       exactly, is distinct and inside [2^(bits-1), 2^bits), honours
       "Exclude", "Residue3Mod4" and "Avoid", and is deterministic in
       "Random" -> seed.

   The module is loaded directly: it is not registered in FeynFacet.m
   yet. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "FeynFacet", "Private", "Core", "ModularArithmetic.wl"}]];
End[];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

(* The body below is read in its own context with only System` and the
   assertion kit visible.  LoadFACET puts FeynCalc, FeynArts and their
   add-ons on $ContextPath, and those packages dump symbols (CLAUDE.md:
   asy ~200 of them plus a bare x, SubTropica exports line): a bare
   lowercase name such as image, lift or crt would otherwise bind to
   whichever package exported it first. *)
(* The switch is undone before the report: on a reused pool subkernel a
   leaked $Context/$ContextPath changes where every later mission's bare
   symbols land (measured 2026-09-02, overhaul B11). *)
ftModularSavedContexts = {$Context, $ContextPath};
$ContextPath = {"FTTest`", "System`"};
$Context = "FTModularArithmeticTest`";

ff[name_String] := Symbol["FeynFacet`Private`" <> name];

{ratRec, crt, imageQ, lift, sqrtOne, sqrtList, residueQ, splitQ,
   splitPts, primesOf} =
  ff /@ {"modularRationalReconstruct", "modularCRT", "modularImageQ",
    "modularLift", "modularSquareRoot", "modularSquareRoots",
    "modularResidueQ", "modularSplitPointQ", "modularSplitPoints",
    "modularPrimes"};
{epsRec, epsCombine, epsImageQ, certRec, certRoot, mqRoots, mqSplitQ} =
  ff /@ {"epsFormFiniteFieldRationalReconstruct",
    "epsFormFiniteFieldCombineLists", "epsFormFiniteFieldImageQ",
    "familyCertRationalReconstruct", "familyCertMQSquareRoot",
    "multiquadraticSquareRoots", "multiquadraticSplitPointQ"};

(* ---- independent oracles ------------------------------------------- *)

(* every rational n/d with |n| <= nB, 0 < d <= dB, gcd(n,d) = 1,
   gcd(d,m) = 1 and n == a d (mod m); the reconstruction contract is
   that this set has at most one element when 2 nB dB < m *)
bruteRR[a_, m_, nB_, dB_] := Module[{sols},
  sols = DeleteDuplicates[Table[
     With[{n = Mod[a d, m]},
      With[{ns = If[2 n > m, n - m, n]},
       If[Abs[ns] <= nB && CoprimeQ[ns, d] && CoprimeQ[d, m],
        ns/d, Nothing]]],
     {d, 1, dB}]];
  Which[sols === {}, $Failed, Length[sols] === 1, First[sols],
   True, "Ambiguous"]];

image[r_, p_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, p], p];

p3 = 2^31 - 1;            (* 3 mod 4 *)
p1 = 1000000009;          (* 1 mod 4 *)
vx = \[FormalX]; vy = \[FormalY];
radicands = {vx, vy, vx + vy};

(* ==================================================================
   A. rational reconstruction
   ================================================================== *)

FTAssert["the two test primes are as declared (2^31-1 is 3 mod 4, 1000000009 is 1 mod 4)",
  PrimeQ[p3] && Mod[p3, 4] === 3 && PrimeQ[p1] && Mod[p1, 4] === 1];

FTAssert["exhaustive, unambiguous agreement at every residue mod 1009 (bound 22)",
  Floor[Sqrt[(1009 - 1)/2]] === 22 &&
   FreeQ[bruteRR[#, 1009, 22, 22] & /@ Range[0, 1008], "Ambiguous"] &&
   AllTrue[Range[0, 1008], ratRec[#, 1009] === bruteRR[#, 1009, 22, 22] &]];

FTAssert["exhaustive agreement at every residue mod 101 (bound 7)",
  Floor[Sqrt[(101 - 1)/2]] === 7 &&
   AllTrue[Range[0, 100], ratRec[#, 101] === bruteRR[#, 101, 7, 7] &]];

unrepresentable1009 = Select[Range[0, 1008], bruteRR[#, 1009, 22, 22] === $Failed &];
FTAssert["unrepresentable residues exist mod 1009 and all reconstruct to $Failed",
  Length[unrepresentable1009] > 0 &&
   AllTrue[unrepresentable1009, ratRec[#, 1009] === $Failed &]];

FTAssert["a == 0 reconstructs to the integer 0 at every modulus tried",
  AllTrue[{1, 2, 101, 1009, p3, p1, p3 p1},
   ratRec[0, #] === 0 && ratRec[#, #] === 0 && ratRec[-2 #, #] === 0 &]];

SeedRandom[20260902];
roundTrip[m_] := Module[{bound = Floor[Sqrt[(m - 1)/2]], pairs},
  pairs = Select[Table[
     {RandomInteger[{-bound, bound}], RandomInteger[{1, bound}]}, {200}],
    CoprimeQ[#[[1]], #[[2]]] && CoprimeQ[#[[2]], m] &];
  {Length[pairs],
   AllTrue[pairs, ratRec[image[#[[1]]/#[[2]], m], m] === #[[1]]/#[[2]] &]}];
roundTrips = roundTrip /@ {1009, 65537, p3, p1, p3 p1};
FTAssert["random in-bound rationals round trip at all five moduli (>80 coprime pairs each)",
  AllTrue[roundTrips, First[#] > 80 && Last[#] &]];

outOfBound = image[500/501, 1009];
bigOut = image[123456789/7, p3];
FTAssert["an out-of-bound rational is never returned, at 1009 and at 2^31-1",
  ratRec[outOfBound, 1009] =!= 500/501 &&
   ratRec[outOfBound, 1009] === bruteRR[outOfBound, 1009, 22, 22] &&
   With[{r = ratRec[bigOut, p3]},
    r =!= 123456789/7 &&
     (r === $Failed ||
      (Abs[Numerator[r]] <= 32767 && Denominator[r] <= 32767 &&
       Mod[Numerator[r] - bigOut Denominator[r], p3] === 0))]];

(* explicit asymmetric bounds *)
asymA = image[437/7, 10007];
FTAssert["asymmetric bounds {500, 9} recover 437/7 mod 10007, where the symmetric bound (70) cannot",
  ratRec[asymA, 10007, {500, 9}] === 437/7 &&
   Floor[Sqrt[(10007 - 1)/2]] === 70 && ratRec[asymA, 10007] =!= 437/7 &&
   ratRec[asymA, 10007] === bruteRR[asymA, 10007, 70, 70]];
(* {5000, 1} is NOT a refusal case: with denominator bound 1 the unique
   preimage is the integer residue itself, 437 * 7^-1 == 1492 (mod 10007),
   which lies inside |n| <= 5000; the original assertion expected $Failed
   there and was wrong (found on the first run, 2026-09-02 04:43). *)
FTAssert["an ambiguous request (2 nBound dBound >= m) is refused, a unit denominator bound returns the integer preimage, and a too-small denominator bound is refused",
  ratRec[asymA, 10007, {500, 20}] === $Failed &&
   ratRec[asymA, 10007, {5000, 1}] === Mod[437 PowerMod[7, -1, 10007], 10007] &&
   Mod[437 PowerMod[7, -1, 10007], 10007] <= 5000 &&
   ratRec[asymA, 10007, {500, 6}] === $Failed];
FTAssert["exhaustive agreement of the asymmetric form at every residue mod 1009, bounds {30, 8}",
  AllTrue[Range[0, 1008],
   ratRec[#, 1009, {30, 8}] === bruteRR[#, 1009, 30, 8] &]];
FTAssert["asymmetric edge cases: zero numerator bound, in-bound integer, bad bounds",
  ratRec[0, 1009, {0, 8}] === 0 && ratRec[7, 1009, {30, 8}] === 7 &&
   ratRec[5, 1009, {30, 0}] === $Failed && ratRec[5, 1009, {-1, 8}] === $Failed];

(* agreement with the two implementations being replaced *)
SeedRandom[314159];
smallInputs = Table[{RandomInteger[{0, 10^12}],
   RandomChoice[{101, 1009, 10007}]}, {200}];
largeInputs = Table[{RandomInteger[{0, 10^24}],
   RandomChoice[{65537, p3, p1, p3 p1, 101 103 107}]}, {200}];
FTAssert["modularRationalReconstruct == epsFormFiniteFieldRationalReconstruct on 200 small-modulus inputs",
  AllTrue[smallInputs, ratRec @@ # === epsRec @@ # &]];
FTAssert["modularRationalReconstruct == familyCertRationalReconstruct on 200 small-modulus inputs",
  AllTrue[smallInputs, ratRec @@ # === certRec @@ # &]];
FTAssert["the two existing implementations agree with each other on the 200 small-modulus inputs",
  AllTrue[smallInputs, epsRec @@ # === certRec @@ # &]];
FTAssert["modularRationalReconstruct == epsFormFiniteFieldRationalReconstruct on 200 large-modulus inputs",
  AllTrue[largeInputs, ratRec @@ # === epsRec @@ # &]];
FTAssert["modularRationalReconstruct == familyCertRationalReconstruct on 200 large-modulus inputs",
  AllTrue[largeInputs, ratRec @@ # === certRec @@ # &]];
FTAssert["the 200 small-modulus inputs actually exercise the failure branch",
  Count[smallInputs, input_ /; ratRec @@ input === $Failed] > 20];

(* ==================================================================
   B. Chinese remaindering
   ================================================================== *)

SeedRandom[271828];
crtTrials = Table[{RandomInteger[{0, 10^6}, 3], {101, 103, 107}}, {100}];
FTAssert["modularCRT equals ChineseRemainder on 100 random triples",
  AllTrue[crtTrials, crt @@ # === ChineseRemainder @@ # &]];
FTAssert["modularCRT lands in [0, Times@@moduli) and reproduces the residues it was given",
  AllTrue[crtTrials, 0 <= crt @@ # < Times @@ Last[#] &] &&
   AllTrue[crtTrials,
    With[{x = crt @@ #}, Mod[x, Last[#]] === Mod[First[#], Last[#]]] &]];
FTAssert["an inconsistent non-coprime system fails typed, a consistent one equals ChineseRemainder",
  crt[{1, 2}, {4, 6}] === $Failed &&
   crt[{1, 3}, {4, 6}] === ChineseRemainder[{1, 3}, {4, 6}]];
FTAssert["malformed CRT arguments are typed failures",
  crt[{1, 2}, {5}] === $Failed && crt[{1, 2}, {5, 0}] === $Failed &&
   crt[{1, 2}, {5, -7}] === $Failed && crt[{}, {}] === $Failed &&
   crt[7, {5}] === $Failed];


SeedRandom[161803];
raggedLists = {RandomInteger[{0, 100}, 5], RandomInteger[{0, 102}, 3],
   RandomInteger[{0, 106}, 4]};
raggedModuli = {101, 103, 107};
FTAssert["the list form equals epsFormFiniteFieldCombineLists at the longest length",
  crt[raggedLists, raggedModuli] ===
   epsCombine[raggedLists, 5, raggedModuli]];
FTAssert["the list form pads shorter lists with zero",
  crt[{{1, 2, 3}, {4}}, {5, 7}] ===
   Table[ChineseRemainder[{{1, 2, 3}[[i]], PadRight[{4}, 3][[i]]}, {5, 7}],
    {i, 3}]];
FTAssert["the list form on empty lists is the empty list, and mismatched lengths fail",
  crt[{{}, {}}, {5, 7}] === {} && crt[{{1}, {2}}, {5}] === $Failed];

(* ==================================================================
   C. modular image of a rational
   ================================================================== *)

SeedRandom[112358];
imageTrials = Table[
   With[{p = RandomChoice[{101, 1009, p3, p1}],
     n = RandomInteger[{-50, 50}], d = RandomInteger[{1, 50}]},
    {RandomInteger[{0, p - 1}], n/d, p}], {200}];
FTAssert["modularImageQ equals epsFormFiniteFieldImageQ on 200 random prime triples",
  AllTrue[imageTrials,
   TrueQ[imageQ @@ #] === TrueQ[epsImageQ @@ #] &]];
FTAssert["modularImageQ accepts the true image, rejects a wrong one and rejects a non-unit denominator",
  imageQ[image[3/5, 101], 3/5, 101] === True &&
   imageQ[image[3/5, 101], 4/5, 101] === False &&
   imageQ[image[3/5, 101], 3/5, 1009] === False &&
   imageQ[3, 5/101, 101] === False && imageQ[3, 5/7, 49] === False &&
   imageQ[0, 0, 101] === True];

(* ==================================================================
   D. lift and verify
   ================================================================== *)

liftPrimes = {101, 103, 107};
liftModulus = Times @@ liftPrimes;
liftBound = Floor[Sqrt[(liftModulus - 1)/2]];
goodVector = {3/5, -7/11, 22/7, 1/2};
goodImages = Table[image[#, p] & /@ goodVector, {p, liftPrimes}];
FTAssert["a vector of known rationals lifts exactly through three small primes",
  lift[goodImages, liftPrimes] === goodVector];
FTAssert["every lifted coordinate reproduces its image at every prime",
  With[{lifted = lift[goodImages, liftPrimes]},
   ListQ[lifted] &&
    Table[image[r, p], {p, liftPrimes}, {r, lifted}] === goodImages]];

badCandidates = Table[Mod[k 314159, liftModulus], {k, 1, 60}];
badResidue = SelectFirst[badCandidates,
   bruteRR[#, liftModulus, liftBound, liftBound] === $Failed &, Missing[]];
FTAssert["an unrepresentable residue at the 3-small-prime modulus exists (exhaustive search) and fails to reconstruct",
  IntegerQ[badResidue] &&
   bruteRR[badResidue, liftModulus, liftBound, liftBound] === $Failed &&
   ratRec[badResidue, liftModulus] === $Failed];
badImages = MapThread[Append, {goodImages, Mod[badResidue, #] & /@ liftPrimes}];
FTAssert["one unreconstructible coordinate fails the whole lift",
  lift[badImages, liftPrimes] === $Failed];

bigPrimes = primesOf[31, 3];
bigVector = {3/5, 123456789/7, -22/1051};
bigImages = Table[image[#, p] & /@ bigVector, {p, bigPrimes}];
FTAssert["the same shape lifts exactly once the primes are large enough",
  lift[bigImages, bigPrimes] === bigVector];
FTAssert["malformed lift arguments are typed failures",
  lift[{{1, 2}, {3}}, {101, 103}] === $Failed &&
   lift[{{1}, {2}}, {101, 100}] === $Failed &&
   lift[{{1}, {2}}, {101, 101}] === $Failed &&
   lift[{{}, {}, {}}, liftPrimes] === {}];

(* ==================================================================
   E. square roots
   ================================================================== *)

SeedRandom[999331];
rootTrials3 = RandomInteger[{0, p3 - 1}, 200];
FTAssert["every root returned at 2^31-1 squares back, and every rejection is a non-residue",
  AllTrue[rootTrials3,
   With[{r = sqrtOne[#, p3]},
    If[JacobiSymbol[#, p3] === -1, r === $Failed,
     IntegerQ[r] && 0 <= r < p3 && Mod[r^2 - #, p3] === 0]] &]];
rootTrials1 = RandomInteger[{0, p1 - 1}, 200];
FTAssert["every root returned at 1000000009 squares back (Tonelli-Shanks), and every rejection is a non-residue",
  AllTrue[rootTrials1,
   With[{r = sqrtOne[#, p1]},
    If[JacobiSymbol[#, p1] === -1, r === $Failed,
     IntegerQ[r] && 0 <= r < p1 && Mod[r^2 - #, p1] === 0]] &]];
FTAssert["random squares at 1000000009 are all recovered",
  AllTrue[RandomInteger[{1, p1 - 1}, 200],
   With[{a = Mod[#^2, p1]}, Mod[sqrtOne[a, p1]^2 - a, p1] === 0] &]];
FTAssert["a non-residue is rejected and zero has the root zero, at both primes",
  With[{a3 = SelectFirst[Range[2, 200], JacobiSymbol[#, p3] === -1 &],
    a1 = SelectFirst[Range[2, 200], JacobiSymbol[#, p1] === -1 &]},
   sqrtOne[a3, p3] === $Failed && sqrtOne[a1, p1] === $Failed] &&
   sqrtOne[0, p3] === 0 && sqrtOne[0, p1] === 0 &&
   sqrtOne[p3, p3] === 0 && sqrtOne[2 p1, p1] === 0];
FTAssert["a modulus that is not an odd prime is refused",
  sqrtOne[4, 12] === $Failed && sqrtOne[1, 2] === $Failed &&
   sqrtOne[4, 9] === $Failed && sqrtOne[1, 1] === $Failed &&
   sqrtOne[1, -7] === $Failed];
squareValues = Mod[Range[3, 40]^2, p3];
FTAssert["modularSquareRoots is multiquadraticSquareRoots representative by representative at 3 mod 4, and both fail on a non-residue",
  sqrtList[squareValues, p3] === mqRoots[squareValues, p3] &&
   sqrtList[squareValues, p3] === PowerMod[squareValues, Quotient[p3 + 1, 4], p3] &&
   With[{bad = Append[squareValues,
      SelectFirst[Range[2, 200], JacobiSymbol[#, p3] === -1 &]]},
    sqrtList[bad, p3] === $Failed && mqRoots[bad, p3] === $Failed]];
FTAssert["zero: modularSquareRoots follows multiquadraticSquareRoots (0), familyCertMQSquareRoot refuses it",
  sqrtList[{0}, p3] === {0} && mqRoots[{0}, p3] === {0} &&
   certRoot[0, p3] === $Failed];
FTAssert["modularSquareRoots serves p == 1 (mod 4), which multiquadraticSquareRoots does not accept",
  With[{values = Mod[Range[3, 40]^2, p1]},
   ListQ[sqrtList[values, p1]] &&
    Mod[sqrtList[values, p1]^2 - values, p1] === ConstantArray[0, Length[values]]]];
SeedRandom[424242];
FTAssert["modularResidueQ is the Jacobi symbol on 200 random values at both primes, rejects zero and refuses an even modulus",
  AllTrue[RandomInteger[{0, p3 - 1}, 200],
    residueQ[#, p3] === (Mod[#, p3] =!= 0 && JacobiSymbol[#, p3] === 1) &] &&
   AllTrue[RandomInteger[{0, p1 - 1}, 200],
    residueQ[#, p1] === (Mod[#, p1] =!= 0 && JacobiSymbol[#, p1] === 1) &] &&
   residueQ[0, p3] === False && residueQ[p1, p1] === False &&
   residueQ[3, 8] === $Failed && residueQ[3, 2] === $Failed &&
   residueQ[3, 1] === $Failed];

(* ==================================================================
   F. split points
   ================================================================== *)

SeedRandom[606060];
splitTrials3 = RandomInteger[{1, p3 - 1}, {200, 2}];
splitTrials1 = RandomInteger[{1, p1 - 1}, {200, 2}];
FTAssert["modularSplitPointQ equals multiquadraticSplitPointQ on 200 points at 2^31-1",
  AllTrue[splitTrials3,
   splitQ[#, radicands, {vx, vy}, p3] ===
    mqSplitQ[#, radicands, {vx, vy}, p3] &]];
FTAssert["modularSplitPointQ equals multiquadraticSplitPointQ on 200 points at 1000000009",
  AllTrue[splitTrials1,
   splitQ[#, radicands, {vx, vy}, p1] ===
    mqSplitQ[#, radicands, {vx, vy}, p1] &]];
FTAssert["both verdicts occur among those 400 points, and a vanishing radicand is never a split point",
  Count[splitTrials3, pt_ /; splitQ[pt, radicands, {vx, vy}, p3]] > 10 &&
   Count[splitTrials1, pt_ /; ! TrueQ[splitQ[pt, radicands, {vx, vy}, p1]]] > 10 &&
   splitQ[{0, 5}, radicands, {vx, vy}, p3] === False &&
   splitQ[{5, p3 - 5}, radicands, {vx, vy}, p3] === False];
FTAssert["a rational coefficient is reduced, not left as a rational remainder",
  splitQ[{6, 1}, {vx/3 + 1}, {vx, vy}, 1009] ===
    (JacobiSymbol[3, 1009] === 1) &&
   splitQ[{6, 1}, {vx/2 - 4}, {vx, vy}, 1009] ===
    (JacobiSymbol[-1, 1009] === 1)];
FTAssert["a coefficient denominator that vanishes mod p is a typed failure",
  splitQ[{1, 1}, {vx/3}, {vx, vy}, 3] === $Failed &&
   splitQ[{1, 1}, {vx + Sqrt[vy]}, {vx, vy}, p3] === $Failed &&
   splitQ[{1}, radicands, {vx, vy}, p3] === $Failed];

splitA = splitPts[{vx, vy}, radicands, p3, 4, 20260902, 500];
splitB = splitPts[{vx, vy}, radicands, p3, 4, 20260902, 500];
splitC = splitPts[{vx, vy}, radicands, p3, 4, 7, 500];
FTAssert["modularSplitPoints is deterministic in its seed",
  splitA === splitB && splitA["Status"] === "ModularSplitPointsV1" &&
   Length[splitA["Points"]] === 4 && IntegerQ[splitA["AttemptCount"]]];
FTAssert["a different seed gives different points",
  splitC["Status"] === "ModularSplitPointsV1" &&
   splitC["Points"] =!= splitA["Points"]];
FTAssert["every accepted point carries the independently evaluated root squares and verified roots",
  AllTrue[splitA["Points"],
   Function[record,
    record["RootSquares"] ===
      Mod[radicands /. Thread[{vx, vy} -> record["Point"]], p3] &&
     Mod[record["RootValues"]^2 - record["RootSquares"], p3] ===
      ConstantArray[0, Length[radicands]] &&
     FreeQ[record["RootSquares"], 0] &&
     AllTrue[record["Point"], 2 <= # <= p3 - 2 &] &&
     splitQ[record["Point"], radicands, {vx, vy}, p3] === True]]];
splitOne = splitPts[{vx, vy}, radicands, p1, 3, 20260902, 500];
FTAssert["p == 1 (mod 4) is admitted and its roots are verified",
  splitOne["Status"] === "ModularSplitPointsV1" &&
   Length[splitOne["Points"]] === 3 &&
   AllTrue[splitOne["Points"],
    Mod[#["RootValues"]^2 - #["RootSquares"], p1] ===
      ConstantArray[0, Length[radicands]] &]];
FTAssert["the attempt budget is respected and reported",
  With[{exhausted = splitPts[{vx, vy}, radicands, p3, 5, 1, 1]},
   exhausted["Status"] === "ModularSplitPointSearchExhausted" &&
    exhausted["AttemptCount"] === 1 && Length[exhausted["Points"]] <= 1]];
FTAssert["an invalid prime and invalid arguments are typed failures",
  splitPts[{vx, vy}, radicands, 4, 2, 1, 10]["Status"] ===
    "ModularSplitPointPrimeInvalid" &&
   splitPts[{vx, vy}, radicands, 3, 2, 1, 10]["Status"] ===
    "ModularSplitPointPrimeInvalid" &&
   splitPts[{}, radicands, p3, 2, 1, 10]["Status"] ===
    "ModularSplitPointArgumentsInvalid" &&
   splitPts[{vx, vy}, radicands, p3, 0, 1, 10] ===
    <|"Status" -> "ModularSplitPointsV1", "Prime" -> p3, "Points" -> {},
      "AttemptCount" -> 0|>];

(* ==================================================================
   G. prime schedules
   ================================================================== *)

descending = NestList[NextPrime[#, -1] &, NextPrime[2^31, -1], 11];
FTAssert["modularPrimes[31, 5] is the descending NextPrime schedule",
  primesOf[31, 5] === Take[descending, 5]];
FTAssert["the schedule is distinct, prime, and inside [2^30, 2^31)",
  With[{ps = primesOf[31, 8]},
   Length[ps] === 8 && DuplicateFreeQ[ps] && AllTrue[ps, PrimeQ] &&
    AllTrue[ps, 2^30 <= # < 2^31 &]]];
FTAssert["\"Exclude\" skips the named primes",
  primesOf[31, 3, "Exclude" -> Take[descending, 2]] ===
   Take[descending, {3, 5}]];
FTAssert["\"Residue3Mod4\" keeps only p == 3 (mod 4)",
  With[{ps = primesOf[31, 4, "Residue3Mod4" -> True]},
   ps === Take[Select[descending, Mod[#, 4] === 3 &], 4] &&
    AllTrue[ps, Mod[#, 4] === 3 &]]];
FTAssert["\"Avoid\" skips a prime dividing a declared denominator",
  primesOf[31, 2, "Avoid" -> {11 First[descending]}] ===
   Take[descending, {2, 3}] &&
   primesOf[31, 2, "Avoid" -> {First[descending] descending[[2]]}] ===
    Take[descending, {3, 4}] &&
   primesOf[31, 1, "Avoid" -> {0}] === $Failed];
FTAssert["a filter that rejects everything fails inside the candidate budget, not by walking the range",
  First[AbsoluteTiming[primesOf[31, 1, "Avoid" -> {0}]]] < 20 &&
   First[AbsoluteTiming[primesOf[31, 40, "Exclude" -> Take[descending, 12],
      "Residue3Mod4" -> True]]] < 20];
FTAssert["bad widths, counts and options are typed failures; zero primes is the empty list",
  primesOf[3, 100] === $Failed && primesOf[31, 0] === {} &&
   primesOf[1, 1] === $Failed && primesOf[31, -1] === $Failed &&
   primesOf[31, 2, "Residue3mod4" -> True] === $Failed &&
   primesOf[31, 2, "Exclude" -> 5] === $Failed &&
   primesOf[31, 2, "Avoid" -> {1/2}] === $Failed];
randomA = primesOf[24, 6, "Random" -> 20260902];
randomB = primesOf[24, 6, "Random" -> 20260902];
randomC = primesOf[24, 6, "Random" -> 5];
FTAssert["\"Random\" -> seed is deterministic, distinct and in range",
  randomA === randomB && Length[randomA] === 6 &&
   DuplicateFreeQ[randomA] && AllTrue[randomA, PrimeQ] &&
   AllTrue[randomA, 2^23 <= # < 2^24 &]];
FTAssert["a different random seed gives a different draw, and the filters still apply",
  randomC =!= randomA && ListQ[randomC] &&
   With[{filtered = primesOf[24, 5, "Random" -> 3, "Residue3Mod4" -> True],
     excluded = primesOf[24, 4, "Random" -> 20260902, "Exclude" -> randomA]},
    Length[filtered] === 5 &&
     AllTrue[filtered, PrimeQ[#] && Mod[#, 4] === 3 && 2^23 <= # < 2^24 &] &&
     Length[excluded] === 4 && DuplicateFreeQ[excluded] &&
     FreeQ[excluded, Alternatives @@ randomA]]];

{$Context, $ContextPath} = ftModularSavedContexts;
FTReport[];
