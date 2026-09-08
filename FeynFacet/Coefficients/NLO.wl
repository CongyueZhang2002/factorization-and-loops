(* Analytic massless NLO contributions for single-inclusive partonic
   densities. All process information enters through amplitude and assembly
   cards; integral methods are selected from momentum geometry. *)
BeginPackage["FeynFacet`"];
ConstructNLOVirtualContribution::usage="ConstructNLOVirtualContribution[table,request] evaluates the required one-loop masters, contracts them with exact coefficients and forms one oriented interference plus its conjugate. Request declares Scale, MandelstamVariables, Variables {v,w}, KinematicConditions, Assumptions and RenormalizationScaleSquared.";
ConstructNLORealContribution::usage="ConstructNLORealContribution[table,request] recognizes analytic two-body phase-space masters and returns explicit delta/plus/regular Laurent coefficients. Request additionally supplies the endpoint domain conditions used by ConstructAnalyticEndpointExpansion.";
ConstructZeroAmplitudeContribution::usage="ConstructZeroAmplitudeContribution[records,request] returns an exact zero only after checking every selected interference is present, has an explicitly zero integrand and has no remaining integral topology. It does not infer zero from the process name.";
AssembleNLOHardFunction::usage="AssembleNLOHardFunction[contributions,request] combines named real, virtual, UV and collinear records, checks exact pole cancellation, and returns explicit LO and finite NLO delta/plus/regular coefficients. Request supplies RequiredContributions, BornDensity, Scale, Variables, Assumptions, and optional ColorRules and Description.";
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
nloDistributionRecord[delta_,plus_,regular_]:=<|"DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular|>;
nloCollect[expr_]:=With[{atoms=DeleteDuplicates[Cases[expr,_Log|_PolyLog,{0,Infinity}]]},
 If[atoms==={},Factor[expr],Collect[expr,atoms,Factor]]];
nloMapDistributions[f_,rows_Association]:=Map[Function[row,nloDistributionRecord[
 f[row["DeltaCoefficient"]],f /@ row["PlusCoefficients"],f[row["RegularCoefficient"]]]],rows];
