#!/usr/bin/env wolframscript
(* Adversarial generality test T1 (Design/GeneralityFixes.md).

   Acceptance criteria, stated before the run:
     STATIC   -- with every Wolfram comment removed (nested comments and
                 string literals handled), no source file under FeynFacet/
                 contains a canonical-family literal ("CF" followed by a
                 digit), an absolute /home/ path, or a project-tree name.
                 Raw loaded Private source, including comments, log text,
                 and status text, contains no concrete family or campaign
                 identifiers; measured scale descriptions remain generic.
     RUNTIME  -- the per-family root-data registry ships EMPTY; an
                 unregistered family is Missing, never None; a synthetic
                 family registers and resolves in both supported V2 forms
                 (a catalogued rationalizing parametrization and explicit
                 source radicands); legacy and invalid registrations are
                 refused and register nothing.
     PATHS    -- no installation path is a built-in literal: the transport
                 backends' root resolves from the package, and package code
                 contains no project-specific result-tree paths. *)

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

(* Loaded implementation prose must remain reusable across projects.  This
   scan is deliberately raw: family labels in comments and messages are the
   regression this assertion protects against. *)
privateSourceFiles = Sort[DeleteDuplicates[Join[
  FileNames["*.m", FileNameJoin[{root, "FeynFacet", "Private"}], Infinity],
  FileNames["*.wl", FileNameJoin[{root, "FeynFacet", "Private"}], Infinity]]]];
privateProvenanceForbidden = <|
  "ConcreteCanonicalFamily" -> RegularExpression["(?i)\\bCF[0-9]+\\b"],
  "NamedCampaignFamily" -> RegularExpression["(?i)(ppHX|UU[_-]?08([_-][A-Za-z0-9]+)*|NNLO_DoubleReal)"],
  "ConcreteResultsPath" -> RegularExpression["(?i)Results[\\\\/]"],
  "ConcreteReviewPath" -> RegularExpression["(?i)Exchange[\\\\/](Codex|Fable)"],
  "ConcreteRepositoryPath" -> RegularExpression["(?i)(/home/maxzhang|factorization-and-loops)"]
|>;

privateProvenanceViolations = Flatten[Table[
  With[{lines = StringSplit[Import[file, "Text"], "\n", All]},
    Flatten[Table[
      If[StringContainsQ[lines[[line]], privateProvenanceForbidden[kind]],
        <|"File" -> FileNameTake[file], "Line" -> line, "Kind" -> kind,
          "Text" -> StringTrim[lines[[line]]]|>,
        Nothing],
      {kind, Keys[privateProvenanceForbidden]}, {line, Length[lines]}], 1]],
  {file, privateSourceFiles}], 1];

