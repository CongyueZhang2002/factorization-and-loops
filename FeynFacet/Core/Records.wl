(* Shared record I/O and length-prefixed binary coefficient records. *)
Begin["FeynFacet`Private`"];
Clear[FamilyArtifactRead,FamilyArtifactWrite,FamilyArtifactMove,FamilyArtifactCopy,FamilyArtifactDelete];
$familyArtifactReadMessages={};
FamilyArtifactRead[file_String,context_String:"Global`"]:=Module[{value},
 value=FeynFacetRecords`ReadRecord[file,context];
 $familyArtifactReadMessages=FeynFacetRecords`Private`$messages;value];
Options[FamilyArtifactWrite]={"Compression"->Automatic};
FamilyArtifactWrite[value_,file_String,OptionsPattern[]]:=
 FeynFacetRecords`WriteRecord[value,file,"Compression"->OptionValue["Compression"]];
FamilyArtifactMove[source_String,target_String]:=FeynFacetRecords`MoveRecord[source,target];
FamilyArtifactCopy[source_String,target_String]:=FeynFacetRecords`CopyRecord[source,target];
FamilyArtifactDelete[file_String]:=FeynFacetRecords`DeleteRecord[file];

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
