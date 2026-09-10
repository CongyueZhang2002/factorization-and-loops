$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
traceGamma[index_,dimension_]:=FeynCalc`DiracGamma[FeynCalc`LorentzIndex[index,dimension],dimension];
traceTwo[dimension_]:=FeynCalc`DiracTrace[traceGamma[traceMu,dimension].traceGamma[traceNu,dimension]];
traceExamples={
 {"D-dimensional shared indices",traceTwo[D]^2,16 D},
 {"mixed physical and D-dimensional indices",traceTwo[4]traceTwo[D],64},
 {"evanescent shared indices",traceTwo[D-4]^2,16(D-4)}};
Do[traceResult=FeynFacet`Private`collinearContractAmplitude[example[[2]],True];
 FTTest`FTAssert[example[[1]],Expand[traceResult-example[[3]]]===0],{example,traceExamples}];
traceOdd=FeynCalc`DiracTrace[traceGamma[traceMu,D].traceGamma[traceNu,D].traceGamma[traceRho,D].traceGamma[traceSigma,D].FeynCalc`DiracGamma[5]];
traceResult=FeynFacet`Private`collinearContractAmplitude[traceOdd^2,True];
FTTest`FTAssert["two chiral traces retain their Levi-Civita contraction",traceResult===384];
FTTest`FTReport[];
