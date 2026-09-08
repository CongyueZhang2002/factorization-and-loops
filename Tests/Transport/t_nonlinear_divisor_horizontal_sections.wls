#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[x,y,ee];
delta=1+x^2+y^2;
a={{{-3 D[delta,x]/(2delta)}},{{-3 D[delta,y]/(2delta)}}};
initial=FeynFacet`Private`solutionAlgebraicHorizontalSectionsAtPoleOrder[a,{x,y},10,All,0];
FTAssert["the first denominator ansatz does not contain a three-halves pole",
 initial==={}];
h=FeynFacet`Private`solutionAlgebraicHorizontalSections[a,{x,y},10];
FTAssert["the bounded higher-pole ansatz finds an algebraic horizontal section",
 Dimensions[h]==={1,1} && !FeynFacet`Private`solutionZero[First[First[h]]] &&
 And@@MapThread[FeynFacet`Private`solutionMatrixZero[D[h,#1]-#2.h]&,
  {{x,y},a}]];
FTAssert["an already successful first ansatz is unchanged",
 FeynFacet`Private`solutionAlgebraicHorizontalSections[{{{0}},{{0}}},{x,y},10]===
 FeynFacet`Private`solutionAlgebraicHorizontalSectionsAtPoleOrder[{{{0}},{{0}}},{x,y},10,All,0]];
FTReport[];
