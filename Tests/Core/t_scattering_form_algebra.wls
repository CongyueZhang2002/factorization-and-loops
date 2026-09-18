
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
process=<|"SetEvanescentZero"->{ap,aq},"PhaseSpaceMomenta"->{ak},
 "VirtualLoopMomenta"->{al},"SetMassZero"->{ap},"Assumptions"->True|>;
expressions={
 FeynCalc`DiracTrace[FeynCalc`GSD[ak].FeynCalc`GAD[amu].FeynCalc`GSD[ap].FeynCalc`GAD[anu]]*
  FeynCalc`FV[aq,amu]FeynCalc`FV[ap,anu],
 FeynCalc`DiracTrace[FeynCalc`GSD[ak-ap].FeynCalc`GSD[al+aq]],
 FeynCalc`DiracTrace[FeynCalc`GS[ap].FeynCalc`GA[5].FeynCalc`GSD[ak].FeynCalc`GS[aq].FeynCalc`GA[5].FeynCalc`GSD[al]],
 0};
Do[
 prepared=FeynFacet`Private`applyKinematicZeros[expr,process];
 expected=FeynFacet`Private`applyKinematicZeros[
   FeynFacet`Private`collinearContractAmplitude[prepared,True],process];
 actual=FeynFacet`Private`applyKinematicZeros[
   FeynFacet`Private`collinearContractAmplitude[prepared,process],process];
 FTTest`FTAssert["scattering FORM contraction agrees with independent FeynCalc algebra "<>ToString[i],
  TrueQ[Expand[FeynCalc`FCI[expected-actual]/.
    FeynCalc`Pair[FeynCalc`Momentum[a_,D-4],FeynCalc`Momentum[b_,D-4]]:>
      FeynCalc`Pair[FeynCalc`Momentum[a,D],FeynCalc`Momentum[b,D]]-
      FeynCalc`Pair[FeynCalc`Momentum[a],FeynCalc`Momentum[b]]]===0]],
 {i,Length[expressions]},{expr,{expressions[[i]]}}];
FTTest`FTAssert["massless identities are applied to external Gram products",
 FeynFacet`Private`applyKinematicZeros[FeynCalc`SPD[ap,ap]+FeynCalc`SPD[ak,ak],process]===
 FeynCalc`FCI[FeynCalc`SPD[ak,ak]]];
FTTest`FTReport[];
