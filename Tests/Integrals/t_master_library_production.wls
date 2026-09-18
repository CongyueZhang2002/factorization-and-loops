Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];
SetEnvironment["FEYNFACET_MASTER_LIBRARY_DIRECTORY"->dir];
FeynFacet`$MasterIntegralLibraryMode="ReadWrite";
top=FeynCalc`FCTopology[TestBubble,
 FeynCalc`FCI[FeynCalc`SFAD[#]]&/@{ell,ell-p},{ell},{p},
 FeynCalc`FCI[{FeynCalc`SPD[p]->s}],{}];
input=<|"MasterIntegralBasis"->{FeynCalc`GLI[TestBubble,{1,1}]},
 "Topologies"->{<|"Topology"->top|>},"DimensionalRegulator"->ep,"KinematicConditions"->s>0|>;
definitions=FeynFacet`ConstructMasterIntegralDefinitions[input];
def=definitions["MasterIntegralDefinitions"][1];
first=FeynFacet`EvaluateOneLoopIntegral[def,{-1,0}];
second=FeynFacet`EvaluateOneLoopIntegral[def,{-1,1}];
FTTest`FTAssert["the analytic one-loop provider automatically stores exact functions",
 AssociationQ[first]&&KeyExistsQ[first,"LibraryStorage"]];
FTTest`FTAssert["a later request automatically expands the stored exact function",
 AssociationQ[second]&&KeyExistsQ[second,"LibraryReuse"]&&second["KnownThroughOrder"]===1];
direct=Block[{FeynFacet`$MasterIntegralLibraryMode="Disabled"},
 FeynFacet`EvaluateOneLoopIntegral[def,{-1,1}]];
FTTest`FTAssert["library coefficients equal direct one-loop coefficients",
 second["Coefficients"]===direct["Coefficients"]];
input=Append[input,"UnrelatedDifferentialSystem"->ConstantArray[1,10000]];
compact=FeynFacet`ConstructMasterIntegralDefinitions[input];
FTTest`FTAssert["source history does not propagate into integral definitions",
 compact===definitions];
FTTest`FTReport[];
