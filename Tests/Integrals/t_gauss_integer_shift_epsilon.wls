
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geErrors=Flatten[Table[
 geParameters={1+mm,mm+bb ee,1+mm+bb ee};
 geCoefficients=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[geParameters,-2/7,ee,5];
 gePolynomial=Total[KeyValueMap[ee^#1 #2&,geCoefficients]];
 Abs[N[(Hypergeometric2F1[Sequence@@geParameters,-2/7]-gePolynomial)/.ee->1/10000,50]],
 {mm,0,3},{bb,{-1,1,2}}]];
FTTest`FTAssert["polylogarithmic Gauss coefficients match independent numerical functions for all shifts",
 Max[geErrors]<10^-21];
geCoefficients=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{3,2,3},gg,ee,3];
FTTest`FTAssert["a zero regulator slope keeps its exact removable limit",
 geCoefficients===<|0->(1-gg)^(-2),1->0,2->0,3->0|>];
FTTest`FTAssert["the uncombined logarithmic argument endpoint is refused",
 FailureQ[FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,-ee,1-ee},1,ee,3]]];
FTTest`FTReport[];
