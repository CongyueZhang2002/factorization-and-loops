Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
frequest=<|"ExternalMomenta"->{fp,fq,fk},"KinematicRules"->{
 SPD[fp]->0,SPD[fq]->-4,SPD[fk]->0,SPD[fp,fq]->4,SPD[fp,fk]->4/3,SPD[fq,fk]->2/3},
 "TimelikeVector"->(fp+fq)/2,"BeamMomentum"->fp,"ObservedMomentum"->fk,
 "SpinVectors"->{fsx,fsout,fsy},"Assumptions"->True|>;
frame=FeynFacet`ScatteringPlaneSpinFrame[frequest];
FTTest`FTAssert["the covariant spin frame reconstructs independent Cartesian energy and angle",
 AssociationQ[frame]&&frame["ObservedEnergy"]===1&&frame["Cosine"]===1/3&&frame["Sine"]===2 Sqrt[2]/3];
FTTest`FTAssert["unnormalized time directions cannot produce a physical spin frame",
 FailureQ[FeynFacet`ScatteringPlaneSpinFrame[Join[frequest,<|"TimelikeVector"->fp+fq|>]]]];
fkin=FCI[frame["PhysicalKinematicRules"]];
averageRequest=<|"PhysicalMomenta"->{fp,fq,fk},"IntegratedMomentum"->fell,
 "NormalMomentum"->fsy,"KinematicRules"->fkin,"Assumptions"->True|>;
a2=FeynFacet`AverageSingleNormalNumerator[SPD[fell,fsy]^2,averageRequest];
a4=FeynFacet`AverageSingleNormalNumerator[SPD[fell,fsy]^4,averageRequest];
a1=FeynFacet`AverageSingleNormalNumerator[SPD[fell,fsy],averageRequest];
FTTest`FTAssert["one normal component uses D-3 rather than D-2 or 2",
 AssociationQ[a2]&&Factor[a2["Value"]+a2["TransverseSquare"]/(D-3)]===0];
FTTest`FTAssert["the fourth tensor moment and odd cancellation hold simultaneously",
 AssociationQ[a4]&&Factor[a4["Value"]-3a4["TransverseSquare"]^2/((D-3)(D-1))]===0&&a1["Value"]===0];
FTTest`FTAssert["an angular-dependent denominator cannot be averaged as a scalar weight",
 FailureQ[FeynFacet`AverageSingleNormalNumerator[SPD[fell,fsy]^2 FAD[{fell+fsy,0}],averageRequest]]];
Print["PHYSICAL SPIN FRAME TEST COMPLETE"];
FTTest`FTReport[];
