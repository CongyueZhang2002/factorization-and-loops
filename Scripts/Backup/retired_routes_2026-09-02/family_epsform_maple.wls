#!/usr/bin/env wolframscript
(* Completing the family's eps-form -- MAPLE ROUTE (standardized from
   Codex's CF48 sector-13 strip-4 solution,
   Exchange/Codex/2026-08-18/07_cf48_maple_rational_gauge/, and its
   7-step request).

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
(* CANONICA for the per-strip Laurent solver FindD (Codex reply 2026-08-18:
   try CANONICA's FindD FIRST; it derives the starting Laurent order of D as
   nmin-1 automatically; Maple only when the CANONICA ansatz does not
   finish).  CANONICA works in CANONICA`eps; FindD lives in CANONICA`Private`
   in the installed 1.0.3 -- isolated here in ONE adapter. *)
Quiet[Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "CANONICA", "src", "CANONICA.m"}]], General::shdw];
canonicaFindD = If[DownValues[CANONICA`FindD] =!= {}, CANONICA`FindD, CANONICA`Private`FindD];
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
(* the global alphabet is recorded for reference; each strip uses its LOCAL denominator alphabet *)

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
  Module[{d = st[[1]], i = st[[2]], j = st[[3]], ri, rj, Ei, Cj, Es, Cs, B, K, localAlphabet, dlogsL, msol, Dm, Bp, resid, tstrip, route},
    ri = ranges[[i]]; rj = ranges[[j]];
    B = {Ac[[1, ri, rj]], Ac[[2, ri, rj]]};
    If[epsFormQ[B[[1]]] && epsFormQ[B[[2]]], Continue[]];   (* already eps-form: nothing to do *)
    tstrip = AbsoluteTime[];
    Ei = {Ac[[1, ri, ri]], Ac[[2, ri, ri]]}; Cj = {Ac[[1, rj, rj]], Ac[[2, rj, rj]]};
    (* eps-stripped diagonal coefficients (Codex: E = SeriesCoefficient[Aii,{eps,0,1}]) *)
    Es = Table[Map[Together, Ei[[mu]]/ee, {2}], {mu, 2}]; Cs = Table[Map[Together, Cj[[mu]]/ee, {2}], {mu, 2}];
    (* LOCAL alphabet: irreducible DENOMINATOR factors of the current strip equation {E, C, B} only (never numerators) *)
    localAlphabet = DeleteDuplicates[monic /@ Select[DeleteDuplicates[Flatten[
      First /@ FactorList[Denominator[Together[#]]] & /@ DeleteCases[Flatten[{Es, Cs, B}], 0]]], polyLetterQ]];
    localAlphabet = Union[localAlphabet, Select[{x1, x2}, MemberQ[localAlphabet, #] &]];
    dlogsL = Table[Together[D[Log[l], #]] & /@ {x1, x2}, {l, localAlphabet}];
    (* ---- ROUTE A: CANONICA FindD (Laurent ansatz, start order nmin-1 automatic) ---- *)
    toC[x_] := x /. ee -> CANONICA`eps; fromC[x_] := x /. CANONICA`eps -> ee;
    Dm = None; route = None; msol = <|"Seconds" -> 0|>;
    Module[{tC, resC},
      {tC, resC} = AbsoluteTiming[Quiet[TimeConstrained[
        canonicaFindD[toC[Es], toC[Cs], toC[B], toC[localAlphabet], {x1, x2}], stripBudget, False]]];
      If[resC =!= False && ListQ[resC],
        Dm = Map[Together, fromC[resC], {2}]; route = "CANONICA-FindD"; msol = <|"Seconds" -> tC, "FirstVariable" -> "-"|>;
        log["strip ", {i, j}, " (d=", d, "): CANONICA FindD ", Round[tC, 0.1], " s, |alphabet| ", Length[localAlphabet]],
        log["strip ", {i, j}, " (d=", d, "): CANONICA FindD did not finish (", Round[tC, 0.1], " s) -> Maple route"]]];
    (* ---- ROUTE B: Maple IntegrableConnections with the local alphabet ---- *)
    If[Dm === None,
      Module[{kmats, kvars, F, flat, ksol, kfree, dim, nk, kron, F0, Fk, Amats, bvecs},
        kmats = Table[Array[Symbol["kk" <> ToString[a] <> "x" <> ToString[#1] <> "x" <> ToString[#2]] &, {Length[ri], Length[rj]}], {a, Length[localAlphabet]}];
        kvars = Flatten[kmats];
        F = Table[B[[mu]] - ee Sum[kmats[[a]] dlogsL[[a, mu]], {a, Length[localAlphabet]}], {mu, 2}];
        flat = Together[D[F[[2]], x1] - D[F[[1]], x2] + (Ei[[1]] . F[[2]] - F[[2]] . Cj[[1]]) - (Ei[[2]] . F[[1]] - F[[1]] . Cj[[2]])];
        flat = DeleteDuplicates[DeleteCases[Flatten[Table[CoefficientList[Expand[Numerator[Together[e]]], {ee, x1, x2}], {e, Flatten[flat]}]], 0]];
        ksol = Quiet[Solve[Thread[flat == 0], kvars]];
        If[ksol === {}, log["strip ", {i, j}, ": residue flatness INCONSISTENT"]; AppendTo[failed, {i, j, "ResidueFlatnessInconsistent"}]; Continue[]];
        ksol = FixedPoint[Function[r, Thread[First /@ r -> Together[(Last /@ r) /. r]]], First[ksol], 50];
        kfree = DeleteDuplicates[Cases[kmats /. ksol, _Symbol?(StringStartsQ[SymbolName[#], "kk"] &), {0, Infinity}]];
        K = kmats /. ksol;
        F = Table[Together[B[[mu]] - ee Sum[K[[a]] dlogsL[[a, mu]], {a, Length[localAlphabet]}]], {mu, 2}];
        dim = Length[ri] Length[rj]; nk = Length[kfree];
        kron = Table[KroneckerProduct[Ei[[mu]], IdentityMatrix[Length[rj]]] - KroneckerProduct[IdentityMatrix[Length[ri]], Transpose[Cj[[mu]]]], {mu, 2}];
        F0 = Table[Flatten[F[[mu]] /. Thread[kfree -> 0]], {mu, 2}];
        Fk = Table[Transpose[Table[Together[D[Flatten[F[[mu]]], k]], {k, kfree}]], {mu, 2}];
        Amats = Table[If[nk == 0, kron[[mu]], ArrayFlatten[{{kron[[mu]], Fk[[mu]]}, {ConstantArray[0, {nk, dim}], ConstantArray[0, {nk, nk}]}}]], {mu, 2}];
        bvecs = Table[Join[F0[[mu]], ConstantArray[0, nk]], {mu, 2}];
        msol = mapleSolve[Amats, bvecs, "strip_" <> ToString[i] <> "_" <> ToString[j]];
        If[msol["Status"] =!= "OK", log["strip ", {i, j}, ": Maple ", msol["Status"], " (", Round[msol["Seconds"], 0.1], " s)"]; AppendTo[failed, {i, j, msol["Status"]}]; Continue[]];
        Module[{sol = msol["Solution"], nD = Length[ri] Length[rj]},
          Dm = ArrayReshape[Take[sol, nD], {Length[ri], Length[rj]}];
          If[nk > 0, K = K /. Thread[kfree -> Drop[sol, nD]]]];
        route = "Maple-IntegrableConnections"]];
    (* step 5: exact re-check on the ORIGINAL block equation, both variables *)
    (* transformed block; acceptance = eps-form: B'/eps eps-free AND exact dlog reconstruction over the local alphabet with constant residues *)
    Bp = Table[Map[Together, B[[mu]] + (Ei[[mu]] . Dm - Dm . Cj[[mu]]) - D[Dm, {x1, x2}[[mu]]], {2}], {mu, 2}];
    If[! (epsFormQ[Bp[[1]]] && epsFormQ[Bp[[2]]]),
      log["strip ", {i, j}, ": transformed block NOT eps-factored -- rejected (route ", route, ")"]; AppendTo[failed, {i, j, "NotEpsFactored"}]; Continue[]];
    Module[{kk, kv, eqs, ksol2},
      kk = Table[Array[Symbol["rr" <> ToString[a] <> "x" <> ToString[#1] <> "x" <> ToString[#2]] &, {Length[ri], Length[rj]}], {a, Length[localAlphabet]}];
      kv = Flatten[kk];
      eqs = DeleteDuplicates[DeleteCases[Flatten[Table[CoefficientList[Expand[Numerator[Together[Bp[[mu]] - ee Sum[kk[[a]] dlogsL[[a, mu]], {a, Length[localAlphabet]}]]]], {x1, x2, ee}], {mu, 2}]], 0]];
      ksol2 = Quiet[Solve[Thread[eqs == 0], kv]];
      If[ksol2 === {}, log["strip ", {i, j}, ": transformed block does not reconstruct as constant-residue dlog over the local alphabet -- rejected"]; AppendTo[failed, {i, j, "DlogReconstructionFailed"}]; Continue[]];
      K = kk /. First[ksol2] /. Thread[kv -> 0]];
    resid = Table[Map[Together, Bp[[mu]] - ee Sum[K[[a]] dlogsL[[a, mu]], {a, Length[localAlphabet]}], {2}], {mu, 2}];
    If[! zeroQ[Flatten[resid]], log["strip ", {i, j}, ": dlog residual nonzero -- rejected"]; AppendTo[failed, {i, j, "RecheckFailed"}]; Continue[]];
    (* step 6: compose T = 1 + D_ij (embedded), update the whole connection: A -> T^-1 A T - T^-1 dT *)
    Module[{T = IdentityMatrix[n], Ti},
      T[[ri, rj]] = Dm; Ti = IdentityMatrix[n]; Ti[[ri, rj]] = -Dm;   (* strictly lower nilpotent: inverse is 1 - D *)
      Ac = Table[Map[Together, Ti . Ac[[mu]] . T - Ti . D[T, {x1, x2}[[mu]]], {2}], {mu, 2}];
      Ttot = Ttot . T; Ttinv = Ti . Ttinv];
    log["strip ", {i, j}, ": DONE via ", route, " (", Round[msol["Seconds"], 0.1], " s solver, ", Round[AbsoluteTime[] - tstrip, 0.1], " s total)"];
    AppendTo[records, <|"Strip" -> {i, j}, "Distance" -> d, "Route" -> route, "SolverSeconds" -> msol["Seconds"],
      "Seconds" -> AbsoluteTime[] - tstrip, "Gauge" -> Dm, "Alphabet" -> localAlphabet, "Residues" -> K, "StripResidual" -> resid|>]],
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
