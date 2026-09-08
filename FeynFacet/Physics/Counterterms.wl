(* Collinear subtraction of invariant single-inclusive partonic densities.
   Kernels use a_s=alpha_s/(2 Pi) and explicit daughter <- parent labels.
   Finite scheme kernels mean f_new=(1+a_s Z) convolution f_old. *)
BeginPackage["FeynFacet`"];
LeadingSplittingKernel::usage="LeadingSplittingKernel[daughter,parent,spin,xi,parameters] gives LO delta/plus/regular kernels for individual species {q,flavor}, {qbar,flavor}, or g. Parameters declares CA, CF, TR, and FlavorCount. Spin is U, L, or T. Plus[k] means [Log[1-xi]^k/(1-xi)]_+.";
FactorizationSchemeKernel::usage="FactorizationSchemeKernel[name,daughter,parent,spin,xi,parameters] supplies a finite distribution redefinition Z. MSbar gives zero; HelicityMSbar includes the diagonal BMHV helicity-restoring Zqq=-4 CF(1-xi). An explicit kernel association can be supplied for one channel, or a scheme matrix with FiniteKernels keyed by {daughter,parent,spin} and optional DefaultScheme (MSbar).";
ConvolveBornCollinearKernel::usage="ConvolveBornCollinearKernel[born,kernel,request] acts on the invariant Born density b(s,t,u;epsilon) delta(s+t+u). Born declares Coefficient, MandelstamVariables and DimensionalRegulator. Request declares Leg (IncomingA, IncomingB, or Observed), Scale s, Variables {v,w}. It returns exact delta/plus/regular coefficients on 0<w<=1, with the complete D-dimensional FF Jacobian.";
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
FactorizationSchemeKernel[name_,daughter_,parent_,spin_,xi_Symbol,parameters_Association]:=Catch[Module[{record},
 If[AssociationQ[name]&&KeyExistsQ[name,"FiniteKernels"],
  If[!AssociationQ[name["FiniteKernels"]],collinearKernelFail["FiniteSchemeKernelMatrixRequired"]];
  record=Lookup[name["FiniteKernels"],Key[{daughter,parent,spin}],Missing["NoFiniteKernelOverride"]];
  If[MissingQ[record],Return[FactorizationSchemeKernel[Lookup[name,"DefaultScheme","MSbar"],daughter,parent,spin,xi,parameters]]];
  Return[FactorizationSchemeKernel[record,daughter,parent,spin,xi,parameters]]];
 If[AssociationQ[name],record=collinearKernelValidate[name];
  If[record["Variable"]=!=xi,collinearKernelFail["KernelVariableMismatch"]];Return[record]];
 If[!MemberQ[{"MSbar","HelicityMSbar"},name],collinearKernelFail["FactorizationSchemeUnsupported",<|"Scheme"->name|>]];
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||!MemberQ[{"U","L","T"},spin]||!KeyExistsQ[parameters,"CF"],
  collinearKernelFail["PartonSpeciesAndSpinRequired"]];
 collinearKernelRecord[xi,0,<||>,If[name==="HelicityMSbar"&&spin==="L"&&daughter===parent&&parent=!="g",-4parameters["CF"](1-xi),0]]
 ],"CollinearCounterterms"];
collinearBornMap[leg_,s_,v_,w_,e_]:=Switch[leg,
 "IncomingA",<|"Fraction"->w,"Invariants"->{w s,w s(v-1),-s v w},"ConstraintJacobian"->1/(s v),"MeasureWeight"->1|>,
 "IncomingB",With[{xi=(1-v)/(1-v w)},<|"Fraction"->xi,"Invariants"->{xi s,s(v-1),-xi s v w},"ConstraintJacobian"->1/(s(1-v w)),"MeasureWeight"->1|>],
 "Observed",With[{xi=1-v+v w},<|"Fraction"->xi,"Invariants"->{s,s(v-1)/xi,-s v w/xi},"ConstraintJacobian"->xi/s,"MeasureWeight"->xi^(-2+2e)|>],
 _,collinearKernelFail["CollinearLegUnsupported",<|"Leg"->leg|>]];
