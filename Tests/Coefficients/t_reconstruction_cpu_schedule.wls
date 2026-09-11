Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Get[root<>"/Tests/TestKit.wl"];
jobs={<|"Name"->"first","Outputs"->{1},"Bytes"->100|>,
 <|"Name"->"second","Outputs"->{2},"Bytes"->200,"SeriesVariable"->eps,"SeriesOrder"->1|>};
options=<|"Threads"->Automatic,"SeriesVariable"->None,"SeriesOrder"->None,"Resume"->False|>;
allocation=0;calls={};active=0;peak=0;
Block[{FeynFacet`Private`facetAllocatedProcessorCount=Function[{},allocation++;If[allocation===1,1,8]],
 FeynFacet`Private`reconstructionJobReusableQ=Function[{a,b,c,d,e,f},False],
 FeynFacet`Private`reconstructionRunJob=Function[{job,data,path,exe,opts},
 active++;peak=Max[peak,active];AppendTo[calls,opts];active--;
 <|"Name"->job["Name"],"RecordBytes"->10,"Seconds"->0,"Statistics"-><|"Probes"->1|>|>]},
 records=FeynFacet`Private`reconstructionRunSchedule[jobs,<||>,"/unused","unused",options];
];
FTAssert["a later native job receives newly available CPUs",
 Lookup[calls,"Threads"]==={1,8}];
FTAssert["the shared queue never overlaps full-budget native jobs",
 peak===1&&Length[records]===2];
FTAssert["per-job epsilon modes are preserved independently of CPU allocation",
 calls[[1]]["SeriesVariable"]===None&&calls[[2]]["SeriesVariable"]===eps&&calls[[2]]["SeriesOrder"]===1];
FTReport[];
