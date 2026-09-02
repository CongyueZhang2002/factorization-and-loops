(* Minimal assertion kit: every test declares its acceptance criterion
   machine-checkably and exits nonzero on failure. *)

BeginPackage["FTTest`"];

FTAssert::usage =
  "FTAssert[label, condition] records one assertion and prints PASS or FAIL.";

FTStripComments::usage =
  "FTStripComments[text] removes (* ... *) comments, nested ones included, in one linear pass over the comment delimiters.";

FTReport::usage =
  "FTReport[] prints a summary and exits the kernel with the number of failures.";

Begin["`Private`"];

$results = {};
$lastAssertionTime = AbsoluteTime[];
$startTime = AbsoluteTime[];

(* Every PASS/FAIL line carries the wall seconds since the previous
   assertion (or since the kit was loaded), so a test's cost is visible
   per section without re-running it under a profiler. *)
FTAssert[label_String, condition_] := Module[
  {ok = TrueQ[condition], now = AbsoluteTime[], elapsed},
  elapsed = Round[now - $lastAssertionTime, 0.1];
  $lastAssertionTime = now;
  AppendTo[$results, {label, ok}];
  Print[If[ok, "PASS  ", "FAIL  "], label, "  [+", elapsed, " s]"];
  ok
];

FTReport[] := Module[{failed = Count[$results, {_, False}]},
  Print[StringRepeat["-", 48]];
  Print[Length[$results], " assertions, ", failed, " failed",
    " (wall ", Round[AbsoluteTime[] - $startTime, 0.1], " s since TestKit load)"];
  Exit[Min[failed, 250]]
];

(* Linear in the text length: only the delimiter positions are walked.
   The earlier per-character AppendTo version was quadratic and took
   30-40 minutes on the 18,000-line multiquadratic solver source. *)
FTStripComments[text_String] := Module[
  {opens, closes, events, depth = 0, cursor = 1, pieces = {}, position, kind},
  opens = StringPosition[text, "(*"][[All, 1]];
  closes = StringPosition[text, "*)"][[All, 1]];
  events = SortBy[Join[({#, 1} & /@ opens), ({#, -1} & /@ closes)], First];
  Do[
    {position, kind} = event;
    (* a delimiter overlapping the previous one, as in open-star-close *)
    If[position < cursor, Continue[]];
    Which[
      kind === 1,
        If[depth === 0 && position > cursor,
          AppendTo[pieces, StringTake[text, {cursor, position - 1}]]];
        depth++; cursor = position + 2,
      depth > 0,
        depth--; cursor = position + 2],
    {event, events}];
  If[depth === 0 && cursor <= StringLength[text],
    AppendTo[pieces, StringTake[text, {cursor, -1}]]];
  StringJoin[pieces]
];

End[];

EndPackage[];
