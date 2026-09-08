
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
End[];
