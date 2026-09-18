Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
prConditions=0<prX<1&&Element[{prA,prB},Reals];
prValue=FeynFacetSolution`RealPartOnPhysicalDomain[
 prA+I prB+PolyLog[3,prX]+I PolyLog[2,-prX],prConditions];
FTTest`FTAssert["integer polylogarithms on a proven real branch participate in physical real parts",
 prValue===prA+PolyLog[3,prX]];
FTTest`FTAssert["a polylogarithm above its cut is not assumed real",
 FailureQ[FeynFacetSolution`RealPartOnPhysicalDomain[PolyLog[2,prX],prX>1]]];
FTTest`FTAssert["a complex polylogarithm argument is not assumed real",
 FailureQ[FeynFacetSolution`RealPartOnPhysicalDomain[PolyLog[3,I prX],0<prX<1]]];
FTTest`FTReport[];
