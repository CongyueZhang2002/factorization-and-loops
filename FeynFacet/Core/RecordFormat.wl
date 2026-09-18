(* Readable Wolfram data and a binary companion for exact symbol identities. *)
BeginPackage["FeynFacetRecords`"];
ReadRecord::usage="ReadRecord[file,context] restores a readable record and its exact binary metadata. Plain Wolfram input files remain readable.";
WriteRecord::usage="WriteRecord[value,file] writes readable data and a compact .meta.wxf companion; .wxf targets are binary records.";
MoveRecord::usage="MoveRecord[source,target] moves a record and its metadata together.";
CopyRecord::usage="CopyRecord[source,target] copies a record and its metadata together.";
DeleteRecord::usage="DeleteRecord[file] deletes a record and its companion.";
Begin["`Private`"];
$header="(* FeynFacet readable record 2; exact machine reading uses the .meta.wxf companion. *)\n";
$messages={};
$visiblePartonicKeys={"Coefficients","BornExpression","ExpressionThroughSelectedOrder","EpsilonRange","Project","Order","Channel","PhysicalChannel",
 "Polarization","Contribution","ResultType","StructureFunctions","Scale","Variables",
 "Coupling","CouplingPower","DensityConvention","DistributionBasis","DimensionalRegulator",
 "DimensionalPrefactor"};
