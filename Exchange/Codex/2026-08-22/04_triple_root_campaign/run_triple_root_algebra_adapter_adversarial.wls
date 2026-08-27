#!/usr/bin/env wolframscript
(* Adversarial algebra identities for ranks zero through three.  This test is
   deliberately independent of the CF300 oracle and reconstruction code. *)

$HistoryLength = 0;
exchangeDirectory = DirectoryName[$InputFileName];
projectRoot = Nest[DirectoryName, $InputFileName, 4];

Get[FileNameJoin[{exchangeDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchangeDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{projectRoot, "Tests", "TestKit.wl"}]];

Clear[x, y, r1, r2, r3];
deltas = {x, y, 1 + x + y};
rootSymbols = {Sqrt[x], Sqrt[y], Sqrt[1 + x + y]};
roots = MapThread[
  <|"Root" -> #1, "RootSquare" -> #2|> &,
  {rootSymbols, deltas}];

exactZeroQ[expression_] := AllTrue[
  Flatten[{expression}], TrueQ[Together[#1] === 0] &];
exactVectorQ[left_List, right_List] :=
  Dimensions[left] === Dimensions[right] && exactZeroQ[left - right];

rankCoefficients[rank_Integer, offset_Integer] := Table[
  Together[
    ((-1)^mask (offset + mask + 1) + (mask + 2) x +
        (offset + rank + 1) y)/(offset + mask + 3 + x + y)],
  {mask, 0, 2^rank - 1}];

(* The character table is its own inverse up to the group order. *)
Do[
  hadamard = CodexTripleRoot`TRHadamardMatrix[rank];
  FTTest`FTAssert[
    "Hadamard involution at rank " <> ToString[rank],
    hadamard . hadamard === 2^rank IdentityMatrix[2^rank]];
  FTTest`FTAssert[
    "Hadamard inverse at rank " <> ToString[rank],
    exactZeroQ[Inverse[hadamard] - hadamard/2^rank]],
  {rank, 0, 3}];

(* Multiplication in channel space must agree with multiplication after
   composing the square-root basis. *)
Do[
  activeDeltas = Take[deltas, rank];
  activeRootSymbols = Take[rootSymbols, rank];
  leftChannels = rankCoefficients[rank, 2];
  rightChannels = rankCoefficients[rank, 7];
  multiplied = CodexTripleRoot`TRMultiply[
    leftChannels, rightChannels, activeDeltas];
  FTTest`FTAssert[
    "multiplication agrees with composition at rank " <> ToString[rank],
    Length[multiplied] === 2^rank && exactZeroQ[
      CodexTripleRoot`TRToExpression[multiplied, activeRootSymbols] -
        CodexTripleRoot`TRToExpression[leftChannels, activeRootSymbols]
          CodexTripleRoot`TRToExpression[
            rightChannels, activeRootSymbols]]],
  {rank, 0, 3}];

(* TRDerivative includes the derivative of every active radical. *)
Do[
  activeDeltas = Take[deltas, rank];
  activeRootSymbols = Take[rootSymbols, rank];
  derivativeInput = rankCoefficients[rank, 11];
  differentiated = CodexTripleRoot`TRDerivative[
    derivativeInput, activeDeltas, x];
  FTTest`FTAssert[
    "derivative agrees with differentiated composition at rank " <>
      ToString[rank],
    Length[differentiated] === 2^rank && exactZeroQ[
      CodexTripleRoot`TRToExpression[
        differentiated, activeRootSymbols] -
      D[CodexTripleRoot`TRToExpression[
        derivativeInput, activeRootSymbols], x]]],
  {rank, 0, 3}];

(* Exact conjugate evaluation/projection over characteristic zero. *)
Do[
  exactCoefficients = Table[
    (-1)^mask (2 mask + rank + 3)/(mask + rank + 5),
    {mask, 0, 2^rank - 1}];
  exactRootValues = Take[{2, 3, 5}, rank];
  exactConjugates = CodexTripleRoot`TREvaluateConjugates[
    exactCoefficients, exactRootValues, 0];
  exactProjection = CodexTripleRoot`TRProjectConjugates[
    exactConjugates, exactRootValues, 0];
  FTTest`FTAssert[
    "characteristic-zero conjugate projection at rank " <>
      ToString[rank],
    Length[exactConjugates] === 2^rank &&
      exactVectorQ[exactProjection, exactCoefficients]],
  {rank, 0, 3}];

(* Empty root lists are a valid split point, including in finite fields. *)
Do[
  FTTest`FTAssert[
    "TRSquareRoots empty list modulo " <> ToString[prime],
    CodexTripleRoot`TRSquareRoots[{}, prime] === {}],
  {prime, {103, 107}}];

(* Both primes are 3 modulo 4.  The prescribed radicands are explicit
   nonzero squares, so all ranks exercise split, unramified points. *)
Do[
  modularRootSeeds = Take[{2, 3, 5}, rank];
  modularRadicands = Mod[modularRootSeeds^2, prime];
  modularRoots = CodexTripleRoot`TRSquareRoots[
    modularRadicands, prime];
  modularCoefficients = Mod[Table[
    (-1)^mask (17 mask + 9 rank + 23),
    {mask, 0, 2^rank - 1}], prime];
  modularConjugates = CodexTripleRoot`TREvaluateConjugates[
    modularCoefficients, modularRoots, prime];
  modularProjection = CodexTripleRoot`TRProjectConjugates[
    modularConjugates, modularRoots, prime];
  FTTest`FTAssert[
    "modular conjugate projection at rank " <> ToString[rank] <>
      " modulo " <> ToString[prime],
    ListQ[modularRoots] && Length[modularRoots] === rank &&
      AllTrue[modularRoots, #1 =!= 0 &] &&
      Mod[modularRoots^2 - modularRadicands, prime] ===
        ConstantArray[0, rank] &&
      Length[modularConjugates] === 2^rank &&
      modularProjection === modularCoefficients],
  {prime, {103, 107}}, {rank, 0, 3}];

(* Rank zero is a one-dimensional algebra, not a special empty result. *)
rankZeroScalar = (1 + x)/(2 + y);
rankZeroDecomposition =
  CodexTripleRootStrip`TRFieldDecompose[rankZeroScalar, {}];
FTTest`FTAssert["rank-zero singleton behavior",
  CodexTripleRoot`TRBasisMasks[0] === {0} &&
    CodexTripleRoot`TRMaskFactor[0, {}] === 1 &&
    exactVectorQ[
      CodexTripleRoot`TRMultiply[
        {rankZeroScalar}, {3 - x}, {}, 0],
      {Together[rankZeroScalar (3 - x)]}] &&
    exactVectorQ[
      CodexTripleRoot`TRDerivative[{rankZeroScalar}, {}, x],
      {D[rankZeroScalar, x]}] &&
    CodexTripleRoot`TREvaluateConjugates[{7/5}, {}, 0] === {7/5} &&
    CodexTripleRoot`TRProjectConjugates[{7/5}, {}, 0] === {7/5} &&
    exactVectorQ[rankZeroDecomposition, {rankZeroScalar}] &&
    exactZeroQ[
      CodexTripleRootStrip`TRFieldCompose[
        rankZeroDecomposition, {}] - rankZeroScalar]];

(* These denominators contain every active radical.  Decomposition therefore
   has to invert a genuine multiquadratic denominator rather than only reduce
   a polynomial numerator. *)
Do[
  activeRoots = Take[roots, rank];
  activeRootSymbols = Lookup[activeRoots, "Root", {}];
  denominator = Times @@ MapThread[
    #1 + #2 &, {Take[{2, 3, 5}, rank], activeRootSymbols}];
  numerator = 1 + Sum[(index + 1) activeRootSymbols[[index]],
      {index, rank}] +
    If[rank >= 2, activeRootSymbols[[1]] activeRootSymbols[[2]], 0] +
    If[rank >= 3,
      activeRootSymbols[[1]] activeRootSymbols[[2]]
        activeRootSymbols[[3]], 0];
  denominatorExpression = numerator/denominator;
  denominatorChannels = CodexTripleRootStrip`TRFieldDecompose[
    denominatorExpression, activeRoots];
  FTTest`FTAssert[
    "active-root denominator round trip at rank " <> ToString[rank],
    AllTrue[activeRootSymbols, ! FreeQ[denominator, #1] &] &&
      ListQ[denominatorChannels] &&
      Length[denominatorChannels] === 2^rank &&
      exactZeroQ[
        CodexTripleRootStrip`TRFieldCompose[
          denominatorChannels, activeRoots] - denominatorExpression]],
  {rank, 1, 3}];

(* Zero must retain the correct channel dimension in every local field. *)
Do[
  activeRoots = Take[roots, rank];
  zeroChannels = CodexTripleRootStrip`TRFieldDecompose[0, activeRoots];
  FTTest`FTAssert[
    "zero expression at rank " <> ToString[rank],
    zeroChannels === ConstantArray[0, 2^rank] &&
      TrueQ[CodexTripleRootStrip`TRFieldCompose[
        zeroChannels, activeRoots] === 0]],
  {rank, 0, 3}];

(* Mix a rational local block, a block using only global root 2, and a block
   using global roots 1 and 3.  Grade-zero contributions intentionally
   collide and must add rather than overwrite each other. *)
localRankZero = {(1 + x)/(2 + y)};
localRankOne = {(3 + y)/(4 + x), (5 - x)/(6 + y)};
localRankTwo = {7/(1 + x), (8 + y)/(2 + x),
  (9 - x)/(3 + y), (10 + x y)/(4 + x + y)};
liftedRankZero = CodexTripleRootStrip`TRLiftLocalChannels[
  localRankZero, {}, 3];
liftedRankOne = CodexTripleRootStrip`TRLiftLocalChannels[
  localRankOne, {2}, 3];
liftedRankTwo = CodexTripleRootStrip`TRLiftLocalChannels[
  localRankTwo, {1, 3}, 3];
expectedRankZero = {localRankZero[[1]], 0, 0, 0, 0, 0, 0, 0};
expectedRankOne = {localRankOne[[1]], 0, localRankOne[[2]], 0,
  0, 0, 0, 0};
expectedRankTwo = {localRankTwo[[1]], localRankTwo[[2]], 0, 0,
  localRankTwo[[3]], localRankTwo[[4]], 0, 0};
FTTest`FTAssert["rank-zero/one/two lifts use the intended global masks",
  exactVectorQ[liftedRankZero, expectedRankZero] &&
    exactVectorQ[liftedRankOne, expectedRankOne] &&
    exactVectorQ[liftedRankTwo, expectedRankTwo]];

globalChannels = liftedRankZero + liftedRankOne + liftedRankTwo;
globalExpression = CodexTripleRootStrip`TRFieldCompose[
  globalChannels, roots];
directLocalExpression =
  CodexTripleRootStrip`TRFieldCompose[localRankZero, {}] +
  CodexTripleRootStrip`TRFieldCompose[localRankOne, roots[[{2}]]] +
  CodexTripleRootStrip`TRFieldCompose[localRankTwo, roots[[{1, 3}]]];
FTTest`FTAssert["mixed local lifts compose to the direct local sum",
  exactZeroQ[globalExpression - directLocalExpression]];
FTTest`FTAssert["mixed local lift sum decomposes back in global rank three",
  exactVectorQ[
    CodexTripleRootStrip`TRFieldDecompose[globalExpression, roots],
    globalChannels]];

(* TRActiveRank currently has no typed invalid-input contract, so this test
   deliberately asserts only its documented valid domain. *)
FTTest`FTAssert["active grade rank covers zero through three",
  CodexTripleRoot`TRActiveRank[{0}, 3] === 0 &&
    CodexTripleRoot`TRActiveRank[{0, 1}, 3] === 1 &&
    CodexTripleRoot`TRActiveRank[{0, 1, 2, 3}, 3] === 2 &&
    CodexTripleRoot`TRActiveRank[Range[0, 7], 3] === 3];

FTTest`FTReport[];
