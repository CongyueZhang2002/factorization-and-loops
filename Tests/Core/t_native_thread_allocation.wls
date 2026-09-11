Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Internal`InheritedBlock[{FeynFacet`Private`facetAllocatedProcessorCount},
 Clear[FeynFacet`Private`facetAllocatedProcessorCount];
 FeynFacet`Private`facetAllocatedProcessorCount[]=4;
 Block[{$ProcessorCount=1,Global`$FACETKernelLimit=1},
  FTAssert["native Kira concurrency is independent of Wolfram kernel and OpenMP limits",
   FeynFacet`Private`ibpKiraThreadCount[Automatic]===4];
  FTAssert["requested native threads cannot exceed the CPU allocation",
   FeynFacet`Private`ibpKiraThreadCount[8]===4];
  FTAssert["an explicit serial native request stays serial",
   FeynFacet`Private`ibpKiraThreadCount[1]===1];
  FTAssert["automatic reconstruction uses allocated CPUs with only one Wolfram kernel",
   FeynFacet`Private`finiteFieldThreadCount[Automatic]===4];
  FTAssert["reconstruction threads cannot exceed the process CPU allocation",
   FeynFacet`Private`finiteFieldThreadCount[8]===4];
  FTAssert["an explicit serial reconstruction request stays serial",
   FeynFacet`Private`finiteFieldThreadCount[1]===1];
  FTAssert["invalid reconstruction thread requests fail",
   FeynFacet`Private`finiteFieldThreadCount[0]===$Failed];

 ]
];
count=FeynFacet`Private`facetAllocatedProcessorCount[];
FTAssert["the live allocation is a positive subset of the host CPUs",
 IntegerQ[count]&&1<=count<=FeynFacet`Private`facetProcessorCount[]];
Print["ALLOCATED CPUS ",count," WOLFRAM PROCESSOR COUNT ",$ProcessorCount];
FTReport[];
