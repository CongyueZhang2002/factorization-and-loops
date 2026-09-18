Begin["FeynFacet`Private`"];
(* Calendar corrections must not change measured contribution durations.
   Linux exposes a cheap monotonic uptime clock with 0.01-second resolution.
   Other hosts use the kernel's elapsed-session clock. *)
facetElapsedClock[]:=If[$OperatingSystem==="Unix"&&FileExistsQ["/proc/uptime"],
 First[ReadList["/proc/uptime",Number,1]],SessionTime[]];
facetElapsedClockType[]:=If[$OperatingSystem==="Unix"&&FileExistsQ["/proc/uptime"],
 "LinuxUptime","SessionTime"];
SetAttributes[facetElapsedTiming,HoldAll];
facetElapsedTiming[expression_]:=Module[{start=facetElapsedClock[],value},
 value=expression;{facetElapsedClock[]-start,value}];
End[];
