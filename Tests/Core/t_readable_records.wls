Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
scratch=CreateDirectory[];
file=scratch<>"/record.wl";
data=<|"Coefficients"-><|0->{FeynCalc`CA Global`x+Log[Global`x],System`Generic,Global`Generic}|>,
 "SymbolKeys"-><|Global`keyOnly-><|FeynCalc`key2[Global`x]->Other`x|>|>,
 "HeldNumber"->With[{number=I/2},HoldComplete[number]],
 "Held"->HoldComplete[Plus[Global`x,0],Times[-1,Power[Global`x,-1]]],
 "Unicode"->{Global`αs,Global`ϕa,"α β ϕ"},
 "DifferentContext"->Other`x,"Regulators"->{Global`Epsilon,FeynCalc`Epsilon},
 "Literal"->"Global`x is a string, not a symbol"|>;
FTTest`FTAssert["readable writer completes",FeynFacet`FamilyArtifactWrite[data,file]===file];
text=ReadString[file];
FTTest`FTAssert["the displayed expression uses bare mathematical symbols",
 !StringContainsQ[StringReplace[text,"\"Global`x is a string, not a symbol\""->""],
  "System`"|"Global`"|"FeynCalc`"|"Other`"]];
FTTest`FTAssert["exact symbols and held syntax survive the round trip",
 FeynFacet`FamilyArtifactRead[file]===data];
