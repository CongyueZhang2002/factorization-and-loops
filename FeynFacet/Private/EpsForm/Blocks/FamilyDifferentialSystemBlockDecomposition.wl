(* Irreducible diagonal blocks of a V2 family differential system.

   For dI = A I, a nonzero entry A[[i,j]] means that row i depends on
   row j.  The strongly connected components of this directed dependency
   graph are therefore the irreducible diagonal blocks.  Reversing a
   topological order of the condensation graph puts every dependency before
   its dependent, so the simultaneously permuted connection matrices are
   block lower triangular.

   Production may classify zero entries by bounded finite-field sampling.
   Such a decomposition is explicitly probabilistic: an entry observed
   nonzero is certainly nonzero, while an entry vanishing at every sampled
   point is only probabilistically classified as zero. *)

Clear[
  BuildFamilyDifferentialSystemBlockDecomposition,
  FamilyDifferentialSystemBlockDecompositionQ
];

ClearAll[
  familyBlockDecompositionFailure,
  familyBlockDecompositionSystemQ,
  familyBlockDecompositionAbsolutePathQ,
  familyBlockDecompositionReferenceQ,
  familyBlockDecompositionExactZeroQ,
  familyBlockDecompositionFiniteFieldValue,
  familyBlockDecompositionCandidatePositions,
  familyBlockDecompositionPatternAtSamples,
  familyBlockDecompositionFiniteFieldPattern,
  familyBlockDecompositionExactPattern,
  familyBlockDecompositionComponents,
  familyBlockDecompositionRowsPartitionQ,
  familyBlockDecompositionSameComponentsQ,
  familyBlockDecompositionLowerTriangularQ,
  familyBlockDecompositionEvidenceQ,
  familyBlockDecompositionReplayPattern
];

familyBlockDecompositionFailure[status_String, extra_: <||>] :=
  Join[<|"Status" -> status|>, extra];

