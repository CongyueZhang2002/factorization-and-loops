Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=CreateDirectory[];file=directory<>"/pair.wl";Export[file,"first","Text"];
calls=0;
Block[{FeynFacet`Private`ibpInputData=Function[{items,targets},
 calls++;<|"Sources"->(ExpandFileName/@items),"Snapshot"->(Import[#,"Text"]&/@items)|>]},
 first=FeynFacet`Private`coefficientInputData[{file},directory];
 reused=FeynFacet`Private`coefficientInputData[{file},directory];
 same=first===reused&&calls===1;
 Export[file,"second","Text"];
 changed=FeynFacet`Private`coefficientInputData[{file},directory];
 different=changed=!=first&&calls===2&&changed["Snapshot"]==={"second"};
];
DeleteDirectory[directory,DeleteContents->True];
If[!TrueQ[same&&different],Print["SOURCE SUMMARY CACHE FAILED ",same," ",different];Exit[1]];
Print["SOURCE SUMMARY CACHE TEST PASS"];
