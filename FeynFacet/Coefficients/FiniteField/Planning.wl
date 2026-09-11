(* Derive exact/finite coefficient jobs from source definitions and physical
   endpoint bounds. No family labels, column numbers or epsilon orders are preset. *)
BeginPackage["FeynFacet`"];
PrepareCoefficientReconstructionPlan::usage =
 "PrepareCoefficientReconstructionPlan[traceDirectory,request] discovers expensive columns, preserves exceptional summands exactly and proves sufficient orders for regular parts. Request supplies an accepted EndpointCatalog, SourceNormalization, PhysicalNormalization, KinematicRules, Assumptions and ThroughOrder.";
Begin["`Private`"];
$coefficientPlanSourceFields={"CardName","Setup","Pairs","AnalyticContext","Topologies",
 "TopologyEquivalence","ReverseRules","MassDimensions","DimensionRule"};
coefficientPlanFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"CoefficientPlan"];
coefficientPlanRead[x_String]:=If[FileExistsQ[x],endpointGroupRead[x],
 coefficientPlanFail["CoefficientPlanDependencyMissing",<|"File"->x|>]];
coefficientPlanRead[x_Association]:=x;
coefficientPlanRead[___]:=coefficientPlanFail["CoefficientPlanDependencyRequired"];
coefficientPlanBackend[arguments_List,marker_String]:=Module[{run},
 run=RunProcess[Prepend[Prepend[arguments,$reconstructionPartitionBackend],"python3"]];
 If[run["ExitCode"]=!=0||!StringContainsQ[run["StandardOutput"],marker],
  coefficientPlanFail["CoefficientPartitionBackendFailed",<|"Diagnostic"->run["StandardError"]|>]];
 True
];
coefficientPlanWrite[data_,file_]:=If[
 FeynFacet`FamilyArtifactWrite[coefficientCanonicalContainers[data],file,"Compression"->True]===$Failed||
 FeynFacet`FamilyArtifactRead[file]=!=coefficientCanonicalContainers[data],
 coefficientPlanFail["CoefficientPlanReadBackFailed",<|"File"->file|>]];

(* A unit coefficient table derives only the multiplier converting each source
   normalized GLI to its physical master. It is never published as a result. *)
