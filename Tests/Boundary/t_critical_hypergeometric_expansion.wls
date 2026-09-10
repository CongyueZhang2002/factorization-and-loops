$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
hx=HypergeometricPFQ[{1,1,-hxE},{1-2hxE,1-hxE},1];
hxNative=SeriesCoefficient[hx,{hxE,0,0}];
hxBefore=UpValues[HypergeometricPFQ];
hxOut=FeynFacet`ExpandHypergeometricLaurentSeries[hx,hxE,4];
FTTest`FTAssert["the continued critical 3F2 limit differs from direct terminating substitution",
 AssociationQ[hxOut]&&hxNative===1&&Coefficient[hxOut["Polynomial"],hxE,0]===3/2];
FTTest`FTAssert["critical unit-argument coefficients are explicit through weight four",
 AssociationQ[hxOut]&&Expand[hxOut["Polynomial"]-
  (3/2-Pi^2 hxE^2/6-5Zeta[3]hxE^3-31Pi^4 hxE^4/180)]===0];
FTTest`FTAssert["vendor upvalues never enter the production kernel",UpValues[HypergeometricPFQ]===hxBefore];
hxWeighted=FeynFacet`ExpandLaurentCoefficientVector[{Gamma[-hxE]^2 hx},hxE,{{-2,0}}];
FTTest`FTAssert["a prefactor double pole requests the needed hypergeometric depth",
 AssociationQ[hxWeighted]&&hxWeighted["Coefficients"][[Key[{1,-2}]]]===3/2&&
 Simplify[hxWeighted["Coefficients"][[Key[{1,0}]]]-(3EulerGamma^2+Pi^2/12)]===0];
hxTransform=(-hxE)Gamma[-hxE]Gamma[-2hxE]/Gamma[-3hxE]*
 HypergeometricPFQ[{-2hxE,-2hxE,-hxE},{1-2hxE,-3hxE},1];
hxResiduals=Table[N[((hx-hxTransform)/.hxE->point),35],{point,{-1/3,-2/7}}];
FTTest`FTAssert["Euler integration gives an independent exact-family continuation check",
 AllTrue[hxResiduals,NumberQ[#]&&Abs[#]<10^-30&]];
FTTest`FTReport[];
