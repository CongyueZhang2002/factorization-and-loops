Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Get[root<>"/Tests/TestKit.wl"];
Clear[eps,z,v,te,tz,tv];
dir=CreateDirectory[];trace=dir<>"/Trace";CreateDirectory[trace];
Export[FeynFacet`Private`finiteFieldTraceManifestFile[trace],<|"Test"->True|>,"WXF"];
masters=Table[FeynCalc`GLI["SourceFamily",{i}],{i,3}];
targets=Table[FeynCalc`GLI["TargetFamily",{i}],{i,3}];
files=Table[dir<>"/Column"<>ToString[i]<>".expr",{i,3}];
MapThread[Export[#1,#2,"Text"]&,{files,{"1/(tz+te)+tv/(tz*te)","1/(tz+te)","tv/(tz*te)"}}];
ep=<|"DataType"->"TangentialEndpointSystem","DimensionalRegulator"->eps,"NormalVariable"->z,"TangentialVariable"->v,
 "Dimension"->3,"PrimarySectors"->{<|"Exponent"->-2eps,"NilpotencyIndex"->1|>},
 "NormalGaugeMatrix"->IdentityMatrix[3],"OriginalMasterIntegralBasis"->targets|>;
bounds=<|"DataType"->"TangentialEndpointLaurentBounds",
 "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"-><|-2eps->{0,0,0}|>|>;
sourceSystemFile=dir<>"/SourceSystem.wxf";Export[sourceSystemFile,<|"TestSystem"->True|>,"WXF"];
ids=FeynFacet`Private`coefficientMasterID/@targets;
frame=<|"SourceDifferentialSystemFile"->sourceSystemFile,"Endpoint"->ep,"Bounds"->bounds,"OriginalMasterIntegralBasis"->targets,"Dimension"->3,
 "GaugeLeafCount"->9,"RowsByIntegralClass"->AssociationThread[ids,List/@Range[3]],
 "AcceptedEndpointBinding"-><|"EndpointSystem"->ep,"LaurentBounds"->bounds|>|>;
catalog=<|"DataType"->"EndpointCoefficientCatalog","Frames"-><|"TargetFamily"->frame|>,
 "IntegralClasses"->AssociationThread[ids,ids],"CutCatalog"-><|"Normalization"-><||>|>|>;
metadata=<|"Topologies"->{},"Setup"-><||>|>;
data=<|"OutputFiles"->files,"OutputMetadata"->Table[<|"MasterIndex"->i,"SignatureIndex"->1|>,{i,3}],
 "Masters"->masters,"SymbolRules"-><|eps->te,z->tz,v->tv|>,"Signatures"-><|1->HoldComplete[1]|>,
 "Variables"->{eps,z,v},"PhysicalFactor"->1|>;
inputs=<|"Metadata"->metadata,"TraceDirectory"->trace,
 "Data"-><|"PhaseSpace"->1|>,"Context"-><|"DimensionlessCoordinates"-><||>|>|>;
match=<|"Mappings"->MapThread[<|"Source"->#1,"Representative"->#2,"Factor"->1|>&,{masters,targets}]|>;
request=<|"EndpointCatalog"->catalog,"SourceNormalization"-><||>,
 "PhysicalNormalization"-><|"Scale"->1,"ReferenceScale"->1,"Assumptions"->True,"KinematicRules"->{}|>,"KinematicRules"->{},
 "ThroughOrder"->0,"Assumptions"->0<v<1,"FiniteAboveBytes"->0,"PlanDirectory"->dir<>"/Plan"|>;
Block[{FeynFacet`MatchCutIntegralCatalogs=Function[{s,t},match],
 FeynFacet`Private`coefficientPlanPhysicalFactors=Function[{a,b,c,d,f},
  <|"GlobalPreFactor"->eps^-2,"MasterMultipliers"->AssociationThread[
    FeynFacet`Private`coefficientMasterID/@masters,{1,1,1}],"Definitions"-><||>,"Normalization"-><||>|>],
 FeynFacet`Private`coefficientPlanFrameBinding=Function[{a,b,c,d,e,f,g,h},<|"Status"->"TestUnitIdentity"|>],
 FeynFacet`Private`finiteFieldCertifyPhysicalVariables=Function[{x,c},x]},
 runPlan[rq_]:=FeynFacet`Private`coefficientPrepareReconstructionPlan[inputs,data,dir,rq];
 result=runPlan[request];
FTAssert["all source columns are discovered without family-specific selection",
 AssociationQ[result]&&result["DiscoveryReport"]["CandidateOutputs"]==={1,2,3}];
FTAssert["regular parts and entirely exceptional columns are distinguished",
 result["DiscoveryReport"]["FiniteOutputs"]==={1,3}&&
 Lookup[result["DiscoveryReport"]["ExactFallbacks"],"Output"]==={2}];
orders=FeynFacet`FamilyArtifactRead[result["CoefficientOrderPlans"]];
FTAssert["derived orders include the physical prefactor and endpoint moment pole",
 Lookup[Values[orders],"RequiredCoefficientUpperOrder"]==={3,3}];
parts=Import[result["PartitionManifest"],"RawJSON"];
FTAssert["a moving divisor remains exact in the emitted literal partition",
 parts[[1]]["Parts"]["Exact"]["Summands"]===1&&parts[[1]]["Parts"]["Regular"]["Summands"]===1];
FTAssert["a fully regular column has an exact zero exceptional part",
 parts[[2]]["Parts"]["Exact"]["Summands"]===0&&StringTrim[Import[parts[[2]]["Parts"]["Exact"]["File"],"Text"]]==="0"];
FTAssert["normalization and accepted endpoint inputs are retained in the proof",
 KeyExistsQ[orders[1]["InputBindings"],"PhysicalNormalizationRequest"]&&
 KeyExistsQ[orders[1]["InputBindings"],"AcceptedEndpointBinding"]];
FTAssert["a missing declared dependency fails before reconstruction",
 MatchQ[FeynFacet`Private`coefficientPrepareReconstructionPlan[inputs,data,dir,
  Append[request,"EndpointCatalog"->dir<>"/absent.wl"]],Failure["CoefficientPlanDependencyMissing",_]]];
unsupported=runPlan[Append[request,"KinematicRules"->{v->1/z}]];
FTAssert["unsupported maps keep affected source columns exactly rational",
 AssociationQ[unsupported]&&unsupported["DiscoveryReport"]["FiniteOutputs"]==={}&&
 Length[unsupported["DiscoveryReport"]["ExactFallbacks"]]===3];
FTAssert["saved finite plans accept unchanged current mathematical inputs",
 FeynFacet`Private`coefficientValidateSavedPlan[result,request]===True];
Export[sourceSystemFile,<|"TestSystem"->False|>,"WXF"];
FTAssert["saved finite plans reject a changed source differential system",
 FailureQ[FeynFacet`Private`coefficientValidateSavedPlan[result,request]]];
Export[sourceSystemFile,<|"TestSystem"->True|>,"WXF"];
FTAssert["saved finite plans reject a larger requested epsilon order",
 FailureQ[FeynFacet`Private`coefficientValidateSavedPlan[result,Append[request,"ThroughOrder"->1]]]];
FTAssert["saved finite plans reject changed physical normalization",
 FailureQ[FeynFacet`Private`coefficientValidateSavedPlan[result,
  Append[request,"PhysicalNormalization"->Append[request["PhysicalNormalization"],"FluxFactor"->eps^-1]]]]];
changedCatalog=Append[catalog,"Frames"->Append[catalog["Frames"],"TargetFamily"->Append[frame,
 "Bounds"->Append[bounds,"Changed"->True]]]];
FTAssert["saved finite plans reject changed endpoint bounds",
 FailureQ[FeynFacet`Private`coefficientValidateSavedPlan[result,Append[request,"EndpointCatalog"->changedCatalog]]]];
empty=runPlan[Append[request,"FiniteAboveBytes"->10^9]];
stored=FeynFacet`FamilyArtifactRead[dir<>"/Plan/Plan.wl"];
FTAssert["an all-rational plan replaces a previous finite plan at the same path",
 stored===empty&&stored["DiscoveryReport"]["CandidateOutputs"]==={}&&!KeyExistsQ[stored,"PartitionManifest"]];
FTAssert["empty-candidate plans still reject invalid mathematical dependencies",
 FailureQ[runPlan[Join[request,<|"FiniteAboveBytes"->10^9,"PhysicalNormalization"-><||>|>]]]];
FTAssert["empty-candidate plans still reject inconsistent source conventions",
 FailureQ[runPlan[Join[request,<|"FiniteAboveBytes"->10^9,"SourceNormalization"-><|"Other"->1|>|>]]]];
(* A numerator-only symbol is included when composing physical substitutions.
   x/(1+eps x), after x -> 1/z, has a moving endpoint pole. *)
mapData=Append[data,"SymbolRules"->Append[data["SymbolRules"],x->tx]];
mapEndpoint=ep;
mapRequest=Append[request["PhysicalNormalization"],"KinematicRules"->{x->1/z}];
FTAssert["physical coordinate composition catches moving-pole counterexample",
 FailureQ[FeynFacet`Private`coefficientPlanEffectiveRules[mapData,inputs["Context"],
 mapRequest,{},mapEndpoint,0<v<1]]];
FTAssert["coordinate substitutions cannot redefine the regulator",
 FailureQ[runPlan[Append[request,"KinematicRules"->{eps->0}]]]];
(* One unavailable source normalization must not prevent the other columns. *)
Block[{FeynFacet`Private`coefficientPlanPhysicalFactors=Function[{a,b,c,d,f},
 If[c==={masters[[2]]},Failure["UnsupportedTestMaster",<||>],
 <|"GlobalPreFactor"->eps^-2,"MasterMultipliers"->AssociationThread[
 FeynFacet`Private`coefficientMasterID/@masters,{1,1,1}],"Definitions"-><||>,"Normalization"-><||>|>]]},
 mixed=runPlan[request];
];
FTAssert["an unsupported master does not prevent independent regular columns",
 mixed["DiscoveryReport"]["FiniteOutputs"]==={1,3}&&
 mixed["DiscoveryReport"]["ExactFallbacks"][[1]]["Reason"][[1]]==="SourcePhysicalNormalizationUnsupported"];Block[{FeynFacet`DetermineCoefficientReconstructionOrders=Function[{a,b,c,d},
 Failure["DivisorInventorySourceBindingMismatch",<||>]]},
 stale=runPlan[request];
];
FTAssert["a stale divisor inventory fails preparation instead of becoming an exact fallback",
 MatchQ[stale,Failure["CoefficientOrderInputIntegrityFailure",_]]];
];
Block[{FeynFacet`ReadContributionCard=Function[{path,name},
 <|"EpsilonRange"->{-4,2},"CoefficientReconstruction"-><|
   "EndpointCatalog"->"Results/endpoint.wl","PhysicalNormalization"->"Results/normalization.wl"|>|>]},
 cardInputs=FeynFacet`Private`coefficientProjectReconstructionInputs[dir,"DoubleReal.Gluons"];
];
FTAssert["contribution cards supply the requested order and resolve dependency paths",
 cardInputs["ThroughOrder"]===2&&cardInputs["EndpointCatalog"]===dir<>"/Results/endpoint.wl"];
planCalls=0;nativeCalls=0;
Block[{FeynFacet`Private`coefficientPrepareReconstructionPlan=Function[{a,b,c,d},
 planCalls++;Failure["TestOrderFailure",<||>]],
 FeynFacet`Private`reconstructionRunSchedule=Function[{a,b,c,d,e},nativeCalls++;{}]},
 failedExecution=FeynFacet`Private`finiteFieldExecuteCoefficientPlan[inputs,data,dir,"unused",
  <|"Threads"->1,"ReconstructionOrderInputs"->request|>];
];
FTAssert["automatic preparation precedes native reconstruction and stops invalid plans",
 planCalls===1&&nativeCalls===0&&failedExecution===$Failed];
nativeCalls=0;
Block[{FeynFacet`Private`reconstructionRunSchedule=Function[{a,b,c,d,e},nativeCalls++;{}]},
 changedExecution=FeynFacet`Private`finiteFieldExecuteCoefficientPlan[inputs,data,dir,"unused",
  <|"Threads"->1,"ReconstructionOrderInputs"->Append[request,"ThroughOrder"->2]|>,result];
 malformedExecution=FeynFacet`Private`finiteFieldExecuteCoefficientPlan[inputs,data,dir,"unused",
  <|"Threads"->1,"ReconstructionOrderInputs"->"invalid"|>];
];
FTAssert["saved-plan execution checks current order inputs before running native jobs",
 changedExecution===$Failed&&nativeCalls===0];
FTAssert["malformed declared order inputs do not silently select full rational work",
 malformedExecution===$Failed&&nativeCalls===0];
reduction=dir<>"/Results/DoubleReal/Gluons/Reduction";
CreateDirectory[reduction<>"/Pairs",CreateIntermediateDirectories->True];
Export[reduction<>"/KiraResult.wl","<||>","Text"];
Export[reduction<>"/Pairs/F1_C1.wl","<||>","Text"];
FTAssert["default coefficient input discovery follows contribution component paths",
 FeynFacet`Private`coefficientResolveResultDirectory[dir,"DoubleReal.Gluons",Automatic]===reduction];
DeleteDirectory[dir,DeleteContents->True];FTReport[];
