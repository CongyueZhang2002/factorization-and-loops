(* Complete ordered physical boundary construction for measured massless
   three-particle integrals, from common normalized definitions and a DE. *)
BeginPackage["FeynFacet`"];
ConstructMeasuredMasterBoundaryValues::usage =
 "ConstructMeasuredMasterBoundaryValues[system,request] derives ordered recoil/measurement endpoint data for a complete unit-cut master system, eliminates physically excluded modes, evaluates analytic corner coefficients, and fixes every surviving Frobenius amplitude by full-rank physical matching.";
Begin["`Private`"];
ConstructMeasuredMasterBoundaryValues[input_Association,request_Association] := Catch[Module[
 {system,definitions,variables,e,source,z,rho,sigma,curve,rules,assumptions,parameters,
  fraction,charts=<||>,boundaries=<||>,corners=<||>,timings=<||>,value,seconds,
  slopes,exponent,a,endpoint,sector,orders,lo,depth,observables,zeros,restricted,
  cornerSystem,cornerPreparation,matching,normalEmbedding,j,n,k,progress,check},
 progress[text_]:=If[TrueQ[Lookup[request,"Verbose",False]],Print[text]];
 check[x_]:=If[FailureQ[x],Throw[x,"CutFamily"]];
 system=solutionNormalizeDifferentialSystem[input];check[system];
 variables=system["KinematicVariables"];e=system["DimensionalRegulator"];
 {source,z,rho,sigma}=Lookup[request,{"RecoilSourceVariable","MeasurementVariable",
   "RecoilVariable","MeasurementEndpointVariable"},None];
 rules=Lookup[request,"RecoilSubstitution",{}];assumptions=Lookup[request,"Assumptions",True];
 If[Length[variables]=!=2||!MatchQ[{source,z,rho,sigma},{_Symbol,_Symbol,_Symbol,_Symbol}]||
   !DuplicateFreeQ[{source,z,rho,sigma}]||!ContainsAll[variables,{source,z}]||
   !MatchQ[rules,{_Rule}]||First[First[rules]]=!=source,
  cutFamilyFail["TwoCoordinateMeasuredRecoilRequestRequired"]];
 curve=source/.rules;
 If[!FreeQ[curve,source]||epsOrderZero[D[curve,rho]],cutFamilyFail["InvertibleNormalCoordinateRequired"]];
 parameters=Lookup[request,"AngularParameters",Table[Unique["angularParameter"],{3}]];
 fraction=Lookup[request,"AngularFractionSymbol",Unique["angularFraction"]];
 definitions=FeynFacet`ConstructMasterIntegralDefinitions[input];check[definitions];
 definitions=definitions["MasterIntegralDefinitions"];n=Length[definitions];
 progress["Constructing normalized physical charts and uniform recoil limits."];
 {seconds,value}=AbsoluteTiming[
  Do[
   value=FeynFacet`ConstructMeasuredThreeParticleIntegral[definitions[j],
    <|"Parameters"->parameters,"AngularAxis"->"TaggedParticle","AngularFractionSymbol"->fraction|>];
   check[value];AssociateTo[charts,j->value];
   value=FeynFacet`ConstructMeasuredRecoilBoundaryIntegral[value,
    <|"NormalVariable"->rho,"SourceVariableSubstitution"->rules,"Assumptions"->assumptions|>];
   check[value];AssociateTo[boundaries,j->value],
  {j,Keys[definitions]}]];
 AssociateTo[timings,"PhysicalChartsAndRecoilLimits"->seconds];
 slopes=DeleteDuplicates[Lookup[Values[boundaries],"RegulatorSlope"]];
 If[Length[slopes]=!=1,cutFamilyFail["CommonPhysicalRecoilSlopeRequired"]];
 exponent=e First[slopes];a=Normal/@system["ConnectionMatrices"];
 {seconds,endpoint}=AbsoluteTiming[FeynFacet`ConstructTangentialEndpointSystem[
  <|"NormalVariable"->rho,"TangentialVariable"->z,"DimensionalRegulator"->e,
   "NormalConnectionMatrix"->((a[[First[FirstPosition[variables,source]]]]/.rules)D[curve,rho]),
   "TangentialConnectionMatrix"->((a[[First[FirstPosition[variables,z]]]]+
     D[curve,z]a[[First[FirstPosition[variables,source]]]])/.rules),
   "OriginalMasterIntegralBasis"->system["MasterIntegralBasis"]|>,
  <|"MaximumNormalOrder"->0,"AnalyticDomain"->"Positive recoil distance near zero at fixed interior measured fraction.",
   "BranchPrescription"->"Positive real endpoint distances; meromorphic dimensional continuation."|>,
  "ParameterVerificationRules"->Lookup[request,"ParameterVerificationRules",{}],
  "Verbose"->Lookup[request,"Verbose",False]]];
 check[endpoint];AssociateTo[timings,"NormalEndpointSystem"->seconds];
 lo=First[endpoint["OriginalNormalOrderRange"]];
 orders=Cancel[#["NormalExponent"]-exponent]&/@Values[boundaries];
 If[!AllTrue[orders,IntegerQ],cutFamilyFail["IntegerPhysicalRecoilOnsetsRequired"]];
 depth=Max[0,Max[orders]-lo];
 {seconds,endpoint}=AbsoluteTiming[FeynFacet`ExtendTangentialEndpointSystem[endpoint,depth]];
 check[endpoint];AssociateTo[timings,"NormalEndpointExtension"->seconds];
 sector=FeynFacet`ConstructEndpointSectorDifferentialSystem[endpoint,exponent];check[sector];
 observables=Table[sector["OriginalCoefficientMatrices"][[orders[[j]]-lo+1,1,j]],{j,n}];
 zeros=Flatten[Table[
  Table[sector["OriginalCoefficientMatrices"][[k-lo+1,1,j]],{k,lo,orders[[j]]-1}],
  {j,n}],1];
 restricted=FeynFacet`RestrictDifferentialSystemToRelations[sector,zeros,
  <|"ValidationPoints"->Lookup[request,"TangentialValidationPoints",{}],
   "RelationProvenance"->"Coefficients below the independently established physical recoil onsets vanish."|>];
 check[restricted];
 observables=Map[Together,observables.restricted["SolutionEmbedding"],{2}];
 normalEmbedding=Map[Together,sector["NormalizedLeadingVectorEmbedding"].
   restricted["SolutionEmbedding"],{2}];
 progress["Constructing the second endpoint for "<>ToString[restricted["Dimension"]]<>" boundary functions."];
 cornerSystem=<|"Variable"->sigma,"DimensionalRegulator"->e,
  "ConnectionMatrix"->(-First[restricted["ConnectionMatrices"]]/.z->1-sigma)|>;
 {seconds,cornerPreparation}=AbsoluteTiming[FeynFacet`PrepareSingularBoundarySystem[cornerSystem,
  "Verbose"->Lookup[request,"Verbose",False]]];
 check[cornerPreparation];AssociateTo[timings,"CornerPreparation"->seconds];
 {seconds,corners}=AbsoluteTiming[AssociationMap[
  FeynFacet`ConstructMeasuredCornerBoundaryTerms[boundaries[#],
   KeyTake[request,{"MaximumOrdinarySeriesOrder"}]]&,Keys[boundaries]]];
 If[!AllTrue[Values[corners],AssociationQ],
  cutFamilyFail["PhysicalCornerCoefficientConstructionFailed",<|"Failures"->Select[corners,FailureQ]|>]];
 AssociateTo[timings,"AnalyticCornerCoefficients"->seconds];
 {seconds,matching}=AbsoluteTiming[FeynFacet`MatchPhysicalBoundaryCoefficients[cornerPreparation,
  <|"ObservableMatrix"->(observables/.z->1-sigma),"PhysicalCoefficients"->corners,
   "ValidationPoints"->Lookup[request,"CornerValidationPoints",{}],
   "PhysicalCoefficientProvenance"->"Analytic spherical convolution of the original normalized momentum-space integrals.",
   "Verbose"->Lookup[request,"Verbose",False]|>]];
 check[matching];AssociateTo[timings,"PhysicalMatching"->seconds];
 <|"DataType"->"MeasuredMasterBoundaryValues","Status"->"OrderedPhysicalBoundaryValuesDetermined",
  "MasterIntegralBasis"->system["MasterIntegralBasis"],"KinematicVariables"->variables,
  "DimensionalRegulator"->e,"RecoilVariable"->rho,"MeasurementVariable"->z,
  "MeasurementEndpointVariable"->sigma,"RecoilSubstitution"->rules,
  "NormalEndpointSystem"->endpoint,"PhysicalRecoilExponent"->exponent,
  "PhysicalNormalSeedMatrix"->normalEmbedding,
  "PhysicalNormalSeedLeftInverse"->Map[Together,restricted["SolutionLeftInverse"].
    sector["NormalizedLeadingVectorLeftInverse"],{2}],
  "PhysicalTangentialSystem"->restricted,"RecoilObservableMatrix"->observables,
  "CornerPreparation"->cornerPreparation,"CornerBoundaryValues"->matching,
  "RecoilBoundaryIntegrals"->boundaries,"CornerBoundaryTerms"->corners,
  "PhysicalRecoilConstraintRank"->Length[restricted["RelationClosure"]["Rows"]],
  "BoundaryConstantCount"->matching["BoundaryConstantCount"],"Timings"->timings,
  "Request"->request,
  "Scope"->"Physical ordered endpoint values. Interior DE evaluation and sufficient epsilon-depth propagation are separate required steps."|>
 ],"CutFamily"];
End[];EndPackage[];
