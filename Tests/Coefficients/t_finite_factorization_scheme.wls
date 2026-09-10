$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
fsRow[c_]:=<|"DeltaCoefficient"->c,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>;
fsTree[c_]:=<|"DeltaCoefficient"->fsRow[c],"PlusCoefficients"-><||>,"RegularCoefficient"->fsRow[0]|>;
fsQ={"q","u"};
fsScheme[var_,l_,m_]:=<|"FiniteKernelsByOrder"-><|
 1-><|{fsQ,fsQ,"U"}->Join[fsRow[l],<|"Variable"->var|>]|>,
 2-><|{fsQ,fsQ,"U"}->Join[fsRow[m],<|"Variable"->var|>]|>|>|>;
fsParameters=<|"CA"->ca,"CF"->cf,"TR"->tr,"FlavorCount"->1|>;
fsRequest=<|"PerturbativeOrder"->2,"ThroughOrder"->0,"DimensionalRegulator"->ee,
 "PerturbativeParameter"->aa,"BornCouplingPower"->2,"KernelParameters"->fsParameters,
 "FlavorClasses"-><|"Quarks"-><|"Members"->{"u"},"Multiplicity"->1|>|>,
 "Legs"->{<|"Role"->"PDF","Spin"->"U","Variable"->xx,"ScaleLog"->lf,
  "OperatorRedefinition"->fsScheme[xx,lambdaPDF,muPDF]|>,
 <|"Role"->"FF","Spin"->"U","Variable"->zz,"ScaleLog"->ld,
  "OperatorRedefinition"->fsScheme[zz,lambdaFF,muFF]|>}|>;
fsMeta=<|"Order"->"NNLO","Contribution"->"Total","Channel"->"test","Scale"->qs,
 "Variables"->{xx,zz},"DimensionalRegulator"->ee,"CouplingPower"->4,
 "DistributionBasis"-><|"Axes"->{
 <|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>,
 <|"Variable"->zz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-zz|>}|>|>;
fsSource[r_,sp_,classes_,hi_]:=FeynFacet`CreatePartonicResult[<|0->fsTree[aa^(2+r){c0,c1,c2}[[r+1]]]|>,
 Join[fsMeta,<|"Order"->{"LO","NLO","NNLO"}[[r+1]],"CouplingPower"->2+r,
 "RenormalizationStage"->"Renormalized"|>]];
fsPlan=FeynFacet`PlanFiniteFactorizationSchemeChange[{fsQ,fsQ},fsRequest];
If[!AssociationQ[fsPlan],Print[fsPlan]];
FTTest`FTAssert["finite scheme planning requests only finite coefficients and declares their source stage",
 AssociationQ[fsPlan]&&fsPlan["SourceRenormalizationStage"]==="Renormalized"&&
 AllTrue[fsPlan["Terms"],#["RequiredSourceThroughOrder"]===0&]];
fsAudit=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ApplyPartonicRenormalization[fsPlan,fsSource,fsMeta]];
If[!AssociationQ[fsAudit]||!AssociationQ[fsAudit["Result"]],Print[fsAudit]];
fsBeta=(11ca-4tr)/6;
fsExpected=aa^4(c2-(lambdaPDF+lambdaFF)c1+
 (lambdaPDF^2-muPDF+fsBeta lf lambdaPDF+lambdaFF^2-muFF+fsBeta ld lambdaFF+
  lambdaPDF lambdaFF)c0);
FTTest`FTAssert["both inverse matrices, unequal scales, and their cross term agree with direct expansion",
 AssociationQ[fsAudit["Result"]]&&
 Expand[fsAudit["Result"]["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]-fsExpected]===0];
FTTest`FTAssert["finite conversion passes the epsilon remainder audit without repeating UV subtraction",
 fsAudit["EpsilonRemainderAudit"]["Status"]==="Passed"&&FreeQ[fsAudit["Result"]["Coefficients"],ee]];
fsBare[r_,sp_,classes_,hi_]:=Join[fsSource[r,sp,classes,hi],<|"RenormalizationStage"->"Bare"|>];
FTTest`FTAssert["bare coefficients cannot be passed to a finite scheme transformation",
 FailureQ[FeynFacet`ApplyPartonicRenormalization[fsPlan,fsBare,fsMeta]]];
FTTest`FTAssert["a four-dimensional finite scheme does not invent positive epsilon coefficients",
 FailureQ[FeynFacet`PlanFiniteFactorizationSchemeChange[{fsQ,fsQ},Join[fsRequest,<|"ThroughOrder"->1|>]]]];
FTTest`FTAssert["spacelike helicity kernels cannot stand in for an undeclared timelike transformation",
 FailureQ[FeynFacet`InverseFactorizationSchemeKernel["HelicityMSbar",fsQ,fsQ,"L",xx,fsParameters,2,
 <|"Evolution"->"TimeLike","ScaleLog"->ld|>]]];
FTTest`FTReport[];
