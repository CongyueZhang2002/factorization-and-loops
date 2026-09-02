(* One core implementation of the finite-field primitives that the
   package used to rebuild file by file (2026-09-02; the migration was
   completed in round 4 of the overhaul, 2026-09-02, after the Codex
   review of that morning found it partial).

   Production consumers (every one verified by reading the call site):
     modularRationalReconstruct  FiniteFieldEpsForm.wl
                                 (epsFormFiniteFieldRationalReconstruct),
                                 FamilyCertificateModular.wl
                                 (familyCertRationalReconstruct)
     modularCRT                  FiniteFieldEpsForm.wl
                                 (epsFormFiniteFieldCombineLists, hence
                                 ...CombineCoordinate and every lift built
                                 on it: DiagonalBlockEpsForm.wl,
                                 FiniteFieldGaugePullBack.wl,
                                 MultiquadraticStripSolve.wl)
     modularImageQ               FiniteFieldEpsForm.wl
                                 (epsFormFiniteFieldImageQ)
     modularSquareRoot(s)        MultiquadraticAlgebra.wl
                                 (multiquadraticSquareRoots, the
                                 multiquadratic ABI representative),
                                 FamilyCertificateModular.wl
                                 (familyCertMQSquareRoot),
                                 ObservableTransportFiniteField.wl, and
                                 through multiquadraticSquareRoots both
                                 screens of MultiquadraticStripSolve.wl
                                 (which carried their own (p+1)/4
                                 exponentiation until 2026-09-02)
     modularResidueQ             the split-point test of
                                 MultiquadraticStripSolve.wl at every
                                 sampling, preflight and sign-transform
                                 site (the inline JacobiSymbol idiom is
                                 gone from that file)
     modularPrimes               FiniteFieldStripSolve.wl
                                 (finiteFieldStripReservePrimes)
     modularLift                 no production caller yet.
                                 diagonalBlockLiftFunction
                                 (DiagonalBlockEpsForm.wl) and the
                                 coefficient lift of
                                 FiniteFieldGaugePullBack.wl ARE this
                                 composition (CRT, reconstruction at the
                                 product modulus, image check at every
                                 prime) on their padded coefficient
                                 lists; wiring them is reported to the
                                 owner of those files.  The regulator
                                 lift of MultiquadraticStripSolve.wl is
                                 NOT this function: it reports the
                                 position of every unreconstructible
                                 coefficient, which drives its
                                 prime-schedule extension.

   Production bodies deliberately retained (also documented in the
   consumer's header):
     - MultiquadraticStripSolve.wl evaluates a radicand at a point as an
       exact rational (Together) and reduces it once; a literal-by-
       literal reduction refuses a coefficient denominator divisible by
       p even when it cancels, and the solver needs the reduced
       radicands themselves, not only the verdict.
     - Its fresh-image primes are
       NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]] under
       RandomSeeding -> seed + 104729; the "Random" draw of
       modularPrimes is RandomPrime over [2^(bits-1), 2^bits) under
       SeedRandom[seed].  A different draw would rename the primes in
       every stored screen-evidence record, so the production draw
       stays.
   The split-point sampler and predicate (modularEvaluateAt,
   modularSplitPointQ, modularSplitPoints) have no production caller
   and no identical production body; they live, verbatim, in
   Scripts/Diagnostics/ModularSplitPoints.wl, loaded by
   Tests/FiniteField/t_modular_arithmetic.wls only.

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
   weaken the contract silently.

   Status (round 4, 2026-09-02): no production caller yet.  The
   production lifts are this composition written out --
   diagonalBlockLiftFunction (DiagonalBlockEpsForm.wl) and the
   coefficient lift of FiniteFieldGaugePullBack.wl on padded
   coefficient lists, both reported for wiring -- except the regulator
   lift of multiquadraticStripReconstructRegulator, which must report
   WHICH coefficients failed to reconstruct ("UnresolvedCoefficient-
   Locations" drives its prime-schedule extension) and therefore keeps
   its own loop over the same primitives. *)
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
   it belongs: modularResidueQ, the split-point test of every consumer,
   is False at zero (so is the diagnostic sampler of
   Scripts/Diagnostics/ModularSplitPoints.wl). *)
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

(* True iff a is a NONZERO quadratic residue mod p.  This is the
   split-point test of MultiquadraticStripSolve.wl at every sampling,
   preflight and sign-transform site: AllTrue[deltas,
   modularResidueQ[#, p] &] replaced the inline
   JacobiSymbol[#, p] === 1 idiom there on 2026-09-02 (identical for
   every odd prime, since JacobiSymbol[0, p] is 0; every entry gate of
   that file requires p > 3).  The test is the Jacobi symbol, so for an
   odd prime it is exact; for an odd composite modulus it is the Jacobi
   symbol and not a residuosity decision (a non-residue can still have
   symbol 1).  An even modulus or a modulus below 3 is a typed
   failure, not an answer. *)
modularResidueQ[value_Integer, modulus_Integer] :=
 If[modulus < 3 || EvenQ[modulus], $Failed,
  Mod[value, modulus] =!= 0 && JacobiSymbol[value, modulus] === 1];

modularResidueQ[___] := $Failed;

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
     "Below" -> b   start the descending schedule at the largest prime
                    <= b instead of at 2^bits - 1 (the strip solver's
                    reserve primes start below 2147483399)
     "Random" -> s  instead of the descending schedule, distinct
                    random primes in [2^(bits-1), 2^bits) drawn
                    deterministically from seed s (the certificate's
                    RandomPrime[{pLow, pHigh}] draw, made
                    reproducible). *)
Options[modularPrimes] = {
  "Exclude" -> {}, "Residue3Mod4" -> False, "Avoid" -> {},
  "Random" -> None, "Below" -> None
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
   candidate = With[{below = OptionValue[modularPrimes, given, "Below"]},
     If[IntegerQ[below] && below <= 2^bits, NextPrime[below + 1, -1],
       NextPrime[2^bits, -1]]];
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
