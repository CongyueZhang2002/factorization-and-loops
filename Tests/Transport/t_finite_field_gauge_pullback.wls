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
rank0 = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
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
      "FiniteFieldCanonicalGaugePrepared" &&
    Dimensions[rank0["Result"]] === Dimensions[gauge0] &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {rank0["Result"], expected0}, 2]]];

symbolicSmall =
  FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
    gauge0, den0, {p, q}, {x, y}, {x, y}, eps, {},
    "SymbolicPreDispatchSeconds" -> 1.];
FTAssert["a cheap canonical symbolic pullback bypasses modular discovery",
  Lookup[symbolicSmall, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared" &&
    Lookup[symbolicSmall, "Model", None] === "SymbolicSmallV1" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {symbolicSmall["Result"], expected0}, 2]]];

(* Regression from live CF300 (12,11): one output has a reduced denominator
   that divides the common denominator.  Moving it to the common denominator
   raises its numerator degree, which must be included in the coupled model. *)
denMixed = (1 + p) (1 + q);
gaugeMixed = {{(1 + eps p^2)/denMixed,
  (1 + eps q)/(1 + p)}};
mixed = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
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
      "FiniteFieldCanonicalGaugePrepared" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {mixed["Result"], expectedMixed}, 2]]];

(* Two entries can have incompatible reduced denominators even though the
   chart solver reports one common chart denominator.  The whole-matrix model
   must refuse cleanly and the entrywise reduced model must still reconstruct
   canonical entries. *)
denPerEntry = (1 + p) (2 + p);
gaugePerEntry = {{1/(1 + p), 1/(2 + p)}};
perEntry = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
  gaugePerEntry, denPerEntry, {p, q}, {x, y}, {x, y}, eps, {},
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 3,
  "MaximumEpsilonTotalDegree" -> 2,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 3];
expectedPerEntry = gaugePerEntry /. {p -> x, q -> y};
FTAssert["incompatible matrix denominators use canonical per-entry models",
  Lookup[perEntry, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared" &&
    Lookup[perEntry, "Model", None] === "PerEntryDenominatorsV1" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {perEntry["Result"], expectedPerEntry}, 2]]];

(* One algebraic entry can itself have quotient grades with distinct reduced
   denominators.  Their least common denominator is wider than the maximum
   univariate grade degree, so the entry model must widen toward the product
   ceiling and recompute its numerator support at that width. *)
rPerGrade = Sqrt[1 + y];
rootsPerGrade = {
  <|"Root" -> rPerGrade, "RootSquare" -> 1 + y|>};
denPerGrade = (1 + p) (2 + p);
gaugePerGrade = {{((2 + p) + q (1 + p))/denPerGrade}};
perGrade = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
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
      "FiniteFieldCanonicalGaugePrepared" &&
    Lookup[perGrade, "Model", None] === "PerEntryDenominatorsV1" &&
    TrueQ[Together[perGrade["Result"][[1, 1]] -
      expectedPerGrade[[1, 1]]] === 0]];

(* A degree refusal at the base cap is model information, not permission to
   store a raw composition.  The bounded cap ladder retries the same reduced
   entry and returns only the canonical reconstruction. *)
denRaised = 1 + p;
gaugeRaised = {{(1 + p^5)/(1 + p)}};
raised = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
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
      "FiniteFieldCanonicalGaugePrepared" &&
    Lookup[raised, "Model", None] === "CommonDenominatorV1" &&
    Lookup[raised, "KinematicDegreeCap", None] === 6 &&
    TrueQ[Together[raised["Result"][[1, 1]] -
      (gaugeRaised /. {p -> x, q -> y})[[1, 1]]] === 0]];

(* Return inside Do exits only the loop.  A refused entry must therefore be
   propagated explicitly instead of falling through with the untouched zero
   slot mislabeled as a prepared gauge. *)
gaugeRefused = {{(1 + p^7)/(1 + p)}};
refused = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
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
      "FiniteFieldGaugePullBackReducedModelRefused" &&
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
probePlan = FeynFacet`Private`finiteFieldGaugePullBackPlan[
  gaugeProbeCancellation, 1, {p, q}, {x, y}, {x, y}, eps, {}];
probeRecord = FeynFacet`Private`finiteFieldGaugePullBackPrime[
  probePlan, probePrime, "MaximumKinematicTotalDegree" -> 4,
  "MaximumEpsilonTotalDegree" -> 10, "HeldOutPointCount" -> 3];
FTAssert["an underestimated epsilon probe widens its retained fibre schedule",
  Lookup[probeRecord, "Status", None] ===
      "FiniteFieldGaugePullBackPrimeV1" &&
    Lookup[probeRecord, "FibreBudget", 0] > 9 &&
    Lookup[probeRecord, "FibreBudget", Infinity] < 2 10 + 8];

(* A genuine rank-two inverse map: no split square roots are chosen by the
   production evaluator; the four quotient grades are reconstructed and
   composed only after exact lifting. *)
r1 = Sqrt[1 + x];
r2 = Sqrt[1 + y];
roots = {<|"Root" -> r1, "RootSquare" -> 1 + x|>,
  <|"Root" -> r2, "RootSquare" -> 1 + y|>};
images = {x + r1, y + r2};
den2 = 1 + p + q + eps p q;
gauge2 = {{(1 + eps + p^2 + q)/den2,
  (2 - eps + p q + eps q^2)/den2}};
