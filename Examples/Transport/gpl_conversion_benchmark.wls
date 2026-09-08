#!/usr/bin/env wolframscript
(* Generate a rational control or an explicitly identified closed subsystem
   of the existing CF254 prepared DE. No physical boundary values are asserted. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{$Output={}},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/FeynFacet/Solution.m"];
args=Rest[$ScriptCommandLine];
If[!MemberQ[{1,2},Length[args]]||!MemberQ[{"rational","two-root"},args[[1]]],
 Print["Expected rational|two-root [OUTPUT_DIRECTORY]"];Exit[2]];
directory=ExpandFileName[If[Length[args]===2,args[[2]],
 FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","GPL_2026-09-06",
  If[args[[1]]==="rational","RationalControl","CF254"]}]]];
If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
If[args[[1]]==="rational",
 Clear[x,eps];
 system=<|"Family"->"Rational logarithmic control","KinematicVariables"->{x},
  "DimensionalRegulator"->eps,"ConnectionMatrices"->{{{eps/(1-x)}}}|>;
 base={0};point={4/5};orders=Range[0,4];rows={1};n=1;pullback=0,
 source=FeynFacetSolution`ReadMasterIntegralSolution[root<>
  "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06/CF254/FiniteSolution"];
 If[FailureQ[source],Print[source];Exit[1]];
 sourceRows={1,2,3,4,5,6,7,8,9,10,17,18,19};n=Length[sourceRows];
 remaining=Complement[Range[Length[source["PreparedConnectionMatrices"][[1]]]],sourceRows];
 If[!AllTrue[Flatten[source["PreparedConnectionMatrices"][[All,sourceRows,remaining]]],#===0&],
  Print["Requested subsystem is not closed"];Exit[1]];
 system=<|"Family"->"CF254 prepared closed subsystem","KinematicVariables"->source["KinematicVariables"],
  "DimensionalRegulator"->source["DimensionalRegulator"],
  "ConnectionMatrices"->source["PreparedConnectionMatrices"][[All,sourceRows,sourceRows]],
  "OriginalMasterIntegralBasis"->(PreparedBasisRow/@sourceRows)|>;
 base={1/4,4};point={251/1000,401/100};orders={0,1};rows={9};
 pullback=First[AbsoluteTiming[
  system=PullBackMasterIntegralDifferentialSystem[system,RationalizingParametrizationCatalog[]["Kallen13"],base]]];
 If[FailureQ[system],Print[system];Exit[1]]
];
request=<|"BasePoint"->base,"RequestedEpsilonOrders"->orders,"RequestedRows"->rows,
 "AnalyticDomain"->"A nonsingular neighborhood containing the stated test path.",
 "BranchPrescription"->"Continuous roots from principal source values at the base point."|>;
construction=First[AbsoluteTiming[
 solution=ConstructMasterIntegralSolution[system,request,"AutomaticPreparation"->False]]];
If[FailureQ[solution],Print[solution];Exit[1]];
solution=ExpandMasterIntegralSolutionInInitialConstants[solution,ConstantArray[0,n],orders];
constants=Flatten[Table[FeynFacetSolution`C[j,k]->If[k===0,j/17,0],{j,n},{k,orders}]];
write=WriteMasterIntegralSolution[solution,directory,"FileFormat"->"WXF"];
If[FailureQ[write],Print[write];Exit[1]];
benchmark=<|"ConvertedSolutionDirectory"->FileNameJoin[{directory,"GPL"}],"Point"->point,"Repeats"->3,"InitialConstantValues"->constants,
 "ConversionOptions"->{"TimeLimit"->90,"FunctionTimeLimit"->20,"MaxExpressionLeaves"->1000000},
 "EvaluationOptions"->{"AccuracyGoal"->25,"PrecisionGoal"->25},
 "TaylorOptions"->{"TaylorOrder"->If[args[[1]]==="rational",128,20],"ParameterRadius"->1,
  "AccuracyGoal"->25,"PrecisionGoal"->25,"TimeLimit"->60}|>;
Put[benchmark,directory<>"/request.wl"];
Put[<|"Source"->args[[1]],"SourceRows"->If[args[[1]]==="two-root",sourceRows,{1}],
 "PullbackSeconds"->pullback,"ConstructionSeconds"->construction,
 "FiniteIntegralCount"->Length[solution["IntegralDefinitions"]]|>,directory<>"/construction.wl"];
Print["BENCHMARK_INPUT ",directory," pullback=",pullback," construction=",construction];
