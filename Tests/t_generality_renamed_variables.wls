#!/usr/bin/env wolframscript
(* Generality of the package under RENAMED symbols and MOVED trees
   (agent II's half of Design/GeneralityFixes.md, 2026-08-23).

   Every check below is written in variables {a, b} with regulator ep,
   i.e. in symbols this project never uses, or against an installation
   root that is not the repository.  The acceptance criterion of each
   check is stated in its label; a check that asserts an UNCHANGED value
   ("today's value") is a regression guard for the backward-compatibility
   rule of the fix plan, not a new capability.

   Covered: C1 (DiagonalBlockClassCampaign "Variables"/"Regulator"),
   C2 (chart-parameter collision), C3 (catalog match under renamed
   variables), C5 (Maple unknown names), C6 (two-variable certificate
   signature), D1 ("DistributionHeads"), D2 (dimension rule by shape),
   D4 (machine-derived kernel/CPU caps, scratch output directory),
   B4 (workspace root, path-free reduction fingerprint, fingerprint
   identity instead of path identity). *)

root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];

scratch = FileNameJoin[{$TemporaryDirectory, "FeynFacetGenerality",
  StringTake[CreateUUID[], 8]}];
Quiet[CreateDirectory[scratch, CreateIntermediateDirectories -> True]];

(* the renamed alphabet: nothing here is named v, w, x, y, t, eps *)
Clear[a, b, ep];

(* ---------------------------------------------------------------- *)
Print["--- C1  class campaign in {a, b} with regulator ep"];
(* ---------------------------------------------------------------- *)

(* a scalar block with a dlog form in the renamed symbols: the coefficients
   are 0 + ep r, so the transformation is 1 and the letters are a, a - 1, b *)
scalarClass = <|"ClassID" -> "SYN1", "Dim" -> 1, "RepFamily" -> "ZZ7",
  "RepRows" -> {1},
  "Variables" -> {a, b}, "Regulator" -> ep,
  "RepAv" -> {{ep/a - 2 ep/(a - 1)}}, "RepAw" -> {{3 ep/b}}|>;
(* the same block with NO declared regulator: it must be detected from the
   representative matrices by name *)
