Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
kin={SPD[p]->0,SPD[Ptot]->s,SPD[p,Ptot]->j,SPD[normalTest]->-1,SPD[p,normalTest]->0,SPD[Ptot,normalTest]->0};
def=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->cutProjectionTest,"FinalMomenta"->{r1,r2},
 "TotalMomentum"->Ptot,"ExternalMomenta"->{p,Ptot},"KinematicRules"->Take[kin,3],"Assumptions"->s>0&&j>0|>];
rules=FeynFacet`UnitCutScalarProductRules[def,{SPD[r1,p]}];
FTTest`FTAssert["unit cuts eliminate the recoil scalar product and full-D virtuality",
 Sort[rules]===Sort[FCI[{SPD[r1]->0,SPD[r1,Ptot]->s/2}]]];
geometry=<|"PhysicalMomenta"->{p,Ptot,normalTest},"IntegratedMomenta"->{r1},"KinematicRules"->kin,
 "TimelikeMomentum"->Ptot,"Assumptions"->s>0&&j>0,"DimensionalRegulator"->eps|>;
expr=FCI[SP[r1]^2+SP[r1]SP[r1,normalTest]^2+SP[r1,p]^2];
old=FeynFacet`AverageEvanescentScalarProducts[expr,geometry];
new=FeynFacet`AverageEvanescentScalarProducts[expr,Join[geometry,<|"UnitCutScalarProductRules"->rules|>]];
If[!AssociationQ[old]||!AssociationQ[new],Print[{old,new}];Exit[1]];
FTTest`FTAssert["early full-D cut restriction commutes with the correlated evanescent average",
 Together[(old["Value"]/.rules)-new["Value"]]===0];
normal=Join[geometry,<|"PhysicalMomenta"->{p,Ptot},"IntegratedMomentum"->r1,"NormalMomentum"->normalTest|>];
oldn=FeynFacet`AverageSingleNormalNumerator[old["Value"],normal];
newn=FeynFacet`AverageSingleNormalNumerator[new["Value"],Join[normal,<|"UnitCutScalarProductRules"->rules|>]];
FTTest`FTAssert["early cut restriction preserves the residual physical normal average",
 AssociationQ[oldn]&&AssociationQ[newn]&&Together[(oldn["Value"]/.rules)-newn["Value"]]===0];
FTTest`FTAssert["physical projected virtuality is not incorrectly set to zero",
 Together[newn["Value"]-FCI[SPD[r1,p]^2]] =!=0];
Print["UNIT CUT ANGULAR PROJECTION TEST COMPLETE"];FTTest`FTReport[];
