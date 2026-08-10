$FACETOtherAddonRoot = FileNameJoin[{
  Nest[DirectoryName, ExpandFileName[$InputFileName], 3],
  "Addon", "Other_Addon"
}];
$FACETKiraExecutable =
  FileNameJoin[{$FACETOtherAddonRoot, "Kira", "bin", "kira"}];
$FACETFermatExecutable =
  FileNameJoin[{$FACETOtherAddonRoot, "Kira", "bin", "fer64"}];
