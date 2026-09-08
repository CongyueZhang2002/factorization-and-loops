$HistoryLength=0;
root="/home/maxzhang/factorization-and-loops";
Get[root<>"/FeynFacet/FiniteSolutionData.wl"];
base=root<>"/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06";
files=Join[FileNames["solution.wxf",base,Infinity],FileNames["input.wxf",base,Infinity]];
retired={"/Exchange/","/Runtime/","/Prototypes/","/Archive/","BoundaryInventory", "/Stale/","2026-09-03_pre_v2","DifferentialEquationDataV2","Overnight_2026-09-06",
 "RequestedMasterIntegralSolutions","TwoRootCF","TransportProjection_2026-08-17"};
issues={};
Do[data=Import[file,"WXF"];
 found=DeleteDuplicates[Cases[data,s_String /; AnyTrue[retired,StringContainsQ[s,#]&],Infinity]];
 If[found=!={},AppendTo[issues,<|"File"->file,"References"->found|>]],{file,files}];
Export["/tmp/feynfacet-repository-cleanup-20260906/current-dependency-check.wxf",
 <|"Files"->Length[files],"OldRunReferences"->issues|>,"WXF"];
Print["CURRENT WXF INPUT/SOLUTION FILES ",Length[files]," OLD RUN REFERENCES ",issues];
Exit[If[issues==={} && Length[files]===182,0,1]];
