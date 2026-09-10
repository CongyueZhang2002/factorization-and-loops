
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
row[d_,p_,r_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->r|>;
meta=<|"Order"->"LO","Contribution"->"Born","Scale"->q2,"Variables"->{xx},
 "DimensionalRegulator"->ee,"DistributionBasis"-><|"Axes"->{
 <|"Variable"->xx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-xx|>}|>|>;
source=FeynFacet`CreatePartonicResult[<|0->row[1,<||>,0],1->row[2,<||>,0],2->row[3,<||>,0]|>,meta];
product=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`MultiplyPartonicLaurentFactor[source,Exp[ee ll]/ee^2,{-2,0}]];
FTTest`FTAssert["pole multiplication keeps the required positive source powers",
 product["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 Simplify[product["Result"]["Coefficients"][0]["DeltaCoefficient"]-(3+2ll+ll^2/2)]===0];
kernel=Join[row[0,<|0->Exp[ee ll]/ee^2|>,0],<|"Variable"->xx|>];
convolved=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ApplyPartonicCollinearKernel[source,kernel,xx,{-2,0}]];
FTTest`FTAssert["the Laurent convolution includes Born epsilon squared",
 convolved["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 Simplify[convolved["Result"]["Coefficients"][0]["PlusCoefficients"][0]-(3+2ll+ll^2/2)]===0];
short=FeynFacet`CreatePartonicResult[KeyTake[source["Coefficients"],{0,1}],meta];
FTTest`FTAssert["an insufficient stored Born range fails before convolution",
 FailureQ[FeynFacet`ApplyPartonicCollinearKernel[short,kernel,xx,{-2,0}]]&&
 FailureQ[FeynFacet`MultiplyPartonicLaurentFactor[short,1/ee^2,{-2,0}]]];
fault=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ApplyPartonicCollinearKernel[source,kernel,xx,{-2,0}],"TruncationOrderShift"->-1];
FTTest`FTAssert["the independent omitted-term audit catches a one-order underestimate",
 fault["EpsilonRemainderAudit"]["Status"]==="Failed"];
zero=FeynFacet`MultiplyPartonicLaurentFactor[source,1/ee,{-4,-2}];
FTTest`FTAssert["orders below the established leading power are explicit zero",
 AssociationQ[zero]&&AllTrue[Values[zero["Coefficients"]],
 #["DeltaCoefficient"]===0&&#["PlusCoefficients"]===<||>&&#["RegularCoefficient"]===0&]];
FTTest`FTReport[];
