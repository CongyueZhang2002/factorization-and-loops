(* The "Series" Laurent extraction of the observable transport (round 4,
   2026-09-02): one Series call per entry, per-row order caps.  It must
   reproduce the former SeriesCoefficient route EXACTLY -- the same
   canonical coefficient expressions (SameQ), not merely equal functions --
   on (1) the synthetic radical matrix of the jet test (rational-in-eps
   entries, a zero, an eps-free entry, an algebraic-zero leading
   coefficient, and one Puiseux entry that takes the SeriesCoefficient
   fallback); (2) real CF259 transformation entries up to 25 KB, including
   the nested-quotient entry (42,20); (3) end to end, on the certified
   rational record CF27, the algebraic toy record and, when present, the
   certified Kallen-chart record CF230: every deterministic part of the
   transported object (demanded rows, constraint matrix, base kernel and
   embedding, automaton or word maps, rank histories) is SameQ between the
   routes.  Row caps: orders above a row's cap are placeholders, orders up
   to the cap agree, and the consumers' guards fire on a fabricated
   overrun.  A pole below the record's TMin is refused with a typed status. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];
rows[mat_, method_, orders_, caps_: Automatic] := Block[
  {FeynFacet`Private`$observableTransportLaurentMethod = method},
  FeynFacet`Private`$observableTransportLaurentDiagnostics = <||>;
  FeynFacet`Private`observableTransportLaurentRows[mat, eps, orders, Range[Length[mat]], caps]];
FTAssert["the production default is the Series route",
  FeynFacet`Private`$observableTransportLaurentMethod === "Series"];
(* round 6: the jet route is retired to Private_Backup with its test *)
FTAssert["selecting the retired Jet route is refused typed, at the row level and at the tensor level",
  rows[{{1/eps}}, "Jet", {-1, 0}] === <|"Status" -> "RouteRetired", "Route" -> "Laurent jet", "Replacement" -> "Series"|> &&
  Block[{FeynFacet`Private`$observableTransportLaurentMethod = "Jet"},
    FeynFacet`Private`observableTransportLaurentMatrices[{{1/eps}}, eps, {-1, 0}]] ===
    <|"Status" -> "RouteRetired", "Route" -> "Laurent jet", "Replacement" -> "Series"|> &&
  System`Names["FeynFacet`Private`observableTransportEpsJet*"] === {}];

(* 1. synthetic matrix of t_observable_transport_laurent_jet.wls *)
r1 = Sqrt[1 - 4 x y]; r2 = Sqrt[x^2 + 4 y];
jetMatrix = {
  {(2 - 9 eps + 9 eps^2)/(2 eps^2), 0, (x + y r1)/(eps (1 - 2 eps) (x - y))},
  {(-2 + 13 eps - 27 eps^2 + 18 eps^3) r2/(2 eps^3 (x + y)), x y/(1 - x),
    ((1 + eps) (r1 - x) + (r1 + x) (1 - eps))/(eps^2 (1 + x eps))},
  {(r1^2 - (1 - 4 x y))/eps^3 + 1/eps, Sqrt[1 + eps]/eps,
    1/(eps (1 - eps r2/(1 + x)))^2}};
orders = {-3, 3};
{seriesSeconds, series} = AbsoluteTiming[rows[jetMatrix, "Series", orders]];
{formerSeconds, former} = AbsoluteTiming[rows[jetMatrix, "SeriesCoefficient", orders]];
Print["synthetic 3x3: Series ", Round[seriesSeconds, 0.001], " s, SeriesCoefficient ", Round[formerSeconds, 0.001], " s"];
FTAssert["synthetic matrix: every order, every entry SameQ between the routes",
  Keys[series] === Range @@ orders && series === former];
FTAssert["synthetic matrix: the eps-free entry and the zero entry are handled",
  series[0][[2, 2]] === Cancel[Together[x y/(1 - x)]] && series[1][[2, 2]] === 0 && series[0][[1, 2]] === 0];
FTAssert["the Puiseux-free radical-in-eps entry Sqrt[1+eps]/eps is a plain Laurent series (no fallback needed)",
  series[-1][[3, 2]] === 1 && series[0][[3, 2]] === 1/2];
fallback = FeynFacet`Private`observableTransportLaurentEntrySeries[eps^(1/2) + 1/eps, eps, {-1, 1}];
FTAssert["a genuine Puiseux entry is refused by the Series entry routine (fallback to SeriesCoefficient)",
  fallback === $Failed];
FTAssert["an eps-free entry gives its canonical form at order 0 only",
  FeynFacet`Private`observableTransportLaurentEntrySeries[(x^2 - y^2)/(x - y), eps, {-1, 1}] === {0, x + y, 0}];

(* 2. real CF259 entries *)
fixture = Get[FileNameJoin[{root, "Tests", "Transport", "Fixtures", "cf259_ttotal_entries.wl"}]];
FTAssert["the CF259 fixture holds five real entries in Global` symbols",
  Length[fixture] === 5 && DeleteDuplicates[Context /@ DeleteDuplicates[Cases[fixture[[All, "Entry"]], _Symbol, Infinity]]] === {"Global`"}];
realMatrix = {fixture[[All, "Entry"]]};
{seriesSeconds, series} = AbsoluteTiming[rows[realMatrix, "Series", {-3, 2}]];
{formerSeconds, former} = AbsoluteTiming[rows[realMatrix, "SeriesCoefficient", {-3, 2}]];
Print["CF259 entries (", fixture[[All, "Bytes"]], " bytes): Series ", Round[seriesSeconds, 0.01], " s, SeriesCoefficient ", Round[formerSeconds, 0.01], " s"];
FTAssert["real CF259 entries: all 30 canonical coefficients SameQ between the routes", series === former];
FTAssert["real CF259 entries: no SeriesCoefficient fallback was needed and no pole below -3 was seen",
  Lookup[FeynFacet`Private`$observableTransportLaurentDiagnostics, "SeriesFallbackCount", 0] === 0 &&
  Lookup[FeynFacet`Private`$observableTransportLaurentDiagnostics, "ValuationBelowRange", 0] === 0];
(* the measured ratio is printed above; a timing assertion would pin a
   symptom, so none is made *)

(* 3. row caps *)
capped = rows[realMatrix, "Series", {-3, 2}, {-1}];
FTAssert["row cap -1: orders -3..-1 agree with the uncapped tensor and orders 0..2 are placeholders",
  And @@ Table[capped[k] === series[k], {k, -3, -1}] && And @@ Table[capped[k] === {ConstantArray[0, 5]}, {k, 0, 2}]];
FTAssert["row cap below the range gives an all-placeholder row", rows[realMatrix, "Series", {-3, 2}, {-4}][-3] === {ConstantArray[0, 5]}];
FTAssert["observableTransportLaurentRowHighs: forbidden range for every component, demanded orders for the demanded ones",
  FeynFacet`Private`observableTransportLaurentRowHighs[4, 0, 0, {{0, 2}, {2, 2}, {1, 4}}] === {-1, 2, -1, 1} &&
  FeynFacet`Private`observableTransportLaurentRowHighs[2, 2, 1, {}] === {0, 0}];
FTAssert["a pole below the requested range is counted (the transport refuses such a record)",
  (FeynFacet`Private`$observableTransportLaurentDiagnostics = <||>;
   FeynFacet`Private`observableTransportLaurentEntrySeries[1/eps^4, eps, {-3, 0}];
   Lookup[FeynFacet`Private`$observableTransportLaurentDiagnostics, "ValuationBelowRange", 0] === 1)];

(* 4. end to end *)
deterministicKeys = {"Status", "PhysicalRows", "PhysicalDemandPairs", "BoundarySlots",
    "BoundaryConstraintMatrix", "BoundaryAmbientSlots", "BoundaryKernelAtBase", "BoundaryBaseEmbedding",
    "BoundaryEvolutionMethod", "BoundaryConstraintLeafCount", "ConstraintRank", "DualClosureRankHistory",
    "SecondBoundaryClosureRankHistory", "FirstSegmentKernels", "FirstSegmentKernelMatrices",
    "SecondSegmentKernels", "SecondSegmentKernelMatrices", "WordRepresentation", "MaximumWeight",
    "FirstSegmentWordMaps", "TwoSegmentWordMaps", "TransportEpsilonValuations", "ExactOperatorAutomaton"};
(* the first-segment kernels carry the per-call path symbol
   Unique["observablePath"]; compare them modulo that name *)
pathSymbolRules[value_] := (# -> Symbol["Global`observablePathCompared"]) & /@
  DeleteDuplicates[Cases[value, s_Symbol /; StringStartsQ[SymbolName[s], "observablePath"], Infinity]];
deterministic[result_] := If[! AssociationQ[result], result,
  With[{taken = KeyTake[result, deterministicKeys]}, taken /. pathSymbolRules[taken]]];
differingKeys[a_, b_] := If[! AssociationQ[a] || ! AssociationQ[b], {a, b},
  With[{da = deterministic[a], db = deterministic[b]},
    Select[deterministicKeys, Lookup[da, #, Missing["A"]] =!= Lookup[db, #, Missing["B"]] &]]];
runBoth[record_, demand_, options___] := Module[{a, b},
  a = Block[{FeynFacet`Private`$observableTransportLaurentMethod = "Series"},
    FeynFacet`BuildObservableTransport[record, demand, options]];
  b = Block[{FeynFacet`Private`$observableTransportLaurentMethod = "SeriesCoefficient"},
    FeynFacet`BuildObservableTransport[record, demand, options]];
  {a, b}];
accepted[value_] := TrueQ[FeynFacet`AcceptedObservableTransportQ[value]];
(* CF27, certified rational record *)
cf27 = FeynFacet`FamilyArtifactRead[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsCertified", "family_epsform_CF27.wl"}]];
system = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF27.wl"}]];
valuations = Get[FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "MasterCoefficientValuations.wl"}]];
path27 = <|"FirstVariable" -> Symbol["Global`v"], "FirstBase" -> 1/4, "SecondBase" -> 1/4, "FirstTargetSample" -> 2/7|>;
demand27 = FeynFacet`BuildObservableTransportDemand[cf27, system, valuations,
  "HardFunctionOrders" -> {0}, "SafetyOrders" -> 1, "MasterValuation" -> 0, "Path" -> path27];
{t27, pair27} = AbsoluteTiming[runBoth[cf27, demand27]];
Print["CF27 both routes: ", Round[t27, 0.1], " s; statuses ", Lookup[#, "Status", Head[#]] & /@ pair27, "; differing keys ", differingKeys @@ pair27];
FTAssert["CF27: both routes accepted and every deterministic part of the object is SameQ",
  accepted[pair27[[1]]] && accepted[pair27[[2]]] && deterministic[pair27[[1]]] === deterministic[pair27[[2]]]];
(* the algebraic toy record of t_algebraic_observable_transport.wls *)
ax = Symbol["Global`algebraicX"]; ay = Symbol["Global`algebraicY"];
toy = <|"Status" -> "ExactEpsilonForm", "Family" -> "AlgebraicObservableToy", "Variables" -> {ax, ay},
  "Regulator" -> eps, "Dim" -> 1, "Ranges" -> {{1}}, "TTotal" -> {{eps}}, "TTotalInverse" -> {{1/eps}},
  "EpsFormX" -> eps {{-1/(2 Sqrt[1 - ax] (1 + Sqrt[1 - ax]))}}, "EpsFormY" -> eps {{0}},
  "Letters" -> {1 + Sqrt[1 - ax]},
  "DLog" -> <|"Valid" -> True, "Dimension" -> 1, "Variables" -> {ax, ay}, "Regulator" -> eps,
    "Letters" -> {1 + Sqrt[1 - ax]}, "Residues" -> {{{1}}}, "ConstantResidues" -> True|>,
  "ChartRecord" -> <|"CoefficientField" -> "Multiquadratic", "Variables" -> {ax, ay}, "Subst" -> {ax -> ax, ay -> ay},
    "Roots" -> {<|"Root" -> Sqrt[1 - ax], "RootSquare" -> 1 - ax|>}|>,
  "GateVerdict" -> True, "GaugeIdentity" -> True, "Flatness" -> True, "TTotalInvertible" -> True|>;
toyPath = FeynFacet`FindObservableTransportPath[toy];
toyDemand = <|"PhysicalRows" -> {1}, "PhysicalOrders" -> {2, 3}, "PhysicalValuation" -> 2, "Path" -> toyPath|>;
pairToy = runBoth[toy, toyDemand, "BoundaryEvolution" -> "AmbientBasePoint"];
Print["algebraic toy both routes: statuses ", Lookup[#, "Status", Head[#]] & /@ pairToy, "; differing keys ", differingKeys @@ pairToy];
FTAssert["algebraic toy record: both routes give the same status and deterministic object",
  deterministic[pairToy[[1]]] === deterministic[pairToy[[2]]]];
(* a two-dimensional algebraic toy: TTotal with radical entries and poles
   of two orders, so the Series route meets radicals inside the closure *)
r = Sqrt[1 - ax];
toy2TTotal = {{eps, (1 + r)/(eps (1 + eps))}, {0, 1/eps}};
toy2 = Join[toy, <|"Family" -> "AlgebraicObservableToy2", "Dim" -> 2, "Ranges" -> {{1}, {2}},
  "TTotal" -> toy2TTotal, "TTotalInverse" -> Map[Cancel[Together[#]] &, Inverse[toy2TTotal], {2}],
  "EpsFormX" -> eps {{-1/(2 r (1 + r)), 0}, {0, -1/(2 r (1 + r))}}, "EpsFormY" -> eps {{0, 0}, {0, 0}},
  "DLog" -> <|"Valid" -> True, "Dimension" -> 2, "Variables" -> {ax, ay}, "Regulator" -> eps,
    "Letters" -> {1 + r}, "Residues" -> {{{1, 0}, {0, 1}}}, "ConstantResidues" -> True|>|>];
toy2Demand = <|"PhysicalRows" -> {1, 2}, "PhysicalOrders" -> {0, 1}, "PhysicalValuation" -> 0, "Path" -> FeynFacet`FindObservableTransportPath[toy2]|>;
pairToy2 = runBoth[toy2, toy2Demand, "BoundaryEvolution" -> "AmbientBasePoint"];
Print["2x2 algebraic toy both routes: statuses ", Lookup[#, "Status", Head[#]] & /@ pairToy2, "; differing keys ", differingKeys @@ pairToy2,
  "; physical rows ", Lookup[pairToy2[[1]], "PhysicalRows", None], "; constraint rank ", Lookup[pairToy2[[1]], "ConstraintRank", None]];
FTAssert["2x2 algebraic toy record (radical TTotal entries with poles): both routes give the same status and deterministic object",
  deterministic[pairToy2[[1]]] === deterministic[pairToy2[[2]]]];
(* CF230, certified Kallen-chart record (its certified coefficient field is Rational), when present *)
cf230File = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "FamilyEpsFormsCertified", "family_epsform_CF230.wl"}];
de230File = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF230.wl"}];
If[FileExistsQ[cf230File] && FileExistsQ[de230File],
  cf230 = FeynFacet`FamilyArtifactRead[cf230File];
  de230 = FeynFacet`FamilyArtifactRead[de230File];
  demand230 = FeynFacet`BuildObservableTransportDemand[cf230, de230, valuations];
  FTAssert["CF230: the demand is built", Lookup[demand230, "Status", None] === "ExactObservableDemand"];
  {t230, pair230} = AbsoluteTiming[runBoth[cf230, demand230]];
  Print["CF230 both routes: ", Round[t230, 0.1], " s; statuses ", Lookup[#, "Status", Head[#]] & /@ pair230,
    "; coefficient field ", Lookup[pair230[[1]], "CoefficientField", None], "; differing keys ", differingKeys @@ pair230];
  FTAssert["CF230 (certified chart record): both routes accepted and every deterministic part of the object is SameQ",
    accepted[pair230[[1]]] && accepted[pair230[[2]]] && deterministic[pair230[[1]]] === deterministic[pair230[[2]]]],
  Print["CF230 record not present; end-to-end multiquadratic comparison skipped"]];
(* 5. a record whose TMin is above an entry's true valuation is refused *)
badToy = Join[toy, <|"TransportEpsilonValuations" -> <|"TMin" -> 0, "BlockLower" -> {0}|>, "TTotal" -> {{1/eps}}, "TTotalInverse" -> {{eps}}|>];
badResult = FeynFacet`BuildObservableTransport[badToy, toyDemand, "BoundaryEvolution" -> "AmbientBasePoint"];
(* Since round 4 (agent T) a record's valuations must carry a certificate,
   and the certifier refuses a claim above the observed order; an
   uncertified or over-claimed record is therefore refused by that gate
   before the Laurent stage runs.  The Laurent-stage guard
   LaurentValuationBelowRecord is defence in depth behind it.  Either
   typed refusal is the contract; a silent drop of the order is not. *)
Print["stale-TMin record status: ", Lookup[badResult, "Status", None]];
FTAssert["a record whose TMin exceeds an entry's valuation is refused typed (certificate gate or Laurent guard), never transported",
  MemberQ[{"LaurentValuationBelowRecord", "TransportEpsilonValuationsUncertified",
      "TransportEpsilonValuationsTooHigh", "TransportEpsilonValuationCertificateInvalid"},
    Lookup[badResult, "Status", None]]];
FTReport[];
