#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
witness=FeynFacet`Private`multiquadraticOffDiagonalBlockInconsistencyWitness;
prime=103;
valid[a_,b_,w_]:=VectorQ[w,IntegerQ] && Length[w]===Length[b] &&
 AllTrue[Mod[w.a,prime],#===0&] && Mod[w.b,prime]=!=0;
a={{1,2},{2,4},{3,6},{4,8}};b={0,0,1,0};
w=witness[a,b,prime];
FTAssert["one witness proves inconsistency of a rank-deficient system",valid[a,b,w]];
FTAssert["a consistent rank-deficient system returns no witness",
 MissingQ[witness[a,{1,2,3,4},prime]]];
FTAssert["a zero right-hand side returns no witness",MissingQ[witness[a,{0,0,0,0},prime]]];
a=ConstantArray[0,{3,2}];b={0,1,0};
FTAssert["rank-zero systems have a unit witness",valid[a,b,witness[a,b,prime]]];
a={{},{},{}};b={0,1,0};
FTAssert["an empty target span still has a witness",witness[a,b,prime]==={0,1,0}];
SeedRandom[8137];a=RandomInteger[{0,prime-1},{600,20}];b=RandomInteger[{0,prime-1},600];
w=witness[a,b,prime];
FTAssert["a tall system needs at most rank plus one supported witness rows",
 valid[a,b,w] && Count[w,Except[0]]<=21];
FTReport[];
