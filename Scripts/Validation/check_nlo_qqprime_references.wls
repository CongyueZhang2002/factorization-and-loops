#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
(* Independent finite comparisons: supplied LL formulas, original INCNLO
   unpolarized implementation, and generated transverse-spin zero/control. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[!MemberQ[{0,3},Length[args]],Print["Usage: check_nlo_qqprime_references.wls [UU_PROJECT LL_PROJECT TT_PROJECT]"];Exit[2]];
$HistoryLength=0;$MaxExtraPrecision=50;Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
If[args==={},args={"ppHX_UU","ppHX_LL","ppHX_TT"}];
{uuProject,llProject,ttProject}=ExpandFileName[FileNameJoin[{root,"Projects",#}]]& /@ args;
project=uuProject<>"/Results/NLO/qqp-qqp";
If[!DirectoryQ[project<>"/Validation"],CreateDirectory[project<>"/Validation",CreateIntermediateDirectories->True]];referenceDirectory=root<>"/External/References/ppHX_NLO";passed=0;failed=0;rows={};
check[name_,test_,detail_:None]:=(If[TrueQ[test],passed++,failed++];AppendTo[rows,<|"Check"->name,"Passed"->TrueQ[test],"Detail"->detail|>];Print[If[TrueQ[test],"PASS ","FAIL "],name]);
referenceText=Import[referenceDirectory<>"/p1_p-fromfor (1).m","Text"];
reference=Block[{$Context="VogelsangReference`",$ContextPath={"System`"}},ToExpression[referenceText];
 Association@Table[name->ToExpression["VogelsangReference`"<>name],{name,{"A0","B0","C0","A1","B1","C1","A2","A","B","DD","EE","F","G","H","L","M","CC"}}]];
reference=reference/.{VogelsangReference`v->v,VogelsangReference`w->w,VogelsangReference`CA->FeynCalc`CA,
 VogelsangReference`CF->FeynCalc`CF,VogelsangReference`Nf->nU+nD,VogelsangReference`lv->Log[v],VogelsangReference`l1v->Log[1-v]};
hard=FeynFacet`ReadPartonicResult[llProject<>"/Results/NLO/qqp-qqp/Results.wl"]["Coefficients"][0];
alpha=FeynFacet`ReadProjectCard[llProject]["Counterterms"]["Coupling"];factor=alpha^3/(8FeynCalc`CA^2 Pi s^2);
color={FeynCalc`CF->(FeynCalc`CA^2-1)/(2FeynCalc`CA)};
coeff[expr_,var_]:=Coefficient[expr,var];
terms=<|
 "A0"->coeff[hard["DeltaCoefficient"],Log[muFA2]]+coeff[hard["DeltaCoefficient"],Log[muFB2]],
 "B0"->coeff[hard["PlusCoefficients"][0],Log[muFA2]]+coeff[hard["PlusCoefficients"][0],Log[muFB2]],
 "C0"->coeff[hard["RegularCoefficient"],Log[muFA2]]+coeff[hard["RegularCoefficient"],Log[muFB2]],
 "A1"->coeff[hard["DeltaCoefficient"],Log[muD2]],"B1"->coeff[hard["PlusCoefficients"][0],Log[muD2]],
 "C1"->coeff[hard["RegularCoefficient"],Log[muD2]],"A2"->coeff[hard["DeltaCoefficient"],Log[muR2]],"DD"->hard["PlusCoefficients"][1],
 "A"->(hard["DeltaCoefficient"]/.{muFA2->1,muFB2->1,muD2->1,muR2->1,s->1}),
 "B"->(hard["PlusCoefficients"][0]/.{muFA2->1,muFB2->1,muD2->1,muR2->1,s->1})|>;
Do[actual=terms[name]/If[MemberQ[{"A","B"},name],factor/.s->1,factor];
 check["LL/"<>name,Factor[(actual-reference[name])/.color]===0],{name,Keys[terms]}];
regular=hard["RegularCoefficient"]/factor/.{muFA2->1,muFB2->1,muD2->1,muR2->1,s->1};
regTerms=<|"EE"->coeff[regular,Log[w]],"F"->coeff[regular,Log[v]],"H"->coeff[regular,Log[1-w]],
 "CC"->(regular/._Log->0),"L"->-(1-w)coeff[regular,Log[1-v w]],
 "M"->(1-w)coeff[regular,Log[1-v+v w]],"G"->coeff[regular,Log[1-v]]+coeff[regular,Log[1-v w]]|>;
Do[check["LL/"<>name,Factor[(regTerms[name]-reference[name])/.color]===0],{name,Keys[regTerms]}];
path=project<>"/Validation/INCNLO_points.json";
proc=RunProcess[{"python3",root<>"/Tests/Support/INCNLO/evaluate_reference.py",referenceDirectory,path}];
If[proc["ExitCode"]=!=0||!StringContainsQ[proc["StandardOutput"],"INCNLO_REFERENCE_POINTS 8"],Print[proc];Exit[1]];
ref=Import[path,"RawJSON"];hard=FeynFacet`ReadPartonicResult[uuProject<>"/Results/NLO/qqp-qqp/Results.wl"]["Coefficients"][0];
alpha=FeynFacet`ReadProjectCard[uuProject]["Counterterms"]["Coupling"];
expr={hard["DeltaCoefficient"],hard["PlusCoefficients"][0],hard["PlusCoefficients"][1],hard["RegularCoefficient"]}8FeynCalc`CA^2 Pi s^2/alpha^3;
Do[point=ToExpression /@ ref["Points"][[i]];{pv,pw,ps,pmf,pmd,pmr,pnf}=point;
 actual=N[expr/.{v->pv,w->pw,s->ps,muFA2->pmf,muFB2->pmf,muD2->pmd,muR2->pmr,nU->Floor[pnf/2],nD->Ceiling[pnf/2],FeynCalc`CA->3},25];
 errors=MapThread[Abs[#1-#2]/Max[1,Abs[#1],Abs[#2]]&,{actual,ref["Values"][[i]]}];
 Do[check["UU/INCNLO/point"<>ToString[i]<>"/"<>ref["OutputCoefficients"][[k]],errors[[k]]<2*10^-10,errors[[k]]],{k,4}],{i,Length[ref["Points"]]}];
ttBornCard=FeynFacet`ReadContributionCard[ttProject<>"/Raw/LO/qqp-qqp","Born"];
ttBornRun=FeynFacet`EvaluateBareContribution[ttBornCard,"all"];
If[!AssociationQ[ttBornRun],Print[ttBornRun];Exit[1]];
transverse=<|"LO"->ttBornRun["Result"]["Coefficients"][0],
 "NLO"->FeynFacet`ReadPartonicResult[ttProject<>"/Results/NLO/qqp-qqp/Results.wl"]["Coefficients"][0]|>;
check["TT/exact LO and NLO zero",AllTrue[Values[transverse],#["DeltaCoefficient"]===0&&AllTrue[Values[#["PlusCoefficients"]],#===0&]&&#["RegularCoefficient"]===0&]];
Do[record=FeynFacet`ReadPartonicResult[ttProject<>"/Raw/NLO/qqp-qqp/"<>kind<>"/Results.wl"];
 check["TT/generated "<>kind<>" coverage",record["ExactInEpsilon"]===True&&record["GeneratedInterferenceCount"]===If[kind==="Real",25,11]],{kind,{"Real","Virtual"}}];
(* Generate the nonzero control on every validation run, so stale output cannot
   hide a disabled transverse projector. Distinct-flavor production stays separate. *)
controlCard=FeynFacet`ReadProcessCard[ttProject<>"/Raw/LO/qqp-qqp","Born"];controlQuark=controlCard["Partons"][[1,1]];
controlCard=FeynFacet`CompleteProcessDiagramSelection[Join[controlCard,
 <|"Partons"->({controlQuark,controlQuark}->{controlQuark,controlQuark})|>]];
control=FeynFacet`ConstructBornInvariantDensity[controlCard,<|"Scale"->s,
 "MandelstamVariables"->{s,t,u},"DimensionalRegulator"->Global`Epsilon|>];
If[AssociationQ[control],controlPath=project<>"/Validation/tt_identical_flavor_control.wxf";
 Export[controlPath<>".tmp",control,"WXF",PerformanceGoal->"Size"];
 RenameFile[controlPath<>".tmp",controlPath,OverwriteTarget->True]];
check["TT/identical-flavor exchange nonzero control",AssociationQ[control]&&control["Coefficient"]=!=0];
report=<|"Status"->If[failed===0,"Passed","Failed"],"Passed"->passed,"Failed"->failed,"Checks"->rows,
 "LLReference"->"Supplied Vogelsang Mathematica expressions; overall convention and logarithmic basis recovered using Born/threshold normalization and verified by all 17 exact identities",
 "LLRegularBasis"->"EE Log[w]+F Log[v]+G Log[1-v]+H Log[1-w]+L(Log[1-v]-Log[1-vw])/(1-w)+M Log[1-v+vw]/(1-w)+CC",
 "UUReference"->ref["Source"],"PhysicalReferenceMultiplier"->"alpha_s^3/(8 CA^2 pi s^2)"|>;
FeynFacet`FamilyArtifactWrite[report,project<>"/Validation/NLOExternalReferences.wl"];
Print["NLO_EXTERNAL_REFERENCE_CHECKS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
