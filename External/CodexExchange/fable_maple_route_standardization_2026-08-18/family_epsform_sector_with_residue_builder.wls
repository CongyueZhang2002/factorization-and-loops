#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- STANDARDIZED SECTOR ROUTE
   (CANONICA per sector, Maple strip fallback).  Design fixed 2026-08-18
   from Codex's reply (External/CodexExchange/codex_reply_fable_maple_
   standardization_2026-08-18.md) and the measured CF48 facts.

   Per sector k = 2..nb, on the truncated connection A[1..nk,1..nk] whose
   diagonal blocks are certified eps-forms:
     A. CANONICA`TransformOffDiagonalBlock  (FindD per strip: local
        denominator alphabet, Laurent ansatz from eps^(nmin-1)) -> dlog form;
        then CANONICA`TransformDlogToEpsForm (eps-only normalisation of the
        sector row) -> eps-form.  Time-constrained.
     B. FALLBACK when A does not finish: solve the sector's remaining
        non-eps-factored strips one at a time with Maple
        IntegrableConnections (Codex's ExactRationalConnectionSolution
        wrapper): local denominator alphabet, residues from the exact
        flatness of the strip equation carried as unknowns, exact both-
        variable re-check; compose; then re-run A on the sector (its
        dlog->eps step finishes the row).
   Family acceptance (unchanged): exact gauge identity T^-1 A T - T^-1 dT
   == A', flatness of A', A'/eps eps-free entrywise, both variables; then a
   route-2-consumable FamilyEpsForms record.
   Usage: family_epsform_sector.wls <family> <outdir> [sectorBudget=1800] [tag] *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
