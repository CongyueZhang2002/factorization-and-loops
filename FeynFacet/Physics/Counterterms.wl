(* Collinear subtraction of invariant single-inclusive partonic densities.
   Kernels use a_s=alpha_s/(2 Pi) and explicit daughter <- parent labels.
   Finite scheme kernels mean f_new=(1+a_s Z) convolution f_old. *)
BeginPackage["FeynFacet`"];
LeadingSplittingKernel::usage="LeadingSplittingKernel[daughter,parent,spin,xi,parameters] gives LO delta/plus/regular kernels for individual species {q,flavor}, {qbar,flavor}, or g. Parameters declares CA, CF, TR, and FlavorCount. Spin is U, L, or T. Plus[k] means [Log[1-xi]^k/(1-xi)]_+.";
FactorizationSchemeKernel::usage="FactorizationSchemeKernel[name,daughter,parent,spin,xi,parameters,order] supplies the coefficient of (alpha_s/(2 Pi))^order in the finite PDF/FF redefinition Z. The default order is one; order zero is the identity. HelicityMSbar provides the full-flavor Larin-to-MSbar PDF coefficients through order two; using them requires a matching raw operator definition. MSbar has no finite corrections. Cards may supply FiniteKernelsByOrder or a channel kernel with an explicit PerturbativeOrder.";
ConvolveBornCollinearKernel::usage="ConvolveBornCollinearKernel[born,kernel,request] acts on the invariant Born density b(s,t,u;epsilon) delta(s+t+u). Born is a common LO PartonicResult with explicit epsilon coefficients and MandelstamVariables. Request declares Leg (IncomingA, IncomingB, or Observed), Scale s, Variables {v,w}. It returns exact delta/plus/regular coefficients on 0<w<=1, with the complete D-dimensional FF Jacobian.";
ConvolveBornMellinKernel::usage="ConvolveBornMellinKernel[born,kernel,axis,range] convolves a corner-supported Born partonic result with a one-variable Mellin kernel, preserving every declared epsilon coefficient and all other distribution axes.";
ConstructCurrentCollinearCounterterm::usage="ConstructCurrentCollinearCounterterm[bornResults,request] constructs the NLO incoming PDF and observed FF counterterms for declared PDF/FF legs of a current process from explicit LO dependencies, LO splitting kernels and the declared finite schemes.";
Begin["`Private`"];
ClearAll[collinearKernelFail,collinearKernelSpeciesQ,collinearKernelRecord,
 collinearKernelValidate,collinearBornMap];
collinearKernelFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"CollinearCounterterms"];
collinearKernelSpeciesQ[x_]:=x==="g"||MatchQ[x,{"q"|"qbar",_Integer|_String}];
collinearKernelRecord[x_,delta_,plus_,regular_]:=<|"Variable"->x,
 "DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular|>;
collinearKernelValidate[k_]:=Module[{x,plus},
 If[!AssociationQ[k]||!ContainsAll[Keys[k],{"Variable","DeltaCoefficient","PlusCoefficients","RegularCoefficient"}],
  collinearKernelFail["SplittingKernelDecompositionRequired"]];
 x=k["Variable"];plus=k["PlusCoefficients"];
 If[!MatchQ[x,_Symbol]||!AssociationQ[plus]||!AllTrue[Keys[plus],IntegerQ[#]&&#>=0&]||
  !FreeQ[{k["DeltaCoefficient"],Values[plus]},x]||
  !FreeQ[k,_Real|_SeriesData|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  collinearKernelFail["ExplicitCollinearKernelRequired"]];k
];
LeadingSplittingKernel[daughter_,parent_,spin_,xi_Symbol,parameters_Association]:=Catch[Module[
 {ca,cf,tr,nf,beta,delta=0,plus=<||>,regular=0,sameQuark},
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||!MemberQ[{"U","L","T"},spin],
  collinearKernelFail["PartonSpeciesAndSpinRequired"]];
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],collinearKernelFail["ColorAndFlavorParametersRequired"]];
 {ca,cf,tr,nf}=Lookup[parameters,{"CA","CF","TR","FlavorCount"}];beta=(11ca-4tr nf)/3;
 sameQuark=daughter===parent&&daughter=!="g";
 Which[
  sameQuark,delta=3cf/2;plus=<|0->2cf|>;regular=If[spin==="T",-2cf,-cf(1+xi)],
  spin==="T",Null,
  daughter==="g"&&parent==="g",delta=beta/2;plus=<|0->2ca|>;
   regular=2ca If[spin==="U",1/xi-2+xi(1-xi),1-2xi],
  daughter==="g",regular=cf If[spin==="U",(1+(1-xi)^2)/xi,2-xi],
  parent==="g",regular=tr If[spin==="U",xi^2+(1-xi)^2,2xi-1],
  True,Null];
 Join[collinearKernelRecord[xi,delta,plus,regular],<|"Daughter"->daughter,"Parent"->parent,
  "Spin"->spin,"PerturbativeParameter"->"alpha_s/(2 Pi)","KernelOrder"->0|>]
 ],"CollinearCounterterms"];

