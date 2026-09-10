$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[lp,ref,total,kA,kB,sInvariant,jProjection,zMeasured,epsilonTest,evSquare];
geometry=ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->ref,"TotalMomentum"->total,
 "FinalMomenta"->{kA,kB},"InvariantMassSquared"->sInvariant,"ReferenceProjection"->jProjection,
 "MeasurementVariable"->zMeasured,"EvanescentSquare"->evSquare,"DimensionalRegulator"->epsilonTest,
 "Assumptions"->sInvariant>0&&jProjection>0&&0<zMeasured<1|>];
FeynCalc`SPD[total,total]=17;
before={DownValues[FeynCalc`Pair],DownValues[FeynCalc`ScalarProduct],
 DownValues[FeynCalc`SP],DownValues[FeynCalc`SPD],DownValues[FeynCalc`SPE],FeynCalc`$ScalarProducts};
values=<|"Bubble"->FeynCalc`FAD[lp,lp+total],
 "FirstMoment"->FeynCalc`SPD[lp,kA]FeynCalc`FAD[lp,lp+total]|>;
result=ReduceMeasuredOneLoopIntegrands[values,geometry,<|"LoopMomentum"->lp|>];
If[FailureQ[result],Print[result]];
FTAssert["the measured vector bubble obeys its exact tensor-reduction identity",
 AssociationQ[result]&&Together[result["Values"]["FirstMoment"]+
 sInvariant/4 result["Values"]["Bubble"]]===0];
after={DownValues[FeynCalc`Pair],DownValues[FeynCalc`ScalarProduct],
 DownValues[FeynCalc`SP],DownValues[FeynCalc`SPD],DownValues[FeynCalc`SPE],FeynCalc`$ScalarProducts};
FTAssert["caller scalar-product definitions are restored exactly",before===after];
FTAssert["the virtual prescription and unperformed phase-space multiplication are explicit",
 result["VirtualPrescriptionRemoved"]===False&&result["PhaseSpaceDensityIncluded"]===False];
bad=ReduceMeasuredOneLoopIntegrands[<|"Physical"->FeynCalc`SP[lp,lp]FeynCalc`FAD[lp,lp+total]|>,
 geometry,<|"LoopMomentum"->lp|>];
FTAssert["unaveraged four-dimensional loop numerators cannot enter full-D reduction",
 MatchQ[bad,Failure["FullDimensionalScalarLoopNumeratorRequired",_]]];
FTReport[];
