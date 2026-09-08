root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
tad=FeynCalc`FCTopology[tadpole,{FeynCalc`SFAD[loop]}, {loop},{},{},{}];
FTTest`FTAssert["massless tadpole is scaleless by loop scaling",TrueQ[FeynFacet`Private`dimensionalShiftScalelessByScalingQ[FeynCalc`GLI[tadpole,{1}],tad]]];
bub=FeynCalc`FCTopology[bubble,{FeynCalc`SFAD[loop],FeynCalc`SFAD[loop-p]}, {loop},{p},{},{}];
FTTest`FTAssert["a bubble with external scale is retained",!TrueQ[FeynFacet`Private`dimensionalShiftScalelessByScalingQ[FeynCalc`GLI[bubble,{1,1}],bub]]];
FTTest`FTReport[];