(* Coefficient of (alpha_s/(2 Pi))^order in f_new = Z convolution f_raw.
   The NNLO helicity entries are the conventional Larin -> MSbar finite PDF
   operator renormalization in the full flavor basis. Production may use them
   only with a matching raw operator contract; this provider does not assert
   equivalence of arbitrary gamma5 calculations.
   Bonino et al., arXiv:2510.00100v1, Appendix A (113)-(116);
   independent singlet/non-singlet checks: arXiv:1409.5131, Appendix A. *)
helicityFinitePDFCoefficient[daughter_,parent_,xi_,parameters_,order_]:=Module[
 {ca,cf,tr,nf,valence,antiquark,sea,sameFlavor},
 If[order===1,Return[If[daughter===parent&&parent=!="g",-4parameters["CF"](1-xi),0]]];
 If[order=!=2,collinearKernelFail["FiniteHelicityPDFOrderUnsupported",<|"Order"->order|>]];
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],
  collinearKernelFail["ColorAndFlavorParametersRequired"]];
 If[daughter==="g"||parent==="g",Return[0]];
 {ca,cf,tr,nf}=Lookup[parameters,{"CA","CF","TR","FlavorCount"}];
 sea=cf tr(2(1-xi)+(3-xi)Log[xi]+(2+xi)Log[xi]^2/2);
 sameFlavor=Last[daughter]===Last[parent];
 If[!sameFlavor,Return[sea]];
 If[First[daughter]===First[parent],
  valence=cf tr nf(1-xi)(20/9+4Log[xi]/3)-
   cf^2(4(1-xi)+(2(2+xi)-4(1-xi)Log[1-xi])Log[xi])-
   cf ca(148(1-xi)/9-Pi^2(1-xi)/3+2(10-xi)Log[xi]/3+(1-xi)Log[xi]^2);
  valence+sea,
  antiquark=-cf(cf-ca/2)(-14(1-xi)+2Pi^2(1+xi)/3-2(1+xi)Log[xi]^2-
   (1+xi)(6-8Log[1+xi])Log[xi]+8(1+xi)PolyLog[2,-xi]);
  antiquark+sea]
];
FactorizationSchemeKernel[name_,daughter_,parent_,spin_,xi_Symbol,parameters_Association]:=
 FactorizationSchemeKernel[name,daughter,parent,spin,xi,parameters,1];
