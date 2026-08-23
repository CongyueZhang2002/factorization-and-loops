#!/usr/bin/env wolframscript

$HistoryLength = 0;

root = "/home/maxzhang/factorization-and-loops";
artifactDirectory = FileNameJoin[{root, "Codex", "TwoRootMapleAugmented"}];
recordPath = FileNameJoin[{
  "/home/maxzhang/FACET/Codex/General/CF254Standardized_20260819",
  "sector_CF254_standard", "CF254_9_8_unsolved.wl"
}];
epsFormStripPath = FileNameJoin[{root, "FeynFacet", "Private", "EpsFormStrip.wl"}];
mapleLibrary = FileNameJoin[{
  root, "Addon", "Other_Addon", "Maple", "IntegrableConnections"
}];

zeroQ[expr_] := AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

toMaple[expr_] := StringReplace[
  ToString[expr, InputForm],
  {
    RegularExpression["(?:[A-Za-z$][A-Za-z0-9$]*`)+"] -> "",
    " " -> "",
    "\n" -> "",
    "\r" -> ""
  }
];

mapleMatrix[name_String, matrix_List] := StringJoin[
  name, " := matrix(", ToString[Length[matrix]], ",",
  ToString[Length[First[matrix]]], ",[",
  StringRiffle[toMaple /@ Flatten[matrix], ","], "]):\n"
];

