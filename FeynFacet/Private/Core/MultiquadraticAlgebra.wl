(* The neutral multiquadratic (extension-field) algebra (2026-08-23).

   One ABI for every consumer of a multiquadratic coefficient frame
   Q(sqrt(delta_1),...,sqrt(delta_r)): the grade masks, the character
   table, the xor-graded product with r_i^2 = delta_i, the derivative
   rule, reduction of a polynomial in the root symbols to the grade
   basis, conjugate evaluation and projection, the split-point test,
   modular square roots, and the F2 grade lattice.

   Source: Exchange/Codex/2026-08-22/04_triple_root_campaign/
   TripleRootAlgebra.wl (Codex, audited).  Semantics are preserved
   exactly; only the names are rehoused in FeynFacet`Private` and the
   two rank-0 fixes named in the promotion handoff are made explicit.

   Ordering is an ABI, not an implementation detail.  Grade mask bit i
   always denotes declared root i, so the caller -- not this file --
   owns the root order (transportChartRootIndices keeps the frame
   order for exactly this reason).  A consumer records
   multiquadraticAlgebraABIFingerprint[]: it is computed from formal
   System` symbols only, so it is independent of the reader's
   $Context/$ContextPath (package bug handoff 2026-08-23, pool defect
   3 forbids context-sensitive fingerprints). *)

Begin["FeynFacet`Private`"];

ClearAll[
  $multiquadraticAlgebraABIFingerprintCache,
  multiquadraticBasisMasks, multiquadraticMaskFactor,
  multiquadraticParity, multiquadraticHadamardMatrix,
  multiquadraticCharacteristicNormalize, multiquadraticIntegerDataQ,
  multiquadraticMultiply,
  multiquadraticDerivative, multiquadraticToExpression,
  multiquadraticFromPolynomial, multiquadraticEvaluateConjugates,
  multiquadraticProjectConjugates, multiquadraticSplitPointQ,
  multiquadraticSquareRoots, multiquadraticGradeClosure,
  multiquadraticActiveRank, multiquadraticAlgebraProbe,
  multiquadraticAlgebraABIFingerprint,
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

multiquadraticEvaluateConjugates[a_List, rootValues_List, modulus_: 0] /;
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

multiquadraticProjectConjugates[values_List, rootValues_List, modulus_: 0] /;
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

multiquadraticSplitPointQ[point : {_, _}, radicands_List, vars : {_, _},
    p_Integer?Positive] :=
  Module[{values = Mod[radicands /. Thread[vars -> point], p]},
    AllTrue[values, # != 0 && JacobiSymbol[#, p] == 1 &]
  ];

(* p = 3 (mod 4) only; the returned representative is the raw
   exponentiation, NOT the smaller of the two roots.  The sign
   representative is part of the ABI: see the differential test
   against FamilyRowGaugeFiniteField.wl, which normalizes instead. *)
multiquadraticSquareRoots[values_List, p_Integer?Positive] /; Mod[p, 4] == 3 :=
  Module[{roots = PowerMod[Mod[values, p], Quotient[p + 1, 4], p]},
    If[Mod[roots^2 - values, p] === ConstantArray[0, Length[values]], roots, $Failed]
  ];

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

(* The ABI probe: ordering (masks, character table) and semantics
   (one product, one derivative) at every supported rank, written in
   formal System` symbols so that InputForm -- and therefore the hash
   -- carries no context. *)
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

(* The fingerprint is a constant of the loaded package: it is computed once
   and memoized (overhaul 2026-09-02, certification audit item 1).  It used
   to run the symbolic probe and a full InputForm on EVERY call, and it is
   called from the validity predicates that run per sample and per prime.
   A failed probe is not memoized, so a context problem stays visible. *)
$multiquadraticAlgebraABIFingerprintCache = None;
multiquadraticAlgebraABIFingerprint[] := Module[{probe, symbols, value},
  If[StringQ[$multiquadraticAlgebraABIFingerprintCache],
    Return[$multiquadraticAlgebraABIFingerprintCache]];
  probe = multiquadraticAlgebraProbe[];
  symbols = DeleteDuplicates[Cases[probe, symbol_Symbol :> symbol,
    {0, Infinity}, Heads -> True]];
  (* a fingerprint whose text depends on the reader's context is not an
     ABI (package bug handoff 2026-08-23, pool defect 3) *)
  If[! AllTrue[symbols, Context[#] === "System`" &], Return[$Failed]];
  value = Hash[ToString[InputForm[probe]], "SHA256", "HexString"];
  $multiquadraticAlgebraABIFingerprintCache = value;
  value
];

End[];
