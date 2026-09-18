(* Typed cut IBPs supply equations; Kira supplies the sparse linear solver.
   No topology configuration, native zero-sector decision or unaudited
   symmetry identification enters this equation source. *)
BeginPackage["FeynFacet`"];
GenerateCutIBPEquations::usage="GenerateCutIBPEquations[family,seeds] constructs the L(L+E) total-derivative IBP equations per seed, using the complete inverse-denominator basis and the jointly continued forward-cut convention. Only mandatory-cut pinches are set to zero.";
Begin["`Private`"];
cutIBPOperators[family_Association]:=Module[
 {top=family["Topology"],loops,external,basis,coordinates,variables,polynomials,kin,
  scalarVelocity,changes},
 loops=top[[3]];external=top[[4]];
 basis=family["LoopScalarProducts"];variables=family["DenominatorVariables"];
 coordinates=Table[Unique["ibpScalar$"],{Length[basis]}];kin=FeynCalc`FCI[top[[5]]];
 polynomials=family["InversePropagators"]/.Thread[basis->coordinates];
 Flatten[Table[
  scalarVelocity=Map[Function[pair,With[{a=pair[[1,1]],b=pair[[2,1]]},
   (If[a===ell,FeynCalc`FCI[FeynCalc`SPD[vector,b]],0]+
    If[b===ell,FeynCalc`FCI[FeynCalc`SPD[vector,a]],0])/.kin]],basis];
  changes=Expand[(Table[
    Sum[D[poly,coordinates[[j]]]scalarVelocity[[j]],{j,Length[basis]}],
    {poly,polynomials}])/.Thread[coordinates->basis]/.family["ScalarProductRules"]];
  <|"LoopMomentum"->ell,"Vector"->vector,"Divergence"->If[ell===vector,D,0],
    "DenominatorDerivativeMonomials"->(CoefficientRules[#,variables]&/@changes)|>,
 {ell,loops},{vector,Join[loops,external]}],1]
];
cutIBPShiftRows[family_,operators_,indices_List]:=Module[
 {count=Length[indices],zero,raw,rows,variables=family["DenominatorVariables"],relations},
 zero=ConstantArray[0,count];
 rows=Table[
  raw=If[KeyExistsQ[operator,"DivergenceMonomials"],
   (-First[#]->Last[#])&/@operator["DivergenceMonomials"],{zero->operator["Divergence"]}];
  Do[If[KeyExistsQ[Lookup[operator,"ProtectedDenominatorCofactorMonomials",<||>],i],
   Scan[Function[term,AppendTo[raw,-First[term]->(-indices[[i]]Last[term])]],
    operator["ProtectedDenominatorCofactorMonomials"][i]],
   Scan[Function[term,AppendTo[raw,
    (UnitVector[count,i]-First[term])->(-indices[[i]]Last[term])]],
    operator["DenominatorDerivativeMonomials"][[i]]]],{i,count}];
  Normal[Select[Map[Factor,Merge[raw,Total]],#=!=0&]],{operator,operators}];
 relations=Values[Lookup[family,"DependentDenominatorRelations",<||>]];
 Join[rows,Map[Function[relation,(-First[#]->Last[#])&/@CoefficientRules[relation,variables]],relations]]
];

GenerateCutIBPEquations[family_Association,seeds:{__FeynCalc`GLI}]:=
 cutGenerateIBPEquations[family,seeds,Automatic];
cutGenerateIBPEquations[family_Association,seeds:{__FeynCalc`GLI},operatorData_]:=Catch[Module[
 {top,cuts,operators,rows,indices,shiftRows,symbols,terms,row,rowTag=Unique["ibpEquation$"],
  substitutions,coefficients,factorCoefficient,coefficientCache=<||>,cacheBytes=0},
 If[!MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-LoopIntegralFamily"},Lookup[family,"Format",None]],
   cutFamilyFail["IntegralFamilyRequired"]];
 top=family["Topology"];cuts=family["CutIndices"];
 If[!AllTrue[seeds,#[[1]]===top[[1]]&&Length[#[[2]]]===Length[top[[2]]]&&
   VectorQ[#[[2]],IntegerQ]&&AllTrue[#[[2,cuts]],#>0&]&],cutFamilyFail["ValidUnpinchedIBPSeedsRequired"]];
 operators=If[operatorData===Automatic,cutIBPOperators[family],operatorData];
 symbols=Table[Unique["integralPower$"],{Length[top[[2]]]}];
 shiftRows=cutIBPShiftRows[family,operators,symbols];
 shiftRows=Map[Function[one,With[{combined=Map[Total,GroupBy[one,First->Last]]},
   {Keys[combined],Values[combined]}]],shiftRows];
 factorCoefficient[value_]:=If[KeyExistsQ[coefficientCache,value],coefficientCache[value],Module[{result},
   result=Factor[value];
   If[cacheBytes+ByteCount[value]+ByteCount[result]<4*1024^2,
    AssociateTo[coefficientCache,value->result];cacheBytes+=ByteCount[value]+ByteCount[result]];
   result]];
 rows=Flatten[Last[Reap[Do[
  indices=seed[[2]];substitutions=Thread[symbols->indices];
  Do[coefficients=factorCoefficient/@(shifts[[2]]/.substitutions);
   terms=MapThread[Function[{shift,coefficient},With[{powers=indices+shift},
    If[coefficient===0||!AllTrue[powers[[cuts]],#>0&],Nothing,FeynCalc`GLI[top[[1]],powers]->coefficient]]],
     {shifts[[1]],coefficients}];
   If[terms=!={},row=Association[terms];
    If[row=!=<||>,Sow[row,rowTag]]],{shifts,shiftRows}],{seed,seeds}],rowTag]],1];
 <|"Format"->"FeynFacet-IBPEquations","Rows"->DeleteDuplicates[rows],
  "Seeds"->seeds,"OperatorCount"->Length[operators],
  "AlgebraicRelationCount"->Length[Lookup[family,"DependentDenominatorRelations",<||>]],
  "EquationSource"->"IntegrationByPartsAndDenominatorRelations",
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
cutKiraDefinitionFile[directory_]:=SelectFirst[
 {directory<>"/InputDefinition.wxf",directory<>"/InputDefinition.wl"},FileExistsQ,directory<>"/InputDefinition.wl"];
