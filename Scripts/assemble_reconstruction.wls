(* Reassembly of per-master coefficients from ratracer/FireFly result
   files.  A reconstruction directory holds one or more rec_*.txt files,
   each a sequence of blocks

     <expression-file-path> =
       <rational function in alias variables>;

   or, for an eps-truncated (to-series) run,

     ORDER[<expression-file-path>,<alias>^<n>] =
       <rational function in alias variables>;

   covering a subset of the trace outputs (a long run is normally split
   so that the heavy columns reconstruct separately).  This script
   parses whatever is present and writes the intermediate artifact
   AssembledCoefficients.wl; it deliberately stops short of the
   production CoefficientResult format, which needs the full column set
   plus the root-freedom and cut certifications - use
   FeynFacet`ReconstructCoefficients for that.

   Since 2026-08-13 the parser, the marker resolution and the
   signature-weighted assembly live in the package
   (FeynFacet/Private/Reduction/Reconstruction.wl); this script is the CLI over
   them and keeps the arguments it always had.

   Usage:
     wolframscript -file Scripts/assemble_reconstruction.wls \
       <reconstructionDir> [<traceDirectory>]

   The trace manifest is discovered from <reconstructionDir>, its parent
   and the parent's other children unless <traceDirectory> names it
   explicitly. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 1,
  Print["Usage: assemble_reconstruction.wls <reconstructionDir> ",
    "[<traceDirectory>]"];
  Exit[1]
];
directory = ExpandFileName[arguments[[1]]];
If[! DirectoryQ[directory],
  Print["No such directory: ", directory];
  Exit[1]
];
traceDirectory = If[Length[arguments] >= 2,
  ExpandFileName[arguments[[2]]],
  Automatic
];

tenth[value_] := N[Round[10 value]/10];

{seconds, artifact} = AbsoluteTiming @ FeynFacet`Private`reconstructionAssembledArtifact[
  directory,
  traceDirectory
];
If[! AssociationQ[artifact],
  Print["Assembly failed"];
  Exit[1]
];
Print["Assembled in ", tenth[seconds], " s"];

artifactFile = FileNameJoin[{directory, "AssembledCoefficients.wl"}];
Print["Writing ", artifactFile];
Print["  wrote in ",
  tenth[First @ AbsoluteTiming[Put[artifact, artifactFile]]],
  " s, ", tenth[FileByteCount[artifactFile]/2.^20], " MB"];

Print["SUMMARY"];
Print["  outputs parsed: ", artifact["OutputsParsed"], "/",
  artifact["OutputCount"]];
Print["  masters covered: ", Length[artifact["Covered"]], "/",
  Length[artifact["Masters"]]];
If[artifact["Partial"] =!= {},
  Print["  masters partially covered: ", Length[artifact["Partial"]], " ",
    Take[artifact["Partial"], UpTo[10]]]
];
If[artifact["Missing"] =!= {},
  Print["  masters missing: ", Length[artifact["Missing"]], " ",
    Take[artifact["Missing"], UpTo[10]]]
];
If[artifact["SeriesVariable"] =!= None,
  Print["  series in ", InputForm[artifact["SeriesVariable"]],
    " truncated at order ", artifact["SeriesTruncation"]]
];
Print["  remainder column: ",
  If[TrueQ[artifact["Remainder"] === 0], "absent", "present"]];
Print["  peak memory (MB): ", Round[MaxMemoryUsed[]/2.^20]];
