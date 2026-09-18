Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];SetEnvironment["FEYNFACET_MASTER_LIBRARY_DIRECTORY"->dir];
FeynFacet`$MasterIntegralLibraryMode="ReadWrite";
v=FeynFacet`EvaluateMasslessVertexMaster["A2Squared",q2,ep,{-2,0}];
w=FeynFacet`EvaluateMasslessVertexMaster["A2Squared",q2,ep,{-2,0}];
FTTest`FTAssert["two-loop scalar providers publish and reuse explicit values",
 AssociationQ[v]&&AssociationQ[w]&&KeyExistsQ[v,"LibraryStorage"]&&KeyExistsQ[w,"LibraryReuse"]&&
 AllTrue[Keys[v["Coefficients"]],Simplify[v["Coefficients"][[Key[#]]]-w["Coefficients"][[Key[#]]]]===0&]];
c=FeynFacet`EvaluateMasslessVertexMaster["A2ConjugateProduct",q2,ep,{-2,0}];
FTTest`FTAssert["the fixed i*pi measure retains the anti-Feynman bubble sign",
 AssociationQ[c]&&AllTrue[Keys[v["Coefficients"]],
 Simplify[v["Coefficients"][[Key[#]]]+c["Coefficients"][[Key[#]]]]===0&]];
b=FeynFacet`EvaluateOneLoopScalarFunctions[FeynCalc`B0[s,0,0],ep,s>0];
FTTest`FTAssert["scalar B0 publication preserves its pi^(-epsilon) normalization",
 FreeQ[b,_Failure]&&FeynFacet`MasterIntegralLibraryInventory[][ "MasterCount"]===3];
d=FeynFacet`Private`masterLibraryScalarFunctionDefinition[FeynCalc`B0[s,0,0],ep,s>0];
b0=FeynFacet`FindMasterIntegralValue[d,Automatic];
FTTest`FTAssert["the stored bubble uses the normalized loop measure",
 AssociationQ[b0]&&Simplify[b-Pi^-ep b0["ExactValue"]]===0];
box=FeynFacet`EvaluateMasslessBoxIntegral[{s,t,0},ep,{-2,0},s<0&&t<0];
again=FeynFacet`EvaluateMasslessBoxIntegral[{s,t,0},ep,{-1,0},s<0&&t<0];
FTTest`FTAssert["box coefficients publish and are reused with complete lower coverage",
 AssociationQ[box]&&AssociationQ[again]&&KeyExistsQ[again,"LibraryReuse"]&&
 AllTrue[Keys[box["Coefficients"]],Simplify[box["Coefficients"][[Key[#]]]-again["Coefficients"][[Key[#]]]]===0&]];
massive=FeynFacet`EvaluateOneLoopScalarFunctions[FeynCalc`B0[s,m2,0],ep,s>0];
FTTest`FTAssert["an unsupported massive scalar cannot alias a cached massless integral",FailureQ[massive]];
below=FeynFacet`EvaluateMasslessBoxIntegral[{belowS,belowT,0},ep,{-4,-3},belowS<0&&belowT<0];
If[!AssociationQ[below],Print["BELOW-POLE RESULT ",below]];
FTTest`FTAssert["requests below the first pole retain certified zero coefficients",
 AssociationQ[below]&&AllTrue[Values[below["Coefficients"]],#===0&]];
FeynFacet`$MasterIntegralLibraryMode="Disabled";
plain=FeynFacet`EvaluateMasslessVertexMaster["A3",q2,ep,{-1,0}];
FTTest`FTAssert["Disabled mode preserves provider evaluation without publication",
 AssociationQ[plain]&&!KeyExistsQ[plain,"LibraryStorage"]&&
 FeynFacet`MasterIntegralLibraryInventory[][ "MasterCount"]===5];
FTTest`FTReport[];
