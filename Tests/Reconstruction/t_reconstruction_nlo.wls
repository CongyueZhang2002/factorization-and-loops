(* The NLO golden through the package reconstruction stage, in both
   modes.

   The stored trace of the regenerated NLO UU 10x10 set is reconstructed
   from scratch by ReconstructCoefficients and compared with the
   2026-08-09 reference CoefficientResult.wl:

   - full rational: every master coefficient must reproduce the golden
     EXACTLY, as in t_nlo_coefficient_golden;
   - series: the eps-truncated reconstruction must equal the golden
     order by order to the requested depth, which is the statement that
     the golden minus the resummed series has Laurent valuation above
     the truncation.

     The comparison is exact, not sampled.  Both sides carry the
     analytic signature (2^(2 Epsilon) Pi^(3 + Epsilon) ...), which is
     not rational in Epsilon, so every power with an Epsilon-dependent
     exponent is split into its Epsilon-free factor and an independent
     atom.  Proving the remainder in the larger ring of those atoms
     proves it after any specialization, and it keeps the two sides
     comparable when the emitter folded the integer part of a signature
     into the coefficient on one side and not the other (the golden
     carries 2^(4 + 2 Epsilon) where the trace carries 2^(2 Epsilon)).

   Acceptance criteria:
   A. The reference loads as a FormatVersion-8 FeynFacet-IBP result and
      the stored trace directory is readable.
   B. Full rational reconstruction completes and returns a
      FormatVersion-8 result with no series truncation.
   C. Identical master integral sets.
   D. Every full product globalPreFactor x masterPreFactor x Coefficient
      agrees with the golden exactly, and the remainders agree exactly.
   E. Resume: rerunning does not reconstruct again.
   F. Series reconstruction completes and stores every coefficient in
      the documented series form, keyed from the column's true Laurent
      start, with the truncation recorded.
   G. The resummed series equals the golden to the requested depth
      exactly, for every master and for the remainder.
   H. The series columns are genuinely truncated, not accidentally
      complete: the fat column's remainder starts exactly one order
      above the truncation.
   I. ReconstructionStatus reports the jobs of the run. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

traceDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NLO", "CoefficientSimplification",
  "UU_08_10_10x10_regen", "FiniteField"
}];
referenceFile = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "CoefficientResult.wl"
}];

seriesDepth = 5;
threads = 8;

reference = If[FileExistsQ[referenceFile], Get[referenceFile], $Failed];

FTTest`FTAssert["A. the reference and the stored trace are readable",
  AssociationQ[reference] &&
    reference["Format"] === "FeynFacet-IBP" &&
    reference["FormatVersion"] === 8 &&
    DirectoryQ[traceDirectory] &&
    AssociationQ[
      FeynFacet`Private`reconstructionTraceRecord[traceDirectory]]];

(* Reconstruct from scratch: the run is timed, so the results of an
   earlier run must not be resumed into it.  Only what this stage
   writes is removed - never the manifest or the expression files. *)
Scan[
  Function[path,
    If[DirectoryQ[path], DeleteDirectory[path, DeleteContents -> True]];
    If[FileExistsQ[path], DeleteFile[path]]
  ],
  Join[
    FileNames["rec_*.txt", traceDirectory],
    FileNames["Series*", traceDirectory],
    {
      FileNameJoin[{traceDirectory, "Jobs"}],
      FileNameJoin[{traceDirectory, "progress"}],
      FileNameJoin[{traceDirectory, "StatusProbe"}]
    }
  ]
];

{rationalSeconds, rationalResult} = AbsoluteTiming @ FeynFacet`ReconstructCoefficients[
  traceDirectory,
  "SeriesVariable" -> None,
  "Threads" -> threads,
  "ResultFile" -> None
];

FTTest`FTAssert["B. full rational reconstruction completes",
  AssociationQ[rationalResult] &&
    rationalResult["Format"] === "FeynFacet-IBP" &&
    rationalResult["FormatVersion"] === 8 &&
    rationalResult["SeriesTruncation"] === None];

masterKeyOf[entry_] := ToString[entry["Master"], InputForm];
fullCoefficient[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] entry["Coefficient"];

referenceMasters = Association[masterKeyOf[#] -> # & /@ reference["Masters"]];
rationalMasters = If[
  AssociationQ[rationalResult],
  Association[masterKeyOf[#] -> # & /@ rationalResult["Masters"]],
  <||>
];

FTTest`FTAssert["C. identical master integral sets",
  Sort[Keys[referenceMasters]] === Sort[Keys[rationalMasters]]];

rationalDifferences = If[
  Sort[Keys[referenceMasters]] === Sort[Keys[rationalMasters]],
  Map[
    Function[key,
      key -> TrueQ @ FeynFacet`Private`exactZeroQ[
        fullCoefficient[reference, referenceMasters[key]] -
          fullCoefficient[rationalResult, rationalMasters[key]]
      ]
    ],
    Keys[referenceMasters]
  ],
  {}
];

