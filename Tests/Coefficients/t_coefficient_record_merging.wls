Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];
master=FeynCalc`GLI["recordFamily",{1,1,-1}];
file=dir<>"/records.bin";
FeynFacet`Private`coefficientWriteRecord[file,<|master->x|>];
FeynFacet`Private`coefficientAppendRecord[file,<|master->x|>];
FTTest`FTAssert["repeated identical reductions are accepted",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,False]===<|master->x|>];
FTTest`FTAssert["repeated amplitude contributions are added",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,True]===<|master->2x|>];
FeynFacet`Private`coefficientAppendRecord[file,<|master->y|>];
FTTest`FTAssert["conflicting reductions fail instead of retaining the first",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,False]===$Failed];
FTTest`FTAssert["distinct contributions to one target remain additive",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,True]===<|master->2x+y|>];
FeynFacet`Private`coefficientWriteRecord[file,{master->x}];
FTTest`FTAssert["non-association records are rejected",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,False]===$Failed];
stream=OpenWrite[file,BinaryFormat->True];
BinaryWrite[stream,100,"UnsignedInteger64"];BinaryWrite[stream,{1,2,3},"Byte"];Close[stream];
FTTest`FTAssert["truncated records are rejected",
 FeynFacet`Private`finiteFieldMergeAssociationRecords[file,False]===$Failed];
DeleteDirectory[dir,DeleteContents->True];
FTTest`FTReport[];
