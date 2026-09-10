$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[ce,cz,ct,cr,cs,cq];
FTAssert["an empty polynomial variable list keeps the entire scalar coefficient",
 FeynFacet`PolynomialCoefficientRules[Gamma[1+ce]/ce,{}]==={{}->Gamma[1+ce]/ce}];
FTAssert["zero has no nonzero scalar monomial",
 FeynFacet`PolynomialCoefficientRules[0,{}]==={}];
FTAssert["declared variables do not expand the scalar coefficient",
 FeynFacet`PolynomialCoefficientRules[(1+cz)Gamma[1+ce],{cz}]==={{1}->Gamma[1+ce],{0}->Gamma[1+ce]}];
FTAssert["trigonometric Laurent poles are exact",
 FeynFacet`DetermineLaurentValuation[Cot[Pi ce],ce]===-1&&
 FeynFacet`DetermineLaurentValuation[Csc[Pi ce],ce]===-1&&
 FeynFacet`DetermineLaurentValuation[ce Cot[Pi ce],ce]===0];
Do[
 {m,h,beta}=entry;
 pars={m+1,h+m+beta ce,h+m+1+beta ce};
 ans=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[pars,cz,ce,2];
 errors=Table[
  pref=If[k===0,h+m,0];
  integrand=If[k===0,(h+m)ct^(h+m-1)/(1-cz ct)^(m+1),
   beta^k ct^(h+m-1)/(1-cz ct)^(m+1)*
    ((h+m)Log[ct]^k/Factorial[k]+Log[ct]^(k-1)/Factorial[k-1])];
  ref=NIntegrate[integrand/.cz->1/3,{ct,0,1},WorkingPrecision->45,AccuracyGoal->32,PrecisionGoal->32];
  Abs[N[ans[k]/.cz->1/3,40]-ref],{k,0,2}];
 FTAssert["shifted Gauss family agrees with independent Euler moments "<>ToString[{m,h,beta}],Max[errors]<10^-30],
 {entry,{{0,1,1},{1,2,-2},{2,1,3}}}];
test=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ExpandGaussHypergeometricCombinations[
 <|"A"->Hypergeometric2F1[1,1+ce,2+ce,cz]/ce^2|>,ce,{-2,0}]];
FTAssert["Gauss contraction propagates the rational double pole",
 AssociationQ[test["Result"]]&&test["Result"]["GaussFunctionUpperOrders"]==={2}&&
 test["EpsilonRemainderAudit"]["Status"]==="Passed"];
FTAssert["a Gamma-only combination retains its nonzero Laurent coefficients",
 With[{a=FeynFacet`ExpandGaussHypergeometricCombinations[<|"A"->Gamma[1+ce]/ce|>,ce,{-2,0}]},
 AssociationQ[a]&&a["Coefficients"][{1,-1}]===1&&a["Coefficients"][{1,0}]===-EulerGamma]];
FTReport[];
