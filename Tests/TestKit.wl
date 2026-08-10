(* Minimal assertion kit: every test declares its acceptance criterion
   machine-checkably and exits nonzero on failure. *)

BeginPackage["FTTest`"];

FTAssert::usage =
  "FTAssert[label, condition] records one assertion and prints PASS or FAIL.";

FTReport::usage =
  "FTReport[] prints a summary and exits the kernel with the number of failures.";

Begin["`Private`"];

$results = {};

FTAssert[label_String, condition_] := Module[{ok = TrueQ[condition]},
  AppendTo[$results, {label, ok}];
  Print[If[ok, "PASS  ", "FAIL  "], label];
  ok
];

FTReport[] := Module[{failed = Count[$results, {_, False}]},
  Print[StringRepeat["-", 48]];
  Print[Length[$results], " assertions, ", failed, " failed"];
  Exit[Min[failed, 250]]
];

End[];

EndPackage[];
