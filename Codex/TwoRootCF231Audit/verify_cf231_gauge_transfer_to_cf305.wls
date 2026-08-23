#!/usr/bin/env wolframscript

(* Exact transfer of the solved CF231 (8,7) rational gauge to CF305. *)

$HistoryLength = 0;

directory = DirectoryName[$InputFileName];
sharpDirectory = FileNameJoin[{DirectoryName[directory],
    "TwoRootCF231Sharp"}];

cf231 = Get[FileNameJoin[{directory, "CF231_8_7_exact_strip.wl"}]];
cf305 = Get[FileNameJoin[{directory, "CF305_8_7_exact_strip.wl"}]];
audit = Get[FileNameJoin[{directory, "CF231_CF305_exact_audit.wl"}]];
candidate = Get[FileNameJoin[{sharpDirectory,
    "CF231_8_7_lifted_exact_check.wl"}]];
residueData = Get[FileNameJoin[{sharpDirectory,
    "CF231_8_7_residue_space.wl"}]];

outputPath = FileNameJoin[{directory,
    "CF231_gauge_transfer_to_CF305_8_7.wl"}];

exactZeroQ[expr_] := TrueQ[Numerator[Cancel[Together[expr]]] === 0];
matrixPairIdentityQ[left_, right_] := And @@ MapThread[
  exactZeroQ[#1 - #2] &, {Flatten[left], Flatten[right]}];

stripIdentities = <|
  "E" -> matrixPairIdentityQ[cf231["E"], cf305["E"]],
  "C" -> matrixPairIdentityQ[cf231["C"], cf305["C"]],
  "Bbar" -> matrixPairIdentityQ[cf231["Bbar"], cf305["Bbar"]]
|>;

{y, s} = cf305["Variables"];
epsilon = cf305["Regulator"];
{e, c} = cf305 /@ {"E", "C"};
gauge = candidate["Gauge"];
residueRules = candidate["ResidueRules"];
forcing = residueData["Forcing"] /. residueRules;
gaugeDerivatives = {D[gauge, y], D[gauge, s]};

residual[mu_Integer, i_Integer, j_Integer] := Cancel[Together[
  gaugeDerivatives[[mu, i, j]] -
    epsilon Sum[e[[mu, i, a]] gauge[[a, j]], {a, 4}] +
    epsilon Sum[gauge[[i, b]] c[[mu, b, j]], {b, 4}] -
    forcing[[mu, i, j]]
]];

kernelCount = Min[4, $ProcessorCount];
LaunchKernels[kernelCount];
DistributeDefinitions[residual, gaugeDerivatives, e, c, forcing,
  epsilon, y, s];
{checkSeconds, residualData} = AbsoluteTiming[
  ParallelTable[
    With[{value = residual[mu, i, j]},
      <|"Index" -> {mu, i, j}, "Zero" -> exactZeroQ[value],
        "Numerator" -> If[exactZeroQ[value], 0, Numerator[value]]|>],
    {mu, 2}, {i, 4}, {j, 4}, Method -> "FinestGrained"]
];
CloseKernels[];

allResidualsZero = And @@ Flatten[Map[#Zero &, residualData, {3}]];
nonzeroResiduals = Cases[Flatten[residualData],
  row_Association /; ! TrueQ[row["Zero"]] :> row];

result = <|
  "SourceFamily" -> "CF231",
  "TargetFamily" -> "CF305",
  "Pair" -> {8, 7},
  "Chart" -> "Kallen23",
  "Transformation" -> audit["FamilyMap", "ExactSubsystemTransformation"],
  "StripIdentities" -> stripIdentities,
  "SourceGaugeClosure" -> candidate["AllResidualsZero"],
  "TargetGaugeClosure" -> allResidualsZero,
  "ExactResidualCount" -> Length[Flatten[residualData]],
  "ExactCheckSeconds" -> checkSeconds,
  "NonzeroResiduals" -> nonzeroResiduals,
  "AcceptanceCriterion" ->
    "E, C, and Bbar are identical under the exact CF231-to-CF305 subsystem map, and all 32 target-family rational-gauge PDE residuals vanish identically",
  "AcceptanceCriterionSatisfied" ->
    And @@ Join[Values[stripIdentities],
      {TrueQ[candidate["AllResidualsZero"]], allResidualsZero}]
|>;

Put[result, outputPath];
Print[InputForm[KeyDrop[result, "NonzeroResiduals"]]];
Exit[If[TrueQ[result["AcceptanceCriterionSatisfied"]], 0, 1]];
