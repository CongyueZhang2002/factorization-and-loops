$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
niRequest=<|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<r,t<1",
 "BranchPrescription"->"Positive real coordinates"|>;
niSystem[a_,b_]:=<|"NormalVariable"->nr,"TangentialVariable"->nt,"DimensionalRegulator"->ne,
 "NormalConnectionMatrix"->a,"TangentialConnectionMatrix"->b|>;
niEndpoint=FeynFacet`ConstructTangentialEndpointSystem[
 niSystem[{{(1+ne)/nr}},{{(-1+2ne)/nt}}],niRequest];
niResult=FeynFacet`NormalizeEndpointIntersection[niEndpoint];
FTTest`FTAssert["integer gauges at both divisors retain the full original inverse",
 AssociationQ[niResult]&&niResult["Status"]==="ExactLogarithmicIntersectionEstablished"&&
 Simplify[niResult["GaugeMatrix"].niResult["InverseGaugeMatrix"]]==={{1}}&&
 niResult["CornerResidues"]==={{{ne}},{{2ne}}}];
niMixed=FeynFacet`ConstructTangentialEndpointSystem[
 niSystem[{{ne/nr+ne/(nr+nt)}},{{ne/nt+ne/(nr+nt)}}],niRequest,
 "NormalGaugeMatrix"->IdentityMatrix[1]];
niBad=FeynFacet`NormalizeEndpointIntersection[niMixed];
FTTest`FTAssert["nonnegative separate valuations do not approve a mixed divisor through the corner",
 MatchQ[niBad,Failure["LogarithmicNormalCrossingNotEstablished",_]]];
FTTest`FTAssert["a logarithmic coordinate normalization does not select a physical solution",
 niResult["PhysicalModesSelected"]===False];
FTTest`FTReport[];
