#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3,
  Print["Usage: run_triple_root_affine_pilot.wls <project-root> <strip-input.wl> <output.wl> [prime=1000003] [eps=1/7] [dx=0] [dy=0]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
inputFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];
prime = If[Length[arguments] >= 4, ToExpression[arguments[[4]]], 1000003];
epsilonValue = If[Length[arguments] >= 5,
  ToExpression[arguments[[5]]], 1/7];
degreeOffset = {
  If[Length[arguments] >= 6, ToExpression[arguments[[6]]], 0],
  If[Length[arguments] >= 7, ToExpression[arguments[[7]]], 0]};

If[! FileExistsQ[inputFile],
  Print["TRPILOT FAIL missing_input=", inputFile];
  Exit[65]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
scratchDirectory = DirectoryName[$InputFileName];
Get[FileNameJoin[{scratchDirectory, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{scratchDirectory, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{scratchDirectory, "TripleRootAffinePilot.wl"}]];

record = Get[inputFile];
If[! AssociationQ[record],
  Print["TRPILOT FAIL invalid_record"];
  Exit[66]];
family = Lookup[record, "Family", None];
frame = FeynFacet`TransportFamilyChart[family];
If[! AssociationQ[frame],
  Print["TRPILOT FAIL invalid_frame family=", family];
  Exit[67]];

{seconds, result} = AbsoluteTiming[
  CodexTripleRootPilot`TRSampleAffinePilot[
    record, frame, epsilonValue, prime,
    "DegreeOffset" -> degreeOffset,
    "Verbose" -> True]];

result = If[AssociationQ[result],
  Join[result, <|"WallSeconds" -> seconds|>], result];
If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile],
    CreateIntermediateDirectories -> True]];
temporary = outputFile <> ".tmp";
Put[result, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];

Print["TRPILOT RESULT status=", If[AssociationQ[result],
    Lookup[result, "Status", None], Head[result]],
  " dimensions=", If[AssociationQ[result],
    InputForm[Lookup[result, "MatrixDimensions", Missing[]]], Missing[]],
  " ranks=", If[AssociationQ[result],
    InputForm[Lookup[result, {"Rank", "AugmentedRank"}, Missing[]]],
    Missing[]],
  " residual=", If[AssociationQ[result],
    Lookup[result, "ResidualZero", Missing[]], Missing[]],
  " seconds=", Round[seconds, 0.1]];

Exit[If[AssociationQ[result] &&
  Lookup[result, "Status", None] === "ConsistentPilot" &&
  TrueQ[Lookup[result, "ResidualZero", False]], 0, 1]];
