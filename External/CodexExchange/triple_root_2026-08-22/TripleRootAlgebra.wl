BeginPackage["CodexTripleRoot`"];

TRBasisMasks::usage = "TRBasisMasks[r] returns the 2^r square-root basis masks.";
TRMaskFactor::usage = "TRMaskFactor[mask, values] multiplies the values selected by the bits of mask.";
TRHadamardMatrix::usage = "TRHadamardMatrix[r] gives the character table of (Z/2)^r in mask order.";
TRMultiply::usage = "TRMultiply[a,b,deltas,p] multiplies two multiquadratic coefficient vectors; p=0 means characteristic zero.";
TRDerivative::usage = "TRDerivative[a,deltas,x] differentiates a multiquadratic coefficient vector with ri^2=deltai.";
TRToExpression::usage = "TRToExpression[a,roots] converts a coefficient vector to an expression in the root symbols.";
TRFromPolynomial::usage = "TRFromPolynomial[expr,roots,deltas] reduces a polynomial expression to the square-root basis.";
TREvaluateConjugates::usage = "TREvaluateConjugates[a,rootValues,p] evaluates all sign conjugates at a split point.";
TRProjectConjugates::usage = "TRProjectConjugates[values,rootValues,p] recovers basis coefficients from all sign conjugates.";
TRSplitPointQ::usage = "TRSplitPointQ[point,radicands,vars,p] tests whether all radicands are nonzero quadratic residues modulo p.";
TRSquareRoots::usage = "TRSquareRoots[values,p] returns modular square roots for p congruent to 3 modulo 4.";
TRGradeClosure::usage = "TRGradeClosure[seeds,generators] closes a set of grades under xor by the generator grades.";
TRActiveRank::usage = "TRActiveRank[masks,r] returns the F2 rank of the listed grade masks.";

Begin["`Private`"];

TRBasisMasks[r_Integer?NonNegative] := Range[0, 2^r - 1];

TRMaskFactor[mask_Integer?NonNegative, values_List] :=
  Times @@ MapIndexed[If[BitGet[mask, First[#2] - 1] == 1, #1, 1] &, values];

TRParity[mask_Integer?NonNegative, rank_Integer?NonNegative] :=
  Mod[Total[BitGet[mask, Range[0, rank - 1]]], 2];

TRHadamardMatrix[rank_Integer?NonNegative] :=
  Table[If[TRParity[BitAnd[row, column], rank] == 0, 1, -1],
    {row, 0, 2^rank - 1}, {column, 0, 2^rank - 1}];

TRCharacteristicNormalize[values_, 0] := Together /@ values;
TRCharacteristicNormalize[values_, p_Integer?Positive] := Mod[values, p];

TRMultiply[a_List, b_List, deltas_List, modulus_: 0] /;
    Length[a] == Length[b] == 2^Length[deltas] :=
  Module[{rank = Length[deltas], out, common, target, term},
    out = ConstantArray[0, 2^rank];
    Do[
      common = BitAnd[left, right];
      target = BitXor[left, right];
      term = a[[left + 1]] b[[right + 1]] TRMaskFactor[common, deltas];
      out[[target + 1]] += term,
      {left, 0, 2^rank - 1}, {right, 0, 2^rank - 1}
    ];
    TRCharacteristicNormalize[out, modulus]
  ];

TRDerivative[a_List, deltas_List, x_] /; Length[a] == 2^Length[deltas] :=
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

TRToExpression[a_List, roots_List] /; Length[a] == 2^Length[roots] :=
  Total[MapThread[#1 TRMaskFactor[#2, roots] &, {a, TRBasisMasks[Length[roots]]}]];

TRFromPolynomial[expr_, roots_List, deltas_List] /; Length[roots] == Length[deltas] :=
  Module[{remainder, rules, out, exponents, mask},
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

TREvaluateConjugates[a_List, rootValues_List, modulus_: 0] /;
    Length[a] == 2^Length[rootValues] :=
  Module[{weighted, result},
    weighted = MapThread[#1 #2 &, {a, TRMaskFactor[#, rootValues] & /@ TRBasisMasks[Length[rootValues]]}];
    result = TRHadamardMatrix[Length[rootValues]].weighted;
    If[modulus === 0, Together /@ result, Mod[result, modulus]]
  ];

TRProjectConjugates[values_List, rootValues_List, modulus_: 0] /;
    Length[values] == 2^Length[rootValues] :=
  Module[{rank = Length[rootValues], rootProducts, weighted},
    rootProducts = TRMaskFactor[#, rootValues] & /@ TRBasisMasks[rank];
    If[modulus === 0,
      weighted = TRHadamardMatrix[rank].values/2^rank;
      Together /@ MapThread[#1/#2 &, {weighted, rootProducts}],
      weighted = Mod[PowerMod[2^rank, -1, modulus] (TRHadamardMatrix[rank].values), modulus];
      Mod[MapThread[#1 PowerMod[#2, -1, modulus] &, {weighted, Mod[rootProducts, modulus]}], modulus]
    ]
  ];

TRSplitPointQ[point : {_, _}, radicands_List, vars : {_, _}, p_Integer?Positive] :=
  Module[{values = Mod[radicands /. Thread[vars -> point], p]},
    AllTrue[values, # != 0 && JacobiSymbol[#, p] == 1 &]
  ];

TRSquareRoots[values_List, p_Integer?Positive] /; Mod[p, 4] == 3 :=
  Module[{roots = PowerMod[Mod[values, p], Quotient[p + 1, 4], p]},
    If[Mod[roots^2 - values, p] === ConstantArray[0, Length[values]], roots, $Failed]
  ];

TRGradeClosure[seeds_List, generators_List] :=
  FixedPoint[
    Function[current,
      Union[current, Flatten[Table[BitXor[grade, generator], {grade, current}, {generator, generators}]]]
    ],
    Union[seeds]
  ];

TRActiveRank[masks_List, rank_Integer: 3] :=
  If[masks === {} || masks === {0}, 0,
    MatrixRank[BitGet[#, Range[0, rank - 1]] & /@ DeleteCases[Union[masks], 0], Modulus -> 2]
  ];

End[];
EndPackage[];
