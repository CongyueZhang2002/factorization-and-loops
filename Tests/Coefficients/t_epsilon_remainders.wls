root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Algebra/EpsilonRemainders.wl"];
Clear[e,x];
input[m_]:=<|"a"-><|"Expression"->1+e,"KnownThroughOrder"->m,"Variables"->{x}|>|>;
r=CheckEpsilonTruncation[Function[v,v["a"]/e^2],input[2],e,{0,0}];
FTAssert["sufficient product orders leave no arbitrary remainder in the requested coefficient",r["Status"]==="Passed"];
r=CheckEpsilonTruncation[Function[v,v["a"]/e^2],input[1],e,{0,0}];
FTAssert["one missing order is exposed by an epsilon pole",r["Status"]==="ContaminationDetected"];
r=CheckEpsilonTruncation[Function[v,D[v["a"],e]],<|"a"-><|"Expression"->0,"KnownThroughOrder"->-1|>|>,e,{0,0}];
FTAssert["higher unknown Taylor coefficients survive when the first constant error would differentiate to zero",r["Status"]==="ContaminationDetected"];
r=CheckEpsilonTruncation[Function[v,D[v["a"],x]/e],input[0],e,{0,0}];
FTAssert["kinematic dependence of omitted coefficients is retained",r["Status"]==="ContaminationDetected"];
pair=<|"a"-><|"Expression"->0,"KnownThroughOrder"->1|>,"b"-><|"Expression"->0,"KnownThroughOrder"->1|>|>;
r=CheckEpsilonTruncation[Function[v,v["a"] v["b"]/e^4],pair,e,{0,0}];
FTAssert["products of two omitted remainders are not lost",r["Status"]==="ContaminationDetected"&&
 Sort[First[r["ContaminatedCoefficients"]]["Sources"]]==={"a","b"}];
FTAssert["independent inputs cannot cancel through a shared debug symbol",
 CheckEpsilonTruncation[Function[v,(v["a"]-v["b"])/e^2],pair,e,{0,0}]["Status"]==="ContaminationDetected"];
FTAssert["repeated use of the same input preserves exact cancellation",
 CheckEpsilonTruncation[Function[v,v["a"]-v["a"]],pair,e,{0,0}]["Status"]==="Passed"];
r=CheckEpsilonTruncation[Function[v,(v["m"].{1,-1})[[1]]],
 <|"m"-><|"Expression"->IdentityMatrix[2],"KnownThroughOrder"->0|>|>,e,{1,1}];
FTAssert["matrix entries have independent omitted coefficients",r["Status"]==="ContaminationDetected"&&
 Length[First[r["ContaminatedCoefficients"]]["Sources"]]===2];
FTAssert["inverse operations propagate omitted coefficients",
 CheckEpsilonTruncation[Function[v,1/v["a"]],input[0],e,{1,1}]["Status"]==="ContaminationDetected"];
FTAssert["exact inputs acquire no artificial remainder",
 CheckEpsilonTruncation[Function[v,v["a"]/e^4],<|"a"-><|"Expression"->e^2,"ExactInEpsilon"->True|>|>,e,{-2,0}]["Status"]==="Passed"];
r=WithEpsilonRemainderChecks[42];
FTAssert["an uninstrumented or cached computation does not falsely report a passed audit",r["EpsilonRemainderAudit"]["Status"]==="NoChecksExecuted"];
r=WithEpsilonRemainderChecks[FeynFacet`Private`epsilonAuditProduct[
 {FeynFacet`Private`epsilonAuditSpec["A",0,1],FeynFacet`Private`epsilonAuditSpec["B",-2,0]},0,"Product"];42];
FTAssert["fast production checks stop on an omitted term that can reach the output",
 FailureQ[r["Result"]]&&r["EpsilonRemainderAudit"]["Status"]==="Failed"];
r=WithEpsilonRemainderChecks[FeynFacet`Private`epsilonAuditProduct[
 {FeynFacet`Private`epsilonAuditSpec["ExactZero",Infinity,0],
  FeynFacet`Private`epsilonAuditSpec["UnusedBoundary",Missing["NotRequired"],-Infinity]},0,"Product"];42];
FTAssert["an exact zero multiplier needs no bound on an unused boundary",r["EpsilonRemainderAudit"]["Status"]==="Passed"];
FTAssert["a failed calculation cannot be mistaken for an uncontaminated symbolic answer",
 FailureQ[CheckEpsilonTruncation[Function[v,$Failed],input[0],e,{0,0}]]];
r=WithEpsilonRemainderChecks[FeynFacet`Private`epsilonAuditProduct[
 {FeynFacet`Private`epsilonAuditSpec["A",0,0]},0,"Product"];$Failed];
FTAssert["a failed production result is not marked as a passed audit",
 r["EpsilonRemainderAudit"]["Status"]==="CalculationFailed"];
FTAssert["debug scope restores normal production behavior",!TrueQ[FeynFacet`Private`$epsilonRemainderChecks]];
FTReport[];
