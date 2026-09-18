(* The direct normal-crossing case needs no sector-dependent constants.
   Every profile is derived from the same complete physical ordered germ. *)
BeginPackage["FeynFacet`"];
PrepareOrderedEndpointProfiles::usage="PrepareOrderedEndpointProfiles[orderedBoundary,coefficientRows,request] constructs both open-face jets and the joint coefficient directly when the original endpoint coordinates form a verified logarithmic normal crossing. It proves the simple-power inclusion-exclusion remainder locally and on open-face compact intervals. Unresolved divisors or higher scalar poles require further resolution and are returned explicitly.";
RequireMatchingEndpointDensity::usage="RequireMatchingEndpointDensity[coefficients,boundary,bulk,rules] checks the exact coefficient rows, physical ordered boundary and coordinate map retained by the bulk contraction before endpoint integration inputs are written.";
Begin["`Private`"];

RequireMatchingEndpointDensity[coefficients_Association,boundary_Association,bulk_Association,rules_List]:=
 Module[{definition=Lookup[bulk,"DensityDefinition",<||>],variables,images},
 If[Lookup[definition,"CoefficientRows",None]=!=Lookup[coefficients,"Coefficients",None]||
  Lookup[definition,"MasterIntegralBasis",None]=!=boundary["MasterIntegralBasis"]||
  Lookup[definition,"DimensionalRegulator",None]=!=boundary["DimensionalRegulator"]||
  Lookup[definition,"PhysicalBoundaryDefinition",None]=!=FeynFacet`OrderedPhysicalBoundaryDefinition[boundary],
  Return[Failure["BulkAndEndpointPhysicalDensityMismatch",<||>]]];
 variables=Lookup[boundary,{"RecoilVariable","MeasurementVariable"}];
 images=variables/.Lookup[definition,"MasterKinematicRules",{}]/.rules;
 If[!And@@MapThread[Cancel[#1-#2]===0&,{images,{boundary["RecoilVariable"],1-boundary["MeasurementEndpointVariable"]}}],
  Return[Failure["BulkAndEndpointCoordinateMapMismatch",<||>]]];
 True
];

endpointInteriorRegularity[intersection_,scalar_,parameters_]:=Module[
 {xs=intersection["KinematicVariables"],e=intersection["DimensionalRegulator"],field,restore,
  mixed,factors,coordinateFactors,units,bad,domain},
 {field,restore}=coefficientRationalFieldReduce[
  {intersection["ConnectionMatrices"],scalar["ScalarGaugeCoefficientMatrix"]}];
 mixed=endpointMixedAnalyticDenominators[field,restore,xs];
 If[mixed=!={},Return[Failure["MixedAnalyticCoordinateDenominatorNotSupported",
  <|"Factors"->(mixed/.restore)|>]]];
 factors=endpointDenominatorFactors[field];
 coordinateFactors=Select[factors,!FreeQ[#,Alternatives@@xs]&];
 units=Factor[#/.e->0]&/@coordinateFactors;
 domain=parameters&&And@@(0<#<1&/@xs);
 bad=Pick[coordinateFactors,(!TrueQ[FullSimplify[#!=0,domain]]&/@units),True];
 If[bad=!={},Return[Failure["InteriorEndpointDensityRegularityNotEstablished",
  <|"UnresolvedDenominatorFactors"->bad,"Domain"->domain|>]]];
 <|"Status"->"InteriorDifferentialSystemAndScalarRowsRegular",
  "Domain"->domain,"CheckedCoordinateDenominatorFactors"->coordinateFactors,
  "Argument"->"The rational connection and coefficient rows have no coordinate poles at epsilon zero on this open support. On each compact subset their denominators remain nonzero on a common epsilon disc. The physically fixed solution continues regularly there; its finite meromorphic regulator bound is fixed by the same boundary data."|>
];

PrepareOrderedEndpointProfiles[data_Association,rows_Association,request_Association]:=
 Catch[Module[{rho,z,sigma,e,basis,source,g,gi,original,connections,rules,variables,
  endpoint,intersection,matching,boundaries,jets,scalar,uniform,collars,constants,bounds,
  cornerMatrix,exponents,powers,normalRequest,cancel,check,forward,reverse,checkPowers,
  profileRows,conditions,zeroRules,proof,conditionTerms,parameters,interior,support},
 check[value_,stage_]:=If[!AssociationQ[value],
  Throw[Failure["EndpointProfilePreparationFailed",<|"Stage"->stage,"Cause"->value|>],"OrderedProfiles"],value];
 If[Lookup[data,"Status",None]=!="OrderedPhysicalBoundaryValuesDetermined",
  Throw[Failure["CompleteOrderedPhysicalBoundaryRequired",<||>],"OrderedProfiles"]];
 {rho,z,sigma,e,basis}=Lookup[data,{"RecoilVariable","MeasurementVariable",
   "MeasurementEndpointVariable","DimensionalRegulator","MasterIntegralBasis"}];
 variables={rho,sigma};rules=Lookup[request,"KinematicRules",None];
 If[!MatchQ[rules,{___Rule}]||!AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&],
  Throw[Failure["ExplicitEndpointRowsAndCoordinatesRequired",<||>],"OrderedProfiles"]];
 support=Lookup[request,"TestFunctionSupport",<||>];
 If[!AssociationQ[support]||!ListQ[Lookup[support,"ExcludedFaces",None]]||
  !ContainsAll[support["ExcludedFaces"],Thread[variables->1]],
  Throw[Failure["OppositeEndpointSupportConditionsRequired",<||>],"OrderedProfiles"]];
 conditions=Lookup[request,"Assumptions",True];
 If[!FreeQ[conditions,e],Throw[Failure["RegulatorIndependentEndpointSupportRequired",<||>],"OrderedProfiles"]];
 conditionTerms=If[Head[conditions]===And,List@@conditions,{conditions}];
 parameters=And@@Select[conditionTerms,FreeQ[#,Alternatives@@variables]&];
 If[!TrueQ[FullSimplify[conditions,parameters&&And@@(0<#<1&/@variables)]],
  Throw[Failure["NonrectangularEndpointSupportRequiresChartCoverage",<|"Assumptions"->conditions|>],"OrderedProfiles"]];
 cancel[m_]:=Module[{v=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[v],Throw[v,"OrderedProfiles"]];Partition[v,Last[Dimensions[m]]]];
 source=data["NormalEndpointSystem"];
 g=source["NormalGaugeMatrix"];gi=source["InverseNormalGaugeMatrix"];
 original={cancel[(D[g,rho]+g.source["NormalizedNormalConnectionMatrix"]).gi],
  cancel[(D[g,z]+g.source["NormalizedTangentialConnectionMatrix"]).gi]};
 connections={original[[1]],-original[[2]]}/.z->1-sigma;
 normalRequest=<|"MaximumNormalOrder"->0,"AnalyticDomain"->ToString[conditions&&0<rho<1&&0<sigma<1,InputForm],
  "BranchPrescription"->"Continuation of the physically fixed ordered boundary along positive endpoint coordinates."|>;
 endpoint=Association@Table[i->check[FeynFacet`ConstructTangentialEndpointSystem[
  <|"NormalVariable"->variables[[i]],"TangentialVariable"->variables[[3-i]],
   "DimensionalRegulator"->e,"OriginalMasterIntegralBasis"->basis,
   "NormalConnectionMatrix"->connections[[i]],"TangentialConnectionMatrix"->connections[[3-i]]|>,
   normalRequest],"NormalSystem"<>ToString[i]],{i,2}];
 (* The triangular matcher admits rho=t, sigma=r. No distant Taylor
    truncation or new boundary constant is introduced. *)
 reverse=check[FeynFacet`NormalizeEndpointIntersection[endpoint[2]],"ReversedIntersection"];
 matching=check[FeynFacet`MatchOrderedBoundaryAtMonomialCorner[reverse,data,
  <|"Variables"->{sigma,rho},"ExponentMatrix"->{{0,1},{1,0}}|>],"ReversedPhysicalMatching"];
 forward=check[FeynFacet`NormalizeEndpointIntersection[endpoint[1]],"ForwardIntersection"];
 intersection=<|1->forward,2->reverse|>;
 matching=<|2->matching,1->check[FeynFacet`TransferJointBoundaryConstants[
  reverse,forward,matching],"ForwardPhysicalMatching"]|>;
 boundaries=Association@Table[i->check[FeynFacet`ConstructPhysicalEndpointBoundarySystem[
  endpoint[i],intersection[i],matching[i]],"PhysicalBoundary"<>ToString[i]],{i,2}];
 profileRows=Map[Map[#/.rules&],rows];
 jets=Association@Table[i->check[FeynFacet`ConstructPhysicalEndpointCoefficientJets[
  endpoint[i],boundaries[i],profileRows,
  <|"DensityJacobian"->1,"IntegerOrderThrough"->-1|>],"CoefficientJets"<>ToString[i]],{i,2}];
 If[AnyTrue[Values[jets],AnyTrue[Keys[#["CoefficientMatrices"]],# < -1&]&],
  Throw[Failure["HigherEndpointPowersRequireDerivativeProfiles",<|"Jets"->jets|>],"OrderedProfiles"]];
 exponents=matching[1]["JointResidueExponents"];powers=-1+exponents;
 If[!AllTrue[powers,PolynomialQ[#,e]&&Exponent[#,e]===1&&(#/.e->0)===-1&],
  Throw[Failure["SimpleAffineRegulatedEndpointPowersRequired",<|"Powers"->powers|>],"OrderedProfiles"]];
 constants=matching[1]["InitialConstantValues"];
 bounds=FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&/@constants;
 scalar=check[FeynFacet`AnalyzeNormalCrossingScalarCoefficients[forward,profileRows,
  <|"NormalizationFactor"->rho sigma,"KinematicRules"->{}|>],"NormalizedScalarDensity"];
 uniform=check[FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[forward,matching[1],scalar,bounds,<|"Assumptions"->parameters|>],
  "JointMeromorphicEnvelope"];
 collars=Association@Table[i->check[FeynFacet`VerifyRadialEndpointCollar[
  endpoint[i],boundaries[i],profileRows,<|"KinematicRules"->{},
   "NormalizationFactor"->variables[[i]],"TangentialConditions"->(parameters&&0<variables[[3-i]]<1)|>],
  "OpenFaceEnvelope"<>ToString[i]],{i,2}];
 interior=check[endpointInteriorRegularity[forward,scalar,parameters],"InteriorRegularity"];
 zeroRules=Thread[variables->0];
 cornerMatrix=cancel[(scalar["ScalarGaugeCoefficientMatrix"]/.zeroRules).
   matching[1]["OrderedConstantToCornerVectorMatrix"]];
 proof=<|"JointlyIntegrableSubtractedStrata"->True,"UniformMeromorphicContinuation"->True,
  "CompleteNonintegrableDivisorTerms"->True,"TestFunctionSupport"->support,"Justification"-><|
   "Method"->"Analytic normal-crossing density with exact physical face restrictions",
   "UniformCornerGerm"->uniform,"OpenFaceCollars"->collars,"InteriorRegularity"->interior,
   "Assumptions"->conditions,
   "PhysicalMatchingVerification"->Map[#["Verification"]&,matching],
   "PhysicalFaceVerification"->Map[#["Verification"]&,boundaries],
   "DensityConvention"->"F=rho^(-1+lambda) sigma^(-1+mu) h(rho,sigma,epsilon), with a joint meromorphic analytic h.",
   "SubtractionIdentity"->"The constructed boundary systems are the exact restrictions h(0,sigma) and h(rho,0), by the verified full connection, physical corner seed and DE uniqueness. Subtracting both and adding h(0,0) makes h divisible by rho sigma. Each edge subtraction is divisible by its remaining coordinate.",
   "Domain"->"A neighborhood of the joint endpoint and collars over compact subsets of each open face; test functions exclude the opposite endpoints at coordinate 1.",
   "InteriorRegularityEstablished"->True|>|>;
 <|"DataType"->"OrderedEndpointProfilePreparation","Status"->"DirectNormalCrossingProfilesPrepared",
  "DimensionalRegulator"->e,"NormalVariables"->variables,"CoefficientRowLabels"->Keys[rows],
  "Powers"->powers,"EndpointSystems"->endpoint,"BoundarySystems"->boundaries,"CoefficientJets"->jets,
  "CornerCoefficientMatrix"->cornerMatrix,"InitialConstantValues"->constants,
  "ProjectionConditions"->proof,"KinematicRules"->rules|>
],"OrderedProfiles"];
End[];EndPackage[];
