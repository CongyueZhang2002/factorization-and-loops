(* Univariate-slice check of a reassembled master coefficient.

   The reconstruction is only trustworthy if it agrees with the trace
   input it was built from.  Comparing the two multivariate rational
   functions directly is out of reach (the inputs run to tens of MB of
   plus-concatenated contributions), but a slice is cheap: fix every
   variable but one to a random rational, and the two sides become
   univariate rational functions that must agree exactly.  A random
   rational point of a wrong identity survives with probability zero in
   exact arithmetic, so a handful of slices is a strong check.

   The original input is substituted TEXTUALLY - the alias variables are
   string-replaced by their rational values before the file is parsed -
   so the giant symbolic expression is never built.  Only the slice
   variable stays symbolic.

   Since 2026-08-13 the check itself lives in the package
   (FeynFacet/Private/Reconstruction.wl, also reachable as the
   "VerifySlices" option of FeynFacet`ReconstructCoefficients); this
   script is the CLI over it and keeps the arguments it always had.

   Usage:
     wolframscript -file Scripts/verify_reconstruction_slice.wls \
       <reconstructionDir> <masterIndex> [count]

   Exits 0 only if every slice agrees exactly. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 2,
  Print["Usage: verify_reconstruction_slice.wls <reconstructionDir> ",
    "<masterIndex> [count]"];
  Exit[1]
];
directory = ExpandFileName[arguments[[1]]];
masterIndex = ToExpression[arguments[[2]]];
count = If[Length[arguments] >= 3, ToExpression[arguments[[3]]], 3];
If[! IntegerQ[masterIndex] || masterIndex < 1 ||
    ! IntegerQ[count] || count < 1,
  Print["masterIndex and count must be positive integers"];
  Exit[1]
];

tenth[value_] := N[Round[10 value]/10];

artifactFile = FileNameJoin[{directory, "AssembledCoefficients.wl"}];
If[! FileExistsQ[artifactFile],
  Print["No AssembledCoefficients.wl in ", directory,
    " - run assemble_reconstruction.wls first"];
  Exit[1]
];
Print["Reading ", artifactFile, " (",
  tenth[FileByteCount[artifactFile]/2.^20], " MB)"];
{seconds, artifact} = AbsoluteTiming[Get[artifactFile]];
If[! AssociationQ[artifact] ||
    artifact["Format"] =!= "FeynFacet-AssembledCoefficients",
  Print["Not an assembled-coefficient artifact: ", artifactFile];
  Exit[1]
];
Print["  read in ", tenth[seconds], " s"];
If[masterIndex > Length[artifact["Masters"]],
  Print["Master index out of range: ", masterIndex, " of ",
    Length[artifact["Masters"]]];
  Exit[1]
];

outcome = FeynFacet`Private`reconstructionVerifySlices[
  artifact,
  masterIndex,
  count
];
If[! AssociationQ[outcome], Exit[1]];

Print["SUMMARY"];
Print["  master ", masterIndex, ": ", outcome["Agreed"], "/",
  outcome["Slices"], " slices agree exactly"];
If[TrueQ[outcome["Verified"]],
  Print["  VERIFIED"];
  Exit[0],
  Print["  NOT VERIFIED"];
  Exit[1]
];
