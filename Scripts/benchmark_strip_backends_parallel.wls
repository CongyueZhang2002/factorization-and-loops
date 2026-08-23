(* Parallel benchmark of the two deep strip-solver backends: one main
   kernel + one subkernel per (fixture, backend) job — the license-safe
   topology. Requested 2026-08-20: concurrent jobs accepted; every
   result record carries "Concurrent" -> True so the provenance states
   that these wall times include machine contention.

   usage: wolframscript -file benchmark_strip_backends_parallel.wls \
            OUTDIR FIXTURE ... (each fixture runs BOTH backends)

   Fixture files: <|"Family", "Sector", "LowerSector",
     "Variables" -> {x,y}, "Regulator" -> eps, "Strip" -> {e,c,bbar}|>.
   Per job: internal parallelism capped (ResidueKernels -> 1,
   KernelCount -> 1); the finite-field backend gets a fresh artifact
   directory (no replay); acceptance is each backend's own exact
   both-variable residual check, stored verbatim. *)

If[Length[$ScriptCommandLine] < 3,
  Print["usage: wolframscript -file benchmark_strip_backends_parallel.wls ",
    "OUTDIR FIXTURE ..."];
  Exit[2]
];

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
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
  {fixture, fixtureFiles}, {backend, {"Maple", "FiniteField"}}], 1];
Print["BENCH-PARALLEL jobs=", Length[jobs]];

launched = Quiet[LaunchKernels[Min[8, Length[jobs]]]];
Print["BENCH-PARALLEL launched ", Length[launched], " subkernels"];
With[{file = loader},
  ParallelEvaluate[(Quiet[Get[file]];), launched]];

runJob[job_Association] := Module[
  {fixture, strip, variables, regulator, tag, backend, wall, solution,
   record, resultFile},
  fixture = FeynFacet`FamilyArtifactRead[job["Fixture"]];
  If[! AssociationQ[fixture],
    Return[<|"Tag" -> job["Tag"], "Backend" -> job["Backend"],
      "Status" -> "FixtureUnreadable"|>]];
  strip = fixture["Strip"];
  variables = fixture["Variables"];
  regulator = fixture["Regulator"];
  tag = job["Tag"]; backend = job["Backend"];
  {wall, solution} = Switch[backend,
    "Maple",
    AbsoluteTiming[
      FeynFacet`SolveResidueRationalGauge[strip, variables, regulator,
        "ResidueKernels" -> 1,
        "ScratchDirectory" ->
          FileNameJoin[{outdir, "scratch_" <> tag <> "_maple"}],
        "Tag" -> tag,
        "Verbose" -> False]],
    "FiniteField",
    AbsoluteTiming[
      FeynFacet`SolveEpsFormStripFiniteField[
        <|"Strip" -> strip, "Variables" -> variables,
          "Regulator" -> regulator|>,
        "KernelCount" -> 1,
        "ArtifactDirectory" ->
          FileNameJoin[{outdir, "ff_artifacts_" <> tag}],
        "Verbose" -> False]]];
  record = <|
    "Tag" -> tag,
    "Backend" -> backend,
    "Fixture" -> job["Fixture"],
    "StripDimensions" -> Dimensions[strip[[3]]],
    "WallSeconds" -> wall,
    "MapleSeconds" -> If[AssociationQ[solution],
      Lookup[solution, "MapleSeconds", Missing["NotApplicable"]],
      Missing["Failed"]],
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
    If[NumberQ[record["MapleSeconds"]],
      " maple=" <> ToString[Round[record["MapleSeconds"], 0.1]] <> " s",
      ""]];
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
