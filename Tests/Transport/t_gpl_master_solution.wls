#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
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
converted=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data];
FTAssert["all required finite integrals become explicit GPLs",
 converted["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL"&&
 Length[converted["GPLRepresentation"]["IntegralExpressions"]]===2&&
 FreeQ[converted["GPLRepresentation"]["IntegralExpressions"],_FeynFacetSolution`F|_FeynFacetSolution`K]];
FTAssert["source finite coefficients and definitions remain unchanged",
 KeyDrop[converted,{"GPLRepresentation"}]===data];
num=FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{1/2},"NumericalBackend"->"GiNaC","AccuracyGoal"->30,"PrecisionGoal"->30];
FTAssert["explicit GiNaC evaluation uses the GPL representation",
 AssociationQ[num]&&num["NumericalBackend"]==="GiNaC"&&
 Abs[num["EpsilonCoefficients"][2][[1,1]]-N[Log[2]^2/2,80]]<10^-30];
default=FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{1/2}];
FTAssert["adding a GPL representation preserves the automatic FLINT selection",
 AssociationQ[default]&&default["NumericalBackend"]==="FLINT"];
base=FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{0},"NumericalBackend"->"GiNaC"];
FTAssert["stationary base-point values do not evaluate infinite GPL letters",
 AssociationQ[base]&&Flatten[Values[base["EpsilonCoefficients"]]]=={1,0,0}];
again=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[converted];
FTAssert["successful conversion reuses finite expressions",again["GPLRepresentation"]["ReusedIntegralExpressions"]===2];
changed=Join[converted,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->2 x/(1-x t)|>}|>];
FTAssert["explicit GPL evaluation refuses changed source definitions",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[changed,{1/2},"NumericalBackend"->"GiNaC"],
  Failure["GPLSourceDefinitionsChanged",_]]];
auto=FeynFacetSolution`EvaluateMasterIntegralSolution[changed,{1/2}];
FTAssert["automatic evaluation falls back to the changed finite integral",
 AssociationQ[auto]&&auto["NumericalBackend"]=!="GiNaC"&&
 Abs[auto["EpsilonCoefficients"][1][[1,1]]-N[2 Log[2],60]]<10^-20];
mixed=Join[data,<|"IntegralDefinitions"->Append[data["IntegralDefinitions"],
 <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->Exp[t]|>],
 "Coefficients"-><|0->{1->{f[1,1]}},1->{1->{f[3,1]}}|>|>];
partial=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[mixed];
FTAssert["unsupported integrals remain explicit and are not labelled converted",
 partial["GPLRepresentation"]["Status"]==="PartiallyConvertedToGPL"&&
 partial["IntegralDefinitions"]===mixed["IntegralDefinitions"]&&
 MemberQ[Lookup[partial["GPLRepresentation"]["UnconvertedIntegrals"],"Index"],3]];
constants={c[1,0]->10^50,c[1,1]->1-10^50 Log[2],c[1,2]->0};
precise=FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{1/2},
 "NumericalBackend"->"GiNaC","InitialConstantValues"->constants,"AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["precision is refined after cancellation with boundary coefficients",
 AssociationQ[precise]&&Length[precise["WorkingPrecisions"]]>=3&&
 Abs[(1/.precise["MasterIntegralEpsilonCoefficients"][1])-1]<10^-25];
FTAssert["invalid numerical options are refused by the GPL backend",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{1/2},"NumericalBackend"->"GiNaC","AccuracyGoal"->-1],
 Failure["InvalidNumericalParameters",_]]];
directory=CreateDirectory[];
Export[FileNameJoin[{directory,"solution.wxf"}],converted,"WXF"];
read=FeynFacetSolution`ReadMasterIntegralSolution[directory];
FTAssert["stored GPL expressions load without rerunning conversion",read===converted];
batch=FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[{
 <|"SolutionDirectory"->directory,"Point"->{1/3},"EvaluationOptions"->{"NumericalBackend"->"GiNaC"}|>,
 <|"SolutionDirectory"->directory,"Point"->{1/2},"EvaluationOptions"->{"NumericalBackend"->"GiNaC"}|>},"Workers"->2];
FTAssert["GPL evaluation works in the existing parallel batch path",
 batch["Status"]==="Completed"&&AllTrue[batch["Results"],#["Result"]["NumericalBackend"]==="GiNaC"&]];
DeleteDirectory[directory,DeleteContents->True];
pole=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->1/(t-1/2)^2|>}|>];
pole=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[pole];
FTAssert["Hermite reduction does not erase a source contour pole",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[pole,{1},"NumericalBackend"->"GiNaC"],
 Failure["IntegrationPathMeetsSingularity",_]]];
