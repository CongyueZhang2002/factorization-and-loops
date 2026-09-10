$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[lp,pRef,pTotal,kTag,kOther,sMass,jProj,zFrac,eReg,hatSquare,hLL,hLK,hKK];
geometry=ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pRef,"TotalMomentum"->pTotal,
 "FinalMomenta"->{kTag,kOther},"InvariantMassSquared"->sMass,"ReferenceProjection"->jProj,
 "MeasurementVariable"->zFrac,"EvanescentSquare"->hatSquare,"DimensionalRegulator"->eReg,
 "Assumptions"->sMass>0&&jProj>0&&0<zFrac<1|>];
gram={{0,jProj},{jProj,sMass}};kk=-sMass zFrac(1-zFrac);
loopProducts=FeynCalc`FCI[{FeynCalc`SPD[lp,pRef],FeynCalc`SPD[lp,pTotal]}];
ll=FeynCalc`FCI[FeynCalc`SPD[lp]]-loopProducts.Inverse[gram].loopProducts;
lk=FeynCalc`FCI[FeynCalc`SPD[lp,kTag]]-loopProducts.Inverse[gram].{zFrac jProj,sMass/2};
ambient=D-2;hatted=D-4;
twoForm=2/(ambient(ambient-1))(ll kk-lk^2);
cross=AverageEvanescentScalarProducts[hLK^2,{{hLL,hLK},{hLK,hKK}},
 {{ll,lk},{lk,kk}},eReg]/.eReg->(4-D)/2;
values=<||>;
Do[
 denominators=FeynCalc`FAD[lp,lp+kTag+sign pRef];
 AssociateTo[values,{ToString[sign]<>"Bubble"->denominators,
  ToString[sign]<>"TwoForm"->twoForm denominators,
  ToString[sign]<>"HattedCross"->cross denominators}],
 {sign,{-1,1}}];
result=ReduceMeasuredOneLoopIntegrands[values,geometry,<|"LoopMomentum"->lp|>];
If[FailureQ[result],Print[result];FTAssert["joint loop covariance can be reduced",False];FTReport[]];
Do[
 bubble=result["Values"][ToString[sign]<>"Bubble"];ksq=sign 2jProj zFrac;
 FTAssert["physical two-form average agrees with loop-first tensor integration, sign "<>ToString[sign],
  Factor[result["Values"][ToString[sign]<>"TwoForm"]+
   ksq kk/(2ambient(D-1))bubble]===0];
 expected=bubble/(4(D-1))*(D hatted(hatted+2)/(ambient(ambient+2))kk^2-
   ksq hatted/ambient kk);
 FTAssert["correlated hatted products agree with independent loop-first integration, sign "<>ToString[sign],
  Factor[result["Values"][ToString[sign]<>"HattedCross"]-expected]===0],
 {sign,{-1,1}}];
FTReport[];
