(* Expand a complete linear combination, after exact triangle IBPs.
   Required scalar orders follow the actual rational coefficient poles. *)
BeginPackage["FeynFacet`"];
ExpandOneLoopScalarFunctions::usage=
 "ExpandOneLoopScalarFunctions[values,epsilon,range,conditions] expands named complete one-loop scalar combinations. It reduces supported triangles to bubbles first, determines sufficient orders per scalar integral, and convolves explicit Laurent coefficients with the common omitted-order audit. It does not perform endpoint distribution limits or Hermitian completion.";
Begin["`Private`"];
ExpandOneLoopScalarFunctions[values_Association,e_Symbol,range:{_Integer,_Integer},conditions_]:=
 Catch[Module[
 {labels=Keys[values],expressions,objects,aliases,polynomials,coefficientMatrix,n,m,
  lower,upper,masterLower,masterUpper,masterCoefficients=<||>,masterExact,master,
  record,orders,vector,matrix,result,object,external,mass,supported,needed},
 If[values===<||>||First[range]>Last[range],
  Throw[Failure["OneLoopLaurentCombinationRequestRequired",<||>],"OneLoopExpansion"]];
 expressions=FeynFacet`ReduceMasslessScalarTriangles[#/.D->4-2e,e,conditions]&/@Values[values];
 If[AnyTrue[expressions,FailureQ],Throw[SelectFirst[expressions,FailureQ],"OneLoopExpansion"]];
 objects=DeleteDuplicates[Cases[expressions,_FeynCalc`B0|_FeynCalc`D0,{0,Infinity}]];
 aliases=Table[Unique["scalarLoopIntegral"],{Length[objects]}];
 polynomials=FeynFacet`PolynomialCoefficientRules[#/.Thread[objects->aliases],aliases]&/@expressions;
 If[AnyTrue[polynomials,FailureQ]||!AllTrue[Flatten[First/@#&/@polynomials,1],Total[#]<=1&],
  Throw[Failure["LinearOneLoopScalarCombinationRequired",<||>],"OneLoopExpansion"]];
 n=Length[labels];m=Length[objects]+1;
 coefficientMatrix=Table[Lookup[Association[polynomials[[i]]],
   Key[If[j===1,ConstantArray[0,m-1],UnitVector[m-1,j-1]]],0],{i,n},{j,m}];
 (* D0 uses the normalized loop provider. B0 below already includes the
    FeynCalc pi^(-epsilon) conversion. No extra loop measure is inserted. *)
 Do[If[MatchQ[objects[[j]],_FeynCalc`D0],coefficientMatrix[[All,j+1]]*=Pi^-e],{j,m-1}];
 coefficientMatrix=Map[Factor,coefficientMatrix,{2}];
 lower=Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,coefficientMatrix,{2}];
 If[!AllTrue[Flatten[lower],IntegerQ[#]||#===Infinity&],
  Throw[Failure["OneLoopCoefficientLaurentBoundsRequired",<||>],"OneLoopExpansion"]];
 masterUpper=Table[Max[Table[If[lower[[i,j]]===Infinity,-Infinity,Last[range]-lower[[i,j]]],{i,n}]],{j,m}];
 masterLower=ConstantArray[0,m];masterExact=ConstantArray[False,m];
 Do[
  If[masterUpper[[j]]===-Infinity,masterUpper[[j]]=0;masterLower[[j]]=Infinity;masterExact[[j]]=True;Continue[]];
  If[j===1,record=FeynFacet`ExpandLaurentCoefficientVector[{1},e,{{0,Max[0,masterUpper[[j]]]}}],
   object=objects[[j-1]];
   record=If[MatchQ[object,FeynCalc`B0[_,0,0]],
    master=FeynFacet`EvaluateOneLoopScalarFunctions[object,e,conditions];
    If[FailureQ[master],Throw[master,"OneLoopExpansion"]];
    FeynFacet`ExpandLaurentCoefficientVector[{master},e,{{-1,Max[-1,masterUpper[[j]]]}}],
    If[!MatchQ[object,FeynCalc`D0[_,_,_,_,_,_,0,0,0,0]],
     Throw[Failure["MasslessScalarBoxRequired",<|"Integral"->object|>],"OneLoopExpansion"]];
    external=Take[List@@object,4];
    supported=Select[external,!TrueQ[FullSimplify[#==0,Assumptions->conditions]]&];
    If[Length[supported]>1,Throw[Failure["AtMostOneOffShellBoxLegRequired",<|"Integral"->object|>],"OneLoopExpansion"]];
    mass=If[supported==={},0,First[supported]];
    FeynFacet`EvaluateMasslessBoxIntegral[{object[[5]],object[[6]],mass},e,
     {-2,Max[-2,masterUpper[[j]]]},conditions]
   ]];
  If[!AssociationQ[record],Throw[Failure["ExplicitScalarLoopExpansionRequired",<|"Cause"->record|>],"OneLoopExpansion"]];
  masterLower[[j]]=First[record["LaurentLowerBounds"]];masterExact[[j]]=First[record["ExactTails"]];
  KeyValueMap[AssociateTo[masterCoefficients,{j,Last[#1]}->#2]&,record["Coefficients"]],
 {j,m}];
 upper=Table[If[masterLower[[j]]===Infinity,0,Last[range]-masterLower[[j]]],{j,m}];
 matrix=FeynFacet`ExpandLaurentCoefficientMatrix[coefficientMatrix,e,upper];
 If[FailureQ[matrix],Throw[matrix,"OneLoopExpansion"]];
 vector=<|"DimensionalRegulator"->e,"Dimension"->m,"Coefficients"->masterCoefficients,
  "LaurentLowerBounds"->masterLower,"KnownThroughOrders"->masterUpper,"ExactTails"->masterExact|>;
 result=FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,vector,ConstantArray[range,n]];
 If[FailureQ[result],Throw[result,"OneLoopExpansion"]];
 Join[result,<|"StructureFunctions"->labels,"ScalarIntegralBasis"->Prepend[objects,1],
  "ScalarIntegralUpperOrders"->masterUpper,"CoefficientEntryLaurentLowerBounds"->lower,
  "KinematicScope"->"Fixed interior kinematics. Regulated endpoint limits are separate.",
  "ConjugateInterferenceAdded"->False|>]
],"OneLoopExpansion"];
End[];EndPackage[];
