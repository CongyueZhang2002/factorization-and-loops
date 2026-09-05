#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

p = Symbol["Global`ffGaugeP"];
q = Symbol["Global`ffGaugeQ"];
x = Symbol["Global`ffGaugeX"];
y = Symbol["Global`ffGaugeY"];
eps = Symbol["Global`ffGaugeEpsilon"];
primes = {1000003, 2147483423};

(* Rank zero exercises degree discovery, the coupled common-denominator
   solve, held-out x/y/epsilon fibres, CRT and rational lifting. *)
den0 = 1 + p + q + eps p q;
gauge0 = {{(1 + 2 eps + (3 - eps) p + q^2)/den0,
  (2 - eps + p q + eps q^2)/den0}};
rank0 = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gauge0, den0, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 4,
  "MaximumEpsilonTotalDegree" -> 4,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expected0 = gauge0 /. {p -> x, q -> y};
FTAssert["rank-zero finite-field pullback reconstructs the exact gauge",
  Lookup[rank0, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    Dimensions[rank0["Result"]] === Dimensions[gauge0] &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {rank0["Result"], expected0}, 2]]];

(* A source denominator need not have a constant term.  Its rational model
   is projective, so discovery must choose a nonzero denominator coordinate
   rather than assuming one particular monomial can be fixed to one. *)
denNoConstant = p (1 + q);
gaugeNoConstant = {{(1 + eps p + q)/denNoConstant}};
noConstant = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugeNoConstant, denNoConstant, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 3,
  "MaximumEpsilonTotalDegree" -> 3,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expectedNoConstant = gaugeNoConstant /. {p -> x, q -> y};
FTAssert["a denominator with zero constant term is normalized projectively",
  Lookup[noConstant, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    TrueQ[Together[noConstant["Result"][[1, 1]] -
      expectedNoConstant[[1, 1]]] === 0]];

symbolicSmall =
  FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
    gauge0, den0, {p, q}, {x, y}, {x, y}, eps, {},
    "SymbolicPreDispatchSeconds" -> 1.];
FTAssert["a cheap canonical symbolic pullback bypasses modular discovery",
  Lookup[symbolicSmall, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    Lookup[symbolicSmall, "Model", None] === "SymbolicSmallV1" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {symbolicSmall["Result"], expected0}, 2]]];

(* Regression from live CF300 (12,11): one output has a reduced denominator
   that divides the common denominator.  Moving it to the common denominator
   raises its numerator degree, which must be included in the coupled model. *)
denMixed = (1 + p) (1 + q);
gaugeMixed = {{(1 + eps p^2)/denMixed,
  (1 + eps q)/(1 + p)}};
mixed = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugeMixed, denMixed, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 4,
  "MaximumEpsilonTotalDegree" -> 3,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expectedMixed = gaugeMixed /. {p -> x, q -> y};
FTAssert["common-denominator fitting transports reduced numerator degrees",
  Lookup[mixed, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {mixed["Result"], expectedMixed}, 2]]];

(* Two entries can have incompatible reduced denominators even though the
   chart solver reports one common chart denominator.  The whole-matrix model
   must refuse cleanly and the entrywise reduced model must still reconstruct
   canonical entries. *)
denPerEntry = (1 + p) (2 + p);
gaugePerEntry = {{1/(1 + p), 1/(2 + p)}};
perEntry = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugePerEntry, denPerEntry, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 3,
  "MaximumEpsilonTotalDegree" -> 2,
  "MaximumDenominatorCandidates" -> 1,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expectedPerEntry = gaugePerEntry /. {p -> x, q -> y};
FTAssert["incompatible matrix denominators use canonical per-entry models",
  Lookup[perEntry, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    Lookup[perEntry, "Model", None] === "PerEntryDenominatorsV1" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {perEntry["Result"], expectedPerEntry}, 2]]];

(* One algebraic entry can itself have quotient grades with distinct reduced
   denominators.  Their least common denominator is wider than the maximum
   univariate grade degree, so the bounded common-multiple model must widen
   toward the product ceiling and recompute its numerator support there. *)
rPerGrade = Sqrt[1 + y];
rootsPerGrade = {
  <|"Generator" -> rPerGrade, "QuadraticRadicand" -> 1 + y|>};
denPerGrade = (1 + p) (2 + p);
gaugePerGrade = {{((2 + p) + q (1 + p))/denPerGrade}};
perGrade = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugePerGrade, denPerGrade, {p, q}, {x, rPerGrade}, {x, y}, eps,
  rootsPerGrade, "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 3,
  "MaximumEpsilonTotalDegree" -> 2,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expectedPerGrade = gaugePerGrade /. {p -> x, q -> rPerGrade};
