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
  "HeldOutPointCount" -> 3];
expected0 = gauge0 /. {p -> x, q -> y};
FTAssert["rank-zero finite-field pullback reconstructs the exact gauge",
  Lookup[rank0, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared" &&
    Dimensions[rank0["Result"]] === Dimensions[gauge0] &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {rank0["Result"], expected0}, 2]]];

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
  "HeldOutPointCount" -> 3];
expectedMixed = gaugeMixed /. {p -> x, q -> y};
FTAssert["common-denominator fitting transports reduced numerator degrees",
  Lookup[mixed, "Status", None] ===
      "FiniteFieldCanonicalGaugePrepared" &&
    And @@ Flatten[MapThread[TrueQ[Together[#1 - #2] === 0] &,
      {mixed["Result"], expectedMixed}, 2]]];

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
      "HeldOutPointCount" -> 3}, "Verbose" -> False]];
FTAssert["the in-frame mode uses the existing post-pullback residual",
  Lookup[integration, "Status", None] === "Solved" &&
    Lookup[Lookup[integration, "FrameCertificate", <||>],
      "ValidationMode", None] === "PostPullBackFiniteFieldResidual" &&
    TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
      integration["Gauge"][[1, 1]] - Sqrt[lambda1],
      frame["Roots"]]]];

FTDone[];
