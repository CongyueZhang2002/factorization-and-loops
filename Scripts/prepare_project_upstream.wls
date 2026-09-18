Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3},Length[args]],Print["Usage: prepare_project_upstream.wls PROJECT ORDER [OUTPUT_MANIFEST.json]"];Exit[2]];
{projectName,order}=Take[args,2];project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>projectName];
If[!AssociationQ[project]||order=!="NNLO",Print["Declared NNLO project required"];Exit[2]];
stages={};shared={};sourceCards={};
add[driver_,identity_,name_]:=AppendTo[stages,<|"Name"->StringRiffle[Append[identity,name],"/"],
 "Driver"->"Scripts/"<>driver,"Arguments"->identity,"Completion"->"COMPLETED ",
 "Log"->StringRiffle[{"Raw",order,identity[[3]],First[StringSplit[identity[[4]],"."]],"Work","Validation",StringReplace[identity[[4]],"."->"-"]<>"-"<>name<>".log"},"/"]|>];
Do[
 directory=FileNameJoin[{project["Directory"],"Raw",order,channel}];
 paths=FileNames["*/Card.wl",directory];
 Do[
  declared=Get[file];
  If[!AssociationQ[declared],Print["Contribution card must be an association: ",file];Exit[1]];
  If[Lookup[declared,"Contribution",None]==="Counterterm",Continue[]];
  contribution=FileNameTake[DirectoryName[file]];
  card=FeynFacet`ReadContributionCard[directory,contribution];
  If[!AssociationQ[card],Print[card];Exit[1]];
  If[card["Contribution"]==="Counterterm",Continue[]];
  components=Keys[Lookup[card,"Components",<||>]];
  selected=If[components==={},{contribution},(contribution<>"."<>#)&/@components];
  Do[
   component=FeynFacet`ReadContributionCard[directory,name];
   identity={projectName,order,channel,name};
   add["construct_current_integrands.wls",identity,"Generate"];
   Switch[card["Contribution"],
    "DoubleReal",
     add["prepare_current_integrals.wls",identity,"Prepare"];
     AppendTo[shared,AssociationThread[{"Project","Order","Channel","Contribution"},identity]],
    "RealVirtual",
     add["reduce_current_one_loop_integrands.wls",identity,"ReduceOneLoop"];
     add["evaluate_current_one_loop_integrands.wls",identity,"EvaluateOneLoop"];
     add["construct_current_one_loop_endpoints.wls",identity,"OneLoopEndpoints"],
    "DoubleVirtual",
     add["prepare_current_virtual_integrals.wls",identity,"PrepareVirtual"];
     add["reduce_current_virtual_integrals.wls",identity,"ReduceVirtual"],
    _,Print["Unsupported generated NNLO contribution ",card["Contribution"]];Exit[1]],
  {name,selected}];
  If[card["Contribution"]==="DoubleVirtual",
   add["prepare_virtual_integration_plan.wls",{projectName,order,channel,contribution},"VirtualIntegrationPlan"]],
 {file,paths}],
 {channel,project["Orders"][order]}];
If[shared==={},Print["Measured double-real sources required for this upstream method"];Exit[1]];
first=First[shared];owner=FileNameJoin[{project["Directory"],"Raw",order,first["Channel"],"DoubleReal","Work"}];
If[!DirectoryQ[owner],CreateDirectory[owner,CreateIntermediateDirectories->True]];
masterPath=owner<>"/SharedMasterIntegrals";
sharedManifest=owner<>"/SharedReduction.json";
Export[sharedManifest,<|"Contributions"->shared,"OutputDirectory"->"SharedMasterIntegrals",
 "WorkingDirectory"->"SharedMasterIntegrals/Kira","Threads"->Lookup[project["Execution"],"KiraThreads",1],
 "GenerationKernels"->Lookup[project["Execution"],"Kernels",1]|>,"RawJSON"];
