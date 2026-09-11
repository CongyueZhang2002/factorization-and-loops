Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
scratch=CreateDirectory[];source=scratch<>"/input.expr";Export[source,"FACETtestx+1\n","Text"];
trace=<|"OutputFiles"->{source},"OutputMetadata"->{<|"MasterIndex"->1,"SignatureIndex"->1|>},
 "Masters"->{1},"SymbolRules"-><|Global`x->Global`FACETtestx|>,
 "Signatures"-><|1->HoldComplete[Times[Global`b,Global`a]]|>,
 "Variables"->{Global`x},"PhysicalFactor"->1|>;
job=<|"Name"->"shared","Outputs"->{1},"Bytes"->FileByteCount[source]|>;
options=<|"SeriesVariable"->None,"SeriesOrder"->None,"Threads"->1,"Resume"->True,
 "FactorScan"->True,"ShiftScan"->True,"ProgressInterval"->1|>;
exe=FeynFacet`Private`finiteFieldResolveExecutable[Automatic];
run=FeynFacet`Private`reconstructionRunJob[job,trace,scratch,exe,options];
FTTest`FTAssert["native job completes with a bound checkpoint",AssociationQ[run]];
reuse[opts_]:=FeynFacet`Private`reconstructionJobReusableQ[job,trace,scratch,exe,opts,True];
FTTest`FTAssert["the identical completed request is reusable",TrueQ[reuse[options]]];
FTTest`FTAssert["Resume False forbids reuse",!TrueQ[reuse[Append[options,"Resume"->False]]]];
Export[source,"FACETtestx+2\n","Text"];
FTTest`FTAssert["same-name and same-size changed input invalidates DONE",!TrueQ[reuse[options]]];
Export[source,"FACETtestx+1\n","Text"];
trace=Append[trace,"PhysicalFactor"->2];
FTTest`FTAssert["changed output interpretation invalidates DONE",!TrueQ[reuse[options]]];
trace=Append[trace,"PhysicalFactor"->1];
file=run["RecordFile"];stream=OpenAppend[file];WriteString[stream,"corrupted\n"];Close[stream];
FTTest`FTAssert["a modified result cannot reuse its old completion record",!TrueQ[reuse[options]]];
DeleteDirectory[scratch,DeleteContents->True];
FTTest`FTReport[];
