#!/usr/bin/env wolframscript

(* Round 10 (T, 2026-09-03): the complete master-integral solution record
   (Design/FinishedTransportContract_2026-09-03.md) on a synthetic two-row
   family whose expansion is computed by hand, independently of the
   composer.  F1 is a constant; dF2 = eps (dx/x + dy/y) F1 (block
   triangular, one letter per variable); T = identity; the physical
   endpoint (x, y) = (2, 1) lies on no letter.  Then exactly
   F2 = c2 + eps c1 [log(x/2) + log y], so
   I_2^(1) = C(c2,1) + C(c1,0) (I_e2 + I_e1 + I_c2 + I_c1), where the four
   one-letter iterated integrals run along y: 1 -> 1/2 at x = 2,
   x: 2 -> 3 at y = 1/2, y: 1/2 -> y at x = 3, and x: 3 -> x.
   Every other demanded pair is a single named boundary constant. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport", "PhysicalBoundaryCampaignAdapter.wl"}]];

FTAssert["the endpoint composer uses boundary-data coefficients and exports no period alias",
  NameQ["FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonBoundaryCoefficientMaps"] &&
    ! NameQ["FeynFacetCampaign`PhysicalBoundary`ComposeEndpointAutomatonPeriodWords"]];

x = Symbol["Global`finishX"]; y = Symbol["Global`finishY"]; eps = Symbol["Global`eps"];
family = "FinishToy";
candidate = <|
  "Family" -> family,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}, {2}}, "Blocks" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> eps {{0, 0}, {1/x, 0}}, "EpsFormY" -> eps {{0, 0}, {1/y, 0}},
  "Letters" -> {x, y}|>;
system = <|"Family" -> family,
  "Av" -> candidate["EpsFormX"],
  "Aw" -> candidate["EpsFormY"]|>;
record = ValidateFamilyDLogEpsilonForm[candidate, system,
  "SourceVariables" -> {x, y}, "IdentityMethod" -> "Symbolic"];
If[Lookup[record, "Status", None] =!=
    "FamilyDLogEpsilonFormValidated",
  Print["FORM: ", InputForm[record]]];
record = Join[KeyDrop[record, "IrreducibleDiagonalBlocks"],
  <|"BlockDecomposition" -> <|
    "DataType" -> "FamilyDifferentialSystemBlockDecomposition",
    "SchemaVersion" -> 2,
    "FamilyDifferentialSystemReference" -> <|
      "RelativePath" -> "finish_toy_system.wl",
      "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
      "Family" -> family|>,
    "IrreducibleDiagonalBlocks" -> {{1}, {2}}|>|>];
path = <|"FirstVariable" -> x, "SecondVariable" -> y, "FirstBase" -> 3, "SecondBase" -> 1/2, "FirstTargetSample" -> 4|>;
demand = <|"PhysicalRows" -> {1, 2}, "PhysicalOrders" -> {0, 1}, "PhysicalValuation" -> 0, "Path" -> path|>;
transport = BuildObservableTransport[record, demand, "BoundaryEvolution" -> "AmbientBasePoint", "WordRepresentation" -> "OperatorAutomaton"];
If[! AcceptedObservableTransportQ[transport],
  Print["TRANSPORT: ", InputForm[transport]]];
FTAssert["the synthetic family transports as an accepted operator automaton",
  AcceptedObservableTransportQ[transport] && transport["WordRepresentation"] === "OperatorAutomaton"];
transport = Join[transport, <|
  "DLogLetters" -> record["Letters"],
  "DLogResidues" -> record["ConstantResidueMatrices"]|>];