nloContribution[type_,e_,w_,cs_,data_:<||>]:=Join[<|"Format"->"FeynFacet-NLOContribution","FormatVersion"->1,
 "Contribution"->type,"DimensionalRegulator"->e,"Variable"->w,"LaurentLowerBound"->Min[Keys[cs]],
 "KnownThroughOrder"->Max[Keys[cs]],"Coefficients"->cs,"DensityConvention"->"E_c d sigma/d^(D-1)p_c"|>,data];
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
  need=-nloCheck[DetermineLaurentValuation[mult,e],"VirtualCoefficientOrderFailed"];
  If[!IntegerQ[need],nloFail["VirtualCoefficientLaurentOrderRequired"]];
  value=nloCheck[EvaluateOneLoopIntegral[def,{-2,need}],"VirtualMasterEvaluationFailed"];
  AssociateTo[values,i->value],{i,Length[table["Masters"]]}];
 contract=WithEpsilonRemainderChecks[ContractAnalyticMasterCoefficients[table,values,<|"EpsilonOrderRange"->{-2,0},
  "Normalization"->norm["Factor"]req["RenormalizationScaleSquared"]^e,"MeasureConversions"->conversions,"KinematicRules"->rules|>]];
 nloCheck[contract["Result"],"VirtualMasterContractionFailed"];
 assum=req["Assumptions"]&&(setup["HadronicVariables"]["Assumptions"]/.rules);
 cs=Map[Function[expr,nloCollect[2nloCheck[FeynFacetSolution`RealPartOnPhysicalDomain[expr,assum],"VirtualPhysicalRealPartFailed"]/(s v)]],contract["Result"]["Coefficients"]];
 nloContribution["Virtual",e,w,nloDistributionRecord[#,<||>,0]& /@ cs,<|"Normalization"->norm,
  "MasterCount"->Length[values],"MasterValues"->values,"MasterDefinitions"->definitions,
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
   req["RenormalizationScaleSquared"]^e conversion value)/.rules];
  audit=WithEpsilonRemainderChecks[
   expansion=ConstructAnalyticEndpointExpansion[expr,<|"DimensionalRegulator"->e,"Variable"->z,
    "Assumptions"->req["Assumptions"],"ThroughOrder"->0,"EndpointConditions"->Lookup[req,"EndpointConditions",<||>]|>];
   If[FailureQ[expansion],expansion,ExtractEndpointDistributions[expansion,<|"ThroughOrder"->0|>]]];
  nloCheck[audit["Result"],"RealEndpointExpansionFailed"];
  AppendTo[outputs,<|"MasterIntegral"->entry["Master"],"EndpointLeadingPower"->expansion["EndpointLeadingPower"],
   "EpsilonRemainderAudit"->audit["EpsilonRemainderAudit"],"Coefficients"->audit["Result"]["Components"][[1]]["Coefficients"]|>],{i,Length[table["Masters"]]}];
 cs=Association@Table[j->Total[Lookup[#["Coefficients"],j,0]& /@ outputs],
  {j,Min[Flatten[Keys /@ Lookup[outputs,"Coefficients"]]],0}];
 delta=Unique["deltaCoefficient"];plus=Unique["plusCoefficient"];
 cs=cs/.{EndpointDeltaDerivative[_,0,1]->delta,EndpointPlusDistribution[_,-1,k_,1,1]:>plus[k]}/.z->1-w;
 If[!FreeQ[cs,_EndpointDeltaDerivative|_EndpointPlusDistribution],nloFail["NLODistributionBasisIncomplete"]];
 realPlusOrders=Union[{0,1},Cases[cs,plus[k_Integer]:>k,Infinity]];
 parts=Map[Function[x,nloDistributionRecord[Coefficient[x,delta],
   Association@Table[k->Coefficient[x,plus[k]],{k,realPlusOrders}],x/.delta->0/.plus[_]->0]],cs];
 nloContribution["Real",e,w,parts,<|"Normalization"->norm,"MasterCount"->Length[outputs],
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
 e=request["DimensionalRegulator"];w=Last[request["Variables"]];cs=Association@Table[j->nloDistributionRecord[0,<||>,0],{j,-2,0}];
 nloContribution[request["Contribution"],e,w,cs,<|"ExactInEpsilon"->True,"GeneratedInterferenceCount"->Length[records],
  "ZeroDerivation"->"Every selected generated Dirac/color interference is exactly zero in D dimensions before integral reduction"|>]
 ],"AnalyticNLO"];
AssembleNLOHardFunction[contributions_Association,request_Association]:=Catch[Module[
 {required,all,variables,s,v,w,assum,color,e,cs,logs,reduced,finite,poles,born,bornDelta,explicit,labels,rows,plusOrders,regulators,regulatorNames},
 If[!ContainsAll[Keys[request],{"RequiredContributions","BornDensity","Scale","Variables","Assumptions"}],nloFail["NLOAssemblyRequestIncomplete"]];
 required=request["RequiredContributions"];If[Sort[Keys[contributions]]=!=Sort[required]||!DuplicateFreeQ[required],nloFail["NLOContributionCoverageIncomplete"]];
 all=Values[contributions];If[!AllTrue[all,AssociationQ[#]&&Lookup[#,"Format",None]==="FeynFacet-NLOContribution"&&#["KnownThroughOrder"]>=0&],nloFail["FiniteNLOContributionsRequired"]];
 {v,w}=request["Variables"];s=request["Scale"];assum=request["Assumptions"];color=Lookup[request,"ColorRules",{}];
 e=First[all]["DimensionalRegulator"];If[!AllTrue[all,#["Variable"]===w&],nloFail["NLOContributionVariableMismatch"]];
 If[!ContainsAll[Lookup[all,"Contribution"],{"Real","Virtual","UVCounterterm"}],nloFail["RealVirtualAndUVContributionsRequired"]];
 If[!AllTrue[all,IntegerQ[#["LaurentLowerBound"]]&&IntegerQ[#["KnownThroughOrder"]]&&
   Sort[Keys[#["Coefficients"]]]===Range[#["LaurentLowerBound"],#["KnownThroughOrder"]]&],
  nloFail["ContiguousNLOContributionEpsilonOrdersRequired"]];
 rows=Flatten[Values /@ Lookup[all,"Coefficients"]];
 If[!AllTrue[rows,AssociationQ[#]&&ContainsAll[Keys[#],{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]&&
   AssociationQ[#["PlusCoefficients"]]&&AllTrue[Keys[#["PlusCoefficients"]],IntegerQ[#]&&#>=0&]&],
  nloFail["ExplicitNLODistributionCoefficientsRequired"]];
 regulators=DeleteDuplicates[Lookup[all,"DimensionalRegulator"]];
 If[!AllTrue[regulators,Head[#]===Symbol&],nloFail["DeclaredNLORegulatorSymbolsRequired"]];
 regulatorNames=SymbolName /@ regulators;
 If[!FreeQ[rows,q_Symbol/;MemberQ[regulatorNames,SymbolName[q]]],
  nloFail["RegulatorFreeNLOEpsilonCoefficientsRequired"]];
 plusOrders=Union[{0,1},Flatten[Keys /@ Lookup[rows,"PlusCoefficients"]]];
 cs=Association@Table[j->nloDistributionRecord[
   Total[Lookup[Lookup[#["Coefficients"],j,<||>],"DeltaCoefficient",0]& /@ all],
   Association@Table[k->Total[Lookup[Lookup[Lookup[#["Coefficients"],j,<||>],"PlusCoefficients",<||>],k,0]& /@ all],{k,plusOrders}],
   Total[Lookup[Lookup[#["Coefficients"],j,<||>],"RegularCoefficient",0]& /@ all]],{j,Min[Lookup[all,"LaurentLowerBound"]],0}];
 cs=cs/.color/.q_PolyGamma:>FunctionExpand[q];
 logs=nloCheck[FeynFacetSolution`ExpandPositiveLogarithms[cs,assum],"NLOLogarithmBranchesFailed"];
 reduced=nloMapDistributions[nloCollect,logs];
 reduced=nloMapDistributions[Function[x,nloCollect[nloCheck[FeynFacetSolution`ExpandPositiveLogarithms[x,assum],"NLOLogarithmBranchesFailed"]]],reduced];
 poles=KeySelect[reduced,#<0&];
 If[!AllTrue[Flatten[({#["DeltaCoefficient"],Values[#["PlusCoefficients"]],#["RegularCoefficient"]}& /@ Values[poles])],#===0&],
  nloFail["NLOPolesDoNotCancel",<|"Residues"->poles|>]];
 finite=reduced[0];born=request["BornDensity"];
 bornDelta=((born["Coefficient"]/.born["DimensionalRegulator"]->0)/.Thread[born["MandelstamVariables"]->{s,s(v-1),-s v}])/(s v);
 explicit={finite,bornDelta};
 If[!FreeQ[explicit,_Integrate|_NIntegrate|_FeynFacetSolution`F|_FeynFacetSolution`K|_FeynFacetSolution`a|_FeynFacetSolution`G|_FeynFacetSolution`B|_FeynFacetSolution`C|_Inactive|_Hypergeometric2F1|_FeynCalc`GLI|_SeriesData|_Series|_SeriesCoefficient|_Failure|_Missing|_Re|_Im|_Conjugate|_PolyGamma|_Gamma|Indeterminate|_DirectedInfinity],nloFail["ExplicitIntegralFreeNLOHardFunctionRequired"]];
 <|"Format"->"FeynFacet-NLOHardFunction","FormatVersion"->1,"Variables"->{v,w},"Scale"->s,
  "DensityConvention"->"E_c d sigma/d^3 p_c","PerturbativeTerms"-><|"LO"->nloDistributionRecord[Factor[bornDelta/.color],<||>,0],"NLO"->finite|>,
  "PoleCancellation"->"Exact symbolic zero in every delta, plus and regular coefficient","Contributions"->required,
  "Domain"->assum,"Description"->Lookup[request,"Description",<||>],
  "PlusConvention"->"PlusCoefficients[k] multiplies [Log[1-w]^k/(1-w)]_+ on [0,1]; test functions exclude w=0 and v=0,1"|>
 ],"AnalyticNLO"];
End[];EndPackage[];
