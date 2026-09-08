
$HistoryLength=0;
Get["/home/maxzhang/factorization-and-loops/FeynFacet/FiniteSolutionData.wl"];
base="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
target=base<>"/NumericalSpeedups_2026-09-06";reports={};
Do[
 stored=Import[base<>"/Stage1And2_2026-09-06/"<>family<>"/FiniteSolution/solution.wxf","WXF"];
 previous=Import[target<>"/"<>family<>"/taylor-expansion.wxf","WXF"];
 fresh=Quiet[FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[stored,previous["Direction"],
   "InitialConstantValues"->previous["InitialConstantValues"],"AccuracyGoal"->30,"PrecisionGoal"->30,
   "TaylorOrder"->32,"WorkingPrecision"->90],N::meprec];
 If[FailureQ[fresh],Print[family," ",fresh];Quit[1]];
 Export[target<>"/"<>family<>"/production-taylor-expansion.wxf",fresh,"WXF"];
 timing=First[AbsoluteTiming[q=Table[FeynFacetSolution`EvaluateMasterIntegralTaylorExpansion[fresh,
  fresh["ValidatedParameterRadius"](-1+2 i/127)],{i,0,127}];]];
 report=Join[KeyTake[fresh,{"ConstructionSeconds","PreparationSeconds","RecurrenceSeconds","ValidationSeconds",
    "DirectComparisonCount","ValidatedParameterRadius","DifferentialEquationResidualRatios","ValidationDifferenceRatios"}],
  <|"Family"->family,"All128QueriesPassed"->AllTrue[q,AssociationQ],"Query128Seconds"->timing,
   "FileBytes"->FileByteCount[target<>"/"<>family<>"/production-taylor-expansion.wxf"]|>];
 Print[InputForm[report]];AppendTo[reports,report],
{family,{"CF269","CF259","CF303"}}];
Export[target<>"/production-taylor-summary.wxf",reports,"WXF"];
summary=Import[target<>"/summary.wxf","WXF"];
Quit[];
