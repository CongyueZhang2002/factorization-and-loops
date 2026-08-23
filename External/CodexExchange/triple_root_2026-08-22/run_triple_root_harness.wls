#!/usr/bin/env wolframscript

scratchDirectory = DirectoryName[$InputFileName];
Get[FileNameJoin[{scratchDirectory, "TripleRootAlgebra.wl"}]];

Print["TRHARNESS main_pid=", $ProcessID, " version=", $Version];

launched = LaunchKernels[4];
If[Length[Kernels[]] > 4,
  Print["TRHARNESS FAIL resource_limit subkernels=", Length[Kernels[]]];
  CloseKernels[];
  Exit[20]
];
Print["TRHARNESS subkernels=", Length[Kernels[]], " details=", ParallelEvaluate[{$ProcessID, $KernelID}]];

ParallelEvaluate[Get[FileNameJoin[{scratchDirectory, "TripleRootAlgebra.wl"}]]];

assert[label_, condition_] := If[TrueQ[condition],
  Print["TRHARNESS PASS ", label],
  Print["TRHARNESS FAIL ", label, " condition_head=", Head[Unevaluated[condition]]];
  CloseKernels[];
  Exit[21]
];

v = Unique["v"];
w = Unique["w"];
lambda1 = (1 - v - w)^2 - 4 v w;
lambda2 = lambda1 /. v -> -v;
lambda3 = lambda1 /. w -> -w;
cf300Deltas = Expand /@ {lambda2, lambda3, 1 - 4 v w};
cf259Deltas = Expand /@ {lambda1, lambda3, 4 v + w^2};

assert["hadamard_inverse", CodexTripleRoot`TRHadamardMatrix[3].CodexTripleRoot`TRHadamardMatrix[3] == 8 IdentityMatrix[8]];

r = Array[Unique["r"] &, 3];
polyA = 1 + 2 r[[1]] - r[[2]] r[[3]];
polyB = 3 - r[[1]] r[[2]] + 5 r[[3]];
coeffA = CodexTripleRoot`TRFromPolynomial[polyA, r, cf300Deltas];
coeffB = CodexTripleRoot`TRFromPolynomial[polyB, r, cf300Deltas];
coeffProduct = CodexTripleRoot`TRMultiply[coeffA, coeffB, cf300Deltas];
directProduct = CodexTripleRoot`TRFromPolynomial[polyA polyB, r, cf300Deltas];
assert["polynomial_multiplication", And @@ Thread[Together[coeffProduct - directProduct] == 0]];

a = {1/(1 + v), v/(1 - w), 0, (v + w)/(1 - v w), 2, 0, v^2, 1/(2 - w)};
b = {w, 0, 1/(1 - v), 3, 0, v w, 1/(1 + w), v - w};
dProduct = CodexTripleRoot`TRDerivative[CodexTripleRoot`TRMultiply[a, b, cf300Deltas], cf300Deltas, v];
leibniz = CodexTripleRoot`TRMultiply[CodexTripleRoot`TRDerivative[a, cf300Deltas, v], b, cf300Deltas] +
  CodexTripleRoot`TRMultiply[a, CodexTripleRoot`TRDerivative[b, cf300Deltas, v], cf300Deltas];
assert["derivative_leibniz", And @@ Thread[Together /@ (dProduct - leibniz) == 0]];

closure = CodexTripleRoot`TRGradeClosure[{1}, {2, 4}];
assert["grade_closure", closure == {1, 3, 5, 7}];
assert["grade_rank", CodexTripleRoot`TRActiveRank[closure, 3] == 3];

prime = 1000003;
assert["prime_3_mod_4", PrimeQ[prime] && Mod[prime, 4] == 3];
candidates = Tuples[Range[2, 160], 2];
DistributeDefinitions[cf300Deltas, cf259Deltas, v, w, prime];

cf300Tagged = ParallelMap[
  Function[point, If[CodexTripleRoot`TRSplitPointQ[point, cf300Deltas, {v, w}, prime], point, Nothing]],
  candidates,
  Method -> "CoarsestGrained"
];
cf259Tagged = ParallelMap[
  Function[point, If[CodexTripleRoot`TRSplitPointQ[point, cf259Deltas, {v, w}, prime], point, Nothing]],
  candidates,
  Method -> "CoarsestGrained"
];
cf300Points = Take[cf300Tagged, UpTo[8]];
cf259Points = Take[cf259Tagged, UpTo[8]];
assert["cf300_split_points", Length[cf300Points] == 8];
assert["cf259_split_points", Length[cf259Points] == 8];
Print["TRHARNESS cf300_split_points=", InputForm[cf300Points]];
Print["TRHARNESS cf259_split_points=", InputForm[cf259Points]];

point = First[cf300Points];
deltaValues = Mod[cf300Deltas /. Thread[{v, w} -> point], prime];
rootValues = CodexTripleRoot`TRSquareRoots[deltaValues, prime];
assert["cf300_modular_roots", rootValues =!= $Failed && Mod[rootValues^2 - deltaValues, prime] == ConstantArray[0, 3]];

SeedRandom[20260822];
coefficients = RandomInteger[{0, prime - 1}, 8];
conjugates = CodexTripleRoot`TREvaluateConjugates[coefficients, rootValues, prime];
projected = CodexTripleRoot`TRProjectConjugates[conjugates, rootValues, prime];
assert["walsh_hadamard_roundtrip", projected == Mod[coefficients, prime]];

left = RandomInteger[{0, prime - 1}, 8];
right = RandomInteger[{0, prime - 1}, 8];
product = CodexTripleRoot`TRMultiply[left, right, deltaValues, prime];
leftConjugates = CodexTripleRoot`TREvaluateConjugates[left, rootValues, prime];
rightConjugates = CodexTripleRoot`TREvaluateConjugates[right, rootValues, prime];
productConjugates = CodexTripleRoot`TREvaluateConjugates[product, rootValues, prime];
assert["conjugate_homomorphism", productConjugates == Mod[leftConjugates rightConjugates, prime]];

Print["TRHARNESS RESULT success prime=", prime, " point=", point,
  " deltas=", deltaValues, " roots=", rootValues];
CloseKernels[];
Exit[0];
