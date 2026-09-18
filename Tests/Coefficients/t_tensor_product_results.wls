$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
tpData=<|"DimensionalRegulator"->tpe,"NormalVariables"->{tpu,tpr},"Intervals"->{{0,1},{0,1}},
 "EndpointGeometry"->"NormalCrossings","EndpointConditions"-><|"JointlySmoothFactors"->True,
 "UniformEpsilonExpansion"->True,"NoOtherSingularities"->True|>,
 "Terms"->{<|"Powers"->{-1-tpe,-1-2tpe},"SmoothFactor"->1+tpu+tpr|>}|>;
tpExpansion=FeynFacet`ExtractEndpointDistributions[tpData,<|"ThroughOrder"->0|>];
tpMeta=<|"Scale"->tpQ2,"Variables"->{tpx,tpz},"DimensionalRegulator"->tpe,
 "Order"->"NNLO","Contribution"->"DoubleReal","DensityConvention"->"dimensionless current coefficient",
 "DistributionBasis"-><|"Axes"->{
  <|"NormalVariable"->tpu,"Variable"->tpx,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-tpx|>,
  <|"NormalVariable"->tpr,"Variable"->tpz,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-tpz|>}|>|>;
tpResult=FeynFacet`CreatePartonicResultFromEndpointExpansion[tpExpansion,tpMeta];
FTTest`FTAssert["two-variable endpoint expansion uses the common epsilon-indexed result",
 AssociationQ[tpResult]&&tpResult["Format"]==="FeynFacet-PartonicResult"&&tpResult["EpsilonRange"]==={-2,0}];
FTTest`FTAssert["corner coefficient preserves the two endpoint residues",
 tpResult["Coefficients"][-2]["DeltaCoefficient"]["DeltaCoefficient"]===1/2];
tpExpression[row_,{}]:=row;
tpExpression[row_,axes_List]:=With[{x=First[axes],rest=Rest[axes]},
 tpExpression[row["DeltaCoefficient"],rest]*FeynFacet`EndpointDeltaDerivative[x,0,1]+
 Total[KeyValueMap[tpExpression[#2,rest]*FeynFacet`EndpointPlusDistribution[x,-1,#1,1,1]&,row["PlusCoefficients"]]]+
 tpExpression[row["RegularCoefficient"],rest]];
FTTest`FTAssert["every edge, corner and regular term survives storage exactly",
 AllTrue[Range[-2,0],Factor[(tpExpression[tpResult["Coefficients"][#],{tpu,tpr}]/.{tpx->1-tpu,tpz->1-tpr})-
 tpExpansion["Coefficients"][#]]===0&]];
tpSum=FeynFacet`CombinePartonicResults[<|"A"->tpResult,"B"->tpResult|>,<|"Contribution"->"Total"|>];
FTTest`FTAssert["the common assembler sums all tensor-product coefficients",
 AssociationQ[tpSum]&&AllTrue[Range[-2,0],Factor[tpExpression[tpSum["Coefficients"][#],{tpu,tpr}]-
 2tpExpression[tpResult["Coefficients"][#],{tpu,tpr}]]===0&]];
tpFile=CreateTemporary[];FeynFacet`FamilyArtifactWrite[tpResult,tpFile];
FTTest`FTAssert["higher-order consumers read the same physical result with an epsilon requirement",
 AssociationQ[FeynFacet`ReadPartonicResult[tpFile,<|"EpsilonRange"->{-1,0}|>]]&&
 FailureQ[FeynFacet`ReadPartonicResult[tpFile,<|"EpsilonRange"->{-1,1}|>]]];DeleteFile[tpFile];
tpBad=tpMeta;tpBad["DistributionBasis"]=<|"Axes"->Reverse[tpMeta["DistributionBasis"]["Axes"]]|>;
FTTest`FTAssert["axis permutations require an actual corresponding change of the expansion",
 FailureQ[FeynFacet`CreatePartonicResultFromEndpointExpansion[tpExpansion,tpBad]]];
tpBad=tpResult;tpBad["Coefficients"]=<|-2->tpResult["Coefficients"][-2],0->tpResult["Coefficients"][0]|>;
FTTest`FTAssert["a missing epsilon coefficient cannot become an implicit zero in a tensor result",
 FailureQ[FeynFacet`RequirePartonicEpsilonRange[tpBad,{-2,0}]]];
tpHidden=<|0-><|"DeltaCoefficient"->0,"PlusCoefficients"-><||>,
 "RegularCoefficient"->FeynFacet`EndpointDeltaDerivative[tpu,0,1]|>|>;
FTTest`FTAssert["distribution objects cannot hide inside a regular coefficient",
 FailureQ[FeynFacet`CreatePartonicResult[tpHidden,KeyDrop[tpMeta,"DistributionBasis"]]]];
tpMapped=FeynFacet`Private`partonicMap[Function[FeynFacet`Private`x,FeynFacet`Private`x+1],
 <|"DeltaCoefficient"->0,"PlusCoefficients"-><|0->2|>,"RegularCoefficient"->3|>];
FTTest`FTAssert["named pure functions keep their parameters during recursive coefficient mapping",
 tpMapped===<|"DeltaCoefficient"->1,"PlusCoefficients"-><|0->3|>,"RegularCoefficient"->4|>];
tpDelta=FeynFacet`EndpointDeltaDerivative[tpr,0,1];
tpPlus=FeynFacet`EndpointPlusDistribution[tpr,-1,0,1,1];
tpCancellation=(tpa tpDelta-tpa tpr tpDelta+tpb tpPlus-tpb tpr tpPlus+Log[1-tpr])/(1-tpr);
tpCancellationExpansion=Join[tpExpansion,<|"LaurentLowerBound"->0,"Coefficients"-><|0->tpCancellation|>|>];
tpCancellationResult=FeynFacet`CreatePartonicResultFromEndpointExpansion[tpCancellationExpansion,tpMeta];
FTTest`FTAssert["removable common denominators do not obstruct already projected delta and plus coefficients",
 AssociationQ[tpCancellationResult]&&
 tpCancellationResult["Coefficients"][0]["RegularCoefficient"]["DeltaCoefficient"]===tpa&&
 tpCancellationResult["Coefficients"][0]["RegularCoefficient"]["PlusCoefficients"][0]===tpb&&
 Factor[tpCancellationResult["Coefficients"][0]["RegularCoefficient"]["RegularCoefficient"]-Log[tpz]/tpz]===0];
tpUnprojected=Join[tpExpansion,<|"LaurentLowerBound"->0,"Coefficients"-><|0->tpr tpPlus|>|>];
FTTest`FTAssert["algebraic normalization still rejects a genuinely normal-variable-dependent distribution coefficient",
 MatchQ[FeynFacet`CreatePartonicResultFromEndpointExpansion[tpUnprojected,tpMeta],
  Failure["EndpointCoefficientsMustBeProjected",_Association]]];
FTTest`FTReport[];
