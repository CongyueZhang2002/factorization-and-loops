Get[DirectoryName[ExpandFileName[$InputFileName],4]<>"/FeynFacet/Algebra/EpsilonRemainders.wl"];
(* Driver control-flow tests only; mathematical constructors have separate
   exact tests and current-process pilots. *)
Clear[FeynFacet`Private`coefficientMasterID,FeynFacet`DetermineMasterCoefficientEndpointOrders,
 FeynFacet`ExtendTangentialEndpointSystem,FeynFacet`ConstructScalarEndpointProjection,
 FeynFacet`ConstructScalarEndpointSolution];
Global`$ScalarDriverTestCalls=<|"Orders"->0,"Extension"->0,"Projection"->0,"Solution"->0|>;
Global`$ScalarDriverSkipDelay=False;
ScalarDriverTestCall[name_]:=AssociateTo[Global`$ScalarDriverTestCalls,
 name->(Global`$ScalarDriverTestCalls[name]+1)];
FeynFacet`Private`coefficientMasterID[x_]:=x;
FeynFacet`DetermineMasterCoefficientEndpointOrders[entries_,endpoint_,bounds_,request_] := (
 ScalarDriverTestCall["Orders"];
 <|"Status"->Switch[Lookup[request,"Mode","Success"],
    "Unresolved","CoefficientRemainderClassUnresolved","Missing","CoefficientOrdersMissing",_,"SufficientOrdersDetermined"],
   "MaximumNormalOrder"->Lookup[request,"Depth",1],"Mode"->Lookup[request,"Mode","Success"],
   "MissingCoefficientOrders"->{},"UnresolvedCoefficientRemainderClasses"->{}|>);
FeynFacet`ExtendTangentialEndpointSystem[endpoint_,depth_,OptionsPattern[]] := (
 ScalarDriverTestCall["Extension"];Join[endpoint,<|"MaximumNormalOrder"->depth|>]);
FeynFacet`ConstructScalarEndpointProjection[plan_,endpoint_,bounds_] := (
 ScalarDriverTestCall["Projection"];
 If[MemberQ[{"AuditGood","AuditLeak"},plan["Mode"]],
  FeynFacet`Private`epsilonAuditMultiplier[
   If[plan["Mode"]==="AuditLeak",1/Global`auditEpsilon,1],Global`auditEpsilon,
   0,0,0,"Test/ScalarEndpointConstruction","mock"]];
 If[plan["Mode"]==="Timeout"&&!TrueQ[Global`$ScalarDriverSkipDelay],Pause[5]];
 <|"DataType"->"ScalarEndpointProjection","Mode"->plan["Mode"]|>);
FeynFacet`ConstructScalarEndpointSolution[projection_,endpoint_,request_,OptionsPattern[]] := (
 ScalarDriverTestCall["Solution"];
 If[projection["Mode"]==="PhysicalMissing",
  Failure["PhysicalEndpointAmplitudeOrderMissing",<|"Column"->1,"Order"->7|>],
  <|"DataType"->"FiniteScalarEndpointSolution","EndpointTerms"->{1},
    "RequiredInitialConstantCoefficients"->{},
    "WorkerInvocation"->Global`$ScalarDriverTestCalls["Solution"]|>]);
