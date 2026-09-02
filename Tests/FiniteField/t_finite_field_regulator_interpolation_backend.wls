#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Block[{$Context = "FeynFacet`Private`",
    $ContextPath = {"System`", "FeynFacet`", "FeynFacet`Private`"}},
  Get[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm",
    "FiniteFieldStripSolve.wl"}]]];

pass = 0; fail = 0;
check[label_, value_] := If[TrueQ[value], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];

Clear[e];
p = 2147483647;
wide = 2305843009213693951;
modQ[q_, value_] := Mod[Mod[Numerator[value], q]
  PowerMod[Mod[Denominator[value], q], -1, q], q];
baseFunctions = {(3 e^3 + 2 e + 1)/(e^3 - 5 e^2 + 7),
  (e + 2)/(4 e^2 + 1), 5, 0, e^5/(e + 3),
  (e^2 - 1)/(e^2 + 2 e + 1)};
baseDegrees = {{3, 3}, {1, 2}, {0, 0}, {-Infinity, 0}, {5, 1}, {1, 1}};
coordinateCount = 256;
functions = Table[baseFunctions[[Mod[index - 1, Length[baseFunctions]] + 1]],
  {index, coordinateCount}];
degrees = Table[baseDegrees[[Mod[index - 1, Length[baseDegrees]] + 1]],
  {index, coordinateCount}];
epsilonValues = Table[index/(index + 20), {index, 1, 24}];
canonical[q_] := Table[<|"EpsilonValue" -> value,
    "EpsilonMod" -> modQ[q, value],
    "Values" -> (modQ[q, #1 /. e -> value] & /@ functions)|>,
  {value, epsilonValues}];

binary = FeynFacet`Private`finiteFieldStripRegulatorInterpolationBinary[];
check["native regulator-interpolation binary is installed",
  StringQ[binary] && FileExistsQ[binary]];

nativeDiscovery = FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
  canonical[p], p, 4, 3, 22, Automatic];
wolframDiscovery = Block[{
    FeynFacet`Private`$finiteFieldStripNativeInterpolationMinimumCoordinates =
      Infinity},
  FeynFacet`Private`finiteFieldStripHeldOutInterpolate[canonical[p], p,
    "InitialConstructionCount" -> 4, "HeldOutCount" -> 3,
    "MaximumTotalDegree" -> 22]];
check["native adaptive discovery is accepted",
  Lookup[nativeDiscovery, "Status", None] === "HeldOutValidated" &&
    Lookup[nativeDiscovery, "InterpolationBackend", None] ===
      "FLINTRegulatorInterpolation"];
check["native discovery matches Wolfram coefficients and consumption",
  KeyTake[nativeDiscovery, {"Status", "SampleCount", "ConstructionCount"}] ===
      KeyTake[wolframDiscovery, {"Status", "SampleCount", "ConstructionCount"}] &&
    KeyTake[#, {"Numerator", "Denominator", "Degrees"}] & /@
        nativeDiscovery["Interpolations"] ===
      (KeyTake[#, {"Numerator", "Denominator", "Degrees"}] & /@
        wolframDiscovery["Interpolations"])] ;

cappedDiscovery = Internal`InheritedBlock[
  {FeynFacet`Private`taskBrokerNativeThreadLimit},
  Unprotect[FeynFacet`Private`taskBrokerNativeThreadLimit];
  Clear[FeynFacet`Private`taskBrokerNativeThreadLimit];
  FeynFacet`Private`taskBrokerNativeThreadLimit[requested_Integer] :=
    Min[requested, 1];
  FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
    canonical[p], p, 4, 3, 22, Automatic]];
check["native discovery obeys the live pool thread grant",
  Lookup[cappedDiscovery, "Status", None] === "HeldOutValidated" &&
    Lookup[cappedDiscovery, "InterpolationBackendThreads", None] === 1 &&
    Lookup[cappedDiscovery["Interpolations"], "Degrees"] === degrees];

nativeWideDiscovery =
  FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
    canonical[wide], wide, 4, 3, 22, Automatic];
check["adaptive discovery accepts a 61-bit prime",
  Lookup[nativeWideDiscovery, "Status", None] === "HeldOutValidated" &&
    Lookup[nativeWideDiscovery["Interpolations"], "Degrees"] === degrees];

nativeFixed = FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
  canonical[wide], wide, 4, 3, 22, degrees];
check["fixed profile accepts a 61-bit prime",
  Lookup[nativeFixed, "Status", None] === "HeldOutValidated" &&
    Lookup[nativeFixed["Interpolations"], "Degrees"] === degrees &&
    Lookup[nativeFixed, "InterpolationBackendThreads", None] === 1];

wrong = FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
  canonical[p], p, 4, 3, 22, ReplacePart[degrees, 1 -> {2, 2}]];
check["wrong fixed profile is rejected rather than grown forever",
  Lookup[wrong, "Status", None] === "RejectPrimeDegreeProfileChanged" &&
    MemberQ[Lookup[wrong, "DegreeMismatchCoordinates", {}], 1]];

highDegreeFunctions = ConstantArray[e^23 + 7 e^11 + 3 e + 1,
  coordinateCount];
highDegreeCanonical = Table[<|"EpsilonValue" -> value,
    "EpsilonMod" -> modQ[wide, value],
    "Values" -> (modQ[wide, #1 /. e -> value] & /@
      highDegreeFunctions)|>, {value, epsilonValues}];
degreeExceeded = FeynFacet`Private`finiteFieldStripNativeHeldOutInterpolate[
  highDegreeCanonical, wide, 4, 3, 22, Automatic];
check["a disproved maximum degree terminates without requesting images",
  Lookup[degreeExceeded, "Status", None] ===
      "MaximumTotalDegreeExceeded" &&
    Lookup[degreeExceeded, "MaximumTotalDegree", None] === 22 &&
    Lookup[degreeExceeded, "ConsumedSampleCount", None] === 24 &&
    Lookup[degreeExceeded, "ConstructionCount", None] === 24 &&
    Length[Lookup[degreeExceeded, "DegreeBoundExceededCoordinates", {}]] ===
      coordinateCount &&
    Lookup[degreeExceeded, "InterpolationBackendThreads", None] >= 1];

automatic = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[
  canonical[p], p, "InitialConstructionCount" -> 4,
  "HeldOutCount" -> 3, "MaximumTotalDegree" -> 22];
check["large automatic interpolation selects the native batch",
  Lookup[automatic, "InterpolationBackend", None] ===
    "FLINTRegulatorInterpolation"];

Print["t_finite_field_regulator_interpolation_backend: ", pass,
  " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
