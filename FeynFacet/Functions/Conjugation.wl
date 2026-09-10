(* Conjugate explicit scalar functions on their declared real branch.
   Piecewise branch conditions are used locally, including the default arm. *)
BeginPackage["FeynFacet`"];
ConjugateExplicitScalarFunctions::usage="ConjugateExplicitScalarFunctions[expression,conditions,complexParameters] conjugates finite rational, logarithmic and classical-polylogarithmic expressions. Undeclared scalar parameters are real, as in ComplexExpand. Every nontrivial real special-function branch is checked, including each Piecewise condition. Unsupported branch claims return Failure.";
Begin["`Private`"];
ConjugateExplicitScalarFunctions[expression_,conditions_,complexParameters_List:{}]:=
 Catch[Module[{conjugate,prove,real,unhandled={},answer},
 prove[q_,assum_]:=prove[q,assum]=TrueQ[TimeConstrained[FullSimplify[q,Assumptions->assum],5,False]];
 real[q_,assum_]:=FreeQ[q,Alternatives@@complexParameters]&&
  FreeQ[q,_Complex]&&prove[Element[q,Reals],assum];
 conjugate[q_,assum_]:=conjugate[q,assum]=Which[
  NumberQ[q],Conjugate[q],
  MatchQ[q,_Symbol],If[MemberQ[complexParameters,q],Conjugate[q],q],
  AssociationQ[q],Map[conjugate[#,assum]&,q],
  ListQ[q],conjugate[#,assum]&/@q,
  MemberQ[{Plus,Times},Head[q]],Map[conjugate[#,assum]&,q],
  Head[q]===Power&&IntegerQ[q[[2]]],conjugate[q[[1]],assum]^q[[2]],
  Head[q]===Piecewise,Module[{branches=q[[1]],default=If[Length[q]===2,q[[2]],0],otherwise},
   otherwise=assum&&Not[Or@@branches[[All,2]]];
   Piecewise[Table[{If[prove[Not[branch[[2]]],assum],0,conjugate[branch[[1]],assum&&branch[[2]]]],branch[[2]]},
    {branch,branches}],If[prove[Not[otherwise],assum],0,conjugate[default,otherwise]]]],
  Head[q]===Log&&prove[q[[1]]>0,assum],q,
  Head[q]===PolyLog&&IntegerQ[q[[1]]]&&q[[1]]>=1&&prove[q[[2]]<=1&&Element[q[[2]],Reals],assum],q,
  MemberQ[{Abs,Re,Im},Head[q]],q,
  Head[q]===Zeta&&prove[q[[1]]>1,assum],q,
  Head[q]===PolyGamma&&MatchQ[List@@q,{_Integer?NonNegative,_Integer?Positive}],q,
  Head[q]===Gamma&&prove[Element[q[[1]],Reals],assum],q,
  Head[q]===Power&&prove[q[[1]]>0&&Element[q[[2]],Reals],assum],q,
  True,Throw[Failure["ExplicitScalarFunctionBranchNotEstablished",<|"Function"->q,"Conditions"->assum|>],"ScalarConjugation"]];
 answer=conjugate[expression,conditions];answer
],"ScalarConjugation"];
End[];EndPackage[];
