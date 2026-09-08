#!/usr/bin/env wolframscript
(* Independent off-base-point checks of the saved finite integrals.
   No FeynFacet package, DE solver, or coefficient generator is imported. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"FeynFacet","FiniteSolutionData.wl"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]<2,Print["Expected SOLUTION_DIRECTORY POINT.wl [REPORT.wl]"];Exit[2]];
data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];point=Get[args[[2]]];
kernels=Get[FileNameJoin[{args[[1]],"kernels.m"}]];
precision=60;step=10^-8;
t=First[AbsoluteTiming[low=FeynFacetSolution`EvaluateMasterIntegralSolution[data,point,
 "QuadratureOrder"->12,"WorkingPrecision"->precision]]];
Print["12-point quadrature seconds ",t];
t=First[AbsoluteTiming[high=FeynFacetSolution`EvaluateMasterIntegralSolution[data,point,
 "QuadratureOrder"->20,"WorkingPrecision"->precision]]];
Print["20-point quadrature seconds ",t];
If[FailureQ[low]||FailureQ[high],Print[InputForm[{low,high}]];Exit[1]];
norm[z_]:=Max[Abs[Flatten[z]]];
relative[a_,b_]:=norm[a-b]/Max[1,norm[a],norm[b]];
orders=data["RequestedEpsilonOrders"];rows=data["RequestedRows"];
If[orders=!=Range[Min[orders],Max[orders]] ||
 rows=!=Range[data["InitialConstants"]["Count"]],
 Print["The full PDE comparison requires all rows and a contiguous epsilon range"];Exit[2]];
convergence=Max[Table[relative[low["EpsilonCoefficients"][k],high["EpsilonCoefficients"][k]],{k,orders}]];
vars=data["KinematicVariables"];ep=data["DimensionalRegulator"];rules=Thread[vars->point];
basis=kernels["BasisTransformationMatrix"];
source=Lookup[kernels,"OriginalConnectionMatrices",None];
If[!ListQ[source],basis0=basis/.rules;basisInv=Inverse[basis0]];
zeroQ[z_]:=TrueQ[Cancel[Together[z]]===0];
valuation[z_]:=If[zeroQ[z],Infinity,With[{a=Together[z]},
 Exponent[Numerator[a],ep,Min]-Exponent[Denominator[a],ep,Min]]];
checks={};
Do[
 plus=FeynFacetSolution`EvaluateMasterIntegralSolution[data,point+step UnitVector[Length[vars],i],
   "QuadratureOrder"->20,"WorkingPrecision"->precision];
 minus=FeynFacetSolution`EvaluateMasterIntegralSolution[data,point-step UnitVector[Length[vars],i],
   "QuadratureOrder"->20,"WorkingPrecision"->precision];
 If[FailureQ[plus]||FailureQ[minus],Print[InputForm[{plus,minus}]];Exit[1]];
 original=If[ListQ[source],source[[i]]/.rules,
   ((D[basis,vars[[i]]]/.rules)+basis0.(kernels["ConnectionMatrices"][[i]]/.rules)).basisInv];
 lowest=Min[Flatten[Map[valuation,original,{2}]]];
 If[lowest===Infinity,lowest=0];
 available=Select[orders,#<=Max[orders]+Min[0,lowest]&];
 series=Map[Normal[Series[#,{ep,0,Max[orders]-Min[orders]}]]&,original,{2}];
 Do[
  derivative=(plus["EpsilonCoefficients"][k]-minus["EpsilonCoefficients"][k])/(2 step);
  rhs=Total[Table[N[Map[Coefficient[#,ep,q]&,series,{2}],precision].
    high["EpsilonCoefficients"][k-q],{q,lowest,k-Min[orders]}]];
  residual=relative[derivative,rhs[[rows]]];
  AppendTo[checks,<|"Coordinate"->i,"EpsilonOrder"->k,"RelativeResidual"->residual|>];
  Print["Coordinate ",i," epsilon ",k," relative residual ",N[residual,4]],
 {k,available}],
{i,Length[vars]}];
report=<|"Status"->If[convergence<10^-25 && Max[Lookup[checks,"RelativeResidual"]]<10^-10,
 "IndependentFiniteIntegralChecksPassed","IndependentFiniteIntegralChecksFailed"],
 "Point"->point,"QuadratureOrders"->{12,20},"WorkingPrecision"->precision,
 "QuadratureRelativeDifference"->convergence,"CentralDifferenceStep"->step,
 "Checks"->checks,"DifferentialEquationSolverUsed"->False,
 "Scope"->"Off-base-point numerical checks for every initial-constant column. Orders needing unstored higher coefficients are not tested by this numerical check; generic exact coefficient identities are separate."|>;
If[Length[args]>=3,Put[report,args[[3]]]];
Print["NUMERICAL_RESULT ",InputForm[report]];
Exit[If[report["Status"]==="IndependentFiniteIntegralChecksPassed",0,1]];
