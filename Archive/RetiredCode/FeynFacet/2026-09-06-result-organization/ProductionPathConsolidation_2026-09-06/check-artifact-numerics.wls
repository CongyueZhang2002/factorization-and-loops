$HistoryLength=0;
root="/home/maxzhang/factorization-and-loops";
Unprotect[Get,Import];
Get[p_String /; StringContainsQ[p,"Private_Backup"]] := (Print["BACKUP READ REFUSED"];Abort[]);
Import[p_String /; StringContainsQ[p,"Private_Backup"],rest___] := (Print["BACKUP READ REFUSED"];Abort[]);
Protect[Get,Import];
Get[root<>"/FeynFacet/FiniteSolutionData.wl"];
base=root<>"/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
results=Table[
 data=FeynFacetSolution`ReadMasterIntegralSolution[base<>"/Stage1And2_2026-09-06/"<>family<>"/FiniteSolution"];
 constants=(FeynFacetSolution`C@@#->(101+3 First[#]+Last[#])/(113+First[#]-Last[#])& /@ data["RequiredInitialConstantCoefficients"]);
 seconds=AbsoluteTiming[result=FeynFacetSolution`EvaluateMasterIntegralSolution[data,{13/50,7/40},
   "NumericalBackend"->"FLINT","InitialConstantValues"->constants,"WorkingPrecision"->80,
   "AccuracyGoal"->30,"PrecisionGoal"->30];][[1]];
 If[FailureQ[result],Print["NUMERICAL FAILURE ",family," ",result];Abort[]];
 reference=Import[base<>"/NumericalSpeedups_2026-09-06/"<>family<>"/evaluation.wxf","WXF"]["Result"];
 aa=Flatten[Last/@#& /@ Values[reference["MasterIntegralEpsilonCoefficients"]]];
 bb=Flatten[Last/@#& /@ Values[result["MasterIntegralEpsilonCoefficients"]]];
 difference=Max[Abs[aa-bb]/(1+Abs[aa])];
 report=<|"Family"->family,"Seconds"->seconds,"Point"->{13/50,7/40},
   "CoefficientCount"->Length[bb],"NonzeroCoefficientCount"->Count[bb,z_/;TrueQ[Abs[z]>10^-30]],
   "NormalizedDifference"->difference,"Passed"->TrueQ[Length[aa]===Length[bb] && difference<10^-30],
   "TestConstants"->constants,"MasterIntegralEpsilonCoefficients"->result["MasterIntegralEpsilonCoefficients"]|>;
 Print["NUMERICAL ",family," count=",Length[bb]," passed=",report["Passed"]];
 report,
 {family,{"CF259","CF303"}}];
Export["/tmp/feynfacet-production-consolidation-20260906/artifact-numerical-comparisons.wxf",results,"WXF"];
Exit[If[AllTrue[results,TrueQ[#["Passed"]]&],0,1]];
