$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
FTTest`FTAssert["native Kira honors one thread and the configured core budget",
 FeynFacet`Private`ibpKiraThreadCount[1]===1 && FeynFacet`Private`ibpKiraThreadCount[999]===FeynFacet`Private`ibpKiraThreadCount[Automatic]];
FTTest`FTAssert["FeynCalc runtime version avoids the Names shadow",
 FeynFacet`Private`packageVersion["FeynCalc`$FeynCalcVersion"]===FeynCalc`$FeynCalcVersion];
FTTest`FTReport[];
