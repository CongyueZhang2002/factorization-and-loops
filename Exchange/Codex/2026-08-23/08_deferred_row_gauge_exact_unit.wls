#!/usr/bin/env wolframscript
(* Exact sequential gate for:
     installed row 1 + deferred future A
     -> constant regulator factor on the completed prefix
     -> installed row 2.
   Run only after the candidate private regulator propagation helper is
   installed.  No parallel kernels are requested by this harness. *)

root = ParentDirectory[
  ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps];
zeroQ[expression_] := TrueQ[Together[expression] === 0];
matrixZeroQ[matrix_] := AllTrue[Flatten[{matrix}], zeroQ];
sameMatrixQ[left_, right_] := Dimensions[left] === Dimensions[right] &&
  matrixZeroQ[left - right];
sameConnectionQ[left_, right_] := Dimensions[left] === Dimensions[right] &&
  And @@ MapThread[sameMatrixQ, {left, right}];
transformConnection[connection_, transformation_, inverse_] := Table[
  Map[Together,
    inverse . connection[[mu]] . transformation -
      inverse . D[transformation, {x, y}[[mu]]], {2}],
  {mu, 2}];

n = 5;
r1 = Sqrt[1 + x + x^2];
r2 = Sqrt[1 - 4 x y];
r3 = Sqrt[4 y + x^2];
grades = {1, r1, r2, r1 r2, r3, r1 r3, r2 r3, r1 r2 r3};
connection = Table[
  Table[If[i < j, 0,
    grades[[1 + Mod[7 mu + 3 i + 2 j, Length[grades]]]]
      (eps + mu + i x + j y)/(1 + i + 2 j + x + 3 y)],
    {i, n}, {j, n}],
  {mu, 2}];

(* First completed row: two rows over the first lower column. *)
rows1 = {2, 3}; columns1 = {1};
gauge1 = {{x/(1 + y)}, {r1 r3/(2 + x)}};
d1 = ConstantArray[0, {n, n}];
d1[[rows1, columns1]] = gauge1;
t1 = IdentityMatrix[n] + d1;
t1Inverse = IdentityMatrix[n] - d1;
expected1 = transformConnection[connection, t1, t1Inverse];
installed1 = expected1[[All, rows1, columns1]];
deferred1 = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows1, gauge1,
  {x, y}, installed1, "Deferred"];

FTTest`FTAssert["first deferred row accepted",
  AssociationQ[deferred1] && deferred1["Status"] === "OK"];
FTTest`FTAssert["first deferred row is dense-equivalent",
  sameConnectionQ[deferred1["Connection"], expected1] &&
    sameMatrixQ[deferred1["Transformation"], t1] &&
    sameMatrixQ[deferred1["Inverse"], t1Inverse]];
