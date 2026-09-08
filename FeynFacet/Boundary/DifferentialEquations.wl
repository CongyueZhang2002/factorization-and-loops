(* Differential equations for the free coefficients of a normal
   Frobenius/Levelt solution along a positive-dimensional boundary stratum.

   If B is the matrix of retained boundary-mode coefficient vectors in a
   normal-residue basis, the coefficient vector c is not constant along the
   stratum.  With induced tangential connection Gamma it obeys

       d_i c = Omega_i c,
       B Omega_i = Gamma_i B - d_i B.

   The construction retains mixing inside resonant or degenerate normal
   exponent sectors.  Compatibility with the normal residue J is the
   horizontality equation d_i J + J Gamma_i - Gamma_i J = 0; for a constant
   Jordan normal form this is [J,Gamma_i]=0, not diagonal evolution of the
   individual generalized eigenvectors.  B is not the complete graded
   Frobenius/Levelt embedding in normal powers and logarithms. *)

Clear[ConstructBoundaryFunctionDifferentialSystem,
  BoundaryFunctionDifferentialSystemQ,
  ConstructBoundaryFunctionEpsilonCoefficientEquations];

ClearAll[boundaryFunctionSystemConnectionData,
  boundaryFunctionSystemModeVector, boundaryFunctionSystemID,
  boundaryFunctionSystemIndependentRows,
  boundaryFunctionSystemFiniteFieldRowRankCertificate,
  boundaryFunctionSystemRowRankCertificateQ,
  boundaryFunctionSystemRationalCoefficientDomainQ,
  boundaryFunctionSystemRationalModValue,
  boundaryFunctionSystemMatrixModValue,
  boundaryFunctionSystemScalarEntries,
  boundaryFunctionSystemFiniteFieldZeroQ,
  boundaryFunctionSystemFiniteFieldValidation,
  boundaryFunctionSystemValidateZeroQ,
  boundaryFunctionSystemEpsilonValuation,
  boundaryFunctionSystemCoefficientFunction];

(* The existing nonresonant constructor already computes the moving-basis
   term.  Normalize that result to the same internal data used by a future
   full Levelt-basis constructor. *)
