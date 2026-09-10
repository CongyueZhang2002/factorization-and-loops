
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
values=Table[((x+y)^i-(x-y)^i)/((x+y)^2-(x-y)^2),{i,2,45}];
actual=FeynFacet`Private`cancelIndependentCoefficients[values,2];
FTTest`FTAssert["parallel rational cancellation gives the same exact rational coefficients",
 actual===(Cancel[Together[#]]&/@values)];
FTTest`FTAssert["the temporary pool is closed",Kernels[]==={}];
FTTest`FTReport[];
