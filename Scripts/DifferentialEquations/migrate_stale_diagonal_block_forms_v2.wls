#!/usr/bin/env wolframscript

(* One-time project migration of already known diagonal-block epsilon forms.

   The stale class files are candidate generators only.  For every requested
   family block this script rederives the exact permutation/source-variable
   exchange that relates the stale representative connection to the current
   V2 family connection, reexpresses the candidate in the explicitly selected
   V2 coefficient presentation, and hands it to the current constructor.  The
   output is accepted only by that constructor's production finite-field
   check against the current family differential system.

   No stale schema or project path is supported inside FeynFacet/Private. *)

$HistoryLength = 0;

usage = StringRiffle[{
  "wolframscript -file migrate_stale_diagonal_block_forms_v2.wls",
  "  --repository-root ROOT",
  "  --family-differential-system PATH",
  "  --coefficient-presentation PATH",
  "  --block-decomposition PATH",
  "  --stale-block-classes PATH --stale-class-form-directory DIR",
  "  --output-directory DIR [--overwrite true|false]",
  "PATH and DIR may be absolute or relative to ROOT."
}, "\n"];

fail[status_String, extra_: <||>, exitCode_: 64] := (
  Print[InputForm[Join[<|"Status" -> status|>, extra]]];
  Exit[exitCode]
);

absolutePathQ[path_String] := StringStartsQ[path, "/"] ||
  StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];

resolvePath[root_String, path_String] := ExpandFileName[
  If[absolutePathQ[path], path, FileNameJoin[{root, path}]]];

args = Rest[$ScriptCommandLine];
If[MemberQ[args, "--help"] || MemberQ[args, "-h"],
  Print[usage]; Exit[0]];
If[OddQ[Length[args]],
  fail["CommandLineArgumentsInvalid", <|"Usage" -> usage|>]];
