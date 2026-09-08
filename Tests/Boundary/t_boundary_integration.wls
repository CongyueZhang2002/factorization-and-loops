
root=DirectoryName[ExpandFileName[$InputFileName],3];
testScratch=CreateDirectory[];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
pass=0;failed=0;
check[name_,value_]:=If[TrueQ[value],pass++;Print["PASS ",name],failed++;Print["FAIL ",name]];
definition=<|"Representation"->"UnitCube","DimensionalRegulator"->eps,
 "Terms"->{<|"IntegrationVariables"->{x},"RegularFactor"->x^(-1+eps)(1-x)^(-1+2eps)|>}|>;
r=FeynFacet`IntegrateEulerBoundaryIntegral[definition,{-1,2}];
Print["BETA ",r];
check["divergent Beta integral evaluated",AssociationQ[r]];
If[AssociationQ[r],check["Beta Laurent pole",r["LaurentCoefficients"][-1]===3/2];
 check["Beta finite coefficient",r["LaurentCoefficients"][0]===0]];
map=<|"DimensionalRegulator"->eps,"ReductionMatrix"->{{eps^-2,eps},{0,1}},
 "BoundaryIntegralLaurentLowerBounds"->{-1,0}|>;
orders=FeynFacet`DetermineBoundaryIntegralOrders[map,{{1,0},{2,2}}];
check["pole in reduction raises demand",orders["BoundaryIntegralOrderRanges"][1]==={-1,2}];
check["second boundary range",orders["BoundaryIntegralOrderRanges"][2]==={0,2}];
problem=<|"BoundaryAmplitudeReduction"->map,"RequestedAmplitudeCoefficients"->{{1,0},{2,2}},
 "BoundaryIntegralDefinitions"-><|1->definition,2-><|"Representation"->"UnitCube",
 "Terms"->{<|"IntegrationVariables"->{},"Prefactor"->1/(1-eps)|>}|>|>|>;
r2=FeynFacet`EvaluateBoundaryIntegralSystem[problem];
Print["ASSEMBLY ",KeyDrop[r2,"EvaluatedBoundaryIntegrals"]];
check["assembly complete",r2["Status"]==="RequestedAmplitudesEvaluated"];
check["second amplitude coefficient",r2["AmplitudeLaurentCoefficients"][[Key[{2,2}]]]===1];
incomplete=FeynFacet`EvaluateBoundaryIntegralSystem[Join[problem,<|"BoundaryIntegralDefinitions"-><||>|>]];
check["missing integrals remain unresolved",Length[incomplete["AmplitudeLaurentCoefficients"]]===0];
cut=FeynFacet`IntegrateEulerBoundaryIntegral[<|"Representation"->"BaikovCut","DimensionalRegulator"->eps|>,{0,0}];
check["unresolved cuts rejected",FailureQ[cut]];
st=FeynFacet`IntegrateEulerBoundaryIntegral[<|"Representation"->"UnitCube",
 "DimensionalRegulator"->eps,"Terms"->{<|"IntegrationVariables"->{x},"RegularFactor"->x^eps/(1-x/2)|>}|>,
 {0,1},"IntegrationBackend"->Automatic,"ScratchDirectory"->testScratch,
 "Verbose"->True];
Print["SUBTROPICA ",st];
check["automatic fallback to SubTropica evaluates a non-Beta integral",AssociationQ[st]&&
 MemberQ[st["IntegrationMethods"],"SubTropicaHyperFLINT"]];
unsupportedBeta=FeynFacet`IntegrateEulerBoundaryIntegral[<|"Representation"->"UnitCube",
 "DimensionalRegulator"->eps,"Terms"->{<|"IntegrationVariables"->{x},"RegularFactor"->x^eps/(1-x/2)|>}|>,
 {0,1},"IntegrationBackend"->"GammaBeta"];
check["a non-Beta integral leaves the Beta backend explicitly",
 MatchQ[unsupportedBeta,Failure["GammaBetaIntegrationNotApplicable",_Association]]];
If[AssociationQ[st],check["SubTropica finite part",Simplify[st["LaurentCoefficients"][0]-2Log[2]]===0]];

savedOutputVariable="retained";savedContextPath=$ContextPath;
poleTest=FeynFacet`IntegrateEulerBoundaryIntegral[<|"Representation"->"UnitCube",
 "DimensionalRegulator"->eps,"Terms"->{<|"IntegrationVariables"->{x},
 "Prefactor"->eps^-2,"RegularFactor"->x^eps/(1-x/2)|>}|>,{-2,0},
 "IntegrationBackend"->"SubTropica","ScratchDirectory"->testScratch];
check["prefactor poles request sufficient integration orders",AssociationQ[poleTest]&&
 Simplify[poleTest["LaurentCoefficients"][-2]-2Log[2]]===0];
check["vendor context path restored",$ContextPath===savedContextPath&&savedOutputVariable==="retained"];


check["multiple-zeta decoder preserves signed multi-indices",
 ToExpression[FeynFacet`Private`boundaryHyperFlintMzvToken["mzv_1_1_m3"],InputForm,HoldComplete]===
 HoldComplete[HyperIntica`mzv[1,1,-3]]];
check["two-index multiple zeta is not decoded as Hurwitz zeta",
 ToExpression[FeynFacet`Private`boundaryHyperFlintMzvToken["mzv_1_m3"],InputForm,HoldComplete]===
 HoldComplete[HyperIntica`mzv[1,-3]]];

check["negative-axis dilogarithm identity removes a spurious contour sign",
 FeynFacet`Private`boundarySimplifyHyperlogConstants[
  branchSign (HyperIntica`Hlog[1,{0,-1/8}]+HyperIntica`Hlog[1,{0,9/8}]-2Log[3]^2)]===0];
DeleteDirectory[testScratch,DeleteContents->True];
Print["ASSERTIONS ",pass+failed," FAILED ",failed];If[failed>0,Exit[1],Exit[0]];
