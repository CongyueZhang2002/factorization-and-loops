recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";
residuePath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_residue_data.wl"}];
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_sample_system.mx"}];

epsilonValue = 1/7;
prime = 1000003;

record = Get[recordPath];
residueData = Get[residuePath];
{x, y} = record["Variables"];
epsilon = record["Regulator"];
{e, c, bbar} = record["Strip"];
forcing = residueData["Forcing"];
freeResidues = residueData["FreeResidues"];

doublePoleFactors = {
  -1 + x,
  -1 + 2 x - y,
  -1 + 2 x + y,
  3 + 4 x^2 + 2 y - y^2,
  -1 + 6 x + 2 x y + y^2,
  -3 + 4 x + 4 x^2 - 2 y + 4 x y + y^2,
  -9 - 11 epsilon + 12 x + 24 epsilon x + 12 x^2 +
    12 epsilon x^2 - 6 y - 6 epsilon y + 12 x y +
    16 epsilon x y + 3 y^2 + 5 epsilon y^2
};

gaugeDenominator = Times @@ doublePoleFactors;
degreeX = Exponent[gaugeDenominator, x];
degreeY = Exponent[gaugeDenominator, y];

coefficientVariables =
  Flatten@Array[a, {4, 2, degreeX + 1, degreeY + 1}];
numerator = Table[
  Sum[
    a[i, j, px + 1, py + 1] x^px y^py,
    {px, 0, degreeX}, {py, 0, degreeY}
  ],
  {i, 4}, {j, 2}
];
gauge = numerator/gaugeDenominator;
unknowns = Join[coefficientVariables, freeResidues];

sampleRules = {epsilon -> epsilonValue};
sampleGauge = gauge /. sampleRules;
sampleE = e /. sampleRules;
sampleC = c /. sampleRules;
sampleForcing = forcing /. sampleRules;

residual = Table[
  D[sampleGauge, {x, y}[[mu]]] -
    epsilonValue (sampleE[[mu]].sampleGauge -
      sampleGauge.sampleC[[mu]]) - sampleForcing[[mu]],
  {mu, 2}
];

ClearAll[entryEquations];
entryEquations[entry_] := Module[{numeratorPolynomial},
  numeratorPolynomial = Expand[Numerator[Together[entry]]];
  Values[CoefficientRules[numeratorPolynomial, {x, y}]]
];

needed = 4;
If[Length[Kernels[]] < needed,
  launched = Quiet[LaunchKernels[needed - Length[Kernels[]]]],
  launched = {}
];
DistributeDefinitions[entryEquations, x, y];

Print["Gauge denominator degrees: ", {degreeX, degreeY}];
Print["Gauge coefficient count: ", Length[coefficientVariables]];
Print["Free residue count: ", Length[freeResidues]];

{equationSeconds, equationBlocks} = AbsoluteTiming[
  ParallelMap[
    entryEquations,
    Flatten[residual],
    Method -> "FinestGrained",
    DistributedContexts -> Automatic
  ]
];
If[launched =!= {}, Quiet[CloseKernels[launched]]];

equations = DeleteCases[DeleteDuplicates@Flatten[equationBlocks], 0];
Print["Polynomial equations: ", Length[equations],
  " in ", equationSeconds, " s"];

{arraySeconds, arrays} = AbsoluteTiming[
  CoefficientArrays[equations, unknowns]
];
If[Length[arrays] =!= 2,
  Print["Nonlinear coefficient array depth: ", Length[arrays]];
  Exit[2]
];

constant = SparseArray[Normal[arrays[[1]]]];
matrix = SparseArray[arrays[[2]]];
Print["Linear matrix dimensions: ", Dimensions[matrix],
  ", nonzero entries: ", Length[matrix["NonzeroValues"]],
  ", built in ", arraySeconds, " s"];

{rankSeconds, rank} = AbsoluteTiming[
  MatrixRank[matrix, Modulus -> prime]
];
augmented = Join[matrix, SparseArray[List /@ (-Normal[constant])], 2];
{augmentedRankSeconds, augmentedRank} = AbsoluteTiming[
  MatrixRank[augmented, Modulus -> prime]
];

Print["Prime: ", prime, ", rank: ", rank,
  ", augmented rank: ", augmentedRank,
  ", nullity: ", Length[unknowns] - rank];
Print["Rank seconds: ", rankSeconds,
  ", augmented-rank seconds: ", augmentedRankSeconds];
Print["Consistent at sample: ", TrueQ[rank === augmentedRank]];

DumpSave[outputPath, {
  epsilonValue, prime, gaugeDenominator, degreeX, degreeY,
  unknowns, constant, matrix, rank, augmentedRank
}];
Print["Saved: ", outputPath, " (", FileByteCount[outputPath], " bytes)"];