mapleProgram[connection_List, variables_List, tag_String] := Module[
  {ledger, resultFile, firstName, secondName},
  ledger = FileNameJoin[{artifactDirectory, "05_cf254_" <> tag <> ".ledger.log"}];
  resultFile = FileNameJoin[{artifactDirectory, "05_cf254_" <> tag <> ".result.txt"}];
  {firstName, secondName} = SymbolName /@ variables;
  StringJoin[
    "restart:\n",
    "interface(prettyprint=0):\n",
    "libname := \"", mapleLibrary, "\", libname:\n",
    "with(IntegrableConnections):\n",
    "with(linalg):\n",
    mapleMatrix["A1", connection[[1]]],
    mapleMatrix["A2", connection[[2]]],
    "variables := [", firstName, ",", secondName, "]:\n",
    "connection := [A1,A2]:\n",
    "fd := fopen(\"", ledger, "\", WRITE):\n",
    "fprintf(fd, \"tag=", tag, "\\n\"):\n",
    "fprintf(fd, \"maple_version=%a\\n\", kernelopts(version)):\n",
    "fprintf(fd, \"dimension=%d\\n\", rowdim(A1)):\n",
    "fprintf(fd, \"variables=%a\\n\", variables):\n",
    "fprintf(fd, \"parameters=[eps]\\n\"):\n",
    "fclose(fd):\n",
    "integrabilityStart := time[real]():\n",
    "try\n",
    "  integrabilityResult := TestIntegrabilityConditions(connection,variables):\n",
    "  integrabilitySeconds := time[real]() - integrabilityStart:\n",
    "  fd := fopen(\"", ledger, "\", APPEND):\n",
    "  fprintf(fd, \"integrability_status=OK\\n\"):\n",
    "  fprintf(fd, \"integrability_seconds=%.6f\\n\", integrabilitySeconds):\n",
    "  fprintf(fd, \"integrability_result=%a\\n\", integrabilityResult):\n",
    "  fclose(fd):\n",
    "catch:\n",
    "  integrabilitySeconds := time[real]() - integrabilityStart:\n",
    "  fd := fopen(\"", ledger, "\", APPEND):\n",
    "  fprintf(fd, \"integrability_status=ERROR\\n\"):\n",
    "  fprintf(fd, \"integrability_seconds=%.6f\\n\", integrabilitySeconds):\n",
    "  fprintf(fd, \"integrability_exception_object=%a\\n\", [lastexception]):\n",
    "  fprintf(fd, \"integrability_exception_message=%s\\n\", StringTools:-FormatMessage(lastexception[2..-1])):\n",
    "  fprintf(fd, \"integrability_lasterror=%a\\n\", [lasterror]):\n",
    "  fprintf(fd, \"integrability_lasterrorlocus=%a\\n\", eval(lasterrorlocus)):\n",
    "  fclose(fd):\n",
    "  quit:\n",
    "end try:\n",
    "fd := fopen(\"", ledger, "\", APPEND):\n",
    "fprintf(fd, \"rationalsolutions_status=STARTED\\n\"):\n",
    "fclose(fd):\n",
    "solveStart := time[real]():\n",
    "try\n",
    "  rationalBasis := RationalSolutions(connection,variables,['param',[eps]]):\n",
    "  solveSeconds := time[real]() - solveStart:\n",
    "  fd := fopen(\"", ledger, "\", APPEND):\n",
    "  fprintf(fd, \"rationalsolutions_status=RETURNED\\n\"):\n",
    "  fprintf(fd, \"rationalsolutions_seconds=%.6f\\n\", solveSeconds):\n",
    "  fprintf(fd, \"rationalsolutions_result_type=%a\\n\", whattype(rationalBasis)):\n",
    "  if rationalBasis = {} then\n",
    "    fprintf(fd, \"rationalsolutions_empty=true\\n\"):\n",
    "  else\n",
    "    rationalBasis := convert(rationalBasis,matrix):\n",
    "    fprintf(fd, \"rationalsolutions_empty=false\\n\"):\n",
    "    fprintf(fd, \"basis_rows=%d\\n\", rowdim(rationalBasis)):\n",
    "    fprintf(fd, \"basis_columns=%d\\n\", coldim(rationalBasis)):\n",
    "    residual1 := map(normal,evalm(map(diff,rationalBasis,variables[1])-A1&*rationalBasis)):\n",
    "    residual2 := map(normal,evalm(map(diff,rationalBasis,variables[2])-A2&*rationalBasis)):\n",
    "    fprintf(fd, \"basis_residual_1_zero=%a\\n\", evalb(convert(residual1,set)={0})):\n",
    "    fprintf(fd, \"basis_residual_2_zero=%a\\n\", evalb(convert(residual2,set)={0})):\n",
    "    rf := fopen(\"", resultFile, "\", WRITE):\n",
    "    fprintf(rf, \"%a\\n\", convert(rationalBasis,listlist)):\n",
    "    fclose(rf):\n",
    "  end if:\n",
    "  fclose(fd):\n",
    "catch:\n",
    "  solveSeconds := time[real]() - solveStart:\n",
    "  fd := fopen(\"", ledger, "\", APPEND):\n",
    "  fprintf(fd, \"rationalsolutions_status=ERROR\\n\"):\n",
    "  fprintf(fd, \"rationalsolutions_seconds=%.6f\\n\", solveSeconds):\n",
    "  fprintf(fd, \"rationalsolutions_exception_object=%a\\n\", [lastexception]):\n",
    "  fprintf(fd, \"rationalsolutions_exception_message=%s\\n\", StringTools:-FormatMessage(lastexception[2..-1])):\n",
    "  fprintf(fd, \"rationalsolutions_lasterror=%a\\n\", [lasterror]):\n",
    "  fprintf(fd, \"rationalsolutions_lasterrorlocus=%a\\n\", eval(lasterrorlocus)):\n",
    "  fclose(fd):\n",
    "end try:\n",
    "quit:\n"
  ]
];

start = AbsoluteTime[];
Print["BEGIN_BUILD"];
Print["record_path=", recordPath];
Print["record_sha256=", FileHash[recordPath, "SHA256", "HexString"]];
Print["eps_form_strip_path=", epsFormStripPath];
Print["eps_form_strip_sha256=", FileHash[epsFormStripPath, "SHA256", "HexString"]];

record = Get[recordPath];
variables = record["Variables"];
epsilon = record["Regulator"];
strip = record["Strip"];
{e, c, bbar} = strip;

$feynFacetRoot = root;
Get[epsFormStripPath];

