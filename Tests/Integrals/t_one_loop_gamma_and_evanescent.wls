$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
olBubble=FeynFacet`Private`oneLoopSingleScaleGamma[{-olQ2},{1,1},4-2ole,1,olQ2>0];
olTriangle=FeynFacet`Private`oneLoopSingleScaleGamma[{0,-olQ2,0},{1,1,1},4-2ole,1,olQ2>0];
FTTest`FTAssert["single-off-shell triangle has its two infrared poles and spacelike sign",
 FullSimplify[olTriangle/(-olQ2^(-1-ole) Gamma[1+ole]Gamma[1-ole]^2/(ole^2 Gamma[1-2ole])),Assumptions->olQ2>0]===1];
FTTest`FTAssert["a convergent triangle parameter integral fixes absolute normalization",
 FullSimplify[olTriangle/.{ole->-1/2,olQ2->4}]+Pi^(3/2)/2===0];
FTTest`FTAssert["a scaleless on-shell bubble vanishes before singular Gamma limits",
 FeynFacet`Private`oneLoopSingleScaleGamma[{0},{1,1},4-2ole,1,True]===0];
FTTest`FTAssert["FeynCalc scalar functions preserve the complete loop measure",
 FullSimplify[(I Pi^2 Pi^(-ole))/(2Pi)^(4-2ole)/(I/(4Pi)^(2-ole))]===1&&
 FeynFacet`EvaluateOneLoopScalarFunctions[FeynCalc`B0[-olQ2,0,0],ole,olQ2>0]===Pi^(-ole)olBubble];
olKin=FeynCalc`FCI[{FeynCalc`SPD[olp]->0,FeynCalc`SPD[olq]->-olQ2,FeynCalc`SPD[olp,olq]->olQ2/2}];
olFull=FeynCalc`FCI[FeynCalc`SPD[oll]];olBar=FeynCalc`FCI[FeynCalc`SP[oll]];
olParallel=4 FeynCalc`FCI[FeynCalc`SPD[oll,olp]FeynCalc`SPD[oll,olp+olq]]/olQ2;
olParallel=FeynCalc`ExpandScalarProduct[olParallel];
olAvg=FeynFacet`Private`oneLoopAveragePhysicalNumerator[olFull-olBar,oll,{olp,olq},olKin,olQ2>0];
FTTest`FTAssert["the signed evanescent square follows the rank-two tensor identity",
 Factor[olAvg-(D-4)/(D-2)(olFull-olParallel)]===0];
olAvg2=FeynFacet`Private`oneLoopAveragePhysicalNumerator[(olFull-olBar)^2,oll,{olp,olq},olKin,olQ2>0];
FTTest`FTAssert["higher evanescent powers are averaged linearly",
 Factor[olAvg2-(D-4)/D (olFull-olParallel)^2]===0&&Factor[olAvg2-olAvg^2]=!=0];
FTTest`FTAssert["a correlated unlisted full-dimensional numerator direction is rejected",
 FailureQ[Catch[FeynFacet`Private`oneLoopAveragePhysicalNumerator[(olFull-olBar)FeynCalc`FCI[FeynCalc`SPD[oll,olExtra]]^2,
  oll,{olp,olq},olKin,olQ2>0],"EpsilonOrders"]]];
FTTest`FTAssert["a null external span is rejected rather than replaced by a pseudoinverse",
 FailureQ[Catch[FeynFacet`Private`oneLoopAveragePhysicalNumerator[olFull-olBar,oll,{olp},olKin,olQ2>0],"EpsilonOrders"]]];
olBasis={ola,olb,olc,old};
olMetric=DiagonalMatrix[{1,-1,-1,-1}];
olKin4=Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[olBasis[[i]],olBasis[[j]]]]->olMetric[[i,j]],{i,4},{j,i,4}]];
olParallel4=Sum[olMetric[[i,i]]FeynCalc`FCI[FeynCalc`SPD[oll,olBasis[[i]]]]^2,{i,4}];
FTTest`FTAssert["a full physical four-dimensional span leaves a wholly evanescent complement",
 Factor[FeynFacet`Private`oneLoopAveragePhysicalNumerator[olFull-olBar,oll,olBasis,olKin4,True]-(olFull-olParallel4)]===0];
(* A fresh on-shell reduction must not depend on scalar-product definitions
   left by an earlier real-emission calculation. *)
olOld=FeynCalc`SPD[olp,olq];FeynCalc`SPD[olp,olq]=olSentinel;
olScoped=FeynFacet`Private`withOneLoopKinematics[
 FeynCalc`SPD[olp,olq],{{olp,olp,0},{olq,olq,-olQ2},{olp,olq,olQ2/2}}];
FTTest`FTAssert["the one-loop Gram matrix is installed locally and caller values are restored",
 olScoped===olQ2/2&&FeynCalc`SPD[olp,olq]===olSentinel];
FeynCalc`SPD[olp,olq]=olOld;
FTTest`FTReport[];
