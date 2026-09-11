(* Current mathematical inputs and coordinate composition for order planning. *)
BeginPackage["FeynFacet`"];Begin["`Private`"];
coefficientPlanRulesQ[rules_]:=ListQ[rules]&&
 AllTrue[rules,MatchQ[#,_Rule]&&MatchQ[First[#],_Symbol]&]&&DuplicateFreeQ[First/@rules];

coefficientPlanDependencies[request_Association] := Module[{catalog,normalization,required},
 catalog=coefficientPlanRead[Lookup[request,"EndpointCatalog",None]];
 normalization=coefficientPlanRead[Lookup[request,"PhysicalNormalization",None]];
 required={"Scale","ReferenceScale","Assumptions","KinematicRules"};
 If[Lookup[catalog,"DataType",None]=!="EndpointCoefficientCatalog"||
   !AssociationQ[Lookup[catalog,"Frames",None]]||catalog["Frames"]===<||>||
   !AssociationQ[Lookup[catalog,"CutCatalog",None]]||
   !AllTrue[Values[catalog["Frames"]],AssociationQ[#]&&
     AssociationQ[Lookup[#,"Endpoint",None]]&&AssociationQ[Lookup[#,"Bounds",None]]&&
     AssociationQ[Lookup[#,"AcceptedEndpointBinding",None]]&],
  coefficientPlanFail["AcceptedEndpointCatalogRequired"]];
 If[!AllTrue[Values[catalog["Frames"]],StringQ[Lookup[#,"SourceDifferentialSystemFile",None]]&&
     FileExistsQ[#["SourceDifferentialSystemFile"]]&],
  coefficientPlanFail["EndpointSourceDifferentialSystemMissing"]];
 If[!AllTrue[Values[catalog["Frames"]],
    #["Endpoint"]===Lookup[#["AcceptedEndpointBinding"],"EndpointSystem",None]&&
    #["Bounds"]===Lookup[#["AcceptedEndpointBinding"],"LaurentBounds",None]&],
  coefficientPlanFail["AcceptedEndpointBindingInconsistent"]];
 If[!ContainsAll[Keys[normalization],required]||!exactDataQ[normalization]||
   !coefficientPlanRulesQ[normalization["KinematicRules"]]||
   !TrueQ[FullSimplify[normalization["Scale"]>0&&normalization["ReferenceScale"]>0,
     normalization["Assumptions"]]],
  coefficientPlanFail["PhysicalNormalizationDeclarationInvalid"]];
 If[!coefficientPlanRulesQ[Lookup[request,"KinematicRules",None]]||
   !IntegerQ[Lookup[request,"ThroughOrder",None]]||
   !AssociationQ[Lookup[request,"SourceNormalization",None]]||
   !KeyExistsQ[request,"Assumptions"],
  coefficientPlanFail["CoefficientPlanningDeclarationInvalid"]];
 If[Lookup[catalog["CutCatalog"],"Normalization",None]=!=request["SourceNormalization"],
  coefficientPlanFail["SourceEndpointNormalizationMismatch"]];
 If[!FreeQ[coefficientRegulatorNormalize[
    {normalization["KinematicRules"],request["KinematicRules"]},$feynFacetEpsilon],$feynFacetEpsilon],
  coefficientPlanFail["RegulatorIndependentCoordinateRulesRequired"]];
 <|"Catalog"->catalog,"Normalization"->normalization|>
];
(* File identities keep a large accepted catalog out of every small plan.
   The used endpoint/bound records themselves remain in each order proof. *)
coefficientPlanRequestBinding[request_,dependencies_] := <|
 "Request"->KeySort@Join[KeyDrop[request,{"EndpointCatalog","PhysicalNormalization","PlanDirectory"}],
   <|"PhysicalNormalization"->dependencies["Normalization"]|>],
 "EndpointCatalogContent"->If[StringQ[request["EndpointCatalog"]],
   coefficientFileHash[request["EndpointCatalog"]],
   Hash[coefficientCanonicalContainers[dependencies["Catalog"]],"SHA256"]],
 "FrameSourceSystems"->Map[coefficientFileHash[#["SourceDifferentialSystemFile"]]&,
   dependencies["Catalog"]["Frames"]]|>;

coefficientValidateSavedPlan[plan_,request_] := Catch[Module[{dependencies,binding},
 If[!AssociationQ[request],coefficientPlanFail["CurrentReconstructionOrderInputsRequired"]];
 dependencies=coefficientPlanDependencies[request];
 binding=coefficientPlanRequestBinding[request,dependencies];
 If[Lookup[Lookup[plan,"PlanningInputBinding",<||>],"CurrentDependencies",None]=!=binding,
  coefficientPlanFail["ReconstructionPlanMathematicalInputsChanged",
    <|"Action"->"Prepare a current plan before reusing reconstruction jobs."|>]];
 True
],"CoefficientPlan"];

(* Compose substitutions in precisely the same order as result assembly:
   color rules, dimensionless coordinates, physical normalization, endpoint
   coordinates. A source numerator is covered even if it has no denominator. *)
coefficientPlanEffectiveRules[data_,context_,normalization_,endpointRules_,endpoint_,domain_] :=
 Catch[Module[{source,stages,values,e,z,v,coefficients,denominators,probe,degree},
 {e,z,v}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable","TangentialVariable"}];
 source=coefficientRegulatorNormalize[Keys[data["SymbolRules"]],e];
 stages=coefficientRegulatorNormalize[
  {Lookup[context,"ColorRules",{}],Normal[context["DimensionlessCoordinates"]],
   normalization["KinematicRules"],endpointRules},e];
 If[!AllTrue[stages,coefficientPlanRulesQ],Throw[Failure["UniqueCoordinateRulesRequired",<||>]]];
 If[Lookup[context,"CoordinateEqualities",{}]=!={},
  Throw[Failure["CoordinateQuotientNeedsTailAnalysis",<||>]]];
 values=Fold[ReplaceAll,#,stages]&/@source;
 Do[
  If[source[[i]]===e,
   If[values[[i]]=!=e,Throw[Failure["RegulatorCoordinateRewriteForbidden",<||>]]],
   If[!FreeQ[values[[i]],e]||!PolynomialQ[values[[i]],{z,v}],
    Throw[Failure["AffineEffectiveCoordinateMapRequired",<|"Source"->source[[i]],"Image"->values[[i]]|>]]];
   coefficients=CoefficientRules[Expand[values[[i]]],{z,v}];
   degree=Max[Prepend[Total[First[#]]&/@coefficients,0]];
   If[degree>1,Throw[Failure["AffineEffectiveCoordinateMapRequired",<|"Source"->source[[i]]|>]]];
   denominators=DeleteDuplicates[Denominator[Together[Last[#]]]&/@coefficients];
   Do[
    probe=coefficientAnalyzeDivisors[<|"Divisors"->{"den"}|>,e,z,{"den"},<|"den"->den|>,{},domain];
    If[AnyTrue[probe,FailureQ],Throw[Failure["EffectiveCoordinateParameterUnitUnproved",<|"Denominator"->den|>]]],
   {den,denominators}]
  ],{i,Length[source]}];
 Thread[source->values]
]];

coefficientPlanFrameBinding[catalog_,frame_,row_,physical_,master_,mapping_,normalization_,rules_] :=
 Catch[Module[{definition,convention,system,input,e,coordinates,frameMaster,transitions,selected},
 selected=Select[Values[Lookup[physical["Definitions"],"MasterIntegralDefinitions",<||>]],
    coefficientMasterID[#["MasterIntegral"]]===coefficientMasterID[master]&];
 If[Length[selected]=!=1,Throw[Failure["UniqueSourcePhysicalDefinitionRequired",<||>]]];
 definition=First[selected];
 convention=catalog["CutCatalog"]["Normalization"];
 If[Lookup[definition,"MomentumSpaceConvention",None]=!=Lookup[convention,"MomentumSpaceConvention",Missing[]]||
   Lookup[definition,"MomentumSpaceConvention",None]=!="AMFlow"||
   Lookup[definition,"MasterIntegralPrefactor",None]=!=1,
  Throw[Failure["PhysicalFrameNormalizationNotEstablished",<||>]]];
 frameMaster=frame["OriginalMasterIntegralBasis"][[row]];
 transitions=Select[catalog["IntegralEquivalences"]["Mappings"],
   MemberQ[coefficientMasterID/@{mapping["Representative"],frameMaster},coefficientMasterID[#["Source"]]]&];
 If[Length[transitions]<Length[DeleteDuplicates[coefficientMasterID/@{mapping["Representative"],frameMaster}]]||
    !AllTrue[transitions,#["Factor"]===1&],
  Throw[Failure["UnitRepresentativeToFrameIdentityRequired",<||>]]];
 system=endpointGroupRead[frame["SourceDifferentialSystemFile"]];
 input=frame["AcceptedEndpointBinding"]["SourceInput"];
 If[!AssociationQ[system]||!AssociationQ[Lookup[system,"KinematicVariableDefinition",None]]||
   !MatchQ[Lookup[system["KinematicVariableDefinition"],"ScaleNormalization",None],_Rule],
  Throw[Failure["EndpointReferenceScaleDefinitionRequired",<||>]]];
 If[Last[system["KinematicVariableDefinition"]["ScaleNormalization"]]=!=normalization["ReferenceScale"],
  Throw[Failure["EndpointPhysicalReferenceScaleMismatch",<||>]]];
 e=frame["Endpoint"]["DimensionalRegulator"];
 coordinates=Lookup[input,"CoordinateRules",None];
 If[!coefficientPlanRulesQ[coordinates]||
   !AllTrue[coordinates,TrueQ[Cancel[Fold[ReplaceAll,First[#],{normalization["KinematicRules"],rules}]-Last[#]]===0]&],
  Throw[Failure["PhysicalToEndpointCoordinateIdentityRequired",<||>]]];
 <|"SourceMaster"->master,"SourcePhysicalDefinition"->definition,"SourceToRepresentative"->mapping,
   "RepresentativeToFrame"->transitions,"FrameMaster"->frameMaster,"FrameRow"->row,
   "PhysicalConvention"->convention,"ReferenceScale"->normalization["ReferenceScale"],
   "SourceDifferentialSystem"->KeyTake[system,{"OriginalMasterIntegralBasis","KinematicVariableDefinition","MathematicalInputReferences"}],
   "EndpointCoordinateRules"->coordinates,"Status"->"UnitPhysicalIntegralIdentityEstablished"|>
]];
End[];EndPackage[];
