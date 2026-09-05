#!/usr/bin/env wolframscript
(* RATIONAL-IN-EPSILON RECONSTRUCTION (round-2 wave item 6; Codex review
   1.1, steps 1-5).

   THE GAP.  The direct multiquadratic route solved the whole unknown
   vector INDEPENDENTLY at every (prime, regulator value), checked only
   that rank/nullity/pivot signatures agreed, and published the gauge and
   residues of the FIRST epsilon fiber.  A stable pivot structure does
   not establish that those independently chosen particular solutions are
   evaluations of ONE rational vector (g(eps), K(eps)).  What was missing
   is the algorithm between the ModularConsistent contract and a solved
   object: one canonical affine section across epsilon images, adaptive
   rational interpolation of EVERY coordinate in the regulator,
   validation at held-out epsilon images and an unseen prime, the
   CRT/rational lift, and reinstallation of the generic object in the
   differential equation.

   THE FIXTURE has a KNOWN answer, built so that publishing one fiber is
   demonstrably not the generic object: a 1x1 block with flat diagonal
   pair, a gauge whose coefficients are RATIONAL FUNCTIONS OF THE
   REGULATOR, and residues K_a(eps) that genuinely depend on eps.

     Q      = 1 - x - y                    (the gauge denominator)
     G      = (1 + eps x - 2 y/(1 + eps)) / Q
     letters {x, y, 1 - x - y, 1 + x + y}
     K      = {0, 0, eps/(1 + 2 eps), -3/(1 + eps)}
     Bbar_mu = d_mu G + eps Sum_a K_a omega_a,mu     (E = C = 0)

   The ansatz is PINNED with the same Q and the support {1, x, y}, so the
   exact coefficient vector is known coordinate by coordinate and the
   reconstruction can be compared against it, not merely to itself.

   ACCEPTANCE CRITERIA, stated before the run.

   R1  The reconstruction returns "ReconstructedRegulatorDependenceV1".
   R2  Its VECTOR is the known solution projected onto the same canonical
       affine section, coordinate by coordinate.  The affine family here
       is one-dimensional (the constant gauge is homogeneous when
       E = C = 0), so "the" solution does not exist and the section is
       what makes the answer unique -- which is precisely the part of
       Codex 1.1 that the fiberwise route lacked.  Its gauge therefore
       differs from the known one by a kinematics-constant direction and
       by nothing else.
   R3  Its residues equal the known K_a(eps) exactly and are free of the
       kinematic variables.
   R4  Those residues genuinely DEPEND on eps -- otherwise the fixture
       would not separate the reconstruction from the fiberwise route.
   R5  The reconstructed GENERIC object satisfies the differential
       equation exactly (the residual is zero at symbolic eps), which is
       the statement the fixed exact verifier of item 2 makes.
   R6  The record carries the evidence: the canonical affine section, the
       coefficient image check at the sampled primes, the unseen-prime
       coefficient check, and a held-out validation per prime.
   R7  THE ADVERSARIAL POINT.  The vector of ONE epsilon fiber -- what
       the pre-fix route published -- is NOT the generic object: its
       residues differ from K(eps), and installing it as the generic
       gauge fails the exact generic residual.
   R8  The reconstruction is not accidentally a constant fit: the degree
       histogram records at least one coordinate of positive regulator
       degree, and the maximum recorded degree is at least 1. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, reconstruct, unpack, residual, letterOneForm} =
 mq /@ {"multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockCompile",
   "multiquadraticOffDiagonalBlockReconstructRegulator",
   "multiquadraticOffDiagonalBlockUnpackVector",
   "multiquadraticOffDiagonalBlockExactChannelResidual",
   "multiquadraticOffDiagonalBlockLetterOneForm"};

Clear[rx, ry, re];
frame = <|"Name" -> "Round2Rational", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {rx, ry},
  "Subst" -> {rx -> rx, ry -> ry}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;

