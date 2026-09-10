(* Context-guarded Wolfram records, atomic writes, and length-prefixed
   binary coefficient records. *)

Begin["FeynFacet`Private`"];

(* public symbols: Clear, not ClearAll (FeynFacet.m defines their usage
   messages before this file loads) *)
Clear[FamilyArtifactRead, FamilyArtifactWrite];
ClearAll[
  $familyArtifactReadMessages,
  coefficientAppendRecord,
  coefficientWriteRecord,
  coefficientScanRecords,
  coefficientReadRecord
];

(* Parse unqualified symbols in the requested context, independent of
   optional packages on the caller's context path. Qualified names remain unchanged. New records qualify symbols, including shadowable System names, so that both guarded reads and ordinary Get preserve identities.
   Syntax errors and aborted reads fail; benign evaluation messages are
   retained separately and do not discard an otherwise valid record. *)
$familyArtifactReadMessages = {};

FamilyArtifactRead[file_String] := FamilyArtifactRead[file, "Global`"];

FamilyArtifactRead[file_String, context_String] := Module[{value, messages},
  If[! StringEndsQ[context, "`"], Return[$Failed]];
  If[! FileExistsQ[file], Return[$Failed]];
  {value, messages} = Block[
    {$Context = context, $ContextPath = {"System`", context},
     $MessageList = {}},
    Quiet[{
      CheckAbort[
        Check[Get[file], $Failed,
          {Syntax::sntx, Syntax::sntxi, Syntax::sntxb, Syntax::sntxf,
           Syntax::sntue, Syntax::sntunc, Syntax::com, Syntax::newl,
           Syntax::bktmcp, Syntax::bktmop, Syntax::bktwrn, Syntax::bktnps,
           Syntax::tsntxi, Syntax::snthc, Syntax::stresc}],
        $Aborted],
      $MessageList}]];
  $familyArtifactReadMessages = messages;
  If[value === $Aborted, $Failed, value]];

(* Atomic artifact writer: Put to a temporary name, then RenameFile. *)
Options[FamilyArtifactWrite]={"Compression"->False};
FamilyArtifactWrite[value_, file_String,OptionsPattern[]] := Module[{directory, temporary,stream},
  directory = DirectoryName[ExpandFileName[file]];
  If[directory =!= "" && ! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  If[TrueQ[OptionValue["Compression"]]||(OptionValue["Compression"]===Automatic&&ByteCount[value]>8*1024^2),
    stream=OpenWrite[temporary];
    WriteString[stream,"Uncompress[",ToString[Block[{$Context="FeynFacetSerialization`",$ContextPath={}},Compress[value]],InputForm],"]\n"];Close[stream],
    (* Both package names and System names shadowed by packages must
       retain their explicit contexts in small uncompressed records. *)
    Block[{$Context="FeynFacetSerialization`",$ContextPath={}},Put[value, temporary]]];
  RenameFile[temporary, file, OverwriteTarget -> True];
  file
];


coefficientAppendRecord[file_String, expression_] := Module[
  {stream, bytes, values},
  bytes = BinarySerialize[expression];
  values = Normal[bytes];
  stream = OpenAppend[file, BinaryFormat -> True];
  If[Head[stream] =!= OutputStream, Return[$Failed]];
  BinaryWrite[stream, Length[values], "UnsignedInteger64"];
  BinaryWrite[stream, values, "Byte"];
  Close[stream];
  file
];

coefficientWriteRecord[file_String, expression_] := Module[{},
  If[FileExistsQ[file], DeleteFile[file]];
  coefficientAppendRecord[file, expression]
];

coefficientScanRecords[file_String, function_] := Module[
  {stream, length, bytes, count = 0, value, result = True},
  If[! FileExistsQ[file], Return[0]];
  stream = OpenRead[file, BinaryFormat -> True];
  If[Head[stream] =!= InputStream, Return[$Failed]];
  While[True,
    length = BinaryRead[stream, "UnsignedInteger64"];
    If[length === EndOfFile, Break[]];
    If[! IntegerQ[length] || length < 0 || length > FileByteCount[file]-StreamPosition[stream],
      result = $Failed;
      Break[]
    ];
    bytes = BinaryReadList[stream, "Byte", length];
    If[Length[bytes] =!= length,
      result = $Failed;
      Break[]
    ];
    value = Quiet @ Check[BinaryDeserialize[ByteArray[bytes]], $Failed];
    If[value === $Failed,
      result = $Failed;
      Break[]
    ];
    If[function[value] === $Failed,
      result = $Failed;
      Break[]
    ];
    count++
  ];
  Close[stream];
  If[result === $Failed, $Failed, count]
];

coefficientReadRecord[file_String] := Module[{values = {}, count},
  count = coefficientScanRecords[file, AppendTo[values, #] &];
  If[count === $Failed || count =!= 1, $Failed, First[values]]
];

End[];
