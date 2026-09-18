Print["FEYNFACET DRIVER ENTERED"];

$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/FeynFacet/Reduction/FamilyEquivalence.wl"];
feGeometry=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->feSource,
 "FinalMomenta"->{feK1,feK2,feK3},"TotalMomentum"->feP+feQ,"ExternalMomenta"->{feP,feQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[feP]->0,FeynCalc`SPD[feQ]->-feS,
  FeynCalc`SPD[feP,feQ]->feS/(2feX)}],"ReferenceMomentum"->feP,"TaggedMomentum"->feK1,
 "MeasurementVariable"->feZ,"Assumptions"->feS>0&&0<feX<1&&0<feZ<1|>];
fePrepared=FeynFacet`PrepareMeasuredCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[feP-feK2]],feGeometry,
 <|"ExternalKinematicConditions"->feS>0&&0<feX<1|>];
feOriginal=First[FeynFacet`DecomposeMeasuredCutIntegrand[fePrepared]["Families"]];
feA=FeynFacet`CreateCutIntegralFamily[Join[feOriginal,<|
 "Topology"->ReplacePart[feOriginal["Topology"],1->feFamilyA]|>]];
feAux=Last[feA["AuxiliaryIndices"]];feCut=First[feA["CutIndices"]];
feB=FeynFacet`CreateCutIntegralFamily[Join[feA,<|"Topology"->ReplacePart[feA["Topology"],
 {1->feFamilyB,{2,feAux}->FeynCalc`FeynAmpDenominator[
  FeynCalc`StandardPropagatorDenominator[0,2feA["InversePropagators"][[feAux]]+
    feA["InversePropagators"][[feCut]],0,{1,1}]]}]|>]];
feBase=ReplacePart[ConstantArray[1,Length[feA["Topology"][[2]]]],Thread[feA["AuxiliaryIndices"]->0]];
feA0=FeynCalc`GLI[feFamilyA,feBase];
feB1=FeynCalc`GLI[feFamilyB,ReplacePart[feBase,feAux->-1]];
feB2=FeynCalc`GLI[feFamilyB,ReplacePart[feBase,{feAux->-1,feCut->2}]];
feInput=<|"Format"->"FeynFacet-CombinedCutIntegralDecompositions","Families"->{feA,feB},
 "Targets"->{feA0,feB1,feB2},"Coefficients"-><|"A"-><|feA0->1|>,"B1"-><|feB1->1|>,"B2"-><|feB2->1|>|>|>;
feResult=FeynFacet`MergeEquivalentCutIntegralFamilies[feInput,<|"PreferredFamilies"->{feFamilyA}|>];
If[FailureQ[feResult],Print[feResult]];
FTTest`FTAssert["equivalent physical denominator supports share one family despite a different auxiliary basis",
 AssociationQ[feResult]&&Length[feResult["Families"]]===1];
feExpected1=<|FeynCalc`GLI[feFamilyA,ReplacePart[feBase,feAux->-1]]->2|>;
feExpected2=<|FeynCalc`GLI[feFamilyA,ReplacePart[feBase,{feAux->-1,feCut->2}]]->2,feA0->1|>;
FTTest`FTAssert["a numerator factor pinching a unit mandatory cut is exactly zero",
 AssociationQ[feResult]&&feResult["Coefficients"]["B1"]===feExpected1];
FTTest`FTAssert["a numerator factor lowering a dotted cut is retained with its correct sign",
 AssociationQ[feResult]&&KeySort[feResult["Coefficients"]["B2"]]===KeySort[feExpected2]];
feOrd=First[Complement[Range[Length[feBase]],Join[feA["CutIndices"],feA["AuxiliaryIndices"]]]];
feDifferent=FeynFacet`CreateCutIntegralFamily[Join[feB,<|"Topology"->ReplacePart[feB["Topology"],
 {2,feOrd}->(feB["Topology"][[2,feOrd]]/.
 FeynCalc`StandardPropagatorDenominator[aa_,bb_,cc_,{nn_,eta_}]:>
 FeynCalc`StandardPropagatorDenominator[aa,bb,cc,{nn,-eta}])]|>]];
feSeparate=FeynFacet`MergeEquivalentCutIntegralFamilies[Join[feInput,<|"Families"->{feA,feDifferent}|>]];
FTTest`FTAssert["opposite ordinary prescriptions do not identify families",
 AssociationQ[feSeparate]&&Length[feSeparate["Families"]]===2];
feMeasure=Join[feB,<|"MeasurePrefactor"->2feB["MeasurePrefactor"]|>];
feSeparate=FeynFacet`MergeEquivalentCutIntegralFamilies[Join[feInput,<|"Families"->{feA,feMeasure}|>]];
FTTest`FTAssert["different normalized measures do not identify families",
 AssociationQ[feSeparate]&&Length[feSeparate["Families"]]===2];
