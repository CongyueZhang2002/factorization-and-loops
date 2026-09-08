
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
data=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","RequestedMasterIntegralSolutions","CF48","solution.wxf"}],"WXF"];
expressions=Flatten[Last /@ #& /@ Values[data["MasterIntegralCoefficients"]]];
Clear[degreeRange];
degreeRange[expression_] := Module[{ranges,power},
 Which[
 expression===0,{Infinity,-Infinity},
 MatchQ[expression,FeynFacetSolution`C[_Integer,_Integer]],{1,1},
 FreeQ[expression,_FeynFacetSolution`C],{0,0},
 Head[expression]===Plus,
   ranges=degreeRange /@ List@@expression;
   {Min[ranges[[All,1]]],Max[ranges[[All,2]]]},
 Head[expression]===Times,
   ranges=degreeRange /@ List@@expression;
   If[MemberQ[ranges,{Infinity,-Infinity}],{Infinity,-Infinity},Total[ranges]],
 Head[expression]===Power && IntegerQ[expression[[2]]] && expression[[2]]>0,
   expression[[2]] degreeRange[expression[[1]]],
 True,{-Infinity,Infinity}]];
linearQ[z_]:=MemberQ[{{1,1},{Infinity,-Infinity}},degreeRange[z]];
elapsed=First[AbsoluteTiming[verdicts=linearQ /@ expressions]];
c1=FeynFacetSolution`C[1,0];c2=FeynFacetSolution`C[2,0];
examples={0,c1,c1+c2,c1 c2,c1^2,1+c1,Exp[c1],1/c1,Sin[x]c1/(1+y),c1-c1};
expected={True,True,True,False,False,False,False,False,True,True};
controls=(linearQ /@ examples)===expected;
report=<|"Scope"->"Conservative structural homogeneity check on actual CF48 coefficients plus ten small controls; a candidate, not an installed replacement.",
 "Family"->"CF48","CoefficientCount"->Length[expressions],"Seconds"->elapsed,
 "AllStoredCoefficientsLinear"->And@@verdicts,"ControlsPassed"->controls|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/linearity-candidate.json",report,"RawJSON"];Print[InputForm[report]];
If[!And@@verdicts || !controls,Exit[1]];
