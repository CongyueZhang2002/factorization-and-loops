#!/usr/bin/env wolframscript
(* Exact identities of the neutral multiquadratic algebra
   (FeynFacet/Private/Core/MultiquadraticAlgebra.wl, 2026-08-23).

   Acceptance criteria, all exact and all stated before the run:
     - for every rank 0..3 the channel product equals the product of
       the composed expressions in the root symbols, and it is
       commutative and associative on nontrivial rational-function
       vectors;
     - the derivative satisfies Leibniz on the same vectors and equals
       the derivative of the composed expression (it must carry
       d(r_i)/r_i = dlog(delta_i)/2 for every active root);
     - the character table is its own inverse up to the group order and
       conjugate evaluation followed by projection is the identity,
       in characteristic zero and modulo two primes;
     - characteristic-zero arithmetic, reduced coordinate by coordinate
       to F_p, equals the arithmetic done in F_p, at two primes, and a
       rational coefficient vector handed to a modular entry point
       fails closed rather than being left unreduced (Mod on a Rational
       is the rational remainder, not the modular image);
     - polynomial reduction to the grade basis round trips, rank 0
       returns the sole rational channel, and a noninteger rational
       power is rejected rather than reported as a rational channel;
     - grade closure and the F2 active rank are the stated lattice
       values;
     - the ABI fingerprint is a 64-character hash that does not change
       between two loads of the module and does not change with the
       reader's $Context/$ContextPath (the probe must contain System`
       symbols only).
   The module is loaded directly, not through FeynFacet.m: it is not
   registered there yet. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FeynFacet`Private`feynFacetPrivateFile["MultiquadraticAlgebra.wl"]];
(* the strip solver is eight files since round 4 (2026-09-02); the manifest
   names them in load order *)
