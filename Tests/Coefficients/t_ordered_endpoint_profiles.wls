Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
normal=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->rho,"TangentialVariable"->z,"DimensionalRegulator"->ee,
 "OriginalMasterIntegralBasis"->{master},
 "NormalConnectionMatrix"->{{ee/rho+1/(1+rho)}},
 "TangentialConnectionMatrix"->{{-2ee/(1-z)-1/(2-z)}}|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"rho>0,0<z<1",
  "BranchPrescription"->"Positive real coordinates"|>];
corner=FeynFacet`PrepareSingularBoundarySystem[
 <|"Variable"->sigma,"DimensionalRegulator"->ee,
 "ConnectionMatrix"->{{2ee/sigma+1/(1+sigma)}}|>];
ordered=<|"Status"->"OrderedPhysicalBoundaryValuesDetermined",
 "RecoilVariable"->rho,"MeasurementVariable"->z,"MeasurementEndpointVariable"->sigma,
 "DimensionalRegulator"->ee,"MasterIntegralBasis"->{master},"NormalEndpointSystem"->normal,
 "PhysicalRecoilExponent"->ee,"PhysicalNormalSeedMatrix"->{{1}},
 "BoundaryConstantCount"->1,"CornerPreparation"->corner,
 "PhysicalTangentialSystem"-><|"ConnectionMatrices"->{{{-2ee/(1-z)-1/(2-z)}}}|>,
 "CornerBoundaryValues"-><|"Verification"-><|"FullExactMatchingRank"->True|>,
  "FrobeniusExpansions"-><|2ee->None|>,"NormalizedSeedMatrix"->{{1}},
  "NormalizedSeedLeftInverse"->{{1}},"InitialConstantValues"->{1}|>|>;
request=<|"KinematicRules"->{z->1-sigma},"Assumptions"->True,
 "TestFunctionSupport"-><|"ExcludedFaces"->{rho->1,sigma->1}|>|>;
prepared=FeynFacet`PrepareOrderedEndpointProfiles[ordered,
 <|"row"-><|master->1/(rho (1-z))|>|>,request];
Print["PREPARATION ",If[AssociationQ[prepared],prepared["Status"],prepared]];
FTAssert["both physical face profiles come from the same ordered constants",
 AssociationQ[prepared]&&prepared["Powers"]==={-1+ee,-1+2ee}&&
 prepared["CornerCoefficientMatrix"]==={{1}}&&
 prepared["BoundarySystems"][1]["InitialConstantValues"]==={1}&&
 prepared["BoundarySystems"][2]["InitialConstantValues"]==={1}];
FTAssert["the simple-power remainder proof checks both face collars and the joint germ",
 AssociationQ[prepared]&&prepared["ProjectionConditions"]["JointlyIntegrableSubtractedStrata"]&&
 Length[prepared["ProjectionConditions"]["Justification"]["OpenFaceCollars"]]===2];
