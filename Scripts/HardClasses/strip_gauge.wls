#!/usr/bin/env wolframscript
(* E2 (decision memo 2026-08-17): STRIP PURIFICATION by the eps-graded
   exactness solve — Fable Max's prescription, the same equation Codex
   attributes to Lee/CANONICA, implemented directly.

   Setting: the assembled family connection A = (Ax, Ay) is block
   LOWER-triangular; every diagonal block is a certified eps-form
   Delta_i = eps delta_i (delta eps-free dlog with constant residues);
   the strips B_ij carry eps-deformed apparent loci which at fixed
   eps-order appear as HIGHER poles at eps-free polynomials plus
   polynomial parts (measured, S1).

   The gauge: T = 1 + D with D strictly block-lower.  At block distance
   d = i - j, exact conjugation touches distance-d strips ONLY through

       B' = B + eps delta_i D - eps D delta_j - dD            (exact),

   shorter strips not at all, longer strips through known products.  So
   one pass over increasing d, and within a strip one pass over
   increasing eps-order k:

       G_k := B_k + delta_i D_{k-1} - D_{k-1} delta_j,
       G_k  = Sum_a c_a dlog phi_a  +  dR_k     (c_a CONSTANT),
       D_k := R_k,   B'_k = the dlog part.

   The decomposition exists with constant c_a because G_k is closed
   (flatness, order by order — CHECKED, not assumed: the split is
   verified exactly in both variables for every entry and order; a
   nonconstant residue is a named tripwire, per the reviews a flatness/
   assembly bug and never a case for integration by parts).

   Output: a family eps-form record in the FamilyEpsForms schema
   (consumed by sweep route 2): TTotal = diag(T_i) . S, S = product of
   the distance gauges, EpsFormX/Y the purified connection, plus the
   exact gate: (i) gauge identity TTotal^-1 A_perm TTotal - TTotal^-1
   dTTotal == A' entrywise; (ii) every strip eps-coefficient in the
   window reconstructs as Sum c_a dlog phi_a with CONSTANT c_a, exactly;
   (iii) diagonal blocks unchanged; (iv) TTotal TTotal^-1 == 1 both
   ways; (v) flatness of A'.  GateVerdict True only if all five hold.

   Usage: strip_gauge.wls <family> <recordOutdir> [diagOutdir] [kPad]   *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]],
  Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]]];
clearGlobalSymbol[name_String] := ToExpression["Global`" <> name, InputForm,
  Function[symbol, Quiet[Unprotect[symbol]]; ClearAll[symbol], HoldAll]];
Scan[clearGlobalSymbol, {"tau", "s", "u", "p", "x", "y"}];

args = Rest[$ScriptCommandLine];
family = args[[1]];
outdir = args[[2]];
diagdir = If[Length[args] >= 3, args[[3]], outdir];
kPad = If[Length[args] >= 4, ToExpression[args[[4]]], 2];
Do[If[! DirectoryQ[d0], CreateDirectory[d0, CreateIntermediateDirectories -> True]],
  {d0, {outdir, diagdir}}];

start = AbsoluteTime[];
log[a___] := Print["[gauge ", family, " +", ToString[Round[AbsoluteTime[] - start]],
  "s] ", StringJoin[ToString /@ {a}]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
  "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}];
  expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]],
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
epsOrderOf = FeynFacet`Private`masterTransportEpsOrder;
laurentList = FeynFacet`Private`masterTransportLaurentList;

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];

(* ==================================================================== *)
(*  the entrywise decomposition  g = Sum c_a dlog f_a + dR              *)
(* ==================================================================== *)

(* One 1-form component pair (gx, gy) at a FIXED eps order (entries are
   eps-free).  Returns <|"OK", "C" -> <|f -> c|>, "R", "Reason"|>.
   Only x1-linear (and pure-x2) irreducible denominator factors are
   supported as letters; anything else that cannot be integrated
   rationally is a named refusal.  demandExact = True additionally
   requires R == 0 (the purity GATE reuses this code). *)
