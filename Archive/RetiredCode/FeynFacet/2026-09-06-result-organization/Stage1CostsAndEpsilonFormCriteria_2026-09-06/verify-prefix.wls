
Block[{Print},Get["/home/maxzhang/factorization-and-loops/Addon/Load/LoadFACET.wl"]];
old=Get["/tmp/feynfacet-stage1-20260906/production-CF259/FamilyDLogEpsilonFormConstructionState_CF259_fresh.wl"];
new=Get["/tmp/feynfacet-stage1-20260906/optimized-CF259/FamilyDLogEpsilonFormConstructionState_CF259_fresh.wl"];
n=Max[Flatten[Take[old["Ranges"],12]]];
normalize[expr_]:=expr/.s_Symbol/;MemberQ[{"x","y","eps","ep"},SymbolName[Unevaluated[s]]]:>Switch[SymbolName[Unevaluated[s]],"x",x,"y",y,_,eps];
keys={"S","SInverse","A"};
results=Association@Table[key->Module[{a=normalize[old[key]],b=normalize[new[key]],diff},
 If[key==="A",a=a[[All,1;;n,1;;n]];b=b[[All,1;;n,1;;n]],
 a=a[[1;;n,1;;n]];b=b[[1;;n,1;;n]]];
 diff=Table[Max[Abs[Flatten[(a-b)/.Thread[{x,y,eps}->N[pt,65]]]]],{pt,{{1/11,1/17,1/13},{2/13,1/19,-1/11}}}];
 <|"IdenticalExpressions"->SameQ[a,b],"NumericalAgreement"->TrueQ[Max[diff]<10^-40]|>],{key,keys}];
Print[results];Export["/tmp/feynfacet-stage1-20260906/prefix-validation.json",results,"RawJSON"];
Exit[If[AllTrue[Values[results],#["NumericalAgreement"]&],0,1]];
