Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
names={"FACETtestAlias1","FACETtestAlias2"};
originals=<|"FACETtestAlias1"->AliasSourceA`x,"FACETtestAlias2"->AliasSourceB`x|>;
parse[text_]:=FeynFacet`Private`reconstructionParseBlock[text,names,originals];
FTTest`FTAssert["a bare alias is decoded at expression level zero",
 parse["FACETtestAlias1"]===AliasSourceA`x];
FTTest`FTAssert["source contexts remain distinct",
 parse["FACETtestAlias1^2+3*FACETtestAlias2"]===AliasSourceA`x^2+3AliasSourceB`x];
FTTest`FTAssert["the parsing context does not change alias identity",
 parse["ForeignParsingContext`FACETtestAlias2"]===AliasSourceB`x];
FTTest`FTAssert["exact numeric coefficients need no alias",
 parse["7/13"]===7/13];
FTTest`FTAssert["unknown input symbols are rejected",
 FailureQ[parse["UnregisteredTraceVariable"]]];
FTTest`FTAssert["a malformed reverse map cannot retain a generated alias",
 MatchQ[FeynFacet`Private`reconstructionParseBlock["FACETtestAlias1",names,
 <|"FACETtestAlias1"->FACETtestAlias1,"FACETtestAlias2"->AliasSourceB`x|>],
 Failure["UndecodedAlias",_Association]]];
FTTest`FTAssert["a bare rational variable is registered before trace emission",
 FeynFacet`Private`finiteFieldRationalSymbols[AliasSourceA`x]==={AliasSourceA`x}];
FTTest`FTReport[];
