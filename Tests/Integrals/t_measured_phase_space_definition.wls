$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mfRequest=<|"Name"->MeasuredFactory,"FinalMomenta"->{mfK1,mfK2,mfK3},
 "TotalMomentum"->mfP+mfQ,"ExternalMomenta"->{mfP,mfQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[mfP]->0,FeynCalc`SPD[mfQ]->-mfS,
  FeynCalc`SPD[mfP,mfQ]->mfS/(2mfX)}],
 "ReferenceMomentum"->mfP,"TaggedMomentum"->mfK1,"MeasurementVariable"->mfZ,
 "Assumptions"->mfS>0&&0<mfX<1&&0<mfZ<1|>;
mfDefinition=FeynFacet`CreateMeasuredPhaseSpaceDefinition[mfRequest];
FTTest`FTAssert["three forward cuts and one energy-free measurement are generated",
 AssociationQ[mfDefinition]&&mfDefinition["ParticleCutIndices"]==={1,2,3}&&
 mfDefinition["MeasurementCutIndices"]==={4}&&mfDefinition["Cuts"][[4]]["PositiveEnergyCondition"]===None];
FTTest`FTAssert["the phase-space normalization includes the measurement Jacobian",
 Factor[mfDefinition["MeasurePrefactor"]-(2Pi)^(3-2D)mfS/mfX]===0];
FTTest`FTAssert["last-particle routing and the measurement polynomial follow from geometry",
 mfDefinition["MomentumConservationRules"]==={mfK3->-mfK1-mfK2+mfP+mfQ}&&
 Factor[mfDefinition["InversePropagators"][[4]]-
  2FeynCalc`FCI[FeynCalc`SPD[mfP,mfK1]]+mfZ mfS/mfX]===0];
mfRecoil=FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[mfRequest,<|"TaggedMomentum"->mfK3|>]];
FTTest`FTAssert["the observed leg can be the eliminated final momentum",
 AssociationQ[mfRecoil]&&FreeQ[mfRecoil["InversePropagators"],mfK3]&&
 Factor[mfRecoil["InversePropagators"][[4]]-
  ((1-mfZ)mfS/mfX-2FeynCalc`FCI[FeynCalc`SPD[mfP,mfK1]+FeynCalc`SPD[mfP,mfK2]] )]===0];
mfTwo=FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[mfRequest,<|"FinalMomenta"->{mfK1,mfK2}|>]];
FTTest`FTAssert["the same factory covers two-particle phase space",
 AssociationQ[mfTwo]&&mfTwo["Topology"][[3]]==={mfK1}&&
 Factor[mfTwo["MeasurePrefactor"]-(2Pi)^(2-D)mfS/mfX]===0];
FTTest`FTAssert["a spacelike measurement reference is rejected",
 FailureQ[FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[mfRequest,<|"ReferenceMomentum"->mfQ|>]]]];
FTTest`FTReport[];
