
(* Apply the global integral quotient to the explicit finite solutions.
   Shared constants refer to integral values at explicitly recorded points.
   If a lower-sector value is needed at another point, import its already
   computed finite solution, with all scalar integral definitions, at that
   fixed point. Nothing is represented by an unevaluated solution generator. *)

Clear[ReduceMasterIntegralSolutionConstants];
ClearAll[boundaryReductionRequiredDefinitions, boundaryReductionKnownValues, boundaryReductionPairs, boundaryReductionRationalOrder,
  boundaryReductionImportAtPoint];

boundaryReductionPairs[data_] := Sort@DeleteDuplicates@Cases[
  data["MasterIntegralCoefficients"],
  FeynFacetSolution`C[j_Integer, k_Integer] :> {j, k}, Infinity];

boundaryReductionRationalOrder[r_, epsilon_] :=
  Exponent[Numerator[r], epsilon, Min] -
    Exponent[Denominator[r], epsilon, Min];


(* Import only definitions reached by the requested fixed-point coefficients.
   Unused coefficients of the provider may have other singularities. *)
boundaryReductionRequiredDefinitions[source_, coefficients_] := Module[
  {a = source["AlgebraicDefinitions"], f = source["IntegralDefinitions"],
   k = source["KernelDefinitions"], ai, fi, ki, am, fm, km, rename, refs},
  ai = Union@Cases[coefficients, FeynFacetSolution`a[j_Integer] :> j, Infinity];
  fi = Union@Cases[coefficients, FeynFacetSolution`F[j_Integer, _] :> j, Infinity];
  ki = Union@Cases[coefficients, FeynFacetSolution`K[j_Integer, _] :> j, Infinity];
  Do[If[MemberQ[ai, i],
    ai = Union[ai, Cases[a[[i]], FeynFacetSolution`a[j_Integer] :> j, {0, Infinity}]];
    fi = Union[fi, Cases[a[[i]], FeynFacetSolution`F[j_Integer, _] :> j, {0, Infinity}]];
    ki = Union[ki, Cases[a[[i]], FeynFacetSolution`K[j_Integer, _] :> j, {0, Infinity}]]],
    {i, Length[a], 1, -1}];
  Do[If[MemberQ[fi, i],
    fi = Union[fi, Cases[f[[i]], FeynFacetSolution`F[j_Integer, _] :> j, Infinity]];
    ki = Union[ki, Cases[f[[i]], FeynFacetSolution`K[j_Integer, _] :> j, Infinity]]],
    {i, Length[f], 1, -1}];
  Do[If[MemberQ[ki, i],
    ki = Union[ki, Cases[k[[i]], FeynFacetSolution`K[j_Integer, _] :> j, Infinity]]],
    {i, Length[k], 1, -1}];
  am = AssociationThread[ai, Range[Length[ai]]];
  fm = AssociationThread[fi, Range[Length[fi]]];
  km = AssociationThread[ki, Range[Length[ki]]];
  rename[expr_] := expr /. {
    FeynFacetSolution`a[j_Integer] :> FeynFacetSolution`a[am[j]],
    FeynFacetSolution`F[j_Integer, t_] :> FeynFacetSolution`F[fm[j], t],
    FeynFacetSolution`K[j_Integer, t_] :> FeynFacetSolution`K[km[j], t]};
  Join[KeyTake[source, {"KinematicVariables","BasePoint","BranchPrescription"}],
    <|"AlgebraicDefinitions" -> rename[a[[ai]]],
      "IntegralDefinitions" -> Map[
        Join[rename[#], <|"Index" -> fm[#["Index"]]|>] &, f[[fi]]],
      "KernelDefinitions" -> Map[
        Join[rename[#], <|"Index" -> km[#["Index"]]|>] &, k[[ki]]],
      "MasterIntegralCoefficients" -> rename[coefficients]|>]
];


boundaryReductionImportAtPoint[target_, source_, point_] := Module[
  {ko, fo, ao, rename, rules, kernels, functions, algebra, coefficients},
  ko = Length[target["KernelDefinitions"]];
  fo = Length[target["IntegralDefinitions"]];
  ao = Length[target["AlgebraicDefinitions"]];
  rename[expr_] := expr /. {
    FeynFacetSolution`K[i_Integer, t_] :> FeynFacetSolution`K[i + ko, t],
    FeynFacetSolution`F[i_Integer, t_] :> FeynFacetSolution`F[i + fo, t],
    FeynFacetSolution`a[i_Integer] :> FeynFacetSolution`a[i + ao]};
  rules = Thread[source["KinematicVariables"] -> point];
  kernels = Map[Join[#, <|"Index" -> (#["Index"] + ko),
      "Expression" -> (rename[#["Expression"]] /. rules)|>] &,
    source["KernelDefinitions"]];
  functions = Map[Join[#, <|"Index" -> (#["Index"] + fo),
      "Integrand" -> (rename[#["Integrand"]] /. rules)|>] &,
    source["IntegralDefinitions"]];
  algebra = rename[source["AlgebraicDefinitions"]] /. rules;
  coefficients = rename[source["MasterIntegralCoefficients"]] /. rules;
  {Join[target, <|
    "KernelDefinitions" -> Join[target["KernelDefinitions"], kernels],
    "IntegralDefinitions" -> Join[target["IntegralDefinitions"], functions],
    "AlgebraicDefinitions" -> Join[target["AlgebraicDefinitions"], algebra]|>],
    coefficients}
];


boundaryReductionKnownValues[solutions_, basisRecords_, needed_] := Module[
  {known = {}, owner, row, rep, evaluation, value, epsilon, orders, series, rules},
  Do[
    orders = Last /@ Select[needed, First[#] === b["Index"] &];
    If[orders === {}, Continue[]];
    owner = solutions[b["MasterIntegral"][[1]]];
    row = FirstPosition[globalDEIdentity /@ owner["OriginalMasterIntegralBasis"],
      b["MasterIntegral"], None];
    If[row === None, Continue[]]; row = First[row];
    rep = Lookup[Lookup[Lookup[Lookup[owner,"ExpansionOrderDetermination",<||>],
      "IntegralRepresentationConstruction", <||>],
      "MasterIntegralRepresentations", <||>], row, None];
    If[! AssociationQ[rep], Continue[]];
    evaluation = miRepElementaryPhaseSpace[rep];
    If[! AssociationQ[evaluation], Continue[]];
    If[! AllTrue[evaluation["Terms"],
        Lookup[#, "IntegrationVariables", None] === {} &], Continue[]];
    value = Total[(#["Prefactor"] Lookup[#, "Integrand", 1]) & /@ evaluation["Terms"]];
    epsilon = rep["DimensionalRegulator"];
    series = Quiet@Check[Normal[Series[value, {epsilon, 0, Max[orders]}]], $Failed];
    If[series === $Failed || ! FreeQ[series, _SeriesData | _Derivative],
      Continue[]];
    rules = Table[FeynFacetSolution`C[b["Index"], k] ->
      Coefficient[Expand[series], epsilon, k], {k, orders}];
    AppendTo[known, <|"BoundaryIndex" -> b["Index"],
      "MasterIntegral" -> b["MasterIntegral"], "ReferencePoint" -> b["ReferencePoint"],
      "ExactValue" -> value, "DimensionalRegulator" -> epsilon,
      "Derivation" -> evaluation["ConstructionMethod"],
      "MeasureConvention" -> rep["MeasureConvention"],
      "CoefficientRules" -> rules|>],
    {b, basisRecords}];
  known
];

Options[ReduceMasterIntegralSolutionConstants] = {"EvaluateKnownIntegrals" -> True};

ReduceMasterIntegralSolutionConstants[solutions_Association,
    global_Association, OptionsPattern[]] := Catch@Module[
  {fail, basis, n, maps, points, lower, records, local, norms, i, j, owner,
   point, matrix, unitColumns, bound, remaining, completed = <||>,
   imports, importEvidence, current, rules, pairs, neededOwners, ready,
   family, coefficient, r, val, max, contribution, expression, h, k, q,
   epsilon, variables, makeConstant, getValue, copied, source, sourceRow,
   providerCoefficients, result, used, oldCount, seriesCoefficient,
   basisRecords, union, summary, demanded, known, knownRules,
   foreign, foreignByOwner, requestedProviderCoefficients, projected, substitution, fixedPointCoefficient},
  fail[tag_, extra_: <||>] := Throw[Failure[tag, extra]];
  If[Lookup[global, "DataType", None] =!= "GlobalMasterDifferentialSystem",
    fail["GlobalMasterDifferentialSystemRequired"]];
  If[!AllTrue[Values[solutions], AssociationQ[#] &&
      Lookup[#,"DataType",None] === "MasterIntegralSolution" &&
      Lookup[#,"SchemaVersion",None] === 3 &&
      ContainsAll[Keys[#], {"OriginalMasterIntegralBasis","BasePoint",
        "InitialConstants","InitialConstantLaurentLowerBounds","MasterIntegralCoefficients",
        "KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}] &],
    fail["FiniteMasterIntegralSolutionsRequired"]];
  If[AnyTrue[Values[solutions], KeyExistsQ[#, "BoundaryBasis"] &],
    fail["BoundaryBasisAlreadyReduced"]];
  basis = global["MasterIntegralBasis"]; n = Length[basis];
  variables = global["KinematicVariables"]; epsilon = global["DimensionalRegulator"];
  maps = Association[(#["Family"] -> #) & /@ global["FamilyMaps"]];
  If[Complement[Keys[solutions], Keys[maps]] =!= {}, fail["FamilyMapsIncomplete"]];
  points = Table[
    owner = basis[[j, 1]];
    If[! KeyExistsQ[solutions, owner], fail["RepresentativeSolutionRequired",
      <|"Master" -> basis[[j]]|>]];
    solutions[owner]["BasePoint"], {j, n}];
  lower = ConstantArray[-Infinity, n];
  (* Reuse stronger bounds only at the same point and through an exact
     unit identity. Bounds transported to other points are not guessed. *)
  Do[
    local = solutions[family]; matrix = Normal[maps[family]["IntegralEmbedding"]];
    Do[
      unitColumns = Select[Range[n], matrix[[i, #]] =!= 0 &];
      If[Length[unitColumns] === 1,
        j = First[unitColumns];
        bound = local["InitialConstantLaurentLowerBounds"][[i]];
        If[matrix[[i, j]] === 1 && local["BasePoint"] === points[[j]] &&
            IntegerQ[bound], lower[[j]] = Max[lower[[j]], bound]]],
      {i, Length[matrix]}],
    {family, Keys[solutions]}];
  demanded = Union@@Table[
    matrix = Normal[maps[family]["IntegralEmbedding"]];
    Union@@Map[Function[pair, Select[Range[n],
      matrix[[pair[[1]], #]] =!= 0 &]],
      boundaryReductionPairs[solutions[family]]],
    {family, Keys[solutions]}];
  If[AnyTrue[demanded, lower[[#]] === -Infinity &],
    fail["RepresentativeLaurentBoundsRequired", <|
      "Masters" -> basis[[Select[demanded, lower[[#]] === -Infinity &]]]|>]];
  lower = lower /. -Infinity -> Missing["NotRequired"];
  basisRecords = Table[<|"Index" -> j, "MasterIntegral" -> basis[[j]],
    "ReferencePoint" -> points[[j]], "LaurentLowerBound" -> lower[[j]]|>, {j, n}];
  remaining = Keys[solutions];
  While[remaining =!= {},
    ready = SelectFirst[remaining, Function[fam,
      local = solutions[fam]; point = local["BasePoint"];
      matrix = Normal[maps[fam]["IntegralEmbedding"]];
      pairs = boundaryReductionPairs[local];
      neededOwners = DeleteDuplicates@Flatten[Map[Function[pair,
        (basis[[#, 1]] & /@ Select[Range[n],
          matrix[[pair[[1]], #]] =!= 0 && point =!= points[[#]] &])], pairs]];
      AllTrue[neededOwners, KeyExistsQ[completed, #] &]], None];
    If[ready === None, fail["CyclicBasePointDependencies",
      <|"Families" -> remaining|>]];
    family = ready; local = solutions[family]; point = local["BasePoint"];
    matrix = Together /@ (Normal[maps[family]["IntegralEmbedding"]] /.
      Thread[variables -> point]);
    imports = <||>; importEvidence = {}; current = local;
    getValue[q_Integer, k_Integer] := Module[{own, cp, rowNumber, coeffs},
      If[k < lower[[q]] && point === points[[q]], Return[0]];
      If[point === points[[q]], Return[FeynFacetSolution`C[q, k]]];
      own = basis[[q, 1]];
      rowNumber = FirstPosition[
        globalDEIdentity /@ solutions[own]["OriginalMasterIntegralBasis"], basis[[q]], None];
      If[rowNumber === None, fail["RepresentativeMasterNotInSource", <|"Master" -> basis[[q]]|>]];
      rowNumber = First[rowNumber]; coeffs = completed[own]["MasterIntegralCoefficients"];
      cp = If[KeyExistsQ[coeffs, k], Lookup[Association[coeffs[k]], rowNumber, Missing[]], Missing[]];
      If[MissingQ[cp],
        (* The provider's own proven local bound also permits exact zeros. *)
        bound = solutions[own]["InitialConstantLaurentLowerBounds"][[rowNumber]];
        If[IntegerQ[bound] && k < bound, Return[0]];
        fail["FixedPointCoefficientOrderMissing", <|"Master" -> basis[[q]],
          "Order" -> k, "Point" -> point|>]];
      fixedPointCoefficient[q, k]
    ];
    seriesCoefficient[r_, h_] := seriesCoefficient[r, h] =
      Together[SeriesCoefficient[r, {epsilon, 0, h}]];
    pairs = boundaryReductionPairs[local];
    rules = Map[Function[pair,
      i = pair[[1]]; k = pair[[2]]; expression = 0;
      Do[
        r = matrix[[i, q]];
        If[r === 0, Continue[]];
        If[r === 1,
          expression += getValue[q, k],
          val = boundaryReductionRationalOrder[r, epsilon];
          (* For a cross-point provider use its declared bound, which may
             be weaker than the bound at the representative point. *)
          bound = If[point === points[[q]], lower[[q]],
            owner = basis[[q, 1]];
            sourceRow = First@FirstPosition[globalDEIdentity /@
              solutions[owner]["OriginalMasterIntegralBasis"], basis[[q]]];
            solutions[owner]["InitialConstantLaurentLowerBounds"][[sourceRow]]];
          If[! IntegerQ[bound], fail["LaurentBoundRequired"]];
          max = k - bound;
          Do[
            coefficient = seriesCoefficient[r, h];
            If[coefficient =!= 0, expression += coefficient getValue[q, k - h]],
            {h, val, max}]],
        {q, n}];
      FeynFacetSolution`C[i, k] -> expression], pairs];

    foreign = DeleteDuplicates@Cases[rules,
      fixedPointCoefficient[q_Integer,k_Integer] :> {q,k}, Infinity];
    foreignByOwner = GroupBy[foreign, basis[[First[#],1]] &];
    Do[
      source = completed[owner];
      requestedProviderCoefficients = foreignByOwner[owner];
      projected = GroupBy[requestedProviderCoefficients, Last,
        Function[requests, Map[Function[request,
          sourceRow = First@FirstPosition[globalDEIdentity /@
            source["OriginalMasterIntegralBasis"], basis[[request[[1]]]]];
          sourceRow -> Lookup[Association[source["MasterIntegralCoefficients"][request[[2]]]], sourceRow]
        ], requests]]];
      projected = Map[DeleteDuplicates, projected];
      source = boundaryReductionRequiredDefinitions[source, projected];
      copied = boundaryReductionImportAtPoint[current, source, point];
      current = First[copied]; AssociateTo[imports, owner -> Last[copied]];
      AppendTo[importEvidence, <|"SourceFamily" -> owner,
        "SourceBasePoint" -> source["BasePoint"], "EvaluationPoint" -> point,
        "Representation" -> "ExplicitFiniteNestedIntegrals",
        "ImportedScalarIntegralCount" -> Length[source["IntegralDefinitions"]],
        "ImportedKernelCount" -> Length[source["KernelDefinitions"]],
        "BranchPrescription" -> source["BranchPrescription"]|>],
      {owner, Keys[foreignByOwner]}];
    substitution = Map[Function[request,
      owner = basis[[request[[1]],1]];
      sourceRow = First@FirstPosition[globalDEIdentity /@
        completed[owner]["OriginalMasterIntegralBasis"], basis[[request[[1]]]]];
      fixedPointCoefficient[request[[1]],request[[2]]] ->
        Lookup[Association[imports[owner][request[[2]]]], sourceRow]
    ], foreign];
    rules = rules /. substitution;
    result = local["MasterIntegralCoefficients"] /. rules;
    oldCount = local["InitialConstants"]["Count"];
    current = Join[current, <|"SchemaVersion" -> 4,
      "SystemDimension" -> oldCount,
      "LocalInitialConstants" -> local["InitialConstants"],
      "LocalInitialConstantLaurentLowerBounds" -> local["InitialConstantLaurentLowerBounds"],
      "LocalInitialConstantLowerBoundInputs" -> Lookup[local,"InitialConstantLowerBoundInputs",{}],
      "InitialConstants" -> <|"Definition" ->
        "C[j,k] is the epsilon^k coefficient of BoundaryBasis[j].MasterIntegral at its ReferencePoint.",
        "KinematicsIndependent" -> True, "Count" -> n|>,
      "InitialConstantLaurentLowerBounds" -> lower,
      "InitialConstantLowerBoundInputs" -> ( <|"LowerBound" -> #["LaurentLowerBound"],
        "MasterIntegral" -> #["MasterIntegral"], "ReferencePoint" -> #["ReferencePoint"],
        "Method" -> "ReuseThroughExactIntegralIdentityAtTheSamePoint"|> & /@ basisRecords),
      "KernelDefinitionCounts" -> Counts[Lookup[current["KernelDefinitions"],"Kind","ScalarExpression"]],
      "BoundaryBasis" -> basisRecords,
      "MasterIntegralCoefficients" -> result,
      "LocalBoundaryCoefficientSubstitutions" -> Map[<|
        "LocalRow" -> First[#][[1]], "EpsilonOrder" -> First[#][[2]],
        "LocalPoint" -> point, "Expression" -> Last[#]|> &, rules],
      "FixedPointSolutionImports" -> importEvidence,
      "BoundaryReduction" -> <|"Method" -> "GlobalIntegralIdentitiesAndFixedPointSolutions",
        "PhysicalBoundaryConditionsApplied" -> False,
        "OriginalLocalConstantSeriesCount" -> Length[Union[First /@ pairs]]|>|>];
    used = boundaryReductionPairs[current];
    current = Join[current, <|"RequiredInitialConstantCoefficients" -> used,
      "BoundaryOrderRequirements" -> <|"RequiredCoefficients" -> used,
        "Basis" -> basisRecords, "OrderPropagation" -> "ExactLaurentConvolution"|>|>];
    AssociateTo[completed, family -> current];
    remaining = DeleteCases[remaining, family];
  ];
  union = Union@@(boundaryReductionPairs /@ Values[completed]);
  known = If[TrueQ[OptionValue["EvaluateKnownIntegrals"]],
    boundaryReductionKnownValues[solutions, basisRecords, union], {}];
  knownRules = Flatten[Lookup[#, "CoefficientRules", {}] & /@ known];
  If[knownRules =!= {},
    completed = Map[Function[sol,
      current = Join[sol, <|"MasterIntegralCoefficients" ->
        (sol["MasterIntegralCoefficients"] /. knownRules),
        "LocalBoundaryCoefficientSubstitutions" -> Map[
          Join[#, <|"Expression" -> (#["Expression"] /. knownRules)|>] &,
          sol["LocalBoundaryCoefficientSubstitutions"]],
        "KnownBoundaryValues" -> known|>];
      used = boundaryReductionPairs[current];
      current = Join[current, <|"RequiredInitialConstantCoefficients" -> used,
        "BoundaryOrderRequirements" -> Join[current["BoundaryOrderRequirements"],
          <|"RequiredCoefficients" -> used|>]|>];
      current], completed];
    union = Union@@(boundaryReductionPairs /@ Values[completed])];
  (* Validate the complete final expression once, after all substitutions.
     Rechecking it before and after each pass would dominate this reduction. *)
  Do[If[!FeynFacet`MasterIntegralSolutionQ[completed[family]],
    fail["ReducedFiniteSolutionInvalid", <|"Family" -> family|>]],
    {family, Keys[completed]}];
  <|"DataType" -> "ReducedMasterIntegralSolutionConstants", "SchemaVersion" -> 1,
    "Solutions" -> completed, "BoundaryBasis" -> basisRecords,
    "RequiredBoundarySeriesCount" -> Length[Union[First /@ union]],
    "RequiredLaurentCoefficientCount" -> Length[union],
    "RequiredBoundaryCoefficients" -> union,
    "KnownBoundaryValues" -> known,
    "PhysicalBoundaryConditionsApplied" -> (known =!= {}),
    "AsymptoticBoundaryConditionsApplied" -> False|>
];