cutKiraReadDefinition[directory_]:=With[{file=cutKiraDefinitionFile[directory]},
 If[FileExistsQ[file],FamilyArtifactRead[file],Missing["UnverifiedWorkspace"]]];
cutKiraSelectWorkspace[directory_,definition_,allowNew_]:=Module[{candidate=directory,index=1,old},
 If[!MemberQ[{True,False},allowNew],cutFamilyFail["BooleanChangedInputWorkspacePolicyRequired"]];
 If[!TrueQ[allowNew],Return[directory]];
 While[DirectoryQ[candidate]&&FileNames[All,candidate]=!={},
  old=cutKiraReadDefinition[candidate];
  If[AssociationQ[old]&&cutKiraDefinitionCanonical[old]===cutKiraDefinitionCanonical[definition],Return[candidate]];
  candidate=directory<>"/Generation"<>IntegerString[index,10,3];index++];
 If[candidate=!=directory,Print["Using a new Kira workspace for changed exact inputs: ",candidate]];
 candidate
];
cutKiraWorkspaceDefinition[directory_,rawDefinition_]:=Module[{file,old,definition=cutKiraDefinitionCanonical[rawDefinition]},
 (* Large equation snapshots are solver state, not physical coefficient
    reports. Binary storage avoids repeatedly parsing/printing tens of MB of
    identical rational trees; small definitions remain readable. *)
 file=FileNameJoin[{directory,If[ByteCount[definition]>2^20,"InputDefinition.wxf","InputDefinition.wl"]}];
 If[DirectoryQ[directory]&&FileNames[All,directory]=!={},
  old=cutKiraReadDefinition[directory];
  If[cutKiraDefinitionCanonical[old]=!=definition,cutFamilyFail["KiraWorkspaceDefinitionMismatch",<|"Directory"->directory|>]];
  If[FileExistsQ[file],Return[file]]];
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 If[FamilyArtifactWrite[definition,file]===$Failed,cutFamilyFail["KiraInputDefinitionWriteFailed"]]
];

(* Kira can leave nonselected pivots on an exported right-hand side.
   Add them to the solved selection; never relabel them as physical masters.
   The equation system is reused without regenerating or enlarging its seeds. *)
