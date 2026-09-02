(* RETIRED ROUTE (overhaul 2026-09-02): FeynFacet`LibraFamilyEpsForm answers
   <|"Status" -> "RouteRetired", ...|> (the implementation is kept, unloaded,
   in FeynFacet/Private_Backup/LibraEpsForm.wl).  This worker only ever
   served that route; its DownValues guard below cannot tell the stub from
   the implementation (review note N5), so a run now records the retired
   status as the family's failure record instead of an eps-form. *)
(* Data adapter from the NNLO family records to LibraFamilyEpsForm. *)

ClearAll[FACETBatch`RunLibraFamilyEpsForm];

FACETBatch`Private`$libraWorkerRepositoryRoot =
  DirectoryName[ExpandFileName[$InputFileName], 3];

FACETBatch`RunLibraFamilyEpsForm[
    family_String, outputDirectory_String, timeLimit_: 1800] := Module[
  {root, putAtomic, writeFailure, resultFile, summaryFile, existing,
   vv, ww, ee, normalizeNames, normalizeSymbols, normalizeRegulator,
   readArtifact, dataDirectory, classFormDirectory, hardFormDirectory,
   deDirectory, twoRootFamilies, chart, chartCertificate, assignments,
   classFormFile, hardFormFile, hardRecord, familyAssignments,
   familyBlocks, missingForms, deFile, de, system, seconds, result,
   summary},

  root = FACETBatch`Private`$libraWorkerRepositoryRoot;
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  resultFile = FileNameJoin[{outputDirectory,
    "family_epsform_" <> family <> ".wl"}];
  summaryFile = FileNameJoin[{outputDirectory,
    "summary_" <> family <> ".wl"}];

  putAtomic[expression_, file_String] := Module[{temporary = file <> ".tmp"},
    Put[expression, temporary];
    RenameFile[temporary, file, OverwriteTarget -> True];
    file
  ];
  writeFailure[status_String, detail_] := Module[{record},
    record = <|"Family" -> family, "Status" -> status,
      "Detail" -> detail, "Date" -> DateString[]|>;
    putAtomic[record, summaryFile];
    record
  ];

  If[FileExistsQ[resultFile] && FileExistsQ[summaryFile],
    existing = Quiet[Check[Get[summaryFile], $Failed]];
    If[AssociationQ[existing] && StringQ[Lookup[existing, "Status", None]],
      Return[Join[existing, <|"Reused" -> True|>]]]];

  Quiet[ClearAll["Global`v", "Global`w", "Global`x", "Global`y",
    "Global`s", "Global`u", "Global`p", "Global`t", "Global`tau",
    "Global`eps"]];
  If[Length[DownValues[FeynFacet`LibraFamilyEpsForm]] === 0,
    Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

  vv = Symbol["Global`v"];
  ww = Symbol["Global`w"];
  ee = Symbol["Global`eps"];
  normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep",
    "v", "w", "x", "y", "s", "u", "p", "t", "tau",
    "sqrtLambda", "gli"};
  normalizeSymbols[expression_] := Module[{symbols, rules},
    symbols = DeleteDuplicates[Cases[expression,
      symbol_Symbol /;
        MemberQ[normalizeNames, SymbolName[symbol]] &&
        Context[symbol] =!= "Global`",
      {0, Infinity}, Heads -> True]];
    rules = Table[symbols[[i]] ->
      Symbol["Global`" <> SymbolName[symbols[[i]]]],
      {i, Length[symbols]}];
    expression /. rules
  ];
  normalizeRegulator[expression_] := Module[{symbols, rules},
    symbols = DeleteDuplicates[Cases[expression,
      symbol_Symbol /;
        MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"},
          SymbolName[symbol]],
      {0, Infinity}, Heads -> True]];
    rules = Thread[symbols -> ee];
    expression /. rules
  ];
  readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

  dataDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical"}];
  classFormDirectory = FileNameJoin[{dataDirectory, "ClassForms"}];
  hardFormDirectory = FileNameJoin[{dataDirectory, "HardClasses",
    "EpsFormRoute"}];
  deDirectory = FileNameJoin[{dataDirectory, "DifferentialEquations"}];
  twoRootFamilies = {
    "CF232", "CF236", "CF240", "CF319", "CF321", "CF385", "CF408",
    "CF249", "CF254", "CF265", "CF226", "CF231", "CF305"
  };
  If[! MemberQ[twoRootFamilies, family],
    Return[writeFailure["FamilyNotInTwoRootInventory", twoRootFamilies]]];

  chart = FeynFacet`TransportFamilyChart[family];
  If[! AssociationQ[chart],
    Return[writeFailure["ChartNotAvailable", chart]]];
  chartCertificate = FeynFacet`TransportChartVerify[chart];
  If[! AssociationQ[chartCertificate] ||
      ! TrueQ[chartCertificate["OK"]],
    Return[writeFailure["ChartIdentityFailed", chartCertificate]]];

  assignments = readArtifact[FileNameJoin[{dataDirectory, "BlockClasses",
    "block_class_assign.wl"}]];
  classFormFile[class_] := FileNameJoin[{classFormDirectory,
    "class" <> ToString[class] <> ".wl"}];
  hardFormFile[class_] := FileNameJoin[{hardFormDirectory,
    "c" <> ToString[class] <> "_epsform_two_variable.wl"}];
  hardRecord[class_, representativeFamily_, representativeRows_] := Module[{raw},
    If[! FileExistsQ[hardFormFile[class]],
      Return[Missing["ClassFormNotFound", class]]];
    raw = readArtifact[hardFormFile[class]];
    <|"ClassID" -> class, "RepFamily" -> representativeFamily,
      "RepRows" -> representativeRows, "Dim" -> Length[raw["T"]],
      "Transformation" -> raw["T"],
      "EpsForm" -> {raw["Ax"], raw["Ay"]},
      "Variables" -> {Symbol["Global`x"], Symbol["Global`y"]},
      "Chart" -> FeynFacet`TransportChartCatalog[]["Kallen1"],
      "AnsatzDegree" -> None, "Validated" -> True|>
  ];

  familyAssignments = Select[assignments, #["Family"] === family &];
  If[familyAssignments === {},
    Return[writeFailure["NoBlockAssignments", None]]];
  familyBlocks = Table[
    {assignment["Rows"],
      If[FileExistsQ[classFormFile[assignment["ClassID"]]],
        assignment["ClassID"],
        hardRecord[assignment["ClassID"], family, assignment["Rows"]]]},
    {assignment, familyAssignments}];
  missingForms = Cases[familyBlocks, _Missing, Infinity];
  If[missingForms =!= {},
    Return[writeFailure["DiagonalFormMissing", missingForms]]];

  deFile = FileNameJoin[{deDirectory, "nnlo_de_" <> family <> ".wl"}];
  If[! FileExistsQ[deFile],
    Return[writeFailure["DifferentialEquationMissing", deFile]]];
  de = readArtifact[deFile];
  system = <|"Family" -> family,
    "Basis" -> Lookup[de, "BlockBasis", None],
    "Av" -> de["Av"], "Aw" -> de["Aw"]|>;

  {seconds, result} = AbsoluteTiming[
    Quiet[Check[
      FeynFacet`LibraFamilyEpsForm[
        system, chart,
        "SourceVariables" -> {vv, ww},
        "Regulator" -> ee,
        "Blocks" -> familyBlocks,
        "FormDirectory" -> classFormDirectory,
        "UseFermat" -> False,
        "TimeLimit" -> timeLimit,
        "Verbose" -> False],
      $Failed]]
  ];
  If[! AssociationQ[result],
    Return[writeFailure["LibraDidNotReturnAssociation", result]]];

  result = Join[result, <|"MeasuredSeconds" -> seconds,
    "ChartCertificate" -> chartCertificate, "Date" -> DateString[]|>];
  putAtomic[result, resultFile];
  summary = <|"Family" -> family, "Status" -> result["Status"],
    "Chart" -> chart["Name"], "Dimension" -> Length[system["Av"]],
    "Blocks" -> Length[familyBlocks], "Seconds" -> seconds,
    "TransformationCount" -> Lookup[result, "TransformationCount", Missing[]],
    "Checks" -> Lookup[result, "Checks", <||>],
    "Steps" -> Lookup[result, "Steps", {}],
    "ResultFile" -> resultFile, "Date" -> DateString[]|>;
  putAtomic[summary, summaryFile];
  summary
];
