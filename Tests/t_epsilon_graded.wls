(* Epsilon-graded scalar solver (Scripts/EpsilonGraded.wl): the route for
   the three generic-eps-irreducible hard classes (97, 77, 79), whose
   eps=0 operators factor completely into first-order pieces.

   Acceptance criteria:

   A. Synthetic control: L = D^2 - (eps/x) D continued from f0 = x
      reproduces the expansion of x^(1+eps) up to kernel elements, with
      exact residual certificates through eps^3.
   B. Primitive-engine regressions:
      B1 the HyperIntica trailing-zero defect (primitive of
         Hlog[x,{0,0}] returned HALF the true value, every on-box
         version, measured 2026-08-15) must be routed around: the
         derivative of EGPrimitive's result must equal the integrand
         exactly;
      B2 var-free denominator content (the class-97 order-2 blocker)
         must be handled;
      B3 shuffle products and powers must integrate exactly.
   C. Stored eps=0 factor chains for classes 97, 77, 79 recompose
      exactly to their monic eps=0 operators (division/recomposition
      certificate, recomputed here from the stored chain and operator,
      never trusting the stored status).
   D. Class-97 stage weights are rational with integer residues
      (EGChainData succeeds), so the chain is quadrature-ready. *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestKit.wl"}]];
root = DirectoryName[$InputFileName, 2];
Get[FileNameJoin[{root, "Scripts", "EpsilonGraded.wl"}]];
x = Global`x; y = Global`y; v = Global`v; w = Global`w; eps = Global`eps;
hardDir = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "HardClasses"}];

(* ---------------------------------------------------------------- A ---- *)
out = EGSolve[{0, -eps/x, 1}, {0, 0}, x, x, eps, "Depth" -> 3];
FTTest`FTAssert["A. synthetic control: status OK, all residual certs True",
  out["Status"] === "OK" && out["ResidualZero"] === {True, True, True}];
FTTest`FTAssert["A. synthetic control: f1 = x Log x modulo kernel {1,x}",
  Module[{d = Simplify[(out["Orders"][[2]] /. Hlog[x, {0}] -> Log[x]) -
       x Log[x]]},
   PolynomialQ[d, x] && Exponent[d, x] <= 1]];

(* ---------------------------------------------------------------- B ---- *)
FTTest`FTAssert["B1. trailing-zero primitive certified (package defect routed)",
  Module[{r = EGPrimitive[Hlog[x, {0, 0}], x]},
   EGZeroQ[EGOwnD[r, x] - Hlog[x, {0, 0}], x]]];
FTTest`FTAssert["B2. var-free denominator content handled",
  Module[{f = -12/((-1 + x)^2 (-1 + y)^3 (1 + y)^6), r},
   r = EGPrimitive[f, x];
   EGZeroQ[EGOwnD[r, x] - f, x]]];
FTTest`FTAssert["B3. shuffle product integrates exactly",
  Module[{f = Hlog[x, {3}] Hlog[x, {-1}]/(x - 5), r},
   r = EGPrimitive[f, x];
   EGZeroQ[EGOwnD[r, x] - f, x]]];

(* ---------------------------------------------------------------- C ---- *)
opMulT[a_List, b_List, var_] := Module[
  {na = Length[a] - 1, nb = Length[b] - 1, res},
  res = ConstantArray[0, na + nb + 1];
  Do[If[a[[i + 1]] =!= 0, Do[If[b[[j + 1]] =!= 0,
     Do[res[[m + j + 1]] += Binomial[i, m] a[[i + 1]] D[b[[j + 1]], {var, i - m}],
       {m, 0, i}]], {j, 0, nb}]], {i, 0, na}];
  Together /@ res];
chainOK[file_, var_] := Module[{d, ps0, mon, rebuilt, cmp},
  d = Get[FileNameJoin[{hardDir, file}]];
  ps0 = Together[d["SymbolicCoefficients"] /. eps -> 0];
  mon = Together[ps0/Last[ps0]];
  rebuilt = Fold[opMulT[{-#2, 1}, #1, var] &,
    {-d["Chain"][[1]], 1}, Rest[d["Chain"]]];
  cmp = Together[rebuilt - mon];
  If[! AllTrue[cmp, # === 0 &], cmp = Simplify[cmp]];
  AllTrue[cmp, # === 0 &]];
FTTest`FTAssert["C. class-97 eps=0 chain recomposes exactly",
  chainOK["eps0_c97_factored.wl", x]];
FTTest`FTAssert["C. class-77 eps=0 chain recomposes exactly",
  chainOK["eps0_c77_factored.wl", v]];
FTTest`FTAssert["C. class-79 eps=0 chain recomposes exactly",
  chainOK["eps0_c79_factored.wl", v]];

(* ---------------------------------------------------------------- D ---- *)
FTTest`FTAssert["D. class-97 stage weights rational with integer residues",
  Module[{d = Get[FileNameJoin[{hardDir, "eps0_c97_factored.wl"}]]},
   EGChainData[d["Chain"], x] =!= $Failed]];

FTTest`FTReport[];
