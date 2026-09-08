#!/usr/bin/env wolframscript
(* ==================================================================== *)
(*  family_epsform.wls -- ONE production driver for FAMILY eps-forms.    *)
(* ==================================================================== *)
(*
   For a family that ASSEMBLES today (TransportFamily in (v,w) or
   TransportFamilyInChart in the class-97 chart, "MaxWeight" -> 0, exactly
   as Scripts/Diagnostics/transport_depth_ledger.wls does it), this driver

     1. assembles and keeps the assembly record (Apv/Apw = conjugated,
        Av/Aw = ORIGINAL permuted, Ranges, per-block T/TInverse/Ev/Ew);

     2. MEASURES coupling purity per (block pair, eps-order): every
        coupling entry is decomposed on the axis-aligned path the
        transport uses (the S1 measurement of Scripts/Diagnostics/blockwise_structure.wls
        -- pure dlog with tau-free constant residues, or not: pole orders,
        polynomial part, eps-dependent denominator factors) AND, because
        the family eps-form is a TWO-VARIABLE statement, in BOTH chart
        variables separately;

     3. runs THE GATE with S = identity.  If it passes, the family was
        already a family eps-form: T_total = diag(T_i), S = 1, status
        "AlreadyEpsForm" -- with the same five-part certificate as below.
        The gate is run, never assumed (purity of the couplings is
        NECESSARY but not SUFFICIENT: a pure-dlog coupling at eps^0 is
        still not an eps-form);

     4. otherwise runs the cleanup, cheapest mechanism first, each one
        measured and recorded:

          M1  EpsLocusStrip        closed-form strip of the eps-DEPENDENT
                                   apparent loci (the CF230 mechanism:
                                   N = M/q^(k-1), M read off the leading
                                   pole, d_var q invertible mod q)
          M2  FuchsPoleReduction   closed-form Moser/Fuchs reduction at
                                   the ordinary eps-FREE letters (Sylvester
                                   operator (k-1) + eps(R_i - R_j),
                                   right-to-left column order)
          M3  DlogToEpsForm        CANONICA TransformDlogToEpsForm, an
                                   eps-ONLY transformation, once the whole
                                   connection is dlog with (x,y)-free
                                   residues
          M4  CanonicaOffDiagonal  CANONICA's off-diagonal recursion driven
                                   SUBSECTOR BY SUBSECTOR with a checkpoint
                                   after every subsector and resumption
                                   through the documented userProvidedD
                                   argument; ansatz degrees escalated
                                   (0,0) -> (1,0) -> (1,1) -> (2,1)

     5. runs THE GATE and writes <outdir>/family_epsform_<family>.wl.

   THE GATE (the only acceptance; a CANONICA/Libra return SHAPE is never
   a criterion) -- five exact conditions on the ORIGINAL (permuted)
   connections through T_total = diag(T_i) . S:

     (i)   Ahat'_mu = T^-1 A0_mu T - T^-1 d_mu T has Ahat'_mu / eps
           EPS-FREE entrywise;
     (ii)  every entry is a sum of CONSTANT matrices times dlog of
           EPS-FREE letters -- residues free of x, y and eps, equal
           between the two directions, and the dlog reconstruction is
           exact entrywise in BOTH variables (this also excludes any
           polynomial part);
     (iii) the eps-form is flat;
     (iv)  S is block lower triangular with (x,y)-free diagonal blocks;
     (v)   T_total . T_total^-1 == 1 exactly, both ways.

   Measured negatives that are NOT re-learned here (recorded in
   TransportProductionPlan.md): naive one-letter-at-a-time Moser reduction
   does not converge (M2 therefore uses the forced right-to-left column
   order and hands what is left to CANONICA's simultaneous ansatz);
   DDeltaDenominatorDegree lives in CANONICA`Private; a per-entry pole
   function applied to a SUBMATRIX returns a silent zero (every pole
   function here is mapped over ENTRIES); CANONICA's own dlog fast path is
   misled by eps-ONLY denominator factors, so the dlog test is made here
   directly.

   Usage:
     family_epsform.wls <family> [frame] [outdir] [canonicaBudget] [kExtra] [scratch]

       frame           auto (default) | vw | chart
       outdir          default Results/UU_08_10_canonical/FamilyEpsForms
       canonicaBudget  seconds for the whole M4 phase (default 5400)
       kExtra          eps-orders above the lowest classified per coupling (3)
       scratch         where the re-derivable assembly cache lives

   Every phase prints ONE greppable line
       [fe <family>] PHASE=<NAME> sec=<phase seconds> elapsed=<total> ...
   and cleanup checkpoints are written to <outdir>/state_<family>_*.wl,
   so a run that dies loses at most one subsector.
*)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";

argv = Rest[$ScriptCommandLine];
If[Length[argv] < 1,
  Print["usage: family_epsform.wls <family> [frame] [outdir] [canonicaBudget] [kExtra] [scratch]"];
  Exit[64]];
family = argv[[1]];
frameArg = If[Length[argv] >= 2 && argv[[2]] =!= "", ToLowerCase[argv[[2]]], "auto"];
outdir = If[Length[argv] >= 3 && argv[[3]] =!= "", argv[[3]],
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
    "FamilyEpsForms"}]];
(* 2700 s covers CF230's measured off-diagonal recursion (1601 s) with
   margin.  Beyond that the ansatz escalation is the cost, not the answer:
   measured on CF201 sector 5 at degrees (1,1), ONE subsector column took
   157.7 s and produced 17922 leaves before returning False. *)
canonicaBudget = If[Length[argv] >= 4 && argv[[4]] =!= "", ToExpression[argv[[4]]], 2700];
kExtra = If[Length[argv] >= 5 && argv[[5]] =!= "", ToExpression[argv[[5]]], 3];
scratch = If[Length[argv] >= 6 && argv[[6]] =!= "", argv[[6]],
  "/tmp/claude-1000/-home-maxzhang/26f8c32a-e9f2-4b47-9b8a-06d049f6a87a/scratchpad/agentB"];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
If[! DirectoryQ[scratch], CreateDirectory[scratch, CreateIntermediateDirectories -> True]];

(* the pool's subkernels keep state between missions: an own value on any
   of these poisons the path parameter, the chart substitution, or a
   Together; and a DownValue left by an earlier mission with a different
   argument pattern would be ADDED to, not replaced by, a SetDelayed here.
   This block must come BEFORE this script's own definitions. *)
Quiet[Clear["Global`tau", "Global`x", "Global`y", "Global`v", "Global`w",
  "Global`eps", "Global`t", "Global`u"]];
Quiet[Clear[log, phase, now, normalizeSymbols, normalizeRegulator, readArtifact,
  putAtomic, zeroQ, zeroMatQ, familyBlocks, hardRecord, classFormFile,
  hardArtifact, hasAssembly, assembleVW, assembleChart, epsOrderOf, laurentAt, classOfRows,
  classifyEntry, purityOf, blockLowerInverse, residueAt, runGate, stateFile,
  epsXYDen, poleOrderAt, maxPoleOf, blockPole, lettersOf, applyStrip,
  epsLocusStrip, fuchsReduce, dlogTest, obstruction, loadCanonica, toCanonica, fromCanonica,
  dlogToEpsForm, canonicaOffDiagonal]];

start = AbsoluteTime[];
tag = "[fe " <> family <> "]";
now[] := Round[AbsoluteTime[] - start, 0.1];
log[a___] := Print[tag, " +", ToString[now[]], "s ", StringJoin[ToString /@ {a}]];
phaseTimes = <||>;
phase[name_String, secs_, a___] := (
  phaseTimes[name] = Round[N[secs], 0.01];
  Print[tag, " PHASE=", name, " sec=", ToString[Round[N[secs], 0.1]],
    " elapsed=", ToString[now[]], "s ", StringJoin[ToString /@ {a}]]);

t0 = AbsoluteTime[];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
ee = Symbol["Global`eps"]; tauS = Symbol["Global`tau"];
phase["LOAD", AbsoluteTime[] - t0, "wolfram=", $Version];

(* ------------------------------------------------------------------ *)
(*  artifact hygiene                                                    *)
(* ------------------------------------------------------------------ *)
(* The inline  expr /. (s_Symbol /; ... :> Symbol["Global`" <> SymbolName[s]])
   spelling was MEASURED (Tests/Infrastructure/t_wolfram_traps.wls item T2) to insert its
   right-hand side UNEVALUATED once a package is on $ContextPath -- and
   this driver LOADS CANONICA.  The rule list is built explicitly.  Do not
   "simplify" this back. *)
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x",
  "y", "u", "t", "tau", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[$normalizeNames, SymbolName[s]] && Context[s] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
  expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]],
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
putAtomic[expr_, file_String] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]; file];

