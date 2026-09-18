Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
c2=FeynFacet`MasslessInvariantPhaseSpaceCoordinates[{pk1,pk2},pq,ps,pe,{}];
c3=FeynFacet`MasslessInvariantPhaseSpaceCoordinates[{pk1,pk2,pk3},pq,ps,pe,{pu,pv}];
c4=FeynFacet`MasslessInvariantPhaseSpaceCoordinates[{pk1,pk2,pk3,pk4},pq,ps,pe,{pu,pv,pa,pb,pt}];
FTTest`FTAssert["two-body absolute phase-space normalization",AssociationQ[c2]&&
 FullSimplify[(c2["Density"]/.pe->0)-1/(8Pi),ps>0]===0];
FTTest`FTAssert["three-body phase-space volume",AssociationQ[c3]&&
 Integrate[c3["Density"]/.pe->0,{pu,0,1},{pv,0,1}]/(ps/(256Pi^3))===1];
FTTest`FTAssert["four-body geometry is constructed",AssociationQ[c4]];
If[!AssociationQ[c4],Print[InputForm[c4]];FTTest`FTReport[]];
FTTest`FTAssert["massless pair invariants conserve the total mass",Simplify[Total[Values[c4["PairInvariants"]]]-ps]===0];
FTTest`FTAssert["energy fractions sum to two",Simplify[Total[c4["EnergyFractions"]]-2]===0];
FTTest`FTAssert["energy-weighted first angular moment follows from momentum conservation",
 Simplify[Total[Values[c4["PairInvariants"]]]/(2ps)]===1/2];
point={pu->2/7,pv->3/5,pa->1/4,pb->2/5,pt->1/3,ps->7};
FTTest`FTAssert["physical invariants and energies are positive at a generic interior point",
 And@@(Positive/@N[Join[Values[c4["PairInvariants"]],c4["EnergyFractions"]]/.point])];
FTTest`FTAssert["four future-null momenta have a negative Gram determinant",N[Det[c4["GramMatrix"]]/.point]<0];
Do[
 normalized=Simplify[c4["RadialDensity"]/FeynFacet`MasslessPhaseSpaceVolume[4,ps,pe]/.{ps->1,pe->reg}];
 numerical=NIntegrate[Evaluate[normalized],{pu,0,1},{pv,0,1},
  WorkingPrecision->25,AccuracyGoal->15,PrecisionGoal->15];
 FTTest`FTAssert["four-body recursive absolute volume at epsilon "<>ToString[reg],Abs[numerical-1]<10^-12];
 moment=NIntegrate[Evaluate[pu^2 normalized],{pu,0,1},{pv,0,1},
  WorkingPrecision->25,AccuracyGoal->15,PrecisionGoal->15];
 FTTest`FTAssert["permutation symmetry gives the pair-mass moment at epsilon "<>ToString[reg],Abs[moment-1/6]<10^-12],
 {reg,{0,-1/2}}];
FTTest`FTAssert["dimensional azimuth is normalized, including away from four dimensions",
 And@@Table[FullSimplify[Integrate[c4["NormalizedAngularDensities"][[3]]/.pe->reg,{pt,0,1}]]===1,{reg,{0,-1/2,-1}}]];
FTTest`FTAssert["coordinate representation does not claim an evaluated integral",
 c4["IntegralEvaluated"]===False&&c4["MeasurementIncluded"]===False];
FTTest`FTAssert["degenerate coordinate declarations are rejected",FailureQ[
 FeynFacet`MasslessInvariantPhaseSpaceCoordinates[{pk1,pk2,pk3,pk4},pq,ps,pe,{pu,pv,pa,pb,pu}]]];
Print["INVARIANT COORDINATES TEST COMPLETE"];
FTTest`FTReport[];
