$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mcRequest=<|"ReferenceMomentum"->mcP,"TotalMomentum"->mcTot,"ParticleMomenta"->{mcK1,mcK2,mcK3},
 "InvariantMassSquared"->mcS,"ReferenceProjection"->mcJ/2,"MeasurementVariable"->mcZ,
 "DimensionalRegulator"->mcEps,"Parameters"->{mcR,mcU,mcB},
 "Assumptions"->mcS>0&&mcJ>0&&0<mcZ<1,"AngularAxis"->"TaggedParticle",
 "AngularFractionSymbol"->mcY|>;
mcChart=FeynFacet`ConstructMeasuredThreeParticlePhaseSpace[mcRequest];
FTTest`FTAssert["the rotated angular chart is constructed",AssociationQ[mcChart]];
mcRule=mcChart["ScalarProductRules"];
mcGram=Table[FeynCalc`FCI[FeynCalc`SPD[aa,bb]]/.mcRule,{aa,mcChart["FullGramMomenta"]},{bb,mcChart["FullGramMomenta"]}];
FTTest`FTAssert["the rotated scalar products reconstruct the Gram determinant",
 Factor[Det[mcGram]-mcChart["FullGramDeterminant"]]===0];
mcZr=mcZ+(1-mcZ)mcR;
FTTest`FTAssert["the radial substitution gives the exact measure Jacobian",
 FullSimplify[(mcR/mcZr)^mcA (1-mcR/mcZr)^mcA D[mcR/mcZr,mcR]/
 (mcR^mcA(1-mcR)^mcA)-mcZ^(mcA+1)mcZr^(-2mcA-2),
 Assumptions->0<mcZ<1&&0<mcR<1&&Element[mcA,Reals]]===0];
mcGauge=FeynCalc`FCI[FeynCalc`SPD[mcTot,mcK2]]/.mcChart["RationalScalarProductRules"];
FTTest`FTAssert["the gauge denominator isolates its additive endpoint",
 Factor[mcGauge-mcS mcZ/(2mcZr)(mcU+(1-mcZ)mcR/mcZ)]===0];
mcSyst=<|"KinematicVariables"->{mcZ,mcW},"DimensionalRegulator"->mcEps,
 "ConnectionMatrices"->{ {{0,1,0},{0,0,0},{0,0,0}},ConstantArray[0,{3,3}]}|>;
mcRestricted=FeynFacet`RestrictDifferentialSystemToRelations[mcSyst,{{1,0,0}}];
FTTest`FTAssert["differentiating a supplied relation eliminates its dependent direction",
 AssociationQ[mcRestricted]&&mcRestricted["Dimension"]===1&&mcRestricted["Verification"]["Embedding"]];
mcA2={{mcEps/mcZ,0},{0,-2mcEps/mcZ}};
mcT2={{1,1/mcZ},{0,1}}.{{1,1},{1,2}};
mcRaw=Map[Together,(D[mcT2,mcZ]+mcT2.mcA2).Inverse[mcT2],{2}];
mcNormal=FeynFacet`NormalizeRegularSingularSystem[<|"Variable"->mcZ,"DimensionalRegulator"->mcEps,"ConnectionMatrix"->mcRaw|>];
FTTest`FTAssert["a nondiagonal singular gauge is normalized without a supplied basis",
 AssociationQ[mcNormal]&&FeynFacet`Private`localNormalizePoleOrder[mcNormal["ConnectionMatrix"],mcZ]<=1];
FTTest`FTReport[];
