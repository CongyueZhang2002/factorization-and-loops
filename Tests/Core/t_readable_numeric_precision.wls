Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Core/RecordFormat.wl"];
checks=0;
check[name_,value_]:=If[TrueQ[value],checks++,Print["FAIL ",name];Exit[1]];
qualified=FeynFacetRecords`Private`recordQualifiedTextQ;
check["precision literals are numeric",!qualified["{1.234`20, 0.``40, 1.25`30*^-10, 3.4`6.12345}"]];
check["ordinary qualified names remain rejected",And@@(qualified/@{"Global`x","Foo1`x","System`Plus[1,2]","1.2`Global`x"})];
check["quoted backticks remain literal strings",!qualified["\"Global`x\""]];
tmp=CreateDirectory[];file=tmp<>"/Numbers.wl";
value=<|"HighPrecision"->N[Pi,40],"Zero"->SetAccuracy[0,45],
 "Scientific"->N[32*10^99,25],"Complex"->N[Pi+I E,35],
 "Timing"->1.380831`6.591685521995882|>;
FeynFacetRecords`WriteRecord[value,file];
read=FeynFacetRecords`ReadRecord[file];
check["numeric record round-trip is readable",AssociationQ[read]];
check["precision and value are retained",And@@Table[
 NumberQ[read[key]]&&Abs[read[key]-value[key]]<=10^(-Accuracy[value[key]]+2)&&
 Abs[Accuracy[read[key]]-Accuracy[value[key]]]<10^-8,{key,Keys[value]}]];
DeleteDirectory[tmp,DeleteContents->True];
Print["NUMERIC RECORD TESTS PASS ",checks];
