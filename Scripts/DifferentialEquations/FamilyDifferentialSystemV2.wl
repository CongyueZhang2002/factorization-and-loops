(* General two-loop family differential-system construction.

   The topology and cut data come from the current CanonicalRegistry; the
   requested seed masters come from the current Kira-stream master-integral
   list.  This module
   retains the established Euler-operator/Kira closure construction while
   keeping project paths and Kira configuration outside FeynFacet`Private`.
   The default flatness check evaluates the defining curvature at bounded
   finite-field sample points. *)

BeginPackage["FeynFacetCampaign`DifferentialEquations`"];

ParseFamilyDifferentialSystemCLIArguments::usage =
  "ParseFamilyDifferentialSystemCLIArguments[args] parses the explicit V2 family differential-system command-line arguments without reading files or running Kira.";
ResolveFamilyDifferentialSystemBuildSpecification::usage =
  "ResolveFamilyDifferentialSystemBuildSpecification[spec] validates the family, variables, regulator, paths, Kira thread bound, and flatness-validation options and resolves repository-relative paths.";
ValidateFamilyDifferentialSystemFlatness::usage =
  "ValidateFamilyDifferentialSystemFlatness[{A1,A2},{x1,x2},eps,opts] validates dA1/dx2-dA2/dx1+[A1,A2]==0 by bounded probabilistic finite-field sampling by default, or by characteristic-zero symbolic identities for development.";
ConstructFamilyDifferentialSystemV2::usage =
  "ConstructFamilyDifferentialSystemV2[family,basis,{A1,A2},{x1,x2},eps,opts] validates flatness and constructs a V2 FamilyDifferentialSystem without invoking Kira.";
FamilyDifferentialSystemV2Q::usage =
  "FamilyDifferentialSystemV2Q[record] checks the V2 FamilyDifferentialSystem schema and its recorded flatness evidence.";
BuildFamilyDifferentialSystemV2::usage =
  "BuildFamilyDifferentialSystemV2[spec] reads the declared registry, Kira-stream master-integral list, and Kira configuration, performs Euler/Kira closure, validates flatness, and atomically writes one V2 FamilyDifferentialSystem plus a sibling V2 ComputationMetrics sidecar.";

Begin["`Private`"];

ClearAll[
  familyDEFailure, familyDEAbsolutePathQ, familyDEResolvePath,
  familyDESafeNameQ, familyDESymbolFromName, familyDEInteger,
  familyDEIntegerList, familyDEInputReference,
  familyDEExtractKiraFamilyConfiguration, familyDEParsePropagator,
  familyDEPrepareEulerAlgebra, familyDEScalarProduct,
  familyDEPropagatorExpression, familyDEEulerWeight,
  familyDEIntegral, familyDECutZero, familyDEEulerDerivative,
  familyDEFamilyLabel, familyDEConvertKiraIntegrals,
  familyDEWriteKiraInput, familyDERunKira,
  familyDEFiniteFieldScalar, familyDEFiniteFieldMatrix,
  familyDEFlatnessEvidenceQ,
  familyDEConstructRecord, familyDEComputationMetricsRecord,
  familyDEComputationMetricsFile, familyDECLIUsage,
  ParseFamilyDifferentialSystemCLIArguments,
  ResolveFamilyDifferentialSystemBuildSpecification,
  ValidateFamilyDifferentialSystemFlatness,
  ConstructFamilyDifferentialSystemV2,
  FamilyDifferentialSystemV2Q, BuildFamilyDifferentialSystemV2
];

familyDEFailure[status_String, extra_: <||>] :=
  Join[<|"Status" -> status|>, extra];

familyDEAbsolutePathQ[path_String] :=
  StringStartsQ[path, "/"] ||
    StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];

familyDEResolvePath[root_String, path_String] := ExpandFileName[
  If[familyDEAbsolutePathQ[path], path, FileNameJoin[{root, path}]]];

familyDESafeNameQ[name_String] :=
  StringMatchQ[name, RegularExpression["[A-Za-z][A-Za-z0-9_]*"]];
familyDESafeNameQ[_] := False;

familyDESymbolFromName[name_String] /; familyDESafeNameQ[name] :=
  Symbol["Global`" <> name];
familyDESymbolFromName[_] := $Failed;

familyDEInteger[text_String] /; StringMatchQ[text, DigitCharacter ..] :=
  FromDigits[text];
familyDEInteger[_] := $Failed;

