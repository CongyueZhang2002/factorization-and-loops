(* One sparse user-system writer for Kira's exact and sampled routes. *)
BeginPackage["FeynFacet`"];
SampleCutIBPEquations::usage="SampleCutIBPEquations[rows,targets,families,request] solves exact generated equations at declared generic finite-field points using Kira. It reports target remainders outside preferred integrals. Samples guide equation selection; they are never returned as exact rational reductions.";
NormalizeIntegralEquationScale::usage="NormalizeIntegralEquationScale[rows,weights,scale] verifies exact monomial homogeneity of every coefficient row under I_i=scale^weight_i J_i. It removes one common monomial per row, producing a scale-independent rational system. This is an exact change of unknowns, not an assumed numerical specialization or physical integral scaling law.";
RestoreIntegralEquationScale::usage="RestoreIntegralEquationScale[rules,normalization] restores exact original-integral reduction rules from the scale-independent unknowns in a verified NormalizeIntegralEquationScale record.";
Begin["`Private`"];
(* Stream one sorted equation at a time. Do not materialize both a list
   of all row strings and a second concatenated copy of the native input. *)
cutKiraWriteEquationRows[equations_List,idMap_Association,coefficientText_,file_String]:=Module[
 {stream=None,temporary=file<>".tmp",completed=False,lineBreak=FromCharacterCode[10],ordered,text},
 ordered=SortBy[equations,{Max[idMap/@Keys[#]]&,Length}];
 Internal`WithLocalSettings[
  stream=OpenWrite[temporary,CharacterEncoding->"UTF8"],
  If[Head[stream]=!=OutputStream,cutFamilyFail["KiraEquationStreamOpenFailed"]];
  If[ordered==={},WriteString[stream,lineBreak<>lineBreak]];
  Scan[Function[row,
   text=StringRiffle[KeyValueMap[
    Function[{integral,coefficient},"FeynFacetIBP["<>ToString[idMap[integral]]<>"]*("<>
     coefficientText[coefficient]<>")"],row],lineBreak]<>lineBreak<>lineBreak;
   If[!TrueQ[Check[WriteString[stream,text];True,False]],cutFamilyFail["KiraEquationStreamWriteFailed"]]
  ],ordered];
  Close[stream];stream=None;
  If[RenameFile[temporary,file,OverwriteTarget->True]===$Failed,cutFamilyFail["KiraEquationStreamInstallFailed"]];
  completed=True,
  If[Head[stream]===OutputStream,Close[stream]];
  If[!completed&&FileExistsQ[temporary],DeleteFile[temporary]]
 ];
 file
];

cutKiraPrepareEquationSystem[records_,targets_,equations_,directory_,preferred_:{}]:=Module[
 {names,familyOrder,unknowns,idMap,variables,aliases,variableRules,coefficientValues,preferredSet,
  coefficientText,rows,project,head=Global`FeynFacetIBP,textCache=<||>,textBytes=0},
 names=#[["Topology",1]]&/@records;
 familyOrder=AssociationThread[names,Range[Length[names]]];
 If[!ListQ[equations]||!AllTrue[equations,AssociationQ]||
  !DuplicateFreeQ[names]||validateCutGLIs[Join[targets,preferred,Keys/@equations],records]=!=True,
  cutFamilyFail["TypedIntegralEquationSystemRequired"]];
 preferredSet=AssociationThread[preferred,ConstantArray[True,Length[preferred]]];
 unknowns=SortBy[DeleteDuplicates[Join[targets,preferred,Flatten[Keys/@equations]]],
  Function[integral,{If[KeyExistsQ[preferredSet,integral],0,1],
   Count[integral[[2]],_?Positive],Total[Abs[integral[[2]]]],
   Total[Select[integral[[2]],Positive]],familyOrder[integral[[1]]],integral[[2]]}]];
 If[Length[unknowns]>=2^31,cutFamilyFail["SingleIndexKiraIdentifierCapacityExceeded"]];
 idMap=AssociationThread[unknowns,Range[Length[unknowns]]];
 coefficientValues=DeleteDuplicates[Flatten[Values/@equations]];
 (* Collect each distinct coefficient's small symbol set first. Traversing
    every repeated rational tree into one giant symbol list can exceed memory
    even though the equation system has only two kinematic parameters. *)
 variables=SortBy[Union@@(DeleteDuplicates[Cases[#,_Symbol,{0,Infinity}]]&/@coefficientValues),
  ToString[#,InputForm]&];
 If[!FreeQ[coefficientValues,_Complex|_Real]||!AllTrue[coefficientValues,exactIntegralCoefficientQ],
  cutFamilyFail["RationalIBPCoefficientsRequired"]];
 Clear[coefficientValues];
 aliases=Table[Symbol["Global`fcz"<>ToString[i]],{i,Length[variables]}];
 If[!AllTrue[aliases,Function[a,With[{symbol=a},OwnValues[symbol]==={}&&DownValues[symbol]==={}]]],
  cutFamilyFail["KiraCoefficientAliasAlreadyDefined"]];
 variableRules=Thread[variables->aliases];
 coefficientText[value_]:=If[KeyExistsQ[textCache,value],textCache[value],Module[{text},
  text=StringDelete[ToString[value/.variableRules,InputForm,PageWidth->Infinity]," "];
  If[textBytes+ByteCount[value]+StringLength[text]<4*1024^2,
   AssociateTo[textCache,value->text];textBytes+=ByteCount[value]+StringLength[text]];
  text]];
 cutKiraWriteEquationRows[equations,idMap,coefficientText,directory<>"/equations.kira"];
 Export[directory<>"/targets",StringRiffle[("FeynFacetIBP["<>ToString[idMap[#]]<>"]"&/@targets),"\n"]<>"\n","String"];
 project=<|"Directory"->directory,"Runtime"->ibpRuntime[],"Manifest"->{<|"Name"->head|>},
  "EquationSource"->"TypedIBP","IntegralIndex"->idMap,"IndexedIntegrals"->unknowns,
  "IdentifierHead"->head,"CoefficientDecodeRules"->Thread[aliases->variables],
  "CoefficientVariables"->variables,"CoefficientAliases"->aliases|>;
 FamilyArtifactWrite[KeyTake[project,{"IndexedIntegrals","IdentifierHead","CoefficientDecodeRules",
   "CoefficientVariables","CoefficientAliases"}],directory<>"/IntegralIdentifiers.wxf",Compression->Automatic];
 project
];
cutKiraEquationJob[mode_,pointFile_:"points",inputFile_:"equations.kira",targetFile_:"targets"]:=StringRiffle[Join[{
 "jobs:","  - reduce_user_defined_system:",
 "      input_system: {files: ["<>ToString[inputFile,InputForm]<>"], config: false}",
 "      select_integrals:","        select_mandatory_list:",
 "          - [FeynFacetIBP, "<>targetFile<>"]","      run_initiate: true"},
 If[mode==="Sample",{"      numerical_points: "<>pointFile},Join[
 If[mode==="FireFly",{"      run_firefly: true"},
  {"      run_triangular: true","      run_back_substitution: true"}],
 {"  - kira2math:","      target:","        - [FeynFacetIBP, "<>targetFile<>"]"}]]],"\n"]<>"\n";
SampleCutIBPEquations[equations_List,targets:{__FeynCalc`GLI},records:{__Association},
 request_Association]:=Catch[Catch[Module[
 {directory,preferred,points,prime,variables,text,values,project,process,files,raw,samples={},
  context,decode,rows,groups,sample,allRules,rules,declared,masterFile,masterIndices,
  expressions,remaining,remainderRows,rank,positions,matrix,result,seconds,denominators,denominatorValues,selected,frontier,selectionHistory={},iteration=0,selectionLimit,totalSeconds=0,runDirectory,runIndex=1,
  requireClosed=Lookup[request,"RequireClosedExport",True],unresolved,
  computeRank=Lookup[request,"ComputeRemainderRank",True]},
 directory=Lookup[request,"WorkingDirectory",None];preferred=Lookup[request,"PreferredMasterIntegrals",{}];
 points=Lookup[request,"Points",{}];prime=Lookup[request,"Prime",2147483647];
 If[!StringQ[directory]||!ListQ[preferred]||!MatchQ[points,{{(_Rule)..}..}]||
  !MemberQ[{True,False},requireClosed]||!MemberQ[{True,False},computeRank]||!IntegerQ[prime]||!PrimeQ[prime]||prime>=2^63,
  cutFamilyFail["FiniteFieldIBPPointRequestRequired"]];
 directory=ExpandFileName[directory];
 cutKiraWorkspaceDefinition[directory,<|"Format"->"FeynFacet-SampledIBPInput",
  "Families"->(KeyTake[#,{"Topology","Cuts","MeasurePrefactor","TimeDirection","Assumptions"}]&/@records),
  "Targets"->targets,"PreferredMasterIntegrals"->preferred,"Equations"->equations,
  "Points"->points,"Prime"->prime|>];
 project=cutKiraPrepareEquationSystem[records,targets,equations,directory,preferred];
 variables=project["CoefficientVariables"];
 values=(variables/.#)&/@points;
 If[!AllTrue[Flatten[values],MatchQ[#,_Integer|_Rational]&&CoprimeQ[Denominator[#],prime]&],
  cutFamilyFail["CompleteNonsingularRationalIBPSamplingPointsRequired"]];
 denominators=DeleteDuplicates[Denominator[Together[#]]&/@DeleteDuplicates[Flatten[Values/@equations]]];
 denominatorValues=Flatten[(denominators/.#)&/@points];
 If[!AllTrue[denominatorValues,MatchQ[#,_Integer|_Rational]&&
    CoprimeQ[Numerator[#],prime]&&CoprimeQ[Denominator[#],prime]&],
  cutFamilyFail["SingularFiniteFieldSamplingPoint"]];
 If[!IntegerQ[Lookup[request,"Threads",1]]||!Between[Lookup[request,"Threads",1],{1,8}],
  cutFamilyFail["OneThroughEightKiraThreadsRequired"]];
 text="prime "<>ToString[prime]<>"\n"<>
  StringRiffle[SymbolName/@project["CoefficientAliases"]," "]<>"\n"<>
  StringRiffle[(StringRiffle[ToString[#,InputForm]&/@#," "]&/@values),"\n"]<>"\n\n";
 Export[directory<>"/points",text,"String"];
 Export[directory<>"/jobs.yaml",cutKiraEquationJob["Sample"],"String"];
 selected=targets;selectionLimit=Lookup[request,"MaximumSelectionClosureIterations",12];
 If[!IntegerQ[selectionLimit]||selectionLimit<1,cutFamilyFail["PositiveSelectionClosureIterationLimitRequired"]];
 While[True,
  While[DirectoryQ[directory<>"/Sampling"<>IntegerString[runIndex,10,3]],runIndex++];
  runDirectory=directory<>"/Sampling"<>IntegerString[runIndex,10,3];
  cutKiraWorkspaceDefinition[runDirectory,<|"Format"->"FeynFacet-KiraSamplingSelection",
   "EquationFile"->directory<>"/equations.kira","SelectedTargets"->selected,"Points"->points,"Prime"->prime|>];
  Export[runDirectory<>"/points",text,"String"];
  Export[runDirectory<>"/jobs.yaml",cutKiraEquationJob["Sample","points",directory<>"/equations.kira"],"String"];
  Export[runDirectory<>"/targets",StringRiffle[
   ("FeynFacetIBP["<>ToString[project["IntegralIndex"][#]]<>"]"&/@selected),"\n"]<>"\n","String"];
 {seconds,process}=AbsoluteTiming[RunProcess[
  {project["Runtime"]["KiraExecutable"],"--parallel="<>ToString[Lookup[request,"Threads",1]],"jobs.yaml"},
  All,ProcessDirectory->runDirectory,ProcessEnvironment-><|"FERMATPATH"->project["Runtime"]["FermatExecutable"]|>]];
 totalSeconds+=seconds;
 Export[runDirectory<>"/kira.log",Lookup[process,"StandardOutput",""]<>Lookup[process,"StandardError",""],"String"];
 If[Lookup[process,"ExitCode",1]=!=0,cutFamilyFail["FiniteFieldKiraRunFailed",<|"Directory"->runDirectory|>]];
 samples={};
 files=Sort[FileNames["points_"<>ToString[prime]<>"_*.m",runDirectory<>"/results/FeynFacetIBP"]];
 decode[expr_]:=expr/.{(HoldPattern[h_Symbol[i_Integer]]/;SymbolName[h]==="FeynFacetIBP"):>
  If[1<=i<=Length[project["IndexedIntegrals"]],project["IndexedIntegrals"][[i]],
   cutFamilyFail["SampledIntegralIdentifierOutOfRange"]]};
 Do[
  context="FeynFacetSampleRead"<>StringReplace[CreateUUID[],"-"->""]<>"`";
  raw=Block[{$Context=context,$ContextPath={"System`"}},Get[file]];
  If[!ListQ[raw]||First[raw]=!=prime||!AllTrue[Rest[raw],MatchQ[#,{_List,{(_Rule)...}}]&],
   cutFamilyFail["FiniteFieldKiraOutputFormatInvalid"]];
  Do[AppendTo[samples,<|"PointValues"->First[entry],"Rules"->decode[Last[entry]]|>],{entry,Rest[raw]}],
 {file,files}];
 masterFile=runDirectory<>"/results/FeynFacetIBP/masters";
 masterIndices=ToExpression/@Flatten[StringCases[Import[masterFile,"Lines"],
  RegularExpression["FeynFacetIBP\\[([0-9]+)\\]"]->"$1"]];
 If[!VectorQ[masterIndices,IntegerQ[#]&&1<=#<=Length[project["IndexedIntegrals"]]&],
  cutFamilyFail["SampledUnpivotedIntegralIdentifiersRequired"]];
 declared=project["IndexedIntegrals"][[masterIndices]];
 If[files==={},
  (* Kira writes no point file when every selected target is itself an
     unpivoted integral. This is identity coverage, not a zero remainder. *)
  If[!ContainsAll[declared,selected]||
    !StringContainsQ[Lookup[process,"StandardOutput",""],"No integrals to reduce"],
   cutFamilyFail["FiniteFieldKiraOutputRequired"]];
  samples=(<|"PointValues"->#,"Rules"->{}|>&/@values)
 ];
 groups=GatherBy[samples,#["PointValues"]&];

  frontier=DeleteDuplicates[Flatten[Map[Function[group,
    rules=DeleteDuplicates[Flatten[Lookup[group,"Rules"]]];
    Complement[DeleteDuplicates[Cases[targets/.Dispatch[rules],_FeynCalc`GLI,Infinity]],preferred,declared]
   ],groups],1]];
  If[frontier==={},Break[]];
  iteration++;
  If[iteration>selectionLimit||ContainsAll[selected,frontier],
   If[requireClosed,cutFamilyFail["SampledSelectionClosureIncomplete",<|"UnresolvedDependencies"->frontier,
     "SelectionHistory"->selectionHistory|>],Break[]]];
  AppendTo[selectionHistory,<|"Iteration"->iteration,"AddedDependencies"->frontier,
    "SamplingSeconds"->seconds,"WorkingDirectory"->runDirectory|>];
  selected=Union[selected,frontier];
  Print["Extending sampled Kira selection by ",Length[frontier]," exported pivot dependencies"];
 ];
 result=Table[
  allRules=Flatten[Lookup[group,"Rules"]];rules=DeleteDuplicates[allRules];
  If[!DuplicateFreeQ[First/@rules],cutFamilyFail["ConflictingFiniteFieldReductionRules"]];
  expressions=targets/.Dispatch[rules];
  remaining=Complement[DeleteDuplicates[Cases[expressions,_FeynCalc`GLI,Infinity]],preferred];
  unresolved=Complement[remaining,declared];
  If[requireClosed&&unresolved=!={},
   cutFamilyFail["UnresolvedSampledPivotDependencies",<|"Integrals"->Complement[remaining,declared]|>]];
  If[computeRank,
  positions=AssociationThread[remaining,Range[Length[remaining]]];
  remainderRows=Flatten[MapIndexed[Function[{expression,index},
   Map[Function[master,{First[index],positions[master]}->Mod[Coefficient[expression,master],prime]],
    Select[DeleteDuplicates[Cases[expression,_FeynCalc`GLI,{0,Infinity}]],KeyExistsQ[positions,#]&]]
   ],expressions],1];
  matrix=SparseArray[Select[remainderRows,Last[#]=!=0&],{Length[targets],Length[remaining]}];
  rank=If[remaining==={},0,MatrixRank[matrix,Modulus->prime]],
  rank=If[remaining==={},0,Missing["NotRequested"]]];
  If[computeRank&&!IntegerQ[rank],cutFamilyFail["FiniteFieldTargetRankRequired"]];
  <|"PointValues"->First[group]["PointValues"],"Rules"->rules,
    "NonpreferredIntegralColumns"->remaining,"TargetRemainderRank"->rank,
    "UnresolvedExportedDependencies"->unresolved,"ClosedOnDeclaredSampleMasters"->(unresolved==={}),
    "RemainderRankIsOnlyUpperBound"->(unresolved=!={}),
    "RemainderRankComputed"->IntegerQ[rank],
    "AllTargetsInPreferredSpanAtPoint"->(rank===0)|>,
 {group,groups}];
 <|"Format"->"FeynFacet-FiniteFieldIBPSamples","FormatVersion"->1,"Prime"->prime,
  "CoefficientVariables"->variables,"Samples"->result,"Targets"->targets,
  "PreferredMasterIntegrals"->preferred,"UnpivotedIntegralsAtGenerationPoint"->declared,
  "EquationCount"->Length[equations],"IntegralColumnCount"->Length[project["IndexedIntegrals"]],
  "Seconds"->totalSeconds,"WorkingDirectory"->directory,"SelectionClosure"->selectionHistory,"FinalSamplingDirectory"->runDirectory,
  "ExactReductionEstablished"->False,"MasterMinimalityEstablished"->False,
  "Scope"->"Finite-field diagnostics for equation selection; exact target identities remain required. With RequireClosedExport False, unresolved columns remain explicit independent formal remainders, so nonzero rank is only an upper bound and is never an irreducibility claim."|>
],"CutFamily"],$ibpFailure];
NormalizeIntegralEquationScale[rows_List,weights_Association,scale_Symbol]:=Catch[Module[
 {columns,output,coefficients,degrees,rowDegree,normalized,proofs,w,degree,unit,rowIndex=0},
 If[rows==={}||!AllTrue[rows,AssociationQ]||!AllTrue[Values[weights],IntegerQ],
  Throw[Failure["RationalIntegralRowsAndIntegerScaleWeightsRequired",<||>]]];
 columns=Union[Flatten[Keys/@rows]];
 If[!ContainsAll[Keys[weights],columns]||!AllTrue[columns,MatchQ[#,_FeynCalc`GLI]&],
  Throw[Failure["CompleteIntegralScaleWeightsRequired",<||>]]];
 (* Prove the integer degree structurally before using rational cancellation.
    Native rows usually contain a monomial scale times a large scale-free
    rational coefficient. Expanding it and memoizing every complete coefficient
    can dominate memory on million-row systems. *)
 degree[value_]:=Module[{parts,power},Which[
  value===scale,1,
  FreeQ[value,scale],0,
  Head[value]===Times,parts=degree/@(List@@value);
    If[VectorQ[parts,IntegerQ],Total[parts],Cancel[Together[scale D[value,scale]/value]]],
  Head[value]===Power&&IntegerQ[value[[2]]],power=degree[value[[1]]];
    If[IntegerQ[power],value[[2]]power,Cancel[Together[scale D[value,scale]/value]]],
  Head[value]===Plus,parts=DeleteDuplicates[degree/@(List@@value)];
    If[Length[parts]===1&&IntegerQ[First[parts]],First[parts],Cancel[Together[scale D[value,scale]/value]]],
  True,Cancel[Together[scale D[value,scale]/value]]]];
 (* After the exact common row degree is verified, evaluation at scale=1 is
    precisely its coefficient in the rescaled unknowns. No integration value
    is specialized here and no unproved scale dependence is discarded. *)
 unit[value_,power_]:=Module[{result},
  result=Quiet[value/.scale->1,{Power::infy,Infinity::indet}];
  If[!FreeQ[result,Indeterminate|_DirectedInfinity],
   result=Cancel[Together[value]]/.scale->1];
  If[!FreeQ[result,Indeterminate|_DirectedInfinity],
   Throw[Failure["FiniteRationalScaleUnitRequired",<||>]]];
  result];
 proofs=ConstantArray[0,Length[rows]];
 output=Map[Function[row,
  rowIndex++;
  coefficients=Normal[Select[row,#=!=0&]];
  If[coefficients==={},Return[<||>,Function]];
  degrees=Map[Function[term,
   w=weights[First[term]];
   normalized=degree[Last[term]];
   If[!IntegerQ[normalized],Throw[Failure["NonmonomialEquationScaleDependence",<|"Term"->term|>]]];
   w+normalized],coefficients];
  rowDegree=First[degrees];
  If[!AllTrue[degrees,#===rowDegree&],
   Throw[Failure["IntegralEquationScaleWeightsNotHomogeneous",<|"Degrees"->degrees|>]]];
  normalized=Association@Map[Function[term,First[term]->
   unit[Last[term],weights[First[term]]-rowDegree]],coefficients];
  If[!FreeQ[Values[normalized],scale],
   Throw[Failure["EquationScaleRemovalNotExact",<||>]]];
  proofs[[rowIndex]]=rowDegree;normalized],rows];
 <|"Format"->"FeynFacet-HomogeneousIntegralEquationSystem","Rows"->output,
  "Scale"->scale,"IntegralWeights"->weights,"OriginalRowScaleDegrees"->proofs,
  "ExactChangeOfUnknownsEstablished"->True,
  "Convention"->"I_i=scale^weight_i J_i. Each original equation is multiplied by the inverse of its recorded common scale monomial. No physical scaling law of I_i is assumed."|>
]];
RestoreIntegralEquationScale[rules_List,normalization_Association]:=Catch[Module[
 {scale,weights,rhs,masters,restored,parsed},
 If[Lookup[normalization,"Format",None]=!="FeynFacet-HomogeneousIntegralEquationSystem"||
  !TrueQ[Lookup[normalization,"ExactChangeOfUnknownsEstablished",False]]||
  !MatchQ[rules,{(_Rule)...}],
  Throw[Failure["VerifiedIntegralScaleNormalizationRequired",<||>]]];
 scale=normalization["Scale"];weights=normalization["IntegralWeights"];
 Map[Function[rule,
  rhs=Last[rule];parsed=linearIntegralSum[rhs];
  If[!linearIntegralSumQ[parsed]||Cancel[Together[parsed["Remainder"]]]=!=0||!FreeQ[rhs,scale],
   Throw[Failure["LinearScaleIndependentIntegralRuleRequired",<|"Rule"->rule|>]]];
  masters=Keys[parsed["Terms"]];
  If[!AllTrue[Prepend[masters,First[rule]],KeyExistsQ[weights,#]&],
   Throw[Failure["DeclaredScaleWeightsForEveryIntegralRequired",<|"Integral"->First[rule]|>]]];
  restored=Total[KeyValueMap[#2 scale^(weights[First[rule]]-weights[#1])#1&,parsed["Terms"]]];
  First[rule]->restored],rules]
]];
End[];EndPackage[];
