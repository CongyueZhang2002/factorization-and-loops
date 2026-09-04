#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

request = <|
  "DataType" -> "HardFunctionEpsilonOrderRequest",
  "SchemaVersion" -> 2,
  "Status" -> "HardFunctionEpsilonOrdersRequested",
  "RequestedHardFunctionEpsilonOrders" -> {1, -1, 0},
  "Reference" -> <|
    "RelativePath" -> "InputData/hard_function_epsilon_order_request.wl",
    "DataType" -> "HardFunctionEpsilonOrderRequest",
    "SchemaVersion" -> 2
  |>
|>;

valuations = <|
  "DataType" -> "HardFunctionMasterCoefficientEpsilonValuations",
  "SchemaVersion" -> 2,
  "Status" ->
    "HardFunctionMasterCoefficientEpsilonValuationsDetermined",
  "Reference" -> <|
    "RelativePath" ->
      "InputData/hard_function_master_coefficient_epsilon_valuations.wl",
    "DataType" ->
      "HardFunctionMasterCoefficientEpsilonValuations",
    "SchemaVersion" -> 2
  |>,
  "Entries" -> {
    <|
      "MasterIntegralIndex" -> 8,
      "MasterIntegral" -> <|
        "Family" -> "FamilyBeta", "PropagatorPowers" -> {1, 1, 0}|>,
      "HardFunctionCoefficientEpsilonValuation" -> 0,
      "DeterminationMethod" -> "ExactLowerAndUpperBoundAgreement"
    |>,
    <|
      "MasterIntegralIndex" -> 3,
      "MasterIntegral" -> <|
        "Family" -> "FamilyAlpha", "PropagatorPowers" -> {1, 0, 1}|>,
      "HardFunctionCoefficientEpsilonValuation" -> -2,
      "DeterminationMethod" -> "ExactLowerAndUpperBoundAgreement"
    |>,
    <|
      "MasterIntegralIndex" -> 11,
      "MasterIntegral" -> <|
        "Family" -> "FamilyGamma", "PropagatorPowers" -> {1, 1, 1}|>,
      "HardFunctionCoefficientEpsilonValuation" -> 3,
      "DeterminationMethod" -> "ExactLowerAndUpperBoundAgreement"
    |>
  }
|>;

requirements = DeriveMasterIntegralEpsilonOrderRequirements[
  request, valuations];

FTAssert[
  "the V2 builder shifts every requested hard-function order by the corresponding coefficient valuation",
  requirements["DataType"] ===
      "MasterIntegralEpsilonOrderRequirements" &&
    requirements["SchemaVersion"] === 2 &&
    requirements["Status"] ===
      "MasterIntegralEpsilonOrderRequirementsDerived" &&
    requirements["RequestedHardFunctionEpsilonOrders"] === {-1, 0, 1} &&
    requirements["Entries"] === {
      <|"MasterIntegralIndex" -> 3,
        "RequiredMasterIntegralEpsilonOrders" -> {1, 2, 3}|>,
      <|"MasterIntegralIndex" -> 8,
        "RequiredMasterIntegralEpsilonOrders" -> {-1, 0, 1}|>,
      <|"MasterIntegralIndex" -> 11,
        "RequiredMasterIntegralEpsilonOrders" -> {-4, -3, -2}|>
    }
];

FTAssert[
  "the result carries explicit mathematical inputs and references rather than discovering project files",
  requirements["MathematicalInputReferences"] === <|
      "HardFunctionEpsilonOrderRequest" -> request["Reference"],
      "HardFunctionMasterCoefficientEpsilonValuations" ->
        valuations["Reference"]
    |> &&
    requirements["MathematicalInputData",
      "HardFunctionEpsilonOrderRequest",
      "RequestedHardFunctionEpsilonOrders"] === {-1, 0, 1} &&
    Length[requirements["MathematicalInputData",
      "HardFunctionMasterCoefficientEpsilonValuations",
      "Entries"]] === 3
];

checks = requirements["Validation", "Checks"];
FTAssert[
  "the validation record re-derives the defining integer-order relation for every master",
  requirements["Validation", "Method"] ===
      "DeterministicIntegerArithmetic" &&
    TrueQ[requirements["Validation", "Exact"]] &&
    TrueQ[requirements["Validation", "Passed"]] &&
    Lookup[checks, "RelationVerified"] === {True, True, True} &&
    Lookup[checks,
      "ReDerivedRequiredMasterIntegralEpsilonOrders"] ===
      {{1, 2, 3}, {-1, 0, 1}, {-4, -3, -2}} &&
    MasterIntegralEpsilonOrderRequirementsQ[requirements]
];

tamperedOrders = ReplacePart[requirements,
  {"Entries", 2, "RequiredMasterIntegralEpsilonOrders"} -> {-1, 0, 2}];
tamperedInput = ReplacePart[requirements,
  {"MathematicalInputData",
    "HardFunctionMasterCoefficientEpsilonValuations", "Entries", 1,
    "HardFunctionCoefficientEpsilonValuation"} -> -1];
tamperedValidation = ReplacePart[requirements,
  {"Validation", "Passed"} -> False];
FTAssert[
  "the predicate re-derives from source data and refuses changed requirements, inputs, or validation",
  ! MasterIntegralEpsilonOrderRequirementsQ[tamperedOrders] &&
    ! MasterIntegralEpsilonOrderRequirementsQ[tamperedInput] &&
    ! MasterIntegralEpsilonOrderRequirementsQ[tamperedValidation]
];

duplicateIndexValuations = Join[valuations, <|
  "Entries" -> Append[valuations["Entries"], First[valuations["Entries"]]]
|>];
nonintegerValuations = ReplacePart[valuations,
  {"Entries", 1, "HardFunctionCoefficientEpsilonValuation"} -> 1/2];
FTAssert[
  "duplicate master indices and noninteger coefficient valuations are refused typed",
  DeriveMasterIntegralEpsilonOrderRequirements[
      request, duplicateIndexValuations]["Status"] ===
        "HardFunctionMasterCoefficientEpsilonValuationsInvalid" &&
    DeriveMasterIntegralEpsilonOrderRequirements[
      request, nonintegerValuations]["Status"] ===
        "HardFunctionMasterCoefficientEpsilonValuationsInvalid"
];

FTAssert[
  "legacy inputs and malformed argument heads are refused distinctly",
  DeriveMasterIntegralEpsilonOrderRequirements[
      Join[request, <|"SchemaVersion" -> 1|>], valuations]["Status"] ===
        "LegacyDifferentialEquationSchemaUnsupported" &&
    DeriveMasterIntegralEpsilonOrderRequirements[
      request, {valuations}]["Status"] ===
        "MasterIntegralEpsilonOrderRequirementInputsNotWellFormed" &&
    ! MasterIntegralEpsilonOrderRequirementsQ[<||>]
];

requestWithoutReference = KeyDrop[request, "Reference"];
valuationsWithoutReference = KeyDrop[valuations, "Reference"];
embeddedOnly = DeriveMasterIntegralEpsilonOrderRequirements[
  requestWithoutReference, valuationsWithoutReference];
FTAssert[
  "in-memory mathematical inputs remain self-validating when external references are not supplied",
  embeddedOnly["MathematicalInputReferences"] === <||> &&
    MasterIntegralEpsilonOrderRequirementsQ[embeddedOnly]
];

FTReport[];
