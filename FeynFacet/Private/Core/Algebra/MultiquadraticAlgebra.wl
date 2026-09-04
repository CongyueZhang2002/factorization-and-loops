(* The quadratic-generator quotient algebra (2026-08-23).

   One explicit ordering convention for computations with declared
   generators r_i and relations
   r_i^2 = delta_i: the grade masks, the character
   table, the xor-graded product with r_i^2 = delta_i, the derivative
   rule, reduction of a polynomial in the root symbols to the grade
   monomials, formal sign-change evaluation and projection, the split-point test,
   modular square roots, and the F2 grade lattice.

   This algebra becomes the usual multiquadratic field representation only
   after square-class independence has been established separately.  Nothing
   in this file promotes formal sign changes to Galois automorphisms.

   Source: Exchange/Codex/2026-08-22/04_triple_root_campaign/
   TripleRootAlgebra.wl (Codex, audited).  Semantics are preserved
   exactly; only the names are rehoused in FeynFacet`Private` and the
   two rank-0 fixes named in the promotion handoff are made explicit.

   Ordering is mathematical data, not an implementation detail.  Grade mask bit i
   always denotes declared generator i, so the caller -- not this file --
   owns the generator declaration order.  The ordered list itself is the
   source of truth; it is checked directly. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticBasisMasks, multiquadraticMaskFactor,
  multiquadraticParity, multiquadraticHadamardMatrix,
  multiquadraticCharacteristicNormalize, multiquadraticIntegerDataQ,
  multiquadraticMultiply,
  multiquadraticDerivative, multiquadraticToExpression,
  multiquadraticFromPolynomial, multiquadraticEvaluateSignChangeImages,
  multiquadraticProjectSignChangeImages,
  multiquadraticSquareRoots, multiquadraticGradeClosure,
  multiquadraticActiveRank, multiquadraticAlgebraProbe,
  $multiquadraticAlgebraProbeRank
];

$multiquadraticAlgebraProbeRank = 3;

multiquadraticBasisMasks[r_Integer?NonNegative] := Range[0, 2^r - 1];