scalarNoDeclaration = KeyDrop[scalarClass, {"Regulator"}];
scalarNoDeclaration["ClassID"] = "SYN2";
(* a regulator-free representative (7 of this project's 173 classes are):
   detection fails and the declared default must carry it *)
zeroClass = <|"ClassID" -> "SYN3", "Dim" -> 1, "RepFamily" -> "ZZ7",
  "RepRows" -> {2}, "RepAv" -> {{0}}, "RepAw" -> {{0}}|>;

campaignDirectory = FileNameJoin[{scratch, "classes"}];
campaign = FeynFacet`DiagonalBlockClassCampaign[
  {scalarClass, scalarNoDeclaration, zeroClass}, campaignDirectory,
  "Variables" -> Automatic, "Regulator" -> Automatic,
  "CanonicaValidation" -> False, "Verbose" -> False];
record1 = FeynFacet`FamilyArtifactRead[
  FileNameJoin[{campaignDirectory, "classSYN1.wl"}]];
record3 = FeynFacet`FamilyArtifactRead[
  FileNameJoin[{campaignDirectory, "classSYN3.wl"}]];

check["(C1) all three synthetic classes canonicalized",
  AssociationQ[campaign] && campaign["Canonicalized"] === 3];
check["(C1) the class record's own {a, b} and ep reach the stored record",
  record1["Variables"] === {a, b} && record1["Regulator"] === ep &&
    record1["Status"] === "CANONICALIZED"];
check["(C1) the letters are the renamed ones (a, a - 1, b)",
  Module[{letters = Lookup[record1, "Letters", {}]},
    Length[letters] === 3 && FreeQ[letters, Symbol["Global`v"]] &&
      AllTrue[{a, a - 1, b}, Function[q,
        AnyTrue[letters, TrueQ[Together[# - q] === 0] &]]]]];
check["(C1) the stored eps-form is written in ep and in {a, b}",
  FreeQ[record1["EpsForm"], Symbol["Global`v"] | Symbol["Global`eps"]] &&
    ! FreeQ[record1["EpsForm"], ep]];
check["(C1) an undeclared regulator is detected from the matrices (ep)",
  Module[{r = FeynFacet`FamilyArtifactRead[
      FileNameJoin[{campaignDirectory, "classSYN2.wl"}]]},
    r["Status"] === "CANONICALIZED" && r["Regulator"] === ep &&
      r["Variables"] === {a, b}]];
check["(C1) a regulator-free representative falls back to the default eps \
(today's behaviour for the 7 such classes)",
  record3["Status"] === "CANONICALIZED" &&
    record3["Regulator"] === Symbol["Global`eps"] &&
    record3["Variables"] === {Symbol["Global`v"], Symbol["Global`w"]}];
check["(C1) explicit options override the record",
  Module[{r = FeynFacet`Private`diagonalBlockClassRecord[scalarClass, ep, 60, None, False,
      {a, b}]},
    r["Status"] === "CANONICALIZED" && r["Regulator"] === ep]];
check["(C1) a class that declares three variables is refused, not sampled \
as a pair",
  FeynFacet`Private`diagonalBlockClassRecord[
      Append[scalarClass, "Variables" -> {a, b, Symbol["Global`u"]}],
      Automatic, 60, None, False,
      Automatic]["Status"] === "ClassVariablesNotTwoSymbols"];

(* ---------------------------------------------------------------- *)
Print["--- C2  chart parameter"];
(* ---------------------------------------------------------------- *)

quadratic = (1 - a - b)^2 - 4 a b;   (* lambda1 in the renamed variables *)
collide = FeynFacet`Private`canonicalBlocksBuildChart[quadratic, {a, b}, a];
check["(C2) a chart parameter equal to a source variable is refused by type",
  AssociationQ[collide] && collide["Status"] === "ChartParameterCollides"];
check["(C2) a genuine parameter still builds the conic chart",
  Module[{c = FeynFacet`Private`canonicalBlocksBuildChart[quadratic, {a, b},
      Symbol["Global`t"]]},
    AssociationQ[c] && ! KeyExistsQ[c, "Status"] &&
      MatchQ[Lookup[c, "Subst", None], _Rule]]];
check["(C2) Automatic keeps Global`t for a (v, w) block (today's value: \
the 24 stored conic records name t)",
  FeynFacet`Private`diagonalBlockChartParameter[Automatic,
      {{{1/(1 - Symbol["Global`v"])}}, {{0}}},
      {Symbol["Global`v"], Symbol["Global`w"]}, Symbol["Global`eps"]] ===
    Symbol["Global`t"] &&
  FeynFacet`Private`canonicalBlocksChartParameter[Automatic, {{{0}}, {{0}}},
      {Symbol["Global`v"], Symbol["Global`w"]}, Symbol["Global`eps"]] ===
    Symbol["Global`t"]];
check["(C2) Automatic yields a fresh symbol when t is one of the block's \
own variables",
  Module[{p = FeynFacet`Private`diagonalBlockChartParameter[Automatic, {{{0}}, {{0}}},
      {Symbol["Global`t"], Symbol["Global`u"]}, ep]},
    MatchQ[p, _Symbol] && p =!= Symbol["Global`t"] &&
      ! MemberQ[{Symbol["Global`t"], Symbol["Global`u"], ep}, p]]];
check["(C2) Automatic yields a fresh symbol when t occurs in the matrices",
  Module[{p = FeynFacet`Private`canonicalBlocksChartParameter[Automatic,
      {{{ep/(1 - Symbol["Global`t"])}}, {{0}}}, {a, b}, ep]},
    MatchQ[p, _Symbol] && p =!= Symbol["Global`t"]]];
(* the refusal reaches the diagonal retry: a colliding parameter stops it
   before any solving *)
conicAv = {{ep/quadratic, 0}, {0, ep/a}};
conicAw = {{ep/quadratic, 0}, {0, ep/b}};
check["(C2) the diagonal chart retry propagates the typed refusal",
  FeynFacet`Private`diagonalBlockChartRetry[{conicAv, conicAw}, {a, b}, ep,
    {"ChartParameter" -> b}]["Status"] === "ChartParameterCollides"];

(* ---------------------------------------------------------------- *)
Print["--- C3  catalog charts under renamed variables"];
(* ---------------------------------------------------------------- *)

catalogCandidate = FeynFacet`Private`diagonalBlockCatalogCandidate[
  {conicAv, conicAw}, {a, b}, ep, quadratic];
check["(C3) the Kallen catalog chart is found for lambda1(a, b) \
(the old gate required the variables to be named v and w)",
  AssociationQ[catalogCandidate] &&
    StringMatchQ[catalogCandidate["Chart"]["Name"], "Kallen1" ~~ ___]];
check["(C3) the chart is rekeyed to the block's own variables",
  Sort[First /@ catalogCandidate["Chart"]["Subst"]] === Sort[{a, b}]];
check["(C3) the pulled-back root square is the block's quadratic",
  TrueQ[Together[catalogCandidate["Chart"]["RootSquare"] - quadratic] === 0]];
check["(C3) the chart identity root^2 = RootSquare o Subst holds exactly in the renamed variables",
  TrueQ[Together[
      catalogCandidate["Chart"]["Root"]^2 -
        (quadratic /. catalogCandidate["Chart"]["Subst"])] === 0]];
check["(C3) the pulled-back system is rational and in the chart variables",
  MatrixQ[catalogCandidate["System"][[1]]] &&
    FreeQ[catalogCandidate["System"], a | b]];
check["(C3) chart variables never collide with the block's variables",
  Module[{c = FeynFacet`Private`diagonalBlockCatalogCandidate[
      {conicAv, conicAw} /. {a -> Symbol["Global`x"], b -> Symbol["Global`y"]},
      {Symbol["Global`x"], Symbol["Global`y"]}, ep,
      quadratic /. {a -> Symbol["Global`x"], b -> Symbol["Global`y"]}]},
    AssociationQ[c] &&
      Intersection[c["Variables"],
        {Symbol["Global`x"], Symbol["Global`y"]}] === {}]];
check["(C3) a quadratic with no catalog chart yields no candidate",
  FeynFacet`Private`diagonalBlockCatalogCandidate[{conicAv, conicAw}, {a, b}, ep,
    4 a + b^2 + 7] === None];

(* ---------------------------------------------------------------- *)
Print["--- C5  Maple unknown names"];
(* ---------------------------------------------------------------- *)

Clear[c, cc1];
check["(C5) the generated unknown head is no longer Global`c",
  Module[{head = Unique["mapleUnknownC"]},
    SymbolName[head] =!= "c" &&
      StringMatchQ[SymbolName[head], LetterCharacter ~~ ___] &&
      StringFreeQ[SymbolName[head], "$"]]];
check["(C5) a caller's c and cc<n> do not collide with the generated names",
  FeynFacet`Private`epsFormStripUnknownNameCollisions[{c, cc1, ep},
    SymbolName[Unique["mapleUnknownC"]],
    SymbolName[Unique["mapleFreeC"]] <> "x"] === {}];
check["(C5) a collision with a variable or the regulator is detected",
  FeynFacet`Private`epsFormStripUnknownNameCollisions[{c, cc1, ep}, "c", "cc"] === {c, cc1}];
check["(C5) the regulator alone is detected too",
  FeynFacet`Private`epsFormStripUnknownNameCollisions[{a, b, ep}, "ep", "zzz"] === {ep}];

(* ---------------------------------------------------------------- *)
Print["--- C6  the certificate is a two-variable statement"];
(* ---------------------------------------------------------------- *)

check["(C6) a three-variable list does not evaluate the modular certificate",
  Head[FeynFacet`Private`familyCertificateModular[{{{ep/a}}, {{ep/b}}}, {{1}}, {{1}},
    {a, b, Symbol["Global`u"]}, ep, {{{ep/a}}, {{ep/b}}}, {a, b},
    None]] === FeynFacet`Private`familyCertificateModular];
check["(C6) the two-variable call still evaluates to a record",
  Module[{r = FeynFacet`Private`familyCertificateModular[
      {{{ep/a}}, {{ep/b}}}, {{1}}, {{1}},
      {a, b}, ep, {{{ep/a}}, {{ep/b}}}, {a, b}, None]},
    AssociationQ[r]]];

(* ---------------------------------------------------------------- *)
Print["--- D1  distribution heads come from the context"];
(* ---------------------------------------------------------------- *)

Clear[myPDF];
check["(D1) the declared twist-2 heads remain the default",
  FeynFacet`Private`coefficientDistributionObjectQ[FeynFacet`f1[a]] &&
    ! FeynFacet`Private`coefficientDistributionObjectQ[myPDF[a]] &&
    FeynFacet`Private`coefficientContextDistributionHeads[<||>] ===
      FeynFacet`Private`$twist2DistributionHeads];
check["(D1) a card's own heads are recognised",
  FeynFacet`Private`coefficientDistributionObjectQ[myPDF[a], {myPDF}] &&
    FeynFacet`Private`coefficientContextDistributionHeads[
      <|"DistributionHeads" -> {myPDF}|>] === {myPDF}];
check["(D1) an invalid declaration falls back to the default",
  FeynFacet`Private`coefficientContextDistributionHeads[
    <|"DistributionHeads" -> "f1"|>] === FeynFacet`Private`$twist2DistributionHeads];

(* ---------------------------------------------------------------- *)
Print["--- D2  the dimension rule is validated by shape"];
(* ---------------------------------------------------------------- *)

baseContext = <|
  "Gamma5Scheme" -> "BMHV", "GlobalBasis" -> {}, "GlobalBasisGram" -> {},
  "SetEvanescentZero" -> {}, "SetMassZero" -> {}, "SetDistributionZero" -> {},
  "CollinearRelations" -> {}, "Assumptions" -> True,
  "CoefficientKinematics" -> <||>, "KinematicMassDimensions" -> <||>,
  "LoopDimension" -> System`D, "CutConvention" -> "OrientedPositiveEnergyDelta",
  "DistributionConvention" -> "FeynFacet/Distributions.wl",
  "FeynFacetSourceHash" -> "0"|>;
seal[assoc_] := Append[assoc,
  "Fingerprint" -> FeynFacet`Private`reductionFingerprint[assoc]];
check["(D2) the front end's own rule D -> 4 - 2 Epsilon still validates",
  TrueQ[FeynFacet`Private`analyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 4 - 2 Symbol["Global`Epsilon"])]]]]];
check["(D2) D -> 6 - 2 ep with the regulator carried in the context validates",
  TrueQ[FeynFacet`Private`analyticContextQ[seal[Join[baseContext,
    <|"DimensionRule" -> (System`D -> 6 - 2 ep), "Regulator" -> ep|>]]]]];
check["(D2) D -> 4 - 3 Epsilon is refused (the -2 is the contract)",
  ! TrueQ[FeynFacet`Private`analyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 4 - 3 Symbol["Global`Epsilon"])]]]]];
check["(D2) a rule that is not linear in the regulator is refused",
  ! TrueQ[FeynFacet`Private`analyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 4 - 2 Symbol["Global`Epsilon"] +
      Symbol["Global`Epsilon"]^2)]]]]];
check["(D2) a non-integer dimension is refused",
  ! TrueQ[FeynFacet`Private`analyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 9/2 - 2 Symbol["Global`Epsilon"])]]]]];
check["(D2) an undeclared foreign regulator is refused",
  ! TrueQ[FeynFacet`Private`analyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 4 - 2 ep)]]]]];
