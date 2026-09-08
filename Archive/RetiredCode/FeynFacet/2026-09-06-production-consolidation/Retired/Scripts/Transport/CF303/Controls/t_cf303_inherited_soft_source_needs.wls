$HistoryLength = 0;
here = DirectoryName[ExpandFileName[$InputFileName]];
cf303Directory = DirectoryName[here];
repository = DirectoryName[cf303Directory, 3];
artifact = Get[FileNameJoin[{cf303Directory, "Artifacts",
  "CF303InheritedSoftSourceNeeds.wl"}]];
checks = <||>;
check[name_, value_] := AssociateTo[checks, name -> TrueQ[value]];

support = {1, 2, 12, 21, 22, 29, 30};
expectedMap = {
  {1, 7, "CF1", 1, 1}, {2, 39, "CF12", 4, 6},
  {12, 8, "CF21", 1, 4}, {21, 29, "CF199", 1, 8},
  {22, 30, "CF199", 2, 9}, {29, 20, "CF53", 4, 11},
  {30, 21, "CF53", 5, 12}};
map = artifact["StateToLowerPhysical"];
check["StateToLowerPhysical",
  ({#StateRow, #CF303OriginalMaster, #LowerFamily, #LowerPhysicalRow,
       #LowerCanonicalRow} & /@ map) === expectedMap];

(* Read only the seven relevant rows of the accepted 154 MB state. *)
state = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-28_codex_clean", "CF303",
  "sector_state_CF303_standard.wl"}];
extractor = FileNameJoin[{repository, "Scripts", "Transport", "Utilities",
  "extract_wl_matrix_slice.py"}];
temporary = CreateTemporary[];
arguments = Join[{"python3", extractor, state, temporary,
    "--key", "SInverse", "--key", "TDiagonalInverse", "--rows"},
   ToString /@ support, {"--columns"}, ToString /@ Range[43]];
process = RunProcess[arguments];
If[process["ExitCode"] =!= 0, Print[process["StandardError"]]; Quit[2]];
gaugeRows = Get[temporary]["Matrices"];
DeleteFile[temporary];
sinv = gaugeRows["SInverse"];
tdinv = gaugeRows["TDiagonalInverse"];
positions = AssociationThread[support, Range[Length[support]]];
expectedFactors = Lookup[map, "CanonicalFromPhysicalFactor"];
actualFactors = Table[
  sinv[[positions[row], row]]*tdinv[[positions[row], row]], {row, support}];
offDiagonalZeroQ[matrix_] := And @@ Flatten@Table[
  If[column === support[[localRow]], True, matrix[[localRow, column]] === 0],
  {localRow, Length[support]}, {column, 43}];
check["AcceptedGaugeRowsAreDiagonalOnSupport",
  offDiagonalZeroQ[sinv] && offDiagonalZeroQ[tdinv]];
check["CanonicalFromPhysicalFactors",
  And @@ MapThread[PossibleZeroQ[#1 - #2] &, {actualFactors,
    expectedFactors}]];

(* Recover the lower-family canonical row and the already generated order
   coverage from the actual accepted artifacts. *)
epsFormsDirectory = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
observableDirectory = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal",
  "Results", "UU_08_10_canonical",
  "ObservableTransport_2026-09-01_codex", "families"}];
families = DeleteDuplicates[Lookup[map, "LowerFamily"]];
epsForms = Association@Table[family -> Get[FileNameJoin[{epsFormsDirectory,
    "family_epsform_" <> family <> ".wl"}]], {family, families}];
observables = Association@Table[family -> Get[FileNameJoin[{observableDirectory,
    "observable_transport_" <> family <> ".wl"}]], {family, families}];
canonicalRow[family_, physicalRow_] := Module[{form, blockIndex, component},
  form = epsForms[family];
  blockIndex = First@FirstPosition[form["Blocks"],
    rows_ /; MemberQ[rows, physicalRow]];
  component = First@FirstPosition[form["Blocks"][[blockIndex]], physicalRow];
  form["Ranges"][[blockIndex, component]]];
