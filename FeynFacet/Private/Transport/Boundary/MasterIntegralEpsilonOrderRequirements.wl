(* Required master-integral epsilon orders derived from the requested
   hard-function orders and the exact epsilon valuations of the coefficients
   multiplying the master integrals. This module is deliberately pure: both
   mathematical inputs are explicit associations and no project discovery or
   file access occurs here. *)

Begin["FeynFacet`Private`"];

Clear[
  FeynFacet`DeriveMasterIntegralEpsilonOrderRequirements,
  FeynFacet`MasterIntegralEpsilonOrderRequirementsQ];

ClearAll[
  masterIntegralEpsilonOrderReferenceQ,
  masterIntegralEpsilonOrderRequestQ,
  masterIntegralCoefficientValuationEntryQ,
  masterIntegralCoefficientValuationsQ,
  masterIntegralEpsilonOrderRequestData,
  masterIntegralCoefficientValuationsData,
  masterIntegralEpsilonOrderRequirementEntries,
  masterIntegralEpsilonOrderRequirementValidation,
  masterIntegralEpsilonOrderRequirementRecord
];

masterIntegralEpsilonOrderReferenceQ[reference_, dataType_String] :=
  AssociationQ[reference] &&
  StringQ[Lookup[reference, "RelativePath", None]] &&
  StringLength[reference["RelativePath"]] > 0 &&
  Lookup[reference, "DataType", None] === dataType &&
  Lookup[reference, "SchemaVersion", None] === 2;

masterIntegralEpsilonOrderRequestQ[request_] := Module[{orders},
  If[! AssociationQ[request] ||
      Lookup[request, "DataType", None] =!=
        "HardFunctionEpsilonOrderRequest" ||
      Lookup[request, "SchemaVersion", None] =!= 2 ||
      Lookup[request, "Status", None] =!=
        "HardFunctionEpsilonOrdersRequested",
    Return[False]];
  orders = Lookup[request, "RequestedHardFunctionEpsilonOrders", None];
  ListQ[orders] && orders =!= {} && VectorQ[orders, IntegerQ] &&
    DuplicateFreeQ[orders] &&
    (! KeyExistsQ[request, "Reference"] ||
      masterIntegralEpsilonOrderReferenceQ[request["Reference"],
        "HardFunctionEpsilonOrderRequest"])
];

masterIntegralCoefficientValuationEntryQ[entry_] :=
  AssociationQ[entry] &&
  IntegerQ[Lookup[entry, "MasterIntegralIndex", None]] &&
  entry["MasterIntegralIndex"] >= 1 &&
  AssociationQ[Lookup[entry, "MasterIntegral", None]] &&
  StringQ[Lookup[entry["MasterIntegral"], "Family", None]] &&
  StringLength[entry["MasterIntegral", "Family"]] > 0 &&
  ListQ[Lookup[entry["MasterIntegral"], "PropagatorPowers", None]] &&
  VectorQ[entry["MasterIntegral", "PropagatorPowers"], IntegerQ] &&
  IntegerQ[Lookup[entry,
    "HardFunctionCoefficientEpsilonValuation", None]] &&
  StringQ[Lookup[entry, "DeterminationMethod", None]] &&
  StringLength[entry["DeterminationMethod"]] > 0;

masterIntegralCoefficientValuationsQ[valuations_] := Module[{entries},
  If[! AssociationQ[valuations] ||
      Lookup[valuations, "DataType", None] =!=
        "HardFunctionMasterCoefficientEpsilonValuations" ||
      Lookup[valuations, "SchemaVersion", None] =!= 2 ||
      Lookup[valuations, "Status", None] =!=
        "HardFunctionMasterCoefficientEpsilonValuationsDetermined",
    Return[False]];
  entries = Lookup[valuations, "Entries", None];
  ListQ[entries] && entries =!= {} &&
    AllTrue[entries, masterIntegralCoefficientValuationEntryQ] &&
    DuplicateFreeQ[Lookup[entries, "MasterIntegralIndex"]] &&
    (! KeyExistsQ[valuations, "Reference"] ||
      masterIntegralEpsilonOrderReferenceQ[valuations["Reference"],
        "HardFunctionMasterCoefficientEpsilonValuations"])
];

