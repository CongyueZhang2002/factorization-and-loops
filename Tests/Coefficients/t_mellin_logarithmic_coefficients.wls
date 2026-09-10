$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mlRow[value_]:=<|"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->value|>;
mlRegular=(1+(1-y)^2)/y (Log[y]^2+Log[1-y]^2-2Log[y]Log[1-y])+y Log[1-y];
mlKernel=((1-y)^2+y^2)/2;
mlResult=FeynFacet`MellinConvolveDistributions[mlRow[mlRegular],mlRow[mlKernel],y];
If[!AssociationQ[mlResult],Print[System`Short[mlResult,5]]];
FTTest`FTAssert["logarithmic coefficient convolutions close after harmonic-sum shifts",
 AssociationQ[mlResult]&&FreeQ[mlResult,_MT`MTInverse|_MT`MTMellinn|_Integrate]];
mlErrors=Table[
 mlNumerical=NIntegrate[Evaluate[(mlRegular/.y->t)(mlKernel/.y->point/t)/t],
 {t,point,1},WorkingPrecision->35,AccuracyGoal->22,PrecisionGoal->22];
 Abs[N[(mlResult["RegularCoefficient"]/.y->point),30]-mlNumerical],
 {point,{2/7,5/11}}];
FTTest`FTAssert["the closed regular convolution agrees with independent direct quadrature",
 Max[mlErrors]<10^-20];
mlPlus=<|"DeltaCoefficient"->0,"PlusCoefficients"-><|0->1|>,"RegularCoefficient"->0|>;
mlFunction=Log[y]Log[1-y]/y;
mlPlusResult=FeynFacet`MellinConvolveDistributions[mlRow[mlFunction],mlPlus,y];
mlPlusError=With[{point=3/8},Abs[
 N[mlPlusResult["RegularCoefficient"]/.y->point,30]-
 (NIntegrate[Evaluate[((mlFunction/.y->point/t)/t-(mlFunction/.y->point))/(1-t)],
 {t,point,1},WorkingPrecision->35,AccuracyGoal->22,PrecisionGoal->22]+
 N[(mlFunction/.y->point)Log[1-point],30])]];
FTTest`FTAssert["the shifted-sum completion preserves the plus-distribution subtraction",
 AssociationQ[mlPlusResult]&&mlPlusError<10^-20];
FTTest`FTReport[];
