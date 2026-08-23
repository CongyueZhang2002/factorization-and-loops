recordPath =
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819/" <>
   "sector_CF254_standard/CF254_9_8_unsolved.wl";
residuePath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_residue_data.wl"}];
outputPath = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_sample_system.mx"}];
blockDirectory = FileNameJoin[{DirectoryName[$InputFileName],
    "CF254_9_8_sample_blocks"}];

epsilonValue = 1/7;
prime = 1000003;

If[! DirectoryQ[blockDirectory], CreateDirectory[blockDirectory]];

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

Print["Gauge denominator degrees: ", {degreeX, degreeY}];
Print["Gauge coefficient count: ", Length[coefficientVariables]];
Print["Free residue count: ", Length[freeResidues]];

blockFiles = Table[
  FileNameJoin[{blockDirectory,
    "block_" <> IntegerString[index, 10, 2] <> ".mx"}],
  {index, Length[Flatten[residual]]}
];

Do[
  If[FileExistsQ[blockFiles[[index]]],
    Print["Component ", index, "/", Length[blockFiles],
      " already checkpointed"],
    {blockSeconds, Null} = AbsoluteTiming[
      entry = Flatten[residual][[index]];
      numeratorPolynomial = Expand[Numerator[Together[entry]]];
      equations = DeleteCases[
        DeleteDuplicates[Values[
          CoefficientRules[numeratorPolynomial, {x, y}]]], 0];
      arrays = CoefficientArrays[equations, unknowns];
      If[Length[arrays] =!= 2,
        Print["Component ", index,
          " is nonlinear in the ansatz coefficients"];
        Exit[2]
      ];
      blockConstant = SparseArray[arrays[[1]]];
      blockMatrix = SparseArray[arrays[[2]]];
      blockEquationCount = Length[equations];
      DumpSave[blockFiles[[index]],
        {blockConstant, blockMatrix, blockEquationCount}];
    ];
    Print["Component ", index, "/", Length[blockFiles],
      ": ", blockEquationCount, " equations, ",
      Dimensions[blockMatrix][[1]], " rows, ",
      Length[blockMatrix["NonzeroValues"]], " nonzero entries, ",
      blockSeconds, " s"];
    Clear[entry, numeratorPolynomial, equations, arrays,
      blockConstant, blockMatrix, blockEquationCount];
    ClearSystemCache[]
  ],
  {index, Length[blockFiles]}
];

constantBlocks = {};
matrixBlocks = {};
equationCounts = {};
Do[
  Clear[blockConstant, blockMatrix, blockEquationCount];
  Get[file];
  AppendTo[constantBlocks, blockConstant];
  AppendTo[matrixBlocks, blockMatrix];
  AppendTo[equationCounts, blockEquationCount],
  {file, blockFiles}
];

constant = Join @@ constantBlocks;
matrix = Join @@ matrixBlocks;
Print["Linear matrix dimensions: ", Dimensions[matrix],
  ", nonzero entries: ", Length[matrix["NonzeroValues"]],
  ", component equation counts: ", equationCounts];

{rankSeconds, rank} = AbsoluteTiming[
  MatrixRank[matrix, Modulus -> prime]
];
augmented = Join[
  matrix,
  SparseArray[List /@ (-Normal[constant])],
  2
];
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
Print["Saved: ", outputPath, " (", FileByteCount[outputPath],
  " bytes)"];
