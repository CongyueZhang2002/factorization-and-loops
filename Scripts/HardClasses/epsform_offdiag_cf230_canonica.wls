#!/usr/bin/env wolframscript
(* Off-diagonal eps-factorization of a family in the chart, ROUTE R1:
   CANONICA's off-diagonal steps on the ASSEMBLED canonical connection.

   Input: the assembly saved by epsform_offdiag_cf230_probe.wls
   (Ax, Ay = Apv/Apw = the conjugated chart connections, block lower
   triangular, every DIAGONAL block already an eps-form).

   What is run, per sector k = 2 ... nb (the diagonal steps are SKIPPED
   because the diagonal blocks are canonical already):

     CANONICA`TransformOffDiagonalBlock[{x,y}, sectorBoundaries[[1..k]],
        IdentityMatrix[n_k], a_k]           (a_k = leading n_k x n_k block)
        -> D_k, a strip with identity diagonal blocks, bringing the
           off-diagonal row block of sector k into DLOG form
     CANONICA`TransformDlogToEpsForm[...]   -> an eps-ONLY transformation
           finishing dlog -> eps-form for the same truncation

   The two together are exactly TransformNextSector minus its
   TransformNextDiagonalBlock call.  Each D_k is embedded into the
   identity of the full size, composed into S, and applied to the full
   connection pair, so the couplings of the higher blocks see the change.

   Measured trap list honored: CANONICA works in CANONICA`eps (translated
   by SymbolName at the boundary and back); a failed step returns
   {False, ...} which is SHAPE-IDENTICAL to success, so every step is
   tested for False explicitly and the only acceptance is the exact gate
   in epsform_offdiag_cf230_gate.wls.

   State is saved after every sector so a long run can be resumed.

   Usage: epsform_offdiag_cf230_canonica.wls [FAMILY] [KSTOP] [NUMDEG] [DENDEG] [TAG] [OUTDIR]
     NUMDEG  DDeltaNumeratorDegree   (CANONICA default 0)
     DENDEG  DDeltaDenominatorDegree (CANONICA default 0)
     TAG     suffix of the state file, so ansatz variants do not collide *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
kStop = If[Length[argv] >= 2, ToExpression[argv[[2]]], 6];
numDeg = If[Length[argv] >= 3, ToExpression[argv[[3]]], 0];
denDeg = If[Length[argv] >= 4, ToExpression[argv[[4]]], 0];
tag = If[Length[argv] >= 5, argv[[5]], ""];
If[Length[argv] >= 6, outdir = argv[[6]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];

start = AbsoluteTime[];
log[a___] := Print["[canon +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`FamilyArtifactRead"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

log["loading CANONICA"];
FeynFacet`Private`canonicalBlocksLoadCanonica[];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);
toCanonica[expr_] := expr /. (s_Symbol /; SymbolName[s] === "eps") :> CANONICA`eps;
fromCanonica[expr_] := expr /. CANONICA`eps -> ee;

asmFile = FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}];
If[! FileExistsQ[asmFile],
  log["!! no assembly at ", asmFile, " -- run epsform_offdiag_cf230_probe.wls first"];
  Exit[1]];
