$HistoryLength=0;
root="/home/maxzhang/factorization-and-loops";
Get[root<>"/FeynFacet/FiniteSolutionData.wl"];
base=root<>"/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06";
report={};
Do[
 data=Import[base<>"/"<>family<>"/FiniteSolution/solution.wxf","WXF"];
 depths=<||>;
 Do[dependencies=DeleteDuplicates[Cases[definition["Integrand"],FeynFacetSolution`F[i_Integer,_]:>i,Infinity]];
 AssociateTo[depths,definition["Index"]->1+If[dependencies==={},0,Max[Lookup[depths,dependencies]]]],{definition,data["IntegralDefinitions"]}];
 special=DeleteDuplicates[Cases[data["KernelDefinitions"],h_Symbol /; MemberQ[{"EllipticK","EllipticE","Hypergeometric2F1","Exp","Log","PolyLog"},SymbolName[h]],Infinity,Heads->True]];
 AppendTo[report,<|"Family"->family,"IntegralDefinitions"->Length[data["IntegralDefinitions"]],"Kernels"->Length[data["KernelDefinitions"]],"MaxNestedIntegrationDepth"->Max[Values[depths]],"TransformedEpsilonOrders"->data["TransformedSystemEpsilonOrderRange"],"NamedKernelFunctions"->(SymbolName/@special)|>];
 Print[Last[report]],
 {family,{"CF231","CF254","CF265","CF303"}}];
Export["/tmp/feynfacet-polylog-review-20260906/finite-depth.wxf",report,"WXF"];