familyBlockDecompositionSystemQ[system_Association] := Module[
  {variables, regulator, basis, matrices, dimension},
  variables = Lookup[system, "KinematicVariables", Missing[]];
  regulator = Lookup[system, "DimensionalRegulator", Missing[]];
  basis = Lookup[system, "OriginalMasterIntegralBasis", Missing[]];
  matrices = Lookup[system, "ConnectionMatrices", Missing[]];
  dimension = If[ListQ[basis], Length[basis], 0];
  Lookup[system, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[system, "SchemaVersion", None] === 2 &&
    Lookup[system, "Status", None] ===
      "FamilyDifferentialSystemValidated" &&
    StringQ[Lookup[system, "Family", None]] &&
    MatchQ[variables, {_Symbol, _Symbol}] &&
    DuplicateFreeQ[variables] && MatchQ[regulator, _Symbol] &&
    ! MemberQ[variables, regulator] && dimension > 0 &&
    MatchQ[matrices, {_?MatrixQ, _?MatrixQ}] &&
    AllTrue[matrices, Dimensions[#] === {dimension, dimension} &]
];
familyBlockDecompositionSystemQ[_] := False;

familyBlockDecompositionAbsolutePathQ[path_String] :=
  StringStartsQ[path, "/"] ||
    StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];
familyBlockDecompositionAbsolutePathQ[_] := False;

familyBlockDecompositionReferenceQ[reference_Association,
    family_String] := Module[{relative, explicit},
  relative = Lookup[reference, "RelativePath", None];
  explicit = Lookup[reference, "ExplicitPath", None];
  Lookup[reference, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[reference, "SchemaVersion", None] === 2 &&
    Lookup[reference, "Family", None] === family &&
    Xor[StringQ[relative] && StringLength[relative] > 0 &&
        ! familyBlockDecompositionAbsolutePathQ[relative],
      StringQ[explicit] && StringLength[explicit] > 0 &&
        familyBlockDecompositionAbsolutePathQ[explicit]]
];
familyBlockDecompositionReferenceQ[_, _] := False;

familyBlockDecompositionExactZeroQ[entry_] := Module[{reduced},
  If[TrueQ[entry === 0], Return[True]];
  reduced = Quiet[Check[Together[entry], $Failed]];
  If[reduced === $Failed, $Failed, TrueQ[reduced === 0]]
];

(* Substitution precedes rational normalization.  Together therefore sees
   only an exact numeric expression, never a large symbolic denominator. *)
familyBlockDecompositionFiniteFieldValue[entry_, rules_List,
    prime_Integer] := Module[{value, numerator, denominator, inverse},
  value = Quiet[Check[entry /. rules, $Failed]];
  If[value === $Failed, Return[$Failed]];
  value = Quiet[Check[Together[value], $Failed]];
  If[value === $Failed || ! RationalQ[value], Return[$Failed]];
  numerator = Numerator[value];
  denominator = Denominator[value];
  If[Mod[denominator, prime] === 0, Return[$Failed]];
  inverse = Quiet[Check[
    PowerMod[Mod[denominator, prime], -1, prime], $Failed]];
  If[inverse === $Failed, $Failed,
    Mod[Mod[numerator, prime] inverse, prime]]
];

familyBlockDecompositionCandidatePositions[{a1_, a2_}, dimension_Integer] :=
  Select[Tuples[Range[dimension], 2],
    Function[position,
      position[[1]] =!= position[[2]] &&
        ! (TrueQ[a1[[position[[1]], position[[2]]]] === 0] &&
          TrueQ[a2[[position[[1]], position[[2]]]] === 0])]];

familyBlockDecompositionPatternAtSamples[matrices : {_, _},
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    samples_List] := Module[
  {dimension = Length[First[matrices]], positions, observed, sample,
   prime, kinematicRules, regulatorRule, rules, values, k},
  positions = familyBlockDecompositionCandidatePositions[
    matrices, dimension];
  observed = ConstantArray[False, {dimension, dimension}];
  Do[
    sample = samples[[s]];
    If[! AssociationQ[sample], Return[$Failed]];
    prime = Lookup[sample, "Prime", Missing[]];
    kinematicRules = Lookup[sample, "KinematicPoint", Missing[]];
    regulatorRule = Lookup[sample, "DimensionalRegulatorValue", Missing[]];
    If[! IntegerQ[prime] || ! PrimeQ[prime] || prime <= 3 ||
        ! MatchQ[kinematicRules, {_Rule, _Rule}] ||
        First /@ kinematicRules =!= variables ||
        ! MatchQ[regulatorRule, _Rule] ||
        First[regulatorRule] =!= regulator ||
        ! AllTrue[Join[Last /@ kinematicRules, {Last[regulatorRule]}],
          IntegerQ], Return[$Failed]];
    rules = Join[kinematicRules, {regulatorRule}];
    values = Table[
      {familyBlockDecompositionFiniteFieldValue[
          matrices[[1, positions[[k, 1]], positions[[k, 2]]]],
          rules, prime],
       familyBlockDecompositionFiniteFieldValue[
          matrices[[2, positions[[k, 1]], positions[[k, 2]]]],
          rules, prime]},
      {k, Length[positions]}];
    If[! FreeQ[values, $Failed], Return[$Failed]];
    Do[
      If[values[[k]] =!= {0, 0},
        observed[[positions[[k, 1]], positions[[k, 2]]]] = True],
      {k, Length[positions]}],
    {s, Length[samples]}];
  Table[i === j || ! TrueQ[observed[[i, j]]],
    {i, dimension}, {j, dimension}]
];

familyBlockDecompositionFiniteFieldPattern[matrices : {_, _},
    variables : {_Symbol, _Symbol}, regulator_Symbol, primes_List,
    pointsPerPrime_Integer, seed_Integer,
    maximumAttempts_Integer] := Module[
  {samples = {}, accepted, attempts, point, rules, sample, trial,
   dimension = Length[First[matrices]], positions, observed, values, k},
  positions = familyBlockDecompositionCandidatePositions[
    matrices, dimension];
  observed = ConstantArray[False, {dimension, dimension}];
  BlockRandom[
    SeedRandom[seed, Method -> "MersenneTwister"];
    Do[
      accepted = 0;
      attempts = 0;
      While[accepted < pointsPerPrime && attempts < maximumAttempts,
        attempts++;
        point = RandomInteger[{2, prime - 2}, 3];
        rules = Thread[Join[variables, {regulator}] -> point];
        values = Table[
          {familyBlockDecompositionFiniteFieldValue[
              matrices[[1, positions[[k, 1]], positions[[k, 2]]]],
              rules, prime],
           familyBlockDecompositionFiniteFieldValue[
              matrices[[2, positions[[k, 1]], positions[[k, 2]]]],
              rules, prime]},
          {k, Length[positions]}];
        If[! FreeQ[values, $Failed], Continue[]];
        Do[
          If[values[[k]] =!= {0, 0},
            observed[[positions[[k, 1]], positions[[k, 2]]]] = True],
          {k, Length[positions]}];
        sample = <|"Prime" -> prime,
          "KinematicPoint" -> Thread[variables -> point[[1 ;; 2]]],
          "DimensionalRegulatorValue" -> (regulator -> point[[3]])|>;
        AppendTo[samples, sample];
        accepted++];
      If[accepted < pointsPerPrime,
        Return[familyBlockDecompositionFailure[
          "FiniteFieldSamplePointsInsufficient", <|
            "Prime" -> prime, "AcceptedPoints" -> accepted,
            "RequiredPoints" -> pointsPerPrime,
            "Attempts" -> attempts|>], Module]],
      {prime, primes}]];
  trial = Table[i === j || ! TrueQ[observed[[i, j]]],
    {i, dimension}, {j, dimension}];
  <|"Status" -> "ConnectionNonzeroPatternClassified",
    "ZeroPattern" -> trial,
    "Evidence" -> <|
      "Method" -> "ProbabilisticFiniteFieldSampling",
      "Passed" -> True, "Exact" -> False, "Probabilistic" -> True,
      "Primes" -> primes, "PointsPerPrime" -> pointsPerPrime,
      "Seed" -> seed, "Samples" -> samples|>|>
];

familyBlockDecompositionExactPattern[matrices : {_, _}] := Module[
  {dimension = Length[First[matrices]], zeroPattern, value},
  zeroPattern = ConstantArray[True, {dimension, dimension}];
  Do[
    If[i =!= j,
      value = And @@
        (familyBlockDecompositionExactZeroQ[#] & /@
          {matrices[[1, i, j]], matrices[[2, i, j]]});
      If[value === $Failed,
        Return[familyBlockDecompositionFailure[
          "CharacteristicZeroConnectionEntryReductionFailed",
          <|"Position" -> {i, j}|>], Module]];
      zeroPattern[[i, j]] = TrueQ[value]],
    {i, dimension}, {j, dimension}];
  <|"Status" -> "ConnectionNonzeroPatternClassified",
    "ZeroPattern" -> zeroPattern,
    "Evidence" -> <|
      "Method" -> "CharacteristicZeroSymbolicIdentity",
      "Passed" -> True, "Exact" -> True,
      "Probabilistic" -> False|>|>
];

familyBlockDecompositionComponents[zeroPattern_?MatrixQ] := Module[
  {dimension = Length[zeroPattern], edges, components, componentIndex,
   condensationEdges, topologicalOrder, orderedComponents},
  edges = Flatten@Table[
    If[i =!= j && ! TrueQ[zeroPattern[[i, j]]],
      {DirectedEdge[i, j]}, {}],
    {i, dimension}, {j, dimension}];
  components = SortBy[Sort /@ ConnectedComponents[
      Graph[Range[dimension], edges]], First];
  componentIndex = ConstantArray[0, dimension];
  Do[Scan[(componentIndex[[#]] = k) &, components[[k]]],
    {k, Length[components]}];
  condensationEdges = DeleteDuplicates@Flatten@Table[
    If[i =!= j && ! TrueQ[zeroPattern[[i, j]]] &&
        componentIndex[[i]] =!= componentIndex[[j]],
      {DirectedEdge[componentIndex[[i]], componentIndex[[j]]]}, {}],
    {i, dimension}, {j, dimension}];
  topologicalOrder = Quiet@TopologicalSort[
    Graph[Range[Length[components]], condensationEdges]];
  If[! ListQ[topologicalOrder] ||
      Length[topologicalOrder] =!= Length[components], Return[$Failed]];
  orderedComponents = components[[Reverse[topologicalOrder]]];
  <|"StronglyConnectedComponents" -> components,
    "OrderedComponents" -> orderedComponents|>
];

familyBlockDecompositionRowsPartitionQ[blocks_, dimension_Integer] :=
  ListQ[blocks] && blocks =!= {} &&
    AllTrue[blocks, MatchQ[#, {__Integer}] && DuplicateFreeQ[#] &] &&
    DuplicateFreeQ[Flatten[blocks]] &&
    Sort[Flatten[blocks]] === Range[dimension];

familyBlockDecompositionSameComponentsQ[blocks_List,
    components_List] :=
  Sort[Sort /@ blocks] === Sort[Sort /@ components];

familyBlockDecompositionLowerTriangularQ[blocks_List,
    zeroPattern_?MatrixQ] := Module[{position, dimension},
  dimension = Length[zeroPattern];
  position = ConstantArray[0, dimension];
  Do[Scan[(position[[#]] = k) &, blocks[[k]]], {k, Length[blocks]}];
  And @@ Flatten@Table[
    position[[i]] >= position[[j]] || TrueQ[zeroPattern[[i, j]]],
    {i, dimension}, {j, dimension}]
];

familyBlockDecompositionEvidenceQ[evidence_Association] := Module[
  {method, primes, points, samples},
  If[! TrueQ[Lookup[evidence, "Passed", False]], Return[False]];
  method = Lookup[evidence, "Method", None];
  Switch[method,
    "CharacteristicZeroSymbolicIdentity",
      TrueQ[Lookup[evidence, "Exact", False]] &&
        ! TrueQ[Lookup[evidence, "Probabilistic", True]],
    "ProbabilisticFiniteFieldSampling",
      primes = Lookup[evidence, "Primes", Missing[]];
      points = Lookup[evidence, "PointsPerPrime", Missing[]];
      samples = Lookup[evidence, "Samples", Missing[]];
      ! TrueQ[Lookup[evidence, "Exact", True]] &&
        TrueQ[Lookup[evidence, "Probabilistic", False]] &&
        MatchQ[primes, {__Integer}] && DuplicateFreeQ[primes] &&
        AllTrue[primes, PrimeQ[#] && # > 3 &] &&
        IntegerQ[points] && points > 0 &&
        MatchQ[samples, {__Association}] &&
        Length[samples] === Length[primes] points &&
        AllTrue[primes,
          Count[Lookup[samples, "Prime", Missing[]], #] === points &],
    _, False]
];
familyBlockDecompositionEvidenceQ[_] := False;

familyBlockDecompositionReplayPattern[system_Association,
    evidence_Association] := Switch[Lookup[evidence, "Method", None],
  "CharacteristicZeroSymbolicIdentity",
    familyBlockDecompositionExactPattern[system["ConnectionMatrices"]],
  "ProbabilisticFiniteFieldSampling",
    Module[{pattern = familyBlockDecompositionPatternAtSamples[
        system["ConnectionMatrices"], system["KinematicVariables"],
        system["DimensionalRegulator"], evidence["Samples"]]},
      If[pattern === $Failed,
        familyBlockDecompositionFailure[
          "FiniteFieldConnectionNonzeroPatternEvaluationFailed"],
        <|"Status" -> "ConnectionNonzeroPatternClassified",
          "ZeroPattern" -> pattern, "Evidence" -> evidence|>]],
  _, familyBlockDecompositionFailure[
    "BlockDecompositionValidationMethodInvalid"]
];

Options[BuildFamilyDifferentialSystemBlockDecomposition] = {
  "ValidationMethod" -> "ProbabilisticFiniteFieldSampling",
  "FiniteFieldPrimes" -> {2147483629, 2147483587, 2147483579},
  "PointsPerPrime" -> 3,
  "Seed" -> 20260904,
  "MaximumAttemptsPerPrime" -> 30
};

BuildFamilyDifferentialSystemBlockDecomposition[system_Association,
    systemReference_Association, OptionsPattern[]] := Module[
  {method = OptionValue["ValidationMethod"],
   primes = OptionValue["FiniteFieldPrimes"],
   points = OptionValue["PointsPerPrime"], seed = OptionValue["Seed"],
   maximumAttempts = OptionValue["MaximumAttemptsPerPrime"], analysis,
   components, blocks, dimension, validation},
  If[(Lookup[system, "DataType", None] === "FamilyDifferentialSystem" &&
        Lookup[system, "SchemaVersion", None] =!= 2) ||
      AnyTrue[{"Av", "Aw", "BlockBasis"}, KeyExistsQ[system, #] &],
    Return[familyBlockDecompositionFailure[
      "LegacyDifferentialEquationSchemaUnsupported"]]];
  If[! familyBlockDecompositionSystemQ[system],
    Return[familyBlockDecompositionFailure[
      "FamilyDifferentialSystemInvalid"]]];
  If[! familyBlockDecompositionReferenceQ[systemReference,
      system["Family"]],
    Return[familyBlockDecompositionFailure[
      "FamilyDifferentialSystemReferenceInvalid"]]];
  dimension = Length[system["OriginalMasterIntegralBasis"]];
  analysis = Switch[method,
    "CharacteristicZeroSymbolicIdentity",
      familyBlockDecompositionExactPattern[system["ConnectionMatrices"]],
    "ProbabilisticFiniteFieldSampling",
      If[! MatchQ[primes, {__Integer}] || ! DuplicateFreeQ[primes] ||
          ! AllTrue[primes, PrimeQ[#] && # > 3 &] ||
          ! IntegerQ[points] || points < 1 || ! IntegerQ[seed] ||
          ! IntegerQ[maximumAttempts] || maximumAttempts < points,
        familyBlockDecompositionFailure[
          "FiniteFieldValidationOptionsInvalid"],
        familyBlockDecompositionFiniteFieldPattern[
          system["ConnectionMatrices"], system["KinematicVariables"],
          system["DimensionalRegulator"], primes, points, seed,
          maximumAttempts]],
    _, familyBlockDecompositionFailure[
      "BlockDecompositionValidationMethodInvalid"]];
  If[Lookup[analysis, "Status", None] =!=
      "ConnectionNonzeroPatternClassified", Return[analysis]];
  components = familyBlockDecompositionComponents[
    analysis["ZeroPattern"]];
  If[! AssociationQ[components],
    Return[familyBlockDecompositionFailure[
      "ConnectionDependencyCondensationInvalid"]]];
  blocks = components["OrderedComponents"];
  If[! familyBlockDecompositionRowsPartitionQ[blocks, dimension] ||
      ! familyBlockDecompositionSameComponentsQ[blocks,
        components["StronglyConnectedComponents"]] ||
      ! familyBlockDecompositionLowerTriangularQ[blocks,
        analysis["ZeroPattern"]],
    Return[familyBlockDecompositionFailure[
      "FamilyDifferentialSystemBlockDecompositionValidationFailed"]]];
  validation = Join[analysis["Evidence"], <|
    "StronglyConnectedComponentsDerived" -> True,
    "RowsPartitionOriginalMasterIntegralBasis" -> True,
    "AboveDiagonalConnectionBlocksZero" -> True|>];
  <|"DataType" -> "FamilyDifferentialSystemBlockDecomposition",
    "SchemaVersion" -> 2,
    "Status" ->
      "FamilyDifferentialSystemBlockDecompositionValidated",
    "FamilyDifferentialSystemReference" -> systemReference,
    "IrreducibleDiagonalBlocks" -> blocks,
    "Validation" -> validation|>
];
BuildFamilyDifferentialSystemBlockDecomposition[___] :=
  familyBlockDecompositionFailure[
    "FamilyDifferentialSystemBlockDecompositionInputsInvalid"];

FamilyDifferentialSystemBlockDecompositionQ[record_Association,
    system_Association] := Module[
  {reference, blocks, evidence, analysis, components, dimension},
  If[! familyBlockDecompositionSystemQ[system], Return[False]];
  reference = Lookup[record, "FamilyDifferentialSystemReference",
    Missing[]];
  blocks = Lookup[record, "IrreducibleDiagonalBlocks", Missing[]];
  evidence = Lookup[record, "Validation", Missing[]];
  dimension = Length[system["OriginalMasterIntegralBasis"]];
  If[Lookup[record, "DataType", None] =!=
        "FamilyDifferentialSystemBlockDecomposition" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "FamilyDifferentialSystemBlockDecompositionValidated" ||
      ! familyBlockDecompositionReferenceQ[reference,
        system["Family"]] ||
      ! familyBlockDecompositionRowsPartitionQ[blocks, dimension] ||
      ! familyBlockDecompositionEvidenceQ[evidence] ||
      ! TrueQ[Lookup[evidence, "StronglyConnectedComponentsDerived",
          False]] ||
      ! TrueQ[Lookup[evidence,
          "RowsPartitionOriginalMasterIntegralBasis", False]] ||
      ! TrueQ[Lookup[evidence,
          "AboveDiagonalConnectionBlocksZero", False]], Return[False]];
  analysis = familyBlockDecompositionReplayPattern[system, evidence];
  If[Lookup[analysis, "Status", None] =!=
      "ConnectionNonzeroPatternClassified", Return[False]];
  components = familyBlockDecompositionComponents[
    analysis["ZeroPattern"]];
  AssociationQ[components] &&
    familyBlockDecompositionSameComponentsQ[blocks,
      components["StronglyConnectedComponents"]] &&
    familyBlockDecompositionLowerTriangularQ[blocks,
      analysis["ZeroPattern"]]
];
FamilyDifferentialSystemBlockDecompositionQ[___] := False;
