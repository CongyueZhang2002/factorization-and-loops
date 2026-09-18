Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->ScalarThreeBody,"FinalMomenta"->{pk1,pk2,pk3},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
spec=<|"Arguments"->{pa,pb},"Observable"->ps FeynCalc`SPD[pa,pb]/(2FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]),
 "Weight"->FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]/ps^2,"Variable"->pz,
 "Tuples"-><|"Ordered"->True,"IncludeRepeated"->True|>|>;
terms=FeynFacet`FinalStateMeasurementTerms[spec,geometry["FinalMomenta"]];
definitions=Map[FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|
 "Measurements"->{KeyTake[#,{"Variable","Observable"}]}|>]]&,terms];

pair=definitions[[2]];
den=FeynCalc`FCI[FeynCalc`SFAD[pk1+pk3]];
prepared=FeynFacet`PrepareCutIntegrand[terms[[2,"Weight"]]den,pair,<|"ExternalKinematicConditions"->ps>0|>];
FTTest`FTAssert["energy-denominator measurement uses the original compact-cut proof",AssociationQ[prepared]];
If[!AssociationQ[prepared],Print[InputForm[prepared]];FTTest`FTReport[]];
cert=prepared["OrdinaryPrescriptionCertificate"];
FTTest`FTAssert["both energy factors are included in the convergence majorant",
 Length[cert["MeasurementDenominatorMajorants"]]===2&&cert["OrdinaryPrescriptionRemoved"]===True];
source=prepared["SourceDefinition"];target=FeynCalc`GLI[source["Topology"][[1]],{2,1,1,3,2}];
raised=FeynFacet`CertifyOrdinaryPrescriptionRemoval[source,target,<|"ExternalKinematicConditions"->ps>0|>];
FTTest`FTAssert["raised particle and measurement cuts share a finite parent domination bound",AssociationQ[raised]&&
 raised["ParticleNormalDerivativeOrder"]===1&&raised["MeasurementPairings"][[1,"DenominatorPowerBound"]]===5];
If[!AssociationQ[raised],Print[InputForm[raised]]];
FTTest`FTAssert["measurement distribution proof does not assert external endpoint coefficients",
 FailureQ[FeynFacet`RequireOrdinaryPrescriptionCertificate[cert,"EndpointDistributions"]]&&cert["EndpointCoefficientsComputed"]===False];
bad=FeynFacet`PrepareCutIntegrand[1/(FeynCalc`SPD[pq,pk1]-ps/4),pair,<|"ExternalKinematicConditions"->ps>0|>];
FTTest`FTAssert["an ordinary denominator crossing the physical interior remains rejected",FailureQ[bad]];
Print["POLYNOMIAL PRESCRIPTIONS TEST COMPLETE"];
FTTest`FTReport[];