ConvolveBornCollinearKernel[born_Association,kernel_Association,request_Association]:=Catch[Module[
 {k,xi,e,mandel,s,v,w,leg,map,h,ratio,slope,weight,endpointWeight,
  delta,plus=<||>,regular,coeff,atEndpoint,power,j,bornExpression,assumptions,endpointData},
 k=collinearKernelValidate[kernel];xi=k["Variable"];
 If[!ContainsAll[Keys[born],{"Coefficient","MandelstamVariables","DimensionalRegulator"}]||
   !ContainsAll[Keys[request],{"Leg","Scale","Variables"}],collinearKernelFail["BornDensityAndCollinearRequestRequired"]];
 e=born["DimensionalRegulator"];mandel=born["MandelstamVariables"];
 s=request["Scale"];{v,w}=request["Variables"];leg=request["Leg"];
 If[!MatchQ[mandel,{_Symbol,_Symbol,_Symbol}]||!MatchQ[{e,s,v,w,xi},{_Symbol..}]||
  !DuplicateFreeQ[mandel]||!DuplicateFreeQ[{e,s,v,w,xi}],collinearKernelFail["DistinctKinematicVariablesRequired"]];
 bornExpression=born["Coefficient"];
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
collinearBornRegularInEpsilon[born_,e_]:=Module[{value=Quiet[Check[Limit[born["Coefficient"],e->0],$Failed]]},
 If[value===$Failed||!FreeQ[value,Indeterminate|_DirectedInfinity|_Limit|_ConditionalExpression],
  collinearKernelFail["BornCoefficientRegularInEpsilonRequired"]]
];
FeynFacet`ConstructNLOCollinearCounterterm[born_Association,card_Association]:=Catch[Module[
 {e,xi,parameters,kernel,finite,poleRecord,finiteRecord,combined,alpha,muR2,muF2,norm,high,keys,series},
 keys={"Leg","Scale","Variables","Daughter","Parent","Spin","KernelParameters","Coupling","RenormalizationScaleSquared","FactorizationScaleSquared","SplittingVariable"};
 If[!ContainsAll[Keys[card],keys],collinearKernelFail["NLOCollinearCardIncomplete",<|"Missing"->Complement[keys,Keys[card]]|>]];
 e=born["DimensionalRegulator"];xi=card["SplittingVariable"];parameters=card["KernelParameters"];
 {alpha,muR2,muF2}=Lookup[card,{"Coupling","RenormalizationScaleSquared","FactorizationScaleSquared"}];
 high=Lookup[card,"ThroughOrder",0];If[!IntegerQ[high]||high<0,collinearKernelFail["CountertermUpperOrderRequired"]];
 collinearBornRegularInEpsilon[born,e];
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
 <|"Format"->"FeynFacet-NLOContribution","FormatVersion"->1,"Contribution"->If[card["Leg"]==="Observed","FFCounterterm","PDFCounterterm"],
  "Card"->card,"DimensionalRegulator"->e,"Variable"->Last[card["Variables"]],
  "LaurentLowerBound"->-1,"KnownThroughOrder"->high,"Coefficients"->series,
  "PoleConvolution"->poleRecord,"FiniteSchemeConvolution"->finiteRecord,
  "Normalization"->"a_s=alpha_s/(2 pi); MSbar pole 1/eps+ln(4 pi)-EulerGamma; finite scheme f_new=(1+a_s Z) convolution f_old",
  "ScaleDomain"->(muR2>0&&muF2>0),"DensityConvention"->"E_c d sigma/d^(D-1)p_c"|>
 ],"CollinearCounterterms"];
FeynFacet`ConstructNLOUVCounterterm[born_Association,card_Association]:=Catch[Module[
 {e,alpha,power,parameters,beta,xi,unit,mapped,norm,high,combined,keys},
 keys={"Scale","Variables","Coupling","KernelParameters","SplittingVariable"};
 If[!ContainsAll[Keys[card],keys],collinearKernelFail["NLOUVCardIncomplete"]];
 {alpha,parameters,xi}=Lookup[card,{"Coupling","KernelParameters","SplittingVariable"}];e=born["DimensionalRegulator"];
 collinearBornRegularInEpsilon[born,e];power=If[born["Coefficient"]===0,0,Exponent[born["Coefficient"],alpha]];
 If[!IntegerQ[power]||power<0||!FreeQ[Cancel[born["Coefficient"]/alpha^power],alpha],collinearKernelFail["HomogeneousBornCouplingRequired"]];
 beta=(11parameters["CA"]-4parameters["TR"]parameters["FlavorCount"])/3;
 high=Lookup[card,"ThroughOrder",0];If[!IntegerQ[high]||high<0,collinearKernelFail["CountertermUpperOrderRequired"]];
 unit=collinearKernelRecord[xi,1,<||>,0];mapped=ConvolveBornCollinearKernel[born,unit,Join[card,<|"Leg"->"IncomingA"|>]];
 If[FailureQ[mapped],collinearKernelFail["BornUVSupportFailed",<|"Cause"->mapped|>]];
 norm=-power beta alpha/(4Pi)Exp[e(Log[4Pi]-EulerGamma)]/e;
 combined=Join[mapped,<|"DeltaCoefficient"->norm mapped["DeltaCoefficient"]|>];
 <|"Format"->"FeynFacet-NLOContribution","FormatVersion"->1,"Contribution"->"UVCounterterm",
  "Card"->card,"DimensionalRegulator"->e,"Variable"->Last[card["Variables"]],
  "LaurentLowerBound"->-1,"KnownThroughOrder"->high,"Coefficients"->collinearDistributionSeries[combined,e,high],
  "BornCouplingPower"->If[born["Coefficient"]===0,Missing["ZeroBornCoefficient"],power],"ExactInEpsilon"->TrueQ[born["Coefficient"]===0],"Beta0"->beta,"RenormalizationScheme"->"MSbar","DensityConvention"->"E_c d sigma/d^(D-1)p_c"|>
 ],"CollinearCounterterms"];

FeynFacet`EnumerateNLOCollinearChannels::usage="EnumerateNLOCollinearChannels[channel,request] enumerates the Born channels required by nonzero LO splitting and finite scheme kernels for two incoming partons and one observed parton. Request supplies Species, IncomingSpins, Schemes, SplittingVariable and KernelParameters. The unobserved recoil is summed over the declared species and exact quark-flavor conservation is imposed. Diagram generation must still confirm each allowed Born channel.";
FeynFacet`EnumerateNLOCollinearChannels[channel_Association,request_Association]:=Catch[Module[
 {species,spins,schemes,xi,parameters,incoming,observed,flavors,charge,rows={},leg,original,spin,candidate,
  daughter,parent,pole,finite,bornIncoming,bornObserved,scheme,recoil,conserved,nonzero},
 If[!ContainsAll[Keys[channel],{"Incoming","Observed"}]||
  !ContainsAll[Keys[request],{"Species","IncomingSpins","Schemes","SplittingVariable","KernelParameters"}],collinearKernelFail["CollinearChannelEnumerationRequestRequired"]];
 {species,spins,schemes,xi,parameters}=Lookup[request,{"Species","IncomingSpins","Schemes","SplittingVariable","KernelParameters"}];
 incoming=channel["Incoming"];observed=channel["Observed"];
 If[!ListQ[species]||!DuplicateFreeQ[species]||!AllTrue[species,collinearKernelSpeciesQ]||
  !MatchQ[incoming,{_,_}]||!MatchQ[spins,{"U"|"L"|"T","U"|"L"|"T"}]||
  !AllTrue[Join[incoming,{observed}],MemberQ[species,#]&],collinearKernelFail["CompleteDeclaredPartonSpeciesRequired"]];
 flavors=DeleteDuplicates[Last /@ Select[species,#=!="g"&]];
 charge[parton_]:=If[parton==="g",ConstantArray[0,Length[flavors]],
   If[First[parton]==="q",1,-1](Boole[#===Last[parton]]& /@ flavors)];
 nonzero[k_]:=!TrueQ[k["DeltaCoefficient"]===0&&AllTrue[Values[k["PlusCoefficients"]],#===0&]&&k["RegularCoefficient"]===0];
 Do[
  original=Switch[leg,"IncomingA",incoming[[1]],"IncomingB",incoming[[2]],"Observed",observed];
  spin=Switch[leg,"IncomingA",spins[[1]],"IncomingB",spins[[2]],"Observed","U"];
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
 <|"Channels"->rows,"Species"->species,"Channel"->channel,"IncomingSpins"->spins,
  "Coverage"->"All nonzero kernels within the declared flavor basis, with quark-flavor conservation; confirm the remaining Born channels by diagram generation"|>
 ],"CollinearCounterterms"];

End[];EndPackage[];
