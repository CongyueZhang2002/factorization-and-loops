(* Bounded exact simplification of rational summands before interpolation.
   No coefficient, epsilon order or integral definition is changed. *)
BeginPackage["FeynFacet`"];
Begin["`Private`"];

$finiteFieldCompactionSource = $InputFileName;
$finiteFieldSummandSplitter = FileNameJoin[{
  DirectoryName[$InputFileName, 3], "Backends", "rational_summands.py"}];

finiteFieldCompactTerm[text_String, names_List, seconds_?NumericQ] := Module[
 {identifiers, value, result, compact},
 identifiers = DeleteDuplicates[StringCases[text,
   RegularExpression["[A-Za-z][A-Za-z0-9]*"]]];
 If[!StringMatchQ[text, RegularExpression["[A-Za-z0-9+*/^()\\-\\s]+"]] ||
    !SubsetQ[names, identifiers],
   Return[Failure["InvalidRationalSummand", <||>]]];
 result = TimeConstrained[
   Block[{$Context = "FeynFacetCompaction`", $ContextPath = {"System`"}},
     value = Quiet[Check[ToExpression[text, InputForm], $Failed]];
     If[value === $Failed || !finiteFieldParseRational[value, names],
       Failure["InvalidRationalSummand", <||>],
       compact = Quiet[Check[Together[value], $Failed]];
       If[compact === $Failed || !finiteFieldParseRational[compact, names],
         Failure["InvalidRationalCompaction", <||>],
         StringReplace[ToString[compact, InputForm, PageWidth -> Infinity], WhitespaceCharacter .. -> ""]
       ]
     ]
   ], Max[seconds, 0.001], $TimedOut];
 Which[
   result === $TimedOut, <|"Text" -> text, "TimedOut" -> True|>,
   FailureQ[result], result,
   !StringQ[result], Failure["InvalidRationalCompaction", <||>],
   True, <|"Text" -> If[StringLength[result] < StringLength[text], result, text],
     "TimedOut" -> False|>
 ]
];