rawAfterRow1 = Select[
  Tuples[{Range[2], Range[4, n], columns1}],
  With[{entry = Extract[deferred1["Connection"], #]},
    ! SameQ[entry, Together[entry]]] &];
FTTest`FTAssert["first row leaves a literal future raw sum",
  rawAfterRow1 =!= {} &&
    deferred1["Statistics", "A", "DeferredFutureEntries"] > 0];

(* Constant factor on the completed 3x3 prefix.  Its lower-triangular
   off-diagonal entries force genuine multi-term future right-products. *)
prefix = 3;
regulatorT = {{1, 0, 0},
  {eps/(1 + eps), 1, 0},
  {1/(2 + eps), eps/(3 + eps), 1}};
regulatorInverse = Map[Together, Inverse[regulatorT], {2}];
gFull = IdentityMatrix[n];
gFull[[1 ;; prefix, 1 ;; prefix]] = regulatorT;
gFullInverse = IdentityMatrix[n];
gFullInverse[[1 ;; prefix, 1 ;; prefix]] = regulatorInverse;
expectedRegulated = Table[
  Map[Together,
    gFullInverse . expected1[[mu]] . gFull, {2}], {mu, 2}];
transformedPrefix =
  expectedRegulated[[All, Range[prefix], Range[prefix]]];
regulatorSeal = FeynFacet`Private`familyRegulatorPropagationSeal[
  deferred1["Connection"][[All, Range[prefix], Range[prefix]]],
  transformedPrefix, regulatorInverse, regulatorT];

deferredRegulator =
  FeynFacet`Private`familyRegulatorPropagateTruncation[
    deferred1["Connection"], transformedPrefix, regulatorInverse,
    regulatorT, prefix, {x, y}, regulatorSeal, "Deferred"];
togetherRegulator =
  FeynFacet`Private`familyRegulatorPropagateTruncation[
    deferred1["Connection"], transformedPrefix, regulatorInverse,
    regulatorT, prefix, {x, y}, regulatorSeal, "Together"];

FTTest`FTAssert["deferred regulator propagation accepted",
  AssociationQ[deferredRegulator] &&
    deferredRegulator["Status"] === "OK"];
FTTest`FTAssert["deferred regulator propagation is exact",
  sameConnectionQ[deferredRegulator["Connection"], expectedRegulated]];
FTTest`FTAssert["Together regulator control is exact",
  AssociationQ[togetherRegulator] &&
    togetherRegulator["Status"] === "OK" &&
    sameConnectionQ[togetherRegulator["Connection"], expectedRegulated] &&
    sameConnectionQ[togetherRegulator["Connection"],
      deferredRegulator["Connection"]]];
rawAfterRegulator = Select[
  Tuples[{Range[2], Range[prefix + 1, n], Range[prefix]}],
  With[{entry = Extract[deferredRegulator["Connection"], #]},
    ! SameQ[entry, Together[entry]]] &];
FTTest`FTAssert["regulator future block retains raw exact sums",
  rawAfterRegulator =!= {} &&
    deferredRegulator["Statistics", "FutureAMode"] === "Deferred" &&
    deferredRegulator["Statistics", "DeferredFutureEntries"] > 0 &&
    deferredRegulator["Statistics", "SingleTermFastPath"] > 0];

badUpper = deferred1["Connection"];
badUpper[[1, 1, prefix + 1]] = 1;
badPropagation = FeynFacet`Private`familyRegulatorPropagateTruncation[
  badUpper, transformedPrefix, regulatorInverse, regulatorT, prefix,
  {x, y}, regulatorSeal, "Deferred"];
FTTest`FTAssert["regulator propagation rejects a nonzero upper-right block",
  AssociationQ[badPropagation] &&
    badPropagation["Status"] === "InvalidBlockStructure"];
badVariableTransformation =
  FeynFacet`Private`familyRegulatorPropagateTruncation[
    deferred1["Connection"], transformedPrefix, regulatorInverse,
    ReplacePart[regulatorT, {1, 1} -> 1 + x], prefix, {x, y},
    regulatorSeal, "Deferred"];
badInversePropagation =
  FeynFacet`Private`familyRegulatorPropagateTruncation[
    deferred1["Connection"], transformedPrefix,
    ReplacePart[regulatorInverse, {1, 1} -> 2], regulatorT, prefix,
    {x, y}, regulatorSeal, "Deferred"];
badSealPropagation =
  FeynFacet`Private`familyRegulatorPropagateTruncation[
    deferred1["Connection"], transformedPrefix, regulatorInverse,
    regulatorT, prefix, {x, y}, Join[regulatorSeal,
      <|"Fingerprint" -> StringRepeat["0", 64]|>], "Deferred"];
FTTest`FTAssert["regulator helper rejects a kinematic transformation",
  badVariableTransformation["Status"] ===
    "RegulatorTransformationNotConstant"];
FTTest`FTAssert["regulator helper rejects a false inverse",
  badInversePropagation["Status"] ===
    "RegulatorTransformationInverseInvalid"];
FTTest`FTAssert["regulator helper rejects a mismatched factor seal",
  badSealPropagation["Status"] === "RegulatorPropagationSealMismatch"];

(* The transformation matrices remain on the historical Together route. *)
sRegulated = FeynFacet`Private`familyRegulatorSparseDot[
  deferred1["Transformation"], gFull, False];
siRegulated = FeynFacet`Private`familyRegulatorSparseDot[
  gFullInverse, deferred1["Inverse"], True];
FTTest`FTAssert["regulated transformation inverse is exact",
  matrixZeroQ[sRegulated . siRegulated - IdentityMatrix[n]] &&
    matrixZeroQ[siRegulated . sRegulated - IdentityMatrix[n]]];
sDirectionSwap = FeynFacet`Private`familyRegulatorSparseDot[
  gFull, deferred1["Transformation"], True];
siDirectionSwap = FeynFacet`Private`familyRegulatorSparseDot[
  deferred1["Inverse"], gFullInverse, False];
FTTest`FTAssert["left-multiplying S is an adversarial direction mutant",
  ! matrixZeroQ[sDirectionSwap . siRegulated - IdentityMatrix[n]] &&
    ! sameMatrixQ[sDirectionSwap, sRegulated]];
FTTest`FTAssert["right-multiplying SInverse is an adversarial direction mutant",
  ! matrixZeroQ[sRegulated . siDirectionSwap - IdentityMatrix[n]] &&
    ! sameMatrixQ[siDirectionSwap, siRegulated]];
swappedBothConnection = transformConnection[
  connection, sDirectionSwap, siDirectionSwap];
FTTest`FTAssert["mutually inverse double swap still implements the wrong gauge",
  matrixZeroQ[sDirectionSwap . siDirectionSwap - IdentityMatrix[n]] &&
    ! sameConnectionQ[swappedBothConnection, expectedRegulated]];

(* The later completed row consumes and overwrites the deferred future block. *)
rows2 = {4, 5}; columns2 = Range[3];
gauge2 = {{r2/(1 + x), 0, r1 r2/(2 + y)},
  {r3/(2 + x), r1/(1 + x + y), r2 r3/(3 + y)}};
d2 = ConstantArray[0, {n, n}];
d2[[rows2, columns2]] = gauge2;
t2 = IdentityMatrix[n] + d2;
t2Inverse = IdentityMatrix[n] - d2;
expectedFinal = transformConnection[expectedRegulated, t2, t2Inverse];
installed2 = expectedFinal[[All, rows2, columns2]];
deferred2 = FeynFacet`Private`familyRowGaugeApply[
  deferredRegulator["Connection"], sRegulated, siRegulated,
  rows2, gauge2, {x, y}, installed2, "Deferred"];
expectedS = Map[Together, t1 . gFull . t2, {2}];
expectedSInverse = Map[Together,
  t2Inverse . gFullInverse . t1Inverse, {2}];

FTTest`FTAssert["second deferred row accepted",
  AssociationQ[deferred2] && deferred2["Status"] === "OK"];
FTTest`FTAssert["sequential final connection is exact",
  sameConnectionQ[deferred2["Connection"], expectedFinal]];
FTTest`FTAssert["sequential final transformations are exact",
  sameMatrixQ[deferred2["Transformation"], expectedS] &&
    sameMatrixQ[deferred2["Inverse"], expectedSInverse] &&
    matrixZeroQ[deferred2["Transformation"] . deferred2["Inverse"] -
      IdentityMatrix[n]]];
FTTest`FTAssert["last row has no future entries to defer",
  deferred2["Statistics", "A", "FutureCandidateEntries"] === 0 &&
    deferred2["Statistics", "A", "DeferredFutureEntries"] === 0];

FTTest`FTReport[];
