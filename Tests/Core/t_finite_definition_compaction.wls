root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;Get[root<>"/FeynFacet/Solution.m"];passed=0;failed=0;
check[label_,test_]:=If[TrueQ[test],passed++;Print["PASS ",label],failed++;Print["FAIL ",label]];
source=<|"KernelDefinitions"->{<|"Index"->1,"Parameter"->tt,"Expression"->1/(1-tt),"Kind"->"ScalarExpression"|>,
 <|"Index"->2,"Parameter"->tt,"Expression"->1/(1-tt),"Kind"->"ScalarExpression"|>},
 "IntegralDefinitions"->{<|"Index"->1,"IntegrationVariable"->tt,"UpperLimitVariable"->uu,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[1,tt]|>,
 <|"Index"->2,"IntegrationVariable"->tt,"UpperLimitVariable"->uu,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[2,tt]|>},
 "AlgebraicDefinitions"->{3,3,FeynFacetSolution`a[1]+FeynFacetSolution`F[1,zz],FeynFacetSolution`a[2]+FeynFacetSolution`F[2,zz]}|>;
compact=FeynFacetSolution`CompactFiniteSolutionDefinitions[source,FeynFacetSolution`a[3]+FeynFacetSolution`a[4]];
check["dependency remapping exposes repeated definitions",Length /@ Lookup[compact,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}]==={1,1,2}];
check["explicit output preserved",compact["Expressions"]===2FeynFacetSolution`a[2]];
check["finite integral preserved",compact["IntegralDefinitions"][[1,"Integrand"]]===FeynFacetSolution`K[1,tt]];
changed=source;changed["IntegralDefinitions"]=ReplacePart[changed["IntegralDefinitions"],{2,"LowerLimit"}->1];
other=FeynFacetSolution`CompactFiniteSolutionDefinitions[changed,FeynFacetSolution`a[3]+FeynFacetSolution`a[4]];
check["different integration endpoints remain distinct",Length[other["IntegralDefinitions"]]===2];
changed=source;changed["KernelDefinitions"]=ReplacePart[changed["KernelDefinitions"],{2,"Kind"}->"DifferentSemanticKind"];
other=FeynFacetSolution`CompactFiniteSolutionDefinitions[changed,FeynFacetSolution`a[3]+FeynFacetSolution`a[4]];
check["all defining fields participate",Length[other["KernelDefinitions"]]===2];
changed=source;changed["AlgebraicDefinitions"]={FeynFacetSolution`a[2],3};
check["forward algebraic references rejected",FailureQ[FeynFacetSolution`CompactFiniteSolutionDefinitions[changed,FeynFacetSolution`a[1]]]];
changed=source;changed["KernelDefinitions"]=ReplacePart[changed["KernelDefinitions"],{1,"Expression"}->FeynFacetSolution`F[1,tt]];
check["kernel cannot depend on an integral",FailureQ[FeynFacetSolution`CompactFiniteSolutionDefinitions[changed,FeynFacetSolution`a[1]]]];
check["unreachable definitions removed",Length[ FeynFacetSolution`CompactFiniteSolutionDefinitions[source,7]["AlgebraicDefinitions"]]===0];
audit=FeynFacetSolution`VerifyFiniteSolutionCompaction[source,FeynFacetSolution`a[3]+FeynFacetSolution`a[4],compact];
check["whole output and retained definitions verify exactly",audit["Status"]==="Passed"];
broken=compact;broken["AlgebraicDefinitions"]=ReplacePart[broken["AlgebraicDefinitions"],1->4];
check["changed defining value rejected by independent check",FailureQ[FeynFacetSolution`VerifyFiniteSolutionCompaction[source,FeynFacetSolution`a[3]+FeynFacetSolution`a[4],broken]]];
scoped=Join[source,<|"DefinitionSemanticContexts"-><|"Kernel"->{"AboveCut","BelowCut"},"Integral"->{"AboveCut","BelowCut"},"Algebraic"->{0,0,"AboveCut","BelowCut"}|>|>];
other=FeynFacetSolution`CompactFiniteSolutionDefinitions[scoped,FeynFacetSolution`a[3]+FeynFacetSolution`a[4]];
check["different global paths never merge",Length[other["KernelDefinitions"]]===2&&Length[other["IntegralDefinitions"]]===2];
check["reference-bearing association keys rejected",FailureQ[FeynFacetSolution`CompactFiniteSolutionDefinitions[source,<|FeynFacetSolution`a[1]->2,FeynFacetSolution`a[2]->3|>]]];
changed=source;changed["AlgebraicDefinitions"]={1.0};
check["approximate semantic values rejected",FailureQ[FeynFacetSolution`CompactFiniteSolutionDefinitions[changed,FeynFacetSolution`a[1]]]];
Get[root<>"/FeynFacet/Coefficients/DistributionStorage.wl"];
distribution=Join[source,<|"DataType"->"FinitePartonicDistributions","PhysicalDomain"->0<vv<1,
 "Expression"->999,"ColorComponents"->{<|"ColorFactor"->cc,"CouplingPower"->3,"ExternalFactor"->1,
  "DeltaTerms"->{FeynFacetSolution`a[3]+FeynFacetSolution`a[4]},"PlusTerms"->{},"RegularRemainderCoefficients"->{0}|>}|>];
final=FeynFacet`CompactFiniteDistributionResult[distribution];
check["final distribution stores only required coefficient views",AssociationQ[final]&&!KeyExistsQ[final,"Expression"]];
roundtrip=BinaryDeserialize[BinarySerialize[final,PerformanceGoal->"Size"]];
check["saved compact expression and all source metadata verify",FeynFacet`VerifyFiniteDistributionCompaction[distribution,roundtrip]["Status"]==="Passed"];
broken=roundtrip;broken["PhysicalDomain"]=0<vv<2;
check["changed physical domain rejected",FailureQ[FeynFacet`VerifyFiniteDistributionCompaction[distribution,broken]]];
broken=roundtrip;broken["KernelDefinitions"]=ReplacePart[broken["KernelDefinitions"],{1,"Index"}->9];
check["changed serialized definition index rejected",FailureQ[FeynFacet`VerifyFiniteDistributionCompaction[distribution,broken]]];
Print["FINITE_DEFINITION_COMPACTION_TESTS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
