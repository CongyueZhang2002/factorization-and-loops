(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripScreens.wl -- part 3 of 8 of the
   multiquadratic strip solver (split from MultiquadraticStripSolve.wl in
   round 4, 2026-09-02, pure moves): the residue-only integrability screen, screen admission and compiled-form
   reuse, the two-image rejection path and evidence classifier, the full-gauge
   per-image screen and the degree-offset ladder.
   Loads after the preceding parts (Private/LoadOrder.wl); the ABI, the
   globals and the shared utilities are in MultiquadraticStripSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripScreenCompilePolynomialExact,
  multiquadraticStripScreenCompileExpandedPolynomialExact,
  multiquadraticStripScreenReducePolynomial,
  multiquadraticStripScreenCompilePolynomial,
  multiquadraticStripScreenCompileScalarExact,
  multiquadraticStripScreenCompileFactoredScalarExact,
  multiquadraticStripScreenReduceScalar,
  multiquadraticStripScreenCompileScalar,
  multiquadraticStripScreenEvaluatePolynomial,
  multiquadraticStripScreenEvaluateRational,
  multiquadraticStripScreenEvaluatePolynomialValue,
  multiquadraticStripScreenEvaluateRationalValue,
  multiquadraticStripScreenPowerTables,
  multiquadraticStripScreenSizeEstimate,
  multiquadraticStripScreenAdmissionRefusal,
  multiquadraticStripSampleSizeEstimate,
  multiquadraticStripSampleAdmissionRefusal,
  multiquadraticStripScreenCompileCached,
  multiquadraticStripScreenCompileCacheClear,
  $multiquadraticStripScreenCompileCache,
  $multiquadraticStripScreenCompileCacheBytes,
  $multiquadraticStripScreenCompileCacheLimit,
  $multiquadraticStripScreenCompileStatistics,
  $multiquadraticStripScreenMaximumUnknowns,
  $multiquadraticStripScreenMaximumBytes,
  $multiquadraticStripSampleMaximumBytes,
  multiquadraticStripIntegrabilityScreen,
  multiquadraticStripIntegrabilityScreenImages,
  multiquadraticStripScreenEvidenceClassify,
  multiquadraticStripConfirmedObstructionEvidenceQ,
  multiquadraticStripFreshResidueScreenImages,
  multiquadraticStripGaugeAnsatz,
  multiquadraticStripGaugeScreen,
  multiquadraticStripGaugeScreenImages,
  multiquadraticStripFreshScreenImages,
  $multiquadraticStripDefaultFreshImageCount,
  multiquadraticStripGaugeScreenLadder,
  multiquadraticStripDegreeOffsetLadder,
  multiquadraticStripDegreeOffsetLadderParse,
  $multiquadraticStripDefaultDegreeOffsetLadder
];

(* ------------------------------------------------------------------ *)
(* The residue-only integrability screen                                *)
(* ------------------------------------------------------------------ *)

(* Cross-differentiating the strip equation
     d_mu G = eps (e_mu G - G c_mu) + bbar_mu - eps Sum_a R_a w_{a,mu}
   and using dw_a = 0 gives, exactly,
     eps F_e G - eps G F_c + Cbbar
       = eps^2 Sum_a [ (w_{a,y} e_x - w_{a,x} e_y) R_a
                     + R_a (w_{a,x} c_y - w_{a,y} c_x) ] ,
     Cbbar = (d_y bbar_x - d_x bbar_y)
             + eps (e_x bbar_y - e_y bbar_x + bbar_x c_y - bbar_y c_x),
     F_e   = d_y e_x - d_x e_y + eps [e_x, e_y]   (F_c likewise).
   When the diagonal connections are flat -- F_e = F_c = 0, MEASURED at
   every sampled point, never assumed -- the gauge G drops out entirely
   and what is left is a LINEAR system in the constant residues alone.
   Its consistency is a necessary condition on the alphabet and it costs
   only point evaluations of e, c, bbar and their first derivatives: no
   channel decomposition, no compilation, no gauge ansatz.  If the
   measurement says a diagonal connection is not flat the screen does not
   apply and the caller falls back to the full condition, i.e. to the
   gauge system, which carries the G-dependent terms.

   Derivatives are taken by the chain rule on the COMPILED form, never
   symbolically: each scalar becomes exponent/coefficient tables over
   (x, y, r_1..r_r) modulo one prime, and
     d/dx = partial_x + Sum_a partial_{r_a} (delta_a)_x / (2 r_a).      *)

multiquadraticStripScreenCompilePolynomialExact[polynomial_,
    allVariables_List] := Module[{expanded, rules, exponents},
  expanded = Quiet[Expand[polynomial]];
  If[! PolynomialQ[expanded, allVariables], Return[$Failed]];
  rules = CoefficientRules[expanded, allVariables];
  If[rules === {},
    Return[<|"Exponents" -> {}, "ExactCoefficients" -> {},
      "MaximumExponents" -> ConstantArray[0, Length[allVariables]]|>]];
  exponents = First /@ rules;
  <|"Exponents" -> Developer`ToPackedArray[exponents],
    "ExactCoefficients" -> Last /@ rules,
    "MaximumExponents" -> Max /@ Transpose[exponents]|>
];
multiquadraticStripScreenCompilePolynomialExact[___] := $Failed;

(* Fast path for an expression which is already an expanded sum of
   monomials.  CoefficientRules calls Expand again and performs a general
   polynomial conversion; on large deferred operands that dominated sparse
   plan construction even though every existing Plus term was already a
   monomial.  Parse that representation directly and merge only genuinely
   duplicate exponent vectors. *)
multiquadraticStripScreenCompileExpandedPolynomialExact[polynomial_,
    allVariables_List] := Module[
  {terms, coefficients, rules, exponents},
  If[! TrueQ[PolynomialQ[polynomial, allVariables]], Return[$Failed]];
  terms = If[Head[polynomial] === Plus, List @@ polynomial, {polynomial}];
  (* Expand each existing additive term independently.  This distributes
     small local factors such as x^n (4 x + y^2), but unlike Expand on the
     whole deferred numerator it cannot form a cross product between the
     numerator's separately compiled top-level factors. *)
  terms = Expand[terms];
  terms = Flatten[If[Head[#1] === Plus, List @@ #1, {#1}] & /@ terms];
  (* Exponent threads over a list of monomials inside the kernel.  Together
     with the all-rational coefficient test and the absence of nested Plus,
     this rejects non-monomial or non-polynomial terms without a scalar
     Wolfram-level parser loop. *)
  If[! FreeQ[terms, _Plus], Return[$Failed]];
  exponents = Transpose[Exponent[terms, #1] & /@ allVariables];
  coefficients = terms /. Thread[allVariables -> 1];
  If[! MatrixQ[exponents,
        IntegerQ[#1] && NonNegative[#1] &] ||
      ! VectorQ[coefficients,
        IntegerQ[#1] || Head[#1] === Rational &], Return[$Failed]];
  rules = Select[Normal[Merge[
      MapThread[Rule, {exponents, coefficients}], Total]],
    Last[#1] =!= 0 &];
  If[rules === {},
    Return[<|"Exponents" -> {}, "ExactCoefficients" -> {},
      "MaximumExponents" -> ConstantArray[0, Length[allVariables]]|>]];
  exponents = First /@ rules;
  <|"Exponents" -> Developer`ToPackedArray[exponents],
    "ExactCoefficients" -> Last /@ rules,
    "MaximumExponents" -> Max /@ Transpose[exponents]|>
];
multiquadraticStripScreenCompileExpandedPolynomialExact[___] := $Failed;

