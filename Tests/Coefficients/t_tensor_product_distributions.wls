(* Compare joint subtraction with exactly integrated regulated monomials. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tpData=<|"DimensionalRegulator"->te,"NormalVariables"->{tx,tz},
 "EndpointGeometry"->"NormalCrossings","Intervals"->{{0,1},{0,1}},
 "EndpointConditions"-><|"JointlySmoothFactors"->True,"UniformEpsilonExpansion"->True,"NoOtherSingularities"->True|>,
 "Terms"->{<|"Powers"->{-1-te,-1-2te},"SmoothFactor"->1|>}|>;
tpResult=FeynFacet`ExtractEndpointDistributions[tpData,<|"ThroughOrder"->0|>];
FTTest`FTAssert["two resolved endpoints return explicit coefficients",AssociationQ[tpResult]&&tpResult["Status"]==="ExplicitFiniteCoefficients"];
tpDx=FeynFacet`EndpointDeltaDerivative[tx,0,1];tpDz=FeynFacet`EndpointDeltaDerivative[tz,0,1];
tpPx[k_]:=FeynFacet`EndpointPlusDistribution[tx,-1,k,1,1];
tpPz[k_]:=FeynFacet`EndpointPlusDistribution[tz,-1,k,1,1];
tpExpected=<|-2->tpDx tpDz/2,-1->-tpDx tpPz[0]-tpPx[0]tpDz/2,
 0->tpPx[0]tpPz[0]+2tpDx tpPz[1]+tpPx[1]tpDz/2|>;
FTTest`FTAssert["corner edge and mixed-plus coefficients have the exact normalization",
 AssociationQ[tpResult]&&And@@Table[Expand[tpResult["Coefficients"][k]-tpExpected[k]]===0,{k,-2,0}]];
tpSmooth=(1+tx+2tz+3tx tz)(1+te+2te^2+3te^3);
tpPolynomial=Join[tpData,<|"Terms"->{<|"Powers"->{-1-te,-1-2te},"SmoothFactor"->tpSmooth|>}|>];
tpIntegrated=FeynFacet`ExtractEndpointDistributions[tpPolynomial,<|"ThroughOrder"->1|>];
tpExactMoment[test_]:=Total[Function[rule,Last[rule]/((First[rule][[1]]-te)(First[rule][[2]]-2te))]/@
 CoefficientRules[Expand[tpSmooth test],{tx,tz}]];
Do[tpSeries=Expand[Normal[Series[tpExactMoment[tpTest],{te,0,1}]]];
 FTTest`FTAssert["distribution action agrees with exact regulated moment "<>ToString[tpTest,InputForm],
 AssociationQ[tpIntegrated]&&And@@Table[
  Simplify[FeynFacet`EndpointDistributionAction[tpIntegrated["Coefficients"][k],tpTest,<|tx->{0,1},tz->{0,1}|>]-
   Coefficient[tpSeries,te,k]]===0,{k,-2,1}]],
 {tpTest,{1,tx,tz,tx tz,1+tx+tz+tx tz}}];
tpReverse=Join[tpPolynomial,<|"NormalVariables"->{tz,tx},
 "Terms"->{<|"Powers"->{-1-2te,-1-te},"SmoothFactor"->tpSmooth|>}|>];
tpReverseResult=FeynFacet`ExtractEndpointDistributions[tpReverse,<|"ThroughOrder"->1|>];
FTTest`FTAssert["interchanging the endpoint order changes no coefficient",
 AssociationQ[tpReverseResult]&&And@@Table[
  Expand[tpReverseResult["Coefficients"][k]-tpIntegrated["Coefficients"][k]]===0,{k,-2,1}]];
tpOrder=FeynFacet`DetermineEndpointDistributionOrders[tpData,<|"ThroughOrder"->0|>];
FTTest`FTAssert["corner edge and interior request distinct sufficient epsilon orders",
 AssociationQ[tpOrder]&&Lookup[First[tpOrder["TermRequirements"]]["Strata"],"RequiredSmoothFactorOrder"]==={2,1,1,0}];
