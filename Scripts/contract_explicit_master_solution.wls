$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: contract_explicit_master_solution.wls COEFFICIENTS SOLUTION REQUEST OUTPUT"];Exit[2]];
{coeff,solution,request}=FeynFacet`FamilyArtifactRead[ExpandFileName[#]]&/@Take[arguments,3];
out=ExpandFileName[arguments[[4]]];
If[!AllTrue[{coeff,solution,request},AssociationQ],Print["Matching coefficient rows, solution and request required."];Exit[1]];
request=Join[request,<|"ProgressFunction"->Function[label,Print["CONTRACT ROW ",label," ",DateString[]]]|>];
{seconds,audited}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ContractExplicitMasterSolution[coeff["Coefficients"],solution,request]]];
FeynFacet`FamilyArtifactWrite[audited,out,Compression->Automatic];
If[!AssociationQ[audited["Result"]]||audited["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print["FAILED ",If[FailureQ[audited["Result"]],audited["Result"],audited["EpsilonRemainderAudit"]]];Exit[1]];
Print["COMPLETED EXPLICIT BULK CONTRACTION ",Length[audited["Result"]["Rows"]]," ROWS SECONDS ",seconds];
