(* Combine full finite densities with explicit singular endpoint solutions.
   The full kinematic dependence is retained in F-S; no local polynomial
   is substituted for the ordinary-point density. *)
BeginPackage["FeynFacet`"];
AssembleEndpointSubtractedDensity::usage =
 "AssembleEndpointSubtractedDensity[interior,endpoints,request] merges finite scalar definitions, checks exact master coverage, and returns delta, plus-distribution and full locally integrable remainder coefficients. endpoints is a labelled association of complete physical scalar endpoint solutions. request declares the coordinate map, interval, target order and endpoint domain conditions.";
Begin["`Private`"];
Clear[endpointSubtractionFail,endpointSubtractionDefinitions,endpointSubtractionShift,
 endpointSubtractionSeries,endpointSubtractionMonomial,endpointSubtractionGroup,endpointSubtractionAssemble];
endpointSubtractionFail[tag_,data_:<||>] := Throw[Failure[tag,data],"EndpointSubtraction"];
(* These mathematical heads do not inspect or construct expression heads.
   Conditional/effectful Wolfram programs use the original full final check. *)
endpointSubtractionReferencePreservingQ[x_] := FreeQ[x,
 Except[Plus|Times|Power|Rational|Complex|Log|Exp|Gamma|PolyGamma|Zeta|PolyLog|
   Sin|Cos|Tan|ArcSin|ArcCos|ArcTan|Sinh|Cosh|Tanh|ArcSinh|ArcCosh|ArcTanh|Abs|Re|Im|Conjugate|
   List|Association|Rule|FeynFacetSolution`G|FeynFacetSolution`a|FeynFacetSolution`F|FeynFacetSolution`K][___]];
