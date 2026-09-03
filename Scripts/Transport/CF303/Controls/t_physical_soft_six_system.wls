#!/usr/bin/env wolframscript

root = ExpandFileName[FileNameJoin[
  {DirectoryName[$InputFileName], "..", "..", "..", ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
artifact = Get[FileNameJoin[{root, "Scripts", "Transport", "CF303",
  "Artifacts", "CF303PhysicalSoftSixSystem.wl"}]];

dense[records_, value_] := Module[{matrix = ConstantArray[0, {6, 6}]},
  Do[matrix[[record["Row"], record["Column"]]] = value[record],
    {record, records}];
  matrix
];
normalResidue = dense[artifact["Homogeneous", "Normal"],
  Lookup[#["Principal"], -1, 0] &];
tangential = dense[artifact["Homogeneous", "Tangential"], #["Finite"] &];
lambda = -2 (1 + 2 eps);
z = Unique["z"];

FTAssert["the exact artifact separates six homogeneous and 39 inherited columns",
  artifact["Status"] === "CF303PhysicalSoftSixSystemExactV1" &&
  artifact["PhysicalRows"] === Range[6] &&
  artifact["HomogeneousColumns"] === Range[6] &&
  artifact["InheritedColumns"] === Range[7, 45]];

FTAssert["the exact fixed-rho Jacobian agrees with the fixed-s chart",
  TrueQ[artifact["Coordinate", "CoordinateJacobianAgreement"]] &&
  TrueQ[Together[artifact["Coordinate", "NormalScale"] -
      (1 - 2 p^2)/(2 p)] === 0]];

FTAssert["the homogeneous normal system is Fuchsian without a higher-pole shear",
  artifact["Homogeneous", "NormalSummary", "MaximumPoleOrder"] === 1 &&
  TrueQ[artifact["Interpretation", "HomogeneousNormalFuchsian"]] &&
  ! TrueQ[artifact["Interpretation",
      "HomogeneousShearNeededForFuchsianity"]]];

FTAssert["the rank-one physical normal residue is generically semisimple",
  Map[Together, normalResidue . normalResidue - lambda normalResidue,
      {2}] === ConstantArray[0, {6, 6}] &&
  Together[CharacteristicPolynomial[normalResidue, z] -
      z^5 (z - lambda)] === 0 &&
  ! TrueQ[Together[normalResidue[[4, 4]]] === 0]];

FTAssert["the physical normal residue is not epsilon times a constant matrix",
  (normalResidue /. eps -> 0) =!= ConstantArray[0, {6, 6}] &&
  ! FreeQ[Together[normalResidue/eps], eps]];

FTAssert["the inherited forcing retains its exact third-order local deck",
  artifact["InheritedForcing", "TangentialSummary", "MaximumPoleOrder"] === 3 &&
  artifact["InheritedForcing", "NormalSummary", "MaximumPoleOrder"] === 3 &&
  artifact["InheritedForcing", "UnscaledFiniteProductJetOrder"] === 3];

monic[factor_] := Together[factor/
  Coefficient[factor, p, Exponent[factor, p]]];
factorPowers = Merge[Flatten[Table[
  With[{factors = Rest[FactorList[
      Denominator[Together[tangential[[row, column]]]]]]},
    (monic[#[[1]]] -> #[[2]]) & /@ Select[factors,
      ! FreeQ[#[[1]], p] &]],
  {row, 6}, {column, 6}], 2], Max];
expectedFactors = {p, -1 + p, 1 + p, -1/2 + p^2};
factorSetAgreement = Length[Keys[factorPowers]] === Length[expectedFactors] &&
  AllTrue[expectedFactors, Function[expected,
    AnyTrue[Keys[factorPowers],
      TrueQ[Together[# - expected] === 0] &]]];
FTAssert["the homogeneous tangential system has only the stated GPL singular set",
  factorSetAgreement &&
  Max[Flatten[Table[
      Exponent[Numerator[Together[tangential[[row, column]]]], p] -
       Exponent[Denominator[Together[tangential[[row, column]]]], p],
      {row, 6}, {column, 6}]]] === 1];

Print["HOMOGENEOUS_NORMAL_RESIDUE=", InputForm[normalResidue]];
Print["NORMAL_SPECTRUM=", InputForm[<|
  "Eigenvalues" -> {lambda, 0, 0, 0, 0, 0},
  "MinimalPolynomial" -> z (z - lambda),
  "GenericRank" -> 1, "ZeroNullity" -> 5,
  "Semisimple" -> True,
  "EpsilonTimesConstantMatrix" -> False|>]];
Print["HOMOGENEOUS_TANGENTIAL_FACTORIZATION=", InputForm[<|
  "Matrix" -> tangential, "DenominatorFactorsAndMaxPowers" -> factorPowers,
  "Letters" -> {0, 1, -1, 1/Sqrt[2], -1/Sqrt[2], Infinity},
  "MaximumPolynomialDegreeAtInfinity" -> 1|>]];
Print["INHERITED_LOCAL_REQUIREMENT=", InputForm[<|
  "TangentialValuations" ->
    artifact["InheritedForcing", "TangentialSummary", "ValuationCounts"],
  "NormalValuations" ->
    artifact["InheritedForcing", "NormalSummary", "ValuationCounts"],
  "UnscaledFiniteProductJetOrder" -> 3|>]];
FTSummary[];
