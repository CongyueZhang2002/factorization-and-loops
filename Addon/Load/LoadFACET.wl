(* Load FACET from paths relative to this file. *)

$FACETRoot = Nest[DirectoryName, ExpandFileName[$InputFileName], 3];

Get[FileNameJoin[{$FACETRoot, "Addon", "Load", "Paths.wl"}]];

$LoadFeynArts = True;
$LoadAddOns = DeleteDuplicates@Join[
  If[ValueQ[$LoadAddOns], $LoadAddOns, {}],
  {"FeynCalcLegacy", "FeynHelpers"}
];

Get[FileNameJoin[{
  $FACETRoot, "Addon", "Mathematica_Addon", "LoadAddons.wl"
}]];

If[Names["FeynCalc`$FeynCalcVersion"] === {},
  FACETLoadAddon["FeynCalc"]
];

Quiet[
  Get[FileNameJoin[{$FACETRoot, "FeynFacet", "FeynFacet.m"}]],
  General::shdw
];

FeynCalc`FCSetDiracGammaScheme["BMHV"];
Global`GlobalBasis = FeynFacet`BuildGlobalBasis[{
  Global`nb, Global`n, Global`xhat, Global`yhat
}];
FeynArts`$FAVerbose = 0;
