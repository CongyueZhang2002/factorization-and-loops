Print["FEYNFACET DRIVER ENTERED"];
(* Deletion is allowed only after a final result exists outside the run's
   guarded working directory. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
run="retention_test_"<>StringReplace[CreateUUID[],"-"->""];
resultDirectory=FileNameJoin[{root,"Projects","ppHX_UU","Results","NLO","qqp-qqp","Validation",run}];
CreateDirectory[resultDirectory,CreateIntermediateDirectories->True];
kira=FileNameJoin[{resultDirectory,"KiraResult.wl"}];
work=FeynFacet`Private`coefficientWorkDirectory[kira];
CreateDirectory[work,CreateIntermediateDirectories->True];
Put["working data",FileNameJoin[{work,"probe.wl"}]];
file=FileNameJoin[{resultDirectory,"CoefficientResult.wl"}];
FTTest`FTAssert["missing final result preserves work",
 FeynFacet`Private`coefficientRemoveWorkingFiles[kira,file]===$Failed&&DirectoryQ[work]];
inside=FileNameJoin[{work,"CoefficientResult.wl"}];Put[<|"Coefficient"->1|>,inside];
FTTest`FTAssert["a result inside work preserves work",
 FeynFacet`Private`coefficientRemoveWorkingFiles[kira,inside]===$Failed&&DirectoryQ[work]];
value=<|"Coefficient"->(1+retentionX)/(1-retentionEpsilon)|>;
FTTest`FTAssert["atomic writer round-trips the final value",
 FeynFacet`Private`coefficientWriteFinalResult[value,file]&&FeynFacet`FamilyArtifactRead[file]===value];
FTTest`FTAssert["cleanup preserves the final result",
 StringQ[FeynFacet`Private`coefficientRemoveWorkingFiles[kira,file]]&&
 !DirectoryQ[work]&&FeynFacet`FamilyArtifactRead[file]===value];
DeleteDirectory[resultDirectory,DeleteContents->True];
parent=DirectoryName[work];
While[DirectoryQ[parent]&&FileNames["*",parent]==={}&&
 StringStartsQ[parent,root<>"/Projects/ppHX_UU/Results/CoefficientSimplification"],
 DeleteDirectory[parent];parent=DirectoryName[parent]];
FTTest`FTReport[];
