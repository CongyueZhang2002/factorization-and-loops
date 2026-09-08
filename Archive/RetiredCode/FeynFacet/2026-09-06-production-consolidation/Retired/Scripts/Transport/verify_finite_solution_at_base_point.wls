#!/usr/bin/env wolframscript
(* Independent clean-kernel verification of stored expressions. No FeynFacet
   package, constructor, word enumerator or DE solver is loaded.
   Checks every initial-constant column, not one physical linear combination.
   These are normalization and first-derivative identities at the base point,
   not a substitute for the flatness and branch requirements. *)
$HistoryLength=0;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Expected solution directory"];Exit[2]];
directory=First[args];
seconds=First[AbsoluteTiming[
 conventions=Get[FileNameJoin[{directory,"conventions.m"}]];
 functions=Get[FileNameJoin[{directory,"functions.m"}]];
 algebra=Get[FileNameJoin[{directory,"algebraic_expressions.m"}]];
 kernels=Get[FileNameJoin[{directory,"kernels.m"}]];
 coefficients=Association@Table[k->Get[FileNameJoin[{directory,
   "coefficients_order_"<>ToString[k]<>".m"}]],{k,conventions["RequestedEpsilonOrders"]}];
]];
Print["ReadSeconds ",seconds];
vars=conventions["KinematicVariables"]; ep=conventions["DimensionalRegulator"];
base=Thread[vars->conventions["BasePoint"]];
n=conventions["InitialConstants"]["Count"]; rows=conventions["RequestedRows"];
zeroQ[z_]:=TrueQ[Cancel[Together[z]]===0];
matrixZeroQ[z_]:=And@@(zeroQ/@Flatten[z]);
T=kernels["BasisTransformationMatrix"];
T0=T/.base; T0inv=Inverse[T0];
allChecks={};
Do[
 (* Each integral has a path one-form vanishing at coincident endpoints.
    The product with derivatives of earlier integral functions therefore
    contributes zero at the base point. *)
 fd=Table[Integrate[D[f["Integrand"]/.FeynFacetSolution`F[_,_]->0,vars[[coordinate]]]/.base,
   {f["IntegrationVariable"],0,1}],{f,functions}];
 av={}; ad={};
 linear[z_]:=Normal[Series[
   (z/.{FeynFacetSolution`a[j_]:>av[[j]]+lambda ad[[j]],
       FeynFacetSolution`F[j_,1]:>lambda fd[[j]]}) /.
     Thread[vars->(conventions["BasePoint"]+lambda UnitVector[Length[vars],coordinate])],
   {lambda,0,1}]];
 Do[z=linear[a];AppendTo[av,Coefficient[z,lambda,0]];
   AppendTo[ad,Coefficient[z,lambda,1]],{a,algebra}];
 originalConnection=((D[T,vars[[coordinate]]]/.base)+T0.
   (kernels["ConnectionMatrices"][[coordinate]]/.base)).T0inv;
 expected=Map[Normal[Series[#,{ep,0,Max[Keys[coefficients]]}]]&,originalConnection,{2}];
 Do[
  stored=linear[Last/@coefficients[k]];
  norm=matrixZeroQ[Map[Coefficient[#,lambda,0]&,stored,{2}]-
    If[k===0,IdentityMatrix[n][[rows]],ConstantArray[0,{Length[rows],n}]]];
  derivative=matrixZeroQ[Map[Coefficient[#,lambda,1]&,stored,{2}]-
    Map[Coefficient[#,ep,k]&,expected[[rows]],{2}]];
  AppendTo[allChecks,norm&&derivative];
  Print["Coordinate ",coordinate," epsilon ",k," normalization ",norm,
    " first derivative ",derivative],
 {k,Keys[coefficients]}],
{coordinate,Length[vars]}];
Print["COLD_READER_CHECKS ",Length[allChecks]," failed ",Count[allChecks,False],
 " PeakMemoryBytes ",MaxMemoryUsed[]];
Exit[If[And@@allChecks,0,1]];
