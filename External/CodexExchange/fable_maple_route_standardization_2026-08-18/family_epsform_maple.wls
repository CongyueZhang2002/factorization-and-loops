#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- MAPLE ROUTE (standardized from
   Codex's CF48 sector-13 strip-4 solution, External/CodexExchange/
   cf48_maple_rational_gauge_2026-08-18/, and its 7-step request).

   Setting: after assembly (TransportFamilyInChart), the family connection
   (A_p, A_s) is block lower triangular with every DIAGONAL block a certified
   eps-form; the off-diagonal blocks B_ij are general.  We build T = 1 + D
   strip by strip in SECTOR ORDER (block distance increasing; within a
   distance, i ascending): for strip (i,j) with diagonal blocks E_mu (i)
   and C_mu (j), find constant residues K_a and a rational gauge D_ij with

       B_mu + eps (E_mu D - D C_mu) - d_mu D  =  eps Sum_a K_a d_mu log phi_a

   in BOTH variables.  Per strip:
     1. one regulator symbol (Global`eps) throughout;
     2. residues K_a from the exact FLATNESS condition of the strip
        equation (linear in the K_a entries); triangular relations
        resolved recursively; free entries set to 0 (recorded);
     3. vectorized inhomogeneous connection d_mu V = A_mu V + b_mu for
        V = vec(D) with the K_a substituted;
     4. Maple IntegrableConnections via ExactRationalConnectionSolution
        (tries every variable ordering; unique rational particular
        solution; exact residual check inside Maple);
     5. accept only after EXACT zero residuals in every variable, re-checked
        in Mathematica on the ORIGINAL block equation;
     6. compose into TTotal; the strips at larger distance see the change;
        the finished family passes the exact two-variable eps-form check
        (family_epsform record schema, route-2 consumable);
     7. record variable ordering, wall time, gauge, residues, strip- and
        family-level residuals.
   Usage: family_epsform_maple.wls <family> <outdir> [budgetSecondsPerStrip=600] *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]];
args = Rest[$ScriptCommandLine];
family = args[[1]]; outdir = args[[2]];
stripBudget = If[Length[args] >= 3, ToExpression[args[[3]]], 600];
start = AbsoluteTime[];
log[a___] := Print["[maple-epsform ", family, " +", ToString[Round[AbsoluteTime[] - start]], "s] ", StringJoin[ToString[#, InputForm] & /@ {a}]];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}]; expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]], {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}]; expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
mapleLib = FileNameJoin[{root, "Addon", "Other_Addon", "Maple", "IntegrableConnections"}];
mapleWrapper = FileNameJoin[{root, "Addon", "Other_Addon", "Maple", "ExactRationalConnectionSolution.mpl"}];
scratch = FileNameJoin[{outdir, "maple_" <> family}]; If[! DirectoryQ[scratch], CreateDirectory[scratch]];

(* ---- assemble ------------------------------------------------------ *)
de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
chart = FeynFacet`TransportFamilyChart[family];
If[! AssociationQ[chart], log["!! this route needs a chart frame (two variables); (v,w) families use route 1"]; Exit[2]];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"], "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
rec = FeynFacet`TransportFamilyInChart[system, chart, "SourceVariables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> blocks,
  "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}], "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
If[! (AssociationQ[rec] && KeyExistsQ[rec, "Assembly"]), log["!! assembly failed"]; Exit[1]];
assembly = rec["Assembly"]; Ax = assembly["Apv"]; Ay = assembly["Apw"]; ranges = assembly["Ranges"]; nb = Length[ranges]; n = Length[Ax];
{x1, x2} = chart["Variables"];
log["assembled ", n, "x", n, ", ", nb, " blocks, chart ", chart["Name"], " vars ", {x1, x2}];
zeroQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] &];
epsFormQ[m_] := AllTrue[Flatten[m], TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
(* ALPHABET: irreducible polynomial factors of all denominators of the
   connection, PLUS the polynomial numerator factors of the certified
   diagonal blocks (letters that survive only in numerators after partial
   fractions), each made monic in its leading variable.  Non-polynomial or
   constant candidates are discarded. *)
monic[f_] := Module[{v = First[Variables[f]], lc}, lc = Coefficient[f, v, Exponent[f, v]];
  If[NumericQ[lc], Expand[f/lc], f]];
polyLetterQ[f_] := PolynomialQ[f, {x1, x2}] && ! FreeQ[f, x1 | x2] && NumericQ[Coefficient[f, First[Variables[f]], Exponent[f, First[Variables[f]]]]];
cands = Flatten[Table[Join[First /@ FactorList[Numerator[Together[e]]], First /@ FactorList[Denominator[Together[e]]]],
  {e, DeleteCases[Flatten[{Ax, Ay}], 0]}]];
alphabet = DeleteDuplicates[monic /@ Select[DeleteDuplicates[cands], polyLetterQ]];
alphabet = Select[alphabet, Exponent[#, x1] + Exponent[#, x2] >= 1 && ! (Exponent[#, x1] + Exponent[#, x2] > 4) &];   (* degree cap: dlog letters here are low degree *)
If[chart["Name"] === "Q4b", alphabet = DeleteDuplicates[Join[
  monic /@ {x1 - 1, x1, x1 + 1, x1 - x2, x2 - 1, x2, x2 + 1, x1 + x2, x1 - x2^2, x1 + x1 x2 - x2^2, x1 + x2^2, -x1 - x1 x2 + x1^2 x2 + x2^2},
  alphabet]]];
log["alphabet: ", Length[alphabet], " letters: ", alphabet];
dlogs = Table[Together[D[Log[l], #]] & /@ {x1, x2}, {l, alphabet}];   (* dlogs[[a, mu]] *)

(* ---- Maple call ---------------------------------------------------- *)
toMaple[e_] := StringReplace[ToString[e, InputForm], {"Global`" -> "", "^" -> "^", " " -> ""}];
mapleSolve[Amats_, bvecs_, tag_] := Module[{mfile, ofile, txt, res, out, dim = Length[bvecs[[1]]], t0},
  mfile = FileNameJoin[{scratch, tag <> ".mpl"}]; ofile = FileNameJoin[{scratch, tag <> ".out"}];
  txt = StringJoin[
    "restart:\nlibname := \"", mapleLib, "\", libname:\nwith(IntegrableConnections):\nwith(linalg):\n",
    "read \"", mapleWrapper, "\":\n",
    "A1 := matrix(", ToString[dim], ",", ToString[dim], ",[", StringRiffle[toMaple /@ Flatten[Amats[[1]]], ","], "]):\n",
    "A2 := matrix(", ToString[dim], ",", ToString[dim], ",[", StringRiffle[toMaple /@ Flatten[Amats[[2]]], ","], "]):\n",
    "b1 := vector(", ToString[dim], ",[", StringRiffle[toMaple /@ bvecs[[1]], ","], "]):\n",
    "b2 := vector(", ToString[dim], ",[", StringRiffle[toMaple /@ bvecs[[2]], ","], "]):\n",
    "res := ExactRationalConnectionSolution([A1,A2],[", toMaple[x1], ",", toMaple[x2], "],[b1,b2],[eps]):\n",
    "fd := fopen(\"", ofile, "\", WRITE):\n",
    "if res = FAIL then fprintf(fd, \"FAIL\\n\") else fprintf(fd, \"OK\\n%a\\n%a\\n\", res[\"FirstVariable\"], res[\"SolutionList\"]) end if:\n",
    "fclose(fd):\nquit:\n"];
  Export[mfile, txt, "Text"];
  t0 = AbsoluteTime[];
  res = TimeConstrained[RunProcess[{"maple", "-q", mfile}], stripBudget, <|"StandardError" -> "TimedOut"|>];
  If[! FileExistsQ[ofile], Return[<|"Status" -> "MapleNoOutput", "Seconds" -> AbsoluteTime[] - t0, "Stderr" -> Lookup[res, "StandardError", ""]|>]];
  out = StringSplit[Import[ofile, "Text"], "\n"];
  If[out === {} || First[out] === "FAIL", Return[<|"Status" -> "MapleFAIL", "Seconds" -> AbsoluteTime[] - t0|>]];
  <|"Status" -> "OK", "FirstVariable" -> out[[2]], "Seconds" -> AbsoluteTime[] - t0,
    "Solution" -> ToExpression[StringReplace[out[[3]], {"[" -> "{", "]" -> "}"}]] /. Thread[ToExpression /@ {"p", "s", "x", "y", "u"} -> ToExpression /@ {"Global`p", "Global`s", "Global`x", "Global`y", "Global`u"}]|>];

(* ---- per-strip solve ------------------------------------------------ *)
Ttot = IdentityMatrix[n]; Ttinv = IdentityMatrix[n];
Ac = {Ax, Ay};   (* current connection *)
records = {}; failed = {};
strips = Sort[Flatten[Table[If[i > j && ! zeroQ[Ac[[1, ranges[[i]], ranges[[j]]]]], {i - j, i, j}, Nothing], {i, nb}, {j, nb}], 1]];
log[Length[strips], " nonzero strips; not eps-form: ", Count[strips, {_, i_, j_} /; ! (epsFormQ[Ac[[1, ranges[[i]], ranges[[j]]]]] && epsFormQ[Ac[[2, ranges[[i]], ranges[[j]]]]])]];
Do[
  Module[{d = st[[1]], i = st[[2]], j = st[[3]], ri, rj, E, C, B, K, kvars, kmats, F, flat, ksol, kfree, Amats, bvecs, dim, msol, Dm, resid, tstrip},
    ri = ranges[[i]]; rj = ranges[[j]];
    B = {Ac[[1, ri, rj]], Ac[[2, ri, rj]]};
    If[epsFormQ[B[[1]]] && epsFormQ[B[[2]]], Continue[]];   (* already eps-form: nothing to do *)
    tstrip = AbsoluteTime[];
    E = {Ac[[1, ri, ri]], Ac[[2, ri, ri]]}; C = {Ac[[1, rj, rj]], Ac[[2, rj, rj]]};
    (* step 2: residues from flatness.  Unknown constant matrices K_a; F_mu = B_mu - eps Sum K_a dlog_a,mu.
       Flatness of d D = eps(E D - D C) + F  <=>  d_1 F_2 - d_2 F_1 + eps(E_1 F_2 - F_2 C_1) - eps(E_2 F_1 - F_1 C_2)
       + [terms in D that cancel by flatness of E, C] = 0 -- linear in K. *)
    kmats = Table[Array[Symbol["kk" <> ToString[a] <> "x" <> ToString[#1] <> "x" <> ToString[#2]] &, {Length[ri], Length[rj]}], {a, Length[alphabet]}];
    kvars = Flatten[kmats];
    F = Table[B[[mu]] - ee Sum[kmats[[a]] dlogs[[a, mu]], {a, Length[alphabet]}], {mu, 2}];
    flat = Together[D[F[[2]], x1] - D[F[[1]], x2] + (E[[1]] . F[[2]] - F[[2]] . C[[1]]) - (E[[2]] . F[[1]] - F[[1]] . C[[2]])];
    flat = DeleteDuplicates[DeleteCases[Flatten[Table[CoefficientList[Expand[Numerator[Together[e]]], {ee, x1, x2}], {e, Flatten[flat]}]], 0]];
    ksol = Quiet[Solve[Thread[flat == 0], kvars]];
    If[ksol === {}, log["strip ", {i, j}, " (d=", d, "): flatness system for residues INCONSISTENT -- ", Length[flat], " eqs"]; AppendTo[failed, {i, j, "ResidueFlatnessInconsistent"}]; Continue[]];
    ksol = First[ksol];
    (* Codex: "the residue rules are triangular and must be substituted
       recursively" -- a single ReplaceAll leaves k's on right-hand sides,
       which then masquerade as free unknowns (and, as degenerate constant
       rows, trigger IntegrableConnections' good_form division by zero). *)
    ksol = FixedPoint[Function[r, Thread[First /@ r -> Together[(Last /@ r) /. r]]], ksol, 50];
    kfree = Complement[DeleteDuplicates[Cases[kmats /. ksol, _Symbol?(StringStartsQ[SymbolName[#], "kk"] &), {0, Infinity}]], {}];
    K = kmats /. ksol;   (* free residue entries stay SYMBOLIC -- they are not
       arbitrary (D exists only for the right choice); carried into Maple's
       unknown vector as constants with d_mu k = 0 *)
    log["strip ", {i, j}, " (d=", d, "): residues from ", Length[flat], " flatness eqs; ", Length[ksol], " fixed, ", Length[kfree], " free (solved with D)"];
    F = Table[Together[B[[mu]] - ee Sum[K[[a]] dlogs[[a, mu]], {a, Length[alphabet]}]], {mu, 2}];
    (* vectorize with V = {vec(D), kfree}: d_mu vec(D) = Kron_mu vec(D) + Fk_mu.kfree + F0_mu; d_mu kfree = 0 *)
    dim = Length[ri] Length[rj]; nk = Length[kfree];
    Module[{kron, F0, Fk},
      kron = Table[KroneckerProduct[E[[mu]], IdentityMatrix[Length[rj]]] - KroneckerProduct[IdentityMatrix[Length[ri]], Transpose[C[[mu]]]], {mu, 2}];
      F0 = Table[Flatten[F[[mu]] /. Thread[kfree -> 0]], {mu, 2}];
      Fk = Table[Transpose[Table[Together[D[Flatten[F[[mu]]], k]], {k, kfree}]], {mu, 2}];
      Amats = Table[If[nk == 0, kron[[mu]],
        ArrayFlatten[{{kron[[mu]], Fk[[mu]]}, {ConstantArray[0, {nk, dim}], ConstantArray[0, {nk, nk}]}}]], {mu, 2}];
      bvecs = Table[Join[F0[[mu]], ConstantArray[0, nk]], {mu, 2}]];
    dim = dim + nk;
    (* step 4: Maple *)
    msol = mapleSolve[Amats, bvecs, "strip_" <> ToString[i] <> "_" <> ToString[j]];
    If[msol["Status"] =!= "OK", log["strip ", {i, j}, ": Maple ", msol["Status"], " (", Round[msol["Seconds"], 0.1], " s)"]; AppendTo[failed, {i, j, msol["Status"]}]; Continue[]];
    Module[{sol = msol["Solution"], nD = Length[ri] Length[rj]},
      Dm = ArrayReshape[Take[sol, nD], {Length[ri], Length[rj]}];
      If[Length[kfree] > 0, K = K /. Thread[kfree -> Drop[sol, nD]]]];
    (* step 5: exact re-check on the ORIGINAL block equation, both variables *)
    resid = Table[Map[Together, B[[mu]] + (E[[mu]] . Dm - Dm . C[[mu]]) - D[Dm, {x1, x2}[[mu]]] - ee Sum[K[[a]] dlogs[[a, mu]], {a, Length[alphabet]}], {2}], {mu, 2}];
    If[! zeroQ[Flatten[resid]], log["strip ", {i, j}, ": Maple solution FAILS the exact block re-check -- rejected"]; AppendTo[failed, {i, j, "RecheckFailed"}]; Continue[]];
    (* step 6: compose T = 1 + D_ij (embedded), update the whole connection: A -> T^-1 A T - T^-1 dT *)
    Module[{T = IdentityMatrix[n], Ti},
      T[[ri, rj]] = Dm; Ti = IdentityMatrix[n]; Ti[[ri, rj]] = -Dm;   (* strictly lower nilpotent: inverse is 1 - D *)
      Ac = Table[Map[Together, Ti . Ac[[mu]] . T - Ti . D[T, {x1, x2}[[mu]]], {2}], {mu, 2}];
      Ttot = Ttot . T; Ttinv = Ti . Ttinv];
    log["strip ", {i, j}, ": DONE via Maple (first var ", msol["FirstVariable"], ", ", Round[msol["Seconds"], 0.1], " s Maple, ", Round[AbsoluteTime[] - tstrip, 0.1], " s total)"];
    AppendTo[records, <|"Strip" -> {i, j}, "Distance" -> d, "FirstVariable" -> msol["FirstVariable"], "MapleSeconds" -> msol["Seconds"],
      "Seconds" -> AbsoluteTime[] - tstrip, "Gauge" -> Dm, "Residues" -> K, "FreeResiduesFixedToZero" -> kfree, "StripResidual" -> resid|>]],
  {st, strips}];
log["strips done: ", Length[records], ", failed: ", Length[failed], " ", failed];
(* ---- family-level exact check ------------------------------------- *)
allEps = epsFormQ[Ac[[1]]] && epsFormQ[Ac[[2]]];
log["whole connection eps-factored (both variables): ", allEps];
gauge = zeroQ[Flatten[Map[Together, Ttinv . Ax . Ttot - Ttinv . D[Ttot, x1] - Ac[[1]], {2}]]] && zeroQ[Flatten[Map[Together, Ttinv . Ay . Ttot - Ttinv . D[Ttot, x2] - Ac[[2]], {2}]]];
log["gauge identity T^-1 A T - T^-1 dT == A' (both variables): ", gauge];
flatness = zeroQ[Flatten[Map[Together, D[Ac[[2]], x1] - D[Ac[[1]], x2] + Ac[[1]] . Ac[[2]] - Ac[[2]] . Ac[[1]], {2}]]];
log["flatness of A': ", flatness];
verdict = allEps && gauge && flatness && failed === {};
out = <|"Family" -> family, "Method" -> "MapleIntegrableConnectionsStripGauge (Codex route, standardized 2026-08-18)",
  "Chart" -> chart["Name"], "Variables" -> {x1, x2}, "Regulator" -> ee, "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "TTotal" -> Ttot, "TTotalInverse" -> Ttinv, "EpsFormX" -> Ac[[1]], "EpsFormY" -> Ac[[2]], "Letters" -> alphabet,
  "Strips" -> records, "FailedStrips" -> failed, "GateVerdict" -> verdict, "GaugeIdentity" -> gauge, "Flatness" -> flatness,
  "WholeEpsFactored" -> allEps, "Status" -> If[verdict, "CleanedUp", "Incomplete"], "WallSeconds" -> AbsoluteTime[] - start,
  "Provenance" -> "strip gauges by Maple IntegrableConnections (Codex ExactRationalConnectionSolution wrapper); residues from flatness; exact checks in Mathematica"|>;
putAtomic[out, FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
log["written; GateVerdict ", verdict, "; wall ", Round[AbsoluteTime[] - start], " s"];
Exit[If[verdict, 0, 1]]
