(* ::Package:: *)

BeginPackage["FACETRoutePrototype`"];

CheckExactConnection::usage =
  "CheckExactConnection[data] checks the zero-curvature equations of an exact rational differential connection.";

ValidateRationalConnectionField::usage =
  "ValidateRationalConnectionField[data] verifies that every connection entry is an exact rational function of the declared variables, parameters and regulator, with optional polynomial kinematic relations.";

ConnectionSingularDivisorCensus::usage =
  "ConnectionSingularDivisorCensus[data] factors the exact denominators of a rational differential connection and reports the pole order of every irreducible divisor in the current basis.";

ConnectionOneFormRank::usage =
  "ConnectionOneFormRank[data] computes the exact rational rank of the span of the connection matrices viewed as one-form coefficients.";

ConnectionResidueSpectra::usage =
  "ConnectionResidueSpectra[data] computes exact residue matrices and characteristic polynomials on logarithmic divisors that are linear in at least one kinematic variable.";

FindSingleInvariantConnection::usage =
  "FindSingleInvariantConnection[data] tests whether a two-variable connection is the pullback of one exact one-variable system and derives the invariant when possible.";

ExpressConnectionInInvariantField::usage =
  "ExpressConnectionInInvariantField[generator,invariant,{x,y},z] reconstructs every entry of an exact rational connection generator in Q(z), verifies the reconstruction after z->invariant, and distinguishes rational from merely algebraic dependence.";

BuildCyclicScalarOperator::usage =
  "BuildCyclicScalarOperator[matrix,variable,covector] converts a first-order system to one exactly equivalent scalar differential equation.";

FindCyclicScalarOperator::usage =
  "FindCyclicScalarOperator[matrix,variable] tests deterministic coordinate covectors and returns the smallest exact scalar equation found.";

ClassifySecondOrderScalarOperator::usage =
  "ClassifySecondOrderScalarOperator[operator,variable] classifies an exactly reconstructed second-order scalar equation by its finite singular points, Fuchsian pole bounds, local indicial polynomials, and behavior at infinity.";

GaussHypergeometricParameters::usage =
  "GaussHypergeometricParameters[classification,variable] derives and exactly verifies the Gauss 2F1 coordinate, gauge powers, and parameters for a three-singularity second-order Fuchsian equation.";

ConstructGaussSolutionBasis::usage =
  "ConstructGaussSolutionBasis[gaussData,variable] constructs the two exact local Gauss 2F1 solutions and their Wronskian certificate from exactly reconstructed hypergeometric data.";

ConstructDlogEpsilonTransport::usage =
  "ConstructDlogEpsilonTransport[kernel,variable,regulator,maxWeight] constructs and exactly verifies the iterated-integral transport of dJ=regulator kernel J through maxWeight, using PolyLogTools and a tangential base point at zero.";

DeriveParametricPeriodAnnihilator::usage =
  "DeriveParametricPeriodAnnihilator[data] derives exact differential operators for a product of polynomial powers and eliminates the declared integration variables with Singular D-module direct image. It does not determine the physical integration cycle or boundary constants.";

AnalyzeMasterAnalyticRoute::usage =
  "AnalyzeMasterAnalyticRoute[data] performs exact connection, variable-reduction and scalar-operator diagnostics and returns the next analytic construction to attempt.";

AnalyzePhysicalBlockNeed::usage =
  "AnalyzePhysicalBlockNeed[blockID,catalogue,physicalBasis,boundaryMap] determines whether a differential block contains physical masters, finds physical members of its exact connection orbit, and reports which of those masters already have boundary records.";

Begin["`Private`"];

ClearAll[
  rat,
  matrixMap,
  vectorMap,
  exactZeroQ,
  firstNonzeroPosition,
  exactZeroModuloIdealQ,
  polynomialRemainderModuloIdeal
];

