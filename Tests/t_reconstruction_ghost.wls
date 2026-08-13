(* The NNLO double-real ghost grid through the package reconstruction
   stage in series mode.

   The ghost trace is the smallest set that is genuinely NNLO-shaped: 27
   masters, one column each, 15.3 MB of trace input, and an alias map
   whose regulator is NOT in the same slot as the NLO one (v5 there, v3
   at NLO).  The module reads the alias map from the manifest, so the
   test asserts that rather than hard-coding a slot.

   The eps-truncated reconstruction must agree with the stored exact
   coefficients order by order to the requested depth.  Exactly as in
   t_reconstruction_nlo, that is the statement that the stored
   coefficient minus the resummed series has Laurent valuation above the
   truncation, proved in the ring where every power with an
   Epsilon-dependent exponent is an independent atom.

   Acceptance criteria:
   A. The stored reference and the stored trace load; the manifest's
      regulator alias is read from the manifest, not assumed.
   B. Series reconstruction of the whole grid completes.
   C. Identical master integral sets.
   D. Every coefficient is stored in the series form, keyed from its
      true Laurent start, and the truncation is recorded.
   E. Every master, and the remainder column, agrees with the stored
      exact coefficient to the requested depth.
   F. The truncation is real: at least one column's remainder starts
      exactly one order above it.
   G. The reconstruction stays inside the measured 18.8 s full-rational
      baseline for this grid. *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

traceDirectory = FileNameJoin[{
  root, "Codex", "ppHX_NNLO_DoubleReal", "CoefficientSimplification",
  "UU_Ghost_08_10_shared", "FiniteField"
}];
referenceFile = FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Results", "UU_Ghost_08_10_shared",
  "CoefficientResult.wl"
}];

seriesDepth = 5;
threads = 16;
(* WORKLOG 2026-08-12: the ghost grid reconstructs in 18.84 s of FireFly
   time as one shared full-rational trace.  Series mode must not be
   slower than the mode it replaces. *)
baselineSeconds = 18.84;

