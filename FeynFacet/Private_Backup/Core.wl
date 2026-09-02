
(* ==== moved from Private/Core.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere in FeynFacet/, Scripts/, Tests/ including string-constructed names (reachability.py 2026-09-02)
   Symbols: atomizeProtectedAnalyticObjects, compileSparseReduction, linearApplyReduction, linearMapCoefficients, protectedAnalyticObjects, removeFactorMultiset, structuralCommonFactor
   This file is never loaded by FeynFacet.m. *)


protectedAnalyticObjects[expression_] := Module[{walk},
  walk[value_?AtomQ] := {};
  walk[value_Plus] := Flatten[walk /@ List @@ value];
  walk[value_Times] := Flatten[walk /@ List @@ value];
  walk[Power[base_, power_Integer]] := walk[base];
  walk[value_] := {value};
  DeleteDuplicates[walk[expression], SameQ]
];

atomizeProtectedAnalyticObjects[expression_] := Module[
  {protected, atoms},
  protected = protectedAnalyticObjects[expression];
  atoms = Table[Unique["analytic$"], Length[protected]];
  <|
    "Expression" -> expression,
    "Atoms" -> atoms,
    "Forward" -> Dispatch[Thread[protected -> atoms]],
    "Backward" -> Dispatch[Thread[atoms -> protected]]
  |>
];

removeFactorMultiset[list_List, factors_List] :=
  Fold[removeFactorOnce, list, factors];

structuralCommonFactor[expressions_List] := Module[
  {factorLists, shared},
  If[expressions === {}, Return[{1, {}}]];
  factorLists = topLevelFactors /@ expressions;
  shared = commonFactorMultiset[factorLists];
  {
    Times @@ shared,
    Times @@@ (removeFactorMultiset[#, shared] & /@ factorLists)
  }
];

linearMapCoefficients[data_?linearIntegralSumStructureQ, function_] := <|
  "Terms" -> Map[function, data["Terms"]],
  "Remainder" -> function[data["Remainder"]]
|>;

compileSparseReduction[
    targets_List,
    rules_,
    coefficientFunction_: Identity
  ] := Module[{images},
  images = AssociationMap[
    Function[target,
      With[{image = linearIntegralSum[Replace[target, rules, {0}]]},
        If[FailureQ[image], image,
          linearMapCoefficients[image, coefficientFunction]
        ]
      ]
    ],
    targets
  ];
  If[AnyTrue[Values[images], FailureQ],
    Failure["InvalidReductionImage", <||>],
    images
  ]
];

linearApplyReduction[data_?linearIntegralSumQ, rules_, reverseRules_] := Module[
  {reduction},
  reduction = compileSparseReduction[
    Keys[data["Terms"]],
    Dispatch[(rules /. reverseRules)]
  ];
  If[FailureQ[reduction], reduction,
    linearComposeReduction[data /. reverseRules, reduction]
  ]
];
