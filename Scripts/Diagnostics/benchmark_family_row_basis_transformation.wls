#!/usr/bin/env wolframscript
(* Compare sparse row-gauge propagation with the former dense implementation
   on an immutable saved state/checkpoint.  The output contains timings and
   exact equality verdicts, never the large intermediate matrices. *)

args = Rest[$ScriptCommandLine];
If[Length[args] < 3,
  Print["Usage: benchmark_family_row_basis_transformation.wls <state.wl> <off_diagonal_block_state.wl> <result.wl>"];
  Exit[64]];
{stateFile, stripFile, resultFile} = args[[1 ;; 3]];
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
state = Get[stateFile]; checkpoint = Get[stripFile];
If[! AssociationQ[state] || ! AssociationQ[checkpoint],
  Print["BENCH invalid fixture"]; Exit[2]];

Clear[x, y];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
k = checkpoint["Sector"];
ranges = state["Ranges"];
rows = ranges[[k]]; start = First[rows]; n = Length[state["S"]];
columns = Range[start - 1]; gauge = checkpoint["PrevD"];
If[Dimensions[gauge] =!= {Length[rows], Length[columns]},
  Print["BENCH gauge dimensions do not match row block: ", Dimensions[gauge],
    " expected ", {Length[rows], Length[columns]}]; Exit[2]];

Print["BENCH fixture sector=", k, " n=", n, " rows=", rows,
  " gauge=", Dimensions[gauge], " stateBytes=", ByteCount[state]];
memory0 = MemoryInUse[]; max0 = MaxMemoryUsed[];
{sparseSeconds, sparse} = AbsoluteTiming[
  FeynFacet`Private`familyRowBasisTransformationApply[state["A"], state["S"],
    state["SInverse"], rows, gauge, variables]];
Print["BENCH sparse done seconds=", N[sparseSeconds], " status=",
  Lookup[sparse, "Status", Missing[]], " statistics=",
  Lookup[sparse, "Statistics", Missing[]], " memoryMB=",
  Round[MemoryInUse[]/10.^6], " maxMB=", Round[MaxMemoryUsed[]/10.^6]];
If[! AssociationQ[sparse] || sparse["Status"] =!= "OK", Exit[2]];

legacyA = state["A"];
legacyS = state["S"];
legacyInverse = state["SInverse"];
{legacySeconds, Null} = AbsoluteTiming[
  Do[
    ad = state["A"][[mu, start ;; n, rows]] . gauge;
    da = gauge . state["A"][[mu, columns, columns]];
    derivative = D[gauge, variables[[mu]]];
    legacyA[[mu, start ;; n, columns]] = Map[Together,
      state["A"][[mu, start ;; n, columns]] + ad, {2}];
    legacyA[[mu, rows, columns]] = Map[Together,
      legacyA[[mu, rows, columns]] - da - derivative, {2}],
    {mu, 2}];
  legacyS[[All, columns]] = Map[Together,
    state["S"][[All, columns]] + state["S"][[All, rows]] . gauge, {2}];
  legacyInverse[[rows, All]] = Map[Together,
    state["SInverse"][[rows, All]] -
      gauge . state["SInverse"][[columns, All]], {2}];];
Print["BENCH legacy done seconds=", N[legacySeconds], " memoryMB=",
  Round[MemoryInUse[]/10.^6], " maxMB=", Round[MaxMemoryUsed[]/10.^6]];

zeroQ[expression_] := TrueQ[Together[expression] === 0];
sameMatrixQ[left_, right_] := Dimensions[left] === Dimensions[right] &&
  AllTrue[Flatten[left - right], zeroQ];
{checkSeconds, verdicts} = AbsoluteTiming[<|
  "Connection" -> And @@ MapThread[sameMatrixQ,
    {sparse["Connection"], legacyA}],
  "Transformation" -> sameMatrixQ[sparse["Transformation"], legacyS],
  "Inverse" -> sameMatrixQ[sparse["Inverse"], legacyInverse]
|>];
Print["BENCH exact comparison seconds=", N[checkSeconds],
  " verdicts=", verdicts];

record = <|
  "Status" -> If[AllTrue[Values[verdicts], TrueQ], "OK", "Mismatch"],
  "StateFile" -> ExpandFileName[stateFile],
  "StripFile" -> ExpandFileName[stripFile],
  "Sector" -> k, "Dimension" -> n,
  "OffDiagonalBasisTransformationBlockDimensions" -> Dimensions[gauge],
  "SparseSeconds" -> sparseSeconds, "LegacySeconds" -> legacySeconds,
  "Speedup" -> If[sparseSeconds > 0, legacySeconds/sparseSeconds, Infinity],
  "CheckSeconds" -> checkSeconds, "Verdicts" -> verdicts,
  "SparseStatistics" -> sparse["Statistics"],
  "InitialMemoryBytes" -> memory0,
  "AdditionalMaxMemoryBytes" -> MaxMemoryUsed[] - max0
|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["BENCH RESULT ", KeyTake[record,
  {"Status", "SparseSeconds", "LegacySeconds", "Speedup", "Verdicts"}],
  " written=", resultFile];
Exit[If[record["Status"] === "OK", 0, 1]];
