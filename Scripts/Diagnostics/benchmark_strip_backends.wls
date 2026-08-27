(* Apples-to-apples benchmark of the two deep strip-solver backends on ONE
   off-diagonal block (k,j) coupling record.

   usage:
     taskset -c <core1,core2,core3> wolframscript -file \
       benchmark_strip_backends.wls FIXTURE BACKEND OUTDIR [TAG]

   FIXTURE  a .wl file with <|"Strip" -> {e, c, bbar},
            "Variables" -> {x, y}, "Regulator" -> eps, ...|>
            (the format SolveEpsFormStripFiniteField consumes; the Maple
            backend takes the same three fields positionally).
   BACKEND  Maple | FiniteField
   OUTDIR   result directory (created if absent)
   TAG      optional label, default = fixture base name

   Protocol (recorded in TransportProductionPlan.md, 2026-08-20):
   - one Wolfram kernel, at most two external CPU cores: launch the whole
     harness under `taskset -c` with THREE cores; children inherit the
     affinity mask, so Maple and any spawned process share the budget.
     Internal parallelism is capped here: ResidueKernels -> 1,
     KernelCount -> 1.
   - no artifact replay: the finite-field backend gets a FRESH artifact
     directory so sampling, interpolation, and lifting are all re-done.
   - split timers: harness wall time per backend; the Maple result's own
     "MapleSeconds" separates the external solve from the Wolfram-side
     residue preparation (prep = wall - MapleSeconds); the finite-field
     result's own stage fields are stored verbatim.
   - acceptance is each backend's own exact both-variable residual check,
     stored verbatim; the harness never grades on shape. *)

If[Length[$ScriptCommandLine] < 4,
  Print["usage: wolframscript -file benchmark_strip_backends.wls ",
    "FIXTURE BACKEND OUTDIR [TAG]"];
  Exit[2]
];

root = DirectoryName[ExpandFileName[$InputFileName], 3];

(* Read the fixture BEFORE anything can load CANONICA: after CANONICA is
   on the context path a later Get reads bare eps/x/y into CANONICA`. *)
fixtureFile = ExpandFileName[$ScriptCommandLine[[2]]];
fixture = Quiet[Check[Get[fixtureFile], $Failed]];
If[! AssociationQ[fixture] ||
    ! SubsetQ[Keys[fixture], {"Strip", "Variables", "Regulator"}],
  Print["BENCH unreadable fixture or missing Strip/Variables/Regulator: ",
    fixtureFile];
  Exit[3]
];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

backend = $ScriptCommandLine[[3]];
If[! MemberQ[{"Maple", "FiniteField"}, backend],
  Print["BENCH backend must be Maple or FiniteField, got: ", backend];
  Exit[4]
];
outdir = ExpandFileName[$ScriptCommandLine[[4]]];
If[! DirectoryQ[outdir],
  CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
tag = If[Length[$ScriptCommandLine] >= 5, $ScriptCommandLine[[5]],
  FileBaseName[fixtureFile]];

strip = fixture["Strip"];
variables = fixture["Variables"];
regulator = fixture["Regulator"];

Print["BENCH tag=", tag, " backend=", backend,
  " dims=", Dimensions[strip[[3]]],
  " cores=", $ProcessorCount];

start = AbsoluteTime[];
result = Switch[backend,
  "Maple",
  AbsoluteTiming[
    FeynFacet`SolveResidueRationalGauge[strip, variables, regulator,
      "ResidueKernels" -> 1,
      "ScratchDirectory" -> FileNameJoin[{outdir, "scratch_" <> tag}],
      "Tag" -> tag,
      "Verbose" -> True]],
  "FiniteField",
  AbsoluteTiming[
    FeynFacet`SolveEpsFormStripFiniteField[
      <|"Strip" -> strip, "Variables" -> variables,
        "Regulator" -> regulator|>,
      "KernelCount" -> 1,
      "ArtifactDirectory" ->
        FileNameJoin[{outdir, "ff_artifacts_" <> tag <> "_" <>
          DateString[Now, {"Hour", "Minute", "Second"}]}],
      "Verbose" -> True]]
];
{wall, solution} = result;

record = <|
  "Tag" -> tag,
  "Backend" -> backend,
  "Fixture" -> fixtureFile,
  "StripDimensions" -> Dimensions[strip[[3]]],
  "WallSeconds" -> wall,
  "MapleSeconds" -> If[AssociationQ[solution],
    Lookup[solution, "MapleSeconds", Missing["NotApplicable"]],
    Missing["Failed"]],
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
  " wall=", Round[wall, 0.1], " s",
  If[NumberQ[record["MapleSeconds"]],
    " maple=" <> ToString[Round[record["MapleSeconds"], 0.1]] <>
    " s prep+check=" <>
    ToString[Round[wall - record["MapleSeconds"], 0.1]] <> " s", ""]];
Exit[If[record["Solved"], 0, 1]]