multiquadraticStripScreenReducePolynomial[exact_Association,
    prime_Integer] := Module[{coefficients},
  coefficients = multiquadraticStripModRational[#1, prime] & /@
    Lookup[exact, "ExactCoefficients", {$Failed}];
  If[MemberQ[coefficients, $Failed], Return[$Failed]];
  <|"Exponents" -> exact["Exponents"],
    "Coefficients" -> Developer`ToPackedArray[coefficients],
    "MaximumExponents" -> exact["MaximumExponents"]|>
];
multiquadraticStripScreenReducePolynomial[___] := $Failed;

multiquadraticStripScreenCompilePolynomial[polynomial_, allVariables_List,
    prime_Integer] := multiquadraticStripScreenReducePolynomial[
  multiquadraticStripScreenCompilePolynomialExact[polynomial, allVariables],
  prime];

multiquadraticStripScreenCompileScalarExact[expression_, roots_List,
    rootSymbols_List, variables_List] := Module[
  {replaced, rational, numerator, denominator, allVariables},
  If[expression === $Failed, Return[$Failed]];
  allVariables = Join[variables, rootSymbols];
  replaced = If[roots === {}, expression,
    Quiet[transportChartApplyRootBranches[expression, roots, rootSymbols]]];
  If[replaced === $Failed, Return[$Failed]];
  If[! FreeQ[replaced, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Quiet[Together[replaced]];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
      ! FreeQ[rational, DirectedInfinity | Indeterminate], Return[$Failed]];
  numerator = multiquadraticStripScreenCompilePolynomialExact[
    Numerator[rational], allVariables];
  denominator = multiquadraticStripScreenCompilePolynomialExact[
    Denominator[rational], allVariables];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["ExactCoefficients"] === {}, Return[$Failed]];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "MaximumExponents" -> MapThread[Max,
      {numerator["MaximumExponents"], denominator["MaximumExponents"]}]|>
];
multiquadraticStripScreenCompileScalarExact[___] := $Failed;

(* Deferred operands already carry an exact canonical quotient.  Recombining
   its numerator factors with Together/Expand before finite-field evaluation
   can manufacture a huge cross product which is absent from the source DAG.
   Compile the existing top-level product factor by factor instead; evaluation
   multiplies the factor values modulo p, so this is exactly the same rational
   function without materializing that cross product.  This representation is
   deliberately split-value-only; derivative screens keep the established
   flat rational compiler. *)
multiquadraticStripScreenCompileFactoredScalarExact[numerator_,
    denominatorFactors_List, roots_List, rootSymbols_List,
    variables_List] := Module[
  {allVariables = Join[variables, rootSymbols], splitNumerator,
   normalizeFactor, compileFactor, numeratorData, denominatorData,
   maxima},
  splitNumerator = If[Head[numerator] === Times, List @@ numerator,
    {numerator}];
  normalizeFactor[factor_, inheritedPower_Integer : 1] := Which[
    MatchQ[factor, Power[_, exponent_Integer?Positive]],
      {First[factor], inheritedPower Last[factor]},
    True, {factor, inheritedPower}];
  compileFactor[{factor_, power_Integer?Positive}] := Module[
    {replaced, compiled},
    replaced = If[roots === {}, factor,
      Quiet[transportChartApplyRootBranches[factor, roots, rootSymbols]]];
    If[replaced === $Failed ||
        ! FreeQ[replaced,
          Power[_, exponent_Rational /; ! IntegerQ[exponent]]] ||
        ! FreeQ[replaced, DirectedInfinity | Indeterminate],
      Return[$Failed]];
    compiled = multiquadraticStripScreenCompileExpandedPolynomialExact[
      replaced, allVariables];
    If[compiled === $Failed,
      compiled = multiquadraticStripScreenCompilePolynomialExact[
        replaced, allVariables]];
    If[compiled === $Failed, $Failed,
      <|"Polynomial" -> compiled, "Power" -> power|>]
  ];
  numeratorData = compileFactor /@
    (normalizeFactor /@ splitNumerator);
  denominatorData = compileFactor /@
    If[denominatorFactors === {}, {{1, 1}},
      normalizeFactor[First[#1], Last[#1]] & /@ denominatorFactors];
  If[MemberQ[numeratorData, $Failed] ||
      MemberQ[denominatorData, $Failed] ||
      AnyTrue[denominatorData,
        Lookup[#1["Polynomial"], "ExactCoefficients", {}] === {} &],
    Return[$Failed]];
  maxima = Lookup[Join[numeratorData, denominatorData][[All, "Polynomial"]],
    "MaximumExponents"];
  <|"Representation" -> "SplitValueFactoredRationalV1",
    "NumeratorFactors" -> numeratorData,
    "DenominatorFactors" -> denominatorData,
    "MaximumExponents" -> If[maxima === {},
      ConstantArray[0, Length[allVariables]], Max /@ Transpose[maxima]]|>
];
multiquadraticStripScreenCompileFactoredScalarExact[___] := $Failed;

multiquadraticStripScreenReduceScalar[exact_Association,
    prime_Integer] := Module[
  {numerator, denominator, reduceFactor, numeratorFactors,
   denominatorFactors},
  If[Lookup[exact, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    reduceFactor[factor_Association] := Module[{polynomial},
      polynomial = multiquadraticStripScreenReducePolynomial[
        Lookup[factor, "Polynomial", <||>], prime];
      If[polynomial === $Failed, $Failed,
        <|"Polynomial" -> polynomial,
          "Power" -> Lookup[factor, "Power", $Failed]|>]];
    numeratorFactors = reduceFactor /@
      Lookup[exact, "NumeratorFactors", {}];
    denominatorFactors = reduceFactor /@
      Lookup[exact, "DenominatorFactors", {}];
    If[MemberQ[numeratorFactors, $Failed] ||
        MemberQ[denominatorFactors, $Failed] ||
        denominatorFactors === {} ||
        ! AllTrue[Join[numeratorFactors, denominatorFactors],
          IntegerQ[#1["Power"]] && #1["Power"] > 0 &],
      Return[$Failed]];
    Return[<|"Representation" -> "SplitValueFactoredRationalV1",
      "NumeratorFactors" -> numeratorFactors,
      "DenominatorFactors" -> denominatorFactors,
      "MaximumExponents" -> exact["MaximumExponents"]|>]];
  numerator = multiquadraticStripScreenReducePolynomial[
    Lookup[exact, "Numerator", <||>], prime];
  denominator = multiquadraticStripScreenReducePolynomial[
    Lookup[exact, "Denominator", <||>], prime];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Numerator" -> numerator, "Denominator" -> denominator,
    "MaximumExponents" -> exact["MaximumExponents"]|>
];
multiquadraticStripScreenReduceScalar[___] := $Failed;

multiquadraticStripScreenCompileScalar[expression_, roots_List,
    rootSymbols_List, variables_List, prime_Integer] :=
  multiquadraticStripScreenReduceScalar[
    multiquadraticStripScreenCompileScalarExact[expression, roots,
      rootSymbols, variables], prime];

(* value and the partial derivative with respect to EVERY compiled
   variable, at one point; every variable value is invertible there,
   which the point acceptance guarantees *)
multiquadraticStripScreenEvaluatePolynomial[compiled_Association,
    powerTables_List, inverses_List, prime_Integer] := Module[
  {exponents = compiled["Exponents"], coefficients = compiled["Coefficients"],
   count = Length[inverses], monomials},
  If[coefficients === {}, Return[{0, ConstantArray[0, count]}]];
  monomials = Fold[
    Function[{accumulated, index},
      Mod[accumulated powerTables[[index]][[exponents[[All, index]] + 1]],
        prime]],
    ConstantArray[1, Length[coefficients]], Range[count]];
  {Mod[coefficients . monomials, prime],
   Table[Mod[inverses[[index]] (
     (coefficients exponents[[All, index]]) . monomials), prime],
    {index, count}]}
];

multiquadraticStripScreenEvaluateRational[compiled_Association,
    powerTables_List, inverses_List, prime_Integer] := Module[
  {numeratorPair, denominatorPair, inverse, value},
  numeratorPair = multiquadraticStripScreenEvaluatePolynomial[
    compiled["Numerator"], powerTables, inverses, prime];
  denominatorPair = multiquadraticStripScreenEvaluatePolynomial[
    compiled["Denominator"], powerTables, inverses, prime];
  If[First[denominatorPair] === 0, Return[$Failed]];
  inverse = PowerMod[First[denominatorPair], -1, prime];
  value = Mod[First[numeratorPair] inverse, prime];
  {value, Mod[(Last[numeratorPair] - value Last[denominatorPair]) inverse,
    prime]}
];

(* Split-branch coefficient images need only the scalar value.  Reusing the
   screen derivative evaluator here would form one extra packed dot product
   per compiled variable for both numerator and denominator, even though all
   of those derivatives are discarded. *)
multiquadraticStripScreenEvaluatePolynomialValue[compiled_Association,
    powerTables_List, prime_Integer] := Module[
  {exponents = compiled["Exponents"], coefficients = compiled["Coefficients"],
   monomials},
  If[coefficients === {}, Return[0]];
  monomials = Fold[
    Function[{accumulated, index},
      Mod[accumulated powerTables[[index]][[exponents[[All, index]] + 1]],
        prime]],
    ConstantArray[1, Length[coefficients]], Range[Length[powerTables]]];
  Mod[coefficients . monomials, prime]
];

multiquadraticStripScreenEvaluateRationalValue[compiled_Association,
    powerTables_List, prime_Integer] := Module[
  {numerator, denominator, evaluateFactor},
  If[Lookup[compiled, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    evaluateFactor[factor_Association] := PowerMod[
      multiquadraticStripScreenEvaluatePolynomialValue[
        factor["Polynomial"], powerTables, prime], factor["Power"], prime];
    numerator = Fold[Mod[#1 #2, prime] &, 1,
      evaluateFactor /@ compiled["NumeratorFactors"]];
    denominator = Fold[Mod[#1 #2, prime] &, 1,
      evaluateFactor /@ compiled["DenominatorFactors"]];
    If[denominator === 0, Return[$Failed]];
    Return[Mod[numerator PowerMod[denominator, -1, prime], prime]]];
  numerator = multiquadraticStripScreenEvaluatePolynomialValue[
    compiled["Numerator"], powerTables, prime];
  denominator = multiquadraticStripScreenEvaluatePolynomialValue[
    compiled["Denominator"], powerTables, prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

multiquadraticStripScreenPowerTables[values_List, maximumExponents_List,
    prime_Integer] := Table[
  FoldList[Mod[#1 values[[index]], prime] &, 1,
    Range[Max[1, maximumExponents[[index]]]]],
  {index, Length[values]}];

(* ------------------------------------------------------------------ *)
(* Screen admission, phase telemetry and compiled-form reuse           *)
(* (Codex 04:30 P1: "the default-on dense screen needs a size/byte gate *)
(* and its own deadline")                                              *)
(* ------------------------------------------------------------------ *)

(* Both screens size a nearly square dense system and hand it to modular
   MatrixRank / NullSpace.  Measured scaling on CF300 (12,9): 43-47 s at
   1816 unknowns, 86-98 s at 2920-3128, 149 s at 3816.  A wider block or
   a larger support turns a default-on "cheap gate" into a dense-memory
   cliff, so the size is ESTIMATED BEFORE ANY ALLOCATION and compared
   against configurable ceilings; over the ceiling the screen returns a
   typed not-applicable result and the established route continues
   unscreened, which is exactly what a gate must do when it cannot
   afford to run. *)
$multiquadraticStripScreenMaximumUnknowns = 20000;
$multiquadraticStripScreenMaximumBytes = 4. 10^9;
$multiquadraticStripSampleMaximumBytes = 4. 10^9;

multiquadraticStripScreenSizeEstimate[rowCount_, columnCount_,
    candidateColumnCount_ : 0] := Module[{total = columnCount + candidateColumnCount},
  <|"Rows" -> rowCount, "Columns" -> columnCount,
    "CandidateColumns" -> candidateColumnCount,
    "TotalColumns" -> total,
    (* one machine integer per entry of the packed matrix, plus the
       augmented column and one transposed copy for the left null space *)
    "PackedBytes" -> 8. rowCount (total + 1) 2|>];

multiquadraticStripScreenAdmissionRefusal[estimate_Association,
    maximumUnknowns_, maximumBytes_, status_String] := Which[
  IntegerQ[maximumUnknowns] && estimate["TotalColumns"] > maximumUnknowns,
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "UnknownCountCeilingExceeded", "SizeEstimate" -> estimate,
      "MaximumUnknowns" -> maximumUnknowns, "MaximumBytes" -> maximumBytes|>,
  NumericQ[maximumBytes] && estimate["PackedBytes"] > maximumBytes,
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ByteCeilingExceeded", "SizeEstimate" -> estimate,
      "MaximumUnknowns" -> maximumUnknowns, "MaximumBytes" -> maximumBytes|>,
  True, None];

(* The production sampler used to discover this limit only after allocation.
   It retains per-point rows and then joins them into the final packed matrix,
   so two dense copies are a hard lower bound on peak memory.  Refuse before
   compiling a provider plan or drawing one point; a smaller support or a
   fibre solver may proceed, but the current dense algorithm may not consume
   the machine merely to demonstrate that it is too large. *)
multiquadraticStripSampleSizeEstimate[pointCount_Integer,
    equationsPerPoint_Integer, normalizationCount_Integer,
    unknownCount_Integer] := Module[{rows},
  rows = pointCount equationsPerPoint + normalizationCount;
  <|"Points" -> pointCount, "Rows" -> rows, "Columns" -> unknownCount,
    "PackedMatrixBytes" -> 8 rows unknownCount,
    "PeakPackedBytesLowerBound" -> 16 rows unknownCount|>
];
multiquadraticStripSampleSizeEstimate[___] := $Failed;

multiquadraticStripSampleAdmissionRefusal[estimate_Association,
    maximumBytes_] := If[
  NumericQ[maximumBytes] &&
      estimate["PeakPackedBytesLowerBound"] > maximumBytes,
  multiquadraticStripFailure["SampleMatrixResourceLimit", <|
    "Reason" -> "DenseMatrixByteCeilingExceeded",
    "SizeEstimate" -> estimate,
    "MaximumMatrixBytes" -> maximumBytes,
    "Resumable" -> True|>],
  None
];
multiquadraticStripSampleAdmissionRefusal[___] :=
  multiquadraticStripFailure["InvalidSampleMatrixAdmission"];

(* Compiled scalar forms are reused across the images of a confirmation
   pair and across the rungs of the degree-offset ladder (Codex 04:30 P1,
   point 4).  A rung changes only the gauge support and denominator: the
   compiled e, c, bbar and root squares are identical, and before this
   cache every rung recompiled all of them for every image.  The key is
   the exact (expression, roots, variables, prime) the compile depends on;
   the cache is byte-bounded and reports hits/misses, so it can never
   become the memory problem the screen ceilings exist to prevent. *)
$multiquadraticStripScreenCompileCache = <||>;
$multiquadraticStripScreenCompileCacheBytes = 0;
$multiquadraticStripScreenCompileCacheLimit = 2. 10^8;
$multiquadraticStripScreenCompileStatistics =
  <|"Hits" -> 0, "Misses" -> 0, "Evictions" -> 0, "Bytes" -> 0|>;

multiquadraticStripScreenCompileCacheClear[] := (
  $multiquadraticStripScreenCompileCache = <||>;
  $multiquadraticStripScreenCompileCacheBytes = 0;
  $multiquadraticStripScreenCompileStatistics =
    <|"Hits" -> 0, "Misses" -> 0, "Evictions" -> 0, "Bytes" -> 0|>);

multiquadraticStripScreenCompileCached[expression_, roots_List,
    rootSymbols_List, variables_List, prime_Integer] := Module[
  {key, value, bytes},
  key = {Hash[{expression, Lookup[roots, "RootSquare", {}], rootSymbols,
    variables, prime}, "SHA256"]};
  If[KeyExistsQ[$multiquadraticStripScreenCompileCache, key],
    $multiquadraticStripScreenCompileStatistics["Hits"] =
      $multiquadraticStripScreenCompileStatistics["Hits"] + 1;
    Return[$multiquadraticStripScreenCompileCache[key]]];
  value = multiquadraticStripScreenCompileScalar[expression, roots,
    rootSymbols, variables, prime];
  $multiquadraticStripScreenCompileStatistics["Misses"] =
    $multiquadraticStripScreenCompileStatistics["Misses"] + 1;
  bytes = ByteCount[value];
  If[$multiquadraticStripScreenCompileCacheBytes + bytes >
      $multiquadraticStripScreenCompileCacheLimit,
    $multiquadraticStripScreenCompileStatistics["Evictions"] =
      $multiquadraticStripScreenCompileStatistics["Evictions"] +
        Length[$multiquadraticStripScreenCompileCache];
    $multiquadraticStripScreenCompileCache = <||>;
    $multiquadraticStripScreenCompileCacheBytes = 0];
  $multiquadraticStripScreenCompileCache[key] = value;
  $multiquadraticStripScreenCompileCacheBytes =
    $multiquadraticStripScreenCompileCacheBytes + bytes;
  $multiquadraticStripScreenCompileStatistics["Bytes"] =
    $multiquadraticStripScreenCompileCacheBytes;
  value
];

Options[multiquadraticStripIntegrabilityScreen] = {
  "Prime" -> Automatic,
  "RegulatorValue" -> Automatic,
  "PointCount" -> 20,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082401,
  "ScoreLetters" -> True,
  "ForcingProvider" -> Automatic,
  "Deadline" -> Infinity,
  "MaximumUnknowns" -> Automatic,
  "MaximumBytes" -> Automatic,
  (* the byte ceiling of the shared compiled-scalar cache, as an OPTION
     rather than a dynamic global: a per-call ceiling belongs to the
     call (2026-08-25).  Automatic is the module constant. *)
  "CompileCacheBytes" -> Automatic
};

multiquadraticStripIntegrabilityScreen[record_Association, roots_List,
    letterRecords_List, opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, strip, e, c, bbar, upper, lower, rank, prime,
   regulatorValue, epsilonMod, pointCount, maximumAttempts, randomSeed,
   rootSymbols, compileScalar, deltaCompiled,
   eCompiled, cCompiled, bCompiled, letterCompiled, maximumExponents,
   letterCount, unknownCount, rows = {}, right = {}, accepted = {},
   rejected = <||>, attempts = 0, point, probeTables, probeInverses,
   deltaValues, rootValues, pointRows, pointRight, pointOK, notFlat = False,
   values, inverses, powerTables, rootDerivatives, evaluate, matrixValue,
   matrixDerivative, ex, ey, cx, cy, bx, by, dyex, dxey, dycx, dxcy, dybx,
   dxby, curvatureE, curvatureC, forcingCurl, oneFormValues, matrix,
   rightVector, rankA, rankAugmented, defect, witness, nullVectors, scored,
   keptColumns, screenStatus, rationalLeaves,
   deadline, maximumUnknowns, maximumBytes, sizeEstimate, refusal,
   lettersCompiled = 0, letterIndex, compileCacheBytes,
   startTime = AbsoluteTime[], phaseTimings = <||>, compileSeconds,
   assemblySeconds, rankSeconds, leftNullSeconds = 0., expired = False,
   compileStatisticsBefore, forcingProvider, nativeForcingQ,
   sameFrameNativeForcingQ, chartNativeForcingQ, preflight, chartPreflight,
   nativeForcing, bbarChannels, bbarDerivativeChannels, bbarCurlChannels,
   forcingExteriorDerivative, gradeMonomials, composeChannels},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripIntegrabilityScreen]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline|>]]];
  maximumUnknowns = Replace[OptionValue["MaximumUnknowns"],
    Automatic :> $multiquadraticStripScreenMaximumUnknowns];
  maximumBytes = Replace[OptionValue["MaximumBytes"],
    Automatic :> $multiquadraticStripScreenMaximumBytes];
  compileCacheBytes = Replace[OptionValue["CompileCacheBytes"],
    Automatic :> $multiquadraticStripScreenCompileCacheLimit];
  If[! (NumericQ[compileCacheBytes] && compileCacheBytes > 0),
    Return[multiquadraticStripFailure["InvalidScreenCompileCacheBytes",
      <|"CompileCacheBytes" -> compileCacheBytes|>]]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  {e, c, bbar} = strip;
  If[! MatchQ[Dimensions[bbar], {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  {upper, lower} = Dimensions[bbar[[1]]];
  rank = Length[roots];
  forcingProvider = OptionValue["ForcingProvider"];
  sameFrameNativeForcingQ = AssociationQ[forcingProvider] &&
    multiquadraticStripProviderValidQ[forcingProvider] &&
    Lookup[forcingProvider, "RootCount", None] === rank &&
    Lookup[forcingProvider, "Variables", None] === variables &&
    Lookup[forcingProvider, "Regulator", None] === epsilon &&
    Lookup[forcingProvider, "Dimensions", None] === {upper, lower} &&
    AssociationQ[Lookup[forcingProvider, "DeferredPreparation", None]];
  chartNativeForcingQ = AssociationQ[forcingProvider] &&
    multiquadraticStripChartForcingProviderValidQ[forcingProvider] &&
    Lookup[forcingProvider, "RootCount", None] === rank &&
    Lookup[forcingProvider, "Variables", None] === variables &&
    Lookup[forcingProvider, "Regulator", None] === epsilon &&
    Lookup[forcingProvider, "Dimensions", None] === {upper, lower} &&
    Lookup[forcingProvider, "Roots", None] === roots;
  nativeForcingQ = sameFrameNativeForcingQ || chartNativeForcingQ;
  If[forcingProvider =!= Automatic && ! nativeForcingQ,
    Return[multiquadraticStripFailure["InvalidIntegrabilityForcingProvider"]]];
  If[rank > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank"]]];
  prime = Replace[OptionValue["Prime"],
    Automatic :> First[$multiquadraticStripDefaultPrimes]];
  regulatorValue = Replace[OptionValue["RegulatorValue"],
    Automatic :> First[$multiquadraticStripDefaultRegulatorValues]];
  pointCount = OptionValue["PointCount"];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount + 40];
  randomSeed = OptionValue["RandomSeed"];
  If[! PrimeQ[prime] || ! (3 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
      ! MatchQ[regulatorValue, _Integer | _Rational] ||
      ! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[randomSeed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount,
    Return[multiquadraticStripFailure["InvalidIntegrabilityScreenInput",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue,
        "PointCount" -> pointCount|>]]];
  epsilonMod = multiquadraticStripModRational[regulatorValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue|>]]];
  letterCount = Length[letterRecords];
  If[letterCount < 1, Return[multiquadraticStripFailure["EmptyAlphabet"]]];
  (* the admission gate, BEFORE any allocation or compile: rows are
     2^rank equations per accepted point times the two one-form
     components times the block entries, columns are the residue
     unknowns *)
  sizeEstimate = multiquadraticStripScreenSizeEstimate[
    pointCount 2^rank upper lower, letterCount upper lower];
  refusal = multiquadraticStripScreenAdmissionRefusal[sizeEstimate,
    maximumUnknowns, maximumBytes, "IntegrabilityScreenNotApplicable"];
  If[AssociationQ[refusal],
    Return[Join[refusal, <|"Prime" -> prime,
      "RegulatorValue" -> regulatorValue, "LetterCount" -> letterCount,
      "Seconds" -> AbsoluteTime[] - startTime|>]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:Compile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate|>]]];
  rootSymbols = Table[Unique["multiquadraticRoot$"], {rank}];
  compileScalar[expression_] := multiquadraticStripScreenCompileCached[
    Quiet[Check[Together[expression /. epsilon -> regulatorValue], $Failed,
      {Power::infy, Infinity::indet, Power::indet}]],
    roots, rootSymbols, variables, prime];
  compileStatisticsBefore = $multiquadraticStripScreenCompileStatistics;
  (* INTERIOR BOUNDARIES of the compile phase (2026-08-25): the letter,
     and the three diagonal/forcing tensors.  See the identical note in
     multiquadraticStripGaugeScreen. *)
  lettersCompiled = 0;
  compileSeconds = First[AbsoluteTiming[
   Block[{$multiquadraticStripScreenCompileCacheLimit = compileCacheBytes},
    deltaCompiled = multiquadraticStripScreenCompileCached[#1, {}, rootSymbols,
        variables, prime] & /@ Lookup[roots, "RootSquare", {}];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    eCompiled = If[expired, {}, Map[compileScalar, e, {3}]];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    cCompiled = If[expired, {}, Map[compileScalar, c, {3}]];
    If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
    bCompiled = If[expired || nativeForcingQ, {},
      Map[compileScalar, bbar, {3}]];
    letterCompiled = With[
      {forms = Lookup[letterRecords, "OneForm", {}]},
      Table[
        If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
          expired = True; {},
          lettersCompiled++; compileScalar /@ forms[[letterIndex]]],
        {letterIndex, Length[forms]}]];]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:LetterCompile", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "LettersCompiled" -> lettersCompiled, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  If[! FreeQ[{deltaCompiled, eCompiled, cCompiled, bCompiled, letterCompiled},
      $Failed],
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ScreenCompilationFailed", "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:PointAssembly", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  rationalLeaves = Cases[{deltaCompiled, eCompiled, cCompiled, bCompiled,
      letterCompiled}, association_Association /;
      KeyExistsQ[association, "Numerator"] :> association, {0, Infinity}];
  maximumExponents = Max /@ Transpose[
    Lookup[rationalLeaves, "MaximumExponents"]];
  assemblySeconds = First[AbsoluteTiming[
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts &&
        ! notFlat && ! expired,
      (* cooperative stop during point acquisition: every accepted point
         is one 2^rank-branch evaluation of the whole block *)
      If[multiquadraticStripDeadlineExpiredQ[deadline],
        expired = True; Break[]];
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      (* the root squares first: the point must split every declared root *)
      probeTables = multiquadraticStripScreenPowerTables[
        Join[point, ConstantArray[1, rank]], maximumExponents, prime];
      probeInverses = Join[PowerMod[point, -1, prime], ConstantArray[1, rank]];
      deltaValues = Table[
        Module[{pair = multiquadraticStripScreenEvaluateRational[
           deltaCompiled[[a]], probeTables, probeInverses, prime]},
         If[pair === $Failed, $Failed, First[pair]]], {a, rank}];
      If[MemberQ[deltaValues, $Failed] || MemberQ[deltaValues, 0] ||
          ! AllTrue[deltaValues, modularResidueQ[#1, prime] &],
        rejected["NotSplitOverPrime"] =
          Lookup[rejected, "NotSplitOverPrime", 0] + 1;
        Continue[]];
      (* one implementation (Core/ModularArithmetic.wl, 2026-09-02): for
         the p == 3 (mod 4) primes this screen admits, and radicands that
         passed the residue test above, this is the former
         PowerMod[delta, (p+1)/4, p] representative with the same square
         check, and the rejection branch stays as unreachable as it was *)
      rootValues = multiquadraticSquareRoots[deltaValues, prime];
      If[rootValues === $Failed,
        rejected["RootImageNotARoot"] =
          Lookup[rejected, "RootImageNotARoot", 0] + 1;
        Continue[]];
      If[nativeForcingQ,
        If[chartNativeForcingQ,
          chartPreflight = multiquadraticStripChartForcingPreflight[
            forcingProvider, regulatorValue, prime, point, rootValues];
          If[Lookup[chartPreflight, "Status", None] =!=
              "MultiquadraticChartForcingPreflightV1",
            rejected["NativeForcingPreflight"] =
              Lookup[rejected, "NativeForcingPreflight", 0] + 1;
            Continue[]];
          nativeForcing =
            multiquadraticStripNativeDeferredChartEvaluateBatch[
              forcingProvider, {chartPreflight}];
          If[Lookup[nativeForcing, "Status", None] =!=
                "MultiquadraticNativeDeferredChartBatchV1" ||
              Length[Lookup[nativeForcing, "BBarBatch", {}]] =!= 1 ||
              Length[Lookup[nativeForcing, "BBarCurlBatch", {}]] =!= 1,
            rejected["NativeForcingEvaluation"] =
              Lookup[rejected, "NativeForcingEvaluation", 0] + 1;
            Continue[]];
          bbarChannels = First[nativeForcing["BBarBatch"]];
          bbarCurlChannels = First[nativeForcing["BBarCurlBatch"]],
          preflight = multiquadraticStripProviderPreflight[
            forcingProvider, regulatorValue, prime, point];
          If[Lookup[preflight, "Status", None] =!=
              "MultiquadraticProviderPreflightV1" ||
              ! TrueQ[Lookup[preflight, "SplitPointQ", False]],
            rejected["NativeForcingPreflight"] =
              Lookup[rejected, "NativeForcingPreflight", 0] + 1;
            Continue[]];
          rootValues = preflight["RootValues"];
          nativeForcing = multiquadraticStripNativeDeferredEvaluateBatch[
            forcingProvider, {preflight}, "Derivatives" -> True];
          If[Lookup[nativeForcing, "Status", None] =!=
                "MultiquadraticNativeDeferredDerivativeBatchV1" ||
              Length[Lookup[nativeForcing, "BBarBatch", {}]] =!= 1 ||
              Take[Dimensions[Lookup[nativeForcing,
                  "BBarDerivativeBatch", {}]], UpTo[2]] =!= {2, 1},
            rejected["NativeForcingEvaluation"] =
              Lookup[rejected, "NativeForcingEvaluation", 0] + 1;
            Continue[]];
          bbarChannels = First[nativeForcing["BBarBatch"]];
          bbarDerivativeChannels =
            nativeForcing["BBarDerivativeBatch"][[All, 1]];
          bbarCurlChannels = Mod[
            bbarDerivativeChannels[[2, 1]] -
              bbarDerivativeChannels[[1, 2]], prime]]];
      pointRows = {}; pointRight = {}; pointOK = True;
      Do[
        values = Join[point, Table[
          Mod[If[BitGet[mask, a - 1] === 1, -1, 1] rootValues[[a]], prime],
          {a, rank}]];
        If[MemberQ[values, 0], pointOK = False; Break[]];
        inverses = PowerMod[values, -1, prime];
        powerTables = multiquadraticStripScreenPowerTables[values,
          maximumExponents, prime];
        rootDerivatives = Table[
          Module[{pair = multiquadraticStripScreenEvaluateRational[
             deltaCompiled[[a]], powerTables, inverses, prime], half},
           If[pair === $Failed, ConstantArray[0, 2],
             half = PowerMod[Mod[2 values[[2 + a]], prime], -1, prime];
             Mod[half Last[pair][[1 ;; 2]], prime]]],
          {a, rank}];
        evaluate[compiled_] := Module[{pair},
          pair = multiquadraticStripScreenEvaluateRational[compiled,
            powerTables, inverses, prime];
          If[pair === $Failed, Throw[$Failed, "MultiquadraticScreenPoint"]];
          {First[pair], Table[Mod[Last[pair][[mu]] +
             Sum[Last[pair][[2 + a]] rootDerivatives[[a, mu]], {a, rank}],
             prime], {mu, 2}]}];
        matrixValue[block_] := Map[First[evaluate[#1]] &, block, {2}];
        matrixDerivative[block_, mu_] :=
          Map[Last[evaluate[#1]][[mu]] &, block, {2}];
        gradeMonomials = Table[Product[
          If[BitGet[grade - 1, a - 1] === 1, values[[2 + a]], 1],
          {a, rank}], {grade, 2^rank}];
        composeChannels[channelTensor_] := Map[
          Mod[#1 . gradeMonomials, prime] &, channelTensor, {2}];
        If[Catch[
            ex = matrixValue[eCompiled[[1]]]; ey = matrixValue[eCompiled[[2]]];
            cx = matrixValue[cCompiled[[1]]]; cy = matrixValue[cCompiled[[2]]];
            If[nativeForcingQ,
              bx = composeChannels[bbarChannels[[1]]];
              by = composeChannels[bbarChannels[[2]]],
              bx = matrixValue[bCompiled[[1]]];
              by = matrixValue[bCompiled[[2]]]];
            dyex = matrixDerivative[eCompiled[[1]], 2];
            dxey = matrixDerivative[eCompiled[[2]], 1];
            dycx = matrixDerivative[cCompiled[[1]], 2];
            dxcy = matrixDerivative[cCompiled[[2]], 1];
            If[nativeForcingQ,
              forcingExteriorDerivative = composeChannels[bbarCurlChannels],
              dybx = matrixDerivative[bCompiled[[1]], 2];
              dxby = matrixDerivative[bCompiled[[2]], 1];
              forcingExteriorDerivative = Mod[dybx - dxby, prime]];
            oneFormValues = Table[
              {First[evaluate[letterCompiled[[k, 1]]]],
               First[evaluate[letterCompiled[[k, 2]]]]}, {k, letterCount}];
            True, "MultiquadraticScreenPoint"] =!= True,
          pointOK = False; Break[]];
        curvatureE = Mod[dyex - dxey + epsilonMod (ex . ey - ey . ex), prime];
        curvatureC = Mod[dycx - dxcy + epsilonMod (cx . cy - cy . cx), prime];
        If[! (AllTrue[Flatten[curvatureE], #1 === 0 &] &&
            AllTrue[Flatten[curvatureC], #1 === 0 &]),
          notFlat = True; pointOK = False; Break[]];
        forcingCurl = Mod[forcingExteriorDerivative +
          epsilonMod (ex . by - ey . bx + bx . cy - by . cx), prime];
        Do[
          AppendTo[pointRight, forcingCurl[[i, j]]];
          AppendTo[pointRows, Developer`ToPackedArray[Flatten[Table[
            Mod[Mod[epsilonMod^2, prime] Mod[
              If[vv === j, Mod[oneFormValues[[k, 2]] ex[[i, uu]] -
                oneFormValues[[k, 1]] ey[[i, uu]], prime], 0] +
              If[uu === i, Mod[oneFormValues[[k, 1]] cy[[vv, j]] -
                oneFormValues[[k, 2]] cx[[vv, j]], prime], 0], prime], prime],
            {k, letterCount}, {uu, upper}, {vv, lower}]]]],
          {i, upper}, {j, lower}],
        {mask, 0, 2^rank - 1}];
      If[TrueQ[pointOK],
        AppendTo[accepted, point];
        rows = Join[rows, pointRows]; right = Join[right, pointRight],
        rejected["Unusable"] = Lookup[rejected, "Unusable", 0] + 1]]]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted[
      "IntegrabilityScreen:PointAssembly", AbsoluteTime[] - startTime,
      deadline, <|"SizeEstimate" -> sizeEstimate,
        "PointCount" -> Length[accepted], "AttemptCount" -> attempts,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  If[TrueQ[notFlat],
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "DiagonalConnectionsNotFlat",
      "FlatDiagonalConnections" -> False, "Prime" -> prime,
      "RegulatorValue" -> regulatorValue, "AttemptCount" -> attempts|>]];
  If[Length[accepted] < 1 || rows === {},
    Return[<|"Status" -> "IntegrabilityScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "NoAdmissiblePoints", "AttemptCount" -> attempts,
      "RejectedPoints" -> rejected, "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  unknownCount = letterCount upper lower;
  matrix = Developer`ToPackedArray[rows];
  rightVector = Developer`ToPackedArray[right];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:Rank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  rankSeconds = First[AbsoluteTiming[
    rankA = MatrixRank[matrix, Modulus -> prime];
    rankAugmented = MatrixRank[MapThread[Append, {matrix, rightVector}],
      Modulus -> prime];]];
  defect = rankAugmented - rankA;
  (* POST-RANK BOUNDARY (2026-08-25): the verdict is paid for, and the
     left null space plus one MatrixRank per letter below is a second
     expensive block.  The stop carries the rank pair it measured. *)
  If[(defect > 0 || (TrueQ[OptionValue["ScoreLetters"]] && letterCount > 1)) &&
      multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["IntegrabilityScreen:PostRank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "Defect" -> defect, "Rank" -> rankA,
        "AugmentedRank" -> rankAugmented, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds|>|>]]];
  witness = Missing["Consistent"];
  If[defect > 0,
    leftNullSeconds = First[AbsoluteTiming[
      nullVectors = NullSpace[Transpose[matrix], Modulus -> prime];]];
    witness = SelectFirst[nullVectors, Mod[#1 . rightVector, prime] =!= 0 &,
      Missing["NoWitnessFound"]];
    If[! MissingQ[witness],
      witness = <|"Prime" -> prime, "Vector" -> witness,
        "TransposeResidualZero" ->
          AllTrue[Mod[witness . matrix, prime], #1 === 0 &],
        "RightHandSidePairing" -> Mod[witness . rightVector, prime],
        "Support" -> Count[witness, _?(#1 =!= 0 &)]|>]];
  scored = If[TrueQ[OptionValue["ScoreLetters"]] && letterCount > 1,
    Table[
      keptColumns = Complement[Range[unknownCount],
        Range[(k - 1) upper lower + 1, k upper lower]];
      <|"Index" -> k, "Kind" -> Lookup[letterRecords[[k]], "Kind", None],
        "Letter" -> Lookup[letterRecords[[k]], "Letter", Missing["NoLetter"]],
        "RankContribution" ->
          rankA - MatrixRank[matrix[[All, keptColumns]], Modulus -> prime]|>,
      {k, letterCount}], {}];
  (* ONE IMAGE.  These statuses are the per-image verdict and keep their
     names; a CONFIRMED verdict over two independent (prime, regulator)
     images is what multiquadraticStripIntegrabilityScreenImages returns
     and what the top level is allowed to act on (Codex 04:30 P1). *)
  screenStatus = If[defect > 0, "AlphabetIntegrabilityObstruction",
    "AlphabetIntegrabilityConsistent"];
  phaseTimings = <|"Compile" -> compileSeconds,
    "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds,
    "LeftNullSpace" -> leftNullSeconds|>;
  <|"Status" -> screenStatus, "Module" -> "MultiquadraticStripSolve",
    "Method" -> "ResidueOnlyIntegrability",
    "SizeEstimate" -> sizeEstimate, "PhaseTimings" -> phaseTimings,
    "CompileCache" -> Join[
      AssociationMap[($multiquadraticStripScreenCompileStatistics[#1] -
        compileStatisticsBefore[#1]) &, {"Hits", "Misses", "Evictions"}],
      <|"Bytes" -> $multiquadraticStripScreenCompileCacheBytes|>],
    "Seconds" -> AbsoluteTime[] - startTime,
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Defect" -> defect, "Rank" -> rankA, "AugmentedRank" -> rankAugmented,
    "Nullity" -> unknownCount - rankA,
    "MatrixDimensions" -> Dimensions[matrix],
    "UnknownCount" -> unknownCount, "LetterCount" -> letterCount,
    "Prime" -> prime, "RegulatorValue" -> regulatorValue,
    "PointCount" -> Length[accepted], "AcceptedPoints" -> accepted,
    "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
    "FlatDiagonalConnections" -> True, "Witness" -> witness,
    "ScoredLetters" -> scored,
    "Alphabet" -> Lookup[letterRecords, "Letter", {}],
    "LetterKinds" -> Lookup[letterRecords, "Kind", {}]|>
];
multiquadraticStripIntegrabilityScreen[___] :=
  multiquadraticStripFailure["InvalidIntegrabilityScreenArguments"];

(* ------------------------------------------------------------------ *)
(* TWO INDEPENDENT IMAGES ON THE REJECTION PATH ONLY                    *)
(* (Codex 04:30 P1: "a single regulator image is not an exact generic  *)
(*  Q(eps) obstruction")                                                *)
(* ------------------------------------------------------------------ *)

(* A rank defect of the specialized finite-field system is EXACT for that
   system, and it is NOT a theorem about the generic system over Q(eps):
   a generically solvable system such as (eps - a) z = 1 is inconsistent
   at eps = a, and more (x, y) points AT THE SAME REGULATOR VALUE cannot
   remove that exceptional-regulator mode.  Nor is a solution denominator
   known in advance from the input-pole census.
   So: the fast single-image CONSISTENCY path is kept exactly as it was
   -- a consistent image gates nothing and is not made more consistent by
   a second one -- and only a REJECTION is confirmed at a second
   independent (prime, regulator) image, precisely as the full-gauge
   screen already does.  Two agreeing images make the verdict a
   HIGH-CONFIDENCE MODULAR OBSTRUCTION, which is what the caller may act
   on; it is still not an unconditional theorem over Q(eps), and the
   status language and the solution contract say so. *)
(* ------------------------------------------------------------------ *)
(* The screen-evidence classifier (round-3 A1, Codex instruction).      *)
(*                                                                      *)
(* ONE side-effect-free classifier decides every screen verdict, for    *)
(* the residue-only screen and the full-gauge screen alike.  Its input  *)
(* is EVIDENCE, not a solver object:                                    *)
(*   ConfiguredRequired / ConfiguredUsable -- the configured images;    *)
(*   FreshRequested / FreshGenerated / FreshUsable -- the fresh draw;   *)
(*   Defects -- every USABLE defect, configured then fresh;             *)
(*   UnusableStatuses -- statuses of images that did not measure;       *)
(*   ConfirmationEnabled -- whether a negative may be confirmed at all. *)
(*                                                                      *)
(* The one monotonicity rule: adding evidence may confirm or weaken a   *)
(* verdict, but failed or contrary fresh evidence is NEVER discarded in *)
(* favour of an earlier two-image result.  "FreshRequested" -> 0 is     *)
(* deliberately valid: a caller that explicitly asks for zero fresh     *)
(* images accepts the configured-image evidence as the whole contract.  *)
(* ------------------------------------------------------------------ *)

multiquadraticStripScreenEvidenceConfirmedQ[ev_Association] :=
  TrueQ[Lookup[ev, "ConfirmationEnabled", False]] &&
  Lookup[ev, "ConfiguredUsable", 0] >= Lookup[ev, "ConfiguredRequired", 2] &&
  Lookup[ev, "FreshGenerated", -1] === Lookup[ev, "FreshRequested", 0] &&
  Lookup[ev, "FreshUsable", -1] === Lookup[ev, "FreshRequested", 0] &&
  Length[Lookup[ev, "Defects", {}]] ===
    Lookup[ev, "ConfiguredUsable", 0] + Lookup[ev, "FreshUsable", 0] &&
  Lookup[ev, "Defects", {}] =!= {} &&
  AllTrue[Lookup[ev, "Defects", {None}], IntegerQ[#1] && #1 > 0 &];

multiquadraticStripScreenEvidenceClassify[ev_Association] := Module[
  {defects = Lookup[ev, "Defects", {}],
   unusable = Lookup[ev, "UnusableStatuses", {}], allPositive},
  allPositive = defects =!= {} &&
    AllTrue[defects, IntegerQ[#1] && #1 > 0 &];
  Which[
    (* a usable zero defect is SAMPLED consistency: that image exhibits
       a solution of its own specialized system.  It wins over every
       positive defect (monotonicity), but it is not a claim about the
       generic field. *)
    defects =!= {} && AllTrue[defects, #1 === 0 &],
      <|"Verdict" -> "SampledConsistent", "AllZero" -> True|>,
    AnyTrue[defects, #1 === 0 &],
      <|"Verdict" -> "SampledConsistent", "AllZero" -> False,
        "Reason" -> "MixedDefectEvidence"|>,
    multiquadraticStripScreenEvidenceConfirmedQ[ev],
      <|"Verdict" -> "ConfirmedObstruction"|>,
    allPositive && unusable =!= {},
      <|"Verdict" -> "Inconclusive", "Reason" -> "UnusableFreshImage"|>,
    allPositive && Lookup[ev, "ConfiguredUsable", 0] >=
        Lookup[ev, "ConfiguredRequired", 2],
      (* every usable image carries a defect, but the requested fresh
         evidence was not fully obtained: the verdict may not harden *)
      <|"Verdict" -> "Inconclusive", "Reason" -> "FreshEvidenceIncomplete"|>,
    allPositive,
      <|"Verdict" -> "Unconfirmed"|>,
    True,
      <|"Verdict" -> "Inconclusive", "Reason" -> "InsufficientEvidence"|>]
];
multiquadraticStripScreenEvidenceClassify[___] :=
  multiquadraticStripFailure["InvalidScreenEvidence"];

(* the predicate a DRIVER must recheck before returning any negative
   contract: the status name alone is not the authority, the evidence
   record is *)
multiquadraticStripConfirmedObstructionEvidenceQ[rec_Association] :=
  Module[{ev = Lookup[rec, "EvidenceRecord", <||>]},
    AssociationQ[ev] && multiquadraticStripScreenEvidenceConfirmedQ[ev]];
multiquadraticStripConfirmedObstructionEvidenceQ[___] := False;

(* Fresh random good images for the RESIDUE-ONLY screen.  Same admission
   as the gauge generator -- unused admissible prime, regulator value the
   forcing sampler accepts -- but NO gauge-denominator condition, because
   there is no gauge ansatz here; instead the root squares and letter
   one-forms must remain evaluable and nondegenerate at the value. *)
multiquadraticStripFreshResidueScreenImages[record_Association, roots_List,
    letterRecords_List, count_Integer, seed_Integer, excludePrimes_List,
    excludeValues_List] := Module[
  {variables, epsilon, strip, pool, sampled, values, primes, candidate,
   rejectedPrimes = {}, rejectedValues, attempts, evaluableQ, squares,
   oneForms},
  If[count <= 0, Return[<|"Status" -> "NoFreshImagesRequested",
    "Images" -> {}, "RejectedPrimes" -> {}, "RejectedValues" -> {}|>]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidRecordForFreshResidueImages"]]];
  squares = Lookup[roots, "RootSquare", {}];
  oneForms = Lookup[letterRecords, "OneForm", {}];
  evaluableQ[value_] := Module[{image = Quiet[Check[
      Together[{squares, oneForms} /. epsilon -> value], $Failed]]},
    image =!= $Failed &&
      FreeQ[image, DirectedInfinity | Indeterminate | ComplexInfinity] &&
      ! AnyTrue[Flatten[{image[[1]]}], TrueQ[Together[#1] === 0] &]];
  pool = DeleteCases[
    BlockRandom[RandomSample[$multiquadraticStripRegulatorSamplePool],
      RandomSeeding -> seed],
    Alternatives @@ excludeValues];
  pool = Select[pool, evaluableQ];
  sampled = multiquadraticStripRegulatorSampleValues[strip[[3]], variables,
    epsilon, count, pool];
  values = Lookup[sampled, "Values", {}];
  rejectedValues = Lookup[sampled, "RejectedValues", {}];
  primes = {}; attempts = 0;
  BlockRandom[
    While[Length[primes] < Length[values] && attempts < 4096,
      attempts++;
      candidate = NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]];
      If[Mod[candidate, 4] === 3 && candidate < 2^31 &&
          ! MemberQ[excludePrimes, candidate] && ! MemberQ[primes, candidate],
        AppendTo[primes, candidate],
        AppendTo[rejectedPrimes, candidate]]],
    RandomSeeding -> seed + 104729];
  If[Length[primes] < Length[values], values = Take[values, Length[primes]]];
  <|"Status" -> If[Length[values] >= count, "FreshScreenImages",
      "InsufficientFreshScreenImages"],
    "Images" -> Transpose[{Take[primes, Length[values]], values}],
    "Requested" -> count, "Seed" -> seed,
    "RejectedValues" -> rejectedValues,
    "RejectedPrimeCount" -> Length[rejectedPrimes]|>
];
multiquadraticStripFreshResidueScreenImages[___] :=
  multiquadraticStripFailure["InvalidFreshResidueImageArguments"];

Options[multiquadraticStripIntegrabilityScreenImages] = Join[
  Options[multiquadraticStripIntegrabilityScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True,
  "FreshImageCount" -> Automatic,
  "FreshImageSeed" -> Automatic
}];

multiquadraticStripIntegrabilityScreenImages[record_Association, roots_List,
    letterRecords_List, opts : OptionsPattern[]] := Module[
  {gate, images, firstPrime, firstRegulator, results = {}, screenOptions,
   result, defects, status, startTime = AbsoluteTime[], configuredCount,
   freshCount, freshSeed, freshRequest, freshImages = {},
   freshResults = {}, evidence, verdict, allImages},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripIntegrabilityScreenImages]]]];
  If[AssociationQ[gate], Return[gate]];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}],
    Return[multiquadraticStripFailure["InvalidIntegrabilityScreenImages",
      <|"Images" -> images|>]]];
  (* an explicitly requested prime / regulator value IS the first image:
     the caller's choice (the alphabet's own first regulator sample) must
     stay the one that decides the fast path *)
  firstPrime = OptionValue["Prime"];
  firstRegulator = OptionValue["RegulatorValue"];
  images = ReplacePart[images, 1 -> {
    Replace[firstPrime, Automatic :> images[[1, 1]]],
    Replace[firstRegulator, Automatic :> images[[1, 2]]]}];
  (* two identical images are one image, not two confirmations *)
  images = DeleteDuplicates[images];
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["Prime" -> _] | HoldPattern["RegulatorValue" -> _] |
      HoldPattern["RandomSeed" -> _]],
    Options[multiquadraticStripIntegrabilityScreen]];
  Do[
    result = multiquadraticStripIntegrabilityScreen[record, roots,
      letterRecords, "Prime" -> images[[k, 1]],
      "RegulatorValue" -> images[[k, 2]],
      "RandomSeed" -> OptionValue["RandomSeed"] + 7919 k,
      Sequence @@ screenOptions];
    AppendTo[results, result];
    If[! MemberQ[{"AlphabetIntegrabilityObstruction",
        "AlphabetIntegrabilityConsistent"}, Lookup[result, "Status", None]],
      Break[]];
    (* the fast path: a zero-defect image ends the screen and permits
       the full route.  It is SAMPLED consistency -- a solution of that
       image's own specialized system -- not proof of generic
       solvability; the classifier below records it as such. *)
    If[Lookup[result, "Defect", 1] === 0, Break[]];
    If[! TrueQ[OptionValue["ConfirmObstruction"]], Break[]],
    {k, Length[images]}];
  configuredCount = Length[results];
  (* ---- the fresh-image confirmation (round-3 A1): a defect that
     survives every configured image is re-tested at fresh random good
     images through the same evidence classifier as the full-gauge
     screen.  "FreshImageCount" -> 0 accepts the configured evidence. *)
  freshCount = Replace[OptionValue["FreshImageCount"],
    Automatic :> $multiquadraticStripDefaultFreshImageCount];
  freshSeed = Replace[OptionValue["FreshImageSeed"],
    Automatic :> Replace[OptionValue["RandomSeed"], Automatic -> 20260826]];
  If[! IntegerQ[freshSeed], freshSeed = 20260826];
  freshRequest = <|"Status" -> "FreshImagesNotRun"|>;
  If[freshCount > 0 && TrueQ[OptionValue["ConfirmObstruction"]] &&
      configuredCount >= 2 &&
      AllTrue[results, Lookup[#1, "Status", None] ===
        "AlphabetIntegrabilityObstruction" &] &&
      AllTrue[results, IntegerQ[Lookup[#1, "Defect", None]] &&
        Lookup[#1, "Defect", 0] > 0 &],
    freshRequest = multiquadraticStripFreshResidueScreenImages[record, roots,
      letterRecords, freshCount, freshSeed, images[[All, 1]],
      images[[All, 2]]];
    freshImages = Lookup[freshRequest, "Images", {}];
    If[! MatchQ[freshImages, {{_Integer, _Integer | _Rational} ...}],
      freshImages = {}];
    Do[
      result = multiquadraticStripIntegrabilityScreen[record, roots,
        letterRecords, "Prime" -> freshImages[[k, 1]],
        "RegulatorValue" -> freshImages[[k, 2]],
        "RandomSeed" -> freshSeed + 15485863 k,
        Sequence @@ screenOptions];
      If[! MemberQ[{"AlphabetIntegrabilityObstruction",
          "AlphabetIntegrabilityConsistent"}, Lookup[result, "Status", None]],
        freshRequest = Join[freshRequest,
          <|"UnusableImage" -> freshImages[[k]],
            "UnusableImageStatus" -> Lookup[result, "Status", None]|>];
        Break[]];
      AppendTo[freshResults, result];
      AppendTo[results, result];
      If[Lookup[result, "Defect", 1] === 0, Break[]],
      {k, Length[freshImages]}]];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  evidence = <|
    "ConfiguredRequired" -> 2,
    "ConfiguredUsable" -> Count[Take[results, UpTo[configuredCount]],
      r_ /; MemberQ[{"AlphabetIntegrabilityObstruction",
        "AlphabetIntegrabilityConsistent"}, Lookup[r, "Status", None]]],
    "FreshRequested" -> If[Lookup[freshRequest, "Status", None] ===
        "FreshImagesNotRun" && freshCount > 0 &&
        ! AllTrue[Take[results, UpTo[configuredCount]],
          IntegerQ[Lookup[#1, "Defect", None]] &&
            Lookup[#1, "Defect", 0] > 0 &], 0, freshCount],
    "FreshGenerated" -> Length[Lookup[freshRequest, "Images", {}]],
    "FreshUsable" -> Length[freshResults],
    "Defects" -> Select[defects, IntegerQ],
    "UnusableStatuses" -> DeleteMissing[
      {Lookup[freshRequest, "UnusableImageStatus", Missing["None"]]}],
    "ConfirmationEnabled" -> TrueQ[OptionValue["ConfirmObstruction"]]|>;
  verdict = multiquadraticStripScreenEvidenceClassify[evidence];
  status = Which[
    ! AllTrue[Take[results, UpTo[configuredCount]],
        MemberQ[{"AlphabetIntegrabilityObstruction",
          "AlphabetIntegrabilityConsistent"}, Lookup[#1, "Status", None]] &],
      (* a not-applicable / budget-exhausted configured image is not a
         verdict *)
      Lookup[Last[Take[results, UpTo[configuredCount]]], "Status",
        "IntegrabilityScreenNotApplicable"],
    Lookup[verdict, "Verdict", None] === "SampledConsistent",
      "AlphabetIntegrabilityConsistent",
    Lookup[verdict, "Verdict", None] === "ConfirmedObstruction",
      "AlphabetIntegrabilityObstruction",
    Lookup[verdict, "Verdict", None] === "Unconfirmed",
      "AlphabetIntegrabilityObstructionUnconfirmed",
    True, "IntegrabilityScreenInconclusive"];
  allImages = Join[Take[images, UpTo[configuredCount]],
    Take[freshImages, UpTo[Length[freshResults]]]];
  Join[
    (* the deciding image's own payload travels on, so witnesses,
       scored letters and phase timings are not lost by the wrapper *)
    KeyDrop[Last[results], {"Status", "Seconds"}],
    <|"Status" -> status, "Module" -> "MultiquadraticStripSolve",
      "Method" -> "ResidueOnlyIntegrability",
      "Confirmed" -> (status === "AlphabetIntegrabilityObstruction" &&
        multiquadraticStripScreenEvidenceConfirmedQ[evidence]),
      "Reason" -> Lookup[verdict, "Reason", Missing["NoReason"]],
      (* SAMPLED consistency: a zero-defect image exhibits a solution of
         ITS OWN specialized system.  The positive-defect images beside
         it are recorded as evidence, never acted on; the generic
         statement is left to the full route. *)
      "SampledConsistency" ->
        (status === "AlphabetIntegrabilityConsistent"),
      "ExceptionalRegulatorImages" ->
        If[status === "AlphabetIntegrabilityConsistent",
          Pick[Take[allImages, UpTo[Length[defects]]],
            Map[IntegerQ[#1] && #1 > 0 &, defects]], {}],
      "ImageCount" -> Length[results], "Defects" -> defects,
      "Images" -> allImages,
      "ImageResults" -> results,
      "ConfiguredImageCount" -> configuredCount,
      "FreshImageCount" -> Length[freshResults],
      "FreshImageRequest" -> KeyTake[freshRequest,
        {"Status", "Requested", "Seed", "RejectedValues",
         "RejectedPrimeCount", "UnusableImage", "UnusableImageStatus"}],
      "EvidenceRecord" -> Join[evidence,
        <|"Verdict" -> Lookup[verdict, "Verdict", None]|>],
      "PhaseTimings" -> Merge[
        Lookup[results, "PhaseTimings", <||>], Total],
      "Seconds" -> AbsoluteTime[] - startTime|>]
];
multiquadraticStripIntegrabilityScreenImages[___] :=
  multiquadraticStripFailure["InvalidIntegrabilityScreenArguments"];

(* ------------------------------------------------------------------ *)
(* The FULL-GAUGE per-image screen (2026-08-25)                         *)
(* ------------------------------------------------------------------ *)

(* The integrability screen above projects the gauge OUT: it certifies
   only that the alphabet can carry the residues.  Its consistency is
   necessary, not sufficient -- CF300 (12,9) is consistent there and
   still carries a defect in the full system.  This screen assembles the
   COMPLETE affine gauge system (gauge coefficients AND residues) at one
   (prime, eps) image by point evaluation, with no symbolic compile and
   no channel decomposition, and measures rank / augmented rank / defect
   / nullity plus a verified left witness.  Measured on CF300 (12,9):
   43 s at 1816 unknowns, 98 s at 3128.  The compile it screens is
   ~7900 s, so it is the cheap gate in front of it.

   Row (mu, i, j) at a split point, in the engine's own column order
   (multiquadraticStripColumnOrder: gauge {i,j,grade,monomial}, then
   residues {letter,i,j}):
     Sum_{i'j' grade mon} g[i',j',grade,mon] K + eps Sum_a R[a,i,j] w_a,mu
       = bbar_mu[i,j],
     K = [i'=i,j'=j] dB_mu - eps [j'=j] e_mu[i,i'] B
                            + eps [i'=i] c_mu[j',j] B,
     B = x^p y^q r_grade / Q.
   The rows are taken in the SIGN basis (2^r sign branches per split
   point), which is the invertible Hadamard image of the engine's grade
   rows; rank, defect and nullity are basis-independent, and the witness
   is reported in that same sign-row basis.

   CANDIDATE COLUMNS.  "CandidateOneForms" appends extra residue columns
   that are NOT part of the base system.  The base rank/defect/witness
   are measured on the base columns alone; each candidate is then scored
   against the witness (y . C != 0 is Codex's necessary condition) and
   the defect of an arbitrary SUBSET of candidates is read off the small
   pairing matrix L . [C | b], where L is a basis of the left null space
   of the base matrix.  One assembly therefore answers every subset
   question, which is what makes witness-guided letter discovery
   affordable. *)

Options[multiquadraticStripGaugeAnsatz] = {
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic
};

(* A minimal ansatz descriptor for the screen.  A full preparation
   record already satisfies the screen's contract; this builder exists so
   the screen can be run BEFORE (or without) a preparation, which is the
   whole point of a cheap gate: preparation decomposes the forcing into
   channels and costs ~10^3 s on the blocks this screen is for. *)
multiquadraticStripGaugeAnsatz[record_Association, roots_List,
    oneForms_List, gaugeDenominator_, opts : OptionsPattern[]] := Module[
  {gate, variables, strip, dimensions, degrees, degreeOffset, support},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeAnsatz]]]];
  If[AssociationQ[gate], Return[gate]];
  variables = Lookup[record, "Variables", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  If[TrueQ[Together[gaugeDenominator] === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1,
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  degrees = Exponent[Together[gaugeDenominator], #1] & /@ variables;
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset"]]];
  support = Replace[OptionValue["Support"], Automatic :>
    Flatten[Table[{i, j}, {i, 0, degrees[[1]] + degreeOffset[[1]]},
      {j, 0, degrees[[2]] + degreeOffset[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticStripFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  <|"Status" -> "MultiquadraticGaugeAnsatzV1",
    "Record" -> record, "Variables" -> variables,
    "Regulator" -> Lookup[record, "Regulator", $Failed],
    "Strip" -> strip, "Roots" -> roots, "RootCount" -> Length[roots],
    "OneForms" -> oneForms,
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> degrees,
    "GaugeSupport" -> support, "Dimensions" -> dimensions,
    "GradeCount" -> 2^Length[roots],
    "GaugeUnknownCount" ->
      (Times @@ dimensions) 2^Length[roots] Length[support],
    "ResidueUnknownCount" -> Length[oneForms] (Times @@ dimensions),
    "UnknownCount" -> (Times @@ dimensions) 2^Length[roots] Length[support] +
      Length[oneForms] (Times @@ dimensions)|>
];
multiquadraticStripGaugeAnsatz[___] :=
  multiquadraticStripFailure["InvalidGaugeAnsatzArguments"];

Options[multiquadraticStripGaugeScreen] = {
  "Prime" -> Automatic,
  "RegulatorValue" -> Automatic,
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082501,
  (* A near-square point set can interpolate a false section in a
     high-nullity system.  Eight surplus point blocks leave a real
     held-out row margin while adding much less work than a symbolic
     compile or an incorrectly adopted support rung. *)
  "ExtraRowPoints" -> 8,
  "CandidateOneForms" -> {},
  "CandidateSubsets" -> Automatic,
  "LeftNullSpace" -> Automatic,
  "Deadline" -> Infinity,
  "MaximumUnknowns" -> Automatic,
  "MaximumBytes" -> Automatic,
  (* see the note at multiquadraticStripIntegrabilityScreen *)
  "CompileCacheBytes" -> Automatic
};

(* A large production screen with no candidate columns needs only the
   affine-consistency verdict.  Paying twice for Wolfram MatrixRank and then
   for a full left null space is useful for witness-guided letter discovery,
   but it is pathological for a tens-of-millions-entry gate.  Above this
   threshold reuse the authenticated CFFR1 affine backend already used by the
   real solver.  Small screens and every explicit witness/candidate request
   retain the historical Wolfram route and its left witness. *)
$multiquadraticStripGaugeScreenNativeMinimumEntries = 10000000;

multiquadraticStripGaugeScreen[ansatz_Association, opts : OptionsPattern[]] :=
  Module[
  {gate, record, variables, epsilon, strip, e, c, bbar, roots, oneForms,
   gaugeDenominator, support, dimensions, upper, lower, rank, gradeCount,
   supportCount, letterCount, gaugeUnknownCount, residueUnknownCount,
   unknownCount, candidateForms, candidateCount, candidateWidth, prime,
   regulatorValue, epsilonMod, pointCount, maximumAttempts, randomSeed,
   equationsPerPoint, rootSymbols, compileScalar,
   deltaCompiled, eCompiled, cCompiled, bCompiled, formCompiled,
   candidateCompiled, denominatorCompiled, rationalLeaves, maximumExponents,
   rows = {}, right = {}, candidateRows = {}, accepted = 0, attempts = 0,
   rejected = <||>, point, probeTables, probeInverses, deltaValues, rootValues,
   pointOK, pointRows, pointRight, pointCandidate, values, inverses,
   powerTables, rootDerivatives, evaluate, denominatorPair, denominatorValue,
   denominatorInverse, denominatorLog, ex, ey, cx, cy, bx, by, formValues,
   candidateValues, monomialValues, gradeValues, gradeLog, basisValues,
   basisDerivatives, xInverse, yInverse, rowVector, matrix, candidateMatrix,
   rightVector, rankA, rankAugmented, defect, leftNull, witness, wanted,
   pairing, subsets, subsetResults, candidateScores, screenStatus, seconds,
   startTime = AbsoluteTime[], subsetDefect,
   deadline, maximumUnknowns, maximumBytes, sizeEstimate, refusal,
   phaseTimings = <||>, compileSeconds, assemblySeconds, rankSeconds,
   leftNullSeconds = 0., expired = False, compileStatisticsBefore,
   lettersCompiled = 0, letterIndex, candidateIndex, compileCacheBytes,
   nativeRankQ = False, rankBackend = "Wolfram", rankThreads = 1,
   rankEvidence = <||>, defectEvidence = None},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreen]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline|>]]];
  maximumUnknowns = Replace[OptionValue["MaximumUnknowns"],
    Automatic :> $multiquadraticStripScreenMaximumUnknowns];
  maximumBytes = Replace[OptionValue["MaximumBytes"],
    Automatic :> $multiquadraticStripScreenMaximumBytes];
  compileCacheBytes = Replace[OptionValue["CompileCacheBytes"],
    Automatic :> $multiquadraticStripScreenCompileCacheLimit];
  If[! (NumericQ[compileCacheBytes] && compileCacheBytes > 0),
    Return[multiquadraticStripFailure["InvalidScreenCompileCacheBytes",
      <|"CompileCacheBytes" -> compileCacheBytes|>]]];
  record = Lookup[ansatz, "Record", <||>];
  If[! AssociationQ[record], record = <||>];
  variables = Lookup[ansatz, "Variables", Lookup[record, "Variables", $Failed]];
  epsilon = Lookup[ansatz, "Regulator", Lookup[record, "Regulator", $Failed]];
  strip = Lookup[ansatz, "Strip", Lookup[record, "Strip", $Failed]];
  roots = Lookup[ansatz, "Roots", $Failed];
  oneForms = Lookup[ansatz, "OneForms", $Failed];
  gaugeDenominator = Lookup[ansatz, "GaugeDenominator", $Failed];
  support = Lookup[ansatz, "GaugeSupport", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] || ! ListQ[roots] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}] ||
      ! MatchQ[support, {{_Integer, _Integer} ..}] ||
      gaugeDenominator === $Failed,
    Return[multiquadraticStripFailure["InvalidGaugeAnsatz",
      <|"MissingKeys" -> Select[{"Variables", "Regulator", "Strip", "Roots",
          "OneForms", "GaugeDenominator", "GaugeSupport"},
        ! KeyExistsQ[ansatz, #1] &]|>]]];
  {e, c, bbar} = strip;
  If[! MatchQ[Dimensions[bbar], {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  {upper, lower} = Dimensions[bbar[[1]]];
  rank = Length[roots];
  If[rank > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank"]]];
  gradeCount = 2^rank;
  supportCount = Length[support];
  letterCount = Length[oneForms];
  candidateForms = Replace[OptionValue["CandidateOneForms"], Automatic :> {}];
  If[! MatchQ[candidateForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["InvalidCandidateOneForms"]]];
  candidateCount = Length[candidateForms];
  candidateWidth = upper lower;
  gaugeUnknownCount = upper lower gradeCount supportCount;
  residueUnknownCount = letterCount upper lower;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = 2 upper lower gradeCount;
  prime = Replace[OptionValue["Prime"],
    Automatic :> First[$multiquadraticStripDefaultPrimes]];
  regulatorValue = Replace[OptionValue["RegulatorValue"],
    Automatic :> First[$multiquadraticStripDefaultRegulatorValues]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Ceiling[(unknownCount +
      Max[1, OptionValue["ExtraRowPoints"]] equationsPerPoint)/
      equationsPerPoint]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 60 pointCount + 60];
  randomSeed = OptionValue["RandomSeed"];
  If[! PrimeQ[prime] || ! (3 < prime < 2^31) || Mod[prime, 4] =!= 3 ||
      ! MatchQ[regulatorValue, _Integer | _Rational] ||
      ! IntegerQ[pointCount] || pointCount < 1 || ! IntegerQ[randomSeed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount,
    Return[multiquadraticStripFailure["InvalidGaugeScreenInput",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue,
        "PointCount" -> pointCount|>]]];
  epsilonMod = multiquadraticStripModRational[regulatorValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[multiquadraticStripFailure["InvalidRegulatorImage",
      <|"Prime" -> prime, "RegulatorValue" -> regulatorValue|>]]];
  (* the admission gate, BEFORE any allocation (Codex 04:30 P1).  The
     screen is DEFAULT ON, so its cost must be bounded by a declared
     ceiling rather than by the block that happens to arrive. *)
  sizeEstimate = multiquadraticStripScreenSizeEstimate[
    pointCount equationsPerPoint, unknownCount,
    candidateCount candidateWidth];
  refusal = multiquadraticStripScreenAdmissionRefusal[sizeEstimate,
    maximumUnknowns, maximumBytes, "GaugeScreenNotApplicable"];
  If[AssociationQ[refusal],
    Return[Join[refusal, <|"Prime" -> prime,
      "RegulatorValue" -> regulatorValue,
      "UnknownCount" -> unknownCount,
      "GaugeUnknownCount" -> gaugeUnknownCount,
      "ResidueUnknownCount" -> residueUnknownCount,
      "EquationsPerPoint" -> equationsPerPoint,
      "RequestedPointCount" -> pointCount,
      "Seconds" -> AbsoluteTime[] - startTime|>]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:Compile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate|>]]];
  (* a MARK, not a start: this function has six typed exits (three budget
     stops, two admission refusals, the result) and a "start" that only
     sometimes reaches a "done" is worse than no pair at all *)
  multiquadraticStripStageMark["gauge screen image",
    <|"prime" -> prime, "eps" -> regulatorValue,
      "unknowns" -> unknownCount, "points" -> pointCount,
      "rows" -> sizeEstimate["Rows"],
      "columns" -> sizeEstimate["TotalColumns"],
      "bytes" -> sizeEstimate["PackedBytes"]|>];
  rootSymbols = Table[Unique["multiquadraticRoot$"], {rank}];
  compileScalar[expression_] := multiquadraticStripScreenCompileCached[
    Quiet[Check[Together[expression /. epsilon -> regulatorValue], $Failed,
      {Power::infy, Infinity::indet, Power::indet}]],
    roots, rootSymbols, variables, prime];
  compileStatisticsBefore = $multiquadraticStripScreenCompileStatistics;
  (* INTERIOR BOUNDARIES of the compile phase (2026-08-25, Codex 14:30
     "screen interior boundaries").  Until today the screen read the
     deadline only BEFORE this phase and again after it: a 52-letter
     alphabet on a wide block spends minutes here and an expired budget
     could not stop between two letters.  The boundary is the LETTER
     (and the diagonal/forcing tensor), which is the finest one that
     exists without changing what is compiled -- one letter is one
     Together plus one modular polynomial compile and is not
     interruptible inside. *)
  lettersCompiled = 0;
  compileSeconds = First[AbsoluteTiming[
  Block[{$multiquadraticStripScreenCompileCacheLimit = compileCacheBytes},
  deltaCompiled = multiquadraticStripScreenCompileCached[#1, {}, rootSymbols,
      variables, prime] & /@ Lookup[roots, "RootSquare", {}];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  eCompiled = If[expired, {}, Map[compileScalar, e, {3}]];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  cCompiled = If[expired, {}, Map[compileScalar, c, {3}]];
  If[multiquadraticStripDeadlineExpiredQ[deadline], expired = True];
  bCompiled = If[expired, {}, Map[compileScalar, bbar, {3}]];
  formCompiled = Table[
    If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
      expired = True; {},
      lettersCompiled++; compileScalar /@ oneForms[[letterIndex]]],
    {letterIndex, letterCount}];
  candidateCompiled = Table[
    If[expired || multiquadraticStripDeadlineExpiredQ[deadline],
      expired = True; {},
      compileScalar /@ candidateForms[[candidateIndex]]],
    {candidateIndex, candidateCount}];
  denominatorCompiled = If[expired, $Failed,
    compileScalar[gaugeDenominator]];]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:LetterCompile",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "LettersCompiled" -> lettersCompiled, "LetterCount" -> letterCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  If[! FreeQ[{deltaCompiled, eCompiled, cCompiled, bCompiled, formCompiled,
      candidateCompiled, denominatorCompiled}, $Failed],
    Return[<|"Status" -> "GaugeScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "ScreenCompilationFailed", "Prime" -> prime,
      "RegulatorValue" -> regulatorValue|>]];
  rationalLeaves = Cases[{deltaCompiled, eCompiled, cCompiled, bCompiled,
      formCompiled, candidateCompiled, denominatorCompiled},
    association_Association /; KeyExistsQ[association, "Numerator"] :>
      association, {0, Infinity}];
  maximumExponents = Max /@ Transpose[
    Lookup[rationalLeaves, "MaximumExponents"]];
  maximumExponents[[1]] = Max[maximumExponents[[1]], Max[support[[All, 1]]]];
  maximumExponents[[2]] = Max[maximumExponents[[2]], Max[support[[All, 2]]]];
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PointAssembly",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "PhaseTimings" -> <|"Compile" -> compileSeconds|>|>]]];
  assemblySeconds = First[AbsoluteTiming[
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[accepted < pointCount && attempts < maximumAttempts && ! expired,
      If[multiquadraticStripDeadlineExpiredQ[deadline],
        expired = True; Break[]];
      attempts++;
      point = RandomInteger[{2, prime - 2}, 2];
      probeTables = multiquadraticStripScreenPowerTables[
        Join[point, ConstantArray[1, rank]], maximumExponents, prime];
      probeInverses = Join[PowerMod[point, -1, prime], ConstantArray[1, rank]];
      deltaValues = Table[
        Module[{pair = multiquadraticStripScreenEvaluateRational[
           deltaCompiled[[a]], probeTables, probeInverses, prime]},
         If[pair === $Failed, $Failed, First[pair]]], {a, rank}];
      If[MemberQ[deltaValues, $Failed] || MemberQ[deltaValues, 0] ||
          ! AllTrue[deltaValues, modularResidueQ[#1, prime] &],
        rejected["NotSplitOverPrime"] =
          Lookup[rejected, "NotSplitOverPrime", 0] + 1;
        Continue[]];
      (* one implementation (Core/ModularArithmetic.wl, 2026-09-02): for
         the p == 3 (mod 4) primes this screen admits, and radicands that
         passed the residue test above, this is the former
         PowerMod[delta, (p+1)/4, p] representative with the same square
         check, and the rejection branch stays as unreachable as it was *)
      rootValues = multiquadraticSquareRoots[deltaValues, prime];
      If[rootValues === $Failed,
        rejected["RootImageNotARoot"] =
          Lookup[rejected, "RootImageNotARoot", 0] + 1;
        Continue[]];
      pointOK = True; pointRows = {}; pointRight = {}; pointCandidate = {};
      (* the 2^r sign branches of this point are the invertible image of
         the grade rows: all of them, or none *)
      Do[
        values = Join[point, Table[
          Mod[If[BitGet[signMask, a - 1] === 1, -1, 1] rootValues[[a]], prime],
          {a, rank}]];
        If[MemberQ[values, 0], pointOK = False; Break[]];
        inverses = PowerMod[values, -1, prime];
        powerTables = multiquadraticStripScreenPowerTables[values,
          maximumExponents, prime];
        rootDerivatives = Table[
          Module[{pair = multiquadraticStripScreenEvaluateRational[
             deltaCompiled[[a]], powerTables, inverses, prime], half},
           If[pair === $Failed, ConstantArray[0, 2],
             half = PowerMod[Mod[2 values[[2 + a]], prime], -1, prime];
             Mod[half Last[pair][[1 ;; 2]], prime]]],
          {a, rank}];
        evaluate[compiled_] := Module[{pair},
          pair = multiquadraticStripScreenEvaluateRational[compiled,
            powerTables, inverses, prime];
          If[pair === $Failed, Throw[$Failed, "MultiquadraticGaugeScreenPoint"]];
          {First[pair], Table[Mod[Last[pair][[mu]] +
             Sum[Last[pair][[2 + a]] rootDerivatives[[a, mu]], {a, rank}],
             prime], {mu, 2}]}];
        If[Catch[
            denominatorPair = evaluate[denominatorCompiled];
            ex = Map[First[evaluate[#1]] &, eCompiled[[1]], {2}];
            ey = Map[First[evaluate[#1]] &, eCompiled[[2]], {2}];
            cx = Map[First[evaluate[#1]] &, cCompiled[[1]], {2}];
            cy = Map[First[evaluate[#1]] &, cCompiled[[2]], {2}];
            bx = Map[First[evaluate[#1]] &, bCompiled[[1]], {2}];
            by = Map[First[evaluate[#1]] &, bCompiled[[2]], {2}];
            formValues = Map[First[evaluate[#1]] &, formCompiled, {2}];
            candidateValues = Map[First[evaluate[#1]] &, candidateCompiled, {2}];
            True, "MultiquadraticGaugeScreenPoint"] =!= True,
          pointOK = False; Break[]];
        denominatorValue = First[denominatorPair];
        If[denominatorValue === 0, pointOK = False; Break[]];
        denominatorInverse = PowerMod[denominatorValue, -1, prime];
        denominatorLog = Mod[Last[denominatorPair] denominatorInverse, prime];
        xInverse = inverses[[1]]; yInverse = inverses[[2]];
        monomialValues = Table[
          Mod[powerTables[[1]][[support[[k, 1]] + 1]]
            powerTables[[2]][[support[[k, 2]] + 1]], prime], {k, supportCount}];
        gradeValues = Table[
          Mod[Product[If[BitGet[grade, a - 1] === 1, values[[2 + a]], 1],
            {a, rank}], prime], {grade, 0, gradeCount - 1}];
        (* dlog r_grade = Sum_{a in grade} (dr_a/dmu)/r_a, and
           rootDerivatives[[a]] is dr_a/dmu because r_a^2 = delta_a *)
        gradeLog = Table[
          Mod[Sum[If[BitGet[grade, a - 1] === 1,
            Mod[rootDerivatives[[a, mu]] inverses[[2 + a]], prime], 0],
            {a, rank}], prime],
          {grade, 0, gradeCount - 1}, {mu, 2}];
        basisValues = Flatten[Table[
          Mod[gradeValues[[grade + 1]] monomialValues[[k]] denominatorInverse,
            prime], {grade, 0, gradeCount - 1}, {k, supportCount}]];
        basisDerivatives = Table[Flatten[Table[
          Mod[Mod[gradeValues[[grade + 1]] monomialValues[[k]]
              denominatorInverse, prime]
            Mod[If[mu === 1, support[[k, 1]] xInverse,
                support[[k, 2]] yInverse] +
              gradeLog[[grade + 1, mu]] - denominatorLog[[mu]], prime], prime],
          {grade, 0, gradeCount - 1}, {k, supportCount}]], {mu, 2}];
        Do[
          rowVector = Join[
            Flatten[Table[
              Mod[If[i2 === i && j2 === j, basisDerivatives[[mu]], 0] +
                Mod[If[j2 === j, -epsilonMod If[mu === 1, ex[[i, i2]],
                      ey[[i, i2]]], 0] +
                  If[i2 === i, epsilonMod If[mu === 1, cx[[j2, j]],
                      cy[[j2, j]]], 0], prime] basisValues, prime],
              {i2, upper}, {j2, lower}]],
            Flatten[Table[If[i2 === i && j2 === j,
              Mod[epsilonMod formValues[[k, mu]], prime], 0],
              {k, letterCount}, {i2, upper}, {j2, lower}]]];
          If[Length[rowVector] =!= unknownCount,
            Throw[$Failed, "MultiquadraticGaugeScreenWidth"]];
          AppendTo[pointRows, Developer`ToPackedArray[rowVector]];
          AppendTo[pointRight, If[mu === 1, bx[[i, j]], by[[i, j]]]];
          If[candidateCount > 0,
            AppendTo[pointCandidate, Developer`ToPackedArray[Flatten[Table[
              If[i2 === i && j2 === j,
                Mod[epsilonMod candidateValues[[k, mu]], prime], 0],
              {k, candidateCount}, {i2, upper}, {j2, lower}]]]]],
          {mu, 2}, {i, upper}, {j, lower}],
        {signMask, 0, gradeCount - 1}];
      If[TrueQ[pointOK],
        accepted++;
        rows = Join[rows, pointRows]; right = Join[right, pointRight];
        If[candidateCount > 0, candidateRows = Join[candidateRows, pointCandidate]],
        rejected["Unusable"] = Lookup[rejected, "Unusable", 0] + 1]]]]];
  If[TrueQ[expired],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PointAssembly",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate, "PointCount" -> accepted,
        "RequestedPointCount" -> pointCount, "AttemptCount" -> attempts,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  If[accepted < pointCount,
    Return[<|"Status" -> "GaugeScreenNotApplicable",
      "Module" -> "MultiquadraticStripSolve",
      "Reason" -> "InsufficientAdmissiblePoints",
      "PointCount" -> accepted, "RequestedPointCount" -> pointCount,
      "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
      "Prime" -> prime, "RegulatorValue" -> regulatorValue|>]];
  matrix = Developer`ToPackedArray[Mod[rows, prime]];
  rightVector = Developer`ToPackedArray[Mod[right, prime]];
  candidateMatrix = If[candidateCount > 0,
    Developer`ToPackedArray[Mod[candidateRows, prime]], {}];
  (* the two opaque calls below cannot be interrupted cooperatively, so
     the deadline is checked immediately before each of them *)
  If[multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:Rank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds|>|>]]];
  rankSeconds = First[AbsoluteTiming[
    nativeRankQ = candidateCount === 0 &&
      OptionValue["LeftNullSpace"] =!= True &&
      Times @@ Dimensions[matrix] >=
        $multiquadraticStripGaugeScreenNativeMinimumEntries &&
      StringQ[finiteFieldStripCFFRBinary[]] &&
      FileExistsQ[finiteFieldStripCFFRBinary[]];
    If[nativeRankQ,
      rankThreads = taskBrokerNativeThreadLimit[8];
      rankEvidence = multiquadraticStripAffineConsistencyEvidence[
        matrix, rightVector, prime, gaugeUnknownCount,
        residueUnknownCount, "FLINTAffineRREF", rankThreads, 0];
      Switch[Lookup[rankEvidence, "Status", None],
        "ProviderSupportImageConsistent",
          rankA = rankEvidence["Rank"];
          rankAugmented = rankEvidence["AugmentedRank"];
          defect = 0;
          rankBackend = "FLINTAffineRREF",
        "ProviderSupportImageInconsistent",
          rankA = Lookup[rankEvidence, "Rank",
            Missing["NotComputedForNativeInconsistency"]];
          rankAugmented = Lookup[rankEvidence, "AugmentedRank",
            Missing["NotComputedForNativeInconsistency"]];
          defect = Lookup[rankEvidence, "Defect", 1];
          rankBackend = "FLINTAffineRREF",
        _, nativeRankQ = False]];
    If[! TrueQ[nativeRankQ],
      rankA = MatrixRank[matrix, Modulus -> prime];
      rankAugmented = MatrixRank[MapThread[Append, {matrix, rightVector}],
        Modulus -> prime];
      defect = rankAugmented - rankA;
      rankBackend = "Wolfram"];
    ]];
  If[TrueQ[nativeRankQ],
    defectEvidence = KeyTake[rankEvidence, {"Status", "DefectEvidence",
      "InconsistentVerdict", "PlanDiscoveryBackendRequested",
      "PlanDiscoveryBackendUsed", "PlanDiscoveryBackendThreads"}];
    (* Drop a consistent native solution immediately: its particular/null
       basis has served only to authenticate the rank verdict and must not
       remain live through the later screen bookkeeping. *)
    rankEvidence = <||>];
  wanted = If[TrueQ[nativeRankQ], False,
    Replace[OptionValue["LeftNullSpace"],
      Automatic :> (defect > 0 || candidateCount > 0)]];
  (* POST-RANK BOUNDARY (2026-08-25).  The rank pair is the screen's
     verdict and it is now paid for; what remains -- the left null space
     of the transpose and one MatrixRank per candidate letter -- is a
     second expensive block.  The stop therefore carries the rank and the
     defect it already measured, so a resumed run knows the verdict even
     though the witness was never built.  It fires only when that second
     block would actually run. *)
  If[(TrueQ[wanted] || candidateCount > 0) &&
      multiquadraticStripDeadlineExpiredQ[deadline],
    Return[multiquadraticStripBudgetExhausted["GaugeScreen:PostRank",
      AbsoluteTime[] - startTime, deadline,
      <|"SizeEstimate" -> sizeEstimate,
        "MatrixDimensions" -> Dimensions[matrix],
        "Defect" -> defect, "Rank" -> rankA,
        "AugmentedRank" -> rankAugmented,
        "LeftNullSpaceWanted" -> TrueQ[wanted],
        "CandidateCount" -> candidateCount,
        "PhaseTimings" -> <|"Compile" -> compileSeconds,
          "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds|>|>]]];
  leftNullSeconds = First[AbsoluteTiming[
    leftNull = If[TrueQ[wanted],
      NullSpace[Transpose[matrix], Modulus -> prime], {}];]];
  witness = Missing["Consistent"];
  If[defect > 0,
    witness = If[ListQ[leftNull] && leftNull =!= {},
      SelectFirst[leftNull, Mod[#1 . rightVector, prime] =!= 0 &,
        Missing["NoWitnessFound"]], Missing["LeftNullSpaceNotComputed"]];
    If[! MissingQ[witness],
      witness = <|"Prime" -> prime, "Vector" -> witness,
        "RowBasis" -> "SignBranch",
        "TransposeResidualZero" ->
          AllTrue[Mod[witness . matrix, prime], #1 === 0 &],
        "RightHandSidePairing" -> Mod[witness . rightVector, prime],
        "Support" -> Count[witness, _?(#1 =!= 0 &)]|>]];
  (* subset defects from the small pairing matrix L . [C | b]:
     b is in the column span of [A | C_S] exactly when its pairing
     column lies in the span of the C_S pairing columns *)
  candidateScores = {}; subsetResults = {};
  If[candidateCount > 0 && ListQ[leftNull],
    pairing = If[leftNull === {}, {},
      Mod[leftNull . MapThread[Append, {candidateMatrix, rightVector}], prime]];
    subsetDefect[indices_List] := Module[{columns},
      If[pairing === {}, Return[0]];
      columns = Flatten[
        ((#1 - 1) candidateWidth + Range[candidateWidth]) & /@ indices];
      MatrixRank[pairing[[All, Append[columns, candidateCount candidateWidth + 1]]],
        Modulus -> prime] -
        If[columns === {}, 0,
          MatrixRank[pairing[[All, columns]], Modulus -> prime]]];
    candidateScores = Table[
      Module[{block = (k - 1) candidateWidth + Range[candidateWidth]},
      <|"Index" -> k,
        "WitnessPairing" -> If[AssociationQ[witness],
          Mod[witness["Vector"] . candidateMatrix[[All, block]], prime],
          Missing["NoWitness"]],
        "PiercesWitness" -> If[AssociationQ[witness],
          AnyTrue[Mod[witness["Vector"] . candidateMatrix[[All, block]], prime],
            #1 =!= 0 &], Missing["NoWitness"]],
        (* rank([A | C_k]) - rank(A), read off the pairing matrix.  0
           means the candidate's residue columns lie in the span of the
           system's existing columns: its dlog is a linear combination of
           one-forms the alphabet already has, so it is not a new letter
           at all -- a distinction the witness pairing alone cannot make,
           and the one that separates "no new direction was produced"
           from "new directions were produced and none touches the
           obstruction". *)
        "RankContribution" -> If[pairing === {}, 0,
          MatrixRank[pairing[[All, block]], Modulus -> prime]],
        "Defect" -> subsetDefect[{k}]|>],
      {k, candidateCount}];
    subsets = Replace[OptionValue["CandidateSubsets"], Automatic :>
      If[candidateCount > 1, {Range[candidateCount]}, {}]];
    If[! MatchQ[subsets, {{___Integer} ...}],
      subsets = If[candidateCount > 1, {Range[candidateCount]}, {}]];
    subsetResults = Table[
      <|"Indices" -> subset, "Defect" -> subsetDefect[subset]|>,
      {subset, subsets}]];
  screenStatus = If[defect > 0, "GaugeImageObstruction", "GaugeImageConsistent"];
  seconds = AbsoluteTime[] - startTime;
  phaseTimings = <|"Compile" -> compileSeconds,
    "PointAssembly" -> assemblySeconds, "Rank" -> rankSeconds,
    "LeftNullSpace" -> leftNullSeconds|>;
  <|"Status" -> screenStatus, "Module" -> "MultiquadraticStripSolve",
    "Method" -> "PointEvaluatedAffineGaugeSystem",
    "SizeEstimate" -> sizeEstimate, "PhaseTimings" -> phaseTimings,
    "CompileCache" -> Join[
      AssociationMap[($multiquadraticStripScreenCompileStatistics[#1] -
        compileStatisticsBefore[#1]) &, {"Hits", "Misses", "Evictions"}],
      <|"Bytes" -> $multiquadraticStripScreenCompileCacheBytes|>],
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Defect" -> defect, "Rank" -> rankA, "AugmentedRank" -> rankAugmented,
    "Nullity" -> If[IntegerQ[rankA], unknownCount - rankA,
      Missing["NotComputedForNativeInconsistency"]],
    "LeftNullity" -> If[IntegerQ[rankA], Length[matrix] - rankA,
      Missing["NotComputedForNativeInconsistency"]],
    "MatrixDimensions" -> Dimensions[matrix],
    "UnknownCount" -> unknownCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "LetterCount" -> letterCount, "Prime" -> prime,
    "RegulatorValue" -> regulatorValue, "PointCount" -> accepted,
    "AttemptCount" -> attempts, "RejectedPoints" -> rejected,
    "EquationsPerPoint" -> equationsPerPoint,
    "Witness" -> witness, "DefectEvidence" -> defectEvidence,
    "RankBackend" -> rankBackend, "RankBackendThreads" -> rankThreads,
    "CandidateCount" -> candidateCount,
    "CandidateScores" -> candidateScores,
    "CandidateSubsetResults" -> subsetResults,
    (* the ansatz a defect belongs to: a defect with no ansatz descriptor
       cannot distinguish a missing letter from too small a support *)
    "Ansatz" -> <|"GaugeDenominator" -> Together[gaugeDenominator],
      "GaugeDenominatorDegrees" ->
        (Exponent[Together[gaugeDenominator], #1] & /@ variables),
      "SupportCount" -> supportCount, "GradeCount" -> gradeCount,
      "Dimensions" -> {upper, lower}, "RootCount" -> rank,
      "RootSquares" -> Lookup[roots, "RootSquare", {}],
      "ABIFingerprint" -> Lookup[ansatz, "ABIFingerprint",
        Missing["NoPreparation"]]|>,
    "Seconds" -> seconds|>
];
multiquadraticStripGaugeScreen[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenArguments"];

(* ---- FRESH RANDOM GOOD IMAGES (2026-08-26, round-2 item 3, Codex
   review 1.5) --------------------------------------------------------

   Two FIXED primes do not make modular inconsistency one-sided.  Codex's
   counterexample: with the two configured primes p1, p2 and P = p1 p2,
   the exact scalar equation P g = 1 is solvable over Q (g = 1/P) and
   inconsistent modulo either prime.  Physical input rarely looks like
   that, but the wording has to survive the case that does.

   So the two configured images stay as the CHEAP FIRST PASS -- unchanged
   cost, unchanged behaviour when they disagree -- and a defect that
   survives them is then re-tested at fresh RANDOM good images drawn per
   call.  An image is GOOD when its prime is an admissible screen prime
   (p = 3 mod 4, 3 < p < 2^31) that no earlier image used, and its
   regulator value is one at which the forcing is regular and still
   kinematics-dependent, and at which the ansatz's own gauge denominator
   does not collapse to a constant or to zero -- a singular denominator
   makes the affine system a different system, and its defect would say
   nothing about the ansatz.

   The regulator values are drawn from the same pool the alphabet
   sampler uses, filtered by exactly the acceptance
   multiquadraticStripRegulatorSampleValues applies, so a value this
   generator returns is a value the rest of the engine calls good. *)
multiquadraticStripFreshScreenImages[ansatz_Association, count_Integer,
    seed_Integer, excludePrimes_List, excludeValues_List] := Module[
  {record, variables, epsilon, strip, gaugeDenominator, pool, sampled,
   values, primes, candidate, rejectedPrimes = {}, rejectedValues, attempts,
   denominatorOK},
  If[count <= 0, Return[<|"Status" -> "NoFreshImagesRequested",
    "Images" -> {}, "RejectedPrimes" -> {}, "RejectedValues" -> {}|>]];
  record = Lookup[ansatz, "Record", <||>];
  variables = Lookup[ansatz, "Variables", Lookup[record, "Variables", $Failed]];
  epsilon = Lookup[ansatz, "Regulator", Lookup[record, "Regulator", $Failed]];
  strip = Lookup[ansatz, "Strip", Lookup[record, "Strip", $Failed]];
  gaugeDenominator = Lookup[ansatz, "GaugeDenominator", 1];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidGaugeAnsatzForFreshImages"]]];
  (* the regulator values: the alphabet sampler's own acceptance, plus
     the ansatz-specific denominator test *)
  pool = DeleteCases[
    BlockRandom[RandomSample[$multiquadraticStripRegulatorSamplePool],
      RandomSeeding -> seed],
    Alternatives @@ excludeValues];
  denominatorOK[value_] := Module[{image = Quiet[Check[
      Together[gaugeDenominator /. epsilon -> value], $Failed]]},
    image =!= $Failed && FreeQ[image, DirectedInfinity | Indeterminate] &&
      ! TrueQ[Together[image] === 0]];
  pool = Select[pool, denominatorOK];
  sampled = multiquadraticStripRegulatorSampleValues[strip[[3]], variables,
    epsilon, count, pool];
  values = Lookup[sampled, "Values", {}];
  rejectedValues = Lookup[sampled, "RejectedValues", {}];
  (* the primes: random admissible screen primes below 2^31, none reused *)
  primes = {}; attempts = 0;
  BlockRandom[
    While[Length[primes] < Length[values] && attempts < 4096,
      attempts++;
      candidate = NextPrime[RandomInteger[{2^29, 2^31 - 2^20}]];
      If[Mod[candidate, 4] === 3 && candidate < 2^31 &&
          ! MemberQ[excludePrimes, candidate] && ! MemberQ[primes, candidate],
        AppendTo[primes, candidate],
        AppendTo[rejectedPrimes, candidate]]],
    RandomSeeding -> seed + 104729];
  If[Length[primes] < Length[values], values = Take[values, Length[primes]]];
  <|"Status" -> If[Length[values] >= count, "FreshScreenImages",
      "InsufficientFreshScreenImages"],
    "Images" -> Transpose[{Take[primes, Length[values]], values}],
    "Requested" -> count, "Seed" -> seed,
    "RejectedValues" -> rejectedValues,
    "RejectedPrimeCount" -> Length[rejectedPrimes]|>
];
multiquadraticStripFreshScreenImages[___] :=
  multiquadraticStripFailure["InvalidFreshScreenImageArguments"];

(* Two independent images.  As a PRODUCTION GATE the second image is run
   only when the first reports a defect -- a defect at one image can be a
   bad image, and a consistent image does not gate anything, so it is not
   made more consistent by a second one.  As a DISCOVERY instrument the
   opposite is wanted: "the defect drops to 0" is only accepted at TWO
   images, so "ConfirmConsistency" -> True runs every image regardless.

   A defect that survives BOTH configured images is then re-tested at
   "FreshImageCount" fresh random good images (round-2 item 3): the
   verdict is an obstruction only when every image run -- configured and
   fresh -- carries a defect, and the record carries the total image
   count so a consumer can state the evidence instead of a theorem.
   "FreshImageCount" -> 0 restores the pre-2026-08-26 two-image
   behaviour exactly, which is what the ladder rungs use. *)
Options[multiquadraticStripGaugeScreenImages] = Join[
  Options[multiquadraticStripGaugeScreen], {
  "Images" -> Automatic,
  "ConfirmObstruction" -> True,
  "ConfirmConsistency" -> False,
  "FreshImageCount" -> Automatic,
  "FreshImageSeed" -> Automatic
}];

$multiquadraticStripDefaultFreshImageCount = 3;

multiquadraticStripGaugeScreenImages[ansatz_Association,
    opts : OptionsPattern[]] := Module[
  {gate, images, results = {}, screenOptions, result, defects,
   freshCount, freshSeed, freshRequest, freshImages = {}, freshResults = {},
   configuredCount, imageCount, evidence, verdict, measuringCount},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreenImages]]]];
  If[AssociationQ[gate], Return[gate]];
  images = Replace[OptionValue["Images"], Automatic :>
    Transpose[{$multiquadraticStripDefaultPrimes,
      $multiquadraticStripDefaultRegulatorValues}]];
  If[! MatchQ[images, {{_Integer, _Integer | _Rational} ..}],
    Return[multiquadraticStripFailure["InvalidGaugeScreenImages",
      <|"Images" -> images|>]]];
  (* two identical (prime, regulator) images are one image, never two
     confirmations *)
  images = DeleteDuplicates[images];
  freshCount = Replace[OptionValue["FreshImageCount"],
    Automatic :> $multiquadraticStripDefaultFreshImageCount];
  If[! (IntegerQ[freshCount] && freshCount >= 0),
    Return[multiquadraticStripFailure["InvalidFreshImageCount",
      <|"FreshImageCount" -> freshCount|>]]];
  freshSeed = Replace[OptionValue["FreshImageSeed"],
    Automatic :> OptionValue["RandomSeed"]];
  If[! IntegerQ[freshSeed],
    Return[multiquadraticStripFailure["InvalidFreshImageSeed",
      <|"FreshImageSeed" -> freshSeed|>]]];
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["Prime" -> _] | HoldPattern["RegulatorValue" -> _] |
      HoldPattern["RandomSeed" -> _]],
    Options[multiquadraticStripGaugeScreen]];
  Do[
    result = multiquadraticStripGaugeScreen[ansatz,
      "Prime" -> images[[k, 1]], "RegulatorValue" -> images[[k, 2]],
      "RandomSeed" -> OptionValue["RandomSeed"] + 7919 k,
      Sequence @@ screenOptions];
    AppendTo[results, result];
    If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
        Lookup[result, "Status", None]], Break[]];
    If[Lookup[result, "Defect", 1] === 0,
      If[! TrueQ[OptionValue["ConfirmConsistency"]], Break[]],
      If[! TrueQ[OptionValue["ConfirmObstruction"]], Break[]]],
    {k, Length[images]}];
  configuredCount = Length[results];
  (* ---- the fresh-image confirmation.  Only a CONFIRMED defect at the
     configured images pays for it: a consistent image, an unconfirmed
     one, and every typed stop go straight out as before. *)
  freshRequest = <|"Status" -> "FreshImagesNotRun"|>;
  If[freshCount > 0 && configuredCount >= 2 &&
      AllTrue[results, Lookup[#1, "Status", None] === "GaugeImageObstruction" &] &&
      AllTrue[results, IntegerQ[Lookup[#1, "Defect", None]] &&
        Lookup[#1, "Defect", 0] > 0 &],
    freshRequest = multiquadraticStripFreshScreenImages[ansatz, freshCount,
      freshSeed, images[[All, 1]], images[[All, 2]]];
    freshImages = Lookup[freshRequest, "Images", {}];
    If[! MatchQ[freshImages, {{_Integer, _Integer | _Rational} ...}],
      freshImages = {}];
    Do[
      result = multiquadraticStripGaugeScreen[ansatz,
        "Prime" -> freshImages[[k, 1]], "RegulatorValue" -> freshImages[[k, 2]],
        "RandomSeed" -> freshSeed + 15485863 k,
        Sequence @@ screenOptions];
      (* a fresh image that does not MEASURE -- a budget stop, a ceiling
         refusal -- is recorded and dropped, never folded into the
         verdict: it would otherwise turn a confirmed two-image
         obstruction into "the screen does not apply to this block",
         which is a different statement about a different thing *)
      If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
          Lookup[result, "Status", None]],
        freshRequest = Join[freshRequest,
          <|"UnusableImage" -> freshImages[[k]],
            "UnusableImageStatus" -> Lookup[result, "Status", None]|>];
        Break[]];
      AppendTo[freshResults, result];
      AppendTo[results, result];
      If[Lookup[result, "Defect", 1] === 0, Break[]],
      {k, Length[freshImages]}]];
  defects = Lookup[results, "Defect", Missing["NoDefect"]];
  imageCount = Length[results];
  measuringCount = Count[results, r_ /; MemberQ[{"GaugeImageObstruction",
    "GaugeImageConsistent"}, Lookup[r, "Status", None]]];
  evidence = <|
    "ConfiguredRequired" -> 2,
    "ConfiguredUsable" -> Count[Take[results, UpTo[configuredCount]],
      r_ /; MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent"},
        Lookup[r, "Status", None]]],
    "FreshRequested" -> If[Lookup[freshRequest, "Status", None] ===
        "FreshImagesNotRun", 0, freshCount],
    "FreshGenerated" -> Length[Lookup[freshRequest, "Images", {}]],
    "FreshUsable" -> Length[freshResults],
    "Defects" -> Select[defects, IntegerQ],
    "UnusableStatuses" -> DeleteMissing[
      {Lookup[freshRequest, "UnusableImageStatus", Missing["None"]]}],
    "ConfirmationEnabled" -> TrueQ[OptionValue["ConfirmObstruction"]]|>;
  verdict = multiquadraticStripScreenEvidenceClassify[evidence];
  Join[<|"Status" -> Which[
      measuringCount < imageCount,
        (* a budget stop is a RESUMABLE stop, not "the screen does not
           apply to this block": the two must not be conflated *)
        If[AnyTrue[results, Lookup[#1, "Status", None] === "BudgetExhausted" &],
          "BudgetExhausted", "GaugeScreenNotApplicable"],
      Lookup[verdict, "Verdict", None] === "SampledConsistent" &&
          TrueQ[Lookup[verdict, "AllZero", False]],
        If[Length[results] >= 2 || ! TrueQ[OptionValue["ConfirmConsistency"]],
          "GaugeImageConsistent", "GaugeImageConsistentUnconfirmed"],
      Lookup[verdict, "Verdict", None] === "SampledConsistent",
        (* a zero defect beside positive ones: sampled consistency.  The
           full route continues; this is NOT "consistent over the
           generic field" and NOT an obstruction (round-3 A1) *)
        "GaugeScreenInconclusive",
      Lookup[verdict, "Verdict", None] === "ConfirmedObstruction",
        "GaugeImageObstruction",
      Lookup[verdict, "Verdict", None] === "Unconfirmed",
        "GaugeImageObstructionUnconfirmed",
      True, "GaugeScreenInconclusive"],
    "Reason" -> Lookup[verdict, "Reason", Missing["NoReason"]],
    "Module" -> "MultiquadraticStripSolve",
    "Method" -> "PointEvaluatedAffineGaugeSystem",
    "ImageCount" -> imageCount, "Defects" -> defects,
    "Images" -> Join[Take[images, UpTo[configuredCount]],
      Take[freshImages, UpTo[imageCount - configuredCount]]],
    "ImageResults" -> results,
    (* the evidence a consumer must quote instead of a theorem; the
       DRIVER rechecks the confirmation predicate on this record before
       any negative contract *)
    "EvidenceRecord" -> Join[evidence,
      <|"Verdict" -> Lookup[verdict, "Verdict", None]|>],
    "ConfiguredImageCount" -> configuredCount,
    "FreshImageCount" -> Length[freshResults],
    "FreshImageRequest" -> KeyTake[freshRequest,
      {"Status", "Requested", "Seed", "RejectedValues", "RejectedPrimeCount",
       "UnusableImage", "UnusableImageStatus"}],
    "FreshImages" -> Take[freshImages, UpTo[Length[freshResults]]],
    "FreshDefects" -> (Lookup[#1, "Defect", Missing["NoDefect"]] & /@
      freshResults),
    "SizeEstimate" -> Lookup[Last[results], "SizeEstimate",
      Missing["NoSizeEstimate"]],
    "PhaseTimings" -> Merge[Lookup[results, "PhaseTimings", <||>], Total],
    "Stage" -> Lookup[Last[results], "Stage", Missing["NoStage"]],
    "MatrixDimensions" -> Lookup[Last[results], "MatrixDimensions",
      Missing["NoMatrix"]],
    "AnsatzFingerprint" -> Lookup[ansatz, "ABIFingerprint",
      Missing["NoPreparation"]],
    "Seconds" -> Total[Lookup[results, "Seconds", 0]]|>,
    (* the ansatz a defect belongs to: without it a defect cannot
       distinguish a missing letter from too small a support *)
    <|"Ansatz" -> Lookup[Last[results], "Ansatz", Missing["NoAnsatz"]]|>]
];
multiquadraticStripGaugeScreenImages[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenArguments"];

(* ------------------------------------------------------------------ *)
(* Screen-validated DEGREE-OFFSET LADDER (2026-08-25)                   *)
(* ------------------------------------------------------------------ *)

(* CF300 (12,9) needs a gauge NUMERATOR three degrees above its
   denominator ("DegreeOffset" -> {3,3}); at the default {0,0} the screen
   above correctly refuses the ansatz, and no caller can be expected to
   know that number per block in an unattended campaign.  So the offset
   is MEASURED: when the screen at the configured offset reports a
   CONFIRMED defect, the SCREEN ONLY -- never the compile -- is re-run at
   escalating offsets, and the first one that is consistent at TWO images
   is adopted for the real solve.  A rung costs one screen per image
   (measured 50-90 s on that block) against a compile measured at
   ~7900 s, so the whole ladder is cheap by construction.

   The escalation is a search over ANSATZ SIZE, not over the alphabet: a
   rung that reaches defect 0 says the missing direction was a gauge pole
   at infinity, and a ladder that exhausts leaves the alphabet verdict of
   the base screen standing untouched. *)

$multiquadraticStripDefaultDegreeOffsetLadder = {{1, 1}, {2, 2}, {3, 3},
  {4, 4}};

(* FACET_MQ_DEGREE_LADDER = "1,1;2,2;3,3", parsed defensively in the style
   of FACET_BROKER_MINIMUM_SECONDS: anything that is not a nonempty list
   of pairs of nonnegative integers falls back to the default rather than
   erroring or half-parsing.  An environment typo must never silently
   change the ansatz an overnight campaign compiles. *)
multiquadraticStripDegreeOffsetLadderParse[text_, fallback_] := Module[
  {trimmed, rungs},
  trimmed = If[StringQ[text], StringTrim[text], ""];
  If[trimmed === "", Return[fallback]];
  If[! StringMatchQ[trimmed, RegularExpression[
      "[0-9]+ *, *[0-9]+( *; *[0-9]+ *, *[0-9]+)*"]],
    Return[fallback]];
  rungs = Quiet[Check[
    Map[ToExpression[StringTrim[#1]] &,
      StringSplit[StringSplit[trimmed, ";"], ","], {2}], $Failed]];
  If[MatchQ[rungs, {{_Integer, _Integer} ..}] &&
      AllTrue[Flatten[rungs], IntegerQ[#1] && #1 >= 0 &],
    rungs, fallback]];

multiquadraticStripDegreeOffsetLadder[] :=
  multiquadraticStripDegreeOffsetLadderParse[
    Environment["FACET_MQ_DEGREE_LADDER"],
    $multiquadraticStripDefaultDegreeOffsetLadder];

(* The source may be a full preparation record or the cheap ansatz
   descriptor: the ladder reads only the four fields it needs to rebuild
   an ansatz at another offset, and both carry them. *)
Options[multiquadraticStripGaugeScreenLadder] = Join[
  DeleteCases[Options[multiquadraticStripGaugeScreenImages],
    HoldPattern["ConfirmConsistency" -> _]], {
  "DegreeOffsetLadder" -> Automatic,
  "BaseDegreeOffset" -> {0, 0},
  "Deadline" -> Infinity,
  "Verbose" -> False
}];

multiquadraticStripGaugeScreenLadder[source_Association,
    opts : OptionsPattern[]] := Module[
  {gate, record, roots, oneForms, gaugeDenominator, ladder, baseOffset,
   deadline, verbose, log, screenOptions, rungs = {}, skipped = {},
   ansatz, result, imageResults, adopted = None,
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripGaugeScreenLadder]]]];
  If[AssociationQ[gate], Return[gate]];
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  record = Lookup[source, "Record", $Failed];
  roots = Lookup[source, "Roots", $Failed];
  oneForms = Lookup[source, "OneForms", $Failed];
  gaugeDenominator = Lookup[source, "GaugeDenominator", $Failed];
  If[! AssociationQ[record] || ! ListQ[roots] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}] || gaugeDenominator === $Failed,
    Return[multiquadraticStripFailure["InvalidGaugeAnsatz",
      <|"MissingKeys" -> Select[{"Record", "Roots", "OneForms",
          "GaugeDenominator"}, ! KeyExistsQ[source, #1] &]|>]]];
  baseOffset = OptionValue["BaseDegreeOffset"];
  If[! MatchQ[baseOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset",
      <|"BaseDegreeOffset" -> baseOffset|>]]];
  ladder = Replace[OptionValue["DegreeOffsetLadder"],
    Automatic :> multiquadraticStripDegreeOffsetLadder[]];
  If[! MatchQ[ladder, {} | {{_Integer, _Integer} ..}] ||
      ! AllTrue[Flatten[ladder], IntegerQ[#1] && #1 >= 0 &],
    Return[multiquadraticStripFailure["InvalidDegreeOffsetLadder",
      <|"DegreeOffsetLadder" -> ladder|>]]];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print["[multiquadratic] ", items]];
  (* every rung is a DISCOVERY measurement, so defect 0 is accepted only
     at two images: "ConfirmConsistency" is the ladder's, not the
     caller's *)
  screenOptions = FilterRules[
    DeleteCases[Flatten[{opts}],
      HoldPattern["DegreeOffsetLadder" -> _] |
      HoldPattern["DegreeOffsetLadder" :> _] |
      HoldPattern["BaseDegreeOffset" -> _] |
      HoldPattern["BaseDegreeOffset" :> _] |
      HoldPattern["Deadline" -> _] | HoldPattern["Deadline" :> _] |
      HoldPattern["Verbose" -> _] | HoldPattern["Verbose" :> _]],
    Options[multiquadraticStripGaugeScreenImages]];
  Do[
    (* a rung no larger than the offset that already failed cannot repair
       anything: it is recorded as skipped, not measured *)
    If[offset[[1]] <= baseOffset[[1]] && offset[[2]] <= baseOffset[[2]],
      AppendTo[skipped, offset]; Continue[]];
    (* the deadline is read at every rung boundary: a rung is this
       ladder's unit of work *)
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      Return[multiquadraticStripBudgetExhausted["GaugeScreenLadder",
        AbsoluteTime[] - startTime, deadline,
        <|"Method" -> "ScreenValidatedDegreeOffsetLadder",
          "BaseDegreeOffset" -> baseOffset,
          "DegreeOffsetLadder" -> ladder,
          "NextDegreeOffset" -> offset,
          "SkippedDegreeOffsets" -> skipped,
          "LadderRungs" -> rungs,
          "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@
            rungs)|>], Module]];
    ansatz = multiquadraticStripGaugeAnsatz[record, roots, oneForms,
      gaugeDenominator, "DegreeOffset" -> offset];
    If[Lookup[ansatz, "Status", None] =!= "MultiquadraticGaugeAnsatzV1",
      Return[ansatz, Module]];
    (* the rung's own screen is bounded by the same deadline: checking
       only BETWEEN rungs left one dense rank/nullspace call able to
       overrun the whole budget on its own (Codex 04:30 P1) *)
    (* "FreshImageCount" -> 0 unless the caller asked otherwise: a rung
       is a search over ANSATZ SIZE, and what it needs from an obstructed
       rung is only "keep climbing".  The fresh-image confirmation
       (round-2 item 3) is what makes the FINAL verdict quotable, and the
       driver runs it once on the base screen, not once per rung -- three
       extra screens per rung at 50-90 s each would be pure cost. *)
    result = multiquadraticStripGaugeScreenImages[ansatz,
      "ConfirmConsistency" -> True, "Deadline" -> deadline,
      "FreshImageCount" -> Replace[OptionValue["FreshImageCount"],
        Automatic :> 0],
      Sequence @@ FilterRules[screenOptions,
        Except[HoldPattern["FreshImageCount" -> _]]]];
    If[Lookup[result, "Status", None] === "BudgetExhausted",
      (* the LADDER is the unit a caller resumes, so the stop keeps the
         ladder's stage name; the screen phase that actually ran out of
         time is carried beside it as diagnostics *)
      Return[Join[result, <|"Method" -> "ScreenValidatedDegreeOffsetLadder",
        "Stage" -> "GaugeScreenLadder",
        "ScreenStage" -> Lookup[result, "Stage", Missing["NoScreenStage"]],
        "BaseDegreeOffset" -> baseOffset, "DegreeOffsetLadder" -> ladder,
        "NextDegreeOffset" -> offset, "SkippedDegreeOffsets" -> skipped,
        "LadderRungs" -> rungs,
        "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@
          rungs)|>], Module]];
    imageResults = Lookup[result, "ImageResults", {}];
    AppendTo[rungs, <|"DegreeOffset" -> offset,
      "SupportCount" -> Length[ansatz["GaugeSupport"]],
      "UnknownCount" -> ansatz["UnknownCount"],
      "Status" -> Lookup[result, "Status", None],
      "ImageCount" -> Lookup[result, "ImageCount", 0],
      "Images" -> Lookup[result, "Images", {}],
      "Defects" -> Lookup[result, "Defects", Missing["NoDefect"]],
      "Ranks" -> Lookup[imageResults, "Rank", {}],
      "AugmentedRanks" -> Lookup[imageResults, "AugmentedRank", {}],
      "Nullities" -> Lookup[imageResults, "Nullity", {}],
      "MatrixDimensions" -> Lookup[imageResults, "MatrixDimensions", {}],
      "Seconds" -> Lookup[result, "Seconds", 0]|>];
    log["gauge screen ladder: DegreeOffset ", offset, ", support ",
      Length[ansatz["GaugeSupport"]], ", ", ansatz["UnknownCount"],
      " unknowns -> ", Lookup[result, "Status", None], ", defects ",
      Lookup[result, "Defects", None], ", ",
      Round[Lookup[result, "Seconds", 0], 0.1], " s"];
    If[! MemberQ[{"GaugeImageObstruction", "GaugeImageConsistent",
        "GaugeImageObstructionUnconfirmed",
        "GaugeImageConsistentUnconfirmed"}, Lookup[result, "Status", None]],
      Return[multiquadraticStripFailure["GaugeScreenLadderNotApplicable",
        <|"DegreeOffset" -> offset,
          "ScreenStatus" -> Lookup[result, "Status", None],
          "LadderRungs" -> rungs, "ScreenResult" -> result|>], Module]];
    If[Lookup[result, "Status", None] === "GaugeImageConsistent",
      adopted = offset; Break[]],
    {offset, ladder}];
  <|"Status" -> If[adopted === None, "GaugeScreenLadderExhausted",
      "GaugeScreenLadderAdopted"],
    "Module" -> "MultiquadraticStripSolve",
    "Method" -> "ScreenValidatedDegreeOffsetLadder",
    "AdoptedDegreeOffset" -> If[adopted === None,
      Missing["GaugeScreenLadderExhausted"], adopted],
    "BaseDegreeOffset" -> baseOffset,
    "DegreeOffsetLadder" -> ladder,
    "SkippedDegreeOffsets" -> skipped,
    "RungCount" -> Length[rungs],
    "LadderDefects" -> ({#1["DegreeOffset"], #1["Defects"]} & /@ rungs),
    "LadderRungs" -> rungs,
    "Seconds" -> AbsoluteTime[] - startTime|>
];
multiquadraticStripGaugeScreenLadder[___] :=
  multiquadraticStripFailure["InvalidGaugeScreenLadderArguments"];

End[];
