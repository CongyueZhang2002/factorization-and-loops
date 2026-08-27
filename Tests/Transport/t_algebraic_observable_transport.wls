#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

x = Symbol["Global`algebraicX"];
y = Symbol["Global`algebraicY"];
eps = Symbol["Global`eps"];

record = <|
  "Status" -> "ExactEpsilonForm",
  "Family" -> "AlgebraicObservableToy",
  "Variables" -> {x, y},
  "Regulator" -> eps,
  "Dim" -> 1,
  "Ranges" -> {{1}},
  "TTotal" -> {{eps}},
  "TTotalInverse" -> {{1/eps}},
  "EpsFormX" -> eps {{1/Sqrt[1 - x]}},
  "EpsFormY" -> eps {{0}},
  "Letters" -> {1 - x},
  "ChartRecord" -> <|"CoefficientField" -> "Multiquadratic"|>,
  "GateVerdict" -> True,
  "GaugeIdentity" -> True,
  "Flatness" -> True,
  "TTotalInvertible" -> True
|>;

path = FindObservableTransportPath[record];
demand = <|
  "PhysicalRows" -> {1},
  "PhysicalOrders" -> {0, 1},
  "PhysicalValuation" -> 0,
  "Path" -> path
|>;
transport = BuildObservableTransport[record, demand];

FTAssert["the algebraic family record is admitted only after exact certificates",
  ExactFamilyEpsilonFormQ[record]];
FTAssert["an endpoint-regular two-segment path is selected automatically",
  AssociationQ[path] && path["Status"] === "ExactPathData"];
FTAssert["observable-only transport finishes over the declared algebraic field",
  AssociationQ[transport] &&
    transport["Status"] === "ExactObservableTransport"];
FTAssert["the first segment uses exact algebraic entry kernels",
  transport["FirstSegmentKernelMethod"] === "AlgebraicEntryKernels" &&
    Length[transport["FirstSegmentKernels"]] === 1];
FTAssert["the second zero connection is represented without spurious kernels",
  transport["SecondSegmentKernelMethod"] === "AlgebraicEntryKernels" &&
    transport["SecondSegmentKernels"] === {}];
FTAssert["all demand-driven transport identities are exact",
  And @@ (TrueQ /@ Values[transport["Certificates"]])];

FTReport[];
