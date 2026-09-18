Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
req=<|"DimensionalRegulator"->eps,"Variable"->t,"Assumptions"->True,"ThroughOrder"->0,
 "EndpointConditions"-><|"NoInteriorSingularities"->True,"UniformEpsilonExpansionOnCompactSubsets"->True,"RepresentationValidOnHalfOpenInterval"->True|>|>;
run[expr_]:=Module[{a=FeynFacet`ConstructAngularEndpointExpansion[expr,req]},
 If[!AssociationQ[a],Print[a];Return[a]];FeynFacet`ExtractEndpointDistributions[a,<|"ThroughOrder"->0|>]];
first=run[t^-eps/eps Hypergeometric2F1[1,1,1-eps,1-t]];
If[!AssociationQ[first],Exit[1]];
cs=First[first["Components"]]["Coefficients"];
FTTest`FTAssert["the coalescing pair retains the double-pole delta coefficient",
 Coefficient[cs[-2],FeynFacet`EndpointDeltaDerivative[t,0,1]]===-1/2];
FTTest`FTAssert["the exact angular connection supplies the finite endpoint constant",
 FullSimplify[Coefficient[cs[0],FeynFacet`EndpointDeltaDerivative[t,0,1]]+Pi^2/12]===0];
FTTest`FTAssert["the logarithmic plus coefficient keeps both dimensional powers",
 Coefficient[cs[0],FeynFacet`EndpointPlusDistribution[t,-1,1,1,1]]===-2];
raised=run[t^(-2-eps)(1+3t+t^2)];
If[!AssociationQ[raised],Exit[1]];
cs=First[raised["Components"]]["Coefficients"];
FTTest`FTAssert["raised endpoint powers have explicit derivative and ordinary delta residues",
 Together[cs[-1]+3FeynFacet`EndpointDeltaDerivative[t,0,1]-FeynFacet`EndpointDeltaDerivative[t,1,1]]===0];
massive=run[t^(-1-eps)Hypergeometric2F1[1/2,1,3/2-eps,9/25]];
If[!AssociationQ[massive],Exit[1]];
cs=First[massive["Components"]]["Coefficients"];
FTTest`FTAssert["the massive seed supplies its analytic endpoint value",
 FullSimplify[Coefficient[cs[-1],FeynFacet`EndpointDeltaDerivative[t,0,1]]+5Log[4]/6]===0];
appell=run[t^(-1-eps)/eps AppellF1[1,-eps,-eps,1-2eps,-1/2,1/3]];
If[!AssociationQ[appell],Exit[1]];
cs=First[appell["Components"]]["Coefficients"];
FTTest`FTAssert["the Appell seed receives the extra endpoint epsilon order",
 FullSimplify[Coefficient[cs[0],FeynFacet`EndpointDeltaDerivative[t,0,1]]+
  2PolyLog[2,1/3]+2PolyLog[2,-1/2]]===0];
FTTest`FTAssert["joint endpoint-dimensional poles still require a separate resolution",
 FailureQ[run[t^-eps/(t+eps)]]];
stored=FeynFacet`CreatePartonicResultFromEndpointExpansion[first,<|"Order"->"NLO","Contribution"->"Real",
 "Scale"->q2,"Variables"->{wTest},"DimensionalRegulator"->eps,"StructureFunctions"->{"Scalar"},
 "DistributionBasis"-><|"Axes"->{<|"NormalVariable"->t,"Variable"->wTest,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-wTest|>}|>|>];
FTTest`FTAssert["single and multiple endpoint engines share the same partonic storage format",
 AssociationQ[stored]&&stored["Coefficients"][-2]["DeltaCoefficient"]===-1/2&&
 stored["Coefficients"][0]["PlusCoefficients"][1]===-2];
audit=FeynFacet`WithEpsilonRemainderChecks[run[t^-eps/eps Hypergeometric2F1[1,1,1-eps,1-t]]];
FTTest`FTAssert["angular and endpoint omitted-order checks pass together",audit["EpsilonRemainderAudit"]["Status"]==="Passed"];
short=FeynFacet`WithEpsilonRemainderChecks[run[t^-eps/eps Hypergeometric2F1[1,1,1-eps,1-t]],"TruncationOrderShift"->-1];
FTTest`FTAssert["the angular endpoint audit detects one missing epsilon order",short["EpsilonRemainderAudit"]["Status"]==="Failed"];
toy=run[t^(-1-2eps)((2+3t)/eps+5+7t+eps(11+13t))];
cs=First[toy["Components"]]["Coefficients"];
expected=-11/2 FeynFacet`EndpointDeltaDerivative[t,0,1]+
 5FeynFacet`EndpointPlusDistribution[t,-1,0,1,1]-4FeynFacet`EndpointPlusDistribution[t,-1,1,1,1]+7-6Log[t];
FTTest`FTAssert["endpoint-only extra order reproduces the full finite distribution",
 Together[cs[0]-expected]===0];
normalizationDifference=run[t^(-1-2eps)(Gamma[1-eps]Gamma[1+eps]-1)/eps];
cs=First[normalizationDifference["Components"]]["Coefficients"];
FTTest`FTAssert["an evanescent interior normalization retains its finite delta",
 FullSimplify[cs[0]+Pi^2/12 FeynFacet`EndpointDeltaDerivative[t,0,1]]===0];
vanishingResidue=run[t^(-1-eps)(1+t/eps)];
FTTest`FTAssert["an endpoint residue may vanish without corrupting the remainder coverage",
 AssociationQ[vanishingResidue]&&FreeQ[vanishingResidue,_Missing|_Failure]&&
 Together[First[vanishingResidue["Components"]]["Coefficients"][-1]+FeynFacet`EndpointDeltaDerivative[t,0,1]-1]===0];
rationalEndpointRequest=Join[req,<|"Assumptions"->xx>0&&zz>0|>];
rationalEndpoint=FeynFacet`ConstructAngularEndpointExpansion[t^(-1-eps)Hypergeometric2F1[1/2,1,3/2-eps,(xx-zz)^2/(xx+zz)^2],rationalEndpointRequest];
FTTest`FTAssert["an even massive seed uses its regular signed rational root at the endpoint",
 AssociationQ[rationalEndpoint]&&FreeQ[rationalEndpoint["Terms"][[1,"TaylorCoefficients"]],Power[_,1/2]]];
FTTest`FTAssert["the rational root convention retains the diagonal value",
 Quiet[rationalEndpoint["Terms"][[1,"TaylorCoefficients",Key[0],"Coefficients",Key[0]]]/.zz->xx]===1];
Print["ANGULAR ENDPOINT TEST COMPLETE"];FTTest`FTReport[];
