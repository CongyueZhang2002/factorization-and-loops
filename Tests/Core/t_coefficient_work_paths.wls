$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
coefficientNestedWork=FeynFacet`Private`coefficientWorkDirectory[root<>"/ExampleProcess/Results/Validation/RunA/Reduction/KiraResult.wl"];
FTTest`FTAssert["nested coefficient work remains in its process folder",
 coefficientNestedWork===FileNameJoin[{root,"ExampleProcess","Results","CoefficientSimplification","Validation","RunA","Reduction"}]];
FTTest`FTAssert["same final folder names in distinct runs do not share scratch",
 coefficientNestedWork=!=FeynFacet`Private`coefficientWorkDirectory[root<>"/ExampleProcess/Results/Validation/RunB/Reduction/KiraResult.wl"]];
FTTest`FTReport[];
