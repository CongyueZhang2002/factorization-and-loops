ClearAll["Global`*"];

root = DirectoryName[$InputFileName];
catalogPath = "/home/maxzhang/factorization-and-loops/Codex/ppHX_NNLO_DoubleReal/BoundaryInventory/SoftCornerBoundaryPeriodCatalog.wl";
catalog = Get[catalogPath];
entry = SelectFirst[catalog["Classes"], MemberQ[#TemplateIDs, 121] &];

c = 1 + rz^2;
p1 = (c - 2 ra ru rz)^2 + rv^2 (c + 2 ra ru rz)^2;
p2 = (ra c + 2 ru rz)^2 + rv^2 (ra c - 2 ru rz)^2;
p3 = (ru c + 2 ra rz)^2 + rv^2 (ru c - 2 ra rz)^2;
p4 = (ra ru c - 2 rz)^2 + rv^2 (ra ru c + 2 rz)^2;

reducedDensity[shift_Integer] :=
  ra^(1 + 2 shift) ru^(1 + 2 shift) rv^(2 shift) rz^(1 + 2 shift) *
  (1 - rz^2)^(3 + 4 shift) *
  (1 + ra^2)^(4 - 2 shift) (1 + ru^2)^(4 - 2 shift) *
  (1 + rv^2)^(5 - 2 shift) (1 + rz^2)^(7 - 6 shift) /
  (p1 p2^2 p3^2 p4);

assumptions = 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0;
sourceDensity = entry["RationalDensity"];
ratios = Table[
  TimeConstrained[
    FullSimplify[
      PowerExpand[(sourceDensity /. ep -> -shift)/reducedDensity[shift]],
      Assumptions -> assumptions
    ],
    60,
    $Failed
  ],
  {shift, 0, 2}
];

variableFreeQ[expression_] := expression =!= $Failed &&
  And @@ (FreeQ[expression, #] & /@ {rz, ra, ru, rv});

denominatorIdentity = Together[
  entry["RationalDenominator"] -
  p1 p2^2 p3^2 p4 / (
    (1 + ra^2)^6 (1 + ru^2)^6 (1 + rv^2)^6 (1 + rz^2)^12
  )
] === 0;

checks = <|
  "Template121Selected" -> TrueQ[entry["CanonicalMaster"] ===
    GLI[CF385, {1, 1, 1, 1, 1, 1, 1, 1, 1}]],
  "DenominatorFactorization" -> denominatorIdentity,
  "DVariableDensity" -> variableFreeQ[ratios[[1]]],
  "DPlus2VariableDensity" -> variableFreeQ[ratios[[2]]],
  "DPlus4VariableDensity" -> variableFreeQ[ratios[[3]]]
|>;

Print["DENSITY_RATIOS=", InputForm[ratios]];
Print["CHECKS=", InputForm[checks]];
If[! And @@ Values[checks], Exit[1]];

result = <|
  "Object" -> "T121QuasiFiniteSourceCertificate",
  "Master" -> entry["CanonicalMaster"],
  "TemplateID" -> 121,
  "SumOfSquares" -> {p1, p2, p3, p4},
  "ReducedDensities" -> Association@Table[
    "DPlus" <> ToString[2 shift] -> reducedDensity[shift],
    {shift, 0, 2}
  ],
  "VariableIndependentRatios" -> ratios,
  "Checks" -> checks
|>;

Put[result, FileNameJoin[{root, "T121QuasiFiniteSourceCertificate.wl"}]];
Print["STATUS=VERIFIED"];
