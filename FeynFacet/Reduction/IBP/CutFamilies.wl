(* Typed cut IBPs supply equations; Kira supplies the sparse linear solver.
   No topology configuration, native zero-sector decision or unaudited
   symmetry identification enters this equation source. *)
BeginPackage["FeynFacet`"];
GenerateCutIBPEquations::usage="GenerateCutIBPEquations[family,seeds] constructs the L(L+E) total-derivative IBP equations per seed, using the complete inverse-denominator basis and the jointly continued forward-cut convention. Only mandatory-cut pinches are set to zero.";
Begin["`Private`"];
cutIBPOperators[family_Association]:=Module[
 {top=family["Topology"],loops,external,basis,coordinates,variables,polynomials,kin,
  scalarVelocity,changes,coefficients},
 loops=top[[3]];external=top[[4]];
 basis=family["LoopScalarProducts"];variables=family["DenominatorVariables"];
 coordinates=Table[Unique["ibpScalar$"],{Length[basis]}];kin=FeynCalc`FCI[top[[5]]];
 polynomials=family["InversePropagators"]/.Thread[basis->coordinates];
 Flatten[Table[
  scalarVelocity=Map[Function[pair,With[{a=pair[[1,1]],b=pair[[2,1]]},
   (If[a===ell,FeynCalc`FCI[FeynCalc`SPD[vector,b]],0]+
    If[b===ell,FeynCalc`FCI[FeynCalc`SPD[vector,a]],0])/.kin]],basis];
  changes=Expand[(Table[
    Sum[Coefficient[poly,coordinates[[j]]]scalarVelocity[[j]],{j,Length[basis]}],
    {poly,polynomials}])/.family["ScalarProductRules"]];
  coefficients=Table[Prepend[Table[Coefficient[change,var],{var,variables}],
    change/.Thread[variables->0]],{change,changes}];
  <|"LoopMomentum"->ell,"Vector"->vector,"Divergence"->If[ell===vector,D,0],
    "DenominatorDerivatives"->Map[Factor,coefficients,{2}]|>,
 {ell,loops},{vector,Join[loops,external]}],1]
];

GenerateCutIBPEquations[family_Association,seeds:{__FeynCalc`GLI}]:=Catch[Module[
 {top,loops,external,basis,coordinates,variables,polynomials,kin,cuts,operators,scalarVelocity,
  changes,coefficients,rows={},terms,indices,raised,add,row,rowTag=Unique["ibpEquation$"]},
 If[!MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-LoopIntegralFamily"},Lookup[family,"Format",None]],cutFamilyFail["IntegralFamilyRequired"]];
 top=family["Topology"];loops=top[[3]];external=top[[4]];cuts=family["CutIndices"];
 If[!AllTrue[seeds,#[[1]]===top[[1]]&&Length[#[[2]]]===Length[top[[2]]]&&
   VectorQ[#[[2]],IntegerQ]&&AllTrue[#[[2,cuts]],#>0&]&],cutFamilyFail["ValidUnpinchedIBPSeedsRequired"]];
 operators=cutIBPOperators[family];
 add[powers_,coefficient_]:=If[coefficient=!=0&&AllTrue[powers[[cuts]],#>0&],
  AppendTo[terms,FeynCalc`GLI[top[[1]],powers]->coefficient]];
 rows=Flatten[Last[Reap[Do[
  indices=seed[[2]];
  Do[terms={};add[indices,operator["Divergence"]];
   Do[If[indices[[i]]===0,Continue[]];
    raised=ReplacePart[indices,i->indices[[i]]+1];
    add[raised,-indices[[i]]operator["DenominatorDerivatives"][[i,1]]];
    Do[add[ReplacePart[raised,j->raised[[j]]-1],
      -indices[[i]]operator["DenominatorDerivatives"][[i,j+1]]],{j,Length[indices]}],
   {i,Length[indices]}];
   If[terms=!={},
    row=Select[Map[Factor,GroupBy[terms,First->Last,Total]],#=!=0&];
    If[row=!=<||>,Sow[row,rowTag]]],
  {operator,operators}],
 {seed,seeds}],rowTag]],1];
 <|"Format"->"FeynFacet-IBPEquations","Rows"->DeleteDuplicates[rows],
  "Seeds"->seeds,"OperatorCount"->Length[operators],"EquationSource"->"IntegrationByParts",
  "NativeSymmetriesUsed"->False,"NativeZeroSectorsUsed"->False|>
],"CutFamily"];

cutSeedCompositions[0,0]:={{}};
cutSeedCompositions[n_Integer?Positive,0]:={};
cutSeedCompositions[n_Integer?NonNegative,1]:={{n}};
cutSeedCompositions[n_Integer?NonNegative,k_Integer/;k>1]:=
 cutSeedCompositions[n,k]=Flatten[Table[Prepend[#,j]&/@cutSeedCompositions[n-j,k-1],{j,0,n}],1];
cutSeedCompositionsUpTo[n_Integer?NonNegative,k_Integer?NonNegative]:=
 Flatten[Table[cutSeedCompositions[j,k],{j,0,n}],1];
cutIBPSeeds[family_,targets_,extension_]:=Module[
 {count,cuts,positive,activeSets,rmax,smax,result={},positions,other,dots,numerators,indices,seedTag=Unique["ibpSeed$"]},
 count=Length[family["Topology"][[2]]];cuts=family["CutIndices"];
 positive[n_]:=Total[Select[n,Positive]];
 rmax=Max[positive[#[[2]]]&/@targets]+First[extension];
 smax=Max[-Total[Select[#[[2]],Negative]]&/@targets]+Last[extension];
 activeSets=DeleteDuplicates[Flatten[
  Subsets[Complement[Flatten[Position[#[[2]],_?Positive]],cuts]]&/@targets,1]];
 result=Flatten[Last[Reap[Do[positions=Join[cuts,active];other=Complement[Range[count],positions];
  If[Length[positions]>rmax,Continue[]];
  dots=cutSeedCompositionsUpTo[rmax-Length[positions],Length[positions]];
  numerators=cutSeedCompositionsUpTo[smax,Length[other]];
  Do[indices=ConstantArray[0,count];indices[[positions]]=1+dot;indices[[other]]=-numerator;
   Sow[FeynCalc`GLI[family["Topology"][[1]],indices],seedTag],
   {dot,dots},{numerator,numerators}],
 {active,activeSets}],seedTag]],1];
 <|"Seeds"->DeleteDuplicates[result],"PositivePowerLimit"->rmax,"NumeratorDegreeLimit"->smax|>
];

(* Reevaluate exact mathematical entries after held topology substitutions.
   Saving/reading already does this; a literal 1*x must not invalidate a
   matching definition while a changed polynomial still must. *)
cutKiraDefinitionCanonical[definition_]:=Map[Identity,definition,{0,Infinity}];
cutKiraSelectWorkspace[directory_,definition_,allowNew_]:=Module[{candidate=directory,index=1,old},
 If[!MemberQ[{True,False},allowNew],cutFamilyFail["BooleanChangedInputWorkspacePolicyRequired"]];
 If[!TrueQ[allowNew],Return[directory]];
 While[DirectoryQ[candidate]&&FileNames[All,candidate]=!={},
  old=If[FileExistsQ[candidate<>"/InputDefinition.wl"],FamilyArtifactRead[candidate<>"/InputDefinition.wl"],None];
  If[AssociationQ[old]&&cutKiraDefinitionCanonical[old]===cutKiraDefinitionCanonical[definition],Return[candidate]];
  candidate=directory<>"/Generation"<>IntegerString[index,10,3];index++];
 If[candidate=!=directory,Print["Using a new Kira workspace for changed exact inputs: ",candidate]];
 candidate
];
cutKiraWorkspaceDefinition[directory_,rawDefinition_]:=Module[{file,old,definition=cutKiraDefinitionCanonical[rawDefinition]},
 file=FileNameJoin[{directory,"InputDefinition.wl"}];
 If[DirectoryQ[directory]&&FileNames[All,directory]=!={},
  old=If[FileExistsQ[file],FamilyArtifactRead[file],Missing["UnverifiedWorkspace"]];
  If[cutKiraDefinitionCanonical[old]=!=definition,cutFamilyFail["KiraWorkspaceDefinitionMismatch",<|"Directory"->directory|>]]];
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 If[FamilyArtifactWrite[definition,file]===$Failed,cutFamilyFail["KiraInputDefinitionWriteFailed"]]
];

(* Kira can leave nonselected pivots on an exported right-hand side.
   Add them to the solved selection; never relabel them as physical masters.
   The equation system is reused without regenerating or enlarging its seeds. *)
cutKiraCloseSelectedReduction[project_,initialRules_,targets_,initialDeclared_,records_,request_]:=Module[
 {rules=initialRules,declared=initialDeclared,closed,frontier,selected=targets,diagnostics={},
  iteration=0,limit=Lookup[request,"MaximumSelectionClosureIterations",12],directory,
  currentProject=project,selectionDefinition,encoded,inputFile,seconds,imported},
 closed=ibpCloseReductionRules[rules,targets];
 frontier=Complement[closed["Masters"],declared,SameTest->SameQ];
 inputFile=FileNameJoin[{project["Directory"],"equations.kira"}];
 While[frontier=!={},
  iteration++;If[iteration>limit,cutFamilyFail["KiraSelectionClosureIncomplete",
   <|"UnreducedDependencies"->frontier,"Iterations"->diagnostics|>]];
  selected=Union[selected,frontier];
  directory=FileNameJoin[{project["Directory"],"SelectionClosure"<>IntegerString[iteration,10,3]}];
  encoded=ibpEncodeProjectIntegrals[project,selected];
  selectionDefinition=<|"Format"->"FeynFacet-KiraSelectionInput",
   "OriginalInputDefinition"->FamilyArtifactRead[FileNameJoin[{project["Directory"],"InputDefinition.wl"}]],
   "SelectedIdentifiers"->encoded|>;
  cutKiraWorkspaceDefinition[directory,selectionDefinition];
  Export[FileNameJoin[{directory,"selected_integrals"}],
   StringRiffle[ibpKiraIntegralText/@encoded,"\n"]<>"\n","String"];
  Export[FileNameJoin[{directory,"jobs.yaml"}],StringRiffle[{
   "jobs:","  - reduce_user_defined_system:",
   "      input_system: {files: ["<>ToString[inputFile,InputForm]<>"], config: false}",
   "      select_integrals:","        select_mandatory_list:",
   "          - [FeynFacetIBP, selected_integrals]",
   "      run_initiate: true","      run_triangular: true","      run_back_substitution: true",
   "  - kira2math:","      target:","        - [FeynFacetIBP, selected_integrals]"},"\n"]<>"\n","String"];
  currentProject=Join[project,<|"Directory"->directory|>];
  Print["Extending the Kira selection by ",Length[frontier]," unresolved exported dependencies"];
  {seconds,imported}=AbsoluteTiming[
   ibpRunKira[currentProject,Lookup[request,"Threads",1]];
   ibpImportRuleTable[project["IdentifierHead"],FileNameJoin[{directory,"results","FeynFacetIBP","kira_selected_integrals.m"}]]];
  rules=ibpDecodeProjectIntegrals[project,imported];
  declared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[currentProject]];
  closed=ibpCloseReductionRules[rules,targets];
  AppendTo[diagnostics,<|"Iteration"->iteration,"AddedDependencies"->frontier,
   "SelectedIntegralCount"->Length[selected],"Seconds"->seconds,"Workspace"->directory|>];
  frontier=Complement[closed["Masters"],declared,SameTest->SameQ]];
 ibpValidateMasters[closed["Masters"],declared,records];
 Join[closed,<|"SelectionClosure"-><|"Status"->If[diagnostics==={},"AlreadyClosed","ClosedByExtendedSelection"],
  "Iterations"->diagnostics|>,"SolutionWorkspace"->currentProject["Directory"]|>]
];
KiraReduction[families:{__Association},targets:{__FeynCalc`GLI},request_Association]:=Catch[
 Catch[Module[
 {records,directory,extension,generated,seeds,equationRecord,equations,unknowns,names,familyOrder,idMap,idRules,
  variables,variableNames,variableRules,reverseVariables,coefficientText,coefficientValues,rows,text,project,
  imported,declared,closed,seconds,generationSeconds,definition,cachedIdentifiers,cachedResult,finish,head=Global`FeynFacetIBP,aliases},
 If[Lookup[request,"EquationSource","TypedIBP"]==="NativeDiagnostic",
  Return[kiraNativeCutFamilyReduction[families,targets,request]]];
 If[Lookup[request,"EquationSource","TypedIBP"]=!="TypedIBP",cutFamilyFail["TypedIBPEquationSourceRequired"]];
 records=FeynFacet`CreateCutIntegralFamily/@families;
 If[!AllTrue[records,AssociationQ],cutFamilyFail["ValidatedCutIntegralFamiliesRequired"]];
 names=First[#["Topology"]]&/@records;
 If[!DuplicateFreeQ[names]||!ContainsAll[names,First/@targets]||!AllTrue[targets,VectorQ[#[[2]],IntegerQ]&]||
   validateCutGLIs[targets,records]=!=True,cutFamilyFail["DistinctFamiliesAndUnpinchedTargetsRequired"]];
 If[!StringQ[Lookup[request,"WorkingDirectory",None]],cutFamilyFail["KiraWorkingDirectoryRequired"]];
 directory=ExpandFileName[request["WorkingDirectory"]];
 extension=Lookup[request,"SeedExtension",{1,1}];
 If[!MatchQ[extension,{_Integer?NonNegative,_Integer?NonNegative}],cutFamilyFail["NonnegativeIBPSeedExtensionRequired"]];
 definition=<|"Format"->"FeynFacet-KiraCutFamilyInput","EquationSource"->"TypedIBP","EquationVersion"->2,
  "Families"->(KeyTake[# ,{"Topology","Cuts","MeasurePrefactor","TimeDirection","Assumptions"}]&/@records),
  "Targets"->Sort[DeleteDuplicates[targets]],"SeedExtension"->extension|>;
 definition=Join[definition,KeyTake[request,{"SeedIntegrals","SeedPolicy","PreferredMasterIntegrals","ExtraEquations"}]];
 directory=cutKiraSelectWorkspace[directory,definition,Lookup[request,"NewWorkspaceForChangedInputs",False]];
 cutKiraWorkspaceDefinition[directory,definition];
 finish[initialRules_,initialDeclared_,solveSeconds_,equationCount_,seedCounts_,generationTime_]:=Module[{result},
  closed=cutKiraCloseSelectedReduction[project,initialRules,targets,initialDeclared,records,request];
  result=<|"Format"->"FeynFacet-CutFamilyReduction","FormatVersion"->1,"Families"->records,"Targets"->targets,
   "Rules"->closed["Rules"],"Masters"->closed["Masters"],"SelectionClosure"->closed["SelectionClosure"],
   "Workspace"->closed["SolutionWorkspace"],"InputWorkspace"->directory,"Seconds"->solveSeconds,
   "EquationSource"->"TypedIBP","NativeSymmetriesUsed"->False,"NativeZeroSectorsUsed"->False,
   "EquationGenerationSeconds"->generationTime,"EquationCount"->equationCount,"SeedCounts"->seedCounts,
   "IndexedIntegrals"->unknowns,"OrdinaryPrescriptionLimitEstablished"->False,
   "MasterMinimality"->"Not asserted beyond the supplied IBP seed closure"|>;
  FamilyArtifactWrite[result,FileNameJoin[{directory,"Reduction.wl"}],Compression->Automatic];
  result];
 If[TrueQ[Lookup[request,"ReuseSavedReduction",True]]&&FileExistsQ[FileNameJoin[{directory,"Reduction.wl"}]],
  cachedResult=FamilyArtifactRead[FileNameJoin[{directory,"Reduction.wl"}]];
  If[AssociationQ[cachedResult]&&Lookup[cachedResult,"Format",None]==="FeynFacet-CutFamilyReduction",
   Return[Join[cachedResult,<|"ReusedSolvedReduction"->True|>]]]];
 If[TrueQ[Lookup[request,"ReuseSavedReduction",True]]&&
   AllTrue[{"IntegralIdentifiers.wl","equations.kira","results/FeynFacetIBP/kira_targets.m"},
    FileExistsQ[FileNameJoin[{directory,#}]]&],
  cachedIdentifiers=FamilyArtifactRead[FileNameJoin[{directory,"IntegralIdentifiers.wl"}]];
  If[AssociationQ[cachedIdentifiers]&&ContainsAll[Keys[cachedIdentifiers],
    {"IndexedIntegrals","IdentifierHead","CoefficientDecodeRules"}],
   unknowns=cachedIdentifiers["IndexedIntegrals"];head=cachedIdentifiers["IdentifierHead"];
   idMap=AssociationThread[unknowns,Range[Length[unknowns]]];
   project=Join[cachedIdentifiers,<|"Directory"->directory,"Runtime"->ibpRuntime[],
    "Manifest"->{<|"Name"->head|>},"EquationSource"->"TypedIBP",
    "InputFingerprint"->reductionFingerprint[definition],"IntegralIndex"->idMap|>];
   {seconds,imported}=AbsoluteTiming[ibpDecodeProjectIntegrals[project,
     ibpImportRuleTable[head,FileNameJoin[{directory,"results","FeynFacetIBP","kira_targets.m"}]]]];
   declared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[project]];
   Print["Reusing the existing typed IBP equations and initial reduction"];
   Return[finish[imported,declared,seconds,Missing["RetainedEquationFile"],
    Missing["RetainedEquationFile"],0]]]];
 generated=Table[
  seeds=Which[
   KeyExistsQ[request,"SeedIntegrals"],
    If[!ListQ[request["SeedIntegrals"]]||validateCutGLIs[request["SeedIntegrals"],records]=!=True,
     cutFamilyFail["ExplicitTypedIBPSeedIntegralsRequired"]];
    <|"Seeds"->Select[request["SeedIntegrals"],#[[1]]===family["Topology"][[1]]&]|>,
   Select[targets,#[[1]]===family["Topology"][[1]]&]==={},<|"Seeds"->{}|>,
   Lookup[request,"SeedPolicy","Rectangular"]==="TargetDownsets",
    FeynFacet`PlanCutIBPSeeds[family,Select[targets,#[[1]]===family["Topology"][[1]]&]],
   Lookup[request,"SeedPolicy","Rectangular"]==="Rectangular",
    cutIBPSeeds[family,Select[targets,#[[1]]===family["Topology"][[1]]&],extension],
   True,cutFamilyFail["SupportedTypedIBPSeedPolicyRequired"]];
  If[!AssociationQ[seeds],cutFamilyFail["TypedIBPSeedSelectionFailed",<|"Cause"->seeds|>]];

  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["Generating typed IBPs for ",
   family["Topology"][[1]],": ",Length[seeds["Seeds"]]," seeds"]];
  {generationSeconds,equationRecord}=If[seeds["Seeds"]==={},{0,<|"Rows"->{},"Seeds"->{}|>},
    AbsoluteTiming[FeynFacet`GenerateCutIBPEquations[family,seeds["Seeds"]]]];
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["IBP generation seconds: ",generationSeconds]];
  If[!AssociationQ[equationRecord],cutFamilyFail["TypedIBPEquationGenerationFailed",<|"Cause"->equationRecord|>]];
  Join[equationRecord,KeyDrop[seeds,"Seeds"],<|"GenerationSeconds"->generationSeconds|>],
 {family,records}];
 If[!AllTrue[generated,AssociationQ],cutFamilyFail["TypedIBPEquationGenerationFailed"]];
 If[!ListQ[Lookup[request,"ExtraEquations",{}]]||
   !AllTrue[Lookup[request,"ExtraEquations",{}],AssociationQ],
  cutFamilyFail["ExplicitAdditionalIntegralEquationsRequired"]];
 equations=Join[Flatten[Lookup[generated,"Rows"],1],Lookup[request,"ExtraEquations",{}]];
 If[equations==={},cutFamilyFail["NonemptyIBPSystemRequired"]];
 project=cutKiraPrepareEquationSystem[records,targets,equations,directory,
   Lookup[request,"PreferredMasterIntegrals",{}]];
 project=Join[project,<|"InputFingerprint"->reductionFingerprint[definition]|>];
 unknowns=project["IndexedIntegrals"];head=project["IdentifierHead"];
 Export[FileNameJoin[{directory,"jobs.yaml"}],cutKiraEquationJob["Exact"],"String"];
 Print["Typed IBP system: ",Length[equations]," equations, ",Length[unknowns]," integral identifiers"];
 {seconds,imported}=AbsoluteTiming[
  ibpRunKira[project,Lookup[request,"Threads",1]];
  ibpImportRuleTable[head,FileNameJoin[{directory,"results","FeynFacetIBP","kira_targets.m"}]]];
 imported=ibpDecodeProjectIntegrals[project,imported];
 declared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[project]];
 If[!FreeQ[{imported,declared},FeynCalc`GLI[head,_]],cutFamilyFail["UnmappedKiraIntegralIdentifier"]];
 finish[imported,declared,seconds,Length[equations],Length[#["Seeds"]]&/@generated,
  Total[Lookup[generated,"GenerationSeconds"]]]
 ],"CutFamily"],$ibpFailure];
End[];EndPackage[];
