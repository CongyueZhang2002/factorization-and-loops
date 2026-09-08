#!/usr/bin/env wolframscript

$HistoryLength = 0;

args = Rest[$ScriptCommandLine];
taskDirectory = args[[1]];
resultDirectory = args[[2]];
kernelTarget = If[Length[args] >= 3, ToExpression[args[[3]]], 8];
candidateSeconds = If[Length[args] >= 4, ToExpression[args[[4]]], 1800];
canonicaFile = "/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m";

If[! DirectoryQ[resultDirectory],
  CreateDirectory[resultDirectory, CreateIntermediateDirectories -> True]];

CloseKernels[];
LaunchKernels[kernelTarget];
Print["Parallel CANONICA strip replay: ", $KernelCount, " subkernels"];

With[{file = canonicaFile},
  ParallelEvaluate[
    Get[file];
    CANONICA`$ComputeParallel = False;
    CANONICA`Private`$ComputeParallel = False;
  ]];

resolveCanonica[name_String] := Module[
  {public = ToExpression["CANONICA`" <> name],
   private = ToExpression["CANONICA`Private`" <> name]},
  Which[
    DownValues[Evaluate[public]] =!= {}, public,
    DownValues[Evaluate[private]] =!= {}, private,
    True, $Failed
  ]
];

solveTask[taskFile_String, configurations_List, seconds_, outputDirectory_] := Module[
  {task, e, c, bbar, invariants, findD, extractIrreducibles, checkDlog,
   irred, alphabet, attempts = {}, gauge, transformed, exactQ, elapsed,
   config, result, outputFile, sector, lowerSector},

  task = Get[taskFile];
  sector = task["Sector"];
  lowerSector = task["LowerSector"];
  outputFile = FileNameJoin[{outputDirectory,
    "canonica_" <> ToString[sector] <> "_" <> ToString[lowerSector] <> ".wl"}];

  If[FileExistsQ[outputFile],
    result = Get[outputFile];
    If[AssociationQ[result] && TrueQ[result["ExactDLog"]],
      Return[KeyDrop[result, "Gauge"]]]];

  findD = resolveCanonica["FindD"];
  extractIrreducibles = resolveCanonica["ExtractIrreducibles"];
  checkDlog = resolveCanonica["CheckDlogForm"];
  If[MemberQ[{findD, extractIrreducibles, checkDlog}, $Failed],
    Return[<|"Sector" -> sector, "LowerSector" -> lowerSector,
      "Status" -> "CANONICAFunctionMissing"|>]];

  {e, c, bbar} = Lookup[task, {"E", "C", "BBar"}] /.
    Global`eps -> CANONICA`eps;
  invariants = task["Invariants"];
  irred = extractIrreducibles[{e, c, bbar},
    CANONICA`AllowEpsDependence -> True];
  alphabet = Union[invariants, Select[irred, FreeQ[#, CANONICA`eps] &]];

  Do[
    config = configurations[[index]];
    {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
      findD[e, c, bbar, alphabet, invariants, {},
        CANONICA`DDeltaNumeratorDegree -> config[[1]],
        CANONICA`DDeltaDenominatorDegree -> config[[2]],
        CANONICA`VerbosityLevel -> 0],
      seconds, $TimedOut]]];

    If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
      AppendTo[attempts, <|
        "NumeratorDegree" -> config[[1]],
        "DenominatorDegree" -> config[[2]],
        "Seconds" -> elapsed,
        "Status" -> Which[
          gauge === $TimedOut, "TimedOut",
          gauge === False, "NoGauge",
          True, "InvalidResult"]|>];
      Continue[]];

    transformed = Table[Map[Together,
      bbar[[mu]] + CANONICA`eps (e[[mu]].gauge - gauge.c[[mu]]) -
        D[gauge, invariants[[mu]]], {2}], {mu, Length[invariants]}];
    exactQ = TrueQ[checkDlog[transformed, invariants, alphabet]];
    AppendTo[attempts, <|
      "NumeratorDegree" -> config[[1]],
      "DenominatorDegree" -> config[[2]],
      "Seconds" -> elapsed,
      "Status" -> If[exactQ, "ExactDLog", "FailedDLogIdentity"]|>];

    If[exactQ,
      result = <|
        "Sector" -> sector,
        "LowerSector" -> lowerSector,
        "ExactDLog" -> True,
        "NumeratorDegree" -> config[[1]],
        "DenominatorDegree" -> config[[2]],
        "Attempts" -> attempts,
        "Gauge" -> (gauge /. CANONICA`eps -> Global`eps)|>;
      Put[result, outputFile];
      Return[KeyDrop[result, "Gauge"]]],
    {index, Length[configurations]}];

  result = <|
    "Sector" -> sector,
    "LowerSector" -> lowerSector,
    "ExactDLog" -> False,
    "Attempts" -> attempts|>;
  Put[result, outputFile];
  result
];

configurations = {
  {1, 0}, {2, 0}, {3, 0}, {4, 0},
  {1, 1}, {2, 1}, {3, 1}, {4, 1},
  {5, 0}, {5, 1}, {6, 0}, {6, 1}
};

taskFiles = Sort[FileNames["next_equation_*.wl", taskDirectory]];
If[taskFiles === {},
  Print["No saved strip equations in ", taskDirectory];
  Exit[2]];

DistributeDefinitions[resolveCanonica, solveTask, configurations];
results = ParallelMap[
  solveTask[#, configurations, candidateSeconds, resultDirectory] &,
  taskFiles,
  Method -> "FinestGrained"];

Put[results, FileNameJoin[{resultDirectory, "summary.wl"}]];
Print[Dataset[results]];
CloseKernels[];
Exit[If[AllTrue[results, TrueQ[Lookup[#, "ExactDLog", False]] &], 0, 1]];
