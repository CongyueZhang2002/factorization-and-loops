root = DirectoryName[$InputFileName];
family = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "CF27"];

record = Get[FileNameJoin[{root, "ObservableTransport_" <> family <> ".wl"}]];
kernel = Get[FileNameJoin[{root, "PreTransportValuationKernel_" <> family <> ".wl"}]];

variables = record["Variables"];
firstVariable = variables[[1]];
pathParameter = record["Path", "Parameter"];
path = record["Path", "Base"][[1]] +
  pathParameter (firstVariable - record["Path", "Base"][[1]]);
poleChecks = Map[
  Function[item,
    letter = record["DLogLetters"][[item["Letter"]]];
    kernelValue = Together[D[
      Log[letter /. firstVariable -> path], pathParameter]];
    poleValue = Total[(#[[2]]/(pathParameter - #[[1]])) & /@ item["Poles"]];
    Together[kernelValue - poleValue] === 0
  ],
  record["PathPoleExpansion"]
];

Print[<|
  "Association" -> AssociationQ[record],
  "Family" -> record["Family"],
  "MaximumWeight" -> record["MaximumWeight"],
  "WordCount" -> Length[record["ObservableWordMaps"]],
  "WordsByWeight" -> Counts[record["ObservableWordMaps"][[All, "Weight"]]],
  "GPLWordCount" -> Length[record["GPLWordMaps"]],
  "GPLWordsByWeight" -> Counts[record["GPLWordMaps"][[All, "Weight"]]],
  "PathPoleCertificate" -> And @@ poleChecks,
  "KernelCertificate" ->
    Union[Flatten[Together[kernel["ConstraintMatrix"].kernel["Kernel"]]]] === {0}
|>];
