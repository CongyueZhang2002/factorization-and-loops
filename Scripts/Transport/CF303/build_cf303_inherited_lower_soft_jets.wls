$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
repository = DirectoryName[scriptDirectory, 3];
Get[FileNameJoin[{repository, "FeynFacet", "Private", "Transport",
  "Boundary", "PhysicalBoundary.wl"}]];
inputDirectory = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
outputPath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303InheritedLowerSoftJets.wl"}];

specifications = {
  <|"Family" -> "CF1", "ConnectionKey" -> "EpsFormY",
    "Variable" -> w, "Endpoint" -> 1 - p^2, "Direction" -> -1,
    "MaximumSeriesOrder" -> 4, "MaximumEpsilonOrder" -> 5,
    "FixedRules" -> {v -> p^2}, "SelectedCanonicalRows" -> {1},
    "LowerPhysicalRows" -> {1}, "ExpectedActiveColumns" -> {1},
    "ColumnRoles" -> {1 -> "Class1Volume"}|>,
  <|"Family" -> "CF12", "ConnectionKey" -> "EpsFormY",
    "Variable" -> y, "Endpoint" -> 1 - p^2, "Direction" -> -1,
    "MaximumSeriesOrder" -> 4, "MaximumEpsilonOrder" -> 5,
    "FixedRules" -> {x -> p^2}, "SelectedCanonicalRows" -> {6},
    "LowerPhysicalRows" -> {4}, "ExpectedActiveColumns" -> {1, 6},
    "ColumnRoles" -> {1 -> "Class1Volume", 6 -> "Class5Physical"}|>,
  <|"Family" -> "CF21", "ConnectionKey" -> "EpsFormX",
    "Variable" -> x, "Endpoint" -> -p, "Direction" -> 1,
    "MaximumSeriesOrder" -> 4, "MaximumEpsilonOrder" -> 5,
    "FixedRules" -> {y -> p}, "SelectedCanonicalRows" -> {4},
    "LowerPhysicalRows" -> {1}, "ExpectedActiveColumns" -> {1, 4},
    "ColumnRoles" -> {1 -> "Class1Volume", 4 -> "Class17PID6"}|>,
  <|"Family" -> "CF199", "ConnectionKey" -> "EpsFormY",
    "Variable" -> y, "Endpoint" -> 1 - p^2, "Direction" -> -1,
    "MaximumSeriesOrder" -> 4, "MaximumEpsilonOrder" -> 6,
    "FixedRules" -> {x -> p^2}, "SelectedCanonicalRows" -> {8, 9},
    "LowerPhysicalRows" -> {1, 2},
    "ExpectedActiveColumns" -> {1, 7, 8, 9},
    "ColumnRoles" -> {1 -> "Class1Volume", 7 -> "Class17Physical",
      8 -> "Class44Component1", 9 -> "Class44Component2"}|>,
  <|"Family" -> "CF53", "ConnectionKey" -> "EpsFormX",
    "Variable" -> x, "Endpoint" -> -p, "Direction" -> 1,
    "MaximumSeriesOrder" -> 4, "MaximumEpsilonOrder" -> 6,
    "FixedRules" -> {y -> p}, "SelectedCanonicalRows" -> {11, 12},
    "LowerPhysicalRows" -> {4, 5},
    "ExpectedActiveColumns" -> {1, 10, 11, 12},
    "ColumnRoles" -> {1 -> "Class1Volume", 10 -> "Class17PID6",
      11 -> "Class44Component1", 12 -> "Class44Component2"}|>
  };

exactZeroQ[value_] := And @@ Flatten[Map[PossibleZeroQ, value, {2}]];
matrixEntries[matrix_] := Replace[
  Reap[Do[If[matrix[[row, column]] =!= 0,
      Sow[<|"Row" -> row, "Column" -> column,
        "Value" -> matrix[[row, column]]|>]],
    {row, Length[matrix]}, {column, Length[First[matrix]]}]][[2]],
  {{} -> {}, {entries_} :> entries}];
activeColumns[prefactor_, rows_] := Sort@DeleteDuplicates@Flatten[
  KeyValueMap[Function[{key, matrix}, Cases[
    Position[matrix[[rows, All]], value_ /; value =!= 0, {2},
      Heads -> False], {_, column_} :> column]], prefactor]];
residueClosure[residue_, seeds_] := FixedPoint[
  Function[columns, Sort@Union[columns, Cases[
    Position[residue[[columns, All]], value_ /; value =!= 0, {2},
      Heads -> False], {_, column_} :> column]]], Sort[seeds]];

