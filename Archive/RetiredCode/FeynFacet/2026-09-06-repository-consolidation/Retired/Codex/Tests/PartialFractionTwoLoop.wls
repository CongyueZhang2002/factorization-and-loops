root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], "..", ".."}]];

Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
FeynCalc`FCClearScalarProducts[];

input =
  FeynFacet`Cut[FeynCalc`SPD[q1], 1] *
  FeynFacet`Cut[FeynCalc`SPD[q2], -1] *
  FeynCalc`FAD[q1 - p, q1 + p, q2 - p, q1 - q2];

algebraicInput = input /. {
  FeynFacet`Cut[FeynCalc`SPD[q_]] :> FeynCalc`FAD[q],
  FeynFacet`Cut[FeynCalc`SPD[q_], _] :> FeynCalc`FAD[q]
};
native = FeynCalc`ApartFF[
  algebraicInput,
  {q1, q2},
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False,
  FeynCalc`FCE -> False
];
result = FeynFacet`PartialFraction[input, {q1, q2}];
terms = If[Head[Expand[result]] === Plus, List @@ Expand[result], {result}];
legacy = FeynFacet`PartialFraction[
  FeynFacet`Cut[FeynCalc`SPD[q1]] FeynCalc`FAD[q1 - p],
  {q1}
];

cutRecords[expr_] := Cases[
  expr,
  FeynFacet`Cut[FeynCalc`SPD[q_], direction_] :> {q, direction},
  Infinity
];

conflicting = Quiet[
  FeynFacet`PartialFraction[
    FeynFacet`Cut[FeynCalc`SPD[q1], 1] *
      FeynFacet`Cut[FeynCalc`SPD[q1], -1] *
      FeynCalc`FAD[q1 - p],
    {q1}
  ],
  FeynFacet`PartialFraction::cutorientation
];

nativeIdentity = TrueQ[
  Together[
    FeynCalc`FeynAmpDenominatorExplicit[algebraicInput] -
    FeynCalc`FeynAmpDenominatorExplicit[FeynCalc`FCE[native]]
  ] === 0
];

checks = <|
  "Returned" -> ! MemberQ[{$Failed, $Aborted, 0}, result],
  "NontrivialDecomposition" -> Length[terms] > 1,
  "OrientedCutsInEveryTerm" -> AllTrue[
    terms,
    ContainsAll[cutRecords[#], {{q1, 1}, {q2, -1}}] &
  ],
  "ConflictingOrientationRejected" -> conflicting === $Failed,
  "LegacyCutDefaultsPositive" ->
    ! FreeQ[legacy, FeynFacet`Cut[FeynCalc`SPD[q1], 1]],
  "NativeExactIdentity" -> nativeIdentity
|>;

Print[checks];

If[! And @@ Values[checks], Exit[1]];
Exit[0];
