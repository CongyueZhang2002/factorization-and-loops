
$HistoryLength=0;
Get["/home/maxzhang/factorization-and-loops/FeynFacet/FiniteSolutionData.wl"];
base="/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06";
requests={};
Do[
 directory=FileNameJoin[{base,family,"FiniteSolution"}];
 stored=Import[FileNameJoin[{directory,"solution.wxf"}],"WXF"];
 constants=(FeynFacetSolution`C@@#->(101+3 First[#]+Last[#])/(113+First[#]-Last[#])& /@ stored["RequiredInitialConstantCoefficients"]);
 Do[AppendTo[requests,<|"SolutionDirectory"->directory,"ID"->family<>"-"<>ToString[i],
  "Point"->{13/50,7/40},"EvaluationOptions"->{"NumericalBackend"->"FLINT",
   "InitialConstantValues"->constants,"AccuracyGoal"->30,"PrecisionGoal"->30,
   "WorkingPrecision"->80}|>],{i,4}],
{family,{"CF259","CF303"}}];
results=Quiet[FeynFacetSolution`EvaluateMasterIntegralSolutionBatch[requests,"Workers"->1],N::meprec];
Export["/tmp/feynfacet-numerical-speedups-20260906/batch-hard-serial.wxf",results,"WXF"];
Print[InputForm[If[AssociationQ[results],Join[KeyDrop[results,"Results"],
 <|"TaskSeconds"->Lookup[results["Results"],"ElapsedSeconds"],"WorkerProcessIDs"->Lookup[results["Results"],"WorkerProcessID"]|>],results]]];
Quit[];
