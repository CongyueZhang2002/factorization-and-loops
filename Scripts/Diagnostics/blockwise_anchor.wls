#!/usr/bin/env wolframscript
(* S3 (regression anchors) for the block-wise transport engine.

   The two families the existing suite already transports monolithically
   are re-solved with "Engine" -> "Blockwise" and the two solutions are
   compared EXACTLY, entrywise and order by order, in the same word
   representation:

     NLO  the certified 7x7 epsilon-form family (t_master_transport B1-B8);
     CF3  the tier-3 family whose conjugated connection keeps a 1/eps
          off-diagonal coupling (t_master_transport C0-C12), i.e. the case
          where weight grading and epsilon grading differ and the
          block-wise recursion has to reach a HIGHER order of a LOWER
          block to produce a lower order of a higher one.

   Acceptance, stated before the run:

     A1  both engines return a verified status on both families;
     A2  F^blockwise_{i,n} - F^monolithic_{i,n} == 0 exactly, for every
         master i and every epsilon order n in the union of the two
         windows (a missing order counts as zero, never as agreement);
     A3  the assembled masters I agree the same way;
     A4  the block-wise recursion certificate is an exact zero for every
         block and every order;
     A5  the Phi cross-check against Libra's cached per-class Pexp is an
         exact zero wherever it was performed.

   Both engines share the assembly, so the block permutation, the
   symbolic constants TransportConstant[s,q,i] and the path are literally
   the same objects; a difference can therefore only be in the transport
   itself, which is what this anchor is for.

   Usage: blockwise_anchor.wls [OUTDIR] [FAMILIES]
     FAMILIES  "NLO", "CF3" or "NLO,CF3" (default). *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_blockwise";

argv = Rest[$ScriptCommandLine];
If[Length[argv] >= 1, outdir = argv[[1]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];
families = If[Length[argv] >= 2, StringSplit[argv[[2]], ","], {"NLO", "CF3"}];

start = AbsoluteTime[];
(* Print, not WriteString["stdout"]: inside a KernelPool mission $Output
   is the mission's own log file and a literal "stdout" write would land
   in the pool log instead. *)
log[a___] := Print["[anchor +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Pool subkernels keep state between missions.  A mission that left an
   OWN VALUE on Global`tau (the "tau = Symbol[\"Global`tau\"]" trap) would
   make every later transport here fail with
   MasterTransport::pathparameter, which is the module refusing correctly
   for a reason that has nothing to do with this run. *)
Quiet[Clear["Global`tau"]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;

zeroQ[e_] := FeynFacet`Private`masterTransportZeroQ[e];

(* The comparison.  Orders present in only one window are compared
   against ZERO rather than skipped: an engine that simply does not
   produce an order must not thereby agree with one that does. *)
compareSeries[keyA_, a_, keyB_, b_, dimension_] := Module[{orders, records},
  orders = Union[keyA, keyB];
  records = Table[
    Module[{va, vb, residual, verdict},
      va = If[MemberQ[keyA, k], a[k], ConstantArray[0, dimension]];
      vb = If[MemberQ[keyB, k], b[k], ConstantArray[0, dimension]];
      residual = va - vb;
      verdict = DeleteDuplicates[zeroQ /@ residual];
      <|"Order" -> k, "Zero" -> verdict,
        "InA" -> MemberQ[keyA, k], "InB" -> MemberQ[keyB, k],
        "Residual" -> If[verdict === {True}, Null, residual]|>],
    {k, orders}];
  <|"Orders" -> orders, "PerOrder" -> records,
    "AllZero" -> AllTrue[records, #["Zero"] === {True} &]|>];

runPair[name_String, system_, options_List] := Module[
  {monolithic, blockwise, tMono, tBlock, fCompare, iCompare, record},
  log["==== ", name, " ===="];
  log[name, ": monolithic engine"];
  {tMono, monolithic} = AbsoluteTiming[
    FeynFacet`TransportFamily[system, Sequence @@ options,
      "Engine" -> "Monolithic"]];
  log[name, " monolithic status ", Lookup[monolithic, "Status", "?"],
    ", weight ", Lookup[monolithic, "Weight", "?"], ", ",
    Round[tMono, 0.1], " s"];
  log[name, ": block-wise engine"];
  {tBlock, blockwise} = AbsoluteTiming[
    FeynFacet`TransportFamily[system, Sequence @@ options,
      "Engine" -> "Blockwise", "Verbose" -> True]];
  log[name, " blockwise status ", Lookup[blockwise, "Status", "?"],
    ", max Chen weight ", Lookup[blockwise, "Weight", "?"], ", ",
    Round[tBlock, 0.1], " s"];

  fCompare = If[AssociationQ[monolithic] && AssociationQ[blockwise] &&
     KeyExistsQ[monolithic, "F"] && KeyExistsQ[blockwise, "F"],
    compareSeries[Keys[monolithic["F"]], monolithic["F"],
      Keys[blockwise["F"]], blockwise["F"], monolithic["N"]],
    <|"AllZero" -> False, "Reason" -> "one engine produced no F"|>];
  iCompare = If[AssociationQ[monolithic] && AssociationQ[blockwise] &&
     KeyExistsQ[monolithic, "I"] && KeyExistsQ[blockwise, "I"],
    Module[{oa, ob},
      oa = monolithic["I"]["Orders"]; ob = blockwise["I"]["Orders"];
      compareSeries[oa,
        Association[Table[oa[[k]] -> monolithic["I"]["I"][[k]], {k, Length[oa]}]],
        ob,
        Association[Table[ob[[k]] -> blockwise["I"]["I"][[k]], {k, Length[ob]}]],
        monolithic["N"]]],
    <|"AllZero" -> False, "Reason" -> "one engine produced no I"|>];

  log[name, " A2 F agrees exactly: ", fCompare["AllZero"]];
  log[name, " A3 I agrees exactly: ", iCompare["AllZero"]];
  log[name, " A4 recursion certificate all zero: ",
    Lookup[Lookup[Lookup[blockwise, "Blockwise", <||>], "Certificate", <||>],
      "AllZero", "?"]];
  log[name, " A5 Phi cross-check all zero: ",
    Lookup[Lookup[Lookup[blockwise, "Blockwise", <||>], "Phi", <||>],
      "AllZero", "?"]];

  record = <|
    "Family" -> name,
    "MonolithicStatus" -> Lookup[monolithic, "Status", "?"],
    "BlockwiseStatus" -> Lookup[blockwise, "Status", "?"],
    "MonolithicSeconds" -> tMono,
    "BlockwiseSeconds" -> tBlock,
    "MonolithicWeight" -> Lookup[monolithic, "Weight", "?"],
    "BlockwiseWeight" -> Lookup[blockwise, "Weight", "?"],
    "MonolithicFOrders" -> Lookup[monolithic, "FOrders", {}],
    "BlockwiseFOrders" -> Lookup[blockwise, "FOrders", {}],
    "FCompare" -> KeyDrop[fCompare, "PerOrder"],
    "FComparePerOrder" -> Table[KeyDrop[r, "Residual"],
      {r, Lookup[fCompare, "PerOrder", {}]}],
    "ICompare" -> KeyDrop[iCompare, "PerOrder"],
    "IComparePerOrder" -> Table[KeyDrop[r, "Residual"],
      {r, Lookup[iCompare, "PerOrder", {}]}],
    "Blockwise" -> KeyDrop[Lookup[blockwise, "Blockwise", <||>], "Solution"],
    "MonolithicDECheck" -> Table[KeyDrop[r, "Residual"],
      {r, Lookup[monolithic, "DECheck", {}]}],
    "BlockwiseDECheck" -> Table[KeyDrop[r, "Residual"],
      {r, Lookup[blockwise, "DECheck", {}]}]|>;
  record];

records = {};

If[MemberQ[families, "NLO"],
  Module[{nloRaw, nloSystem, nloBasis, nloAv, nloAw, nloT},
    nloRaw = Get[FileNameJoin[{root, "ppHX_NLO", "Results", "NLO_UU_Masters.wl"}]];
    nloSystem = nloRaw["DifferentialSystem"];
    nloBasis = nloSystem["Basis"];
    nloAv = normalizeRegulator[nloSystem["Av"]];
    nloAw = normalizeRegulator[nloSystem["Aw"]];
    nloT = DiagonalMatrix[{1, (2 ee - 1)/(ee vv),
       (2 ee - 1)/(ee ww (vv + ww - 1)), (2 ee - 1)/(ee ww),
       (2 ee - 1)/(ee (vv + ww - 1)), (2 ee - 1)/(ee vv (vv + ww - 1)),
       (2 ee - 1)/(ee vv ww)}];
    AppendTo[records, runPair["NLO",
      <|"Family" -> "NLO", "Basis" -> nloBasis, "Av" -> nloAv, "Aw" -> nloAw|>,
      {"Variables" -> {vv, ww}, "Regulator" -> ee,
       "Blocks" -> Table[{{i}, <|"Type" -> "EpsForm", "T" -> {{nloT[[i, i]]}}|>},
         {i, 7}],
       "BasePoint" -> {1/4, 1/4}, "Orders" -> {-1, 2},
       "PhysicalValuation" -> -1, "TransportBackend" -> "Libra"}]]]];

If[MemberQ[families, "CF3"],
  Module[{cf3},
    cf3 = normalizeRegulator[Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical", "DifferentialEquations",
      "nnlo_de_CF3.wl"}]]];
    AppendTo[records, runPair["CF3",
      <|"Family" -> "CF3", "Basis" -> cf3["BlockBasis"],
        "Av" -> cf3["Av"], "Aw" -> cf3["Aw"]|>,
      {"Variables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> Automatic,
       "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> -1,
       "Orders" -> {-1, 3}, "TransportBackend" -> "Libra",
       "MaxWeight" -> 12}]]]];

FeynFacet`Private`masterTransportPutAtomic[
  <|"Records" -> records, "Seconds" -> AbsoluteTime[] - start,
    "Date" -> DateString[]|>,
  FileNameJoin[{outdir, "blockwise_anchor.wl"}]];
log["written ", FileNameJoin[{outdir, "blockwise_anchor.wl"}]];
Do[
  log["SUMMARY ", r["Family"], ": monolithic ", r["MonolithicStatus"], " (",
    Round[r["MonolithicSeconds"], 0.1], " s) vs blockwise ",
    r["BlockwiseStatus"], " (", Round[r["BlockwiseSeconds"], 0.1],
    " s); F equal ", r["FCompare"]["AllZero"], ", I equal ",
    r["ICompare"]["AllZero"]],
  {r, records}];
log["DONE"];
