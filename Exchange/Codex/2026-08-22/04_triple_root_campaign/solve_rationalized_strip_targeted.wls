#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 4,
  Print["Usage: solve_rationalized_strip_targeted.wls <project-root> <record.wl> <artifact-dir> <solution.wl> [support-strategy=SimplexFirst] [dxdy-list]"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
artifactDirectory = ExpandFileName[arguments[[3]]];
solutionFile = ExpandFileName[arguments[[4]]];
supportStrategy = If[Length[arguments] >= 5,
  arguments[[5]], "SimplexFirst"];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[recordFile];
If[! AssociationQ[record] || ! TrueQ[Lookup[record, "Rational", False]],
  Print["TRTARGET FAIL invalid_rational_record"];
  Exit[65]];

If[! DirectoryQ[artifactDirectory],
  CreateDirectory[artifactDirectory, CreateIntermediateDirectories -> True]];

solveRecord = KeyTake[record,
  {"Family", "Sector", "LowerSector", "Variables", "Regulator", "Strip"}];
{seconds, result} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[
    solveRecord,
    "KernelCount" -> 4,
    "ArtifactDirectory" -> artifactDirectory,
    "ArtifactPrefix" -> "CF300_8_5_targeted",
    "SupportStrategy" -> supportStrategy,
    "SupportLearning" -> False,
    "FinalCheck" -> "Exact",
    "Verbose" -> True]];

output = <|"SourceRecord" -> recordFile,
  "Seconds" -> seconds,
  "Result" -> result|>;
temporary = solutionFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, solutionFile, OverwriteTarget -> True];

Print["TRTARGET RESULT status=", If[AssociationQ[result],
    Lookup[result, "Status", None], Head[result]],
  " method=", If[AssociationQ[result],
    Lookup[result, "Method", None], None],
  " offset=", If[AssociationQ[result],
    Lookup[result, "SelectedNumeratorDegreeOffset", Missing[]], Missing[]],
  " support=", If[AssociationQ[result],
    Length[Lookup[result, "GaugeSupport", {}]], 0],
  " seconds=", Round[seconds, 0.1]];

Exit[If[AssociationQ[result] &&
  Lookup[result, "Status", None] === "Solved" &&
  TrueQ[Lookup[result, "ExactDLog", False]], 0, 1]];
