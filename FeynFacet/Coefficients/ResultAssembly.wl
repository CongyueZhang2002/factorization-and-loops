finiteFieldAssembleResult[
    data_Association,
    metadata_Association,
    kiraFile_String,
    context_Association,
    traceData_Association,
    trace_Association,
    reconstruction_Association,
    executable_String,
    threads_Integer
  ] := Module[
  {
    outputs, grouped, directRules, coefficients, remainder,
    recordsByName, equivalence, classByName, masterData,
    reconstructed, forbiddenMomenta, remainingMomenta,
    remainingFractionObjects, cutCheck,
    reconstructionData, certifiedColumn, rootSubstitutions, supportContext
  },
  supportContext=Join[context,<|"ExternalDistribution"->data["PhaseSpace"]|>];
  outputs = MapThread[
    Join[#1, <|"RationalExpression" -> #2|>] &,
    {
      traceData["OutputMetadata"],
      reconstruction["Expressions"]
    }
  ];
  grouped = GroupBy[outputs, #1["MasterIndex"] &];
  directRules = Normal[context["DimensionlessCoordinates"]];
  (* The trace is emitted in physical variables, so a reconstructed
     coefficient carrying a root variable is a regression of the
     descend, not a parity accident.  The check stays where it is
     cheap: on the small reconstructed output, never on trace inputs. *)
  certifiedColumn[entries_List] := finiteFieldCertifyPhysicalVariables[
    Total[
      Function[entry,
        ReleaseHold[
          traceData["Signatures"][entry["SignatureIndex"]]
        ] entry["RationalExpression"]
      ] /@ entries
    ],
    supportContext
  ];
  coefficients = AssociationMap[
    Function[index, certifiedColumn[Lookup[grouped, index, {}]]],
    Range[Length[traceData["Masters"]]]
  ];
  remainder = certifiedColumn[Lookup[grouped, 0, {}]];
  If[MemberQ[Values[coefficients], $Failed] || remainder === $Failed,
    Return[$Failed]
  ];
  coefficients = (# /. directRules) & /@ coefficients;
  remainder = remainder /. directRules;
  recordsByName = Association[
    #1["Topology"][[1]] -> #1 & /@ metadata["Topologies"]
  ];
  equivalence = metadata["TopologyEquivalence"];
  classByName = If[
    AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
    Association[#1["Representative"] -> #1 & /@ equivalence["Classes"]],
    <||>
  ];
  masterData = DeleteCases[
    MapIndexed[
      Function[{master, position},
        Module[{coefficient, record},
          coefficient = coefficients[First[position]];
          record = recordsByName[master[[1]]];
          <|
            "Master" -> master,
            "PreFactor" -> 1,
            "Coefficient" -> coefficient,
            "TopologyName" -> master[[1]],
            "CutMomenta" -> record["CutMomenta"],
            "CutIndices" -> record["CutIndices"],
            "CutDirections" -> record["CutDirections"],
            "TopologyClass" -> Lookup[
              classByName,
              master[[1]],
              Missing["NotFound"]
            ]
          |>
        ]
      ],
      traceData["Masters"]
    ],
    Nothing
  ];
  reconstructed = traceData["PhysicalFactor"] (
    Total[#1["Coefficient"] #1["Master"] & /@ masterData] + remainder
  );
  forbiddenMomenta = coefficientForbiddenMomenta[data["Setup"]];
  remainingMomenta = remainingDeclaredMomenta[
    {Lookup[masterData, "Coefficient"], remainder},
    forbiddenMomenta
  ];
  rootSubstitutions = Lookup[context, "RootSubstitutions", <||>];
  remainingFractionObjects = Select[
    Join[
      context["FractionVariables"],
      context["FractionRootVariables"],
      If[
        AssociationQ[rootSubstitutions],
        #["Root"] & /@ Values[rootSubstitutions],
        {}
      ]
    ],
    ! FreeQ[{Lookup[masterData, "Coefficient"], remainder}, #] &
  ];
  If[
    remainingMomenta =!= {} || remainingFractionObjects =!= {} ||
      ! FreeQ[reconstructed, System`D],
    Return[$Failed]
  ];
  cutCheck = validateCutGLIs[
    Lookup[masterData, "Master"],
    metadata["Topologies"]
  ];
  If[cutCheck =!= True, Return[$Failed]];
  reconstructionData = <|
    "Format" -> $finiteFieldReconstructionFormat,
    "FormatVersion" -> $finiteFieldReconstructionVersion,
    "Method" -> "SharedMultiOutputTrace",
    "CompleteTargetSet" -> traceData["CompleteTargetSet"],
    "ProcessedTargetCount" -> traceData["ProcessedTargetCount"],
    "TargetCount" -> traceData["TargetCount"],
    "OutputCount" -> Length[traceData["OutputOrder"]],
    "SignatureCount" -> Length[traceData["Signatures"]],
    "RationalVariableCount" -> Length[traceData["Variables"]],
    "TraceBytes" -> trace["TraceBytes"],
    "ReconstructedBytes" -> reconstruction["ResultBytes"],
    "TraceBuildSeconds" -> trace["BuildSeconds"],
    "ReconstructionSeconds" -> reconstruction["ReconstructionSeconds"],
    "Threads" -> threads,
    "RatracerExecutable" -> executable,
    "RatracerExecutableHash" -> FileHash[
      executable,
      "SHA256",
      "HexString"
    ],
    "TraceFile" -> trace["TraceFile"],
    "TraceFileHash" -> FileHash[
      trace["TraceFile"],
      "SHA256",
      "HexString"
    ],
    "ResultFile" -> reconstruction["ResultFile"],
    "ResultFileHash" -> FileHash[
      reconstruction["ResultFile"],
      "SHA256",
      "HexString"
    ]
  |>;
  Join[
    <||>,
    resultContext[data],
    <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> traceData["PhysicalFactor"],
      "Remainder" -> remainder,
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "HadronicNormalization" -> <|
        "PreFactor" -> traceData["PhysicalFactor"],
        "DistributionFactor" -> context["ExpectedDistributionFactor"],
        "LaurentValuation" -> context["ExpectedLaurentValuation"],
        "DimensionlessCoordinates" -> context["DimensionlessCoordinates"],
        "CoordinateRestriction" -> <|"Equalities"->Lookup[context,"CoordinateEqualities",{}],
          "ExternalDistribution"->data["PhaseSpace"],"NormalDerivativeDataAvailable"->False|>,
        "BranchGrammar" -> context["BranchGrammar"],
        (* Provenance of the root treatment.  The root variables are no
           longer a representation of the result - they are the
           transient lift of the entrywise descend, and what the result
           records is which of them were eliminated, with the exact
           relation used, plus the descend telemetry. *)
        "RootDescend" -> <|
          "EliminatedRoots" -> If[
            AssociationQ[rootSubstitutions],
            Association @ KeyValueMap[
              Function[{quantity, substitutionData},
                quantity ->
                  substitutionData["Constant"] substitutionData["Root"]^2
              ],
              rootSubstitutions
            ],
            <||>
          ],
          "TraceVariables" -> traceData["Variables"],
          "ScalePowers" -> Lookup[traceData, "ScalePowers", {}],
          "Statistics" -> Lookup[traceData, "DescendStatistics", <||>]
        |>
      |>,
      "FiniteFieldReconstruction" -> reconstructionData,
      "Topologies" -> metadata["Topologies"],
      "KiraArtifact" -> ExpandFileName[kiraFile],
      "ReverseRules" -> metadata["ReverseRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> metadata["MassDimensions"],
      "KiraManifest" -> metadata["KiraManifest"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> metadata["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> metadata["SourceInputFingerprint"]
    |>
  ]
];

