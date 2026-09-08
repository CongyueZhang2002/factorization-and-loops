#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[x,z];
normalize=FeynFacet`Private`solutionNormalizeHomogeneousFunctions;
reconstruct=FeynFacet`Private`solutionCyclicReconstruction;
a={{0,1/x},{0,0}};bad={{1,Log[x]},{0,0}};
h=reconstruct[a,bad,x];
FTAssert["cyclic-vector reconstruction restores a missing vector component",
 h==={{1,Log[x]},{0,1}} &&
 FeynFacet`Private`solutionMatrixZero[D[h,x]-a.h] && Det[h]===1];
wrong={{x,x^2},{0,0}};
FTAssert["incorrect scalar components are never promoted to solutions",
 reconstruct[a,wrong,x]===wrong];
FTAssert["a block with no cyclic coordinate is left for another method",
 reconstruct[ConstantArray[0,{2,2}],bad,x]===bad];
expr=Exp[4(ArcTanh[z]-Log[z-3]/2)];
normal=normalize[expr];
FTAssert["integer exponential/logarithm powers become rational functions",
 FreeQ[normal,_ArcTanh|_Log|Power[E,_]] &&
 Cancel[normal-(1+z)^2/((1-z)^2(z-3)^2)]===0];
FTAssert["elementary normalization retains complex branch values",
 And@@(Abs[N[(expr-normal)/.z->#,65]]<10^-50& /@
   {-3,2,1/3+I/5,-2+I/3})];
rootValue=normalize[Sqrt[(x-1)^2]];
FTAssert["radicand expansion does not discard a square-root branch",
 (rootValue/.x->-2)===3];
FTReport[];
