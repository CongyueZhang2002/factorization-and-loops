$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
FeynCalc`FCSetDiracGammaScheme["BMHV"];FeynCalc`$LeviCivitaSign=-1;
laKin=FeynCalc`FCI[{FeynCalc`SPD[laP]->0,FeynCalc`SPD[laN]->0,FeynCalc`SPD[laP,laN]->laS/2}];
laRequest=<|"KinematicRules"->laKin,"Assumptions"->laS>0|>;
laAverage=FeynFacet`AverageLongitudinalEpsilonProduct[{laA,laB},{laC,laE},laP,laN,laRequest];
laMomenta={laP,laN,laK1,laK2,laK3,laK4};
laContract=FeynCalc`FVD[laK1,laA]FeynCalc`FVD[laK2,laB]FeynCalc`FVD[laK3,laC]FeynCalc`FVD[laK4,laE];
laEpsilonProduct=FeynCalc`LC[laA,laB][laP,laN]FeynCalc`LC[laC,laE][laP,laN];
laPhysical=FeynFacet`EvaluateFORMDiracExpression[laEpsilonProduct laContract,<|
 "Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"Gamma5Scheme"->"BMHV","KinematicRules"->laKin|>];
laGeometry=<|"PhysicalMomenta"->{laP,laN},"IntegratedMomenta"->{laK1,laK2,laK3,laK4},
 "TimelikeMomentum"->laP+laN,"KinematicRules"->laKin,"Assumptions"->laS>0,"DimensionalRegulator"->laEps|>;
laAveraged=FeynFacet`AverageEvanescentScalarProducts[laPhysical["Value"],laGeometry];
laExpected=FeynFacet`EvaluateFORMDiracExpression[laAverage["Value"]laContract,<|
 "Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"KinematicRules"->laKin|>];
FTTest`FTAssert["four arbitrary full-D vector contractions prove the averaged two-form tensor",
 AssociationQ[laAveraged]&&AssociationQ[laExpected]&&Factor[laAveraged["Value"]-laExpected["Value"]]===0];
FTTest`FTAssert["the tensor normalization gives the exact Larin current-dual ratio",
 Factor[(laAverage["LarinNormalizationRatio"]/.D->4-2laEps)-(1-laEps)(1-2laEps)]===0];
laNorm=FeynFacet`EvaluateFORMDiracExpression[
 laAverage["Value"]FeynCalc`MTD[laA,laC]FeynCalc`MTD[laB,laE],<|
 "Momenta"->{laP,laN},"PhysicalMomenta"->{laP,laN},"KinematicRules"->laKin|>];
FTTest`FTAssert["the physical oriented two-plane has norm two at generic dimension",
 AssociationQ[laNorm]&&Factor[laNorm["Value"]-laS^2/2]===0];
laWeighted=FeynFacet`AverageEvanescentScalarProducts[
 laPhysical["Value"]FeynCalc`FCI[FeynCalc`SPD[laK1,laK2]],laGeometry];
FTTest`FTAssert["a full-D invariant numerator commutes with the same joint average",
 AssociationQ[laWeighted]&&Factor[laWeighted["Value"]-
 FeynCalc`FCI[FeynCalc`SPD[laK1,laK2]]laExpected["Value"]]===0];
FTTest`FTAssert["a non-null incoming longitudinal momentum is rejected",
 FailureQ[FeynFacet`AverageLongitudinalEpsilonProduct[{laA,laB},{laC,laE},laP,laN,
  <|"KinematicRules"->ReplacePart[laKin,1->(FeynCalc`FCI[FeynCalc`SPD[laP]]->laS)],
   "Assumptions"->laS>0|>]]];
laCurrent=FeynFacet`DISCurrentProjectors[laP,laN,{laMu,laNu}]["CoefficientProjectors"]["2g1"];
laWords={
 FeynCalc`GAD[laNu].FeynCalc`GSD[laK1].FeynCalc`GAD[laMu],
 FeynCalc`GAD[laNu].FeynCalc`GSD[laK1].FeynCalc`GSD[laK2].FeynCalc`GSD[laK3].FeynCalc`GAD[laMu],
 FeynCalc`GAD[laNu].FeynCalc`GSD[laK1].FeynCalc`GAD[laRho].FeynCalc`GSD[laK2].
  FeynCalc`GSD[laK3].FeynCalc`GAD[laRho].FeynCalc`GAD[laMu]};
