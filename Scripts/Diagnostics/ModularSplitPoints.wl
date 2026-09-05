(* Scripts/Diagnostics/ModularSplitPoints.wl -- the split-point sampler
   and predicate of the 2026-09-02 finite-field consolidation, moved out
   of FeynFacet/Private/Core/Modular/ModularArithmetic.wl in round 4 (2026-09-02)
   because they have NO production caller and no identical production
   body: MultiquadraticOffDiagonalBlockSolve.wl evaluates a radicand at a point as an
   exact rational (multiquadraticOffDiagonalBlockModRational: Together, then ONE
   reduction) and needs the reduced radicands themselves for the roots,
   whereas modularEvaluateAt below reduces literal by literal and refuses
   a coefficient denominator divisible by p even when it cancels; and the
   solver's point sampling is interleaved with row assembly, not a
   stand-alone search.  The production split-point test is
   modularResidueQ on the reduced radicands (Core/ModularArithmetic.wl).

   Reference API, exercised by Tests/FiniteField/t_modular_arithmetic.wls
   (sections F), which loads this file explicitly.  Not loaded by the
   package.  The three definitions are verbatim (pure move); they depend
   on modularResidueQ and modularSquareRoot of ModularArithmetic.wl, so
   load the package (or that file) first. *)

Begin["FeynFacet`Private`"];

ClearAll[modularEvaluateAt, modularSplitPointQ, modularSplitPoints];

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

End[];
