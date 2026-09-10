#!/usr/bin/env wolframscript
(* Independent reference-only comparison; this driver never enters production. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Usage: check_sidis_references.wls PROJECT"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>First[args]];
polarized=First[project["Polarization"]["Incoming"]]==="L";
referenceSource=root<>"/External/References/SIDIS/"<>If[polarized,"ancillary_LL_2404.08597v3.inc","ancillary_UU_2401.16281v2.inc"];
referenceFile=project["Directory"]<>"/NLO/q-q/Results/Validation/ReferenceNLOCoefficients.wl";
conversion=RunProcess[{"python3",root<>"/Tests/Support/sidis_form_reference.py",referenceSource,referenceFile}];
If[conversion["ExitCode"]=!=0,Print[conversion["StandardError"]];Exit[1]];
reference=FeynFacet`FamilyArtifactRead[referenceFile];
refExpression[row_,{},component_]:=If[ListQ[row],row[[component]],row];
refExpression[row_Association,axes_List,component_]:=With[{axis=First[axes],remaining=Rest[axes]},
 refExpression[row["DeltaCoefficient"],remaining,component] Dd[1-axis]+
 Total[KeyValueMap[refExpression[#2,remaining,component] Dn[#1,1-axis]&,row["PlusCoefficients"]]]+
 refExpression[row["RegularCoefficient"],remaining,component]];
report=<||>;count=0;failures=0;
Do[
 directory=project["Directory"]<>"/NLO/"<>channel;result=FeynFacet`ReadPartonicResult[directory<>"/Results/Result.wl"];
 If[!AssociationQ[result],Print["MISSING_RESULT ",channel];failures++;Continue[]];
 species=project["Channels"][channel];
 flavorType=Which[First[species["Incoming"]]==="g","G2Q",species["Observed"]==="g","Q2G",True,"Q2Q"];
 born=FeynFacet`ReadPartonicResult[project["Directory"]<>"/LO/q-q/Results/Result.wl"];
 charge=First[born["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"]];
 normalization=charge result["Coupling"]/(2Pi);
 axisVariables=result["Variables"];conditions=0<axisVariables[[1]]<1&&0<axisVariables[[2]]<1&&
  Q2>0&&muR2>0&&muF2>0&&muD2>0&&FeynCalc`CA>1;
 Do[
  key=If[polarized,"DC1"<>flavorType,"C1"<>If[component===1,"T","L"]<>flavorType];
  actual=refExpression[result["Coefficients"][0],axisVariables,component]/normalization;
  expected=reference[key]/.{NC->FeynCalc`CA,LMUR->Log[muR2/Q2],LMUF->Log[muF2/Q2],LMUA->Log[muD2/Q2]};
  objects=DeleteDuplicates[Cases[{actual,expected},_Dd|_Dn,Infinity]];
  markers=Unique["distributionCoefficient$"]&/@objects;
  polynomial=Expand[(actual-expected)/.Thread[objects->markers]];
  If[!PolynomialQ[polynomial,markers],Print["NONPOLYNOMIAL_DISTRIBUTIONS ",channel];failures++;Continue[]];
  residues=If[markers==={}, {polynomial},Last/@CoefficientRules[polynomial,markers]];
  exact=And@@(TrueQ[FullSimplify[#,Assumptions->conditions]===0]&/@residues);
  count++;If[!exact,failures++];
  AssociateTo[report,channel<>"/"<>project["StructureFunctions"][[component]]->
   <|"ReferenceCoefficient"->key,"ExactAgreement"->exact,"DistributionCoefficientCount"->Length[residues]|>];
  Print[If[exact,"PASS ","FAIL "],channel," ",project["StructureFunctions"][[component]]],
 {component,Length[project["StructureFunctions"]]}],
 {channel,project["Orders"]["NLO"]}];
output=project["Directory"]<>"/NLO/q-q/Results/Validation/LiteratureComparison.wl";
FeynFacet`FamilyArtifactWrite[<|"ReferenceFile"->referenceSource,"Checks"->count,"Failures"->failures,
 "Normalization"->"Published coefficient times the generated Born flavor charge squared and alpha_s/(2 pi)",
 "Results"->report|>,output];
Print["SIDIS_REFERENCE_CHECKS ",count-failures,"/",count];
If[failures>0||count=!=Length[project["Orders"]["NLO"]]Length[project["StructureFunctions"]],Exit[1]];
