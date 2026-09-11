Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Block[{FeynFacet`Private`finiteFieldCoefficientSimplificationCore=Function[{inputs,kira,opts},opts],
 FeynFacet`Private`coefficientRunProject=Function[{project,card,folder,opts},opts]},
 values={FeynFacet`CoefficientSimplification[{"input.wl"},"kira.wl","ReconstructionPlan"->"plan.wl"],
 FeynFacet`CoefficientSimplification["project","Real","ReconstructionPlan"->"plan.wl"],
 FeynFacet`CoefficientSimplification["project","Real","result","ReconstructionPlan"->"plan.wl"]};
 passed=AllTrue[values,AssociationQ[#]&&#["ReconstructionPlan"]==="plan.wl"&&
 #["CompactAboveBytes"]===10*2^20&&#["BundleBelowBytes"]===16*2^20&&#["CompactionEntrySeconds"]===30&]];
If[!TrueQ[passed],Print["COEFFICIENT OPTION FORWARDING FAILED ",values];Exit[1]];
Print["COEFFICIENT OPTION FORWARDING TEST PASS"];
