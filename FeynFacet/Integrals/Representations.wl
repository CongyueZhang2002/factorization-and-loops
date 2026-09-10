(* Integral definitions from topology data, with the existing AMFlow measure.
   This constructs representations, not a new basis or boundary normalization. *)
Begin["FeynFacet`Private`"];
Clear[miRepFC,miRepFamilyName,miRepReadReference,miRepSourceData,miRepKiraRules,
 miRepFamilyData,miRepDefinition,miRepOrdinary,miRepBaikov,miRepPhaseVolume,
 miRepBuild,miRepSimplexSectors,miRepTerm,miRepCutFromFamily,miRepClosedCutTerms,miRepFactorized];

miRepFC[z_] := Module[{symbols,rules},
 symbols=DeleteDuplicates[Cases[z,s_Symbol /; MemberQ[
  {"GLI","FCTopology","FeynAmpDenominator","StandardPropagatorDenominator",
   "PropagatorDenominator","Pair","Momentum","SPD","SP"},SymbolName[s]],
  {0,Infinity},Heads->True]];
 (* Resolve the replacement symbols before traversing held Association values. *)
 rules=(#->Symbol["FeynCalc`"<>SymbolName[#]]& /@ symbols);
 z/.Dispatch[rules]
];
miRepFamilyName[z_] := If[StringQ[z],z,If[Head[z]===Symbol,SymbolName[z],ToString[z,InputForm]]];

miRepReadReference[ref_,root_] := Module[{path},
 If[!AssociationQ[ref] || !StringQ[Lookup[ref,"RelativePath",None]],
  epsOrderFail["IntegralDefinitionReferenceRequired"]];
 path=ExpandFileName[FileNameJoin[{root,ref["RelativePath"]}]];
 If[!FileExistsQ[path],epsOrderFail["IntegralDefinitionFileMissing",<|"Path"->path|>]];
 If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],
  Block[{$Context="Global`",$ContextPath={"System`","Global`","FeynCalc`","FeynFacet`"}},Get[path]]]
];

(* The Kira writer emits one scalar-product rule per line. Read that restricted
   format; do not evaluate arbitrary YAML text as Wolfram Language code. *)