rank2 = FeynFacet`Private`transportChartFiniteFieldCanonicalGauge[
  gauge2, den2, {p, q}, images, {x, y}, eps, roots,
  "Primes" -> primes, "MinimumPrimeCount" -> 2,
  "MaximumPrimeCount" -> 2,
  "MaximumKinematicTotalDegree" -> 10,
  "MaximumEpsilonTotalDegree" -> 12,
  "SymbolicPreDispatchSeconds" -> 0,
  "HeldOutPointCount" -> 4];
expected2 = gauge2 /. {p -> images[[1]], q -> images[[2]]};
differences = If[Lookup[rank2, "Status", None] ===
    "FiniteFieldCanonicalGaugePrepared",
  MapThread[#1 - #2 &, {rank2["Result"], expected2}, 2], {$Failed}];
channels = If[FreeQ[differences, $Failed], Map[
    FeynFacet`Private`multiquadraticFieldDecompose[#, roots] &,
    differences, {2}], {$Failed}];
FTAssert["rank-two finite-field pullback reconstructs every quotient grade",
  Lookup[rank2, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared" &&
    FreeQ[channels, $Failed] &&
    And @@ (TrueQ[Together[#] === 0] & /@ Flatten[channels])];

FTAssert["the explicit mode is present without changing the Exact default",
  Lookup[Association[Options[FeynFacet`SolveEpsFormStripInFrame]],
      "GaugePullBackMode", None] === "Exact" &&
    MatchQ[Lookup[Association[
      Options[FeynFacet`SolveEpsFormStripInFrame]],
      "GaugePullBackFiniteFieldOptions", None], {___Rule}]];

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
frame = FeynFacet`BuildAlgebraicTransportFrame[
  {lambda1, lambda2, lambda3}, {v, w}, {cx, cy}];
knownGauge = {{Sqrt[lambda1]}};
zeroOneForm = {ConstantArray[0, {1, 1}], ConstantArray[0, {1, 1}]};
strip = {zeroOneForm, zeroOneForm,
  {D[knownGauge, v], D[knownGauge, w]}};
integration = Block[{FeynFacet`SolveEpsFormStripFiniteField},
  FeynFacet`SolveEpsFormStripFiniteField[record_Association, ___Rule] :=
    Module[{chartVars = record["Variables"]},
      <|"Status" -> "Solved", "Method" -> "InjectedKnownChartGauge",
        "Gauge" -> {{chartVars[[1]] - chartVars[[2]]}},
        "GaugeDenominator" -> 1, "Alphabet" -> {},
        "ResidueMatrices" -> {}, "ExactDLog" -> True,
        "Certificate" -> "ExactDLog"|>];
  FeynFacet`SolveEpsFormStripInFrame[strip, {v, w}, eps, frame,
    "FiniteFieldFirst" -> True,
    "GaugePullBackMode" -> "FiniteFieldReconstruct",
    "GaugePullBackFiniteFieldOptions" -> {
      "Primes" -> primes, "MinimumPrimeCount" -> 2,
      "MaximumPrimeCount" -> 2,
      "MaximumKinematicTotalDegree" -> 2,
      "MaximumEpsilonTotalDegree" -> 2,
      "SymbolicPreDispatchSeconds" -> 0,
      "HeldOutPointCount" -> 3}, "Verbose" -> False]];
FTAssert["the in-frame mode uses the existing post-pullback residual",
  Lookup[integration, "Status", None] === "Solved" &&
    Lookup[Lookup[integration, "FrameCertificate", <||>],
      "ValidationMode", None] === "PostPullBackFiniteFieldResidual" &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      integration["Gauge"][[1, 1]] - Sqrt[lambda1],
      frame["Roots"]]]];

(* A failed rational ansatz keeps the already-materialized chart and moves
   only the solve to the conservative rank-zero engine.  Stub both seams so
   this is a routing test, not a second finite-field campaign. *)
fallbackCalled = False;
fallbackIntegration = Block[{FeynFacet`SolveEpsFormStripFiniteField,
    FeynFacet`Private`solveEpsFormStripMultiquadratic},
  FeynFacet`SolveEpsFormStripFiniteField[___] := $Failed;
  FeynFacet`Private`solveEpsFormStripMultiquadratic[
      record_Association, fallbackFrame_Association, ___Rule] := Module[
    {chartVars = record["Variables"]},
    fallbackCalled = fallbackFrame["Roots"] === {} &&
      fallbackFrame["Variables"] === chartVars;
    <|"Status" -> "Solved", "Method" -> "InjectedConservativeRankZero",
      "Gauge" -> {{chartVars[[1]] - chartVars[[2]]}},
      "GaugeDenominator" -> 1, "Alphabet" -> {},
      "ResidueMatrices" -> {}, "ExactDLog" -> True,
      "Certificate" -> "ExactDLog"|>];
  FeynFacet`SolveEpsFormStripInFrame[strip, {v, w}, eps, frame,
    "FiniteFieldFirst" -> True, "Verbose" -> False]];
FTAssert["a failed rational ansatz reuses the chart in the rank-zero solver",
  TrueQ[fallbackCalled] &&
    Lookup[fallbackIntegration, "Status", None] === "Solved" &&
    StringContainsQ[Lookup[fallbackIntegration, "Method", ""],
      "InjectedConservativeRankZero"] &&
    Lookup[Lookup[fallbackIntegration, "InnerSolution", <||>],
      "FallbackFrame", None] === "MaterializedRationalChart"];

FTDone[];
