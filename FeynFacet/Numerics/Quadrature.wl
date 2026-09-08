$gaussCache={};
gaussIntegrationData[n_,precision_] := Module[{x,z,p,w,q,hit,result},
 hit=SelectFirst[$gaussCache,First[#]==={n,precision}&,None];
 If[hit=!=None,Return[Last[hit]]];
 z=Sort[x/.NSolve[LegendreP[n,x]==0,x,WorkingPrecision->precision]];
 p=Table[N[LegendreP[k,z[[i]]],precision],{k,0,n},{i,n}];
 w=Table[2(1-z[[i]]^2)/(n^2 p[[n,i]]^2),{i,n}];
 q=Table[w[[j]]/4 (z[[i]]+1+
    Sum[p[[k+1,j]](p[[k+2,i]]-p[[k,i]]),{k,1,n-1}]),{i,n},{j,n}];
 result=<|"Nodes"->(1+z)/2,"Weights"->w/2,"IndefiniteIntegrationMatrix"->q|>;
 $gaussCache=Take[Append[$gaussCache,{{n,precision},result}],-Min[12,Length[$gaussCache]+1]];
 result
];

finiteNumericQ[z_] := NumericQ[z] && FreeQ[z,Indeterminate|_DirectedInfinity];
finiteNumberQ[z_] := NumberQ[z] && FreeQ[z,Indeterminate|_DirectedInfinity];
numericalFailure[name_,details_:<||>] := Throw[Failure[name,details],"NumericalSolution"];

(* Integrate the already stored definitions on each panel. Earlier integrals
   retain their accumulated values at the beginning of every panel. *)
evaluateFinitePanelsWolfram[data_,point_,count_,precision_,breaks_] := Module[
 {grid,functions=data["IntegralDefinitions"],algebra=data["AlgebraicDefinitions"],
  vars=data["KinematicVariables"],pointRules,kernelDefs,kernelValues,values,ends,
  av,result,masterResult,resolve,kernelBodies,bodies,refs,body,nodes,width,samples,
  start,variable},
 grid=gaussIntegrationData[count,precision];
 pointRules=Thread[vars->N[point,precision]];
 kernelDefs=Lookup[data,"KernelDefinitions",{}];
 kernelBodies=(#["Expression"]/.pointRules)& /@ kernelDefs;
 bodies=(#["Integrand"]/.pointRules)& /@ functions;
 ends=ConstantArray[0,Length[functions]];
 Do[
  width=N[breaks[[panel+1]]-breaks[[panel]],precision];
  nodes=N[breaks[[panel]]+width grid["Nodes"],precision];
  kernelValues=ConstantArray[0,{Length[kernelDefs],count}];
  Do[
   body=kernelBodies[[i]];
   kernelValues[[i]]=Table[N[(body/.FeynFacetSolution`K[j_Integer,_]:>kernelValues[[j,k]])/.
    kernelDefs[[i,"Parameter"]]->nodes[[k]],precision],{k,count}];
   If[!VectorQ[kernelValues[[i]],finiteNumberQ],
    numericalFailure["KernelEvaluationNotFinite",<|"Index"->i,"Panel"->panel|>]],
  {i,Length[kernelDefs]}];
  values=ConstantArray[0,{Length[functions],count}];
  Do[
   variable=functions[[i,"IntegrationVariable"]];body=bodies[[i]];start=ends[[i]];
   samples=Table[N[(body/.{FeynFacetSolution`F[j_,_]:>values[[j,k]],
     FeynFacetSolution`K[j_,_]:>kernelValues[[j,k]]})/.variable->nodes[[k]],precision],{k,count}];
   If[!VectorQ[samples,finiteNumberQ],
    numericalFailure["IntegralEvaluationNotFinite",<|"Index"->i,"Panel"->panel|>]];
   values[[i]]=start+width grid["IndefiniteIntegrationMatrix"].samples;
   ends[[i]]=start+width grid["Weights"].samples,
  {i,Length[functions]}],
 {panel,Length[breaks]-1}];
 assembleFiniteResult[data,point,count,precision,breaks,ends]
];

(* Exact cancellations can make N emit very large meprec expressions.
   Finiteness, reported arithmetic uncertainty and refinement decide acceptance. *)
assembleFiniteResult[data_,point_,count_,precision_,breaks_,ends_] := Quiet[Module[
 {algebra=data["AlgebraicDefinitions"],av,result,masterResult,resolve,
  pointRules=Thread[data["KinematicVariables"]->N[point,precision]]},
 av=ConstantArray[0,Length[algebra]];
 Do[
  av[[i]]=N[algebra[[i]]/.{
   FeynFacetSolution`a[j_]:>If[IntegerQ[j]&&1<=j<i,av[[j]],
    numericalFailure["ArithmeticDependencyInvalid",<|"Index"->i|>]],
   FeynFacetSolution`F[j_,1]:>ends[[j]]}/.pointRules,precision],
 {i,Length[algebra]}];
 resolve[z_] := N[z/.{FeynFacetSolution`a[j_]:>av[[j]],
   FeynFacetSolution`F[j_,1]:>ends[[j]]}/.pointRules,precision];
 result=Map[resolve[Last/@#]&,data["Coefficients"]];
 If[!And@@(MatrixQ[#,finiteNumberQ[#]||#===Missing["NotComputed"]&]& /@ Values[result]),
  numericalFailure["CoefficientEvaluationNotNumeric"]];
 masterResult=If[AssociationQ[Lookup[data,"MasterIntegralCoefficients",None]],
  Map[(First[#]->resolve[Last[#]]& /@ #)&,data["MasterIntegralCoefficients"]],None];
 Join[If[AssociationQ[masterResult],<|"MasterIntegralEpsilonCoefficients"->masterResult|>,<||>],
  <|"EpsilonCoefficients"->result,"Rows"->data["RequestedRows"],"Point"->point,
   "QuadratureOrder"->count,"WorkingPrecision"->precision,"IntegrationBreakpoints"->breaks,
   "Method"->"PiecewiseGaussLegendreCollocation","OriginalDifferentialEquationUsed"->False|>]
],N::meprec];

constantRules[data_,input_] := Module[{rules,needed,missing},
 If[input===Automatic,Return[{}]];
 rules=If[AssociationQ[input],Normal[input],input];
 If[!ListQ[rules]||!And@@(MatchQ[#,Rule[FeynFacetSolution`C[_Integer,_Integer],_?finiteNumericQ]]& /@ rules),
  numericalFailure["InitialConstantValuesNotWellFormed"]];
 If[!DuplicateFreeQ[First/@rules],numericalFailure["DuplicateInitialConstantValues"]];
 needed=DeleteDuplicates[Cases[Lookup[data,"MasterIntegralCoefficients",<||>],
   FeynFacetSolution`C[_Integer,_Integer],Infinity]];
 missing=Complement[needed,First/@rules];
 If[missing=!={},numericalFailure["InitialConstantValuesIncomplete",<|"MissingConstants"->missing|>]];
 rules
];
applyConstants[result_,rules_] := If[rules==={},result,
 Join[result,<|"MasterIntegralEpsilonCoefficients"->
    Map[(First[#]->N[Last[#]/.rules,result["WorkingPrecision"]]& /@ #)&,
      result["MasterIntegralEpsilonCoefficients"]],
   "InitialConstantValuesApplied"->True|>]];
comparisonVector[data_,result_,supplied_] := Module[{v,rows,expressions,constants,m},
 If[supplied,
  v=Flatten[Last/@#& /@ Values[result["MasterIntegralEpsilonCoefficients"]]],
  v=DeleteCases[Flatten[Values[result["EpsilonCoefficients"]]],_Missing];
  If[AssociationQ[Lookup[data,"MasterIntegralCoefficients",None]],
   expressions=Flatten[Last/@#& /@ Values[data["MasterIntegralCoefficients"]]];
   rows=Flatten[Last/@#& /@ Values[result["MasterIntegralEpsilonCoefficients"]]];
   Do[
    constants=DeleteDuplicates[Cases[expressions[[m]],FeynFacetSolution`C[_Integer,_Integer],Infinity]];
    v=Join[v,Coefficient[rows[[m]],#]& /@ constants,
      {rows[[m]]/.FeynFacetSolution`C[_,_]->0}],
   {m,Length[expressions]}]]];
 If[!VectorQ[v,finiteNumberQ]||v==={},numericalFailure["NumericalOutputNotFinite",
   <|"NonNumericPositions"->Position[v,z_/;!finiteNumberQ[z],{1}]|>]];
 v
];
scaledDifference[a_,b_,ag_,pg_] :=
 Max[Abs[a-b]/(10^-ag+10^-pg MapThread[Max,{Abs[a],Abs[b]}])];
numericAbsoluteUncertainty[z_] := If[Precision[z]===Infinity,0,10^(-Floor[Accuracy[z]])];
roundoffRatio[v_,ag_,pg_] := Max[numericAbsoluteUncertainty[#]/(10^-ag+10^-pg Abs[#])& /@ v];

(* This is a limited polynomial-pole/branch-point check, not an analytic-
   continuation algorithm. Unsupported factors are reported explicitly. *)
polynomialPathCheck[data_,point_,seconds_] := Module[
 {defs=Lookup[data,"KernelDefinitions",{}],vars=data["KinematicVariables"],
  factors,sourceExpressions,variable=Unique["pathParameter"],rules,expandKernel,expandExpression,
  checked={},unknown={},zeros,b,q,report,run,tol=10^-30},
 rules=Thread[vars->point];
 expandKernel[i_Integer] := expandKernel[i]=
   expandExpression[defs[[i,"Expression"]]/.defs[[i,"Parameter"]]->variable];
 expandExpression[z_] := z/.FeynFacetSolution`K[i_Integer,_]:>expandKernel[i];
 sourceExpressions=Join[
  ({#["Expression"],#["Parameter"]}& /@ defs),
  ({#["Integrand"],#["IntegrationVariable"]}& /@ data["IntegralDefinitions"])];
 run=TimeConstrained[
  factors=DeleteDuplicates[Flatten[Table[
   Join[
    Cases[sourceExpressions[[i,1]],
     (Power[z_,r_?NumberQ]/;(!IntegerQ[r]||r<0)):>(z/.sourceExpressions[[i,2]]->variable),{0,Infinity}],
    Cases[sourceExpressions[[i,1]],Log[z_]:>(z/.sourceExpressions[[i,2]]->variable),{0,Infinity}]],
   {i,Length[sourceExpressions]}]]];
  Do[
   b=expandExpression[factor]/.rules;
   If[!FreeQ[b,FeynFacetSolution`K],AppendTo[unknown,Short[factor]];Continue[]];
   q=Quiet[Check[Together[b],$Failed]];
   If[q===$Failed||!PolynomialQ[Numerator[q],variable]||
     !PolynomialQ[Denominator[q],variable],AppendTo[unknown,Short[factor]];Continue[]];
   Do[
    If[FreeQ[poly,variable],
     If[poly===0,numericalFailure["IntegrationPathMeetsSingularity",<|"Factor"->factor|>]],
     If[!MemberQ[checked,poly],
      zeros=Quiet[Check[variable/.NSolve[poly==0,variable,WorkingPrecision->50],$Failed]];
      If[!ListQ[zeros]||!VectorQ[zeros,NumericQ],AppendTo[unknown,Short[factor]],
       If[AnyTrue[zeros,Abs[Im[#]]<tol&&-tol<=Re[#]<=1+tol&],
        numericalFailure["IntegrationPathMeetsSingularity",<|"Factor"->factor,"Roots"->zeros|>]];
       AppendTo[checked,poly]]]],
    {poly,{Numerator[q],Denominator[q]}}],
  {factor,factors}];True,
 seconds,False];
 <|"Method"->"PolynomialPoleAndBranchPointCheck","CompletedWithinTimeLimit"->TrueQ[run],
   "CheckedPolynomialCount"->Length[checked],"UnresolvedFactorCount"->Length[unknown],
   "FullAnalyticContinuationVerified"->False,
   "BranchHandling"->"Stored expressions on the prescribed ordinary-point path; no automatic change of branch sheet."|>
];

