(* Apples-to-apples benchmark of the two finite-field linear-algebra
   backends on one
   off-diagonal block (k,j) coupling record.

   usage:
     taskset -c <core1,core2,core3> wolframscript -file \
       benchmark_off_diagonal_block_backends.wls FIXTURE BACKEND OUTDIR [TAG]

   FIXTURE  a .wl file with <|"OffDiagonalBlockEquation" -> {e, c, inhomogeneity},
            "Variables" -> {x, y}, "Regulator" -> eps, ...|>
            (the format SolveOffDiagonalBasisTransformationBlockFiniteField consumes).
   BACKEND  Wolfram | FLINT
   OUTDIR   result directory (created if absent)
   TAG      optional label, default = fixture base name

   Protocol (recorded in TransportProductionPlan.md, 2026-08-20):
   - one Wolfram kernel; internal parallelism is capped at one worker.
   - no artifact replay: the finite-field backend gets a FRESH artifact
     directory so sampling, interpolation, and lifting are all re-done.
   - harness wall time and the solver's own stage fields are stored.
   - acceptance is each backend's own exact both-variable residual check,
     stored verbatim; the harness never grades on shape. *)

If[Length[$ScriptCommandLine] < 4,
  Print["usage: wolframscript -file benchmark_off_diagonal_block_backends.wls ",
    "FIXTURE BACKEND OUTDIR [TAG]"];
  Exit[2]
];

root = DirectoryName[ExpandFileName[$InputFileName], 3];

fixtureFile = ExpandFileName[$ScriptCommandLine[[2]]];
fixture = Quiet[Check[Get[fixtureFile], $Failed]];
If[! AssociationQ[fixture] ||
    ! SubsetQ[Keys[fixture], {"OffDiagonalBlockEquation", "Variables", "Regulator"}],
  Print["BENCH unreadable fixture or missing OffDiagonalBlockEquation/Variables/Regulator: ",
    fixtureFile];
  Exit[3]
];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

backend = $ScriptCommandLine[[3]];
If[! MemberQ[{"Wolfram", "FLINT"}, backend],
  Print["BENCH backend must be Wolfram or FLINT, got: ", backend];
  Exit[4]
];
outdir = ExpandFileName[$ScriptCommandLine[[4]]];
If[! DirectoryQ[outdir],
  CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
tag = If[Length[$ScriptCommandLine] >= 5, $ScriptCommandLine[[5]],
  FileBaseName[fixtureFile]];

offDiagonalBlockEquation = fixture["OffDiagonalBlockEquation"];
variables = fixture["Variables"];
regulator = fixture["Regulator"];

Print["BENCH tag=", tag, " backend=", backend,
  " dims=", Dimensions[offDiagonalBlockEquation[[3]]],
  " cores=", $ProcessorCount];

start = AbsoluteTime[];
result = AbsoluteTiming[
    FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
      <|"OffDiagonalBlockEquation" -> offDiagonalBlockEquation,
        "Variables" -> variables, "Regulator" -> regulator|>,
      "Backend" -> backend,
      "KernelCount" -> 1,
      "ArtifactDirectory" ->
        FileNameJoin[{outdir, "ff_artifacts_" <> tag <> "_" <>
          DateString[Now, {"Hour", "Minute", "Second"}]}],
      "Verbose" -> True]];
{wall, solution} = result;

record = <|
  "Tag" -> tag,
  "Backend" -> backend,
  "Fixture" -> fixtureFile,
  "OffDiagonalBlockDimensions" -> Dimensions[offDiagonalBlockEquation[[3]]],
  "WallSeconds" -> wall,
  "ProcessorCount" -> $ProcessorCount,
  "InternalKernels" -> 1,
  "Solved" -> AssociationQ[solution] &&
    Lookup[solution, "Status", None] === "Solved",
  "BackendResult" -> solution,
  "Date" -> DateString[Now],
  "HarnessSeconds" -> AbsoluteTime[] - start
|>;

temporary = FileNameJoin[{outdir,
  "result_" <> tag <> "_" <> backend <> ".wl.partial"}];
Put[record, temporary];
RenameFile[temporary,
  FileNameJoin[{outdir, "result_" <> tag <> "_" <> backend <> ".wl"}],
  OverwriteTarget -> True];

Print["BENCH tag=", tag, " backend=", backend,
  " solved=", record["Solved"],
  " wall=", Round[wall, 0.1], " s"];
Exit[If[record["Solved"], 0, 1]]
