#!/usr/bin/env wolframscript
(* Off-diagonal eps-factorization of CF230 in the chart v = x y,
   w = (1-x)(1-y): STEP 0, the structural probe.

   Question decided here (cheap, before any package is run):

   The assembled canonical connection Ahat = T^-1 A T - T^-1 dT with T
   block diagonal has couplings with an eps-DEPENDENT apparent locus
   q(x,y,eps) = -2 eps - 3(1+eps)(x+y) + (6+8eps) x y  (measured earlier
   in blockwise_class49_locus_CF230.wl as a factor of det T_6).

   A block-unipotent strip S = 1 + N (N strictly block lower triangular,
   identity diagonal blocks) obeys, at block distance 1,

       d N_ij - eps E_i N_ij + eps N_ij E_j = Ahat_ij - Ahat'_ij .

   If N_ij had a pole of order k >= 1 at q = 0 the left side would carry
   a pole of order k+1 (from -k N dq/q^{k+1}), which nothing on the right
   can match; hence N_ij is REGULAR at q = 0, hence the left side is, and
   hence Ahat_ij - Ahat'_ij must be too.  Ahat'_ij is eps-free-letter dlog
   by definition.  So a unipotent strip can only work if Ahat_ij has NO
   pole at the eps-dependent locus.

   Equivalently, by the exact identity dlog det T_i = tr A_ii - tr Ahat_ii
   (trace of T^-1 dT), an eps-dependent factor of det T_i must already be
   present in the ORIGINAL chart system's diagonal block trace.  This
   script measures both sides:

     (a) the eps-dependent irreducible denominator factors of the
         ORIGINAL permuted chart connections (assembly Av/Aw), per block
         pair;
     (b) the same for the conjugated connections (assembly Apv/Apw);
     (c) det T_i and its eps-dependent factors, per block;
     (d) the identity dlog det T_6 = tr A_66 - tr Ahat_66 in both
         variables (exact zero test).

   It also SAVES the assembly (Apv, Apw, Av, Aw, Ranges, per-block T and
   TInverse) so that later steps never have to re-assemble.

   Usage: epsform_offdiag_cf230_probe.wls [FAMILY] [OUTDIR]                *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
If[Length[argv] >= 2, outdir = argv[[2]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];

start = AbsoluteTime[];
log[a___] := Print["[probe +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

Quiet[Clear["Global`tau"]];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];

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

(* --- the raw (v,w) system's eps-dependent denominators, before any
       chart or conjugation: this is the cleanest statement of where an
       eps-dependent locus can come from at all --- *)
epsDenFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e], d},
     If[TrueQ[t === 0], {},
       d = Denominator[t];
       Select[FactorList[d][[All, 1]], ! FreeQ[#, ee] &]]]],
   m, {2}]]];

log["raw (v,w) system: eps-dependent denominator factors of Av: ",
  epsDenFactors[de["Av"]]];
log["raw (v,w) system: eps-dependent denominator factors of Aw: ",
  epsDenFactors[de["Aw"]]];

log["assembling in the chart (MaxWeight -> 0: no transport)"];
{asmSeconds, r} = AbsoluteTiming[FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
   <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
     "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
   chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
   "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
   "PhysicalValuation" -> 0, "Orders" -> {0, 1},
   "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
log["assembly status ", Lookup[r, "Status", "?"], " in ", Round[asmSeconds, 0.1], " s"];

If[! (AssociationQ[r] && KeyExistsQ[r, "Assembly"] &&
      AssociationQ[r["Assembly"]] && r["Assembly"]["Status"] === "OK"),
  log["!! no usable assembly; keys ", Keys[r]]; Exit[1]];

assembly = r["Assembly"];
ranges = assembly["Ranges"];
nb = Length[ranges];
dims = Length /@ ranges;
classes = blocks[[All, 2]];
log["blocks ", nb, " dims ", dims, " classes ", classes];
log["five-part assembly certificate: ",
  TrueQ[FeynFacet`Private`masterTransportCertificateOK[assembly]]];

ax = assembly["Apv"]; ay = assembly["Apw"];      (* conjugated, in (x,y) *)
a0x = assembly["Av"];  a0y = assembly["Aw"];      (* original permuted, in (x,y) *)
tt = Table[assembly["Forms"][[i]]["T"], {i, nb}];
ti = assembly["TInverse"];

(* ---------------- (a) original chart system ---------------- *)
log["---- (a) ORIGINAL chart connections: eps-dependent denominator factors per block pair"];
Do[If[i >= j,
   Module[{fx, fy},
     fx = epsDenFactors[a0x[[ranges[[i]], ranges[[j]]]]];
     fy = epsDenFactors[a0y[[ranges[[i]], ranges[[j]]]]];
     If[fx =!= {} || fy =!= {},
       log["  A0[", i, ",", j, "]  x: ", fx, "   y: ", fy]]]],
  {i, nb}, {j, nb}];
log["  (nothing printed above = every original coupling has eps-free denominators)"];

(* ---------------- (b) conjugated ---------------- *)
log["---- (b) CONJUGATED connections Ahat: eps-dependent denominator factors per block pair"];
Do[If[i >= j,
   Module[{fx, fy},
     fx = epsDenFactors[ax[[ranges[[i]], ranges[[j]]]]];
     fy = epsDenFactors[ay[[ranges[[i]], ranges[[j]]]]];
     If[fx =!= {} || fy =!= {},
       log["  Ahat[", i, ",", j, "]  x: ", fx, "   y: ", fy]]]],
  {i, nb}, {j, nb}];

(* ---------------- (c) det T ---------------- *)
log["---- (c) det T per block"];
dets = Table[Together[Det[tt[[i]]]], {i, nb}];
Do[log["  block ", i, " (class ", classes[[i]], "): det T factors = ",
   FactorList[Numerator[dets[[i]]]][[All, 1]], " / ",
   FactorList[Denominator[dets[[i]]]][[All, 1]]], {i, nb}];

(* ---------------- (d) the trace identity ---------------- *)
log["---- (d) exact identity dlog det T_i = tr A0_ii - tr Ahat_ii (both variables)"];
Do[Module[{ld, rx, ry},
   ld = dets[[i]];
   rx = Together[D[ld, xx]/ld - (Tr[a0x[[ranges[[i]], ranges[[i]]]]] -
        Tr[ax[[ranges[[i]], ranges[[i]]]]])];
   ry = Together[D[ld, yy]/ld - (Tr[a0y[[ranges[[i]], ranges[[i]]]]] -
        Tr[ay[[ranges[[i]], ranges[[i]]]]])];
   log["  block ", i, ": residual x = ", rx, "   residual y = ", ry]],
  {i, nb}];

(* ---------------- save ---------------- *)
out = <|"Family" -> family, "Ranges" -> ranges, "Dims" -> dims,
  "Classes" -> classes, "Blocks" -> blocks[[All, 1]],
  "Ax" -> ax, "Ay" -> ay, "A0x" -> a0x, "A0y" -> a0y,
  "T" -> tt, "TInverse" -> ti,
  "Ev" -> Table[assembly["Forms"][[i]]["Ev"], {i, nb}],
  "Ew" -> Table[assembly["Forms"][[i]]["Ew"], {i, nb}],
  "CertificateOK" -> TrueQ[FeynFacet`Private`masterTransportCertificateOK[assembly]],
  "Date" -> DateString[]|>;
tmp = FileNameJoin[{outdir, "assembly_" <> family <> ".wl.tmp"}];
Put[out, tmp];
RenameFile[tmp, FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}], OverwriteTarget -> True];
log["saved assembly to ", FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]];
log["DONE"];
