#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Solution.m"];
c=FeynFacetSolution`CompareLaurentCoefficients;
a=<|-2->0,-1->3,0->7|>;
FTAssert["all requested coefficients, including an explicit zero, pass",
 With[{r=c[a,a,{-2,-1,0}]},r["Status"]==="Passed"&&r["PassedCoefficientCount"]===3&&r["NonzeroComparisonCount"]===2]];
FTAssert["a missing highest reference order is incomplete, not an intersection pass",
 With[{r=c[a,KeyDrop[a,0],{-2,-1,0}]},r["Status"]==="Incomplete"&&r["MissingReferenceOrders"]==={0}]];
FTAssert["a missing lower computed coefficient is not silently zero",
 With[{r=c[KeyDrop[a,-2],a,{-2,-1,0}]},r["Status"]==="Incomplete"&&r["MissingComputedOrders"]==={-2}]];
FTAssert["absent independent references are never passes",c[a,<||>,{-2,-1,0}]["Status"]==="Incomplete"];
FTAssert["a wrong sign is a numerical failure",c[a,<|-2->0,-1->-3,0->7|>,{-2,-1,0}]["Status"]==="Failed"];
FTAssert["equal low precision values cannot pass an eighteen-digit check",c[<|0->1.|>,<|0->1.|>,{0}]["Status"]==="Failed"];
FTAssert["empty and repeated order inventories are refused",FailureQ[c[a,a,{}]]&&FailureQ[c[a,a,{0,0}]]];
FTReport[];
