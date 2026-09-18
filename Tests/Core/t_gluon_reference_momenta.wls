$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
grSetup=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU/Raw/LO/u-ub_g-g","Born"];
grObserved=First[Last[grSetup["PartonMomentum"]]];grReference=First[First[grSetup["PartonMomentum"]]];
grDeclared=Join[grSetup,<|"GluonPolarizationReferences"->Association[grObserved->grReference]|>];
grProcess=Catch[FeynFacet`Private`normalizeProcess[FeynFacet`Private`interferencePairSetup[grDeclared,{1,1}]],
 FeynFacet`Private`$collinearFailure];
FTTest`FTAssert["physical reference has the expected nonzero partonic denominator",
 AssociationQ[grProcess]&&Factor[grProcess["GluonPolarizationScalarProducts"][grObserved]+t/2]===0];
FTTest`FTAssert["a polarization reference does not replace the operator dual vector",
 grProcess["Outgoing"][[1,"DualDirection"]]===First[Last[grSetup["HadronDualDirection"]]]];
FTTest`FTAssert["the observed reference stays nonsingular at the recoil endpoint",
 TrueQ[FullSimplify[(grProcess["GluonPolarizationScalarProducts"][grObserved]/.t->s(v-1))>0,
 Assumptions->s>0&&0<v<1]]];
grBad=Join[grSetup,<|"GluonPolarizationReferences"->Association[grObserved->grObserved]|>];
FTTest`FTAssert["a reference parallel to the same momentum label is rejected",
 Quiet[Catch[FeynFacet`Private`normalizeProcess[FeynFacet`Private`interferencePairSetup[grBad,{1,1}]],
 FeynFacet`Private`$collinearFailure]]===$Failed];
grLeg=<|"Role"->"FF","Species"->"g","Polarization"->"U","Momentum"->grk,
 "MomentumSpace"->"Physical4","Indices"->{grmu,grnu},"ReferenceMomentum"->grn|>;
grOne=FeynFacet`PartonicSpinDensity[grLeg]["SpinDensity"];
grTwo=FeynFacet`PartonicSpinDensity[Join[grLeg,<|"ReferenceMomentum"->grm|>]]["SpinDensity"];
grB[reference_,index_]:=FeynCalc`FVD[reference,index]/FeynCalc`SPD[grk,reference]-
 FeynCalc`SPD[reference]FeynCalc`FVD[grk,index]/(2FeynCalc`SPD[grk,reference]^2);
grGauge=FeynCalc`FVD[grk,grmu](grB[grm,grnu]-grB[grn,grnu])+
 (grB[grm,grmu]-grB[grn,grmu])FeynCalc`FVD[grk,grnu];
FTTest`FTAssert["reference change is exactly a Ward term, including non-null references",
 Factor[FeynCalc`FCI[grTwo-grOne-grGauge]]===0];
FTTest`FTAssert["physical external momentum retains the D-dimensional polarization metric",
 !FreeQ[FeynCalc`FCI[grOne],FeynCalc`Pair[FeynCalc`LorentzIndex[grmu,D],FeynCalc`LorentzIndex[grnu,D]]]];
FTTest`FTReport[];
