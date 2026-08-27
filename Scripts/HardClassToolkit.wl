(* ==========================================================================
   HardClassToolkit.wl  --  FeynFacet hard-class attack ladder
   ==========================================================================
   Public driver:  AttackClass[classData_Association, opts]
   Ordered ladder, cheapest first, every rung certificate-gated:
     R1  structure diagnostics   (a) one-variable dependence
                                 (b) apparent-singularity census + balances
                                 (c) exponent census / Jordan structure
                                 (d) invariant-subspace (reducibility) probe
     R2  cyclic-vector scalar reduction
     R3  operator identification (factorization / 2F1 / Sym^k / tensor)
     R4  certification against the ORIGINAL block system
     R5  report + forwarded obstruction

   DESIGN RULES (learned the hard way, see TOOLKIT.md):
     - regulator normalized by SymbolName at EVERY tool boundary
     - no Return[] inside Do[]
     - Module initializers are NOT sequentially scoped: declare, then assign
     - no self-assignments (v = Global`v)
     - absent keys tested with KeyExistsQ, never compared against None
     - all file writes are temp + RenameFile (non-atomic Put is a known trap)
     - BALANCES ARE REPORTED, NEVER AUTO-APPLIED: applying a balance before a
       rational-ansatz search is MEASURED-DESTRUCTIVE (WORKLOG 2026-08-14).
   ========================================================================== *)

HCT$Version = "1.0";

(* Libra trap (MEASURED, WL 14.2), turned off HERE because this toolkit is
   loaded into the same kernel as Libra by every eps-form driver
   (Scripts/HardClasses/epsform_lee79b_c79.wls, epsform_symrep79_c79.wls, symrep97.wls,
   balance_loop5.wls) and the failure mode is silent:

     Libra`Projector wraps its work in Check; its own OInverse emits a
     benign OptionValue::optnf message; Check reads the message as
     failure and Projector returns a ZERO matrix.  Every balance search
     built on it then reports "no balance found" with no error at all.
     Quiet at the CALL site does not help -- Check is inside Projector.

   The toolkit does not itself Get Libra, so this is a guard for the
   surrounding kernel, not a load-site fix; the load-site fix lives in
   FeynFacet/Private/MasterTransport.wl (masterTransportLoadLibra).
   Pinned by Tests/Infrastructure/t_wolfram_traps.wls.  The message carries no
   information we act on -- it reports an option name a third-party
   package passes to its own helper -- so switching it off is not
   suppressing a diagnostic of ours. *)
Off[OptionValue::optnf];

(* ---------------------------------------------------------------- 0. utils *)

HCT$RegulatorNames = {"eps", "Eps", "EPS", "epsilon", "Epsilon", "ep", "\[Epsilon]"};

(* Normalize incoming symbols to this file's eps, v, w -- by SymbolName, so
   Global`eps, CANONICA`eps, Epsilon, ep all collapse to one symbol. *)
HCTNormalize[expr_] := Module[{syms, rules, nm},
  syms = DeleteDuplicates@Cases[expr, s_Symbol :> s, {0, Infinity}, Heads -> True];
  rules = {};
  Do[
    nm = SymbolName[syms[[i]]];
    Which[
      MemberQ[HCT$RegulatorNames, nm] && syms[[i]] =!= eps, AppendTo[rules, syms[[i]] -> eps],
      nm === "v" && syms[[i]] =!= v, AppendTo[rules, syms[[i]] -> v],
      nm === "w" && syms[[i]] =!= w, AppendTo[rules, syms[[i]] -> w],
      True, Null],
    {i, Length[syms]}];
  expr /. rules];

HCTmap[f_, m_] := Map[f, m, {2}];
HCTtog[m_] := HCTmap[Together, m];
HCTzeroQ[m_] := AllTrue[Flatten[{m}], (Together[#] === 0 || TrueQ[Simplify[# == 0]]) &];

(* deterministic normalization of a polynomial up to a nonzero constant *)
HCTNormFactor[p_] := Module[{cr, c, q},
  q = Expand[p];
  cr = CoefficientRules[q, {eps, v, w}];
  c = If[cr === {}, 1, cr[[1, 2]]];
  If[c === 0, q, Expand[Cancel[q/c]]]];

HCTSameLocusQ[f_, L_] := TrueQ[Expand[HCTNormFactor[f] - HCTNormFactor[L]] === 0];

(* all irreducible non-constant denominator factors appearing in a matrix *)
HCTSingularLoci[mats_List] := Module[{dens, fl, out},
  dens = DeleteDuplicates@Flatten[Map[Denominator[Together[#]] &, mats, {3}]];
  out = {};
  Do[
    fl = FactorList[dens[[i]]];
    Do[
      If[! FreeQ[fl[[j, 1]], v] || ! FreeQ[fl[[j, 1]], w],
        AppendTo[out, HCTNormFactor[fl[[j, 1]]]]],
      {j, Length[fl]}],
    {i, Length[dens]}];
  DeleteDuplicates[out]];

HCTPoleOrder[expr_, L_] := Module[{fl, m},
  fl = FactorList[Denominator[Together[expr]]];
  m = 0;
  Do[If[HCTSameLocusQ[fl[[i, 1]], L], m = Max[m, fl[[i, 2]]]], {i, Length[fl]}];
  m];

HCTMatPoleOrder[mat_, L_] := Max[Map[HCTPoleOrder[#, L] &, Flatten[mat]]];

(* ------------------------------------------------- residue at a locus L=0 *)
(* A = R dlog(L) + regular  =>  R = A_x * L / d_x L  restricted to L = 0.     *)
(* Prefer the direction of LOWEST degree and keep the OTHER variable symbolic:
   a quadratic locus (e.g. the Kallen curve Q) is still solvable in radicals,
   and staying symbolic in v is far cheaper than RootReduce on sampled roots. *)
HCTResidue[Av_, Aw_, L_] := Module[{dv, dw, mat, dvar, sol, xs, R},
  dv = Exponent[L, v]; dw = Exponent[L, w];
  Which[
    dw >= 1 && (dw <= dv || dv === 0), dvar = w; mat = Aw,
    dv >= 1, dvar = v; mat = Av,
    True, dvar = None; mat = None];
  If[dvar === None || (dv > 2 && dw > 2),
    R = HCTResidueSampled[Aw, L],
    sol = Quiet@TimeConstrained[Solve[L == 0, dvar], 120, $Failed];
    If[! ListQ[sol] || sol === {},
      R = HCTResidueSampled[Aw, L],
      xs = dvar /. First[sol];
      R = HCTmap[Cancel[Together[# L/D[L, dvar]]] &, mat] /. dvar -> xs;
      R = Quiet@TimeConstrained[HCTmap[Simplify, R], 240, HCTmap[Together, R]]]];
  R];

HCTResidueSampled[Aw_, L_] := Module[{vv, sol, xs, R, k, ok},
  R = $Failed; ok = False; k = 0;
  Do[
    If[! ok,
      vv = 3 + 2 k + 1/(7 + k);
      sol = Solve[(L /. v -> vv) == 0, w];
      If[sol =!= {} && Head[sol] === List,
        xs = w /. First[sol];
        R = HCTmap[Cancel[Together[# L/D[L, w]]] &, Aw] /. v -> vv;
        R = R /. w -> xs;
        (* RootReduce on a symbolic-eps matrix is a known stall; Together is
           enough for eigenvalues and Simplify is attempted only under guard *)
        R = Quiet@TimeConstrained[HCTmap[Simplify, R], 180, HCTmap[Together, R]];
        ok = True]];
    k++,
    {6}];
  R];

(* eigen-data with Jordan info; robust for symbolic eps *)
HCTSpectrum[R_] := Module[{n, cp, evs, out, lam, geo, alg, fl},
  If[R === $Failed, <|"Status" -> "failed"|>,
   n = Length[R];
   cp = Quiet@TimeConstrained[Factor[CharacteristicPolynomial[R, HCT$lam]], 240,
                              CharacteristicPolynomial[R, HCT$lam]];
   evs = Quiet@TimeConstrained[Simplify[Eigenvalues[R]], 300, $Failed];
   If[evs === $Failed, Return[<|"Status" -> "eigenvalue timeout", "CharPoly" -> cp,
                                "Rank" -> Quiet@TimeConstrained[MatrixRank[R], 120, "?"]|>, Module]];
   (* RANK-1 SHORTCUT.  Eigenvalues of a residue taken on an algebraic locus
      (e.g. the Kallen curve, where w carries a Sqrt) come back as unsimplified
      monsters, and the half-integer detector then MISSES the very obstruction
      it exists to find (measured: class 79, Q locus).  For a rank-1 residue
      the single nonzero eigenvalue IS the trace, which simplifies easily.   *)
   If[Quiet@TimeConstrained[MatrixRank[R], 120, 0] === 1,
     Module[{tr},
       tr = Quiet@TimeConstrained[FullSimplify[Tr[R]], 240,
                                  Quiet@TimeConstrained[Simplify[Tr[R]], 120, Tr[R]]];
       evs = Append[ConstantArray[0, n - 1], tr]],
     evs = Quiet@TimeConstrained[FullSimplify[evs], 240, evs]];
   fl = FactorList[cp];
   out = {};
   Do[
     lam = evs[[i]];
     alg = Count[evs, x_ /; TrueQ[Simplify[x - lam == 0]]];
     geo = n - MatrixRank[R - lam IdentityMatrix[n]];
     AppendTo[out, <|"Eigenvalue" -> lam, "Algebraic" -> alg, "Geometric" -> geo,
                     "Jordan" -> If[alg === geo, "diagonalizable", "NON-diagonalizable"]|>],
     {i, Length[evs]}];
   <|"Status" -> "ok", "Eigenvalues" -> evs, "Rank" -> MatrixRank[R],
     "Trace" -> Simplify[Tr[R]], "Detail" -> DeleteDuplicatesBy[out, Simplify[#["Eigenvalue"]] &],
     "CharPoly" -> cp|>]];

(* fractional part of the eps -> 0 limit of an exponent *)
(* defined via HCTExponentClass so the two can never disagree *)
HCTHalfIntegerQ[lam_] := StringStartsQ[HCTExponentClass[lam], "half-integer"];

HCTExponentClass[lam_] := Module[{r},
  (* the eps->0 limit must be forced to a number, else an algebraic-locus
     exponent is silently classified "unrecognized" and a half-integer
     obstruction goes unreported *)
  r = Quiet@TimeConstrained[FullSimplify[lam /. eps -> 0], 120,
                            Quiet[Simplify[lam /. eps -> 0]]];
  r = Quiet@TimeConstrained[RootReduce[r], 60, r];
  Which[
    TrueQ[Element[r, Integers]], "integer",
    TrueQ[Element[r, Rationals]] && Denominator[r] === 2, "half-integer",
    TrueQ[Element[r, Rationals]], "rational-" <> ToString[Denominator[r]],
    True, "unrecognized"]];

(* ============================================================== R1a  ======= *)
(* One-variable dependence.  Generalizes class 115's mechanism:
     Av = M dz/dv , Aw = M dz/dw  with a COMMON M(z)
   Necessary: [Av,Aw] = 0 and Aw = rho * Av for a SCALAR rational rho.
   Then rho = z_w/z_v, level sets obey dv/dw = -rho, and z is its first
   integral -- obtained mechanically from the linear PDE, no guessing.       *)

HCTOneVariableTest[Av_, Aw_] := Module[
  {comm, commZero, pos, rho, propQ, pde, sol, zc, Mv, chk, wsol, res, zexpr, deg},
  res = <|"Rung" -> "R1a"|>;
  comm = HCTtog[Av . Aw - Aw . Av];
  commZero = HCTzeroQ[comm];
  res["Commutator"] = If[commZero, "zero", "NONZERO"];
  If[HCTzeroQ[Av], res["Degenerate"] = "Av identically zero"];
  If[HCTzeroQ[Aw], res["Degenerate"] = "Aw identically zero"];
  (* scalar proportionality Aw = rho Av *)
  pos = Select[Flatten[Table[{i, j}, {i, Length[Av]}, {j, Length[Av]}], 1],
               Together[Av[[#[[1]], #[[2]]]]] =!= 0 &];
  If[pos === {},
    res["Proportional"] = False; res["OneVariable"] = False; res,
    rho = Together[Aw[[pos[[1, 1]], pos[[1, 2]]]]/Av[[pos[[1, 1]], pos[[1, 2]]]]];
    propQ = HCTzeroQ[HCTtog[Aw - rho Av]];
    res["Proportional"] = propQ;
    res["Rho"] = If[propQ, rho, Missing["not proportional"]];
    If[! propQ,
      res["OneVariable"] = False;
      res["Obstruction"] = "Av and Aw are not scalar multiples of a common matrix";
      res,
      (* first integral of  -rho d_v z + d_w z = 0 *)
      pde = -rho D[HCT$z[v, w], v] + D[HCT$z[v, w], w] == 0;
      sol = Quiet@TimeConstrained[DSolve[pde, HCT$z[v, w], {v, w}], 120, $Failed];
      zexpr = Missing["undetermined"];
      If[ListQ[sol] && sol =!= {},
        zc = HCT$z[v, w] /. First[sol];
        (* DSolve returns C[1][ firstIntegral ] *)
        If[! FreeQ[zc, C[1]],
          zexpr = Quiet@Simplify[First@Cases[zc, C[1][arg_] :> arg, {0, Infinity}]]]];
      If[MissingQ[zexpr],
        (* fallback: separable ODE route  dv/dw = -rho *)
        sol = Quiet@TimeConstrained[
          DSolve[{HCT$V'[w] == -(rho /. v -> HCT$V[w])}, HCT$V[w], w], 120, $Failed];
        If[ListQ[sol] && sol =!= {},
          zc = Quiet@Solve[HCT$V[w] == (HCT$V[w] /. First[sol]) /. HCT$V[w] -> v, C[1]];
          If[ListQ[zc] && zc =!= {}, zexpr = Simplify[C[1] /. First[zc]]]]];
      res["Invariant"] = zexpr;
      If[MissingQ[zexpr],
        res["OneVariable"] = "undetermined";
        res["Obstruction"] = "proportional, but the first integral was not found";
        res,
        (* verify M = Av / d_v z depends on (v,w) only through z *)
        Mv = HCTmap[Cancel[Together[#/D[zexpr, v]]] &, Av];
        wsol = Quiet@Solve[zexpr == HCT$Z, w];
        chk = If[ListQ[wsol] && wsol =!= {},
                 HCTzeroQ[HCTmap[Together, D[Mv /. First[wsol], v]]],
                 "unverified"];
        res["MDependsOnlyOnZ"] = chk;
        res["M"] = If[TrueQ[chk] && ListQ[wsol] && wsol =!= {},
                      HCTmap[Simplify, (Mv D[zexpr, v]) /. First[wsol]], Mv];
        (* the one-variable system:  dF/dz = Mz . F *)
        res["Mz"] = If[ListQ[wsol] && wsol =!= {},
                       HCTmap[Simplify, Mv /. First[wsol]], Missing["unsolved"]];
        res["OneVariable"] = TrueQ[chk] && commZero;
        res]]]];

(* ============================================================== R1b/R1c === *)

HCTSingularCensus[Av_, Aw_, locusTC_: 300] :=
 Module[{loci, out, L, ov, ow, R, sp, appQ, bal, P, n, det},
  loci = HCTSingularLoci[{Av, Aw}];
  out = {};
  Do[
    L = loci[[i]];
    ov = HCTMatPoleOrder[Av, L];
    ow = HCTMatPoleOrder[Aw, L];
    appQ = ! FreeQ[L, eps];
    Print["    [R1c] locus ", L, "  ord(Av)=", ov, " ord(Aw)=", ow,
          If[appQ, "  <-- eps-DEPENDENT => necessarily APPARENT", ""]];
    If[Max[ov, ow] > 1,
      AppendTo[out, <|"Locus" -> L, "OrdAv" -> ov, "OrdAw" -> ow,
        "Fuchsian" -> False, "EpsDependent" -> appQ,
        "Exponents" -> Missing["non-Fuchsian: simple-pole residue formula invalid"],
        "Note" -> "order-" <> ToString[Max[ov, ow]] <> " pole: needs Moser reduction"|>],
      (* per-locus time guard: one hard locus must never stall the census.
         Pole orders are already recorded above and are the cheap payload.   *)
      R = Quiet@TimeConstrained[HCTResidue[Av, Aw, L], locusTC, $Failed];
      sp = If[R === $Failed, <|"Status" -> "residue timeout"|>,
              Quiet@TimeConstrained[HCTSpectrum[R], locusTC, <|"Status" -> "spectrum timeout"|>]];
      bal = Missing["not rank-1"];
      If[sp["Status"] === "ok" && sp["Rank"] === 1 && ! TrueQ[Simplify[sp["Trace"] == 0]],
        n = Simplify[sp["Trace"]];
        bal = Quiet@TimeConstrained[
          Module[{PP},
            PP = HCTmap[Simplify, R/n];
            <|"Projector" -> PP, "Trace" -> n,
              "T" -> HCTmap[Simplify, IdentityMatrix[Length[R]] - PP + L PP],
              "Tinv" -> HCTmap[Simplify, IdentityMatrix[Length[R]] - PP + PP/L],
              "IdempotentCheck" -> HCTzeroQ[HCTtog[PP . PP - PP]],
              "WARNING" -> "do NOT apply before a rational-ansatz search (measured destructive)"|>],
          locusTC, Missing["balance timeout"]]];
      If[sp["Status"] =!= "ok",
        Print["      [R1c]   ", sp["Status"], " at this locus (pole orders retained)"]];
      AppendTo[out, <|"Locus" -> L, "OrdAv" -> ov, "OrdAw" -> ow,
        "Fuchsian" -> True, "EpsDependent" -> appQ,
        "Residue" -> R, "Spectrum" -> sp,
        "Exponents" -> If[sp["Status"] === "ok", sp["Eigenvalues"], Missing[sp["Status"]]],
        "ExponentClasses" -> If[sp["Status"] === "ok",
                                HCTExponentClass /@ sp["Eigenvalues"], Missing[sp["Status"]]],
        "Balance" -> bal|>]],
    {i, Length[loci]}];
  out];

(* ============================================================== R1d ======== *)
(* Cheap reducibility probes.  The DEFINITIVE answer comes from R3 operator
   factorization; these fire only when reducibility is visible rationally.    *)

HCTInvariantSubspace[Av_, Aw_] := Module[
  {n, supp, g, scc, res, cp, roots, x, sub, rat, k},
  n = Length[Av];
  res = <|"Rung" -> "R1d"|>;
  (* (i) support-digraph reducibility: permutation to block-triangular form *)
  supp = Table[If[Together[Av[[i, j]]] === 0 && Together[Aw[[i, j]]] === 0, 0, 1],
               {i, n}, {j, n}];
  g = AdjacencyGraph[supp, DirectedEdges -> True];
  (* strongly connected components: >1 <=> a permutation makes the support
     block-triangular <=> the block splits as a differential system          *)
  scc = ConnectedComponents[g];
  res["SupportSCC"] = scc;
  res["SupportWCC"] = WeaklyConnectedComponents[g];
  res["PermutationReducible"] = Length[scc] > 1;
  (* (ii) rational eigenvector giving a rank-1 subsystem *)
  cp = Factor[CharacteristicPolynomial[Av, x]];
  rat = Select[FactorList[cp][[All, 1]], Exponent[#, x] === 1 &];
  res["RationalEigenvaluesOfAv"] = Length[rat];
  sub = {};
  Do[
    k = Simplify[x /. First[Solve[rat[[i]] == 0, x]]];
    Module[{ns, y, cv, cw},
     ns = NullSpace[HCTmap[Together, Av - k IdentityMatrix[n]]];
     Do[
       y = ns[[j]];
       (* rank-1 sub-D-module iff (A.y - dy) is parallel to y in BOTH directions *)
       cv = HCTtog[Av . y - D[y, v]];
       cw = HCTtog[Aw . y - D[y, w]];
       If[HCTzeroQ[Simplify[Outer[Times, y, cv] - Outer[Times, cv, y]]] &&
          HCTzeroQ[Simplify[Outer[Times, y, cw] - Outer[Times, cw, y]]],
         AppendTo[sub, <|"Vector" -> Simplify[y], "Rank" -> 1|>]],
       {j, Length[ns]}]],
    {i, Length[rat]}];
  res["Rank1Subsystems"] = sub;
  res["Reducible"] = Length[sub] > 0 || Length[scc] > 1;
  res["Caveat"] = "negative here does NOT prove irreducibility; see R3 factorization";
  res];

(* ============================================================== R2 ======== *)
(* Cyclic-vector reduction to one scalar ODE of order = dim, in variable x.
   Covector recursion:  c_{k+1} = d_x c_k + c_k . A   for  y = c.F.          *)

HCTScalarReduce[A_, x_, cvec_] := Module[{n, rows, M, rhs, a, i},
  n = Length[A];
  rows = {cvec};
  Do[AppendTo[rows, HCTtog[{D[Last[rows], x] + Last[rows] . A}][[1]]], {i, 1, n}];
  M = Transpose[Take[rows, n]];
  If[TrueQ[Simplify[Det[M] == 0]],
    <|"Status" -> "not cyclic", "CyclicVector" -> cvec|>,
    rhs = rows[[n + 1]];
    a = Simplify[LinearSolve[M, rhs]];
    <|"Status" -> "ok", "CyclicVector" -> cvec, "Order" -> n,
      "Coefficients" -> a,   (* y^(n) = sum a[[k]] y^(k-1) *)
      "Covectors" -> Take[rows, n],
      "ReconstructionMatrix" -> M,
      "LeafCount" -> LeafCount[a]|>]];

(* Partial work must survive a timeout: the first cyclic vector often succeeds
   and the later ones only try to beat it.  Results are mirrored into a global
   so the driver can recover them even if the whole rung is aborted.        *)
HCT$LastReductions = {};

HCTBestScalarReduction[A_, x_, maxTry_: 8, budget_: 480] :=
 Module[{n, cands, res, best, i, r, t0, left},
  n = Length[A];
  cands = Join[
    IdentityMatrix[n],
    Table[UnitVector[n, 1] + UnitVector[n, i], {i, 2, n}],
    {Table[1, {n}]}];
  cands = Take[cands, UpTo[maxTry]];
  cands = DeleteDuplicates[cands];
  res = {};
  HCT$LastReductions = {};
  t0 = AbsoluteTime[];
  Do[
    left = budget - (AbsoluteTime[] - t0);
    (* Economics: a cyclic vector that works is worth far more than a slightly
       smaller one that costs minutes to find.  Once we have a working
       reduction and a third of the budget is gone, stop shopping.          *)
    If[res =!= {} && (AbsoluteTime[] - t0) > budget/3, left = 0;
       Print["    [R2] have a working reduction and 1/3 budget spent; stopping search"]];
    If[left > 5,
      r = Quiet@TimeConstrained[HCTScalarReduce[A, x, cands[[i]]], Min[300, left],
                                <|"Status" -> "timeout"|>];
      If[r["Status"] === "ok",
        Print["    [R2] cyclic vector ", cands[[i]], " -> order ", r["Order"],
              ", LeafCount ", r["LeafCount"]];
        AppendTo[res, Append[r, "Index" -> i]];
        HCT$LastReductions = res],
      Print["    [R2] budget spent, stopping after ", i - 1, " candidates"]],
    {i, Length[cands]}];
  If[res === {},
    <|"Status" -> "no cyclic vector found"|>,
    (* DETERMINISTIC tie-break: smallest coefficients, then EARLIEST candidate.
       SortBy alone breaks ties by canonical order of the whole Association,
       which silently selected e2 (component F2) over e1 on class 115 and made
       the identification incomparable to the recorded F1 convention.        *)
    best = First@SortBy[res, {#["LeafCount"] &, #["Index"] &}];
    Append[Append[best, "Tried" -> Length[cands]],
           "AllReductions" -> (<|"CyclicVector" -> #["CyclicVector"],
                                 "LeafCount" -> #["LeafCount"]|> & /@ res)]]];

(* operator coefficients p_k with  sum_{k=0}^{n} p_k y^(k) = 0 , p_n = 1      *)
HCTOperatorCoefficients[red_] := Module[{n, a},
  n = red["Order"]; a = red["Coefficients"];
  Append[-a, 1]];

(* ============================================================== R3 ======== *)
(* Local exponents of a scalar operator: indicial polynomial at x0 (or Inf).  *)

HCTIndicial[ps_, x_, x0_] := Module[{n, t, ords, m, ind, s, terms, i, ex},
  n = Length[ps] - 1;
  If[x0 === Infinity,
    (* y ~ x^(-s) ; term k contributes p_k * (-s)(-s-1)...(-s-k+1) * x^(-s-k) *)
    terms = Table[Expand[ps[[k + 1]] Product[(-s - j), {j, 0, k - 1}]], {k, 0, n}];
    ords = Table[If[TrueQ[terms[[k + 1]] === 0], -Infinity,
                    Exponent[terms[[k + 1]], x] - k], {k, 0, n}];
    m = Max[ords];
    ind = Sum[If[ords[[k + 1]] === m, Coefficient[terms[[k + 1]], x, m + k], 0], {k, 0, n}],
    (* finite x0 ; y ~ t^s , t = x - x0 *)
    terms = Table[Expand[(ps[[k + 1]] /. x -> x0 + t) Product[(s - j), {j, 0, k - 1}]],
                  {k, 0, n}];
    ords = Table[If[TrueQ[terms[[k + 1]] === 0], Infinity,
                    Exponent[terms[[k + 1]], t, Min] - k], {k, 0, n}];
    m = Min[ords];
    ind = Sum[If[ords[[k + 1]] === m, Coefficient[terms[[k + 1]], t, m + k], 0], {k, 0, n}]];
  ind = Factor[Simplify[ind]];
  ex = Quiet@Simplify[s /. Solve[ind == 0, s]];
  <|"Point" -> x0, "Indicial" -> ind, "Exponents" -> ex|>];

(* Leading-coefficient factorization is ALWAYS reported; explicit roots are
   attempted under a time guard.  In the two-variable route the leading
   coefficient is a polynomial in x whose coefficients involve the spectator
   variable, so Solve can blow up -- a failed solve must still leave the
   factorization behind for the next agent.                                  *)
HCTLeadingFactors[ps_] := Module[{lead},
  lead = Numerator[Together[Last[ps]]];
  DeleteCases[FactorList[lead][[All, 1]], _?NumericQ]];

HCTSingularPoints[ps_, x_, tc_: 240] := Module[{roots},
  roots = Quiet@TimeConstrained[
    Solve[Numerator[Together[Last[ps]]] == 0, x], tc, $Failed];
  If[! ListQ[roots], $Failed,
    Quiet@TimeConstrained[DeleteDuplicates[Simplify[x /. roots]], 120,
                          DeleteDuplicates[x /. roots]]]];

(* normalize the scalar ODE to polynomial coefficients *)
HCTPolyOperator[ps_, x_] := Module[{den, q, g},
  den = PolynomialLCM @@ (Denominator[Together[#]] & /@ ps);
  q = Expand[Together[# den]] & /@ ps;
  (* remove common content, else spurious singular points appear *)
  g = PolynomialGCD @@ DeleteCases[q, 0];
  If[! TrueQ[g === 1 || NumericQ[g]], q = Expand[Cancel[#/g]] & /@ q];
  q];

HCT$LastIdentify = <||>;

HCTIdentifyOperator[red_, x_] := Module[
  {n, ps, sing, pts, sch, res, i, ex, fuchs, mob, ab, cpar, a, b, c, hyp, chk},
  res = <|"Rung" -> "R3"|>;
  n = red["Order"];
  ps = Quiet@TimeConstrained[HCTPolyOperator[HCTOperatorCoefficients[red], x], 300, $Failed];
  If[ps === $Failed,
    res["Status"] = "operator normalization timed out";
    HCT$LastIdentify = res;
    Return[res, Module]];
  res["Order"] = n;
  res["PolyCoefficients"] = ps;
  HCT$LastIdentify = res;   (* mirror partial work: survives a rung abort *)
  res["LeadingFactors"] = Quiet@TimeConstrained[HCTLeadingFactors[ps], 240,
                                                Missing["factorization timeout"]];
  Print["    [R3] leading-coefficient factors: ", res["LeadingFactors"]];
  HCT$LastIdentify = res;
  sing = HCTSingularPoints[ps, x];
  If[sing === $Failed,
    res["SingularPoints"] = Missing["Solve timed out; see LeadingFactors"];
    res["RiemannScheme"] = {};
    res["Type"] = "order " <> ToString[n] <> " (singular points unresolved)";
    Print["    [R3] singular points UNRESOLVED -- factorization retained"];
    Return[res, Module]];
  pts = Append[sing, Infinity];
  res["SingularPoints"] = pts;
  sch = {};
  Do[
    ex = Quiet@TimeConstrained[HCTIndicial[ps, x, pts[[i]]], 180, $Failed];
    If[ex =!= $Failed,
      Print["    [R3] exponents at x = ", pts[[i]], " : ", ex["Exponents"]];
      AppendTo[sch, ex];
      res["RiemannScheme"] = sch; HCT$LastIdentify = res,
      Print["    [R3] exponents at x = ", pts[[i]], " : TIMEOUT"]],
    {i, Length[pts]}];
  res["RiemannScheme"] = sch;
  res["AllPointsResolved"] = Length[sch] === Length[pts];
  HCT$LastIdentify = res;
  res["ExponentClasses"] =
    Association@Table[ToString[sch[[i]]["Point"]] -> (HCTExponentClass /@ sch[[i]]["Exponents"]),
                      {i, Length[sch]}];
  (* Fuchs relation:  sum of all exponents = (n-1)n/2 * (#points - 2)         *)
  fuchs = Simplify[Total[Flatten[#["Exponents"] & /@ sch]]];
  res["ExponentSum"] = fuchs;
  res["FuchsExpected"] = (n - 1) n/2 (Length[sch] - 2);
  res["FuchsRelationHolds"] = TrueQ[Simplify[fuchs == (n - 1) n/2 (Length[sch] - 2)]];
  (* --- order 2 with exactly 3 singular points => Gauss 2F1, mechanically --- *)
  If[n === 2 && Length[sch] === 3,
    res["Type"] = "Riemann P / Gauss hypergeometric";
    res["Hypergeometric"] = HCTRiemannToGauss[sch, x],
    If[n === 2,
      res["Type"] = "order 2, " <> ToString[Length[sch]] <> " singular points";
      res["Note"] = "check for apparent singularities; if they reduce the count to 3 it is still 2F1",
      res["Type"] = "order " <> ToString[n];
      res["SymmetricPower"] = HCTSymmetricPowerTest[sch, n]]];
  res];

(* Riemann scheme -> 2F1 parameters.  Mechanical, no guessing:
     map the 3 points to {0,1,Inf} by a Moebius transformation,
     y = X^a1 (1-X)^b1 2F1(a,b;c;X),
     a = a1+b1+g1, b = a1+b1+g2, c = 1 + a1 - a2.                            *)
HCTRiemannToGauss[sch_, x_] := Module[
  {pts, exps, finite, inf, p0, p1, X, e0, e1, ei, out, choices, i, a1, a2, b1, b2, g1, g2},
  pts = #["Point"] & /@ sch;
  exps = #["Exponents"] & /@ sch;
  inf = Position[pts, Infinity];
  finite = Complement[Range[Length[pts]], Flatten[inf]];
  If[Length[inf] =!= 1 || Length[finite] =!= 2,
    <|"Status" -> "3 points but not {finite,finite,Inf}", "Points" -> pts|>,
    p0 = pts[[finite[[1]]]]; p1 = pts[[finite[[2]]]];
    (* prefer 0 as the base point when it is one of them *)
    If[TrueQ[Simplify[p1 == 0]], {p0, p1} = {p1, p0};
       finite = Reverse[finite]];
    X = Simplify[(x - p0)/(p1 - p0)];
    e0 = exps[[finite[[1]]]]; e1 = exps[[finite[[2]]]]; ei = exps[[Flatten[inf][[1]]]];
    out = {};
    choices = Tuples[{{1, 2}, {1, 2}, {1, 2}}];
    Do[
      a1 = e0[[choices[[i, 1]]]]; a2 = e0[[3 - choices[[i, 1]]]];
      b1 = e1[[choices[[i, 2]]]]; b2 = e1[[3 - choices[[i, 2]]]];
      g1 = ei[[choices[[i, 3]]]]; g2 = ei[[3 - choices[[i, 3]]]];
      AppendTo[out, <|
        "a" -> Simplify[a1 + b1 + g1], "b" -> Simplify[a1 + b1 + g2],
        "c" -> Simplify[1 + a1 - a2],
        "Prefactor" -> HoldForm[X^a1 (1 - X)^b1] /. {a1 -> a1, b1 -> b1},
        "PrefactorExponents" -> {a1, b1},
        "Argument" -> X|>],
      {i, Length[choices]}];
    <|"Status" -> "ok", "Argument" -> X, "MappedPoints" -> {p0, p1, Infinity},
      "Branches" -> out,
      "Canonical" -> First@SortBy[out, LeafCount[{#["PrefactorExponents"]}] &]|>]];

(* order 3/4: is the scheme consistent with Sym^k of an order-2, or with a
   tensor product of two order-2s?  Necessary conditions on exponents.       *)
HCTSymmetricPowerTest[sch_, n_] := Module[{ok2, ok3, oktp, i, e, res},
  res = <|"Order" -> n|>;
  If[n === 3,
    ok2 = True;
    Do[
      e = Sort[Simplify[sch[[i]]["Exponents"]]];
      If[Length[e] =!= 3 || ! TrueQ[Simplify[e[[1]] + e[[3]] == 2 e[[2]]]], ok2 = False],
      {i, Length[sch]}];
    res["Sym2OfOrder2"] = ok2;
    res["Criterion"] = "exponents at every point must be {2a, a+b, 2b} i.e. in arithmetic progression"];
  If[n === 4,
    ok3 = True; oktp = True;
    Do[
      e = Sort[Simplify[sch[[i]]["Exponents"]]];
      If[Length[e] =!= 4,
        ok3 = False; oktp = False,
        (* Sym^3: {3a,2a+b,a+2b,3b} -> arithmetic progression *)
        If[! (TrueQ[Simplify[e[[2]] - e[[1]] == e[[3]] - e[[2]]]] &&
              TrueQ[Simplify[e[[3]] - e[[2]] == e[[4]] - e[[3]]]]), ok3 = False];
        (* tensor product of two order-2: {a1+a2,a1+b2,b1+a2,b1+b2} -> e1+e4 == e2+e3 *)
        If[! TrueQ[Simplify[e[[1]] + e[[4]] == e[[2]] + e[[3]]]], oktp = False]],
      {i, Length[sch]}];
    res["Sym3OfOrder2"] = ok3;
    res["TensorOfTwoOrder2"] = oktp;
    res["Criterion"] = "Sym^3: exponents in arithmetic progression; tensor: e1+e4 == e2+e3 at every point"];
  res];

(* ------------------------------------------------------------------------- *)
(* Reconcile SCALAR-ODE exponents with SYSTEM residue exponents.
   They are NOT the same object.  The scalar ODE for the component y = c.F has
   exponents that exceed the system's residue eigenvalues by a non-negative
   integer at any locus where that component of the corresponding eigenvector
   vanishes.  On class 115 this is exactly the -3/2-4eps (system, and F2) vs
   -1/2-4eps (component F1) discrepancy that made two correct records look
   contradictory.  Always report both.                                        *)

HCTMatchLocus[L_, x0_, zexpr_, xvar_] := Module[{sub, r},
  r = False;
  If[MissingQ[zexpr] || zexpr === "none",
    (* two-variable route: xvar is v or w, locus matched by direct substitution *)
    r = TrueQ[Simplify[(L /. xvar -> x0) == 0]],
    sub = Quiet@Solve[zexpr == x0, w];
    If[ListQ[sub] && sub =!= {},
      r = TrueQ[Simplify[(L /. First[sub]) == 0]]]];
  r];

HCTReconcileExponents[r1bc_, r3_, zexpr_, xvar_] := Module[
  {out, i, j, pt, sysE, scaE, shifts, hits},
  out = {};
  Do[
    pt = r3["RiemannScheme"][[i]]["Point"];
    scaE = r3["RiemannScheme"][[i]]["Exponents"];
    If[pt =!= Infinity,
      hits = Select[r1bc, HCTMatchLocus[#["Locus"], pt, zexpr, xvar] &];
      If[hits =!= {},
        sysE = hits[[1]]["Exponents"];
        shifts = If[MissingQ[sysE], Missing["non-Fuchsian"],
                    Quiet@Simplify[Sort[scaE] - Sort[sysE]]];
        AppendTo[out, <|"ScalarPoint" -> pt, "Locus" -> hits[[1]]["Locus"],
                        "SystemExponents" -> sysE, "ScalarExponents" -> scaE,
                        "IntegerShifts" -> shifts|>]]],
    {i, Length[r3["RiemannScheme"]]}];
  out];

(* ============================================================== R4 ======== *)
(* Certify a 2F1 identification EXACTLY: the cyclic-vector reduction is an
   exact equivalence, so it suffices to show the reduced operator equals the
   Gauss operator (in the mapped variable, after the prefactor) identically.  *)

HCTCertifyGauss[red_, x_, hyp_, Av_, Aw_, zexpr_] := Module[
  {ps, X, a, b, c, pre, y, gauss, sub, resid, det, cert, num, i, pt, val},
  cert = <|"Rung" -> "R4"|>;
  ps = HCTPolyOperator[HCTOperatorCoefficients[red], x];
  X = hyp["Canonical"]["Argument"];
  a = hyp["Canonical"]["a"]; b = hyp["Canonical"]["b"]; c = hyp["Canonical"]["c"];
  pre = hyp["Canonical"]["PrefactorExponents"];
  (* Build the ODE satisfied by y = X^p (1-X)^q 2F1(a,b;c;X) and compare *)
  y = X^pre[[1]] (1 - X)^pre[[2]] HCT$F[X];
  gauss = X (1 - X) Derivative[2][HCT$F][X] + (c - (a + b + 1) X) HCT$F'[X] - a b HCT$F[X];
  (* substitute y into the reduced operator, then eliminate F'' via gauss *)
  resid = Sum[ps[[k + 1]] D[y, {x, k}], {k, 0, red["Order"]}];
  resid = Expand[resid /. Derivative[2][HCT$F][X] ->
                   (Derivative[2][HCT$F][X] /. First@Solve[gauss == 0, Derivative[2][HCT$F][X]])];
  (* F and F' are independent: every coefficient must vanish separately *)
  num = {Simplify[Together[Coefficient[resid, HCT$F[X]]]],
         Simplify[Together[Coefficient[resid, HCT$F'[X]]]],
         Simplify[Together[resid - Coefficient[resid, HCT$F[X]] HCT$F[X] -
                                   Coefficient[resid, HCT$F'[X]] HCT$F'[X]]]};
  cert["ExactOperatorResidual"] = num;
  cert["ExactMatch"] = AllTrue[num, TrueQ[Simplify[# == 0]] &];
  det = Simplify[Det[red["ReconstructionMatrix"]]];
  cert["ReconstructionDet"] = det;
  cert["ReconstructionInvertible"] = ! TrueQ[Simplify[det == 0]];
  cert["Method"] = "exact: cyclic-vector equivalence + operator identity";
  cert];

(* numeric fallback / independent check of a solution vector in the ORIGINAL
   two-variable system, at random rational points, high precision           *)
HCTNumericCheck[Av_, Aw_, Fvec_, npts_: 3, prec_: 60] := Module[
  {out, i, ptv, ptw, pte, r1, r2},
  out = {};
  Do[
    ptv = 1/(5 + 2 i) + 1/23; ptw = 1/(7 + 3 i) + 1/29; pte = 1/(11 + i);
    r1 = Quiet@N[(D[Fvec, v] - Av . Fvec) /. {v -> ptv, w -> ptw, eps -> pte}, prec];
    r2 = Quiet@N[(D[Fvec, w] - Aw . Fvec) /. {v -> ptv, w -> ptw, eps -> pte}, prec];
    AppendTo[out, <|"Point" -> {ptv, ptw, pte},
                    "MaxResidual" -> Max[Abs[Flatten[{r1, r2}]]]|>],
    {i, npts}];
  out];

(* ============================================================== driver ==== *)

Options[AttackClass] = {
  "Rungs" -> All, "Verbose" -> True, "ApplyBalances" -> False,
  "ScalarVariable" -> Automatic, "TimeConstraint" -> 900};

AttackClass[cdIn_Association, OptionsPattern[]] := Module[
  {cd, Av, Aw, dim, id, rep, rows, rep1a, cen, r1d, rungs, out, t, red, ident,
   cert, xvar, Aone, zexpr, sysOne, t0, obstruction},
  cd = HCTNormalize[cdIn];
  Av = HCTtog[cd["RepAv"]]; Aw = HCTtog[cd["RepAw"]];
  dim = Length[Av];
  id = If[KeyExistsQ[cd, "ClassID"], cd["ClassID"], "?"];
  rep = If[KeyExistsQ[cd, "RepFamily"], cd["RepFamily"], "?"];
  rows = If[KeyExistsQ[cd, "RepRows"], cd["RepRows"], {}];
  rungs = OptionValue["Rungs"];
  out = <|"ClassID" -> id, "Dim" -> dim, "RepFamily" -> rep, "RepRows" -> rows,
          "ToolkitVersion" -> HCT$Version|>;
  Print["=== AttackClass: class ", id, " (", rep, " rows ", rows, "), dim ", dim, " ==="];

  (* ---- R1a ---- *)
  If[rungs === All || MemberQ[rungs, "R1a"],
    t0 = AbsoluteTime[];
    rep1a = HCTOneVariableTest[Av, Aw];
    out["R1a"] = rep1a;
    out["T_R1a"] = AbsoluteTime[] - t0;
    Print["  [R1a] commutator=", rep1a["Commutator"],
          "  proportional=", rep1a["Proportional"],
          "  ONE-VARIABLE=", If[KeyExistsQ[rep1a, "OneVariable"], rep1a["OneVariable"], "n/a"],
          If[KeyExistsQ[rep1a, "Invariant"] && ! MissingQ[rep1a["Invariant"]],
             "  z=" <> ToString[rep1a["Invariant"]], ""],
          "   (", Round[out["T_R1a"], 0.01], "s)"]];

  (* ---- R1b/R1c ---- *)
  If[rungs === All || MemberQ[rungs, "R1c"],
    t0 = AbsoluteTime[];
    cen = HCTSingularCensus[Av, Aw];
    out["R1bc"] = cen;
    out["T_R1bc"] = AbsoluteTime[] - t0;
    out["ApparentLoci"] = Select[cen, TrueQ[#["EpsDependent"]] &];
    out["NonFuchsianLoci"] = Select[cen, ! TrueQ[#["Fuchsian"]] &];
    out["HalfIntegerLoci"] = Select[cen,
      (! MissingQ[#["Exponents"]]) && AnyTrue[Flatten[{#["Exponents"]}], HCTHalfIntegerQ] &];
    Print["  [R1b/c] ", Length[cen], " loci; ",
          Length[out["ApparentLoci"]], " eps-dependent (apparent); ",
          Length[out["NonFuchsianLoci"]], " non-Fuchsian; ",
          Length[out["HalfIntegerLoci"]], " with half-integer exponents",
          "   (", Round[out["T_R1bc"], 0.01], "s)"]];

  (* ---- R1d ---- *)
  If[rungs === All || MemberQ[rungs, "R1d"],
    t0 = AbsoluteTime[];
    r1d = Quiet@TimeConstrained[HCTInvariantSubspace[Av, Aw], OptionValue["TimeConstraint"],
                                <|"Status" -> "timeout"|>];
    out["R1d"] = r1d;
    out["T_R1d"] = AbsoluteTime[] - t0;
    Print["  [R1d] permutation-reducible=",
          If[KeyExistsQ[r1d, "PermutationReducible"], r1d["PermutationReducible"], "?"],
          "  rank-1 subsystems=",
          If[KeyExistsQ[r1d, "Rank1Subsystems"], Length[r1d["Rank1Subsystems"]], "?"],
          "   (", Round[out["T_R1d"], 0.01], "s)"]];

  (* ---- R2: choose the reduction variable ---- *)
  If[rungs === All || MemberQ[rungs, "R2"],
    t0 = AbsoluteTime[];
    xvar = OptionValue["ScalarVariable"];
    Aone = Missing["none"]; zexpr = Missing["none"];
    If[TrueQ[out["R1a"]["OneVariable"]] && ! MissingQ[out["R1a"]["Mz"]],
      (* genuine one-variable system: reduce in z, exactly as class 115 wants *)
      zexpr = out["R1a"]["Invariant"];
      Aone = HCTmap[Simplify, out["R1a"]["Mz"] /. HCT$Z -> HCT$zv];
      xvar = HCT$zv;
      Print["  [R2] one-variable route: reducing in z = ", zexpr],
      (* genuine two-variable: reduce in v with w a parameter *)
      If[xvar === Automatic, xvar = v];
      Aone = If[xvar === v, Av, Aw];
      Print["  [R2] two-variable block: reducing in ", xvar, " (other variable is a parameter)"]];
    red = Quiet@TimeConstrained[
      HCTBestScalarReduction[Aone, xvar, 8, 0.8 OptionValue["TimeConstraint"]],
      OptionValue["TimeConstraint"], <|"Status" -> "timeout"|>];
    (* recover partial work if the rung was aborted outright *)
    If[red["Status"] =!= "ok" && HCT$LastReductions =!= {},
      red = Append[First@SortBy[HCT$LastReductions, {#["LeafCount"] &, #["Index"] &}],
                   "Note" -> "recovered after rung timeout; not all cyclic vectors tried"];
      Print["    [R2] recovered a reduction from partial work"]];
    out["R2"] = red; out["R2Variable"] = xvar; out["R2Invariant"] = zexpr;
    out["T_R2"] = AbsoluteTime[] - t0;
    Print["  [R2] status=", red["Status"],
          If[red["Status"] === "ok",
             "  order " <> ToString[red["Order"]] <> ", LeafCount " <> ToString[red["LeafCount"]], ""],
          "   (", Round[out["T_R2"], 0.01], "s)"]];

  (* ---- R3 ---- *)
  If[(rungs === All || MemberQ[rungs, "R3"]) && KeyExistsQ[out, "R2"] && out["R2"]["Status"] === "ok",
    t0 = AbsoluteTime[];
    HCT$LastIdentify = <||>;
    ident = Quiet@TimeConstrained[HCTIdentifyOperator[out["R2"], out["R2Variable"]],
                                  OptionValue["TimeConstraint"], <|"Status" -> "timeout"|>];
    If[! KeyExistsQ[ident, "PolyCoefficients"] && KeyExistsQ[HCT$LastIdentify, "PolyCoefficients"],
      ident = Append[HCT$LastIdentify, "Note" -> "recovered after rung timeout; scheme may be partial"];
      Print["    [R3] recovered partial identification (operator + factors retained)"]];
    out["R3"] = ident;
    If[KeyExistsQ[out, "R1bc"] && KeyExistsQ[ident, "RiemannScheme"],
      out["R3Reconciliation"] =
        Quiet@TimeConstrained[
          HCTReconcileExponents[out["R1bc"], ident, out["R2Invariant"], out["R2Variable"]],
          300, Missing["timeout"]];
      If[ListQ[out["R3Reconciliation"]],
        Do[Print["    [R3] reconcile ", rc["Locus"], " : system ", rc["SystemExponents"],
                 "  vs component ", rc["ScalarExponents"], "  shift ", rc["IntegerShifts"]],
           {rc, out["R3Reconciliation"]}]]];
    out["T_R3"] = AbsoluteTime[] - t0;
    Print["  [R3] type=", If[KeyExistsQ[ident, "Type"], ident["Type"], "?"],
          If[KeyExistsQ[ident, "Hypergeometric"] && ident["Hypergeometric"]["Status"] === "ok",
             "\n        2F1 parameters: a=" <>
             ToString[ident["Hypergeometric"]["Canonical"]["a"]] <> ", b=" <>
             ToString[ident["Hypergeometric"]["Canonical"]["b"]] <> ", c=" <>
             ToString[ident["Hypergeometric"]["Canonical"]["c"]] <> ", arg=" <>
             ToString[ident["Hypergeometric"]["Canonical"]["Argument"]], ""],
          "   (", Round[out["T_R3"], 0.01], "s)"]];

  (* ---- R4 ---- *)
  If[(rungs === All || MemberQ[rungs, "R4"]) && KeyExistsQ[out, "R3"] &&
     KeyExistsQ[out["R3"], "Hypergeometric"] && out["R3"]["Hypergeometric"]["Status"] === "ok",
    t0 = AbsoluteTime[];
    cert = Quiet@TimeConstrained[
      HCTCertifyGauss[out["R2"], out["R2Variable"], out["R3"]["Hypergeometric"], Av, Aw,
                      out["R2Invariant"]],
      OptionValue["TimeConstraint"], <|"Status" -> "timeout"|>];
    out["R4"] = cert;
    out["T_R4"] = AbsoluteTime[] - t0;
    Print["  [R4] exact operator match=",
          If[KeyExistsQ[cert, "ExactMatch"], cert["ExactMatch"], "?"],
          "  reconstruction invertible=",
          If[KeyExistsQ[cert, "ReconstructionInvertible"], cert["ReconstructionInvertible"], "?"],
          "   (", Round[out["T_R4"], 0.01], "s)"]];

  (* ---- R5: forwarded obstruction ---- *)
  obstruction = HCTObstruction[out];
  out["R5Obstruction"] = obstruction;
  Print["  [R5] ", obstruction];
  out];

HCTObstruction[out_Association] := Module[{s},
  s = {};
  If[KeyExistsQ[out, "R1a"] && ! TrueQ[out["R1a"]["OneVariable"]],
    AppendTo[s, "genuinely two-variable (no common-M / no first integral)"]];
  If[KeyExistsQ[out, "NonFuchsianLoci"] && Length[out["NonFuchsianLoci"]] > 0,
    AppendTo[s, "non-Fuchsian loci needing Moser reduction: " <>
      ToString[#["Locus"] & /@ out["NonFuchsianLoci"]]]];
  If[KeyExistsQ[out, "HalfIntegerLoci"] && Length[out["HalfIntegerLoci"]] > 0,
    AppendTo[s, "half-integer exponents (sqrt letter needed) at: " <>
      ToString[#["Locus"] & /@ out["HalfIntegerLoci"]]]];
  If[KeyExistsQ[out, "ApparentLoci"] && Length[out["ApparentLoci"]] > 0,
    AppendTo[s, "eps-dependent (necessarily apparent) loci: " <>
      ToString[#["Locus"] & /@ out["ApparentLoci"]] <> " [balances reported, NOT applied]"]];
  If[KeyExistsQ[out, "R2"] && out["R2"]["Status"] =!= "ok",
    AppendTo[s, "R2 cyclic-vector reduction did not complete: " <> ToString[out["R2"]["Status"]]]];
  If[KeyExistsQ[out, "R4"] && TrueQ[out["R4"]["ExactMatch"]],
    AppendTo[s, "SOLVED: exact hypergeometric certificate"]];
  If[s === {}, "no obstruction recorded", StringRiffle[s, "; "]]];

(* ------------------------------------------------------- kernel mission pool *)

(* HCTMissionPool[missions, runFn]: dynamic mission queue on 1 main +
   k subkernels.  Every mission spec is submitted up front; WaitNext
   hands each finished subkernel the next spec, so heterogeneous jobs
   (search chunks, DSolve probes, reductions) share the pool without a
   second main kernel.  runFn[spec] runs on a subkernel and must
   return its own tagged result; the CALLER must DistributeDefinitions
   runFn and every symbol it uses BEFORE calling (DistributeDefinitions
   is HoldAll, so the pool cannot forward a symbol list faithfully).
   Returns results in completion order.
   Measured 2026-08-15 (class-97 pool: 12 y-specialized Beke chunks +
   DSolve probe + exterior-square reduction): 331s on 4 subkernels vs
   ~19min serial, single license main. *)
Options[HCTMissionPool] = {"Kernels" -> 4, "Progress" -> Automatic};
HCTMissionPool[missions_List, runFn_, OptionsPattern[]] := Module[
  {nk = OptionValue["Kernels"], prog = OptionValue["Progress"],
   queue, running, results = {}, r, res, t0},
  If[Length[Kernels[]] < nk, LaunchKernels[nk - Length[Kernels[]]]];
  queue = With[{f = runFn, t = #}, ParallelSubmit[f[t]]] & /@ missions;
  running = queue; t0 = AbsoluteTime[];
  While[Length[running] > 0,
    r = WaitNext[running];
    res = r[[1]]; running = r[[3]];
    AppendTo[results, res];
    If[prog === Automatic,
      Print["POOL done ",
        If[ListQ[res] && Length[res] > 0, ToString[res[[1]]],
          ToString[Head[res]]],
        " | remaining=", Length[running],
        " elapsed=", Round[AbsoluteTime[] - t0], "s"],
      prog[res, Length[running], AbsoluteTime[] - t0]]];
  results];

(* ------------------------------------------------------- report / registry *)

HCTPut[expr_, file_] := Module[{tmp},
  tmp = file <> ".tmp";
  Put[expr, tmp];
  RenameFile[tmp, file, OverwriteTarget -> True];
  file];

HCTSaveReport[out_Association, dir_] :=
  HCTPut[out, FileNameJoin[{dir, "attack_class" <> ToString[out["ClassID"]] <> ".wl"}]];

(* campaign-schema record (matches CandidateForms/classN.wl) *)
HCTFormRecord[out_Association, extra_Association] := Join[
  <|"ClassID" -> out["ClassID"], "RepFamily" -> out["RepFamily"],
    "RepRows" -> out["RepRows"], "Dim" -> out["Dim"],
    "Variables" -> {v, w}, "Chart" -> None, "AnsatzDegree" -> None,
    "Validated" -> False|>, extra];

Print["HardClassToolkit ", HCT$Version, " loaded."];
