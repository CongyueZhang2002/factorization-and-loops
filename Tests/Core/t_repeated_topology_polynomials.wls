
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
topology=FeynCalc`FCTopology[topA,FeynCalc`FCI/@{FeynCalc`SFAD[loop],FeynCalc`SFAD[loop-ext]},
 {loop},{ext},{},{}];
reference=FeynFacet`Private`canonicalPakFormUncached[topology,{1}];
FTTest`FTAssert["the exact reference Pak polynomial is available",AssociationQ[reference]];
DownValues[originalPak]=DownValues[FeynFacet`Private`canonicalPakFormUncached]/.
 FeynFacet`Private`canonicalPakFormUncached->originalPak;
calls=0;
values=Internal`InheritedBlock[{FeynFacet`Private`canonicalPakFormUncached},
 Clear[FeynFacet`Private`canonicalPakFormUncached];
 FeynFacet`Private`canonicalPakFormUncached[args___]:=(calls++;originalPak[args]);
 Block[{FeynFacet`Private`$canonicalPakCache=<||>},
  {FeynFacet`Private`canonicalPakForm[topology,{1}],
   FeynFacet`Private`canonicalPakForm[ReplacePart[topology,1->topB],{1}],
   FeynFacet`Private`canonicalPakForm[topology,{1,2}]}]];
FTTest`FTAssert["changing only the integral label reuses the exact polynomial and ordering",
 values[[1]]===reference&&values[[2]]===reference&&calls===2];
FTTest`FTAssert["a different cut mask is computed independently",
 values[[3]]===FeynFacet`Private`canonicalPakFormUncached[topology,{1,2}]];
FTTest`FTAssert["the cache does not outlive its construction",
 !AssociationQ[FeynFacet`Private`$canonicalPakCache]];
FTTest`FTReport[];