coefficientPlanPhysicalFactors[inputs_,data_,masters_,normalization_,definitionRequest_] := Module[
 {e=$feynFacetEpsilon,definitions,construction,unit,converted},
 definitions=KeyTake[inputs["Metadata"],$coefficientPlanSourceFields];
 construction=FeynFacet`ConstructMasterIntegralDefinitions[
  Join[definitions,<|"OriginalMasterIntegralBasis"->masters,"DimensionalRegulator"->e|>],definitionRequest];
 If[!AssociationQ[construction]||Lookup[construction,"UnresolvedIntegralDefinitions",None]=!=<||>,
  Return[Failure["ReconstructionPhysicalDefinitionsRequired",<|"Cause"->construction|>]]];
 unit=<|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
  "DimensionalRegulator"->e,"Definitions"->definitions,"PreFactor"->data["PhysicalFactor"],
  "PhaseSpace"->inputs["Data"]["PhaseSpace"],"FractionMeasure"->inputs["Data"]["FractionMeasure"],
  "Masters"->(<|"Master"->#,"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->1|>}|>&/@masters),
  "RemainderTerms"->{}|>;
 converted=FeynFacet`ConstructPhysicalMasterCoefficientDensity[unit,
  Association[(#["MasterIntegral"]->#)&/@Values[construction["MasterIntegralDefinitions"]]],normalization];
 If[!AssociationQ[converted],Return[converted]];
 <|"GlobalPreFactor"->converted["PreFactor"],
   "MasterMultipliers"->Association[(coefficientMasterID[#["Master"]]->First[#["Terms"]]["PreFactor"])&/@converted["Masters"]],
   "Definitions"->construction,"Normalization"->converted["PhysicalDensityNormalization"]|>
];

coefficientPrepareReconstructionPlan[inputs_Association,data_Association,
 nativeDirectory_String,request_Association] := Catch[Module[
 {catalog,normalization,sourceNormalization,threshold,selected,indices,masters,definitions,
  sourceCatalog,match,mappings,physical,root,partitions={},plans=<||>,reports={},names,originals,
  source,master,mapping,representative,candidates,frame,row,e,z,pref,signature,rules,domain,
  directory,inventory,analysis,rejected,rejectedFile,partition,regular,order,orderRequest,
  path,result,classification,allFiles,prepared,through,dependencies,currentBinding,
  physicalCache=<||>,effectiveRules,frameBinding},
 dependencies=coefficientPlanDependencies[request];
 catalog=dependencies["Catalog"];normalization=dependencies["Normalization"];
 currentBinding=coefficientPlanRequestBinding[request,dependencies];
 sourceNormalization=Lookup[request,"SourceNormalization",None];
 {rules,domain,through}=Lookup[request,{"KinematicRules","Assumptions","ThroughOrder"},None];
 threshold=Lookup[request,"FiniteAboveBytes",16*2^20];
 If[Lookup[catalog,"DataType",None]=!="EndpointCoefficientCatalog"||
   !AssociationQ[sourceNormalization]||!IntegerQ[through]||domain===None||
   !ListQ[rules]||!IntegerQ[threshold]||threshold<0,
  coefficientPlanFail["CoefficientPlanningInputsRequired"]];
 root=projectAbsolutePath[Lookup[request,"PlanDirectory",FileNameJoin[{nativeDirectory,"ReconstructionPlan"}]]];
 If[!DirectoryQ[root],CreateDirectory[root,CreateIntermediateDirectories->True]];
 allFiles=data["OutputFiles"];
 selected=Select[Range[Length[allFiles]],FileByteCount[allFiles[[#]]]>=threshold&&
   data["OutputMetadata"][[#]]["MasterIndex"]>0&];
 definitions=KeyTake[inputs["Metadata"],$coefficientPlanSourceFields];
 prepared=<|"DataType"->"CoefficientReconstructionPlan","SchemaVersion"->2,
   "PlanningInputBinding"-><|"CurrentDependencies"->currentBinding,"SourceDefinitions"->definitions|>,
   "PreparationMethod"->"Source divisor partition and physical endpoint Laurent bounds",
   "OrdinaryWorkingDirectory"->FileNameJoin[{nativeDirectory,"Reconstruction"}],
   "SourceTraceManifestHash"->coefficientFileHash[finiteFieldTraceManifestFile[inputs["TraceDirectory"]]]|>;
 If[selected==={},
  prepared=Join[prepared,<|"DiscoveryReport"-><|"CandidateOutputs"->{},"FiniteOutputs"->{},"ExactFallbacks"->{}|>|>];
  coefficientPlanWrite[prepared,FileNameJoin[{root,"Plan.wl"}]];Return[prepared]];
 definitions=KeyTake[inputs["Metadata"],$coefficientPlanSourceFields];
 indices=DeleteDuplicates[Lookup[data["OutputMetadata"][[selected]],"MasterIndex"]];
 masters=data["Masters"][[indices]];
 sourceCatalog=<|"Integrals"->masters,"Families"->definitions["Topologies"],"Normalization"->sourceNormalization|>;
 match=FeynFacet`MatchCutIntegralCatalogs[sourceCatalog,catalog["CutCatalog"]];
 If[!AssociationQ[match],coefficientPlanFail["SourceEndpointCatalogMatchFailed",<|"Cause"->match|>]];
 mappings=Association[(coefficientMasterID[#["Source"]]->#)&/@match["Mappings"]];

 names=SymbolName/@Values[data["SymbolRules"]];
 originals=Association@KeyValueMap[SymbolName[#2]->#1&,data["SymbolRules"]];
 Do[
  Print["Deriving coefficient orders for output ",index," (",Round[FileByteCount[allFiles[[index]]]/2.^20,0.1]," MiB)"];
  result=Catch[
   source=allFiles[[index]];master=data["Masters"][[data["OutputMetadata"][[index]]["MasterIndex"]]];
   mapping=Lookup[mappings,Key[coefficientMasterID[master]],None];
   If[!AssociationQ[mapping]||mapping["Factor"]=!=1,
    Throw[Failure["DirectUnitIntegralEmbeddingUnavailable",<|"Master"->master|>],"ExactColumn"]];
   If[!KeyExistsQ[physicalCache,coefficientMasterID[master]],
    AssociateTo[physicalCache,coefficientMasterID[master]->
      coefficientPlanPhysicalFactors[inputs,data,{master},normalization,Lookup[request,"DefinitionRequest",<||>]]]];
   physical=physicalCache[coefficientMasterID[master]];
   If[!AssociationQ[physical],Throw[Failure["SourcePhysicalNormalizationUnsupported",<|"Cause"->physical|>],"ExactColumn"]];
   representative=mapping["Representative"];
   candidates=FeynFacet`FindEndpointCoefficientFrames[catalog,{representative}];
   If[!ListQ[candidates]||candidates==={},Throw[Failure["CoveringEndpointFrameUnavailable",<||>],"ExactColumn"]];
   (* Prefer the matched family's accepted bounds when available, then the
      existing dimension/gauge-size ordering. *)
   candidates=Join[Intersection[{First[coefficientMasterID[representative]]},candidates],
     DeleteCases[candidates,First[coefficientMasterID[representative]]]];
   frame=catalog["Frames"][First[candidates]];
   row=First[frame["RowsByIntegralClass"][catalog["IntegralClasses"][coefficientMasterID[representative]]]];
   {e,z}=Lookup[frame["Endpoint"],{"DimensionalRegulator","NormalVariable"}];
   effectiveRules=coefficientPlanEffectiveRules[data,inputs["Context"],normalization,rules,frame["Endpoint"],domain];
   If[FailureQ[effectiveRules],Throw[effectiveRules,"ExactColumn"]];
   frameBinding=coefficientPlanFrameBinding[catalog,frame,row,physical,master,mapping,normalization,rules];
   If[FailureQ[frameBinding],Throw[frameBinding,"ExactColumn"]];
   signature=finiteFieldCertifyPhysicalVariables[
     coefficientRegulatorNormalize[ReleaseHold[data["Signatures"][data["OutputMetadata"][[index]]["SignatureIndex"]]],e],
     Join[inputs["Context"],<|"ExternalDistribution"->inputs["Data"]["PhaseSpace"]|>]];
   If[signature===$Failed,Throw[Failure["PhysicalAnalyticSignatureRequired",<||>],"ExactColumn"]];
   pref=signature/.Normal[inputs["Context"]["DimensionlessCoordinates"]];
   pref=coefficientRegulatorNormalize[(pref/.normalization["KinematicRules"])*
     physical["GlobalPreFactor"]physical["MasterMultipliers"][coefficientMasterID[master]],e]/.rules;
   orderRequest=<|"MasterRow"->row,"ThroughOrder"->through,"AliasNames"->names,"AliasOriginals"->originals,
     "KinematicRules"->effectiveRules,"Assumptions"->domain,"PreFactor"->pref,"PreFactorInEndpointCoordinates"->True,
     "PhysicalFrameBinding"->frameBinding,
     "CatalogMapping"->mapping,"SourceDefinitions"->definitions,
     "TraceColumnBinding"-><|"OutputMetadata"->data["OutputMetadata"][[index]],
       "Definitions"->KeyTake[data,{"Masters","SymbolRules","Signatures","Variables","PhysicalFactor"}]|>,
     "PhysicalNormalizationRequest"->normalization,
     "PhysicalNormalizationConstruction"->physical["Definitions"],
     "AcceptedEndpointBinding"->frame["AcceptedEndpointBinding"]|>;
   directory=FileNameJoin[{root,FileBaseName[source]}];
   If[!DirectoryQ[directory],CreateDirectory[directory]];
   path=FileNameJoin[{directory,"Source.divisors.json"}];
   coefficientPlanBackend[{source,path},"DIVISOR INVENTORY"];
   inventory=Import[path,"RawJSON"];
   analysis=coefficientAnalyzeDivisors[inventory,e,z,names,originals,effectiveRules,domain];
   rejected=Pick[inventory["Divisors"],FailureQ/@analysis];
   classification=MapThread[<|"Divisor"->#1,"Analysis"->#2|>&,{inventory["Divisors"],analysis}];
   coefficientPlanWrite[classification,FileNameJoin[{directory,"DivisorAnalysis.wl"}]];
   rejectedFile=FileNameJoin[{directory,"RejectedDivisors.json"}];Export[rejectedFile,rejected,"RawJSON"];
   coefficientPlanBackend[{"--partition",rejectedFile,source,FileNameJoin[{directory,"Partitions"}]},
     "LITERAL PARTITION CREATED AND VERIFIED"];
   partition=Import[FileNameJoin[{directory,"Partitions","Partition.json"}],"RawJSON"];
   If[partition["Parts"]["Regular"]["Summands"]===0,Throw[Failure["NoRegularCoefficientSummands",<||>],"ExactColumn"]];
   regular=Import[FileNameJoin[{directory,"Partitions","Regular.divisors.json"}],"RawJSON"];
   orderRequest=Append[orderRequest,"Source"-><|"ExpressionFile"->regular["Source"],
     "LiteralPartitionManifest"->FileNameJoin[{directory,"Partitions","Partition.json"}],
     "InventoryFile"->FileNameJoin[{directory,"Partitions","Regular.divisors.json"}]|>];
   order=FeynFacet`DetermineCoefficientReconstructionOrders[regular,frame["Endpoint"],frame["Bounds"],orderRequest];
   If[FailureQ[order]&&MemberQ[{"DivisorInventorySourceBindingMismatch","CoefficientOrderInputsRequired",
      "NonemptyDenominatorProductInventoryRequired"},order[[1]]],
    coefficientPlanFail["CoefficientOrderInputIntegrityFailure",<|"Cause"->order|>]];
   If[!AssociationQ[order],Throw[order,"ExactColumn"]];
   AssociateTo[plans,index->order];AppendTo[partitions,partition];
   <|"Output"->index,"Status"->"FiniteRegularPart","RequiredUpperOrder"->order["RequiredCoefficientUpperOrder"],
     "RegularSummands"->partition["Parts"]["Regular"]["Summands"],
     "ExactSummands"->partition["Parts"]["Exact"]["Summands"],"EndpointFrame"->First[candidates]|>,
  "ExactColumn"];
  AppendTo[reports,If[FailureQ[result],<|"Output"->index,"Status"->"ExactRational","Reason"->result|>,result]],
 {index,selected}];
 prepared=Join[prepared,<|"DiscoveryReport"-><|"CandidateOutputs"->selected,"FiniteOutputs"->Keys[plans],
   "ExactFallbacks"->Select[reports,#["Status"]==="ExactRational"&],"Columns"->reports|>,
   "PlanningInputBinding"-><|"CurrentDependencies"->currentBinding,
     "SourceDefinitions"->definitions,"SourceCatalogMatch"->match|>|>];
 If[partitions=!={},
  path=FileNameJoin[{root,"Partitions.json"}];Export[path,partitions,"RawJSON"];
  coefficientPlanWrite[plans,FileNameJoin[{root,"CoefficientOrders.wl"}]];
  prepared=Join[prepared,<|"PartitionManifest"->path,
    "CoefficientOrderPlans"->FileNameJoin[{root,"CoefficientOrders.wl"}],
    "PartitionWorkingDirectory"->FileNameJoin[{root,"Reconstruction"}]|>]];
 coefficientPlanWrite[prepared,FileNameJoin[{root,"Plan.wl"}]];
 prepared
],"CoefficientPlan"];
FeynFacet`PrepareCoefficientReconstructionPlan[traceDirectory_String,request_Association] := Module[
 {inputs,data,native},
 inputs=reconstructionInputs[ExpandFileName[traceDirectory],<|"CoefficientSetup"->Lookup[request,"CoefficientSetup",Automatic]|>];
 If[!AssociationQ[inputs],Return[inputs]];
 data=finiteFieldCompactTrace[inputs["TraceData"],inputs["TraceDirectory"],1,
   Lookup[request,"CompactAboveBytes",10*2^20],Lookup[request,"CompactionEntrySeconds",30],
   Lookup[request,"CompactionColumnSeconds",600]];
 If[!AssociationQ[data],Return[data]];
 native=If[KeyExistsQ[data,"Compaction"],data["Compaction"]["Directory"],inputs["TraceDirectory"]];
 coefficientPrepareReconstructionPlan[inputs,data,native,request]
];
End[];EndPackage[];
