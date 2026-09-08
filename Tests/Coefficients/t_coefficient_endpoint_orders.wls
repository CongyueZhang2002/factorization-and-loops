#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solutions/Orders/LaurentBounds.wl"];
Begin["FeynFacet`Private`"];
Get[Global`root<>"/FeynFacet/Coefficients/FinalResults.wl"];
End[];
Get[root<>"/FeynFacet/Coefficients/PoleCancellation.wl"];
Get[root<>"/FeynFacet/Coefficients/EndpointAssembly.wl"];
Clear[e,z,v];
entry[c_,p_:1]:=<|"Terms"->{<|"PreFactor"->p,"Representation"->"Exact","Coefficient"->c|>}|>;
finite[cs_,lo_,p_:1]:=<|"Terms"->{<|"PreFactor"->p,"Representation"->"LaurentSeries",
 "LaurentRemainderClass"-><|"Status"->"EstablishedForSourceCoefficient","NormalDivisor"->z,
   "EpsilonOrderLowerBound"->lo+Length[cs],"NormalPoleOrderUpperBound"->0,
   "UniformOnTangentialCompactSets"->True,"Justification"-><|"TestSource"->"The omitted tail is epsilon^(lo+Length[cs])/(1-epsilon-z), jointly analytic near (0,0)."|>|>,
 "Coefficient"-><|"SeriesVariable"->e,"Orders"->AssociationThread[Range[lo,lo+Length[cs]-1],cs],
   "SeriesTruncation"->lo+Length[cs]-1|>|>}|>;
endpoint[t_,logs_:0]:=<|"DataType"->"TangentialEndpointSystem","DimensionalRegulator"->e,
 "NormalVariable"->z,"TangentialVariable"->v,"Dimension"->Length[t],"NormalGaugeMatrix"->t,
 "PrimarySectors"->{<|"Exponent"->-2e,"NilpotencyIndex"->logs+1|>}|>;
bounds[b_]:=<|"DataType"->"TangentialEndpointLaurentBounds",
 "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"-><|(-2e)->b|>|>;
plan[cs_,t_,b_,logs_:0]:=FeynFacet`DetermineMasterCoefficientEndpointOrders[
 cs,endpoint[t,logs],bounds[b],<|"ThroughOrder"->0|>];
a=plan[{entry[1/z^2],entry[-1/z^2+1/z]},{{1,0},{1,1}},{-1,-1}];
FTAssert["coefficient row is combined with the gauge before normal valuation",
 AllTrue[Cancel[Together[#]]&/@(a["DensityNormalGaugeRow"]-{1/z,(-1+z)/z^2}),#===0&]&&a["MaximumNormalOrder"]===1];
a=plan[{entry[1/z^3],entry[-1/z^3]},{{1,z},{1,0}},{-1,-1}];
FTAssert["cancellation of the most singular transformed coefficient lowers normal depth",
 a["DensityNormalGaugeEntryLowerBounds"]==={Infinity,-2}&&a["MaximumNormalOrder"]===1];
a=plan[{entry[1/z]},{{z^-2}},{-1}];
FTAssert["normal gauge poles require subleading normalized coefficients",
 a["MaximumNormalOrder"]===2];
a=plan[{entry[1/z,e^-2]},{{1}},{-3},2];
FTAssert["Jordan logarithms and coefficient poles increase endpoint epsilon demands",
 a["RequiredEndpointMasterUpperOrders"][1]===5&&
 a["CoefficientTermRequirements"][[1,"RequiredCoefficientUpperOrder"]]===8];
a=plan[{finite[{1,2,3,4,5,6},0]},{{1}},{-4}];
FTAssert["known epsilon fifth order suffices for a fourth-order endpoint pole and one moment",
 a["Status"]==="SufficientOrdersDetermined"&&a["MissingCoefficientOrders"]==={}];
a=plan[{finite[{1,2,3,4,5},0]},{{1}},{-4}];
FTAssert["an unknown epsilon fifth coefficient is never replaced by zero",
 a["Status"]==="CoefficientOrdersMissing"&&
 a["MissingCoefficientOrders"][[1,"RequiredCoefficientUpperOrder"]]===5&&
 !a["NormalDepthSufficientForTargetOrder"]];
a=plan[{finite[{1,2,3,4,5,6},0]},{{1}},{-4},1];
FTAssert["one endpoint logarithm exposes a missing coefficient above epsilon fifth order",
 a["MissingCoefficientOrders"][[1,"RequiredCoefficientUpperOrder"]]===6];
a=plan[{finite[{0,0,0},0]},{{1}},{0}];
FTAssert["zero finite prefixes preserve the bound of their unknown tails",
 a["CoefficientLaurentLowerBounds"]==={3}&&
 a["CoefficientTermRequirements"][[1,"UnknownTailLowerBound"]]===3];
a=plan[{finite[{1,2,3},0,e^-2]},{{1}},{-1}];
FTAssert["finite coefficient availability is checked before analytic prefactor multiplication",
 a["MissingCoefficientOrders"][[1,"RequiredCoefficientUpperOrder"]]===4];
a=plan[{entry[1/(z+e)]},{{1}},{0}];
FTAssert["a divisor approaching the endpoint prevents a false uniform order claim",
 MatchQ[a,Failure["CoalescingCoefficientEndpointDivisor",_]]];
a=plan[{entry[1/(z+e)]},{{z+e}},{0}];
FTAssert["an exact coefficient pole removed by the normal gauge is accepted",
 a["Status"]==="SufficientOrdersDetermined"&&a["DensityNormalGaugeRow"]==={1}];
a=plan[{entry[1/(z+e)],entry[-1/(z+e)+1/z]},{{1,1},{1,1+z+e}},{0,0}];
FTAssert["coalescing poles are checked after the full scalar row cancellation",
 a["Status"]==="SufficientOrdersDetermined"&&
 AllTrue[Cancel[Together[#]]&/@(a["DensityNormalGaugeRow"]-{1/z,(1+e)/z}),#===0&]];
a=FeynFacet`DetermineMasterCoefficientEndpointOrders[{entry[1]},endpoint[{{1}}],
 <|"DataType"->"TangentialEndpointLaurentBounds","OriginalMasterIntegralLaurentLowerBounds"->{0}|>,
 <|"ThroughOrder"->0|>];
FTAssert["a full-function bound cannot substitute for separate regulated-power bounds",
 MatchQ[a,Failure["UniformPrimarySectorLaurentBoundsRequired",_]]];
a=finite[{1,2,3},0];a["Terms"]=KeyDrop[#,"LaurentRemainderClass"]&/@a["Terms"];
a=plan[{a},{{1}},{0}];
FTAssert["known finite coefficients cannot certify the normal structure of their unknown tail",
 a["Status"]==="CoefficientRemainderClassUnresolved"&&
 !a["NormalDepthSufficientForTargetOrder"]&&Length[a["UnresolvedCoefficientRemainderClasses"]]===1];
FTAssert["fixed epsilon and endpoint monomials times a joint unit need no moving-divisor factorization",
 FeynFacet`Private`coefficientEndpointCoalescingDivisors[1/(e^3 z^4 (1-v+e*z)^7),z,e]==={}];
FTAssert["removing fixed monomials still detects a coalescing polynomial factor",
 FeynFacet`Private`coefficientEndpointCoalescingDivisors[1/(e^3 z^4 (z+e)*(1-v+e*z)^7),z,e]=!={}];
FTAssert["analytic scale factors do not turn fixed endpoint poles into moving divisors",
 FeynFacet`Private`coefficientEndpointCoalescingDivisors[1/(s^(2+2e) e^2 z^3 (1-v+e*z)),z,e]==={}];
FTAssert["the actual value of analytic field factors is used in a joint-unit test",
 FeynFacet`Private`coefficientEndpointCoalescingDivisors[1/(s^e-1+z),z,e]=!={}];
FTReport[];
