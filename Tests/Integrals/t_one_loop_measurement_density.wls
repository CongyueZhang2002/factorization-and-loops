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
nonlinear=Join[reduced,<|"InteriorValues"->Map[#^2&,reduced["InteriorValues"]]|>];
FTTest`FTAssert["nonlinear scalar-loop products cannot be silently discarded",
 MatchQ[FeynFacet`ConstructOneLoopMeasurementDensity[nonlinear,coordinates,definition,request],
  Failure["LinearScalarLoopFunctionCombinationRequired",_]]];
restricted=FeynFacet`ConstructOneLoopMeasurementDensity[reduced,coordinates,
 Join[definition,<|"Assumptions"->ps>0&&0<pz<1/2|>],request];
FTTest`FTAssert["a broader request cannot discard the defining physical domain",
 AssociationQ[restricted]&&TrueQ[FullSimplify[restricted["MeasurementGeometry"]["Domain"]\[Implies]pz<1/2]]];
fakeCard=<|"Assembly"-><|"IntegrationMethod"->"PolynomialMeasurement"|>,
 "FinalMomenta"->particles,"UnobservedPartons"->{"q","qb","g"},
 "Channel"->"source","Channels"-><|"source"-><|"Incoming"->{"q"},"Observed"->None|>|>|>;
FTTest`FTAssert["scattering channels are rejected before decay generation",
 MatchQ[FeynFacet`PrepareMeasuredCurrentOneLoopContribution[fakeCard],Failure["ThreeParticleOneLoopTreeDecayRequired",_]]];
endpointProof=FeynFacet`ResolveOneLoopMeasurementIntegrationEndpoints[density];
FTTest`FTAssert["both exact regulated energy endpoints justify coefficientwise integration",
 AssociationQ[endpointProof]&&endpointProof["LaurentExpansionUnderIntegralEstablished"]&&
 Length[endpointProof["Endpoints"]]===2&&!endpointProof["MeasurementEndpointDistributionsEstablished"]];
external=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 FeynCalc`Momentum[pk1+pk3,D],0,0,{1,-1}]];
externalReduced=FeynFacet`ReduceOneLoopIntegrands[<|"Scalar"->loop external|>,kin,<|"LoopMomentum"->pl|>];
externalDensity=FeynFacet`ConstructOneLoopMeasurementDensity[externalReduced,coordinates,definition,request];
externalProof=FeynFacet`ResolveOneLoopMeasurementIntegrationEndpoints[externalDensity];
FTTest`FTAssert["an external causal denominator is bounded under the integral while the loop phase remains",
 AssociationQ[externalProof]&&externalProof["ExternalPrescriptionLimitEstablished"]&&
 !FreeQ[externalDensity["Branches"],FeynCalc`StandardPropagatorDenominator[_,_,_,{1,-1}]]&&
 !externalDensity["VirtualPrescriptionRemoved"]];
If[!AssociationQ[externalProof],Print[InputForm[{externalDensity,externalProof}]]];
singular=FeynFacet`ConstructOneLoopMeasurementDensity[reduced,coordinates,definition,
 Join[request,<|"Weight"->weight/(2FeynCalc`SPD[pk1,pk2])^5|>]];
FTTest`FTAssert["nonintegrable regulated energy endpoints cannot be expanded under the integral",
 MatchQ[FeynFacet`ResolveOneLoopMeasurementIntegrationEndpoints[singular],Failure["RegulatedEnergyEndpointSubtractionRequired",_]]];
globalBasisSymbolBefore=System`Names["Global`GLI"];
integrated=FeynFacet`IntegrateOneLoopMeasurementInterior[density,{-1,-1}];
FTTest`FTAssert["loading the GPL evaluator does not introduce a global FeynCalc shadow",
 System`Names["Global`GLI"]===globalBasisSymbolBefore];
FTTest`FTAssert["the measured bubble Laurent coefficient is integrated explicitly",
 AssociationQ[integrated]&&integrated["IntegralEvaluated"]&&FreeQ[integrated["Coefficients"],_Integrate|_NIntegrate]];
If[AssociationQ[integrated],
 value=FeynFacetSolution`EvaluateGPLExpression[integrated["Coefficients"][{1,-1}],{ps->2,pz->1/3},"WorkingPrecision"->40];
 reference=I Pi^2*ps/(512Pi^3)*Beta[3,3]Hypergeometric2F1[3,3,6,pz]/.{ps->2,pz->1/3};
 FTTest`FTAssert["the integrated Laurent coefficient agrees with the independent Euler moment",
  NumberQ[value]&&Abs[value-N[reference,40]]<10^-28]];
Print["ONE LOOP MEASUREMENT DENSITY TEST COMPLETE"];
FTTest`FTReport[];
