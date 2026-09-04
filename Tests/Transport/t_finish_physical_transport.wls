#!/usr/bin/env wolframscript

(* Round 10 (T, 2026-09-03): the ONE finished-transport record
   (Design/FinishedTransportContract_2026-09-03.md) on a synthetic two-row
   family whose expansion is computed by hand, independently of the
   composer.  F1 is a constant; dF2 = eps (dx/x + dy/y) F1 (block
   triangular, one letter per variable); T = identity; the physical
   endpoint (x, y) = (2, 1) lies on no letter.  Then exactly
   F2 = c2 + eps c1 [log(x/2) + log y], so
   I_2^(1) = P(c2,1) + P(c1,0) (W_e2 + W_e1 + W_c2 + W_c1) with the four
   one-letter leg words y: 1 -> 1/2 at x = 2 (endpoint second),
   x: 2 -> 3 at y = 1/2 (endpoint first), y: 1/2 -> y at x = 3 (current
   second), x: 3 -> x (current first); every other demanded pair is a
   single named period. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "Transport", "PhysicalBoundaryCampaignAdapter.wl"}]];

x = Symbol["Global`finishX"]; y = Symbol["Global`finishY"]; eps = Symbol["Global`eps"];
family = "FinishToy";
record = <|
  "Status" -> "ExactEpsilonForm", "Family" -> family,
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}, {2}}, "Blocks" -> {{1}, {2}},
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2],
  "EpsFormX" -> eps {{0, 0}, {1/x, 0}}, "EpsFormY" -> eps {{0, 0}, {1/y, 0}},
  "Letters" -> {x, y},
  "DLog" -> <|"Valid" -> True, "Dimension" -> 2, "Variables" -> {x, y}, "Regulator" -> eps,
    "Letters" -> {x, y}, "Residues" -> {{{0, 0}, {1, 0}}, {{0, 0}, {1, 0}}}, "ConstantResidues" -> True|>,
  "ChartRecord" -> <|"CoefficientField" -> "Rational", "Variables" -> {x, y}, "Subst" -> {x -> x, y -> y}, "Roots" -> {}|>,
  "Chart" -> "RationalIdentity",
  "GateVerdict" -> True, "GaugeIdentity" -> True, "Flatness" -> True, "TTotalInvertible" -> True|>;
path = <|"FirstVariable" -> x, "SecondVariable" -> y, "FirstBase" -> 3, "SecondBase" -> 1/2, "FirstTargetSample" -> 4|>;
demand = <|"PhysicalRows" -> {1, 2}, "PhysicalOrders" -> {0, 1}, "PhysicalValuation" -> 0, "Path" -> path|>;
transport = BuildObservableTransport[record, demand, "BoundaryEvolution" -> "AmbientBasePoint", "WordRepresentation" -> "OperatorAutomaton"];
FTAssert["the synthetic family transports as an accepted operator automaton",
  AcceptedObservableTransportQ[transport] && transport["WordRepresentation"] === "OperatorAutomaton"];
transport = Join[transport, <|"DLogLetters" -> record["DLog"]["Letters"], "DLogResidues" -> record["DLog"]["Residues"]|>];

