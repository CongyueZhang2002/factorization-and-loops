#!/usr/bin/env wolframscript
(* General single-divisor endpoint driver. All paths, coordinate maps,
   selections, normalization and finite orders are mathematical input. *)
$HistoryLength=0;
started=AbsoluteTime[];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
If[Length[DownValues[FeynFacet`ConstructTangentialEndpointSystem]]===0,
 Get[root<>"/FeynFacet/Boundary/TangentialSystem.wl"]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
read[path_String]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]];
read[value_]:=value;
output=ExpandFileName[args[[2]]];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
save[value_,name_]:=Module[{path=FileNameJoin[{output,name<>".wxf"}],stream,tmp},
 tmp=path<>".partial";stream=OpenWrite[tmp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[value,PerformanceGoal->"Size"]],"Byte"];
 Close[stream];RenameFile[tmp,path,OverwriteTarget->True]];
require[value_,stage_]:=If[FailureQ[value]||!AssociationQ[value],
 save[<|"Stage"->stage,"Failure"->value|>,"failure"];Print["FAIL ",stage," ",value];Exit[1]];
fail[tag_,detail_:<||>]:=require[Failure[tag,detail],"Input"];
zero[value_]:=FeynFacet`Private`tangentialEndpointZeroQ[value];
input=read[args[[1]]];require[input,"Input"];
save[input,"input"];
source=read[input["DifferentialSystem"]];require[source,"DifferentialSystem"];
save[source,"source_system"];
variables=source["KinematicVariables"];epsilon=source["DimensionalRegulator"];
{normal,tangent}=input["EndpointCoordinates"];
rules=input["CoordinateRules"];
images=variables/.rules;
If[Length[variables]=!=2 || Length[images]=!=2 ||
 !FreeQ[images,Alternatives@@variables] ||
 !MatchQ[{normal,tangent},{_Symbol,_Symbol}] || normal===tangent,
 fail["TwoDimensionalEndpointCoordinateMapRequired"]];
jacobian=Det[Table[D[images[[i]],x],{i,2},{x,{normal,tangent}}]];
If[zero[jacobian],fail["EndpointCoordinateMapSingular"]];
rows=Lookup[input,"Rows",Range[Length[source["OriginalMasterIntegralBasis"]]]];
outside=Complement[Range[Length[source["OriginalMasterIntegralBasis"]]],rows];
If[!VectorQ[rows,IntegerQ] || rows==={} || !DuplicateFreeQ[rows] ||
 !AllTrue[rows,1<=#<=Length[source["OriginalMasterIntegralBasis"]]&],fail["EndpointMasterRowsInvalid"]];
If[outside=!={} && !zero[source["ConnectionMatrices"][[All,rows,outside]]],
 fail["EndpointMasterSelectionNotDifferentiallyClosed"]];
matrices=source["ConnectionMatrices"][[All,rows,rows]]/.rules;
endpointSystem=<|"NormalVariable"->normal,"TangentialVariable"->tangent,
 "DimensionalRegulator"->epsilon,
 "OriginalMasterIntegralBasis"->source["OriginalMasterIntegralBasis"][[rows]],
 "NormalConnectionMatrix"->Total[MapThread[#1 #2&,{D[images,normal],matrices}]],
 "TangentialConnectionMatrix"->Total[MapThread[#1 #2&,{D[images,tangent],matrices}]]|>;
endpoint=ConstructTangentialEndpointSystem[endpointSystem,input["EndpointRequest"],
 "NormalGaugeMatrix"->read[Lookup[input,"NormalGaugeMatrix",Automatic]],
 "ParameterVerificationRules"->Lookup[input,"ParameterVerificationRules",
   {tangent->input["SolutionRequest"]["TangentialBasePoint"]}],"Verbose"->True];
require[endpoint,"SymbolicTangentialSystem"];save[endpoint,"endpoint_system"];
Print["PASS symbolic tangential system: ",Length[rows]," original components."];
solutionRequest=input["SolutionRequest"];
If[KeyExistsQ[input,"PhysicalBoundaryConstruction"],
 construction=read[input["PhysicalBoundaryConstruction"]];require[construction,"PhysicalBoundaryConstruction"];
 preparation=construction["PreparedBoundarySystem"];
 frozenNormal=preparation["NormalizedDifferentialSystem"]["Variable"];
 base=solutionRequest["TangentialBasePoint"];
 frozenImages=(variables/.construction["NormalCoordinateRules"])/.frozenNormal->normal;
 If[!zero[(images/.tangent->base)-frozenImages],
  fail["PhysicalBoundaryCoordinateLineMismatch"]];
 If[KeyExistsQ[input,"OriginalIntegralEmbedding"],embedding=read[input["OriginalIntegralEmbedding"]],
  globalSystem=read[construction["GlobalDifferentialSystem"]];
  closed=read[construction["RequestedDifferentialSystem"]];
  require[globalSystem,"GlobalDifferentialSystem"];require[closed,"RequestedDifferentialSystem"];
  familyMap=SelectFirst[globalSystem["FamilyMaps"],ToString[#["Family"]]===ToString[source["Family"]]&,Missing[]];
  If[MissingQ[familyMap],fail["GlobalFamilyIntegralEmbeddingMissing"]];
  If[(FeynFacet`Private`globalDEIdentity/@source["OriginalMasterIntegralBasis"])=!=
    (FeynFacet`Private`globalDEIdentity/@familyMap["OriginalMasterIntegralBasis"]),
   fail["GlobalFamilyIntegralBasisMismatch"]];
  globalAliases=Thread[globalSystem["KinematicVariables"]->variables];
  embedding=(Normal[familyMap["IntegralEmbedding"]][[rows]]/.globalAliases/.rules)/.tangent->base;
  removed=Complement[Range[Dimensions[embedding][[2]]],closed["SourceMasterRows"]];
  If[removed=!={} && !zero[embedding[[All,removed]]],fail["FamilyOutsidePhysicalBoundaryClosure"]];
  embedding=embedding[[All,closed["SourceMasterRows"]]]];
 reference=<|"TangentialBasePoint"->base,
  "NormalizedDifferentialSystem"->preparation["NormalizedDifferentialSystem"],
  "OriginalToNormalizedGauge"->preparation["OriginalToNormalizedGauge"],
  "NormalizedToOriginalGauge"->preparation["NormalizedToOriginalGauge"],
  "SeedMatrix"->construction["BoundarySeed"]["Basis"],
  "OriginalIntegralEmbedding"->embedding|>;
 Print["Matching the complete physical normal-line seed."];
 matching=MatchTangentialEndpointBoundaryBasis[endpoint,reference];
 require[matching,"PhysicalBoundaryBasisMatching"];save[matching,"boundary_basis_matching"];
 laurentBounds=DetermineTangentialEndpointLaurentBounds[endpoint,matching,
   construction["AmplitudeLaurentLowerBounds"]];
 require[laurentBounds,"PhysicalEndpointLaurentBounds"];save[laurentBounds,"laurent_bounds"];
 solutionRequest=Join[solutionRequest,<|"PhysicalBoundaryValues"-><|
   "BoundaryBasisMatching"->matching,
   "AmplitudeLaurentLowerBounds"->construction["AmplitudeLaurentLowerBounds"],
   "AmplitudeCoefficients"-><|"PhysicalBoundaryConstruction"->construction|>|>|>]];
If[Lookup[input,"ConstructionStage","FiniteSolution"]==="SystemAndMatching",
 summary=<|"Family"->Lookup[source,"Family",None],"Rows"->rows,
   "Dimension"->Length[rows],"SourceDifferentialSystemFile"->input["DifferentialSystem"],
   "OriginalMasterIntegralBasis"->source["OriginalMasterIntegralBasis"][[rows]],
   "CoordinateRules"->rules,"CoordinateJacobian"->jacobian,
   "MaximumNormalOrder"->endpoint["MaximumNormalOrder"],
   "OriginalNormalOrderRange"->endpoint["OriginalNormalOrderRange"],
   "NormalGaugeRowLowerBounds"->(Min/@Map[
      FeynFacet`Private`boundaryLocalOrder[#,normal]&,Normal[endpoint["NormalGaugeMatrix"]],{2}]),
   "ResidueSectors"->(KeyTake[#,{"Exponent","NilpotencyIndex"}]&/@endpoint["PrimarySectors"]),
   "BoundaryBasisMatched"->KeyExistsQ[input,"PhysicalBoundaryConstruction"],
   "LaurentBounds"->If[KeyExistsQ[input,"PhysicalBoundaryConstruction"],laurentBounds,None],
   "ConstructionStage"->"SystemAndMatching","ElapsedSeconds"->AbsoluteTime[]-started,
   "Status"->"PASS"|>;
 save[summary,"summary"];
 Print["PASS normal gauge, tangential system and complete boundary matching."];Exit[0]];
solution=ConstructTangentialEndpointSolution[endpoint,solutionRequest,"Verbose"->True];
require[solution,"FiniteTangentialEndpointSolution"];save[solution,"endpoint_solution"];
save[<|"Family"->Lookup[source,"Family",None],"Rows"->rows,
 "OriginalMasterIntegralBasis"->source["OriginalMasterIntegralBasis"][[rows]],
 "CoordinateRules"->rules,"CoordinateJacobian"->jacobian,
 "MaximumNormalOrder"->endpoint["MaximumNormalOrder"],
 "OriginalNormalOrderRange"->endpoint["OriginalNormalOrderRange"],
 "EpsilonOrderRange"->solution["EpsilonOrderRange"],
  "PhysicalBoundaryValuesApplied"->solution["PhysicalBoundaryValuesApplied"],
 "ElapsedSeconds"->AbsoluteTime[]-started,
 "Status"->"PASS"|>,"summary"];
Print["PASS finite tangential endpoint functions: ",Length[solution["EndpointTerms"]],
 " terms; physical normalization applied = ",solution["PhysicalBoundaryValuesApplied"],"."];
