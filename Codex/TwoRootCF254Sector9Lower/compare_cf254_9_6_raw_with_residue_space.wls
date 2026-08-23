directory = DirectoryName[$InputFileName];
candidate = Get[FileNameJoin[{directory,
  "CF254_9_6_raw_lifted_candidate.wl"}]];
residueData = Get[FileNameJoin[{directory,
  "CF254_9_6_residue_data.wl"}]];
record = Get[
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
    "sector_CF254_standard/CF254_9_6_input.wl"];

{x, y} = record["Variables"];
epsilon = record["Regulator"];
bbar = record["Strip"][[3]];
alphabet = candidate["Alphabet"];
residueMatrices = candidate["ResidueMatrices"];
dlog = Table[
  Together[D[Log[alphabet[[a]]], record["Variables"][[mu]]]],
  {a, Length[alphabet]}, {mu, 2}];
rawForcing = Table[
  bbar[[mu]] - epsilon Sum[
    residueMatrices[[a]] dlog[[a, mu]], {a, Length[alphabet]}],
  {mu, 2}];

freeResidues = residueData["FreeResidues"];
compatibilityForcing = residueData["Forcing"];
point = {x -> 2/13, y -> 3/17};
pointEquations = Thread[
  Flatten[(compatibilityForcing /. point) - (rawForcing /. point)] == 0];
parameterSolutions = Solve[pointEquations, freeResidues];
If[Length[parameterSolutions] =!= 1,
  Print["The exact residue space did not yield one parameter point: ",
    parameterSolutions];
  Exit[1]
];
parameterRules = First[parameterSolutions];
exactDifference = Map[Together,
  (compatibilityForcing /. parameterRules) - rawForcing, {3}];
checks = Map[TrueQ[# === 0] &, exactDifference, {3}];

result = <|
  "FreeResidueCount" -> Length[freeResidues],
  "ParameterRules" -> parameterRules,
  "ExactForcingAgreement" -> And @@ Flatten[checks],
  "Checks" -> checks
|>;
Put[result, FileNameJoin[{directory,
  "CF254_9_6_raw_residue_space_comparison.wl"}]];
Print[result];
If[! TrueQ[result["ExactForcingAgreement"]], Exit[1]];
