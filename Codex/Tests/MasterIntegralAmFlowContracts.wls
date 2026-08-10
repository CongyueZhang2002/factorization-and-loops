$HistoryLength = 0;

Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];

input = Get[
  "/mnt/c/Users/congyue zhang/Desktop/Mathematica/Hard Function/" <>
    "EvaluateMasters/NLO/Input.wl"
];
topology = First[Values[input["Topologies"]]];
family = topology[[1]];
master = FeynCalc`GLI[family, {1, 1, 1, 1}];
data = <|
  "Master" -> master,
  "Topology" -> topology,
  "CutIndices" -> input["CutPositions"],
  "CutDirections" -> ConstantArray[1, Length[input["CutPositions"]]],
  "Prescription" -> {0}
|>;
point = {s -> 10, t -> -3, u -> -2, Epsilon -> -1/10};

AMFlow`SetAMFOptions[___] := Null;
AMFlow`SetReductionOptions[___] := Null;
AMFlow`SetReducerOptions[___] := Null;
AMFlow`WithGlobalVariables[expression_] := expression;
AMFlow`SolveIntegrals[___] := $Failed;
directoriesBefore = FileNames[
  "FeynFacetMasterIntegral-*",
  $TemporaryDirectory
];
failedSolve = Quiet @ FeynFacet`MasterIntegralAmFlow[
  data,
  point,
  "TimeConstraint" -> 1
];
directoriesAfter = FileNames[
  "FeynFacetMasterIntegral-*",
  $TemporaryDirectory
];
createdDirectories = Complement[directoriesAfter, directoriesBefore];

checks = <|
  "NonAssociationRejected" -> SameQ[
    Quiet[FeynFacet`MasterIntegralAmFlow[42, point]],
    $Failed
  ],
  "MissingTopologyRejected" -> SameQ[
    Quiet[FeynFacet`MasterIntegralAmFlow[<|"Master" -> master|>, point]],
    $Failed
  ],
  "InvalidKinematicsRejected" -> SameQ[
    Quiet[FeynFacet`MasterIntegralAmFlow[data, 42]],
    $Failed
  ],
  "WrongFamilyRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        Append[data, "Master" -> FeynCalc`GLI[otherFamily, {1, 1, 1, 1}]],
        point
      ]
    ],
    $Failed
  ],
  "RemovedCutRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        Append[data, "Master" -> FeynCalc`GLI[family, {0, 1, 1, 1}]],
        point
      ]
    ],
    $Failed
  ],
  "NegativePrecisionRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        data,
        point,
        "PrecisionGoal" -> 0
      ]
    ],
    $Failed
  ],
  "InvalidAMFlowPathRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        data,
        point,
        "AMFlowPath" -> 42
      ]
    ],
    $Failed
  ],
  "InvalidWorkingDirectoryRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        data,
        point,
        "WorkingDirectory" -> 42
      ]
    ],
    $Failed
  ],
  "InvalidKeepDirectoryRejected" -> SameQ[
    Quiet[
      FeynFacet`MasterIntegralAmFlow[
        data,
        point,
        "KeepWorkingDirectory" -> "yes"
      ]
    ],
    $Failed
  ],
  "FailedSolveRejected" -> SameQ[failedSolve, $Failed],
  "FailedSolveDirectoryRemoved" -> createdDirectories === {}
|>;

Print[checks];
Scan[
  If[DirectoryQ[#], DeleteDirectory[#, DeleteContents -> True]] &,
  createdDirectories
];
If[! And @@ Values[checks], Exit[1]];
Exit[0];
