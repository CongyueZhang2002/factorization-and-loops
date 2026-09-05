#!/usr/bin/env wolframscript
(* Check levels (user decision 2026-08-22: checks stay separate from the
   calculation).  The production guards -- exact-rational evaluation at
   random points -- must accept the true objects and reject corrupted ones,
   and a production assembly must produce the SAME connection as a
   development assembly. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
checks = <||>;

(* point zero test *)
Clear[x, y, e];
checks["PointZeroAcceptsIdentity"] = FeynFacet`Private`masterTransportPointZeroQ[
  {{(x^2 - y^2) - (x - y) (x + y), e/(1 + e) - 1 + 1/(1 + e)}}, {x, y, e}];
checks["PointZeroRejectsNonzero"] = ! FeynFacet`Private`masterTransportPointZeroQ[
  {{(x^2 - y^2) - (x - y) (x + y) + e x/(1 + y)}}, {x, y, e}];
checks["PointZeroSurvivesPoles"] = FeynFacet`Private`masterTransportPointZeroQ[
  {{1/(x - 1/2) - 1/(x - 1/2)}}, {x, y, e}];

(* Finite-field Pfaffian check on a self-contained exact dlog block. *)
fixture = <|"Variables" -> {x, y}, "Regulator" -> e,
  "OffDiagonalBlockEquation" -> {
    {{{0}}, {{0}}}, {{{0}}, {{0}}},
    {{{2 e/x}}, {{-3 e/y}}}}|>;
stored = <|"OffDiagonalBasisTransformationBlock" -> {{0}},
  "Alphabet" -> {x, y}, "ResidueMatrices" -> {{{2}}, {{-3}}}|>;
{tN, vN} = AbsoluteTiming[
  FeynFacet`VerifyOffDiagonalBasisTransformationBlock[
    fixture, stored, "Method" -> "Numerical"]];
checks["NumericalVerifyAcceptsTrueGauge"] =
  TrueQ[vN["DLogFormCertified"]] &&
    vN["CheckMethod"] === "Numerical" && tN < 30;
bad = Join[stored, <|"OffDiagonalBasisTransformationBlock" ->
    ReplacePart[stored["OffDiagonalBasisTransformationBlock"],
      {1, 1} -> e x]|>];
vB = FeynFacet`VerifyOffDiagonalBasisTransformationBlock[
  fixture, bad, "Method" -> "Numerical"];
checks["NumericalVerifyRejectsCorruptedBasisTransformationBlock"] =
  vB["NumericalPfaffianResidualsZero"] === False &&
    vB["DLogFormCertified"] === False;
badR = Join[stored, <|"ResidueMatrices" ->
    ReplacePart[stored["ResidueMatrices"],
      {1, 1, 1} -> stored["ResidueMatrices"][[1, 1, 1]] + 1]|>];
checks["NumericalVerifyRejectsCorruptedResidue"] =
  FeynFacet`VerifyOffDiagonalBasisTransformationBlock[
    fixture, badR, "Method" -> "Numerical"]["DLogFormCertified"] === False;

(* solver: Numerical final check gives the same gauge as Exact on a synthetic block *)
Clear[xH, yH, epsH];
record = <|"Variables" -> {xH, yH}, "Regulator" -> epsH,
  "OffDiagonalBlockEquation" -> {{{{1}}, {{0}}}, {{{0}}, {{0}}}, {{{1 - epsH xH}}, {{0}}}}|>;
common = {"Primes" -> {1000003, 2147483423, 2147483477}, "EpsilonSamples" -> ((#/(# + 20)) & /@ Range[12]),
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}}, "PointCount" -> 8, "KernelCount" -> 1, "ConstructionCount" -> 6,
  "MaximumTotalDegree" -> 4, "MinimumPrimeCount" -> 3, "AdaptiveValidationMargin" -> 4, "Verbose" -> False};
exact = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, Sequence @@ common];
numerical = FeynFacet`SolveOffDiagonalBasisTransformationBlockFiniteField[record, "FinalCheck" -> "Numerical", Sequence @@ common];
checks["NumericalFinalCheckSameGauge"] = AssociationQ[exact] && AssociationQ[numerical] &&
  numerical["Status"] === "Solved" && numerical["Certificate"] === "NumericalResidual" &&
  MissingQ[numerical["ExactDLog"]] && Map[Together, numerical["OffDiagonalBasisTransformationBlock"], {2}] === Map[Together, exact["OffDiagonalBasisTransformationBlock"], {2}] &&
  numerical["ResidueMatrices"] === exact["ResidueMatrices"];

(* Assembly: production and development checks must return the same
   mathematical connection.  Keep this fixture V2 and self-contained; the
   migrated V1 CF34 files are deliberately not live package inputs. *)
Clear[xA, yA, epsA];
family = "CheckLevelToy";
system = <|"Family" -> family, "Basis" -> {m1, m2},
  "Av" -> epsA {{1/xA, 0}, {1/(1 + xA), 2/xA}},
  "Aw" -> ConstantArray[0, {2, 2}]|>;
blocks = {{{1}, Automatic}, {{2}, Automatic}};
assemble[level_] := Block[{FeynFacet`Private`masterTransportCheckLevel = (level &)},
  FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
    system, None, "SourceVariables" -> {xA, yA},
    "Regulator" -> epsA, "Blocks" -> blocks, "Verbose" -> False]];
{tD, dev} = AbsoluteTiming[assemble["Development"]];
{tP, prod} = AbsoluteTiming[assemble["Production"]];
If[! (AssociationQ[dev] && dev["Status"] ===
    "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks"),
  Print["development assembly: ",
    If[AssociationQ[dev], KeyDrop[dev, "FamilyDifferentialSystem"], dev]]];
checks["AssemblyBothModesSucceed"] = AssociationQ[dev] && AssociationQ[prod] &&
  dev["Status"] === "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks" &&
  prod["Status"] === "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks";
checks["AssemblyProductionSameConnection"] = checks["AssemblyBothModesSucceed"] &&
  dev["FamilyDifferentialSystem"]["Apv"] === prod["FamilyDifferentialSystem"]["Apv"] &&
  dev["FamilyDifferentialSystem"]["Apw"] === prod["FamilyDifferentialSystem"]["Apw"];
checks["AssemblyProductionLabelled"] = checks["AssemblyBothModesSucceed"] &&
  prod["FamilyDifferentialSystem"]["Certificate"]["CheckLevel"] === "Production" &&
  dev["FamilyDifferentialSystem"]["Certificate"]["CheckLevel"] === "Development";

(* A validated non-scalar diagonal form is installed directly in production;
   development still re-derives the same conjugated block. *)
t2 = {{xA, 0}, {0, 1}};
ti2 = {{1/xA, 0}, {0, 1}};
e2v = epsA {{1/xA, 0}, {0, 2/xA}};
a2v = Map[Together, t2 . e2v . ti2 + D[t2, xA] . ti2, {2}];
system2 = <|"Family" -> "CheckLevelNonScalarToy", "Basis" -> {m1, m2},
  "Av" -> a2v, "Aw" -> ConstantArray[0, {2, 2}]|>;
record2 = <|"DataType" -> "DiagonalBlockDLogEpsilonForm",
  "SchemaVersion" -> 2, "Status" -> "DLogEpsilonFormValidated",
  "BlockRows" -> {1, 2}, "CoefficientVariables" -> {xA, yA},
  "DimensionalRegulator" -> epsA,
  "BasisTransformationMatrix" -> t2, "Letters" -> {xA},
  "ConstantResidueMatrices" -> {{{1, 0}, {0, 2}}},
  "Validation" -> <|"Passed" -> True|>|>;
assemble2[level_] := Block[{
    FeynFacet`Private`masterTransportCheckLevel = (level &)},
  FeynFacet`AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
    system2, None, "SourceVariables" -> {xA, yA},
    "Regulator" -> epsA, "Blocks" -> {{{1, 2}, record2}},
    "Verbose" -> False]];
dev2 = assemble2["Development"];
prod2 = assemble2["Production"];
checks["ValidatedNonScalarProductionSameConnection"] =
  AssociationQ[dev2] && AssociationQ[prod2] &&
  dev2["FamilyDifferentialSystem", "Apv"] ===
    prod2["FamilyDifferentialSystem", "Apv"] &&
  dev2["FamilyDifferentialSystem", "Apw"] ===
    prod2["FamilyDifferentialSystem", "Apw"];
checks["ProductionDefersDuplicateDiagonalIdentities"] =
  MissingQ[prod2["FamilyDifferentialSystem", "Certificate",
    "DiagonalEqualsDeclaredForm"]] &&
  MissingQ[prod2["FamilyDifferentialSystem", "Certificate",
    "TransformationInverseVerified"]] &&
  prod2["FamilyDifferentialSystem", "Certificate",
    "FlatnessConjugatedRoute"] === "DeferredToFamilyCertificate";
Print["synthetic assembly seconds: development ", Round[tD, 0.1],
  " production ", Round[tP, 0.1]];
Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#] &]]];
Exit[If[And @@ Values[checks], 0, 1]];
