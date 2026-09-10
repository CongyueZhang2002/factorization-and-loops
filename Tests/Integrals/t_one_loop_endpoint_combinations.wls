$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[ce,cr,cs,cq];assum=cq>0&&0<cr<1/3&&0<cs<1/3;
y=1-(1-cs)/(1-cr);bubble=FeynCalc`B0[-cq,0,0];
source=(FeynCalc`B0[-cq(1-cs)/(1-cr),0,0]-bubble(1+ce y))/y^2;
resolved=FeynFacet`ResolveOneLoopScalarEndpointPowers[<|"A"->source|>,ce,{cr,cs},assum];
FTAssert["coincident bubble Gram poles are removed by exact divided differences",
 AssociationQ[resolved]&&resolved["JointAnalyticFactorsVerified"]&&
 resolved["CoincidentBubbleSubtractions"][[1,"TaylorSubtractionOrder"]]===2];
expr=If[AssociationQ[resolved],Total[
 (Times@@MapThread[Power,{{cr,cs},#["Powers"]}])#["SmoothFactor"]&/@resolved["Terms"]],0];
params={cr->1/9,cs->1/7,cq->7/3,ce->-1/11};
direct=FeynFacet`EvaluateOneLoopScalarFunctions[source,ce,assum];
FTAssert["resolved bubble pair agrees off the coincident divisor",
 Abs[N[(Activate[expr]-direct)/.params,40]]<10^-32];
limit=FeynFacet`EvaluateOneLoopScalarFunctions[bubble,ce,assum]ce(ce+1)/2;
FTAssert["coincident bubble value uses the regular second Taylor coefficient",
 Abs[N[(Activate[expr/.cs->cr]-limit)/.{cr->1/9,cq->7/3,ce->-1/11},40]]<10^-32];
FTAssert["a scalar mixed denominator remains a failure despite a regular master",
 FailureQ[FeynFacet`ResolveOneLoopScalarEndpointPowers[
 <|"A"->bubble cr/(cr+cs)^3|>,ce,{cr,cs},assum]]];
FTReport[];
