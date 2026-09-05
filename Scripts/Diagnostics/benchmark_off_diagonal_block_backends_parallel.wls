(* Parallel benchmark of the two finite-field linear-algebra backends:
   one main
   kernel + one subkernel per (fixture, backend) job — the license-safe
   topology. Requested 2026-08-20: concurrent jobs accepted; every
   result record carries "Concurrent" -> True so the provenance states
   that these wall times include machine contention.

   usage: wolframscript -file benchmark_off_diagonal_block_backends_parallel.wls \
            OUTDIR FIXTURE ... (each fixture runs BOTH backends)

   Fixture files: <|"Family", "Sector", "LowerSector",
     "Variables" -> {x,y}, "Regulator" -> eps,
     "OffDiagonalBlockEquation" -> {e,c,inhomogeneity}|>.
   Per job: internal parallelism is capped at one worker; each backend gets a fresh artifact
   directory (no replay); acceptance is each backend's own exact
   both-variable residual check, stored verbatim. *)

If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file benchmark_off_diagonal_block_backends_parallel.wls ",
    "OUTDIR FIXTURE ..."];
  Exit[2]
];

root = DirectoryName[ExpandFileName[$InputFileName], 3];
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
Get[loader];

outdir = ExpandFileName[$ScriptCommandLine[[2]]];
fixtureFiles = ExpandFileName /@ $ScriptCommandLine[[3 ;;]];
If[! AllTrue[fixtureFiles, FileExistsQ],
  Print["BENCH-PARALLEL missing fixture: ",
    Select[fixtureFiles, ! FileExistsQ[#] &]];
  Exit[3]
];
If[! DirectoryQ[outdir],
  CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

jobs = Flatten[Table[
  <|"Fixture" -> fixture, "Backend" -> backend,
    "Tag" -> FileBaseName[fixture]|>,
  {fixture, fixtureFiles}, {backend, {"Wolfram", "FLINT"}}], 1];
Print["BENCH-PARALLEL jobs=", Length[jobs]];

launched = Quiet[LaunchKernels[Min[8, Length[jobs]]]];
Print["BENCH-PARALLEL launched ", Length[launched], " subkernels"];
With[{file = loader},
  ParallelEvaluate[(Quiet[Get[file]];), launched]];

runJob[job_Association] := Module[
  {fixture, offDiagonalBlockEquation, variables, regulator, tag, backend,
   wall, solution,
   record, resultFile},
  fixture = FeynFacet`FamilyArtifactRead[job["Fixture"]];
  If[! AssociationQ[fixture],
    Return[<|"Tag" -> job["Tag"], "Backend" -> job["Backend"],
      "Status" -> "FixtureUnreadable"|>]];
  offDiagonalBlockEquation = fixture["OffDiagonalBlockEquation"];
  variables = fixture["Variables"];
  regulator = fixture["Regulator"];
  tag = job["Tag"]; backend = job["Backend"];
  {wall, solution} = AbsoluteTiming[
      FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
        <|"OffDiagonalBlockEquation" -> offDiagonalBlockEquation,
          "Variables" -> variables, "Regulator" -> regulator|>,
        "Backend" -> backend,
        "KernelCount" -> 1,
        "ArtifactDirectory" ->
          FileNameJoin[{outdir, "ff_artifacts_" <> tag}],
        "Verbose" -> False]];
  record = <|
    "Tag" -> tag,
    "Backend" -> backend,
    "Fixture" -> job["Fixture"],
    "OffDiagonalBlockDimensions" -> Dimensions[offDiagonalBlockEquation[[3]]],
    "WallSeconds" -> wall,
    "Concurrent" -> True,
    "KernelTopology" -> "SubkernelParallel",
    "Solved" -> AssociationQ[solution] &&
      Lookup[solution, "Status", None] === "Solved",
    "BackendResult" -> solution,
    "Date" -> DateString[Now]
  |>;
  resultFile = FileNameJoin[{outdir,
    "result_" <> tag <> "_" <> backend <> ".wl"}];
  FeynFacet`FamilyArtifactWrite[record, resultFile];
  Print["BENCH-LIVE tag=", tag, " backend=", backend,
    " solved=", record["Solved"], " wall=", Round[wall, 0.1], " s",
    ""];
  KeyDrop[record, "BackendResult"]
];

start = AbsoluteTime[];
results = ParallelMap[runJob, jobs,
  Method -> "FinestGrained", DistributedContexts -> Automatic];
If[launched =!= {}, Quiet[CloseKernels[launched]]];

Do[Print["BENCH-PARALLEL tag=", row["Tag"], " backend=", row["Backend"],
  " solved=", Lookup[row, "Solved", False],
  " wall=", Round[Lookup[row, "WallSeconds", 0.], 0.1]], {row, results}];
FeynFacet`FamilyArtifactWrite[
  <|"Jobs" -> results, "ElapsedSeconds" -> AbsoluteTime[] - start,
    "Concurrent" -> True|>,
  FileNameJoin[{outdir, "benchmark_summary.wl"}]];
Print["BENCH-PARALLEL done seconds=", Round[AbsoluteTime[] - start, 0.1],
  " solved=", Count[results, r_ /; TrueQ[r["Solved"]]], "/",
  Length[jobs]];
