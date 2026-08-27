BeginPackage["CodexTripleRootReconstruction`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootPilot`"}];

TRStableRootOrder::usage =
  "TRStableRootOrder[frame, variables, indices] returns roots sorted by a canonical root-square fingerprint, independent of catalog order.";
TRPrepareReconstruction::usage =
  "TRPrepareReconstruction[record, frame] prepares a stable multiquadratic affine-system ABI shared by every epsilon and prime sample.";
TRGaugeCoefficientIndex::usage =
  "TRGaugeCoefficientIndex[preparation,i,j,grade,monomial] gives the packed gauge-coefficient column.";
TRResidueIndex::usage =
  "TRResidueIndex[preparation,letter,i,j] gives the packed residue column.";
TRAssembleReconstructionSample::usage =
  "TRAssembleReconstructionSample[preparation,epsValue,prime] builds a modular system, including optional normalization equations.";
TRCanonicalAffineSolve::usage =
  "TRCanonicalAffineSolve[matrix,right,prime] returns a deterministic RREF particular solution and nullspace basis.";
TRReconstructAffineBatch::usage =
  "TRReconstructAffineBatch[preparation,epsValues,primes] reconstructs bounded polynomial epsilon dependence by CRT and rational reconstruction.";
TRInterpolateRationalAffinePrime::usage =
  "TRInterpolateRationalAffinePrime[preparation,epsValues,prime] constructs one prime artifact with rational-in-epsilon interpolation of every normalized affine coordinate.";
TRLiftRationalAffineBatch::usage =
  "TRLiftRationalAffineBatch[preparation,primeArtifacts] combines compatible rational-in-epsilon prime artifacts by CRT, reconstructs the exact gauge vector, and checks the channel PDE.";
TRUnpackReconstructedVector::usage =
  "TRUnpackReconstructedVector[preparation,vector] assembles gauge channels and residue matrices from the packed vector.";
TRExactChannelResidual::usage =
  "TRExactChannelResidual[preparation,vector] verifies the affine differential equation exactly in root channels.";
TRVerifyReconstructionExact::usage =
  "TRVerifyReconstructionExact[result] reruns exact channel verification on a reconstruction result.";
TRVerifyReconstructionModPrime::usage =
  "TRVerifyReconstructionModPrime[result,prime,epsValues] verifies a reconstruction at fresh split points, with an optional branch-sign permutation.";
TRVerifyReconstructionAllBranchMasksModPrime::usage =
  "TRVerifyReconstructionAllBranchMasksModPrime[result,prime,epsValues] performs one full ABI validation and then verifies every split-branch permutation at fresh points.";
TRPreparationABICompatibleQ::usage =
  "TRPreparationABICompatibleQ[left,right] tests equality of canonical preparation fingerprints.";
TRPreparationABIValidQ::usage =
  "TRPreparationABIValidQ[preparation] recomputes the equation/ansatz ABI and rejects stale or mutated preparation fields.";
TRCrossPrimeEliminationPlanValidQ::usage =
  "TRCrossPrimeEliminationPlanValidQ[preparation,plan] validates a versioned fixed-row, fixed-normalization elimination plan against the preparation ABI.";

Begin["`Private`"];

$trValidatedABIFingerprint = None;

trPreparationFastPathQ[preparation_Association, candidate_] :=
  candidate === Lookup[preparation, "ABIFingerprint",
      Missing["PreparationABI"]] &&
    $trValidatedABIFingerprint === candidate;

trZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Together[#1] === 0] &];

trModNumber[value_, prime_Integer] := Module[
  {rational = Together[value], numerator, denominator},
  If[! MatchQ[rational, _Integer | _Rational], Return[$Failed]];
  numerator = Mod[Numerator[rational], prime];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

trCanonicalExpressionString[expression_, variables : {_Symbol, _Symbol}] :=
 Module[{xx = Symbol["CodexTripleRootReconstruction`Private`rootX"],
   yy = Symbol["CodexTripleRootReconstruction`Private`rootY"],
   rational, canonical},
  rational = Together[expression /. Thread[variables -> {xx, yy}]];
  canonical = {Expand[Numerator[rational]],
    Expand[Denominator[rational]]};
  ToString[InputForm[canonical]]
 ];

trExpressionFingerprint[expression_, variables_List] := Module[
  {canonical = trCanonicalExpressionString[expression, variables]},
  <|"CanonicalString" -> canonical,
    "SHA256" -> Hash[canonical, "SHA256", "HexString"]|>
];

trCanonicalEquationString[record_Association,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {xx = Symbol["CodexTripleRootReconstruction`Private`equationX"],
   yy = Symbol["CodexTripleRootReconstruction`Private`equationY"],
   ee = Symbol["CodexTripleRootReconstruction`Private`equationEpsilon"],
   strip, canonical},
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  canonical = Map[
    Function[entry, Module[{rational},
      rational = Together[entry /.
        Thread[variables -> {xx, yy}] /. epsilon -> ee];
      {Expand[Numerator[rational]], Expand[Denominator[rational]]}]],
    strip, {4}];
  ToString[InputForm[canonical]]
];

trBuildABIPayload[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List] := Module[
  {rootCanonicalSquares, rootCanonicalExpressions, rootSourceIndices,
   storedCanonicalSquares, storedRootFingerprints, rootFingerprints,
   rootOrderingFingerprint, rootMetadataConsistent, equationCanonical},
  rootCanonicalSquares =
    trCanonicalExpressionString[
      Lookup[#1, "RootSquare", $Failed], variables] & /@ roots;
  rootCanonicalExpressions = trCanonicalExpressionString[
      Lookup[#1, "Root", $Failed], variables] & /@ roots;
  rootSourceIndices = Lookup[roots, "SourceIndex", $Failed];
  storedCanonicalSquares = Lookup[roots, "CanonicalRootSquare", $Failed];
  storedRootFingerprints = Lookup[roots, "RootFingerprint", $Failed];
  rootFingerprints =
    Hash[#1, "SHA256", "HexString"] & /@ rootCanonicalSquares;
  rootOrderingFingerprint = Hash[rootCanonicalSquares,
    "SHA256", "HexString"];
  rootMetadataConsistent =
    VectorQ[rootSourceIndices, IntegerQ[#1] && #1 >= 1 &] &&
    DuplicateFreeQ[rootSourceIndices] &&
    storedCanonicalSquares === rootCanonicalSquares &&
    storedRootFingerprints === rootFingerprints &&
    AllTrue[roots, TrueQ[Together[
        Lookup[#1, "Root", $Failed]^2 -
          Lookup[#1, "RootSquare", $Failed]] === 0] &];
  equationCanonical = trCanonicalEquationString[
    record, variables, epsilon];
  If[MemberQ[Join[rootCanonicalSquares, rootCanonicalExpressions],
        _?(StringContainsQ[#1, "$Failed"] &)] ||
      ! TrueQ[rootMetadataConsistent] ||
      equationCanonical === $Failed, Return[$Failed]];
  <|
    "EquationCanonical" -> equationCanonical,
    "EquationFingerprint" -> Hash[
      equationCanonical, "SHA256", "HexString"],
    "RootCanonicalSquares" -> rootCanonicalSquares,
    "RootCanonicalExpressions" -> rootCanonicalExpressions,
    "RootSourceIndices" -> rootSourceIndices,
    "RootFingerprints" -> rootFingerprints,
    "RootOrderingFingerprint" -> rootOrderingFingerprint,
    "Dimensions" -> dimensions,
    "GaugeDenominator" -> trCanonicalExpressionString[
      gaugeDenominator, variables],
    "GaugeSupport" -> support,
    "OneForms" -> Map[
      trCanonicalExpressionString[#1, variables] &, oneForms, {2}],
    "Normalizations" -> normalizations|>
];

TRPreparationABIValidQ[preparation_Association] := Module[
  {record, roots, variables, epsilon, dimensions, support, oneForms,
   gaugeDenominator, normalizations, payload, storedPayload,
   fingerprint, rootCount, gradeCount, gaugeUnknownCount,
   residueUnknownCount, unknownCount},
  If[Lookup[preparation, "Status", None] =!=
      "PreparedReconstruction", Return[False]];
  record = Lookup[preparation, "Record", $Failed];
  roots = Lookup[preparation, "Roots", $Failed];
  variables = Lookup[preparation, "Variables", $Failed];
  epsilon = Lookup[preparation, "Regulator", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  support = Lookup[preparation, "GaugeSupport", $Failed];
  oneForms = Lookup[preparation, "OneForms", $Failed];
  gaugeDenominator = Lookup[preparation, "GaugeDenominator", $Failed];
  normalizations = Lookup[preparation, "Normalizations", $Failed];
  If[! AssociationQ[record] || ! ListQ[roots] ||
      ! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[dimensions, {_Integer, _Integer}] ||
      ! ListQ[support] || ! ListQ[oneForms] ||
      ! ListQ[normalizations], Return[False]];
  payload = trBuildABIPayload[record, roots, variables, epsilon,
    dimensions, gaugeDenominator, support, oneForms, normalizations];
  If[payload === $Failed, Return[False]];
  storedPayload = Lookup[preparation, "ABIPayload", Missing["Payload"]];
  fingerprint = Hash[ToString[InputForm[payload]],
    "SHA256", "HexString"];
  rootCount = Length[roots];
  gradeCount = 2^rootCount;
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  TrueQ[payload === storedPayload] &&
    Lookup[preparation, "ABIFingerprint", Missing["Fingerprint"]] ===
      fingerprint &&
    Lookup[preparation, "RootFingerprints", Missing["Roots"]] ===
      payload["RootFingerprints"] &&
    Lookup[preparation, "RootSourceIndices", Missing["RootSources"]] ===
      payload["RootSourceIndices"] &&
    Lookup[preparation, "RootOrderingFingerprint",
        Missing["RootOrdering"]] ===
      payload["RootOrderingFingerprint"] &&
    Lookup[preparation, "RootCount", Missing["RootCount"]] ===
      rootCount &&
    Lookup[preparation, "GradeCount", Missing["GradeCount"]] ===
      gradeCount &&
    Lookup[preparation, "GaugeUnknownCount", Missing["Gauge"]] ===
      gaugeUnknownCount &&
    Lookup[preparation, "ResidueUnknownCount", Missing["Residue"]] ===
      residueUnknownCount &&
    Lookup[preparation, "UnknownCount", Missing["Unknown"]] ===
      unknownCount &&
    Lookup[preparation, "EquationsPerPoint", Missing["Equations"]] ===
      gradeCount 2 (Times @@ dimensions)
];

TRStableRootOrder[frame_Association, variables : {_Symbol, _Symbol},
    indices_: Automatic] := Module[
  {current, selectedIndices, roots, decorated, duplicatePairs},
  current = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
  If[! ListQ[current],
    Return[<|"Status" -> "InvalidMultiquadraticFrame"|>]];
  selectedIndices = Replace[indices, Automatic :> Range[Length[current]]];
  If[! ListQ[selectedIndices] ||
      ! AllTrue[selectedIndices, IntegerQ[#1] && 1 <= #1 <= Length[current] &],
    Return[<|"Status" -> "InvalidRootIndices"|>]];
  roots = current[[selectedIndices]];
  duplicatePairs = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[roots[[#[[1]], "RootSquare"]] -
      roots[[#[[2]], "RootSquare"]]] === 0] &];
  If[duplicatePairs =!= {},
    Return[<|"Status" -> "DuplicateRootSquares",
      "DuplicatePairs" -> duplicatePairs|>]];
  decorated = MapThread[
    Function[{root, sourceIndex}, Module[{fingerprint},
      fingerprint = trExpressionFingerprint[root["RootSquare"], variables];
      Join[root, <|"SourceIndex" -> sourceIndex,
        "RootFingerprint" -> fingerprint["SHA256"],
        "CanonicalRootSquare" -> fingerprint["CanonicalString"]|>]
    ]], {roots, selectedIndices}];
  decorated = SortBy[decorated,
    {Lookup[#1, "CanonicalRootSquare", ""],
      Lookup[#1, "RootFingerprint", ""]} &];
  <|"Status" -> "StableRootOrder",
    "Roots" -> decorated,
    "SourceIndices" -> Lookup[decorated, "SourceIndex", {}],
    "RootFingerprints" -> Lookup[decorated, "RootFingerprint", {}],
    "OrderingFingerprint" -> Hash[
      Lookup[decorated, "CanonicalRootSquare", {}],
      "SHA256", "HexString"]|>
];

trGaugeIndex[upperDimension_Integer, lowerDimension_Integer,
    gradeCount_Integer, supportCount_Integer,
    i_Integer, j_Integer, grade_Integer, monomial_Integer] :=
  ((((i - 1) * lowerDimension + (j - 1)) * gradeCount + grade) *
    supportCount) + monomial;

trResidueIndex[gaugeUnknownCount_Integer, upperDimension_Integer,
    lowerDimension_Integer, letter_Integer, i_Integer, j_Integer] :=
  gaugeUnknownCount + (((letter - 1) * upperDimension + (i - 1)) *
    lowerDimension) + j;

TRGaugeCoefficientIndex[preparation_Association, i_Integer,
    j_Integer, grade_Integer, monomial : {_Integer, _Integer}] := Module[
  {dimensions, gradeCount, support, positions, supportIndex},
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  gradeCount = Lookup[preparation, "GradeCount", $Failed];
  support = Lookup[preparation, "GaugeSupport", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] ||
      ! IntegerQ[gradeCount] || ! ListQ[support], Return[$Failed]];
  positions = Flatten[Position[support, monomial, {1}, Heads -> False]];
  If[Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
      j < 1 || j > dimensions[[2]] ||
      grade < 0 || grade >= gradeCount, Return[$Failed]];
  supportIndex = First[positions];
  trGaugeIndex[dimensions[[1]], dimensions[[2]], gradeCount,
    Length[support], i, j, grade, supportIndex]
];

TRResidueIndex[preparation_Association, letter_Integer,
    i_Integer, j_Integer] := Module[
  {dimensions, oneForms, gaugeUnknownCount},
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  oneForms = Lookup[preparation, "OneForms", $Failed];
  gaugeUnknownCount = Lookup[preparation, "GaugeUnknownCount", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || ! ListQ[oneForms] ||
      ! IntegerQ[gaugeUnknownCount] || letter < 1 ||
      letter > Length[oneForms] || i < 1 || i > dimensions[[1]] ||
      j < 1 || j > dimensions[[2]], Return[$Failed]];
  trResidueIndex[gaugeUnknownCount, dimensions[[1]], dimensions[[2]],
    letter, i, j]
];

trCompileNormalizations[specifications_List, dimensions_List,
    gradeCount_Integer, support_List, oneForms_List,
    gaugeUnknownCount_Integer] := Catch[Module[
  {compiled = {}, kind, column, positions, supportIndex, i, j, grade,
   monomial, letter, value},
  Do[
    If[! AssociationQ[specification],
      Throw[<|"Status" -> "InvalidNormalizationEquation",
        "Equation" -> specification|>]];
    kind = Lookup[specification, "Kind", Missing["Kind"]];
    value = Lookup[specification, "Value", Missing["Value"]];
    If[MissingQ[value],
      Throw[<|"Status" -> "InvalidNormalizationEquation",
        "Equation" -> specification|>]];
    column = Switch[kind,
      "Column",
        Lookup[specification, "Column", $Failed],
      "GaugeCoefficient",
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        grade = Lookup[specification, "Grade", $Failed];
        monomial = Lookup[specification, "Monomial", $Failed];
        positions = Flatten[
          Position[support, monomial, {1}, Heads -> False]];
        If[! IntegerQ[i] || ! IntegerQ[j] || ! IntegerQ[grade] ||
            Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]] || grade < 0 ||
            grade >= gradeCount, $Failed,
          supportIndex = First[positions];
          trGaugeIndex[dimensions[[1]], dimensions[[2]], gradeCount,
            Length[support], i, j, grade, supportIndex]],
      "Residue",
        letter = Lookup[specification, "Letter", $Failed];
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        If[! IntegerQ[letter] || ! IntegerQ[i] || ! IntegerQ[j] ||
            letter < 1 || letter > Length[oneForms] ||
            i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]], $Failed,
          trResidueIndex[gaugeUnknownCount, dimensions[[1]],
            dimensions[[2]], letter, i, j]],
      _, $Failed];
    If[! IntegerQ[column] || column < 1 ||
        column > gaugeUnknownCount +
          Length[oneForms] (Times @@ dimensions),
      Throw[<|"Status" -> "InvalidNormalizationEquation",
        "Equation" -> specification,
        "ResolvedColumn" -> column,
        "Dimensions" -> dimensions,
        "GradeCount" -> gradeCount,
        "SupportContainsMonomial" -> MemberQ[support, monomial],
        "GaugeUnknownCount" -> gaugeUnknownCount,
        "ResidueUnknownCount" -> Length[oneForms] (Times @@ dimensions)|>]];
    AppendTo[compiled, <|"Column" -> column, "Value" -> value,
      "Kind" -> kind|>],
    {specification, specifications}];
  If[Length[DeleteDuplicates[Lookup[compiled, "Column", {}]]] =!=
      Length[compiled],
    Throw[<|"Status" -> "DuplicateNormalizationColumn",
      "Normalizations" -> compiled|>]];
  compiled
]];

Options[TRPrepareReconstruction] = {
  "OneForms" -> Automatic,
  "GaugeDenominator" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  "NormalizationEquations" -> {}
};

TRPrepareReconstruction[record_Association, frame_Association,
    OptionsPattern[]] := Module[
  {classification, variables, epsilon, stableOrder, roots, strip,
   channelForcing, oneFormData, oneForms, gaugeDenominator,
   denominatorDegrees, degreeOffset, numeratorDegrees, support,
   dimensions, gradeCount, gaugeUnknownCount, residueUnknownCount,
   unknownCount, equationsPerPoint, normalizations, abiPayload,
   abiFingerprint},
  classification = CodexTripleRootStrip`TRClassifyStripRecord[record, frame];
  If[Lookup[classification, "Status", None] =!=
      "ExactRootClassification", Return[classification]];
  If[Lookup[classification, "RootCount", 0] < 1,
    Return[Join[classification, <|"Status" -> "NoActiveRoots"|>]]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[<|"Status" -> "InvalidStripRecord"|>]];
  stableOrder = TRStableRootOrder[frame, variables,
    classification["RootIndices"]];
  If[Lookup[stableOrder, "Status", None] =!= "StableRootOrder",
    Return[stableOrder]];
  roots = stableOrder["Roots"];
  channelForcing = Map[
    CodexTripleRootStrip`TRFieldDecompose[#1, roots] &,
    strip[[3]], {3}];
  If[! FreeQ[channelForcing, $Failed],
    Return[Join[classification,
      <|"Status" -> "ForcingChannelDecompositionFailed",
        "RootOrder" -> stableOrder|>]]];
  oneFormData = OptionValue["OneForms"];
  If[oneFormData === Automatic,
    oneFormData = CodexTripleRootStrip`TRCandidateOneFormBasis[
      strip, roots, variables, epsilon]];
  oneForms = If[AssociationQ[oneFormData],
    Lookup[oneFormData, "OneForms", $Failed], oneFormData];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[Join[classification,
      <|"Status" -> "OneFormBasisFailed"|>]]];
  gaugeDenominator = Replace[OptionValue["GaugeDenominator"],
    Automatic :> CodexTripleRootStrip`TRRationalGaugeDenominator[
      channelForcing, variables]];
  If[TrueQ[Together[gaugeDenominator] === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[Join[classification,
      <|"Status" -> "GaugeDenominatorNotRational"|>]]];
  denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset,
      {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[<|"Status" -> "InvalidDegreeOffset"|>]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  If[support === Automatic,
    support = Flatten[Table[{i, j}, {i, 0, numeratorDegrees[[1]]},
      {j, 0, numeratorDegrees[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support,
        MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[<|"Status" -> "InvalidSupport"|>]];
  support = Sort[DeleteDuplicates[support]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] ||
      Dimensions[strip[[3, 2]]] =!= dimensions,
    Return[<|"Status" -> "InvalidForcingDimensions"|>]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  normalizations = trCompileNormalizations[
    OptionValue["NormalizationEquations"], dimensions, gradeCount,
    support, oneForms, gaugeUnknownCount];
  If[AssociationQ[normalizations] &&
      Lookup[normalizations, "Status", None] =!= None,
    Return[normalizations]];
  abiPayload = trBuildABIPayload[record, roots, variables, epsilon,
    dimensions, gaugeDenominator, support, oneForms, normalizations];
  If[abiPayload === $Failed,
    Return[<|"Status" -> "PreparationABIFingerprintFailed"|>]];
  abiFingerprint = Hash[ToString[InputForm[abiPayload]],
    "SHA256", "HexString"];
  Join[classification, <|
    "Status" -> "PreparedReconstruction",
    "Record" -> record,
    "Frame" -> frame,
    "Variables" -> variables,
    "Regulator" -> epsilon,
    "Roots" -> roots,
    "RootCount" -> Length[roots],
    "RootSourceIndices" -> Lookup[roots, "SourceIndex", {}],
    "RootFingerprints" -> Lookup[roots, "RootFingerprint", {}],
    "RootOrderingFingerprint" -> stableOrder["OrderingFingerprint"],
    "OneForms" -> oneForms,
    "OneFormMetadata" -> oneFormData,
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeSupport" -> support,
    "Dimensions" -> dimensions,
    "GradeCount" -> gradeCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "Normalizations" -> normalizations,
    "ABIPayload" -> abiPayload,
    "ABIFingerprint" -> abiFingerprint|>]
];

trPermutePointBranches[pointData_Association, rank_Integer,
    equationsPerSign_Integer, flipMask_Integer] := Module[
  {gradeCount = 2^rank, rows, right, order},
  If[flipMask < 0 || flipMask >= gradeCount, Return[$Failed]];
  rows = Lookup[pointData, "Rows", $Failed];
  right = Lookup[pointData, "RightHandSide", $Failed];
  If[! ListQ[rows] || ! ListQ[right] ||
      Length[rows] =!= gradeCount equationsPerSign ||
      Length[right] =!= Length[rows], Return[$Failed]];
  order = Flatten[Table[
    Range[BitXor[signMask, flipMask] equationsPerSign + 1,
      (BitXor[signMask, flipMask] + 1) equationsPerSign],
    {signMask, 0, gradeCount - 1}]];
  Join[pointData, <|"Rows" -> rows[[order]],
    "RightHandSide" -> right[[order]],
    "BranchFlipMask" -> flipMask|>]
];

Options[TRAssembleReconstructionSample] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260823,
  "BranchFlipMask" -> 0
};

Options[trAssembleReconstructionSampleInternal] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260823,
  "BranchFlipMask" -> 0,
  (* A trusted caller first runs TRPreparationABIValidQ once, then passes
     the resulting stored fingerprint to avoid canonicalizing a large
     physical equation again at every regulator sample.  A missing or
     mismatched token retains the full public-boundary validation. *)
  "ValidatedABIFingerprint" -> Automatic
};

TRAssembleReconstructionSample[preparation_Association, epsilonValue_,
    prime_Integer, OptionsPattern[]] := Module[{fingerprint},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  fingerprint = preparation["ABIFingerprint"];
  Block[{$trValidatedABIFingerprint = fingerprint},
    trAssembleReconstructionSampleInternal[preparation, epsilonValue,
      prime, "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> OptionValue["RandomSeed"],
      "BranchFlipMask" -> OptionValue["BranchFlipMask"],
      "ValidatedABIFingerprint" -> fingerprint]]
];

trAssembleReconstructionSampleInternal[preparation_Association, epsilonValue_,
    prime_Integer, OptionsPattern[]] := Module[
  {record, roots, oneForms, gaugeDenominator, support, unknownCount,
   equationsPerPoint, dimensions, equationsPerSign, pointCount,
   maximumAttempts, randomSeed, flipMask, accepted = {}, attempts = 0,
   point, pointData, pointRows, right, normalizationRows,
   normalizationRight, value, matrix, validatedFingerprint},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidPreparation"|>]];
  validatedFingerprint = OptionValue["ValidatedABIFingerprint"];
  If[! trPreparationFastPathQ[preparation, validatedFingerprint] &&
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  If[! PrimeQ[prime] || Mod[prime, 4] =!= 3,
    Return[<|"Status" -> "PrimeMustBe3Mod4", "Prime" -> prime|>]];
  If[trModNumber[epsilonValue, prime] === $Failed ||
      trModNumber[epsilonValue, prime] === 0,
    Return[<|"Status" -> "InvalidEpsilonSample",
      "Prime" -> prime, "EpsilonValue" -> epsilonValue|>]];
  record = preparation["Record"];
  roots = preparation["Roots"];
  oneForms = preparation["OneForms"];
  gaugeDenominator = preparation["GaugeDenominator"];
  support = preparation["GaugeSupport"];
  unknownCount = preparation["UnknownCount"];
  equationsPerPoint = preparation["EquationsPerPoint"];
  dimensions = preparation["Dimensions"];
  equationsPerSign = 2 Times @@ dimensions;
  pointCount = Replace[OptionValue["PointCount"],
    Automatic :> Max[4, Ceiling[(unknownCount + equationsPerPoint)/
      equationsPerPoint]]];
  If[! IntegerQ[pointCount] || pointCount < 1,
    Return[<|"Status" -> "InvalidPointCount"|>]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  If[! IntegerQ[maximumAttempts] || maximumAttempts < pointCount,
    Return[<|"Status" -> "InvalidMaximumAttempts"|>]];
  randomSeed = OptionValue["RandomSeed"];
  flipMask = OptionValue["BranchFlipMask"];
  If[! IntegerQ[flipMask] || flipMask < 0 ||
      flipMask >= preparation["GradeCount"],
    Return[<|"Status" -> "InvalidBranchFlipMask"|>]];
  BlockRandom[
    SeedRandom[randomSeed];
    While[Length[accepted] < pointCount && attempts < maximumAttempts,
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      pointData = Quiet[CodexTripleRootPilot`TRSplitPointRows[
        record, roots, oneForms, gaugeDenominator, support,
        epsilonValue, prime, point]];
      If[AssociationQ[pointData],
        pointData = trPermutePointBranches[pointData,
          preparation["RootCount"], equationsPerSign, flipMask];
        If[AssociationQ[pointData], AppendTo[accepted, pointData]]]
    ]
  ];
  If[Length[accepted] < pointCount,
    Return[<|"Status" -> "InsufficientSplitPoints",
      "Prime" -> prime, "EpsilonValue" -> epsilonValue,
      "AcceptedPointCount" -> Length[accepted],
      "AttemptCount" -> attempts|>]];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  right = Join @@ Lookup[accepted, "RightHandSide"];
  normalizationRows = Table[
    SparseArray[{normalization["Column"] -> 1}, unknownCount],
    {normalization, preparation["Normalizations"]}];
  normalizationRight = Table[
    value = trModNumber[
      normalization["Value"] /.
        preparation["Regulator"] -> epsilonValue, prime];
    value,
    {normalization, preparation["Normalizations"]}];
  If[MemberQ[normalizationRight, $Failed],
    Return[<|"Status" -> "NormalizationValueSingular",
      "Prime" -> prime, "EpsilonValue" -> epsilonValue|>]];
  matrix = SparseArray[Join[pointRows, normalizationRows]];
  right = Mod[Join[right, normalizationRight], prime];
  <|"Status" -> "AssembledReconstructionSample",
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "Prime" -> prime,
    "EpsilonValue" -> epsilonValue,
    "Matrix" -> matrix,
    "RightHandSide" -> right,
    "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point", {}],
    "AttemptCount" -> attempts,
    "BranchFlipMask" -> flipMask,
    "NormalizationCount" -> Length[normalizationRows]|>
];

TRCanonicalAffineSolve[matrix_?MatrixQ, right_List,
    prime_Integer] := Module[
  {dimensions = Dimensions[matrix], unknownCount, augmented, reduced,
   coefficientPart, pivotRows = {}, pivotColumns = {}, position,
   inconsistentRows, freeColumns, particular, nullspace, residual,
   nullResidual},
  If[! PrimeQ[prime],
    Return[<|"Status" -> "InvalidPrime", "Prime" -> prime|>]];
  If[Length[dimensions] =!= 2 || dimensions[[1]] =!= Length[right],
    Return[<|"Status" -> "AffineDimensionMismatch"|>]];
  unknownCount = dimensions[[2]];
  augmented = MapThread[Append,
    {Mod[Normal[matrix], prime], Mod[right, prime]}];
  reduced = RowReduce[augmented, Modulus -> prime];
  coefficientPart = reduced[[All, 1 ;; unknownCount]];
  Do[
    position = SelectFirst[Range[unknownCount],
      Mod[coefficientPart[[row, #1]], prime] =!= 0 &,
      Missing["NotFound"]];
    If[! MissingQ[position],
      AppendTo[pivotRows, row];
      AppendTo[pivotColumns, position]],
    {row, Length[coefficientPart]}];
  If[! DuplicateFreeQ[pivotColumns] ||
      ! AllTrue[pivotColumns, IntegerQ[#1] && 1 <= #1 <= unknownCount &] ||
      Length[pivotColumns] > Min[dimensions],
    Return[<|"Status" -> "InvalidPivotStructure",
      "Prime" -> prime,
      "MatrixDimensions" -> dimensions,
      "PivotColumns" -> pivotColumns|>]];
  inconsistentRows = Select[Range[Length[coefficientPart]],
    trZeroQ[Mod[coefficientPart[[#1]], prime]] &&
      Mod[reduced[[#1, -1]], prime] =!= 0 &];
  If[inconsistentRows =!= {},
    Return[<|"Status" -> "InconsistentModularSystem",
      "Prime" -> prime,
      "MatrixDimensions" -> dimensions,
      "InconsistentRows" -> inconsistentRows|>]];
  freeColumns = Complement[Range[unknownCount], pivotColumns];
  particular = ConstantArray[0, unknownCount];
  Do[particular[[pivotColumns[[k]]]] =
      Mod[reduced[[pivotRows[[k]], -1]], prime],
    {k, Length[pivotColumns]}];
  nullspace = Table[Module[{vector = ConstantArray[0, unknownCount]},
    vector[[free]] = 1;
    Do[vector[[pivotColumns[[k]]]] = Mod[
        -reduced[[pivotRows[[k]], free]], prime],
      {k, Length[pivotColumns]}];
    vector], {free, freeColumns}];
  residual = AllTrue[Mod[matrix . particular - right, prime],
    #1 === 0 &];
  nullResidual = AllTrue[nullspace, Function[vector,
    AllTrue[Mod[matrix . vector, prime], #1 === 0 &]]];
  <|"Status" -> If[TrueQ[residual] && TrueQ[nullResidual],
      "CanonicalAffineSolution", "CanonicalAffineResidualNonzero"],
    "Prime" -> prime,
    "MatrixDimensions" -> dimensions,
    "Rank" -> Length[pivotColumns],
    "Nullity" -> Length[freeColumns],
    "PivotColumns" -> pivotColumns,
    "FreeColumns" -> freeColumns,
    "PivotSignature" -> Hash[pivotColumns, "SHA256", "HexString"],
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> nullspace,
    "ResidualZero" -> residual,
    "NullspaceResidualZero" -> nullResidual|>
];

trInterpolatePolynomialMod[values_List, epsilonValues_List,
    degree_Integer, prime_Integer] := Module[
  {componentCount, sampleMods, trainingCount, vandermonde,
   coefficients, validationResiduals},
  If[Length[values] =!= Length[epsilonValues] || values === {} ||
      ! MatrixQ[values, IntegerQ], Return[$Failed]];
  componentCount = Length[First[values]];
  If[! AllTrue[values, Length[#1] === componentCount &], Return[$Failed]];
  sampleMods = trModNumber[#1, prime] & /@ epsilonValues;
  If[MemberQ[sampleMods, $Failed], Return[$Failed]];
  trainingCount = degree + 1;
  If[Length[values] < trainingCount, Return[$Failed]];
  vandermonde = Table[PowerMod[sampleMods[[row]], power, prime],
    {row, trainingCount}, {power, 0, degree}];
  coefficients = Quiet[Check[
    LinearSolve[vandermonde, Take[values, trainingCount],
      Modulus -> prime], $Failed]];
  If[coefficients === $Failed, Return[$Failed]];
  coefficients = Mod[coefficients, prime];
  validationResiduals = Table[
    Mod[Sum[sampleMods[[sample]]^power *
          coefficients[[power + 1]], {power, 0, degree}] -
      values[[sample]], prime],
    {sample, Length[values]}];
  <|"Coefficients" -> coefficients,
    "ValidationZero" -> AllTrue[Flatten[validationResiduals], #1 === 0 &],
    "ValidationResiduals" -> validationResiduals|>
];

trRationalReconstruct[residue_Integer, modulus_Integer] := Module[
  {bound, r0 = modulus, r1 = Mod[residue, modulus],
   t0 = 0, t1 = 1, quotient, nextR, nextT, numerator, denominator},
  If[modulus <= 1, Return[$Failed]];
  If[Mod[residue, modulus] === 0, Return[0]];
  bound = Floor[Sqrt[modulus/2]];
  While[Abs[r1] > bound && r1 =!= 0,
    quotient = Quotient[r0, r1];
    nextR = r0 - quotient r1;
    nextT = t0 - quotient t1;
    {r0, r1} = {r1, nextR};
    {t0, t1} = {t1, nextT};
  ];
  If[r1 === 0 || t1 === 0, Return[$Failed]];
  numerator = r1;
  denominator = t1;
  If[denominator < 0,
    numerator = -numerator;
    denominator = -denominator];
  If[Abs[numerator] > bound || denominator > bound ||
      CoprimeQ[numerator, denominator] =!= True ||
      Mod[denominator residue - numerator, modulus] =!= 0,
    Return[$Failed]];
  numerator/denominator
];

trCRTRecover[residues_List, primes_List] := Module[
  {combined, modulus},
  If[Length[residues] =!= Length[primes] || residues === {},
    Return[$Failed]];
  combined = ChineseRemainder[Mod[residues, primes], primes];
  modulus = Times @@ primes;
  trRationalReconstruct[combined, modulus]
];

trRecoverCoefficientMatrix[data_List, primes_List] := Module[
  {dimensions, recovered},
  If[data === {} || ! AllTrue[data, ArrayQ] ||
      Length[DeleteDuplicates[Dimensions /@ data]] =!= 1,
    Return[$Failed]];
  dimensions = Dimensions[First[data]];
  recovered = Table[
    trCRTRecover[Table[data[[primeIndex, degreeIndex, component]],
      {primeIndex, Length[primes]}], primes],
    {degreeIndex, dimensions[[1]]},
    {component, dimensions[[2]]}];
  If[! FreeQ[recovered, $Failed], $Failed, recovered]
];

trRecoverNullspaceCoefficients[data_List, primes_List] := Module[
  {dimensions, recovered},
  If[data === {} || ! AllTrue[data, ArrayQ] ||
      Length[DeleteDuplicates[Dimensions /@ data]] =!= 1,
    Return[$Failed]];
  dimensions = Dimensions[First[data]];
  If[Length[dimensions] =!= 3, Return[$Failed]];
  recovered = Table[
    trCRTRecover[Table[
      data[[primeIndex, degreeIndex, basisIndex, component]],
      {primeIndex, Length[primes]}], primes],
    {degreeIndex, dimensions[[1]]},
    {basisIndex, dimensions[[2]]},
    {component, dimensions[[3]]}];
  If[! FreeQ[recovered, $Failed], $Failed, recovered]
];

Options[TRReconstructAffineBatch] = {
  "EpsilonDegree" -> 0,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260823,
  "Verbose" -> True,
  "RequireExactResidual" -> True
};

TRReconstructAffineBatch[preparation_Association,
    epsilonValues_List, primes_List, OptionsPattern[]] := Module[
  {degree, verbose, log, pointCount, maximumAttempts, randomSeed,
   sampleRecords = {}, primeRecords = {}, sample, solve,
   referencePivots = Missing["NotSet"], referenceFree = Missing["NotSet"],
   particularValues, nullspaceValues, particularInterpolation,
   nullspaceInterpolation, flattenedNullspace, nullity,
   particularCoefficientData, nullspaceCoefficientData,
   reconstructedParticularCoefficients,
   reconstructedNullspaceCoefficients, epsilon,
   reconstructedVector, reconstructedNullspace, unpacked, exact,
   primeIndex, epsilonIndex, prime, seed},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidPreparation"|>]];
  If[! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  degree = OptionValue["EpsilonDegree"];
  If[! IntegerQ[degree] || degree < 0,
    Return[<|"Status" -> "InvalidEpsilonDegree"|>]];
  If[Length[epsilonValues] < degree + 2,
    Return[<|"Status" -> "InsufficientEpsilonSamples",
      "Required" -> degree + 2,
      "Provided" -> Length[epsilonValues]|>]];
  If[Length[DeleteDuplicates[epsilonValues]] =!= Length[epsilonValues],
    Return[<|"Status" -> "DuplicateEpsilonSamples"|>]];
  If[Length[primes] < 2 || ! AllTrue[primes,
      PrimeQ[#1] && Mod[#1, 4] === 3 &] ||
      Length[DeleteDuplicates[primes]] =!= Length[primes],
    Return[<|"Status" -> "InvalidReconstructionPrimes"|>]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["TRRECON ", items]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  randomSeed = OptionValue["RandomSeed"];
  Do[
    prime = primes[[primeIndex]];
    log["prime=", prime, " (", primeIndex, "/", Length[primes], ")"];
    sampleRecords = {};
    Do[
      seed = Hash[{randomSeed, preparation["ABIFingerprint"],
        primeIndex, epsilonIndex}, "CRC32"];
      sample = TRAssembleReconstructionSample[preparation,
        epsilonValues[[epsilonIndex]], prime,
        "PointCount" -> pointCount,
        "MaximumAttempts" -> maximumAttempts,
        "RandomSeed" -> seed];
      If[Lookup[sample, "Status", None] =!=
          "AssembledReconstructionSample",
        Return[Join[sample, <|"Status" -> "ModularSampleAssemblyFailed",
          "FailedPrime" -> prime,
          "FailedEpsilonValue" -> epsilonValues[[epsilonIndex]]|>]]];
      solve = TRCanonicalAffineSolve[sample["Matrix"],
        sample["RightHandSide"], prime];
      If[Lookup[solve, "Status", None] =!= "CanonicalAffineSolution",
        Return[Join[solve, <|"Status" -> "ModularAffineSolveFailed",
          "FailedPrime" -> prime,
          "FailedEpsilonValue" -> epsilonValues[[epsilonIndex]]|>]]];
      If[MissingQ[referencePivots],
        referencePivots = solve["PivotColumns"];
        referenceFree = solve["FreeColumns"],
        If[solve["PivotColumns"] =!= referencePivots ||
            solve["FreeColumns"] =!= referenceFree,
          Return[<|"Status" -> "PivotSignatureChanged",
            "Prime" -> prime,
            "EpsilonValue" -> epsilonValues[[epsilonIndex]],
            "ReferencePivotColumns" -> referencePivots,
            "ObservedPivotColumns" -> solve["PivotColumns"]|>]]];
      AppendTo[sampleRecords, <|
        "Prime" -> prime,
        "EpsilonValue" -> epsilonValues[[epsilonIndex]],
        "AcceptedPoints" -> sample["AcceptedPoints"],
        "AttemptCount" -> sample["AttemptCount"],
        "MatrixDimensions" -> sample["MatrixDimensions"],
        "ParticularSolution" -> solve["ParticularSolution"],
        "NullspaceBasis" -> solve["NullspaceBasis"],
        "Rank" -> solve["Rank"],
        "Nullity" -> solve["Nullity"]|>],
      {epsilonIndex, Length[epsilonValues]}];
    particularValues = Lookup[sampleRecords, "ParticularSolution"];
    particularInterpolation = trInterpolatePolynomialMod[
      particularValues, epsilonValues, degree, prime];
    If[! AssociationQ[particularInterpolation] ||
        ! TrueQ[particularInterpolation["ValidationZero"]],
      Return[<|"Status" -> "ParticularEpsilonDegreeInsufficient",
        "Prime" -> prime, "EpsilonDegree" -> degree|>]];
    nullity = First[Lookup[sampleRecords, "Nullity"]];
    If[nullity === 0,
      nullspaceInterpolation = <|"Coefficients" ->
        ConstantArray[{}, degree + 1], "ValidationZero" -> True|>,
      nullspaceValues = Lookup[sampleRecords, "NullspaceBasis"];
      flattenedNullspace = Flatten[#1, 1] & /@ nullspaceValues;
      nullspaceInterpolation = trInterpolatePolynomialMod[
        flattenedNullspace, epsilonValues, degree, prime];
      If[! AssociationQ[nullspaceInterpolation] ||
          ! TrueQ[nullspaceInterpolation["ValidationZero"]],
        Return[<|"Status" -> "NullspaceEpsilonDegreeInsufficient",
          "Prime" -> prime, "EpsilonDegree" -> degree|>]];
      nullspaceInterpolation = Join[nullspaceInterpolation,
        <|"Coefficients" -> Map[
          ArrayReshape[#1, {nullity, preparation["UnknownCount"]}] &,
          nullspaceInterpolation["Coefficients"]]|>]
    ];
    AppendTo[primeRecords, <|
      "Prime" -> prime,
      "Samples" -> sampleRecords,
      "ParticularCoefficients" ->
        particularInterpolation["Coefficients"],
      "NullspaceCoefficients" ->
        nullspaceInterpolation["Coefficients"]|>],
    {primeIndex, Length[primes]}];
  particularCoefficientData =
    Lookup[primeRecords, "ParticularCoefficients"];
  reconstructedParticularCoefficients = trRecoverCoefficientMatrix[
    particularCoefficientData, primes];
  If[reconstructedParticularCoefficients === $Failed,
    Return[<|"Status" -> "ParticularRationalReconstructionFailed",
      "Primes" -> primes|>]];
  nullspaceCoefficientData = Lookup[primeRecords,
    "NullspaceCoefficients"];
  reconstructedNullspaceCoefficients = If[referenceFree === {},
    ConstantArray[{}, degree + 1],
    trRecoverNullspaceCoefficients[nullspaceCoefficientData, primes]];
  If[reconstructedNullspaceCoefficients === $Failed,
    Return[<|"Status" -> "NullspaceRationalReconstructionFailed",
      "Primes" -> primes|>]];
  epsilon = preparation["Regulator"];
  reconstructedVector = Together /@ Sum[
    reconstructedParticularCoefficients[[power + 1]] epsilon^power,
    {power, 0, degree}];
  reconstructedNullspace = If[referenceFree === {}, {},
    Map[Together, Sum[
      reconstructedNullspaceCoefficients[[power + 1]] epsilon^power,
      {power, 0, degree}], {2}]];
  unpacked = TRUnpackReconstructedVector[preparation,
    reconstructedVector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedReconstruction",
    Return[unpacked]];
  exact = TRExactChannelResidual[preparation, reconstructedVector];
  If[TrueQ[OptionValue["RequireExactResidual"]] &&
      ! TrueQ[Lookup[exact, "ResidualZero", False]],
    Return[<|"Status" -> "ExactResidualNonzero",
      "Primes" -> primes,
      "EpsilonDegree" -> degree,
      "Preparation" -> preparation,
      "ReconstructedVector" -> reconstructedVector,
      "ExactVerification" -> exact|>]];
  <|"Status" -> If[TrueQ[Lookup[exact, "ResidualZero", False]],
      "ExactReconstruction", "ReconstructedWithoutExactCertificate"],
    "Preparation" -> preparation,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "Primes" -> primes,
    "EpsilonValues" -> epsilonValues,
    "EpsilonDegree" -> degree,
    "PivotColumns" -> referencePivots,
    "FreeColumns" -> referenceFree,
    "Rank" -> Length[referencePivots],
    "Nullity" -> Length[referenceFree],
    "ParticularCoefficientVectors" ->
      reconstructedParticularCoefficients,
    "NullspaceCoefficientVectors" ->
      reconstructedNullspaceCoefficients,
    "ReconstructedVector" -> reconstructedVector,
    "ReconstructedNullspace" -> reconstructedNullspace,
    "GaugeChannels" -> unpacked["GaugeChannels"],
    "Residues" -> unpacked["Residues"],
    "ExactVerification" -> exact,
    "ModularSampleSummary" -> Map[
      KeyDrop[#1, {"Samples"}] &, primeRecords]|>
];

$trCrossPrimeEliminationPlanVersion = 1;
$trCrossPrimeEliminationPlanPayloadKeys = {
  "Status", "PlanVersion", "ABIFingerprint",
  "RootOrderingFingerprint", "MatrixDimensions", "PointCount",
  "NormalizationEquationCount", "BranchFlipMask",
  "IndependentEquationRows", "NormalizationColumns", "GenericRank",
  "Nullity", "UnknownCount", "GaugeUnknownCount", "FreeResidueCount",
  "GaugeNumeratorDegrees", "GaugeDenominatorDegrees", "GaugeSupport",
  "PilotPrime", "PilotEpsilonValue", "PilotRandomSeed",
  "PilotAcceptedPoints", "PilotPivotColumns", "PilotFreeColumns",
  "DiscoveryMethod"};

trStableAssociationFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

trCrossPrimeEliminationPlanPayload[plan_Association] :=
  KeyTake[plan, $trCrossPrimeEliminationPlanPayloadKeys];

trCrossPrimeEliminationPlanFingerprint[plan_Association] :=
  trStableAssociationFingerprint[
    trCrossPrimeEliminationPlanPayload[plan]];

trDegreeProfileQ[profile_, coordinateCount_Integer] :=
  ListQ[profile] && Length[profile] === coordinateCount &&
    AllTrue[profile, TrueQ[#1 === {-Infinity, 0}] ||
      (MatchQ[#1, {_Integer, _Integer}] && Min[#1] >= 0) &];

trCrossPrimeEliminationPlanValidQ[preparation_Association,
    plan_Association, expectedMatrixDimensions_: Automatic] := Module[
  {requiredKeys, matrixDimensions, pointCount, normalizationCount,
   rank, nullity, unknownCount, rows, normalizationColumns,
   pilotPivotColumns, pilotFreeColumns, pilotPrime, acceptedPoints,
   numeratorDegrees},
  requiredKeys = Append[$trCrossPrimeEliminationPlanPayloadKeys,
    "PlanFingerprint"];
  If[Sort[Keys[plan]] =!= Sort[requiredKeys] ||
      ! AllTrue[requiredKeys, KeyExistsQ[plan, #1] &], Return[False]];
  matrixDimensions = plan["MatrixDimensions"];
  pointCount = plan["PointCount"];
  normalizationCount = plan["NormalizationEquationCount"];
  rank = plan["GenericRank"];
  nullity = plan["Nullity"];
  unknownCount = plan["UnknownCount"];
  rows = plan["IndependentEquationRows"];
  normalizationColumns = plan["NormalizationColumns"];
  pilotPivotColumns = plan["PilotPivotColumns"];
  pilotFreeColumns = plan["PilotFreeColumns"];
  pilotPrime = plan["PilotPrime"];
  acceptedPoints = plan["PilotAcceptedPoints"];
  numeratorDegrees = Max /@ Transpose[preparation["GaugeSupport"]];
  TrueQ[
    plan["Status"] === "CrossPrimeEliminationPlanV1" &&
    plan["PlanVersion"] === $trCrossPrimeEliminationPlanVersion &&
    plan["ABIFingerprint"] === preparation["ABIFingerprint"] &&
    plan["RootOrderingFingerprint"] ===
      preparation["RootOrderingFingerprint"] &&
    MatchQ[matrixDimensions, {_Integer, _Integer}] &&
    matrixDimensions[[1]] >= 1 &&
    matrixDimensions[[2]] === preparation["UnknownCount"] &&
    (expectedMatrixDimensions === Automatic ||
      matrixDimensions === expectedMatrixDimensions) &&
    IntegerQ[pointCount] && pointCount >= 1 &&
    IntegerQ[normalizationCount] && normalizationCount >= 0 &&
    normalizationCount === Length[preparation["Normalizations"]] &&
    matrixDimensions[[1]] ===
      pointCount preparation["EquationsPerPoint"] + normalizationCount &&
    plan["BranchFlipMask"] === 0 &&
    IntegerQ[rank] && rank >= 0 && IntegerQ[nullity] && nullity >= 0 &&
    IntegerQ[unknownCount] && unknownCount >= 1 &&
    unknownCount === preparation["UnknownCount"] &&
    rank + nullity === unknownCount &&
    VectorQ[rows, IntegerQ] && Length[rows] === rank &&
    DuplicateFreeQ[rows] && rows === Sort[rows] &&
    AllTrue[rows, 1 <= #1 <= matrixDimensions[[1]] &] &&
    VectorQ[normalizationColumns, IntegerQ] &&
    Length[normalizationColumns] === nullity &&
    DuplicateFreeQ[normalizationColumns] &&
    normalizationColumns === Sort[normalizationColumns] &&
    AllTrue[normalizationColumns, 1 <= #1 <= unknownCount &] &&
    VectorQ[pilotPivotColumns, IntegerQ] &&
    VectorQ[pilotFreeColumns, IntegerQ] &&
    Length[pilotPivotColumns] === rank &&
    Length[pilotFreeColumns] === nullity &&
    pilotPivotColumns === Sort[pilotPivotColumns] &&
    pilotFreeColumns === Sort[pilotFreeColumns] &&
    Sort[Join[pilotPivotColumns, pilotFreeColumns]] ===
      Range[unknownCount] &&
    plan["GaugeUnknownCount"] === preparation["GaugeUnknownCount"] &&
    plan["FreeResidueCount"] === preparation["ResidueUnknownCount"] &&
    plan["GaugeNumeratorDegrees"] === numeratorDegrees &&
    plan["GaugeDenominatorDegrees"] ===
      preparation["GaugeDenominatorDegrees"] &&
    plan["GaugeSupport"] === preparation["GaugeSupport"] &&
    IntegerQ[pilotPrime] && 2 < pilotPrime < 2^31 &&
    PrimeQ[pilotPrime] && Mod[pilotPrime, 4] === 3 &&
    trModNumber[plan["PilotEpsilonValue"], pilotPrime] =!= $Failed &&
    trModNumber[plan["PilotEpsilonValue"], pilotPrime] =!= 0 &&
    IntegerQ[plan["PilotRandomSeed"]] &&
    MatrixQ[acceptedPoints, IntegerQ] &&
    Dimensions[acceptedPoints] === {pointCount, 2} &&
    AllTrue[Flatten[acceptedPoints],
      2 <= #1 <= pilotPrime - 2 &] &&
    plan["DiscoveryMethod"] ===
      "CanonicalRREFPlusProductionPlanDiscovery" &&
    StringQ[plan["PlanFingerprint"]] &&
    plan["PlanFingerprint"] ===
      trCrossPrimeEliminationPlanFingerprint[plan]]
];

TRCrossPrimeEliminationPlanValidQ[preparation_Association,
    plan_Association] :=
  TrueQ[TRPreparationABIValidQ[preparation]] &&
    trCrossPrimeEliminationPlanValidQ[preparation, plan];

trFinalizeCrossPrimeEliminationPlan[preparation_Association,
    discovered_Association, sample_Association, solve_Association,
    seed_Integer] := Module[{payload},
  payload = <|
    "Status" -> "CrossPrimeEliminationPlanV1",
    "PlanVersion" -> $trCrossPrimeEliminationPlanVersion,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"],
    "MatrixDimensions" -> sample["MatrixDimensions"],
    "PointCount" -> Length[sample["AcceptedPoints"]],
    "NormalizationEquationCount" -> sample["NormalizationCount"],
    "BranchFlipMask" -> sample["BranchFlipMask"],
    "IndependentEquationRows" -> discovered["IndependentEquationRows"],
    "NormalizationColumns" -> discovered["NormalizationColumns"],
    "GenericRank" -> discovered["GenericRank"],
    "Nullity" -> discovered["Nullity"],
    "UnknownCount" -> discovered["UnknownCount"],
    "GaugeUnknownCount" -> discovered["GaugeUnknownCount"],
    "FreeResidueCount" -> discovered["FreeResidueCount"],
    "GaugeNumeratorDegrees" -> discovered["GaugeNumeratorDegrees"],
    "GaugeDenominatorDegrees" -> discovered["GaugeDenominatorDegrees"],
    "GaugeSupport" -> preparation["GaugeSupport"],
    "PilotPrime" -> sample["Prime"],
    "PilotEpsilonValue" -> sample["EpsilonValue"],
    "PilotRandomSeed" -> seed,
    "PilotAcceptedPoints" -> sample["AcceptedPoints"],
    "PilotPivotColumns" -> solve["PivotColumns"],
    "PilotFreeColumns" -> solve["FreeColumns"],
    "DiscoveryMethod" ->
      "CanonicalRREFPlusProductionPlanDiscovery"|>;
  Append[payload, "PlanFingerprint" ->
    trStableAssociationFingerprint[payload]]
];

trSolveReconstructionWithPlan[preparation_Association,
    matrix_?MatrixQ, right_List, plan_Association, prime_Integer,
    backend_, backendThreads_Integer, backendFallback_?BooleanQ] :=
 Module[{rank, nullity, unknownCount, rows, normalizationColumns,
   selector, core, rhsMatrix, solutionMatrix, flint, backendUsed,
   backendAttempted, particular, nullspace, normalizationOK, residual,
   nullResidual},
  If[! PrimeQ[prime] || !(2 < prime < 2^31) ||
      backendThreads < 1 ||
      ! trCrossPrimeEliminationPlanValidQ[preparation, plan,
        Dimensions[matrix]],
    Return[<|"Status" -> "InvalidCrossPrimeEliminationPlan",
      "Prime" -> prime|>]];
  rank = plan["GenericRank"];
  nullity = plan["Nullity"];
  unknownCount = plan["UnknownCount"];
  rows = plan["IndependentEquationRows"];
  normalizationColumns = plan["NormalizationColumns"];
  If[Length[right] =!= Dimensions[matrix][[1]] ||
      ! MatrixQ[matrix, IntegerQ] || ! VectorQ[right, IntegerQ],
    Return[<|"Status" -> "EliminationPlanDimensionMismatch"|>]];
  If[nullity === 0,
    core = matrix[[rows]];
    rhsMatrix = List /@ right[[rows]],
    selector = SparseArray[
      MapIndexed[{First[#2], #1} -> 1 &, normalizationColumns],
      {nullity, unknownCount}];
    core = Join[matrix[[rows]], selector];
    rhsMatrix = Join[
      Join[List /@ right[[rows]],
        ConstantArray[0, {rank, nullity}], 2],
      Join[ConstantArray[0, {nullity, 1}],
        IdentityMatrix[nullity], 2]]];
  backendUsed = "Wolfram";
  flint = $Failed;
  backendAttempted = FeynFacet`Private`finiteFieldStripBackendQ[
    backend, Length[core]];
  If[TrueQ[backendAttempted],
    flint = FeynFacet`Private`finiteFieldStripFLINTSolve[
      core, rhsMatrix, prime, backendThreads];
    If[MatrixQ[flint, IntegerQ], backendUsed = "FLINT"]];
  solutionMatrix = Which[
    MatrixQ[flint, IntegerQ], flint,
    TrueQ[backendFallback],
      If[TrueQ[backendAttempted],
        backendUsed = "WolframFixedCoreFallback"];
      Quiet[Check[LinearSolve[core, rhsMatrix, Modulus -> prime],
        $Failed]],
    True, $Failed];
  If[solutionMatrix === $Failed ||
      ! MatrixQ[solutionMatrix, IntegerQ] ||
      Dimensions[solutionMatrix] =!= {unknownCount, nullity + 1},
    Return[<|"Status" -> "ConstrainedCoreSolveFailed",
      "Backend" -> backendUsed|>]];
  solutionMatrix = Mod[solutionMatrix, prime];
  particular = solutionMatrix[[All, 1]];
  nullspace = If[nullity === 0, {},
    Transpose[solutionMatrix[[All, 2 ;;]]]];
  normalizationOK =
    particular[[normalizationColumns]] === ConstantArray[0, nullity] &&
    (nullity === 0 ||
      nullspace[[All, normalizationColumns]] === IdentityMatrix[nullity]);
  residual = AllTrue[Mod[matrix . particular - right, prime],
    #1 === 0 &];
  nullResidual = AllTrue[If[nullspace === {}, {},
      Flatten[Mod[matrix . Transpose[nullspace], prime]]],
    #1 === 0 &];
  <|"Status" -> If[TrueQ[normalizationOK && residual && nullResidual],
      "CanonicalAffineSolution", "ConstrainedResidualNonzero"],
    "Prime" -> prime, "MatrixDimensions" -> Dimensions[matrix],
    "Rank" -> rank, "Nullity" -> nullity,
    "ParticularSolution" -> particular,
    "NullspaceBasis" -> nullspace,
    "ResidualZero" -> residual,
    "NullspaceResidualZero" -> nullResidual,
    "NormalizationCheck" -> normalizationOK,
    "NormalizationColumns" -> normalizationColumns,
    "EliminationPlanFingerprint" -> plan["PlanFingerprint"],
    "Backend" -> backendUsed,
    "BackendFallbackAllowed" -> backendFallback,
    "SolvePath" -> "OneConstrainedMultiRHSFactorization"|>
];

Options[TRInterpolateRationalAffinePrime] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260825,
  "ConstructionCount" -> 24,
  "MaximumTotalDegree" -> 22,
  "DenseByteCap" -> 2147483648,
  "Backend" -> Automatic,
  "BackendThreads" -> 2,
  "BackendFallback" -> True,
  "EliminationPlanMode" -> "Discover",
  "EliminationPlan" -> None,
  "ExpectedDegreeProfile" -> Automatic,
  "Verbose" -> True
};

TRInterpolateRationalAffinePrime[preparation_Association,
    epsilonValues_List, prime_Integer, OptionsPattern[]] := Module[
  {pointCount, maximumAttempts, randomSeed, constructionCount,
   maximumTotalDegree, denseByteCap, denseByteEstimate = 0,
   backend, backendThreads, backendFallback, planMode, providedPlan,
   expectedDegreeProfile, verbose, log,
   validatedFingerprint,
   rawSamples = {}, failures = {}, sample, solve, interpolationSamples,
   selectedSamples, normalizationColumns = {}, discarded = {},
   interpolation, seed, eliminationPlan = None, planResult,
   numeratorDegrees, epsilonIndex, degreeProfile,
   degreeMismatchCoordinates},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  If[! PrimeQ[prime] || !(2 < prime < 2^31) || Mod[prime, 4] =!= 3,
    Return[<|"Status" -> "PrimeMustBe3Mod4", "Prime" -> prime|>]];
  If[epsilonValues === {} ||
      Length[DeleteDuplicates[epsilonValues]] =!= Length[epsilonValues],
    Return[<|"Status" -> "InvalidEpsilonSamples"|>]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = OptionValue["MaximumAttempts"];
  randomSeed = OptionValue["RandomSeed"];
  constructionCount = OptionValue["ConstructionCount"];
  maximumTotalDegree = OptionValue["MaximumTotalDegree"];
  denseByteCap = OptionValue["DenseByteCap"];
  backend = OptionValue["Backend"];
  backendThreads = OptionValue["BackendThreads"];
  backendFallback = OptionValue["BackendFallback"];
  planMode = OptionValue["EliminationPlanMode"];
  providedPlan = OptionValue["EliminationPlan"];
  expectedDegreeProfile = OptionValue["ExpectedDegreeProfile"];
  If[! IntegerQ[randomSeed] || ! IntegerQ[constructionCount] ||
      constructionCount < 1 || ! IntegerQ[maximumTotalDegree] ||
      maximumTotalDegree < 0 || ! IntegerQ[backendThreads] ||
      backendThreads < 1 || ! BooleanQ[backendFallback] ||
      ! IntegerQ[denseByteCap] ||
      denseByteCap < 1,
    Return[<|"Status" -> "InvalidInterpolationOptions"|>]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["TRRATIONALPRIME ", items]];
  validatedFingerprint = preparation["ABIFingerprint"];
  numeratorDegrees = Max /@ Transpose[preparation["GaugeSupport"]];
  Which[
    planMode === "Discover" && providedPlan === None &&
        expectedDegreeProfile === Automatic, Null,
    planMode === "Require" && AssociationQ[providedPlan] &&
        trCrossPrimeEliminationPlanValidQ[preparation, providedPlan] &&
        trDegreeProfileQ[expectedDegreeProfile,
          preparation["UnknownCount"]],
      eliminationPlan = providedPlan;
      normalizationColumns = eliminationPlan["NormalizationColumns"],
    planMode === "Require",
      Return[<|"Status" -> "RequiredCrossPrimeEliminationPlanInvalid",
        "Prime" -> prime|>],
    True,
      Return[<|"Status" -> "InvalidEliminationPlanMode",
        "Prime" -> prime|>]];
  Block[{$trValidatedABIFingerprint = validatedFingerprint}, Do[
    seed = Hash[{randomSeed, validatedFingerprint, prime,
      epsilonValues[[epsilonIndex]]}, "CRC32"];
    sample = trAssembleReconstructionSampleInternal[preparation,
      epsilonValues[[epsilonIndex]], prime,
      "PointCount" -> pointCount,
      "MaximumAttempts" -> maximumAttempts,
      "RandomSeed" -> seed,
      "ValidatedABIFingerprint" -> validatedFingerprint];
    If[Lookup[sample, "Status", None] =!=
        "AssembledReconstructionSample",
      AppendTo[failures, <|"EpsilonValue" -> epsilonValues[[epsilonIndex]],
        "Stage" -> "Assembly", "Result" -> sample|>]; Continue[]];
    If[! AssociationQ[eliminationPlan],
      (* Conservative boxed-integer/pointer allowance for the augmented
         dense matrix.  This gate is deliberately before the one full
         canonical RowReduce used to discover the constrained plan. *)
      denseByteEstimate = 32 Times[
        Length[sample["Matrix"]],
        Dimensions[sample["Matrix"]][[2]] + 1];
      If[denseByteEstimate > denseByteCap,
        Return[<|"Status" -> "CanonicalDenseByteBudgetExceeded",
          "Prime" -> prime,
          "MatrixDimensions" -> Dimensions[sample["Matrix"]],
          "DenseByteEstimate" -> denseByteEstimate,
          "DenseByteCap" -> denseByteCap|>]]];
    solve = If[AssociationQ[eliminationPlan],
      trSolveReconstructionWithPlan[preparation, sample["Matrix"],
        sample["RightHandSide"], eliminationPlan, prime,
        backend, backendThreads, backendFallback],
      TRCanonicalAffineSolve[sample["Matrix"],
        sample["RightHandSide"], prime]];
    If[Lookup[solve, "Status", None] =!= "CanonicalAffineSolution",
      AppendTo[failures, <|"EpsilonValue" -> epsilonValues[[epsilonIndex]],
        "Stage" -> "Solve", "Result" -> solve|>]; Continue[]];
    If[! AssociationQ[eliminationPlan],
      planResult = FeynFacet`Private`finiteFieldStripDiscoverPlan[
        sample["Matrix"], solve["Rank"], solve["NullspaceBasis"],
        preparation["GaugeUnknownCount"],
        preparation["ResidueUnknownCount"],
        numeratorDegrees,
        preparation["GaugeDenominatorDegrees"], prime];
      If[! AssociationQ[planResult] ||
          Lookup[planResult, "Status", None] =!= "OK",
        Return[<|"Status" -> "EliminationPlanDiscoveryFailed",
          "Prime" -> prime, "Plan" -> planResult|>]];
      eliminationPlan = trFinalizeCrossPrimeEliminationPlan[
        preparation, planResult, sample, solve, seed];
      If[! trCrossPrimeEliminationPlanValidQ[
          preparation, eliminationPlan, sample["MatrixDimensions"]],
        Return[<|"Status" -> "CrossPrimeEliminationPlanFinalizationFailed",
          "Prime" -> prime|>]];
      normalizationColumns = eliminationPlan["NormalizationColumns"]];
    AppendTo[rawSamples, Join[solve, <|
      "EpsilonValue" -> epsilonValues[[epsilonIndex]],
      "Prime" -> prime,
      "AugmentedRank" -> solve["Rank"],
      "Consistent" -> True,
      "ParticularCheckZero" -> solve["ResidualZero"],
      "NullspaceCheckZero" -> solve["NullspaceResidualZero"],
      "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
      "FreeResidueCount" -> preparation["ResidueUnknownCount"],
      "GaugeNumeratorDegrees" -> numeratorDegrees,
      "GaugeSupport" -> preparation["GaugeSupport"],
      "AcceptedPoints" -> sample["AcceptedPoints"],
      "AttemptCount" -> sample["AttemptCount"]|>]],
    {epsilonIndex, Length[epsilonValues]}]];
  If[rawSamples === {}, Return[<|"Status" ->
      If[planMode === "Require", "FixedEliminationPlanNoUsableSamples",
        "NoUsableSamples"],
    "Prime" -> prime, "Failures" -> failures|>]];
  selectedSamples = rawSamples;
  If[Length[selectedSamples] < constructionCount + 4,
    Return[<|"Status" -> "InsufficientStablePivotSamples",
      "Prime" -> prime,
      "StablePivotSampleCount" -> Length[selectedSamples],
      "Required" -> constructionCount + 4,
      "DiscardedEpsilonValues" -> Lookup[discarded, "EpsilonValue", {}],
      "Failures" -> failures|>]];
  interpolationSamples = KeyTake[#1, {"EpsilonValue", "Prime",
      "ParticularSolution", "NullspaceBasis", "Rank", "AugmentedRank",
      "Consistent", "ParticularCheckZero", "NullspaceCheckZero",
      "GaugeUnknownCount", "FreeResidueCount", "GaugeNumeratorDegrees",
      "GaugeSupport"}] & /@ selectedSamples;
  log["prime=", prime, " samples=", Length[interpolationSamples],
    " rank=", eliminationPlan["GenericRank"],
    " nullity=", eliminationPlan["Nullity"],
    " unknowns=", preparation["UnknownCount"]];
  interpolation = FeynFacet`InterpolateEpsFormStripAffine[
    interpolationSamples, prime,
    "ConstructionCount" -> constructionCount,
    "MaximumTotalDegree" -> maximumTotalDegree,
    "NormalizationColumns" -> normalizationColumns];
  If[! AssociationQ[interpolation] ||
      Lookup[interpolation, "UnresolvedCoordinates", {1}] =!= {},
    Return[<|"Status" -> "RationalEpsilonInterpolationFailed",
      "Prime" -> prime, "ABIFingerprint" -> validatedFingerprint,
      "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
      "Interpolation" -> interpolation,
      "DiscardedEpsilonValues" -> Lookup[discarded, "EpsilonValue", {}],
      "Failures" -> failures|>]];
  degreeProfile = Lookup[interpolation["Interpolations"],
    "Degrees", $Failed];
  If[! trDegreeProfileQ[degreeProfile, preparation["UnknownCount"]],
    Return[<|"Status" -> "InvalidInterpolatedDegreeProfile",
      "Prime" -> prime|>]];
  If[planMode === "Require" &&
      degreeProfile =!= expectedDegreeProfile,
    degreeMismatchCoordinates = Select[Range[Length[degreeProfile]],
      degreeProfile[[#1]] =!= expectedDegreeProfile[[#1]] &];
    Return[<|"Status" -> "RejectPrimeDegreeProfileChanged",
      "Prime" -> prime,
      "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
      "DegreeMismatchCoordinates" -> degreeMismatchCoordinates,
      "ExpectedDegreeProfile" -> expectedDegreeProfile,
      "ObservedDegreeProfile" -> degreeProfile|>]];
  Join[interpolation, <|
    "Status" -> "RationalAffinePrimeInterpolated",
    "ABIFingerprint" -> validatedFingerprint,
    "RootOrderingFingerprint" ->
      preparation["RootOrderingFingerprint"],
    "EliminationPlanMode" -> planMode,
    "EliminationPlan" -> eliminationPlan,
    "EliminationPlanFingerprint" -> eliminationPlan["PlanFingerprint"],
    "DegreeProfile" -> degreeProfile,
    "DegreeProfileFingerprint" ->
      trStableAssociationFingerprint[degreeProfile],
    "EliminationPlanSummary" -> KeyTake[eliminationPlan,
      {"Status", "PlanVersion", "PlanFingerprint",
        "NormalizationColumns", "IndependentEquationRows",
        "GenericRank", "Nullity", "UnknownCount", "GaugeUnknownCount",
        "FreeResidueCount", "GaugeNumeratorDegrees",
        "GaugeDenominatorDegrees", "PilotPrime"}],
    "InputEpsilonValues" -> epsilonValues,
    "StablePivotSampleCount" -> Length[selectedSamples],
    "CanonicalDenseByteEstimate" -> denseByteEstimate,
    "CanonicalDenseByteCap" -> denseByteCap,
    "DensePilotPerformed" -> (planMode === "Discover"),
    "DiscardedEpsilonValues" -> Lookup[discarded, "EpsilonValue", {}],
    "SampleFailures" -> failures,
    "SampleSummaries" -> (KeyTake[#1, {"EpsilonValue", "Rank",
        "Nullity", "PivotSignature", "AcceptedPoints",
        "AttemptCount", "Backend", "SolvePath"}] & /@
      selectedSamples)|>]
];

trRationalInterpolationShapeQ[interpolation_Association,
    prime_Integer] := Module[{numerator, denominator, degrees},
  numerator = Lookup[interpolation, "Numerator", $Failed];
  denominator = Lookup[interpolation, "Denominator", $Failed];
  degrees = Lookup[interpolation, "Degrees", $Failed];
  ListQ[numerator] && numerator =!= {} &&
    ListQ[denominator] && denominator =!= {} &&
    VectorQ[numerator, IntegerQ[#1] && 0 <= #1 < prime &] &&
    VectorQ[denominator, IntegerQ[#1] && 0 <= #1 < prime &] &&
    Last[denominator] === 1 &&
    If[numerator === {0}, degrees === {-Infinity, 0} &&
        denominator === {1},
      Last[numerator] =!= 0 &&
        MatchQ[degrees, {_Integer, _Integer}] &&
        Min[degrees] >= 0 &&
        Length[numerator] === degrees[[1]] + 1 &&
        Length[denominator] === degrees[[2]] + 1]
];

trLiftRationalCoordinate[artifacts_List, coordinate_Integer,
    primes_List, epsilon_Symbol] := Module[
  {coordinates, degrees, numerator, denominator, value,
   trainingImagesExact},
  coordinates = Table[
    artifacts[[primeIndex, "Interpolations", coordinate]],
    {primeIndex, Length[artifacts]}];
  If[! And @@ MapThread[trRationalInterpolationShapeQ,
      {coordinates, primes}], Return[$Failed]];
  degrees = Lookup[coordinates, "Degrees", $Failed];
  If[Length[DeleteDuplicates[degrees]] =!= 1, Return[$Failed]];
  numerator = Table[trCRTRecover[Table[
      coordinates[[primeIndex, "Numerator", coefficient]],
      {primeIndex, Length[primes]}], primes],
    {coefficient, Length[First[coordinates]["Numerator"]]}];
  denominator = Table[trCRTRecover[Table[
      coordinates[[primeIndex, "Denominator", coefficient]],
      {primeIndex, Length[primes]}], primes],
    {coefficient, Length[First[coordinates]["Denominator"]]}];
  If[! FreeQ[{numerator, denominator}, $Failed], Return[$Failed]];
  trainingImagesExact = And @@ Flatten[Table[
      trModNumber[numerator[[coefficient]], primes[[primeIndex]]] ===
        coordinates[[primeIndex, "Numerator", coefficient]],
      {primeIndex, Length[primes]}, {coefficient, Length[numerator]}]] &&
    And @@ Flatten[Table[
      trModNumber[denominator[[coefficient]], primes[[primeIndex]]] ===
        coordinates[[primeIndex, "Denominator", coefficient]],
      {primeIndex, Length[primes]}, {coefficient, Length[denominator]}]];
  If[! TrueQ[trainingImagesExact], Return[$Failed]];
  value = Together[FromDigits[Reverse[numerator], epsilon]/
    FromDigits[Reverse[denominator], epsilon]];
  <|"Value" -> value, "Degrees" -> First[degrees],
    "NumeratorCoefficients" -> numerator,
    "DenominatorCoefficients" -> denominator,
    "TrainingPrimeImagesExact" -> True|>
];

TRLiftRationalAffineBatch[preparation_Association,
    artifacts_List] := Module[
  {primes, fingerprints, orderings, plans, planFingerprints,
   normalizationColumns, coordinateCounts, degreeProfiles,
   degreeProfileFingerprints, commonPlan, epsilon, liftedCoordinates,
   vector, unpacked, exact},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  If[Length[artifacts] < 3 || ! AllTrue[artifacts,
      AssociationQ[#1] && Lookup[#1, "Status", None] ===
        "RationalAffinePrimeInterpolated" &],
    Return[<|"Status" -> "InsufficientPrimeArtifacts"|>]];
  primes = Lookup[artifacts, "Prime", $Failed];
  If[! VectorQ[primes, IntegerQ] || ! DuplicateFreeQ[primes] ||
      ! AllTrue[primes,
        PrimeQ[#1] && 2 < #1 < 2^31 && Mod[#1, 4] === 3 &],
    Return[<|"Status" -> "InvalidPrimeArtifacts"|>]];
  fingerprints = Lookup[artifacts, "ABIFingerprint", $Failed];
  orderings = Lookup[artifacts, "RootOrderingFingerprint", $Failed];
  plans = Lookup[artifacts, "EliminationPlan", $Failed];
  planFingerprints = Lookup[artifacts,
    "EliminationPlanFingerprint", $Failed];
  normalizationColumns = Lookup[artifacts, "NormalizationColumns", $Failed];
  coordinateCounts = Length[Lookup[#1, "Interpolations", {}]] & /@
    artifacts;
  degreeProfiles = Lookup[artifacts, "DegreeProfile", $Failed];
  degreeProfileFingerprints = Lookup[artifacts,
    "DegreeProfileFingerprint", $Failed];
  If[! AllTrue[fingerprints, #1 === preparation["ABIFingerprint"] &] ||
      ! AllTrue[orderings,
        #1 === preparation["RootOrderingFingerprint"] &] ||
      ! AllTrue[plans, AssociationQ] ||
      ! AllTrue[plans,
        trCrossPrimeEliminationPlanValidQ[preparation, #1] &] ||
      Length[DeleteDuplicates[plans, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[planFingerprints]] =!= 1 ||
      ! TrueQ[And @@ MapThread[SameQ, {planFingerprints,
          Lookup[plans, "PlanFingerprint", $Failed]}]] ||
      Length[DeleteDuplicates[normalizationColumns]] =!= 1 ||
      Length[DeleteDuplicates[coordinateCounts]] =!= 1 ||
      First[coordinateCounts] =!= preparation["UnknownCount"] ||
      ! AllTrue[degreeProfiles,
        trDegreeProfileQ[#1, preparation["UnknownCount"]] &] ||
      Length[DeleteDuplicates[degreeProfiles]] =!= 1 ||
      ! TrueQ[And @@ MapThread[SameQ, {degreeProfiles,
          Lookup[Lookup[#1, "Interpolations", {}], "Degrees", $Failed] & /@
            artifacts}]] ||
      ! TrueQ[And @@ MapThread[SameQ, {degreeProfileFingerprints,
          trStableAssociationFingerprint /@ degreeProfiles}]],
    Return[<|"Status" -> "PrimeArtifactABIMismatch",
      "Primes" -> primes|>]];
  commonPlan = First[plans];
  If[First[normalizationColumns] =!= commonPlan["NormalizationColumns"],
    Return[<|"Status" -> "PrimeArtifactNormalizationMismatch",
      "Primes" -> primes|>]];
  epsilon = preparation["Regulator"];
  liftedCoordinates = Table[trLiftRationalCoordinate[
      artifacts, coordinate, primes, epsilon],
    {coordinate, preparation["UnknownCount"]}];
  If[MemberQ[liftedCoordinates, $Failed],
    Return[<|"Status" -> "RationalCoefficientReconstructionFailed",
      "Primes" -> primes,
      "FailedCoordinates" -> Flatten[Position[
        liftedCoordinates, $Failed]]|>]];
  vector = Lookup[liftedCoordinates, "Value"];
  unpacked = TRUnpackReconstructedVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedReconstruction",
    Return[unpacked]];
  exact = TRExactChannelResidual[preparation, vector];
  <|"Status" -> If[TrueQ[Lookup[exact, "ResidualZero", False]],
      "ExactRationalReconstruction", "ExactResidualNonzero"],
    "Preparation" -> preparation,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "Primes" -> primes,
    "EliminationPlan" -> commonPlan,
    "EliminationPlanFingerprint" -> commonPlan["PlanFingerprint"],
    "DegreeProfile" -> First[degreeProfiles],
    "DegreeProfileFingerprint" -> First[degreeProfileFingerprints],
    "NormalizationColumns" -> First[normalizationColumns],
    "PilotPivotColumns" -> commonPlan["PilotPivotColumns"],
    "PilotFreeColumns" -> commonPlan["PilotFreeColumns"],
    "Rank" -> commonPlan["GenericRank"],
    "Nullity" -> commonPlan["Nullity"],
    "ReconstructedVector" -> vector,
    "ReconstructedCoordinates" -> liftedCoordinates,
    "GaugeChannels" -> unpacked["GaugeChannels"],
    "Residues" -> unpacked["Residues"],
    "ExactVerification" -> exact|>
];

TRUnpackReconstructedVector[preparation_Association,
    vector_List] := Module[
  {dimensions, gradeCount, support, denominator, variables,
   gaugeUnknownCount, residueUnknownCount, unknownCount,
   gaugeCoefficients, gaugeChannels, residues},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction",
    Return[<|"Status" -> "InvalidPreparation"|>]];
  If[! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "InvalidPreparationABI"|>]];
  unknownCount = preparation["UnknownCount"];
  If[Length[vector] =!= unknownCount,
    Return[<|"Status" -> "ReconstructedVectorLengthMismatch",
      "Expected" -> unknownCount, "Observed" -> Length[vector]|>]];
  dimensions = preparation["Dimensions"];
  gradeCount = preparation["GradeCount"];
  support = preparation["GaugeSupport"];
  denominator = preparation["GaugeDenominator"];
  variables = preparation["Variables"];
  gaugeUnknownCount = preparation["GaugeUnknownCount"];
  residueUnknownCount = preparation["ResidueUnknownCount"];
  gaugeCoefficients = Table[
    vector[[trGaugeIndex[dimensions[[1]], dimensions[[2]],
      gradeCount, Length[support], i, j, grade, monomial]]],
    {i, dimensions[[1]]}, {j, dimensions[[2]]},
    {grade, 0, gradeCount - 1}, {monomial, Length[support]}];
  gaugeChannels = Table[Together[
      Sum[gaugeCoefficients[[i, j, grade, monomial]] *
          variables[[1]]^support[[monomial, 1]] *
          variables[[2]]^support[[monomial, 2]],
        {monomial, Length[support]}]/denominator],
    {i, dimensions[[1]]}, {j, dimensions[[2]]},
    {grade, gradeCount}];
  residues = If[residueUnknownCount === 0, {},
    Table[vector[[trResidueIndex[gaugeUnknownCount,
      dimensions[[1]], dimensions[[2]], letter, i, j]]],
      {letter, Length[preparation["OneForms"]]},
      {i, dimensions[[1]]}, {j, dimensions[[2]]}]];
  <|"Status" -> "UnpackedReconstruction",
    "GaugeCoefficients" -> gaugeCoefficients,
    "GaugeChannels" -> gaugeChannels,
    "Residues" -> residues|>
];

trDecomposeMatrix[matrix_List, roots_List] :=
  Map[CodexTripleRootStrip`TRFieldDecompose[#1, roots] &, matrix, {2}];

trChannelMatrixProduct[left_List, right_List, deltas_List] := Module[
  {leftDimensions = Dimensions[left], rightDimensions = Dimensions[right],
   inner},
  If[Length[leftDimensions] =!= 3 || Length[rightDimensions] =!= 3 ||
      leftDimensions[[2]] =!= rightDimensions[[1]] ||
      leftDimensions[[3]] =!= rightDimensions[[3]], Return[$Failed]];
  inner = leftDimensions[[2]];
  Table[Together /@ Total[Table[
      CodexTripleRoot`TRMultiply[left[[i, k]], right[[k, j]], deltas],
      {k, inner}]],
    {i, leftDimensions[[1]]}, {j, rightDimensions[[2]]}]
];

TRExactChannelResidual[preparation_Association, vector_List] := Module[
  {unpacked, gauge, residues, record, roots, deltas, variables,
   epsilon, strip, eChannels, cChannels, bbarChannels,
   oneFormChannels, derivative, leftProduct, rightProduct,
   residueTerm, residual},
  unpacked = TRUnpackReconstructedVector[preparation, vector];
  If[Lookup[unpacked, "Status", None] =!= "UnpackedReconstruction",
    Return[unpacked]];
  gauge = unpacked["GaugeChannels"];
  residues = unpacked["Residues"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  deltas = Lookup[roots, "RootSquare", {}];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  strip = record["Strip"];
  eChannels = trDecomposeMatrix[#1, roots] & /@ strip[[1]];
  cChannels = trDecomposeMatrix[#1, roots] & /@ strip[[2]];
  bbarChannels = trDecomposeMatrix[#1, roots] & /@ strip[[3]];
  oneFormChannels = Table[
    CodexTripleRootStrip`TRFieldDecompose[
      preparation["OneForms"][[letter, mu]], roots],
    {letter, Length[preparation["OneForms"]]}, {mu, 2}];
  If[! FreeQ[{eChannels, cChannels, bbarChannels, oneFormChannels},
      $Failed],
    Return[<|"Status" -> "ExactChannelDecompositionFailed"|>]];
  residual = Table[
    derivative = Map[
      CodexTripleRoot`TRDerivative[#1, deltas, variables[[mu]]] &,
      gauge, {2}];
    leftProduct = trChannelMatrixProduct[eChannels[[mu]], gauge,
      deltas];
    rightProduct = trChannelMatrixProduct[gauge, cChannels[[mu]],
      deltas];
    If[leftProduct === $Failed || rightProduct === $Failed,
      Return[<|"Status" -> "ExactChannelDimensionMismatch"|>]];
    residueTerm = If[Length[preparation["OneForms"]] === 0,
      ConstantArray[0,
        Append[preparation["Dimensions"], preparation["GradeCount"]]],
      Table[Together /@ Total[Table[
          residues[[letter, i, j]] oneFormChannels[[letter, mu]],
          {letter, Length[preparation["OneForms"]]}]],
        {i, preparation["Dimensions"][[1]]},
        {j, preparation["Dimensions"][[2]]}]];
    Map[Together,
      derivative - epsilon leftProduct + epsilon rightProduct +
        epsilon residueTerm - bbarChannels[[mu]], {3}],
    {mu, 2}];
  <|"Status" -> If[trZeroQ[residual],
      "ExactChannelResidualZero", "ExactChannelResidualNonzero"],
    "ResidualZero" -> trZeroQ[residual],
    "ResidualChannels" -> residual|>
];

TRVerifyReconstructionExact[result_Association] := Module[
  {preparation, vector, resultFingerprint},
  preparation = Lookup[result, "Preparation", $Failed];
  vector = Lookup[result, "ReconstructedVector", $Failed];
  If[! AssociationQ[preparation] || ! ListQ[vector],
    Return[<|"Status" -> "InvalidReconstructionResult"|>]];
  resultFingerprint = Lookup[result, "ABIFingerprint", Missing["ResultABI"]];
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! TRPreparationABIValidQ[preparation] ||
      resultFingerprint =!= Lookup[preparation, "ABIFingerprint",
        Missing["PreparationABI"]],
    Return[<|"Status" -> "ReconstructionABIMismatch",
      "ResultABIFingerprint" -> resultFingerprint,
      "PreparationABIFingerprint" -> Lookup[preparation,
        "ABIFingerprint", Missing["PreparationABI"]]|>]];
  TRExactChannelResidual[preparation, vector]
];

Options[TRVerifyReconstructionModPrime] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260824,
  "BranchFlipMask" -> 0
};

Options[trVerifyReconstructionModPrimeInternal] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260824,
  "BranchFlipMask" -> 0,
  "ValidatedABIFingerprint" -> Automatic
};

TRVerifyReconstructionModPrime[result_Association, prime_Integer,
    epsilonValues_List, OptionsPattern[]] := Module[
  {preparation, fingerprint},
  preparation = Lookup[result, "Preparation", $Failed];
  fingerprint = Lookup[result, "ABIFingerprint", Missing["ResultABI"]];
  If[! AssociationQ[preparation] ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      fingerprint =!= Lookup[preparation, "ABIFingerprint",
        Missing["PreparationABI"]] ||
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "ReconstructionABIMismatch"|>]];
  Block[{$trValidatedABIFingerprint = fingerprint},
    trVerifyReconstructionModPrimeInternal[result, prime, epsilonValues,
      "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> OptionValue["RandomSeed"],
      "BranchFlipMask" -> OptionValue["BranchFlipMask"],
      "ValidatedABIFingerprint" -> fingerprint]]
];

trVerifyReconstructionModPrimeInternal[result_Association, prime_Integer,
    epsilonValues_List, OptionsPattern[]] := Module[
  {preparation, vector, trainingPrimes, epsilon, checks, sample,
   evaluatedVector, residual, seed, resultFingerprint,
   validatedFingerprint},
  preparation = Lookup[result, "Preparation", $Failed];
  vector = Lookup[result, "ReconstructedVector", $Failed];
  trainingPrimes = Lookup[result, "Primes", {}];
  If[! AssociationQ[preparation] || ! ListQ[vector],
    Return[<|"Status" -> "InvalidReconstructionResult"|>]];
  resultFingerprint = Lookup[result, "ABIFingerprint", Missing["ResultABI"]];
  validatedFingerprint = OptionValue["ValidatedABIFingerprint"];
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      (! trPreparationFastPathQ[preparation, validatedFingerprint] &&
        ! TRPreparationABIValidQ[preparation]) ||
      resultFingerprint =!= Lookup[preparation, "ABIFingerprint",
        Missing["PreparationABI"]],
    Return[<|"Status" -> "ReconstructionABIMismatch",
      "ResultABIFingerprint" -> resultFingerprint,
      "PreparationABIFingerprint" -> Lookup[preparation,
        "ABIFingerprint", Missing["PreparationABI"]]|>]];
  If[MemberQ[trainingPrimes, prime],
    Return[<|"Status" -> "PrimeWasUsedForReconstruction",
      "Prime" -> prime|>]];
  If[! PrimeQ[prime] || Mod[prime, 4] =!= 3,
    Return[<|"Status" -> "PrimeMustBe3Mod4", "Prime" -> prime|>]];
  epsilon = preparation["Regulator"];
  checks = Table[
    seed = Hash[{OptionValue["RandomSeed"],
      preparation["ABIFingerprint"], prime, epsilonValue}, "CRC32"];
    sample = trAssembleReconstructionSampleInternal[
      preparation, epsilonValue,
      prime, "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> seed,
      "BranchFlipMask" -> OptionValue["BranchFlipMask"],
      "ValidatedABIFingerprint" -> Lookup[preparation,
        "ABIFingerprint", Automatic]];
    If[Lookup[sample, "Status", None] =!=
        "AssembledReconstructionSample", sample,
      evaluatedVector = trModNumber[
          #1 /. epsilon -> epsilonValue, prime] & /@ vector;
      If[MemberQ[evaluatedVector, $Failed],
        <|"Status" -> "ReconstructedVectorSingular",
          "Prime" -> prime, "EpsilonValue" -> epsilonValue|>,
        residual = Mod[sample["Matrix"] . evaluatedVector -
          sample["RightHandSide"], prime];
        <|"Status" -> If[AllTrue[residual, #1 === 0 &],
            "ModularResidualZero", "ModularResidualNonzero"],
          "Prime" -> prime,
          "EpsilonValue" -> epsilonValue,
          "ResidualZero" -> AllTrue[residual, #1 === 0 &],
          "NonzeroResidualCount" -> Count[residual, _?(#1 =!= 0 &)],
          "AcceptedPoints" -> sample["AcceptedPoints"],
          "BranchFlipMask" -> sample["BranchFlipMask"]|>]
    ],
    {epsilonValue, epsilonValues}];
  <|"Status" -> If[AllTrue[checks,
      TrueQ[Lookup[#1, "ResidualZero", False]] &],
      "UnseenPrimeVerified", "UnseenPrimeVerificationFailed"],
    "Prime" -> prime,
    "ABIFingerprint" -> preparation["ABIFingerprint"],
    "ResidualZero" -> AllTrue[checks,
      TrueQ[Lookup[#1, "ResidualZero", False]] &],
    "Checks" -> checks|>
];

Options[TRVerifyReconstructionAllBranchMasksModPrime] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 20260826
};

TRVerifyReconstructionAllBranchMasksModPrime[result_Association,
    prime_Integer, epsilonValues_List, OptionsPattern[]] := Module[
  {preparation, vector, fingerprint, gradeCount, checks},
  preparation = Lookup[result, "Preparation", $Failed];
  vector = Lookup[result, "ReconstructedVector", $Failed];
  fingerprint = Lookup[result, "ABIFingerprint", Missing["ResultABI"]];
  If[! AssociationQ[preparation] || ! ListQ[vector] ||
      Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      fingerprint =!= Lookup[preparation, "ABIFingerprint",
        Missing["PreparationABI"]] ||
      ! TRPreparationABIValidQ[preparation],
    Return[<|"Status" -> "ReconstructionABIMismatch"|>]];
  gradeCount = preparation["GradeCount"];
  checks = Block[{$trValidatedABIFingerprint = fingerprint}, Table[
    trVerifyReconstructionModPrimeInternal[
      result, prime, epsilonValues,
      "PointCount" -> OptionValue["PointCount"],
      "MaximumAttempts" -> OptionValue["MaximumAttempts"],
      "RandomSeed" -> OptionValue["RandomSeed"] + signMask,
      "BranchFlipMask" -> signMask,
      "ValidatedABIFingerprint" -> fingerprint],
    {signMask, 0, gradeCount - 1}]];
  <|"Status" -> If[AllTrue[checks,
      Lookup[#1, "Status", None] === "UnseenPrimeVerified" &&
        TrueQ[Lookup[#1, "ResidualZero", False]] &],
      "AllBranchMasksVerified", "BranchMaskVerificationFailed"],
    "Prime" -> prime, "ABIFingerprint" -> fingerprint,
    "AllSplitBranchRowsPerPoint" -> True,
    "BranchFlipMasks" -> Range[0, gradeCount - 1],
    "ResidualZero" -> AllTrue[checks,
      TrueQ[Lookup[#1, "ResidualZero", False]] &],
    "Checks" -> checks|>
];

TRPreparationABICompatibleQ[left_Association, right_Association] :=
  TRPreparationABIValidQ[left] && TRPreparationABIValidQ[right] &&
  Lookup[left, "ABIFingerprint", Missing["Left"]] ===
    Lookup[right, "ABIFingerprint", Missing["Right"]] &&
  ! MissingQ[Lookup[left, "ABIFingerprint", Missing["Left"]]];

End[];
EndPackage[];
