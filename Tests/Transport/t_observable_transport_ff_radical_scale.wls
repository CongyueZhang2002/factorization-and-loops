(* The finite-field compiler of the observable transport must accept an
   algebraic record whose declared root squares appear RESCALED after a
   variable is fixed to a rational base point (CF259 probe 4, 2026-09-02:
   Sqrt[56/45 + y^2] is canonicalized by Wolfram as Sqrt[56 + 45 y^2]/(3 Sqrt[5]),
   which the compiler refused: AlgebraicMatrixCompileFailed).
   Acceptance: (1) the specialized matrix compiles; (2) at a rational
   point mod a large prime the compiled values satisfy the defining
   identities of the radicals (square, product, inverse) exactly mod p, on
   both sheets; (3) the derivative evaluator agrees with the exact
   derivative mod p; (4) the production entry
   observableTransportFFAlgebraicIndependentRowsAtSamples returns pivots
   for the specialized matrix instead of $Failed; (5) a matrix with an
   undeclared radical is still refused. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
y = Symbol["Global`y"];
q1 = 56/45 + y^2; q2 = 961/2025 - (118 y)/45 + y^2;
squares = {q1, q2};
(* the forms found in the CF259 dump (probe 4): the declared squares rescaled
   by 45 and 45^2 and a loose numeric Sqrt[5] -- written literally, as
   Together/Cancel produces them *)
m = {{Sqrt[56 + 45 y^2]/(3 Sqrt[5]), 3 Sqrt[5]/Sqrt[56 + 45 y^2]},
     {Sqrt[5] Sqrt[961 - 5310 y + 2025 y^2]/45,
      y Sqrt[56 + 45 y^2] Sqrt[961 - 5310 y + 2025 y^2]/(135 Sqrt[5])}};
FTAssert["the matrix carries the rescaled radicals and the numeric Sqrt[5] (the defect's trigger)",
  ! FreeQ[m, Sqrt[5]] && ! FreeQ[m, Sqrt[56 + 45 y^2]] && ! FreeQ[m, Sqrt[961 - 5310 y + 2025 y^2]]];
FTAssert["those entries equal Sqrt[q1], 1/Sqrt[q1], Sqrt[5] Sqrt[q2] and y Sqrt[q1] Sqrt[q2] exactly",
  And @@ (TrueQ[RootReduce[Together[#]] === 0] & /@ Flatten[
    m - {{Sqrt[q1], 1/Sqrt[q1]}, {Sqrt[5] Sqrt[q2], y Sqrt[q1] Sqrt[q2]}}])];
compiled = FeynFacet`Private`observableTransportFFCompileAlgebraicMatrix[m, {y}, squares];
FTAssert["the specialized matrix compiles", AssociationQ[compiled]];
(* a 31-bit prime p == 3 (mod 4) in which 5 is a quadratic residue: for
   2^31 - 1 itself (5 | p) = (p | 5) = (2 | 5) = -1, so no split point
   exists there -- the first draft of this test tripped over exactly that *)
p = SelectFirst[Table[NextPrime[2^31, -k], {k, 1, 60}],
  Mod[#, 4] === 3 && JacobiSymbol[5, #] === 1 &];
FTAssert["a test prime with (5|p) = 1 exists below 2^31", IntegerQ[p]];
img[r_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, p], p];
(* a point where both squares and the constant 5 are quadratic residues *)
y0 = SelectFirst[Range[1234567, 1234567 + 400],
  Function[v, JacobiSymbol[img[q1 /. y -> v], p] === 1 &&
    JacobiSymbol[img[q2 /. y -> v], p] === 1 && JacobiSymbol[5, p] === 1], None];
FTAssert["a split point exists for the test prime", IntegerQ[y0]];
v1 = img[q1 /. y -> y0]; v2 = img[q2 /. y -> y0];
r1 = FeynFacet`Private`modularSquareRoot[v1, p]; r2 = FeynFacet`Private`modularSquareRoot[v2, p];
sheetsOK = And @@ Table[
  Module[{val = FeynFacet`Private`observableTransportFFAlgebraicCompiledMatrixValue[compiled, {y0}, {r1, r2}, signs, p]},
    MatrixQ[val, IntegerQ] &&
    Mod[val[[1, 1]]^2 - v1, p] === 0 &&
    Mod[val[[1, 1]] val[[1, 2]] - 1, p] === 0 &&
    Mod[val[[2, 1]]^2 - 5 v2, p] === 0 &&
    Mod[val[[2, 2]]^2 - y0^2 v1 v2, p] === 0 &&
    Mod[val[[1, 1]] - signs[[1]] r1, p] === 0],
  {signs, {{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}}];
FTAssert["compiled values satisfy the radical identities on all four sheets", sheetsOK];
der = FeynFacet`Private`observableTransportFFAlgebraicCompiledMatrixValueWithDerivative[compiled, y, {y0}, {r1, r2}, {1, 1}, p];
(* d/dy Sqrt[q1] = y/Sqrt[q1]; d/dy 1/Sqrt[q1] = -y/q1^(3/2) *)
(* the derivative evaluator returns {values, derivatives}, two matrices *)
FTAssert["derivative evaluator: d/dy Sqrt[q1] = y/Sqrt[q1] and d/dy (1/Sqrt[q1]) = -y q1^(-3/2) mod p",
  ListQ[der] && Mod[der[[2, 1, 1]] r1 - y0, p] === 0 &&
    Mod[der[[2, 1, 2]] PowerMod[r1, 3, p] + y0, p] === 0];
pivots = FeynFacet`Private`observableTransportFFAlgebraicIndependentRowsAtSamples[m, {y}, {{y -> 3/11}, {y -> 4/13}}, squares];
FTAssert["the production rank sampler returns pivots for the specialized matrix", MatchQ[pivots, {{__Integer}, {__Integer}}]];
bad = {{Sqrt[1 + y^3], y}};
FTAssert["an undeclared radical is still refused",
  FeynFacet`Private`observableTransportFFCompileAlgebraicMatrix[bad, {y}, squares] === $Failed];
FTAssert["square-free split: Sqrt[45] = 3 Sqrt[5], Sqrt[8/9] = (2/3) Sqrt[2]",
  FeynFacet`Private`observableTransportFFSquareFreeSplit[45] === {3, 5} &&
  FeynFacet`Private`observableTransportFFSquareFreeSplit[8/9] === {2/3, 2}];
FTReport[];