feB0=FeynCalc`GLI[feFamilyB,feBase];
feCertified=FeynFacet`FindCutIntegralEquivalences[{feA0,feB0},{feA,feDifferent},
 "Normalization"->"FullTypedIntegralDefinitions","PreferredMasterIntegrals"->{feA0},
 "OrdinaryPrescriptionGeometry"-><|"MeasurementVariable"->feZ,"ReferenceMomentum"->feP,
 "TaggedMomentum"->feK1,"ExternalKinematicConditions"->feS>0&&0<feX<1|>];
FTTest`FTAssert["ordinary prescription labels agree only after individual convergence certificates",
 AssociationQ[feCertified]&&feCertified["EquivalenceClassCount"]===1&&
 Length[feCertified["OrdinaryPrescriptionCertificates"]]===2&&
 feCertified["ExternalEndpointUniformityEstablished"]===False];
feEndpoint=FeynFacet`FindCutIntegralEquivalences[{feA0,feB0},{feA,feDifferent},
 "Normalization"->"FullTypedIntegralDefinitions",
 "OrdinaryPrescriptionGeometry"-><|"PrescriptionScope"->"EndpointDistributions"|>];
FTTest`FTAssert["generic prescription equalities cannot be relabeled as joint endpoint identities",
 MatchQ[feEndpoint,Failure["JointEndpointPrescriptionEqualityNotEstablished",_]]];
feDotA=FeynCalc`GLI[feFamilyA,ReplacePart[feBase,feCut->2]];
feDotB=FeynCalc`GLI[feFamilyB,ReplacePart[feBase,feCut->2]];
feDotted=FeynFacet`FindCutIntegralEquivalences[{feDotA,feDotB},{feA,feDifferent},
 "Normalization"->"FullTypedIntegralDefinitions",
 "OrdinaryPrescriptionGeometry"-><|"MeasurementVariable"->feZ,"ReferenceMomentum"->feP,
 "TaggedMomentum"->feK1,"ExternalKinematicConditions"->feS>0&&0<feX<1|>];
FTTest`FTAssert["a cut derivative receives its own powered-integral prescription proof",
 AssociationQ[feDotted]&&feDotted["EquivalenceClassCount"]===1&&
 AllTrue[Values[feDotted["OrdinaryPrescriptionCertificates"]],
 Total[#["ParticleCutDerivativeOrders"]]===1&]];
feDirect=FeynFacet`MapIntegralFamilyCoordinates[{feB1,feB2},feB,feA];
FTTest`FTAssert["direct basis changes use the same exact polynomial and cut-derivative arithmetic",
 AssociationQ[feDirect]&&feDirect["IntegralImages"][feB1]===feExpected1&&
 KeySort[feDirect["IntegralImages"][feB2]]===KeySort[feExpected2]];
FTTest`FTAssert["an auxiliary-basis change cannot alter a positive ordinary prescription",
 FailureQ[FeynFacet`MapIntegralFamilyCoordinates[{feB1},feDifferent,feA]]];

feSystem=<|"KinematicVariables"->{feX},"DimensionalRegulator"->feEpsilon,
 "DimensionRule"->D->4-2feEpsilon,"MasterIntegralBasis"->{feA0,feB0},
 "Families"->{feA,feDifferent},"ConnectionMatrices"->{ConstantArray[0,{2,2}]},
 "Reduction"-><|"Masters"->{feA0,feB0},"Rules"->{},"Families"->{feA,feDifferent}|>|>;
feStrictSystem=FeynFacet`ReduceEquivalentMasterIntegrals[feSystem,<||>];
feCertifiedSystem=FeynFacet`ReduceEquivalentMasterIntegrals[feSystem,
 <|"OrdinaryPrescriptionGeometry"-><|"ExternalKinematicConditions"->feS>0&&0<feX<1|>|>];
FTTest`FTAssert["master preparation preserves prescriptions unless individual certification is requested",
 AssociationQ[feStrictSystem]&&Length[feStrictSystem["MasterIntegralBasis"]]===2&&
 AssociationQ[feCertifiedSystem]&&Length[feCertifiedSystem["MasterIntegralBasis"]]===1];
FTTest`FTAssert["certified master reduction retains original definitions and generic scope",
 AssociationQ[feCertifiedSystem]&&
 feCertifiedSystem["IntegralEquivalences"]["OriginalIntegralDefinitions"]==={feA,feDifferent}&&
 feCertifiedSystem["IntegralEquivalences"]["OrdinaryPrescriptionEqualityScope"]==="GenericKinematics"&&
 feCertifiedSystem["ExternalEndpointUniformityEstablished"]===False];

Print["AFFINE REGRESSION COMPLETE"];FTTest`FTReport[];