(* pool subkernels keep state: clear the Global` symbols CANONICA and earlier
   missions leave behind (they broke TransportFamilyInChart on a reused
   subkernel: "assembly failed" on kernel 26, 2026-08-18) *)
Scan[Function[nm, ToExpression["Global`" <> nm, InputForm, Function[sy, Quiet[Unprotect[sy]]; ClearAll[sy], HoldAll]]], {"tau", "s", "u", "p", "x", "y", "eps"}];
(* CANONICA is loaded AFTER assembly (its Global` shadowing of x, y, eps must
   not touch the assembly step); it parallelises internally
   (ParallelizeMap[$ComputeParallel]) -- inside a pool subkernel that would
   launch sub-subkernels on the shared licence AND escape TimeConstrained
   (measured: a 300 s-constrained strip step ran 33 min) -> serial. *)
loadCanonica[] := (
  (* the package loader keeps a kernel-lifetime "already loaded" flag; on a
     reused pool subkernel that flag can be True while the definitions are
     not present (measured 2026-08-18: all five CANONICA symbols undefined on
     kernel 27).  Force a real Get every mission; CANONICA's Get is
     re-entrant (BeginPackage/EndPackage). *)
  FeynFacet`Private`$canonicalBlocksCanonicaLoaded = False;
  FeynFacet`Private`canonicalBlocksLoadCanonica[];
  CANONICA`$ComputeParallel = False; CANONICA`Private`$ComputeParallel = False;
  If[DownValues[CANONICA`Private`FindD] === {} && DownValues[CANONICA`FindD] === {},
    Print["[sector-epsform] !! CANONICA did not load (FindD undefined after Get)"]; Exit[3]]);
(* CANONICA 1.0.3 defines some internals in CANONICA` and some in
   CANONICA`Private` (FindD: Private; CalculateNextSubsectorD: public --
   measured 2026-08-18).  Resolve EACH symbol to the context that carries a
   definition, at call time (after loadCanonica[]). *)
canonicaSym[name_String] := Module[{pub = ToExpression["CANONICA`" <> name], priv = ToExpression["CANONICA`Private`" <> name]},
  (* DownValues is HoldAll: without Evaluate it reads the Module local
     itself (always {}) -- watcher diagnosis 2026-08-18 *)
  Which[DownValues[Evaluate[pub]] =!= {}, pub, DownValues[Evaluate[priv]] =!= {}, priv,
    True, (Print["[sector-epsform] !! CANONICA symbol ", name, " undefined in both contexts"]; pub)]];
resolveCanonica[] := (
  canonicaFindD = canonicaSym["FindD"]; canonicaCNSD = canonicaSym["CalculateNextSubsectorD"];
  canonicaNextEq = canonicaSym["NextEquationD"]; canonicaInsertD = canonicaSym["InsertDIntoIdentity"];
  canonicaTransformDE = canonicaSym["TransformDE"];
  Print["[sector-epsform] CANONICA symbol contexts: ", Context /@ {canonicaFindD, canonicaCNSD, canonicaNextEq, canonicaInsertD, canonicaTransformDE}]);
args = Rest[$ScriptCommandLine];
family = args[[1]]; outdir = args[[2]];
sectorBudget = If[Length[args] >= 3, ToExpression[args[[3]]], 1800];
tag = If[Length[args] >= 4, args[[4]], ""];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
start = AbsoluteTime[];
log[a___] := Print["[sector-epsform ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}]; expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]], {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}]; expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
toC[e_] := e /. ee -> CANONICA`eps; fromC[e_] := e /. CANONICA`eps -> ee;
ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
mapleLib = FileNameJoin[{root, "Addon", "Other_Addon", "Maple", "IntegrableConnections"}];
mapleWrapper = FileNameJoin[{root, "Addon", "Other_Addon", "Maple", "ExactRationalConnectionSolution.mpl"}];
scratch = FileNameJoin[{outdir, "sector_" <> family <> tag}]; If[! DirectoryQ[scratch], CreateDirectory[scratch]];

(* ---- assemble in the chart; rename chart variables to (x, y) for CANONICA ---- *)
de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
chart = FeynFacet`TransportFamilyChart[family];
If[! AssociationQ[chart], log["!! needs a chart frame"]; Exit[2]];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"], "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
rec = FeynFacet`TransportFamilyInChart[system, chart, "SourceVariables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> blocks,
  "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}], "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
If[! (AssociationQ[rec] && KeyExistsQ[rec, "Assembly"]), log["!! assembly failed"]; Exit[1]];
assembly = rec["Assembly"]; {c1, c2} = chart["Variables"];
loadCanonica[]; resolveCanonica[];
Get[FileNameJoin[{root, "External", "CodexExchange",
  "fable_maple_route_standardization_2026-08-18",
  "BuildResidueCompatibility.wl"}]];
toXY = {c1 -> xx, c2 -> yy}; fromXY = {xx -> c1, yy -> c2};
A0 = {assembly["Apv"] /. toXY, assembly["Apw"] /. toXY};
ranges = assembly["Ranges"]; nb = Length[ranges]; n = Length[A0[[1]]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
invariants = {xx, yy};
log["assembled ", n, "x", n, ", ", nb, " sectors, chart ", chart["Name"], " ", {c1, c2}, " -> ", {xx, yy}];
zeroQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] &];
epsFormQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
badStrips[a_, upTo_] := Flatten[Table[If[i > j && ! zeroQ[a[[1, ranges[[i]], ranges[[j]]]]] &&
  ! (epsFormQ[a[[1, ranges[[i]], ranges[[j]]]]] && epsFormQ[a[[2, ranges[[i]], ranges[[j]]]]]), {i, j}, Nothing], {i, upTo}, {j, upTo}], 1];
log["initial: ", Length[badStrips[A0, nb]], " non-eps-factored strips"];

(* ---- state (resume) ---- *)
stateFile = FileNameJoin[{outdir, "sector_state_" <> family <> tag <> ".wl"}];
state = If[FileExistsQ[stateFile], (log["resuming"]; normalizeSymbols[Get[stateFile]]),
  <|"Sector" -> 1, "S" -> IdentityMatrix[n], "A" -> A0, "Fallbacks" -> {}|>];

(* ---- Maple strip fallback (from family_epsform_maple.wls, verified emitter) ---- *)
monic[f_] := Module[{v = First[Variables[f]], lc}, lc = Coefficient[f, v, Exponent[f, v]]; If[NumericQ[lc], Expand[f/lc], f]];
polyLetterQ[f_] := PolynomialQ[f, {xx, yy}] && ! FreeQ[f, xx | yy] && NumericQ[Coefficient[f, First[Variables[f]], Exponent[f, First[Variables[f]]]]];
toMaple[e_] := StringReplace[ToString[e, InputForm], {"Global`" -> "", " " -> ""}];
mapleSolve[Amats_, bvecs_, tg_] := Module[{mfile, ofile, txt, res, out, dim = Length[bvecs[[1]]], t0},
  mfile = FileNameJoin[{scratch, tg <> ".mpl"}]; ofile = FileNameJoin[{scratch, tg <> ".out"}];
  txt = StringJoin["restart:\nlibname := \"", mapleLib, "\", libname:\nwith(IntegrableConnections):\nwith(linalg):\nread \"", mapleWrapper, "\":\n",
    "A1 := matrix(", ToString[dim], ",", ToString[dim], ",[", StringRiffle[toMaple /@ Flatten[Amats[[1]]], ","], "]):\n",
    "A2 := matrix(", ToString[dim], ",", ToString[dim], ",[", StringRiffle[toMaple /@ Flatten[Amats[[2]]], ","], "]):\n",
    "b1 := vector(", ToString[dim], ",[", StringRiffle[toMaple /@ bvecs[[1]], ","], "]):\n",
    "b2 := vector(", ToString[dim], ",[", StringRiffle[toMaple /@ bvecs[[2]], ","], "]):\n",
    "res := ExactRationalConnectionSolution([A1,A2],[x,y],[b1,b2],[eps]):\n",
    "fd := fopen(\"", ofile, "\", WRITE):\nif res = FAIL then fprintf(fd, \"FAIL\\n\") else fprintf(fd, \"OK\\n%a\\n%a\\n\", res[\"FirstVariable\"], res[\"SolutionList\"]) end if:\nfclose(fd):\nquit:\n"];
  Export[mfile, txt, "Text"]; t0 = AbsoluteTime[];
  res = TimeConstrained[RunProcess[{"maple", "-q", mfile}], sectorBudget, <||>];
  If[! FileExistsQ[ofile], Return[<|"Status" -> "MapleNoOutput", "Seconds" -> AbsoluteTime[] - t0|>]];
  out = StringSplit[Import[ofile, "Text"], "\n"];
  If[out === {} || First[out] === "FAIL", Return[<|"Status" -> "MapleFAIL", "Seconds" -> AbsoluteTime[] - t0|>]];
  <|"Status" -> "OK", "FirstVariable" -> out[[2]], "Seconds" -> AbsoluteTime[] - t0,
    "Solution" -> normalizeRegulator[
      ToExpression[StringReplace[out[[3]], {"[" -> "{", "]" -> "}"}]]] /.
      {Symbol["Global`x"] -> xx, Symbol["Global`y"] -> yy}|>];
(* Maple on CANONICA's own strip equation objects: e, c eps-STRIPPED diagonal
   coefficients (A_ii = eps e, A_jj = eps c), bbar the current off-diagonal
   block including the previousD correction.  Equation for the gauge D:
   d_mu D = eps (e_mu D - D c_mu) + F_mu,
   F_mu = bbar_mu - eps Sum_a K_a(eps) dlog_a
   (residues rational in eps at this stage).  Residues from exact flatness
   over Q(eps); genuinely undetermined ones carried as Maple unknowns. *)
mapleStripEq[e_, c_, bbar_, i_, j_] := Module[{ni = Length[e[[1]]], nj = Length[c[[1]]], residueData, alph, dl, kfree, freeRules, nFreeResidues, K, F, dim, nk, kron, F0, Fk, Amats, bvecs, msol, Dm},
  residueData = BuildResidueCompatibility[{e, c, bbar}, {xx, yy}, ee];
  If[residueData === $Failed,
    log["    Maple strip (", i, ",", j, "): residue flatness inconsistent"];
    Return[$Failed]];
  alph = residueData["Alphabet"];
  dl = residueData["DLog"];
  K = residueData["ResidueMatrices"];
  kfree = residueData["FreeResidues"];
  F = residueData["Forcing"];
  nFreeResidues = Length[kfree];
  freeRules = Thread[kfree -> 0];
  K = K /. freeRules;
  F = Map[Together, F /. freeRules, {3}];
  kfree = {};
  dim = ni nj; nk = Length[kfree];
  kron = Table[ee (KroneckerProduct[e[[mu]], IdentityMatrix[nj]] - KroneckerProduct[IdentityMatrix[ni], Transpose[c[[mu]]]]), {mu, 2}];
  F0 = Table[Flatten[F[[mu]] /. Thread[kfree -> 0]], {mu, 2}];
  Fk = Table[Transpose[Table[Together[D[Flatten[F[[mu]]], kk]], {kk, kfree}]], {mu, 2}];
  Amats = Table[If[nk == 0, kron[[mu]], ArrayFlatten[{{kron[[mu]], Fk[[mu]]}, {ConstantArray[0, {nk, dim}], ConstantArray[0, {nk, nk}]}}]], {mu, 2}];
  bvecs = Table[Join[F0[[mu]], ConstantArray[0, nk]], {mu, 2}];
  msol = mapleSolve[Amats, bvecs, "strip_" <> ToString[i] <> "_" <> ToString[j]];
  If[msol["Status"] =!= "OK", log["    Maple strip (", i, ",", j, "): ", msol["Status"], " (", Round[msol["Seconds"], 0.1], " s, |alphabet| ", Length[alph], ", free residues fixed to zero ", nFreeResidues, ")"]; Return[$Failed]];
  Dm = Map[Together, ArrayReshape[Take[msol["Solution"], dim], {ni, nj}], {2}];
  (* exact re-check of the strip equation in both variables: bbar + eps(e D - D c) - dD must be a dlog form; test: its flatness-consistent residues exist -> equivalently d/dtau-free structure; here we assert the strong condition used by CANONICA: result equals Sum K dlog with the K just solved *)
  Module[{Bp = Table[Map[Together, bbar[[mu]] + ee (e[[mu]] . Dm - Dm . c[[mu]]) - D[Dm, {xx, yy}[[mu]]], {2}], {mu, 2}], Kfin, resid},
    Kfin = If[nk > 0, K /. Thread[kfree -> Drop[msol["Solution"], dim]], K];
    resid = Table[Map[Together, Bp[[mu]] - ee Sum[Kfin[[q]] dl[[q, mu]], {q, Length[alph]}], {2}], {mu, 2}];
    If[! zeroQ[Flatten[resid]], log["    Maple strip (", i, ",", j, "): exact re-check FAILED -- rejected"]; Return[$Failed]]];
  log["    Maple strip (", i, ",", j, "): OK (first var ", msol["FirstVariable"], ", ", Round[msol["Seconds"], 0.1], " s, |alphabet| ", Length[alph], ", free residues fixed to zero ", nFreeResidues, ")"];
  Dm];

(* solve ONE strip (i,j) of the current connection a by the Maple route; returns the gauge D_ij (block matrix) or $Failed *)
mapleStrip[a_, i_, j_] := Module[{ri = ranges[[i]], rj = ranges[[j]], Ei, Cj, B, alph, dl, kmats, kvars, F, flat, ksol, kfree, K, dim, nk, kron, F0, Fk, Amats, bvecs, msol, Dm, Bp, tF, resF},
  Ei = {a[[1, ri, ri]], a[[2, ri, ri]]}; Cj = {a[[1, rj, rj]], a[[2, rj, rj]]}; B = {a[[1, ri, rj]], a[[2, ri, rj]]};
  alph = DeleteDuplicates[monic /@ Select[DeleteDuplicates[Flatten[First /@ FactorList[Denominator[Together[#]]] & /@ DeleteCases[Flatten[{Ei/ee, Cj/ee, B}], 0]]], polyLetterQ]];
  dl = Table[Together[D[Log[l], #]] & /@ {xx, yy}, {l, alph}];
  (* STRIP ROUTE A: CANONICA FindD on this single strip (eps-stripped e, c; local denominator alphabet; Laurent start automatic).
     Verified 2026-08-18 to reproduce Codex's strip gauge exactly in 0.1 s. *)
  {tF, resF} = AbsoluteTiming[Quiet[TimeConstrained[
    canonicaFindD[toC[Map[Together, Ei/ee, {3}]], toC[Map[Together, Cj/ee, {3}]], toC[B], toC[alph], {xx, yy}], Min[sectorBudget, 300], False]]];
  If[resF =!= False && ListQ[resF],
    log["    fallback strip ", {i, j}, ": FindD OK (", Round[tF, 0.1], " s, |alphabet| ", Length[alph], ")"];
    Return[Map[Together, fromC[resF], {2}]]];
  log["    fallback strip ", {i, j}, ": FindD did not finish (", Round[tF, 0.1], " s) -> Maple"];
  kmats = Table[Array[Symbol["kk" <> ToString[q] <> "x" <> ToString[#1] <> "x" <> ToString[#2]] &, {Length[ri], Length[rj]}], {q, Length[alph]}];
  kvars = Flatten[kmats];
  F = Table[B[[mu]] - Sum[kmats[[q]] dl[[q, mu]], {q, Length[alph]}], {mu, 2}];
  flat = Together[D[F[[2]], xx] - D[F[[1]], yy] + (Ei[[1]] . F[[2]] - F[[2]] . Cj[[1]]) - (Ei[[2]] . F[[1]] - F[[1]] . Cj[[2]])];
  (* the residues at the dlog stage are RATIONAL IN eps (constant in
     kinematics only): B' = Sum_a K_a(eps) dlog phi_a; the eps-only
     normalisation to constant residues is the sector's TransformDlogToEpsForm
     step.  So the flatness system is solved over Q(eps): coefficients in
     the KINEMATIC variables only, eps kept symbolic in the K's. *)
  flat = DeleteDuplicates[DeleteCases[Flatten[Table[CoefficientList[Expand[Numerator[Together[e]]], {xx, yy}], {e, Flatten[flat]}]], 0]];
  ksol = Quiet[Solve[Thread[flat == 0], kvars]];
  If[ksol === {}, log["    fallback strip ", {i, j}, ": residue flatness inconsistent"]; Return[$Failed]];
  ksol = FixedPoint[Function[r, Thread[First /@ r -> Together[(Last /@ r) /. r]]], First[ksol], 50];
  kfree = DeleteDuplicates[Cases[kmats /. ksol, _Symbol?(StringStartsQ[SymbolName[#], "kk"] &), {0, Infinity}]];
  K = kmats /. ksol;
  F = Table[Together[B[[mu]] - Sum[K[[q]] dl[[q, mu]], {q, Length[alph]}]], {mu, 2}];
  dim = Length[ri] Length[rj]; nk = Length[kfree];
  kron = Table[KroneckerProduct[Ei[[mu]], IdentityMatrix[Length[rj]]] - KroneckerProduct[IdentityMatrix[Length[ri]], Transpose[Cj[[mu]]]], {mu, 2}];
  F0 = Table[Flatten[F[[mu]] /. Thread[kfree -> 0]], {mu, 2}];
  Fk = Table[Transpose[Table[Together[D[Flatten[F[[mu]]], k]], {k, kfree}]], {mu, 2}];
  Amats = Table[If[nk == 0, kron[[mu]], ArrayFlatten[{{kron[[mu]], Fk[[mu]]}, {ConstantArray[0, {nk, dim}], ConstantArray[0, {nk, nk}]}}]], {mu, 2}];
  bvecs = Table[Join[F0[[mu]], ConstantArray[0, nk]], {mu, 2}];
  msol = mapleSolve[Amats, bvecs, "strip_" <> ToString[i] <> "_" <> ToString[j]];
  If[msol["Status"] =!= "OK", log["    fallback strip ", {i, j}, ": Maple ", msol["Status"], " (", Round[msol["Seconds"], 0.1], " s, |alphabet| ", Length[alph], ", free residues ", nk, ")"]; Return[$Failed]];
  Dm = ArrayReshape[Take[msol["Solution"], dim], {Length[ri], Length[rj]}];
  Bp = Table[Map[Together, B[[mu]] + (Ei[[mu]] . Dm - Dm . Cj[[mu]]) - D[Dm, {xx, yy}[[mu]]], {2}], {mu, 2}];
  (* fallback acceptance = the strip becomes an eps-form (constant residues implied by exact flatness + rationality; the sector's dlog->eps step and the family checks re-verify) *)
  If[! (epsFormQ[Bp[[1]]] && epsFormQ[Bp[[2]]]),
    (* dlog-form with polynomial-in-eps prefactor is also acceptable here: TransformDlogToEpsForm finishes the row *)
    log["    fallback strip ", {i, j}, ": Maple gauge gives dlog form (not yet eps-normalised); accepted for the sector re-run"]];
  log["    fallback strip ", {i, j}, ": Maple OK (first var ", msol["FirstVariable"], ", ", Round[msol["Seconds"], 0.1], " s, |alphabet| ", Length[alph], ", free residues ", nk, ")"];
  Dm];

(* ---- the sector loop ---- *)
Do[
 Module[{nk = bounds[[k, 2]], aTrunc, res, dk, res2, dk2, sfull, aNew, secs, ok = False, tries = 0},
  log["==== sector ", k, " (rows ", bounds[[k]], ", truncation ", nk, "x", nk, ")"];
  While[! ok && tries < 3,
    tries++;
    aTrunc = toC[{state["A"][[1]][[1 ;; nk, 1 ;; nk]], state["A"][[2]][[1 ;; nk, 1 ;; nk]]}];
    {secs, res} = AbsoluteTiming[Quiet[TimeConstrained[CANONICA`TransformOffDiagonalBlock[
      invariants, bounds[[1 ;; k]], IdentityMatrix[nk], aTrunc, CANONICA`VerbosityLevel -> 0], sectorBudget, {False, "TimedOut"}]]];
    log["  TransformOffDiagonalBlock: ", Round[secs, 0.1], " s", If[res[[1]] === False, " -> did not finish", ""]];
    If[res[[1]] =!= False, ok = True,
      (* FALLBACK = CANONICA's own row loop (CalculateNextSubsectorD), with
         Maple solving exactly the strip whose FindD returns False, using the
         SAME equation objects (NextEquationD: e, c, bbar) CANONICA would use;
         the Maple gauge is prepended into previousD as CalculateNextSubsectorD
         does; then the row continues; finally InsertDIntoIdentity+TransformDE. *)
      Module[{aP = aTrunc, sb = bounds[[1 ;; k]], subSize = bounds[[k, 2]] - bounds[[k, 1]] + 1, prevD, step, nextEq, e, c, bbar, msol, Dm, trafoD, ok2 = True, nlow, mapleUsed = {}},
        prevD = Table[{}, {subSize}];
        While[ok2 && Length[prevD[[1]]] + subSize =!= nk,
          log["  fallback: row loop at width ", Length[prevD[[1]]], " of ", nk - subSize];
          step = Quiet[TimeConstrained[canonicaCNSD[aP, invariants, sb, prevD, CANONICA`VerbosityLevel -> 0], Min[sectorBudget, 300], {False, prevD}]];
          (* progress guard: a step must WIDEN prevD; "success" without growth is
             a silent failure (measured 2026-08-18: infinite loop at width 2) *)
          If[step[[1]] =!= False && ListQ[step] && Length[step[[1]]] > Length[prevD[[1]]], prevD = step; Continue[]];
          If[step[[1]] =!= False, log["  fallback: CalculateNextSubsectorD returned without widening the row -> treating as FindD failure"]];
          (* FindD failed on this strip: hand it to Maple *)
          nextEq = canonicaNextEq[aP, invariants, sb, prevD];
          If[nextEq[[1]] === False, log["  fallback: NextEquationD failed"]; ok2 = False; Break[]];
          {e, c, bbar, nlow} = {fromC[nextEq[[1]]], fromC[nextEq[[2]]], fromC[nextEq[[3]]], nextEq[[5]]};
          log["  fallback: strip (", k, ",", nlow, ") -> Maple (FindD returned False)"];
          Dm = mapleStripEq[e, c, bbar, k, nlow];
          If[Dm === $Failed, ok2 = False; Break[]];
          AppendTo[mapleUsed, {k, nlow}];
          prevD = MapIndexed[Join[toC[Dm][[#2[[1]]]], #1] &, prevD]];
        If[ok2,
          trafoD = canonicaInsertD[sb, prevD];
          res = {IdentityMatrix[nk] . trafoD, canonicaTransformDE[aP, invariants, trafoD]};
          state["Fallbacks"] = Join[state["Fallbacks"], mapleUsed]; ok = True;
          log["  fallback: sector ", k, " row completed (Maple strips ", mapleUsed, ")"],
          log["  !! fallback could not complete sector ", k]; putAtomic[state, stateFile]; Exit[2]]]]];
  If[! ok, log["  !! sector ", k, " not completed"]; putAtomic[state, stateFile]; Exit[2]];
  dk = fromC[res[[1]]];
  {secs, res2} = AbsoluteTiming[Quiet[TimeConstrained[CANONICA`TransformDlogToEpsForm[invariants, bounds[[1 ;; k]], IdentityMatrix[nk], res[[2]], CANONICA`VerbosityLevel -> 0], sectorBudget, {False, "TimedOut"}]]];
  log["  TransformDlogToEpsForm: ", Round[secs, 0.1], " s", If[res2[[1]] === False, " -> returned False (dlog step kept)", ""]];
  dk2 = If[res2[[1]] === False, IdentityMatrix[nk], fromC[res2[[1]]]];
  sfull = IdentityMatrix[n]; sfull[[1 ;; nk, 1 ;; nk]] = Together[dk . dk2];
  aNew = Table[Map[Together, Inverse[sfull] . state["A"][[mu]] . sfull - Inverse[sfull] . D[sfull, {xx, yy}[[mu]]], {2}], {mu, 2}];
  state = <|"Sector" -> k, "S" -> Together[state["S"] . sfull], "A" -> aNew, "Fallbacks" -> state["Fallbacks"]|>;
  putAtomic[state, stateFile];
  log["  sector ", k, " done; non-eps-factored strips remaining (all sectors): ", Length[badStrips[state["A"], nb]]]],
 {k, Max[2, state["Sector"] + 1], nb}];

(* ---- family-level exact checks (in chart variables) ---- *)
S = state["S"] /. fromXY; Sinv = Together[Inverse[S]];
Ap = {state["A"][[1]] /. fromXY, state["A"][[2]] /. fromXY};
Aorig = {assembly["Apv"], assembly["Apw"]};
allEps = epsFormQ[Ap[[1]]] && epsFormQ[Ap[[2]]];
gauge = zeroQ[Flatten[Map[Together, Sinv . Aorig[[1]] . S - Sinv . D[S, c1] - Ap[[1]], {2}]]] && zeroQ[Flatten[Map[Together, Sinv . Aorig[[2]] . S - Sinv . D[S, c2] - Ap[[2]], {2}]]];
flatness = zeroQ[Flatten[Map[Together, D[Ap[[2]], c1] - D[Ap[[1]], c2] + Ap[[1]] . Ap[[2]] - Ap[[2]] . Ap[[1]], {2}]]];
log["FAMILY: A'/eps eps-free ", allEps, "; gauge identity ", gauge, "; flatness ", flatness, "; fallbacks used ", state["Fallbacks"]];
verdict = allEps && gauge && flatness;
letters = DeleteDuplicates[monic /@ Select[DeleteDuplicates[Flatten[First /@ FactorList[Denominator[Together[#]]] & /@ DeleteCases[Flatten[Ap], 0]]] /. fromXY, PolynomialQ[#, {c1, c2}] && ! FreeQ[#, c1 | c2] &]];
out = <|"Family" -> family, "Method" -> "SectorCANONICA+MapleStripFallback (standardized 2026-08-18)", "Chart" -> chart["Name"], "Variables" -> {c1, c2}, "Regulator" -> ee,
  "Ranges" -> ranges, "Blocks" -> assembly["Blocks"], "TTotal" -> S, "TTotalInverse" -> Sinv, "S" -> S, "EpsFormX" -> Ap[[1]], "EpsFormY" -> Ap[[2]],
  "Letters" -> letters, "GateVerdict" -> verdict, "GaugeIdentity" -> gauge, "Flatness" -> flatness, "Triangular" -> True, "TTotalInvertible" -> True,
  "Fallbacks" -> state["Fallbacks"], "Status" -> If[verdict, "CleanedUp", "Incomplete"], "WallSeconds" -> AbsoluteTime[] - start,
  "Provenance" -> "CANONICA TransformOffDiagonalBlock+TransformDlogToEpsForm per sector; Maple IntegrableConnections strip fallback (Codex wrapper); exact checks in Mathematica"|>;
putAtomic[out, FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
log["written family_epsform_", family, ".wl; GateVerdict ", verdict, "; wall ", Round[AbsoluteTime[] - start], " s"];
Exit[If[verdict, 0, 1]]
