(* Independent integral and distribution identities for the MT adapter. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mcRow[d_,p_,f_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->f|>;
mcD=mcRow[1,<||>,0];mcP=mcRow[0,<|0->1|>,0];mcX=mcRow[0,<||>,mx];
mcA=FeynFacet`MellinConvolveDistributions[mcD,mcP,mx];
FTTest`FTAssert["delta is the identity under Mellin convolution",
 AssociationQ[mcA]&&mcA["DeltaCoefficient"]===0&&mcA["PlusCoefficients"]===<|0->1|>&&mcA["RegularCoefficient"]===0];
mcB=FeynFacet`MellinConvolveDistributions[mcP,mcP,mx];
FTTest`FTAssert["two plus distributions produce the known endpoint and regular terms",
 AssociationQ[mcB]&&Simplify[mcB["DeltaCoefficient"]+Zeta[2]]===0&&mcB["PlusCoefficients"]===<|1->2|>&&
 Simplify[mcB["RegularCoefficient"]+Log[mx]/(1-mx),0<mx<1]===0];
mcC=FeynFacet`MellinConvolveDistributions[mcP,mcX,mx];
FTTest`FTAssert["plus against a polynomial agrees with its direct subtracted integral",
 AssociationQ[mcC]&&mcC["DeltaCoefficient"]===0&&mcC["PlusCoefficients"]===<||>&&
 Simplify[mcC["RegularCoefficient"]-(1-mx-mx Log[mx]+mx Log[1-mx]),0<mx<1]===0];
mcE=FeynFacet`MellinConvolveDistributions[mcX,mcRow[0,<||>,1],mx];
FTTest`FTAssert["ordinary functions use dy/y",
 AssociationQ[mcE]&&Simplify[mcE["RegularCoefficient"]-(1-mx),0<mx<1]===0];
mcF=FeynFacet`MellinConvolveDistributions[mcRow[0,<|0->mf|>,0],mcX,mx];
FTTest`FTAssert["the other convolution variable remains a symbolic coefficient",
 AssociationQ[mcF]&&Simplify[mcF["RegularCoefficient"]-mf mcC["RegularCoefficient"],0<mx<1]===0];
FTTest`FTAssert["a noncanonical plus coefficient is rejected",
 FailureQ[FeynFacet`MellinConvolveDistributions[mcRow[0,<|0->mx|>,0],mcD,mx]]];
FTTest`FTAssert["MT does not shadow the FeynCalc metric shorthand",
 System`Names["Global`MT"]==={}];

mcG=FeynFacet`MellinConvolveDistributions[mcP,mcRow[0,<|1->1|>,0],mx];
FTTest`FTAssert["D0 convoluted with D1 includes its zeta endpoint terms",
 AssociationQ[mcG]&&Simplify[mcG["DeltaCoefficient"]-Zeta[3]]===0&&
 Lookup[mcG["PlusCoefficients"],{0,2}] === {-Pi^2/6,3/2}&&
 Simplify[mcG["RegularCoefficient"]+Log[mx]Log[1-mx]/(1-mx),0<mx<1]===0];
mcH=FeynFacet`MellinConvolveDistributions[mcRow[0,<|2->1|>,0],mcRow[0,<||>,mx^2],mx];
mcPoint=7/19;
mcIntegral=NIntegrate[Log[1-my]^2/(1-my)((mcPoint/my)^2/my-mcPoint^2),
 {my,mcPoint,1},AccuracyGoal->10,PrecisionGoal->10]+mcPoint^2 Log[1-mcPoint]^3/3;
FTTest`FTAssert["D2 against x squared agrees with direct subtracted quadrature",
 Abs[N[mcH["RegularCoefficient"]/.mx->mcPoint]-mcIntegral]<10^-9];
mcInv=FeynFacet`MellinConvolveDistributions[mcRow[0,<|2->1|>,0],mcRow[0,<||>,1/mx],mx];
FTTest`FTAssert["the inverse-monomial convolution has the exact endpoint primitive",
 Simplify[mcInv["RegularCoefficient"]-Log[1-mx]^3/(3mx)]===0];
FTTest`FTReport[];