zeroQ[e_] := TrueQ[Together[e] === 0];
zeroMatQ[m_] := AllTrue[Flatten[m], zeroQ];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];
ftHard = FileNameJoin[{ftData, "HardClasses", "EpsFormRoute"}];

(* ------------------------------------------------------------------ *)
(*  (1) assembly -- the loading/normalization of transport_depth_ledger *)
(* ------------------------------------------------------------------ *)

assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;
(* 2026-08-17 03:25 (coordinator): the "chart" frame is the family's chart
   from the catalog (TransportCharts.wl: Kallen1/2/3, Q4a/b, Bilinear115,
   joint Kallen12/13/23) when the catalog assigns one; the class-97 chart
   is kept only as the fallback for a root-free family that does not
   assemble in (v,w).  The sweep's route 2 uses the same catalog chart to
   pull back the original system, so records stay consumable. *)
Module[{catalogChart = Quiet[FeynFacet`TransportFamilyChart[family]]},
  If[AssociationQ[catalogChart], chart97 = catalogChart]];
classFormFile[cid_] := FileNameJoin[{ftClassForms, "class" <> ToString[cid] <> ".wl"}];
hardArtifact[cid_] := FileNameJoin[{ftHard, "c" <> ToString[cid] <> "_epsform_two_variable.wl"}];
hardRecord[cid_, repFamily_, repRows_] := Module[{raw},
  If[FileExistsQ[classFormFile[cid]], Return[readArtifact[classFormFile[cid]]]];
  raw = readArtifact[hardArtifact[cid]];
  <|"ClassID" -> cid, "RepFamily" -> repFamily, "RepRows" -> repRows,
    "Dim" -> Length[raw["T"]], "Transformation" -> raw["T"],
    "EpsForm" -> {raw["Ax"], raw["Ay"]}, "Variables" -> {xx, yy},
    "Chart" -> <|"Kind" -> "TwoVariable",
      "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
      "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww,
      "Variables" -> {xx, yy}|>,
    "AnsatzDegree" -> None, "Validated" -> True|>];
familyBlocks[f_String] := Table[{a["Rows"],
    If[FileExistsQ[classFormFile[a["ClassID"]]], a["ClassID"],
      hardRecord[a["ClassID"], f, a["Rows"]]]},
  {a, Select[assignments, #["Family"] === f &]}];

hasAssembly[r_] := AssociationQ[r] && KeyExistsQ[r, "Assembly"] &&
  AssociationQ[r["Assembly"]] && KeyExistsQ[r["Assembly"], "Ranges"];

de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
famBlocks = familyBlocks[family];

assembleVW[] := FeynFacet`TransportFamily[
  <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
    "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
  "Variables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> famBlocks, "FormDirectory" -> ftClassForms,
  "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
assembleChart[] := FeynFacet`TransportFamilyInChart[
  <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
    "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> famBlocks, "FormDirectory" -> ftClassForms,
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];

asmCache = FileNameJoin[{scratch, "assembly_" <> family <> ".wl"}];
t0 = AbsoluteTime[];
cached = If[FileExistsQ[asmCache], Quiet[Check[normalizeSymbols[Get[asmCache]], $Failed]], $Failed];
If[AssociationQ[cached] && cached["FrameArg"] === frameArg &&
   MemberQ[{"Chart", "SourceVW"}, Lookup[cached, "Frame", None]] &&
   AssociationQ[Lookup[cached, "Assembly", None]],
  frame = cached["Frame"]; asm = cached["Assembly"]; asmStatus = "cached",
  (* else: assemble *)
  frame = None; asm = None; asmStatus = "?";
  If[frameArg =!= "chart",
    rec = assembleVW[];
    asmStatus = If[AssociationQ[rec], Lookup[rec, "Status", "?"], ToString[rec]];
    If[hasAssembly[rec], frame = "SourceVW"; asm = rec["Assembly"],
      log["  (v,w) assembly ", asmStatus, " -- ",
        ToString[Short[Lookup[rec, "Reason", "-"], 2]]]]];
  If[frame === None && frameArg =!= "vw",
    rec = assembleChart[];
    asmStatus = If[AssociationQ[rec], Lookup[rec, "Status", "?"], ToString[rec]];
    If[hasAssembly[rec], frame = "Chart"; asm = rec["Assembly"],
      log["  chart assembly ", asmStatus, " -- ",
        ToString[Short[Lookup[rec, "Reason", "-"], 2]]]]];
  ];
If[frame === None || ! AssociationQ[asm] || asm["Status"] =!= "OK",
  phase["ASSEMBLE", AbsoluteTime[] - t0, "status=NOASSEMBLY last=", asmStatus];
  putAtomic[<|"Family" -> family, "Status" -> "NoAssembly", "Reason" -> asmStatus,
    "Frame" -> frameArg, "Date" -> DateString[]|>,
    FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
  log["ABORT: the family does not assemble in the requested frame"];
  Exit[3]];

vars = If[frame === "Chart", {xx, yy}, {vv, ww}];
x1 = vars[[1]]; x2 = vars[[2]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = asm["N"];
dims = Length /@ ranges;
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
(* famBlocks is in the class-ASSIGNMENT file order; the assembly reorders
   the blocks topologically (MasterTransport.wl:1257 blocks = blocks[[order]])
   and Ranges/Blocks/Apv follow THAT order.  Re-key the class labels by the
   block's original row set so that Classes[[i]] labels Blocks[[i]]; taking
   famBlocks[[All,2]] directly mislabels every family whose DAG order differs
   from the file order. *)
classOfRows = Association @ Table[
   Sort[famBlocks[[i, 1]]] -> (famBlocks[[i, 2]] /.
      r_Association :> Lookup[r, "ClassID", "record"]), {i, Length[famBlocks]}];
classes = Table[Lookup[classOfRows, Key[Sort[asm["Blocks"][[i]]]],
    Missing["BlockNotInAssignment"]], {i, nb}];
tPerBlock = Table[asm["Forms"][[i]]["T"], {i, nb}];
tInvPerBlock = asm["TInverse"];
ax0 = asm["Apv"]; ay0 = asm["Apw"];            (* conjugated (block eps-forms) *)
a0x = asm["Av"];  a0y = asm["Aw"];             (* ORIGINAL permuted, same frame *)
certOK = TrueQ[FeynFacet`Private`masterTransportCertificateOK[asm]];
basePoint = If[frame === "Chart", {1/2, x2}, {1/4, 1/4}];
targetPoint = vars;
If[asmStatus =!= "cached",
  putAtomic[<|"Family" -> family, "FrameArg" -> frameArg, "Frame" -> frame,
    "Assembly" -> asm, "Date" -> DateString[]|>, asmCache]];
phase["ASSEMBLE", AbsoluteTime[] - t0, "frame=", frame, " dim=", n,
  " blocks=", nb, " dims=", dims, " classes=", classes,
  " certificate=", certOK, " source=", asmStatus];

(* ------------------------------------------------------------------ *)
(*  (2) coupling purity: on the path AND in both frame variables        *)
(* ------------------------------------------------------------------ *)

epsOrderOf[e_] := FeynFacet`Private`masterTransportEpsOrder[e, ee];
laurentAt[e_, r_] := Module[{l = FeynFacet`Private`masterTransportLaurentList[e, {r, r}, ee]},
  If[l === $Failed, $Failed, First[l]]];

(* the exact structure of ONE entry as a rational function of one
   variable: pole orders, polynomial part, letters, numerators free of
   that variable.  Mapped over ENTRIES, never over a submatrix. *)
classifyEntry[e_, var_] := Module[{t, ap, terms, poles, poly},
  t = Together[e];
  If[TrueQ[t === 0],
    Return[<|"Zero" -> True, "MaxPole" -> 0, "PolyDegree" -> None,
      "NumeratorsFree" -> True, "Letters" -> {}|>]];
  ap = Apart[t, var];
  terms = If[Head[ap] === Plus, List @@ ap, {ap}];
  poles = {}; poly = {};
  Do[Module[{tt = Together[term], num, den, k, letter, fl, lin},
     num = Numerator[tt]; den = Denominator[tt];
     If[FreeQ[den, var],
       (* Exponent[0, var] is -Infinity: an exactly zero Apart term would
          otherwise be recorded as a polynomial part and make a pure
          coupling read as non-pure *)
       If[! TrueQ[num === 0], AppendTo[poly, Exponent[num, var]]],
       k = Exponent[den, var];
       fl = FactorList[den][[All, 1]];
       lin = Select[fl, ! FreeQ[#, var] &];
       letter = If[Length[lin] === 1 && Exponent[First[lin], var] === 1,
         Together[-Coefficient[First[lin], var, 0]/Coefficient[First[lin], var, 1]],
         "NotASinglePowerOfALinearFactor"];
       AppendTo[poles, <|"Order" -> k, "Letter" -> letter,
         "NumeratorFree" -> FreeQ[num, var]|>]]],
   {term, terms}];
  <|"Zero" -> False,
    "MaxPole" -> If[poles === {}, 0, Max[poles[[All, "Order"]]]],
    "PolyDegree" -> If[poly === {}, None, Max[poly]],
    "NumeratorsFree" -> AllTrue[poles, TrueQ[#["NumeratorFree"]] &],
    "Letters" -> DeleteDuplicates[poles[[All, "Letter"]]]|>];

(* the S1 measurement of one matrix, per block pair and per eps-order *)
purityOf[m_, var_, label_String] := Module[
  {records = {}, live, allOrders, maxPoleAll, polyAll, numOK, lettersAll, nonPure},
  Do[If[i >= j,
    Module[{sub, entries, nonzero, ords, r0, r1, perOrder},
     sub = m[[ranges[[i]], ranges[[j]]]];
     entries = Flatten[sub];
     nonzero = Select[entries, ! zeroQ[#] &];
     If[nonzero === {},
       AppendTo[records, <|"I" -> i, "J" -> j, "Zero" -> True|>],
       ords = epsOrderOf /@ nonzero;
       r0 = Min[ords]; r1 = r0 + kExtra;
       perOrder = Table[
         Module[{coeffs, classified},
          coeffs = Map[laurentAt[#, rr] &, sub, {2}];
          If[! FreeQ[coeffs, $Failed],
            <|"Order" -> rr, "Status" -> "LaurentFailed"|>,
            classified = Map[classifyEntry[#, var] &, coeffs, {2}];
            <|"Order" -> rr, "Status" -> "OK",
              "AllZero" -> AllTrue[Flatten[classified], TrueQ[#["Zero"]] &],
              "MaxPole" -> Max[Append[Table[c["MaxPole"], {c, Flatten[classified]}], 0]],
              "PolyDegrees" -> DeleteDuplicates[DeleteCases[
                 Table[c["PolyDegree"], {c, Flatten[classified]}],
                 None | DirectedInfinity[-1]]],
              "NumeratorsFree" -> AllTrue[Flatten[classified], TrueQ[#["NumeratorsFree"]] &],
              "Letters" -> DeleteDuplicates[Flatten[
                 Table[c["Letters"], {c, Flatten[classified]}]]]|>]],
         {rr, r0, r1}];
       AppendTo[records, <|"I" -> i, "J" -> j, "Zero" -> False,
         "Dims" -> {dims[[i]], dims[[j]]}, "Classes" -> {classes[[i]], classes[[j]]},
         "RMin" -> r0, "Window" -> {r0, r1}, "PerOrder" -> perOrder|>]]]],
   {i, nb}, {j, nb}];
  live = Select[records, ! TrueQ[#["Zero"]] &];
  allOrders = Select[Flatten[Table[r["PerOrder"], {r, live}], 1],
    #["Status"] === "OK" && ! TrueQ[#["AllZero"]] &];
  maxPoleAll = Max[Append[Table[p["MaxPole"], {p, allOrders}], 0]];
  polyAll = DeleteDuplicates[Flatten[Table[p["PolyDegrees"], {p, allOrders}]]];
  numOK = AllTrue[allOrders, TrueQ[#["NumeratorsFree"]] &];
  lettersAll = DeleteDuplicates[Flatten[Table[p["Letters"], {p, allOrders}]]];
  (* a coupling (i,j), i =!= j, is NON-PURE at an order if it has a higher
     pole, a polynomial part, a non-free numerator or an eps-dependent
     letter there *)
  nonPure = Flatten[Table[
    Module[{r = live[[q]]},
     If[r["I"] === r["J"], {},
      Table[Module[{p = r["PerOrder"][[s]]},
        If[p["Status"] =!= "OK" || TrueQ[p["AllZero"]], Nothing,
         If[p["MaxPole"] > 1 || p["PolyDegrees"] =!= {} ||
            ! TrueQ[p["NumeratorsFree"]] || ! FreeQ[p["Letters"], ee],
          <|"I" -> r["I"], "J" -> r["J"], "Order" -> p["Order"],
            "MaxPole" -> p["MaxPole"], "PolyDegrees" -> p["PolyDegrees"],
            "NumeratorsFree" -> p["NumeratorsFree"],
            "EpsLetters" -> Select[p["Letters"], ! FreeQ[#, ee] &]|>,
          Nothing]]],
       {s, Length[r["PerOrder"]]}]]],
    {q, Length[live]}], 1];
  <|"Label" -> label, "Variable" -> var,
    "MaxPoleOrder" -> maxPoleAll, "PolynomialPartDegrees" -> polyAll,
    "NumeratorsFree" -> numOK, "LettersEpsFree" -> FreeQ[lettersAll, ee],
    "DistinctLetters" -> Length[lettersAll], "Letters" -> lettersAll,
    "PureDlogConstantResidues" -> (maxPoleAll <= 1 && polyAll === {} && numOK &&
       FreeQ[lettersAll, ee]),
    "NonPureCouplings" -> nonPure,
    "NonPureCouplingPairs" -> DeleteDuplicates[Table[{r["I"], r["J"]}, {r, nonPure}]],
    "DiagonalRMin" -> Table[{r["I"], r["RMin"]}, {r, Select[live, #["I"] === #["J"] &]}],
    "OffDiagonalRMin" -> Table[{r["I"], r["J"], r["RMin"]},
       {r, Select[live, #["I"] =!= #["J"] &]}],
    "Records" -> records|>];

t0 = AbsoluteTime[];
ahatPath = FeynFacet`Private`masterTransportPathMatrix[ax0, ay0, targetPoint,
  basePoint, tauS, vars];
monic = FeynFacet`Private`masterTransportMonicCheck[ahatPath, tauS];
purityPath = purityOf[ahatPath, tauS, "path"];
purityX = purityOf[ax0, x1, "variable1"];
purityY = purityOf[ay0, x2, "variable2"];
epsDenAll = DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {},
      Select[FactorList[Denominator[t]][[All, 1]],
       ! FreeQ[#, ee] && (! FreeQ[#, x1] || ! FreeQ[#, x2]) &]]]],
   {ax0, ay0}, {3}]]];
purity = <|
  "Path" -> <|"Base" -> basePoint, "Target" -> targetPoint, "Parameter" -> tauS,
    "MonicLinear" -> monic["Linear"], "Measurement" -> purityPath|>,
  "Variables" -> <|ToString[x1] -> purityX, ToString[x2] -> purityY|>,
  "EpsDependentKinematicDenominators" -> epsDenAll,
  "PureOnPath" -> purityPath["PureDlogConstantResidues"],
  "PureInBothVariables" -> (purityX["PureDlogConstantResidues"] &&
     purityY["PureDlogConstantResidues"]),
  "NonPureCouplingPairsOnPath" -> purityPath["NonPureCouplingPairs"],
  "NumberOfNonPureCouplingPairs" -> Length[purityPath["NonPureCouplingPairs"]],
  "AssemblyCertificateOK" -> certOK|>;
phase["PURITY", AbsoluteTime[] - t0,
  "monicLinear=", monic["Linear"],
  " pureOnPath=", purity["PureOnPath"],
  " pureBothVars=", purity["PureInBothVariables"],
  " nonPurePairs=", purity["NumberOfNonPureCouplingPairs"], "/",
  Length[Select[purityPath["Records"], ! TrueQ[#["Zero"]] && #["I"] =!= #["J"] &]],
  " maxPoleTau=", purityPath["MaxPoleOrder"],
  " polyPart=", purityPath["PolynomialPartDegrees"],
  " epsLoci=", epsDenAll];

(* ------------------------------------------------------------------ *)
(*  THE GATE                                                            *)
(* ------------------------------------------------------------------ *)

blockLowerInverse[m_] := Module[{inv, dinv, acc},
  dinv = Table[Map[Together, Inverse[m[[ranges[[i]], ranges[[i]]]]], {2}], {i, nb}];
  inv = ConstantArray[0, {n, n}];
  Do[inv[[ranges[[i]], ranges[[i]]]] = dinv[[i]], {i, nb}];
  Do[If[i > j,
    acc = Sum[m[[ranges[[i]], ranges[[k]]]] . inv[[ranges[[k]], ranges[[j]]]],
      {k, j, i - 1}];
    inv[[ranges[[i]], ranges[[j]]]] = Map[Together, -dinv[[i]] . acc, {2}]],
   {i, nb}, {j, nb}];
  inv];

(* Residue[] rather than (L mat / dL) on the locus: the naive substitution
   divides by zero wherever a SECOND letter vanishes on the same locus
   (measured on CF230: it poisons the matrix with ComplexInfinity). *)
residueAt[mat_, L_, var_] := Module[{sol, d},
  d = D[L, var];
  If[zeroQ[d], Return[None]];
  If[Exponent[Together[L], var] =!= 1,
    Print[tag, "   !! letter ", L, " is not linear in ", var,
      " -- the residue reader does not apply"];
    Return[$Failed]];
  sol = Solve[L == 0, var];
  If[sol === {}, Return[None]];
  Map[Together[Residue[#, {var, var /. First[sol]}]] &, mat, {2}]];

(* apPre: the conjugated pair when it is ALREADY known exactly.  At
   S = identity that is the assembly's own Apv/Apw, which are built
   block-wise as T_i^-1 A0_ij T_j (- T_i^-1 dT_i on the diagonal)
   (MasterTransport.wl:1320) -- i.e. literally
   T_total^-1 A0 T_total - T_total^-1 dT_total for block-diagonal
   T_total, PROVIDED tInverse really inverts T, which condition (v) of
   this gate re-establishes independently below.  Recomputing it costs
   minutes on the 13x13-24x24 families and gains nothing; the route
   taken is recorded in the gate record. *)
runGate[sMat_, label_String] := runGate[sMat, label, None];
runGate[sMat_, label_String, apPre_] := Module[
  {upperZero, diagBlocks, diagXYFree, diagIdentity, tbd, tbdInv, ttot, sInv,
   ttotInv, invOK, ap, epsFree, b, rawLetters, letters, epsInLetters, resX,
   resY, constX, constY, reconX, reconY, gateX, gateY, sameR, flat, verdict,
   gateRec, linearOK},
  upperZero = AllTrue[Flatten[Table[If[i < j, sMat[[ranges[[i]], ranges[[j]]]], {}],
     {i, nb}, {j, nb}]], zeroQ];
  diagBlocks = Table[Map[Together, sMat[[ranges[[i]], ranges[[i]]]], {2}], {i, nb}];
  diagXYFree = AllTrue[Flatten[diagBlocks], FreeQ[#, x1] && FreeQ[#, x2] &];
  diagIdentity = AllTrue[Table[
     zeroMatQ[diagBlocks[[i]] - IdentityMatrix[Length[ranges[[i]]]]], {i, nb}], TrueQ];
  tbd = ConstantArray[0, {n, n}]; tbdInv = ConstantArray[0, {n, n}];
  Do[tbd[[ranges[[i]], ranges[[i]]]] = tPerBlock[[i]];
     tbdInv[[ranges[[i]], ranges[[i]]]] = tInvPerBlock[[i]], {i, nb}];
  ttot = Map[Together, tbd . sMat, {2}];
  sInv = blockLowerInverse[sMat];
  ttotInv = Map[Together, sInv . tbdInv, {2}];
  invOK = zeroMatQ[ttot . ttotInv - IdentityMatrix[n]] &&
          zeroMatQ[ttotInv . ttot - IdentityMatrix[n]];
  ap = If[apPre =!= None, apPre,
    Table[Map[Together,
      ttotInv . {a0x, a0y}[[mu]] . ttot - ttotInv . D[ttot, vars[[mu]]], {2}], {mu, 2}]];
  epsFree = AllTrue[Flatten[ap], FreeQ[Together[#/ee], ee] &];
  b = If[epsFree, Table[Map[Together[#/ee] &, ap[[mu]], {2}], {mu, 2}], ap];
  rawLetters = DeleteDuplicates[Flatten[Map[
     Function[e, Module[{t = Together[e]},
       If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], b, {3}]]];
  rawLetters = Select[rawLetters, ! FreeQ[#, x1] || ! FreeQ[#, x2] &];
  letters = DeleteDuplicates[Together /@ rawLetters, NumberQ[Together[#1/#2]] &];
  epsInLetters = Select[letters, ! FreeQ[#, ee] &];
  linearOK = True;
  resX = Association @ Table[Module[{r = residueAt[b[[1]], L, x1]},
     If[r === $Failed, linearOK = False; Nothing, If[r === None, Nothing, L -> r]]],
    {L, letters}];
  resY = Association @ Table[Module[{r = residueAt[b[[2]], L, x2]},
     If[r === $Failed, linearOK = False; Nothing, If[r === None, Nothing, L -> r]]],
    {L, letters}];
  constX = AllTrue[Flatten[Values[resX]], FreeQ[#, x1] && FreeQ[#, x2] && FreeQ[#, ee] &];
  constY = AllTrue[Flatten[Values[resY]], FreeQ[#, x1] && FreeQ[#, x2] && FreeQ[#, ee] &];
  reconX = If[Length[resX] === 0, ConstantArray[0, {n, n}],
    Sum[resX[L] D[Log[L], x1], {L, Keys[resX]}]];
  reconY = If[Length[resY] === 0, ConstantArray[0, {n, n}],
    Sum[resY[L] D[Log[L], x2], {L, Keys[resY]}]];
  gateX = zeroMatQ[b[[1]] - reconX];
  gateY = zeroMatQ[b[[2]] - reconY];
  sameR = AllTrue[Intersection[Keys[resX], Keys[resY]], zeroMatQ[resX[#] - resY[#]] &];
  flat = zeroMatQ[D[ap[[1]], x2] - D[ap[[2]], x1] + ap[[1]] . ap[[2]] - ap[[2]] . ap[[1]]];
  verdict = And @@ (TrueQ /@ {upperZero, diagXYFree, invOK, epsFree, constX,
     constY, gateX, gateY, sameR, flat, linearOK, epsInLetters === {}});
  gateRec = <|"BlockLowerTriangular" -> upperZero, "SDiagonalFreeOfXY" -> diagXYFree,
    "SUnipotent" -> diagIdentity, "TTotalInvertible" -> invOK,
    "EpsLinear" -> epsFree, "LettersEpsFree" -> (epsInLetters === {}),
    "LettersLinearInDirection" -> linearOK,
    "ResiduesConstantX" -> constX, "ResiduesConstantY" -> constY,
    "DlogIdentityX" -> gateX, "DlogIdentityY" -> gateY,
    "ResiduesAgree" -> sameR, "Flat" -> flat,
    "ConjugationRoute" -> If[apPre === None, "RecomputedFromOriginalConnections",
      "AssemblyBlockConjugation (T_total^-1 A0 T_total - T_total^-1 dT_total by \
construction, with (v) re-establishing T_total^-1)"]|>;
  Print[tag, " GATE(", label, ") verdict=", If[verdict, "PASSED", "FAILED"],
    " ", Normal[gateRec], " letters=", Length[letters],
    If[epsInLetters === {}, "", " EPSLETTERS=" <> ToString[epsInLetters]]];
  <|"Verdict" -> verdict, "Gate" -> gateRec, "Letters" -> letters,
    "Residues" -> Association[Table[L -> Lookup[resX, L, Lookup[resY, L, None]],
       {L, letters}]],
    "EpsFormX" -> ap[[1]], "EpsFormY" -> ap[[2]],
    "S" -> sMat, "SInverse" -> sInv, "TBlockDiagonal" -> tbd,
    "TTotal" -> ttot, "TTotalInverse" -> ttotInv|>];

(* ------------------------------------------------------------------ *)
(*  (3) the cheap branch: is it already a family eps-form?              *)
(* ------------------------------------------------------------------ *)

mechanisms = {};
t0 = AbsoluteTime[];
(* SHORT-CIRCUIT, measured: gate condition (ii) demands EPS-FREE letters,
   and an eps-dependent (x,y) denominator factor of Apv/Apw IS an
   eps-dependent letter (dividing by eps cannot cancel it).  So when the
   purity measurement already found one, GATE0 is a foregone failure.
   On CF230 that gate cost 1293 s -- with the conjugation already taken
   from the assembly, i.e. the cost is the letter/residue extraction on
   the uncleaned 13x13, not the conjugation -- to establish exactly the
   "LettersEpsFree -> False" that epsDenAll had already reported. *)
If[epsDenAll =!= {},
  gateResult = <|"Verdict" -> False,
    "Gate" -> <|"LettersEpsFree" -> False,
      "Skipped" -> "GATE0 not run: the purity measurement found eps-dependent \
kinematic denominators, which are eps-dependent letters, so condition (ii) \
cannot hold at S = 1",
      "EpsDependentLetters" -> epsDenAll|>,
    "Letters" -> {}, "Residues" -> <||>,
    "EpsFormX" -> ax0, "EpsFormY" -> ay0,
    "S" -> IdentityMatrix[n], "SInverse" -> IdentityMatrix[n],
    "TBlockDiagonal" -> None, "TTotal" -> None, "TTotalInverse" -> None|>;
  phase["GATE0", AbsoluteTime[] - t0, "verdict=SKIPPED-FAILED",
    " reason=epsDependentLetters ", epsDenAll],
  gateResult = runGate[IdentityMatrix[n], "S=1", If[certOK, {ax0, ay0}, None]];
  phase["GATE0", AbsoluteTime[] - t0, "verdict=",
    If[gateResult["Verdict"], "PASSED", "FAILED"],
    " letters=", Length[gateResult["Letters"]]]];
(* an ACCEPTED family must carry the gate on the recomputed conjugation *)
If[gateResult["Verdict"] && certOK,
  t0 = AbsoluteTime[];
  gateResult = runGate[IdentityMatrix[n], "S=1-recomputed", None];
  phase["GATE0R", AbsoluteTime[] - t0, "verdict=",
    If[gateResult["Verdict"], "PASSED", "FAILED"]]];

status = If[gateResult["Verdict"], "AlreadyEpsForm", "NeedsCleanup"];

(* ------------------------------------------------------------------ *)
(*  (4) the cleanup                                                     *)
(* ------------------------------------------------------------------ *)

stateFile[suffix_String] := FileNameJoin[{outdir,
  "state_" <> family <> "_" <> suffix <> ".wl"}];

epsXYDen[mm_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {},
      Select[FactorList[Denominator[t]][[All, 1]],
       ! FreeQ[#, ee] && (! FreeQ[#, x1] || ! FreeQ[#, x2]) &]]]], mm, {3}]]];
poleOrderAt[e_, L_] := Module[{t = Together[e]},
  If[TrueQ[t === 0], 0,
   Total[Cases[FactorList[Denominator[t]], {f_, p_} /; NumberQ[Together[f/L]] :> p]]]];
(* poleOrderAt takes ONE entry.  Handed a SUBMATRIX,
   FactorList[Denominator[matrix]] is nonsense and Total[{}] = 0 -- a silent
   "no poles anywhere" that reads as a clean verdict (measured 2026-08-17).
   Everything below maps it over entries. *)
maxPoleOf[mm_, L_] := Max[Append[Map[poleOrderAt[#, L] &, Flatten[mm]], 0]];
blockPole[aa_, i_, j_, L_] := Max[Append[Flatten[Table[
   Map[poleOrderAt[#, L] &, Flatten[aa[[mu]][[ranges[[i]], ranges[[j]]]]]], {mu, 2}]], 0]];
lettersOf[aa_] := DeleteDuplicates[
  Select[DeleteDuplicates[Flatten[Map[
     Function[e, Module[{t = Together[e]},
       If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], aa, {3}]]],
   ! FreeQ[#, x1] || ! FreeQ[#, x2] &],
  NumberQ[Together[#1/#2]] &];

applyStrip[aa_, nmat_] := Table[Map[Together,
   aa[[mu]] - D[nmat, vars[[mu]]] + aa[[mu]] . nmat - nmat . aa[[mu]], {2}], {mu, 2}];

(* ---- M1: closed-form strip of the eps-DEPENDENT loci ---- *)
epsLocusStrip[aIn_, sIn_] := Module[
  {a = aIn, s = sIn, loci, q, var, other, gcd, cofac, dqInv, step = 0, applied = 0,
   done = False, k, rows, cols, mat, nmat},
  loci = epsXYDen[a];
  If[loci === {}, Return[<|"A" -> a, "S" -> s, "Applied" -> 0, "Loci" -> {},
    "Status" -> "NoEpsLocus"|>]];
  log["  M1 eps-dependent kinematic loci: ", loci];
  Do[
    q = loci[[qi]];
    var = If[! zeroQ[D[q, x1]], x1, x2];
    other = If[var === x1, x2, x1];
    {gcd, cofac} = PolynomialExtendedGCD[q, D[q, var], other];
    If[! FreeQ[gcd, other],
      log["  M1 !! gcd(q, d q) depends on ", other, " -- q and its derivative are not coprime"];
      Continue[]];
    dqInv = Together[cofac[[2]]/gcd];
    step = 0; done = False;
    While[! done && step <= 8,
     k = Max[Table[maxPoleOf[a[[mu]], q], {mu, 2}]];
     If[k === 0, done = True; Break[]];
     If[k === 1,
       log["  M1 !! a SIMPLE pole at ", q,
         " survives -- the nilpotency/monodromy argument says this cannot happen"];
       done = True; Break[]];
     rows = Flatten[ranges[[Select[Range[nb], Function[i,
        Max[Table[maxPoleOf[a[[mu]][[ranges[[i]], All]], q], {mu, 2}]] > 0]]]]];
     cols = Complement[Range[n], rows];
     mat = Map[Together[q^k #] &, a[[If[var === x1, 1, 2]]][[rows, cols]], {2}];
     mat = Map[Together[-# dqInv/(k - 1)] &, mat, {2}];
     nmat = ConstantArray[0, {n, n}];
     nmat[[rows, cols]] = Map[Together[#/q^(k - 1)] &, mat, {2}];
     If[! zeroMatQ[nmat . nmat],
       log["  M1 !! N^2 is not zero -- support assumption violated"]; done = True; Break[]];
     a = applyStrip[a, nmat];
     s = Map[Together, s . (IdentityMatrix[n] + nmat), {2}];
     applied++; step++;
     log["  M1 locus ", q, " step ", step, ": pole ", k, " -> ",
       Max[Table[maxPoleOf[a[[mu]], q], {mu, 2}]], ", strip leaves ", LeafCount[nmat]]],
   {qi, Length[loci]}];
  <|"A" -> a, "S" -> s, "Applied" -> applied, "Loci" -> loci,
    "Remaining" -> epsXYDen[a],
    "Status" -> If[epsXYDen[a] === {}, "OK", "EpsLocusRemains"]|>];

(* ---- M2: closed-form Fuchs/Moser reduction at the eps-FREE letters ----
   The letter set is refreshed between PASSES, not inside the step loop:
   substituting L = 0 to read C_k can introduce denominators in the other
   variable, so a new letter can appear; recomputing lettersOf on every
   step costs O(n^2) FactorList calls and dominates on the big families. *)
fuchsReduce[aIn_, sIn_, maxSteps_Integer, budget_] := Module[
  {a = aIn, s = sIn, letters, step = 0, worst, k, i, j, L, var, rootRule, dimI,
   dimJ, ri, rj, ck, op, m, nmat, resAt, tStart = AbsoluteTime[], pass = 0,
   lettersSeen = {}, stop = False, tab, weight, fingerprint, seen = {},
   bestA = aIn, bestS = sIn, bestW = Infinity, cycles = 0, note = "OK"},
  resAt[mm_, LL_, vr_, rr_] := Map[Together, Together[LL mm/D[LL, vr]] /. rr, {2}];
  While[pass < 3 && ! stop,
   pass++;
   letters = Select[lettersOf[a], FreeQ[#, ee] &];
   If[letters === {} || (pass > 1 && Complement[letters, lettersSeen] === {}), Break[]];
   lettersSeen = Union[lettersSeen, letters];
   seen = {};
  While[step < maxSteps && ! stop,
   If[AbsoluteTime[] - tStart > budget,
     log["  M2 !! budget ", budget, " s exhausted after ", step, " steps"];
     note = "BudgetExhausted"; stop = True; Break[]];
   (* ONE scan per step produces both the selection and the total pole
      content.  The MEASURED negative this guards against (recorded in
      TransportProductionPlan.md and reproduced here on CF201 pair (7,4)):
      a one-letter-at-a-time Moser reduction does NOT converge in two
      variables -- clearing the pole at 1-x in the x-direction puts the
      pole at 1-y back in the y-direction, and the two alternate forever.
      Right-to-left column order is necessary but not sufficient.  So the
      state is fingerprinted, a repeat stops the loop, and the BEST state
      ever reached (least total pole content) is what is returned -- M2
      can then never hand M4 something worse than it was given. *)
   tab = Table[If[i2 > j2, Table[blockPole[a, i2, j2, LL], {LL, letters}], {}],
     {i2, nb}, {j2, nb}];
   weight = Total[Flatten[tab]];
   fingerprint = Flatten[tab];
   If[weight < bestW, bestW = weight; bestA = a; bestS = s];
   If[MemberQ[seen, fingerprint],
     cycles++;
     log["  M2 !! state repeats after ", step,
       " steps (two-variable Moser cycle); returning the best state seen, \
total pole content ", bestW];
     note = "CycleDetected"; stop = True; Break[]];
   AppendTo[seen, fingerprint];
   worst = None; k = 1;
   Do[If[i2 > j2 && worst === None,
     Module[{ko = Max[Append[tab[[i2, j2]], 0]]},
      If[ko > 1, k = ko;
       worst = {i2, j2, letters[[First[FirstPosition[tab[[i2, j2]], ko]]]]}]]],
    {i2, nb, 1, -1}, {j2, nb, 1, -1}];
   If[worst === None, Break[]];
   {i, j, L} = worst;
   var = If[! zeroQ[D[L, x1]], x1, x2];
   If[Exponent[Together[L], var] =!= 1,
     log["  M2 !! letter ", L, " is not linear in ", var, " -- stopping"]; Break[]];
   rootRule = First[Solve[L == 0, var]];
   dimI = Length[ranges[[i]]]; dimJ = Length[ranges[[j]]];
   ri = resAt[a[[If[var === x1, 1, 2]]][[ranges[[i]], ranges[[i]]]], L, var, rootRule];
   rj = resAt[a[[If[var === x1, 1, 2]]][[ranges[[j]], ranges[[j]]]], L, var, rootRule];
   ck = Map[Together,
     Together[L^k a[[If[var === x1, 1, 2]]][[ranges[[i]], ranges[[j]]]]] /. rootRule, {2}];
   (* [(k-1) M + eps (R_i M - M R_j)] d_var L = -C_k  on L = 0; the operator
      is (k-1) + eps(lambda_i - lambda_j), invertible over Q(eps) for k >= 2 *)
   op = (k - 1) IdentityMatrix[dimI dimJ] +
     KroneckerProduct[ri, IdentityMatrix[dimJ]] -
     KroneckerProduct[IdentityMatrix[dimI], Transpose[rj]];
   m = Quiet[Check[LinearSolve[op, Flatten[Map[Together[-#/(D[L, var] /. rootRule)] &,
        ck, {2}]]], $Failed]];
   If[m === $Failed, log["  M2 !! Sylvester solve failed at (", i, ",", j, ") ", L]; Break[]];
   m = Map[Together, ArrayReshape[m, {dimI, dimJ}], {2}];
   nmat = ConstantArray[0, {n, n}];
   nmat[[ranges[[i]], ranges[[j]]]] = Map[Together[#/L^(k - 1)] &, m, {2}];
   If[! zeroMatQ[nmat . nmat], log["  M2 !! N^2 nonzero"]; Break[]];
   a = applyStrip[a, nmat];
   s = Map[Together, s . (IdentityMatrix[n] + nmat), {2}];
   step++;
   If[Mod[step, 5] === 1 || step <= 3,
     log["  M2 step ", step, ": pair (", i, ",", j, ") letter ", L, " pole ", k,
       " -> ", blockPole[a, i, j, L]]]]];
  (* never return a state worse than the best one reached *)
  Module[{wEnd = Total[Flatten[Table[
      If[i3 > j3, Table[blockPole[a, i3, j3, LL],
         {LL, Select[lettersOf[a], FreeQ[#, ee] &]}], {}], {i3, nb}, {j3, nb}]]]},
   If[wEnd <= bestW, bestW = wEnd; bestA = a; bestS = s]];
  a = bestA; s = bestS;
  <|"A" -> a, "S" -> s, "Steps" -> step, "Passes" -> pass, "Cycles" -> cycles,
    "TotalPoleContent" -> bestW, "Note" -> note,
    "MaxOffDiagonalPole" -> Max[Append[Flatten[Table[
       If[i3 > j3, Table[blockPole[a, i3, j3, LL], {LL, Select[lettersOf[a], FreeQ[#, ee] &]}],
        {}], {i3, nb}, {j3, nb}]], 1]],
    "Status" -> "OK"|>];

(* ---- the dlog test (CANONICA's own fast path is misled by eps-only
        denominator factors, so it is made here directly) ---- *)
dlogTest[aa_] := Module[{letters, resX, resY, constX, constY, ok, bad = False},
  letters = lettersOf[aa];
  If[AnyTrue[letters, ! FreeQ[#, ee] &],
    Return[<|"Dlog" -> False, "Reason" -> "eps-dependent letters",
      "Letters" -> letters|>]];
  resX = Association @ Table[Module[{r = residueAt[aa[[1]], L, x1]},
     If[r === $Failed, bad = True; Nothing, If[r === None, Nothing, L -> r]]], {L, letters}];
  resY = Association @ Table[Module[{r = residueAt[aa[[2]], L, x2]},
     If[r === $Failed, bad = True; Nothing, If[r === None, Nothing, L -> r]]], {L, letters}];
  If[bad, Return[<|"Dlog" -> False, "Reason" -> "letter not linear in its direction",
     "Letters" -> letters|>]];
  constX = AllTrue[Flatten[Values[resX]], FreeQ[#, x1] && FreeQ[#, x2] &];
  constY = AllTrue[Flatten[Values[resY]], FreeQ[#, x1] && FreeQ[#, x2] &];
  ok = constX && constY &&
    zeroMatQ[aa[[1]] - If[Length[resX] === 0, ConstantArray[0, {n, n}],
       Sum[resX[L] D[Log[L], x1], {L, Keys[resX]}]]] &&
    zeroMatQ[aa[[2]] - If[Length[resY] === 0, ConstantArray[0, {n, n}],
       Sum[resY[L] D[Log[L], x2], {L, Keys[resY]}]]];
  <|"Dlog" -> ok, "ResiduesXYFree" -> {constX, constY}, "Letters" -> letters,
    "EpsFactored" -> AllTrue[Join[Flatten[Values[resX]], Flatten[Values[resY]]],
       FreeQ[Together[#/ee], ee] &]|>];

(* ---- why a state is NOT an eps-form: the obstruction, per block pair ----
   Three mutually exclusive causes, measured rather than guessed:
     HigherPoles         a letter still carries a pole of order >= 2
     ResidueNotXYFree    all poles simple but a residue depends on x or y
     NonDlogRemainder    all poles simple and residues constant, yet
                         A_mu - Sum_a R_a dlog phi_a =!= 0 -- i.e. an
                         ENTIRE part (a singularity at infinity), which no
                         finite-letter strip and no CANONICA D-ansatz over
                         the finite alphabet can remove
     EpsOrder            dlog with (x,y)-free residues that are NOT eps *
                         constant (the eps-only finish M3 handles this)   *)
obstruction[aa_] := Module[{letters, out = {}, resOf, remOf},
  letters = lettersOf[aa];
  resOf[mm_, L_, mu_] := Module[{v = vars[[mu]], sol},
    If[zeroQ[D[L, v]], Return[None]];
    If[Exponent[Together[L], v] =!= 1, Return[$Failed]];
    sol = Solve[L == 0, v];
    If[sol === {}, None, Map[Together[Residue[#, {v, v /. First[sol]}]] &, mm, {2}]]];
  Do[If[i >= j,
    Module[{sub, higher, resbad, rem, entire, active},
     sub = Table[aa[[mu]][[ranges[[i]], ranges[[j]]]], {mu, 2}];
     If[zeroMatQ[sub], Null,
      higher = Select[letters, blockPole[aa, i, j, #] > 1 &];
      resbad = {}; entire = {};
      Do[Module[{r = resOf[sub[[mu]], L, mu]},
         If[MatrixQ[r] && ! AllTrue[Flatten[r], FreeQ[#, x1] && FreeQ[#, x2] &],
           AppendTo[resbad, {L, vars[[mu]]}]]],
       {mu, 2}, {L, letters}];
      Do[Module[{acc = ConstantArray[0, {Length[ranges[[i]]], Length[ranges[[j]]]}]},
         Do[Module[{r = resOf[sub[[mu]], L, mu]},
            If[MatrixQ[r], acc = acc + r D[Log[L], vars[[mu]]]]], {L, letters}];
         rem = Map[Together, sub[[mu]] - acc, {2}];
         If[! zeroMatQ[rem],
           AppendTo[entire, <|"Direction" -> vars[[mu]],
             "RemainderIsPolynomial" -> AllTrue[Flatten[rem],
                zeroQ[#] || FreeQ[Denominator[Together[#]], vars[[mu]]] &],
             "MaxLeaves" -> Max[LeafCount /@ Flatten[rem]]|>]]],
       {mu, 2}];
      active = higher =!= {} || resbad =!= {} || entire =!= {};
      If[active,
        AppendTo[out, <|"I" -> i, "J" -> j, "Diagonal" -> (i === j),
          "HigherPoles" -> higher, "ResidueNotXYFree" -> resbad,
          "NonDlogRemainder" -> entire|>]]]]],
   {i, nb}, {j, nb}];
  <|"Letters" -> letters, "Pairs" -> out,
    "Classes" -> DeleteDuplicates[Flatten[Table[
       Join[If[p["HigherPoles"] =!= {}, {"HigherPoles"}, {}],
            If[p["ResidueNotXYFree"] =!= {}, {"ResidueNotXYFree"}, {}],
            If[p["NonDlogRemainder"] =!= {}, {"NonDlogRemainder"}, {}]],
       {p, out}]]]|>];

canonicaLoaded = False;
loadCanonica[] := If[! canonicaLoaded,
  FeynFacet`Private`canonicalBlocksLoadCanonica[]; canonicaLoaded = True];
toCanonica[expr_] := expr /. {ee -> CANONICA`eps};
fromCanonica[expr_] := expr /. {CANONICA`eps -> ee};

(* ---- M3: the eps-ONLY finish ---- *)
dlogToEpsForm[aIn_, sIn_] := Module[{res, u, aNew},
  loadCanonica[];
  res = CANONICA`TransformDlogToEpsForm[vars, bounds, IdentityMatrix[n],
    toCanonica[aIn], CANONICA`VerbosityLevel -> 0];
  If[res[[1]] === False,
    Return[<|"A" -> aIn, "S" -> sIn, "Status" -> "False"|>]];
  u = fromCanonica[res[[1]]];
  aNew = Table[Map[Together,
     Inverse[u] . aIn[[mu]] . u - Inverse[u] . D[u, vars[[mu]]], {2}], {mu, 2}];
  <|"A" -> aNew, "S" -> Map[Together, sIn . u, {2}], "U" -> u,
    "UFreeOfXY" -> (FreeQ[u, x1] && FreeQ[u, x2]), "Status" -> "OK"|>];

(* ---- M4: CANONICA off-diagonal recursion, subsector by subsector ---- *)
canonicaOffDiagonal[aIn_, sIn_, budget_] := Module[
  {a = aIn, s = sIn, tStart = AbsoluteTime[], degrees, perSector = {}, failed = False},
  loadCanonica[];
  degrees = {{0, 0}, {1, 0}, {1, 1}, {2, 1}};
  Do[
   If[failed, Continue[]];
   Module[{nk, subSize, aTrunc, boundsK, offRows, offCols, already, got = False,
     partFile, prevD, trafoD, sfull, aNew, secStart = AbsoluteTime[], usedDeg = None},
    nk = bounds[[k, 2]];
    subSize = Length[ranges[[k]]];
    boundsK = bounds[[1 ;; k]];
    offRows = ranges[[k]]; offCols = Range[1, nk - subSize];
    already = If[offCols === {}, True,
      dlogTest[Table[Module[{mm = ConstantArray[0, {n, n}]},
         mm[[offRows, offCols]] = a[[mu]][[offRows, offCols]]; mm], {mu, 2}]]["Dlog"]];
    If[already,
      log["  M4 sector ", k, ": off-diagonal block already dlog with (x,y)-free residues -- skipped"];
      AppendTo[perSector, <|"Sector" -> k, "Skipped" -> True, "Seconds" -> 0.|>];
      Continue[]];
    Do[
     If[got, Continue[]];
     Module[{numDeg = degrees[[d, 1]], denDeg = degrees[[d, 2]], opts, res, secs},
      partFile = stateFile["canonica_s" <> ToString[k] <> "_d" <> ToString[numDeg] <>
        ToString[denDeg]];
      prevD = If[FileExistsQ[partFile],
        Module[{p = toCanonica[normalizeSymbols[Get[partFile]]]},
         log["  M4 sector ", k, " (deg ", {numDeg, denDeg}, "): resuming with ",
           Length[First[p]], " columns"]; p],
        Table[{}, {subSize}]];
      opts = {CANONICA`DDeltaNumeratorDegree -> numDeg,
        (* DDeltaDenominatorDegree is first created inside CANONICA`Private
           (CANONICA.m:522); the public spelling silently binds another symbol *)
        CANONICA`Private`DDeltaDenominatorDegree -> denDeg,
        CANONICA`VerbosityLevel -> 0};
      aTrunc = toCanonica[{a[[1]][[1 ;; nk, 1 ;; nk]], a[[2]][[1 ;; nk, 1 ;; nk]]}];
      Catch[
       While[Length[First[prevD]] + subSize =!= nk,
        If[AbsoluteTime[] - tStart > budget,
          log["  M4 !! budget ", budget, " s exhausted in sector ", k];
          Throw[Null, "fe"]];
        {secs, res} = AbsoluteTiming[CANONICA`CalculateNextSubsectorD[aTrunc, vars,
           boundsK, prevD, Sequence @@ opts]];
        If[res === False || First[res] === False,
          log["  M4 sector ", k, " deg ", {numDeg, denDeg},
            ": CalculateNextSubsectorD returned False after ", Round[secs, 0.1], " s"];
          Throw[Null, "fe"]];
        prevD = res;
        putAtomic[fromCanonica[prevD], partFile];
        log["  M4 sector ", k, " deg ", {numDeg, denDeg}, ": ",
          Length[First[prevD]], "/", nk - subSize, " columns, ", Round[secs, 0.1],
          " s, leaves ", LeafCount[prevD]]];
       If[Length[First[prevD]] + subSize === nk, got = True; usedDeg = {numDeg, denDeg}],
       "fe"]],
     {d, Length[degrees]}];
    If[! got,
      log["  M4 !! sector ", k, " could not be closed at any ansatz degree"];
      failed = True;
      AppendTo[perSector, <|"Sector" -> k, "Skipped" -> False, "Closed" -> False,
        "Seconds" -> Round[AbsoluteTime[] - secStart, 0.1]|>];
      Continue[]];
    trafoD = fromCanonica[CANONICA`Private`InsertDIntoIdentity[boundsK,
       toCanonica[normalizeSymbols[Get[partFile]]]]];
    sfull = IdentityMatrix[n];
    sfull[[1 ;; nk, 1 ;; nk]] = trafoD;
    aNew = Table[Map[Together,
       Inverse[sfull] . a[[mu]] . sfull - Inverse[sfull] . D[sfull, vars[[mu]]], {2}],
      {mu, 2}];
    a = aNew;
    s = Map[Together, s . sfull, {2}];
    AppendTo[perSector, <|"Sector" -> k, "Skipped" -> False, "Closed" -> True,
      "AnsatzDegrees" -> usedDeg, "Seconds" -> Round[AbsoluteTime[] - secStart, 0.1]|>];
    putAtomic[<|"Sector" -> k, "S" -> s, "A" -> a|>,
      stateFile["canonica_after_s" <> ToString[k]]];
    log["  M4 sector ", k, " closed with ansatz degrees ", usedDeg, " in ",
      Round[AbsoluteTime[] - secStart, 0.1], " s"]],
   {k, 2, nb}];
  <|"A" -> a, "S" -> s, "PerSector" -> perSector,
    "Status" -> If[failed, "Incomplete", "OK"]|>];

(* ---------------- run the cleanup ---------------- *)

cleanupNotes = <||>;
If[status === "NeedsCleanup",
  Module[{a = {ax0, ay0}, s = IdentityMatrix[n], r},

   (* M1 *)
   t0 = AbsoluteTime[];
   r = epsLocusStrip[a, s];
   a = r["A"]; s = r["S"];
   cleanupNotes["M1"] = KeyDrop[r, {"A", "S"}];
   If[r["Applied"] > 0, AppendTo[mechanisms, "EpsLocusStrip"]];
   phase["M1_STRIP", AbsoluteTime[] - t0, "status=", r["Status"], " steps=",
     r["Applied"], " loci=", r["Loci"], " remaining=", r["Remaining"]];
   If[r["Applied"] > 0, putAtomic[<|"S" -> s, "A" -> a|>, stateFile["m1_strip"]]];

   (* M2 *)
   t0 = AbsoluteTime[];
   r = fuchsReduce[a, s, 120, 1800];
   a = r["A"]; s = r["S"];
   cleanupNotes["M2"] = KeyDrop[r, {"A", "S"}];
   If[r["Steps"] > 0, AppendTo[mechanisms, "FuchsPoleReduction"]];
   phase["M2_FUCHS", AbsoluteTime[] - t0, "steps=", r["Steps"],
     " passes=", Lookup[r, "Passes", "-"],
     " note=", Lookup[r, "Note", "-"],
     " cycles=", Lookup[r, "Cycles", "-"],
     " poleContent=", Lookup[r, "TotalPoleContent", "-"],
     " maxOffDiagPole=", Lookup[r, "MaxOffDiagonalPole", "-"]];
   If[r["Steps"] > 0, putAtomic[<|"S" -> s, "A" -> a|>, stateFile["m2_fuchs"]]];

   (* M3 (only if the whole connection is dlog already) *)
   t0 = AbsoluteTime[];
   Module[{dt = dlogTest[a]},
    cleanupNotes["DlogTestBeforeM3"] = KeyDrop[dt, "Letters"];
    If[TrueQ[dt["Dlog"]],
      r = dlogToEpsForm[a, s];
      If[r["Status"] === "OK", a = r["A"]; s = r["S"];
        AppendTo[mechanisms, "DlogToEpsForm"]];
      cleanupNotes["M3"] = KeyDrop[r, {"A", "S", "U"}];
      phase["M3_DLOGEPS", AbsoluteTime[] - t0, "dlog=True status=", r["Status"],
        " UfreeOfXY=", Lookup[r, "UFreeOfXY", "-"]],
      cleanupNotes["M3"] = <|"Status" -> "Skipped", "Reason" -> Lookup[dt, "Reason", "notDlog"]|>;
      phase["M3_DLOGEPS", AbsoluteTime[] - t0, "dlog=False skipped reason=",
        Lookup[dt, "Reason", "residues not (x,y)-free"]]]];

   (* interim gate: M1+M2+M3 may already be enough *)
   t0 = AbsoluteTime[];
   gateResult = runGate[s, "afterM3"];
   phase["GATE1", AbsoluteTime[] - t0, "verdict=",
     If[gateResult["Verdict"], "PASSED", "FAILED"]];

   (* M4 *)
   If[! gateResult["Verdict"],
    t0 = AbsoluteTime[];
    r = canonicaOffDiagonal[a, s, canonicaBudget];
    a = r["A"]; s = r["S"];
    cleanupNotes["M4"] = KeyDrop[r, {"A", "S"}];
    AppendTo[mechanisms, "CanonicaOffDiagonal"];
    phase["M4_CANONICA", AbsoluteTime[] - t0, "status=", r["Status"],
      " sectors=", Normal[r["PerSector"]]];
    putAtomic[<|"S" -> s, "A" -> a|>, stateFile["m4_canonica"]];

    (* the eps-only finish after the recursion *)
    t0 = AbsoluteTime[];
    Module[{dt = dlogTest[a]},
     If[TrueQ[dt["Dlog"]] && ! TrueQ[dt["EpsFactored"]],
       r = dlogToEpsForm[a, s];
       If[r["Status"] === "OK", a = r["A"]; s = r["S"];
         AppendTo[mechanisms, "DlogToEpsForm"]];
       cleanupNotes["M5"] = KeyDrop[r, {"A", "S", "U"}];
       phase["M5_DLOGEPS", AbsoluteTime[] - t0, "status=", r["Status"]],
       cleanupNotes["M5"] = <|"Status" -> "Skipped"|>;
       phase["M5_DLOGEPS", AbsoluteTime[] - t0, "skipped dlog=", dt["Dlog"],
         " epsFactored=", Lookup[dt, "EpsFactored", "-"]]]];

    t0 = AbsoluteTime[];
    gateResult = runGate[s, "final"];
    phase["GATE2", AbsoluteTime[] - t0, "verdict=",
      If[gateResult["Verdict"], "PASSED", "FAILED"]]];

   (* a failure must be CLASSIFIED, not just reported *)
   If[! gateResult["Verdict"],
    t0 = AbsoluteTime[];
    Module[{ob = obstruction[a]},
     cleanupNotes["Obstruction"] = ob;
     phase["OBSTRUCTION", AbsoluteTime[] - t0, "classes=", ob["Classes"],
       " pairs=", Table[{p["I"], p["J"],
          If[p["HigherPoles"] =!= {}, "poles" <> ToString[Length[p["HigherPoles"]]], ""],
          If[p["ResidueNotXYFree"] =!= {}, "resXY", ""],
          If[p["NonDlogRemainder"] =!= {},
             "entire" <> ToString[Table[q["RemainderIsPolynomial"],
                {q, p["NonDlogRemainder"]}]], ""]}, {p, ob["Pairs"]}]]]];

   status = If[gateResult["Verdict"], "CleanedUp", "GateFailed"];
   Clear[a]]];

(* ------------------------------------------------------------------ *)
(*  (5) the record                                                      *)
(* ------------------------------------------------------------------ *)

t0 = AbsoluteTime[];
recordFile = FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}];
record = <|
  "Family" -> family,
  "Status" -> status,
  "GateVerdict" -> gateResult["Verdict"],
  "Frame" -> frame,
  "Chart" -> If[frame === "Chart", "v = x y, w = (1-x)(1-y)", "source (v,w)"],
  "Variables" -> vars,
  "Regulator" -> ee,
  "Dim" -> n, "BlockDims" -> dims,
  "Ranges" -> ranges, "Blocks" -> asm["Blocks"], "Classes" -> classes,
  (* Perm[[k]] is the ORIGINAL row carried by permuted index k, so
     A0 = de-connection[[Perm, Perm]] and I = TTotal . F in this basis.
     It equals Flatten[Blocks] (MasterTransport.wl:1261) and is stored so
     that no consumer has to re-derive it. *)
  "Perm" -> Lookup[asm, "Perm", Flatten[asm["Blocks"]]],
  (* the eps-Laurent window of T_total: I = TTotal . F at eps^n needs F at
     eps^(n - min), so the sweep must carry F to N - min and regrade *)
  "TTotalEpsOrders" -> Module[{o = DeleteCases[
      Flatten[Map[epsOrderOf, gateResult["TTotal"], {2}]], Infinity]},
    If[o === {}, {0, 0}, {Min[o], Max[o]}]],
  "BasePoint" -> basePoint, "Target" -> targetPoint,
  "S" -> gateResult["S"], "SInverse" -> gateResult["SInverse"],
  "TBlockDiagonal" -> gateResult["TBlockDiagonal"],
  "TTotal" -> gateResult["TTotal"], "TTotalInverse" -> gateResult["TTotalInverse"],
  "EpsFormX" -> gateResult["EpsFormX"], "EpsFormY" -> gateResult["EpsFormY"],
  "Letters" -> gateResult["Letters"], "Residues" -> gateResult["Residues"],
  "Purity" -> purity,
  "Gate" -> gateResult["Gate"],
  "Mechanisms" -> mechanisms,
  "Cleanup" -> cleanupNotes,
  "Timings" -> phaseTimes,
  "TotalSeconds" -> Round[AbsoluteTime[] - start, 0.1],
  "Statement" -> "family eps-form of " <> family <> " in the " <>
    If[frame === "Chart", "chart v = x y, w = (1-x)(1-y)", "source (v,w) frame"] <>
    ": the ORIGINAL (permuted) connections pushed through T_total = diag(T_i) . S \
equal eps Sum_a R_a dlog phi_a with constant R_a and eps-free letters, checked \
entrywise and exactly in BOTH variables; EpsFormX/EpsFormY are written in the \
frame's own variables (see \"Variables\")",
  "Provenance" -> <|
    "Driver" -> "Scripts/family_epsform.wls",
    "Arguments" -> argv,
    "SchemaBaseline" -> "HardClasses/EpsFormRoute/family_epsform_CF230.wl (extended)",
    "AssemblyRoute" -> If[frame === "Chart", "TransportFamilyInChart", "TransportFamily"],
    "AssemblyCertificateOK" -> certOK,
    "WolframVersion" -> $Version,
    "Date" -> DateString[]|>|>;
putAtomic[record, recordFile];

(* payoff view: Scripts/HardClasses/epsform_offdiag_cf230_payoff.wls reads the record's
   Ranges / EpsFormX / EpsFormY / Letters and transports in {x, y}.  For a
   family whose frame is the source (v,w) the same record is written once
   more with v -> x, w -> y (a pure renaming of two free symbols) so the
   payoff smoke test runs unchanged. *)
payoffFile = recordFile;
If[frame =!= "Chart",
  payoffFile = FileNameJoin[{outdir, "family_epsform_" <> family <> "_xyview.wl"}];
  putAtomic[Join[
    KeyTake[record, {"Family", "Status", "Frame", "Dim", "BlockDims", "Ranges",
      "Blocks", "Classes"}],
    <|"Variables" -> {xx, yy}, "VariableMap" -> {xx -> vv, yy -> ww},
      "EpsFormX" -> (record["EpsFormX"] /. {vv -> xx, ww -> yy}),
      "EpsFormY" -> (record["EpsFormY"] /. {vv -> xx, ww -> yy}),
      "Letters" -> (record["Letters"] /. {vv -> xx, ww -> yy}),
      "Note" -> "renaming of family_epsform_" <> family <> ".wl for the payoff \
driver, which transports in {x, y}; x := v, y := w"|>], payoffFile]];

phase["WRITE", AbsoluteTime[] - t0, "record=", recordFile,
  " bytes=", FileByteCount[recordFile],
  If[payoffFile === recordFile, "", " payoffView=" <> payoffFile]];

Print[tag, " RESULT family=", family, " frame=", frame, " dim=", n,
  " blocks=", nb, " status=", status,
  " gate=", If[gateResult["Verdict"], "PASSED", "FAILED"],
  " nonPureCouplings=", purity["NumberOfNonPureCouplingPairs"],
  " mechanisms=", mechanisms,
  " letters=", Length[gateResult["Letters"]],
  " total=", Round[AbsoluteTime[] - start, 0.1], "s"];

Clear[ahatPath, purityPath, purityX, purityY, gateResult, record, asm, cached];
"family_epsform " <> family <> " " <> status