familyDEIntegerList[text_String] := Module[{parts = StringSplit[text, ","]},
  If[parts === {} || ! AllTrue[parts, StringMatchQ[#, DigitCharacter ..] &],
    $Failed, FromDigits /@ parts]
];

familyDEInputReference[root_String, path_String, dataType_String,
    schemaVersion_Integer, family_String] := Join[
  If[StringStartsQ[path, root <> "/"],
    <|"RelativePath" -> StringDrop[path, StringLength[root] + 1]|>,
    <|"ExplicitPath" -> path|>],
  <|"DataType" -> dataType, "SchemaVersion" -> schemaVersion,
    "Family" -> family|>];

familyDECLIUsage[] := StringRiffle[{
  "wolframscript -file build_family_differential_system_v2.wls",
  "  --repository-root ROOT --family FAMILY",
  "  --canonical-registry PATH --master-integral-list PATH",
  "  --integral-families PATH --kinematics PATH",
  "  --scratch PATH --output PATH",
  "  --variables x1,x2 --regulator eps",
  "  --invariants twoP1DotP2,twoP1DotP3,twoP2DotP3",
  "  [--kira PATH] [--fermat PATH] [--kira-dimension-symbol d]",
  "  [--kira-threads 8] [--maximum-closure-iterations 5]",
  "  [--flatness-method finite-field|symbolic]",
  "  [--finite-field-primes p1,p2,...]",
  "  [--finite-field-points 3] [--finite-field-seed 20260904]",
  "  [--overwrite true|false]"
}, "\n"];

ParseFamilyDifferentialSystemCLIArguments[args_List] := Module[
  {pairs, raw, known, required, missing, unknown, variables, invariants,
   regulator, dimensionSymbol, threads, iterations, points, seed, primes,
   method, overwrite},
  If[args === {"--help"} || args === {"-h"},
    Return[<|"Status" -> "HelpRequested", "Usage" -> familyDECLIUsage[]|>]];
  If[OddQ[Length[args]],
    Return[familyDEFailure["CommandLineArgumentsInvalid",
      <|"Usage" -> familyDECLIUsage[]|>]]];
  pairs = Partition[args, 2];
  If[! AllTrue[pairs,
      Length[#] === 2 && StringStartsQ[First[#], "--"] &],
    Return[familyDEFailure["CommandLineArgumentsInvalid",
      <|"Usage" -> familyDECLIUsage[]|>]]];
  If[! DuplicateFreeQ[First /@ pairs],
    Return[familyDEFailure["CommandLineOptionRepeated"]]];
  raw = Association[(StringDrop[First[#], 2] -> Last[#]) & /@ pairs];
  known = {"repository-root", "family", "canonical-registry",
    "master-integral-list", "integral-families", "kinematics", "scratch",
    "output", "variables", "regulator", "invariants", "kira", "fermat",
    "kira-dimension-symbol", "kira-threads",
    "maximum-closure-iterations", "flatness-method",
    "finite-field-primes", "finite-field-points", "finite-field-seed",
    "overwrite"};
  unknown = Complement[Keys[raw], known];
  If[unknown =!= {},
    Return[familyDEFailure["CommandLineOptionUnknown",
      <|"UnknownOptions" -> unknown|>]]];
  required = {"repository-root", "family", "canonical-registry",
    "master-integral-list", "integral-families", "kinematics", "scratch",
    "output", "variables", "regulator", "invariants"};
  missing = Select[required, ! KeyExistsQ[raw, #] &];
  If[missing =!= {},
    Return[familyDEFailure["CommandLineOptionsMissing",
      <|"MissingOptions" -> missing, "Usage" -> familyDECLIUsage[]|>]]];
  variables = familyDESymbolFromName /@ StringSplit[raw["variables"], ","];
  regulator = familyDESymbolFromName[raw["regulator"]];
  invariants = familyDESymbolFromName /@ StringSplit[raw["invariants"], ","];
  dimensionSymbol = familyDESymbolFromName[
    Lookup[raw, "kira-dimension-symbol", "d"]];
  threads = familyDEInteger[Lookup[raw, "kira-threads", "8"]];
  iterations = familyDEInteger[
    Lookup[raw, "maximum-closure-iterations", "5"]];
  points = familyDEInteger[Lookup[raw, "finite-field-points", "3"]];
  seed = familyDEInteger[Lookup[raw, "finite-field-seed", "20260904"]];
  primes = If[KeyExistsQ[raw, "finite-field-primes"],
    familyDEIntegerList[raw["finite-field-primes"]],
    {2147483629, 2147483587, 2147483579}];
  method = Switch[Lookup[raw, "flatness-method", "finite-field"],
    "finite-field", "ProbabilisticFiniteFieldSampling",
    "symbolic", "CharacteristicZeroSymbolicIdentity",
    _, $Failed];
  overwrite = Switch[ToLowerCase[Lookup[raw, "overwrite", "false"]],
    "true", True, "false", False, _, $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[invariants, {_Symbol, _Symbol, _Symbol}] ||
      regulator === $Failed || dimensionSymbol === $Failed ||
      MemberQ[{threads, iterations, points, seed, primes, method, overwrite},
        $Failed],
    Return[familyDEFailure["CommandLineOptionValueInvalid"]]];
  <|"Status" -> "FamilyDifferentialSystemCLIArgumentsParsed",
    "RepositoryRoot" -> raw["repository-root"],
    "Family" -> raw["family"],
    "CanonicalRegistryFile" -> raw["canonical-registry"],
    "MasterIntegralListFile" -> raw["master-integral-list"],
    "IntegralFamiliesFile" -> raw["integral-families"],
    "KinematicsFile" -> raw["kinematics"],
    "ScratchDirectory" -> raw["scratch"],
    "OutputFile" -> raw["output"],
    "KiraExecutable" -> Lookup[raw, "kira",
      "Addon/Other_Addon/Kira/bin/kira"],
    "FermatExecutable" -> Lookup[raw, "fermat",
      "Addon/Other_Addon/Kira/bin/fer64"],
    "KinematicVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "KinematicInvariantSymbols" -> invariants,
    "KiraDimensionSymbol" -> dimensionSymbol,
    "KiraThreads" -> threads,
    "MaximumClosureIterations" -> iterations,
    "FlatnessValidationMethod" -> method,
    "FiniteFieldPrimes" -> primes,
    "FiniteFieldPointsPerPrime" -> points,
    "FiniteFieldSeed" -> seed,
    "OverwriteOutput" -> overwrite|>
];
ParseFamilyDifferentialSystemCLIArguments[_] :=
  familyDEFailure["CommandLineArgumentsInvalid"];

ResolveFamilyDifferentialSystemBuildSpecification[spec_Association] := Module[
  {root, family, fileKeys, resolved, missing, variables, regulator,
   invariants, dimensionSymbol, threads, iterations, method, primes, points,
   seed, scratch, output, overwrite},
  root = Lookup[spec, "RepositoryRoot", Missing[]];
  If[! StringQ[root],
    Return[familyDEFailure["RepositoryRootRequired"]]];
  root = ExpandFileName[root];
  If[! DirectoryQ[root],
    Return[familyDEFailure["RepositoryRootNotFound",
      <|"RepositoryRoot" -> root|>]]];
  family = Lookup[spec, "Family", Missing[]];
  If[! familyDESafeNameQ[family],
    Return[familyDEFailure["FamilyNameInvalid"]]];
  fileKeys = {"CanonicalRegistryFile", "MasterIntegralListFile",
    "IntegralFamiliesFile", "KinematicsFile", "KiraExecutable",
    "FermatExecutable"};
  missing = Select[fileKeys, ! StringQ[Lookup[spec, #, Missing[]]] &];
  If[missing =!= {},
    Return[familyDEFailure["InputPathsMissing", <|"Missing" -> missing|>]]];
  resolved = Association@Table[key -> familyDEResolvePath[root, spec[key]],
    {key, fileKeys}];
  missing = Select[fileKeys, ! FileExistsQ[resolved[#]] &];
  If[missing =!= {},
    Return[familyDEFailure["InputFilesNotFound", <|
      "Missing" -> Association@Table[key -> resolved[key], {key, missing}]|>]]];
  scratch = Lookup[spec, "ScratchDirectory", Missing[]];
  output = Lookup[spec, "OutputFile", Missing[]];
  If[! StringQ[scratch] || ! StringQ[output],
    Return[familyDEFailure["ScratchAndOutputPathsRequired"]]];
  scratch = familyDEResolvePath[root, scratch];
  output = familyDEResolvePath[root, output];
  If[MemberQ[{"/", root}, scratch] || output === root || output === "/",
    Return[familyDEFailure["ScratchOrOutputPathTooBroad"]]];
  variables = Lookup[spec, "KinematicVariables", Missing[]];
  regulator = Lookup[spec, "DimensionalRegulator", Missing[]];
  invariants = Lookup[spec, "KinematicInvariantSymbols", Missing[]];
  dimensionSymbol = Lookup[spec, "KiraDimensionSymbol", Global`d];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! DuplicateFreeQ[variables] || ! MatchQ[regulator, _Symbol] ||
      MemberQ[variables, regulator] ||
      ! MatchQ[invariants, {_Symbol, _Symbol, _Symbol}] ||
      ! DuplicateFreeQ[invariants] || ! MatchQ[dimensionSymbol, _Symbol] ||
      ! DuplicateFreeQ[Join[variables, {regulator}, invariants,
        {dimensionSymbol}]],
    Return[familyDEFailure["DifferentialVariablesInvalid"]]];
  threads = Lookup[spec, "KiraThreads", 8];
  iterations = Lookup[spec, "MaximumClosureIterations", 5];
  method = Lookup[spec, "FlatnessValidationMethod",
    "ProbabilisticFiniteFieldSampling"];
  primes = Lookup[spec, "FiniteFieldPrimes",
    {2147483629, 2147483587, 2147483579}];
  points = Lookup[spec, "FiniteFieldPointsPerPrime", 3];
  seed = Lookup[spec, "FiniteFieldSeed", 20260904];
  overwrite = Lookup[spec, "OverwriteOutput", False];
  If[! BooleanQ[overwrite],
    Return[familyDEFailure["OverwriteOutputOptionInvalid"]]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[familyDEFailure["KiraThreadCountInvalid",
      <|"MaximumKiraThreads" -> 8, "RequestedKiraThreads" -> threads|>]]];
  If[! IntegerQ[iterations] || iterations < 1,
    Return[familyDEFailure["MaximumClosureIterationsInvalid"]]];
  If[! MemberQ[{"ProbabilisticFiniteFieldSampling",
        "CharacteristicZeroSymbolicIdentity"}, method],
    Return[familyDEFailure["FlatnessValidationMethodInvalid"]]];
  If[! MatchQ[primes, {__Integer}] ||
      ! AllTrue[primes, PrimeQ[#] && # > 3 &] ||
      ! IntegerQ[points] || points < 1 || ! IntegerQ[seed],
    Return[familyDEFailure["FiniteFieldValidationOptionsInvalid"]]];
  Join[KeyDrop[spec, "Status"], resolved, <|
    "Status" -> "FamilyDifferentialSystemBuildSpecificationResolved",
    "RepositoryRoot" -> root, "Family" -> family,
    "ScratchDirectory" -> scratch, "OutputFile" -> output,
    "KinematicVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "KinematicInvariantSymbols" -> invariants,
    "KiraDimensionSymbol" -> dimensionSymbol,
    "KiraThreads" -> threads,
    "MaximumClosureIterations" -> iterations,
    "FlatnessValidationMethod" -> method,
    "FiniteFieldPrimes" -> primes,
    "FiniteFieldPointsPerPrime" -> points,
    "FiniteFieldSeed" -> seed, "OverwriteOutput" -> overwrite|>]
];
ResolveFamilyDifferentialSystemBuildSpecification[_] :=
  familyDEFailure["FamilyDifferentialSystemBuildSpecificationInvalid"];

familyDEExtractKiraFamilyConfiguration[text_String, family_String] := Module[
  {lines, starts, start, stop, blockLines, block, topLine, sector,
   cutLine, cuts},
  lines = StringSplit[StringReplace[text, "\r\n" -> "\n"], "\n"];
  starts = Select[Range[Length[lines]],
    StringStartsQ[StringTrim[lines[[#]]], "- name: "] &];
  start = SelectFirst[starts,
    StringTrim[lines[[#]]] === "- name: " <> family &, Missing[]];
  If[MissingQ[start],
    Return[familyDEFailure["KiraFamilyConfigurationNotFound",
      <|"Family" -> family|>]]];
  stop = SelectFirst[starts, # > start &, Length[lines] + 1];
  blockLines = lines[[start ;; stop - 1]];
  block = StringRiffle[blockLines, "\n"];
  topLine = SelectFirst[blockLines,
    StringContainsQ[#, "top_level_sectors:"] &, Missing[]];
  sector = If[MissingQ[topLine], {},
    StringCases[topLine,
      "b" ~~ bits : (("0" | "1") ..) :> "b" <> bits]];
  cutLine = SelectFirst[blockLines,
    StringContainsQ[#, "cut_propagators:"] &, Missing[]];
  cuts = If[MissingQ[cutLine], {},
    FromDigits /@ StringCases[cutLine, DigitCharacter ..]];
  If[Length[sector] =!= 1,
    Return[familyDEFailure["KiraFamilyConfigurationIncomplete"]]];
  <|"Status" -> "KiraFamilyConfigurationSelected",
    "FamilyBlock" -> block, "TopLevelSector" -> First[sector],
    "CutIndices" -> Sort[cuts]|>
];
familyDEExtractKiraFamilyConfiguration[___] :=
  familyDEFailure["KiraFamilyConfigurationInvalid"];

familyDEParsePropagator[
    FeynCalc`FeynAmpDenominator[
      FeynCalc`StandardPropagatorDenominator[
        FeynCalc`Momentum[m_, ___], 0, 0, _]]] := {"Quadratic", m};
familyDEParsePropagator[
    FeynCalc`FeynAmpDenominator[
      FeynCalc`StandardPropagatorDenominator[
        0, FeynCalc`Pair[FeynCalc`Momentum[a_, ___],
          FeynCalc`Momentum[b_, ___]], 0, _]]] := {"Bilinear", a, b};
familyDEParsePropagator[other_] := Missing["UnsupportedPropagator", other];

familyDEPrepareEulerAlgebra[topology_, invariants_List,
    cutPositions_List] := Module[
  {propagators, loopMomenta, externalMomenta, momentumBasis, pairs,
   unknowns, scalarProducts, propagatorSymbols, expressions, solution,
   p1, p2, p3},
  If[Length[topology] < 4,
    Return[familyDEFailure["CanonicalTopologyInvalid"]]];
  propagators = familyDEParsePropagator /@ topology[[2]];
  loopMomenta = topology[[3]];
  externalMomenta = topology[[4]];
  If[! MatchQ[loopMomenta, {_, _}] ||
      ! MatchQ[externalMomenta, {_, _, _}] ||
      Length[invariants] =!= 3 || ! FreeQ[propagators, _Missing],
    Return[familyDEFailure["TwoLoopThreeExternalMomentumTopologyRequired",
      <|"LoopMomenta" -> loopMomenta,
        "ExternalMomenta" -> externalMomenta|>]]];
  If[! AllTrue[cutPositions, IntegerQ[#] && 1 <= # <= Length[propagators] &],
    Return[familyDEFailure["CutIndicesInvalid"]]];
  momentumBasis = Join[loopMomenta, externalMomenta];
  pairs = Join[{{loopMomenta[[1]], loopMomenta[[1]]},
      {loopMomenta[[2]], loopMomenta[[2]]},
      {loopMomenta[[1]], loopMomenta[[2]]}},
    Flatten[Table[{loop, external}, {loop, loopMomenta},
      {external, externalMomenta}], 1]];
  If[Length[propagators] =!= Length[pairs],
    Return[familyDEFailure["TopologyDoesNotSpanLoopScalarProducts",
      <|"PropagatorCount" -> Length[propagators],
        "LoopScalarProductCount" -> Length[pairs]|>]]];
  unknowns = Table[Unique["loopScalarProduct$"], {Length[pairs]}];
  scalarProducts = AssociationThread[Sort /@ pairs, unknowns];
  {p1, p2, p3} = externalMomenta;
  AssociateTo[scalarProducts, <|
    Sort[{p1, p1}] -> 0, Sort[{p2, p2}] -> 0,
    Sort[{p3, p3}] -> 0,
    Sort[{p1, p2}] -> invariants[[1]]/2,
    Sort[{p1, p3}] -> invariants[[2]]/2,
    Sort[{p2, p3}] -> invariants[[3]]/2|>];
  propagatorSymbols = Table[Unique["propagator$"], {Length[propagators]}];
  expressions = familyDEPropagatorExpression[#, momentumBasis,
      scalarProducts] & /@ propagators;
  If[! FreeQ[expressions, _Missing],
    Return[familyDEFailure["ScalarProductRepresentationIncomplete"]]];
  solution = Quiet@Check[
    Solve[Thread[propagatorSymbols == expressions], unknowns], $Failed];
  If[! MatchQ[solution, {_List}],
    Return[familyDEFailure["PropagatorsDoNotDetermineLoopScalarProducts"]]];
  <|"Status" -> "EulerScalarProductAlgebraPrepared",
    "Propagators" -> propagators,
    "PropagatorSymbols" -> propagatorSymbols,
    "ScalarProductSolution" -> First[solution],
    "ScalarProducts" -> scalarProducts,
    "MomentumBasis" -> momentumBasis,
    "LoopMomenta" -> loopMomenta,
    "ExternalMomenta" -> externalMomenta|>
];

familyDEScalarProduct[m1_, m2_, momentumBasis_List,
    scalarProducts_Association] := Module[
  {v1 = Coefficient[m1, #] & /@ momentumBasis,
   v2 = Coefficient[m2, #] & /@ momentumBasis, value},
  Sum[
    value = Lookup[scalarProducts,
      Key[Sort[{momentumBasis[[i]], momentumBasis[[j]]}]],
      Missing["ScalarProduct"]];
    v1[[i]] v2[[j]] value,
    {i, Length[momentumBasis]}, {j, Length[momentumBasis]}]
];

familyDEPropagatorExpression[{"Quadratic", momentum_}, basis_, products_] :=
  Expand[familyDEScalarProduct[momentum, momentum, basis, products]];
familyDEPropagatorExpression[{"Bilinear", a_, b_}, basis_, products_] :=
  Expand[familyDEScalarProduct[a, b, basis, products]];
familyDEPropagatorExpression[___] := Missing["UnsupportedPropagator"];

familyDEEulerWeight[direction_, {"Quadratic", momentum_}, basis_, products_] :=
  2 Coefficient[momentum, direction] *
    familyDEScalarProduct[direction, momentum, basis, products];
familyDEEulerWeight[direction_, {"Bilinear", a_, b_}, basis_, products_] :=
  Coefficient[a, direction] familyDEScalarProduct[direction, b, basis, products] +
    Coefficient[b, direction] familyDEScalarProduct[direction, a, basis, products];

familyDECutZero[expression_, {}] := expression;
familyDECutZero[expression_, cutPositions_List] := expression /.
  HoldPattern[integral : familyDEIntegral[_, indices_List]] /;
      Min[indices[[cutPositions]]] <= 0 :> 0;

familyDEEulerDerivative[direction_, familyDEIntegral[family_, indices_List],
    preparation_Association, cutPositions_List] := Module[
  {propagators = preparation["Propagators"],
   propagatorSymbols = preparation["PropagatorSymbols"],
   solution = preparation["ScalarProductSolution"],
   basis = preparation["MomentumBasis"],
   products = preparation["ScalarProducts"], raw, weight, raised},
  Sum[
    raw = familyDEEulerWeight[direction, propagators[[j]], basis, products];
    If[raw === 0 || indices[[j]] === 0, 0,
      weight = Expand[-indices[[j]] raw /. solution];
      raised = ReplacePart[indices, j -> indices[[j]] + 1];
      familyDECutZero[Expand[
        (weight /. Thread[propagatorSymbols -> 0])
          familyDEIntegral[family, raised] +
        Sum[Coefficient[weight, propagatorSymbols[[k]]]
          familyDEIntegral[family,
            ReplacePart[raised, k -> raised[[k]] - 1]],
          {k, Length[propagators]}]], cutPositions]],
    {j, Length[propagators]}]
];

familyDEFamilyLabel[integral_] := Quiet@Check[
  If[Head[integral[[1]]] === Symbol, SymbolName[integral[[1]]],
    ToString[integral[[1]], InputForm]], $Failed];

familyDEConvertKiraIntegrals[expression_, family_String] := expression /.
  HoldPattern[head_Symbol[indices__Integer]] /;
      SymbolName[Unevaluated[head]] === family :>
    familyDEIntegral[family, {indices}];

familyDEWriteKiraInput[targetList_List, family_String,
    configuration_Association, workspace_String] := Module[
  {maxR, maxS, targetText, jobsText},
  If[targetList === {}, Return[familyDEFailure["KiraTargetListEmpty"]]];
  CreateDirectory[FileNameJoin[{workspace, "config"}],
    CreateIntermediateDirectories -> True];
  Export[FileNameJoin[{workspace, "config", "integralfamilies.yaml"}],
    "integralfamilies:\n" <> configuration["FamilyBlock"] <> "\n", "String"];
  CopyFile[configuration["KinematicsFile"],
    FileNameJoin[{workspace, "config", "kinematics.yaml"}]];
  targetText = StringRiffle[
      (family <> "[" <> StringRiffle[ToString /@ #[[2]], ","] <> "]") & /@
        Sort[targetList], "\n"] <> "\n";
  Export[FileNameJoin[{workspace, "integrals_1"}], targetText, "String"];
  maxR = Max[Total[Select[#[[2]], # > 0 &]] & /@ targetList];
  maxS = Max[0, Max[-Total[Select[#[[2]], # < 0 &]] & /@ targetList]];
  jobsText = StringRiffle[{
    "jobs:", "  - reduce_sectors:", "      reduce:",
    "        - {topologies: [" <> family <> "], sectors: [" <>
      configuration["TopLevelSector"] <> "], r: " <> ToString[maxR + 1] <>
      ", s: " <> ToString[maxS + 1] <> " }",
    "      select_integrals:", "        select_mandatory_list:",
    "          - [" <> family <> ", \"integrals_1\"]",
    "      run_initiate: true", "      run_triangular: true",
    "      run_back_substitution: true", "      integral_ordering: 2",
    "  - kira2math:", "      target:",
    "        - [" <> family <> ", \"integrals_1\"]"}, "\n"] <> "\n";
  Export[FileNameJoin[{workspace, "jobs.yaml"}], jobsText, "String"];
  <|"Status" -> "KiraInputWritten", "MaximumPositiveIndexSum" -> maxR + 1,
    "MaximumNegativeIndexSum" -> maxS + 1|>
];

familyDERunKira[targetList_List, family_String, configuration_Association,
    specification_Association, workspaceRoot_String,
    iteration_Integer] := Module[
  {workspace, input, run, files, rawRules, rules, seconds},
  workspace = FileNameJoin[{workspaceRoot,
    "closure_" <> IntegerString[iteration, 10, 2]}];
  If[FileExistsQ[workspace],
    Return[familyDEFailure["KiraWorkspaceAlreadyExists",
      <|"Workspace" -> workspace|>]]];
  input = familyDEWriteKiraInput[targetList, family,
    Join[configuration,
      <|"KinematicsFile" -> specification["KinematicsFile"]|>], workspace];
  If[Lookup[input, "Status", None] =!= "KiraInputWritten", Return[input]];
  {seconds, run} = AbsoluteTiming[RunProcess[
    {specification["KiraExecutable"],
      "--parallel=" <> ToString[specification["KiraThreads"]],
      "jobs.yaml"}, All, ProcessDirectory -> workspace,
    ProcessEnvironment -> <|"FERMATPATH" ->
      specification["FermatExecutable"]|>]];
  Export[FileNameJoin[{workspace, "kira.log"}],
    Lookup[run, "StandardOutput", ""] <> Lookup[run, "StandardError", ""],
    "String"];
  If[Lookup[run, "ExitCode", 1] =!= 0,
    Return[familyDEFailure["KiraReductionFailed",
      <|"ExitCode" -> Lookup[run, "ExitCode", Missing[]],
        "Seconds" -> N[seconds], "Workspace" -> workspace|>]]];
  files = FileNames["kira_integrals_*.m",
    FileNameJoin[{workspace, "results"}], 2];
  If[files === {},
    Return[familyDEFailure["KiraRulesMissing",
      <|"Workspace" -> workspace|>]]];
  rawRules = Quiet@Check[Flatten[Get /@ files], $Failed];
  If[! ListQ[rawRules],
    Return[familyDEFailure["KiraRulesUnreadable"]]];
  rules = familyDEConvertKiraIntegrals[rawRules, family];
  <|"Status" -> "KiraReductionRulesRead", "Rules" -> rules,
    "RuleCount" -> Length[rules], "TargetCount" -> Length[targetList],
    "MaximumPositiveIndexSum" -> input["MaximumPositiveIndexSum"],
    "MaximumNegativeIndexSum" -> input["MaximumNegativeIndexSum"],
    "Seconds" -> N[seconds]|>
];

familyDEFiniteFieldScalar[expression_, rules_List, prime_Integer] := Module[
  {value, numerator, denominator, inverse},
  (* Substitution comes first.  Exact numeric arithmetic then produces one
     Rational without constructing a symbolic common denominator. *)
  value = Quiet@Check[expression /. rules, $Failed];
  If[value === $Failed || ! RationalQ[value], Return[$Failed]];
  numerator = Numerator[value]; denominator = Denominator[value];
  If[Mod[denominator, prime] === 0, Return[$Failed]];
  inverse = Quiet@Check[PowerMod[Mod[denominator, prime], -1, prime], $Failed];
  If[inverse === $Failed, $Failed, Mod[numerator inverse, prime]]
];

familyDEFiniteFieldMatrix[matrix_List, rules_List, prime_Integer] := Module[
  {value = Map[familyDEFiniteFieldScalar[#, rules, prime] &, matrix, {2}]},
  If[FreeQ[value, $Failed], value, $Failed]
];

Options[ValidateFamilyDifferentialSystemFlatness] = {
  "Method" -> "ProbabilisticFiniteFieldSampling",
  "FiniteFieldPrimes" -> {2147483629, 2147483587, 2147483579},
  "PointsPerPrime" -> 3, "Seed" -> 20260904,
  "MaximumAttemptsPerPrime" -> 30
};

ValidateFamilyDifferentialSystemFlatness[connectionMatrices : {_, _},
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    OptionsPattern[]] := Module[
  {method = OptionValue["Method"], primes = OptionValue["FiniteFieldPrimes"],
   points = OptionValue["PointsPerPrime"], seed = OptionValue["Seed"],
   maximumAttempts = OptionValue["MaximumAttemptsPerPrime"], a1, a2,
   dimension, derivative12, derivative21, residuals, failures, samples = {},
   attempts, accepted, point, rules, values, curvature, nonzero},
  {a1, a2} = Normal /@ connectionMatrices;
  dimension = If[MatrixQ[a1], Length[a1], 0];
  If[dimension < 1 || ! MatrixQ[a2] ||
      Dimensions[a1] =!= {dimension, dimension} ||
      Dimensions[a2] =!= {dimension, dimension} ||
      variables[[1]] === variables[[2]] || MemberQ[variables, regulator],
    Return[familyDEFailure["ConnectionMatricesInvalid"]]];
  If[method === "CharacteristicZeroSymbolicIdentity",
    residuals = Table[Together[
      D[a1[[i, j]], variables[[2]]] -
      D[a2[[i, j]], variables[[1]]] +
      Sum[a1[[i, k]] a2[[k, j]] - a2[[i, k]] a1[[k, j]],
        {k, dimension}]], {i, dimension}, {j, dimension}];
    failures = Position[residuals, value_ /; value =!= 0, {2},
      Heads -> False];
    Return[<|"Status" -> If[failures === {},
        "ConnectionFlatnessValidated", "ConnectionFlatnessValidationFailed"],
      "Accepted" -> (failures === {}),
      "Method" -> "CharacteristicZeroSymbolicIdentity",
      "Exact" -> True, "Probabilistic" -> False,
      "CheckedEntries" -> dimension^2,
      "NonzeroEntryPositions" -> Take[failures, UpTo[20]]|>]];
  If[method =!= "ProbabilisticFiniteFieldSampling" ||
      ! MatchQ[primes, {__Integer}] ||
      ! AllTrue[primes, PrimeQ[#] && # > 3 &] ||
      ! IntegerQ[points] || points < 1 || ! IntegerQ[seed] ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < points,
    Return[familyDEFailure["FiniteFieldValidationOptionsInvalid"]]];
  derivative12 = Map[D[#, variables[[2]]] &, a1, {2}];
  derivative21 = Map[D[#, variables[[1]]] &, a2, {2}];
  BlockRandom[SeedRandom[seed];
    Do[
      attempts = 0; accepted = 0;
      While[accepted < points && attempts < maximumAttempts,
        attempts++;
        point = RandomInteger[{2, prime - 2}, 3];
        rules = Thread[Append[variables, regulator] -> point];
        values = familyDEFiniteFieldMatrix[#, rules, prime] & /@
          {a1, a2, derivative12, derivative21};
        If[MemberQ[values, $Failed], Continue[]];
        curvature = Mod[values[[3]] - values[[4]] +
          values[[1]].values[[2]] - values[[2]].values[[1]], prime];
        nonzero = Position[curvature, value_ /; value =!= 0, {2},
          Heads -> False];
        AppendTo[samples, <|"Prime" -> prime,
          "KinematicPoint" -> Thread[variables -> point[[1 ;; 2]]],
          "DimensionalRegulatorValue" -> (regulator -> point[[3]]),
          "CurvatureZero" -> (nonzero === {})|>];
        If[nonzero =!= {},
          Return[<|"Status" -> "ConnectionFlatnessValidationFailed",
            "Accepted" -> False,
            "Method" -> "ProbabilisticFiniteFieldSampling",
            "Exact" -> False, "Probabilistic" -> True,
            "FailureSample" -> Last[samples],
            "NonzeroEntryPositions" -> Take[nonzero, UpTo[20]],
            "Samples" -> samples|>, Module]];
        accepted++];
      If[accepted < points,
        Return[familyDEFailure["FiniteFieldSamplePointsInsufficient",
          <|"Prime" -> prime, "AcceptedPoints" -> accepted,
            "RequiredPoints" -> points, "Attempts" -> attempts|>], Module]],
      {prime, primes}]];
  <|"Status" -> "ConnectionFlatnessValidated", "Accepted" -> True,
    "Method" -> "ProbabilisticFiniteFieldSampling",
    "Exact" -> False, "Probabilistic" -> True,
    "CheckedEntriesPerSample" -> dimension^2,
    "Primes" -> primes, "PointsPerPrime" -> points,
    "Seed" -> seed, "Samples" -> samples|>
];
ValidateFamilyDifferentialSystemFlatness[___] :=
  familyDEFailure["ConnectionFlatnessInputsInvalid"];

familyDEFlatnessEvidenceQ[evidence_Association] :=
  Lookup[evidence, "Status", None] === "ConnectionFlatnessValidated" &&
    TrueQ[Lookup[evidence, "Accepted", False]] &&
    Switch[Lookup[evidence, "Method", None],
      "CharacteristicZeroSymbolicIdentity",
        TrueQ[Lookup[evidence, "Exact", False]] &&
          ! TrueQ[Lookup[evidence, "Probabilistic", True]],
      "ProbabilisticFiniteFieldSampling",
        ! TrueQ[Lookup[evidence, "Exact", True]] &&
          TrueQ[Lookup[evidence, "Probabilistic", False]] &&
          MatchQ[Lookup[evidence, "Samples", Missing[]], {__Association}] &&
          AllTrue[evidence["Samples"], TrueQ[Lookup[#, "CurvatureZero", False]] &],
      _, False];
familyDEFlatnessEvidenceQ[_] := False;

familyDEConstructRecord[family_String, basis_List, connectionMatrices_List,
    variables_List, regulator_Symbol, validation_Association,
    inputReferences_Association, kinematicData_Association,
    cutIndices_List] := <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Status" -> "FamilyDifferentialSystemValidated", "Family" -> family,
  "KinematicVariables" -> variables,
  "DimensionalRegulator" -> regulator,
  "OriginalMasterIntegralBasis" -> basis,
  "ConnectionMatrices" -> connectionMatrices,
  "KinematicVariableDefinition" -> kinematicData,
  "CutIndices" -> cutIndices,
  "MathematicalInputReferences" -> inputReferences,
  "Validation" -> <|"ConnectionFlatness" -> validation|>|>;

familyDEComputationMetricsRecord[family_String,
    phaseTimings_Association, constructionCounts_Association,
    backendRuns_List, nativeThreadCount_Integer] := <|
  "DataType" -> "ComputationMetrics", "SchemaVersion" -> 2,
  "MathematicalStage" -> "FamilyDifferentialSystemConstruction",
  "Family" -> family,
  "WallTimeSeconds" -> Lookup[phaseTimings, "TotalSeconds", 0.],
  "PeakMemoryBytes" -> MaxMemoryUsed[],
  "Backend" -> "Kira", "NativeThreadCount" -> nativeThreadCount,
  "PhaseTimings" -> phaseTimings,
  "ConstructionCounts" -> constructionCounts,
  "BackendRuns" -> backendRuns|>;

familyDEComputationMetricsFile[outputFile_String] := FileNameJoin[{
  DirectoryName[outputFile],
  FileBaseName[outputFile] <> ".computation-metrics.wl"}];

Options[ConstructFamilyDifferentialSystemV2] =
  Join[Options[ValidateFamilyDifferentialSystemFlatness], {
    "MathematicalInputReferences" -> <||>,
    "KinematicVariableDefinition" -> <||>, "CutIndices" -> {}}];

ConstructFamilyDifferentialSystemV2[family_String, basis_List,
    matrices : {_, _}, variables : {_Symbol, _Symbol}, regulator_Symbol,
    opts : OptionsPattern[]] := Module[{validation},
  validation = ValidateFamilyDifferentialSystemFlatness[matrices, variables,
    regulator, Sequence @@ FilterRules[{opts},
      Options[ValidateFamilyDifferentialSystemFlatness]]];
  If[! familyDEFlatnessEvidenceQ[validation], Return[validation]];
  familyDEConstructRecord[family, basis, Normal /@ matrices, variables,
    regulator, validation,
    OptionValue["MathematicalInputReferences"],
    OptionValue["KinematicVariableDefinition"],
    OptionValue["CutIndices"]]
];
ConstructFamilyDifferentialSystemV2[___] :=
  familyDEFailure["FamilyDifferentialSystemInputsInvalid"];

FamilyDifferentialSystemV2Q[record_Association] := Module[
  {variables, regulator, basis, matrices, dimension, validation},
  variables = Lookup[record, "KinematicVariables", Missing[]];
  regulator = Lookup[record, "DimensionalRegulator", Missing[]];
  basis = Lookup[record, "OriginalMasterIntegralBasis", Missing[]];
  matrices = Lookup[record, "ConnectionMatrices", Missing[]];
  dimension = If[ListQ[basis], Length[basis], 0];
  validation = Lookup[Lookup[record, "Validation", <||>],
    "ConnectionFlatness", Missing[]];
  Lookup[record, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[record, "SchemaVersion", None] === 2 &&
    Lookup[record, "Status", None] === "FamilyDifferentialSystemValidated" &&
    StringQ[Lookup[record, "Family", None]] &&
    MatchQ[variables, {_Symbol, _Symbol}] && DuplicateFreeQ[variables] &&
    MatchQ[regulator, _Symbol] && ! MemberQ[variables, regulator] &&
    dimension > 0 && MatchQ[matrices, {_?MatrixQ, _?MatrixQ}] &&
    AllTrue[matrices, Dimensions[#] === {dimension, dimension} &] &&
    familyDEFlatnessEvidenceQ[validation]
];
FamilyDifferentialSystemV2Q[_] := False;

BuildFamilyDifferentialSystemV2[spec_Association] := Catch@Module[
  {totalStart = AbsoluteTime[], resolved, family, root, registry,
   masterIntegralList,
   registryData, families, familyRecord, topology, cutIndices, allMasters,
   familyMasters, masterHead, familyLabel, seedBasis, blockBasis,
   preparation, invariants, variables, regulator, dimensionSymbol,
   configurationText, configuration, workspaceRoot, derivatives,
   computeDerivatives, iteration = 0, closed = False, needed, kiraResult,
   kiraRules = {}, dispatch, reduceRaw, appearing, newMembers,
   maximumIterations, runMetrics = {}, matrices, matrixFor, unresolved,
   reduced, substitution, validation, outputBasis, inputReferences,
   kinematicData, phaseTimings = <||>, constructionCounts, record,
   computationMetrics, computationMetricsFile, existingOutputs,
   seconds, value, outputFile, overwrite},
  resolved = ResolveFamilyDifferentialSystemBuildSpecification[spec];
  If[Lookup[resolved, "Status", None] =!=
      "FamilyDifferentialSystemBuildSpecificationResolved", Throw[resolved]];
  family = resolved["Family"]; root = resolved["RepositoryRoot"];
  variables = resolved["KinematicVariables"];
  regulator = resolved["DimensionalRegulator"];
  invariants = resolved["KinematicInvariantSymbols"];
  dimensionSymbol = resolved["KiraDimensionSymbol"];
  outputFile = resolved["OutputFile"];
  computationMetricsFile = familyDEComputationMetricsFile[outputFile];
  overwrite = resolved["OverwriteOutput"];
  existingOutputs = Select[{outputFile, computationMetricsFile}, FileExistsQ];
  If[existingOutputs =!= {} && ! overwrite,
    Throw[familyDEFailure["OutputFilesAlreadyExist",
      <|"ExistingOutputFiles" -> existingOutputs|>]]];
  {seconds, value} = AbsoluteTiming[
    registry = FeynFacet`Private`coefficientReadRecord[
      resolved["CanonicalRegistryFile"]];
    masterIntegralList = FeynFacet`FamilyArtifactRead[
      resolved["MasterIntegralListFile"]]];
  phaseTimings["InputReadSeconds"] = N[seconds];
  If[! AssociationQ[registry] || ! AssociationQ[masterIntegralList],
    Throw[familyDEFailure["MathematicalInputsUnreadable"]]];
  registryData = Lookup[registry, "Registry", Missing[]];
  families = If[AssociationQ[registryData],
    Lookup[registryData, "Families", Missing[]], Missing[]];
  If[Lookup[registry, "Type", None] =!=
        "FeynFacetCanonicalFamilyRegistryRecord" ||
      Lookup[registry, "Version", None] =!= 1 ||
      Lookup[registryData, "Type", None] =!=
        "FeynFacetCanonicalFamilyRegistry" ||
      Lookup[registryData, "Version", None] =!= 1 ||
      Lookup[masterIntegralList, "Format", None] =!=
        "FeynFacet-KiraStream" ||
      Lookup[masterIntegralList, "FormatVersion", None] =!= 1 ||
      ! ListQ[families] ||
      ! ListQ[Lookup[masterIntegralList, "Masters", Missing[]]],
    Throw[familyDEFailure[
      "CurrentRegistryOrMasterIntegralListRequired"]]];
  familyRecord = SelectFirst[families,
    ToString[Lookup[#, "Name", ""]] === family &, Missing[]];
  If[MissingQ[familyRecord],
    Throw[familyDEFailure["FamilyNotFoundInCanonicalRegistry",
      <|"Family" -> family|>]]];
  topology = Lookup[familyRecord, "Topology", Missing[]];
  cutIndices = Sort[Lookup[familyRecord, "CutIndices", {}]];
  allMasters = masterIntegralList["Masters"];
  familyMasters = Select[allMasters, familyDEFamilyLabel[#] === family &];
  If[familyMasters === {},
    Throw[familyDEFailure["FamilyHasNoMasterIntegralListEntries",
      <|"Family" -> family|>]]];
  masterHead = Head[First[familyMasters]];
  familyLabel = First[First[familyMasters]];
  seedBasis = familyDEIntegral[family, #[[2]]] & /@ familyMasters;
  configurationText = Import[resolved["IntegralFamiliesFile"], "Text"];
  configuration = familyDEExtractKiraFamilyConfiguration[
    configurationText, family];
  If[Lookup[configuration, "Status", None] =!=
      "KiraFamilyConfigurationSelected", Throw[configuration]];
  If[configuration["CutIndices"] =!= cutIndices,
    Throw[familyDEFailure["RegistryAndKiraCutIndicesDisagree", <|
      "RegistryCutIndices" -> cutIndices,
      "KiraCutIndices" -> configuration["CutIndices"]|>]]];
  {seconds, preparation} = AbsoluteTiming[
    familyDEPrepareEulerAlgebra[topology, invariants, cutIndices]];
  phaseTimings["EulerPreparationSeconds"] = N[seconds];
  If[Lookup[preparation, "Status", None] =!=
      "EulerScalarProductAlgebraPrepared", Throw[preparation]];
  computeDerivatives[integral_] := Module[{operators},
    operators = familyDEEulerDerivative[#, integral, preparation,
        cutIndices] & /@ preparation["ExternalMomenta"];
    <|1 -> Together[(operators[[1]] - operators[[2]] + operators[[3]])/
        (2 invariants[[2]])],
      2 -> Together[(-operators[[1]] + operators[[2]] + operators[[3]])/
        (2 invariants[[3]])]|>];
  derivatives = Association@Table[integral -> computeDerivatives[integral],
    {integral, seedBasis}];
  blockBasis = seedBasis;
  maximumIterations = resolved["MaximumClosureIterations"];
  workspaceRoot = FileNameJoin[{resolved["ScratchDirectory"],
    "family_differential_system_" <> family}];
  If[FileExistsQ[workspaceRoot],
    Throw[familyDEFailure["KiraWorkspaceAlreadyExists",
      <|"Workspace" -> workspaceRoot|>]]];
  CreateDirectory[workspaceRoot, CreateIntermediateDirectories -> True];
  {seconds, value} = AbsoluteTiming[
    While[iteration < maximumIterations,
      iteration++;
      needed = DeleteDuplicates@Join[blockBasis,
        Cases[Values[derivatives], _familyDEIntegral, {0, Infinity}]];
      kiraResult = familyDERunKira[needed, family, configuration, resolved,
        workspaceRoot, iteration];
      If[Lookup[kiraResult, "Status", None] =!= "KiraReductionRulesRead",
        Throw[kiraResult]];
      AppendTo[runMetrics, KeyDrop[kiraResult, "Rules"]];
      kiraRules = kiraResult["Rules"];
      dispatch = Dispatch[kiraRules];
      reduceRaw[expression_] :=
        familyDECutZero[expression, cutIndices] //. dispatch;
      appearing = DeleteDuplicates@Cases[
        reduceRaw /@ needed, _familyDEIntegral, {0, Infinity}];
      newMembers = Complement[appearing, blockBasis];
      If[newMembers === {}, closed = True; Break[]];
      blockBasis = Join[blockBasis, newMembers];
      Scan[(derivatives[#] = computeDerivatives[#]) &, newMembers]]];
  phaseTimings["KiraClosureSeconds"] = N[seconds];
  If[! closed,
    Throw[familyDEFailure["KiraClosureDidNotConverge", <|
      "MaximumClosureIterations" -> maximumIterations,
      "BasisDimension" -> Length[blockBasis]|>]]];
  dispatch = Dispatch[kiraRules];
  reduceRaw[expression_] :=
    familyDECutZero[expression, cutIndices] //. dispatch;
  matrixFor[direction_Integer] := Table[
    reduced = Collect[reduceRaw[derivatives[blockBasis[[i]]][direction]],
      _familyDEIntegral, Together];
    unresolved = Complement[
      DeleteDuplicates@Cases[reduced, _familyDEIntegral, {0, Infinity}],
      blockBasis];
    If[unresolved =!= {},
      Throw[familyDEFailure["ReducedDerivativeOutsideClosedBasis", <|
        "Direction" -> direction,
        "UnresolvedIntegrals" -> Take[unresolved, UpTo[20]]|>]]];
    Table[Together[Coefficient[reduced, blockBasis[[j]]]],
      {j, Length[blockBasis]}], {i, Length[blockBasis]}];
  {seconds, matrices} = AbsoluteTiming[{matrixFor[1], matrixFor[2]}];
  phaseTimings["ConnectionAssemblySeconds"] = N[seconds];
  substitution = {invariants[[1]] -> 1,
    invariants[[2]] -> variables[[1]],
    invariants[[3]] -> variables[[2]],
    dimensionSymbol -> 4 - 2 regulator};
  matrices = Map[Together[# /. substitution] &, matrices, {3}];
  {seconds, validation} = AbsoluteTiming[
    ValidateFamilyDifferentialSystemFlatness[matrices, variables, regulator,
      "Method" -> resolved["FlatnessValidationMethod"],
      "FiniteFieldPrimes" -> resolved["FiniteFieldPrimes"],
      "PointsPerPrime" -> resolved["FiniteFieldPointsPerPrime"],
      "Seed" -> resolved["FiniteFieldSeed"]]];
  phaseTimings["FlatnessValidationSeconds"] = N[seconds];
  If[! familyDEFlatnessEvidenceQ[validation], Throw[validation]];
  outputBasis = blockBasis /.
    familyDEIntegral[_, indices_List] :> masterHead[familyLabel, indices];
  inputReferences = <|
    "CanonicalRegistry" -> familyDEInputReference[root,
      resolved["CanonicalRegistryFile"],
      "FeynFacetCanonicalFamilyRegistryRecord", 1, family],
    "MasterIntegralList" -> familyDEInputReference[root,
      resolved["MasterIntegralListFile"], "FeynFacet-KiraStream", 1,
      family],
    "IntegralFamiliesConfiguration" -> familyDEInputReference[root,
      resolved["IntegralFamiliesFile"],
      "KiraIntegralFamiliesConfiguration", 1, family],
    "KinematicsConfiguration" -> familyDEInputReference[root,
      resolved["KinematicsFile"], "KiraKinematicsConfiguration", 1,
      family]|>;
  kinematicData = <|
    "SourceInvariantSymbols" -> invariants,
    "ScaleNormalization" -> (invariants[[1]] -> 1),
    "KinematicVariableRules" -> Thread[invariants[[2 ;; 3]] -> variables],
    "DimensionRule" -> (dimensionSymbol -> 4 - 2 regulator)|>;
  constructionCounts = <|
    "EulerOperatorCount" -> 3,
    "SeedMasterIntegralCount" -> Length[seedBasis],
    "ClosedMasterIntegralCount" -> Length[blockBasis],
    "KiraClosureIterations" -> iteration|>;
  record = familyDEConstructRecord[family, outputBasis, matrices, variables,
    regulator, validation, inputReferences, kinematicData, cutIndices];
  If[! FamilyDifferentialSystemV2Q[record],
    Throw[familyDEFailure["ConstructedFamilyDifferentialSystemInvalid"]]];
  If[! DirectoryQ[DirectoryName[outputFile]],
    CreateDirectory[DirectoryName[outputFile],
      CreateIntermediateDirectories -> True]];
  {seconds, value} = AbsoluteTiming[
    FeynFacet`FamilyArtifactWrite[record, outputFile]];
  phaseTimings["MathematicalResultWriteSeconds"] = N[seconds];
  If[value =!= outputFile,
    Throw[familyDEFailure["FamilyDifferentialSystemWriteFailed"]]];
  phaseTimings["TotalSeconds"] = N[AbsoluteTime[] - totalStart];
  computationMetrics = familyDEComputationMetricsRecord[family,
    phaseTimings, constructionCounts, runMetrics, resolved["KiraThreads"]];
  value = FeynFacet`FamilyArtifactWrite[computationMetrics,
    computationMetricsFile];
  If[value =!= computationMetricsFile,
    Throw[familyDEFailure["ComputationMetricsWriteFailed"]]];
  <|"Status" -> "FamilyDifferentialSystemBuildCompleted",
    "FamilyDifferentialSystem" -> record,
    "ComputationMetrics" -> computationMetrics,
    "FamilyDifferentialSystemFile" -> outputFile,
    "ComputationMetricsFile" -> computationMetricsFile|>
];
BuildFamilyDifferentialSystemV2[_] :=
  familyDEFailure["FamilyDifferentialSystemBuildSpecificationInvalid"];

End[];
EndPackage[];
