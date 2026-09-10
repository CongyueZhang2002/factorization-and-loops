$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
hermCard=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp","Real"];
hermPlan=FeynFacet`DiagramInterferencePlan[hermCard];
FTTest`FTAssert["five diagrams require fifteen direct contractions",Length[hermPlan["Pairs"]]===15&&hermPlan["FullPairCount"]===25];
FTTest`FTAssert["full-grid diagnostic remains available",Length[FeynFacet`DiagramInterferencePlan[hermCard,"HermitianReduction"->False]["Pairs"]]===25];
hermLarge=Join[hermCard,Association@Table[key->Append[hermCard[key],"DiagramIndices"->Range[36]],{key,{"ForwardAmplitudes","ConjugateAmplitudes"}}]];
FTTest`FTAssert["36 diagrams require 666 direct contractions",Length[FeynFacet`DiagramInterferencePlan[hermLarge]["Pairs"]]===666];
hermRect=Append[hermCard,"ConjugateAmplitudes"->Append[hermCard["ConjugateAmplitudes"],"DiagramIndices"->{1}]];
FTTest`FTAssert["unequal sets retain their rectangle",FeynFacet`DiagramInterferencePlan[hermRect]["HermitianReduction"]===False&&Length[FeynFacet`DiagramInterferencePlan[hermRect]["Pairs"]]===5];
hermVirtual=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp","Virtual"];
FTTest`FTAssert["virtual-tree interference is not doubled by the pair driver",FeynFacet`DiagramInterferencePlan[hermVirtual]["HermitianReduction"]===False];
hermSynthetic=<|"ForwardAmplitudes"-><|"LoopMomenta"->{hermL}|>,"ConjugateAmplitudes"-><|"LoopMomenta"->{hermR}|>,"ComplexParameters"->{hermCoupling}|>;
hermSeed=<|"Numerator"->(1+I)hermCoupling hermL+Conjugate[hermCoupling]hermR,"OrdinaryPropagators"->FeynCalc`SFAD[hermL] FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[hermR,D],0,0,{2,-1}]],"ExternalPropagators"->1|>;
hermReverse=FeynFacet`Private`hermitianConjugateContraction[hermSeed,hermSynthetic];
FTTest`FTAssert["complex coefficients and loop labels are conjugated",Expand[hermReverse["Numerator"]-((1-I)Conjugate[hermCoupling]hermR+hermCoupling hermL)]===0];
FTTest`FTAssert["ordinary causal prescriptions are reversed",Cases[FeynCalc`FCI[hermReverse["OrdinaryPropagators"]],FeynCalc`StandardPropagatorDenominator[___,{1,-1}],Infinity]=!={}];
hermDouble=FeynFacet`Private`hermitianConjugateContraction[hermReverse,hermSynthetic];
FTTest`FTAssert["Hermitian conjugation is an involution including prescriptions",
 Expand[hermDouble["Numerator"]-hermSeed["Numerator"]]===0&&
 Sort[Cases[FeynCalc`FCI[hermDouble["OrdinaryPropagators"]],_FeynCalc`StandardPropagatorDenominator,Infinity]]===
 Sort[Cases[FeynCalc`FCI[hermSeed["OrdinaryPropagators"]],_FeynCalc`StandardPropagatorDenominator,Infinity]]];
hermComplexMass=FeynFacet`Private`conjugatePhysicalAmplitude[
 FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[hermL,D],0,hermCoupling,{1,1}]],hermSynthetic];
FTTest`FTAssert["declared complex mass fields are conjugated with the prescription",
 !FreeQ[hermComplexMass,FeynCalc`StandardPropagatorDenominator[_,0,Conjugate[hermCoupling],{1,-1}]]];
Do[
 hermCard=FeynFacet`ReadProcessCard[root<>If[pol==="UU","/Projects/ppHX_UU_NNLO","/Projects/ppHX_"<>pol<>"_NLO"]<>"/NLO/qqp-qqp","Real"];
 hermSelected=FeynFacet`Private`interferencePairSetup[hermCard,{1,5}];
 hermPrepared=FeynFacet`PrepareProcessDiagrams[hermSelected];
 {hermSeconds,hermRows}=AbsoluteTiming[FeynFacet`CollinearFactorizeInterferencesPreIBP[hermSelected,"PreparedDiagrams"->hermPrepared]];
 FTTest`FTAssert[pol<>" paired calculation returns both orientations",ListQ[hermRows]&&Length[hermRows]===2];
 If[ListQ[hermRows]&&Length[hermRows]===2,
 hermDirect=FeynFacet`CollinearFactorizePreIBP[hermRows[[2,"Setup"]],"PreparedDiagrams"->hermPrepared];
 hermDerived=hermRows[[2,"Result"]];
 FTTest`FTAssert[pol<>" reverse interference agrees with independent contraction",
 MatchQ[hermDirect,{_,_,_,_,_List}]&&hermDerived[[{1,3}]]===hermDirect[[{1,3}]]&&
 Expand[hermDerived[[2]]hermDerived[[4]]-hermDirect[[2]]hermDirect[[4]]]===0];
 Print[pol<>" triangular pair seconds: ",hermSeconds]],{pol,{"UU","LL","TT"}}];
FTTest`FTReport[];
