#!/usr/bin/env wolframscript
(* A package-minted dlog basis is reused by the rational finite-field engine,
   and its mathematical alphabet/denominator survive interpolation lifting. *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

prepare = FeynFacet`Private`finiteFieldStripPrepare;
definingInput = FeynFacet`Private`finiteFieldStripDefiningInput;

Clear[tx, ty, te];
strip = {
  {{{0}}, {{0}}},
  {{{0}}, {{0}}},
  {{{1}}, {{0}}}
};
record = <|"Strip" -> strip, "Variables" -> {tx, ty},
  "Regulator" -> te|>;
dlogRecords = {
  <|"Letter" -> tx, "OneForm" -> {1/tx, 0}|>,
  <|"Letter" -> ty, "OneForm" -> {0, 1/ty}|>
};

automatic = prepare[record];
precomputed = prepare[Join[record, <|"DLogRecords" -> dlogRecords|>]];

zeroCoordinate = <|"Numerator" -> {0}, "Denominator" -> {1},
  "Degrees" -> {-Infinity, 0}, "ConstructionNullity" -> 1,
  "ValidatedPointCount" -> 1, "UniquenessPointRequirement" -> 1|>;
storedAlphabet = {1 + tx};
storedDenominator = 1 + tx;
modular = <|
  "Prime" -> 1000003, "UnresolvedCoordinates" -> {},
  "GaugeUnknownCount" -> 1, "FreeResidueCount" -> 1,
  "GaugeNumeratorDegrees" -> {0, 0}, "NormalizationColumns" -> {},
  "GaugeSupport" -> {{0, 0}}, "SampleCount" -> 1,
  "CertificationMode" -> "HeldOut", "Alphabet" -> storedAlphabet,
  "GaugeDenominator" -> storedDenominator,
  "Interpolations" -> {zeroCoordinate, zeroCoordinate}|>;
lifted = FeynFacet`ReconstructEpsFormStrip[record, {modular},
  "KernelCount" -> 1, "ExactCheck" -> False];
legacyOptionRecord = Join[record, <|
  "ExtraLetters" -> {1 + tx}, "GaugeDenominatorFactor" -> 1 + tx|>];
legacyOptionModular = Join[KeyDrop[modular,
    {"Alphabet", "GaugeDenominator"}], <|
  "FreeResidueCount" -> 3,
  "Interpolations" -> ConstantArray[zeroCoordinate, 4]|>];
legacyOptionLifted = FeynFacet`ReconstructEpsFormStrip[
  legacyOptionRecord, {legacyOptionModular},
  "KernelCount" -> 1, "ExactCheck" -> False];
explicitOptionModular = Join[legacyOptionModular, <|
  "Prime" -> 1000033,
  "Alphabet" -> {tx, ty, 1 + tx},
  "GaugeDenominator" -> 1 + tx|>];
mixedSchemaLifted = FeynFacet`ReconstructEpsFormStrip[
  legacyOptionRecord, {legacyOptionModular, explicitOptionModular},
  "KernelCount" -> 1, "ExactCheck" -> False];
conflictingOptionModular = Join[explicitOptionModular, <|
  "Prime" -> 1000037, "Alphabet" -> {tx, ty}|>];
mixedSchemaConflict = Quiet[FeynFacet`ReconstructEpsFormStrip[
  legacyOptionRecord, {legacyOptionModular, conflictingOptionModular},
  "KernelCount" -> 1, "ExactCheck" -> False],
  FeynFacet`ReconstructEpsFormStrip::data];

checks = <|
  "AutomaticPreparation" -> AssociationQ[automatic],
  "PrecomputedPreparation" -> AssociationQ[precomputed],
  "MathematicalBasisAgreement" -> AssociationQ[automatic] &&
    AssociationQ[precomputed] &&
    precomputed["Alphabet"] === automatic["Alphabet"] &&
    precomputed["DLog"] === automatic["DLog"],
  "PrecomputedRouteSkipsDerivation" -> AssociationQ[precomputed] &&
    precomputed["DLogBasisRoute"] === "Precomputed" &&
    precomputed["PrecomputedDLogCount"] === 2 &&
    precomputed["DerivedDLogCount"] === 0,
  "PreparationStoresDefiningInput" ->
    automatic["DefiningInput"] === definingInput[record] &&
    precomputed["DefiningInput"]["DLogOneForms"] === dlogRecords,
  "LiftUsesStoredAlphabet" -> AssociationQ[lifted] &&
    lifted["Alphabet"] === storedAlphabet,
  "LiftUsesStoredGaugeDenominator" -> AssociationQ[lifted] &&
    lifted["GaugeDenominator"] === storedDenominator &&
    lifted["GaugeDenominatorDegrees"] === {1, 0},
  "LegacyLiftReplaysRecordAnsatz" -> AssociationQ[legacyOptionLifted] &&
    legacyOptionLifted["Alphabet"] === {tx, ty, 1 + tx} &&
    legacyOptionLifted["GaugeDenominator"] === 1 + tx,
  "CompatibleMixedSchemaLift" -> AssociationQ[mixedSchemaLifted] &&
    mixedSchemaLifted["Alphabet"] === {tx, ty, 1 + tx} &&
    mixedSchemaLifted["GaugeDenominator"] === 1 + tx,
  "ConflictingMixedSchemaRejected" -> mixedSchemaConflict === $Failed
|>; 

Print[InputForm[checks]];
Print["failed: ", Keys[Select[checks, ! TrueQ[#1] &]]];
Exit[If[AllTrue[Values[checks], TrueQ], 0, 1]];
