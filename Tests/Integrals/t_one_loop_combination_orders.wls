$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[eps];
source=<|"BubblePole"->FeynCalc`B0[-2,0,0]/eps,
 "TriangleDifference"->FeynCalc`C0[0,-2,-3,0,0,0]|>;
out=WithEpsilonRemainderChecks[ExpandOneLoopScalarFunctions[source,eps,{-2,0},True]];
FTAssert["complete loop combinations have explicit coefficients and a passing omitted-order audit",
 AssociationQ[out["Result"]]&&out["EpsilonRemainderAudit"]["Status"]==="Passed"];
If[AssociationQ[out["Result"]],
 expected=Normal[Series[EvaluateOneLoopScalarFunctions[source["BubblePole"],eps,True],{eps,0,0}]];
 FTAssert["a coefficient pole requests and retains the needed positive bubble order",
 FullSimplify[out["Result"]["Coefficients"][[Key[{1,0}]]]-Coefficient[expected,eps,0]]===0&&
 Max[out["Result"]["ScalarIntegralUpperOrders"]]>=1]];
short=WithEpsilonRemainderChecks[ExpandOneLoopScalarFunctions[source,eps,{-2,0},True],
 "TruncationOrderShift"->-1];
FTAssert["the loop order audit detects a deliberately shortened expansion",
 short["EpsilonRemainderAudit"]["Status"]==="Failed"];
FTReport[];
