(* Exact observable-only transport for two-variable epsilon-form families. *)

ClearAll[
  observableTransportCancel,
  observableTransportCancelMatrix,
  observableTransportZeroQ,
  observableTransportZeroMatrixQ,
  observableTransportMatrixNonzeroQ,
  observableTransportSlotKey,
  observableTransportEpsilonOrder,
  observableTransportLaurentMatrices,
  observableTransportIndependentRows,
  observableTransportRowBasis,
  observableTransportColumnBasis,
  observableTransportExactColumnBasis,
  observableTransportExactRowBasis,
  observableTransportReachabilityCertificate,
  observableTransportDualObservableCertificate,
  observableTransportKernel,
  observableTransportInvariantEmbedding,
  observableTransportResidues,
  observableTransportEntryKernels,
  observableTransportRecordRegularQ,
  observableTransportLiftResidues,
  observableTransportWordMaps,
  observableTransportSuffixVisibility,
  observableTransportBackwardWordMaps,
  observableTransportQuotientWordMaps,
  observableTransportKernelDecomposition,
  observableTransportSecondSegmentMaps,
  observableTransportFamilyName,
  observableTransportIntegralIndices,
  observableTransportNonsingularQ,
  observableTransportFamilyFromFile,
  observableTransportWriteAtomic,
  observableTransportSourceFrameQ,
  observableTransportRecordChart,
  observableTransportBlockLowerQ,
  BuildObservableTransportManifest,
  FindObservableTransportPath,
  BuildObservableTransportDemand,
  BuildObservableTransport
];

observableTransportCancel[x_] := Quiet[Cancel[Together[x]]];

(* Keep structural zeros structural.  The lifted epsilon-order operators are
   sparse by construction; unconditionally applying Normal here used to turn
   every exact cancellation into a dense state-space matrix. *)
observableTransportCancelMatrix[m_SparseArray] :=
  Map[observableTransportCancel, m, {2}];

observableTransportCancelMatrix[m_] :=
  Map[observableTransportCancel, Normal[m], {2}];

observableTransportZeroQ[x_] :=
  TrueQ[masterTransportZeroQ[x]];

observableTransportZeroMatrixQ[m_SparseArray] :=
  AllTrue[Last /@ Most[ArrayRules[m]], observableTransportZeroQ];

observableTransportZeroMatrixQ[m_] :=
  AllTrue[Flatten[{Normal[m]}], observableTransportZeroQ];

(* A nonzero exact value at any nonsingular rational sample proves that the
   symbolic matrix is nonzero.  Only the ambiguous/all-zero sample case falls
   back to the full exact identity test.  This is a one-sided accelerator,
   never a probabilistic zero decision. *)