appendStage[name_,driver_,arguments_]:=AppendTo[stages,<|"Name"->name,"Driver"->"Scripts/"<>driver,
 "Arguments"->arguments,"Completion"->"COMPLETED ",
 "Log"->StringRiffle[Drop[FileNameSplit[owner],Length[FileNameSplit[project["Directory"]]]],"/"]<>"/Validation/"<>name<>".log"|>];
appendStage["SharedDifferentialSystem","construct_shared_current_differential_system.wls",{sharedManifest}];
appendStage["PhysicalMasterBasis","prepare_measured_master_solution.wls",{sharedManifest}];
appendStage["PhysicalMasterCoefficients","contract_current_integral_reduction.wls",
 {masterPath<>"/ReductionInput.wl",masterPath<>"/PhysicalReduction.wl",masterPath<>"/MasterCoefficients.wl"}];
appendStage["PhysicalBoundaries","construct_measured_master_boundaries.wls",
 {masterPath<>"/PhysicalDifferentialSystem.wl",masterPath<>"/BoundaryRequest.wl",masterPath<>"/BoundaryValues.wl"}];
appendStage["MasterOrders","plan_current_master_orders.wls",
 {masterPath<>"/MasterCoefficients.wl",masterPath<>"/SolutionRequest.wl"}];
appendStage["ExplicitMasterSolution","solve_ordered_measured_master_integrals.wls",
 {masterPath<>"/MasterIntegralDefinitions.wl",masterPath<>"/BoundaryValues.wl",masterPath<>"/SolutionRequest.wl",masterPath<>"/Solution"}];
bulkRequest=owner<>"/BulkContractionRequest.wl";
firstCard=FeynFacet`ReadContributionCard[
 FileNameJoin[{project["Directory"],"Raw",order,first["Channel"]}],first["Contribution"]];
boundaryRequest=firstCard["Assembly"]["MasterIntegration"]["Boundary"];
inverseRecoil=Solve[
 boundaryRequest["RecoilSubstitution"][[1,1]]==boundaryRequest["RecoilSubstitution"][[1,2]],
 boundaryRequest["RecoilVariable"]];
If[!MatchQ[inverseRecoil,{{_Rule}}],Print["Unique declared recoil-coordinate inverse required"];Exit[1]];
rawRanges=Table[
 FeynFacet`ReadContributionCard[FileNameJoin[{project["Directory"],"Raw",order,item["Channel"]}],
  item["Contribution"]]["EpsilonRange"],{item,shared}];
FeynFacet`FamilyArtifactWrite[<|"EpsilonOrderRange"->{Min[rawRanges[[All,1]]],Max[rawRanges[[All,2]]]},
 "MasterKinematicRules"->First[inverseRecoil],"RetainLowerLaurentOrders"->True|>,bulkRequest];
appendStage["BulkContraction","contract_explicit_master_solution.wls",
 {masterPath<>"/MasterCoefficients.wl",masterPath<>"/Solution/PhysicalMasterExplicitGPLSolution.wl",
  bulkRequest,masterPath<>"/BulkCoefficients.wl"}];
appendStage["EndpointProfiles","construct_ordered_endpoint_profiles.wls",
 {masterPath<>"/MasterCoefficients.wl",masterPath<>"/BoundaryValues.wl",
  masterPath<>"/BulkCoefficients.wl",masterPath<>"/Endpoints"}];
outputManifest=If[Length[args]===3,ExpandFileName[args[[3]]],owner<>"/Upstream.json"];
If[!StringStartsQ[outputManifest,project["Directory"]<>"/"],
 Print["Upstream manifest must belong to the active project"];Exit[1]];
If[!DirectoryQ[DirectoryName[outputManifest]],CreateDirectory[DirectoryName[outputManifest],CreateIntermediateDirectories->True]];
Export[outputManifest,<|"Stages"->stages,"FinalAssemblyReady"->True,
 "SupportedEndpointGeometry"->"Verified direct logarithmic normal crossing with simple physical density powers",
 "Remaining"->{}|>,"RawJSON"];
Print["COMPLETED PROJECT UPSTREAM INVENTORY ",outputManifest," STAGES ",Length[stages]];
