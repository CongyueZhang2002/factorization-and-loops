(* Benchmark the two live finite-field linear-algebra implementations for
   off-diagonal basis-transformation blocks. One backend is selected per
   run and applied serially to every supplied V2 block-equation record.

   Usage:
     benchmark_off_diagonal_block_methods.wls BACKEND OUTDIR FILE...

   BACKEND is Wolfram or FLINT. Every accepted solve is independently
   checked by VerifyOffDiagonalBasisTransformationBlock. *)

If[Length[$ScriptCommandLine] < 5,
  Print["usage: benchmark_off_diagonal_block_methods.wls ",
    "(Wolfram|FLINT) OUTDIR FILE..."];
  Exit[2]
];

root = DirectoryName[ExpandFileName[$InputFileName], 3];
backend = $ScriptCommandLine[[2]];
outdir = ExpandFileName[$ScriptCommandLine[[3]]];
files = ExpandFileName /@ Drop[$ScriptCommandLine, 3];
If[! MemberQ[{"Wolfram", "FLINT"}, backend],
  Print["backend must be Wolfram or FLINT"];
  Exit[2]
];
If[! DirectoryQ[outdir],
  CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
records = FeynFacet`FamilyArtifactRead /@ files;
If[! AllTrue[records, AssociationQ],
  Print["one or more records could not be read"];
  Exit[3]
];

tsv = FileNameJoin[{outdir, ToLowerCase[backend] <> ".tsv"}];
If[! FileExistsQ[tsv],
  Export[tsv,
    "record\tdimensions\tbackend\tsolved\tmethod\tseconds\tverification\n",
    "Text"]];
writeRow[items__] := Module[{stream = OpenAppend[tsv]},
  WriteString[stream, StringRiffle[ToString /@ {items}, "\t"], "\n"];
  Close[stream]];

Do[Module[{record = records[[index]], name, dimensions, started,
    solution, verification, accepted, method, seconds},
  name = FileBaseName[files[[index]]];
  If[! SubsetQ[Keys[record],
      {"OffDiagonalBlockEquation", "Variables", "Regulator"}],
    Print["record lacks the V2 off-diagonal block-equation fields: ", name];
    writeRow[name, "?", backend, False, "InvalidRecord", 0.,
      "MissingV2Fields"];
    Continue[]];
  dimensions = Dimensions[record["OffDiagonalBlockEquation"][[3, 1]]];
  started = AbsoluteTime[];
  solution = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[
    record, "Backend" -> backend, "KernelCount" -> 1,
    "ArtifactDirectory" -> FileNameJoin[{outdir,
      "artifacts_" <> ToLowerCase[backend] <> "_" <> name}],
    "Verbose" -> False];
  seconds = Round[AbsoluteTime[] - started, 0.1];
  verification = If[AssociationQ[solution] &&
      Lookup[solution, "Status", None] === "Solved",
    FeynFacet`VerifyOffDiagonalBasisTransformationBlock[
      record, solution, "KernelCount" -> 1], <||>];
  accepted = TrueQ[Lookup[verification, "DLogFormCertified", False]];
  method = If[AssociationQ[solution],
    Lookup[solution, "Method", backend], "Failed"];
  writeRow[name, dimensions, backend, accepted, method, seconds,
    Lookup[verification, "Status", "NotRun"]];
  Print["BENCH ", backend, " ", name, " accepted=", accepted,
    " wall=", seconds, " s"],
  {index, Length[records]}];

Print["BENCH ", backend, " DONE"];