observableOrders[family_, physicalRow_] := Lookup[
  SelectFirst[observables[family]["Demand"]["MasterRows"],
    Lookup[#, "OriginalRow", None] === physicalRow &], "Orders", {}];
check["LowerCanonicalRows",
  (canonicalRow[#LowerFamily, #LowerPhysicalRow] & /@ map) ===
    Lookup[map, "LowerCanonicalRow"]];
check["ObservableOrderCoverage",
  (observableOrders[#LowerFamily, #LowerPhysicalRow] & /@ map) ===
    Lookup[map, "ExistingObservableOrders"]];
check["OnlyOneExtraOrderPerIncompleteRow",
  Lookup[Select[map, Lookup[#, "MissingObservableOrders"] =!= {} &],
    "MissingObservableOrders"] === {{2}, {2}, {3}, {2}, {3}}];
check["AllLowerTransportsRational",
  And @@ (Lookup[#, "CoefficientField", None] === "Rational" & /@
    Values[observables])];

(* Derive the soft normal and tangential class-44 mode system rather than
   trusting the recorded mode labels. *)
class44 = Get[FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "ClassForms", "class44.wl"}]];
{av, aw} = class44["EpsForm"];
r = Unique["softDistance"];
softRules = {v -> p^2, w -> 1 - p^2 - r};
normalResidue = Map[Cancel[Together[Limit[r*(-# /. softRules), r -> 0]]] &,
  aw, {2}];
tangential = Map[Cancel[Together[Limit[#, r -> 0]]] &,
  2*p*(av - aw) /. softRules, {2}];
modeFrame = {{2, 0}, {-3, 1}};
modeTangent = Map[Factor, Inverse[modeFrame].tangential.modeFrame, {2}];
expectedModeTangent = DiagonalMatrix[{
  eps*(-4/p - 2/(p - 1) - 2/(p + 1)),
  eps*(-4/p + 2/(p - 1) + 2/(p + 1))}];
check["Class44SoftResidue", normalResidue === eps*{{0, 0}, {-6, -4}}];
check["Class44ModeTangent",
  And @@ Flatten[Map[PossibleZeroQ, modeTangent - expectedModeTangent, {2}]]];

periodRoot = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "BoundaryPeriods", "Certificates"}];
period6 = Get[FileNameJoin[{periodRoot, "period_06.wl"}]];
nullity = Get[FileNameJoin[{periodRoot, "NullityPeriods.wl"}]];
period9 = SelectFirst[nullity["Periods"], Lookup[#, "PeriodID", None] === 9 &];
check["PID6CF21KnownZero", period6["Status"] === "Exact" &&
  period6["ExactCoefficient"] === 0 &&
  period6["VerifiedTransfers"]["CF21"]["Status"] === "Exact"];
check["PID9StructuralCandidate",
  period9["ClassID"] === 44 && period9["ClassDim"] === 2 &&
  period9["FrobeniusExponent"]["soft"] === 0 &&
  !FileExistsQ[FileNameJoin[{periodRoot, "period_09.wl"}]]];
check["FormalLedgerIsGPLOnly",
  Length[artifact["Stage3NeedsLedger"]] === 2 &&
  Lookup[artifact["Stage3NeedsLedger"], "PeriodClass"] === {"GPL", "GPL"} &&
  artifact["PrunedStage3Inputs"]["Elliptic"] === {}];

(* One accepted point is enough to verify that the projection really has
   only seven source columns and a double pole.  It is not used as an
   identity certificate. *)
pointScript = FileNameJoin[{cf303Directory,
  "cf303_inherited_soft_projection_point.py"}];
pointProcess = RunProcess[{"python3", pointScript, "--p", "3"}];
If[pointProcess["ExitCode"] =!= 0,
  Print[pointProcess["StandardError"]]; Quit[2]];
point = ImportString[pointProcess["StandardOutput"], "RawJSON"];
formalProjections = Select[point["mode_projections"],
  Lookup[#, "period_status"] === "FormalUnevaluated" &];
check["AcceptedWSupportAndPoleDepth",
  point["status"] === "CF303InheritedSoftProjectionPointV1" &&
  point["source_state_rows"] === support &&
  point["local_rho_power_window"] === {-2, 0} &&
  point["maximum_input_w_pole_order"] === 2 &&
  TrueQ[point["coefficient_field_usage"]["rational_base_only"]]];
check["MinimalWCoordinateCount",
  artifact["MinimalWProjection"]["RequiredScalarWCoordinates"] ===
   2*(3*6 + 4*7)];
check["BothPID9PrincipalProjectionsAreActive",
  point["formal_pid9_coordinate_count"] === 28 &&
  Counts[Lookup[formalProjections, "mode_id"]] ===
    <|"CF199::PID9ZeroMode" -> 14, "CF53::PID9ZeroMode" -> 14|> &&
  Count[Flatten[Lookup[formalProjections, "local_coefficients"]],
    item_Association /; Lookup[item, "rho_power"] === 0] === 28];

failed = Keys@Select[checks, Not];
If[failed =!= {}, Print["FAIL ", failed]; Quit[3]];
Print["PASS checks=", Length[checks],
  " pointSeconds=", point["total_seconds"],
  " supportRows=", support, " requiredW=92 formalPID9Series=2x7"];
Quit[];