If[AssociationQ[prepared],
 edge=FeynFacet`SolvePhysicalEndpointCoefficientJets[prepared["CoefficientJets"][1],
  <|"IntegerNormalPower"->-1,"ThroughOrder"->1|>],
 edge=prepared];
Print["EDGE ",If[AssociationQ[edge],edge["Coefficients"],edge]];
toLog[expr_]:=expr/.FeynFacetSolution`G[{0},u_]:>Log[u];
FTAssert["the general endpoint solver emits the expected finite coefficients",
 AssociationQ[edge]&&
 Simplify[toLog[edge["Coefficients"][{1,0}]]-(1+sigma)/sigma]===0&&
 Simplify[toLog[edge["Coefficients"][{1,1}]]-2(1+sigma)Log[sigma]/sigma]===0];
bad=FeynFacet`PrepareOrderedEndpointProfiles[ordered,
 <|"row"-><|master->rho (1-z)/(rho+(1-z)^2)^3|>|>,request];
FTAssert["a hidden weighted corner divergence cannot pass the direct-crossing proof",
 FailureQ[bad]];

rectangular=FeynFacet`PrepareOrderedEndpointProfiles[ordered,
 <|"row"-><|master->1/(rho (1-z))|>|>,
 Join[request,<|"Assumptions"->(0<rho<1&&0<sigma<1)|>]];
FTAssert["ordinary rectangular assumptions are separated into tangential collars",
 AssociationQ[rectangular]];
moving=FeynFacet`PrepareOrderedEndpointProfiles[ordered,
 <|"row"-><|master->1/(rho (1-z)(rho (1-z)+1-Exp[-ee]))|>|>,request];
FTAssert["an analytic generator cannot hide a regulator-dependent corner divisor",
 FailureQ[moving]&& !FreeQ[moving,"MixedAnalyticCoordinateDenominatorNotSupported"]];
interior=FeynFacet`PrepareOrderedEndpointProfiles[ordered,
 <|"row"-><|master->1/(rho (1-z)(1-16rho (1-z))^2)|>|>,request];
FTAssert["regular corner and face germs do not certify a density with an interior pole",
 FailureQ[interior]&& !FreeQ[interior,"InteriorEndpointDensityRegularityNotEstablished"]];
normalization=2^(1+ee)Gamma[1+ee];
normalizedRows=<|"row"-><|master->normalization/(rho (1-z))|>|>;
normalized=FeynFacet`PrepareOrderedEndpointProfiles[ordered,normalizedRows,request];
rescaled=ordered;
rescaled["CornerBoundaryValues"]=Join[ordered["CornerBoundaryValues"],<|
 "NormalizedSeedMatrix"->{{ee^2}},"NormalizedSeedLeftInverse"->{{1/ee^2}},
 "InitialConstantValues"->{1/ee^2}|>];
rescaled=FeynFacet`PrepareOrderedEndpointProfiles[rescaled,normalizedRows,request];
normalEdge=If[AssociationQ[normalized],FeynFacet`SolvePhysicalEndpointCoefficientJets[
 normalized["CoefficientJets"][1],<|"IntegerNormalPower"->-1,"ThroughOrder"->1|>],normalized];
scaledEdge=If[AssociationQ[rescaled],FeynFacet`SolvePhysicalEndpointCoefficientJets[
 rescaled["CoefficientJets"][1],<|"IntegerNormalPower"->-1,"ThroughOrder"->1|>],rescaled];
FTAssert["analytic normalization and Laurent seed saturation preserve physical coefficients",
 AssociationQ[normalEdge]&&AssociationQ[scaledEdge]&&
 Simplify[Values[normalEdge["Coefficients"]]-Values[scaledEdge["Coefficients"]]]==={0,0}&&
 Simplify[normalEdge["Coefficients"][{1,1}]-
  2(1+sigma)(Log[2]-EulerGamma+2Log[sigma])/sigma]===0];
cornerVector=If[AssociationQ[rescaled],FeynFacet`ExpandLaurentCoefficientVector[
 rescaled["CornerCoefficientMatrix"].rescaled["InitialConstantValues"],ee,{{0,1}}],rescaled];
FTAssert["corner coefficients retain the full analytic normalization",
 AssociationQ[cornerVector]&&cornerVector["Coefficients"][{1,0}]===2&&
 Simplify[cornerVector["Coefficients"][{1,1}]-2(Log[2]-EulerGamma)]===0];
density=<|"Coefficients"->normalizedRows|>;
bulk=<|"DensityDefinition"-><|"CoefficientRows"->normalizedRows,
 "MasterIntegralBasis"->{master},"DimensionalRegulator"->ee,"MasterKinematicRules"->{},
 "PhysicalBoundaryDefinition"->FeynFacet`OrderedPhysicalBoundaryDefinition[ordered]|>|>;
FTAssert["bulk and endpoint inputs require the same exact scalar normalization",
 FeynFacet`RequireMatchingEndpointDensity[density,ordered,bulk,request["KinematicRules"]]===True&&
 FailureQ[FeynFacet`RequireMatchingEndpointDensity[density,ordered,
  <|"DensityDefinition"->Join[bulk["DensityDefinition"],
   <|"CoefficientRows"->Map[Map[2#&],normalizedRows]|>]|>,request["KinematicRules"]]]];
zero=FeynFacet`ExpandLaurentCoefficientVector[{0},ee,{{0,2}}];
missingLow=FeynFacet`ExpandLaurentCoefficientVector[{1/ee},ee,{{0,2}}];
profile=<|"DimensionalRegulator"->ee,"NormalVariables"->{rho,sigma},
 "CoefficientRowLabels"->{"row"},"ProfileGroups"->{<|"Powers"->{-1+ee,-1+2ee},
 "FaceSeries"-><|{1}->missingLow,{2}->zero,{1,2}->zero|>|>}|>;
lowCheck=FeynFacet`CreatePartonicResultFromProfileCoefficients[zero,profile,
 <|"EpsilonRange"->{-4,0},"DistributionBasis"-><|"Axes"->{<|"Interval"->{0,1}|>,<|"Interval"->{0,1}|>}|>|>,<||>];
FTAssert["a stored profile cannot omit a known lower Laurent pole",
 MatchQ[lowCheck,Failure["MissingLowerLaurentProfileCoefficients",_]]];

degenerateRows=<|"row"-><|master->1/(parameter+rho (1-z))^2|>|>;
closedDomain=FeynFacet`PrepareOrderedEndpointProfiles[ordered,degenerateRows,
 Join[request,<|"Assumptions"->parameter>=0|>]];
openDomain=FeynFacet`PrepareOrderedEndpointProfiles[ordered,degenerateRows,
 Join[request,<|"Assumptions"->parameter>0|>]];
FTAssert["a parameter specialization may not change the certified endpoint powers",
 FailureQ[closedDomain]&&!FreeQ[closedDomain,"CornerParameterUnitsUnresolved"]&&
 AssociationQ[openDomain]];
FTAssert["a complete projection certificate requires the declared opposite-face support",
 MatchQ[FeynFacet`PrepareOrderedEndpointProfiles[ordered,
  <|"row"-><|master->1/(rho (1-z))|>|>,KeyDrop[request,"TestFunctionSupport"]],
 Failure["OppositeEndpointSupportConditionsRequired",_]]];
FTReport[];
