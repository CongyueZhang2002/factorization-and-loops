(* Flavor-complete collinear operator renormalization through a^2.
   Reference a=alpha_s/(2 Pi), beta_D(a)=-epsilon a-b0 a^2.
   MSbarCouplingNormalization supplies the exact finite-epsilon coupling map.
   Bare PDFs = Z convolution renormalized PDFs; a fragmentation matrix
   stores physical parent first. No finite hard coefficient is used here. *)
BeginPackage["FeynFacet`"];
CollinearRenormalizationKernel::usage="CollinearRenormalizationKernel[daughter,parent,spin,x,epsilon,parameters,order,request] returns the explicit coefficient of a^order in the MS collinear transition matrix, a=alpha_s/(2 Pi). Request declares Evolution (SpaceLike or TimeLike), ScaleLog=log(muF^2/muR^2), OperatorScheme, and optional Inverse. Individual physical daughter <- parent labels are used for both evolutions. Larin helicity P1 is derived from the conventional helicity-MSbar kernel and its finite operator transformation.";
PlanCollinearRenormalization::usage="PlanCollinearRenormalization[targetSpecies,request] builds the general UV and collinear coefficient plan from physical PDF/FF leg declarations. Each leg supplies Role, Spin, Variable, ScaleLog and OperatorScheme; KernelParameters supplies CA, CF, TR and FlavorCount. The formal parameter is a=alpha_s/(2 Pi), with physical coupling powers already in the bare sources. CouplingNormalization declares the exact bare-coupling convention; omitted means the reference MSbar convention.";

InverseFactorizationSchemeKernel::usage="InverseFactorizationSchemeKernel[scheme,daughter,parent,spin,x,parameters,order,request] gives the inverse finite PDF/FF redefinition through order two, at a=alpha_s(muR)/(2 Pi). It includes the beta0 ScaleLog F1 term from a(muF). Built-in helicity kernels are spacelike; other evolutions need an explicit finite definition.";
PlanFiniteFactorizationSchemeChange::usage="PlanFiniteFactorizationSchemeChange[targetSpecies,request] plans a finite epsilon-zero operator scheme change on already UV-renormalized and collinearly subtracted coefficients. Each leg declares Role, Spin, Variable, ScaleLog and OperatorRedefinition. Coupling renormalization is disabled, and finite sources with uncancelled poles are refused.";
MSbarCouplingRenormalization::usage="MSbarCouplingRenormalization[parameters,normalization] returns the coefficients of a and a^2 in the bare strong-coupling renormalization constant, a=alpha_s/(2 Pi), using the declared exact MSbar coupling-normalization record.";
Begin["`Private`"];


MSbarCouplingRenormalization[parameters_Association,normalization_Association]:=Catch[Module[{e,n,b0,b1},
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}]||
   Lookup[normalization,"Format",None]=!="FeynFacet-MSbarCouplingNormalization"||
   !MatchQ[Lookup[normalization,"DimensionalRegulator",None],_Symbol],
  collinearKernelFail["QCDParametersAndCouplingNormalizationRequired"]];
 e=normalization["DimensionalRegulator"];n=normalization["PoleNormalization"];
 b0=(11parameters["CA"]-4parameters["TR"]parameters["FlavorCount"])/6;
 b1=(17parameters["CA"]^2-10parameters["CA"]parameters["TR"]parameters["FlavorCount"]-
     6parameters["CF"]parameters["TR"]parameters["FlavorCount"])/6;
 <|1->-b0 n/e,2->n^2(b0^2/e^2-b1/(2e))|>
],"CollinearCounterterms"];

