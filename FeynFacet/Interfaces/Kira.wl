(* Maintained Kira configuration adapter.
   FeynHelpers 2.0.0 writes malformed YAML for a shifted bilinear denominator.
   Keep its standard quadratic representation and kinematic/job conventions;
   serialize each linear denominator directly as its exact scalar polynomial.
   Kira general propagators: arXiv:2008.06494, section 3.9. *)
Begin["FeynFacet`Private`"];
Options[kiraCreateConfigFiles]=Options[FeynCalc`KiraCreateConfigFiles];
kiraCreateConfigFiles[top_FeynCalc`FCTopology,sectors_List,directory_String,opts:OptionsPattern[]]:=Module[
 {files,descriptors,linear,lines,start,positions,core,text,index},
 descriptors=propagatorDescriptor/@top[[2]];
 If[MemberQ[descriptors,$Failed],Return[$Failed]];
 linear=Flatten[Position[Lookup[descriptors,"Type"],"LinearLorentzian"]];
 files=FeynCalc`KiraCreateConfigFiles[top,sectors,directory,opts];
 If[!MatchQ[files,{_String,_String}]||linear==={},Return[files]];
 lines=Import[First[files],"Lines"];
 start=FirstPosition[lines,line_String/;StringTrim[line]==="propagators:"];
 If[MissingQ[start],Return[$Failed]];
 positions=Select[Range[First[start]+1,Length[lines]],
  StringStartsQ[StringTrim[lines[[#]]],"- "]&];
 If[Length[positions]=!=Length[descriptors],Return[$Failed]];
 Do[
  core=FeynCalc`ExpandScalarProduct[descriptors[[index,"UnitCore"]]]/.OptionValue[FeynCalc`FinalSubstitutions];
  core=core/.FeynCalc`Pair[FeynCalc`Momentum[a_,D],FeynCalc`Momentum[b_,D]]:>a b;
  If[!FreeQ[core,_FeynCalc`Pair|_FeynCalc`Momentum|_Real|_Failure],Return[$Failed]];
  text=Block[{$Context="Global`",$ContextPath={"System`","Global`","FeynCalc`"}},
   ToString[core,InputForm]];
  If[!StringMatchQ[text,RegularExpression["[A-Za-z0-9_ +*/^().-]+"]],Return[$Failed]];
  lines[[positions[[index]]]]="      - [ \""<>text<>"\", 0 ]",
 {index,linear}];
 Export[First[files],StringRiffle[lines,"\n"]<>"\n","String"];
 files
];
End[];