FTAssert["one algebraic entry widens across incompatible grade denominators",
  Lookup[perGrade, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    Lookup[perGrade, "Model", None] ===
      "ExpandedCommonDenominatorV1" &&
    TrueQ[Together[perGrade["Result"][[1, 1]] -
      expectedPerGrade[[1, 1]]] === 0]];

(* A degree refusal at the base cap is model information, not permission to
   store a raw composition.  The bounded cap ladder retries the same reduced
   entry and returns only the canonical reconstruction. *)
denRaised = 1 + p;
gaugeRaised = {{(1 + p^5)/(1 + p)}};
raised = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugeRaised, denRaised, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 2,
  "KinematicDegreeSchedule" -> {2, 6},
  "MaximumEpsilonTotalDegree" -> 2,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
FTAssert["the bounded degree ladder returns a reduced gauge only",
  Lookup[raised, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    Lookup[raised, "Model", None] === "CommonDenominatorV1" &&
    Lookup[raised, "KinematicDegreeCap", None] === 6 &&
    TrueQ[Together[raised["Result"][[1, 1]] -
      (gaugeRaised /. {p -> x, q -> y})[[1, 1]]] === 0]];

(* Return inside Do exits only the loop.  A refused entry must therefore be
   propagated explicitly instead of falling through with the untouched zero
   slot mislabeled as a prepared gauge. *)
gaugeRefused = {{(1 + p^7)/(1 + p)}};
refused = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gaugeRefused, 1 + p, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 2,
  "KinematicDegreeSchedule" -> {2, 4},
  "MaximumEpsilonTotalDegree" -> 2,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
FTAssert["a refused entry cannot fall through as a zero prepared gauge",
  Lookup[refused, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionReducedModelRefused" &&
    Lookup[refused, "Entry", None] === {1, 1}];

FTAssert["adaptive epsilon budgets replace the fixed full fibre grid",
  Lookup[rank0, "Model", None] === "CommonDenominatorV1" &&
    Max[Lookup[rank0["PrimeRecords"], "FibreBudget", Infinity]] <
      2 4 + 8];

(* The two cheap budget probes can both hit a zero of the leading epsilon
   coefficient.  That may underestimate work, never correctness: the full
   coefficient interpolation requests more fibres and the retained schedule
   widens without repeating degree discovery. *)
probePrime = First[primes];
probePrimitive = PrimitiveRoot[probePrime];
probeRoots = {
  PowerMod[probePrimitive, 414, probePrime],
  PowerMod[probePrimitive, 427, probePrime]};
gaugeProbeCancellation = {{1 + eps +
  eps^8 (p - probeRoots[[1]]) (p - probeRoots[[2]])}};
probePlan = FeynFacet`Private`finiteFieldBasisTransformationReexpressionPlan[
  gaugeProbeCancellation, 1, {p, q}, {x, y}, {x, y}, eps, {}];
probeRecord = FeynFacet`Private`finiteFieldBasisTransformationReexpressionPrime[
  probePlan, probePrime, "MaximumKinematicTotalDegree" -> 4,
  "MaximumEpsilonTotalDegree" -> 10, "HeldOutPointCount" -> 3];
FTAssert["an underestimated epsilon probe widens its retained fibre schedule",
  Lookup[probeRecord, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionPrimeV1" &&
    Lookup[probeRecord, "FibreBudget", 0] > 9 &&
    Lookup[probeRecord, "FibreBudget", Infinity] < 2 10 + 8];

(* A genuine rank-two inverse map: no split square roots are chosen by the
   production evaluator; the four quotient grades are reconstructed and
   composed only after exact lifting. *)
r1 = Sqrt[1 + x];
r2 = Sqrt[1 + y];
roots = {<|"Generator" -> r1, "QuadraticRadicand" -> 1 + x|>,
  <|"Generator" -> r2, "QuadraticRadicand" -> 1 + y|>};
images = {x + r1, y + r2};
den2 = 1 + p + q + eps p q;
gauge2 = {{(1 + eps + p^2 + q)/den2,
  (2 - eps + p q + eps q^2)/den2}};
rank2 = FeynFacet`Private`reexpressBasisTransformationInSourceVariablesFiniteField[
  gauge2, den2, {p, q}, images, {x, y}, eps, roots,
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 10,
  "MaximumEpsilonTotalDegree" -> 12,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 4];
expected2 = gauge2 /. {p -> images[[1]], q -> images[[2]]};
differences = If[Lookup[rank2, "Status", None] ===
    "FiniteFieldBasisTransformationReexpressionConstructed",
  MapThread[#1 - #2 &, {rank2["Result"], expected2}, 2], {$Failed}];
channels = If[FreeQ[differences, $Failed], Map[
    FeynFacet`Private`multiquadraticFieldDecompose[#, roots] &,
    differences, {2}], {$Failed}];
FTAssert["rank-two finite-field pullback reconstructs every quotient grade",
  Lookup[rank2, "Status", None] ===
      "FiniteFieldBasisTransformationReexpressionConstructed" &&
    FreeQ[channels, $Failed] &&
    And @@ (TrueQ[Together[#] === 0] & /@ Flatten[channels])];

FTAssert["the explicit mode is present without changing the Exact default",
  Lookup[Association[Options[FeynFacet`SolveOffDiagonalBasisTransformationBlock]],
      "BasisTransformationReexpressionMode", None] === "Exact" &&
    MatchQ[Lookup[Association[
      Options[FeynFacet`SolveOffDiagonalBasisTransformationBlock]],
      "BasisTransformationReexpressionFiniteFieldOptions", None], {___Rule}]];

(* Integration seam: the inner rational-chart solve is independent of this
   test.  Return the known Kallen1 chart gauge, then exercise the live inverse
   map, reconstruction branch and the existing post-pullback strip residual. *)
v = Symbol["Global`ffGaugeV"];
w = Symbol["Global`ffGaugeW"];
cx = Symbol["Global`ffGaugeChartX"];
cy = Symbol["Global`ffGaugeChartY"];
lambda1 = (1 - v - w)^2 - 4 v w;
lambda2 = (1 + v - w)^2 + 4 v w;
lambda3 = (1 - v + w)^2 + 4 v w;
frame = FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
  {lambda1, lambda2, lambda3}, {v, w}, {cx, cy}];
knownOffDiagonalBasisTransformationBlock = {{Sqrt[lambda1]}};
zeroOneForm = {ConstantArray[0, {1, 1}], ConstantArray[0, {1, 1}]};
strip = {zeroOneForm, zeroOneForm,
  {D[knownOffDiagonalBasisTransformationBlock, v], D[knownOffDiagonalBasisTransformationBlock, w]}};
integration = Block[{FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField},
  FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record_Association, ___Rule] :=
    Module[{chartVars = record["Variables"]},
      <|"Status" -> "Solved", "Method" -> "InjectedKnownChartGauge",
        "OffDiagonalBasisTransformationBlock" -> {{chartVars[[1]] - chartVars[[2]]}},
        "OffDiagonalBasisTransformationDenominator" -> 1, "Alphabet" -> {},
        "ResidueMatrices" -> {}, "ExactDLog" -> True,
        "Certificate" -> "ExactDLog"|>];
  FeynFacet`SolveOffDiagonalBasisTransformationBlock[strip, {v, w}, eps, frame,
    "BasisTransformationReexpressionMode" -> "FiniteFieldReconstruct",
    "BasisTransformationReexpressionFiniteFieldOptions" -> {
      "Primes" -> primes, "MinimumPrimeCount" -> 2,
      "MaximumPrimeCount" -> 2,
      "MaximumKinematicTotalDegree" -> 2,
      "MaximumEpsilonTotalDegree" -> 2,
      "SymbolicPreDispatchSeconds" -> 0,
      "HeldOutPointCount" -> 3}, "Verbose" -> False]];
FTAssert["the in-frame mode uses the existing post-pullback residual",
  Lookup[integration, "Status", None] === "Solved" &&
    Lookup[Lookup[integration, "Validation", <||>],
      "ValidationMode", None] === "PostPullBackFiniteFieldResidual" &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      integration["OffDiagonalBasisTransformationBlock"][[1, 1]] - Sqrt[lambda1],
      FeynFacet`Private`coefficientPresentationSquareRootsInVariables[
        frame, {v, w}]]]];

(* A failed rational ansatz keeps the already-materialized chart and moves
   only the solve to the conservative rank-zero engine.  Stub both seams so
   this is a routing test, not a second finite-field campaign. *)
fallbackCalled = False;
fallbackIntegration = Block[{FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField,
    FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators},
  FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[___] := $Failed;
  FeynFacet`Private`solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators[
      record_Association, fallbackPresentation_Association, ___Rule] := Module[
    {chartVars = record["Variables"]},
    fallbackCalled =
      fallbackPresentation["DataType"] ===
        "SourceVariableRepresentation" &&
      fallbackPresentation["CoefficientVariables"] === chartVars &&
      FeynFacet`Private`coefficientPresentationSquareRootRecords[
        fallbackPresentation] === {};
    <|"Status" -> "Solved", "Method" -> "InjectedConservativeRankZero",
      "OffDiagonalBasisTransformationBlock" -> {{chartVars[[1]] - chartVars[[2]]}},
      "OffDiagonalBasisTransformationDenominator" -> 1, "Alphabet" -> {},
      "ResidueMatrices" -> {}, "ExactDLog" -> True,
      "Certificate" -> "ExactDLog"|>];
  FeynFacet`SolveOffDiagonalBasisTransformationBlock[strip, {v, w}, eps, frame,
    "Verbose" -> False]];
FTAssert["a failed rational ansatz reuses the chart in the rank-zero solver",
  TrueQ[fallbackCalled] &&
    Lookup[fallbackIntegration, "Status", None] === "Solved" &&
    StringContainsQ[Lookup[fallbackIntegration, "Method", ""],
      "InjectedConservativeRankZero"] &&
    Lookup[Lookup[fallbackIntegration, "InnerSolution", <||>],
      "FallbackCoefficientPresentation", None] ===
        "SourceVariableRepresentationAfterRationalization"];

FTDone[];
