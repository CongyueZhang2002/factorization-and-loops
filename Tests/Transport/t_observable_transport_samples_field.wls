#!/usr/bin/env wolframscript

(* Round 4 (2026-09-02), Codex review points 3 and 4 on the observable
   transport.
   (3) When the fraction grid cannot supply the requested number of
       admissible rank or residue samples for an algebraic record, the
       transport must stop with a typed exhaustion status (sample kind,
       requested and available counts); the former code kept the
       original samples, some of them proved inadmissible.
   (4) The coefficient field: a transport-ready record must declare it
       (typed refusal otherwise), and the legacy inference for older
       records inspects every computational field, not only Letters and
       TTotal; FindObservableTransportPath refuses instead of assuming
       "Rational". *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`sampleX"];
y = Symbol["Global`sampleY"];
eps = Symbol["Global`eps"];
grid = FeynFacet`Private`$observableTransportSampleFractions;

(* the 1x1 algebraic fixture of t_algebraic_observable_transport with one
   extra letter of zero residue, which leaves the connection unchanged but
   enters the admissibility test of the samples *)
toy[extraLetter_] := <|
  "Status" -> "ExactEpsilonForm",
  "Family" -> "SampleExhaustionToy",
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Dim" -> 1,
  "Ranges" -> {{1}},
  "TTotal" -> {{eps}},
  "TTotalInverse" -> {{1/eps}},
  "EpsFormX" -> eps {{-1/(2 Sqrt[1 - x] (1 + Sqrt[1 - x]))}},
  "EpsFormY" -> eps {{0}},
  "Letters" -> {1 + Sqrt[1 - x], extraLetter},
  "DLog" -> <|
    "Valid" -> True,
    "Dimension" -> 1,
    "Variables" -> {x, y},
    "Regulator" -> eps,
    "Letters" -> {1 + Sqrt[1 - x], extraLetter},
    "Residues" -> {{{1}}, {{0}}},
    "ConstantResidues" -> True|>,
  "ChartRecord" -> <|"CoefficientField" -> "Multiquadratic",
    "Variables" -> {x, y}, "Subst" -> {x -> x, y -> y},
    "Roots" -> {<|"Root" -> Sqrt[1 - x], "RootSquare" -> 1 - x|>}|>,
  "GateVerdict" -> True,
  "GaugeIdentity" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True
|>;
(* the base point y = 1/4 is not on the grid; x = 1/4 -> 2/7 *)
path = <|"FirstVariable" -> x, "SecondVariable" -> y,
  "FirstBase" -> 1/4, "SecondBase" -> 1/4, "FirstTargetSample" -> 2/7|>;
demand = <|"PhysicalRows" -> {1}, "PhysicalOrders" -> {2, 3},
  "PhysicalValuation" -> 2, "Path" -> path|>;
killY = Times @@ ((y - #) & /@ grid);
killX = Times @@ ((x - #) & /@ grid);
FTAssert["the fixture with an innocuous extra letter is an exact record and transports",
  ExactFamilyEpsilonFormQ[toy[1 + y]] &&
    BuildObservableTransport[toy[1 + y], demand,
      "BoundaryEvolution" -> "AmbientBasePoint"]["Status"] ===
      "ModularlyVerifiedObservableTransport"];
rankExhausted = BuildObservableTransport[toy[killY], demand,
  "BoundaryEvolution" -> "AmbientBasePoint"];
FTAssert["a letter vanishing at every grid value of the second variable exhausts the rank samples (typed)",
  Lookup[rankExhausted, "Status", None] === "AdmissibleSamplesExhausted" &&
    rankExhausted["SampleKind"] === "Rank" &&
    rankExhausted["Requested"] === 3 && rankExhausted["Available"] === 0 &&
    rankExhausted["Candidates"] === Length[grid]^2 &&
    rankExhausted["Family"] === "SampleExhaustionToy"];
residueExhausted = BuildObservableTransport[toy[killX], demand,
  "BoundaryEvolution" -> "AmbientBasePoint"];
FTAssert["a letter vanishing at every grid value of the first variable exhausts the residue samples (typed)",
  Lookup[residueExhausted, "Status", None] === "AdmissibleSamplesExhausted" &&
    residueExhausted["SampleKind"] === "Residue" &&
    residueExhausted["Requested"] === 7 &&
    residueExhausted["Available"] < 7 &&
    residueExhausted["Candidates"] === Length[grid]^2];
FTAssert["explicit rank samples bypass the automatic grid, so the exhaustion is not reached",
  Lookup[BuildObservableTransport[toy[killY], demand,
    "BoundaryEvolution" -> "AmbientBasePoint",
    "RankSamples" -> {{Symbol["Global`t"] -> 1/4, y -> 1/4}}],
    "Status", None] =!= "AdmissibleSamplesExhausted"];

(* ---- coefficient field ---- *)
field = FeynFacet`Private`observableTransportCoefficientField;
legacy = <|"Status" -> "ExactEpsilonForm", "Family" -> "LegacyToy",
  "Variables" -> {x, y}, "Regulator" -> eps,
  "Letters" -> {x, 1 - y}, "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
  "EpsFormX" -> eps {{1/x}}, "EpsFormY" -> eps {{-1/(1 - y)}}|>;
FTAssert["a radical-free legacy record infers Rational and gets a path",
  field[legacy] === "Rational" &&
    FindObservableTransportPath[legacy]["Status"] === "ExactPathData"];
FTAssert["a radical in TTotalInverse alone refuses the inference (Codex: was Rational)",
  field[Join[legacy, <|"TTotalInverse" -> {{Sqrt[1 - x]}}|>]] ===
    Missing["CoefficientFieldRequired", {"TTotalInverse"}]];
FTAssert["a radical in an epsilon-form matrix alone refuses the inference",
  field[Join[legacy, <|"EpsFormY" -> eps {{1/Sqrt[1 - y]}}|>]] ===
    Missing["CoefficientFieldRequired", {"EpsFormY"}]];
FTAssert["a radical in the dlog letters or residues alone refuses the inference",
  field[Join[legacy, <|"DLog" -> <|"Letters" -> {1 + Sqrt[1 - x]},
      "Residues" -> {{{1}}}|>|>]] ===
    Missing["CoefficientFieldRequired", {"DLog/Letters"}] &&
  field[Join[legacy, <|"DLog" -> <|"Letters" -> {x},
      "Residues" -> {{{Sqrt[2]}}}|>|>]] ===
    Missing["CoefficientFieldRequired", {"DLog/Residues"}]];
FTAssert["a chart root with a radical refuses the inference; a rationalizing chart does not",
  field[Join[legacy, <|"ChartRecord" -> <|"Variables" -> {x, y},
      "Subst" -> {x -> x, y -> y},
      "Roots" -> {<|"Root" -> Sqrt[1 - x], "RootSquare" -> 1 - x|>}|>|>]] ===
    Missing["CoefficientFieldRequired", {"ChartRecord/Roots"}] &&
  field[Join[legacy, <|"ChartRecord" -> <|"Variables" -> {x, y},
      "Subst" -> {x -> x, y -> y},
      "Roots" -> {<|"Root" -> x - y, "RootSquare" -> (x - y)^2|>}|>|>]] ===
    "Rational"];
FTAssert["an explicit declaration wins over the inference (record, chart record, certificate)",
  field[Join[legacy, <|"TTotalInverse" -> {{Sqrt[1 - x]}},
      "CoefficientField" -> "Multiquadratic"|>]] === "Multiquadratic" &&
  field[Join[legacy, <|"ChartRecord" -> <|"CoefficientField" -> "Rational"|>|>]] ===
    "Rational" &&
  field[Join[legacy, <|"EpsilonFormCertificate" ->
      <|"CoefficientField" -> "Multiquadratic"|>|>]] === "Multiquadratic"];
FTAssert["FindObservableTransportPath refuses a record whose field cannot be resolved",
  With[{result = FindObservableTransportPath[
      Join[legacy, <|"TTotalInverse" -> {{Sqrt[1 - x]}}|>]]},
    result["Status"] === "CoefficientFieldRequired" &&
      MissingQ[result["CoefficientField"]]]];
transportReady = <|"Status" -> "TransportReadyEpsilonConnection",
  "Family" -> "TransportReadyToy", "Variables" -> {x, y}, "Regulator" -> eps,
  "Letters" -> {x, 1 - y}, "TTotal" -> {{1}}, "TTotalInverse" -> {{1}},
  "EpsFormRepresentation" -> "ConstantResidueDLog"|>;
FTAssert["a transport-ready record without a declared field is refused, even when radical-free",
  field[transportReady] === Missing["CoefficientFieldDeclarationRequired"] &&
    With[{result = BuildObservableTransport[transportReady, demand]},
      result["Status"] === "ObservableTransportCoefficientFieldMissingOrInvalid" &&
        result["CoefficientField"] === Missing["CoefficientFieldDeclarationRequired"]] &&
    field[Join[transportReady, <|"CoefficientField" -> "Rational"|>]] === "Rational"];
FTReport[];
