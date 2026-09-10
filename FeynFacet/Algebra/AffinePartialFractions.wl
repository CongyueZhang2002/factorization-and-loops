(* Exact multivariate partial fractions using only the supplied affine
   denominator polynomials. No integration contour or prescription is changed.
   A source-product prescription certificate belongs before this operation. *)
BeginPackage["FeynFacet`"];
PartialFractionAffineDenominators::usage="PartialFractionAffineDenominators[denominators,powers,variables,request] expresses a product of inverse affine denominators in terms of products whose positive-power denominators have independent linear parts. Terms contain Coefficient and Powers in the original denominator list. Only external coefficients are divided by; ExceptionalDivisors records their possible zeros. This rational identity does not establish a causal-prescription limit.";
Begin["`Private`"];
affineFractionFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AffineFractions"];
PartialFractionAffineDenominators[denominators_List,powers_List,variables_List,request_Association:<||>]:=
 Catch[Module[{polynomials,matrix,constant,relation,reduce,merge,terms,divisors={},counts=0,
  maxStates=Lookup[request,"MaximumStates",100000],result,assumptions=Lookup[request,"Assumptions",True]},
 If[!MatchQ[variables,{_Symbol..}]||!DuplicateFreeQ[variables]||
    Length[powers]=!=Length[denominators]||!VectorQ[powers,IntegerQ[#]&&#>=0&]||
    !FreeQ[denominators,_Real|_Failure|_Missing|$Failed|$Aborted]||
    !IntegerQ[maxStates]||maxStates<1,affineFractionFail["ExactAffineDenominatorDataRequired"]];
 polynomials=Expand[denominators];
 If[!AllTrue[polynomials,PolynomialQ[#,variables]&&
     AllTrue[First/@CoefficientRules[#,variables],Total[#]<=1&]&]||
    MemberQ[polynomials,0],affineFractionFail["NonzeroAffineDenominatorsRequired"]];
 matrix=Table[Coefficient[poly,var],{poly,polynomials},{var,variables}];
 constant=polynomials/.Thread[variables->0];
 merge[items_]:=Select[Map[With[{coefficient=Factor[Total[#[[All,1]]]],indices=#[[1,2]]},
    {coefficient,indices}]&,GatherBy[items,Last]],First[#]=!=0&];
 (* The relation depends on the positive support, not its powers. In a
    homogeneous relation the same pivot is retained until another member
    leaves that support. This provides a decreasing nonpivot power sum. *)
 relation[support_List]:=relation[support]=Module[{null,offsets,choice,c,offset,pivot,den},
  If[support==={},Return[None]];
  null=NullSpace[Transpose[matrix[[support]]]];
  If[null==={},Return[None]];
  offsets=Factor[#.constant[[support]]]&/@null;
  choice=FirstPosition[offsets,value_/;value=!=0,Missing["Homogeneous"],{1},Heads->False];
  If[MissingQ[choice],c=First[null];offset=0,c=null[[First[choice]]];offset=offsets[[First[choice]]]];
  pivot=Last[Flatten[Position[c,value_/;value=!=0,{1},Heads->False]]];
  den=If[offset===0,c[[pivot]],offset];
  AppendTo[divisors,den];
  <|"Support"->support,"Coefficients"->c,"Constant"->offset,"Pivot"->pivot|>];
 reduce[nu_List]:=reduce[nu]=Module[{support,rel,c,offset,pivot,new,branches},
  counts++;If[counts>maxStates,affineFractionFail["PartialFractionStateLimit",<|"States"->counts|>]];
  support=Flatten[Position[nu,value_/;value>0,{1}]];rel=relation[support];
  If[rel===None,Return[{{1,nu}}]];
  c=rel["Coefficients"];offset=rel["Constant"];pivot=rel["Pivot"];
  branches=Table[
   If[c[[i]]===0||(offset===0&&i===pivot),Nothing,
    new=ReplacePart[nu,support[[i]]->nu[[support[[i]]]]-1];
    If[offset===0,new=ReplacePart[new,support[[pivot]]->new[[support[[pivot]]]]+1]];
    With[{factor=If[offset===0,-c[[i]]/c[[pivot]],c[[i]]/offset]},
     ({factor First[#],Last[#]}&/@reduce[new])]],
   {i,Length[support]}];
  merge[Flatten[branches,1]]];
 terms=Block[{$RecursionLimit=Max[$RecursionLimit,1024]},reduce[powers]];
 (* Include denominators already present in external coefficients as well as
    the divisions introduced by elimination. This is an algebraic chamber
    record, not a proof that a physical endpoint is regular. *)
 divisors=DeleteDuplicates[Factor/@Join[divisors,
   Denominator[Together[#]]&/@Join[Flatten[matrix],constant,terms[[All,1]]]]];
 divisors=DeleteCases[divisors,_Integer|_Rational];
 result=<|"Format"->"FeynFacet-AffinePartialFractions","FormatVersion"->1,
  "Denominators"->denominators,"InputPowers"->powers,"Variables"->variables,
  "Terms"->(<|"Coefficient"->First[#],"Powers"->Last[#]|>&/@terms),
  "ExceptionalDivisors"->divisors,"Assumptions"->assumptions,
  "ValidityConditions"->And@@(#!=0&/@divisors),"States"->counts,
  "NewLoopDependentDenominators"->False,"PrescriptionsChanged"->False|>;
 result
 ],"AffineFractions"];
End[];EndPackage[];
