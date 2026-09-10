(* Scalar Laurent polynomials in commuting color and coupling factors. *)
BeginPackage["FeynFacet`"];
CollectDistributionColorFactors::usage=
 "CollectDistributionColorFactors[density,request] collects explicit delta, plus and regular coefficients in declared color variables, a coupling variable and optional external distribution factors. Integral definitions remain shared and must be independent of these factors.";
Begin["`Private`"];
$colorCoefficientSourceFile=$InputFileName;
Clear[colorCoefficientFail,colorLaurentRules];
colorCoefficientFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"DistributionColor"];
colorLaurentRules[expression_,targets_List,algebraicLookup_:(Function[j,None])]:=Module[
 {variables=Table[Unique["colorVariable"],{Length[targets]}],zero,reduce,combine,multiply,power,dependent,
  lookup=algebraicLookup,depends},
 zero=ConstantArray[0,Length[targets]];
 depends[j_]:=lookup[j]=!=None;
 dependent=Alternatives[Sequence@@variables,
   FeynFacetSolution`a[j_Integer]/;depends[j]];
 (* Sparse Laurent polynomials in the requested factors only. Kinematic
    expressions remain coefficients and are never expanded into a second,
    potentially enormous polynomial ring. *)
 combine[records_List]:=Select[
   ({First[First[#]],Total[Last/@#]})&/@GatherBy[records,First],Last[#]=!=0&];
 multiply[left_List,right_List]:=If[left==={}||right==={},{},
   combine[Flatten[Table[{a[[1]]+b[[1]],a[[2]] b[[2]]},{a,left},{b,right}],1]]];
 power[base_List,n_Integer]:=Module[{answer={{zero,1}},factor=base,k=n},
   While[k>0,If[OddQ[k],answer=multiply[answer,factor]];k=Quotient[k,2];
     If[k>0,factor=multiply[factor,factor]]];answer];
 reduce[x_]:=Which[
   x===0,{},
   MatchQ[x,FeynFacetSolution`a[_Integer]],With[{value=lookup[x[[1]]]},If[value===None,{{zero,x}},value]],
   FreeQ[x,dependent],{{zero,x}},
   MemberQ[variables,x],{{UnitVector[Length[targets],First[FirstPosition[variables,x]]],1}},
   Head[x]===Plus,Module[{free,dependentParts},
     free=Select[List@@x,FreeQ[#,dependent]&];
     dependentParts=Select[List@@x,!FreeQ[#,dependent]&];
     combine[Join[If[free==={},{},{{zero,Total[free]}}],Flatten[reduce/@dependentParts,1]]]],
   Head[x]===Times,Module[{free,dependentParts},
     free=Select[List@@x,FreeQ[#,dependent]&];
     dependentParts=Select[List@@x,!FreeQ[#,dependent]&];
     Fold[multiply,{{zero,Times@@free}},reduce/@dependentParts]],
   Head[x]===Power&&IntegerQ[x[[2]]]&&x[[2]]>=0,power[reduce[x[[1]]],x[[2]]],
   Head[x]===Power&&IntegerQ[x[[2]]]&&x[[2]]<0,Module[{base=reduce[x[[1]]]},
     If[Length[base]=!=1,colorCoefficientFail["LaurentColorMonomialDenominatorRequired"]];
     {{x[[2]] base[[1,1]],base[[1,2]]^x[[2]]}}],
   True,colorCoefficientFail["ScalarLaurentColorDependenceRequired",<|"ExpressionHead"->Head[x]|>]];
 reduce[expression/.Thread[targets->variables]]
];
colorIndependentCoefficientJob[task_]:=Catch[
 First[task]->colorLaurentRules[task[[2]],task[[3]]],"DistributionColor"];
colorIndependentCoefficients[definitions_,targets_,workers_] := Module[{indices,kernels={},result},
 indices=Select[Range[Length[definitions]],!FreeQ[definitions[[#]],Alternatives@@targets]&&
   FreeQ[definitions[[#]],_FeynFacetSolution`a]&];
 If[indices==={},Return[<||>]];
 If[Kernels[]=!={},colorCoefficientFail["IndependentColorWorkerPoolRequired"]];
 Internal`WithLocalSettings[Null,
  kernels=facetLaunchKernels[Min[workers,Length[indices]]];
  If[Length[kernels]=!=Min[workers,Length[indices]],colorCoefficientFail["ColorWorkersUnavailable"]];
  With[{file=$colorCoefficientSourceFile},ParallelEvaluate[
   $HistoryLength=0;$MaxExtraPrecision=50;
   SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];Get[file];True,kernels]];
  result=ParallelMap[colorIndependentCoefficientJob,({#,definitions[[#]],targets}&/@indices),
    Method->"FinestGrained",DistributedContexts->None],
  If[kernels=!={},CloseKernels[kernels]]];
 If[!ListQ[result]||!AllTrue[result,MatchQ[#,_Rule]&]||Length[result]=!=Length[indices],
  colorCoefficientFail["ColorWorkerResultsIncomplete",<|"Failures"->Select[result,FailureQ]|>]];
 Association[result]
];
CollectDistributionColorFactors[data_Association,request_Association]:=Catch[Module[
 {colors,coupling,external,targets,nc,records={},parts,add,group,vector,
  values,components,lo,hi,delta,plus,regular,coefficients,i,q,range,
  expanded=<||>,expression,algebraicInput,deltaInput,plusInput,regularInput,refs,lookup,
  regulator=Lookup[data,"DimensionalRegulator",None],normal=Lookup[data,"NormalVariable",None],
  workers=Lookup[request,"Workers",1],verbose=TrueQ[Lookup[request,"Verbose",False]],
  timings=<||>,stageStarted=AbsoluteTime[],mark},
 mark[name_]:=(AssociateTo[timings,name->(AbsoluteTime[]-stageStarted)];stageStarted=AbsoluteTime[];
  If[verbose,Print["Color collection ",name,": ",timings[name]," s"]]);
 If[!IntegerQ[workers]||!TrueQ[1<=workers<=8],colorCoefficientFail["ColorWorkerCountMustBeOneThroughEight"]];
 If[Lookup[data,"DataType",None]=!="FiniteEndpointSubtractedDensity",
  colorCoefficientFail["FiniteEndpointSubtractedDensityRequired"]];
 colors=Lookup[request,"ColorVariables",{}];coupling=Lookup[request,"CouplingVariable",None];
 external=Lookup[request,"ExternalFactors",{}];
 If[colors==={}||!VectorQ[colors,MatchQ[#,_Symbol]&]||
   !MatchQ[coupling,None|_Symbol]||!ListQ[external],colorCoefficientFail["ColorAndCouplingVariablesRequired"]];
 targets=Join[colors,If[coupling===None,{},{coupling}],external];nc=Length[colors];
 If[!DuplicateFreeQ[targets],colorCoefficientFail["DistinctCoefficientFactorsRequired"]];
 If[(regulator=!=None&&!FreeQ[targets,regulator])||
   (normal=!=None&&!FreeQ[targets,normal]),
  colorCoefficientFail["RegulatorAndEndpointIndependentFactorsRequired"]];
 If[!FreeQ[KeyTake[data,{"IntegralDefinitions","KernelDefinitions"}],Alternatives@@targets],
  colorCoefficientFail["ColorIndependentIntegralDefinitionsRequired"]];
 (* Collect each color-dependent algebraic definition once, in dependency
    order. Substituting sparse color coefficients avoids repeatedly inlining
    the same large expression in every delta, plus and regular coefficient. *)
 {algebraicInput,deltaInput,plusInput,regularInput}=Lookup[data,
   {"AlgebraicDefinitions","DeltaTerms","PlusTerms","RegularRemainderCoefficients"}];
 lookup[j_]:=Lookup[expanded,j,None];
 mark["InputChecks"];
 If[workers>1,expanded=colorIndependentCoefficients[algebraicInput,targets,workers];
  If[verbose,Print["Independent color coefficients collected: ",Length[expanded]]]];
 mark["IndependentCoefficients"];
 Do[
  expression=algebraicInput[[i]];
  If[regulator=!=None&&!FreeQ[expression,regulator],
   colorCoefficientFail["EpsilonIndependentAlgebraicCoefficientsRequired",<|"AlgebraicIndex"->i|>]];
  refs=Cases[expression,FeynFacetSolution`a[j_]:>j,{0,Infinity}];
  If[!AllTrue[refs,IntegerQ[#]&&1<=#<i&],colorCoefficientFail["AcyclicAlgebraicColorDefinitionsRequired"]];
  If[!KeyExistsQ[expanded,i]&&(!FreeQ[expression,Alternatives@@targets]||AnyTrue[refs,KeyExistsQ[expanded,#]&]),
   AssociateTo[expanded,i->If[refs==={},colorLaurentRules[expression,targets],
     colorLaurentRules[expression,targets,lookup]]]];
  If[verbose&&Mod[i,10000]===0,Print["Color definitions collected: ",i,"/",Length[algebraicInput]]],
 {i,Length[algebraicInput]}];
 If[verbose,Print["Color-dependent algebraic definitions: ",Length[expanded]]];
 mark["AlgebraicDefinitions"];
 {lo,hi}=data["EpsilonOrderRange"];range=Range[lo,hi];
 add[kind_,index_,coefficients_Association]:=KeyValueMap[Function[{order,expression},
  If[!AllTrue[Cases[expression,FeynFacetSolution`a[j_]:>j,{0,Infinity}],
    IntegerQ[#]&&1<=#<=Length[algebraicInput]&],colorCoefficientFail["AlgebraicColorReferenceOutsideDefinitions"]];
  parts=colorLaurentRules[expression,targets,lookup];
  records=Join[records,({First[#],{kind,index,order},Last[#]}&/@parts)]],coefficients];
 Do[add["Delta",i,deltaInput[[i,"Coefficients"]]],{i,Length[deltaInput]}];
 If[verbose,Print["Delta color coefficients collected"]];
 mark["DeltaCoefficients"];
 Do[add["Plus",i,plusInput[[i,"Coefficients"]]],{i,Length[plusInput]}];
 If[verbose,Print["Plus color coefficients collected"]];
 mark["PlusCoefficients"];
 add["Regular",0,regularInput];
 If[verbose,Print["Regular color coefficients collected"]];
 mark["RegularCoefficients"];
 components=Table[
  vector=First[First[group]];values=Association[(#[[2]]->#[[3]])&/@group];
  delta=Table[Join[KeyDrop[deltaInput[[i]],"Coefficients"],<|"Coefficients"->
    Association@Table[q->Lookup[values,Key[{"Delta",i,q}],0],{q,range}]|>],{i,Length[deltaInput]}];
  plus=Table[Join[KeyDrop[plusInput[[i]],"Coefficients"],<|"Coefficients"->
    Association@Table[q->Lookup[values,Key[{"Plus",i,q}],0],{q,range}]|>],{i,Length[plusInput]}];
  regular=Association@Table[q->Lookup[values,Key[{"Regular",0,q}],0],{q,range}];
  <|"ColorFactor"->Times@@MapThread[Power,{colors,Take[vector,nc]}],
    "CouplingPower"->If[coupling===None,0,vector[[nc+1]]],
    "ExternalFactor"->Times@@MapThread[Power,{external,Take[vector,-Length[external]]}],
    "FactorPowers"->vector,"DeltaTerms"->delta,"PlusTerms"->plus,
    "RegularRemainderCoefficients"->regular|>,
 {group,GatherBy[records,First]}];
 mark["ComponentAssembly"];
 Join[data,<|"ColorVariables"->colors,"CouplingVariable"->coupling,
  "ExternalFactors"->external,"PartonicChannel"->Lookup[request,"PartonicChannel",Missing["NotSpecified"]],
  "ColorComponents"->components,
  "ColorCollectionTimings"->timings,
  "ExpandedColorDependentAlgebraicDefinitions"->Sort[Keys[expanded]],
  "ColorDecompositionConvention"->"Each component multiplies its ColorFactor, CouplingVariable^CouplingPower and ExternalFactor. All finite integral definitions are shared with the full density."|>]
],"DistributionColor"];
CollectDistributionColorFactors[___]:=Failure["FiniteDensityAndColorRequestRequired",<||>];
End[];
EndPackage[];
