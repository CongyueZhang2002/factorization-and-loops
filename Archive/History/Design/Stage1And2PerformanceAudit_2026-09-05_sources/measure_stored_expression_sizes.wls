
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
data=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","RequestedMasterIntegralSolutions","CF303","solution.wxf"}],"WXF"];
sizes=ReverseSortBy[KeyValueMap[<|"Field"->#1,"WolframBytes"->ByteCount[#2]|>&,data],#["WolframBytes"]&];
report=<|"Family"->"CF303","TotalWolframBytes"->ByteCount[data],
 "LargestFields"->Take[sizes,UpTo[12]],
 "FiniteIntegralCount"->Length[data["IntegralDefinitions"]],
 "KernelCount"->Length[data["KernelDefinitions"]],
 "ArithmeticCount"->Length[data["AlgebraicDefinitions"]]|>;
Export[DirectoryName[ExpandFileName[$InputFileName]]<>"/CF303-stored-size.json",report,"RawJSON"];Print[InputForm[report]];