letters = {rx, ry, 1 - rx - ry, 1 + rx + ry};
forms = letterOneForm[#1, {rx, ry}] & /@ letters;
(* the engine canonicalizes a supplied gauge denominator (each factor
   scaled to a unit leading coefficient: 1 - rx - ry becomes
   -1 + rx + ry), so the known coefficients are read off in the engine's
   own form of the denominator *)
denominator = FeynFacet`Private`multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator[
  1 - rx - ry, 1, {rx, ry}];
knownOffDiagonalBasisTransformationBlock = {{Together[(1 + re rx - 2 ry/(1 + re))/denominator]}};
knownResidues = {{{0}}, {{0}}, {{re/(1 + 2 re)}}, {{-3/(1 + re)}}};
inhomogeneity = Table[Map[Together,
    D[knownOffDiagonalBasisTransformationBlock, {rx, ry}[[mu]]] +
      re Sum[knownResidues[[a]] forms[[a, mu]], {a, Length[letters]}], {2}],
  {mu, 2}];
record = <|"Family" -> "REGULATOR_RECONSTRUCTION", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {rx, ry}, "Regulator" -> re,
  "OffDiagonalBlockEquation" -> {{{{0}}, {{0}}}, {{{0}}, {{0}}}, inhomogeneity}|>;
report["inhomogeneity", inhomogeneity];

(* the ansatz is PINNED: the same denominator and the support {1, x, y},
   so the exact coefficient vector is known *)
support = {{0, 0}, {1, 0}, {0, 1}};
prepared = prepare[record, frame, "OneForms" -> forms,
  "OffDiagonalBasisTransformationDenominator" -> denominator, "Support" -> support];
(* the engine owns the support ORDER (it canonicalizes it); the test
   asserts the support SET and reads the order back below *)
check["the ansatz is prepared as pinned",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticOffDiagonalBlockV1" &&
    Sort[prepared["OffDiagonalBasisTransformationNumeratorSupport"]] === Sort[support] &&
    TrueQ[Together[prepared["OffDiagonalBasisTransformationDenominator"] - denominator] === 0] &&
    prepared["ResidueUnknownCount"] === 4 &&
    prepared["UnknownCount"] === 7];
report["ansatz", KeyTake[prepared,
  {"UnknownCount", "OffDiagonalBasisTransformationUnknownCount", "ResidueUnknownCount",
   "OffDiagonalBasisTransformationNumeratorSupport", "OffDiagonalBasisTransformationDenominator"}]];

(* THE KNOWN EXACT VECTOR, read off in the module's OWN column order --
   the support order is the engine's, not the test's, and hard-coding it
   would test the test.  The gauge coefficients are the coefficients of
   the numerator G Q in the declared support monomials; the residues
   follow. *)
coefficientIn[expression_, monomial_] := Coefficient[
  Coefficient[Expand[Together[expression]], rx, monomial[[1]]], ry,
  monomial[[2]]];
knownNumerator = Together[knownOffDiagonalBasisTransformationBlock[[1, 1]] denominator];
knownVector = Join[
  coefficientIn[knownNumerator, #1] & /@ prepared["OffDiagonalBasisTransformationNumeratorSupport"],
  Flatten[knownResidues]];
report["known vector in the engine's column order", knownVector];
check["the known vector unpacks to the known gauge and residues",
  TrueQ[Together[unpack[prepared, knownVector]["OffDiagonalBasisTransformationBlock"][[1, 1]] -
      knownOffDiagonalBasisTransformationBlock[[1, 1]]] === 0] &&
    TrueQ[Together[Flatten[unpack[prepared, knownVector]["Residues"]] -
      Flatten[knownResidues]] === {0, 0, 0, 0}]];
check["and it satisfies the differential equation at generic eps",
  Lookup[residual[prepared, knownVector], "Status", None] ===
    "ExactChannelResidualZero"];

(* THE AFFINE FAMILY IS ONE-DIMENSIONAL HERE.  With E = C = 0 the
   homogeneous solution is the CONSTANT gauge: adding c to G adds c Q to
   the numerator, so the nullspace direction is the coefficient list of Q
   itself with zero residues.  The reconstruction does not return "the"
   solution -- there is no such thing -- it returns the representative of
   the affine family that lies on ONE canonical section, which is the
   whole point of the section.  The exact statement is therefore:
   the known solution, projected onto the SAME section, is the
   reconstructed vector coordinate by coordinate. *)
nullDirection = Join[
  coefficientIn[denominator, #1] & /@ prepared["OffDiagonalBasisTransformationNumeratorSupport"],
  {0, 0, 0, 0}];
check["the homogeneous direction is a genuine nullspace element",
  Lookup[residual[prepared, knownVector + 3 nullDirection], "Status",
    None] === "ExactChannelResidualZero"];
projectToSection[vector_, columns_] := Module[{scale},
  If[Length[columns] =!= 1, Return[$Failed]];
  scale = Together[vector[[First[columns]]]/
    nullDirection[[First[columns]]]];
  Together[vector - scale nullDirection]];

assembly = compile[prepared];
check["the ansatz compiles",
  Lookup[assembly, "Status", None] === "CompiledMultiquadraticOffDiagonalBlockV1"];

(* ------------------------------------------------------------------ *)
(* R1 - R6: the reconstruction                                          *)
(* ------------------------------------------------------------------ *)

{reconstructionSeconds, reconstruction} = AbsoluteTiming[
  reconstruct[prepared, assembly]];
report["R1 reconstruction", KeyTake[reconstruction,
  {"Status", "Method", "SamplePrimes", "UnseenPrime", "RegulatorValues",
   "NormalizationColumns", "DegreeHistogram", "MaximumRegulatorDegree",
   "ResiduesKinematicsFree", "ResiduesRegulatorFree"}]];
report["R1 seconds / phases", {Round[reconstructionSeconds, 0.01],
  Lookup[reconstruction, "PhaseSeconds", None]}];
check["R1 the reconstruction succeeds",
  Lookup[reconstruction, "Status", None] ===
    "ReconstructedRegulatorDependenceV1"];

sectionKnown = projectToSection[knownVector,
  Lookup[reconstruction, "NormalizationColumns", {}]];
report["R2 reconstructed gauge", Lookup[reconstruction, "OffDiagonalBasisTransformationBlock", None]];
report["R2 known solution projected onto the same section", sectionKnown];
check["R2 the affine family is one-dimensional and the section pins one \
coordinate",
  Lookup[reconstruction, "Nullity", None] === 1 &&
    Length[Lookup[reconstruction, "NormalizationColumns", {}]] === 1 &&
    ListQ[sectionKnown]];
check["R2 the reconstructed VECTOR is the known solution projected onto \
the same canonical section, coordinate by coordinate",
  ListQ[sectionKnown] &&
    TrueQ[Together[Lookup[reconstruction, "Vector", {}] - sectionKnown] ===
      ConstantArray[0, Length[sectionKnown]]]];
check["R2 and the reconstructed GAUGE therefore differs from the known \
one only by a homogeneous (kinematics-constant) direction",
  ListQ[Lookup[reconstruction, "OffDiagonalBasisTransformationBlock", None]] &&
    TrueQ[Together[D[reconstruction["OffDiagonalBasisTransformationBlock"][[1, 1]] - knownOffDiagonalBasisTransformationBlock[[1, 1]],
      rx]] === 0] &&
    TrueQ[Together[D[reconstruction["OffDiagonalBasisTransformationBlock"][[1, 1]] - knownOffDiagonalBasisTransformationBlock[[1, 1]],
      ry]] === 0] &&
    ! TrueQ[Together[reconstruction["OffDiagonalBasisTransformationBlock"][[1, 1]] -
      knownOffDiagonalBasisTransformationBlock[[1, 1]]] === 0]];

check["R3 the reconstructed residues equal the known K_a(eps) exactly",
  ListQ[Lookup[reconstruction, "Residues", None]] &&
    TrueQ[Together[Flatten[reconstruction["Residues"]] -
      Flatten[knownResidues]] === {0, 0, 0, 0}]];
check["R3 and they are free of the kinematic variables",
  TrueQ[reconstruction["ResiduesKinematicsFree"]] &&
    FreeQ[reconstruction["Residues"], rx | ry]];
report["R3 reconstructed residues", Flatten[
  Lookup[reconstruction, "Residues", {}]]];

check["R4 the residues genuinely DEPEND on the regulator",
  ! FreeQ[Lookup[reconstruction, "Residues", {}], re] &&
    Lookup[reconstruction, "ResiduesRegulatorFree", True] === False];

check["R5 the reconstructed GENERIC object satisfies the differential \
equation exactly",
  Lookup[Lookup[reconstruction, "ExactGenericResidual", <||>], "Status",
    None] === "ExactChannelResidualZero"];

check["R6 the record carries the section and both coefficient checks",
  VectorQ[Lookup[reconstruction, "NormalizationColumns", None], IntegerQ] &&
    TrueQ[reconstruction["CoefficientImageCheck"]] &&
    TrueQ[reconstruction["UnseenPrimeCoefficientCheck"]] &&
    AssociationQ[Lookup[reconstruction, "HeldOutValidation", None]] &&
    AllTrue[Values[reconstruction["HeldOutValidation"]],
      Lookup[#1, "CertificationMode", None] === "HeldOut" &]];
report["R6 held-out validation", Lookup[reconstruction,
  "HeldOutValidation", None]];

(* ------------------------------------------------------------------ *)
(* R7: the adversarial point -- one fiber is not the generic object     *)
(* ------------------------------------------------------------------ *)

(* the SECTION-NORMALIZED exact vector AT eps = 1, which is exactly what
   a fiberwise route lifts at one regulator value and publishes as "the"
   gauge and "the" residues *)
oneFiberVector = Together[sectionKnown /. re -> 1];
check["R7 one epsilon fiber's residues are NOT the generic residues",
  ! TrueQ[Together[Flatten[unpack[prepared, oneFiberVector]["Residues"]] -
    Flatten[knownResidues]] === {0, 0, 0, 0}]];
check["R7 and installing that fiber as the generic gauge FAILS the exact \
generic residual",
  Lookup[residual[prepared, oneFiberVector], "Status", None] ===
    "ExactChannelResidualNonzero"];
check["R7 while it is of course correct AT its own fiber",
  Lookup[residual[prepared, oneFiberVector, 1], "Status", None] ===
    "ExactChannelResidualZero"];
report["R7 one-fiber vector at eps = 1", oneFiberVector];

(* ------------------------------------------------------------------ *)
(* R8: the fit is not accidentally constant                             *)
(* ------------------------------------------------------------------ *)

check["R8 at least one coordinate has positive regulator degree",
  IntegerQ[Lookup[reconstruction, "MaximumRegulatorDegree", None]] &&
    reconstruction["MaximumRegulatorDegree"] >= 1];
report["R8 degree histogram", Lookup[reconstruction, "DegreeHistogram", None]];

Print["t_multiquadratic_regulator_reconstruction: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
