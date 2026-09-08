root = DirectoryName[$InputFileName];
family = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "CF299"];

Get[FileNameJoin[{root, "ObservableTransportConsumer.wl"}]];
record = Get[FileNameJoin[{root, "ObservableTransport_" <> family <> ".wl"}]];

{seconds, result} = AbsoluteTiming[ObservableTransportResult[record]];
Print[<|
  "Family" -> family,
  "Components" -> Length[result],
  "DistinctGPLWords" -> Length @ DeleteDuplicates @
    Cases[result, TransportWord[word_List, _] :> word, Infinity],
  "Bytes" -> ByteCount[result],
  "Seconds" -> seconds
|>];
