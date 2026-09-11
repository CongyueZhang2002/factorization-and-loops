Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`Private`"}},
 Get[root<>"/FeynFacet/Algebra/ExactArithmetic.wl"]];
samples={1,1/3,1+2I,1.2,SetPrecision[1.2,50],1.2+3I,1+2.3I,
 HoldComplete[f[1.2]],<|"a"->{1/3,2I}|>,<|"a"->f[1.2]|>,
 SparseArray[{{1,1}->1/3},{2,2}],SparseArray[{{1,1}->1.2},{2,2}],
 Indeterminate,Infinity,Root[#^2-2&,1],SparseArray[{},{100000,100000},1.2]};
expected={True,True,True,False,False,False,False,False,True,False,True,False,True,True,True,False};
MapIndexed[(FTTest`FTAssert["exact-number containment "<>ToString[First[#2]],
 FeynFacet`Private`exactDataQ[#1]===expected[[First[#2]]]])&,samples];
FTTest`FTReport[];
