#!/usr/bin/env wolframscript
(* Adversarial generality test T1 (Design/GeneralityFixes.md).

   Acceptance criteria, stated before the run:
     STATIC   -- with every Wolfram comment removed (nested comments and
                 string literals handled), no source file under FeynFacet/
                 contains a canonical-family literal ("CF" followed by a
                 digit), an absolute /home/ path, or a project-tree name.
                 Comments may cite families and measurements: that is
                 provenance, and the plan keeps it.
     RUNTIME  -- the per-family chart registry ships EMPTY; an unregistered
                 family is Missing["FamilyChartNotRegistered", family] and
                 never None; a synthetic family registers and resolves in
                 both entry forms (catalog chart name, root-square list) and
                 as a legacy chart alias; every invalid registration is
                 refused typed and registers nothing.
     PATHS    -- no installation path is a built-in literal: the transport
                 backends' root resolves from the package, and the strip
                 solver's implementation provenance hashes only package
                 sources unless a driver declares itself. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* ------------------------------------------------------------------ *)
(*  STATIC: the package sources with every comment removed              *)
(* ------------------------------------------------------------------ *)
(* Wolfram comments nest, and a comment opener inside a string literal
   opens nothing, so the stripper is a scanner over three states rather
   than a pattern replacement.  String literals are KEPT: a project datum
   hidden in a string is exactly what this test looks for.  This comment
   deliberately spells no opener of its own -- inside a comment the kernel
   counts openers even in quotes, and one written here would swallow the
   rest of the file. *)
