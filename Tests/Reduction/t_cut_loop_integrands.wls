Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->mixedTest,
 "FinalMomenta"->{ik1,ik2},"TotalMomentum"->iq,"ExternalMomenta"->{iq},
 "KinematicRules"->{FeynCalc`SPD[iq]->is},"Assumptions"->is>0|>];
prop[m_,sign_:1]:=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[m,D],0,0,{1,sign}]];
bubble=prop[il,-1]prop[il-iq,-1];
source=<|"Scalar"->2bubble,"CutZero"->FeynCalc`FCI[FeynCalc`SPD[ik1]]bubble|>;
decomposed=FeynFacet`DecomposeCutLoopIntegrands[source,phase,{il},<|"FamilyNamePrefix"->"MixedTest"|>];
FTTest`FTAssert["mixed loop/phase-space decomposition retains explicitly directed particle cuts",
 AssociationQ[decomposed]&&Length[decomposed["Families"]]===1&&
 First[decomposed["Families"]]["CutIndices"]==={1,2}&&
 Lookup[First[decomposed["Families"]]["Cuts"],"EnergyDirection"]==={1,1}];
If[!AssociationQ[decomposed],Print[InputForm[decomposed]];FTTest`FTReport[]];
family=First[decomposed["Families"]];
FTTest`FTAssert["the default virtual measure and original opposite causal signs are retained",
 family["MeasurePrefactor"]===phase["MeasurePrefactor"]&&
 family["OrdinaryPropagatorPrescriptions"][[3;;4]]==={-1,-1}&&
 !decomposed["OrdinaryPrescriptionLimitEstablished"]];
FTTest`FTAssert["a numerator that pinches a mandatory particle cut is exactly zero",
 decomposed["CoefficientRules"]["CutZero"]===<||>&&
 Values[decomposed["CoefficientRules"]["Scalar"]]==={2}];
normalized=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->bubble|>,phase,{il},
 <|"VirtualLoopMeasurePrefactor"->1/(I Pi^(D/2))|>];
FTTest`FTAssert["an explicitly declared normalized virtual measure is composed once with phase space",
 AssociationQ[normalized]&&Factor[First[normalized["Families"]]["MeasurePrefactor"]/
   phase["MeasurePrefactor"]-1/(I Pi^(D/2))]===0];
pure=FeynFacet`DecomposeVirtualLoopIntegrands[<|"Scalar"->2bubble|>,{il},{iq},
 {FeynCalc`SPD[iq]->is},<|"Assumptions"->is>0|>];
FTTest`FTAssert["pure virtual sources use the same numerator algebra without acquiring cut factors",
 AssociationQ[pure]&&First[pure["Families"]]["CutIndices"]==={}&&
 Values[pure["CoefficientRules"]["Scalar"]]==={2}];
FTTest`FTAssert["an ordinary propagator coinciding with a mandatory cut is not silently merged",
 FailureQ[FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->bubble prop[ik1]|>,phase,{il}]]];
Print["CUT LOOP INTEGRANDS TEST COMPLETE"];FTTest`FTReport[];
