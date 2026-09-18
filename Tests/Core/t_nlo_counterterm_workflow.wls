Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
pars=<|"CA"->caTest,"CF"->cfTest,"TR"->1/2,"FlavorCount"->nfTest|>;
qTest={"q","u"};
ctSpec=<|"Spin"->"U","Variable"->xiTest,"DimensionalRegulator"->epTest,
 "KernelParameters"->pars,"PerturbativeOrder"->1,"ScaleLog"->Log[mfTest]-Log[mrTest],
 "OperatorScheme"->"MSbar","Operation"->"Factorization",
 "PoleNormalization"->Exp[epTest(Log[4Pi]-EulerGamma)]|>;
ctFinite=<|"Variable"->xiTest,"DeltaCoefficient"->0,"PlusCoefficients"-><||>,
 "RegularCoefficient"->kappaTest(1-xiTest)|>;
ctScheme=<|"FiniteKernels"-><|{qTest,qTest,"U"}->ctFinite|>|>;
ctPDF=FeynFacet`PDFCountertermDistribution[qTest,qTest,ctSpec];
ctFF=FeynFacet`FFCountertermDistribution[qTest,qTest,ctSpec];
ctChanged=FeynFacet`PDFCountertermDistribution[qTest,qTest,
 Join[ctSpec,<|"OperatorRedefinition"->ctScheme|>]];
ctZero[row_]:=FeynFacet`Private`partonicZeroTreeQ[FeynFacet`Private`partonicMap[
 Function[value,FullSimplify[value,0<xiTest<1&&mfTest>0&&mrTest>0]],row]];
ctDiff[a_,b_]:=FeynFacet`Private`partonicDistributionSum[{a,FeynFacet`Private`partonicMap[Minus,b]},1];
ctP0=FeynFacet`LeadingSplittingKernel[qTest,qTest,"U",xiTest,pars];
ctExpected=FeynFacet`Private`partonicMap[Function[value,
 Exp[epTest(Log[4Pi]-EulerGamma+Log[mrTest]-Log[mfTest])]value/epTest],ctP0];
FTTest`FTAssert["PDF and FF counterterms are explicit physical distribution objects",
 AssociationQ[ctPDF]&&AssociationQ[ctFF]&&ctPDF["Format"]==="FeynFacet-CollinearCountertermDistribution"&&
 ctPDF["Role"]==="PDF"&&ctFF["Role"]==="FF"&&
 FreeQ[{ctPDF,ctFF},_Integrate|_SeriesData|_Failure]];
FTTest`FTAssert["the exact MSbar dimensional pole factor and unequal scales survive construction",
 ctZero[ctDiff[ctPDF,ctExpected]]];
FTTest`FTAssert["finite operator redefinition has the inverse hard-coefficient sign",
 ctZero[FeynFacet`Private`partonicDistributionSum[{ctChanged,
 FeynFacet`Private`partonicMap[Minus,ctPDF],ctFinite},1]]];
ctIdentity=FeynFacet`PDFCountertermDistribution[qTest,qTest,Join[ctSpec,<|"PerturbativeOrder"->0|>]];
ctMixedIdentity=FeynFacet`FFCountertermDistribution["g",qTest,Join[ctSpec,<|"PerturbativeOrder"->0|>]];
FTTest`FTAssert["order zero is flavor-diagonal identity with no regulator dependence",
 ctIdentity["DeltaCoefficient"]===1&&ctIdentity["PlusCoefficients"]===<||>&&
 ctIdentity["RegularCoefficient"]===0&&ctZero[ctMixedIdentity]];
