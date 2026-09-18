Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
particles={pk1,pk2,pk3};
coordinates=FeynFacet`MasslessInvariantPhaseSpaceCoordinates[particles,pq,ps,pe,{pu,pv}];
kin=<|"ExternalMomenta"->particles,"MomentumRules"->{pq->Total[particles]},
 "KinematicRules"->coordinates["ScalarProductRules"],"Assumptions"->coordinates["PhysicalDomain"],"DimensionalRegulator"->pe|>;
loop=FeynCalc`FeynAmpDenominator@@(FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[#,D],0,0,{1,1}]&/@{pl,pl-pk1-pk2});
reduced=FeynFacet`ReduceOneLoopIntegrands[<|"Scalar"->loop|>,kin,<|"LoopMomentum"->pl|>];
geometry=<|"Name"->LoopPushforwardTest,"FinalMomenta"->particles,"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
observable=ps FeynCalc`SPD[pk1,pk2]/(2FeynCalc`SPD[pq,pk1]FeynCalc`SPD[pq,pk2]);
definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|
 "Measurements"->{<|"Variable"->pz,"Observable"->observable|>}|>]];
weight=FeynCalc`SPD[pq,pk1]FeynCalc`SPD[pq,pk2]/ps^2;
request=<|"Parameters"->{px,py},"Weight"->weight,"Assumptions"->ps>0&&0<pz<1|>;
density=FeynFacet`ConstructOneLoopMeasurementDensity[reduced,coordinates,definition,request];
FTTest`FTAssert["the generated causal loop density maps to the physical measurement chart",AssociationQ[density]];
If[!AssociationQ[density],Print[InputForm[density]];FTTest`FTReport[]];
branch=First[density["Branches"]];function=First[Keys[branch["ScalarFunctions"]]];
fraction=pz px(1-px)/(1-pz px);
FTTest`FTAssert["the bubble invariant is transported by the derived external Gram map",
 Factor[branch["ScalarFunctions"][function][[1]]/ps-fraction]===0];
FTTest`FTAssert["the loop tensor reduction measure is retained rather than normalized twice",
 Factor[branch["Coefficients"]["Scalar"][function]/(I Pi^2)-px^2(1-px)^2/(4(1-pz px)^3)]===0];
FTTest`FTAssert["unintegrated scalar functions retain exact regulator and causal metadata",
 density["ExactInRegulator"]&&density["PhaseSpaceDensityIncluded"]&&
 !density["IntegralEvaluated"]&&!density["VirtualPrescriptionRemoved"]&&!density["ConjugateInterferenceAdded"]];
bad=Join[coordinates,<|"ScalarProductRules"->(coordinates["ScalarProductRules"]/.pu->2pu)|>];
FTTest`FTAssert["an incompatible reduction chart is rejected before scalar insertion",
 MatchQ[FeynFacet`ConstructOneLoopMeasurementDensity[reduced,bad,definition,request],Failure["LoopReductionAndPhaseSpaceGramMismatch",_]]];
Print["ONE LOOP MEASUREMENT DENSITY TEST COMPLETE"];
FTTest`FTReport[];