check["(D2) Gamma5Scheme is still required to be BMHV",
  ! TrueQ[FeynFacet`Private`analyticContextQ[seal[Join[baseContext,
    <|"Gamma5Scheme" -> "NDR",
      "DimensionRule" -> (System`D -> 4 - 2 Symbol["Global`Epsilon"])|>]]]]];
check["(D2) the store's copy of the check agrees",
  TrueQ[FeynFacet`Private`coefficientAnalyticContextQ[seal[Join[baseContext,
    <|"DimensionRule" -> (System`D -> 6 - 2 ep), "Regulator" -> ep|>]]]] &&
  ! TrueQ[FeynFacet`Private`coefficientAnalyticContextQ[seal[Append[baseContext,
    "DimensionRule" -> (System`D -> 4 - 3 ep)]]]]];

(* ---------------------------------------------------------------- *)
Print["--- D4  machine size and scratch defaults"];
(* ---------------------------------------------------------------- *)

Print["    $ProcessorCount ", $ProcessorCount, ", operating-system cpus ",
  FeynFacet`Private`facetProcessorCount[], ", FACET_CPU_LIST ",
  ToString[Environment["FACET_CPU_LIST"]]];
check["(D4) the operating-system cpu count is read (20 on this machine)",
  IntegerQ[FeynFacet`Private`facetProcessorCount[]] && FeynFacet`Private`facetProcessorCount[] >= 20];
Module[{envCount = Environment["FACET_KERNEL_COUNT"], expected},
  (* FACET_KERNEL_COUNT (set by the pool driver for missions) caps the
     count below the machine ceiling; the assertion must hold in both
     environments (in-pool failure 2026-08-23) *)
  expected = If[StringQ[envCount] && envCount =!= "", Min[8, ToExpression[envCount]], 8];
  check["(D4) the kernel ceiling on this machine is unchanged (8, or the FACET_KERNEL_COUNT cap)",
    FeynFacet`Private`facetKernelCount[] === expected &&
      FeynFacet`Private`facetKernelCount[3] === Min[3, expected] &&
      FeynFacet`Private`facetKernelCount[99] === expected]];
If[StringQ[Environment["FACET_CPU_LIST"]],
  Print["    FACET_CPU_LIST is set in this session; the fallback check is \
reported, not asserted"];
  Print["    facetCPUList[] = ", FeynFacet`Private`facetCPUList[]],
  check["(D4) the CPU-list fallback on this machine is unchanged (0..15)",
    FeynFacet`Private`facetCPUList[] === StringRiffle[ToString /@ Range[0, 15], ","]]];
check["(D4) CanonicalizeClasses no longer writes into Directory[]",
  Module[{source = Import[FileNameJoin[{root, "FeynFacet", "Private",
      "CanonicalBlocks.wl"}], "Text"]},
    StringFreeQ[source, "Directory[], \"CanonicalClassForms\""] &&
      StringContainsQ[source, "$TemporaryDirectory"]]];
check["(D4) MasterTransport refuses a base point on a letter zero",
  Module[{source = Import[FileNameJoin[{root, "FeynFacet", "Private",
      "MasterTransport.wl"}], "Text"]},
    StringContainsQ[source, "\"BasePointOnLetterZero\""] &&
      StringContainsQ[source, "Lookup[monic, \"Denominators\", {}]"]]];

(* ---------------------------------------------------------------- *)
Print["--- B4  workspace root, fingerprints, paths"];
(* ---------------------------------------------------------------- *)

check["(B4) the workspace root defaults to the package root",
  FeynFacet`Private`$feynFacetWorkspaceRoot === FeynFacet`Private`$feynFacetRoot];
repositoryResults = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical"}];
location = FeynFacet`Private`ibpProjectLocation[repositoryResults];
check["(B4) this repository's Kira workspace path is unchanged",
  location["Root"] === FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
      "Kira"}] &&
    location["Directory"] === FileNameJoin[{location["Root"],
      "UU_08_10_canonical"}]];
outside = FileNameJoin[{scratch, "elsewhere", "ZZ7", "Results", "run1"}];
Quiet[CreateDirectory[outside, CreateIntermediateDirectories -> True]];
workspace = FileNameJoin[{scratch, "workspace"}];
outsideLocation = FeynFacet`Private`ibpProjectLocation[outside, workspace];
check["(B4) a result tree outside the workspace root is no longer refused",
  outsideLocation["Root"] ===
      FileNameJoin[{workspace, "Codex", "ZZ7", "Kira"}] &&
    outsideLocation["Directory"] ===
      FileNameJoin[{outsideLocation["Root"], "run1"}] &&
    outsideLocation["WorkspaceRoot"] === ExpandFileName[workspace]];
check["(B4) the delete guard is the workspace root it was given",
  FeynFacet`Private`coefficientSafeWorkPathQ[FileNameJoin[{workspace, "x"}], workspace] &&
    ! FeynFacet`Private`coefficientSafeWorkPathQ[workspace, workspace] &&
    ! FeynFacet`Private`coefficientSafeWorkPathQ[FileNameJoin[{scratch, "other"}],
      workspace]];
runtimeA = <|"KiraExecutable" -> "/opt/kira/bin/kira",
  "KiraExecutableHash" -> "h1", "FermatExecutable" -> "/opt/kira/bin/fer64",
  "FermatExecutableHash" -> "h2", "SupportFile" -> "/opt/kira/BACKWARD/chdat",
  "SupportFileHash" -> "h3"|>;
runtimeB = Join[runtimeA, <|"KiraExecutable" -> "/usr/local/kira/bin/kira",
  "FermatExecutable" -> "/usr/local/kira/bin/fer64",
  "SupportFile" -> "/usr/local/kira/BACKWARD/chdat"|>];
payloadA = FeynFacet`Private`reductionInputPayload[{}, {}, {}, runtimeA];
payloadB = FeynFacet`Private`reductionInputPayload[{}, {}, {}, runtimeB];
check["(B4) the reduction payload still records the executable paths",
  payloadA["Runtime"]["KiraExecutable"] === "/opt/kira/bin/kira"];
check["(B4) the fingerprint does not depend on where the executables live",
  FeynFacet`Private`ibpPayloadFingerprint[payloadA] === FeynFacet`Private`ibpPayloadFingerprint[payloadB] &&
    FeynFacet`Private`reductionFingerprint[payloadA] =!= FeynFacet`Private`reductionFingerprint[payloadB]];
check["(B4) the fingerprint still depends on the executable hashes",
  FeynFacet`Private`ibpPayloadFingerprint[payloadA] =!=
    FeynFacet`Private`ibpPayloadFingerprint[FeynFacet`Private`reductionInputPayload[{}, {}, {},
      Append[runtimeA, "KiraExecutableHash" -> "other"]]]];
storedContext = seal[Append[baseContext,
  "DimensionRule" -> (System`D -> 4 - 2 Symbol["Global`Epsilon"])]];
check["(B4) artifact identity is the analytic context, not the directory",
  FeynFacet`Private`coefficientSameInputsQ[
      <|"ResultDirectory" -> "/one", "AnalyticContext" -> storedContext|>,
      <|"ResultDirectory" -> "/two", "AnalyticContext" -> storedContext|>] &&
    ! FeynFacet`Private`coefficientSameInputsQ[
      <|"ResultDirectory" -> "/one", "AnalyticContext" -> storedContext|>,
      <|"ResultDirectory" -> "/one",
        "AnalyticContext" -> Append[storedContext, "Fingerprint" -> "x"]|>]];
(* the solved Kira workspaces this repository already carries were
   fingerprinted WITH the executable paths; the import path accepts that
   hash as well, and that is what keeps them readable *)
legacyPayloadFile = FileNameJoin[{root, "Codex", "ppHX_NLO", "Kira",
  "UU_08_10_canonical_stream", "reduction_input.wxf"}];
legacyHashFile = FileNameJoin[{root, "Codex", "ppHX_NLO", "Kira",
  "UU_08_10_canonical_stream", "reduction_input.sha256"}];
If[FileExistsQ[legacyPayloadFile] && FileExistsQ[legacyHashFile],
  Module[{stored = StringTrim[Import[legacyHashFile, "Text"]],
      payload = Import[legacyPayloadFile, "WXF"]},
    check["(B4) a solved workspace written before this change still \
validates by its stored hash",
      AssociationQ[payload] &&
        FeynFacet`Private`reductionFingerprint[payload] === stored];
    Print["    legacy payload runtime keys: ",
      Keys[Lookup[payload, "Runtime", <||>]]]],
  Print["    no stored Kira workspace in this tree; \
the legacy-hash check is reported as not run"]];
check["(B4) without a fingerprint the stored path is still compared",
  FeynFacet`Private`coefficientSameInputsQ[<|"ResultDirectory" -> scratch|>,
      <|"ResultDirectory" -> scratch|>] &&
    ! FeynFacet`Private`coefficientSameInputsQ[<|"ResultDirectory" -> scratch|>,
      <|"ResultDirectory" -> root|>]];

Quiet[DeleteDirectory[scratch, DeleteContents -> True]];
Print["t_generality_renamed_variables: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