FactorizationSchemeKernel[name_,daughter_,parent_,spin_,xi_Symbol,parameters_Association,
 order_Integer]:=Catch[Module[{record,orders,channel},
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||
   !MemberQ[{"U","L","T"},spin]||order<0,
  collinearKernelFail["PartonSpeciesSpinAndNonnegativeSchemeOrderRequired"]];
 If[order===0,Return[collinearKernelRecord[xi,If[daughter===parent,1,0],<||>,0]]];
 If[AssociationQ[name]&&KeyExistsQ[name,"FiniteKernelsByOrder"],
  orders=name["FiniteKernelsByOrder"];
  If[!AssociationQ[orders]||!AllTrue[Keys[orders],IntegerQ[#]&&#>0&]||
    !AllTrue[Values[orders],AssociationQ],collinearKernelFail["FiniteSchemeKernelsIndexedByPositiveOrderRequired"]];
  channel=Map[If[AssociationQ[#]&&!KeyExistsQ[#,"PerturbativeOrder"],
    Append[#,"PerturbativeOrder"->order],#]&,Lookup[orders,order,<||>]];
  Return[FactorizationSchemeKernel[<|"FiniteKernels"->channel,
   "DefaultScheme"->Lookup[name,"DefaultScheme","MSbar"]|>,daughter,parent,spin,xi,parameters,order]]];
 If[AssociationQ[name]&&KeyExistsQ[name,"FiniteKernels"],
  If[!AssociationQ[name["FiniteKernels"]],collinearKernelFail["FiniteSchemeKernelMatrixRequired"]];
  record=Lookup[name["FiniteKernels"],Key[{daughter,parent,spin}],Missing["NoFiniteKernelOverride"]];
  If[MissingQ[record],Return[FactorizationSchemeKernel[Lookup[name,"DefaultScheme","MSbar"],
    daughter,parent,spin,xi,parameters,order]]];
  Return[FactorizationSchemeKernel[record,daughter,parent,spin,xi,parameters,order]]];
 If[AssociationQ[name],record=collinearKernelValidate[name];
  If[record["Variable"]=!=xi,collinearKernelFail["KernelVariableMismatch"]];
  If[Lookup[record,"PerturbativeOrder",1]=!=order,
   collinearKernelFail["ExplicitFiniteSchemeOrderMismatch",<|"RequestedOrder"->order|>]];
  Return[record]];
 If[!MemberQ[{"MSbar","HelicityMSbar"},name],
  collinearKernelFail["FactorizationSchemeUnsupported",<|"Scheme"->name|>]];
 If[name==="HelicityMSbar"&&spin==="L"&&!KeyExistsQ[parameters,"CF"],
  collinearKernelFail["ColorAndFlavorParametersRequired"]];
 collinearKernelRecord[xi,0,<||>,If[name==="HelicityMSbar"&&spin==="L",
  helicityFinitePDFCoefficient[daughter,parent,xi,parameters,order],0]]
],"CollinearCounterterms"];
collinearBornMap[leg_,s_,v_,w_,e_]:=Switch[leg,
 "IncomingA",<|"Fraction"->w,"Invariants"->{w s,w s(v-1),-s v w},"ConstraintJacobian"->1/(s v),"MeasureWeight"->1|>,
 "IncomingB",With[{xi=(1-v)/(1-v w)},<|"Fraction"->xi,"Invariants"->{xi s,s(v-1),-xi s v w},"ConstraintJacobian"->1/(s(1-v w)),"MeasureWeight"->1|>],
 "Observed",With[{xi=1-v+v w},<|"Fraction"->xi,"Invariants"->{s,s(v-1)/xi,-s v w/xi},"ConstraintJacobian"->xi/s,"MeasureWeight"->xi^(-2+2e)|>],
 _,collinearKernelFail["CollinearLegUnsupported",<|"Leg"->leg|>]];
(* Reconstruct the invariant coefficient needed by the physical convolution.
   This is a kinematic substitution and its delta Jacobian, not a file-format adapter. *)
partonicBornInvariantCoefficient[born_Association,upper_Integer]:=Module[{check,e,s,v,w,mandel,delta},
 check=RequirePartonicEpsilonRange[born,{0,upper}];
 If[FailureQ[check],collinearKernelFail["BornEpsilonOrdersInsufficient",<|"Cause"->check|>]];
 If[born["Order"]=!="LO"||!AllTrue[Values[born["Coefficients"]],
  #["RegularCoefficient"]===0&&AllTrue[Values[#["PlusCoefficients"]],#===0&]&],
  collinearKernelFail["BornDeltaResultRequired"]];
 e=born["DimensionalRegulator"];s=born["Scale"];{v,w}=born["Variables"];mandel=born["MandelstamVariables"];
 delta=Sum[born["Coefficients"][j]["DeltaCoefficient"]e^j,{j,0,upper}];
 (s v delta)/.Thread[{s,v}->{mandel[[1]],1+mandel[[2]]/mandel[[1]]}]
];


ConvolveBornCollinearKernel[born_Association,kernel_Association,request_Association]:=Catch[Module[
 {k,xi,e,mandel,s,v,w,leg,map,h,ratio,slope,weight,endpointWeight,
  delta,plus=<||>,regular,coeff,atEndpoint,power,j,bornExpression,assumptions,endpointData},
 k=collinearKernelValidate[kernel];xi=k["Variable"];
 If[!ContainsAll[Keys[born],{"Coefficients","EpsilonRange","MandelstamVariables","DimensionalRegulator"}]||
   !ContainsAll[Keys[request],{"Leg","Scale","Variables"}],collinearKernelFail["BornDensityAndCollinearRequestRequired"]];
 e=born["DimensionalRegulator"];mandel=born["MandelstamVariables"];
 s=request["Scale"];{v,w}=request["Variables"];leg=request["Leg"];
 If[!MatchQ[mandel,{_Symbol,_Symbol,_Symbol}]||!MatchQ[{e,s,v,w,xi},{_Symbol..}]||
  !DuplicateFreeQ[mandel]||!DuplicateFreeQ[{e,s,v,w,xi}],collinearKernelFail["DistinctKinematicVariablesRequired"]];
 bornExpression=partonicBornInvariantCoefficient[born,Lookup[request,"BornThroughOrder",Last[born["EpsilonRange"]]]];
 If[!FreeQ[bornExpression,v|w|xi],collinearKernelFail["BornCoefficientUsesOutputCoordinates"]];
 If[!FreeQ[bornExpression,_SeriesData|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity|_Real],
  collinearKernelFail["ExactBornCoefficientRequired"]];
 assumptions=0<v<1&&0<w<1&&s>0;
 map=collinearBornMap[leg,s,v,w,e];h=map["Fraction"];
 ratio=Cancel[(1-h)/(1-w)];slope=Cancel[D[h,w]/.w->1];
 If[!TrueQ[FullSimplify[0<slope<Infinity,0<v<1]],collinearKernelFail["NondegenerateCollinearEndpointRequired"]];
 weight=map["ConstraintJacobian"]map["MeasureWeight"](bornExpression/.Thread[mandel->map["Invariants"]]);
 endpointData={weight,D[weight,w]}/.w->1;
 If[!FreeQ[endpointData,Indeterminate|_DirectedInfinity|Power[0,_]|_ConditionalExpression],collinearKernelFail["SmoothBornEndpointRequired"]];
 endpointWeight=Cancel[(weight/.w->1)/slope];
 If[!FreeQ[endpointWeight,Indeterminate|_DirectedInfinity],collinearKernelFail["RegularBornEndpointRequired"]];
 delta=endpointWeight k["DeltaCoefficient"];
 regular=weight(k["RegularCoefficient"]/.xi->h);
 KeyValueMap[Function[{logPower,kernelCoefficient},
  delta+=kernelCoefficient endpointWeight Log[slope]^(logPower+1)/(logPower+1);
  Do[
   coeff=kernelCoefficient Binomial[logPower,j] weight/ratio If[logPower===j,1,Log[ratio]^(logPower-j)];
   atEndpoint=kernelCoefficient Binomial[logPower,j] endpointWeight If[logPower===j,1,Log[slope]^(logPower-j)];
   AssociateTo[plus,j->(Lookup[plus,j,0]+atEndpoint)];
   regular+=(coeff-atEndpoint)Log[1-w]^j/(1-w),{j,0,logPower}]],k["PlusCoefficients"]];
 <|"Variable"->w,"Endpoint"->1,"Domain"->assumptions,"DimensionalRegulator"->e,
  "DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular,
  "CollinearMap"->map,"DensityConvention"->"E_c d sigma / d^(D-1) p_c",
  "BornSupport"->"delta(s+t+u)","KernelDirection"->"daughter <- parent",
  "PlusConvention"->"[Log[1-w]^k/(1-w)]_+ on [0,1]; other endpoint excluded"|>
 ],"CollinearCounterterms"];

FeynFacet`ConstructNLOCollinearCounterterm::usage="ConstructNLOCollinearCounterterm[born,card] produces explicit Laurent delta/plus/regular coefficients from a Born density, LO kernel and a selected finite PDF/FF scheme. The common dimensional factor (mu_R^2)^(p epsilon) for a Born alpha_s^p is left outside every NLO contribution.";
FeynFacet`ConstructNLOUVCounterterm::usage="ConstructNLOUVCounterterm[born,card] applies MSbar coupling renormalization, deriving the Born power of alpha_s from the generated expression.";
collinearDistributionSeries[record_,e_,high_]:=Module[{delta,plus,regular,scalarSeries},
 scalarSeries[expr_]:=Module[{poly=Normal[Series[expr,{e,0,high}]]},
  If[!FreeQ[poly,_SeriesData|_Series|_SeriesCoefficient|_Integrate|_Failure|Indeterminate|_DirectedInfinity],collinearKernelFail["ExplicitCountertermSeriesRequired"]];
  Association@Table[j->Coefficient[Expand[e poly],e,j+1],{j,-1,high}]];
 delta=scalarSeries[record["DeltaCoefficient"]];plus=scalarSeries /@ record["PlusCoefficients"];
 regular=scalarSeries[record["RegularCoefficient"]];
 Association@Table[j-><|"DeltaCoefficient"->delta[j],"PlusCoefficients"->(# [j]& /@ plus),"RegularCoefficient"->regular[j]|>,{j,-1,high}]
];
collinearBornRegularInEpsilon[born_,e_]:=If[!TrueQ[RequirePartonicEpsilonRange[born,{0,0}]],
 collinearKernelFail["BornCoefficientRegularInEpsilonRequired"]];
FeynFacet`ConstructNLOCollinearCounterterm[born_Association,card_Association]:=Catch[Module[
 {e,xi,parameters,kernel,finite,poleRecord,finiteRecord,combined,alpha,muR2,muF2,norm,high,keys,series},
 keys={"Leg","Scale","Variables","Daughter","Parent","Spin","KernelParameters","Coupling","RenormalizationScaleSquared","FactorizationScaleSquared","SplittingVariable"};
 If[!ContainsAll[Keys[card],keys],collinearKernelFail["NLOCollinearCardIncomplete",<|"Missing"->Complement[keys,Keys[card]]|>]];
 e=born["DimensionalRegulator"];xi=card["SplittingVariable"];parameters=card["KernelParameters"];
 {alpha,muR2,muF2}=Lookup[card,{"Coupling","RenormalizationScaleSquared","FactorizationScaleSquared"}];
 high=Lookup[card,"ThroughOrder",0];If[!IntegerQ[high]||high<0,collinearKernelFail["CountertermUpperOrderRequired"]];
 collinearBornRegularInEpsilon[born,e];
 If[!TrueQ[RequirePartonicEpsilonRange[born,{0,high+1}]],collinearKernelFail["BornEpsilonOrdersInsufficient",<|"Required"->{0,high+1}|>]];
 kernel=Lookup[card,"SplittingKernel",LeadingSplittingKernel[card["Daughter"],card["Parent"],card["Spin"],xi,parameters]];
 finite=Lookup[card,"FiniteKernel",FactorizationSchemeKernel[Lookup[card,"Scheme","MSbar"],card["Daughter"],card["Parent"],card["Spin"],xi,parameters]];
 If[FailureQ[kernel]||FailureQ[finite],collinearKernelFail["CountertermKernelConstructionFailed"]];
 If[!FreeQ[{kernel,finite},e],collinearKernelFail["FourDimensionalFactorizationKernelsRequired"]];
 poleRecord=ConvolveBornCollinearKernel[born,kernel,card];finiteRecord=ConvolveBornCollinearKernel[born,finite,card];
 If[FailureQ[poleRecord]||FailureQ[finite],collinearKernelFail["BornCollinearConvolutionFailed",<|"Pole"->poleRecord,"Finite"->finiteRecord|>]];
 norm=Exp[e(Log[4Pi]-EulerGamma)]Exp[e(Log[muR2]-Log[muF2])]/e;
 combined=Join[poleRecord,<|
  "DeltaCoefficient"->alpha/(2Pi)(norm poleRecord["DeltaCoefficient"]-finiteRecord["DeltaCoefficient"]),
  "PlusCoefficients"->Association@Table[j->alpha/(2Pi)(norm Lookup[poleRecord["PlusCoefficients"],j,0]-Lookup[finiteRecord["PlusCoefficients"],j,0]),
    {j,Union[Keys[poleRecord["PlusCoefficients"]],Keys[finiteRecord["PlusCoefficients"]]]}],
  "RegularCoefficient"->alpha/(2Pi)(norm poleRecord["RegularCoefficient"]-finiteRecord["RegularCoefficient"])|>];
 series=collinearDistributionSeries[combined,e,high];
 CreatePartonicResult[(partonicMap[partonicCollect,#]& /@ series),<|"Format"->"FeynFacet-PartonicResult","FormatVersion"->1,"Order"->"NLO",
  "DimensionalPrefactor"->born["DimensionalPrefactor"],
  "Scale"->card["Scale"],"Variables"->card["Variables"],"Contribution"->If[card["Leg"]==="Observed","FFCounterterm","PDFCounterterm"],
  "Subtraction"->KeyTake[card,{"Leg","Daughter","Parent","Spin","Scheme","FactorizationScaleSquared"}],"DimensionalRegulator"->e,"Variable"->Last[card["Variables"]],
    "Normalization"->"a_s=alpha_s/(2 pi); MSbar pole 1/eps+ln(4 pi)-EulerGamma; finite scheme f_new=(1+a_s Z) convolution f_old",
  "ScaleDomain"->(muR2>0&&muF2>0),"DensityConvention"->"E_c d sigma/d^(D-1)p_c"|>]
 ],"CollinearCounterterms"];
FeynFacet`ConstructNLOUVCounterterm[born_Association,card_Association]:=Catch[Module[
 {e,alpha,power,parameters,beta,xi,unit,mapped,norm,high,combined,keys},
 keys={"Scale","Variables","Coupling","KernelParameters","SplittingVariable"};
 If[!ContainsAll[Keys[card],keys],collinearKernelFail["NLOUVCardIncomplete"]];
 {alpha,parameters,xi}=Lookup[card,{"Coupling","KernelParameters","SplittingVariable"}];e=born["DimensionalRegulator"];
 collinearBornRegularInEpsilon[born,e];power=born["CouplingPower"];
 If[!IntegerQ[power]||power<0,collinearKernelFail["HomogeneousBornCouplingRequired"]];
 beta=(11parameters["CA"]-4parameters["TR"]parameters["FlavorCount"])/3;
 high=Lookup[card,"ThroughOrder",0];If[!IntegerQ[high]||high<0,collinearKernelFail["CountertermUpperOrderRequired"]];
 If[!TrueQ[RequirePartonicEpsilonRange[born,{0,high+1}]],collinearKernelFail["BornEpsilonOrdersInsufficient",<|"Required"->{0,high+1}|>]];
 unit=collinearKernelRecord[xi,1,<||>,0];mapped=ConvolveBornCollinearKernel[born,unit,Join[card,<|"Leg"->"IncomingA"|>]];
 If[FailureQ[mapped],collinearKernelFail["BornUVSupportFailed",<|"Cause"->mapped|>]];
 norm=-power beta alpha/(4Pi)Exp[e(Log[4Pi]-EulerGamma)]/e;
 combined=Join[mapped,<|"DeltaCoefficient"->norm mapped["DeltaCoefficient"]|>];
 CreatePartonicResult[(partonicMap[partonicCollect,#]& /@ collinearDistributionSeries[combined,e,high]),<|"Format"->"FeynFacet-PartonicResult","FormatVersion"->1,"Order"->"NLO",
  "DimensionalPrefactor"->born["DimensionalPrefactor"],
  "Scale"->card["Scale"],"Variables"->card["Variables"],"Contribution"->"UVCounterterm",
  "Subtraction"->KeyTake[card,{"Leg","Daughter","Parent","Spin","Scheme","FactorizationScaleSquared"}],"DimensionalRegulator"->e,"Variable"->Last[card["Variables"]],
    "BornCouplingPower"->power,"Beta0"->beta,"RenormalizationScheme"->"MSbar","DensityConvention"->"E_c d sigma/d^(D-1)p_c"|>]
 ],"CollinearCounterterms"];

FeynFacet`EnumerateNLOCollinearChannels::usage="EnumerateNLOCollinearChannels[channel,request] enumerates the Born channels required by nonzero LO splitting and finite scheme kernels for two incoming partons and one observed parton. Request supplies Species, Polarization, Schemes, SplittingVariable and KernelParameters. The unobserved recoil is summed over the declared species and exact quark-flavor conservation is imposed. Diagram generation must still confirm each allowed Born channel.";
FeynFacet`EnumerateNLOCollinearChannels[channel_Association,request_Association]:=Catch[Module[
 {species,spins,schemes,xi,parameters,incoming,observed,flavors,charge,rows={},leg,original,spin,candidate,
  daughter,parent,pole,finite,bornIncoming,bornObserved,scheme,recoil,conserved,nonzero,freeFlavor,probe},
 If[!ContainsAll[Keys[channel],{"Incoming","Observed"}]||
  !ContainsAll[Keys[request],{"Species","Polarization","Schemes","SplittingVariable","KernelParameters"}],collinearKernelFail["CollinearChannelEnumerationRequestRequired"]];
 {species,spins,schemes,xi,parameters}=Lookup[request,{"Species","Polarization","Schemes","SplittingVariable","KernelParameters"}];
 incoming=channel["Incoming"];observed=channel["Observed"];
 If[!ListQ[species]||!DuplicateFreeQ[species]||!AllTrue[species,collinearKernelSpeciesQ]||
  !MatchQ[incoming,{_,_}]||!AssociationQ[spins]||!MatchQ[Lookup[spins,"Incoming",None],{"U"|"L"|"T","U"|"L"|"T"}]||!MemberQ[{"U","L","T"},Lookup[spins,"Observed",None]]||
  !AllTrue[Join[incoming,{observed}],MemberQ[species,#]&],collinearKernelFail["CompleteDeclaredPartonSpeciesRequired"]];
 If[Lookup[request,"FlavorSummation",None]==="MasslessQCD",
  qcdRequireConjugateSpecies[species];
  If[!AllTrue[Values[schemes],MemberQ[{"MSbar","HelicityMSbar"},#]&],
   collinearKernelFail["FlavorSymmetricFiniteSchemesRequired"]];
  If[Complement[qcdFlavorLabels[species],qcdFixedFlavors[channel]]==={}&&
   !TrueQ[parameters["FlavorCount"]-Length[qcdFixedFlavors[channel]]===0],
   freeFlavor=ToString[Unique["flavor"],InputForm];
   probe=FeynFacet`EnumerateNLOCollinearChannels[channel,Join[request,<|
    "Species"->Join[species,{{"q",freeFlavor},{"qbar",freeFlavor}}],
    "FlavorSummation"->None|>]];
   If[!AssociationQ[probe],collinearKernelFail["FlavorCompletenessEnumerationFailed"]];
   If[!FreeQ[probe["Channels"],freeFlavor],
    collinearKernelFail["AdditionalUnobservedFlavorRepresentativeRequired"]]]];
 flavors=DeleteDuplicates[Last /@ Select[species,#=!="g"&]];
 charge[parton_]:=If[parton==="g",ConstantArray[0,Length[flavors]],
   If[First[parton]==="q",1,-1](Boole[#===Last[parton]]& /@ flavors)];
 nonzero[k_]:=!TrueQ[k["DeltaCoefficient"]===0&&AllTrue[Values[k["PlusCoefficients"]],#===0&]&&k["RegularCoefficient"]===0];
 Do[
  original=Switch[leg,"IncomingA",incoming[[1]],"IncomingB",incoming[[2]],"Observed",observed];
  spin=Switch[leg,"IncomingA",spins["Incoming"][[1]],"IncomingB",spins["Incoming"][[2]],"Observed",spins["Observed"]];
  scheme=Lookup[schemes,leg,Missing["FactorizationSchemeRequired"]];If[MissingQ[scheme],collinearKernelFail["FactorizationSchemeForEveryLegRequired"]];
  If[AssociationQ[scheme]&&!KeyExistsQ[scheme,"FiniteKernels"],collinearKernelFail["ChannelEnumerationNeedsFiniteKernelMatrix"]];
  Do[
   {daughter,parent}=If[leg==="Observed",{original,candidate},{candidate,original}];
   pole=LeadingSplittingKernel[daughter,parent,spin,xi,parameters];
   finite=FactorizationSchemeKernel[scheme,daughter,parent,spin,xi,parameters];
   If[FailureQ[pole]||FailureQ[finite],collinearKernelFail["CollinearEnumerationKernelFailed"]];
   If[!nonzero[pole]&&!nonzero[finite],Continue[]];
   bornIncoming=Switch[leg,"IncomingA",ReplacePart[incoming,1->candidate],"IncomingB",ReplacePart[incoming,2->candidate],"Observed",incoming];
   bornObserved=If[leg==="Observed",candidate,observed];
   Do[
    conserved=Total[charge /@ bornIncoming]===charge[bornObserved]+charge[recoil];
    If[conserved,AppendTo[rows,<|"Leg"->leg,"Daughter"->daughter,"Parent"->parent,"Spin"->spin,"Scheme"->scheme,
     "BornChannel"-><|"Incoming"->bornIncoming,"Observed"->bornObserved,"Recoil"->recoil|>,
     "SplittingKernel"->pole,"FiniteKernel"->finite|>]],{recoil,species}],{candidate,species}],
  {leg,{"IncomingA","IncomingB","Observed"}}];
 If[Lookup[request,"FlavorSummation",None]==="MasslessQCD",
  rows=qcdFlavorSummedRows[rows,channel,parameters["FlavorCount"],"BornChannel"]];
 <|"Channels"->rows,"Species"->species,"Channel"->channel,"Polarization"->spins,
  "Coverage"->"All nonzero kernels within the declared flavor basis, with quark-flavor conservation; confirm the remaining Born channels by diagram generation"|>
 ],"CollinearCounterterms"];

partonicZeroTreeQ[value_Association]:=AllTrue[Values[value],partonicZeroTreeQ];
partonicZeroTreeQ[value_List]:=AllTrue[value,partonicZeroTreeQ];
partonicZeroTreeQ[value_]:=TrueQ[value===0];
collinearBornCorner[row_,0]:=row;
collinearBornCorner[row_Association,n_Integer?Positive]:=(
 If[!partonicZeroTreeQ[row["PlusCoefficients"]]||!partonicZeroTreeQ[row["RegularCoefficient"]],
  collinearKernelFail["CornerSupportedBornResultRequired"]];
 collinearBornCorner[row["DeltaCoefficient"],n-1]);
collinearCornerKernel[coefficient_,kernel_,n_Integer?Positive,1]:=partonicDistribution[
 partonicCornerDistribution[coefficient kernel["DeltaCoefficient"],n-1],
 partonicCornerDistribution[coefficient #,n-1]&/@kernel["PlusCoefficients"],
 partonicCornerDistribution[coefficient kernel["RegularCoefficient"],n-1]];
collinearCornerKernel[coefficient_,kernel_,n_Integer?Positive,axis_Integer]:=partonicDistribution[
 collinearCornerKernel[coefficient,kernel,n-1,axis-1],<||>,
 If[n===1,0,partonicDistributionZero[n-1]]];
ConvolveBornMellinKernel[born_Association,kernel_Association,axis_Symbol,{low_Integer,high_Integer}]:=Catch[Module[
 {axes,position,e,rows,coefficient},
 If[born["Order"]=!="LO"||!KeyExistsQ[born["DistributionBasis"],"Axes"],collinearKernelFail["TensorProductBornResultRequired"]];
 axes=Lookup[born["DistributionBasis"]["Axes"],"Variable"];position=FirstPosition[axes,axis,Missing[]];
 If[MissingQ[position]||!FreeQ[kernel,born["DimensionalRegulator"]]||kernel["Variable"]=!=axis,
  collinearKernelFail["RegulatorIndependentKernelOnDeclaredAxisRequired"]];
 If[FailureQ[RequirePartonicEpsilonRange[born,{low,high}]],collinearKernelFail["BornEpsilonOrdersInsufficient"]];
 collinearKernelValidate[kernel];e=born["DimensionalRegulator"];
 rows=Association@Table[n->collinearCornerKernel[collinearBornCorner[born["Coefficients"][n],Length[axes]],kernel,Length[axes],First[position]],{n,low,high}];
 CreatePartonicResult[rows,Join[KeyDrop[born,{"Coefficients","EpsilonRange","Coverage"}],<|"EpsilonRange"->{low,high}|>]]
],"CollinearCounterterms"];
ConstructCurrentCollinearCounterterm[bornResults_Association,request_Association]:=Catch[Module[
 {target,variables,ct,e,range,needed,parts=<||>,details={},born,bornChannel,leg,axis,spin,daughter,parent,
  kernel,finite,scaleLog,convolved,schemeConvolved,coefficients,rows,value,id,meta,alpha,normalization,legSpecs,legSpec,index,role,observed},
 If[!ContainsAll[Keys[request],{"PhysicalChannel","Variables","Counterterms","DimensionalRegulator","EpsilonRange","Polarization","Include","FactorizationLegs"}],
  collinearKernelFail["CurrentCollinearRequestRequired"]];
 target=request["PhysicalChannel"];variables=request["Variables"];ct=request["Counterterms"];e=request["DimensionalRegulator"];
 range=request["EpsilonRange"];alpha=ct["Coupling"];
 legSpecs=request["FactorizationLegs"];
 If[!MatchQ[range,{-1,_Integer?NonNegative}]||!MatchQ[variables,{_Symbol..}]||
  !AssociationQ[legSpecs]||legSpecs===<||>||!AllTrue[Values[legSpecs],AssociationQ]||
  !ContainsAll[Keys[legSpecs],request["Include"]],collinearKernelFail["DeclaredCurrentFactorizationLegsRequired"]];
 Do[legSpec=legSpecs[leg];role=Lookup[legSpec,"Role",None];axis=Lookup[legSpec,"Variable",None];
  index=Lookup[legSpec,"Index",None];
  If[!MemberQ[variables,axis]||!MemberQ[{"PDF","FF"},role]||
    (role==="PDF"&&(!IntegerQ[index]||index<1||index>Length[target["Incoming"]]))||
    (role==="FF"&&!KeyExistsQ[target,"Observed"])||
    !KeyExistsQ[ct["Schemes"],leg]||!KeyExistsQ[ct["FactorizationScalesSquared"],leg],
   collinearKernelFail["CurrentFactorizationLegRequired",<|"Leg"->leg|>]],{leg,Keys[legSpecs]}];
 needed={0,Last[range]+1};
 Do[born=bornResults[name];bornChannel=born["PhysicalChannel"];
  If[FailureQ[RequirePartonicEpsilonRange[born,needed]],collinearKernelFail["BornEpsilonOrdersInsufficient",<|"Channel"->name,"Required"->needed|>]];
  born=coefficientRegulatorNormalize[born,e];
  Do[
   If[!MemberQ[request["Include"],leg],Continue[]];
   legSpec=legSpecs[leg];axis=legSpec["Variable"];role=legSpec["Role"];
   If[role==="PDF",
    index=legSpec["Index"];
    If[Length[bornChannel["Incoming"]]=!=Length[target["Incoming"]]||
     Lookup[bornChannel,"Observed",None]=!=Lookup[target,"Observed",None]||
     ReplacePart[bornChannel["Incoming"],index->target["Incoming"][[index]]]=!=target["Incoming"],Continue[]];
    {daughter,parent}={bornChannel["Incoming"][[index]],target["Incoming"][[index]]};
    spin=request["Polarization"]["Incoming"][[index]],
    If[bornChannel["Incoming"]=!=target["Incoming"]||!KeyExistsQ[bornChannel,"Observed"],Continue[]];
    {daughter,parent}={target["Observed"],bornChannel["Observed"]};spin=request["Polarization"]["Observed"]];
   kernel=LeadingSplittingKernel[daughter,parent,spin,axis,ct["KernelParameters"]];
   finite=FactorizationSchemeKernel[ct["Schemes"][leg],daughter,parent,spin,axis,ct["KernelParameters"]];
   If[FailureQ[kernel]||FailureQ[finite],collinearKernelFail["CurrentSplittingKernelFailed"]];
   scaleLog=Log[ct["RenormalizationScaleSquared"]/ct["FactorizationScalesSquared"][leg]];
   convolved=ConvolveBornMellinKernel[born,kernel,axis,needed];
   schemeConvolved=ConvolveBornMellinKernel[born,finite,axis,{0,Last[range]}];
   If[!AssociationQ[convolved]||!AssociationQ[schemeConvolved],collinearKernelFail["CurrentBornConvolutionFailed"]];
   coefficients=Association@Table[n->partonicDistributionSum[
    Join[Table[partonicMap[Function[value,alpha/(2Pi) scaleLog^(n-j+1)/Factorial[n-j+1] value],
      convolved["Coefficients"][j]],{j,0,n+1}],
     If[n>=0,{partonicMap[Function[value,-alpha/(2Pi)value],schemeConvolved["Coefficients"][n]]},{}]],Length[variables]],
   {n,First[range],Last[range]}];
   id=leg<>"/"<>name;AssociateTo[parts,id->coefficients];
   AppendTo[details,<|"Leg"->leg,"BornChannel"->name,"Daughter"->daughter,"Parent"->parent,
    "Spin"->spin,"Scheme"->ct["Schemes"][leg],"RequiredBornEpsilonRange"->needed|>],
  {leg,Keys[legSpecs]}],{name,Keys[bornResults]}];
 If[parts===<||>,collinearKernelFail["NonemptyCurrentCountertermContributionsRequired"]];
 rows=Association@Table[n->partonicDistributionSum[(#[n]&/@Values[parts]),Length[variables]],{n,First[range],Last[range]}];
 meta=Join[KeyDrop[request,{"Counterterms","CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints",
   "TwoParticleMeasurement","BareCouplingRules","EndpointExpansion"}],
  <|"Order"->"NLO","Contribution"->"Counterterm","CouplingPower"->1,
  "StructureFunctions"->Lookup[request,"StructureFunctions",Keys[request["CurrentProjectors"]]],"Subtractions"->details,
  "CountertermConvention"->"alpha_s/(2 pi) [(mu_R^2/mu_F^2)^epsilon P^(0)/epsilon - Z^(1)], Born epsilon coefficients retained"|>];
 CreatePartonicResult[rows,meta]
],"CollinearCounterterms"];
End[];EndPackage[];