finiteFieldCompactColumn[file_String, destination_String, names_List,
    workers_Integer, entrySeconds_, columnSeconds_] := Module[
 {lines = destination <> ".terms", temporary = destination <> ".partial",
  input = None, output = None, split, chunk, reduced, remaining, elapsed,
  count = 0, timeouts = 0, kept = 0, first = True, start, result, write,
  resultFile = destination},
 write[text_String] := If[text =!= "0",
   WriteString[output, If[first, "", "+"], "(", text, ")"]; first = False];
 start = AbsoluteTime[];
 result = Internal`WithLocalSettings[Null,
   Catch[
     split = Quiet[Check[RunProcess[{"python3", $finiteFieldSummandSplitter,
       file, lines}], $Failed]];
     If[!AssociationQ[split] || split["ExitCode"] =!= 0,
       Throw[Failure["SummandSplitting", <|"File" -> file|>]]];
     input = OpenRead[lines]; output = OpenWrite[temporary];
     If[Head[input] =!= InputStream || Head[output] =!= OutputStream,
       Throw[Failure["CompactionStreams", <|"File" -> file|>]]];
     While[(chunk = ReadList[input, String, 1024]) =!= {},
       remaining = columnSeconds - (AbsoluteTime[] - start);
       reduced = If[remaining <= 0,
         (<|"Text" -> #, "TimedOut" -> False|> & /@ chunk),
         With[{variables = names, limit = Min[entrySeconds, remaining]},
           If[workers > 1,
             ParallelMap[finiteFieldCompactTerm[#, variables, limit] &, chunk,
               Method -> ("ItemsPerEvaluation" -> 8), DistributedContexts -> None],
             finiteFieldCompactTerm[#, variables, limit] & /@ chunk
           ]
         ]
       ];
       If[!AllTrue[reduced, AssociationQ],
         Throw[Failure["SummandCompaction", <|"File" -> file,
           "Failures" -> Select[reduced, !AssociationQ[#] &]|>]]];
       count += Length[chunk];
       timeouts += Count[Lookup[reduced, "TimedOut"], True];
       kept += Count[MapThread[SameQ, {Lookup[reduced, "Text"], chunk}], True];
       Scan[write, Lookup[reduced, "Text"]];
     ];
     If[first, WriteString[output, "0"]];
     WriteString[output, "\n"]; Close[output]; output = None;
     Close[input]; input = None;
     If[FileByteCount[temporary] < FileByteCount[file],
       RenameFile[temporary, destination, OverwriteTarget -> True],
       DeleteFile[temporary]; resultFile = file
     ];
     <|"Source" -> file, "Output" -> resultFile,
       "InputBytes" -> FileByteCount[file], "OutputBytes" -> FileByteCount[resultFile],
       "Terms" -> count, "UnchangedTerms" -> kept, "TimedOutTerms" -> timeouts,
       "Seconds" -> AbsoluteTime[] - start|>
   ],
   If[Head[input] === InputStream, Quiet[Close[input]]];
   If[Head[output] === OutputStream, Quiet[Close[output]]];
   Scan[If[FileExistsQ[#], DeleteFile[#]] &, {lines, temporary}]
 ];
 result
];

(* Derived files have their own manifest and native-trace directory. Reuse is
   bound to the exact output definitions, aliases, source bytes and options. *)
finiteFieldCompactTrace[traceData_Association, directory_String,
    kernels_, threshold_Integer, entrySeconds_, columnSeconds_] := Module[
 {files, selected, names, binding, manifest, saved, hashes, launched = {},
  existing, workers, records = {}, record, derived, outputFiles, result,
  options, target, initialized},
 files = traceData["OutputFiles"];
 If[!AllTrue[files, FileExistsQ] || threshold < 0 ||
    !TrueQ[entrySeconds > 0 && columnSeconds > 0], Return[$Failed]];
 selected = Select[Range[Length[files]], FileByteCount[files[[#]]] >= threshold &];
 If[selected === {}, Return[traceData]];
 names = SymbolName /@ Values[traceData["SymbolRules"]];
 options = <|"ThresholdBytes" -> threshold, "EntrySeconds" -> entrySeconds,
   "ColumnSeconds" -> columnSeconds|>;
 binding = <|"Version" -> 1, "Options" -> options,
   "TraceData" -> KeyDrop[traceData, "Compaction"],
   "InputHashes" -> coefficientFileHashes[files]|>;
 target = FileNameJoin[{directory, "Compacted"}];
 If[!DirectoryQ[target], CreateDirectory[target]];
 manifest = FileNameJoin[{target, "Compaction.wl"}];
 saved = If[FileExistsQ[manifest],
   Quiet[Check[FeynFacet`FamilyArtifactRead[manifest], $Failed]], $Failed];
 If[AssociationQ[saved] && Lookup[saved, "Binding", None] === binding &&
    Length[Lookup[saved, "OutputFiles", {}]] === Length[files] &&
    AllTrue[Lookup[saved, "OutputFiles", {}], FileExistsQ] &&
    Lookup[saved, "OutputHashes", None] ===
      coefficientFileHashes[saved["OutputFiles"]],
   Print["Reusing exact rational summand compaction"];
   Return[Join[traceData, <|"OutputFiles" -> saved["OutputFiles"],
     "ExpressionBytes" -> (FileByteCount /@ saved["OutputFiles"]),
     "Compaction" -> KeyDrop[saved, {"Binding", "OutputHashes"}]|>]]
 ];
 workers = finiteFieldNormalizationKernelCount[kernels, 64];
 If[workers === $Failed, Return[$Failed]];
 result = Internal`WithLocalSettings[Null,
   Catch[
     If[workers > 1,
       existing = Kernels[];
       If[Length[existing] < workers,
         launched = facetLaunchKernels[workers - Length[existing]]];
       If[Length[Kernels[]] > workers,
         Throw[Failure["CompactionWorkerBudget", <|"Requested" -> workers,
           "Existing" -> Length[Kernels[]]|>]]];
       If[Kernels[] === {}, workers = 1,
         workers = Length[Kernels[]];
         With[{source = $finiteFieldCompactionSource},
           initialized = And @@ ParallelEvaluate[
             SetSystemOptions["ParallelOptions" -> {"ParallelThreadNumber" -> 1,
               "MKLThreadNumber" -> 1}];
             Get[source]; Length[DownValues[finiteFieldCompactTerm]] > 0, Kernels[]]];
         If[!TrueQ[initialized], Throw[$Failed]];
         DistributeDefinitions[finiteFieldParseRational]
       ]
     ];
     outputFiles = files;
     Do[
       Print["Compacting rational output ", index, " (",
         Round[FileByteCount[files[[index]]]/2.^20, 0.1], " MiB)"];
       record = finiteFieldCompactColumn[files[[index]],
         FileNameJoin[{target, FileNameTake[files[[index]]]}],
         names, workers, entrySeconds, columnSeconds];
       If[!AssociationQ[record], Throw[record]];
       outputFiles[[index]] = record["Output"];
       AppendTo[records, Append[record, "OutputIndex" -> index]];
       Print["  ", Round[record["Seconds"], 0.1], " s; ",
         Round[record["OutputBytes"]/2.^20, 0.1], " MiB"],
       {index, selected}];
     saved = <|"Binding" -> binding, "Directory" -> target,
       "OutputFiles" -> outputFiles, "Columns" -> records,
       "OutputHashes" -> coefficientFileHashes[outputFiles]|>;
     If[FeynFacet`FamilyArtifactWrite[saved, manifest, "Compression" -> True] === $Failed ||
        FeynFacet`FamilyArtifactRead[manifest] =!= saved, Throw[$Failed]];
     Join[traceData, <|"OutputFiles" -> outputFiles,
       "ExpressionBytes" -> (FileByteCount /@ outputFiles),
       "Compaction" -> KeyDrop[saved, {"Binding", "OutputHashes"}]|>]
   ],
   If[launched =!= {}, Quiet[CloseKernels[launched]]]
 ];
 result
];

End[];
EndPackage[];