ctBorn=FeynFacet`CreatePartonicResult[Association@Table[j-><|
 "DeltaCoefficient"->(j+1)alphaTest^2(1+vTest^2)/(sTest^2 vTest(vTest-1)^2),
 "PlusCoefficients"-><||>,"RegularCoefficient"->0|>,{j,0,2}],
 <|"Order"->"LO","Contribution"->"Born","Scale"->sTest,"Variables"->{vTest,wTest},"CouplingPower"->2,
 "MandelstamVariables"->{sTest,tTest,uTest},"DimensionalRegulator"->epTest,
 "DimensionalPrefactor"->mrTest^(2epTest),"RenormalizationStage"->"Bare"|>];
ctRequest=<|"Convolution"->"InvariantSingleInclusive","Scale"->sTest,"Variables"->{vTest,wTest},
 "Leg"->"IncomingA","PerturbativeParameter"->alphaTest/(2Pi),"EpsilonRange"->{-1,1}|>;
ctApplied=FeynFacet`ApplyCountertermDistribution[ctBorn,ctPDF,ctRequest];
ctCustom=FeynFacet`ApplyCountertermDistribution[ctBorn,ctChanged,Join[ctRequest,<|"EpsilonRange"->{-1,0}|>]];
FTTest`FTAssert["a finite scheme does not silently define positive-epsilon coefficients",
 FailureQ[FeynFacet`ApplyCountertermDistribution[ctBorn,ctChanged,ctRequest]]];
FTTest`FTAssert["distribution insertion retains the common exact Born dimensional prefactor",
 AssociationQ[ctApplied]&&ctApplied["DimensionalPrefactor"]===mrTest^(2epTest)&&
 ctApplied["EpsilonRange"]==={-1,1}];
FTTest`FTAssert["finite scheme leaves the pole unchanged after the physical convolution",
 AssociationQ[ctCustom]&&ctZero[ctDiff[ctApplied["Coefficients"][-1],ctCustom["Coefficients"][-1]]]];
FTTest`FTAssert["factorization logarithm equals minus the pole coefficient",
 AssociationQ[ctApplied]&&Factor[Coefficient[ctApplied["Coefficients"][0]["RegularCoefficient"],Log[mfTest]]+
 ctApplied["Coefficients"][-1]["RegularCoefficient"]]===0];
ctShort=FeynFacet`CreatePartonicResult[KeyTake[ctBorn["Coefficients"],{0,1}],ctBorn];
FTTest`FTAssert["a pole insertion requesting epsilon one rejects a Born source ending at epsilon one",
 FailureQ[FeynFacet`ApplyCountertermDistribution[ctShort,ctPDF,ctRequest]]];
FTTest`FTAssert["raw factorization rejects a finite renormalized hard source",
 FailureQ[FeynFacet`ApplyCountertermDistribution[Join[ctBorn,<|"RenormalizationStage"->"Renormalized"|>],ctPDF,ctRequest]]];
ctObserved=FeynFacet`ApplyCountertermDistribution[ctBorn,ctFF,Join[ctRequest,<|"Leg"->"Observed"|>]];
FTTest`FTAssert["the observed insertion uses the dimensional FF Jacobian and is explicit",
 AssociationQ[ctObserved]&&FreeQ[ctObserved["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient]&&
 ctObserved["Coefficients"][0]["RegularCoefficient"]=!=ctApplied["Coefficients"][0]["RegularCoefficient"]];
ctSimpleBorn=FeynFacet`CreatePartonicResult[<|
 0-><|"DeltaCoefficient"->alphaTest^2/(sTest vTest),"PlusCoefficients"-><||>,"RegularCoefficient"->0|>,
 1-><|"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>,ctBorn];
ctMix=FeynFacet`ApplyCountertermDistribution[ctSimpleBorn,
 FeynFacet`FFCountertermDistribution[qTest,"g",ctSpec],
 Join[ctRequest,<|"Leg"->"Observed","EpsilonRange"->{-1,0}|>]];
ctFraction=1-vTest+vTest wTest;
ctMixPole=alphaTest^3/(2Pi)*pars["TR"](ctFraction^2+(1-ctFraction)^2)/(sTest ctFraction);
If[AssociationQ[ctMix],
 ctMixPoleResidual=Cancel[Together[ctMix["Coefficients"][-1]["RegularCoefficient"]-ctMixPole]];
 ctMixFiniteResidual=Factor[Cancel[Together[ctMix["Coefficients"][0]["RegularCoefficient"]-
  ctMixPole(Log[4Pi]-EulerGamma+Log[mrTest]-Log[mfTest]+2Log[ctFraction])]]];
 If[ctMixPoleResidual=!=0||FullSimplify[ctMixFiniteResidual]=!=0,
  Print["FF POLE RESIDUAL ",ctMixPoleResidual];Print["FF FINITE RESIDUAL ",ctMixFiniteResidual]]];
FTTest`FTAssert["the off-diagonal FF insertion retains its exact dimensional Jacobian in the finite coefficient",
 AssociationQ[ctMix]&&ctMixPoleResidual===0&&FullSimplify[ctMixFiniteResidual]===0];
ctEpsilonFinite=Join[ctFinite,<|"RegularCoefficient"->kappaTest/epTest|>];
FTTest`FTAssert["a finite operator redefinition cannot hide another epsilon pole",
 FailureQ[FeynFacet`PDFCountertermDistribution[qTest,qTest,
  Join[ctSpec,<|"OperatorRedefinition"->ctEpsilonFinite|>]]]];
FTTest`FTReport[];
