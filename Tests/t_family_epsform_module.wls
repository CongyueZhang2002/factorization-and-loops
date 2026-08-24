(* FamilyEpsForm.wl module tests: context-guarded artifact reads keep
   certification exact after CANONICA has loaded (the measured
   2026-08-20 defect: in one kernel only the first certified family
   passed, every later naive read was poisoned), the diagonal-block
   normalizer accepts both shipped "Blocks" layouts, and the schema
   normalizer reports typed failures. Uses the two smallest production
   records, CF2 and CF3. *)

root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical"}];
recordFile[f_] := FileNameJoin[{base, "FamilyEpsForms",
  "family_epsform_" <> f <> ".wl"}];
systemFile[f_] := FileNameJoin[{base, "DifferentialEquations",
  "nnlo_de_" <> f <> ".wl"}];

(* round-trip through the atomic writer and guarded reader *)
scratch = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "t_family_epsform_" <> ToString[$ProcessID]}]];
sample = <|"A" -> {1/2, Symbol["Global`eps"]}, "B" -> "text"|>;
written = FeynFacet`FamilyArtifactWrite[sample,
  FileNameJoin[{scratch, "sample.wl"}]];
roundTrip = FeynFacet`FamilyArtifactRead[written] === sample;
missingRead = FeynFacet`FamilyArtifactRead[
  FileNameJoin[{scratch, "absent.wl"}]] === $Failed;

(* first certification loads CANONICA through the dlog check *)
rec2 = FeynFacet`FamilyArtifactRead[recordFile["CF2"]];
sys2 = FeynFacet`FamilyArtifactRead[systemFile["CF2"]];
first = FeynFacet`CertifyFamilyEpsilonForm[rec2, sys2];

(* the regression: a guarded read AFTER CANONICA is on the path must
   still certify -- a naive Get here failed its gauge identity *)
rec3 = FeynFacet`FamilyArtifactRead[recordFile["CF3"]];
sys3 = FeynFacet`FamilyArtifactRead[systemFile["CF3"]];
second = FeynFacet`CertifyFamilyEpsilonForm[rec3, sys3];

(* annotated diagonal-block layout {{indices, classId}..} *)
annotated = Join[rec3, <|"Blocks" ->
  MapIndexed[{#1, 90 + First[#2]} &, rec3["Blocks"]]|>];
adapted = FeynFacet`CertifyFamilyEpsilonForm[annotated, sys3];
normalized = FeynFacet`FamilyEpsilonFormRecord[annotated];

typedFailure = FeynFacet`FamilyEpsilonFormRecord[
  <|"TTotal" -> {{1}}|>]["Status"] === "RecordKeysMissing";
(* legacy chart aliases live in the PROJECT chart table since the
   generality pass (2026-08-23): unregistered, the alias must not
   silently resolve; after TransportFamilyChartLoad it resolves as
   before *)
legacyChartAliasUnregistered = FeynFacet`FamilyEpsilonFormRecord[
  Join[rec3, <|"Chart" -> "v = x y, w = (1-x)(1-y)"|>]]["Chart"] =!=
  "Kallen1";
FeynFacet`TransportFamilyChartLoad[
  FileNameJoin[{base, "TransportFamilyCharts.wl"}]];
legacyChartAlias = legacyChartAliasUnregistered &&
  FeynFacet`FamilyEpsilonFormRecord[
    Join[rec3, <|"Chart" -> "v = x y, w = (1-x)(1-y)"|>]]["Chart"] ===
  "Kallen1";
badPermutation = FeynFacet`FamilyEpsilonFormRecord[
  Join[rec3, <|"Blocks" -> {{1}, {1}, {2}}|>]]["Status"] ===
  "BlockBasisPermutationInvalid";

tests = <|
  "ArtifactRoundTrip" -> roundTrip,
  "MissingFileFails" -> missingRead,
  "FirstFamilyCertified" -> first["Status"] === "ExactEpsilonForm",
  "GuardedReadAfterCanonicaCertified" ->
    second["Status"] === "ExactEpsilonForm" &&
      TrueQ[second["Checks"]["GaugeIdentity"]],
  "AnnotatedBlocksCertified" ->
    adapted["Status"] === "ExactEpsilonForm",
  "NormalizerPlainBlocks" ->
    AssociationQ[normalized] && normalized["Blocks"] === rec3["Blocks"],
  "TypedMissingKeys" -> typedFailure,
  "TypedBadPermutation" -> badPermutation,
  "LegacyChartAlias" -> legacyChartAlias
|>;

DeleteDirectory[scratch, DeleteContents -> True];
Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
