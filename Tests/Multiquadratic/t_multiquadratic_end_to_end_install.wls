#!/usr/bin/env wolframscript
(* Small end-to-end promotion: internally constructed dlog -> provider-backed
   rational-in-epsilon reconstruction -> active-support certification ->
   installable off-diagonal basis transformation. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
solve = mq["solveEpsFormStripMultiquadratic"];
rowForm = mq["familyRowGaugeDLogForm"];

Clear[x, y, eps, cx, cy];
delta = 1 + x;
frame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {delta}, {x, y}, {cx, cy}];

(* The known gauge occupies the odd root grade with rational denominator Q.
   The nonzero residue on dlog(x) forces a genuinely active installed letter. *)
gauge = {{Sqrt[delta]/delta}};
e = {{{0}}, {{0}}};
c = {{{0}}, {{0}}};
oneForm = {1/x, 0};
bbar = Table[Map[Together,
    D[gauge, {x, y}[[mu]]] + eps oneForm[[mu]], {2}], {mu, 2}];
record = <|"Family" -> "END_TO_END_INSTALL", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {e, c, bbar}|>;

result = solve[record, frame,
  "CoefficientProvider" -> "SplitBranch",
  "AdditionalLetters" -> {x}, "AlgebraicLetters" -> {},
  "GaugeDenominator" -> delta, "GaugeDenominatorFactor" -> 1,
  "Support" -> {{0, 0}},
  "RegulatorSampleCount" -> 2, "DLogKernels" -> 1,
  "IntegrabilityScreen" -> False, "ScreenFirst" -> False,
  "GaugeScreen" -> False, "RegulatorReconstruction" -> True,
  "RegulatorReconstructionCheck" -> "ProviderPoints",
  "ReconstructionUnseenPrimeCount" -> 2,
  "ReconstructionFreshPointwiseChecksPerPrime" -> 3];

If[Lookup[result, "Status", None] =!= "Solved",
  Print["DIAGNOSTIC result: ", InputForm[result]]];

check["the direct solver promotes the reconstructed block to Solved",
  Lookup[result, "Status", None] === "Solved" &&
    Lookup[result, "Method", None] ===
      "DirectMultiquadraticFiniteField" &&
    Lookup[result, "SolutionContract", None] ===
      "InstallableMultiquadraticDLogV1"];
check["the generic gauge, not one regulator fibre, is installed",
  TrueQ[Together[First[First[result["Gauge"]]] -
      First[First[gauge]]] === 0]];
check["active support contains the certified dlog(x) contribution",
  MemberQ[Lookup[result, "Alphabet", {}], x] &&
    TrueQ[Lookup[result, "OneFormsCertified", False]] &&
    Length[Lookup[result, "ResidueMatrices", {}]] >= 1];
check["active certification carries the full verified one-form data",
  AllTrue[Lookup[result, "OneForms", {}], MatchQ[#1, {_, _}] &] &&
    MemberQ[Lookup[result, "OneForms", {}], oneForm]];
check["fresh residual evidence meets the accepted 2 x 3 policy",
  Lookup[Lookup[result, "InstallationEvidence", <||>], "Status", None] ===
      "InstallationEvidenceAccepted" &&
    Lookup[result["InstallationEvidence"], "ValidationPrimeCount", 0] >= 2 &&
    Lookup[result["InstallationEvidence"], "ValidationImageCount", 0] >= 6];
check["reconstruction exposes coefficient data and mathematical image keys",
  AssociationQ[Lookup[result["RegulatorReconstruction"],
      "CoefficientData", None]] &&
    With[{keys = Lookup[result["RegulatorReconstruction"],
        "TrainingImageKeys", {}]}, keys =!= {} &&
      AllTrue[keys, MatchQ[#, {_Integer?PrimeQ,
        _Integer | _Rational, {_Integer, _Integer}}] &]]];
check["top-level performs no affine solve after reconstructed fresh checks",
  Lookup[result, "PostReconstructionAffineSolveCount", -1] === 0 &&
    Lookup[result, "FullAffineSolveCount", -1] ===
      Lookup[result["RegulatorReconstruction"], "FullAffineSolveCount", -2]];
check["installed summary retains adaptive prime-count telemetry",
  ListQ[Lookup[result["RegulatorReconstruction"],
      "LiftAttemptHistory", None]] &&
    IntegerQ[Lookup[result["RegulatorReconstruction"],
      "CoefficientHeight", None]] &&
    IntegerQ[Lookup[result["RegulatorReconstruction"],
      "ActualMinimumPrimeCount", None]] &&
    Lookup[result["RegulatorReconstruction"], "ActualPrimeCount", None] ===
      Length[Lookup[result["RegulatorReconstruction"],
        "SamplePrimes", {}]] &&
    Lookup[result["RegulatorReconstruction"],
      "ActualMinimumPrimeCountBasis", None] ===
        "ExactSymmetricHeightBoundOverAcceptedPrimePrefixes"];

installedForm = If[Lookup[result, "Status", None] === "Solved",
  rowForm[result, {x, y}, eps, {1, 1}], $Failed];
check["FamilyRowGauge consumes the certified forms without redifferentiation",
  ListQ[installedForm] &&
    TrueQ[Together[installedForm[[1, 1, 1]] - eps/x] === 0] &&
    TrueQ[Together[installedForm[[2, 1, 1]]] === 0]];

Print["t_multiquadratic_end_to_end_install: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
