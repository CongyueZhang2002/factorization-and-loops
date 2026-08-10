$HistoryLength = 0;
$IterationLimit = 10^6;

Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];

root = "/mnt/c/Users/congyue zhang/Desktop/Mathematica/Hard Function";
input = Get[FileNameJoin[{root, "EvaluateMasters", "NLO", "Input.wl"}]];
reference = Get[FileNameJoin[{
  root, "EvaluateMasters", "validation", "NLO", "amflow_reference.wl"
}]];

familyNames = reference["FamilyArguments"];
requested = Select[Rest[$ScriptCommandLine], MemberQ[familyNames, #] &];
familyNames = If[requested === {}, familyNames, requested];

point = {s -> 10, t -> -3, u -> -2, Epsilon -> -1/10};
expected = AssociationMap[
  ToExpression[reference["Values"][#] <> "`18", InputForm] &,
  Prepend[familyNames, "Bubble"]
];

data[name_, masters_] := <|
  "Master" -> masters,
  "Topology" -> input["Topologies"][name],
  "CutIndices" -> input["CutPositions"],
  "CutDirections" -> ConstantArray[1, Length[input["CutPositions"]]],
  "Prescription" -> {0}
|>;

values = <||>;
Do[
  topology = input["Topologies"][name];
  family = topology[[1]];
  masters = If[
    name === First[familyNames],
    {
      FeynCalc`GLI[family, {1, 1, 1, 1}],
      FeynCalc`GLI[family, {1, 1, 0, 0}]
    },
    {FeynCalc`GLI[family, {1, 1, 1, 1}]}
  ];
  result = FeynFacet`MasterIntegralAmFlow[
    data[name, masters],
    point,
    "PrecisionGoal" -> 18,
    "EpsilonOrder" -> 0,
    "Threads" -> 1,
    "TimeConstraint" -> 1200
  ];
  If[result === $Failed, Print["FAILED: ", name]; Exit[1]];
  If[ListQ[result],
    values[name] = First[result];
    values["Bubble"] = Last[result],
    values[name] = result
  ];
  Print[name, " = ", InputForm[values[name]]],
  {name, familyNames}
];

differences = AssociationMap[
  Abs[values[#] - expected[#]] &,
  Keys[values]
];
relativeDifferences = AssociationMap[
  differences[#]/Abs[expected[#]] &,
  Keys[values]
];
criterion = And @@ (# < 10^-15 & /@ Values[relativeDifferences]);

Print["Values: ", InputForm[values]];
Print["Relative differences: ", InputForm[relativeDifferences]];
Print["Acceptance criterion max relative difference < 10^-15: ", criterion];

Put[
  <|
    "Point" -> point,
    "Values" -> values,
    "Expected" -> KeyTake[expected, Keys[values]],
    "RelativeDifferences" -> relativeDifferences,
    "AcceptanceCriterion" -> HoldForm[MaxRelativeDifference < 10^-15],
    "CriterionSatisfied" -> criterion
  |>,
  "/home/maxzhang/FACET/Codex/Tests/master_integral_nlo_result.wl"
];

Exit[If[criterion, 0, 1]];
