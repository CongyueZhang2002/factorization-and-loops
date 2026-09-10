(* FeynCalc kinematics and light-cone basis operations. *)
DeclareScalar[scalars_List] := Module[{pieces},
  pieces = DeleteDuplicates @ Cases[
    scalars,
    x_ /; ! ListQ[Unevaluated[x]] &&
      ! MatchQ[x, _Integer | _Rational] &&
      ! TrueQ[x === 0],
    {1, Infinity},
    Heads -> False
  ];
  (* Reassigning an existing FeynCalc scalar declaration invalidates its
     algebra caches. Coordinate substitutions repeatedly use the same scalars. *)
  Scan[Function[piece,
    If[! TrueQ[FeynCalc`DataType[piece, FeynCalc`FCVariable]],
      FeynCalc`DataType[piece, FeynCalc`FCVariable] = True]], pieces];
  scalars
];

DeclareScalar[scalar_] := First[DeclareScalar[{scalar}]];

BuildBasis::length = "Expected four basis vectors, but received `1`.";
BuildBasis::relation = "Basis relations failed: `1`.";


BuildBasis[basis_List, assumptions_: True] := Module[
  {heads, expected, actual, bad},

  If[Length[basis] =!= 4,
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  expected = {
    GlobalBasisGram,
    GlobalBasisGram,
    ConstantArray[0, {4, 4}]
  };
  actual = FullSimplify[
    Table[
      FeynCalc`ExpandScalarProduct[
        heads[[kind]][basis[[i]], basis[[j]]]
      ],
      {kind, 3}, {i, 4}, {j, 4}
    ],
    Assumptions -> assumptions
  ];
  bad = Position[MapThread[SameQ, {actual, expected}, 3], False];

  If[bad =!= {},
    Message[
      BuildBasis::relation,
      Function[pos, {
        heads[[pos[[1]]]],
        basis[[pos[[2]]]],
        basis[[pos[[3]]]],
        expected[[Sequence @@ pos]],
        actual[[Sequence @@ pos]]
      }] /@ bad
    ];
    Return[$Failed]
  ];

  basis
];

BuildBasis[basis_, assumptions_: True] := (
  Message[BuildBasis::length, basis];
  $Failed
);


Build4Vec::arguments =
  "Expected coordinate and basis lists of equal length, but received `1` and `2`.";

Build4Vec[coordinates_List, basis_List] /;
    Length[coordinates] === Length[basis] := (
  DeclareScalar[coordinates];
  Total[coordinates basis]
);

Build4Vec[coordinates_, basis_] := (
  Message[Build4Vec::arguments, coordinates, basis];
  $Failed
);


declareGlobalBasis[basis_List] := Do[
  With[
    {p = basis[[i]], q = basis[[j]], value = GlobalBasisGram[[i, j]]},
    FeynCalc`SP[p, q] = value;
    FeynCalc`SPD[p, q] = value;
    FeynCalc`SPE[p, q] = 0
  ],
  {i, 4}, {j, i, 4}
];

BuildGlobalBasis[basis_List] := Module[
  {heads, oldDefinitions, oldBasis, oldEvanescent, result},
  If[
    Length[basis] =!= 4 ||
      ! AllTrue[basis, MatchQ[#, _Symbol] &] ||
      ! DuplicateFreeQ[basis],
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  oldDefinitions = DownValues /@ heads;
  oldBasis = globalBasis;
  oldEvanescent = internalSetEvanescentZero;
  declareGlobalBasis[basis];
  result = BuildBasis[basis];
  If[result === $Failed,
    MapThread[(DownValues[#1] = #2) &, {heads, oldDefinitions}];
    globalBasis = oldBasis;
    internalSetEvanescentZero = oldEvanescent;
    Return[$Failed]
  ];
  globalBasis = basis;
  internalSetEvanescentZero = basis[[{2, 1, 3, 4}]];
  result
];

BuildGlobalBasis[basis_] := (
  Message[BuildBasis::length, basis];
  $Failed
);


SimplifyAssum[expr_, assumptions_: True] :=
  Simplify[expr, Assumptions -> assumptions];

FullSimplifyAssum[expr_, assumptions_: True] :=
  FullSimplify[expr, Assumptions -> assumptions];


ToFeynFacetForm::convert =
  "FeynCalc could not convert the expression to its external form.";

ToFeynFacetForm::internal =
  "Internal FeynCalc scalar-product objects remain after conversion: `1`.";

internalScalarProductObjects[expr_] := DeleteDuplicates[
  Cases[
    HoldComplete[expr],
    object : HoldPattern[
      (FeynCalc`Pair | FeynCalc`CartesianPair | FeynCalc`TemporalPair)[___]
    ] :> object,
    Infinity
  ],
  SameQ
];

feynFacetFormQ[expr_] := internalScalarProductObjects[expr] === {};

ToFeynFacetForm[expr_] := Module[{converted, remaining},
  converted = Check[FeynCalc`FCE[expr], $Failed];
  If[converted === $Failed,
    Message[ToFeynFacetForm::convert];
    Return[$Failed]
  ];
  remaining = internalScalarProductObjects[converted];
  If[! feynFacetFormQ[converted],
    Message[ToFeynFacetForm::internal, Take[remaining, UpTo[3]]];
    Return[$Failed]
  ];
  converted
];

remainingDeclaredMomenta[expression_, momenta_List] := Select[
  DeleteDuplicates[momenta, SameQ],
  ! FreeQ[HoldComplete[expression], #] &
];