metadataFile[file_String]:=file<>".meta.wxf";
writeIdentifier[id_String]:="(* Companion: "<>id<>" *)\n";
(* Persist execution/definition details once, outside the displayed mathematics. *)
splitRecord[value_Association]:=Module[{keys,shown,hidden},
 If[Lookup[value,"Format",None]==="FeynFacet-PartonicResult",
  keys=Select[$visiblePartonicKeys,KeyExistsQ[value,#]&];
  Return[{KeyTake[value,keys],<|"Kind"->"Partonic","Hidden"->KeyDrop[value,keys],
    "KeyOrder"->Keys[value]|>}]];
 If[Lookup[value,"Format",None]==="FeynFacet-PartonicChannelResults"&&AssociationQ[value["Results"]],
  shown=Map[First@splitRecord[#]&,value["Results"]];
  hidden=Map[Last@splitRecord[#]&,value["Results"]];
  Return[{Join[KeyDrop[value,"Results"],<|"Results"->shown|>],
    <|"Kind"->"Channels","Children"->hidden,"KeyOrder"->Keys[value]|>}]];
 If[KeyExistsQ[value,"InputCompanions"],
  Return[{KeyDrop[value,"InputCompanions"],<|"Kind"->"WithMetadata",
    "Hidden"->KeyTake[value,{"InputCompanions"}],"KeyOrder"->Keys[value]|>}]];
 {value,<|"Kind"->"Complete"|>}
];
splitRecord[value_]:={value,<|"Kind"->"Complete"|>};
joinRecord[value_,meta_Association]:=Switch[Lookup[meta,"Kind",None],
 "Complete",value,
 "Partonic"|"WithMetadata",If[AssociationQ[value],KeyTake[Join[value,meta["Hidden"]],meta["KeyOrder"]],$Failed],
 "Channels",If[AssociationQ[value]&&AssociationQ[value["Results"]]&&
    Sort[Keys[value["Results"]]]===Sort[Keys[meta["Children"]]],
   KeyTake[Join[value,<|"Results"->Association@KeyValueMap[
    #1->joinRecord[#2,meta["Children"][#1]]&,value["Results"]]|>],meta["KeyOrder"]],$Failed],
 _,$Failed
];
symbolName[HoldComplete[s_Symbol]]:=SymbolName[Unevaluated[s]];
symbolContext[HoldComplete[s_Symbol]]:=Context[Unevaluated[s]];
(* A collision is represented by an indexed spelling, never by merging symbols. *)
symbolAliases[symbols_List]:=Module[{used=<||>,names={},name,candidate,n},
 Do[
  name=symbolName[s];candidate=name;n=1;
  While[KeyExistsQ[used,candidate]||System`Names["System`"<>candidate]=!={},
   n++;candidate=name<>ToString[n]];
  AssociateTo[used,candidate->True];AppendTo[names,candidate],
 {s,symbols}];names
];
heldRule[HoldComplete[left_],HoldComplete[right_]]:=HoldPattern[left]:>right;
heldSymbol[name_String]:=ToExpression[name,InputForm,HoldComplete];
(* Association traversal normally visits values only. Include mathematical keys. *)
recordSymbols[value_]:=Join[
 Cases[value,s_Symbol/;Context[Unevaluated[s]]=!="System`":>HoldComplete[s],
  {0,Infinity},Heads->True],
 Flatten[recordSymbols/@Cases[value,a_Association:>Keys[a],{0,Infinity},Heads->True],1]];
replaceRecordSymbols[value_,rules_]:=Module[{result=value,positions,association,mapped},
 positions=Reverse@SortBy[Position[result,_Association,{0,Infinity},Heads->True],Length];
 Do[
  association=If[position==={},result,Extract[result,position]];
  mapped=Association@KeyValueMap[Function[{key,item},replaceRecordSymbols[key,rules]->item],association];
  result=ReplacePart[result,position->mapped],
 {position,positions}];
 result/.rules
];
(* InputForm abbreviations such as I are not structurally exact under HoldComplete.
   Retain only the original held subexpressions in the binary companion. *)
recordContainsHeldQ[value_]:=
 !FreeQ[value,_HoldComplete|_Hold|_HoldForm|_HoldPattern|_Defer|_Function|HoldPattern[Inactive[SparseArray][___]]]||
 AnyTrue[Cases[value,a_Association:>Keys[a],{0,Infinity},Heads->True],recordContainsHeldQ];
heldParts[value_]:=Module[{positions,associations,outer,inside},
 positions=Position[value,_HoldComplete|_Hold|_HoldForm|_HoldPattern|_Defer|_Function|HoldPattern[Inactive[SparseArray][___]],
   {0,Infinity},Heads->True];
 inside[p_]:=AnyTrue[positions,Length[#]<=Length[p]&&Take[p,Length[#]]===#&];
 (* InputForm can merge distinct held keys, so preserve their enclosing
    association before parsing can collapse entries. Do not inspect inside
    already protected held expressions. Ordinary coefficient maps are unaffected. *)
 associations=Select[Position[value,_Association,{0,Infinity},Heads->True],!inside[#]&];
 associations=Select[associations,recordContainsHeldQ[Keys[If[#==={},value,Extract[value,#]]]]&];
 positions=Join[positions,associations];
 outer=Select[positions,Function[p,!AnyTrue[positions,Length[#]<Length[p]&&Take[p,Length[#]]===#&]]];
 (#->If[#==={},With[{whole=value},HoldComplete[whole]],Extract[value,#,HoldComplete]])&/@outer
];
(* WXF does not preserve an atomic Complex inside a held association key:
   it can deserialize as unevaluated Complex[re,im]. Mark only actual atoms,
   keeping deliberately held Complex syntax distinct. The marker is metadata only. *)
recordObjects[value_,pattern_]:=Join[
 Cases[value,pattern,{0,Infinity},Heads->True],
 Flatten[recordObjects[#,pattern]& /@ Cases[value,a_Association:>Keys[a],{0,Infinity},Heads->True],1]];
encodeHeldMetadata[parts_]:=Module[{atoms,rules},
 atoms=DeleteDuplicates@recordObjects[parts,_Complex?AtomQ];
 If[atoms==={},Return[parts]];
 rules=(#->heldComplexAtom[Re[#],Im[#]]& /@ atoms);
 replaceRecordSymbols[parts,rules]
];
decodeHeldMetadata[parts_]:=Module[{atoms,rules},
 atoms=DeleteDuplicates@recordObjects[parts,_heldComplexAtom];
 If[atoms==={},Return[parts]];
 rules=(#->Apply[Complex,List@@#]& /@ atoms);
 replaceRecordSymbols[parts,rules]
];
restoreHeldParts[value_,parts_List]:=Fold[
 Function[{result,part},If[First[part]==={},ReleaseHold[Last[part]],
   ReplacePart[result,First[part]->ReleaseHold[Last[part]]]]],value,parts];
(* SparseArray hides stored entries from ordinary expression traversal. Use
   its explicit constructor while replacing symbols, without densifying it. *)
recordExplicitArrays[value_]:=Module[{arrays,rules},
 arrays=DeleteDuplicates@recordObjects[value,_SparseArray];
 If[arrays==={},Return[value]];
 rules=(#->Inactive[SparseArray][ArrayRules[#],Dimensions[#]]&/@arrays);
 replaceRecordSymbols[value,rules]
];
recordActivateArrays[value_]:=Module[{arrays,rules},
 arrays=DeleteDuplicates@recordObjects[value,HoldPattern[Inactive[SparseArray][___]]];
 If[arrays==={},Return[value]];
 rules=(#->Activate[#]&/@arrays);
 replaceRecordSymbols[value,rules]
];
recordReplaceUnquoted[text_String,from_String,to_String]:=Module[{positions,strings,index=1,count},
 positions=StringPosition[text,from,Overlaps->False];
 If[positions==={},Return[text]];
 strings=StringPosition[text,RegularExpression["\"(?:[^\"\\\\]++|\\\\.)*+\""],Overlaps->False];
 count=Length[strings];
 positions=Select[positions,Function[position,
  While[index<=count&&strings[[index,2]]<position[[1]],index++];
  index>count||strings[[index,1]]>position[[1]]]];
 StringReplacePart[text,to,positions]
];
encode[value_]:=Module[{held=HoldComplete[value],symbols,aliases,context,locals,rules,text},
 held=recordExplicitArrays[held];
 symbols=DeleteDuplicates@recordSymbols[held];
 symbols=SortBy[symbols,{symbolName,symbolContext}];
 aliases=symbolAliases[symbols];context="FeynFacetRecordWrite"<>StringReplace[CreateUUID[],"-"->""]<>"`";
 locals=heldSymbol[context<>#]&/@aliases;
 rules=Dispatch[MapThread[heldRule,{symbols,locals}]];
 held=replaceRecordSymbols[held,rules];
 text=Block[{$Context=context,$ContextPath={"System`",context}},
   ToString[held,InputForm,PageWidth->100]];
 If[!StringStartsQ[text,"HoldComplete["]||!StringEndsQ[text,"]"],Return[$Failed]];
 text=StringTrim[StringDrop[StringDrop[text,StringLength["HoldComplete["]],-1]]<>"\n";
 text=recordReplaceUnquoted[text,"Inactive[SparseArray]","SparseArray"];
 With[{pattern=context<>"*"},Quiet[Remove[pattern],Remove::rmnsm]];
 <|"Text"->text,"Symbols"->AssociationThread[aliases,symbols]|>
];
unrestoredRecordSymbolsQ[value_,context_String]:=
 !FreeQ[value,s_Symbol/;Context[Unevaluated[s]]===context]||
 AnyTrue[Cases[value,a_Association:>Keys[a],{0,Infinity},Heads->True],
   unrestoredRecordSymbolsQ[#,context]&];
(* The writer emits bare aliases. A context qualifier outside a string
   cannot be an alias supplied by the companion. *)
recordQualifiedTextQ[text_String]:=Module[{ticks,strings,index=1,count,numbers},
 ticks=StringPosition[text,"`"];
 If[ticks==={},Return[False]];
 strings=StringPosition[text,RegularExpression["\"(?:[^\"\\\\]++|\\\\.)*+\""],Overlaps->False];
 count=Length[strings];
 (* Both lists are ordered; inspect each quoted interval at most once. *)
 ticks=Select[ticks,Function[tick,
  While[index<=count&&strings[[index,2]]<tick[[1]],index++];
  index>count||strings[[index,1]]>=tick[[1]]]];
 If[ticks==={},Return[False]];
 (* Wolfram precision/accuracy marks are numeric syntax, not context
    qualifiers. Match complete numeric tokens; a digit at the end of a
    symbol or an escaped named character must not hide a qualified name. *)
 numbers=StringPosition[text,RegularExpression[
  "(?<![\\p{L}\\p{N}$\\\\\\]])(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)`{1,2}(?:[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+))?(?:\\*\\^[+-]?[0-9]+)?(?![\\p{L}\\p{N}$`])"],
  Overlaps->False];
 index=1;count=Length[numbers];
 AnyTrue[ticks,Function[tick,
  While[index<=count&&numbers[[index,2]]<tick[[1]],index++];
  index>count||numbers[[index,1]]>tick[[1]]]]
];
decode[text_String,symbols_Association]:=Module[{context,held,locals,rules,value},
 If[recordQualifiedTextQ[text],Return[$Failed]];
 context="FeynFacetRecordRead"<>StringReplace[CreateUUID[],"-"->""]<>"`";
 held=Block[{$Context=context,$ContextPath={"System`",context}},
   Quiet[Check[ToExpression["("<>StringTrim[recordReplaceUnquoted[text,"SparseArray[","Inactive[SparseArray]["]]<>")",InputForm,HoldComplete],$Failed,{Syntax::sntx,Syntax::sntxi,Syntax::sntxf,Syntax::sntue}]]];
 If[held===$Failed,With[{pattern=context<>"*"},Quiet[Remove[pattern],Remove::rmnsm]];Return[$Failed]];
 (* Check names before traversal: an unlisted symbol could otherwise
    disappear through evaluation, or occur only inside an association key. *)
 If[!ContainsAll[(context<>#& /@ Keys[symbols]),System`Names[context<>"*"]],
   With[{pattern=context<>"*"},Quiet[Remove[pattern],Remove::rmnsm]];Return[$Failed]];
 locals=heldSymbol[context<>#]&/@Keys[symbols];
 rules=Dispatch[MapThread[heldRule,{locals,Values[symbols]}]];
 held=replaceRecordSymbols[held,rules];
 If[unrestoredRecordSymbolsQ[held,context],
  With[{pattern=context<>"*"},Quiet[Remove[pattern],Remove::rmnsm]];Return[$Failed]];
 value=recordActivateArrays[ReleaseHold[held]];With[{pattern=context<>"*"},Quiet[Remove[pattern],Remove::rmnsm]];value
];
plainRead[file_,context_]:=Module[{value},
 {value,$messages}=Block[{$Context=context,$ContextPath={"System`",context},$MessageList={}},
  Quiet[{CheckAbort[Check[Get[file],$Failed,
   {Syntax::sntx,Syntax::sntxi,Syntax::sntxb,Syntax::sntxf,Syntax::sntue,Syntax::sntunc,
    Syntax::com,Syntax::newl,Syntax::bktmcp,Syntax::bktmop,Syntax::bktwrn,Syntax::bktnps,
    Syntax::tsntxi,Syntax::snthc,Syntax::stresc}],$Aborted],$MessageList}]];
 If[value===$Aborted,$Failed,value]
];
ReadRecord[file_String,context_String:"Global`"]:=Module[{text,meta,value,stream,attempt,valid=False},
 $messages={};
 If[!StringEndsQ[context,"`"]||!FileExistsQ[file],Return[$Failed]];
 If[ToLowerCase[FileExtension[file]]==="wxf",Return[Quiet@Check[Import[file,"WXF"],$Failed]]];
 If[!FileExistsQ[metadataFile[file]],
  stream=OpenRead[file];If[Head[stream]=!=InputStream,Return[$Failed]];
  text=ReadLine[stream];Close[stream];
  If[StringQ[text]&&StringStartsQ[text,StringTrim[$header]],Return[$Failed]];
  Return[plainRead[file,context]]];
 Do[
  text=Quiet[Check[FromCharacterCode[BinaryReadList[file,"Byte"],"UTF8"],$Failed]];
  meta=Quiet[Import[metadataFile[file],"WXF"]];
  valid=StringQ[text]&&AssociationQ[meta]&&
    Lookup[meta,"Format",None]==="FeynFacet-ReadableRecordMetadata"&&
    Lookup[meta,"Version",None]===2&&StringStartsQ[text,$header]&&
    AssociationQ[Lookup[meta,"Symbols",None]]&&AssociationQ[Lookup[meta,"Record",None]]&&
    StringQ[Lookup[meta,"WriteIdentifier",None]]&&
    StringStartsQ[StringDrop[text,StringLength[$header]],writeIdentifier[meta["WriteIdentifier"]]];
  If[valid,Break[]];If[attempt<3,Pause[0.02]],
 {attempt,3}];
 If[!TrueQ[valid],Return[$Failed]];
 value=decode[StringDrop[text,StringLength[$header<>writeIdentifier[meta["WriteIdentifier"]]]],meta["Symbols"]];
 If[value===$Failed,Return[$Failed]];
 joinRecord[restoreHeldParts[value,decodeHeldMetadata[Lookup[meta,"HeldExpressions",{}]]],meta["Record"]]
];
Options[WriteRecord]={"Compression"->Automatic};
WriteRecord[value_,file_String,OptionsPattern[]]:=Module[
 {directory=DirectoryName[ExpandFileName[file]],temporary,companion,parts,encoded,text,meta,result,stream,identifier=CreateUUID[]},
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 temporary=file<>".partial-"<>CreateUUID[];
 If[ToLowerCase[FileExtension[file]]==="wxf",
  Return[Quiet@Check[
   Export[temporary,value,"WXF",PerformanceGoal->"Size"];
   RenameFile[temporary,file,OverwriteTarget->True];file,$Failed]]];
 parts=splitRecord[value];encoded=encode[First[parts]];
 If[!AssociationQ[encoded]||recordQualifiedTextQ[encoded["Text"]],Return[$Failed]];
 text=$header<>writeIdentifier[identifier]<>encoded["Text"];
 meta=<|"Format"->"FeynFacet-ReadableRecordMetadata","Version"->2,
  "WriteIdentifier"->identifier,"Symbols"->encoded["Symbols"],"HeldExpressions"->encodeHeldMetadata[heldParts[First[parts]]],"Record"->Last[parts]|>;
 companion=metadataFile[temporary];
 result=Quiet@Check[
  stream=OpenWrite[temporary,BinaryFormat->True];
  BinaryWrite[stream,ToCharacterCode[text,"UTF8"],"Byte"];Close[stream];
  Export[companion,meta,"WXF",PerformanceGoal->"Size"];
  RenameFile[companion,metadataFile[file],OverwriteTarget->True];
  RenameFile[temporary,file,OverwriteTarget->True];file,$Failed];
 If[FileExistsQ[temporary],DeleteFile[temporary]];
 If[FileExistsQ[companion],DeleteFile[companion]];
 result
];
transferRecord[source_String,target_String,move_]:=Module[{operation,result},
 If[!FileExistsQ[source],Return[$Failed]];
 If[ExpandFileName[source]===ExpandFileName[target],Return[target]];
 operation=If[TrueQ[move],RenameFile,CopyFile];
 result=Quiet@Check[
  operation[source,target,OverwriteTarget->True];
  If[FileExistsQ[metadataFile[source]],
   operation[metadataFile[source],metadataFile[target],OverwriteTarget->True],
   If[FileExistsQ[metadataFile[target]],DeleteFile[metadataFile[target]]]];
  target,$Failed];result
];
MoveRecord[source_String,target_String]:=transferRecord[source,target,True];
CopyRecord[source_String,target_String]:=transferRecord[source,target,False];
DeleteRecord[file_String]:=Quiet@Check[
 If[FileExistsQ[metadataFile[file]],DeleteFile[metadataFile[file]]];
 If[FileExistsQ[file],DeleteFile[file]];file,$Failed];
End[];EndPackage[];