special=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->1/(t+x)|>}|>];
special=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[special];
FTAssert["specializing a nonzero letter to zero cannot regularize a divergent source integral",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[special,{0},"NumericalBackend"->"GiNaC"],
 Failure["IntegrationPathMeetsSingularity",_]]];
shifted=data;shifted["IntegralDefinitions"]=ReplacePart[data["IntegralDefinitions"],
 {2,"Integrand"}->f[1,t^2]];
FTAssert["nonidentity nested arguments are rejected before conversion",
 MatchQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[shifted],
 Failure["IntegralDependencyNotSupported",_]]];
hidden=data;hidden["KernelDefinitions"]=ReplacePart[data["KernelDefinitions"],
 {1,"Expression"}->f[1,t]];
FTAssert["kernel definitions cannot hide integral dependencies",
 MatchQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[hidden],
 Failure["KernelDefinitionCannotDependOnIntegral",_]]];
cross=Join[data,<|"KernelDefinitions"->{<|"Parameter"->t,"Expression"->Log[(1+2 I t)^4]|>}|>];
cross=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[cross];
FTAssert["a principal-log cut crossing is not erased by logarithmic differentiation",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[cross,{1},"NumericalBackend"->"GiNaC"],
 Failure["SourcePrincipalBranchCutOnPath",_]]];
FTAssert["approximate kinematic inputs require sensitivity handling rather than exact rationalization",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[converted,{N[1/2,80]},"NumericalBackend"->"GiNaC"],
 Failure["GPLExactKinematicInputsRequired",_]]];
badSchema=converted;badSchema["GPLRepresentation"]=Join[converted["GPLRepresentation"],<|"SchemaVersion"->17|>];
FTAssert["GPL schema is validated before reuse",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[badSchema,{1/2},"NumericalBackend"->"GiNaC"],
 Failure["GPLSourceDefinitionsChanged",_]]];
duplicate=Join[data,<|"IntegralDefinitions"->{
 <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]|>,
 <|"IntegrationVariable"->u,"LowerLimit"->0,"Integrand"->k[1,u]|>},
 "MasterIntegralCoefficients"-><||>|>];
beforeMemo=DownValues[FeynFacetSolution`Private`gplIntegrateWord];
duplicate=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[duplicate];
FTAssert["identical integrands with different dummy variables are integrated once",
 duplicate["GPLRepresentation"]["DistinctIntegrandsAttempted"]===1&&
 duplicate["GPLRepresentation"]["RepeatedIntegrandsReused"]===1&&
 SameQ@@Values[duplicate["GPLRepresentation"]["IntegralExpressions"]]];
FTAssert["conversion memoization leaves no persistent recurrence definitions",
 DownValues[FeynFacetSolution`Private`gplIntegrateWord]===beforeMemo];
partialAgain=converted;
partialAgain["GPLRepresentation"]["IntegralExpressions"]=KeyTake[
 converted["GPLRepresentation"]["IntegralExpressions"],{1}];
partialAgain=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[partialAgain];
FTAssert["partial GPL conversion resumes with exact sources",
 partialAgain["GPLRepresentation"]["ReusedIntegralExpressions"]===1&&
 partialAgain["GPLRepresentation"]["IntegralExpressions"]===converted["GPLRepresentation"]["IntegralExpressions"]];
otherAssumptions=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[converted,"Assumptions"->x>0];
FTAssert["unconditional expressions remain valid on a restricted parameter domain",
 otherAssumptions["GPLRepresentation"]["ReusedIntegralExpressions"]===2&&
 otherAssumptions["GPLRepresentation"]["Assumptions"]===(x>0)];
incompatibleAssumptions=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[
 otherAssumptions,"Assumptions"->x<0];
FTAssert["a changed restricted domain does not reuse assumption-dependent expressions",
 incompatibleAssumptions["GPLRepresentation"]["ReusedIntegralExpressions"]===0];
strongerAssumptions=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[
 otherAssumptions,"Assumptions"->x>0&&y>0];
FTAssert["reuse on a stronger domain requires an established implication",
 strongerAssumptions["GPLRepresentation"]["ReusedIntegralExpressions"]===2];
FTReport[];
