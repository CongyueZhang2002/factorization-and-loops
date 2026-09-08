(* FeynFacet symbolic construction. Optional epsilon-form algorithms
   are loaded explicitly with Get[".../FeynFacet/EpsilonForm.m"]. *)
If[System`Names["FeynCalc`$FeynCalcVersion"] === {}, Needs["FeynCalc`"]];
BeginPackage["FeynFacet`"];
ClearAll["FeynFacet`*"];
ClearAll["FeynFacet`Private`*"];
Begin["`Private`"];
$feynFacetDirectory = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{$feynFacetDirectory,"Kernel","Loader.wl"}]];
End[];
FeynFacet`Private`loadFeynFacetModules["Public"];
Begin["`Private`"];
$feynFacetEpsilon = Symbol["Global`Epsilon"];
$dimensionRule = System`D -> 4 - 2 $feynFacetEpsilon;
Get[FileNameJoin[{$feynFacetDirectory,"Kernel","Formatting.wl"}]];
loadFeynFacetModules["SolutionData"];
loadFeynFacetModules["Symbolic"];
(* Analytic-context provenance is needed by symbolic construction only.
   Standalone readers need not have the symbolic sources installed. *)
$feynFacetSourceHash = Hash[
 ({StringDrop[#,StringLength[$feynFacetDirectory]+1],FileHash[#,"SHA256"]}& /@ $feynFacetSourceFiles),
 "SHA256","HexString"];
End[];
Quiet[EndPackage[],General::shdw];
If[Length[DownValues[FeynCalc`Calc]] === 0,
  Quiet[
    Block[{FeynCalc`$FeynCalcStartupMessages = False},
      FeynCalc`FCReloadAddOns[{"FeynCalcLegacy"}]
    ],
    General::shdw
  ]
];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Print["FeynFacet: the FeynCalcLegacy add-on is required but could not be loaded."];
  Abort[]
];

Print[
  Style["FeynFacet ", "Text", Bold],
  Style["0.1", "Text"]
];
