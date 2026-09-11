Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
recordRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[recordRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[recordRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
recordValue=<|"Setup"-><|"BuiltinSymbol"->System`Generic,"Regulator"->Global`Epsilon,"PhysicalSymbol"->FeynCalc`CA,"Parton"->FeynArts`F[3,{1}],"Integral"->FeynCalc`GLI["recordFamily",{1,1}],"Distribution"->FeynFacet`h1[recordX]|>,"Coefficients"->Table[(recordX+recordY)^j,{j,100}]|>;
recordFile=CreateTemporary[];FeynFacet`FamilyArtifactWrite[recordValue,recordFile,"Compression"->True];
FTTest`FTAssert["compressed finite records remain directly Get-readable",Get[recordFile]===recordValue];
FTTest`FTAssert["artifact reader preserves every exact symbol and coefficient",FeynFacet`FamilyArtifactRead[recordFile]===recordValue];
DeleteFile[recordFile];
recordFile=CreateTemporary[];FeynFacet`FamilyArtifactWrite[recordValue,recordFile,"Compression"->False];
FTTest`FTAssert["plain records remain directly Get-readable despite regulator name collisions",Get[recordFile]===recordValue];
FTTest`FTAssert["small plain records preserve package symbol contexts",
 FeynFacet`FamilyArtifactRead[recordFile]===recordValue];
DeleteFile[recordFile];recordDirectory=CreateDirectory[];
FTTest`FTAssert["an invalid final rename reports failure and preserves the destination",
 FeynFacet`FamilyArtifactWrite[recordValue,recordDirectory,"Compression"->True]===$Failed&&DirectoryQ[recordDirectory]];
DeleteDirectory[recordDirectory,DeleteContents->True];
FTTest`FTReport[];
