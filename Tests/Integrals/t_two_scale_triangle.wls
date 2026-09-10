$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[eps,aa,bb,r,y];
conditions=aa>0&&bb>0&&aa!=bb;
value=EvaluateOneLoopScalarFunctions[FeynCalc`C0[0,-aa,-bb,0,0,0],eps,conditions];
rGamma=Gamma[1+eps]Gamma[1-eps]^2/Gamma[1-2eps];
expected=Pi^-eps rGamma/eps^2 (aa^-eps-bb^-eps)/(bb-aa);
FTAssert["two off-shell invariants give the exact Dirichlet divided difference",
 FullSimplify[value-expected,Assumptions->conditions&&Element[eps,Reals]]===0];
permuted=EvaluateOneLoopScalarFunctions[FeynCalc`C0[-bb,0,-aa,0,0,0],eps,conditions];
FTAssert["the massless triangle is invariant under permutation of its external invariants",
 FullSimplify[value-permuted,Assumptions->conditions]===0];
coincident=EvaluateOneLoopScalarFunctions[FeynCalc`C0[0,-aa,-aa,0,0,0],eps,aa>0];
FTAssert["coincident nonzero invariants have a finite exact limit",
 FullSimplify[coincident-Pi^-eps rGamma/eps aa^(-1-eps),Assumptions->aa>0]===0];
reference=-Gamma[2/3]NIntegrate[
 9 r^3 (3-3r^3+r^6)^(1/3)(2y+5(1-y))^(-2/3),{r,0,1},{y,0,1},
 WorkingPrecision->30,PrecisionGoal->18,AccuracyGoal->18,
 Method->{"GlobalAdaptive","SymbolicProcessing"->0}];
numerical=N[Pi^eps value/.{aa->2,bb->5,eps->-1/3},25];
FTAssert["an independent Euclidean Feynman-parameter integral verifies the sign and normalization",
 NumberQ[reference]&&Abs[numerical-reference]<10^-16];
timelike=EvaluateOneLoopScalarFunctions[FeynCalc`C0[0,aa,-bb,0,0,0],eps,aa>0&&bb>0];
pole=SeriesCoefficient[timelike,{eps,0,-1}];
FTAssert["the virtual causal prescription supplies the timelike discontinuity",
 FullSimplify[pole-(Log[bb/aa]+I Pi)/(aa+bb),Assumptions->aa>0&&bb>0]===0];
reduced=ReduceMasslessScalarTriangles[FeynCalc`C0[0,-aa,-bb,0,0,0],eps,conditions];
fromBubbles=EvaluateOneLoopScalarFunctions[reduced,eps,conditions];
FTAssert["the exact bubble-triangle IBP agrees before any epsilon expansion",
 FullSimplify[value-fromBubbles,Assumptions->conditions]===0];
FTReport[];
