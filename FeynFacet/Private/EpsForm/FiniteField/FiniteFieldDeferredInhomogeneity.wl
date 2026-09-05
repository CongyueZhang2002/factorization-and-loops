(* FeynFacet/Private/EpsForm/FiniteField/FiniteFieldDeferredInhomogeneity.wl
   (round 8, pass 3, 2026-09-02): the finite-field off-diagonal block equation sampler fed from the
   deferred block-equation DAG WITHOUT materializing it in characteristic
   zero.

   On the chart route a off-diagonal block equation whose inhomogeneity is a deferred preparation used to
   be pulled back exactly before the inner solve (materialization of every
   operand, then the Jacobian normalization: 53 + 60 s on one measured
   block, 1477 s of materialization alone on a larger block), only for the sampler
   to reduce the result modulo primes at random points.  Here the sampler
   gets the residue images directly: the chart point is mapped to the source
   frame modulo p, the declared roots take their rational chart images
   modulo p, the native evaluator flint_deferred_ast_eval (the same adapter
   the chartless engine uses) evaluates the DAG at every point in one call,
   the grade channels are contracted with the root values and the chain
   rule is applied modulo p.  Exactness: on two measured production blocks the
   images agree SameQ with the exact pull-back at every sample point
   (2026-09-02).

   The three census items the sampler used to read off the materialized
   inhomogeneity (the regulator-free irreducible denominator factors, the basis-transformation block
   denominator Prod f^(k-1) over factors of pole order k > 1, the inhomogeneity's
   degree at infinity) are recovered modulo p as well: the candidate factors
   are the irreducible factors of the operand denominators and of the chart
   map pulled back into the chart (a structural superset), and every entry's
   true denominator is interpolated along two random lines in the chart with
   one nullspace at the structural degree bound, reduced by the gcd and
   validated on held-out points; the multiplicity of each candidate is read
   off by exact division of the line denominator.  Two lines must agree.
   The exact census counts a sign variant of the same irreducible factor
   twice (measured production output:
   basis-transformation block denominator degrees {14, 11} where the true ones are {12, 10}); this
   census does not, so the ansatz is the minimal one and a solution is
   compared with the exact route's as a rational function, not as a vector.

   Nothing here is an acceptance step.  The unseen-prime residual of the
   sampler, the modular residual below (the numerical verifier's identity
   with the DAG image in place of the placeholder inhomogeneity) and the family
   certificate are the checks; exact materialization is left to the family
   certificate.  Plan and census refusals fall back to the exact pull-back
   before the solve; a runtime failure after the deferred route is selected
   is returned typed instead of silently repeating the expensive exact path. *)

Begin["FeynFacet`Private`"];

ClearAll[
  $finiteFieldDeferredInhomogeneityRegistry,
  $finiteFieldDeferredInhomogeneityImageCache,
  $finiteFieldDeferredInhomogeneityBatchLimit,
  $finiteFieldDeferredInhomogeneityTypedFailures,
  $finiteFieldDeferredInhomogeneityLastFailure,
  finiteFieldDeferredInhomogeneityRouteQ,
  finiteFieldDeferredInhomogeneityModAt,
  finiteFieldDeferredInhomogeneityPlan,
  finiteFieldDeferredInhomogeneityHandle,
  finiteFieldDeferredInhomogeneityEnsurePlan,
  finiteFieldDeferredInhomogeneityTable,
  finiteFieldDeferredInhomogeneityTables,
  finiteFieldDeferredInhomogeneityPowers,
  finiteFieldDeferredInhomogeneityPolynomialAt,
  finiteFieldDeferredInhomogeneityRationalValues,
  finiteFieldDeferredInhomogeneityRationalAt,
  finiteFieldDeferredInhomogeneityDenominatorBases,
  finiteFieldDeferredInhomogeneityRegulatorPoleFactors,
  finiteFieldDeferredInhomogeneityRegulatorPoleQ,
  finiteFieldDeferredInhomogeneityPointData,
  finiteFieldDeferredInhomogeneitySelectSplitImages,
  finiteFieldDeferredInhomogeneityPreflights,
  finiteFieldDeferredInhomogeneityPreflightsReference,
  finiteFieldDeferredInhomogeneityImages,
  finiteFieldDeferredInhomogeneityLineFit,
  finiteFieldDeferredInhomogeneityPolynomialRoot,
  finiteFieldDeferredInhomogeneityReduceRadicals,
  finiteFieldDeferredInhomogeneityRadicalVariants,
  finiteFieldDeferredInhomogeneityRelativeNorm,
  finiteFieldDeferredInhomogeneityCandidateFactors,
  finiteFieldDeferredInhomogeneityCensus,
  finiteFieldDeferredInhomogeneityDerivativeRules,
  finiteFieldDeferredInhomogeneityRuntimeFailure,
  finiteFieldDeferredInhomogeneityRuntimeFailureQ,
  finiteFieldDeferredInhomogeneityLocalRetryQ,
  finiteFieldDeferredInhomogeneityResidualQ,
  finiteFieldDeferredInhomogeneityCoefficientResidualQ
];

$finiteFieldDeferredInhomogeneityRegistry = <||>;
(* images already evaluated, keyed by {plan key, prime, x, y, epsMod}: the
   regulator samples of a prime share their points, so a wave of samples is
   one native batch (finiteFieldOffDiagonalBlockSolve pre-warms it) and every
   per-sample request is served from here *)
$finiteFieldDeferredInhomogeneityImageCache = <||>;
(* images per native request: flint_deferred_ast_eval.c caps a request at
   MAX_TOTAL_IMAGES = 4096 channels, i.e. Floor[4096/gradeCount] images
   (ResourceLimit, exit 5); the chunk is the smaller of this and that cap *)
$finiteFieldDeferredInhomogeneityBatchLimit = 1024;

(* Runtime failures are data, not a diagnostic side channel.  Only an absent
   helper-local plan is worth one retry on the solving kernel; arithmetic,
   native-adapter and mathematical failures must propagate unchanged. *)
finiteFieldDeferredInhomogeneityRuntimeFailure[reason_String, detail_: None] :=
  <|"Status" -> "DeferredInhomogeneityRuntimeFailure", "Reason" -> reason,
    "Detail" -> detail|>;
finiteFieldDeferredInhomogeneityRuntimeFailureQ[result_] :=
  AssociationQ[result] &&
    Lookup[result, "Status", None] === "DeferredInhomogeneityRuntimeFailure";
finiteFieldDeferredInhomogeneityLocalRetryQ[result_] :=
  finiteFieldDeferredInhomogeneityRuntimeFailureQ[result] &&
    Lookup[result, "Reason", None] === "DeferredInhomogeneityPlanUnknown";

(* FACET_DEFERRED_INHOMOGENEITY=Off restores the exact pull-back before the inner
   solve (the pre-2026-09-02 route); anything else keeps the DAG route *)
finiteFieldDeferredInhomogeneityRouteQ[] :=
  Environment["FACET_DEFERRED_INHOMOGENEITY"] =!= "Off";

finiteFieldDeferredInhomogeneityModAt[expression_, values_Association, prime_Integer] :=
  With[{r = blockEquationDeferredModEvaluate[expression, values, {}, prime]},
    If[AssociationQ[r] && r["Status"] === "OK", r["Value"], $Failed]];

(* Structural denominator bases of the deferred arithmetic DAG.  Operands
   and term coefficients both contribute; no target entry is assembled. *)
