$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mcFamily=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|
 "Name"->mcFamilyName,"FinalMomenta"->{mcK1,mcK2,mcK3},
 "TotalMomentum"->mcP+mcQ,"ExternalMomenta"->{mcP,mcQ},
 "ReferenceMomentum"->mcP,"TaggedMomentum"->mcK1,"MeasurementVariable"->mcZ,
 "KinematicRules"->{FeynCalc`SPD[mcP]->0,FeynCalc`SPD[mcQ]->0,FeynCalc`SPD[mcP,mcQ]->mcS/2},
 "Assumptions"->mcS>0&&0<mcZ<1,
 "OrdinaryPropagators"->{FeynCalc`SFAD[mcK2+mcK3]}|>];
mcDefs=FeynFacet`ConstructMasterIntegralDefinitions[<|"DimensionalRegulator"->mcEps,
 "Families"->{mcFamily},"MasterIntegralBasis"->{
 FeynCalc`GLI[mcFamilyName,{1,1,1,1,0}],FeynCalc`GLI[mcFamilyName,{1,1,1,1,1}],
 FeynCalc`GLI[mcFamilyName,{2,1,1,1,0}]}|>]["MasterIntegralDefinitions"];
mcChart=FeynFacet`ConstructMeasuredThreeParticleIntegral[mcDefs[1],<|"Parameters"->{mcT,mcY,mcA}|>];
Print["CHART ",If[AssociationQ[mcChart],KeyTake[mcChart,{"DataType","ScalarIntegrand","MeasureConversionFactor"}],mcChart]];
FTTest`FTAssert["normalized unit-cut definitions reach the common exact phase-space chart",
 AssociationQ[mcChart]&&mcChart["ScalarIntegrand"]===1&&mcChart["MeasureConversionFactor"]===1];
mcProp=FeynFacet`ConstructMeasuredThreeParticleIntegral[mcDefs[2],<|"Parameters"->{mcT,mcY,mcA}|>];
FTTest`FTAssert["the unobserved pair invariant has its independently factorized form",
 AssociationQ[mcProp]&&Factor[mcProp["ScalarIntegrand"]-1/(mcS(1-mcZ)mcT)]===0];
mcMoment=Gamma[-mcEps]Gamma[2-2mcEps]/(Gamma[1-2mcEps]Gamma[1-mcEps]);
FTTest`FTAssert["the analytic inverse pair-mass moment retains its dimensional pole",
 FullSimplify[FunctionExpand[mcMoment]+(1-2mcEps)/mcEps]===0];
mcScaled=FeynFacet`ConstructMeasuredThreeParticleIntegral[
 Join[mcDefs[1],<|"MasterIntegralPrefactor"->2/3|>],<|"Parameters"->{mcT,mcY,mcA}|>];
FTTest`FTAssert["a declared master prefactor is preserved exactly",mcScaled["MeasureConversionFactor"]===2/3];
FTTest`FTAssert["the unit-cut chart refuses a differentiated particle delta",
 FailureQ[FeynFacet`ConstructMeasuredThreeParticleIntegral[mcDefs[3]]]];

mcLimit=FeynFacet`ConstructMeasuredRecoilBoundaryIntegral[mcProp,<|
 "NormalVariable"->mcRho,"SourceVariableSubstitution"->{mcS->mcJ mcRho},
 "Assumptions"->mcJ>0&&0<mcZ<1&&0<mcRho<1/2|>];
(* Here J also vanishes with S, so this geometry must not be certified as
   a finite-null-projection recoil limit. *)
FTTest`FTAssert["the recoil proof rejects a simultaneously vanishing null projection",
 FailureQ[mcLimit]&&mcLimit[[1]]==="VanishingTimelikeRecoilAndFiniteNullProjectionRequired"];
mcChange={{1,mcZ},{0,1}};
mcResidue=mcChange.DiagonalMatrix[{0,-2mcEps}].Inverse[mcChange];
mcGamma=D[mcChange,mcZ].Inverse[mcChange]+mcChange.DiagonalMatrix[{0,mcEps/mcZ}].Inverse[mcChange];
mcEndpoint=FeynFacet`ConstructTangentialEndpointSystem[<|
 "NormalVariable"->mcRho,"TangentialVariable"->mcZ,"DimensionalRegulator"->mcEps,
 "NormalConnectionMatrix"->mcResidue/mcRho,"TangentialConnectionMatrix"->mcGamma|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"Positive normal and tangential variables.",
 "BranchPrescription"->"Positive real normal variable."|>,"NormalGaugeMatrix"->IdentityMatrix[2]];
mcSector=FeynFacet`ConstructEndpointSectorDifferentialSystem[mcEndpoint,-2mcEps];
FTTest`FTAssert["a varying residue eigenspace induces its connection with the basis derivative",
 AssociationQ[mcSector]&&mcSector["Dimension"]===1&&
 mcSector["Verification"]["TangentialConnection"]===True];

mcRecoilFamily=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|
 "Name"->mcRecoilFamilyName,"FinalMomenta"->{mcK1,mcK2,mcK3},
 "TotalMomentum"->mcP+mcQ,"ExternalMomenta"->{mcP,mcQ},
 "ReferenceMomentum"->mcP,"TaggedMomentum"->mcK1,"MeasurementVariable"->mcZ,
 "KinematicRules"->{FeynCalc`SPD[mcP]->0,FeynCalc`SPD[mcQ]->mcS-mcJ,FeynCalc`SPD[mcP,mcQ]->mcJ/2},
 "Assumptions"->mcJ>mcS>0&&0<mcZ<1,
 "OrdinaryPropagators"->{FeynCalc`SFAD[mcK2+mcK3],FeynCalc`SFAD[mcP-mcK2-mcK3]}|>];
mcRecoilDefs=FeynFacet`ConstructMasterIntegralDefinitions[<|"DimensionalRegulator"->mcEps,
 "Families"->{mcRecoilFamily},"MasterIntegralBasis"->{
 FeynCalc`GLI[mcRecoilFamilyName,{1,1,1,1,1,1}]}|>]["MasterIntegralDefinitions"];
mcRecoilChart=FeynFacet`ConstructMeasuredThreeParticleIntegral[mcRecoilDefs[1],
 <|"Parameters"->{mcT,mcY,mcA}|>];
mcRecoil=FeynFacet`ConstructMeasuredRecoilBoundaryIntegral[mcRecoilChart,<|
 "NormalVariable"->mcRho,"SourceVariableSubstitution"->{mcS->mcJ mcRho},
 "Assumptions"->mcJ>0&&0<mcZ<1&&0<mcRho<1/2|>];
FTTest`FTAssert["the physical recoil proof keeps the null projection finite and includes subset denominators",
 AssociationQ[mcRecoil]&&mcRecoil["RegulatorSlope"]===-2&&
 MemberQ[Lookup[Values[mcRecoil["DenominatorCertificates"]],"Type"],"NullReferenceMinusFutureSubset"]];
FTTest`FTAssert["the uniform recoil coefficient preserves the ordinary denominator sign",
 AssociationQ[mcRecoil]&&Factor[mcRecoil["ScalarIntegrand"]+1/(mcJ^2(1-mcZ)^2 mcT)]===0];

FTTest`FTReport[];
