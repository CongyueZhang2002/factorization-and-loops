(* Probe one rationalized NNLO soft-corner period with exact SubTropica integration. *)

$HistoryLength = 0;
$IterationLimit = 10^7;
$FeynCalcStartupMessages = False;

Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];
catalog = Get[
  "/home/maxzhang/factorization-and-loops/Codex/ppHX_NNLO_DoubleReal/BoundaryInventory/SoftCornerBoundaryPeriodCatalog.wl"
];

templateID = If[
  Length[$ScriptCommandLine] >= 2,
  ToExpression[Last[$ScriptCommandLine]],
  31
];
output = FileNameJoin[{
  "/home/maxzhang/factorization-and-loops", "Codex",
  "ppHX_NNLO_DoubleReal", "BoundaryInventory",
  "ProbeSoftCornerTemplate" <> ToString[templateID] <> ".wl"
}];
record = SelectFirst[
  catalog["Classes"],
  MemberQ[#1["TemplateIDs"], templateID] &,
  Missing["NotFound"]
];
If[MissingQ[record],
  Print["ERROR: template not found: ", templateID];
  Exit[1]
];

period = BuildNormalizedMasterBoundaryIntegral[<|
  "Name" -> "NNLO soft-corner template " <> ToString[templateID],
  "Density" -> record["RationalDensity"],
  "IntegrationDomains" -> record["IntegrationDomains"],
  "Regulator" -> ep,
  "Normalization" -> 1,
  "EpsilonRange" -> {-8, 0},
  "Assumptions" -> Element[ep, Reals],
  "ConvergenceAssumptions" -> -1/2 < ep < 0,
  "BranchData" -> <|
    "PhysicalChamber" -> record["PhysicalChamber"],
    "CoordinateMap" -> catalog["CoordinateMap"]
  |>
|>];
If[period === $Failed,
  Print["ERROR: boundary-period construction failed."];
  Exit[1]
];

result = EvaluateMasterBoundarySubTropica[
  period,
  "Kernels" -> 1,
  "TimeConstraint" -> 300,
  "MemoryConstraint" -> 4 1024^3
];

If[result === $Failed,
  probeRecord = <|
    "TemplateID" -> templateID,
    "Constructed" -> True,
    "AnalyticEvaluation" -> False
  |>;
  Put[probeRecord, output];
  Print[InputForm[probeRecord]];
  Exit[1]
];

probeRecord = <|
  "TemplateID" -> templateID,
  "Constructed" -> True,
  "AnalyticEvaluation" -> True,
  "ElapsedSeconds" -> result["ElapsedSeconds"],
  "ResultValuation" -> result["ResultValuation"],
  "Result" -> result["Result"]
|>;
Put[probeRecord, output];
Print[InputForm[probeRecord]];
