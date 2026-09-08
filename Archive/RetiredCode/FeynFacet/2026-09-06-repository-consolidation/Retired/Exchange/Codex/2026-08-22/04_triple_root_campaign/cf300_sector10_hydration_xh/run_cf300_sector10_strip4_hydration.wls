#!/usr/bin/env wolframscript
(* External-only replay of one saved CF300 sector-10 strip.  The input and
   modular artifacts are copied under this benchmark directory before the
   mission is submitted; no production checkpoint or artifact is writable. *)

repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
benchDir = FileNameJoin[{exchange, "cf300_sector10_hydration_xh"}];
scratch = FileNameJoin[{benchDir, "scratch"}];
inputFile = FileNameJoin[{scratch, "CF300_10_4_input.wl"}];
artifactDir = FileNameJoin[{scratch, "CF300_10_4_finite_field"}];
resultFile = FileNameJoin[{benchDir,
  "cf300_sector10_strip4_hydration_result.wl"}];
liveDir = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-23", "CF300", "sector_CF300_standard"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
If[! FileExistsQ[inputFile] || ! DirectoryQ[artifactDir], Exit[2]];
input = FeynFacet`FamilyArtifactRead[inputFile];
If[! AssociationQ[input], Exit[3]];

hashDirectory[dir_] := Association@Table[
  FileNameTake[file] -> FileHash[file, "SHA256", "HexString"],
  {file, Sort[FileNames["*.wl", dir]]}];
beforeHashes = hashDirectory[artifactDir];
beforeNames = Keys[beforeHashes];
memoryBefore = MemoryInUse[];
frame = FeynFacet`TransportFamilyChart["CF300"];

Print["HYDRATE starting isolated CF300 (10,4); cached files=", beforeNames];
{solveSeconds, solution} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripInFrame[
    input["Strip"], input["Variables"], input["Regulator"], frame,
    "FiniteFieldFirst" -> True,
    "FiniteFieldOptions" -> {
      "KernelCount" -> 1,
      "FinalCheck" -> "Numerical",
      "Verbose" -> True},
    "ScratchDirectory" -> scratch,
    "Tag" -> "CF300_10_4",
    "Verbose" -> True]];
memoryAfterSolve = MemoryInUse[];
afterHashes = hashDirectory[artifactDir];

gauge = If[AssociationQ[solution],
  Lookup[solution, "Gauge", Missing["NoGauge"]], Missing["NoSolution"]];
dimensions = If[ListQ[gauge], Dimensions[gauge], {}];
residueOwner = If[AssociationQ[solution] &&
    AssociationQ[Lookup[solution, "InnerSolution", None]],
  solution["InnerSolution"], solution];
residues = If[AssociationQ[residueOwner],
  Lookup[residueOwner, "ResidueMatrices", Missing["NoResidues"]],
  Missing["NoResidues"]];
{formSeconds, solvedForm} = AbsoluteTiming[
  If[MatchQ[dimensions, {_Integer, _Integer}],
    FeynFacet`Private`familyRowGaugeDLogForm[solution,
      input["Variables"], input["Regulator"], dimensions],
    Missing["GaugeDimensions"]]];

sectorCensus = Table[
  candidateFile = FileNameJoin[{liveDir,
    "CF300_10_" <> ToString[nlow] <> "_input.wl"}];
  candidate = FeynFacet`FamilyArtifactRead[candidateFile];
  candidateArtifactDir = FileNameJoin[{liveDir,
    "CF300_10_" <> ToString[nlow] <> "_finite_field"}];
  <|"LowerSector" -> nlow,
    "InputBytes" -> FileByteCount[candidateFile],
    "ZeroForcing" -> AllTrue[Flatten[candidate["Strip"][[3]]],
      SameQ[#, 0] &],
    "CachedPrimeCount" -> If[DirectoryQ[candidateArtifactDir],
      Length[FileNames["*_mod_*.wl", candidateArtifactDir]], 0]|>,
  {nlow, 9}];

checks = <|
  "Solved" -> AssociationQ[solution] &&
    Lookup[solution, "Status", None] === "Solved",
  "ProductionCertificate" -> AssociationQ[solution] &&
    MemberQ[{"NumericalResidual", "ExactDLog"},
      Lookup[solution, "Certificate", None]],
  "GaugeAvailable" -> MatrixQ[gauge],
  "ResidueMatricesAvailable" -> ListQ[residues],
  "SolvedFormRebuilt" -> ListQ[solvedForm] &&
    Dimensions[solvedForm] === Prepend[dimensions, 2],
  "CopiedArtifactSetPreserved" -> beforeNames === Keys[afterHashes],
  "CopiedArtifactHashesPreserved" -> beforeHashes === afterHashes|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status, "Purpose" -> "LegacyCheckpointHydration",
  "Family" -> "CF300", "Sector" -> 10, "LowerSector" -> 4,
  "Isolation" -> <|"Input" -> inputFile,
    "ArtifactDirectory" -> artifactDir,
    "LiveDirectoryReadOnly" -> liveDir|>,
  "Checks" -> checks, "SolveSeconds" -> solveSeconds,
  "SolvedFormBuildSeconds" -> formSeconds,
  "SolutionSummary" -> If[AssociationQ[solution],
    KeyTake[solution, {"Status", "Method", "Certificate", "ExactDLog",
      "RootIndices", "Alphabet", "FrameCertificate"}], solution],
  "GaugeDimensions" -> dimensions,
  "ResidueMatrixCount" -> If[ListQ[residues], Length[residues], 0],
  "SolvedFormLeafCount" -> If[ListQ[solvedForm], LeafCount[solvedForm], 0],
  "SolvedFormByteCount" -> If[ListQ[solvedForm], ByteCount[solvedForm], 0],
  "CopiedArtifactHashesBefore" -> beforeHashes,
  "CopiedArtifactHashesAfter" -> afterHashes,
  "Sector10Census" -> sectorCensus,
  "CachedNonzeroStripCount" -> Count[sectorCensus,
    a_Association /; ! TrueQ[a["ZeroForcing"]] &&
      a["CachedPrimeCount"] >= 3],
  "MemoryBytes" -> <|"Before" -> memoryBefore,
    "AfterSolve" -> memoryAfterSolve, "MaxMemoryUsed" -> MaxMemoryUsed[]|>,
  "ProductionCheckpointTouched" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["HYDRATE RESULT ", KeyTake[record,
  {"Status", "Checks", "SolveSeconds", "SolvedFormBuildSeconds",
   "GaugeDimensions", "ResidueMatrixCount", "CachedNonzeroStripCount"}],
  " written=", resultFile];
Clear[input, solution, gauge, residues, solvedForm, candidate, record];
Exit[If[status === "OK", 0, 1]];