collinearKernelSum[rows_List,x_]:=Join[partonicDistributionSum[rows,1],<|"Variable"->x|>];
collinearKernelScale[row_,factor_]:=Join[partonicMap[Function[value,factor value],row],<|"Variable"->row["Variable"]|>];
collinearIntermediateSpecies[daughter_,parent_,nf_]:=Module[{flavors,other="SummedFlavor"},
 flavors=DeleteDuplicates[Last/@Select[{daughter,parent},#=!="g"&]];
 While[MemberQ[flavors,other],other=other<>"_"];
 Join[{{"g",1}},Flatten[Table[{{{"q",f},1},{{"qb",f},1}},{f,flavors}],1],
  {{{"q",other},nf-Length[flavors]},{{"qb",other},nf-Length[flavors]}}]
];
collinearKernelProduct[left_,right_,daughter_,parent_,x_,nf_]:=Module[{rows,answer},
 rows=Table[
  If[intermediate[[2]]===0,Nothing,
   answer=FeynFacet`MellinConvolveDistributions[
    left[daughter,intermediate[[1]]],right[intermediate[[1]],parent],x];
   If[FailureQ[answer],collinearKernelFail["CollinearKernelConvolutionFailed",<|"Cause"->answer|>]];
   collinearKernelScale[Join[answer,<|"Variable"->x|>],intermediate[[2]]]],
  {intermediate,collinearIntermediateSpecies[daughter,parent,nf]}];
 collinearKernelSum[rows,x]
];
CollinearRenormalizationKernel[daughter_,parent_,spin_,x_Symbol,e_Symbol,
 parameters_Association,order_Integer,request_Association]:=Catch[Module[
 {evolution,scheme,scaleLog,inverse,p0,p1,f1,product,commutator,b0,nf,eta,answer,lo,finite},
 If[!MemberQ[{0,1,2},order]||x===e||!collinearKernelSpeciesQ[daughter]||
  !collinearKernelSpeciesQ[parent]||!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],
  collinearKernelFail["CollinearRenormalizationRequestRequired"]];
 evolution=Lookup[request,"Evolution",None];scheme=Lookup[request,"OperatorScheme",None];
 scaleLog=Lookup[request,"ScaleLog",0];inverse=Lookup[request,"Inverse",False];
 If[!MemberQ[{"SpaceLike","TimeLike"},evolution]||!MemberQ[{True,False},inverse]||
  !FreeQ[{scaleLog,parameters},x|e]||
  (spin==="L"&&!MemberQ[{"HelicityMSbar","Larin"},scheme])||
  (spin=!="L"&&scheme=!="MSbar")||(order===2&&evolution==="TimeLike"&&spin=!="U"),
  collinearKernelFail["ExplicitCollinearEvolutionAndOperatorSchemeRequired"]];
 If[order===0,Return[Join[collinearKernelRecord[x,If[daughter===parent,1,0],<||>,0],
   <|"PerturbativeOrder"->0,"Evolution"->evolution,"OperatorScheme"->scheme|>]]];
 nf=parameters["FlavorCount"];b0=(11parameters["CA"]-4parameters["TR"]nf)/6;eta=Exp[-e scaleLog];
 lo[a_,b_]:=LeadingSplittingKernel[a,b,spin,x,parameters];
 finite[a_,b_]:=FactorizationSchemeKernel["HelicityMSbar",a,b,spin,x,parameters,1];
 p0=lo[daughter,parent];
 If[FailureQ[p0],collinearKernelFail["LeadingSplittingKernelFailed",<|"Cause"->p0|>]];
 If[order===1,answer=collinearKernelScale[p0,If[inverse,-1,1]eta/e],
  product=collinearKernelProduct[lo,lo,daughter,parent,x,nf];
  p1=NextToLeadingSplittingKernel[daughter,parent,spin,x,parameters,evolution];
  If[FailureQ[p1],collinearKernelFail["NextToLeadingSplittingKernelFailed",<|"Cause"->p1|>]];
  If[spin==="L"&&scheme==="Larin",
   f1=finite[daughter,parent];
   commutator=collinearKernelSum[{
    collinearKernelProduct[finite,lo,daughter,parent,x,nf],
    collinearKernelScale[collinearKernelProduct[lo,finite,daughter,parent,x,nf],-1]},x];
   p1=collinearKernelSum[{p1,collinearKernelScale[commutator,-1],collinearKernelScale[f1,b0]},x]];
  answer=collinearKernelSum[{
   collinearKernelScale[product,eta^2/(2e^2)],
   collinearKernelScale[p0,b0(eta^2-2eta)/(2e^2)],
   collinearKernelScale[p1,eta^2/(2e)]},x];
  If[inverse,answer=collinearKernelSum[{
    collinearKernelScale[product,eta^2/e^2],collinearKernelScale[answer,-1]},x]]
 ];
 Join[answer,<|"Daughter"->daughter,"Parent"->parent,"Spin"->spin,
  "Evolution"->evolution,"OperatorScheme"->scheme,"PerturbativeOrder"->order,
  "DimensionalRegulator"->e,"PerturbativeParameter"->"alpha_s/(2 Pi)",
  "ScaleLog"->scaleLog,"Inverse"->inverse,"FlavorSum"->"All individual quarks, antiquarks and the gluon",
  "Convention"->"f_bare=Z convolution f; fragmentation matrix parent first"|>]
],"CollinearCounterterms"];

PlanCollinearRenormalization[target_List,request_Association]:=Catch[Module[
 {legs,parameters,e,provider,coupling,normalization,poleNormalization,externalSymbols,answer},
 legs=Lookup[request,"Legs",{}];parameters=Lookup[request,"KernelParameters",<||>];
 e=Lookup[request,"DimensionalRegulator",None];
 If[!MatchQ[legs,{_Association...}]||!AllTrue[legs,
   ContainsAll[Keys[#],{"Role","Spin","Variable","ScaleLog","OperatorScheme"}]&&
   MemberQ[{"PDF","FF"},#["Role"]]&]||
  !ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],
  collinearKernelFail["PhysicalCollinearLegDeclarationsRequired"]];
 normalization=Lookup[request,"CouplingNormalization",
  MSbarCouplingNormalization[e,Exp[-e(Log[4Pi]-EulerGamma)]]];
 If[!AssociationQ[normalization]||
   Lookup[normalization,"Format",None]=!="FeynFacet-MSbarCouplingNormalization"||
   Lookup[normalization,"DimensionalRegulator",None]=!=e,
  collinearKernelFail["MSbarCouplingNormalizationRecordRequired"]];
 poleNormalization=normalization["PoleNormalization"];
 externalSymbols=DeleteDuplicates[Cases[
   {Lookup[request,"PerturbativeParameter",None],(#["Variable"]&/@legs),
    (#["ScaleLog"]&/@legs)},symbol_Symbol/;Context[symbol]=!="System`",Infinity]];
 If[!FreeQ[poleNormalization,Alternatives@@DeleteCases[externalSymbols,e]]||
   !AllTrue[legs,Lookup[#,"PoleNormalization",poleNormalization]===poleNormalization&],
  collinearKernelFail["CommonScaleIndependentCouplingNormalizationRequired"]];
 coupling=Lookup[request,"CouplingRenormalization",MSbarCouplingRenormalization[parameters,normalization]];
 If[!AssociationQ[coupling],collinearKernelFail["CouplingRenormalizationCoefficientsRequired"]];
 provider=Function[{j,src,dst,n},With[{leg=legs[[j]]},
  If[leg["Role"]==="PDF",FeynFacet`PDFCountertermDistribution,FeynFacet`FFCountertermDistribution][
   If[leg["Role"]==="PDF",src,dst],If[leg["Role"]==="PDF",dst,src],
   Join[<|"PoleNormalization"->poleNormalization|>,KeyTake[leg,{"Spin","Variable","ScaleLog","OperatorScheme","PoleNormalization"}],
    <|"DimensionalRegulator"->e,"KernelParameters"->parameters,
      "PerturbativeOrder"->n,"Operation"->"CollinearSubtraction"|>]]]];
 answer=FeynFacet`PlanPartonicRenormalization[target,Join[request,<|
   "CouplingNormalization"->normalization,"CouplingRenormalization"->coupling,"TransitionKernel"->provider|>]];
 If[AssociationQ[answer],Join[answer,<|"CouplingNormalization"->normalization|>],answer]
],"CollinearCounterterms"];

InverseFactorizationSchemeKernel[scheme_,daughter_,parent_,spin_,x_Symbol,
 parameters_Association,order_Integer,request_Association]:=Catch[Module[
 {evolution,scaleLog,b0,first,second,product,finite,answer},
 evolution=Lookup[request,"Evolution",None];scaleLog=Lookup[request,"ScaleLog",None];
 If[!MemberQ[{"SpaceLike","TimeLike"},evolution]||scaleLog===None||
   !MemberQ[{0,1,2},order]||
   !ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}]||
   !FreeQ[scaleLog,x]||(order===2&&evolution==="TimeLike"&&spin==="L"&&scheme==="HelicityMSbar"),
  collinearKernelFail["DeclaredFiniteOperatorRedefinitionAndScaleRequired"]];
 finite[a_,b_]:=FeynFacet`FactorizationSchemeKernel[scheme,a,b,spin,x,parameters,1,<|"Evolution"->evolution|>];
 If[order===0,Return[Join[FeynFacet`FactorizationSchemeKernel[scheme,daughter,parent,spin,x,parameters,0],
  <|"Daughter"->daughter,"Parent"->parent,"Evolution"->evolution,"PerturbativeOrder"->0|>],Module]];
 first=finite[daughter,parent];
 If[!AssociationQ[first],collinearKernelFail["FiniteOperatorKernelFailed",<|"Cause"->first|>]];
 If[order===1,answer=collinearKernelScale[first,-1],
  second=FeynFacet`FactorizationSchemeKernel[scheme,daughter,parent,spin,x,parameters,2,<|"Evolution"->evolution|>];
  If[!AssociationQ[second],collinearKernelFail["SecondFiniteOperatorKernelRequired",<|"Cause"->second|>]];
  product=collinearKernelProduct[finite,finite,daughter,parent,x,parameters["FlavorCount"]];
  b0=(11parameters["CA"]-4parameters["TR"]parameters["FlavorCount"])/6;
  answer=collinearKernelSum[{product,collinearKernelScale[second,-1],
    collinearKernelScale[first,b0 scaleLog]},x]];
 Join[answer,<|"Daughter"->daughter,"Parent"->parent,"Evolution"->evolution,
  "PerturbativeOrder"->order,"OperatorRedefinition"->scheme,"ScaleLog"->scaleLog,
  "Convention"->"Inverse of f_new=(1+a(muF) F1+a(muF)^2 F2) convolution f_old; a=alpha_s/(2 Pi)."|>]
],"CollinearCounterterms"];
PlanFiniteFactorizationSchemeChange[target_List,request_Association]:=Catch[Module[
 {legs,parameters,provider,answer},
 legs=Lookup[request,"Legs",{}];parameters=Lookup[request,"KernelParameters",<||>];
 If[!MatchQ[legs,{_Association...}]||!AllTrue[legs,
  ContainsAll[Keys[#],{"Role","Spin","Variable","ScaleLog","OperatorRedefinition"}]&&
  MemberQ[{"PDF","FF"},#["Role"]]&]||Lookup[request,"ThroughOrder",None]=!=0,
  collinearKernelFail["FiniteSchemePhysicalLegsAndEpsilonZeroRequired"]];
 provider=Function[{j,src,dst,n},With[{leg=legs[[j]]},
  If[leg["Role"]==="PDF",FeynFacet`PDFCountertermDistribution,FeynFacet`FFCountertermDistribution][
   If[leg["Role"]==="PDF",src,dst],If[leg["Role"]==="PDF",dst,src],
   Join[KeyTake[leg,{"Spin","Variable","ScaleLog","OperatorScheme","OperatorRedefinition"}],
    <|"DimensionalRegulator"->request["DimensionalRegulator"],"KernelParameters"->parameters,
      "PerturbativeOrder"->n,"Operation"->"FiniteSchemeChange"|>]]]];
 answer=FeynFacet`PlanPartonicRenormalization[target,Join[request,
  <|"CouplingRenormalization"-><|1->0,2->0|>,"SourceRenormalizationStage"->"Renormalized",
    "TransitionKernel"->provider|>]];
 If[!AssociationQ[answer],Return[answer,Module]];
 Join[answer,<|"Transformation"->"FiniteFactorizationSchemeChange",
  "FiniteSchemeLegs"->legs,"PositiveEpsilonSchemeContinuationDefined"->False|>]
],"CollinearCounterterms"];
End[];EndPackage[];
