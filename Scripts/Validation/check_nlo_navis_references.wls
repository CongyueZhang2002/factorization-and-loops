#!/usr/bin/env wolframscript
(* Full finite NNLO-campaign NLO scattering comparisons with public Navis.
   Reference expressions remain external validation inputs. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: check_nlo_navis_references.wls UU_PROJECT LL_PROJECT"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projects=AssociationThread[{"UU","LL"},FeynFacet`ReadProjectCard[root<>"/Projects/"<>#]&/@args];
If[!AllTrue[Values[projects],AssociationQ],Print[projects];Exit[1]];
channels=<|"qqp-qqp"->1,"qqbar-qpqpbar"->5,"qg-qg"->13,"u-g_g-u"->14|>;
referencePath=projects["LL"]["Directory"]<>"/NLO/qg-qg/Results/Validation/Navis_points.json";
proc=RunProcess[{"python3",root<>"/Tests/Support/Navis/evaluate_reference.py",
 root<>"/External/References/ppHX_NLO",referencePath}];
If[proc["ExitCode"]=!=0||!StringContainsQ[proc["StandardOutput"],"NAVIS_REFERENCE_POINTS 40 COEFFICIENTS 320"],Print[proc];Exit[1]];
reference=Import[referencePath,"RawJSON"];passed=0;failed=0;reports={};
vector[r_]:={r["DeltaCoefficient"],Lookup[r["PlusCoefficients"],0,0],Lookup[r["PlusCoefficients"],1,0],r["RegularCoefficient"]};
Do[
 project=projects[pol];directory=project["Directory"]<>"/NLO/"<>channel;
 polarization=<|"Incoming"->If[pol==="UU",{"U","U"},{"L","L"}],"Observed"->"U"|>;
 result=FeynFacet`ReadPartonicResult[directory<>"/Results/Result.wl",
  <|"Order"->"NLO","Contribution"->"Total","Polarization"->polarization,"EpsilonRange"->{0,0}|>];
 If[!AssociationQ[result],Print[result];Exit[1]];
 physical=result["PhysicalChannel"];inc=physical["Incoming"];obs=physical["Observed"];j=channels[channel];
 eligible=Switch[j,
  1,MatchQ[inc,{{"q",_},{"q",_}}]&&inc[[1,2]]=!=inc[[2,2]]&&obs===inc[[1]],
  5,MatchQ[inc,{{"q",_},{"qbar",_}}]&&inc[[1,2]]===inc[[2,2]]&&MatchQ[obs,{"q",_}]&&Last[obs]=!=inc[[1,2]],
  13,MatchQ[inc,{{"q",_},"g"}]&&obs===inc[[1]],
  14,MatchQ[inc,{{"q",_},"g"}]&&obs==="g"];
 If[!TrueQ[eligible],Print["Reference physical channel mismatch: ",channel];Exit[2]];
 ct=project["Counterterms"];ca=ct["KernelParameters"]["CA"];cf=ct["KernelParameters"]["CF"];
 {sv,{vv,ww}}=Lookup[result,{"Scale","Variables"}];alpha=ct["Coupling"];
 cc=Times@@(If[#==="g",ca^2-1,ca]&/@inc);multiplier=alpha^3/(8cc Pi sv^2);
 expr=vector[result["Coefficients"][0]]/multiplier;checks={};started=AbsoluteTime[];
 Do[
  {pv,pw,ps,pmf,pmd,pmr,pnf,pca}=ToExpression/@reference["Points"][[i]];
  rules={vv->pv,ww->pw,sv->ps,ct["RenormalizationScaleSquared"]->pmr,
   ct["FactorizationScalesSquared"]["IncomingA"]->pmf,
   ct["FactorizationScalesSquared"]["IncomingB"]->pmf,
   ct["FactorizationScalesSquared"]["Observed"]->pmd,
   project["ProcessDefaults"]["MasslessQuarkFlavors"]["UpType"]->Floor[pnf/2],
   project["ProcessDefaults"]["MasslessQuarkFlavors"]["DownType"]->Ceiling[pnf/2],
   ca->pca,cf->(pca^2-1)/(2pca)};
  actual=N[expr/.rules,25];expected=reference["Channels"][ToString[j]][pol][[i]];
  If[!VectorQ[actual,NumberQ],Print["Unresolved numerical input: ",InputForm[actual]];Exit[1]];
  errors=MapThread[Abs[#1-#2]/Max[1,Abs[#1],Abs[#2]]&,{actual,expected}];
  Do[
   ok=TrueQ[errors[[k]]<2*10^-10];If[ok,passed++,failed++];
   AppendTo[checks,<|"Point"->i,"Coefficient"->reference["OutputCoefficients"][[k]],
    "Passed"->ok,"RelativeError"->errors[[k]],"Actual"->actual[[k]],"Reference"->expected[[k]]|>];
   If[!ok,Print["FAIL ",pol,"/",channel,"/point",i,"/",reference["OutputCoefficients"][[k]],
     " error=",errors[[k]]," actual=",actual[[k]]," reference=",expected[[k]]]],
   {k,4}],{i,Length[reference["Points"]]}];
 report=<|"Status"->If[AllTrue[checks,TrueQ[#["Passed"]]&],"Passed","Failed"],
  "PhysicalChannel"->physical,"Polarization"->polarization,"ReferenceChannel"->j,
  "Passed"->Count[Lookup[checks,"Passed"],True],"Failed"->Count[Lookup[checks,"Passed"],False],
  "Checks"->checks,"ParameterPoints"->reference["Points"],"InputVariables"->reference["InputVariables"],
  "PhysicalMultiplier"->multiplier,"ReferenceSource"->reference["Source"],
  "NormalizationSource"->reference["NormalizationSource"],"Schemes"->reference["Schemes"],
  "SecondsExcludingLoading"->AbsoluteTime[]-started|>;
 FeynFacet`Private`projectWrite[report,directory<>"/Results/Validation/NavisReferences.wl"];
 AppendTo[reports,KeyDrop[report,{"Checks"}]];
 Print[report["Status"]," ",pol,"/",channel," ",report["Passed"],"/",Length[checks],
  " max error=",Max[Lookup[checks,"RelativeError"]]," seconds=",report["SecondsExcludingLoading"]],
 {pol,{"UU","LL"}},{channel,Keys[channels]}];
FeynFacet`Private`projectWrite[<|"Status"->If[failed===0,"Passed","Failed"],"Passed"->passed,"Failed"->failed,
 "Reports"->reports|>,DirectoryName[referencePath]<>"/NavisCampaignReferences.wl"];
Print["NLO_NAVIS_REFERENCE_CHECKS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
