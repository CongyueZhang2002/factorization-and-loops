(* File and coefficient handling for the two validation drivers. *)
readValidationFile[path_] := If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
validationPath[base_,path_] := ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
writeValidationFile[path_,data_] := Module[{tmp=path<>".tmp"},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 Export[tmp,BinarySerialize[data,PerformanceGoal->"Size"],"Byte"];RenameFile[tmp,path,OverwriteTarget->True]];
validationCoefficients[data_Association,orders_,eps_] := Module[{expr,series},
 If[AssociationQ[Lookup[data,"LaurentCoefficients",None]],Return[data["LaurentCoefficients"]]];
 expr=Lookup[data,"AnalyticExpression",Missing[]];If[MissingQ[expr],Return[<||>]];
 expr=expr/.s_Symbol/;MemberQ[{"eps","ep","Epsilon"},SymbolName[s]]:>eps;
 series=Quiet[Series[expr,{eps,0,Max[orders]}]];
 If[!FreeQ[series,_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity],Return[<||>]];
 Association@Table[k->SeriesCoefficient[series,{eps,0,k}],{k,orders}]
];
validationSelectedFile[base_,spec_] := Module[{data},
 If[!AssociationQ[spec]||!KeyExistsQ[spec,"File"],Return[Missing["NoReference"]]];
 If[!FileExistsQ[validationPath[base,spec["File"]]],Return[Missing["FileNotFound"]]];
 data=readValidationFile[validationPath[base,spec["File"]]];
 Do[data=If[AssociationQ[data],Lookup[data,key,Missing["KeyNotFound"]],Missing["KeyNotFound"]],
  {key,Lookup[spec,"Keys",{}]}];data
];
validationMasterID[master_] := {ToString[master[[1]],InputForm]/.s_String:>StringReplace[s,"\""->""],master[[2]]};
