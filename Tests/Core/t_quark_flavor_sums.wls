
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
classes=<|"Up"-><|"Members"->{"u","c"},"Multiplicity"->nu,"Charge"->qu|>,
 "Down"-><|"Members"->{"d","s","b"},"Multiplicity"->nd,"Charge"->qd|>|>;
Do[terms=FeynFacet`QuarkFlavorSumTerms[{"g","g","g"},Range[n],classes];
 FTTest`FTAssert["complete species count for "<>ToString[n]<>" summed indices",
  ListQ[terms]&&Expand[Total[Lookup[terms,"Multiplicity"]]-(1+2nu+2nd)^n]===0],
 {n,0,3}];
terms=FeynFacet`QuarkFlavorSumTerms[{{"q","u"},{"q","d"}},{1,2},classes];
diagonal=Total[Map[If[#["Species"][[1]]===#["Species"][[2]]&&#["Species"][[1]]=!="g",
 #["Multiplicity"]classes[#["FlavorClasses"][Last[#["Species"][[1]]]]]["Charge"]^2,0]&,terms]];
FTTest`FTAssert["repeated flavor indices carry N rather than N squared",
 Expand[diagonal-2nu qu^2-2nd qd^2]===0];
sameFlavorOppositeSigns=Total[Map[If[
 !MemberQ[#["Species"],"g"]&&First[#["Species"][[1]]]=!=First[#["Species"][[2]]]&&
 Last[#["Species"][[1]]]===Last[#["Species"][[2]]],#["Multiplicity"],0]&,terms]];
FTTest`FTAssert["quark and antiquark labels share the same flavor index",
 Expand[sameFlavorOppositeSigns-2(nu+nd)]===0];
FTTest`FTAssert["unknown external flavors are refused",
 FailureQ[FeynFacet`QuarkFlavorSumTerms[{{"q","unknown"}},{1},classes]]];
FTTest`FTReport[];
