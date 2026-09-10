$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[pe,pr,ps];
series[value_,high_]:=<|"LaurentLowerBound"->0,"KnownThroughOrder"->high,
 "Coefficients"->Association@Table[k->Coefficient[Normal[Series[value,{pe,0,high}]],pe,k],{k,0,high}],
 "ExactInEpsilon"->False|>;
density=(1+pr+ps+pr ps)/(pr ps)Exp[-pe Log[pr]-2pe Log[ps]];
data=<|"DimensionalRegulator"->pe,"NormalVariables"->{pr,ps},"Powers"->{-1-pe,-1-2pe},
 "Intervals"->{{0,1},{0,1}},"BulkSeries"->series[density,0],
 "FaceSeries"-><|{1}->series[(1+ps)/ps Exp[-2pe Log[ps]],1],
 {2}->series[(1+pr)/pr Exp[-pe Log[pr]],1],{1,2}->series[1,2]|>,
 "ProjectionConditions"-><|"JointlyIntegrableSubtractedStrata"->True,"UniformMeromorphicContinuation"->True,
 "CompleteNonintegrableDivisorTerms"->True,"Justification"-><|"ExactPolynomialIdentity"->True|>|>|>;
got=FeynFacet`AssembleProjectedEndpointDistributions[data,<|"ThroughOrder"->0|>];
direct=FeynFacet`ExtractEndpointDistributions[
 Join[KeyTake[data,{"DimensionalRegulator","NormalVariables","Powers","Intervals"}],
 <|"EndpointGeometry"->"NormalCrossings","EndpointConditions"-><|"JointlySmoothFactors"->True,
 "UniformEpsilonExpansion"->True,"NoOtherSingularities"->True|>,
 "Terms"->{<|"Powers"->data["Powers"],"SmoothFactor"->(1+pr)(1+ps)|>}|>],<|"ThroughOrder"->0|>];
FTAssert["projected strata equal direct smooth tensor expansion",
 AssociationQ[got]&&And@@Table[Expand[got["Coefficients"][k]-direct["Coefficients"][k]]===0,{k,-2,0}]];
FTAssert["the full double-subtracted regular remainder is retained",
 got["Strata"][[1,"SubtractedProfileCoefficients"]][0]//Simplify//(#===1&)];
bad=data;bad["FaceSeries"]=Join[bad["FaceSeries"],<|{1,2}->series[1,1]|>];
FTAssert["a missing corner epsilon order is rejected",
 MatchQ[FeynFacet`AssembleProjectedEndpointDistributions[bad,<|"ThroughOrder"->0|>],
 Failure["InsufficientProjectedEndpointOrders",_]]];
FTAssert["unverified joint L1 claims are rejected",
 FailureQ[FeynFacet`AssembleProjectedEndpointDistributions[KeyDrop[data,"ProjectionConditions"],<|"ThroughOrder"->0|>]]];
FTAssert["missing open edge is rejected",
 FailureQ[FeynFacet`AssembleProjectedEndpointDistributions[
 Join[data,<|"FaceSeries"->KeyDrop[data["FaceSeries"],{{1}}]|>],<|"ThroughOrder"->0|>]]];
logA=Exp[-pe Log[ps]]Log[ps];logB=Exp[-pe Log[pr]]Log[pr];
pR=Exp[-2pe Log[pr]]/pr;pS=Exp[-2pe Log[ps]]/ps;
logDensity=pR pS+pR logA+pS logB+logA logB;
logData=Join[data,<|"Powers"->{-1-2pe,-1-2pe},"BulkSeries"->series[logDensity,0],
 "FaceSeries"-><|{1}->series[pS+logA,1],{2}->series[pR+logB,1],{1,2}->series[1,2]|>|>];
logResult=FeynFacet`AssembleProjectedEndpointDistributions[logData,<|"ThroughOrder"->0|>];
FTAssert["integrable logarithmic edge factors are never evaluated at the corner",
 AssociationQ[logResult]&&FreeQ[logResult,_DirectedInfinity|Indeterminate]];
FTAssert["logarithmic nonsmooth strata give the independent finite constant moment",
 FeynFacet`EndpointDistributionAction[Expand[logResult["Coefficients"][0]],1,<|pr->{0,1},ps->{0,1}|>]===3];
second=Join[data,<|"Powers"->{-1-3pe,-1-4pe},"BulkSeries"->series[
 (1+pr)(1+ps)/(pr ps)Exp[-3pe Log[pr]-4pe Log[ps]],0],
 "FaceSeries"-><|{1}->series[(1+ps)/ps Exp[-4pe Log[ps]],1],
 {2}->series[(1+pr)/pr Exp[-3pe Log[pr]],1],{1,2}->series[1,2]|>|>];
secondResult=FeynFacet`AssembleProjectedEndpointDistributions[second,<|"ThroughOrder"->0|>];
combinedData=Join[KeyDrop[data,{"Powers","FaceSeries"}],<|"ProfileGroups"->{
 KeyTake[data,{"Powers","FaceSeries"}],KeyTake[second,{"Powers","FaceSeries"}]},
 "BulkSeries"->series[density+(1+pr)(1+ps)/(pr ps)Exp[-3pe Log[pr]-4pe Log[ps]],0]|>];
combined=FeynFacet`AssembleProjectedEndpointDistributions[combinedData,<|"ThroughOrder"->0|>];
FTAssert["different regulator powers share one complete bulk subtraction",
 AssociationQ[combined]&&And@@Table[
 Expand[combined["Coefficients"][k]-got["Coefficients"][k]-secondResult["Coefficients"][k]]===0,{k,-2,0}]];
FTAssert["the merged ordinary remainder contains both complete densities",
 Simplify[First[combined["Strata"]]["SubtractedProfileCoefficients"][0]]===2];
FTReport[];
