#!/usr/bin/env wolframscript

(* Bounded production control for selecting a regular base point and first
   path-parameter scale for a multiquadratic coefficient operator. *)
repo = ExpandFileName@FileNameJoin[
  {DirectoryName[$InputFileName], "..", "..", ".."}];
Get[FileNameJoin[{repo, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];

recordFile = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsCertified",
  "family_epsform_CF300.wl"}];
FTAssert["the accepted CF300 record is available", FileExistsQ[recordFile]];
record = Get[recordFile];

plannerTiming = AbsoluteTiming[
  path = ChooseRegularBasePointAndFirstPathParameterScale[record]];
variables = record["CoefficientVariables"];
rootSquares = Together /@ Lookup[
  record["CoefficientPresentation", "SquareRootGenerators"],
  "QuadraticRadicand"];
base = Lookup[path, {"FirstBase", "SecondBase"}, {}];
baseRules = Thread[variables -> base];
baseSquares = Together /@ (rootSquares /. baseRules);
baseRoots = Sqrt[baseSquares];
oldSquares = Together /@ (rootSquares /.
  Thread[variables -> {1/4, 1/4}]);

Print["CF300 planner seconds: ", First[plannerTiming]];
Print["CF300 selected base/first path-parameter scale: ", InputForm[
  {base, Lookup[path, "FirstPathParameterScale", Missing[]]}]];
Print["CF300 root squares/roots at base: ",
  InputForm[{baseSquares, baseRoots}]];

FTAssert["the real CF300 planner selects a regular base point and scale",
  Lookup[path, "Status", None] ===
    "RegularBasePointAndFirstPathParameterScaleSelected"];
FTAssert["all three CF300 roots are nonzero rationals at the selected base",
  Length[baseRoots] === 3 &&
    VectorQ[baseRoots,
      MatchQ[#, _Integer | _Rational] && TrueQ[# != 0] &]];
FTAssert["the selected CF300 base and parameter-scale point are record-regular",
  FeynFacet`Private`observableTransportRecordRegularQ[record, baseRules] &&
    FeynFacet`Private`observableTransportRecordRegularQ[record,
      Thread[variables -> {
        path["FirstBase"] + path["FirstPathParameterScale"],
        path["SecondBase"]}]]];
FTAssert["the planner avoids the former nonsplit default base",
  ! VectorQ[Sqrt[oldSquares], MatchQ[#, _Integer | _Rational] &]];

FTReport[];
