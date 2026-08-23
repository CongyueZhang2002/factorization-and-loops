#!/usr/bin/env wolframscript
(* Check levels (user decision 2026-08-22: checks stay separate from the
   calculation).  The production guards -- exact-rational evaluation at
   random points -- must accept the true objects and reject corrupted ones,
   and a production assembly must produce the SAME connection as a
   development assembly. *)
root = ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
checks = <||>;
B = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "BenchmarkStripBackends"}];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];

(* point zero test *)
Clear[x, y, e];
checks["PointZeroAcceptsIdentity"] = FeynFacet`Private`masterTransportPointZeroQ[
  {{(x^2 - y^2) - (x - y) (x + y), e/(1 + e) - 1 + 1/(1 + e)}}, {x, y, e}];
checks["PointZeroRejectsNonzero"] = ! FeynFacet`Private`masterTransportPointZeroQ[
  {{(x^2 - y^2) - (x - y) (x + y) + e x/(1 + y)}}, {x, y, e}];
checks["PointZeroSurvivesPoles"] = FeynFacet`Private`masterTransportPointZeroQ[
  {{1/(x - 1/2) - 1/(x - 1/2)}}, {x, y, e}];

(* numerical Pfaffian check on the stored canonical (9,6) result *)
fixture = FeynFacet`FamilyArtifactRead[FileNameJoin[{B, "fixtures", "fixture_CF254_9_6.wl"}]];
stored = FeynFacet`FamilyArtifactRead[FileNameJoin[{B, "frozen_M0", "a4_run", "result_A4_CF254_9_6_FiniteField.wl"}]]["BackendResult"];
{tN, vN} = AbsoluteTiming[FeynFacet`VerifyEpsFormStrip[fixture, stored, "Method" -> "Numerical"]];
checks["NumericalVerifyAcceptsTrueGauge"] = TrueQ[vN["DLogFormCertified"]] && vN["CheckMethod"] === "Numerical" && tN < 30;
bad = Join[stored, <|"Gauge" -> ReplacePart[stored["Gauge"], {1, 1} -> stored["Gauge"][[1, 1]] + fixture["Regulator"] First[fixture["Variables"]]]|>];
vB = FeynFacet`VerifyEpsFormStrip[fixture, bad, "Method" -> "Numerical"];
checks["NumericalVerifyRejectsCorruptedGauge"] = vB["NumericalPfaffianResidualsZero"] === False && vB["DLogFormCertified"] === False;
badR = Join[stored, <|"ResidueMatrices" -> ReplacePart[stored["ResidueMatrices"], {1, 2, 1} -> stored["ResidueMatrices"][[1, 2, 1]] + 1]|>];
checks["NumericalVerifyRejectsCorruptedResidue"] = FeynFacet`VerifyEpsFormStrip[fixture, badR, "Method" -> "Numerical"]["DLogFormCertified"] === False;

(* solver: Numerical final check gives the same gauge as Exact on a synthetic block *)
Clear[xH, yH, epsH];
record = <|"Variables" -> {xH, yH}, "Regulator" -> epsH,
  "Strip" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}}, {{{1 - epsH xH}}, {{0}}}}|>;
common = {"Primes" -> {1000003, 2147483423, 2147483477}, "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}}, "PointCount" -> 8, "KernelCount" -> 1, "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4, "MinimumPrimeCount" -> 3, "AdaptiveValidationMargin" -> 4, "Verbose" -> False};
exact = FeynFacet`SolveEpsFormStripFiniteField[record, Sequence @@ common];
numerical = FeynFacet`SolveEpsFormStripFiniteField[record, "FinalCheck" -> "Numerical", Sequence @@ common];
checks["NumericalFinalCheckSameGauge"] = AssociationQ[exact] && AssociationQ[numerical] &&
  numerical["Status"] === "Solved" && numerical["Certificate"] === "NumericalResidual" &&
  MissingQ[numerical["ExactDLog"]] && Map[Together, numerical["Gauge"], {2}] === Map[Together, exact["Gauge"], {2}] &&
  numerical["ResidueMatrices"] === exact["ResidueMatrices"];

(* assembly: production == development on a small family (CF34, dim 8) *)
assignments = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "BlockClasses", "block_class_assign.wl"}]];
family = "CF34";
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
de = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"], "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
chart = FeynFacet`TransportFamilyChart[family];
If[chart === None,   (* root-free family: the identity chart, as the sector script does *)
  chart = <|"Name" -> "RationalIdentity", "Kind" -> "TwoVariable", "CoefficientField" -> "Rational",
    "Variables" -> {Global`x, Global`y}, "Subst" -> {Global`v -> Global`x, Global`w -> Global`y},
    "Root" -> None, "RootSquare" -> None, "Roots" -> {}, "Notes" -> "identity chart"|>];
assemble[level_] := Block[{FeynFacet`Private`masterTransportCheckLevel = (level &)},
  FeynFacet`TransportFamilyInChart[system, chart, "SourceVariables" -> {Global`v, Global`w}, "Regulator" -> Global`eps,
    "AssemblyOnly" -> True, "Blocks" -> blocks, "FormDirectory" -> FileNameJoin[{R, "ClassForms"}],
    "PhysicalValuation" -> 0, "Orders" -> {0, 1}, "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
{tD, dev} = AbsoluteTiming[assemble["Development"]];
{tP, prod} = AbsoluteTiming[assemble["Production"]];
If[! (AssociationQ[dev] && dev["Status"] === "ExactFamilyAssembly"), Print["development assembly: ", If[AssociationQ[dev], KeyDrop[dev, "Assembly"], dev]]];
checks["AssemblyBothModesSucceed"] = AssociationQ[dev] && AssociationQ[prod] &&
  dev["Status"] === "ExactFamilyAssembly" && prod["Status"] === "ExactFamilyAssembly";
checks["AssemblyProductionSameConnection"] = checks["AssemblyBothModesSucceed"] &&
  dev["Assembly"]["Apv"] === prod["Assembly"]["Apv"] && dev["Assembly"]["Apw"] === prod["Assembly"]["Apw"];
checks["AssemblyProductionLabelled"] = checks["AssemblyBothModesSucceed"] &&
  prod["Assembly"]["Certificate"]["CheckLevel"] === "Production" &&
  dev["Assembly"]["Certificate"]["CheckLevel"] === "Development";
Print["CF34 assembly seconds: development ", Round[tD, 0.1], " production ", Round[tP, 0.1]];
Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#] &]]];
Exit[If[And @@ Values[checks], 0, 1]];