decomposeForm[gx_, gy_, x1_, x2_, demandExact_ : False] := Module[
  {tx, terms, cAssoc, R0, ok = True, reason = "", failure = None,
   hy, termsY, R1, resx, resy},
  cAssoc = <||>; R0 = 0;
  tx = Together[gx];
  If[! TrueQ[tx === 0],
    terms = If[Head[#] === Plus, List @@ #, {#}] &[Apart[tx, x1]];
    Do[
      Module[{tden, fs, f, m, q, alpha, c},
        tden = Denominator[Together[term]];
        fs = Select[First /@ FactorList[tden], ! FreeQ[#, x1] &];
        Which[
          fs === {},
            (* polynomial in x1 (coefficients rational in x2): primitive *)
            R0 = R0 + Integrate[Together[term], x1],
          Length[fs] === 1 && Exponent[First[fs], x1] === 1,
            f = First[fs];
            m = Exponent[tden, x1];   (* tden = f^m * (x1-free) *)
            alpha = Coefficient[f, x1, 1];
            q = Together[term f^m];   (* x1-free numerator over the x1-free rest *)
            If[! FreeQ[q, x1], ok = False; reason = "NumeratorNotReduced"; Break[]];
            If[m === 1,
              c = Together[q/alpha];
              If[FreeQ[c, x1] && FreeQ[c, x2] && FreeQ[c, ee],
                cAssoc[f] = Lookup[cAssoc, Key[f], 0] + c,
                ok = False;
                reason = "NonConstantResidue at " <> ToString[InputForm[f]];
                failure = <|"OK" -> False, "Reason" -> reason,
                  "Factor" -> f, "Residue" -> c,
                  "Component" -> "First"|>;
                Break[]],
              (* m >= 2: rational primitive *)
              R0 = R0 + Together[q f^(1 - m)/(alpha (1 - m))]],
          True,
            ok = False;
            reason = "UnsupportedDenominatorFactor " <>
              ToString[InputForm[fs]]; Break[]]],
      {term, terms}]];
  If[! ok, Return[If[AssociationQ[failure], failure,
    <|"OK" -> False, "Reason" -> reason|>]]];
  (* ---- the second component: what the x1-side already explains ------ *)
  hy = Together[gy - Sum[cAssoc[f] D[f, x2]/f, {f, Keys[cAssoc]}] - D[R0, x2]];
  If[! FreeQ[hy, x1],
    Return[<|"OK" -> False, "Reason" -> "ResidualDependsOnX1 (closedness violated)",
      "Residual" -> hy|>]];
  (* pure-x2 letters and the x2-primitive *)
  R1 = 0;
  If[! TrueQ[hy === 0],
    termsY = If[Head[#] === Plus, List @@ #, {#}] &[Apart[hy, x2]];
    Do[
      Module[{tden, fs, f, m, q, alpha, c},
        tden = Denominator[Together[term]];
        fs = Select[First /@ FactorList[tden], ! FreeQ[#, x2] &];
        Which[
          fs === {},
            R1 = R1 + Integrate[Together[term], x2],
          Length[fs] === 1 && Exponent[First[fs], x2] === 1,
            f = First[fs];
            m = Exponent[tden, x2];
            alpha = Coefficient[f, x2, 1];
            q = Together[term f^m];
            If[m === 1,
              c = Together[q/alpha];
              If[FreeQ[c, x2] && FreeQ[c, ee],
                cAssoc[f] = Lookup[cAssoc, Key[f], 0] + c,
                ok = False; reason = "NonConstantResidueY at " <> ToString[InputForm[f]];
                failure = <|"OK" -> False, "Reason" -> reason,
                  "Factor" -> f, "Residue" -> c,
                  "Component" -> "Second"|>;
                Break[]],
              R1 = R1 + Together[q f^(1 - m)/(alpha (1 - m))]],
          True,
            ok = False; reason = "UnsupportedYFactor " <> ToString[InputForm[fs]];
            Break[]]],
      {term, termsY}]];
  If[! ok, Return[If[AssociationQ[failure], failure,
    <|"OK" -> False, "Reason" -> reason|>]]];
  (* ---- exact final verification of the split ------------------------ *)
  resx = Together[gx - Sum[cAssoc[f] D[f, x1]/f, {f, Keys[cAssoc]}] - D[R0 + R1, x1]];
  resy = Together[gy - Sum[cAssoc[f] D[f, x2]/f, {f, Keys[cAssoc]}] - D[R0 + R1, x2]];
  If[! (TrueQ[resx === 0] && TrueQ[resy === 0]),
    Return[<|"OK" -> False, "Reason" -> "SplitDoesNotReconstruct",
      "ResidualX" -> resx, "ResidualY" -> resy|>]];
  If[demandExact && ! TrueQ[Together[R0 + R1] === 0],
    Return[<|"OK" -> False, "Reason" -> "ExactPartNonzero", "R" -> Together[R0 + R1]|>]];
  <|"OK" -> True, "C" -> cAssoc, "R" -> Together[R0 + R1]|>
];

(* ==================================================================== *)
(*  assemble                                                            *)
(* ==================================================================== *)

de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
valuations = readArtifact[FileNameJoin[{ftData, "MasterCoefficientValuations.wl"}]];
valuationOf = Association @ Table[{r["Family"], r["Indices"]} -> r["Valuation"], {r, valuations}];
canonical = Lookup[de, "CanonicalMasters", {}];
nMax = Max[Append[
  Table[Module[{val = Lookup[valuationOf, Key[{g[[1]], g[[2]]}], Missing[]]},
    If[IntegerQ[val], -val, Nothing]], {g, canonical}] /. Nothing -> Sequence[], 0]];
chart = FeynFacet`FamilyRootData[family];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"], "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
log["assembling, frame ", If[AssociationQ[chart], chart["Name"], "SourceVW"],
  ", demand nMax ", nMax];
rec = If[AssociationQ[chart],
  FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system, chart, "SourceVariables" -> {vv, ww},
    "Regulator" -> ee, "Blocks" -> blocks,
    "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False],
  FeynFacet`TransportFamily[system, "Variables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> blocks, "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
If[! (AssociationQ[rec] && KeyExistsQ[rec, "Assembly"] && AssociationQ[rec["Assembly"]] &&
      KeyExistsQ[rec["Assembly"], "Ranges"]),
  log["!! assembly failed: ", Lookup[rec, "Status", "?"]];
  putAtomic[<|"Family" -> family, "Status" -> "AssemblyFailed",
    "Reason" -> Lookup[rec, "Reason", Lookup[rec, "Status", "?"]]|>,
    FileNameJoin[{diagdir, "gauge_" <> family <> "_diag.wl"}]];
  Exit[1]];
assembly = rec["Assembly"];
{x1, x2} = If[AssociationQ[chart], chart["Variables"], {vv, ww}];
Ax = assembly["Apv"]; Ay = assembly["Apw"];
ranges = assembly["Ranges"]; nb = Length[ranges]; n = Length[Ax];
log["assembled ", n, "x", n, ", ", nb, " blocks"];

(* diagonals: delta_i, asserted eps-free *)
delta = Table[Map[Together[#/ee] &, {Ax[[ranges[[i]], ranges[[i]]]],
  Ay[[ranges[[i]], ranges[[i]]]]}, {3}], {i, nb}];
If[! FreeQ[delta, ee],
  log["!! a diagonal block is not an eps-form"]; Exit[1]];

(* eps window *)
kLow = Min[Append[DeleteCases[Flatten[Table[
  If[i > j, epsOrderOf[#, ee] & /@ Flatten[{Ax[[ranges[[i]], ranges[[j]]]],
    Ay[[ranges[[i]], ranges[[j]]]]}], {}], {i, nb}, {j, nb}]], Infinity], 0]];
kHigh = nMax + Max[0, -kLow] + kPad;
log["window: eps^", kLow, " .. eps^", kHigh];

(* ==================================================================== *)
(*  the distance loop                                                   *)
(* ==================================================================== *)

S = IdentityMatrix[n];
tripwire = None;
stripLog = {};
Do[
  Module[{Dfull, touched = {}},
    Dfull = ConstantArray[0, {n, n}];
    Do[
      If[i - j === dist && tripwire === None,
        Module[{ri = ranges[[i]], rj = ranges[[j]], Bx, By, zeroQ, BxK, ByK,
          Dprev, DK, t0 = AbsoluteTime[]},
          Bx = Ax[[ri, rj]]; By = Ay[[ri, rj]];
          zeroQ = AllTrue[Flatten[{Bx, By}], TrueQ[Together[#] === 0] &];
          If[! zeroQ,
            BxK = Table[Map[laurentList[#, {kLow, kHigh}, ee][[k - kLow + 1]] &,
              Bx, {2}], {k, kLow, kHigh}];
            ByK = Table[Map[laurentList[#, {kLow, kHigh}, ee][[k - kLow + 1]] &,
              By, {2}], {k, kLow, kHigh}];
            Dprev = ConstantArray[0, {Length[ri], Length[rj]}];
            DK = {};
            Do[
              Module[{Gx, Gy, Dk},
                Gx = Map[Together, BxK[[k - kLow + 1]] +
                  delta[[i, 1]] . Dprev - Dprev . delta[[j, 1]], {2}];
                Gy = Map[Together, ByK[[k - kLow + 1]] +
                  delta[[i, 2]] . Dprev - Dprev . delta[[j, 2]], {2}];
                Dk = ConstantArray[0, {Length[ri], Length[rj]}];
                Do[
                  Module[{split},
                    If[tripwire === None &&
                       ! (TrueQ[Together[Gx[[a, b]]] === 0] &&
                          TrueQ[Together[Gy[[a, b]]] === 0]),
                      split = decomposeForm[Gx[[a, b]], Gy[[a, b]], x1, x2];
                      If[TrueQ[split["OK"]],
                        Dk[[a, b]] = split["R"],
                        tripwire = <|"Strip" -> {i, j}, "Order" -> k,
                          "Entry" -> {a, b}, "Reason" -> split["Reason"],
                          "Detail" -> KeyDrop[split, {"OK"}]|>]]],
                  {a, Length[ri]}, {b, Length[rj]}];
                Dprev = Dk;
                AppendTo[DK, k -> Dk]],
              {k, kLow, kHigh}];
            If[tripwire === None,
              Dfull[[ri, rj]] = Sum[ee^First[kv] Last[kv], {kv, DK}];
              AppendTo[touched, {i, j}];
              AppendTo[stripLog, <|"Strip" -> {i, j},
                "Seconds" -> AbsoluteTime[] - t0,
                "DLeaves" -> LeafCount[Dfull[[ri, rj]]]|>];
              log["strip (", i, ",", j, ") purified in ",
                Round[AbsoluteTime[] - t0, 0.1], " s, D leaves ",
                LeafCount[Dfull[[ri, rj]]]]]]]],
      {i, nb}, {j, nb}];
    (* exact conjugation by T_d = 1 + Dfull (touches distance >= dist only) *)
    If[tripwire === None && touched =!= {},
      Module[{Td, TdInv, Dp, t0 = AbsoluteTime[]},
        Td = IdentityMatrix[n] + Dfull;
        TdInv = IdentityMatrix[n]; Dp = -Dfull;
        While[! AllTrue[Flatten[Dp], TrueQ[# === 0] &],
          TdInv = TdInv + Dp; Dp = Map[Together, -Dp . Dfull, {2}]];
        Ax = Map[Together, TdInv . Ax . Td - TdInv . D[Td, x1], {2}];
        Ay = Map[Together, TdInv . Ay . Td - TdInv . D[Td, x2], {2}];
        S = Map[Together, S . Td, {2}];
        log["distance ", dist, ": conjugated (", Length[touched], " strips) in ",
          Round[AbsoluteTime[] - t0, 0.1], " s"]]]],
  {dist, 1, nb - 1}];

If[tripwire =!= None,
  log["!! TRIPWIRE: ", ToString[Short[tripwire, 4]]];
  putAtomic[<|"Family" -> family, "Status" -> "Tripwire", "Tripwire" -> tripwire,
    "WallSeconds" -> AbsoluteTime[] - start, "Date" -> DateString[]|>,
    FileNameJoin[{diagdir, "gauge_" <> family <> "_diag.wl"}]];
  Exit[1]];

(* ==================================================================== *)
(*  THE GATE (all five parts exact)                                     *)
(* ==================================================================== *)

log["gate: (ii) strip purity through the window"];
purityOK = True; purityDetail = {};
Do[
  If[i > j && purityOK,
    Module[{ri = ranges[[i]], rj = ranges[[j]], Bx, By},
      Bx = Ax[[ri, rj]]; By = Ay[[ri, rj]];
      If[! AllTrue[Flatten[{Bx, By}], TrueQ[Together[#] === 0] &],
        Do[
          Module[{bx = Map[laurentList[#, {kLow, kHigh}, ee][[k - kLow + 1]] &, Bx, {2}],
                  by = Map[laurentList[#, {kLow, kHigh}, ee][[k - kLow + 1]] &, By, {2}]},
            Do[
              If[purityOK && ! (TrueQ[Together[bx[[a, b]]] === 0] &&
                                TrueQ[Together[by[[a, b]]] === 0]),
                Module[{split = decomposeForm[bx[[a, b]], by[[a, b]], x1, x2, True]},
                  If[! TrueQ[split["OK"]],
                    purityOK = False;
                    purityDetail = <|"Strip" -> {i, j}, "Order" -> k,
                      "Entry" -> {a, b}, "Reason" -> split["Reason"]|>]]],
              {a, Length[ri]}, {b, Length[rj]}]],
          {k, kLow, kHigh}]]]],
  {i, nb}, {j, nb}];
log["  purity: ", purityOK, If[purityOK, "", " " <> ToString[Short[purityDetail, 3]]]];

log["gate: (iii) diagonals unchanged (exact by triangularity; asserted)"];
diagOK = AllTrue[Flatten[Table[
  {Map[Together, Ax[[ranges[[i]], ranges[[i]]]] - ee delta[[i, 1]], {2}],
   Map[Together, Ay[[ranges[[i]], ranges[[i]]]] - ee delta[[i, 2]], {2}]},
  {i, nb}]], TrueQ[Together[#] === 0] &];
log["  diagonals: ", diagOK];

log["gate: (i)+(iv) TTotal gauge identity against the ORIGINAL permuted system"];
TblkFull = ConstantArray[0, {n, n}];
TblkInvFull = ConstantArray[0, {n, n}];
Do[
  TblkFull[[ranges[[i]], ranges[[i]]]] = assembly["Forms"][[i]]["T"];
  TblkInvFull[[ranges[[i]], ranges[[i]]]] =
    Lookup[assembly["Forms"][[i]], "TInverse",
      Inverse[assembly["Forms"][[i]]["T"]]],
  {i, nb}];
SInv = Module[{Ds = S - IdentityMatrix[n], acc = IdentityMatrix[n], Dp},
  Dp = -Ds;
  While[! AllTrue[Flatten[Dp], TrueQ[Together[#] === 0] &],
    acc = Map[Together, acc + Dp, {2}]; Dp = Map[Together, -Dp . Ds, {2}]];
  acc];
TTotal = Map[Together, TblkFull . S, {2}];
TTotalInv = Map[Together, SInv . TblkInvFull, {2}];
invOK = AllTrue[Flatten[Map[Together, TTotal . TTotalInv, {2}] - IdentityMatrix[n]],
    TrueQ[Together[#] === 0] &] &&
  AllTrue[Flatten[Map[Together, TTotalInv . TTotal, {2}] - IdentityMatrix[n]],
    TrueQ[Together[#] === 0] &];
log["  TTotal invertible both ways: ", invOK];
A0x = assembly["Av"]; A0y = assembly["Aw"];   (* original permuted, frame variables *)
gaugeOK = Module[{gx, gy},
  gx = Map[Together, TTotalInv . A0x . TTotal - TTotalInv . D[TTotal, x1] - Ax, {2}];
  gy = Map[Together, TTotalInv . A0y . TTotal - TTotalInv . D[TTotal, x2] - Ay, {2}];
  AllTrue[Flatten[{gx, gy}], TrueQ[Together[#] === 0] &]];
log["  gauge identity: ", gaugeOK];

log["gate: (v) flatness of the purified connection"];
flatOK = AllTrue[Flatten[Map[Together,
  D[Ax, x2] - D[Ay, x1] + Ax . Ay - Ay . Ax, {2}]], TrueQ[Together[#] === 0] &];
log["  flat: ", flatOK];

gate = purityOK && diagOK && invOK && gaugeOK && flatOK;
letters = DeleteDuplicates[Join[
  Flatten[Table[Select[First /@ Rest[FactorList[Denominator[Together[e]]]],
    (! FreeQ[#, x1] || ! FreeQ[#, x2]) && FreeQ[#, ee] &],
    {e, Flatten[{Ax, Ay}]}]]]];

record = <|
  "Family" -> family,
  "Status" -> If[gate, "CleanedUp", "GateFailed"],
  "GateVerdict" -> gate,
  "Method" -> "GradedStripPrimitive (E2, decision memo 2026-08-17)",
  "Frame" -> If[AssociationQ[chart], "Chart", "SourceVW"],
  "Chart" -> If[AssociationQ[chart], chart["Name"], "source (v,w)"],
  "Variables" -> {x1, x2}, "Regulator" -> ee,
  "Dim" -> n, "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "Classes" -> Table[Lookup[assembly["Forms"][[i]], "ClassID", None], {i, nb}],
  "TTotal" -> TTotal, "TTotalInverse" -> TTotalInv, "S" -> S,
  "EpsFormX" -> Ax, "EpsFormY" -> Ay,
  "Letters" -> letters, "Window" -> {kLow, kHigh},
  "Gate" -> <|"Purity" -> purityOK, "PurityDetail" -> purityDetail,
    "DiagonalsUnchanged" -> diagOK, "TTotalInvertible" -> invOK,
    "GaugeIdentity" -> gaugeOK, "Flat" -> flatOK|>,
  "StripLog" -> stripLog,
  "WallSeconds" -> AbsoluteTime[] - start, "Date" -> DateString[],
  "Provenance" -> "Scripts/HardClasses/strip_gauge.wls; graded exactness solve per strip \
per eps-order; every split verified exactly in both variables; purity gate \
re-derived on the final connection with the exact-part-zero demand"|>;
If[gate,
  putAtomic[record, FileNameJoin[{outdir, "family_epsform_" <> family <> ".wl"}]];
  log["GATE PASSED; record written to FamilyEpsForms"],
  putAtomic[record, FileNameJoin[{diagdir, "gauge_" <> family <> "_diag.wl"}]];
  log["GATE FAILED; diagnostic written"]];
log["DONE ", If[gate, "CleanedUp", "GateFailed"], " in ",
  Round[AbsoluteTime[] - start], " s"];
