Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
FTTest`FTAssert["rational regulator factors have finite meromorphic principal parts",
 AssociationQ[FeynFacet`VerifyMeromorphicNormalization[{ee,ee^-2,(1+ee)/(1-ee)},ee,ss>0]]];
FTTest`FTAssert["reciprocal sums use their actual leading nonzero order",
 AssociationQ[FeynFacet`VerifyMeromorphicNormalization[{1/(Gamma[1+ee]-1)},ee,ss>0]]];
FTTest`FTAssert["essential regulator singularities and singular external factors remain rejected",
 FailureQ[FeynFacet`VerifyMeromorphicNormalization[{Exp[1/ee]},ee,True]]&&
 FailureQ[FeynFacet`VerifyMeromorphicNormalization[{1/(a-b)},ee,a==b]]];
Print["MEROMORPHIC NORMALIZATION TEST COMPLETE"];FTTest`FTReport[];
