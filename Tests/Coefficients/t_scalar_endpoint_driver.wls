#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/Scripts/Coefficients/ScalarEndpointDriver.wl"];
Get[root<>"/Scripts/Coefficients/ScalarEndpointCampaign.wl"];
mockFile=root<>"/Tests/Coefficients/Support/ScalarEndpointDriverMocks.wl";Get[mockFile];
testOutput=root<>"/ppHX_NNLO_DoubleReal/Results/Assembly/TangentialEndpoint_2026-09-07/ScalarDriverTests/"<>
 StringReplace[CreateUUID[],"-"->""];
endpointDirectory=testOutput<>"/Endpoint";
put[value_,name_]:=ScalarEndpointDriver`WriteScalarEndpointArtifact[value,endpointDirectory<>"/"<>name<>".wxf"];
put[<|"OriginalMasterIntegralBasis"->{"m"},"MaximumNormalOrder"->0|>,"endpoint_system"];
put[<|"TangentialBasePoint"->1/4|>,"boundary_basis_matching"];put[<||>,"laurent_bounds"];
put[<|"PhysicalBoundaryConstruction"-><|"AmplitudeLaurentLowerBounds"->{0}|>|>,"input"];
coefficient[family_,mode_:"Success",depth_:1]:=<|"Family"->family,
 "OriginalMasterIntegralBasis"->{"m"},"CoefficientEntries"->{<|"Master"->"m","Terms"->{}|>},
 "Request"-><|"ThroughOrder"->0,"Mode"->mode,"Depth"->depth|>,"SourceCoefficientFile"->"AnalyticDriverFixture"|>;
request[family_,mode_:"Success",depth_:1]:=<|"CoefficientInput"->coefficient[family,mode,depth],
 "EndpointSystemDirectory"->endpointDirectory,"ThroughOrder"->0|>;
run[input_,directory_,seconds_:10]:=ScalarEndpointDriver`RunScalarEndpointFamily[input,directory,
 "ImplementationFiles"->{},"Verbose"->False,"TimeLimit"->seconds];
first=run[request["Alpha"],testOutput<>"/First"];
FTAssert["one family checkpoints all four stages",first["Status"]==="ExplicitPhysicalScalarEndpointCoefficients"&&
 Values[$ScalarDriverTestCalls]==={1,1,1,1}];
before=$ScalarDriverTestCalls;second=run[request["Alpha"],testOutput<>"/First"];
FTAssert["resume reuses every completed stage without rerunning constructors",
 second["ReusedStages"]==={"order_requirements","endpoint_system","scalar_projection","scalar_endpoint_solution"}&&
 $ScalarDriverTestCalls===before];
changed=run[request["Alpha","Success",2],testOutput<>"/First"];
FTAssert["changed mathematical input cannot reuse stale stage files",
 changed["Generation"]===first["Generation"]+1&&changed["NormalOrder"]===2&&changed["ReusedStages"]==={}];
other=run[request["Beta"],testOutput<>"/Other"];
FTAssert["reusing the same kernel keeps family state local",other["Family"]==="Beta"&&other["Generation"]===1];
unresolved=run[request["Unresolved","Unresolved"],testOutput<>"/Unresolved"];
missing=run[request["Missing","Missing"],testOutput<>"/Missing"];
physicalMissing=run[request["PhysicalMissing","PhysicalMissing"],testOutput<>"/PhysicalMissing"];
FTAssert["unresolved coefficient classes and missing orders have distinct statuses",
 unresolved["Status"]==="UNRESOLVED_COEFFICIENT_CLASS"&&missing["Status"]==="MISSING_ORDERS"&&
 physicalMissing["Status"]==="MISSING_ORDERS"];
timed=run[request["Timed","Timeout"],testOutput<>"/Timed",1];
before=$ScalarDriverTestCalls;$ScalarDriverSkipDelay=True;
continued=run[request["Timed","Timeout"],testOutput<>"/Timed"];
FTAssert["a timed-out projection retains and reuses its completed order and normal stages",
 timed["Status"]==="TIME_LIMIT"&&timed["Stage"]==="ScalarEndpointProjection"&&
 continued["Status"]==="ExplicitPhysicalScalarEndpointCoefficients"&&
 continued["ReusedStages"]==={"order_requirements","endpoint_system"}&&
 $ScalarDriverTestCalls["Orders"]===before["Orders"]];
files=Table[With[{path=testOutput<>"/Inputs/"<>name<>".wxf"},
 ScalarEndpointDriver`WriteScalarEndpointArtifact[coefficient[name],path];path],{name,{"Alpha","Beta","Gamma"}}];
manifest=<|"AcceptedDirectories"->AssociationThread[{"Alpha","Beta","Gamma","Deferred","NoInput"},
 ConstantArray[endpointDirectory,5]]|>;
campaign=ScalarEndpointCampaign`RunScalarEndpointCampaign[
 <|"CoefficientInputFiles"->files,"AcceptedEndpointManifest"->manifest,"Workers"->2,
   "FamilyTimeLimit"->10,"Verbose"->False,"WorkerInitializationFile"->mockFile,
   "DeferredFamilies"-><|"Deferred"->"The required coefficient class is being established."|>|>,testOutput<>"/Campaign"];
FTAssert["dynamic campaign reports every input, absent input and explicit deferral",
 AssociationQ[campaign]&&campaign["RequestedFamilyCount"]===5&&campaign["ExplicitFamilyCount"]===3&&
 campaign["DeferredFamilyCount"]===1&&campaign["OtherFailureFamilyCount"]===1];
values=Table[ScalarEndpointDriver`ReadScalarEndpointInput[testOutput<>"/Campaign/"<>name<>"/scalar_endpoint_solution.wxf"]["WorkerInvocation"],
 {name,{"Alpha","Beta","Gamma"}}];
FTAssert["persistent workers process more than one family without resetting their runtime",
 Max[values]>=2&&Length[DeleteDuplicates[Lookup[campaign["Results"],"WorkerKernelID"]]]<=2];
FTAssert["the campaign closes only its owned worker pool",Kernels[]==={}];
Print["Artifacts: ",testOutput];FTReport[];