Get[FeynFacet`Private`feynFacetPrivateFile[#]] & /@
  Select[Lookup[Get[FileNameJoin[{root, "FeynFacet", "Private", "LoadOrder.wl"}]],
    "EpsForm"], StringStartsQ[FileNameTake[#], "MultiquadraticStrip"] &];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{basisMasks, maskFactor, hadamard, multiply, derivative, toExpression,
  fromPolynomial, evaluateConjugates, projectConjugates,
  squareRoots, gradeClosure, activeRank, abiFingerprint, algebraProbe} =
 mq /@ {"multiquadraticBasisMasks", "multiquadraticMaskFactor",
   "multiquadraticHadamardMatrix", "multiquadraticMultiply",
   "multiquadraticDerivative", "multiquadraticToExpression",
   "multiquadraticFromPolynomial", "multiquadraticEvaluateConjugates",
   "multiquadraticProjectConjugates",
   "multiquadraticSquareRoots", "multiquadraticGradeClosure",
   "multiquadraticActiveRank", "multiquadraticAlgebraABIFingerprint",
   "multiquadraticAlgebraProbe"};

Clear[x, y];
zeroQ[expression_] := AllTrue[Flatten[{expression}], TrueQ[Together[#] === 0] &];
allDeltas = {x, y, 1 + x + y};
allRoots = Sqrt /@ allDeltas;
(* coefficient vectors with a nontrivial denominator, so that Together
   is exercised and no channel is a bare monomial *)
vector[rank_, offset_] := Table[
  Together[((-1)^mask (offset + mask + 1) + (mask + 2) x + (offset + rank + 1) y)/
    (offset + mask + 3 + x + y)], {mask, 0, 2^rank - 1}];
primes = {10007, 1000003};

Do[
  Module[{deltas, roots, a, b, c, ab, ba, product},
    deltas = Take[allDeltas, rank];
    roots = Take[allRoots, rank];
    a = vector[rank, 2]; b = vector[rank, 7]; c = vector[rank, 13];
    ab = multiply[a, b, deltas];
    ba = multiply[b, a, deltas];
    check["rank " <> ToString[rank] <> ": product equals the composed product",
      Length[ab] === 2^rank &&
        zeroQ[toExpression[ab, roots] - toExpression[a, roots] toExpression[b, roots]]];
    check["rank " <> ToString[rank] <> ": product is commutative", zeroQ[ab - ba]];
    check["rank " <> ToString[rank] <> ": product is associative",
      zeroQ[multiply[ab, c, deltas] - multiply[a, multiply[b, c, deltas], deltas]]];
    check["rank " <> ToString[rank] <> ": derivative equals the composed derivative",
      zeroQ[toExpression[derivative[a, deltas, x], roots] -
        D[toExpression[a, roots], x]]];
    check["rank " <> ToString[rank] <> ": derivative satisfies Leibniz",
      zeroQ[derivative[ab, deltas, x] -
        (multiply[derivative[a, deltas, x], b, deltas] +
         multiply[a, derivative[b, deltas, x], deltas])]];
    check["rank " <> ToString[rank] <> ": character table is its own inverse",
      hadamard[rank] . hadamard[rank] === 2^rank IdentityMatrix[2^rank]];
    check["rank " <> ToString[rank] <> ": conjugate round trip in characteristic zero",
      zeroQ[projectConjugates[evaluateConjugates[a, roots], roots] - a]];
    product = fromPolynomial[
      Expand[toExpression[a, roots] toExpression[b, roots] /.
        Thread[roots -> Take[{\[FormalR], \[FormalS], \[FormalT]}, rank]]],
      Take[{\[FormalR], \[FormalS], \[FormalT]}, rank], deltas];
    check["rank " <> ToString[rank] <> ": polynomial reduction returns the channels",
      ListQ[product] && zeroQ[product - ab]];
  ],
  {rank, 0, 3}];

(* Characteristic zero, reduced coordinate by coordinate to F_p, equals
   the arithmetic done in F_p.  The reduction is the strip module's
   rational-to-field map, which is what every modular consumer applies
   before entering the algebra. *)
reduce[values_, prime_] :=
  FeynFacet`Private`multiquadraticStripModRational[#, prime] & /@ Flatten[{values}];
Do[
  Module[{deltas, a, b, exact, image, values, rootValues},
    deltas = Take[{3, 5, 7}, rank];
    a = Table[(mask + 2)/(mask + 3), {mask, 0, 2^rank - 1}];
    b = Table[(-1)^mask (mask + 5)/(2 mask + 7), {mask, 0, 2^rank - 1}];
    exact = multiply[a, b, deltas];
    image = multiply[reduce[a, prime], reduce[b, prime], deltas, prime];
    check["rank " <> ToString[rank] <> " mod " <> ToString[prime] <>
      ": product agrees with characteristic zero",
      reduce[exact, prime] === image];
    rootValues = Take[{4, 9, 25}, rank];
    values = evaluateConjugates[reduce[a, prime], rootValues, prime];
    check["rank " <> ToString[rank] <> " mod " <> ToString[prime] <>
      ": conjugate evaluation agrees with characteristic zero",
      reduce[evaluateConjugates[a, rootValues], prime] === values];
    check["rank " <> ToString[rank] <> " mod " <> ToString[prime] <>
      ": conjugate projection inverts evaluation",
      projectConjugates[values, rootValues, prime] === reduce[a, prime]];
  ],
  {rank, 0, 3}, {prime, primes}];

check["a rational vector handed to the modular product fails closed",
  multiply[{2/3, 1}, {1, 1}, {5}, 10007] === $Failed];
check["a rational vector handed to modular conjugate evaluation fails closed",
  evaluateConjugates[{2/3, 1}, {4}, 10007] === $Failed &&
    projectConjugates[{2/3, 1}, {4}, 10007] === $Failed];

check["rank 0 reduction returns the sole rational channel",
  fromPolynomial[(1 + x)/y, {}, {}] === {(1 + x)/y}];
check["rank 0 reduction rejects a noninteger rational power",
  fromPolynomial[Sqrt[x], {}, {}] === $Failed];
check["rank 1 reduction rejects a noninteger rational power",
  fromPolynomial[\[FormalR] Sqrt[y], {\[FormalR]}, {x}] === $Failed];
check["mask factor selects the bits of the mask",
  maskFactor[0, {2, 3, 5}] === 1 && maskFactor[5, {2, 3, 5}] === 10 &&
    maskFactor[7, {2, 3, 5}] === 30 && maskFactor[0, {}] === 1];
check["basis masks enumerate the grade lattice",
  basisMasks[0] === {0} && basisMasks[3] === Range[0, 7]];

check["grade closure is the xor closure of the generators",
  gradeClosure[{0}, {3, 5}] === {0, 3, 5, 6} &&
    gradeClosure[{1}, {}] === {1} &&
    gradeClosure[{0}, {1, 2, 4}] === Range[0, 7]];
check["active rank is the F2 rank of the grade masks",
  activeRank[{}, 3] === 0 && activeRank[{0}, 3] === 0 &&
    activeRank[{1, 2, 4}, 3] === 3 && activeRank[{1, 2, 3}, 3] === 2 &&
    activeRank[{3, 5, 6}, 3] === 2];

(* the split-point test at every production site is the shared
   modularResidueQ (Core/ModularArithmetic.wl) on the solver's reduced
   radicands: a NONZERO quadratic residue for every root square.  The
   former multiquadraticSplitPointQ alias had no caller and lives in
   Private_Backup (2026-09-02, N8); the sampler modularSplitPointQ /
   modularSplitPoints has no production caller and lives in
   Scripts/Diagnostics/ModularSplitPoints.wl (round 4, 2026-09-02). *)
check["split point test accepts a point with all radicands square",
  AllTrue[Mod[{2, 3, 2 3}, 23], TrueQ[mq["modularResidueQ"][#, 23]] &] ===
    (JacobiSymbol[2, 23] == 1 && JacobiSymbol[3, 23] == 1 &&
      JacobiSymbol[6, 23] == 1)];
check["split point test rejects a vanishing radicand",
  mq["modularResidueQ"][0, 23] === False &&
    AllTrue[Mod[{0, 3}, 23], TrueQ[mq["modularResidueQ"][#, 23]] &] === False];
check["modular square roots invert squaring for p = 3 mod 4",
  Module[{values = {4, 9, 25}, p = 103, r},
    r = squareRoots[values, p];
    ListQ[r] && Mod[r^2 - values, p] === {0, 0, 0}]];
check["modular square roots fail closed on a nonresidue",
  squareRoots[{5}, 103] === $Failed && JacobiSymbol[5, 103] === -1];
check["modular square roots accept the empty rank-0 list",
  squareRoots[{}, 103] === {}];

(* ABI fingerprint: stable across loads and independent of context *)
firstFingerprint = abiFingerprint[];
check["ABI fingerprint is a SHA256 hex string",
  StringQ[firstFingerprint] && StringLength[firstFingerprint] === 64 &&
    StringMatchQ[firstFingerprint, RegularExpression["[0-9a-f]{64}"]]];
check["ABI probe contains System` symbols only",
  AllTrue[DeleteDuplicates[Cases[algebraProbe[], symbol_Symbol :> symbol,
    {0, Infinity}, Heads -> True]], Context[#] === "System`" &]];
check["ABI fingerprint does not depend on the reader's context",
  Block[{$Context = "Global`", $ContextPath = {"System`"}},
      abiFingerprint[]] === firstFingerprint &&
    Block[{$Context = "FeynFacet`MultiquadraticProbe`",
        $ContextPath = {"System`", "FeynFacet`MultiquadraticProbe`"}},
      abiFingerprint[]] === firstFingerprint];
Get[FeynFacet`Private`feynFacetPrivateFile["MultiquadraticAlgebra.wl"]];
check["ABI fingerprint is stable across two loads of the module",
  abiFingerprint[] === firstFingerprint];
check["the strip module records the same algebra ABI fingerprint",
  FeynFacet`Private`multiquadraticAlgebraABIFingerprint[] === firstFingerprint];

Print["t_multiquadratic_algebra: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
