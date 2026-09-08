$RecursionLimit = 4096;
root = DirectoryName[$InputFileName];
Get[FileNameJoin[{root, "ObservableTransportConsumer.wl"}]];
record = Get[FileNameJoin[{root, "ObservableTransport_CF27.wl"}]];
kernel = Get[FileNameJoin[{root, "PreTransportValuationKernel_CF27.wl"}]];
old = Get[
  "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/" <>
  "UU_08_10_canonical/Masters/CF27.wl"];

zeroWords = {
  TransportWord[{}, _] :> 1,
  TransportWord[_List, _] :> 0
};
baseValue[order_, row_] :=
  Together[old["F"][order][[row]] /. tau -> 0 /. zeroWords];

kernelVariables =
  BoundaryCoordinate["Kernel", #] & /@ Range[kernel["Nullity"]];
lowBoundaryValues = baseValue @@@ kernel["BoundarySlots"];
kernelRules = First @ Solve[
  Thread[kernel["Kernel"].kernelVariables == lowBoundaryValues],
  kernelVariables];

slotRules = Cases[
  record["BoundaryCoordinates"],
  coordinate : BoundaryCoordinate["Slot", {order_, row_}] :>
    (coordinate -> baseValue[order, row])
];
boundaryRules = Join[kernelRules, slotRules];

variables = record["Variables"];
firstVariable = variables[[1]];
secondVariable = variables[[2]];
base = record["Path", "Base"][[1]];
path = base + tau (firstVariable - base);
activeLetters = record["PathActiveLetters"];
rootValues = Table[
  polynomial = Numerator[
    Together[record["DLogLetters"][[index]] /. firstVariable -> path]];
  Together[-Coefficient[polynomial, tau, 0]/
    Coefficient[polynomial, tau, 1]],
  {index, activeLetters}
];
roots = AssociationThread[activeLetters, rootValues];

nRows = Length[record["PhysicalRows"]];
nColumns = Length[record["BoundaryCoordinates"]];
observable = ConstantArray[0, nRows];
Do[
  matrix = SparseArray[
    (#[[1 ;; 2]] -> #[[3]]) & /@ map["Entries"],
    {nRows, nColumns}
  ];
  word = map["Word"];
  wordValue = If[word === {}, 1, TransportWord[Lookup[roots, word], 1]];
  observable += matrix.record["BoundaryCoordinates"] wordValue,
  {map, record["ObservableWordMaps"]}
];
observable = Together /@ (observable /. boundaryRules);

observableGPL = ConstantArray[0, nRows];
Do[
  matrix = SparseArray[
    (#[[1 ;; 2]] -> #[[3]]) & /@ map["Entries"],
    {nRows, nColumns}
  ];
  word = map["Word"];
  wordValue = If[word === {}, 1, TransportWord[word, 1]];
  observableGPL += matrix.record["BoundaryCoordinates"] wordValue,
  {map, record["GPLWordMaps"]}
];
observableGPL = Together /@ (observableGPL /. boundaryRules);

stored = Flatten[old["I", "I"][[1 ;; 3, {1, 2}]]] /. tau -> 1;
storedRoots = DeleteDuplicates @ Cases[stored,
  TransportWord[word_List, _] :> Sequence @@ word, Infinity];
generatedRoots = DeleteDuplicates @ Flatten[
  record["GPLWordMaps"][[All, "Word"]]];
rootRules = Map[
  Function[root,
    root -> SelectFirst[storedRoots, Together[# - root] === 0 &, root]],
  generatedRoots
];
observableGPL = observableGPL /.
  TransportWord[word_List, endpoint_] :>
    TransportWord[word /. rootRules, endpoint];
residual = MapThread[Together[#1 - #2] &, {observable, stored}];
gplResidual = MapThread[Together[#1 - #2] &, {observableGPL, stored}];
consumer = ObservableTransportResult[record, boundaryRules];
consumer = consumer /.
  TransportWord[word_List, endpoint_] :>
    TransportWord[word /. rootRules, endpoint];
consumerResidual = MapThread[
  Together[#1 - #2] &,
  {Lookup[consumer, record["PhysicalRows"]], stored}
];

Print[<|
  "PathRootsAgree" ->
    Sort[Values[roots]] ===
      Sort[DeleteDuplicates @ Cases[stored,
        TransportWord[word_List, _] :> Sequence @@ word, Infinity]],
  "IndependentBoundaryCoordinates" -> Length[record["BoundaryCoordinates"]],
  "ObservableComponents" -> Length[observable],
  "ExactStoredResultAgreement" -> Union[residual] === {0},
  "NonzeroResiduals" -> Count[residual, value_ /; value =!= 0],
  "ExactGPLStoredResultAgreement" -> Union[gplResidual] === {0},
  "NonzeroGPLResiduals" -> Count[gplResidual, value_ /; value =!= 0],
  "ConsumerStoredResultAgreement" -> Union[consumerResidual] === {0}
|>];
