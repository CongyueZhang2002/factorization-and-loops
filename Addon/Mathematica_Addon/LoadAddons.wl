(* Resolve third-party Mathematica packages from the FACET tree. *)

$FACETMathematicaAddonRoot =
  DirectoryName[ExpandFileName[$InputFileName]];

$FACETMathematicaAddonDirectories = <|
  "FeynCalc" -> FileNameJoin[{$FACETMathematicaAddonRoot, "FeynCalc"}],
  "FeynArts" -> FileNameJoin[{$FACETMathematicaAddonRoot, "FeynArts"}],
  "PackageX" -> FileNameJoin[{$FACETMathematicaAddonRoot, "X"}],
  "SubTropica" -> FileNameJoin[{$FACETMathematicaAddonRoot, "SubTropica"}],
  "Libra" -> FileNameJoin[{$FACETMathematicaAddonRoot, "Libra", "Source"}],
  "HPL" -> FileNameJoin[{$FACETMathematicaAddonRoot, "HPL", "HPL-2.0"}],
  "PolyLogTools" -> FileNameJoin[{$FACETMathematicaAddonRoot, "PolyLogTools"}],
  "CANONICA" -> FileNameJoin[{$FACETMathematicaAddonRoot, "CANONICA", "src"}],
  "AMFlow" -> FileNameJoin[{$FACETMathematicaAddonRoot, "AMFlow"}],
  "RationalizeRoots" -> FileNameJoin[{
    $FACETMathematicaAddonRoot, "RationalizeRoots"
  }]
|>;

$FACETMathematicaAddonEntryPoints = <|
  "FeynCalc" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["FeynCalc"], "FeynCalc.m"
  }],
  "FeynArts" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["FeynArts"], "FeynArts.m"
  }],
  "PackageX" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["PackageX"], "Kernel", "init.m"
  }],
  "SubTropica" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["SubTropica"], "Kernel", "init.m"
  }],
  "Libra" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["Libra"], "Libra.m"
  }],
  "HPL" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["HPL"], "HPL.m"
  }],
  "PolyLogTools" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["PolyLogTools"], "PolyLogTools.m"
  }],
  "CANONICA" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["CANONICA"], "CANONICA.m"
  }],
  "AMFlow" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["AMFlow"], "AMFlow.m"
  }],
  "RationalizeRoots" -> FileNameJoin[{
    $FACETMathematicaAddonDirectories["RationalizeRoots"],
    "RationalizeRoots.m"
  }]
|>;

If[! And @@ (DirectoryQ /@ Values[$FACETMathematicaAddonDirectories]),
  Print["FACET: one or more Mathematica add-on directories are missing."];
  Abort[]
];

If[! And @@ (FileExistsQ /@ Values[$FACETMathematicaAddonEntryPoints]),
  Print["FACET: one or more Mathematica add-on entry points are missing."];
  Abort[]
];

$Path = DeleteDuplicates@Join[
  {$FACETMathematicaAddonRoot},
  Values[$FACETMathematicaAddonDirectories],
  $Path
];

FeynCalc`$FeynArtsDirectory =
  $FACETMathematicaAddonDirectories["FeynArts"];

ClearAll[FACETAddonFile, FACETLoadAddon];

FACETAddonFile::name = "Unknown FACET Mathematica add-on `1`.";
FACETLoadAddon::name = FACETAddonFile::name;

FACETAddonFile[name_String] /;
    KeyExistsQ[$FACETMathematicaAddonEntryPoints, name] :=
  $FACETMathematicaAddonEntryPoints[name];

FACETAddonFile[name_String] := (
  Message[FACETAddonFile::name, name];
  $Failed
);

FACETLoadAddon[name_String] /;
    KeyExistsQ[$FACETMathematicaAddonEntryPoints, name] :=
  Get[$FACETMathematicaAddonEntryPoints[name]];

FACETLoadAddon[name_String] := (
  Message[FACETLoadAddon::name, name];
  $Failed
);
