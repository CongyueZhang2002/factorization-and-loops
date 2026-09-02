(* FeynFacet/Private/Core/Artifacts/Artifacts.wl -- split out of Core/Base/Core.wl in round 5
   (2026-09-02, substructure ruling): the context-guarded artifact reader/writer
   FamilyArtifactRead/Write (from EpsForm in round 4) and the length-prefixed
   binary record I/O coefficient*Record (from Reduction in round 4).
   Verbatim moves of whole top-level statements; loads after Base/Core.wl
   (Private/LoadOrder.wl), inside the FeynFacet`Private` context. *)

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

(* Context-guarded artifact reader. After CANONICA is on the context
   path, a bare Get parses eps/x/y into CANONICA` and every later
   symbolic comparison silently fails (measured 2026-08-20: in one
   kernel the first family certified and every later one failed its
   gauge identity). All campaign and worker reads of .wl artifacts go
   through this function.

   FamilyArtifactRead[file] keeps the historical default context exactly:
   the file is parsed with $Context = "Global`" and
   $ContextPath = {"System`", "Global`"}.  FamilyArtifactRead[file,
   context] parses it into an explicit context instead, so a caller can
   isolate an artifact's symbols from Global` (the pattern of
   MultiquadraticStripSolve.wl's hydration).

   Failure discrimination, rebased 2026-08-23 (port-agent defect J).
   The old body was Quiet[Check[Get[file], $Failed]], which treats ANY
   message as a read failure and therefore threw away a perfectly valid
   artifact whose evaluation emitted a benign message.  Measured on
   14.2.1, the three failure modes are distinct:
     - a missing or unopenable file: Get returns $Failed;
     - an aborted read: CheckAbort returns $Aborted (the old body let the
       abort propagate into the caller);
     - a syntax-corrupt file (truncated Association, stray bracket,
       binary garbage): Get returns Null, NOT $Failed, and the parser
       messages (Syntax::sntue, Syntax::com, Syntax::sntx) are NOT
       recorded in $MessageList -- the old body typed those failures only
       as a side effect of Check firing on every message.  They are
       therefore named explicitly below, so a corrupt artifact still
       fails typed while a benign message no longer discards a good one.
   $MessageList collects the benign messages of the last read into
   $familyArtifactReadMessages; that variable is a diagnostic, not part
   of the contract.  An empty file still reads as Null, exactly as
   before. *)
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
FamilyArtifactWrite[value_, file_String] := Module[{directory, temporary},
  directory = DirectoryName[ExpandFileName[file]];
  If[directory =!= "" && ! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  Put[value, temporary];
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
    If[! IntegerQ[length] || length < 0,
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
