ClearAll[ObservableTransportResult];

ObservableTransportResult[
    record_Association,
    boundaryRules_List : {}
  ] := Module[
  {coordinates, labels, rows, columns, result, matrix, word, wordValue},

  coordinates = record["BoundaryCoordinates"];
  labels = record["PhysicalRows"];
  rows = Length[labels];
  columns = Length[coordinates];
  result = ConstantArray[0, rows];

  Do[
    matrix = SparseArray[
      (#[[1 ;; 2]] -> #[[3]]) & /@ item["Entries"],
      {rows, columns}
    ];
    word = item["Word"];
    wordValue = If[word === {}, 1, TransportWord[word, 1]];
    result += matrix.coordinates wordValue,
    {item, record["GPLWordMaps"]}
  ];

  AssociationThread[
    labels,
    result /. boundaryRules
  ]
];