familyRecords = Table[
  family = specification["Family"];
  form = Get[FileNameJoin[{inputDirectory,
    "family_epsform_" <> family <> ".wl"}]];
  timing = AbsoluteTiming[frobenius = TimeConstrained[
    ComputeTruncatedLocalFrobeniusExpansion[
      form[specification["ConnectionKey"]],
      <|"Variable" -> specification["Variable"], "Regulator" -> eps,
        "LocalVariable" -> rho,
        "LocalExpansionPoint" -> specification["Endpoint"],
        "LocalDirection" -> specification["Direction"],
        "FixedRules" -> specification["FixedRules"]|>,
      "MaximumSeriesOrder" -> specification["MaximumSeriesOrder"],
      "MaximumEpsilonOrder" -> specification["MaximumEpsilonOrder"]],
    600, $Aborted]];
  If[frobenius === $Aborted,
    Print["FAIL timeout family=", family]; Quit[2]];
  If[Lookup[frobenius, "Status", None] =!=
      "TruncatedLocalFrobeniusExpansionComputed",
    Print["FAIL family=", family, " result=", InputForm[frobenius]];
    Quit[3]];
  selected = specification["SelectedCanonicalRows"];
  prefactor = frobenius["FrobeniusPrefactorCoefficients"];
  active = activeColumns[prefactor, selected];
  closure = residueClosure[frobenius["Residue"], active];
  If[closure =!= specification["ExpectedActiveColumns"],
    Print["FAIL closure family=", family, " actual=", closure]; Quit[4]];
  outside = Complement[Range[frobenius["Dimension"]], closure];
  If[outside =!= {} && !exactZeroQ[frobenius["Residue"][[closure, outside]]],
    Print["FAIL noninvariant residue family=", family]; Quit[5]];
  projectedPrefactor = KeyValueMap[Function[{key, matrix},
    <|"RhoOrder" -> key[[1]], "EpsilonOrder" -> key[[2]],
      "Entries" -> matrixEntries[matrix[[selected, closure]]]|>], prefactor];
  <|"Family" -> family, "CoefficientField" -> "Rational",
    "FunctionClass" -> "GPL", "EndpointSpec" -> <|
      "Variable" -> specification["Variable"],
      "Endpoint" -> specification["Endpoint"],
      "LocalVariable" -> rho,
      "LocalDirection" -> specification["Direction"],
      "FixedRules" -> specification["FixedRules"],
      "PhysicalSoftCoordinate" -> "s=1-v-w=rho"|>,
    "Dimension" -> frobenius["Dimension"],
    "SelectedCanonicalRows" -> selected,
    "LowerPhysicalRows" -> specification["LowerPhysicalRows"],
    "ActiveCanonicalColumns" -> closure,
    "ColumnRoles" -> specification["ColumnRoles"],
    "Residue" -> <|"Dimensions" -> {Length[closure], Length[closure]},
      "Entries" -> matrixEntries[frobenius["Residue"][[closure, closure]]],
      "Rank" -> MatrixRank[frobenius["Residue"][[closure, closure]]]|>,
    "SelectedFrobeniusPrefactor" -> <|
      "Dimensions" -> {Length[selected], Length[closure]},
      "CoefficientWindow" -> <|
        "Rho" -> {0, specification["MaximumSeriesOrder"]},
        "Epsilon" -> {0, specification["MaximumEpsilonOrder"]}|>,
      "NonzeroCoefficients" -> Select[projectedPrefactor,
        Lookup[#, "Entries"] =!= {} &]|>,
    "BuildSeconds" -> First[timing]|>,
  {specification, specifications}];

result = <|
  "Status" -> "CF303InheritedLowerSoftJetsAcceptedV2",
  "Family" -> "CF303",
  "Scope" ->
   "Only lower-family canonical rows feeding CF303 W support; physical constants remain explicit",
  "Endpoint" -> <|"PhysicalSoftStratum" -> "s=1-v-w=0",
    "TangentialVariable" -> p, "LocalVariable" -> rho|>,
  "JetDepthReason" ->
    "The accepted H deck has rho pole order three: rho^0 regularization needs source jets through rho^3 and the rho^1 intertwining control needs rho^4",
  "DemandedCoefficientWindows" -> Association@Table[
    specification["Family"] -> <|
      "Rho" -> {0, specification["MaximumSeriesOrder"]},
      "Epsilon" -> {0, specification["MaximumEpsilonOrder"]}|>,
    {specification, specifications}],
  "Families" -> familyRecords,
  "TotalBuildSeconds" -> Total[Lookup[familyRecords, "BuildSeconds"]],
  "Use" ->
   "F_source-selected=H_selected(rho,eps).rho^(eps R_active).c_active; convolve with the projected W deck and supply physical mode constants from the Stage3 ledger"
  |>;
Put[result, outputPath];
Print["PASS families=", Lookup[familyRecords, "Family"],
  " activeColumns=", Lookup[familyRecords, "ActiveCanonicalColumns"],
  " seconds=", Lookup[familyRecords, "BuildSeconds"],
  " total=", result["TotalBuildSeconds"]];
Quit[];
