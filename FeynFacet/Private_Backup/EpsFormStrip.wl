
(* ==== moved from Private/EpsFormStrip.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: CANONICA degree ladder + Maple residue strip solver; production entry SolveEpsFormStripInFrame is called with FiniteFieldFirst -> True by Scripts/family_epsform_sector.wls (line 1399) and skips it; only FACET_STRIP_ROUTE=Legacy and Tests/Infrastructure/t_construction_budget.wls reached it; route_split.py 2026-09-02: 4 route-only symbols
   Symbols: SolveEpsFormStrip, epsFormStripExactDLogQ, epsFormStripExactPotentialGauge, epsFormStripRunCanonica
   This file is never loaded by FeynFacet.m. *)


epsFormStripExactDLogQ[
    gauge_List, {e_, c_, bbar_}, variables_List, epsilon_Symbol,
    alphabet_List] := Module[{check, ec, cc, bc, dc, transformed},
  If[! epsFormStripLoadCanonica[], Return[False]];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  If[check === $Failed, Return[False]];
  {ec, cc, bc, dc} = ({e, c, bbar, gauge} /.
    epsilon -> CANONICA`eps);
  transformed = Table[
    Map[Together,
      bc[[mu]] + CANONICA`eps (ec[[mu]].dc - dc.cc[[mu]]) -
        D[dc, variables[[mu]]],
      {2}],
    {mu, Length[variables]}];
  TrueQ[check[transformed, variables, alphabet]]
];

