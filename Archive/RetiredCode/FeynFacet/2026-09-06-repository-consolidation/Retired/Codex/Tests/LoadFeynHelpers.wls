root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];

Get[FileNameJoin[{
  root, "Addon", "Mathematica_Addon", "LoadAddons.wl"
}]];

$LoadAddOns = {"FeynHelpers", "FeynCalcLegacy"};
FACETLoadAddon["FeynCalc"];

checks = <|
  "FeynCalc" -> MemberQ[$Packages, "FeynCalc`"],
  "FeynHelpers" -> ValueQ[FeynCalc`$FeynHelpersVersion],
  "FeynCalcLegacy" -> Length[DownValues[FeynCalc`Calc]] > 0
|>;

Print[checks];

If[! And @@ Values[checks], Exit[1]];
Exit[0];
