#!/usr/bin/env wolframscript
(* Compare stored finite expressions with AMFlow's independent local-series
   solver on the original rational DE, after diagonal epsilon rescaling.
   The supplied test boundary is an explicitly finite Laurent polynomial.
   This does not perform auxiliary mass flow or validate physical constants. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
$PrePrint=.;
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]!=3,Print["Expected SOLUTION_DIRECTORY REQUEST.wl REPORT.wxf"];Exit[2]];
request=FeynFacetRecords`ReadRecord[args[[2]]];
data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];
point=request["Point"];precision=Lookup[request,"WorkingPrecision",90];
goal=Lookup[request,"AccuracyGoal",30];seriesOrder=Lookup[request,"SeriesOrder",70];
boundary=request["TestBoundaryPolynomial"];e=data["DimensionalRegulator"];
nn=data["InitialConstants"]["Count"];
If[!ListQ[boundary]||Length[boundary]!=nn,Print["Explicit full test boundary polynomial required"];Exit[2]];
Get[request["AMFlowDESolverPath"]];
DESolver`SetDefaultOptions[];
DESolver`SetGlobalOptions["Solver"->"MMA","WorkingPre"->precision,"ChopPre"->precision-15,"SilentMode"->True];
DESolver`SetExpansionOptions["XOrder"->seriesOrder,"ExtraXOrder"->15];
result=TimeConstrained[Catch[Module[
 {a,rs,shifts,xrules,connection,low,high,rows,orders,b,polynomial,coefficientMatrices,
  lift,vector,run,answer,reference,constants,evaluated,errors={},start=AbsoluteTime[],
  deSeconds,quadSeconds,report,key,rr,target,q,dimension,normalizedLift},
 a=Normal/@data["OriginalConnectionMatrices"];
 rs=FeynFacet`FindEpsilonRescaling[a,e];
 If[FailureQ[rs],Throw[rs]];
 shifts=rs["EpsilonShifts"];
 xrules=Thread[data["KinematicVariables"]->(data["BasePoint"]+
   DESolver`eta (point-data["BasePoint"]))];
 connection=Map[Cancel,Sum[(point-data["BasePoint"])[[i]] a[[i]],{i,Length[a]}]/.xrules,{2}];
 b=Map[Cancel,DiagonalMatrix[e^-shifts].connection.DiagonalMatrix[e^shifts],{2}];
 rows=Keys[data["RequestedMasterIntegralOrderRanges"]];
 low=Min[MapThread[If[#1===0,Infinity,Exponent[Expand[#1 e^-#2],e,Min]]&,{boundary,shifts}]];
 high=Max[Map[Last[data["RequestedMasterIntegralOrderRanges"][#]]-shifts[[#]]&,rows]];
 If[!IntegerQ[low]||high<low,Throw[Failure["TestBoundaryRangeUnsupported",<||>]]];
 orders=Range[low,high];dimension=nn Length[orders];
 Print["LIFT ",dimension," epsilon range ",{low,high}," shifts ",shifts];
 polynomial=Map[Normal[Series[#,{e,0,high-low}]]&,b,{2}];
 coefficientMatrices=Table[SparseArray[Map[Coefficient[#,e,q]&,polynomial,{2}]],{q,0,high-low}];
 lift=Total[Table[KroneckerProduct[
  SparseArray[Table[{i+q,i}->1,{i,Length[orders]-q}],{Length[orders],Length[orders]}],
  coefficientMatrices[[q+1]]],{q,0,high-low}]];
 vector=Flatten[Table[Table[Coefficient[Expand[boundary[[i]] e^-shifts[[i]]],e,q],
   {i,nn}],{q,orders}]];
 normalizedLift=Map[Together,Normal[lift],{2}];
 deSeconds=First[AbsoluteTiming[
  DESolver`LoadSystem["finite-solution-comparison",normalizedLift,N[vector,precision],0];
  run=DESolver`RunSegment[DESolver`GetPoles[normalizedLift],0,1];
  If[run==={},Throw[Failure["AMFlowRegularPathNotFound",<||>]]];
  DESolver`RegularRun["finite-solution-comparison",run];
  answer=Partition[DESolver`BC["finite-solution-comparison"],nn];
  DESolver`ClearSystem["finite-solution-comparison"];
 ]];
 constants=Map[Function[p,FeynFacetSolution`C@@p->Coefficient[boundary[[First[p]]],e,Last[p]]],
  data["RequiredInitialConstantCoefficients"]];
 quadSeconds=First[AbsoluteTiming[
  evaluated=FeynFacetSolution`EvaluateMasterIntegralSolution[data,point,
   "InitialConstantValues"->constants,"WorkingPrecision"->precision,
   "AccuracyGoal"->goal,"PrecisionGoal"->goal,
   "TimeLimit"->Lookup[request,"TimeLimit",600]];
 ]];
 If[FailureQ[evaluated],Throw[evaluated]];
 Do[
  rr=Association[evaluated["MasterIntegralEpsilonCoefficients"][key]];
  Do[
   q=key-shifts[[row]];
   reference=If[q<low,0,If[q>high,Throw[Failure["ReferenceOrderMissing",<||>]],
     answer[[q-low+1,row]]]];
   target=rr[row];
   AppendTo[errors,<|"Row"->row,"EpsilonOrder"->key,"ReferenceValue"->reference,
    "StoredSolutionValue"->target,"AbsoluteDifference"->Abs[target-reference],
    "ToleranceRatio"->Abs[target-reference]/(10^-goal (1+Max[Abs[target],Abs[reference]]))|>],
  {row,Keys[rr]}],
 {key,Keys[evaluated["MasterIntegralEpsilonCoefficients"]]}];
 report=<|"Status"->If[Max[Lookup[errors,"ToleranceRatio"]]<=1,
   "AMFlowSeriesComparisonPassed","AMFlowSeriesComparisonFailed"],
  "Family"->data["Family"],"BasePoint"->data["BasePoint"],"Point"->point,
  "AccuracyGoal"->goal,"WorkingPrecision"->precision,"SeriesOrder"->seriesOrder,
  "EpsilonRescaling"->shifts,"LiftedSystemDimension"->dimension,
  "AMFlowDESolverSeconds"->deSeconds,"StoredSolutionEvaluationSeconds"->quadSeconds,
  "Comparisons"->errors,"NumericalEvaluation"->KeyDrop[evaluated,{"EpsilonCoefficients","MasterIntegralEpsilonCoefficients"}],
  "TestBoundaryPolynomial"->boundary,"ElapsedSeconds"->AbsoluteTime[]-start,
  "Scope"->"Independent local-series evaluation of the original DE for an explicitly supplied test boundary polynomial. No physical boundary or auxiliary-mass-flow check is claimed."|>;
 report
]],Lookup[request,"TimeLimit",600],Failure["ComparisonTimeLimit",<||>]];
Export[args[[3]],result,"WXF"];
Print["RESULT ",If[AssociationQ[result],InputForm[KeyDrop[result,{"Comparisons","TestBoundaryPolynomial","NumericalEvaluation"}]],InputForm[result]]];
If[AssociationQ[result],Print["MAXIMUM_TOLERANCE_RATIO ",Max[Lookup[result["Comparisons"],"ToleranceRatio"]]]];
Exit[If[AssociationQ[result]&&result["Status"]==="AMFlowSeriesComparisonPassed",0,1]];