FTTest`FTAssert["D1. every master coefficient product agrees exactly",
  rationalDifferences =!= {} &&
    AllTrue[Last /@ rationalDifferences, TrueQ]];
FTTest`FTAssert["D2. the remainders agree exactly",
  AssociationQ[rationalResult] &&
    TrueQ @ FeynFacet`Private`exactZeroQ[
      reference["PreFactor"] reference["Remainder"] -
        rationalResult["PreFactor"] rationalResult["Remainder"]
    ]];

{resumeSeconds, resumeResult} = AbsoluteTiming @ FeynFacet`ReconstructCoefficients[
  traceDirectory,
  "SeriesVariable" -> None,
  "Threads" -> threads,
  "ResultFile" -> None
];
resumeSchedule = If[
  AssociationQ[resumeResult],
  resumeResult["FiniteFieldReconstruction"]["Schedule"],
  {}
];

FTTest`FTAssert["E. a completed result file is never reconstructed again",
  AssociationQ[resumeResult] &&
    resumeSchedule =!= {} &&
    AllTrue[resumeSchedule, TrueQ[#["Seconds"] === 0] &] &&
    Sort[Keys[Association[masterKeyOf[#] -> # & /@ resumeResult["Masters"]]]] ===
      Sort[Keys[referenceMasters]]];

{seriesSeconds, seriesResult} = AbsoluteTiming @ FeynFacet`ReconstructCoefficients[
  traceDirectory,
  "SeriesVariable" -> Automatic,
  "SeriesOrder" -> seriesDepth,
  "Threads" -> threads,
  "ResultFile" -> None
];

seriesMasters = If[
  AssociationQ[seriesResult],
  Association[masterKeyOf[#] -> # & /@ seriesResult["Masters"]],
  <||>
];

storedSeriesQ[entry_] := Module[{coefficient, orders},
  coefficient = entry["Coefficient"];
  If[! FeynFacet`Private`reconstructionSeriesQ[coefficient], Return[False]];
  orders = Keys[coefficient["Orders"]];
  coefficient["SeriesVariable"] === Global`Epsilon &&
    orders =!= {} && orders === Range[Min[orders], seriesDepth] &&
    ! TrueQ[coefficient["Orders"][Min[orders]] === 0]
];

FTTest`FTAssert["F. the series result stores every coefficient in the series form",
  AssociationQ[seriesResult] &&
    seriesResult["Format"] === "FeynFacet-IBP" &&
    seriesResult["SeriesVariable"] === Global`Epsilon &&
    seriesResult["SeriesTruncation"] === seriesDepth &&
    seriesResult["FiniteFieldReconstruction"]["SeriesTruncation"] === seriesDepth &&
    Sort[Keys[seriesMasters]] === Sort[Keys[referenceMasters]] &&
    AllTrue[seriesResult["Masters"], storedSeriesQ] &&
    FeynFacet`Private`reconstructionSeriesQ[seriesResult["Remainder"]]];

(* An Epsilon-dependent exponent becomes an independent atom, after its
   Epsilon-free part is factored out so both sides produce the same
   atom. *)
regulator = Global`Epsilon;
atomize[expression_] := expression /. Power[base_, exponent_] /;
  ! FreeQ[exponent, regulator] :>
    base^(exponent /. regulator -> 0) *
      reconstructionAtom[base, Expand[exponent - (exponent /. regulator -> 0)]];

laurentValuation[expression_] := Module[{together, numerator, denominator},
  together = Together[atomize[expression]];
  If[TrueQ[together === 0], Return[Infinity]];
  numerator = Expand[Numerator[together]];
  denominator = Expand[Denominator[together]];
  Exponent[numerator, regulator, Min] - Exponent[denominator, regulator, Min]
];

resummed[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] *
    FeynFacet`Private`reconstructionSeriesNormal[entry["Coefficient"]];

seriesRemainders = If[
  Sort[Keys[seriesMasters]] === Sort[Keys[referenceMasters]],
  Map[
    Function[key,
      key -> laurentValuation[
        fullCoefficient[reference, referenceMasters[key]] -
          resummed[seriesResult, seriesMasters[key]]
      ]
    ],
    Keys[referenceMasters]
  ],
  {}
];
remainderColumnValuation = If[
  AssociationQ[seriesResult],
  laurentValuation[
    reference["PreFactor"] reference["Remainder"] -
      seriesResult["PreFactor"] *
        FeynFacet`Private`reconstructionSeriesNormal[seriesResult["Remainder"]]
  ],
  -Infinity
];

FTTest`FTAssert["G1. the resummed series equals the golden to the requested depth",
  seriesRemainders =!= {} &&
    AllTrue[Last /@ seriesRemainders, # > seriesDepth &]];
FTTest`FTAssert["G2. the remainder column agrees to the requested depth",
  remainderColumnValuation > seriesDepth];

(* A column whose reconstruction happened to be complete would agree
   trivially; the fat column must show the truncation it paid for. *)
FTTest`FTAssert["H. the truncated column stops exactly at the requested depth",
  MemberQ[Last /@ seriesRemainders, seriesDepth + 1]];

status = Quiet @ Check[
  FeynFacet`ReconstructionStatus[traceDirectory], $Failed];

FTTest`FTAssert["I1. ReconstructionStatus reports the jobs of the run",
  AssociationQ[status] && Length[status] >= 2 &&
    AllTrue[Values[status], IntegerQ[#["Probes"]] && #["Probes"] > 0 &] &&
    AllTrue[Values[status], TrueQ[#["Complete"]] &] &&
    AllTrue[Values[status], IntegerQ[#["UpdatedSecondsAgo"]] &&
      Abs[#["UpdatedSecondsAgo"]] < 3600 &]];

(* A job still running has no recorded total of its own, so the expected
   probe count has to come from the total/first-prime ratio of a column
   that did complete.  Two samples a minute apart, one prime deep, are
   what a live job looks like at that point. *)
probeDirectory = FileNameJoin[{traceDirectory, "StatusProbe"}];
Scan[
  CreateDirectory[#, CreateIntermediateDirectories -> True] &,
  {
    FileNameJoin[{probeDirectory, "progress"}],
    FileNameJoin[{probeDirectory, "Jobs"}]
  }
];
epochNow = UnixTime[];
Export[
  FileNameJoin[{probeDirectory, "progress", "inflight.progress"}],
  StringRiffle[
    {
      ToString[epochNow - 60] <> " 1000 prime1 0",
      ToString[epochNow] <> " 4000 prime2 4000"
    },
    "\n"
  ] <> "\n",
  "String"
];
Export[
  FileNameJoin[{probeDirectory, "Jobs", "reference.done"}],
  "<|\"Job\" -> \"reference\", \"Outputs\" -> 1, \"Probes\" -> 8000, " <>
    "\"FirstPrimeProbes\" -> 4000, \"Seconds\" -> 100, \"Completed\" -> " <>
    ToString[epochNow] <> "|>\n",
  "String"
];
liveStatus = Quiet @ Check[
  FeynFacet`ReconstructionStatus[traceDirectory], $Failed];
liveJob = If[AssociationQ[liveStatus],
  Lookup[liveStatus, "StatusProbe/inflight", <||>], <||>];

FTTest`FTAssert["I2. an unfinished job gets a rate, an expected total and an ETA",
  AssociationQ[liveJob] &&
    liveJob["Phase"] === "prime2" &&
    liveJob["Probes"] === 4000 &&
    liveJob["ProbeRate"] === 50 &&
    liveJob["ExpectedProbes"] === 8000 &&
    liveJob["RemainingSeconds"] === 80 &&
    ! TrueQ[liveJob["Complete"]]];

If[DirectoryQ[probeDirectory],
  DeleteDirectory[probeDirectory, DeleteContents -> True]];

Print["    masters compared: ", Length[rationalDifferences]];
Print["    full rational: ", Round[rationalSeconds, 0.01], " s (",
  Round[
    rationalResult["FiniteFieldReconstruction"]["ReconstructionSeconds"], 0.01],
  " s FireFly, ",
  Total[
    Map[
      Lookup[Lookup[#, "Statistics", <||>], "Probes", 0] &,
      rationalResult["FiniteFieldReconstruction"]["Schedule"]
    ]
  ], " probes)"];
Print["    resume: ", Round[resumeSeconds, 0.01], " s"];
Print["    series to Epsilon^", seriesDepth, ": ",
  Round[seriesSeconds, 0.01], " s (",
  Round[
    seriesResult["FiniteFieldReconstruction"]["ReconstructionSeconds"], 0.01],
  " s FireFly, ",
  Total[
    Map[
      Lookup[Lookup[#, "Statistics", <||>], "Probes", 0] &,
      seriesResult["FiniteFieldReconstruction"]["Schedule"]
    ]
  ], " probes)"];
Print["    series Laurent starts: ",
  InputForm[Min[Keys[#["Coefficient"]["Orders"]]] & /@ seriesResult["Masters"]]];
Print["    golden-minus-series valuations: ",
  InputForm[Last /@ seriesRemainders]];
If[! AllTrue[Last /@ rationalDifferences, TrueQ],
  Print["    differing masters: ",
    Select[rationalDifferences, ! TrueQ[Last[#]] &][[All, 1]]]];

FTTest`FTReport[];
