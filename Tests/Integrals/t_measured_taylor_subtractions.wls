Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
one=FeynFacet`ConstructMeasuredTaylorSubtractions[
 {<|"Coefficient"->1+r,"Measurement"->r|>},<|r->-2-2e|>,e];
FTTest`FTAssert["a power-divergent face retains the measurement chain-rule derivative",
 AssociationQ[one]&&one["MaximumTestFunctionDerivativeOrder"]===1&&
 First[one["TaylorIdentities"]]["TaylorCoefficients"][[2]]===
  FeynFacet`TestFunction[0]+Derivative[1][FeynFacet`TestFunction][0]];
evaluateAction[expr_]:=expr/.{
 HoldPattern[Derivative[k_Integer][FeynFacet`TestFunction][x_]]:>
  (D[1+t+t^3,{t,k}]/.t->x),FeynFacet`TestFunction[x_]:>1+x+x^3};
integrateSubtracted[record_,reg_]:=Total[Map[Function[term,Module[{expr,vars},
 expr=evaluateAction[term["Coefficient"]term["Action"]
   Times@@KeyValueMap[#1^#2&,term["NormalPowers"]]]/.e->reg;
 vars=Keys[term["NormalPowers"]];
 Fold[Integrate[#1,{#2,0,1}]&,expr,vars]]],record["SubtractedTerms"]]];
FTTest`FTAssert["the complete one-face decomposition equals an independent convergent integral",
 Simplify[integrateSubtracted[one,-2]-Integrate[r^2(1+r)(1+r+r^3),{r,0,1}]]===0];
two=FeynFacet`ConstructMeasuredTaylorSubtractions[
 {<|"Coefficient"->1+r s,"Measurement"->r+s-r s|>},<|r->-1-2e,s->-1-e|>,e];
FTTest`FTAssert["overlapping logarithmic faces retain their double regulator pole",
 AssociationQ[two]&&AnyTrue[two["SubtractedTerms"],Length[#["Faces"]]===2&&
  Together[#["Coefficient"]-1/(2e^2)]===0&]&&two["MaximumTestFunctionDerivativeOrder"]===0];
FTTest`FTAssert["two-face subtraction including its overlap preserves the measured action",
 Simplify[integrateSubtracted[two,-1]-Integrate[r(1+r s)(1+(r+s-r s)+(r+s-r s)^3),{r,0,1},{s,0,1}]]===0];
FTTest`FTAssert["formal Taylor identities cannot masquerade as a contact-order or L1 certificate",
 !two["WeightedL1ConvergenceVerified"]&&!two["EndpointContactOrderEstablished"]&&!two["ChartCoverageVerified"]];
FTTest`FTAssert["oppositely regulated logarithmic faces require a common convergence domain",
 FailureQ[FeynFacet`ConstructMeasuredTaylorSubtractions[
  {<|"Coefficient"->1,"Measurement"->r s|>},<|r->-1-e,s->-1+e|>,e]]];
Print["MEASURED TAYLOR SUBTRACTIONS TEST COMPLETE"];FTTest`FTReport[];
