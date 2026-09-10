$HistoryLength=0;$MaxExtraPrecision=50;
zeroRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[zeroRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[zeroRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
zeroData=<|"Terms"-><|FeynCalc`GLI["a",{1}]->0,FeynCalc`GLI["a",{2}]->(1/(zeroX+1)+zeroX/(zeroX+1)-1),FeynCalc`GLI["a",{3}]->1|>,"Remainder"->0|>;
zeroKept=FeynFacet`Private`linearDropZeros[zeroData,(#===0&)];
FTTest`FTAssert["structural pruning preserves an exact sum with an unsimplified zero",
 Factor[FeynFacet`Private`linearToExpression[zeroKept]-FeynFacet`Private`linearToExpression[zeroData]]===0&&Length[zeroKept["Terms"]]===2];
FTTest`FTAssert["the exact zero test remains available for final aggregation",
 Length[FeynFacet`Private`linearDropZeros[zeroData]["Terms"]]===1];
FTTest`FTAssert["spin harmonics share a single algebraic basis",
 FeynFacet`Private`partonicCollect[Cos[zeroA-zeroB]-Cos[zeroA]Cos[zeroB]-Sin[zeroA]Sin[zeroB]]===0];
FTTest`FTReport[];
