
(* Conditional transverse moments in massless three-particle phase space.
   Positive rational coordinates remove square roots before Euler integration. *)
Begin["FeynFacet`Private`"];
coalescingTwoPairEulerTerms[alpha_,single_,complement_,pairPowerList_,constant_,variables_] := Module[
 {t=variables[[1]],u=variables[[2]],r=variables[[3]],x,p=pairPowerList[[1]],q=pairPowerList[[2]],
 factors,pref,terms={},degree,coefficient,chi},
 x={t,(1-t)u,(1-t)(1-u)};
 factors=Join[MapThread[{#1,alpha-1-#2}&,{x,single}],
    MapThread[{1-#1,-#2}&,{x,complement}],{{1-t,1}}];
 If[p>0&&q>0,
  (* The normalized Gaussian quadratic moments give
     2F1[p,q;alpha;chi], chi=x2*x3/(x12*x13). Its Euler representation
     integrates both transverse variables, leaving one rational variable. *)
  pref=Cancel[FunctionExpand[
    Pochhammer[2alpha,-p-q]^-1 Pochhammer[alpha,-p]/Gamma[q]]];
  AppendTo[terms,positiveRationalEulerTerm[{r,t,u},
    Join[factors,{{x[[1]]+x[[2]]x[[3]]r,-p},{x[[1]]+x[[3]],p-q},
      {r,alpha-q-1},{1-r,q-1}}],constant pref]],
  (* A nonpositive integer hypergeometric parameter terminates the sum.
     This also covers numerator insertions and the one-pair limit. *)
  degree=Min[Select[{-p,-q},#>=0&]];
  pref=Cancel[FunctionExpand[
    Pochhammer[alpha,-p]Pochhammer[alpha,-q]/Pochhammer[2alpha,-p-q]]];
  chi=x[[2]]x[[3]]/((x[[1]]+x[[2]])(x[[1]]+x[[3]]));
  Do[coefficient=Cancel[FunctionExpand[pref Pochhammer[p,k]Pochhammer[q,k]/
      (Pochhammer[alpha,k]Factorial[k])]];
   If[coefficient===0,Continue[]];
   AppendTo[terms,positiveRationalEulerTerm[{t,u},
     Join[factors,{{x[[1]]+x[[2]],-p},{x[[1]]+x[[3]],-q},{chi,k}}],
     constant coefficient]],
  {k,0,degree}]];
 terms
];

FeynFacet`EvaluateSphericalBetaMoment::usage =
 "EvaluateSphericalBetaMoment[expression,{r,u,y},alpha] evaluates rational endpoint monomials with independent Beta(alpha,alpha) polar variables r,u and the rotated angular fraction y=r+u-2ru-2 Sqrt[r(1-r)u(1-u)] cos(phi). It returns Gamma products or 3F2(1), by spherical convolution and Euler integration, with meromorphic continuation from the common convergence domain.";

sphericalBetaMonomial[term_,variables_] := Module[
 {factors,constant=1,exponents=ConstantArray[0,{Length[variables],2}],p,k,ratio,match},
 factors=Join[FactorList[Numerator[term]],({First[#],-Last[#]}&/@FactorList[Denominator[term]])];
 Do[{p,k}=factor;
  If[FreeQ[p,Alternatives@@variables],constant*=p^k;Continue[]];
  match=None;
  Do[
   ratio=Cancel[p/If[side===1,variables[[j]],1-variables[[j]]]];
   If[FreeQ[ratio,Alternatives@@variables],
    match={j,side};constant*=ratio^k;Break[]],{j,Length[variables]},{side,2}];
  If[match===None,Return[Failure["SphericalEndpointMonomialRequired",<|"Factor"->p|>],Module]];
  exponents[[Sequence@@match]]+=k,
 {factor,factors}];
 <|"Constant"->constant,"Exponents"->exponents|>
];

sphericalBetaConvolution[alpha_,b_,c_] :=
 Gamma[2alpha]Gamma[alpha-b]Gamma[alpha-c]/(Gamma[alpha]^2 Gamma[2alpha-b-c]);

sphericalBetaThreeMoment[alpha_,radial_,polar_,relative_] := Module[
 {rr=First[radial],tt=Last[radial],b,c,opposite,aa,bb,k,degree,conv,third},
 If[Count[polar,Except[0]]>1||Count[relative,Except[0]]>1,
  Return[Failure["SingleAngularEndpointTermRequired",<||>]]];
 b=-Total[relative];c=-Total[polar];
 opposite=Xor[Last[relative]=!=0,Last[polar]=!=0];
 aa=alpha+rr;bb=alpha+tt;third=If[opposite,aa,bb];
 conv=sphericalBetaConvolution[alpha,b,c];
 degree=Select[{-b,-c},IntegerQ[#]&&#>=0&];
 If[degree=!={},
  Return[conv Sum[Pochhammer[b,k]Pochhammer[c,k]/
   (Pochhammer[alpha,k]Factorial[k])*
   If[opposite,Beta[aa+k,bb],Beta[aa,bb+k]]/Beta[alpha,alpha],
   {k,0,Min[degree]}]]];
 If[(!opposite&&tt===0)||(opposite&&rr===0),
  k=If[opposite,-tt,-rr];
  Return[Gamma[2alpha]^2 Gamma[alpha-k]Gamma[alpha-b]Gamma[alpha-c]Gamma[2alpha-k-b-c]/
   (Gamma[alpha]^3 Gamma[2alpha-k-b]Gamma[2alpha-k-c]Gamma[2alpha-b-c])]];
 conv Beta[aa,bb]/Beta[alpha,alpha]*
  HypergeometricPFQ[{b,c,third},{alpha,aa+bb},1]
];

FeynFacet`EvaluateSphericalBetaMoment[expression_,variables:{_Symbol,_Symbol,_Symbol},alpha_]:=
 Catch[Module[{expanded,terms,result=0,data,value},
 If[!DuplicateFreeQ[variables]||!FreeQ[alpha,Alternatives@@variables],
  Throw[Failure["IndependentSphericalMomentParametersRequired",<||>]]];
 expanded=Expand[Apart[Apart[Cancel[expression],variables[[3]]],variables[[2]]]];
 terms=If[Head[expanded]===Plus,List@@expanded,{expanded}];
 Do[
  If[term===0,Continue[]];
  data=sphericalBetaMonomial[term,variables];If[FailureQ[data],Throw[data]];
  value=sphericalBetaThreeMoment[alpha,Sequence@@data["Exponents"]];
  If[FailureQ[value],Throw[value]];
  result+=data["Constant"]value,{term,terms}];
 result
]];

End[];
