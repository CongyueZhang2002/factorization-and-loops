(* External optimization overlay for the already demand-projected word
   recursion.  The package implementation expands one complete, unused
   weight beyond MaximumWeight solely to fill NextWeightIsZero.  The public
   transport result never consumes or exposes that diagnostic.  On families
   with thousands of invisible terminal states this means tens of thousands
   of exact sparse matrix products after the requested answer is complete.

   This overlay changes only that behavior.  Every requested state, map,
   count, and exact certificate is constructed by the same recurrence.  The
   unrequested terminal probe is recorded as Missing instead of evaluated.
   Installation is explicit and process-local; no package file is edited. *)

BeginPackage["CodexProjectedTransportFastWordKernel`"];

CodexInstallProjectedTransportFastWordKernel::usage =
  "CodexInstallProjectedTransportFastWordKernel[] installs the external " <>
  "no-terminal-probe word recursion in the current kernel.";

CodexUninstallProjectedTransportFastWordKernel::usage =
  "CodexUninstallProjectedTransportFastWordKernel[] restores the downvalues " <>
  "that were present at installation time.";

CodexProjectedTransportFastWordTelemetry::usage =
  "CodexProjectedTransportFastWordTelemetry[] returns measurements from the " <>
  "most recent optimized word recursion.";

Begin["`Private`"];

ClearAll[
  CodexInstallProjectedTransportFastWordKernel,
  CodexUninstallProjectedTransportFastWordKernel,
  CodexProjectedTransportFastWordTelemetry,
  codexOriginalObservableTransportWordMaps
];

$codexFastWordInstalled = False;
$codexFastWordTelemetry = <||>;

CodexProjectedTransportFastWordTelemetry[] := $codexFastWordTelemetry;

CodexInstallProjectedTransportFastWordKernel[] := Module[{},
  If[TrueQ[$codexFastWordInstalled], Return[True]];
  If[DownValues[FeynFacet`Private`observableTransportWordMaps] === {},
    Return[$Failed]];

  DownValues[codexOriginalObservableTransportWordMaps] =
    DownValues[FeynFacet`Private`observableTransportWordMaps] /.
      FeynFacet`Private`observableTransportWordMaps ->
        codexOriginalObservableTransportWordMaps;

  ClearAll[FeynFacet`Private`observableTransportWordMaps];
  FeynFacet`Private`observableTransportWordMaps[
      residues_List, boundary_, demanded_, maximumWeight_Integer] := Module[
    {states, maps, stateCounts, mapCounts, scalarCounts, projected, children,
     terminalStates, seconds, answer},

    states = {{{}, boundary}};
    maps = {};
    stateCounts = {};
    mapCounts = {};
    scalarCounts = {};
    terminalStates = 0;

    {seconds, answer} = AbsoluteTiming[
      Do[
        AppendTo[stateCounts, Length[states]];
        projected = ({#[[1]],
              FeynFacet`Private`observableTransportCancelMatrix[
                demanded . #[[2]]]} &) /@ states;
        projected = Select[projected,
          ! FeynFacet`Private`observableTransportZeroMatrixQ[#[[2]]] &];
        maps = Join[maps, projected];
        AppendTo[mapCounts, Length[projected]];
        AppendTo[scalarCounts,
          Total[Count[Flatten[#[[2]]],
              x_ /; ! FeynFacet`Private`observableTransportZeroQ[x]] & /@
            projected]];

        If[weight < maximumWeight,
          children = Flatten[Table[
            With[{child = residues[[a]] . state[[2]]},
              If[FeynFacet`Private`observableTransportZeroMatrixQ[child],
                Nothing, {Prepend[state[[1]], a], child}]],
            {state, states}, {a, Length[residues]}], 1];
          states = children,
          terminalStates = Length[states];
          states = {}
        ],
        {weight, 0, maximumWeight}
      ];

      <|
        "Maps" -> maps,
        "StateCountsByWeight" -> stateCounts,
        "MapCountsByWeight" -> mapCounts,
        "ScalarCountsByWeight" -> scalarCounts,
        "NextWeightIsZero" -> Missing["TerminalProbeNotRequested"]
      |>
    ];

    $codexFastWordTelemetry = <|
      "Mode" -> "DemandProjectedNoTerminalProbe",
      "MaximumWeight" -> maximumWeight,
      "ResidueMatrices" -> Length[residues],
      "StateCountsByWeight" -> stateCounts,
      "TerminalStates" -> terminalStates,
      "TerminalMatrixProductsAvoidedUpperBound" ->
        terminalStates Length[residues],
      "WordRecursionSeconds" -> seconds,
      "RequestedMapsUnchangedByConstruction" -> True
    |>;
    answer
  ];

  $codexFastWordInstalled = True;
  True
];

CodexUninstallProjectedTransportFastWordKernel[] := Module[{},
  If[! TrueQ[$codexFastWordInstalled], Return[True]];
  DownValues[FeynFacet`Private`observableTransportWordMaps] =
    DownValues[codexOriginalObservableTransportWordMaps] /.
      codexOriginalObservableTransportWordMaps ->
        FeynFacet`Private`observableTransportWordMaps;
  $codexFastWordInstalled = False;
  True
];

End[];
EndPackage[];