masterIntegralEpsilonOrderRequestData[request_Association] := Join[<|
    "DataType" -> "HardFunctionEpsilonOrderRequest",
    "SchemaVersion" -> 2,
    "Status" -> "HardFunctionEpsilonOrdersRequested",
    "RequestedHardFunctionEpsilonOrders" ->
      Sort[request["RequestedHardFunctionEpsilonOrders"]]
  |>, If[KeyExistsQ[request, "Reference"],
    <|"Reference" -> request["Reference"]|>, <||>]];

masterIntegralCoefficientValuationsData[valuations_Association] := Join[<|
    "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
    "SchemaVersion" -> 2,
    "Status" ->
      "HardFunctionMasterCoefficientEpsilonValuationsDetermined",
    "Entries" -> SortBy[
      Map[KeyTake[#, {"MasterIntegralIndex", "MasterIntegral",
          "HardFunctionCoefficientEpsilonValuation",
          "DeterminationMethod"}] &,
        valuations["Entries"]],
      #1["MasterIntegralIndex"] &]
  |>, If[KeyExistsQ[valuations, "Reference"],
    <|"Reference" -> valuations["Reference"]|>, <||>]];

masterIntegralEpsilonOrderRequirementEntries[requestData_Association,
    valuationData_Association] := Module[{orders},
  orders = requestData["RequestedHardFunctionEpsilonOrders"];
  Map[Function[entry, <|
      "MasterIntegralIndex" -> entry["MasterIntegralIndex"],
      "RequiredMasterIntegralEpsilonOrders" ->
        Sort[(# - entry["HardFunctionCoefficientEpsilonValuation"] &) /@
          orders]
    |>], valuationData["Entries"]]
];

masterIntegralEpsilonOrderRequirementValidation[requestData_Association,
    valuationData_Association, requirementEntries_List] := Module[
  {orders, requirementByIndex, checks},
  orders = requestData["RequestedHardFunctionEpsilonOrders"];
  requirementByIndex = Association[
    (#1["MasterIntegralIndex"] -> #1) & /@ requirementEntries];
  checks = Map[Function[entry, Module[
      {index, valuation, rederived, stored},
      index = entry["MasterIntegralIndex"];
      valuation = entry["HardFunctionCoefficientEpsilonValuation"];
      rederived = Sort[(# - valuation &) /@ orders];
      stored = Lookup[Lookup[requirementByIndex, index, <||>],
        "RequiredMasterIntegralEpsilonOrders", Missing["NotStored"]];
      <|
        "MasterIntegralIndex" -> index,
        "HardFunctionCoefficientEpsilonValuation" -> valuation,
        "ReDerivedRequiredMasterIntegralEpsilonOrders" -> rederived,
        "StoredRequiredMasterIntegralEpsilonOrders" -> stored,
        "RelationVerified" -> TrueQ[stored === rederived]
      |>
    ]], valuationData["Entries"]];
  <|
    "Method" -> "DeterministicIntegerArithmetic",
    "Exact" -> True,
    "DefiningRelation" ->
      "required master-integral epsilon order = requested hard-function epsilon order - hard-function coefficient epsilon valuation",
    "Checks" -> checks,
    "Passed" -> AllTrue[checks, TrueQ[#1["RelationVerified"]] &]
  |>
];

masterIntegralEpsilonOrderRequirementRecord[request_Association,
    valuations_Association] := Module[
  {requestData, valuationData, entries, validation, references},
  requestData = masterIntegralEpsilonOrderRequestData[request];
  valuationData = masterIntegralCoefficientValuationsData[valuations];
  entries = masterIntegralEpsilonOrderRequirementEntries[
    requestData, valuationData];
  validation = masterIntegralEpsilonOrderRequirementValidation[
    requestData, valuationData, entries];
  references = Association@DeleteCases[{
      If[KeyExistsQ[request, "Reference"],
        "HardFunctionEpsilonOrderRequest" -> request["Reference"], Nothing],
      If[KeyExistsQ[valuations, "Reference"],
        "HardFunctionMasterCoefficientEpsilonValuations" ->
          valuations["Reference"], Nothing]
    }, Nothing];
  <|
    "DataType" -> "MasterIntegralEpsilonOrderRequirements",
    "SchemaVersion" -> 2,
    "Status" -> If[TrueQ[validation["Passed"]],
      "MasterIntegralEpsilonOrderRequirementsDerived",
      "MasterIntegralEpsilonOrderRequirementsValidationFailed"],
    "RequestedHardFunctionEpsilonOrders" ->
      requestData["RequestedHardFunctionEpsilonOrders"],
    "Entries" -> entries,
    "MathematicalInputReferences" -> references,
    "MathematicalInputData" -> <|
      "HardFunctionEpsilonOrderRequest" -> requestData,
      "HardFunctionMasterCoefficientEpsilonValuations" -> valuationData
    |>,
    "Validation" -> validation
  |>
];

FeynFacet`DeriveMasterIntegralEpsilonOrderRequirements[
    request_Association, valuations_Association] := Module[{},
  If[Lookup[request, "SchemaVersion", None] =!= 2 ||
      Lookup[valuations, "SchemaVersion", None] =!= 2,
    Return[<|
      "DataType" -> "MasterIntegralEpsilonOrderRequirements",
      "SchemaVersion" -> 2,
      "Status" -> "LegacyDifferentialEquationSchemaUnsupported"
    |>]];
  If[! masterIntegralEpsilonOrderRequestQ[request],
    Return[<|
      "DataType" -> "MasterIntegralEpsilonOrderRequirements",
      "SchemaVersion" -> 2,
      "Status" -> "HardFunctionEpsilonOrderRequestInvalid"
    |>]];
  If[! masterIntegralCoefficientValuationsQ[valuations],
    Return[<|
      "DataType" -> "MasterIntegralEpsilonOrderRequirements",
      "SchemaVersion" -> 2,
      "Status" ->
        "HardFunctionMasterCoefficientEpsilonValuationsInvalid"
    |>]];
  masterIntegralEpsilonOrderRequirementRecord[request, valuations]
];

FeynFacet`DeriveMasterIntegralEpsilonOrderRequirements[___] := <|
  "DataType" -> "MasterIntegralEpsilonOrderRequirements",
  "SchemaVersion" -> 2,
  "Status" -> "MasterIntegralEpsilonOrderRequirementInputsNotWellFormed"
|>;

FeynFacet`MasterIntegralEpsilonOrderRequirementsQ[record_Association] :=
 Module[{inputs, request, valuations, expected},
  If[Lookup[record, "DataType", None] =!=
        "MasterIntegralEpsilonOrderRequirements" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!=
        "MasterIntegralEpsilonOrderRequirementsDerived",
    Return[False]];
  inputs = Lookup[record, "MathematicalInputData", None];
  If[! AssociationQ[inputs] ||
      ! KeyExistsQ[inputs, "HardFunctionEpsilonOrderRequest"] ||
      ! KeyExistsQ[inputs,
        "HardFunctionMasterCoefficientEpsilonValuations"],
    Return[False]];
  request = inputs["HardFunctionEpsilonOrderRequest"];
  valuations =
    inputs["HardFunctionMasterCoefficientEpsilonValuations"];
  expected = FeynFacet`DeriveMasterIntegralEpsilonOrderRequirements[
    request, valuations];
  Lookup[expected, "Status", None] ===
      "MasterIntegralEpsilonOrderRequirementsDerived" &&
    record["RequestedHardFunctionEpsilonOrders"] ===
      expected["RequestedHardFunctionEpsilonOrders"] &&
    record["Entries"] === expected["Entries"] &&
    Lookup[record, "MathematicalInputReferences", Missing["NotStored"]] ===
      expected["MathematicalInputReferences"] &&
    inputs === expected["MathematicalInputData"] &&
    Lookup[record, "Validation", Missing["NotStored"]] ===
      expected["Validation"]
];

FeynFacet`MasterIntegralEpsilonOrderRequirementsQ[___] := False;

End[];
