(* Planning adapters for coefficient rows in existing closed endpoint systems.
   Integral identity and contribution ownership are independent of family labels. *)
BeginPackage["FeynFacet`"];
BuildEndpointCoefficientCatalog::usage=
 "BuildEndpointCoefficientCatalog[cutCatalog,frames] indexes the exact affine integral classes occurring in accepted closed endpoint systems. Each frame supplies Endpoint, Bounds and its retained source references.";
FindEndpointCoefficientFrames::usage=
 "FindEndpointCoefficientFrames[catalog,masters] returns saved closed frames covering the requested physical master definitions, ordered by dimension and gauge size. Coverage alone does not certify the contracted coefficient row.";
ConstructEndpointCoefficientGroups::usage=
 "ConstructEndpointCoefficientGroups[table,catalog,request] assigns exact moving-pole contributions to suitable saved common DE frames, preserves finite regular terms, and verifies exact contracted-row cancellation with complete ownership records.";
Begin["`Private`"];
endpointGroupFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"EndpointGroups"];
endpointGroupRead[value_String]:=If[ToLowerCase[FileExtension[value]]==="wxf",
 Import[value,"WXF"],FeynFacet`FamilyArtifactRead[value]];
endpointGroupRead[value_]:=value;
BuildEndpointCoefficientCatalog[cutCatalog_Association,inputFrames_Association]:=Catch[Module[
 {frames=<||>,integrals,equivalence,classes,frame,endpoint,bounds,basis,ids,rows,keys,matching,sourceInput},
 If[inputFrames===<||>||!ContainsAll[Keys[cutCatalog],{"Integrals","Families","Normalization"}],
  endpointGroupFail["EndpointAndIntegralCatalogsRequired"]];
 KeyValueMap[Function[{name,input},
  endpoint=endpointGroupRead[input["Endpoint"]];bounds=endpointGroupRead[input["Bounds"]];
  If[!AssociationQ[endpoint]||!AssociationQ[bounds]||
    endpoint["DataType"]=!="TangentialEndpointSystem"||bounds["DataType"]=!="TangentialEndpointLaurentBounds"||
    Length[endpoint["OriginalMasterIntegralBasis"]]=!=endpoint["Dimension"]||
    Length[bounds["OriginalMasterIntegralLaurentLowerBounds"]]=!=endpoint["Dimension"],
   endpointGroupFail["AcceptedEndpointFrameAndPhysicalBoundsRequired",<|"Frame"->name|>]];
  If[!AllTrue[endpoint["OriginalMasterIntegralBasis"],
      First[coefficientMasterID[#]]===name&],
   endpointGroupFail["EndpointFrameKeyMustBeMathematicalFamily",<|"Frame"->name|>]];
  matching=endpointGroupRead[input["BoundaryBasisMatching"]];
  sourceInput=endpointGroupRead[input["SourceInput"]];
  If[!AssociationQ[matching]||!AssociationQ[sourceInput],
    endpointGroupFail["AcceptedPhysicalEndpointMatchingRequired"]];
  AssociateTo[frames,name->Join[input,<|"Endpoint"->endpoint,"Bounds"->bounds,
    "OriginalMasterIntegralBasis"->endpoint["OriginalMasterIntegralBasis"],
    "AcceptedEndpointBinding"-><|"EndpointSystem"->endpoint,"LaurentBounds"->bounds,
      "BoundaryBasisMatching"->matching,"SourceInput"->sourceInput|>|>]]],inputFrames];
 integrals=DeleteDuplicatesBy[Join[cutCatalog["Integrals"],
   Flatten[Lookup[Values[frames],"OriginalMasterIntegralBasis"],1]],coefficientMasterID];
 equivalence=FeynFacet`FindCutIntegralEquivalences[integrals,cutCatalog["Families"],
   "PreferredMasterIntegrals"->Lookup[cutCatalog,"PreferredIntegrals",cutCatalog["Integrals"]],
   "Normalization"->cutCatalog["Normalization"]];
 If[FailureQ[equivalence],endpointGroupFail["EndpointIntegralClassConstructionFailed",<|"Cause"->equivalence|>]];
 If[!AllTrue[equivalence["Mappings"],MemberQ[{0,1},#["Factor"]]&],
  endpointGroupFail["WeightedAffineIntegralEmbeddingRequired"]];
 classes=Association@Map[coefficientMasterID[#["Source"]]->
   If[#["Factor"]===0,0,coefficientMasterID[#["Representative"]]]&,equivalence["Mappings"]];
 KeyValueMap[Function[{name,value},
  basis=value["OriginalMasterIntegralBasis"];ids=coefficientMasterID/@basis;
  If[!AllTrue[ids,KeyExistsQ[classes,#]&],endpointGroupFail["EndpointIntegralClassMissing"]];
  keys=classes/@ids;
  rows=GroupBy[Range[Length[basis]],keys[[#]]&];
  AssociateTo[frames,name->Join[value,<|"RowsByIntegralClass"->rows,
    "Dimension"->Length[basis],"GaugeLeafCount"->LeafCount[value["Endpoint"]["NormalGaugeMatrix"]]|>]]],frames];
 <|"DataType"->"EndpointCoefficientCatalog","Frames"->frames,"IntegralClasses"->classes,
   "CutCatalog"->cutCatalog,"IntegralEquivalences"->equivalence,
   "Scope"->"Exact affine physical-integral identity and saved frame coverage. A fresh contracted-row cancellation and sufficient physical epsilon/normal orders remain required."|>
],"EndpointGroups"];
FindEndpointCoefficientFrames[catalog_Association,masters_List]:=Catch[Module[
 {classes,ids,needed,frames},
 classes=catalog["IntegralClasses"];ids=coefficientMasterID/@masters;
 If[!AllTrue[ids,KeyExistsQ[classes,#]&],endpointGroupFail["CoefficientMasterOutsideEndpointCatalog"]];
 needed=DeleteDuplicates[classes/@ids];
 If[MemberQ[needed,0],endpointGroupFail["ZeroIntegralRequiresCoefficientCoverageHandling"]];
 frames=Select[catalog["Frames"],ContainsAll[Keys[#["RowsByIntegralClass"]],needed]&];
 Keys@SortBy[frames,{#["Dimension"],#["GaugeLeafCount"]}&]
],"EndpointGroups"];

(* Principal parts are taken from exact terms only. In particular, a fresh
   regular Laurent prefix is never subjected to the old pole subtraction. *)
endpointGroupPrincipalParts[expressions_List,z_Symbol,e_Symbol,location_] := Module[
 {field,restore,delta,shifted,variables,reduced,orders,result,indices,series,m,analyticSymbols},
 If[expressions==={},Return[{}]];
 {field,restore}=coefficientRationalFieldReduce[expressions];
 If[!FreeQ[Last/@restore,z],
  endpointGroupFail["NormalDependentAnalyticPrefactorNeedsPrincipalPartExpansion"]];
 analyticSymbols=First/@restore;
 If[analyticSymbols=!={}&&!FreeQ[field,
   Power[base_,n_Integer]/;n<0&&!FreeQ[base,z]&&!FreeQ[base,Alternatives@@analyticSymbols]],
  endpointGroupFail["MixedAnalyticNormalDenominatorNotSupported"]];
 delta=Unique["normalDisplacement"];
 shifted=field/.z->location+delta;
 variables=DeleteDuplicates[Prepend[Cases[shifted,_Symbol,{0,Infinity}],delta]];
 reduced=FeynFacet`CancelRationalExpressions[shifted,variables];
 If[!ListQ[reduced]||Length[reduced]=!=Length[expressions],
  endpointGroupFail["ExactCoefficientPrincipalPartFailed",<|"Cause"->reduced|>]];
 orders=If[#===0,0,Max[0,-coefficientEndpointNormalOrder[#,delta]]]&/@reduced;
 If[!VectorQ[orders,IntegerQ],endpointGroupFail["FiniteCoefficientPoleOrderRequired"]];
 result=ConstantArray[<|"PoleOrder"->0,"PrincipalPart"->0|>,Length[expressions]];
 (* Equal pole orders share one recurrence range. Regular terms are not
    expanded and a deep pole never increases another term's epsilon order. *)
 Do[
  indices=Flatten[Position[orders,m]];
  series=FeynFacet`RationalLaurentCoefficients[reduced[[indices]],variables,delta,{-m,-1}];
  If[!MatchQ[series,{__Association}]||Length[series]=!=Length[indices],
   endpointGroupFail["RationalPrincipalPartCoefficientsRequired",<|"Cause"->series|>]];
  MapThread[Function[{i,coefficients},
   result[[i]]=<|"PoleOrder"->m,
    "PrincipalPart"->(Total[KeyValueMap[#2 (z-location)^#1&,coefficients]]/.restore),
    "Method"->"Exact rational principal part before epsilon expansion"|>],{indices,series}],
 {m,DeleteCases[DeleteDuplicates[orders],0]}];
 result
];
endpointGroupPrincipalPart[expression_,z_Symbol,e_Symbol,location_] :=
 First[endpointGroupPrincipalParts[{expression},z,e,location]];
endpointGroupCancelList[expressions_List] := Module[{field,restore,variables,result},
 {field,restore}=coefficientRationalFieldReduce[expressions];
 variables=DeleteDuplicates[Cases[field,_Symbol,{0,Infinity}]];
 If[variables==={},Return[field/.restore]];
 result=FeynFacet`CancelRationalExpressions[field,variables];
 If[!ListQ[result],endpointGroupFail["ExactCoefficientGroupCancellationFailed",<|"Cause"->result|>]];
 result/.restore
];
endpointGroupCancel[expression_] := First[endpointGroupCancelList[{expression}]];
endpointGroupPoleSupports[entries_List,z_Symbol,e_Symbol] := Module[
 {groups=<||>,terms,divisors,location,key,record},
 Do[
  terms=Select[entries[[i]]["Terms"],#["Representation"]==="Exact"&];
  divisors=coefficientEndpointCoalescingDivisors[
    coefficientEndpointTermExpression/@terms,z,e];
  Do[
   If[!PolynomialQ[divisor,z]||Exponent[divisor,z]=!=1,
    endpointGroupFail["RationalLinearMovingDivisorRequired",<|"Divisor"->divisor|>]];
   location=Cancel[-Coefficient[divisor,z,0]/Coefficient[divisor,z,1]];
   key=ToString[location,InputForm];
   record=Lookup[groups,key,<|"DivisorLocation"->location,"Divisor"->z-location,"SourceRows"->{}|>];
   record["SourceRows"]=Union[record["SourceRows"],{i}];
   AssociateTo[groups,key->record],
  {divisor,divisors}],
 {i,Length[entries]}];
 Values[groups]
];

endpointGroupAlign[entries_List,frame_Association,classes_Association] := Module[
 {basis=frame["OriginalMasterIntegralBasis"],aligned,used={},key,row,mappings={}},
 aligned=(<|"Master"->#,"Terms"->{}|>&/@basis);
 Do[
  key=classes[coefficientMasterID[entry["Master"]]];
  If[!KeyExistsQ[frame["RowsByIntegralClass"],key],endpointGroupFail["CommonFrameIntegralMissing"]];
  row=First[frame["RowsByIntegralClass"][key]];
  If[MemberQ[used,row],endpointGroupFail["EquivalentCoefficientSourcesMustBeCombinedBeforeGrouping"]];
  AppendTo[used,row];aligned[[row]]=entry;
  AppendTo[mappings,<|"SourceMaster"->entry["Master"],"TargetMaster"->basis[[row]],"TargetRow"->row,"Factor"->1|>],
 {entry,entries}];
 <|"Entries"->aligned,"IntegralMappings"->mappings|>
];
(* The assembled table and saved frames must share actual powered-integral
   definitions. A repeated family label is not a definition binding. *)
endpointGroupCheckDefinitions[table_Association,catalog_Association] := Module[
 {target,definitions,byName,used,name,source,expected},
 target=Lookup[catalog,"CutCatalog",None];
 definitions=Lookup[Lookup[table,"Definitions",<||>],"Topologies",None];
 If[!AssociationQ[target]||!ListQ[definitions]||
   Lookup[table,"TargetCatalog",None]=!=target,
  endpointGroupFail["BoundPhysicalIntegralCatalogRequired"]];
 byName[records_] := Association[
   (cutEquivalenceFamilyName[#["Topology"][[1]]]->coefficientTopologyMetadata[#])&/@records];
 source=byName[definitions];expected=byName[target["Families"]];
 used=DeleteDuplicates[First[coefficientMasterID[#]]&/@Lookup[table["Masters"],"Master"]];
 If[!ContainsAll[Keys[source],used]||!ContainsAll[Keys[expected],used]||
   !AllTrue[used,source[#]===expected[#]&],
  endpointGroupFail["PhysicalMasterDefinitionDiffersFromEndpointCatalog"]];
 True
];
endpointGroupCheckEmittedCoefficients[entries_List,emitted_List] := Module[
 {byMaster,actualTerms,originalTerms,differences,comparison,identities},
 byMaster=GroupBy[emitted,coefficientMasterID[#["Master"]]&];
 differences=Table[
  originalTerms=entry["Terms"];
  actualTerms=Flatten[Lookup[Lookup[byMaster,Key[coefficientMasterID[entry["Master"]]],{}],"Terms",{}],1];
  If[Select[actualTerms,#["Representation"]==="LaurentSeries"&]=!=
     Select[originalTerms,#["Representation"]==="LaurentSeries"&],
   endpointGroupFail["FiniteRegularCoefficientChanged"]];
  Total[coefficientEndpointTermExpression/@Select[originalTerms,#["Representation"]==="Exact"&]]-
   Total[coefficientEndpointTermExpression/@Select[actualTerms,#["Representation"]==="Exact"&]],
 {entry,entries}];
 comparison=endpointGroupCancelList[differences];
 Do[If[comparison[[i]]=!=0,
   endpointGroupFail["ExactSourceCoefficientRecombinationFailed",<|"Master"->entries[[i]]["Master"]|>]],
 {i,Length[entries]}];
 Lookup[entries,"Master"]
];
ConstructEndpointCoefficientGroups[table_Association,catalog_Association,request_Association]:=Catch[Module[
 {frames=catalog["Frames"],classes=catalog["IntegralClasses"],first,e,z,entries,residual,
  groups,counts,whole,assigned=<||>,removed={},added={},groupEntries,entry,terms,pieces,
  part,record,label,locations,coefficient,remaining,candidates,frame,aligned,row,cancelled,
  principalIndices,principalParts,changedTerms={},
  attempt,trials,chosen,inputs=<||>,ordinary=<||>,owner,originalFamily,key,sourceFile,
  rules=Lookup[request,"KinematicRules",{}],pref,basis,normalRequest,identities={},insert,gaugeDivisors=<||>,emitted,owners,expectedOwners},
 If[table["Format"]=!="FeynFacet-MasterIntegralCoefficients"||
   !TrueQ[Lookup[table,"PhysicalMasterNormalizationApplied",False]]||frames===<||>,
  endpointGroupFail["PhysicalCoefficientTableAndEndpointCatalogRequired"]];
 endpointGroupCheckDefinitions[table,catalog];
 first=First[Values[frames]]["Endpoint"];
 {e,z}=Lookup[first,{"DimensionalRegulator","NormalVariable"}];
 If[!AllTrue[Values[frames],
   #["Endpoint"]["NormalVariable"]===z&&
   #["Endpoint"]["TangentialVariable"]===first["TangentialVariable"]&],
  endpointGroupFail["CommonEndpointCoordinateChartRequired"]];
 entries=coefficientRegulatorNormalize[table["Masters"]/.rules,e,table["DimensionalRegulator"]];
 residual=entries;pref=coefficientRegulatorNormalize[table["PreFactor"]/.rules,e];
 sourceFile=Lookup[request,"SourceCoefficientFile",Lookup[table,"Source",None]];
 If[coefficientEndpointCoalescingDivisors[{pref},z,e]=!={},
  endpointGroupFail["GlobalPrefactorNeedsJointEndpointTreatment"]];
 If[Lookup[table,"RemainderTerms",{}]=!={},endpointGroupFail["ConstantRemainderNeedsEndpointContribution"]];
 normalRequest=Join[KeyDrop[request,{"KinematicRules"}],<|"KinematicRules"->{},
   "GlobalPrefactor"->pref,"SourceCoefficientFile"->sourceFile,
   "CancelNormalizedCoefficientRow"->True|>];
 insert[label_,value_] := If[KeyExistsQ[inputs,label],
   endpointGroupFail["DuplicateEndpointContributionLabel",<|"Label"->label|>],
   AssociateTo[inputs,label->value]];
 groups=endpointGroupPoleSupports[entries,z,e];
 counts=Counts[Flatten[Lookup[groups,"SourceRows",{}]]];
 whole=Select[Keys[counts],counts[#]===1&&AllTrue[entries[[#]]["Terms"],#["Representation"]==="Exact"&]&];
 (* Each moved whole coefficient has one owner. Shared or finite-series
    sources remain owners of their remainders and contribute exact pieces. *)
 Do[
  label="PoleGroup"<>IntegerString[g,10,4];
  groupEntries={};
  principalIndices=Flatten[Table[
    If[MemberQ[whole,i],{},({i,#}&/@Select[Range[Length[entries[[i,"Terms"]]]],
      entries[[i,"Terms",#,"Representation"]]==="Exact"&])],
    {i,groups[[g,"SourceRows"]]}],1];
  principalParts=endpointGroupPrincipalParts[
    (coefficientEndpointTermExpression[entries[[#[[1]],"Terms",#[[2]]]]]&/@principalIndices),
    z,e,groups[[g,"DivisorLocation"]]];
  principalParts=AssociationThread[principalIndices,principalParts];
  Do[
   entry=entries[[i]];
   If[MemberQ[whole,i],
    AppendTo[groupEntries,entry];
    residual[[i]]=Join[residual[[i]],<|"Terms"->{}|>],
    terms={};pieces={};
    Do[
     If[entry["Terms"][[j,"Representation"]]=!="Exact",Continue[]];
     part=principalParts[{i,j}];
     If[part["PrincipalPart"]===0,Continue[]];
     record=<|"Master"->coefficientMasterID[entry["Master"]],"PoleLabel"->label,
       "SourceTermIndex"->j,"PoleExpression"->part["PrincipalPart"]|>;
     AppendTo[removed,record];AppendTo[added,record];AppendTo[pieces,record];
     AppendTo[terms,<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->part["PrincipalPart"]|>];
     (* Only the exact exceptional term is changed. Finite regular terms,
        including their unknown tails and source certificates, stay intact. *)
     remaining=coefficientEndpointTermExpression[residual[[i,"Terms",j]]]-part["PrincipalPart"];
     residual[[i,"Terms",j]]=<|"Representation"->"Exact","PreFactor"->1,
       "Coefficient"->remaining|>;
     AppendTo[changedTerms,{i,j}],
    {j,Length[entry["Terms"]]}];
    If[terms=!={},AppendTo[groupEntries,Join[entry,<|"Terms"->terms,
      "PartialCoefficientContributions"->pieces|>]]];
    residual[[i]]=Join[residual[[i]],<|"SeparatedCoefficientPoles"->Join[
      Lookup[residual[[i]],"SeparatedCoefficientPoles",{}],pieces]|>]],
  {i,groups[[g,"SourceRows"]]}];
  If[groupEntries==={},Continue[]];
  candidates=FeynFacet`FindEndpointCoefficientFrames[catalog,Lookup[groupEntries,"Master"]];
  If[FailureQ[candidates],Throw[candidates,"EndpointGroups"]];
  chosen=None;trials={};
  Do[
   frame=frames[name];
   attempt=Catch[
    If[!KeyExistsQ[gaugeDivisors,name],AssociateTo[gaugeDivisors,name->
      coefficientEndpointCoalescingDivisors[coefficientRegulatorNormalize[
       frame["Endpoint"]["NormalGaugeMatrix"],e,frame["Endpoint"]["DimensionalRegulator"]],z,e]]];
    If[gaugeDivisors[name]=!={},
     endpointGroupFail["CommonEmbeddingHasMovingPoles"]];
    aligned=endpointGroupAlign[groupEntries,frame,classes];
    row=(Total[coefficientEndpointTermExpression/@#["Terms"]]&/@aligned["Entries"]).
      coefficientRegulatorNormalize[frame["Endpoint"]["NormalGaugeMatrix"],e,frame["Endpoint"]["DimensionalRegulator"]];
    cancelled=TimeConstrained[endpointGroupCancelList[row],Lookup[request,"FrameTimeLimit",120],$TimedOut];
    If[cancelled===$TimedOut,endpointGroupFail["CommonRowCancellationTimeLimit"]];
    If[coefficientEndpointCoalescingDivisors[cancelled,z,e]=!={},
     endpointGroupFail["CommonRowStillHasMovingDivisors"]];
    <|"Family"->name,"ContributionLabel"->label,"CoefficientEntries"->aligned["Entries"],
      "OriginalMasterIntegralBasis"->frame["OriginalMasterIntegralBasis"],
      "SourceDifferentialSystemFile"->frame["SourceDifferentialSystemFile"],
      "SourceCoefficientFile"->sourceFile,"Request"->normalRequest,
      "AcceptedEndpointBinding"->frame["AcceptedEndpointBinding"],
      "CommonBasisEmbedding"->aligned["IntegralMappings"],
      "NormalizedCoefficientRow"->cancelled,"CoefficientRowCancellation"-><|
        "Method"->"Exact rational cancellation in the complete normalized row",
        "RemainingCoalescingDivisors"->{},"EpsilonExpansionUsed"->False|>|>,
   "EndpointGroups"];
   If[AssociationQ[attempt],chosen=attempt;Break[]];
   AppendTo[trials,<|"Frame"->name,"Cause"->attempt|>],
  {name,Take[candidates,UpTo[Lookup[request,"MaximumFrameAttempts",3]]]}];
  If[chosen===None,endpointGroupFail["CommonEndpointFrameNotFound",
    <|"PoleGroup"->label,"Support"->Lookup[groupEntries,"Master"],"Attempts"->trials|>]];
  insert[label,chosen],
 {g,Length[groups]}];
 (* Subtractions at different poles commute exactly. Cancel each changed
    source term once after all principal parts have been removed. *)
 changedTerms=DeleteDuplicates[changedTerms];
 cancelled=endpointGroupCancelList[
   (coefficientEndpointTermExpression[residual[[#[[1]],"Terms",#[[2]]]]]&/@changedTerms)];
 MapThread[Function[{index,value},
   residual[[index[[1]],"Terms",index[[2]],"Coefficient"]]=value],{changedTerms,cancelled}];
 (* Place every remaining source in its original saved frame when possible;
    otherwise choose a covering saved frame. Auxiliary coordinates carry
    zero coefficients, never invented zero physical boundary amplitudes. *)
 Do[
  entry=residual[[i]];
  If[entry["Terms"]==={},Continue[]];
  If[AllTrue[entry["Terms"],coefficientExactZeroTermQ]&&
    Lookup[entry,"SeparatedCoefficientPoles",{}]==={},Continue[]];
  originalFamily=First[coefficientMasterID[entry["Master"]]];
  candidates=FeynFacet`FindEndpointCoefficientFrames[catalog,{entry["Master"]}];
  If[FailureQ[candidates]||candidates==={},endpointGroupFail["OrdinaryEndpointFrameMissing"]];
  owner=If[MemberQ[candidates,originalFamily],originalFamily,First[candidates]];
  AssociateTo[ordinary,owner->Append[Lookup[ordinary,owner,{}],entry]],
 {i,Length[residual]}];
 KeyValueMap[Function[{name,values},
  frame=frames[name];aligned=endpointGroupAlign[values,frame,classes];
  insert[name,<|"Family"->name,"ContributionLabel"->name,
    "CoefficientEntries"->aligned["Entries"],"OriginalMasterIntegralBasis"->frame["OriginalMasterIntegralBasis"],
    "SourceDifferentialSystemFile"->frame["SourceDifferentialSystemFile"],
    "SourceCoefficientFile"->sourceFile,"Request"->normalRequest,
      "AcceptedEndpointBinding"->frame["AcceptedEndpointBinding"],
    "CommonBasisEmbedding"->aligned["IntegralMappings"]|>]],ordinary];
 emitted=Flatten[Lookup[Values[inputs],"CoefficientEntries"],1];
 added=Flatten[Lookup[emitted,"PartialCoefficientContributions",{}],1];
 owners=coefficientMasterID[#["Master"]]&/@Select[emitted,
   Lookup[#,"PartialCoefficientContributions",{}]==={}&&
    (AnyTrue[#["Terms"],!coefficientExactZeroTermQ[#]&]||
     Lookup[#,"SeparatedCoefficientPoles",{}]=!={})&];
 expectedOwners=coefficientMasterID[#["Master"]]&/@Select[entries,
   AnyTrue[#["Terms"],!coefficientExactZeroTermQ[#]&]&];
 If[!DuplicateFreeQ[owners]||Sort[owners]=!=Sort[expectedOwners],
  endpointGroupFail["EmittedWholeCoefficientOwnershipFailed"]];
 If[!coefficientPoleCoverage[removed,added,coefficientMasterID/@Lookup[entries,"Master"]],
  endpointGroupFail["ExactCoefficientPieceCoverageFailed"]];
 (* Reconstruct from actual emitted values, not from subtraction metadata
    or the original whole-source expression. This also checks finite pieces
    that would survive a common-frame moving-pole cancellation. *)
 identities=endpointGroupCheckEmittedCoefficients[entries,emitted];
 <|"DataType"->"EndpointCoefficientGroups","CoefficientInputs"->inputs,
   "PoleGroups"->groups,"RemovedCoefficientPieces"->removed,"AddedCoefficientPieces"->added,
   "ExactSourceRecombinations"->identities,"FiniteRegularCoefficientsUnchanged"->True,
   "SourceCoefficientFile"->sourceFile,"AppliedKinematicRules"->rules,
   "Scope"->"Source coverage and fresh exact common-row cancellation. The existing endpoint order, physical boundary and domain checks are still required for each generated contribution."|>
],"EndpointGroups"];
End[];EndPackage[];
