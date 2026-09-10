#!/usr/bin/env wolframscript
(* Original INCNLO finite coefficients; optional annihilation LL=-UU check.
   No reference quantity enters production or determines a fitted factor. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[!MemberQ[{3,4},Length[args]],Print["Usage: check_nlo_scattering_references.wls UU_PROJECT CHANNEL INCNLO_INDEX [LL_PROJECT]"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
{projectName,channelName}=Take[args,2];referenceIndex=ToExpression[args[[3]]];
If[!MemberQ[{1,5,13,14},referenceIndex],Print["Reference tag normalization is established for indices 1,5,13,14 only."];Exit[2]];
project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>projectName];directory=project["Directory"]<>"/NLO/"<>channelName;
result=FeynFacet`ReadPartonicResult[directory<>"/Results/Result.wl",<|"Order"->"NLO","Contribution"->"Total","EpsilonRange"->{0,0}|>];
If[!AssociationQ[result],Print[result];Exit[1]];
physical=result["PhysicalChannel"];inc=physical["Incoming"];obs=physical["Observed"];
eligible=Switch[referenceIndex,
 1,MatchQ[inc,{{"q",_},{"q",_}}]&&inc[[1,2]]=!=inc[[2,2]]&&obs===inc[[1]],
 5,MatchQ[inc,{{"q",_},{"qbar",_}}]&&inc[[1,2]]===inc[[2,2]]&&MatchQ[obs,{"q",_}]&&Last[obs]=!=inc[[1,2]],
 13,MatchQ[inc,{{"q",_},"g"}]&&obs===inc[[1]],
 14,MatchQ[inc,{{"q",_},"g"}]&&obs==="g"];
If[!TrueQ[eligible]||result["Polarization"]=!=<|"Incoming"->{"U","U"},"Observed"->"U"|>,Print["Reference channel identity mismatch."];Exit[2]];
passed=0;failed=0;checks={};
check[name_,test_,detail_:None]:=(If[TrueQ[test],passed++,failed++];
 AppendTo[checks,<|"Check"->name,"Passed"->TrueQ[test],"Detail"->detail|>];
 Print[If[TrueQ[test],"PASS ","FAIL "],name]);
referencePath=directory<>"/Results/Validation/INCNLO_points.json";
proc=RunProcess[{"python3",root<>"/Tests/Support/INCNLO/evaluate_reference.py",
 root<>"/External/References/ppHX_NLO",referencePath,"--channel",ToString[referenceIndex]}];
If[proc["ExitCode"]=!=0||!StringContainsQ[proc["StandardOutput"],"INCNLO_REFERENCE_POINTS 8"],Print[proc];Exit[1]];
reference=Import[referencePath,"RawJSON"];
ct=project["Counterterms"];ca=ct["KernelParameters"]["CA"];cf=ct["KernelParameters"]["CF"];
{sv,{vv,ww}}=Lookup[result,{"Scale","Variables"}];alpha=ct["Coupling"];
cc=Times@@(If[#==="g",ca^2-1,ca]&/@inc);multiplier=alpha^3/(8cc Pi sv^2);
row=result["Coefficients"][0];vector[r_]:={r["DeltaCoefficient"],Lookup[r["PlusCoefficients"],0,0],Lookup[r["PlusCoefficients"],1,0],r["RegularCoefficient"]};
expr=vector[row]/multiplier;
Do[{pv,pw,ps,pmf,pmd,pmr,pnf}=ToExpression/@reference["Points"][[i]];
 rules={vv->pv,ww->pw,sv->ps,ct["RenormalizationScaleSquared"]->pmr,
  ct["FactorizationScalesSquared"]["IncomingA"]->pmf,ct["FactorizationScalesSquared"]["IncomingB"]->pmf,
  ct["FactorizationScalesSquared"]["Observed"]->pmd,
  project["ProcessDefaults"]["MasslessQuarkFlavors"]["UpType"]->Floor[pnf/2],
  project["ProcessDefaults"]["MasslessQuarkFlavors"]["DownType"]->Ceiling[pnf/2],ca->3,cf->4/3};
 actual=N[expr/.rules,25];
 If[!VectorQ[actual,NumberQ],Print["Unresolved numerical variables: ",InputForm[actual]];Exit[1]];
 errors=MapThread[Abs[#1-#2]/Max[1,Abs[#1],Abs[#2]]&,{actual,reference["Values"][[i]]}];
 Do[check["UU/INCNLO/point"<>ToString[i]<>"/"<>reference["OutputCoefficients"][[k]],errors[[k]]<2*10^-10,errors[[k]]],{k,4}],
 {i,Length[reference["Points"]]}];
If[Length[args]===4,
 If[referenceIndex=!=5,Print["Exact LL=-UU comparison applies only to the selected distinct-flavor annihilation channel."];Exit[2]];
 polarized=FeynFacet`ReadPartonicResult[root<>"/Projects/"<>args[[4]]<>"/NLO/"<>channelName<>"/Results/Result.wl",
  <|"Order"->"NLO","Contribution"->"Total","PhysicalChannel"->physical,
    "Polarization"-><|"Incoming"->{"L","L"},"Observed"->"U"|>,"EpsilonRange"->{0,0}|>];
 If[!AssociationQ[polarized],Print[polarized];Exit[1]];
 difference=vector[polarized["Coefficients"][0]]+vector[row];
 Do[check["LL/annihilation helicity identity/"<>reference["OutputCoefficients"][[i]],
  Factor[difference[[i]]/.project["ColorRules"]]===0],{i,4}]];
report=<|"Status"->If[failed===0,"Passed","Failed"],"Passed"->passed,"Failed"->failed,"Checks"->checks,
 "ReferenceChannel"->referenceIndex,"PhysicalMultiplier"->multiplier,
 "NormalizationSource"->reference["NormalizationSource"],
 "LLReference"->If[Length[args]===4,"hep-ph/0211007, equation (25), helicity-preserving factorization scheme",None]|>;
FeynFacet`Private`projectWrite[report,directory<>"/Results/Validation/NLOScatteringReferences.wl"];
Print["NLO_SCATTERING_REFERENCE_CHECKS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
