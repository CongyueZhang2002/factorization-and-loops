Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
qg=FeynCalc`FCI[qs^2 qz-(4FeynCalc`SPD[qa,qk]-qs)^2];
qt=FeynCalc`FCTopology[QuadraticAngularMeasurement,{
 FeynCalc`FCI[FeynCalc`SFAD[qk]],FeynCalc`FCI[FeynCalc`SFAD[qP-qk]],
 FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,FeynCalc`FCI[FeynCalc`SPD[qa,qk]],0,{1,1}]],
 FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[qg,{1,1}]]},
 {qk},{qP,qa},FeynCalc`FCI[{FeynCalc`SPD[qP]->qs,FeynCalc`SPD[qa]->0,FeynCalc`SPD[qP,qa]->qs/2}],{}];
qf=FeynFacet`CreateCutIntegralFamily[<|"Topology"->qt,"Cuts"->{
 <|"Index"->1,"Type"->"Particle","Momentum"->qk|>,
 <|"Index"->2,"Type"->"Particle","Momentum"->qP-qk|>,
 <|"Index"->4,"Type"->"Measurement"|>},"TimeDirection"->qP,
 "Assumptions"->qs>0&&0<qz<1,"Dimension"->D,"MeasurePrefactor"->qs^2 (2Pi)^(2-D)|>];
FTTest`FTAssert["quadratic measurement uses a complete affine basis plus a dependent cut",AssociationQ[qf]];
If[!AssociationQ[qf],Print[qf];FTTest`FTReport[]];
FTTest`FTAssert["only the independent scalar-product coordinates are inverted",
 qf["AffineBasisIndices"]==={1,2,3}&&qf["DenominatorDegrees"]==={1,1,1,2}&&Keys[qf["DependentDenominatorRelations"]]==={4}];
qi=FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,0,1}];
qd=FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,0,2}];
FTTest`FTAssert["quadratic cut differentiation has the exact sign and scale",
 Factor[FeynFacet`DifferentiateCutIntegral[qf,qi,qz]+qs^2 qd]===0];
qmult=FeynFacet`MultiplyCutIntegral[qf,qi,(4FeynCalc`FCI[FeynCalc`SPD[qa,qk]]/qs-1)^2];
qmultExpected=qi-8/qs FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,-1,1}]+16/qs^2 FeynCalc`GLI[QuadraticAngularMeasurement,{1,1,-2,1}];
FTTest`FTAssert["polynomial insertion retains the quadratic numerator exactly",Factor[qmult-qmultExpected]===0];
qe=FeynFacet`GenerateCutIBPEquations[qf,{qi,qd}];
FTTest`FTAssert["momentum IBPs include the automatically generated denominator identity",
 AssociationQ[qe]&&qe["OperatorCount"]===3&&qe["AlgebraicRelationCount"]===1];
qRows=Total[KeyValueMap[Times,#]]&/@qe["Rows"];
qRelation=qs^2 qz qi-qs^2 qmult;
FTTest`FTAssert["the unit-cut algebraic relation is present without dividing by a loop variable",
 AnyTrue[qRows,Factor[#-qRelation]===0&]];
FTTest`FTAssert["every generated relation retains positive powers on mandatory cuts",
 AllTrue[Flatten[Keys/@qe["Rows"]],AllTrue[#[[2,qf["CutIndices"]]],#>0&]&]];
qDerivativeS=FeynFacet`DifferentiateCutIntegral[qf,qi,qs];
FTTest`FTAssert["external scale differentiation closes on finite polynomial shifts",
 FreeQ[qDerivativeS,_Failure|_FeynCalc`Pair|_Derivative]];
qFront=DeleteDuplicates[Join[{qi,qd},Cases[qDerivativeS,_FeynCalc`GLI,Infinity]]];
qPred=FeynFacet`FindCutIBPPredecessorSeeds[qf,qFront,{qi}];
FTTest`FTAssert["predecessor selection supports quadratic and defining-relation shifts",AssociationQ[qPred]];
Print["QUADRATIC ALGEBRA TEST COMPLETE"];
FTTest`FTReport[];