observableTransportMatrixNonzeroQ[m_, sampleRules_List] := Module[
  {samples, evaluated, values},
  samples = If[MatchQ[sampleRules, {_Rule ..}],
    {sampleRules}, sampleRules];
  If[! ListQ[samples] || samples === {}, samples = {{}}];
  Do[
    evaluated = Quiet[Check[Normal[m] /. rules, $Failed]];
    If[evaluated =!= $Failed &&
        FreeQ[evaluated,
          Indeterminate | ComplexInfinity | DirectedInfinity[_]],
      values = Flatten[{evaluated}];
      If[AnyTrue[values,
          NumberQ[#] && TrueQ[# != 0] &], Return[True]]
    ],
    {rules, samples}
  ];
  ! observableTransportZeroMatrixQ[m]
];

observableTransportSourceFrameQ[value_] := Module[
  {name = ToLowerCase@StringReplace[ToString[value, InputForm],
      Except[LetterCharacter | DigitCharacter] -> ""]},
  MemberQ[{"sourcevw", "sourcevwx", "sourcevwy", "source"}, name]
];

observableTransportRecordChart[record_Association, Automatic] := Module[
  {chartRecord = Lookup[record, "ChartRecord", Missing["NotAvailable"]],
   chart = Lookup[record, "Chart", None],
   frame = Lookup[record, "Frame", None]},
  Which[
    AssociationQ[chartRecord], chartRecord,
    observableTransportSourceFrameQ[frame] ||
      observableTransportSourceFrameQ[chart], None,
    chart === None || MissingQ[chart], None,
    StringQ[chart], Lookup[TransportChartCatalog[], chart, $Failed],
    AssociationQ[chart], chart,
    True, $Failed
  ]
];

observableTransportRecordChart[record_Association, chart_] := chart;

observableTransportBlockLowerQ[matrices : {_, _}, ranges_List] := Module[
  {n = Length[First[matrices]]},
  If[! AllTrue[ranges, VectorQ[#, IntegerQ] &] ||
      Sort[Flatten[ranges]] =!= Range[n], Return[False]];
  AllTrue[
    Flatten[Table[
      If[i < j,
        {matrices[[1, ranges[[i]], ranges[[j]]]],
         matrices[[2, ranges[[i]], ranges[[j]]]]},
        {}],
      {i, Length[ranges]}, {j, Length[ranges]}]],
    observableTransportZeroMatrixQ
  ]
];

(* CertifyFamilyEpsilonForm and ExactFamilyEpsilonFormQ moved to
   FamilyEpsForm.wl on 2026-08-20. *)

observableTransportFamilyFromFile[file_String] := Module[{name, match},
  name = FileBaseName[file];
  match = StringCases[name,
    StartOfString ~~ "family_epsform_" ~~
      family : ("CF" ~~ DigitCharacter ..) ~~ EndOfString :> family];
  If[Length[match] === 1, First[match], Missing["NoFamily"]]
];

observableTransportWriteAtomic[value_, file_String, format_: Automatic] :=
 Module[{directory, temporary},
  directory = DirectoryName[ExpandFileName[file]];
  If[! DirectoryQ[directory],
    CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  temporary = FileNameJoin[{directory,
    "." <> FileNameTake[file] <> ".tmp-" <> ToString[$ProcessID]}];
  If[format === Automatic, Put[value, temporary],
    Export[temporary, value, format]];
  RenameFile[temporary, file, OverwriteTarget -> True];
  file
];

Options[BuildObservableTransportManifest] = {
  "Card" -> None,
  "ReportFile" -> Automatic
};

BuildObservableTransportManifest[
    epsilonFormDirectories : {__String},
    differentialSystemDirectory_String, valuationsFile_String,
    manifestFile_String, OptionsPattern[]] := Module[
  {directories, differentialFiles, familyFromDifferential, candidates,
   candidateRows, grouped, selected = <||>, rejected = <||>,
   duplicates = <||>, missing, family, records, exactRecords,
   card, reportFile, rows, report},
  directories = ExpandFileName /@ epsilonFormDirectories;
  If[! AllTrue[directories, DirectoryQ] ||
      ! DirectoryQ[differentialSystemDirectory] ||
      ! FileExistsQ[valuationsFile],
    Return[<|"Status" -> "InputPathMissing"|>]];
  differentialFiles = SortBy[
    FileNames["nnlo_de_CF*.wl", differentialSystemDirectory],
    FileBaseName];
  familyFromDifferential[file_] := Module[{match},
    match = StringCases[FileBaseName[file],
      StartOfString ~~ "nnlo_de_" ~~
        value : ("CF" ~~ DigitCharacter ..) ~~ EndOfString :> value];
    If[Length[match] === 1, First[match], Missing["NoFamily"]]
  ];
  differentialFiles = Association @ Cases[differentialFiles,
    file_ :> With[{name = familyFromDifferential[file]},
      If[MissingQ[name], Nothing, name -> ExpandFileName[file]]]];
  candidates = Flatten[Table[
    Thread[{priority,
      FileNames["family_epsform_CF*.wl", directories[[priority]],
        Infinity]}],
    {priority, Length[directories]}], 1];
  candidateRows = Cases[candidates, {priority_Integer, file_String} :>
    Module[{name, record},
      name = observableTransportFamilyFromFile[file];
      If[MissingQ[name] || ! KeyExistsQ[differentialFiles, name],
        Nothing,
        record = Quiet[Check[Get[file], $Failed]];
        <|"Family" -> name, "Priority" -> priority,
          "File" -> ExpandFileName[file],
          "Exact" -> ExactFamilyEpsilonFormQ[record]|>]
    ]];
  grouped = GroupBy[candidateRows, #Family &];
  Do[
    records = SortBy[Lookup[grouped, family, {}],
      {#Priority &, #File &}];
    exactRecords = Select[records, TrueQ[#Exact] &];
    If[exactRecords === {},
      If[records =!= {}, AssociateTo[rejected, family -> records]],
      AssociateTo[selected, family -> First[exactRecords]];
      If[Length[exactRecords] > 1,
        AssociateTo[duplicates, family -> Rest[exactRecords]]]],
    {family, Keys[differentialFiles]}];
  missing = Select[Keys[differentialFiles], ! KeyExistsQ[selected, #] &];
  card = OptionValue["Card"];
  If[card =!= None && (! StringQ[card] || ! FileExistsQ[card]),
    Return[<|"Status" -> "TransportCardMissing", "Card" -> card|>]];
  rows = Prepend[
    Table[{family, selected[family]["File"],
      differentialFiles[family], ExpandFileName[valuationsFile],
      If[card === None, "", ExpandFileName[card]]},
      {family, SortBy[Keys[selected],
        ToExpression[StringDrop[#, 2]] &]}],
    {"family", "epsilon_form", "differential_system", "valuations",
      "card"}];
  observableTransportWriteAtomic[rows, manifestFile, "TSV"];
  report = <|
    "Status" -> If[missing === {}, "CompleteExactInventory",
      "IncompleteExactInventory"],
    "DifferentialFamilyCount" -> Length[differentialFiles],
    "ExactFamilyCount" -> Length[selected],
    "MissingFamilies" -> SortBy[missing,
      ToExpression[StringDrop[#, 2]] &],
    "Selected" -> selected,
    "RejectedCandidates" -> rejected,
    "AdditionalExactCandidates" -> duplicates,
    "Manifest" -> ExpandFileName[manifestFile]
  |>;
  reportFile = Replace[OptionValue["ReportFile"],
    Automatic :> FileNameJoin[{DirectoryName[ExpandFileName[manifestFile]],
      "transport_inventory.wl"}]];
  If[reportFile =!= None,
    observableTransportWriteAtomic[report, reportFile]];
  report
];

observableTransportFamilyName[integral_] := Module[{arguments, family},
  arguments = Quiet[Check[List @@ integral, {}]];
  If[Length[arguments] < 1, Return[Missing["NoFamily"], Module]];
  family = First[arguments];
  Which[
    StringQ[family], family,
    Head[family] === Symbol, SymbolName[family],
    True, Missing["NoFamily"]
  ]
];

observableTransportIntegralIndices[integral_] := Module[{arguments},
  arguments = Quiet[Check[List @@ integral, {}]];
  If[Length[arguments] >= 2 && ListQ[arguments[[2]]],
    arguments[[2]], Missing["NoIndices"]]
];

observableTransportNonsingularQ[expressions_List, rules_List] :=
  AllTrue[expressions, Function[expression,
    Module[{value = Quiet[Check[Together[expression /. rules], $Failed]]},
      value =!= $Failed &&
        FreeQ[value,
          Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
        ! TrueQ[Numerator[value] === 0] &&
        ! TrueQ[Denominator[value] === 0]
    ]
  ]];

observableTransportRecordRegularQ[record_Association, rules_List] :=
  AllTrue[
    DeleteCases[Flatten[{
      Lookup[record, "TTotal", {}],
      Lookup[record, "TTotalInverse", {}],
      Lookup[record, "EpsFormX", {}],
      Lookup[record, "EpsFormY", {}]
    }], 0],
    Function[expression,
      Module[{value = Quiet[Check[Together[expression /. rules], $Failed]]},
        value =!= $Failed &&
          FreeQ[value,
            Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
          ! TrueQ[Denominator[value] === 0]
      ]
    ]
  ];

Options[FindObservableTransportPath] = {
  "Candidates" -> Automatic
};

FindObservableTransportPath[record_Association, OptionsPattern[]] := Module[
  {variables, letters, coefficientField, fractions, candidates, selected,
   admissibleQ},
  variables = Lookup[record, "Variables", Missing[]];
  letters = Lookup[record, "Letters", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! ListQ[letters],
    Return[<|"Status" -> "PathInputNotWellFormed"|>]
  ];
  fractions = {1/4, 1/3, 1/5, 2/7, 3/8, 2/5, 3/7, 3/11,
    4/11, 5/13};
  candidates = Replace[OptionValue["Candidates"], Automatic ->
    Select[Tuples[fractions, 3], #[[1]] =!= #[[3]] &]];
  If[! MatchQ[candidates, {{_, _, _} ..}],
    Return[<|"Status" -> "InvalidPathCandidates"|>]
  ];
  coefficientField = Lookup[Lookup[record, "ChartRecord", <||>],
    "CoefficientField", "Rational"];
  admissibleQ = If[coefficientField === "Multiquadratic",
    Function[point,
      observableTransportRecordRegularQ[record,
        Thread[variables -> point]]],
    Function[point,
      observableTransportNonsingularQ[letters,
        Thread[variables -> point]]]
  ];
  selected = SelectFirst[candidates,
    admissibleQ[#[[1 ;; 2]]] &&
      admissibleQ[{#[[3]], #[[2]]}] &,
    Missing["NoNonsingularPath"]];
  If[MissingQ[selected],
    <|"Status" -> "NoNonsingularRationalPath"|>,
    <|
      "Status" -> "ExactPathData",
      "FirstVariable" -> variables[[1]],
      "SecondVariable" -> variables[[2]],
      "FirstBase" -> selected[[1]],
      "SecondBase" -> selected[[2]],
      "FirstTargetSample" -> selected[[3]],
      "BranchStatement" ->
        "The exact transport map is retained in the polynomial dlog " <>
        "alphabet. Physical analytic continuation is fixed separately."
    |>
  ]
];

Options[BuildObservableTransportDemand] = {
  "HardFunctionOrders" -> {0},
  "SafetyOrders" -> 1,
  "MasterValuation" -> 0,
  "Path" -> Automatic
};

BuildObservableTransportDemand[record_Association,
    familySystem_Association, valuations_List, OptionsPattern[]] := Module[
  {family, basis, permutation, hardOrders, safety, masterValuation,
   path, familyValuations, rows = {}, missing = {}, pairs, originalRow,
   recordRow, maximumOrder},

  family = Lookup[record, "Family", Missing["NoFamily"]];
  basis = Lookup[familySystem, "BlockBasis", Missing["NoBasis"]];
  permutation = Flatten[Lookup[record, "Blocks", Missing["NoBlocks"]]];
  hardOrders = Sort@DeleteDuplicates@Flatten@{
    OptionValue["HardFunctionOrders"]};
  safety = OptionValue["SafetyOrders"];
  masterValuation = OptionValue["MasterValuation"];
  path = OptionValue["Path"];
  If[! StringQ[family] || ! ListQ[basis] ||
      ! VectorQ[permutation, IntegerQ] ||
      ! VectorQ[hardOrders, IntegerQ] || hardOrders === {} ||
      ! IntegerQ[safety] || safety < 0 || ! IntegerQ[masterValuation],
    Return[<|"Status" -> "InvalidObservableDemandInput"|>]
  ];

  familyValuations = Select[valuations,
    AssociationQ[#] && Lookup[#, "Family", None] === family &&
      ListQ[Lookup[#, "Indices", None]] &&
      IntegerQ[Lookup[#, "Valuation", None]] &];
  Do[
      originalRow = FirstPosition[basis,
        integral_ /;
          observableTransportFamilyName[integral] === family &&
          observableTransportIntegralIndices[integral] ===
            item["Indices"],
        Missing["NotInFamilyBasis"], {1}];
      If[MissingQ[originalRow],
        AppendTo[missing, <|"Valuation" -> item,
          "Reason" -> "MasterNotInFamilyBasis"|>],
        originalRow = First[originalRow];
        recordRow = FirstPosition[permutation, originalRow,
          Missing["NotInRecordPermutation"], {1}];
        If[MissingQ[recordRow],
          AppendTo[missing,
            <|"Valuation" -> item, "OriginalRow" -> originalRow,
              "Reason" -> "MasterNotInRecordPermutation"|>],
          maximumOrder = Max[hardOrders] - item["Valuation"] + safety;
          If[maximumOrder >= masterValuation,
            AppendTo[rows, <|"Valuation" -> item["Valuation"],
              "OriginalRow" -> originalRow,
              "RecordRow" -> First[recordRow],
              "Orders" -> Range[masterValuation, maximumOrder]|>]
        ]
      ]
    ],
      {item, familyValuations}];
  If[missing =!= {},
    Return[<|"Status" -> "ObservableDemandMappingFailed",
      "Family" -> family, "Missing" -> missing|>]
  ];
  If[rows === {},
    Return[<|"Status" -> "NoNonzeroMasterCoefficientDemand",
      "Family" -> family|>]
  ];
  pairs = Sort@DeleteDuplicates@Flatten[
    Table[{order, row["RecordRow"]}, {row, rows},
      {order, row["Orders"]}], 1];
  <|
    "Status" -> "ExactObservableDemand",
    "Family" -> family,
    "PhysicalDemandPairs" -> pairs,
    "PhysicalValuation" -> masterValuation,
    "HardFunctionOrders" -> hardOrders,
    "SafetyOrders" -> safety,
    "MasterRows" -> rows,
    "Path" -> path
  |>
];

observableTransportSlotKey[{order_, component_}] :=
  ToString[Unevaluated[{order, component}], InputForm];

observableTransportEpsilonOrder[0, _] := Infinity;
observableTransportEpsilonOrder[x_, eps_] :=
  masterTransportEpsOrder[observableTransportCancel[x], eps];

observableTransportLaurentMatrices[m_, eps_, {low_Integer, high_Integer}] :=
  Association@Table[
    order -> Map[
      observableTransportCancel[SeriesCoefficient[#, {eps, 0, order}]] &,
      Normal[m], {2}],
    {order, low, high}
  ];

observableTransportIndependentRows[m_, rules_List] := Module[
  {evaluated, reduced, pivots},
  If[Length[m] === 0, Return[{}]];
  evaluated = Normal[m] /. rules;
  If[! FreeQ[evaluated,
      Indeterminate | ComplexInfinity | DirectedInfinity[_]],
    Return[$Failed]
  ];
  reduced = RowReduce[Transpose[evaluated]];
  pivots = DeleteMissing[
    (Replace[
       FirstPosition[#, x_ /; ! TrueQ[x === 0],
         Missing["ZeroRow"], {1}, Heads -> False],
       {position_Integer} :> position
     ] &) /@ reduced
  ];
  DeleteDuplicates[pivots]
];

observableTransportRowBasis[m_, rules_List] := Module[{rows},
  rows = observableTransportIndependentRows[m, rules];
  If[rows === $Failed, Return[$Failed]];
  If[rows === {}, ConstantArray[0, {0, If[MatrixQ[m], Dimensions[m][[2]], 0]}],
    m[[rows]]]
];

observableTransportColumnBasis[m_, rules_List] := Module[{basis},
  basis = observableTransportRowBasis[Transpose[m], rules];
  If[basis === $Failed, $Failed, Transpose[basis]]
];

(* Select a column basis at inexpensive rational samples, then certify over
   the exact coefficient field that it spans every original column.  A bad
   sample can only trigger the exact RowReduce fallback; it can never remove
   a direction from the certified reachable space. *)
observableTransportExactColumnBasis[m_, sampleRules_List] := Module[
  {dimensions, rows, columns, samples, candidates, selected, verify,
   verified, exactPivots},

  dimensions = Dimensions[m];
  If[Length[dimensions] =!= 2,
    Return[<|"Status" -> "ReachableMatrixNotRectangular"|>]
  ];
  {rows, columns} = dimensions;
  If[columns === 0,
    Return[<|"Status" -> "Exact", "Basis" -> SparseArray[{}, {rows, 0}],
      "Rank" -> 0, "Pivots" -> {}, "SpanIdentity" -> True,
      "Coordinates" -> SparseArray[{}, {0, 0}],
      "Method" -> "Empty"|>]
  ];

  samples = If[MatchQ[sampleRules, {_Rule ..}],
    {sampleRules}, sampleRules];
  If[! ListQ[samples] || samples === {}, samples = {{}}];
  candidates = DeleteCases[
    MapIndexed[
      With[{pivots = observableTransportIndependentRows[
            Transpose[m], #1]},
        If[pivots === $Failed, Nothing,
          <|"Pivots" -> pivots, "Rules" -> #1,
            "Sample" -> First[#2]|>]
      ] &,
      samples],
    Nothing
  ];

  verify[pivots_List, rules_List, method_String] := Module[
    {basis, rank, pivotRows, coordinates, residual, nonbasisColumns,
     nonpivotRows, solvedCoordinates},
    rank = Length[pivots];
    basis = If[rank === 0, SparseArray[{}, {rows, 0}], m[[All, pivots]]];
    If[rank === 0,
      Return[If[observableTransportZeroMatrixQ[m],
        <|"Status" -> "Exact", "Basis" -> basis, "Rank" -> 0,
          "Pivots" -> {}, "SpanIdentity" -> True,
          "Coordinates" -> SparseArray[{}, {0, columns}],
          "Method" -> method|>,
        <|"Status" -> "ReachableBasisSpanIdentityFailed",
          "Method" -> method|>]]
    ];
    pivotRows = observableTransportIndependentRows[basis, rules];
    If[pivotRows === $Failed || Length[pivotRows] =!= rank,
      Return[<|"Status" -> "ReachableBasisRankFailed",
        "Rank" -> rank, "PivotRows" -> pivotRows,
        "Method" -> method|>]
    ];
    (* Basis columns span themselves exactly, and the selected pivot rows of
       every other column are satisfied exactly by LinearSolve.  Certifying
       only the complementary rows and columns proves the same full identity
       without constructing a usually enormous all-row residual. *)
    nonbasisColumns = Complement[Range[columns], pivots];
    coordinates = ConstantArray[0, {rank, columns}];
    coordinates[[All, pivots]] = IdentityMatrix[rank];
    If[nonbasisColumns =!= {},
      solvedCoordinates = observableTransportCancelMatrix[
        LinearSolve[basis[[pivotRows]],
          m[[pivotRows, nonbasisColumns]]]];
      coordinates[[All, nonbasisColumns]] = solvedCoordinates
    ];
    nonpivotRows = Complement[Range[rows], pivotRows];
    residual = If[nonbasisColumns === {} || nonpivotRows === {}, 0,
      observableTransportCancelMatrix[
        basis[[nonpivotRows]] . coordinates[[All, nonbasisColumns]] -
          m[[nonpivotRows, nonbasisColumns]]]];
    If[! observableTransportZeroMatrixQ[residual],
      Return[<|"Status" -> "ReachableBasisSpanIdentityFailed",
        "Rank" -> rank, "Method" -> method|>]
    ];
    <|"Status" -> "Exact", "Basis" -> basis, "Rank" -> rank,
      "Pivots" -> pivots, "SpanIdentity" -> True,
      "Coordinates" -> coordinates,
      "Method" -> method|>
  ];

  If[candidates =!= {},
    selected = First@MaximalBy[candidates, Length[#["Pivots"]] &];
    verified = verify[selected["Pivots"], selected["Rules"],
      "SampleSelectedExactSpan"];
    If[Lookup[verified, "Status", None] === "Exact", Return[verified]]
  ];

  exactPivots = observableTransportIndependentRows[Transpose[m], {}];
  If[exactPivots === $Failed,
    Return[<|"Status" -> "ExactReachableBasisConstructionFailed"|>]
  ];
  verify[exactPivots, {}, "ExactRowReduceFallback"]
];

(* Exact row analogue of observableTransportExactColumnBasis.  Applying the
   certified column factorization to Transpose[m] gives

       m == Coordinates . Basis

   over the exact coefficient field. *)
observableTransportExactRowBasis[m_, sampleRules_List] := Module[
  {columnRecord},
  columnRecord = observableTransportExactColumnBasis[
    Transpose[m], sampleRules];
  If[Lookup[columnRecord, "Status", None] =!= "Exact",
    Return[columnRecord]
  ];
  <|
    "Status" -> "Exact",
    "Basis" -> Transpose[columnRecord["Basis"]],
    "Rank" -> columnRecord["Rank"],
    "Pivots" -> columnRecord["Pivots"],
    "SpanIdentity" -> TrueQ[columnRecord["SpanIdentity"]],
    "Coordinates" -> Transpose[columnRecord["Coordinates"]],
    "Method" -> columnRecord["Method"]
  |>
];

(* Demand-dual compact automaton.  O_t is an exact row basis of

       span{P.R_word : |word|=t}.

   Exact transitions O_t.R_a == C_(a,t).O_(t+1) allow one requested word to
   be reconstructed as

       A_0.C_(a1,0)...C_(aw,w-1).(O_w.N).

   Only the current O_t is retained during construction.  In particular,
   no forward reachable space span{R_word.N}, fundamental matrix, or word
   inventory is built. *)
observableTransportDualObservableCertificate[residues_List, demanded_,
    boundary_, maximumWeight_Integer, sampleRules_List,
    verbose_: False] := Module[
  {basisRecord, observableRows, initialCoordinates, transitions,
   transitionMatrices, terminalContractions, terminal, terminalZero,
   terminalEntries, ranks, spanIdentities, methods, products, candidates,
   coordinates, currentRank, stateDimension, boundaryDimension,
   remainingWeights, zeroRows, zeroTerminal, zeroTransitions,
   nonzeroWeights, observableMaximum},

  stateDimension = Dimensions[boundary][[1]];
  boundaryDimension = Dimensions[boundary][[2]];
  basisRecord = observableTransportExactRowBasis[demanded, sampleRules];
  If[Lookup[basisRecord, "Status", None] =!= "Exact",
    Return[basisRecord]
  ];
  observableRows = basisRecord["Basis"];
  initialCoordinates = basisRecord["Coordinates"];
  transitions = {};
  terminalContractions = {};
  terminalZero = {};
  terminalEntries = {};
  ranks = {};
  spanIdentities = {TrueQ[basisRecord["SpanIdentity"]]};
  methods = {basisRecord["Method"]};

  Do[
    currentRank = Dimensions[observableRows][[1]];
    AppendTo[ranks, currentRank];
    If[TrueQ[verbose], Print[
      "CODEX_DUAL weight=", weight,
      " phase=terminal-start rank=", currentRank,
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    terminal = observableTransportCancelMatrix[observableRows . boundary];
    AppendTo[terminalContractions, terminal];
    AppendTo[terminalZero, observableTransportZeroMatrixQ[terminal]];
    AppendTo[terminalEntries,
      Count[Flatten[terminal],
        value_ /; ! observableTransportZeroQ[value]]];
    If[TrueQ[verbose], Print[
      "CODEX_DUAL weight=", weight,
      " phase=terminal-done zero=", Last[terminalZero],
      " nonzero_entries=", Last[terminalEntries],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];

    If[currentRank === 0 && weight < maximumWeight,
      remainingWeights = maximumWeight - weight;
      ranks = Join[ranks, ConstantArray[0, remainingWeights]];
      terminalZero = Join[terminalZero,
        ConstantArray[True, remainingWeights]];
      terminalEntries = Join[terminalEntries,
        ConstantArray[0, remainingWeights]];
      spanIdentities = Join[spanIdentities,
        ConstantArray[True, remainingWeights]];
      methods = Join[methods,
        ConstantArray["ZeroObservableSpace", remainingWeights]];
      zeroRows = SparseArray[{}, {0, stateDimension}];
      zeroTerminal = SparseArray[{}, {0, boundaryDimension}];
      terminalContractions = Join[terminalContractions,
        ConstantArray[zeroTerminal, remainingWeights]];
      zeroTransitions = Table[SparseArray[{}, {0, 0}],
        {Length[residues]}];
      transitions = Join[transitions,
        ConstantArray[zeroTransitions, remainingWeights]];
      observableRows = zeroRows;
      Break[]
    ];

    If[weight < maximumWeight,
      If[TrueQ[verbose], Print[
        "CODEX_DUAL weight=", weight,
        " phase=products-start alphabet=", Length[residues]]];
      products = observableTransportCancelMatrix[
          observableRows . #] & /@ residues;
      candidates = If[products === {},
        SparseArray[{}, {0, stateDimension}], Join @@ products];
      If[TrueQ[verbose], Print[
        "CODEX_DUAL weight=", weight,
        " phase=basis-start candidate_dimensions=", Dimensions[candidates],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]];
      basisRecord = observableTransportExactRowBasis[
        candidates, sampleRules];
      If[Lookup[basisRecord, "Status", None] =!= "Exact",
        Return[Join[<|"Weight" -> weight + 1|>, basisRecord]]
      ];
      coordinates = basisRecord["Coordinates"];
      transitionMatrices = Table[
        coordinates[[(a - 1) currentRank + Range[currentRank], All]],
        {a, Length[residues]}];
      AppendTo[transitions, transitionMatrices];
      observableRows = basisRecord["Basis"];
      AppendTo[spanIdentities, TrueQ[basisRecord["SpanIdentity"]]];
      AppendTo[methods, basisRecord["Method"]];
      If[TrueQ[verbose], Print[
        "CODEX_DUAL weight=", weight,
        " phase=basis-done next_rank=", basisRecord["Rank"],
        " method=", basisRecord["Method"],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]]
    ],
    {weight, 0, maximumWeight}
  ];

  nonzeroWeights = Flatten@Position[terminalZero, False] - 1;
  observableMaximum = If[nonzeroWeights === {}, -1, Max[nonzeroWeights]];

  <|
    "Status" -> "Exact",
    "AutomatonOrientation" -> "DualObservableRows",
    "RequestedMaximumWeight" -> maximumWeight,
    "ObservableMaximumWeight" -> observableMaximum,
    "ObservableRankByExactWeight" -> ranks,
    "DemandedMapIsZero" -> terminalZero,
    "DemandedNonzeroEntries" -> terminalEntries,
    "SpanIdentities" -> spanIdentities,
    "BasisMethods" -> methods,
    "InitialCoordinates" -> initialCoordinates,
    "ObservableTransitionsByWeight" -> transitions,
    "TerminalContractionsByExactWeight" -> terminalContractions,
    "TransitionIdentities" -> True,
    "NextWeightStateIsZero" -> Missing["TerminalProbeNotRequested"],
    "Field" -> "ExactRationalFunctionField",
    "CutoffIdentity" -> And @@ spanIdentities
  |>
];

(* At exact weight w, Q_w spans every R_word.N with |word|=w.  Therefore
   P.Q_w==0 proves that every demanded word map at that weight is zero.
   Computing these small spaces before enumerating words gives the exact
   observable cutoff and avoids constructing the enormous invisible tail. *)
observableTransportReachabilityCertificate[residues_List, boundary_,
    demanded_, maximumWeight_Integer, sampleRules_List] := Module[
  {basisRecord, reachable, products, candidates, projected, zero,
   ranks, demandedZero, demandedEntries, spanIdentities, methods,
   nonzeroWeights, observableMaximum, nextStateZero,
   stateDimension, remainingWeights, reachableBases, zeroBasis,
   boundaryCoordinates, transitions, transitionMatrices, zeroTransitions,
   coordinates, currentRank},

  stateDimension = Dimensions[boundary][[1]];
  basisRecord = observableTransportExactColumnBasis[boundary, sampleRules];
  If[Lookup[basisRecord, "Status", None] =!= "Exact", Return[basisRecord]];
  reachable = basisRecord["Basis"];
  reachableBases = {reachable};
  boundaryCoordinates = basisRecord["Coordinates"];
  transitions = {};
  ranks = {};
  demandedZero = {};
  demandedEntries = {};
  spanIdentities = {TrueQ[basisRecord["SpanIdentity"]]};
  methods = {basisRecord["Method"]};

  Do[
    AppendTo[ranks, Dimensions[reachable][[2]]];
    projected = observableTransportCancelMatrix[demanded . reachable];
    zero = observableTransportZeroMatrixQ[projected];
    AppendTo[demandedZero, zero];
    AppendTo[demandedEntries,
      If[zero, 0,
        Count[Flatten[projected],
          value_ /; ! observableTransportZeroQ[value]]]];

    (* Once the exact reachable space is zero, every later exact-weight
       space is zero as well.  Pad the certificate without asking symbolic
       array constructors to preserve a zero-column matrix shape. *)
    If[Dimensions[reachable][[2]] === 0 && weight < maximumWeight,
      remainingWeights = maximumWeight - weight;
      ranks = Join[ranks, ConstantArray[0, remainingWeights]];
      demandedZero = Join[demandedZero,
        ConstantArray[True, remainingWeights]];
      demandedEntries = Join[demandedEntries,
        ConstantArray[0, remainingWeights]];
      spanIdentities = Join[spanIdentities,
        ConstantArray[True, remainingWeights]];
      methods = Join[methods,
        ConstantArray["ZeroReachableSpace", remainingWeights]];
      zeroBasis = SparseArray[{}, {stateDimension, 0}];
      reachableBases = Join[reachableBases,
        ConstantArray[zeroBasis, remainingWeights]];
      zeroTransitions = Table[SparseArray[{}, {0, 0}],
        {Length[residues]}];
      transitions = Join[transitions,
        ConstantArray[zeroTransitions, remainingWeights]];
      Break[]
    ];

    If[weight < maximumWeight,
      currentRank = Dimensions[reachable][[2]];
      products = observableTransportCancelMatrix[# . reachable] & /@
        residues;
      candidates = If[products === {},
        SparseArray[{}, {stateDimension, 0}], ArrayFlatten[{products}]];
      basisRecord = observableTransportExactColumnBasis[
        candidates, sampleRules];
      If[Lookup[basisRecord, "Status", None] =!= "Exact",
        Return[Join[<|"Weight" -> weight + 1|>, basisRecord]]
      ];
      coordinates = basisRecord["Coordinates"];
      transitionMatrices = Table[
        coordinates[[All,
          (a - 1) currentRank + Range[currentRank]]],
        {a, Length[residues]}];
      AppendTo[transitions, transitionMatrices];
      reachable = basisRecord["Basis"];
      AppendTo[reachableBases, reachable];
      AppendTo[spanIdentities, TrueQ[basisRecord["SpanIdentity"]]];
      AppendTo[methods, basisRecord["Method"]]
    ],
    {weight, 0, maximumWeight}
  ];

  nonzeroWeights = Flatten@Position[demandedZero, False] - 1;
  observableMaximum = If[nonzeroWeights === {}, -1, Max[nonzeroWeights]];
  (* No weight-(maximumWeight+1) product is part of the requested transport.
     Constructing it can dominate large families and was only telemetry. *)
  nextStateZero = Missing["TerminalProbeNotRequested"];

  <|
    "Status" -> "Exact",
    "RequestedMaximumWeight" -> maximumWeight,
    "ObservableMaximumWeight" -> observableMaximum,
    "ReachableRankByExactWeight" -> ranks,
    "DemandedMapIsZero" -> demandedZero,
    "DemandedNonzeroEntries" -> demandedEntries,
    "SpanIdentities" -> spanIdentities,
    "BasisMethods" -> methods,
    "ReachableBases" -> reachableBases,
    "BoundaryCoordinates" -> boundaryCoordinates,
    "ReachableTransitionsByWeight" -> transitions,
    "TransitionIdentities" -> True,
    "NextWeightStateIsZero" -> nextStateZero,
    "Field" -> "ExactRationalFunctionField",
    "CutoffIdentity" -> And @@ spanIdentities
  |>
];

(* Discover a rational-function kernel from cheap exact rational samples.
   Sample pivots are only a proposal: the returned basis is accepted solely
   after the full symbolic identity m.kernel == 0.  For rank r and nullity k
   this solves one r-by-r system with k right-hand sides, instead of asking
   generic NullSpace to row-reduce the full symbolic matrix. *)
observableTransportKernel[m_, sampleRules_: None,
    verbose_: False] := Module[
  {dimension, vectors, samples, rowPivots, rank, pivotColumns,
   freeColumns, square, rhs, solved, kernel, residual,
   sampled, sampleVectors, sampleKernel, probeSamples, probeZero,
   certifiedKernel = Missing["NotCertified"]},

  dimension = If[MatrixQ[m], Dimensions[m][[2]], 0];
  If[Length[m] === 0, Return[IdentityMatrix[dimension]]];
  If[sampleRules =!= None,
    samples = If[MatchQ[sampleRules, {_Rule ..}],
      {sampleRules}, sampleRules];
    If[! ListQ[samples], samples = {}];

    (* Many Laurent-regularity kernels are constant even when the constraint
       matrix has high-degree multivariate entries.  Detect that case from an
       exact rational point, reject it cheaply at the remaining points, and
       accept it only after the full symbolic identity. *)
    Do[
      sampled = Quiet[Check[Normal[m] /. rules, $Failed]];
      If[sampled === $Failed ||
          ! AllTrue[Flatten[sampled], NumberQ] ||
          ! FreeQ[sampled,
            Indeterminate | ComplexInfinity | DirectedInfinity[_]],
        Continue[]
      ];
      sampleVectors = Quiet[Check[NullSpace[sampled], $Failed]];
      If[sampleVectors === $Failed, Continue[]];
      sampleKernel = If[sampleVectors === {},
        SparseArray[{}, {dimension, 0}], Transpose[sampleVectors]];
      probeSamples = DeleteCases[samples, rules, {1}, 1];
      probeZero = AllTrue[probeSamples,
        Function[probeRules,
          sampled = Quiet[Check[Normal[m] /. probeRules, $Failed]];
          sampled =!= $Failed &&
            AllTrue[Flatten[sampled], NumberQ] &&
            FreeQ[sampled,
              Indeterminate | ComplexInfinity | DirectedInfinity[_]] &&
            AllTrue[Flatten[sampled . sampleKernel], TrueQ[# === 0] &]
        ]
      ];
      If[! probeZero, Continue[]];
      residual = observableTransportCancelMatrix[m . sampleKernel];
      If[observableTransportZeroMatrixQ[residual],
        If[TrueQ[verbose], Print[
          "CODEX_KERNEL phase=certified method=constant-sample-exact",
          " rank=", dimension - Dimensions[sampleKernel][[2]],
          " nullity=", Dimensions[sampleKernel][[2]],
          " memory_bytes=", MemoryInUse[],
          " max_memory_bytes=", MaxMemoryUsed[]]];
        certifiedKernel = sampleKernel;
        Break[]
      ],
      {rules, samples}];
    If[! MissingQ[certifiedKernel], Return[certifiedKernel]];

    Do[
      rowPivots = observableTransportIndependentRows[m, rules];
      If[rowPivots === $Failed, Continue[]];
      rank = Length[rowPivots];
      If[TrueQ[verbose], Print[
        "CODEX_KERNEL phase=sample-rank rank=", rank,
        " dimensions=", Dimensions[m],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]];

      If[rank === 0,
        If[observableTransportZeroMatrixQ[m],
          certifiedKernel = IdentityMatrix[dimension]; Break[]];
        Continue[]
      ];
      pivotColumns = observableTransportIndependentRows[
        Transpose[m[[rowPivots]]], rules];
      If[pivotColumns === $Failed ||
          Length[pivotColumns] =!= rank, Continue[]];
      If[rank === dimension,
        kernel = SparseArray[{}, {dimension, 0}];
        If[TrueQ[verbose], Print[
          "CODEX_KERNEL phase=certified method=sample-pivots",
          " rank=", rank, " nullity=0"]];
        certifiedKernel = kernel;
        Break[]
      ];

      (* Match NullSpace's canonical free-variable order so external records
         retain the established boundary-coordinate convention. *)
      freeColumns = Reverse[Complement[Range[dimension], pivotColumns]];
      square = m[[rowPivots, pivotColumns]];
      rhs = m[[rowPivots, freeColumns]];
      solved = Quiet[Check[LinearSolve[square, rhs], $Failed]];
      If[solved === $Failed, Continue[]];
      solved = observableTransportCancelMatrix[solved];
      kernel = ConstantArray[0, {dimension, Length[freeColumns]}];
      kernel[[freeColumns]] = IdentityMatrix[Length[freeColumns]];
      kernel[[pivotColumns]] = -solved;
      residual = observableTransportCancelMatrix[m . kernel];
      If[observableTransportZeroMatrixQ[residual],
        If[TrueQ[verbose], Print[
          "CODEX_KERNEL phase=certified method=sample-pivots",
          " rank=", rank,
          " nullity=", Length[freeColumns],
          " memory_bytes=", MemoryInUse[],
          " max_memory_bytes=", MaxMemoryUsed[]]];
        certifiedKernel = kernel;
        Break[]
      ],
      {rules, samples}];
    If[! MissingQ[certifiedKernel], Return[certifiedKernel]]
  ];

  If[TrueQ[verbose], Print[
    "CODEX_KERNEL phase=fallback method=exact-nullspace",
    " dimensions=", Dimensions[m]]];
  vectors = NullSpace[m];
  If[vectors === {}, ConstantArray[0, {dimension, 0}], Transpose[vectors]]
];

(* Refine a first-segment admissible Laurent embedding to the largest exact
   subbundle that is invariant under the spectator connection.  If N maps
   boundary coordinates to the lifted state, invariance is

       N' + N B = A N.

   Solving B on pivot rows and taking the exact kernel of the remaining
   residual gives the coordinate directions for which this equation is
   soluble.  Repeating strictly lowers the coordinate dimension until the
   residual vanishes, so termination is proved by finite dimension. *)
observableTransportInvariantEmbedding[embedding_?MatrixQ,
    liftedConnection_?MatrixQ, variable_, rankRules_List,
    verbose_: False] := Catch[Module[
  {current, coordinateMap, initialColumns, columns, pivotRows, pivotSquare,
   rhs, induced, residual, kernel, newColumns, history, step},

  current = observableTransportCancelMatrix[embedding];
  initialColumns = Dimensions[current][[2]];
  coordinateMap = IdentityMatrix[initialColumns];
  history = {};

  Do[
    columns = Dimensions[current][[2]];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=iteration-start",
      " dimensions=", Dimensions[current],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    If[columns === 0,
      Throw[<|"Status" -> "NoInvariantBoundaryCoordinates",
        "History" -> history|>, "InvariantEmbeddingExit"]
    ];
    pivotRows = observableTransportIndependentRows[current, rankRules];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=pivots-done",
      " pivot_count=", If[ListQ[pivotRows], Length[pivotRows], -1],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    If[pivotRows === $Failed || Length[pivotRows] =!= columns,
      Throw[<|"Status" -> "BoundaryEmbeddingRankFailed",
        "Coordinates" -> columns, "PivotRows" -> pivotRows,
        "History" -> history|>, "InvariantEmbeddingExit"]
    ];
    pivotSquare = current[[pivotRows]];
    rhs = observableTransportCancelMatrix[
      liftedConnection . current - D[current, variable]];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=rhs-done",
      " dimensions=", Dimensions[rhs],
      " head=", Head[rhs],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    induced = observableTransportCancelMatrix[
      LinearSolve[pivotSquare, rhs[[pivotRows]]]];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=induced-done",
      " dimensions=", Dimensions[induced],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    residual = observableTransportCancelMatrix[current . induced - rhs];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=residual-done",
      " dimensions=", Dimensions[residual],
      " head=", Head[residual],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    If[observableTransportZeroMatrixQ[residual],
      AppendTo[history, <|"Step" -> step, "Coordinates" -> columns,
        "ResidualZero" -> True|>];
      Throw[<|
        "Status" -> "Exact",
        "Embedding" -> current,
        "CoordinateMap" -> coordinateMap,
        "Connection" -> induced,
        "PivotRows" -> pivotRows,
        "Residual" -> residual,
        "InitialCoordinates" -> initialColumns,
        "FinalCoordinates" -> columns,
        "RemovedCoordinates" -> initialColumns - columns,
        "History" -> history
      |>, "InvariantEmbeddingExit"]
    ];

    kernel = observableTransportKernel[residual, rankRules, verbose];
    If[TrueQ[verbose], Print[
      "CODEX_INVARIANT step=", step, " phase=kernel-done",
      " dimensions=", If[MatrixQ[kernel], Dimensions[kernel], Missing[]],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]];
    If[! MatrixQ[kernel] || Dimensions[kernel][[1]] =!= columns,
      Throw[<|"Status" -> "SpectatorObstructionKernelFailed",
        "Coordinates" -> columns, "History" -> history|>,
        "InvariantEmbeddingExit"]
    ];
    newColumns = Dimensions[kernel][[2]];
    AppendTo[history, <|
      "Step" -> step,
      "Coordinates" -> columns,
      "ResidualZero" -> False,
      "ObstructionRank" -> columns - newColumns,
      "NextCoordinates" -> newColumns
    |>];
    If[newColumns >= columns,
      Throw[<|"Status" -> "SpectatorInvariantRefinementDidNotProgress",
        "Coordinates" -> columns, "History" -> history|>,
        "InvariantEmbeddingExit"]
    ];
    If[! observableTransportZeroMatrixQ[residual . kernel],
      Throw[<|"Status" -> "SpectatorObstructionKernelIdentityFailed",
        "Coordinates" -> columns, "History" -> history|>,
        "InvariantEmbeddingExit"]
    ];
    current = observableTransportCancelMatrix[current . kernel];
    coordinateMap = observableTransportCancelMatrix[coordinateMap . kernel],
    {step, 0, initialColumns}
  ];

  <|"Status" -> "SpectatorInvariantRefinementDidNotTerminate",
    "History" -> history|>
], "InvariantEmbeddingExit"];

(* Reconstruct constant residue matrices R_a from
     A_i/eps = Sum_a R_a d_i Log[letter_a]
   and then check the identity symbolically in both variables. *)
observableTransportResidues[letters_List, connections_List,
    variables : {_, _}, samples_List] := Module[
  {dlogs, coefficientRows, connectionRows, letterPivots, selectedLetters,
   selectedDlogs, rowPivots, square, sampledConnections, residueRows,
   dimension, residues, reconstructed},

  dimension = Length[First[connections]];
  dlogs = ({
      observableTransportCancel[D[#, variables[[1]]]/#],
      observableTransportCancel[D[#, variables[[2]]]/#]
    } &) /@ letters;
  coefficientRows = Flatten[Table[
    (#[[direction]] /. Thread[variables -> point]) & /@ dlogs,
    {point, samples}, {direction, 2}], 1];
  connectionRows = Flatten[Table[
    Flatten[connections[[direction]] /. Thread[variables -> point]],
    {point, samples}, {direction, 2}], 1];

  letterPivots = observableTransportIndependentRows[
    Transpose[coefficientRows], {}];
  If[letterPivots === $Failed || letterPivots === {},
    Return[<|"Status" -> "ResidueRankFailed"|>]
  ];
  selectedLetters = letters[[letterPivots]];
  selectedDlogs = dlogs[[letterPivots]];
  coefficientRows = coefficientRows[[All, letterPivots]];

  rowPivots = observableTransportIndependentRows[coefficientRows, {}];
  If[rowPivots === $Failed || Length[rowPivots] < Length[selectedLetters],
    Return[<|"Status" -> "ResidueSamplingFailed"|>]
  ];
  rowPivots = Take[rowPivots, Length[selectedLetters]];
  square = coefficientRows[[rowPivots]];
  sampledConnections = connectionRows[[rowPivots]];
  residueRows = LinearSolve[square, sampledConnections];
  residues = Partition[#, dimension] & /@ residueRows;

  reconstructed = Table[
    Sum[selectedDlogs[[a, direction]] residues[[a]],
      {a, Length[selectedLetters]}],
    {direction, 2}
  ];
  reconstructed = observableTransportCancelMatrix /@ reconstructed;
  If[! And @@ MapThread[
      observableTransportZeroMatrixQ[#1 - #2] &,
      {connections, reconstructed}],
    Return[<|"Status" -> "ResidueIdentityFailed"|>]
  ];
  <|
    "Status" -> "Exact",
    "Letters" -> selectedLetters,
    "Residues" -> residues,
    "Identity" -> True
  |>
];

(* An epsilon-form over an algebraic field need not admit one global
   rational chart.  Ordered integration nevertheless only needs a scalar
   kernel basis and constant matrices.  Taking each distinct nonzero matrix
   entry as a kernel is finite, exact, and independent of any rationalizing
   chart.  It is less compact than a dlog alphabet, so it is a fallback after
   the residue decomposition, never a replacement for it. *)
observableTransportEntryKernels[matrix_?MatrixQ] := Module[
  {kernels = {}, matrices = {}, keys = <||>, value, key, position,
   reconstructed},
  Do[
    value = observableTransportCancel[matrix[[row, column]]];
    If[observableTransportZeroQ[value], Continue[]];
    key = ToString[Unevaluated[value], InputForm];
    position = Lookup[keys, key, Missing["NewKernel"]];
    If[MissingQ[position],
      AppendTo[kernels, value];
      AppendTo[matrices, ConstantArray[0, Dimensions[matrix]]];
      position = Length[kernels];
      AssociateTo[keys, key -> position]
    ];
    matrices[[position, row, column]] += 1,
    {row, Length[matrix]}, {column, Length[First[matrix]]}
  ];
  reconstructed = If[kernels === {},
    ConstantArray[0, Dimensions[matrix]],
    Sum[kernels[[index]] matrices[[index]],
      {index, Length[kernels]}]
  ];
  If[! observableTransportZeroMatrixQ[matrix - reconstructed],
    Return[<|"Status" -> "EntryKernelIdentityFailed"|>]
  ];
  <|"Status" -> "Exact", "Method" -> "AlgebraicEntryKernels",
    "Kernels" -> kernels, "Matrices" -> matrices, "Identity" -> True|>
];

observableTransportLiftResidues[residues_List, slots_List] := Module[
  {positions, dimension, liftedDimension, rules, row, column, value},
  If[residues === {}, Return[{}]];
  positions = AssociationThread[
    observableTransportSlotKey /@ slots, Range[Length[slots]]];
  dimension = Length[First[residues]];
  liftedDimension = Length[slots];
  Table[
    rules = Reap[
      Do[
        row = positions[observableTransportSlotKey[slot]];
        Do[
          column = Lookup[positions,
            observableTransportSlotKey[{slot[[1]] - 1, source}], Missing[]];
          value = residues[[a, slot[[2]], source]];
          If[! MissingQ[column] && ! observableTransportZeroQ[value],
            Sow[{row, column} -> value]],
          {source, dimension}],
        {slot, slots}]
    ][[2]];
    SparseArray[If[rules === {}, {}, First[rules]],
      {liftedDimension, liftedDimension}],
    {a, Length[residues]}]
];

observableTransportWordMaps[residues_List, boundary_, demanded_,
    maximumWeight_Integer] := Module[
  {states, maps, stateCounts, mapCounts, scalarCounts, projected, children},
  states = {{{}, boundary}};
  maps = {};
  stateCounts = {};
  mapCounts = {};
  scalarCounts = {};
  Do[
    AppendTo[stateCounts, Length[states]];
    projected = ({#[[1]],
          observableTransportCancelMatrix[demanded . #[[2]]]} &) /@ states;
    projected = Select[projected,
      ! observableTransportZeroMatrixQ[#[[2]]] &];
    maps = Join[maps, projected];
    AppendTo[mapCounts, Length[projected]];
    AppendTo[scalarCounts,
      Total[Count[Flatten[#[[2]]], x_ /; ! observableTransportZeroQ[x]] & /@
        projected]];
    If[weight < maximumWeight,
      children = Flatten[Table[
        With[{child = residues[[a]] . state[[2]]},
          If[observableTransportZeroMatrixQ[child], Nothing,
            {Prepend[state[[1]], a], child}]],
        {state, states}, {a, Length[residues]}], 1],
      children = states
    ];
    states = children,
    {weight, 0, maximumWeight}
  ];
  children = Flatten[Table[
    With[{child = residues[[a]] . state[[2]]},
      If[observableTransportZeroMatrixQ[child], Nothing,
        {Prepend[state[[1]], a], child}]],
    {state, states}, {a, Length[residues]}], 1];
  <|
    "Maps" -> maps,
    "StateCountsByWeight" -> stateCounts,
    "MapCountsByWeight" -> mapCounts,
    "ScalarCountsByWeight" -> scalarCounts,
    "NextWeightIsZero" -> (children === {})
  |>
];

(* Dual traversal of exactly the same demanded maps.  The forward recurrence
   carries R_word.N (state dimension by boundary coordinates).  When the
   number of demanded rows is smaller, carry P.R_word instead and multiply by
   N only when emitting a word.  For a key {a_r,...,a_1}, Append builds
   P.R_a_r...R_a_1, matching the forward word orientation exactly. *)
observableTransportSuffixVisibility[state_, reachableBases_List,
    remainingWeight_Integer, sampleRules_List] := Module[
  {outputVisible, extensionVisible},
  outputVisible = observableTransportMatrixNonzeroQ[
    state . reachableBases[[1]], sampleRules];
  extensionVisible = remainingWeight >= 1 &&
    AnyTrue[Range[1, remainingWeight],
      observableTransportMatrixNonzeroQ[
          state . reachableBases[[# + 1]], sampleRules] &];
  {outputVisible, extensionVisible}
];

observableTransportBackwardWordMaps[residues_List, boundary_, demanded_,
    maximumWeight_Integer, reachableBases_List, sampleRules_List] := Module[
  {states, maps, stateCounts, mapCounts, scalarCounts, projected, children,
   initialVisibility, visibility, child, remaining},
  initialVisibility = observableTransportSuffixVisibility[
    demanded, reachableBases, maximumWeight, sampleRules];
  states = If[Or @@ initialVisibility,
    {{{}, demanded, Last[initialVisibility]}}, {}];
  maps = {};
  stateCounts = {};
  mapCounts = {};
  scalarCounts = {};
  Do[
    states = SortBy[states, Reverse[First[#]] &];
    AppendTo[stateCounts, Length[states]];
    projected = ({#[[1]],
          observableTransportCancelMatrix[#[[2]] . boundary]} &) /@ states;
    projected = Select[projected,
      observableTransportMatrixNonzeroQ[#[[2]], sampleRules] &];
    maps = Join[maps, projected];
    AppendTo[mapCounts, Length[projected]];
    AppendTo[scalarCounts,
      Total[Count[Flatten[#[[2]]],
          value_ /; ! observableTransportZeroQ[value]] & /@ projected]];
    If[weight < maximumWeight,
      remaining = maximumWeight - weight - 1;
      children = Flatten[Table[
        If[! TrueQ[state[[3]]], Nothing,
          child = state[[2]] . residues[[a]];
          visibility = observableTransportSuffixVisibility[
            child, reachableBases, remaining, sampleRules];
          If[Or @@ visibility,
            {Append[state[[1]], a], child, Last[visibility]}, Nothing]],
        {state, states}, {a, Length[residues]}], 1];
      states = children,
      states = {}
    ],
    {weight, 0, maximumWeight}
  ];
  <|
    "Maps" -> maps,
    "StateCountsByWeight" -> stateCounts,
    "MapCountsByWeight" -> mapCounts,
    "ScalarCountsByWeight" -> scalarCounts,
    "NextWeightIsZero" -> Missing["TerminalProbeNotRequested"],
    "Traversal" -> "TwoSidedDemandBackward"
  |>
];

(* Minimal exact reachable-observable automaton.  Q_t is an exact basis of
   span{R_word.N: |word|=t}, and C_(a,t) is certified by

       R_a.Q_t == Q_(t+1).C_(a,t).

   A prefix carries only H_t=P.R_prefix.Q_t.  Its child is therefore the
   small exact update H'_t=H_(t+1).C_(a,t).  Neither a full fundamental
   matrix, R_prefix.N, nor P.R_prefix is ever constructed. *)
observableTransportQuotientWordMaps[boundaryCoordinates_, demanded_,
    reachableBases_List, transitions_List, maximumWeight_Integer,
    sampleRules_List] := Module[
  {initialContractions, initialFlags, states, maps, stateCounts, mapCounts,
   projected, children, contractions, flags, remaining},

  initialContractions = observableTransportCancelMatrix[demanded . #] & /@
    Take[reachableBases, maximumWeight + 1];
  initialFlags = observableTransportMatrixNonzeroQ[#, sampleRules] & /@
    initialContractions;
  states = If[Or @@ initialFlags,
    {{{}, initialContractions, initialFlags}}, {}];
  maps = {};
  stateCounts = {};
  mapCounts = {};

  Do[
    states = SortBy[states, Reverse[First[#]] &];
    AppendTo[stateCounts, Length[states]];
    projected = Cases[states,
      state_ /; TrueQ[state[[3, 1]]] :>
        {state[[1]], observableTransportCancelMatrix[
          state[[2, 1]] . boundaryCoordinates]}];
    projected = Select[projected,
      observableTransportMatrixNonzeroQ[#[[2]], sampleRules] &];
    maps = Join[maps, projected];
    AppendTo[mapCounts, Length[projected]];

    If[weight < maximumWeight,
      remaining = maximumWeight - weight - 1;
      children = Flatten[Table[
        If[! Or @@ Rest[state[[3]]], Nothing,
          contractions = Table[
            observableTransportCancelMatrix[
              state[[2, t + 2]] . transitions[[t + 1, a]]],
            {t, 0, remaining}];
          flags = observableTransportMatrixNonzeroQ[#, sampleRules] & /@
            contractions;
          If[Or @@ flags,
            {Append[state[[1]], a], contractions, flags}, Nothing]],
        {state, states}, {a, Length[First[transitions]]}], 1];
      states = children,
      states = {}
    ],
    {weight, 0, maximumWeight}
  ];

  <|
    "Maps" -> maps,
    "StateCountsByWeight" -> stateCounts,
    "MapCountsByWeight" -> mapCounts,
    "ScalarCountsByWeight" -> Missing["UnrequestedTelemetry"],
    "NextWeightIsZero" -> Missing["TerminalProbeNotRequested"],
    "Traversal" -> "ExactReachableObservableQuotient"
  |>
];

(* Decompose a one-variable rational connection into exact kernels times
   constant matrices. The kernels remain rational functions; no branch is
   selected here. *)
observableTransportKernelDecomposition[m_, variable_] := Module[
  {terms, kernels, matrices, key, position, apart, together, numerator,
   denominator, degree, leading, monicDenominator, normalizedNumerator,
   coefficientRules, coefficient, normal, nonzeroPositions, row, column},
  kernels = {};
  matrices = {};
  normal = Normal[m];
  nonzeroPositions = Position[normal,
    value_ /; ! TrueQ[value === 0], {2}, Heads -> False];
  Do[
    {row, column} = entryPosition;
    apart = Apart[normal[[row, column]], variable];
    terms = If[Head[apart] === Plus, List @@ apart, {apart}];
    Do[
      If[observableTransportZeroQ[term], Continue[]];
      together = observableTransportCancel[term];
      numerator = Numerator[together];
      denominator = Denominator[together];
      degree = Exponent[denominator, variable];
      If[degree <= 0,
        Return[<|"Status" -> "PolynomialSecondSegment",
          "Entry" -> {row, column}, "Term" -> term|>]
      ];
      leading = Coefficient[denominator, variable, degree];
      monicDenominator = Expand[denominator/leading];
      normalizedNumerator = Expand[numerator/leading];
      If[Exponent[normalizedNumerator, variable] >= degree,
        Return[<|"Status" -> "ImproperSecondSegmentFraction",
          "Entry" -> {row, column}, "Term" -> term|>]
      ];
      coefficientRules = CoefficientRules[normalizedNumerator, {variable}];
      Do[
        coefficient = rule[[2]];
        If[! FreeQ[coefficient, variable],
          Return[<|"Status" -> "NonconstantKernelCoefficient",
            "Entry" -> {row, column}, "Term" -> term|>]
        ];
        key = observableTransportCancel[
          variable^First[rule[[1]]]/monicDenominator];
        position = FirstPosition[kernels, key, Missing[]];
        If[MissingQ[position],
          AppendTo[kernels, key];
          AppendTo[matrices, ConstantArray[0, Dimensions[m]]];
          position = {Length[kernels]}
        ];
        matrices[[position[[1]], row, column]] += coefficient,
        {rule, coefficientRules}],
      {term, terms}
    ],
    {entryPosition, nonzeroPositions}
  ];
  matrices = observableTransportCancelMatrix /@ matrices;
  If[! observableTransportZeroMatrixQ[
      m - Sum[kernels[[a]] matrices[[a]], {a, Length[kernels]}]],
    Return[<|"Status" -> "KernelIdentityFailed"|>]
  ];
  <|"Status" -> "Exact", "Kernels" -> kernels,
    "Matrices" -> matrices, "Identity" -> True|>
];

observableTransportSecondSegmentMaps[firstMaps_List, matrices_List,
    maximumWeight_Integer, sampleRules_List] := Module[
  {output, counts, states, children, totalWeight, harvested},
  counts = ConstantArray[0, maximumWeight + 1];
  harvested = Reap[
    Do[
      states = {{{}, first[[2]]}};
      Do[
        totalWeight = Length[first[[1]]] + secondWeight;
        Do[
          If[observableTransportMatrixNonzeroQ[state[[2]], sampleRules],
            Sow[{first[[1]], state[[1]], state[[2]]}];
            counts[[totalWeight + 1]]++
          ],
          {state, states}
        ];
        If[totalWeight < maximumWeight,
          children = Flatten[Table[
            With[{child = state[[2]] . matrices[[a]]},
              If[! observableTransportMatrixNonzeroQ[child, sampleRules],
                Nothing, {Append[state[[1]], a], child}]],
            {state, states}, {a, Length[matrices]}], 1],
          children = {}
        ];
        states = children,
        {secondWeight, 0, maximumWeight - Length[first[[1]]]}
      ],
      {first, firstMaps}
    ]
  ][[2]];
  output = If[harvested === {}, {}, First[harvested]];
  <|"Maps" -> output, "MapCountsByWeight" -> counts,
    "ScalarCountsByWeight" -> Missing["UnrequestedTelemetry"]|>
];

Options[BuildObservableTransport] = {
  "MaximumWeight" -> Automatic,
  "ClosureSteps" -> Automatic,
  "RankSamples" -> Automatic,
  "ResidueSamples" -> Automatic,
  "WordRepresentation" -> "MaterializedWords",
  "DiagnosticStopAfter" -> None,
  "Verbose" -> False
};

BuildObservableTransport[record_Association, demand_Association,
    OptionsPattern[]] := Catch@Module[
  {status, variables, eps, dimension, ranges, tTotal, tInverse,
   epsConnections, letters, physicalDemandPairs, physicalRows,
   physicalOrders, valuation,
   path, firstVariable, secondVariable, firstBase, secondBase,
   firstTargetSample, tau, rankSamples, automatonRankSamples,
   nonzeroSamples, residueSamples, tmin,
   blockLower, rowLower, blockOfRow, pathRules, tangent,
   firstConnection, secondConnection, propagatedLower, stateRowLower,
   flow, forbiddenFHigh, forbiddenPhysicalOrders, slots, positions,
   boundarySlots, boundaryPositions, embedding, lifted, tLaurent,
   forbiddenRows, forbiddenLabels, forbiddenMap, pivots, basis, frontier,
    constraints, closureHistory, closureSteps, closureStep, covariant, candidate,
   newPivots, constraintMatrix, constraintPivots, constraintRank,
   boundaryKernel, extendedFHigh, extendedSlots, extendedPositions,
   extendedBoundarySlots, newBoundarySlots, constrainedBoundary,
   unconstrainedColumns, tDemandLaurent, demandedRows, physicalLabels,
   physicalDemand, physicalOrder, component,
   demandedMap, residueRecord, firstKernelRecord, liftedResidues,
   pathActiveLetters, firstKernelIndices, firstKernelMethod,
   maximumWeight, observableMaximumWeight, reachabilityRecord,
   publicReachabilityRecord, reachableBases, reachableTransitions,
    reachableBoundaryCoordinates, dualInitialCoordinates,
    dualTransitions, dualTerminalContractions, wordRecord, wordTraversal,
    wordRepresentation, firstInitialContractions, compactAutomaton,
   firstStateCounts, firstMapCounts,
   nextStates, liftedSecond, boundaryDerivative, inducedRhs, pivotRows,
   pivotSquare, inducedConnection, inducedResidual, invariantRecord, kernelRecord,
   secondRecord, verbose, start, stageMark, diagnosticStop, recordExactQ,
   stabilized,
    constrainedRules, kernelColumns, coefficientField,
    boundaryKernelSamples,
   invariantSeconds, reachabilitySeconds, wordSeconds, kernelSeconds,
   secondSeconds},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
  stageMark = Function[label,
    If[verbose, Print[
      "CODEX_STAGE ", label,
      " elapsed_s=", N[AbsoluteTime[] - start],
      " memory_bytes=", MemoryInUse[],
      " max_memory_bytes=", MaxMemoryUsed[]]]];
  wordRepresentation = OptionValue["WordRepresentation"];
  diagnosticStop = OptionValue["DiagnosticStopAfter"];
  If[! MemberQ[{None, "BoundaryConstraintMatrix"}, diagnosticStop],
    Return[<|"Status" -> "InvalidDiagnosticStop",
      "DiagnosticStopAfter" -> diagnosticStop|>, Module]
  ];
  If[! MemberQ[{"MaterializedWords", "CompactAutomaton"},
      wordRepresentation],
    Return[<|"Status" -> "InvalidWordRepresentation",
      "WordRepresentation" -> wordRepresentation|>, Module]
  ];
  status = Lookup[record, "Status", Missing[]];
  recordExactQ = ExactFamilyEpsilonFormQ[record];
  If[! recordExactQ,
    Return[<|"Status" -> "FamilyEpsilonFormNotExactlyCertified",
      "RecordStatus" -> status|>, Module]
  ];

  variables = Lookup[record, "Variables", Missing[]];
  eps = Lookup[record, "Regulator", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[eps, _Symbol],
    Return[<|"Status" -> "TwoVariableRecordRequired"|>, Module]
  ];
  dimension = Lookup[record, "Dim", Length[Lookup[record, "TTotal", {}]]];
  ranges = Lookup[record, "Ranges", Missing[]];
  tTotal = Lookup[record, "TTotal", Missing[]];
  tInverse = Lookup[record, "TTotalInverse", Missing[]];
  epsConnections = {
    Lookup[record, "EpsFormX", Missing[]],
    Lookup[record, "EpsFormY", Missing[]]
  };
  letters = Lookup[record, "Letters", Missing[]];
  coefficientField = Lookup[Lookup[record, "ChartRecord", <||>],
    "CoefficientField", "Rational"];
  If[! ListQ[ranges] || ! MatrixQ[tTotal] || ! MatrixQ[tInverse] ||
      ! AllTrue[epsConnections, MatrixQ] || ! ListQ[letters],
    Return[<|"Status" -> "IncompleteFamilyEpsilonFormRecord"|>, Module]
  ];

  physicalDemandPairs = Lookup[demand, "PhysicalDemandPairs", Automatic];
  If[physicalDemandPairs === Automatic,
    physicalRows = Lookup[demand, "PhysicalRows", All];
    If[physicalRows === All, physicalRows = Range[dimension]];
    physicalOrders = Sort@DeleteDuplicates@Flatten@{
      Lookup[demand, "PhysicalOrders", Missing[]]};
    physicalDemandPairs = Flatten[
      Table[{order, row}, {order, physicalOrders}, {row, physicalRows}], 1],
    physicalDemandPairs = Sort@DeleteDuplicates[physicalDemandPairs];
    physicalRows = DeleteDuplicates[physicalDemandPairs[[All, 2]]];
    physicalOrders = Sort@DeleteDuplicates[physicalDemandPairs[[All, 1]]]
  ];
  valuation = Lookup[demand, "PhysicalValuation", 0];
  If[! MatchQ[physicalDemandPairs, {{_Integer, _Integer} ..}] ||
      ! VectorQ[physicalRows, IntegerQ] ||
      ! AllTrue[physicalRows, 1 <= # <= dimension &] ||
      ! VectorQ[physicalOrders, IntegerQ] || physicalOrders === {} ||
      ! IntegerQ[valuation],
    Return[<|"Status" -> "InvalidPhysicalDemand"|>, Module]
  ];

  path = Lookup[demand, "Path", Automatic];
  If[path === Automatic, path = FindObservableTransportPath[record]];
  If[AssociationQ[path] &&
      Lookup[path, "Status", None] === "ExactPathData",
    path = KeyDrop[path, "Status"]];
  If[! AssociationQ[path],
    Return[<|"Status" -> "PathDataRequired"|>, Module]
  ];
  firstVariable = Lookup[path, "FirstVariable", First[variables]];
  If[! MemberQ[variables, firstVariable],
    Return[<|"Status" -> "InvalidFirstPathVariable"|>, Module]
  ];
  secondVariable = First@DeleteCases[variables, firstVariable];
  firstBase = Lookup[path, "FirstBase", Missing[]];
  secondBase = Lookup[path, "SecondBase", Missing[]];
  firstTargetSample = Lookup[path, "FirstTargetSample", Missing[]];
  If[MemberQ[{firstBase, secondBase, firstTargetSample}, _Missing],
    Return[<|"Status" -> "PathDataRequired",
      "Required" -> {"FirstBase", "SecondBase", "FirstTargetSample"}|>,
      Module]
  ];
  tau = Unique["observablePath"];
  rankSamples = Replace[OptionValue["RankSamples"], Automatic -> {
      {tau -> 2/5, secondVariable -> 3/11},
      {tau -> 3/5, secondVariable -> 4/13},
      {tau -> 4/7, secondVariable -> 2/9}
    }];
  residueSamples = Replace[OptionValue["ResidueSamples"], Automatic -> {
      {1/7, 1/11}, {2/7, 2/11}, {3/7, 3/11}, {4/7, 5/11},
      {5/7, 7/11}, {1/5, 2/9}, {2/5, 4/9}
    }];
  nonzeroSamples = (Join[#, {firstVariable -> firstTargetSample}] &) /@
    rankSamples;
  automatonRankSamples = {
    {firstVariable -> firstBase, secondVariable -> secondBase},
    Join[{firstVariable -> firstTargetSample}, First[rankSamples]],
    Join[{firstVariable -> (firstBase + firstTargetSample)/2},
      Last[rankSamples]]
  };

  stageMark["regularity-preparation-start"];

  tmin = Min[0, Sequence @@ DeleteCases[
      observableTransportEpsilonOrder[#, eps] & /@ Flatten[tTotal],
      Infinity]];
  blockLower = Table[
    With[{orders = DeleteCases[
        observableTransportEpsilonOrder[#, eps] & /@
          Flatten[tInverse[[ranges[[block]], All]]], Infinity]},
      If[orders === {}, 0, Min[orders]]],
    {block, Length[ranges]}];
  rowLower = ConstantArray[Missing["NotCovered"], dimension];
  blockOfRow = ConstantArray[0, dimension];
  Do[
    Do[rowLower[[row]] = blockLower[[block]];
       blockOfRow[[row]] = block, {row, ranges[[block]]}],
    {block, Length[ranges]}];
  If[! FreeQ[rowLower, _Missing] || MemberQ[blockOfRow, 0],
    Return[<|"Status" -> "BlockRangesDoNotCoverFamily"|>, Module]
  ];

  pathRules = {
    firstVariable -> firstBase + tau (firstTargetSample - firstBase)
  };
  tangent = firstTargetSample - firstBase;
  firstConnection = observableTransportCancelMatrix[
    (epsConnections[[FirstPosition[variables, firstVariable][[1]]]]/eps /.
       pathRules) tangent];
  If[! FreeQ[firstConnection, eps],
    Return[<|"Status" -> "ConnectionIsNotEpsilonForm"|>, Module]
  ];

  propagatedLower = blockLower;
  Do[
    stabilized = False;
    Do[
      If[source < target && ! observableTransportZeroMatrixQ[
          firstConnection[[ranges[[target]], ranges[[source]]]]],
        propagatedLower[[target]] = Min[propagatedLower[[target]],
          propagatedLower[[source]] + 1]
      ],
      {source, 1, target - 1}],
    {target, Length[ranges]}];
  stateRowLower = propagatedLower[[blockOfRow]];
  flow = Min[propagatedLower];
  forbiddenFHigh = valuation - 1 - tmin;
  forbiddenPhysicalOrders = Range[flow + tmin, valuation - 1];
  slots = Flatten[Table[
    If[order >= stateRowLower[[component]], {{order, component}}, {}],
    {order, flow, forbiddenFHigh}, {component, dimension}], 2];
  positions = AssociationThread[
    observableTransportSlotKey /@ slots, Range[Length[slots]]];
  boundarySlots = Select[slots, #[[1]] >= rowLower[[#[[2]]]] &];
  boundaryPositions = AssociationThread[
    observableTransportSlotKey /@ boundarySlots,
    Range[Length[boundarySlots]]];
  embedding = SparseArray[
    Table[
      {positions[observableTransportSlotKey[slot]],
         boundaryPositions[observableTransportSlotKey[slot]]} -> 1,
      {slot, boundarySlots}],
    {Length[slots], Length[boundarySlots]}];
  lifted = First@observableTransportLiftResidues[{firstConnection}, slots];

  stageMark["boundary-regularity-closure-start"];

  tLaurent = observableTransportLaurentMatrices[tTotal, eps,
    {tmin, Max[0, valuation - 1 - flow]}];
  forbiddenRows = {};
  forbiddenLabels = {};
  Do[
    With[{row = Table[
        Lookup[tLaurent, physicalOrder - slot[[1]],
          ConstantArray[0, {dimension, dimension}]][[component, slot[[2]]]],
        {slot, slots}]},
      If[! AllTrue[row, observableTransportZeroQ],
        AppendTo[forbiddenRows, row];
        AppendTo[forbiddenLabels, {physicalOrder, component}]
      ]],
    {physicalOrder, forbiddenPhysicalOrders}, {component, dimension}];
  forbiddenMap = If[forbiddenRows === {},
    SparseArray[{}, {0, Length[slots]}], forbiddenRows];
  If[verbose, Print["Observable transport forbidden map: ",
    Dimensions[forbiddenMap], "; slots ", Length[slots],
    "; boundary slots ", Length[boundarySlots]]];
  If[forbiddenRows =!= {} &&
      (! MatrixQ[forbiddenMap] ||
       Dimensions[forbiddenMap][[2]] =!= Length[slots]),
    Return[<|"Status" -> "ForbiddenMapNotRectangular",
      "Dimensions" -> Dimensions[forbiddenMap],
      "SlotCount" -> Length[slots]|>, Module]
  ];

  If[forbiddenRows === {},
    constraintMatrix = SparseArray[{}, {0, Length[boundarySlots]}];
    constraintRank = 0;
    boundaryKernel = IdentityMatrix[Length[boundarySlots]];
    closureHistory = {0},
    pivots = observableTransportIndependentRows[forbiddenMap,
      First[rankSamples]];
    If[pivots === $Failed,
      Return[<|"Status" -> "SingularRankSample"|>, Module]
    ];
    basis = forbiddenMap[[pivots]];
    frontier = basis;
    If[verbose, Print["Observable transport initial dual basis: ",
      Dimensions[basis], "; lifted connection ", Dimensions[lifted]]];
    constraints = {observableTransportCancelMatrix[
      (basis /. tau -> 0) . embedding]};
    closureHistory = {Length[pivots]};
    closureSteps = Replace[OptionValue["ClosureSteps"],
      Automatic -> Length[slots]];
    Do[
      If[verbose, Print[
        "CODEX_REGULARITY step=", closureStep,
        " phase=covariant-start basis_rows=", Length[basis],
        " frontier_rows=", Length[frontier],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]];
      covariant = observableTransportCancelMatrix[D[frontier, tau] +
        frontier . lifted];
      If[verbose, Print[
        "CODEX_REGULARITY step=", closureStep,
        " phase=covariant-done candidate_rows=",
        Length[basis] + Length[covariant],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]];
      candidate = Join[basis, covariant];
      pivots = observableTransportIndependentRows[candidate,
        First[rankSamples]];
      If[verbose, Print[
        "CODEX_REGULARITY step=", closureStep,
        " phase=pivots-done pivot_count=",
        If[ListQ[pivots], Length[pivots], -1],
        " memory_bytes=", MemoryInUse[],
        " max_memory_bytes=", MaxMemoryUsed[]]];
      If[pivots === $Failed,
        Return[<|"Status" -> "SingularClosureRankSample"|>, Module]
      ];
      newPivots = Select[pivots, # > Length[basis] &];
      frontier = If[newPivots === {},
        ConstantArray[0, {0, Length[slots]}], candidate[[newPivots]]];
      If[newPivots =!= {}, AppendTo[constraints,
        observableTransportCancelMatrix[(frontier /. tau -> 0) . embedding]]];
      basis = candidate[[pivots]];
      AppendTo[closureHistory, Length[pivots]];
      If[newPivots === {} || Length[pivots] === Length[slots],
        stabilized = True;
        Break[]],
      {closureStep, closureSteps}];
    If[! stabilized,
      Return[<|"Status" -> "DualClosureDidNotStabilize"|>, Module]
    ];
    constraintMatrix = Join @@ constraints;
    constraintPivots = observableTransportIndependentRows[
      constraintMatrix, {secondVariable -> secondBase}];
    If[constraintPivots === $Failed,
      Return[<|"Status" -> "SingularConstraintRankSample"|>, Module]
    ];
    constraintMatrix = constraintMatrix[[constraintPivots]];
    constraintRank = Length[constraintPivots];
    If[diagnosticStop === "BoundaryConstraintMatrix",
      Return[<|
        "Status" -> "DiagnosticBoundaryConstraintMatrix",
        "Family" -> Lookup[record, "Family", Missing[]],
        "Variables" -> variables,
        "Regulator" -> eps,
        "Path" -> path,
        "BoundarySlots" -> boundarySlots,
        "ConstraintMatrix" -> constraintMatrix,
        "ConstraintRank" -> constraintRank,
        "ConstraintDimensions" -> Dimensions[constraintMatrix],
        "RankSamples" -> rankSamples,
        "DualClosureRankHistory" -> closureHistory,
        "Seconds" -> AbsoluteTime[] - start,
        "MemoryInUseBytes" -> MemoryInUse[],
        "MaxMemoryUsedBytes" -> MaxMemoryUsed[]
      |>, Module]
    ];
    boundaryKernelSamples = {
      {firstVariable -> firstBase, secondVariable -> secondBase},
      Join[{firstVariable -> firstTargetSample}, First[rankSamples]],
      Join[{firstVariable -> (firstBase + firstTargetSample)/2},
        Last[rankSamples]]
    };
    boundaryKernel = observableTransportKernel[constraintMatrix,
      boundaryKernelSamples, verbose];
    If[! observableTransportZeroMatrixQ[constraintMatrix . boundaryKernel],
      Return[<|"Status" -> "BoundaryKernelIdentityFailed"|>, Module]
    ]
  ];

  stageMark["boundary-regularity-closure-done"];

  extendedFHigh = Max[physicalOrders] - tmin;
  extendedSlots = Flatten[Table[
    If[order >= stateRowLower[[component]], {{order, component}}, {}],
    {order, flow, extendedFHigh}, {component, dimension}], 2];
  extendedPositions = AssociationThread[
    observableTransportSlotKey /@ extendedSlots,
    Range[Length[extendedSlots]]];
  extendedBoundarySlots = Select[extendedSlots,
    #[[1]] >= rowLower[[#[[2]]]] &];
  newBoundarySlots = Complement[extendedBoundarySlots, boundarySlots];
  kernelColumns = If[MatrixQ[boundaryKernel],
    Dimensions[boundaryKernel][[2]], 0];
  constrainedRules = Reap[
    Do[
      With[{stateRow = extendedPositions[observableTransportSlotKey[
            boundarySlots[[boundaryRow]]]],
          value = boundaryKernel[[boundaryRow, column]]},
        If[! observableTransportZeroQ[value],
          Sow[{stateRow, column} -> value]]],
      {boundaryRow, Length[boundarySlots]}, {column, kernelColumns}];
    Do[
      Sow[{extendedPositions[observableTransportSlotKey[newBoundarySlots[[i]]]],
          kernelColumns + i} -> 1],
      {i, Length[newBoundarySlots]}]
  ][[2]];
  constrainedBoundary = SparseArray[
    If[constrainedRules === {}, {}, First[constrainedRules]],
    {Length[extendedSlots], kernelColumns + Length[newBoundarySlots]}];

  tDemandLaurent = observableTransportLaurentMatrices[tTotal, eps,
    {tmin, Max[physicalOrders] - flow}];
  demandedRows = {};
  physicalLabels = {};
  Do[
    {physicalOrder, component} = physicalDemand;
    With[{row = Table[
        Lookup[tDemandLaurent, physicalOrder - slot[[1]],
          ConstantArray[0, {dimension, dimension}]][[component, slot[[2]]]],
        {slot, extendedSlots}]},
      If[! AllTrue[row, observableTransportZeroQ],
        AppendTo[demandedRows, row];
        AppendTo[physicalLabels, {physicalOrder, component}]
      ]],
    {physicalDemand, physicalDemandPairs}];
  demandedMap = If[demandedRows === {},
    SparseArray[{}, {0, Length[extendedSlots]}], demandedRows];
  If[verbose, Print["Observable transport demanded map: ",
    Dimensions[demandedMap], "; extended slots ", Length[extendedSlots],
    "; constrained boundary ", Dimensions[constrainedBoundary]]];
  If[! MatrixQ[demandedMap] ||
      Dimensions[demandedMap][[2]] =!= Length[extendedSlots],
    Return[<|"Status" -> "DemandedMapNotRectangular",
      "Dimensions" -> Dimensions[demandedMap],
      "SlotCount" -> Length[extendedSlots]|>, Module]
  ];

  stageMark["demand-projection-done"];

  stageMark["kernel-preprocessing-start"];

  residueRecord = If[coefficientField === "Multiquadratic", $Failed,
    observableTransportResidues[
      letters,
      observableTransportCancelMatrix[#/eps] & /@ epsConnections,
      variables, residueSamples]
  ];
  If[AssociationQ[residueRecord] &&
      Lookup[residueRecord, "Status", None] === "Exact",
    pathActiveLetters = Select[Range[Length[residueRecord["Letters"]]],
      ! observableTransportZeroQ[
        D[residueRecord["Letters"][[#]], firstVariable]] &];
    firstKernelRecord = <|"Status" -> "Exact",
      "Method" -> "DLogResidues",
      "Kernels" -> (observableTransportCancel[
          (D[#, firstVariable]/# /. pathRules) tangent] & /@
        residueRecord["Letters"][[pathActiveLetters]]),
      "Matrices" -> residueRecord["Residues"][[pathActiveLetters]],
      "Identity" -> True|>;
    firstKernelIndices = pathActiveLetters;
    firstKernelMethod = "DLogResidues",
    firstKernelRecord = observableTransportEntryKernels[firstConnection];
    If[Lookup[firstKernelRecord, "Status", None] =!= "Exact",
      Return[firstKernelRecord, Module]
    ];
    firstKernelIndices = Range[Length[firstKernelRecord["Kernels"]]];
    pathActiveLetters = {};
    firstKernelMethod = firstKernelRecord["Method"]
  ];
  liftedResidues = observableTransportLiftResidues[
    firstKernelRecord["Matrices"], extendedSlots];
  maximumWeight = Replace[OptionValue["MaximumWeight"],
    Automatic -> extendedFHigh - flow];
  If[! IntegerQ[maximumWeight] || maximumWeight < 0,
    Return[<|"Status" -> "InvalidMaximumWeight"|>, Module]
  ];
  secondConnection = observableTransportCancelMatrix[
    (epsConnections[[FirstPosition[variables, secondVariable][[1]]]]/eps) /.
      firstVariable -> firstBase];
  liftedSecond = First@observableTransportLiftResidues[
    {secondConnection}, extendedSlots];
  stageMark["kernel-preprocessing-done"];
  stageMark["spectator-invariant-refinement-start"];
  {invariantSeconds, invariantRecord} = AbsoluteTiming[
    observableTransportInvariantEmbedding[
      constrainedBoundary, liftedSecond, secondVariable,
      {secondVariable -> secondBase}, verbose]
  ];
  If[! AssociationQ[invariantRecord] ||
      Lookup[invariantRecord, "Status", None] =!= "Exact",
    Return[If[AssociationQ[invariantRecord], invariantRecord,
      <|"Status" -> "SpectatorInvariantRefinementFailed"|>], Module]
  ];
  constrainedBoundary = invariantRecord["Embedding"];
  inducedConnection = invariantRecord["Connection"];
  inducedResidual = invariantRecord["Residual"];
  stageMark["spectator-invariant-refinement-done"];

  (* Compact mode is demand-dual: propagate only exact row spaces reachable
     from the requested hard-function projector.  The legacy materialized
     regression mode keeps the forward boundary-reachable construction. *)
  stageMark[If[wordRepresentation === "CompactAutomaton",
    "demand-dual-automaton-start", "forward-materialization-start"]];
  If[wordRepresentation === "CompactAutomaton",
    {reachabilitySeconds, reachabilityRecord} = AbsoluteTiming[
      observableTransportDualObservableCertificate[
        liftedResidues, demandedMap, constrainedBoundary, maximumWeight,
        automatonRankSamples, verbose]
    ];
    If[! AssociationQ[reachabilityRecord] ||
        Lookup[reachabilityRecord, "Status", None] =!= "Exact",
      Return[If[AssociationQ[reachabilityRecord], reachabilityRecord,
        <|"Status" -> "ObservableDualCertificateFailed"|>], Module]
    ];
    observableMaximumWeight =
      reachabilityRecord["ObservableMaximumWeight"];
    dualInitialCoordinates = Lookup[reachabilityRecord,
      "InitialCoordinates", Missing[]];
    dualTransitions = Lookup[reachabilityRecord,
      "ObservableTransitionsByWeight", {}];
    dualTerminalContractions = Lookup[reachabilityRecord,
      "TerminalContractionsByExactWeight", {}];
    If[! MatrixQ[dualInitialCoordinates] ||
        Length[dualTransitions] =!= maximumWeight ||
        Length[dualTerminalContractions] =!= maximumWeight + 1,
      Return[<|"Status" -> "DualObservableAutomatonInventoryIncomplete",
        "ExpectedTransitions" -> maximumWeight,
        "ActualTransitions" -> Length[dualTransitions],
        "ExpectedTerminals" -> maximumWeight + 1,
        "ActualTerminals" -> Length[dualTerminalContractions]|>, Module]
    ];
    publicReachabilityRecord = KeyDrop[reachabilityRecord,
      {"InitialCoordinates", "ObservableTransitionsByWeight",
        "TerminalContractionsByExactWeight"}];
    wordTraversal = "ExactCompactDualObservableAutomaton";
    wordSeconds = 0.;
    firstInitialContractions = Missing["DualObservableOrientation"];
    wordRecord = <|
      "Maps" -> Missing["CompactAutomatonNotMaterialized"],
      "StateCountsByWeight" ->
        Missing["CompactAutomatonNotEnumerated"],
      "MapCountsByWeight" -> Missing["CompactAutomatonNotEnumerated"],
      "ScalarCountsByWeight" -> Missing["UnrequestedTelemetry"],
      "NextWeightIsZero" -> Lookup[reachabilityRecord,
        "NextWeightStateIsZero", Missing[]],
      "Traversal" -> wordTraversal|>;
    firstStateCounts = Missing["CompactAutomatonNotEnumerated"];
    firstMapCounts = Missing["CompactAutomatonNotEnumerated"],

    {reachabilitySeconds, reachabilityRecord} = AbsoluteTiming[
      observableTransportReachabilityCertificate[
        liftedResidues, constrainedBoundary, demandedMap, maximumWeight,
        rankSamples]
    ];
    If[! AssociationQ[reachabilityRecord] ||
        Lookup[reachabilityRecord, "Status", None] =!= "Exact",
      Return[If[AssociationQ[reachabilityRecord], reachabilityRecord,
        <|"Status" -> "ObservableReachabilityCertificateFailed"|>], Module]
    ];
    observableMaximumWeight =
      reachabilityRecord["ObservableMaximumWeight"];
    reachableBases = Lookup[reachabilityRecord, "ReachableBases", {}];
    reachableTransitions = Lookup[reachabilityRecord,
      "ReachableTransitionsByWeight", {}];
    reachableBoundaryCoordinates = Lookup[reachabilityRecord,
      "BoundaryCoordinates", Missing[]];
    If[Length[reachableBases] =!= maximumWeight + 1,
      Return[<|"Status" -> "ReachableBasisInventoryIncomplete",
        "Expected" -> maximumWeight + 1,
        "Actual" -> Length[reachableBases]|>, Module]
    ];
    If[Length[reachableTransitions] =!= maximumWeight ||
        ! MatrixQ[reachableBoundaryCoordinates],
      Return[<|"Status" -> "ReachableAutomatonInventoryIncomplete",
        "ExpectedTransitions" -> maximumWeight,
        "ActualTransitions" -> Length[reachableTransitions]|>, Module]
    ];
    publicReachabilityRecord = KeyDrop[reachabilityRecord,
      {"ReachableBases", "ReachableTransitionsByWeight",
        "BoundaryCoordinates"}];
    wordTraversal = "ExactReachableObservableQuotient";
    {wordSeconds, wordRecord} = AbsoluteTiming[
      If[observableMaximumWeight < 0,
        <|"Maps" -> {}, "StateCountsByWeight" -> {},
          "MapCountsByWeight" -> {}, "ScalarCountsByWeight" -> {},
          "NextWeightIsZero" -> Missing["NoObservableWord"],
          "Traversal" -> "None"|>,
        observableTransportQuotientWordMaps[
          reachableBoundaryCoordinates, demandedMap, reachableBases,
          reachableTransitions, observableMaximumWeight, nonzeroSamples]
      ]
    ];
    wordRecord["Maps"] = ({firstKernelIndices[[#[[1]]]], #[[2]]} &) /@
      wordRecord["Maps"];
    firstStateCounts = PadRight[wordRecord["StateCountsByWeight"],
      maximumWeight + 1, Missing["ObservableCutoffCertified"]];
    firstMapCounts = PadRight[wordRecord["MapCountsByWeight"],
      maximumWeight + 1, 0]
  ];
  stageMark[If[wordRepresentation === "CompactAutomaton",
    "demand-dual-automaton-done", "forward-materialization-done"]];
  stageMark["spectator-kernel-decomposition-start"];
  {kernelSeconds, kernelRecord} = AbsoluteTiming[
    If[coefficientField === "Multiquadratic",
      observableTransportEntryKernels[inducedConnection],
      observableTransportKernelDecomposition[
        inducedConnection, secondVariable]
    ]
  ];
  If[Lookup[kernelRecord, "Status", None] =!= "Exact",
    Return[kernelRecord, Module]
  ];
  stageMark["spectator-kernel-decomposition-done"];
  If[wordRepresentation === "CompactAutomaton",
    secondSeconds = 0.;
    secondRecord = <|
      "Maps" -> Missing["CompactAutomatonNotMaterialized"],
      "MapCountsByWeight" -> Missing["CompactAutomatonNotEnumerated"],
      "ScalarCountsByWeight" -> Missing["UnrequestedTelemetry"]|>;
    compactAutomaton = <|
      "Status" -> "ExactCompactTwoSegmentAutomaton",
      "Orientation" -> "DualObservableRows",
      "FirstAlphabetIndices" -> firstKernelIndices,
      "FirstMaximumWeight" -> observableMaximumWeight,
      "RequestedMaximumWeight" -> maximumWeight,
      "FirstInitialCoordinates" -> dualInitialCoordinates,
      "FirstObservableTransitionsByWeight" -> If[
        observableMaximumWeight <= 0, {},
        Take[dualTransitions, observableMaximumWeight]],
      "FirstTerminalContractionsByExactWeight" -> If[
        observableMaximumWeight < 0, {},
        Take[dualTerminalContractions, observableMaximumWeight + 1]],
      "BoundaryCoordinateCount" -> Dimensions[constrainedBoundary][[2]],
      "SecondAlphabetIndices" -> Range[Length[kernelRecord["Matrices"]]],
      "SecondKernelMatrices" -> kernelRecord["Matrices"],
      "WordMapFormula" ->
        "P=A_0.O_0; H<-H.C_(a,t); M=H.(O_w.N); " <>
        "M<-M.K_b for the spectator word"|>,

    {secondSeconds, secondRecord} = AbsoluteTiming[
      observableTransportSecondSegmentMaps[
        wordRecord["Maps"], kernelRecord["Matrices"], maximumWeight,
        nonzeroSamples]
    ];
    compactAutomaton = Missing["MaterializedWordRepresentation"]
  ];

  <|
    "Status" -> "ExactObservableTransport",
    "Family" -> Lookup[record, "Family", Missing[]],
    "Variables" -> variables,
    "Regulator" -> eps,
    "PhysicalRows" -> physicalLabels,
    "PhysicalDemandPairs" -> physicalDemandPairs,
    "PhysicalValuation" -> valuation,
    "Path" -> <|
      "FirstVariable" -> firstVariable,
      "SecondVariable" -> secondVariable,
      "FirstBase" -> firstBase,
      "SecondBase" -> secondBase,
      "FirstTargetSample" -> firstTargetSample|>,
    "BoundarySlots" -> boundarySlots,
    "BoundaryConstraintMatrix" -> constraintMatrix,
    "BoundaryKernel" -> boundaryKernel,
    "BoundaryEmbedding" -> constrainedBoundary,
    "BoundaryCoordinateMap" -> invariantRecord["CoordinateMap"],
    "BoundaryCoordinates" -> Dimensions[constrainedBoundary][[2]],
    "ConstraintRank" -> constraintRank,
    "SpectatorConstraintRank" -> invariantRecord["RemovedCoordinates"],
    "SpectatorInvariantRefinement" ->
      KeyDrop[invariantRecord,
        {"Embedding", "CoordinateMap", "Connection", "Residual"}],
    "DualClosureRankHistory" -> closureHistory,
    "FirstSegmentKernelMethod" -> firstKernelMethod,
    "FirstSegmentKernels" -> firstKernelRecord["Kernels"],
    "FirstSegmentKernelMatrices" -> firstKernelRecord["Matrices"],
    "DLogLetters" -> If[AssociationQ[residueRecord],
      residueRecord["Letters"], {}],
    "DLogResidues" -> If[AssociationQ[residueRecord],
      residueRecord["Residues"], {}],
    "FirstSegmentActiveLetters" -> pathActiveLetters,
    "WordRepresentation" -> wordRepresentation,
    "CompactTransportAutomaton" -> compactAutomaton,
    "FirstSegmentWordMaps" -> wordRecord["Maps"],
    "FirstSegmentStateCountsByWeight" -> firstStateCounts,
    "FirstSegmentMapCountsByWeight" -> firstMapCounts,
    "FirstSegmentTraversal" -> Lookup[wordRecord, "Traversal",
      "BoundaryForward"],
    "ObservableMaximumFirstSegmentWeight" -> observableMaximumWeight,
    "ObservableReachabilityCertificate" -> publicReachabilityRecord,
    "SecondSegmentKernels" -> kernelRecord["Kernels"],
    "SecondSegmentKernelMatrices" -> kernelRecord["Matrices"],
    "SecondSegmentKernelMethod" -> Lookup[kernelRecord, "Method",
      "RationalKernelDecomposition"],
    "TwoSegmentWordMaps" -> secondRecord["Maps"],
    "TwoSegmentMapCountsByWeight" -> secondRecord["MapCountsByWeight"],
    "StageSeconds" -> <|
      "SpectatorInvariantRefinement" -> invariantSeconds,
      "ReachabilityCertificate" -> reachabilitySeconds,
      "FirstSegmentQuotientWords" -> wordSeconds,
      "SpectatorKernelDecomposition" -> kernelSeconds,
      "SecondSegmentComposition" -> secondSeconds|>,
    "Certificates" -> <|
      "FamilyEpsilonFormExact" -> True,
      "BoundaryKernel" -> True,
      "BoundaryEmbeddingFullColumnRank" ->
        Length[invariantRecord["PivotRows"]] ===
          Dimensions[constrainedBoundary][[2]],
      "SpectatorInvariantRefinement" -> True,
      "ObservableReachableSpansExact" ->
        And @@ reachabilityRecord["SpanIdentities"],
      "ObservableCutoffExact" ->
        TrueQ[reachabilityRecord["CutoffIdentity"]],
      "ReachableAutomatonExact" ->
        TrueQ[reachabilityRecord["TransitionIdentities"]],
      "CompactAutomatonExact" -> True,
      "FirstKernelIdentity" -> True,
      "BoundarySubspaceInvariant" -> True,
      "SecondKernelIdentity" -> True|>,
    "MaximumWeight" -> maximumWeight,
    "Seconds" -> AbsoluteTime[] - start
  |>
];
