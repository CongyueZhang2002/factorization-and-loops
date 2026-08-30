#!/usr/bin/env wolframscript
(* Exact rational-DAG materialization and its fail-closed legacy seam.

   The native assertions are conditional because source distributions do not
   contain built binaries.  The public materialization seam must nevertheless
   retain the historical Together result when the accelerator is unavailable
   or the expression lies outside its polynomial-ring contract. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, z, w];
native = FeynFacet`Private`rationalMaterializationFLINTBinary[];
nativeAvailable = StringQ[native] && FileExistsQ[native];
canonical = FeynFacet`Private`rationalMaterializationCanonicalValue;
collect = FeynFacet`Private`rationalMaterializationCollect;
seam = FeynFacet`Private`blockEquationDeferredCanonicalOperandValue;

denominatorProduct[factors_Association] :=
  Times @@ KeyValueMap[#1^#2 &, factors];
representedValue[{numerator_, factors_Association}] :=
  numerator/denominatorProduct[factors];

nativeCases = {
  {(1 - x^2)/(x - 1), {x}},
  {(2/3) (x^2 - y^2)/(x - y), {x, y}},
  {(x^2 - y^2)/((x - y) (1 + x)), {x, y}},
  {(x^2 + y^2 + z^2 + w^2) (x - y)/
      ((x - y) (1 + x)), {x, y, z, w}}
};

nativeResults = If[nativeAvailable,
  Map[Function[testCase, With[{value = collect[First[testCase],
      Last[testCase], FeynFacet`Private`rationalMaterializationFLINTReduce,
      0]}, If[MatchQ[value, {_, _Association, True}],
        value[[1 ;; 2]], $Failed]]], nativeCases],
  {}];

wireFile = CreateTemporary[];
wireWrite = FeynFacet`Private`rationalMaterializationWriteRows[
  wireFile, {{0, -1}, {2, 10^100}}, 1];
wireText = If[StringQ[wireWrite], Import[wireFile, "Text"], ""];
Quiet[DeleteFile[wireFile]];
FTAssert["the native wire format contains bare signed decimal integers",
  StringQ[wireWrite] && StringFreeQ[wireText, "\""] &&
    StringContainsQ[wireText, "0\t-1"] &&
    StringContainsQ[wireText, ToString[10^100, InputForm]]];

FTAssert["native cases reconstruct the exact input",
  ! nativeAvailable || And @@ MapThread[
    MatchQ[#1, {_, _Association}] &&
      TrueQ[Together[representedValue[#1] - First[#2]] === 0] &,
    {nativeResults, nativeCases}]];
FTAssert["signed native gcd preserves its rational unit",
  ! nativeAvailable || SameQ[First[nativeResults], {-1 - x, <||>}]];
FTAssert["rational coefficient content survives native reduction",
  ! nativeAvailable ||
    TrueQ[Together[representedValue[nativeResults[[2]]] -
      (2/3) (x + y)] === 0]];
FTAssert["a genuinely uncancelled factor remains factored",
  ! nativeAvailable ||
    TrueQ[Together[representedValue[nativeResults[[3]]] -
      (x + y)/(1 + x)] === 0] &&
    Total[Values[Last[nativeResults[[3]]]]] === 1];
FTAssert["the backend is not tied to a two-variable polynomial ring",
  ! nativeAvailable ||
    TrueQ[Together[representedValue[nativeResults[[4]]] -
      (x^2 + y^2 + z^2 + w^2)/(1 + x)] === 0]];

edgeCases = {
  {(x^2 - 1)/(x - 1)^2, {x}},
  {((1 + x)/(1 + y))^-2, {x, y}}
};
edgeResults = If[nativeAvailable, Map[Function[testCase,
  collect[First[testCase], Last[testCase],
    FeynFacet`Private`rationalMaterializationFLINTReduce, 0]], edgeCases],
  {}];
FTAssert["repeated factor powers preserve exact multiplicity",
  ! nativeAvailable || MatchQ[edgeResults[[1]], {_, _Association, True}] &&
    TrueQ[Together[representedValue[edgeResults[[1, 1 ;; 2]]] -
      First[edgeCases[[1]]]] === 0]];
FTAssert["a negative power of a rational subtree is collected exactly",
  ! nativeAvailable || MatchQ[edgeResults[[2]], {_, _Association, True}] &&
    TrueQ[Together[representedValue[edgeResults[[2, 1 ;; 2]]] -
      First[edgeCases[[2]]]] === 0]];
FTAssert["zero has the canonical empty denominator map",
  canonical[0, {x, y}] === {0, <||>}];

failureCalls = 0;
failureExpression = 1/((1 + x) (1 + y)) +
  1/((1 + x) (2 + y));
failureResult = collect[failureExpression, {x, y},
  Function[request, failureCalls++; $Failed], 0];
FTAssert["one native refusal aborts the operand without ancestor retries",
  failureResult === $Failed && failureCalls === 1];

small = (1 + x + y)/((1 - x) (1 + y));
smallResult = seam[small, {x, y}];
FTAssert["an already assembled quotient retains the exact fast path",
  MatchQ[smallResult, {_, _Association}] &&
    TrueQ[Together[representedValue[smallResult] - small] === 0]];

rationalSum = 1/(1 + x) + 1/(2 + y);
rationalSumResult = canonical[rationalSum, {x, y}];
FTAssert["a small rational sum retains the exact Together probe result",
  MatchQ[rationalSumResult, {_, _Association}] &&
    TrueQ[Together[representedValue[rationalSumResult] - rationalSum] === 0]];
forcedCollectorResult = Block[{
    FeynFacet`Private`$rationalMaterializationProbeSeconds = 0.},
  canonical[rationalSum, {x, y}]];
FTAssert["an expired probe enters the exact collector",
  MatchQ[forcedCollectorResult, {_, _Association}] &&
    TrueQ[Together[representedValue[forcedCollectorResult] -
      rationalSum] === 0]];

algebraic = Sqrt[2]/(1 - x) + 1/(2 + x);
algebraicResult = Block[{
    FeynFacet`Private`$rationalMaterializationProbeSeconds = 0.},
  seam[algebraic, {x}]];
FTAssert["unsupported algebraic nodes fail closed to Together",
  MatchQ[algebraicResult, {_, _Association}] &&
    TrueQ[Together[representedValue[algebraicResult] - algebraic] === 0]];

FTAssert["an incomplete explicit polynomial ring is refused",
  Block[{FeynFacet`Private`$rationalMaterializationProbeSeconds = 0.},
    FeynFacet`Private`rationalMaterializationCanonicalValue[
      1/(1 + y) + 1/(2 + y), {x}]] === $Failed];
FTAssert["non-rational numeric coefficients are refused",
  Block[{FeynFacet`Private`$rationalMaterializationProbeSeconds = 0.},
    FeynFacet`Private`rationalMaterializationCanonicalValue[
      Sqrt[2]/x + 1/(1 + x), {x}]] === $Failed];

FTReport[];
