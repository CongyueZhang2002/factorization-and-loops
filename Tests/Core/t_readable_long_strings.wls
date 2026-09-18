Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Core/RecordFormat.wl"];
text=StringRepeat["a",300000]<>" System`Quoted "<>StringRepeat["b",300000];
quoted=ToString[text,InputForm];
FTTest`FTAssert["long quoted strings do not exhaust regex recursion",
 FeynFacetRecords`Private`recordQualifiedTextQ[quoted<>" + 1.25`20"]===False];
FTTest`FTAssert["a qualifier after a long string remains forbidden",
 FeynFacetRecords`Private`recordQualifiedTextQ[quoted<>" + Global`x"]===True];
escaped=ToString[StringRepeat["quoted "<>FromCharacterCode[34]<>" text "<>FromCharacterCode[92],20000],InputForm];
FTTest`FTAssert["many escaped quotes and backslashes remain a single string",
 FeynFacetRecords`Private`recordQualifiedTextQ[escaped<>" + 1.25`20"]===False];
FTTest`FTReport[];