If[privateProvenanceViolations =!= {},
  Print["private-source provenance violations:"];
  Scan[Print["  ", #["File"], ":", #["Line"], " [", #["Kind"], "] ",
    StringTake[#["Text"], UpTo[100]]] &, privateProvenanceViolations]];
FTAssert["Private comments, messages, and statuses contain no concrete family or campaign identifiers",
  privateProvenanceViolations === {}];

(* ------------------------------------------------------------------ *)
(*  RUNTIME: the per-family root-data registry                          *)
(* ------------------------------------------------------------------ *)
registry := FeynFacet`Private`$familyRootDataRegistry;

FTAssert["the package ships an empty family root-data registry",
  registry === <||>];

emptyLookup = FeynFacet`FamilyRootData["ZZ7"];
FTAssert["an unregistered family is Missing, never None",
  emptyLookup === Missing["FamilyRootDataNotRegistered", "ZZ7"] &&
    emptyLookup =!= None && MissingQ[emptyLookup]];

(* the package's own source/chart symbols, never assigned to themselves
   (self-assignment v = Global`v is one of this repository's paid-for
   Wolfram traps) *)
gv = Symbol["Global`v"]; gw = Symbol["Global`w"];
gx = Symbol["Global`x"]; gy = Symbol["Global`y"];
lambda1 = (1 - gv - gw)^2 - 4 gv gw;
lambda3 = (1 - gv + gw)^2 + 4 gv gw;

registration = FeynFacet`RegisterFamilyRootData[<|
  "ZZ7" -> <|"RationalizingParametrizationName" -> "Kallen1"|>,
  "ZZ8" -> <|"SourceRadicands" ->
    {lambda1, lambda3, 4 gv + gw^2}|>|>];
FTAssert["a valid registration reports its count and kinds",
  AssociationQ[registration] &&
    registration["Status"] === "FamilyRootDataRegistered" &&
    registration["Registered"] === 2 &&
    KeySort[registration["Kinds"]] === KeySort[<|
      "RationalizingParametrization" -> 1,
      "SquareRootGeneratorsAndQuadraticRelations" -> 1|>]];

chartNameLookup = FeynFacet`FamilyRootData["ZZ7"];
FTAssert["a registered chart name resolves to the catalog record",
  AssociationQ[chartNameLookup] &&
    chartNameLookup === FeynFacet`RationalizingParametrizationCatalog[]["Kallen1"]];

rootLookup = FeynFacet`FamilyRootData["ZZ8"];
FTAssert["a registered root-square list resolves to an exact frame",
  AssociationQ[rootLookup] &&
    rootLookup["Status"] === "SquareRootGeneratorRelationsVerified" &&
    Length[rootLookup["SquareRootGenerators"]] === 3 &&
    TrueQ[rootLookup["QuadraticRelationVerification"]["Verified"]] &&
    rootLookup["QuadraticRelationVerification"]["PerGenerator"] ===
      {True, True, True} &&
    rootLookup["CoefficientVariables"] === {gx, gy}];

ga = Symbol["Global`generalityA"]; gb = Symbol["Global`generalityB"];
gp = Symbol["Global`generalityP"]; gq = Symbol["Global`generalityQ"];
renamedRoots = FeynFacet`FamilyRootData["ZZ8", {ga, gb}, {gp, gq}];
FTAssert["source and chart variables are arguments, not Global` literals",
  AssociationQ[renamedRoots] &&
    renamedRoots["Status"] === "SquareRootGeneratorRelationsVerified" &&
    renamedRoots["CoefficientVariables"] === {gp, gq} &&
    renamedRoots["SourceToCoefficientVariableRules"] ===
      {ga -> gp, gb -> gq} &&
    TrueQ[Together[
      renamedRoots["SquareRootGenerators"][[1]]["SourceRadicand"] -
        ((1 - ga - gb)^2 - 4 ga gb)] === 0] &&
    TrueQ[Together[
      renamedRoots["SquareRootGenerators"][[1]]["QuadraticRadicand"] -
        ((1 - gp - gq)^2 - 4 gp gq)] === 0]];

renamedChart = FeynFacet`FamilyRootData["ZZ7", {ga, gb}, {gp, gq}];
FTAssert["a catalog chart is rekeyed exactly into the caller's symbols",
  AssociationQ[renamedChart] &&
    renamedChart["ParametrizingVariables"] === {gp, gq} &&
    (First /@ renamedChart["SourceVariableSubstitution"]) === {ga, gb} &&
    Together[(Last /@ renamedChart["SourceVariableSubstitution"]) - {gp gq,
      (1 - gp) (1 - gq)}] === {0, 0}];

FTAssert["legacy chart and root-square registry entries are refused",
  AllTrue[
    {<|"ChartAlias" -> "Kallen1"|>,
      <|"RootSquares" -> {lambda1}|>,
      <|"RationalizingParametrizationAlias" -> "Kallen1"|>},
    Lookup[FeynFacet`RegisterFamilyRootData[<|"ZZ9" -> #|>],
      "Status", None] === "InvalidFamilyRootDataEntries" &]];

before = registry;
refusals = <|
  "RationalizingParametrizationNameNotInCatalog" ->
    FeynFacet`RegisterFamilyRootData[<|"ZZ9" -> <|
      "RationalizingParametrizationName" -> "NoSuchParametrization"|>|>],
  "SourceRadicandContainsRadicals" ->
    FeynFacet`RegisterFamilyRootData[
      <|"ZZ9" -> <|"SourceRadicands" -> {Sqrt[gv]}|>|>],
  "SourceRadicandsNotANonemptyList" ->
    FeynFacet`RegisterFamilyRootData[
      <|"ZZ9" -> <|"SourceRadicands" -> {}|>|>],
  "FamilyRootDataEntryKeysNotRecognized" ->
    FeynFacet`RegisterFamilyRootData[
      <|"ZZ9" -> <|"UnknownField" -> "Kallen1"|>|>],
  "SourceRadicandEntryHasExtraKeys" ->
    FeynFacet`RegisterFamilyRootData[
      <|"ZZ9" -> <|"SourceRadicands" -> {lambda1},
        "Extra" -> True|>|>],
  "FamilyRootDataEntryNotAssociation" ->
    FeynFacet`RegisterFamilyRootData[<|"ZZ9" -> 17|>]
|>;
FTAssert["every invalid entry is refused with its own reason",
  AllTrue[Keys[refusals], Function[reason,
    Lookup[refusals[reason], "Status", None] ===
        "InvalidFamilyRootDataEntries" &&
      Lookup[Lookup[refusals[reason]["Invalid"], "ZZ9", <||>],
        "Status", None] === reason]]];
