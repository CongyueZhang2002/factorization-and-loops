$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
faRequest=<|"Momenta"->{faP,faQ,faK},"PhysicalMomenta"->{faP,faQ}|>;
faExpression=FeynCalc`DiracTrace[FeynCalc`GSD[faP].FeynCalc`GAD[faMu].FeynCalc`GSD[faK].FeynCalc`GAD[faNu]];
faResult=FeynFacet`EvaluateFORMDiracExpression[faExpression,faRequest];
Print[faResult];
FTTest`FTAssert["FORM returns the exact open four-gamma tensor in D dimensions",
 AssociationQ[faResult]&&Factor[faResult["Value"]-FeynCalc`DiracSimplify[faExpression]]===0];
faScalar=faExpression FeynCalc`FVD[faQ,faMu]FeynCalc`FVD[faP,faNu];
faResult=FeynFacet`EvaluateFORMDiracExpression[faScalar,faRequest];
Print[faResult];
FTTest`FTAssert["FORM contracts the trace with external Lorentz tensors",
 AssociationQ[faResult]&&Factor[faResult["Value"]-FeynCalc`Calc[faScalar]]===0];
faShifted=FeynCalc`DiracTrace[FeynCalc`GSD[faK-faP].FeynCalc`GSD[faQ+faP]];
faResult=FeynFacet`EvaluateFORMDiracExpression[faShifted,faRequest];
Print[faResult];
FTTest`FTAssert["linear momentum shifts retain their exact gamma algebra",
 AssociationQ[faResult]&&Factor[FeynCalc`ExpandScalarProduct[faResult["Value"]-FeynCalc`DiracSimplify[faShifted]]]===0];
faPropagator=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 FeynCalc`Momentum[faK-faP,D],0,0,{2,-1}]];
faResult=FeynFacet`EvaluateFORMDiracExpression[faScalar faPropagator,faRequest];
FTTest`FTAssert["ordinary causal propagators remain opaque and unchanged",
 AssociationQ[faResult]&&faResult["PrescriptionsChanged"]===False&&
 Factor[faResult["Value"]-faPropagator FeynCalc`Calc[faScalar]]===0];
FTTest`FTAssert["gamma5 is rejected instead of being evaluated by nonchiral tracen",
 FailureQ[FeynFacet`EvaluateFORMDiracExpression[
 FeynCalc`DiracTrace[FeynCalc`GS[faP].FeynCalc`GA[5].FeynCalc`GSD[faK]],faRequest]]];
FTTest`FTAssert["a four-dimensional slash of an integrated momentum requires the BMHV backend",
 FailureQ[FeynFacet`EvaluateFORMDiracExpression[
 FeynCalc`DiracTrace[FeynCalc`GS[faK].FeynCalc`GS[faP]],faRequest]]];
faMixed=FeynCalc`DiracTrace[FeynCalc`GAD[faMu].FeynCalc`GSD[faK].FeynCalc`GAD[faNu].FeynCalc`GSD[faP]]*
 FeynCalc`FV[faQ,faMu]FeynCalc`FV[faP,faNu];
faResult=FeynFacet`EvaluateFORMDiracExpression[faMixed,faRequest];
FTTest`FTAssert["physical four-dimensional vector components contract with full-D gamma indices",
 AssociationQ[faResult]&&Factor[faResult["Value"]-(FeynCalc`Calc[faMixed]/.
  FeynCalc`Pair[FeynCalc`Momentum[a_],FeynCalc`Momentum[b_]]/;MemberQ[{faP,faQ},a]||MemberQ[{faP,faQ},b]:>
   FeynCalc`FCI[FeynCalc`SPD[a,b]])]===0];
faCompound=FeynCalc`FCI[faScalar]/.faMu->faDummy[7];
faResult=FeynFacet`EvaluateFORMDiracExpression[faCompound,faRequest];
FTTest`FTAssert["compound dummy-index labels preserve their exact contractions",
 AssociationQ[faResult]&&Factor[faResult["Value"]-FeynCalc`Calc[faCompound]]===0];
faLong=FeynCalc`DiracTrace[
 FeynCalc`GAD[faMu].FeynCalc`GSD[faP].FeynCalc`GSD[faK].FeynCalc`GSD[faQ].
 FeynCalc`GAD[faMu].FeynCalc`GSD[faQ].FeynCalc`GSD[faK].FeynCalc`GSD[faP]];
faResult=FeynFacet`EvaluateFORMDiracExpression[faLong,faRequest];
FTTest`FTAssert["a contracted eight-gamma trace retains its full dimensional polynomial",
 AssociationQ[faResult]&&Factor[faResult["Value"]-FeynCalc`Calc[faLong]]===0];
FTTest`FTReport[];