finiteFieldDeferredInhomogeneityDenominatorBases[
    preparation_Association] := Module[{records, operands, basesOf},
  records = Lookup[preparation, "Records", {}];
  operands = DeleteDuplicates[Flatten[{
      Lookup[#, "Operands", {}], Lookup[#, "Coefficient", 1]} & /@
    Flatten[Lookup[records, "Terms", {}]]]];
  basesOf[expr_] := Module[{den = Denominator[expr], list},
    list = If[Head[den] === Times, List @@ den, {den}];
    Select[Join[
      Replace[list, Power[base_, _Integer] :> base, {1}],
      Cases[expr, Power[base_, exponent_?Negative] :> base,
        {0, Infinity}]], ! NumericQ[#] &]
  ];
  DeleteDuplicates[Flatten[basesOf /@ operands]]
];
finiteFieldDeferredInhomogeneityDenominatorBases[___] := $Failed;

(* Exact regulator-only poles are unusable epsilon samples, not failures of
   the multiquadratic evaluator.  Keeping their irreducible factors in the
   plan lets every sampler skip them before a native batch is formed. *)
finiteFieldDeferredInhomogeneityRegulatorPoleFactors[
    preparation_Association, variables_List, epsilon_Symbol] := Module[
  {bases, pure, factors},
  bases = finiteFieldDeferredInhomogeneityDenominatorBases[preparation];
  If[bases === $Failed, Return[$Failed]];
  pure = Select[bases,
    ! FreeQ[#, epsilon] && FreeQ[#, Alternatives @@ variables] &&
      PolynomialQ[#, epsilon] &];
  factors = Flatten[(First /@ Rest[FactorList[#]]) & /@ pure];
  DeleteDuplicates[Select[factors, ! FreeQ[#, epsilon] &]]
];
finiteFieldDeferredInhomogeneityRegulatorPoleFactors[___] := $Failed;

finiteFieldDeferredInhomogeneityRegulatorPoleQ[key_String,
    prime_Integer, epsilonMod_Integer] := Module[{plan, factors, epsilon},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[False]];
  factors = Lookup[plan, "RegulatorPoleFactors", {}];
  epsilon = plan["Regulator"];
  AnyTrue[factors,
    finiteFieldDeferredInhomogeneityModAt[#,
      <|epsilon -> epsilonMod|>, prime] === 0 &]
];
finiteFieldDeferredInhomogeneityRegulatorPoleQ[___] := False;

(* The plan binds everything the images need: the preparation and its file
   (the adapter parses the file itself), the chart substitution, the
   Jacobian, and the roots with their rational images.  The registry uses an
   ephemeral identifier only to route calls within a run; it is not evidence
   and is never used to decide mathematical compatibility. *)
finiteFieldDeferredInhomogeneityPlan[deferredPreparation_Association,
    inputFile_String, data_Association, usedRoots_List, rootImages_List,
    chartVariables : {_Symbol, _Symbol}, variables : {_Symbol, _Symbol},
  epsilon_Symbol, dimensions : {_Integer, _Integer}] := Module[
  {preparation, sourceVariableSubstitution, differentialPullbackMatrix,
   coefficientPresentation, allRoots, rationalizedRootIndices,
   unrationalizedRootIndices, projectionRootIndices, coefficientData, key,
   plan, rootSignature, allRootSignatures, usedRootSignatures,
   derivedRootPositions, declaredRootIndices, normalizeRoot,
   normalizedUsedRoots, regulatorPoleFactors},
  preparation = Lookup[deferredPreparation, "Preparation",
    Lookup[deferredPreparation, "DeferredPreparation", $Failed]];
  sourceVariableSubstitution = Lookup[data,
    "SourceVariableSubstitution", $Failed];
  differentialPullbackMatrix = Lookup[data,
    "DifferentialPullbackMatrix", $Failed];
  coefficientPresentation = Lookup[deferredPreparation,
    "CoefficientPresentation", <||>];
  allRoots = Lookup[coefficientPresentation, "SquareRootGenerators",
    If[usedRoots === {}, {}, $Failed]];
  If[! MatchQ[allRoots, {___Association}] ||
      Length[allRoots] >
        $multiquadraticOffDiagonalBlockMaximumRootCount,
    Return[<|"Status" -> "DeferredInhomogeneityPlanInvalid"|>]];
  normalizeRoot[root_Association] := <|
    "Generator" -> squareRootRecordExpression[root],
    "QuadraticRadicand" -> squareRootRecordRadicand[root],
    "SourceRadicand" -> Lookup[root, "SourceRadicand",
      squareRootRecordRadicand[root]]|>;
  allRoots = normalizeRoot /@ allRoots;
  normalizedUsedRoots = normalizeRoot /@ usedRoots;
  rootSignature[root_Association] := {
    squareRootRecordExpression[root],
    Together[squareRootRecordRadicand[root]],
    Together[Lookup[root, "SourceRadicand",
      squareRootRecordRadicand[root]]]
  };
  allRootSignatures = rootSignature /@ allRoots;
  usedRootSignatures = rootSignature /@ normalizedUsedRoots;
  derivedRootPositions = FirstPosition[allRootSignatures, #,
      None, {1}] & /@ usedRootSignatures;
  If[MemberQ[derivedRootPositions, None],
    Return[<|"Status" -> "DeferredInhomogeneityPlanInvalid"|>]];
  derivedRootPositions = First /@ derivedRootPositions;
  declaredRootIndices = Lookup[deferredPreparation,
    "SquareRootGeneratorIndices", derivedRootPositions];
  rationalizedRootIndices = declaredRootIndices;
  If[! VectorQ[rationalizedRootIndices, IntegerQ] ||
      ! DuplicateFreeQ[rationalizedRootIndices] ||
      rationalizedRootIndices =!= derivedRootPositions,
    Return[<|"Status" -> "DeferredInhomogeneityPlanInvalid"|>]];
  unrationalizedRootIndices = Complement[Range[Length[allRoots]],
    rationalizedRootIndices];
  projectionRootIndices = Lookup[deferredPreparation,
    "ProjectionSquareRootGeneratorIndices",
    If[unrationalizedRootIndices === {}, {}, $Failed]];
  If[! AssociationQ[preparation] ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      ! FileExistsQ[inputFile] ||
      ! MatchQ[sourceVariableSubstitution, {_Rule, _Rule}] ||
      ! MatchQ[differentialPullbackMatrix, {{_, _}, {_, _}}] ||
      ! VectorQ[rationalizedRootIndices, IntegerQ] ||
      ! DuplicateFreeQ[rationalizedRootIndices] ||
      ! AllTrue[rationalizedRootIndices,
        Between[#1, {1, Length[allRoots]}] &] ||
      ! VectorQ[projectionRootIndices, IntegerQ] ||
      projectionRootIndices =!=
        Sort[DeleteDuplicates[projectionRootIndices]] ||
      ! ContainsOnly[projectionRootIndices, unrationalizedRootIndices] ||
      Length[usedRoots] =!= Length[rootImages] ||
      Length[rationalizedRootIndices] =!= Length[usedRoots] ||
      multiquadraticOffDiagonalBlockNativeDeferredBinary[] === None,
    Return[<|"Status" -> "DeferredInhomogeneityPlanInvalid"|>]];
  regulatorPoleFactors = If[
    KeyExistsQ[deferredPreparation, "RegulatorPoleFactors"],
    deferredPreparation["RegulatorPoleFactors"],
    finiteFieldDeferredInhomogeneityRegulatorPoleFactors[
      preparation, variables, epsilon]];
  If[regulatorPoleFactors === $Failed ||
      ! ListQ[regulatorPoleFactors] ||
      ! AllTrue[regulatorPoleFactors,
        PolynomialQ[#, epsilon] &&
          FreeQ[#, Alternatives @@ variables] &],
    Return[<|"Status" -> "DeferredInhomogeneityPlanInvalid"|>]];
  key = CreateUUID["deferred-inhomogeneity-"];
  coefficientData = <|
    "DataType" -> "DeferredInhomogeneityCoefficientData",
    "SchemaVersion" -> 1, "Variables" -> variables,
    "Regulator" -> epsilon, "Roots" -> allRoots,
    "Dimensions" -> dimensions|>;
  plan = <|"Status" -> "OK", "Key" -> key,
    "InputFile" -> inputFile,
    "Tables" -> finiteFieldDeferredInhomogeneityTables[data, rootImages, allRoots,
      chartVariables, variables, epsilon],
    "Preparation" -> preparation,
    "Variables" -> variables, "ChartVariables" -> chartVariables,
    "Regulator" -> epsilon, "Dimensions" -> dimensions,
    "SourceVariableSubstitution" -> sourceVariableSubstitution,
    "DifferentialPullbackMatrix" -> differentialPullbackMatrix,
    "Roots" -> allRoots,
    "RationalizedRootIndices" -> rationalizedRootIndices,
    "UnrationalizedRootIndices" -> unrationalizedRootIndices,
    "ProjectionSquareRootGeneratorIndices" -> projectionRootIndices,
    "RootImages" -> rootImages,
    "RegulatorPoleFactors" -> regulatorPoleFactors,
    "Provider" -> <|"Variables" -> variables, "Regulator" -> epsilon,
      "Roots" -> allRoots, "RootCount" -> Length[allRoots],
      "GradeCount" -> 2^Length[allRoots], "Dimensions" -> dimensions,
      "DeferredPreparation" -> preparation,
      "DeferredPreparationFile" -> inputFile,
      "CoefficientData" -> coefficientData,
      "ProviderID" -> key|>|>;
  $finiteFieldDeferredInhomogeneityRegistry[key] = plan;
  plan
];
finiteFieldDeferredInhomogeneityPlan[___] := <|"Status" -> "DeferredInhomogeneityPlanInvalid"|>;

(* A helper kernel has an empty registry.  The descriptor therefore carries
   a small serializable handle from which the helper rebuilds the same
   mathematical plan.  The rebuilt plan is "slim": it has the
   preparation's validation fields but not its records, so it serves images
   and residual checks, never a census. *)
finiteFieldDeferredInhomogeneityHandle[plan_Association] := <|
  "InputFile" -> plan["InputFile"],
  "Preparation" -> KeyTake[plan["Preparation"],
    {"DataType", "SchemaVersion", "Status", "Variables", "Regulator",
      "Dimensions", "TargetOrder"}],
  "SourceVariableSubstitution" -> plan["SourceVariableSubstitution"],
  "DifferentialPullbackMatrix" -> plan["DifferentialPullbackMatrix"],
  "Roots" -> (KeyTake[#, {"Generator", "QuadraticRadicand",
      "SourceRadicand"}] & /@ plan["Roots"]),
  "RationalizedRootIndices" -> plan["RationalizedRootIndices"],
  "UnrationalizedRootIndices" -> plan["UnrationalizedRootIndices"],
  "ProjectionSquareRootGeneratorIndices" ->
    plan["ProjectionSquareRootGeneratorIndices"],
  "RegulatorPoleFactors" -> plan["RegulatorPoleFactors"],
  "RootImages" -> plan["RootImages"],
  "ChartVariables" -> plan["ChartVariables"], "Variables" -> plan["Variables"],
  "Regulator" -> plan["Regulator"], "Dimensions" -> plan["Dimensions"]|>;
finiteFieldDeferredInhomogeneityEnsurePlan[descriptor_Association] := Module[{key, handle, plan},
  key = Lookup[descriptor, "Key", None];
  If[! StringQ[key], Return[None]];
  If[KeyExistsQ[$finiteFieldDeferredInhomogeneityRegistry, key], Return[key]];
  handle = Lookup[descriptor, "Handle", None];
  If[! AssociationQ[handle], Return[None]];
  plan = finiteFieldDeferredInhomogeneityPlan[<|
      "Preparation" -> handle["Preparation"],
      "CoefficientPresentation" -> <|
        "SquareRootGenerators" -> handle["Roots"]|>,
      "SquareRootGeneratorIndices" ->
        handle["RationalizedRootIndices"],
      "ProjectionSquareRootGeneratorIndices" -> Lookup[handle,
        "ProjectionSquareRootGeneratorIndices",
        handle["UnrationalizedRootIndices"]],
      "RegulatorPoleFactors" -> Lookup[handle,
        "RegulatorPoleFactors", {}]|>,
    handle["InputFile"], KeyTake[handle,
      {"SourceVariableSubstitution", "DifferentialPullbackMatrix"}],
    handle["Roots"][[handle["RationalizedRootIndices"]]],
    handle["RootImages"], handle["ChartVariables"], handle["Variables"],
    handle["Regulator"], handle["Dimensions"]];
  If[Lookup[plan, "Status", None] =!= "OK", Return[None]];
  If[plan["UnrationalizedRootIndices"] =!=
        handle["UnrationalizedRootIndices"] ||
      plan["ProjectionSquareRootGeneratorIndices"] =!= Lookup[handle,
        "ProjectionSquareRootGeneratorIndices",
        handle["UnrationalizedRootIndices"]],
    KeyDropFrom[$finiteFieldDeferredInhomogeneityRegistry, plan["Key"]];
    Return[None]];
  KeyDropFrom[$finiteFieldDeferredInhomogeneityRegistry, plan["Key"]];
  $finiteFieldDeferredInhomogeneityRegistry[key] = Join[plan,
    <|"Key" -> key, "Slim" -> True,
      "Provider" -> Join[plan["Provider"],
        <|"ProviderID" -> key|>]|>];
  key
];
finiteFieldDeferredInhomogeneityEnsurePlan[___] := None;

(* Coefficient tables of the small eps-free chart data (substitution,
   root images, root squares, Jacobian): a rational function becomes
   {numeratorRules, denominatorRules} with integer coefficients, and a batch
   of points is evaluated with packed-array arithmetic instead of one AST
   evaluation per point per expression (2 ms per image before). *)
finiteFieldDeferredInhomogeneityTable[expression_, vars_List] := Module[{t, rn, rd, lcm},
  t = Together[expression];
  rn = CoefficientRules[Numerator[t], vars]; rd = CoefficientRules[Denominator[t], vars];
  lcm = LCM @@ Denominator /@ Join[rn[[All, 2]], rd[[All, 2]]];
  {MapAt[lcm # &, rn, {All, 2}], MapAt[lcm # &, rd, {All, 2}]}
];
finiteFieldDeferredInhomogeneityTables[data_Association, rootImages_List, usedRoots_List,
    chartVariables_List, variables_List, epsilon_Symbol] := Module[
  {chartVars = Append[chartVariables, epsilon], sourceVars = Append[variables, epsilon],
   subst, images, squares, jacobian, degrees},
  subst = finiteFieldDeferredInhomogeneityTable[#, chartVars] & /@
    data["SourceVariableSubstitution"][[All, 2]];
  images = finiteFieldDeferredInhomogeneityTable[#, chartVars] & /@ rootImages;
  jacobian = Map[finiteFieldDeferredInhomogeneityTable[#, chartVars] &,
    data["DifferentialPullbackMatrix"], {2}];
  squares = finiteFieldDeferredInhomogeneityTable[#, sourceVars] & /@
    (squareRootRecordRadicand /@ usedRoots);
  degrees[tables_] := Max /@ Transpose[Join[ConstantArray[0, {1, 3}],
    Flatten[Cases[tables, (exponents_List -> _) :> exponents, Infinity], 0]]];
  <|"SourceVariableSubstitution" -> subst, "RootImages" -> images,
    "DifferentialPullbackMatrix" -> jacobian,
    "Squares" -> squares,
    "ChartDegrees" -> degrees[{subst, images, jacobian}],
    "SquareDegrees" -> degrees[squares]|>
];
(* powers 0..degree of a packed vector of residues: dims {degree + 1, n} *)
finiteFieldDeferredInhomogeneityPowers[values_List, degree_Integer, prime_Integer] :=
  NestList[Mod[# values, prime] &, ConstantArray[1, Length[values]], degree];
finiteFieldDeferredInhomogeneityPolynomialAt[rules_List, powers_List, prime_Integer, count_Integer] :=
  Module[{acc = ConstantArray[0, count]},
    Do[acc = Mod[acc + Mod[Mod[rule[[2]], prime]
      Fold[Mod[#1 #2, prime] &, MapThread[#1[[#2 + 1]] &, {powers, rule[[1]]}]], prime], prime],
      {rule, rules}];
    acc];
(* Vectorized rational values plus a pointwise regularity mask.  Zero
   denominators are replaced only while forming placeholder arithmetic at
   points already marked unusable; those values are never admitted. *)
finiteFieldDeferredInhomogeneityRationalValues[
    {numRules_, denRules_}, powers_List, prime_Integer,
    count_Integer] := Module[{num, den, regular, safeDen},
  num = finiteFieldDeferredInhomogeneityPolynomialAt[
    numRules, powers, prime, count];
  den = finiteFieldDeferredInhomogeneityPolynomialAt[
    denRules, powers, prime, count];
  regular = (# =!= 0) & /@ den;
  safeDen = Replace[den, 0 -> 1, {1}];
  <|"Values" -> Mod[num PowerMod[safeDen, -1, prime], prime],
    "RegularPointQ" -> regular|>
];
(* the values of a rational function at the batch; $Failed with the first
   singular position when a denominator vanishes *)
finiteFieldDeferredInhomogeneityRationalAt[{numRules_, denRules_}, powers_List, prime_Integer,
    count_Integer] := Module[{num, den, zero},
  With[{result = finiteFieldDeferredInhomogeneityRationalValues[
      {numRules, denRules}, powers, prime, count]},
    num = result["Values"];
    den = result["RegularPointQ"]];
  zero = FirstPosition[den, False, None, {1}, Heads -> False];
  If[zero =!= None, Return[{$Failed, First[zero]}]];
  num
];

(* Source points, all quadratic-radicand values, and the chosen modular
   square-root values for a batch of chart points.  Roots rationalized by the
   selected parametrization retain their declared images.  Any remaining
   generators receive deterministic modular square roots, so callers can
   retain only points where the complete multiquadratic algebra splits. *)
finiteFieldDeferredInhomogeneityPointData[plan_Association, prime_Integer,
    images_List] := Module[
  {tables = plan["Tables"], count = Length[images], powers,
   svData, rvData, dvData, jacobianData, sv, rv, dv,
   jacobianValues, sourcePowers, regularityMasks, regularPointQ,
   mismatch, rationalizedRootIndices, unrationalizedRootIndices,
   pointRadicands, rootValues, splitPointQ, b},
  If[images === {}, Return[<|"Status" -> "OK", "SourcePoints" -> {},
    "QuadraticRadicands" -> {}, "SquareRootGeneratorValues" -> {},
    "DifferentialPullbackMatrixValues" -> {},
    "RegularPointQ" -> {}, "SplitPointQ" -> {}|>]];
  powers = MapThread[finiteFieldDeferredInhomogeneityPowers[#1, #2, prime] &,
    {Transpose[images], tables["ChartDegrees"]}];
  svData = finiteFieldDeferredInhomogeneityRationalValues[
      #, powers, prime, count] & /@
    tables["SourceVariableSubstitution"];
  rvData = finiteFieldDeferredInhomogeneityRationalValues[
      #, powers, prime, count] & /@ tables["RootImages"];
  jacobianData = Map[
    finiteFieldDeferredInhomogeneityRationalValues[
      #, powers, prime, count] &,
    tables["DifferentialPullbackMatrix"], {2}];
  sv = If[svData === {}, {}, Lookup[svData, "Values"]];
  rv = If[rvData === {}, {}, Lookup[rvData, "Values"]];
  jacobianValues = Map[Lookup[#, "Values"] &, jacobianData, {2}];
  sourcePowers = MapThread[finiteFieldDeferredInhomogeneityPowers[#1, #2, prime] &,
    {Append[sv, images[[All, 3]]], tables["SquareDegrees"]}];
  dvData = finiteFieldDeferredInhomogeneityRationalValues[
      #, sourcePowers, prime, count] & /@ tables["Squares"];
  dv = If[dvData === {}, {}, Lookup[dvData, "Values"]];
  regularityMasks = Join[
    If[svData === {}, {}, Lookup[svData, "RegularPointQ"]],
    If[rvData === {}, {}, Lookup[rvData, "RegularPointQ"]],
    Lookup[Flatten[jacobianData], "RegularPointQ"],
    If[dvData === {}, {}, Lookup[dvData, "RegularPointQ"]]];
  regularPointQ = If[regularityMasks === {},
    ConstantArray[True, count],
    (And @@ #) & /@ Transpose[regularityMasks]];
  Do[If[TrueQ[regularPointQ[[b]]] &&
      Mod[jacobianValues[[1, 1, b]] jacobianValues[[2, 2, b]] -
        jacobianValues[[1, 2, b]] jacobianValues[[2, 1, b]], prime] === 0,
    regularPointQ[[b]] = False], {b, count}];
  rationalizedRootIndices = plan["RationalizedRootIndices"];
  unrationalizedRootIndices = plan["UnrationalizedRootIndices"];
  mismatch = FirstCase[Range[count], pointIndex_ /;
      TrueQ[regularPointQ[[pointIndex]]] &&
        AnyTrue[Range[Length[rationalizedRootIndices]],
          Mod[rv[[#, pointIndex]]^2 -
            dv[[rationalizedRootIndices[[#]], pointIndex]], prime] =!=
              0 &], None];
  If[mismatch =!= None,
    Return[<|"Status" -> "DeferredInhomogeneityRootImageMismatch",
      "Image" -> images[[mismatch]]|>]];
  pointRadicands = If[dv === {}, ConstantArray[{}, count], Transpose[dv]];
  rootValues = Table[If[! TrueQ[regularPointQ[[b]]], $Failed,
    Module[{values = ConstantArray[0, Length[plan["Roots"]]],
      rationalValues, residualSquares},
      rationalValues = If[rationalizedRootIndices === {}, {},
        rv[[All, b]]];
      If[MemberQ[rationalValues, 0], Return[$Failed, Module]];
      If[rationalizedRootIndices =!= {},
        values[[rationalizedRootIndices]] = rationalValues];
      residualSquares = If[unrationalizedRootIndices === {}, {},
        dv[[unrationalizedRootIndices, b]]];
      If[! AllTrue[residualSquares,
          #1 =!= 0 && modularResidueQ[#1, prime] &],
        Return[$Failed, Module]];
      If[unrationalizedRootIndices =!= {},
        values[[unrationalizedRootIndices]] =
          multiquadraticSquareRoots[residualSquares, prime]];
      values]], {b, count}];
  splitPointQ = ListQ /@ rootValues;
  <|"Status" -> "OK", "SourcePoints" -> Transpose[sv],
    "QuadraticRadicands" -> pointRadicands,
    "SquareRootGeneratorValues" -> rootValues,
    "DifferentialPullbackMatrixValues" ->
      Table[jacobianValues[[i, j, b]], {b, count}, {i, 2}, {j, 2}],
    "RegularPointQ" -> regularPointQ,
    "SplitPointQ" -> splitPointQ|>
];
finiteFieldDeferredInhomogeneityPointData[___] :=
  <|"Status" -> "DeferredInhomogeneityPointDataInvalid"|>;

(* Select split points before a native request is assembled.  Interpolation
   only requires distinct points; conditioning the set on quadratic-residue
   tests does not alter the rational function being reconstructed. *)
finiteFieldDeferredInhomogeneitySelectSplitImages[key_String,
    prime_Integer, images_List, required_Integer] := Module[
  {plan, data, indices},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan] || required < 1,
    Return[<|"Status" -> "DeferredInhomogeneitySplitSelectionInvalid"|>]];
  data = finiteFieldDeferredInhomogeneityPointData[plan, prime, images];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  indices = Pick[Range[Length[images]], data["SplitPointQ"], True];
  If[Length[indices] < required,
    Return[<|"Status" -> "DeferredInhomogeneityInsufficientSplitPoints",
      "Required" -> required, "Found" -> Length[indices],
      "CandidateCount" -> Length[images]|>]];
  indices = Take[indices, required];
  <|"Status" -> "OK", "Indices" -> indices,
    "Images" -> images[[indices]], "CandidateCount" -> Length[images],
    "AcceptedCount" -> Length[indices]|>
];
finiteFieldDeferredInhomogeneitySelectSplitImages[___] :=
  <|"Status" -> "DeferredInhomogeneitySplitSelectionInvalid"|>;

(* One native preflight per already-selected split image. *)
finiteFieldDeferredInhomogeneityPreflights[plan_Association, prime_Integer,
    images_List] := Module[{data, bad, count = Length[images]},
  data = finiteFieldDeferredInhomogeneityPointData[plan, prime, images];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  bad = FirstPosition[data["SplitPointQ"], False, None];
  If[bad =!= None,
    Return[<|"Status" -> "DeferredInhomogeneityPointNotSplit",
      "Image" -> images[[First[bad]]]|>]];
  Table[<|"Status" -> "MultiquadraticProviderPreflightV1",
      "Provider" -> "DeferredInhomogeneity",
      "CoefficientData" -> plan["Provider", "CoefficientData"],
      "Prime" -> prime, "ProviderID" -> plan["Key"],
      "Point" -> data["SourcePoints"][[b]],
      "EpsilonMod" -> images[[b, 3]],
      "QuadraticRadicands" -> data["QuadraticRadicands"][[b]],
      "SquareRootGeneratorValues" ->
        data["SquareRootGeneratorValues"][[b]],
      "DifferentialPullbackMatrixValue" ->
        data["DifferentialPullbackMatrixValues"][[b]],
      "SplitPointQ" -> True|>, {b, count}]
];
(* the per-point reference (AST evaluation of the chart data at every image);
   the exactness probe and the test compare the batch evaluator against it *)
finiteFieldDeferredInhomogeneityPreflightsReference[plan_Association, prime_Integer,
    images_List] := Module[{X, Y, subst, rootImages, squares, variables,
  epsilon, rationalizedRootIndices},
  {X, Y} = plan["ChartVariables"];
  subst = plan["SourceVariableSubstitution"];
  rootImages = plan["RootImages"]; variables = plan["Variables"];
  squares = squareRootRecordRadicand /@ plan["Roots"];
  epsilon = plan["Regulator"];
  rationalizedRootIndices = plan["RationalizedRootIndices"];
  Catch[Table[Module[{x = image[[1]], y = image[[2]],
      eps = image[[3]], values, sv, rv, dv, allRootValues},
      values = <|X -> x, Y -> y, epsilon -> eps|>;
      sv = finiteFieldDeferredInhomogeneityModAt[#, values, prime] & /@ subst[[All, 2]];
      rv = finiteFieldDeferredInhomogeneityModAt[#, values, prime] & /@ rootImages;
      If[MemberQ[sv, $Failed] || MemberQ[rv, $Failed],
        Throw[<|"Status" -> "DeferredInhomogeneitySingularChartPoint", "Image" -> image|>, "dfp"]];
      dv = finiteFieldDeferredInhomogeneityModAt[#,
        Join[AssociationThread[variables, sv], <|epsilon -> eps|>], prime] & /@ squares;
      If[MemberQ[dv, $Failed] ||
          (rv =!= {} && Mod[rv^2 - dv[[rationalizedRootIndices]], prime] =!=
            ConstantArray[0, Length[rv]]),
        Throw[<|"Status" -> "DeferredInhomogeneityRootImageMismatch", "Image" -> image|>, "dfp"]];
      If[! AllTrue[dv, #1 =!= 0 && modularResidueQ[#1, prime] &],
        Throw[<|"Status" -> "DeferredInhomogeneityPointNotSplit",
          "Image" -> image|>, "dfp"]];
      allRootValues = multiquadraticSquareRoots[dv, prime];
      If[rationalizedRootIndices =!= {},
        allRootValues[[rationalizedRootIndices]] = rv];
      <|"Status" -> "MultiquadraticProviderPreflightV1",
        "Provider" -> "DeferredInhomogeneity",
        "CoefficientData" -> plan["Provider", "CoefficientData"],
        "Prime" -> prime, "ProviderID" -> plan["Key"],
        "Point" -> sv, "EpsilonMod" -> eps,
        "QuadraticRadicands" -> dv,
        "SquareRootGeneratorValues" -> allRootValues,
        "SplitPointQ" -> True|>],
    {image, images}], "dfp"]
];

(* the inhomogeneity images: one native batch; per image an array
   {2, d1, d2} of residues (the chart one-form after the Jacobian) *)
Options[finiteFieldDeferredInhomogeneityImages] = {"Threads" -> Automatic};
finiteFieldDeferredInhomogeneityImages[key_String, prime_Integer, images_List,
    OptionsPattern[]] := Module[
  {plan, preflights, batch, gradeCount, jacobian, masks,
   started = AbsoluteTime[],
   cacheKeys, missing, batchSeconds = 0., values, computed, requestedThreads, threads},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredInhomogeneityPlanUnknown"|>]];
  If[images === {}, Return[<|"Status" -> "OK", "Values" -> {}, "Seconds" -> 0.|>]];
  requestedThreads = Replace[OptionValue["Threads"],
    Automatic :> Clip[$ProcessorCount, {1, 8}]];
  If[! IntegerQ[requestedThreads] || ! Between[requestedThreads, {1, 8}],
    Return[<|"Status" -> "DeferredInhomogeneityInvalidThreadCount",
      "Threads" -> requestedThreads|>]];
  threads = taskBrokerNativeThreadLimit[requestedThreads];
  (* R2 F1: the cache is bounded between calls only -- a call is atomic with
     respect to it; its own results live in a local list until they are
     returned, so a reset can never leave a value of this call Missing *)
  If[Length[$finiteFieldDeferredInhomogeneityImageCache] > 400000,
    $finiteFieldDeferredInhomogeneityImageCache = <||>];
  cacheKeys = Join[{key, prime}, #] & /@ images;
  values = Lookup[$finiteFieldDeferredInhomogeneityImageCache, cacheKeys];
  missing = Pick[Range[Length[images]], MatchQ[#, _Missing] & /@ values];
  (* the native evaluator caps the images per request (ResourceLimit above
     ~1000): the missing images go in chunks of $finiteFieldDeferredInhomogeneityBatchLimit *)
  Do[
    preflights = finiteFieldDeferredInhomogeneityPreflights[plan, prime, images[[chunk]]];
    If[AssociationQ[preflights], Return[preflights, Module]];
    batch = multiquadraticOffDiagonalBlockNativeDeferredEvaluateBatch[plan["Provider"], preflights,
      "Threads" -> threads];
    If[Lookup[batch, "Status", None] =!= "MultiquadraticNativeDeferredBatchV1",
      Return[<|"Status" -> "DeferredInhomogeneityBatchFailed", "Detail" -> batch|>, Module]];
    batchSeconds += batch["Seconds"];
    gradeCount = batch["GradeCount"];
    With[{unrationalizedMask = Total[
          2^(plan["UnrationalizedRootIndices"] - 1)]},
      If[unrationalizedMask =!= 0,
        With[{unwantedGrades = 1 + Select[Range[0, gradeCount - 1],
              BitAnd[#1, unrationalizedMask] =!= 0 &]},
          If[AnyTrue[Flatten[
                batch["InhomogeneityBatch"][[All, All, All, All,
                  unwantedGrades]]], #1 =!= 0 &],
            Return[<|
              "Status" ->
                "DeferredInhomogeneityOutsideRationalizedSubfield",
              "UnrationalizedRootIndices" ->
                plan["UnrationalizedRootIndices"],
              "Prime" -> prime|>, Module]]]]];
    (* grade contraction with the root values (one Dot per image) and the
       already-admitted differential pullback matrix for the whole chunk *)
    jacobian = Table[
      preflights[[b, "DifferentialPullbackMatrixValue", i, j]],
      {i, 2}, {j, 2}, {b, Length[preflights]}];
    masks = Table[multiquadraticMaskFactor[g,
        #["SquareRootGeneratorValues"]], {g, 0, gradeCount - 1}] & /@
      preflights;
    Do[computed = With[{av = Mod[batch["InhomogeneityBatch"][[b]] . masks[[b]], prime]},
        {Mod[Mod[av[[1]] jacobian[[1, 1, b]], prime] + Mod[av[[2]] jacobian[[2, 1, b]], prime], prime],
         Mod[Mod[av[[1]] jacobian[[1, 2, b]], prime] + Mod[av[[2]] jacobian[[2, 2, b]], prime], prime]}];
      values[[chunk[[b]]]] = computed;
      $finiteFieldDeferredInhomogeneityImageCache[cacheKeys[[chunk[[b]]]]] = computed,
      {b, Length[chunk]}],
    {chunk, Partition[missing, UpTo[Min[$finiteFieldDeferredInhomogeneityBatchLimit,
      Floor[4096/Lookup[plan["Provider"], "GradeCount", 8]]]]]}];
  (* never OK with a hole: a Missing value is a typed failure of the call *)
  If[! FreeQ[values, _Missing, {1}],
    Return[<|"Status" -> "DeferredInhomogeneityImagesIncomplete",
      "MissingCount" -> Count[values, _Missing, {1}]|>]];
  <|"Status" -> "OK",
    "Values" -> values,
    "BatchedImages" -> Length[missing],
    "Threads" -> threads,
    "BatchSeconds" -> batchSeconds,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

(* rational interpolation in one variable modulo p: one nullspace at the
   degree bound, reduced by the gcd, validated on held-out points *)
finiteFieldDeferredInhomogeneityLineFit[data_List, bound_Integer, prime_Integer, t_Symbol] := Module[
  {construction, validation, matrix, nullspace, vector, numPoly, denPoly, g},
  If[Length[data] < 2 bound + 6, Return[$Failed]];
  construction = Take[data, 2 bound + 2]; validation = Drop[data, 2 bound + 2];
  matrix = Table[Join[Table[PowerMod[datum[[1]], power, prime], {power, 0, bound}],
      Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime], prime], {power, 0, bound}]],
    {datum, construction}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[nullspace === {}, Return[$Failed]];
  vector = First[nullspace];
  numPoly = FromDigits[Reverse[vector[[1 ;; bound + 1]]], t];
  denPoly = FromDigits[Reverse[vector[[bound + 2 ;;]]], t];
  If[denPoly === 0, Return[$Failed]];
  g = PolynomialGCD[numPoly, denPoly, Modulus -> prime];
  numPoly = PolynomialQuotient[numPoly, g, t, Modulus -> prime];
  denPoly = PolynomialQuotient[denPoly, g, t, Modulus -> prime];
  If[! AllTrue[validation, Mod[denPoly /. t -> #[[1]], prime] =!= 0 &&
      Mod[(numPoly /. t -> #[[1]]) - #[[2]] (denPoly /. t -> #[[1]]), prime] === 0 &],
    Return[$Failed]];
  <|"Numerator" -> numPoly, "Denominator" -> denPoly,
    "Degrees" -> {Exponent[numPoly, t], Exponent[denPoly, t]}|>
];

(* A source root whose square becomes a perfect square under the chart map
   reaches the candidates as Sqrt[p^2/q^2]: reduced to p/q (the sign is
   irrelevant for a factor candidate; an irreducible radical is left and its
   piece dropped, which the census's degree consistency then reports). *)
finiteFieldDeferredInhomogeneityPolynomialRoot[poly_] := Module[
  {factorList, scalar, scalarRoot, factors},
  If[TrueQ[poly === 0], Return[0]];
  factorList = FactorList[poly];
  scalar = factorList[[1, 1]]^factorList[[1, 2]];
  scalarRoot = Sqrt[scalar];
  factors = Rest[factorList];
  If[! MatchQ[scalarRoot, _Integer | _Rational] ||
      ! AllTrue[factors[[All, 2]], EvenQ], Return[$Failed]];
  scalarRoot Times @@
    (Power[#[[1]], #[[2]]/2] & /@ factors)
];
finiteFieldDeferredInhomogeneityRadicalVariants[expr_, maximum_: Infinity] := Module[
  {powers, rationalized, representatives = {}, classes, position, equivalentQ},
  powers = DeleteDuplicates[Cases[expr,
    power : Power[_, exponent_Rational /; Denominator[exponent] == 2] :> power,
    {0, Infinity}]];
  rationalized = Cases[powers, power_ :> With[{t = Together[power[[1]]]},
    With[{n = finiteFieldDeferredInhomogeneityPolynomialRoot[Numerator[t]],
        d = finiteFieldDeferredInhomogeneityPolynomialRoot[Denominator[t]]},
      If[n === $Failed || d === $Failed, Nothing, {power, n/d}]]]];
  If[rationalized === {}, Return[{expr}]];
  equivalentQ[a_, b_] := TrueQ[Together[a - b] === 0] ||
    TrueQ[Together[a + b] === 0];
  classes = Table[
    position = FirstPosition[representatives,
      representative_ /; equivalentQ[item[[2]], representative], None];
    If[position === None,
      AppendTo[representatives, item[[2]]]; Length[representatives],
      First[position]],
    {item, rationalized}];
  If[IntegerQ[maximum] && Length[representatives] > maximum,
    Return[{expr}]];
  Table[expr /. MapThread[
      Function[{item, class},
        item[[1]] -> signChoice[[class]] Power[item[[2]], 2 item[[1, 2]]]],
      {rationalized, classes}],
    {signChoice, Tuples[{1, -1}, Length[representatives]]}]
];

(* Relative norm from the complete multiquadratic field to the field made
   rational by the selected parametrization.  A denominator factor is first
   written with formal generators.  The selected generators are replaced by
   their rational images, while only the remaining generators are conjugated.
   Their orbit product is invariant under every remaining sign change and is
   then reduced with r_i^2 = Delta_i.  This operation is factorwise: it never
   assembles the characteristic-zero block equation. *)
finiteFieldDeferredInhomogeneityRelativeNorm[expression_,
    plan_Association] := Module[
  {roots = plan["Roots"], rationalizedIndices,
   unrationalizedIndices, tags, rootExpressions, tagged,
   rationalizedRules, unmatchedRadicals, activeIndices, squares,
   quadraticNormStep, result},
  rationalizedIndices = plan["RationalizedRootIndices"];
  unrationalizedIndices = plan["UnrationalizedRootIndices"];
  tags = Table[Unique["FeynFacet`Private`deferredNormRoot"],
    {Length[roots]}];
  rootExpressions = squareRootRecordExpression /@ roots;
  If[! DuplicateFreeQ[rootExpressions], Return[$Failed]];
  tagged = transportChartApplyRootBranches[expression, roots, tags];
  tagged = tagged /. plan["SourceVariableSubstitution"];
  rationalizedRules = Thread[
    tags[[rationalizedIndices]] -> plan["RootImages"]];
  tagged = Together[tagged /. rationalizedRules];
  unmatchedRadicals = transportChartRadicalBases[tagged];
  If[unmatchedRadicals =!= {}, Return[$Failed]];
  activeIndices = Select[unrationalizedIndices,
    ! FreeQ[tagged, tags[[#]]] &];
  squares = Together[
      squareRootRecordRadicand[#] /.
        plan["SourceVariableSubstitution"]] & /@ roots;
  quadraticNormStep[value_, index_Integer] := Module[
    {tag = tags[[index]], square = squares[[index]], rational,
     numerator, denominator, numeratorNorm, denominatorNorm},
    rational = Together[value];
    numerator = Numerator[rational];
    denominator = Denominator[rational];
    If[! PolynomialQ[numerator, tag] ||
        ! PolynomialQ[denominator, tag], Return[$Failed]];
    numeratorNorm = PolynomialRemainder[
      Expand[numerator (numerator /. tag -> -tag)],
      tag^2 - square, tag];
    denominatorNorm = PolynomialRemainder[
      Expand[denominator (denominator /. tag -> -tag)],
      tag^2 - square, tag];
    If[! FreeQ[{numeratorNorm, denominatorNorm}, tag] ||
        TrueQ[denominatorNorm === 0], Return[$Failed]];
    Cancel[numeratorNorm/denominatorNorm]
  ];
  result = Fold[If[#1 === $Failed, $Failed,
      quadraticNormStep[#1, #2]] &,
    tagged, activeIndices];
  If[result === $Failed ||
      ! FreeQ[result, Alternatives @@ tags[[unrationalizedIndices]]],
    $Failed, Together[result]]
];
finiteFieldDeferredInhomogeneityRelativeNorm[___] := $Failed;

(* the structural superset of the pulled-back denominator factors *)
finiteFieldDeferredInhomogeneityCandidateFactors[plan_Association] := Module[
  {records, operands, basesOf, sourceBases, subst, X, Y, epsilon,
   relativeNorms, pieces},
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"];
  subst = plan["SourceVariableSubstitution"];
  records = Lookup[plan["Preparation"], "Records", {}];
  (* the operands and the terms' coefficients: both carry denominators *)
  operands = DeleteDuplicates[Flatten[{Lookup[#, "Operands", {}], Lookup[#, "Coefficient", 1]} & /@
    Flatten[Lookup[records, "Terms", {}]]]];
  (* every denominator base at every level (Denominator is structural and
     misses denominators nested inside sums; a measured large block had missing
     quartic and degree-7 factors), radicals' squares included *)
  basesOf[expr_] := Module[{den = Denominator[expr], list},
    list = If[Head[den] === Times, List @@ den, {den}];
    Select[Join[Replace[list, Power[base_, _Integer] :> base, {1}],
      Cases[expr, Power[base_, exponent_?Negative] :> base, {0, Infinity}]], ! NumericQ[#] &]];
  sourceBases = DeleteDuplicates[Flatten[basesOf /@ operands]];
  (* A factor containing roots outside the selected parametrization is
     replaced by its relative norm.  Every rational denominator of the
     projected sum divides this norm; factoring it therefore supplies the
     census with a structural superset without exact block materialization. *)
  relativeNorms =
    finiteFieldDeferredInhomogeneityRelativeNorm[#, plan] & /@
      sourceBases;
  If[MemberQ[relativeNorms, $Failed], Return[$Failed]];
  pieces = Join[Numerator /@ relativeNorms,
    Denominator /@ relativeNorms,
    Denominator /@ Together /@ subst[[All, 2]],
    Denominator /@ Together /@ plan["RootImages"],
    Numerator /@ Together /@ plan["RootImages"],
    Denominator /@ Flatten[Together /@ plan["DifferentialPullbackMatrix"]],
    Numerator /@ Flatten[Together /@ plan["DifferentialPullbackMatrix"]]];
  pieces = DeleteDuplicates[Select[pieces, ! NumericQ[#] &]];
  If[! AllTrue[pieces, PolynomialQ[#, {X, Y, epsilon}] &],
    Return[$Failed]];
  pieces = DeleteDuplicates[Flatten[
    (First /@ Rest[FactorList[#]]) & /@ pieces]];
  pieces = Select[pieces, ! FreeQ[#, X | Y] &];
  DeleteDuplicates[pieces, TrueQ[Together[#1 - #2] === 0] || TrueQ[Together[#1 + #2] === 0] &]
];

(* The census: candidate factors, their maximal pole orders over the
   entries and the inhomogeneity's degree at infinity, from two random lines
   (a + t, b + s t) in the chart at a random regulator image. *)
Options[finiteFieldDeferredInhomogeneityCensus] = {
  "DegreeBound" -> 110, "Seed" -> 20260902, "Threads" -> Automatic};
finiteFieldDeferredInhomogeneityCensus[key_String, prime_Integer,
    OptionsPattern[]] := Module[
  {plan, started = AbsoluteTime[], candidates, X, Y, epsilon, bound, t, lineCount,
   epsilonMod, splitFactor, lineCensus, results = {}, lineFailures = {},
   lineResult, letters, powers, infinity},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredInhomogeneityPlanUnknown"|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"];
  bound = OptionValue["DegreeBound"]; lineCount = 2 bound + 20;
  splitFactor = 2^Length[plan["UnrationalizedRootIndices"]];
  t = Symbol["FeynFacet`Private`deferredInhomogeneityLineT"];
  If[TrueQ[Lookup[plan, "Slim", False]], Return[<|"Status" -> "DeferredInhomogeneityPlanSlim"|>]];
  candidates = finiteFieldDeferredInhomogeneityCandidateFactors[plan];
  If[candidates === $Failed,
    Return[<|"Status" ->
      "DeferredInhomogeneityCandidateFactorConstructionFailed"|>]];
  lineCensus[seed_] := Module[{a0, b0, slope, candidateTValues,
      candidateImages, selection, tValues, images, evaluated, fits,
      factorLines, pairwiseFactors, divideDenominator, divisions,
      entryPowers},
    BlockRandom[SeedRandom[seed];
      {a0, b0, slope} = RandomInteger[{2, prime - 2}, 3];
      epsilonMod = RandomInteger[{2, prime - 2}]];
    candidateTValues = Table[Mod[a0 + 7 k, prime],
      {k, 4 splitFactor lineCount}];
    candidateImages = Table[{Mod[a0 + tv, prime],
        Mod[b0 + slope tv, prime], epsilonMod},
      {tv, candidateTValues}];
    selection = finiteFieldDeferredInhomogeneitySelectSplitImages[
      key, prime, candidateImages, lineCount];
    If[Lookup[selection, "Status", None] =!= "OK",
      Return[If[Lookup[selection, "Status", None] ===
          "DeferredInhomogeneityInsufficientSplitPoints",
        <|"Status" -> "DeferredInhomogeneityExceptionalCensusLine",
          "Reason" -> "InsufficientSplitPoints"|>, selection], Module]];
    tValues = candidateTValues[[selection["Indices"]]];
    images = selection["Images"];
    evaluated = finiteFieldDeferredInhomogeneityImages[key, prime, images,
      "Threads" -> OptionValue["Threads"]];
    If[Lookup[evaluated, "Status", None] =!= "OK", Return[evaluated, Module]];
    fits = Table[finiteFieldDeferredInhomogeneityLineFit[
        Table[{tValues[[k]], Flatten[evaluated["Values"][[k]]][[entry]]}, {k, lineCount}],
        bound, prime, t], {entry, 2 Times @@ plan["Dimensions"]}];
    If[MemberQ[fits, $Failed], Return[<|"Status" -> "DeferredInhomogeneityLineFitFailed"|>, Module]];
    factorLines = PolynomialMod[Expand[# /. {X -> a0 + t, Y -> b0 + slope t, epsilon -> epsilonMod}], prime] & /@ candidates;
    If[AnyTrue[factorLines, # === 0 || FreeQ[#, t] &],
      Return[<|"Status" ->
        "DeferredInhomogeneityExceptionalCensusLine",
        "Reason" -> "CandidateDegenerated"|>, Module]];
    pairwiseFactors = Subsets[factorLines, {2}];
    If[AnyTrue[pairwiseFactors,
        Exponent[PolynomialGCD[#[[1]], #[[2]],
          Modulus -> prime], t] > 0 &],
      Return[<|"Status" ->
        "DeferredInhomogeneityExceptionalCensusLine",
        "Reason" -> "CandidatesCollided"|>, Module]];
    divideDenominator[denominator_] := Module[
      {remaining = PolynomialMod[Expand[denominator], prime], q, r,
       count},
      With[{counts = Table[
          count = 0;
          While[Exponent[remaining, t] >= Exponent[line, t],
            {q, r} = PolynomialQuotientRemainder[
              remaining, line, t, Modulus -> prime];
            If[r =!= 0, Break[]];
            remaining = q; count++];
          count, {line, factorLines}]},
        <|"Powers" -> counts,
          "Covered" -> FreeQ[remaining, t],
          "UncoveredDegree" -> Exponent[remaining, t]|>]
    ];
    divisions = divideDenominator[#["Denominator"]] & /@ fits;
    entryPowers = Lookup[divisions, "Powers"];
    <|"Status" -> "OK",
      "MaxPowers" -> (Max /@ Transpose[entryPowers]),
      "Infinity" -> Max[Table[fit["Degrees"][[1]] - fit["Degrees"][[2]], {fit, fits}]],
      "LineDegrees" -> Lookup[fits, "Degrees"],
      "DenominatorsCovered" ->
        AllTrue[divisions, TrueQ[#["Covered"]] &]|>];
  Do[
    lineResult = lineCensus[OptionValue["Seed"] + offset];
    Which[
      Lookup[lineResult, "Status", None] === "OK",
        AppendTo[results, lineResult],
      Lookup[lineResult, "Status", None] ===
          "DeferredInhomogeneityExceptionalCensusLine",
        AppendTo[lineFailures, lineResult],
      True, Return[lineResult]];
    If[Length[results] >= 2, Break[]], {offset, 0, 7}];
  If[Length[results] < 2,
    Return[<|"Status" -> "DeferredInhomogeneityCensusLinesUnavailable",
      "ExceptionalLines" -> lineFailures|>]];
  If[results[[1]]["MaxPowers"] =!= results[[2]]["MaxPowers"] ||
      results[[1]]["Infinity"] =!= results[[2]]["Infinity"] ||
      ! TrueQ[results[[1]]["DenominatorsCovered"]] ||
      ! TrueQ[results[[2]]["DenominatorsCovered"]],
    Return[<|"Status" -> "DeferredInhomogeneityCensusLinesDisagree", "Lines" -> results|>]];
  powers = results[[1]]["MaxPowers"];
  letters = Pick[candidates, Table[powers[[k]] > 0 && FreeQ[candidates[[k]], epsilon], {k, Length[candidates]}]];
  <|"Status" -> "OK", "Key" -> key, "Prime" -> prime,
    "Letters" -> letters,
    "OffDiagonalBasisTransformationDenominatorFactorPowers" -> Select[Transpose[{candidates, powers}], Last[#] > 1 &],
    "InhomogeneityInfinityDegree" -> results[[1]]["Infinity"],
    "LineDegrees" -> results[[1]]["LineDegrees"],
    "CandidateCount" -> Length[candidates],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

(* the numerical verifier's identity with the DAG image in place of the
   placeholder inhomogeneity: d G - eps (e G - G c) - inhomogeneity + eps Sum K dlog == 0
   at random points modulo a fresh prime; every regular point must vanish.
   Everything is evaluated from coefficient tables (derivatives by exponent
   shift), so a measured 64751-leaf chart basis-transformation block is never
   differentiated or substituted symbolically (20 s per check before). *)
finiteFieldDeferredInhomogeneityDerivativeRules[rules_List, index_Integer] :=
  Cases[rules, (exponents_List -> coefficient_) /; exponents[[index]] > 0 :>
    (exponents - UnitVector[Length[exponents], index] -> coefficient exponents[[index]])];
Options[finiteFieldDeferredInhomogeneityResidualQ] = {
  "Seed" -> 20260903, "Threads" -> Automatic};
finiteFieldDeferredInhomogeneityResidualQ[key_String, {e_, c_},
    basisTransformationBlock_, alphabet_List,
    residueMatrices_List, pointCount_Integer: 16, OptionsPattern[]] := Module[
  {plan, X, Y, epsilon, vars, prime, points, images, started = AbsoluteTime[],
   offDiagonalBasisTransformationTables, eTables, cTables, letterTables, residueTables, residues, degrees, powers, poly, bad = {},
   inverse, at, dAt, dlogAt, offDiagonalBasisTransformationValues, offDiagonalBasisTransformationDerivatives, eValues, cValues, dlogValues,
   epsValues, product, residual, good, ok, dims, tableSeconds,
   candidatePoints, splitSelection, splitFactor},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan], Return[<|"Status" -> "DeferredInhomogeneityPlanUnknown"|>]];
  {X, Y} = plan["ChartVariables"]; epsilon = plan["Regulator"]; vars = {X, Y, epsilon};
  If[! FreeQ[{e, c, basisTransformationBlock, alphabet}, Power[_, _Rational]],
    Return[<|"Status" -> "DeferredInhomogeneityResidualRadical"|>]];
  dims = Dimensions[basisTransformationBlock];
  tableSeconds = First[AbsoluteTiming[
    offDiagonalBasisTransformationTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, basisTransformationBlock, {2}];
    eTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, e, {3}];
    cTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, c, {3}];
    letterTables = finiteFieldDeferredInhomogeneityTable[#, vars] & /@ alphabet;
    (* the residue matrices may carry eps (the verifier reports ResiduesEpsFree separately) *)
    residueTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, residueMatrices, {3}]]];
  (* R2 F4: seeded, so the prime and the points of a recorded check are
     reproducible from the record's Seed *)
  BlockRandom[SeedRandom[OptionValue["Seed"]];
    prime = RandomPrime[{2^30, 2^31 - 1}];
    splitFactor = 2^Length[plan["UnrationalizedRootIndices"]];
    candidatePoints = Table[RandomInteger[{3, prime - 3}, 3],
      {4 splitFactor pointCount}]];
  splitSelection = finiteFieldDeferredInhomogeneitySelectSplitImages[
    key, prime, candidatePoints, pointCount];
  If[Lookup[splitSelection, "Status", None] =!= "OK",
    Return[splitSelection]];
  points = splitSelection["Images"];
  images = finiteFieldDeferredInhomogeneityImages[key, prime, points,
    "Threads" -> OptionValue["Threads"]];
  If[Lookup[images, "Status", None] =!= "OK", Return[images]];
  degrees = Max /@ Transpose[Join[ConstantArray[0, {1, 3}],
    Cases[{offDiagonalBasisTransformationTables, eTables, cTables, letterTables, residueTables}, (exponents_List -> _) :> exponents, Infinity]]];
  powers = MapThread[finiteFieldDeferredInhomogeneityPowers[#1, #2, prime] &, {Transpose[points], degrees}];
  poly[rules_] := finiteFieldDeferredInhomogeneityPolynomialAt[rules, powers, prime, pointCount];
  (* a vanishing denominator marks the point as a pole (dropped, as before) *)
  inverse[values_] := (bad = Join[bad, Flatten[Position[values, 0, {1}, Heads -> False]]];
    PowerMod[values /. 0 -> 1, -1, prime]);
  at[{rn_, rd_}] := Mod[poly[rn] inverse[poly[rd]], prime];
  dAt[{rn_, rd_}, mu_] := With[{n = poly[rn], d = poly[rd],
      dn = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rn, mu]],
      dd = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rd, mu]]},
    With[{inv = inverse[d]}, Mod[Mod[Mod[dn d, prime] - Mod[n dd, prime], prime] Mod[inv inv, prime], prime]]];
  dlogAt[{rn_, rd_}, mu_] := With[{n = poly[rn], d = poly[rd],
      dn = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rn, mu]],
      dd = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rd, mu]]},
    Mod[Mod[dn inverse[n], prime] - Mod[dd inverse[d], prime], prime]];
  offDiagonalBasisTransformationValues = Map[at, offDiagonalBasisTransformationTables, {2}];
  offDiagonalBasisTransformationDerivatives = Table[Map[dAt[#, mu] &, offDiagonalBasisTransformationTables, {2}], {mu, 2}];
  eValues = Map[at, eTables, {3}]; cValues = Map[at, cTables, {3}];
  residues = Map[at, residueTables, {3}];
  dlogValues = Table[dlogAt[letterTables[[a]], mu], {a, Length[alphabet]}, {mu, 2}];
  epsValues = points[[All, 3]];
  (* matrix products with the point index innermost *)
  product[a_, b_] := Table[Mod[Total[Table[Mod[a[[i, k]] b[[k, j]], prime], {k, Length[b]}]], prime],
    {i, Length[a]}, {j, Length[First[b]]}];
  residual = Table[Mod[
      offDiagonalBasisTransformationDerivatives[[mu]] -
        Map[Mod[epsValues #, prime] &, Mod[product[eValues[[mu]], offDiagonalBasisTransformationValues] - product[offDiagonalBasisTransformationValues, cValues[[mu]]], prime], {2}] -
        Transpose[images["Values"][[All, mu]], {3, 1, 2}] +
        Map[Mod[epsValues #, prime] &,
          Mod[Sum[Map[Mod[dlogValues[[a, mu]] #, prime] &, residues[[a]], {2}], {a, Length[alphabet]}], prime], {2}],
      prime], {mu, 2}];
  good = Complement[Range[pointCount], bad];
  ok = Length[good] >= Ceiling[pointCount/2] &&
    Flatten[residual[[All, All, All, good]]] === ConstantArray[0, 2 Times @@ dims Length[good]];
  <|"Status" -> "OK", "ResidualZero" -> ok, "Prime" -> prime,
    "Points" -> Length[good], "RequestedPoints" -> pointCount, "Seed" -> OptionValue["Seed"],
    "TableSeconds" -> tableSeconds,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

(* The production residual for a basis-transformation block reconstructed in
   the source variables.  The reconstruction already consists of exact
   rational functions of epsilon multiplying source-variable monomials in
   each multiquadratic grade.  Evaluate that representation directly at the
   same fresh modular points used for the deferred inhomogeneity, including
   its source derivatives and the chart Jacobian.  This is mathematically the
   same residual as finiteFieldDeferredInhomogeneityResidualQ, without first
   composing a large characteristic-zero expression, substituting every root
   branch, and parsing the result back into coefficient tables. *)
Options[finiteFieldDeferredInhomogeneityCoefficientResidualQ] =
  Options[finiteFieldDeferredInhomogeneityResidualQ];
finiteFieldDeferredInhomogeneityCoefficientResidualQ[key_String, {e_, c_},
    representation_Association, rootIndices_List, signs_List,
    alphabet_List, residueMatrices_List, pointCount_Integer: 16,
    OptionsPattern[]] := Module[
  {plan, X, Y, epsilon, vars, sourceVariables, prime, candidatePoints,
   splitFactor, splitSelection, points, pointData, images,
   eTables, cTables, letterTables, residueTables, tableSeconds,
   degrees, powers, poly, regularPointQ, inverse, at, dlogAt,
   eValues, cValues, residues, dlogValues, epsValues, sourcePoints,
   dimensions, entryCount, rootCount, gradeCount, numeratorSupport,
   denominatorSupport, numeratorPairs, denominatorPairs,
   numeratorMonomials, denominatorMonomials,
   numeratorMonomialDerivatives, denominatorMonomialDerivatives,
   coefficientPolynomialValues, rationalMod, coefficientAt,
   numeratorCoefficientValues, denominatorCoefficientValues,
   assemble, numeratorValues, numeratorDerivatives, denominatorValues,
   denominatorDerivatives, inverseDenominator, channelValues,
   channelDerivatives, selectedRootValues, rootMonomialValues,
   rootSquareExpressions, rootSquareValues, rootSquareDerivativeValues,
   rootLogDerivatives, rootMonomialDerivatives,
   basisTransformationFlatValues, basisTransformationFlatDerivatives,
   basisTransformationValues, basisTransformationDerivatives,
   product, residual, good, ok, started = AbsoluteTime[],
   representationSeconds, failure = None, monomialValues},
  plan = Lookup[$finiteFieldDeferredInhomogeneityRegistry, key, $Failed];
  If[! AssociationQ[plan],
    Return[<|"Status" -> "DeferredInhomogeneityPlanUnknown"|>]];
  dimensions = Lookup[representation, "Dimensions", $Failed];
  sourceVariables = Lookup[representation, "Variables", $Failed];
  epsilon = Lookup[representation, "Regulator", $Failed];
  rootCount = Lookup[representation, "RootCount", $Failed];
  gradeCount = Lookup[representation, "GradeCount", $Failed];
  numeratorSupport = Lookup[representation, "NumeratorSupport", $Failed];
  denominatorSupport = Lookup[representation, "DenominatorSupport", $Failed];
  numeratorPairs = Lookup[representation,
    "NumeratorCoefficientPairs", $Failed];
  denominatorPairs = Lookup[representation,
    "DenominatorCoefficientPairs", $Failed];
  If[Lookup[representation, "Status", None] =!=
        "FiniteFieldBasisTransformationCoefficientRepresentationV1" ||
      dimensions =!= plan["Dimensions"] ||
      sourceVariables =!= plan["Variables"] ||
      epsilon =!= plan["Regulator"] ||
      ! IntegerQ[rootCount] || ! IntegerQ[gradeCount] ||
      gradeCount =!= 2^rootCount ||
      rootIndices =!= plan["RationalizedRootIndices"] ||
      Length[rootIndices] =!= rootCount ||
      signs =!= Select[signs, MemberQ[{1, -1}, #] &] ||
      Length[signs] =!= rootCount ||
      ! MatchQ[numeratorSupport, {{_Integer, _Integer} ..}] ||
      ! MatchQ[denominatorSupport, {{_Integer, _Integer} ..}] ||
      Min[Flatten[{numeratorSupport, denominatorSupport}]] < 0 ||
      Dimensions[numeratorPairs] =!=
        {Times @@ dimensions, gradeCount, Length[numeratorSupport]} ||
      Length[denominatorPairs] =!= Length[denominatorSupport],
    Return[<|"Status" ->
      "DeferredInhomogeneityCoefficientRepresentationInvalid"|>]];
  entryCount = Times @@ dimensions;
  {X, Y} = plan["ChartVariables"];
  vars = {X, Y, epsilon};
  If[! FreeQ[{e, c, alphabet}, Power[_, _Rational]],
    Return[<|"Status" -> "DeferredInhomogeneityResidualRadical"|>]];
  tableSeconds = First[AbsoluteTiming[
    eTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, e, {3}];
    cTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &, c, {3}];
    letterTables = finiteFieldDeferredInhomogeneityTable[#, vars] & /@ alphabet;
    residueTables = Map[finiteFieldDeferredInhomogeneityTable[#, vars] &,
      residueMatrices, {3}]]];
  BlockRandom[SeedRandom[OptionValue["Seed"]];
    prime = RandomPrime[{2^30, 2^31 - 1}];
    splitFactor = 2^Length[plan["UnrationalizedRootIndices"]];
    candidatePoints = Table[RandomInteger[{3, prime - 3}, 3],
      {4 splitFactor pointCount}]];
  splitSelection = finiteFieldDeferredInhomogeneitySelectSplitImages[
    key, prime, candidatePoints, pointCount];
  If[Lookup[splitSelection, "Status", None] =!= "OK",
    Return[splitSelection]];
  points = splitSelection["Images"];
  pointData = finiteFieldDeferredInhomogeneityPointData[plan, prime, points];
  If[Lookup[pointData, "Status", None] =!= "OK", Return[pointData]];
  images = finiteFieldDeferredInhomogeneityImages[key, prime, points,
    "Threads" -> OptionValue["Threads"]];
  If[Lookup[images, "Status", None] =!= "OK", Return[images]];
  epsValues = points[[All, 3]];
  sourcePoints = pointData["SourcePoints"];
  regularPointQ = ConstantArray[True, pointCount];
  degrees = Max /@ Transpose[Join[ConstantArray[0, {1, 3}],
    Cases[{eTables, cTables, letterTables, residueTables},
      (exponents_List -> _) :> exponents, Infinity]]];
  powers = MapThread[
    finiteFieldDeferredInhomogeneityPowers[#1, #2, prime] &,
    {Transpose[points], degrees}];
  poly[rules_] := finiteFieldDeferredInhomogeneityPolynomialAt[
    rules, powers, prime, pointCount];
  inverse[values_] := Module[{zero},
    zero = Flatten[Position[values, 0, {1}, Heads -> False]];
    If[zero =!= {}, regularPointQ[[zero]] = False];
    PowerMod[Replace[values, 0 -> 1, {1}], -1, prime]
  ];
  at[{rn_, rd_}] := Mod[poly[rn] inverse[poly[rd]], prime];
  dlogAt[{rn_, rd_}, mu_] := With[{n = poly[rn], d = poly[rd],
      dn = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rn, mu]],
      dd = poly[finiteFieldDeferredInhomogeneityDerivativeRules[rd, mu]]},
    Mod[Mod[dn inverse[n], prime] - Mod[dd inverse[d], prime], prime]];
  eValues = Map[at, eTables, {3}];
  cValues = Map[at, cTables, {3}];
  residues = Map[at, residueTables, {3}];
  dlogValues = Table[dlogAt[letterTables[[a]], mu],
    {a, Length[alphabet]}, {mu, 2}];

  representationSeconds = First[AbsoluteTiming[
    rationalMod[value_] := Module[{denominatorMod},
      If[! (IntegerQ[value] || Head[value] === Rational),
        failure = "CoefficientNotRational"; Return[0]];
      denominatorMod = Mod[Denominator[value], prime];
      If[denominatorMod === 0,
        failure = "CoefficientDenominatorSingular"; Return[0]];
      Mod[Mod[Numerator[value], prime]
        PowerMod[denominatorMod, -1, prime], prime]
    ];
    coefficientPolynomialValues[coefficients_List] := Fold[
      Mod[#1 epsValues + #2, prime] &,
      ConstantArray[0, pointCount],
      Reverse[rationalMod /@ coefficients]];
    coefficientAt[pair_Association] := Module[
      {numeratorCoefficients, denominatorCoefficients,
       numeratorValue, denominatorValue, zero},
      numeratorCoefficients = Lookup[pair, "NumeratorCoefficients", $Failed];
      denominatorCoefficients = Lookup[pair, "DenominatorCoefficients", $Failed];
      If[! MatchQ[numeratorCoefficients, {__}] ||
          ! MatchQ[denominatorCoefficients, {__}],
        failure = "CoefficientPairInvalid"; Return[ConstantArray[0, pointCount]]];
      numeratorValue = coefficientPolynomialValues[numeratorCoefficients];
      denominatorValue = coefficientPolynomialValues[denominatorCoefficients];
      zero = Flatten[Position[denominatorValue, 0, {1}, Heads -> False]];
      If[zero =!= {}, regularPointQ[[zero]] = False];
      Mod[numeratorValue PowerMod[
        Replace[denominatorValue, 0 -> 1, {1}], -1, prime], prime]
    ];
    numeratorCoefficientValues = Map[coefficientAt, numeratorPairs, {3}];
    denominatorCoefficientValues = coefficientAt /@ denominatorPairs;

    monomialValues[support_List, derivative_Integer] := Table[
      If[derivative > 0 && monomial[[derivative]] === 0, 0,
        Mod[If[derivative === 0, 1, monomial[[derivative]]]
          Product[PowerMod[sourcePoints[[b, mu]],
            monomial[[mu]] - Boole[derivative === mu], prime],
            {mu, 2}], prime]],
      {monomial, support}, {b, pointCount}];
    numeratorMonomials = monomialValues[numeratorSupport, 0];
    denominatorMonomials = monomialValues[denominatorSupport, 0];
    numeratorMonomialDerivatives = Table[
      monomialValues[numeratorSupport, mu], {mu, 2}];
    denominatorMonomialDerivatives = Table[
      monomialValues[denominatorSupport, mu], {mu, 2}];
    assemble[coefficientValues_, monomials_] :=
      Mod[Total[MapThread[Mod[#1 #2, prime] &,
        {coefficientValues, monomials}]], prime];
    numeratorValues = Map[
      assemble[#, numeratorMonomials] &, numeratorCoefficientValues, {2}];
    numeratorDerivatives = Table[Map[
        assemble[#, numeratorMonomialDerivatives[[mu]]] &,
        numeratorCoefficientValues, {2}], {mu, 2}];
    denominatorValues = assemble[
      denominatorCoefficientValues, denominatorMonomials];
    denominatorDerivatives = Table[assemble[
      denominatorCoefficientValues, denominatorMonomialDerivatives[[mu]]],
      {mu, 2}];
    inverseDenominator = inverse[denominatorValues];
    channelValues = Map[
      Mod[# inverseDenominator, prime] &, numeratorValues, {2}];
    channelDerivatives = Table[MapThread[
        Function[{derivativeNumerator, numerator},
          Mod[Mod[derivativeNumerator denominatorValues -
              numerator denominatorDerivatives[[mu]], prime]
            Mod[inverseDenominator inverseDenominator, prime], prime]],
        {numeratorDerivatives[[mu]], numeratorValues}, 2], {mu, 2}];

    selectedRootValues = If[rootCount === 0, {},
      MapThread[Mod[#1 #2, prime] &,
        {signs, Transpose[
          pointData["SquareRootGeneratorValues"][[All, rootIndices]]]}]];
    rootMonomialValues = Table[Fold[Mod[#1 #2, prime] &,
        ConstantArray[1, pointCount],
        Pick[selectedRootValues,
          Table[BitGet[grade - 1, bit - 1], {bit, rootCount}], 1]],
      {grade, gradeCount}];
    rootSquareExpressions = squareRootRecordRadicand /@
      plan["Roots"][[rootIndices]];
    rootSquareValues = If[rootCount === 0, {},
      Transpose[pointData["QuadraticRadicands"][[All, rootIndices]]]];
    rootSquareDerivativeValues = Table[With[{value =
        finiteFieldDeferredInhomogeneityModAt[
          D[rootSquareExpressions[[root]], sourceVariables[[mu]]],
          Join[AssociationThread[sourceVariables, sourcePoints[[b]]],
            <|epsilon -> epsValues[[b]]|>], prime]},
        If[value === $Failed,
          regularPointQ[[b]] = False; 0, value]],
      {mu, 2}, {root, rootCount}, {b, pointCount}];
    rootLogDerivatives = Table[Mod[
        rootSquareDerivativeValues[[mu, root]]
          PowerMod[2 rootSquareValues[[root]], -1, prime], prime],
      {mu, 2}, {root, rootCount}];
    rootMonomialDerivatives = Table[Mod[
        rootMonomialValues[[grade]] Total[Pick[
          rootLogDerivatives[[mu]],
          Table[BitGet[grade - 1, bit - 1], {bit, rootCount}], 1]], prime],
      {mu, 2}, {grade, gradeCount}];
    basisTransformationFlatValues = Table[Mod[Total[Table[
        channelValues[[entry, grade]] rootMonomialValues[[grade]],
        {grade, gradeCount}]], prime], {entry, entryCount}];
    basisTransformationFlatDerivatives = Table[Table[Mod[Total[Table[
          channelDerivatives[[mu, entry, grade]] rootMonomialValues[[grade]] +
          channelValues[[entry, grade]] rootMonomialDerivatives[[mu, grade]],
          {grade, gradeCount}]], prime], {entry, entryCount}], {mu, 2}];
    basisTransformationValues = ArrayReshape[
      basisTransformationFlatValues, Append[dimensions, pointCount]];
    basisTransformationDerivatives = Table[ArrayReshape[
        basisTransformationFlatDerivatives[[sourceMu]],
        Append[dimensions, pointCount]], {sourceMu, 2}];
    basisTransformationDerivatives = Table[Mod[Sum[Map[
          Mod[pointData["DifferentialPullbackMatrixValues"][[All,
              sourceMu, chartMu]] #, prime] &,
          basisTransformationDerivatives[[sourceMu]], {2}],
        {sourceMu, 2}], prime], {chartMu, 2}];
  ]];
  If[failure =!= None,
    Return[<|"Status" ->
      "DeferredInhomogeneityCoefficientRepresentationInvalid",
      "Reason" -> failure|>]];
  product[a_, b_] := Table[Mod[Total[Table[
      Mod[a[[i, k]] b[[k, j]], prime], {k, Length[b]}]], prime],
    {i, Length[a]}, {j, Length[First[b]]}];
  residual = Table[Mod[
      basisTransformationDerivatives[[mu]] -
        Map[Mod[epsValues #, prime] &,
          Mod[product[eValues[[mu]], basisTransformationValues] -
            product[basisTransformationValues, cValues[[mu]]], prime], {2}] -
        Transpose[images["Values"][[All, mu]], {3, 1, 2}] +
        Map[Mod[epsValues #, prime] &,
          Mod[Sum[Map[Mod[dlogValues[[a, mu]] #, prime] &,
            residues[[a]], {2}], {a, Length[alphabet]}], prime], {2}],
      prime], {mu, 2}];
  good = Pick[Range[pointCount], regularPointQ, True];
  ok = Length[good] >= Ceiling[pointCount/2] &&
    Flatten[residual[[All, All, All, good]]] ===
      ConstantArray[0, 2 Times @@ dimensions Length[good]];
  <|"Status" -> "OK", "ResidualZero" -> ok, "Prime" -> prime,
    "Points" -> Length[good], "RequestedPoints" -> pointCount,
    "Seed" -> OptionValue["Seed"], "TableSeconds" -> tableSeconds,
    "CoefficientEvaluationSeconds" -> representationSeconds,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
finiteFieldDeferredInhomogeneityCoefficientResidualQ[___] :=
  <|"Status" -> "DeferredInhomogeneityCoefficientResidualInvalid"|>;

End[];
