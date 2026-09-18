Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
record[name_]:=FeynFacet`MasslessVertexMasterDefinition[name,{pl1,pl2},{pp1,pp2},ps,pe,"Timelike"];
bubble=record["A2"];
FTTest`FTAssert["timelike scalar bubble has the Feynman-parameter branch",
 AssociationQ[bubble]&&FullSimplify[bubble["ExactValue"]/
  (Exp[I Pi pe]ps^-pe Gamma[pe]Beta[1-pe,1-pe]),ps>0&&Element[pe,Reals]]===1];
Do[FTTest`FTAssert["connected one-scale homogeneity fixes the phase of "<>row[[1]],
 FullSimplify[record[row[[1]]]["ContinuationFactor"]-row[[2]]]===0],
 {row,{{"A2Squared",Exp[2I Pi pe]},{"A3",-Exp[2I Pi pe]},
 {"A4",Exp[2I Pi pe]},{"A6",Exp[2I Pi pe]}}}];
opposite=record["A2ConjugateProduct"];
FTTest`FTAssert["opposite causal bubbles have cancelling continuation phases",opposite["ContinuationFactor"]===1];
FTTest`FTAssert["opposite normalized bubble measure gives minus the complex modulus squared",
 Abs[N[(opposite["ExactValue"]+bubble["ExactValue"]Conjugate[bubble["ExactValue"]])/.{ps->5,pe->-1/3},30]]<10^-25];
FTTest`FTAssert["taking the real part before squaring is detectably incorrect",
 Abs[N[(opposite["ExactValue"]+Re[bubble["ExactValue"]]^2)/.{ps->5,pe->-1/3},30]]>10^-3];
Block[{FeynFacet`$MasterIntegralLibraryMode="Disabled"},
 space=FeynFacet`EvaluateMasslessVertexMaster["A2",ps,pe,{0,0}];
 time=FeynFacet`EvaluateMasslessVertexMaster["A2",ps,pe,{0,0},"Timelike"];
 FTTest`FTAssert["continuation is applied before discarding the negative epsilon orders",
  AssociationQ[time]&&FullSimplify[time["Coefficients"][{1,0}]-space["Coefficients"][{1,0}]-I Pi,ps>0]===0];
 square=FeynFacet`EvaluateMasslessVertexMaster["A2Squared",ps,pe,{0,0},"Timelike"];
 series=Normal[Series[bubble["ExactValue"],{pe,0,1}]];
 FTTest`FTAssert["finite two-loop product retains phase-times-pole terms",
  AssociationQ[square]&&FullSimplify[square["Coefficients"][{1,0}]-Coefficient[Expand[series^2],pe,0],ps>0]===0]
];
mixed=Join[FeynFacet`MasslessVertexMasterDefinition["A6",{pl1,pl2},{pp1,pp2},ps,pe],
 <|"CausalPrescription"->{-1,1,1,1,1,1}|>];
FTTest`FTAssert["connected mixed prescriptions cannot use a common homogeneity phase",
 FailureQ[FeynFacet`Private`masslessVertexTimelikePhase[mixed,pe]]];
Print["TIMELIKE VERTEX TEST COMPLETE"];
FTTest`FTReport[];
