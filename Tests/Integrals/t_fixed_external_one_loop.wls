Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
kin=<|"ExternalMomenta"->{vp,vn},"KinematicRules"->{SPD[vp]->-vs,SPD[vn]->-1,SPD[vp,vn]->0},
 "Assumptions"->vs>0,"DimensionalRegulator"->ve|>;
values=<|"Scalar"->FAD[{vell,0},{vell-vp,0}],
 "Longitudinal"->SPD[vell,vp] FAD[{vell,0},{vell-vp,0}],
 "Transverse"->SPD[vell,vn]^2 FAD[{vell,0},{vell-vp,0}]|>;
result=FeynFacet`ReduceOneLoopIntegrands[values,kin,<|"LoopMomentum"->vell,"PrintTimings"->True|>];
FTTest`FTAssert["arbitrary fixed-external one-loop reduction completes",AssociationQ[result]];
If[AssociationQ[result],
 rows=result["InteriorValues"];
 FTTest`FTAssert["rank-one bubble reduction respects loop-momentum symmetry",
  Factor[rows["Longitudinal"]+vs rows["Scalar"]/2]===0];
 FTTest`FTAssert["rank-two tensor reduction retains its exact D-dependent metric term",
  Factor[rows["Transverse"]+vs rows["Scalar"]/(4(D-1))]===0];
 FTTest`FTAssert["no unresolved tensor or momentum object remains",
  FreeQ[rows,_Pair|_Momentum|_PaVe|_TID]]];
Print["FIXED EXTERNAL ONE LOOP TEST COMPLETE"];
FTTest`FTReport[];
