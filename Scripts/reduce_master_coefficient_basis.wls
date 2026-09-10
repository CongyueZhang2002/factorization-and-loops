$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: reduce_master_coefficient_basis.wls COEFFICIENTS SYSTEM OUTPUT"];Exit[2]];
{inputFile,systemFile,outputFile}=ExpandFileName/@args;
input=FeynFacet`FamilyArtifactRead[inputFile];sys=FeynFacet`FamilyArtifactRead[systemFile];
If[!AllTrue[{input,sys},AssociationQ]||!TrueQ[Lookup[input,"Complete",False]]||
 (!KeyExistsQ[sys,"AdditionalMasterRelations"]&&!KeyExistsQ[sys,"IntegralBasisChange"]),
 Print["Complete coefficient table and exact differential basis map required"];Exit[1]];
basis=sys["MasterIntegralBasis"];e=input["DimensionalRegulator"];
If[KeyExistsQ[sys,"IntegralBasisChange"],
 rel=sys["IntegralBasisChange"];sourceBasis=rel["SourceMasterIntegralBasis"];map=rel["SelectedToSourceMatrix"],
 rel=sys["AdditionalMasterRelations"];sourceBasis=rel["SpanningBasis"];map=rel["SpanningBasisEmbedding"]];
If[input["MasterIntegralBasis"]=!=sourceBasis,Print["Coefficient and source basis order mismatch"];Exit[1]];
map=map/.sys["DimensionRule"]/.sys["DimensionalRegulator"]->e;
red=<|"Masters"->basis,"Rules"->Thread[sourceBasis->(map.basis)]|>;
output=<||>;requirements=<||>;timings=<||>;
Do[
 Print["REDUCING ",name];
 {seconds,row}=AbsoluteTiming[FeynFacet`ApplyIntegralReduction[<|name->input["Coefficients"][name]|>,red]];
 If[!AssociationQ[row],Print[row];Exit[1]];
 AssociateTo[output,name->row[name]];AssociateTo[timings,name->seconds];
 AssociateTo[requirements,name->(FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&/@row[name])],
 {name,Keys[input["Coefficients"]]}];
answer=Join[input,<|"Coefficients"->output,"MasterIntegralBasis"->basis,
 "CoefficientLaurentLowerBounds"->requirements,"BasisReductionSecondsByRow"->timings,
 "BasisReduction"->red,"BasisReductionSystemFile"->systemFile,"PreviousCoefficientFile"->inputFile|>];
FeynFacet`FamilyArtifactWrite[answer,outputFile,Compression->Automatic];
Print["COMPLETED ",outputFile," MASTERS ",Length[basis]," SECONDS ",Total[Values[timings]]];
