(* Benchmark fixture: uses the saved Wolfram data and each AMFlow reference at its own point and boundary. *)

$HistoryLength=0;
Get["/home/maxzhang/factorization-and-loops/FeynFacet/FiniteSolutionData.wl"];
base="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
summary={};
Do[
 stored=Import[base<>"/Stage1And2_2026-09-06/"<>family<>"/FiniteSolution/solution.wxf","WXF"];
 constants=(FeynFacetSolution`C@@#->(101+3 First[#]+Last[#])/(113+First[#]-Last[#])& /@ stored["RequiredInitialConstantCoefficients"]);
 prepareTime=AbsoluteTiming[prepared=FeynFacetSolution`PrepareMasterIntegralSolution[stored,"NumericalBackend"->"FLINT"];][[1]];
 evaluateTime=AbsoluteTiming[result=Quiet[FeynFacetSolution`EvaluateMasterIntegralSolution[prepared,{13/50,7/40},
   "NumericalBackend"->"FLINT","InitialConstantValues"->constants,"WorkingPrecision"->80,
   "AccuracyGoal"->30,"PrecisionGoal"->30],N::meprec];][[1]];
 old=Import[base<>"/NumericalSpeedups_2026-09-06/"<>family<>"/wolfram-comparison.wxf","WXF"]["ReferenceResult"];
 aa=Flatten[Last/@#& /@ Values[old["MasterIntegralEpsilonCoefficients"]]];
 bb=Flatten[Last/@#& /@ Values[result["MasterIntegralEpsilonCoefficients"]]];
 error=Max[Abs[aa-bb]/(1+Abs[aa])];
 report=<|"Family"->family,"PreparationSeconds"->prepareTime,"EvaluationSeconds"->evaluateTime,
  "CoefficientCount"->Length[bb],"WolframComparisonPassed"->TrueQ[error<10^-30],
  "WolframNormalizedDifference"->error,"Result"->result|>;
 If[family=!="CF303",
  amf=Import[base<>"/NumericalEvaluation_2026-09-06/"<>family<>"/series-comparison.wxf","WXF"];
  referenceConstants=(FeynFacetSolution`C@@#->Coefficient[
    amf["TestBoundaryPolynomial"][[First[#]]],stored["DimensionalRegulator"],Last[#]]& /@
    stored["RequiredInitialConstantCoefficients"]);
  referencePointResult=FeynFacetSolution`EvaluateMasterIntegralSolution[prepared,amf["Point"],
    "InitialConstantValues"->referenceConstants,"WorkingPrecision"->90,
    "AccuracyGoal"->30,"PrecisionGoal"->30];
  amfErrors=Table[
   row=Rationalize[entry["Row"],0];order=entry["EpsilonOrder"];
   Abs[Association[referencePointResult["MasterIntegralEpsilonCoefficients"][order]][row]-entry["ReferenceValue"]]/
    (1+Abs[entry["ReferenceValue"]]),{entry,amf["Comparisons"]}];
  report=Join[report,<|"AMFlowComparisonPassed"->TrueQ[Max[amfErrors]<10^-30],
   "AMFlowNormalizedDifference"->Max[amfErrors],"AMFlowComparisonPoint"->amf["Point"]|>]];
 Export["/tmp/feynfacet-numerical-speedups-20260906/"<>family<>"-final.wxf",report,"WXF"];
 Print[InputForm[KeyDrop[report,"Result"]]];AppendTo[summary,KeyDrop[report,"Result"]],
{family,{"CF269","CF259","CF303"}}];
Export["/tmp/feynfacet-numerical-speedups-20260906/final-timings.wxf",summary,"WXF"];
Quit[];