shadow=Block[{$Context="Other`",$ContextPath={"Other`","Global`","System`"}},
 FeynFacet`FamilyArtifactRead[file]];
FTTest`FTAssert["caller symbol search paths do not change record identities",shadow===data];
FTTest`FTAssert["metadata is a binary companion with no repeated coefficient payload",
 AssociationQ[Import[file<>".meta.wxf","WXF"]]&&
 Import[file<>".meta.wxf","WXF"]["Record"]===<|"Kind"->"Complete"|>];
meta=<|"Order"->"LO","Contribution"->"Born","Scale"->s,"Variables"->{v,w},
 "DimensionalRegulator"->Global`Epsilon,"ProcessDefinition"-><|"Example"->HoldComplete[FeynCalc`Generic]|>|>;
result=FeynFacet`CreatePartonicResult[<|0-><|"DeltaCoefficient"->v,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>,meta];
final=scratch<>"/Results.wl";FeynFacet`FamilyArtifactWrite[result,final];
FTTest`FTAssert["coefficients lead the mathematical file and execution metadata is separate",
 StringStartsQ[StringTrim[StringReplace[ReadString[final],RegularExpression["(?s)\\(\\*.*?\\*\\)"]->""]],
 "<|\"Coefficients\""]&&!StringContainsQ[ReadString[final],"ProcessDefinition"]];
FTTest`FTAssert["the common physical result is fully restored",FeynFacet`ReadPartonicResult[final]===result];
plain=Block[{$Context="ReadableMath`",$ContextPath={"System`","ReadableMath`"}},Get[final]];
FTTest`FTAssert["ordinary Get directly exposes the finite coefficient",
 AssociationQ[plain]&&KeyExistsQ[plain,"Coefficients"]&&plain["Coefficients"][0]["RegularCoefficient"]===0];
large=Association@Table["a"<>ToString[k]-><|"Terms"->Table[FeynCalc`CA Global`αs x^j,{j,20}],"Index"->k|>,{k,4}];
largeFile=scratch<>"/large.wl";
FTTest`FTAssert["multiline records are parsed as one complete expression",
 FeynFacet`FamilyArtifactWrite[large,largeFile]===largeFile&&FeynFacet`FamilyArtifactRead[largeFile]===large];
(* Corruption must be caught even when the unknown symbol occurs only as a key. *)
unknown=scratch<>"/unknown.wl";
FeynFacet`FamilyArtifactCopy[file,unknown];
Export[unknown,StringReplace[text,"<|"->"<|\"Unlisted\"->notInCompanion,",1],"Text"];
FTTest`FTAssert["an unlisted parsed value symbol is rejected",FeynFacet`FamilyArtifactRead[unknown]===$Failed];
FeynFacet`FamilyArtifactCopy[file,unknown];
Export[unknown,StringReplace[text,"<|"->"<|notInCompanion->1,",1],"Text"];
FTTest`FTAssert["an unlisted parsed association key is rejected",FeynFacet`FamilyArtifactRead[unknown]===$Failed];
FTTest`FTAssert["an undeclared symbol cannot disappear through cancellation",
 FeynFacetRecords`Private`decode["<|0->unknown-unknown|>",<||>]===$Failed];
FTTest`FTAssert["undeclared held definitions are rejected before association traversal",
 FeynFacetRecords`Private`decode["HoldComplete[{<|\"k\"->(u=1+1)|>,u}]",<||>]===$Failed];
heldKeyData=With[{z=I},<|HoldComplete[z]->7,HoldComplete[I]->11|>];
heldKeyFile=scratch<>"/heldKeys.wl";
FTTest`FTAssert["distinct held keys survive InputForm abbreviation without merging",
 FeynFacet`FamilyArtifactWrite[heldKeyData,heldKeyFile]===heldKeyFile&&
 FeynFacet`FamilyArtifactRead[heldKeyFile]===heldKeyData];
FTTest`FTAssert["a qualified value cannot bypass the companion symbol table",
 FeynFacetRecords`Private`decode["<|\"a\"->Foreign`q|>",<||>]===$Failed];
FTTest`FTAssert["a qualified key cannot bypass the companion symbol table",
 FeynFacetRecords`Private`decode["<|Foreign`q->1|>",<||>]===$Failed];
scanCases={
 {"x+1",False},{"Foreign`x",True},{"\"Foreign`x\"",False},
 {"\"an escaped \\\" quote and Foreign`x\"",False},
 {"\"backslash \\\\\"<>Foreign`x",True},
 {"\"one`\"<>\"two`\"",False},{"\"one`\"<>Foreign`x<>\"two`\"",True},
 {"<|\"`\"->\"nested \\\"`\\\"\"|>",False}};
FTTest`FTAssert["context scanning respects escaped quotes and backslashes",
 AllTrue[scanCases,FeynFacetRecords`Private`recordQualifiedTextQ[First[#]]===Last[#]&]];
FTTest`FTAssert["many string literals do not hide a trailing qualified symbol",
 FeynFacetRecords`Private`recordQualifiedTextQ[
  StringJoin[ConstantArray["\"string`value\"<>",1000]]<>"Foreign`x"]];
copied=scratch<>"/copy.wl";
FTTest`FTAssert["copy preserves the companion",
 FeynFacet`FamilyArtifactCopy[file,copied]===copied&&FeynFacet`FamilyArtifactRead[copied]===data];
moved=scratch<>"/moved.wl";
FTTest`FTAssert["move preserves the companion",
 FeynFacet`FamilyArtifactMove[copied,moved]===moved&&!FileExistsQ[copied<>".meta.wxf"]&&
 FeynFacet`FamilyArtifactRead[moved]===data];
CopyFile[final<>".meta.wxf",moved<>".meta.wxf",OverwriteTarget->True];
FTTest`FTAssert["a companion from a different write cannot be reused",FeynFacet`FamilyArtifactRead[moved]===$Failed];
FeynFacet`FamilyArtifactDelete[moved];
FTTest`FTAssert["record removal includes metadata",!FileExistsQ[moved]&&!FileExistsQ[moved<>".meta.wxf"]];
DeleteFile[file<>".meta.wxf"];
FTTest`FTAssert["missing metadata fails exact machine reading",FeynFacet`FamilyArtifactRead[file]===$Failed];
binary=scratch<>"/binary.wxf";
FTTest`FTAssert["binary records remain exact",
 FeynFacet`FamilyArtifactWrite[data,binary]===binary&&FeynFacet`FamilyArtifactRead[binary]===data];
DeleteDirectory[scratch,DeleteContents->True];
FTTest`FTReport[];
