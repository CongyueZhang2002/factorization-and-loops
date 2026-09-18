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
phase3=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->mixedThreeTest,
 "FinalMomenta"->{ik1,ik2,ik3},"TotalMomentum"->iq,"ExternalMomenta"->{iq},
 "KinematicRules"->{FeynCalc`SPD[iq]->is},"Assumptions"->is>0|>];
threeSource=<|"Scalar"->prop[ik1+ik2]prop[ik1+ik3,-1]prop[ik2+ik3]bubble|>;
partials=FeynFacet`Private`cutLoopExternalPartialFractions[threeSource,phase3,{il}];
FTTest`FTAssert["unit-cut external partial fractions never increase any original denominator power",
 AssociationQ[partials]&&partials["PowersNeverIncreased"]&&
 Length[First[Values[partials["PartialFractions"]]]["Terms"]]===3];
If[!AssociationQ[partials],Print[InputForm[partials]];Exit[1]];
unitRules=FeynFacet`UnitCutScalarProductRules[phase3];
identity=FeynCalc`ExpandScalarProduct[FeynCalc`FeynAmpDenominatorExplicit[
 (threeSource["Scalar"]/.phase3["MomentumConservationRules"])-partials["Values"]["Scalar"]]]/.
 phase3["Topology"][[5]]/.unitRules;
FTTest`FTAssert["the external rewrite is an exact rational identity on the original particle cuts",
 Factor[identity]===0];
FTTest`FTAssert["external partial fractions retain the virtual denominator product and its causal signs",
 !partials["VirtualPrescriptionsChanged"]&&
 !FreeQ[partials["Values"],FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[il,D],0,0,{1,-1}]]];
mixed3=FeynFacet`DecomposeCutLoopIntegrands[partials["Values"],phase3,{il}];
FTTest`FTAssert["the rewritten mixed products have complete independent off-shell families",
 AssociationQ[mixed3]&&Length[mixed3["Families"]]===3&&
 AllTrue[mixed3["Families"],Length[#["CutIndices"]]===3&]];
FTTest`FTAssert["unit-cut partial fraction identities cannot be applied to dotted particle cuts",
 FailureQ[FeynFacet`Private`cutLoopExternalPartialFractions[threeSource,
  Join[phase3,<|"CutPowers"->{2,1,1}|>],{il}]]];
generic[core_]:=FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[FeynCalc`FCI[core],{1,1}]];
homogeneousSource=<|"Scalar"->generic[2FeynCalc`SPD[ik1,ik2]]generic[2FeynCalc`SPD[ik1,ik3]]*
 generic[2FeynCalc`SPD[ik1,ik2]+2FeynCalc`SPD[ik1,ik3]]bubble|>;
FTTest`FTAssert["a homogeneous dependency requiring raised external powers needs a new proof",
 MatchQ[FeynFacet`Private`cutLoopExternalPartialFractions[homogeneousSource,phase3,{il}],
  Failure["NonincreasingExternalPowersAndNonzeroDivisorsRequired",_]]];
shifted=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->(bubble/.il->il+ik1)|>,phase,{il},
 <|"FamilyNamePrefix"->"ShiftedMixedTest"|>];
opposite=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->prop[il+ik1]prop[il+ik1-iq]|>,phase,{il},
 <|"FamilyNamePrefix"->"OppositeMixedTest"|>];
equivalences=FeynFacet`FindCutIntegralEquivalences[Join[decomposed["Targets"],shifted["Targets"]],
 Join[decomposed["Families"],shifted["Families"]],"Normalization"->"DeclaredTypedCutMeasures"];
FTTest`FTAssert["mixed cut and virtual directions admit a verified virtual loop shift",
 AssociationQ[equivalences]&&equivalences["EquivalenceClassCount"]===1];
separate=FeynFacet`FindCutIntegralEquivalences[Join[decomposed["Targets"],opposite["Targets"]],
 Join[decomposed["Families"],opposite["Families"]],"Normalization"->"DeclaredTypedCutMeasures"];
FTTest`FTAssert["a virtual routing change cannot identify opposite causal prescriptions",
 AssociationQ[separate]&&separate["EquivalenceClassCount"]===2];
dotted=ReplacePart[#,{2,1}->2]&/@Join[decomposed["Targets"],shifted["Targets"]];
dottedMaps=FeynFacet`FindCutIntegralFamilyMaps[dotted,Join[decomposed["Families"],shifted["Families"]]];
FTTest`FTAssert["mixed family routing maps cover dotted cuts using unrestricted propagator identities",
 AssociationQ[dottedMaps]&&dottedMaps["RepresentativeFamilyCount"]===1&&
 AllTrue[dottedMaps["Mappings"],TrueQ[#["OffShellPropagatorsAndDirectedCutsVerified"]]&]];
farShift=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->(bubble/.il->il+3ik1-7iq)|>,phase,{il},
 <|"FamilyNamePrefix"->"FarShiftedMixedTest"|>];
farEquivalence=FeynFacet`FindCutIntegralEquivalences[Join[decomposed["Targets"],farShift["Targets"]],
 Join[decomposed["Families"],farShift["Families"]],"Normalization"->"DeclaredTypedCutMeasures",
 "PreferredMasterIntegrals"->decomposed["Targets"]];
FTTest`FTAssert["a mixed routing compares common witness frames despite extra coordinate-axis candidates",
 AssociationQ[farEquivalence]&&farEquivalence["EquivalenceClassCount"]===1&&
 farEquivalence["RepresentativeMasterIntegrals"]===decomposed["Targets"]];
farMaps=FeynFacet`FindCutIntegralFamilyMaps[Join[decomposed["Targets"],farShift["Targets"]],
 Join[decomposed["Families"],farShift["Families"]]];
FTTest`FTAssert["the selected common frames produce an independently verified off-shell map",
 AssociationQ[farMaps]&&farMaps["RepresentativeFamilyCount"]===1&&
 AllTrue[farMaps["Mappings"],TrueQ[#["OffShellPropagatorsAndDirectedCutsVerified"]]&]];
Print["CUT LOOP INTEGRANDS TEST COMPLETE"];FTTest`FTReport[];
