$HistoryLength = 0;

args = Rest[$ScriptCommandLine];
taskFile = args[[1]];
outputFile = args[[2]];
maximumNumeratorDegree = If[Length[args] >= 3, ToExpression[args[[3]]], 6];
maximumDenominatorDegree = If[Length[args] >= 4, ToExpression[args[[4]]], 1];
candidateSeconds = If[Length[args] >= 5, ToExpression[args[[5]]], 1800];
minimumNumeratorDegree = If[Length[args] >= 6, ToExpression[args[[6]]], 1];
minimumDenominatorDegree = If[Length[args] >= 7, ToExpression[args[[7]]], 0];

Catch[
ClearAll[Global`x, Global`y, Global`eps];
Get["/home/maxzhang/FACET/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m"];
CANONICA`$ComputeParallel = False;
CANONICA`Private`$ComputeParallel = False;

resolveCanonica[name_String] := Module[
  {public = ToExpression["CANONICA`" <> name],
   private = ToExpression["CANONICA`Private`" <> name]},
  Which[
    DownValues[Evaluate[public]] =!= {}, public,
    DownValues[Evaluate[private]] =!= {}, private,
    True, $Failed
  ]
];

task = Get[taskFile];
sector = If[AssociationQ[task], Lookup[task, "Sector", Missing["NotRecorded"]],
  Missing["NotRecorded"]];
lowerSector = If[AssociationQ[task],
  Lookup[task, "LowerSector", Missing["NotRecorded"]], Missing["NotRecorded"]];
{e, c, bbar} = If[AssociationQ[task] && KeyExistsQ[task, "E"],
  Lookup[task, {"E", "C", "BBar"}],
  Take[task, 3]];
invariants = If[AssociationQ[task],
  Lookup[task, "Invariants", {Global`x, Global`y}], {Global`x, Global`y}];
{e, c, bbar} = {e, c, bbar} /. Global`eps -> CANONICA`eps;

findD = resolveCanonica["FindD"];
extractIrreducibles = resolveCanonica["ExtractIrreducibles"];
checkDlog = resolveCanonica["CheckDlogForm"];

If[MemberQ[{findD, extractIrreducibles, checkDlog}, $Failed],
  result = <|"Sector" -> sector, "LowerSector" -> lowerSector,
    "ExactDLog" -> False, "Status" -> "CANONICAFunctionMissing"|>;
  Put[result, outputFile];
  Throw[result]];

irred = extractIrreducibles[{e, c, bbar},
  CANONICA`AllowEpsDependence -> True];
alphabet = Union[invariants, Select[irred, FreeQ[#, CANONICA`eps] &]];
configurations = Flatten[
  Table[{numeratorDegree, denominatorDegree},
    {denominatorDegree, minimumDenominatorDegree, maximumDenominatorDegree},
    {numeratorDegree, minimumNumeratorDegree, maximumNumeratorDegree}],
  1];

attempts = {};
result = $Failed;
Do[
  config = configurations[[index]];
  Print["Trying strip ", {sector, lowerSector},
    " with numerator degree ", config[[1]],
    ", denominator degree ", config[[2]]];
  {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
    findD[e, c, bbar, alphabet, invariants, {},
      CANONICA`DDeltaNumeratorDegree -> config[[1]],
      CANONICA`DDeltaDenominatorDegree -> config[[2]],
      CANONICA`VerbosityLevel -> 0],
    candidateSeconds, $TimedOut]]];

  If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
    AppendTo[attempts, <|
      "NumeratorDegree" -> config[[1]],
      "DenominatorDegree" -> config[[2]],
      "Seconds" -> elapsed,
      "Status" -> Which[
        gauge === $TimedOut, "TimedOut",
        gauge === False, "NoGauge",
        True, "InvalidResult"]|>];
    Continue[]];

  transformed = Table[Map[Together,
    bbar[[mu]] + CANONICA`eps (e[[mu]].gauge - gauge.c[[mu]]) -
      D[gauge, invariants[[mu]]], {2}], {mu, Length[invariants]}];
  exactQ = TrueQ[checkDlog[transformed, invariants, alphabet]];
  AppendTo[attempts, <|
    "NumeratorDegree" -> config[[1]],
    "DenominatorDegree" -> config[[2]],
    "Seconds" -> elapsed,
    "Status" -> If[exactQ, "ExactDLog", "FailedDLogIdentity"]|>];

  If[exactQ,
    result = <|
      "Sector" -> sector,
      "LowerSector" -> lowerSector,
      "ExactDLog" -> True,
      "NumeratorDegree" -> config[[1]],
      "DenominatorDegree" -> config[[2]],
      "Attempts" -> attempts,
      "Gauge" -> (gauge /. CANONICA`eps -> Global`eps)|>;
    Break[]],
  {index, Length[configurations]}];

If[result === $Failed,
  result = <|
    "Sector" -> sector,
    "LowerSector" -> lowerSector,
    "ExactDLog" -> False,
    "Status" -> "NoExactGaugeInSearchRange",
    "Attempts" -> attempts|>];

Put[result, outputFile];
KeyDrop[result, "Gauge"]
]
