Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
directory=CreateDirectory[];
record=<|"Format"->"TestRecord","HeldSignature"->HoldComplete[2^(1+2Global`Epsilon)*Pi^(2Global`Epsilon)],
 "SourceDefinition"->HoldComplete[Global`D,Global`Epsilon,System`D],
 "FiniteTerms"->{<|"Orders"-><|-1->0,0->1|>,"SeriesTruncation"->0|>}|>;
file=directory<>"/result.wl";
written=FeynFacet`Private`coefficientWriteFinalResult[record,file];
passed=TrueQ[written]&&Get[file]===record;
DeleteDirectory[directory,DeleteContents->True];
If[!passed,Print["FINAL RECORD STORAGE FAILED"];Exit[1]];
Print["FINAL RECORD STORAGE TEST PASS"];
