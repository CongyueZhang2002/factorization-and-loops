#!/usr/bin/env wolframscript
(* Genuine rank-3 and adversarial contract tests for the round-3 deferred
   construction bundle.  The fixture uses the three independent CF259
   square classes lambda1, lambda3 and Q4, but no family-specific package
   branch: it is ordinary two-variable multiquadratic input. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{prepare, compileBundle, validateBundle, evaluateBundle, fingerprintBundle,
  sourceExpression, algebraicZeroQ, rootFrame, frameCanonicalize,
  fieldDecompose, maskFactor} =
 mq /@ {"blockEquationDeferredPrepare",
   "blockEquationDeferredCompileBundle",
   "blockEquationDeferredBundleValidate",
   "blockEquationDeferredBundleEvaluate",
   "blockEquationDeferredBundleFingerprint",
   "blockEquationDeferredSourceExpression",
   "blockEquationDeferredAlgebraicZeroQ",
   "blockEquationDeferredRootFrame",
   "blockEquationDeferredFrameCanonicalize",
   "multiquadraticFieldDecompose", "multiquadraticMaskFactor"};

Clear[rx, ry, re];
lambda1 = Expand[(1 - rx - ry)^2 - 4 rx ry];
lambda3 = Expand[(1 - rx + ry)^2 + 4 rx ry];
q4 = Expand[4 rx + ry^2];
declaredRoots = {
  <|"Root" -> Sqrt[lambda1], "RootSquare" -> lambda1,
    "SourceIndex" -> 1|>,
  <|"Root" -> Sqrt[lambda3], "RootSquare" -> lambda3,
    "SourceIndex" -> 3|>,
  <|"Root" -> Sqrt[q4], "RootSquare" -> q4,
    "SourceIndex" -> 4|>};
rootExpressions = Lookup[declaredRoots, "Root"];
grade[mask_] := maskFactor[mask, rootExpressions];

(* Every grade is present.  A generic all-grade denominator has a full
   eight-member orbit, so this probes more than a frame declaration. *)
rank3Numerator = Sum[(mask + 2) grade[mask], {mask, 0, 7}];
rank3Divisor = 11 + rx + 2 ry +
  Sum[(2 mask + 1) grade[mask], {mask, 1, 7}];
entryX = rank3Numerator/((1 + rx) rank3Divisor);
entryY = (3 + rx ry + grade[7])/((1 - ry) rank3Divisor^2);
connection = {
  {{0, 0}, {entryX, 0}},
  {{0, 0}, {entryY, 0}}};
ranges = {{1}, {2}};
preparation = prepare[connection, ranges, 2, 1, <||>, {rx, ry}, re];
bundle = compileBundle[preparation, "Roots" -> declaredRoots];

FTAssert["R1 the genuine three-root fixture compiles",
  Lookup[preparation, "Status", None] === "Prepared" &&
    Lookup[bundle, "Status", None] === "PreparedDeferredBundle"];
FTAssert["R2 the bundle carries three independent roots and eight grades",
  Length[bundle["RootFrame"]["Roots"]] === 3 &&
    Length[fieldDecompose[rank3Numerator,
      bundle["RootFrame"]["Roots"]]] === 8];
rank3Channels = fieldDecompose[rank3Numerator,
  bundle["RootFrame"]["Roots"]];
FTAssert["R3 every one of the eight field grades is nonzero",
  MatchQ[rank3Channels, {_, _, _, _, _, _, _, _}] &&
    AllTrue[rank3Channels, ! TrueQ[Together[#] === 0] &]];
FTAssert["R4 the untouched rank-3 bundle passes validation",
  validateBundle[bundle]["Status"] === "BundleValid"];

rank3Evaluation = evaluateBundle[bundle, {}];
frameSquares = Together /@ Lookup[bundle["RootFrame"]["Roots"],
  "RootSquare"];
targets = bundle["TargetOrder"];
FTAssert["R5 bundle assembly equals the deferred source in the rank-3 field",
  Lookup[rank3Evaluation, "Status", None] === "OK" &&
    AllTrue[targets, Function[target,
      TrueQ[algebraicZeroQ[
        rank3Evaluation["Image"][[Sequence @@ target]] -
          sourceExpression[preparation, target], frameSquares]]]]];

rank3Factor = SelectFirst[bundle["DivisorSummary"]["Factors"],
  TrueQ[Lookup[#, "Algebraic", False]] &&
    Lookup[#, "RootMask", 0] === 7 &, Missing["NoRank3Factor"]];
rank3Orbit = If[MissingQ[rank3Factor], Missing["NoRank3Orbit"],
  bundle["DivisorSummary"]["GaloisOrbits"][[rank3Factor["OrbitIndex"]]]];
FTAssert["R6 an algebraic divisor genuinely involving all roots is recorded",
  ! MissingQ[rank3Factor] && ! MissingQ[rank3Orbit]];
FTAssert["R7 its orbit has all eight conjugates and a rational norm",
  ! MissingQ[rank3Orbit] && rank3Orbit["OrbitSize"] === 8 &&
    AllTrue[Values[rank3Orbit["NormCertificate"]], TrueQ] &&
    FreeQ[rank3Orbit["Norm"], Power[_, exponent_Rational /;
      ! IntegerQ[exponent]]]];

frame = rootFrame[declaredRoots, {rx, ry}, re];
tripleComposite = Sqrt[Expand[lambda1 lambda3 q4]];
canonicalComposite = frameCanonicalize[tripleComposite, frame, {rx, ry}];
positivePoint = {rx -> 1/5, ry -> 1/7};
FTAssert["R8 a triple composite radical denests into the declared frame",
  Lookup[canonicalComposite, "Status", None] === "OK" &&
    Lookup[canonicalComposite, "RootIndices", {}] === {1, 2, 3} &&
    TrueQ[Together[canonicalComposite["Expression"]^2 -
      tripleComposite^2] === 0] &&
    Chop[N[(canonicalComposite["Expression"] - tripleComposite) /.
      positivePoint, 50]] === 0];

(* Canonical interning adversary.  These spellings are SameQ-distinct but
   Together-identical.  They must share one evaluated operand. *)
equivalentA = (1 - rx)/(1 - rx^2);
equivalentB = 1/(1 + rx);
equivalentConnection = {
  {{0, 0}, {equivalentA, 0}},
  {{0, 0}, {equivalentB, 0}}};
equivalentPreparation = prepare[equivalentConnection, ranges, 2, 1, <||>,
  {rx, ry}, re];
equivalentBundle = compileBundle[equivalentPreparation, "Roots" -> {}];
FTAssert["A1 the interning adversary really has two raw spellings of one value",
  ! SameQ[equivalentA, equivalentB] &&
    TrueQ[Together[equivalentA - equivalentB] === 0]];
FTAssert["A2 canonical-equivalent operands are interned exactly once",
  Lookup[equivalentBundle, "Status", None] === "PreparedDeferredBundle" &&
    Length[equivalentBundle["OperandTable"]] === 1];

(* A content hash detects accidental mutation only while the stale hash is
   retained.  A validator must also reject a structurally inconsistent
   bundle whose hash has been recomputed, as can happen at an artifact or
   cache boundary. *)
badFactorIndex = Length[bundle["DivisorSummary"]["Factors"]] + 11;
badOccurrence = ReplacePart[bundle,
  {Key["DivisorOccurrences"], 1, Key["FactorIndex"]} -> badFactorIndex];
badOccurrence = Join[badOccurrence,
  <|"BundleFingerprint" -> fingerprintBundle[badOccurrence]|>];
FTAssert["A3 validation rejects a refingerprinted out-of-range factor index",
  validateBundle[badOccurrence]["Status"] =!= "BundleValid"];

firstOccurrence = First[bundle["DivisorOccurrences"]];
occurrenceTarget = firstOccurrence["Target"];
jobIndex = First@FirstPosition[bundle["TargetOrder"], occurrenceTarget];
termIndex = firstOccurrence["TermIndex"];
termOperandIDs = bundle["Jobs"][[jobIndex]]["Terms"][[termIndex, 2]];
otherOperandID = SelectFirst[Range[Length[bundle["OperandTable"]]],
  ! MemberQ[termOperandIDs, #] &, None];
If[otherOperandID === None,
  badOccurrenceOperand = badOccurrence,
  badOccurrenceOperand = ReplacePart[bundle,
    {Key["DivisorOccurrences"], 1, Key["OperandID"]} -> otherOperandID];
  badOccurrenceOperand = Join[badOccurrenceOperand,
    <|"BundleFingerprint" -> fingerprintBundle[badOccurrenceOperand]|>]];
FTAssert["A4 validation checks occurrence provenance against its job term",
  otherOperandID === None ||
    validateBundle[badOccurrenceOperand]["Status"] =!= "BundleValid"];

positiveFrame = rootFrame[{
    <|"Root" -> Sqrt[1 + rx], "RootSquare" -> 1 + rx|>}, {rx, ry}, re];
negativeFrame = rootFrame[{
    <|"Root" -> -Sqrt[1 + rx], "RootSquare" -> 1 + rx|>}, {rx, ry}, re];
FTAssert["A5 root-frame fingerprints distinguish opposite root branches",
  positiveFrame["Status"] === "StableRootOrder" &&
    negativeFrame["Status"] === "StableRootOrder" &&
    positiveFrame["RootFingerprints"] =!= negativeFrame["RootFingerprints"]];

FTReport[];
