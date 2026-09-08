#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
Clear[x,t];
c=FeynFacetSolution`C;f=FeynFacetSolution`F;k=FeynFacetSolution`K;
data=<|"KinematicVariables"->{x},"BasePoint"->{0},"RequestedRows"->{1},
 "KernelDefinitions"->{<|"Index"->1,"Parameter"->t,"Expression"->x/(1-x t)|>},
 "IntegralDefinitions"->{
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]|>,
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t] f[1,t]|>},
 "AlgebraicDefinitions"->{},
 "Coefficients"-><|0->{1->{1}},1->{1->{f[1,1]}},2->{1->{f[2,1]}}|>,
 "MasterIntegralCoefficients"-><|0->{1->c[1,0]},1->{1->f[1,1] c[1,0]+c[1,1]},
  2->{1->f[2,1] c[1,0]+f[1,1] c[1,1]+c[1,2]}|>|>;
ev[dd_,pt_,opts___] := FeynFacetSolution`EvaluateMasterIntegralSolution[dd,pt,opts];

prepared=FeynFacetSolution`PrepareMasterIntegralSolution[data,"NumericalBackend"->"FLINT"];
compiled=ev[prepared,{4/5},"NumericalBackend"->"FLINT","AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["compiled integration preserves the analytic nested logarithm",
 AssociationQ[compiled]&&Abs[compiled["EpsilonCoefficients"][2][[1,1]]-N[Log[5]^2/2,60]]<10^-25];
FTAssert["failed order refinements reuse their previous higher-order evaluation",
 compiled["ReusedEvaluationCount"]>0];
altered=Join[prepared,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->2 x/(1-x t)|>}|>];
changed=ev[altered,{1/2},"NumericalBackend"->"FLINT"];
FTAssert["changing prepared definitions rebuilds the numerical arithmetic",
 AssociationQ[changed]&&Abs[changed["EpsilonCoefficients"][1][[1,1]]-N[2 Log[2],50]]<10^-20];
elementary=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,
 "Expression"->Pi+E+Sqrt[x]+Log[x]+ArcTanh[x/3]+ArcTan[x/3]+Sin[x t]|>}|>];
left=ev[elementary,{-1+I/5},"NumericalBackend"->"FLINT","AccuracyGoal"->25,"PrecisionGoal"->25];
right=ev[elementary,{-1+I/5},"NumericalBackend"->"Wolfram","AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["complex elementary functions agree with the reference implementation",
 AssociationQ[left]&&AssociationQ[right]&&Max[Abs[Flatten[Values[left["EpsilonCoefficients"]]]-
 Flatten[Values[right["EpsilonCoefficients"]]]]]<10^-25];
unsupported=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->BesselJ[0,x t]|>}|>];
fallback=FeynFacetSolution`PrepareMasterIntegralSolution[unsupported];
FTAssert["unsupported compiled expressions retain the arbitrary-precision Wolfram evaluator",
 AssociationQ[fallback]&&fallback["NumericalPreparation"]["Backend"]==="Wolfram"];
FTAssert["forcing an unsupported compiled expression gives an explicit failure",
 FailureQ[FeynFacetSolution`PrepareMasterIntegralSolution[unsupported,"NumericalBackend"->"FLINT"]]];
single=ev[prepared,{1/2},"Threads"->1,"CheckConvergence"->False];
threaded=ev[prepared,{1/2},"Threads"->8,"CheckConvergence"->False];
FTAssert["parallel kernel-node evaluation agrees with one thread",
 single["EpsilonCoefficients"]===threaded["EpsilonCoefficients"]];
dir=CreateDirectory[];
Export[FileNameJoin[{dir,"solution.wxf"}],data,"WXF"];
batch=FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[{
 <|"SolutionDirectory"->dir,"Point"->{1/3}|>,
 <|"SolutionDirectory"->dir,"Point"->{2}|>,
 <|"SolutionDirectory"->dir,"Point"->{1/2}|>},"Workers"->2];
FTAssert["independent batch failures preserve order and successful results",
 AssociationQ[batch]&&batch["Status"]==="CompletedWithFailures"&&
 (Lookup[batch["Results"],"RequestIndex"]==={1,2,3})&&
 AssociationQ[batch["Results"][[1,"Result"]]]&&FailureQ[batch["Results"][[2,"Result"]]]&&
 AssociationQ[batch["Results"][[3,"Result"]]]];
FTAssert["batch evaluation uses separate persistent worker processes",
 Length[DeleteDuplicates[Lookup[batch["Results"],"WorkerProcessID"]]]===2];
DeleteDirectory[dir,DeleteContents->True];

FTAssert["arithmetic uncertainty remains nonzero beyond machine exponent range",
 FeynFacetSolution`Private`numericAbsoluteUncertainty[N[1,500]]>0&&
 FeynFacetSolution`Private`numericAbsoluteUncertainty[N[1,500]]<10^-490];
FTAssert["parallel tasks cannot overwrite the same output file",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[{
  <|"OutputFile"->"/tmp/feynfacet-duplicate-output.wxf"|>,
  <|"OutputFile"->"/tmp/feynfacet-duplicate-output.wxf"|>}],
 Failure["NumericalBatchOutputPathsInvalid",_]]];
FTReport[];