pairs = Partition[args, 2];
If[! AllTrue[pairs,
    StringQ[First[#]] && StringStartsQ[First[#], "--"] &] ||
    ! DuplicateFreeQ[First /@ pairs],
  fail["CommandLineArgumentsInvalid", <|"Usage" -> usage|>]];
raw = Association[(StringDrop[First[#], 2] -> Last[#]) & /@ pairs];
known = {"repository-root", "family-differential-system",
  "coefficient-presentation", "block-decomposition",
  "stale-block-classes", "stale-class-form-directory",
  "output-directory", "overwrite"};
unknown = Complement[Keys[raw], known];
If[unknown =!= {}, fail["CommandLineOptionUnknown",
  <|"UnknownOptions" -> unknown|>]];
missing = Select[Most[known], ! KeyExistsQ[raw, #] &];
If[missing =!= {}, fail["CommandLineOptionsMissing",
  <|"MissingOptions" -> missing, "Usage" -> usage|>]];

repositoryRoot = ExpandFileName[raw["repository-root"]];
If[! DirectoryQ[repositoryRoot], fail["RepositoryRootNotFound",
  <|"RepositoryRoot" -> repositoryRoot|>, 66]];
systemFile = resolvePath[repositoryRoot, raw["family-differential-system"]];
presentationFile = resolvePath[repositoryRoot,
  raw["coefficient-presentation"]];
decompositionFile = resolvePath[repositoryRoot,
  raw["block-decomposition"]];
classesFile = resolvePath[repositoryRoot, raw["stale-block-classes"]];
classFormDirectory = resolvePath[repositoryRoot,
  raw["stale-class-form-directory"]];
outputDirectory = resolvePath[repositoryRoot, raw["output-directory"]];
overwrite = Switch[ToLowerCase[Lookup[raw, "overwrite", "false"]],
  "true", True, "false", False, _, $Failed];
If[overwrite === $Failed, fail["OverwriteOptionInvalid"]];
If[! AllTrue[{systemFile, presentationFile, decompositionFile,
      classesFile}, FileExistsQ],
  fail["MigrationInputFileNotFound", <|
    "Files" -> Select[{systemFile, presentationFile, decompositionFile,
      classesFile}, ! FileExistsQ[#] &]|>, 66]];
If[! DirectoryQ[classFormDirectory],
  fail["StaleClassFormDirectoryNotFound", <|
    "Directory" -> classFormDirectory|>, 66]];
If[! DirectoryQ[outputDirectory],
  CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]];

read[file_String] := FeynFacet`FamilyArtifactRead[file];
system = read[systemFile];
presentation = read[presentationFile];
decomposition = read[decompositionFile];
classes = read[classesFile];
If[! AssociationQ[system] || ! AssociationQ[presentation] ||
    ! AssociationQ[decomposition] || ! ListQ[classes],
  fail["MigrationInputUnreadable", <|
    "SystemAssociation" -> AssociationQ[system],
    "PresentationAssociation" -> AssociationQ[presentation],
    "DecompositionAssociation" -> AssociationQ[decomposition],
    "ClassList" -> ListQ[classes]|>, 65]];
If[! TrueQ[FeynFacet`FamilyDifferentialSystemBlockDecompositionQ[
      decomposition, system]],
  fail["BlockDecompositionDoesNotMatchFamilyDifferentialSystem", <|
    "Family" -> Lookup[system, "Family", Missing[]]|>, 2]];

family = system["Family"];
sourceVariables = system["KinematicVariables"];
regulator = system["DimensionalRegulator"];
presentationData =
  FeynFacet`Private`masterTransportCoefficientPresentationData[
    presentation, sourceVariables];
If[Lookup[presentationData, "Status", None] =!= "OK",
  fail["CoefficientPresentationInvalid", <|
    "Reason" -> Lookup[presentationData, "Status", None]|>, 2]];
coefficientVariables =
  FeynFacet`Private`masterTransportPresentationVariables[
    presentationData];
blocks = decomposition["IrreducibleDiagonalBlocks"];
nonScalarBlocks = Select[blocks, Length[#] > 1 &];

classFor[rows_List] := SelectFirst[classes,
  Function[class, AnyTrue[Lookup[class, "Members", {}],
    Lookup[#, "Family", None] === family &&
      Lookup[#, "Rows", None] === rows &]], Missing["NotFound"]];

classFormFile[class_Association] := FileNameJoin[{classFormDirectory,
  "class" <> ToString[class["ClassID"]] <> ".wl"}];

classMemberMap[class_Association, rows_List] := Module[
  {representative, swappedRepresentative, member, normalizedRepresentative,
   normalizedSwappedRepresentative, normalizedMember},
  representative = {class["RepAv"], class["RepAw"]};
  member = system["ConnectionMatrices"][[All, rows, rows]];
  normalizedRepresentative =
    FeynFacet`Private`canonicalBlocksMatrix[#,
      sourceVariables, regulator] & /@ representative;
  swappedRepresentative =
    FeynFacet`Private`canonicalBlocksSwapPair[
      representative, sourceVariables];
  normalizedSwappedRepresentative =
    FeynFacet`Private`canonicalBlocksMatrix[#,
      sourceVariables, regulator] & /@ swappedRepresentative;
  normalizedMember = FeynFacet`Private`canonicalBlocksMatrix[#,
      sourceVariables, regulator] & /@ member;
  FeynFacet`Private`canonicalBlocksMatchOrbit[
    normalizedRepresentative, normalizedSwappedRepresentative,
    normalizedMember]
];

(* Recover the compact dlog data needed by the V2 record.  This is candidate
   construction, not acceptance: it deliberately does not repeat the stale
   record's characteristic-zero identity check.  The current constructor
   tests the resulting T and residues directly against the current family
   connection at its stored finite-field points. *)
extractDLogData[form_Association, classID_Integer] := Module[
  {variables, epsilonForm, reduced, letters, logarithmicDerivatives,
   points, rows, rightHandSide, solveEntry, solutions, residues, dimension},
  variables = Lookup[form, "Variables", Missing[]];
  epsilonForm = Lookup[form, "EpsForm", Missing[]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[epsilonForm, {_?MatrixQ, _?MatrixQ}], Return[$Failed]];
  dimension = Length[epsilonForm[[1]]];
  reduced = Map[Together[#/regulator] &, epsilonForm, {3}];
  If[! FreeQ[reduced, regulator], Return[$Failed]];
  letters = FeynFacet`Private`familyCertLetters[
    epsilonForm, variables, regulator];
  If[letters === {},
    Return[If[AllTrue[Flatten[reduced], TrueQ[# === 0] &],
      <|"Letters" -> {}, "Residues" -> {}|>, $Failed]]];
  logarithmicDerivatives = Table[
    Together[D[letter, variable]/letter],
    {letter, letters}, {variable, variables}];
  BlockRandom[
    SeedRandom[910000 + classID, Method -> "MersenneTwister"];
    points = Table[Thread[variables -> Table[
      RandomInteger[{2, 97}]/RandomInteger[{101, 199}],
      Length[variables]]], {Length[letters] + 6}]];
  rows = Flatten[Table[
    logarithmicDerivatives[[All, direction]] /. point,
    {point, points}, {direction, Length[variables]}], 1];
  solveEntry[row_, column_] := Module[{solution},
    rightHandSide = Flatten[Table[
      reduced[[direction, row, column]] /. point,
      {point, points}, {direction, Length[variables]}]];
    solution = Quiet[Check[LinearSolve[rows, rightHandSide], $Failed]];
    If[VectorQ[solution], solution, $Failed]
  ];
  solutions = Table[solveEntry[row, column],
    {row, dimension}, {column, dimension}];
  If[! FreeQ[solutions, $Failed], Return[$Failed]];
  residues = Table[
    Table[solutions[[row, column, letterIndex]],
      {row, dimension}, {column, dimension}],
    {letterIndex, Length[letters]}];
  <|"Letters" -> letters, "Residues" -> residues|>
];

(* Recover q(sourceVariables) from a rationalizing chart by eliminating its
   local parameters from

       sourceVariables == chart images,       q == rationalRoot^2.

   This uses the chart relation itself, rather than guessing q from the
   currently selected family's root list.  The latter is not invariant under
   the source-variable exchange relating a class representative to a member.
   Direct inversion is tried first; exact elimination is the general fallback.
   Every returned expression is verified by substitution back into the chart. *)
recoverSourceRadicand[substitution_List, rationalRoot_,
    localVariables_List] := Module[
  {parameters, equations, inverseSolutions, marker, eliminated,
   markerSolutions, candidates, normalize, verified},
  If[! MatchQ[substitution, {_Rule, _Rule}] ||
      ! MatchQ[localVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[rationalRoot, Except[_Missing]], Return[$Failed]];
  parameters = Select[localVariables,
    ! MemberQ[sourceVariables, #] &];
  If[parameters === {}, Return[$Failed]];
  equations = DeleteCases[MapThread[
    Numerator[Together[#1 - #2]] == 0 &,
    {sourceVariables, Last /@ substitution}], True];
  If[equations === {}, Return[$Failed]];
  normalize[expression_] := Quiet[Check[
    Cancel[Together[expression]], $Failed]];
  inverseSolutions = Quiet[Check[Solve[equations, parameters], {}]];
  candidates = Cases[inverseSolutions, rules_List :>
    normalize[rationalRoot^2 /. rules]];
  candidates = Select[candidates,
    # =!= $Failed && FreeQ[#, Alternatives @@ parameters] &&
      FreeQ[#, _ConditionalExpression] &];
  verified = Select[candidates, TrueQ[Together[
      (# /. substitution) - rationalRoot^2] === 0] &];
  If[verified =!= {},
    Return[First[DeleteDuplicates[verified,
      TrueQ[Together[#1 - #2] === 0] &]]]];
  marker = Unique["sourceRadicand"];
  eliminated = Quiet[Check[Eliminate[And @@ Append[equations,
      Numerator[Together[marker - rationalRoot^2]] == 0], parameters],
    $Failed]];
  If[eliminated === $Failed, Return[$Failed]];
  markerSolutions = Quiet[Check[Solve[eliminated, marker], {}]];
  candidates = Cases[markerSolutions,
    rules_List :> normalize[marker /. rules]];
  candidates = Select[candidates,
    # =!= $Failed && FreeQ[#, Alternatives @@ parameters] &&
      FreeQ[#, marker | _ConditionalExpression] &];
  verified = Select[candidates, TrueQ[Together[
      (# /. substitution) - rationalRoot^2] === 0] &];
  If[verified === {}, $Failed,
    First[DeleteDuplicates[verified,
      TrueQ[Together[#1 - #2] === 0] &]]]
];

oldLocalParametrization[form_Association, swapped_] := Module[
  {old, localVariables, substitution, fixed, root, radicand,
   images},
  old = Lookup[form, "Chart", None];
  If[MemberQ[{None, Null}, old], Return[None]];
  localVariables = form["Variables"];
  If[! AssociationQ[old] ||
      ! MatchQ[localVariables, {_Symbol, _Symbol}], Return[$Failed]];
  Which[
    MatchQ[Lookup[old, "Subst", Missing[]], {_Rule, _Rule}],
      substitution = old["Subst"];
      root = Lookup[old, "Root", Missing[]];
      radicand = Lookup[old, "RootSquare", Missing[]],
    MatchQ[Lookup[old, "Subst", Missing[]], _Rule] &&
        MatchQ[Lookup[old, "Fixed", Missing[]], _Symbol],
      fixed = old["Fixed"];
      substitution = (# -> If[# === fixed, #,
          Together[# /. old["Subst"]]]) & /@ sourceVariables;
      root = Together[Lookup[old, "Root", Missing[]] /. old["Subst"]];
      radicand = Lookup[old, "RootSquare", Missing[]],
    True, Return[$Failed]
  ];
  If[MatchQ[radicand, _Missing],
    radicand = recoverSourceRadicand[
      substitution, root, localVariables]];
  If[! MatchQ[root, Except[_Missing]] ||
      radicand === $Failed ||
      ! MatchQ[radicand, Except[_Missing]], Return[$Failed]];
  If[TrueQ[swapped],
    images = Reverse[Last /@ substitution];
    substitution = Thread[sourceVariables -> images];
    radicand = FeynFacet`Private`canonicalBlocksSwap[
      radicand, sourceVariables]];
  <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "Name" -> "MigratedDiagonalBlockLocalParametrization",
    "Kind" -> "TwoVariable",
    "SourceVariables" -> sourceVariables,
    "ParametrizingVariables" -> localVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> {<|
      "RationalRoot" -> root,
      "SourceRadicand" -> radicand|>},
    "ParentParametrizationMaps" -> <||>,
    "ParentParametrizations" -> <||>
  |>
];

candidateFor[rows_List, class_Association, form_Association,
    map_Association] := Module[
  {details, permutation, swapped, transformation, letters, residues,
   localPresentation, coordinateRecord, coordinateMap, rules},
  details = extractDLogData[form, class["ClassID"]];
  If[! AssociationQ[details],
    Return[<|"Status" -> "StaleClassDLogDecompositionFailed",
      "ClassID" -> class["ClassID"]|>]];
  permutation = map["Permutation"];
  swapped = TrueQ[map["Swap"]];
  transformation = form["Transformation"][[permutation, permutation]];
  letters = details["Letters"];
  residues = #[[permutation, permutation]] & /@ details["Residues"];
  localPresentation = oldLocalParametrization[form, swapped];
  If[localPresentation === $Failed,
    Return[<|"Status" -> "StaleLocalParametrizationNotConvertible",
      "ClassID" -> class["ClassID"]|>]];
  If[localPresentation === None,
    If[swapped,
      transformation = FeynFacet`Private`canonicalBlocksSwap[
        transformation, sourceVariables];
      letters = FeynFacet`Private`canonicalBlocksSwap[
        letters, sourceVariables]];
    coordinateRecord = <|
      "CoefficientVariables" -> form["Variables"]|>,
    coordinateRecord = <|
      "CoefficientVariables" -> form["Variables"],
      "RationalizingParametrization" -> localPresentation|>
  ];
  coordinateMap = FeynFacet`Private`masterTransportRecordCoordinateMap[
    coordinateRecord, presentationData];
  If[Lookup[coordinateMap, "Status", None] =!= "OK",
    Return[<|"Status" -> "StaleCandidateReexpressionFailed",
      "ClassID" -> class["ClassID"],
      "Reason" -> Lookup[coordinateMap, "Status", None]|>]];
  rules = coordinateMap["CoefficientVariableRules"];
  <|
    "DataType" -> "DiagonalBlockDLogEpsilonForm",
    "SchemaVersion" -> 2,
    "BlockRows" -> rows,
    "CoefficientVariables" -> coefficientVariables,
    "DimensionalRegulator" -> regulator,
    "BasisTransformationMatrix" -> (transformation /. rules),
    "Letters" -> (letters /. rules),
    "ConstantResidueMatrices" -> residues,
    "Status" -> "UnvalidatedMigrationCandidate",
    "Validation" -> <||>
  |>
];

results = Table[Catch[Module[
    {class, file, form, map, candidate, result, outputFile, start},
  start = AbsoluteTime[];
  Print["MIGRATE-DIAGONAL-BLOCK family=", family,
    " rows=", InputForm[rows], " stage=start"];
  outputFile = FileNameJoin[{outputDirectory,
    "rows_" <> StringRiffle[ToString /@ rows, "_"] <> ".wl"}];
  If[FileExistsQ[outputFile] && ! overwrite,
    result = read[outputFile];
    If[TrueQ[FeynFacet`DiagonalBlockDLogEpsilonFormQ[
        result, system, presentation]],
      Throw[<|"Status" -> "ExistingV2FormAccepted",
        "BlockRows" -> rows, "OutputFile" -> outputFile,
        "Seconds" -> N[AbsoluteTime[] - start]|>, "block"]]];
  class = classFor[rows];
  If[MissingQ[class], Throw[<|"Status" -> "StaleClassNotFound",
    "BlockRows" -> rows|>, "block"]];
  file = classFormFile[class];
  If[! FileExistsQ[file], Throw[<|"Status" -> "StaleClassFormNotFound",
    "BlockRows" -> rows, "ClassID" -> class["ClassID"]|>, "block"]];
  form = read[file];
  If[! AssociationQ[form], Throw[<|
    "Status" -> "StaleClassFormUnreadable", "BlockRows" -> rows,
    "ClassID" -> class["ClassID"]|>, "block"]];
  map = classMemberMap[class, rows];
  If[! AssociationQ[map], Throw[<|
    "Status" -> "StaleClassMemberMapNotRecovered", "BlockRows" -> rows,
    "ClassID" -> class["ClassID"]|>, "block"]];
  candidate = candidateFor[rows, class, form, map];
  If[Lookup[candidate, "DataType", None] =!=
      "DiagonalBlockDLogEpsilonForm",
    Throw[Join[candidate, <|"BlockRows" -> rows|>], "block"]];
  result = FeynFacet`ConstructDiagonalBlockDLogEpsilonForm[
    system, presentation, rows,
    "CandidateDiagonalBlockDLogEpsilonForm" -> candidate];
  If[! TrueQ[FeynFacet`DiagonalBlockDLogEpsilonFormQ[
      result, system, presentation]],
    Throw[<|"Status" -> "MigratedCandidateRejected",
      "BlockRows" -> rows, "ClassID" -> class["ClassID"],
      "MemberMap" -> map, "Reason" -> result|>, "block"]];
  FeynFacet`FamilyArtifactWrite[result, outputFile];
  Print["MIGRATE-DIAGONAL-BLOCK family=", family,
    " rows=", InputForm[rows], " class=", class["ClassID"],
    " stage=written seconds=", N[AbsoluteTime[] - start]];
  <|"Status" -> "V2FormWritten", "BlockRows" -> rows,
    "ClassID" -> class["ClassID"], "MemberMap" -> map,
    "OutputFile" -> outputFile,
    "Seconds" -> N[AbsoluteTime[] - start]|>
], "block"], {rows, nonScalarBlocks}];

summary = <|
  "Status" -> If[AllTrue[results,
      MemberQ[{"V2FormWritten", "ExistingV2FormAccepted"},
        Lookup[#, "Status", None]] &],
    "StaleDiagonalBlockFormsMigratedToV2",
    "StaleDiagonalBlockFormMigrationIncomplete"],
  "Family" -> family,
  "RequestedNonScalarBlocks" -> Length[nonScalarBlocks],
  "AcceptedBlocks" -> Count[Lookup[results, "Status", None],
    "V2FormWritten" | "ExistingV2FormAccepted"],
  "Results" -> results|>;
Print[InputForm[summary]];
If[summary["Status"] =!= "StaleDiagonalBlockFormsMigratedToV2",
  Exit[2]];
