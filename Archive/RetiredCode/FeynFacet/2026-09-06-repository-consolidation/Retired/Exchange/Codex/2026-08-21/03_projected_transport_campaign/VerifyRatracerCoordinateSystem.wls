#!/usr/bin/env wolframscript

(* Parse a Ratracer multi-RHS solution and certify it against the exact
   unspecialized pivot and complementary rows captured from the observable
   transport basis problem.  Sampling is rejection-only; acceptance requires
   both symbolic matrix identities over Q(p,s). *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 3,
  Print["Usage: VerifyRatracerCoordinateSystem.wls " <>
    "SYSTEM.mx SOLUTION.txt OUTPUT_DIRECTORY"];
  Exit[64]
];

{systemFile, solutionFile, outputDirectory} =
  ExpandFileName /@ arguments;
If[! And @@ (FileExistsQ /@ {systemFile, solutionFile}), Exit[66]];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Block[{$Context = "FeynFacet`Private`",
    $ContextPath = {"FeynFacet`", "System`", "Global`"}},
  Get[FileNameJoin[{bundle,
    "CodexObservableTransportRatracerCandidate.wl"}]]];

start = AbsoluteTime[];
Clear[Global`codexRatracerCapturedSystem];
Get[systemFile];
system = Global`codexRatracerCapturedSystem;
Clear[Global`codexRatracerCapturedSystem];
If[! AssociationQ[system] ||
    Lookup[system, "Format", None] =!=
      "CodexObservableTransportRatracerCoordinateSystem",
  Print["Invalid exact coordinate-system fixture"];
  Exit[65]
];

rank = system["Rank"];
rhsColumns = system["RightHandSideColumns"];
pivotBasis = system["BasisPivot"];
pivotTargets = system["TargetsPivot"];
complementaryBasis = system["BasisComplement"];
complementaryTargets = system["TargetsComplement"];
If[Dimensions[pivotBasis] =!= {rank, rank} ||
    Dimensions[pivotTargets] =!= {rank, rhsColumns} ||
    Dimensions[complementaryBasis][[2]] =!= rank ||
    Dimensions[complementaryTargets] =!=
      {Dimensions[complementaryBasis][[1]], rhsColumns},
  Print["Captured coordinate-system dimensions are inconsistent"];
  Exit[65]
];

text = Import[solutionFile, "Text"];
triples = StringCases[text,
  RegularExpression[
      "CO\\[dep@([0-9]+),master@([0-9]+)\\]\\s*=\\s*([\\s\\S]*?);"] :>
    {"$1", "$2", "$3"}];
If[triples === {},
  Print["No Ratracer coordinate outputs were parsed"];
  Exit[65]
];
If[! AllTrue[triples[[All, 3]],
    StringMatchQ[#, RegularExpression["[0-9ps+*/^().\\-\\s]+"]] &],
  Print["Ratracer solution contains an unexpected token"];
  Exit[65]
];

{parseSeconds, parsedRules} = AbsoluteTiming[
  ({ToExpression[#[[1]]], ToExpression[#[[2]]]} ->
      ToExpression[#[[3]], InputForm]) & /@ triples
];
capturedVariables = system["CoefficientVariables"];
capturedByName = AssociationThread[
  SymbolName /@ capturedVariables, capturedVariables];
parsedSymbols = DeleteDuplicates[Cases[
  Last /@ parsedRules,
  symbol_Symbol /;
      KeyExistsQ[capturedByName,
        SymbolName[Unevaluated[symbol]]] :> symbol,
  Infinity]];
symbolRules = Dispatch[
  (# -> capturedByName[SymbolName[Unevaluated[#]]]) & /@ parsedSymbols];
parsedRules = (First[#] -> (Last[#] /. symbolRules)) & /@ parsedRules;
Print["CODEX_RATRACER_VERIFY phase=symbol-map parsed=",
  InputForm[(SymbolName[Unevaluated[#]] -> Context[Unevaluated[#]]) & /@
    parsedSymbols],
  " captured=",
  InputForm[(SymbolName[Unevaluated[#]] -> Context[Unevaluated[#]]) & /@
    capturedVariables]];
keys = First /@ parsedRules;
If[Length[DeleteDuplicates[keys]] =!= Length[keys] ||
    ! AllTrue[keys,
      1 <= #[[1]] <= rank && 1 <= #[[2]] <= rhsColumns &],
  Print["Ratracer solution has duplicate or out-of-range coordinates"];
  Exit[65]
];
coordinates = SparseArray[parsedRules, {rank, rhsColumns}];
Print["CODEX_RATRACER_VERIFY phase=parsed outputs=", Length[parsedRules],
  " dimensions=", Dimensions[coordinates],
  " seconds=", N[parseSeconds],
  " memory_bytes=", MemoryInUse[],
  " max_memory_bytes=", MaxMemoryUsed[]];

coefficientVariables = Select[capturedVariables,
  ! FreeQ[{pivotBasis, pivotTargets, complementaryBasis,
      complementaryTargets}, #] &];
samples = DeleteDuplicates[
  Cases[system["SampleRules"], rules_List :>
    Select[rules, MemberQ[coefficientVariables, First[#]] &]]];
samples = Select[samples,
  Length[DeleteDuplicates[First /@ #]] === Length[coefficientVariables] &];
{sampleSeconds, sampleChecks} = AbsoluteTiming[
  Table[
    With[{a = Normal[pivotBasis /. rules],
          b = Normal[pivotTargets /. rules],
          x = Normal[coordinates] /. rules,
          ac = Normal[complementaryBasis /. rules],
          bc = Normal[complementaryTargets /. rules]},
      MatrixQ[a] && MatrixQ[b] && MatrixQ[x] &&
        MatrixQ[ac] && MatrixQ[bc] &&
        FreeQ[{a, b, x, ac, bc},
          Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
        TrueQ[a . x === b] && TrueQ[ac . x === bc]
    ],
    {rules, samples}]
];
Print["CODEX_RATRACER_VERIFY phase=sample-check checks=", sampleChecks,
  " seconds=", N[sampleSeconds]];
If[! And @@ sampleChecks,
  Print["Ratracer reconstruction failed an exact rational sample"];
  Exit[1]
];

{pivotSeconds, pivotIdentity} = AbsoluteTiming[
  FeynFacet`Private`observableTransportExactCoordinateIdentityQ[
    pivotBasis, coordinates, pivotTargets]
];
Print["CODEX_RATRACER_VERIFY phase=pivot-exact identity=", pivotIdentity,
  " seconds=", N[pivotSeconds],
  " memory_bytes=", MemoryInUse[],
  " max_memory_bytes=", MaxMemoryUsed[]];
If[! TrueQ[pivotIdentity], Exit[1]];

{complementSeconds, complementIdentity} = AbsoluteTiming[
  FeynFacet`Private`observableTransportExactCoordinateIdentityQ[
    complementaryBasis, coordinates, complementaryTargets]
];
Print["CODEX_RATRACER_VERIFY phase=complement-exact identity=",
  complementIdentity,
  " seconds=", N[complementSeconds],
  " memory_bytes=", MemoryInUse[],
  " max_memory_bytes=", MaxMemoryUsed[]];
If[! TrueQ[complementIdentity], Exit[1]];

solutionRecord = <|
  "Status" -> "ExactRatracerCoordinateSolution",
  "Exact" -> True,
  "FormatVersion" -> 1,
  "Rank" -> rank,
  "RightHandSideColumns" -> rhsColumns,
  "NonzeroCoordinates" -> Length[parsedRules],
  "Coordinates" -> coordinates,
  "PivotIdentity" -> True,
  "ComplementIdentity" -> True,
  "SampleChecks" -> sampleChecks,
  "ParseSeconds" -> parseSeconds,
  "SampleSeconds" -> sampleSeconds,
  "PivotExactSeconds" -> pivotSeconds,
  "ComplementExactSeconds" -> complementSeconds,
  "TotalSeconds" -> AbsoluteTime[] - start,
  "SystemFile" -> systemFile,
  "SystemSHA256" -> FileHash[systemFile, "SHA256", "HexString"],
  "RatracerSolutionFile" -> solutionFile,
  "RatracerSolutionSHA256" ->
    FileHash[solutionFile, "SHA256", "HexString"],
  "MaxMemoryUsedBytes" -> MaxMemoryUsed[]
|>;

mxFile = FileNameJoin[{outputDirectory,
  "coordinate_solution_exact.mx"}];
temporary = mxFile <> ".partial-" <> ToString[$ProcessID];
Global`codexRatracerCoordinateSolution = solutionRecord;
DumpSave[temporary, Global`codexRatracerCoordinateSolution];
Clear[Global`codexRatracerCoordinateSolution];
RenameFile[temporary, mxFile, OverwriteTarget -> True];

summary = KeyDrop[solutionRecord, "Coordinates"];
summary = Join[summary, <|
  "ExactSolutionFile" -> mxFile,
  "ExactSolutionBytes" -> FileByteCount[mxFile],
  "ExactSolutionSHA256" -> FileHash[mxFile, "SHA256", "HexString"]|>];
summaryFile = FileNameJoin[{outputDirectory,
  "coordinate_solution_exact_summary.wl"}];
temporary = summaryFile <> ".partial-" <> ToString[$ProcessID];
Put[summary, temporary];
RenameFile[temporary, summaryFile, OverwriteTarget -> True];
Print[InputForm[summary]];