residueStart = AbsoluteTime[];
residueData = epsFormStripBuildResidueCompatibility[
  strip, variables, epsilon, 4];
residueSeconds = AbsoluteTime[] - residueStart;
If[residueData === $Failed,
  Print["residue_status=FAILED"];
  Print["residue_failure_stage=", InputForm[$epsFormStripResidueFailureStage]];
  Print["residue_seconds=", InputForm[residueSeconds]];
  Exit[1]
];

freeResiduesOriginal = residueData["FreeResidues"];
stableFreeResidues = Array[Symbol["Global`kappa" <> ToString[#]] &,
  Length[freeResiduesOriginal]];
stableRules = Thread[freeResiduesOriginal -> stableFreeResidues];
residueMatrices = residueData["ResidueMatrices"] /. stableRules;
forcing = residueData["Forcing"] /. stableRules;

shape = Dimensions[bbar[[1]]];
gaugeDimension = Times @@ shape;
homConnection = Table[
  epsilon (
    KroneckerProduct[e[[mu]], IdentityMatrix[shape[[2]]]] -
    KroneckerProduct[IdentityMatrix[shape[[1]]], Transpose[c[[mu]]]]),
  {mu, 2}];
source = Flatten /@ forcing;
zeroResidueRules = Thread[stableFreeResidues -> 0];
sourceConstant = Map[Together, source /. zeroResidueRules, {2}];
sourceParameterMatrices = Table[
  Transpose@Table[
    Map[Together, Coefficient[source[[mu]], parameter]],
    {parameter, stableFreeResidues}],
  {mu, 2}];
sourceReconstructed = Table[
  Map[Together,
    sourceConstant[[mu]] +
      sourceParameterMatrices[[mu]].stableFreeResidues - source[[mu]]],
  {mu, 2}];

residueCount = Length[stableFreeResidues];
augmentedDimension = gaugeDimension + 1 + residueCount;
augmentedConnection = Table[
  ArrayFlatten[{
    {
      homConnection[[mu]],
      Transpose[{sourceConstant[[mu]]}],
      sourceParameterMatrices[[mu]]
    },
    {
      ConstantArray[0, {1, gaugeDimension}],
      {{0}},
      ConstantArray[0, {1, residueCount}]
    },
    {
      ConstantArray[0, {residueCount, gaugeDimension}],
      ConstantArray[0, {residueCount, 1}],
      ConstantArray[0, {residueCount, residueCount}]
    }
  }],
  {mu, 2}];

flatnessStart = AbsoluteTime[];
augmentedFlatness = Map[Together,
  D[augmentedConnection[[2]], variables[[1]]] -
    D[augmentedConnection[[1]], variables[[2]]] +
    augmentedConnection[[2]].augmentedConnection[[1]] -
    augmentedConnection[[1]].augmentedConnection[[2]],
  {2}];
flatnessSeconds = AbsoluteTime[] - flatnessStart;

convertedStrip = strip /. epsilon -> CANONICA`eps;
extractIrreducibles = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
allIrreducibles = extractIrreducibles[
  convertedStrip, CANONICA`AllowEpsDependence -> True] /.
  CANONICA`eps -> epsilon;
epsilonDependentIrreducibles = Select[allIrreducibles, ! FreeQ[#, epsilon] &];

sourceParameterNonzero = Table[
  ! zeroQ[sourceParameterMatrices[[mu, All, parameterIndex]]],
  {parameterIndex, residueCount}, {mu, 2}];

summary = <|
  "RecordPath" -> recordPath,
  "RecordSHA256" -> FileHash[recordPath, "SHA256", "HexString"],
  "EpsFormStripPath" -> epsFormStripPath,
  "EpsFormStripSHA256" -> FileHash[epsFormStripPath, "SHA256", "HexString"],
  "Variables" -> variables,
  "Regulator" -> epsilon,
  "StripDimensions" -> Dimensions /@ strip,
  "GaugeShape" -> shape,
  "GaugeDimension" -> gaugeDimension,
  "ResidueEquationCount" -> residueData["EquationCount"],
  "ResidueCount" -> residueCount,
  "OriginalFreeResidues" -> freeResiduesOriginal,
  "StableFreeResidues" -> stableFreeResidues,
  "StableResidueRules" -> stableRules,
  "ResidueCompatibilityZero" -> residueData["CompatibilityZero"],
  "ResidueBuildSeconds" -> residueSeconds,
  "ResidueInternalTimings" -> KeyTake[residueData, {
    "CompatibilitySeconds", "EquationSeconds", "SolveSeconds",
    "NormalizationSeconds", "ExactCheckSeconds"
  }],
  "Alphabet" -> residueData["Alphabet"],
  "AllIrreducibles" -> allIrreducibles,
  "EpsilonDependentIrreducibles" -> epsilonDependentIrreducibles,
  "SourceAffineDecompositionZero" -> zeroQ[sourceReconstructed],
  "SourceParameterNonzeroByVariable" -> sourceParameterNonzero,
  "AugmentedDimension" -> augmentedDimension,
  "AugmentedDimensions" -> Dimensions /@ augmentedConnection,
  "AugmentedFlatnessZero" -> zeroQ[augmentedFlatness],
  "AugmentedFlatnessSeconds" -> flatnessSeconds
|>;

data = <|
  "Summary" -> summary,
  "Strip" -> strip,
  "Alphabet" -> residueData["Alphabet"],
  "DLog" -> residueData["DLog"],
  "ResidueMatrices" -> residueMatrices,
  "FreeResidues" -> stableFreeResidues,
  "Forcing" -> forcing,
  "HomConnection" -> homConnection,
  "SourceConstant" -> sourceConstant,
  "SourceParameterMatrices" -> sourceParameterMatrices,
  "AugmentedConnection" -> augmentedConnection
|>;

summaryPath = FileNameJoin[{artifactDirectory, "04_cf254_augmented_summary.wl"}];
dataPath = FileNameJoin[{artifactDirectory, "04_cf254_augmented_data.wl"}];
Put[summary, summaryPath];
Put[data, dataPath];

xyMaplePath = FileNameJoin[{artifactDirectory, "05_cf254_augmented_xy.mpl"}];
yxMaplePath = FileNameJoin[{artifactDirectory, "05_cf254_augmented_yx.mpl"}];
Export[xyMaplePath,
  mapleProgram[augmentedConnection, variables, "augmented_xy"], "Text"];
Export[yxMaplePath,
  mapleProgram[Reverse[augmentedConnection], Reverse[variables], "augmented_yx"],
  "Text"];

Print["residue_status=OK"];
Print["residue_seconds=", InputForm[residueSeconds]];
Print["residue_equation_count=", residueData["EquationCount"]];
Print["residue_count=", residueCount];
Print["original_free_residues=", InputForm[freeResiduesOriginal]];
Print["stable_free_residues=", InputForm[stableFreeResidues]];
Print["alphabet=", InputForm[residueData["Alphabet"]]];
Print["epsilon_dependent_irreducibles=", InputForm[epsilonDependentIrreducibles]];
Print["source_affine_decomposition_zero=", zeroQ[sourceReconstructed]];
Print["source_parameter_nonzero_by_variable=", InputForm[sourceParameterNonzero]];
Print["gauge_dimension=", gaugeDimension];
Print["augmented_dimension=", augmentedDimension];
Print["augmented_dimensions=", InputForm[Dimensions /@ augmentedConnection]];
Print["augmented_flatness_seconds=", InputForm[flatnessSeconds]];
Print["augmented_flatness_zero=", zeroQ[augmentedFlatness]];
Print["summary_path=", summaryPath];
Print["data_path=", dataPath];
Print["xy_maple_path=", xyMaplePath];
Print["yx_maple_path=", yxMaplePath];
Print["total_seconds=", InputForm[AbsoluteTime[] - start]];
Print["END_BUILD"];

Exit[0];