tpInsufficient=<|"LaurentLowerBound"->0,"KnownThroughOrder"->1,"Coefficients"-><|0->1,1->1|>|>;
FTTest`FTAssert["an omitted smooth coefficient can never be assumed zero at the corner",
 MatchQ[FeynFacet`ExtractEndpointDistributions[Join[tpData,<|"Terms"->{<|"Powers"->{-1-te,-1-2te},"SmoothFactor"->tpInsufficient|>}|>],
 <|"ThroughOrder"->0|>],Failure["InsufficientEndpointEpsilonOrders",_]]];
tpOverlap=Join[tpData,<|"Terms"->{<|"Powers"->{-1-te,-1-2te},"SmoothFactor"->1/(tx+tz)|>}|>];
FTTest`FTAssert["an unresolved corner singularity is rejected",FailureQ[FeynFacet`ExtractEndpointDistributions[tpOverlap,<|"ThroughOrder"->0|>]]];
FTTest`FTAssert["ordinary multiplication on the same distribution axis is rejected",
 FailureQ[FeynFacet`EndpointDistributionAction[tpPx[0]^2,1+tx,<|tx->{0,1}|>]]];
tpNonunit=FeynFacet`ExtractEndpointDistributions[Join[tpData,<|"Intervals"->{{0,2},{0,3}}|>],<|"ThroughOrder"->0|>];
tpNonunitExact=Expand[Normal[Series[2^(-te)3^(-2te)/(2te^2),{te,0,0}]]];
FTTest`FTAssert["nonunit interval endpoint masses include logarithmic tails",
 AssociationQ[tpNonunit]&&And@@Table[Simplify[
  FeynFacet`EndpointDistributionAction[tpNonunit["Coefficients"][k],1,<|tx->{0,2},tz->{0,3}|>]-
  Coefficient[tpNonunitExact,te,k]]===0,{k,-2,0}]];
tpSingle=Join[tpData,<|"NormalVariables"->{tx},"Intervals"->{{0,1}},
 "Terms"->{<|"Powers"->{-1-te},"SmoothFactor"->1|>}|>];
tpSingleResult=FeynFacet`ExtractEndpointDistributions[tpSingle,<|"ThroughOrder"->0|>];
FTTest`FTAssert["one normal variable uses the same finite distribution convention",
 AssociationQ[tpSingleResult]&&tpSingleResult["Coefficients"][-1]===-tpDx&&
 tpSingleResult["Coefficients"][0]===tpPx[0]];
tpThree=Join[tpData,<|"NormalVariables"->{tx,tz,ty},"Intervals"->{{0,1},{0,1},{0,1}},
 "Terms"->{<|"Powers"->{-1-te,-1-2te,-1-3te},"SmoothFactor"->1|>}|>];
tpThreeResult=FeynFacet`ExtractEndpointDistributions[tpThree,<|"ThroughOrder"->0|>];
FTTest`FTAssert["the same construction handles a three-variable intersection",
 AssociationQ[tpThreeResult]&&Simplify[
 FeynFacet`EndpointDistributionAction[tpThreeResult["Coefficients"][0],1+tx tz ty,
  <|tx->{0,1},tz->{0,1},ty->{0,1}|>]-1]===0];
tpStored=<|"LaurentLowerBound"->0,"KnownThroughOrder"->2,
 "Coefficients"-><|0->1,1->1,2->1|>|>;
tpAudited=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ExtractEndpointDistributions[
 Join[tpData,<|"Terms"->{<|"Powers"->{-1-te,-1-2te},"SmoothFactor"->tpStored|>}|>],<|"ThroughOrder"->0|>]];
FTTest`FTAssert["joint subtraction participates in the omitted-epsilon audit",
 AssociationQ[tpAudited]&&FreeQ[tpAudited,_Failure|$Failed|$Aborted]];
FTTest`FTReport[];
