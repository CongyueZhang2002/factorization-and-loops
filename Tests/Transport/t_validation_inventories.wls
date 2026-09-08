#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
work=CreateDirectory[];CreateDirectory[work<>"/solution"];
saved=<|"MasterIntegralCoefficients"-><|0->{1->2,2->3}|>,
 "OriginalMasterIntegralBasis"->{Global`GLI[family,{1}],Global`GLI[family,{2}]}|>;
Export[work<>"/solution/solution.wxf",saved,"WXF"];
old=<|"SolutionDirectory"->work<>"/solution","Rows"->{1},
 "MasterIntegralBasis"->{Global`GLI[family,{1}]},"RequiredOrders"-><|1->{0}|>|>;
Export[work<>"/old-master.wxf",old,"WXF"];
p=RunProcess[{"wolframscript","-file",root<>"/Scripts/Validation/prepare_complete_master_reference.wls",
 work<>"/old-master.wxf",work<>"/reference.wl","1"}];
FTAssert["an added requested master invalidates the old inventory before AMFlow",
 p["ExitCode"]===1&&StringContainsQ[p["StandardOutput"],"Master inventory changed"]&&!FileExistsQ[work<>"/reference.wl"]];
reduction=<|"BoundaryInputs"->{<|"LaurentCoefficients"-><|0->1,1->2|>|>,<|"LaurentCoefficients"-><|0->3|>|>},
 "DimensionalRegulator"->eps,"InputOrderDetermination"-><|"BoundaryIntegralOrderRanges"-><|1->{0,1},2->{0,0}|>|>|>;
Export[work<>"/reduction.wxf",reduction,"WXF"];
entry[i_,orders_] := <|"ID"->ToString[i],"BoundaryInputIndex"->i,"RequiredOrders"->orders|>;
boundary=<|"AmplitudeReductionFile"->work<>"/reduction.wxf","RecomputeBoundaryIntegrals"->False,
 "BoundaryIntegrals"->{entry[1,{0,1}]}|>;
runBoundary[spec_] := (Export[work<>"/boundary.wxf",spec,"WXF"];
 RunProcess[{"wolframscript","-file",root<>"/Scripts/Validation/validate_stage3.wls",
  work<>"/boundary.wxf",work<>"/report.wxf","1"}]);
p=runBoundary[boundary];
FTAssert["an added boundary input cannot be silently omitted",
 p["ExitCode"]===2&&StringContainsQ[p["StandardOutput"],"Boundary inventory changed"]];
p=runBoundary[Join[boundary,<|"BoundaryIntegrals"->{entry[1,{0}],entry[2,{0}]}|>]];
FTAssert["increased boundary epsilon demands invalidate an old inventory",
 p["ExitCode"]===2&&StringContainsQ[p["StandardOutput"],"Boundary inventory changed"]];
p=runBoundary[Join[boundary,<|"BoundaryIntegrals"->{entry[1,{0,1}],entry[2,{0}]}|>]];
FTAssert["a current inventory reaches coefficient validation and reports missing references",
 p["ExitCode"]===1&&StringContainsQ[p["StandardOutput"],"1 Incomplete"]&&
 !StringContainsQ[p["StandardOutput"],"Boundary inventory changed"]];
DeleteDirectory[work,DeleteContents->True];FTReport[];
