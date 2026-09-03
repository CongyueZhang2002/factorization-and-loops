#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

z = Symbol["Global`endpointResidueZ"];
a = Symbol["Global`endpointResidueA"];
curve = (z - a)^4 + (z - a) + 1;
factor1 = (z - a) (z - a - 1);
factor2 = (z - a) (z - a - 2);
composite = {"Composite", "endpoint-control"};
innerComposite = {"Composite", "endpoint-inner"};
letters = {
  {"GPLPole", a},
  {"GPLFactor", factor1, 0},
  {"E4Pole", a},
  {"E4Factor", factor2, 0},
  {"E4Omega0"}, {"E4OmegaInf"}, {"E4Eta2"},
  composite
};
matrices = {
  SparseArray[{{1, 1} -> 1}, {2, 2}],
  SparseArray[{{1, 2} -> 1}, {2, 2}],
  SparseArray[{{2, 1} -> 1}, {2, 2}],
  SparseArray[{{2, 2} -> 1}, {2, 2}],
  SparseArray[{{1, 1} -> 7}, {2, 2}],
  SparseArray[{{1, 2} -> 7}, {2, 2}],
  SparseArray[{{2, 1} -> 7}, {2, 2}],
  IdentityMatrix[2, SparseArray]
};
definitions = <|composite -> {
  {2, innerComposite},
  {3, {"GPLFactor", factor1, 0}},
  {-5, {"E4Omega0"}}
}, innerComposite -> {{1, {"GPLPole", a}}}|>;

result = BuildCompactEndpointResidue[letters, matrices, z, a,
  "Curve" -> curve, "CompositeDefinitions" -> definitions];
expectedWeights = {1, -1, 1, -1/2, 0, 0, 0, -1};
expectedResidue = {{0, -1}, {1, -3/2}};
FTAssert["symbolic endpoint weights are computed directly for GPL, elliptic, cohomology and composite letters",
  result["Status"] === "CompactEndpointResidueBuilt" &&
    result["MatrixDimensions"] === {2, 2} &&
    Lookup[result["LetterWeights"], "Weight"] === expectedWeights &&
    Normal[result["Residue"]] === expectedResidue &&
    Head[result["Residue"]] === SparseArray];

rectangular = BuildCompactEndpointResidue[
  {{"GPLPole", a}, {"GPLPole", a + 1}},
  {SparseArray[{{1, 2} -> 2}, {2, 3}],
    SparseArray[{{2, 3} -> 7}, {2, 3}]}, z, a];
FTAssert["rectangular off-diagonal decks use the same compact endpoint operation",
  rectangular["Status"] === "CompactEndpointResidueBuilt" &&
    rectangular["MatrixDimensions"] === {2, 3} &&
    MissingQ[rectangular["Dimension"]] &&
    Normal[rectangular["Residue"]] === {{0, 2, 0}, {0, 0, 0}}];

higherPole = BuildCompactEndpointResidue[
  {{"GPLFactor", (z - a)^2 (z - a - 1), 0}},
  {IdentityMatrix[1, SparseArray]}, z, a];
FTAssert["a higher-order endpoint pole is refused before any connection is materialized",
  higherPole["Status"] === "EndpointHigherOrderPole" &&
    higherPole["PoleOrder"] === 2];

degenerateCurve = (z - a)^2 ((z - a)^2 + 1);
FTAssert["a degenerate elliptic curve and a branch-point endpoint are refused distinctly",
  BuildCompactEndpointResidue[{{"E4Omega0"}},
      {IdentityMatrix[1, SparseArray]}, z, a,
      "Curve" -> degenerateCurve]["Status"] === "EllipticCurveDegenerate" &&
    BuildCompactEndpointResidue[{{"E4Omega0"}},
      {IdentityMatrix[1, SparseArray]}, z, a,
      "Curve" -> (z - a) ((z - a)^3 + 1)]["Status"] ===
        "EllipticCurveDegeneratesAtEndpoint"];

FTAssert["composite cycles and unaligned residue matrices fail typed",
  BuildCompactEndpointResidue[{{"Loop"}}, {IdentityMatrix[1]}, z, a,
      "CompositeDefinitions" -> <|{"Loop"} -> {{1, {"Loop"}}}|>]["Status"] ===
        "CompositeLetterCycle" &&
    BuildCompactEndpointResidue[{{"GPLPole", a}, {"GPLPole", a + 1}},
      {ConstantArray[0, {1, 2}], ConstantArray[0, {2, 2}]}, z, a]["Status"] ===
        "EndpointResidueMatricesNotAligned"];

FTSummary[];