cutKiraIdentityTargets[project_Association,rules_List,targets_List]:=Module[{images},
 images=targets/.Dispatch[rules];
 If[AllTrue[MapThread[(#1===#2||#1===0)&,{images,targets}],TrueQ],
  ibpEncodeProjectIntegrals[project,DeleteCases[images,0]],Automatic]
];
(* FireFly's masters.final enumerates reconstructed right-hand-side columns.
   It omits requested identity masters and can include unselected pivots.
   Kira's initial masters file is the declaration from the supplied IBP system.
   Close exports against that declaration; never promote an arbitrary RHS. *)
cutKiraExportSelectedDependencies[project_,frontier_,iteration_]:=Module[
 {directory=project["Directory"],encoded,file,job,output,process,imported},
 encoded=ibpEncodeProjectIntegrals[project,frontier];
 file="export_dependencies_"<>IntegerString[iteration,10,3];
 Export[directory<>"/"<>file,StringRiffle[ibpKiraIntegralText/@encoded,"\n"]<>"\n","String"];
 job="jobs_"<>file<>".yaml";
 Export[directory<>"/"<>job,"jobs:\n  - kira2math:\n      target:\n        - [FeynFacetIBP, "<>file<>"]\n","String"];
 process=RunProcess[{project["Runtime"]["KiraExecutable"],"--parallel=1",job},All,
   ProcessDirectory->directory,ProcessEnvironment-><|"FERMATPATH"->project["Runtime"]["FermatExecutable"]|>];
 Export[directory<>"/"<>file<>".log",Lookup[process,"StandardOutput",""]<>Lookup[process,"StandardError",""],"String"];
 If[Lookup[process,"ExitCode",1]=!=0,cutFamilyFail["KiraDependencyExportFailed"]];
 output=directory<>"/results/FeynFacetIBP/kira_"<>file<>".m";
 imported=ibpDecodeProjectIntegrals[project,ibpImportRuleTable[project["IdentifierHead"],output]];
 If[!ContainsAll[frontier,First/@imported]||!DuplicateFreeQ[First/@imported],
  cutFamilyFail["ExactRequestedDependencyExportsRequired"]];
 imported
];
cutKiraCloseSelectedReduction[project_,initialRules_,targets_,initialDeclared_,records_,request_]:=Module[
 {rules=initialRules,declared=initialDeclared,closed,frontier,diagnostics={},newRules,missing,oldFrontier,
  iteration=0,limit=Lookup[request,"MaximumSelectionClosureIterations",12],directory,
  currentProject=project,selectionDefinition,encoded,inputFile,seconds,imported,newDeclared},
 closed=ibpCloseReductionRules[rules,targets];
 frontier=Complement[closed["Masters"],declared,SameTest->SameQ];
 inputFile=FileNameJoin[{project["Directory"],"equations.kira"}];
 While[frontier=!={},
  iteration++;If[iteration>limit,cutFamilyFail["KiraSelectionClosureIncomplete",
   <|"UnreducedDependencies"->frontier,"Iterations"->diagnostics|>]];
  oldFrontier=frontier;
  {seconds,newRules}=AbsoluteTiming[cutKiraExportSelectedDependencies[currentProject,frontier,iteration]];
  missing=Complement[frontier,First/@newRules];
  If[missing=!={},
   directory=FileNameJoin[{project["Directory"],"DependencyReduction"<>IntegerString[iteration,10,3]}];
   encoded=ibpEncodeProjectIntegrals[project,missing];
   selectionDefinition=<|"Format"->"FeynFacet-KiraDependencyInput",
    "OriginalInputDefinition"->cutKiraReadDefinition[project["Directory"]],
    "SelectedIdentifiers"->encoded|>;
   cutKiraWorkspaceDefinition[directory,selectionDefinition];
   Export[directory<>"/selected_integrals",StringRiffle[ibpKiraIntegralText/@encoded,"\n"]<>"\n","String"];
   Export[directory<>"/jobs.yaml",cutKiraEquationJob[
    Lookup[request,"RationalSolver","Fermat"],"points",inputFile,"selected_integrals"],"String"];
   currentProject=Join[project,<|"Directory"->directory|>];
   Print["Reducing ",Length[missing]," unresolved dependencies while retaining ",Length[rules]," exact export rows"];
   seconds+=First@AbsoluteTiming[
    If[!FileExistsQ[directory<>"/results/FeynFacetIBP/kira_selected_integrals.m"],
      ibpRunKira[currentProject,Lookup[request,"Threads",1]]];
    imported=ibpDecodeProjectIntegrals[project,ibpImportRuleTable[project["IdentifierHead"],
      directory<>"/results/FeynFacetIBP/kira_selected_integrals.m"]];
    newDeclared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[currentProject,Automatic,"masters"]]];
   If[!ContainsAll[missing,First/@imported],cutFamilyFail["ExactRequestedDependencyReductionsRequired"]];
   newRules=Join[newRules,imported];declared=Union[declared,newDeclared]];
  If[validateCutGLIs[newRules,records]=!=True||
    !DuplicateFreeQ[Join[First/@rules,First/@newRules]],cutFamilyFail["DistinctPhysicalDependencyRulesRequired"]];
  rules=Join[rules,newRules];closed=ibpCloseReductionRules[rules,targets];
  AppendTo[diagnostics,<|"Iteration"->iteration,"AddedDependencies"->oldFrontier,
    "ExportedRuleCount"->Length[newRules],"ReconstructionTargetCount"->Length[missing],
    "Seconds"->seconds,"Workspace"->currentProject["Directory"]|>];
  frontier=Complement[closed["Masters"],declared,SameTest->SameQ];
  If[frontier===oldFrontier,cutFamilyFail["KiraDependencyClosureMadeNoProgress",
    <|"UnreducedDependencies"->frontier,"Iterations"->diagnostics|>]]];
 ibpValidateMasters[closed["Masters"],declared,records];
 Join[closed,<|"SelectionClosure"-><|"Status"->If[diagnostics==={},"AlreadyClosed","ClosedByDependencyReduction"],
  "DeclaredMasterSource"->"InitialIBPSystem","Iterations"->diagnostics|>,
  "SolutionWorkspace"->currentProject["Directory"]|>]
];
(* Family equations are independent; preserve family and equation ordering
   while the managed pool schedules the actual symbolic work. *)
cutGenerateIBPJob[job_Association]:=Catch[Module[
 {family=job["Family"],plan=job["Plan"],seconds,record},
 If[!AssociationQ[plan]||!ListQ[Lookup[plan,"Seeds",None]],
  cutFamilyFail["TypedIBPSeedSelectionFailed"]];
 {seconds,record}=If[plan["Seeds"]==={},{0,<|"Rows"->{},"Seeds"->{}|>},
  AbsoluteTiming[cutGenerateIBPEquations[family,plan["Seeds"],job["Operators"]]]];
 If[!AssociationQ[record],cutFamilyFail["TypedIBPEquationGenerationFailed",<|"Cause"->record|>]];
 If[TrueQ[Lookup[job,"PrintTimings",False]],
  Print["IBP_GENERATED ",family["Topology"][[1]]," SEEDS ",Length[plan["Seeds"]],
   " ROWS ",Length[record["Rows"]]," SECONDS ",seconds]];
 Join[record,KeyDrop[plan,"Seeds"],<|"GenerationSeconds"->seconds,"GenerationKernel"->$KernelID|>]
],"CutFamily"];
cutGenerateIBPBatch[jobs_List,workers_Integer]:=Module[{answer,preparedJobs},
 If[!Between[workers,{1,8}],Return[Failure["OneThroughEightIBPGenerationKernelsRequired",<||>]]];
 (* Capture FeynCalc-dependent operator construction once on the caller.
    Workers receive explicit tables and perform only exact row generation. *)
 preparedJobs=Catch[Map[Function[job,
  If[!AssociationQ[job]||!AssociationQ[Lookup[job,"Family",None]]||
    !AssociationQ[Lookup[job,"Plan",None]],cutFamilyFail["TypedIBPGenerationJobRequired"]];
   If[KeyExistsQ[job,"Operators"],
    If[!ListQ[job["Operators"]]||!AllTrue[job["Operators"],AssociationQ],
      cutFamilyFail["PreparedIBPOperatorRecordsRequired"]];job,
    Join[job,<|"Operators"->cutIBPOperators[job["Family"]]|>]]],jobs],"CutFamily"];
 If[!ListQ[preparedJobs],Return[preparedJobs]];
 answer=facetWithSymbolicWorkers[
  facetSymbolicMap[FeynFacet`Private`cutGenerateIBPJob,preparedJobs],Min[workers,Max[1,Length[jobs]]]];
 If[!ListQ[answer]||Length[answer]=!=Length[jobs]||!AllTrue[answer,AssociationQ],
  Return[Failure["TypedIBPEquationGenerationFailed",<|"Cause"->answer|>]]];
 answer
];
(* The unknown rescaling is verified on every equation before removing a
   dimensionful variable from rational reconstruction. It does not replace
   physical integral values by their values at scale one. *)
cutKiraNormalizeScale[records_,equations_,targets_,scale_]:=Module[
 {lambda=Unique["equationScale"],degrees,scaled,powers,unknowns,weights,normalization},
 If[!MatchQ[scale,_Symbol],cutFamilyFail["SymbolicIntegralEquationScaleRequired"]];
 degrees=Association@Table[
  scaled=Expand[(#/.Thread[family["LoopScalarProducts"]->lambda family["LoopScalarProducts"]])/.scale->lambda scale]&/@
    family["InversePropagators"];
  powers=Cancel[Together[lambda D[#,lambda]/#]]&/@scaled;
  If[!VectorQ[powers,IntegerQ],cutFamilyFail["HomogeneousInversePropagatorsRequired"]];
  family["Topology"][[1]]->powers,{family,records}];
 unknowns=Union[targets,Flatten[Keys/@equations]];
 weights=Association[(#->(-#[[2]].degrees[#[[1]]]))&/@unknowns];
 normalization=FeynFacet`NormalizeIntegralEquationScale[equations,weights,scale];
 If[!AssociationQ[normalization],cutFamilyFail["VerifiedIntegralEquationScaleRequired",<|"Cause"->normalization|>]];
 Join[normalization,<|"PropagatorScaleWeights"->degrees,"EquationCount"->Length[equations]|>]
];
KiraReduction[families:{__Association},targets:{__FeynCalc`GLI},request_Association]:=Catch[
 Catch[Module[
 {records,directory,extension,generated,seeds,equationRecord,equations,unknowns,names,familyOrder,idMap,idRules,
  variables,variableNames,variableRules,reverseVariables,coefficientText,coefficientValues,rows,text,project,
  imported,declared,closed,seconds,generationSeconds,generationWorkers,jobs,totalEquationCount,familySeedCounts,generationWorkerSeconds=Missing["NotRetained"],generationKernelCount=Missing["NotRetained"],definition,cachedIdentifiers,cachedResult,finish,head=Global`FeynFacetIBP,aliases,
   scaleNormalization=None,scale=Lookup[request,"HomogeneousScale",None],restoredRules,
   knownRules=Lookup[request,"KnownIntegralRules",{}],solveTargets=targets,elimination=None,
   eliminationSeconds=0,composed,residualIsZero=False,
  solver=Lookup[request,"RationalSolver","Fermat"]},
 If[Lookup[request,"EquationSource","TypedIBP"]==="NativeDiagnostic",
  If[KeyExistsQ[request,"KnownIntegralRules"],cutFamilyFail["KnownIntegralRulesRequireTypedIBP"]];
  Return[kiraNativeCutFamilyReduction[families,targets,request]]];
 If[Lookup[request,"EquationSource","TypedIBP"]=!="TypedIBP",cutFamilyFail["TypedIBPEquationSourceRequired"]];
 If[!MemberQ[{"Fermat","FireFly"},solver],cutFamilyFail["SupportedKiraRationalSolverRequired"]];
 records=FeynFacet`CreateCutIntegralFamily/@families;
 If[!AllTrue[records,AssociationQ],cutFamilyFail["ValidatedCutIntegralFamiliesRequired"]];
 names=First[#["Topology"]]&/@records;
  If[!DuplicateFreeQ[names]||!ContainsAll[names,First/@targets]||!AllTrue[targets,VectorQ[#[[2]],IntegerQ]&]||
    validateCutGLIs[targets,records]=!=True,cutFamilyFail["DistinctFamiliesAndUnpinchedTargetsRequired"]];
  If[!MatchQ[knownRules,{(_Rule)...}]||validateCutGLIs[knownRules,records]=!=True,
    cutFamilyFail["ExactUnpinchedKnownIntegralRulesRequired"]];
  If[knownRules=!={},
   elimination=FeynFacet`EliminateKnownIntegralRules[{},targets,knownRules];
   If[!AssociationQ[elimination],cutFamilyFail["ClosedKnownIntegralRulesRequired",<|"Cause"->elimination|>]];
   solveTargets=elimination["Targets"];
   If[Intersection[Lookup[request,"PreferredMasterIntegrals",{}],First/@knownRules]=!={},
    cutFamilyFail["PreferredMastersMustRemainAfterKnownRuleElimination"]]];
 If[!StringQ[Lookup[request,"WorkingDirectory",None]],cutFamilyFail["KiraWorkingDirectoryRequired"]];
 directory=ExpandFileName[request["WorkingDirectory"]];
 extension=Lookup[request,"SeedExtension",{1,1}];
 If[!MatchQ[extension,{_Integer?NonNegative,_Integer?NonNegative}],cutFamilyFail["NonnegativeIBPSeedExtensionRequired"]];
 definition=<|"Format"->"FeynFacet-KiraCutFamilyInput","EquationSource"->"TypedIBP","EquationVersion"->3,
  "Families"->(KeyTake[# ,{"Topology","Cuts","MeasurePrefactor","TimeDirection","Assumptions"}]&/@records),
  "Targets"->Sort[DeleteDuplicates[targets]],"SeedExtension"->extension|>;
  definition=Join[definition,KeyTake[request,{"SeedIntegrals","SeedPolicy","PreferredMasterIntegrals","ExtraEquations","HomogeneousScale","RationalSolver","KnownIntegralRules"}]];
 directory=cutKiraSelectWorkspace[directory,definition,Lookup[request,"NewWorkspaceForChangedInputs",False]];
 cutKiraWorkspaceDefinition[directory,definition];
 finish[initialRules_,initialDeclared_,solveSeconds_,equationCount_,seedCounts_,generationTime_]:=Module[{result},
   closed=If[solveTargets==={},<|"Rules"->{},"Masters"->{},"SolutionWorkspace"->directory,
     "SelectionClosure"-><|"Status"->"AllTargetsZeroByKnownRules","DeclaredMasterSource"->"SuppliedExactRules","Iterations"->{}|>|>,
     cutKiraCloseSelectedReduction[project,initialRules,solveTargets,initialDeclared,records,request]];
  restoredRules=If[AssociationQ[scaleNormalization],
    FeynFacet`RestoreIntegralEquationScale[closed["Rules"],scaleNormalization],closed["Rules"]];
   If[!ListQ[restoredRules],cutFamilyFail["OriginalIntegralScaleRestorationFailed",<|"Cause"->restoredRules|>]];
   composed=If[knownRules==={},<|"Rules"->restoredRules,"Masters"->closed["Masters"]|>,
     ibpCloseReductionRules[Join[knownRules,restoredRules],targets]];
   result=<|"Format"->"FeynFacet-CutFamilyReduction","FormatVersion"->1,"Families"->records,"Targets"->targets,
    "Rules"->composed["Rules"],"Masters"->composed["Masters"],"SelectionClosure"->closed["SelectionClosure"],
   "Workspace"->closed["SolutionWorkspace"],"InputWorkspace"->directory,"Seconds"->solveSeconds,
   "EquationSource"->"TypedIBP","RationalSolver"->solver,"NativeSymmetriesUsed"->False,"NativeZeroSectorsUsed"->False,
   "EquationGenerationSeconds"->generationTime,
   "EquationGenerationWorkerSeconds"->generationWorkerSeconds,
    "EquationGenerationKernels"->generationKernelCount,
    "KnownRuleEliminationSeconds"->eliminationSeconds,
    "KnownRuleElimination"->If[AssociationQ[elimination],KeyTake[elimination,
      {"OriginalEquationCount","ResidualEquationCount","OriginalColumnCount","ResidualColumnCount","Scope"}],None],
   "EquationCount"->equationCount,"SeedCounts"->seedCounts,
   "IndexedIntegralCount"->Length[unknowns],"OrdinaryPrescriptionLimitEstablished"->False,
   "MasterMinimality"->"Not asserted beyond the supplied IBP seed closure",
   "EquationScaleNormalization"->If[AssociationQ[scaleNormalization],KeyTake[scaleNormalization,
     {"Scale","PropagatorScaleWeights","EquationCount","ExactChangeOfUnknownsEstablished","Convention"}],None]|>;
   FamilyArtifactWrite[result,FileNameJoin[{directory,"Reduction.wl"}],Compression->Automatic];
   result];
  If[solveTargets==={},unknowns={};Return[finish[{}, {},0,0,{},0]]];
 If[TrueQ[Lookup[request,"ReuseSavedReduction",True]]&&FileExistsQ[FileNameJoin[{directory,"Reduction.wl"}]],
  cachedResult=FamilyArtifactRead[FileNameJoin[{directory,"Reduction.wl"}]];
  If[AssociationQ[cachedResult]&&Lookup[cachedResult,"Format",None]==="FeynFacet-CutFamilyReduction"&&
    Lookup[Lookup[cachedResult,"SelectionClosure",<||>],"DeclaredMasterSource",None]==="InitialIBPSystem",
   closed=ibpCloseReductionRules[cachedResult["Rules"],cachedResult["Targets"]];
   Return[Join[cachedResult,KeyTake[closed,{"Rules","Masters"}],<|"ReusedSolvedReduction"->True|>]]]];
 If[TrueQ[Lookup[request,"ReuseSavedReduction",True]]&&
   AllTrue[{"IntegralIdentifiers.wxf","equations.kira","targets"},
    FileExistsQ[FileNameJoin[{directory,#}]]&],
  cachedIdentifiers=FamilyArtifactRead[FileNameJoin[{directory,"IntegralIdentifiers.wxf"}]];
   If[AssociationQ[cachedIdentifiers]&&ContainsAll[Keys[cachedIdentifiers],
     {"IndexedIntegrals","IdentifierHead","CoefficientDecodeRules"}],
    If[knownRules=!={},
     elimination=FamilyArtifactRead[directory<>"/EquationElimination.wl"];
     If[!AssociationQ[elimination]||Lookup[elimination,"Targets",None]=!=solveTargets||
       Lookup[elimination,"OriginalTargets",None]=!=targets,
      cutFamilyFail["SavedResidualIntegralEquationDefinitionRequired"]];
     residualIsZero=elimination["ResidualColumnCount"]===0];
   unknowns=cachedIdentifiers["IndexedIntegrals"];head=cachedIdentifiers["IdentifierHead"];
   If[scale=!=None&&!residualIsZero,
    scaleNormalization=FamilyArtifactRead[directory<>"/EquationScaleNormalization.wl"];
    If[!AssociationQ[scaleNormalization]||Lookup[scaleNormalization,"Scale",None]=!=scale,
     cutFamilyFail["SavedIntegralEquationScaleNormalizationRequired"]]];
   idMap=AssociationThread[unknowns,Range[Length[unknowns]]];
   project=Join[cachedIdentifiers,<|"Directory"->directory,"Runtime"->ibpRuntime[],
    "Manifest"->{<|"Name"->head|>},"EquationSource"->"TypedIBP",
    "InputFingerprint"->reductionFingerprint[definition],"IntegralIndex"->idMap|>];
   If[residualIsZero,Return[finish[{},solveTargets,0,elimination["OriginalEquationCount"],
     Missing["RetainedEquationFile"],0]]];
   {seconds,imported}=AbsoluteTiming[
    If[!FileExistsQ[directory<>"/results/FeynFacetIBP/kira_targets.m"],
     Print["Resuming the native solve from verified typed IBP equation files"];
     Export[directory<>"/jobs.yaml",cutKiraEquationJob[solver],"String"];
     ibpRunKira[project,Lookup[request,"Threads",1]]];
    ibpDecodeProjectIntegrals[project,
     ibpImportRuleTable[head,FileNameJoin[{directory,"results","FeynFacetIBP","kira_targets.m"}]]]];
   declared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[project,Automatic,"masters"]];
   Print["Reusing the existing typed IBP equations and initial reduction"];
   Return[finish[imported,declared,seconds,Missing["RetainedEquationFile"],
    Missing["RetainedEquationFile"],0]]]];
 jobs=Table[
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
  <|"Family"->family,"Plan"->seeds,"PrintTimings"->Lookup[request,"PrintTimings",False]|>,
 {family,records}];
 generationWorkers=Lookup[request,"GenerationKernels",1];
 If[!IntegerQ[generationWorkers]||!Between[generationWorkers,{1,8}],
  cutFamilyFail["OneThroughEightIBPGenerationKernelsRequired"]];
 {generationSeconds,generated}=AbsoluteTiming[cutGenerateIBPBatch[jobs,generationWorkers]];
 If[!ListQ[generated]||!AllTrue[generated,AssociationQ],cutFamilyFail["TypedIBPEquationGenerationFailed",<|"Cause"->generated|>]];
 If[!ListQ[Lookup[request,"ExtraEquations",{}]]||
   !AllTrue[Lookup[request,"ExtraEquations",{}],AssociationQ],
  cutFamilyFail["ExplicitAdditionalIntegralEquationsRequired"]];
 equations=Join[Flatten[Lookup[generated,"Rows"],1],Lookup[request,"ExtraEquations",{}]];
 If[equations==={},cutFamilyFail["NonemptyIBPSystemRequired"]];
 totalEquationCount=Length[equations];familySeedCounts=Length[#["Seeds"]]&/@generated;
 generationWorkerSeconds=Total[Lookup[generated,"GenerationSeconds"]];
 generationKernelCount=Length[DeleteDuplicates[Lookup[generated,"GenerationKernel"]]];
  Clear[generated,jobs,seeds,equationRecord];
  If[knownRules=!={},
   {eliminationSeconds,elimination}=AbsoluteTiming[
     FeynFacet`EliminateKnownIntegralRules[equations,targets,knownRules]];
   If[!AssociationQ[elimination],cutFamilyFail["KnownIntegralEquationEliminationFailed",<|"Cause"->elimination|>]];
   equations=elimination["Rows"];residualIsZero=equations==={};
   elimination=KeyDrop[elimination,{"Rows","KnownRules","TargetImages"}];
   If[elimination["Targets"]=!=solveTargets,cutFamilyFail["ConsistentResidualTargetsRequired"]];
   If[FamilyArtifactWrite[KeyDrop[elimination,{"Rows","KnownRules","TargetImages"}],
     directory<>"/EquationElimination.wl"]===$Failed,cutFamilyFail["IntegralEquationEliminationWriteFailed"]];
   Print["Substituted ",Length[knownRules]," known integral identities: ",totalEquationCount,
     " equations -> ",Length[equations]," residual equations; ",elimination["OriginalColumnCount"],
     " -> ",elimination["ResidualColumnCount"]," equation columns"]];
  If[scale=!=None,
   scaleNormalization=If[residualIsZero,None,cutKiraNormalizeScale[records,equations,solveTargets,scale]];
   If[AssociationQ[scaleNormalization],
   equations=scaleNormalization["Rows"];
  scaleNormalization=KeyDrop[scaleNormalization,{"Rows","OriginalRowScaleDegrees"}];
  If[FamilyArtifactWrite[scaleNormalization,directory<>"/EquationScaleNormalization.wl",Compression->Automatic]===$Failed,
    cutFamilyFail["IntegralEquationScaleNormalizationWriteFailed"]];
   Print["Removed equation scale ",scale," by a verified change of integral unknowns"]]];
  project=cutKiraPrepareEquationSystem[records,solveTargets,equations,directory,
   Lookup[request,"PreferredMasterIntegrals",{}]];
 Clear[equations];
 project=Join[project,<|"InputFingerprint"->reductionFingerprint[definition]|>];
  unknowns=project["IndexedIntegrals"];head=project["IdentifierHead"];
  If[residualIsZero,Return[finish[{},solveTargets,0,totalEquationCount,familySeedCounts,generationSeconds]]];
 Export[FileNameJoin[{directory,"jobs.yaml"}],cutKiraEquationJob[solver],"String"];
 Print["Typed IBP system: ",totalEquationCount," equations, ",Length[unknowns]," integral identifiers"];
 {seconds,imported}=AbsoluteTiming[
  ibpRunKira[project,Lookup[request,"Threads",1]];
  ibpImportRuleTable[head,FileNameJoin[{directory,"results","FeynFacetIBP","kira_targets.m"}]]];
 imported=ibpDecodeProjectIntegrals[project,imported];
 declared=ibpDecodeProjectIntegrals[project,ibpDeclaredMasters[project,Automatic,"masters"]];
 If[!FreeQ[{imported,declared},FeynCalc`GLI[head,_]],cutFamilyFail["UnmappedKiraIntegralIdentifier"]];
 finish[imported,declared,seconds,totalEquationCount,familySeedCounts,
  generationSeconds]
 ],"CutFamily"],$ibpFailure];
End[];EndPackage[];