multiquadraticMaskFactor[mask_Integer?NonNegative, values_List] :=
  Times @@ MapIndexed[If[BitGet[mask, First[#2] - 1] == 1, #1, 1] &, values];

multiquadraticParity[mask_Integer?NonNegative, rank_Integer?NonNegative] :=
  Mod[Total[BitGet[mask, Range[0, rank - 1]]], 2];

multiquadraticHadamardMatrix[rank_Integer?NonNegative] :=
  Table[If[multiquadraticParity[BitAnd[row, column], rank] == 0, 1, -1],
    {row, 0, 2^rank - 1}, {column, 0, 2^rank - 1}];

(* modulus 0 means characteristic zero: no reduction, exact Together.

   A positive modulus means F_p and therefore INTEGER data.  Mod on a
   Rational is the rational remainder, not the modular image
   (Mod[2/3, 10007] is 2/3), so the source's Mod[values, p] silently
   leaves a rational coefficient vector unreduced and every later
   comparison against a genuine field element is then false.  This port
   fails closed instead: a caller reduces its rationals first (the
   strip module's multiquadraticStripModRational does exactly that).
   Deviation from TripleRootAlgebra.wl line 32; no result that was
   correct there changes. *)
multiquadraticIntegerDataQ[values_] :=
  AllTrue[Flatten[{values}], IntegerQ];

multiquadraticCharacteristicNormalize[values_, 0] := Together /@ values;
multiquadraticCharacteristicNormalize[values_, p_Integer?Positive] :=
  If[multiquadraticIntegerDataQ[values], Mod[values, p], $Failed];

multiquadraticMultiply[a_List, b_List, deltas_List, modulus_: 0] /;
    Length[a] == Length[b] == 2^Length[deltas] :=
  Module[{rank = Length[deltas], out, common, target, term},
    out = ConstantArray[0, 2^rank];
    Do[
      common = BitAnd[left, right];
      target = BitXor[left, right];
      term = a[[left + 1]] b[[right + 1]] multiquadraticMaskFactor[common, deltas];
      out[[target + 1]] += term,
      {left, 0, 2^rank - 1}, {right, 0, 2^rank - 1}
    ];
    multiquadraticCharacteristicNormalize[out, modulus]
  ];

(* d(a_m r_m) = (a_m' + a_m/2 Sum_{i in m} dlog delta_i) r_m: the
   derivative never leaves its grade. *)
multiquadraticDerivative[a_List, deltas_List, x_] /; Length[a] == 2^Length[deltas] :=
  Table[
    Together[
      D[a[[mask + 1]], x] +
      a[[mask + 1]]/2 Sum[
        If[BitGet[mask, index] == 1, D[deltas[[index + 1]], x]/deltas[[index + 1]], 0],
        {index, 0, Length[deltas] - 1}
      ]
    ],
    {mask, 0, 2^Length[deltas] - 1}
  ];

multiquadraticToExpression[a_List, roots_List] /; Length[a] == 2^Length[roots] :=
  Total[MapThread[#1 multiquadraticMaskFactor[#2, roots] &,
    {a, multiquadraticBasisMasks[Length[roots]]}]];

(* Rank 0 has the sole rational channel, and a fractional power is not
   a rational coefficient: it must fail closed rather than be reported
   as a grade-0 channel (the declared-root census is quadratic).  The
   rejection is applied at every rank, so a caller that hands in an
   undeclared radical never receives a silently wrong reduction. *)
multiquadraticFromPolynomial[expr_, roots_List, deltas_List] /;
    Length[roots] == Length[deltas] :=
  Module[{remainder, rules, out, exponents, mask},
    If[! FreeQ[expr, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
      Return[$Failed]];
    If[roots === {}, Return[{Together[expr]}]];
    remainder = Last[PolynomialReduce[
      Expand[expr],
      MapThread[#1^2 - #2 &, {roots, deltas}],
      roots
    ]];
    rules = CoefficientRules[remainder, roots];
    out = ConstantArray[0, 2^Length[roots]];
    Do[
      exponents = First[rule];
      mask = Total[exponents 2^Range[0, Length[roots] - 1]];
      out[[mask + 1]] += Last[rule],
      {rule, rules}
    ];
    Together /@ out
  ];

multiquadraticEvaluateSignChangeImages[
    a_List, rootValues_List, modulus_: 0] /;
    Length[a] == 2^Length[rootValues] :=
  Module[{weighted, result},
    weighted = MapThread[#1 #2 &,
      {a, multiquadraticMaskFactor[#, rootValues] & /@
        multiquadraticBasisMasks[Length[rootValues]]}];
    result = multiquadraticHadamardMatrix[Length[rootValues]].weighted;
    If[modulus === 0, Together /@ result,
      If[multiquadraticIntegerDataQ[{a, rootValues}], Mod[result, modulus],
        $Failed]]
  ];

multiquadraticProjectSignChangeImages[
    values_List, rootValues_List, modulus_: 0] /;
    Length[values] == 2^Length[rootValues] :=
  Module[{rank = Length[rootValues], rootProducts, weighted},
    rootProducts = multiquadraticMaskFactor[#, rootValues] & /@
      multiquadraticBasisMasks[rank];
    If[modulus === 0,
      weighted = multiquadraticHadamardMatrix[rank].values/2^rank;
      Together /@ MapThread[#1/#2 &, {weighted, rootProducts}],
      If[! multiquadraticIntegerDataQ[{values, rootValues}], Return[$Failed]];
      weighted = Mod[PowerMod[2^rank, -1, modulus] (
        multiquadraticHadamardMatrix[rank].values), modulus];
      Mod[MapThread[#1 PowerMod[#2, -1, modulus] &,
        {weighted, Mod[rootProducts, modulus]}], modulus]
    ]
  ];

(* p = 3 (mod 4) only; the returned representative is the raw
   exponentiation, NOT the smaller of the two roots.  The sign
   representative is part of the ABI: see the differential test
   against FamilyRowGaugeFiniteField.wl, which normalizes instead. *)
(* one implementation (Core/ModularArithmetic.wl, overhaul 2026-09-02):
   the former definition existed only for p == 3 (mod 4); every odd prime
   is now admissible (Tonelli-Shanks for p == 1 (mod 4)), which removes
   the class of wasted split-point searches recorded on 2026-08-31 *)
multiquadraticSquareRoots[values_List, p_Integer?Positive] :=
  modularSquareRoots[values, p];

multiquadraticGradeClosure[seeds_List, generators_List] :=
  FixedPoint[
    Function[current,
      Union[current, Flatten[Table[BitXor[grade, generator],
        {grade, current}, {generator, generators}]]]
    ],
    Union[seeds]
  ];

multiquadraticActiveRank[masks_List, rank_Integer?NonNegative] :=
  If[masks === {} || masks === {0}, 0,
    MatrixRank[BitGet[#, Range[0, rank - 1]] & /@ DeleteCases[Union[masks], 0],
      Modulus -> 2]
  ];

(* The explicit semantics probe: ordering (masks, character table) and
   one product and derivative at every supported rank.  Tests compare
   this mathematical data directly with SameQ. *)
multiquadraticAlgebraProbe[] := Module[
  {deltas, a, b},
  Table[
    deltas = Take[{\[FormalX], \[FormalY], 1 + \[FormalX] + \[FormalY]}, rank];
    a = Table[(1 + mask + \[FormalX])/(2 + mask + \[FormalY]),
      {mask, 0, 2^rank - 1}];
    b = Table[((-1)^mask (3 + mask) + \[FormalY])/(1 + mask + \[FormalX] + \[FormalY]),
      {mask, 0, 2^rank - 1}];
    {rank,
     multiquadraticBasisMasks[rank],
     multiquadraticHadamardMatrix[rank],
     multiquadraticMultiply[a, b, deltas],
     multiquadraticDerivative[a, deltas, \[FormalX]]},
    {rank, 0, $multiquadraticAlgebraProbeRank}]
];

(* ------------------------------------------------------------------ *)
(*  Square-root and radical algebra of coefficient presentations       *)
(*  (moved from Geometry/TransportCharts.wl, layer pass                 *)
(*  2026-09-02: EpsForm loads before Geometry and these are the         *)
(*  helpers every EpsForm solver calls -- radical bases, exact          *)
(*  denesting, generator classification, sign-image application, the    *)
(*  algebraic zero test and presentation re-keying; no catalog logic)   *)
(* ------------------------------------------------------------------ *)

ClearAll[
  squareRootRecordExpression,
  squareRootRecordRadicand,
  algebraCoefficientPresentationNormalize,
  algebraSourceVariableRepresentationRecordQ,
  algebraRationalizingParametrizationRecordQ,
  algebraSquareRootGeneratorRelationsRecordQ,
  algebraRationalFunctionQ,
  algebraCoefficientPresentationMapRationalQ,
  algebraSourceVariableRepresentationIdentityVerifiedQ,
  algebraRationalizedSquareRootImagesRationalQ,
  algebraSquareRootGeneratorRadicandsRationalQ,
  algebraRationalizedSquareRootIdentitiesVerifiedQ,
  algebraSquareRootGeneratorIdentitiesVerifiedQ,
  coefficientPresentationSquareRootRecords,
  rekeyCoefficientPresentation,
  coefficientPresentationSquareRootsInVariables,
  transportChartRadicalBases,
  transportChartNumericSquareClass,
  transportChartSquareSplit,
  transportChartExactSquareRoot,
  transportChartSquareClassData,
  transportChartDenestRadicalBase,
  transportChartDenestSign,
  transportChartCanonicalizeDenestedRadicals,
  transportChartRootIndices,
  transportChartRootBranchScale,
  transportChartApplyRootBranches,
  transportChartDeclaredRadicalGenerators,
  transportChartAlgebraicZeroQ
];

squareRootRecordExpression[record_Association] := Lookup[record,
  "Generator", Lookup[record, "RationalRoot",
    Missing["SquareRootExpressionNotAvailable"]]];

squareRootRecordRadicand[record_Association] := Which[
  KeyExistsQ[record, "QuadraticRadicand"], record["QuadraticRadicand"],
  KeyExistsQ[record, "RationalRoot"], Together[record["RationalRoot"]^2],
  True, Missing["SquareRootRadicandNotAvailable"]
];

(* Algebra loads before Core/Charts, so its V2 discriminator is kept
   self-contained.  Generated V1 records are a typed refusal. *)
algebraCoefficientPresentationNormalize[input_Association] := Which[
  MemberQ[{"LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
    Lookup[input, "Status", None]],
    <|"Status" -> Lookup[input, "Status"]|>,
  KeyExistsQ[input, "QuadraticRelations"] ||
      (ListQ[Lookup[input, "SquareRootGenerators", $Failed]] &&
        AnyTrue[input["SquareRootGenerators"], Function[generator,
          AssociationQ[generator] &&
            AnyTrue[{"GeneratorIndex", "GeneratorExpression"},
              KeyExistsQ[generator, #] &]]]),
    <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>,
  Lookup[input, "DataType", None] === "SourceVariableRepresentation" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "CoefficientVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
        {_Rule, _Rule}] &&
      MatrixQ[Lookup[input, "DifferentialPullbackMatrix", $Failed]],
    <|
      "DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "Status" -> Lookup[input, "Status", "OK"],
      "SourceVariables" -> input["SourceVariables"],
      "CoefficientVariables" -> input["CoefficientVariables"],
      "SourceVariableSubstitution" -> input["SourceVariableSubstitution"],
      "DifferentialPullbackMatrix" ->
        input["DifferentialPullbackMatrix"],
      "JacobianDeterminant" -> Lookup[input, "JacobianDeterminant", 1]|>,
  KeyExistsQ[input, "RationalizedSquareRoots"] &&
      KeyExistsQ[input, "ParametrizingVariables"] &&
      KeyExistsQ[input, "SourceVariableSubstitution"] &&
      KeyExistsQ[input, "SquareRootGenerators"] &&
      KeyExistsQ[input, "SourceToCoefficientVariableRules"],
    <|"Status" -> "CoefficientPresentationSchemaAmbiguous"|>,
  Lookup[input, "DataType", None] === "RationalizingParametrization" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      ListQ[Lookup[input, "RationalizedSquareRoots", $Failed]] &&
      KeyExistsQ[input, "ParametrizingVariables"] &&
      KeyExistsQ[input, "SourceVariableSubstitution"],
    Join[<|
      "DataType" -> "RationalizingParametrization",
      "SchemaVersion" -> 2,
      "Status" -> Lookup[input, "Status",
        "RationalizingParametrizationDeclared"],
      "Name" -> Lookup[input, "Name",
        "UnnamedRationalizingParametrization"],
      "Kind" -> Lookup[input, "Kind", "TwoVariable"],
      "ParametrizingVariables" -> input["ParametrizingVariables"],
      "SourceVariables" -> Lookup[input, "SourceVariables",
        First /@ input["SourceVariableSubstitution"]],
      "SourceVariableSubstitution" -> input["SourceVariableSubstitution"],
      "RationalizedSquareRoots" -> Map[
        <|"RationalRoot" -> Lookup[#, "RationalRoot", Missing[]],
          "SourceRadicand" -> Lookup[#, "SourceRadicand", Missing[]]|> &,
        input["RationalizedSquareRoots"]],
      "ParentParametrizationMaps" ->
        Lookup[input, "ParentParametrizationMaps", <||>],
      "ParentParametrizations" ->
        Map[If[AssociationQ[#],
            algebraCoefficientPresentationNormalize[#], #] &,
          Lookup[input, "ParentParametrizations", <||>]]|>,
      KeyTake[input, {"InverseParametrizationByRootValues", "Notes"}]],
  Lookup[input, "DataType", None] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "CoefficientVariables", $Failed],
        {_Symbol, _Symbol}] &&
      ListQ[Lookup[input, "SquareRootGenerators", $Failed]] &&
      KeyExistsQ[input, "SourceToCoefficientVariableRules"],
    Module[{generators},
      generators = Map[
        <|"Generator" -> Lookup[#, "Generator", Missing[]],
          "QuadraticRadicand" ->
            Lookup[#, "QuadraticRadicand", Missing[]],
          "SourceRadicand" -> Lookup[#, "SourceRadicand", Missing[]]|> &,
        input["SquareRootGenerators"]];
      <|
        "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
        "SchemaVersion" -> 2,
        "Status" -> Lookup[input, "Status",
          "SquareRootGeneratorRelationsUnverified"],
        "SourceVariables" -> Lookup[input, "SourceVariables", Missing[]],
        "CoefficientVariables" ->
          Lookup[input, "CoefficientVariables", Missing[]],
        "SourceToCoefficientVariableRules" ->
          input["SourceToCoefficientVariableRules"],
        "SquareRootGenerators" -> generators,
        "SquareClassIndependenceStatus" -> "NotChecked",
        "SquareClassIndependenceVerified" -> False,
        "SignChangeImageInterpretation" ->
          "FormalGeneratorSignChangesOnly",
        "GaloisConjugatesCertified" -> False|>],
  AnyTrue[{"Variables", "Subst", "Roots", "RootSquare", "FieldKind",
      "CoefficientField", "GeneratorOrdering"}, KeyExistsQ[input, #] &] ||
      MemberQ[{"SourceVariableRepresentation",
        "RationalizingParametrization",
        "SquareRootGeneratorsAndQuadraticRelations"},
        Lookup[input, "DataType", None]],
    <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>,
  True, <|"Status" -> "CoefficientPresentationNotWellFormed"|>
];

algebraSourceVariableRepresentationRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] === "SourceVariableRepresentation" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "CoefficientVariables", $Failed],
    {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
    {_Rule, _Rule}] &&
  MatrixQ[Lookup[input, "DifferentialPullbackMatrix", $Failed]];

algebraRationalizingParametrizationRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] === "RationalizingParametrization" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "ParametrizingVariables", $Failed],
    {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
    {_Rule, _Rule}] &&
  ListQ[Lookup[input, "RationalizedSquareRoots", $Failed]];

algebraSquareRootGeneratorRelationsRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] ===
    "SquareRootGeneratorsAndQuadraticRelations" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "CoefficientVariables", $Failed],
    {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceToCoefficientVariableRules", $Failed],
    {_Rule, _Rule}] &&
  ListQ[Lookup[input, "SquareRootGenerators", $Failed]];

algebraRationalFunctionQ[expression_, variables_List] := Module[{value},
  value = Together[expression];
  FreeQ[value,
    Power[_, _Rational] | _Root | Log | Hypergeometric2F1] &&
    PolynomialQ[Numerator[value], variables] &&
    PolynomialQ[Denominator[value], variables]
];

algebraCoefficientPresentationMapRationalQ[
    presentation_Association] := Module[{variables, substitution},
  {variables, substitution} = Which[
    Lookup[presentation, "DataType", None] ===
        "SourceVariableRepresentation",
      {Lookup[presentation, "SourceVariables", $Failed],
       Lookup[presentation, "SourceVariableSubstitution", $Failed]},
    KeyExistsQ[presentation, "RationalizedSquareRoots"],
      {Lookup[presentation, "ParametrizingVariables", $Failed],
       Lookup[presentation, "SourceVariableSubstitution", $Failed]},
    KeyExistsQ[presentation, "SquareRootGenerators"],
      {Lookup[presentation, "CoefficientVariables", $Failed],
       Lookup[presentation, "SourceToCoefficientVariableRules", $Failed]},
    True, {$Failed, $Failed}];
  MatchQ[variables, {_Symbol, _Symbol}] &&
    MatchQ[substitution, {_Rule, _Rule}] &&
    AllTrue[Last /@ substitution,
      algebraRationalFunctionQ[#, variables] &]
];

algebraSourceVariableRepresentationIdentityVerifiedQ[
    presentation_Association] := Module[
  {sourceVariables, coefficientVariables, substitution, pullback},
  sourceVariables = Lookup[presentation, "SourceVariables", $Failed];
  coefficientVariables = Lookup[presentation,
    "CoefficientVariables", $Failed];
  substitution = Lookup[presentation,
    "SourceVariableSubstitution", $Failed];
  pullback = Lookup[presentation, "DifferentialPullbackMatrix", $Failed];
  MatchQ[sourceVariables, {_Symbol, _Symbol}] &&
    coefficientVariables === sourceVariables &&
    substitution === Thread[sourceVariables -> sourceVariables] &&
    pullback === IdentityMatrix[2] &&
    Lookup[presentation, "JacobianDeterminant", 1] === 1
];

algebraRationalizedSquareRootImagesRationalQ[
    presentation_Association] := Module[{variables, roots},
  variables = Lookup[presentation, "ParametrizingVariables", $Failed];
  roots = Lookup[presentation, "RationalizedSquareRoots", $Failed];
  MatchQ[variables, {_Symbol, _Symbol}] && ListQ[roots] &&
    AllTrue[roots, AssociationQ[#] &&
      algebraRationalFunctionQ[
        Lookup[#, "RationalRoot", Missing[]], variables] &]
];

algebraSquareRootGeneratorRadicandsRationalQ[
    presentation_Association] := Module[{variables, generators},
  variables = Lookup[presentation, "CoefficientVariables", $Failed];
  generators = Lookup[presentation, "SquareRootGenerators", $Failed];
  MatchQ[variables, {_Symbol, _Symbol}] && ListQ[generators] &&
    AllTrue[generators, AssociationQ[#] &&
      algebraRationalFunctionQ[
        Lookup[#, "QuadraticRadicand", Missing[]], variables] &]
];

algebraRationalizedSquareRootIdentitiesVerifiedQ[
    presentation_Association] := Module[
  {variables, substitution, roots},
  variables = Lookup[presentation, "ParametrizingVariables", $Failed];
  substitution = Lookup[presentation,
    "SourceVariableSubstitution", $Failed];
  roots = Lookup[presentation, "RationalizedSquareRoots", $Failed];
  MatchQ[variables, {_Symbol, _Symbol}] &&
    MatchQ[substitution, {_Rule, _Rule}] && ListQ[roots] &&
    algebraCoefficientPresentationMapRationalQ[presentation] &&
    algebraRationalizedSquareRootImagesRationalQ[presentation] &&
    AllTrue[roots, Function[root,
      AssociationQ[root] &&
        TrueQ[Together[
          Lookup[root, "RationalRoot", Missing[]]^2 -
            (Lookup[root, "SourceRadicand", Missing[]] /.
              substitution)] === 0]]]
];

algebraSquareRootGeneratorIdentitiesVerifiedQ[
    presentation_Association] := Module[
  {variables, substitution, generators},
  variables = Lookup[presentation, "CoefficientVariables", $Failed];
  substitution = Lookup[presentation,
    "SourceToCoefficientVariableRules", $Failed];
  generators = Lookup[presentation, "SquareRootGenerators", $Failed];
  MatchQ[variables, {_Symbol, _Symbol}] &&
    MatchQ[substitution, {_Rule, _Rule}] && ListQ[generators] &&
    algebraCoefficientPresentationMapRationalQ[presentation] &&
    algebraSquareRootGeneratorRadicandsRationalQ[presentation] &&
    AllTrue[generators, Function[generator,
      AssociationQ[generator] &&
        TrueQ[Together[
          Lookup[generator, "Generator", Missing[]]^2 -
            Lookup[generator, "QuadraticRadicand", Missing[]]] === 0] &&
        TrueQ[Together[
          Lookup[generator, "QuadraticRadicand", Missing[]] -
            (Lookup[generator, "SourceRadicand", Missing[]] /.
              substitution)] === 0]]]
];

coefficientPresentationSquareRootRecords[input_Association] := Module[
  {presentation = algebraCoefficientPresentationNormalize[input]},
  If[MemberQ[{
      "LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
      Lookup[presentation, "Status", None]],
    Return[presentation]];
  If[algebraSourceVariableRepresentationRecordQ[presentation],
    Return[If[
      algebraSourceVariableRepresentationIdentityVerifiedQ[presentation],
      {}, <|"Status" ->
        "SourceVariableRepresentationIdentityFailed"|>]]];
  If[(KeyExistsQ[presentation, "RationalizedSquareRoots"] ||
       KeyExistsQ[presentation, "SquareRootGenerators"]) &&
      ! algebraCoefficientPresentationMapRationalQ[presentation],
    Return[<|"Status" -> "CoefficientPresentationMapNotRational"|>]];
  If[ListQ[Lookup[presentation, "RationalizedSquareRoots", $Failed]] &&
      ! algebraRationalizedSquareRootImagesRationalQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationRootImageNotRational"|>]];
  If[ListQ[Lookup[presentation, "SquareRootGenerators", $Failed]] &&
      ! algebraSquareRootGeneratorRadicandsRationalQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorQuadraticRadicandNotRational"|>]];
  If[ListQ[Lookup[presentation, "SquareRootGenerators", $Failed]] &&
      ! algebraSquareRootGeneratorIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorRelationVerificationFailed"|>]];
  If[ListQ[Lookup[presentation, "RationalizedSquareRoots", $Failed]] &&
      ! algebraRationalizedSquareRootIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationSquareRootIdentityFailed"|>]];
  Which[
    ListQ[Lookup[presentation, "SquareRootGenerators", $Failed]],
      presentation["SquareRootGenerators"],
    ListQ[Lookup[presentation, "RationalizedSquareRoots", $Failed]],
      presentation["RationalizedSquareRoots"],
    True, $Failed]
];


transportChartRadicalBases[expr_] := Module[{raw},
  (* A large connection repeats the same declared roots hundreds of
     thousands of times.  Normalize each distinct syntactic radicand once,
     not once per occurrence, then merge algebraically identical images. *)
  raw = DeleteDuplicates[Cases[Unevaluated[expr],
    Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
      base, {0, Infinity}, Heads -> True]];
  DeleteDuplicates[Together /@ raw]
];

(* ------------------------------------------------------------------ *)
(*  Square classes and the denesting of nested radical bases            *)
(* ------------------------------------------------------------------ *)
(* WHY (2026-08-24, CF303).  The syntactic matcher below classifies a
   radical only when its radicand IS a declared root square.  The CF303
   family connection carries radicands that are declared squares times a
   NESTED radical, e.g.

     q2 (u + v Sqrt[q1]),  u = 1+2x+x^2+2xy+y^2, v = 1+x+y,

   and bare numeric radicands (Sqrt[2]).  Both reduce in the displayed
   quadratic-relation quotient: with w^2 = u^2 - v^2 q1 = (2y)^2 exactly,
   u + w = (1+x+y)^2, hence 2 (u + v Sqrt[q1]) = ((1+x+y) + Sqrt[q1])^2
   and the radicand's square class is 2 q2 -- declared root 2 times the
   numeric class 2, no new field extension.  Refusing such a connection
   as "undeclared radicals" was a matcher limitation, not a mathematical
   obstruction.  The classification is exact throughout (Fermat
   denesting); only the global SIGN of a rewrite is fixed numerically,
   in transportChartDenestSign, and the identity rewrite^2 == base is
   checked exactly and is sign-independent. *)

(* Sqrt[p/q] = Sqrt[p q]/q, so the square class of a rational number is
   the squarefree part of numerator*denominator.  The sign is kept: a
   negative class means the radical is imaginary, which is data, not an
   error. *)
transportChartNumericSquareClass[value_] := Module[{r, sign, n, d},
  r = Together[value];
  If[! MatchQ[r, _Integer | _Rational], Return[$Failed]];
  If[r === 0, Return[0]];
  sign = Sign[r]; r = Abs[r];
  n = Numerator[r]; d = Denominator[r];
  sign Times @@ (First[#]^Mod[Last[#], 2] & /@ FactorInteger[n d])];

(* g = class h^2 with class squarefree: the squarefree rational content
   times every irreducible factor of odd multiplicity, once. *)
transportChartSquareSplit[g_] := Module[
  {expression, list, numeric, polynomials, sign, n, d, k, m, class, h},
  expression = Together[g];
  If[TrueQ[expression === 0], Return[{0, 0}]];
  list = FactorList[expression];
  numeric = Times @@ (First[#]^Last[#] & /@ Select[list, NumericQ[First[#]] &]);
  If[! MatchQ[numeric, _Integer | _Rational], Return[$Failed]];
  polynomials = Select[list, ! NumericQ[First[#]] &];
  sign = Sign[numeric];
  n = Numerator[Abs[numeric]]; d = Denominator[Abs[numeric]];
  k = transportChartNumericSquareClass[Abs[numeric]];
  m = Sqrt[(n d)/k];
  If[! IntegerQ[m], Return[$Failed]];
  class = sign k Times @@ (First[#]^Mod[Last[#], 2] & /@ polynomials);
  h = (m/d) Times @@
    (First[#]^Quotient[Last[#] - Mod[Last[#], 2], 2] & /@ polynomials);
  {Together[class], Together[h]}];

(* the exact square root of a rational function, or $Failed *)
transportChartExactSquareRoot[g_] := Module[{split},
  split = transportChartSquareSplit[g];
  If[split === $Failed, Return[$Failed]];
  If[TrueQ[Together[First[split] - 1] === 0] &&
      TrueQ[Together[Last[split]^2 - g] === 0],
    Together[Last[split]], $Failed]];

(* expr == NumericClass Product[declared squares] Factor^2, verified
   exactly, or a typed refusal naming the factors that match no declared
   square.  Matching is sign- and numeric-multiple-insensitive: a factor
   equal to a rational multiple of a declared square contributes that
   root index and moves the multiple into the numeric class. *)
transportChartSquareClassData[expr_, rootBases_List] := Module[
  {class, h, split, list, numeric = 1, indices = {}, unmatched = {}, whole,
   numericClass, mu, factor},
  split = transportChartSquareSplit[expr];
  If[split === $Failed,
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  {class, h} = split;
  If[class === 0, Return[<|"Status" -> "ZeroSquareClass"|>]];
  (* the whole class first: a declared square may be reducible *)
  whole = SelectFirst[Range[Length[rootBases]],
    Module[{ratio = Together[class/rootBases[[#]]]},
      MatchQ[ratio, _Integer | _Rational] && ratio =!= 0] &, 0];
  If[whole > 0,
    indices = {whole}; numeric = Together[class/rootBases[[whole]]],
    list = FactorList[class];
    Do[Module[{f = First[entry], e = Last[entry], match},
      Which[
        NumericQ[f], numeric *= f^e,
        EvenQ[e], Null,
        True,
          match = SelectFirst[Range[Length[rootBases]],
            Module[{ratio = Together[f/rootBases[[#]]]},
              MatchQ[ratio, _Integer | _Rational] && ratio =!= 0] &, 0];
          If[match > 0,
            AppendTo[indices, match];
            numeric *= Together[f/rootBases[[match]]]^e,
            AppendTo[unmatched, f^e]]]],
      {entry, list}]];
  If[unmatched =!= {},
    Return[<|"Status" -> "UnmatchedSquareClassFactors",
      "Unmatched" -> unmatched|>]];
  numericClass = transportChartNumericSquareClass[numeric];
  If[numericClass === $Failed,
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  mu = Sqrt[Together[numeric/numericClass]];
  If[! MatchQ[mu, _Integer | _Rational],
    Return[<|"Status" -> "NonRationalSquareClassContent"|>]];
  factor = Together[mu h];
  indices = Sort[DeleteDuplicates[indices]];
  If[! TrueQ[Together[
      numericClass Times @@ rootBases[[indices]] factor^2 - expr] === 0],
    Return[<|"Status" -> "SquareClassIdentityFailed"|>]];
  <|"Status" -> "OK", "RootIndices" -> indices,
    "NumericClass" -> numericClass, "Factor" -> factor|>];

(* Denest ONE radical base against the declared root set.  Returns
     <|"Status" -> "Denested", "RootIndices" -> {...} (the square class),
       "NumericClass" -> c, "Residual" -> 1, "InnerRootIndices" -> {...}
       (declared roots that survive INSIDE the rewrite),
       "Rewrite" -> expression in declared radicals, up to a global sign,
       "SquareIdentity" -> True, "Witness" -> <|"u","v","w","Square"|>|>
   or one of the typed refusals "NotDenestable" (with a "Reason") and
       "NestedMultiRootRadical".  The variables are the coefficient
   variables of the presentation; the algorithm itself is
   variable-agnostic and treats any other symbol (the regulator, say) as
   a coefficient-ring parameter.  RootIndices and InnerRootIndices are
   retained only as a private compatibility ABI for internal callers. *)
transportChartDenestRadicalBase[base_, roots_List, variables_List] := Module[
  {rootBases, symbols, substitute, reduceRules, reduce, toRatio, zeroQ,
   ratio, num, den, normal, list, numeric, sign, n, d, k, m, hPoly, rFree,
   fRaw, fPart, present, index, u, v, discriminant, w, branch, g, c, h, split,
   alpha, beta, verified, solved, classExpr, classData, rootImages, rewrite,
   witness, check},
  If[! MatchQ[variables, {___Symbol}],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "InvalidVariables"|>]];
  rootBases = Together /@ (squareRootRecordExpression[#]^2 & /@ roots);

  (* (i) a purely numeric radicand is chart independent *)
  If[NumericQ[base] && FreeQ[base, _Complex],
    k = transportChartNumericSquareClass[base];
    If[k === $Failed, Return[<|"Status" -> "NotDenestable",
      "Reason" -> "NonRationalNumericRadicand"|>]];
    Return[<|"Status" -> "Denested", "RootIndices" -> {},
      "NumericClass" -> k, "Residual" -> 1, "InnerRootIndices" -> {},
      "Rewrite" -> Sqrt[Together[base/k]] Sqrt[k], "SquareIdentity" -> True,
      "Witness" -> <|"Kind" -> "Numeric", "u" -> base, "v" -> 0, "w" -> 0,
        "Square" -> Together[base/k]|>|>]];

  (* (ii) declared radicals become polynomial generators r_i, r_i^2 = q_i *)
  symbols = Table[Unique["FeynFacet`Private`denestRoot"], {Length[rootBases]}];
  substitute[expression_] := expression /.
    Power[b_, e_Rational /; Denominator[e] === 2] :>
      Module[{position = FirstPosition[rootBases,
          q_ /; TrueQ[Together[b - q] === 0], Missing["NoRoot"], {1},
          Heads -> False]},
        If[MissingQ[position], Power[b, e], symbols[[First[position]]]^(2 e)]];
  reduceRules = Table[With[{s = symbols[[i]], q = rootBases[[i]]},
      s^e_Integer /; e >= 2 :> q^Quotient[e, 2] s^Mod[e, 2]],
    {i, Length[symbols]}];
  reduce[p_] := FixedPoint[Expand[# /. reduceRules] &, Expand[p]];
  (* {numerator, denominator} with the generators cleared from the
     denominator by conjugation and every generator power reduced.
     Numeric radicals (the class constants our own rewrite introduces)
     ride along as exact constants; an undeclared SYMBOLIC radical is
     refused before this is reached. *)
  toRatio[expression_] := Module[{c0, nu, de, i},
    c0 = Together[substitute[expression]];
    nu = reduce[Numerator[c0]]; de = reduce[Denominator[c0]];
    Do[If[! FreeQ[de, symbols[[i]]],
        Module[{conjugate = reduce[de /. symbols[[i]] -> -symbols[[i]]]},
          nu = reduce[nu conjugate]; de = reduce[de conjugate]]],
      {i, Length[symbols]}];
    If[! FreeQ[de, Alternatives @@ symbols], $Failed, {nu, de}]];
  zeroQ[e1_, e2_] := Module[{a = toRatio[e1], b = toRatio[e2]},
    a =!= $Failed && b =!= $Failed &&
      TrueQ[Together[reduce[a[[1]] b[[2]] - b[[1]] a[[2]]]] === 0]];

  If[! FreeQ[substitute[base], Power[_, e_Rational /; Denominator[e] =!= 1]],
    Return[<|"Status" -> "NotDenestable",
      "Reason" -> "UndeclaredInnerRadical"|>]];
  ratio = toRatio[base];
  If[ratio === $Failed,
    Return[<|"Status" -> "NotDenestable",
      "Reason" -> "RootDenominatorNotCleared"|>]];
  {num, den} = ratio;
  (* Sqrt[num/den] = Sqrt[num den]/den *)
  normal = reduce[num den];
  If[TrueQ[normal === 0],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "ZeroRadicand"|>]];

  (* (iii) split off the generator-free factors *)
  list = FactorList[normal];
  numeric = Times @@ (First[#]^Last[#] & /@ Select[list, NumericQ[First[#]] &]);
  If[! MatchQ[numeric, _Integer | _Rational],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "NonRationalContent"|>]];
  sign = Sign[numeric]; n = Numerator[Abs[numeric]]; d = Denominator[Abs[numeric]];
  k = transportChartNumericSquareClass[Abs[numeric]];
  m = Sqrt[(n d)/k]/d;
  hPoly = m Times @@ (First[#]^Quotient[Last[#], 2] & /@
    Select[list, ! NumericQ[First[#]] &]);
  rFree = Times @@ (First[#]^Mod[Last[#], 2] & /@ Select[list,
    ! NumericQ[First[#]] && FreeQ[First[#], Alternatives @@ symbols] &]);
  fRaw = Times @@ (First[#]^Mod[Last[#], 2] & /@ Select[list,
    ! NumericQ[First[#]] && ! FreeQ[First[#], Alternatives @@ symbols] &]);
  fPart = reduce[fRaw];
  If[FreeQ[fPart, Alternatives @@ symbols],
    rFree = Together[rFree fPart]; fPart = 1];

  If[TrueQ[fPart === 1],
    (* (iv) no residual radical: a plain square class *)
    classExpr = Together[sign k rFree];
    classData = transportChartSquareClassData[classExpr, rootBases];
    If[Lookup[classData, "Status", None] =!= "OK",
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "UnclassifiedSquareClass", "Detail" -> classData|>]];
    rootImages = Sqrt /@ rootBases[[classData["RootIndices"]]];
    rewrite = Together[hPoly classData["Factor"]/den] *
      Sqrt[classData["NumericClass"]] Times @@ rootImages;
    witness = <|"Kind" -> "SquareClass", "u" -> classExpr, "v" -> 0, "w" -> 0,
      "Square" -> Together[hPoly^2]|>;
    index = 0,
    (* (v) a residual radical: Fermat denesting of u + v r *)
    present = Select[Range[Length[symbols]], ! FreeQ[fPart, symbols[[#]]] &];
    If[Length[present] =!= 1,
      Return[<|"Status" -> "NestedMultiRootRadical",
        "InnerRootIndices" -> present|>]];
    index = First[present];
    If[Exponent[fPart, symbols[[index]]] =!= 1,
      Return[<|"Status" -> "NotDenestable", "Reason" -> "ResidualNotLinear"|>]];
    u = Together[Coefficient[fPart, symbols[[index]], 0]];
    v = Together[Coefficient[fPart, symbols[[index]], 1]];
    discriminant = Together[u^2 - v^2 rootBases[[index]]];
    w = transportChartExactSquareRoot[discriminant];
    If[w === $Failed,
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "DiscriminantNotASquare"|>]];
    (* Both Fermat branches can denest; their c differ by a declared
       square, which IS a square of Q(x,y)[r]/(r^2 - q), so the square
       class is defined only modulo that square and both rewrites are
       exact.  The branch whose class uses the FEWEST declared roots is
       taken: it keeps the chart demand minimal. *)
    verified = {}; solved = {};
    Do[
      g = Together[branch/2];
      If[TrueQ[g === 0], Continue[]];
      split = transportChartSquareSplit[g];
      If[split === $Failed, Continue[]];
      {c, h} = split;
      alpha = Together[c h];
      If[TrueQ[alpha === 0], Continue[]];
      beta = Together[c v/(2 alpha)];
      If[TrueQ[Together[alpha^2 + beta^2 rootBases[[index]] - c u] === 0] &&
          TrueQ[Together[2 alpha beta - c v] === 0],
        Module[{candidateClass = Together[sign k rFree c], candidateData},
          candidateData = transportChartSquareClassData[candidateClass, rootBases];
          AppendTo[verified, <|"Class" -> candidateClass, "Data" -> candidateData,
            "Coefficient" -> c, "Alpha" -> alpha, "Beta" -> beta|>];
          If[Lookup[candidateData, "Status", None] === "OK",
            AppendTo[solved, Last[verified]]]]],
      {branch, {Together[u + w], Together[u - w]}}];
    If[verified === {},
      Return[<|"Status" -> "NotDenestable", "Reason" -> "NoDenestingBranch"|>]];
    If[solved === {},
      Return[<|"Status" -> "NotDenestable",
        "Reason" -> "UnclassifiedSquareClass",
        "Detail" -> First[verified]["Data"]|>]];
    solved = First[SortBy[solved,
      {Length[#["Data"]["RootIndices"]] &, LeafCount[#["Class"]] &}]];
    c = solved["Coefficient"]; alpha = solved["Alpha"]; beta = solved["Beta"];
    classExpr = solved["Class"]; classData = solved["Data"];
    rootImages = Sqrt /@ rootBases[[classData["RootIndices"]]];
    rewrite = Together[hPoly classData["Factor"] *
        (alpha + beta Sqrt[rootBases[[index]]])/(c den)] *
      Sqrt[classData["NumericClass"]] Times @@ rootImages;
    witness = <|"Kind" -> "Fermat", "u" -> u, "v" -> v, "w" -> w,
      "Square" -> Together[c fPart /.
        symbols[[index]] -> Sqrt[rootBases[[index]]]],
      "Alpha" -> alpha, "Beta" -> beta, "Coefficient" -> c,
      "InnerRootIndex" -> index|>];

  rewrite = rewrite /. Thread[symbols -> (Sqrt /@ rootBases)];
  (* the decisive exact identity, independent of the global sign *)
  check = zeroQ[rewrite^2, base];
  If[! TrueQ[check],
    Return[<|"Status" -> "NotDenestable", "Reason" -> "RewriteIdentityFailed",
      "Rewrite" -> rewrite|>]];

  <|"Status" -> "Denested", "RootIndices" -> classData["RootIndices"],
    "NumericClass" -> classData["NumericClass"], "Residual" -> 1,
    "InnerRootIndices" -> If[index === 0, {}, {index}],
    "Rewrite" -> rewrite, "SquareIdentity" -> check, "Witness" -> witness|>];

(* The exact identity rewrite^2 == base fixes a rewrite up to a global
   sign; the sign is fixed by numeric evaluation at rational points of
   the chart region where EVERY declared square is positive.  The points
   must agree, otherwise the answer is the typed "DenestSignAmbiguous".
   This is the only numeric step of the denesting layer. *)
transportChartDenestSign[base_, rewrite_, roots_List,
    variables : {__Symbol}, pointCount_Integer: 2] := Module[
  {rootBases, candidates, signs = {}, used = {}, tolerance = 10^-20,
   precision = 30},
  rootBases = Together /@ (squareRootRecordExpression[#]^2 & /@ roots);
  candidates = Table[Thread[variables ->
      PadRight[{Prime[k + 2]/Prime[k + 12], Prime[2 k + 3]/Prime[2 k + 17]},
        Length[variables], 1/(k + 3)]], {k, 1, 60}];
  Do[
    Module[{squares, value, lhs, rhs},
      squares = Quiet[N[rootBases /. point, precision]];
      If[! AllTrue[squares, MatchQ[#, _Real] && # > 0 &], Continue[]];
      value = Quiet[N[base /. point, precision]];
      rhs = Quiet[N[rewrite /. point, precision]];
      If[! FreeQ[{value, rhs}, Indeterminate | _DirectedInfinity], Continue[]];
      If[! (NumericQ[value] && NumericQ[rhs]), Continue[]];
      If[Abs[value] < 10^-10, Continue[]];
      lhs = Sqrt[value];
      Which[
        Abs[lhs - rhs] <= tolerance Max[1, Abs[lhs]],
          AppendTo[signs, 1]; AppendTo[used, point],
        Abs[lhs + rhs] <= tolerance Max[1, Abs[lhs]],
          AppendTo[signs, -1]; AppendTo[used, point],
        True, AppendTo[signs, 0]; AppendTo[used, point]]];
    If[Length[signs] >= pointCount, Break[]],
    {point, candidates}];
  If[Length[signs] < pointCount || MemberQ[signs, 0] ||
      Length[DeleteDuplicates[signs]] =!= 1,
    Return[<|"Status" -> "DenestSignAmbiguous", "Signs" -> signs,
      "Points" -> used|>]];
  <|"Status" -> "OK", "Sign" -> First[signs], "Points" -> used,
    "Precision" -> precision, "Tolerance" -> tolerance|>];

(* Rewrite every denested SYMBOLIC radical of an expression in terms of
   the declared radicals (numeric radicands are already constants of the
   coefficient ring and are left alone).  The classification is exact;
   each rewrite carries its numerically fixed global sign. *)
transportChartCanonicalizeDenestedRadicals[expr_, roots_List,
    variables : {__Symbol}, denested_Association] := Module[
  {records, rewrites, failures = {}, lookup, canonical, count = 0},
  records = KeySelect[denested, ! NumericQ[#] &];
  If[records === <||>,
    Return[<|"Status" -> "OK", "Expression" -> expr, "Rewrites" -> <||>,
      "Rewritten" -> 0|>]];
  rewrites = Association @ KeyValueMap[Function[{base, record},
    Module[{signData},
      If[! TrueQ[Lookup[record, "SquareIdentity", False]],
        AppendTo[failures, <|"Base" -> base,
          "Reason" -> "DenestIdentityNotVerified"|>]; Nothing,
        signData = transportChartDenestSign[base,
          Lookup[record, "Rewrite", 0], roots, variables];
        If[Lookup[signData, "Status", None] =!= "OK",
          AppendTo[failures, <|"Base" -> base,
            "Reason" -> "DenestSignAmbiguous", "Detail" -> signData|>]; Nothing,
          base -> <|"Rewrite" -> Together[signData["Sign"] record["Rewrite"]],
            "Sign" -> signData["Sign"], "SignPoints" -> signData["Points"],
            "RootIndices" -> Lookup[record, "RootIndices", {}],
            "NumericClass" -> Lookup[record, "NumericClass", 1],
            "Witness" -> Lookup[record, "Witness", <||>]|>]]]],
    records];
  If[failures =!= {},
    Return[<|"Status" -> "DenestSignAmbiguous", "Failures" -> failures|>]];
  lookup[b_] := lookup[b] = SelectFirst[Keys[rewrites],
    TrueQ[Together[b - #] === 0] &, None];
  canonical = expr /.
    Power[b_ /; ! NumericQ[b], e_Rational /; Denominator[e] === 2] :>
      With[{match = lookup[b]},
        If[match === None, Power[b, e], count++; rewrites[match]["Rewrite"]^(2 e)]];
  <|"Status" -> "OK", "Expression" -> canonical, "Rewrites" -> rewrites,
    "Rewritten" -> count|>];

transportChartRootIndices[expr_, roots_List] := Module[
  {rootBases, radicals, matches, indices, unknown, denested, denestedBases,
   numericClasses, variables},
  rootBases = Together /@ (squareRootRecordExpression[#]^2 & /@ roots);
  radicals = transportChartRadicalBases[expr];
  (* level 1 only, no heads: an all-level Position tests SUBexpressions of
     each root square, so a radical equal to a subexpression of another
     square contributed flattened position specs as bogus root indices
     (Sqrt[x] against {x, y, 1+x+y} classified as rank 3; found by the
     multiquadratic port's census differential, 2026-08-23) *)
  matches[base_] := Flatten[Position[rootBases, candidate_ /;
    TrueQ[Together[base - candidate] === 0], {1}, Heads -> False]];
  (* Generator grade masks are a private ABI: discovery order can change
     when an algebraically identical expression is reordered.  Keep the
     declared generator order so channel 2^i always names the same generator. *)
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#] === {} &];
  (* 2026-08-24: a radicand that is not itself a declared square may
     still reduce in the displayed relation quotient.  Such a base is
     denested exactly, contributes the declared roots of its square class
     AND the declared roots surviving inside its rewrite, and leaves the
     unclassified list.  Discovery order is untouched and the declared
     generator order still fixes the grade mask, so recorded masks stay
     valid; the index set can only GAIN correctly classified entries. *)
  variables = DeleteDuplicates[Flatten[Variables /@ rootBases]];
  variables = Select[variables, MatchQ[#, _Symbol] &];
  denested = Association @ Map[
    Function[base, base -> transportChartDenestRadicalBase[base, roots, variables]],
    unknown];
  denestedBases = Select[denested,
    Lookup[#, "Status", None] === "Denested" &];
  indices = Sort[DeleteDuplicates[Join[indices,
    Flatten[Lookup[Values[denestedBases], "RootIndices", {}]],
    Flatten[Lookup[Values[denestedBases], "InnerRootIndices", {}]]]]];
  numericClasses = DeleteDuplicates[DeleteCases[
    Flatten[Lookup[Values[denestedBases], "NumericClass", {}]], 1]];
  unknown = Select[unknown, ! KeyExistsQ[denestedBases, #] &];
  <|"RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    "NumericRadicalClasses" -> numericClasses,
    "DenestedRadicalBases" -> denestedBases|>
];


rekeyCoefficientPresentation[input_Association,
    sourceVariables : {_Symbol, _Symbol},
    targetVariables : {_Symbol, _Symbol}] := Module[
  {presentation, kind, oldSubstitution, oldSourceVariables,
   oldTargetVariables, sourceRules, variableRules, substitution, roots,
   generators, relationChecks, sourceRelationChecks,
   jacobianDeterminant, verified, result, identityVariableMapQ},
  presentation = algebraCoefficientPresentationNormalize[input];
  If[MemberQ[{
      "LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
      Lookup[presentation, "Status", None]],
    Return[presentation]];
  kind = Which[
    algebraSourceVariableRepresentationRecordQ[presentation],
      "SourceVariables",
    algebraRationalizingParametrizationRecordQ[presentation],
      "RationalizingParametrization",
    algebraSquareRootGeneratorRelationsRecordQ[presentation],
      "SquareRootGeneratorsAndQuadraticRelations",
    True, None];
  If[kind === None,
    Return[<|"Status" -> "CoefficientPresentationNotWellFormed"|>]];
  If[kind === "SourceVariables",
    If[! algebraSourceVariableRepresentationIdentityVerifiedQ[presentation],
      Return[<|"Status" ->
        "SourceVariableRepresentationIdentityFailed"|>]];
    If[targetVariables =!= sourceVariables,
      Return[<|"Status" ->
        "SourceVariableRepresentationCannotUseDistinctCoefficientVariables"|>]];
    Return[<|
      "DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "Status" -> "OK",
      "SourceVariables" -> sourceVariables,
      "CoefficientVariables" -> sourceVariables,
      "SourceVariableSubstitution" ->
        Thread[sourceVariables -> sourceVariables],
      "DifferentialPullbackMatrix" -> IdentityMatrix[2],
      "JacobianDeterminant" -> 1|>]];
  identityVariableMapQ = sourceVariables === targetVariables &&
    Lookup[presentation, "SourceVariables", None] ===
      Lookup[presentation, "CoefficientVariables", None] &&
    Lookup[presentation, "SourceToCoefficientVariableRules", None] ===
      Thread[Lookup[presentation, "SourceVariables", {}] ->
        Lookup[presentation, "SourceVariables", {}]];
  If[Length[DeleteDuplicates[SymbolName /@
        Join[sourceVariables, targetVariables]]] =!= 4 &&
      ! identityVariableMapQ,
    Return[<|"Status" ->
      "CoefficientPresentationVariablesCollide"|>]];
  If[! algebraCoefficientPresentationMapRationalQ[presentation],
    Return[<|"Status" -> "CoefficientPresentationMapNotRational"|>]];
  If[kind === "RationalizingParametrization" &&
      ! algebraRationalizedSquareRootImagesRationalQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationRootImageNotRational"|>]];
  If[kind === "SquareRootGeneratorsAndQuadraticRelations" &&
      ! algebraSquareRootGeneratorRadicandsRationalQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorQuadraticRadicandNotRational"|>]];
  If[kind === "SquareRootGeneratorsAndQuadraticRelations" &&
      ! algebraSquareRootGeneratorIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorRelationVerificationFailed"|>]];
  If[kind === "RationalizingParametrization" &&
      ! algebraRationalizedSquareRootIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationSquareRootIdentityFailed"|>]];
  oldSubstitution = If[kind === "RationalizingParametrization",
    presentation["SourceVariableSubstitution"],
    presentation["SourceToCoefficientVariableRules"]];
  oldTargetVariables = If[kind === "RationalizingParametrization",
    presentation["ParametrizingVariables"],
    presentation["CoefficientVariables"]];
  oldSourceVariables = First /@ oldSubstitution;
  sourceRules = Thread[oldSourceVariables -> sourceVariables];
  variableRules = Thread[oldTargetVariables -> targetVariables];
  substitution = Map[
    Function[rule, (First[rule] /. sourceRules) ->
      Together[Last[rule] /. variableRules]], oldSubstitution];
  jacobianDeterminant = Together@Det@Table[
    D[Last[substitution[[i]]], targetVariables[[j]]],
    {i, 2}, {j, 2}];
  If[TrueQ[jacobianDeterminant === 0],
    Return[<|"Status" ->
      "CoefficientPresentationJacobianDegenerate"|>]];
  If[kind === "RationalizingParametrization",
    roots = Map[
      <|"RationalRoot" -> Together[#["RationalRoot"] /. variableRules],
        "SourceRadicand" ->
          Together[#["SourceRadicand"] /. sourceRules]|> &,
      presentation["RationalizedSquareRoots"]];
    If[! AllTrue[roots, TrueQ[Together[#1["RationalRoot"]^2 -
          (#1["SourceRadicand"] /. substitution)] === 0] &],
      Return[<|"Status" ->
        "RationalizingParametrizationSquareRootIdentityFailed"|>]];
    result = <|
      "DataType" -> "RationalizingParametrization",
      "SchemaVersion" -> 2,
      "Status" -> "RationalizingParametrizationDeclared",
      "Name" -> Lookup[presentation, "Name",
          "RationalizingParametrization"] <> "Rekeyed",
      "Kind" -> "TwoVariable",
      "SourceVariables" -> sourceVariables,
      "ParametrizingVariables" -> targetVariables,
      "SourceVariableSubstitution" -> substitution,
      "RationalizedSquareRoots" -> roots,
      "ParentParametrizationMaps" -> <||>,
      "ParentParametrizations" -> <||>
    |>;
    If[KeyExistsQ[presentation, "InverseParametrizationByRootValues"],
      result = Append[result, "InverseParametrizationByRootValues" ->
        presentation["InverseParametrizationByRootValues"]]];
    Return[result]];
  generators = Map[
    <|"Generator" -> Together[#["Generator"] /. variableRules],
      "QuadraticRadicand" ->
        Together[#["QuadraticRadicand"] /. variableRules],
      "SourceRadicand" ->
        Together[#["SourceRadicand"] /. sourceRules]|> &,
    presentation["SquareRootGenerators"]];
  relationChecks = TrueQ[Together[#["Generator"]^2 -
        #["QuadraticRadicand"]] === 0] & /@ generators;
  sourceRelationChecks = TrueQ[Together[#["QuadraticRadicand"] -
        (#["SourceRadicand"] /. substitution)] === 0] & /@ generators;
  verified = AllTrue[Join[relationChecks, sourceRelationChecks], TrueQ] &&
    ! TrueQ[jacobianDeterminant === 0];
  <|
    "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
    "SchemaVersion" -> 2,
    "Status" -> If[verified,
      "SquareRootGeneratorRelationsVerified",
      "SquareRootGeneratorRelationVerificationFailed"],
    "SourceVariables" -> sourceVariables,
    "CoefficientVariables" -> targetVariables,
    "SourceToCoefficientVariableRules" -> substitution,
    "SquareRootGenerators" -> generators,
    "QuadraticRelationVerification" -> <|
      "Verified" -> verified,
      "PerGenerator" -> relationChecks,
      "SourceRadicandRelations" -> sourceRelationChecks,
      "CoordinateJacobianDeterminant" ->
        Factor[jacobianDeterminant]|>,
    "SquareClassIndependenceStatus" -> "NotChecked",
    "SquareClassIndependenceVerified" -> False,
    "SignChangeImageInterpretation" ->
      "FormalGeneratorSignChangesOnly",
    "GaloisConjugatesCertified" -> False|>
];

coefficientPresentationSquareRootsInVariables[input_Association,
    variables : {_Symbol, _Symbol}] := Module[
  {presentation, kind, presentationVariables, substitution, variableRules},
  presentation = algebraCoefficientPresentationNormalize[input];
  kind = Which[
    algebraSourceVariableRepresentationRecordQ[presentation],
      "SourceVariables",
    algebraRationalizingParametrizationRecordQ[presentation],
      "RationalizingParametrization",
    algebraSquareRootGeneratorRelationsRecordQ[presentation],
      "SquareRootGeneratorsAndQuadraticRelations",
    True, None];
  If[MemberQ[{
      "LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
      Lookup[presentation, "Status", None]],
    Return[presentation]];
  If[kind === None, Return[$Failed]];
  If[kind === "SourceVariables",
    Return[If[
      algebraSourceVariableRepresentationIdentityVerifiedQ[presentation],
      {}, <|"Status" ->
        "SourceVariableRepresentationIdentityFailed"|>]]];
  If[! algebraCoefficientPresentationMapRationalQ[presentation],
    Return[<|"Status" -> "CoefficientPresentationMapNotRational"|>]];
  If[kind === "RationalizingParametrization" &&
      ! algebraRationalizedSquareRootImagesRationalQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationRootImageNotRational"|>]];
  If[kind === "SquareRootGeneratorsAndQuadraticRelations" &&
      ! algebraSquareRootGeneratorRadicandsRationalQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorQuadraticRadicandNotRational"|>]];
  If[kind === "SquareRootGeneratorsAndQuadraticRelations" &&
      ! algebraSquareRootGeneratorIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "SquareRootGeneratorRelationVerificationFailed"|>]];
  If[kind === "RationalizingParametrization" &&
      ! algebraRationalizedSquareRootIdentitiesVerifiedQ[presentation],
    Return[<|"Status" ->
      "RationalizingParametrizationSquareRootIdentityFailed"|>]];
  presentationVariables = If[kind === "RationalizingParametrization",
    presentation["ParametrizingVariables"],
    presentation["CoefficientVariables"]];
  substitution = If[kind === "RationalizingParametrization",
    presentation["SourceVariableSubstitution"],
    presentation["SourceToCoefficientVariableRules"]];
  variableRules = Thread[presentationVariables -> variables];
  If[kind === "RationalizingParametrization",
    Map[
      <|"RationalRoot" -> Together[#["RationalRoot"] /. variableRules],
        "QuadraticRadicand" -> Together[
          (#["SourceRadicand"] /. substitution) /. variableRules],
        "SourceRadicand" -> #["SourceRadicand"]|> &,
      presentation["RationalizedSquareRoots"]],
    Map[
      <|"Generator" -> Together[#["Generator"] /. variableRules],
        "QuadraticRadicand" -> Together[
          #["QuadraticRadicand"] /. variableRules],
        "SourceRadicand" -> #["SourceRadicand"]|> &,
      presentation["SquareRootGenerators"]]]
];

(* The radicand carried by an expression need not be the declared root
   square itself: the kernel AUTOMATICALLY pulls a rational square factor
   out of a radical (Sqrt[N/4] evaluates to Sqrt[N]/2, Sqrt[4 N] to
   2 Sqrt[N]), so after a chart pullback the surviving base is c^2 times
   the pulled-back root square for some positive rational c.  MEASURED
   2026-08-24 on the CF259 rows 1..16 truncation in KallenQ4a: the two
   bases were exactly 4 and 16 times the declared squares (the chart's
   own root images carry denominators 2 t and 4 t), the branch rule
   matched neither, and FactorFamilyRegulatorDependenceInFrame refused a
   correct chart with "ChartStillAlgebraic".  Matching up to the square
   class of a positive RATIONAL NUMBER is exact -- base == c^2 Q gives
   (c image)^2 == c^2 Q == base -- and is a strict generalization: c is 1
   for every chart whose pullback needs no such factor, which is what the
   catalog's older charts produce.  Symbolic square factors are NOT
   admitted: the kernel never extracts one (the sign of a symbol is
   unknown), so a symbolic ratio means the base is a different quadratic
   and must stay untouched. *)
transportChartRootBranchScale[base_, rootSquare_] := Module[{ratio, scale},
  (* The common case is a literal declared radicand.  Avoid invoking
     Together on every occurrence merely to rediscover structural equality;
     the algebraic comparison below remains the general fallback. *)
  If[SameQ[base, rootSquare], Return[1]];
  If[TrueQ[Together[base - rootSquare] === 0], Return[1]];
  If[TrueQ[Together[rootSquare] === 0], Return[None]];
  ratio = Together[base/rootSquare];
  If[! MatchQ[ratio, _Integer | _Rational] || ! TrueQ[ratio > 0],
    Return[None]];
  scale = Sqrt[ratio];
  If[MatchQ[scale, _Integer | _Rational], scale, None]
];

transportChartApplyRootBranches[expr_, roots_List, images_List] := Module[
  {scale},
  (* one Together per distinct (radicand, root) pair, not one per
     occurrence: the same radical appears in most entries of a connection *)
  scale[base_, index_] := scale[base, index] =
    transportChartRootBranchScale[base,
      squareRootRecordRadicand[roots[[index]]]];
  Fold[Function[{current, index},
    current /. Power[base_, exponent_Rational] :>
      Module[{factor = If[Denominator[exponent] === 2,
          scale[base, index], None]},
        If[factor === None, Power[base, exponent],
          (factor images[[index]])^(2 exponent)]]],
    expr, Range[Length[roots]]]];

(* ------------------------------------------------------------------ *)
(*  Comparison in the displayed quadratic-relation quotient            *)
(* ------------------------------------------------------------------ *)
(* WHY (2026-08-25, CF303 off-diagonal block {17,12}).  Every acceptance
   test of the in-frame strip construction below reduced to
   Together[lhs - rhs] === 0.  Together is canonical on RATIONAL entries
   only; on entries that still carry a radical it compares two
   non-canonical forms, so an exactly equal pair is reported UNEQUAL --
   the documented trap of this repository.  MEASURED that night: the
   {17,12} gauge round trip rejected all four branch choices although the
   objects were exactly equal, because one coordinate-map image carried a
   NESTED radical the branch substitution above cannot match (it matches
   only rational-square multiples of a declared root square), so radicals
   survived into the comparison.  A generic rational 1x1 gauge reproduced
   the rejection, which is what proves the defect is in the comparison
   layer and not in any solved object.

   The test below is exact: every radical is matched against the declared
   root set (same square-class rule the branch substitution uses) and
   against the numeric square classes, each match becomes a generator
   r with r^2 = q, the generators are cleared from the denominator by
   conjugation and the numerator is reduced as a polynomial.  This is the
   same reduction transportChartDenestRadicalBase uses internally.

   This is a sound one-sided identity test without an independence claim:
   reduction to zero modulo the displayed relations proves equality after
   every specialization satisfying those relations.  Additional relations
   among dependent generators can make it reject an actual zero, never
   accept a false zero.  A radical outside the displayed generators returns
   $Failed rather than being misclassified. *)

transportChartDeclaredRadicalGenerators[expr_, roots_List] := Module[
  {rootBases, radicals, records, unmatched = {}},
  rootBases = Together /@ (squareRootRecordRadicand /@ roots);
  radicals = transportChartRadicalBases[expr];
  records = Map[Function[base, Module[{index = 0, scale = None, split},
      Do[scale = transportChartRootBranchScale[base, rootBases[[i]]];
         If[scale =!= None, index = i; Break[]], {i, Length[rootBases]}];
      Which[
        index > 0,
          (* base == scale^2 q, so Sqrt[base] == scale r: the same rule
             transportChartApplyRootBranches substitutes with *)
          base -> <|"Kind" -> "Declared", "Index" -> index,
            "Class" -> rootBases[[index]], "Factor" -> scale|>,
        MatchQ[Together[base], _Integer | _Rational],
          split = transportChartSquareSplit[base];
          If[split === $Failed || First[split] === 0,
            AppendTo[unmatched, base]; Nothing,
            base -> <|"Kind" -> "Numeric", "Index" -> 0,
              "Class" -> First[split], "Factor" -> Last[split]|>],
        True, AppendTo[unmatched, base]; Nothing]]],
    radicals];
  If[unmatched =!= {},
    Return[<|"Status" -> "UndeclaredRadicalBases", "Unmatched" -> unmatched|>]];
  (* one generator per square CLASS, compared exactly: a syntactic
     DeleteDuplicates would give the same class two generators and the
     reduction would then not be canonical *)
  <|"Status" -> "OK", "Records" -> Association[records],
    "Classes" -> Fold[
      Function[{accumulated, class},
        If[AnyTrue[accumulated, TrueQ[Together[class - #] === 0] &],
          accumulated, Append[accumulated, class]]],
      {}, #["Class"] & /@ Values[Association[records]]]|>];

(* True / False / $Failed.  $Failed means "not decidable from the
   displayed generators and quadratic relations" and is never a synonym
   for False. *)
transportChartAlgebraicZeroQ[expr_, roots_List] := Module[
  {together, generatorData, records, classes, symbols, classIndex,
   substitute, reduceRules, reduce, converted, nu, de, i},
  together = Together[expr];
  If[FreeQ[together, Power[_, _Rational]],
    Return[TrueQ[together === 0]]];
  generatorData = transportChartDeclaredRadicalGenerators[together, roots];
  If[Lookup[generatorData, "Status", None] =!= "OK", Return[$Failed]];
  records = generatorData["Records"];
  classes = generatorData["Classes"];
  If[classes === {}, Return[TrueQ[together === 0]]];
  symbols = Table[Unique["FeynFacet`Private`fieldRoot"], {Length[classes]}];
  classIndex[class_] := classIndex[class] = SelectFirst[
    Range[Length[classes]], TrueQ[Together[classes[[#]] - class] === 0] &, 0];
  substitute[expression_] := expression /.
    Power[b_, e_Rational /; Denominator[e] === 2] :>
      Module[{record = SelectFirst[Keys[records],
          TrueQ[Together[b - #] === 0] &, None], k},
        If[record === None, Power[b, e],
          k = classIndex[records[record]["Class"]];
          If[k === 0, Power[b, e],
            (records[record]["Factor"] symbols[[k]])^(2 e)]]];
  reduceRules = Table[With[{s = symbols[[i]], q = classes[[i]]},
      s^e_Integer /; e >= 2 :> q^Quotient[e, 2] s^Mod[e, 2]],
    {i, Length[symbols]}];
  reduce[p_] := FixedPoint[Expand[# /. reduceRules] &, Expand[p]];
  converted = Together[substitute[together]];
  If[! FreeQ[converted, Power[_, _Rational]], Return[$Failed]];
  nu = reduce[Numerator[converted]]; de = reduce[Denominator[converted]];
  (* clear the generators from the denominator by conjugation *)
  Do[If[! FreeQ[de, symbols[[i]]],
      Module[{conjugate = reduce[de /. symbols[[i]] -> -symbols[[i]]]},
        nu = reduce[nu conjugate]; de = reduce[de conjugate]]],
    {i, Length[symbols]}];
  If[! FreeQ[de, Alternatives @@ symbols], Return[$Failed]];
  If[TrueQ[Together[de] === 0], Return[$Failed]];
  TrueQ[Together[reduce[nu]] === 0]];

End[];