endpointSubtractionDefinitions[data_,expressions_,e_] := Module[{a,f,k,all},
 {a,f,k}=Lookup[data,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"},None];
 If[!AllTrue[{a,f,k},ListQ]||!finiteDensityDefinitionCheck[data,e],
  endpointSubtractionFail["ExplicitAcyclicFiniteDefinitionsRequired"]];
 all={a,f,k,expressions};
 If[!FreeQ[all,e|_FeynFacetSolution`C|_FeynFacetSolution`B|_Missing|_Failure|$Failed|
   _Series|_SeriesData|_SeriesCoefficient|Indeterminate|_DirectedInfinity]||
  !AllTrue[Cases[all,FeynFacetSolution`a[i_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[a]&]||
  !AllTrue[Cases[all,FeynFacetSolution`F[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[f]&]||
  !AllTrue[Cases[all,FeynFacetSolution`K[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[k]&],
  endpointSubtractionFail["ExplicitClosedPhysicalCoefficientsRequired"]];
 KeyTake[data,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"}]
];
endpointSubtractionShift[x_,na_,nf_,nk_] :=
 FeynFacetSolution`Private`replaceFiniteExpressionReferences[x,{
 FeynFacetSolution`a[i_Integer]:>With[{j=i+na},FeynFacetSolution`a[j]],
 FeynFacetSolution`F[i_Integer,u_]:>With[{j=i+nf},FeynFacetSolution`F[j,u]],
 FeynFacetSolution`K[i_Integer,u_]:>With[{j=i+nk},FeynFacetSolution`K[j,u]]}];
endpointSubtractionSeries[term_,z_,lo_,hi_] := Module[{c=term["Coefficients"],b=term["RegulatorExponent"]},
 Association@Table[q->z^term["Power"] Log[z]^term["LogPower"] Total[
  KeyValueMap[If[#1<=q,#2 endpointDistributionPower[b Log[z],q-#1]/Factorial[q-#1],0]&,c]],{q,lo,hi}]
];
endpointSubtractionMonomial[term_,e_,target_] := Module[{a,b,l,series,zero},
 {a,b,l}=Lookup[term,{"Power","RegulatorExponent","LogPower"},None];
 If[!IntegerQ[a]||a>=0||!MatchQ[b,_Integer|_Rational]||!IntegerQ[l]||l<0,
  endpointSubtractionFail["SingularPrimaryEndpointMonomialRequired"]];
 series=KeyTake[term,{"LaurentLowerBound","KnownThroughOrder","Coefficients","ExactInEpsilon"}];
 zero=<|"LaurentLowerBound"->0,"KnownThroughOrder"->-1,"Coefficients"-><||>,"ExactInEpsilon"->True|>;
 <|"Power"->a+e b,"LogPower"->l,"Prefactor"->1,
  "TaylorCoefficients"->Association@Table[j->If[j===0,series,zero],{j,0,-a-1}],
  "Remainder"->zero,"RemainderEndpointPowerLowerBound"->0|>
];
endpointSubtractionGroup[records_,keys_,lo_,hi_] := Map[Function[group,
 Join[KeyTake[First[group],keys],<|"Coefficients"->Association@Table[
   q->Total[Lookup[#["Coefficients"],q,0]&/@group],{q,lo,hi}]|>]],
 GatherBy[records,Lookup[#,keys]&]];
endpointSubtractionAssemble[interior_,endpoints_,request_] := Module[
 {e,z,v,target,rules,geometry,expected,covered,source,pref,full,definitions,aa,ff,kk,
  aaParts,ffParts,kkParts,na,nf,nk,record,terms={},monomials={},scopes={},bundle,
  localTerms,localMonomials,shifted,distribution,delta,plus,lo,hi,regular,singular,
  coefficients,termSeries,fullCoefficients,byEndpoint=<||>,label,check,boundSymbols,
  endpointSource,fullSource,condition,domain,allDistributionTerms,regularDistribution,
  scalarRemainderPresent,scalarRemainderModels=0,removedPoles={},addedPoles={},remainderConditions={},
  timings=<||>,stageStarted=AbsoluteTime[],mark,referencePreserving},
 mark[name_]:=(AssociateTo[timings,name->(AbsoluteTime[]-stageStarted)];stageStarted=AbsoluteTime[];
   If[TrueQ[Lookup[request,"Verbose",False]],Print["Endpoint assembly ",name,": ",timings[name]," s"]]);
 If[Lookup[interior,"DataType",None]=!="FiniteMasterIntegralDensity"||
  !TrueQ[Lookup[interior,"PhysicalMasterNormalizationApplied",False]]||
  !TrueQ[Lookup[interior,"PhysicalBoundaryCoefficientsResolved",False]]||
  !TrueQ[Lookup[interior,"UnknownInitialConstantCount",None]===0]||
  !TrueQ[Lookup[interior,"EndpointSubtractionsApplied",True]===False],
  endpointSubtractionFail["UnsubtractedCompletePhysicalDensityRequired"]];
 If[Length[DownValues[FeynFacetSolution`Private`replaceFiniteExpressionReferences]]===0,
  endpointSubtractionFail["FiniteSolutionDefinitionReaderNotLoaded"]];
 {e,z,v,target}= {Lookup[interior,"DimensionalRegulator",None],
  Lookup[request,"NormalVariable",None],Lookup[request,"TangentialVariable",None],
  Lookup[request,"ThroughOrder",None]};
 rules=Lookup[request,"KinematicRules",None];
 If[!MatchQ[{e,z,v},{_Symbol,_Symbol,_Symbol}]||MemberQ[{e,z,v},None]||
  !DuplicateFreeQ[{e,z,v}]||!IntegerQ[target]||!MatchQ[rules,{(_Rule)..}]||
  !FreeQ[rules,e]||!TrueQ[Lookup[request,"CoordinateJacobianIncluded",False]],
  endpointSubtractionFail["EndpointCoordinateMapAndIncludedJacobianRequired"]];
 (* Only scalar substitutions for declared coordinates are allowed. Such a
    map cannot create or change finite-definition indices. *)
 If[!AllTrue[First/@rules,MatchQ[#,_Symbol]&&MemberQ[Lookup[interior,"KinematicVariables",{}],#]&&
     !MemberQ[{FeynFacetSolution`a,FeynFacetSolution`F,FeynFacetSolution`K,FeynFacetSolution`B,FeynFacetSolution`C},#]&]||
   !FreeQ[Last/@rules,FeynFacetSolution`a|FeynFacetSolution`F|FeynFacetSolution`K|FeynFacetSolution`B|FeynFacetSolution`C|
     _FeynFacetSolution`a|_FeynFacetSolution`F|_FeynFacetSolution`K|
     _FeynFacetSolution`C|_FeynFacetSolution`B|_Rule|_RuleDelayed|_Association|
     _Missing|_Failure|$Failed|_Series|_SeriesData|_SeriesCoefficient|Indeterminate|_DirectedInfinity],
  endpointSubtractionFail["ScalarKinematicCoordinateRulesRequired"]];
 {lo,hi}=Lookup[interior,"EpsilonOrderRange",{None,None}];
 If[!IntegerQ[lo]||!IntegerQ[hi]||target>hi||
   !AssociationQ[Lookup[interior,"Coefficients",None]]||
   Sort[Keys[interior["Coefficients"]]]=!=Range[lo,hi],
  endpointSubtractionFail["FullInteriorCoefficientOrdersInsufficient"]];
 If[!AssociationQ[endpoints]||endpoints===<||>||!AllTrue[Keys[endpoints],StringQ],
  endpointSubtractionFail["LabelledScalarEndpointSolutionsRequired"]];
 expected=DeleteDuplicates[Lookup[Lookup[interior,"MasterOrderRequirements",{}],"Master",{}]];
 If[expected==={},endpointSubtractionFail["CompleteInteriorMasterIdentityListRequired"]];
 fullSource=Lookup[interior,"SourceCoefficientFile",None];
 scalarRemainderPresent=AnyTrue[Values[Lookup[interior,"ScalarRemainderCoefficients",<||>]],#=!=0&];
 fullCoefficients=KeySelect[interior["Coefficients"],#<=target&];
 definitions=endpointSubtractionDefinitions[interior,fullCoefficients,e];
 referencePreserving=endpointSubtractionReferencePreservingQ[{definitions,Last/@rules}];
 boundSymbols=DeleteDuplicates[Join[Lookup[definitions["KernelDefinitions"],"Parameter",{}],
   Lookup[definitions["IntegralDefinitions"],"IntegrationVariable",{}],
   Lookup[definitions["IntegralDefinitions"],"UpperLimitVariable",{}]]];
 If[!FreeQ[rules,Alternatives@@boundSymbols],
  endpointSubtractionFail["EndpointCoordinateMapCapturesIntegralParameter"]];
 definitions=FeynFacetSolution`Private`replaceFiniteExpressionReferences[definitions,rules];
 fullCoefficients=FeynFacetSolution`Private`replaceFiniteExpressionReferences[fullCoefficients,rules];
 {aa,ff,kk}=Lookup[definitions,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"}];
 {aaParts,ffParts,kkParts}={{aa},{ff},{kk}};{na,nf,nk}=Length/@{aa,ff,kk};
 mark["InteriorDefinitions"];
 covered={};
 Do[
  record=epsOrderNormalize[endpoints[label],e];
  If[!AssociationQ[record]||Lookup[record,"DataType",None]=!="FiniteScalarEndpointSolution"||
   Lookup[record,"DimensionalRegulator",None]=!=e||Lookup[record,"NormalVariable",None]=!=z||
   Lookup[record,"TangentialVariable",None]=!=v||!IntegerQ[Lookup[record,"ThroughOrder",None]]||
   record["ThroughOrder"]<target||!TrueQ[Lookup[record,"PhysicalBoundaryValuesApplied",False]]||
   Lookup[record,"RequiredInitialConstantCoefficients",None]=!={}||
   !TrueQ[Lookup[record,"GlobalPrefactorIncluded",False]],
   endpointSubtractionFail["CompleteMatchingPhysicalScalarEndpointRequired",<|"Endpoint"->label|>]];
  check=Lookup[record,"CoefficientTailSufficiency",<||>];
  remainderConditions=Join[remainderConditions,Lookup[check,"CoefficientRemainderDomainConditions",{}]];
  If[Lookup[check,"Status",None]=!="SufficientOrdersDetermined"||
    Lookup[check,"MissingCoefficientOrders",None]=!={}||
    Lookup[check,"UnresolvedCoefficientRemainderClasses",{}]=!={},
   endpointSubtractionFail["UniformEndpointCoefficientTailRequired",<|"Endpoint"->label|>]];
  source=Lookup[record,"ProjectedMasterIdentities",None];
  If[!ListQ[source]||!DuplicateFreeQ[source],
   endpointSubtractionFail["ProjectedMasterIdentityListRequired",<|"Endpoint"->label|>]];
  covered=Join[covered,source];
  removedPoles=Join[removedPoles,Lookup[record,"SeparatedCoefficientPoles",{}]];
  addedPoles=Join[addedPoles,Lookup[record,"PartialCoefficientContributions",{}]];
  If[TrueQ[Lookup[record,"ScalarRemainderContributionIncluded",False]],scalarRemainderModels++];
  endpointSource=Lookup[record,"SourceCoefficientFile",None];
  If[fullSource===None||endpointSource=!=fullSource,
   endpointSubtractionFail["EndpointCoefficientSourceMismatch",<|"Endpoint"->label,
    "InteriorSource"->fullSource,"EndpointSource"->endpointSource|>]];
  localMonomials=Lookup[record,"EndpointTerms",None];
  If[!ListQ[localMonomials]||!AllTrue[localMonomials,AssociationQ],
   endpointSubtractionFail["ExplicitEndpointMonomialsRequired",<|"Endpoint"->label|>]];
  localTerms=endpointSubtractionMonomial[#,e,target]&/@localMonomials;
  bundle=endpointSubtractionDefinitions[record,Lookup[localMonomials,"Coefficients",{}],e];
  referencePreserving=referencePreserving&&endpointSubtractionReferencePreservingQ[bundle];
  If[!FreeQ[bundle,z],endpointSubtractionFail["NormalIndependentEndpointCoefficientDefinitionsRequired"]];
  shifted=endpointSubtractionShift[bundle,na,nf,nk];
  AppendTo[aaParts,shifted["AlgebraicDefinitions"]];
  AppendTo[ffParts,MapIndexed[Join[#1,<|"Index"->nf+First[#2]|>]&,shifted["IntegralDefinitions"]]];
  AppendTo[kkParts,MapIndexed[Join[#1,<|"Index"->nk+First[#2]|>]&,shifted["KernelDefinitions"]]];
  localTerms=endpointSubtractionShift[localTerms,na,nf,nk];
  localMonomials=endpointSubtractionShift[localMonomials,na,nf,nk];
  AppendTo[scopes,<|"Endpoint"->label,"AlgebraicOffset"->na,"IntegralOffset"->nf,"KernelOffset"->nk,
   "ProjectedMasterIdentities"->source|>];
  {na,nf,nk}={na,nf,nk}+Length/@Lookup[bundle,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"}];
  terms=Join[terms,localTerms];monomials=Join[monomials,localMonomials];
  AssociateTo[byEndpoint,label->KeyTake[record,{"AnalyticDomain","BranchPrescription","TangentialBasePoint"}]],
 {label,Keys[endpoints]}];
 If[Sort[covered]=!=Sort[expected],
  endpointSubtractionFail["EndpointMasterCoverageMismatch",<|
   "MissingMasters"->Complement[expected,covered],"UnexpectedMasters"->Complement[covered,expected],
   "RepeatedMasters"->First/@Select[Tally[covered],Last[#]>1&]|>]];
 If[!TrueQ[coefficientPoleCoverage[removedPoles,addedPoles,covered]],
  endpointSubtractionFail["EndpointCoefficientPoleCoverageMismatch",<|
    "RemovedPoleCount"->Length[removedPoles],"AddedPoleCount"->Length[addedPoles]|>]];
 If[scalarRemainderModels=!=If[scalarRemainderPresent,1,0],
  endpointSubtractionFail["ScalarRemainderEndpointCoverageRequired",<|
   "ScalarRemainderPresent"->scalarRemainderPresent,"EndpointModelCount"->scalarRemainderModels|>]];
 geometry=Join[KeyTake[request,{"Interval","Assumptions","EndpointConditions","TestFunctionDomain"}],
  <|"DimensionalRegulator"->e,"Variable"->z,"NormalVariables"->{z},"Terms"->terms|>];
 mark["EndpointDefinitionsAndCoverage"];
 distribution=FeynFacet`ExtractEndpointDistributions[geometry,<|"ThroughOrder"->target|>];
 If[FailureQ[distribution],endpointSubtractionFail["EndpointDistributionExtractionFailed",<|"Cause"->distribution|>]];
 allDistributionTerms=distribution["Terms"];
 mark["DistributionExtraction"];
 lo=Min[Append[Lookup[allDistributionTerms,"LaurentLowerBound",lo],lo]];
 delta=endpointSubtractionGroup[Flatten[Lookup[allDistributionTerms,"DeltaTerms",{}],1],
  {"DerivativeOrder"},lo,target];
 plus=endpointSubtractionGroup[Flatten[Lookup[allDistributionTerms,"PlusTerms",{}],1],
  {"Power","LogPower","SubtractionOrder"},lo,target];
 termSeries=endpointSubtractionSeries[#,z,lo,target]&/@monomials;
 singular=Association@Table[q->Total[Lookup[#,q,0]&/@termSeries],{q,lo,target}];
 regularDistribution=Association@Table[q->Total[Lookup[#["RegularRemainder"]["Coefficients"],q,0]&/@allDistributionTerms],{q,lo,target}];
 If[AnyTrue[Values[regularDistribution],#=!=0&],
  endpointSubtractionFail["SingularModelContainsUnaccountedRegularPart"]];
 regular=Association@Table[q->(Lookup[fullCoefficients,q,0]-singular[q]),{q,lo,target}];
 coefficients=Association@Table[q->(regular[q]+
   Total[Lookup[#["Coefficients"],q,0] FeynFacet`EndpointDeltaDerivative[z,#["DerivativeOrder"],Last[request["Interval"]]]&/@delta]+
   Total[Lookup[#["Coefficients"],q,0] FeynFacet`EndpointPlusDistribution[z,#["Power"],#["LogPower"],#["SubtractionOrder"],Last[request["Interval"]]]&/@plus]),{q,lo,target}];
 definitions=<|"AlgebraicDefinitions"->Join@@aaParts,"IntegralDefinitions"->Join@@ffParts,"KernelDefinitions"->Join@@kkParts|>;
 mark["CoefficientAssembly"];
 (* Every input graph was checked above. Translation into disjoint index
    intervals preserves closure and order; the scalar coordinate map cannot
    introduce references. Check the new outputs and undefined transformed
    values, without traversing every graph edge for a second time. *)
 If[Length/@Lookup[definitions,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"}]=!={na,nf,nk}||
   !FreeQ[{definitions,coefficients},e|_FeynFacetSolution`C|_FeynFacetSolution`B|_Missing|_Failure|$Failed|
     _Series|_SeriesData|_SeriesCoefficient|Indeterminate|_DirectedInfinity]||
   !AllTrue[Cases[coefficients,FeynFacetSolution`a[i_]:>i,Infinity],IntegerQ[#]&&1<=#<=na&]||
   !AllTrue[Cases[coefficients,FeynFacetSolution`F[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=nf&]||
   !AllTrue[Cases[coefficients,FeynFacetSolution`K[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=nk&],
  endpointSubtractionFail["ExplicitClosedPhysicalCoefficientsRequired"]];
 If[!referencePreserving,endpointSubtractionDefinitions[definitions,coefficients,e]];
 mark["FinalDefinitionChecks"];
 Join[<|"DataType"->"FiniteEndpointSubtractedDensity","SchemaVersion"->1,
  "Status"->"ExplicitDeltaPlusAndRegularCoefficients","DimensionalRegulator"->e,
  "NormalVariable"->z,"TangentialVariable"->v,"Interval"->request["Interval"],
  "EpsilonOrderRange"->{lo,target},"OmittedEpsilonOrderLowerBound"->target+1,
  "DeltaTerms"->delta,"PlusTerms"->plus,"RegularRemainderCoefficients"->regular,
  "SingularModelCoefficients"->singular,"InteriorCoefficients"->fullCoefficients,
  "Coefficients"->coefficients,"Expression"->Total[KeyValueMap[#2 e^#1&,coefficients]],
  "EndpointSubtractionsApplied"->True,"UnknownInitialConstantCount"->0,
  "DefinitionScopes"->Join[Lookup[interior,"DefinitionScopes",{}],scopes],
  "MasterCount"->Length[expected],"ProjectedMasterIdentities"->covered,
  "RecombinedCoefficientPoles"->removedPoles,
  "TangentialAssumptions"->And[Lookup[request,"Assumptions",True],And@@DeleteDuplicates[remainderConditions]],
  "PhysicalDensityNormalization"->Lookup[interior,"PhysicalDensityNormalization",<||>],
  "SourceCoefficientFile"->fullSource,"KinematicRules"->rules,
  "ComputationTimings"->timings,
  "DomainConvention"->distribution["DomainConvention"],"EndpointConditions"->request["EndpointConditions"],
  "EndpointAnalyticDomains"->byEndpoint,"InteriorAnalyticDomains"->Lookup[interior,"AnalyticDomains",<||>],
  "DistributionConvention"->distribution["Convention"],
  "Scope"->"Bare density on the declared single-endpoint test-function domain. The remainder is the full interior function minus its explicit singular model. No other cuts, counterterms, or upper-endpoint extension are inferred.",
  "CompleteDifferentialCrossSectionClaimed"->False|>,definitions]
];
FeynFacet`AssembleEndpointSubtractedDensity[interior_Association,endpoints_Association,request_Association] :=
 Catch[endpointSubtractionAssemble[interior,endpoints,request],"EndpointSubtraction"];
FeynFacet`AssembleEndpointSubtractedDensity[___] :=
 Failure["FiniteInteriorScalarEndpointsAndRequestRequired",<||>];
End[];
EndPackage[];
