(* Shared, fully instantiated mathematical definitions. Reading these
   records only selects and renumbers existing expressions; it performs
   no DE solve, expansion or coefficient generation. *)
Begin["FeynFacetSolution`Private`"];

(* Association holds its values. Evaluate index substitutions before
   rebuilding each container so no local array lookups survive in the file.
   Three integer-index rules avoid a linear search through huge pattern
   dispatch tables on every scalar reference. *)
Clear[replaceFiniteExpressionReferences];
replaceFiniteExpressionReferences[value_Association,rules_] :=
 Association@KeyValueMap[#1->replaceFiniteExpressionReferences[#2,rules]&,value];
replaceFiniteExpressionReferences[value_List,rules_] :=
 replaceFiniteExpressionReferences[#,rules]&/@value;
replaceFiniteExpressionReferences[value_Rule,rules_] :=
 First[value]->replaceFiniteExpressionReferences[Last[value],rules];
replaceFiniteExpressionReferences[value_,rules_] := value/.rules;

Clear[FeynFacetSolution`PruneFiniteSolutionDefinitions,
 FeynFacetSolution`ResolveSharedBoundaryDefinitions];
Options[FeynFacetSolution`PruneFiniteSolutionDefinitions]={"Verbose"->False};
FeynFacetSolution`PruneFiniteSolutionDefinitions[data_Association,expressions_,OptionsPattern[]] := Catch@Module[
 {algebraDefinitions=Lookup[data,"AlgebraicDefinitions",{}],f=Lookup[data,"IntegralDefinitions",{}],
  k=Lookup[data,"KernelDefinitions",{}],aa,ff,kk,ar,fr,kr,mark,rewrite,
  sa,sf,sk,am,fm,km,expr=expressions,na,nf,nk,pa,pf,pk,ha=1,hf=1,hk=1,ta=0,tf=0,tk=0,current,progress},
 progress[x_]:=If[TrueQ[OptionValue["Verbose"]],Print[x]];
 {na,nf,nk}=Length/@{algebraDefinitions,f,k};
 aa=ConstantArray[0,na];ff=ConstantArray[0,nf];kk=ConstantArray[0,nk];
 pa=ConstantArray[0,na];pf=ConstantArray[0,nf];pk=ConstantArray[0,nk];
 mark[value_] := Module[{refs},
  refs=Cases[value,FeynFacetSolution`a[i_]:>i,{0,Infinity}];
  If[!AllTrue[refs,IntegerQ[#]&&1<=#<=na&],Throw[Failure["InvalidAlgebraicDefinitionReference",<||>]]];
  Do[If[aa[[ref]]===0,aa[[ref]]=1;pa[[++ta]]=ref],{ref,refs}];
  refs=Cases[value,FeynFacetSolution`F[i_,_]:>i,{0,Infinity}];
  If[!AllTrue[refs,IntegerQ[#]&&1<=#<=nf&],Throw[Failure["InvalidIntegralDefinitionReference",<||>]]];
  Do[If[ff[[ref]]===0,ff[[ref]]=1;pf[[++tf]]=ref],{ref,refs}];
  refs=Cases[value,FeynFacetSolution`K[i_,_]:>i,{0,Infinity}];
  If[!AllTrue[refs,IntegerQ[#]&&1<=#<=nk&],Throw[Failure["InvalidKernelDefinitionReference",<||>]]];
  Do[If[kk[[ref]]===0,kk[[ref]]=1;pk[[++tk]]=ref],{ref,refs}]];
 mark[expr];
 progress["Algebraic dependency traversal."];
 While[ha<=ta,current=pa[[ha++]];If[Mod[ha,25000]===0,progress[{"Algebraic",ha,ta}]];mark[algebraDefinitions[[current]]]];
 progress["Integral dependency traversal."];
 While[hf<=tf,current=pf[[hf++]];
  If[!FreeQ[f[[current,"Integrand"]],_FeynFacetSolution`a],
   Throw[Failure["IntegralDependsOnAlgebraicDefinition",<||>]]];
  mark[f[[current,"Integrand"]]]];
 progress["Scalar kernel dependency traversal."];
 While[hk<=tk,current=pk[[hk++]];If[Mod[hk,100000]===0,progress[{"Kernel",hk,tk}]];
  If[!FreeQ[k[[current,"Expression"]],_FeynFacetSolution`a|_FeynFacetSolution`F],
   Throw[Failure["KernelDependsOnIntegralDefinition",<||>]]];
  mark[k[[current,"Expression"]]]];
 progress["Dependency traversal complete."];
 sa=Flatten@Position[aa,1];sf=Flatten@Position[ff,1];sk=Flatten@Position[kk,1];
 am=ConstantArray[0,na];fm=ConstantArray[0,nf];km=ConstantArray[0,nk];
 If[sa=!={},am[[sa]]=Range[Length[sa]]];
 If[sf=!={},fm[[sf]]=Range[Length[sf]]];
 If[sk=!={},km[[sk]]=Range[Length[sk]]];
 progress[{"Renumbering finite definitions",Length[sa],Length[sf],Length[sk]}];
 ar={
  FeynFacetSolution`a[i_Integer]:>With[{j=am[[i]]},FeynFacetSolution`a[j]],
  FeynFacetSolution`F[i_Integer,u_]:>With[{j=fm[[i]]},FeynFacetSolution`F[j,u]],
  FeynFacetSolution`K[i_Integer,u_]:>With[{j=km[[i]]},FeynFacetSolution`K[j,u]]};
 rewrite[value_] := replaceFiniteExpressionReferences[value,ar];
 <|"Expressions"->rewrite[expr],
  "AlgebraicDefinitions"->(rewrite/@algebraDefinitions[[sa]]),
  "IntegralDefinitions"->MapIndexed[Join[rewrite[#1],<|"Index"->First[#2]|>]&,f[[sf]]],
  "KernelDefinitions"->MapIndexed[Join[rewrite[#1],<|"Index"->First[#2]|>]&,k[[sk]]],
  "SourceDefinitionIndices"-><|"Algebraic"->sa,"Integral"->sf,"Kernel"->sk|>|>
];

(* Source scopes can carry global branch/path information. Conservatively
   keep different scopes distinct, even when their defining bodies coincide.
   Unscoped entries in a scoped record receive unique context identifiers. *)
finiteDefinitionSemanticContexts[data_]:=Module[{kinds={"Kernel","Integral","Algebraic"},counts,contexts,scopes,endpointScopes,lo,hi,range,kind},
 counts=AssociationThread[kinds,Length /@ Lookup[data,(#<>"Definitions"& /@ kinds),{}]];
 If[KeyExistsQ[data,"DefinitionSemanticContexts"],contexts=data["DefinitionSemanticContexts"],
  scopes=Lookup[data,"DefinitionScopes",{}];
  contexts=Association@Table[kind->If[scopes==={},ConstantArray[0,counts[kind]],-Range[counts[kind]]],{kind,kinds}];
  Do[Do[
    If[KeyExistsQ[scopes[[i]],kind<>"Range"],{lo,hi}=scopes[[i]][kind<>"Range"],
     If[KeyExistsQ[scopes[[i]],kind<>"Offset"],lo=scopes[[i]][kind<>"Offset"]+1;
      hi=SelectFirst[Drop[scopes,i],KeyExistsQ[#,kind<>"Offset"]&,<|kind<>"Offset"->counts[kind]|>][kind<>"Offset"],Continue[]]];
    If[!IntegerQ[lo]||!IntegerQ[hi]||lo<1||hi>counts[kind],Throw[Failure["FiniteDefinitionScopeRangeInvalid",<||>]]];
    If[hi>=lo,range=Range[lo,hi];contexts[kind]=ReplacePart[contexts[kind],Thread[range->ConstantArray[i,Length[range]]]]],
   {kind,kinds}],{i,Length[scopes]}]];
 If[!AssociationQ[contexts]||!AllTrue[kinds,ListQ[Lookup[contexts,#,None]]&&Length[contexts[#]]===counts[#]&]||!FreeQ[contexts,_Real],
  Throw[Failure["ExactFiniteDefinitionSemanticContextsRequired",<||>]]];contexts
];
finiteReferenceKeysAbsentQ[x_]:=FreeQ[Cases[x,a_Association:>Keys[a],{0,Infinity}],
 _FeynFacetSolution`a|_FeynFacetSolution`F|_FeynFacetSolution`K];

(* Exact common-definition elimination in the dependency order K, F, a.
   Parameters, endpoints, integrands, kernel kind and every other defining
   field are retained in the comparison key. Bound variables are not renamed. *)
FeynFacetSolution`CompactFiniteSolutionDefinitions::usage="CompactFiniteSolutionDefinitions[data,expressions] eliminates exactly repeated instantiated K/F/a definitions in topological order and optionally prunes unreachable definitions. It preserves bound-variable names and all defining fields except their integer Index. No integration, DE solve or epsilon expansion is performed.";
Options[FeynFacetSolution`CompactFiniteSolutionDefinitions]={"Prune"->True,"Verbose"->False};
FeynFacetSolution`CompactFiniteSolutionDefinitions[data_Association,expressions_,OptionsPattern[]]:=Catch[Module[
 {oldK=Lookup[data,"KernelDefinitions",{}],oldF=Lookup[data,"IntegralDefinitions",{}],oldA=Lookup[data,"AlgebraicDefinitions",{}],
  nk,nf,na,km,fm,am,seen,newK,newF,newA,key,index,count,rewritten,result,pruned,verbose=OptionValue["Verbose"],
  rewrite,reference,kind,values,records,tag,progress,compactCounts,contexts,context,comparisonKey,newContexts=<||>,finalContexts},
 contexts=finiteDefinitionSemanticContexts[data];
 If[!finiteReferenceKeysAbsentQ[expressions]||!FreeQ[expressions,_Real],Throw[Failure["ExactFiniteExpressionsWithLiteralKeysRequired",<||>]]];
 {nk,nf,na}=Length /@ {oldK,oldF,oldA};km=ConstantArray[0,nk];fm=ConstantArray[0,nf];am=ConstantArray[0,na];
 progress[x_]:=If[TrueQ[verbose],Print[x]];
 reference[map_,i_,type_]:=If[IntegerQ[i]&&1<=i<=Length[map]&&map[[i]]>0,map[[i]],
  Throw[Failure["InvalidOrForwardFiniteDefinitionReference",<|"Type"->type,"Index"->i|>]]];
 rewrite[x_]:=replaceFiniteExpressionReferences[x,{
  FeynFacetSolution`K[i_,u_]:>With[{j=reference[km,i,"Kernel"]},FeynFacetSolution`K[j,u]],
  FeynFacetSolution`F[i_,u_]:>With[{j=reference[fm,i,"Integral"]},FeynFacetSolution`F[j,u]],
  FeynFacetSolution`a[i_]:>With[{j=reference[am,i,"Algebraic"]},FeynFacetSolution`a[j]]}];
 Do[
  records=Switch[kind,"Kernel",oldK,"Integral",oldF,"Algebraic",oldA];seen=<||>;count=0;tag=Unique["definitions"];
  values=Reap[Do[
   If[kind==="Algebraic",key=records[[i]],
    If[!AssociationQ[records[[i]]]||Lookup[records[[i]],"Index",None]=!=i,
     Throw[Failure["ConsecutiveFiniteDefinitionIndicesRequired",<|"Type"->kind,"Index"->i|>]]];
    key=KeyDrop[records[[i]],"Index"]];
   If[(kind==="Kernel"&&!FreeQ[key,_FeynFacetSolution`F|_FeynFacetSolution`a])||
      (kind==="Integral"&&!FreeQ[key,_FeynFacetSolution`a]),Throw[Failure["FiniteDefinitionLayerOrderViolation",<|"Type"->kind|>]]];
   If[!FreeQ[key,_Real]||!finiteReferenceKeysAbsentQ[key],Throw[Failure["ExactDefinitionWithLiteralKeysRequired",<|"Type"->kind,"Index"->i|>]]];
   key=rewrite[key];context=contexts[kind][[i]];comparisonKey={context,key};index=Lookup[seen,Key[comparisonKey],0];
   If[index===0,index=++count;AssociateTo[seen,comparisonKey->index];Sow[{If[kind==="Algebraic",key,Join[<|"Index"->index|>,key]],context},tag]];
   Switch[kind,"Kernel",km[[i]]=index,"Integral",fm[[i]]=index,"Algebraic",am[[i]]=index];
   If[Mod[i,50000]===0,progress[{kind,i,Length[records],"Distinct",count}]],{i,Length[records]}],tag][[2]];
  values=If[values==={},{},First[values]];AssociateTo[newContexts,kind->If[values==={},{},values[[All,2]]]];values=If[values==={},{},values[[All,1]]];
  Switch[kind,"Kernel",newK=values,"Integral",newF=values,"Algebraic",newA=values];
  progress[{kind,"Completed",Length[records],count}],{kind,{"Kernel","Integral","Algebraic"}}];
 rewritten=rewrite[expressions];compactCounts=Length /@ {newK,newF,newA};
 result=<|"Expressions"->rewritten,"KernelDefinitions"->newK,"IntegralDefinitions"->newF,"AlgebraicDefinitions"->newA|>;
 If[TrueQ[OptionValue["Prune"]],
  progress["Pruning unreachable finite definitions."];pruned=FeynFacetSolution`PruneFiniteSolutionDefinitions[result,rewritten,"Verbose"->verbose];
  If[FailureQ[pruned],Throw[pruned]];result=KeyDrop[pruned,"SourceDefinitionIndices"]];
 finalContexts=If[TrueQ[OptionValue["Prune"]],Association@Table[kind->newContexts[kind][[pruned["SourceDefinitionIndices"][kind]]],{kind,{"Kernel","Integral","Algebraic"}}],newContexts];
 Join[result,<|"DefinitionSemanticContexts"->finalContexts,"Compaction"-><|"Method"->"Exact topological common-definition elimination, retaining all semantic fields and bound-variable names",
  "SemanticContextPolicy"->"Distinct source scopes never merge; every defining field and exact context is retained; reference-bearing association keys are rejected",
  "SourceCounts"-><|"Kernel"->nk,"Integral"->nf,"Algebraic"->na|>,
  "DistinctCountsBeforePruning"->AssociationThread[{"Kernel","Integral","Algebraic"},compactCounts],
  "RetainedCounts"->AssociationThread[{"Kernel","Integral","Algebraic"},Length /@ Lookup[result,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}]],
  "OriginalToDistinctIndices"-><|"Kernel"->km,"Integral"->fm,"Algebraic"->am|>,
  "RetainedDistinctIndices"->If[TrueQ[OptionValue["Prune"]],pruned["SourceDefinitionIndices"],<|"Kernel"->Range[Length[newK]],"Integral"->Range[Length[newF]],"Algebraic"->Range[Length[newA]]|>]|>|>]
]];

FeynFacetSolution`VerifyFiniteSolutionCompaction::usage="VerifyFiniteSolutionCompaction[source,expressions,compact] independently composes the old-to-retained index maps and checks every retained source definition and the complete output exactly. It performs no numerical integral evaluation.";
FeynFacetSolution`VerifyFiniteSolutionCompaction[source_Association,expressions_,compact_Association]:=Catch[Module[
 {report=compact["Compaction"],maps=<||>,oldMaps,retained,back,map,oldRecords,newRecords,key,actual,j,
  rewrite,lookup,counts=<||>,kinds={"Kernel","Integral","Algebraic"},field,sourceIndex,contexts=finiteDefinitionSemanticContexts[source]},
 lookup[kind_,index_]:=If[IntegerQ[index]&&1<=index<=Length[maps[kind]]&&maps[kind][[index]]>0,maps[kind][[index]],
  Throw[Failure["CompactionLostRequiredDefinition",<|"Type"->kind,"Index"->index|>]]];
 Do[
  oldMaps=report["OriginalToDistinctIndices"][kind];retained=report["RetainedDistinctIndices"][kind];
  back=ConstantArray[0,report["DistinctCountsBeforePruning"][kind]];
  If[retained=!={},back[[retained]]=Range[Length[retained]]];
  map=If[oldMaps==={},{},back[[oldMaps]]];AssociateTo[maps,kind->map],{kind,kinds}];
 rewrite[x_]:=replaceFiniteExpressionReferences[x,{
  FeynFacetSolution`K[i_,u_]:>With[{q=lookup["Kernel",i]},FeynFacetSolution`K[q,u]],
  FeynFacetSolution`F[i_,u_]:>With[{q=lookup["Integral",i]},FeynFacetSolution`F[q,u]],
  FeynFacetSolution`a[i_]:>With[{q=lookup["Algebraic",i]},FeynFacetSolution`a[q]]}];
 If[rewrite[expressions]=!=compact["Expressions"],Throw[Failure["CompactedOutputExpressionChanged",<||>]]];
 Do[field=kind<>"Definitions";oldRecords=Lookup[source,field,{}];newRecords=Lookup[compact,field,{}];
  If[Length[oldRecords]=!=Length[maps[kind]],Throw[Failure["CompactionSourceCountsChanged",<||>]]];
  sourceIndex=Flatten[Position[maps[kind],_Integer?Positive]];
  Do[j=maps[kind][[i]];key=oldRecords[[i]];actual=newRecords[[j]];
   If[contexts[kind][[i]]=!=compact["DefinitionSemanticContexts"][kind][[j]],Throw[Failure["CompactedDefinitionSemanticContextChanged",<|"Type"->kind,"SourceIndex"->i|>]]];
   If[kind=!="Algebraic",key=KeyDrop[key,"Index"];actual=KeyDrop[actual,"Index"]];
   If[rewrite[key]=!=actual,Throw[Failure["CompactedDefinitionChanged",<|"Type"->kind,"SourceIndex"->i,"RetainedIndex"->j|>]]],{i,sourceIndex}];
  AssociateTo[counts,kind->Length[sourceIndex]],{kind,kinds}];
 <|"Status"->"Passed","Method"->"Composed index-map equality for the entire output and every retained source definition; all defining fields compared",
  "RetainedSourceDefinitionsChecked"->counts,"OriginalToRetainedIndices"->maps|>
]];

FeynFacetSolution`ResolveSharedBoundaryDefinitions[record_Association,
 shared_Association] := Catch@Module[
 {requested,definitions,selected,pruned,result,ka,fa,aa,shift,replace,
  keys,requirements,constants,shiftRules,boundaryRules,source=Lookup[record,"SharedBoundaryDefinitionFile",None]},
 If[Lookup[shared,"DataType",None]=!="SharedBoundaryCoefficientDefinitions",
  Throw[Failure["SharedBoundaryCoefficientDefinitionsRequired",<||>]]];
 requested=DeleteDuplicates@Cases[record["MasterIntegralCoefficients"],
   FeynFacetSolution`B[i_Integer,q_Integer]:>{i,q},Infinity];
 definitions=shared["BoundaryCoefficientDefinitions"];
 If[!AllTrue[requested,KeyExistsQ[definitions,#]&],
  Throw[Failure["SharedBoundaryCoefficientMissing",
   <|"Keys"->Select[requested,!KeyExistsQ[definitions,#]&]|>]]];
 selected=Association@Table[key->definitions[[Key[key]]],{key,requested}];
 pruned=FeynFacetSolution`PruneFiniteSolutionDefinitions[shared,selected];
 If[FailureQ[pruned],Throw[pruned]];
 {ka,fa,aa}=Length/@Lookup[pruned,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}];
 shiftRules=With[{ao=aa,fo=fa,ko=ka},{
  FeynFacetSolution`a[i_Integer]:>FeynFacetSolution`a[i+ao],
  FeynFacetSolution`F[i_Integer,u_]:>FeynFacetSolution`F[i+fo,u],
  FeynFacetSolution`K[i_Integer,u_]:>FeynFacetSolution`K[i+ko,u]}];
 shift[value_] := replaceFiniteExpressionReferences[value,shiftRules];
 result=shift[KeyDrop[record,"SharedBoundaryDefinitionFile"]];
 boundaryRules=KeyValueMap[Function[{key,expression},
  Apply[FeynFacetSolution`B,key]->expression],pruned["Expressions"]];
 boundaryRules=Dispatch[boundaryRules];
 replace[value_] := value/.boundaryRules;
 result=Join[result,<|
  "KernelDefinitions"->Join[pruned["KernelDefinitions"],
    MapIndexed[Join[#1,<|"Index"->ka+First[#2]|>]&,result["KernelDefinitions"]]],
  "IntegralDefinitions"->Join[pruned["IntegralDefinitions"],
    MapIndexed[Join[#1,<|"Index"->fa+First[#2]|>]&,result["IntegralDefinitions"]]],
  "AlgebraicDefinitions"->Join[pruned["AlgebraicDefinitions"],result["AlgebraicDefinitions"]],
  "MasterIntegralCoefficients"->replace[result["MasterIntegralCoefficients"]],
  "SharedBoundaryDefinitionSource"->source,
  "SharedBoundaryDefinitionsResolved"->True|>];
 If[!FreeQ[result["MasterIntegralCoefficients"],_FeynFacetSolution`B],
  Throw[Failure["UnresolvedSharedBoundaryCoefficient",<||>]]];
 requirements=Sort@DeleteDuplicates@Cases[result["MasterIntegralCoefficients"],
  FeynFacetSolution`C[i_Integer,q_Integer]:>{i,q},Infinity];
 If[Lookup[result,"RequiredInitialConstantCoefficients",Automatic]=!=Automatic&&
   Sort[result["RequiredInitialConstantCoefficients"]]=!=requirements,
  Throw[Failure["SharedBoundaryCoefficientRequirementsMismatch",<|"Expected"->Lookup[result,"RequiredInitialConstantCoefficients",{}],"Found"->requirements|>]]];
 Join[result,<|"RequiredInitialConstantCoefficients"->requirements|>]
];

sharedBoundaryRead[record_,directory_] := Module[{path,shared,result,constructionPath},
 If[!AssociationQ[record]||!KeyExistsQ[record,"SharedBoundaryDefinitionFile"],Return[record]];
 path=record["SharedBoundaryDefinitionFile"];
 If[!StringQ[path],Return[Failure["SharedBoundaryDefinitionPathRequired",<||>]]];
 path=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{directory,path}]]];
 If[!FileExistsQ[path],Return[Failure["SharedBoundaryDefinitionFileMissing",<|"Path"->path|>]]];
 shared=Import[path,"WXF"];
 result=FeynFacetSolution`ResolveSharedBoundaryDefinitions[record,shared];
 If[FailureQ[result],Return[result]];
 If[StringQ[Lookup[shared,"NumericalConstructionFile",None]],
  constructionPath=ExpandFileName[FileNameJoin[{DirectoryName[path],shared["NumericalConstructionFile"]}]];
  result=Join[result,<|"SingularBoundaryNumericalInput"-><|
   "SharedBoundaryDefinitionFile"->path,"ConstructionInputFile"->constructionPath,
   "CompactSolutionFile"->ExpandFileName[FileNameJoin[{directory,"solution.wxf"}]]|>|>]];
 result
];
End[];
