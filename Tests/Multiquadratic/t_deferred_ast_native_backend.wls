#!/usr/bin/env wolframscript

(* Keep the native differential suite in the ordinary WLS gate without
   reimplementing its binary decoder in Wolfram. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
test = FileNameJoin[{root, "Tests", "Multiquadratic",
  "t_deferred_ast_native_backend.py"}];
binary = Quiet[Environment["FACET_DEFERRED_AST_EVAL_BIN"]];
If[! StringQ[binary] || binary === "",
  binary = FileNameJoin[{root, "FeynFacet", "Backends", "flint", "bin",
    "flint_deferred_ast_eval"}]];
process = RunProcess[{"python3", test, "--binary", binary}];
If[process["StandardOutput"] =!= "", Print[process["StandardOutput"]]];
If[process["StandardError"] =!= "", Print[process["StandardError"]]];
FTAssert["native deferred-AST backend differential suite",
  process["ExitCode"] === 0];
FTReport[];
