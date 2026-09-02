(* One core implementation of the finite-field primitives that the
   package currently rebuilds file by file (2026-09-02).

   Wired consumers (2026-09-02, after the review's note N2):
   FiniteFieldEpsForm.wl (epsFormFiniteFieldRationalReconstruct,
   ...CombineLists, ...ImageQ, and ...CombineCoordinate /
   DiagonalBlockEpsForm.wl's diagonalBlockLiftFunction through them),
   FamilyCertificateModular.wl (familyCertRationalReconstruct,
   familyCertMQSquareRoot), MultiquadraticAlgebra.wl
   (multiquadraticSquareRoots, multiquadraticSplitPointQ),
   ObservableTransportFiniteField.wl (modularSquareRoot for the
   numeric radical constants).
   NOT yet wired (deliberately, see the overhaul plan): the split-point
   sampler of PathTransportNative.wl and the prime schedules of
   FiniteFieldStripSolve.wl keep their own bodies; modularLift,
   modularResidueQ, modularSplitPoints and modularPrimes are the
   reference API for them, exercised by
   Tests/FiniteField/t_modular_arithmetic.wls only.  This file
   reproduces the consumers' semantics exactly where they agree and
   states, at each definition, the one place where they do not.

   Every failure is TYPED: $Failed, or an Association carrying
   "Status".  Nothing here prints, and no expected failure reaches a
   Wolfram message: PowerMod on a non-unit and ChineseRemainder on an
   inconsistent system are pre-checked, never caught after the fact.
   No user expression is passed through Together or Simplify. *)

Begin["FeynFacet`Private`"];

ClearAll[
  modularRationalReconstruct,
  modularCRT,
  modularImageQ,
  modularLift,
  modularTonelliShanks,
  modularSquareRoot,
  modularSquareRoots,
  modularResidueQ,
  modularEvaluateAt,
  modularSplitPointQ,
  modularSplitPoints,
  modularPrimes
];

(* ------------------------------------------------------------------
   Rational reconstruction (Wang)
   ------------------------------------------------------------------

   modularRationalReconstruct[a, m] returns the unique rational n/d
   with |n| <= B, 0 < d <= B, gcd(n, d) = 1 and n == a d (mod m), for
   the symmetric bound B = Floor[Sqrt[(m - 1)/2]], and $Failed when no
   such rational exists.  a == 0 (mod m) returns the integer 0.

   This is epsFormFiniteFieldRationalReconstruct verbatim, including
   the two checks that familyCertRationalReconstruct omits: the
   numerator bound and the residual Mod[n - a d, m] == 0.  Both are
   loop invariants of the extended Euclidean scheme (r_k <= B on exit,
   and r_k == t_k a (mod m) throughout), so the two existing
   implementations return the same value on every input; they are kept
   because the residual is what makes gcd(d, m) = 1 provable
   (g = gcd(d, m) divides n and d, hence divides gcd(n, d) = 1), which
   is what lets a caller use the result at each prime of a composite
   modulus.

   The sign is normalized to a positive denominator.  Wolfram
   normalizes Rational signs anyway, so this only affects which bound
   the denominator is tested against. *)
modularRationalReconstruct[value_Integer, modulus_Integer] :=
 Module[{a, bound, r0, r1, t0 = 0, t1 = 1, quotient, num, den},
  If[modulus < 1, Return[$Failed]];
  a = Mod[value, modulus];
  If[a === 0, Return[0]];
  bound = Floor[Sqrt[(modulus - 1)/2]];
  {r0, r1} = {modulus, a};
  While[r1 > bound,
   quotient = Quotient[r0, r1];
   {r0, r1} = {r1, r0 - quotient r1};
   {t0, t1} = {t1, t0 - quotient t1}];
  {num, den} = {r1, t1};
  If[den < 0, {num, den} = {-num, -den}];
  If[den === 0 || Abs[num] > bound || den > bound ||
    CoprimeQ[num, den] =!= True || Mod[num - a den, modulus] =!= 0,
   $Failed,
   num/den]
 ];

(* Explicit asymmetric bounds: |n| <= nBound, 0 < d <= dBound.
   Uniqueness of such a preimage needs 2 nBound dBound < m, so an
   ambiguous request is a typed failure rather than an arbitrary
   choice.  The Euclidean scheme is stopped at the NUMERATOR bound;
   the denominator bound is a filter on the result. *)
modularRationalReconstruct[value_Integer, modulus_Integer,
   {nBound_Integer, dBound_Integer}] :=
 Module[{a, r0, r1, t0 = 0, t1 = 1, quotient, num, den},
  If[modulus < 1 || nBound < 0 || dBound < 1 ||
    2 nBound dBound >= modulus, Return[$Failed]];
  a = Mod[value, modulus];
  If[a === 0, Return[0]];
  {r0, r1} = {modulus, a};
  While[r1 > nBound,
   quotient = Quotient[r0, r1];
   {r0, r1} = {r1, r0 - quotient r1};
   {t0, t1} = {t1, t0 - quotient t1}];
  {num, den} = {r1, t1};
  If[den < 0, {num, den} = {-num, -den}];
  If[den === 0 || Abs[num] > nBound || den > dBound ||
    CoprimeQ[num, den] =!= True || Mod[num - a den, modulus] =!= 0,
   $Failed,
   num/den]
 ];

modularRationalReconstruct[___] := $Failed;

(* ------------------------------------------------------------------
   Chinese remaindering
   ------------------------------------------------------------------

   modularCRT[{r1, ..., rk}, {m1, ..., mk}] is the smallest
   nonnegative solution of x == ri (mod mi), which lies in
   [0, Times @@ moduli) for coprime moduli, and $Failed when the
   system is inconsistent or the arguments do not match.  Consistency
   is decided BEFORE calling ChineseRemainder, so an inconsistent
   system never emits a message.

   modularCRT[{list1, ..., listk}, moduli] combines coordinate by
   coordinate, padding shorter lists with 0 to the longest length.
   That is epsFormFiniteFieldCombineLists with the length inferred
   instead of passed (that function takes the length from the degree
   record its caller already validated). *)
modularCRT[residues : {__Integer}, moduli : {__Integer}] :=
 Module[{result},
  If[Length[residues] =!= Length[moduli] ||
    ! AllTrue[moduli, IntegerQ[#] && # > 0 &], Return[$Failed]];
  If[! AllTrue[Subsets[Range[Length[moduli]], {2}],
     Function[pair,
      Mod[residues[[First[pair]]] - residues[[Last[pair]]],
        GCD[moduli[[First[pair]]], moduli[[Last[pair]]]]] === 0]],
   Return[$Failed]];
  result = ChineseRemainder[residues, moduli];
  If[IntegerQ[result] && result >= 0, result, $Failed]
 ];

modularCRT[lists : {__List}, moduli : {__Integer}] :=
 Module[{length, padded, combined},
  If[Length[lists] =!= Length[moduli] ||
    ! AllTrue[moduli, IntegerQ[#] && # > 0 &] ||
    ! AllTrue[lists, AllTrue[#, IntegerQ] &], Return[$Failed]];
  length = Max[Append[Length /@ lists, 0]];
  If[length === 0, Return[{}]];
  padded = PadRight[#, length] & /@ lists;
  combined = Table[modularCRT[padded[[All, index]], moduli],
    {index, length}];
  If[MemberQ[combined, $Failed], $Failed, combined]
 ];

modularCRT[___] := $Failed;

(* ------------------------------------------------------------------
   Modular image of a rational
   ------------------------------------------------------------------

   modularImageQ[k, r, m] is True exactly when the denominator of r is
   a unit mod m and r == k (mod m).  epsFormFiniteFieldImageQ decides
   the unit condition by Mod[Denominator[r], m] =!= 0, which is the
   same statement for a PRIME m but not for a composite one (it would
   then call PowerMod on a non-unit and emit a message).  This version
   uses CoprimeQ, so it is also correct at a CRT modulus. *)
modularImageQ[integer_Integer, rational_, modulus_Integer] :=
 Module[{den},
  If[modulus < 1 || ! IntegerQ[Numerator[rational]] ||
    ! IntegerQ[Denominator[rational]], Return[False]];
  den = Denominator[rational];
  CoprimeQ[den, modulus] &&
   Mod[Numerator[rational] PowerMod[den, -1, modulus], modulus] ===
    Mod[integer, modulus]
 ];

modularImageQ[___] := $Failed;

(* ------------------------------------------------------------------
   Lift and verify
   ------------------------------------------------------------------

   modularLift[{images at p1, images at p2, ...}, {p1, p2, ...}]
   reconstructs one rational per coordinate: Chinese remaindering
   across the primes, rational reconstruction at the product modulus,
   then the diagonalBlockLiftFunction verification of every
   reconstructed rational against its image at EVERY prime.  Returns
   the list of rationals, or $Failed if any coordinate fails.

   The verification is defence in depth, not a filter: the residual
   check inside modularRationalReconstruct already forces
   gcd(denominator, Times @@ primes) = 1 and congruence at the product
   modulus, so a reconstruction that returns a rational always passes
   it.  It is kept so that a future reconstruction backend cannot
   weaken the contract silently. *)
modularLift[imagesByPrime : {__List}, primes : {__Integer}] :=
 Module[{count, modulus, combined, rationals, transposed},
  If[Length[imagesByPrime] =!= Length[primes] ||
    ! AllTrue[primes, PrimeQ] || ! DuplicateFreeQ[primes] ||
    Length[DeleteDuplicates[Length /@ imagesByPrime]] =!= 1 ||
    ! AllTrue[Flatten[imagesByPrime], IntegerQ], Return[$Failed]];
  count = Length[First[imagesByPrime]];
  If[count === 0, Return[{}]];
  modulus = Times @@ primes;
  combined = Table[modularCRT[imagesByPrime[[All, index]], primes],
    {index, count}];
  If[MemberQ[combined, $Failed], Return[$Failed]];
  rationals = modularRationalReconstruct[#, modulus] & /@ combined;
  If[MemberQ[rationals, $Failed], Return[$Failed]];
  transposed = Transpose[imagesByPrime];
  (* explicit Function variables: a nested slot would bind to the prime *)
  If[! (And @@ MapThread[
      Function[{images, rational},
       And @@ MapThread[
         Function[{image, prime}, TrueQ[modularImageQ[image, rational, prime]]],
         {images, primes}]],
      {transposed, rationals}]),
   Return[$Failed]];
  rationals
 ];

modularLift[___] := $Failed;

(* ------------------------------------------------------------------
   Square roots in F_p
   ------------------------------------------------------------------

   modularSquareRoot[a, p] returns a square root of a in [0, p), or
   $Failed if a is a nonzero non-residue or p is not an odd prime.
   a == 0 returns 0.

   p == 3 (mod 4) takes the one-exponentiation path and returns the
   RAW representative PowerMod[a, (p+1)/4, p], not the smaller of the
   two roots: that sign representative is the multiquadratic ABI
   (MultiquadraticAlgebra.wl).  Every other odd prime goes through
   Tonelli-Shanks with the smallest non-residue as the generator, so
   the representative is deterministic there too.  The square is
   always verified.

   The two existing implementations DISAGREE at zero:
   multiquadraticSquareRoots accepts 0 and returns 0, while
   familyCertMQSquareRoot rejects it (a zero root square collapses two
   sign embeddings, so the certificate's split points must avoid it).
   This file follows multiquadraticSquareRoots -- zero is a legitimate
   square root question -- and enforces the certificate's rule where
   it belongs, in modularSplitPointQ / modularSplitPoints, both of
   which reject a zero radicand. *)
modularTonelliShanks[a_Integer, p_Integer] :=
 Module[{q, s = 0, z, c, t, r, m, i, b, tag},
  tag = "modularTonelliShanks";
  Catch[
   q = p - 1;
   While[EvenQ[q], q = q/2; s++];
   z = 2;
   While[z < p && JacobiSymbol[z, p] =!= -1, z++];
   If[z >= p, Throw[$Failed, tag]];
   c = PowerMod[z, q, p];
   t = PowerMod[a, q, p];
   r = PowerMod[a, (q + 1)/2, p];
   m = s;
   While[t =!= 1,
    If[t === 0, Throw[$Failed, tag]];
    i = 0; b = t;
    While[b =!= 1,
     b = Mod[b^2, p]; i++;
     If[i >= m, Throw[$Failed, tag]]];
    b = PowerMod[c, 2^(m - i - 1), p];
    r = Mod[r b, p];
    c = Mod[b^2, p];
    t = Mod[t c, p];
    m = i];
   r,
   tag]
 ];

modularTonelliShanks[___] := $Failed;

modularSquareRoot[value_Integer, prime_Integer] :=
 Module[{a, root},
  If[! PrimeQ[prime] || prime === 2, Return[$Failed]];
  a = Mod[value, prime];
  If[a === 0, Return[0]];
  If[PowerMod[a, Quotient[prime - 1, 2], prime] =!= 1, Return[$Failed]];
  root = If[Mod[prime, 4] === 3,
    PowerMod[a, Quotient[prime + 1, 4], prime],
    modularTonelliShanks[a, prime]];
  If[IntegerQ[root] && Mod[root^2 - a, prime] === 0, root, $Failed]
 ];

modularSquareRoot[___] := $Failed;

(* One root per value, or $Failed if any value fails.  For
   p == 3 (mod 4) this is multiquadraticSquareRoots, representative by
   representative, and it also serves p == 1 (mod 4). *)
modularSquareRoots[values_List, prime_Integer] :=
 Module[{roots},
  If[! AllTrue[values, IntegerQ], Return[$Failed]];
  roots = modularSquareRoot[#, prime] & /@ values;
  If[MemberQ[roots, $Failed], $Failed, roots]
 ];

modularSquareRoots[___] := $Failed;

(* True iff a is a NONZERO quadratic residue mod p.  The test is the
   Jacobi symbol, as in multiquadraticSplitPointQ, so for an odd prime
   it is exact; for an odd composite modulus it is the Jacobi symbol
   and not a residuosity decision (a non-residue can still have
   symbol 1).  An even modulus or a modulus below 3 is a typed
   failure, not an answer. *)
modularResidueQ[value_Integer, modulus_Integer] :=
 If[modulus < 3 || EvenQ[modulus], $Failed,
  Mod[value, modulus] =!= 0 && JacobiSymbol[value, modulus] === 1];

modularResidueQ[___] := $Failed;

(* ------------------------------------------------------------------
   Split points
   ------------------------------------------------------------------

   modularEvaluateAt[expression, <|var -> value, ...|>, p] reduces a
   polynomial or rational expression in the given variables to F_p.
   It is the scalar part of blockEquationDeferredModEvaluate: integer
   and RATIONAL literals (Mod on a Rational is the rational
   remainder, never the modular image -- the trap that
   multiquadraticCharacteristicNormalize fails closed on), Plus,
   Times, integer Power, and assigned symbols.  A denominator that
   vanishes mod p, an unassigned symbol, a zero base at a negative
   exponent and any other head are $Failed. *)
modularEvaluateAt[expression_, values_Association, prime_Integer] :=
 Module[{tag, walk},
  If[! IntegerQ[prime] || prime < 2, Return[$Failed]];
  tag = "modularEvaluateAt";
  walk[node_] := Which[
    IntegerQ[node], Mod[node, prime],
    Head[node] === Rational,
     Module[{den = Mod[Denominator[node], prime]},
      If[den === 0, Throw[$Failed, tag]];
      Mod[Numerator[node] PowerMod[den, -1, prime], prime]],
    MatchQ[node, _Symbol],
     If[KeyExistsQ[values, node], walk[values[node]], Throw[$Failed, tag]],
    Head[node] === Plus,
     Fold[Mod[#1 + walk[#2], prime] &, 0, List @@ node],
    Head[node] === Times,
     Fold[Mod[#1 walk[#2], prime] &, 1, List @@ node],
    MatchQ[node, Power[_, _Integer]],
     Module[{base = walk[First[node]], exponent = Last[node]},
      If[base === 0 && exponent < 0, Throw[$Failed, tag]];
      PowerMod[base, exponent, prime]],
    True, Throw[$Failed, tag]];
  Catch[walk[expression], tag]
 ];

modularEvaluateAt[___] := $Failed;

(* True iff every radicand, evaluated at the point, is a nonzero
   quadratic residue mod p -- multiquadraticSplitPointQ for any number
   of variables and radicands, with rational coefficients reduced
   properly instead of left as rational remainders.  $Failed when a
   coefficient denominator vanishes mod p, when a radicand is not
   evaluable, or when the modulus is invalid. *)
modularSplitPointQ[point_List, radicands_List, variables_List,
   prime_Integer] :=
 Module[{rules, evaluated, residues},
  If[Length[point] =!= Length[variables] ||
    ! AllTrue[variables, MatchQ[#, _Symbol] &] ||
    ! AllTrue[point, IntegerQ[#] || Head[#] === Rational &],
   Return[$Failed]];
  rules = AssociationThread[variables, point];
  evaluated = modularEvaluateAt[#, rules, prime] & /@ radicands;
  If[! FreeQ[evaluated, $Failed], Return[$Failed]];
  residues = modularResidueQ[#, prime] & /@ evaluated;
  If[! FreeQ[residues, $Failed], Return[$Failed]];
  AllTrue[residues, TrueQ]
 ];

modularSplitPointQ[___] := $Failed;

(* pathTransportNativeSplitPoints with two changes: the radicands are
   evaluated by modularEvaluateAt instead of the deferred-DAG
   evaluator, and the roots are taken by modularSquareRoot, so a prime
   p == 1 (mod 4) is admitted (the native version refuses every prime
   outside 3 mod 4 because it hard-codes the (p+1)/4 exponent).

   Determinism is the ABI: the same seed yields the same candidate
   sequence, hence the same accepted points and the same
   AttemptCount.  A zero radicand is rejected, as in the native
   version and in the certificate. *)
modularSplitPoints[variables : {__Symbol}, radicands_List,
   prime_Integer, count_Integer, seed_Integer,
   maximumAttempts_Integer] :=
 Module[{points = {}, attempts = 0, candidate, rules, deltas, roots},
  If[! PrimeQ[prime] || prime <= 3 || count < 0 || maximumAttempts < 0,
   Return[<|"Status" -> "ModularSplitPointPrimeInvalid",
     "Prime" -> prime, "RadicandCount" -> Length[radicands]|>]];
  BlockRandom[
   SeedRandom[seed, Method -> "MersenneTwister"];
   While[Length[points] < count && attempts < maximumAttempts,
    attempts++;
    candidate = RandomInteger[{2, prime - 2}, Length[variables]];
    rules = AssociationThread[variables, candidate];
    deltas = modularEvaluateAt[#, rules, prime] & /@ radicands;
    If[FreeQ[deltas, $Failed] && FreeQ[deltas, 0],
     roots = modularSquareRoot[#, prime] & /@ deltas;
     If[FreeQ[roots, $Failed],
      AppendTo[points,
       <|"Point" -> candidate, "RootSquares" -> deltas,
         "RootValues" -> roots|>]]]]];
  If[Length[points] === count,
   <|"Status" -> "ModularSplitPointsV1", "Prime" -> prime,
     "Points" -> points, "AttemptCount" -> attempts|>,
   <|"Status" -> "ModularSplitPointSearchExhausted", "Prime" -> prime,
     "Points" -> points, "AcceptedPointCount" -> Length[points],
     "RequestedPointCount" -> count, "AttemptCount" -> attempts|>]
 ];

modularSplitPoints[___] :=
  <|"Status" -> "ModularSplitPointArgumentsInvalid"|>;

(* ------------------------------------------------------------------
   Prime schedules
   ------------------------------------------------------------------

   modularPrimes[bits, count] is the deterministic schedule the strip
   solver uses: the largest prime below 2^bits, then downward through
   NextPrime[..., -1] (2147483647, 2147483629, ... for bits = 31).
   $Failed if count such primes do not exist.

   BOTH searches are bounded by the same candidate budget,
   1000 + 200 count.  Without it a filter that rejects everything --
   "Avoid" -> {0} is the extreme case, and a narrow "Residue3Mod4" plus
   "Exclude" is the realistic one -- walks every prime down to
   2^(bits-1): 49 million NextPrime steps at bits = 31, eight minutes
   of kernel time for a call whose answer is "no".  The budget is a
   typed failure, not a silent truncation, and it is far above any
   real schedule (the strip solver takes eleven primes).

   Options
     "Exclude"      primes to skip (a reserve prime must stay unseen,
                    as in finiteFieldStripReservePrimes)
     "Residue3Mod4" True keeps only p == 3 (mod 4), the multiquadratic
                    ABI's square-root path
     "Avoid"        integers none of which may vanish mod p -- the
                    denominators that must stay units
     "Random" -> s  instead of the descending schedule, distinct
                    random primes in [2^(bits-1), 2^bits) drawn
                    deterministically from seed s (the certificate's
                    RandomPrime[{pLow, pHigh}] draw, made
                    reproducible). *)
Options[modularPrimes] = {
  "Exclude" -> {}, "Residue3Mod4" -> False, "Avoid" -> {},
  "Random" -> None
};

modularPrimes[bits_Integer, count_Integer, opts : OptionsPattern[]] :=
 Module[{given, exclude, residue3, avoid, seed, chosen = {}, acceptQ,
   candidate, floor, attempts, limit},
  given = Flatten[{opts}];
  If[! AllTrue[given,
     MatchQ[#, Rule[_String, _]] &&
      MemberQ[Keys[Options[modularPrimes]], First[#]] &],
   Return[$Failed]];
  exclude = OptionValue[modularPrimes, given, "Exclude"];
  residue3 = OptionValue[modularPrimes, given, "Residue3Mod4"];
  avoid = OptionValue[modularPrimes, given, "Avoid"];
  seed = OptionValue[modularPrimes, given, "Random"];
  If[bits < 2 || count < 0 || ! ListQ[exclude] || ! ListQ[avoid] ||
    ! AllTrue[exclude, IntegerQ] || ! AllTrue[avoid, IntegerQ] ||
    ! MemberQ[{True, False}, residue3], Return[$Failed]];
  If[count === 0, Return[{}]];
  floor = 2^(bits - 1);
  acceptQ[p_] := ! MemberQ[exclude, p] && ! MemberQ[chosen, p] &&
    (! TrueQ[residue3] || Mod[p, 4] === 3) &&
    AllTrue[avoid, Mod[#, p] =!= 0 &];
  attempts = 0;
  limit = 200 count + 1000;
  If[seed === None,
   candidate = NextPrime[2^bits, -1];
   While[Length[chosen] < count && candidate >= floor && attempts < limit,
    attempts++;
    If[acceptQ[candidate], AppendTo[chosen, candidate]];
    candidate = NextPrime[candidate, -1]],
   If[! IntegerQ[seed], Return[$Failed]];
   BlockRandom[
    SeedRandom[seed, Method -> "MersenneTwister"];
    While[Length[chosen] < count && attempts < limit,
     attempts++;
     candidate = RandomPrime[{floor, 2^bits - 1}];
     If[IntegerQ[candidate] && acceptQ[candidate],
      AppendTo[chosen, candidate]]]]];
  If[Length[chosen] === count, chosen, $Failed]
 ];

modularPrimes[___] := $Failed;

End[];