(* the physical endpoint (x, y) = (2, 1): regular, the y letter's pole is at 0 *)
rho = Symbol["Global`finishRho"];
frobeniusSpec = <|"Variable" -> y, "Regulator" -> eps, "LocalVariable" -> rho, "Endpoint" -> 1,
  "LocalDirection" -> -1, "FixedRules" -> {x -> 2}|>;
frobenius = BuildEndpointFrobenius[record["EpsFormY"], frobeniusSpec, "MaximumSeriesOrder" -> 2, "MaximumEpsilonOrder" -> 3];
realizations = Table[<|"PeriodID" -> {family, id}, "PeriodClass" -> "GPL", "PeriodEpsilonValuation" -> 0,
    "CanonicalRows" -> {id}, "PhysicalRows" -> {id}, "ConstraintRows" -> Range[id],
    "DemandedOutputs" -> {{0, 1}, {0, 2}, {1, 1}, {1, 2}}, "EpsilonExponent" -> 0, "IntegerValuation" -> 0, "LogLevel" -> 0|>, {id, 2}];
modeMap = BuildBoundaryModeMap[frobenius, IdentityMatrix[2],
  <|"Family" -> family, "Limit" -> "toyEdge", "FixedRules" -> {x -> 2},
    "PhysicalEndpointRelation" -> <|"Stratum" -> "toyEdge", "LocalPower" -> 1, "LeadingCoefficient" -> 1|>|>, realizations];
modeMap = Join[modeMap, <|"Chart" -> "RationalIdentity", "GaugeConstantRules" -> {},
  "PhysicalEdgePoint" -> <|"Stratum" -> "toyEdge", "Variable" -> y, "Endpoint" -> 1, "LocalDirection" -> -1, "FixedRules" -> {x -> 2}, "LeadingCoefficient" -> 1|>,
  "StructuralPeriodIDs" -> {1, 2}, "CertifiedPeriodIDs" -> {}, "KnownZeroLedgerPeriodIDs" -> {}|>];
FTAssert["the synthetic endpoint has two ordinary zero modes",
  modeMap["Status"] === "BoundaryModeMapBuilt" && Length[modeMap["Modes"]] === 2];
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
finished = FinishPhysicalTransport[family, "Directories" -> <|"EpsilonForm" -> directory, "ObservableTransport" -> directory,
  "BoundaryModes" -> directory, "EndpointTransport" -> directory|>];
If[Lookup[finished, "Status", None] =!= "PhysicalTransportFinished",
  Print["FINISHED: ", InputForm[KeyDrop[finished, {"Expressions", "Terms", "CanonicalExpansions", "ConnectionForCheck", "GradedRecordTermsAtBase", "Letters", "PeriodBasis"}]]]];
FTAssert["the synthetic family is finished with the three certificates and re-verified by the predicate",
  Lookup[finished, "Status", None] === "PhysicalTransportFinished" &&
    finished["Certificates"]["DifferentialEquation"]["Status"] === "DifferentialEquationVerified" &&
    finished["Certificates"]["BoundaryMatching"]["Status"] === "BoundaryMatchingVerified" &&
    finished["Certificates"]["Binding"]["Purity"]["Status"] === "ExpressionsPure" &&
    PhysicalTransportFinishedQ[finished]];

(* the hand expansion, independent of the composer *)
symbolOf[id_, order_] := With[{entry = SelectFirst[Lookup[finished, "PeriodBasis", {}], #["PeriodID"] === {family, id} && #["EpsilonOrder"] === order &, None]},
  If[entry === None, None, entry["Symbol"]]];
prescriptions = Lookup[Lookup[finished, "Path", <||>], "Prescriptions", <||>];
wordCurrentX = TransportIteratedIntegral @@ {{{"GPLPole", 0}}, {x, 3, x}, None, prescriptions["Current"]};
wordCurrentY = TransportIteratedIntegral @@ {{{"GPLPole", 0}}, {y, 1/2, y}, None, prescriptions["Current"]};
wordEndpointX = TransportIteratedIntegral @@ {{{"GPLPole", 0}}, {x, 2, 3}, None, prescriptions["Endpoint"]};
wordEndpointY = TransportIteratedIntegral @@ {{{"GPLPole", 0}}, {y, 1, 1/2}, None, prescriptions["Endpoint"]};
expected = <|{0, 1} -> symbolOf[1, 0], {1, 1} -> symbolOf[1, 1], {0, 2} -> symbolOf[2, 0],
  {1, 2} -> symbolOf[2, 1] + symbolOf[1, 0] (wordEndpointY + wordEndpointX + wordCurrentY + wordCurrentX)|>;
If[Lookup[finished, "Status", None] === "PhysicalTransportFinished",
  Do[If[Together[finished["Expressions"][pair] - expected[pair]] =!= 0,
      Print["PAIR ", pair, " finished: ", InputForm[finished["Expressions"][pair]], " expected: ", InputForm[expected[pair]]]], {pair, Keys[expected]}]];
FTAssert["every demanded pair equals the hand-computed expansion (one-letter words on all four legs, periods by name)",
  Lookup[finished, "Status", None] === "PhysicalTransportFinished" && ! MemberQ[Values[expected], None] &&
    AllTrue[Keys[expected], Together[finished["Expressions"][#] - expected[#]] === 0 &]];
If[Lookup[finished, "Status", None] === "PhysicalTransportFinished",
  Print["PERIODS: ", InputForm[({#["PeriodID"], #["EpsilonOrder"], #["Status"], #["Definition"]["FrobeniusMode"]["CanonicalRows"]} &) /@ finished["PeriodBasis"]],
    " relations ", InputForm[finished["PeriodRelations"]["Relations"]], " unknowns ", finished["PeriodRelations"]["IndependentUnknownCount"]]];
FTAssert["the period table names both boundary data with their Frobenius modes, all unevaluated and independent, with the four hand coordinates present and no relation",
  Lookup[finished, "Status", None] === "PhysicalTransportFinished" &&
    SubsetQ[({#["PeriodID"], #["EpsilonOrder"]} &) /@ finished["PeriodBasis"], {{{family, 1}, 0}, {{family, 1}, 1}, {{family, 2}, 0}, {{family, 2}, 1}}] &&
    finished["PeriodRelations"]["Relations"] === {} &&
    finished["PeriodRelations"]["IndependentUnknownCount"] === Length[finished["PeriodBasis"]] &&
    AllTrue[finished["PeriodBasis"], #["Status"] === "Unevaluated" && #["Definition"]["Family"] === family &&
      #["Definition"]["FrobeniusMode"]["CanonicalRows"] === {#["PeriodID"][[2]]} &]];
tampered = If[AssociationQ[finished] && KeyExistsQ[finished, "Expressions"],
  Join[finished, <|"Expressions" -> Join[finished["Expressions"], <|{1, 2} -> finished["Expressions"][{1, 2}] + Symbol["Global`leaked$1"]|>]|>], <||>];
FTAssert["a leaked symbol or a changed status is refused by the predicate",
  ! PhysicalTransportFinishedQ[tampered] && ! PhysicalTransportFinishedQ[Join[finished, <|"Status" -> "PhysicalTransportIncomplete"|>]]];
DeleteDirectory[directory, DeleteContents -> True];
FTReport[];
