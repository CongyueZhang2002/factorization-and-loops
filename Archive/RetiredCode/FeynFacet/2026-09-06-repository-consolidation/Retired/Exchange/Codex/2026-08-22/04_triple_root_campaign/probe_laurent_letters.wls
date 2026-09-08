#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] < 3, Exit[64]];
projectRoot = ExpandFileName[arguments[[1]]];
recordFile = ExpandFileName[arguments[[2]]];
outputFile = ExpandFileName[arguments[[3]]];

Get[FileNameJoin[{projectRoot, "Addon", "Load", "LoadFACET.wl"}]];
record = Get[recordFile];
solveRecord = KeyTake[record,
  {"Family", "Sector", "LowerSector", "Variables", "Regulator", "Strip"}];
{x, y} = solveRecord["Variables"];
epsilon = solveRecord["Regulator"];
bbar = solveRecord["Strip"][[3]];
baseline = FeynFacet`PrepareEpsFormStripSampling[solveRecord];
baselineAlphabet = baseline["Alphabet"];

sameLetterQ[left_, right_] := Module[{ratio = Together[left/right]},
  FreeQ[ratio, Alternatives[x, y]] && NumericQ[ratio]];
canonical[polynomial_] := Module[{primitive, rules, coefficient},
  primitive = Last[FactorTermsList[Expand[polynomial], {x, y}]];
  rules = CoefficientRules[primitive, {x, y}];
  If[rules === {}, primitive,
    coefficient = Last[First[rules]];
    Together[primitive/coefficient]]
];
factorLetters[expression_] := Module[{q = Together[expression], factors},
  factors = Join[
    Rest[FactorList[Numerator[q]]],
    Rest[FactorList[Denominator[q]]]];
  canonical /@ Select[First /@ factors,
    ! FreeQ[#1, Alternatives[x, y]] && FreeQ[#1, epsilon] &]
];

orders = Range[-2, 6];
coefficientForms = DeleteCases[Flatten[Table[
  Together[SeriesCoefficient[entry, {epsilon, 0, order}]],
  {entry, Flatten[bbar]}, {order, orders}]], 0];
laurentLetters = DeleteDuplicates[
  Flatten[factorLetters /@ coefficientForms], sameLetterQ];
extraLetters = Select[laurentLetters, Function[letter,
  ! AnyTrue[baselineAlphabet, Function[base,
    sameLetterQ[letter, base]]]]];

candidateRecord = Join[solveRecord, <|"ExtraLetters" -> extraLetters|>];
preparation = FeynFacet`PrepareEpsFormStripSampling[candidateRecord];
offsets = {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 0}, {0, 2},
  {2, 1}, {1, 2}, {2, 2}, {3, 0}, {0, 3}, {3, 1}, {1, 3}, {3, 2},
  {2, 3}, {3, 3}};
probes = {};
Do[
  sample = Quiet[FeynFacet`SampleEpsFormStripAffine[
    candidateRecord, 1/7, 1000003,
    "Preparation" -> preparation,
    "ExpectedFingerprint" -> preparation["Fingerprint"],
    "NumeratorDegreeOffset" -> offset,
    "Support" -> "Rectangle",
    "DiscoverPlan" -> False]];
  probe = <|"Offset" -> offset,
    "Status" -> If[AssociationQ[sample],
      If[TrueQ[Lookup[sample, "Consistent", False]], "Consistent",
        "Inconsistent"], "SampleFailed"],
    "MatrixDimensions" -> If[AssociationQ[sample],
      Lookup[sample, "MatrixDimensions", Missing[]], Missing[]],
    "Rank" -> If[AssociationQ[sample], Lookup[sample, "Rank", Missing[]],
      Missing[]],
    "AugmentedRank" -> If[AssociationQ[sample],
      Lookup[sample, "AugmentedRank", Missing[]], Missing[]]|>;
  AppendTo[probes, probe];
  Print["TRLETTERS offset=", offset, " status=", probe["Status"],
    " dimensions=", probe["MatrixDimensions"]];
  If[probe["Status"] === "Consistent", Break[]],
  {offset, offsets}];

output = <|"Source" -> recordFile,
  "Orders" -> orders,
  "BaselineAlphabet" -> baselineAlphabet,
  "LaurentLetters" -> laurentLetters,
  "ExtraLetters" -> extraLetters,
  "ExpandedAlphabet" -> preparation["Alphabet"],
  "GaugeDenominator" -> preparation["GaugeDenominator"],
  "GaugeDenominatorDegrees" -> preparation["DenominatorDegrees"],
  "Probes" -> probes,
  "Consistent" -> AnyTrue[probes,
    Lookup[#1, "Status", None] === "Consistent" &]|>;
temporary = outputFile <> ".tmp";
Put[output, temporary];
RenameFile[temporary, outputFile, OverwriteTarget -> True];

Print["TRLETTERS RESULT baseline=", Length[baselineAlphabet],
  " laurent=", Length[laurentLetters],
  " extra=", Length[extraLetters],
  " expanded=", Length[preparation["Alphabet"]],
  " consistent=", output["Consistent"]];
