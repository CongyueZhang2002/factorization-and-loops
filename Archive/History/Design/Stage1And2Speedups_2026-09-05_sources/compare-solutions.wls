
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected OLD_RESULTS_DIRECTORY NEW_RESULTS_DIRECTORY"];Exit[2]];
oldDirectory=ExpandFileName[args[[1]]];newDirectory=ExpandFileName[args[[2]]];
reports={};
Do[
 old=Import[oldDirectory<>"/"<>family<>"/solution.wxf","WXF"];
 new=Import[newDirectory<>"/"<>family<>"/solution.wxf","WXF"];
 keys={"BasePoint","OriginalMasterIntegralBasis","RequestedMasterIntegralOrderRanges",
 "RequestedEpsilonOrders","TransformedSystemEpsilonOrderRange",
 "TransformedCoefficientUpperOrders","RequiredInitialConstantCoefficients",
 "BasisConvolutionCoefficients","AlgebraicDefinitions","Coefficients","MasterIntegralCoefficients"};
 same=KeyTake[old,keys]===KeyTake[new,keys];
 maxRelative=0;ok=Length[old["IntegralDefinitions"]]===Length[new["IntegralDefinitions"]];
 duration=First[AbsoluteTiming[
 Do[
  vars=new["KinematicVariables"];t=new["Path"]["Parameter"];
  point=new["BasePoint"]+Table[(j+i)/(200 (i+1)),{i,Length[vars]}];
  rules=N[Append[Thread[vars->point],t->({1/3,2/3}[[j]])],65];
  ov=FeynFacet`Private`solutionEvaluateKernelDefinitions[old["KernelDefinitions"],rules,65];
  nv=FeynFacet`Private`solutionEvaluateKernelDefinitions[new["KernelDefinitions"],rules,65];
  Do[
   of=old["IntegralDefinitions"][[i]];nf=new["IntegralDefinitions"][[i]];
   ob=N[(of["Integrand"]/.FeynFacetSolution`K[k_Integer,_]:>ov[[k]])/.
     of["IntegrationVariable"]->FeynFacetSolution`s,65];
   nb=N[(nf["Integrand"]/.FeynFacetSolution`K[k_Integer,_]:>nv[[k]])/.
     nf["IntegrationVariable"]->FeynFacetSolution`s,65];
   fs=DeleteDuplicates[Cases[{ob,nb},_FeynFacetSolution`F,Infinity]];
   oc=Append[Coefficient[ob,#]& /@ fs,ob/._FeynFacetSolution`F->0];
   nc=Append[Coefficient[nb,#]& /@ fs,nb/._FeynFacetSolution`F->0];
   If[!VectorQ[Join[oc,nc],NumericQ],ok=False;Break[]];
   rel=Max[Abs[oc-nc]]/Max[1,Max[Abs[oc]],Max[Abs[nc]]];
   maxRelative=Max[maxRelative,rel],
  {i,Length[new["IntegralDefinitions"]]}],
 {j,2}]]];
 report=<|"Family"->family,"SameOrdersBasisConvolutionsAndMasterCoefficients"->same,
 "AllIntegralDefinitionsCompared"->ok,"RationalPointCount"->2,"WorkingPrecision"->65,
 "MaximumRelativeCoefficientDifference"->N[maxRelative,8],"ComparisonSeconds"->duration|>;
 AppendTo[reports,report];Print[InputForm[report]];
 Export[FileNameJoin[{$TemporaryDirectory,"feynfacet-solution-comparison.json"}],reports,"RawJSON"];
 If[!TrueQ[same && ok && maxRelative<10^-45],Exit[1]];
 Clear[old,new,ov,nv],
{family,{"CF269","CF48","CF265","CF259","CF303"}}];
