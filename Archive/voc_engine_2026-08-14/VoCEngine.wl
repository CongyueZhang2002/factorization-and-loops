(* ::Package:: *)

(* VoCEngine.wl -- tier-3 "block-diagonal + variation of constants" engine.

   Conventions (deliberately NO BeginPackage: every symbol lands in Global`,
   which is the context the data files were written in -- class forms carry
   Global`eps, family DEs carry bare v,w,eps, NLO carries Global`Epsilon).
   NEVER load CANONICA into a kernel that loads this file: bare `eps` would
   then parse as the protected CANONICA`eps.

   Symbols: eps (regulator), v,w (kinematics), t (chart variable),
   sqrtQ[k] (inert roots, sqrtQ[k]^2 -> VoCRootQ[k]), tau (path parameter),
   cst[s,k,i] (symbolic integration constants).

   DE convention: dI/dv = Av.I, dI/dw = Aw.I and I = T.F, so
       A'_x = T^-1.A_x.T - T^-1.(d_x T).
   Path: straight segment (v,w)(tau) = base + tau*(target-base), tau in [0,1];
   the whole recursion closes on the segment, and setting tau->1 with a
   symbolic target returns the general (v,w) answer.
*)

If[!ValueQ[VoCRoot],    VoCRoot = "/home/maxzhang/factorization-and-loops"];
If[!ValueQ[VoCScratch], VoCScratch = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad"];
VoCSccDir   := FileNameJoin[{VoCScratch, "scc_verify"}];
VoCFormsDir := FileNameJoin[{VoCScratch, "class_campaign", "forms"}];
VoCEngDir   := FileNameJoin[{VoCScratch, "voc_engine"}];
VoCMapDir   := FileNameJoin[{VoCEngDir, "maps"}];

VoCLog[args___] := (WriteString["stdout",
   "[" <> DateString["ISODateTime"] <> "] " <> StringJoin[ToString /@ {args}] <> "\n"]);

VoCPut[expr_, file_] := Module[{tmp = file <> ".tmp" <> ToString[$ProcessID]},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]; file];

(* ------------------------------------------------------------------ *)
(* 0'. GPL quadrature layer (closed shuffle algebra, no Integrate)     *)
(* ------------------------------------------------------------------ *)

If[!ValueQ[GPLLoaded], Get[FileNameJoin[{VoCEngDir, "GPLLayer.wl"}]]];

(* "GPL" (default) or "Integrate" (legacy).  The GPL backend is a complete
   decision procedure for our integrand class; the legacy one calls
   Integrate and dies at weight >= 3. *)
If[!ValueQ[VoCBackendDefault], VoCBackendDefault = "GPL"];

(* tau-derivative that knows about G *)
VoCDtau[e_] := If[FreeQ[e, G], D[e, tau], GPLDeriv[e, tau]];

(* ------------------------------------------------------------------ *)
(* 0. symbol normalisation                                             *)
(* ------------------------------------------------------------------ *)

VoCNormalize[expr_] := expr /. {
   s_Symbol /; SymbolName[s] === "Epsilon" :> eps,
   s_Symbol /; SymbolName[s] === "eps" :> eps,
   s_Symbol /; SymbolName[s] === "v" :> v,
   s_Symbol /; SymbolName[s] === "w" :> w,
   s_Symbol /; SymbolName[s] === "t" :> t};

VoCSwapRule = {v -> w, w -> v};

(* ------------------------------------------------------------------ *)
(* 1. inert square roots                                               *)
(* ------------------------------------------------------------------ *)

VoCRootTable = <||>;
VoCRootN = 0;
VoCRegisterRoot[q_] := Module[{qq = Expand[q], hit},
  hit = SelectFirst[Keys[VoCRootTable], VoCRootTable[#] === qq &, None];
  If[hit =!= None, hit, VoCRootN++; VoCRootTable[VoCRootN] = qq; VoCRootN]];
VoCRootQ[k_Integer] := VoCRootTable[k];

VoCSqrtReduce[e_] := e //. {
   sqrtQ[k_]^n_Integer /; n >= 2 :> VoCRootQ[k]^Quotient[n, 2] sqrtQ[k]^Mod[n, 2],
   sqrtQ[k_]^n_Integer /; n <= -1 :> sqrtQ[k]^(n + 2)/VoCRootQ[k]};

VoCRootsIn[e_] := DeleteDuplicates[Cases[e, sqrtQ[k_] :> k, {0, Infinity}]];

VoCCanon[e_] := Module[{x, num, den, ks, k, a, b},
  x = Together[VoCSqrtReduce[e]];
  den = Denominator[x]; num = Numerator[x];
  ks = VoCRootsIn[den];
  If[ks === {}, Return[Together[VoCSqrtReduce[num/den]]]];
  k = First[ks];
  den = Expand[VoCSqrtReduce[den]];
  a = den /. sqrtQ[k] -> 0;
  b = Coefficient[den, sqrtQ[k], 1];
  VoCCanon[Expand[num (a - b sqrtQ[k])]/Expand[VoCSqrtReduce[a^2 - b^2 VoCRootQ[k]]]]];

VoCZeroQ[e_] := Module[{x, num, ks, k, a, b},
  x = VoCCanon[e];
  If[x === 0, Return[True]];
  num = Expand[VoCSqrtReduce[Numerator[Together[x]]]];
  ks = VoCRootsIn[num];
  If[ks === {}, Return[Together[num] === 0]];
  k = First[ks];
  a = num /. sqrtQ[k] -> 0;
  b = Coefficient[num, sqrtQ[k], 1];
  VoCZeroQ[a] && VoCZeroQ[b]];

VoCZeroMatQ[m_] := AllTrue[Flatten[{m}], VoCZeroQ];

(* Zero test for transcendental expressions (Log/PolyLog).
   Returns True (proved exactly), "NumericOnly" (exact test inconclusive but
   a high-precision probe vanishes), or False.  Never returns True on the
   strength of numerics -- callers must treat "NumericOnly" as not proved. *)
VoCZeroFnTime = 90;
VoCZeroFn[e_] := Module[{s},
  If[e === 0, Return[True]];
  (* GPL representation: distinct words are linearly independent over the
     rational functions, so collecting and Together-ing the coefficients is
     an exact decision procedure -- no Simplify, no numerics. *)
  If[!FreeQ[e, G], Return[TrueQ[GPLZeroQ[e, tau]]]];
  s = Together[e];
  If[s === 0, Return[True]];
  s = TimeConstrained[Simplify[s], VoCZeroFnTime, $TimedOut];
  If[s === 0, Return[True]];
  If[s =!= $TimedOut && TrueQ[s == 0], Return[True]];
  If[s === $TimedOut, s = Together[e]];
  If[VoCNumericZeroQ[s], "NumericOnly", False]];

(* probe at interior chamber points; cst[] constants get random rational values *)
VoCNumericZeroQ[e_, npts_: 3, prec_: 40] := Module[{cs, res},
  cs = DeleteDuplicates[Cases[e, _cst, {0, Infinity}]];
  res = Table[
    Module[{sub, val},
     sub = Join[
       {v -> RandomInteger[{200, 700}]/1000, w -> RandomInteger[{100, 250}]/1000,
        tau -> RandomInteger[{100, 900}]/1000},
       Thread[cs -> Table[RandomInteger[{-50, 50}]/17, {Length[cs]}]]];
     val = Quiet[N[e /. sub, prec]];
     If[NumericQ[val], Abs[val], $Failed]], {npts}];
  FreeQ[res, $Failed] && Max[res] < 10^(-prec/2)];

VoCD[e_, x_] := VoCDi[VoCCanon[e], x];
VoCDi[e_, x_] := Module[{ks, k, ee, nn, dd, a, b, q},
  ks = VoCRootsIn[e];
  If[ks === {}, Return[D[e, x]]];
  k = First[ks];
  ee = Together[VoCSqrtReduce[e]]; nn = Expand[Numerator[ee]]; dd = Denominator[ee];
  a = (nn /. sqrtQ[k] -> 0)/dd;
  b = Coefficient[nn, sqrtQ[k], 1]/dd;
  q = VoCRootQ[k];
  VoCDi[a, x] + VoCDi[b, x] sqrtQ[k] + b D[q, x]/(2 q) sqrtQ[k]];
VoCDMat[m_, x_] := Map[VoCD[#, x] &, m, {2}];

VoCSwap[e_] := Module[{ks = VoCRootsIn[e], sub},
  sub = Table[sqrtQ[k] -> sqrtQ[VoCRegisterRoot[Expand[VoCRootQ[k] /. VoCSwapRule]]], {k, ks}];
  e /. Join[VoCSwapRule, sub]];

(* ------------------------------------------------------------------ *)
(* 2. data loaders                                                     *)
(* ------------------------------------------------------------------ *)

VoCBlocksAll[] := VoCBlocksAll[] = VoCNormalize[Get[FileNameJoin[{VoCSccDir, "blocks.wl"}]]];
VoCClassesAll[] := VoCClassesAll[] = VoCNormalize[Get[FileNameJoin[{VoCSccDir, "classes.wl"}]]];
VoCAssignAll[] := VoCAssignAll[] = Get[FileNameJoin[{VoCSccDir, "block_class_assign.wl"}]];

VoCClassByID[id_] := VoCClassByID[id] = SelectFirst[VoCClassesAll[], #["ClassID"] === id &, $Failed];
VoCClassForm[id_] := VoCClassForm[id] = Module[{f = FileNameJoin[{VoCFormsDir, "class" <> ToString[id] <> ".wl"}]},
   If[FileExistsQ[f], VoCNormalize[Get[f]], $Failed]];

VoCFamilyDE[fam_String] := VoCFamilyDE[fam] = Module[{f, d},
   f = FileNameJoin[{VoCRoot, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
      "DifferentialEquations", "nnlo_de_" <> fam <> ".wl"}];
   If[!FileExistsQ[f], Return[$Failed]];
   d = VoCNormalize[Get[f]];
   <|"Family" -> fam, "Basis" -> d["BlockBasis"], "Av" -> d["Av"], "Aw" -> d["Aw"]|>];

VoCNLOSystem[] := VoCNLOSystem[] = Module[{d, ds},
   d = VoCNormalize[Get[FileNameJoin[{VoCRoot, "ppHX_NLO", "Results", "NLO_UU_Masters.wl"}]]];
   ds = d["DifferentialSystem"];
   <|"Family" -> "NLO", "Basis" -> ds["Basis"], "Av" -> ds["Av"], "Aw" -> ds["Aw"],
     "Masters" -> d["Masters"]|>];

(* family + its stored SCC blocks and class assignment, with an independent
   recomputation of the SCC partition as a cross-check *)
VoCPrepareFamily[fam_String] := Module[{sys, asg, blocks, mine, ok},
  sys = VoCFamilyDE[fam];
  If[sys === $Failed, Return[$Failed]];
  asg = Select[VoCAssignAll[], #["Family"] === fam &];
  blocks = Transpose[{asg[[All, "Rows"]], asg[[All, "ClassID"]]}];
  mine = VoCSCCBlocks[sys["Av"], sys["Aw"]];
  ok = Sort[Sort /@ blocks[[All, 1]]] === mine;
  <|"System" -> sys, "Blocks" -> blocks, "SCCAgrees" -> ok, "SCCMine" -> mine|>];

(* ------------------------------------------------------------------ *)
(* 3. SCC decomposition and block-triangular ordering                  *)
(* ------------------------------------------------------------------ *)

VoCSCCBlocks[av_, aw_] := Module[{n = Length[av], edges, g},
  edges = DeleteCases[Flatten@Table[
      If[i =!= j && !(VoCZeroQ[av[[i, j]]] && VoCZeroQ[aw[[i, j]]]), i -> j, Null],
      {i, n}, {j, n}], Null];
  g = Graph[Range[n], edges];
  Sort[Sort /@ ConnectedComponents[g]]];

VoCOrderBlocks[av_, aw_, blocks_] := Module[{nb = Length[blocks], edges, ord},
  edges = DeleteCases[Flatten@Table[
      If[i =!= j &&
         !(VoCZeroMatQ[av[[blocks[[i]], blocks[[j]]]]] && VoCZeroMatQ[aw[[blocks[[i]], blocks[[j]]]]]),
        j -> i, Null], {i, nb}, {j, nb}], Null];
  ord = TopologicalSort[Graph[Range[nb], edges]];
  If[Head[ord] =!= List || Length[ord] =!= nb, $Failed, ord]];

(* ------------------------------------------------------------------ *)
(* 4. per-block canonical data                                          *)
(* ------------------------------------------------------------------ *)

(* 4a. 1x1 canonicalisation by an explicit dlog prefactor *)
VoCScalarEpsForm[av_, aw_] := Module[{a0v, a0w, lets, cs, dlv, dlw, eqs, sol, T, ev, ew, free},
  (* only entries regular at eps = 0 are handled by this cheap route *)
  If[VoCEpsOrder[av] < 0 || VoCEpsOrder[aw] < 0, Return[$Failed]];
  a0v = Together[av /. eps -> 0]; a0w = Together[aw /. eps -> 0];
  lets = DeleteDuplicates@Select[
     Join @@ (FactorList[Denominator[#]][[All, 1]] & /@ {a0v, a0w}), !FreeQ[#, v | w] &];
  If[lets === {},
   If[Together[a0v] === 0 && Together[a0w] === 0,
     Return[<|"T" -> {{1}}, "Ev" -> {{Together[av]}}, "Ew" -> {{Together[aw]}}, "Source" -> "scalar-dlog"|>],
     Return[$Failed]]];
  cs = Table[Unique["ccx"], {Length[lets]}];
  dlv = Sum[cs[[i]] D[lets[[i]], v]/lets[[i]], {i, Length[lets]}];
  dlw = Sum[cs[[i]] D[lets[[i]], w]/lets[[i]], {i, Length[lets]}];
  eqs = Flatten[{CoefficientList[Numerator[Together[a0v - dlv]], {v, w}],
                 CoefficientList[Numerator[Together[a0w - dlw]], {v, w}]}];
  sol = Quiet@Solve[Thread[DeleteDuplicates[eqs] == 0], cs];
  If[sol === {} || Head[sol] =!= List, Return[$Failed]];
  cs = cs /. First[sol];
  free = Cases[cs, s_Symbol /; StringMatchQ[SymbolName[s], "ccx*"], {0, Infinity}];
  cs = cs /. Thread[free -> 0];
  T = Times @@ Table[lets[[i]]^cs[[i]], {i, Length[lets]}];
  If[!(Together[a0v - D[Log[T], v]] === 0 && Together[a0w - D[Log[T], w]] === 0), Return[$Failed]];
  ev = Together[av - D[Log[T], v]]; ew = Together[aw - D[Log[T], w]];
  If[!(FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps]), Return[$Failed]];
  <|"T" -> {{T}}, "Ev" -> {{ev}}, "Ew" -> {{ew}}, "Source" -> "scalar-dlog"|>];

(* 4b. equivalence map block <-> class representative *)
VoCFindMap[bav_, baw_, rav_, raw_] := Module[{d = Length[bav], perms, res = $Failed, cand},
  perms = Permutations[Range[d]];
  Do[cand = If[sw, {VoCSwap[baw], VoCSwap[bav]}, {bav, baw}];
     Do[If[res === $Failed,
        If[VoCZeroMatQ[cand[[1]][[p, p]] - rav] && VoCZeroMatQ[cand[[2]][[p, p]] - raw],
          res = <|"Perm" -> p, "Swap" -> sw|>]], {p, perms}],
    {sw, {False, True}}];
  res];

VoCMapFile[fam_, rows_] := FileNameJoin[{VoCMapDir,
    "map_" <> fam <> "_" <> StringRiffle[ToString /@ rows, "-"] <> ".wl"}];

VoCBlockMap[fam_, rows_, bav_, baw_, cid_] := Module[{f = VoCMapFile[fam, rows], cls, m},
  If[FileExistsQ[f], Return[Get[f]]];
  If[!DirectoryQ[VoCMapDir], CreateDirectory[VoCMapDir, CreateIntermediateDirectories -> True]];
  cls = VoCClassByID[cid];
  If[cls === $Failed, Return[$Failed]];
  m = VoCFindMap[bav, baw, cls["RepAv"], cls["RepAw"]];
  If[m === $Failed, Return[$Failed]];
  m = Join[m, <|"Family" -> fam, "Rows" -> rows, "ClassID" -> cid|>];
  VoCPut[m, f];
  m];

(* 4c. class form pulled back to (v,w); charts -> inert sqrtQ *)
VoCChartQ[cid_, chart_] := Module[{cls = VoCClassByID[cid], dens, cands, tdeg},
  tdeg[p_] := Exponent[p /. {v -> VoCss v, w -> VoCss w}, VoCss];
  dens = DeleteDuplicates@Flatten@Map[
     FactorList[Denominator[Together[#]]][[All, 1]] &, {cls["RepAv"], cls["RepAw"]}, {3}];
  cands = Select[dens, !FreeQ[#, v | w] && tdeg[#] >= 2 &];
  (* the stored Root still contains the eliminated variable, exactly as
     hardclasses.wls built it: q|_subst == (Root|_subst)^2 in the chart frame *)
  SelectFirst[cands,
   Together[(# /. chart["Subst"]) - (chart["Root"] /. chart["Subst"])^2] === 0 &, $Failed]];

VoCFormInVW[cid_] := VoCFormInVW[cid] = Module[
  {form = VoCClassForm[cid], chart, q, k, texpr, tsub, tv, tw, ex1, et, fixed, ev, ew},
  If[form === $Failed, Return[$Failed]];
  (* SCHEMA FIX 2026-08-14: 7 of the 170 stored class forms (100, 134, 138,
     147, 155, 161, 172) were written WITHOUT a "Chart" key at all, while the
     rest carry "Chart" -> None.  form["Chart"] then returns Missing[...],
     which is not === None, so the chart branch below was entered with a
     Missing chart and every family using one of those classes died with
     "NoForm" (this is what killed CF360).  A chart-free class and an absent
     key mean the same thing.  The resulting form still has to pass the
     assembly certificate, so a wrong reading here cannot pass silently. *)
  chart = Lookup[form, "Chart", None];
  If[chart === None || MissingQ[chart],
    Return[<|"T" -> form["Transformation"], "Ev" -> form["EpsForm"][[1]],
             "Ew" -> form["EpsForm"][[2]], "Chart" -> None, "Root" -> None|>]];
  q = VoCChartQ[cid, chart];
  If[q === $Failed, Return[$Failed]];
  k = VoCRegisterRoot[q];
  texpr = t /. First[Solve[chart["Root"] == sqrtQ[k], t]];
  tsub = t -> texpr;
  tv = VoCD[texpr, v]; tw = VoCD[texpr, w];
  fixed = chart["Fixed"];
  {ex1, et} = form["EpsForm"];
  ex1 = Map[VoCCanon[# /. tsub] &, ex1, {2}];
  et = Map[VoCCanon[# /. tsub] &, et, {2}];
  If[fixed === v,
    ev = Map[VoCCanon, ex1 + et tv, {2}]; ew = Map[VoCCanon, et tw, {2}],
    ew = Map[VoCCanon, ex1 + et tw, {2}]; ev = Map[VoCCanon, et tv, {2}]];
  <|"T" -> Map[VoCCanon[# /. tsub] &, form["Transformation"], {2}],
    "Ev" -> ev, "Ew" -> ew, "Chart" -> chart, "Root" -> k, "RootQ" -> q, "TExpr" -> texpr|>];

(* branch check: does the chart substitution composed with the inverse
   reproduce (v,w) at a chamber point, with sqrtQ = +Sqrt[q] ? *)
VoCChartBranchCheck[cid_, pt_] := Module[{rep = VoCFormInVW[cid], form = VoCClassForm[cid], k, qv, tv, res},
  If[rep === $Failed || rep["Chart"] === None, Return[<|"Status" -> "NoChart"|>]];
  k = rep["Root"];
  qv = N[VoCRootQ[k] /. {v -> pt[[1]], w -> pt[[2]]}, 40];
  tv = N[rep["TExpr"] /. sqrtQ[k] -> Sqrt[qv] /. {v -> pt[[1]], w -> pt[[2]]}, 40];
  res = N[(form["Chart"]["Subst"][[2]] /. t -> tv) /. {v -> pt[[1]], w -> pt[[2]]}, 40];
  <|"Status" -> "OK", "q" -> qv, "t" -> tv, "Recovered" -> res, "Target" -> N[pt[[2]], 40],
    "Residual" -> Abs[res - pt[[2]]], "Fixed" -> form["Chart"]["Fixed"]|>];

VoCBlockFormFromClass[fam_, rows_, bav_, baw_, cid_] := Module[
  {map, rep, d = Length[rows], Tb, Evb, Ewb, Tr, ev, ew, z},
  rep = VoCFormInVW[cid];
  If[rep === $Failed, Return[<|"Status" -> "NoForm", "ClassID" -> cid|>]];
  map = VoCBlockMap[fam, rows, bav, baw, cid];
  If[map === $Failed, Return[<|"Status" -> "NoMap", "ClassID" -> cid|>]];
  {Tr, ev, ew} = {rep["T"], rep["Ev"], rep["Ew"]};
  If[map["Swap"], Tr = Map[VoCSwap, Tr, {2}]; {ev, ew} = {Map[VoCSwap, ew, {2}], Map[VoCSwap, ev, {2}]}];
  z = ConstantArray[0, {d, d}];
  Tb = z; Tb[[map["Perm"], map["Perm"]]] = Tr;
  Evb = z; Evb[[map["Perm"], map["Perm"]]] = ev;
  Ewb = z; Ewb[[map["Perm"], map["Perm"]]] = ew;
  <|"Status" -> "OK", "T" -> Tb, "Ev" -> Evb, "Ew" -> Ewb, "ClassID" -> cid,
    "Map" -> map, "Source" -> "class" <> ToString[cid], "Chart" -> rep["Chart"]|>];

(* ------------------------------------------------------------------ *)
(* 5. assembly + conjugation certificate                               *)
(* ------------------------------------------------------------------ *)

Options[VoCAssemble] = {"Provider" -> "Class", "Blocks" -> Automatic, "Verbose" -> True};

VoCAssemble[sys_Association, OptionsPattern[]] := Module[
  {fam = sys["Family"], av = sys["Av"], aw = sys["Aw"], n, blocks, cids, ord, perm,
   pav, paw, forms, Tinv, Ap = <||>, cert = <||>, ranges, nb, ti, tj, diagOK, triOK,
   verbose = OptionValue["Verbose"], prov = OptionValue["Provider"], blkspec, t0, apv, apw},
  n = Length[av];
  blkspec = OptionValue["Blocks"];
  If[blkspec === Automatic,
    blocks = VoCSCCBlocks[av, aw]; cids = ConstantArray[None, Length[blocks]],
    blocks = blkspec[[All, 1]]; cids = blkspec[[All, 2]]];
  If[verbose, VoCLog[fam, ": ", n, " masters, ", Length[blocks], " SCC blocks, dims ",
     Tally[Length /@ blocks]]];
  ord = VoCOrderBlocks[av, aw, blocks];
  If[ord === $Failed, Return[<|"Status" -> "OrderFailed"|>]];
  blocks = blocks[[ord]]; cids = cids[[ord]];
  perm = Flatten[blocks];
  If[Sort[perm] =!= Range[n], Return[<|"Status" -> "BlocksNotAPartition"|>]];
  pav = av[[perm, perm]]; paw = aw[[perm, perm]];
  nb = Length[blocks];
  ranges = FoldList[Plus, 0, Length /@ blocks];
  ranges = Table[Range[ranges[[i]] + 1, ranges[[i + 1]]], {i, nb}];
  triOK = AllTrue[Flatten@Table[If[i < j,
      {pav[[ranges[[i]], ranges[[j]]]], paw[[ranges[[i]], ranges[[j]]]]}, {}], {i, nb}, {j, nb}], VoCZeroQ];
  cert["BlockLowerTriangular"] = triOK;
  If[verbose, VoCLog["  block-lower-triangular after sort: ", triOK]];
  cert["FlatnessOriginal"] = VoCZeroMatQ[VoCDMat[av, w] - VoCDMat[aw, v] + av.aw - aw.av];
  If[verbose, VoCLog["  flatness of original A: ", cert["FlatnessOriginal"]]];
  t0 = AbsoluteTime[];
  forms = Table[
    Module[{rows = blocks[[i]], sav, saw},
     sav = av[[rows, rows]]; saw = aw[[rows, rows]];
     If[prov === "Scalar",
      If[Length[rows] =!= 1, <|"Status" -> "NotScalar"|>,
       Module[{r = VoCScalarEpsForm[sav[[1, 1]], saw[[1, 1]]]},
        If[r === $Failed, <|"Status" -> "ScalarFailed"|>, Join[<|"Status" -> "OK"|>, r]]]],
      VoCBlockFormFromClass[fam, rows, sav, saw, cids[[i]]]]],
    {i, nb}];
  If[!AllTrue[forms, #["Status"] === "OK" &],
    Return[<|"Status" -> "FormFailed", "Blocks" -> blocks,
             "Failures" -> Select[Transpose[{blocks, forms}], #[[2]]["Status"] =!= "OK" &]|>]];
  If[verbose, VoCLog["  block forms ready (", Round[AbsoluteTime[] - t0], "s)"]];
  t0 = AbsoluteTime[];
  Tinv = Table[Map[VoCCanon, Inverse[forms[[i]]["T"]], {2}], {i, nb}];
  Do[ti = ranges[[i]];
   Do[tj = ranges[[j]];
    If[i >= j,
     Module[{blkv, blkw},
      blkv = Tinv[[i]].pav[[ti, tj]].forms[[j]]["T"];
      blkw = Tinv[[i]].paw[[ti, tj]].forms[[j]]["T"];
      If[i === j,
       blkv = blkv - Tinv[[i]].VoCDMat[forms[[i]]["T"], v];
       blkw = blkw - Tinv[[i]].VoCDMat[forms[[i]]["T"], w]];
      Ap[{i, j}] = {Map[VoCCanon, blkv, {2}], Map[VoCCanon, blkw, {2}]}]],
    {j, nb}], {i, nb}];
  If[verbose, VoCLog["  conjugation done (", Round[AbsoluteTime[] - t0], "s)"]];
  diagOK = Table[
    VoCZeroMatQ[Ap[{i, i}][[1]] - forms[[i]]["Ev"]] && VoCZeroMatQ[Ap[{i, i}][[2]] - forms[[i]]["Ew"]],
    {i, nb}];
  cert["DiagonalEqualsEpsForm"] = AllTrue[diagOK, TrueQ];
  cert["DiagonalPerBlock"] = diagOK;
  cert["EpsFormLinear"] = AllTrue[Flatten[Table[{forms[[i]]["Ev"], forms[[i]]["Ew"]}, {i, nb}]],
     (# === 0 || FreeQ[Together[#/eps], eps]) &];
  cert["OffDiagonalUpperZero"] = "by construction (T block-diagonal, A block-lower-triangular)";
  If[verbose, VoCLog["  diagonal blocks = class eps-forms: ", cert["DiagonalEqualsEpsForm"],
     " ; eps-linearity of the diagonal: ", cert["EpsFormLinear"]]];
  apv = ConstantArray[0, {n, n}]; apw = ConstantArray[0, {n, n}];
  Do[If[i >= j,
    apv[[ranges[[i]], ranges[[j]]]] = Ap[{i, j}][[1]];
    apw[[ranges[[i]], ranges[[j]]]] = Ap[{i, j}][[2]]], {i, nb}, {j, nb}];
  t0 = AbsoluteTime[];
  cert["FlatnessConjugated"] = VoCZeroMatQ[VoCDMat[apv, w] - VoCDMat[apw, v] + apv.apw - apw.apv];
  If[verbose, VoCLog["  flatness of A': ", cert["FlatnessConjugated"],
     " (", Round[AbsoluteTime[] - t0], "s)"]];
  <|"Status" -> "OK", "Family" -> fam, "N" -> n, "Perm" -> perm, "Blocks" -> blocks,
    "Ranges" -> ranges, "ClassIDs" -> cids, "Forms" -> forms, "Tinv" -> Tinv,
    "Apv" -> apv, "Apw" -> apw, "Av" -> pav, "Aw" -> paw,
    "Basis" -> If[MissingQ[sys["Basis"]], None, sys["Basis"][[perm]]], "Certificate" -> cert|>];

VoCCertificateOK[asm_] := asm["Status"] === "OK" && And @@ (TrueQ /@ {
    asm["Certificate"]["BlockLowerTriangular"], asm["Certificate"]["DiagonalEqualsEpsForm"],
    asm["Certificate"]["EpsFormLinear"], asm["Certificate"]["FlatnessConjugated"],
    asm["Certificate"]["FlatnessOriginal"]});

(* ------------------------------------------------------------------ *)
(* 6. eps-Laurent helpers                                              *)
(* ------------------------------------------------------------------ *)

VoCEpsOrder[e_] := Module[{x = Together[e]},
  If[x === 0, Infinity, Exponent[Numerator[x], eps, Min] - Exponent[Denominator[x], eps, Min]]];

VoCLaurent[e_, {r0_, r1_}] := Module[{x = Together[e], sd},
  If[x === 0, Return[ConstantArray[0, r1 - r0 + 1]]];
  sd = Normal[Series[x, {eps, 0, r1}]];
  Table[Together[Coefficient[sd, eps, r]], {r, r0, r1}]];

VoCLaurentMat[m_, {r0_, r1_}] := Module[{co = Map[VoCLaurent[#, {r0, r1}] &, m, {2}]},
  Table[Map[#[[r - r0 + 1]] &, co, {2}], {r, r0, r1}]];

(* ------------------------------------------------------------------ *)
(* 7. path pull-back and the order-by-order solver                     *)
(* ------------------------------------------------------------------ *)

VoCBasePoint = {1/4, 1/4};

VoCPathMatrix[asm_, target_, base_] := Module[{dv, dw, sub},
  dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
  sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
  If[VoCRootsIn[{asm["Apv"], asm["Apw"]}] =!= {}, Return[$Failed]];
  Map[Together, (asm["Apv"] dv + asm["Apw"] dw) /. sub, {2}]];

(* one definite quadrature  int_0^tau g(sigma) dsigma, memoised *)
VoCIntCache = <||>;
VoCIntOne[g_, assum_, lim_] := Module[{sig, res},
  If[g === 0, Return[0]];
  If[KeyExistsQ[VoCIntCache, {g, assum}], Return[VoCIntCache[{g, assum}]]];
  sig = Unique["sg"];
  res = TimeConstrained[Quiet[Integrate[g /. tau -> sig, {sig, 0, tau}, Assumptions -> assum]],
    lim, $TimedOut];
  If[res === $TimedOut || !FreeQ[res, Integrate | ConditionalExpression | Indeterminate |
      ComplexInfinity | DirectedInfinity], res = $Failed];
  VoCIntCache[{g, assum}] = res;
  res];

(* Split an integrand into  (simple pole in tau) x (transcendental factor).
   Every quadrature then becomes a standard one-letter GPL step, which
   Integrate does quickly, and the pieces repeat so the cache compounds. *)
VoCSplitApart[t_] := Module[{fac, tr, ra},
  fac = If[Head[t] === Times, List @@ t, {t}];
  tr = Times @@ Select[fac, ! FreeQ[#, Log | PolyLog | Zeta] &];
  ra = Times @@ Select[fac, FreeQ[#, Log | PolyLog | Zeta] &];
  Expand[Quiet[Apart[ra, tau]] tr]];

VoCPrepIntegrand[g_] := Module[{e = Expand[g]},
  If[Head[e] === Plus, Total[VoCSplitApart /@ (List @@ e)], VoCSplitApart[e]]];

Options[VoCPathIntegrate] = {"Assumptions" -> True, "TimeLimit" -> 300, "Backend" -> Automatic};
VoCPathIntegrate[g0_, OptionsPattern[]] := Module[
  {g, res, prim, sig, terms, lim = OptionValue["TimeLimit"], assum = OptionValue["Assumptions"],
   backend = OptionValue["Backend"]},
  If[backend === Automatic, backend = VoCBackendDefault];
  (* ---- GPL backend: closed shuffle algebra, exact, ms-scale ---- *)
  If[backend === "GPL",
   If[g0 === 0 || Together[g0] === 0, Return[0]];
   Return[GPLDefInt[g0, tau]]];
  (* ---- legacy Integrate backend ---- *)
  g = Together[g0];
  If[g === 0, Return[0]];
  terms = VoCPrepIntegrand[g];
  (* term by term first for large integrands: each piece is far easier and
     pieces repeat across eps-orders, so the cache compounds *)
  If[Head[terms] === Plus && LeafCount[terms] > 60,
   res = Map[VoCIntOne[#, assum, Max[30, Round[lim/4]]] &, List @@ terms];
   If[FreeQ[res, $Failed], Return[Total[res]]]];
  res = VoCIntOne[g, assum, lim];
  If[res =!= $Failed, Return[res]];
  If[Head[terms] === Plus,
   res = Map[VoCIntOne[#, assum, Max[30, Round[lim/4]]] &, List @@ terms];
   If[FreeQ[res, $Failed], Return[Total[res]]]];
  (* 3. antiderivative + endpoints *)
  sig = Unique["sg"];
  prim = TimeConstrained[Quiet[Integrate[g /. tau -> sig, sig]], lim, $TimedOut];
  If[prim === $TimedOut || !FreeQ[prim, Integrate], Return[$Failed]];
  res = (prim /. sig -> tau) - Quiet[Limit[prim, sig -> 0, Direction -> "FromAbove"]];
  If[!FreeQ[res, Indeterminate | ComplexInfinity | DirectedInfinity | Limit], Return[$Failed]];
  res];

(* Design-doc Q5: every letter restricted to the segment must have fixed
   sign.  For a numeric endpoint this is decided exactly by root counting;
   for a symbolic endpoint we can only report "NotChecked". *)
VoCPathLetterCheck[ahat_] := Module[{fs, bad},
  fs = DeleteDuplicates@Flatten@Map[
     FactorList[Denominator[Together[#]]][[All, 1]] &, ahat, {2}];
  fs = Select[fs, !FreeQ[#, tau] &];
  If[!FreeQ[fs, v | w], Return[<|"Status" -> "NotChecked", "Letters" -> fs|>]];
  bad = Select[fs, Quiet[CountRoots[#, {tau, 0, 1}]] =!= 0 &];
  <|"Status" -> If[bad === {}, "FixedSign", "VanishesOnPath"], "Letters" -> fs, "Bad" -> bad|>];

(* ------------------------------------------------------------------ *)
(*  DEPTH BUDGET -- and the arithmetic that decides what can be CHECKED *)
(*                                                                      *)
(*  This budget answers "how deep must each sector be SOLVED".  It does  *)
(*  NOT answer "how deep must we go to VERIFY the assembled solution",   *)
(*  and the two are different.  The master series spans [n0, n0+kmax],   *)
(*  i.e. kmax+1 orders, while the assembled check at order n consumes    *)
(*  I_{n-r} down to r = rmin(A), so it needs I up to n + |rmin(A)|.      *)
(*  Therefore                                                           *)
(*                                                                      *)
(*      order n checkable  <=>  n <= n0 + kmax - |rmin(A)|              *)
(*      number checkable    =   kmax - |rmin(A)| + 1                    *)
(*      ANY check at all requires   kmax >= |rmin(A)|                    *)
(*                                                                      *)
(*  Confirmed on every gate: NLO |rmin|=0,kmax=2 -> 3 checkable (3 seen);*)
(*  CF3 |rmin|=1,kmax=3 -> 3 (3 seen); CF360 |rmin|=2,kmax=2 -> 1 (1);   *)
(*  CF123 |rmin|=2,kmax=1 -> 0 (0 seen -- the whole solve was            *)
(*  unverifiable, which is NOT a failure of the solution).               *)
(*                                                                      *)
(*  So CF360 passing at exactly kmax=2 was the MINIMUM, not luck.  When  *)
(*  setting production depth, satisfy BOTH requirements at once or a     *)
(*  family gets solved to a depth that can never be certified.           *)
(* ------------------------------------------------------------------ *)
VoCDepthBudget[asm_, ahat_, kmax_] := Module[{nb = Length[asm["Blocks"]], ranges = asm["Ranges"], need, rmin},
  need = ConstantArray[kmax, nb];
  rmin = Table[If[i > j,
     Min[Append[VoCEpsOrder /@ Flatten[ahat[[ranges[[i]], ranges[[j]]]]], Infinity]], Infinity],
    {i, nb}, {j, nb}];
  Do[Do[If[j < i && rmin[[i, j]] =!= Infinity,
      need[[j]] = Max[need[[j]], need[[i]] - rmin[[i, j]]]], {j, nb}], {i, nb, 1, -1}];
  <|"Need" -> need, "RMin" -> rmin|>];

(* ------------------------------------------------------------------ *)
(* 7'. VALUATION CONSTRAINTS                                           *)
(*                                                                     *)
(*  "KMin" means ONE thing: the true Laurent valuation n0 of the        *)
(*  PHYSICAL masters I -- the order at which the exact answer starts.   *)
(*  It is simultaneously                                               *)
(*     (a) the reference for the valuation constraints below, and       *)
(*     (b) the starting order the boundary-fixing stage uses            *)
(*         (VoCConstantRules / the gates' exact-master expansions).     *)
(*  These are ONE physics statement and must never be split by a        *)
(*  refactor: if (b) starts at a different order than (a), the          *)
(*  constrained subfamily and the boundary data describe different      *)
(*  functions and every downstream check silently compares apples to    *)
(*  pears.                                                             *)
(*                                                                     *)
(*  Why constraints are needed at all: F = T^-1.I, so on a block where  *)
(*  T is singular at eps=0 (det T ~ eps) F has valuation BELOW n0 and   *)
(*  must be solved from kminF = n0 + ord(T^-1) < n0.  Solving from      *)
(*  there admits extra low-order homogeneous solutions that are pure    *)
(*  gauge: the general family has I_n =/= 0 for n < n0, which the       *)
(*  physical answer forbids.  Imposing I_n == 0 (n0 > n >= kminF+tr0)   *)
(*  identically in tau is a LINEAR system on the integration constants  *)
(*  and cuts the family down to the physical subfamily.                 *)
(*  Verified on CF360: without it the assembled DE check fails on the   *)
(*  2x2 block; with it, order eps^0 vanishes on every row.              *)
(* ------------------------------------------------------------------ *)

(* smallest eps order occurring in any T^-1 block (clipped at 0) *)
VoCTinvOrderMin[asm_] := Min[Append[DeleteCases[Flatten[
    Table[VoCEpsOrder /@ Flatten[asm["Tinv"][[s]]], {s, Length[asm["Ranges"]]}]],
   Infinity], 0]];

(* linear equations expressing "e vanishes identically in tau" *)
VoCValEqs[e_] := Module[{c, eqs = {}},
  If[e === 0, Return[{}]];
  If[FreeQ[e, G],
   Return[DeleteCases[CoefficientList[Expand[Numerator[Together[e]]], tau], 0]]];
  c = GPLCollect[e, tau];
  If[c === $Failed, Return[$Failed]];
  Do[eqs = Join[eqs, DeleteCases[
      CoefficientList[Expand[Numerator[Together[Lookup[c, Key[k]]]]], tau], 0]],
   {k, Keys[c]}];
  eqs];

Options[VoCSolve] = {"KMin" -> -1, "KMax" -> 2, "Base" -> Automatic, "Target" -> {v, w},
   "Assumptions" -> Automatic, "TimeLimit" -> 300, "Verbose" -> True, "ConstantRules" -> {},
   "Backend" -> Automatic, "VerifyQuadratures" -> True};

VoCSolve[asm_, OptionsPattern[]] := Module[
  {ahat, nb, ranges, kmin = OptionValue["KMin"], kmax = OptionValue["KMax"],
   target = OptionValue["Target"], base, budget, need, rmin, F, assum, res, r0, r1, lau,
   crules = OptionValue["ConstantRules"], t0, tt, verbose = OptionValue["Verbose"],
   failed = False, rminAll, warn = {}, lcheck, backend = OptionValue["Backend"],
   qchk = {}, times = {}, nint = 0,
   kminPhys, kminF, tinvMin, valRules = {}, valOK = True, valOrders = {}, valEqs = 0},
  If[backend === Automatic, backend = VoCBackendDefault];
  (* KMin is the PHYSICAL valuation n0 of I (see section 7').  F = T^-1.I can
     start lower, by ord(T^-1); solve it from there and cut the extra
     low-order homogeneous freedom afterwards with valuation constraints. *)
  kminPhys = kmin;
  tinvMin = VoCTinvOrderMin[asm];
  kminF = kminPhys + Min[0, tinvMin];
  kmin = kminF;
  base = If[OptionValue["Base"] === Automatic, VoCBasePoint, OptionValue["Base"]];
  ahat = VoCPathMatrix[asm, target, base];
  If[ahat === $Failed, Return[<|"Status" -> "AlgebraicPathUnsupported"|>]];
  nb = Length[asm["Blocks"]]; ranges = asm["Ranges"];
  assum = If[OptionValue["Assumptions"] === Automatic,
    If[FreeQ[target, v | w], 0 < tau < 1, 0 < tau < 1 && 0 < v < 1 && 0 < w < 1 && v + w < 1],
    OptionValue["Assumptions"]];
  budget = VoCDepthBudget[asm, ahat, kmax];
  need = budget["Need"]; rmin = budget["RMin"];
  rminAll = Min[Append[DeleteCases[Flatten[rmin], Infinity], 0]];
  lcheck = VoCPathLetterCheck[ahat];
  If[verbose, VoCLog["  depth budget per sector: ", need, "  (global rmin ", rminAll, ")"];
    VoCLog["  letters on the segment: ", lcheck["Status"], " (", Length[lcheck["Letters"]],
      " letters", If[lcheck["Status"] === "VanishesOnPath",
        ", VANISHING: " <> ToString[InputForm[lcheck["Bad"]]], ""], ")"]];
  r0 = rminAll; r1 = Max[need] - kmin;
  lau = VoCLaurentMat[ahat, {r0, r1}];
  F = <||>;
  Do[If[!failed,
    Do[If[!failed,
      Module[{d = Length[ranges[[s]]], rhs, k = kk},
       rhs = ConstantArray[0, d];
       Do[Module[{rmat = lau[[r - r0 + 1]], m = kk - r},
         Do[If[j < s || (j === s && m < kk),
           If[KeyExistsQ[F, {j, m}],
             rhs = rhs + rmat[[ranges[[s]], ranges[[j]]]].F[{j, m}],
             If[m >= kmin && !VoCZeroMatQ[rmat[[ranges[[s]], ranges[[j]]]]],
               AppendTo[warn, {"missing", s, kk, j, m}]]]],
          {j, s}]],
        {r, r0, r1}];
       rhs = If[backend === "GPL", rhs, Map[Together, rhs]];
       t0 = AbsoluteTime[];
       res = Table[VoCPathIntegrate[rhs[[i]], "Assumptions" -> assum,
          "TimeLimit" -> OptionValue["TimeLimit"], "Backend" -> backend], {i, d}];
       tt = AbsoluteTime[] - t0;
       nint += d;
       AppendTo[times, <|"Sector" -> s, "Order" -> kk, "N" -> d, "Seconds" -> tt|>];
       If[MemberQ[res, $Failed],
        VoCLog["  !! integration failed at sector ", s, " order eps^", kk,
          If[backend === "GPL" && GPLFailures =!= {},
            "  (last GPL assertion: " <> ToString[Last[GPLFailures][[1]]] <> ")", ""]];
        failed = True,
        (* exact per-quadrature check:  d/dtau F - source == 0, by Together *)
        If[TrueQ[OptionValue["VerifyQuadratures"]] && backend === "GPL",
         Module[{zz},
          zz = Table[TrueQ[GPLZeroQ[GPLDeriv[res[[i]], tau] - rhs[[i]], tau]], {i, d}];
          AppendTo[qchk, <|"Sector" -> s, "Order" -> kk, "Zero" -> zz|>];
          If[!AllTrue[zz, TrueQ],
           VoCLog["  !! quadrature verification FAILED at sector ", s,
             " order eps^", kk, ": ", zz]]]];
        F[{s, kk}] = Table[cst[s, kk, i] + res[[i]], {i, d}] /. crules;
        If[verbose, VoCLog["  sector ", s, " rows ", asm["Blocks"][[s]], " order eps^", kk,
           ": ", Round[tt, 0.01], "s, leaves ", LeafCount[F[{s, kk}]],
           If[qchk =!= {} && Last[qchk]["Sector"] === s && Last[qchk]["Order"] === kk,
             ", d/dtau check " <> ToString[AllTrue[Last[qchk]["Zero"], TrueQ]], ""]]]]]],
     {kk, kmin, need[[s]]}]],
   {s, nb}];
  (* ---------- valuation constraints + their assertion ---------- *)
  If[!failed && kminF < kminPhys,
   Module[{tmp, lo, msLow, eqs = {}, csts, sol, bad},
    lo = kminF + VoCTOrderMin[asm];
    valOrders = Range[lo, kminPhys - 1];
    If[valOrders =!= {},
     tmp = <|"F" -> F, "KMin" -> kminF, "Need" -> need, "Base" -> base, "Target" -> target|>;
     msLow = VoCMasterSeries[asm, tmp, {lo, kminPhys - 1}];
     Do[Do[Module[{ee = VoCValEqs[msLow["I"][[oi, i]]]},
        If[ee === $Failed, valOK = False, eqs = Join[eqs, ee]]],
        {i, asm["N"]}], {oi, Length[msLow["I"]]}];
     eqs = DeleteDuplicates[DeleteCases[eqs, 0]];
     valEqs = Length[eqs];
     csts = DeleteDuplicates[Cases[Values[F], _cst, {0, Infinity}]];
     sol = If[eqs === {}, {{}}, Quiet[Solve[Thread[eqs == 0], csts]]];
     If[Head[sol] =!= List || sol === {},
      valOK = False;
      VoCLog["  !! VALUATION CONSTRAINTS INCONSISTENT (", valEqs, " equations)"],
      valRules = First[sol];
      F = ((# /. valRules) &) /@ F;
      If[verbose, VoCLog["  valuation: I must vanish for eps^", lo, "..eps^",
         kminPhys - 1, "; ", valEqs, " equations fixed ", Length[valRules],
         " of ", Length[csts], " constants"]];
      (* ASSERTION (runs in every production solve): the constrained family
         really does have the claimed valuation.  Never silent. *)
      tmp = <|"F" -> F, "KMin" -> kminF, "Need" -> need, "Base" -> base, "Target" -> target|>;
      msLow = VoCMasterSeries[asm, tmp, {lo, kminPhys - 1}];
      bad = Select[Flatten[msLow["I"]], !TrueQ[VoCZeroFn[#]] &];
      If[bad =!= {},
       valOK = False;
       VoCLog["  !! VALUATION ASSERTION FAILED: I does not vanish below eps^",
         kminPhys, " (", Length[bad], " nonzero components)"],
       If[verbose, VoCLog["  valuation assertion: I vanishes on eps^", lo,
          "..eps^", kminPhys - 1, " -- OK"]]]]]]];
  <|"Status" -> If[failed, "IntegrationFailed", "OK"], "F" -> F, "KMin" -> kmin, "KMax" -> kmax,
    "Need" -> need, "RMin" -> rminAll, "Target" -> target, "Base" -> base, "Ahat" -> ahat,
    "LetterCheck" -> lcheck, "Warnings" -> warn, "Backend" -> backend,
    "QuadCheck" -> qchk, "QuadPass" -> (qchk =!= {} && AllTrue[Flatten[qchk[[All, "Zero"]]], TrueQ]),
    "Times" -> times, "NIntegrals" -> nint,
    "KMinPhysical" -> kminPhys, "TinvOrderMin" -> tinvMin,
    "ValuationOK" -> valOK, "ValuationRules" -> valRules,
    "ValuationOrders" -> valOrders, "ValuationEqs" -> valEqs,
    "TotalSeconds" -> If[times === {}, 0, Total[times[[All, "Seconds"]]]]|>];

(* !!! BUG FIX 2026-08-14 -- silent, and it invalidated every assembled
   path-frame DE check.  This read

       Module[{n = asm["N"], out = ConstantArray[0, n], ranges = ...}, ...]

   but Module initializers are NOT sequentially scoped: the `n` inside the
   second initializer is the still-unassigned local symbol, so in 14.2
   ConstantArray[0, n] returns a structured SymbolicZerosArray[{n}] of
   length 1 instead of {0,...,0} -- with no error.  The first sector's Part
   assignment then mutated that 1-element object and the assignments for all
   further sectors failed with Set::partw, so I = T.F silently kept ONLY
   sector 1 (and degenerated to a scalar Plus at higher orders).  Note the
   defect is invisible for single-sector systems.
   `out` is therefore now built in the BODY, and the shape is asserted. *)
VoCFVector[asm_, solv_, k_] := Module[{n = asm["N"], out, ranges = asm["Ranges"]},
  out = ConstantArray[0, n];
  If[Head[out] =!= List || Length[out] =!= n,
   VoCLog["  !! VoCFVector: zero vector has wrong shape ", Head[out], " ", Length[out]];
   Return[$Failed]];
  Do[If[KeyExistsQ[solv["F"], {s, k}], out[[ranges[[s]]]] = solv["F"][{s, k}]], {s, Length[ranges]}];
  out];

(* T as a Laurent series in eps, block-diagonal, in the permuted basis *)
VoCTLaurent[asm_, {r0_, r1_}] := Module[{n = asm["N"], ranges = asm["Ranges"], nb = Length[asm["Ranges"]]},
  Table[Module[{z = ConstantArray[0, {n, n}]},
    Do[z[[ranges[[s]], ranges[[s]]]] =
       Map[VoCLaurent[#, {r0, r1}][[r - r0 + 1]] &, asm["Forms"][[s]]["T"], {2}], {s, nb}];
    z], {r, r0, r1}]];

VoCTOrderMin[asm_] := Min[Append[DeleteCases[
    Flatten[Table[VoCEpsOrder /@ Flatten[asm["Forms"][[s]]["T"]], {s, Length[asm["Ranges"]]}]],
    Infinity], 0]];

(* I = T.F expanded in eps, coefficients in the PERMUTED basis.

   !!! BUG FIX -- READ THIS BEFORE TRUSTING ANY EARLIER PATH-FRAME RESULT !!!
   Until 2026-08-14 this routine returned T as a function of (v,w) while
   VoCCheckDEPath compares d/dtau I against the PATH-RESTRICTED A.  Those two
   are inconsistent, so the path-frame DE check could NEVER have passed as
   written -- it was simply never reached, because the Integrate backend died
   in the quadratures first.  ANY earlier claim that rests on VoCCheckDEPath
   must be re-run with the fixed version below.

   "PathT" (default True) restricts T to the same straight segment the
   quadratures use, so that I(tau) is a genuine function of the path
   parameter and  dI/dtau = Ahat.I  holds.  (With T left in (v,w) the
   path-frame DE check compares apples to pears and can never pass.)
   At tau = 1 the substitution is the identity, so the (v,w)-frame use of
   the result is unaffected. *)
Options[VoCMasterSeries] = {"PathT" -> True};
VoCMasterSeries[asm_, solv_, {n0_, n1_}, OptionsPattern[]] := Module[
  {tr0, tr1, tl, out, kmaxF, sub, bp, tp},
  tr0 = VoCTOrderMin[asm]; tr1 = n1 - solv["KMin"];
  kmaxF = Max[solv["Need"]];
  tl = VoCTLaurent[asm, {tr0, tr1}];
  If[TrueQ[OptionValue["PathT"]],
   bp = solv["Base"]; tp = solv["Target"];
   sub = {v -> bp[[1]] + tau (tp[[1]] - bp[[1]]),
          w -> bp[[2]] + tau (tp[[2]] - bp[[2]])};
   tl = Map[Together, tl /. sub, {3}]];
  out = Table[Sum[
     If[solv["KMin"] <= nn - r <= kmaxF, tl[[r - tr0 + 1]].VoCFVector[asm, solv, nn - r],
      ConstantArray[0, asm["N"]]], {r, tr0, tr1}], {nn, n0, n1}];
  <|"Orders" -> Range[n0, n1], "I" -> out, "TR0" -> tr0|>];

(* numeric value of a (possibly GPL-valued) expression at tau = val *)
VoCNAt[expr_, val_: 1, prec_: 40] :=
  If[FreeQ[expr, G], N[expr /. tau -> val, prec], GPLNumeric[expr, tau, val, prec]];
VoCNAtVec[vec_List, val_: 1, prec_: 40] := Map[VoCNAt[#, val, prec] &, vec];

(* ------------------------------------------------------------------ *)
(* 8. verification against the ORIGINAL family DE                      *)
(* ------------------------------------------------------------------ *)

(* (a) on the path: dI/dtau = (Av dv/dtau + Aw dw/dtau).I, order by order *)
VoCCheckDEPath[asm_, solv_, ms_, orders_] := Module[
  {b = solv["Base"], target = solv["Target"], dv, dw, sub, ahat, lau, r0, r1, o0, o1},
  dv = target[[1]] - b[[1]]; dw = target[[2]] - b[[2]];
  sub = {v -> b[[1]] + tau dv, w -> b[[2]] + tau dw};
  ahat = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
  o0 = Min[ms["Orders"]]; o1 = Max[ms["Orders"]];
  r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[ahat], Infinity], 0]];
  r1 = o1 - o0;
  lau = VoCLaurentMat[ahat, {r0, r1}];
  (* A term with r < 0 needs I at order nn-r > nn: with 1/eps^k couplings
     (global rmin = -k) the check at order nn needs the master series up to
     nn+k.  Orders outside [o0,o1] used to be dropped SILENTLY by the range
     guard, which makes the comparison meaningless and reports a spurious
     False (this is exactly what CF360, rmin = -3, did).  Report the lack of
     support explicitly instead. *)
  Table[Module[{lhs, rhs, missing},
    (* Only orders ABOVE the top of the series are genuinely missing: orders
       below n0 are zero by construction (the Laurent expansion starts at the
       minimum order of T and F), so shifts needing them are not a gap. *)
    missing = Select[Range[r0, r1],
       (nn - # > o1) && !VoCZeroMatQ[lau[[# - r0 + 1]]] &];
    lhs = VoCDtau /@ ms["I"][[nn - o0 + 1]];
    rhs = Sum[If[o0 <= nn - r <= o1, lau[[r - r0 + 1]].ms["I"][[nn - r - o0 + 1]],
       ConstantArray[0, asm["N"]]], {r, r0, r1}];
    <|"Order" -> nn,
      "Zero" -> If[missing =!= {}, {"InsufficientOrders"},
         DeleteDuplicates[VoCZeroFn /@ (lhs - rhs)]],
      "MissingShifts" -> missing, "NeedUpTo" -> If[missing === {}, o1, nn - Min[missing]],
      "Residual" -> (lhs - rhs)|>],
   {nn, orders}]];

(* (b) in (v,w) at tau -> 1 (only meaningful for a symbolic target).

   NOTE: with the GPL backend the answer contains G[{a(v,w),...},1], whose
   v- and w-derivatives need the Goncharov parameter-differential (not
   implemented -- see REPORT_GPL.md).  This routine therefore refuses to
   run rather than reporting a meaningless zero test.  The exact statement
   for the GPL backend comes from the path frame (VoCCheckDEPath) plus the
   flatness certificate. *)
VoCCheckDEvw[asm_, ms_, orders_] := Module[{o0 = Min[ms["Orders"]], o1 = Max[ms["Orders"]], iv, lauv, lauw, r0, r1},
  If[!FreeQ[ms["I"], G],
   Return[Table[<|"Order" -> nn, "ZeroV" -> {"NeedsParamDeriv"},
      "ZeroW" -> {"NeedsParamDeriv"}|>, {nn, orders}]]];
  iv = Table[ms["I"][[nn - o0 + 1]] /. tau -> 1, {nn, o0, o1}];
  r0 = Min[Append[DeleteCases[VoCEpsOrder /@ Flatten[{asm["Av"], asm["Aw"]}], Infinity], 0]];
  r1 = o1 - o0;
  lauv = VoCLaurentMat[asm["Av"], {r0, r1}];
  lauw = VoCLaurentMat[asm["Aw"], {r0, r1}];
  Table[Module[{lv, rv, lw, rw},
    lv = D[iv[[nn - o0 + 1]], v]; lw = D[iv[[nn - o0 + 1]], w];
    rv = Sum[If[o0 <= nn - r <= o1, lauv[[r - r0 + 1]].iv[[nn - r - o0 + 1]],
        ConstantArray[0, asm["N"]]], {r, r0, r1}];
    rw = Sum[If[o0 <= nn - r <= o1, lauw[[r - r0 + 1]].iv[[nn - r - o0 + 1]],
        ConstantArray[0, asm["N"]]], {r, r0, r1}];
    <|"Order" -> nn, "ZeroV" -> DeleteDuplicates[VoCZeroFn /@ (lv - rv)],
      "ZeroW" -> DeleteDuplicates[VoCZeroFn /@ (lw - rw)]|>],
   {nn, orders}]];

(* ------------------------------------------------------------------ *)
(* 9. boundary constants from a known expansion at the base point      *)
(* ------------------------------------------------------------------ *)

(* icoef: association order -> numeric vector of I in the ORIGINAL basis order *)
VoCConstantRules[asm_, icoef_Association, kmin_, kmax_] := Module[
  {perm = asm["Perm"], ranges = asm["Ranges"], nb, base = VoCBasePoint, tir0, tir1, til, fk, rules = {}, n = asm["N"]},
  nb = Length[ranges];
  tir0 = Min[Append[DeleteCases[Flatten[Table[VoCEpsOrder /@ Flatten[asm["Tinv"][[s]]], {s, nb}]], Infinity], 0]];
  tir1 = kmax - Min[Keys[icoef]];
  til = Table[Module[{z = ConstantArray[0, {n, n}]},
     Do[z[[ranges[[s]], ranges[[s]]]] =
        Map[VoCLaurent[#, {tir0, tir1}][[r - tir0 + 1]] &, asm["Tinv"][[s]], {2}], {s, nb}];
     z /. {v -> base[[1]], w -> base[[2]]}], {r, tir0, tir1}];
  Do[fk = Sum[If[KeyExistsQ[icoef, k - r], til[[r - tir0 + 1]].(icoef[k - r][[perm]]),
       ConstantArray[0, n]], {r, tir0, tir1}];
   Do[rules = Join[rules, Table[cst[s, k, i] -> fk[[ranges[[s]][[i]]]], {i, Length[ranges[[s]]]}]], {s, nb}],
   {k, kmin, kmax}];
  rules];

(* ------------------------------------------------------------------ *)
(* 10. numeric eps-series of the exact NLO masters                     *)
(* ------------------------------------------------------------------ *)

(* 2F1(1,1;1-eps;z) = Sum_n z^n exp(Sum_m eps^m H_n^(m)/m); exact term by term *)
VoC2F1Series[z_, kmax_, prec_] := Module[{zz, hs, pk, ek, res, n, tol, zpow, j},
  zz = SetPrecision[z, prec + 20];
  tol = 10^(-prec - 15);
  hs = ConstantArray[0, kmax];
  res = ConstantArray[0, kmax + 1];
  zpow = 1;
  n = 0;
  While[True,
   If[n > 0, Do[hs[[m]] = hs[[m]] + 1/SetPrecision[n^m, prec + 20], {m, kmax}]];
   (* e = Exp[P], P = Sum_m hs[[m]]/m eps^m ; k e_k = Sum_{j=1..k} j p_j e_{k-j} *)
   pk = Table[hs[[m]]/m, {m, kmax}];
   ek = ConstantArray[0, kmax + 1]; ek[[1]] = 1;
   Do[ek[[k + 1]] = Sum[j pk[[j]] ek[[k - j + 1]], {j, 1, k}]/k, {k, 1, kmax}];
   res = res + zpow ek;
   If[n > 5 && Abs[zpow] < tol, Break[]];
   If[n > 200000, Break[]];
   n++; zpow = zpow zz];
  res];

(* returns <|"Orders" -> Range[nmin,kmax], "C" -> coefficient list|> *)
VoCExactSeries[expr_, point_, nmin_, kmax_, prec_] := Module[{e, ser},
  e = expr /. {v -> point[[1]], w -> point[[2]]};
  e = e /. Hypergeometric2F1[1, 1, 1 - eps, z_] :> Module[{co = VoC2F1Series[Together[z], kmax - nmin + 3, prec]},
      Sum[co[[k + 1]] eps^k, {k, 0, kmax - nmin + 2}]];
  ser = Normal[Series[e, {eps, 0, kmax}]];
  <|"Orders" -> Range[nmin, kmax], "C" -> Table[N[Coefficient[ser, eps, k], prec], {k, nmin, kmax}]|>];

(* ------------------------------------------------------------------ *)
(* 11. independent numeric route: the SAME recursion solved by NDSolve  *)
(*     along the path (cross-check of the symbolic quadratures)          *)
(* ------------------------------------------------------------------ *)

Options[VoCSolveODE] = {"KMin" -> -1, "KMax" -> 2, "Base" -> Automatic, "Target" -> {1/2, 1/5},
   "Precision" -> 40, "Init" -> <||>, "Verbose" -> True};

VoCSolveODE[asm_, OptionsPattern[]] := Module[
  {ahat, nb, ranges, kmin = OptionValue["KMin"], kmax = OptionValue["KMax"],
   target = OptionValue["Target"], base, budget, need, r0, r1, lau, keys, vars, eqs = {},
   inits = {}, sol, prec = OptionValue["Precision"], init = OptionValue["Init"], fvec, rminAll},
  base = If[OptionValue["Base"] === Automatic, VoCBasePoint, OptionValue["Base"]];
  If[!FreeQ[target, v | w], Return[<|"Status" -> "NeedsNumericTarget"|>]];
  ahat = VoCPathMatrix[asm, target, base];
  If[ahat === $Failed, Return[<|"Status" -> "AlgebraicPathUnsupported"|>]];
  nb = Length[asm["Blocks"]]; ranges = asm["Ranges"];
  budget = VoCDepthBudget[asm, ahat, kmax]; need = budget["Need"];
  rminAll = Min[Append[DeleteCases[Flatten[budget["RMin"]], Infinity], 0]];
  r0 = rminAll; r1 = Max[need] - kmin;
  lau = VoCLaurentMat[ahat, {r0, r1}];
  keys = Flatten[Table[{s, k}, {s, nb}, {k, kmin, need[[s]]}], 1];
  fvec[j_, m_] := If[MemberQ[keys, {j, m}], Table[ff[j, m, i][tau], {i, Length[ranges[[j]]]}],
     ConstantArray[0, Length[ranges[[j]]]]];
  vars = Flatten[Table[ff[key[[1]], key[[2]], i], {key, keys}, {i, Length[ranges[[key[[1]]]]]}]];
  Do[Module[{s = key[[1]], k = key[[2]], rhs},
    rhs = ConstantArray[0, Length[ranges[[s]]]];
    Do[Module[{rmat = lau[[r - r0 + 1]], m = k - r},
      Do[If[j < s || (j === s && m < k),
        rhs = rhs + rmat[[ranges[[s]], ranges[[j]]]].fvec[j, m]], {j, s}]], {r, r0, r1}];
    Do[AppendTo[eqs, ff[s, k, i]'[tau] == rhs[[i]]], {i, Length[ranges[[s]]]}];
    Do[AppendTo[inits, ff[s, k, i][0] == SetPrecision[Lookup[init, cst[s, k, i], 0], prec]],
     {i, Length[ranges[[s]]]}]], {key, keys}];
  sol = Quiet[NDSolve[Join[eqs, inits], vars, {tau, 0, 1}, WorkingPrecision -> prec,
     AccuracyGoal -> prec - 18, PrecisionGoal -> prec - 18, MaxSteps -> 10^7,
     MaxStepFraction -> 1/50, Method -> "StiffnessSwitching",
     InterpolationOrder -> All], {NDSolve::precw}];
  If[Head[sol] =!= List || sol === {}, Return[<|"Status" -> "NDSolveFailed"|>]];
  <|"Status" -> "OK", "Keys" -> keys, "Need" -> need, "KMin" -> kmin,
    "F" -> Association@Table[key -> (Table[ff[key[[1]], key[[2]], i][1], {i, Length[ranges[[key[[1]]]]]}] /.
        First[sol]), {key, keys}], "Target" -> target, "Base" -> base|>];

(* I = T.F at the endpoint from a numeric (or symbolic) F association *)
VoCMasterSeriesFrom[asm_, Fassoc_, kmin_, kmaxF_, {n0_, n1_}, endpoint_] := Module[
  {tr0, tr1, tl, ranges = asm["Ranges"], n = asm["N"], fv},
  tr0 = VoCTOrderMin[asm]; tr1 = n1 - kmin;
  tl = VoCTLaurent[asm, {tr0, tr1}] /. {v -> endpoint[[1]], w -> endpoint[[2]]};
  fv[k_] := Module[{out = ConstantArray[0, n]},
    Do[If[KeyExistsQ[Fassoc, {s, k}], out[[ranges[[s]]]] = Fassoc[{s, k}]], {s, Length[ranges]}]; out];
  <|"Orders" -> Range[n0, n1],
    "I" -> Table[Sum[If[kmin <= nn - r <= kmaxF, tl[[r - tr0 + 1]].fv[nn - r], ConstantArray[0, n]],
       {r, tr0, tr1}], {nn, n0, n1}]|>];

VoCLog["VoCEngine loaded"];
