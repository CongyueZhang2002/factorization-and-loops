Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=CreateDirectory[];
small=<|"Format"->"SyntheticExactWorkspace","Definition"->(1+x)/(2-y)|>;
FeynFacet`Private`cutKiraWorkspaceDefinition[directory<>"/Small",small];
before=BinaryReadList[directory<>"/Small/InputDefinition.wl","Byte"];
FeynFacet`Private`cutKiraWorkspaceDefinition[directory<>"/Small",small];
FTTest`FTAssert["matching exact workspace definitions are not rewritten",
 before===BinaryReadList[directory<>"/Small/InputDefinition.wl","Byte"]];
large=<|"Format"->"SyntheticExactWorkspace","Equations"->Table[<|j->(x+j)/(y+j)|>,{j,20000}]|>;
FeynFacet`Private`cutKiraWorkspaceDefinition[directory<>"/Large",large];
FTTest`FTAssert["large exact solver snapshots use binary records with identical mathematical content",
 FileExistsQ[directory<>"/Large/InputDefinition.wxf"]&&
 FeynFacet`Private`cutKiraReadDefinition[directory<>"/Large"]===large];
FTTest`FTAssert["binary snapshots still reject changed equations",
 FailureQ[Catch[FeynFacet`Private`cutKiraWorkspaceDefinition[directory<>"/Large",Append[large,"Changed"->True]],"CutFamily"]]];
FTTest`FTAssert["exact binary matches reuse the same workspace while changes get another directory",
 FeynFacet`Private`cutKiraSelectWorkspace[directory<>"/Large",large,True]===directory<>"/Large"&&
 FeynFacet`Private`cutKiraSelectWorkspace[directory<>"/Large",Append[large,"Changed"->True],True]=!=directory<>"/Large"];
If[DirectoryQ[directory],DeleteDirectory[directory,DeleteContents->True]];
Print["IBP WORKSPACE SNAPSHOT TEST COMPLETE"];FTTest`FTReport[];