rat[expr_] := Cancel[Together[expr]];
matrixMap[f_, matrix_] := Map[f, matrix, {2}];
vectorMap[f_, vector_] := Map[f, vector];
exactZeroQ[expr_] := And @@ (TrueQ[rat[#] === 0] & /@ Flatten[{expr}]);

ClearAll[
  simpleSingularSymbolQ,
  singularName,
  singularRingString,
  singularExpressionString,
  singularMarkerRecords,
  runSingularScript
];

simpleSingularSymbolQ[symbol_Symbol] := StringMatchQ[
  SymbolName[Unevaluated[symbol]],
  RegularExpression["[A-Za-z][A-Za-z0-9_]*"]
];
simpleSingularSymbolQ[_] := False;

singularName[symbol_Symbol] := SymbolName[Unevaluated[symbol]];
singularName[name_String] := name;

singularRingString[
  parameters_List,
  variables_List,
  ordering_String : "dp",
  ringName_String : "coefficientRing"
] :=
  "ring " <> ringName <> " = " <>
    If[parameters === {}, "0", "(0," <> StringRiffle[singularName /@ parameters, ","] <> ")"] <>
    ",(" <> StringRiffle[singularName /@ variables, ","] <> ")," <> ordering <> ";";

singularExpressionString[expression_] := ToString[
  Unevaluated[expression],
  InputForm,
  CharacterEncoding -> "ASCII"
];

singularMarkerRecords[output_String, begin_String, end_String] :=
  StringTrim /@ StringCases[
    output,
    begin ~~ Shortest[record__] ~~ end :> record
  ];

runSingularScript[
  executable_String,
  script_String,
  timeLimit_?NumericQ,
  keepTemporaryFiles_
] := Module[{directory, path, timing, process, result},
  directory = CreateDirectory[];
  path = FileNameJoin[{directory, "FACETDModule.sing"}];
  Export[path, script, "Text"];
  {timing, process} = AbsoluteTiming@TimeConstrained[
    RunProcess[{executable, "-q", path}],
    timeLimit,
    $Aborted
  ];
  result = Which[
    process === $Aborted,
      <|"State" -> "TimeLimitExceeded", "ElapsedSeconds" -> timing|>,
    ! AssociationQ[process],
      <|"State" -> "ProcessFailure", "ElapsedSeconds" -> timing|>,
    Lookup[process, "ExitCode", 1] =!= 0,
      <|
        "State" -> "SingularError",
        "ElapsedSeconds" -> timing,
        "StandardOutput" -> Lookup[process, "StandardOutput", ""],
        "StandardError" -> Lookup[process, "StandardError", ""]
      |>,
    True,
      <|
        "State" -> "Completed",
        "ElapsedSeconds" -> timing,
        "StandardOutput" -> Lookup[process, "StandardOutput", ""],
        "StandardError" -> Lookup[process, "StandardError", ""]
      |>
  ];
  If[TrueQ[keepTemporaryFiles],
    AssociateTo[result, "TemporaryDirectory" -> directory],
    Quiet@DeleteDirectory[directory, DeleteContents -> True]
  ];
  result
];

DeriveParametricPeriodAnnihilator::data =
  "The input must declare PolynomialFactors, Exponents, IntegrationVariables, KinematicVariables and Parameters.";
DeriveParametricPeriodAnnihilator::symbols =
  "Variables and parameters must be distinct ASCII symbols accepted by Singular; undeclared symbols are not allowed.";
DeriveParametricPeriodAnnihilator::factors =
  "Every factor must be polynomial in the integration and kinematic variables, with coefficients rational in the declared parameters.";
DeriveParametricPeriodAnnihilator::exponents =
  "Each exponent must be an exact rational function of the declared parameters and independent of all integration and kinematic variables.";
DeriveParametricPeriodAnnihilator::singular =
  "The Singular calculation failed at stage `1`.";
DeriveParametricPeriodAnnihilator::parse =
  "The Singular output could not be parsed at stage `1`.";

Options[DeriveParametricPeriodAnnihilator] = {
  "SingularExecutable" -> Automatic,
  "TimeLimit" -> 120,
  "KeepTemporaryFiles" -> False
};

DeriveParametricPeriodAnnihilator[
  data_Association,
  OptionsPattern[]
] := Module[
  {
    factors, exponents, integrationVariables, kinematicVariables,
    parameters, polynomialVariables, declaredSymbols, expressionSymbols,
    undeclaredSymbols, derivativeNames, singularExecutable, timeLimit,
    keepTemporaryFiles, factorFractions, validFactors, validExponents,
    sourceScript, sourceRun, integrandOperators, exponentRules,
    mappedIntegrandOperators, allVariables, variableCount,
    commutatorEntries, integrationMask, integrationScript,
    integrationRun, periodOperators
  },
  factors = Lookup[data, "PolynomialFactors", Missing["PolynomialFactors"]];
  exponents = Lookup[data, "Exponents", Missing["Exponents"]];
  integrationVariables = Lookup[
    data,
    "IntegrationVariables",
    Missing["IntegrationVariables"]
  ];
  kinematicVariables = Lookup[
    data,
    "KinematicVariables",
    Missing["KinematicVariables"]
  ];
  parameters = Lookup[data, "Parameters", Missing["Parameters"]];
  If[
    ! And[
      ListQ[factors], ListQ[exponents],
      ListQ[integrationVariables], ListQ[kinematicVariables],
      ListQ[parameters], factors =!= {},
      Length[factors] === Length[exponents],
      integrationVariables =!= {}
    ],
    Message[DeriveParametricPeriodAnnihilator::data];
    Return[$Failed]
  ];
  polynomialVariables = Join[integrationVariables, kinematicVariables];
  declaredSymbols = Join[polynomialVariables, parameters];
  derivativeNames = ("D" <> SymbolName[#]) & /@ polynomialVariables;
  If[
    ! DuplicateFreeQ[declaredSymbols] ||
      ! And @@ (simpleSingularSymbolQ /@ declaredSymbols) ||
      ! DuplicateFreeQ[Join[SymbolName /@ declaredSymbols, derivativeNames]],
    Message[DeriveParametricPeriodAnnihilator::symbols];
    Return[$Failed]
  ];
  expressionSymbols = DeleteDuplicates@Cases[
    Join[factors, exponents],
    symbol_Symbol /; Context[Unevaluated[symbol]] =!= "System`",
    Infinity
  ];
  undeclaredSymbols = Select[
    expressionSymbols,
    ! MemberQ[declaredSymbols, #] &
  ];
  If[undeclaredSymbols =!= {},
    Message[DeriveParametricPeriodAnnihilator::symbols];
    Return[$Failed]
  ];
  factorFractions = Together /@ factors;
  validFactors = And @@ Map[
    Function[fraction,
      ! TrueQ[Numerator[fraction] === 0] &&
        PolynomialQ[Numerator[fraction], polynomialVariables] &&
        FreeQ[Denominator[fraction], Alternatives @@ polynomialVariables] &&
        If[parameters === {},
          NumericQ[Denominator[fraction]],
          PolynomialQ[Numerator[Together[Denominator[fraction]]], parameters] &&
            PolynomialQ[Denominator[Together[Denominator[fraction]]], parameters]
        ]
    ],
    factorFractions
  ];
  If[! TrueQ[validFactors],
    Message[DeriveParametricPeriodAnnihilator::factors];
    Return[$Failed]
  ];
  validExponents = And @@ Map[
    Function[exponent,
      FreeQ[exponent, Alternatives @@ polynomialVariables] &&
        FreeQ[exponent, _Real] &&
        If[parameters === {},
          NumericQ[exponent],
          PolynomialQ[Numerator[Together[exponent]], parameters] &&
            PolynomialQ[Denominator[Together[exponent]], parameters]
        ]
    ],
    exponents
  ];
  If[! TrueQ[validExponents],
    Message[DeriveParametricPeriodAnnihilator::exponents];
    Return[$Failed]
  ];
  singularExecutable = Replace[
    OptionValue["SingularExecutable"],
    Automatic :> FindExecutable["Singular"]
  ];
  If[! StringQ[singularExecutable] || ! FileExistsQ[singularExecutable],
    Message[DeriveParametricPeriodAnnihilator::singular, "executable discovery"];
    Return[$Failed]
  ];
  timeLimit = OptionValue["TimeLimit"];
  keepTemporaryFiles = TrueQ[OptionValue["KeepTemporaryFiles"]];
  sourceScript = StringRiffle[
    {
      "LIB \"dmodideal.lib\";",
      singularRingString[parameters, polynomialVariables, "dp", "sourceRing"],
      "ideal factors = " <>
        StringRiffle[singularExpressionString /@ factorFractions, ","] <> ";",
      "def symbolicRing = annihilatorMultiFs(factors);",
      "setring symbolicRing;",
      "int facetIndex;",
      "for (facetIndex=1; facetIndex<=size(annFs); facetIndex++) {",
      "  print(\"__FACET_ANN_BEGIN__\");",
      "  print(annFs[facetIndex]);",
      "  print(\"__FACET_ANN_END__\");",
      "}",
      "quit;"
    },
    "\n"
  ];
  sourceRun = runSingularScript[
    singularExecutable,
    sourceScript,
    timeLimit,
    keepTemporaryFiles
  ];
  If[Lookup[sourceRun, "State", ""] =!= "Completed",
    Message[DeriveParametricPeriodAnnihilator::singular, "integrand annihilator"];
    Return[<|"State" -> "IntegrandAnnihilatorFailed", "Process" -> sourceRun|>]
  ];
  integrandOperators = singularMarkerRecords[
    sourceRun["StandardOutput"],
    "__FACET_ANN_BEGIN__",
    "__FACET_ANN_END__"
  ];
  If[integrandOperators === {},
    Message[DeriveParametricPeriodAnnihilator::parse, "integrand annihilator"];
    Return[<|"State" -> "IntegrandAnnihilatorParseFailed", "Process" -> sourceRun|>]
  ];
  exponentRules = MapIndexed[
    "s(" <> ToString[First[#2]] <> ")" ->
      "(" <> singularExpressionString[#1] <> ")" &,
    exponents
  ];
  mappedIntegrandOperators = StringReplace[integrandOperators, exponentRules];
  allVariables = polynomialVariables;
  variableCount = Length[allVariables];
  commutatorEntries = Table[
    "commutators[" <> ToString[index] <> "," <>
      ToString[variableCount + index] <> "] = 1;",
    {index, variableCount}
  ];
  integrationMask = Join[
    ConstantArray[1, Length[integrationVariables]],
    ConstantArray[0, Length[kinematicVariables]]
  ];
  integrationScript = StringRiffle[
    Join[
      {
        "LIB \"dmodapp.lib\";",
        singularRingString[
          parameters,
          Join[allVariables, derivativeNames],
          "dp",
          "coefficientRing"
        ],
        "matrix commutators[" <> ToString[2 variableCount] <> "][" <>
          ToString[2 variableCount] <> "];"
      },
      commutatorEntries,
      {
        "def weylRing = nc_algebra(1,commutators);",
        "setring weylRing;",
        "ideal integrandAnnihilator = " <>
          StringRiffle[mappedIntegrandOperators, ","] <> ";",
        "intvec integrationMask = " <>
          StringRiffle[ToString /@ integrationMask, ","] <> ";",
        "def resultRing = integralIdeal(integrandAnnihilator,integrationMask);",
        "setring resultRing;",
        "ideal periodAnnihilator = std(intIdeal);",
        "int facetIndex;",
        "for (facetIndex=1; facetIndex<=size(periodAnnihilator); facetIndex++) {",
        "  print(\"__FACET_PERIOD_BEGIN__\");",
        "  print(periodAnnihilator[facetIndex]);",
        "  print(\"__FACET_PERIOD_END__\");",
        "}",
        "quit;"
      }
    ],
    "\n"
  ];
  integrationRun = runSingularScript[
    singularExecutable,
    integrationScript,
    timeLimit,
    keepTemporaryFiles
  ];
  If[Lookup[integrationRun, "State", ""] =!= "Completed",
    Message[DeriveParametricPeriodAnnihilator::singular, "direct image"];
    Return[<|
      "State" -> "DirectImageFailed",
      "IntegrandAnnihilatorStrings" -> integrandOperators,
      "Process" -> integrationRun
    |>]
  ];
  periodOperators = singularMarkerRecords[
    integrationRun["StandardOutput"],
    "__FACET_PERIOD_BEGIN__",
    "__FACET_PERIOD_END__"
  ];
  If[periodOperators === {},
    Message[DeriveParametricPeriodAnnihilator::parse, "direct image"];
    Return[<|
      "State" -> "DirectImageParseFailed",
      "IntegrandAnnihilatorStrings" -> integrandOperators,
      "Process" -> integrationRun
    |>]
  ];
  <|
    "State" -> "ExactIntegrationIdealDerived",
    "PolynomialFactors" -> factors,
    "Exponents" -> exponents,
    "IntegrationVariables" -> integrationVariables,
    "KinematicVariables" -> kinematicVariables,
    "Parameters" -> parameters,
    "DerivativeNames" -> AssociationThread[allVariables, derivativeNames],
    "IntegrandAnnihilatorStrings" -> integrandOperators,
    "PeriodAnnihilatorStrings" -> periodOperators,
    "ElapsedSeconds" -> <|
      "IntegrandAnnihilator" -> sourceRun["ElapsedSeconds"],
      "DirectImage" -> integrationRun["ElapsedSeconds"]
    |>,
    "PhysicalCycleDetermined" -> False,
    "EndpointTermsDetermined" -> False,
    "BoundaryConstantsDetermined" -> False,
    "Interpretation" ->
      "The returned integration ideal annihilates the algebraic period whenever boundary terms vanish or are incorporated in a relative-cycle formulation; it does not select the positive-energy cut cycle."
  |>
];

firstNonzeroPosition[matrix_] := Module[{positions},
  positions = Select[
    Flatten[Table[{i, j}, {i, Length[matrix]}, {j, Length[matrix]}], 1],
    ! exactZeroQ[matrix[[#[[1]], #[[2]]]]] &
  ];
  If[positions === {},
    Missing["ZeroMatrix"],
    First@SortBy[
      positions,
      {LeafCount[rat[matrix[[#[[1]], #[[2]]]]]] &, Identity}
    ]
  ]
];

polynomialRemainderModuloIdeal[polynomial_, ideal_List, variables_List] := Module[
  {basis},
  If[ideal === {}, Return[Expand[polynomial]]];
  basis = GroebnerBasis[ideal, variables];
  Last[PolynomialReduce[Expand[polynomial], basis, variables]]
];

exactZeroModuloIdealQ[expression_, ideal_List, variables_List] := Module[
  {fraction, numerator, denominator, numeratorRemainder, denominatorRemainder},
  If[ideal === {}, Return[exactZeroQ[expression]]];
  fraction = rat[expression];
  numerator = Numerator[fraction];
  denominator = Denominator[fraction];
  If[
    ! PolynomialQ[numerator, variables] || ! PolynomialQ[denominator, variables],
    Return[False]
  ];
  numeratorRemainder = polynomialRemainderModuloIdeal[numerator, ideal, variables];
  denominatorRemainder = polynomialRemainderModuloIdeal[denominator, ideal, variables];
  TrueQ[Expand[numeratorRemainder] === 0] &&
    ! TrueQ[Expand[denominatorRemainder] === 0]
];

ClearAll[exactMemberQ, exactIntersection, exactComplement];

exactMemberQ[list_List, item_] := AnyTrue[list, SameQ[#, item] &];
exactIntersection[left_List, right_List] := Select[left, exactMemberQ[right, #] &];
exactComplement[left_List, right_List] := Select[left, ! exactMemberQ[right, #] &];

ClearAll[
  canonicalPolynomial,
  denominatorFactorOrders,
  mergeFactorOrders,
  matrixFactorOrders,
  factorOrder
];

canonicalPolynomial[polynomial_] := Module[
  {expanded, variables, rules, leadingCoefficient},
  expanded = Expand[polynomial];
  variables = Variables[expanded];
  If[variables === {}, Return[1]];
  rules = CoefficientRules[expanded, variables];
  If[rules === {}, Return[1]];
  leadingCoefficient = Last[First[rules]];
  Factor[Cancel[expanded/leadingCoefficient]]
];

denominatorFactorOrders[expression_] := Module[{denominator, factors},
  denominator = Denominator[rat[expression]];
  If[NumericQ[denominator], Return[{}]];
  factors = Quiet@FactorList[denominator];
  If[! ListQ[factors], Return[{}]];
  Map[
    {canonicalPolynomial[First[#]], Last[#]} &,
    Select[factors, ! NumericQ[First[#]] && Last[#] > 0 &]
  ]
];

mergeFactorOrders[records_List] := Map[
  {First[First[#]], Max[#[[All, 2]]]} &,
  GatherBy[records, First]
];

matrixFactorOrders[matrix_?MatrixQ] := mergeFactorOrders[
  Flatten[denominatorFactorOrders /@ Flatten[matrix], 1]
];

factorOrder[records_List, divisor_] := Module[{orders},
  orders = Cases[records, {factor_, order_} /; SameQ[factor, divisor] :> order];
  If[orders === {}, 0, Max[orders]]
];

ConnectionSingularDivisorCensus[data_Association] := Module[
  {variables, matrices, regulator, ordersByVariable, divisors, records},
  variables = Lookup[data, "Variables", Missing["Variables"]];
  matrices = Lookup[data, "Matrices", Missing["Matrices"]];
  regulator = Lookup[data, "Regulator", Missing["Regulator"]];
  If[! ListQ[variables] || ! AssociationQ[matrices] ||
      ! And @@ (KeyExistsQ[matrices, #] & /@ variables),
    Return[$Failed]
  ];
  ordersByVariable = Association@Table[
    variable -> matrixFactorOrders[matrices[variable]],
    {variable, variables}
  ];
  divisors = DeleteDuplicates@Flatten[
    Map[First, Values[ordersByVariable], {2}]
  ];
  records = Map[
    Function[divisor,
      With[
        {orders = Association@Table[
          variable -> factorOrder[ordersByVariable[variable], divisor],
          {variable, variables}
        ]},
        <|
          "Polynomial" -> divisor,
          "DifferentialPoleOrders" -> orders,
          "MaximumPoleOrder" -> Max[Values[orders]],
          "LogarithmicInCurrentBasis" -> Max[Values[orders]] <= 1,
          "Kind" -> Which[
            ! FreeQ[divisor, Alternatives @@ variables], "Kinematic",
            ! MissingQ[regulator] && ! FreeQ[divisor, regulator],
              "RegulatorOnly",
            True, "ParameterOnly"
          ]
        |>
      ]
    ],
    SortBy[divisors, ToString[InputForm[#]] &]
  ];
  <|
    "Divisors" -> records,
    "KinematicDivisors" ->
      With[{selected = Select[records, #["Kind"] === "Kinematic" &]},
        If[selected === {}, {}, Lookup[selected, "Polynomial"]]
      ],
    "RegulatorOnlyDivisors" ->
      With[{selected = Select[records, #["Kind"] === "RegulatorOnly" &]},
        If[selected === {}, {}, Lookup[selected, "Polynomial"]]
      ],
    "MaximumPoleOrder" -> If[records === {}, 0, Max[Lookup[records, "MaximumPoleOrder"]]]
  |>
];

ConnectionOneFormRank[data_Association] := Module[
  {variables, matrices, nonzeroVariables, vectors, rank, relations},
  variables = Lookup[data, "Variables", Missing["Variables"]];
  matrices = Lookup[data, "Matrices", Missing["Matrices"]];
  If[! ListQ[variables] || ! AssociationQ[matrices] ||
      ! And @@ (KeyExistsQ[matrices, #] & /@ variables),
    Return[$Failed]
  ];
  nonzeroVariables = Select[variables, ! exactZeroQ[matrices[#]] &];
  vectors = (Flatten[matrixMap[rat, matrices[#]]] &) /@ nonzeroVariables;
  rank = If[vectors === {}, 0, MatrixRank[vectors]];
  relations = If[vectors === {}, IdentityMatrix[Length[variables]],
    NullSpace[Transpose[vectors]]];
  <|
    "Rank" -> rank,
    "VariableCount" -> Length[variables],
    "NonzeroVariables" -> nonzeroVariables,
    "DirectRankOneInCurrentBasis" -> TrueQ[rank == 1],
    "ExactRelationsAmongNonzeroMatrices" -> relations
  |>
];

ConnectionResidueSpectra[data_Association] := Module[
  {variables, matrices, census, divisors, lambda},
  variables = Lookup[data, "Variables", Missing["Variables"]];
  matrices = Lookup[data, "Matrices", Missing["Matrices"]];
  If[! ListQ[variables] || ! AssociationQ[matrices], Return[$Failed]];
  census = ConnectionSingularDivisorCensus[data];
  If[census === $Failed, Return[$Failed]];
  divisors = Lookup[census, "Divisors", {}];
  Map[
    Function[record,
      Module[{divisor, coordinate, root, residue, polynomial},
        divisor = record["Polynomial"];
        coordinate = SelectFirst[
          variables,
          Exponent[divisor, #] == 1 && ! exactZeroQ[D[divisor, #]] &,
          Missing["NoLinearCoordinate"]
        ];
        If[! TrueQ[record["LogarithmicInCurrentBasis"]] || MissingQ[coordinate],
          Return[Join[record, <|
            "ResidueState" -> If[MissingQ[coordinate],
              "DivisorNotLinearInAvailableCoordinates",
              "ConnectionNotLogarithmicInCurrentBasis"]
          |>]]
        ];
        root = rat[coordinate /. First@Solve[divisor == 0, coordinate]];
        residue = matrixMap[
          Function[entry,
            rat[rat[divisor entry/D[divisor, coordinate]] /. coordinate -> root]
          ],
          matrices[coordinate]
        ];
        polynomial = Factor[CharacteristicPolynomial[residue, lambda]];
        Join[record, <|
          "ResidueState" -> "ExactResidueComputed",
          "TransverseCoordinate" -> coordinate,
          "DivisorRoot" -> root,
          "ResidueMatrix" -> residue,
          "CharacteristicPolynomial" -> polynomial
        |>]
      ]
    ],
    divisors
  ]
];

ClearAll[
  heldNonSystemSymbols,
  inexactNumbers,
  forbiddenExactConstants,
  connectionEntryFieldRecord
];

heldNonSystemSymbols[expression_] := DeleteDuplicates@Cases[
  HoldComplete[expression],
  symbol_Symbol /; Context[Unevaluated[symbol]] =!= "System`",
  {0, Infinity},
  Heads -> True
];

inexactNumbers[expression_] := DeleteDuplicates@Cases[
  HoldComplete[expression],
  number_?NumberQ /; Precision[number] =!= Infinity,
  {0, Infinity},
  Heads -> True
];

forbiddenExactConstants[expression_] := DeleteDuplicates@Cases[
  HoldComplete[expression],
  Pi | E | EulerGamma | Catalan | GoldenRatio,
  {0, Infinity},
  Heads -> True
];

connectionEntryFieldRecord[
  expression_,
  allowedSymbols_List,
  ideal_List,
  idealVariables_List
] := Module[
  {fraction, numerator, denominator, undeclared, inexact, constants,
   numeratorPolynomial, denominatorPolynomial, denominatorRemainder,
   denominatorNonzero},
  fraction = Quiet@Check[rat[expression], $Failed];
  undeclared = exactComplement[heldNonSystemSymbols[expression], allowedSymbols];
  inexact = inexactNumbers[expression];
  constants = exactComplement[forbiddenExactConstants[expression], allowedSymbols];
  If[fraction === $Failed,
    Return[<|
      "Expression" -> expression,
      "RationalInDeclaredField" -> False,
      "Reason" -> "Together or cancellation failed"
    |>]
  ];
  numerator = Numerator[fraction];
  denominator = Denominator[fraction];
  numeratorPolynomial = PolynomialQ[numerator, allowedSymbols];
  denominatorPolynomial = PolynomialQ[denominator, allowedSymbols];
  denominatorRemainder = If[denominatorPolynomial,
    Quiet@Check[
      polynomialRemainderModuloIdeal[denominator, ideal, idealVariables],
      $Failed
    ],
    $Failed
  ];
  denominatorNonzero = denominatorRemainder =!= $Failed &&
    ! TrueQ[Expand[denominatorRemainder] === 0];
  <|
    "Expression" -> expression,
    "UndeclaredSymbols" -> undeclared,
    "InexactNumbers" -> inexact,
    "ForbiddenExactConstants" -> constants,
    "NumeratorPolynomial" -> numeratorPolynomial,
    "DenominatorPolynomial" -> denominatorPolynomial,
    "DenominatorNonzeroModuloKinematicIdeal" -> denominatorNonzero,
    "RationalInDeclaredField" ->
      undeclared === {} && inexact === {} && constants === {} &&
      numeratorPolynomial && denominatorPolynomial && denominatorNonzero
  |>
];

ValidateRationalConnectionField[data_Association] := Module[
  {variables, parameters, regulator, matrices, allowedSymbols, ideal,
   idealVariables, declaredSymbolsValid, declaredSymbolsUnique,
   coordinatesMatchVariables, matrixStructure, idealPolynomial, records,
   valid},
  variables = Lookup[data, "Variables", Missing["Variables"]];
  parameters = Lookup[data, "Parameters", {}];
  regulator = Lookup[data, "Regulator", Missing["Regulator"]];
  matrices = Lookup[data, "Matrices", Missing["Matrices"]];
  If[
    ! ListQ[variables] || ! ListQ[parameters] || ! AssociationQ[matrices] ||
      MissingQ[regulator],
    Return[$Failed]
  ];
  allowedSymbols = DeleteDuplicates@Join[variables, parameters, {regulator}];
  declaredSymbolsValid = And @@ (MatchQ[#, _Symbol] & /@ allowedSymbols);
  declaredSymbolsUnique = Length[allowedSymbols] ===
    Length@Join[variables, parameters, {regulator}];
  coordinatesMatchVariables =
    exactComplement[variables, Keys[matrices]] === {} &&
    exactComplement[Keys[matrices], variables] === {};
  ideal = Flatten@{Lookup[data, "KinematicIdeal", {}]};
  idealVariables = Lookup[
    data,
    "KinematicIdealVariables",
    exactIntersection[allowedSymbols, heldNonSystemSymbols[ideal]]
  ];
  If[ideal =!= {} && idealVariables === {}, idealVariables = allowedSymbols];
  matrixStructure = And @@ (MatrixQ /@ Values[matrices]) &&
    And @@ (
      Function[matrix,
        With[{dimensions = Dimensions[matrix]},
          Length[dimensions] === 2 && dimensions[[1]] === dimensions[[2]]
        ]
      ] /@ Values[matrices]
    ) &&
    SameQ @@ (Dimensions /@ Values[matrices]);
  idealPolynomial = declaredSymbolsValid && ListQ[idealVariables] &&
    And @@ (MatchQ[#, _Symbol] & /@ idealVariables) &&
    And @@ (PolynomialQ[#, allowedSymbols] & /@ ideal) &&
    exactComplement[heldNonSystemSymbols[ideal], allowedSymbols] === {} &&
    inexactNumbers[ideal] === {} && forbiddenExactConstants[ideal] === {};
  records = If[
    declaredSymbolsValid && declaredSymbolsUnique &&
      coordinatesMatchVariables && matrixStructure && idealPolynomial,
    Flatten[
      Map[
        Function[coordinate,
          With[{matrix = matrices[coordinate]},
            Flatten@Table[
              Join[
                <|"Coordinate" -> coordinate, "Position" -> {i, j}|>,
                connectionEntryFieldRecord[
                  matrix[[i, j]], allowedSymbols, ideal, idealVariables
                ]
              ],
              {i, Length[matrix]}, {j, Length[matrix[[i]]]}
            ]
          ]
        ],
        Keys[matrices]
      ],
      1
    ],
    {}
  ];
  valid = declaredSymbolsValid && declaredSymbolsUnique &&
    coordinatesMatchVariables && matrixStructure && idealPolynomial &&
    records =!= {} &&
    And @@ (TrueQ[Lookup[#, "RationalInDeclaredField", False]] & /@ records);
  <|
    "Valid" -> valid,
    "AllowedSymbols" -> allowedSymbols,
    "KinematicIdeal" -> ideal,
    "KinematicIdealVariables" -> idealVariables,
    "DeclaredSymbolsValid" -> declaredSymbolsValid,
    "DeclaredSymbolsUnique" -> declaredSymbolsUnique,
    "CoordinatesMatchVariables" -> coordinatesMatchVariables,
    "MatrixStructureValid" -> matrixStructure,
    "KinematicIdealPolynomial" -> idealPolynomial,
    "EntryRecords" -> records
  |>
];

CheckExactConnection[data_Association] := Module[
  {variables, matrices, pairs, curvatures, fieldValidation, ideal,
   idealVariables, zeroChecks, dimension},
  variables = Lookup[data, "Variables", Missing["Variables"]];
  matrices = Lookup[data, "Matrices", Missing["Matrices"]];
  If[! ListQ[variables] || ! AssociationQ[matrices] ||
      ! And @@ (KeyExistsQ[matrices, #] & /@ variables),
    Return[$Failed]
  ];
  fieldValidation = ValidateRationalConnectionField[data];
  If[fieldValidation === $Failed || ! TrueQ[fieldValidation["Valid"]],
    Return[<|
      "Flat" -> False,
      "Reason" -> "The connection is not in the declared exact rational field",
      "FieldValidation" -> fieldValidation
    |>]
  ];
  ideal = fieldValidation["KinematicIdeal"];
  idealVariables = fieldValidation["KinematicIdealVariables"];
  dimension = First[Dimensions[First[Values[matrices]]]];
  pairs = Subsets[variables, {2}];
  curvatures = Association@Table[
    With[{x = pair[[1]], y = pair[[2]], ax = matrices[pair[[1]]], ay = matrices[pair[[2]]]},
      pair -> matrixMap[rat, D[ay, x] - D[ax, y] + ay . ax - ax . ay]
    ],
    {pair, pairs}
  ];
  zeroChecks = Map[
    Function[curvature,
      And @@ (
        exactZeroModuloIdealQ[#, ideal, idealVariables] & /@ Flatten[curvature]
      )
    ],
    curvatures
  ];
  <|
    "Dimension" -> dimension,
    "Curvatures" -> curvatures,
    "CurvatureZeroModuloKinematicIdeal" -> zeroChecks,
    "Flat" -> And @@ Values[zeroChecks],
    "FieldValidation" -> fieldValidation
  |>
];

ClearAll[polynomialFirstIntegral, firstIntegralFromPDE, invariantMatrix];

polynomialFirstIntegral[rho_, {x_, y_}, maxDegree_Integer] := Module[
  {fraction, numerator, denominator, degree, monomials, coefficients, ansatz,
   equation, rows, linearMatrix, nullspace, candidates, result},
  fraction = rat[rho];
  numerator = Numerator[fraction];
  denominator = Denominator[fraction];
  result = Missing["NoPolynomialFirstIntegralFoundWithinDegreeBound", maxDegree];
  Do[
    monomials = Flatten@Table[
      If[1 <= i + j <= degree, x^i y^j, Nothing],
      {i, 0, degree}, {j, 0, degree - i}
    ];
    coefficients = Table[Unique["routeCoefficient"], {Length[monomials]}];
    ansatz = coefficients . monomials;
    equation = Expand[denominator D[ansatz, y] - numerator D[ansatz, x]];
    If[TrueQ[equation === 0], result = First[monomials]; Break[]];
    rows = Values[CoefficientRules[equation, {x, y}]];
    linearMatrix = Normal[CoefficientArrays[rows, coefficients][[2]]];
    nullspace = NullSpace[linearMatrix];
    candidates = Map[
      Function[vector, rat[vector . monomials]],
      nullspace
    ];
    candidates = Select[
      candidates,
      Function[candidate,
        ! exactZeroQ[candidate] &&
          ! (exactZeroQ[D[candidate, x]] && exactZeroQ[D[candidate, y]])
      ]
    ];
    If[candidates =!= {},
      result = First@SortBy[candidates, LeafCount];
      Break[]
    ],
    {degree, 1, maxDegree}
  ];
  result
];

firstIntegralFromPDE[rho_, {x_, y_}, maxDegree_Integer] := Module[
  {polynomial},
  polynomial = polynomialFirstIntegral[rho, {x, y}, maxDegree];
  polynomial
];

invariantMatrix[matrix_, invariant_, {x_, y_}] := Module[
  {dx, dy, generator, reduced, tangentCheck},
  dx = rat[D[invariant, x]];
  dy = rat[D[invariant, y]];
  generator = Which[
    ! exactZeroQ[dx], matrixMap[rat[#/dx] &, matrix],
    ! exactZeroQ[dy], matrixMap[rat[#/dy] &, matrix],
    True, Return[$Failed]
  ];
  tangentCheck = matrixMap[
    rat,
    dy D[generator, x] - dx D[generator, y]
  ];
  reduced = <|
    "Generator" -> generator,
    "DependsOnlyOnInvariant" -> exactZeroQ[tangentCheck],
    "TangentDerivative" -> tangentCheck
  |>;
  reduced
];

Options[FindSingleInvariantConnection] = {
  "CandidateInvariants" -> {},
  "FindInvariant" -> True,
  "InvariantDegree" -> 4
};

FindSingleInvariantConnection[data_Association, OptionsPattern[]] := Module[
  {variables, matrices, x, y, ax, ay, pos, pivotEntry, pivotZeroDivisor,
   pivotPoleDivisor, rho, proportional, candidates, invariant, reduction,
   dx, dy, pullbackCheck, flatness},
  variables = Lookup[data, "Variables", {}];
  matrices = Lookup[data, "Matrices", <||>];
  If[Length[variables] =!= 2 || ! AssociationQ[matrices], Return[$Failed]];
  {x, y} = variables;
  {ax, ay} = Lookup[matrices, {x, y}, {Missing["Ax"], Missing["Ay"]}];
  If[! MatrixQ[ax] || ! MatrixQ[ay] || Dimensions[ax] =!= Dimensions[ay],
    Return[$Failed]
  ];
  flatness = CheckExactConnection[data];
  pos = firstNonzeroPosition[ax];
  If[MissingQ[pos],
    If[exactZeroQ[ay],
      Return[<|"OneVariable" -> False, "Reason" -> "Zero connection"|>],
      Return[<|
        "OneVariable" -> True,
        "Invariant" -> y,
        "Generator" -> ay,
        "PullbackCheck" -> True,
        "FlatConnection" -> TrueQ[flatness["Flat"]]
      |>]
    ]
  ];
  pivotEntry = rat[ax[[pos[[1]], pos[[2]]]]];
  pivotZeroDivisor = Factor[Numerator[pivotEntry]];
  pivotPoleDivisor = Factor[Denominator[pivotEntry]];
  rho = rat[ay[[pos[[1]], pos[[2]]]]/pivotEntry];
  proportional = exactZeroQ[matrixMap[rat, ay - rho ax]];
  If[! proportional,
    Return[<|
      "OneVariable" -> False,
      "ScalarProportionality" -> False,
      "RatioCandidate" -> rho,
      "PivotPosition" -> pos,
      "PivotEntry" -> pivotEntry,
      "PivotZeroDivisor" -> pivotZeroDivisor,
      "PivotPoleDivisor" -> pivotPoleDivisor,
      "FlatConnection" -> TrueQ[flatness["Flat"]]
    |>]
  ];
  candidates = DeleteDuplicates@Flatten@{
    OptionValue["CandidateInvariants"],
    If[TrueQ[OptionValue["FindInvariant"]],
      firstIntegralFromPDE[rho, variables, OptionValue["InvariantDegree"]],
      Nothing
    ]
  };
  candidates = Select[candidates,
    ! MissingQ[#] &&
      ! (exactZeroQ[D[#, x]] && exactZeroQ[D[#, y]]) &&
      exactZeroQ[rat[D[#, y] - rho D[#, x]]] &
  ];
  If[candidates === {},
    Return[<|
      "OneVariable" -> Undetermined,
      "ScalarProportionality" -> True,
      "Ratio" -> rho,
      "Reason" -> Missing[
        "NoPolynomialFirstIntegralFoundWithinDegreeBound",
        OptionValue["InvariantDegree"]
      ],
      "FlatConnection" -> TrueQ[flatness["Flat"]]
    |>]
  ];
  invariant = First@SortBy[candidates, LeafCount];
  reduction = invariantMatrix[ax, invariant, variables];
  dx = rat[D[invariant, x]];
  dy = rat[D[invariant, y]];
  pullbackCheck = exactZeroQ[matrixMap[rat, ax - dx reduction["Generator"]]] &&
    exactZeroQ[matrixMap[rat, ay - dy reduction["Generator"]]];
  <|
    "OneVariable" -> TrueQ[reduction["DependsOnlyOnInvariant"]] && pullbackCheck &&
      TrueQ[flatness["Flat"]],
    "Class" -> "DirectSingleInvariantPullbackInCurrentBasis",
    "ScalarProportionality" -> True,
    "Ratio" -> rho,
    "PivotPosition" -> pos,
    "PivotEntry" -> pivotEntry,
    "PivotZeroDivisor" -> pivotZeroDivisor,
    "PivotPoleDivisor" -> pivotPoleDivisor,
    "Invariant" -> invariant,
    "Generator" -> reduction["Generator"],
    "DependsOnlyOnInvariant" -> reduction["DependsOnlyOnInvariant"],
    "PullbackCheck" -> pullbackCheck,
    "FlatConnection" -> TrueQ[flatness["Flat"]]
  |>
];

BuildCyclicScalarOperator[matrix_?MatrixQ, variable_, covector_List] := Module[
  {dimension, rows, reconstruction, next, coefficients, determinant, check},
  dimension = Length[matrix];
  If[Dimensions[matrix] =!= {dimension, dimension} || Length[covector] =!= dimension,
    Return[$Failed]
  ];
  rows = {covector};
  Do[
    AppendTo[rows, vectorMap[rat, D[Last[rows], variable] + Last[rows] . matrix]],
    {dimension}
  ];
  reconstruction = Transpose[Take[rows, dimension]];
  determinant = rat[Det[reconstruction]];
  If[exactZeroQ[determinant],
    Return[<|"Cyclic" -> False, "Covector" -> covector|>]
  ];
  next = rows[[dimension + 1]];
  coefficients = vectorMap[rat, LinearSolve[reconstruction, next]];
  check = exactZeroQ[vectorMap[rat, next - coefficients . Take[rows, dimension]]];
  <|
    "Cyclic" -> check,
    "Order" -> dimension,
    "Covector" -> covector,
    "Coefficients" -> coefficients,
    "Equation" -> HoldForm[
      Derivative[dimension][y][variable] ==
        Sum[coefficients[[k + 1]] Derivative[k][y][variable], {k, 0, dimension - 1}]
    ],
    "ReconstructionMatrix" -> reconstruction,
    "Determinant" -> determinant,
    "ExactReconstruction" -> check,
    "Complexity" -> LeafCount[coefficients]
  |>
];

Options[FindCyclicScalarOperator] = {"TimeLimit" -> 300};

FindCyclicScalarOperator[matrix_?MatrixQ, variable_, OptionsPattern[]] := Module[
  {dimension, candidates, results},
  dimension = Length[matrix];
  candidates = Join[
    IdentityMatrix[dimension],
    Table[UnitVector[dimension, 1] + UnitVector[dimension, k], {k, 2, dimension}],
    {ConstantArray[1, dimension]}
  ];
  results = Table[
    TimeConstrained[
      BuildCyclicScalarOperator[matrix, variable, candidates[[k]]],
      OptionValue["TimeLimit"],
      <|"Cyclic" -> False, "Reason" -> "Time limit", "Covector" -> candidates[[k]]|>
    ],
    {k, Length[candidates]}
  ];
  results = Select[results, AssociationQ[#] && TrueQ[# ["Cyclic"]] &];
  If[results === {},
    <|"Cyclic" -> False, "Reason" -> "No tested covector was cyclic"|>,
    First@SortBy[results, {# ["Complexity"] &, First@FirstPosition[candidates, # ["Covector"]] &}]
  ]
];

ClearAll[
  scalarDenominatorFactors,
  scalarFactorOrder,
  localIndicialData,
  infinityIndicialData
];

scalarDenominatorFactors[expressions_List, variable_] := Module[
  {factors},
  factors = Flatten[
    Cases[
      Quiet@FactorList[Denominator[rat[#]]],
      {factor_, power_Integer} /;
          power > 0 && ! FreeQ[factor, variable] :>
        {canonicalPolynomial[factor], power}
    ] & /@ expressions,
    1
  ];
  DeleteDuplicates[First /@ factors]
];

scalarFactorOrder[expression_, factor_] := Module[{records},
  records = denominatorFactorOrders[expression];
  factorOrder[records, canonicalPolynomial[factor]]
];

localIndicialData[p_, q_, variable_, factor_] := Module[
  {roots, point, pOrder, qOrder, p0, q0, rho},
  roots = Quiet@Solve[factor == 0, variable];
  If[Exponent[factor, variable] =!= 1 || ! ListQ[roots] || roots === {},
    Return[<|
      "Factor" -> factor,
      "State" -> "NonlinearOrUnresolvedFiniteDivisor"
    |>]
  ];
  point = rat[variable /. First[roots]];
  pOrder = scalarFactorOrder[p, factor];
  qOrder = scalarFactorOrder[q, factor];
  If[pOrder > 1 || qOrder > 2,
    Return[<|
      "Factor" -> factor,
      "Point" -> point,
      "POrder" -> pOrder,
      "QOrder" -> qOrder,
      "State" -> "IrregularFiniteSingularity"
    |>]
  ];
  p0 = rat[Limit[(variable - point) p, variable -> point]];
  q0 = rat[Limit[(variable - point)^2 q, variable -> point]];
  <|
    "Factor" -> factor,
    "Point" -> point,
    "POrder" -> pOrder,
    "QOrder" -> qOrder,
    "P0" -> p0,
    "Q0" -> q0,
    "IndicialPolynomial" -> Factor[rho (rho - 1) + p0 rho + q0],
    "Exponents" -> (rho /. Quiet@Solve[
      rho (rho - 1) + p0 rho + q0 == 0,
      rho
    ]),
    "State" -> "RegularFiniteSingularity"
  |>
];

infinityIndicialData[p_, q_, variable_] := Module[
  {t, pInfinity, qInfinity, p0, q0, rho, regular},
  t = Unique["inverseVariable"];
  pInfinity = rat[2/t - (p /. variable -> 1/t)/t^2];
  qInfinity = rat[(q /. variable -> 1/t)/t^4];
  regular = Exponent[Numerator[pInfinity], t, Min] -
        Exponent[Denominator[pInfinity], t, Min] >= -1 &&
      Exponent[Numerator[qInfinity], t, Min] -
        Exponent[Denominator[qInfinity], t, Min] >= -2;
  If[! TrueQ[regular], Return[<|
    "State" -> "IrregularInfinity",
    "TransformedP" -> pInfinity,
    "TransformedQ" -> qInfinity
  |>]];
  p0 = rat[Limit[t pInfinity, t -> 0]];
  q0 = rat[Limit[t^2 qInfinity, t -> 0]];
  <|
    "State" -> "RegularInfinity",
    "P0" -> p0,
    "Q0" -> q0,
    "IndicialPolynomial" -> Factor[rho (rho - 1) + p0 rho + q0],
    "Exponents" -> (rho /. Quiet@Solve[
      rho (rho - 1) + p0 rho + q0 == 0,
      rho
    ])
  |>
];

ClassifySecondOrderScalarOperator[
  operator_Association,
  variable_
] := Module[
  {coefficients, p, q, factors, finite, infinity, regularFinite,
   regularInfinity, singularPointCount, class},
  If[! TrueQ[Lookup[operator, "Cyclic", False]] ||
      Lookup[operator, "Order", Missing["Order"]] =!= 2,
    Return[<|
      "State" -> "NotAReconstructedSecondOrderOperator"
    |>]
  ];
  coefficients = Lookup[operator, "Coefficients", Missing["Coefficients"]];
  If[! ListQ[coefficients] || Length[coefficients] =!= 2,
    Return[<|"State" -> "MissingScalarCoefficients"|>]
  ];
  q = rat[-coefficients[[1]]];
  p = rat[-coefficients[[2]]];
  factors = scalarDenominatorFactors[{p, q}, variable];
  finite = localIndicialData[p, q, variable, #] & /@ factors;
  infinity = infinityIndicialData[p, q, variable];
  regularFinite = And @@ (
    TrueQ[Lookup[#, "State", ""] === "RegularFiniteSingularity"] & /@
      finite
  );
  regularInfinity = TrueQ[
    Lookup[infinity, "State", ""] === "RegularInfinity"
  ];
  singularPointCount = Length[finite] + 1;
  class = Which[
    regularFinite && regularInfinity && singularPointCount == 3,
      "GaussHypergeometricType",
    regularFinite && regularInfinity && singularPointCount == 4,
      "FourPointFuchsianType",
    regularFinite && regularInfinity,
      "FuchsianType",
    True,
      "IrregularOrUnresolvedType"
  ];
  <|
    "State" -> "ExactSecondOrderClassification",
    "Class" -> class,
    "NormalizedP" -> p,
    "NormalizedQ" -> q,
    "FiniteSingularities" -> finite,
    "Infinity" -> infinity,
    "AllSingularitiesRegular" -> regularFinite && regularInfinity,
    "SingularPointCountIncludingInfinity" -> singularPointCount
  |>
];

GaussHypergeometricParameters[
  classification_Association,
  variable_
] := Module[
  {finite, infinity, orderedFinite, point0, point1, scale, x,
   pOriginal, qOriginal, pInX, qInX, exponents0, exponents1,
   exponentsInfinity, candidates, preferred},
  If[Lookup[classification, "Class", ""] =!= "GaussHypergeometricType",
    Return[<|"State" -> "NotGaussHypergeometricType"|>]
  ];
  finite = Lookup[classification, "FiniteSingularities", {}];
  infinity = Lookup[classification, "Infinity", <||>];
  If[Length[finite] =!= 2 ||
      Lookup[infinity, "State", ""] =!= "RegularInfinity",
    Return[<|"State" -> "IncompleteSingularityData"|>]
  ];
  orderedFinite = SortBy[finite, LeafCount[Lookup[#, "Point"]] &];
  point0 = orderedFinite[[1, "Point"]];
  point1 = orderedFinite[[2, "Point"]];
  scale = rat[point1 - point0];
  If[exactZeroQ[scale], Return[<|"State" -> "CoincidentFinitePoints"|>]];
  x = Unique["hypergeometricVariable"];
  pOriginal = classification["NormalizedP"];
  qOriginal = classification["NormalizedQ"];
  pInX = rat[scale (pOriginal /. variable -> point0 + scale x)];
  qInX = rat[scale^2 (qOriginal /. variable -> point0 + scale x)];
  exponents0 = orderedFinite[[1, "Exponents"]];
  exponents1 = orderedFinite[[2, "Exponents"]];
  exponentsInfinity = infinity["Exponents"];
  candidates = Flatten@Table[
    Module[{alpha0, alpha1, other0, other1, a, b, c, logDerivative,
      transformedP, transformedQ, standardP, standardQ, exact},
      alpha0 = exponents0[[i]];
      alpha1 = exponents1[[j]];
      other0 = exponents0[[3 - i]];
      other1 = exponents1[[3 - j]];
      c = rat[1 + alpha0 - other0];
      {a, b} = rat /@ (exponentsInfinity + alpha0 + alpha1);
      logDerivative = rat[alpha0/x - alpha1/(1 - x)];
      transformedP = rat[pInX + 2 logDerivative];
      transformedQ = rat[
        qInX + pInX logDerivative + D[logDerivative, x] +
          logDerivative^2
      ];
      standardP = rat[(c - (a + b + 1) x)/(x (1 - x))];
      standardQ = rat[-a b/(x (1 - x))];
      exact = exactZeroQ[transformedP - standardP] &&
        exactZeroQ[transformedQ - standardQ] &&
        exactZeroQ[c - a - b - (other1 - alpha1)];
      If[exact,
        {<|
          "Coordinate" -> rat[(variable - point0)/scale],
          "CoordinateSymbol" -> x,
          "FinitePoints" -> {point0, point1},
          "GaugePowers" -> {alpha0, alpha1},
          "Parameters" -> <|"a" -> a, "b" -> b, "c" -> c|>,
          "ExactEquationReconstruction" -> True
        |>},
        {}
      ]
    ],
    {i, 2}, {j, 2}
  ];
  candidates = DeleteDuplicates[candidates];
  preferred = If[candidates === {}, Missing["NoVerifiedCandidate"],
    First@SortBy[
      candidates,
      {
        Count[Lookup[#, "GaugePowers", {}], value_ /; ! exactZeroQ[value]] &,
        LeafCount
      }
    ]
  ];
  <|
    "State" -> If[candidates === {},
      "GaussParametersNotReconstructed",
      "GaussParametersExactlyReconstructed"
    ],
    "Candidates" -> candidates,
    "Preferred" -> preferred,
    "ExactReconstruction" -> candidates =!= {}
  |>
];

ConstructGaussSolutionBasis[
  gaussData_Association,
  variable_
] := Module[
  {preferred, coordinate, coordinateSymbol, gaugePowers, parameters,
   alpha0, alpha1, a, b, c, prefactor, localBasis, physicalBasis,
   wronskian, nonresonant},
  If[! TrueQ[Lookup[gaussData, "ExactReconstruction", False]],
    Return[<|"State" -> "GaussEquationNotExactlyReconstructed"|>]
  ];
  preferred = Lookup[gaussData, "Preferred", Missing["Preferred"]];
  If[! AssociationQ[preferred],
    Return[<|"State" -> "MissingPreferredGaussCandidate"|>]
  ];
  coordinate = preferred["Coordinate"];
  coordinateSymbol = preferred["CoordinateSymbol"];
  gaugePowers = preferred["GaugePowers"];
  parameters = preferred["Parameters"];
  {alpha0, alpha1} = gaugePowers;
  {a, b, c} = Lookup[parameters, {"a", "b", "c"}];
  nonresonant = ! exactZeroQ[1 - c];
  If[! nonresonant,
    Return[<|
      "State" -> "ResonantLocalBasisRequiresLogarithmicSolution",
      "Coordinate" -> coordinate,
      "GaugePowers" -> gaugePowers,
      "Parameters" -> parameters
    |>]
  ];
  prefactor = coordinateSymbol^alpha0 (1 - coordinateSymbol)^alpha1;
  localBasis = {
    prefactor Hypergeometric2F1[a, b, c, coordinateSymbol],
    prefactor coordinateSymbol^(1 - c)
      Hypergeometric2F1[a - c + 1, b - c + 1, 2 - c,
        coordinateSymbol]
  };
  physicalBasis = localBasis /. coordinateSymbol -> coordinate;
  wronskian = rat[
    D[coordinate, variable] (1 - c)
      coordinate^(2 alpha0 - c)
      (1 - coordinate)^(2 alpha1 + c - a - b - 1)
  ];
  <|
    "State" -> "ExactNonresonantGaussBasisConstructed",
    "Coordinate" -> coordinate,
    "GaugePowers" -> gaugePowers,
    "Parameters" -> parameters,
    "BasisInUnitCoordinate" -> localBasis,
    "Basis" -> physicalBasis,
    "Wronskian" -> wronskian,
    "LocallyIndependent" -> ! exactZeroQ[wronskian],
    "ExactEquationReconstruction" -> TrueQ[
      preferred["ExactEquationReconstruction"]
    ]
  |>
];

Options[ConstructDlogEpsilonTransport] = {
  "Parameters" -> {},
  "BoundaryMatrix" -> Automatic
};

ConstructDlogEpsilonTransport[
  kernel_?MatrixQ,
  variable_,
  regulator_,
  maxWeight_Integer,
  OptionsPattern[]
] := Module[
  {dimension, parameters, allowedSymbols, fieldRecords, boundary,
   integrateMatrix, differentiateMatrix, coefficients, recurrenceResiduals,
   recurrenceVerified, transport, residual, truncatedResidual},
  If[maxWeight < 0,
    Return[<|"State" -> "NegativeWeightRequested"|>]
  ];
  If[
    DownValues[PolyLogTools`GIntegrate] === {} ||
      DownValues[PolyLogTools`DG] === {},
    Return[<|"State" -> "PolyLogToolsNotLoaded"|>]
  ];
  dimension = Length[kernel];
  If[Dimensions[kernel] =!= {dimension, dimension},
    Return[<|"State" -> "ConnectionKernelIsNotSquare"|>]
  ];
  parameters = OptionValue["Parameters"];
  If[! ListQ[parameters] ||
      ! And @@ (MatchQ[#, _Symbol] & /@ Join[{variable, regulator}, parameters]),
    Return[<|"State" -> "InvalidVariableOrParameterDeclaration"|>]
  ];
  If[! FreeQ[kernel, regulator],
    Return[<|"State" -> "ConnectionKernelDependsOnRegulator"|>]
  ];
  allowedSymbols = DeleteDuplicates@Join[{variable}, parameters];
  fieldRecords = connectionEntryFieldRecord[
      #, allowedSymbols, {}, {}
    ] & /@ Flatten[kernel];
  If[! And @@ (TrueQ[# ["RationalInDeclaredField"]] & /@ fieldRecords),
    Return[<|
      "State" -> "ConnectionKernelIsNotExactRational",
      "FieldRecords" -> fieldRecords
    |>]
  ];
  boundary = Replace[
    OptionValue["BoundaryMatrix"],
    Automatic -> IdentityMatrix[dimension]
  ];
  If[
    ! MatrixQ[boundary] || Dimensions[boundary] =!= {dimension, dimension} ||
      ! exactZeroQ[D[boundary, variable]],
    Return[<|"State" -> "BoundaryMatrixMustBeConstantAndSquare"|>]
  ];
  integrateMatrix[matrix_] := Map[
    PolyLogTools`GIntegrate[#, variable] &,
    matrix,
    {2}
  ];
  differentiateMatrix[matrix_] := Map[
    PolyLogTools`DG[#, variable] &,
    matrix,
    {2}
  ];
  coefficients = NestList[
    integrateMatrix[kernel . #] &,
    boundary,
    maxWeight
  ];
  recurrenceResiduals = Table[
    matrixMap[
      rat,
      differentiateMatrix[coefficients[[weight + 1]]] -
        kernel . coefficients[[weight]]
    ],
    {weight, 1, maxWeight}
  ];
  recurrenceVerified = And @@ (exactZeroQ /@ recurrenceResiduals);
  transport = Sum[
    regulator^weight coefficients[[weight + 1]],
    {weight, 0, maxWeight}
  ];
  residual = Expand[
    differentiateMatrix[transport] - regulator kernel . transport
  ];
  truncatedResidual = matrixMap[
    rat,
    Map[
      Sum[
        Coefficient[#, regulator, weight] regulator^weight,
        {weight, 0, maxWeight}
      ] &,
      residual,
      {2}
    ]
  ];
  <|
    "State" -> If[
      recurrenceVerified && exactZeroQ[truncatedResidual],
      "ExactDlogTransportConstructed",
      "DlogTransportVerificationFailed"
    ],
    "Variable" -> variable,
    "Regulator" -> regulator,
    "MaximumWeight" -> maxWeight,
    "BasePoint" -> 0,
    "BasePointPrescription" -> "TangentialBasePoint",
    "BoundaryMatrix" -> boundary,
    "WeightCoefficients" -> coefficients,
    "Transport" -> transport,
    "RecurrenceResiduals" -> recurrenceResiduals,
    "TruncatedDifferentialEquationResidual" -> truncatedResidual,
    "ExactRecurrence" -> recurrenceVerified,
    "ExactDifferentialEquation" -> exactZeroQ[truncatedResidual],
    "PhysicalBoundaryDetermined" -> False
  |>
];

ClearAll[
  rationalFunctionInVariableQ,
  exactInvariantReconstructionQ,
  directInvariantFieldCandidates,
  eliminateInvariantFieldRelation,
  expressEntryInInvariantField
];

rationalFunctionInVariableQ[expression_, variable_] := Module[{fraction},
  fraction = rat[expression];
  PolynomialQ[Numerator[fraction], variable] &&
    PolynomialQ[Denominator[fraction], variable]
];

exactInvariantReconstructionQ[
  expression_, candidate_, invariant_, variable_
] := exactZeroQ[expression - (candidate /. variable -> invariant)];

directInvariantFieldCandidates[
  expression_, invariant_, variables_List, variable_
] := Module[{solutions, candidates},
  candidates = Flatten@Table[
    solutions = Quiet@Solve[invariant == variable, coordinate];
    If[ListQ[solutions], rat[expression /. #] & /@ solutions, {}],
    {coordinate, variables}
  ];
  candidates = Select[
    DeleteDuplicates[candidates],
    FreeQ[#, Alternatives @@ variables] &&
      rationalFunctionInVariableQ[#, variable] &&
      exactInvariantReconstructionQ[expression, #, invariant, variable] &
  ];
  SortBy[candidates, LeafCount]
];

Options[eliminateInvariantFieldRelation] = {"TimeLimit" -> 30};

eliminateInvariantFieldRelation[
  expression_, invariant_, variables_List, variable_, OptionsPattern[]
] := Module[{value, relation},
  value = Unique["invariantValue"];
  relation = TimeConstrained[
    Quiet@Eliminate[
      {
        Numerator[rat[invariant - variable]] == 0,
        Numerator[rat[expression - value]] == 0
      },
      variables
    ],
    OptionValue["TimeLimit"],
    $Aborted
  ];
  <|"ValueSymbol" -> value, "Relation" -> relation|>
];

Options[expressEntryInInvariantField] = {"EliminationTimeLimit" -> 30};

expressEntryInInvariantField[
  expression_, invariant_, variables_List, variable_, OptionsPattern[]
] := Module[
  {tangent, direct, elimination, value, relation, solutions, candidates},
  If[exactZeroQ[expression], Return[<|
    "State" -> "RationalInvariantFieldRepresentationVerified",
    "Expression" -> 0,
    "Method" -> "ZeroEntry",
    "ExactReconstruction" -> True
  |>]];
  tangent = rat[
    D[invariant, variables[[2]]] D[expression, variables[[1]]] -
      D[invariant, variables[[1]]] D[expression, variables[[2]]]
  ];
  If[! exactZeroQ[tangent], Return[<|
    "State" -> "NotInvariantOnLevelSets",
    "TangentDerivative" -> tangent,
    "ExactReconstruction" -> False
  |>]];
  direct = directInvariantFieldCandidates[
    expression, invariant, variables, variable
  ];
  If[direct =!= {}, Return[<|
    "State" -> "RationalInvariantFieldRepresentationVerified",
    "Expression" -> First[direct],
    "Method" -> "ExactCoordinateElimination",
    "ExactReconstruction" -> True
  |>]];
  elimination = eliminateInvariantFieldRelation[
    expression,
    invariant,
    variables,
    variable,
    "TimeLimit" -> OptionValue["EliminationTimeLimit"]
  ];
  value = elimination["ValueSymbol"];
  relation = elimination["Relation"];
  If[relation === $Aborted, Return[<|
    "State" -> "InvariantFieldEliminationTimedOut",
    "TangentDerivative" -> tangent,
    "ExactReconstruction" -> False
  |>]];
  solutions = Quiet@Solve[relation, value];
  candidates = If[ListQ[solutions], value /. solutions, {}];
  candidates = Select[
    Flatten[{candidates}],
    FreeQ[#, Alternatives @@ variables] &&
      rationalFunctionInVariableQ[#, variable] &&
      exactInvariantReconstructionQ[expression, #, invariant, variable] &
  ];
  If[candidates =!= {}, Return[<|
    "State" -> "RationalInvariantFieldRepresentationVerified",
    "Expression" -> First@SortBy[candidates, LeafCount],
    "Method" -> "ExactPolynomialElimination",
    "EliminationRelation" -> relation,
    "ExactReconstruction" -> True
  |>]];
  If[relation =!= True && relation =!= False && ! FreeQ[relation, value],
    <|
      "State" -> "AlgebraicRelationFoundButNoRationalRepresentation",
      "EliminationRelation" -> relation,
      "TangentDerivative" -> tangent,
      "ExactReconstruction" -> False
    |>,
    <|
      "State" -> "TangentInvariantButExplicitRepresentationNotFound",
      "EliminationRelation" -> relation,
      "TangentDerivative" -> tangent,
      "ExactReconstruction" -> False
    |>
  ]
];

Options[ExpressConnectionInInvariantField] = {"EliminationTimeLimit" -> 30};

ExpressConnectionInInvariantField[
  generator_?MatrixQ,
  invariant_,
  variables : {_, _},
  variable_,
  OptionsPattern[]
] := Module[
  {entries, uniqueEntries, records, entryVerified, matrix,
   residualVariables, exactMatrixReconstruction, verified},
  entries = Flatten[generator];
  uniqueEntries = DeleteDuplicates[entries];
  records = Map[
    Function[entry,
      <|
        "OriginalEntry" -> entry,
        "Result" -> expressEntryInInvariantField[
          entry,
          invariant,
          variables,
          variable,
          "EliminationTimeLimit" -> OptionValue["EliminationTimeLimit"]
        ]
      |>
    ],
    uniqueEntries
  ];
  entryVerified = And @@ (
    TrueQ[Lookup[# ["Result"], "ExactReconstruction", False]] & /@ records
  );
  matrix = If[entryVerified,
    Map[
      Function[entry,
        SelectFirst[
          records,
          SameQ[# ["OriginalEntry"], entry] &,
          <|"Result" -> <|"Expression" -> Missing["MissingEntry"]|>|>
        ]["Result"]["Expression"]
      ],
      generator,
      {2}
    ],
    Missing["NotReconstructed"]
  ];
  residualVariables = If[MatrixQ[matrix],
    DeleteDuplicates@Cases[
      matrix,
      Alternatives @@ variables,
      Infinity
    ],
    Missing["NotReconstructed"]
  ];
  exactMatrixReconstruction = MatrixQ[matrix] &&
    residualVariables === {} &&
    exactZeroQ[(matrix /. variable -> invariant) - generator];
  verified = entryVerified && exactMatrixReconstruction;
  <|
    "State" -> If[verified,
      "RationalInvariantFieldRepresentationVerified",
      "RationalInvariantFieldRepresentationNotVerified"
    ],
    "Matrix" -> matrix,
    "EntryRecords" -> records,
    "ResidualOriginalVariables" -> residualVariables,
    "ExactMatrixReconstruction" -> exactMatrixReconstruction,
    "ExactReconstruction" -> verified
  |>
];

ClearAll[verifiedEpsilonFormQ];

verifiedEpsilonFormQ[data_Association] := Module[
  {certificate, required},
  certificate = Lookup[data, "EpsilonFormCertificate", <||>];
  required = {
    "TransformationEquation",
    "EpsilonFactorization",
    "RegulatorIndependentResidues",
    "DlogReconstruction",
    "FlatConnection"
  };
  AssociationQ[certificate] &&
    And @@ (TrueQ[Lookup[certificate, #, False]] & /@ required)
];

Options[AnalyzeMasterAnalyticRoute] = {
  "CandidateInvariants" -> {},
  "InvariantDegree" -> 4,
  "ScalarTimeLimit" -> 300
};

AnalyzeMasterAnalyticRoute[data_Association, OptionsPattern[]] := Module[
  {flatness, fieldValidation, oneFormRank, divisorCensus, residueSpectra,
   invariantResult, z,
   invariantFieldResult, oneVariableMatrix, scalar, secondOrderClassification,
   gaussData, gaussBasis,
   epsilonForm,
  declaredEpsilonForm, route},
  flatness = CheckExactConnection[data];
  fieldValidation = If[AssociationQ[flatness],
    Lookup[flatness, "FieldValidation", Missing["NotAvailable"]],
    Missing["NotAvailable"]
  ];
  If[flatness === $Failed || ! TrueQ[flatness["Flat"]],
      Return[<|
        "State" -> "Rejected",
        "Reason" -> If[
          AssociationQ[fieldValidation] && ! TrueQ[fieldValidation["Valid"]],
          "The connection is not in the declared exact rational field",
          "The connection is not exactly flat modulo the declared kinematic ideal"
        ],
        "CoefficientField" -> fieldValidation,
        "Connection" -> flatness
      |>]
  ];
  oneFormRank = ConnectionOneFormRank[data];
  divisorCensus = ConnectionSingularDivisorCensus[data];
  residueSpectra = ConnectionResidueSpectra[data];
  invariantResult = FindSingleInvariantConnection[
    data,
    "CandidateInvariants" -> OptionValue["CandidateInvariants"],
    "InvariantDegree" -> OptionValue["InvariantDegree"]
  ];
  invariantFieldResult = Missing["NotApplicable"];
  oneVariableMatrix = Missing["NotApplicable"];
  scalar = Missing["NotApplicable"];
  secondOrderClassification = Missing["NotApplicable"];
  gaussData = Missing["NotApplicable"];
  gaussBasis = Missing["NotApplicable"];
  If[AssociationQ[invariantResult] && TrueQ[invariantResult["OneVariable"]],
    z = Unique["z"];
    invariantFieldResult = ExpressConnectionInInvariantField[
      invariantResult["Generator"],
      invariantResult["Invariant"],
      data["Variables"],
      z
    ];
    oneVariableMatrix = Lookup[
      invariantFieldResult,
      "Matrix",
      Missing["NotReconstructed"]
    ];
    If[MatrixQ[oneVariableMatrix] &&
        TrueQ[Lookup[invariantFieldResult, "ExactMatrixReconstruction", False]] &&
        Lookup[invariantFieldResult, "ResidualOriginalVariables", {1}] === {},
      scalar = FindCyclicScalarOperator[
        oneVariableMatrix,
        z,
        "TimeLimit" -> OptionValue["ScalarTimeLimit"]
      ];
      If[AssociationQ[scalar] && TrueQ[Lookup[scalar, "Order", 0] == 2],
        secondOrderClassification = ClassifySecondOrderScalarOperator[
          scalar,
          z
        ];
        If[Lookup[secondOrderClassification, "Class", ""] ===
            "GaussHypergeometricType",
          gaussData = GaussHypergeometricParameters[
            secondOrderClassification,
            z
          ];
          If[TrueQ[Lookup[gaussData, "ExactReconstruction", False]],
            gaussBasis = ConstructGaussSolutionBasis[gaussData, z]
          ]
        ]
      ]
    ]
  ];
  epsilonForm = verifiedEpsilonFormQ[data];
  declaredEpsilonForm = TrueQ[Lookup[data, "VerifiedEpsilonForm", False]];
  route = Which[
    epsilonForm && AssociationQ[invariantResult] && TrueQ[invariantResult["OneVariable"]],
      "Use the exact epsilon-form transport; use the verified one-variable pullback only to reduce the independent boundary calculation",
    epsilonForm,
      "Use exact iterated-integral transport; determine only the independent boundary periods",
    AssociationQ[gaussData] &&
        TrueQ[Lookup[gaussData, "ExactReconstruction", False]],
      "Construct the exact Gauss hypergeometric solution and determine its physical linear combination from boundary data",
    AssociationQ[scalar] && TrueQ[scalar["Cyclic"]] && scalar["Order"] == 2,
      "Identify the exact second-order Picard-Fuchs operator before direct integration",
    AssociationQ[scalar] && TrueQ[scalar["Cyclic"]],
      "Factor and classify the exact Picard-Fuchs operator before direct integration",
    True,
      "Construct exact parametric or Baikov data, test linear reducibility, then test a bounded canonical transformation"
  ];
  <|
    "State" -> "ExactDiagnosticsComplete",
    "CoefficientField" -> fieldValidation,
    "Connection" -> flatness,
    "ConnectionOneFormRank" -> oneFormRank,
    "SingularDivisors" -> divisorCensus,
    "ResidueSpectra" -> residueSpectra,
    "SingleInvariant" -> invariantResult,
    "InvariantFieldRepresentation" -> invariantFieldResult,
    "OneVariableMatrix" -> oneVariableMatrix,
    "ScalarOperator" -> scalar,
    "SecondOrderClassification" -> secondOrderClassification,
    "GaussHypergeometricData" -> gaussData,
    "GaussSolutionBasis" -> gaussBasis,
    "VerifiedEpsilonForm" -> epsilonForm,
    "DeclaredEpsilonForm" -> declaredEpsilonForm,
    "NextAnalyticConstruction" -> route
  |>
];

AnalyzePhysicalBlockNeed[
  blockID_String,
  catalogue_Association,
  physicalBasis_List,
  boundaryMap_: <||>
] := Module[
  {classIndex, classes, classRecord, members, target, boundaryRecords,
   memberRecords, physicalMembers, physicalMasters, knownBoundaryRecords,
   missingBoundaryMasters, recommended},
  classIndex = Lookup[
    Lookup[catalogue, "BlockToClass", <||>],
    blockID,
    Missing["UnknownBlock", blockID]
  ];
  If[MissingQ[classIndex], Return[<|
    "State" -> "UnknownBlock",
    "BlockID" -> blockID
  |>]];
  classes = Lookup[catalogue, "Classes", {}];
  classRecord = SelectFirst[
    classes,
    TrueQ[Lookup[#, "ClassIndex", Missing[]] == classIndex] &,
    Missing["MissingClassRecord", classIndex]
  ];
  If[MissingQ[classRecord], Return[<|
    "State" -> "MissingClassRecord",
    "BlockID" -> blockID,
    "ClassIndex" -> classIndex
  |>]];
  members = Lookup[classRecord, "Members", {}];
  target = SelectFirst[
    members,
    SameQ[Lookup[#, "ID", Missing[]], blockID] &,
    Missing["MissingBlockMember", blockID]
  ];
  boundaryRecords = If[AssociationQ[boundaryMap],
    Lookup[boundaryMap, "MasterRecords", {}],
    {}
  ];
  memberRecords = Map[
    Function[member,
      Module[{memberPhysical, memberBoundaries, memberMissing},
        memberPhysical = exactIntersection[
          Lookup[member, "Masters", {}],
          physicalBasis
        ];
        memberBoundaries = Select[
          boundaryRecords,
          exactMemberQ[memberPhysical, Lookup[#, "Master", Missing[]]] &
        ];
        memberMissing = exactComplement[
          memberPhysical,
          Lookup[memberBoundaries, "Master", {}]
        ];
        <|
          "ID" -> Lookup[member, "ID", Missing["ID"]],
          "PhysicalMasters" -> memberPhysical,
          "PhysicalMasterCount" -> Length[memberPhysical],
          "KnownBoundaryRecords" -> memberBoundaries,
          "KnownBoundaryRecordCount" -> Length[memberBoundaries],
          "PhysicalMastersWithoutBoundaryRecord" -> memberMissing
        |>
      ]
    ],
    members
  ];
  physicalMembers = Select[memberRecords, # ["PhysicalMasterCount"] > 0 &];
  physicalMasters = DeleteDuplicates@Flatten[
    Lookup[physicalMembers, "PhysicalMasters", {}],
    1
  ];
  knownBoundaryRecords = Select[
    boundaryRecords,
    exactMemberQ[physicalMasters, Lookup[#, "Master", Missing[]]] &
  ];
  missingBoundaryMasters = exactComplement[
    physicalMasters,
    Lookup[knownBoundaryRecords, "Master", {}]
  ];
  recommended = If[physicalMembers === {}, Missing["NoPhysicalOrbitMember"],
    First@SortBy[
      physicalMembers,
      {
        Length[# ["PhysicalMastersWithoutBoundaryRecord"]] &,
        # ["PhysicalMasterCount"] &,
        ToString[# ["ID"]] &
      }
    ]
  ];
  <|
    "State" -> "ExactPhysicalMembershipComputed",
    "BlockID" -> blockID,
    "ConnectionClassIndex" -> classIndex,
    "TargetMasters" -> If[AssociationQ[target], Lookup[target, "Masters", {}], {}],
    "TargetPhysicalMasters" -> If[AssociationQ[target],
      exactIntersection[Lookup[target, "Masters", {}], physicalBasis],
      {}
    ],
    "TargetAuxiliaryOnly" -> If[AssociationQ[target],
      exactIntersection[Lookup[target, "Masters", {}], physicalBasis] === {},
      Missing["MissingBlockMember", blockID]
    ],
    "PhysicalOrbitMembers" -> physicalMembers,
    "PhysicalOrbitMasterCount" -> Length[physicalMasters],
    "KnownBoundaryRecords" -> knownBoundaryRecords,
    "PhysicalMastersWithoutBoundaryRecord" -> missingBoundaryMasters,
    "RecommendedPhysicalMember" -> recommended,
    "Interpretation" -> "Orbit membership proves equality of the exact differential connection after the recorded coordinate and basis map; it does not prove equality of the cut integrals."
  |>
];

End[];
EndPackage[];
