#!/usr/bin/env wolframscript
(* Reference-only comparison with arXiv:1307.6925, section 5 and appendix.
   Their stored rsigc is x times the Mellin-convolution coefficient and uses
   alpha_s/pi, TF=1/2, Lv=log(mu^2/Q2), with mu_R=mu_F.
   Neither these functions nor their coefficients enter production. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[Length[args]<1,Print["Usage: check_drell_yan_references.wls PROJECT [CHANNEL ...]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>First[args]];
referenceFile=root<>"/External/References/DrellYan/sig_DY_LO_NLO_NNLO.m";
Block[{$Context="DrellYanReference`",$ContextPath={"System`"}},Get[referenceFile]];
channels=If[Length[args]>1,Rest[args],project["Orders"]["NLO"]];
refToLogs={DrellYanReference`HPL[{0},y_]:>Log[y],
 DrellYanReference`HPL[{1},y_]:>-Log[1-y],DrellYanReference`HPL[{2},y_]:>PolyLog[2,y],
 DrellYanReference`HPL[{0,0},y_]:>Log[y]^2/2,
 DrellYanReference`HPL[{1,0},y_]:>-PolyLog[2,y]-Log[y]Log[1-y],
 DrellYanReference`HPL[{1,1},y_]:>Log[1-y]^2/2};
refCoefficient[row_]:=If[ListQ[row],First[row],row];
refExpression[row_Association]:=refCoefficient[row["DeltaCoefficient"]]dyDelta+
 Total[KeyValueMap[refCoefficient[#2]dyPlus[#1]&,row["PlusCoefficients"]]]+
 refCoefficient[row["RegularCoefficient"]];
report=<||>;count=0;failures=0;
Do[
 result=FeynFacet`ReadPartonicResult[project["Directory"]<>"/NLO/"<>channel<>"/Results/Result.wl"];
 If[!AssociationQ[result],Print["MISSING_RESULT ",channel];failures++;Continue[]];
 born=FeynFacet`ReadPartonicResult[project["Directory"]<>"/LO/q-qbar/Results/Result.wl"];
 charge=First[born["Coefficients"][0]["DeltaCoefficient"]];
 key=If[MemberQ[project["Channels"][channel]["Incoming"],"g"],"qg","qb"];
 ref=DrellYanReference`rsigc["NLO",key]/DrellYanReference`x;
 Do[
  actual=refExpression[result["Coefficients"][order]]/(charge result["Coupling"]/Pi)/.muR2->muF2;
  expected=Coefficient[ref,DrellYanReference`ep,order]/.refToLogs/.{
    DrellYanReference`coeff[_]->1,DrellYanReference`TF->1/2,
    DrellYanReference`CF->(FeynCalc`CA^2-1)/(2FeynCalc`CA),
    DrellYanReference`CA->FeynCalc`CA,DrellYanReference`Lv->Log[muF2/Q2],
    DrellYanReference`x->z,
    DrellYanReference`PlusDistribution[-1,_]->dyDelta,
    DrellYanReference`PlusDistribution[n_Integer?NonNegative,_]:>dyPlus[n]};
  objects=DeleteDuplicates[Cases[{actual,expected},dyDelta|_dyPlus,Infinity]];
  markers=Unique["distributionCoefficient$"]&/@objects;
  polynomial=Expand[(actual-expected)/.Thread[objects->markers]];
  residues=If[markers==={}, {polynomial},Last/@CoefficientRules[polynomial,markers]];
  exact=FreeQ[expected,_DrellYanReference`HPL]&&
   And@@(TrueQ[FullSimplify[#,Assumptions->0<z<1&&Q2>0&&muF2>0&&FeynCalc`CA>1]===0]&/@residues);
  count++;If[!exact,failures++];
  AssociateTo[report,channel<>"/epsilon"<>ToString[order]-><|"ExactAgreement"->exact,
   "ReferenceChannel"->key,"DistributionCoefficientCount"->Length[residues]|>];
  Print[If[exact,"PASS ","FAIL "],channel," epsilon^",order],{order,{0,1}}];
 scaleCheck=FeynFacet`Private`partonicZeroTreeQ[
  FeynFacet`Private`partonicMap[Function[value,FullSimplify[D[value,muR2],Assumptions->muR2>0]],
  result["Coefficients"][0]]];
 count++;If[!scaleCheck,failures++];
 AssociateTo[report,channel<>"/independentRenormalizationScale"-><|"ExactAgreement"->scaleCheck|>];
 Print[If[scaleCheck,"PASS ","FAIL "],channel," finite coefficient independent of mu_R"],
 {channel,channels}];
output=project["Directory"]<>"/NLO/q-qbar/Results/Validation/LiteratureComparison.wl";
FeynFacet`FamilyArtifactWrite[<|"ReferenceFile"->referenceFile,
 "ReferencePaper"->"https://arxiv.org/abs/1307.6925","Checks"->count,"Failures"->failures,
 "Normalization"->"rsigc/x, charge squared alpha_s/pi, TF=1/2, mu_R=mu_F; finite mu_R independence checked separately",
 "Results"->report|>,output];
Print["DRELL_YAN_REFERENCE_CHECKS ",count-failures,"/",count];
Exit[If[failures===0&&count===3Length[channels],0,1]];
