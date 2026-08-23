#!/usr/bin/env wolframscript
(* S1 (measure, no engine): the EXACT structure of every coupling block
   Ahat_ij of a family in the chart, along the axis-aligned path the
   chart layer uses.

   The block-wise engine's integration step is a WORD APPEND, and that is
   licensed only if every entry of every eps-Laurent coefficient of every
   coupling is

       sum_a  c_a / (tau - a)      c_a free of tau, a free of tau,

   i.e. pure dlog with constant (tau-free) residues, no higher poles and
   no polynomial part.  Both reviews flag this as an UNPROVEN assumption.
   This script measures it: partial-fraction each entry in tau at each
   eps-Laurent order and report, per (i,j) and per order,

     - the maximum pole order in tau,
     - the degree of the polynomial part (None if absent),
     - whether every partial-fraction numerator is free of tau,
     - whether the letters (pole positions) are free of eps,
     - the letters themselves.

   Nothing is transported here: MaxWeight -> 0 makes
   TransportFamilyInChart stop at DepthExceedsCap and hand back the
   assembly record (Apv/Apw = the conjugated chart connections, Ranges,
   Forms), which is all this measurement needs.

   Usage:  blockwise_structure.wls FAMILY [KEXTRA] [OUTDIR]
     FAMILY  CF230 (default) or CF258
     KEXTRA  how many eps orders above the lowest one to classify (4)
     OUTDIR  where the record is written (default: the session
             scratchpad; the measured record is MOVED into
             Results/.../EpsFormRoute/ once it is the evidence of a
             reported result). *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
scratch = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_blockwise";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
kExtra = If[Length[argv] >= 2, ToExpression[argv[[2]]], 4];
If[Length[argv] >= 3, scratch = argv[[3]]];
If[! DirectoryQ[scratch], CreateDirectory[scratch]];

start = AbsoluteTime[];
(* Print, not WriteString["stdout"]: inside a KernelPool mission $Output
   is the mission's own log file and a literal "stdout" write would land
   in the pool log instead. *)
log[a___] := Print["[s1 +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
ee = Symbol["Global`eps"];
(* NOT "tau = Symbol[\"Global`tau\"]": this script evaluates at Global`
   context, so that line reads Global`tau = Global`tau and gives the symbol
   an OWN VALUE -- which TransportFamily then refuses as a path parameter,
   correctly (MasterTransport::pathparameter).  Measured here on
   2026-08-16.  Subkernels of the pool keep state between missions, so the
   symbol is cleared first as well. *)
Quiet[Clear["Global`tau"]];
tauSym = Symbol["Global`tau"];

(* trap: normalize every artifact by SymbolName before use *)
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] &&
   Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);
normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];

assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
familyBlocks[f_] := Table[{a["Rows"], a["ClassID"]},
  {a, Select[assignments, #["Family"] === f &]}];

chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
blocks = familyBlocks[family];
log[family, ": ", Length[de["Av"]], " masters, ", Length[blocks], " blocks"];

log["assembling in the chart (MaxWeight -> 0: no transport)"];
{assembleSeconds, r} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
   <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
     "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
   chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
   "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
   "PhysicalValuation" -> 0, "Orders" -> {0, 1},
   "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> True]];
log["assembly status ", Lookup[r, "Status", "?"], " in ",
  Round[assembleSeconds, 0.1], " s"];

If[! (AssociationQ[r] && KeyExistsQ[r, "Assembly"] &&
      AssociationQ[r["Assembly"]] && r["Assembly"]["Status"] === "OK"),
  log["!! no usable assembly; keys ", Keys[r]];
  Export[FileNameJoin[{scratch, "blockwise_structure_" <> family <> "_FAILED.txt"}],
    ToString[Lookup[r, "Status", "?"]], "Text"];
  Exit[1]];

assembly = r["Assembly"];
ranges = assembly["Ranges"];
nb = Length[ranges];
dims = Length /@ ranges;
classes = blocks[[All, 2]];
log["blocks ", nb, " dims ", dims];

(* the certificate must hold before any structure claim is worth making *)
certOK = TrueQ[FeynFacet`Private`masterTransportCertificateOK[assembly]];
log["five-part assembly certificate: ", certOK];

(* the same axis-aligned path the chart layer builds: base {1/2, y},
   target {x, y}, direction "First" *)
base = {1/2, yy};
target = {xx, yy};
log["path: base ", base, " target ", target, " (axis-aligned in x)"];

{ahatSeconds, ahat} = AbsoluteTiming[
   FeynFacet`Private`masterTransportPathMatrix[assembly["Apv"], assembly["Apw"],
     target, base, tauSym, {xx, yy}]];
log["path connection built in ", Round[ahatSeconds, 0.1], " s, leaves ",
  LeafCount[ahat]];

monic = FeynFacet`Private`masterTransportMonicCheck[ahat, tauSym];
log["monic check: all denominators linear in tau = ", monic["Linear"],
  " (", Length[monic["Denominators"]], " distinct denominators)"];

(* ---------------------------------------------------------------- *)
(*  the classification of ONE entry at ONE eps order                  *)
(* ---------------------------------------------------------------- *)

(* Apart in tau, then read off the exact structure of each term. *)
classifyEntry[e_] := Module[{t, ap, terms, poles, poly, out},
  t = Together[e];
  If[TrueQ[t === 0], Return[<|"Zero" -> True, "MaxPole" -> 0,
    "PolyDegree" -> None, "NumeratorsTauFree" -> True, "Letters" -> {}|>]];
  ap = Apart[t, tauSym];
  terms = If[Head[ap] === Plus, List @@ ap, {ap}];
  poles = {}; poly = {};
  Do[
    Module[{tt = Together[term], num, den, k, letter},
      num = Numerator[tt]; den = Denominator[tt];
      If[FreeQ[den, tauSym],
        AppendTo[poly, Exponent[num, tauSym]],
        (* den = c (tau - a)^k with a free of tau: k is the pole order and
           the letter is the root, taken from the LINEAR factor rather
           than from Solve so that a k-fold pole gives one letter *)
        k = Exponent[den, tauSym];
        letter = Module[{fl, lin},
          fl = FactorList[den][[All, 1]];
          lin = Select[fl, ! FreeQ[#, tauSym] &];
          If[Length[lin] === 1 && Exponent[First[lin], tauSym] === 1,
            Together[-Coefficient[First[lin], tauSym, 0]/
              Coefficient[First[lin], tauSym, 1]],
            "NotASinglePowerOfALinearFactor"]];
        AppendTo[poles, <|"Order" -> k, "Letter" -> letter,
          "NumeratorTauFree" -> FreeQ[num, tauSym]|>]]],
    {term, terms}];
  out = <|
    "Zero" -> False,
    "MaxPole" -> If[poles === {}, 0, Max[poles[[All, "Order"]]]],
    "PolyDegree" -> If[poly === {}, None, Max[poly]],
    "NumeratorsTauFree" -> AllTrue[poles, TrueQ[#["NumeratorTauFree"]] &],
    "Letters" -> DeleteDuplicates[poles[[All, "Letter"]]]|>;
  out];

(* Laurent coefficients of a rational function of eps over a window *)
laurent[e_, {r0_, r1_}] :=
  FeynFacet`Private`masterTransportLaurentList[e, {r0, r1}, ee];

epsOrder[e_] := FeynFacet`Private`masterTransportEpsOrder[e, ee];

(* ---------------------------------------------------------------- *)
(*  per block pair                                                    *)
(* ---------------------------------------------------------------- *)

records = {};
Do[
  If[i >= j,
    Module[{sub, ords, r0, r1, perOrder, entries, polyQ, nonzero},
      sub = ahat[[ranges[[i]], ranges[[j]]]];
      entries = Flatten[sub];
      nonzero = Select[entries, ! TrueQ[Together[#] === 0] &];
      If[nonzero === {},
        AppendTo[records, <|"I" -> i, "J" -> j, "Zero" -> True|>],
        ords = epsOrder /@ nonzero;
        r0 = Min[ords];
        r1 = r0 + kExtra;
        (* is the block polynomial in eps?  then the Laurent tower is
           finite and r1 can be pinned exactly *)
        polyQ = AllTrue[nonzero,
          PolynomialQ[Together[#] ee^Max[0, -r0], ee] &];
        perOrder = Table[
          Module[{coeffs, classified},
            coeffs = Map[laurent[#, {rr, rr}] &, sub, {2}];
            coeffs = Map[If[# === $Failed, $Failed, First[#]] &, coeffs, {2}];
            If[! FreeQ[coeffs, $Failed],
              <|"Order" -> rr, "Status" -> "LaurentFailed"|>,
              classified = Map[classifyEntry, coeffs, {2}];
              <|"Order" -> rr,
                "Status" -> "OK",
                "AllZero" -> AllTrue[Flatten[classified], TrueQ[#["Zero"]] &],
                "MaxPole" -> Max[Append[
                   Table[c["MaxPole"], {c, Flatten[classified]}], 0]],
                "PolyDegrees" -> DeleteDuplicates[DeleteCases[
                   Table[c["PolyDegree"], {c, Flatten[classified]}], None]],
                "NumeratorsTauFree" -> AllTrue[Flatten[classified],
                   TrueQ[#["NumeratorsTauFree"]] &],
                "Letters" -> DeleteDuplicates[
                   Flatten[Table[c["Letters"], {c, Flatten[classified]}]]]|>]],
          {rr, r0, r1}];
        AppendTo[records, <|"I" -> i, "J" -> j, "Zero" -> False,
          "Dims" -> {dims[[i]], dims[[j]]},
          "Classes" -> {classes[[i]], classes[[j]]},
          "RMin" -> r0, "Window" -> {r0, r1},
          "PolynomialInEps" -> polyQ,
          "PerOrder" -> perOrder|>];
        log["  (", i, ",", j, ") dim ", dims[[i]], "x", dims[[j]],
          " rmin ", r0, " polyInEps ", polyQ,
          " maxPole ", Max[Table[Lookup[p, "MaxPole", 0], {p, perOrder}]],
          " polyPart ", DeleteDuplicates[Flatten[
             Table[Lookup[p, "PolyDegrees", {}], {p, perOrder}]]],
          " letters ", Length[DeleteDuplicates[Flatten[
             Table[Lookup[p, "Letters", {}], {p, perOrder}]]]]]]]],
  {i, nb}, {j, nb}];

(* ---------------------------------------------------------------- *)
(*  verdicts                                                          *)
(* ---------------------------------------------------------------- *)

live = Select[records, ! TrueQ[#["Zero"]] &];
allOrders = Flatten[Table[rec["PerOrder"], {rec, live}], 1];
allOrders = Select[allOrders, #["Status"] === "OK" && ! TrueQ[#["AllZero"]] &];

maxPoleAll = Max[Append[Table[p["MaxPole"], {p, allOrders}], 0]];
polyPartsAll = DeleteDuplicates[Flatten[Table[p["PolyDegrees"], {p, allOrders}]]];
numeratorsOK = AllTrue[allOrders, TrueQ[#["NumeratorsTauFree"]] &];
lettersAll = DeleteDuplicates[Flatten[Table[p["Letters"], {p, allOrders}]]];
lettersEpsFree = FreeQ[lettersAll, ee];
lettersTauFree = FreeQ[lettersAll, tauSym];

diagonalRecords = Select[live, #["I"] === #["J"] &];
offRecords = Select[live, #["I"] =!= #["J"] &];

verdict = <|
  "Family" -> family,
  "Blocks" -> nb, "Dims" -> dims, "Classes" -> classes,
  "AssemblyCertificateOK" -> certOK,
  "MonicLinear" -> monic["Linear"],
  "Path" -> <|"Base" -> base, "Target" -> target, "Parameter" -> tauSym,
     "Direction" -> "First(axis-aligned in x)"|>,
  "MaxPoleOrderInTau" -> maxPoleAll,
  "PolynomialPartDegrees" -> polyPartsAll,
  "PartialFractionNumeratorsTauFree" -> numeratorsOK,
  "LettersEpsFree" -> lettersEpsFree,
  "LettersTauFree" -> lettersTauFree,
  "DistinctLetters" -> Length[lettersAll],
  "Letters" -> lettersAll,
  "PureDlogConstantResidues" ->
    (maxPoleAll <= 1 && polyPartsAll === {} && numeratorsOK &&
     lettersEpsFree && lettersTauFree),
  "DiagonalRMin" -> Table[{rec["I"], rec["RMin"]}, {rec, diagonalRecords}],
  "OffDiagonalRMin" -> Table[{rec["I"], rec["J"], rec["RMin"]}, {rec, offRecords}],
  "CouplingsPolynomialInEps" ->
    Table[{rec["I"], rec["J"], rec["PolynomialInEps"]}, {rec, offRecords}],
  "Records" -> records,
  "Seconds" -> AbsoluteTime[] - start|>;

log["==== VERDICT (", family, ") ===="];
log["  max pole order in tau over all couplings and orders: ", maxPoleAll,
  "   (acceptance for the word-append integration: 1)"];
log["  polynomial parts in tau: ",
  If[polyPartsAll === {}, "NONE", polyPartsAll],
  "   (acceptance: NONE)"];
log["  partial-fraction numerators free of tau: ", numeratorsOK];
log["  letters free of eps: ", lettersEpsFree, ", free of tau: ", lettersTauFree];
log["  distinct letters: ", Length[lettersAll]];
log["  PURE DLOG WITH CONSTANT RESIDUES: ", verdict["PureDlogConstantResidues"]];

FeynFacet`Private`masterTransportPutAtomic[verdict,
  FileNameJoin[{scratch, "blockwise_structure_" <> family <> ".wl"}]];
log["written ", FileNameJoin[{scratch, "blockwise_structure_" <> family <> ".wl"}]];

(* the assembly is expensive; keep it for S2/S4 so nothing is recomputed *)
FeynFacet`Private`masterTransportPutAtomic[
  <|"Family" -> family, "Assembly" -> assembly, "Base" -> base,
    "Target" -> target, "Blocks" -> blocks,
    "Chart" -> Lookup[r, "Chart", None]|>,
  FileNameJoin[{scratch, "assembly_" <> family <> ".wl"}]];
log["assembly cached (", Round[ByteCount[assembly]/1024.^2, 0.1], " MB)"];
log["DONE"];