epsFormStripExactPotentialGauge[
    strip : {e_, c_, bbar_}, variables : {x_, y_},
    epsilon_Symbol, alphabet_List] := Module[
  {candidate, remainder, correction, gauge, residuals},
  If[! epsFormStripZeroQ[e] || ! epsFormStripZeroQ[c], Return[$Failed]];
  candidate = Quiet[Check[
    Map[Integrate[#, x] &, bbar[[1]], {2}], $Failed]];
  If[candidate === $Failed || ! FreeQ[candidate, _Integrate],
    Return[$Failed]];
  remainder = Map[Together, bbar[[2]] - D[candidate, y], {2}];
  If[! FreeQ[remainder, x], Return[$Failed]];
  correction = Quiet[Check[
    Map[Integrate[#, y] &, remainder, {2}], $Failed]];
  If[correction === $Failed || ! FreeQ[correction, _Integrate],
    Return[$Failed]];
  gauge = Map[Together, candidate + correction, {2}];
  residuals = Table[
    Map[Together, bbar[[mu]] - D[gauge, variables[[mu]]], {2}],
    {mu, 2}];
  If[epsFormStripZeroQ[residuals] &&
      epsFormStripExactDLogQ[
        gauge, strip, variables, epsilon, alphabet],
    gauge, $Failed]
];

epsFormStripRunCanonica[
    strip : {_, _, _}, variables : {_, _}, epsilon_Symbol,
    alphabet_List, degrees_List, denominatorDegree_Integer,
    timeLimit_, kernelCount_Integer] :=
 Module[
  {needed, launched = {}, canonicaFile, converted, rawResults = {},
   evaluations, next, remaining, completedDegrees = {},
   exactDegrees = {}, bestExactDegree, attempts = {}, candidates = {},
   raw, exact, summary},

  If[kernelCount <= 1,
    (* one kernel of our own: serial ladder, or -- inside a KernelPool
       mission -- degree 0 locally and the other degrees on the pool's
       free subkernels (TaskBroker.wl, 2026-08-21) *)
    rawResults = If[taskBrokerActiveQ[] && Length[degrees] > 1,
      taskBrokerCanonicaLadder[strip, variables, epsilon, alphabet,
        degrees, denominatorDegree, timeLimit],
      (epsFormStripRunCanonicaOne[
        strip, variables, epsilon, alphabet, denominatorDegree,
        timeLimit, #] &) /@ degrees],

  needed = Min[Length[degrees], kernelCount];
  If[Length[Kernels[]] < needed,
    launched = Quiet[LaunchKernels[needed - Length[Kernels[]]]]];
  If[Length[Kernels[]] < needed,
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    Return[<|
      "Attempts" -> (<|"NumeratorDegree" -> #,
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelKernelUnavailable",
        "ParentExactDLog" -> False|> & /@ degrees),
      "Candidates" -> {}|>]];

  canonicaFile = $epsFormStripCanonicaFile;
  With[{file = canonicaFile},
    ParallelEvaluate[
      If[DownValues[CANONICA`FindD] === {} &&
          DownValues[CANONICA`Private`FindD] === {},
        Block[{$Output = {}}, Quiet[Get[file], General::shdw]]];
      CANONICA`$ComputeParallel = False;
      CANONICA`Private`$ComputeParallel = False;
      Off[General::shdw];
    ]];
  converted = strip /. epsilon -> CANONICA`eps;
  evaluations = With[
    {ec = converted[[1]], cc = converted[[2]], bc = converted[[3]],
     vars = variables, letters = alphabet, denDegree = denominatorDegree,
     seconds = timeLimit, originalEpsilon = epsilon},
    Function[degree,
      With[{degreeValue = degree}, ParallelSubmit[
        Module[{findD, elapsed, gauge},
          findD = Which[
            DownValues[CANONICA`FindD] =!= {}, CANONICA`FindD,
            DownValues[CANONICA`Private`FindD] =!= {},
              CANONICA`Private`FindD,
            True, $Failed];
          If[findD === $Failed,
            Return[<|"NumeratorDegree" -> degreeValue,
              "DenominatorDegree" -> denDegree,
              "Status" -> "CANONICAFunctionMissing",
              "ExactDLog" -> False|>]];
          {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
            findD[ec, cc, bc, letters, vars, {},
              CANONICA`DDeltaNumeratorDegree -> degreeValue,
              CANONICA`DDeltaDenominatorDegree -> denDegree,
              CANONICA`VerbosityLevel -> 0],
            seconds, $TimedOut]]];
          If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
            Return[<|
              "NumeratorDegree" -> degreeValue,
              "DenominatorDegree" -> denDegree,
              "Seconds" -> elapsed,
              "Status" -> Which[
                gauge === $TimedOut, "TimedOut",
                gauge === False, "NoGauge",
                True, "InvalidResult"],
              "ExactDLog" -> False|>]];
          <|
            "NumeratorDegree" -> degreeValue,
            "DenominatorDegree" -> denDegree,
            "Seconds" -> elapsed,
            "Status" -> "CandidateGauge",
            "ExactDLog" -> Missing["ParentCheckPending"],
            "Gauge" -> gauge /. CANONICA`eps -> originalEpsilon|>
        ]]]] /@ degrees];
  remaining = evaluations;
  While[remaining =!= {},
    next = WaitNext[remaining];
    raw = next[[1]];
    remaining = next[[3]];
    If[AssociationQ[raw],
      AppendTo[completedDegrees,
        Lookup[raw, "NumeratorDegree", Infinity]];
      exact = ListQ[Lookup[raw, "Gauge", $Failed]] &&
        epsFormStripExactDLogQ[
          raw["Gauge"], strip, variables, epsilon, alphabet];
      raw = Join[raw, <|
        "Status" -> If[exact, "ExactDLog", "FailedDLogIdentity"],
        "ExactDLog" -> exact,
        "ParentExactDLog" -> exact|>];
      If[exact,
        AppendTo[exactDegrees, raw["NumeratorDegree"]];
        bestExactDegree = Min[exactDegrees];
        If[AllTrue[Select[degrees, # < bestExactDegree &],
            MemberQ[completedDegrees, #] &],
          (* abort only kernels this module launched: under a shared
             pool an unconditional AbortKernels[] kills sibling
             evaluations (2026-08-20 review) *)
          If[remaining =!= {} && launched =!= {},
            Quiet[AbortKernels[]]];
          remaining = {}]]];
    (* inside the While: every completed degree's result is recorded.
       A misplaced bracket here (found in the 2026-08-20 review) ran
       this append once, after the loop, so only the last-completed
       degree survived and an exactly-checked gauge could be silently
       discarded. *)
    AppendTo[rawResults, raw]];
  ParallelEvaluate[On[General::shdw]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]]];

  Do[
    If[AssociationQ[raw],
      exact = Lookup[raw, "ParentExactDLog", Missing["NotChecked"]];
      If[! MemberQ[{True, False}, exact],
        exact = TrueQ[Lookup[raw, "ExactDLog", False]] &&
          ListQ[Lookup[raw, "Gauge", $Failed]] &&
          epsFormStripExactDLogQ[
            raw["Gauge"], strip, variables, epsilon, alphabet]];
      summary = Join[
        KeyDrop[raw, "Gauge"],
        <|"ParentExactDLog" -> exact|>];
      If[exact,
        AppendTo[candidates,
          <|"NumeratorDegree" -> raw["NumeratorDegree"],
            "Gauge" -> raw["Gauge"], "Attempt" -> summary|>]],
      summary = <|
        "NumeratorDegree" -> Missing["Unknown"],
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelEvaluationFailed",
        "ParentExactDLog" -> False|>];
    AppendTo[attempts, summary],
    {raw, rawResults}];

  <|"Attempts" -> SortBy[attempts, Lookup[#, "NumeratorDegree", Infinity] &],
    "Candidates" -> SortBy[candidates, #["NumeratorDegree"] &]|>
];

SolveEpsFormStrip[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {degrees, denominatorDegree, canonicaTime, canonicaKernels,
   mapleExecutable, mapleLibrary, mapleTime, mapleMethodTime,
   mapleResidueKernels,
   mapleDenominatorPowers,
   mapleNumeratorOffsets, scratchDirectory,
   tag, verbose, alphabet, converted, irreducibles,
   check, alreadyDLog, exactPotential, canonica, selected, maple, result},

  If[! epsFormStripShapeQ[strip],
    Message[SolveEpsFormStrip::shape]; Return[$Failed]];
  degrees = DeleteDuplicates[OptionValue["CANONICANumeratorDegrees"]];
  (* an EMPTY degree list means "dlog recognition only": the strip-method
     benchmark of 2026-08-22 (20 real strips) showed the finite field
     3-130x faster than the CANONICA ladder wherever both solve and the
     ladder burning 480 s on every strip it cannot solve, so the
     production route runs recognition, then the finite field *)
  If[! AllTrue[degrees, IntegerQ[#] && # >= 0 &],
    Message[SolveEpsFormStrip::degrees]; Return[$Failed]];
  denominatorDegree = OptionValue["CANONICADenominatorDegree"];
  canonicaTime = OptionValue["CANONICATimeLimit"];
  canonicaKernels = facetKernelCount[
    OptionValue["CANONICAKernels"], Length[degrees]];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = OptionValue["MapleLibrary"];
  mapleTime = OptionValue["MapleTimeLimit"];
  mapleMethodTime = OptionValue["MapleMethodTimeLimit"];
  mapleResidueKernels = facetKernelCount[
    OptionValue["MapleResidueKernels"]];
  mapleDenominatorPowers = OptionValue[
    "MapleLetterDenominatorPowers"];
  mapleNumeratorOffsets = OptionValue[
    "MapleNumeratorDegreeOffsets"];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];
  If[! epsFormStripLoadCanonica[],
    Message[SolveEpsFormStrip::canonica, $epsFormStripCanonicaFile];
    Return[$Failed]];

  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  exactPotential = epsFormStripExactPotentialGauge[
    strip, variables, epsilon, alphabet];
  If[ListQ[exactPotential],
    Return[<|
      "Status" -> "Solved",
      "Method" -> "ExactPotential",
      "Gauge" -> exactPotential,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];
  converted = strip /. epsilon -> CANONICA`eps;
  irreducibles = epsFormStripCanonicaSymbol["ExtractIrreducibles"][
    converted, CANONICA`AllowEpsDependence -> True];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  alreadyDLog = FreeQ[irreducibles, CANONICA`eps] &&
    (epsFormStripZeroQ[converted[[3]]] ||
      TrueQ[check[converted[[3]], variables, alphabet]]);
  If[alreadyDLog,
    Return[<|
      "Status" -> "Solved",
      "Method" -> "AlreadyDLog",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];

  If[verbose,
    Print["CANONICA strip search: numerator degrees ", degrees,
      ", ", canonicaTime, " s each"]];
  canonica = If[degrees === {}, <|"Attempts" -> {}, "Candidates" -> {}|>,
    epsFormStripRunCanonica[
      strip, variables, epsilon, alphabet, degrees, denominatorDegree,
      canonicaTime, canonicaKernels]];
  If[canonica["Candidates"] =!= {},
    selected = First[canonica["Candidates"]];
    result = <|
      "Status" -> "Solved",
      "Method" -> "CANONICA",
      "Gauge" -> selected["Gauge"],
      "NumeratorDegree" -> selected["NumeratorDegree"],
      "DenominatorDegree" -> denominatorDegree,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> canonica["Attempts"]
    |>;
    Return[result]];

  (* "UseMaple" -> False: dlog recognition + CANONICA ladder only (the
     strip-method benchmark of 2026-08-21 measures the routes separately) *)
  If[! TrueQ[OptionValue["UseMaple"]],
    Return[<|"Status" -> If[degrees === {}, "NotRecognized", "CANONICAFailed"],
      "Method" -> If[degrees === {}, "Recognition", "CANONICA"],
      "CANONICAAttempts" -> canonica["Attempts"]|>]];
  If[verbose, Print["CANONICA found no exact dlog gauge; invoking Maple"]];
  maple = SolveResidueRationalGauge[
    strip, variables, epsilon,
    "MapleExecutable" -> mapleExecutable,
    "MapleLibrary" -> mapleLibrary,
    "ScratchDirectory" -> scratchDirectory,
    "Tag" -> tag,
    "TimeLimit" -> mapleTime,
    "MethodTimeLimit" -> mapleMethodTime,
    "ResidueKernels" -> mapleResidueKernels,
    "LetterDenominatorPowers" -> mapleDenominatorPowers,
    "NumeratorDegreeOffsets" -> mapleNumeratorOffsets,
    "Verbose" -> verbose];
  If[AssociationQ[maple],
    Return[Join[maple,
      <|"CANONICAAttempts" -> canonica["Attempts"]|>]]];

  Message[SolveEpsFormStrip::failed];
  $Failed
];
