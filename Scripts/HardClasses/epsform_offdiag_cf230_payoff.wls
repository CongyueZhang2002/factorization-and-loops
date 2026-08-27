#!/usr/bin/env wolframscript
(* THE PAYOFF TEST: block-wise transport of the family in the COMPLETED
   family eps-form.

   The block-wise engine's integration step is a word APPEND exactly when
   every coupling is pure dlog with constant residues in the path
   parameter.  Measured before this session (blockwise_structure_CF230.wl):
   5 of 18 nonzero coupling pairs of CF230 in the chart were NOT -- all of
   them issuing from block 6 -- with tau-poles up to order 3 and a
   polynomial part, and the integrator had to fall back on exact
   integration by parts (block 6 at eps^-2: 28 words, max coefficient
   leaves 7123, 151.1 s in bw_engine_cf230.log; the run was reported as
   75.5 s after the entry-wise-Apart refactor).

   Here the SAME family is transported with the SAME engine, the SAME
   chart, the SAME path and the SAME orders, but in the basis of the
   completed family eps-form: every block's transformation is the
   IDENTITY, every diagonal block is its eps-form, and every coupling is
   eps * (constant residue) * dlog(eps-free letter).

   Usage: epsform_offdiag_cf230_payoff.wls [FAMILY] [ORDERS] [FORMFILE] [OUTDIR] *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
orders = If[Length[argv] >= 2, ToExpression /@ StringSplit[argv[[2]], ","], {0, 1}];
formFile = If[Length[argv] >= 3, argv[[3]],
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
    "HardClasses", "EpsFormRoute", "family_epsform_" <> family <> ".wl"}]];
If[Length[argv] >= 4, outdir = argv[[4]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];

start = AbsoluteTime[];
log[a___] := Print["[payoff +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

(* the pool's subkernels keep state: an own value on Global`tau would make
   TransportFamily refuse the path parameter *)
Quiet[Clear["Global`tau"]];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);

If[! FileExistsQ[formFile], log["!! no family eps-form at ", formFile]; Exit[1]];
form = normalizeSymbols[Get[formFile]];
(* accepts either the gate artifact (EpsFormX/EpsFormY) or a raw pipeline
   state (A = {Ax, Ay}); the second is only for dry-running the transport
   API before the certified artifact exists *)
If[! KeyExistsQ[form, "EpsFormX"] && KeyExistsQ[form, "A"],
  form = Join[form, <|"EpsFormX" -> form["A"][[1]], "EpsFormY" -> form["A"][[2]],
    "Ranges" -> normalizeSymbols[Get[FileNameJoin[{outdir,
       "assembly_" <> family <> ".wl"}]]]["Ranges"], "Letters" -> {"(dry run)"}|>];
  log["DRY RUN: reading a pipeline state, not a certified family eps-form"]];
ranges = form["Ranges"]; nb = Length[ranges]; n = Length[form["EpsFormX"]];
ax = form["EpsFormX"]; ay = form["EpsFormY"];
log[family, ": family eps-form ", n, "x", n, ", ", nb, " blocks, orders ", orders];
log["  letters (", Length[form["Letters"]], "): ", form["Letters"]];

blocks = Table[{ranges[[i]],
   <|"Type" -> "EpsForm",
     "T" -> IdentityMatrix[Length[ranges[[i]]]],
     "TInverse" -> IdentityMatrix[Length[ranges[[i]]]],
     "Ev" -> ax[[ranges[[i]], ranges[[i]]]],
     "Ew" -> ay[[ranges[[i]], ranges[[i]]]]|>}, {i, nb}];

{seconds, result} = AbsoluteTiming[FeynFacet`TransportFamily[
   <|"Family" -> family <> "_epsform", "Av" -> ax, "Aw" -> ay|>,
   "Variables" -> {xx, yy}, "Regulator" -> ee,
   "Blocks" -> blocks, "FormDirectory" -> None,
   "PhysicalValuation" -> 0, "Orders" -> orders,
   "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
   "BasePoint" -> {1/2, yy}, "Target" -> {xx, yy},
   "MaxWeight" -> 14, "Verbose" -> True]];

log[family, " status ", Lookup[result, "Status", "?"], " in ", Round[seconds, 0.1], " s"];
If[AssociationQ[result], FeynFacet`TransportStatus[result]];

blockwise = Lookup[result, "Blockwise", None];
If[AssociationQ[blockwise],
 log["  recursion certificate all zero: ", blockwise["Certificate"]["AllZero"]];
 log["  Phi cross-check all zero: ", blockwise["Phi"]["AllZero"]];
 log["  max words per block-order: ", blockwise["MaxWordCount"],
   ", max Chen weight ", blockwise["Weight"],
   ", max coefficient leaves ", blockwise["MaxCoefficientLeaves"]];
 log["  timing: ", blockwise["Timing"]];
 log["  peak Wolfram memory: ", Round[blockwise["PeakMemory"]/1024.^3, 0.01], " GB"];
 Do[log["  words block ", r["Block"], " eps^", r["Order"], ": ", r["Words"],
    " (weight ", r["MaxWeight"], ", max leaves ", Lookup[r, "MaxCoefficientLeaves", "-"],
    ", ", Round[r["Seconds"], 0.01], " s)"], {r, blockwise["WordCounts"]}]];

record = <|"Family" -> family, "Basis" -> "family eps-form (off-diagonal completed)",
  "Orders" -> orders, "Status" -> Lookup[result, "Status", "?"],
  "Seconds" -> seconds, "Engine" -> Lookup[result, "Engine", "?"],
  "Weight" -> Lookup[result, "Weight", "?"],
  "Certificate" -> Lookup[result, "Certificate", None],
  "Checkable" -> Lookup[result, "Checkable", None],
  "DECheck" -> Table[KeyDrop[r, "Residual"], {r, Lookup[result, "DECheck", {}]}],
  "Budget" -> Lookup[result, "Budget", None], "Shift" -> Lookup[result, "Shift", None],
  "Blockwise" -> If[AssociationQ[blockwise], KeyDrop[blockwise, {"Solution"}], blockwise],
  "PeakMemoryBytes" -> MaxMemoryUsed[], "Date" -> DateString[]|>;
FeynFacet`Private`masterTransportPutAtomic[record,
  FileNameJoin[{outdir, "payoff_blockwise_" <> family <> ".wl"}]];
log["written ", FileNameJoin[{outdir, "payoff_blockwise_" <> family <> ".wl"}]];
log["DONE"];
