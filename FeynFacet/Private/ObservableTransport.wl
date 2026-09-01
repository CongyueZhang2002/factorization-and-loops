(* Exact observable-only transport for two-variable epsilon-form families. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[BuildObservableTransportManifest, FindObservableTransportPath, BuildObservableTransportDemand, BuildObservableTransport];
ClearAll[
  observableTransportCancel,
  observableTransportCancelMatrix,
  observableTransportZeroQ,
  observableTransportZeroMatrixQ,
  observableTransportSlotKey,
  observableTransportEpsilonOrder,
  observableTransportLaurentMatrices,
  observableTransportIndependentRows,
  observableTransportRowBasis,
  observableTransportColumnBasis,
  observableTransportKernel,
  observableTransportResidues,
  observableTransportEntryKernels,
  observableTransportRecordRegularQ,
  observableTransportLiftResidues,
  observableTransportWordMaps,
  observableTransportKernelDecomposition,
  observableTransportSecondSegmentMaps,
  observableTransportFamilyName,
  observableTransportIntegralIndices,
  observableTransportNonsingularQ,
  observableTransportFamilyFromFile,
  observableTransportWriteAtomic,
  observableTransportSourceFrameQ,
  observableTransportRecordChart,
  observableTransportBlockLowerQ
];

observableTransportCancel[x_] := Quiet[Cancel[Together[x]]];

observableTransportCancelMatrix[m_] :=
  Map[observableTransportCancel, Normal[m], {2}];

observableTransportZeroQ[x_] :=
  TrueQ[masterTransportZeroQ[x]];

observableTransportZeroMatrixQ[m_] :=
  AllTrue[Flatten[{Normal[m]}], observableTransportZeroQ];

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

(* Default family-name extractor (generality pass 2026-08-23): the family
   is the one canonical-family token in the file's base name, whatever
   prefix a campaign gives its artifacts.  A campaign whose file names do
   not carry the token supplies its own function through
   "FamilyFromFileName". *)
observableTransportFamilyFromFile[file_String] := Module[{match},
  match = DeleteDuplicates[StringCases[FileBaseName[file],
    $canonicalFamilyPrefix ~~ DigitCharacter ..]];
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

(* Generality pass 2026-08-23 (A2): the artifact NAMING of a campaign is
   the campaign's, not the package's.  The file patterns, the file-name ->
   family map and the family sort order are options; their defaults name
   no campaign prefix (only the canonical-family token) and the driver
   script passes the project's own patterns explicitly. *)
Options[BuildObservableTransportManifest] = {
  "Card" -> None,
  "ReportFile" -> Automatic,
  "DifferentialFilePattern" -> "*.wl",
  "EpsFormFilePattern" -> "*.wl",
  "FamilyFromFileName" -> Automatic,
  "FamilySortKey" -> Identity
};

BuildObservableTransportManifest[
    epsilonFormDirectories : {__String},
    differentialSystemDirectory_String, valuationsFile_String,
    manifestFile_String, OptionsPattern[]] := Module[
  {directories, differentialFiles, familyFromFile, candidates,
   candidateRows, grouped, selected = <||>, rejected = <||>,
   duplicates = <||>, missing, family, records, exactRecords,
   card, reportFile, rows, report, differentialPattern, epsFormPattern,
   familySortKey},
  directories = ExpandFileName /@ epsilonFormDirectories;
  If[! AllTrue[directories, DirectoryQ] ||
      ! DirectoryQ[differentialSystemDirectory] ||
      ! FileExistsQ[valuationsFile],
    Return[<|"Status" -> "InputPathMissing"|>]];
  differentialPattern = OptionValue["DifferentialFilePattern"];
  epsFormPattern = OptionValue["EpsFormFilePattern"];
  If[! StringQ[differentialPattern] || ! StringQ[epsFormPattern],
    Return[<|"Status" -> "InvalidFilePatternOption"|>]];
  familyFromFile = Replace[OptionValue["FamilyFromFileName"],
    Automatic -> observableTransportFamilyFromFile];
  familySortKey = Replace[OptionValue["FamilySortKey"],
    Automatic -> Identity];
  differentialFiles = SortBy[
    FileNames[differentialPattern, differentialSystemDirectory],
    FileBaseName];
  differentialFiles = Association @ Cases[differentialFiles,
    file_ :> With[{name = familyFromFile[file]},
      If[! StringQ[name], Nothing, name -> ExpandFileName[file]]]];
  If[differentialFiles === <||>,
    Return[<|"Status" -> "NoDifferentialFamiliesFound",
      "DifferentialSystemDirectory" ->
        ExpandFileName[differentialSystemDirectory],
      "DifferentialFilePattern" -> differentialPattern,
      "DifferentialFamilyCount" -> 0|>]];
  candidates = Flatten[Table[
    Thread[{priority,
      FileNames[epsFormPattern, directories[[priority]],
        Infinity]}],
    {priority, Length[directories]}], 1];
  candidateRows = Cases[candidates, {priority_Integer, file_String} :>
    Module[{name, record},
      name = familyFromFile[file];
      If[! StringQ[name] || ! KeyExistsQ[differentialFiles, name],
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
      {family, SortBy[Keys[selected], familySortKey]}],
    {"family", "epsilon_form", "differential_system", "valuations",
      "card"}];
  observableTransportWriteAtomic[rows, manifestFile, "TSV"];
  report = <|
    "Status" -> If[missing === {}, "CompleteExactInventory",
      "IncompleteExactInventory"],
    "DifferentialFamilyCount" -> Length[differentialFiles],
    "ExactFamilyCount" -> Length[selected],
    "MissingFamilies" -> SortBy[missing, familySortKey],
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

observableTransportKernel[m_] := Module[{dimension, vectors},
  dimension = If[MatrixQ[m], Dimensions[m][[2]], 0];
  If[Length[m] === 0, Return[IdentityMatrix[dimension]]];
  vectors = NullSpace[m];
  If[vectors === {}, ConstantArray[0, {dimension, 0}], Transpose[vectors]]
];

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
  {kernels = {}, matrices = {}, keys = <||>, value, key, position},
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
  (* Every matrix entry is assigned its own exact canonical value above;
     equal InputForm keys merely share that same stored value.  Rebuilding
     the matrix and sending the resulting radical zeros through the general
     symbolic zero prover is therefore tautological.  It was also both slow
     and incomplete: a proven-by-construction zero could be reported as
     inconclusive. *)
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

(* Decompose a one-variable rational connection into exact kernels times
   constant matrices. The kernels remain rational functions; no branch is
   selected here. *)
observableTransportKernelDecomposition[m_, variable_] := Module[
  {terms, kernels, matrices, key, position, apart, together, numerator,
   denominator, degree, leading, monicDenominator, normalizedNumerator,
   coefficientRules, coefficient},
  kernels = {};
  matrices = {};
  Do[
    apart = Apart[m[[row, column]], variable];
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
    {row, Length[m]}, {column, Length[First[m]]}
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
    maximumWeight_Integer] := Module[
  {output, counts, scalarCounts, states, children, totalWeight},
  output = {};
  counts = ConstantArray[0, maximumWeight + 1];
  scalarCounts = ConstantArray[0, maximumWeight + 1];
  Do[
    states = {{{}, first[[2]]}};
    Do[
      totalWeight = Length[first[[1]]] + secondWeight;
      Do[
        If[! observableTransportZeroMatrixQ[state[[2]]],
          AppendTo[output, {first[[1]], state[[1]], state[[2]]}];
          counts[[totalWeight + 1]]++;
          scalarCounts[[totalWeight + 1]] +=
            Count[Flatten[state[[2]]],
              x_ /; ! observableTransportZeroQ[x]]
        ],
        {state, states}
      ];
      If[totalWeight < maximumWeight,
        children = Flatten[Table[
          With[{child = state[[2]] . matrices[[a]]},
            If[observableTransportZeroMatrixQ[child], Nothing,
              {Append[state[[1]], a], child}]],
          {state, states}, {a, Length[matrices]}], 1],
        children = {}
      ];
      states = children,
      {secondWeight, 0, maximumWeight - Length[first[[1]]]}
    ],
    {first, firstMaps}
  ];
  <|"Maps" -> output, "MapCountsByWeight" -> counts,
    "ScalarCountsByWeight" -> scalarCounts|>
];

Options[BuildObservableTransport] = {
  "MaximumWeight" -> Automatic,
  "ClosureSteps" -> Automatic,
  "RankSamples" -> Automatic,
  "ResidueSamples" -> Automatic,
  "Verbose" -> False
};

BuildObservableTransport[record_Association, demand_Association,
    OptionsPattern[]] := Catch@Module[
  {status, variables, eps, dimension, ranges, tTotal, tInverse,
   epsConnections, letters, physicalDemandPairs, physicalRows,
   physicalOrders, valuation,
   path, firstVariable, secondVariable, firstBase, secondBase,
   firstTargetSample, tau, rankSamples, residueSamples, tmin,
   blockLower, rowLower, blockOfRow, pathRules, tangent,
   firstConnection, secondConnection, propagatedLower, stateRowLower,
   flow, forbiddenFHigh, forbiddenPhysicalOrders, slots, positions,
   boundarySlots, boundaryPositions, embedding, lifted, tLaurent,
   forbiddenRows, forbiddenLabels, forbiddenMap, pivots, basis, frontier,
   constraints, closureHistory, closureSteps, covariant, candidate,
   newPivots, constraintMatrix, constraintPivots, constraintRank,
   boundaryKernel, extendedFHigh, extendedSlots, extendedPositions,
   extendedBoundarySlots, newBoundarySlots, constrainedBoundary,
   unconstrainedColumns, tDemandLaurent, demandedRows, physicalLabels,
   physicalDemand, physicalOrder, component,
   demandedMap, residueRecord, firstKernelRecord, liftedResidues,
   pathActiveLetters, firstKernelIndices, firstKernelMethod,
   maximumWeight, wordRecord,
   nextStates, liftedSecond, boundaryDerivative, inducedRhs, pivotRows,
   pivotSquare, inducedConnection, inducedResidual, kernelRecord,
   secondRecord, verbose, start, recordExactQ, stabilized,
   constrainedRules, kernelColumns, coefficientField},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
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
      covariant = observableTransportCancelMatrix[D[frontier, tau] +
        frontier . lifted];
      candidate = Join[basis, covariant];
      pivots = observableTransportIndependentRows[candidate,
        First[rankSamples]];
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
      {closureSteps}];
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
    boundaryKernel = observableTransportKernel[constraintMatrix];
    If[! observableTransportZeroMatrixQ[constraintMatrix . boundaryKernel],
      Return[<|"Status" -> "BoundaryKernelIdentityFailed"|>, Module]
    ]
  ];

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
  wordRecord = observableTransportWordMaps[
    liftedResidues, constrainedBoundary, demandedMap, maximumWeight];
  wordRecord["Maps"] = ({firstKernelIndices[[#[[1]]]], #[[2]]} &) /@
    wordRecord["Maps"];

  secondConnection = observableTransportCancelMatrix[
    (epsConnections[[FirstPosition[variables, secondVariable][[1]]]]/eps) /.
      firstVariable -> firstBase];
  liftedSecond = First@observableTransportLiftResidues[
    {secondConnection}, extendedSlots];
  boundaryDerivative = D[Normal[constrainedBoundary], secondVariable];
  inducedRhs = observableTransportCancelMatrix[
    liftedSecond . constrainedBoundary - boundaryDerivative];
  pivotRows = observableTransportIndependentRows[
    Normal[constrainedBoundary],
    {secondVariable -> secondBase}];
  If[pivotRows === $Failed || Length[pivotRows] =!= Dimensions[constrainedBoundary][[2]],
    Return[<|"Status" -> "BoundaryEmbeddingRankFailed"|>, Module]
  ];
  pivotSquare = Normal[constrainedBoundary][[pivotRows]];
  inducedConnection = observableTransportCancelMatrix[
    LinearSolve[pivotSquare, inducedRhs[[pivotRows]]]];
  inducedResidual = observableTransportCancelMatrix[
    constrainedBoundary . inducedConnection - inducedRhs];
  If[! observableTransportZeroMatrixQ[inducedResidual],
    Return[<|"Status" -> "BoundarySubspaceNotInvariant"|>, Module]
  ];
  kernelRecord = If[coefficientField === "Multiquadratic",
    observableTransportEntryKernels[inducedConnection],
    observableTransportKernelDecomposition[
      inducedConnection, secondVariable]
  ];
  If[Lookup[kernelRecord, "Status", None] =!= "Exact",
    Return[kernelRecord, Module]
  ];
  secondRecord = observableTransportSecondSegmentMaps[
    wordRecord["Maps"], kernelRecord["Matrices"], maximumWeight];

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
    "BoundaryCoordinates" -> Dimensions[constrainedBoundary][[2]],
    "ConstraintRank" -> constraintRank,
    "DualClosureRankHistory" -> closureHistory,
    "FirstSegmentKernelMethod" -> firstKernelMethod,
    "FirstSegmentKernels" -> firstKernelRecord["Kernels"],
    "FirstSegmentKernelMatrices" -> firstKernelRecord["Matrices"],
    "DLogLetters" -> If[AssociationQ[residueRecord],
      residueRecord["Letters"], {}],
    "DLogResidues" -> If[AssociationQ[residueRecord],
      residueRecord["Residues"], {}],
    "FirstSegmentActiveLetters" -> pathActiveLetters,
    "FirstSegmentWordMaps" -> wordRecord["Maps"],
    "FirstSegmentStateCountsByWeight" -> wordRecord["StateCountsByWeight"],
    "FirstSegmentMapCountsByWeight" -> wordRecord["MapCountsByWeight"],
    "SecondSegmentKernels" -> kernelRecord["Kernels"],
    "SecondSegmentKernelMatrices" -> kernelRecord["Matrices"],
    "SecondSegmentKernelMethod" -> Lookup[kernelRecord, "Method",
      "RationalKernelDecomposition"],
    "TwoSegmentWordMaps" -> secondRecord["Maps"],
    "TwoSegmentMapCountsByWeight" -> secondRecord["MapCountsByWeight"],
    "Certificates" -> <|
      "FamilyEpsilonFormExact" -> True,
      "BoundaryKernel" -> True,
      "FirstKernelIdentity" -> True,
      "BoundarySubspaceInvariant" -> True,
      "SecondKernelIdentity" -> True|>,
    "MaximumWeight" -> maximumWeight,
    "Seconds" -> AbsoluteTime[] - start
  |>
];