Do[
 laLeg=<|"Role"->"PDF","Species"->{species,"u"},"Polarization"->"L","Momentum"->laP,"MomentumSpace"->"Physical4"|>;
 laDensity=FeynFacet`AveragedDISHelicityDensity[laLeg,laP,laN,{laMu,laNu},laRequest];
 laOriginal=FeynFacet`PartonicSpinDensity[laLeg]["SpinDensity"];
 Do[
  laRaw=FeynFacet`EvaluateFORMDiracExpression[laCurrent FeynCalc`DiracTrace[laOriginal.word],
   <|"Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"Gamma5Scheme"->"BMHV","KinematicRules"->laKin|>];
  laRawAverage=FeynFacet`AverageEvanescentScalarProducts[laRaw["Value"],laGeometry];
  laDirect=FeynFacet`EvaluateFORMDiracExpression[FeynCalc`DiracTrace[laDensity["SpinDensity"].word],
   <|"Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"KinematicRules"->laKin|>];
  FTTest`FTAssert[species<>" joint current-density identity for an ordered word of length "<>ToString[Length[word]],
   AssociationQ[laRawAverage]&&AssociationQ[laDirect]&&Factor[laRawAverage["Value"]-laDirect["Value"]]===0],
 {word,laWords}],
 {species,{"q","qbar"}}];
laGluonLeg=<|"Role"->"PDF","Species"->"g","Polarization"->"L","Momentum"->laP,
 "MomentumSpace"->"Physical4","ReferenceMomentum"->laN,"Indices"->{laG1,laG2}|>;
laGluonDensity=FeynFacet`AveragedDISHelicityDensity[laGluonLeg,laP,laN,{laMu,laNu},laRequest];
laGluonTensor=FeynCalc`FVD[laK1,laG1]FeynCalc`FVD[laK2,laG2]FeynCalc`FVD[laK3,laMu]FeynCalc`FVD[laK4,laNu];
laGluonRaw=FeynFacet`EvaluateFORMDiracExpression[
 FeynFacet`PartonicSpinDensity[laGluonLeg]["SpinDensity"]laCurrent laGluonTensor,
 <|"Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"Gamma5Scheme"->"BMHV","KinematicRules"->laKin|>];
laGluonAverage=FeynFacet`AverageEvanescentScalarProducts[laGluonRaw["Value"],laGeometry];
laGluonDirect=FeynFacet`EvaluateFORMDiracExpression[laGluonDensity["SpinDensity"]laGluonTensor,
 <|"Momenta"->laMomenta,"PhysicalMomenta"->{laP,laN},"KinematicRules"->laKin|>];
FTTest`FTAssert["the gluon density-current identity preserves both index order and normalization",
 AssociationQ[laGluonAverage]&&AssociationQ[laGluonDirect]&&Factor[laGluonAverage["Value"]-laGluonDirect["Value"]]===0];

laEligibility=<|"PhysicalMomenta"->{laP,laN},"JointMomenta"->laMomenta,"MomentumRules"->{}|>;
FTTest`FTAssert["an additional epsilon tensor cannot use the two-epsilon shortcut",
 !FeynFacet`Private`currentJointHelicityAmplitudeQ[
  FeynCalc`FCI[FeynCalc`LC[laA,laB][laK1,laK2]],laEligibility]];
FTTest`FTAssert["an additional physical metric cannot use the isotropic shortcut",
 !FeynFacet`Private`currentJointHelicityAmplitudeQ[FeynCalc`FCI[FeynCalc`MT[laA,laB]],laEligibility]];
FTTest`FTAssert["undeclared integrated vectors are rejected",
 !FeynFacet`Private`currentJointHelicityAmplitudeQ[FeynCalc`FCI[FeynCalc`GSD[laUnknown]],laEligibility]];
FTTest`FTReport[];
