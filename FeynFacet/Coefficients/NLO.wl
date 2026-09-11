(* Analytic massless NLO contributions for single-inclusive partonic
   densities. All process information enters through amplitude and assembly
   cards; integral methods are selected from momentum geometry. *)
BeginPackage["FeynFacet`"];
ConstructNLOVirtualContribution::usage="ConstructNLOVirtualContribution[table,request] evaluates the required one-loop masters, contracts them with exact coefficients and forms one oriented interference plus its conjugate. Request declares Scale, MandelstamVariables, Variables {v,w}, KinematicConditions, Assumptions and RenormalizationScaleSquared.";
ConstructNLORealContribution::usage="ConstructNLORealContribution[table,request] recognizes analytic two-body phase-space masters and returns explicit delta/plus/regular Laurent coefficients. Request additionally supplies the endpoint domain conditions used by ConstructAnalyticEndpointExpansion.";
ConstructZeroAmplitudeContribution::usage="ConstructZeroAmplitudeContribution[records,request] returns an exact zero only after checking every selected interference is present, has an explicitly zero integrand and has no remaining integral topology. It does not infer zero from the process name.";
AssembleNLOHardFunction::usage="AssembleNLOHardFunction[contributions,request] combines named real, virtual, UV and collinear records, checks exact pole cancellation, and returns explicit finite NLO delta/plus/regular coefficients. Request supplies RequiredContributions, Scale, Variables, Assumptions, and optional ColorRules and Description.";
Begin["`Private`"];
nloFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AnalyticNLO"];
nloCheck[x_,tag_]:=If[FailureQ[x]||x===$Failed||x===$Aborted,nloFail[tag,<|"Cause"->x|>],x];
nloRequest[table_,request_]:=Module[{e,req,required},
 required={"Scale","MandelstamVariables","Variables","KinematicConditions","Assumptions","RenormalizationScaleSquared"};
 If[!ContainsAll[Keys[request],required],nloFail["AnalyticNLORequestIncomplete",<|"Missing"->Complement[required,Keys[request]]|>]];
 e=table["DimensionalRegulator"];req=coefficientRegulatorNormalize[request,e];
 If[!MatchQ[req["MandelstamVariables"],{_Symbol,_Symbol,_Symbol}]||!DuplicateFreeQ[req["MandelstamVariables"]]||
  !MatchQ[req["Variables"],{_Symbol,_Symbol}]||!DuplicateFreeQ[Join[req["MandelstamVariables"],req["Variables"],{e}]]||
  First[req["MandelstamVariables"]]=!=req["Scale"],nloFail["SingleInclusiveMandelstamCoordinatesRequired"]];
 If[Lookup[req,"ThroughOrder",0]=!=0,nloFail["FiniteNLOOrderRequired"]];
 If[!AllTrue[Flatten[Lookup[table["Masters"],"Terms"]],Lookup[#,"Representation",None]==="Exact"&]||
  table["RemainderTerms"]=!={},nloFail["ExactReducedNLOCoefficientsRequired"]];req
];
nloIntegralInput[table_,conditions_]:=Module[{setup,tops,external,kin},
 setup=table["Definitions"]["Setup"];tops=table["Definitions"]["Topologies"];
 external=Union[Flatten[(#["Topology"][[4]]& /@ tops)]];
 kin=Flatten[Table[With[{lhs=FeynCalc`FCI[FeynCalc`SPD[p,q]]},
   lhs->FeynFacet`SimplifyAssum[FeynCalc`SPD[p,q],setup]],{p,external},{q,external}]];
 <|"OriginalMasterIntegralBasis"->Lookup[table["Masters"],"Master"],"Topologies"->tops,
  "Setup"->setup,"DimensionalRegulator"->table["DimensionalRegulator"],"KinematicRules"->kin,"KinematicConditions"->conditions|>
];
nloMapDistributions[f_,rows_Association]:=(partonicMap[f,#]& /@ rows);
nloContribution[type_,e_,w_,cs_,request_,data_:<||>]:=CreatePartonicResult[nloMapDistributions[partonicCollect,cs],Join[
 KeyTake[request,{"Project","Channel","Scale","Variables","Coupling","CouplingPower","DimensionalPrefactor","PhysicalChannel","Polarization"}],
 <|"Order"->"NLO","Contribution"->type,"DimensionalRegulator"->e,"Variable"->w|>,data]];
ConstructNLOVirtualContribution[table_Association,request_Association]:=Catch[Module[
 {req,e,s,mandel,v,w,setup,loops,input,definitions,norm,rules,conversions,values=<||>,entry,def,mult,need,value,contract,cs,assum},
 req=nloRequest[table,request];e=table["DimensionalRegulator"];s=req["Scale"];mandel=req["MandelstamVariables"];
 {v,w}=req["Variables"];setup=table["Definitions"]["Setup"];
 loops=Lookup[Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"LoopOrder"];
 If[Sort[loops]=!={0,1}||Length[setup["PhaseSpaceMomentum"]]=!=1,nloFail["OneOrientedVirtualBornInterferenceRequired"]];
 input=nloIntegralInput[table,req["KinematicConditions"]];
 definitions=nloCheck[ConstructMasterIntegralDefinitions[input],"VirtualMasterDefinitionsFailed"]["MasterIntegralDefinitions"];
 norm=nloCheck[PartonicInvariantDensityNormalization[setup,<|"Scale"->s,"DimensionalRegulator"->e|>],"VirtualNormalizationFailed"];
 rules=Thread[mandel->{s,s(v-1),-s v}];
 conversions=Association[Map[#["MasterIntegral"]->nloCheck[MasterIntegralMeasureConversion[#],"VirtualMeasureConversionFailed"]["Factor"]&,Values[definitions]]];
 Do[entry=table["Masters"][[i]];def=definitions[i];
  If[coefficientMasterID[entry["Master"]]=!=coefficientMasterID[def["MasterIntegral"]]||def["CutIndices"]=!={},nloFail["VirtualMasterDefinitionMismatch"]];
  mult=(table["PreFactor"]norm["Factor"]req["RenormalizationScaleSquared"]^e conversions[entry["Master"]]
   Total[(#["PreFactor"]#["Coefficient"]& /@ entry["Terms"])])/.rules;
  (* Only a sufficient lower bound is required. An analytic sum need not
     have an immediately computable exact valuation. *)
  need=nloCheck[DetermineMeromorphicLaurentLowerBound[mult,e],"VirtualCoefficientOrderFailed"];
  If[!IntegerQ[need]&&need=!=Infinity,nloFail["VirtualCoefficientLaurentOrderRequired"]];
  need=If[need===Infinity,-2,Max[-2,-need]];
  value=nloCheck[EvaluateOneLoopIntegral[def,{-2,need}],"VirtualMasterEvaluationFailed"];
  AssociateTo[values,i->value],{i,Length[table["Masters"]]}];
 contract=WithEpsilonRemainderChecks[ContractAnalyticMasterCoefficients[table,values,<|"EpsilonOrderRange"->{-2,0},
  "Normalization"->norm["Factor"]req["RenormalizationScaleSquared"]^e,"MeasureConversions"->conversions,"KinematicRules"->rules|>]];
 nloCheck[contract["Result"],"VirtualMasterContractionFailed"];
 assum=req["Assumptions"]&&(setup["HadronicVariables"]["Assumptions"]/.rules);
 cs=Map[Function[expr,partonicCollect[2nloCheck[FeynFacetSolution`RealPartOnPhysicalDomain[expr,assum],"VirtualPhysicalRealPartFailed"]/(s v)]],contract["Result"]["Coefficients"]];
 nloContribution["Virtual",e,w,partonicDistribution[#,<||>,0]& /@ cs,req,<|"Normalization"->norm,
  "MasterCount"->Length[values],
  "EpsilonRemainderAudit"->contract["EpsilonRemainderAudit"],"InterferenceMultiplicity"->"One oriented interference plus its complex conjugate"|>]
 ],"AnalyticNLO"];
ConstructNLORealContribution[table_Association,request_Association]:=Catch[Module[
 {req,e,s,mandel,v,w,z,setup,input,definitions,representations,norm,rules,entry,def,rep,value,conversion,expr,
  expansion,audit,outputs={},cs,parts,delta,plus,markers,unresolved,realPlusOrders},
 req=nloRequest[table,request];e=table["DimensionalRegulator"];s=req["Scale"];mandel=req["MandelstamVariables"];
 {v,w}=req["Variables"];z=Unique["thresholdVariable"];setup=table["Definitions"]["Setup"];
 If[Lookup[Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"LoopOrder"]=!={0,0}||Length[setup["PhaseSpaceMomentum"]]=!=2,
  nloFail["TreeAmplitudeWithTwoUnobservedParticlesRequired"]];
 input=nloIntegralInput[table,req["KinematicConditions"]];
 definitions=nloCheck[ConstructMasterIntegralDefinitions[input],"RealMasterDefinitionsFailed"]["MasterIntegralDefinitions"];
 representations=nloCheck[ConstructMasterIntegralRepresentations[input],"RealMasterRepresentationsFailed"];
 If[representations["UnresolvedIntegralDefinitions"]=!=<||>,nloFail["AnalyticRealMastersIncomplete"]];
 norm=nloCheck[PartonicInvariantDensityNormalization[setup,<|"Scale"->s,"DimensionalRegulator"->e|>],"RealNormalizationFailed"];
 rules=Thread[mandel->{s,s(v-1),-s v(1-z)}];
 Do[entry=table["Masters"][[i]];def=definitions[i];rep=representations["MasterIntegralRepresentations"][i];
  If[coefficientMasterID[entry["Master"]]=!=coefficientMasterID[def["MasterIntegral"]]||
   coefficientMasterID[entry["Master"]]=!=coefficientMasterID[rep["MasterIntegral"]]||
   !AllTrue[rep["Terms"],#["IntegrationVariables"]==={}&],nloFail["ExplicitRealMasterValueRequired"]];
  value=Total[Lookup[rep["Terms"],"Prefactor"]];conversion=nloCheck[MasterIntegralMeasureConversion[def],"RealMeasureConversionFailed"]["Factor"];
  expr=Factor[(Total[(#["PreFactor"]#["Coefficient"]& /@ entry["Terms"])]table["PreFactor"]norm["Factor"]
   req["RenormalizationScaleSquared"]^e conversion value)/.Lookup[req,"ColorRules",{}]/.rules];
  audit=WithEpsilonRemainderChecks[
   expansion=ConstructAnalyticEndpointExpansion[expr,<|"DimensionalRegulator"->e,"Variable"->z,
    "Assumptions"->req["Assumptions"],"ThroughOrder"->0,"EndpointConditions"->Lookup[req,"EndpointConditions",<||>]|>];
   If[FailureQ[expansion],expansion,ExtractEndpointDistributions[expansion,<|"ThroughOrder"->0|>]]];
  nloCheck[audit["Result"],"RealEndpointExpansionFailed"];
  AppendTo[outputs,<|"MasterIntegral"->entry["Master"],"EndpointLeadingPower"->expansion["EndpointLeadingPower"],
   "EpsilonRemainderAudit"->audit["EpsilonRemainderAudit"],"Coefficients"->audit["Result"]["Components"][[1]]["Coefficients"]|>],{i,Length[table["Masters"]]}];
 cs=Association@Table[j->Total[Lookup[#["Coefficients"],j,0]& /@ outputs],
  {j,Min[-2,Min[Flatten[Keys /@ Lookup[outputs,"Coefficients"]]]],0}];
 delta=Unique["deltaCoefficient"];plus=Unique["plusCoefficient"];
 cs=cs/.{EndpointDeltaDerivative[_,0,1]->delta,EndpointPlusDistribution[_,-1,k_,1,1]:>plus[k]}/.z->1-w;
 If[!FreeQ[cs,_EndpointDeltaDerivative|_EndpointPlusDistribution],nloFail["NLODistributionBasisIncomplete"]];
 realPlusOrders=Union[{0,1},Cases[cs,plus[k_Integer]:>k,Infinity]];
 parts=Map[Function[x,partonicDistribution[Coefficient[x,delta],
   Association@Table[k->Coefficient[x,plus[k]],{k,realPlusOrders}],x/.delta->0/.plus[_]->0]],cs];
 nloContribution["Real",e,w,parts,req,<|"Normalization"->norm,"MasterCount"->Length[outputs],
  "MasterEndpointOrders"->(KeyDrop[#,"Coefficients"]& /@ outputs)|>]
 ],"AnalyticNLO"];
ConstructZeroAmplitudeContribution[records_List,request_Association]:=Catch[Module[{setup,expected,actual,e,w,cs},
 If[records==={}||!AllTrue[records,AssociationQ]||!ContainsAll[Keys[request],{"Contribution","DimensionalRegulator","Variables"}],nloFail["ZeroAmplitudeRecordsRequired"]];
 setup=records[[1]]["Setup"];expected=Tuples[Lookup[Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"DiagramIndices"]];
 actual=Lookup[Lookup[records,"Pair"],{"Forward","Conjugate"}];
 If[Sort[actual]=!=Sort[expected]||!DuplicateFreeQ[actual],nloFail["ZeroAmplitudeDiagramCoverageIncomplete"]];
 If[!AllTrue[records,KeyDrop[#["Setup"],{"ForwardAmplitudes","ConjugateAmplitudes","SourceNotebook","CardName"}]===
    KeyDrop[setup,{"ForwardAmplitudes","ConjugateAmplitudes","SourceNotebook","CardName"}]&&#["Integrand"]===0&&#["Topologies"]==={}&&#["Setup"]["Partons"]===setup["Partons"]&&
   #["Setup"]["HadronLongSpin"]===setup["HadronLongSpin"]&&#["Setup"]["HadronTransSpin"]===setup["HadronTransSpin"]&],nloFail["EveryGeneratedInterferenceMustVanish"]];
 e=request["DimensionalRegulator"];w=Last[request["Variables"]];cs=Association@Table[j->partonicDistribution[0,<||>,0],{j,-2,0}];
 nloContribution[request["Contribution"],e,w,cs,request,<|"ExactInEpsilon"->True,"GeneratedInterferenceCount"->Length[records],
  "ZeroDerivation"->"Every selected generated Dirac/color interference is exactly zero in D dimensions before integral reduction"|>]
 ],"AnalyticNLO"];
AssembleNLOHardFunction[contributions_Association,request_Association]:=Catch[Module[
  {required,combined,assum,color,coefficients,logs,reduced,check,final},
  If[!ContainsAll[Keys[request],{"RequiredContributions","Scale","Variables","Assumptions"}],
    nloFail["NLOAssemblyRequestIncomplete"]];
  required=request["RequiredContributions"];
  If[Sort[Keys[contributions]]=!=Sort[required]||!DuplicateFreeQ[required],
    nloFail["NLOContributionCoverageIncomplete"]];
  combined=nloCheck[CombinePartonicResults[contributions,<|"Contribution"->"Total"|>],
    "NLOResultConventionMismatch"];
  If[combined["Order"]=!="NLO"||combined["Scale"]=!=request["Scale"]||
    combined["Variables"]=!=request["Variables"],nloFail["NLOContributionVariableMismatch"]];
  If[!ContainsAll[combined["IncludedContributions"],{"Real","Virtual","Counterterm"}],
    nloFail["RealVirtualAndUVContributionsRequired"]];
  If[RequirePartonicEpsilonRange[combined,{0,0}]=!=True,nloFail["FiniteNLOContributionsRequired"]];
  assum=request["Assumptions"];color=Lookup[request,"ColorRules",{}];
  coefficients=KeySelect[combined["Coefficients"],#<=0&];
  coefficients=coefficients/.color/.q_PolyGamma:>FunctionExpand[q];
  logs=nloCheck[FeynFacetSolution`ExpandPositiveLogarithms[coefficients,assum],"NLOLogarithmBranchesFailed"];
  reduced=nloMapDistributions[partonicCollect,logs];
  reduced=nloMapDistributions[Function[x,partonicCollect[
    nloCheck[FeynFacetSolution`ExpandPositiveLogarithms[x,assum],"NLOLogarithmBranchesFailed"]]],reduced];
  combined=nloCheck[CreatePartonicResult[reduced,Join[combined,<|"Assumptions"->assum|>]],"SimplifiedNLOResultRequired"];
  check=VerifyPartonicPoleCancellation[<|"Total"->combined|>];
  If[!AssociationQ[check]||check["Status"]=!="Passed",
    nloFail["NLOPolesDoNotCancel",<|"Check"->check|>]];
  final=nloCheck[FinalizePartonicResults[<|"Total"->combined|>,check,<|"RequireAlgebraicIdentityProof"->True,"Metadata"-><|
    "PoleCancellation"->"Exact symbolic zero in every delta, plus and regular coefficient",
    "Contributions"->required,"Domain"->assum,"Description"->Lookup[request,"Description",<||>]|>|>],
    "ExplicitIntegralFreeNLOHardFunctionRequired"];
  final["Total"]
],"AnalyticNLO"];
End[];EndPackage[];
