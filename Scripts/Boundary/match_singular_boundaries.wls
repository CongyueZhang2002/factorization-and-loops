#!/usr/bin/env wolframscript
(* Materialize the singular-boundary solution in a process-independent
   campaign. Every input is a mathematical record or an explicit file path. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
read[x_String]:=If[ToLowerCase[FileExtension[x]]==="wxf",Import[x,"WXF"],FeynFacetRecords`ReadRecord[x]];
read[x_]:=x;
require[x_,stage_]:=If[FailureQ[x]||!AssociationQ[x],Print["FAIL ",stage," ",x];Exit[1]];
save[data_,path_]:=Module[{tmp=path<>".partial",stream},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 stream=OpenWrite[tmp,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[data,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 RenameFile[tmp,path,OverwriteTarget->True]];

relativePath[from_,target_]:=Module[{a=FileNameSplit[ExpandFileName[from]],
 b=FileNameSplit[ExpandFileName[target]],common=0},
 While[common<Min[Length[a],Length[b]]&&a[[common+1]]===b[[common+1]],common++];
 FileNameJoin[Join[ConstantArray["..",Length[a]-common],Drop[b,common]]]];
input=read[args[[1]]];require[input,"Input"];
output=ExpandFileName[args[[2]]];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
global=read[input["GlobalDifferentialSystem"]];
closed=read[input["RequestedDifferentialSystem"]];
preparation=If[KeyExistsQ[input,"PreparedBoundarySystem"],read[input["PreparedBoundarySystem"]],
 PrepareSingularBoundarySystem[read[input["NormalDifferentialSystem"]],"Verbose"->True]];
require[preparation,"Singular system preparation"];
(* The retained generic-epsilon physical subspace and any known amplitudes
   are physical inputs. Their matrix explicitly fixes the coordinate basis. *)
seed=read[input["BoundarySeed"]];
seedMatrix=seed["Basis"];
bounds=Lookup[input,"AmplitudeLaurentLowerBounds",Automatic];
orderData=If[KeyExistsQ[input,"BoundaryAmplitudeOrders"],read[input["BoundaryAmplitudeOrders"]],
 DetermineBoundaryAmplitudeOrders[preparation,seed,input["OriginalMasterLaurentLowerBounds"]]];
require[orderData,"Boundary amplitude orders"];
If[bounds===Automatic,bounds=orderData["AmplitudeLaurentLowerBounds"]];
entryLower=orderData["MatrixEntryLaurentLowerBounds"];
ordinaryBounds=MapThread[Min,{input["OriginalMasterLaurentLowerBounds"],
 Table[Min[entryLower[[i]]+bounds],{i,Length[entryLower]}]}];
files=ExpandFileName/@input["SolutionFiles"];
solutions=Association@Table[q=read[file];q["Family"]->q,{file,files}];
sourceFiles=AssociationThread[Lookup[Values[solutions],"Family"],files];
familyMaps=Association@Table[ToString[q["Family"]]->q,{q,global["FamilyMaps"]}];
globalBounds=AssociationThread[closed["SourceMasterRows"],ordinaryBounds];
Clear[q];
extend[q_]:=Module[{fm,emb,old,local,e=q["DimensionalRegulator"]},
 fm=familyMaps[q["Family"]];
 old=Lookup[q,"LocalInitialConstantLaurentLowerBounds",q["InitialConstantLaurentLowerBounds"]];
 emb=Normal[fm["IntegralEmbedding"]]/.Thread[q["KinematicVariables"]->q["BasePoint"]];
 local=Table[Min@Table[If[emb[[i,j]]===0,Infinity,
  FeynFacet`Private`solutionValuation[emb[[i,j]],e]+Lookup[globalBounds,j,
   If[MissingQ[old[[i]]],Infinity,old[[i]]]]],{j,Length[First[emb]]}],{i,Length[emb]}];
 ExtendMasterIntegralSolutionForBoundaryBounds[q,local]];
cores=Lookup[input,"Cores",1];
If[!IntegerQ[cores]||cores<1||cores>8,Print["FAIL Cores must be 1 through 8"];Exit[1]];
If[cores>1,
 LaunchKernels[cores];
 With[{loader=root<>"/Addon/Load/LoadFACET.wl"},ParallelEvaluate[Block[{Print},Get[loader]]]];
 Print["Distributing family order inputs."];
 DistributeDefinitions[familyMaps,globalBounds,extend];
 Print["Extending family orders on ",cores," subkernels."];
 extended=ParallelMap[extend,Values[solutions],DistributedContexts->None];
 CloseKernels[],
 extended=extend/@Values[solutions]];
If[AnyTrue[extended,!AssociationQ[#]&],Print["FAIL Family order extension ",Select[extended,!AssociationQ[#]&]];Exit[1]];
solutions=AssociationThread[Keys[solutions],extended];Clear[extended];
Print["Family orders complete."];
maps=ExpressFamilyBoundaryConstantsInGlobalBasis[solutions,global,closed,ordinaryBounds,input["NormalCoordinates"]];
require[maps,"Same-point integral embeddings"];Clear[solutions];
spec=Join[KeyDrop[maps,"Solutions"],<|"AmplitudeLaurentLowerBounds"->bounds,
 "KnownAmplitudeExpressions"->Lookup[input,"KnownAmplitudeExpressions",<||>],
 "UnknownAmplitudeDefinitions"->input["UnknownAmplitudeDefinitions"]|>];
knownOrdinary=Lookup[input,"KnownOriginalMasterExpressions",<||>];
z=preparation["NormalizedDifferentialSystem"]["Variable"];
spec=Join[spec,<|"KnownOrdinaryPointValues"->Association@Table[
 If[!KeyExistsQ[knownOrdinary,entry["ConnectionRow"]],Nothing,
  entry["Index"]->(knownOrdinary[entry["ConnectionRow"]]/.z->First[entry["NormalCoordinates"]])],
 {entry,spec["OrdinaryPointBoundaryBasis"]}]|>];
upper=Table[Max[Prepend[Table[
 If[KeyExistsQ[spec["KnownOrdinaryPointValues"],First[pair]]||
    entryLower[[spec["BoundaryIndexToConnectionRow"][First[pair]],j]]===Infinity,
  Nothing,Last[pair]-bounds[[j]]],
 {pair,spec["RequiredBoundaryCoefficients"]}],0]],{j,Length[bounds]}];
connection=If[KeyExistsQ[input,"BoundaryConnection"],read[input["BoundaryConnection"]],
 ConstructSingularBoundaryConnection[preparation,seedMatrix,
  <|"ColumnUpperOrders"->upper,"BranchPrescription"->input["BranchPrescription"]|>,
  "ContourDeformation"->Lookup[input,"ContourDeformation",1/4],
  "EndpointPower"->Lookup[input,"EndpointPower",8],"Verbose"->True]];
require[connection,"Finite singular-boundary connection"];
If[AnyTrue[Range[Length[upper]],upper[[#]]>connection["ColumnUpperOrders"][[#]]&],
 Print["FAIL Supplied connection has insufficient epsilon orders"];Exit[1]];
connection=Join[connection,<|"MatrixEntryLaurentLowerBounds"->entryLower|>];
(* Proved zero coefficients are removed before dependency selection. *)
connection["Coefficients"]=Association@KeyValueMap[Function[{order,rows},
 order->Map[Function[row,First[row]->MapIndexed[
  If[order<entryLower[[First[row],First[#2]]],0,#1]&,Last[row]]],rows]],connection["Coefficients"]];
shared=ConstructSharedBoundaryCoefficientDefinitions[connection,spec,"Verbose"->True];
require[shared,"Shared finite boundary coefficients"];
sharedFile=output<>"/shared_boundary_coefficients.wxf";save[shared,sharedFile];
save[<|"NormalizedDifferentialSystem"->preparation["NormalizedDifferentialSystem"],
 "OriginalToNormalizedGauge"->preparation["OriginalToNormalizedGauge"],
 "SeedMatrix"->seedMatrix,"ColumnLowerBounds"->bounds,
 "KnownAmplitudeExpressions"->spec["KnownAmplitudeExpressions"],
 "UnknownBoundaryAmplitudes"->spec["UnknownAmplitudeDefinitions"],
 "NormalCoordinates"->input["NormalCoordinates"],"MatrixEntryLaurentLowerBounds"->entryLower,
 "CountertermNormalOrder"->connection["CountertermNormalOrder"]|>,output<>"/boundary_amplitude_basis.wxf"];
records={};pairs={};stored=<||>;
KeyValueMap[Function[{family,draft},
 result=ApplySharedBoundaryCoefficientDefinitions[draft,shared,sharedFile];
 require[result,"Family "<>family];
 AssociateTo[stored,family->result["StoredSolution"]];
 pairs=Union[pairs,result["RequiredBoundaryAmplitudeCoefficients"]];
 AppendTo[records,<|"Family"->family,"Status"->"PASS",
  "RequiredBoundaryAmplitudeCoefficients"->result["RequiredBoundaryAmplitudeCoefficients"],
  "ResolvedDefinitionCounts"->(Length/@Lookup[result["ResolvedSolution"],
    {"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}])|>];
 Print["PASS ",family]],maps["Solutions"]];
(* Validate every candidate before replacing any campaign source file. *)
KeyValueMap[Function[{family,data},Module[{path,record=data,summary,required},
 path=If[TrueQ[Lookup[input,"ReplaceSourceSolutions",False]],sourceFiles[family],
  output<>"/Solutions/"<>family<>"/solution.wxf"];
 record["SharedBoundaryDefinitionFile"]=relativePath[DirectoryName[path],sharedFile];
 save[record,path];
 required=record["RequiredInitialConstantCoefficients"];
 summary=<|"Status"->"Completed","Family"->family,"SchemaVersion"->5,
  "ClosedMasterCount"->Length[record["OriginalMasterIntegralBasis"]],
  "RequestedMasterCount"->Length[record["RequestedRows"]],
  "StoredMasterCoefficientCount"->Total[Length/@Values[record["MasterIntegralCoefficients"]]],
  "RequiredBoundaryCoefficientCount"->Length[required],
  "RequiredUnknownBoundarySeriesCount"->Length[Union[First/@required]],
  "GlobalUnknownBoundarySeriesCount"->shared["UnknownBoundarySeriesCount"],
  "CompressedBytes"->FileByteCount[path],
  "SingularBoundaryMatchingApplied"->True,"BoundaryConstantsDetermined"->False,
  "PhysicalNNLOCoverageInferred"->False|>;
 save[summary,DirectoryName[path]<>"/summary.wxf"];
 Export[DirectoryName[path]<>"/summary.json",summary,"RawJSON"]]],stored];
audit=<|"Results"->records,"UnknownSeriesCount"->Length[Union[First/@pairs]],
 "RequiredBoundaryAmplitudeCoefficients"->pairs,"UnknownLaurentCoefficientCount"->Length[pairs],
 "BoundaryFeynmanContinuationIndependentlyChecked"->False|>;
save[audit,output<>"/matching_audit.wxf"];
Print["PASS singular matching: ",Length[records]," families, ",audit["UnknownSeriesCount"],
 " unknown series, ",Length[pairs]," Laurent coefficients."];