asm = normalizeSymbols[Get[asmFile]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
log[family, ": ", n, "x", n, ", ", nb, " sectors, boundaries ", bounds,
  ", certificate ", asm["CertificateOK"]];

invariants = {xx, yy};

(* ---- state (resume) ---- *)
stateFile = FileNameJoin[{outdir, "canonica_state_" <> family <> tag <> ".wl"}];
baseFile = FileNameJoin[{outdir, "canonica_state_" <> family <> ".wl"}];
Which[
  FileExistsQ[stateFile],
    state = normalizeSymbols[Get[stateFile]];
    log["resuming from sector ", state["Sector"], " (state file ", stateFile, ")"],
  FileExistsQ[baseFile],
    state = normalizeSymbols[Get[baseFile]];
    log["resuming from sector ", state["Sector"], " (base state file)"],
  True,
    state = <|"Sector" -> 1, "S" -> IdentityMatrix[n],
      "A" -> {asm["Ax"], asm["Ay"]}|>];
log["ansatz degrees: DDeltaNumeratorDegree ", numDeg,
  ", DDeltaDenominatorDegree ", denDeg];

putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

(* ---- diagnostics ---- *)
epsDenFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e], d},
     If[TrueQ[t === 0], {}, d = Denominator[t];
       Select[FactorList[d][[All, 1]], ! FreeQ[#, ee] &]]]], m, {2}]]];

epsOrderMin[m_] := Module[{nz = Select[Flatten[m], ! TrueQ[Together[#] === 0] &]},
  If[nz === {}, Infinity,
   Min[FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@ nz]]];

report[a_, upTo_] := Module[{ax = a[[1]], ay = a[[2]], tab},
  tab = Table[If[i >= j,
     Module[{sx = ax[[ranges[[i]], ranges[[j]]]], sy = ay[[ranges[[i]], ranges[[j]]]]},
      If[epsOrderMin[sx] === Infinity && epsOrderMin[sy] === Infinity, Nothing,
       {i, j, Min[epsOrderMin[sx], epsOrderMin[sy]],
        DeleteDuplicates[Join[epsDenFactors[sx], epsDenFactors[sy]]]}]],
     Nothing], {i, upTo}, {j, upTo}];
  Do[log["    (", r[[1]], ",", r[[2]], ") min eps order ", r[[3]],
     If[r[[4]] === {}, "  eps-free denominators", "  eps-dependent denominators " <> ToString[r[[4]]]]],
   {r, Flatten[tab, 1]}]];

log["initial structure (min eps order per block pair; eps-form wants 1 everywhere):"];
report[state["A"], nb];

(* ---- the sector loop ---- *)
Do[
 Module[{nk, aTrunc, res, dk, sfull, secs, res2, dk2, aNew},
  nk = bounds[[k, 2]];
  log["==== sector ", k, " (rows ", bounds[[k]], ", truncation ", nk, "x", nk, ")"];
  aTrunc = toCanonica[{state["A"][[1]][[1 ;; nk, 1 ;; nk]],
                       state["A"][[2]][[1 ;; nk, 1 ;; nk]]}];
  {secs, res} = AbsoluteTiming[CANONICA`TransformOffDiagonalBlock[
     invariants, bounds[[1 ;; k]], IdentityMatrix[nk], aTrunc,
     CANONICA`DDeltaNumeratorDegree -> numDeg,
     (* DDeltaDenominatorDegree is an UNDOCUMENTED option first created
        inside CANONICA`Private` (line 522 of CANONICA.m), so the public
        context spelling would silently be a different symbol *)
     CANONICA`Private`DDeltaDenominatorDegree -> denDeg,
     CANONICA`VerbosityLevel -> 10]];
  log["  TransformOffDiagonalBlock: ", Round[secs, 0.1], " s"];
  If[res[[1]] === False,
   log["  !! TransformOffDiagonalBlock returned False at sector ", k];
   putAtomic[state, stateFile]; Exit[2]];
  dk = fromCanonica[res[[1]]];
  log["  D_", k, " leaves ", LeafCount[dk], ", identity? ",
    TrueQ[Together[dk - IdentityMatrix[nk]] === ConstantArray[0, {nk, nk}]] ||
    AllTrue[Flatten[Together[dk - IdentityMatrix[nk]]], TrueQ[# === 0] &]];

  (* dlog -> eps-form for the same truncation (eps-only transformation) *)
  {secs, res2} = AbsoluteTiming[CANONICA`TransformDlogToEpsForm[
     invariants, bounds[[1 ;; k]], IdentityMatrix[nk], res[[2]],
     CANONICA`VerbosityLevel -> 10]];
  log["  TransformDlogToEpsForm: ", Round[secs, 0.1], " s"];
  If[res2[[1]] === False,
   log["  !! TransformDlogToEpsForm returned False at sector ", k];
   (* still record the dlog step *)
   dk2 = IdentityMatrix[nk],
   dk2 = fromCanonica[res2[[1]]]];
  log["  E_", k, " (eps-only) leaves ", LeafCount[dk2], ", diagonal blocks identity? ",
    AllTrue[Flatten[Table[If[i === j,
        Together[dk2[[ranges[[i]], ranges[[j]]]] - IdentityMatrix[Length[ranges[[i]]]]],
        {}], {i, k}, {j, k}]], TrueQ[# === 0] &]];

  sfull = IdentityMatrix[n];
  sfull[[1 ;; nk, 1 ;; nk]] = Together[dk . dk2];
  aNew = Map[Together, {Inverse[sfull] . state["A"][[1]] . sfull -
       Inverse[sfull] . D[sfull, xx],
     Inverse[sfull] . state["A"][[2]] . sfull -
       Inverse[sfull] . D[sfull, yy]}, {3}];
  state = <|"Sector" -> k, "S" -> Together[state["S"] . sfull], "A" -> aNew|>;
  putAtomic[state, stateFile];
  log["  composed S leaves ", LeafCount[state["S"]], "; structure now:"];
  report[state["A"], nb]],
 {k, Max[2, state["Sector"] + 1], kStop}];

log["==== final state after sector ", state["Sector"]];
log["S leaves ", LeafCount[state["S"]], ", block-unipotent? ",
  AllTrue[Flatten[Table[
     Together[state["S"][[ranges[[i]], ranges[[j]]]] -
       If[i === j, IdentityMatrix[Length[ranges[[i]]]],
        ConstantArray[0, {Length[ranges[[i]]], Length[ranges[[j]]]}]]],
     {i, nb}, {j, i, nb}]], TrueQ[# === 0] &]];
log["A/eps eps-free? ",
  AllTrue[Flatten[state["A"]], FreeQ[Together[#/ee], ee] &]];
log["eps-dependent denominators left: ",
  DeleteDuplicates[Join[epsDenFactors[state["A"][[1]]], epsDenFactors[state["A"][[2]]]]]];
log["DONE"];
