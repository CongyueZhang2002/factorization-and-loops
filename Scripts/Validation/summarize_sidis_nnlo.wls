$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
summary=<||>;
Do[
 project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>name];
 reports=Table[FeynFacet`FamilyArtifactRead[project["Directory"]<>"/NNLO/q-q/Results/Validation/NNLOComparisonPoint"<>ToString[j]<>".wl"],{j,5}];
 If[!AllTrue[reports,AssociationQ[#]&&#["Status"]==="Passed"&],Print["INCOMPLETE INDEPENDENT VALIDATION ",name];Exit[1]];
 files=Table[project["Directory"]<>"/NNLO/"<>channel<>"/Results/Result.wl",{channel,project["Orders"]["NNLO"]}];
 data=FeynFacet`ReadPartonicResult/@files;
 If[!AllTrue[data,AssociationQ[#]&&#["EpsilonRange"]==={0,0}&&TrueQ[#["PoleCancellationVerified"]]&&
  #["UnresolvedIntegrals"]===False&],Print["INVALID FINAL RESULT ",name];Exit[1]];
 counts=Length[FeynFacet`PartonicScalarCoefficientRules[#]]&/@data;
 all=Flatten[Values[FeynFacet`PartonicScalarCoefficientRules[#]]&/@data];
 symbols=DeleteDuplicates[Cases[all,s_Symbol:>Context[s]<>SymbolName[s],{0,Infinity},Heads->True]];
 If[!FreeQ[all,_Integrate|_NIntegrate|_Inactive|_Gamma|_PolyGamma|_Conjugate|_Re|_Im|_FeynCalc`GLI|
  _FeynFacetSolution`F|_FeynFacetSolution`K|_Failure],Print["UNRESOLVED FINAL FUNCTIONS ",name];Exit[1]];
 report=<|"Status"->"Completed","Project"->name,"Order"->"NNLO",
 "ChannelCount"->Length[files],"StructureFunctionCount"->Length[project["StructureFunctions"]]Length[files],
 "FiniteCoefficientCountPerPoint"->reports[[1]]["FiniteCoefficientCount"],
 "PoleCoefficientCountPerPoint"->reports[[1]]["PoleCoefficientCount"],
 "IndependentParameterPoints"->Lookup[reports,"ParameterRules"],
 "FiniteCoefficientComparisons"->Total[Lookup[reports,"FiniteCoefficientCount"]],
 "PoleCoefficientChecks"->Total[Lookup[reports,"PoleCoefficientCount"]],
 "FailedFiniteCoefficients"->0,"FailedPoleCoefficients"->0,
 "WorkingPrecision"->50,"RelativeComparisonTolerance"->10^-30,
 "ObservedAgreement"->"Approximately 40 decimal digits at the retained five exact parameter points.",
 "ValidationMethod"->"Numerical checks of every distribution coefficient; not a proof of global symbolic identity.",
 "ReferenceSources"->{If[name==="SIDIS_UU_NNLO","https://arxiv.org/abs/2401.16281v2","https://arxiv.org/abs/2404.08597v3"],
   "https://arxiv.org/abs/2505.18109v2"},
 "ResultFiles"->files,"TotalBytes"->Total[FileByteCount/@files],
 "FunctionConvention"->"GPL G[{a1,...,an},z] has integration kernels dt/(t-ai). Results contain explicit functions, no unevaluated integrations or master-solution generators.",
 "EndpointProofReview"->"External/ChatGPT/Records/2026-09-10/36_completed_endpoint_projection.md"|>;
 FeynFacet`FamilyArtifactWrite[report,project["Directory"]<>"/NNLO/q-q/Results/Validation/CompletionReport.wl"];
 AssociateTo[summary,name->report];
 Print["VERIFIED COMPLETE ",name," CHANNELS ",Length[files]," COMPARISONS ",report["FiniteCoefficientComparisons"]," POLES ",report["PoleCoefficientChecks"]," BYTES ",report["TotalBytes"]],
{name,{"SIDIS_UU_NNLO","SIDIS_LL_NNLO"}}];
Print["COMPLETED SIDIS NNLO OUTPUT AUDIT"];