reference = If[FileExistsQ[referenceFile], Get[referenceFile], $Failed];
record = FeynFacet`Private`reconstructionTraceRecord[traceDirectory];
traceData = If[AssociationQ[record], record["TraceData"], $Failed];
regulatorAlias = If[
  AssociationQ[traceData],
  FeynFacet`Private`reconstructionSeriesAlias[traceData, Global`Epsilon],
  $Failed
];

FTTest`FTAssert["A. the reference, the trace and its alias map load",
  AssociationQ[reference] &&
    reference["Format"] === "FeynFacet-IBP" &&
    reference["FormatVersion"] === 8 &&
    AssociationQ[traceData] &&
    StringQ[regulatorAlias] &&
    (* the ghost alias map numbers the regulator last, unlike the NLO
       one; reading it from the manifest is the whole point *)
    regulatorAlias === SymbolName[traceData["SymbolRules"][Global`Epsilon]]];

If[! AssociationQ[traceData] || ! AssociationQ[reference], FTTest`FTReport[]];

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
      FileNameJoin[{traceDirectory, "progress"}]
    }
  ]
];

{seriesSeconds, result} = AbsoluteTiming @ FeynFacet`ReconstructCoefficients[
  traceDirectory,
  "SeriesVariable" -> Automatic,
  "SeriesOrder" -> seriesDepth,
  "Threads" -> threads,
  "ResultFile" -> None
];

FTTest`FTAssert["B. series reconstruction of the ghost grid completes",
  AssociationQ[result] &&
    result["Format"] === "FeynFacet-IBP" &&
    result["FormatVersion"] === 8 &&
    result["SeriesTruncation"] === seriesDepth];

If[! AssociationQ[result], FTTest`FTReport[]];

masterKeyOf[entry_] := ToString[entry["Master"], InputForm];
referenceMasters = Association[masterKeyOf[#] -> # & /@ reference["Masters"]];
resultMasters = Association[masterKeyOf[#] -> # & /@ result["Masters"]];
sameMasters = Sort[Keys[referenceMasters]] === Sort[Keys[resultMasters]];

FTTest`FTAssert["C. identical master integral sets", sameMasters];

storedSeriesQ[entry_] := Module[{coefficient, orders},
  coefficient = entry["Coefficient"];
  If[! FeynFacet`Private`reconstructionSeriesQ[coefficient], Return[False]];
  orders = Keys[coefficient["Orders"]];
  coefficient["SeriesVariable"] === Global`Epsilon &&
    orders =!= {} && orders === Range[Min[orders], seriesDepth] &&
    ! TrueQ[coefficient["Orders"][Min[orders]] === 0]
];

FTTest`FTAssert["D. every coefficient is stored in the series form",
  AllTrue[result["Masters"], storedSeriesQ] &&
    result["FiniteFieldReconstruction"]["SeriesTruncation"] === seriesDepth &&
    result["SeriesVariable"] === Global`Epsilon];

regulator = Global`Epsilon;
atomize[expression_] := expression /. Power[base_, exponent_] /;
  ! FreeQ[exponent, regulator] :>
    base^(exponent /. regulator -> 0) *
      reconstructionAtom[base, Expand[exponent - (exponent /. regulator -> 0)]];

laurentValuation[expression_] := Module[{together, numerator, denominator},
  together = Together[atomize[expression]];
  If[TrueQ[together === 0], Return[Infinity]];
  numerator = Numerator[together];
  denominator = Denominator[together];
  Exponent[numerator, regulator, Min] - Exponent[denominator, regulator, Min]
];

fullCoefficient[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] entry["Coefficient"];
resummed[data_Association, entry_Association] :=
  data["PreFactor"] entry["PreFactor"] *
    FeynFacet`Private`reconstructionSeriesNormal[entry["Coefficient"]];

(* Largest column first: a failure shows up on the interesting one
   without waiting for the cheap ones. *)
comparisonOrder = If[
  sameMasters,
  SortBy[Keys[referenceMasters], -LeafCount[referenceMasters[#]["Coefficient"]] &],
  {}
];
valuations = Map[
  Function[key,
    Module[{seconds, value},
      {seconds, value} = AbsoluteTiming @ laurentValuation[
        fullCoefficient[reference, referenceMasters[key]] -
          resummed[result, resultMasters[key]]
      ];
      Print["    ", StringTake[key, UpTo[44]], ": valuation ", value,
        " (leaf ", LeafCount[referenceMasters[key]["Coefficient"]], ", ",
        Round[seconds, 0.01], " s)"];
      key -> value
    ]
  ],
  comparisonOrder
];
remainderValuation = laurentValuation[
  reference["PreFactor"] reference["Remainder"] -
    result["PreFactor"] *
      FeynFacet`Private`reconstructionSeriesNormal[result["Remainder"]]
];

FTTest`FTAssert["E1. every master agrees with the stored exact coefficient to depth",
  valuations =!= {} && AllTrue[Last /@ valuations, # > seriesDepth &]];
FTTest`FTAssert["E2. the remainder column agrees to depth",
  remainderValuation > seriesDepth];

FTTest`FTAssert["F. the truncation is real on at least one column",
  MemberQ[Last /@ valuations, seriesDepth + 1]];

fireflySeconds = result["FiniteFieldReconstruction"]["ReconstructionSeconds"];

FTTest`FTAssert["G. the run stays inside the full-rational baseline",
  NumericQ[fireflySeconds] && fireflySeconds <= baselineSeconds];

Print["    alias map: ", InputForm[traceData["SymbolRules"]]];
Print["    columns: ", Length[traceData["OutputFiles"]],
  ", trace input (MB): ",
  Round[Total[traceData["ExpressionBytes"]]/2.^20, 0.1]];
Print["    masters compared: ", Length[valuations]];
Print["    FireFly: ", Round[fireflySeconds, 0.01], " s of a ",
  baselineSeconds, " s baseline, ",
  Total[
    Map[
      Lookup[Lookup[#, "Statistics", <||>], "Probes", 0] &,
      result["FiniteFieldReconstruction"]["Schedule"]
    ]
  ], " probes"];
Print["    stage wall time: ", Round[seriesSeconds, 0.01], " s"];
Print["    Laurent starts: ",
  InputForm[Sort[Min[Keys[#["Coefficient"]["Orders"]]] & /@ result["Masters"]]]];
If[! AllTrue[Last /@ valuations, # > seriesDepth &],
  Print["    disagreeing masters: ",
    Select[valuations, ! (Last[#] > seriesDepth) &][[All, 1]]]];

FTTest`FTReport[];