(* the physical endpoint (x, y) = (2, 1): regular, the y letter's pole is at 0 *)
rho = Symbol["Global`finishRho"];
frobeniusSpec = <|"Variable" -> y, "Regulator" -> eps, "LocalVariable" -> rho,
  "LocalExpansionPoint" -> 1,
  "LocalDirection" -> -1, "FixedRules" -> {x -> 2}|>;
frobenius = ComputeTruncatedLocalFrobeniusExpansion[candidate["EpsFormY"],
  frobeniusSpec, "MaximumSeriesOrder" -> 2,
  "MaximumEpsilonOrder" -> 3];
If[Lookup[frobenius, "Status", None] =!=
    "TruncatedLocalFrobeniusExpansionComputed",
  Print["FROBENIUS: ", InputForm[frobenius]]];
realizations = Table[<|"BoundaryConstantID" -> {family, id},
    "FrobeniusModeID" -> {family, id},
    "DeclaredBoundaryConstantAnalyticClass" -> "GPL",
    "BoundaryConstantEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id}, "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> {{0, 1}, {0, 2}, {1, 1}, {1, 2}}, "EpsilonExponent" -> 0, "IntegerValuation" -> 0, "LogLevel" -> 0|>, {id, 2}];
modeMap = MatchBoundaryAsymptoticsToFrobeniusModes[frobenius, IdentityMatrix[2],
  <|"Family" -> family, "Limit" -> "toyEdge", "FixedRules" -> {x -> 2},
    "BoundaryDomain" -> <|"Type" -> "PhysicalBoundaryPoint",
      "Coordinates" -> {x -> 2, y -> 1}|>,
    "PhysicalEndpointRelation" -> <|"Stratum" -> "toyEdge", "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>, realizations];
modeMap = Join[modeMap, <|"Chart" -> "RationalIdentity"|>];
If[Lookup[modeMap, "Status", None] =!= "BoundaryAsymptoticModeMatching",
  Print["MODES: ", InputForm[modeMap]]];
FTAssert["the synthetic endpoint has two ordinary zero modes",
  modeMap["Status"] === "BoundaryAsymptoticModeMatching" &&
    Length[modeMap["FrobeniusModes"]] === 2];
endpoint = FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[transport, modeMap, <||>];
If[Lookup[endpoint, "Status", None] =!= "GradedPhysicalEndpointTransportBuilt", Print["ENDPOINT: ", InputForm[endpoint]]];
FTAssert["the synthetic graded endpoint record builds",
  Lookup[endpoint, "Status", None] === "GradedPhysicalEndpointTransportBuilt"];

directory = FileNameJoin[{$TemporaryDirectory, "finish_toy_" <> ToString[$ProcessID]}];
CreateDirectory[directory];
Put[record, FileNameJoin[{directory, "family_epsform_" <> family <> ".wl"}]];
Put[transport, FileNameJoin[{directory, "observable_transport_" <> family <> ".wl"}]];
Put[modeMap, FileNameJoin[{directory, "boundary_mode_" <> family <> ".wl"}]];
Put[endpoint, FileNameJoin[{directory, "physical_endpoint_transport_" <> family <> ".wl"}]];
inputFiles = <|
  "FamilyDLogEpsilonForm" ->
    FileNameJoin[{directory, "family_epsform_" <> family <> ".wl"}],
  "IteratedIntegralCoefficientOperatorForRequestedOutputs" ->
    FileNameJoin[{directory, "observable_transport_" <> family <> ".wl"}],
  "BoundaryAsymptoticModeMatching" ->
    FileNameJoin[{directory, "boundary_mode_" <> family <> ".wl"}],
  "RegularizedBoundaryToBasePointEvolutionOperator" ->
    FileNameJoin[{directory,
      "physical_endpoint_transport_" <> family <> ".wl"}]|>;
solution = ConstructMasterIntegralSolution[family,
  "InputFiles" -> inputFiles];
If[Lookup[solution, "Status", None] =!= "MasterIntegralSolutionConstructed",
  Print["SOLUTION: ", InputForm[KeyDrop[solution, {"Expressions", "Terms", "CanonicalExpansions",
    "ConnectionForCheck", "GradedRecordTermsAtBase", "Letters", "BoundaryConstantTable"}]]]];
If[Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed" &&
    ! MasterIntegralSolutionQ[solution],
  Print["SOLUTION VALIDATION: ", InputForm[<|
    "DataType" -> Lookup[solution, "DataType", None],
    "SchemaVersion" -> Lookup[solution, "SchemaVersion", None],
    "DemandCoverage" -> Lookup[solution, "DemandCoverage", None],
    "BoundaryDataStatus" -> Lookup[solution, "BoundaryDataStatus", None],
    "Certificates" -> Lookup[solution, "Certificates", <||>]|>]]];
FTAssert["the synthetic family has a complete boundary-constant solution with three validation records",
  Lookup[solution, "DataType", None] === "MasterIntegralSolution" &&
    Lookup[solution, "SchemaVersion", None] === 2 &&
    Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed" &&
    Lookup[solution, "DemandCoverage", None] === "Complete" &&
    Lookup[solution, "BoundaryDataStatus", None] === "Undetermined" &&
    solution["Certificates"]["DifferentialEquation"]["Status"] === "DifferentialEquationVerifiedSymbolically" &&
    solution["Certificates"]["BoundaryMatching"]["Status"] === "BoundaryMatchingVerified" &&
    solution["Certificates"]["ExpressionPurity"]["Status"] === "ExpressionsPure" &&
    MasterIntegralSolutionQ[solution]];

(* the hand expansion, independent of the composer *)
boundaryConstantSymbol[id_, order_] := With[{entry = SelectFirst[Lookup[solution, "BoundaryConstantTable", {}],
    #["BoundaryConstantID"] === {family, id} && #["EpsilonOrder"] === order &, None]},
  If[entry === None, None, entry["Symbol"]]];
prescriptions = Lookup[Lookup[solution, "Path", <||>], "Prescriptions", <||>];
integralCurrentX = FormalChenIteratedIntegral @@ {{{"GPLPole", 0}}, {x, 3, x}, None, prescriptions["Current"]};
integralCurrentY = FormalChenIteratedIntegral @@ {{{"GPLPole", 0}}, {y, 1/2, y}, None, prescriptions["Current"]};
integralBoundaryX = FormalChenIteratedIntegral @@ {{{"GPLPole", 0}}, {x, 2, 3}, None, prescriptions["Endpoint"]};
integralBoundaryY = FormalChenIteratedIntegral @@ {{{"GPLPole", 0}}, {y, 1, 1/2}, None, prescriptions["Endpoint"]};
expected = <|{0, 1} -> boundaryConstantSymbol[1, 0], {1, 1} -> boundaryConstantSymbol[1, 1],
  {0, 2} -> boundaryConstantSymbol[2, 0],
  {1, 2} -> boundaryConstantSymbol[2, 1] + boundaryConstantSymbol[1, 0]
    (integralBoundaryY + integralBoundaryX + integralCurrentY + integralCurrentX)|>;
If[Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed",
  Do[If[Together[solution["Expressions"][pair] - expected[pair]] =!= 0,
      Print["PAIR ", pair, " solution: ", InputForm[solution["Expressions"][pair]],
        " expected: ", InputForm[expected[pair]]]], {pair, Keys[expected]}]];
FTAssert["every demanded pair equals the hand-computed expansion in boundary constants and four one-letter iterated integrals",
  Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed" &&
    ! MemberQ[Values[expected], None] &&
    AllTrue[Keys[expected], Together[solution["Expressions"][#] - expected[#]] === 0 &]];
If[Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed",
  Print["BOUNDARY CONSTANTS: ", InputForm[({#["BoundaryConstantID"], #["EpsilonOrder"], #["Status"],
      #["Definition"]["FrobeniusMode"]["CanonicalRows"]} &) /@ solution["BoundaryConstantTable"]],
    " relations ", InputForm[
      solution["BoundaryConstantRelations"]["BoundaryRelations"]],
    " unknowns ", solution["BoundaryConstantRelations"]["IndependentUnknownCount"]]];
FTAssert["the boundary-constant table names both constants and their Frobenius modes, all unevaluated and independent, with the four epsilon coefficients present and no relation",
  Lookup[solution, "Status", None] === "MasterIntegralSolutionConstructed" &&
    SubsetQ[({#["BoundaryConstantID"], #["EpsilonOrder"]} &) /@ solution["BoundaryConstantTable"],
      {{{family, 1}, 0}, {{family, 1}, 1}, {{family, 2}, 0}, {{family, 2}, 1}}] &&
    solution["BoundaryConstantRelations"]["BoundaryRelations"] === {} &&
    solution["BoundaryConstantRelations"]["IndependentUnknownCount"] === Length[solution["BoundaryConstantTable"]] &&
    AllTrue[solution["BoundaryConstantTable"], #["Status"] === "Unevaluated" &&
      #["Definition"]["Family"] === family &&
      #["Definition"]["FrobeniusMode"]["CanonicalRows"] === {#["BoundaryConstantID"][[2]]} &]];
modularSolution = ConstructMasterIntegralSolution[family,
  "InputFiles" -> inputFiles,
  "DifferentialEquationCheck" -> "Modular", "ModularPoints" -> 2,
  "ModularPrimeCount" -> 2];
FTAssert["finite-field sampling is identified as probabilistic modular validation rather than symbolic verification",
  Lookup[modularSolution, "Status", None] === "MasterIntegralSolutionConstructed" &&
    modularSolution["Certificates"]["DifferentialEquation"]["Status"] ===
      "DifferentialEquationValidatedAtFiniteFieldSamplePoints" &&
    modularSolution["Certificates"]["DifferentialEquation"]["ValidationStrength"] ===
      "ProbabilisticFiniteFieldSampling" &&
    MasterIntegralSolutionQ[modularSolution]];
tampered = If[AssociationQ[solution] && KeyExistsQ[solution, "Expressions"],
  Join[solution, <|"Expressions" -> Join[solution["Expressions"],
    <|{1, 2} -> solution["Expressions"][{1, 2}] + Symbol["Global`leaked$1"]|>]|>], <||>];
FTAssert["a leaked symbol or a changed status is refused by the predicate",
  ! MasterIntegralSolutionQ[tampered] &&
    ! MasterIntegralSolutionQ[
      Join[solution, <|"Status" -> "MasterIntegralSolutionIncomplete"|>]]];

(* Both path segments are part of the same differential-system solution.
   Altering the second-segment coefficient operator must therefore be caught
   just as altering the first segment would be. *)
tamperedSecondOperator = ReplacePart[modularSolution,
  {"StructuralCheckData", "ExactOperatorAutomaton",
      "SecondOperatorMatrices", 1, 1, 1} ->
    modularSolution["StructuralCheckData", "ExactOperatorAutomaton",
      "SecondOperatorMatrices", 1, 1, 1] + 1];
FTAssert["the structural differential-equation validation covers the second path segment",
  ! MasterIntegralSolutionQ[tamperedSecondOperator]];

(* A missing lower epsilon coefficient is allowed only below a proven
   valuation.  This fixture couples solely through the second variable, so
   it detects an asymmetric first/second-equation implementation. *)
secondVariableOnlyForm = <|
  "BlockDecomposition" -> record["BlockDecomposition"],
  "BasisTransformationMatrix" -> IdentityMatrix[2],
  "CoefficientVariables" -> {x, y}, "DimensionalRegulator" -> eps,
  "Letters" -> {y},
  "ConstantResidueMatrices" -> {{{0, 0}, {1, 0}}}|>;
missingSecondVariableLower =
  Catch[FeynFacet`Private`finishDifferentialCertificate[
    <|{1, 2} -> <||>|>, {{1, 2}}, secondVariableOnlyForm,
    <|"Regulator" -> eps, "TransportEpsilonValuations" -> <||>|>,
    <|"CurrentFirst" -> <|"Variable" -> x, "From" -> 2|>,
      "CurrentSecond" -> <|"Variable" -> y|>|>, "Method" -> "Exact",
    "Variables" -> {x, y}]];
FTAssert["a missing lower coefficient in the second differential equation is refused",
  Lookup[missingSecondVariableLower, "Status", None] ===
    "DifferentialEquationValidationFailed" &&
    Lookup[First[missingSecondVariableLower["Failures"]], "Equation", None] === y];
DeleteDirectory[directory, DeleteContents -> True];
FTReport[];
