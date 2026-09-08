(* Standalone reader/evaluator: no FeynCalc, diagrams or epsilon form. *)
BeginPackage["FeynFacetSolution`"];
ReadMasterIntegralSolution::usage="ReadMasterIntegralSolution[directory] reads the explicit finite solution and its mathematical definitions.";
EvaluateMasterIntegralSolution::usage="EvaluateMasterIntegralSolution[data,point] evaluates the saved solution with supplied initial constants, using Wolfram, FLINT or an explicit GPL representation.";
PruneFiniteSolutionDefinitions::usage="PruneFiniteSolutionDefinitions[data, expressions] retains and renumbers the finite scalar definitions actually used by the expressions.";
ResolveSharedBoundaryDefinitions::usage="ResolveSharedBoundaryDefinitions[solution, sharedData] substitutes already stored boundary coefficients and their finite scalar definitions.";
Begin["`Private`"];
$finiteSolutionDirectory=DirectoryName[ExpandFileName[$InputFileName]];
$solutionModules=Get[FileNameJoin[{$finiteSolutionDirectory,"Kernel","Modules.wl"}]];
$solutionModulePaths=Join[$solutionModules["SolutionData"],$solutionModules["Solution"]];
If[!MatchQ[$solutionModulePaths,{__String}] || !DuplicateFreeQ[$solutionModulePaths],
 Print["FeynFacetSolution: invalid module manifest"];Abort[]];
Scan[Function[path,With[{file=FileNameJoin[{$finiteSolutionDirectory,path}]},
 If[!FileExistsQ[file] || Check[Get[file],$Failed,{Get::noopen,Syntax::sntx,Syntax::sntxf,Syntax::sntxi}]===$Failed,Abort[]]]],$solutionModulePaths];
End[];
EndPackage[];