boundaryFunctionSystemConnectionData[data_Association] := Which[
  Lookup[data, "DataType", None] === "InducedBoundaryConnection" &&
      Lookup[data, "SchemaVersion", None] === 2,
    With[{variables = Lookup[data, "TangentialVariables", Missing[]],
        matrices = Lookup[data, "InducedTangentialConnectionMatrices",
          Missing[]]},
      <|
        "TangentialVariables" -> variables,
        "Regulator" -> Lookup[data, "DimensionalRegulator", Missing[]],
        "NormalBasisInverse" -> Lookup[data,
          "InverseNormalFrobeniusBasis", Missing[]],
        "NormalResidueNormalForm" -> Lookup[data,
          "NormalResidueNormalForm", Missing[]],
        "InducedConnectionMatrices" -> If[AssociationQ[matrices] &&
            ListQ[variables] &&
            AllTrue[variables, KeyExistsQ[matrices, #] &],
          matrices[[Key[#]]] & /@ variables, matrices]|>],
  Lookup[data, "Status", None] ===
      "TangentialConnectionTransformedToNormalResidueEigenbasis",
    <|
      "TangentialVariables" -> {Lookup[data, "TangentialVariable", Missing[]]},
      "Regulator" -> Lookup[data, "Regulator", Missing[]],
      "NormalBasisInverse" -> Lookup[data,
        "InverseNormalResidueEigenbasis", Missing[]],
      "NormalResidueNormalForm" -> Lookup[data,
        "NormalResidueInEigenbasis", Missing[]],
      "InducedConnectionMatrices" -> {
        Lookup[data, "TangentialConnectionInEigenbasis", Missing[]]}|>,
  True, $Failed
];

boundaryFunctionSystemModeVector[mode_Association] :=
  Lookup[mode, "PhysicalToLocalMode",
    Lookup[mode, "CanonicalMode", Missing["BoundaryModeVector"]]];

boundaryFunctionSystemID[mode_Association] :=
  Lookup[mode, "BoundaryFunctionID", Missing["BoundaryFunctionID"]];

boundaryFunctionSystemIndependentRows[matrix_?MatrixQ] := Module[
  {reduced, rows},
  reduced = Quiet[Check[RowReduce[Transpose[matrix]], $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  rows = DeleteCases[Map[Function[row,
      SelectFirst[Range[Length[row]],
        ! boundaryExactZeroQ[row[[#]]] &, Missing["NoPivot"]]],
    reduced], _Missing];
  If[Length[rows] === Dimensions[matrix][[2]], rows, $Failed]
];

(* A denominator-regular specialization with a nonzero maximal minor is a
   one-sided exact witness that the rational-function matrix has full column
   rank.  Randomness is used only to find such a witness. *)
boundaryFunctionSystemFiniteFieldRowRankCertificate[matrix_?MatrixQ,
    variables_List, regulator_Symbol, primes_List, seed_Integer,
    requestedRows_] := Module[
  {allVariables = Append[variables, regulator], dimensions,
   columnCount, attempts, rules, image, reduced, rows, determinant,
   certificate, tag = Unique["boundaryModeRowRank"]},
  dimensions = Dimensions[matrix];
  If[Length[dimensions] =!= 2, Return[<|
    "Status" -> "BoundaryModeMatrixRowRankNotCertified"|>]];
  columnCount = Last[dimensions];
  If[! boundaryFunctionSystemRationalCoefficientDomainQ[matrix],
    Return[<|"Status" ->
      "BoundaryModeMatrixFiniteFieldCoefficientDomainUnsupported"|>]];
  certificate = BlockRandom[SeedRandom[seed, Method -> "MersenneTwister"];
    Catch[
    Do[
      attempts = 0;
      While[attempts < 20,
        attempts++;
        rules = Thread[allVariables ->
          RandomInteger[{2, prime - 2}, Length[allVariables]]];
        image = boundaryFunctionSystemMatrixModValue[matrix, rules, prime];
        If[image =!= $Failed,
          rows = If[requestedRows === Automatic,
            reduced = RowReduce[Transpose[image], Modulus -> prime];
            DeleteCases[Map[Function[row,
                SelectFirst[Range[Length[row]],
                  Mod[row[[#]], prime] =!= 0 &,
                  Missing["ZeroRow"]]], reduced], _Missing],
            requestedRows];
          If[Length[rows] === columnCount,
            determinant = Quiet[Check[
              Mod[Det[image[[rows, All]], Modulus -> prime], prime],
              $Failed]];
            If[IntegerQ[determinant] && determinant =!= 0,
              Throw[<|
                "Status" -> "BoundaryModeMatrixRowRankCertified",
                "Method" -> "FiniteFieldNonzeroMinor",
                "Prime" -> prime, "Point" -> rules,
                "MatrixDimensions" -> dimensions,
                "RowRank" -> columnCount,
                "RowRankProfile" -> rows,
                "MinorDeterminantModPrime" -> determinant|>, tag]]]]],
      {prime, primes}], tag, #1 &]];
  If[AssociationQ[certificate], Return[certificate]];
  <|"Status" -> "BoundaryModeMatrixRowRankNotCertified",
    "Method" -> "BoundedFiniteFieldSearch",
    "AttemptCount" -> 20 Length[primes]|>
];

boundaryFunctionSystemRowRankCertificateQ[matrix_?MatrixQ,
    certificate_Association, variables_List, regulator_Symbol] := Module[
  {method, dimensions = Dimensions[matrix], columnCount, rows,
   coordinateMatrix, determinant, prime, point, allVariables, image},
  If[Length[dimensions] =!= 2, Return[False]];
  columnCount = Last[dimensions];
  method = Lookup[certificate, "Method", None];
  rows = Lookup[certificate, "RowRankProfile", None];
  If[Lookup[certificate, "Status", None] =!=
        "BoundaryModeMatrixRowRankCertified" ||
      Lookup[certificate, "MatrixDimensions", None] =!= dimensions ||
      Lookup[certificate, "RowRank", None] =!= columnCount ||
      ! MatchQ[rows, {__Integer}] || Length[rows] =!= columnCount ||
      ! DuplicateFreeQ[rows] ||
      ! AllTrue[rows, 1 <= # <= First[dimensions] &], Return[False]];
  coordinateMatrix = matrix[[rows, All]];
  Which[
    method === "ExactSymbolicNonzeroMinor",
      determinant = Quiet[Check[Together[Det[coordinateMatrix]], $Failed]];
      determinant =!= $Failed &&
        ! boundaryExactZeroQ[determinant] &&
        boundaryExactZeroQ[determinant -
          Lookup[certificate, "MinorDeterminant", Missing[]]],
    method === "FiniteFieldNonzeroMinor",
      prime = Lookup[certificate, "Prime", None];
      point = Lookup[certificate, "Point", None];
      allVariables = Append[variables, regulator];
      If[! PrimeQ[prime] ||
          ! MatchQ[point, {Rule[_Symbol, _Integer] ..}] ||
          Sort[First /@ point] =!= Sort[allVariables] ||
          ! DuplicateFreeQ[First /@ point], Return[False]];
      image = boundaryFunctionSystemMatrixModValue[matrix, point, prime];
      If[image === $Failed, Return[False]];
      determinant = Quiet[Check[
        Mod[Det[image[[rows, All]], Modulus -> prime], prime], $Failed]];
      IntegerQ[determinant] && determinant =!= 0 &&
        determinant === Lookup[certificate,
          "MinorDeterminantModPrime", None],
    True, False]
];

boundaryFunctionSystemRowRankCertificateQ[___] := False;

boundaryFunctionSystemScalarEntries[expressions_] :=
  Flatten[{expressions} /.
    sparse_SparseArray :> Normal[sparse]];

(* The point evaluator below is an evaluator for Q(t_1,...,t_n,eps), not
   for a square-root extension.  Refuse the latter before point generation;
   otherwise every attempted point is merely discarded and an unsupported
   coefficient domain is misreported as a failed mathematical identity. *)
boundaryFunctionSystemRationalCoefficientDomainQ[expressions_] :=
  FreeQ[boundaryFunctionSystemScalarEntries[expressions],
    _AlgebraicNumber | _Root |
      Power[_, exponent_ /; ! IntegerQ[exponent]]];

(* Exact rational evaluation after all variables have numerical finite-field
   representatives.  No symbolic common denominator is formed. *)
boundaryFunctionSystemRationalModValue[expression_, rules_List,
    prime_Integer] := Module[{value, numerator, denominator},
  value = Quiet[Check[Together[expression /. rules], $Failed]];
  If[value === $Failed || ! MatchQ[value, _Integer | _Rational],
    Return[$Failed]];
  numerator = Numerator[value];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

boundaryFunctionSystemMatrixModValue[matrix_?MatrixQ, rules_List,
    prime_Integer] := Module[{value},
  value = Map[boundaryFunctionSystemRationalModValue[#, rules, prime] &,
    Normal[matrix], {2}];
  If[FreeQ[value, $Failed], value, $Failed]
];

boundaryFunctionSystemFiniteFieldZeroQ[expressions_, variables_List,
    regulator_Symbol, primes_List, seed_Integer] := Module[
  {allVariables = Append[variables, regulator], accepted = {}, attempts,
   rules, values, scalarExpressions},
  scalarExpressions = boundaryFunctionSystemScalarEntries[expressions];
  BlockRandom[SeedRandom[seed];
    Do[
      attempts = 0;
      While[attempts < 20,
        attempts++;
        rules = Thread[allVariables ->
          RandomInteger[{2, prime - 2}, Length[allVariables]]];
        values = boundaryFunctionSystemRationalModValue[#, rules, prime] & /@
          scalarExpressions;
        If[FreeQ[values, $Failed],
          AppendTo[accepted, <|"Prime" -> prime, "Point" -> rules,
            "Zero" -> AllTrue[values, # === 0 &]|>];
          Break[]]
      ],
      {prime, primes}]
  ];
  <|"AcceptedPoints" -> accepted,
    "AllZero" -> Length[accepted] === Length[primes] &&
      AllTrue[accepted, TrueQ[#Zero] &]|>
];

(* Evaluate primitive matrices and their entrywise derivatives first, then
   perform the matrix products over F_p.  This is the production path for a
   supplied connection: it never builds Gamma.S, S.Omega, or a curvature
   matrix in characteristic zero. *)
boundaryFunctionSystemFiniteFieldValidation[normalResidue_?MatrixQ,
    inducedConnections_List, modeMatrix_?MatrixQ,
    boundaryConnections_List, variables_List, regulator_Symbol,
    primes_List, seed_Integer] := Module[
  {allVariables = Append[variables, regulator], accepted = {}, attempts,
   rules, j, gamma, s, omega, dj, ds, domega, primitive, normalChecks,
   invariantChecks, flatnessChecks, conditions},
  If[! boundaryFunctionSystemRationalCoefficientDomainQ[
      {normalResidue, inducedConnections, modeMatrix,
       boundaryConnections}],
    Return[<|
      "Status" -> "BoundaryFunctionFiniteFieldCoefficientDomainUnsupported",
      "SupportedCoefficientDomain" -> "RationalFunctions",
      "Method" -> "ProbabilisticFiniteFieldSampling",
      "Conditions" -> <||>, "Evidence" -> <||>|>]];
  BlockRandom[SeedRandom[seed];
    Do[
      attempts = 0;
      While[attempts < 20,
        attempts++;
        rules = Thread[allVariables ->
          RandomInteger[{2, prime - 2}, Length[allVariables]]];
        j = boundaryFunctionSystemMatrixModValue[
          normalResidue, rules, prime];
        gamma = boundaryFunctionSystemMatrixModValue[#, rules, prime] & /@
          inducedConnections;
        s = boundaryFunctionSystemMatrixModValue[modeMatrix, rules, prime];
        omega = boundaryFunctionSystemMatrixModValue[#, rules, prime] & /@
          boundaryConnections;
        dj = boundaryFunctionSystemMatrixModValue[
            D[normalResidue, #], rules, prime] & /@ variables;
        ds = boundaryFunctionSystemMatrixModValue[
            D[modeMatrix, #], rules, prime] & /@ variables;
        domega = Table[boundaryFunctionSystemMatrixModValue[
            D[boundaryConnections[[direction]], variable], rules, prime],
          {variable, variables},
          {direction, Length[boundaryConnections]}];
        primitive = {j, gamma, s, omega, dj, ds, domega};
        If[FreeQ[primitive, $Failed],
          normalChecks = MapThread[
            Mod[#1 + j . #2 - #2 . j, prime] ===
                ConstantArray[0, Dimensions[j]] &,
            {dj, gamma}];
          invariantChecks = MapThread[
            Mod[#1 . s - #2 - s . #3, prime] ===
                ConstantArray[0, Dimensions[s]] &,
            {gamma, ds, omega}];
          flatnessChecks = Flatten@Table[
            Mod[domega[[i, jIndex]] - domega[[jIndex, i]] -
                omega[[i]] . omega[[jIndex]] +
                omega[[jIndex]] . omega[[i]], prime] ===
              ConstantArray[0, Dimensions[First[omega]]],
            {i, Length[variables]},
            {jIndex, i + 1, Length[variables]}];
          AppendTo[accepted, <|"Prime" -> prime, "Point" -> rules,
            "NormalResidueHorizontal" -> And @@ normalChecks,
            "BoundaryModeSubspaceInvariant" -> And @@ invariantChecks,
            "TangentialConnectionFlat" -> And @@ flatnessChecks|>];
          Break[]]
      ],
      {prime, primes}]
  ];
  conditions = Association@Table[name ->
      (Length[accepted] === Length[primes] &&
        AllTrue[accepted, TrueQ[Lookup[#, name, False]] &]),
    {name, {"NormalResidueHorizontal",
      "BoundaryModeSubspaceInvariant", "TangentialConnectionFlat"}}];
  <|"Status" -> "BoundaryFunctionDifferentialSystemValidationCompleted",
    "Method" -> "ProbabilisticFiniteFieldSampling",
    "Conditions" -> conditions,
    "Evidence" -> <|"AcceptedPoints" -> accepted|>|>
];

boundaryFunctionSystemValidateZeroQ[expressions_, "Exact", ___] :=
  <|"AllZero" -> boundaryExactZeroQ[expressions],
    "Method" -> "ExactSymbolicIdentity"|>;
boundaryFunctionSystemValidateZeroQ[expressions_, "FiniteField",
    variables_List, regulator_Symbol, primes_List, seed_Integer] :=
  Join[<|"Method" -> "ProbabilisticFiniteFieldSampling"|>,
    boundaryFunctionSystemFiniteFieldZeroQ[expressions, variables,
      regulator, primes, seed]];

Options[ConstructBoundaryFunctionDifferentialSystem] = {
  "BoundaryFunctionConnectionMatrices" -> Automatic,
  "ModeCoordinateRows" -> Automatic,
  "ValidationMethod" -> Automatic,
  "FiniteFieldPrimes" -> {2147483647, 2147483629, 2147483587},
  "Seed" -> 20260904
};

ConstructBoundaryFunctionDifferentialSystem[modeMatching_Association,
    connectionData_Association, OptionsPattern[]] := Catch@Module[
  {fail, normalized, variables, regulator, inverseNormalBasis,
   normalResidue, inducedConnections, boundaryDomain, modes, ids,
   modeValuations,
   modeVectors, dimension, modeCount, modeMatrix, coordinateRows,
   coordinateMatrix, coordinateMinorDeterminant, requestedRows,
   rowRankCertificate, suppliedConnections,
   boundaryConnections, rhs,
   connectionEpsilonValuations, valuationViolations,
   invariantResiduals, horizontalityResiduals, flatnessResiduals,
   method, primes, seed, validation, conditions, validationExpressions,
   connectionAssociation},

  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  normalized = boundaryFunctionSystemConnectionData[connectionData];
  If[normalized === $Failed,
    fail["InducedBoundaryConnectionRequired"]];
  variables = normalized["TangentialVariables"];
  regulator = normalized["Regulator"];
  inverseNormalBasis = normalized["NormalBasisInverse"];
  normalResidue = normalized["NormalResidueNormalForm"];
  inducedConnections = normalized["InducedConnectionMatrices"];
  boundaryDomain = Lookup[modeMatching, "BoundaryDomain", Missing[]];
  If[Lookup[modeMatching, "DataType", None] =!=
        "BoundaryAsymptoticModeMatching" ||
      Lookup[modeMatching, "SchemaVersion", None] =!= 2 ||
      Lookup[modeMatching, "Status", None] =!=
        "BoundaryAsymptoticsMatchedToFrobeniusModes" ||
      Lookup[modeMatching, "BoundaryDataType", None] =!=
        "BoundaryFunction" ||
      Lookup[boundaryDomain, "Type", None] =!=
        "PhysicalBoundaryStratum" ||
      Lookup[boundaryDomain, "TangentialVariables", Missing[]] =!=
        variables ||
      ! StringQ[Lookup[modeMatching, "Family", Missing[]]] ||
      Lookup[modeMatching, "Regulator", Missing[]] =!= regulator ||
      ! MatchQ[variables, {__Symbol}] ||
      ! MatchQ[regulator, _Symbol] || MemberQ[variables, regulator] ||
      ! MatrixQ[inverseNormalBasis] || ! MatrixQ[normalResidue] ||
      ! ListQ[inducedConnections] ||
      Length[inducedConnections] =!= Length[variables] ||
      ! AllTrue[inducedConnections, MatrixQ],
    fail["BoundaryFunctionDifferentialSystemInputsInvalid"]];
  dimension = Length[normalResidue];
  If[Dimensions[normalResidue] =!= {dimension, dimension} ||
      Dimensions[inverseNormalBasis] =!= {dimension, dimension} ||
      ! AllTrue[inducedConnections,
        Dimensions[#] === {dimension, dimension} &],
    fail["InducedBoundaryConnectionDimensionsInvalid"]];

  modes = Lookup[modeMatching, "FrobeniusModes", Missing[]];
  If[! ListQ[modes] || modes === {},
    fail["BoundaryFunctionModesRequired"]];
  ids = boundaryFunctionSystemID /@ modes;
  modeValuations = Lookup[modes,
    "BoundaryFunctionEpsilonValuation", Missing[]];
  modeVectors = boundaryFunctionSystemModeVector /@ modes;
  If[MemberQ[ids, _Missing] || ! DuplicateFreeQ[ids] ||
      ! VectorQ[modeValuations, IntegerQ] ||
      ! AllTrue[modeVectors,
        VectorQ[#] && Length[#] === dimension &],
    fail["BoundaryFunctionModeBasisInvalid"]];
  modeCount = Length[ids];
  modeMatrix = inverseNormalBasis . Transpose[modeVectors];

  method = Replace[OptionValue["ValidationMethod"],
    Automatic :> If[dimension <= 8, "Exact", "FiniteField"]];
  If[! MemberQ[{"Exact", "FiniteField"}, method],
    fail["BoundaryFunctionDifferentialSystemValidationMethodInvalid"]];
  primes = OptionValue["FiniteFieldPrimes"];
  seed = OptionValue["Seed"];
  If[method === "FiniteField" &&
      (! MatchQ[primes, {__Integer}] || ! AllTrue[primes, PrimeQ] ||
        ! DuplicateFreeQ[primes]),
    fail["BoundaryFunctionDifferentialSystemFiniteFieldPrimesInvalid"]];

  requestedRows = OptionValue["ModeCoordinateRows"];
  If[requestedRows =!= Automatic &&
      (! MatchQ[requestedRows, {__Integer}] ||
        Length[requestedRows] =!= modeCount ||
        ! DuplicateFreeQ[requestedRows] ||
        ! AllTrue[requestedRows, 1 <= # <= dimension &]),
    fail["BoundaryFunctionModeCoordinateRowsInvalid"]];
  If[method === "Exact",
    coordinateRows = Replace[requestedRows,
      Automatic :> boundaryFunctionSystemIndependentRows[modeMatrix]];
    If[coordinateRows === $Failed ||
        ! MatchQ[coordinateRows, {__Integer}] ||
        Length[coordinateRows] =!= modeCount,
      fail["BoundaryFunctionModesLinearlyDependent"]];
    coordinateMatrix = modeMatrix[[coordinateRows, All]];
    coordinateMinorDeterminant = Quiet[Check[
      Together[Det[coordinateMatrix]], $Failed]];
    If[coordinateMinorDeterminant === $Failed ||
        boundaryExactZeroQ[coordinateMinorDeterminant],
      fail["BoundaryFunctionModesLinearlyDependent"]];
    rowRankCertificate = <|
      "Status" -> "BoundaryModeMatrixRowRankCertified",
      "Method" -> "ExactSymbolicNonzeroMinor",
      "MatrixDimensions" -> Dimensions[modeMatrix],
      "RowRank" -> modeCount, "RowRankProfile" -> coordinateRows,
      "MinorDeterminant" -> coordinateMinorDeterminant|>,
    rowRankCertificate =
      boundaryFunctionSystemFiniteFieldRowRankCertificate[modeMatrix,
        variables, regulator, primes, seed, requestedRows];
    If[Lookup[rowRankCertificate, "Status", None] =!=
        "BoundaryModeMatrixRowRankCertified",
      fail[Lookup[rowRankCertificate, "Status",
        "BoundaryModeMatrixRowRankNotCertified"], <|
          "RowRankEvidence" -> rowRankCertificate|>]];
    coordinateRows = rowRankCertificate["RowRankProfile"];
    coordinateMatrix = modeMatrix[[coordinateRows, All]]];

  suppliedConnections = OptionValue[
    "BoundaryFunctionConnectionMatrices"];
  boundaryConnections = If[suppliedConnections === Automatic,
    rhs = MapThread[#1 . modeMatrix - D[modeMatrix, #2] &,
      {inducedConnections, variables}];
    Quiet[Check[Map[boundaryCanonicalMatrix[
          LinearSolve[coordinateMatrix, #[[coordinateRows, All]]]] &,
        rhs], $Failed]],
    suppliedConnections];
  If[boundaryConnections === $Failed ||
      ! ListQ[boundaryConnections] ||
      Length[boundaryConnections] =!= Length[variables] ||
      ! AllTrue[boundaryConnections,
        MatrixQ[#] && Dimensions[#] === {modeCount, modeCount} &],
    fail["BoundaryFunctionConnectionMatricesInvalid"]];

  connectionEpsilonValuations = Map[
    Map[boundaryFunctionSystemEpsilonValuation[#, regulator] &, #, {2}] &,
    boundaryConnections];
  If[! FreeQ[connectionEpsilonValuations, $Failed],
    fail["BoundaryFunctionConnectionNotLaurentRationalInDimensionalRegulator"]];
  valuationViolations = Flatten@Table[If[
      connectionEpsilonValuations[[direction, row, column]] === Infinity ||
        connectionEpsilonValuations[[direction, row, column]] +
            modeValuations[[column]] >= modeValuations[[row]],
      Nothing, <|"TangentialVariable" -> variables[[direction]],
        "Row" -> row, "Column" -> column,
        "ConnectionEpsilonValuation" ->
          connectionEpsilonValuations[[direction, row, column]],
        "SourceBoundaryFunctionEpsilonValuation" ->
          modeValuations[[column]],
        "TargetBoundaryFunctionEpsilonValuation" ->
          modeValuations[[row]]|>],
    {direction, Length[variables]}, {row, modeCount},
    {column, modeCount}];
  If[valuationViolations =!= {},
    fail["BoundaryFunctionEpsilonValuationsInconsistent", <|
      "Violations" -> valuationViolations|>]];

  validation = If[method === "FiniteField" &&
      suppliedConnections =!= Automatic,
    boundaryFunctionSystemFiniteFieldValidation[normalResidue,
      inducedConnections, modeMatrix, boundaryConnections, variables,
      regulator, primes, seed],
    If[! ListQ[rhs],
      rhs = MapThread[#1 . modeMatrix - D[modeMatrix, #2] &,
        {inducedConnections, variables}]];
    invariantResiduals = MapThread[
      #1 - modeMatrix . #2 &, {rhs, boundaryConnections}];
    horizontalityResiduals = MapThread[
      D[normalResidue, #2] + normalResidue . #1 - #1 . normalResidue &,
      {inducedConnections, variables}];
    flatnessResiduals = Flatten[Table[
      D[boundaryConnections[[j]], variables[[i]]] -
        D[boundaryConnections[[i]], variables[[j]]] -
        boundaryConnections[[i]] . boundaryConnections[[j]] +
        boundaryConnections[[j]] . boundaryConnections[[i]],
      {i, Length[variables]}, {j, i + 1, Length[variables]}], 1];
    validationExpressions = <|
      "NormalResidueHorizontal" -> horizontalityResiduals,
      "BoundaryModeSubspaceInvariant" -> invariantResiduals,
      "TangentialConnectionFlat" -> flatnessResiduals|>;
    With[{evidence = Map[
        boundaryFunctionSystemValidateZeroQ[#, method, variables,
          regulator, primes, seed] &, validationExpressions]},
      <|"Method" -> If[method === "Exact", "ExactSymbolicIdentity",
          "ProbabilisticFiniteFieldSampling"],
        "Conditions" ->
          Map[TrueQ[Lookup[#, "AllZero", False]] &, evidence],
        "Evidence" -> evidence|>]
  ];
  If[Lookup[validation, "Status", None] ===
      "BoundaryFunctionFiniteFieldCoefficientDomainUnsupported",
    fail["BoundaryFunctionFiniteFieldCoefficientDomainUnsupported", <|
      "SupportedCoefficientDomain" -> "RationalFunctions"|>]];
  conditions = validation["Conditions"];
  If[! And @@ Values[conditions],
    fail["BoundaryFunctionDifferentialSystemValidationFailed", <|
      "Conditions" -> conditions, "Validation" -> validation|>]];

  connectionAssociation = AssociationThread[variables,
    boundaryConnections];
  <|
    "DataType" -> "BoundaryFunctionDifferentialSystem",
    "SchemaVersion" -> 2,
    "Status" -> "BoundaryFunctionDifferentialSystemValidated",
    "Family" -> Lookup[modeMatching, "Family", Missing[]],
    "BoundaryDomain" -> boundaryDomain,
    "DimensionalRegulator" -> regulator,
    "TangentialVariables" -> variables,
    "BoundaryFunctionIDs" -> ids,
    "BoundaryFunctionEpsilonValuations" ->
      AssociationThread[ids, modeValuations],
    "NormalResidueNormalForm" -> normalResidue,
    "BoundaryModeCoefficientMatrixInNormalResidueBasis" -> modeMatrix,
    "BoundaryModeMatrixRowRankCertificate" -> rowRankCertificate,
    "InducedTangentialConnectionMatrices" ->
      AssociationThread[variables, inducedConnections],
    "BoundaryFunctionConnectionMatrices" -> connectionAssociation,
    "BoundaryFunctionConnectionEpsilonValuations" ->
      AssociationThread[variables, connectionEpsilonValuations],
    "DifferentialEquationConvention" ->
      "D[c(t,eps),t_i] = Omega_i(t,eps).c(t,eps)",
    "Validation" -> validation
  |>
];

ConstructBoundaryFunctionDifferentialSystem[___] :=
  <|"Status" ->
    "BoundaryFunctionDifferentialSystemInputsNotWellFormed"|>;

BoundaryFunctionDifferentialSystemQ[record_] := Module[
  {variables, regulator, ids, normalResidue, modeMatrix,
   inducedConnections, connections, valuations, connectionValuations,
   dimension, domain, rowRankCertificate, conditions,
   requiredConditions = {"NormalResidueHorizontal",
     "BoundaryModeSubspaceInvariant", "TangentialConnectionFlat"}},
  If[! AssociationQ[record], Return[False]];
  variables = Lookup[record, "TangentialVariables", None];
  regulator = Lookup[record, "DimensionalRegulator", None];
  domain = Lookup[record, "BoundaryDomain", None];
  ids = Lookup[record, "BoundaryFunctionIDs", None];
  normalResidue = Lookup[record, "NormalResidueNormalForm", None];
  modeMatrix = Lookup[record,
    "BoundaryModeCoefficientMatrixInNormalResidueBasis", None];
  rowRankCertificate = Lookup[record,
    "BoundaryModeMatrixRowRankCertificate", None];
  inducedConnections = Lookup[record,
    "InducedTangentialConnectionMatrices", None];
  connections = Lookup[record,
    "BoundaryFunctionConnectionMatrices", None];
  valuations = Lookup[record,
    "BoundaryFunctionEpsilonValuations", None];
  connectionValuations = Lookup[record,
    "BoundaryFunctionConnectionEpsilonValuations", None];
  dimension = If[MatrixQ[normalResidue], Length[normalResidue], 0];
  conditions = Lookup[Lookup[record, "Validation", <||>],
    "Conditions", <||>];
  Lookup[record, "DataType", None] ===
      "BoundaryFunctionDifferentialSystem" &&
    Lookup[record, "SchemaVersion", None] === 2 &&
    Lookup[record, "Status", None] ===
      "BoundaryFunctionDifferentialSystemValidated" &&
    StringQ[Lookup[record, "Family", None]] && AssociationQ[domain] &&
    Lookup[domain, "Type", None] === "PhysicalBoundaryStratum" &&
    Lookup[domain, "TangentialVariables", None] === variables &&
    MatchQ[variables, {__Symbol}] && MatchQ[regulator, _Symbol] &&
    ! MemberQ[variables, regulator] &&
    ListQ[ids] && ids =!= {} && DuplicateFreeQ[ids] &&
    MatrixQ[normalResidue] &&
    Dimensions[normalResidue] === {dimension, dimension} &&
    MatrixQ[modeMatrix] &&
    Dimensions[modeMatrix] === {dimension, Length[ids]} &&
    boundaryFunctionSystemRowRankCertificateQ[modeMatrix,
      rowRankCertificate, variables, regulator] &&
    AssociationQ[inducedConnections] &&
    Sort[Keys[inducedConnections]] === Sort[variables] &&
    AllTrue[variables, MatrixQ[inducedConnections[#]] &&
      Dimensions[inducedConnections[#]] === {dimension, dimension} &] &&
    AssociationQ[connections] &&
    Sort[Keys[connections]] === Sort[variables] &&
    AllTrue[variables, MatrixQ[connections[#]] &&
      Dimensions[connections[#]] === {Length[ids], Length[ids]} &] &&
    AssociationQ[valuations] &&
    AllTrue[ids, KeyExistsQ[valuations, #] &&
      IntegerQ[valuations[[Key[#]]]] &] &&
    AssociationQ[connectionValuations] &&
    Sort[Keys[connectionValuations]] === Sort[variables] &&
    AllTrue[variables, MatrixQ[connectionValuations[#]] &&
      Dimensions[connectionValuations[#]] ===
        {Length[ids], Length[ids]} &&
      AllTrue[Flatten[connectionValuations[#]],
        IntegerQ[#] || # === Infinity &] &] &&
    AssociationQ[conditions] &&
    ContainsAll[Keys[conditions], requiredConditions] &&
    AllTrue[requiredConditions, TrueQ[conditions[#]] &] &&
    Lookup[record, "DifferentialEquationConvention", None] ===
      "D[c(t,eps),t_i] = Omega_i(t,eps).c(t,eps)"
];

boundaryFunctionSystemEpsilonValuation[0, _Symbol] := Infinity;
boundaryFunctionSystemEpsilonValuation[expression_, regulator_Symbol] :=
  Module[{rationalExpression, numerator, denominator, valuation},
    rationalExpression = Quiet[Check[Together[expression], $Failed]];
    If[rationalExpression === $Failed, Return[$Failed]];
    {numerator, denominator} =
      NumeratorDenominator[rationalExpression];
    If[! PolynomialQ[numerator, regulator] ||
        ! PolynomialQ[denominator, regulator], Return[$Failed]];
    valuation = Exponent[numerator, regulator, Min] -
      Exponent[denominator, regulator, Min];
    If[IntegerQ[valuation], valuation, $Failed]
  ];

boundaryFunctionSystemCoefficientFunction[id_, order_Integer,
    variables_List] := Apply[
  BoundaryFunctionEpsilonCoefficient[id, order], variables];

ConstructBoundaryFunctionEpsilonCoefficientEquations[
    system_Association, window : {_Integer, _Integer}] := Catch@Module[
  {fail, low = First[window], high = Last[window], variables, regulator,
   ids, connections, valuations, coefficient, equations,
   requiredOrders, connectionOrders, coefficientLabels},
  fail[status_, extra_: <||>] :=
    Throw[Join[<|"Status" -> status|>, extra]];
  If[! BoundaryFunctionDifferentialSystemQ[system] || low > high,
    fail["BoundaryFunctionEpsilonCoefficientEquationInputsInvalid"]];
  variables = system["TangentialVariables"];
  regulator = system["DimensionalRegulator"];
  ids = system["BoundaryFunctionIDs"];
  connections = system["BoundaryFunctionConnectionMatrices"];
  valuations = system["BoundaryFunctionEpsilonValuations"];
  valuations = Table[valuations[[Key[ids[[index]]]]],
    {index, Length[ids]}];
  coefficient[variable_, row_, column_, order_] :=
    coefficient[variable, row, column, order] =
      SeriesCoefficient[connections[variable][[row, column]],
        {regulator, 0, order}];
  connectionOrders = Association@KeyValueMap[Function[{variable, matrix},
      variable -> Table[boundaryFunctionSystemEpsilonValuation[
        matrix[[row, column]], regulator], {row, Length[ids]},
        {column, Length[ids]}]], connections];
  equations = Association@Flatten@Table[
    If[n < valuations[[row]], Nothing,
      {variable, n, row} -> (
        D[boundaryFunctionSystemCoefficientFunction[ids[[row]], n,
            variables], variable] ==
          Total@Flatten@Table[With[
            {minimum = connectionOrders[variable][[row, column]]},
            If[minimum === Infinity, {},
              Table[coefficient[variable, row, column, k]
                  boundaryFunctionSystemCoefficientFunction[
                    ids[[column]], n - k, variables],
                {k, minimum, n - valuations[[column]]}]]],
            {column, Length[ids]}])],
    {variable, variables}, {n, low, high}, {row, Length[ids]}];
  coefficientLabels = DeleteDuplicates@Cases[Values[equations],
    HoldPattern[
      BoundaryFunctionEpsilonCoefficient[candidate_, order_Integer][___]] :>
        {candidate, order}, Infinity];
  (* The dependent coefficient on the left occurs underneath Derivative,
     so the direct function-call pattern above does not see it.  Equation
     keys are the authoritative row/order labels. *)
  coefficientLabels = DeleteDuplicates@Join[coefficientLabels,
    ({ids[[#[[3]]]], #[[2]]} &) /@ Keys[equations]];
  requiredOrders = Association@Table[id -> Sort[Last /@
      Select[coefficientLabels, SameQ[First[#], id] &]], {id, ids}];
  <|
    "DataType" -> "BoundaryFunctionEpsilonCoefficientEquations",
    "SchemaVersion" -> 2,
    "Status" -> "BoundaryFunctionEpsilonCoefficientEquationsConstructed",
    "BoundaryFunctionDifferentialSystem" -> system,
    "RequestedEpsilonOrderWindow" -> window,
    "RequiredBoundaryFunctionEpsilonOrders" -> requiredOrders,
    "Equations" -> equations
  |>
];

ConstructBoundaryFunctionEpsilonCoefficientEquations[___] :=
  <|"Status" ->
    "BoundaryFunctionEpsilonCoefficientEquationInputsNotWellFormed"|>;