generalityStripComments[text_String] := Module[
  {chars, n, i, depth, inString, keep},
  chars = Characters[text];
  n = Length[chars];
  keep = ConstantArray[True, n];
  i = 1; depth = 0; inString = False;
  While[i <= n,
    Which[
      depth > 0,
        keep[[i]] = False;
        Which[
          i < n && chars[[i]] === "(" && chars[[i + 1]] === "*",
            keep[[i + 1]] = False; depth++; i += 2,
          i < n && chars[[i]] === "*" && chars[[i + 1]] === ")",
            keep[[i + 1]] = False; depth--; i += 2,
          True, i++],
      inString,
        If[chars[[i]] === "\\", i += 2,
          If[chars[[i]] === "\"", inString = False]; i++],
      i < n && chars[[i]] === "(" && chars[[i + 1]] === "*",
        keep[[i]] = False; keep[[i + 1]] = False; depth = 1; i += 2,
      chars[[i]] === "\"", inString = True; i++,
      True, i++]];
  StringJoin[MapThread[If[#2, #1, " "] &, {chars, keep}]]
];

packageDirectory = FileNameJoin[{root, "FeynFacet"}];
sourceFiles = Sort[DeleteDuplicates[Join[
  FileNames["*.m", packageDirectory, Infinity],
  FileNames["*.wl", packageDirectory, Infinity]]]];

forbidden = <|
  "CanonicalFamilyLiteral" -> "CF" ~~ DigitCharacter,
  "AbsoluteHomePath" -> "/home/",
  "ProjectTreeName" -> ("ppHX" | "UU_08_10" | "factorization-and-loops" |
    "nnlo_de" | "family_epsform" | "TransportProductionPlan")
|>;

scanFile[file_String] := Module[{stripped, lines},
  stripped = generalityStripComments[Import[file, "Text"]];
  lines = StringSplit[stripped, "\n", All];
  Flatten[Table[
    Table[
      If[StringContainsQ[lines[[line]], forbidden[key]],
        <|"File" -> FileNameTake[file], "Line" -> line, "Kind" -> key,
          "Text" -> StringTrim[lines[[line]]]|>,
        Nothing],
      {line, Length[lines]}],
    {key, Keys[forbidden]}], 1]
];

violations = Flatten[scanFile /@ sourceFiles, 1];
Print["scanned ", Length[sourceFiles], " package source files"];
If[violations =!= {},
  Print["violations:"];
  Scan[Print["  ", #["File"], ":", #["Line"], " [", #["Kind"], "] ",
    StringTake[#["Text"], UpTo[100]]] &, violations]];

stripperProbe = generalityStripComments[
  "a (* one (* two *) three *) b \"(* not a comment *)\""];
FTAssert["the comment stripper removes nested comments and keeps strings",
  StringLength[stripperProbe] === StringLength[
      "a (* one (* two *) three *) b \"(* not a comment *)\""] &&
    StringContainsQ[stripperProbe, "\"(* not a comment *)\""] &&
    ! StringContainsQ[stripperProbe, "one"] &&
    ! StringContainsQ[stripperProbe, "two"] &&
    ! StringContainsQ[stripperProbe, "three"] &&
    StringTake[stripperProbe, 1] === "a"];
FTAssert["every package source file is scanned",
  Length[sourceFiles] >= 30];
FTAssert["no canonical-family literal outside comments",
  ! MemberQ[violations, r_ /; r["Kind"] === "CanonicalFamilyLiteral"]];
FTAssert["no absolute /home/ path outside comments",
  ! MemberQ[violations, r_ /; r["Kind"] === "AbsoluteHomePath"]];
FTAssert["no project-tree name outside comments",
  ! MemberQ[violations, r_ /; r["Kind"] === "ProjectTreeName"]];

(* ------------------------------------------------------------------ *)
(*  RUNTIME: the per-family chart registry                              *)
(* ------------------------------------------------------------------ *)
registry := FeynFacet`Private`$transportFamilyChartRegistry;

FTAssert["the package ships an empty family-chart registry",
  registry === <||>];

emptyLookup = FeynFacet`TransportFamilyChart["ZZ7"];
FTAssert["an unregistered family is Missing, never None",
  emptyLookup === Missing["FamilyChartNotRegistered", "ZZ7"] &&
    emptyLookup =!= None && MissingQ[emptyLookup]];

(* the package's own source/chart symbols, never assigned to themselves
   (self-assignment v = Global`v is one of this repository's paid-for
   Wolfram traps) *)
gv = Symbol["Global`v"]; gw = Symbol["Global`w"];
gx = Symbol["Global`x"]; gy = Symbol["Global`y"];
lambda1 = (1 - gv - gw)^2 - 4 gv gw;
lambda3 = (1 - gv + gw)^2 + 4 gv gw;

registration = FeynFacet`TransportFamilyChartRegister[<|
  "ZZ7" -> "Kallen1",
  "ZZ8" -> <|"RootSquares" -> {lambda1, lambda3, 4 gv + gw^2}|>,
  "v = x y, w = (1-x)(1-y)" -> <|"ChartAlias" -> "Kallen1"|>|>];
FTAssert["a valid registration reports its count and kinds",
  AssociationQ[registration] &&
    registration["Status"] === "FamilyChartsRegistered" &&
    registration["Registered"] === 3 &&
    KeySort[registration["Kinds"]] === KeySort[<|"ChartName" -> 1,
      "RootSquares" -> 1, "ChartAlias" -> 1|>]];

chartNameLookup = FeynFacet`TransportFamilyChart["ZZ7"];
FTAssert["a registered chart name resolves to the catalog record",
  AssociationQ[chartNameLookup] &&
    chartNameLookup === FeynFacet`TransportChartCatalog[]["Kallen1"]];

rootLookup = FeynFacet`TransportFamilyChart["ZZ8"];
FTAssert["a registered root-square list resolves to an exact frame",
  AssociationQ[rootLookup] && rootLookup["Status"] === "ExactFrame" &&
    Length[rootLookup["Roots"]] === 3 &&
    TrueQ[rootLookup["ChartCertificate"]["OK"]] &&
    rootLookup["ChartCertificate"]["RootIdentities"] ===
      {True, True, True} &&
    rootLookup["Variables"] === {gx, gy}];

ga = Symbol["Global`generalityA"]; gb = Symbol["Global`generalityB"];
gp = Symbol["Global`generalityP"]; gq = Symbol["Global`generalityQ"];
renamedRoots = FeynFacet`TransportFamilyChart["ZZ8", {ga, gb}, {gp, gq}];
FTAssert["source and chart variables are arguments, not Global` literals",
  AssociationQ[renamedRoots] && renamedRoots["Status"] === "ExactFrame" &&
    renamedRoots["Variables"] === {gp, gq} &&
    renamedRoots["Subst"] === {ga -> gp, gb -> gq} &&
    TrueQ[Together[renamedRoots["Roots"][[1]]["RootSquare"] -
      ((1 - ga - gb)^2 - 4 ga gb)] === 0]];

renamedChart = FeynFacet`TransportFamilyChart["ZZ7", {ga, gb}, {gp, gq}];
FTAssert["a catalog chart is rekeyed exactly into the caller's symbols",
  AssociationQ[renamedChart] && renamedChart["Variables"] === {gp, gq} &&
    (First /@ renamedChart["Subst"]) === {ga, gb} &&
    Together[(Last /@ renamedChart["Subst"]) - {gp gq,
      (1 - gp) (1 - gq)}] === {0, 0}];

FTAssert["a legacy chart alias resolves through the registry",
  FeynFacet`Private`transportFamilyChartAlias[
      "v = x y, w = (1-x)(1-y)"] === "Kallen1" &&
    MissingQ[FeynFacet`Private`transportFamilyChartAlias["v = x, w = y"]]];
FTAssert["a record written with a legacy chart string is normalized",
  FeynFacet`Private`familyEpsFormLegacyChart[
      <|"Chart" -> "v = x y, w = (1-x)(1-y)"|>] ===
    <|"Chart" -> "Kallen1"|> &&
  FeynFacet`Private`familyEpsFormLegacyChart[
      <|"Chart" -> "NotAnAlias"|>] === <|"Chart" -> "NotAnAlias"|>];

before = registry;
refusals = <|
  "ChartNameNotInCatalog" ->
    FeynFacet`TransportFamilyChartRegister[<|"ZZ9" -> "NoSuchChart"|>],
  "RootSquareContainsRadicals" ->
    FeynFacet`TransportFamilyChartRegister[
      <|"ZZ9" -> <|"RootSquares" -> {Sqrt[gv]}|>|>],
  "RootSquaresNotANonemptyList" ->
    FeynFacet`TransportFamilyChartRegister[
      <|"ZZ9" -> <|"RootSquares" -> {}|>|>],
  "EntryKeysNotRecognized" ->
    FeynFacet`TransportFamilyChartRegister[
      <|"ZZ9" -> <|"Chart" -> "Kallen1"|>|>],
  "ChartAliasNotInCatalog" ->
    FeynFacet`TransportFamilyChartRegister[
      <|"ZZ9" -> <|"ChartAlias" -> "NoSuchChart"|>|>],
  "EntryNotStringOrAssociation" ->
    FeynFacet`TransportFamilyChartRegister[<|"ZZ9" -> 17|>]
|>;
FTAssert["every invalid entry is refused with its own reason",
  AllTrue[Keys[refusals], Function[reason,
    Lookup[refusals[reason], "Status", None] ===
        "InvalidFamilyChartEntries" &&
      Lookup[Lookup[refusals[reason]["Invalid"], "ZZ9", <||>],
        "Status", None] === reason]]];
FTAssert["a refused registration registers nothing",
  registry === before && MissingQ[FeynFacet`TransportFamilyChart["ZZ9"]]];
FTAssert["a mixed valid/invalid table registers nothing",
  Lookup[FeynFacet`TransportFamilyChartRegister[
      <|"ZZ10" -> "Kallen2", "ZZ11" -> "NoSuchChart"|>],
    "Status", None] === "InvalidFamilyChartEntries" &&
  MissingQ[FeynFacet`TransportFamilyChart["ZZ10"]]];
FTAssert["non-string family keys are refused",
  Lookup[FeynFacet`TransportFamilyChartRegister[<|17 -> "Kallen1"|>],
    "Status", None] === "FamilyChartKeysNotStrings"];

missingFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-no-such-chart-file-" <> CreateUUID[] <> ".wl"}];
badFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-bad-chart-file-" <> CreateUUID[] <> ".wl"}];
Put[{"not", "an", "association"}, badFile];
goodFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-chart-file-" <> CreateUUID[] <> ".wl"}];
Put[<|"ZZ12" -> "Kallen3"|>, goodFile];
FTAssert["a chart file is loaded, and a missing or malformed one refused",
  Lookup[FeynFacet`TransportFamilyChartLoad[missingFile], "Status",
      None] === "FamilyChartFileMissing" &&
    Lookup[FeynFacet`TransportFamilyChartLoad[badFile], "Status", None] ===
      "FamilyChartFileNotAnAssociation" &&
    Lookup[FeynFacet`TransportFamilyChartLoad[goodFile], "Status", None] ===
      "FamilyChartsRegistered" &&
    Lookup[FeynFacet`TransportFamilyChart["ZZ12"], "Name", None] ===
      "Kallen3"];
Quiet[DeleteFile /@ Select[{badFile, goodFile}, FileExistsQ]];

(* ------------------------------------------------------------------ *)
(*  PATHS and provenance                                                *)
(* ------------------------------------------------------------------ *)
FTAssert["the installation roots are package properties, not literals",
  StringQ[FeynFacet`Private`$feynFacetAddonRoot] &&
    DirectoryQ[FeynFacet`Private`$feynFacetAddonRoot] &&
    StringQ[FeynFacet`Private`$feynFacetLoader] &&
    FeynFacet`Private`masterTransportResolveInstallationRoot[Automatic] ===
      FeynFacet`Private`$feynFacetAddonRoot &&
    FeynFacet`Private`masterTransportResolveInstallationRoot[
      FileNameJoin[{$TemporaryDirectory, "feynfacet-no-such-root"}]] ===
      $Failed];
FTAssert["the blockwise transport root option defaults to Automatic",
  Lookup[Options[FeynFacet`Private`masterTransportBlockwiseSolve], "Root",
    Missing[]] === Automatic];

(* a context-qualified name may not be broken across lines *)
solverProvenance = FeynFacet`Private`familyRowGaugeSolverImplementationProvenance;
packageProvenance = solverProvenance["RationalChartFiniteField"];
driverPath = FileNameJoin[{root, "Scripts", "family_epsform_sector.wls"}];
driverProvenance = solverProvenance["RationalChartFiniteField",
  "DriverProvenance" -> <|"driver.wls" -> driverPath|>];
FTAssert["the solver provenance hashes only package sources by default",
  AssociationQ[packageProvenance] &&
    packageProvenance["DriverProvenance"] === <||> &&
    Sort[Keys[packageProvenance["SourceSHA256"]]] ===
      Sort[{"FamilyRowGaugeResume.wl", "FamilyRowGauge.wl",
        "FiniteFieldStripSolve.wl", "TransportCharts.wl"}]];
FTAssert["a driver declares its own identity through the option",
  AssociationQ[driverProvenance] &&
    Keys[driverProvenance["DriverProvenance"]] === {"driver.wls"} &&
    driverProvenance["DriverProvenance"]["driver.wls"]["Path"] ===
      driverPath &&
    driverProvenance["DriverProvenance"]["driver.wls"]["SHA256"] ===
      FileHash[driverPath, "SHA256", "HexString"] &&
    driverProvenance =!= packageProvenance &&
    solverProvenance["RationalChartFiniteField",
      "DriverProvenance" -> <|"driver.wls" -> missingFile|>] === $Failed];

sealed = FeynFacet`Private`familyRowGaugeSolverConfiguration[
  "ZeroForcing", "Rational", <||>, None, None, None, None,
  "DriverProvenance" -> <|"driver.wls" -> driverPath|>];
FTAssert["the sealed solver configuration is schema version 5 and valid",
  AssociationQ[sealed] && sealed["Status"] === "OK" &&
    sealed["SchemaVersion"] === 5 &&
    FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[sealed]];
FTAssert["a version-3 configuration is refused, so old checkpoints recompute",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
      Join[sealed, <|"SchemaVersion" -> 3|>]] &&
    Lookup[FeynFacet`Private`familyRowGaugeResumeSolverConfigurationCheck[
        <|"Method" -> "ZeroForcing",
          "SolverConfiguration" -> Join[sealed, <|"SchemaVersion" -> 3|>]|>,
        sealed], "Status", None] === "ResumeSolverConfigurationMismatch"];
FTAssert["a configuration whose driver source changed is refused",
  ! FeynFacet`Private`familyRowGaugeSolverConfigurationValidQ[
    sealed /. driverPath -> FileNameJoin[{root, "Tests", "TestKit.wl"}]]];

(* A2: an empty differential directory is named, never a complete inventory *)
emptyDirectory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "feynfacet-generality-" <> CreateUUID[]}]];
valuations = FileNameJoin[{emptyDirectory, "valuations.wl"}];
Put[<||>, valuations];
manifestReport = FeynFacet`BuildObservableTransportManifest[
  {emptyDirectory}, emptyDirectory, valuations,
  FileNameJoin[{emptyDirectory, "manifest.tsv"}],
  "ReportFile" -> None];
FTAssert["zero differential families is a named refusal, not an inventory",
  Lookup[manifestReport, "Status", None] ===
      "NoDifferentialFamiliesFound" &&
    Lookup[manifestReport, "DifferentialFamilyCount", -1] === 0 &&
    ! FileExistsQ[FileNameJoin[{emptyDirectory, "manifest.tsv"}]]];
FTAssert["the manifest builder takes its file patterns from the caller",
  Sort[Keys[Association[
    Options[FeynFacet`BuildObservableTransportManifest]]]] ===
    Sort[{"Card", "ReportFile", "DifferentialFilePattern",
      "EpsFormFilePattern", "FamilyFromFileName", "FamilySortKey"}]];
Quiet[DeleteDirectory[emptyDirectory, DeleteContents -> True]];

(* C4: the chart-extension output variables.  RationalizeRoots is an
   external add-on; when it is not installed the routine refuses typed
   before the collision check, and that is what is asserted then. *)
rationalizeRootsFile = FileNameJoin[{FeynFacet`Private`$feynFacetAddonRoot,
  "Addon", "Mathematica_Addon", "RationalizeRoots", "RationalizeRoots.m"}];
extension = FeynFacet`RationalizeTransportChartExtension[
  FeynFacet`TransportChartCatalog[]["Kallen1"],
  (1 + gv - gw)^2 + 4 gv gw,
  "OutputVariables" -> {gx, gy}, "TimeConstraint" -> 30];
FTAssert["chart-extension output variables may not meet the base chart",
  Lookup[extension, "Status", None] === If[FileExistsQ[rationalizeRootsFile],
    "OutputVariablesCollideWithBaseChart", "RationalizeRootsUnavailable"]];
FTAssert["the chart-extension output default is a fresh private pair",
  Lookup[Options[FeynFacet`RationalizeTransportChartExtension],
      "OutputVariables", Missing[]] === Automatic &&
    FreeQ[Options[FeynFacet`RationalizeTransportChartExtension],
      Symbol["Global`r"] | Symbol["Global`t"]]];

FTReport[];
