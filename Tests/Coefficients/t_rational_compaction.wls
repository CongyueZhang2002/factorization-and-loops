Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
compact[text_]:=FeynFacet`Private`finiteFieldCompactTerm[text,{"x","y"},10];
value[text_]:=Block[{$Context="CompactionTest`",$ContextPath={"System`"}},
 ToExpression[text,InputForm]];
result=compact["(x^2+2*x+1)/(x+1)"];
FTTest`FTAssert["cancels rational factors exactly",
 AssociationQ[result]&&Together[value[result["Text"]]-(CompactionTest`x+1)]===0];
FTTest`FTAssert["keeps a short representation",
 compact["x"]["Text"]==="x"];
FTTest`FTAssert["rejects undeclared variables",
 FailureQ[compact["z+x"]]];
FTTest`FTAssert["rejects algebraic powers",
 FailureQ[compact["x^(1/2)"]]];
FTTest`FTAssert["rejects executable syntax",
 FailureQ[compact["Print[123]"]]];
FTTest`FTAssert["rejects singular arithmetic",
 FailureQ[compact["1/0"]]];
Block[{Global`x=777},
 FTTest`FTAssert["parsing is independent of caller symbol values",
  compact["x"]["Text"]==="x"]];
scratch=CreateDirectory[];
source=scratch<>"/input.expr";destination=scratch<>"/output.expr";
Export[source,"(x+1)*(1/(x+1))+(x^2-1)/(x+1)\n","Text"];
sourceHash=FileHash[source];
column=FeynFacet`Private`finiteFieldCompactColumn[source,destination,{"x","y"},1,10,60];
FTTest`FTAssert["column compaction preserves its sum",
 AssociationQ[column]&&Together[value[Import[column["Output"],"Text"]]-
  value[Import[source,"Text"]]]===0];
FTTest`FTAssert["source file is unchanged",FileHash[source]===sourceHash];
Export[source,"(x+1)+(invalid\n","Text"];
invalid=FeynFacet`Private`finiteFieldCompactColumn[source,destination,{"x","y"},1,10,60];
FTTest`FTAssert["failed splitting cannot publish a replacement",FailureQ[invalid]];
FTTest`FTAssert["working files are closed and removed on failure",
 !FileExistsQ[destination<>".terms"]&&!FileExistsQ[destination<>".partial"]];

Export[source,"x+1\n","Text"];
traceData=<|"OutputFiles"->{source},"OutputOrder"->{"one"},
 "OutputMetadata"->{<|"MasterIndex"->0,"SignatureIndex"->1|>},
 "Masters"->{},"SymbolRules"-><|CompactionTest`x->CompactionTest`x,
   CompactionTest`y->CompactionTest`y|>,
 "Signatures"-><|1->HoldComplete[Times[Power[CompactionTest`y,-1],CompactionTest`x,
   Times[CompactionTest`x,CompactionTest`y]]]|>,"Variables"->{CompactionTest`x,CompactionTest`y},
 "PhysicalFactor"->1,"CompleteTargetSet"->True|>;
compacted=FeynFacet`Private`finiteFieldCompactTrace[traceData,scratch,1,0,10,60];
FTTest`FTAssert["derived compaction manifest roundtrips",
 AssociationQ[compacted]&&KeyExistsQ[compacted,"Compaction"]];
reused=FeynFacet`Private`finiteFieldCompactTrace[traceData,scratch,1,0,10,60];
FTTest`FTAssert["unchanged compaction reuses its bound output",SameQ[compacted,reused]];
executable=FeynFacet`Private`finiteFieldResolveExecutable[Automatic];
nativeDirectory=CreateDirectory[scratch<>"/native"];
built=FeynFacet`Private`finiteFieldBuildTrace[traceData,executable,nativeDirectory];
FTTest`FTAssert["native trace builds for the bound expressions",AssociationQ[built]];
reused=FeynFacet`Private`finiteFieldBuildTrace[traceData,executable,nativeDirectory];
FTTest`FTAssert["unchanged native trace is reused",AssociationQ[reused]&&reused["BuildSeconds"]===0];
Export[source,"y+1\n","Text"];
rebuilt=FeynFacet`Private`finiteFieldBuildTrace[traceData,executable,nativeDirectory];
FTTest`FTAssert["same-size source changes rebuild the native trace",
 AssociationQ[rebuilt]&&rebuilt["BuildSeconds"]>0];
traceData=Append[traceData,"PhysicalFactor"->2];
rebuilt=FeynFacet`Private`finiteFieldBuildTrace[traceData,executable,nativeDirectory];
FTTest`FTAssert["changed output definitions rebuild the native trace",
 AssociationQ[rebuilt]&&rebuilt["BuildSeconds"]>0];
Export[nativeDirectory<>"/TraceOutputs.txt","0 wrong/path.expr\n","Text"];
rebuilt=FeynFacet`Private`finiteFieldBuildTrace[traceData,executable,nativeDirectory];
FTTest`FTAssert["wrong output names cannot reuse an equal-size output list",
 AssociationQ[rebuilt]&&rebuilt["BuildSeconds"]>0];

FTTest`FTAssert["native file hashes equal Wolfram hashes exactly",
 FeynFacet`Private`coefficientFileHashes[{source,destination}]===
  (FileHash[#,"SHA256","HexString"]&/@{source,destination})];
FTTest`FTAssert["native file hashes preserve source order",
 FeynFacet`Private`coefficientFileHashes[{source,destination}]===
  Reverse[FeynFacet`Private`coefficientFileHashes[{destination,source}]]];
parallelDirectory=CreateDirectory[scratch<>"/parallel"];
parallelSource=parallelDirectory<>"/input.expr";
Export[parallelSource,StringRiffle[
 Table["(x^2-"<>ToString[j^2]<>")/(x+"<>ToString[j]<>")",{j,1031}],"+"]<>"\n","Text"];
parallelData=Append[traceData,"OutputFiles"->{parallelSource}];
parallelResult=FeynFacet`Private`finiteFieldCompactTrace[parallelData,parallelDirectory,2,0,10,60];
FTTest`FTAssert["parallel compaction covers multiple input batches exactly",
 AssociationQ[parallelResult]&&value[Import[First[parallelResult["OutputFiles"]],"Text"]]===
  1031 CompactionTest`x-1031*1032/2&&Kernels[]==={}];
DeleteDirectory[scratch,DeleteContents->True];
FTTest`FTReport[];
