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
(* The four basis names are RESERVED Global symbols.  A campaign script
   that assigns any of them (the eps-form sector driver used n/nb as
   counters until 2026-08-23) leaves a reused kernel unable to rebuild
   the basis: BuildGlobalBasis[{34, 44, xhat, yhat}] refuses.  Clearing
   own-values here makes a reload self-healing; scripts must still not
   assign these names mid-mission (t_global_basis_reload pins both). *)
If[ValueQ[Global`nb], Clear[Global`nb]];
If[ValueQ[Global`n], Clear[Global`n]];
If[ValueQ[Global`xhat], Clear[Global`xhat]];
If[ValueQ[Global`yhat], Clear[Global`yhat]];
Global`GlobalBasis = FeynFacet`BuildGlobalBasis[{
  Global`nb, Global`n, Global`xhat, Global`yhat
}];
FeynArts`$FAVerbose = 0;
