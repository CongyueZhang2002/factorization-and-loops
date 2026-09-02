
(* ==== moved from Private/TransportCharts.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: GaugePullBackMode -> MapleCanonical branch; default mode Exact, no script sets MapleCanonical; one test (t_maple_canonical_gauge, moved to Private_Backup/Tests)
   Symbols: transportChartMapleCanonicalGauge
   This file is never loaded by FeynFacet.m. *)


transportChartMapleCanonicalGauge[before_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], normalized, after},
  normalized = epsFormStripMapleCanonicalize[before,
    "MapleExecutable" -> OptionValue["MapleExecutable"],
    "ScratchDirectory" -> OptionValue["ScratchDirectory"],
    "CacheDirectory" -> OptionValue["CacheDirectory"],
    "Tag" -> OptionValue["Tag"], "TimeLimit" -> OptionValue["TimeLimit"],
    "Runner" -> OptionValue["Runner"], "Verbose" -> OptionValue["Verbose"]];
  If[Lookup[normalized, "Status", None] =!= "MapleCanonicalGaugeV1",
    Return[<|"Status" -> "MapleGaugeCanonicalizationFailed",
      "Detail" -> normalized|>]];
  after = normalized["Result"];
  If[Dimensions[after] =!= Dimensions[before],
    Return[<|"Status" -> "MapleGaugeCanonicalShapeMismatch"|>]];
  <|"Status" -> "MapleCanonicalGaugePrepared", "Result" -> after,
    "Normalizer" -> KeyDrop[normalized, "Result"],
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
transportChartMapleCanonicalGauge[___] :=
  <|"Status" -> "MapleGaugeCanonicalizationInvalidInput"|>;