FTAssert["a refused registration registers nothing",
  registry === before && MissingQ[FeynFacet`FamilyRootData["ZZ9"]]];
FTAssert["a mixed valid/invalid table registers nothing",
  Lookup[FeynFacet`RegisterFamilyRootData[
      <|"ZZ10" -> <|"RationalizingParametrizationName" -> "Kallen2"|>,
        "ZZ11" -> <|"RationalizingParametrizationName" ->
          "NoSuchParametrization"|>|>],
    "Status", None] === "InvalidFamilyRootDataEntries" &&
  MissingQ[FeynFacet`FamilyRootData["ZZ10"]]];
FTAssert["non-string family keys are refused",
  Lookup[FeynFacet`RegisterFamilyRootData[<|17 -> <|
      "RationalizingParametrizationName" -> "Kallen1"|>|>],
    "Status", None] === "FamilyRootDataKeysNotStrings"];

missingFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-no-such-chart-file-" <> CreateUUID[] <> ".wl"}];
badFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-bad-chart-file-" <> CreateUUID[] <> ".wl"}];
Put[{"not", "an", "association"}, badFile];
goodFile = FileNameJoin[{$TemporaryDirectory,
  "feynfacet-chart-file-" <> CreateUUID[] <> ".wl"}];
Put[<|"ZZ12" -> <|
  "RationalizingParametrizationName" -> "Kallen3"|>|>, goodFile];
FTAssert["a root-data file is loaded, and a missing or malformed one refused",
  Lookup[FeynFacet`LoadFamilyRootData[missingFile], "Status",
      None] === "FamilyRootDataFileMissing" &&
    Lookup[FeynFacet`LoadFamilyRootData[badFile], "Status", None] ===
      "FamilyRootDataFileNotAnAssociation" &&
    Lookup[FeynFacet`LoadFamilyRootData[goodFile], "Status", None] ===
      "FamilyRootDataRegistered" &&
    Lookup[FeynFacet`FamilyRootData["ZZ12"], "Name", None] ===
      "Kallen3"];
Quiet[DeleteFile /@ Select[{badFile, goodFile}, FileExistsQ]];

(* ------------------------------------------------------------------ *)
(*  PATHS and provenance                                                *)
(* ------------------------------------------------------------------ *)
FTAssert["the installation roots are package properties, not literals",
  StringQ[FeynFacet`Private`$feynFacetAddonRoot] &&
    DirectoryQ[FeynFacet`Private`$feynFacetAddonRoot] &&
    StringQ[FeynFacet`Private`$feynFacetLoader] &&
    FileExistsQ[FeynFacet`Private`$feynFacetLoader]];
FTAssert["the removed path-ordered compatibility route is not public",
  System`Names["FeynFacet`TransportFamily"] === {} &&
    DownValues[FeynFacet`Private`masterTransportBlockwiseSolve] === {}];

(* A2: an empty differential directory is named, never a complete inventory *)
emptyDirectory = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "feynfacet-generality-" <> CreateUUID[]}]];
valuations = FileNameJoin[{emptyDirectory, "valuations.wl"}];
Put[<||>, valuations];
inputFileSearch =
  FeynFacet`FindRequestedOutputIteratedIntegralCoefficientInputFiles[
    {emptyDirectory}, emptyDirectory];
FTAssert["zero differential families is a named refusal, not an inventory",
  Lookup[inputFileSearch, "Status", None] ===
      "NoDifferentialFamiliesFound" &&
    Lookup[inputFileSearch, "DifferentialFamilyCount", -1] === 0 &&
    ! FileExistsQ[FileNameJoin[{emptyDirectory, "manifest.tsv"}]]];
FTAssert["the input-file finder takes its file patterns from the caller",
  Sort[Keys[Association[
    Options[
      FeynFacet`FindRequestedOutputIteratedIntegralCoefficientInputFiles]]]] ===
    Sort[{"DifferentialFilePattern", "EpsFormFilePattern",
      "FamilyFromFileName"}]];
Quiet[DeleteDirectory[emptyDirectory, DeleteContents -> True]];

(* C4: the chart-extension output variables.  RationalizeRoots is an
   external add-on; when it is not installed the routine refuses typed
   before the collision check, and that is what is asserted then. *)
rationalizeRootsFile = FileNameJoin[{FeynFacet`Private`$feynFacetAddonRoot,
  "Addon", "Mathematica_Addon", "RationalizeRoots", "RationalizeRoots.m"}];
extension = FeynFacet`ExtendRationalizingParametrization[
  FeynFacet`RationalizingParametrizationCatalog[]["Kallen1"],
  (1 + gv - gw)^2 + 4 gv gw,
  "OutputVariables" -> {gx, gy}, "TimeConstraint" -> 30];
FTAssert["extension variables may not collide with the base parametrization",
  Lookup[extension, "Status", None] === If[FileExistsQ[rationalizeRootsFile],
    "OutputVariablesCollideWithBaseParametrization",
    "RationalizeRootsUnavailable"]];
FTAssert["the parametrization-extension output default is a fresh private pair",
  Lookup[Options[FeynFacet`ExtendRationalizingParametrization],
      "OutputVariables", Missing[]] === Automatic &&
    FreeQ[Options[FeynFacet`ExtendRationalizingParametrization],
      Symbol["Global`r"] | Symbol["Global`t"]]];

FTReport[];
