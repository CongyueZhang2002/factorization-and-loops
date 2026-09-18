Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
FeynCalc`FCSetDiracGammaScheme["BMHV"];FeynCalc`$LeviCivitaSign=-1;
request=<|"Momenta"->{spin,beam,loopA,loopB},"PhysicalMomenta"->{spin,beam},
 "KinematicRules"->{FeynCalc`SPD[spin,beam]->0},"Gamma5Scheme"->"BMHV"|>;
pseudo=FeynCalc`GA[5].FeynCalc`GS[spin].FeynCalc`GS[beam];
dual=I/2 FeynCalc`LC[alpha,beta][spin,beam] FeynCalc`GA[alpha].FeynCalc`GA[beta];
chains={FeynCalc`GSD[loopA].FeynCalc`GSD[loopB],
 FeynCalc`GAD[rho].FeynCalc`GSD[loopA].FeynCalc`GSD[loopB].FeynCalc`GAD[rho],
 FeynCalc`GAD[rho].FeynCalc`GAD[sigma].FeynCalc`GSD[loopA].FeynCalc`GSD[loopB].FeynCalc`GAD[rho].FeynCalc`GAD[sigma],
 FeynCalc`GAE[rho].FeynCalc`GSD[loopA].FeynCalc`GSD[loopB].FeynCalc`GAE[rho],
 FeynCalc`GAD[rho].FeynCalc`GA[5].FeynCalc`GS[spin].FeynCalc`GSD[loopA].FeynCalc`GSD[loopB].FeynCalc`GAD[rho]};
Do[
 ans=FeynFacet`EvaluateFORMDiracExpression[FeynCalc`DiracTrace[(pseudo-dual).chain],request];
 If[!AssociationQ[ans]||Factor[ans["Value"]]=!=0,Print[InputForm[ans]]];
 FTTest`FTAssert["physical pseudotensor equals the Hodge dual with D-dimensional internal chain "<>ToString[j],
 AssociationQ[ans]&&Factor[ans["Value"]]===0],{j,Length[chains]},{chain,{chains[[j]]}}];
Print["PHYSICAL TRANSVERSITY DUALITY TEST COMPLETE"];FTTest`FTReport[];