miRepKiraRules[path_,momenta_,invariants_] := Module[{lines,result={},m,parts,a,b,rhs,held,names},
 If[!FileExistsQ[path],epsOrderFail["KinematicDefinitionsFileMissing",<|"Path"->path|>]];
 lines=StringSplit[Import[path,"Text"],"\n"];
 names=AssociationThread[SymbolName /@ Join[momenta,invariants],Join[momenta,invariants]];
 Do[
  m=StringCases[line,RegularExpression[
   "^\\s*-\\s*\\[\\s*\\[\\s*([A-Za-z][A-Za-z0-9]*)\\s*,\\s*([A-Za-z][A-Za-z0-9]*)\\s*\\]\\s*,\\s*(.*?)\\s*\\]\\s*$"] :> {"$1","$2","$3"}];
  If[m==={},Continue[]];{a,b,rhs}=First[m];
  If[!KeyExistsQ[names,a] || !KeyExistsQ[names,b] ||
    !StringMatchQ[rhs,RegularExpression["[A-Za-z0-9 +*/^().-]+"]],
    epsOrderFail["UnsupportedKiraScalarProductRule"]];
  held=ToExpression[rhs,InputForm,HoldComplete];
  If[!FreeQ[held,_Real] || !AllTrue[
    Cases[held,s_Symbol:>s,Infinity],KeyExistsQ[names,SymbolName[#]]&],
    epsOrderFail["UnknownKiraInvariant"]];
  held=held/.s_Symbol /; KeyExistsQ[names,SymbolName[s]]:>names[SymbolName[s]];
  AppendTo[result,FeynCalc`FCI[FeynCalc`SPD[names[a],names[b]]]->ReleaseHold[held]],
 {line,lines}];
 If[result==={},epsOrderFail["KiraScalarProductRulesNotFound"]];result
];

miRepSourceData[input_,root_] := Module[{s=input,ref,base,definition,registry,kin={},rules={},presentation},
 If[!KeyExistsQ[s,"Topologies"]&&ListQ[Lookup[s,"Families",None]],
  s=Append[s,"Topologies"->s["Families"]]];
 If[Lookup[s,"DataType",None]==="FamilyDLogEpsilonForm",
  ref=Lookup[Lookup[s,"BlockDecomposition",<||>],"FamilyDifferentialSystemReference",None];
  base=miRepReadReference[ref,root];
  If[!AssociationQ[base],epsOrderFail["DifferentialSystemReferenceInvalid"]];
  If[miRepFamilyName[Lookup[base,"Family",None]]=!=miRepFamilyName[s["Family"]],
   epsOrderFail["IntegralDefinitionFamilyMismatch"]];
  s=Join[base,s,<|"KinematicVariables"->s["CoefficientVariables"]|>]
 ];
 ref=Lookup[Lookup[s,"MathematicalInputReferences",<||>],"CanonicalRegistry",None];
 If[!KeyExistsQ[s,"Topology"] && !KeyExistsQ[s,"TopologyRecord"] &&
   !KeyExistsQ[s,"Topologies"] && AssociationQ[ref],
  registry=miRepFC[miRepReadReference[ref,root]];
  registry=Lookup[registry,"Registry",registry];
  s=Join[s,<|"Topologies"->registry["Families"],
    "LoopSectorData"->registry["SectorData"]|>]
 ];
 definition=Lookup[s,"KinematicVariableDefinition",<||>];
 ref=Lookup[Lookup[s,"MathematicalInputReferences",<||>],"KinematicsConfiguration",None];
 If[AssociationQ[ref] && !KeyExistsQ[s,"KinematicRules"],
  base=FirstCase[Lookup[s,"Topologies",{}],a_Association /;
    miRepFamilyName[Lookup[a,"Name",None]]===miRepFamilyName[Lookup[s,"Family",None]],None];
  If[AssociationQ[base],
   kin=miRepKiraRules[FileNameJoin[{root,ref["RelativePath"]}],base["Topology"][[4]],
     Lookup[definition,"SourceInvariantSymbols",{}]];
   rules=Join[Flatten[{Lookup[definition,"ScaleNormalization",{}]}],
     Lookup[definition,"KinematicVariableRules",{}]];
   presentation=Lookup[s,"CoefficientPresentation",<||>];
   kin=kin/.rules/.Lookup[presentation,"SourceVariableSubstitution",{}];
   s=Join[s,<|"KinematicRules"->kin|>]
  ]
 ];
 miRepFC[s]
];

miRepFamilyData[source_,master_] := Module[{family,records,record,top,s,flow,loops,sectors,pres,matches,particles,cutRank},
 family=master[[1]];
 records=Replace[Lookup[source,"Topologies",{}],
   t_FeynCalc`FCTopology:><|"Topology"->t|>,{1}];
 record=Lookup[source,"TopologyRecord",source];
 If[records=!={},
  matches=Select[records,Function[r,
   top=Lookup[r,"Topology",None];
   MatchQ[top,_FeynCalc`FCTopology] && miRepFamilyName[top[[1]]]===miRepFamilyName[family]]];
  If[Length[matches]>1,epsOrderFail["AmbiguousMasterTopologyName",<|"Family"->family|>]];
  record=If[matches==={},None,First[matches]]];
 If[!AssociationQ[record],epsOrderFail["MasterTopologyNotFound",<|"MasterIntegral"->master|>]];
 s=Join[KeyDrop[source,{"Topologies","TopologyRecord"}],record];
 top=Lookup[s,"Topology",None];
 If[!MatchQ[top,_FeynCalc`FCTopology] || Length[top]<5 ||
   miRepFamilyName[top[[1]]]=!=miRepFamilyName[family],
  epsOrderFail["MasterTopologyNotFound",<|"MasterIntegral"->master|>]];
 top=ReplacePart[top,2->(FeynCalc`ToSFAD /@ top[[2]])];
 s=Join[s,<|"Topology"->top|>];
 loops=top[[3]];
 If[!KeyExistsQ[s,"Prescription"],
  flow=Which[
   MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[s,"Format",None]],
    particles=Select[s["Cuts"],#["Type"]==="Particle"&];
    cutRank=MatrixRank[Table[Coefficient[cut["Momentum"],ell],{cut,particles},{ell,loops}]];
    If[cutRank=!=Length[loops],epsOrderFail["MixedCutAndVirtualLoopPrescriptionsRequired"]];
    <|"LoopMomenta"->loops,"Prescription"->ConstantArray[0,Length[loops]]|>,
   AssociationQ[Lookup[s,"Setup",None]],FeynFacet`AMFlowPrescription[s["Setup"]],
   AssociationQ[Lookup[s,"LoopSectorData",None]],
    sectors=s["LoopSectorData"];
    <|"LoopMomenta"->sectors["LoopMomenta"],
      "Prescription"->(sectors["Sectors"]/.{"PhaseSpace"->0,"Forward"->1,"Conjugate"->-1})|>,
   Lookup[s,"CutIndices",{}]==={},<|"LoopMomenta"->loops,"Prescription"->ConstantArray[1,Length[loops]]|>,
   True,epsOrderFail["LoopPrescriptionRequired"]];
  If[!AssociationQ[flow] || Sort[flow["LoopMomenta"]]=!=Sort[loops],
   epsOrderFail["LoopPrescriptionMomentaMismatch"]];
  pres=Lookup[AssociationThread[flow["LoopMomenta"],flow["Prescription"]],loops];
  s=Join[s,<|"Prescription"->pres|>]
 ];
 s
];

miRepDefinition[s_,master_,e_] := Module[
 {top=s["Topology"],loops,dim,nu,cuts,dirs,cm,pres,desc,cores,kin,virt,phase,measure,extra,
  components,sideSets,cutData,eta,standard,definition,certificate},
 If[MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[s,"Format",None]],
  Return[miRepTypedDefinition[s,master,e]]];
 loops=top[[3]];nu=master[[2]];dim=Lookup[s,"Dimension",4-2e];
 cuts=Lookup[s,"CutIndices",{}];dirs=Lookup[s,"CutDirections",ConstantArray[1,Length[cuts]]];
 pres=s["Prescription"];
 If[Length[nu]=!=Length[top[[2]]] || !VectorQ[nu,IntegerQ] ||
  !DuplicateFreeQ[cuts] || !VectorQ[cuts,IntegerQ[#]&&1<=#<=Length[nu]&] ||
  !VectorQ[pres,MemberQ[{-1,0,1},#]&] || Length[pres]=!=Length[loops] ||
  Length[dirs]=!=Length[cuts] || !VectorQ[dirs,MemberQ[{-1,1},#]&],
  epsOrderFail["IntegralDefinitionIndicesInvalid"]];
 kin=masterIntegralLastRules[FeynCalc`FCI[Join[top[[5]],Lookup[s,"KinematicRules",{}]]]];
 desc=propagatorDescriptor[#,kin]& /@ top[[2]];
 If[MemberQ[desc,$Failed] || !AllTrue[desc,#["Power"]===1&],
  epsOrderFail["UnitPowerTopologyPropagatorsRequired"]];
 cores=FeynCalc`ExpandScalarProduct[#["UnitCore"]]& /@ desc;
 cores=cores/.kin;
 cm=Lookup[s,"CutMomenta",Lookup[desc[[cuts]],"Momentum",{}]];
 If[Length[cm]=!=Length[cuts] || !AllTrue[desc[[cuts]],#["Type"]==="QuadraticLorentzian"&],
  epsOrderFail["OrientedQuadraticCutsRequired"]];
 (* An oriented cut momentum must be the same line as the cut denominator. *)
 Do[If[!epsOrderZero[FeynCalc`ExpandScalarProduct[
   FeynCalc`FCI[FeynCalc`SPD[cm[[j]]]-FeynCalc`SPD[desc[[cuts[[j]],"Momentum"]]]]]],
   epsOrderFail["CutMomentumDoesNotMatchPropagator"]],{j,Length[cuts]}];
 cm=MapThread[Times,{cm,dirs}];
 sideSets=Table[DeleteDuplicates[DeleteCases[
   Pick[pres,(!FreeQ[cores[[i]],#]&) /@ loops],0]],{i,Length[cores]}];
 If[AnyTrue[sideSets[[cuts]],#=!={}&],epsOrderFail["CutDependsOnVirtualMomentum"]];
 If[AnyTrue[Select[Range[Length[nu]],nu[[#]]>0 && !MemberQ[cuts,#]&],
   Length[sideSets[[#]]]>1&],epsOrderFail["DenominatorMixesVirtualPrescriptions"]];
 (* Preserve the eta sign of the actual stored polynomial, including any
    minus sign absorbed by FCLoopSwitchEtaSign. Side labels fix the measure. *)
 eta=Table[If[MemberQ[cuts,i]||nu[[i]]<=0,0,
   FirstCase[FeynCalc`FCI[top[[2,i]]],FeynCalc`StandardPropagatorDenominator[___,{_,sign_}]:>sign,1,Infinity]],{i,Length[nu]}];
 virt=Count[pres,1]+Count[pres,-1];phase=Count[pres,0];
 components=Length[cuts]-phase;
 If[(cuts==={} && phase>0) || (cuts=!={} && (phase<1 || components<1)),
  epsOrderFail["PhaseSpaceLoopAndCutCountsInconsistent"]];
 measure=(I Pi^(dim/2))^-virt (-1)^Count[pres,-1] *
   If[cuts==={},1,(2Pi)^(components dim-Length[cuts](dim-1))];
 extra=Lookup[s,"MasterIntegralPrefactor",1];
 If[!FreeQ[extra,Alternatives@@loops] || !FreeQ[{cores,measure,extra},_Real],
  epsOrderFail["ExactMomentumIndependentMasterPrefactorRequired"]];
 cutData=MapThread[<|"PropagatorIndex"->#1,"Momentum"->#2,
   "InversePropagator"->cores[[#1]],"Power"->nu[[#1]],
   "DeltaDerivativeOrder"->Max[0,nu[[#1]]-1],
   "DistributionCoefficient"->If[nu[[#1]]>0,(-1)^(nu[[#1]]-1)/(nu[[#1]]-1)!,0]|>&,{cuts,cm}];
 definition=<|"MasterIntegral"->master,"LoopMomenta"->loops,"ExternalMomenta"->top[[4]],
  "DimensionalRegulator"->e,"Dimension"->dim,"InversePropagators"->cores,
  "PropagatorMomenta"->Lookup[desc,"Momentum"],
  "PropagatorTypes"->Lookup[desc,"Type"],
  "TimeDirection"->Lookup[s,"TimeDirection",Expand[Total[cm]]],
  "PropagatorPowers"->nu,"CutIndices"->cuts,"OrientedCutMomenta"->cm,
  "CutDistributions"->cutData,"Prescription"->pres,"PropagatorPrescriptions"->eta,
  "MomentumSpaceConvention"->"AMFlow","MeasurePrefactor"->measure,
  "MasterIntegralPrefactor"->extra,"KinematicRules"->kin,
  "KinematicConditions"->Lookup[s,"KinematicConditions",Lookup[s,"Assumptions",True]],
  "VirtualLoopCount"->virt,"PhaseSpaceLoopCount"->phase,
  "MomentumConservationDeltaCount"->If[cuts==={},0,components],
  "CutDistributionConvention"->"theta(q^0) (-1)^(a-1) delta^(a-1)(D)/(a-1)!; a<=0 gives zero.",
  "MeasureConvention"->"d^D l/(i pi^(D/2)) for +i0 virtual loops, -d^D l/(i pi^(D/2)) for -i0 virtual loops; standard Lorentz-invariant phase space for cut particles.",
  "BoundaryNormalizationChanged"->False|>;
 If[TrueQ[$constructingPrescriptionCertificate],Return[definition]];
 certificate=ordinaryPrescriptionCertificate[definition];
 definition=Append[definition,"OriginalPropagatorPrescriptions"->eta];
 If[TrueQ[certificate["OrdinaryPrescriptionRemoved"]],
   definition["PropagatorPrescriptions"]=ConstantArray[0,Length[nu]]];
 Append[definition,"OrdinaryPrescriptionCertificate"->certificate]
];


(* Typed cuts provide their exact measure explicitly. Counting a measurement
   delta as an additional on-shell particle would change the normalization.
   Both typed and legacy inputs return the same momentum-space definition
   fields; only the geometric cut metadata differ. *)
miRepTypedDefinition[source_,master_,e_]:=Module[
 {family,top,nu,loops,dim,kin,descriptors,cores,cuts,particles,measurements,
  cm,pres,eta,cutData,prefactor,extra,definition,certificate,cutMaster},
 family=FeynFacet`CreateCutIntegralDefinition[source];
 If[!AssociationQ[family],epsOrderFail["TypedCutDefinitionInvalid",<|"Cause"->family|>]];
 top=family["Topology"];nu=master[[2]];loops=top[[3]];
 If[Length[nu]=!=Length[top[[2]]]||!VectorQ[nu,IntegerQ]||
  miRepFamilyName[master[[1]]]=!=miRepFamilyName[top[[1]]],
  epsOrderFail["IntegralDefinitionIndicesInvalid"]];
 dim=Lookup[family,"Dimension",D]/.D->4-2e;kin=FeynCalc`FCI[top[[5]]];
 descriptors=propagatorDescriptor[#,kin]&/@top[[2]];cores=family["InversePropagators"];
 cuts=family["CutIndices"];particles=Select[family["Cuts"],#["Type"]==="Particle"&];
 measurements=Select[family["Cuts"],#["Type"]==="Measurement"&];
 cm=(#["EnergyDirection"]#["Momentum"]&/@particles);
 pres=source["Prescription"];
 If[Length[pres]=!=Length[loops]||!VectorQ[pres,MemberQ[{-1,0,1},#]&],
  epsOrderFail["IntegralLoopPrescriptionsRequired"]];
 eta=Table[If[MemberQ[cuts,i]||nu[[i]]<=0,0,
  family["OrdinaryPropagatorPrescriptions"][[i]]],{i,Length[nu]}];
 prefactor=family["MeasurePrefactor"]/.D->dim;
 extra=Lookup[source,"MasterIntegralPrefactor",1];
 If[!FreeQ[{prefactor,extra},Alternatives@@loops],epsOrderFail["ExternalMasterNormalizationRequired"]];
 cutData=Map[Function[cut,With[{i=cut["Index"]},
  Join[<|"PropagatorIndex"->i,"Type"->cut["Type"],"InversePropagator"->cores[[i]],
   "Power"->nu[[i]],"DeltaDerivativeOrder"->Max[0,nu[[i]]-1],
   "DistributionCoefficient"->If[nu[[i]]>0,(-1)^(nu[[i]]-1)/(nu[[i]]-1)!,0]|>,
   KeyTake[cut,{"Momentum","EnergyDirection","MassSquared","PositiveEnergyCondition"}]]]],family["Cuts"]];
 definition=<|"MasterIntegral"->master,"LoopMomenta"->loops,"ExternalMomenta"->top[[4]],
  "DimensionalRegulator"->e,"Dimension"->dim,"InversePropagators"->cores,
  "PropagatorMomenta"->Lookup[descriptors,"Momentum",None],
  "PropagatorTypes"->Lookup[descriptors,"Type"],"TimeDirection"->family["TimeDirection"],
  "PropagatorPowers"->nu,"CutIndices"->cuts,"ParticleCutIndices"->Lookup[particles,"Index",{}],
  "MeasurementCutIndices"->Lookup[measurements,"Index",{}],"OrientedCutMomenta"->cm,
  "CutDistributions"->cutData,"Prescription"->pres,"PropagatorPrescriptions"->eta,
  "OriginalPropagatorPrescriptions"->eta,"MomentumSpaceConvention"->"ExplicitMeasure",
  "MeasurePrefactor"->prefactor,"MasterIntegralPrefactor"->extra,"KinematicRules"->kin,
  "KinematicConditions"->Lookup[source,"KinematicConditions",family["Assumptions"]],
  "VirtualLoopCount"->Count[pres,1]+Count[pres,-1],"PhaseSpaceLoopCount"->Count[pres,0],
  "MomentumConservationDeltaCount"->Length[particles]-Count[pres,0],
  "CutDistributionConvention"->family["CutConvention"],
  "MeasureConvention"->"The declared prefactor multiplies product d^D loop momenta and all typed cut distributions.",
  "SourceCutDefinition"->family,"BoundaryNormalizationChanged"->False|>;
 If[TrueQ[$constructingPrescriptionCertificate],Return[definition]];
 cutMaster=FeynCalc`GLI[top[[1]],nu];
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,cutMaster,
  <|"DimensionalRegulator"->e|>];
 If[FailureQ[certificate],certificate=<|"OrdinaryPrescriptionRemoved"->False,
  "EndpointDistributionStatus"->"NotCertified","Reason"->ToString[certificate,InputForm]|>];
 If[TrueQ[certificate["OrdinaryPrescriptionRemoved"]],
  definition["PropagatorPrescriptions"]=ConstantArray[0,Length[nu]]];
 Append[definition,"OrdinaryPrescriptionCertificate"->certificate]
];

miRepOrdinary[s_,definition_,seconds_] := Module[{top,master,dim,e,fp,xs,vars,rules},
 top=s["Topology"];master=definition["MasterIntegral"];dim=definition["Dimension"];
 e=definition["DimensionalRegulator"];
 If[Length[DeleteDuplicates[definition["Prescription"]]]>1,
  Return[<|"Representation"->"MomentumSpace","ParameterRepresentationStatus"->"MixedVirtualPrescriptionsRequireSeparateParametrization"|>]];
 top=ReplacePart[top,5->definition["KinematicRules"]];
 master=FeynCalc`GLI[top[[1]],master[[2]]];
 fp=TimeConstrained[CheckAbort[
   FeynCalc`FCFeynmanParametrize[master,top,
    FeynCalc`FCReplaceD->{D->dim},FeynCalc`FeynmanIntegralPrefactor->"Multiloop1",
    FeynCalc`FCVerbose->False],$Aborted],seconds,$TimedOut];
 If[!MatchQ[fp,{_,_,_List}] || !FreeQ[fp,_FeynCalc`FCFeynmanParametrize],
  epsOrderFail["FeynmanParametrizationNotEstablished",<|"Result"->fp|>]];
 xs=fp[[3]];vars=Table[Unique["feynmanParameter"],{Length[xs]}];rules=Thread[xs->vars];
 <|"Representation"->"ProjectiveFeynmanParameters","FeynmanParameters"->vars,
   "ParametricIntegrand"->(fp[[1]]/.rules),
   "ParametricPrefactor"->definition["MasterIntegralPrefactor"] fp[[2]],
   "ParameterDomain"->"Nonnegative parameters with delta(1-sum x); no parameters means an explicit expression.",
   "AnalyticContinuation"->If[First[definition["Prescription"]]===-1,
     "Continuation with the -i0 prescription.","Continuation with the +i0 prescription."],
   "ConstructionMethod"->"FCFeynmanParametrize, including numerator derivatives and Gamma factors."|>
];

(* Independent loop-momentum components give a product of integrals.
   A shared external momentum does not couple the integrations. Numerators
   participate in the dependency graph just as denominators do. *)
miRepFactorized[s_,d_,seconds_] := Module[
 {loops=d["LoopMomenta"],nu=d["PropagatorPowers"],active,dependencies,edges,groups,
  factors={},constant=1,indices,cuts,positions,subTop,subSource,subDefinition,rep,
  subMaster,top=s["Topology"],used},
 active=Select[Range[Length[nu]],nu[[#]]=!=0&];
 dependencies=Table[Select[Range[Length[loops]],
   !FreeQ[d["InversePropagators"][[j]],loops[[#]]]&],{j,Length[nu]}];
 edges=Flatten[UndirectedEdge@@@Subsets[dependencies[[#]],{2}]& /@ active];
 groups=ConnectedComponents[Graph[Range[Length[loops]],edges]];
 If[Length[groups]<2,Return[None]];
 Do[
  indices=Select[active,Intersection[dependencies[[#]],group]=!={}&];
  If[indices==={},Return[None,Module]];
  cuts=Intersection[indices,d["CutIndices"]];
  positions=First[FirstPosition[d["CutIndices"],#]]& /@ cuts;
  subTop=ReplacePart[top,{2->top[[2,indices]],3->loops[[group]]}];
  subSource=Join[s,<|"Topology"->subTop,"MasterIntegralPrefactor"->1,
    "Prescription"->d["Prescription"][[group]],
    "CutIndices"->(First[FirstPosition[indices,#]]& /@ cuts),
    "CutMomenta"->d["OrientedCutMomenta"][[positions]],
    "CutDirections"->ConstantArray[1,Length[cuts]]|>];
  subMaster=FeynCalc`GLI[top[[1]],nu[[indices]]];
  subDefinition=miRepDefinition[subSource,subMaster,d["DimensionalRegulator"]];
  rep=Which[cuts==={},miRepOrdinary[subSource,subDefinition,seconds],
    subDefinition["VirtualLoopCount"]===0,
      With[{volume=miRepElementaryPhaseSpace[subDefinition]},
       If[AssociationQ[volume],volume,miRepBaikov[subDefinition]]],
    True,<|"Representation"->"MomentumSpace",
      "ParameterRepresentationStatus"->"CoupledLoopAndPhaseSpaceParametrizationRequired"|>];
  (* This factor is specified by propagators, not a fictitious reduced-family GLI. *)
  AppendTo[factors,Join[KeyDrop[subDefinition,"MasterIntegral"],rep,<|
    "ParentPropagatorIndices"->indices,"ParentMasterIntegral"->d["MasterIntegral"]|>]],
 {group,groups}];
 Do[If[dependencies[[j]]==={},
   If[MemberQ[d["CutIndices"],j],Return[None,Module]];
   constant*=d["InversePropagators"][[j]]^-nu[[j]]],{j,active}];
 <|"Representation"->"ProductOfIntegrals",
   "Prefactor"->d["MasterIntegralPrefactor"] constant,"Factors"->factors,
   "ConstructionMethod"->"Factorization into independent loop-momentum integrations.",
   "MeasureConvention"->d["MeasureConvention"],
   "FactorizationScope"->"Every active denominator and numerator belongs to one integration component; loop-independent factors are explicit."|>
];

(* Pure phase space: decompose loop vectors into external projections and a
   Euclidean transverse Gram matrix T. The Wishart Jacobian fixes all pi/Gamma
   factors. Delta derivatives are retained as distributions on the full domain;
   differentiating only the density would lose domain-boundary contributions. *)
miRepBaikov[definition_] := Module[
 {loops,ext,l,nExt,spPairs,spVars,z,all,matrix,dot,externalGram,projections,loopGram,
  t,polys,a,c,spRules,jac,pref,exponent,domain,energyRef,energies,cuts,nu,ordinary,
  distributions,cutValues,reduced,n,minorConditions,kin,dim,e,timeSquare,externalSpatial,kinematicConditions,ordinaryEta},
 loops=definition["LoopMomenta"];ext=definition["ExternalMomenta"];
 l=Length[loops];nExt=Length[ext];all=Join[loops,ext];kin=definition["KinematicRules"];
 dim=definition["Dimension"];e=definition["DimensionalRegulator"];
 If[nExt<1,epsOrderFail["ExternalTimeDirectionRequired"]];
 spPairs=Join[Flatten[Table[{i,j},{i,l},{j,i,l}],1],Tuples[{Range[l],l+Range[nExt]}]];
 spVars=Table[Unique["scalarProduct"],{Length[spPairs]}];n=Length[spVars];
 matrix=ConstantArray[0,{Length[all],Length[all]}];
 Do[matrix[[Sequence@@spPairs[[j]]]]=spVars[[j]];
    matrix[[Sequence@@Reverse[spPairs[[j]]]]]=spVars[[j]],{j,n}];
 externalGram=Table[FeynCalc`FCI[FeynCalc`SPD[ext[[i]],ext[[j]]]]/.kin,{i,nExt},{j,nExt}];
 If[epsOrderZero[Det[externalGram]],epsOrderFail["IndependentExternalMomentaRequiredForBaikov"]];
 matrix[[l+Range[nExt],l+Range[nExt]]]=externalGram;
 dot[u_,v_] := Expand[(Coefficient[Expand[u],#]& /@ all).matrix.
   (Coefficient[Expand[v],#]& /@ all)];
 polys=definition["InversePropagators"]/.FeynCalc`Pair[
    FeynCalc`Momentum[u_,___],FeynCalc`Momentum[v_,___]]:>dot[u,v];
 If[!AllTrue[polys,PolynomialQ[#,spVars]&],epsOrderFail["PolynomialScalarProductDenominatorsRequired"]];
 (* Complete an incomplete family with explicit scalar products, not invented denominators. *)
 a=Table[Coefficient[poly,v],{poly,polys},{v,spVars}];
 If[MatrixRank[a]=!=Length[polys],epsOrderFail["IndependentInversePropagatorsRequiredForBaikov"]];
 Do[If[MatrixRank[Append[a,UnitVector[n,j]]]>Length[a],
   AppendTo[polys,spVars[[j]]];AppendTo[a,UnitVector[n,j]]],{j,n}];
 If[Dimensions[a]=!={n,n} || !FreeQ[a,Alternatives@@spVars],
  epsOrderFail["AffineScalarProductDenominatorsRequired"]];
 c=polys/.Thread[spVars->0];
 If[!And@@(epsOrderZero /@ (polys-a.spVars-c)),epsOrderFail["AffineScalarProductDenominatorsRequired"]];
 z=Table[Unique["baikovVariable"],{n}];spRules=Thread[spVars->Inverse[a].(z-c)];
 jac=1/Abs[Det[a]];
 projections=matrix[[Range[l],l+Range[nExt]]];loopGram=matrix[[Range[l],Range[l]]];
 t=Map[Factor,(projections.Inverse[externalGram].Transpose[projections]-loopGram)/.spRules,{2}];
 exponent=(dim-nExt-l-1)/2;
 pref=definition["MasterIntegralPrefactor"] definition["MeasurePrefactor"] jac *
   Abs[Det[externalGram]]^(-l/2) Pi^(l (dim-nExt)/2-l(l-1)/4) /
   Product[Gamma[(dim-nExt-j+1)/2],{j,l}];
 minorConditions=Flatten[Table[Det[t[[set,set]]]>=0,{size,l},{set,Subsets[Range[l],{size}]}]];
 energyRef=definition["TimeDirection"];
 If[!FreeQ[energyRef,Alternatives@@loops] || energyRef===0,
   epsOrderFail["FutureExternalTimeDirectionRequired"]];
 timeSquare=Factor[dot[energyRef,energyRef]];
 externalSpatial=Outer[Times,(dot[#,energyRef]& /@ ext),(dot[#,energyRef]& /@ ext)]/timeSquare-externalGram;
 kinematicConditions=And[timeSquare>0,And@@Flatten[Table[
   Det[externalSpatial[[set,set]]]>=0,{size,nExt},{set,Subsets[Range[nExt],{size}]}]]];
 If[kinematicConditions===False,epsOrderFail["PhysicalExternalGramSignatureRequired"]];
 energies=(Factor[dot[#,energyRef]/.spRules]& /@ definition["OrientedCutMomenta"]);
 cuts=definition["CutIndices"];nu=definition["PropagatorPowers"];
 ordinaryEta=Unique["ordinaryEta"];
 ordinary=miRepPrescribedPowers[z,definition,ordinaryEta];
 distributions=Times@@Table[
   (-1)^(nu[[j]]-1)/(nu[[j]]-1)! Derivative[nu[[j]]-1][DiracDelta][z[[j]]],{j,cuts}];
 cutValues=Thread[z[[cuts]]->0];
 reduced=If[AllTrue[nu[[cuts]],#===1&],
   <|"IntegrationVariables"->Delete[z,List /@ cuts],
     "Integrand"->(ordinary Det[t]^exponent/.cutValues),
     "DomainConditions"->And@@Join[minorConditions/.cutValues,Thread[(energies/.cutValues)>0]]|>,None];
 <|"Representation"->"BaikovCut","IntegrationVariables"->z,"ParametricPrefactor"->pref,
   "Integrand"->ordinary Det[t]^exponent distributions,
   "DomainConditions"->And@@Join[minorConditions,Thread[energies>0]],
   "OrdinaryPrescriptionParameter"->ordinaryEta,
  "OrdinaryPrescriptionLimit"->"Take eta -> 0 from positive real values at fixed dimension in an established convergence domain, then continue dimension meromorphically.",
  "ExternalGramMatrix"->externalGram,"TransverseGramMatrix"->t,
   "BaikovPolynomial"->Factor[Det[t]],"BaikovExponent"->exponent,
   "ScalarProductSubstitution"->spRules,"InversePropagatorVariables"->Take[z,Length[nu]],
   "CoordinateInversePropagators"->(polys/.Thread[spVars->
     (FeynCalc`FCI[FeynCalc`SPD[all[[#[[1]]]],all[[#[[2]]]]]]& /@ spPairs)]),
   "ScalarProductJacobian"->jac,"TimeDirection"->energyRef,
   "TimeDirectionSquared"->timeSquare,"KinematicConditions"->kinematicConditions,
   "ExternalSignatureCondition"->"The external span has one positive and E-1 negative metric eigenvalues; TimeDirection is future timelike.",
   "UnitCutRepresentation"->reduced,
   "ParameterDomain"->"Positive semidefinite transverse Gram matrix and positive cut energies; dimensionally continued from D>E+L-1."|>
];

miRepPositiveQ[expression_,definition_] := TrueQ[expression>0] ||
 TrueQ[Quiet[FullSimplify[expression>0,Assumptions->Lookup[definition,"KinematicConditions",True]]]];

miRepPhaseVolume[definition_] := Module[
 {cuts,nu,loops,l,cm,q,kin,dim,s,masses,coeff,selected,det,exponent,value,c2},
 cuts=definition["CutIndices"];nu=definition["PropagatorPowers"];
 loops=definition["LoopMomenta"];l=Length[loops];cm=definition["OrientedCutMomenta"];
 If[Length[cuts]=!=l+1 || !AllTrue[nu[[cuts]],#===1&] ||
  !AllTrue[Complement[Range[Length[nu]],cuts],nu[[#]]===0&],Return[None]];
 kin=definition["KinematicRules"];dim=definition["Dimension"];
 masses=MapThread[Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#1]]]-#2]/.kin&,
   {cm,definition["InversePropagators"][[cuts]]}];
 If[!AllTrue[masses,epsOrderZero],Return[None]];
 q=Expand[Total[cm]];
 If[!FreeQ[q,Alternatives@@loops] || q===0,Return[None]];
 If[!miRepPositiveQ[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
   FeynCalc`SPD[q,definition["TimeDirection"]]]]/.kin,definition],Return[None]];
 s=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[q]]]/.kin;
 If[!miRepPositiveQ[s,definition],Return[None]];
 coeff=Table[Coefficient[m,k],{m,cm},{k,loops}];
 selected=SelectFirst[Subsets[Range[l+1],{l}],!epsOrderZero[Det[coeff[[#]]]]&,None];
 If[selected===None,Return[None]];det=Abs[Det[coeff[[selected]]]];
 c2=Pi^((dim-1)/2)/(2^(dim-2) Gamma[(dim-1)/2]);
 value=c2^l Product[Gamma[(j-2)(dim-2)/2] Gamma[dim-2]/
   Gamma[j(dim-2)/2],{j,3,l+1}] s^(l(dim-2)/2-1)/det^dim;
 <|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{},
    "Prefactor"->definition["MasterIntegralPrefactor"] definition["MeasurePrefactor"] value|>},
   "ConstructionMethod"->"Recursive two-body phase-space factorization for the massless inclusive volume.",
   "TotalMomentumSquared"->s,"PhaseSpaceRoutingDeterminant"->det|>
];

Options[FeynFacet`ConstructMasterIntegralRepresentations]={
 "InputRoot"->Automatic,"ParametrizationTimeLimit"->30};
miRepBuild[input_,request_,root_,seconds_,definitionsOnly_:False] := Module[
 {source,e,masters,result=<||>,failures=<||>,familyData=<||>,prepared=<||>,d,s,key,def,rep,pref,rows,kin},
 If[!StringQ[root] || !(seconds===Infinity || TrueQ[NumericQ[seconds] && seconds>0]),
  epsOrderFail["RepresentationConstructionOptionsInvalid"]];
 If[!MemberQ[{"GenericKinematics","EndpointDistributions"},Lookup[request,"PrescriptionScope","GenericKinematics"]],
  epsOrderFail["UnknownPrescriptionScope"]];
 source=miRepSourceData[Join[input,request],root];
 e=Lookup[source,"DimensionalRegulator",None];
 If[!MatchQ[e,_Symbol],epsOrderFail["DimensionalRegulatorRequired"]];
 source=epsOrderNormalize[source,e];
 If[!MemberQ[{"AMFlow","ExplicitMeasure"},Lookup[source,"MomentumSpaceConvention","AMFlow"]],
  epsOrderFail["UnsupportedMomentumSpaceConvention"]];
 masters=Lookup[input,"OriginalMasterIntegralBasis",Lookup[input,"MasterIntegralBasis",Lookup[input,"Master",{}]]];
 If[MatchQ[miRepFC[masters],_FeynCalc`GLI],masters={masters}];
 If[masters==={} || !AllTrue[miRepFC[masters],MatchQ[#,_FeynCalc`GLI]&],
  epsOrderFail["MasterIntegralIdentifiersRequired"]];
 rows=Lookup[request,"RequestedRows",Range[Length[masters]]];
 If[!ListQ[rows] || !DuplicateFreeQ[rows] || !AllTrue[rows,IntegerQ[#]&&1<=#<=Length[masters]&],
  epsOrderFail["MasterRowsInvalid"]];
 kin=Lookup[source,"KinematicRules",{}];
 If[KeyExistsQ[request,"BasePoint"] && ListQ[request["BasePoint"]],
  If[Length[Lookup[source,"KinematicVariables",Lookup[source,"CoefficientVariables",{}]]]=!=Length[request["BasePoint"]],
   epsOrderFail["IntegralBasePointDimensionMismatch"]];
  kin=kin/.Thread[Lookup[source,"KinematicVariables",Lookup[source,"CoefficientVariables",{}]]->request["BasePoint"]];
  source=source/.Thread[Lookup[source,"KinematicVariables",Lookup[source,"CoefficientVariables",{}]]->request["BasePoint"]];
  source=Join[source,<|"KinematicRules"->kin|>]
 ];
 Do[
  rep=Catch[
   key=miRepFamilyName[miRepFC[masters[[j]]][[1]]];
   If[!KeyExistsQ[familyData,key],AssociateTo[familyData,key->miRepFamilyData[source,miRepFC[masters[[j]]]]]];
   s=familyData[key];
   pref=Lookup[Lookup[request,"MasterIntegralPrefactors",<||>],j,Lookup[s,"MasterIntegralPrefactor",1]];
   def=miRepDefinition[Join[s,<|"MasterIntegralPrefactor"->pref|>],miRepFC[masters[[j]]],e];
   If[Lookup[request,"PrescriptionScope","GenericKinematics"]==="EndpointDistributions" &&
     FailureQ[FeynFacet`RequireOrdinaryPrescriptionCertificate[
       def["OrdinaryPrescriptionCertificate"],"EndpointDistributions"]],
     epsOrderFail["EndpointDistributionPrescriptionCertificateRequired"]];
   If[AnyTrue[def["PropagatorPowers"][[def["CutIndices"]]],#<=0&],
    d=<|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{},"Prefactor"->0|>}|>,
    d=Which[
     TrueQ[definitionsOnly],<|"Representation"->"MomentumSpace"|>,
     def["CutIndices"]==={},miRepOrdinary[s,def,seconds],
     def["VirtualLoopCount"]===0,
      With[{volume=miRepElementaryPhaseSpace[def]},
       If[AssociationQ[volume],volume,
        If[!KeyExistsQ[prepared,key],AssociateTo[prepared,key->miRepBaikov[
          Join[def,<|"PropagatorPowers"->ConstantArray[1,Length[def["PropagatorPowers"]]],
            "MasterIntegralPrefactor"->1|>]]]];
        (* Reuse the family Gram determinant and Jacobian for every exponent vector. *)
        miRepCutFromFamily[prepared[key],def]]],
     True,With[{product=miRepFactorized[s,def,seconds]},
      If[AssociationQ[product],product,<|"Representation"->"MomentumSpace",
       "ParameterRepresentationStatus"->"CoupledLoopAndPhaseSpaceParametrizationRequired"|>]]
    ]
   ];
   Join[def,d,<|"MasterIntegral"->masters[[j]],"Status"->"IntegralRepresentationConstructed"|>],
  "EpsilonOrders"];
  If[FailureQ[rep],AssociateTo[failures,j->rep],AssociateTo[result,j->rep]],
 {j,rows}];
 <|"DataType"->"MasterIntegralRepresentations",
  "Status"->If[failures===<||>,"IntegralRepresentationsConstructed","SomeIntegralDefinitionsUnresolved"],
  "MasterIntegralRepresentations"->result,"UnresolvedIntegralDefinitions"->failures,
  "FamilyCount"->Length[familyData],"DimensionalRegulator"->e,
  "NormalizationConvention"->"The convention and explicit prefactor are recorded for each integral.","BoundaryNormalizationChanged"->False|>
];

miRepPrescribedPowers[variables_,definition_,eta_]:=Module[{nu,cuts,signs},
 nu=definition["PropagatorPowers"];cuts=definition["CutIndices"];
 signs=Lookup[definition,"PropagatorPrescriptions",ConstantArray[0,Length[nu]]];
 Times@@Table[If[MemberQ[cuts,j],1,
   (variables[[j]]+If[nu[[j]]>0,I signs[[j]]eta,0])^-nu[[j]]],{j,Length[nu]}]
];

miRepCutFromFamily[family_,def_] := Module[{r=family,z,nu,cuts,powers,delta,zero,unit},
 z=r["IntegrationVariables"];nu=def["PropagatorPowers"];cuts=def["CutIndices"];
 powers=miRepPrescribedPowers[z,def,r["OrdinaryPrescriptionParameter"]];
 delta=Times@@Table[(-1)^(nu[[j]]-1)/(nu[[j]]-1)! Derivative[nu[[j]]-1][DiracDelta][z[[j]]],{j,cuts}];
 r["ParametricPrefactor"]=def["MasterIntegralPrefactor"] r["ParametricPrefactor"];
 r["Integrand"]=powers r["BaikovPolynomial"]^r["BaikovExponent"] delta;
 zero=Thread[z[[cuts]]->0];
 r["UnitCutRepresentation"]=If[AllTrue[nu[[cuts]],#===1&],
  <|"IntegrationVariables"->Delete[z,List /@ cuts],
    "Integrand"->(powers r["BaikovPolynomial"]^r["BaikovExponent"]/.zero),
    "DomainConditions"->(r["DomainConditions"]/.zero)|>,None];r
];

FeynFacet`ConstructMasterIntegralRepresentations[input_Association,request_Association:<||>,OptionsPattern[]] :=
 Catch[miRepBuild[input,request,Replace[OptionValue["InputRoot"],Automatic:>$feynFacetRoot],
   OptionValue["ParametrizationTimeLimit"]],"EpsilonOrders"];


FeynFacet`ConstructMasterIntegralDefinitions::usage="ConstructMasterIntegralDefinitions[input,request] derives original momentum-space integral definitions and normalization without computing parameter representations.";
Options[FeynFacet`ConstructMasterIntegralDefinitions]={"InputRoot"->Automatic};
FeynFacet`ConstructMasterIntegralDefinitions[input_Association,request_Association:<||>,OptionsPattern[]] :=
 Catch[Module[{result},
 result=miRepBuild[input,request,Replace[OptionValue["InputRoot"],Automatic:>$feynFacetRoot],1,True];
 Join[KeyDrop[result,"MasterIntegralRepresentations"],<|"DataType"->"MasterIntegralDefinitions",
  "MasterIntegralDefinitions"->result["MasterIntegralRepresentations"]|>]
 ],"EpsilonOrders"];

(* Convert the homogeneous parameter integrand returned by FeynCalc into
   primary sectors. Polynomial powers are separated without PowerExpand. *)
miRepTerm[term_,xs_,pref_,e_] := Module[{factors,g=1,p=pref,poly={},base,exponent,num,den},
 factors=If[Head[term]===Times,List@@term,{term}];
 Do[
  If[xs==={} || FreeQ[factor,Alternatives@@xs],p=p factor;Continue[]];
  If[Head[factor]===Power && !IntegerQ[factor[[2]]],
   {base,exponent}=List@@factor;
   If[!epsOrderExponentQ[exponent,e],epsOrderFail["ParametricExponentInvalid"]];
   base=Cancel[base];num=Numerator[base];den=Denominator[base];
   If[!PolynomialQ[num,xs] || !PolynomialQ[den,xs],
    epsOrderFail["PolynomialParameterFactorsRequired"]];
   AppendTo[poly,<|"Polynomial"->num,"Exponent"->exponent|>];
   If[den=!=1,AppendTo[poly,<|"Polynomial"->den,"Exponent"->-exponent|>]],
   g=g factor],
 {factor,factors}];
 <|"IntegrationVariables"->xs,"Prefactor"->p,"RegularFactor"->g,"PolynomialFactors"->poly|>
];
miRepSimplexSectors[d_,e_] := Module[{xs,int,pref,terms,sector,ys,result={}},
 xs=d["FeynmanParameters"];int=d["ParametricIntegrand"];pref=d["ParametricPrefactor"];
 If[xs==={},Return[{miRepTerm[int,{},pref,e]}]];
 Do[
  ys=Delete[xs,j];sector=Expand[int/.xs[[j]]->1];
  terms=If[Head[sector]===Plus,List@@sector,{sector}];
  result=Join[result,miRepTerm[#,ys,pref,e]& /@ terms],
 {j,Length[xs]}];result
];

(* A fully localized cut can be evaluated by normal derivatives only when the
   cut point is strictly inside the Gram/energy domain. In that case the domain
   indicator is locally constant and contributes no derivative terms. *)
miRepClosedCutTerms[d_,e_] := Module[{z,cuts,nu,zero,domain,tests,values,density},
 z=d["IntegrationVariables"];cuts=d["CutIndices"];nu=d["PropagatorPowers"];
 If[Sort[cuts]=!=Range[Length[z]],epsOrderFail["CutDomainResolutionRequired",
   <|"RepresentationConstructed"->True|>]];
 zero=Thread[z->0];domain=d["DomainConditions"];
 tests=If[Head[domain]===And,List@@domain,{domain}];
 If[!AllTrue[tests,MatchQ[#,_Greater|_GreaterEqual] && Length[#]===2&],
  epsOrderFail["CutPointInteriorNotEstablished"]];
 values=(#[[1]]-#[[2]]/.zero)& /@ tests;
 If[!AllTrue[values,TrueQ[#>0]&] || !TrueQ[d["KinematicConditions"]],
  epsOrderFail["CutPointInteriorNotEstablished"]];
 density=d["BaikovPolynomial"]^d["BaikovExponent"];
 Do[density=D[density,{z[[j]],nu[[j]]-1}]/(nu[[j]]-1)!,{j,cuts}];
 {<|"IntegrationVariables"->{},"Prefactor"->d["ParametricPrefactor"] (density/.zero)|>}
];

End[];
