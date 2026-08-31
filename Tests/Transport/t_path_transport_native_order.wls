#!/usr/bin/env wolframscript

(* Packed multiquadratic source-order provider.  The toy exercises three
   independent root grades and positive, zero and negative epsilon orders. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

private[name_] := Symbol["FeynFacet`Private`" <> name];
x = Global`nativeOrderX; y = Global`nativeOrderY;
eps = Global`nativeOrderEps;
deltas = {(1 + x)^2, (1 + y)^2, 1 + x + y};
roots = Sqrt /@ deltas;

assembly = <|"Blocks" -> {{1}, {2}, {3}},
  "Ranges" -> {{1}, {2}, {3}}|>;
ax = ConstantArray[0, {3, 3}];
ay = ConstantArray[0, {3, 3}];
ax[[2, 1]] = (1 + Total[roots])/eps^2;
ax[[3, 1]] = eps^2/(1 + eps);
ay[[3, 2]] = (1 + eps)/eps;

result = private["pathTransportNativeSourceOrderTable"][assembly,
  {ax, ay}, {x, y}, eps, deltas,
  "PointCount" -> 2, "EpsilonImageCount" -> 12,
  "MaximumTotalDegree" -> 6, "HeldOutCount" -> 3,
  "Threads" -> 2, "Seed" -> 271828];

FTAssert["native order table returns its typed success",
  AssociationQ[result] &&
    Lookup[result, "Status", None] === "NativeTransportOrderTableV1"];
FTAssert["three lower edges have their exact epsilon valuations",
  result["OrderTable"][[2, 1]] === -2 &&
    result["OrderTable"][[3, 1]] === 2 &&
    result["OrderTable"][[3, 2]] === -1];
FTAssert["upper triangle and diagonal cannot enter the depth budget",
  And @@ Flatten[Table[
    If[i <= j, result["OrderTable"][[i, j]] === Infinity, True],
    {i, 3}, {j, 3}]]];
FTAssert["independent split points agree on the complete table",
  TrueQ[result["PointTablesAgreeQ"]] &&
    result["DifferingEdges"] === {}];

badPrime = private["pathTransportNativeSourceOrderTable"][assembly,
  {ax, ay}, {x, y}, eps, deltas,
  "Prime" -> 2305843009213691993, "PointCount" -> 1,
  "EpsilonImageCount" -> 8, "MaximumTotalDegree" -> 2,
  "Threads" -> 1];
FTAssert["the p mod 4 = 1 square-root route refuses immediately",
  Lookup[badPrime, "Status", None] === "NativeTransportPrimeInvalid"];

malformed = private["masterTransportDepthBudgetFromTable"][assembly,
  {{Infinity, Infinity, Infinity}, {1/2, Infinity, Infinity},
    {0, Infinity, Infinity}}, 3];
FTAssert["the depth recurrence refuses a noninteger lower-edge order",
  Lookup[malformed, "Status", None] === "InvalidOrderTable" &&
    Lookup[malformed, "InvalidEdges", {}] === {{2, 1}}];

(* Selected-sheet path jets: the first two roots rationalize on the path;
   the third remains one continued quadratic root. *)
z = Global`nativeOrderZ; tau = Global`nativeOrderTau;
r = Global`nativeOrderR;
contract = <|"Status" -> "ExactParametricPathContractV1",
  "Family" -> "TOY", "HardSector" -> 3, "Chart" -> "ToyRank3",
  "FrozenCoordinates" -> <||>, "Variables" -> {x, y},
  "PathVariable" -> z, "SourcePath" -> <|x -> z, y -> z^2|>,
  "SourceRootSquares" -> deltas,
  "SourceRootBranches" -> {1 + z, 1 + z^2, r},
  "SourceRootRules" -> Thread[Sqrt[deltas] -> {1 + z, 1 + z^2, r}],
  "PathExtension" -> <|"Type" -> "Quadratic", "Root" -> r,
    "RootSquare" -> 1 + z + z^2, "Representation" -> "ExplicitSqrt",
    "BranchConvention" -> "toy continued sheet"|>|>;
(* This prime is 3 mod 4 and the residual root square 31/25 at z=1/5
   is a nonzero quadratic residue, so Automatic selects a split sheet. *)
prime = 2305843009213681999;
series = private["pathTransportNativeSeriesData"][{ax, ay}, {x, y},
  eps, deltas, contract, {1/5, 3/5}, tau, Range[-2, 5],
  prime, 4, "EpsilonImageCount" -> 12, "MaximumTotalDegree" -> 6,
  "HeldOutCount" -> 3, "Threads" -> 2, "Seed" -> 314159];
FTAssert["rank-three selected-sheet path jets interpolate successfully",
  Lookup[series, "Status", None] === "NativeTransportSeriesDataV1" &&
    Sort[series["RequestedOrders"]] === Range[-2, 5]];
modRational[q_] := Mod[Numerator[q] PowerMod[Denominator[q], -1, prime],
  prime];
z0 = modRational[1/5];
dz = modRational[2/5];
root0 = series["SheetValue"];
expected21 = Mod[dz (1 + (1 + z0) + (1 + z0^2) + root0), prime];
FTAssert["path pullback multiplies the x-form by dx/dtau once",
  series["PathCoefficientJets"][-2][[2, 1, 1]] === expected21];
expectedYDerivative = {modRational[4/25], modRational[8/25], 0, 0, 0};
FTAssert["epsilon Laurent extraction and y-path tangent are exact jets",
  series["PathCoefficientJets"][-1][[3, 2]] === expectedYDerivative &&
    series["PathCoefficientJets"][0][[3, 2]] === expectedYDerivative];
FTAssert["a positive epsilon coefficient survives native interpolation",
  series["PathCoefficientJets"][2][[3, 1, 1]] === dz];

budget = private["masterTransportDepthBudgetFromTable"][assembly,
  result["OrderTable"], 2];
graph = private["pathTransportNativeFormalGraph"][assembly, budget,
  {0, 0, 0}, {2, 2, 2}, tau, eps];
constants = Function[{block, order, component},
  Mod[100 block + 10 (order + 10) + component, prime]];
evaluation = private["pathTransportNativeFormalEvaluate"][graph, series,
  assembly, "ConstantValues" -> constants, "TauOrder" -> 4];
acceptance = private["pathTransportNativeFormalAccept"][graph,
  evaluation, series, assembly, constants];
FTAssert["native providers build and evaluate the complete formal graph",
  Lookup[graph, "Status", None] === "OKFormalLowerGraph" &&
    Lookup[evaluation, "Status", None] ===
      "OKModularGraphSeriesBatch"];
FTAssert["one direct modular differential-equation acceptance closes",
  Lookup[acceptance, "Status", None] ===
      "NativeTransportFormalAcceptedV1" &&
    acceptance["ResidualCoefficientCount"] > 0 &&
    acceptance["BasepointCoefficientCount"] > 0];
private["pathTransportExceptionFormalRelease"][graph];

FTTest`FTReport[];
